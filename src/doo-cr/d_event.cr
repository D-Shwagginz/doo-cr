# Event Data

module Doocr
  #
  # GLOBAL VARIABLES
  #
  MAXEVENTS = 64

  #
  # Event handling.
  #

  # Input event types.
  enum EvType
    KeyDown
    KeyUp
    Mouse
    Joystick
  end

  enum GameAction
    Nothing
    Loadlevel
    Newgame
    Loadgame
    Savegame
    Playdemo
    Completed
    Victory
    Worlddone
    Screenshot
  end

  #
  # Button/action code definitions.
  #
  enum ButtonCode
    # Press "Fire".
    Attack = 1
    # Use button, to open doors, activate switches.
    Use = 2

    # Flag: game events, not really buttons.
    Special     = 128
    SpecialMask =   3

    # Flag, weapon change pending.
    # If true, the next 3 bits hold weapon num.
    Change = 4
    # The 3bit weapon mask and shift, convenience.
    WeapenMask  = (8 + 16 + 32)
    WeaponShift = 3

    # Pause the game.
    SPause = 1
    # Save the game at each console.
    SSaveGame = 2

    # Savegame slot numbers
    #  occupy the second byte of buttons.
    SSavemask  = (4 + 8 + 16)
    SSaveShift = 2
  end

  # Event structure.
  struct Event
    property type : EvType = EvType::KeyDown
    property data1 : Int32 = 0 # keys / mouse/joystick buttons
    property data2 : Int32 = 0 # mouse/joystick x move
    property data3 : Int32 = 0 # mouse/joystick y move
  end
end
