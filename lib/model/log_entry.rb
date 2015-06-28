require 'model/log'
require 'model/certificate'
require 'certificate-transparency'

class LogEntry < Sequel::Model
	many_to_one :log
	many_to_one :certificate

	# This method is epic.  We insert all the records we can, ignoring any
	# that already exist, and then return a pile of new model objects
	# representing the records we *did* insert.
	#
	def self.bulk_insert_entries(log_id, entries, offset)
		unless log_id.is_a? String and log_id =~ /^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$/
			raise ArgumentError,
			      "log_id is not a UUID: #{log_id.inspect}"
		end

		unless offset.is_a? Integer
			raise ArgumentError,
			      "offset must be an integer"
		end

		entries.map! do |e|
			leaf_input = e.leaf_input.to_blob.unpack("H*").first
			extra_data = JSON.parse(e.to_json)["extra_data"].unpack("m").first.unpack("H*").first

			%{('#{log_id}'::uuid,#{offset},'\\x#{leaf_input}'::bytea,'\\x#{extra_data}'::bytea)}.tap { offset += 1 }
		end

		# Dear Lord, save me from the nightmares of hand-hacked SQL
		sql = %{
			INSERT INTO log_entries (log_id,ordinal,leaf_input,extra_data)
			       (SELECT * FROM (VALUES #{entries.join(',')}) AS src
			       (log_id,ordinal,leaf_input,extra_data)
			       WHERE NOT EXISTS (
			           SELECT 1 FROM log_entries AS dst
			            WHERE src.log_id=dst.log_id
			              AND src.ordinal=dst.ordinal
			       )) RETURNING *
		}

		begin
			db.fetch(sql).map { |e| LogEntry.load(e) }
		rescue Sequel::CheckConstraintViolation
			# We're trying to insert log entries which aren't immediately
			# after the previous ones.  Ideally, this shouldn't happen,
			# but it isn't terrible that it has, because the problem will
			# sort itself out as soon as another STH is fetched and we start
			# to fetch new records from that.  So, we just ignore it.
			return nil
		rescue Sequel::UniqueConstraintViolation
			# Hit that one-in-a-million chance, conflicting with someone else's
			# insert.  We can try again straight away, and be *extremely*
			# confident it will succeed this time.
			retry
		rescue StandardError => ex
			db.log_exception(ex, "Failed to insert #{entries.length} log entries for log #{log_id}")
			raise
		end
	end

	def mtl
		@mtl ||= CT::MerkleTreeLeaf.from_blob(leaf_input)
	end

	def chain
		# This is 18 kinds of ugly, but for now it's what we've got to work with
		# TODO: refactor this whole type into using CT::LogEntry more directly
		CT::LogEntry.from_json(self.to_json).certificate_chain.to_a
	end

	def precertificate
		# This is 18 kinds of ugly, but for now it's what we've got to work with
		# TODO: refactor this whole type into using CT::LogEntry more directly
		CT::LogEntry.from_json(self.to_json).precertificate
	end

	def to_json
		{
			id:         id,
			leaf_input: [leaf_input].pack("m0"),
			extra_data: [extra_data].pack("m0")
		}.to_json
	end
end
