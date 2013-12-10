require "singleton"
require 'hashie'

module Weeter
  class Configuration
    class ClientAppConfig < Hashie::Mash
      InvalidConfiguration = Class.new(StandardError)
      def subscription_updates_port
        self['subscription_updates_port'] || 7337
      end

      def redis_namespace
        self['redis_namespace'] || raise(InvalidConfiguration, 'missing `redis-namespace` config')
      end
    end
  end
end
