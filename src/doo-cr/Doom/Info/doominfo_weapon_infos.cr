module Doocr
  module DoomInfo
    class_getter weaponinfos : Array(WeaponInfo) = [
      # fist
      WeaponInfo.new(
        AmmoType::NoAmmo,
        MobjState::Punchup,
        MobjState::Punchdown,
        MobjState::Punch,
        MobjState::Punch1,
        MobjState::Null
      ),

      # pistol
      WeaponInfo.new(
        AmmoType::Clip,
        MobjState::Pistolup,
        MobjState::Pistoldown,
        MobjState::Pistol,
        MobjState::Pistol1,
        MobjState::Pistolflash
      ),

      # shotgun
      WeaponInfo.new(
        AmmoType::Shell,
        MobjState::Sgunup,
        MobjState::Sgundown,
        MobjState::Sgun,
        MobjState::Sgun1,
        MobjState::Sgunflash1
      ),

      # chaingun
      WeaponInfo.new(
        AmmoType::Clip,
        MobjState::Chainup,
        MobjState::Chaindown,
        MobjState::Chain,
        MobjState::Chain1,
        MobjState::Chainflash1
      ),

      # missile launcher
      WeaponInfo.new(
        AmmoType::Missile,
        MobjState::Missileup,
        MobjState::Missiledown,
        MobjState::Missile,
        MobjState::Missile1,
        MobjState::Missileflash1
      ),

      # plasma rifle
      WeaponInfo.new(
        AmmoType::Cell,
        MobjState::Plasmaup,
        MobjState::Plasmadown,
        MobjState::Plasma,
        MobjState::Plasma1,
        MobjState::Plasmaflash1
      ),

      # bfg 9000
      WeaponInfo.new(
        AmmoType::Cell,
        MobjState::Bfgup,
        MobjState::Bfgdown,
        MobjState::Bfg,
        MobjState::Bfg1,
        MobjState::Bfgflash1
      ),

      # chainsaw
      WeaponInfo.new(
        AmmoType::NoAmmo,
        MobjState::Sawup,
        MobjState::Sawdown,
        MobjState::Saw,
        MobjState::Saw1,
        MobjState::Null
      ),

      # # super shotgun
      WeaponInfo.new(
        AmmoType::Shell,
        MobjState::Dsgunup,
        MobjState::Dsgundown,
        MobjState::Dsgun,
        MobjState::Dsgun1,
        MobjState::Dsgunflash1
      ),
    ]
  end
end
