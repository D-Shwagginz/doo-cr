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
  class PathTraversal
    @world : World | Nil = nil

    @intercepts : Array(Intercept) = [] of Intercept
    @intercept_count : Int32 = 0

    @early_out : Bool = false

    @target : DivLine | Nil = nil
    getter trace : DivLine | Nil = nil

    @line_intercept_func : Proc(LineDef, Bool) | Nil = nil
    @thing_intercept_func : Proc(Mobj, Bool) | Nil = nil

    def initialize(@world)
      @intercepts = Array(Intercept).new(256)
      256.times do |i|
        @intercepts << Intercept.new
      end

      @target = DivLine.new
      @trace = DivLine.new

      @line_intercept_func = ->add_line_intercepts(LineDef)
      @thing_intercept_func = ->add_thing_intercepts(Mobj)
    end

    # Looks for lines in the given block that intercept the given trace
    # to add to the intercepts list.
    # A line is crossed if its endpoints are on opposite sidesof the trace.
    # Returns true if earlyOut and a solid line hit.
    private def add_line_intercepts(line : LineDef) : Bool
      s1 : Int32 = 0
      s2 : Int32 = 0

      # Avoid precision problems with two routines.
      if (@trace.as(DivLine).dx > Fixed.from_i(16) ||
         @trace.as(DivLine).dy > Fixed.from_i(16) ||
         @trace.as(DivLine).dx < -Fixed.from_i(16) ||
         @trace.as(DivLine).dy < -Fixed.from_i(16))
        s1 = Geometry.point_on_div_line_side(line.vertex1.as(Vertex).x, line.vertex1.as(Vertex).y, @trace.as(DivLine))
        s2 = Geometry.point_on_div_line_side(line.vertex2.as(Vertex).x, line.vertex2.as(Vertex).y, @trace.as(DivLine))
      else
        s1 = Geometry.point_on_line_side(@trace.as(DivLine).x, @trace.as(DivLine).y, line)
        s2 = Geometry.point_on_line_side(@trace.as(DivLine).x + @trace.as(DivLine).dx, @trace.as(DivLine).y + @trace.as(DivLine).dy, line)
      end

      if s1 == s2
        # Line isn't crossed
        return true
      end

      # Hit the line
      @target.as(DivLine).make_from(line)

      frac = intercept_vector(@trace.as(DivLine), @target.as(DivLine))

      if frac < Fixed.zero
        # Behind source.
        return true
      end

      # Try to early out the check.
      if @early_out && frac < Fixed.one && line.back_sector == nil
        # Stop checking.
        return false
      end

      @intercepts[@intercept_count].make(frac, line)
      @intercept_count += 1

      # Continue.
      return true
    end

    # Looks for things that intercept the given trace.
    private def add_thing_intercepts(thing : Mobj) : Bool
      trace_positive = (@trace.as(DivLine).dx.data ^ @trace.as(DivLine).dy.data) > 0

      x1 : Fixed
      y1 : Fixed
      x2 : Fixed
      y2 : Fixed

      # Check a corner to corner crossection for hit.
      if trace_positive
        x1 = thing.x - thing.radius
        y1 = thing.y + thing.radius

        x2 = thing.x + thing.radius
        y2 = thing.y - thing.radius
      else
        x1 = thing.x - thing.radius
        y1 = thing.y - thing.radius

        x2 = thing.x + thing.radius
        y2 = thing.y + thing.radius
      end

      s1 = Geometry.point_on_div_line_side(x1, y1, @trace.as(DivLine))
      s2 = Geometry.point_on_div_line_side(x2, y2, @trace.as(DivLine))

      if s1 == s2
        # Line isn't crossed.
        return true
      end

      @target.as(DivLine).x = x1
      @target.as(DivLine).y = y1
      @target.as(DivLine).dx = x2 - x1
      @target.as(DivLine).dy = y2 - y1

      frac = intercept_vector(@trace.as(DivLine), @target.as(DivLine))

      if frac < Fixed.zero
        # Behind source.
        return true
      end

      @intercepts[@intercept_count].make(frac, thing)
      @intercept_count += 1

      # Keep going.
      return true
    end

    # Returns the fractional intercept point along the first divline.
    # This is only called by the addthings and addlines traversers.
    private def intercept_vector(v2 : DivLine, v1 : DivLine) : Fixed
      den = (v1.dy >> 8) * v2.dx - (v1.dx >> 8) * v2.dy

      return Fixed.zero if den == Fixed.zero

      num = ((v1.x - v2.x) >> 8) * v1.dy + ((v2.y - v1.y) >> 8) * v1.dx

      frac = num / den

      return frac
    end

    # Returns true if the traverser function returns true for all lines.
    private def traverse_intercepts(func : Proc(Intercept, Bool), max_frac : Fixed) : Bool
      count = @intercept_count

      intercept : Intercept | Nil = nil

      while count > 0
        count -= 1

        dist = Fixed.max_value
        @intercept_count.times do |i|
          if @intercepts[i].frac < dist
            dist = @intercepts[i].frac
            intercept = @intercepts[i]
          end
        end

        if dist > max_frac
          # Checked everything in range.
          return true
        end

        if !func.call(intercept.as(Intercept))
          # Don't bother going farther.
          return false
        end

        intercept.as(Intercept).frac = Fixed.max_value
      end

      # Everything was traversed.
      return true
    end

    # Traces a line from x1, y1 to x2, y2, calling the traverser function for each.
    # Returns true if the traverser function returns true for all lines.
    def path_traverse(x1 : Fixed, y1 : Fixed, x2 : Fixed, y2 : Fixed, flags : PathTraverseFlags, trav : Proc(Intercept, Bool)) : Bool
      @early_out = (flags & PathTraverseFlags::EarlyOut).to_i32 != 0

      valid_count = @world.as(World).get_new_valid_count

      bm = @world.as(World).map.as(Map).blockmap.as(BlockMap)

      @intercept_count = 0

      if ((x1 - bm.origin_x).data & (BlockMap.block_size.data - 1)) == 0
        # Don't side exactly on a line.
        x1 += Fixed.one
      end

      if ((y1 - bm.origin_y).data & (BlockMap.block_size.data - 1)) == 0
        # Don't side exactly on a line.
        y1 += Fixed.one
      end

      @trace.as(DivLine).x = x1
      @trace.as(DivLine).y = y1
      @trace.as(DivLine).dx = x2 - x1
      @trace.as(DivLine).dy = y2 - y1

      x1 -= bm.origin_x
      y1 -= bm.origin_y

      block_x1 = x1.data >> BlockMap.frac_to_block_shift
      block_y1 = y1.data >> BlockMap.frac_to_block_shift

      x2 -= bm.origin_x
      y2 -= bm.origin_y

      block_x2 = x2.data >> BlockMap.frac_to_block_shift
      block_y2 = y2.data >> BlockMap.frac_to_block_shift

      step_x : Fixed
      step_y : Fixed

      partial : Fixed

      block_step_x : Int32 = 0
      block_step_y : Int32 = 0

      if block_x2 > block_x1
        block_step_x = 1
        partial = Fixed.new(Fixed::FRAC_UNIT - ((x1.data >> BlockMap.block_to_frac_shift) & (Fixed::FRAC_UNIT - 1)))
        step_y = (y2 - y1) / (x2 - x1).abs
      elsif block_x2 < block_x1
        block_step_x = -1
        partial = Fixed.new((x1.data >> BlockMap.block_to_frac_shift) & (Fixed::FRAC_UNIT - 1))
        step_y = (y2 - y1) / (x2 - x1).abs
      else
        block_step_x = 0
        partial = Fixed.one
        step_y = Fixed.from_i(256)
      end

      intercept_y = Fixed.new(y1.data >> BlockMap.block_to_frac_shift) + (partial * step_y)

      if block_y2 > block_y1
        block_step_y = 1
        partial = Fixed.new(Fixed::FRAC_UNIT - ((y1.data >> BlockMap.block_to_frac_shift) & (Fixed::FRAC_UNIT - 1)))
        step_x = (x2 - x1) / (y2 - y1).abs
      elsif block_y2 < block_y1
        block_step_y = -1
        partial = Fixed.new((y1.data >> BlockMap.block_to_frac_shift) & (Fixed::FRAC_UNIT - 1))
        step_x = (x2 - x1) / (y2 - y1).abs
      else
        block_step_y = 0
        partial = Fixed.one
        step_x = Fixed.from_i(256)
      end

      intercept_x = Fixed.new(x1.data >> BlockMap.block_to_frac_shift) + (partial * step_x)

      # Step through map blocks.
      # Count is present to prevent a round off error from skipping the break.
      bx = block_x1
      by = block_y1

      64.times do |count|
        if (flags & PathTraverseFlags::AddLines).to_i32 != 0
          if !bm.iterate_lines(bx, by, @line_intercept_func.as(Proc(LineDef, Bool)), valid_count)
            # Early out.
            return false
          end
        end

        if (flags & PathTraverseFlags::AddThings).to_i32 != 0
          if !bm.iterate_things(bx, by, @thing_intercept_func.as(Proc(Mobj, Bool)))
            # Early out.
            return false
          end
        end

        break if bx == block_x2 && by == block_y2

        if intercept_y.to_i_floor == by
          intercept_y += step_y
          bx += block_step_x
        elsif intercept_x.to_i_floor == bx
          intercept_x += step_x
          by += block_step_y
        end
      end

      # Go through the sorted list.
      return traverse_intercepts(trav, Fixed.one)
    end
  end
end
