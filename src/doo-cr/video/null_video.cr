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

require "./i_video.cr"

module Doocr::Video
  class NullVideo
    include IVideo

    @@instance : NullVideo | Nil = nil

    def self.get_instance
      if @@instance == nil
        @@instance = Video::NullVideo.new
      end

      return @@instance
    end

    def render(doom : Doom, frame_frac : Fixed)
    end

    def initialize_wipe
    end

    def display_message=(display_message : Bool)
    end

    def gamma_correction_level=(gamma_correction_level : Int32)
    end

    def has_focus : Bool
      return true
    end

    def window_size=(window_size : Int32)
    end

    def max_window_size : Int32
      return ThreeDRenderer.max_screen_size
    end

    def window_size : Int32
      return 7
    end

    def display_message : Bool
      return true
    end

    def max_gamma_correction_level : Int32
      return 10
    end

    def gamma_correction_level : Int32
      return 2
    end

    def wipe_band_count : Int32
      return 321
    end

    def wipe_height : Int32
      return 200
    end
  end
end
