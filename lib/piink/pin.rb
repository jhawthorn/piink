require "mini_gpio"

module Piink
  module Pin
    GPIO = MiniGPIO.new

    class Output
      def initialize(pin)
        @pin = pin
        GPIO.set_mode pin, MiniGPIO::Modes::OUTPUT
      end

      def pull_high
        GPIO.write @pin, 1
      end
      alias_method :set_high, :pull_high

      def pull_low
        GPIO.write @pin, 0
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
        GPIO.set_mode pin, MiniGPIO::Modes::INPUT
      end

      def high?
        value == 1
      end

      def low?
        value == 0
      end

      def value
        GPIO.read(@pin)
      end
      alias_method :read, :value
    end
  end
end
