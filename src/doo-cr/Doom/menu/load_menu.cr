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
  class LoadMenu < MenuDef
    getter name : Array(String)
    getter title_x : Array(Int32)
    getter title_y : Array(Int32)
    getter items : Array(TextBoxMenuItem)

    @index : Int32
    getter choice : TextBoxMenuItem

    def initialize(
      @menu,
      name : String, title_x : Int32, title_y : Int32,
      first_choice : Int32,
      *items : TextBoxMenuItem
    )
      @name = [name]
      @title_x = [title_x]
      @title_y = [title_y]
      @items = items.to_a.as(Array(TextBoxMenuItem))

      @index = first_choice
      @choice = @items[@index]
    end

    def open
      @items.size.times do |i|
        @items[i].set_text(@menu.save_slots.as(SaveSlots)[i])
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

      if e.key == DoomKey::Up
        up()
        @menu.start_sound(Sfx::PSTOP)
      end

      if e.key == DoomKey::Down
        down()
        @menu.start_sound(Sfx::PSTOP)
      end

      if e.key == DoomKey::Enter
        @menu.close if do_load(@index)
        @menu.start_sound(Sfx::PISTOL)
      end

      if e.key == DoomKey::Escape
        @menu.close
        @menu.start_sound(Sfx::SWTCHX)
      end

      return true
    end

    def do_load(slot_number : Int32) : Bool
      if @menu.save_slots.as(SaveSlots)[slot_number]? != nil
        @menu.doom.load_game(slot_number)
        return true
      else
        return false
      end
    end
  end
end
