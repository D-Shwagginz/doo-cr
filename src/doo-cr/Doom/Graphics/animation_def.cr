module Doocr
  class AnimationDef
    getter is_texture : Bool
    getter end_name : String
    getter start_name : String
    getter speed : Int32

    def initialize(
      @is_texture : Bool,
      @end_name : String,
      @start_name : String,
      @speed : Int32
    )
    end
  end
end
