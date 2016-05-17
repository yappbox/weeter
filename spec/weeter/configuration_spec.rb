require 'spec_helper'

describe Weeter::Configuration do
  describe "#twitter" do
    it "returns the instance" do
      expect(Weeter::Configuration.instance.twitter).to eq(Weeter::Configuration::TwitterConfig.instance)
    end

    it "yields the instance when a block is provided" do
      Weeter::Configuration.instance.twitter do |twitter_config|
        expect(twitter_config).to eq(Weeter::Configuration::TwitterConfig.instance)
      end
    end
  end
end
