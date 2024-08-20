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

require "./i_user_input.cr"

module Doocr::UserInput
  class NullUserInput
    include IUserInput

    @@instance : NullUserInput | Nil

    def self.get_instance
      if @@instance == nil
        @@instance = NullUserInput.new
      end

      return @@instance
    end

    def reset
    end

    def grab_mouse
    end

    def release_mouse
    end

    def mouse_sensitivity=(mouse_sensitivity : Int32)
    end

    def build_tic_cmd(cmd : TicCmd)
      cmd.clear
    end

    def max_mouse_sensitivity : Int32
      return 9
    end

    def mouse_sensitivity : Int32
      return 3
    end
  end
end
