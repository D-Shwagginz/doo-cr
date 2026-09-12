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
# ==> System misc

module Doocr
  def self.i_get_heap_size : LibC::Int
    return Doocr.mb_used * 1024 * 1024
  end

  def self.i_zone_base(size : LibC::Int*) : CDoom::Byte*
    size.value = Doocr.mb_used * 1024 * 1024
    return GC.malloc(size.value).as(CDoom::Byte*)
  end

  @@basetime = 0

  #
  # i_get_time
  # returns time in 1/70th second tics
  #
  def self.i_get_time : LibC::Int
    now = Time.local
    sec = now.to_unix.to_i32
    usec = (now.nanosecond // 1_000).to_i32
    @@basetime = sec if @@basetime == 0
    newtics = (sec - @@basetime) * CDoom::TICRATE + usec * CDoom::TICRATE // 1000000
    return newtics
  end

  #
  # i_init
  #
  def self.i_init
    CDoom.i_init_graphics
    CDoom.i_init_sound
    CDoom.i_init_music
  end

  #
  # i_quit
  #
  def self.i_quit
    @@closing = true
    CDoom.d_quit_net_game
    CDoom.s_stop_music
    CDoom.i_shutdown_sound
    CDoom.i_shutdown_music
    CDoom.m_save_defaults
    CDoom.i_shutdown_graphics
    sleep 2.millisecond # give audio time to shutdown
    exit(0)
  end

  def self.i_wait_vbl(count : LibC::Int)
    now = Time.instant
    till = now + Time::Span.new(nanoseconds: (count * (1000000 // 70)) * 1000)
    while now < till
      now = Time.instant
    end
  end

  def self.i_alloc_low(length : LibC::Int) : CDoom::Byte*
    mem = GC.malloc(length).as(CDoom::Byte*)
    CDoom.doom_memset(mem, 0, length)
    return mem
  end

  #
  # i_error
  #
  def self.i_error(error : String)
    @@closing = true
    # Message first.
    STDERR.puts error

    # Shutdown. Here might be other errors.
    CDoom.g_check_demo_status if Doocr.demorecording != 0

    CDoom.d_quit_net_game
    CDoom.i_shutdown_sound
    CDoom.i_shutdown_music
    CDoom.i_shutdown_graphics

    exit(-1)
  end

  def self.i_shutdown_graphics
    @@screen_texture.try { |st| Raylib.unload_texture(st) }
    @@viewport_target.try { |vt| Raylib.unload_render_texture(vt) }
    @@render_target.try { |rt| Raylib.unload_render_texture(rt) }

    Raylib.close_window if Raylib.window_ready?
  end

  def self.i_start_frame
    i_poll_mouse
  end

  def self.i_start_tic(in_delta : Raylib::Vector2? = nil)
    mousedelta = in_delta || @@mouse_queued
    Doocr.doom_mouse_move(mousedelta.x.to_i32!, mousedelta.y.to_i32)
    if in_delta.nil?
      @@mouse_queued = Raylib::Vector2.new
    end

    poll_key(TAB, Tab)
    poll_key(ENTER, Enter)
    poll_key(ESCAPE, Escape)
    poll_key(SPACE, Space)
    poll_key(APOSTROPHE, Apostrophe)
    poll_key(MULTIPLY, KpMultiply)
    poll_key(COMMA, Comma)
    poll_key(MINUS, Minus)
    poll_key(PERIOD, Period)
    poll_key(SLASH, Slash)
    poll_key(ZERO, Zero)
    poll_key(ONE, One)
    poll_key(TWO, Two)
    poll_key(THREE, Three)
    poll_key(FOUR, Four)
    poll_key(FIVE, Five)
    poll_key(SIX, Six)
    poll_key(SEVEN, Seven)
    poll_key(EIGHT, Eight)
    poll_key(NINE, Nine)
    poll_key(SEMICOLON, Semicolon)
    poll_key(EQUALS, Equal)
    poll_key(LEFT_BRACKET, LeftBracket)
    poll_key(RIGHT_BRACKET, RightBracket)
    poll_key(A, A)
    poll_key(B, B)
    poll_key(C, C)
    poll_key(D, D)
    poll_key(E, E)
    poll_key(F, F)
    poll_key(G, G)
    poll_key(H, H)
    poll_key(I, I)
    poll_key(J, J)
    poll_key(K, K)
    poll_key(L, L)
    poll_key(M, M)
    poll_key(N, N)
    poll_key(O, O)
    poll_key(P, P)
    poll_key(Q, Q)
    poll_key(R, R)
    poll_key(S, S)
    poll_key(T, T)
    poll_key(U, U)
    poll_key(V, V)
    poll_key(W, W)
    poll_key(X, X)
    poll_key(Y, Y)
    poll_key(Z, Z)
    poll_key(BACKSPACE, Backspace)
    poll_two_key(CTRL, LeftControl, RightControl)
    poll_key(LEFT_ARROW, Left)
    poll_key(UP_ARROW, Up)
    poll_key(RIGHT_ARROW, Right)
    poll_key(DOWN_ARROW, Down)
    poll_two_key(SHIFT, LeftShift, RightShift)
    poll_two_key(ALT, LeftAlt, RightAlt)
    poll_key(F1, F1)
    poll_key(F2, F2)
    poll_key(F3, F3)
    poll_key(F4, F4)
    poll_key(F5, F5)
    poll_key(F6, F6)
    poll_key(F7, F7)
    poll_key(F8, F8)
    poll_key(F9, F9)
    poll_key(F10, F10)
    poll_key(F11, F11)
    poll_key(F12, F12)
    poll_key(PAUSE, Pause)

    poll_button(LEFT, Left)
    poll_button(RIGHT, Right)
    poll_button(MIDDLE, Middle)
  end

  def self.i_update_no_blit
    # what is this?
  end

  @@lasttic = 0

  def self.i_finish_update
    # draws little dots on the bottom of the screen
    if Doocr.devparm != 0
      i = CDoom.i_get_time
      tics = i - @@lasttic
      @@lasttic = i
      tics = 20 if tics > 20

      i = 0
      while i < tics * 2
        Doocr.screens[0][(CDoom::SCREENHEIGHT - 1) * CDoom::SCREENWIDTH + i] = 0xff
        i += 2
      end
      while i < 20 * 2
        Doocr.screens[0][(CDoom::SCREENHEIGHT - 1) * CDoom::SCREENWIDTH + i] = 0x0
        i += 2
      end
    end

    doom_draw
  end

  def self.color_distance(r1 : Int32, g1 : Int32, b1 : Int32, r2 : Int32, g2 : Int32, b2 : Int32) : Int32
    dr = r1 - r2
    dg = g1 - g2
    db = b1 - b2
    (2 * dr * dr) + (4 * dg * dg) + (3 * db * db)
  end

  def self.nearest_palette_index(r : Int32, g : Int32, b : Int32) : UInt8
    best_idx = 0
    best_dist = Int32::MAX
    256.times do |i|
      pr = Doocr.screen_palette[i * 3].to_i32
      pg = Doocr.screen_palette[i * 3 + 1].to_i32
      pb = Doocr.screen_palette[i * 3 + 2].to_i32
      d = color_distance(r, g, b, pr, pg, pb)
      if d < best_dist
        best_dist = d
        best_idx = i
      end
    end
    best_idx.to_u8
  end

  def self.i_read_screen(scr : CDoom::Byte*)
    if @@software_rendering
      CDoom.doom_memcpy(scr, Doocr.screens[0], CDoom::SCREENWIDTH * CDoom::SCREENHEIGHT)
    else
      @@viewport_target.try do |vt|
        hud_ptr = Doocr.screens[0]

        vpimage = Raylib.load_image_from_texture(vt.texture)

        (CDoom::SCREENWIDTH * CDoom::SCREENHEIGHT).times do |p|
          pix = hud_ptr[p]
          if pix == 255 # Get viewport color
            x = p % CDoom::SCREENWIDTH
            y = p // CDoom::SCREENWIDTH
            color = Raylib.get_image_color(vpimage, x, y)
            scr[p] = nearest_palette_index(color.r.to_i32, color.g.to_i32, color.b.to_i32)
          else
            scr[p] = pix
          end
        end

        Raylib.unload_image(vpimage)
      end
    end
  end

  def self.i_set_palette(palette : CDoom::Byte*)
    256.times do |i|
      r = Doocr.gammatable[Doocr.usegamma][palette.value] & ~3
      palette += 1
      g = Doocr.gammatable[Doocr.usegamma][palette.value] & ~3
      palette += 1
      b = Doocr.gammatable[Doocr.usegamma][palette.value] & ~3
      palette += 1
      Doocr.screen_palette[i*3] = r
      Doocr.screen_palette[i*3 + 1] = g
      Doocr.screen_palette[i*3 + 2] = b
      @@palette_rgba[i] = (255_u32 << 24) | (b.to_u32 << 16) | (g.to_u32 << 8) | r.to_u32
    end
  end

  def self.float_to_fixed(f : Float64) : CDoom::Fixed
    (f * FRACUNIT).round.to_i32
  end

  @@was_focused = false

  def self.i_init_graphics
    Doocr.screens[0] = GC.malloc(CDoom::SCREENWIDTH * CDoom::SCREENHEIGHT).as(UInt8*)
    Doocr.screens[0].clear(CDoom::SCREENWIDTH * CDoom::SCREENHEIGHT)

    unless @@headless
      Raylib.set_config_flags(Raylib::ConfigFlags::WindowResizable)
      Raylib.init_window(1024, 768, "DOO-CR")
      Raylib.set_exit_key(Raylib::KeyboardKey::Null)
      @@was_focused = false
      Raylib.toggle_borderless_windowed if @@rlfullscreen != 0
      # Raylib.set_target_fps(35)

      image = Raylib.gen_image_color(CDoom::SCREENWIDTH, CDoom::SCREENHEIGHT, Raylib::BLACK)
      @@screen_texture = Raylib.load_texture_from_image(image)
      @@viewport_target = Raylib.load_render_texture(CDoom::SCREENWIDTH, CDoom::SCREENHEIGHT)
      @@render_target = Raylib.load_render_texture(@@sres_x, @@sres_y)

      Raylib.unload_image(image)
      Raylib.set_texture_filter(@@screen_texture.not_nil!, Raylib::TextureFilter::Point)
      Raylib.set_texture_filter(@@viewport_target.not_nil!.texture, Raylib::TextureFilter::Point)
      Raylib.set_texture_filter(@@render_target.not_nil!.texture, Raylib::TextureFilter::Point)
    end

    CDoom.i_set_palette(CDoom.w_cache_lump_name("PLAYPAL", CDoom::PU_CACHE).as(UInt8*))
  end
end
