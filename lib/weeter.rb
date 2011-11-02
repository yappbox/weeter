require 'eventmachine'
require 'json'
require 'logger'

require 'weeter/configuration'
require 'weeter/cli'
require 'weeter/plugins'
require 'weeter/runner'
require 'weeter/twitter'


module Weeter
  
  def self.configure
    yield Configuration.instance
  end
  
  def self.logger
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