module Doocr::Mod
  class Line
    enum When
      Crossed
      Used
      Shot
    end

    getter db_name : String
    getter when : When
    getter action : Proc(CDoom::Line*, Int32, CDoom::Mobj*, Nil)
    property number : Int32 = 200 # I believe 141 is the last special line number in Doom. 200 to be safe and round

    def initialize(@db_name, @when, @action)
      @number += Mod.lines.size
    end
  end
end
