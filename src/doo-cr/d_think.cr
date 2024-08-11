#  MapObj data. Map Objects or mobjs are actors, entities,
#  thinker, take-your-pick... anything that moves, acts, or
#  suffers state changes of more or less violent nature.

module Doocr
  alias ActionfV = Proc(Nil)
  alias ActionfP1 = Proc(Void, Nil)
  alias ActionfP2 = Proc(Void, Void, Nil)

  alias Actionf = ActionfV | ActionfP1 | ActionfP2 | Nil

  alias Think = Actionf

  struct Thinker
    property prev_t: Thinker
    property next_t : Thinker
    property function : Think

    def initialize(@prev_t, @next_t, @function)
    end
  end
end
