require_relative '../spec_helper'
require 'agent/log_entry_processor'

describe LogEntryProcessor do
	def send_message
		LogEntryProcessor.amqp_receive(
			"ctmonitor.log_entries.new_entry",
			le.to_json
		)

		le.reload
	end

	let(:le) { load(:log_entry__real_second) }
	let(:cert_id) do
		["fdd93bb66f098186d8b4296243877eb8d00ca02bb70b613fc33dd5fd9a6aa3f0"].pack("H*")
	end

	let(:cert_as_json) do
		{
			:id  => [cert_id].pack("m0"),
			:der => [le.mtl.timestamped_entry.x509_entry.to_der].pack("m0")
		}.to_json
	end

	before(:each) { load(:certificate__second_issuer) }

	it "looks for unprocessed log entries if we haven't seen a message in a while" do
		expect(LogEntryProcessor)
		  .to receive(:last_message)
		  .and_yield([Time.now - 600])
		expect(LogEntry)
		  .to receive(:where)
		  .with(:certificate_id => nil)
		  .and_call_original

		LogEntryProcessor.trigger(60)
	end

	it "doesn't look in the DB if we've just seen a message" do
		expect(LogEntryProcessor)
		  .to receive(:last_message)
		  .and_yield([Time.now - 5])
		expect(LogEntry)
		  .to_not receive(:where)

		LogEntryProcessor.trigger(60)
	end

	context "for an entry we don't already have a cert for" do
		context "received via message" do
			it "doesn't already have the certificate in the DB" do
				expect(Certificate[cert_id]).to be(nil)
			end

			it "creates the certificate in the DB" do
				send_message

				expect(Certificate[cert_id]).to be_a(Certificate)
			end

			it "links the log entry to the cert" do
				send_message

				expect(le.certificate).to eq(Certificate[cert_id])
			end

			it "tells the world that there's a new certificate" do
				expect(LogEntryProcessor.new_cert)
				  .to receive(:publish)
				  .with(cert_as_json)

				send_message
			end

			it "stores the cert chain" do
				send_message

				expect(Certificate[cert_id].issuer).to_not be(nil)
			end

			it "updates last_message to the current time" do
				send_message

				LogEntryProcessor.last_message do |lm|
					expect(lm[0]).to be_within(0.5).of(Time.now)
				end
			end
		end

		context "found via trigger" do
			it "doesn't already have the certificate in the DB" do
				expect(Certificate[cert_id]).to be(nil)
			end

			it "creates the certificate in the DB" do
				le; LogEntryProcessor.trigger(60)

				expect(Certificate[cert_id]).to_not be_nil
			end

			it "links the log entry to the cert" do
				le; LogEntryProcessor.trigger(60); le.reload

				expect(le.certificate).to eq(Certificate[cert_id])
			end

			it "tells the world that there's a new certificate" do
				expect(LogEntryProcessor.new_cert)
				  .to receive(:publish)
				  .with(cert_as_json)

				le; LogEntryProcessor.trigger(60); le.reload
			end

			it "doesn't update last_message" do
				le; LogEntryProcessor.trigger(60); le.reload

				LogEntryProcessor.last_message do |lm|
					expect(lm[0].to_i).to eq(0)
				end
			end
		end
	end

	context "an entry we already have a cert for" do
		let(:le) { load(:certificate__second); load(:log_entry__real_second) }

		it "attaches the log entry to the existing cert" do
			le; LogEntryProcessor.trigger(60); le.reload

			expect(le.certificate.id).to eq(cert_id)
		end

		it "says nothing about a new cert" do
			expect(LogEntryProcessor.new_cert)
			  .to_not receive(:publish)

			le; LogEntryProcessor.trigger(60); le.reload
		end

		it "doesn't update last_message" do
			le; LogEntryProcessor.trigger(60); le.reload

			LogEntryProcessor.last_message do |lm|
				expect(lm[0].to_i).to eq(0)
			end
		end
	end
end
