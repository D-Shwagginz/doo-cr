module Doocr
  module Mod
    class Weapon
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

      enum AmmoType
        Clip   # Pistol / chaingun ammo.
        Shell  # Shotgun / double barreled shotgun.
        Cell   # Plasma rifle, BFG.
        Misl   # Missile launcher.
        Noammo # Unlimited for chainsaw / fist.
      end

      property ammo_use : Int32 = 0
      property ammo_give : Int32 = 0
      property ammo_type : AmmoType = AmmoType::Noammo

      
    end

    def self.add_weapon(slot : WeaponSlot, &)
      weapon = Weapon.new
      yield weapon
      
    end
  end

  def self.make_mod(&)
    yield Mod
  end
end
