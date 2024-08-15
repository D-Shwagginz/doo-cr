module Doocr
  class Vertex
    class_getter datasize : Int32 = 4

    getter x : Fixed
    getter y : Fixed

    def initialize(@x : Fixed, @y : Fixed)
    end

    def self.from_data(data : Bytes, offset : Int32) : Vertex
      x = IO::ByteFormat::LittleEndian.decode(Int16, data[offset, 2])
      y = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 2, 2])

      return Vertex.new(Fixed.from_int(x), Fixed.from_int(y))
    end

    def self.from_wad(wad : Wad, lump : Int32) : Array(Vertex)
      length = wad.get_lump_size(lump)
      raise if length % @@datasize != 0

      data = wad.read_lump(lump)
      count = length / @@datasize
      vertices = Array(Vertex).new(count)

      count.times do |i|
        offset = @@datasize * i
        vertices << from_data(data, offset)
      end

      return vertices
    end
  end
end
