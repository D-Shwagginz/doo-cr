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
  class VerticalDoor < Thinker
    @world : World | Nil = nil

    property type : VerticalDoorType | Nil = nil
    property sector : Sector | Nil = nil
    property top_height : Fixed = Fixed.zero
    property speed : Fixed = Fixed.zero

    # 1 = up, 0 = waiting at top, -1 = down.
    property direction : Int32 = 0

    # Tics to wait at the top.
    property top_wait : Int32 = 0

    # When it reaches 0, start going down
    # (keep in case a door going down is reset).
    property top_count_down : Int32 = 0

    def initialize(@world)
    end

    def run
      sa = @world.as(World).sector_action.as(SectorAction)

      result : SectorActionResult

      case @direction
      when 0
        # Waiting.
        @top_count_down -= 1
        if @top_count_down == 0
          case type
          when VerticalDoorType::BlazeRaise
            # Time to go back down.
            @direction = -1
            @world.as(World).start_sound(@sector.as(Sector).sound_origin.as(Mobj), Sfx::BDCLS, SfxType::Misc)
          when VerticalDoorType::Normal
            # Time to go back down.
            @direction = -1
            @world.as(World).start_sound(@sector.as(Sector).sound_origin.as(Mobj), Sfx::DORCLS, SfxType::Misc)
          when VerticalDoorType::Close30ThenOpen
            @direction = 1
            @world.as(World).start_sound(@sector.as(Sector).sound_origin.as(Mobj), Sfx::DOROPN, SfxType::Misc)
          else
          end
        end
      when 2
        # Initial wait.
        @top_count_down -= 1
        if @top_count_down == 0
          case type
          when VerticalDoorType::RaiseIn5Mins
            @direction = 1
            @type = VerticalDoorType::Normal
            @world.as(World).start_sound(@sector.as(Sector).sound_origin.as(Mobj), Sfx::DOROPN, SfxType::Misc)
          else
          end
        end
      when -1
        # Down.
        result = sa.as(SectorAction).move_plane(
          @sector.as(Sector).as(Sector),
          @speed,
          @sector.as(Sector).floor_height,
          false, 1, @direction
        )
        if result == SectorActionResult::PastDestination
          case type
          when VerticalDoorType::BlazeRaise, VerticalDoorType::BlazeClose
            @sector.as(Sector).special_data = nil
            # Unlink and free.
            @world.as(World).thinkers.as(Thinkers).remove(self)
            @sector.as(Sector).disable_frame_interpolation_for_one_frame
            @world.as(World).start_sound(@sector.as(Sector).sound_origin.as(Mobj), Sfx::BDCLS, SfxType::Misc)
          when VerticalDoorType::Normal, VerticalDoorType::Close
            @sector.as(Sector).special_data = nil
            # Unlink and free.
            @world.as(World).thinkers.as(Thinkers).remove(self)
            @sector.as(Sector).disable_frame_interpolation_for_one_frame
          when VerticalDoorType::Close30ThenOpen
            @direction = 0
            @top_count_down = 35 * 30
          else
          end
        elsif result == SectorActionResult::Crushed
          case type
          when VerticalDoorType::BlazeClose, VerticalDoorType::Close # Do not go back up!

          else
            @direction = 1
            @world.as(World).start_sound(@sector.as(Sector).sound_origin.as(Mobj), Sfx::DOROPN, SfxType::Misc)
          end
        end
      when 1
        # Up
        result = sa.move_plane(
          @sector.as(Sector).as(Sector),
          @speed,
          @top_height,
          false, 1, @direction
        )

        if result == SectorActionResult::PastDestination
          case type
          when VerticalDoorType::BlazeRaise, VerticalDoorType::Normal
            # Wait at top.
            @direction = 0
            @top_count_down = @top_wait
          when VerticalDoorType::Close30ThenOpen, VerticalDoorType::BlazeOpen, VerticalDoorType::Open
            @sector.as(Sector).special_data = nil
            # Unlink and free.
            @world.as(World).thinkers.as(Thinkers).remove(self)
            @sector.as(Sector).disable_frame_interpolation_for_one_frame
          else
          end
        end
      end
    end
  end
end
