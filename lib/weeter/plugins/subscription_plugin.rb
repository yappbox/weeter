require 'weeter/plugins/subscription/http'
require 'weeter/plugins/subscription/redis'

require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/module/delegation'

module Weeter
  module Plugins
    class SubscriptionPlugin
      delegate :get_initial_filters, :to => :configured_plugin
      delegate :listen_for_filter_update, :to => :configured_plugin
      
      def initialize(client_app_config)
        @config = client_app_config
      end
    
    protected
      def configured_plugin
        @configured_plugin ||= begin
          Weeter.logger.info("Using #{@config.subscription_plugin} subscription plugin")
          Subscription.const_get(@config.subscription_plugin.to_s.camelize).new(@config)
        end
      end
    end
  end
end