require "rpi_gpio"
require "spi"

module Piink
  class Display
    EPD_WIDTH       = 800
    EPD_HEIGHT      = 480

    RESET_PIN = RST_PIN  = 17
    DC_PIN   = 25
    CS_PIN   = 8
    BUSY_PIN = 24

    def initialize
      setup_gpio
      setup_spi
    end

    def setup_gpio
      RPi::GPIO.set_numbering :bcm

      RPi::GPIO.setup RST_PIN,  as: :output
      RPi::GPIO.setup DC_PIN,   as: :output
      RPi::GPIO.setup CS_PIN,   as: :output
      RPi::GPIO.setup BUSY_PIN, as: :input
    end

    def setup_spi
      @spidev = SPI.new(device: '/dev/spidev0.0')
      @spidev.speed=4000000
    end

    def reset
      RPi::GPIO.set_high RESET_PIN
      sleep 0.2
      RPi::GPIO.set_low RESET_PIN
      sleep 0.004
      RPi::GPIO.set_high RESET_PIN
      sleep 0.2
    end


    def send_command(command)
      RPi::GPIO.set_low DC_PIN
      RPi::GPIO.set_low CS_PIN
      @spidev.xfer(txdata: [command])
      RPi::GPIO.set_high CS_PIN
    end

    def send_data(data)
      data = Array(data)
      RPi::GPIO.set_high DC_PIN
      RPi::GPIO.set_low CS_PIN
      data.each_slice(4096) do |slice|
        @spidev.xfer(txdata: slice)
      end
      RPi::GPIO.set_high CS_PIN
    end

    def read_busy
      print "Waiting while e-Paper busy..."
      STDOUT.flush
      send_command(0x71)
      while RPi::GPIO.low?(BUSY_PIN)
        sleep 0.05
        send_command(0x71)
      end
      sleep 0.2
      puts
    end

    def init
      reset

      send_command(0x01)			#POWER SETTING
      send_data(0x07)
      send_data(0x07)    #VGH=20V,VGL=-20V
      send_data(0x3f)		#VDH=15V
      send_data(0x3f)		#VDL=-15V

      send_command(0x04) #POWER ON

      sleep 0.1

      read_busy

      send_command(0x00)			#PANNEL SETTING
      send_data(0x0F)   #KW-3f   KWR-2F	BWROTP 0f	BWOTP 1f

      send_command(0x61)        	#tres
      send_data(0x03)		#source 800
      send_data(0x20)
      send_data(0x01)		#gate 480
      send_data(0xE0)

      send_command(0x15)
      send_data(0x00)

      send_command(0x50)			#VCOM AND DATA INTERVAL SETTING
      send_data(0x11)
      send_data(0x07)

      send_command(0x60)			#TCON SETTING
      send_data(0x22)
    end

    def clear
      total_bytes = EPD_WIDTH * EPD_HEIGHT / 8

      send_command(0x10)
      send_data([0xff] * total_bytes)

      send_command(0x13)
      send_data([0x00] * total_bytes)

      send_command(0x12)
      sleep 0.1
      read_busy
    end

    def display(imageblack, imagered)
      total_bytes = EPD_WIDTH * EPD_HEIGHT / 8

      send_command(0x10)
      send_data(imageblack)

      send_command(0x13)
      imagered = imagered.map { |v| 0xff ^ v }
      send_data(imagered)

      send_command(0x12)
      sleep 0.1
      read_busy()
    end

    def deep_sleep
      send_command(0x02) # POWER_OFF
      read_busy

      send_command(0x07) # DEEP_SLEEP
      send_data(0xa5)
    end

    def close_display
      puts("close 5V, Module enters 0 power consumption ...")
      RPi::GPIO.set_low(RST_PIN)
      RPi::GPIO.set_low(DC_PIN)
    end
  end
end
