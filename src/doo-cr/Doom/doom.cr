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
  class Doom
    @args : CommandLineArgs
    @config : Config
    @content : GameContent
    @video : Video::IVideo
    @sound : Audio::ISound
    @music : Audio::IMusic
    @user_input : UserInput::IUserInput

    @events : Array(DoomEvent)

    getter options : GameOptions

    getter menu : DoomMenu | Nil = nil

    getter opening : OpeningSequence | Nil = nil

    getter demo_playback : DemoPlayback | Nil = nil

    @cmds : Array(TicCmd) = [] of TicCmd
    getter game : DoomGame | Nil = nil

    getter wipe_effect : Video::WipeEffect | Nil = nil
    getter wiping : Bool = false

    getter current_state : DoomState = DoomState.new(0)
    @next_state : DoomState = DoomState.new(0)
    @need_wipe : Bool = false

    @send_pause : Bool = false

    @quit : Bool = false
    getter quit_message : String | Nil = nil

    @mouse_grabbed : Bool = false

    def initialize(@args, @config, @content, video : Video::IVideo | Nil = nil, sound : Audio::ISound | Nil = nil, music : Audio::IMusic | Nil = nil, user_input : UserInput::IUserInput | Nil = nil)
      @video = video == nil ? Video::NullVideo.get_instance.as(Video::IVideo) : video.as(Video::IVideo)
      @sound = sound == nil ? Audio::NullSound.get_instance.as(Audio::ISound) : sound.as(Audio::ISound)
      @music = music == nil ? Audio::NullMusic.get_instance.as(Audio::IMusic) : music.as(Audio::IMusic)
      @user_input = user_input == nil ? UserInput::NullUserInput.get_instance.as(UserInput::IUserInput) : user_input.as(UserInput::IUserInput)

      @events = Array(DoomEvent).new

      @options = GameOptions.new(@args, @content)
      @options.as(GameOptions).video = @video
      @options.as(GameOptions).sound = @sound
      @options.as(GameOptions).music = @music
      @options.as(GameOptions).user_input = @user_input

      @menu = DoomMenu.new(self)

      @opening = OpeningSequence.new(@content, @options)

      @cmds = Array.new(Player::MAX_PLAYER_COUNT, TicCmd.new)
      @game = DoomGame.new(@content, @options)

      @wipe_effect = Video::WipeEffect.new(@video.wipe_band_count, @video.wipe_height)
      @wiping = false

      @current_state = DoomState::None
      @next_state = DoomState::Opening
      @need_wipe = false

      @send_pause = false

      @quit = false
      @quit_message = nil

      @mouse_grabbed = false

      check_game_args()
    end

    private def check_game_args
      if @args.warp.present
        @next_state = DoomState::Game
        @options.as(GameOptions).episode = @args.warp.value.as(Tuple(Int32, Int32))[0]
        @options.as(GameOptions).map = @args.warp.value.as(Tuple(Int32, Int32))[1]
        @game.as(DoomGame).defered_init_new
      elsif @args.episode.present
        @next_state = DoomState::Game
        @options.as(GameOptions).episode = @args.episode.value.as(Int32)
        @options.as(GameOptions).map = 1
        @game.as(DoomGame).defered_init_new
      end

      if @args.skill.present
        @options.as(GameOptions).skill = GameSkill.new(@args.skill.value.as(Int32) - 1)
      end

      @options.as(GameOptions).deathmatch = 1 if @args.deathmatch.present

      @options.as(GameOptions).deathmatch = 2 if @args.altdeath.present

      @options.as(GameOptions).fast_monsters = true if @args.fast.present

      @options.as(GameOptions).respawn_monsters = true if @args.respawn.present

      @options.as(GameOptions).no_monsters = true if @args.nomonsters.present

      if @args.loadgame.present
        @next_state = DoomState::Game
        @game.as(DoomGame).load_game(@args.loadgame.value.as(Int32))
      end

      if @args.playdemo.present
        @next_state = DoomState::DemoPlayback
        @demo_playback = DemoPlayback.new(@args, @content, @options, @args.playdemo.value.as(String))
      end

      if @args.timedemo.present
        @next_state = DoomState::DemoPlayback
        @demo_playback = DemoPlayback.new(@args, @content, @options, @args.timedemo.value.as(String))
      end
    end

    def new_game(skill : GameSkill, episode : Int32, map : Int32)
      @game.as(DoomGame).defered_init_new(skill, episode, map)
      @next_state = DoomState::Game
    end

    def end_game
      @next_state = DoomState::Opening
    end

    private def do_events
      return if @wiping

      @events.each do |e|
        next if @menu.as(DoomMenu).do_event(e)

        next if e.type == EventType::KeyDown && check_function_key(e.key)

        if @current_state == DoomState::Game
          if e.key == DoomKey::Pause && e.type == EventType::KeyDown
            @send_pause = true
            next
          end

          next if @game.as(DoomGame).do_event(e)
        elsif @current_state == DoomState::DemoPlayback
          @demo_playback.as(DemoPlayback).do_event(e)
        end
      end

      @events.clear
    end

    private def check_function_key(key : DoomKey) : Bool
      case key
      when DoomKey::F1
        @menu.as(DoomMenu).show_help_screen
        return true
      when DoomKey::F2
        @menu.as(DoomMenu).show_save_screen
        return true
      when DoomKey::F3
        @menu.as(DoomMenu).show_load_screen
        return true
      when DoomKey::F4
        @menu.as(DoomMenu).show_volume_control
        return true
      when DoomKey::F6
        @menu.as(DoomMenu).quick_save
        return true
      when DoomKey::F7
        if @current_state == DoomState::Game
          @menu.as(DoomMenu).end_game
        else
          @options.as(GameOptions).sound.as(Audio::ISound).start_sound(Sfx::OOF)
        end
        return true
      when DoomKey::F8
        @video.display_message = !@video.display_message
        if @current_state == DoomState::Game && @game.as(DoomGame).game_state == GameState::Level
          msg = ""
          if @video.display_message
            msg = DoomInfo::Strings::MSGON.to_s
          else
            msg = DoomInfo::Strings::MSGOFF.to_s
          end
          @game.as(DoomGame).world.as(World).console_player.send_message(msg)
        end
        @menu.as(DoomMenu).start_sound(Sfx::SWTCHN)
        return true
      when DoomKey::F9
        @menu.as(DoomMenu).quick_load
        return true
      when DoomKey::F10
        @menu.as(DoomMenu).quit
        return true
      when DoomKey::F11
        gcl = @video.gamma_correction_level
        gcl += 1
        gcl = 0 if gcl > @video.max_gamma_correction_level
        @video.gamma_correction_level = gcl
        if @current_state == DoomState::Game && @game.as(DoomGame).game_state == GameState::Level
          msg = ""
          if gcl == 0
            msg = DoomInfo::Strings::GAMMALVL0
          else
            msg = "Gamma correction level #{gcl}"
          end
          @game.as(DoomGame).world.as(World).console_player.send_message(msg)
        end
        return true
      when DoomKey::Add, DoomKey::Quote, DoomKey::Equal
        if (@current_state == DoomState::Game &&
           @game.as(DoomGame).game_state == GameState::Level &&
           @game.as(DoomGame).world.as(World).auto_map.as(AutoMap).visible)
          return false
        else
          @video.window_size = Math.min(@video.window_size + 1, @video.max_window_size)
          @sound.start_sound(Sfx::STNMOV)
          return true
        end
      when DoomKey::Subtract, DoomKey::Hyphen, DoomKey::Semicolon
        if (@current_state == DoomState::Game &&
           @game.as(DoomGame).game_state == GameState::Level &&
           @game.as(DoomGame).world.as(World).auto_map.as(AutoMap).visible)
          return false
        else
          @video.window_size = Math.max(@video.window_size - 1, 0)
          @sound.start_sound(Sfx::STNMOV)
          return true
        end
      else
        return false
      end
    end

    def update : UpdateResult
      do_events()

      if !@wiping
        @menu.as(DoomMenu).update

        if @next_state != @current_state
          @opening.as(OpeningSequence).reset if @next_state != DoomState::Opening

          @demo_playback = nil if @next_state != DoomState::DemoPlayback

          @current_state = @next_state
        end

        return UpdateResult::Completed if @quit

        if @need_wipe
          @need_wipe = false
          start_wipe()
        end
      end

      if !@wiping
        case @current_state
        when DoomState::Opening
          start_wipe() if @opening.as(OpeningSequence).update == UpdateResult::NeedWipe
        when DoomState::DemoPlayback
          result = @demo_playback.as(DemoPlayback).update
          if result == UpdateResult::NeedWipe
            start_wipe()
          elsif result == UpdateResult::Completed
            quit("FPS: #{@demo_playback.as(DemoPlayback).fps.to_s}")
          end
        when DoomState::Game
          @user_input.build_tic_cmd(@cmds[@options.as(GameOptions).console_player])
          if @send_pause
            @send_pause = false
            @cmds[@options.as(GameOptions).console_player].buttons |= (TicCmdButtons.special | TicCmdButtons.pause).to_u8
          end
          start_wipe() if @game.as(DoomGame).update(@cmds) == UpdateResult::NeedWipe
        else
          raise "Invalid application state!"
        end
      end

      if @wiping
        @wiping = false if @wipe_effect.as(Video::WipeEffect).update == UpdateResult::Completed
      end

      @sound.update

      check_mouse_state()

      return UpdateResult::None
    end

    private def check_mouse_state
      mouse_should_be_grabbed : Bool = false
      if !@video.has_focus
        mouse_should_be_grabbed = false
      elsif @config.video_fullscreen
        mouse_should_be_grabbed = true
      else
        mouse_should_be_grabbed = @current_state == DoomState::Game && !@menu.as(DoomMenu).active
      end

      if @mouse_grabbed
        if !mouse_should_be_grabbed
          @user_input.release_mouse
          @mouse_grabbed = false
        end
      else
        if mouse_should_be_grabbed
          @user_input.grab_mouse
          @mouse_grabbed = true
        end
      end
    end

    private def start_wipe
      @wipe_effect.as(Video::WipeEffect).start
      @video.initialize_wipe
      @wiping = true
    end

    def pause_game
      if (@current_state == DoomState::Game &&
         @game.as(DoomGame).game_state == GameState::Level &&
         !@game.as(DoomGame).paused && !@send_pause)
        @send_pause = true
      end
    end

    def resume_game
      if (@current_state == DoomState::Game &&
         @game.as(DoomGame).game_state == GameState::Level &&
         @game.as(DoomGame).paused && !@send_pause)
        @send_pause = true
      end
    end

    def save_game(slot_number : Int32, description : String) : Bool
      if @current_state == DoomState::Game && @game.as(DoomGame).game_state == GameState::Level
        @game.as(DoomGame).save_game(slot_number, description)
        return true
      else
        return false
      end
    end

    def load_game(slot_number : Int32)
      @game.as(DoomGame).load_game(slot_number)
      @next_state = DoomState::Game
    end

    def quit
      @quit = true
    end

    def quit(message : String)
      @quit = true
      @quit_message = message
    end

    def post_event(e : DoomEvent)
      @events << e if @events.size < 64
    end
  end
end
