require 'em-hiredis'

module Weeter
  module Plugins
    module Net
      module Redis
        def create_redis_client
          @redis ||= begin
            redis = EM::Hiredis.connect(@config.redis_uri)
            redis.callback { Weeter.logger.info "Connected to Redis" }
            redis
          end
        end
      end
    end
  end
end