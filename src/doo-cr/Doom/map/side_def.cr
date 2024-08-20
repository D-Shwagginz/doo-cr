module Doocr
  class SideDef
    class_getter datasize : Int32 = 30

    property texture_offset : Fixed
    property row_offset : Fixed
    property top_texture : Int32
    property bottom_texture : Int32
    property middle_texture : Int32
    getter sector : Sector | Nil

    def initialize(
      @texture_offset : Fixed,
      @row_offset : Fixed,
      @top_texture : Int32,
      @bottom_texture : Int32,
      @middle_texture : Int32,
      @sector : Sector | Nil
    )
    end

    def self.from_data(data : Bytes, offset : Int32, texture : ITextureLookup, sector : Sector) : SideDef
      texture_offset = IO::ByteFormat::LittleEndian.decode(Int16, data[offset, 2])
      row_offset = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 2, 2])
      top_texture_name = String.new(data[offset + 4, 8])
      bottom_texture_name = String.new(data[offset + 12, 8])
      middle_texture_name = String.new(data[offset + 20, 8])
      sector_num = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 28, 2])

      return SideDef.new(
        Fixed.from_i(texture_offset),
        Fixed.from_i(row_offset),
        textures.get_number(top_texture_name),
        textures.get_number(bottom_texture_name),
        textures.get_number(middle_texture_name),
        sector_num != -1 ? sectors[sector_num] : nil
      )
    end

    def self.from_wad(wad : Wad, lump : Int32, textures : ITextureLookup, sectors : Array(Sector)) : Array(SideDef)
      length = wad.get_lump_size(lump)
      raise if length % @@datasize != 0

      data = wad.read_lump(lump)
      count = length / @@datasize
      sides = Array(SideDef).new(count)

      count.times do |i|
        offset = @@datasize * i
        sides << from_data(data, offset, textures, sectors)
      end

      return sides
    end
  end
end
