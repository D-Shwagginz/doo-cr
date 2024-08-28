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

require "./i_texture_lookup.cr"

module Doocr
  class TextureLookup
    include ITextureLookup
    @textures : Array(Texture) = Array(Texture).new
    @name_to_texture : Hash(String, Texture) = {} of String => Texture
    @name_to_number : Hash(String, Int32) = {} of String => Int32

    getter switch_list : Array(Int32) = Array(Int32).new

    def each(&)
      @textures.each do |t|
        yield t
      end
    end

    def size
      return @textures.size
    end

    def [](num : Int32)
      return @textures[num]
    end

    def [](name : String) : Texture
      return @name_to_texture[name]
    end

    def initialize(wad : Wad, use_dummy : Bool = false)
      begin
        print("Load textures: ")

        init_lookup(wad)
        init_switch_list()

        puts("OK (#{@textures.size} textures)")
      rescue e
        puts("Failed")
        raise e
      end
    end

    private def init_lookup(wad : Wad)
      @textures = [] of Texture
      @name_to_texture = {} of String => Texture
      @name_to_number = {} of String => Int32

      patches = load_patches(wad)

      n = 1
      while n <= 2
        lump_number = wad.get_lump_number("TEXTURE#{n + 1}")
        break if lump_number == -1

        data = wad.read_lump(lump_number)
        count = IO::ByteFormat::LittleEndian.decode(Int32, data[0, 4])
        count.times do |i|
          offset = IO::ByteFormat::LittleEndian.decode(Int32, data[4 + 4*i, 4])
          texture = Texture.from_data(data, offset, patches)
          @name_to_number[texture.name] = @textures.size if !@name_to_number[texture.name]?
          @textures << texture
          @name_to_texture[texture.name] = texture if !@name_to_texture[texture.name]?
        end
        n += 1
      end
    end

    private def init_switch_list
      list = [] of Int32
      DoomInfo.switch_names.each do |tuple|
        texnum1 = get_number(tuple[0].to_s)
        texnum2 = get_number(tuple[1].to_s)
        if texnum1 != -1 && texnum2 != -1
          list << texnum1
          list << texnum2
        end
      end

      @switch_list = list
    end

    def get_number(name : String) : Int32
      return 0 if name[0] == '-'
      if number = @name_to_number[name]?
        return number
      else
        return -1
      end
    end

    private def load_patches(wad : Wad) : Array(Patch)
      patch_names = load_patch_names(wad)
      patches = Array(Patch).new(patch_names.size)
      patch_names.size.times do |i|
        name = patch_names[i]

        # This check is necessary to avoid crash in DOOM1.WAD.
        next if wad.get_lump_number(name) == -1

        data = wad.read_lump(name)
        patches << Patch.from_data(name, data)
      end
      return patches
    end

    private def load_patch_names(wad : Wad) : Array(String)
      data = wad.read_lump("PNAMES")
      count = IO::ByteFormat::LittleEndian.decode(Int32, data[0, 4])
      names = Array(String).new(count)
      count.times do |i|
        names << String.new(data[4 + 8*i, 8])
      end

      return names
    end
  end
end
