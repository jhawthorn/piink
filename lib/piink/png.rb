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

    COLORS = {
      red: ChunkyPNG::Color('red'),
      black: ChunkyPNG::Color('black'),
      white: ChunkyPNG::Color('white')
    }

    def nearest_color(a)
      COLORS.min_by do |_, b|
        r = ChunkyPNG::Color.r(a) - ChunkyPNG::Color.r(b)
        g = ChunkyPNG::Color.g(a) - ChunkyPNG::Color.g(b)
        b = ChunkyPNG::Color.b(a) - ChunkyPNG::Color.g(b)
        r * r + g * g + b * b
      end[0]
    end

    def write_to(display)
      colormap = Hash.new do |h, k|
        h[k] = nearest_color(k)
      end

      imageblack = convert_buffer @png.pixels.map { |x| colormap[x] == :black }
      imagered   = convert_buffer @png.pixels.map { |x| colormap[x] == :red   }
      display.display(imageblack, imagered)
    end
  end
end
