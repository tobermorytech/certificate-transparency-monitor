require_relative '../init'
require 'brown'

require 'model/log'

class STHFetcher < Brown::Agent
	amqp_publisher :fetched,
	               amqp_url: ENV["AMQP_URL"] || "amqp://localhost",
	               exchange_name: "ctmonitor.sth.fetched",
	               exchange_type: :fanout,
	               type: "sth-fetched-v1"

	every 60 do
		logger.debug { "Doing a round of STH fetches" }
		Log.each do |log|
			begin
				sth = log.fetch_sth

				fetched.publish(
				  {
				    :log_id    => sth.log_id,
				    :size      => sth.size,
				    :timestamp => sth.timestamp.strftime("%FT%TZ")
				  }.to_json
				)

				logger.debug { "Fetch completed; log #{log.name} has #{sth.size} entries as of #{sth.timestamp}" }
			rescue StandardError => ex
				logger.warn { "Failed to fetch STH for #{log.base_url}: #{ex.message} (#{ex.class})" }
				logger.info { ex.backtrace.map { |l| "    #{l}" }.join("\n") }
			end
		end
	end
end
