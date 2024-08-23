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
  class DoomString
    @@value_table : Hash(String, DoomString) = {} of String => DoomString
    @@name_table : Hash(String, DoomString) = {} of String => DoomString

    @original : String | Nil = nil
    @replaced : String | Nil = nil

    def initialize(@original : String)
      @replaced = @original

      if !@@value_table.has_key?(@original)
        @@value_table[original] = self
      end
    end

    def initialize(name : String, @original : String)
      @@name_table[name] = self
    end

    def to_s
      return @replaced
    end

    def [](index : Int32) : Char
      return @replaced[index]
    end

    def self.replace_by_value(original : String, replaced : String)
      if ds = @@value_table[original]?
        ds.replaced = replaced
      end
    end

    def self.replace_by_name(name : String, value : String)
      if ds = @@name_table[name]?
        ds.replaced = value
      end
    end
  end
end
