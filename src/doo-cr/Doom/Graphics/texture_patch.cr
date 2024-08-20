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
  class TexturePatch
    class_getter datasize : Int32 = 10

    getter origin_x : Int32
    getter origin_y : Int32
    @patch : Patch

    def name : String
      return @patch.name
    end

    def width : Int
      return @patch.width
    end

    def height : Int
      return @patch.height
    end

    def columns : Array(Array(Column))
      return @patch.columns
    end

    def initialize(@origin_x : Int32, @origin_y : Int32, @patch : Patch)
    end

    def self.from_data(data : Bytes, offset : Int, patches : Array(Patch)) : TexturePatch
      origin_x = IO::ByteFormat::LittleEndian.decode(Int16, data[offset, 2])
      origin_y = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 2, 2])
      patch_num = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 4, 2])

      return TexturePatch.new(origin_x, origin_y, patches[patch_num])
    end
  end
end
