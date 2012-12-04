require 'active_support/core_ext/numeric/time'

module Weeter
  class Limitator
    Result = Struct.new(:status, :limited_keys)

    DO_NOT_LIMIT      = :do_not_limit
    INITIATE_LIMITING = :initiate_limiting
    CONTINUE_LIMITING = :continue_limiting

    module UNLIMITED
      def self.limit_status(*args)
        DO_NOT_LIMIT
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
      self.window = TimeWindow.new({
        start: self.now,
        duration: options.fetch(:duration)
      })

      self.max = options.fetch(:max)

      flush
    end

    def process(*keys)
      ensure_correct_window

      keys.each do |key|
        increment(key)
      end

      result = Result.new
      limited_keys = keys.select { |key| exceeds_max?(key) }
      if limited_keys.any?
        result[:limited_keys] = limited_keys
        if limited_keys.any? { |key| exceeds_max_by_one?(key) }
          result[:status] = INITIATE_LIMITING
        else
          result[:status] = CONTINUE_LIMITING
        end
      else
        result[:status] = DO_NOT_LIMIT
      end
      result
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

    def exceeds_max_by_one?(key)
      lookup[key] == max + 1
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
