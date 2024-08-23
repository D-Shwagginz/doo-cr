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

module Doocr
  class SaveMenu < MenuDef
    getter name : Array(String)
    getter title_x : Array(Int32)
    getter title_y : Array(Int32)
    getter items : Array(TextBoxMenuItem)

    @index : Int32
    getter choice : TextBoxMenuItem

    @text_input : TextInput | Nil = nil

    getter last_save_slot : Int32

    def initialize(
      @menu,
      name : String, title_x : Int32, title_y : Int32,
      first_choice : Int32,
      *items : TextBoxMenuItem
    )
      @name = [name]
      @title_x = [title_x]
      @title_y = [title_y]
      @items = items

      @index = first_choice
      @choice = @items[@index]

      @last_save_slot = -1
    end

    def open
      if (@menu.doom.state != DoomState::Game ||
         @menu.doom.game.state != GameState::Level)
        @menu.notify_save_failed
        return
      end

      @items.size.times do |i|
        @items[i].set_text(@menu.save_slots[i])
      end
    end

    private def up
      @index -= 1
      @index = @items.size - 1 if @index < 0
      @choice = @items[@index]
    end

    private def down
      @index += 1
      @index = 0 if @index >= @items.size
      @choice = @items[@index]
    end

    def do_event(e : DoomEvent) : Bool
      return true if e.type != EventType::KeyDown

      if @text_input != nil
        result = @text_input.do_event(e)

        if @text_input.state == TextInputState::Canceled
          @text_input = nil
        elsif @text_input.state == TextInputState::Finished
          @text_input = nil
        end

        return true if result
      end

      if e.key == DoomKey::Up
        up()
        @menu.start_sound(Sfx::PSTOP)
      end

      if e.key == DoomKey::Down
        down()
        @menu.start_sound(Sfx::PSTOP)
      end

      if e.key == DoomKey::Enter
        @text_input = @choice.edit(->{ do_save(index) })
        @menu.start_sound(Sfx::PISTOL)
      end

      if e.key == DoomKey::Escape
        @menu.close
        @menu.start_sound(Sfx::SWTCHX)
      end

      return true
    end

    def do_save(slot_number : Int32)
      string = String.build do |buffer|
        @items[slot_number].text.each do |char|
          buffer << char
        end
      end
      @menu.save_slots[slot_number] = string
      if @menu.doom.save_game(slot_number, @menu.save_slots[slot_number])
        @menu.close
        @last_save_slot = slot_number
      else
        @menu.notify_save_failed
      end
      @menu.start_sound(Sfx::PISTOL)
    end
  end
end
