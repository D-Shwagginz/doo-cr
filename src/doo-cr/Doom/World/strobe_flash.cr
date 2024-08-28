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
  class StrobeFlash < Thinker
    class_getter strobe_bright : Int32 = 5
    class_getter fast_dark : Int32 = 15
    class_getter slow_dark : Int32 = 35

    @world : World | Nil = nil

    property sector : Sector | Nil = nil
    property count : Int32 = 0
    property min_light : Int32 = 0
    property max_light : Int32 = 0
    property dark_time : Int32 = 0
    property bright_time : Int32 = 0

    def initialize(@world)
    end

    def run
      @count -= 1
      return if @count > 0

      if @sector.as(Sector).light_level == @min_light
        @sector.as(Sector).light_level = @max_light
        @count = @bright_time
      else
        @sector.as(Sector).light_level = @min_light
        @count = @dark_time
      end
    end
  end
end
