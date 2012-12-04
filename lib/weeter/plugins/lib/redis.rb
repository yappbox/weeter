require 'em-hiredis'

module Weeter
  module Plugins
    module Net
      module Redis
        def create_redis_client
          redis = EM::Hiredis.connect(@config.redis_uri)
          redis.callback { Weeter.logger.info "Connected to Redis" }
          redis.errback { |message| Weeter.logger.err "Failed to connect to Redis: #{message}" }
          redis
        end
      end
    end
  end
end
