require 'spec_helper'

describe Weeter::Configuration::ClientAppConfig do
  %w{delete_url subscriptions_url oauth}.each do |setting|
    it "should accept setting for #{setting}" do
      Weeter.configure do |conf|
        conf.client_app do |app|
          app.send("#{setting}=", "testvalue")
        end
      end
      Weeter::Configuration.instance.client_app.send(setting).should == "testvalue"
    end
  end
  
  it "should default subscription_updates_port" do
    Weeter::Configuration.instance.client_app.subscription_updates_port.should == 7337
  end
end
