require 'spork'
require 'json'

Spork.prefork do
	require_relative '../lib/init'
	require 'bundler'
	Bundler.setup(:default, :development)
	require 'extlib'
	require 'rspec/core'
	require 'rspec/mocks'
	require 'pry-byebug'
	require 'webmock/rspec'

	require 'fixture_dependencies'

	FixtureDependencies.fixture_path = File.expand_path("../fixtures", __FILE__)

	RSpec.configure do |config|
		config.fail_fast = true
		config.order = :random
#		config.full_backtrace = true

		config.expect_with :rspec do |c|
			c.syntax = :expect
		end
	end
end

Spork.each_run do
	require_relative 'example_methods'
	require_relative 'example_group_methods'

	RSpec.configure do |config|
		config.include ExampleMethods
		config.extend  ExampleGroupMethods
	end

	require 'fixture_dependencies/rspec/sequel'

	require 'brown/rspec'

	FileUtils.mkdir_p("#{APP_ROOT}/tmp")
	File.unlink("#{APP_ROOT}/tmp/brown.log") rescue nil
	Brown::Agent.logger = Logger.new("#{APP_ROOT}/tmp/brown.log")
	Brown::Agent.logger.level = Logger::DEBUG
end
