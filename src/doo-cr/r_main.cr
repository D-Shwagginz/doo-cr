# Rendering Loop and Setup

module Doocr
  DISTMAP = 2

  # Lighting constants.
  # Now why not 32 levels here?
  LIGHTLEVELS   = 16
  LIGHTSEGSHIFT =  4

  MAXLIGHTSCALE   =  48
  LIGHTSCALESHIFT =  12
  MAXLIGHTZ       = 128
  LIGHTZSHIFT     =  20

  # Number of diminishing brightness levels.
  # There a 0-31, i.e. 32 LUT in the COLORMAP lump.
  NUMCOLORMAPS = 32

  @@zlight : Array(Array(Int32)) = Array.new(LIGHTLEVELS, Array.new(MAXLIGHTZ, 0))

  # Do not really change anything here,
  #  because it might be in the middle of a refresh.
  # The change will take effect next refresh.
  @@setsizeneeded : Bool = false
  @@setblocks : Int32 = 0
  @@setdetail : Int32 = 0

  # just for profiling purposes
  @@framecount : Int32 = 0

  def self.r_init
    r_initdata()
    puts "r_initdata"
    r_set_view_size(@@config["screenblocks"].as(Int32), @@config["detaillevel"].as(Int32))
    r_init_light_tables()
    puts "r_init_light_tables"
    r_init_sky_map()
    puts "r_init_sky_map"
    r_init_translation_tables()
    puts "r_init_translation_tables"

    @@framecount = 0
  end

  def self.r_set_view_size(block : Int32, detail : Int32)
    @@setsizeneeded = true
    @@setblocks = block
    @@setdetail = detail
  end

  def self.r_init_light_tables
    LIGHTLEVELS.times do |i|
      startmap = ((LIGHTLEVELS - 1 - i)*2)*NUMCOLORMAPS/LIGHTLEVELS
      MAXLIGHTZ.times do |j|
        scale = fixeddiv((SCREENWIDTH/2*FRACUNIT).to_i32, (j + 1) << LIGHTZSHIFT)
        scale = scale >> LIGHTSCALESHIFT
        level = startmap - scale/DISTMAP

        level = 0 if level < 0
        level = NUMCOLORMAPS - 1 if level >= NUMCOLORMAPS

        @@zlight[i][j] = @@colormaps[(level*256).to_i]
      end
    end
  end
end
