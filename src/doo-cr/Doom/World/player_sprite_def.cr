module Doocr
  class PlayerSpriteDef
    property state : MobjStateDef | Nil
    property tics : Int32
    property sx : Fixed
    property sy : Fixed

    def clear
      @state = nil
      @tics = 0
      @sx = Fixed.zero
      @sy = Fixed.zero
    end
  end
end
