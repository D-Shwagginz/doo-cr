module Doocr::Video
  class MenuRenderer
    @@cursor : Array(Char) = ['_']

    @wad : Wad
    @screen : DrawScreen

    @cache : PatchCache

    def initialize(@wad : Wad, @screen : DrawScreen)
      @cache = PatchCache.new(@wad)
    end

    def render(menu : DoomMenu)
    end
  end
end
