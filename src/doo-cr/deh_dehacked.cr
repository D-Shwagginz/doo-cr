# Copyright (C) 2026 Devin Shwagginz
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# ==> The standard and globalish DeHackEd interpreter and parser

module Doocr
  # Misc variables
  @@deh_initial_health = 100
  @@deh_initial_bullets = 50
  @@deh_max_health = 200
  @@deh_max_armor = 200
  @@deh_green_armor_class = 1
  @@deh_blue_armor_class = 2
  @@deh_max_soulsphere = 200
  @@deh_soulsphere_health = 100
  @@deh_megasphere_health = 200
  @@deh_god_mode_health = 100
  @@deh_idfa_armor = 200
  @@deh_idfa_armor_class = 2
  @@deh_idkfa_armor = 200
  @@deh_idkfa_armor_class = 2
  @@deh_bfg_cells_per_shot = 40
  @@deh_species_infighting = 0

  # The type of Dehacked Block
  enum DehBlocks
    None
    Thing
    Frame
    Sound
    Ammo
    Weapon
    Cheat
    Misc
    Pointer
    # BEH
    Strings
    Pars
    Codeptrs
  end

  # The blocks header word, matching to it's type and the following sub-header words
  DEH_BLOCKS = {
    "thing" => {
      DehBlocks::Thing, [
        "id#=",
        "initialframe=",
        "hitpoints=",
        "firstmovingframe=",
        "alertsound=",
        "reactiontime=",
        "attacksound=",
        "injuryframe=",
        "painchance=",
        "painsound=",
        "closeattackframe=",
        "farattackframe=",
        "deathframe=",
        "explodingframe=",
        "deathsound=",
        "speed=",
        "width=",
        "height=",
        "mass=",
        "missiledamage=",
        "actionsound=",
        "bits=",
        "respawnframe=",
      ],
    },
    "frame" => {
      DehBlocks::Frame, [
        "spritenumber=",
        "spritesubnumber=",
        "duration=",
        "nextframe=",
        "unknown1=",
        "unknown2=",
      ],
    },
    "sound" => {
      DehBlocks::Sound, [
        "zero/one=",
        "value=",
        "zero2=",
        "zero3=",
      ],
    },
    "ammo" => {
      DehBlocks::Ammo, [
        "maxammo=",
        "perammo=",
      ],
    },
    "weapon" => {
      DehBlocks::Weapon, [
        "ammotype=",
        "deselectframe=",
        "selectframe=",
        "bobbingframe=",
        "shootingframe=",
        "firingframe=",
      ],
    },
    "cheat" => {
      DehBlocks::Cheat, [
        "changemusic=",
        "chainsaw=",
        "godmode=",
        "ammo&keys=",
        "ammo=",
        "noclipping1=",
        "noclipping2=",
        "invincibility=",
        "berserk=",
        "invisibility=",
        "radiationsuit=",
        "auto-map=",
        "lite-ampgoggles=",
        "beholdmenu=",
        "levelwarp=",
        "playerposition=",
        "mapcheat=",
      ],
    },
    "misc" => {
      DehBlocks::Misc, [
        "initialhealth=",
        "initialbullets=",
        "maxhealth=",
        "maxarmor=",
        "greenarmorclass=",
        "bluearmorclass=",
        "maxsoulsphere=",
        "soulspherehealth=",
        "megaspherehealth=",
        "godmodehealth=",
        "idfaarmor=",
        "idfaarmorclass=",
        "idkfaarmor=",
        "idkfaarmorclass=",
        "bfgcells/shot=",
        "monstersinfight=",
      ],
    },
  }

  # The dehacked files to load
  @@dehackeds = [] of String
  # Current includes to load
  @@deh_cur_include = [] of Tuple(String, Bool) # name, notext
  # The original codepointer table for use in Pointer N (Frame X)
  @@original_codepointers = [] of Void*

  # Adds a dehacked file
  # Parses it and changes everything accordingly
  # Supports pre-bex dehacked as well as bex
  def self.deh_add_dehacked(io : IO, in_wad : Bool = false, included : Bool = false, notext : Bool = false)
    # The parser's current data
    cur_block = DehBlocks::None
    cur_num = -1
    cur_parser = [] of String

    # Init the codepointers
    @@original_codepointers = @@states.map(&.action) if @@original_codepointers.empty?

    # Until the EOF
    while (line = io.gets)
      # Skip comments and null lines
      line = line.lstrip
      next if line.size == 0
      next if line[0] == '#'

      begin
        # BEH extended stuff
        if line.starts_with?("[STRINGS]") && !notext
          cur_block = DehBlocks::Strings
          next
        end

        if line.starts_with?("[PARS]")
          cur_block = DehBlocks::Pars
          next
        end

        if line.starts_with?("[CODEPTR]")
          cur_block = DehBlocks::Codeptrs
          next
        end

        if line.starts_with?("Text") && !notext
          deh_parse_text(line, io)
          next
        end

        case cur_block
        when DehBlocks::Strings
          deh_parse_string(line, io)
          next
        when DehBlocks::Pars
          deh_parse_par(line)
          next
        when DehBlocks::Codeptrs
          normalized = line.downcase
          if normalized.starts_with?("frame") && normalized.includes?('=')
            deh_parse_codeptr(line)
            next
          end
          cur_block = DehBlocks::None
        end

        # BEX include. Errors if include is in a wad's DEHACKED or if it is nested
        if line.downcase.starts_with?("include")
          cur_block = DehBlocks::None

          i_error("Error: DeHackEd include in DEHACKED lump") if in_wad
          i_error("Error: Nested DeHackEd includes") if included
          start = "include".size
          notext = false
          if i = line.index("notext")
            start = i + "notext".size
            notext = true
          end
          @@deh_cur_include << {line[start..].lstrip, notext}
          next
        end

        # No spaces
        line = line.delete(' ')

        # I don't care about caps
        line = line = line.downcase

        # Standard dehacked

        # OG Function Pointer
        if line.starts_with?("pointer")
          cur_block = DehBlocks::Pointer
          cur_num = if m = line.match(/\(frame(\d+)\)/)
                      m[1].to_i
                    else
                      -1 # malformed header. Codep line below will no-op
                    end
          cur_parser = ["codepframe="]
          next
        end

        # Run through the current parsers line headers
        cur_parser.each_with_index do |start, loc|
          # Line has header?
          if line.starts_with?(start)
            case cur_block
            # Set thing data. Thing is laid out 1 to 1 with dehacked header hash
            when DehBlocks::Thing
              next if cur_num < 1 || cur_num > @@mobjinfo.size
              ((@@mobjinfo.to_unsafe + cur_num - 1).as(Int32*) + loc).value =
                line[start.size..].to_i(strict: false)
              # Fame is not all Int32 unlike thing, so parse it manually
            when DehBlocks::Frame
              next if cur_num < 0 || cur_num >= @@states.size
              state = @@states.to_unsafe + cur_num
              value = line[start.size..].to_i(strict: false)
              case loc
              when 0 # Sprite number
                state.value.sprite = CDoom::Spritenum.new(value)
              when 1 # Sprite subnumber
                state.value.frame = value
              when 2 # Duration
                state.value.tics = value
              when 3 # Next frame
                state.value.nextstate = CDoom::Statenum.new(value)
              when 4 # Unknown 1
                state.value.misc1 = value
              when 5 # Unknown 2
                state.value.misc2 = value
              end
              # Ditto
            when DehBlocks::Sound
              next if cur_num < 0 || cur_num >= @@s_sfx.size
              sound = @@s_sfx.to_unsafe + cur_num
              value = line[start.size..].to_i(strict: false)
              case loc
              when 0 # Zero/One
                sound.value.singularity = value
              when 1 # Value
                sound.value.priority = value
              when 2 # Zero 2
                sound.value.pitch = value
              when 3 # Zero 3
                sound.value.volume = value
              end
              # Ditto
            when DehBlocks::Ammo
              value = line[start.size..].to_i(strict: false)
              case loc
              when 0 # Max ammo
                Doocr.maxammo[cur_num] = value
              when 1 # Per ammo
                Doocr.clipammo[cur_num] = value
              end
              # Weapon is all Int32, parse based off loc
            when DehBlocks::Weapon
              next if cur_num < 0 || cur_num >= CDoom::Weapontype::NUMWEAPONS.value
              value = line[start.size..].to_i(strict: false)
              weapon = Doocr.weaponinfo[cur_num]
              case loc
              when 0 then weapon.ammo = CDoom::Ammotype.new(value)
              when 1 then weapon.upstate = value
              when 2 then weapon.downstate = value
              when 3 then weapon.readystate = value
              when 4 then weapon.atkstate = value
              when 5 then weapon.flashstate = value
              end
              # Custom cheats
            when DehBlocks::Cheat
              value = [] of UInt8
              line[start.size..].each_char { |chr| value << scramble(chr.ord.to_u8!) }
              case loc
              when 0 # IDMUS
                value.push 1, 0, 0, 0xff
                @@cheat_mus_seq = value
                Doocr.cheat_mus.sequence = @@cheat_mus_seq.to_unsafe
              when 1 # IDCHOPPERS
                value.push 0xff
                @@cheat_choppers_seq = value
                Doocr.cheat_choppers.sequence = @@cheat_choppers_seq.to_unsafe
              when 2 # IDDQD
                value.push 0xff
                @@cheat_god_seq = value
                Doocr.cheat_god.sequence = @@cheat_god_seq.to_unsafe
              when 3 # IDKFA
                value.push 0xff
                @@cheat_ammo_seq = value
                Doocr.cheat_ammo.sequence = @@cheat_ammo_seq.to_unsafe
              when 4 # IDFA
                value.push 0xff
                @@cheat_ammonokey_seq = value
                Doocr.cheat_ammonokey.sequence = @@cheat_ammonokey_seq.to_unsafe
              when 5 # IDSPISPOPD
                value.push 0xff
                @@cheat_noclip_seq = value
                Doocr.cheat_noclip.sequence = @@cheat_noclip_seq.to_unsafe
              when 6 # IDCLIP
                value.push 0xff
                @@cheat_commercial_noclip_seq = value
                Doocr.cheat_commercial_noclip.sequence = @@cheat_commercial_noclip_seq.to_unsafe
              when 7, 8, 9, 10, 11, 12, 13 # IDBEHOLDX
                value.push 0xff
                @@cheat_powerup_seq[loc - 7] = value
                Doocr.cheat_powerup[loc - 7].sequence = @@cheat_powerup_seq[loc - 7].to_unsafe
              when 14 # IDCLEV
                value.push 1, 0, 0, 0xff
                @@cheat_clev_seq = value
                Doocr.cheat_clev.sequence = @@cheat_clev_seq.to_unsafe
              when 15 # IDMYPOS
                value.push 0xff
                @@cheat_mypos_seq = value
                Doocr.cheat_mypos.sequence = @@cheat_mypos_seq.to_unsafe
              when 16 # IDDT
                value.push 0xff
                @@cheat_amap_seq = value
                Doocr.cheat_amap.sequence = @@cheat_amap_seq.to_unsafe
              end
              # Misc data, set all manually (maybe could use array of pointers to the variables?)
            when DehBlocks::Misc
              value = line[start.size..].to_i(strict: false)
              case loc
              when 0 # Initial health
                @@deh_initial_health = value
              when 1 # Initial bullets
                @@deh_initial_bullets = value
              when 2 # Max health
                @@deh_max_health = value
              when 3 # Max armor
                @@deh_max_armor = value
              when 4 # Green armor class
                @@deh_green_armor_class = value
              when 5 # Blue armor class
                @@deh_blue_armor_class = value
              when 6 # Max soulsphere
                @@deh_max_soulsphere = value
              when 7 # Soulsphere health
                @@deh_soulsphere_health = value
              when 8 # Megasphere health
                @@deh_megasphere_health = value
              when 9 # Godmode health
                @@deh_god_mode_health = value
              when 10 # Idfa armor
                @@deh_idfa_armor = value
              when 11 # Idfa armor class
                @@deh_idfa_armor_class = value
              when 12 # Idkfa armor
                @@deh_idkfa_armor = value
              when 13 # Idkfa armor class
                @@deh_idkfa_armor_class = value
              when 14 # Bfg cells/shot
                @@deh_bfg_cells_per_shot = value
              when 15 # Monsters infight
                @@deh_species_infighting = value == 221 ? 1 : value == 202 ? 0 : @@deh_species_infighting
              end
              # The OG pointer
            when DehBlocks::Pointer
              # cur_num is the target frame (rom Pointer N (Frame X)
              # value is the vanilla frame whose original action we copy.
              value = line[start.size..].to_i(strict: false)
              next if cur_num < 0 || cur_num >= @@states.size
              next if value < 0 || value >= @@original_codepointers.size
              (@@states.to_unsafe + cur_num).value.action = @@original_codepointers[value]
            end
          end
        end

        # Check if this line is a new block
        DEH_BLOCKS.each do |block, block_info|
          if line.starts_with?(block)
            num = line[block.size..].to_i?(strict: false)
            break unless num || block_info[0] == DehBlocks::Cheat
            cur_num = num ? num : -1 # For blocks like Cheat
            cur_block = block_info[0]
            cur_parser = block_info[1]
            break
          end
        end
      rescue ex : Exception
        puts "  deh: skipping malformed line #{line.inspect}: #{ex.message}"
      end
    end
  end

  # Initializes dehacked files as well as DEHACKED in wad if present
  def self.deh_init_dehacked
    # Add in DEHACKED lump
    if (i = w_check_num_for_name("DEHACKED".to_unsafe)) != -1
      dehl = Bytes.new(
        w_cache_lump_name("DEHACKED".to_unsafe, CDoom::PU_CACHE).as(UInt8*),
        w_lump_length(i))

      puts " adding DEHACKED"
      deh_add_dehacked(IO::Memory.new(dehl), true)
    end

    # Add in -deh's"
    @@dehackeds.each do |deh|
      unless File.exists?(deh)
        puts " couldn't open #{deh}"
        next
      end
      File.open(deh, "rb") do |file|
        puts " adding #{deh}"
        deh_add_dehacked(file)

        # Parse includes
        @@deh_cur_include.each do |inc|
          unless File.exists?(inc[0])
            puts " couldn't open #{inc[0]} included in #{file}"
            next
          end
          File.open(inc[0], "rb") do |inc_f|
            puts " adding #{inc[0]} included in #{file}"
            deh_add_dehacked(inc_f, false, true, inc[1])
          end
        end
        @@deh_cur_include.clear
      end
    end
  end
end
