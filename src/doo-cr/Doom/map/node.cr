module Doocr
  class Node
    class_getter datasize : Int32 = 28

    getter x : Fixed
    getter y : Fixed
    getter dx : Fixed
    getter dy : Fixed

    getter bounding_box : Array(Array(Fixed))

    getter children : Array(Int32)

    def initialize(
      @x : Fixed,
      @y : Fixed,
      @dx : Fixed,
      @dy : Fixed,
      front_bounding_box_top : Fixed,
      front_bounding_box_bottom : Fixed,
      front_bounding_box_left : Fixed,
      front_bounding_box_right : Fixed,
      back_bounding_box_top : Fixed,
      back_bounding_box_bottom : Fixed,
      back_bounding_box_left : Fixed,
      back_bounding_box_right : Fixed,
      front_child : Int32,
      back_child : Int32
    )
      front_bounding_box = [
        front_bounding_box_top,
        front_bounding_box_bottom,
        front_bounding_box_left,
        front_bounding_box_right,
      ]

      back_bounding_box = [
        back_bounding_box_top,
        back_bounding_box_bottom,
        back_bounding_box_left,
        back_bounding_box_right,
      ]

      @bounding_box = [
        front_bounding_box,
        back_bounding_box,
      ]

      @children = [
        front_child,
        back_child,
      ]
    end

    def self.from_data(data : Bytes, offset : Int32) : Node
      x = IO::ByteFormat::LittleEndian.decode(Int16, data[offset, 2])
      y = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 2, 2])
      dx = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 4, 2])
      dy = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 6, 2])
      front_bounding_box_top = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 8, 2])
      front_bounding_box_bottom = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 10, 2])
      front_bounding_box_left = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 12, 2])
      front_bounding_box_right = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 14, 2])
      back_bounding_box_top = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 16, 2])
      back_bounding_box_bottom = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 18, 2])
      back_bounding_box_left = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 20, 2])
      back_bounding_box_right = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 22, 2])
      front_child = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 24, 2])
      back_child = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 26, 2])

      return Node.new(
        Fixed.from_int(x),
        Fixed.from_int(y),
        Fixed.from_int(dx),
        Fixed.from_int(dy),
        Fixed.from_int(front_bounding_box_top),
        Fixed.from_int(front_bounding_box_bottom),
        Fixed.from_int(front_bounding_box_left),
        Fixed.from_int(front_bounding_box_right),
        Fixed.from_int(back_bounding_box_top),
        Fixed.from_int(back_bounding_box_bottom),
        Fixed.from_int(back_bounding_box_left),
        Fixed.from_int(back_bounding_box_right),
        front_child,
        back_child
      )
    end

    def self.from_wad(wad : Wad, lump : Int32, subsectors : Array(Subsector)) : Array(Node)
      length = wad.get_lump_size(lump)
      raise if length % @@datasize != 0

      data = wad.read_lump(lump)
      count = length / @@datasize
      nodes = Array(Node).new(count)

      count.times do |i|
        offset = @@datasize * i
        nodes << from_data(data, offset)
      end

      return nodes
    end

    def is_subsector(node : Int32) : Bool
      return (node & 0xFFFF8000) != 0
    end

    def get_subsector(node : Int32) : Int32
      return node ^ 0xFFFF8000
    end
  end
end