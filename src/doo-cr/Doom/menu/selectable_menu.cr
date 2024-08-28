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
  class SelectableMenu < MenuDef
    getter name : Array(String)
    getter title_x : Array(Int32)
    getter title_y : Array(Int32)
    getter items : Array(MenuItem)

    @index : Int32
    getter choice : MenuItem

    @text_input : TextInput | Nil = nil

    def initialize(
      @menu,
      name : String, title_x : Int32, title_y : Int32,
      first_choice : Int32,
      *items : MenuItem
    )
      @name = [name]
      @title_x = [title_x]
      @title_y = [title_y]
      @items = [] of MenuItem
      items.each { |item| @items << item.as(MenuItem) }

      @index = first_choice
      @choice = @items[@index]
    end

    def initialize(
      @menu,
      name1 : String, title_x1 : Int32, title_y1 : Int32,
      name2 : String, title_x2 : Int32, title_y2 : Int32,
      first_choice : Int32,
      *items : MenuItem
    )
      @name = [name1, name2]
      @title_x = [title_x1, title_x2]
      @title_y = [title_y1, title_y2]
      @items = [] of MenuItem
      items.each { |item| @items << item.as(MenuItem) }

      @index = first_choice
      @choice = @items[@index]
    end

    def open
      @items.each do |item|
        toggle = item.as?(ToggleMenuItem)
        toggle.as(ToggleMenuItem).reset if toggle != nil

        slider = item.as?(SliderMenuItem)
        slider.as(SliderMenuItem).reset if slider != nil
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
        result = @text_input.as(TextInput).do_event(e)

        if @text_input.as(TextInput).state == TextInputState::Canceled
          @text_input = nil
        elsif @text_input.as(TextInput).state == TextInputState::Finished
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

      if e.key == DoomKey::Left
        toggle = @choice.as?(ToggleMenuItem)
        if toggle != nil
          toggle.as(ToggleMenuItem).down
          @menu.start_sound(Sfx::PISTOL)
        end

        slider = @choice.as?(SliderMenuItem)
        if slider != nil
          slider.as(SliderMenuItem).down
          @menu.start_sound(Sfx::STNMOV)
        end
      end

      if e.key == DoomKey::Right
        toggle = @choice.as?(ToggleMenuItem)
        if toggle != nil
          toggle.as(ToggleMenuItem).up
          @menu.start_sound(Sfx::PISTOL)
        end

        slider = @choice.as?(SliderMenuItem)
        if slider != nil
          slider.as(SliderMenuItem).up
          @menu.start_sound(Sfx::STNMOV)
        end
      end

      if e.key == DoomKey::Enter
        toggle = @choice.as?(ToggleMenuItem)
        if toggle != nil
          toggle.as(ToggleMenuItem).up
          @menu.start_sound(Sfx::PISTOL)
        end

        if simple = @choice.as?(SimpleMenuItem)
          if simple.selectable
            if x = simple.action
              x.call
            end
            if simple.next
              @menu.set_current(simple.next.as(MenuDef))
            else
              @menu.close
            end
          end
          @menu.start_sound(Sfx::PISTOL)
          return true
        end

        if @choice.next != nil
          @menu.set_current(@choice.next.as(MenuDef))
          @menu.start_sound(Sfx::PISTOL)
        end
      end

      if e.key == DoomKey::Escape
        @menu.close
        @menu.start_sound(Sfx::SWTCHX)
      end

      return true
    end
  end
end
