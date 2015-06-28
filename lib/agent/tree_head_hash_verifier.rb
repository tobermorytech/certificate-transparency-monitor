require_relative '../init'
require 'brown'
require 'merkle-hash-tree'

require 'model/log'
require 'model/tree_head'

class TreeHeadHashVerifier < Brown::Agent
	amqp_listener "ctmonitor.log_entries.fetched",
	              amqp_url: ENV["AMQP_URL"] || "amqp://localhost" do |msg|
		begin
			body = JSON.parse(msg.payload)
			log = Log[body['log_id']]

			logger.debug { "Verifying heads for log #{log.name} smaller than #{body['last'] + 1}" }

			heads = log.tree_heads_dataset.where{size <= body['last'] + 1}.and(:hash_correct => nil)

			logger.debug { "#{heads.count} heads need to be verified" }

			heads.each do |head|
				tree = MerkleHashTree.new(log.dai, Digest::SHA256)

				head.hash_correct = tree.head(0..head.size - 1) == head.root_hash
				head.save
			end
		ensure
			msg.ack
		end
	end
end
