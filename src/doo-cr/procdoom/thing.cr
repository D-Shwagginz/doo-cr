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
# ==> A custom thing

module Doocr::Mod
  class Thing
    @[Flags]
    enum Flags
      # Call on_touch when touched
      Special
      # Blocks other things from moving through it
      Solid
      # Can be shot/hit
      Shootable
      # Don't use the sector links (invisible but touchable)
      NoSector
      # Don't use the blocklinks (inert but displayable)
      NoBlockmap

      # Not to be activated by sound, deaf monster
      Ambush
      # Will try to attack right back after being attacked
      AttackRightBack
      # Will take at least one step before attacking
      StepsBeforeAttack
      # Spawn hanging from ceiling
      SpawnCeiling
      # Don't apply gravity (every tic),
      #  that is, object will float, keeping current height
      #  or changing it actively.
      NoGravity

      # Allows traveling over height distances greater than 24 units
      TravelOverCliffs
      # Can pick up other items
      PicksUpItems
      # Can walk through obstacles and walls
      Noclip
      # Will remember wall sliding information
      Slide
      # Allow moves to any height, no gravity.
      # For active floaters, e.g. cacodemons, pain elementals.
      Float
      # Can walk through obstacles, but not walls
      SemiNoclip
      # Don't hit same species, explode on block.
      # Player missiles as well as fireballs of various kinds.
      Missile
      # Dropped by a demon, not level spawned.
      # E.g. ammo clips dropped by dying former humans.
      Dropped
      # Use fuzzy draw (shadow demons or spectres),
      #  temporary player invisibility powerup.
      Shadow
      # Flag: don't bleed when shot (use puff),
      #  barrels and shootable furniture shall not bleed.
      NoBlood
      # Don't stop moving halfway off a step,
      #  that is, have dead bodies slide down all the way.
      Corpse
      # Won't automatically get equal to the floors level
      InFloat

      # On kill, count this enemy object
      #  towards intermission kill total.
      # Happy gathering.
      CountKill

      # On picking up, count this item object
      #  towards intermission item total.
      CountItem

      # Special handling: skull in flight.
      # Neither a cacodemon nor a missile.
      SkullFly

      # Don't spawn this object
      #  in death match mode (e.g. key cards).
      NoDeathmatch
    end

    getter db_name : String
    getter db_sprite : String = ""
    getter doomednum : Int32 = 5050 # I think 5002 is the last thing number in doom builder, but 5050 to be safe
    getter mobjtype : Int32 = CDoom::Mobjtype::NUMMOBJTYPES.value

    property health : Int32 = 0
    property speed : Float64 = 0.0
    property radius : Float64 = 0.0
    property height : Float64 = 0.0
    property damage : Int32 = 0
    property reaction_time : Int32 = 0
    property pain_chance : Int32 = 0
    property mass : Int32 = 0

    @spawnstate : StateHandler = StateHandler.new
    @walkstate : StateHandler = StateHandler.new
    @painstate : StateHandler = StateHandler.new
    @meleestate : StateHandler = StateHandler.new
    @attackstate : StateHandler = StateHandler.new
    @deathstate : StateHandler = StateHandler.new
    @explodestate : StateHandler = StateHandler.new
    @raisestate : StateHandler = StateHandler.new

    property alertsound : String = ""
    property attacksound : String = ""
    property painsound : String = ""
    property deathsound : String = ""
    property activesound : String = ""

    getter flags : Flags = Flags::None

    def set_flags(flags : Flags)
      @flags |= flags
    end

    def unset_flag(flags : Flags)
      @flags = @flags & ~flags
    end

    getter on_touch : Proc(CDoom::Mobj*, CDoom::Mobj*, Nil) = ->(special : CDoom::Mobj*, toucher : CDoom::Mobj*) { nil }

    def on_touch(&touch : CDoom::Mobj*, CDoom::Mobj* -> Nil)
      @on_touch = touch
      set_flags(Flags::Special)
    end

    # Yields the thing's state handlers for you to add states to
    def states(&)
      yield @spawnstate, @walkstate, @painstate,
        @meleestate, @attackstate, @deathstate,
        @explodestate, @raisestate

      state = nil
      if state = @spawnstate.states[0]?
      elsif state = @walkstate.states[0]?
      elsif state = @painstate.states[0]?
      elsif state = @meleestate.states[0]?
      elsif state = @attackstate.states[0]?
      elsif state = @deathstate.states[0]?
      elsif state = @explodestate.states[0]?
      elsif state = @raisestate.states[0]?
      else
        return
      end

      sprite = Doocr.sprnames[state.not_nil!.sprite.value]
      return if sprite.downcase == "tnt1"
      @db_sprite = sprite + ('A' + state.not_nil!.frame)
    end

    def initialize(@db_name, db_spawnable : Bool = true)
      @doomednum = db_spawnable ? @doomednum + Mod.things.size : -1
      @mobjtype += Mod.things.size
    end

    protected def parse
      spawn_num = @spawnstate.parse
      walk_num = @walkstate.parse
      pain_num = @painstate.parse
      melee_num = @meleestate.parse
      attack_num = @attackstate.parse
      death_num = @deathstate.parse
      explode_num = @explodestate.parse
      raise_num = @raisestate.parse

      # Sounds
      if @alertsound.empty?
        alert_sound = 0
      elsif sound = Doocr.s_sfx.index { |sfx| sfx.name.value == @alertsound[0..5].downcase }
        alert_sound = sound
      else
        alert_sound = Mod.add_sound(@alertsound)
      end

      if @attacksound.empty?
        attack_sound = 0
      elsif sound = Doocr.s_sfx.index { |sfx| sfx.name.value == @attacksound[0..5].downcase }
        attack_sound = sound
      else
        attack_sound = Mod.add_sound(@attacksound)
      end

      if @painsound.empty?
        pain_sound = 0
      elsif sound = Doocr.s_sfx.index { |sfx| sfx.name.value == @painsound[0..5].downcase }
        pain_sound = sound
      else
        pain_sound = Mod.add_sound(@painsound)
      end

      if @deathsound.empty?
        death_sound = 0
      elsif sound = Doocr.s_sfx.index { |sfx| sfx.name.value == @deathsound[0..5].downcase }
        death_sound = sound
      else
        death_sound = Mod.add_sound(@deathsound)
      end

      if @activesound.empty?
        active_sound = 0
      elsif sound = Doocr.s_sfx.index { |sfx| sfx.name.value == @activesound[0..5].downcase }
        active_sound = sound
      else
        active_sound = Mod.add_sound(@activesound)
      end

      Doocr.mobjinfo << CDoom::Mobjinfo.new(
        doomednum: @doomednum,
        spawnstate: spawn_num,
        spawnhealth: @health,
        seestate: walk_num,
        seesound: alert_sound,
        reactiontime: @reaction_time,
        attacksound: attack_sound,
        painstate: pain_num,
        painchance: @pain_chance,
        painsound: pain_sound,
        meleestate: melee_num,
        missilestate: attack_num,
        deathstate: death_num,
        xdeathstate: explode_num,
        deathsound: death_sound,
        speed: Doocr.float_to_fixed(@speed),
        radius: Doocr.float_to_fixed(@radius),
        height: Doocr.float_to_fixed(@height),
        mass: @mass,
        damage: @damage,
        activesound: active_sound,
        flags: @flags.value,
        raisestate: raise_num
      )

      @spawnstate.parse_ends
      @walkstate.parse_ends
      @painstate.parse_ends
      @meleestate.parse_ends
      @attackstate.parse_ends
      @deathstate.parse_ends
      @explodestate.parse_ends
      @raisestate.parse_ends
    end
  end
end
