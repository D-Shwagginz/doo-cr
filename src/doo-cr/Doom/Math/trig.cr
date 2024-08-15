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
