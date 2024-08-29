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
  class Seg
    class_getter datasize : Int32 = 12

    getter vertex1 : Vertex
    getter vertex2 : Vertex
    getter offset : Fixed
    getter angle : Angle
    getter side_def : SideDef | Nil
    getter line_def : LineDef | Nil
    getter front_sector : Sector | Nil
    getter back_sector : Sector | Nil = nil

    def initialize(
      @vertex1,
      @vertex2,
      @offset,
      @angle,
      @side_def,
      @line_def,
      @front_sector,
      @back_sector
    )
    end

    def self.from_data(data : Bytes, offset : Int32, vertices : Array(Vertex), lines : Array(LineDef)) : Seg
      vertex1_number = IO::ByteFormat::LittleEndian.decode(Int16, data[offset, 2])
      vertex2_number = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 2, 2])
      angle = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 4, 2])
      line_number = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 6, 2])
      side = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 8, 2])
      seg_offset = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 10, 2])

      line_def = lines[line_number]
      front_side = side == 0 ? line_def.front_side : line_def.back_side
      back_side = side == 0 ? line_def.back_side : line_def.front_side

      return Seg.new(
        vertices[vertex1_number],
        vertices[vertex2_number],
        Fixed.from_i(seg_offset),
        Angle.new(angle.to_u32! << 16),
        front_side.as(SideDef),
        line_def,
        front_side.as(SideDef).sector.as(Sector),
        (line_def.flags & LineFlags::TwoSided).to_i32 != 0 ? back_side.as?(SideDef).try &.sector : nil
      )
    end

    def self.from_wad(wad : Wad, lump : Int32, vertices : Array(Vertex), lines : Array(LineDef)) : Array(Seg)
      length = wad.get_lump_size(lump)
      raise "" if length % @@datasize != 0

      data = wad.read_lump(lump)
      count = (length / @@datasize).to_i32
      segs = Array(Seg).new(count)

      count.times do |i|
        offset = @@datasize * i
        segs << from_data(data, offset, vertices, lines)
      end

      return segs
    end
  end
end
