require 'spec_helper'

module Weeter
  module Plugins
    describe SubscriptionPlugin do
      describe "#get_initial_filters" do
        it "delegates to the configured plugin" do
          client_app_config = Hashie::Mash.new(:subscription_plugin => :http)

          mock_plugin = double(Subscription::Http)
          expect(Subscription::Http).to receive(:new).and_return(mock_plugin)

          expect(mock_plugin).to receive(:get_initial_filters).and_yield([{'foo' => 'bar'}])

          plugin = SubscriptionPlugin.new(client_app_config)
          plugin.get_initial_filters do |filter_params|
            expect(filter_params).to eq([{'foo' => 'bar'}])
          end
        end
      end
    end
  end
end
