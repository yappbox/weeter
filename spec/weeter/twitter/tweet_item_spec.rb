require 'spec_helper'

describe Weeter::TweetItem do
  let(:tweet_json) {
    {'text' => "Hey", 'id_str' => "123", 'user' => {'id_str' => '1'}}
  }

  describe "deletion?" do
    it "is true if it is a deletion request" do
      item = Weeter::TweetItem.new({"delete"=>{"status"=>{"id"=>234, "user_id"=>34555}}})
      expect(item).to be_deletion
    end

    it "is false if it is not a deletion request" do
      item = Weeter::TweetItem.new({'text' => "Hey", 'id_str' => "123", 'user' => {'id_str' => "1"}})
      expect(item).to_not be_deletion
    end
  end

  describe "publishable" do


    it "is publishable if not a reply or a retweet" do
      item = Weeter::TweetItem.new(tweet_json)
      expect(item).to be_publishable
    end

    it "is not publishable if implicitly retweeted" do
      item = Weeter::TweetItem.new(tweet_json.merge({'text' => 'RT @joe Hey'}))
      expect(item).to_not be_publishable
    end

    it "is not publishable if explicitly retweeted" do
      item = Weeter::TweetItem.new(tweet_json.merge('retweeted_status' => {'id_str' => '111', 'text' => 'Hey', 'user' => {'id_str' => "1"}}))
      expect(item).to_not be_publishable
    end

    it "is not publishable if implicit reply" do
      item = Weeter::TweetItem.new(tweet_json.merge('text' => '@joe Hey'))
      expect(item).to_not be_publishable
    end

    it "is not publishable if explicit reply" do
      item = Weeter::TweetItem.new(tweet_json.merge('text' => '@joe Hey', 'in_reply_to_user_id_str' => '1'))
      expect(item).to_not be_publishable
    end

    it "is not publishable if disconnect message" do
      item = Weeter::TweetItem.new({"disconnect" => {"code" => 7,"stream_name" => "YappBox-statuses668638","reason" => "admin logout"}})
      expect(item).to_not be_publishable
    end

  end

  describe "limit_notice?" do
    it "is true if it's a limit notice" do
      item = Weeter::TweetItem.new({ 'limit' => { 'track' => 65 }})
      expect(item).to be_limit_notice
      expect(item.missed_tweets_count).to eq(65)
    end
    it "is not be true if it's a limit notice" do
      item = Weeter::TweetItem.new(tweet_json)
      expect(item).to_not be_limit_notice
      expect(lambda {
        item.missed_tweets_count
      }).to_not raise_error
    end
  end

  describe "json attributes" do

    it "delegates hash calls to its json" do
      item = Weeter::TweetItem.new({'text' => "Hey"})
      expect(item['text']).to eq("Hey")
    end

    it "retrieves nested attributes" do
      item = Weeter::TweetItem.new({'text' => "Hey", 'id_str' => "123", 'user' => {'id_str' => '1'}})
      expect(item['user']['id_str']).to eq("1")
    end

  end



end
