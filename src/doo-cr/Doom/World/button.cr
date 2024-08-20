module Doocr
  class Button
    property line : LineDef | Nil
    property position : ButtonPosition = ButtonPosition.new(0)
    property texture : Int32 = 0
    property timer : Int32 = 0
    property sound_origin : Mobj | Nil

    def clear
      @line = nil
      @position = 0
      @texture = 0
      @timer = 0
      @sound_origin = nil
    end
  end
end
