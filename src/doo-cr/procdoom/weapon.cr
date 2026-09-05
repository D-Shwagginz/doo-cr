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

      CDoom.weaponinfo[@slot.value] = CDoom::Weaponinfo.new(
        ammo: CDoom::Ammotype.from_value(@ammo_type.value),
        upstate: CDoom::Statenum.new(up_num),
        downstate: CDoom::Statenum.new(down_num),
        readystate: CDoom::Statenum.new(ready_num),
        atkstate: CDoom::Statenum.new(atk_num),
        flashstate: CDoom::Statenum.new(flash_num),
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
