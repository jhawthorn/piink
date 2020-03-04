$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

require "piink/display"
require 'chunky_png'

class PNG
  def initialize(filename)
    @png = ChunkyPNG::Image.from_file(filename)
  end

  def convert_buffer(buffer)
    buffer.each_slice(8).map do |values|
      values.inject(0) do |acc, v|
        (acc << 1) | (v ? 0 : 1)
      end
    end
  end

  def write_to(display)
    red = ChunkyPNG::Color('red')
    black = ChunkyPNG::Color('black')

    imageblack = convert_buffer @png.pixels.map { |x| x == black }
    imagered   = convert_buffer @png.pixels.map { |x| x == red   }
    display.display(imageblack, imagered)
  end
end

def run(filename)
  display = Piink::Display.new

  display.init
  #display.clear

  PNG.new(filename).write_to(display)

  display.deep_sleep
  display.close_display

  RPi::GPIO.reset
end

run(ARGV.fetch(0))
