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
    module DeHackEdConst
      class_property initial_health : Int32 = 100
      class_property initial_bullets : Int32 = 50
      class_property max_health : Int32 = 200
      class_property max_armor : Int32 = 200
      class_property green_armor_class : Int32 = 1
      class_property blue_armor_class : Int32 = 2
      class_property max_soulsphere : Int32 = 200
      class_property soulsphere_health : Int32 = 100
      class_property megasphere_health : Int32 = 200
      class_property god_mode_health : Int32 = 100
      class_property idfa_armor : Int32 = 200
      class_property idfa_armor_class : Int32 = 2
      class_property idkfa_armor : Int32 = 200
      class_property idkfa_armor_class : Int32 = 2
      class_property bfg_cells_per_shot : Int32 = 40
      class_property monsters_infight : Bool = false
    end
  end
end
