require 'eventmachine'
require 'json'
require 'logger'

module Weeter
  extend self

  autoload 'Cli',     'weeter/cli'
  autoload 'Plugins', 'weeter/plugins'
  autoload 'Runner',  'weeter/runner'
  autoload 'Twitter', 'weeter/twitter'
  autoload 'Limitator', 'weeter/limitator'
  autoload 'Configuration', 'weeter/configuration'
  autoload 'TweetItem', 'weeter/tweet_item'

  def configure
    yield Configuration.instance
  end

  def logger
    @logger ||= begin
      if Configuration.instance.log_path == false
        nil
      elsif Configuration.instance.log_path
        Logger.new(Configuration.instance.log_path)
      else
        Logger.new(STDOUT)
      end
    end
  end
end
