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
  class Subsector
    class_getter datasize : Int32 = 4

    getter sector : Sector
    getter seg_count : Int32
    getter first_seg : Int32

    def initialize(@sector : Sector, @seg_count : Int32, @first_seg : Int32)
    end

    def self.from_data(data : Bytes, offset : Int32, segs : Array(Seg)) : Subsector
      seg_count = IO::ByteFormat::LittleEndian.decode(Int16, data[offset, 2])
      first_seg_number = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 2, 2])

      return Subsector.new(
        segs[first_seg_number].side_def.sector.as(Sector),
        seg_count,
        first_seg_number
      )
    end

    def self.from_wad(wad : Wad, lump : Int32, segs : Array(Seg)) : Array(Subsector)
      length = wad.get_lump_size(lump)
      raise "" if length % @@datasize != 0

      data = wad.read_lump(lump)
      count = (length / @@datasize).to_i32
      subsectors = Array(Subsector).new(count)

      count.times do |i|
        offset = @@datasize * i
        subsectors << from_data(data, offset, segs)
      end

      return subsectors
    end
  end
end
