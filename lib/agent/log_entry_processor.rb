require_relative '../init'
require 'brown'

require 'model/log_entry'

class LogEntryProcessor < Brown::Agent
	amqp_publisher :new_cert,
	               amqp_url: ENV["AMQP_URL"] || "amqp://localhost",
	               exchange_name: "ctmonitor.certificate.new",
	               exchange_type: :fanout,
	               type: "certificate-v1"

	memo(:last_message) { [Time.at(0)] }

	every(60) do
		last_message do |lm|
			if lm[0] + 30 < Time.now
				logger.debug { "No messages received recently; looking for old log entries" }

				LogEntry.db.transaction do
					le_list = LogEntry.where(:certificate_id => nil).limit(1000).for_update

					le_list.each do |le|
						logger.debug { "Processing log entry #{le.ordinal} of log #{le.log.name}" }

						process_log_entry(le)
					end
				end
			end
		end
	end

	amqp_listener "ctmonitor.log_entries.new_entry",
	              concurrency: 20,
	              amqp_url: ENV["AMQP_URL"] || "amqp://localhost" do |msg|
		begin
			data = JSON.parse(msg.payload)
			le = LogEntry[data["id"]]

			logger.debug { "Processing log entry #{le.id}" }

			if le.certificate.nil?
				process_log_entry(le)
			end

			logger.debug { "Done" }

			last_message do |lm|
				lm[0] = Time.now
			end
		ensure
			msg.ack
		end
	end

	private

	def process_log_entry(le)
		if le.mtl.leaf_type != :timestamped_entry
			raise RuntimeError,
			      "Unknown leaf_type: #{le.mtl.leaf_type}"
		end

		te = le.mtl.timestamped_entry

		x509_cert = case te.entry_type
			when :x509_entry
				te.x509_entry
			when :precert_entry
				le.precertificate
			else
				raise RuntimeError,
				      "Unknown TimestampedEntry entry type: #{te.entry_type}"
			end

		cert = Certificate.find_by_x509(x509_cert)

		if cert.nil?
			cert = store_chain(le.chain.dup.unshift(x509_cert))
		end

		le.certificate = cert
		le.save
	end

	def store_chain(chain)
		return nil if chain.empty?

		issuer_cert = if chain.length == 1
			nil
		else
			Certificate.find_by_x509(chain[1]) || store_chain(chain[1..-1])
		end

		Certificate.create(
			:der => chain.first.to_der,
			:issuer => issuer_cert
		).tap do |cert|
			new_cert.publish(
				{
					:id => [cert.id].pack("m0"),
					:der => [cert.x509.to_der].pack("m0")
				}.to_json
			)
		end
	end
end
