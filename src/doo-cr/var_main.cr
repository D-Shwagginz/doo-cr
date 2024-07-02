# All Global Variables

module Doocr
  # Command line arguments to add and change
  @@argv : Array(String) = [] of String

  @@drone : Bool = false

  @@singletics : Bool = false # debug flag to cancel adaptiveness

  @@inhelpscreens : Bool = false

  # Loaded Data File Paths
  @@wadfiles : Array(String) = [] of String

  @@debugfile : File | Nil = nil

  @@advancedemo : Bool = false

  @@wadfile : String = ""     # primary wad file
  @@mapdir : String = ""      # directory of development maps
  @@basedefault : String = "" # default file

  # ------------------------
  # Command line parameters.
  #
  @@nomonsters : Bool = false  # checkparm of -nomonsters
  @@respawnparm : Bool = false # checkparm of -respawn
  @@fastparm : Bool = false    # checkparm of -fast

  @@devparm : Bool = false # DEBUG: launched with -devparm

  # -----------------------------------------------------
  # Game Mode - identify IWAD as shareware, retail etc.
  #
  @@gamemode : GameMode = GameMode::Indetermined
  @@gamemission : GameMission = GameMission::Doom

  # Language.
  @@language = Language::English

  # Set if homebrew PWAD stuff has been added.
  @@modifiedgame : Bool = false

  # -------------------------------------------
  # Selected skill type, map etc.
  #

  # Defaults for menu, methinks.
  @@start_skill : Skill = Skill::Medium
  @@start_episode : Int32 = 0
  @@start_map : Int32 = 0

  @@autostart : Bool = false
  # Selected by user.
  @@game_skill : Skill = Skill::Medium
  @@game_episode : Int32 = 0
  @@game_map : Int32 = 0

  # Nightmare mode flag, single player.
  @@respawn_monsters : Bool = false

  # Netgame? Only true if >1 player.
  @@netgame : Bool = false

  # Flag: true only if started as net deathmatch.
  # An enum might handle altdeath/cooperative better.
  @@deathmatch : UInt8 = 0

  # -------------------------
  # Internal parameters for sound rendering.
  # These have been taken from the DOS version,
  # but are not (yet) supported with Linux
  # (e.g. no sound volume adjustment with menu.

  # These are not used, but should be (menu).
  # From m_menu.c:
  # Sound FX volume has default, 0 - 15
  # Music volume has default, 0 - 15
  # These are multiplied by 8.
  @@SfxVolume : Int32 = 0   # maximum volume for sound
  @@MusicVolume : Int32 = 0 # maximum volume for music

  # Event data
  @@events : Array(Event) = Array.new(MAXEVENTS, Event.new)
  @@event_head : Int32 = 0
  @@event_tail : Int32 = 0

  # Event Game Action
  @@gameaction : GameAction = GameAction::Nothing

  # --------------------------------------
  # DEMO playback/recording related stuff.
  # No demo, there is a human player in charge?
  # Disable save/end game?
  @@usergame : Bool = false

  # ?
  @@demoplayback : Bool = false
  @@demorecording : Bool = false

  # Quit after playing a demo from cmdline.
  @@singledemo : Bool = false

  # ?
  @@gamestate : Gamestate = Gamestate::Level

  @@gametic : Int32 = 0

  @@sendpause : Bool = false # send a pause event next tic
end
