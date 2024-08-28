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
  class QuitConfirm < MenuDef
    @@doom_quit_sound_list : Array(Sfx) = [
      Sfx::PLDETH,
      Sfx::DMPAIN,
      Sfx::POPAIN,
      Sfx::SLOP,
      Sfx::TELEPT,
      Sfx::POSIT1,
      Sfx::POSIT3,
      Sfx::SGTATK,
    ]

    @@doom2_quit_sound_list : Array(Sfx) = [
      Sfx::VILACT,
      Sfx::GETPOW,
      Sfx::BOSCUB,
      Sfx::SLOP,
      Sfx::SKESWG,
      Sfx::KNTDTH,
      Sfx::BSPACT,
      Sfx::SGTATK,
    ]

    @app : Doom
    @random : DoomRandom
    getter text : Array(String) = [] of String

    @end_count : Int32

    def initialize(@menu, @app)
      @random = DoomRandom.new(Time.utc.millisecond)
      @end_count = -1
    end

    def open
      list : Array(DoomString)
      if @app.options.game_mode == GameMode::Commercial
        if @app.options.mission_pack == MissionPack::Doom2
          list = DoomInfo::QuitMessages.doom2
        else
          list = DoomInfo::QuitMessages.final_doom
        end
      else
        list = DoomInfo::QuitMessages.doom
      end

      @text = (list.to_s[@random.next % list.size] + "\n\n" + DoomInfo::Strings::PRESSYN.to_s).split('\n')
    end

    def do_event(e : DoomEvent) : Bool
      return true if @end_count != -1

      return true if e.type != EventType::KeyDown

      if (e.key == DoomKey::Y ||
         e.key == DoomKey::Enter ||
         e.key == DoomKey::Space)
        @end_count = 0

        sfx : Sfx
        if @menu.options.game_mode == GameMode::Commercial
          sfx = @@doom2_quit_sound_list[@random.next % @@doom2_quit_sound_list.size]
        else
          sfx = @@doom_quit_sound_list[@random.next % @@doom_quit_sound_list.size]
        end
        @menu.start_sound(sfx)
      end

      if (e.key == DoomKey::N ||
         e.key == DoomKey::Escape)
        @menu.close
        @menu.start_sound(Sfx::SWTCHX)
      end

      return true
    end

    def update
      @end_count += 1 if @end_count != -1

      @app.quit if @end_count == 50
    end
  end
end
