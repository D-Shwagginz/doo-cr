module Doocr
  class TexturePatch
    DATASIZE = 10

    getter origin_x : Int32
    getter origin_y : Int32
    @patch : Patch

    def name : String
      return @patch.name
    end

    def width : Int
      return @patch.width
    end

    def height : Int
      return @patch.height
    end

    def columns : Array(Array(Column))
      return @patch.columns
    end

    def initialize(@origin_x : Int32, @origin_y : Int32, @patch : Patch)
    end

    def self.from_data(data : Bytes, offset : Int, patches : Array(Patch)) : TexturePatch
      origin_x = IO::ByteFormat::LittleEndian.decode(Int16, data[offset, 2])
      origin_y = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 2, 2])
      patch_num = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 4, 2])

      return TexturePatch.new(origin_x, origin_y, patches[patch_num])
    end
  end
end
