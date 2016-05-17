require 'spec_helper'

describe Weeter::Configuration::TwitterConfig do
  %w{basic_auth oauth}.each do |setting|
    it "accepts setting for #{setting}" do
      Weeter.configure do |conf|
        conf.twitter do |app|
          app.send("#{setting}=", "testvalue")
        end
      end
      expect(Weeter::Configuration::TwitterConfig.instance.send(setting)).to eq("testvalue")
    end
  end

  describe "auth_options" do

    before do
      Weeter::Configuration::TwitterConfig.instance.oauth = nil
      Weeter::Configuration::TwitterConfig.instance.basic_auth = nil
    end

    it "returns the oauth settings with a oauth credentials" do
      Weeter::Configuration::TwitterConfig.instance.oauth = {:consumer_key => 'consumer_key', :consumer_secret => 'consumer_secret', :access_key => 'acces_key', :access_secret => 'access_secret'}
      expect(Weeter::Configuration::TwitterConfig.instance.auth_options).to eq({:oauth => {:consumer_key => 'consumer_key', :consumer_secret => 'consumer_secret', :access_key => 'acces_key', :access_secret => 'access_secret'}})
    end

    it "returns the basic auth settings separated by a colon" do
      Weeter::Configuration::TwitterConfig.instance.basic_auth = {:username => "bob", :password => "s3cr3t"}
      expect(Weeter::Configuration::TwitterConfig.instance.auth_options).to eq({:auth => "bob:s3cr3t"})
    end

    it "prefers oauth over basic auth" do
      Weeter::Configuration::TwitterConfig.instance.basic_auth = {:username => "bob", :password => "s3cr3t"}
      Weeter::Configuration::TwitterConfig.instance.oauth = {:consumer_key => 'consumer_key', :consumer_secret => 'consumer_secret', :access_key => 'acces_key', :access_secret => 'access_secret'}
      expect(Weeter::Configuration::TwitterConfig.instance.auth_options).to eq({:oauth => {:consumer_key => 'consumer_key', :consumer_secret => 'consumer_secret', :access_key => 'acces_key', :access_secret => 'access_secret'}})
    end
  end

end
