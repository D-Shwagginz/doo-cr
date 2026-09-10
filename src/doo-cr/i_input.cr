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
# ==> System input

module Doocr
  # -- Macros for quick key polling --
  macro poll_key(doomkey, raylibkey)
  was_down = Doocr.keystates[Doocr::DoomKey::{{doomkey}}.value]
  is_down = Raylib::KeyboardKey::{{raylibkey}}.down?

  Doocr.doom_key_down(Doocr::DoomKey::{{doomkey}}) if is_down && !was_down
  Doocr.doom_key_up(Doocr::DoomKey::{{doomkey}}) if !is_down && was_down
end

  macro poll_two_key(doomkey, raylibkey1, raylibkey2)
  was_down = Doocr.keystates[Doocr::DoomKey::{{doomkey}}.value]
  is_down = Raylib::KeyboardKey::{{raylibkey1}}.down? || Raylib::KeyboardKey::{{raylibkey2}}.down?
  
  Doocr.doom_key_down(Doocr::DoomKey::{{doomkey}}) if is_down && !was_down
  Doocr.doom_key_up(Doocr::DoomKey::{{doomkey}}) if !is_down && was_down
end

  macro poll_button(doombutton, raylibbutton)
  was_down = Doocr.button_states[Doocr::DoomButton::{{doombutton}}.value] != 0
  is_down = Raylib::MouseButton::{{raylibbutton}}.down?
  Doocr.doom_button_down(Doocr::DoomButton::{{doombutton}}) if is_down && !was_down
  Doocr.doom_button_up(Doocr::DoomButton::{{doombutton}}) if !is_down && was_down
end

  def self.doom_key_down(key : Doocr::DoomKey)
    @@keystates[key.value] = true
    event = CDoom::Event.new
    event.type = Doocr::Evtype::Keydown
    event.data1 = key.value
    CDoom.d_post_event(pointerof(event))
  end

  def self.doom_key_up(key : Doocr::DoomKey)
    @@keystates[key.value] = false
    event = CDoom::Event.new
    event.type = Doocr::Evtype::Keyup
    event.data1 = key.value
    CDoom.d_post_event(pointerof(event))
  end

  def self.doom_button_down(button : Doocr::DoomButton)
    Doocr.button_states[button.value] = 1

    event = CDoom::Event.new
    event.type = Doocr::Evtype::Mouse
    event.data1 =
      (Doocr.button_states[0]) |
        (Doocr.button_states[1] != 0 ? 2 : 0) |
        (Doocr.button_states[2] != 0 ? 4 : 0)
    event.data2 = 0
    event.data3 = 0
    CDoom.d_post_event(pointerof(event))
  end

  def self.doom_button_up(button : Doocr::DoomButton)
    Doocr.button_states[button.value] = 0

    event = CDoom::Event.new
    event.type = Doocr::Evtype::Mouse
    event.data1 =
      (Doocr.button_states[0]) |
        (Doocr.button_states[1] != 0 ? 2 : 0) |
        (Doocr.button_states[2] != 0 ? 4 : 0)

    event.data1 =
      event.data1 ^
        (Doocr.button_states[0]) ^
        (Doocr.button_states[1] != 0 ? 2 : 0) ^
        (Doocr.button_states[2] != 0 ? 4 : 0)

    event.data2 = 0
    event.data3 = 0
    CDoom.d_post_event(pointerof(event))
  end

  def self.doom_mouse_move(delta_x : Int32, delta_y : Int32)
    event = CDoom::Event.new
    event.type = Doocr::Evtype::Mouse
    event.data1 =
      (Doocr.button_states[0]) |
        (Doocr.button_states[1] != 0 ? 2 : 0) |
        (Doocr.button_states[2] != 0 ? 4 : 0)
    event.data2 = delta_x
    event.data3 = -delta_y

    CDoom.d_post_event(pointerof(event)) if event.data2 != 0 || event.data3 != 0
  end

  def self.i_tactile(on : LibC::Int, off : LibC::Int, total : LibC::Int)
  end

  def self.i_base_ticcmd : CDoom::Ticcmd*
    return pointerof(@@emptycmd)
  end

  @@emptycmd = CDoom::Ticcmd.new
  @@mouse_queued = Raylib::Vector2.new

  def self.i_poll_mouse
    return if @@headless
    Raylib.poll_input_events
    delta = Raylib.get_mouse_delta * 2 # Rough sensitivity increase
    @@mouse_queued = Raylib::Vector2.new(
      x: @@mouse_queued.x + delta.x,
      y: @@mouse_queued.y + delta.y
    )
  end
end
