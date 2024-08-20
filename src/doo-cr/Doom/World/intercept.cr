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

module Doocr
  class Intercept
    property frac : Fixed | Nil
    getter thing : Mobj | Nil
    getter line : LineDef | Nil

    def make(@frac : Fixed, @thing : Mobj)
      line = nil
    end

    def make(@frac : Fixed, @line : LineDef)
      thing = nil
    end
  end
end
