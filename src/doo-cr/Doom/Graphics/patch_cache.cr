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
  class PatchCache
    @wad : Wad
    @cache : Hash(String, Patch)

    def initialize(@wad : Wad)
      @cache = {} of String => Patch
    end

    def [](name : String)
      if !@cache[name]?
        patch = Patch.from_wad(@wad, name)
        @cache[name] = patch
      end
      return @cache[name]
    end

    def get_width(name : String) : Int32
      return [name].width
    end

    def get_height(name : String) : Int32
      return [name].height
    end
  end
end
