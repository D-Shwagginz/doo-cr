module Doocr
  class GameContent
    getter wad : Wad | Nil = nil
    getter palette : Palette
    getter colormap : ColorMap
    getter textures : ITextureLookup
    getter flats : IFlatLookup
    getter sprites : ISpriteLookup
    getter animation : TextureAnimation

    private def initialize(
      @wad : Wad,
      @palette : Palette,
      @colormap : ColorMap,
      @textures : ITextureLookup,
      @flats : IFlatLookup,
      @sprites : ISpriteLookup,
      @animation : TextureAnimation
    )
    end

    def initialize(args : CommandLineArgs)
      @wad = Wad.new(ConfigUtilities.get_wad_paths(args))

      DeHackedEd.initialize(args, @wad)

      @palette = Palette.new(@wad)
      @colormap = ColorMap.new(@wad)
      @textures = TextureLookup.new(@wad)
      @flats = FlatLookup.new(@wad)
      @sprites = SpriteLookup.new(@wad)
      @animation = TextureAnimation.new(@textures, @flats)
    end

    def self.create_dummy(*wadpaths : String) : GameContent
      wad = Wad.new(wadpaths)
      textures = DummyTextureLookup.new(wad)
      flats = DummyFlatLookup.new(wad)
      gc = GameContent.new(
        wad,
        Palette.new(wad),
        ColorMap.new(wad),
        textures,
        flats,
        DummySpriteLookup.new(wad),
        TextureAnimation.new(textures, flats)
      )

      return gc
    end

    def dispose
      if @wad != nil
        @wad.as(Wad).dispose
        @wad = nil
      end
    end
  end
end