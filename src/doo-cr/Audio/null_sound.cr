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

    def max_volume : Int32
      return 15
    end

    def volume : Int32
      return 0
    end
  end
end
