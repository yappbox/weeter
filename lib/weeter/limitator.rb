require 'active_support/core_ext/numeric/time'

module Weeter
  class Limitator

    module UNLIMITED
      def self.limit?(*args)
        false
      end
    end

    class TimeWindow
      def initialize(options = {})
        @start = options.fetch(:start)
        @duration = options.fetch(:duration)
      end

      def over?(time)
        time - @start > @duration
      end

      def begin_new_window(at)
        @start = at
      end
    end

    attr_accessor :lookup, :window, :max

    def initialize(options = {})
      self.window= TimeWindow.new({
        start: self.now,
        duration: options.fetch(:duration)
      })

      self.max = options.fetch(:max)

      flush
    end

    def limit?(*keys)
      ensure_correct_window

      keys.each do |key|
        increment(key)
      end

      keys.any? { |key| exceeds_max?(key) }
    end

  protected

    def now
      Time.now
    end

    def increment(key)
      lookup[key] += 1
    end

    def exceeds_max?(key)
      lookup[key] > max
    end

    def ensure_correct_window
      return unless window.over?(now)

      flush

      window.begin_new_window(now)
    end

    def flush
      self.lookup = Hash.new(0)
    end
  end
end
