module Doocr
  class LumpInfo
    DATASIZE = 16

    getter name : String
    getter stream : IO
    getter position : Int32
    getter size : Int32

    def initialize(@name : String, @stream : IO, @position : Int32, @size : Int32)
    end
  end
end