module Doocr
  class Patch
    getter name : String
    getter width : Int32
    getter height : Int32
    getter left_offset : Int32
    getter top_offset : Int32
    getter columns : Array(Array(Column))

    def to_s
      return @name
    end

    def initialize(
      @name : String,
      @width : Int32,
      @height : Int32,
      @left_offset : Int32,
      @top_offset : Int32,
      @columns : Array(Array(Column))
    )
    end

    def self.from_data(name : String, data : Bytes) : Patch
      width = IO::ByteFormat::LittleEndian.decode(Int16, data[0, 2])
      height = IO::ByteFormat::LittleEndian.decode(Int16, data[2, 2])
      left_offset = IO::ByteFormat::LittleEndian.decode(Int16, data[4, 2])
      top_offset = IO::ByteFormat::LittleEndian.decode(Int16, data[6, 2])

      data = pad_data(data, width)

      columns = Array.new(width, [] of Column)
      width.times do |x|
        cs = [] of Column
        p = IO::ByteFormat::LittleEndian.decode(Int32, data[8 + 4 * x, 4])
        while true
          top_delta = data[p]
          break if top_delta == Column::LAST
          length = data[p + 1]
          offset = p + 3
          cs << Column.new(top_delta, data, offset, length)
          p += length + 4
        end
        columns[x] = cs
      end

      return Patch.new(
        name,
        width,
        height,
        left_offset,
        top_offset,
        columns
      )
    end

    def self.from_wad(wad : Wad, name : String)
      return from_data(name, wad.read_lump(name))
    end

    private def pad_data(data : Bytes, width : Int) : Bytes
      need = 0
      width.times do |x|
        p = IO::ByteFormat::LittleEndian.decode(Int32, data[8 + 4 * x, 4])
        while true
          top_delta = data[p]
          break if top_delta == Column::LAST
          length = data[p + 1]
          offset = p + 3
          need = offset + 128 > need ? offset + 128 : need
          p += length + 4
        end
      end

      if data.size < need
        data = data + Bytes.new(need - data.size)
      end
      return data
    end
  end
end