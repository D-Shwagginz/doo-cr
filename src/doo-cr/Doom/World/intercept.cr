module Doocr
  class Intercept
    property frac : Fixed | Nil
    getter thing : Mobj | Nil
    getter line : LineDef | Nil

    def make(@frac : Fixed, @thing : Mobj)
      line = nil
    end

    def make(@frac : Fixed, @line : LineDef)
      thing = nil
    end
  end
end
