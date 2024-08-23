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
  class Demo
    @p : Int32
    @data : Bytes

    getter options : GameOptions

    @player_count : Int32

    def initialize(data : Bytes)
      @p = 0

      if @data[@p] != 109
        raise "Demo is from a different game version!"
      end

      @p += 1

      @data = data

      @options = GameOptions.new
      @options.skill = GameSkill.new(@data[@p])
      @p += 1
      @options.episode = @data[@p]
      @p += 1
      @options.map = @data[@p]
      @p += 1
      @options.deathmatch = @data[@p]
      @p += 1
      @options.respawn_monsters = @data[@p] != 0
      @p += 1
      @options.fast_monsters = @data[@p] != 0
      @p += 1
      @options.no_monsters = @data[@p] != 0
      @p += 1
      @options.console_player = @data[@p]
      @p += 1

      @options.players[0].in_game = @data[@p] != 0
      @p += 1
      @options.players[1].in_game = @data[@p] != 0
      @p += 1
      @options.players[2].in_game = @data[@p] != 0
      @p += 1
      @options.players[3].in_game = @data[@p] != 0
      @p += 1

      @options.demo_playback = true

      @player_count = 0
      Player::MAX_PLAYER_COUNT.times do |i|
        @player_count += 1 if @options.players[i].in_game
      end

      @options.net_game = true if @player_count >= 2
    end

    def initialize(filename : String)
      initialize(File.open(filename) { |file| file.getb_to_end })
    end

    def read_cmd(cmds : Array(TicCmd)) : Bool
      return false if @p == @data.size

      return false if @data[@p] == 0x80

      return false if @p + 4 * @player_count > @data.size

      players = @options.players
      Player::MAX_PLAYER_COUNT.times do |i|
        if players[i].in_game
          cmd = cmds[i]
          cmd.forward_move = @data[@p].to_i8
          @p += 1
          cmd.side_move = @data[@p].to_i8
          @p += 1
          cmd.angle_turn = (@data[@p] << 8).to_i8
          @p += 1
          cmd.buttons = @data[@p]
          @p += 1
        end
      end

      return true
    end
  end
end
