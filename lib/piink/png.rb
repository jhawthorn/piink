require "chunky_png"

module Piink
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
end
