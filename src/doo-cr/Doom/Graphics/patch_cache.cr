module Doocr
  class PatchCache
    @wad : Wad
    @cache : Hash(String, Patch)

    def initialize(@wad : Wad)
      @cache = {} of String => Patch
    end

    def [](name : String)
      if !@cache[name]?
        patch = Patch.from_wad(@wad, name)
        @cache[name] = patch
      end
      return @cache[name]
    end

    def get_width(name : String) : Int32
      return [name].width
    end

    def get_height(name : String) : Int32
      return [name].height
    end
  end
end
