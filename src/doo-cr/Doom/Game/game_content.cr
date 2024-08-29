#
# Copyright (C) 1993-1996 Id Software, Inc.
# Copyright (C) 2019-2020 Nobuaki Tanaka
# Copyright (C) 2024 Devin Shwagginz
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#

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

      DeHackedEd.initialize(args, @wad.as(Wad))

      @palette = Palette.new(@wad.as(Wad))
      @colormap = ColorMap.new(@wad.as(Wad))
      @textures = TextureLookup.new(@wad.as(Wad))
      @flats = FlatLookup.new(@wad.as(Wad))
      @sprites = SpriteLookup.new(@wad.as(Wad))
      @animation = TextureAnimation.new(@textures, @flats)
    end

    def self.create_dummy(*wadpaths : String) : GameContent
      wad = Wad.new(wadpaths.to_a)
      textures = DummyTextureLookup.new(wad)
      flats = DummyFlatLookup.new(wad)
      gc = new(
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

    def finalize
      if @wad != nil
        @wad.as(Wad).finalize
        @wad = nil
      end
    end
  end
end
