require 'em-http'

module Weeter
  class Runner

    def initialize(config)
      @config = config
      Weeter.logger.info("Starting weeter with configuration: #{@config.inspect}")
    end

    def start
      EM.run {
        subscription_plugin.get_initial_filters do |filter_params|
          Weeter.logger.info("Connecting to twitter with initial filters")
          tweet_consumer.connect(filter_params)
          subscription_plugin.listen_for_filter_update(tweet_consumer)

          trap('TERM') do
            Weeter.logger.info("Stopping weeter")
            EM.stop if EM.reactor_running?
          end
        end
      }
    end

  protected

    def limiter
      @limiter ||= if @config.limiter.enabled
        Weeter::Limitator.new({
          max:      @config.limiter.max,
          duration: @config.limiter.duration
        })
      else
        Weeter::Limitator::UNLIMITED
      end
    end

    def notification_plugin
      @notification_plugin ||= Weeter::Plugins::NotificationPlugin.new(@config.client_app)
    end

    def subscription_plugin
      @subscription_plugin ||= Weeter::Plugins::SubscriptionPlugin.new(@config.client_app)
    end

    def tweet_consumer
      @tweet_consumer ||= Weeter::Twitter::TweetConsumer.new(@config.twitter, notification_plugin, limiter, @config.subscriptions_limit)
    end
  end
end
