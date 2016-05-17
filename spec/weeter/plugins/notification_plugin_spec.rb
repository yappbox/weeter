require 'spec_helper'

module Weeter
  module Plugins
    describe NotificationPlugin do
      describe "#publish_tweet" do
        it "delegates to the configured plugin" do
          client_app_config = Hashie::Mash.new(:notification_plugin => :http)
          tweet_item = TweetItem.new({})

          mock_plugin = double(Notification::Http)
          expect(Notification::Http).to receive(:new).and_return(mock_plugin)

          expect(mock_plugin).to receive(:publish_tweet).with(tweet_item)

          plugin = NotificationPlugin.new(client_app_config)
          plugin.publish_tweet(tweet_item)
        end
      end
    end
  end
end
