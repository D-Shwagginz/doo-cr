module Doocr
  # The module which houses all the methods to provide you hooks
  # to insert custom weapons, things, states and more!
  #
  # You can use doo-cr -dbcfg to create a doom builder config file which
  # will show all your custom stuff in doom builder
  #
  # Here's an example of how to recreate the pistol as a modded weapon
  #
  # ```
  # Doocr.make_mod do |mod|
  #   mod.add_weapon Doocr::Mod::Weapon::WeaponSlot::Pistol do |weapon|
  #     weapon.ammo_type = Doocr::Mod::Weapon::AmmoType::Clip
  #     weapon.states do |up, down, ready, atk, flash|
  #       ready.add "PISG", 'A', 1, (->CDoom.a_weapon_ready).pointer
  #       ready.loop
  #
  #       down.add "PISG", 'A', 1, (->CDoom.a_lower).pointer
  #       down.loop
  #
  #       up.add "PISG", 'A', 1, (->CDoom.a_raise).pointer
  #       up.loop
  #
  #       atk.add "PISG", 'A', 4
  #       atk.add "PISG", 'B', 6, (->CDoom.a_fire_pistol).pointer
  #       atk.add "PISG", 'C', 4
  #       atk.add "PISG", 'B', 5, (->CDoom.a_refire).pointer
  #       atk.goto ready
  #
  #       flash.add_lit "PISF", 'A', 7, (->CDoom.a_light1).pointer
  #       flash.goto 1
  #     end
  #   end
  # end
  # ```
  #
  # Here's an example to make a custom linedef tag
  # ```
  # Doocr.make_mod do |mod|
  #   mod.add_line "Custom spawn zombie line", Doocr::Mod::Line::When::Crossed do |line, side, thing|
  #     unless thing.value.player.null?
  #       mo = thing
  #       an = mo.value.angle
  #
  #       x = mo.value.x + Doocr.fixed_mul(Doocr::FRACUNIT * 55, Doocr.finecosine[an >> CDoom::ANGLETOFINESHIFT])
  #       y = mo.value.y + Doocr.fixed_mul(Doocr::FRACUNIT * 55, Doocr.finesine[an >> CDoom::ANGLETOFINESHIFT])
  #       z = mo.value.z
  #
  #       th = Doocr.p_spawn_mobj(x, y, z, CDoom::Mobjtype::MT_POSSESSED)
  #
  #       th.value.angle = an
  #       th.value.momx = Doocr.fixed_mul(Doocr::FRACUNIT * 8, Doocr.finecosine[an >> CDoom::ANGLETOFINESHIFT])
  #       th.value.momy = Doocr.fixed_mul(Doocr::FRACUNIT * 8, Doocr.finesine[an >> CDoom::ANGLETOFINESHIFT])
  #     end
  #   end
  # end
  # ```
  module Mod
    @@weapons = [] of Weapon
    class_getter lines = [] of Line

    protected def self.parse
      @@weapons.each &.parse
    end

    # Adds a weapon into the mod at the given slot.
    # Takes a block which yields the weapon for setup
    def self.add_weapon(slot : Weapon::WeaponSlot, &)
      weapon = Weapon.new(slot)
      yield weapon
      @@weapons << weapon
    end

    # Adds a custom line tag into the mod given its doombuilder name,
    # when it will happen, and the block that will be performed when this occurs.
    #
    # The blocks parms are the line that the tag happened on, the side it happened, and the thing that triggered it
    def self.add_line(db_name : String, when : Line::When, &action : Proc(CDoom::Line*, Int32, CDoom::Mobj*, Nil))
      line = Line.new(db_name, when, action)
      @@lines << line
    end
  end

  # Yields the mod module for block style code
  def self.make_mod(&)
    yield Mod
  end

  # Gets the current player that the state is being called from.
  #  Can be null if the state isn't being called from a player (a mobj state)
  def self.get_player : CDoom::Player*
    @@current_thinking_player
  end

  # Gets the current mobj that the state is being called from.
  #  Can be null if the state isn't being called from a mobj (a weapon state)
  def self.get_mobj : CDoom::Mobj*
    @@current_thinking_mobj
  end
end
