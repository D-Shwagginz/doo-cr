module Doocr
  class Player
    MAX_PLAYER_COUNT = 4

    class_getter normal_view_height : Fixed = Fixed.from_i(41)

    @@default_player_names : Array(String) = [
      "Green",
      "Indigo",
      "Brown",
      "Red",
    ]

    @number : Int32 = 0
    @name : String | Nil
    @in_game : Bool = false

    @mobj : Mobj | Nil
    # @player_state : PlayerState
    @cmd : TicCmd | Nil
  end
end
