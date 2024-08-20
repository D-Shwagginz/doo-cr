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
  class IntermissionInfo
    # Episode number (0-2).
    property episode : Int32 = 0

    # If true, splash the secret level.
    property did_secret : Bool = false

    # Previous and next levels, origin 0.
    property last_level : Int32 = 0
    property next_level : Int32 = 0

    setter max_kill_count : Int32 = 0

    def max_kill_count
      return @max_kill_count > 1 ? @max_kill_count : 1
    end

    setter max_item_count : Int32 = 0

    def max_item_count
      return @max_item_count > 1 ? @max_item_count : 1
    end

    setter max_secret_count : Int32 = 0

    def max_secret_count
      return @max_secret_count > 1 ? @max_secret_count : 1
    end

    setter total_frags : Int32 = 0

    def total_frags
      return @total_frags > 1 ? @total_frags : 1
    end

    # The par time.

    property par_time : Int32 = 0

    getter players : Array(PlayerScores) = Array(PlayerScores).new

    def initialize
      @players = Array(PlayerScores).new(Player::MAX_PLAYER_COUNT)
      Player::MAX_PLAYER_COUNT.times do |i|
        players << PlayerScores.new
      end
    end
  end
end
