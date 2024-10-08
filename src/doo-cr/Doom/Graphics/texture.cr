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
  class Texture
    getter name : String
    getter masked : Bool
    getter width : Int32
    getter height : Int32
    getter patches : Array(TexturePatch)
    getter composite : Patch

    def to_s
      return @name
    end

    def initialize(
      @name,
      @masked,
      @width,
      @height,
      @patches
    )
      @composite = generate_composite(@name, @width, @height, @patches)
    end

    def self.from_data(data : Bytes, offset : Int32, patch_lookup : Array(Patch)) : Texture
      name = DoomInterop.to_s(data, offset, 8)
      masked = IO::ByteFormat::LittleEndian.decode(Int32, data[offset + 8, 4])
      width = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 12, 2])
      height = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 14, 2])
      patch_count = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 20, 2])
      patches = Array(TexturePatch).new(patch_count)
      patch_count.times do |i|
        patch_offset = offset + 22 + TexturePatch.datasize * i
        patches << TexturePatch.from_data(data, patch_offset, patch_lookup)
      end

      return Texture.new(
        name,
        masked != 0,
        width.to_i32,
        height.to_i32,
        patches
      )
    end

    def self.get_name(data : Bytes, offset : Int32) : String
      return DoomInterop.to_s(data, offset, 8)
    end

    def self.get_height(data : Bytes, offset : Int32) : Int32
      width = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 14, 2]).to_i32
    end

    private def generate_composite(name : String, width : Int32, height : Int32, patches : Array(TexturePatch)) : Patch
      patch_count = Array(Int32).new(width, 0)
      columns = Array.new(width, [] of Column)
      composite_column_count = 0

      patches.each do |patch|
        left = patch.origin_x
        right = left + patch.width

        start = Math.max(left, 0)
        ending = Math.min(right, width)

        x = start
        while x < ending
          patch_count[x] += 1
          if patch_count[x] == 2
            composite_column_count += 1
          end

          columns[x] = patch.columns[x - patch.origin_x]
          x += 1
        end
      end

      padding = 128 - height > 0 ? 128 - height : 0
      data = Bytes.new(height * composite_column_count + padding)
      i = 0
      width.times do |x|
        if patch_count[x] == 0
          columns[x] = [] of Column
        end

        if patch_count[x] >= 2
          column = Column.new(0, data, height * i, height)

          patches.each do |patch|
            px = x - patch.origin_x
            next if px < 0 || px >= patch.width
            patch_column = patch.columns[px]
            draw_column_in_cache(
              patch_column,
              column.data,
              column.offset,
              patch.origin_y,
              height
            )
          end

          columns[x] = (Array(Column).new << column)

          i += 1
        end
      end

      return Patch.new(name, width, height, 0, 0, columns)
    end

    private def draw_column_in_cache(
      source : Array(Column),
      destination : Bytes,
      destination_offset : Int32,
      destination_y : Int32,
      destination_height : Int32
    )
      source.each do |column|
        source_index = column.offset
        destination_index = destination_offset + destination_y + column.top_delta
        length = column.length

        top_exceedance = -(destination_y + column.top_delta)
        if top_exceedance > 0
          source_index += top_exceedance
          destination_index += top_exceedance
          length -= top_exceedance
        end

        bottom_exceedance = destination_y + column.top_delta + column.length - destination_height
        length -= bottom_exceedance if bottom_exceedance > 0

        if length > 0
          length.times do |i|
            column.data[source_index + i] = destination[destination_index + i]
          end
        end
      end
    end
  end
end
