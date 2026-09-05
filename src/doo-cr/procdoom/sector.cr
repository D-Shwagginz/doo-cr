module Doocr::Mod
  class Sector
    getter db_name : String
    getter action : Proc(CDoom::Sector*, CDoom::Player*, Nil)
    property number : Int32 = 20 # I believe 17 is the last special sector number in Doom. 20 to be safe and round

    def initialize(@db_name, @action)
      @number += Mod.sectors.size
    end
  end
end
