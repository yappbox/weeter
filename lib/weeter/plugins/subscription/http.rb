require 'evma_httpserver'
require 'multi_json'

module Weeter
  module Plugins
    module Subscription
      class Http
        def initialize(client_app_config)
          @config = client_app_config
        end

        def get_initial_filters(&block)
          http = Weeter::Plugins::Net::OauthHttp.get(@config, @config.subscriptions_url)
          http.callback {
            filter_params = {}
            if http.response_header.status == 200
              yield MultiJson.decode(http.response)
            else
              Weeter.logger.error "Initial filters request failed with response code #{http.response_header.status}."
              yield
            end
          }
        end

        def listen_for_filter_update(tweet_consumer)
          port = @config.subscription_updates_port || Weeter::Configuration::ClientAppConfig::DEFAULT_SUBSCRIPTIONS_UPDATE_PORT
          EM.start_server('localhost', port, UpdateServer) do |conn|
            conn.tweet_consumer = tweet_consumer
          end
        end

        class UpdateServer < EM::Connection
          include EM::HttpServer
          attr_accessor :tweet_consumer

          def process_http_request
            Weeter.logger.info("Reconnecting Twitter stream")
            filter_params = MultiJson.decode(@http_post_content)
            tweet_consumer.reconnect(filter_params)
            EM::DelegatedHttpResponse.new(self).send_response
          end
        end
      end
    end
  end
end
