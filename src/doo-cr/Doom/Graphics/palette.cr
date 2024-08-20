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
  class Palette
    getter damagestart : Int32 = 1
    getter damagecount : Int32 = 8

    getter bonusstart : Int32 = 9
    getter bonuscount : Int32 = 4

    getter ironfeet : Int32 = 13

    @data : Bytes

    @palettes : Array(Array(UInt32))

    def [](palette_number : Int)
      return @palettes[palette_number]
    end

    def initialize(wad : Wad)
      begin
        print("Load palette: ")

        @data = wad.read_lump("PLAYPAL")

        count = @data.size / (3 * 256)
        @palettes = Array.new(count, [] of UInt32)
        @palettes.size.times do |i|
          @palettes[i] = Array(UInt32).new(256)
        end

        puts("OK")
      rescue e
        puts("Failed")
        raise e
      end
    end

    def reset_colors(p : Float64)
      @palettes.size.times do |i|
        palette_offset = (3 * 256) * i
        256.times do |j|
          color_offset = palette_offset + 3 * j

          r = @data[color_offset]
          g = @data[color_offset + 1]
          b = @data[color_offset + 2]

          r = ().round_even(255 * ((r / 255.0)**p)).to_u8
          g = ().round_even(255 * ((g / 255.0)**p)).to_u8
          b = ().round_even(255 * ((b / 255.0)**p)).to_u8

          @palettes[i][j] = ((r << 0) | (g << 8) | (b << 16) | (255 << 24)).to_u32
        end
      end
    end
  end
end
