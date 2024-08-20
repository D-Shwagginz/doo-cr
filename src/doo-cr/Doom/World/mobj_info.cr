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
  class MobjInfo
    property doomednum : Int32
    property spawn_state : MobjState
    property spawn_health : Int32
    property see_state : MobjState
    property see_sound : Sfx
    property reaction_time : Int32
    property attack_sound : Sfx
    property pain_state : MobjState
    property pain_chance : Int32
    property pain_sound : Sfx
    property melee_state : MobjState
    property missile_state : MobjState
    property death_state : MobjState
    property xdeath_state : MobjState
    property death_sound : Sfx
    property speed : Int32
    property radius : Fixed
    property height : Fixed
    property mass : Int32
    property damage : Int32
    property active_sound : Sfx
    property flags : MobjFlags
    property raise_state : MobjState

    def initialize(
      @doomednum : Int32,
      @spawn_state : MobjState,
      @spawn_health : Int32,
      @see_state : MobjState,
      @see_sound : Sfx,
      @reaction_time : Int32,
      @attack_sound : Sfx,
      @pain_state : MobjState,
      @pain_chance : Int32,
      @pain_sound : Sfx,
      @melee_state : MobjState,
      @missile_state : MobjState,
      @death_state : MobjState,
      @xdeath_state : MobjState,
      @death_sound : Sfx,
      @speed : Int32,
      @radius : Fixed,
      @height : Fixed,
      @mass : Int32,
      @damage : Int32,
      @active_sound : Sfx,
      @flags : MobjFlags,
      @raise_state : MobjState
    )
    end
  end
end
