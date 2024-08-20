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
  class LineDef
    class_getter datasize : Int32 = 14

    getter vertex1 : Vertex | Nil
    getter vertex2 : Vertex | Nil

    getter dx : Fixed | Nil
    getter dy : Fixed | Nil

    property flags : LineFlags = LineFlags.new(0)
    property special : LineSpecial = LineSpecial.new(0)
    property tag : Int16 = 0_i16

    getter from_side : SideDef | Nil
    getter back_side : SideDef | Nil

    getter bounding_box : Array(Fixed) = Array(Fixed).new

    getter slope_type : SlopeType = SlopeType.new(0)

    getter front_sector : Sector | Nil
    getter back_sector : Sector | Nil

    property valid_count : Int32 = 0

    property special_data : Thinker | Nil

    property sound_origin : Mobj | Nil

    def initialize(
      @vertex1 : Vertex,
      @vertex2 : Vertex,
      @flags : LineFlags,
      @special : LineSpecial,
      @tag : Int16,
      @front_side : SideDef,
      @back_side : SideDef | Nil
    )
      @dx = @vertex2.x - @vertex1.x
      @dy = @vertex2.y - @vertex1.y

      if dx == Fixed.zero
        @slope_type = SlopeType::Vertical
      elsif dy == Fixed.zero
        @slope_type = SlopeType::Horizontal
      else
        if dy / dx > Fixed.zero
          @slope_type = SlopeType::Positive
        else
          @slope_type = SlopeType::Negative
        end
      end

      @bounding_box = Array(Fixed).new(4)
      @bounding_box << Fixed.max(@vertex1.y, @vertex2.y)
      @bounding_box << Fixed.min(@vertex1.y, @vertex2.y)
      @bounding_box << Fixed.min(@vertex1.x, @vertex2.x)
      @bounding_box << Fixed.max(@vertex1.x, @vertex2.x)

      @front_sector = @front_side.as?(Sector).try &.sector
      @back_sector = @back_side.as?(Sector).try &.sector
    end

    def self.from_data(data : Bytes, offset : Int32, vertices : Array(Vertex), sides : Array(SideDef)) : LineDef
      vertex1_number = IO::ByteFormat::LittleEndian.decode(Int16, data[offset, 2])
      vertex2_number = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 2, 2])
      flags = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 4, 2])
      special = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 6, 2])
      tag = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 8, 2])
      side0_number = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 10, 2])
      side1_number = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 12, 2])

      return LineDef.new(
        vertices[vertex1_number],
        vertices[vertex2_number],
        LineFlags.new(flags),
        LineSpecial.new(special),
        tag,
        sides[side0_number],
        side1_number != -1 ? sides[side1_number] : nil
      )
    end

    def self.from_wad(wad : Wad, lump : Int32, vertices : Array(Vertex), sides : Array(SideDef)) : Array(LineDef)
      length = wad.get_lump_size(lump)
      raise if length % @@datasize != 0

      data = wad.read_lump(lump)
      count = length / @@datasize
      lines = Array(LineDef).new(count)
      count.times do |i|
        offset = 14 * i
        lines << from_data(data, offset, vertices, sides)
      end

      return lines
    end
  end
end
