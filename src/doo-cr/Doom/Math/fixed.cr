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
  struct Fixed
    FRACBITS  = 16
    FRAC_UNIT = 1 << FRACBITS

    class_getter zero : Fixed = Fixed.new(0)
    class_getter one : Fixed = Fixed.new(FRAC_UNIT)

    class_getter max_value : Fixed = Fixed.new(Int32::MAX)
    class_getter min_value : Fixed = Fixed.new(Int32::MIN)

    class_getter epsilon : Fixed = Fixed.new(1)
    class_getter one_plus_epsilon = Fixed.new(FRAC_UNIT + 1)
    class_getter one_minus_epsilon = Fixed.new(FRAC_UNIT - 1)

    getter data : Int32

    def initialize(@data : Int32)
    end

    def self.from_i(value : Int32) : Fixed
      return Fixed.new(value << FRACBITS)
    end

    def self.from_f32(value : Float32) : Fixed
      return Fixed.new((FRAC_UNIT * value).to_i32)
    end

    def self.from_f64(value : Float64) : Fixed
      return Fixed.new((FRAC_UNIT * value).to_i32)
    end

    def to_f32 : Float32
      return data.to_f32 / FRAC_UNIT
    end

    def to_f64 : Float64
      return data.to_f64 / FRAC_UNIT
    end

    def abs : Fixed
      if @data < 0
        return Fixed.new(-@data)
      else
        return self
      end
    end

    def + : Fixed
      return self
    end

    def - : Fixed
      return Fixed.new(-@data)
    end

    def +(b : Fixed) : Fixed
      return Fixed.new(@data + b.data)
    end

    def -(b : Fixed) : Fixed
      return Fixed.new(@data - b.data)
    end

    def *(b : Fixed) : Fixed
      return Fixed.new(((@data.to_i64 * b.data.to_i64) >> FRACBITS).to_i32)
    end

    def *(b : Int32) : Fixed
      return Fixed.new(@data * b)
    end

    def /(b : Fixed) : Fixed
      if (cintabs(@data) >> 14) >= cintabs(b.data)
        return Fixed.new((@data ^ b.data) < 0 ? Int32::MIN : Int32::MAX)
      end

      return fixed_div2(self, b)
    end

    private def cintabs(n : Int32) : Int32
      return n < 0 ? -n : n
    end

    private def fixed_div2(a : Fixed, b : Fixed) : Fixed
      c = (a.data.to_f64 / b.data.to_f64) * FRAC_UNIT

      if c >= 2147483648.0 || c < -2147483648.0
        raise DivisionByZeroError.new
      end

      return Fixed.new(c.to_i32)
    end

    def /(b : Int32) : Fixed
      return Fixed.new((@data / b).to_i32)
    end

    def <<(b : Int32) : Fixed
      return Fixed.new(@data << b)
    end

    def >>(b : Int32) : Fixed
      return Fixed.new(@data >> b)
    end

    def ==(b : Fixed) : Bool
      return @data == b.data
    end

    def !=(b : Fixed) : Bool
      return @data != b.data
    end

    def <(b : Fixed) : Bool
      return @data < b.data
    end

    def >(b : Fixed) : Bool
      return @data > b.data
    end

    def <=(b : Fixed) : Bool
      return @data <= b.data
    end

    def >=(b : Fixed) : Bool
      return @data >= b.data
    end

    def self.min(a : Fixed, b : Fixed) : Fixed
      if a < b
        return a
      else
        return b
      end
    end

    def self.max(a : Fixed, b : Fixed) : Fixed
      if a < b
        return b
      else
        return a
      end
    end

    def to_i_floor : Int32
      return @data >> FRACBITS
    end

    def to_i_ceiling : Int32
      return (@data + FRAC_UNIT - 1) >> FRACBITS
    end

    def to_s : String
      return (data.to_f64 / FRAC_UNIT).to_s
    end
  end
end
