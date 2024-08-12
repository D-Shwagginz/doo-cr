module Doocr
  struct Fixed
    FRACBITS = 16
    FRACUNIT = 1 << FRACBITS

    getter zero : Fixed = Fixed.new(0)
    getter one : Fixed = Fixed.new(FRACUNIT)

    getter maxvalue : Fixed = Fixed.new(Int32::MAX)
    getter minvalue : Fixed = Fixed.new(Int32::MIN)

    getter epsilon : Fixed = Fixed.new(1)
    getter one_plus_epsilon = Fixed.new(FRACUNIT + 1)
    getter one_minus_epsilon = Fixed.new(FRACUNIT - 1)

    getter data : Int32

    def initialize(@data : Int32)
    end

    def self.from_i(value : Int32) : Fixed
      return Fixed.new(value << FRACBITS)
    end

    def self.from_f32(value : Float32) : Fixed
      return Fixed.new((FRACUNIT * value).to_i32)
    end

    def self.from_f64(value : Float64) : Fixed
      return Fixed.new((FRACUNIT * value).to_i32)
    end

    def to_f32 : Float32
      return data.to_f32 / FRACUNIT
    end

    def to_f64 : Float64
      return data.to_f64 / FRACUNIT
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
      return Fixed.new((@data.to_i64 * b.data.to_i64).to_i32)
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
      c = (a.data.to_f64 / b.data.to_f64) * FRACUNIT

      if c >= 2147483648.0 || c < -2147483648.0
        raise DivisionByZeroError
      end

      return Fixed.new(c.to_i32)
    end

    def /(b : Int32) : Fixed
      return Fixed.new(@data / b)
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

    def min(b : Fixed) : Fixed
      if self < b
        return self
      else
        return b
      end
    end

    def max(b : Fixed) : Fixed
      if self < b
        return b
      else
        return self
      end
    end

    def to_i_floor : Int32
      return @data >> FRACBITS
    end

    def to_i_ceiling : Int32
      return (@data + FRACUNIT - 1) >> FRACBITS
    end

    def to_s : String
      return (data.to_f64 / FRACUNIT).to_s
    end
  end
end
