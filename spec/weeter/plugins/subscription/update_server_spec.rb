require 'spec_helper'
module Weeter
  module Plugins
    module Subscription
      describe Http::UpdateServer do
        before(:each) do
          @new_ids = [1,2,3]
          @tweet_consumer = double('TweetConsumer', :reconnect => nil)
          @tweet_server = Http::UpdateServer.new(nil)
          @tweet_server.instance_variable_set('@http_post_content', MultiJson.encode(@new_ids))
          @tweet_server.tweet_consumer = @tweet_consumer
          @response = double('DelegatedHttpResponse', :send_response => nil)
          expect(EM::DelegatedHttpResponse).to receive(:new).and_return(@response)
        end

        after(:each) do
          @tweet_server.process_http_request
        end

        it "processes http request" do
          expect(@tweet_consumer).to receive(:reconnect).with(@new_ids)
        end

        it "sends the response" do
          expect(@response). to receive(:send_response)
        end
      end
    end
  end
end
