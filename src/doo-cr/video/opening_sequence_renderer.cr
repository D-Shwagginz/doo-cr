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
  class OpeningSequenceRenderer
    @screen : DrawScreen
    @parent : Renderer

    @cache : PatchCache

    def initialize(
      wad : Wad, @screen, @parent
    )
      @cache = PatchCache.new(wad)
    end

    def render(sequence : OpeningSequence, frame_frac : Fixed)
      scale = (@screen.width / 320).to_i32

      case sequence.state
      when OpeningSequenceState::Title
        @screen.draw_patch(@cache["TITLEPIC"], 0, 0, scale)
      when OpeningSequenceState::Demo
        @parent.render_game(sequence.game.as(DoomGame), frame_frac)
      when OpeningSequenceState::Credit
        @screen.draw_patch(@cache["CREDIT"], 0, 0, scale)
      end
    end
  end
end
