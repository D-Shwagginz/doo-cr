module Doocr
  class Flat
    getter name : String | Nil
    getter data : Bytes = Bytes.new(0)

    def to_s
      return @name
    end

    def initialize(@name : String, data : Bytes)
    end

    def self.from_data(name : String, data : Bytes)
      return Flat.new(name, data)
    end
  end
end
