require_relative '../spec_helper'
require 'agent/log_entry_fetch_scheduler'

describe LogEntryFetchScheduler do
	let(:log) { load(:log__first) }

	before :each do
		load(:log_entry)
		load(:tree_heads)
	end

	context "receiving messages from STHFetcher" do
		let(:go) do
			LogEntryFetchScheduler.amqp_receive(
			  "ctmonitor.sth.fetched",
			  %({"log_id":"#{log.id}","size":123,"timestamp":"2361-03-21T19:15:01Z"})
			)
		end

		it "spews out the right download request" do
			expect(LogEntryFetchScheduler.need_entries)
			  .to receive(:publish)
			  .with(%({"log_id":"#{log.id}","first":2,"last":49}))

			go
		end
	end

	context "receiving messages from LogEntriesFetcher" do
		let(:go) do
			LogEntryFetchScheduler.amqp_receive(
			  "ctmonitor.log_entries.fetched",
			  %({"log_id":"#{log.id}","first":0,"last":0})
			)
		end

		it "spews out the right download request" do
			expect(LogEntryFetchScheduler.need_entries)
			  .to receive(:publish)
			  .with(%({"log_id":"#{log.id}","first":2,"last":49}))

			go
		end
	end
end
