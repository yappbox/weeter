require 'spec_helper'

describe Weeter::Configuration::ClientAppConfig do
  %w{delete_url subscriptions_url oauth}.each do |setting|
    it "accepts setting for #{setting}" do
      Weeter.configure do |conf|
        conf.client_app do |app|
          app.send("#{setting}=", "testvalue")
        end
      end
      expect(Weeter::Configuration.instance.client_app.send(setting)).to eq("testvalue")
    end
  end

  it "sets default subscription_updates_port" do
    expect(Weeter::Configuration.instance.client_app.subscription_updates_port).to eq(7337)
  end
end
