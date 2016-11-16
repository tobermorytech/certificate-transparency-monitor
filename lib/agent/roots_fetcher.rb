require_relative '../init'
require 'brown'

require 'model/log'

class RootsFetcher < Brown::Agent
	amqp_publisher :new_cert,
	               amqp_url: ENV["AMQP_URL"] || "amqp://localhost",
	               exchange_name: "ctmonitor.certificate.new",
	               exchange_type: :fanout,
	               type: "certificate-v1"
	every 86400 do
		logger.debug { "Doing a round of root fetches" }
		Log.where(inactive: false).each do |log|
			begin
				log.fetch_roots.each do |new_root|
					new_cert.publish(
						{
							:id => [new_root.id].pack("m0"),
							:der => [new_root.x509.to_der].pack("m0")
						}.to_json
					)
				end

				logger.debug { "Fetch completed; log #{log.name} has #{log.roots.size} roots" }
			rescue StandardError => ex
				logger.warn { "Failed to fetch roots for #{log.base_url}: #{ex.message} (#{ex.class})" }
				logger.info { ex.backtrace.map { |l| "    #{l}" }.join("\n") }
			end
		end
	end
end
