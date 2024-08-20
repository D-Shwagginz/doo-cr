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
  class Player
    MAX_PLAYER_COUNT = 4

    class_getter normal_view_height : Fixed = Fixed.from_i(41)

    @@default_player_names : Array(String) = [
      "Green",
      "Indigo",
      "Brown",
      "Red",
    ]

    @number : Int32 = 0
    @name : String | Nil
    @in_game : Bool = false

    @mobj : Mobj | Nil
    # @player_state : PlayerState
    @cmd : TicCmd | Nil
  end
end
