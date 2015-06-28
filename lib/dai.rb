if ENV["REDIS_URL"]
	require 'redis'
end

class DAI
	def initialize(log)
		@log = log

		if ENV["REDIS_URL"]
			@redis = Redis.new(:url => ENV["REDIS_URL"])
		end
	end

	def [](ordinal)
		@log.entries_dataset.where(:ordinal => ordinal).first.leaf_input
	end

	def length
		@log.entries_dataset.order(Sequel.desc(:ordinal)).limit(1).first.ordinal + 1
	end

	def mht_cache_set(k, v)
		@redis && @redis.set(cache_key(k), v)
	end

	def mht_cache_get(k)
		if @redis && val = @redis.get(cache_key(k))
			val.force_encoding("BINARY")
		end
	end

	private

	def cache_key(k)
		"ctmonitor:mht:#{@log.id}:#{k}"
	end
end
