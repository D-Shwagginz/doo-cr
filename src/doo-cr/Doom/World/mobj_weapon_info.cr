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
  class WeaponInfo
    property ammo : AmmoType
    property up_state : MobjState
    property down_state : MobjState
    property ready_state : MobjState
    property attack_state : MobjState
    property flash_state : MobjState

    def initialize(
      @ammo : AmmoType,
      @up_state : MobjState,
      @down_state : MobjState,
      @ready_state : MobjState,
      @attack_state : MobjState,
      @flash_state : MobjState
    )
    end
  end
end
