module Doocr
  class Subsector
    class_getter datasize : Int32 = 4

    getter sector : Sector
    getter seg_count : Int32
    getter first_seg : Int32

    def initialize(@sector : Sector, @seg_count : Int32, @first_seg : Int32)
    end

    def self.from_data(data : Bytes, offset : Int32, segs : Array(Seg)) : Subsector
      seg_count = IO::ByteFormat::LittleEndian.decode(Int16, data[offset, 2])
      first_seg_number = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 2, 2])

      return Subsector.new(
        segs[first_seg_number].side_def.sector,
        seg_count,
        first_seg_number
      )
    end

    def self.from_wad(wad : Wad, lump : Int32, segs : Array(Seg)) : Array(Subsector)
      length = wad.get_lump_size(lump)
      raise if length % @@datasize != 0

      data = wad.read_lump(lump)
      count = length / @@datasize
      subsectors = Array(Subsector).new(count)

      count.times do |i|
        offset = @@datasize * i
        subsectors << from_data(data, offset, segs)
      end

      return subsectors
    end
  end
end
