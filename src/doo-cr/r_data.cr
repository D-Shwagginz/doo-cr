# All Rendering Data and setup

module Doocr
  @@textures : Array(WAD::TextureX::TextureMap) = [] of WAD::TextureX::TextureMap
  @@flats : Hash(String, WAD::Flat) = Hash(String, WAD::Flat).new
  @@colormaps : Array(UInt8) = [] of UInt8

  def self.r_initdata
    r_init_textures()
    print "init_textures "
    r_init_flats()
    print "init_flats "
    r_init_sprite_lumps()
    print "init_sprites "
    r_init_colormaps()
    print "init_colormaps "
  end

  def self.r_init_textures
    # Load the map texture definitions from textures.lmp.
    # The data is contained in one or two lumps,
    #  TEXTURE1 for shareware, plus TEXTURE2 for commercial.
    texture1 = @@lumps["TEXTURE1"].as?(WAD::TextureX)
    puts "warning: Invalid TEXTURE1 lump or none at all" unless texture1
    @@textures = @@textures + texture1.as(WAD::TextureX).mtextures if texture1
    if @@lumps.has_key?("TEXTURE2")
      texture2 = @@lumps["TEXTURE2"].as?(WAD::TextureX)
      raise "warning: Invalid TEXTURE2 lump" unless texture2
      @@textures = @@textures + texture2.as(WAD::TextureX).mtextures if texture2
    end
  end

  def self.r_init_flats
    fstart = @@lumps.keys.index("F_START")
    fend = @@lumps.keys.index("F_END")
    puts "warning: No F_START found in WAD" unless fstart
    puts "warning: No F_END found in WAD" unless fend

    if fstart && fend
      @@lumps.each do |name, key|
        if !key.as?(WAD::Flat)
          next
        end

        @@flats[name] = key.as(WAD::Flat)
      end
    end
  end

  def self.r_init_sprite_lumps
    sstart = @@lumps.keys.index("S_START")
    send = @@lumps.keys.index("S_END")
    puts "warning: No S_START found in WAD" unless sstart
    puts "warning: No S_END found in WAD" unless send
  end

  def self.r_init_colormaps
    colormap = @@lumps["COLORMAP"]?

    raise "r_init_colormaps: No colormap found in WAD" unless colormap
    colormap = colormap.as?(WAD::Colormap)
    raise "r_init_colormaps: Invalid colormap found in WAD" unless colormap

    colormap.tables.each do |table|
      @@colormaps = @@colormaps + table.table
    end
  end
end
