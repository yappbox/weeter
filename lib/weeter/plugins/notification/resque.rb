module Weeter
  module Plugins
    module Notification
      class Resque
        include Weeter::Plugins::Net::Redis

        def initialize(client_app_config)
          @config = client_app_config
        end

        def publish_tweet(tweet_item)
          resque_job = %Q|{"class":"WeeterPublishTweetJob","args":[#{tweet_item.to_json}],"jid": "#{SecureRandom.hex(12)}"}|
          Weeter.logger.info("Publishing tweet #{tweet_item['id']} from user #{tweet_item['user']['id_str']}: #{tweet_item['text']}")
          enqueue(resque_job)
        end

        def delete_tweet(tweet_item)
          resque_job = %Q|{"class":"WeeterDeleteTweetJob","args":[#{tweet_item.to_json}],"jid": "#{SecureRandom.hex(12)}"}|
          Weeter.logger.info("Deleting tweet #{tweet_item['id']} for user #{tweet_item['user']['id_str']}")
          enqueue(resque_job)
        end

        def notify_missed_tweets(tweet_item)
          resque_job = %Q|{"class":"WeeterMissedTweetsJob","args":[#{tweet_item.to_json}],"jid": "#{SecureRandom.hex(12)}"}|
          Weeter.logger.info("Notifying of missed tweets (#{tweet_item.missed_tweets_count}).")
          enqueue(resque_job)
        end

        def notify_rate_limiting_initiated(tweet_item, limited_keys)
          payload = tweet_item.to_hash.merge(:limited_keys => limited_keys)
          payload_json = MultiJson.encode(payload)
          resque_job = %Q|{"class":"WeeterRateLimitingInitiatedJob","args":[#{payload_json}],"jid": "#{SecureRandom.hex(12)}"}|
          Weeter.logger.info("Initiated rate limiting with tweet: #{payload_json}")
          enqueue(resque_job)
        end

      protected

        def redis
          @redis ||= create_redis_client
        end

        def enqueue(job)
          redis.rpush(queue_key, job)
        end

        def queue_key
          "#{@config.redis_namespace}:#{@config.queue}"
        end
      end
    end
  end
end
