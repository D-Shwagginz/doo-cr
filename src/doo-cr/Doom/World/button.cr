module Doocr
  class Button
    property line : LineDef | Nil
    property position : ButtonPosition
    property texture : Int32
    property timer : Int32
    property sound_origin : Mobj | Nil

    def clear
      @line = nil
      @position = 0
      @texture = 0
      @timer = 0
      @soun_origin = nil
    end
  end
end
