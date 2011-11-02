require 'weeter/plugins/notification/http'
require 'weeter/plugins/notification/resque'

require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/module/delegation'

module Weeter
  module Plugins
    class NotificationPlugin
      delegate :publish_tweet, :to => :configured_plugin
      delegate :delete_tweet, :to => :configured_plugin
      
      def initialize(client_app_config)
        @config = client_app_config
      end
      
    protected
      def configured_plugin
        @configured_plugin ||= begin
          Weeter.logger.info("Using #{@config.notification_plugin} notification plugin")
          Notification.const_get(@config.notification_plugin.to_s.camelize).new(@config)
        end
      end
    end
  end
end