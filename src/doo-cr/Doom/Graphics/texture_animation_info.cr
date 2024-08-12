module Doocr
  class TextureAnimationInfo
    getter is_texture : Bool
    getter pic_num : Int32
    getter base_pic : Int32
    getter num_pics : Int32
    getter speed : Int32

    def initialize(
      @is_texture : Bool,
      @pic_num : Int32,
      @base_pic : Int32,
      @num_pics : Int32,
      @speed : Int32
    )
    end
  end
end
