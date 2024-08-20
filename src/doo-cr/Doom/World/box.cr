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
  module Box
    TOP    = 0
    BOTTOM = 1
    LEFT   = 2
    RIGHT  = 3

    def self.clear(box : Array(Fixed))
      box[TOP] = Fixed.min_value
      box[RIGHT] = Fixed.min_value
      box[BOTTOM] = Fixed.max_value
      box[LEFT] = Fixed.max_value
    end

    def self.add_point(box : Array(Fixed), x : Fixed, y : Fixed)
      if x < box[LEFT]
        box[LEFT] = x
      elsif x > box[RIGHT]
        box[RIGHT] = x
      end

      if y < box[BOTTOM]
        box[BOTTOM] = y
      elsif y > box[TOP]
        box[TOP] = y
      end
    end
  end
end
