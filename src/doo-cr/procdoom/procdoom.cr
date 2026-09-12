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
# ==> The main code for the custom modding/engine generation stuff

module Doocr
  # The module which houses all the methods to provide you hooks
  # to insert custom weapons, things, states and more!
  #
  # You can use doo-cr -dbcfg to create a doom builder config file which
  # will show all your custom tags in doom builder
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
  # Here's an example of how to make a custom linedef tag
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
  #
  # Here's an example of how to make a custom sector tag
  # ```
  # Doocr.make_mod do |mod|
  #   mod.add_sector "My Custom Sector" do |sector, player|
  #     player.value.message = "You entered my sector!"
  #   end
  # end
  # ```
  # Here's an example of to make a custom thing you can pickup
  # ```
  # Doocr.make_mod do |mod|
  #   mod.add_thing "My Health potion" do |thing|
  #     thing.health = 1000
  #     thing.radius = 20.0
  #     thing.height = 16.0
  #     thing.reaction_time = 8
  #     thing.mass = 100
  #
  #     thing.states do |spawn, walk, pain, melee, attack, death, explode, raise|
  #       spawn.add "BON1", 'A', 6
  #       spawn.add "BON1", 'B', 6
  #       spawn.add "BON1", 'C', 6
  #       spawn.add "BON1", 'D', 6
  #       spawn.add "BON1", 'C', 6
  #       spawn.add "BON1", 'B', 6
  #       spawn.loop
  #     end
  #
  #     thing.on_touch do |special, toucher|
  #       if toucher.value.health > 0
  #         player = toucher.value.player
  #         player.value.health = player.value.health + 1 # can go over 100%
  #         player.value.health = 200 if player.value.health > 200
  #         player.value.mo.value.health = player.value.health
  #         player.value.message = "Got my modded health!"
  #
  #         player.value.itemcount = player.value.itemcount + 1
  #         CDoom.p_remove_mobj(special)
  #         player.value.bonuscount = player.value.bonuscount + CDoom::BONUSADD
  #         CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_itemup.value) if mod.get_player_num(player) == Doocr.consoleplayer
  #       end
  #     end
  #   end
  # end
  # ```
  module Mod
    @@weapons = [] of Weapon
    class_getter lines = [] of Line
    class_getter sectors = [] of Sector
    class_getter things = [] of Thing

    class_property name = ""
    class_getter wad_names = [] of String

    protected def self.parse
      @@weapons.each &.parse
      @@things.each &.parse
    end

    # Adds a wad to check for auto loading
    def self.check_wad(wad : String)
      @@wad_names << wad
    end

    # Adds a weapon into the mod at the given slot.
    # Takes a block which yields the weapon for setup
    def self.add_weapon(slot : Weapon::WeaponSlot, &)
      weapon = Weapon.new(slot)
      yield weapon
      @@weapons << weapon
    end

    # Adds a thing into the mod
    # Takes a block which yields the thing for setup
    # Returns the index of the mobj for spawning inside of your methods
    def self.add_thing(db_name : String, db_spawnable : Bool = true, &) : CDoom::Mobjtype
      thing = Thing.new(db_name, db_spawnable)
      yield thing
      @@things << thing
      return CDoom::Mobjtype.new(thing.mobjtype)
    end

    # Adds a sound into the mod
    # name is up to 6 chars
    # singularity - only one at a time
    # priority - Sfx priority for when channels get full
    # Returns the index that sound is at
    def self.add_sound(name : String, singularity : Bool = false, priority : Int32 = 64) : Int32
      Doocr.s_sfx << CDoom::Sfxinfo.new(
        name: name[0..5].downcase,
        singularity: singularity.to_unsafe,
        priority: priority,
        link: Pointer(CDoom::Sfxinfo).null, pitch: -1, volume: -1,
        data: Pointer(Void).null
      )
      Doocr.lengths << 0
      return Doocr.s_sfx.size - 1
    end

    # Adds a custom line tag into the mod given its doombuilder name,
    # when it will happen, and the block that will be performed when this occurs.
    #
    # The blocks parms are the line that the tag happened on, the side it happened, and the thing that triggered it
    def self.add_line(db_name : String, when : Line::When, &action : Proc(CDoom::Line*, Int32, CDoom::Mobj*, Nil))
      line = Line.new(db_name, when, action)
      @@lines << line
    end

    # Adds a custom sector tag into the mod given its doombuilder name,
    # when it will happen, and the block that will be performed when this occurs.
    #
    # The blocks parms are the line that the tag happened on, the side it happened, and the thing that triggered it
    def self.add_sector(db_name : String, &action : Proc(CDoom::Sector*, CDoom::Player*, Nil))
      sector = Sector.new(db_name, action)
      @@sectors << sector
    end

    # Gets which player number a player pointer is
    def self.get_player_num(player : CDoom::Player*) : Int64
      return player - Doocr.players
    end

    # Gets the current player that the state is being called from.
    #  Can be null if the state isn't being called from a player (a mobj state)
    def self.get_player : CDoom::Player*
      Doocr.current_thinking_player
    end

    # Gets the current mobj that the state is being called from.
    #  Can be null if the state isn't being called from a mobj (a weapon state)
    def self.get_mobj : CDoom::Mobj*
      Doocr.current_thinking_mobj
    end

    class_getter update_player_action : Proc(CDoom::Player*, Nil) = ->(player : CDoom::Player*) { nil }

    # Sets what will happen when a player is updated
    def self.update_player(&action : CDoom::Player* -> Nil)
      @@update_player_action = action
    end

    macro make_var(var)
      module Doocr::Mod
        class_property {{var}}
      end
    end

    class_getter player_vars = [] of Hash(String, String | Int32 | Bool)

    # Gets a variable assigned to a player number
    def self.player_var(player : CDoom::Player*)
      @@player_vars[player - Doocr.players]
    end

    # Creates a player var with a default value
    def self.make_player_var(var : String, value : String | Int32 | Bool)
      @@player_vars.each { |hash| hash[var] = value }
    end
  end

  # Yields the mod module for block style code
  def self.make_mod(&)
    CDoom::MAXPLAYERS.times { |i| Mod.player_vars << {} of String => String | Int32 | Bool }
    yield Mod
  end
end
