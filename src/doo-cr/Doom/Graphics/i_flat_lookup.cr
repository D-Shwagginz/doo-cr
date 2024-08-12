module Doocr
  module IFlatLookup
    abstract def get_number(name : String) : Int
    abstract def [](name : String) : Flat
    abstract def sky_flat_number : Int
    abstract def sky_flat : Flat
  end
end
