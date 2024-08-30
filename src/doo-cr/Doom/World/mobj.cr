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

require "./thinker.cr"

module Doocr
  #
  # NOTES: mobj_t
  #
  # mobj_ts are used to tell the refresh where to draw an image,
  # tell the world simulation when objects are contacted,
  # and tell the sound driver how to position a sound.
  #
  # The refresh uses the next and prev links to follow
  # lists of things in sectors as they are being drawn.
  # The sprite, frame, and angle elements determine which patch_t
  # is used to draw the sprite if it is visible.
  # The sprite and frame values are allmost allways set
  # from state_t structures.
  # The statescr.exe utility generates the states.h and states.c
  # files that contain the sprite/frame numbers from the
  # statescr.txt source file.
  # The xyz origin point represents a point at the bottom middle
  # of the sprite (between the feet of a biped).
  # This is the default origin position for patch_ts grabbed
  # with lumpy.exe.
  # A walking creature will have its z equal to the floor
  # it is standing on.
  #
  # The sound code uses the x,y, and subsector fields
  # to do stereo positioning of any sound effited by the mobj_t.
  #
  # The play simulation uses the blocklinks, x,y,z, radius, height
  # to determine when mobj_ts are touching each other,
  # touching lines in the map, or hit by trace lines (gunshots,
  # lines of sight, etc).
  # The mobj_t->flags element has various bit flags
  # used by the simulation.
  #
  # Every mobj_t is linked into a single sector
  # based on its origin coordinates.
  # The subsector_t is found with R_PointInSubsector(x,y),
  # and the sector_t can be found with subsector->sector.
  # The sector links are only used by the rendering code,
  # the play simulation does not care about them at all.
  #
  # Any mobj_t that needs to be acted upon by something else
  # in the play world (block movement, be shot, etc) will also
  # need to be linked into the blockmap.
  # If the thing has the MF_NOBLOCK flag set, it will not use
  # the block links. It can still interact with other things,
  # but only as the instigator (missiles will run into other
  # things, but nothing can run into a missile).
  # Each block in the grid is 128*128 units, and knows about
  # every line_t that it contains a piece of, and every
  # interactable mobj_t that has its origin contained.
  #
  # A valid mobj_t is a mobj_t that has the proper subsector_t
  # filled in for its xy coordinates and is linked into the
  # sector from which the subsector was made, or has the
  # MF_NOSECTOR flag set (the subsector_t needs to be valid
  # even if MF_NOSECTOR is set), and is linked into a blockmap
  # block or has the MF_NOBLOCKMAP flag set.
  # Links should only be modified by the P_[Un]SetThingPosition()
  # functions.
  # Do not change the MF_NO? flags while a thing is valid.
  #
  # Any questions?
  #
  class Mobj < Thinker
    class_getter on_floor_z : Fixed = Fixed.min_value
    class_getter on_ceiling_z : Fixed = Fixed.max_value

    getter world : World | Nil = nil

    # Info for drawing: position.
    property x : Fixed = Fixed.zero
    property y : Fixed = Fixed.zero
    property z : Fixed = Fixed.zero

    # More list: links in sector (if needed).
    property sector_next : Mobj | Nil = nil
    property sector_prev : Mobj | Nil = nil

    # More drawing info: to determine current sprite.
    property angle : Angle = Angle.ang0      # Orientation
    property sprite : Sprite = Sprite.new(0) # Used to find patch_t and flip value.
    property frame : Int32 = 0               # Might be ORed with FF_FULLBRIGHT.

    # Interaction info, by BLOCKMAP.
    # Links in blocks (if needed).
    property block_next : Mobj | Nil = nil
    property block_prev : Mobj | Nil = nil

    property subsector : Subsector | Nil = nil

    # The closest interval over all contacted Sectors.
    property floor_z : Fixed = Fixed.zero
    property ceiling_z : Fixed = Fixed.zero

    # For movement checking.
    property radius : Fixed = Fixed.zero
    property height : Fixed = Fixed.zero

    # Momentums, used to update position.
    property mom_x : Fixed = Fixed.zero
    property mom_y : Fixed = Fixed.zero
    property mom_z : Fixed = Fixed.zero

    # If == valid_count, already checked.
    property valid_count : Int32 = 0

    property type : MobjType = MobjType.new(0)
    property info : MobjInfo | Nil = nil

    property tics : Int32 = 0 # State tic counter.
    property state : MobjStateDef | Nil = nil
    property flags : MobjFlags = MobjFlags.new(0)
    property health : Int32 = 0

    # Movement direction, movement generation (zig-zagging).
    property move_dir : Direction = Direction.new(0)
    property move_count : Int32 = 0 # When 0, select a new dir.

    # Thing being chased / attacked (or null),
    # also the originator for missiles.
    property target : Mobj | Nil = nil

    # Reaction time: if non 0, don't attack yet.
    # Used by player to freeze a bit after teleporting.
    property reaction_time : Int32 = 0

    # If >0, the target will be chased
    # no matter what (even if shot).
    property threshold : Int32 = 0

    # Additional info record for player avatars only.
    # Only valid if type == MT_PLAYER
    property player : Player | Nil = nil

    # Player number last looked for.
    property last_look : Int32 = 0

    # For nightmare respawn.
    property spawn_point : MapThing | Nil = nil

    # Thing being chased/attacked for tracers.
    property tracer : Mobj | Nil = nil

    # For frame interpolation.
    @interpolate : Bool = false
    @old_x : Fixed = Fixed.zero
    @old_y : Fixed = Fixed.zero
    @old_z : Fixed = Fixed.zero

    def initialize(@world)
    end

    def run
      # Momentum movement.
      if (@mom_x != Fixed.zero || @mom_y != Fixed.zero ||
         (@flags & MobjFlags::SkullFly).to_i32 != 0)
        @world.as(World).thing_movement.as(ThingMovement).x_y_movement(self)

        # Mobj was removed.
        return if @thinker_state == ThinkerState::Removed
      end

      if (@z != @floor_z) || @mom_z != Fixed.zero
        @world.as(World).thing_movement.as(ThingMovement).z_movement(self)

        # Mobj was removed.
        return if @thinker_state == ThinkerState::Removed
      end

      # Cycle through states,
      # calling action functions at transitions.
      if @tics != -1
        @tics -= 1

        # You can cycle through multiple states in a tic.
        if @tics == 0
          if !set_state(@state.as(MobjStateDef).next)
            # Freed itself.
            return
          end
        end
      else
        # Check for nightmare respawn.
        return if (@flags & MobjFlags::CountKill).to_i32 == 0

        options = @world.as(World).options
        return if !(options.skill == GameSkill::Nightmare || options.respawn_monsters)

        @move_count += 1

        return if @move_count < 12 * 35

        return if (@world.as(World).level_time & 31 != 0)

        return if @world.as(World).random.next > 4

        nightmare_respawn()
      end
    end

    def set_state(state : MobjState) : Bool
      y = true
      while y || @tics == 0
        y = false
        if state == MobjState::Nil
          @state = DoomInfo.states[MobjState::Nil.to_i32]
          @world.as(World).thing_allocation.as(ThingAllocation).remove_mobj(self)
          return false
        end

        st = DoomInfo.states[state.to_i32]
        @state = st
        @tics = get_tics(st)
        @sprite = st.sprite
        @frame = st.frame

        # Modified handling.
        # Call action functions when the state is set.
        if (x = st.mobj_action) && st.mobj_action.responds_to?(:call)
          x.call(@world.as(World), self)
        end

        state = st.next
      end

      return true
    end

    private def get_tics(state : MobjStateDef) : Int32
      options = @world.as(World).options
      if options.fast_monsters || options.skill == GameSkill::Nightmare
        if (MobjState::SargRun1.to_i32 <= @state.as(MobjStateDef).number &&
           @state.as(MobjStateDef).number <= MobjState::SargPain2.to_i32)
          return @state.as(MobjStateDef).tics >> 1
        else
          return @state.as(MobjStateDef).tics
        end
      else
        return @state.as(MobjStateDef).tics
      end
    end

    private def nightmare_respawn
      sp : MapThing
      if @spawn_point != nil
        sp = @spawn_point.as(MapThing)
      else
        sp = MapThing.empty
      end

      # Something is occupying it's position?
      if !@world.as(World).thing_movement.as(ThingMovement).check_position(self, sp.x, sp.y)
        # No respawn.
        return
      end

      ta = @world.as(World).thing_allocation.as(ThingAllocation)

      # Spawn a teleport fog at old spot.
      fog1 = ta.spawn_mobj(
        @x, @y,
        @subsector.as(Subsector).sector.floor_height,
        MobjType::Tfog
      )

      # Initiate teleport sound.
      @world.as(World).start_sound(fog1, Sfx::TELEPT, SfxType::Misc)

      # Spawn a teleport fog at the new spot.
      ss = Geometry.point_in_subsector(sp.x, sp.y, @world.as(World).map.as(Map))

      fog2 = ta.spawn_mobj(
        sp.x, sp.y,
        ss.sector.floor_height, MobjType::Tfog
      )
      @world.as(World).start_sound(fog2, Sfx::TELEPT, SfxType::Misc)

      # Spawn the new monster.
      z : Fixed
      if (@info.as(MobjInfo).flags & MobjFlags::SpawnCeiling).to_i32 != 0
        z = @@on_ceiling_z
      else
        z = @@on_floor_z
      end

      # Inherit attributes from deceased one.
      mobj = ta.spawn_mobj(sp.x, sp.y, z, type)
      mobj.spawn_point = @spawn_point
      mobj.angle = sp.angle

      if (sp.flags & ThingFlags::Ambush).to_i32 != 0
        mobj.flags |= MobjFlags::Ambush
      end

      mobj.reaction_time = 18

      # Remove the old monster.
      @world.as(World).thing_allocation.as(ThingAllocation).remove_mobj(self)
    end

    def update_frame_interpolation_info
      @interpolate = true
      @old_x = @x
      @old_y = @y
      @old_z = @z
    end

    def disable_frame_interpolation_for_one_frame
      @interpolate = false
    end

    def get_interpolated_x(frame_frac : Fixed) : Fixed
      if @interpolate
        return @old_x + frame_frac * (@x - @old_x)
      else
        return @x
      end
    end

    def get_interpolated_y(frame_frac : Fixed) : Fixed
      if @interpolate
        return @old_y + frame_frac * (@y - @old_y)
      else
        return @y
      end
    end

    def get_interpolated_z(frame_frac : Fixed) : Fixed
      if @interpolate
        return @old_z + frame_frac * (@z - @old_z)
      else
        return @z
      end
    end
  end
end
