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
          break
        when 1
          start_demo("DEMO1")
          break
        when 2
          start_credit_screen()
          break
        when 3
          start_demo("DEMO2")
          break
        when 4
          start_title_screen()
          break
        when 5
          start_demo("DEMO3")
          break
        when 6
          start_credit_screen()
          break
        when 7
          start_demo("DEMO4")
          break
        end

        @current_stage = @next_stage
        update_result = UpdateResult::NeedWipe
      end

      case @current_stage
      when 0
        @count += 1
        @next_stage = 1 if @count == @timer
        break
      when 1
        if !@demo.read_cmd(@cmds)
          @next_stage = 2
        else
          @game.update(@cmds)
        end
        break
      when 2
        @count += 1
        @next_stage = 3 if @count == @timer
        break
      when 3
        if !@demo.read_cmd(@cmds)
          @next_stage = 4
        else
          @game.update(@cmds)
        end
        break
      when 4
        @count += 1
        @next_stage = 5 if @count == @timer
        break
      when 5
        if !@demo.read_cmd(@cmds)
          if @content.wad.get_lump_number("DEMO4") == -1
            @next_stage = 0
          else
            @next_stage = 6
          end
        else
          @game.update(@cmds)
        end
        break
      when 6
        @count += 1
        @next_stage = 7 if @count == @timer
        break
      when 7
        if !@demo.read_cmd(@cmds)
          @next_stage = 0
        else
          @game.update(@cmds)
        end
        break
      end

      if @state == OpeningSequenceState::Title && @count == 1
        if @options.game_mode == GameMode::Commercial
          @options.music.start_music(Bgm::DM2TTL, false)
        else
          @options.music.start_music(Bgm::INTRO, false)
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
      if @options.game_mode == GmaeMode::Commercial
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

      @demo = Demo.new(@content.wad.read_lump(lump))
      @demo.options.game_version = @options.game_version
      @demo.options.game_mode = @options.game_mode
      @demo.options.mission_pack = @options.mission_pack
      @demo.options.video = @options.video
      @demo.options.sound = @options.sound
      @demo.options.music = @options.music

      @game = DoomGame.new(@content, @demo.options)
      @game.defered_init_new
    end
  end
end
