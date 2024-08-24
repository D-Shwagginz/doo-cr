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
  module DoomInfo
    module PowerDuration
      class_getter invulnerability : Int32 = 30 * GameConst.tic_rate
      class_getter invisibility : Int32 = 60 * GameConst.tic_rate
      class_getter infrared : Int32 = 120 * GameConst.tic_rate
      class_getter iron_feet : Int32 = 60 * GameConst.tic_rate
    end
  end
end