# Copyright (C) 2026 Devin Shwagginz
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# ==> A custom linedef tag

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
    getter number : Int32 = 200 # I believe 141 is the last special line number in Doom. 200 to be safe and round

    def initialize(@db_name, @when, @action)
      @number += Mod.lines.size
    end
  end
end
