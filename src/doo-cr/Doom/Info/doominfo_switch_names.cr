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
    class_getter switch_names : Array(Tuple(DoomString, DoomString)) = [
      {DoomString.new("SW1BRCOM"), DoomString.new("SW2BRCOM")},
      {DoomString.new("SW1BRN1"), DoomString.new("SW2BRN1")},
      {DoomString.new("SW1BRN2"), DoomString.new("SW2BRN2")},
      {DoomString.new("SW1BRNGN"), DoomString.new("SW2BRNGN")},
      {DoomString.new("SW1BROWN"), DoomString.new("SW2BROWN")},
      {DoomString.new("SW1COMM"), DoomString.new("SW2COMM")},
      {DoomString.new("SW1COMP"), DoomString.new("SW2COMP")},
      {DoomString.new("SW1DIRT"), DoomString.new("SW2DIRT")},
      {DoomString.new("SW1EXIT"), DoomString.new("SW2EXIT")},
      {DoomString.new("SW1GRAY"), DoomString.new("SW2GRAY")},
      {DoomString.new("SW1GRAY1"), DoomString.new("SW2GRAY1")},
      {DoomString.new("SW1METAL"), DoomString.new("SW2METAL")},
      {DoomString.new("SW1PIPE"), DoomString.new("SW2PIPE")},
      {DoomString.new("SW1SLAD"), DoomString.new("SW2SLAD")},
      {DoomString.new("SW1STARG"), DoomString.new("SW2STARG")},
      {DoomString.new("SW1STON1"), DoomString.new("SW2STON1")},
      {DoomString.new("SW1STON2"), DoomString.new("SW2STON2")},
      {DoomString.new("SW1STONE"), DoomString.new("SW2STONE")},
      {DoomString.new("SW1STRTN"), DoomString.new("SW2STRTN")},
      {DoomString.new("SW1BLUE"), DoomString.new("SW2BLUE")},
      {DoomString.new("SW1CMT"), DoomString.new("SW2CMT")},
      {DoomString.new("SW1GARG"), DoomString.new("SW2GARG")},
      {DoomString.new("SW1GSTON"), DoomString.new("SW2GSTON")},
      {DoomString.new("SW1HOT"), DoomString.new("SW2HOT")},
      {DoomString.new("SW1LION"), DoomString.new("SW2LION")},
      {DoomString.new("SW1SATYR"), DoomString.new("SW2SATYR")},
      {DoomString.new("SW1SKIN"), DoomString.new("SW2SKIN")},
      {DoomString.new("SW1VINE"), DoomString.new("SW2VINE")},
      {DoomString.new("SW1WOOD"), DoomString.new("SW2WOOD")},
      {DoomString.new("SW1PANEL"), DoomString.new("SW2PANEL")},
      {DoomString.new("SW1ROCK"), DoomString.new("SW2ROCK")},
      {DoomString.new("SW1MET2"), DoomString.new("SW2MET2")},
      {DoomString.new("SW1WDMET"), DoomString.new("SW2WDMET")},
      {DoomString.new("SW1BRIK"), DoomString.new("SW2BRIK")},
      {DoomString.new("SW1MOD1"), DoomString.new("SW2MOD1")},
      {DoomString.new("SW1ZIM"), DoomString.new("SW2ZIM")},
      {DoomString.new("SW1STON6"), DoomString.new("SW2STON6")},
      {DoomString.new("SW1TEK"), DoomString.new("SW2TEK")},
      {DoomString.new("SW1MARB"), DoomString.new("SW2MARB")},
      {DoomString.new("SW1SKULL"), DoomString.new("SW2SKULL")},
    ]
  end
end
