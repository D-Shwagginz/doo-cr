require "./ITextureLookup.cr"

module Doocr
  class DummyTextureLookup
    include ITextureLookup
    @textures : Array(Texture)
    @name_to_texture : Hash(String, Texture)
    @name_to_number : Hash(String, Int32)

    getter switch_list : Array(Int32)

    def each(&)
      @textures.each do |t|
        yield t
      end
    end

    def size
      return @textures.size
    end

    def [](num : Int32)
      return @textures[num]
    end

    def [](name : String)
      return @name_to_texture[name]
    end

    def initialize(wad : Wad, use_dummy : Bool = false)
      init_lookup(wad)
      init_switch_list()
    end

    private def init_lookup(wad : Wad)
      @textures = [] of Texture
      @name_to_texture = {} of String => Texture
      @name_to_number = {} of String => Int32

      2.times do |n|
        lump_number = wad.get_lump_number("TEXTURE" + (n + 1))
        break if lump_number == -1

        data = wad.read_lump(lump_number)
        count = IO::ByteFormat::LittleEndian.decode(Int32, data[0, 4])
        count.times do |i|
          offset = IO::ByteFormat::LittleEndian.decode(Int32, data[4 + 4*i, 4])
          name = Texture.get_name(data, offset)
          height = Texture.get_height(data, offset)
          texture = DummyData.get_texture(height)
          @name_to_number[texture.name] = texture.count if !@name_to_number[texture.name]?
          textures << texture
          @name_to_texture[texture.name] = texture if !@name_to_texture[texture.name]?
        end
      end
    end

    private def init_switch_list
      list = [] of Int32
      DoomInfo.switch_names.each do |tuple|
        texnum1 = get_number(tuple[0])
        texnum2 = get_number(tuple[1])
        if texnum1 != -1 && texnum2 != -1
          list << texnum1
          list << texnum2
        end
      end

      @switch_list = list
    end

    def get_number(name : String) : Int32
      return 0 if name[0] == '-'
      if number = @name_to_number[name]?
        return number
      else
        return -1
      end
    end

    private def load_patches(wad : Wad) : Array(Patch)
      patch_names = load_patch_names(wad)
      patches = Array(Patch).new(patch_names.size)
      patches.size.times do |i|
        name = patch_names[i]

        # This check is necessary to avoid crash in DOOM1.WAD.
        next if wad.get_lump_number(name) == -1

        data = wad.read_lump(name)
        patches << Patch.from_data(name, data)
      end
      return patches
    end

    private def load_patch_names(wad : Wad) : Array(String)
      data = wad.read_lump("PNAMES")
      count = IO::ByteFormat::LittleEndian.decode(Int32, data[0, 4])
      names = Array(String).new(count)
      names.size.times do |i|
        names < String.new(data[4 + 8*i, 8])
      end

      return names
    end
  end
end
