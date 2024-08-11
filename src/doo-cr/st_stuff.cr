# Status bar code.

module Doocr
  ST_HEIGHT = 32*SCREEN_MUL
  ST_WIDTH  = SCREENWIDTH
  ST_Y      = SCREENHEIGHT - ST_HEIGHT

  ST_NUMPAINFACES     = 5
  ST_NUMSTRAIGHTFACES = 3
  ST_NUMEXTRAFACES    = 2
  ST_NUMSPECIALFACES  = 3
  ST_NUMTURNFACES     = 2
  ST_FACESTRIDE       = ST_NUMSTRAIGHTFACES + ST_NUMTURNFACES + ST_NUMSPECIALFACES
  ST_NUMFACES         = ST_FACESTRIDE*ST_NUMPAINFACES + ST_NUMEXTRAFACES

  @@veryfirsttime : Int32 = 1

  @@lu_palette : Int32 = 0

  @@tallnum : Array(WAD::Graphic) = Array.new(10, WAD::Graphic.new)
  @@shortnum : Array(WAD::Graphic) = Array.new(10, WAD::Graphic.new)

  @@tallpercent : WAD::Graphic = WAD::Graphic.new

  @@keys : Array(WAD::Graphic) = Array.new(Card::NumCards.value, WAD::Graphic.new)

  @@armsbg : WAD::Graphic = WAD::Graphic.new

  @@arms : Array(Array(WAD::Graphic)) = Array.new(6, Array.new(2, WAD::Graphic.new))

  @@faceback : WAD::Graphic = WAD::Graphic.new

  @@sbar : WAD::Graphic = WAD::Graphic.new

  @@faces : Array(WAD::Graphic) = Array.new(ST_NUMFACES, WAD::Graphic.new)

  def self.st_init
    @@veryfirsttime = 0
    st_load_data()
  end

  def self.st_load_data
    raise "st_load_data: Could not find PLAYPAL" unless @@lumps.keys.index("PLAYPAL")
    @@lu_palette = @@lumps.keys.index!("PLAYPAL")
    st_load_graphic()
  end

  def self.st_load_graphic
    10.times do |i|
      x = @@lumps["STTNUM#{i}"].as?(WAD::Graphic)
      raise "st_load_graphic: Could not find graphic STTNUM#{i}" unless x
      @@tallnum[i] = x.as(WAD::Graphic)

      x = @@lumps["STYSNUM#{i}"].as?(WAD::Graphic)
      raise "st_load_graphic: Could not find graphic STYSNUM#{i}" unless x
      @@shortnum[i] = x.as(WAD::Graphic)
    end

    # Load percent key.
    # Note: why not load STMINUS here, too?
    x = @@lumps["STTPRCNT"].as?(WAD::Graphic)
    raise "st_load_graphic: Could not find graphic STTPRCNT" unless x
    @@tallpercent = x.as(WAD::Graphic)

    # key cards
    Card::NumCards.value.times do |i|
      x = @@lumps["STKEYS#{i}"].as?(WAD::Graphic)
      raise "st_load_graphic: Could not find graphic STKEYS#{i}" unless x
      @@keys[i] = x.as(WAD::Graphic)
    end

    # arms background
    x = @@lumps["STARMS"].as?(WAD::Graphic)
    raise "st_load_graphic: Could not find graphic STARMS" unless x
    @@armsbg = x.as(WAD::Graphic)

    # arms ownership widgets
    6.times do |i|
      x = @@lumps["STGNUM#{i}"].as?(WAD::Graphic)
      raise "st_load_graphic: Could not find graphic STGNUM#{i}" unless x
      @@arms[i][0] = x.as(WAD::Graphic)

      @@arms[i][1] = @@shortnum[i + 2]
    end

    # face backgrounds for different color players
    # x = @@lumps["STFB#{@@console_player}"].as?(WAD::Graphic)
    # raise "st_load_graphic: Could not find graphic STFB#{@@console_player}" unless x
    # @@faceback = x.as(WAD::Graphic)

    # status bar background bits
    x = @@lumps["STBAR"].as?(WAD::Graphic)
    raise "st_load_graphic: Could not find graphic STBAR" unless x
    @@sbar = x.as(WAD::Graphic)

    # face states
    facenum = 0
    ST_NUMPAINFACES.times do |i|
      ST_NUMSTRAIGHTFACES.times do |j|
        x = @@lumps["STFST#{i}#{j}"].as?(WAD::Graphic)
        raise "st_load_graphic: Could not find graphic STFST#{i}#{j}" unless x
        @@faces[facenum + 1] = x.as(WAD::Graphic)
        facenum += 1
      end
      # turn right
      x = @@lumps["STFTR#{i}0"].as?(WAD::Graphic)
      raise "st_load_graphic: Could not find graphic STFTR#{i}0" unless x
      @@faces[facenum] = x.as(WAD::Graphic)
      facenum += 1
      # turn left
      x = @@lumps["STFTL#{i}0"].as?(WAD::Graphic)
      raise "st_load_graphic: Could not find graphic STFTL#{i}0" unless x
      @@faces[facenum] = x.as(WAD::Graphic)
      facenum += 1
      # ouch!
      x = @@lumps["STFOUCH#{i}"].as?(WAD::Graphic)
      raise "st_load_graphic: Could not find graphic STFOUCH#{i}" unless x
      @@faces[facenum] = x.as(WAD::Graphic)
      facenum += 1
      # evil grin ;)
      x = @@lumps["STFEVL#{i}"].as?(WAD::Graphic)
      raise "st_load_graphic: Could not find graphic STFEVL#{i}" unless x
      @@faces[facenum] = x.as(WAD::Graphic)
      facenum += 1
      # pissed off
      x = @@lumps["STFKILL#{i}"].as?(WAD::Graphic)
      raise "st_load_graphic: Could not find graphic STFKILL#{i}" unless x
      @@faces[facenum] = x.as(WAD::Graphic)
      facenum += 1
    end
    x = @@lumps["STFGOD0"].as?(WAD::Graphic)
    raise "st_load_graphic: Could not find graphic STFGOD0" unless x
    @@faces[facenum] = x.as(WAD::Graphic)
    facenum += 1
    x = @@lumps["STFDEAD0"].as?(WAD::Graphic)
    raise "st_load_graphic: Could not find graphic STFDEAD0" unless x
    @@faces[facenum] = x.as(WAD::Graphic)
    facenum += 1
  end
end
