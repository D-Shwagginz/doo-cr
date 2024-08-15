module Doocr
  class ColorMap
    class_getter inverse : Int32 = 32

    @data : Array(Array(UInt8))

    def [](index : Int)
      return @data[index]
    end

    def full_bright : Array(UInt8)
      return @data[0]
    end

    def initialize(wad : Wad)
      begin
        print("Load color map: ")

        raw = wad.read_lump("COLORMAP")
        num = raw.size / 256
        @data = Array.new(num, [] of UInt8)
        num.times do |i|
          @data[i] = Array(UInt8).new(256)
          offset = 256 * i
          256.times do |c|
            @data[i][c] = raw[offset + c]
          end
        end

        puts("OK")
      rescue e
        puts("Failed")
        raise e
      end
    end
  end
end
