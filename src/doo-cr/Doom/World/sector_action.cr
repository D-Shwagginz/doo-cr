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
  class SectorAction
    # SECTOR HEIGHT CHANGING
    # After modifying a sectors floor or ceiling height,
    # call this routine to adjust the positions
    # of all things that touch the sector.
    #
    # If anything doesn't fit anymore, true will be returned.
    # If crunch is true, they will take damage
    # as they are being crushed.
    # If Crunch is false, you should set the sector height back
    # the way it was and call P_ChangeSector again
    # to undo the changes.

    @world : World | Nil

    def initialize(@world)
      init_sector_change()
    end

    @crush_change : Bool = false
    @no_fit : Bool = false
    @crush_thing_func : Proc(Mobj, Bool) | Nil

    private def init_sector_change
      @crush_thing_func = crush_thing()
    end

    private def thing_height_clip(thing : Mobj) : Bool
      on_floor = thing.z == thing.floor_z

      tm = @world.thing_movement

      tm.check_position(thing, thing.x, thing.y)
      # What about stranding a monster partially off an edge?

      thing.floor_z = tm.current_floor_z
      thing.ceiling_z = tm.current_ceiling_z

      if on_floor
        # Walking monsters rise and fall with the floor.
        thing.z = thing.floor_z
      else
        # Don't adjust a floating monster unless forced to.
        if thing.z + thing.height > thing.ceiling_z
          thing = thing.ceiling_z - thing.height
        end
      end

      return false if thing.ceiling_z - thing.floor_z < thing.height

      return true
    end

    private def crush_thing(thing : Mobj) : Bool
      if thing_height_clip(thing)
        # Keep checking.
        return true
      end

      # Crunch bodies to giblets.
      if thing.health <= 0
        thing.set_state(MobjState::Gibs)
        thing.flags &= ~MobjFlags::Solid
        thing.height = Fixed.zero
        thing.radius = Fixed.zero

        # Keep checking.
        return true
      end

      # Crunch dropped items.
      if (thing.flags & MobjFlags::Dropped) != 0
        @world.thing_allocation.remove_mobj(thing)

        # Keep checking.
        return true
      end

      if (thing.flags & MobjFlags::Shootable) == 0
        # Assume it is bloody gibs or something
        return true
      end

      @no_fit = true

      if @crush_change && (@world.level_time & 3) == 0
        @world.thing_interaction.damage_mobj(thing, nil, nil, 10)

        # Spray blood in a random direction.
        blood = @world.thing_allocation.spawn_mobj(
          thing.x,
          thing.y,
          thing.z + thing.height / 2,
          MobjType::Blood
        )

        random = @world.random
        blood.mom_x = Fixed.new((random.next - random.next) << 12)
        blood.mom_y = Fixed.new((random.next - random.next) << 12)
      end

      # Keep checking (crush other things).
      return true
    end

    private def change_sector(sector : Sector, crunch : Bool) : Bool
      @no_fit = false
      @crush_change = crunch

      bm = @world.map.block_map
      block_box = sector.block_box

      # Re-check heights for all things near the moving sector.
      x = block_box.left
      while x <= block_box.right
        y = block_box.bottom
        while y <= block_box.top
          bm.iterate_things(x, y, @crush_thing_func)
          y += 1
        end
        x += 1
      end

      return @no_fit
    end

    # Move a plane (floor or ceiling) and check for crushing.
    def move_plane(
      sector : Sector,
      speed : Fixed,
      dest : Fixed,
      crush : Bool,
      floor_or_ceiling : Int32,
      direction : Int32
    ) : SectorActionResult
    end
  end
end
