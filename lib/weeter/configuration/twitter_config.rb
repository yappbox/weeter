require "singleton"

module Weeter
  class Configuration
    class TwitterConfig
      include Singleton
      attr_accessor :basic_auth, :oauth

      def auth_options
        if oauth
          {:oauth => oauth}
        else
          username = basic_auth[:username]
          password = basic_auth[:password]
          {:auth => "#{username}:#{password}"}
        end
      end
    end
    
  end
end