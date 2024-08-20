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
  class Animation
    @im : Intermission
    @number : Int32

    @type : AnimationType
    @period : Int32
    @frame_count : Int32
    getter location_x : Int32
    getter location_y : Int32
    getter data : Int32
    getter patches : Array(String)
    getter patch_number : Int32 = 0
    @next_tic : Int32 = 0

    def initialize(@im : Intermission, info : AnimationInfo, @number : Int32)
      @type = info.type
      @period = info.period
      @frame_count = info.count
      @location_x = info.x
      @location_y = info.y
      @data = info.data

      @patches = Array.new(@frame_count, "")
      @frame_count.times do |i|
        # MONDO HACK!
        if @im.info.episode != 1 || @number != 8
          @patches[i] = "WOA" + @im.info.episode + @number.to_s(precision: 2) + i.to_s(precision: 2)
        else
          # HACK ALERT!
          @patches[i] = "WIA104" + i.to_s(precision: 2)
        end
      end
    end

    def reset(bg_count : Int32)
      @patch_number = -1

      # Specify the next time to draw it.
      case @type
      when AnimationType::Always
        @next_tic = bg_count + 1 + (@im.random.next % @period)
      when AnimationType::Random
        @next_tic = bg_count + 1 + (@im.random.next % @data)
      when AnimationType::Level
        @next_tic = bg_count + 1
      end
    end

    def update(bg_count : Int32)
      if bg_count == @next_tic
        case @type
        when AnimationType::Always
          @patch_number = 0 if @patch_number + 1 > @frame_count
          @next_tic = bg_count + period
          break
        when AnimationType::Random
          @patch_number += 1
          if @patch_number == @frame_count
            @patch_number = -1
            @next_tic = bg_count + (@im.random.next % @data)
          else
            @next_tic = bg_count + period
          end
          break
        when AnimationType::Level
          # Gawd-awful hack for level anims.
          if !(@im.state == IntermissionState::StatCount && @number == 7) && @im.info.next_level == @data
            @patch_number += 1
            @patch_number -= 1 if @patch_number == @frame_count
            @next_tic = bg_count + period
          end
          break
        end
      end
    end
  end
end
