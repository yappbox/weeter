require 'spec_helper'

module Weeter
  module Plugins
    describe SubscriptionPlugin do
      describe "#get_initial_filters" do
        it "should delegate to the configured plugin" do
          client_app_config = Hashie::Mash.new(:subscription_plugin => :http)
          
          mock_plugin = mock(Subscription::Http)
          Subscription::Http.should_receive(:new).and_return(mock_plugin)
          
          mock_plugin.should_receive(:get_initial_filters).and_yield([{'foo' => 'bar'}])

          plugin = SubscriptionPlugin.new(client_app_config)
          plugin.get_initial_filters do |filter_params|
            filter_params.should == [{'foo' => 'bar'}]
          end
        end
      end
    end
  end
end
