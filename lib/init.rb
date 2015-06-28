$LOAD_PATH.unshift(__dir__)

require 'sequel'
require 'logger'

Sequel.database_timezone = :utc

db_logger = Logger.new($stderr)
db_logger.formatter = proc { |s, d, p, m| "[#{s}] #{m}\n" }
db_logger.level = ENV['DEBUG_SQL'] ? Logger::DEBUG : Logger::WARN

app_name = case $0
	when /brown/
		ARGV[0].split('/').last
	when /puma/
		"webapp:#{ENV['PORT']}"
	else
		$0
	end

DB_URL = ENV["DATABASE_URL"] || "postgres:///ctmonitor_development"
DB = Sequel.connect(
	DB_URL,
	:loggers => [db_logger],
	:max_connections => 20,
	:after_connect => proc do |conn|
		conn.execute("SET application_name TO '#{app_name}'")
	end
)

APP_ROOT = File.expand_path("../..", __FILE__)
