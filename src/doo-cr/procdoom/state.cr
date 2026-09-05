module Doocr::Mod
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
end
