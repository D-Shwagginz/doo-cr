module Doocr
  class Finale
    class_getter text_speed : Int32 = 3
    class_getter text_wait : Int32 = 250

    getter options : GameOptions | Nil

    # Stage of animation:
    # 0 = text, 1 = art screen, 2 = character cast.
    getter stage : Int32 = 0
    getter count : Int32 = 0

    getter flat : String | Nil
    getter text : String | Nil

    # For bunny scroll.
    getter scrolled : Int32 = 0
    getter show_the_end : Bool = false
    getter the_end_index : Int32 = 0

    @update_result : UpdateResult | Nil

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
      case @options.mission_pack
      when MissionPack::Plutonia
        c1_text = DoomInfo::Strings::P1TEXT
        c2_text = DoomInfo::Strings::P2TEXT
        c3_text = DoomInfo::Strings::P3TEXT
        c4_text = DoomInfo::Strings::P4TEXT
        c5_text = DoomInfo::Strings::P5TEXT
        c6_text = DoomInfo::Strings::P6TEXT
        break
      when MissionPack::Tnt
        c1_text = DoomInfo::Strings::T1TEXT
        c2_text = DoomInfo::Strings::T2TEXT
        c3_text = DoomInfo::Strings::T3TEXT
        c4_text = DoomInfo::Strings::T4TEXT
        c5_text = DoomInfo::Strings::T5TEXT
        c6_text = DoomInfo::Strings::T6TEXT
        break
      else
        c1_text = DoomInfo::Strings::C1TEXT
        c2_text = DoomInfo::Strings::C2TEXT
        c3_text = DoomInfo::Strings::C3TEXT
        c4_text = DoomInfo::Strings::C4TEXT
        c5_text = DoomInfo::Strings::C5TEXT
        c6_text = DoomInfo::Strings::C6TEXT
        break
      end

      case @options.game_mode
      when GameMode::Shareware, GameMode::Registered, GameMode::Retail
        @options.music.start_music(Bgm::VICTOR, true)
        case @options.episode
        when 1
          @flat = "FLOOR4_8"
          @text = DoomInfo::Strings::E1TEXT
          break
        when 2
          @flat = "SFLR6_1"
          @text = DoomInfo::Strings::E2TEXT
          break
        when 3
          @flat = "MFLR8_4"
          @text = DoomInfo::Strings::E3TEXT
          break
        when 4
          @flat = "MFLR8_3"
          @text = DoomInfo::Strings::E4TEXT
          break
        else
          break
        end
        break
      when GameMode::Commercial
        @options.music.start_music(Bgm::READ_M, true)
        case @options.map
        when 6
          @flat = "SLIME16"
          @text = c1_text
          break
        when 11
          @flat = "RROCK14"
          @text = c2_text
          break
        when 20
          @flat = "RROCK07"
          @text = c3_text
          break
        when 30
          @flat = "RROCK17"
          @text = c4_text
          break
        when 15
          @flat = "RROCK13"
          @text = c5_text
          break
        when 31
          @flat = "RROCK19"
          @text = c6_text
          break
        else
          break
        end
      else
        @options.music.start_music(Bgm::READ_M, true)
        @flat = "F_SKY1"
        @text = DoomInfo::Strings::C1TEXT
        break
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
      if @options.game_mode == GameMode::Commercial && @count > 50
        i : Int32

        # Go on to the next level.
        Player::MAX_PLAYER_COUNT.times do |x|
          if @options.players[x].cmd.buttons != 0
            i = x
            break
          end
        end

        if i < Player::MAX_PLAYER_COUNT && @stage != 2
          if @options.map == 30
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
        return @update_result
      end

      if @options.game_mode == GameMode::Commercial
        return @update_result
      end

      if @stage == 0 && @count > @text.size * @@text_speed + @@text_wait
        @count = 0
        @stage = 1
        @update_result = UpdateResult::NeedWipe
        if @options.episode == 3
          @options.music.start_music(Bgm::BUNNY, true)
        end
      end

      if @stage == 1 && @options.episode == 3
        bunny_scroll()
      end

      return @update_result
    end

    private def bunny_scroll
      @scrolled = 320 - (@count - 230) / 2
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

      stage = (@count - 1180) / 5
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
    getter cast_state : MobjStateDef | Nil
    @cast_tics : Int32 = 0
    @cast_frames : Int32 = 0
    @cast_death : Bool = false
    @cast_on_melee : Bool = false
    @cast_attacking : Bool = false

    private def start_cast
      @stage = 2

      @cast_number = 0
      @cast_state = DoomInfo.states[DoomInfo.mobj_infos[@@castorder[@cast_number].type.to_i32].see_state.to_i32]
      @cast_tics = @cast_state.tics
      @cast_frames = 0
      @cast_death = false
      @cast_on_melee = false
      @cast_attacking = false

      @update_result = UpdateResult::NeedWipe

      @options.music.start_music(Bgm::EVIL, true)
    end

    private def update_cast
      x = true
      @cast_tics -= 1
      if @cast_tics > 0
        # Not time to change state yet.
        return
      end

      if @cast_state.tics == -1 || @cast_state.next == MobjState::Null
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
          st = @cast_state.next
          @cast_state = DoomInfo.states[st.to_i32]
          @cast_frames += 1

          # Sound hacks....
          sfx : Sfx
          case st
          when MobjState::PlayAtk1
            sfx = Sfx::DSHTGN
            break
          when MobjState::PossAtk2
            sfx = Sfx::PISTOL
            break
          when MobjState::SposAtk2
            sfx = Sfx::SHOTGN
            break
          when MobjState::VileAtk2
            sfx = Sfx::VILATK
            break
          when MobjState::SkelFist2
            sfx = Sfx::SKESWG
            break
          when MobjState::SkelFist4
            sfx = Sfx::SKEPCH
            break
          when MobjState::SkelMiss2
            sfx = Sfx::SKEATK
            break
          when MobjState::FattAtk8
          when MobjState::FattAtk5
          when MobjState::FattAtk2
            sfx = Sfx::FIRSHT
            break
          when MobjState::CposAtk2
          when MobjState::CposAtk3
          when MobjState::CposAtk4
            sfx = Sfx::SHOTGN
            break
          when MobjState::TrooAtk3
            sfx = Sfx::CLAW
            break
          when MobjState::SargAtk2
            sfx = Sfx::SGTATK
            break
          when MobjState::BossAtk2
          when MobjState::Bos2Atk2
          when MobjState::HeadAtk2
            sfx = Sfx::FIRSHT
            break
          when MobjState::SkullAtk2
            sfx = Sfx::SKLATK
            break
          when MobjState::SpidAtk2
          when MobjState::SpidAtk3
            sfx = Sfx::SHOTGN
            break
          when MobjState::BspiAtk2
            sfx = Sfx::PLASMA
            break
          when MobjState::CyberAtk2
          when MobjState::CyberAtk4
          when MobjState::CyberAtk6
            sfx = Sfx::RLAUNC
            break
          when MobjState::PainAtk3
            sfx = Sfx::SKLATK
            break
          else
            sfx = 0
            break
          end

          if sfx != 0
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
            if @cast_state == DoomInfo.states[MobjState::Null.to_i]
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

        @cast_tics = @cast_state.tics
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
        @cast_tics = @cast_state.tics
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
      @options.sound.start_sound(sfx)
    end

    private class CastInfo
      property name : String
      property type : MobjType

      def initialize(@name : String, @type : MobjType)
      end
    end
  end
end
