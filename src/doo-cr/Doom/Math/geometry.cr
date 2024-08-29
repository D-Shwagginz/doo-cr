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
  module Geometry
    SLOPERANGE          = 2048
    SLOPEBITS           =   11
    FRAC_TO_SLOPE_SHIFT = Fixed::FRACBITS - SLOPEBITS

    private def self.slope_div(num : Fixed, den : Fixed) : UInt32
      return SLOPERANGE.to_u32 if den.data.to_u32 < 512
      ans = (num.data.to_u32 << 3) / (den.data.to_u32 >> 8)
      return ans <= SLOPERANGE ? ans.to_u32 : SLOPERANGE.to_u32
    end

    # Calculate the distance between the two points.
    def self.point_to_dist(from_x : Fixed, from_y : Fixed, to_x : Fixed, to_y : Fixed) : Fixed
      dx = (to_x - from_x).abs
      dy = (to_y - from_y).abs

      if dy > dx
        temp = dx
        dx = dy
        dy = temp
      end

      # The code below to avoid division by zero is based on Chocolate Doom's implementation.
      frac : Fixed
      if dx != Fixed.zero
        frac = dy / dx
      else
        frac = Fixed.zero
      end

      angle = Trig.tan_to_angle(frac.data.to_u32 >> FRAC_TO_SLOPE_SHIFT) + Angle.ang90

      # Use as cosine.
      dist = dx / Trig.sin(angle)

      return dist
    end

    # Calculate on which side of the node the point is.
    # returns: 0 (front) or 1 (back).
    def self.point_on_side(x : Fixed, y : Fixed, node : Node) : Int32
      if node.dx == Fixed.zero
        if x <= node.x
          return node.dy > Fixed.zero ? 1 : 0
        else
          return node.dy < Fixed.zero ? 1 : 0
        end
      end

      if node.dy == Fixed.zero
        if y <= node.y
          return node.dx < Fixed.zero ? 1 : 0
        else
          return node.dx > Fixed.zero ? 1 : 0
        end
      end

      dx = x - node.x
      dy = y - node.y

      # Try to quickly decide by looking at sign bits.
      if ((node.dy.data ^ node.dx.data ^ dx.data ^ dy.data) & 0x80000000) != 0
        if ((node.dy.data ^ dx.data) & 0x80000000) != 0
          # Left is negative.
          return 1
        end

        return 0
      end

      left = Fixed.new(node.dy.data >> Fixed::FRACBITS) * dx
      right = dy * Fixed.new(node.dx.data >> Fixed::FRACBITS)

      if right < left
        # Front side.
        return 0
      else
        # Back side.
        return 1
      end
    end

    # Calculate the angle of the line passing through the two points.
    def self.point_to_angle(from_x : Fixed, from_y : Fixed, to_x : Fixed, to_y : Fixed) : Angle
      x = to_x - from_x
      y = to_y - from_y

      return Angle.ang0 if x == Fixed.zero && y == Fixed.zero

      if x >= Fixed.zero
        # x >= 0
        if y >= Fixed.zero
          # y >= 0
          if x > y
            # octant 0
            return Trig.tan_to_angle(slope_div(y, x))
          else
            # octant 1
            return Angle.new(Angle.ang90.data - 1) - Trig.tan_to_angle(slope_div(x, y))
          end
        else
          # y < 0
          y = -y

          if x > y
            # octant 8
            return -Trig.tan_to_angle(slope_div(y, x))
          else
            # octant 7
            return Angle.ang270 + Trig.tan_to_angle(slope_div(x, y))
          end
        end
      else
        # x < 0
        x = -x

        if y >= Fixed.zero
          # y >= 0
          if x > y
            # octant 3
            return Angle.new(Angle.ang180.data - 1) - Trig.tan_to_angle(slope_div(y, x))
          else
            # octant 2
            return Angle.ang90 + Trig.tan_to_angle(slope_div(x, y))
          end
        else
          # y < 0
          y = -y

          if x > y
            # octant 4
            return Angle.ang180 + Trig.tan_to_angle(slope_div(y, x))
          else
            # octant 5
            return Angle.new(Angle.ang270.data - 1) - Trig.tan_to_angle(slope_div(x, y))
          end
        end
      end
    end

    # Get the subsector which contains the point.
    def self.point_in_subsector(x : Fixed, y : Fixed, map : Map) : Subsector
      # Single subsector is a special case.
      if map.nodes.size == 0
        return map.subsectors[0]
      end

      node_number = map.nodes.size - 1

      while !Node.is_subsector(node_number)
        node = map.nodes[node_number]
        side = point_on_side(x, y, node)
        node_number = node.children[side]
      end

      return map.subsectors[Node.get_subsector(node_number)]
    end

    # Calculate on which side of the line the point is.
    # returns: 0 (front) or 1 (back).
    def self.point_on_seg_side(x : Fixed, y : Fixed, line : Seg) : Int32
      lx = line.vertex1.as(Vertex).x
      ly = line.vertex1.as(Vertex).y

      ldx = line.vertex2.as(Vertex).x - lx
      ldy = line.vertex2.as(Vertex).y - ly

      if ldx == Fixed.zero
        if x <= lx
          return ldy > Fixed.zero ? 1 : 0
        else
          return ldy < Fixed.zero ? 1 : 0
        end
      end

      if ldy == Fixed.zero
        if y <= ly
          return ldx < Fixed.zero ? 1 : 0
        else
          return ldx > Fixed.zero ? 1 : 0
        end
      end

      dx = x - lx
      dy = y - ly

      # Try to quickly decide by looking at sign bits.
      if (((ldy.data ^ ldx.data ^ dx.data ^ dy.data) & 0x80000000) != 0)
        if (((ldy.data ^ dx.data) & 0x80000000) != 0)
          # Left is negative.
          return 1
        else
          return 0
        end
      end

      left = Fixed.new(ldy.data >> Fixed::FRACBITS) * dx
      right = dy * Fixed.new(ldx.data >> Fixed::FRACBITS)

      if right < left
        # Front side.
        return 0
      else
        # Back side.
        return 1
      end
    end

    # Calculate on which side of the line the point is.
    # returns: 0 (front) or 1 (back).
    def self.point_on_line_side(x : Fixed, y : Fixed, line : LineDef) : Int32
      if line.dx == Fixed.zero
        if x <= line.vertex1.as(Vertex).x
          return line.dy > Fixed.zero ? 1 : 0
        else
          return line.dy < Fixed.zero ? 1 : 0
        end
      end

      if line.dy == Fixed.zero
        if y <= line.vertex1.as(Vertex).y
          return line.dx < Fixed.zero ? 1 : 0
        else
          return line.dx > Fixed.zero ? 1 : 0
        end
      end

      dx = x - line.vertex1.as(Vertex).x
      dy = y - line.vertex1.as(Vertex).y

      left = Fixed.new(line.dy.data >> Fixed::FRACBITS) * dx
      right = dy * Fixed.new(line.dx.data >> Fixed::FRACBITS)

      if right < left
        # Front side.
        return 0
      else
        # Back side.
        return 1
      end
    end

    # Calculate on which side of the line the box is.
    # returns: 0 (front), 1 (back), or -1 if the box crosses the line.
    def self.box_on_line_side(box : Array(Fixed), line : LineDef) : Int32
      p1 : Int32
      p2 : Int32

      case line.slope_type
      when SlopeType::Horizontal
        p1 = box[Box::TOP] > line.vertex1.as(Vertex).y ? 1 : 0
        p2 = box[Box::BOTTOM] > line.vertex1.as(Vertex).y ? 1 : 0
        if line.dx < Fixed.zero
          p1 ^= 1
          p2 ^= 1
        end
      when SlopeType::Vertical
        p1 = box[Box::RIGHT] < line.vertex1.as(Vertex).x ? 1 : 0
        p2 = box[Box::LEFT] < line.vertex1.as(Vertex).x ? 1 : 0
        if line.dy < Fixed.zero
          p1 ^= 1
          p2 ^= 1
        end
      when SlopeType::Positive
        p1 = point_on_line_side(box[Box::LEFT], box[Box::TOP], line)
        p2 = point_on_line_side(box[Box::RIGHT], box[Box::BOTTOM], line)
      when SlopeType::Negative
        p1 = point_on_line_side(box[Box::RIGHT], box[Box::TOP], line)
        p2 = point_on_line_side(box[Box::LEFT], box[Box::BOTTOM], line)
      else
        raise "Invalide SlopeType."
      end

      if p1 == p2
        return p1
      else
        return -1
      end
    end

    # Calculate on which side of the line the point is.
    # returns: 0 (front) or 1 (back).
    def self.point_on_div_line_side(x : Fixed, y : Fixed, line : DivLine) : Int32
      if line.dx == Fixed.zero
        if x <= line.x
          return line.dy > Fixed.zero ? 1 : 0
        else
          return line.dy < Fixed.zero ? 1 : 0
        end
      end

      if line.dy == Fixed.zero
        if y <= line.y
          return line.dx < Fixed.zero ? 1 : 0
        else
          return line.dx > Fixed.zero ? 1 : 0
        end
      end

      dx = x - line.x
      dy = y - line.y

      # Try to quickly decide by looking at sign bits.
      if (((line.dy.data ^ line.dx.data ^ dx.data ^ dy.data) & 0x80000000) != 0)
        if (((line.dy.data ^ dx.data) & 0x80000000) != 0)
          # Left is negative.
          return 1
        else
          return 0
        end
      end

      left = Fixed.new(line.dy.data >> 8) * Fixed.new(dx.data >> 8)
      right = Fixed.new(dy.data >> 8) * Fixed.new(line.dx.data >> 8)

      if right < left
        # Front side.
        return 0
      else
        # Back side.
        return 1
      end
    end

    # Gives an estimation of distance (not exact).
    def self.aprox_distance(dx : Fixed, dy : Fixed) : Fixed
      dx = dx.abs
      dy = dy.abs

      if dx < dy
        return dx + dy - (dx >> 1)
      else
        return dx + dy - (dy >> 1)
      end
    end

    # Calculate on which side of the line the point is.
    # returns: 0 (front) or 1 (back), or 2 if the box crosses the line.
    def self.div_line_side(x : Fixed, y : Fixed, line : DivLine) : Int32
      if line.dx == Fixed.zero
        if x == line.x
          return 2
        end

        if x <= line.x
          return line.dy > Fixed.zero ? 1 : 0
        end

        return line.dy < Fixed.zero ? 1 : 0
      end

      if line.dy == Fixed.zero
        if x == line.y
          return 2
        end

        if y <= line.y
          return line.dx < Fixed.zero ? 1 : 0
        end

        return line.dx > Fixed.zero ? 1 : 0
      end

      dx = x - line.x
      dy = y - line.y

      left = Fixed.new((line.dy.data >> Fixed::FRACBITS) * (dx.data >> Fixed::FRACBITS))
      right = Fixed.new((dy.data >> Fixed::FRACBITS) * (line.dx.data >> Fixed::FRACBITS))

      if right < left
        # Front side.
        return 0
      end

      if left == right
        return 2
      else
        # Back side.
        return 1
      end
    end

    # Calculate on which side of the line the point is.
    # returns: 0 (front) or 1 (back), or 2 if the box crosses the line.
    def self.div_line_side(x : Fixed, y : Fixed, node : Node) : Int32
      if node.dx == Fixed.zero
        if x == node.x
          return 2
        end

        if x <= node.x
          return node.dy > Fixed.zero ? 1 : 0
        end

        return node.dy < Fixed.zero ? 1 : 0
      end

      if node.dy == Fixed.zero
        if x == node.y
          return 2
        end

        if y <= node.y
          return node.dx < Fixed.zero ? 1 : 0
        end

        return node.dx > Fixed.zero ? 1 : 0
      end

      dx = x - node.x
      dy = y - node.y

      left = Fixed.new((node.dy.data >> Fixed::FRACBITS) * (dx.data >> Fixed::FRACBITS))
      right = Fixed.new((dy.data >> Fixed::FRACBITS) * (node.dx.data >> Fixed::FRACBITS))

      if right < left
        # Front side.
        return 0
      end

      if left == right
        return 2
      else
        # Back side.
        return 1
      end
    end
  end
end
