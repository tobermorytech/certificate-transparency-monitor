module ExampleMethods
	def quick_stub(name, *args)
		method       = :get
		status_code  = 200
		content_type = "application/json"
		url          = nil
		body         = nil

		case name
		when :get_sth_from_first_ok
			url  = "http://example.com/first/ct/v1/get-sth"
			body = {
				tree_size: 10825,
				timestamp: 1432868228017,
				sha256_root_hash: "76EVVFH14DcePzgKH+xZrTMn+4jHkwb7YWqQxXBJg7Y=",
				tree_head_signature: "BAMARzBFAiAe5lSujEoImVsvV+XeUuoNw73xaCzwL5/0BNLVwfvpIAIhAJRqKQ5eicBDkCsJPnbkN0vPGH1uINGBhTq5fk5dVJu+"
			}.to_json
		when :get_sth_from_first_invalid_sig
			url  = "http://example.com/first/ct/v1/get-sth"
			body = {
				tree_size: 10825,
				timestamp: 1432868228017,
				sha256_root_hash: "76EVVFH14DcePzgKH+xZrTMn+4jHkwb7YWqQxXBJg7Y=",
				tree_head_signature: "BAMARzBFAiAe5lSujEoImVsvV+XXXXXXXXXxaCzwL5/0BNLVwfvpIAIhAJRqKQ5eicBDkCsJPnbkN0vPGH1uINGBhTq5fk5dVJu+"
			}.to_json
		when :get_log_entries_from_first_ok
			url  = "http://example.com/first/ct/v1/get-entries?start=#{args[0]}&end=#{args[1]}"
			body = read_fixture_file("three_entries.json")
		when :get_roots_from_first_ok
			url  = "http://example.com/first/ct/v1/get-roots"
			body = read_fixture_file("roots")
		when :get_new_roots_from_first_ok
			url  = "http://example.com/first/ct/v1/get-roots"
			body = read_fixture_file("new_roots")
		else
			raise ArgumentError,
			      "Unknown name passed to stub_request: #{name.inspect}"
		end

		stub_request(method, url)
		  .to_return(
			  :body => body,
			  :status => status_code,
			  :headers => {
				 'Content-Length' => body.length,
				 'Content-Type'   => content_type
			  }
		  )
	end

	def fixture_file(f)
		File.expand_path("../fixtures/#{f}", __FILE__)
	end

	def read_fixture_file(f)
		File.read(fixture_file(f))
	end
end
