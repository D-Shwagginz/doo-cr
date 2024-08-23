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
  class MapCollision
    @world : World | Nil = nil

    getter open_top : Fixed = Fixed.zero
    getter open_bottom : Fixed = Fixed.zero
    getter open_range : Fixed = Fixed.zero
    getter low_floor : Fixed = Fixed.zero

    def initialize(@world)
    end

    # Sets opentop and openbottom to the window through a two sided line.
    def line_opening(line : LineDef)
      if line.back_side == nil
        # If the line is single sided, nothing can pass through.
        @open_range = Fixed.zero
        return
      end

      front = line.front_sector.as(Sector)
      back = line.back_sector.as(Sector)

      if front.ceiling_height < back.ceiling_height
        @open_top = front.ceiling_height
      else
        @open_top = back.ceiling_height
      end

      if front.floor_height > back.floor_height
        @open_bottom = front.floor_height
        @low_floor = back.floor_height
      else
        @open_bottom = back.floor_height
        @low_floor = front.floor_height
      end

      @open_range = @open_top - @open_bottom
    end
  end
end
