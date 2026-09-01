module Doocr
  # -- Macros for quick key polling --
  macro poll_key(doomkey, raylibkey)
  was_down = Doocr.keystates[CDoom::DoomKey::{{doomkey}}.value]
  is_down = Raylib::KeyboardKey::{{raylibkey}}.down?

  Doocr.doom_key_down(CDoom::DoomKey::{{doomkey}}) if is_down && !was_down
  Doocr.doom_key_up(CDoom::DoomKey::{{doomkey}}) if !is_down && was_down
end

  macro poll_two_key(doomkey, raylibkey1, raylibkey2)
  was_down = Doocr.keystates[CDoom::DoomKey::{{doomkey}}.value]
  is_down = Raylib::KeyboardKey::{{raylibkey1}}.down? || Raylib::KeyboardKey::{{raylibkey2}}.down?
  
  Doocr.doom_key_down(CDoom::DoomKey::{{doomkey}}) if is_down && !was_down
  Doocr.doom_key_up(CDoom::DoomKey::{{doomkey}}) if !is_down && was_down
end

  macro poll_button(doombutton, raylibbutton)
  was_down = CDoom.button_states[CDoom::DoomButton::{{doombutton}}.value] != 0
  is_down = Raylib::MouseButton::{{raylibbutton}}.down?
  Doocr.doom_button_down(CDoom::DoomButton::{{doombutton}}) if is_down && !was_down
  Doocr.doom_button_up(CDoom::DoomButton::{{doombutton}}) if !is_down && was_down
end

  def self.doom_key_down(key : CDoom::DoomKey)
    @@keystates[key.value] = true
    event = CDoom::Event.new
    event.type = CDoom::Evtype::Keydown
    event.data1 = key.value
    CDoom.d_post_event(pointerof(event))
  end

  def self.doom_key_up(key : CDoom::DoomKey)
    @@keystates[key.value] = false
    event = CDoom::Event.new
    event.type = CDoom::Evtype::Keyup
    event.data1 = key.value
    CDoom.d_post_event(pointerof(event))
  end

  def self.doom_button_down(button : CDoom::DoomButton)
    CDoom.button_states[button.value] = 1

    event = CDoom::Event.new
    event.type = CDoom::Evtype::Mouse
    event.data1 =
      (CDoom.button_states[0]) |
        (CDoom.button_states[1] != 0 ? 2 : 0) |
        (CDoom.button_states[2] != 0 ? 4 : 0)
    event.data2 = 0
    event.data3 = 0
    CDoom.d_post_event(pointerof(event))
  end

  def self.doom_button_up(button : CDoom::DoomButton)
    CDoom.button_states[button.value] = 0

    event = CDoom::Event.new
    event.type = CDoom::Evtype::Mouse
    event.data1 =
      (CDoom.button_states[0]) |
        (CDoom.button_states[1] != 0 ? 2 : 0) |
        (CDoom.button_states[2] != 0 ? 4 : 0)

    event.data1 =
      event.data1 ^
        (CDoom.button_states[0]) ^
        (CDoom.button_states[1] != 0 ? 2 : 0) ^
        (CDoom.button_states[2] != 0 ? 4 : 0)

    event.data2 = 0
    event.data3 = 0
    CDoom.d_post_event(pointerof(event))
  end

  def self.doom_mouse_move(delta_x : Int32, delta_y : Int32)
    event = CDoom::Event.new
    event.type = CDoom::Evtype::Mouse
    event.data1 =
      (CDoom.button_states[0]) |
        (CDoom.button_states[1] != 0 ? 2 : 0) |
        (CDoom.button_states[2] != 0 ? 4 : 0)
    event.data2 = delta_x
    event.data3 = -delta_y

    CDoom.d_post_event(pointerof(event)) if event.data2 != 0 || event.data3 != 0
  end

  def self.i_tactile(on : LibC::Int, off : LibC::Int, total : LibC::Int)
  end

  def self.i_base_ticcmd : CDoom::Ticcmd*
    return pointerof(CDoom.emptycmd)
  end

  @@mouse_queued = Raylib::Vector2.new

  def self.i_poll_mouse
    Raylib.poll_input_events
    delta = Raylib.get_mouse_delta * 2 # Rough sensitivity increase
    @@mouse_queued = Raylib::Vector2.new(
      x: @@mouse_queued.x + delta.x,
      y: @@mouse_queued.y + delta.y
    )
  end
end
