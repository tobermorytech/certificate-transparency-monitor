require 'digest/sha2'
require 'openssl'
require 'fileutils'

class Certificate < Sequel::Model
	one_to_many :log_entries

	many_to_one :issuer,
	            class_name: "Certificate"

	# Stuff a bunch of certs into the table.  Doesn't get real worried
	# if any of the certs were already there, it just ignores them.
	#
	# @param [Array<OpenSSL::X509::Certificate>]
	#
	# @return [Array<Certificate>] model objects representing the
	#   rows that were successfully added to the database.
	#
	def self.bulk_insert(certs)
		rows = certs.map! do |c|
			hex_id  = Digest::SHA256.digest(c.to_der).unpack("H*").first
			hex_der = c.to_der.unpack("H*").first

			%{('\\x#{hex_id}'::bytea,'\\x#{hex_der}'::bytea)}
		end

		# Dear Lord, save me from the nightmares of hand-hacked SQL
		sql = %{
			INSERT INTO certificates (id, der)
			       (SELECT * FROM (VALUES #{rows.join(',')}) AS src
			       (id, der)
			       WHERE NOT EXISTS (
			           SELECT 1 FROM certificates AS dst
			            WHERE src.id=dst.id
			       )) RETURNING *
		}

		begin
			db.fetch(sql).map { |e| Certificate.load(e) }
		rescue Sequel::UniqueConstraintViolation
			# Hit that one-in-a-million chance, conflicting with someone else's
			# insert.  We can try again straight away, and be *extremely*
			# confident it will succeed this time.
			retry
		rescue StandardError => ex
			db.log_exception(ex, "Failed to insert #{rows.length} certificates")
			raise
		end
	end

	# Find a certificate record, given an X509 certificate.
	#
	# @param cert [OpenSSL::X509::Certificate]
	#
	# @return [Certificate] or nil if no certificate record was found for the
	#   specified certificate.
	#
	def self.find_by_x509(x509)
		Certificate[Digest::SHA256.digest(x509.to_der)]
	end

	# Overload standard Sequel::Model fetcher
	#
	# See https://github.com/jeremyevans/sequel/pull/1020 for the reason why
	# this is necessary.
	#
	def self.[](k)
		super(Sequel::SQL::Blob.new(k))
	end

	# Calculate the ID for the record.
	#
	def before_create
		self.id = Digest::SHA256.digest(der)
	end

	# Return the raw subject field from the cert.
	def subject
		x509.subject
	end

	# Return the list of subject alt names in the cert, if any.  We'll always
	# give you back an array, even if it's empty.  The entries will come back
	# in their type-tagged form (eg "DNS:foo.example.com",
	# "email:foo@example.com", etc), so you'll need to account for that.
	#
	def subject_alt_names
		if subjectAltName
			subjectAltName.value.split(', ')
		else
			[]
		end
	end

	# Give up the CN of the cert, if any.
	#
	def cn
		subject.to_a.find { |c| c.first == "CN" }.last.force_encoding("UTF-8") rescue nil
	end

	# Return the list of hostnames embedded in the cert, whether those be
	# in the subject's CN, or in subjectAltName.
	#
	# @return [Array<String>]
	#
	def hostnames
		cns = subject
		        .to_a
		        .select { |e| e[0] == "CN" }
		        .map { |e| e[1] }

		sANs = subject_alt_names
		         .select { |sAN| sAN =~ /^DNS:/ }
		         .map { |sAN| sAN.gsub(/^DNS:/, '') }
		         .select { |sAN| URI(sAN) rescue nil }

		(cns + sANs).uniq.select do |h|
			begin
				# Least-worst way to check a hostname for validity that I know of
				URI(h)
			rescue URI::InvalidURIError
				false
			end
		end
	end

	# Return the certificate as an easy-to-introspect object.
	#
	# @return [OpenSSL::X509::Certificate]
	#
	def x509
		OpenSSL::X509::Certificate.new(der)
	end

	# Return a hex-encoded form of the record's ID, for use in URLs, etc.
	#
	def hex_id
		id.unpack("H*").first
	end

	private

	# Return the subjectAltName extension for the cert, or `nil` if none exists.
	#
	# @return [OpenSSL::X509::Extension]
	#
	def subjectAltName
		x509.extensions.find { |e| e.oid == "subjectAltName" }
	end
end
