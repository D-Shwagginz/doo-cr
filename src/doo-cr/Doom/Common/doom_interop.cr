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
  module DoomInterop
    def self.to_string(data : Bytes, offset : Int32, max_length : Int32)
      length = 0
      max_length.times do |i|
        break if data[offset + i] == 0
        length += 1
      end
      chars = Array.new(length, '\0')
      chars.size.times do |i|
        c = data[offset + i]
        c -= 0x20 if 'a' <= c && c <= 'z'
        chars[i] = c.chr
      end
      string = String.build do |buffer|
        chars.each do |char|
          buffer << char
        end
      end
      return string
    end
  end
end
