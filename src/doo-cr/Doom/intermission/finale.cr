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
  class Finale
    class_getter text_speed : Int32 = 3
    class_getter text_wait : Int32 = 250

    getter options : GameOptions

    # Stage of animation:
    # 0 = text, 1 = art screen, 2 = character cast.
    getter stage : Int32 = 0
    getter count : Int32 = 0

    getter flat : String | Nil = nil
    getter text : String | Nil = nil

    # For bunny scroll.
    getter scrolled : Int32 = 0
    getter show_the_end : Bool = false
    getter the_end_index : Int32 = 0

    @update_result : UpdateResult | Nil = nil

    def cast_name : String
      @@castorder[@cast_number].name
    end

    def initialize(@options : GameOptions)
      c1_text : String
      c2_text : String
      c3_text : String
      c4_text : String
      c5_text : String
      c6_text : String
      case @options.as(GameOptions).mission_pack
      when MissionPack::Plutonia
        c1_text = DoomInfo::Strings::P1TEXT.to_s
        c2_text = DoomInfo::Strings::P2TEXT.to_s
        c3_text = DoomInfo::Strings::P3TEXT.to_s
        c4_text = DoomInfo::Strings::P4TEXT.to_s
        c5_text = DoomInfo::Strings::P5TEXT.to_s
        c6_text = DoomInfo::Strings::P6TEXT.to_s
      when MissionPack::Tnt
        c1_text = DoomInfo::Strings::T1TEXT.to_s
        c2_text = DoomInfo::Strings::T2TEXT.to_s
        c3_text = DoomInfo::Strings::T3TEXT.to_s
        c4_text = DoomInfo::Strings::T4TEXT.to_s
        c5_text = DoomInfo::Strings::T5TEXT.to_s
        c6_text = DoomInfo::Strings::T6TEXT.to_s
      else
        c1_text = DoomInfo::Strings::C1TEXT.to_s
        c2_text = DoomInfo::Strings::C2TEXT.to_s
        c3_text = DoomInfo::Strings::C3TEXT.to_s
        c4_text = DoomInfo::Strings::C4TEXT.to_s
        c5_text = DoomInfo::Strings::C5TEXT.to_s
        c6_text = DoomInfo::Strings::C6TEXT.to_s
      end

      case @options.as(GameOptions).game_mode
      when GameMode::Shareware, GameMode::Registered, GameMode::Retail
        @options.as(GameOptions).music.as(Audio::IMusic).start_music(Bgm::VICTOR, true)
        case @options.as(GameOptions).episode
        when 1
          @flat = "FLOOR4_8"
          @text = DoomInfo::Strings::E1TEXT.to_s
        when 2
          @flat = "SFLR6_1"
          @text = DoomInfo::Strings::E2TEXT.to_s
        when 3
          @flat = "MFLR8_4"
          @text = DoomInfo::Strings::E3TEXT.to_s
        when 4
          @flat = "MFLR8_3"
          @text = DoomInfo::Strings::E4TEXT.to_s
        else
        end
      when GameMode::Commercial
        @options.as(GameOptions).music.as(Audio::IMusic).start_music(Bgm::READ_M, true)
        case @options.as(GameOptions).map
        when 6
          @flat = "SLIME16"
          @text = c1_text
        when 11
          @flat = "RROCK14"
          @text = c2_text
        when 20
          @flat = "RROCK07"
          @text = c3_text
        when 30
          @flat = "RROCK17"
          @text = c4_text
        when 15
          @flat = "RROCK13"
          @text = c5_text
        when 31
          @flat = "RROCK19"
          @text = c6_text
        else
        end
      else
        @options.as(GameOptions).music.as(Audio::IMusic).start_music(Bgm::READ_M, true)
        @flat = "F_SKY1"
        @text = DoomInfo::Strings::C1TEXT.to_s
      end

      @stage = 0
      @count = 0

      @scrolled = 0
      @show_the_end = false
      @the_end_index = 0
    end

    def update : UpdateResult
      @update_result = UpdateResult::None

      # Check for skipping.
      if @options.as(GameOptions).game_mode == GameMode::Commercial && @count > 50
        i : Int32 = 0

        # Go on to the next level.
        Player::MAX_PLAYER_COUNT.times do |x|
          i = x
          if @options.as(GameOptions).players[x].cmd.as(TicCmd).buttons != 0
            break
          end
        end

        if i < Player::MAX_PLAYER_COUNT && @stage != 2
          if @options.as(GameOptions).map == 30
            start_cast()
          else
            return UpdateResult::Completed
          end
        end
      end

      # Advance animation.
      @count += 1

      if @stage == 2
        update_cast()
        return @update_result.as(UpdateResult)
      end

      if @options.as(GameOptions).game_mode == GameMode::Commercial
        return @update_result.as(UpdateResult)
      end

      if @stage == 0 && @count > @text.as(String).size * @@text_speed + @@text_wait
        @count = 0
        @stage = 1
        @update_result = UpdateResult::NeedWipe
        if @options.as(GameOptions).episode == 3
          @options.as(GameOptions).music.as(Audio::IMusic).start_music(Bgm::BUNNY, true)
        end
      end

      if @stage == 1 && @options.as(GameOptions).episode == 3
        bunny_scroll()
      end

      return @update_result.as(UpdateResult)
    end

    private def bunny_scroll
      @scrolled = 320 - ((@count - 230) / 2).to_i32
      if @scrolled > 320
        @scrolled = 320
      end
      if @scrolled < 0
        @scrolled = 0
      end

      return if @count < 1130

      if @count < 1180
        @the_end_index = 0
        return
      end

      stage = ((@count - 1180) / 5).to_i32
      stage = 6 if stage > 6
      if stage > @the_end_index
        start_sound(Sfx::PISTOL)
        @the_end_index = stage
      end
    end

    @@castorder : Array(CastInfo) = [
      CastInfo.new(DoomInfo::Strings::CC_ZOMBIE, MobjType::Possessed),
      CastInfo.new(DoomInfo::Strings::CC_SHOTGUN, MobjType::Shotguy),
      CastInfo.new(DoomInfo::Strings::CC_HEAVY, MobjType::Chainguy),
      CastInfo.new(DoomInfo::Strings::CC_IMP, MobjType::Troop),
      CastInfo.new(DoomInfo::Strings::CC_DEMON, MobjType::Sergeant),
      CastInfo.new(DoomInfo::Strings::CC_LOST, MobjType::Skull),
      CastInfo.new(DoomInfo::Strings::CC_CACO, MobjType::Head),
      CastInfo.new(DoomInfo::Strings::CC_HELL, MobjType::Knight),
      CastInfo.new(DoomInfo::Strings::CC_BARON, MobjType::Bruiser),
      CastInfo.new(DoomInfo::Strings::CC_ARACH, MobjType::Baby),
      CastInfo.new(DoomInfo::Strings::CC_PAIN, MobjType::Pain),
      CastInfo.new(DoomInfo::Strings::CC_REVEN, MobjType::Undead),
      CastInfo.new(DoomInfo::Strings::CC_MANCU, MobjType::Fatso),
      CastInfo.new(DoomInfo::Strings::CC_ARCH, MobjType::Vile),
      CastInfo.new(DoomInfo::Strings::CC_SPIDER, MobjType::Spider),
      CastInfo.new(DoomInfo::Strings::CC_CYBER, MobjType::Cyborg),
      CastInfo.new(DoomInfo::Strings::CC_HERO, MobjType::Player),
    ]

    @cast_number : Int32 = 0
    getter cast_state : MobjStateDef | Nil = nil
    @cast_tics : Int32 = 0
    @cast_frames : Int32 = 0
    @cast_death : Bool = false
    @cast_on_melee : Bool = false
    @cast_attacking : Bool = false

    private def start_cast
      @stage = 2

      @cast_number = 0
      @cast_state = DoomInfo.states[DoomInfo.mobj_infos[@@castorder[@cast_number].type.to_i32].see_state.to_i32]
      @cast_tics = @cast_state.as(MobjStateDef).tics
      @cast_frames = 0
      @cast_death = false
      @cast_on_melee = false
      @cast_attacking = false

      @update_result = UpdateResult::NeedWipe

      @options.as(GameOptions).music.as(Audio::IMusic).start_music(Bgm::EVIL, true)
    end

    private def update_cast
      x = true
      @cast_tics -= 1
      if @cast_tics > 0
        # Not time to change state yet.
        return
      end

      if @cast_state.as(MobjStateDef).tics == -1 || @cast_state.as(MobjStateDef).next == MobjState::Nil
        # Switch from deathstate to next monster.
        @cast_number += 1
        @cast_death = false
        if @cast_number == @@castorder.size
          @cast_number = 0
        end
        if DoomInfo.mobj_infos[@@castorder[@cast_number].type.to_i32].see_sound != 0
          start_sound(DoomInfo.mobj_infos[@@castorder[@cast_number].type.to_i32].see_sound)
        end
        @cast_state = DoomInfo.states[DoomInfo.mobj_infos[@@castorder[@cast_number].type.to_i32].see_state.to_i32]
        @cast_frames = 0
      else
        # Just advance to next state in animation.
        if @cast_state == DoomInfo.states[MobjState::PlayAtk1.to_i32]
          # Oh, gross hack!
          @cast_attacking = false
          @cast_state = DoomInfo.states[DoomInfo.mobj_infos[@@castorder[@cast_number].type.to_i32].see_state.to_i32]
          @cast_frames = 0
          x = false
        end
        if x
          st = @cast_state.as(MobjStateDef).next
          @cast_state = DoomInfo.states[st.to_i32]
          @cast_frames += 1

          # Sound hacks....
          sfx : Sfx = Sfx.new(0)
          case st
          when MobjState::PlayAtk1
            sfx = Sfx::DSHTGN
          when MobjState::PossAtk2
            sfx = Sfx::PISTOL
          when MobjState::SposAtk2
            sfx = Sfx::SHOTGN
          when MobjState::VileAtk2
            sfx = Sfx::VILATK
          when MobjState::SkelFist2
            sfx = Sfx::SKESWG
          when MobjState::SkelFist4
            sfx = Sfx::SKEPCH
          when MobjState::SkelMiss2
            sfx = Sfx::SKEATK
          when MobjState::FattAtk8
          when MobjState::FattAtk5
          when MobjState::FattAtk2
            sfx = Sfx::FIRSHT
          when MobjState::CposAtk2
          when MobjState::CposAtk3
          when MobjState::CposAtk4
            sfx = Sfx::SHOTGN
          when MobjState::TrooAtk3
            sfx = Sfx::CLAW
          when MobjState::SargAtk2
            sfx = Sfx::SGTATK
          when MobjState::BossAtk2
          when MobjState::Bos2Atk2
          when MobjState::HeadAtk2
            sfx = Sfx::FIRSHT
          when MobjState::SkullAtk2
            sfx = Sfx::SKLATK
          when MobjState::SpidAtk2
          when MobjState::SpidAtk3
            sfx = Sfx::SHOTGN
          when MobjState::BspiAtk2
            sfx = Sfx::PLASMA
          when MobjState::CyberAtk2
          when MobjState::CyberAtk4
          when MobjState::CyberAtk6
            sfx = Sfx::RLAUNC
          when MobjState::PainAtk3
            sfx = Sfx::SKLATK
          else
            sfx = Sfx.new(0)
          end

          if sfx.to_i32 != 0
            start_sound(sfx)
          end
        end

        if x
          if @cast_frames == 12
            # Go into attack frame.
            @cast_attacking = true
            if @cast_on_melee
              @cast_state = DoomInfo.states[DoomInfo.mobj_infos[@@castorder[@cast_number].type.to_i32].melee_state.to_i32]
            else
              @cast_state = DoomInfo.states[DoomInfo.mobj_infos[@@castorder[@cast_number].type.to_i32].missile_state.to_i32]
            end

            @cast_on_melee = !@cast_on_melee
            if @cast_state == DoomInfo.states[MobjState::Nil.to_i]
              if @cast_on_melee
                @cast_state = DoomInfo.states[DoomInfo.mobj_infos[@@castorder[@cast_number].type.to_i32].melee_state.to_i32]
              else
                @cast_state = DoomInfo.states[DoomInfo.mobj_infos[@@castorder[@cast_number].type.to_i32].missile_state.to_i32]
              end
            end
          end

          if @cast_attacking
            if (@cast_frames == 24 ||
               @cast_state == DoomInfo.states[DoomInfo.mobj_infos[@@castorder[@cast_number].type.to_i32].see_state.to_i32])
              @cast_attacking = false
              @cast_state = DoomInfo.states[DoomInfo.mobj_infos[@@castorder[@cast_number].type.to_i32].see_state.to_i32]
              @cast_frames = 0
            end
          end
        end

        @cast_tics = @cast_state.as(MobjStateDef).tics
        if @cast_tics == -1
          @cast_tics = 15
        end
      end
    end

    def do_event(e : DoomEvent) : Bool
      return false if @stage != 2

      if e.type == EventType::KeyDown
        if @cast_death
          # Already in dying frames.
          return true
        end

        # Go into death frame.
        @cast_death = true
        @cast_state = DoomInfo.states[DoomInfo.mobj_infos[@@castorder[@cast_number].type.to_i32].death_state.to_i32]
        @cast_tics = @cast_state.as(MobjStateDef).tics
        @cast_frames = 0
        @cast_attacking = false
        if DoomInfo.mobj_infos[@@castorder[@cast_number].type.to_i32].death_sound != 0
          start_sound(DoomInfo.mobj_infos[@@castorder[@cast_number].type.to_i32].death_sound)
        end

        return true
      end

      return false
    end

    private def start_sound(sfx : Sfx)
      @options.as(GameOptions).sound.as(Audio::ISound).start_sound(sfx)
    end

    private class CastInfo
      property name : String
      property type : MobjType

      def initialize(name : String | DoomString, @type : MobjType)
        name = name.to_s
        @name = name == nil ? "ERROR" : name.as(String)
      end
    end
  end
end
