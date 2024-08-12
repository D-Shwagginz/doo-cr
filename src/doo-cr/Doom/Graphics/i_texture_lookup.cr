module Doocr
  module ITextureLookup
    abstract def get_number(name : String) : Int
    abstract def [](name : String) : Texture
    abstract def switch_list : Array(Int32)
  end
end
