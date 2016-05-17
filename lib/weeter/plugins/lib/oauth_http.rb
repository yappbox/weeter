require 'em-http'
require 'simple_oauth'

module Weeter
  module Plugins
    module Net
      class OauthHttp
        def self.get(config, url, params = {})
          request(config, :get, url, params)
        end

        def self.put(config, url, params = {})
          request(config, :put, url, params)
        end

        def self.post(config, url, params = {})
          request(config, :post, url, params)
        end

        def self.delete(config, url, params = {})
          request(config, :delete, url, params)
        end

        def self.request(config, method, url, params = {})
          if method == :post
            request_options = {:body => params}
          else
            request_options = {:query => params}
          end
          request_options.merge!(:head => {"Authorization" => oauth_header(config, url, params, method.to_s.upcase)}) if config.oauth
          EM::HttpRequest.new(url).send(method, request_options)
        end

        def self.oauth_header(config, uri, params, http_method)
          ::SimpleOAuth::Header.new(http_method, uri, params, config.oauth).to_s
        end
      end
    end
  end
end
