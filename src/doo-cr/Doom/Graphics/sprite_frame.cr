module Doocr
  class SpriteFrame
    getter rotate : Bool
    getter patches : Array(Patch)
    getter flip : Array(Bool)

    def initialize(@rotate : Bool, @patches : Array(Patch), @flip : Array(Bool))
    end
  end
end
