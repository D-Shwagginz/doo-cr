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
  class TicCmd
    property forward_move : Int8 = 0
    property side_move : Int8 = 0
    property angle_turn : Int16 = 0
    property buttons : UInt8 = 0

    def clear
      @forward_move = 0
      @side_move = 0
      @angle_turn = 0
      @buttons = 0
    end

    def copy_from(cmd : TicCmd)
      @forward_move = cmd.forward_move
      @side_move = cmd.side_move
      @angle_turn = cmd.angle_turn
      @buttons = cmd.buttons
    end
  end
end
