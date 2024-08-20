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
  module Trig
    FINE_ANGLE_COUNT    = 8192
    FINE_MASK           = FINE_ANGLE_COUNT - 1
    ANGLE_TO_FINE_SHIFT = 19

    FINE_COSINE_OFFSET = FINE_ANGLE_COUNT / 4

    def self.tan(angle_plus_90 : Angle) : Fixed
      return Fixed.new(@@fine_tangent[angle_plus_90.data >> ANGLE_TO_FINE_SHIFT])
    end

    def self.tan(fine_angle_plus_90 : Int32) : Fixed
      return Fixed.new(@@fine_tangent[fine_angle_plus_90])
    end

    def self.sin(angle : Angle) : Fixed
      return Fixed.new(@@fine_sine[angle.data >> ANGLE_TO_FINE_SHIFT])
    end

    def self.sin(fine_angle : Int32) : Fixed
      return Fixed.new(@@fine_sine[fine_angle])
    end

    def self.cos(angle : Angle) : Fixed
      return Fixed.new(@@fine_sine[(angle.data >> ANGLE_TO_FINE_SHIFT_) + FINE_COSINE_OFFSET])
    end

    def self.cos(fine_angle : Int32) : Fixed
      return Fixed.new(@@fine_sine[fine_angle + FINE_COSINE_OFFSET])
    end

    def self.tan_to_angle(tan : UInt32) : Angle
      return Angle.new(@@tan_to_angle[tan])
    end
  end
end
