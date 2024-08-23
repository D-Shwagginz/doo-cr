#
# Copyright (C) 1993-1996 Id Software, Inc.
# Copyright (C) 2019-2020 Nobuaki Tanaka
# Copyright (C) 2024 Devin Shwagginz
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#

module Doocr
  module DeHackedEd
    @source_pointer_table : Array(Tuple(Proc(World, Player, PlayerSpriteDef, Nil), Proc(World, Mobj, Nil)))

    def self.initialize(args : CommandLineArgs, wad : Wad)
      if args.deh.present
        read_files(args.deh.value)
      end

      if !args.nodeh.present
        read_dehacked_lump(wad)
      end
    end

    private def read_files(*filenames : String)
      last_file_name = ""
      begin
        print("Load DeHackEd patches: ")

        filenames.each do |filename|
          last_file_name = filename
          process_lines(File.read_lines(filename))
        end

        s = ""
        filenames.select { |x| Path.basename(x) }.each do |v|
          s = s + v + ", "
        end
        s = s.rchop
        puts("OK (#{s})")
      rescue e
        puts("Failed")
        raise "Failed to apply DeHackEd patch: #{last_file_name} #{e}"
      end
    end

    private def read_dehacked_lump(wad : Wad)
      lump = wad.get_lump_number("DEHACKED")

      if lump != -1
        begin
          print("Load DeHackEd patch from WAD: ")

          process_lines(read_lines(wad.read_lump(lump)))

          puts("OK")
        rescue e
          puts("Failed")
          raise "Failed to apply DeHackEd patch! #{e}"
        end
      end
    end

    private def read_lines(data : Bytes) : Array(String)
      sr = String.new(data)
      return sr.lines
    end

    private def process_lines(lines : Array(String))
      if @source_pointer_table == nil
        @source_pointer_table = Array(Tuple(Proc(World, Player, PlayerSpriteDef, Nil), Proc(World, Mobj, Nil))).new(DoomInfo::States::LENGTH)
        @source_pointer_table.size.times do |i|
          player_action = DoomInfo.states[i].player_action
          mobj_action = DoomInfo.states[i].mobj_action
          @source_pointer_table[i] = {player_action, mobj_action}
        end
      end

      line_number = 0
      data = [] of String
      last_block = Block::None
      last_block_line = 0
      lines.each do |line|
        line_number += 1

        next if line.size > 0 && line[0] == '#'

        split = line.split(' ')
        block_type = get_block_type(split)
        if block_type == Block::None
          data << line
        else
          process_block(last_block, data, last_block_line)
          data.clear
          data << line
          last_block = block_type
          last_block_line = line_number
        end
      end
      process_block(last_block, data, last_block_line)
    end

    private def process_block(type : Block, data : Array(String), line_number : Int32)
      begin
        case type
        when Block::Thing
          process_thing_block(data)
          break
        when Block::Frame
          process_frame_block(data)
          break
        when Block::Pointer
          process_pointer_block(data)
          break
        when Block::Sound
          process_sound_block(data)
          break
        when Block::Ammo
          process_ammo_block(data)
          break
        when Block::Weapon
          process_weapon_block(data)
          break
        when Block::Cheat
          process_cheat_block(data)
          break
        when Block::Misc
          process_misc_block(data)
          break
        when Block::Text
          process_text_block(data)
          break
        when Block::Sprite
          process_sprite_block(data)
          break
        when Block::BexStrings
          process_bexstrings_block(data)
          break
        when Block::BexPars
          process_bexpars_block(data)
          break
        end
      rescue e
        raise "Failed to process block: #{type} (line #{line_number}) #{e}"
      end
    end

    private def process_thing_block(data : Array())
      thing_number = data[0].split(' ')[1].to_i32 - 1
      info = DoomInfo.mobj_infos[thing_number]
      dic = get_key_value_pairs(data)

      info.doomednum = get_int(dic, "ID #", info.doomednum)
      info.spawn_state = MobjState.new(get_int(dic, "Initial frame", info.spawn_state.to_i))
      info.spawn_health = get_int(dic, "Hit points", info.spawn_health)
      info.see_state = MobjState.new(get_int(dic, "First moving frame", info.see_state.to_i))
      info.see_sound = Sfx.new(get_int(dic, "Alert sound", info.see_sound.to_i))
      info.reaction_time = get_int(dic, "Reaction time", info.reaction_time)
      info.attack_sound = Sfx.new(get_int(dic, "Attack sound", info.attack_sound.to_i))
      info.pain_state = MobjState.new(get_int(dic, "Injury frame", info.pain_state.to_i))
      info.pain_chance = get_int(dic, "Pain chance", info.pain_chance)
      info.pain_sound = Sfx.new(get_int(dic, "Pain sound", info.pain_sound.to_i))
      info.melee_state = MobjState.new(get_int(dic, "Close attack frame", info.melee_state.to_i))
      info.missile_state = MobjState.new(get_int(dic, "Far attack frame", info.missile_state.to_i))
      info.death_state = MobjState.new(get_int(dic, "Death frame", info.death_state.to_i))
      info.xdeath_state = MobjState.new(get_int(dic, "Exploding frame", info.xdeath_state.to_i))
      info.death_sound = Sfx.new(get_int(dic, "Death sound", info.death_sound.to_i))
      info.speed = get_int(dic, "Speed", info.speed)
      info.radius = Fixed.new(get_int(dic, "Width", info.radius.data))
      info.height = Fixed.new(get_int(dic, "Height", info.height.data))
      info.mass = get_int(dic, "Mass", info.mass)
      info.damage = get_int(dic, "Missile damage", info.damage)
      info.active_sound = Sfx.new(get_int(dic, "Action sound", info.active_sound.to_i))
      info.flags = MobjFlags.new(get_int(dic, "Bits", info.flags.to_i))
      info.raise_state = MobjState.new(get_int(dic, "Respawn frame", info.raise_state.to_i))
    end

    private def process_frame_block(data : Array(String))
      frame_number = data[0].split(' ')[1].to_i32
      info = DoomInfo.states[frame_number]
      dic = get_key_value_pairs(data)

      info.sprite = Sprite.new(get_int(dic, "Sprite number", info.sprite.to_i))
      info.frame = get_int(dic, "Sprite subnumber", info.frame)
      info.tics = get_int(dic, "Duration", info.tics)
      info.next = MobjState.new(get_int(dic, "Next frame", info.next.to_i))
      info.misc1 = get_int(dic, "Unknown 1", info.misc1)
      info.misc2 = get_int(dic, "Unknown 2", info.misc2)
    end

    private def process_pointer_block(data : Array(String))
      dic = get_key_value_pairs(data)
      start = data[0].index('(') ? data[0].index('(') : -1
      start += 1
      endnum = data[0].index(')') ? data[0].index(')') : -1
      length = endnum - start
      target_frame_number = data[0][start, length].split(' ')[1]
      source_frame_number = get_int(dic, "Codep Frame", -1)
      return if source_frame_number == -1
      info = DoomInfo.states[target_frame_number]

      info.player_action = @source_pointer_table[source_frame_number][0]
      info.mobj_action = @source_pointer_table[source_frame_number][1]
    end

    private def process_sound_block(data : Array(String))
    end

    private def process_ammo_block(data : Array(String))
      ammo_number = data[0].split(' ')[1].to_i32
      dic = get_key_value_pairs(data)
      max = Doominfo::AmmoInfos.max
      clip = DoomInfo::AmmoInfos.clip

      max[ammo_number] = get_int(dic, "Max ammo", max[ammo_number])
      clip[ammo_number] = get_int(dic, "Per ammo", clip[ammo_number])
    end

    private def process_weapon_block(data : Array(String))
      weapon_number = data[0].split(' ')[1].to_i32
      info = DoomInfo.weaponinfos[weapon_number]
      dic = get_key_value_pairs(data)

      info.ammo = AmmoType.new(get_int(dic, "Ammo type", info.ammo.to_i))
      info.up_state = MobjState.new(get_int(dic, "Deselect frame", info.up_state.to_i))
      info.down_state = MobjState.new(get_int(dic, "Select frame", info.down_state.to_i))
      info.ready_state = MobjState.new(get_int(dic, "Bobbing frame", info.ready_state.to_i))
      info.attack_state = MobjState.new(get_int(dic, "Shooting frame", info.attack_state.to_i))
      info.flash_state = MobjState.new(get_int(dic, "Firing frame", info.flash_state.to_i))
    end

    private def process_cheat_block(data : Array(String))
    end

    private def process_misc_block(data : Array(String))
      dic = get_key_value_pairs(data)

      DoomInfo::DeHackEdConst.initial_health = get_int(dic, "Initial Health", DoomInfo::DeHackEdConst.initial_health)
      DoomInfo::DeHackEdConst.initial_bullets = get_int(dic, "Initial Bullets", DoomInfo::DeHackEdConst.initial_bullets)
      DoomInfo::DeHackEdConst.max_health = get_int(dic, "Max Health", DoomInfo::DeHackEdConst.max_health)
      DoomInfo::DeHackEdConst.max_armor = get_int(dic, "Max Armor", DoomInfo::DeHackEdConst.max_armor)
      DoomInfo::DeHackEdConst.green_armor_class = get_int(dic, "Green Armor Class", DoomInfo::DeHackEdConst.green_armor_class)
      DoomInfo::DeHackEdConst.blue_armor_class = get_int(dic, "Blue Armor Class", DoomInfo::DeHackEdConst.blue_armor_class)
      DoomInfo::DeHackEdConst.max_soulsphere = get_int(dic, "Max Soulsphere", DoomInfo::DeHackEdConst.max_soulsphere)
      DoomInfo::DeHackEdConst.soulsphere_health = get_int(dic, "Soulsphere Health", DoomInfo::DeHackEdConst.soulsphere_health)
      DoomInfo::DeHackEdConst.megasphere_health = get_int(dic, "Megasphere Health", DoomInfo::DeHackEdConst.megasphere_health)
      DoomInfo::DeHackEdConst.god_mode_health = get_int(dic, "God Mode Health", DoomInfo::DeHackEdConst.god_mode_health)
      DoomInfo::DeHackEdConst.idfa_armor = get_int(dic, "IDFA Armor", DoomInfo::DeHackEdConst.idfa_armor)
      DoomInfo::DeHackEdConst.idfa_armor_class = get_int(dic, "IDFA Armor Class", DoomInfo::DeHackEdConst.idfa_armor_class)
      DoomInfo::DeHackEdConst.idkfa_armor = get_int(dic, "IDKFA Armor", DoomInfo::DeHackEdConst.idkfa_armor)
      DoomInfo::DeHackEdConst.idkfa_armor_class = get_int(dic, "IDKFA Armor Class", DoomInfo::DeHackEdConst.idkfa_armor_class)
      DoomInfo::DeHackEdConst.bfg_cells_per_shot = get_int(dic, "BFG Cells/Shot", DoomInfo::DeHackEdConst.bfg_cells_per_shot)
      DoomInfo::DeHackEdConst.monsters_infight = get_int(dic, "Monsters Infight", 0) == 221
    end

    private def process_text_block(data : Array(String))
      split = data[0].split(' ')
      length1 = split[1].to_i32
      length2 = split[2].to_i32

      line = 1
      pos = 0

      sb1 = String.build do |sb1|
        length1.times do |i|
          if pos == data[line].size
            sb1 << '\n'
            line += 1
            pos = 0
          else
            sb1 << data[line][pos]
            pos += 1
          end
        end
      end

      sb2 = String.build do |sb2|
        length2.times do |i|
          if pos == data[line].size
            sb2 << '\n'
            line += 1
            pos = 0
          else
            sb2 << data[line][pos]
            pos += 1
          end
        end
      end

      DoomString.replace_by_value(sb1, sb2)
    end

    private def process_sprite_block(data : Array(String))
    end

    private def process_bexstrings_block(data : Array(String))
      name = ""
      sb = ""
      data.skip(1).each do |line|
        if name == ""
          eq_pos = line.index('=')
          if !eq_pos.nil?
            left = line[0, eq_pos].strip
            right = line[(eq_pos + 1)..].strip.gsub("\\n", '\n')
            if right[-1] != '\\'
              DoomString.replace_by_name(left, right)
            else
              name = left
              sb = ""
              sb += right[0, right.size - 1]
            end
          end
        else
          value = line.strip.gsub("\\n", '\n')
          if value[-1] != '\\'
            sb += value
            DoomString.replace_by_name(name, sb)
            name = ""
            sb = ""
          else
            sb += value[0, value.size - 1]
          end
        end
      end
    end

    private def process_bexpars_block(data : Array(String))
      data.skip(1).each do |line|
        split = line.split(' ', remove_empty: true)

        if split.size >= 3 && split[0] == "par"
          parsed = [] of Int32
          split.skip(1).each do |value|
            if result = value.to_i32?
              parsed << result
            else
              break
            end
          end

          if (parsed.size == 2 &&
             parsed[0] <= DoomInfo::ParTimes.doom2.size)
            DoomInfo::ParTimes.doom2[parsed[0] - 1] = parsed[1]
          end

          if (parsed.size >= 3 &&
             parsed[0] <= DoomInfo::ParTimes.doom1.size &&
             parsed[1] <= DoomInfo::ParTimes.doom1[parsed[0] - 1].size)
            DoomInfo::ParTimes.doom1[parsed[0] - 1][parsed[1] - 1] = parsed[2]
          end
        end
      end
    end

    private def get_block_type(split : Array(String))
      if is_thing_block_start(split)
        return Block::Thing
      elsif is_frame_block_start(split)
        return Block::Frame
      elsif is_pointer_block_start(split)
        return Block::Pointer
      elsif is_sound_block_start(split)
        return Block::Sound
      elsif is_ammo_block_start(split)
        return Block::Ammo
      elsif is_weapon_block_start(split)
        return Block::Weapon
      elsif is_cheat_block_start(split)
        return Block::Cheat
      elsif is_misc_block_start(split)
        return Block::Misc
      elsif is_text_block_start(split)
        return Block::Text
      elsif is_sprite_block_start(split)
        return Block::Sprite
      elsif is_bexstrings_block_start(split)
        return Block::BexStrings
      elsif is_bexpars_block_start(split)
        return Block::BexPars
      else
        return Block::None
      end
    end

    private def is_thing_block_start(split : Array(String)) : Bool
      return false if split.size < 2
      return false if split[0] != "Thing"
      return false if !is_number(split[1])
      return true
    end

    private def is_frame_block_start(split : Array(String)) : Bool
      return false if split.size < 2
      return false if split[0] != "Frame"
      return false if !is_number(split[1])
      return true
    end

    private def is_pointer_block_start(split : Array(String)) : Bool
      return false if split.size < 2
      return false if split[0] != "Pointer"
      return true
    end

    private def is_sound_block_start(split : Array(String)) : Bool
      return false if split.size < 2
      return false if split[0] != "Sound"
      return false if !is_number(split[1])
      return true
    end

    private def is_ammo_block_start(split : Array(String)) : Bool
      return false if split.size < 2
      return false if split[0] != "Ammo"
      return false if !is_number(split[1])
      return true
    end

    private def is_weapon_block_start(split : Array(String)) : Bool
      return false if split.size < 2
      return false if split[0] != "Weapon"
      return false if !is_number(split[1])
      return true
    end

    private def is_cheat_block_start(split : Array(String)) : Bool
      return false if split.size < 2
      return false if split[0] != "Cheat"
      return false if split[1] != "0"
      return true
    end

    private def is_misc_block_start(split : Array(String)) : Bool
      return false if split.size < 2
      return false if split[0] != "Misc"
      return false if split[1] != "0"
      return true
    end

    private def is_text_block_start(split : Array(String)) : Bool
      return false if split.size < 3
      return false if split[0] != "Text"
      return false if !is_number(split[1])
      return false if !is_number(split[2])
      return true
    end

    private def is_sprite_block_start(split : Array(String)) : Bool
      return false if split.size < 2
      return false if split[0] != "Sprite"
      return false if !is_number(split[1])
      return true
    end

    private def is_bexstrings_block_start(split : Array(String)) : Bool
      return true if split[0] == "[STRINGS]"
      return false
    end

    private def is_bexpars_block_start(split : Array(String)) : Bool
      return true if split[0] == "[PARS]"
      return false
    end

    private def is_number(value : String) : Bool
      value.each_char do |ch|
        return false if !('0' <= ch && ch <= '9')
      end
      return true
    end

    private def get_key_value_pairs(data : Array(String)) : Hash(String, String)
      dic = {} of String => String
      data.each do |line|
        split = line.split('=')
        if split.size == 2
          dic[split[0].strip] = split[1].strip
        end
      end

      return dic
    end

    private def get_int(dic : Hash(String, String), key : String, default_value : Int32) : Int32
      if value = dic[key]?
        if int_value = value.to_i32?
          return int_value
        end
      end

      return default_value
    end

    private enum Block
      None
      Thing
      Frame
      Pointer
      Sound
      Ammo
      Weapon
      Cheat
      Misc
      Text
      Sprite
      BexStrings
      BexPars
    end
  end
end
