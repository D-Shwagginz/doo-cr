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

require "./menu_def.cr"

module Doocr
  class HelpScreen < MenuDef
    @page_count : Int32

    getter page : Int32 = 0

    def initialize(@menu)
      if @menu.options.game_mode == GameMode::Shareware
        @page_count = 2
      else
        @page_count = 1
      end
    end

    def open
      @page = @page_count - 1
    end

    def do_event(e : DoomEvent) : Bool
      return if e.type != EventType::KeyDown

      if (e.key == DoomKey::Enter ||
         e.key == DoomKey::Space ||
         e.key == DoomKey::LControl ||
         e.key == DoomKey::RControl)
        @page -= 1
        @menu.close if @page == -1
        @menu.start_sound(Sfx::PISTOL)
      end

      if e.key == DoomKey::Escape
        @menu.close
        @menu.start_sound(Sfx::SWTCHX)
      end

      return true
    end
  end
end
