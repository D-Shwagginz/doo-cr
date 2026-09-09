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
# ==> Screen wipe

module Doocr
  def self.wipe_shitty_col_major_x_form(array : Int16*, width : Int32, height : Int32)
    dest = CDoom.z_malloc(width * height * sizeof(Int16), CDoom::PU_STATIC, Pointer(Void).null).as(Int16*)

    height.times do |y|
      width.times do |x|
        dest[x * height + y] = array[y * width + x]
      end
    end

    CDoom.doom_memcpy(array, dest, width * height * 2)

    CDoom.z_free(dest)
  end

  def self.wipe_init_color_x_form(width : Int32, height : Int32, ticks : Int32) : Int32
    CDoom.doom_memcpy(CDoom.wipe_scr, CDoom.wipe_scr_start, width * height)
    return 0
  end

  def self.wipe_do_color_x_form(width : Int32, height : Int32, ticks : Int32) : Int32
    changed = 0
    w = CDoom.wipe_scr
    e = CDoom.wipe_scr_end
    stop = w + width * height

    while w != stop
      wv = w.value.to_i32
      ev = e.value.to_i32
      if wv != ev
        if wv > ev
          newval = wv - ticks
          w.value = (newval < ev ? ev : newval).to_u8
        elsif wv < ev
          newval = wv + ticks
          w.value = (newval > ev ? ev : newval).to_u8
        end
        changed = 1
      end
      w += 1
      e += 1
    end

    return (changed == 0).to_unsafe
  end

  def self.wipe_exit_color_x_form(width : Int32, height : Int32, ticks : Int32) : Int32
    return 0
  end

  def self.wipe_init_melt(width : Int32, height : Int32, ticks : Int32) : Int32
    # copy start screen to main screen
    CDoom.doom_memcpy(CDoom.wipe_scr, CDoom.wipe_scr_start, width * height)

    # makes this wipe faster (in theory)
    # to have stuff in column-major format
    CDoom.wipe_shitty_col_major_x_form(CDoom.wipe_scr_start.as(Int16*), width // 2, height)
    CDoom.wipe_shitty_col_major_x_form(CDoom.wipe_scr_end.as(Int16*), width // 2, height)

    # setup initial column positions
    # (y<0 => not ready to scroll yet)
    CDoom.y = CDoom.z_malloc(width * sizeof(Int32), CDoom::PU_STATIC, Pointer(Void).null).as(Int32*)
    CDoom.y[0] = -(CDoom.m_random % 16)
    i = 1
    while i < width
      r = (CDoom.m_random % 3) - 1
      CDoom.y[i] = CDoom.y[i - 1] + r
      if (CDoom.y[i] > 0)
        CDoom.y[i] = 0
      elsif CDoom.y[i] == -16
        CDoom.y[i] = -15
      end
      i += 1
    end

    return 0
  end

  def self.wipe_do_melt(width : Int32, height : Int32, ticks : Int32) : Int32
    done = 1

    width //= 2

    while ticks != 0
      width.times do |i|
        if CDoom.y[i] < 0
          CDoom.y[i] = CDoom.y[i] + 1
          done = 0
        elsif CDoom.y[i] < height
          dy = (CDoom.y[i] < 16) ? CDoom.y[i] + 1 : 8
          dy = height - CDoom.y[i] if CDoom.y[i] + dy >= height
          s = CDoom.wipe_scr_end.as(Int16*) + (i * height + CDoom.y[i])
          d = CDoom.wipe_scr.as(Int16*) + (CDoom.y[i] * width + i)
          idx = 0
          j = dy
          while j != 0
            d[idx] = s.value
            s += 1
            idx += width
            j -= 1
          end
          CDoom.y[i] = CDoom.y[i] + dy
          s = CDoom.wipe_scr_start.as(Int16*) + (i * height)
          d = CDoom.wipe_scr.as(Int16*) + (CDoom.y[i] * width + i)
          idx = 0
          j = height - CDoom.y[i]
          while j != 0
            d[idx] = s.value
            s += 1
            idx += width
            j -= 1
          end
          done = 0
        end
      end

      ticks -= 1
    end

    return done
  end

  def self.wipe_exit_melt(width : Int32, height : Int32, ticks : Int32) : Int32
    CDoom.z_free(CDoom.y)
    return 0
  end

  def self.wipe_start_screen(x : Int32, y : Int32, width : Int32, height : Int32) : Int32
    CDoom.wipe_scr_start = CDoom.screens[2]
    CDoom.i_read_screen(CDoom.wipe_scr_start)
    return 0
  end

  def self.wipe_end_screen(x : Int32, y : Int32, width : Int32, height : Int32) : Int32
    CDoom.wipe_scr_end = CDoom.screens[3]
    CDoom.i_read_screen(CDoom.wipe_scr_end)
    CDoom.v_draw_block(x, y, 0, width, height, CDoom.wipe_scr_start) # restore start scr
    return 0
  end

  @@wipes : Array(Proc(Int32, Int32, Int32, Int32)) = [
    ->CDoom.wipe_init_color_x_form(Int32, Int32, Int32), ->CDoom.wipe_do_color_x_form(Int32, Int32, Int32),
    ->CDoom.wipe_exit_color_x_form(Int32, Int32, Int32), ->CDoom.wipe_init_melt(Int32, Int32, Int32),
    ->CDoom.wipe_do_melt(Int32, Int32, Int32), ->CDoom.wipe_exit_melt(Int32, Int32, Int32),
  ]

  def self.wipe_screen_wipe(wipeno : Int32, x : Int32, y : Int32, width : Int32, height : Int32, ticks : Int32) : Int32
    # initial stuff
    if Doocr.go == 0
      Doocr.go = 1
      CDoom.wipe_scr = CDoom.screens[0]
      @@wipes[wipeno * 3].call(width, height, ticks)
    end

    # do a piece of wipe-in
    CDoom.v_mark_rect(0, 0, width, height)
    rc = @@wipes[wipeno * 3 + 1].call(width, height, ticks)

    # final stuff
    if rc != 0
      Doocr.go = 0
      @@wipes[wipeno * 3 + 2].call(width, height, ticks)
    end

    return (Doocr.go == 0).to_unsafe
  end
end
