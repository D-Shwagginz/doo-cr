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
  class MapThing
    class_getter datasize : Int32 = 10

    getter empty : MapThing = MapThing.new(
      Fixed.zero,
      Fixed.zero,
      Angle.ang0,
      0,
      ThingFlags.new(0)
    )

    getter x : Fixed
    getter y : Fixed
    getter angle : Angle
    property type : Int32
    getter flags : ThingFlags

    def initialize(
      @x : Fixed,
      @y : Fixed,
      @angle : Angle,
      @type : Int32,
      @flags : ThingFlags
    )
    end

    def self.from_data(data : Bytes, offset : Int32) : MapThing
      x = IO::ByteFormat::LittleEndian.decode(Int16, data[offset, 2])
      y = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 2, 2])
      angle = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 4, 2])
      type = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 6, 2])
      flags = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 8, 2])

      return MapThing.new(
        Fixed.from_i(x),
        Fixed.from_i(y),
        Angle.new(Angle.ang45.data * (angle / 45).to_u32),
        type,
        ThingFlags.new(flags)
      )
    end

    def self.from_wad(wad : Wad, lump : Int32) : Array(MapThing)
      length = wad.get_lump_size(lump)
      raise if length % @@datasize != 0

      data = wad.read_lump(lump)
      count = length / @@datasize
      things = Array(MapThing).new(count)

      count.times do |i|
        offset = @@datasize * i
        things << from_data(data, offset)
      end

      return things
    end
  end
end
