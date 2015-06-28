require_relative  '../spec_helper'
require 'model/log'

describe Log do
	context "first log" do
		let(:log) { load(:log__first) }

		before :each do
			load(:log_entries)
			load(:tree_heads)
			load(:certificates)
		end

		context "fetching an STH" do
			before(:each) do
				quick_stub(:get_sth_from_first_ok)
				log.fetch_sth
			end

			it "is associated with the log" do
				expect(log.tree_heads.length).to eq(6)
			end

			it "has the correct size" do
				expect(log.tree_heads.last.size).to eq(10825)
			end
		end

		it "takes size from the DB" do
			expect(log.size).to eq(2)
		end

		it "gives us the newest tree head" do
			expect(log.newest_tree_head.size).to eq(50)
		end

		it "has roots" do
			expect(log.roots.length).to be > 0
		end
	end

	context "second log" do
		let(:log) { load(:log__second) }

		it "has no entries" do
			expect(log.size).to eq(0)
		end
	end
end
