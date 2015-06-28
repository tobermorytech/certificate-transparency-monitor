require 'spec_helper'
require 'model/log_entry'
require 'model/certificate'

describe Certificate do
	context "existing" do
		let(:cert) { load(:log_entry__cert1_first); load(:certificate__first) }

		it "has one or more log entries" do
			expect(cert.log_entries.length).to be >= 1
		end

		it "has a subject" do
			expect(cert.subject).to be_a(OpenSSL::X509::Name)
		end

		it "has a subjectAltName list" do
			expect(cert.subject_alt_names).to be_an(Array)
		end
	end

	context "creating a new object" do
		let(:cert) do
			Certificate.new(:der => read_fixture_file("cert_der"))
		end

		it "saves without error" do
			expect(cert.save).to eq(cert)
		end
	end
end
