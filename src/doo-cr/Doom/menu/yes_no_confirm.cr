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
  class YesNoConfirm < MenuDef
    getter text : Array(String)
    @action : Proc(Nil)

    def initialize(
      @menu, text, @action
    )
      @text = text.to_s.split('\n')
    end

    def do_event(e : DoomEvent) : Bool
      return true if e.type != EventType::KeyDown

      if (e.key == DoomKey::Y ||
         e.key == DoomKey::Enter ||
         e.key == DoomKey::Space)
        @action.call
        @menu.close
        @menu.start_sound(Sfx::PISTOL)
      end

      if (e.key == DoomKey::N ||
         e.key == DoomKey::Escape)
        @menu.close
        @menu.start_sound(Sfx::SWTCHX)
      end

      return true
    end
  end
end
