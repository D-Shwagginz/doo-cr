module Doocr
  class DivLine
    property x : Fixed = Fixed.zero
    property y : Fixed = Fixed.zero
    property dx : Fixed = Fixed.zero
    property dy : Fixed = Fixed.zero

    def make_from(line : LineDef)
      @x = line.vertex1.x
      @y = line.vertex1.y
      @dx = line.dx
      @dy = line.dy
    end
  end
end
