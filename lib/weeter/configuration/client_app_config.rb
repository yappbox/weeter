require "singleton"
require 'hashie'

module Weeter
  class Configuration
    class ClientAppConfig < Hashie::Mash
      DEFAULT_SUBSCRIPTIONS_UPDATE_PORT = 7337
      InvalidConfiguration = Class.new(StandardError)

      def verify_redis_namespace_config
        !!self.redis_namespace || raise(InvalidConfiguration, 'missing `redis-namespace` config')
      end
    end
  end
end
