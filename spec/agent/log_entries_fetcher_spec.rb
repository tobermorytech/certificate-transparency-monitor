require_relative '../spec_helper'
require 'agent/log_entries_fetcher'

describe LogEntriesFetcher do
	let(:log) { load(:tree_head); load(:log__first) }

	before :each do
		log
		load(:log_entries)
		@stub = quick_stub(:get_log_entries_from_first_ok, 2, 49)
	end

	context "when it gets a 'need entries' message" do
		let(:go) do
			LogEntriesFetcher.amqp_receive(
			  "ctmonitor.log.need_entries",
			  %({"log_id":"#{log.id}","first":2,"last":4})
			)
		end

		it "makes the request" do
			go

			expect(@stub).to have_been_requested
		end

		it "publishes the newly fetched entries" do
			JSON.parse(read_fixture_file("three_entries.json"))["entries"].each do |entry|
				expect(LogEntriesFetcher.new_log_entry)
				  .to receive(:publish) do |entry_json|
					entry_data = JSON.parse(entry_json)
					expect(entry_data["leaf_input"]).to eq(entry["leaf_input"])
					expect(entry_data["extra_data"]).to eq(entry["extra_data"])
					expect(entry_data["id"]).to match(/^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$/)
				end
			end

			go
		end

		context "the database" do
			let(:db_entries) do
				go; LogEntry.dataset.where(:log_id => log.id, :ordinal => (2..4)).order(:ordinal)
			end

			it "adds three entries" do
				expect(db_entries.count).to eq(3)
			end

			it "puts the first one first" do
				expect(Digest::MD5.hexdigest(db_entries.first.leaf_input))
				  .to eq("98a4e784d2ed3abfaeeb7c930bba8542")
			end

			it "puts the last one last" do
				expect(Digest::MD5.hexdigest(db_entries.last.leaf_input))
				  .to eq("e4e7f5e0b9b112d7b57a89816a9c1601")
			end
		end

		it "broadcasts that it has fetched some entries" do
			expect(LogEntriesFetcher.fetched)
			  .to receive(:publish)
			  .with(%({"log_id":"#{load(:log__first).id}","first":2,"last":4,"added":3}))

			go
		end
	end
end
