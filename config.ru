require "rubygems"
require "bundler/setup"

require 'eventmachine'
require 'ruby-debug'

$:.unshift File.expand_path("../lib", __FILE__)
require 'weeter'

# EM.run do
  module Weeter
    class App

      def initialize
        @configuration_file = File.expand_path("../weeter.conf", __FILE__)
        load @configuration_file
        Weeter.logger.info("Starting weeter with configuration: #{ClientAppConfiguration.instance.inspect}")
    
        EM.next_tick do
          client_app_proxy.get_initial_filters do |filter_params|
            tweet_consumer.connect(filter_params)
          end
        end
      end

      def client_app_proxy
        @client_app_proxy ||= Weeter::ClientAppProxy.new(ClientAppConfiguration.instance)
      end

      def tweet_consumer
        @tweet_consumer ||= Weeter::TweetConsumer.new(TwitterConfiguration.instance, client_app_proxy)
      end

      def call(env)
        EM.next_tick do
          Weeter.logger.info("Reconnecting Twitter stream")
          req = Rack::Request.new(env)
          filter_params = JSON.parse(req.body.read)
          tweet_consumer.reconnect(filter_params)
          env['async.callback'].call([200, {}, ["OK"]])
        end
  
        # signal to the server that we are sending an async response
        throw :async
      end
    end
  end

  run Weeter::App.new
# end
