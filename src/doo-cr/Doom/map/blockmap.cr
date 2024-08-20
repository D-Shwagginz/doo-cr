module Doocr
  class BlockMap
    class_getter int_block_size : Int32 = 128
    class_getter block_size : Fixed = Fixed.from_i(@@int_block_size)
    class_getter block_mask : Int32 = @@block_size.data - 1
    class_getter frac_to_block_shift = Fixed::FRACBITS + 7
    class_getter block_to_frac_shift = @@frac_to_block_shift - Fixed::FRACBITS

    getter origin_x : Fixed
    getter origin_y : Fixed

    getter width : Int32
    getter height : Int32

    @table : Array(Int16)

    @lines : Array(LineDef)
    getter thing_lists : Array(Mobj)

    private def initialize(
      @origin_x : Fixed,
      @origin_y : Fixed,
      @width : Int32,
      @height : Int32,
      @table : Array(Int16),
      @lines : Array(LineDef)
    )
      @thing_lists = Array(Mobj).new(width * height)
    end

    def self.from_wad(wad : Wad, lump : Int32, lines : Array(LineDef)) : BlockMap
      data = wad.read_lump(lump)

      table = Array(Int16).new(data.size / 2)
      (data.size / 2).times do |i|
        offset = 2 * i
        table << IO::ByteFormat::LittleEndian.decode(Int16, data[offset, 2])
      end

      origin_x = Fixed.from_i(table[0])
      origin_y = Fixed.from_i(table[1])
      width = table[2]
      height = table[3]

      return BlockMap.new(
        origin_x,
        origin_y,
        width,
        height,
        table,
        lines
      )
    end

    def get_block_x(x : Fixed) : Int32
      return (x - @origin_x).data >> @@frac_to_block_shift
    end

    def get_block_y(y : Fixed) : Int32
      return (y - @origin_y).data >> @@frac_to_block_shift
    end

    def get_index(block_x : Int32, block_y : Int32) : Int32
      if 0 <= block_x && block_x < @width && 0 <= block_y && block_y < @height
        return @width * block_y + block_x
      else
        return -1
      end
    end

    def get_index(x : Fixed, y : Fixed) : Int32
      block_x = get_block_x(x)
      block_y = get_block_y
      return get_index(block_x, block_y)
    end

    def iterate_lines(block_x : Int32, block_y : Int32, proc : Proc(LineDef, Bool), valid_count : Int32) : Bool
      index = get_index(block_x, block_y)

      return true if index == -1

      offset = @table[4 + index]?
      while offset != nil && @table[offset]? != nil && @table[offset] != -1
        line = @lines[@table[offset]]

        if line.valid_count == valid_count
          offset += 1
          next
        end

        line.valid_count = valid_count

        if !proc(line)
          return false
        end

        offset += 1
      end

      return true
    end

    def iterate_things(block_x : Int32, block_y : Int32, proc : Proc(Mobj, Bool)) : Bool
      index = get_index(block_x, block_y)

      return true if index == -1

      mobj = @thing_lists[index]?
      while mobj != nil
        if !func(mobj)
          return false
        end

        mobj = mobj.block_next
      end

      return true
    end
  end
end
