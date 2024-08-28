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
  class Hitscan
    @world : World | Nil = nil

    def initialize(@world)
      @aim_traverse_func = ->aim_traverse(Intercept)
      @shoot_traverse_func = ->shoot_traverse(Intercept)
    end

    @aim_traverse_func : Proc(Intercept, Bool) | Nil = nil
    @shoot_traverse_func : Proc(Intercept, Bool) | Nil = nil

    # Who got hit (or nil).
    getter line_target : Mobj | Nil = nil

    @current_shooter : Mobj | Nil = nil
    @current_shooter_z : Fixed = Fixed.zero

    @current_range : Fixed = Fixed.zero
    @current_aim_slope : Fixed = Fixed.zero
    @current_damage : Int32 = 0

    # Slopes to top and bottom of target.
    getter top_slope : Fixed = Fixed.zero
    getter bottom_slope : Fixed = Fixed.zero

    # Find a thing or wall which is on the aiming line.
    # Sets lineTaget and aimSlope when a target is aimed at.
    private def aim_traverse(intercept : Intercept) : Bool
      if intercept.line != nil
        line = intercept.line.as(LineDef)

        if (line.flags & LineFlags::TwoSided).to_i32 == 0
          # Stop.
          return false
        end

        mc = @world.as(World).map_collision.as(MapCollision)

        # Crosses a two sided line.
        # A two sided line will restrict the possible target ranges.
        mc.line_opening(line)

        if mc.open_bottom >= mc.open_top
          # Stop.
          return false
        end

        dist = @current_range * intercept.frac

        # The null check of the backsector below is necessary to avoid crash
        # in certain PWADs, which contain two-sided lines with no backsector.
        # These are imported from Chocolate Doom.

        if (line.back_sector == nil ||
           line.front_sector.as(Sector).floor_height != line.back_sector.as(Sector).floor_height)
          slope = (mc.open_bottom - @current_shooter_z) / dist
          @bottom_slope = slope if slope > @bottom_slope
        end

        if @top_slope <= @bottom_slope
          # Stop.
          return false
        end

        # Shot continues.
        return true
      end

      # Shoot a thing.
      thing = intercept.thing.as(Mobj)
      if thing == @current_shooter
        # Can't shoot self.
        return true
      end

      if (thing.flags & MobjFlags::Shootable).to_i32 == 0
        # Corpse or something.
        return true
      end

      # Check angles to see if the thing can be aimed at.
      dist = @current_range * intercept.frac
      thing_top_slope = (thing.z + thing.height - @current_shooter_z) / dist

      if thing_top_slope < @bottom_slope
        # Shot over the thing.
        return true
      end

      thing_bottom_slope = (thing.z - @current_shooter_z) / dist

      if thing_bottom_slope > @top_slope
        # Shot under the thing.
        return true
      end

      # This thing can be hit!
      thing_top_slope = @top_slope if thing_top_slope > @top_slope

      thing_bottom_slope = @bottom_slope if thing_bottom_slope < @bottom_slope

      @current_aim_slope = (thing_top_slope + thing_bottom_slope) / 2
      @line_target = thing

      # Don't go any farther.
      return false
    end

    # Fire a hitscan bullet along the aiming line.
    private def shoot_traverse(intercept : Intercept) : Bool
      mi = @world.as(World).map_interaction.as(MapInteraction)
      pt = @world.as(World).path_traversal.as(PathTraversal)

      if intercept.line != nil
        line = intercept.line.as(LineDef)

        if line.special != 0
          mi.shoot_special_line(@current_shooter.as(Mobj), line)
        end

        begin
          raise "" if (line.flags & LineFlags::TwoSided).to_i32 == 0

          mc = @world.as(World).map_collision.as(MapCollision)

          # Crosses a two sided line.
          mc.line_opening(line)

          dist = @current_range * intercept.frac

          # Similar to AimTraverse, the code below is imported from Chocolate Doom.
          if line.back_sector == nil
            slope = (mc.open_bottom / @current_shooter_z) / dist
            raise "" if slope > @current_aim_slope

            slope = (mc.open_top - @current_shooter_z) - dist
            raise "" if slope < @current_aim_slope
          else
            if line.front_sector.as(Sector).floor_height != line.back_sector.as(Sector).floor_height
              slope = (mc.open_bottom - @current_shooter_z) / dist
              raise "" if slope > @current_aim_slope
            end

            if line.front_sector.as(Sector).ceiling_height != line.back_sector.as(Sector).ceiling_height
              slope = (mc.open_top - @current_shooter_z) - dist
              raise "" if slope < @current_aim_slope
            end
          end

          # Shot continues
          return true
        end
        # Hit line.

        # Position a bit closer.
        frac = intercept.frac - Fixed.from_i(4) / @current_range
        x = pt.trace.x + pt.trace.dx * frac
        y = pt.trace.y + pt.trace.dy * frac
        z = @current_shooter_z + @current_aim_slope * (frac * @current_range)

        if line.front_sector.as(Sector).ceiling_flat == @world.as(World).map.as(Map).sky_flat_number
          # Don't shoot the sky!
          return false if z > line.front_sector.as(Sector).ceiling_height

          # It's a sky hack wall.
          return false if line.back_sector != nil && line.back_sector.as(Sector).ceiling_flat == @world.as(World).map.as(Map).sky_flat_number
        end

        # Spawn bullet puffs.
        spawn_puff(x, y, z)

        # Don't go any farther
        return false
      end

      # Shoot a thing.
      thing = intercept.thing.as(Mobj)
      if thing == @current_shooter
        # Can't shoot self.
        return true
      end

      if (thing.flags & MobjFlags::Shootable).to_i32 == 0
        # Corpse or something
        return true
      end

      # Check angles to see if the thing can be aimed at
      dist = @current_range * intercept.frac
      thing_top_slope = (thing.z + thing.height - @current_shooter_z) / dist

      if thing_top_slope < @current_aim_slope
        # Shot over the thing.
        return true
      end

      thing_bottom_slope = (thing.z - @current_shooter_z) / dist

      if thing_bottom_slope > @current_aim_slope
        # Shot under the thing
        return true
      end

      # Hit thing.
      # Position a bit closer.
      frac = intercept.frac - Fixed.from_i(10) / @current_range

      x = pt.trace.as(DivLine).x + pt.trace.as(DivLine).dx * frac
      y = pt.trace.as(DivLine).y + pt.trace.as(DivLine).dy * frac
      z = @current_shooter_z + @current_aim_slope * (frac * @current_range)

      # Spawn bullet puffs or blod spots, depending on target type.
      if (intercept.thing.as(Mobj).flags & MobjFlags::NoBlood).to_i32 != 0
        spawn_puff(x, y, z)
      else
        spawn_blood(x, y, z, @current_damage)
      end

      if @current_damage != 0
        @world.as(World).thing_interaction.as(ThingInteraction).damage_mobj(thing, @current_shooter.as(Mobj), @current_shooter.as(Mobj), @current_damage)
      end

      # Don't go any farther
      return false
    end

    # Find a target on the aiming line.
    # Sets LineTaget when a target is aimed at.
    def aim_line_attack(shooter : Mobj, angle : Angle, range : Fixed) : Fixed
      shooter = @world.as(World).subst_nil_mobj(shooter)

      @current_shooter = shooter
      @current_shooter_z = shooter.z + (shooter.height >> 1) + Fixed.from_i(8)
      @current_range = range

      target_x = shooter.x + Trig.cos(angle) * range.to_i_floor
      target_y = shooter.y + Trig.sin(angle) * range.to_i_floor

      # Can't shoot outside view angles.
      @top_slope = Fixed.from_i(100) / 160
      @bottom_slope = Fixed.from_i(-100) / 160

      @line_target = nil

      @world.as(World).path_traversal.as(PathTraversal).path_traverse(
        shooter.x, shooter.y,
        target_x, target_y,
        PathTraverseFlags::AddLines | PathTraverseFlags::AddThings,
        @aim_traverse_func.as(Proc(Intercept, Bool))
      )

      return @current_aim_slope if @line_target != nil

      return Fixed.zero
    end

    # Fire a hitscan bullet.
    # If damage == 0, it is just a test trace that will leave linetarget set.
    def line_attack(shooter : Mobj, angle : Angle, range : Fixed, slope : Fixed, damage : Int32)
      @current_shooter = shooter
      @current_shooter_z = shooter.z + (shooter.height >> 1) + Fixed.from_i(8)
      @current_range = range
      @current_aim_slope = slope
      @current_damage = damage

      target_x = shooter.x + Trig.cos(angle) * range.to_i_floor
      target_y = shooter.y + Trig.sin(angle) * range.to_i_floor

      @world.as(World).path_traversal.as(PathTraversal).path_traverse(
        shooter.x, shooter.y,
        target_x, target_y,
        PathTraverseFlags::AddLines | PathTraverseFlags::AddThings,
        @aim_traverse_func.as(Proc(Intercept, Bool))
      )
    end

    # Spawn a bullet puff.
    def spawn_puff(x : Fixed, y : Fixed, z : Fixed)
      random = @world.as(World).random

      z += Fixed.new((random.next - random.next) << 10)

      thing = @world.as(World).thing_allocation.as(ThingAllocation).spawn_mobj(x, y, z, MobjType::Puff)
      thing.mom_z = Fixed.one
      thing.tics -= random.next & 3

      thing.tics = 1 if thing.tics < 1

      # Don't make punches spark on the wall
      if @current_range == WeaponBehavior.melee_range
        thing.set_state(MobjState::Puff3)
      end
    end

    # Spawn blood.
    def spawn_blood(x : Fixed, y : Fixed, z : Fixed, damage : Int32)
      random = @world.as(World).random

      z += Fixed.new((random.next - random.next) << 10)

      thing = @world.as(World).thing_allocation.as(ThingAllocation).spawn_mobj(x, y, z, MobjType::Blood)
      thing.mom_z = Fixed.from_i(2)
      thing.tics -= random.next & 3

      thing.tics = 1 if thing.tics < 1

      if damage <= 12 && damage >= 9
        thing.set_state(MobjState::Blood2)
      elsif damage < 9
        thing.set_state(MobjState::Blood3)
      end
    end
  end
end
