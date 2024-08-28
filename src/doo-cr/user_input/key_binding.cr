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
  class KeyBinding
    class_getter empty : KeyBinding = new()

    getter keys : Array(DoomKey)
    getter mouse_buttons : Array(DoomMouseButton)

    private def initialize
      @keys = [] of DoomKey
      @mouse_buttons = [] of DoomMouseButton
    end

    def initialize(@keys : Array(DoomKey))
      @mouse_buttons = [] of DoomMouseButton
    end

    def initialize(@keys : Array(DoomKey), @mouse_buttons : Array(DoomMouseButton))
    end

    def to_s
      key_values = @keys.select { |key| key.to_s }
      mouse_values = @mouse_buttons.select { |button| DoomMouseButtonEx.to_s(button) }
      values = key_values + mouse_values
      if values.size > 0
        s = ""
        values.each do |v|
          s = s + v + ", "
        end
        s = s.rchop

        return s
      else
        return "none"
      end
    end

    def self.parse(value : String)
      return @@empty if value == "none"

      keys = [] of DoomKey
      mouse_buttons = [] of DoomMouseButton

      split = value.split(',').select { |x| x.strip }
      split.each do |s|
        key = DoomKey.parse(s)
        if key != DoomKey::Unknown
          keys << key
          next
        end

        mouse_button = DoomMouseButton.parse(s)
        if mouse_button != DoomMouseButton::Unknown
          mouse_buttons << mouse_button
        end
      end

      return KeyBinding.new(keys, mouse_buttons)
    end
  end
end
