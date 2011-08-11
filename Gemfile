source "http://rubygems.org"
gem 'eventmachine'
gem 'em-http-request', :require => 'em-http'
gem 'eventmachine_httpserver', :require => 'evma_httpserver'
gem 'json'
gem 'twitter-stream', '=0.1.14', :require => 'twitter/json_stream'
gem 'daemons'

gem "roauth", :git => 'git://github.com/maccman/roauth.git', :ref => '0cac7427c3d3ad6110c56bc154f290e6bc109312'

group :development do
  if RUBY_VERSION.to_f < 1.9
    gem 'ruby-debug'
  else
    gem 'ruby-debug19'
  end
  gem "rspec", :require => "spec"
  gem "rake"
end
