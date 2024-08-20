require "./i_sound.cr"

module Doocr::Audio
  class NullSound
    include ISound

    @@instance : NullSound | Nil

    def self.get_instance
      if @@instance == nil
        @@instance = NullSound.new
      end

      return @@instance
    end

    def set_listener(listener : Mobj)
    end

    def update
    end

    def start_sound(mobj : Mobj, sfx : Sfx, type : SfxType, volume : Int32)
    end

    def start_sound(mobj : Mobj, sfx : Sfx, type : SfxType)
    end

    def start_sound(sfx : Sfx)
    end

    def stop_sound(mobj : Mobj)
    end

    def reset
    end

    def pause
    end

    def resume
    end

    def volume=(volume : Int32)
    end

    def max_volume : Int32
      return 15
    end

    def volume : Int32
      return 0
    end
  end
end
