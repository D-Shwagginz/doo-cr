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
  class GameOptions
    property game_version : GameVersion = GameVersion.new(0)
    property game_mode : GameMode = GameMode.new(0)
    property mission_pack : MissionPack = MissionPack.new(0)
    getter players : Array(Player) = Array(Player).new
    property console_player : Int32 = 0
    property episode : Int32 = 0
    property map : Int32 = 0
    property skill : GameSkill = GameSkill.new(0)
    property demo_playback : Bool = false
    property net_game : Bool = false
    property deathmatch : Int32 = 0
    property fast_monsters : Bool = false
    property respawn_monsters : Bool = false
    property no_monsters : Bool = false

    getter intermission_info : IntermissionInfo | Nil = nil

    getter random : DoomRandom | Nil = nil

    property video : Video::IVideo | Nil = nil

    property sound : Audio::ISound | Nil = nil

    property music : Audio::IMusic | Nil = nil

    property user_input : UserInput::IUserInput | Nil = nil

    def initialize
      @game_version = GameVersion::Version109
      @game_mode = GameMode::Commercial
      @mission_pack = MissionPack::Doom2

      @players = Array(Player).new(Player::MAX_PLAYER_COUNT)
      Player::MAX_PLAYER_COUNT.times do |i|
        @players << Player.new(i)
      end
      @players[0].in_game = true
      @console_player = 0

      @episode = 1
      @map = 1
      @skill = GameSkill::Medium

      @demo_playback = false
      @net_game = false

      @deathmatch = 0
      @fast_monsters = false
      @respawn_monsters = false
      @no_monsters = false

      @intermission_info = IntermissionInfo.new

      @random = DoomRandom.new

      @video = Video::NullVideo.get_instance
      @sound = Audio::NullSound.get_instance
      @music = Audio::NullMusic.get_instance
      @user_input = UserInput::NullUserInput.get_instance
    end

    def initialize(args : CommandLineArgs, content : GameContent)
      if args.solonet.present
        @net_game = true
      end

      @game_version = content.wad.as(Wad).game_version
      @game_mode = content.wad.as(Wad).game_mode
      @mission_pack = content.wad.as(Wad).mission_pack
    end
  end
end
