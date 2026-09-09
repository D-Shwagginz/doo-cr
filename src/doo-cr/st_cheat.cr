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
# ==> Cheats

module Doocr
  @@firsttime = 1
  @@cheat_xlate_table = uninitialized StaticArray(UInt8, 256)

  def self.cht_check_cheat(cht : Doocr::Cheatseq, key : UInt8) : LibC::Int
    rc = 0
    if @@firsttime != 0
      @@firsttime = 0
      256.times { |i| @@cheat_xlate_table[i] = (scramble(i)).to_u8 }
    end

    if cht.p.null?
      cht.p = cht.sequence # initialize if first time
    end

    if cht.p.value == 0
      cht.p.value = key
      cht.p = cht.p + 1
    elsif @@cheat_xlate_table[key.to_u8!] == cht.p.value
      cht.p = cht.p + 1
    else
      cht.p = cht.sequence
    end

    if cht.p.value == 1
      cht.p = cht.p + 1
    elsif cht.p.value == 0xff # end of sequence character
      cht.p = cht.sequence
      rc = 1
    end

    return rc
  end

  def self.cht_get_param(cht : Doocr::Cheatseq, buffer : LibC::Char*)
    p = cht.sequence
    while p.value != 1
      p += 1
    end
    p += 1

    c = 0

    loop do
      c = p.value
      buffer.value = c
      buffer += 1
      p.value = 0
      p += 1

      break unless c != 0 && p.value != 0xff
    end

    buffer.value = 0 if p.value == 0xff
  end
end
