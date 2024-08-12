module Doocr
  class Column
    LAST = 0xff

    getter top_delta : Int32
    getter data : Bytes
    getter offset : Int32
    getter length : Int32

    def initialize(
      @top_delta : Int32,
      @data : Bytes,
      @offset : Int32,
      @length : Int32
    )
    end
  end
end
