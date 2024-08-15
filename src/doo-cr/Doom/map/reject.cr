module Doocr
  class Reject
    @data : Bytes

    @sector_count : Int32

    private def initialize(data : Bytes, sector_count : Int32)
      # If the reject table is too small, expand it to avoid crash.
      # https://doomwiki.org/wiki/Reject#Reject_Overflow
      expected_length = (sector_count * sector_count + 7) / 8
      if data.size < expected_length
        data += Bytes.new(expected_length - data.size)
      end

      @data = data
      @sector_count = sector_count
    end

    def self.from_wad(wad : Wad, lump : Int32, sectors : Array(Sector)) : Reject
      return Reject.new(wad.read_lump(lump), sectors.size)
    end

    def check(sector1 : Sector, sector2 : Sector2) : Bool
      s1 = sector1.number
      s2 = sector2.number

      p = s1 * sector_count + s2
      byte_index = p >> 3
      bit_index = 1 << (p & 7)

      return (@data[byte_index] & bit_index) != 0
    end
  end
end
