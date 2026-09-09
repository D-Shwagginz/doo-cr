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
# ==> Doocr's own Blockmap builder

module Doocr::Nodebuilder
  def self.line_intersects_box?(v1 : Raylib::Vector2, v2 : Raylib::Vector2, bmin : Raylib::Vector2, bmax : Raylib::Vector2) : Bool
    # Parametric line: P(t) = v1 + t * (v2 - v1), for t in [0, 1]
    dx = v2.x - v1.x
    dy = v2.y - v1.y

    t_min = 0.0
    t_max = 1.0

    # Clip against each of the 4 box edges (slab method)
    {
      {-dx, v1.x - bmin.x}, # left edge
      {dx, bmax.x - v1.x},  # right edge
      {-dy, v1.y - bmin.y}, # bottom edge
      {dy, bmax.y - v1.y},  # top edge
    }.each do |(p, q)|
      if p == 0
        # Line is parallel to this edge; if outside, no intersection at all
        return false if q < 0
      else
        r = q / p
        if p < 0
          return false if r > t_max
          t_min = r if r > t_min
        else
          return false if r < t_min
          t_max = r if r < t_max
        end
      end
    end

    true
  end

  def self.build_blockmap
    blockmap = IO::Memory.new
    offsets = IO::Memory.new

    # Find map bounds
    left = Int32::MAX
    bottom = Int32::MAX
    right = Int32::MIN
    top = Int32::MIN
    Doocr.numvertexes.times do |i|
      vertex = CDoom.vertexes[i]
      x = vertex.x >> FRACBITS
      y = vertex.y >> FRACBITS
      right = x if x > right
      left = x if x < left
      top = y if y > top
      bottom = y if y < bottom
    end

    Doocr.bmaporgx = left << FRACBITS
    Doocr.bmaporgy = bottom << FRACBITS

    Doocr.bmapwidth = ((right - left) // 128) + 1
    Doocr.bmapheight = ((top - bottom) // 128) + 1

    # Build the blockmap starting from the bottom left
    Doocr.bmapheight.times do |y|
      Doocr.bmapwidth.times do |x|
        offsets.write_bytes (blockmap.pos // 2).to_i16!
        bstart = Raylib::Vector2.new(x: left + x * 128, y: bottom + y * 128)
        bend = Raylib::Vector2.new(x: bstart.x + 128, y: bstart.y + 128)

        Doocr.numlines.times do |lin|
          line = CDoom.lines[lin]
          v1 = Raylib::Vector2.new(
            x: line.v1.value.x >> FRACBITS,
            y: line.v1.value.y >> FRACBITS
          )
          v2 = Raylib::Vector2.new(
            x: line.v2.value.x >> FRACBITS,
            y: line.v2.value.y >> FRACBITS
          )

          if line_intersects_box?(v1, v2, bstart, bend)
            blockmap.write_bytes lin.to_i16!
          end
        end

        blockmap.write_bytes -1_i16
      end
    end

    # Load blockmap normally
    Doocr.blockmaplump = blockmap.to_slice.to_unsafe.as(Int16*)
    Doocr.blockmap = offsets.to_slice.to_unsafe.as(Int16*)

    # clear out mobj chains
    count = sizeof(CDoom::Mobj*) * Doocr.bmapwidth * Doocr.bmapheight
    CDoom.blocklinks = CDoom.z_malloc(count, CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Mobj**)
    CDoom.doom_memset(CDoom.blocklinks, 0, count)
  end
end
