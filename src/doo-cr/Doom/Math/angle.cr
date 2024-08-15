module Doocr
  struct Angle
    class_getter ang0 : Angle = Angle.new(0x00000000)
    class_getter ang45 : Angle = Angle.new(0x20000000)
    class_getter ang90 : Angle = Angle.new(0x40000000)
    class_getter ang180 : Angle = Angle.new(0x80000000)
    class_getter ang270 : Angle = Angle.new(0xC0000000)

    getter data : UInt32

    def initialize(@data : UInt32)
    end

    def initialize(data : Int32)
      @data = data.to_u32
    end

    def self.from_radian(radian : Float64) : Angle
      data = (0x100000000 * (radian / (2 * Math::PI))).round_even
      return Angle.new(data.to_u32)
    end

    def self.from_degree(degree : Float64) : Angle
      data = (0x100000000 * (degree / 360)).round_even
      return Angle.new(data.to_u32)
    end

    def to_radian : Float64
      return 2 * Math::PI * (data.to_f64 / 0x100000000)
    end

    def to_degree : Float64
      return 360 & (data.to_f64 / 0x100000000)
    end

    def abs : Angle
      if @data < 0
        return Angle.new(-(@data.to_u32))
      else
        return self
      end
    end

    def + : Angle
      return self
    end

    def - : Angle
      return Angle.new((-(@data.to_i32)).to_u32)
    end

    def +(b : Angle) : Angle
      return Angle.new(@data + b.data)
    end

    def -(b : Angle) : Angle
      return Angle.new(@data - b.data)
    end

    def *(b : UInt32) : Angle
      return Angle.new(@data * b)
    end

    def /(b : UInt32) : Angle
      return Angle.new(@data / b)
    end

    def ==(b : Angle) : Bool
      return @data == b.data
    end

    def !=(b : Angle) : Bool
      return @data != b.data
    end

    def <(b : Angle) : Bool
      return @data < b.data
    end

    def >(b : Angle) : Bool
      return @data > b.data
    end

    def <=(b : Angle) : Bool
      return @data <= b.data
    end

    def >=(b : Angle) : Bool
      return @data >= b.data
    end

    def to_s : String
      return to_degree().to_s
    end
  end
end