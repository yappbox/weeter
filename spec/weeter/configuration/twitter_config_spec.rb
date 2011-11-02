require 'spec_helper'

describe Weeter::Configuration::TwitterConfig do
  %w{basic_auth oauth}.each do |setting|
    it "should accept setting for #{setting}" do
      Weeter.configure do |conf|
        conf.twitter do |app|
          app.send("#{setting}=", "testvalue")
        end
      end
      Weeter::Configuration::TwitterConfig.instance.send(setting).should == "testvalue"
    end
  end
  
  describe "auth_options" do
    
    before do
      Weeter::Configuration::TwitterConfig.instance.oauth = nil
      Weeter::Configuration::TwitterConfig.instance.basic_auth = nil
    end
    
    it "should return the oauth settings with a oauth credentials" do
      Weeter::Configuration::TwitterConfig.instance.oauth = {:consumer_key => 'consumer_key', :consumer_secret => 'consumer_secret', :access_key => 'acces_key', :access_secret => 'access_secret'}
      Weeter::Configuration::TwitterConfig.instance.auth_options.should == {:oauth => {:consumer_key => 'consumer_key', :consumer_secret => 'consumer_secret', :access_key => 'acces_key', :access_secret => 'access_secret'}}
    end
    
    it "should return the basic auth settings separated by a colon" do
      Weeter::Configuration::TwitterConfig.instance.basic_auth = {:username => "bob", :password => "s3cr3t"}
      Weeter::Configuration::TwitterConfig.instance.auth_options.should == {:auth => "bob:s3cr3t"}
    end
  
    it "should prefer oauth over basic auth" do
      Weeter::Configuration::TwitterConfig.instance.basic_auth = {:username => "bob", :password => "s3cr3t"}
      Weeter::Configuration::TwitterConfig.instance.oauth = {:consumer_key => 'consumer_key', :consumer_secret => 'consumer_secret', :access_key => 'acces_key', :access_secret => 'access_secret'}
      Weeter::Configuration::TwitterConfig.instance.auth_options.should == {:oauth => {:consumer_key => 'consumer_key', :consumer_secret => 'consumer_secret', :access_key => 'acces_key', :access_secret => 'access_secret'}}
    end
  end
  
end