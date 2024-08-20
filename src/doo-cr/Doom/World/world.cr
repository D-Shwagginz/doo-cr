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
  class World
    @options : GameOptions | Nil
    @game : DoomGame | Nil
    @random : DoomRandom | Nil

    @map : Map | Nil

    @thinkers : Thinkers | Nil
    @specials : Specials | Nil
    @thing_allocation : ThingAllocation | Nil
    @thing_movement : ThingMovement | Nil
    @thing_interaction : ThingInteraction | Nil
    @map_collision : MapCollision | Nil
    @map_interaction : MapInteraction | Nil
    @path_traversal : PathTraversal | Nil
    @hitscan : Hitscan | Nil
    @visibility_check : VisibilityCheck | Nil
    @sector_action : SectorAction | Nil
  end
end
