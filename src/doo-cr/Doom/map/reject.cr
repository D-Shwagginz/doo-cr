#
# Copyright (C) 1993-1996 Id Software, Inc.
# Copyright (C) 2019-2020 Nobuaki Tanaka
# Copyright (C) 2024 Devin Shwagginz
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#

module Doocr
  class Reject
    @data : Bytes

    @sector_count : Int32

    private def initialize(data : Bytes, sector_count : Int32)
      # If the reject table is too small, expand it to avoid crash.
      # https://doomwiki.org/wiki/Reject#Reject_Overflow
      expected_length = (sector_count * sector_count + 7) / 8
      if data.size < expected_length
        data += Bytes.new(expected_length - data.size)
      end

      @data = data
      @sector_count = sector_count
    end

    def self.from_wad(wad : Wad, lump : Int32, sectors : Array(Sector)) : Reject
      return Reject.new(wad.read_lump(lump), sectors.size)
    end

    def check(sector1 : Sector, sector2 : Sector2) : Bool
      s1 = sector1.number
      s2 = sector2.number

      p = s1 * sector_count + s2
      byte_index = p >> 3
      bit_index = 1 << (p & 7)

      return (@data[byte_index] & bit_index) != 0
    end
  end
end
