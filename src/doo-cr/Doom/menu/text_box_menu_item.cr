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
  class TextBoxMenuItem < MenuItem
    getter item_x : Int32
    getter item_y : Int32

    @text : Array(Char) | Nil = nil
    @edit : TextInput | Nil = nil

    def editing : Bool
      return @edit != nil
    end

    def initialize(
      @skull_x, @skull_y,
      @item_x, @item_y
    )
    end

    def edit(finished : Proc(Nil)) : TextInput
      @edit = TextInput.new(
        @text != nil ? @text : Array(Char).new,
        ->(cs : Array(Char)) {},
        ->(cs : Array(Char)) { @text = cs; @edit = nil; finished.call },
        ->{ @edit = nil }
      )

      return @edit
    end

    def set_text(text : String | Nil)
      @text = text.to_a if text != nil
    end

    def text : Array(Char)
      if @edit == nil
        return @text
      else
        return @edit.text
      end
    end
  end
end
