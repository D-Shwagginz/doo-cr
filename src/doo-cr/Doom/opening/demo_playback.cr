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
  class DemoPlayback
    @demo : Demo
    @cmds : Array(TicCmd)
    getter game : DoomGame

    @start : Time::Span
    @elapsed : Time::Span = Time::Span.new
    @counting : Bool = false

    @frame_count : Int32 = 0

    def fps : Float64
      return @counting ? (Time.monotonic - @start).total_seconds : @elapsed.total_seconds
    end

    def initialize(args : CommandLineArgs, content : GameContent, options : GameOptions, demo_name : String)
      if File.exists?(demo_name)
        @demo = Demo.new(demo_name)
      elsif File.exists?(demo_name + ".lmp")
        @demo = Demo.new(demo_name + ".lmp")
      else
        lump_name = demo_name.upcase
        if content.wad.as(Wad).get_lump_number(lump_name) == -1
          raise "Demo '#{demo_name}' was not found!"
        end
        @demo = Demo.new(content.wad.as(Wad).read_lump(lump_name))
      end

      @demo.options.as(GameOptions).game_version = options.game_version
      @demo.options.as(GameOptions).game_mode = options.game_mode
      @demo.options.as(GameOptions).mission_pack = options.mission_pack
      @demo.options.as(GameOptions).video = options.video
      @demo.options.as(GameOptions).sound = options.sound
      @demo.options.as(GameOptions).music = options.music

      @demo.options.as(GameOptions).net_game = true if args.solonet.present

      @cmds = Array.new(Player::MAX_PLAYER_COUNT, TicCmd.new)

      @game = DoomGame.new(content, @demo.options.as(GameOptions))
      @game.defered_init_new

      @start = Time.monotonic
    end

    def update : UpdateResult
      if !@counting
        @start = Time.monotonic
        @counting = true
      end

      if !@demo.read_cmd(@cmds)
        @counting = false
        @elapsed = Time.monotonic - @start
        return UpdateResult::Completed
      else
        @frame_count += 1
        return @game.update(@cmds)
      end
    end

    def do_event(e : DoomEvent)
      @game.do_event(e)
    end
  end
end
