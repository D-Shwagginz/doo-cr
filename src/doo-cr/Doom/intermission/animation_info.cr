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
  class AnimationInfo
    getter type : AnimationType = AnimationType.new(0)
    getter period : Int32 = 0
    getter count : Int32 = 0
    getter x : Int32 = 0
    getter y : Int32 = 0
    getter data : Int32 = 0

    def initialize(
      @type,
      @period,
      @count,
      @x,
      @y
    )
    end

    def initialize(
      @type,
      @period,
      @count,
      @x,
      @y,
      @data
    )
    end

    class_getter episodes : Array(Array(AnimationInfo)) = [
      [
        AnimationInfo.new(AnimationType::Always, (GameConst.tic_rate / 3).to_i32, 3, 224, 104),
        AnimationInfo.new(AnimationType::Always, (GameConst.tic_rate / 3).to_i32, 3, 184, 160),
        AnimationInfo.new(AnimationType::Always, (GameConst.tic_rate / 3).to_i32, 3, 112, 136),
        AnimationInfo.new(AnimationType::Always, (GameConst.tic_rate / 3).to_i32, 3, 72, 112),
        AnimationInfo.new(AnimationType::Always, (GameConst.tic_rate / 3).to_i32, 3, 88, 96),
        AnimationInfo.new(AnimationType::Always, (GameConst.tic_rate / 3).to_i32, 3, 64, 48),
        AnimationInfo.new(AnimationType::Always, (GameConst.tic_rate / 3).to_i32, 3, 192, 40),
        AnimationInfo.new(AnimationType::Always, (GameConst.tic_rate / 3).to_i32, 3, 136, 16),
        AnimationInfo.new(AnimationType::Always, (GameConst.tic_rate / 3).to_i32, 3, 80, 16),
        AnimationInfo.new(AnimationType::Always, (GameConst.tic_rate / 3).to_i32, 3, 64, 24),
      ],

      [
        AnimationInfo.new(AnimationType::Level, (GameConst.tic_rate / 3).to_i32, 1, 128, 136, 1),
        AnimationInfo.new(AnimationType::Level, (GameConst.tic_rate / 3).to_i32, 1, 128, 136, 2),
        AnimationInfo.new(AnimationType::Level, (GameConst.tic_rate / 3).to_i32, 1, 128, 136, 3),
        AnimationInfo.new(AnimationType::Level, (GameConst.tic_rate / 3).to_i32, 1, 128, 136, 4),
        AnimationInfo.new(AnimationType::Level, (GameConst.tic_rate / 3).to_i32, 1, 128, 136, 5),
        AnimationInfo.new(AnimationType::Level, (GameConst.tic_rate / 3).to_i32, 1, 128, 136, 6),
        AnimationInfo.new(AnimationType::Level, (GameConst.tic_rate / 3).to_i32, 1, 128, 136, 7),
        AnimationInfo.new(AnimationType::Level, (GameConst.tic_rate / 3).to_i32, 3, 192, 144, 8),
        AnimationInfo.new(AnimationType::Level, (GameConst.tic_rate / 3).to_i32, 1, 128, 136, 8),
      ],

      [
        AnimationInfo.new(AnimationType::Always, (GameConst.tic_rate / 3).to_i32, 3, 104, 168),
        AnimationInfo.new(AnimationType::Always, (GameConst.tic_rate / 3).to_i32, 3, 40, 136),
        AnimationInfo.new(AnimationType::Always, (GameConst.tic_rate / 3).to_i32, 3, 160, 96),
        AnimationInfo.new(AnimationType::Always, (GameConst.tic_rate / 3).to_i32, 3, 104, 80),
        AnimationInfo.new(AnimationType::Always, (GameConst.tic_rate / 3).to_i32, 3, 120, 32),
        AnimationInfo.new(AnimationType::Always, (GameConst.tic_rate / 4).to_i32, 3, 40, 0),
      ],
    ]
  end
end
