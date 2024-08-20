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
  class Doom
    @args : CommandLineArgs | Nil
    @config : Config | Nil
    @content : GameContent | Nil
    @video : IVideo | Nil
    @sound : Audio::ISound | Nil
    @music : Audio::IMusic | Nil
    @user_input : UserInput::IUserInput | Nil

    @events : Array(DoomEvent) = Array(DoomEvent).new

    @options : GameOptions | Nil
  end
end
