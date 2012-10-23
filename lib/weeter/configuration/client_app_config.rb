require "singleton"
require 'hashie'

module Weeter
  class Configuration
    class ClientAppConfig < Hashie::Mash
      def subscription_updates_port
        self['subscription_updates_port'] || 7337
      end
    end
  end
end
