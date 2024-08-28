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
  class Cheat
    @@list : Array(CheatInfo) = [
      CheatInfo.new("idfa", ->(cheat : Cheat, typed : String) { cheat.full_ammo }, false),
      CheatInfo.new("idkfa", ->(cheat : Cheat, typed : String) { cheat.full_ammo_and_keys }, false),
      CheatInfo.new("iddqd", ->(cheat : Cheat, typed : String) { cheat.god_mode }, false),
      CheatInfo.new("idclip", ->(cheat : Cheat, typed : String) { cheat.no_clip }, false),
      CheatInfo.new("idspispopd", ->(cheat : Cheat, typed : String) { cheat.no_clip }, false),
      CheatInfo.new("iddt", ->(cheat : Cheat, typed : String) { cheat.full_map }, true),
      CheatInfo.new("idbehold", ->(cheat : Cheat, typed : String) { cheat.show_power_up_list }, false),
      CheatInfo.new("idbehold?", ->(cheat : Cheat, typed : String) { cheat.do_power_up(typed) }, false),
      CheatInfo.new("idchoppers", ->(cheat : Cheat, typed : String) { cheat.give_chainsaw }, false),
      CheatInfo.new("tntem", ->(cheat : Cheat, typed : String) { cheat.kill_monsters }, false),
      CheatInfo.new("killem", ->(cheat : Cheat, typed : String) { cheat.kill_monsters }, false),
      CheatInfo.new("fhhall", ->(cheat : Cheat, typed : String) { cheat.kill_monsters }, false),
      CheatInfo.new("idclev??", ->(cheat : Cheat, typed : String) { cheat.change_level(typed) }, true),
      CheatInfo.new("idmus??", ->(cheat : Cheat, typed : String) { cheat.change_music(typed) }, false),
    ]

    @@max_code_length : Int32 = @@list.max_by { |info| info.code.size }.code.size

    @world : World | Nil = nil

    @buffer : Array(Char) = [] of Char
    @p : Int32 = 0

    def initialize(@world)
      @buffer = Array.new(@@max_code_length, '\0')
      @p = 0
    end

    def do_event(e : DoomEvent) : Bool
      if e.type == EventType::KeyDown
        @buffer[@p] - e.key.get_char

        @p = (@p + 1) % @buffer.size

        check_buffer
      end

      return true
    end

    def check_buffer
      @@list.size.times do |i|
        code = @@list[i].code
        q = @p
        j : Int32 = 0
        while j < code.size
          q -= 1
          if q == -1
            q = @buffer.size - 1
          end
          ch = code[code.size - j - 1]
          break if @buffer[q] != ch && ch != '?'
          j += 1
        end

        if j == code.size
          typed = Array.new(code.size, '\0')
          k = code.size
          q = @p
          while j < code.size
            k -= 1
            q -= 1
            if q == -1
              q = @buffer.size - 1
            end
            typed[k] = @buffer[q]
            j += 1
          end

          if @world.as(World).options.skill != GameSkill::Nightmare || @@list[i].available_on_nightmare
            string = String.build do |buffer|
              typed.each do |char|
                buffer << char
              end
            end
            @@list[i].action.call(self, string)
          end
        end
      end
    end

    def give_weapons
      player = @world.as(World).console_player
      if @world.as(World).options.game_mode == GameMode::Commercial
        WeaponType::Count.to_i32.times do |i|
          player.weapon_owned[i] = true
        end
      else
        WeaponType::Missile.to_i32.times do |i|
          player.weapon_owned[i] = true
        end
        player.weapon_owned[WeaponType::Chainsaw.to_i32] = true
        if @world.as(World).options.game_mode != GameMode::Shareware
          player.weapon_owned[WeaponType::Plasma.to_i32] = true
          player.weapon_owned[WeaponType::Bfg.to_i32] = true
        end
      end

      player.backpack = true
      AmmoType::Count.to_i32.times do |i|
        player.max_ammo[i] = 2 * DoomInfo::AmmoInfos.max[i]
        player.ammo[i] = 2 * DoomInfo::AmmoInfos.max[i]
      end
    end

    def full_ammo
      give_weapons()
      player = @world.as(World).console_player
      player.armor_type = DoomInfo::DeHackEdConst.idfa_armor_class
      player.armor_points = DoomInfo::DeHackEdConst.idfa_armor
      player.send_message(DoomInfo::Strings::STSTR_FAADDED)
    end

    def full_ammo_and_keys
      give_weapons()
      player = @world.as(World).console_player
      player.armor_type = DoomInfo::DeHackEdConst.idkfa_armor_class
      player.armor_points = DoomInfo::DeHackEdConst.idkfa_armor
      CardType::Count.to_i32.times do |i|
        player.cards[i] = true
      end
      player.send_message(DoomInfo::Strings::STSTR_KFAADDED)
    end

    def god_mode
      player = @world.as(World).console_player
      if (player.cheats & CheatFlags::GodMode).to_i32 != 0
        player.cheats &= ~CheatFlags::GodMode
        player.send_message(DoomInfo::Strings::STSTR_DQDOFF)
      else
        player.cheats |= CheatFlags::GodMode
        player.health = Math.max(DoomInfo::DeHackEdConst.god_mode_health, player.health)
        player.mobj.as(Mobj).health = player.health
        player.send_message(DoomInfo::Strings::STSTR_DQDON)
      end
    end

    def no_clip
      player = @world.as(World).console_player
      if (player.cheats & CheatFlags::NoClip).to_i32 != 0
        player.cheats &= ~CheatFlags::NoClip
        player.send_message(DoomInfo::Strings::STSTR_NCOFF)
      else
        player.cheats |= CheatFlags::NoClip
        player.send_message(DoomInfo::Strings::STSTR_NCON)
      end
    end

    def full_map
      @world.as(World).auto_map.as(AutoMap).toggle_cheat
    end

    def show_power_up_list
      player = @world.as(World).console_player
      player.send_message(DoomInfo::Strings::STSTR_BEHOLD)
    end

    def do_power_up(typed : String)
      case typed[-1]
      when 'v'
        toggle_invulnerability()
      when 's'
        toggle_strength()
      when 'i'
        toggle_invisibility()
      when 'r'
        toggle_iron_feet()
      when 'a'
        toggle_all_map()
      when 'l'
        toggle_infrared()
      end
    end

    def toggle_invulnerability
      player = @world.as(World).console_player
      if player.powers[PowerType::Invulnerability.to_i32] > 0
        player.powers[PowerType::Invulnerability.to_i32] = 0
      else
        player.powers[PowerType::Invulnerability.to_i32] = DoomInfo::PowerDuration.invulnerability
      end
      player.send_message(DoomInfo::Strings::STSTR_BEHOLDX)
    end

    def toggle_strength
      player = @world.as(World).console_player
      if player.powers[PowerType::Strength.to_i32] > 0
        player.powers[PowerType::Strength.to_i32] = 0
      else
        player.powers[PowerType::Strength.to_i32] = 1
      end
      player.send_message(DoomInfo::Strings::STSTR_BEHOLDX)
    end

    def toggle_invisibility
      player = @world.as(World).console_player
      if player.powers[PowerType::Invisibility.to_i32] > 0
        player.powers[PowerType::Invisibility.to_i32] = 0
        player.mobj.as(Mobj).flags &= ~MobjFlags::Shadow
      else
        player.powers[PowerType::Invisibility.to_i32] = DoomInfo::PowerDuration.invisibility
        player.mobj.as(Mobj).flags |= MobjFlags::Shadow
      end
      player.send_message(DoomInfo::Strings::STSTR_BEHOLDX)
    end

    def toggle_iron_feet
      player = @world.as(World).console_player
      if player.powers[PowerType::IronFeet.to_i32] > 0
        player.powers[PowerType::IronFeet.to_i32] = 0
      else
        player.powers[PowerType::IronFeet.to_i32] = DoomInfo::PowerDuration.iron_feet
      end
      player.send_message(DoomInfo::Strings::STSTR_BEHOLDX)
    end

    def toggle_all_map
      player = @world.as(World).console_player
      if player.powers[PowerType::AllMap.to_i32] > 0
        player.powers[PowerType::AllMap.to_i32] = 0
      else
        player.powers[PowerType::AllMap.to_i32] = 1
      end
      player.send_message(DoomInfo::Strings::STSTR_BEHOLDX)
    end

    def toggle_infrared
      player = @world.as(World).console_player
      if player.powers[PowerType::Infrared.to_i32] > 0
        player.powers[PowerType::Infrared.to_i32] = 0
      else
        player.powers[PowerType::Infrared.to_i32] = DoomInfo::PowerDuration.infrared
      end
      player.send_message(DoomInfo::Strings::STSTR_BEHOLDX)
    end

    def give_chainsaw
      player = @world.as(World).console_player
      player.weapon_owned[WeaponType::Chainsaw.to_i32] = true
      player.send_message(DoomInfo::Strings::STSTR_CHOPPERS)
    end

    def kill_monsters
      player = @world.as(World).console_player
      count = 0
      enumerator = @world.as(World).thinkers.as(Thinkers).get_enumerator
      while true
        thinker = enumerator.current
        mobj = thinker.as?(Mobj)
        if (mobj != nil &&
           mobj.as(Mobj).player != nil &&
           ((mobj.as(Mobj).flags & MobjFlags::CountKill).to_i32 != 0 || mobj.as(Mobj).type == MobjType::Skull) &&
           mobj.as(Mobj).health > 0)
          @world.as(World).thing_interaction.as(ThingInteraction).damage_mobj(mobj.as(Mobj), nil, player.mobj, 10000)
          count += 1
        end
        break if !enumerator.move_next
      end
      player.send_message("#{count} monsters killed")
    end

    def change_level(typed : String)
      if @world.as(World).options.game_mode == GameMode::Commercial
        map = 0
        return if !(map = typed[typed.size - 2, 2].to_i32?)
        skill = @world.as(World).options.skill.as(GameSkill)
        @world.as(World).game.defered_init_new(skill, 1, map)
      else
        episode = 0
        return if !(episode = typed[typed.size - 2, 1].to_i32?)
        map = 0
        return if !(map = typed[typed.size - 1, 1].to_i32?)
        skill = @world.as(World).options.skill.as(GameSkill)
        @world.as(World).game.defered_init_new(skill, episode, map)
      end
    end

    def change_music(typed : String)
      options = GameOptions.new
      options.game_mode = @world.as(World).options.game_mode
      if @world.as(World).options.game_mode == GameMode::Commercial
        map = 0
        return if !(map = typed[typed.size - 2, 2].to_i32?)
        options.map = map
      else
        episode = 0
        return if !(episode = typed[typed.size - 2, 1].to_i32?)
        map = 0
        return if !(map == typed[typed.size - 1, 1].to_i32?)
        options.episode = episode
        options.map = map
      end
      @world.as(World).options.music.as(Audio::IMusic).start_music(Map.get_map_bgm(options), true)
      @world.as(World).console_player.send_message(DoomInfo::Strings::STSTR_MUS)
    end

    class CheatInfo
      getter code : String
      getter action : Proc(Cheat, String, Nil)
      getter available_on_nightmare : Bool

      def initialize(@code, @action, @available_on_nightmare)
      end
    end
  end
end
