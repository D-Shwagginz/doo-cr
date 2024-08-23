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
  class Platform < Thinker
    @world : World | Nil = nil

    property sector : Sector | Nil = nil
    property speed : Fixed = Fixed.zero
    property low : Fixed = Fixed.zero
    property high : Fixed = Fixed.zero
    property wait : Int32 = 0
    property count : Int32 = 0
    property status : PlatformState = PlatformState.new(0)
    property old_status : PlatformState = PlatformState.new(0)
    property crush : Bool = false
    property tag : Int32 = 0
    property type : PlatformType | Nil = nil

    def initialize(@world)
    end

    def run
      sa = @world.as(World).sector_action

      result : SectorActionResult

      case @status
      when PlatformState::Up
        result = sa.move_plane(@sector, @speed, @high, @crush, 0, 1)

        if (type == PlatformType::RaiseAndChange ||
           type == PlatformType::RaiseToNearestAndChange)
          if ((@world.as(World).level_time + @sector.number) & 7) == 0
            @world.as(World).start_sound(@sector.sound_origin, Sfx::STNMOV, SfxType::Misc)
          end
        end

        if result == SectorActionResult::Crushed && !@crush
          @count = @wait
          @status = PlatformState::Down
          @world.as(World).start_sound(@sector.sound_origin, Sfx::PSTART, SfxType::Misc)
        else
          if result == SectorActionResult::PastDestination
            @count = @wait
            @status = PlatformState::Waiting
            @world.as(World).start_sound(@sector.sound_origin, Sfx::PSTOP, SfxType::Misc)

            case type
            when PlatformType::BlazeDwus, PlatformType::DownWaitUpStay
              sa.remove_active_platform(self)
              @sector.disable_frame_interpolation_for_one_frame
              break
            when PlatformType::RaiseAndChange, PlatformType::RaiseToNearestAndChange
              sa.remove_active_platform(self)
              @sector.disable_frame_interpolation_for_one_frame
              break
            else
              break
            end
          end
        end

        break
      when PlatformState::Down
        result = sa.move_plane(@sector, @speed, @low, false, 0, -1)

        if result == SectorActionResult::PastDestination
          @count = @wait
          @status = PlatformState::Waiting
          @world.as(World).start_sound(@sector.sound_origin, Sfx::PSTOP, SfxType::Misc)
        end

        break
      when PlatformState::Waiting
        @count -= 1
        if @count == 0
          if @sector.floor_height == @low
            @status = PlatformState::Up
          else
            @status = PlatformState::Down
          end
          @world.as(World).start_sound(@sector.sound_origin, Sfx::PSTART, SfxType::Misc)
        end

        break
      when PlatformState::InStasis
        break
      end
    end
  end
end
