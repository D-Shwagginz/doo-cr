module Doocr
  class PlayerScores
    # Whether the player is in game.
    property in_game : Bool

    # Player stats, kills, collected items etc.
    property kill_count : Int32
    property item_count : Int32
    property secret_count : Int32
    property time : Int32
    getter frags : Array(Int32)

    def initialize
      @in_game = false

      @kill_count = 0
      @item_count = 0
      @secret_count = 0
      @time = 0
      @frags = Array.new
    end
  end
end
