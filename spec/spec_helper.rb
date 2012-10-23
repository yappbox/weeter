require 'rspec'
require 'multi_json'

$LOAD_PATH.unshift File.dirname(__FILE__) + "/../lib"
require 'weeter'

RSpec.configure do |config|
  config.before(:all) do
    Weeter::Configuration.instance.log_path = 'log/test.log'
  end
end
