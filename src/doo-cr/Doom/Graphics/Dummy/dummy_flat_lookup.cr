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

require "../i_flat_lookup.cr"

module Doocr
  class DummyFlatLookup
    include IFlatLookup
    @flats : Array(Flat)

    @name_to_flat : Hash(String, Flat)
    @name_to_number : Hash(String, Int32)

    getter sky_flat_number : Int32
    getter sky_flat : Flat

    def each(&)
      @flats.each do |t|
        yield t
      end
    end

    def size
      return @flats.size
    end

    def [](num : Int32)
      return @flats[num]
    end

    def [](name : String) : Flat
      @name_to_flat[name]
    end

    def initialize(wad : Wad)
      first_flat = wad.get_lump_number("F_START") + 1
      last_flat = wad.get_lump_number("F_END") - 1
      count = last_flat - first_flat + 1

      @flats = Array(Flat).new(count)

      @name_to_flat = {} of String => Flat
      @name_to_number = {} of String => Int32

      lump = first_flat
      while lump <= last_flat
        if wad.get_lump_size(lump) != 4096
          lump += 1
          next
        end

        number = lump - first_flat
        name = wad.lump_infos[lump].name
        flat = name != "F_SKY1" ? DummyData.get_flat : DummyData.get_sky_flat
        flat = flat.as(Flat)

        @flats << flat
        @name_to_flat[name] = flat
        @name_to_number[name] = number

        lump += 1
      end

      @sky_flat_number = @name_to_number["F_SKY1"]
      @sky_flat = @name_to_flat["F_SKY1"]
    end

    def get_number(name : String) : Int32
      if @name_to_number.has_key?(name)
        return @name_to_number[name]
      else
        return -1
      end
    end
  end
end
