require_relative '../init'
require 'brown'

require 'model/log'

class LogEntriesFetcher < Brown::Agent
	amqp_publisher :fetched,
	               amqp_url: ENV["AMQP_URL"] || "amqp://localhost",
	               exchange_name: "ctmonitor.log_entries.fetched",
	               exchange_type: :fanout,
	               type: "log-entries-fetched-v1"

	amqp_publisher :new_log_entry,
	               amqp_url: ENV["AMQP_URL"] || "amqp://localhost",
	               exchange_name: "ctmonitor.log_entries.new_entry",
	               exchange_type: :fanout,
	               type: "log-entry-v1"

	amqp_listener "ctmonitor.log.need_entries",
	              concurrency: 20,
	              amqp_url: ENV["AMQP_URL"] || "amqp://localhost" do |msg|
		begin
			body = JSON.parse(msg.payload)
			log = Log[body['log_id']]

			logger.debug { "Need entries starting from #{body['first']} for log #{log.name}" }

			if body['first'] < log.newest_tree_head.size
				new_entries = log.fetch_entries(body['first'], log.newest_tree_head.size - 1)

				unless new_entries.empty?
					body['added'] = new_entries.length
					body['last']  = new_entries.last.ordinal
					logger.debug { "Added #{new_entries.length} entries to log #{log.name}" }
					fetched.publish(body.to_json)
					new_entries.each do |entry|
						new_log_entry.publish(entry.to_json)
					end
				end
			end
		rescue StandardError => ex
			logger.warn { "Failed to fetch entries from #{body['first']} from log #{log.name}: #{ex.message} (#{ex.class})" }
		end

		msg.ack
	end
end
