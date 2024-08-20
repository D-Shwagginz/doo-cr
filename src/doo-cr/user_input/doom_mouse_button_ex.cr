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
  module DoomMouseButtonEx
    def self.to_s(button : DoomMouseButton)
      case button
      when DoomMouseButton::Mouse1
        return "mouse1"
      when DoomMouseButton::Mouse2
        return "mouse2"
      when DoomMouseButton::Mouse3
        return "mouse3"
      when DoomMouseButton::Mouse4
        return "mouse4"
      when DoomMouseButton::Mouse5
        return "mouse5"
      else
        return "unknown"
      end
    end

    def self.parse(value : String)
      case value
      when "mouse1"
        return DoomMouseButton::Mouse1
      when "mouse2"
        return DoomMouseButton::Mouse2
      when "mouse3"
        return DoomMouseButton::Mouse3
      when "mouse4"
        return DoomMouseButton::Mouse4
      when "mouse5"
        return DoomMouseButton::Mouse5
      else
        return DoomMouseButton::Unknown
      end
    end
  end
end
