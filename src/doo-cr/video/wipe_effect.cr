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

module Doocr::Video
  class WipeEffect
    getter y : Array(Int16)
    @height : Int32
    @random : DoomRandom

    def initialize(width : Int32, @height)
      @y = Array.new(width, 0_i16)
      @random = DoomRandom.new(Time.utc.millisecond)
    end

    def start
      y[0] = -(@random.next % 16).to_i16
      i = 1
      while i < @y.size
        r = (@random.next % 3) - 1
        @y[i] = (@y[i - 1] + r).to_i16
        if @y[i] > 0
          @y[i] = 0
        elsif @y[i] == -16
          @y[i] = -15
        end
        i += 1
      end
    end

    def update : UpdateResult
      done = true

      @y.size.times do |i|
        if @y[i] < 0
          @y[i] += 1
          done = false
        elsif @y[i] < @height
          dy = (@y[i] < 16) ? @y[i] + 1 : 8
          dy = @height - @y[i] if @y[i] + dy >= @height
          @y[i] += dy.to_i16
          done = false
        end
      end

      if done
        return UpdateResult::Completed
      else
        return UpdateResult::None
      end
    end
  end
end
