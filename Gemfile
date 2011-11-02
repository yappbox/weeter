source "http://rubygems.org"
gem 'em-http-request', :require => 'em-http'
gem 'eventmachine'
gem 'eventmachine_httpserver', :require => 'evma_httpserver'
gem 'em-hiredis'
gem 'json'
gem "roauth", :git => 'git://github.com/maccman/roauth.git', :ref => '0cac7427c3d3ad6110c56bc154f290e6bc109312'
gem 'thin'
gem 'twitter-stream', '=0.1.14', :require => 'twitter/json_stream'
gem 'hashie'
gem 'activesupport'

group :development do
  if RUBY_VERSION.to_f < 1.9
    gem 'ruby-debug'
  else
    gem 'ruby-debug19'
  end
  gem "rspec", :require => "spec"
  gem "rake"
end
