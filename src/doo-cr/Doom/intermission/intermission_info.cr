module Doocr
  class IntermissionInfo
    # Episode number (0-2).
    property episode : Int32

    # If true, splash the secret level.
    property did_secret : Bool

    # Previous and next levels, origin 0.
    property last_level : Int32
    property next_level : Int32

    setter max_kill_count : Int32

    def max_kill_count
      return @max_kill_count > 1 ? @max_kill_count : 1
    end

    setter max_item_count : Int32

    def max_item_count
      return @max_item_count > 1 ? @max_item_count : 1
    end

    setter max_secret_count : Int32

    def max_secret_count
      return @max_secret_count > 1 ? @max_secret_count : 1
    end

    setter total_frags : Int32

    def total_frags
      return @total_frags > 1 ? @total_frags : 1
    end

    # The par time.

    property par_time : Int32

    getter players : Array(PlayerScores)

    def initialize
      @players = Array(PlayerScores).new(Player::MAX_PLAYER_COUNT)
      Player::MAX_PLAYER_COUNT.times do |i|
        players << PlayerScores.new
      end
    end
  end
end
