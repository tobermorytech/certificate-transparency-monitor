require_relative '../spec_helper'
require 'agent/tree_head_hash_verifier'

describe TreeHeadHashVerifier do
	let(:log) { load(:log_entry); load(:tree_head); load(:log__first) }

	before :each do
		log
	end

	context "when it gets an 'entries fetched' message" do
		let(:go) do
			TreeHeadHashVerifier.amqp_receive(
			  "ctmonitor.log_entries.fetched",
			  %({"log_id":"#{log.id}","last":1})
			)
		end

		let(:correct_head) do
			go; load(:tree_head__not_verified_hash_correct_first)
		end

		let(:fuxxed_head) do
			go; load(:tree_head__not_verified_hash_fuxxed_first)
		end

		let(:unverified_head) do
			go; load(:tree_head__large_first)
		end

		it "doesn't verify the overly-large tree head" do
			expect(unverified_head.hash_correct).to eq(nil)
		end

		it "correctly verifies the head with the correct hash" do
			expect(correct_head.hash_correct).to eq(true)
		end

		it "correctly fails to verify the head with the incorrect hash" do
			expect(fuxxed_head.hash_correct).to eq(false)
		end
	end
end
