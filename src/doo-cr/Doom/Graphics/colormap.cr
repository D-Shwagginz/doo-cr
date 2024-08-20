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
  class ColorMap
    class_getter inverse : Int32 = 32

    @data : Array(Array(UInt8))

    def [](index : Int)
      return @data[index]
    end

    def full_bright : Array(UInt8)
      return @data[0]
    end

    def initialize(wad : Wad)
      begin
        print("Load color map: ")

        raw = wad.read_lump("COLORMAP")
        num = raw.size / 256
        @data = Array.new(num, [] of UInt8)
        num.times do |i|
          @data[i] = Array(UInt8).new(256)
          offset = 256 * i
          256.times do |c|
            @data[i][c] = raw[offset + c]
          end
        end

        puts("OK")
      rescue e
        puts("Failed")
        raise e
      end
    end
  end
end
