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
  class CeilingMove < Thinker
    @world : World | Nil = nil

    property type : CeilingMoveType = CeilingMoveType.new(0)
    property sector : Sector | Nil = nil
    property bottom_height : Fixed = Fixed.zero
    property top_height : Fixed = Fixed.zero
    property speed : Fixed = Fixed.zero
    property crush : Bool = false

    # 1 = up, 0 = waiting, -1 = down.
    property direction : Int32 = 0

    # Corresponding sector tag.
    property tag : Int32 = 0

    property old_direction : Int32 = 0

    def initialize(@world)
    end

    def run
      result : SectorActionResult

      sa = @world.as(World).sector_action.as(SectorAction)

      case @direction
      when 0
        # In stasis.

      when 1
        # Up.
        result = sa.move_plane(
          @sector.as(Sector),
          @speed,
          @top_height,
          false,
          1,
          @direction
        )

        if ((@world.as(World).level_time + @sector.as(Sector).number) & 7) == 0
          case type
          when CeilingMoveType::SilentCrushAndRaise
          else
            @world.as(World).start_sound(@sector.as(Sector).sound_origin.as(Mobj), Sfx::STNMOV, SfxType::Misc)
          end
        end

        if result == SectorActionResult::PastDestination
          case type
          when CeilingMoveType::RaiseToHighest
            sa.remove_active_ceiling(self)
            @sector.as(Sector).disable_frame_interpolation_for_one_frame
          when CeilingMoveType::SilentCrushAndRaise, CeilingMoveType::FastCrushAndRaise, CeilingMoveType::CrushAndRaise
            if type == CeilingMoveType::SilentCrushAndRaise
              @world.as(World).start_sound(@sector.as(Sector).sound_origin.as(Mobj), Sfx::PSTOP, SfxType::Misc)
            end
            @direction = -1
          else
          end
        end
      when -1
        # Down.
        result = sa.move_plane(
          @sector.as(Sector),
          @speed,
          @bottom_height,
          false,
          1,
          @direction
        )

        if ((@world.as(World).level_time + sector.as(Sector).number) & 7) == 0
          case type
          when CeilingMoveType::SilentCrushAndRaise
          else
            @world.as(World).start_sound(sector.as(Sector).sound_origin.as(Mobj), Sfx::STNMOV, SfxType::Misc)
          end
        end

        if result == SectorActionResult::PastDestination
          case type
          when CeilingMoveType::SilentCrushAndRaise, CeilingMoveType::CrushAndRaise, CeilingMoveType::FastCrushAndRaise
            if type == CeilingMoveType::SilentCrushAndRaise
              @world.as(World).start_sound(sector.as(Sector).sound_origin.as(Mobj), Sfx::PSTOP, SfxType::Misc)
              @speed = SectorAction.ceiling_speed
            end
            if type == CeilingMoveType::CrushAndRaise
              @speed = SectorAction.ceiling_speed
            end
            @direction = 1
          when CeilingMoveType::LowerAndCrush, CeilingMoveType::LowerToFloor
            sa.remove_active_ceiling(self)
            sector.as(Sector).disable_frame_interpolation_for_one_frame
          else
          end
        else
          if result == SectorActionResult::Crushed
            case type
            when CeilingMoveType::SilentCrushAndRaise, CeilingMoveType::CrushAndRaise, CeilingMoveType::LowerAndCrush
              @speed = SectorAction.ceiling_speed / 8
            else
            end
          end
        end
      end
    end
  end
end
