require "singleton"
require "weeter/configuration/client_app_config"
require "weeter/configuration/twitter_config"
 
module Weeter

  class Configuration
    include Singleton
    attr_accessor :log_path

    def twitter
      yield Configuration::TwitterConfig.instance if block_given?
      Configuration::TwitterConfig.instance
    end
    
    def client_app
      @client_app_config ||= Configuration::ClientAppConfig.new
      yield @client_app_config if block_given?
      @client_app_config
    end
    
    def log_path
      @log_path || File.join(File.dirname(__FILE__), '..', '..', 'log', 'weeter.log')
    end
  end
end