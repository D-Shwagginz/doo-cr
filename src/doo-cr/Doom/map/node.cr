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
  class Node
    class_getter datasize : Int32 = 28

    getter x : Fixed
    getter y : Fixed
    getter dx : Fixed
    getter dy : Fixed

    getter bounding_box : Array(Array(Fixed))

    getter children : Array(Int32)

    def initialize(
      @x : Fixed,
      @y : Fixed,
      @dx : Fixed,
      @dy : Fixed,
      front_bounding_box_top : Fixed,
      front_bounding_box_bottom : Fixed,
      front_bounding_box_left : Fixed,
      front_bounding_box_right : Fixed,
      back_bounding_box_top : Fixed,
      back_bounding_box_bottom : Fixed,
      back_bounding_box_left : Fixed,
      back_bounding_box_right : Fixed,
      front_child : Int32,
      back_child : Int32
    )
      front_bounding_box = [
        front_bounding_box_top,
        front_bounding_box_bottom,
        front_bounding_box_left,
        front_bounding_box_right,
      ]

      back_bounding_box = [
        back_bounding_box_top,
        back_bounding_box_bottom,
        back_bounding_box_left,
        back_bounding_box_right,
      ]

      @bounding_box = [
        front_bounding_box,
        back_bounding_box,
      ]

      @children = [
        front_child,
        back_child,
      ]
    end

    def self.from_data(data : Bytes, offset : Int32) : Node
      x = IO::ByteFormat::LittleEndian.decode(Int16, data[offset, 2])
      y = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 2, 2])
      dx = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 4, 2])
      dy = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 6, 2])
      front_bounding_box_top = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 8, 2])
      front_bounding_box_bottom = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 10, 2])
      front_bounding_box_left = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 12, 2])
      front_bounding_box_right = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 14, 2])
      back_bounding_box_top = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 16, 2])
      back_bounding_box_bottom = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 18, 2])
      back_bounding_box_left = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 20, 2])
      back_bounding_box_right = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 22, 2])
      front_child = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 24, 2])
      back_child = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 26, 2])

      return Node.new(
        Fixed.from_i(x),
        Fixed.from_i(y),
        Fixed.from_i(dx),
        Fixed.from_i(dy),
        Fixed.from_i(front_bounding_box_top),
        Fixed.from_i(front_bounding_box_bottom),
        Fixed.from_i(front_bounding_box_left),
        Fixed.from_i(front_bounding_box_right),
        Fixed.from_i(back_bounding_box_top),
        Fixed.from_i(back_bounding_box_bottom),
        Fixed.from_i(back_bounding_box_left),
        Fixed.from_i(back_bounding_box_right),
        front_child,
        back_child
      )
    end

    def self.from_wad(wad : Wad, lump : Int32, subsectors : Array(Subsector)) : Array(Node)
      length = wad.get_lump_size(lump)
      raise "" if length % @@datasize != 0

      data = wad.read_lump(lump)
      count = (length / @@datasize).to_i32
      nodes = Array(Node).new(count)

      count.times do |i|
        offset = @@datasize * i
        nodes << from_data(data, offset)
      end

      return nodes
    end

    def self.is_subsector(node : Int32) : Bool
      return (node & 0xFFFF8000) != 0
    end

    def self.get_subsector(node : Int32) : Int32
      return node ^ 0xFFFF8000
    end
  end
end
