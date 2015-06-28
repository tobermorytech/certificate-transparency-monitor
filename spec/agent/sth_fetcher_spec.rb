require_relative '../spec_helper'
require 'agent/sth_fetcher'

describe STHFetcher do
	def log
		Log[load(:log__first).id]
	end

	context "with a valid STH" do
		before :each do
			load(:log__first)
			@stub = quick_stub(:get_sth_from_first_ok)
		end

		it "retrieves a log every minute" do
			STHFetcher.trigger(60)

			expect(@stub).to have_been_requested
		end

		it "broadcasts that it has fetched an STH" do
			expect(STHFetcher.fetched)
			  .to receive(:publish)
			  .with(%({"log_id":"#{load(:log__first).id}","size":10825,"timestamp":"2015-05-29T02:57:08Z"}))

			STHFetcher.trigger(60)
		end
	end

	context "with an STH with an invalid sig" do
		before :each do
			load(:log__first)
			@stub = quick_stub(:get_sth_from_first_invalid_sig)
		end

		it "doesn't broadcast that it has fetched an STH" do
			expect(STHFetcher.fetched)
			  .to_not receive(:publish)

			STHFetcher.trigger(60)
		end

		it "adds an error to the log" do
			err_count = log.errors.count

			STHFetcher.trigger(60)

			expect(log.errors.count).to eq(err_count+1)
		end

		it "adds the STH to the database" do
			sth_count = log.tree_heads.count

			STHFetcher.trigger(60)

			expect(log.tree_heads.count).to eq(sth_count+1)
		end

		let(:error) { log.errors.last }

		it "describes the error" do
			STHFetcher.trigger(60)

			expect(error.details).to eq("Invalid signature")
		end

		it "links the error to the STH" do
			STHFetcher.trigger(60)

			expect(error.tree_head.id).to eq(log.tree_heads.last.id)
		end
	end
end
