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
  class FloorMove < Thinker
    @world : World | Nil = nil

    property type : FloorMoveType = FloorMoveType.new(0)
    property crush : Bool = false
    property sector : Sector | Nil = nil
    property direction : Int32 = 0
    property new_special : SectorSpecial = SectorSpecial.new(0)
    property texture : Int32 = 0
    property floor_dest_height : Fixed = Fixed.zero
    property speed : Fixed = Fixed.zero

    def initialize(@world)
    end

    def run
      result : SectorActionResult

      sa = @world.as(World).sector_action.as(SectorAction)

      result = sa.move_plane(
        @sector.as(Sector),
        @speed,
        @floor_dest_height,
        @crush,
        0,
        @direction
      )

      if ((@world.as(World).level_time + @sector.as(Sector).number) & 7) == 0
        @world.as(World).start_sound(@sector.as(Sector).sound_origin.as(Mobj), Sfx::STNMOV, SfxType::Misc)
      end

      if result == SectorActionResult::PastDestination
        @sector.as(Sector).special_data = nil

        if @direction == 1
          case type
          when FloorMoveType::DonutRaise
            @sector.as(Sector).special = @new_special
            @sector.as(Sector).floor_flat = @texture
          end
        elsif @direction == -1
          case type
          when FloorMoveType::LowerAndChange
            @sector.as(Sector).special = @new_special
            @sector.as(Sector).floor_flat = @texture
          end
        end

        @world.as(World).thinkers.as(Thinkers).remove(self)
        @sector.as(Sector).disable_frame_interpolation_for_one_frame

        @world.as(World).start_sound(@sector.as(Sector).sound_origin.as(Mobj), Sfx::PSTOP, SfxType::Misc)
      end
    end
  end
end
