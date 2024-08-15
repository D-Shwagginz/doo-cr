require "../i_sprite_lookup.cr"

module Doocr
  class DummySpriteLookup
    include ISpriteLookup

    @spritedefs : Array(SpriteDef)

    def initialize(wad : Wad)
      temp = {} of String => Array(SpriteInfo)
      Sprite::Count.times do |i|
        temp[DoomInfo.sprite_names[i]] = [] of SpriteInfo
      end

      cache = {} of Int32 => Patch

      enumerate_sprites(wad) do |lump|
        name = wad.lump_infos[lump].name[0, 4]
        next if !temp.has_key?(name)

        list = temp[name]

        frame = wad.lump_infos[lump].name[4] - 'A'
        rotation = wad.lump_infos[lump].name[5] - '0'

        while list.size < frame.ord + 1
          list << SpriteInfo.new
        end

        if rotation == 0
          8.times do |i|
            if list[frame].patches[i]? == nil
              list[frame].patches << DummyData.get_patch
              list[frame].flip << false
            end
          end
        else
          if list[frame].patches[rotation - 1]? == nil
            list[frame].patches << DummyData.get_patch
            list[frame].flip << false
          end
        end
      end

      if wad.lump_infos[lump].name.size == 8
        frame = wad.lump_infos[lump].name[6] - 'A'
        rotation = wad.lump_infos[lump].name[7] - '0'

        while list.size < frame + 1
          list << SpriteInfo.new
        end

        if rotation == 0
          8.times do |i|
            if list[frames].patches[i]? == nil
              list[frame].patches << DummyData.get_patch
              list[frame].flip << true
            end
          end
        else
          if list[frame].patches[rotation - 1]? == nil
            list[frame].patches << DummyData.get_patch
            list[frame].flip << true
          end
        end
      end

      @spritedefs = Array(SpriteDef).new(Sprite::Count.to_i32)
      Sprite::Count.to_i32.times do |i|
        list = temp[DoomInfo.sprite_names[i]]

        frames = SpriteFrame.new(list.size)
        frames.size.times do |j|
          list[j].check_completion

          frame = SpriteFrame.new(list[j].has_rotation)
          frames[j] = frame
        end

        @spritedefs << SpriteDef.new(frames)
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
