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
  class SliderMenuItem < MenuItem
    getter name : String
    getter item_x : Int32
    getter item_y : Int32

    getter slider_length : Int32
    getter slider_position : Int32

    @reset : Proc(Int32) | Nil = nil
    @action : Proc(Int32, Nil) | Nil = nil

    def slider_x
      return @item_x
    end

    def slider_y
      return @item_y + 16
    end

    def initialize(
      @name,
      @skull_x, @skull_y,
      @item_x, @item_y,
      @slider_length,
      @reset,
      @action
    )
      @slider_position = 0
    end

    def reset
      @slider_position = @reset.as(Proc(Int32)).call if @reset != nil
    end

    def up
      @slider_position += 1 if @slider_position < @slider_length - 1
      @action.as(Proc(Int32, Nil)).call(@slider_position) if @action != nil
    end

    def down
      @slider_position -= 1 if @slider_position > 0
      @action.as(Proc(Int32, Nil)).call(@slider_position) if @action != nil
    end
  end
end
