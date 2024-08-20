module Doocr
  class TicCmdButtons
    class_getter attack : UInt8 = 1

    # Use button, to open doors, activate switches.
    class_getter use : UInt8 = 2

    # Flag: game events, not really buttons.
    class_getter special : UInt8 = 128
    class_getter special_mask : UInt8 = 3

    # Flag, weapon change pending.
    # If true, the next 3 bits hold weapon num.
    class_getter change : UInt8 = 4

    # The 3bit weapon mask and shift, convenience.
    class_getter weapon_mask : UInt8 = 8_u8 + 16_u8 + 32_u8
    class_getter weapon_shift : UInt8 = 3

    # Pause the game.
    class_getter pause : UInt8 = 1
  end
end
