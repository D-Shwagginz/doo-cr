module Doocr
  class MapThing
    class_getter datasize : Int32 = 10

    getter empty : MapThing = MapThing.new(
      Fixed.zero,
      Fixed.zero,
      Angle.ang0,
      0,
      0
    )

    getter x : Fixed
    getter y : Fixed
    getter angle : Angle
    property type : Int32
    getter flags : ThingFlags

    def initialize(
      @x : Fixed,
      @y : Fixed,
      @angle : Angle,
      @type : Int32,
      @flags : ThingFlags
    )
    end

    def self.from_data(data : Bytes, offset : Int32) : MapThing
      x = IO::ByteFormat::LittleEndian.decode(Int16, data[offset, 2])
      y = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 2, 2])
      angle = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 4, 2])
      type = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 6, 2])
      flags = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 8, 2])

      return MapThing.new(
        Fixed.from_int(x),
        Fixed.from_int(y),
        Angle.new(Angle.ang45.data * (angle / 45).to_u32),
        type,
        ThingFlags.new(flags)
      )
    end

    def self.from_wad(wad : Wad, lump : Int32) : Array(MapThing)
      length = wad.get_lump_size(lump)
      raise if length % @@datasize != 0

      data = wad.read_lump(lump)
      count = length / @@datasize
      things = Array(MapThing).new(count)

      count.times do |i|
        offset = @@datasize * i
        things << from_data(data, offset)
      end

      return things
    end
  end
end
