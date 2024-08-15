module Doocr
  class Player
    MAX_PLAYER_COUNT = 4

    class_getter normal_view_height : Fixed = Fixed.from_int(41)

    @@default_player_names : Array(String) = [
      "Green",
      "Indigo",
      "Brown",
      "Red",
    ]

    @number : Int32
    @name : String
    @in_game : Bool

    @mobj : Mobj
    @player_state : PlayerState
    @cmd : TicCmd
  end
end
