require 'spec_helper'

describe Weeter::Twitter::TweetConsumer do
  let(:limiter) do
    Weeter::Limitator.new({
      max: 1,
      duration: 10.minutes
    })
  end

  describe "auth" do
    it 'should use connect to JSON stream with auth options for the configuration' do
      @mock_stream = mock('JSONStream', :each_item => nil, :on_error => nil, :on_max_reconnects => nil)
      Twitter::JSONStream.stub!(:connect).and_return(@mock_stream)

      Weeter::Configuration::TwitterConfig.instance.stub!(:auth_options).and_return(:foo => :bar)
      consumer = Weeter::Twitter::TweetConsumer.new(Weeter::Configuration::TwitterConfig.instance, mock('NotificationPlugin'), limiter)
      Twitter::JSONStream.should_receive(:connect).with(hash_including(:foo => :bar))
      consumer.connect({'follow' => ['1','2']})
    end
  end

  describe '#limit_filter_params' do

    let(:client_proxy) { mock('NotificationPlugin', :publish_tweet => nil) }
    let(:consumer) do
      Weeter::Twitter::TweetConsumer.new(Weeter::Configuration::TwitterConfig.instance, client_proxy, limiter, 1000)
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
        result.fetch('track').length.should == 0
        result.fetch('follow').length.should == 0
      end
    end

    context 'follow above' do
      let(:follow) { (1..1001).to_a }

      it 'it limits follows, but not tracks' do
        result = consumer.send(:limit_filter_params, params)
        result.fetch('follow').length.should == 1000
        result.fetch('track').length.should == 0
      end
    end

    context 'track above' do
      let(:track) { (1..1001).to_a }

      it 'limits tracks, but not follows' do
        result = consumer.send(:limit_filter_params, params)
        result.fetch('track').length.should == 1000
        result.fetch('follow').length.should == 0
      end
    end

    context 'they are equally over' do
      let(:track)  { (1..600).to_a }
      let(:follow) { (1..600).to_a }

      it 'limits tracks, but not follows' do

        result = consumer.send(:limit_filter_params, params)
        result.fetch('track').length.should == 500
        result.fetch('follow').length.should == 500
      end
    end

    context 'track is more over' do
      let(:track)  { (1..800).to_a }
      let(:follow) { (1..300).to_a }

      it 'limits tracks, but not follows' do
        result = consumer.send(:limit_filter_params, params)
        result.fetch('track').length.should == 700
        result.fetch('follow').length.should == 300
      end
    end
  end

  describe "connecting to twitter" do

    let(:tweet_values) {
      [@tweet_hash]
    }
    let(:mock_stream) {
      mock_stream = mock('JSONStream', :on_error => nil, :on_max_reconnects => nil)
      each_item_stub = mock_stream.stub!(:each_item)
      tweet_values.each do |t|
        each_item_stub.and_yield(MultiJson.encode(t))
      end
      mock_stream
    }
    before(:each) do
      @filter_params = {'follow' => ['1','2','3']}
      Weeter::Configuration::TwitterConfig.instance.stub!(:auth_options).and_return(:foo => :bar)
      @tweet_hash = {'text' => "Hey", 'id_str' => "123", 'user' => {'id_str' => "1"}}
      Twitter::JSONStream.stub!(:connect).and_return(mock_stream)
      @client_proxy = mock('NotificationPlugin', :publish_tweet => nil)
      @consumer = Weeter::Twitter::TweetConsumer.new(Weeter::Configuration::TwitterConfig.instance, @client_proxy, limiter)
    end

    after(:each) do
      @consumer.connect(@filter_params)
    end

    it "should instantiate a TweetItem" do
      tweet_item = Weeter::TweetItem.new(@tweet_hash)
      Weeter::TweetItem.should_receive(:new).with({'text' => "Hey", 'id_str' => "123", 'user' => {'id_str' => "1"}}).and_return(tweet_item)
    end

    it "should connect to a Twitter JSON stream" do
      Twitter::JSONStream.should_receive(:connect).
        with(:ssl => true, :foo => :bar, :params => {'follow' => [1,2,3]}, :method => 'POST')
    end

    it "should publish new tweet if publishable" do
      mock_tweet = mock('tweet', :deletion? => false, :publishable? => true, :limit_notice? => false, :limiting_facets => [])
      Weeter::TweetItem.stub!(:new).and_return(mock_tweet)
      @client_proxy.should_receive(:publish_tweet).with(mock_tweet)
    end

    it "should not publish unpublishable tweets" do
      mock_tweet = mock('tweet', :deletion? => false, :publishable? => false, :limit_notice? => false, :[] => '', :limiting_facets => [])
      Weeter::TweetItem.stub!(:new).and_return mock_tweet
      @client_proxy.should_not_receive(:publish_tweet).with(mock_tweet)
    end

    it "should delete deletion tweets" do
      mock_tweet = mock('tweet', :deletion? => true, :publishable? => false, :limit_notice? => false, :limiting_facets => [])
      Weeter::TweetItem.stub!(:new).and_return mock_tweet
      @client_proxy.should_receive(:delete_tweet).with(mock_tweet)
    end

    it "should notify when stream is limited by Twitter" do
      tweet_item = Weeter::TweetItem.new({'limit' => { 'track' => 65 } })
      Weeter::TweetItem.stub!(:new).and_return(tweet_item)
      @client_proxy.should_receive(:notify_missed_tweets).with(tweet_item)
    end

    context "when weeter is initiating rate-limiting on a facet" do
      let(:tweet_values) {
        [@tweet_hash, @tweet_hash]
      }
      it "should notify that rate limiting is being initiated" do
        tweet_item1 = mock('tweet', :deletion? => false, :publishable? => true, :limit_notice? => false, :limiting_facets => ['key'], :[] => '1')
        tweet_item2 = mock('tweet', :deletion? => false, :publishable? => true, :limit_notice? => false, :limiting_facets => ['key'], :[] => '2')
        Weeter::TweetItem.stub!(:new).and_return(tweet_item1, tweet_item2)

        @client_proxy.should_receive(:notify_rate_limiting_initiated).with(tweet_item2, ['key'])
      end
    end
  end

end
