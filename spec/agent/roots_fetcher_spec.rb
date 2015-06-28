require_relative '../spec_helper'
require 'agent/roots_fetcher'

describe RootsFetcher do
	let(:log) { load(:log__first) }

	let(:orig_roots) { log.roots }

	let(:new_roots) do
		orig_roots
		RootsFetcher.trigger(86400)
		log.reload
		log.roots - orig_roots
	end

	context "retrieving the same set of roots" do
		before :each do
			load(:log__first)
			load(:certificates)
			@stub = quick_stub(:get_roots_from_first_ok)
		end

		it "retrieves the roots every day" do
			RootsFetcher.trigger(86400)

			expect(@stub).to have_been_requested
		end

		it "doesn't change anything" do
			orig_roots_ids = orig_roots.map(&:id).sort

			RootsFetcher.trigger(86400)

			log.reload

			expect(log.roots.map(&:id).sort).to eq(orig_roots_ids)
		end
	end

	context "retrieving a set of roots with a new one" do
		before :each do
			load(:log__first)
			@stub = quick_stub(:get_new_roots_from_first_ok)
		end

		it "retrieves the roots every day" do
			RootsFetcher.trigger(86400)

			expect(@stub).to have_been_requested
		end

		it "adds a new root to the list of roots" do
			expect(new_roots.length).to eq(1)
		end

		it "identifies the correct one as the new one" do
			expect(new_roots.first.subject.to_s).to match(/CFCA/)
		end

		it "points the issuer ID to itself" do
			expect(new_roots.first.issuer).to eq(new_roots.first)
		end

		it "announces that the new cert exists" do
			expect(RootsFetcher.new_cert)
			  .to receive(:publish) do |msg|
				msg = JSON.parse(msg)
				expect(msg["id"])
				  .to eq("B3GSDIy4dNXFpNwNalGi1JXTjE3izVuD0qBvqgUZNfY=")
				expect(msg["der"]).to eq(<<-EOF.gsub(/\s+/, ''))
					MIIDHzCCAgegAwIBAgIEGZk8PzANBgkqhkiG9w0BAQUFADAiMQswCQYDVQQGEw
					JDTjETMBEGA1UEChMKQ0ZDQSBHVCBDQTAeFw0xMTA2MTMwODE1MDlaFw0yNjA2
					MDkwODE1MDlaMCIxCzAJBgNVBAYTAkNOMRMwEQYDVQQKEwpDRkNBIEdUIENBMI
					IBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAv3PGWiuMePZYt/zSF5Cl
					K3TsgSyTzVLMbuQqyyShMeStMG7jmCIx1yGbn9UPNy9auziit3kmZ9YNxRcqnL
					lUBOENdYZu2MzFgGcbyIwtACaGPHp5Prapwk4gsDeXxoV2EoIK51S7i/49ruPs
					a1hD9qU361iivZDE5fvKa8owbLd7ifYx0oz/T8KWJUOpcTUlCxjhrMijJLZxk4
					zxXfycEAV7/8Bb4LGXrR/Y/kX1wB+dW0c5HAb622aF2yQj6nvSOSD46yqyGlHz
					lFooAk6nXEduz/zZ6OZhWhYnxxUNmNno0wM1kCnfsi+NEHcjyLh60xFhavP/gZ
					Kl7EJLaE6A1wIDAQABo10wWzAfBgNVHSMEGDAWgBSMdlDOJdN5Kzz0bZ2a4Z4F
					T+g9JTAMBgNVHRMEBTADAQH/MAsGA1UdDwQEAwIBxjAdBgNVHQ4EFgQUjHZQzi
					XTeSs89G2dmuGeBU/oPSUwDQYJKoZIhvcNAQEFBQADggEBAL67lljU3YmJDyzN
					+mNFdg05gJqN+qhFYT0hVejOaMcZ6cKxB8KLOy/PYYWQp1IXMjqvCgUVyMbO3Y
					6UJgb40GDus27UDbpa3augfFByptWQk1bXWTnb6H+zlXhTgVJSX/SSgQLB+yK5
					0QNXp37L+8BGvBN0TCgrdpJpH8FQkRHFTN4LlIwXg4yvN4e06mtvolo1QWGFL5
					wXwPu5DqJhBkd2vJAJmHQN0ggvveQNcvGmX8N8wH3qvNOrIJHLXAWMnag1+jZW
					uwnzhF3W8eIsntl+8YKg4bcvfu35e6AAuLLeHXnhgfNSWZoUXefCEfOawzp4I7
					5OZt6kOWnymDosCgA=
				EOF
			end

			new_roots
		end
	end
end
