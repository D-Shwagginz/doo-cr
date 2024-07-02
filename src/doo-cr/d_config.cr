module Doocr
  DEFAULTCONFIG = {
    "mouse_sensitivity" => 5,
    "sfx_volume"        => 8,
    "music_volume"      => 8,
    "show_messages"     => 1,

    "key_right"       => Raylib::KeyboardKey::Right,
    "key_left"        => Raylib::KeyboardKey::Left,
    "key_up"          => Raylib::KeyboardKey::Up,
    "key_down"        => Raylib::KeyboardKey::Down,
    "key_strafeleft"  => Raylib::KeyboardKey::Comma,
    "key_straferight" => Raylib::KeyboardKey::Period,

    "key_fire"   => Raylib::KeyboardKey::RightControl,
    "key_use"    => Raylib::KeyboardKey::Space,
    "key_strafe" => Raylib::KeyboardKey::RightAlt,
    "key_speed"  => Raylib::KeyboardKey::RightShift,

    "use_mouse"      => 1,
    "mouseb_fire"    => 0,
    "mouseb_strafe"  => 1,
    "mouseb_forward" => 2,

    "use_joystick" => 0,
    "joyb_fire"    => 0,
    "joyb_strafe"  => 1,
    "joyb_use"     => 3,
    "joyb_speed"   => 2,

    "screenblocks" => 9,
    "detaillevel"  => 0,

    "snd_channels" => 3,

    "usegamma" => 0,

    "chatmacro0" => HUSTR_CHATMACRO0,
    "chatmacro1" => HUSTR_CHATMACRO1,
    "chatmacro2" => HUSTR_CHATMACRO2,
    "chatmacro3" => HUSTR_CHATMACRO3,
    "chatmacro4" => HUSTR_CHATMACRO4,
    "chatmacro5" => HUSTR_CHATMACRO5,
    "chatmacro6" => HUSTR_CHATMACRO6,
    "chatmacro7" => HUSTR_CHATMACRO7,
    "chatmacro8" => HUSTR_CHATMACRO8,
    "chatmacro9" => HUSTR_CHATMACRO9,
  }

  @@config = {
    "mouse_sensitivity" => 5,
    "sfx_volume"        => 8,
    "music_volume"      => 8,
    "show_messages"     => 1,

    "key_right"       => Raylib::KeyboardKey::Right,
    "key_left"        => Raylib::KeyboardKey::Left,
    "key_up"          => Raylib::KeyboardKey::Up,
    "key_down"        => Raylib::KeyboardKey::Down,
    "key_strafeleft"  => Raylib::KeyboardKey::Comma,
    "key_straferight" => Raylib::KeyboardKey::Period,

    "key_fire"   => Raylib::KeyboardKey::RightControl,
    "key_use"    => Raylib::KeyboardKey::Space,
    "key_strafe" => Raylib::KeyboardKey::RightAlt,
    "key_speed"  => Raylib::KeyboardKey::RightShift,

    "use_mouse"      => 1,
    "mouseb_fire"    => 0,
    "mouseb_strafe"  => 1,
    "mouseb_forward" => 2,

    "use_joystick" => 0,
    "joyb_fire"    => 0,
    "joyb_strafe"  => 1,
    "joyb_use"     => 3,
    "joyb_speed"   => 2,

    "screenblocks" => 9,
    "detaillevel"  => 0,

    "snd_channels" => 3,

    "usegamma" => 0,

    "chatmacro0" => HUSTR_CHATMACRO0,
    "chatmacro1" => HUSTR_CHATMACRO1,
    "chatmacro2" => HUSTR_CHATMACRO2,
    "chatmacro3" => HUSTR_CHATMACRO3,
    "chatmacro4" => HUSTR_CHATMACRO4,
    "chatmacro5" => HUSTR_CHATMACRO5,
    "chatmacro6" => HUSTR_CHATMACRO6,
    "chatmacro7" => HUSTR_CHATMACRO7,
    "chatmacro8" => HUSTR_CHATMACRO8,
    "chatmacro9" => HUSTR_CHATMACRO9,
  }

  # Current Movement Config
  @@forwardmove : Array(Int32) = [0x19, 0x32]
  @@sidemove : Array(Int32) = [0x18, 0x28]
  @@angleturn : Array(Int32) = [640, 1280, 320] # + slow turn
end
