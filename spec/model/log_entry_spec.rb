require_relative '../spec_helper'
require 'model/log_entry'

describe LogEntry do
	let(:entry) { load(:certificate__first); load(:log_entry__cert1_first) }
	let(:log)   { load(:log__first) }

	it "has a log" do
		expect(entry.log.id).to eq(log.id)
	end

	it "has a certificate" do
		expect(entry.certificate).to be_a(Certificate)
	end
end
