# Implements special effects

module Doocr
  # max # of wall switches in a level
  MAXSWITCHES = 50

  MAXANIMS = 32

  @@anims : Array(Anim) = Array.new(MAXANIMS, Anim.new)
  @@lastanim : Anim = Anim.new

  struct Anim
    property istexture : Bool = false
    property picnum : Int32 = 0
    property basepic : Int32 = 0
    property numpics : Int32 = 0
    property speed : Int32 = 0
  end

  struct Animdef
    property istexture : Bool # if false, it is a flat
    property endname : String
    property startname : String
    property speed : Int32

    def initialize(@istexture, @endname, @startname, @speed)
    end
  end

  @@animdefs = [
    Animdef.new(false, "NUKAGE3", "NUKAGE1", 8),
    Animdef.new(false, "FWATER4", "FWATER1", 8),
    Animdef.new(false, "SWATER4", "SWATER1", 8),
    Animdef.new(false, "LAVA4", "LAVA1", 8),
    Animdef.new(false, "BLOOD3", "BLOOD1", 8),

    # DOOM II flat animations.
    Animdef.new(false, "RROCK08", "RROCK05", 8),
    Animdef.new(false, "SLIME04", "SLIME01", 8),
    Animdef.new(false, "SLIME08", "SLIME05", 8),
    Animdef.new(false, "SLIME12", "SLIME09", 8),

    Animdef.new(true, "BLODGR4", "BLODGR1", 8),
    Animdef.new(true, "SLADRIP3", "SLADRIP1", 8),

    Animdef.new(true, "BLODRIP4", "BLODRIP1", 8),
    Animdef.new(true, "FIREWALL", "FIREWALA", 8),
    Animdef.new(true, "GSTFONT3", "GSTFONT1", 8),
    Animdef.new(true, "FIRELAVA", "FIRELAV3", 8),
    Animdef.new(true, "FIREMAG3", "FIREMAG1", 8),
    Animdef.new(true, "FIREBLU2", "FIREBLU1", 8),
    Animdef.new(true, "ROCKRED3", "ROCKRED1", 8),

    Animdef.new(true, "BFALL4", "BFALL1", 8),
    Animdef.new(true, "SFALL4", "SFALL1", 8),
    Animdef.new(true, "WFALL4", "WFALL1", 8),
    Animdef.new(true, "DBRAIN4", "DBRAIN1", 8),
  ]

  struct SwitchList
    property name1 : String = ""
    property name2 : String = ""
    property episode : Int16 = 0

    def initialize(@name1, @name2, episode)
    end
  end

  def self.p_init_pic_anims
    # Init animation
    @@animdefs.each do |i|
      if i.istexture
        # different episode ?
        next if !@@textures.any? { |x| x.name == i.startname }

        @@lastanim.picnum = @@textures.index! { |x| x.name == i.endname }
        @@lastanim.basepic = @@textures.index! { |x| x.name == i.startname }
      else
        next if !@@flats.keys.any? { |x| x == i.startname }

        @@lastanim.picnum = @@flats.keys.index! { |x| x == i.endname }
        @@lastanim.basepic = @@flats.keys.index! { |x| x == i.startname }
      end

      @@lastanim.istexture = i.istexture
      @@lastanim.numpics = @@lastanim.picnum - @@lastanim.basepic + 1

      if @@lastanim.numpics < 2
        raise "p_init_pic_anims: bad cycle from #{i.startname} to #{i.endname}"
      end

      @@lastanim.speed = i.speed
      @@anims << @@lastanim
    end
  end
end
