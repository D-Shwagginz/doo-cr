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
      sa = @world.as(World).sector_action

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
            @world.as(World).start_sound(@sector.sound_origin, Sfx::BDCLS, SfxType::Misc)
            break
          when VerticalDoorType::Normal
            # Time to go back down.
            @direction = -1
            @world.as(World).start_sound(@sector.sound_origin, Sfx::DORCLS, SfxType::Misc)
            break
          when VerticalDoorType::Close30ThenOpen
            @direction = 1
            @world.as(World).start_sound(@sector.sound_origin, Sfx::DOROPN, SfxType::Misc)
            break
          else
            break
          end
        end
        break
      when 2
        # Initial wait.
        @top_count_down -= 1
        if @top_count_down == 0
          case type
          when VerticalDoorType::RaiseIn5Mins
            @direction = 1
            @type = VerticalDoorType::Normal
            @world.as(World).start_sound(@sector.sound_origin, Sfx::DOROPN, SfxType::Misc)
            break
          else
            break
          end
        end
        break
      when -1
        # Down.
        result = sa.move_plane(
          @sector,
          @speed,
          @sector.floor_height,
          false, 1, @direction
        )
        if result == SectorActionResult::PastDestination
          case type
          when VerticalDoorType::BlazeRaise, VerticalDoorType::BlazeClose
            @sector.special_data = nil
            # Unlink and free.
            @world.as(World).thinkers.remove(self)
            @sector.disable_frame_interpolation_for_one_frame
            @world.as(World).start_sound(@sector.sound_origin, Sfx::BDCLS, SfxType::Misc)
            break
          when VerticalDoorType::Normal, VerticalDoorType::Close
            @sector.special_data = nil
            # Unlink and free.
            @world.as(World).thinkers.remove(self)
            @sector.disable_frame_interpolation_for_one_frame
            break
          when VerticalDoorType::Close30ThenOpen
            @direction = 0
            @top_count_down = 35 * 30
            break
          else
            break
          end
        elsif result == SectorActionResult::Crushed
          case type
          when VerticalDoorType::BlazeClose, VerticalDoorType::Close # Do not go back up!
            break
          else
            @direction = 1
            @world.as(World).start_sound(@sector.sound_origin, Sfx::DOROPN, SfxType::Misc)
            break
          end
        end
        break
      when 1
        # Up
        result = sa.move_plane(
          @sector,
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
            break
          when VerticalDoorType::Close30ThenOpen, VerticalDoorType::BlazeOpen, VerticalDoorType::Open
            @sector.special_data = nil
            # Unlink and free.
            @world.as(World).thinkers.remove(self)
            @sector.disable_frame_interpolation_for_one_frame
            break
          else
            break
          end
        end
        break
      end
    end
  end
end
