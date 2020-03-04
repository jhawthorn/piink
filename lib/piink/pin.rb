require "rpi_gpio"

module Piink
  module Pin
    class Output
      def initialize(pin)
        @pin = pin
        RPi::GPIO.setup pin, as: :output
      end

      def pull_high
        RPi::GPIO.set_high @pin
      end
      alias_method :set_high, :pull_high

      def pull_low
        RPi::GPIO.set_low @pin
      end
      alias_method :set_low, :pull_low

      def set(value)
        case value
        when 0, false
          pull_low
        when 1, true
          pull_high
        else
          raise "#{value.inspect} must be one of 0, 1, false, true"
        end
      end
      alias_method :write, :set
    end

    class Input
      def initialize(pin)
        @pin = pin
        RPi::GPIO.setup pin, as: :input
      end

      def high?
        RPi::GPIO.high?(@pin)
      end

      def low?
        RPi::GPIO.low?(@pin)
      end

      def value
        low? ? 0 : 1
      end
      alias_method :read, :value
    end
  end
end
