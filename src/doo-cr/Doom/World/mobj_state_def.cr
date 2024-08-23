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
  class MobjStateDef
    property number : Int32
    property sprite : Sprite
    property frame : Int32
    property tics : Int32
    property player_action : Proc(World, Player, PlayerSpriteDef, Nil) | Nil = nil
    property mobj_action : Proc(World, Mobj, Nil) | Nil = nil
    property next : MobjState
    property misc1 : Int32
    property misc2 : Int32

    def initialize(
      @number,
      @sprite,
      @frame,
      @tics,
      @player_action,
      @mobj_action,
      @next,
      @misc1,
      @misc2
    )
    end
  end
end
