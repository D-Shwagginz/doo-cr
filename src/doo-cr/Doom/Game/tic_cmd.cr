module Doocr
  class TicCmd
    property forward_move : Int8 = 0
    property side_move : Int8 = 0
    property angle_turn : Int8 = 0
    property buttons : Int8 = 0

    def clear
      @forward_move = 0
      @side_move = 0
      @angle_turn = 0
      @buttons = 0
    end

    def copy_from(cmd : TicCmd)
      @forward_move = cmd.forward_move
      @side_move = cmd.side_move
      @angle_turn = cmd.angle_turn
      @buttons = cmd.buttons
    end
  end
end
