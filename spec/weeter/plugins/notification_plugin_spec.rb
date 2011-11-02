require 'spec_helper'

module Weeter
  module Plugins
    describe NotificationPlugin do
      describe "#publish_tweet" do
        it "should delegate to the configured plugin" do
          client_app_config = Hashie::Mash.new(:notification_plugin => :http)
          tweet_item = TweetItem.new({})
          
          mock_plugin = mock(Notification::Http)
          Notification::Http.should_receive(:new).and_return(mock_plugin)
          
          mock_plugin.should_receive(:publish_tweet).with(tweet_item)

          plugin = NotificationPlugin.new(client_app_config)
          plugin.publish_tweet(tweet_item)
        end
      end
    end
  end
end
