require "rpi_gpio"
require 'chunky_png'
require "spi"

EPD_WIDTH       = 800
EPD_HEIGHT      = 480


RESET_PIN = RST_PIN  = 17
DC_PIN   = 25
CS_PIN   = 8
BUSY_PIN = 24


RPi::GPIO.set_numbering :bcm

RPi::GPIO.setup RST_PIN,  as: :output
RPi::GPIO.setup DC_PIN,   as: :output
RPi::GPIO.setup CS_PIN,   as: :output
RPi::GPIO.setup BUSY_PIN, as: :input

SPIDEV = SPI.new(device: '/dev/spidev0.0')
SPIDEV.speed=4000000

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
  SPIDEV.xfer(txdata: [command])
  RPi::GPIO.set_high CS_PIN
end

def send_data(data)
  RPi::GPIO.set_high DC_PIN
  RPi::GPIO.set_low CS_PIN
  SPIDEV.xfer(txdata: [data])
  RPi::GPIO.set_high CS_PIN
end

def read_busy
  puts "e-Paper busy"
  send_command(0x71)
  while RPi::GPIO.low?(BUSY_PIN)
    send_command(0x71)
  end
  sleep 0.2
  puts "done"
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
  total_bytes.times do
    send_data(0xff)
  end

  send_command(0x13)
  total_bytes.times do
    send_data(0x00)
  end

  send_command(0x12)
  sleep 0.1
  read_busy
end

def display(imageblack, imagered)
  total_bytes = EPD_WIDTH * EPD_HEIGHT / 8

  send_command(0x10)
  total_bytes.times do |i|
    send_data(imageblack[i])
  end

  send_command(0x13)
  total_bytes.times do |i|
    send_data(0xff ^ imagered[i])
  end

  send_command(0x12)
  sleep 0.1
  read_busy()
end

def close_display
  #SPIDEV.close

  puts("close 5V, Module enters 0 power consumption ...")
  RPi::GPIO.set_low(RST_PIN)
  RPi::GPIO.set_low(DC_PIN)
end

def convert_buffer(buffer)
  buffer.each_slice(8).map do |values|
    a = 0
    values.each do |v|
      a <<= 1
      a |= 1 unless v
    end
    a
  end
end

def display_png(filename)
  red = ChunkyPNG::Color('red')
  black = ChunkyPNG::Color('black')

  png = ChunkyPNG::Image.from_file(filename)
  imageblack = convert_buffer png.pixels.map { |x| x == black }
  imagered   = convert_buffer png.pixels.map { |x| x == red   }
  display(imageblack, imagered)
end

init

clear

display_png(ARGV[0])
#total_bytes = EPD_WIDTH * EPD_HEIGHT / 8
#display([0xf0]*total_bytes, [0x0f]*total_bytes)

#close_display

RPi::GPIO.reset
