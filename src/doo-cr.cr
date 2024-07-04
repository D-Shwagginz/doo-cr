require "./doo-cr/d_defines.cr"

module Doocr
  VERSION = "1.0.0Alpha"

  # s_ = String data
  # d_ = Initialisation/general code
  # v_ = Video/Raylib code
  # a_ = Audio/Raylib code
  # var_ = Global Variables
  # w_ = Wad Related Code
  # m_ = Miscellaneous
  # hu_ = Heads up Display
  # r_ = Rendering
  # p_ = Game Logic

  def self.doocr_main : Int
    @@argv = ARGV

    doom_main()

    until Raylib.close_window?
      Raylib.begin_drawing

      Raylib.clear_background(Raylib::RAYWHITE)

      Raylib.end_drawing
    end

    return 0
  end
end

Doocr.doocr_main
