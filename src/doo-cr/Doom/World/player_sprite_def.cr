module Doocr
  class PlayerSpriteDef
    property state : MobjStateDef | Nil
    property tics : Int32 = 0
    property sx : Fixed | Nil
    property sy : Fixed | Nil

    def clear
      @state = nil
      @tics = 0
      @sx = Fixed.zero
      @sy = Fixed.zero
    end
  end
end
