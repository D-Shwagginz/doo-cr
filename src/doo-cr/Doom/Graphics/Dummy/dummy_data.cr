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
  module DummyData
    @@dummy_patch : Patch | Nil = nil

    def self.get_patch
      if @@dummy_patch != nil
        @@dummy_patch
      else
        width = 64
        height = 128

        data = Bytes.new(height + 32)
        data.size.times do |y|
          data[y] = y / 32 % 2 == 0 ? 80_u8 : 96_u8
        end

        columns = Array.new(width, [] of Column)
        c1 = [Column.new(0, data, 0, height)]
        c2 = [Column.new(0, data, 32, height)]
        width.times do |x|
          columns << x / 32 % 2 == 0 ? c1 : c2
        end

        @@dummy_patch = Patch.new("DUMMY", width, height, 32, 128, columns)

        return @@dummy_patch
      end
    end

    @@dummy_textures : Hash(Int, Texture)

    def self.get_texture(height : Int32) : Texture
      if @@dummy_textures.has_key?(height)
        return @@dummy_textures[height]
      else
        patch = [TexturePatch.new(0, 0, get_patch())]
        @@dummy_textures[height, Texture.new("DUMMY", false, 64, height, patch)]
        return @@dummy_textures[height]
      end
    end

    @@dummy_flat : Flat | Nil = nil

    def self.get_flat : Flat
      if @@dummy_flat != nil
        return @@dummy_flat
      else
        data = Bytes.new(64 * 64)
        spot = 0
        64.times do |y|
          64.times do |x|
            data[spot] = ((x / 32) ^ (y / 32)) == 0 ? 80_u8 : 96_u8
            spot += 1
          end
        end

        @@dummy_flat = Flat.new("DUMMY", data)

        return @@dummy_flat
      end
    end

    @@dummy_sky_flat : Flat | Nil = nil

    def self.get_sky_flat
      if @@dummy_sky_flat != nil
        return @@dummy_sky_flat
      else
        @@dummy_sky_flat = Flat.new("DUMMY", get_flat().data)
      end
    end
  end
end
