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

  def self.doocr_main : Int
    @@argv = ARGV

    doom_main()

    return 0
  end
end

Doocr.doocr_main
