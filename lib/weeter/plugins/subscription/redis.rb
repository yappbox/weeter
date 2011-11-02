module Weeter
  module Plugins
    module Subscription
      class Redis
        def initialize(client_app_config)
          @config = client_app_config
        end

        def get_initial_filters(&block)
        end

        def listen_for_filter_update(tweet_consumer)
        end
      end
    end
  end
end