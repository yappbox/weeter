# require 'weeter/tasks'
# will give you the weeter tasks

namespace :weeter do
  task :setup do
    require 'weeter'
    # extend this task to set the config path
  end

  desc "Start Weeter"
  task :start => :setup do
    configuration_file = ENV['WEETER_CONFIG_PATH']
    load configuration_file
    Weeter::Runner.new(Weeter::Configuration.instance).start
  end
end