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

module Doocr::SFML
  class SFMLDoom
    @args : CommandLineArgs | Nil = nil

    @config : Config | Nil = nil
    @content : GameContent | Nil = nil

    @window : SF::RenderWindow | Nil = nil

    @video : SFMLVideo | Nil = nil

    @sound : SFMLSound | Nil = nil
    @music : SFMLMusic | Nil = nil

    def quit_message : String
      # return @doom.quit_message
      return "Exit"
    end

    def initialize(@args : CommandLineArgs)
      begin
      rescue e
      end
    end
  end
end