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
  class FireFlicker < Thinker
    @world : World | Nil = nil

    property sector : Sector | Nil = nil
    property count : Int32 = 0
    property max_light : Int32 = 0
    property min_light : Int32 = 0

    def initialize(@world)
    end

    def run
      @count -= 1
      return if @count > 0

      amount = (@world.as(World).random.next & 3) * 16

      if @sector.as(Sector).light_level - amount < @min_light
        @sector.as(Sector).light_level = @min_light
      else
        @sector.as(Sector).light_level = @max_light - amount
      end

      @count = 4
    end
  end
end
