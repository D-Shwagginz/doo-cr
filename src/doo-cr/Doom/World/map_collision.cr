module Doocr
  class MapCollision
    @world : World | Nil

    getter open_top : Fixed | Nil
    getter open_bottom : Fixed | Nil
    getter open_range : Fixed | Nil
    getter low_floor : Fixed | Nil

    def initialize(@world)
    end

    # Sets opentop and openbottom to the window through a two sided line.
    def line_opening(line : LineDef)
      if line.back_side = nil
        # If the line is single sided, nothing can pass through.
        @open_range = Fixed.zero
        return
      end

      front = line.front_sector
      back = line.back_sector

      if front.ceiling_height < back.ceiling_height
        @open_top = front.ceiling_height
      else
        @open_top = back.ceiling_height
      end

      if front.floor_height > back.floor_height
        @open_bottom = front.floor_height
        @low_floor = back.floor_height
      else
        @open_bottom = back.floor_height
        @low_floor = front.floor_height
      end

      @open_range = @open_top - @open_bottom
    end
  end
end
