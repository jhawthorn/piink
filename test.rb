$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

require "piink/display"
require "piink/png"

def run(filename)
  display = Piink::Display.new

  display.init
  #display.clear

  Piink::PNG.new(filename).write_to(display)

  display.deep_sleep
  display.close_display
end

run(ARGV.fetch(0))
