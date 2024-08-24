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
  class GlowingLight < Thinker
    @@glow_speed : Int32 = 8

    @world : World | Nil = nil

    property sector : Sector | Nil = nil
    property min_light : Int32 = 0
    property max_light : Int32 = 0
    property direction : Int32 = 0

    def initialize(@world)
    end

    def run
      case @direction
      when -1
        # Down.
        @sector.light_level -= @@glow_speed
        if @sector.light_level <= @min_light
          @sector.light_level += @@glow_speed
          @direction = 1
        end
        break
      when 1
        # Up.
        @sector.light_level += @@glow_speed
        if @sector.light_level >= @max_light
          @sector.light_level -= @@glow_speed
          @direction = -1
        end
        break
      end
    end
  end
end