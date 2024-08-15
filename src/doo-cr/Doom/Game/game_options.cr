module Doocr
  class GameOptions
    property game_version : GameVersion
    property game_mode : GameMode
    property mission_pack : MissionPack
    getter players : Array(Player)
    property console_player : Int32
    property episode : Int32
    property map : Int32
    property skill : GameSkill
    property demo_playback : Bool
    property net_game : Bool
    property deathmatch : Int32
    property fast_monsters : Bool
    property respawn_monsters : Bool
    property no_monsters : Bool

    getter intermission_info : IntermissionInfo

    getter random : DoomRandom

    property video : IVideo

    property sound : Audio::ISound

    property music : Audio::IMusic

    property user_input : UserInput::IUserInput

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

      @video = NullVideo.get_instance
      @sound = NullSound.get_instance
      @music = NullMusic.get_instance
      @user_input = NullUserInput.get_instance
    end

    def initialize(args : CommandLineArgs, content : GameContent)
      if args.solonet.present
        @net_game = true
      end

      @game_version = content.wad.game_version
      @game_mode = content.wad.game_mode
      @mission_pack = content.wad.mission_pack
    end
  end
end
