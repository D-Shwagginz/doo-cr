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

require "./i_sprite_lookup.cr"

module Doocr
  class SpriteLookup
    include ISpriteLookup

    @spritedefs : Array(SpriteDef)

    def initialize(wad : Wad)
      begin
        print("Load sprites: ")

        temp = {} of String => Array(SpriteInfo)
        Sprite::Count.to_i32.times do |i|
          temp[DoomInfo.sprite_names[i]] = [] of SpriteInfo if !temp[DoomInfo.sprite_names[i]]?
        end

        cache = {} of Int32 => Patch

        enumerate_sprites(wad) do |lump|
          name = wad.lump_infos[lump].name[0, 4]

          next if !temp[name]?

          list = temp[name]

          frame = wad.lump_infos[lump].name[4] - 'A'
          rotation = wad.lump_infos[lump].name[5] - '0'

          while list.size < frame + 1
            list << SpriteInfo.new
          end

          if rotation.ord == 0
            8.times do |i|
              if list[frame].patches[i]? == nil
                list[frame].patches << cached_read(lump, wad, cache)
                list[frame].flip << true
              end
            end
          else
            if list[frame].patches[rotation - 1]? == nil
              list[frame].patches << cached_read(lump, wad, cache)
              list[frame].flip << true
            end
          end
        end

        @spritedefs = Array(SpriteDef).new(Sprite::Count.to_i32)
        Sprite::Count.to_i32.times do |i|
          list = temp[DoomInfo.sprite_names[i]]

          frames = Array(SpriteFrame).new(list.size)
          list.size.times do |j|
            list[j].check_completion

            frame = SpriteFrame.new(list[j].has_rotation, list[j].patches, list[j].flip)
            frames << frame
          end

          @spritedefs << SpriteDef.new(frames)
        end

        puts("OK (#{cache.size} sprites)")
      rescue e
        puts("Failed")
        raise e
      end
    end

    private def enumerate_sprites(wad : Wad, &)
      sprite_selection = false
      lump = wad.lump_infos.size - 1
      while lump >= 0
        name = wad.lump_infos[lump].name

        if name.starts_with?("S")
          if name.ends_with?("_END")
            sprite_selection = true
            lump -= 1
            next
          elsif name.ends_with?("_START")
            sprite_selection = false
            lump -= 1
            next
          end
        end

        if sprite_selection
          if wad.lump_infos[lump].size > 0
            yield lump
          end
        end

        lump -= 1
      end
    end

    private def cached_read(lump : Int32, wad : Wad, cache : Hash(Int32, Patch)) : Patch
      if !cache.has_key?(lump)
        name = wad.lump_infos[lump].name
        cache[lump] = Patch.from_data(name, wad.read_lump(lump))
      end

      return cache[lump]
    end

    def [](sprite : Sprite) : SpriteDef
      return @spritedefs[sprite.to_i32]
    end

    private class SpriteInfo
      getter patches : Array(Patch)
      getter flip : Array(Bool)

      def initialize
        @patches = Array(Patch).new(8)
        @flip = Array(Bool).new(8)
      end

      def check_completion
        8.times do |i|
          if @patches[i]? == nil
            raise("Missing sprite!")
          end
        end
      end

      def has_rotation : Bool
        (@patches.size - 1).times do |i|
          return true if @patches[i + 1]? && @patches[i + 1] != @patches[0]
        end

        return false
      end
    end
  end
end
