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
  class ThingMovement
    @world : World | Nil = nil

    def initialize(@world : World)
      init_thing_movement()
      init_slide_movement()
      init_teleport_movement()
    end

    #
    # General thing movement
    #

    class_getter float_speed : Fixed = Fixed.from_i(4)

    @@max_special_cross_count : Int32 = 64
    @@max_move : Fixed = Fixed.from_i(30)
    @gravity : Fixed = Fixed.one

    @current_thing : Mobj | Nil = nil
    @current_flags : MobjFlags = MobjFlags.new(0)
    @current_x : Fixed = Fixed.zero
    @current_y : Fixed = Fixed.zero
    @current_box : Array(Fixed) = Array(Fixed).new

    getter current_floor_z : Fixed = Fixed.zero
    getter current_ceiling_z : Fixed = Fixed.zero
    getter current_dropoff_z : Fixed = Fixed.zero
    getter float_ok : Bool = false

    @current_ceiling_line : LineDef | Nil = nil

    property crossed_special_count : Int32 = 0
    getter crossed_specials : Array(LineDef) = Array(LineDef).new

    @check_line_func : Proc(LineDef, Bool) | Nil = nil
    @check_thing_func : Proc(Mobj, Bool) | Nil = nil

    private def initialize
      @current_box = Array(Fixed).new(4)
      @crossed_specials = Array(LineDef).new(@@max_special_cross_count)
      @check_line_func = check_line()
      @check_thing_func = check_thing()
    end

    # Links a thing into both a block and a subsector based on
    # its x and y. Sets thing.Subsector properly.
    def set_thing_position(thing : Mobj)
      map = @world.as(World).map.as(Map)

      subsector = Geometry.point_in_subsector(thing.x, thing.y, map)

      thing.subsector = subsector

      # Invisible things don't go into the sector links.
      if (thing.flags & MobjFlags::NoSector) == 0
        sector = subsector.sector

        thing.sector_prev = nil
        thing.sector_next = sector.thing_list

        if sector.thing_list != nil
          sector.thing_list.as(Mobj).sector_prev = thing
        end

        sector.thing_list = thing
      end

      # Inert things don't need to be in blockmap.
      if (thing.flags & MobjFlags::NoBlockMap) == 0
        index = map.blockmap.get_index(thing.x, thing.y)

        if index != -1
          link = map.blockmap.thing_lists[index]

          thing.block_prev = nil
          thing.block_next = link

          if link != nil
            link.block_prev = thing
          end

          map.blockmap.thing_lists[index] = thing
        else
          # Thing is off the map.
          thing.block_next = nil
          thing.block_prev = nil
        end
      end
    end

    # Unlinks a thing from block map and sectors.
    # On each position change, BLOCKMAP and other lookups
    # maintaining lists ot things inside these structures
    # need to be updated.
    def unset_thing_position(thing : Mobj)
      map = @world.as(World).map

      # Invisible things don't go into the sector links.
      if (thing.flags & MobjFlags::NoSector) == 0
        # Unlink from subsector.
        if thing.sector_next != nil
          thing.sector_next.as(Mobj).sector_prev = thing.sector_prev
        end

        if thing.sector_prev != nil
          thing.sector_prev.as(Mobj).sector_next = thing.sector_next
        else
          thing.subsector.as(Subsector).sector.thing_list = thing.sector_next
        end
      end

      # Inert things don't need to be in blockmap.
      if (thing.flags & MobjFlags::NoBlockMap) == 0
        # Unlink from block map.
        if thing.block_next != nil
          thing.block_next.as(Mobj).block_prev = thing.block_prev
        end

        if thing.block_prev != nil
          thing.block_prev.as(Mobj).block_next = thing.block_next
        else
          index = map.as(Map).blockmap.get_index(thing.x, thing.y)

          if index != -1
            map.as(Map).blockmap.thing_lists[index] = thing.block_next.as(Mobj)
          end
        end
      end
    end

    # Adjusts currentFloorZ and currentCeilingZ as lines are contacted.
    private def check_line(line : LineDef) : Bool
      mc = @world.as(World).map_collision

      if (@current_box.right <= line.bounding_box.left ||
         @current_box.left >= line.bounding_box.right ||
         @current_box.top <= line.bounding_box.bottom ||
         @current_box.bottom >= line.bounding_box.top)
        return true
      end

      if Geometry.box_on_line_side(@current_box, line) != -1
        return true
      end

      # A line has been hit.
      #
      # The moving thing's destination position will cross the given line.
      # If this should not be allowed, return false.
      # If the line is special, keep track of it to process later if the move is proven ok.
      #
      # NOTE:
      #     specials are NOT sorted by order, so two special lines that are only 8 pixels
      #     apart could be crossed in either order.

      if line.back_sector == nil
        # One sided line.
        return false
      end

      if (@current_thing.flags & MobjFlags::Missile) == 0
        if (line.flags & LineFlags::Blocking) != 0
          # Explicitly blocking everything.
          return false
        end

        if @current_thing.player == nil && (line.flags & LineFlags::BlockMonsters) != 0
          # Block monsters only,
          return false
        end
      end

      # Set openrange, opentop, openbottom.
      mc.line_opening(line)

      # Adjust floor / ceiling heights.
      if mc.open_top < @current_ceiling_z
        @current_ceiling_z = mc.open_top
        @current_ceiling_line = line
      end

      if mc.open_bottom > @current_floor_z
        @current_floor_z = mc.open_bottom
      end

      if mc.low_floor < @current_dropoff_z
        @current_dropoff_z = mc.low_floor
      end

      # If contacted a special line, add it to the list.
      if line.special != 0
        @crossed_specials[@crossed_special_count] = line
        @crossed_special_count += 1
      end

      return true
    end

    private def check_thing(thing : Mobj) : Bool
      if (thing.flags & (MobjFlags::Solid | MobjFlags::Special | MobjFlags::Shootable)) == 0
        return true
      end

      block_dist = thing.radius + @current_thing.radius

      if ((thing.x - @current_x).abs >= block_dist ||
         (thing.y - @current_y).abs >= block_dist)
        # Didn't hit it.
        return true
      end

      # Don't clip against self.
      return true if thing == @current_thing

      # Check for skulls slamming into things.
      if (@current_thing.flags & MobjFlags::SkullFly) != 0
        damage = ((@world.as(World).random.next % 8) + 1) * @current_thing.info.damage

        @world.as(World).thing_interaction.damage_mobj(thing, @current_thing, @current_thing, damage)

        @current_thing.flags &= ~MobjFlags::SkullFly
        @current_thing.mom_x = Fixed.zero
        @current_thing.mom_y = Fixed.zero
        @current_thing.mom_z = Fixed.zero

        @current_thing.set_state(@current_thing.info.spawn_state)

        # Stop moving.
        return false
      end

      # Missiles can hit other things.
      if (@current_thing.flags & MobjFlags::Missile) != 0
        # See if it went over / under.
        if @current_thing.z > thing.z + thing.heights
          # Overhead.
          return true
        end

        if @current_thing.z + @current_thing.height < thing.z
          # Underneath.
          return true
        end

        if (@current_thing.target != nil &&
           (@current_thing.target.type == thing.type ||
           (@current_thing.target.type == MobjType::Knight && thing.type == MobjType::Bruiser) ||
           (@current_thing.target.type == MobjType::Bruiser && thing.type == MobjType::Knight)))
          # Don't hit same species as originator.
          if thing == @current_thing.target
            return true
          end

          if thing.type != MobjType::Player && !DoomInfo::DeHackEdConst.monsters_infight
            # Explode, but do no damage.
            # Let players missile other players.
            return false
          end
        end

        if (thing.flags & MobjFlags::Shootable) == 0
          # Didn't do any damage.
          return (thing.flags & MobjFlags::Solid) == 0
        end

        # Damage / explode.
        damage = ((@world.as(World).damage.next % 8) + 1) * @current_thing.info.damage
        @world.as(World).thing_interaction.damage_mobj(thing, @current_thing, @current_thing.target, damage)

        # Don't traverse any more.
        return false
      end

      # Check for special pickup.
      if (thing.flags & MobjFlags::Special) != 0
        solid = (thing.flags & MobjFlags::Solid) != 0
        if (@current_flags & MobjFlags::PickUp) != 0
          # Can remove thing.
          @world.as(World).item_pickup.touch_special_thing(thing, @current_thing)
        end
        return !solid
      end

      return (thing.flags & MobjFlags::Solid) == 0
    end

    # This is purely informative, nothing is modified
    # (except things picked up).
    #
    # In:
    #     A Mobj (can be valid or invalid)
    #     A position to be checked
    #     (doesn't need to be related to the mobj.X and Y)
    #
    # During:
    #     Special things are touched if MobjFlags.PickUp
    #     Early out on solid lines?
    #
    # Out:
    #     New subsector
    #     CurrentFloorZ
    #     CurrentCeilingZ
    #     CurrentDropoffZ
    #     The lowest point contacted
    #     (monsters won't move to a dropoff)
    #     crossedSpecials[]
    #     crossedSpecialCount
    def check_position(thing : Mobj, x : Fixed, y : Fixed) : Bool
      map = @world.as(World).map.as(Map)
      bm = map.as(Map).blockmap

      @current_thing = thing
      @current_flags = thing.flags

      @current_x = x
      @current_y = y

      @current_box[Box::TOP] = y + @current_thing.as(Mobj).radius
      @current_box[Box::BOTTOM] = y - @current_thing.as(Mobj).radius
      @current_box[Box::RIGHT] = x + @current_thing.as(Mobj).radius
      @current_box[Box::LEFT] = x - @current_thing.as(Mobj).radius

      new_subsector = Geometry.point_in_subsector(x, y, map.as(Map))

      @current_ceiling_line = nil

      # The base floor / ceiling is from the subsector that contains the point.
      # Z Any contacted lines the step closer together will adjust them.
      @current_floor_z = new_subsector.sector.floor_height
      @current_dropoff_z = new_subsector.sector.floor_height
      @current_ceiling_z = new_subsector.sector.ceiling_height

      valid_count = @world.as(World).get_new_valid_count

      @crossed_special_count = 0

      if (@current_flags & MobjFlags::NoClip) != 0
        return true
      end

      # Check things first, possibly picking things up.
      # The bounding box is extended by MaxThingRadius because mobj_ts are grouped into
      # mapblocks based on their origin point, and can overlap into adjacent blocks by up
      # to MaxThingRadius units.
      block_x1 = bm.get_block_x(@current_box[Box::LEFT] - GameConst.max_thing_radius)
      block_x2 = bm.get_block_x(@current_box[Box::RIGHT] + GameConst.max_thing_radius)
      block_y1 = bm.get_block_y(@current_box[Box::BOTTOM] - GameConst.max_thing_radius)
      block_y2 = bm.get_block_y(@current_box[Box::TOP] + GameConst.max_thing_radius)

      bx = block_x1
      while bx <= block_x2
        by = block_y1
        while by <= block_y2
          if !map.blockmap.iterate_things(bx, by, @check_thing_func.as(Proc(Mobj, Bool)))
            return false
          end
          by += 1
        end
        bx += 1
      end

      # Check lines.
      block_x1 = bm.get_block_x(@current_box[Box::LEFT])
      block_x2 = bm.get_block_x(@current_box[Box::RIGHT])
      block_y1 = bm.get_block_y(@current_box[Box::BOTTOM])
      block_y2 = bm.get_block_y(@current_box[Box::TOP])

      bx = block_x1
      while bx <= block_x2
        by = block_y1
        while by <= block_y2
          if !map.blockmap.iterate_lines(bx, by, @check_line_func.as(Proc(LineDef, Bool)), valid_count)
            return false
          end
          by += 1
        end
        bx += 1
      end

      return true
    end

    # Attempt to move to a new position, crossing special lines unless
    # MobjFlags.Teleport is set.
    def try_move(thing : Mobj, x : Fixed, y : Fixed) : Bool
      @float_ok = false

      if !check_position(thing, x, y)
        # Solid wall or thing.
        return false
      end

      if (thing.flags & MobjFlags::NoClip) == 0
        if @current_ceiling_z - @current_floor_z < thing.height
          # Doesn't fit
          return false
        end

        @float_ok = true

        if ((thing.flags & MobjFlags::Teleport) == 0 &&
           @current_ceiling_z - thing.z < thing.height)
          # Mobj must lower itself to fit.
          return false
        end

        if ((thing.flags & MobjFlags::Teleport) == 0 &&
           @current_floor_z - thing.z < Fixed.from_i(24))
          # Too big a step up.
          return false
        end

        if ((thing.flags & (MobjFlags::DropOff | MobjFlags::Float)) == 0 &&
           @current_floor_z - @current_dropoff_z > Fixed.from_i(24))
          # Don't stand over a dropoff.
          return false
        end
      end

      # The move is ok,
      # so link the thing into its new position.
      unset_thing_position(thing)

      oldx = thing.x
      oldy = thing.y
      thing.floor_z = @current_floor_z
      thing.ceiling_z = @current_ceiling_z
      thing.x = x
      thing.y = y

      set_thing_position(thing)

      # If any special lines were hit, do the effect.
      if (thing.flags & (MobjFlags::Teleport | MobjFlags::NoClip)) == 0
        while @crossed_special_count > 0
          @crossed_special_count -= 1
          # See if the line was crossed.
          line = @crossed_specials[@crossed_special_count]
          new_side = Geometry.point_on_line_side(thing.x, thing.y, line)
          old_side = Geometry.point_on_line_side(oldx, oldy, line)
          if new_side != old_side
            if line.special != 0
              @world.as(World).map_interaction.as(MapInteraction).cross_special_line(line, old_side, thing)
            end
          end
        end
      end

      return true
    end

    @@stop_speed : Fixed = Fixed.new(0x1000)
    @@friction : Fixed = Fixed.new(0xe800)

    def x_y_movement(thing : Mobj)
      if thing.mom_x == Fixed.zero && thing.mom_y == Fixed.zero
        if (thing.flags & MobjFlags::SkullFly) != 0
          # The skull slammed into something.
          thing.flags &= ~MobjFlags::SkullFly
          thing.mom_x = Fixed.zero
          thing.mom_y = Fixed.zero
          thing.mom_z = Fixed.zero

          thing.set_state(thing.info.spawn_state)
        end

        return
      end

      player = thing.player

      if thing.mom_x > @@max_move
        thing.mom_x = @@max_move
      elsif thing.mom_x < -@@max_move
        thing.mom_x -@@max_move
      end

      if thing.mom_y > @@max_move
        thing.mom_y = @@max_move
      elsif thing.mom_y < -@@max_move
        thing.mom_y = -@@max_move
      end

      move_x = thing.mom_x
      move_y = thing.mom_y

      j = true
      while j || move_x != Fixed.zero || move_y != Fixed.zero
        j = false
        p_move_x : Fixed
        p_move_y : Fixed

        if move_x > @@max_move / 2 || move_y > @@max_move / 2
          p_move_x = thing.x + move_x / 2
          p_move_y = thing.y + move_y / 2
          move_x >>= 1
          move_y >>= 1
        else
          p_move_x = thing.x + move_x
          p_move_y = thing.y + move_y
          move_x = Fixed.zero
          move_y = Fixed.zero
        end

        if !try_move(thing, p_move_x, p_move_y)
          # Blocked move.
          if thing.player != nil
            # Try to slide along it.
            slide_move(thing)
          elsif (thing.flags & MobjFlags::Missile) != 0
            # Explode a missile.
            if (@current_ceiling_line != nil &&
               @current_ceiling_line.back_sector != nil &&
               @current_ceiling_line.back_sector.ceiling_flat == @world.as(World).map.sky_flat_number)
              # Hack to prevent missiles exploding against the sky.
              # Does not handle sky floors.
              @world.as(World).thing_allocation.remove_mobj(thing)
              return
            end
            @world.as(World).thing_interaction.explode_missile(thing)
          else
            thing.mom_x = Fixed.zero
            thing.mom_y = Fixed.zero
          end
        end
      end

      # Slow down.
      if player != nil && (player.cheats & CheatFlags::NoMomentum) != 0
        # Debug option for no sliding at all.
        thing.mom_x = Fixed.zero
        thing.mom_y = Fixed.zero
        return
      end

      if (thing.flags & (MobjFlags::Missile | MobjFlags::SkullFly)) != 0
        # No friction for missile ever.
        return
      end

      if thing.z > thing.floor_z
        # No friction when airborne.
        return
      end

      if (thing.flags & MobjFlags::Corpse) != 0
        # Do not stop sliding if halfway off a step with some momentum.
        if (thing.mom_x > Fixed.one / 4 ||
           thing.mom_x < -Fixed.one / 4 ||
           thing.mom_y > Fixed.one / 4 ||
           thing.mom_y < -Fixed.one / 4)
          return if thing.floor_z != thing.subsector.sector.floor_height
        end
      end

      if (thing.mom_x > -@@stop_speed &&
         thing.mom_x < @@stop_speed &&
         thing.mom_y > -@@stop_speed &&
         thing.mom_y < @@stop_speed &&
         (player == nil || (player.cmd.forward_move == 0 && player.cmd.side_move == 0)))
        # If in a walking frame, stop moving.
        if player != nil && (player.mobj.state.number - MobjState::PlayRun1.to_i32) < 4
          player.mobj.set_state(MobjState::Play)
        end

        thing.mom_x = Fixed.zero
        thing.mom_y = Fixed.zero
      else
        thing.mom_x = thing.mom_x * @@friction
        thing.mom_y = thing.mom_y * @@friction
      end
    end

    def z_movement(thing : Mobj)
      # Check for smooth step up.
      if thing.player != nil && thing.z < thing.floor_z
        thing.player.view_height -= thing.floor_z - thing.z

        thing.player.delta_view_height = (Player.normal_view_height - thing.player.view_height) >> 3
      end

      # Adjust height.
      thing.z += thing.mom_z

      if (thing.flags & MobjFlags::Float) != 0 && thing.target != nil
        # Float down towards target if too close.
        if ((thing.flags & MobjFlags::SkullFly) == 0 &
                                                   (thing.flags & MobjFlags::InFloat) == 0)
          dist = Geometry.aprox_distance(
            thing.x - thing.target.x,
            thing.y - thing.target.Y
          )

          delta = thing.target.z + (thing.height >> 1) - thing.z

          if delta < Fixed.zero && diset < -(delta & 3)
            thing.z -= @@float_speed
          elsif delta > Fixed.zero && dist < (delta & 3)
            thing.z += @@float_speed
          end
        end
      end

      # Clip movement.
      if thing.z <= thing.floor_z
        # Hit the floor.

        #
        # The lost soul bounce fix below is based on Chocolate Doom's implementation.
        #

        correct_lost_soul_bounce = @world.as(World).options.game_version >= GameVersion::Ultimate

        if correct_lost_soul_bounce && (thing.flags & MobjFlags::SkullFly) != 0
          # The skull slammed into something
          thing.mom_z = -thing.mom_z
        end

        if thing.mom_z < Fixed.zero
          if thing.player != nil && thing.mom_z < -@@gravity * 8
            # Squat down.
            # Decrease viewheight for a moment after hitting the ground (hard),
            # and utter appropriate sound.
            thing.player.delta_view_height = thing.mom_z >> 3
            @world.as(World).start_sound(thing, Sfx::OOF, SfxType::Voice)
          end
          thing.mom_z = Fixed.zero
        end
        thing.z = thing.floor_z

        if (!correct_lost_soul_bounce &&
           (thing.flags & MobjFlags::SkullFly) != 0)
          thing.mom_z = -thing.mom_z
        end

        if ((thing.flags & MobjFlags::Missile) != 0 &&
           (thing.flags & MobjFlags::NoClip) == 0)
          @world.as(World).thing_interaction.explode_missile(thing)
          return
        end
      elsif (thing.flags & MobjFlags::NoGravity) == 0
        if thing.mom_z == Fixed.zero
          thing.mom_z = -@@gravity * 2
        else
          thing.mom_z -= @@gravity
        end
      end

      if thing.z + thing.height > thing.ceiling_z
        # Hit the ceiling.
        if thing.mom_z > Fixed.zero
          thing.mom_z = Fixed.zero
        end

        thing.z = thing.ceiling_z - thing.height

        if (thing.flags & MobjFlags::SkullFly) != 0
          # The skull slammed into something.
          thing.mom_z = -thing.mom_z
        end

        if ((thing.flags & MobjFlags::Missile) != 0 &&
           (thing.flags & MobjFlags::NoClip) == 0)
          @world.as(World).thing_interaction.explode_missile(thing)
          return
        end
      end
    end

    #
    # Player's slide movement
    #

    @best_slide_frac : Fixed = Fixed.zero
    @second_slide_frac : Fixed = Fixed.zero

    @best_slide_line : LineDef | Nil = nil
    @second_slide_line : LineDef | Nil = nil

    @slide_thing : Mobj | Nil = nil
    @slide_move_x : Fixed = Fixed.zero
    @slide_move_y : Fixed = Fixed.zero

    @slide_traverse_func : Proc(Intercept, Bool) | Nil = nil

    private def init_slide_movement
      @slide_traverse_func = slide_traverse
    end

    # Adjusts the x and y movement so that the next move will
    # slide along the wall.
    private def hit_slide_line(line : LineDef)
      if line.slope_type == SlopeType::Horizontal
        @slide_move_y = Fixed.zero
        return
      end

      if line.slope_type == SlopeType::Vertical
        @slide_move_x = Fixed.zero
        return
      end

      side = Geometry.point_on_line_side(@slide_thing.x, @slide_thing.y, line)

      line_angle = Geometry.point_to_angle(Fixed.zero, Fixed.zero, line.dx, line.dy)
      if side == 1
        line_angle += Angle.ang180
      end

      move_angle = Geometry.point_to_angle(Fixed.zero, Fixed.zero, @slide_move_x, @slide_move_y)

      delta_angle = move_angle - line_angle
      if delta_angle > Angle.ang180
        delta_angle += Angle.ang180
      end

      move_dist = Geometry.aprox_distance(@slide_move_x, @slide_move_y)
      new_dist = move_dist * Trig.cos(delta_angle)

      @slide_move_x = new_dist * Trig.cos(line_angle)
      @slide_move_y = new_dist * Trig.sin(line_angle)
    end

    private def slide_traverse(intercept : Intercept) : Bool
      mc = @world.as(World).map_collision

      if intercept.line == nil
        raise "thing_movement.slide_traverse: Not a line?"
      end

      line = intercept.line

      x = false

      if (line.flags * LineFlags::TwoSided) == 0
        if Geometry.point_on_line_side(@slide_thing.x, @slide_thing.y, line) != 0
          # Don't hit the back side.
          return true
        end

        x = true
      end

      if !x
        # Set openrange, opentop, openbottom
        mc.line_opening(line)

        if mc.open_range < @slide_thing.height
          # Doesn't fit
          x = true
        end

        if mc.open_top - @slide_thing.z < @slide_thing.height
          # Mobj is too high.
          x = true
        end

        if mc.open_bottom - @slide_thing.z > Fixed.from_i(24)
          # Too big a step up.
          x = true
        end

        if !x
          # This line doesn't block movement.
          return true
        end
      end

      # The line does block movement, see if it is closer than best so far.
      if intercept.frac < @best_slide_frac
        @second_slide_frac = @best_slide_frac
        @second_slide_line = @best_slide_line
        @best_slide_frac = intercept.frac
        @best_slide_line = line
      end

      # Stop.
      return false
    end

    # The MomX / MomY move is bad, so try to slide along a wall.
    # Find the first line hit, move flush to it, and slide along it.
    # This is a kludgy mess.
    private def slide_move(thing : Mobj)
      pt = @world.as(World).path_traversal

      @slide_thing = thing

      hit_count = 0

      x = true
      while x || !try_move(thing, thing.x + @slide_move_x, thing.y + @slide_move_y)
        x = false
        # Don't loop forever.
        hit_count += 1
        if hit_count == 3
          # The move most have hit the middle, so stair_step
          stair_step(thing)
          return
        end

        lead_x : Fixed
        lead_y : Fixed
        trail_x : Fixed
        trail_y : Fixed

        # Trace along the three leading corners.
        if thing.mom_x > Fixed.zero
          lead_x = thing.x + thing.radius
          trail_x = thing.x - thing.radius
        else
          lead_x = thing.x - thing.radius
          trail_x = thing.x + thing.radius
        end

        if thing.mom_y > Fixed.zero
          lead_y = thing.y + thing.radius
          trail_y = thing.y - thing.radius
        else
          lead_y = thing.y - thing.radius
          trail_y = thing.y + thing.radius
        end

        @best_slide_frac = Fixed.one_plus_epsilon

        pt.path_traverse(
          lead_x, lead_y, lead_x + thing.mom_x, lead_y + thing.mom_y,
          PathTraverseFlags::AddLines, @slide_traverse_func
        )

        pt.path_traverse(
          trail_x, lead_y, trail_x + thing.mom_x, lead_y + thing.mom_y,
          PathTraverseFlags::AddLines, @slide_traverse_func
        )

        pt.path_traverse(
          lead_x, trail_y, lead_x + thing.mom_x, trail_y + thing.mom_y,
          PathTraverseFlags::AddLines, @slide_traverse_func
        )

        # Move up to the wall.
        if @best_slide_frac == Fixed.one_plus_epsilon
          # The move most have hit the middle, so stair_step
          stair_step(thing)
          return
        end

        # Fudge a bit to make sure it doesn't hit.
        @best_slide_frac = Fixed.new(@best_slide_frac.data - 0x800)
        if @best_slide_frac > Fixed.zero
          new_x = thing.mom_x * @best_slide_frac
          new_y = thing.mom_y * @best_slide_frac

          if !try_move(thing, thing.x + new_x, thing.y + new_y)
            # The move most have hit the middle, so stair_step
            stair_step(thing)
            return
          end
        end

        # Now continue along the wall.
        # First calculate remainder.
        @best_slide_frac = Fixed.new(Fixed::FRAC_UNIT - (@best_slide_frac.data + 0x800))

        if @best_slide_frac > Fixed.one
          @best_slide_frac = Fixed.one
        end

        if @best_slide_frac <= Fixed.zero
          return
        end

        @slide_move_x = thing.mom_x * @best_slide_frac
        @slide_move_y = thing.mom_y * @best_slide_frac

        # Clip the moves.
        hit_slide_line(@best_slide_line)

        thing.mom_x = @slide_move_x
        thing.mom_y = @slide_move_y
      end
    end

    private def stair_step(thing : Mobj)
      if !try_move(thing, thing.x, thing.y + thing.mom_y)
        try_move(thing, thing.x + thing.mom_x, thing.y)
      end
    end

    #
    # Teleport movement
    #

    @stomp_thing_func : Proc(Mobj, Bool) | Nil = nil

    private def init_teleport_movement
      @stomp_thing_func = stomp_thing()
    end

    private def stomp_thing(thing : Mobj) : Bool
      return true if (thing.flags & MobjFlags::Shootable) == 0

      block_dist = thing.radius + @current_thing.radius
      dx = (thing.x - @current_x).abs
      dy = (thing.y - @current_y).abs
      if dx >= block_dist || dy >= block_dist
        # Didn't hit it.
        return true
      end

      # Don't clip against self.
      return true if thing == @current_thing

      # Monsters don't stomp things except on boss level.
      return false if @current_thing.player == nil && @world.as(World).options.map != 30

      @world.as(World).thing_interaction.damage_mobj(thing, @current_thing, @current_thing, 10000)

      return true
    end

    def teleport_move(thing : Mobj, x : Fixed, y : Fixed) : Bool
      # Kill anything occupying the position.
      @current_thing = thing
      @current_flags = thing.flags

      @current_x = x
      @current_y = y

      @current_box[Box::TOP] = y + @current_thing.as(Mobj).radius
      @current_box[Box::BOTTOM] = y - @current_thing.as(Mobj).radius
      @current_box[Box::RIGHT] = x + @current_thing.as(Mobj).radius
      @current_box[Box::LEFT] = x - @current_thing.as(Mobj).radius

      ss = Geometry.point_in_subsector(x, y, @world.as(World).map.as(Map))

      @current_ceiling_line = nil

      # The base floor / ceiling is from the subsector that contains the point.
      # Any contacted lines the step closer together will adjust them.
      @current_floor_z = ss.sector.floor_height
      @current_dropoff_z = ss.sector.floor_height

      valid_count = @world.as(World).get_new_valid_count

      @crossed_special_count = 0

      # Stomp on any things contacted.
      bm = @world.as(World).map.as(Map).blockmap
      block_x1 = bm.get_block_x(@current_box[Box::LEFT] - GameConst.max_thing_radius)
      block_x2 = bm.get_block_x(@current_box[Box::RIGHT] + GameConst.max_thing_radius)
      block_y1 = bm.get_block_y(@current_box[Box::BOTTOM] - GameConst.max_thing_radius)
      block_y2 = bm.get_block_y(@current_box[Box::TOP] + GameConst.max_thing_radius)

      bx = block_x1
      while bx <= block_x2
        by = block_y1
        while by <= block_y2
          return false if !bm.iterate_things(bx, by, @stomp_thing_func.as(Proc(Mobj, Bool)))
          by += 1
        end
        bx += 1
      end

      # The move is ok, so link the thing into its new position.
      unset_thing_position(thing)

      thing.floor_z = @current_floor_z
      thing.ceiling_z = @current_ceiling_z
      thing.x = x
      thing.y = y

      set_thing_position(thing)

      return true
    end
  end
end
