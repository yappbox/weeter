require 'twitter/json_stream'
require 'multi_json'

module Weeter
  module Twitter
    class TweetConsumer

      attr_reader :limiter

      def initialize(twitter_config, notifier, limiter)
        @config = twitter_config
        @notifier = notifier
        @limiter = limiter
      end

      def connect(filter_params)
        filter_params = clean_filter_params(filter_params)
        connect_options = {:ssl => true, :params => filter_params, :method => 'POST'}.merge(@config.auth_options)
        @stream = ::Twitter::JSONStream.connect(connect_options)

        @stream.each_item do |item|
          begin
            tweet_item = TweetItem.new(MultiJson.decode(item))

            if tweet_item.deletion?
              @notifier.delete_tweet(tweet_item)
            elsif tweet_item.publishable?
              if limiter.limit?(*tweet_item.limiting_facets)
                rate_limit_tweet(tweet_item)
              else
                @notifier.publish_tweet(tweet_item)
              end
            else
              ignore_tweet(tweet_item)
            end
          rescue => ex
            Weeter.logger.error("Twitter stream tweet exception: #{ex.class.name}: #{ex.message}")
          end
        end

        @stream.on_error do |msg|
          Weeter.logger.error("Twitter stream error: #{msg}. Connect options were #{connect_options.inspect}")
        end

        @stream.on_max_reconnects do |timeout, retries|
          Weeter.logger.error("Twitter stream max-reconnects reached: timeout=#{timeout}, retries=#{retries}")
        end
      end

      def reconnect(filter_params)
        @stream.stop
        connect(filter_params)
      end

    protected

      def clean_filter_params(p)
        return {} if p.nil?
        cleaned_params = {}
        cleaned_params['follow'] = p['follow'] if (p['follow'] || []).any?
        cleaned_params['follow'] = cleaned_params['follow'].map(&:to_i)
        cleaned_params['track'] = p['track'] if (p['track'] || []).any?
        cleaned_params
      end

      def ignore_tweet(tweet_item)
        id = tweet_item['id_str']
        text = tweet_item['text']
        user_id = tweet_item['user']['id_str']
        Weeter.logger.info("Ignoring tweet #{id} from user #{user_id}: #{text}")
      end

      def rate_limit_tweet(tweet_item)
        id = tweet_item['id_str']
        text = tweet_item['text']
        user_id = tweet_item['user']['id_str']

        Weeter.logger.info("Rate Limiting tweet #{id} from user #{user_id}: #{text}")
      end
    end
  end
end
