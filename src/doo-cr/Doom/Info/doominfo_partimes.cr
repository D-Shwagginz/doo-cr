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
  module DoomInfo
    module ParTimes
      class_getter doom1 : Array(Array(Int32)) = [
        [30, 75, 120, 90, 165, 180, 180, 30, 165],
        [90, 90, 90, 120, 90, 360, 240, 30, 170],
        [90, 45, 90, 150, 90, 90, 165, 30, 135],
        [165, 255, 135, 150, 180, 390, 135, 360, 180],
      ]

      class_getter doom2 : Array(UInt32) = [
        30, 90, 120, 120, 90, 150, 120, 120, 270, 90,
        210, 150, 150, 150, 210, 150, 420, 150, 210, 150,
        240, 150, 180, 150, 150, 300, 330, 420, 300, 180,
        120, 30,
      ]
    end
  end
end
