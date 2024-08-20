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
    class_getter texture_animation : Array(AnimationDef) = [
      AnimationDef.new(false, "NUKAGE3", "NUKAGE1", 8),
      AnimationDef.new(false, "FWATER4", "FWATER1", 8),
      AnimationDef.new(false, "SWATER4", "SWATER1", 8),
      AnimationDef.new(false, "LAVA4", "LAVA1", 8),
      AnimationDef.new(false, "BLOOD3", "BLOOD1", 8),

      # DOOM II flat animations.
      AnimationDef.new(false, "RROCK08", "RROCK05", 8),
      AnimationDef.new(false, "SLIME04", "SLIME01", 8),
      AnimationDef.new(false, "SLIME08", "SLIME05", 8),
      AnimationDef.new(false, "SLIME12", "SLIME09", 8),

      AnimationDef.new(true, "BLODGR4", "BLODGR1", 8),
      AnimationDef.new(true, "SLADRIP3", "SLADRIP1", 8),

      AnimationDef.new(true, "BLODRIP4", "BLODRIP1", 8),
      AnimationDef.new(true, "FIREWALL", "FIREWALA", 8),
      AnimationDef.new(true, "GSTFONT3", "GSTFONT1", 8),
      AnimationDef.new(true, "FIRELAVA", "FIRELAV3", 8),
      AnimationDef.new(true, "FIREMAG3", "FIREMAG1", 8),
      AnimationDef.new(true, "FIREBLU2", "FIREBLU1", 8),
      AnimationDef.new(true, "ROCKRED3", "ROCKRED1", 8),

      AnimationDef.new(true, "BFALL4", "BFALL1", 8),
      AnimationDef.new(true, "SFALL4", "SFALL1", 8),
      AnimationDef.new(true, "WFALL4", "WFALL1", 8),
      AnimationDef.new(true, "DBRAIN4", "DBRAIN1", 8),
    ]
  end
end
