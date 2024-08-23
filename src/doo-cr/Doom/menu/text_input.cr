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
  class TextInput
    getter text : Array(Char)
    @typed : Proc(Array(Char), Nil)
    @finished : Proc(Array(Char), Nil)
    @canceled : Proc(Nil)

    getter state : TextInputState

    def initialize(@text : Array(Char), @typed, @finished, @canceled)
      @state = TextInputState::Typing
    end

    def do_event(e : DoomEvent) : Bool
      ch = e.key.get_char
      if ch != 0
        @text << ch
        @typed.call(@text)
        return true
      end

      if e.key == DoomKey::Backspace && e.type == EventType::KeyDown
        @text.delete_at(@text.size - 1) if @text.size > 0
        @typed.call(@text)
        return true
      end

      if e.key == DoomKey::Enter && e.type == EventType::KeyDown
        @canceled.call
        @state = TextInputState::Canceled
        return true
      end

      return true
    end
  end
end
