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
  class MapInteraction
    @@use_range : Fixed = Fixed.from_int(64)

    @world : World | Nil

    def initialize(@world)
      init_use()
    end

    #
    # Line use
    #

    @use_thing : Mobj | Nil
    @use_traverse_func : Proc(Intercept, Bool) | Nil

    private def init_use
      @use_traverse_func = use_traverse()
    end

    private def use_traverse(intercept : Intercept) : Bool
      mc = @world.map_collision

      if intercept.line.special == 0
        mc.line_opening(intercept.line)
        if mc.open_range <= Fixed.zero
          @world.start_sound(@use_thing, Sfx::NOWAY, SfxType::Voice)

          # Can't use through a wall.
          return false
        end

        # Not a special line, but keep checking.
        return true
      end

      side = 0
      side = 1 if Geometry.point_on_line_side(@use_thing.x, @use_thing.y, intercept.line) == 1

      use_special_line(@use_thing, intercept.line, side)

      # Can't use for more than one special line in a row
      return false
    end

    # Looks for special lines in front of the player to activate.
    def use_lines(player : Player)
      pt = @world.path_traversal

      @use_thing = player.Mobj

      angle = player.mobj.angle

      x1 = player.mobj.x
      y1 = player.mobj.y
      x2 = x1 + @@use_range.to_int_floor * Trig.cos(angle)
      y2 = y1 + @@use_range.to_int_floor * Trig.sin(angle)

      pt.path_traverse(x1, y1, x2, y2, PathTraverseFlags::AddLines)
    end

    # Called when a thing uses a special line.
    # Only the front sides of lines are usable.
    def use_special_line(thing : Mobj, line : LineDef, side : Int32) : Bool
      specials = @world.specials
      sa = @world.sector_action

      # Err...
      # Use the back sides of VERY SPECIAL lines...
      if side != 0
        case line.special.to_i32
        when 124
          # Sliding door open and close (unused).
          break
        else
          return false
        end
      end

      # Switches that other things can activate.
      if thing.player == nil
        # Never open secret doors.
        if (line.Flags & LineFlags::Secret) != 0
          return false
        end

        case line.special.to_i32
        when 1 # Manual door raise.
          break
        when 32 # Manual blue.
          break
        when 33 # Manual red.
          break
        when 34 # Manual yellow.
          break
        else
          return false
        end
      end

      # Do something.
      case line.special.to_i32
      # MANUALS
      # Vertical door, Blue door (locked), Yellow door (locked), Red door (locked).
      # Manual door open, Blue locked door open, Red locked door open, Yellow locked door open.
      # Blazing door raise, Blazing door open.
      when 1, 26, 27, 28, 31, 32, 33, 34, 117, 118
        sa.do_local_door(line, thing)
        break

        # SWITCHES
      when 7
        # Build stairs.
        if sa.build_stairs(line, StairType::Build8)
          specials.change_switch_texture(line, false)
        end
        break
      when 9
        # Change donut.
        if sa.do_donut(line)
          specials.change_switch_texture(line, false)
        end
        break
      when 11
        # Exit level.
        specials.change_switch_texture(line, false)
        world.exit_level
        break
      when 14
        # Raise floor 32 and change texture.
        if sa.do_platform(line, PlatformType::RaiseAndChange, 32)
          specials.change_switch_texture(line, false)
        end
        break
      when 15
        # Raise floor 24 and change texture.
        if sa.do_platform(line, PlatformType::RaiseAndChange, 24)
          specials.change_switch_texture(line, false)
        end
        break
      when 18
        # Raise floor to next highest floor.
        if sa.do_floor(line, FloorMoveType::RaiseFloorToNearest)
          specials.change_switch_texture(line, false)
        end
        break
      when 20
        # Raise platform next highest floor and change texture.
        if sa.do_platform(line, PlatformType::RaiseToNearestAndChange, 0)
          specials.change_switch_texture(line, false)
        end
        break
      when 21
        # Platform down, wait, up and stay.
        if sa.do_platform(line, PlatformType::DownWaitUpStay, 0)
          specials.change_switch_texture(line, false)
        end
        break
      when 23
        # Lower floor to Lowest.
        if sa.do_floor(line, FloorMoveType::LowerFloorToLowest)
          specials.change_switch_texture(line, false)
        end
        break
      when 29
        # Raise door.
        if sa.do_door(line, VerticalDoorType::Normal)
          specials.change_switch_texture(line, false)
        end
        break
      when 41
        # Lower ceiling to floor.
        if sa.do_ceiling(line, CeilingMoveType::LowerToFloor)
          specials.change_switch_texture(line, false)
        end
        break
      when 71
        # Turbo lower floor.
        if sa.do_floor(line, FloorMoveType::TurboLower)
          specials.change_switch_texture(line, false)
        end
        break
      when 49
        # Ceiling crush and raise.
        if sa.do_ceiling(line, CeilingMoveType::CrushAndRaise)
          specials.change_switch_texture(line, false)
        end
        break
      when 50
        # Close door.
        if sa.do_door(line, VerticalDoorType::Close)
          specials.change_switch_texture(line, false)
        end
        break
      when 51
        # Secret exit.
        specials.change_switch_texture(line, false)
        world.secret_exit_level
        break
      when 55
        # Raise floor crush.
        if sa.do_floor(line, FloorMoveType::RaiseFloorCrush)
          specials.change_switch_texture(line, false)
        end
        break
      when 101
        # Raise floor.
        if sa.do_floor(line, FloorMoveType::RaiseFloor)
          specials.change_switch_texture(line, false)
        end
        break
      when 102
        # Lower floor to surrounding floor height.
        if sa.do_floor(line, FloorMoveType::LowerFloor)
          specials.change_switch_texture(line, false)
        end
        break
      when 103
        # Open door.
        if sa.do_door(line, VerticalDoorType::Open)
          specials.change_switch_texture(line, false)
        end
        break
      when 111
        # Blazing door raise (faster than turbo).
        if sa.do_door(line, VerticalDoorType::BlazeRaise)
          specials.change_switch_texture(line, false)
        end
        break
      when 112
        # Blazing door open (faster than turbo).
        if sa.do_door(line, VerticalDoorType::BlazeOpen)
          specials.change_switch_texture(line, false)
        end
        break
      when 113
        # Blazing door close (faster than turbo).
        if sa.do_door(line, VerticalDoorType::BlazeClose)
          specials.change_switch_texture(line, false)
        end
        break
      when 122
        # Blazing platform down, wait, up and stay.
        if sa.do_platform(line, PlatformType::BlazeDwus, 0)
          specials.change_switch_texture(line, false)
        end
        break
      when 127
        # Build stairs turbo 16.
        if sa.build_stairs(line, StairType::Turbo16)
          specials.change_switch_texture(line, false)
        end
        break
      when 131
        # Raise floor turbo.
        if sa.do_floor(line, FloorMoveType::RaiseFloorTurbo)
          specials.change_switch_texture(line, false)
        end
        break
      when 133, 135, 137 # Blazing open door (blue), Blazing open door (red), Blazing open door (yellow).
        if sa.do_locked_door(line, VerticalDoorType::BlazeOpen, thing)
          specials.change_switch_texture(line, false)
        end
        break
      when 140
        # Raise floor 512.
        if sa.do_floor(line, FloorMoveType::RaiseFloor512)
          specials.change_switch_texture(line, false)
        end
        break

        # BUTTONS
      when 42
        # Close door.
        if sa.do_door(line, VerticalDoorType::Close)
          specials.change_switch_texture(line, true)
        end
        break
      when 43
        # Lower ceiling to floor.
        if sa.do_ceiling(line, CeilingMoveType::LowerToFloor)
          specials.change_switch_texture(line, true)
        end
        break
      when 45
        # lower floor to surrounding floor height.
        if sa.do_floor(line, FloorMoveType::LowerFloor)
          specials.change_switch_texture(line, true)
        end
        break
      when 60
        # Lower floor to Lowest.
        if sa.do_floor(line, FloorMoveType::LowerFloorToLowest)
          specials.change_switch_texture(line, true)
        end
        break
      when 61
        # Open door.
        if sa.do_door(line, VerticalDoorType::Open)
          specials.change_switch_texture(line, true)
        end
        break
      when 62
        # Platform down, wait, up and stay.
        if sa.do_platform(line, PlatformType::DownWaitUpStay, 1)
          specials.change_switch_texture(line, true)
        end
        break
      when 63
        # Raise door.
        if sa.do_door(line, VerticalDoorType::Normal)
          specials.change_switch_texture(line, true)
        end
        break
      when 64
        # Raise floor to ceiling.
        if sa.do_floor(line, FloorMoveType::RaiseFloor)
          specials.change_switch_texture(line, true)
        end
        break
      when 66
        # Raise floor 24 and change texture.
        if sa.do_platform(line, PlatformType::RaiseAndChange, 24)
          specials.change_switch_texture(line, true)
        end
        break
      when 67
        # Raise floor 32 and change texture.
        if sa.do_platform(line, PlatformType::RaiseAndChange, 32)
          specials.change_switch_texture(line, true)
        end
        break
      when 65
        # Raise floor crush.
        if sa.do_floor(line, FloorMoveType::RaiseFloorCrush)
          specials.change_switch_texture(line, true)
        end
        break
      when 68
        # Raise platform to next highest floor and change texture.
        if sa.do_platform(line, PlatformType::RaiseToNearestAndChange, 0)
          specials.change_switch_texture(line, true)
        end
        break
      when 69
        # Raise floor to next highest floor.
        if sa.do_floor(line, FloorMoveType::RaiseFloorToNearest)
          specials.change_switch_texture(line, true)
        end
        break
      when 70
        # Turbo lower floor.
        if sa.do_floor(line, FloorMoveType::TurboLower)
          specials.change_switch_texture(line, true)
        end
        break
      when 114
        # Blazing door raise (faster than turbo).
        if sa.do_door(line, VerticalDoorType::BlazeRaise)
          specials.change_switch_texture(line, true)
        end
        break
      when 115
        # Blazing door open (faster than turbo).
        if sa.do_door(line, VerticalDoorType::BlazeOpen)
          specials.change_switch_texture(line, true)
        end
        break
      when 116
        # Blazing door close (faster than turbo).
        if sa.do_door(line, VerticalDoorType::BlazeClose)
          specials.change_switch_texture(line, true)
        end
        break
      when 123
        # Blazing platform down, wait, up and stay.
        if sa.do_platform(line, PlatformType::BlazeDwus, 0)
          specials.change_switch_texture(line, true)
        end
        break
      when 132
        # Raise floor turbo.
        if sa.do_floor(line, FloorMoveType::RaiseFloorTurbo)
          specials.change_switch_texture(line, true)
        end
        break
      when 99, 134, 136 # Blazing open door (blue), Blazing open door (red), Blazing open door (yellow).
        if sa.do_locked_door(line, VerticalDoorType::BlazeOpen, thing)
          specials.change_switch_texture(line, true)
        end
        break
      when 138
        # Light turn on.
        sa.light_turn_on(line, 255)
        specials.change_switch_texture(line, true)
        break
      when 139
        # Light turn Off.
        sa.light_turn_on(line, 35)
        specials.change_switch_texture(line, true)
        break
      end

      return true
    end

    #
    # Line crossing.
    #

    # Called every time a thing origin is about to cross a line
    # with a non zero special.
    def cross_special_line(line : LineDef, side : Int32, thing : Mobj)
      # Triggers that other things can activate.
      if thing.player == nil
        # Things that should NOT trigger specials...
        case thing.type
        when MobjType::Rocket, MobjType::Plasma, MobjType::Bfg, MobjType::Troopshot, MobjType::Headshot, MobjType::Bruisershot
          return
        else
          break
        end

        ok = false
        case line.special.to_i32
        # TELEPORT TRIGGER, TELEPORT RETRIGGER, TELEPORT MONSTERONLY TRIGGER.
        # TELEPORT MONSTERONLY RETRIGGER, RAISE DOOR.
        # PLAT DOWN-WAIT-UP-STAY TRIGGER, PLAT DOWN-WAIT-UP-STAY RETRIGGER
        when 39, 97, 125, 126, 4, 10, 88
          ok = true
          break
        end

        return if !ok
      end

      sa = @world.sector_action

      # Note: could use some const's here.
      case line.special.to_i32
      # TRIGGERS.
      # All from here to RETRIGGERS.
      when 2
        # Open door.
        sa.do_door(line, VerticalDoorType::Open)
        line.special = 0
        break
      when 3
        # Close door.
        sa.do_door(line, VerticalDoorType::Close)
        line.special = 0
        break
      when 4
        # Raise door.
        sa.do_door(line, VerticalDoorType::Normal)
        line.special = 0
        break
      when 5
        # Raise floor.
        sa.do_floor(line, FloorMoveType::RaiseFloor)
        line.special = 0
        break
      when 6
        # Fast ceiling crush and raise.
        sa.do_ceiling(line, CeilingMoveType::FastCrushAndRaise)
        line.special = 0
        break
      when 8
        # Build stairs.
        sa.build_stairs(line, StairType::Build8)
        line.special = 0
        break
      when 10
        # Platform down, wait, up and stay.
        sa.do_platform(line, PlatformType::DownWaitUpStay, 0)
        line.special = 0
        break
      when 12
        # Light turn on - brightest near.
        sa.light_turn_on(line, 0)
        line.special = 0
        break
      when 13
        # Light turn on 255.
        sa.light_turn_on(line, 255)
        line.special = 0
        break
      when 16
        # Close door 30.
        sa.do_door(line, VerticalDoorType::Close30ThenOpen)
        line.special = 0
        break
      when 17
        # Start light strobing.
        sa.start_light_strobing(line)
        line.special = 0
        break
      when 19
        # Lower floor.
        sa.do_floor(line, FloorMoveType::LowerFloor)
        line.special = 0
        break
      when 22
        # Raise floor to nearest height and change texture.
        sa.do_platform(line, PlatformType::RaiseToNearestAndChange, 0)
        line.special = 0
        break
      when 25
        # Ceiling crush and raise.
        sa.do_ceiling(line, CeilingMoveType::CrushAndRaise)
        line.special = 0
        break
      when 30
        # Raise floor to shortest texture height on either side of lines.
        sa.do_floor(line, FloorMoveType::RaiseToTexture)
        line.special = 0
        break
      when 35
        # Lights very dark.
        sa.light_turn_on(line, 35)
        line.special = 0
        break
      when 36
        # Lower floor (turbo).
        sa.do_floor(line, FloorMoveType::TurboLower)
        line.special = 0
        break
      when 37
        # Lower and change.
        sa.do_floor(line, FloorMoveType::LowerAndChange)
        line.special = 0
        break
      when 38
        # Lower floor to lowest.
        sa.do_floor(line, FloorMoveType::LowerFloorToLowest)
        line.special = 0
        break
      when 39
        # Do teleport.
        sa.teleport(line, side, thing)
        line.special = 0
        break
      when 40
        # Raise ceiling and lower floor.
        sa.do_ceiling(line, CeilingMoveType::RaiseToHighest)
        sa.do_floor(line, FloorMoveType::LowerFloorToLowest)
        line.special = 0
        break
      when 44
        # Ceiling crush.
        sa.do_ceiling(line, CeilingMoveType::LowerAndCrush)
        line.special = 0
        break
      when 52
        # Do exit.
        @world.exit_level
        break
      when 53
        # Perpetual platform raise.
        sa.do_platform(line, PlatformType::PerpetualRaise, 0)
        line.special = 0
        break
      when 54
        # Platform stop.
        sa.stop_platform(line)
        line.special = 0
        break
      when 56
        # Raise floor crush.
        sa.do_floor(line, FloorMoveType::RaiseFloorCrush)
        line.special = 0
        break
      when 57
        # Ceiling crush stop.
        sa.ceiling_crush_stop(line)
        line.special = 0
        break
      when 58
        # Raise floor 24.
        sa.do_floor(line, FloorMoveType::RaiseFloor24)
        line.special = 0
        break
      when 59
        # Raise floor 24 and change.
        sa.do_floor(line, FloorMoveType::RaiseFloor24AndChange)
        line.special = 0
        break
      when 104
        # Turn lights off in sector (tag).
        sa.turn_tag_lights_off(line)
        line.special = 0
        break
      when 108
        # Blazing door raise (faster than turbo).
        sa.do_door(line, VerticalDoorType::BlazeRaise)
        line.special = 0
        break
      when 109
        # Blazing door open (faster than turbo).
        sa.do_door(line, VerticalDoorType::BlazeOpen)
        line.special = 0
        break
      when 100
        # Build stairs turbo 16.
        sa.build_stairs(line, StairType::Turbo16)
        line.special = 0
        break
      when 110
        # Blazing door close (faster than turbo).
        sa.do_door(line, VerticalDoorType::BlazeClose)
        line.special = 0
        break
      when 119
        # Raise floor to nearest surrounding floor.
        sa.do_floor(line, FloorMoveType::RaiseFloorToNearest)
        line.special = 0
        break
      when 121
        # Blazing platform down, wait, up and stay.
        sa.do_platform(line, PlatformType::BlazeDwus, 0)
        line.special = 0
        break
      when 124
        # Secret exit.
        @world.secret_exit_level
        break
      when 125
        # Teleport monster only.
        if (thing.Player == null)
          sa.teleport(line, side, thing)
          line.special = 0
        end
        break
      when 130
        # Raise floor turbo.
        sa.do_floor(line, FloorMoveType::RaiseFloorTurbo)
        line.special = 0
        break
      when 141
        # Silent ceiling crush and raise.
        sa.do_ceiling(line, CeilingMoveType::SilentCrushAndRaise)
        line.special = 0
        break

        # RETRIGGERS. All from here till end.
      when 72
        # Ceiling crush.
        sa.do_ceiling(line, CeilingMoveType::LowerAndCrush)
        break
      when 73
        # Ceiling crush and raise.
        sa.do_ceiling(line, CeilingMoveType::CrushAndRaise)
        break
      when 74
        # Ceiling crush stop.
        sa.ceiling_crush_stop(line)
        break
      when 75
        # Close door.
        sa.do_door(line, VerticalDoorType::Close)
        break
      when 76
        # Close door 30.
        sa.do_door(line, VerticalDoorType::Close30ThenOpen)
        break
      when 77
        # Fast ceiling crush and raise.
        sa.do_ceiling(line, CeilingMoveType::FastCrushAndRaise)
        break
      when 79
        # Lights very dark.
        sa.light_turn_on(line, 35)
        break
      when 80
        # Light turn on - brightest near.
        sa.light_turn_on(line, 0)
        break
      when 81
        # Light turn on 255.
        sa.light_turn_on(line, 255)
        break
      when 82
        # Lower floor to lowest.
        sa.do_floor(line, FloorMoveType::LowerFloorToLowest)
        break
      when 83
        # Lower floor.
        sa.do_floor(line, FloorMoveType::LowerFloor)
        break
      when 84
        # Lower and change.
        sa.do_floor(line, FloorMoveType::LowerAndChange)
        break
      when 86
        # Open door.
        sa.do_door(line, VerticalDoorType::Open)
        break
      when 87
        # Perpetual platform raise.
        sa.do_platform(line, PlatformType::PerpetualRaise, 0)
        break
      when 88
        # Platform down, wait, up and stay.
        sa.do_platform(line, PlatformType::DownWaitUpStay, 0)
        break
      when 89
        # Platform stop.
        sa.stop_platform(line)
        break
      when 90
        # Raise door.
        sa.do_door(line, VerticalDoorType::Normal)
        break
      when 91
        # Raise floor.
        sa.do_floor(line, FloorMoveType::RaiseFloor)
        break
      when 92
        # Raise floor 24.
        sa.do_floor(line, FloorMoveType::RaiseFloor24)
        break
      when 93
        # Raise floor 24 and change.
        sa.do_floor(line, FloorMoveType::RaiseFloor24AndChange)
        break
      when 94
        # Raise Floor Crush
        sa.do_floor(line, FloorMoveType::RaiseFloorCrush)
        break
      when 95
        # Raise floor to nearest height and change texture.
        sa.do_platform(line, PlatformType::RaiseToNearestAndChange, 0)
        break
      when 96
        # Raise floor to shortest texture height on either side of lines.
        sa.do_floor(line, FloorMoveType::RaiseToTexture)
        break
      when 97
        # Do Teleport.
        sa.teleport(line, side, thing)
        break
      when 98
        # Lower floor (turbo).
        sa.do_floor(line, FloorMoveType::TurboLower)
        break
      when 105
        # Blazing door raise (faster than turbo).
        sa.do_door(line, VerticalDoorType::BlazeRaise)
        break
      when 106
        # Blazing door open (faster than turbo).
        sa.do_door(line, VerticalDoorType::BlazeOpen)
        break
      when 107
        # Blazing door close (faster than turbo).
        sa.do_door(line, VerticalDoorType::BlazeClose)
        break
      when 120
        # Blazing platform down, wait, up and stay.
        sa.do_platform(line, PlatformType::BlazeDwus, 0)
        break
      when 126
        # Teleport monster only.
        if (thing.Player == null)
          sa.teleport(line, side, thing)
        end
        break
      when 128
        # Raise to nearest floor.
        sa.do_floor(line, FloorMoveType::RaiseFloorToNearest)
        break
      when 129
        # Raise floor turbo.
        sa.do_floor(line, FloorMoveType::RaiseFloorTurbo)
        break
      end
    end

    #
    # Line shoot
    #

    # Called when a thing shoots a special line.
    def shoot_special_line(thing : Mobj, line : LineDef)
      ok : Bool = false

      # Impacts that other things can activate.
      if thing.player == nil
        ok = false
        case line.special.to_i32
        when 46
          # Open door impact.
          ok = true
          break
        end
        return if !ok
      end

      sa = @world.sector_action
      specials = @world.specials

      case line.special.to_i32
      when 24
        # Raise floor.
        sa.do_floor(line, FloorMoveType::RaiseFloor)
        specials.change_switch_texture(line, false)
        break
      when 46
        # Open door.
        sa.do_door(line, VerticalDoorType::Open)
        specials.change_switch_texture(line, true)
        break
      when 47
        # Raise floor near and change.
        sa.do_platform(line, PlatformType::RaiseToNearestAndChange, 0)
        specials.change_switch_texture(line, false)
        break
      end
    end
  end
end
