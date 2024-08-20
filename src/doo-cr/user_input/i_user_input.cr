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

module Doocr::UserInput
  module IUserInput
    abstract def build_tic_cmd(cmd : TicCmd)
    abstract def reset
    abstract def grab_mouse
    abstract def release_mouse

    abstract def max_mouse_sensitivity : Int32
    abstract def mouse_sensitivity : Int32
    abstract def mouse_sensitivity=(@mouse_sensitivity : Int32)
  end
end
