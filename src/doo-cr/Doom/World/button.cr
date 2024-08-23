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
  class Button
    property line : LineDef | Nil = nil
    property position : ButtonPosition = ButtonPosition.new(0)
    property texture : Int32 = 0
    property timer : Int32 = 0
    property sound_origin : Mobj | Nil = nil

    def clear
      @line = nil
      @position = 0
      @texture = 0
      @timer = 0
      @sound_origin = nil
    end
  end
end
