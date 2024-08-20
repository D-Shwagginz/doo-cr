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
  class Vertex
    class_getter datasize : Int32 = 4

    getter x : Fixed
    getter y : Fixed

    def initialize(@x : Fixed, @y : Fixed)
    end

    def self.from_data(data : Bytes, offset : Int32) : Vertex
      x = IO::ByteFormat::LittleEndian.decode(Int16, data[offset, 2])
      y = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 2, 2])

      return Vertex.new(Fixed.from_i(x), Fixed.from_i(y))
    end

    def self.from_wad(wad : Wad, lump : Int32) : Array(Vertex)
      length = wad.get_lump_size(lump)
      raise if length % @@datasize != 0

      data = wad.read_lump(lump)
      count = length / @@datasize
      vertices = Array(Vertex).new(count)

      count.times do |i|
        offset = @@datasize * i
        vertices << from_data(data, offset)
      end

      return vertices
    end
  end
end
