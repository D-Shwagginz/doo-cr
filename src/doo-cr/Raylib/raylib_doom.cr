module Doocr::Raylib
  class RaylibDoom
    @args : CommandLineArgs | Nil

    @config : Config | Nil
    @content : GameContent | Nil

    @video : RaylibVideo | Nil

    def initialize(@args : CommandLineArgs)
      begin
      rescue e
      end
    end
  end
end
