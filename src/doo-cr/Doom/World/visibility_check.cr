module Doocr
  class VisibilityCheck
    @world : World | Nil

    # Eye z of looker.
    @sight_z_start : Fixed | Nil
    @bottom_slope : Fixed | Nil
    @top_slope : Fixed | Nil

    # From looker to target.
    @trace : DivLine | Nil
    @target_x : Fixed | Nil
    @target_y : Fixed | Nil

    @occluder : DivLine | Nil

    def initialize(@world)
      @trace = DivLine.new
      @occluder = DivLine.new
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

    # Returns true if strace crosses the given subsector successfully.
    private def cross_subsector(subsector_number : Int32, valid_count : Int32) : Bool
      map = @world.map
      subsector = @map.subsectors[subsector_number]
      count = subsector.seg_count

      # Check lines.
      count.times do |i|
        seg = map.segs[subsector.first_seg + i]
        line = seg.line_def

        # Already checked other side?
        next if line.valid_count == valid_count

        line.valid_count = valid_count

        v1 = line.vertex1
        v2 = line.vertex2
        s1 = Geometry.div_line_side(v1.x, v1.y, @trace)
        s2 = Geometry.div_line_side(v2.x, v2.y, @trace)

        # Line isn't crossed?
        next if s1 == s2

        @occluder.make_from(line)
        s1 = Geometry.div_line_side(@trace.x, @trace.y, @occluder)
        s2 = Geometry.div_line_side(@target_x, @target_y, @occluder)

        # Line isn't crossed?
        next if s1 == s2

        # The check below is imported from Chocolate Doom to
        # avoid crash due to two-sided lines with no backsector.
        return false if line.back_sector == nil

        # Stop because it is not two sided anyway.
        # Might do this after updating validcount?
        return false if (line.flags & LineFlags::TwoSided) == 0

        # Crosses a two sided line.
        front = seg.front_sector
        back = seg.back_sector

        # No wall to block sight with?
        if (front.floor_height == back.floor_height &&
           front.ceiling_height == back.ceiling_height)
          next
        end

        # Possible occluder because of ceiling height differences.
        open_top : Fixed
        if front.ceiling_height < back.ceiling_height
          open_top = front.ceiling_height
        else
          open_top = back.ceiling_height
        end

        # Because of ceiling height differences.
        open_bottom : Fixed
        if front.floor_height > back.floor_height
          open_bottom = front.floor_height
        else
          open_bottom = back.floor_height
        end

        # Quick test for totally closed doors.
        if open_bottom >= open_top
          # Stop.
          return false
        end

        frac = intercept_vector(@trace, @occluder)

        if front.floor_height != back.floor_height
          slope = (open_bottom - @sight_z_start) / frac
          @bottom_slope = slope if slope > @bottom_slope
        end

        if front.ceiling_height != back.ceiling_height
          slope = (open_top - @sight_z_start) / frac
          @top_slope = slope if slope < @top_slope
        end

        if @top_slope <= @bottom_slope
          # Stop.
          return false
        end
      end

      # Passed the subsector ok.
      return true
    end

    # Returns true if strace crosses the given node successfully.
    private def cross_bsp_node(node_number : Int32, valid_count : Int32) : Bool
      if Node.is_subsector(node_number)
        if node_number == -1
          return cross_subsector(0, valid_count)
        else
          return cross_subsector(Node.get_subsector(node_number), valid_count)
        end
      end

      node = @world.map.nodes[node_number]

      # Decide which side the start point is on.
      side = Geometry.div_line_side(@trace.x, @trace.y, node)
      if side == 2
        # An "on" should cross both sides.
        side = 0
      end

      # Cross the starting side
      return false if !cross_bsp_node(node.children[side], valid_count)

      # The partition plane is crossed here.
      if side == Geometry.div_line_side(@target_x, @target_y, node)
        # The line doesn't touch the other side.
        return true
      end

      # Cross the ending side.
      return cross_bsp_node(node.children[side ^ 1], valid_count)
    end

    # Returns true if a straight line between the looker and target is unobstructed.
    def check_sight(looker : Mobj, target : Mobj) : Bool
      map = @world.map

      # First check for trivial rejection.
      # Check in REJECT table.
      if map.reject.check(looker.subsector.sector, target.subsector.sector)
        # Can't possibly be connected.
        return false
      end

      # An unobstructed LOS is possible.
      # Now look from eyes of t1 to any part of t2.

      @sight_z_start = looker.z + looker.height - (looker.height >> 2)
      @top_slope = target.z + target.height - @sight_z_start
      @bottom_slope = target.z - @sight_z_start

      @trace.x = looker.x
      @trace.y = looker.y
      @trace.dx = target.x - looker.x
      @trace.dy = target.y - looker.y

      @target_x = target.x
      @target_y = target.y

      # The head node is the last node output.
      return cross_bsp_node(map.nodes.length - 1, @world.get_new_valid_count)
    end
  end
end
