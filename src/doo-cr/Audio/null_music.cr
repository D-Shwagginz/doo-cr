require "./i_music.cr"

module Doocr::Audio
  class NullMusic
    include IMusic

    @@instance : NullMusic | Nil

    def self.get_instance
      if @@instance == nil
        @@instance = NullMusic.new
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
