require "../i_flat_lookup.cr"

module Doocr
  class DummyFlatLookup
    include IFlatLookup
    @flats : Array(Flat)

    @name_to_flat : Hash(String, Flat)
    @name_to_number : Hash(String, Int32)

    getter sky_flat_number : Int32
    getter sky_flat : Flat

    def each(&)
      @flats.each do |t|
        yield t
      end
    end

    def size
      return @flats.size
    end

    def [](num : Int32)
      return @flats[num]
    end

    def [](name : String)
      @name_to_flat[name]
    end

    def initialize(wad : Wad)
      first_flat = wad.get_lump_number("F_START") + 1
      last_flat = wad.get_lump_number("F_END") - 1
      count = last_flat - first_flat + 1

      @flats = Array(Flat).new(count)

      @name_to_flat = {} of String => Flat
      @name_to_number = {} of String => Int32

      lump = first_flat
      while lump <= last_flat
        if wad.get_lump_size(lump) != 4096
          lump += 1
          next
        end

        number = lump - first_flat
        name = wad.lump_infos[lump].name
        flat = name != "F_SKY1" ? DummyData.get_flat : DummData.get_sky_flat

        @flats << flat
        @name_to_flat[name] = flat
        @name_to_number[name] = number

        lump += 1
      end

      @sky_flat_number = @name_to_number["F_SKY1"]
      @sky_flat = @name_to_flat["F_SKY1"]
    end

    def get_number(name : String) : Int32
      if @name_to_number.has_key?(name)
        return @name_to_number[name]
      else
        return -1
      end
    end
  end
end
