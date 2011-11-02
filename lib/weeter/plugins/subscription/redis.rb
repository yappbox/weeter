require 'multi_json'

module Weeter
  module Plugins
    module Subscription
      class Redis
        include Weeter::Plugins::Net::Redis
        
        def initialize(client_app_config)
          @config = client_app_config
        end

        def get_initial_filters(&block)
          redis.get(@config.subscriptions_key) do |value|
            if value.nil?
              raise "Expected to find subscription data at redis key #{@config.subscriptions_key}"
            end
            yield MultiJson.decode(value)
          end
        end

        def listen_for_filter_update(tweet_consumer)
          pub_sub_redis.subscribe(@config.subscriptions_changed_channel)
          pub_sub_redis.on(:message) do |channel, message|
            Weeter.logger.info [:message, channel, message]
            Weeter.logger.info("Reconnecting Twitter stream")
            get_initial_filters do |filter_params|
              tweet_consumer.reconnect(filter_params)
            end
          end
        end
        
      protected
        
        def redis
          @redis ||= create_redis_client
        end

        def pub_sub_redis
          @pub_sub_redis ||= create_redis_client
        end
        
      end
    end
  end
end