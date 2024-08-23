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

require "../doom/graphics/i_flat_lookup.cr"
require "../doom/graphics/i_sprite_lookup.cr"

module Doocr::Video
  class FinaleRenderer
    @wad : Wad
    @flats : IFlatLookup
    @sprites : ISpriteLookup

    @screen : DrawScreen
    @scale : Int32

    @cache : PatchCache

    def initialize(content : GameContent, @screen)
      @wad = content.wad
      @flats = content.flats
      @sprites = content.sprites

      @scale = @screen.width / 320

      @cache = PatchCache.new(@wad)
    end

    def render(finale : Finale)
      if finale.stage == 2
        render_cast(finale)
        return
      end

      if finale.state == 0
        render_text_screen(finale)
      else
        case finale.options.episode
        when 1
          draw_patch("CREDIT", 0, 0)
          break
        when 2
          draw_patch("VICTORY2", 0, 0)
          break
        when 3
          bunny_scroll(finale)
          break
        when 4
          draw_patch("ENDPIC", 0, 0)
          break
        end
      end
    end

    private def render_text_screen(finale : Finale)
      fill_flat(@flats[finale.flat])

      # Draw some of the text onto the screen.
      cx = 10 * @scale
      cy = 17 * @scale
      ch = 0

      count = (finale.count - 10) / Finale.text_speed
      count = 0 if count < 0

      while count > 0
        break if ch == finale.text.size

        c = finale.text[ch]
        ch += 1

        if c == '\n'
          cx = 10 * @scale
          cy += 11 * @scale
          count -= 1
          next
        end

        @screen.draw_char(c, cx, cy, @scale)

        cx += @screen.measure_char(c, @scale)
        count -= 1
      end
    end

    private def bunny_scroll(finale : Finale)
      scroll = 320 - finale.scrolled
      draw_patch("PFUB2", scroll - 320, 0)
      draw_patch("PFUB1", scroll, 0)

      if finale.show_the_end
        patch = "END0"
        case finale.the_end_index
        when 1
          patch = "END1"
          break
        when 2
          patch = "END2"
          break
        when 3
          patch = "END3"
          break
        when 4
          patch = "END4"
          break
        when 5
          patch = "END5"
          break
        when 6
          patch = "END6"
          break
        end

        draw_patch(
          patch,
          (320 - 13 * 8) / 2,
          (240 - 8 * 8) / 2
        )
      end
    end

    private def fill_flat(flat : Flat)
      src = flat.data
      dst = @screen.data
      scale = @screen.width / 320
      x_frac = Fixed.one / scale - Fixed.epsilon
      step = Fixed.one / scale
      @screen.width.times do |x|
        y_frac = Fixed.one / scale - Fixed.epsilon
        p = @screen.height * x
        @screen.height.times do |y|
          spot_x = x_frac.to_i_floor & 0x3F
          spot_y = y_frac.to_i_floor & 0x3F
          dst[p] = src[(spot_y << 6) + spot_x]
          y_frac += step
          p += 1
        end
        x_frac += step
      end
    end

    private def draw_patch(name : String, x : Int32, y : Int32)
      scale = @screen.width / 320
      @screen.draw_patch(@cache[name], @scale * x, @scale * y, @scale)
    end

    private def render_cast(finale : Finale)
      draw_patch("BOSSBACK", 0, 0)

      frame = finale.cast_state.frame & 0x7fff
      patch = @sprites[finale.cast_state.sprite].frames[frame].patches[0]
      if sprites[finale.cast_state.sprite].frames[frame].flip[0]
        @screen.draw_patch_flip(
          patch,
          @screen.width / 2,
          @screen.height - @scale * 30,
          @scale
        )
      else
        @screen.draw_patch(
          patch,
          @screen.width / 2,
          @screen.height - @scale * 30,
          @scale
        )
      end

      width = @screen.measure_text(finale.cast_name, @scale)
      @screen.draw_text(
        finale.cast_name,
        (@screen.width - width) / 2,
        @screen.height - @scale * 13,
        @scale
      )
    end
  end
end
