#
# Copyright (C) 1993-1996 Id Software, Inc.
# Copyright (C) 2019-2020 Nobuaki Tanaka
# Copyright (C) 2024 Devin Shwagginz
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#

require "../user_input/i_user_input.cr"

module Doocr::SFML
  class SFMLUserInput
    include UserInput::IUserInput

    alias Keyboard = SF::Keyboard
    alias Key = SF::Keyboard::Key
    alias Mouse = SF::Mouse
    alias Button = SF::Mouse::Button

    @config : Config

    @window : SF::RenderWindow | Nil = nil

    @weapon_keys : Array(Bool) = [] of Bool
    @turn_held : Int32 = 0

    @use_mouse : Bool = false
    @mouse_grabbed : Bool = false
    @mouse_x : Int32 = 0
    @mouse_y : Int32 = 0
    @mouse_prev_x : Int32 = 0
    @mouse_prev_y : Int32 = 0
    @mouse_delta_x : Int32 = 0
    @mouse_delta_y : Int32 = 0

    def initialize(@config, @window, doom : SFMLDoom, @use_mouse : Bool)
      begin
        print("Initialize user input: ")

        @weapon_keys = Array.new(7, false)
        @turn_held = 0

        puts "OK"
      rescue e
        puts "Failed"
        raise e
      end
    end

    def build_tic_cmd(cmd : TicCmd)
      key_forward = is_pressed(@config.key_forward)
      key_backward = is_pressed(@config.key_backward)
      key_strafeleft = is_pressed(@config.key_strafeleft)
      key_straferight = is_pressed(@config.key_straferight)
      key_turnleft = is_pressed(@config.key_turnleft)
      key_turnright = is_pressed(@config.key_turnright)
      key_fire = is_pressed(@config.key_fire)
      key_use = is_pressed(@config.key_use)
      key_run = is_pressed(@config.key_run)
      key_strafe = is_pressed(@config.key_strafe)

      @weapon_keys[0] = Keyboard.key_pressed?(Key::Num1)
      @weapon_keys[1] = Keyboard.key_pressed?(Key::Num2)
      @weapon_keys[2] = Keyboard.key_pressed?(Key::Num3)
      @weapon_keys[3] = Keyboard.key_pressed?(Key::Num4)
      @weapon_keys[4] = Keyboard.key_pressed?(Key::Num5)
      @weapon_keys[5] = Keyboard.key_pressed?(Key::Num6)
      @weapon_keys[6] = Keyboard.key_pressed?(Key::Num7)

      cmd.clear

      strafe = key_strafe
      speed = key_run ? 1 : 0
      forward = 0
      side = 0

      speed = 1 - speed if @config.game_alwaysrun

      if key_turnleft || key_turnright
        @turn_held += 1
      else
        @turn_held = 0
      end

      turn_speed = 0
      if @turn_held < PlayerBehavior.slow_turn_tics
        turn_speed = 2
      else
        turn_speed = speed
      end

      if strafe
        side += PlayerBehavior.side_move[speed] if key_turnright
        side -= PlayerBehavior.side_move[speed] if key_turnleft
      else
        cmd.angle_turn -= PlayerBehavior.angle_turn[turn_speed].to_i16 if key_turnright
        cmd.angle_turn += PlayerBehavior.angle_turn[turn_speed].to_i16 if key_turnleft
      end

      forward += PlayerBehavior.forward_move[speed] if key_forward
      forward -= PlayerBehavior.forward_move[speed] if key_backward

      side -= PlayerBehavior.side_move[speed] if key_strafeleft
      side += PlayerBehavior.side_move[speed] if key_straferight

      cmd.buttons |= TicCmdButtons.attack if key_fire

      cmd.buttons |= TicCmdButtons.use if key_use

      # Check weapon keys.
      @weapon_keys.size.times do |i|
        if @weapon_keys[i]
          cmd.buttons |= TicCmdButtons.change
          cmd.buttons |= (i << TicCmdButtons.weapon_shift).to_u8
          break
        end
      end

      update_mouse()
      ms = 0.5_f32 * @config.mouse_sensitivity
      mx = (ms * @mouse_delta_x).round_even
      my = (ms * -@mouse_delta_y).round_even
      forward += my
      if strafe
        side += mx * 2
      else
        cmd.angle_turn -= (mx * 0x8).to_i16
      end

      if forward > PlayerBehavior.max_move
        forward = PlayerBehavior.max_move
      elsif forward < -PlayerBehavior.max_move
        forward = -PlayerBehavior.max_move
      end

      if side > PlayerBehavior.max_move
        side = PlayerBehavior.max_move
      elsif side < -PlayerBehavior.max_move
        side = -PlayerBehavior.max_move
      end

      cmd.forward_move += forward.to_i8
      cmd.side_move += side.to_i8
    end

    private def is_pressed(key_binding : KeyBinding) : Bool
      key_binding.keys.each do |key|
        return true if Keyboard.key_pressed?(SFMLUserInput.doom_to_sfml(key))
      end

      if @mouse_grabbed
        key_binding.mouse_buttons.each do |mouse_button|
          return true if Mouse.button_pressed?(Button.new(mouse_button.to_i32))
        end
      end

      return false
    end

    def reset
      return if !@use_mouse

      @mouse_x = Mouse.position.x
      @mouse_y = Mouse.position.y
      @mouse_prev_x = @mouse_x
      @mouse_prev_y = @mouse_y
      @mouse_delta_x = 0
      @mouse_delta_y = 0
    end

    def grab_mouse
      return if !@use_mouse

      if !@mouse_grabbed
        @window.as(SF::RenderWindow).mouse_cursor_grabbed = true
        @window.as(SF::RenderWindow).mouse_cursor_visible = false
        @mouse_grabbed = true
        @mouse_x = Mouse.position.x
        @mouse_y = Mouse.position.y
        @mouse_prev_x = @mouse_x
        @mouse_prev_y = @mouse_y
        @mouse_delta_x = 0
        @mouse_delta_y = 0
      end
      Number
    end

    def release_mouse
      return if !@use_mouse

      if @mouse_grabbed
        @window.as(SF::RenderWindow).mouse_cursor_grabbed = false
        @window.as(SF::RenderWindow).mouse_cursor_visible = true
        Mouse.position = SF::Vector2.new(@window.as(SF::RenderWindow).size.x - 10, @window.as(SF::RenderWindow).size.y - 10)
        @mouse_grabbed = false
      end
    end

    private def update_mouse
      return if !@use_mouse

      if @mouse_grabbed
        @mouse_prev_x = @mouse_x
        @mouse_prev_y = @mouse_y
        @mouse_x = Mouse.position.x
        @mouse_y = Mouse.position.y
        @mouse_delta_x = @mouse_x - @mouse_prev_x
        @mouse_delta_y = @mouse_y - @mouse_prev_y

        @mouse_delta_y = 0 if @config.mouse_disableyaxis
      end
    end

    def finalize
      puts "Shutdown user input."
    end

    def self.sfml_to_doom(sfml_key : Key) : DoomKey
      case sfml_key
      when Key::Space then return DoomKey::Space
        # when Key::Apostrophe then return DoomKey::Apostrophe
      when Key::Comma  then return DoomKey::Comma
      when Key::Minus  then return DoomKey::Subtract
      when Key::Period then return DoomKey::Period
      when Key::Slash  then return DoomKey::Slash
      when Key::Num0   then return DoomKey::Num0
        # when Key::D0 then return DoomKey::D0
      when Key::Num1         then return DoomKey::Num1
      when Key::Num2         then return DoomKey::Num2
      when Key::Num3         then return DoomKey::Num3
      when Key::Num4         then return DoomKey::Num4
      when Key::Num5         then return DoomKey::Num5
      when Key::Num6         then return DoomKey::Num6
      when Key::Num7         then return DoomKey::Num7
      when Key::Num8         then return DoomKey::Num8
      when Key::Num9         then return DoomKey::Num9
      when Key::Semicolon    then return DoomKey::Semicolon
      when Key::Equal        then return DoomKey::Equal
      when Key::A            then return DoomKey::A
      when Key::B            then return DoomKey::B
      when Key::C            then return DoomKey::C
      when Key::D            then return DoomKey::D
      when Key::E            then return DoomKey::E
      when Key::F            then return DoomKey::F
      when Key::G            then return DoomKey::G
      when Key::H            then return DoomKey::H
      when Key::I            then return DoomKey::I
      when Key::J            then return DoomKey::J
      when Key::K            then return DoomKey::K
      when Key::L            then return DoomKey::L
      when Key::M            then return DoomKey::M
      when Key::N            then return DoomKey::N
      when Key::O            then return DoomKey::O
      when Key::P            then return DoomKey::P
      when Key::Q            then return DoomKey::Q
      when Key::R            then return DoomKey::R
      when Key::S            then return DoomKey::S
      when Key::T            then return DoomKey::T
      when Key::U            then return DoomKey::U
      when Key::V            then return DoomKey::V
      when Key::W            then return DoomKey::W
      when Key::X            then return DoomKey::X
      when Key::Y            then return DoomKey::Y
      when Key::Z            then return DoomKey::Z
      when Key::LeftBracket  then return DoomKey::LBracket
      when Key::BackSlash    then return DoomKey::Backslash
      when Key::RightBracket then return DoomKey::RBracket
        # when Key::GraveAccent then return DoomKey::GraveAccent
        # when Key::World1 then return DoomKey::World1
        # when Key::World2 then return DoomKey::World2
      when Key::Escape    then return DoomKey::Escape
      when Key::Enter     then return DoomKey::Enter
      when Key::Tab       then return DoomKey::Tab
      when Key::Backspace then return DoomKey::Backspace
      when Key::Insert    then return DoomKey::Insert
      when Key::Delete    then return DoomKey::Delete
      when Key::Right     then return DoomKey::Right
      when Key::Left      then return DoomKey::Left
      when Key::Down      then return DoomKey::Down
      when Key::Up        then return DoomKey::Up
      when Key::PageUp    then return DoomKey::PageUp
      when Key::PageDown  then return DoomKey::PageDown
      when Key::Home      then return DoomKey::Home
      when Key::End       then return DoomKey::End
        # when Key::CapsLock then return DoomKey::CapsLock
        # when Key::ScrollLock then return DoomKey::ScrollLock
        # when Key::NumLock then return DoomKey::NumLock
        # when Key::PrintScreen then return DoomKey::PrintScreen
      when Key::Pause then return DoomKey::Pause
      when Key::F1    then return DoomKey::F1
      when Key::F2    then return DoomKey::F2
      when Key::F3    then return DoomKey::F3
      when Key::F4    then return DoomKey::F4
      when Key::F5    then return DoomKey::F5
      when Key::F6    then return DoomKey::F6
      when Key::F7    then return DoomKey::F7
      when Key::F8    then return DoomKey::F8
      when Key::F9    then return DoomKey::F9
      when Key::F10   then return DoomKey::F10
      when Key::F11   then return DoomKey::F11
      when Key::F12   then return DoomKey::F12
      when Key::F13   then return DoomKey::F13
      when Key::F14   then return DoomKey::F14
      when Key::F15   then return DoomKey::F15
        # when Key::F16 then return DoomKey::F16
        # when Key::F17 then return DoomKey::F17
        # when Key::F18 then return DoomKey::F18
        # when Key::F19 then return DoomKey::F19
        # when Key::F20 then return DoomKey::F20
        # when Key::F21 then return DoomKey::F21
        # when Key::F22 then return DoomKey::F22
        # when Key::F23 then return DoomKey::F23
        # when Key::F24 then return DoomKey::F24
        # when Key::F25 then return DoomKey::F25
      when Key::Keypad0 then return DoomKey::Numpad0
      when Key::Keypad1 then return DoomKey::Numpad1
      when Key::Keypad2 then return DoomKey::Numpad2
      when Key::Keypad3 then return DoomKey::Numpad3
      when Key::Keypad4 then return DoomKey::Numpad4
      when Key::Keypad5 then return DoomKey::Numpad5
      when Key::Keypad6 then return DoomKey::Numpad6
      when Key::Keypad7 then return DoomKey::Numpad7
      when Key::Keypad8 then return DoomKey::Numpad8
      when Key::Keypad9 then return DoomKey::Numpad9
        # when Key::KeypadDecimal then return DoomKey::Decimal
      when Key::KeypadDivide   then return DoomKey::Divide
      when Key::KeypadMultiply then return DoomKey::Multiply
      when Key::KeypadSubtract then return DoomKey::Subtract
      when Key::KeypadAdd      then return DoomKey::Add
      when Key::KeypadEnter    then return DoomKey::Enter
      when Key::KeypadEqual    then return DoomKey::Equal
      when Key::ShiftLeft      then return DoomKey::LShift
      when Key::ControlLeft    then return DoomKey::LControl
      when Key::AltLeft        then return DoomKey::LAlt
        # when Key::SuperLeft then return DoomKey::SuperLeft
      when Key::ShiftRight   then return DoomKey::RShift
      when Key::ControlRight then return DoomKey::RControl
      when Key::AltRight     then return DoomKey::RAlt
        # when Key::SuperRight then return DoomKey::SuperRight
      when Key::Menu then return DoomKey::Menu
      else
        return DoomKey::Unknown
      end
    end

    def self.doom_to_sfml(key : DoomKey) : Key
      case key
      when DoomKey::A        then return Key::A
      when DoomKey::B        then return Key::B
      when DoomKey::C        then return Key::C
      when DoomKey::D        then return Key::D
      when DoomKey::E        then return Key::E
      when DoomKey::F        then return Key::F
      when DoomKey::G        then return Key::G
      when DoomKey::H        then return Key::H
      when DoomKey::I        then return Key::I
      when DoomKey::J        then return Key::J
      when DoomKey::K        then return Key::K
      when DoomKey::L        then return Key::L
      when DoomKey::M        then return Key::M
      when DoomKey::N        then return Key::N
      when DoomKey::O        then return Key::O
      when DoomKey::P        then return Key::P
      when DoomKey::Q        then return Key::Q
      when DoomKey::R        then return Key::R
      when DoomKey::S        then return Key::S
      when DoomKey::T        then return Key::T
      when DoomKey::U        then return Key::U
      when DoomKey::V        then return Key::V
      when DoomKey::W        then return Key::W
      when DoomKey::X        then return Key::X
      when DoomKey::Y        then return Key::Y
      when DoomKey::Z        then return Key::Z
      when DoomKey::Num0     then return Key::Num0
      when DoomKey::Num1     then return Key::Num1
      when DoomKey::Num2     then return Key::Num2
      when DoomKey::Num3     then return Key::Num3
      when DoomKey::Num4     then return Key::Num4
      when DoomKey::Num5     then return Key::Num5
      when DoomKey::Num6     then return Key::Num6
      when DoomKey::Num7     then return Key::Num7
      when DoomKey::Num8     then return Key::Num8
      when DoomKey::Num9     then return Key::Num9
      when DoomKey::Escape   then return Key::Escape
      when DoomKey::LControl then return Key::LControl
      when DoomKey::LShift   then return Key::LShift
      when DoomKey::LAlt     then return Key::LAlt
        # when DoomKey::LSystem then return Key::LSystem
      when DoomKey::RControl then return Key::RControl
      when DoomKey::RShift   then return Key::RShift
      when DoomKey::RAlt     then return Key::RAlt
        # when DoomKey::RSystem then return Key::RSystem
      when DoomKey::Menu      then return Key::Menu
      when DoomKey::LBracket  then return Key::LBracket
      when DoomKey::RBracket  then return Key::RBracket
      when DoomKey::Semicolon then return Key::Semicolon
      when DoomKey::Comma     then return Key::Comma
      when DoomKey::Period    then return Key::Period
        # when DoomKey::Quote then return Key::Quote
      when DoomKey::Slash     then return Key::Slash
      when DoomKey::Backslash then return Key::BackSlash
        # when DoomKey::Tilde then return Key::Tilde
      when DoomKey::Equal then return Key::Equal
        # when DoomKey::Hyphen then return Key::Hyphen
      when DoomKey::Space     then return Key::Space
      when DoomKey::Enter     then return Key::Enter
      when DoomKey::Backspace then return Key::Backspace
      when DoomKey::Tab       then return Key::Tab
      when DoomKey::PageUp    then return Key::PageUp
      when DoomKey::PageDown  then return Key::PageDown
      when DoomKey::End       then return Key::End
      when DoomKey::Home      then return Key::Home
      when DoomKey::Insert    then return Key::Insert
      when DoomKey::Delete    then return Key::Delete
      when DoomKey::Add       then return Key::Add
      when DoomKey::Subtract  then return Key::Subtract
      when DoomKey::Multiply  then return Key::Multiply
      when DoomKey::Divide    then return Key::Divide
      when DoomKey::Left      then return Key::Left
      when DoomKey::Right     then return Key::Right
      when DoomKey::Up        then return Key::Up
      when DoomKey::Down      then return Key::Down
      when DoomKey::Numpad0   then return Key::Num0
      when DoomKey::Numpad1   then return Key::Num1
      when DoomKey::Numpad2   then return Key::Num2
      when DoomKey::Numpad3   then return Key::Num3
      when DoomKey::Numpad4   then return Key::Num4
      when DoomKey::Numpad5   then return Key::Num5
      when DoomKey::Numpad6   then return Key::Num6
      when DoomKey::Numpad7   then return Key::Num7
      when DoomKey::Numpad8   then return Key::Num8
      when DoomKey::Numpad9   then return Key::Num9
      when DoomKey::F1        then return Key::F1
      when DoomKey::F2        then return Key::F2
      when DoomKey::F3        then return Key::F3
      when DoomKey::F4        then return Key::F4
      when DoomKey::F5        then return Key::F5
      when DoomKey::F6        then return Key::F6
      when DoomKey::F7        then return Key::F7
      when DoomKey::F8        then return Key::F8
      when DoomKey::F9        then return Key::F9
      when DoomKey::F10       then return Key::F10
      when DoomKey::F11       then return Key::F11
      when DoomKey::F12       then return Key::F12
      when DoomKey::F13       then return Key::F13
      when DoomKey::F14       then return Key::F14
      when DoomKey::F15       then return Key::F15
      when DoomKey::Pause     then return Key::Pause
      else
        return Key::Unknown
      end
    end

    def max_mouse_sensitivity : Int32
      return 15
    end

    def mouse_sensitivity : Int32
      return @config.mouse_sensitivity
    end

    def mouse_sensitivity=(mouse_sensitivity : Int32)
      @config.mouse_sensitivity = mouse_sensitivity
    end
  end
end
