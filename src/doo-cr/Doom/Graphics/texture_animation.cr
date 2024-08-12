module Doocr
  class TextureAnimation
    getter animations : Array(TextureAnimationInfo)

    def initialize(textures : ITextureLookup, flats : IFlatLookup)
      begin
        print("Load texture animation info: ")

        list = [] of TextureAnimationInfo

        DoomInfo.texture_animation.each do |animdef|
          if animdef.is_texture
            next if textures.get_number(animdef.start_name) == -1
            pic_num = textures.get_number(animdef.end_name)
            base_pic = textures.get_number(animdef.start_name)
          else
            next if flats.get_number(animdef.start_name) == -1
            pic_num = flats.get_number(animdef.end_name)
            base_pic = flats.get_number(animdef.start_name)
          end

          anim = TextureAnimationInfo.new(
            animdef.is_texture,
            pic_num,
            base_pic,
            pic_num - base_pic + 1,
            animdef.speed
          )

          if anim.num_pics < 2
            raise "Bad animation cycle from " + animdef.start_name + " to " + animdef.end_name + "!"
          end

          list << anim
        end

        @animations = list
        puts("OK")
      rescue e
        puts("Failed")
        raise e
      end
    end
  end
end
