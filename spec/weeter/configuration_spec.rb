require 'spec_helper'

describe Weeter::Configuration do
  describe "#twitter" do
    it "should return the instance" do
      Weeter::Configuration.instance.twitter.should == Weeter::Configuration::TwitterConfig.instance
    end

    it "should yield the instance when a block is provided" do
      Weeter::Configuration.instance.twitter do |twitter_config|
        twitter_config.should == Weeter::Configuration::TwitterConfig.instance
      end
    end
  end
end