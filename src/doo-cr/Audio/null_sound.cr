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

require "./i_sound.cr"

module Doocr::Audio
  class NullSound
    include ISound

    @@instance : NullSound | Nil = nil

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
