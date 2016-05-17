require 'spec_helper'
require 'em-twitter'

describe Weeter::Twitter::TweetConsumer do
  let(:limiter) do
    Weeter::Limitator.new({
      max: 1,
      duration: 10.minutes
    })
  end

  describe "auth" do
    it 'connects to JSON stream with auth options for the configuration' do
      mock_client = double('EM::Twitter::Client', on_error: nil, on_unauthorized: nil, on_forbidden: nil, on_not_found: nil,
        on_not_acceptable: nil, on_range_unacceptable: nil, on_too_long: nil, on_enhance_your_calm: nil, on_reconnect: nil,
        on_max_reconnects: nil,
        each: nil)
      expect(Weeter::Configuration::TwitterConfig.instance).to receive(:auth_options).and_return(:oauth => { :foo => :bar }).at_least(:once)
      expect(EM::Twitter::Client).to receive(:connect).with(hash_including(
        :path => "/1.1/statuses/filter.json",
        :params => { 'follow' => [1, 2] }
      )).and_return(mock_client)

      consumer = Weeter::Twitter::TweetConsumer.new(Weeter::Configuration::TwitterConfig.instance, double('NotificationPlugin'), limiter)
      consumer.connect({'follow' => ['1','2']})
    end
  end

  describe '#limit_filter_params' do

    let(:client_proxy) { double('NotificationPlugin', :publish_tweet => nil) }
    let(:consumer) do
      Weeter::Twitter::TweetConsumer.new(Weeter::Configuration::TwitterConfig.instance, client_proxy, limiter)
    end

    let(:track) {[]}
    let(:follow) {[]}

    let(:params) do
      {
        'follow' => follow,
        'track'  => track
      }
    end

    context 'limit not reached' do
      it 'leaves the values alone' do
        result = consumer.send(:limit_filter_params, params)
        expect(result.fetch('track').length).to eq(0)
        expect(result.fetch('follow').length).to eq(0)
      end
    end

    context 'follow above' do
      let(:follow) { (1..5001).to_a }

      it 'it limits follows, but not tracks' do
        result = consumer.send(:limit_filter_params, params)
        expect(result.fetch('follow').length).to eq(5000)
        expect(result.fetch('track').length).to eq(0)
      end
    end

    context 'track above' do
      let(:track) { (1..401).to_a }

      it 'limits tracks, but not follows' do
        result = consumer.send(:limit_filter_params, params)
        expect(result.fetch('track').length).to eq(400)
        expect(result.fetch('follow').length).to eq(0)
      end
    end

    context 'they are both over' do
      let(:track)  { (1..401).to_a }
      let(:follow) { (1..5001).to_a }

      it 'limits both' do

        result = consumer.send(:limit_filter_params, params)
        expect(result.fetch('track').length).to eq(400)
        expect(result.fetch('follow').length).to eq(5000)
      end
    end
  end

  describe "connecting to twitter" do

    let(:tweet_values) {
      [@tweet_hash]
    }
    let(:mock_client) {
      client = double('EM::Twitter::Client', on_error: nil, on_unauthorized: nil, on_forbidden: nil, on_not_found: nil,
        on_not_acceptable: nil, on_range_unacceptable: nil, on_too_long: nil, on_enhance_your_calm: nil, on_reconnect: nil,
        on_max_reconnects: nil,
        each: nil)
      client_expectation = expect(client).to receive(:each)
      tweet_values.each do |t|
        client_expectation.and_yield(MultiJson.encode(t))
      end
      client
    }
    before(:each) do
      @tweet_hash = {'text' => "Hey", 'id_str' => "123", 'user' => {'id_str' => "1"}}
      expect(EM::Twitter::Client).to receive(:connect).with(hash_including(
        :path => "/1.1/statuses/filter.json",
        :params => { 'follow' => [1, 2, 3] }
      )).and_return(mock_client)

      @filter_params = {'follow' => ['1','2','3']}
      expect(Weeter::Configuration::TwitterConfig.instance).to receive(:auth_options).and_return(:oauth => { :foo => :bar }).at_least(:once)
      @client_proxy = double('NotificationPlugin', :publish_tweet => nil)
      @consumer = Weeter::Twitter::TweetConsumer.new(Weeter::Configuration::TwitterConfig.instance, @client_proxy, limiter)
    end

    after(:each) do
      @consumer.connect(@filter_params)
    end

    it "instantiates a TweetItem" do
      tweet_item = Weeter::TweetItem.new(@tweet_hash)
      expect(Weeter::TweetItem).to receive(:new).with({'text' => "Hey", 'id_str' => "123", 'user' => {'id_str' => "1"}}).and_return(tweet_item)
    end

    it "publishes new tweet if publishable" do
      mock_tweet = double('tweet', :deletion? => false, :publishable? => true, :limit_notice? => false, :limiting_facets => [])
      expect(Weeter::TweetItem).to receive(:new).and_return(mock_tweet)
      expect(@client_proxy).to receive(:publish_tweet).with(mock_tweet)
    end

    it "does not publish unpublishable tweets" do
      mock_tweet = double('tweet', :deletion? => false, :publishable? => false, :limit_notice? => false, :[] => '', :limiting_facets => [], :disconnect_notice? => false)
      expect(Weeter::TweetItem).to receive(:new).and_return mock_tweet
      expect(@client_proxy).to_not receive(:publish_tweet).with(mock_tweet)
    end

    it "deletes deletion tweets" do
      mock_tweet = double('tweet', :deletion? => true, :publishable? => false, :limit_notice? => false, :limiting_facets => [])
      expect(Weeter::TweetItem).to receive(:new).and_return mock_tweet
      expect(@client_proxy).to receive(:delete_tweet).with(mock_tweet)
    end

    it "notifies when stream is limited by Twitter" do
      tweet_item = Weeter::TweetItem.new({'limit' => { 'track' => 65 } })
      expect(Weeter::TweetItem).to receive(:new).and_return(tweet_item)
      expect(@client_proxy).to receive(:notify_missed_tweets).with(tweet_item)
    end

    context "when weeter is initiating rate-limiting on a facet" do
      let(:tweet_values) {
        [@tweet_hash, @tweet_hash]
      }
      it "notifies that rate limiting is being initiated" do
        tweet_item1 = double('tweet', :deletion? => false, :publishable? => true, :limit_notice? => false, :limiting_facets => ['key'], :[] => '1')
        tweet_item2 = double('tweet', :deletion? => false, :publishable? => true, :limit_notice? => false, :limiting_facets => ['key'], :[] => '2')
        expect(Weeter::TweetItem).to receive(:new).and_return(tweet_item1, tweet_item2)

        expect(@client_proxy).to receive(:notify_rate_limiting_initiated).with(tweet_item2, ['key'])
      end
    end
  end

end
