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

module Doocr::Audio
  module ISound
    abstract def set_listener(listener : Mobj)
    abstract def update
    abstract def start_sound(sfx : Sfx)
    abstract def start_sound(mobj : Mobj, sfx : Sfx, type : SfxType)
    abstract def start_sound(mobj : Mobj, sfx : Sfx, type : SfxType, volume : Int32)
    abstract def stop_sound(mobj : Mobj)
    abstract def reset
    abstract def pause
    abstract def resume

    abstract def max_volume : Int32
    abstract def volume : Int32
    abstract def volume=(@volume : Int32)
  end
end
