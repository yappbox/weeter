require 'twitter/json_stream'
require 'multi_json'

module Weeter
  module Twitter
    class TweetConsumer
      extend ::Forwardable
      TRACK_LIMIT = 400
      FOLLOW_LIMIT = 5000

      attr_reader :limiter, :notifier
      def_delegators :@notifier, :notify_missed_tweets,
                                 :notify_rate_limiting_initiated,
                                 :delete_tweet,
                                 :publish_tweet

      def initialize(twitter_config, notifier, limiter)
        @config = twitter_config
        @notifier = notifier
        @limiter = limiter
      end

      def connect(filter_params)
        filter_params = limit_filter_params(filter_params)
        filter_params = clean_filter_params(filter_params)


        connect_options = {
          ssl:    true,
          params: filter_params,
          method: 'POST'
        }.merge(@config.auth_options)

        Weeter.logger.info("Connecting to Twitter stream...")
        @stream = ::Twitter::JSONStream.connect(connect_options)

        @stream.each_item do |item|
          begin
            tweet_item = TweetItem.new(MultiJson.decode(item))

            if tweet_item.limit_notice?
              notify_missed_tweets(tweet_item)
            elsif tweet_item.deletion?
              delete_tweet(tweet_item)
            elsif tweet_item.publishable?
              publish_or_rate_limit(tweet_item)
            else
              ignore_tweet(tweet_item)
            end
          rescue => ex
            Weeter.logger.error("Twitter stream tweet exception: #{ex.class.name}: #{ex.message} #{tweet_item.to_json}")
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
        @stream.unbind
        connect(filter_params)
      end

    protected

      def limit_filter_params(params)
        result = params.clone
        result.default = []

        follow_count = result['follow'].length
        track_count = result['track'].length

        if follow_count > FOLLOW_LIMIT
          Weeter.logger.error("Twitter Subscriptions include #{follow_count} follows, but are limited to #{FOLLOW_LIMIT}")
          result['follow']  = result['follow'][0...FOLLOW_LIMIT]
        end

        if track_count > TRACK_LIMIT
          Weeter.logger.error("Twitter Subscriptions include #{track_count} tracks, but are limited to #{TRACK_LIMIT}")
          result['track']  = result['track'][0...TRACK_LIMIT]
        end

        result
      end

      def clean_filter_params(p)
        return {} if p.nil?
        cleaned_params = {}
        cleaned_params['follow'] = p['follow'] if (p['follow'] || []).any?
        cleaned_params['follow'] = cleaned_params['follow'].map(&:to_i) if cleaned_params['follow']
        cleaned_params['track'] = p['track'] if (p['track'] || []).any?
        cleaned_params
      end

      def ignore_tweet(tweet_item)
        return if tweet_item.disconnect_notice?
        id = tweet_item['id_str']
        text = tweet_item['text']
        user = tweet_item['user']
        user_id = user['id_str'] if user
        Weeter.logger.info("Ignoring tweet #{id} from user #{user_id}: #{text}")
      end

      def rate_limit_tweet(tweet_item)
        id = tweet_item['id_str']
        text = tweet_item['text']
        user_id = tweet_item['user']['id_str']

        Weeter.logger.info("Rate Limiting tweet #{id} from user #{user_id}: #{text}")
      end

      def publish_or_rate_limit(tweet_item)
        limit_result = limiter.process(*tweet_item.limiting_facets)
        case limit_result.status
        when Weeter::Limitator::INITIATE_LIMITING
          notify_rate_limiting_initiated(tweet_item, limit_result.limited_keys)
          rate_limit_tweet(tweet_item)
        when Weeter::Limitator::CONTINUE_LIMITING
          rate_limit_tweet(tweet_item)
        when Weeter::Limitator::DO_NOT_LIMIT
          publish_tweet(tweet_item)
        end
      end
    end
  end
end
