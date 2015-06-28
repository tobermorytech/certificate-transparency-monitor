require_relative '../init'
require 'brown'

require 'model/log'

class LogEntryFetchScheduler < Brown::Agent
	amqp_publisher :need_entries,
	               amqp_url: ENV["AMQP_URL"] || "amqp://localhost",
	               exchange_name: "ctmonitor.log.need_entries",
	               exchange_type: :fanout,
	               type: "need-entries-v1"

	amqp_listener ["ctmonitor.sth.fetched", "ctmonitor.log_entries.fetched"],
	              concurrency: 20,
	              amqp_url: ENV["AMQP_URL"] || "amqp://localhost" do |msg|
		body = JSON.parse(msg.payload)

		log = Log[body['log_id']]

		# log.size can change in real-time; get a copy of it and stick with it
		log_size = log.size

		if log_size < log.newest_tree_head.size
			last_entry_to_fetch = log.newest_tree_head.size - 1
			logger.debug { "scheduling entries #{log_size}-#{last_entry_to_fetch} for log #{log.name}" }
			need_entries.publish(
			  {
			    :log_id => log.id,
			    :first  => log_size,
			    :last   => last_entry_to_fetch
			  }.to_json
			)
		end

		msg.ack
	end
end
