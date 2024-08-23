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
  class PlayerScores
    # Whether the player is in game.
    property in_game : Bool

    # Player stats, kills, collected items etc.
    property kill_count : Int32
    property item_count : Int32
    property secret_count : Int32
    property time : Int32
    getter frags : Array(Int32)

    def initialize
      @in_game = false

      @kill_count = 0
      @item_count = 0
      @secret_count = 0
      @time = 0
      @frags = Array.new(Player::MAX_PLAYER_COUNT, 0)
    end
  end
end
