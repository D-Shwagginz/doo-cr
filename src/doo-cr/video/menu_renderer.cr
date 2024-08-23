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

module Doocr::Video
  class MenuRenderer
    @@cursor : Array(Char) = ['_']

    @wad : Wad
    @screen : DrawScreen

    @cache : PatchCache

    def initialize(@wad : Wad, @screen : DrawScreen)
      @cache = PatchCache.new(@wad)
    end

    def render(menu : DoomMenu)
      selectable = menu.current.as?(SelectableMenu)
      draw_selectable_menu(selectable) if selectable != nil

      save = menu.current.as?(SaveMenu)
      draw_save_menu(save) if save != nil

      yes_no = menu.current.as?(YesNoConfirm)
      draw_text(yes_no.text) if yes_no != nil

      press_any_key = menu.current.as?(PressAnyKey)
      draw_text(press_any_key.text) if press_any_key != nil

      quit = menu.current.as?(QuitConfirm)
      draw_text(quit.text) if quit != nil

      help = menu.current.as?(HelpScreen)
      draw_help(help) if help != nil
    end

    private def draw_selectable_menu(selectable : SelectableMenu)
      selectable.name.size.times do |i|
        draw_menu_patch(
          selectable.name[i],
          selectable.title_x[i],
          selectable.title_y[i]
        )
      end

      selectable.items.each do |item|
        draw_menu_item(selectable.menu, item)
      end

      choice = selectable.choice
      skull = selectable.menu.tics / 8 % 2 == 0 ? "M_SKULL1" : "M_SKULL2"
      draw_menu_patch(skull, choice.skull_x, choice.skull_y)
    end

    private def draw_save_menu(save : SaveMenu)
      save.name.size.times do |i|
        draw_menu_patch(
          save.name[i],
          save.title_x[i],
          save.title_y[i]
        )
      end

      save.items.each do |item|
        draw_menu_item(save.menu, item)
      end

      choice = save.choice
      skull = save.menu.tics / 8 % 2 == 0 ? "M_SKULL1" : "M_SKULL2"
      draw_menu_patch(skull, choice.skull_x, choice.skull_y)
    end

    private def draw_load_menu(load : LoadMenu)
      load.name.size.times do |i|
        draw_menu_patch(
          load.name[i],
          load.title_x[i],
          load.title_y[i]
        )
      end

      load.items.each do |item|
        draw_menu_item(load.menu, item)
      end

      choice = load.choice
      skull = load.menu.tics / 8 % 2 == 0 ? "M_SKULL1" : "M_SKULL2"
      draw_menu_patch(skull, choice.skull_x, choice.skull_y)
    end

    private def draw_menu_patch(name : String, x : Int32, y : Int32)
      scale = @screen.width / 320
      @screen.draw_patch(@cache[name], scale * x, scale * y, scale)
    end

    private def draw_menu_text(text : Array(Char), x : Int32, y : Int32)
      scale = @screen.width / 320
      @screen.draw_text(text, scale * x, scale * y, scale)
    end

    private def draw_simple_menu_item(item : SimpleMenuItem)
      draw_menu_patch(item.name, item.item_x, item.item_y)
    end

    private def draw_toggle_menu_item(item : ToggleMenuItem)
      draw_menu_patch(item.name, item.item_x, item.item_y)
      draw_menu_patch(item.state, item.state_x, item.item_y)
    end

    private def draw_slider_menu_item(item : SliderMenuItem)
      draw_menu_patch(item.name, item.item_x, item.item_y)

      draw_menu_patch("M_THERML", item.slider_x, item.slider_y)
      item.slider_length.times do |i|
        x = item.slider_x + 8 * (1 + i)
        draw_menu_patch("M_THERMM", x, item.slider_y)
      end

      endr = item.slider_x + 8 * (1 + item.slider_length)
      draw_menu_patch("MTHERMR", endr, item.slider_y)

      pos = item.slider_x + 8 * (1 + item.slider_position)
      draw_menu_patch("M_THERMO", pos, item.slider_y)
    end

    @empty_text : Array(Char) = "EMPTY SLOT".chars

    private def draw_text_box_menu_item(item : TextBoxMenuItem, tics : Int32)
      length = 24
      draw_menu_patch("M_LSLEFT", item.item_x, item.item_y)
      length.times do |i|
        x = item.item_x + 8 * (1 + i)
        draw_menu_patch("M_LSCNTR", x, item.item_y)
      end
      draw_menu_patch("M_LSRGHT", item.item_x + 8 * (1 + length), item.item_y)

      if !item.editing
        text = item.text != nil ? item.text : @empty_text
        draw_menu_text(text, item.item_x + 8, item.item_y)
      else
        draw_menu_item(item.text, item.item_x + 8, item.item_y)
        if tics / 3 % 2 == 0
          text_width = @screen.measure_text(item.text, 1)
          draw_menu_text(@@cursor, item.item_x + 8 + text_width, item.item_y)
        end
      end
    end

    private def draw_text(text : Array(String))
      scale = @screen.width / 320
      height = 7 * scale * text.size

      text.size.times do |i|
        x = (@screen.width - @screen.measure_text(text[i], scale)) / 2
        y = (@screen.height - height) / 2 + 7 * scale * (i + 1)
        @screen.draw_text(text[i], x, y, scale)
      end
    end

    private def draw_help(help : HelpScreen)
      skull = help.menu.tics / 8 % 2 == 0 ? "M_SKULL1" : "M_SKULL2"

      if help.menu.options.game_mode == GameMode::Commercial
        draw_menu_patch("HELP", 0, 0)
        draw_menu_patch(skulll, 298, 160)
      else
        if help.page == 0
          draw_menu_patch("HELP1", 0, 0)
          draw_menu_patch(skull, 298, 170)
        else
          draw_menu_patch("HELP2", 0, 0)
          draw_menu_patch(skull, 248, 180)
        end
      end
    end
  end
end
