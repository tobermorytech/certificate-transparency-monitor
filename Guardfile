RSPEC_PORT = rand(50000) + 15000

guard 'spork', :rspec_port => RSPEC_PORT do
	watch('Gemfile')             { :rspec }
	watch('Gemfile.lock')        { :rspec }
	watch('spec/spec_helper.rb') { :rspec }
end

guard 'rspec',
      :cmd            => "rspec --drb --drb-port #{RSPEC_PORT}",
      :all_on_start   => true,
      :all_after_pass => true do
	watch(%r{^spec/.+_spec\.rb$})
	watch(%r{^spec/fixtures/.+\.yml(\.erb)?$})
	watch(%r{^lib/}) { "spec" }
end
