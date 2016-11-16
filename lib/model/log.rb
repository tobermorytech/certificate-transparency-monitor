require 'uri'
require 'json'
require 'extlib'
require 'model/log_entry'
require 'model/log_error'
require 'model/tree_head'
require 'net/http'
require 'certificate-transparency-client'

require 'dai'

class Log < Sequel::Model
	one_to_many :tree_heads
	one_to_one  :newest_tree_head,
	            class_name: "TreeHead",
	            order: Sequel.desc(:retrieved_at),
	            limit: 1

	one_to_many :entries, :class_name => "LogEntry"
	one_to_many :errors,  :class_name => "LogError"

	many_to_many :roots, join_table: :roots,
	                     left_key:   :log_id,
	                     right_key:  :certificate_id,
	                     class_name: "Certificate"

	def size
		(entries_dataset.max(:ordinal) + 1) rescue 0
	end

	# Retrieve the current Signed Tree Head from the log, and add it to the set
	# of tree heads for this log.
	#
	# @return TreeHead
	#
	# @raise [RuntimeError] if something went wrong in the fetching process.
	#
	def fetch_sth
		sth = begin
			client.get_sth
		rescue StandardError => ex
			LogError.create(
				log: self,
				when: Time.now,
				details: "#{ex.message} (#{ex.class})"
			)

			raise
		end

		TreeHead.create(
			timestamp: sth.timestamp,
			root_hash: sth.root_hash,
			signature: sth.signature,
			size:      sth.tree_size,
			log:       self
		).tap do |th|
			unless sth.valid?(public_key)
				LogError.create(
					log: self,
					tree_head: th,
					when: Time.now,
					details: "Invalid signature"
				)

				raise RuntimeError,
				      "Invalid signature"
			end
		end
	end

	def fetch_entries(first, last)
		entries = client.get_entries(first, last)

		LogEntry.bulk_insert_entries(self.id, entries, first)
	end

	def fetch_roots
		Certificate.bulk_insert(client.get_roots).each do |c|
			# Since we know these are roots, we should self-ref the
			# issuer
			c.issuer = c
			c.save

			self.add_root(c)
		end
	end

	# Return a Data Access Interface (as used by MerkleHashTree) for this
	# log.
	#
	def dai
		DAI.new(self)
	end

	private

	def client
		@client ||= CT::Client.new(base_url, public_key: public_key)
	end
end
