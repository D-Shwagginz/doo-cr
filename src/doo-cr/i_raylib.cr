# Copyright (C) 2026 Devin Shwagginz
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# ==> System video

module Doocr
  @@raylibbuffer = Bytes.new(CDoom::SCREENWIDTH * CDoom::SCREENHEIGHT * 4)

  @@palette_rgba = Array(UInt32).new(256, 0_u32)

  def self.update_viewport(vt : Raylib::RenderTexture)
    # Software render
    viewport_ptr = @@software_screen.to_unsafe
    buf_ptr = @@raylibbuffer.to_unsafe.as(UInt32*)
    palette_ptr = @@palette_rgba.to_unsafe
    (CDoom::SCREENWIDTH * CDoom::SCREENHEIGHT).times do |p|
      pix = viewport_ptr[p]
      if pix == 255
        buf_ptr[p] = 0_u32
      else
        buf_ptr[p] = palette_ptr[pix]
      end
    end
    Raylib.update_texture(vt.texture, @@raylibbuffer.to_unsafe)

    Raylib.begin_texture_mode(vt) # TODO: Render GL player view
    #  Raylib.draw_text("Hello World!", 100, 100, 4, Raylib::BLUE)
    Raylib.end_texture_mode
  end

  def self.doom_draw
    if Thread.current != MAIN_THREAD
      raise "Error: doom_draw called off main thread: #{Thread.current} (expected #{MAIN_THREAD})"
      # Hopefully this fixes God's cursed bug
    end

    return unless Raylib.window_ready? || @@headless
    # Pointers for speed. "Oh! But it's oop!". I don't see you having a source port of Doom.
    screen_ptr = CDoom.screens[0]
    buf_ptr = @@raylibbuffer.to_unsafe.as(UInt32*)
    palette_ptr = @@palette_rgba.to_unsafe
    p255 = @@palette_rgba[255]

    @@screen_texture.try do |st|
      @@viewport_target.try do |vt|
        @@render_target.try do |rt|
          next unless Raylib.texture_valid?(st)
          (CDoom::SCREENWIDTH * CDoom::SCREENHEIGHT).times do |p|
            pix = screen_ptr[p]
            if !@@software_rendering && pix == 255
              buf_ptr[p] = 0_u32
            else
              buf_ptr[p] = palette_ptr[pix]
            end
          end

          Raylib.update_texture(st, @@raylibbuffer.to_unsafe)

          scalew = Raylib.get_screen_width.to_f / @@sres_x.to_f
          scaleh = Raylib.get_screen_height.to_f / @@sres_y.to_f
          scale = scalew < scaleh ? scalew : scaleh

          unless @@software_rendering
            update_viewport(vt)

            Raylib.begin_texture_mode(rt)
            Raylib.clear_background(Raylib::Color.new(r: p255 & 0xff, g: (p255 >> 8) & 0xff, b: (p255 >> 16) & 0xff, a: 255))

            Raylib.draw_texture_pro(vt.texture,
              Raylib::Rectangle.new(x: 0.0_f32, y: 0.0_f32, width: vt.texture.width.to_f, height: -vt.texture.height.to_f),
              Raylib::Rectangle.new(x: 0.0_f32, y: 0.0_f32,
                width: rt.texture.width.to_f, height: rt.texture.height.to_f),
              Raylib::Vector2.new, 0, Raylib::WHITE)
            Raylib.end_texture_mode
          end

          Raylib.begin_drawing
          Raylib.clear_background(Raylib::BLACK)
          unless @@software_rendering
            Raylib.draw_texture_pro(rt.texture,
              Raylib::Rectangle.new(x: 0.0_f32, y: 0.0_f32, width: rt.texture.width.to_f, height: rt.texture.height.to_f),
              Raylib::Rectangle.new(x: (Raylib.get_screen_width - (rt.texture.width.to_f * scale)) * 0.5_f32, y: (Raylib.get_screen_height - (rt.texture.height.to_f * scale)) * 0.5_f32,
                width: rt.texture.width.to_f * scale, height: rt.texture.height.to_f * scale),
              Raylib::Vector2.new, 0, Raylib::WHITE)
          end

          Raylib.draw_texture_pro(st,
            Raylib::Rectangle.new(x: 0.0_f32, y: 0.0_f32, width: st.width.to_f, height: st.height.to_f),
            Raylib::Rectangle.new(x: (Raylib.get_screen_width - (rt.texture.width.to_f * scale)) * 0.5_f32, y: (Raylib.get_screen_height - (rt.texture.height.to_f * scale)) * 0.5_f32,
              width: rt.texture.width.to_f * scale, height: rt.texture.height.to_f * scale),
            Raylib::Vector2.new, 0, Raylib::WHITE)

          # Draw crosshair
           if (Doocr.crosshair != 0 &&
             Doocr.menuactive == 0 &&
             Doocr.gamestate == CDoom::Gamestate::Level &&
             Doocr.automapactive == 0)
            y = CDoom::SCREENHEIGHT // 2
            y += Doocr.setblocks == 11 ? 8 : -8
            2.times do |i|
              Raylib.draw_pixel(CDoom::SCREENWIDTH // 2 - 2 - i, y, Raylib::RAYWHITE)
              Raylib.draw_pixel(CDoom::SCREENWIDTH // 2 + 2 + i, y, Raylib::RAYWHITE)
            end
            2.times do |i|
              Raylib.draw_pixel(CDoom::SCREENWIDTH // 2, (y - 2 - i), Raylib::RAYWHITE)
              Raylib.draw_pixel(CDoom::SCREENWIDTH // 2, (y + 2 + i), Raylib::RAYWHITE)
            end
          end
          Raylib.end_drawing
        end
      end
    end
  end
end
