# Main Requires and Constants

# Raylib-cr
require "raylib-cr"
require "raylib-cr/audio"

# Wa-cr
require "wa-cr"
require "wa-cr/raylib"
require "wa-cr/write"

require "./libadlmidi.cr"
require "./libopnmidi.cr"

# All important printed strings.
# Language selection (message strings).
# Use -DFRENCH etc.

{% if flag?(:FRENCH) %}
  require "./s_french.cr"
{% else %}
  require "./s_english.cr"
{% end %}

# General String Data
require "./s_strings.cr"

# Settings Configuration
require "./d_config.cr"

# Sound Data
require "./a_sounds.cr"

# Main Variables
require "./var_main.cr"

# All Event Data
require "./d_event.cr"

# Main Init Code
require "./d_main.cr"

# Map Data Translation
require "./d_mapdata.cr"

# Main Video Data
require "./v_video.cr"

# Wad Related Code
require "./w_wad.cr"

# Menu Related Code
require "./m_menu.cr"

# Audio Code
require "./a_sounds.cr"

# Heads up data
require "./hu_stuff.cr"

require "./m_swap.cr"

require "./r_main.cr"

require "./r_data.cr"

require "./m_fixed.cr"

require "./r_sky.cr"

require "./r_draw.cr"

require "./p_setup.cr"

require "./p_switch.cr"

require "./p_spec.cr"

require "./r_things.cr"

require "./info.cr"

require "./r_defs.cr"

require "./i_sound.cr"
require "./i_system.cr"

require "./d_net.cr"

require "./s_sound.cr"

require "./st_stuff.cr"

require "./g_game.cr"

require "./m_random.cr"

require "./d_think.cr"

require "./p_mobj.cr"

require "./d_player.cr"

require "./am_map.cr"

module Doocr
  # Prints Raylib Log
  {% if flag?(:LOG) %}
    LOG_RAYLIB = true
  {% else %}
    LOG_RAYLIB = false
  {% end %}

  #
  # Global parameters/defines.
  #
  # DOOM version
  D_VERSION = 110

  RANGECHECK = false

  # Do or do not use external soundserver.
  # The sndserver binary to be run separately
  #  has been introduced by Dave Taylor.
  # The integrated sound support is experimental,
  #  and unfinished. Default is synchronous.
  # Experimental asynchronous timer based is
  #  handled by SNDINTR.
  SNDSERV = true
  SNDINTR = true

  # This one switches between MIT SHM (no proper mouse)
  # and XFree86 DGA (mickey sampling). The original
  # linuxdoom used SHM, which is default.
  X11_DGA = true

  #
  # For resize of screen, at start of game.
  # It will not work dynamically, see visplanes.
  #
  BASE_WIDTH = 320

  # It is educational but futile to change this
  #  scaling e.g. to 2. Drawing of status bar,
  #  menues etc. is tied to the scale implied
  #  by the graphics.
  SCREEN_MUL       =     1
  INV_ASPECT_RATIO = 0.625 # 0.75, ideally

  SCREENWIDTH = 320
  # SCREEN_MUL*BASE_WIDTH #320
  SCREENHEIGHT = 200
  # SCREEN_MUL*BASE_WIDTH*INV_ASPECT_RATIO #200

  # The maximum number of players, multiplayer/networking.
  MAXPLAYERS = 4

  # State updates, number of tics / second.
  TICRATE = 35

  #
  # Difficulty/skill settings/filters.
  #

  # Skill flags.
  MTF_EASY   = 1
  MTF_NORMAL = 2
  MTF_HARD   = 4

  # Deaf monsters/do not react to sound.
  MTF_AMBUSH = 8

  # Game mode handling - identify IWAD version
  #  to handle IWAD dependend animations etc.
  enum GameMode
    Shareware  # DOOM 1 shareware, E1, M9
    Registered # DOOM 1 registered, E3, M27
    Commercial # DOOM 2 retail, E1 M34
    # DOOM 2 german edition not handled
    Retail       # DOOM 1 retail, E4, M36
    Indetermined # Well, no IWAD found.
  end

  # Mission packs - might be useful for TC stuff?
  enum GameMission
    Doom     # DOOM 1
    Doom2    # DOOM 2
    PackTNT  # TNT mission pack
    PackPlut # Plutonia pack
    None
  end

  # Identify language to use, software localization.
  enum Language
    English
    French
    German
    Unknown
  end

  # The current state of the game: whether we are
  # playing, gazing at the intermission screen,
  # the game final animation, or a demo.
  enum Gamestate
    Level
    Intermission
    Finale
    DemoScreen
  end

  enum Skill
    Baby
    Easy
    Medium
    Hard
    Nightmare
  end

  #
  # Key cards.
  #
  enum Card
    BlueCard
    YellowCard
    RedCard
    BlueSkull
    YellowSkull
    RedSkull

    NumCards
  end

  # The defined weapons,
  #  including a marker indicating
  #  user has not changed weapon.
  enum WeaponType
    Fist
    Pistol
    Shotgun
    Chaingun
    Missile
    Plasma
    BFG
    Chainsaw
    SuperShotgun

    NumWeapons

    # No pending weapon change.
    NoChange
  end

  # Ammunition types defined.
  enum AmmoType
    Clip  # Pistol / chaingun ammo.
    Shell # Shotgun / double barreled shotgun.
    Cell  # Plasma rifle, BFG.
    Misl  # Missile launcher.
    NumAmmo
    NoAmmo # Unlimited for chainsaw / fist.
  end

  # Power up artifacts.
  enum PowerType
    Invulnerability
    Strength
    Invisibility
    Ironfeet
    Allmap
    Infrared
    NumPowers
  end

  #
  # Power up durations,
  #  how many seconds till expiration,
  #  assuming TICRATE is 35 ticks/second.
  #
  enum PowerDuration
    InvulnTics = (30*TICRATE)
    InvisTics  = (60*TICRATE)
    InfraTics  = (120*TICRATE)
    IronTics   = (60*TICRATE)
  end
end
