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
  class ToggleMenuItem < MenuItem
    getter name : String
    getter item_x : Int32
    getter item_y : Int32

    @states : Array(String)
    getter state_x : Int32

    @state_number : Int32

    @reset : Proc(Int32) | Nil = nil
    @action : Proc(Int32, Nil) | Nil = nil

    def state : String
      return @states[@state_number]
    end

    def initialize(
      @name,
      @skull_x, @skull_y,
      @item_x, @item_y,
      state1 : String, state2 : String,
      @state_x,
      @reset,
      @action
    )
      @states = [state1, state2]

      @state_number = 0
    end

    def reset
      @state_number = @reset.as(Proc(Int32)).call if @reset != nil
    end

    def up
      @state_number += 1
      @state_number = 0 if @state_number == @states.size

      @action.as(Proc(Int32, Nil)).call(@state_number) if @action != nil
    end

    def down
      @state_number -= 1
      @state_number = @states.size - 1 if @state_number == -1

      @action.as(Proc(Int32, Nil)).call(@state_number) if @action != nil
    end
  end
end
