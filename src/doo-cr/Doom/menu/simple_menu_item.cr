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
  class SimpleMenuItem < MenuItem
    getter name : String
    getter item_x : Int32
    getter item_y : Int32
    getter action : Proc(Nil) | Nil = nil
    @selectable : Proc(Bool) | Nil = nil

    def selectable : Bool
      if @selectable == nil
        return true
      else
        return @selectable.as(Proc(Bool)).call
      end
    end

    def initialize(
      @name,
      @skull_x, @skull_y,
      @item_x, @item_y,
      @action, @next
    )
    end

    def initialize(
      @name,
      @skull_x, @skull_y,
      @item_x, @item_y,
      @action, @next, @selectable
    )
    end
  end
end
