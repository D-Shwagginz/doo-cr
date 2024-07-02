# All Wad Related Code

module Doocr
  # All loaded Lump and generic files
  @@lumps = Hash(String, WAD::Map |
                         WAD::PcSound |
                         WAD::Sound |
                         WAD::Music |
                         WAD::Genmidi |
                         WAD::Dmxgus |
                         WAD::Playpal |
                         WAD::Colormap |
                         WAD::EnDoom |
                         WAD::TextureX |
                         WAD::Pnames |
                         WAD::Graphic |
                         WAD::Flat |
                         WAD::Demo |
                         File |
                         String).new

  @@reloadname : String = ""
  @@reloadlump : Int32 = 0

  # All files are optional, but at least one file
  #  must be found.
  # Files with a .wad extension are idlink files
  #  with multiple lumps.
  # Other files are single lumps with the base filename
  #  for the lump name.
  # Lump names can appear multiple times.
  # The name searcher looks backwards, so a later file
  #  does override all earlier ones.
  def self.init_multiple_files(filenames : Array(String))
    filenames.each do |filename|
      add_file(filename)
    end

    raise "init_multiple_files: no files found" if @@lumps.size == 0
  end

  def self.add_file(filename : String)
    # handle reload indicator.
    if (filename[0] == '~')
      filename = filename[1..]
      @@reloadname = filename
      @@reloadlump = @@lumps.size
    end

    if !File.exists?(filename) || !File.readable?(filename)
      puts " couldn't open #{filename}"
      return
    end

    puts " adding #{filename}"
    start_lump = @@lumps.size

    if filename[-3..-1] != "wad" && filename[-3..-1] != "WAD"
      # Single lump file
      x = filename.rindex('\\') ? filename.rindex('\\') : filename.rindex('/')
      y = filename.rindex('.')
      if !x || !y
        puts " invalid file #{filename}\n (does not contain a '/' or a '\\' or a .extention)"
        return
      end
      lump = nil
      lump = WAD::PcSound.parse(filename) if WAD::PcSound.is_pcsound?(filename[x, y])
      lump = WAD::Sound.parse(filename) if WAD::Sound.is_sound?(filename[x, y])
      lump = WAD::Music.parse(filename) if WAD::Music.is_music?(filename[x, y])
      lump = WAD::Genmidi.parse(filename) if WAD::Genmidi.is_genmidi?(filename[x, y])
      lump = WAD::Dmxgus.parse(filename) if WAD::Dmxgus.is_dmxgus?(filename[x, y])
      lump = WAD::Playpal.parse(filename) if WAD::Playpal.is_playpal?(filename[x, y])
      lump = WAD::Colormap.parse(filename) if WAD::Colormap.is_colormap?(filename[x, y])
      lump = WAD::EnDoom.parse(filename) if WAD::EnDoom.is_endoom?(filename[x, y])
      lump = WAD::TextureX.parse(filename) if WAD::TextureX.is_texturex?(filename[x, y])
      lump = WAD::Pnames.parse(filename) if WAD::Pnames.is_pnames?(filename[x, y])
      begin
        WAD::Graphic.parse(filename).try do |graphic|
          lump = graphic
        end
      rescue e
      end
      begin
        WAD::Flat.parse(filename).try do |graphic|
          lump = graphic
        end
      rescue e
      end
      begin
        WAD::Demo.parse(filename).try do |demo|
          lump = demo
        end
      rescue e
      end
      lump = File.open(filename, "rb") unless lump
      @@lumps[filename[x, y]] = lump
    else
      # WAD file
      wad = WAD.read(filename)
      wad.directories.each do |directory|
        case wad.what_is?(directory.name)
        when "Map"
          @@lumps[directory.name] = wad.maps[directory.name]
        when "PcSound"
          @@lumps[directory.name] = wad.pcsounds[directory.name]
        when "Sound"
          @@lumps[directory.name] = wad.sounds[directory.name]
        when "Music"
          @@lumps[directory.name] = wad.music[directory.name]
        when "Genmidi"
          @@lumps[directory.name] = wad.genmidi
        when "Dmxgus"
          @@lumps[directory.name] = wad.dmxgus
        when "Playpal"
          @@lumps[directory.name] = wad.playpal
        when "Colormap"
          @@lumps[directory.name] = wad.colormap
        when "EnDoom"
          @@lumps[directory.name] = wad.endoom
        when "TexMap"
          @@lumps[directory.name] = wad.texmaps[directory.name]
        when "Pnames"
          @@lumps[directory.name] = wad.pnames
        when "Graphic"
          @@lumps[directory.name] = wad.graphics[directory.name]
        when "Flat"
          @@lumps[directory.name] = wad.flats[directory.name]
        when "Demo"
          @@lumps[directory.name] = wad.demos[directory.name]
        when "Marker"
          @@lumps[directory.name] = directory.name
        end
      end
    end
  end
end
