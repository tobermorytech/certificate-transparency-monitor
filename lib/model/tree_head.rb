require 'certificate-transparency'

require 'model/log'

class TreeHead < Sequel::Model
	many_to_one :log

	def before_create
		self.retrieved_at = Time.now
	end

	def valid_sig?
		sth = CT::SignedTreeHead.new
		sth.timestamp = timestamp
		sth.tree_size = size
		sth.root_hash = root_hash
		sth.signature = signature

		sth.valid?(log.public_key)
	end

	def valid_tree?
		hash_correct
	end
end
