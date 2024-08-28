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
  class OpeningSequence
    @content : GameContent
    @options : GameOptions

    getter state : OpeningSequenceState = OpeningSequenceState.new(0)

    @current_stage : Int32
    @next_stage : Int32

    @count : Int32 = 0
    @timer : Int32 = 0

    @cmds : Array(TicCmd)
    @demo : Demo | Nil = nil
    getter game : DoomGame | Nil = nil

    @reset : Bool

    def initialize(@content, @options)
      @cmds = Array.new(Player::MAX_PLAYER_COUNT, TicCmd.new)

      @current_stage = 0
      @next_stage = 0

      @reset = false

      start_title_screen()
    end

    def reset
      @current_stage = 0
      @next_stage = 0

      @demo = nil
      @game = nil

      @reset = true

      start_title_screen()
    end

    def update : UpdateResult
      update_result = UpdateResult::None

      if @next_stage != @current_stage
        case @next_stage
        when 0
          start_title_screen()
        when 1
          start_demo("DEMO1")
        when 2
          start_credit_screen()
        when 3
          start_demo("DEMO2")
        when 4
          start_title_screen()
        when 5
          start_demo("DEMO3")
        when 6
          start_credit_screen()
        when 7
          start_demo("DEMO4")
        end

        @current_stage = @next_stage
        update_result = UpdateResult::NeedWipe
      end

      case @current_stage
      when 0
        @count += 1
        @next_stage = 1 if @count == @timer
      when 1
        if !@demo.as(Demo).read_cmd(@cmds)
          @next_stage = 2
        else
          @game.as(DoomGame).update(@cmds)
        end
      when 2
        @count += 1
        @next_stage = 3 if @count == @timer
      when 3
        if !@demo.as(Demo).read_cmd(@cmds)
          @next_stage = 4
        else
          @game.as(DoomGame).update(@cmds)
        end
      when 4
        @count += 1
        @next_stage = 5 if @count == @timer
      when 5
        if !@demo.as(Demo).read_cmd(@cmds)
          if @content.wad.as(Wad).get_lump_number("DEMO4") == -1
            @next_stage = 0
          else
            @next_stage = 6
          end
        else
          @game.as(DoomGame).update(@cmds)
        end
      when 6
        @count += 1
        @next_stage = 7 if @count == @timer
      when 7
        if !@demo.as(Demo).read_cmd(@cmds)
          @next_stage = 0
        else
          @game.as(DoomGame).update(@cmds)
        end
      end

      if @state == OpeningSequenceState::Title && @count == 1
        if @options.as(GameOptions).game_mode == GameMode::Commercial
          @options.as(GameOptions).music.as(Audio::IMusic).start_music(Bgm::DM2TTL, false)
        else
          @options.as(GameOptions).music.as(Audio::IMusic).start_music(Bgm::INTRO, false)
        end
      end

      if @reset
        @reset = false
        return UpdateResult::NeedWipe
      else
        return update_result
      end
    end

    private def start_title_screen
      @state = OpeningSequenceState::Title

      @count = 0
      if @options.as(GameOptions).game_mode == GameMode::Commercial
        @timer = 35 * 11
      else
        @timer = 170
      end
    end

    private def start_credit_screen
      @state = OpeningSequenceState::Credit

      @count = 0
      @timer = 200
    end

    private def start_demo(lump : String)
      @state = OpeningSequenceState::Demo

      @demo = Demo.new(@content.wad.as(Wad).read_lump(lump))
      @demo.as(Demo).options.as(GameOptions).game_version = @options.as(GameOptions).game_version
      @demo.as(Demo).options.as(GameOptions).game_mode = @options.as(GameOptions).game_mode
      @demo.as(Demo).options.as(GameOptions).mission_pack = @options.as(GameOptions).mission_pack
      @demo.as(Demo).options.as(GameOptions).video = @options.as(GameOptions).video
      @demo.as(Demo).options.as(GameOptions).sound = @options.as(GameOptions).sound
      @demo.as(Demo).options.as(GameOptions).music = @options.as(GameOptions).music

      @game = DoomGame.new(@content, @demo.as(Demo).options.as(GameOptions))
      @game.as(DoomGame).defered_init_new
    end
  end
end
