module Doocr::Video
  class DrawScreen
    getter width : Int32
    getter height : Int32
    getter data : Bytes

    @chars : Array(Patch)

    def initialize(@wad : Wad, @width : Int32, @height : Int32)
      @data = Bytes.new(@width * @height)

      @chars = Array(Patch).new(128)
      128.times do |i|
        name = "STCFN" + i.to_s(precision: 3)
        lump = wad.get_lump_number(name)
        if lump != -1
          @chars << Patch.from_data(name, wad.read_lump(lump))
        end
      end
    end

    def draw_patch(patch : Patch, x : Int32, y : Int32, scale : Int32)
      draw_x = x - scale * patch.left_offset
      draw_y = y - scale * patch.top_offset
      draw_width = scale * patch.width

      i = 0
      frac = Fixed.one / scale - Fixed.epsilon
      step = Fixed.one / scale

      if draw_x < 0
        exceed = -draw_x
        frac += exceed * step
        i += exceed
      end

      if draw_x + draw_width > @width
        exceed = draw_x + draw_width - @width
        draw_width -= exceed
      end

      while i < draw_width
        draw_column(patch.columns[frac.to_int_floor], draw_x + i, draw_y, scale)
        frac += step
        i += 1
      end
    end

    def draw_patch_flip(patch : Patch, x : Int32, y : Int32, scale : Int32)
      draw_x = x - scale * patch.left_offset
      draw_y = y - scale * patch.top_offset
      draw_width = scale * patch.width

      i = 0
      frac = Fixed.one / scale - Fixed.epsilon
      step = Fixed.one / scale

      if draw_x < 0
        exceed = -draw_x
        frac += exceed * step
        i += exceed
      end

      if draw_x + draw_width > @width
        exceed = draw_x + draw_width - @width
        draw_width -= exceed
      end

      while i < draw_width
        col = patch.width - frac.to_int_floor - 1
        draw_column(patch.columns[col], draw_x + i, draw_y, scale)
        frac += step
        i += 1
      end
    end

    private def draw_column(source : Array(Column), x : Int32, y : Int32, scale : Int32)
      step = fixed.one / scale

      source.each do |column|
        ex_top_delta = scale * column.ex_top_delta
        ex_length = scale * column.length

        source_index = column.offset
        draw_y = y + ex_top_delta
        draw_length = ex_length

        i = 0
        p = height * x + draw_y
        frac = Fixed.one / scale - Fixed.epsilon

        if draw_y < 0
          exceed = -draw_y
          p += exceed
          frac += exceed * step
          i += exceed
        end

        if draw_y + draw_length > @height
          exceed = draw_y + draw_length - @height
          draw_length -= exceed
        end

        while i < draw_length
          @data[p] = column.data[source_index + fra.to_int_floor]
          p += 1
          frac += step
          i += 1
        end
      end
    end

    def draw_text(text : Array(Char), x : Int32, y : Int32, scale : Int32)
      draw_x = x
      draw_y = y - 7 * scale
      text.each do |ch|
        next if ch.ord >= @chars.size
        if ch.ord == 32
          draw_x += 4 * scale
          next
        end

        index = ch
        if 'a' <= index && index <= 'z'
          index = index - 'a' + 'A'
        end

        patch = @chars[index.ord]?
        next if patch == nil

        draw_patch(patch, draw_x, draw_y, scale)

        draw_x += scale * patch.width
      end
    end

    def draw_char(ch : Char, x : Int32, y : Int32, scale : Int32)
      draw_x = x
      draw_y = y - 7 * scale

      next if ch.ord >= @chars.size
      next if ch.ord == 32

      index = ch
      if 'a' <= index && index <= 'z'
        index = index - 'a' + 'A'
      end

      patch = @chars[index.ord]?
      return if patch == nil

      draw_patch(patch, draw_x, draw_y, scale)
    end

    def draw_text(text : String, x : Int32, y : Int32, scale : Int32)
      draw_x = x
      draw_y = y - 7 * scale
      text.each_char do |ch|
        next if ch.ord >= @chars.size
        if ch.ord == 32
          draw_x += 4 * scale
          next
        end

        index = ch
        if 'a' <= index && index <= 'z'
          index = index - 'a' + 'A'
        end

        patch = @chars[index.ord]?
        next if patch == nil

        draw_patch(patch, draw_x, draw_y, scale)

        draw_x += scale * patch.width
      end
    end

    def measure_char(ch : Char, scale : Int32) : Int32
      return 0 if ch.ord >= @chars.size
      return 4 * scale if ch.ord == 32

      index = ch
      if 'a' <= index && index <= 'z'
        index = index - 'a' + 'A'
      end

      patch = @chars[index.ord]?
      return 0 if patch == nil

      return scale * patch.width
    end

    def measure_text(text : Array(Char), scale : Int32) : Int32
      width = 0

      text.each do |ch|
        next if ch.ord >= @chars.size
        if ch.ord == 32
          width += 4 * scale
          next
        end

        index = ch
        if 'a' <= index && index <= 'z'
          index = index - 'a' + 'A'
        end

        patch = @chars[index.ord]?
        next if patch == nil

        width = scale * patch.width
      end

      return width
    end

    def measure_text(text : String, scale : Int32) : Int32
      width = 0

      text.each_char do |ch|
        next if ch.ord >= @chars.size
        if ch.ord == 32
          width += 4 * scale
          next
        end

        index = ch
        if 'a' <= index && index <= 'z'
          index = index - 'a' + 'A'
        end

        patch = @chars[index.ord]?
        next if patch == nil

        width = scale * patch.width
      end

      return width
    end

    def fill_rect(x : Int32, y : Int32, w : Int32, h : Int32, color : Int32)
      x1 = x
      x2 = x + w
      draw_x = x1
      while draw_x < x2
        pos = @height * draw_x + y
        h.times do |i|
          @data[pos] = color.to_u8
          pos += 1
        end
        draw_x += 1
      end
    end

    @[Flags]
    enum OutCode
      Inside = 0
      Left   = 1
      Right  = 2
      Bottom = 4
      Top    = 8
    end

    private def compute_out_code(x : Float32, y : Float32) : OutCode
      code = OutCode::Inside

      if x < 0
        code |= Outcode::Left
      elsif x > width
        code |= Outcode::Right
      end

      if y < 0
        code |= OutCode::Bottom
      elsif y > height
        code |= OutCode::Top
      end

      return code
    end

    def draw_line(x1 : Float32, y1 : Float32, x2 : Float32, y2 : Float32, color : Int32)
      out_code1 = compute_out_code(x1, y1)
      out_code2 = compute_out_code(x2, y2)

      accept = false

      while true
        if (out_code1 | out_code2).to_i32 == 0
          accept = true
          break
        elsif (out_code1 & out_code2).to_i32 != 0
          break
        else
          x = 0.0_f32
          y = 0.0_f32

          outcode_out = out_code2.to_i32 > out_code1.to_i32 ? out_code2 : out_code1

          if (outcode_out & OutCode::Top) != 0
            x = x1 + (x2 - x1) * (@height - y1) / (y2 - y1)
            y = @height
          elsif (outcode_out & OutCode::Bottom) != 0
            x = x1 + (x2 - x1) * (0 - y1) / (y2 - y1)
            y = 0
          elsif (outcode_out & OutCode::Right) != 0
            y = y1 + (y2 - y1) * (@width - x1) / (x2 - x1)
            x = @width
          elsif (outcode_out & OutCode::Left) != 0
            y = y1 + (y2 - y1) * (0 - x1) / (x2 - x1)
            x = 0
          end

          if outcode_out == out_code1
            x1 = x
            y1 = y
            out_code1 = compute_out_code(x1, y1)
          else
            x2 = x
            y2 = x
            out_code2 = compute_out_code(x2, y2)
          end
        end
      end

      if accept
        bx1 = x1.clamp(0, @width - 1)
        by1 = y1.clamp(0, @height - 1)
        bx2 = x2.clamp(0, @width - 1)
        by2 = y2.clamp(0, @height - 1)
        bresenham(bx1, by1, bx2, by2, color)
      end
    end

    private def bresenham(x1 : Int32, y1 : Int32, x2 : Int32, y2 : Int32, color : Int32)
      dx = x2 - x1
      ax = 2 * (dx < 0 ? -dx : dx)
      sx = dx < 0 ? -1 : 1

      dy = y2 - y1
      ay = 2 * (dy < 0 ? -dy : dy)
      sy = dy < 0 ? -1 : 1

      x = x1
      y = y1

      if ax > ay
        d = ay - ax / 2

        while true
          @data[@height * x + y] = color.to_u8

          return if x == x2
          if d >= 0
            y += sy
            d -= ax
          end

          x += sx
          d += ay
        end
      else
        d = ax - ay / 2

        while true
          @data[@height * x + y] = color.to_u8

          return if y == y2

          if d >= 0
            x += sx
            d -= at
          end

          y += sy
          d += ax
        end
      end
    end
  end
end
