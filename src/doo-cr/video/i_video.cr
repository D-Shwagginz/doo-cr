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

module Doocr::Video
  module IVideo
    abstract def render(doom : Doom, frame_frac : Fixed)
    abstract def initialize_wipe
    abstract def has_focus : Bool

    abstract def max_window_size : Int32
    abstract def window_size : Int32
    abstract def window_size=(@window_size : Int32)

    abstract def display_message : Bool
    abstract def display_message=(@display_message : Bool)

    abstract def max_gamma_correction_level : Int32
    abstract def gamma_correction_level : Int32
    abstract def gamma_correction_level=(@gamma_correction_level : Int32)

    abstract def wipe_band_count : Int32
    abstract def wipe_height : Int32
  end
end
