module Doocr
  class DoomString
    @@value_table : Hash(String, DoomString) = {} of String => DoomString
    @@name_table : Hash(String, DoomString) = {} of String => DoomString

    @original : String
    @replaced : String

    def initialize(@original : String)
      @replaced = @original

      if !@@value_table.has_key?(@original)
        @@value_table[original] = self
      end
    end

    def initialize(name : String, @original : String)
      @@name_table[name] = self
    end

    def to_s
      return @replaced
    end

    def [](index : Int32) : Char
      return @replaced[index]
    end

    def self.replace_by_value(original : String, replaced : String)
      if ds = @@value_table[original]?
        ds.replaced = replaced
      end
    end

    def self.replace_by_name(name : String, value : String)
      if ds = @@name_table[name]?
        ds.replaced = value
      end
    end
  end
end
