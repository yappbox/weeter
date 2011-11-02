module Weeter
  module Plugins
    module Notification
      class Resque
        def initialize(client_app_config)
          @config = client_app_config
        end

        def publish_tweet(tweet_item)
        end

        def delete_tweet(tweet_item)
        end
      end
    end
  end
end