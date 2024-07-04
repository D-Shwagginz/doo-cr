# Refresh of things, i.e. objects represented by sprites.

module Doocr
  # variables used to look up
  #  and range check Thing sprites patches
  @@sprites : Array(Spritedef) = [] of Spritedef

  @@sprtemp : Array(Spriteframe) = Array.new(29, Spriteframe.new)
  @@maxframe : Int32 = 0
  @@spritename : String = ""

  # constant arrays
  #  used for psprite clipping and initializing clipping
  @@negonearray : Array(Int16) = Array.new(SCREENWIDTH, 0_i16)
  @@screenheightarray : Array(Int16) = Array.new(SCREENWIDTH, 0_i16)

  def self.r_init_sprites(namelist : Array(String))
    SCREENWIDTH.times do |i|
      @@negonearray[i] = -1
    end

    r_init_sprite_defs(namelist)
  end

  def self.r_init_sprite_defs(namelist : Array(String))
    patched = 0

    @@sprites = Array.new(@@spritelumps.size, Spritedef.new)

    namelist.each.with_index do |spritename, i|
      @@spritename = spritename
      @@maxframe = -1

      @@spritelumps.each do |name, sprite|
        if spritename == name
          frame = (name[4] - 'A').to_i
          rotation = (name[5] - '0').to_i

          if @@modifiedgame
            patched = @@spritelumps.keys.index! { |x| x == name }
          else
            patches = i
          end

          r_install_sprite_lump(patched, frame, rotation, false)

          if name[6]?
            frame = name[6] - 'A'
            rotation = name[7] - '0'
            r_install_sprite_lump(i, frame.to_i, rotation.to_i, true)
          end
        end
      end

      # check the frames that were found for completeness
      if @@maxframe == -1
        @@sprites[i].numframes = 0
        next
      end

      @@maxframe += 1

      @@maxframe.times do |frame|
        case @@sprtemp[frame].rotate
        when -1
          # no rotations were found for that frame at all
          raise "r_init_sprites: No patches found for #{name} frame #{'A' + frame}"
        when 0
          # only the first rotation is needed
        when 1
          8.times do |rotation|
            if @@sprtemp[frame].lump[rotation] == -1
              raise "r_init_sprites: Sprite #{name} frame #{'A' + frame} is missing rotations"
            end
          end
        end
      end

      @@sprites[i].numframes = @@maxframe
      @@sprites[i].spriteframes = @@sprtemp
    end
  end

  def self.r_install_sprite_lump(spritepos : Int32, frame : Int32, rotation : Int32, flipped : Bool)
    if frame >= 29 || rotation > 8
      raise "r_install_sprite_lump: Bad frame characters in sprite ##{spritepos} with data #{@@spritelumps.values[spritepos]}"
    end

    @@maxframe = frame if frame > @@maxframe

    if rotation == 0
      # the lump should be used for all rotations
      if @@sprtemp[frame].rotate == 0
        raise "r_init_sprites: Sprite #{@@spritename} frame #{'A' + frame} has multip rot=0 lump"
      end
      if @@sprtemp[frame].rotate == 1
        raise "r_init_sprites: Sprite #{@@spritename} frame #{'A' + frame} has rotations and a rot=0 lump"
      end

      @@sprtemp[frame].rotate = 0
      8.times do |r|
        @@sprtemp[frame].lump[r] = spritepos.to_i16
        @@sprtemp[frame].flip[r] = flipped.to_unsafe.to_u8
      end
      return
    end

    # the lump is only used for one rotation
    if @@sprtemp[frame].rotate == 0
      raise "r_init_sprites: Sprite #{@@spritename} frame #{'A' + frame} has rotations and a rot=0 lump"
    end

    @@sprtemp[frame].rotate = 1

    # make 0 based
    rotation -= 1
    if @@sprtemp[frame].lump[rotation] != -1
      raise "r_init_sprites: Sprite #{@@spritename} : #{'A' + frame} : #{'1' + rotation} has two lumps mapped to it"
    end

    @@sprtemp[frame].lump[rotation] = spritepos.to_i16
    @@sprtemp[frame].flip[rotation] = flipped.to_unsafe.to_u8
  end
end
