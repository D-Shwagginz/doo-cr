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
# ==> A custom sector tag

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
