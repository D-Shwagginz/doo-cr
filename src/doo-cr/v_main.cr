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
# ==> Backend video stuff

module Doocr
  def self.slope_div(num : LibC::UInt, den : LibC::UInt) : LibC::Int
    return SLOPERANGE if den < 512

    ans = (num << 3)//(den >> 8)

    return ans <= SLOPERANGE ? ans.to_i32! : SLOPERANGE
  end

  def self.v_mark_rect(x : LibC::Int,
                       y : LibC::Int,
                       width : LibC::Int,
                       height : LibC::Int)
    CDoom.m_add_to_box(CDoom.dirtybox, x, y)
    CDoom.m_add_to_box(CDoom.dirtybox, x + width - 1, y + height - 1)
  end

  def self.v_copy_rect(srcx : LibC::Int,
                       srcy : LibC::Int,
                       srcscrn : LibC::Int,
                       width : LibC::Int,
                       height : LibC::Int,
                       destx : LibC::Int,
                       desty : LibC::Int,
                       destscrn : LibC::Int)
    {% if flag?("RANGECHECK") %}
      if srcx < 0 ||
         srcx + width > CDoom::SCREENWIDTH ||
         srcy < 0 || srcy + height > CDoom::SCREENHEIGHT ||
         destx < 0 || destx + width > CDoom::SCREENWIDTH ||
         desty < 0 ||
         desty + height > CDoom::SCREENHEIGHT ||
         srcscrn.to_u32! > 4 ||
         destscrn.to_u32! > 4
        CDoom.i_error("Error: Bad v_copy_rect")
      end
    {% end %}
    CDoom.v_mark_rect(destx, desty, width, height)

    src = CDoom.screens[srcscrn] + CDoom::SCREENWIDTH * srcy + srcx
    dest = CDoom.screens[destscrn] + CDoom::SCREENWIDTH * desty + destx

    while height > 0
      CDoom.doom_memcpy(dest, src, width)
      src += CDoom::SCREENWIDTH
      dest += CDoom::SCREENWIDTH
      height -= 1
    end
  end

  #
  # Masks a column based masked pic to the screen.
  #
  def self.v_draw_patch(x : LibC::Int,
                        y : LibC::Int,
                        scrn : LibC::Int,
                        patch : CDoom::Patch*)
    y -= patch.value.topoffset
    x -= patch.value.leftoffset
    {% if flag?("RANGECHECK") %}
      if x < 0 ||
         x + patch.value.width - 1 > CDoom::SCREENWIDTH ||
         y < 0 ||
         y + patch.value.height - 1 > CDoom::SCREENHEIGHT ||
         scrn.to_u32! > 4
        # No i_error abort - what is up with TNT.WAD?
        puts "Patch at #{x},#{y}, exceeds LFB"
        puts "v_draw_patch: bad patch (ignored)"
        return
      end
    {% end %}

    if scrn == 0
      CDoom.v_mark_rect(x, y, patch.value.width, patch.value.height)
    end

    col = 0
    desttop = CDoom.screens[scrn] + y * CDoom::SCREENWIDTH + x

    w = patch.value.width

    while col < w
      column = (patch.as(UInt8*) + (patch.value.columnofs.to_unsafe + col).value).as(CDoom::Column*)

      # step through the posts in a column
      until column.value.topdelta == 0xff
        source = column.as(UInt8*) + 3
        dest = desttop + column.value.topdelta.to_u64 * CDoom::SCREENWIDTH
        count = column.value.length

        while count != 0
          count -= 1
          dest.value = source.value
          source += 1
          dest += CDoom::SCREENWIDTH
        end
        column = (column.as(UInt8*) + column.value.length + 4).as(CDoom::Column*)
      end

      x += 1
      col += 1
      desttop += 1
    end
  end

  #
  # Masks a column based masked pic to the screen.
  # Flips horizontally, e.g. to mirror face.
  #
  def self.v_draw_patch_flipped(x : LibC::Int,
                                y : LibC::Int,
                                scrn : LibC::Int,
                                patch : CDoom::Patch*)
    y -= patch.value.topoffset
    x -= patch.value.leftoffset
    {% if flag?("RANGECHECK") %}
      if x < 0 ||
         x + patch.value.width > CDoom::SCREENWIDTH ||
         y < 0 ||
         y + patch.value.height > CDoom::SCREENHEIGHT ||
         scrn.to_u32! > 4
        puts "Patch origin #{x},#{y} exceeds LFB"
        CDoom.i_error("Error: Bad v_draw_patch in v_draw_patch_flipped")
      end
    {% end %}

    if scrn == 0
      CDoom.v_mark_rect(x, y, patch.value.width, patch.value.height)
    end

    col = 0
    desttop = CDoom.screens[scrn] + y * CDoom::SCREENWIDTH + x

    w = patch.value.width

    while col < w
      column = (patch.as(UInt8*) + (patch.value.columnofs.to_unsafe + (w - 1 - col)).value).as(CDoom::Column*)

      # step through the posts in a column
      until column.value.topdelta == 0xff
        source = column.as(UInt8*) + 3
        dest = desttop + column.value.topdelta.to_u64 * CDoom::SCREENWIDTH
        count = column.value.length

        while count != 0
          count -= 1
          dest.value = source.value
          source += 1
          dest += CDoom::SCREENWIDTH
        end
        column = (column.as(UInt8*) + column.value.length + 4).as(CDoom::Column*)
      end

      x += 1
      col += 1
      desttop += 1
    end
  end

  def self.v_draw_patch_rect_direct(x : LibC::Int, y : LibC::Int, scrn : LibC::Int, patch : CDoom::Patch*, src_x : LibC::Int, src_w : LibC::Int)
    y -= patch.value.topoffset
    x -= patch.value.leftoffset
    {% if flag?("RANGECHECK") %}
      if x < 0 ||
         x + patch.value.width > CDoom::SCREENWIDTH ||
         y < 0 ||
         y + patch.value.height > CDoom::SCREENHEIGHT ||
         scrn.to_u32! > 4
        puts "Patch at #{x},#{y}, exceeds LFB"
        # No i_error abort - what is up with TNT.WAD?
        puts "v_draw_patch_rect_direct: bad patch (ignored)"
        return
      end
    {% end %}

    if scrn == 0
      CDoom.v_mark_rect(x, y, src_w, patch.value.height)
    end

    col = 0
    desttop = CDoom.screens[scrn] + y * CDoom::SCREENWIDTH + x

    w = src_w

    while col < w
      column = (patch.as(UInt8*) + (patch.value.columnofs.to_unsafe + (col + src_x)).value).as(CDoom::Column*)

      # step through the posts in a column
      until column.value.topdelta == 0xff
        source = column.as(UInt8*) + 3
        dest = desttop + column.value.topdelta.to_u64 * CDoom::SCREENWIDTH
        count = column.value.length

        while count != 0
          count -= 1
          dest.value = source.value
          source += 1
          dest += CDoom::SCREENWIDTH
        end
        column = (column.as(UInt8*) + column.value.length + 4).as(CDoom::Column*)
      end

      x += 1
      col += 1
      desttop += 1
    end
  end

  #
  # Draws directly to the screen on the pc.
  #
  def self.v_draw_patch_direct(x : LibC::Int,
                               y : LibC::Int,
                               scrn : LibC::Int,
                               patch : CDoom::Patch*)
    CDoom.v_draw_patch(x, y, scrn, patch)
  end

  #
  # Draw a linear block of pixels into the view buffer.
  #
  def self.v_draw_block(x : LibC::Int,
                        y : LibC::Int,
                        scrn : LibC::Int,
                        width : LibC::Int,
                        height : LibC::Int,
                        src : CDoom::Byte*)
    {% if flag?("RANGECHECK") %}
      if x < 0 ||
         x > CDoom::SCREENWIDTH ||
         y < 0 ||
         y > CDoom::SCREENHEIGHT ||
         scrn.to_u32! > 4
        CDoom.i_error("Error: Bad v_draw_block")
      end
    {% end %}

    CDoom.v_mark_rect(x, y, width, height)

    dest = CDoom.screens[scrn] + y * CDoom::SCREENWIDTH + x

    while height != 0
      height -= 1
      CDoom.doom_memcpy(dest, src, width)
      src += width
      dest += CDoom::SCREENWIDTH
    end
  end

  def self.v_get_block(x : LibC::Int,
                       y : LibC::Int,
                       scrn : LibC::Int,
                       width : LibC::Int,
                       height : LibC::Int,
                       dest : CDoom::Byte*)
    {% if flag?("RANGECHECK") %}
      if x < 0 ||
         x > CDoom::SCREENWIDTH ||
         y < 0 ||
         y > CDoom::SCREENHEIGHT ||
         scrn.to_u32! > 4
        CDoom.i_error("Error: Bad v_get_block")
      end
    {% end %}

    src = CDoom.screens[scrn] + y * CDoom::SCREENWIDTH + x

    while height != 0
      height -= 1
      CDoom.doom_memcpy(dest, src, width)
      src += width
      dest += width
    end
  end

  def self.v_init
    # stick these in low dos memory on PCs

    base = CDoom.i_alloc_low(CDoom::SCREENWIDTH * CDoom::SCREENHEIGHT * 4)

    4.times do |i|
      CDoom.screens[i] = base + i * CDoom::SCREENWIDTH * CDoom::SCREENHEIGHT
    end
  end
end
