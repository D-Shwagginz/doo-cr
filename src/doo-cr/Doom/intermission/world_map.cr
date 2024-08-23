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
  module WorldMap
    @@locations : Array(Array(Point)) = [
      # Episode 0 world map.
      [
        Point.new(185, 164), # location of level 0 (CJ)
        Point.new(148, 143), # location of level 1 (CJ)
        Point.new(69, 122),  # location of level 2 (CJ)
        Point.new(209, 102), # location of level 3 (CJ)
        Point.new(116, 89),  # location of level 4 (CJ)
        Point.new(166, 55),  # location of level 5 (CJ)
        Point.new(71, 56),   # location of level 6 (CJ)
        Point.new(135, 29),  # location of level 7 (CJ)
        Point.new(71, 24),   # location of level 8 (CJ)
      ],

      # Episode 1 world map should go here.
      [
        Point.new(254, 25),  # location of level 0 (CJ)
        Point.new(97, 50),   # location of level 1 (CJ)
        Point.new(188, 64),  # location of level 2 (CJ)
        Point.new(128, 78),  # location of level 3 (CJ)
        Point.new(214, 92),  # location of level 4 (CJ)
        Point.new(133, 130), # location of level 5 (CJ)
        Point.new(208, 136), # location of level 6 (CJ)
        Point.new(148, 140), # location of level 7 (CJ)
        Point.new(235, 158), # location of level 8 (CJ)
      ],

      # Episode 2 world map should go here.
      [
        Point.new(156, 168), # location of level 0 (CJ)
        Point.new(48, 154),  # location of level 1 (CJ)
        Point.new(174, 95),  # location of level 2 (CJ)
        Point.new(265, 75),  # location of level 3 (CJ)
        Point.new(130, 48),  # location of level 4 (CJ)
        Point.new(279, 23),  # location of level 5 (CJ)
        Point.new(198, 48),  # location of level 6 (CJ)
        Point.new(140, 25),  # location of level 7 (CJ)
        Point.new(281, 136), # location of level 8 (CJ)
      ],
    ]

    class Point
      getter x : Int32
      getter y : Int32

      def initialize(@x, @y)
      end
    end
  end
end
