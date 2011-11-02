module Weeter
  module Plugins
    module Notification
      class Http
        def initialize(client_app_config)
          @config = client_app_config
        end

        def publish_tweet(tweet_item)
          id = tweet_item['id_str']
          text = tweet_item['text']
          user_id = tweet_item['user']['id_str']
          Weeter.logger.info("Publishing tweet #{id} from user #{user_id}: #{text}")
          Weeter::Plugins::Net::OauthHttp.post(@config, @config.publish_url, {:id => id, :text => text, :twitter_user_id => user_id})
        end

        def delete_tweet(tweet_item)
          id = tweet_item['delete']['status']['id'].to_s
          user_id = tweet_item['delete']['status']['user_id'].to_s
          Weeter.logger.info("Deleting tweet #{id} for user #{user_id}")
          Weeter::Plugins::Net::OauthHttp.delete(@config, @config.delete_url, {:id => id, :twitter_user_id => user_id})
        end
      end
    end
  end
end