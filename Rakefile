exec(*(["bundle", "exec", $PROGRAM_NAME] + ARGV)) if ENV['BUNDLE_GEMFILE'].nil?

begin
	Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
	$stderr.puts e.message
	$stderr.puts "Run `bundle install` to install missing gems"
	exit e.status_code
end

task :environment do
	require_relative 'lib/init'
end

desc "Migrate schema of DATABASE_URL"
task :migrate_db => :environment do
	sh "sequel #{DB_URL} -m db/migrate"
end

desc "Load all fixtures into DATABASE_URL"
task :load_fixtures => :environment do
	require 'fixture_dependencies'
	Dir["lib/model/*.rb"].each { |f| require "./#{f}" }
	FixtureDependencies.fixture_path = File.expand_path('../spec/fixtures', __FILE__)
	FixtureDependencies.load(*Dir["spec/fixtures/*.yml*"].map { |f| File.basename(f).gsub(/\.yml(\.erb)?$/, '').to_sym })
end

begin
	require 'rspec/core/rake_task'
rescue LoadError
	puts "RSpec not found; no testing for you!"
else
	task :test_env do
		ENV["DATABASE_URL"] = "postgres:///ctmonitor_test"
	end

	RSpec::Core::RakeTask.new :test => [:test_env, :environment, :migrate_db] do |t|
		t.pattern = "spec/**/*_spec.rb"
	end

	task :spec => :test

	desc "Run guard"
	task :guard => [:test_env, :environment, :migrate_db] do
		require 'guard/cli'
		::Guard::CLI.start(%w{--clear})
		while ::Guard.running do
			sleep 0.5
		end
	end
end
