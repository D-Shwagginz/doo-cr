# Copyright (C) 2026 Devin Shwagginz
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# ==> Custom weapons

module Doocr::Mod
  # A modded weapon
  class Weapon
    @slot : WeaponSlot
    # The ammo type for use in functions that deal with
    #  `Mod.get_player` ammo values
    setter ammo_type : AmmoType = AmmoType::Noammo
    @up : StateHandler = StateHandler.new
    @down : StateHandler = StateHandler.new
    @ready : StateHandler = StateHandler.new
    @atk : StateHandler = StateHandler.new
    @flash : StateHandler = StateHandler.new

    # The slot a weapon can occupy
    enum WeaponSlot
      Fist
      Pistol
      Shotgun
      Chaingun
      Rocket
      Plasma
      BFG
      Chainsaw
      SuperShotgun
    end

    # A type of ammo a weapon can use
    enum AmmoType
      Clip   = 0 # Pistol / chaingun ammo.
      Shell  = 1 # Shotgun / double barreled shotgun.
      Cell   = 2 # Plasma rifle, BFG.
      Misl   = 3 # Missile launcher.
      Noammo = 5 # Unlimited for chainsaw / fist.
    end

    # Yields the up, down, ready, atk, and flash state handlers
    #  for you to add states to
    def states(&)
      yield @up, @down, @ready, @atk, @flash
    end

    protected def parse
      up_num = @up.parse
      down_num = @down.parse
      ready_num = @ready.parse
      atk_num = @atk.parse
      flash_num = @flash.parse

      Doocr.weaponinfo[@slot.value] = Doocr::Weaponinfo.new(
        ammo: Doocr::Ammotype.from_value(@ammo_type.value),
        upstate: Doocr::Statenum.new(up_num),
        downstate: Doocr::Statenum.new(down_num),
        readystate: Doocr::Statenum.new(ready_num),
        atkstate: Doocr::Statenum.new(atk_num),
        flashstate: Doocr::Statenum.new(flash_num),
      )

      @up.parse_ends
      @down.parse_ends
      @ready.parse_ends
      @atk.parse_ends
      @flash.parse_ends
    end

    def initialize(@slot)
    end
  end
end
