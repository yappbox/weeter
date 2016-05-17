require 'spec_helper'
require 'tweetstream'

describe Weeter::Twitter::TweetConsumer do
  let(:limiter) do
    Weeter::Limitator.new({
      max: 1,
      duration: 10.minutes
    })
  end

  describe "auth" do
    it 'connects to JSON stream with auth options for the configuration' do
      mock_client = double('TweetStream::Client', on_error: nil)
      expect(TweetStream::Client).to receive(:new).and_return(mock_client)

      expect(Weeter::Configuration::TwitterConfig.instance).to receive(:auth_options).and_return(:foo => :bar).at_least(:once)
      consumer = Weeter::Twitter::TweetConsumer.new(Weeter::Configuration::TwitterConfig.instance, double('NotificationPlugin'), limiter)
      expect(mock_client).to receive(:filter).with(hash_including('follow' => [1, 2]))
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
      client = double('TweetStream::Client', on_error: nil)
      filter_stub = {}
      client_expectation = expect(client).to receive(:filter).with(hash_including('follow' => [1, 2, 3])).and_return(filter_stub)
      tweet_values.each do |t|
        client_expectation.and_yield(MultiJson.encode(t))
      end
      client
    }
    before(:each) do
      @tweet_hash = {'text' => "Hey", 'id_str' => "123", 'user' => {'id_str' => "1"}}
      expect(TweetStream::Client).to receive(:new).and_return(mock_client)
      @filter_params = {'follow' => ['1','2','3']}
      expect(Weeter::Configuration::TwitterConfig.instance).to receive(:auth_options).and_return(:foo => :bar).at_least(:once)
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
