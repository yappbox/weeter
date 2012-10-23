require 'singleton'
require 'active_support/core_ext/numeric'

module Weeter
  class Configuration
    class LimiterConfig
      include Singleton
      attr_writer :enabled
      attr_accessor :max, :duration

      def enabled
        @enabled || false
      end
    end
  end
end
