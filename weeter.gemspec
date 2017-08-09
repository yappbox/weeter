# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "weeter/version"

Gem::Specification.new do |s|
  s.name        = "weeter"
  s.version     = Weeter::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Luke Melia", "Noah Davis", "Joey Aghion"]
  s.email       = ["luke@lukemelia.com"]
  s.homepage    = "http://github.com/lukemelia/weeter"
  s.summary     = %q{Consume the Twitter stream and notify your app}
  s.description = %q{Weeter subscribes to a set of twitter users or search terms using Twitter's streaming API, and notifies your app with each new tweet.}

  s.rubyforge_project = "weeter"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency('eventmachine', '~> 1.2.0')
  s.add_dependency('eventmachine_httpserver', '~> 0.2.1')
  s.add_dependency('em-hiredis', '~> 0.3.1')
  s.add_dependency('multi_json', '~> 1.3.0')
  s.add_dependency('hashie', '>= 2.0.5')
  s.add_dependency('em-http-request', '~> 1.1.5')
  s.add_dependency('i18n', "~> 0.7")
  s.add_dependency('activesupport', ">= 3.2.22")
  s.add_dependency("simple_oauth", '~> 0.3.1')
  s.add_dependency('em-twitter', '~> 0.3.5')

  s.add_development_dependency 'rspec', '~> 3.4.0'
  s.add_development_dependency 'byebug', '~> 2.4.1'
  s.add_development_dependency 'ZenTest'
end
