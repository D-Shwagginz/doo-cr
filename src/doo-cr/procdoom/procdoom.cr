module Doocr
  # The module which houses all the methods to provide you hooks
  # to insert custom weapons, things, states and more!
  #
  # Currently you can only add custom weapons
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
  # And here's an example how how to make a modded pistol which shoots out zombiemen!
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
  #       atk.add "PISG", 'B', 6 do
  #         player = Doocr.get_player
  #         mo = player.value.mo
  #         an = mo.value.angle
  #
  #         Doocr.s_start_sound(mo.as(Void*), CDoom::Sfxenum::SFX_pistol.value)
  #
  #         x = mo.value.x + Doocr.fixed_mul(Doocr::FRACUNIT * 55, Doocr.finecosine[an >> CDoom::ANGLETOFINESHIFT])
  #         y = mo.value.y + Doocr.fixed_mul(Doocr::FRACUNIT * 55, Doocr.finesine[an >> CDoom::ANGLETOFINESHIFT])
  #         z = mo.value.z
  #
  #         th = Doocr.p_spawn_mobj(x, y, z, CDoom::Mobjtype::MT_POSSESSED)
  #
  #         th.value.angle = an
  #         th.value.momx = Doocr.fixed_mul(Doocr::FRACUNIT * 8, Doocr.finecosine[an >> CDoom::ANGLETOFINESHIFT])
  #         th.value.momy = Doocr.fixed_mul(Doocr::FRACUNIT * 8, Doocr.finesine[an >> CDoom::ANGLETOFINESHIFT])
  #         th.value.momz = Doocr::FRACUNIT * 8
  #       end
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
  module Mod
    # A handler for states.
    # Used to build custom states into the engine
    class StateHandler
      @goto : StateHandler?
      @goto_num = 0
      getter state_index = -1

      @states : Array(CDoom::State) = [] of CDoom::State

      # Adds a state into this handler given the name of the sprite,
      # the frame letter or number, the tics/length of the state, and the action it performs.
      #
      # The next state for this added state will be the next state in the handler
      # unless this is the last state in the handler, in which case it will default to 0 (a null state)
      # or whatever you specify with `StateHandler#loop` or <br>
      # `StateHandler#goto(handler : StateHandler)`/`StateHandler#goto(state_num : Int32)`
      #
      # The action is given as a do-end block
      def add(name : String, frame : Char | Int, tics : Int32, &action)
        Doocr.sprnames << name unless Doocr.sprnames.includes?(name)
        next_state = @states.size + 1
        @state_index = @states.size if @state_index == -1
        @states << CDoom::State.new(
          sprite: CDoom::Spritenum.new(Doocr.sprnames.index!(name)),
          frame: (frame.is_a?(Char) ? frame.upcase - 'A' : frame),
          tics: tics,
          action: action.pointer,
          nextstate: CDoom::Statenum.new(next_state),
          misc1: 0, misc2: 0
        )
      end

      # Adds a state into this handler given the name of the sprite,
      # the frame letter or number, the tics/length of the state, and the action it performs.
      #
      # The next state for this added state will be the next state in the handler
      # unless this is the last state in the handler, in which case it will default to 0 (a null state)
      # or whatever you specify with `StateHandler#loop` or <br>
      # `StateHandler#goto(handler : StateHandler)`/`StateHandler#goto(state_num : Int32)`
      #
      # The action is given as a Proc
      def add(name : String, frame : Char | Int, tics : Int32, action : Proc(Nil))
        Doocr.sprnames << name unless Doocr.sprnames.includes?(name)
        next_state = @states.size + 1
        @state_index = @states.size if @state_index == -1
        @states << CDoom::State.new(
          sprite: CDoom::Spritenum.new(Doocr.sprnames.index!(name)),
          frame: (frame.is_a?(Char) ? frame.upcase - 'A' : frame),
          tics: tics,
          action: action,
          nextstate: CDoom::Statenum.new(next_state),
          misc1: 0, misc2: 0
        )
      end

      # Adds a state into this handler given the name of the sprite,
      # the frame letter or number, the tics/length of the state, and the action it performs.
      #
      # The next state for this added state will be the next state in the handler
      # unless this is the last state in the handler, in which case it will default to 0 (a null state)
      # or whatever you specify with `StateHandler#loop` or <br>
      # `StateHandler#goto(handler : StateHandler)`/`StateHandler#goto(state_num : Int32)`
      #
      # The action is given as a raw function pointer
      def add(name : String, frame : Char | Int, tics : Int32, action : Void*)
        Doocr.sprnames << name unless Doocr.sprnames.includes?(name)
        next_state = @states.size + 1
        @state_index = @states.size if @state_index == -1
        @states << CDoom::State.new(
          sprite: CDoom::Spritenum.new(Doocr.sprnames.index!(name)),
          frame: (frame.is_a?(Char) ? frame.upcase - 'A' : frame),
          tics: tics,
          action: action,
          nextstate: CDoom::Statenum.new(next_state),
          misc1: 0, misc2: 0
        )
      end

      # Adds a state into this handler given the name of the sprite,
      # the frame letter or number, and the tics/length of the state.
      #
      # The next state for this added state will be the next state in the handler
      # unless this is the last state in the handler, in which case it will default to 0 (a null state)
      # or whatever you specify with `StateHandler#loop` or <br>
      # `StateHandler#goto(handler : StateHandler)`/`StateHandler#goto(state_num : Int32)`
      #
      # The action is null
      def add(name : String, frame : Char | Int, tics : Int32)
        Doocr.sprnames << name unless Doocr.sprnames.includes?(name)
        next_state = @states.size + 1
        @state_index = @states.size if @state_index == -1
        @states << CDoom::State.new(
          sprite: CDoom::Spritenum.new(Doocr.sprnames.index!(name)),
          frame: (frame.is_a?(Char) ? frame.upcase - 'A' : frame),
          tics: tics,
          action: Pointer(Void).null,
          nextstate: CDoom::Statenum.new(next_state),
          misc1: 0, misc2: 0
        )
      end

      # Adds a fullbright state into this handler given the name of the sprite,
      # the frame letter or number, the tics/length of the state, and the action it performs.
      #
      # The next state for this added state will be the next state in the handler
      # unless this is the last state in the handler, in which case it will default to 0 (a null state)
      # or whatever you specify with `StateHandler#loop` or <br>
      # `StateHandler#goto(handler : StateHandler)`/`StateHandler#goto(state_num : Int32)`
      #
      # The action is given as a do-end block
      def add_lit(name : String, frame : Char | Int, tics : Int32, &action)
        frame = frame.is_a?(Char) ? frame.upcase - 'A' : frame
        add(name, frame | 0x8000, tics, action.pointer)
      end

      # Adds a fullbright state into this handler given the name of the sprite,
      # the frame letter or number, the tics/length of the state, and the action it performs.
      #
      # The next state for this added state will be the next state in the handler
      # unless this is the last state in the handler, in which case it will default to 0 (a null state)
      # or whatever you specify with `StateHandler#loop` or <br>
      # `StateHandler#goto(handler : StateHandler)`/`StateHandler#goto(state_num : Int32)`
      #
      # The action is given as a proc
      def add_lit(name : String, frame : Char | Int, tics : Int32, action : Proc(Nil))
        frame = frame.is_a?(Char) ? frame.upcase - 'A' : frame
        add(name, frame | 0x8000, tics, action)
      end

      # Adds a fullbright state into this handler given the name of the sprite,
      # the frame letter or number, the tics/length of the state, and the action it performs.
      #
      # The next state for this added state will be the next state in the handler
      # unless this is the last state in the handler, in which case it will default to 0 (a null state)
      # or whatever you specify with `StateHandler#loop` or <br>
      # `StateHandler#goto(handler : StateHandler)`/`StateHandler#goto(state_num : Int32)`
      #
      # The action is given as a raw function pointer
      def add_lit(name : String, frame : Char | Int, tics : Int32, action : Void*)
        frame = frame.is_a?(Char) ? frame.upcase - 'A' : frame
        add(name, frame | 0x8000, tics, action)
      end

      # Adds a fullbright state into this handler given the name of the sprite,
      # the frame letter or number, and the tics/length of the state
      #
      # The next state for this added state will be the next state in the handler
      # unless this is the last state in the handler, in which case it will default to 0 (a null state)
      # or whatever you specify with `StateHandler#loop` or <br>
      # `StateHandler#goto(handler : StateHandler)`/`StateHandler#goto(state_num : Int32)`
      #
      # The action is null
      def add_lit(name : String, frame : Char | Int, tics : Int32)
        frame = frame.is_a?(Char) ? frame.upcase - 'A' : frame
        add(name, frame | 0x8000, tics)
      end

      # Makes the last state in this handler's next state be pointed
      # to the first state in the handler
      def loop
        @goto = self
      end

      # Makes the last state in this handler's next state be pointed
      # to the first state of another handler
      def goto(@goto : StateHandler)
      end

      # Makes the last state in this handler's next state be pointed
      # to a state number
      def goto(@goto_num : Int32)
      end

      protected def parse : CDoom::Statenum
        @state_index = @states.empty? ? 0 : Doocr.states.size
        @states.size.times do |i|
          (@states.to_unsafe + i).value.nextstate =
            CDoom::Statenum.new(@states[i].nextstate.value + @state_index)
        end
        Doocr.states.concat(@states)

        return CDoom::Statenum.new(state_index)
      end

      protected def parse_ends
        if handler = @goto
          (Doocr.states.to_unsafe + @state_index + @states.size - 1).value.nextstate =
            CDoom::Statenum.new(handler.state_index)
        else
          (Doocr.states.to_unsafe + @state_index + @states.size - 1).value.nextstate =
            CDoom::Statenum.new(@goto_num)
        end
      end
    end

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

    @@weapons = [] of Weapon

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
