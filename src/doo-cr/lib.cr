# Copyright (C) 2026 Devin Shwagginz
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# ==> The "C" side of Doo-cr. Hope to get rid of this someday.

# Abs macroo
macro doom_abs(x)
  (({{x}}) < 0 ? -({{x}}) : ({{x}}))
end

# Cheat Scrambler
macro scramble(a)
  (((({{a}})&1)<<7) + ((({{a}})&2)<<5) + (({{a}})&4) + ((({{a}})&8)<<1) \
 + ((({{a}})&16)>>1) + (({{a}})&32) + ((({{a}})&64)>>5) + ((({{a}})&128)>>7))
end

#
# This is used to get the local FILE:LINE info from CPP
# prior to really call the function in question.
#
macro z_change_tag(p, t)
  if (({{p}}.as(CDoom::Byte*)) - sizeof(CDoom::Memblock)).as(CDoom::Memblock*).value.id != 0x1d4a11
    buf = Pointer(UInt8).malloc(260)
    CDoom.doom_strcpy(buf, "Error: Z_CT at #{__FILE__} :")
    CDoom.doom_concat(buf, doom_itoa(__LINE__, 10))
    CDoom.i_error(buf)
  end
  CDoom.z_change_tag2({{p}}, {{t}})
end

# translates between frame-buffer and map distances
macro ftom(x)
  (CDoom.fixed_mul(({{x}}<<16), Doocr.scale_ftom))
end

# define MTOF(x) (FixedMul((x),scale_mtof)>>16)
macro mtof(x)
  (CDoom.fixed_mul({{x}}, Doocr.scale_mtof)>>16)
end

# translates between frame-buffer and map coordinates
# define CXMTOF(x)  (f_x + MTOF((x)-m_x))
# define CYMTOF(y)  (f_y + (f_h - MTOF((y)-m_y)))
macro cxmtof(x)
  (Doocr.f_x + mtof({{x}}-Doocr.m_x))
end

macro cymtof(y)
  (Doocr.f_y + (Doocr.f_h - mtof({{y}}-Doocr.m_y)))
end

# Macros for filling C StaticArrays
macro c_array(array, *objs)
  {% for elm, i in objs %}
    {{array}}[{{i}}] = {{elm}}
  {% end %}
end

macro c_array_strings(array, *objs)
  {% for elm, i in objs %}
    {{array}}[{{i}}] = {{elm}}.to_unsafe
  {% end %}
end

macro c_array_cheat(array, *objs)
  {% for elm, i in objs %}
    ({{array}}.to_unsafe + {{i}}).value.sequence = {{elm[0]}}
    ({{array}}.to_unsafe + {{i}}).value.p = {{elm[1]}}
  {% end %}
end

macro c_array_animinfo(array, *objs)
  {% for elm, i in objs %}
    ({{array}}.to_unsafe + {{i}}).value.type = {{elm[0]}}
    ({{array}}.to_unsafe + {{i}}).value.period = {{elm[1]}}
    ({{array}}.to_unsafe + {{i}}).value.nanims = {{elm[2]}}
    ({{array}}.to_unsafe + {{i}}).value.loc.x = {{elm[3]}}[0]
    ({{array}}.to_unsafe + {{i}}).value.loc.y = {{elm[3]}}[1]
    ({{array}}.to_unsafe + {{i}}).value.data1 = {{elm[4]}}
  {% end %}
end

# Was a define in C
macro ng_statsx
  (32 + Doocr.star.value.width//2 + 32*(Doocr.dofrags == 0).to_unsafe)
end

# The C Library
lib CDoom
  DOOM_SAMPLERATE = Doocr::DOOM_SAMPLERATE
  DOOM_MIDI_RATE = Doocr::DOOM_MIDI_RATE
  DOOM_FLAG_HIDE_MOUSE_OPTIONS = Doocr::DOOM_FLAG_HIDE_MOUSE_OPTIONS
  DOOM_FLAG_HIDE_SOUND_OPTIONS = Doocr::DOOM_FLAG_HIDE_SOUND_OPTIONS
  DOOM_FLAG_HIDE_MUSIC_OPTIONS = Doocr::DOOM_FLAG_HIDE_MUSIC_OPTIONS
  DOOM_FLAG_MENU_DARKEN_BG = Doocr::DOOM_FLAG_MENU_DARKEN_BG

  alias DoomBool = LibC::Int
  alias Default = Doocr::Default

  alias DoomKey = Doocr::DoomKey
  alias DoomButton = Doocr::DoomButton

  #
  # P_inter.C
  #

  #
  # P_Doors.C
  #

  #
  # G_game.C
  #

  #
  # HU_stuff.C
  #

  # The following should NOT be changed unless it seems
  # just AWFULLY necessary

  HUSTR_KEYGREEN  = 'g'
  HUSTR_KEYINDIGO = 'i'
  HUSTR_KEYBROWN  = 'b'
  HUSTR_KEYRED    = 'r'

  #
  # AM_map.C
  #

  #
  # ST_stuff.C
  #

  #
  # F_Finale.C
  #

  # after level 6, put this:

  # After level 11, put this:

  # After level 20, put this:

  # After level 29, put this:

  # Before level 31, put this:

  # Before level 32, put this:

  # after map 06

  # after map 11

  # after map 20

  # after map 30

  # before map 31

  # before map 32

  #
  # Character cast strings F_FINALE.C
  #

  # __D_THINK__

  #
  # Experimental stuff.
  # To compile this as "ANSI C with classes"
  #  we will need to handle the various
  #  action functions cleanly.
  #
  alias ActionfV = Proc(Nil)
  alias ActionfP1 = Proc(Void*, Nil)
  alias ActionfP2 = Proc(Void*, Void*, Nil)

  union Actionf
    acp1 : ActionfP1
    acv : ActionfV
    acp2 : ActionfP2
  end

  # Historically, "think_t" is yet another
  #  function pointer to a routine to handle
  #  an actor.
  alias Think = Actionf

  # Doubly linked list of actors.
  struct Thinker
    prev : Thinker*
    next : Thinker*
    function : Think
    # padded so that Proc#closure_data doesn't overwrite
    # the 8 bytes after the function pointer (think)
    # This is bullshit
    pad : LibC::LongLong
    remove : UInt8
  end

  # __DOOM_CONFIG_H__

  {% if flag?(:windows) %}
    DOOM_WIN32 = true
  {% elsif flag?(:macosx) %}
    DOOM_APPLE = true
  {% else %}
    DOOM_LINUX = true
  {% end %}

  fun doom_itoa(i : LibC::Int, radix : LibC::Int) : LibC::Char*
  fun doom_ctoa(c : LibC::Char) : LibC::Char*
  fun doom_ptoa(p : Void*) : LibC::Char*
  fun doom_memset(ptr : Void*, value : LibC::Int, num : LibC::Int)
  fun doom_memcpy(destination : Void*, source : Void*, num : LibC::Int) : Void*
  fun doom_fprint(handle : Void*, str : LibC::Char*) : LibC::Int
  fun doom_strlen(str : LibC::Char*) : LibC::Int
  fun doom_concat(dst : LibC::Char*, src : LibC::Char*) : LibC::Char*
  fun doom_strcpy(destination : LibC::Char*, source : LibC::Char*) : LibC::Char*
  fun doom_strncpy(destination : LibC::Char*, source : LibC::Char*, num : LibC::Int) : LibC::Char*
  fun doom_strcmp(str1 : LibC::Char*, str2 : LibC::Char*) : LibC::Int
  fun doom_strncmp(str1 : LibC::Char*, str2 : LibC::Char*, n : LibC::Int) : LibC::Int
  fun doom_strcasecmp(str1 : LibC::Char*, str2 : LibC::Char*) : LibC::Int
  fun doom_strncasecmp(str1 : LibC::Char*, str2 : LibC::Char*, n : LibC::Int) : LibC::Int
  fun doom_atoi(str : LibC::Char*) : LibC::Int
  fun doom_atox(str : LibC::Char*) : LibC::Int
  fun doom_toupper(c : LibC::Int) : LibC::Int

  # __DOOMDEF__

  #
  # Global parameters/defines.
  #
  # DOOM version
  VERSION = Doocr::VERSION

  # Game mode handling - identify IWAD version
  #  to handle IWAD dependend animations etc.
  alias GameMode = Doocr::GameMode

  # Mission packs - might be useful for TC stuff?
  alias GameMission = Doocr::GameMission

  # Identify language to use, software localization.
  alias Language = Doocr::Language

  #
  # For resize of screen, at start of game.
  # It will not work dynamically, see visplanes.
  #
  BASE_WIDTH = Doocr::BASE_WIDTH

  # It is educational but futile to change this
  #  scaling e.g. to 2. Drawing of status bar,
  #  menues etc. is tied to the scale implied
  #  by the graphics.
  SCREEN_MUL       = Doocr::SCREEN_MUL
  INV_ASPECT_RATIO = Doocr::INV_ASPECT_RATIO

  # Constants suck. Crystal sucks.
  # Ruby might sucks for OOP, but it sure is a better Crystal.
  # So there.
  SCREENWIDTH  = Doocr::SCREENWIDTH
  SCREENHEIGHT = Doocr::SCREENHEIGHT

  # The maximum number of players, multiplayer/networking.
  MAXPLAYERS = Doocr::MAXPLAYERS

  # State updates, number of tics / second.
  {% if flag?("DOOM_FAST_TICK") %}
    TICKMUL = 2
  {% else %}
    TICKMUL = 1
  {% end %}
  TICRATE = (35 * TICKMUL)

  # The current state of the game: whether we are
  # playing, gazing at the intermission screen,
  # the game final animation, or a demo.
  alias Gamestate = Doocr::Gamestate

  #
  # Difficulty/skill settings/filters.
  #

  # Skill flags.
  MTF_EASY   = Doocr::MTF_EASY
  MTF_NORMAL = Doocr::MTF_NORMAL
  MTF_HARD   = Doocr::MTF_HARD

  # Deaf monsters/do not react to sound.
  MTF_AMBUSH = Doocr::MTF_AMBUSH

  alias Skill = Doocr::Skill

  #
  # Key card.
  #
  alias Card = Doocr::Card

  # The defined weapons,
  # including a marker indicating
  # user has not changed weapon.
  alias Weapontype = Doocr::Weapontype

  # Ammunition types defined.
  alias Ammotype = Doocr::Ammotype

  # Power up artifacts.
  alias Powertype = Doocr::Powertype

  #
  # Power up durations,
  #  how many seconds till expiration,
  #  assuming TICRATE is 35 ticks/second.
  #
  alias Powerduration = Doocr::Powerduration

  #
  # DOOM keyboard definition.
  # This is the stuff configured by Setup.Exe.
  # Most key data are simple ascii (uppercased).
  #
  KEY_RIGHTARROW = 0xae
  KEY_LEFTARROW  = 0xac
  KEY_UPARROW    = 0xad
  KEY_DOWNARROW  = 0xaf
  KEY_ESCAPE     =   27
  KEY_ENTER      =   13
  KEY_TAB        =    9
  KEY_F1         = (0x80 + 0x3b)
  KEY_F2         = (0x80 + 0x3c)
  KEY_F3         = (0x80 + 0x3d)
  KEY_F4         = (0x80 + 0x3e)
  KEY_F5         = (0x80 + 0x3f)
  KEY_F6         = (0x80 + 0x40)
  KEY_F7         = (0x80 + 0x41)
  KEY_F8         = (0x80 + 0x42)
  KEY_F9         = (0x80 + 0x43)
  KEY_F10        = (0x80 + 0x44)
  KEY_F11        = (0x80 + 0x57)
  KEY_F12        = (0x80 + 0x58)

  KEY_BACKSPACE =  127
  KEY_PAUSE     = 0xff

  KEY_EQUALS = 0x3d
  KEY_MINUS  = 0x2d

  KEY_RSHIFT = (0x80 + 0x36)
  KEY_RCTRL  = (0x80 + 0x1d)
  KEY_RALT   = (0x80 + 0x38)

  KEY_LALT = KEY_RALT

  # __D_ITEMS__

  # __DOOMTYPE__

  alias Byte = LibC::UChar
  # Types are already defined in the Crystal int classes

  # __D_EVENT__

  #
  # Event handling.
  #

  # Input event types.
  alias Evtype = Doocr::Evtype

  # Event structure.
  struct Event
    type : Evtype
    data1 : LibC::Int # keys / mouse/joystick buttons
    data2 : LibC::Int # mouse/joystick x move
    data3 : LibC::Int # mouse/joystick y move
  end

  alias Gameaction = Doocr::Gameaction

  #
  # Button/action code definitions.
  #
  enum Buttoncode
    # Press "Fire".
    BT_ATTACK = 1
    # Use button, to open doors, activate switches.
    BT_USE = 2

    # Flag: game events, not really buttons.
    BT_SPECIAL     = 128
    BT_SPECIALMASK =   3

    # Flag, weapon change pending.
    # If true, the next 3 bits hold weapon num.
    BT_CHANGE = 4
    # The 3bit weapon mask and shift, convenience.
    BT_WEAPONMASK  = (8 + 16 + 32)
    BT_WEAPONSHIFT = 3

    # Pause the game.
    BTS_PAUSE = 1
    # Save the game at each console.
    BTS_SAVEGAME = 2

    # Savegame slot numbers
    #  occupy the second byte of buttons.
    BTS_SAVEMASK  = (4 + 8 + 16)
    BTS_SAVESHIFT = 2
  end

  #
  # GLOBAL VARIABLES
  MAXEVENTS = (64 * 64) # [pd] Crank up the number because we pump them faster

  # __AMMAP_H__

  # Used by ST StatusBar stuff.
  AM_MSGHEADER  = (('a'.ord << 24) + ('m'.ord << 16))
  AM_MSGENTERED = (AM_MSGHEADER | ('e'.ord << 8))
  AM_MSGEXITED  = (AM_MSGHEADER | ('x'.ord << 8))

  # __D_MAIN__

  MAXWADFILES = 20


  fun d_add_file = D_AddFile(file : LibC::Char*)

  # Called by IO functions when input is detected.
  fun d_post_event = D_PostEvent(ev : Event*)

  #
  # BASE LEVEL
  #
  fun d_page_ticker = D_PageTicker
  fun d_page_drawer = D_PageDrawer
  fun d_advance_demo = D_AdvanceDemo
  fun d_start_title = D_StartTitle

  # __D_TEXTUR__

  #
  # Flats?
  #
  # a pic is an unmasked block of pixels
  struct Pic
    width : Byte
    height : Byte
    data : Byte
  end

  # __D_TICCMD__

  # The data sampled per tick (single player)
  # and transmitted to other peers (multiplayer).
  # Mainly movements/button commands per game tick,
  # plus a checksum for internal state consistency.
  struct Ticcmd
    forwardmove : LibC::SChar # *2048 for move
    sidemove : LibC::SChar    # *2048 for move
    angleturn : LibC::Short   # <<16 for angle delta
    consistancy : LibC::Short # checks for net game
    chatchar : Byte
    buttons : Byte
  end

  # __DOOMDATA__

  #
  # Map level types.
  # The following data structures define the persistent format
  # used in the lumps of the WAD files.
  #

  # Lump order in a map WAD: each map needs a couple of lumps
  # to provide a complete scene geometry description.
  ML_LABEL    =  0 # A separator, name, ExMx or MAPxx
  ML_THINGS   =  1 # Monsters, items..
  ML_LINEDEFS =  2 # LineDefs, from editing
  ML_SIDEDEFS =  3 # SideDefs, from editing
  ML_VERTEXES =  4 # Vertices, edited and BSP splits generated
  ML_SEGS     =  5 # LineSegs, from LineDefs split by BSP
  ML_SSECTORS =  6 # SubSectors, list of LineSegs
  ML_NODES    =  7 # BSP nodes
  ML_SECTORS  =  8 # Sectors, from editing
  ML_REJECT   =  9 # LUT, sector-sector visibility
  ML_BLOCKMAP = 10 # LUT, motion clipping, walls/grid element

  # A single Vertex.
  struct Mapvertex
    x : LibC::Short
    y : LibC::Short
  end

  struct Mapsidedef
    textureoffset : LibC::Short
    rowoffset : LibC::Short
    toptexture : LibC::Char[8]
    bottomtexture : LibC::Char[8]
    midtexture : LibC::Char[8]
    sector : LibC::Short
  end

  struct Maplinedef
    v1 : LibC::Short
    v2 : LibC::Short
    flags : LibC::Short
    special : LibC::Short
    tag : LibC::Short
    sidenum : LibC::Short[2]
  end

  # A SideDef, defining the visual appearance of a wall,
  # by setting textures and offsets.

  # Solid, is an obstacle.
  ML_BLOCKING = 1

  # Blocks monsters only.
  ML_BLOCKMONSTERS = 2

  # Backside will not be present at all
  #  if not two sided.
  ML_TWOSIDED = 4

  # If a texture is pegged, the texture will have
  # the end exposed to air held constant at the
  # top or bottom of the texture (stairs or pulled
  # down things) and will move with a height change
  # of one of the neighbor sectors.
  # Unpegged textures allways have the first row of
  # the texture at the top pixel of the line for both
  # top and bottom textures (use next to windows).

  # upper texture unpegged
  ML_DONTPEGTOP = 8

  # lower texture unpegged
  ML_DONTPEGBOTTOM = 16

  # In AutoMap: don't map as two sided: IT'S A SECRET!
  ML_SECRET = 32

  # Sound rendering: don't let sound cross two of these.
  ML_SOUNDBLOCK = 64

  # Don't draw on the automap at all.
  ML_DONTDRAW = 128

  # Set if already seen, thus drawn in automap.
  ML_MAPPED = 256

  # Sector definition, from editing.
  struct Mapsector
    floorheight : LibC::Short
    ceilingheight : LibC::Short
    floorpic : LibC::Char[8]
    ceilingpic : LibC::Char[8]
    lightlevel : LibC::Short
    special : LibC::Short
    tag : LibC::Short
  end

  # SubSector, as generated by BSP.
  struct Mapsubsector
    numsegs : LibC::Short
    # Index of first one, segs are stored sequentially.
    firstseg : LibC::Short
  end

  # LineSeg, generated by splitting LineDefs
  # using partition lines selected by BSP builder.
  struct Mapseg
    v1 : LibC::Short
    v2 : LibC::Short
    angle : LibC::Short
    linedef : LibC::Short
    side : LibC::Short
    offset : LibC::Short
  end

  #
  # BSP node structure.
  #

  # Indicate a leaf.
  NF_SUBSECTOR = 0x8000

  struct Mapnode
    # Partition line from (x,y) to x+dx,y+dy)
    x : LibC::Short
    y : LibC::Short
    dx : LibC::Short
    dy : LibC::Short

    # Bounding box for each child,
    # clip against view frustum.
    bbox : LibC::Short[4][2]

    # If NF_SUBSECTOR its a subsector,
    # else it's a node of another subtree.
    children : LibC::UShort[2]
  end

  # Thing definition, position, orientation and type,
  # plus skill/visibility flags and attributes.
  struct Mapthing
    x : LibC::Short
    y : LibC::Short
    angle : LibC::Short
    type : LibC::Short
    options : LibC::Short
  end

  # __DSTRINGS__

  # All important printed strings.
  # Language selection (message strings).
  # Use -DFRENCH etc.

  {% if flag?("FRENCH") %}
    # require "./d_french.cr" # Leave the extra space there, to throw off regex in PureDOOM.h creation
  {% else %}
    # require "./d_englsh.cr"
  {% end %}

  # Misc. other strings.

  #
  # File locations,
  #  relative to current position.
  # Path names are OS-sensitive.
  #
  DEVMAPS = "devmaps"
  DEVDATA = "devdata"

  # Not done in french?

  # QuitDOOM messages
  NUM_QUITMESSAGES = 22

  # __F_FINALE__

  #
  # FINALE
  #

  # Called by main loop.
  fun f_responder = F_Responder(ev : Event*) : DoomBool

  # Called by main loop.
  fun f_ticker = F_Ticker

  # Called by main loop.
  fun f_drawer = F_Drawer

  fun f_start_finale = F_StartFinale

  # __F_WIPE_H__

  #
  # SCREEN WIPE PACKAGE
  #

  # simple gradual pixel change for 8-bit only
  WIPE_COLORXFORM = 0
  # weird screen melt
  WIPE_MELT     = 1
  WIPE_NUMWIPES = 2

  fun wipe_start_screen = wipe_StartScreen(x : LibC::Int, y : LibC::Int, width : LibC::Int, height : LibC::Int) : LibC::Int
  fun wipe_end_screen = wipe_EndScreen(x : LibC::Int, y : LibC::Int, width : LibC::Int, height : LibC::Int) : LibC::Int
  fun wipe_screen_wipe = wipe_ScreenWipe(wipeno : LibC::Int, x : LibC::Int, y : LibC::Int, width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int

  # __G_GAME__

  #
  # GAME
  #
  fun g_deathmatch_spawn_player = G_DeathMatchSpawnPlayer(playernum : LibC::Int)

  fun g_init_new = G_InitNew(skill : Skill, episode : LibC::Int, map : LibC::Int)

  # Can be called by the startup code or M_Responder.
  # A normal game starts at map 1,
  # but a warp test can start elsewhere
  fun g_defered_init_new = G_DeferedInitNew(skill : Skill, episode : LibC::Int, map : LibC::Int)

  fun g_defered_play_demo = G_DeferedPlayDemo(demo : LibC::Char*)

  # Can be called by the startup code or M_Responder,
  # calls P_SetupLevel or W_EnterWorld.
  fun g_load_game = G_LoadGame(name : LibC::Char*)

  fun g_do_load_game = G_DoLoadGame

  # Called by M_Responder.
  fun g_save_game = G_SaveGame(slot : LibC::Int, description : LibC::Char*)

  # Only called by startup code.
  fun g_record_demo = G_RecordDemo(name : LibC::Char*)

  fun g_begin_recording = G_BeginRecording

  fun g_time_demo = G_TimeDemo(name : LibC::Char*)
  fun g_check_demo_status = G_CheckDemoStatus : DoomBool

  fun g_exit_level = G_ExitLevel
  fun g_secret_exit_level = G_SecretExitLevel

  fun g_world_done = G_WorldDone

  fun g_ticker = G_Ticker
  fun g_responder = G_Responder(ev : Event*) : DoomBool

  fun g_screenshot = G_ScreenShot

  # __HU_STUFF_H__

  #
  # Globally visible constants.
  HU_FONTSTART = 33 # the first font characters
  HU_FONTEND   = 95 # the last font characters

  # Calculate # of glyphs in font.
  HU_FONTSIZE = (HU_FONTEND - HU_FONTSTART + 1)

  HU_BROADCAST = 5

  HU_MSGREFRESH = KEY_ENTER
  HU_MSGX       =  0
  HU_MSGY       =  0
  HU_MSGWIDTH   = 64 # in characters
  HU_MSGHEIGHT  =  1 # in lines

  HU_MSGTIMEOUT = (4*TICRATE)

  #
  # HEADS UP TEXT
  #

  fun hu_init = HU_Init
  fun hu_start = HU_Start
  fun hu_responder = HU_Responder(ev : Event*) : DoomBool
  fun hu_ticker = HU_Ticker
  fun hu_drawer = HU_Drawer
  fun hu_dequeue_chat_char = HU_dequeueChatChar : LibC::Char
  fun hu_erase = HU_Erase

  # __I_NET__

  # Called by D_DoomMain

  fun i_init_network = I_InitNetwork
  fun i_net_cmd = I_NetCmd

  # __I_SYSTEM__

  # Called by DoomMain.
  fun i_init = I_Init

  # Called by startup code
  # to get the ammount of memory to malloc
  # for the zone management.
  fun i_zone_base = I_ZoneBase(size : LibC::Int*) : Byte*

  # Called by D_DoomLoop,
  # returns current time in tics.
  fun i_get_time = I_GetTime : LibC::Int

  # Called by D_DoomLoop,
  # called before processing any tics in a frame
  # (just after displaying a frame).
  # Time consuming syncronous operations
  # are performed here (joystick reading).
  # Can call D_PostEvent.
  fun i_start_frame = I_StartFrame

  # Called by D_DoomLoop,
  # called before processing each tic in a frame.
  # Quick syncronous operations are performed here.
  # Can call D_PostEvent.
  fun i_start_tic = I_StartTic

  # Asynchronous interrupt functions should maintain private queues
  # that are read by the synchronous functions
  # to be converted into events.

  # Either returns a null ticcmd,
  # or calls a loadable driver to build it.
  # This ticcmd will then be modified by the gameloop
  # for normal input.
  fun i_base_ticcmd = I_BaseTiccmd : Ticcmd*

  # Called by M_Responder when quit is selected.
  # Clean exit, displays sell blurb.
  fun i_quit = I_Quit

  # Allocates from low memory under dos,
  # just mallocs under unix
  fun i_alloc_low = I_AllocLow(length : LibC::Int) : Byte*

  fun i_tactile = I_Tactile(on : LibC::Int, off : LibC::Int, total : LibC::Int)

  fun i_error = I_Error(error : LibC::Char*)

  # __I_VIDEO__

  # Called by D_DoomMain,
  # determines the hardware configuration
  # and sets up the video mode
  fun i_init_graphics = I_InitGraphics

  fun i_shutdown_graphics = I_ShutdownGraphics

  # Takes full 8 bit values.
  fun i_set_palette = I_SetPalette(palette : Byte*)

  fun i_update_no_blit = I_UpdateNoBlit
  fun i_finish_update = I_FinishUpdate

  # Wait for vertical retrace or pause a bit.
  fun i_wait_vbl = I_WaitVBL(count : LibC::Int)

  fun i_read_screen = I_ReadScreen(scr : Byte*)

  fun i_begin_read = I_BeginRead
  fun i_end_read = I_EndRead

  # __INFO__

  enum Spritenum
    SPR_TROO
    SPR_SHTG
    SPR_PUNG
    SPR_PISG
    SPR_PISF
    SPR_SHTF
    SPR_SHT2
    SPR_CHGG
    SPR_CHGF
    SPR_MISG
    SPR_MISF
    SPR_SAWG
    SPR_PLSG
    SPR_PLSF
    SPR_BFGG
    SPR_BFGF
    SPR_BLUD
    SPR_PUFF
    SPR_BAL1
    SPR_BAL2
    SPR_PLSS
    SPR_PLSE
    SPR_MISL
    SPR_BFS1
    SPR_BFE1
    SPR_BFE2
    SPR_TFOG
    SPR_IFOG
    SPR_PLAY
    SPR_POSS
    SPR_SPOS
    SPR_VILE
    SPR_FIRE
    SPR_FATB
    SPR_FBXP
    SPR_SKEL
    SPR_MANF
    SPR_FATT
    SPR_CPOS
    SPR_SARG
    SPR_HEAD
    SPR_BAL7
    SPR_BOSS
    SPR_BOS2
    SPR_SKUL
    SPR_SPID
    SPR_BSPI
    SPR_APLS
    SPR_APBX
    SPR_CYBR
    SPR_PAIN
    SPR_SSWV
    SPR_KEEN
    SPR_BBRN
    SPR_BOSF
    SPR_ARM1
    SPR_ARM2
    SPR_BAR1
    SPR_BEXP
    SPR_FCAN
    SPR_BON1
    SPR_BON2
    SPR_BKEY
    SPR_RKEY
    SPR_YKEY
    SPR_BSKU
    SPR_RSKU
    SPR_YSKU
    SPR_STIM
    SPR_MEDI
    SPR_SOUL
    SPR_PINV
    SPR_PSTR
    SPR_PINS
    SPR_MEGA
    SPR_SUIT
    SPR_PMAP
    SPR_PVIS
    SPR_CLIP
    SPR_AMMO
    SPR_ROCK
    SPR_BROK
    SPR_CELL
    SPR_CELP
    SPR_SHEL
    SPR_SBOX
    SPR_BPAK
    SPR_BFUG
    SPR_MGUN
    SPR_CSAW
    SPR_LAUN
    SPR_PLAS
    SPR_SHOT
    SPR_SGN2
    SPR_COLU
    SPR_SMT2
    SPR_GOR1
    SPR_POL2
    SPR_POL5
    SPR_POL4
    SPR_POL3
    SPR_POL1
    SPR_POL6
    SPR_GOR2
    SPR_GOR3
    SPR_GOR4
    SPR_GOR5
    SPR_SMIT
    SPR_COL1
    SPR_COL2
    SPR_COL3
    SPR_COL4
    SPR_CAND
    SPR_CBRA
    SPR_COL6
    SPR_TRE1
    SPR_TRE2
    SPR_ELEC
    SPR_CEYE
    SPR_FSKU
    SPR_COL5
    SPR_TBLU
    SPR_TGRN
    SPR_TRED
    SPR_SMBT
    SPR_SMGT
    SPR_SMRT
    SPR_HDB1
    SPR_HDB2
    SPR_HDB3
    SPR_HDB4
    SPR_HDB5
    SPR_HDB6
    SPR_POB1
    SPR_POB2
    SPR_BRS1
    SPR_TLMP
    SPR_TLP2
    NUMSPRITES

    SPR_TNT = 138
  end

  enum Statenum
    S_NULL
    S_LIGHTDONE
    S_PUNCH
    S_PUNCHDOWN
    S_PUNCHUP
    S_PUNCH1
    S_PUNCH2
    S_PUNCH3
    S_PUNCH4
    S_PUNCH5
    S_PISTOL
    S_PISTOLDOWN
    S_PISTOLUP
    S_PISTOL1
    S_PISTOL2
    S_PISTOL3
    S_PISTOL4
    S_PISTOLFLASH
    S_SGUN
    S_SGUNDOWN
    S_SGUNUP
    S_SGUN1
    S_SGUN2
    S_SGUN3
    S_SGUN4
    S_SGUN5
    S_SGUN6
    S_SGUN7
    S_SGUN8
    S_SGUN9
    S_SGUNFLASH1
    S_SGUNFLASH2
    S_DSGUN
    S_DSGUNDOWN
    S_DSGUNUP
    S_DSGUN1
    S_DSGUN2
    S_DSGUN3
    S_DSGUN4
    S_DSGUN5
    S_DSGUN6
    S_DSGUN7
    S_DSGUN8
    S_DSGUN9
    S_DSGUN10
    S_DSNR1
    S_DSNR2
    S_DSGUNFLASH1
    S_DSGUNFLASH2
    S_CHAIN
    S_CHAINDOWN
    S_CHAINUP
    S_CHAIN1
    S_CHAIN2
    S_CHAIN3
    S_CHAINFLASH1
    S_CHAINFLASH2
    S_MISSILE
    S_MISSILEDOWN
    S_MISSILEUP
    S_MISSILE1
    S_MISSILE2
    S_MISSILE3
    S_MISSILEFLASH1
    S_MISSILEFLASH2
    S_MISSILEFLASH3
    S_MISSILEFLASH4
    S_SAW
    S_SAWB
    S_SAWDOWN
    S_SAWUP
    S_SAW1
    S_SAW2
    S_SAW3
    S_PLASMA
    S_PLASMADOWN
    S_PLASMAUP
    S_PLASMA1
    S_PLASMA2
    S_PLASMAFLASH1
    S_PLASMAFLASH2
    S_BFG
    S_BFGDOWN
    S_BFGUP
    S_BFG1
    S_BFG2
    S_BFG3
    S_BFG4
    S_BFGFLASH1
    S_BFGFLASH2
    S_BLOOD1
    S_BLOOD2
    S_BLOOD3
    S_PUFF1
    S_PUFF2
    S_PUFF3
    S_PUFF4
    S_TBALL1
    S_TBALL2
    S_TBALLX1
    S_TBALLX2
    S_TBALLX3
    S_RBALL1
    S_RBALL2
    S_RBALLX1
    S_RBALLX2
    S_RBALLX3
    S_PLASBALL
    S_PLASBALL2
    S_PLASEXP
    S_PLASEXP2
    S_PLASEXP3
    S_PLASEXP4
    S_PLASEXP5
    S_ROCKET
    S_BFGSHOT
    S_BFGSHOT2
    S_BFGLAND
    S_BFGLAND2
    S_BFGLAND3
    S_BFGLAND4
    S_BFGLAND5
    S_BFGLAND6
    S_BFGEXP
    S_BFGEXP2
    S_BFGEXP3
    S_BFGEXP4
    S_EXPLODE1
    S_EXPLODE2
    S_EXPLODE3
    S_TFOG
    S_TFOG01
    S_TFOG02
    S_TFOG2
    S_TFOG3
    S_TFOG4
    S_TFOG5
    S_TFOG6
    S_TFOG7
    S_TFOG8
    S_TFOG9
    S_TFOG10
    S_IFOG
    S_IFOG01
    S_IFOG02
    S_IFOG2
    S_IFOG3
    S_IFOG4
    S_IFOG5
    S_PLAY
    S_PLAY_RUN1
    S_PLAY_RUN2
    S_PLAY_RUN3
    S_PLAY_RUN4
    S_PLAY_ATK1
    S_PLAY_ATK2
    S_PLAY_PAIN
    S_PLAY_PAIN2
    S_PLAY_DIE1
    S_PLAY_DIE2
    S_PLAY_DIE3
    S_PLAY_DIE4
    S_PLAY_DIE5
    S_PLAY_DIE6
    S_PLAY_DIE7
    S_PLAY_XDIE1
    S_PLAY_XDIE2
    S_PLAY_XDIE3
    S_PLAY_XDIE4
    S_PLAY_XDIE5
    S_PLAY_XDIE6
    S_PLAY_XDIE7
    S_PLAY_XDIE8
    S_PLAY_XDIE9
    S_POSS_STND
    S_POSS_STND2
    S_POSS_RUN1
    S_POSS_RUN2
    S_POSS_RUN3
    S_POSS_RUN4
    S_POSS_RUN5
    S_POSS_RUN6
    S_POSS_RUN7
    S_POSS_RUN8
    S_POSS_ATK1
    S_POSS_ATK2
    S_POSS_ATK3
    S_POSS_PAIN
    S_POSS_PAIN2
    S_POSS_DIE1
    S_POSS_DIE2
    S_POSS_DIE3
    S_POSS_DIE4
    S_POSS_DIE5
    S_POSS_XDIE1
    S_POSS_XDIE2
    S_POSS_XDIE3
    S_POSS_XDIE4
    S_POSS_XDIE5
    S_POSS_XDIE6
    S_POSS_XDIE7
    S_POSS_XDIE8
    S_POSS_XDIE9
    S_POSS_RAISE1
    S_POSS_RAISE2
    S_POSS_RAISE3
    S_POSS_RAISE4
    S_SPOS_STND
    S_SPOS_STND2
    S_SPOS_RUN1
    S_SPOS_RUN2
    S_SPOS_RUN3
    S_SPOS_RUN4
    S_SPOS_RUN5
    S_SPOS_RUN6
    S_SPOS_RUN7
    S_SPOS_RUN8
    S_SPOS_ATK1
    S_SPOS_ATK2
    S_SPOS_ATK3
    S_SPOS_PAIN
    S_SPOS_PAIN2
    S_SPOS_DIE1
    S_SPOS_DIE2
    S_SPOS_DIE3
    S_SPOS_DIE4
    S_SPOS_DIE5
    S_SPOS_XDIE1
    S_SPOS_XDIE2
    S_SPOS_XDIE3
    S_SPOS_XDIE4
    S_SPOS_XDIE5
    S_SPOS_XDIE6
    S_SPOS_XDIE7
    S_SPOS_XDIE8
    S_SPOS_XDIE9
    S_SPOS_RAISE1
    S_SPOS_RAISE2
    S_SPOS_RAISE3
    S_SPOS_RAISE4
    S_SPOS_RAISE5
    S_VILE_STND
    S_VILE_STND2
    S_VILE_RUN1
    S_VILE_RUN2
    S_VILE_RUN3
    S_VILE_RUN4
    S_VILE_RUN5
    S_VILE_RUN6
    S_VILE_RUN7
    S_VILE_RUN8
    S_VILE_RUN9
    S_VILE_RUN10
    S_VILE_RUN11
    S_VILE_RUN12
    S_VILE_ATK1
    S_VILE_ATK2
    S_VILE_ATK3
    S_VILE_ATK4
    S_VILE_ATK5
    S_VILE_ATK6
    S_VILE_ATK7
    S_VILE_ATK8
    S_VILE_ATK9
    S_VILE_ATK10
    S_VILE_ATK11
    S_VILE_HEAL1
    S_VILE_HEAL2
    S_VILE_HEAL3
    S_VILE_PAIN
    S_VILE_PAIN2
    S_VILE_DIE1
    S_VILE_DIE2
    S_VILE_DIE3
    S_VILE_DIE4
    S_VILE_DIE5
    S_VILE_DIE6
    S_VILE_DIE7
    S_VILE_DIE8
    S_VILE_DIE9
    S_VILE_DIE10
    S_FIRE1
    S_FIRE2
    S_FIRE3
    S_FIRE4
    S_FIRE5
    S_FIRE6
    S_FIRE7
    S_FIRE8
    S_FIRE9
    S_FIRE10
    S_FIRE11
    S_FIRE12
    S_FIRE13
    S_FIRE14
    S_FIRE15
    S_FIRE16
    S_FIRE17
    S_FIRE18
    S_FIRE19
    S_FIRE20
    S_FIRE21
    S_FIRE22
    S_FIRE23
    S_FIRE24
    S_FIRE25
    S_FIRE26
    S_FIRE27
    S_FIRE28
    S_FIRE29
    S_FIRE30
    S_SMOKE1
    S_SMOKE2
    S_SMOKE3
    S_SMOKE4
    S_SMOKE5
    S_TRACER
    S_TRACER2
    S_TRACEEXP1
    S_TRACEEXP2
    S_TRACEEXP3
    S_SKEL_STND
    S_SKEL_STND2
    S_SKEL_RUN1
    S_SKEL_RUN2
    S_SKEL_RUN3
    S_SKEL_RUN4
    S_SKEL_RUN5
    S_SKEL_RUN6
    S_SKEL_RUN7
    S_SKEL_RUN8
    S_SKEL_RUN9
    S_SKEL_RUN10
    S_SKEL_RUN11
    S_SKEL_RUN12
    S_SKEL_FIST1
    S_SKEL_FIST2
    S_SKEL_FIST3
    S_SKEL_FIST4
    S_SKEL_MISS1
    S_SKEL_MISS2
    S_SKEL_MISS3
    S_SKEL_MISS4
    S_SKEL_PAIN
    S_SKEL_PAIN2
    S_SKEL_DIE1
    S_SKEL_DIE2
    S_SKEL_DIE3
    S_SKEL_DIE4
    S_SKEL_DIE5
    S_SKEL_DIE6
    S_SKEL_RAISE1
    S_SKEL_RAISE2
    S_SKEL_RAISE3
    S_SKEL_RAISE4
    S_SKEL_RAISE5
    S_SKEL_RAISE6
    S_FATSHOT1
    S_FATSHOT2
    S_FATSHOTX1
    S_FATSHOTX2
    S_FATSHOTX3
    S_FATT_STND
    S_FATT_STND2
    S_FATT_RUN1
    S_FATT_RUN2
    S_FATT_RUN3
    S_FATT_RUN4
    S_FATT_RUN5
    S_FATT_RUN6
    S_FATT_RUN7
    S_FATT_RUN8
    S_FATT_RUN9
    S_FATT_RUN10
    S_FATT_RUN11
    S_FATT_RUN12
    S_FATT_ATK1
    S_FATT_ATK2
    S_FATT_ATK3
    S_FATT_ATK4
    S_FATT_ATK5
    S_FATT_ATK6
    S_FATT_ATK7
    S_FATT_ATK8
    S_FATT_ATK9
    S_FATT_ATK10
    S_FATT_PAIN
    S_FATT_PAIN2
    S_FATT_DIE1
    S_FATT_DIE2
    S_FATT_DIE3
    S_FATT_DIE4
    S_FATT_DIE5
    S_FATT_DIE6
    S_FATT_DIE7
    S_FATT_DIE8
    S_FATT_DIE9
    S_FATT_DIE10
    S_FATT_RAISE1
    S_FATT_RAISE2
    S_FATT_RAISE3
    S_FATT_RAISE4
    S_FATT_RAISE5
    S_FATT_RAISE6
    S_FATT_RAISE7
    S_FATT_RAISE8
    S_CPOS_STND
    S_CPOS_STND2
    S_CPOS_RUN1
    S_CPOS_RUN2
    S_CPOS_RUN3
    S_CPOS_RUN4
    S_CPOS_RUN5
    S_CPOS_RUN6
    S_CPOS_RUN7
    S_CPOS_RUN8
    S_CPOS_ATK1
    S_CPOS_ATK2
    S_CPOS_ATK3
    S_CPOS_ATK4
    S_CPOS_PAIN
    S_CPOS_PAIN2
    S_CPOS_DIE1
    S_CPOS_DIE2
    S_CPOS_DIE3
    S_CPOS_DIE4
    S_CPOS_DIE5
    S_CPOS_DIE6
    S_CPOS_DIE7
    S_CPOS_XDIE1
    S_CPOS_XDIE2
    S_CPOS_XDIE3
    S_CPOS_XDIE4
    S_CPOS_XDIE5
    S_CPOS_XDIE6
    S_CPOS_RAISE1
    S_CPOS_RAISE2
    S_CPOS_RAISE3
    S_CPOS_RAISE4
    S_CPOS_RAISE5
    S_CPOS_RAISE6
    S_CPOS_RAISE7
    S_TROO_STND
    S_TROO_STND2
    S_TROO_RUN1
    S_TROO_RUN2
    S_TROO_RUN3
    S_TROO_RUN4
    S_TROO_RUN5
    S_TROO_RUN6
    S_TROO_RUN7
    S_TROO_RUN8
    S_TROO_ATK1
    S_TROO_ATK2
    S_TROO_ATK3
    S_TROO_PAIN
    S_TROO_PAIN2
    S_TROO_DIE1
    S_TROO_DIE2
    S_TROO_DIE3
    S_TROO_DIE4
    S_TROO_DIE5
    S_TROO_XDIE1
    S_TROO_XDIE2
    S_TROO_XDIE3
    S_TROO_XDIE4
    S_TROO_XDIE5
    S_TROO_XDIE6
    S_TROO_XDIE7
    S_TROO_XDIE8
    S_TROO_RAISE1
    S_TROO_RAISE2
    S_TROO_RAISE3
    S_TROO_RAISE4
    S_TROO_RAISE5
    S_SARG_STND
    S_SARG_STND2
    S_SARG_RUN1
    S_SARG_RUN2
    S_SARG_RUN3
    S_SARG_RUN4
    S_SARG_RUN5
    S_SARG_RUN6
    S_SARG_RUN7
    S_SARG_RUN8
    S_SARG_ATK1
    S_SARG_ATK2
    S_SARG_ATK3
    S_SARG_PAIN
    S_SARG_PAIN2
    S_SARG_DIE1
    S_SARG_DIE2
    S_SARG_DIE3
    S_SARG_DIE4
    S_SARG_DIE5
    S_SARG_DIE6
    S_SARG_RAISE1
    S_SARG_RAISE2
    S_SARG_RAISE3
    S_SARG_RAISE4
    S_SARG_RAISE5
    S_SARG_RAISE6
    S_HEAD_STND
    S_HEAD_RUN1
    S_HEAD_ATK1
    S_HEAD_ATK2
    S_HEAD_ATK3
    S_HEAD_PAIN
    S_HEAD_PAIN2
    S_HEAD_PAIN3
    S_HEAD_DIE1
    S_HEAD_DIE2
    S_HEAD_DIE3
    S_HEAD_DIE4
    S_HEAD_DIE5
    S_HEAD_DIE6
    S_HEAD_RAISE1
    S_HEAD_RAISE2
    S_HEAD_RAISE3
    S_HEAD_RAISE4
    S_HEAD_RAISE5
    S_HEAD_RAISE6
    S_BRBALL1
    S_BRBALL2
    S_BRBALLX1
    S_BRBALLX2
    S_BRBALLX3
    S_BOSS_STND
    S_BOSS_STND2
    S_BOSS_RUN1
    S_BOSS_RUN2
    S_BOSS_RUN3
    S_BOSS_RUN4
    S_BOSS_RUN5
    S_BOSS_RUN6
    S_BOSS_RUN7
    S_BOSS_RUN8
    S_BOSS_ATK1
    S_BOSS_ATK2
    S_BOSS_ATK3
    S_BOSS_PAIN
    S_BOSS_PAIN2
    S_BOSS_DIE1
    S_BOSS_DIE2
    S_BOSS_DIE3
    S_BOSS_DIE4
    S_BOSS_DIE5
    S_BOSS_DIE6
    S_BOSS_DIE7
    S_BOSS_RAISE1
    S_BOSS_RAISE2
    S_BOSS_RAISE3
    S_BOSS_RAISE4
    S_BOSS_RAISE5
    S_BOSS_RAISE6
    S_BOSS_RAISE7
    S_BOS2_STND
    S_BOS2_STND2
    S_BOS2_RUN1
    S_BOS2_RUN2
    S_BOS2_RUN3
    S_BOS2_RUN4
    S_BOS2_RUN5
    S_BOS2_RUN6
    S_BOS2_RUN7
    S_BOS2_RUN8
    S_BOS2_ATK1
    S_BOS2_ATK2
    S_BOS2_ATK3
    S_BOS2_PAIN
    S_BOS2_PAIN2
    S_BOS2_DIE1
    S_BOS2_DIE2
    S_BOS2_DIE3
    S_BOS2_DIE4
    S_BOS2_DIE5
    S_BOS2_DIE6
    S_BOS2_DIE7
    S_BOS2_RAISE1
    S_BOS2_RAISE2
    S_BOS2_RAISE3
    S_BOS2_RAISE4
    S_BOS2_RAISE5
    S_BOS2_RAISE6
    S_BOS2_RAISE7
    S_SKULL_STND
    S_SKULL_STND2
    S_SKULL_RUN1
    S_SKULL_RUN2
    S_SKULL_ATK1
    S_SKULL_ATK2
    S_SKULL_ATK3
    S_SKULL_ATK4
    S_SKULL_PAIN
    S_SKULL_PAIN2
    S_SKULL_DIE1
    S_SKULL_DIE2
    S_SKULL_DIE3
    S_SKULL_DIE4
    S_SKULL_DIE5
    S_SKULL_DIE6
    S_SPID_STND
    S_SPID_STND2
    S_SPID_RUN1
    S_SPID_RUN2
    S_SPID_RUN3
    S_SPID_RUN4
    S_SPID_RUN5
    S_SPID_RUN6
    S_SPID_RUN7
    S_SPID_RUN8
    S_SPID_RUN9
    S_SPID_RUN10
    S_SPID_RUN11
    S_SPID_RUN12
    S_SPID_ATK1
    S_SPID_ATK2
    S_SPID_ATK3
    S_SPID_ATK4
    S_SPID_PAIN
    S_SPID_PAIN2
    S_SPID_DIE1
    S_SPID_DIE2
    S_SPID_DIE3
    S_SPID_DIE4
    S_SPID_DIE5
    S_SPID_DIE6
    S_SPID_DIE7
    S_SPID_DIE8
    S_SPID_DIE9
    S_SPID_DIE10
    S_SPID_DIE11
    S_BSPI_STND
    S_BSPI_STND2
    S_BSPI_SIGHT
    S_BSPI_RUN1
    S_BSPI_RUN2
    S_BSPI_RUN3
    S_BSPI_RUN4
    S_BSPI_RUN5
    S_BSPI_RUN6
    S_BSPI_RUN7
    S_BSPI_RUN8
    S_BSPI_RUN9
    S_BSPI_RUN10
    S_BSPI_RUN11
    S_BSPI_RUN12
    S_BSPI_ATK1
    S_BSPI_ATK2
    S_BSPI_ATK3
    S_BSPI_ATK4
    S_BSPI_PAIN
    S_BSPI_PAIN2
    S_BSPI_DIE1
    S_BSPI_DIE2
    S_BSPI_DIE3
    S_BSPI_DIE4
    S_BSPI_DIE5
    S_BSPI_DIE6
    S_BSPI_DIE7
    S_BSPI_RAISE1
    S_BSPI_RAISE2
    S_BSPI_RAISE3
    S_BSPI_RAISE4
    S_BSPI_RAISE5
    S_BSPI_RAISE6
    S_BSPI_RAISE7
    S_ARACH_PLAZ
    S_ARACH_PLAZ2
    S_ARACH_PLEX
    S_ARACH_PLEX2
    S_ARACH_PLEX3
    S_ARACH_PLEX4
    S_ARACH_PLEX5
    S_CYBER_STND
    S_CYBER_STND2
    S_CYBER_RUN1
    S_CYBER_RUN2
    S_CYBER_RUN3
    S_CYBER_RUN4
    S_CYBER_RUN5
    S_CYBER_RUN6
    S_CYBER_RUN7
    S_CYBER_RUN8
    S_CYBER_ATK1
    S_CYBER_ATK2
    S_CYBER_ATK3
    S_CYBER_ATK4
    S_CYBER_ATK5
    S_CYBER_ATK6
    S_CYBER_PAIN
    S_CYBER_DIE1
    S_CYBER_DIE2
    S_CYBER_DIE3
    S_CYBER_DIE4
    S_CYBER_DIE5
    S_CYBER_DIE6
    S_CYBER_DIE7
    S_CYBER_DIE8
    S_CYBER_DIE9
    S_CYBER_DIE10
    S_PAIN_STND
    S_PAIN_RUN1
    S_PAIN_RUN2
    S_PAIN_RUN3
    S_PAIN_RUN4
    S_PAIN_RUN5
    S_PAIN_RUN6
    S_PAIN_ATK1
    S_PAIN_ATK2
    S_PAIN_ATK3
    S_PAIN_ATK4
    S_PAIN_PAIN
    S_PAIN_PAIN2
    S_PAIN_DIE1
    S_PAIN_DIE2
    S_PAIN_DIE3
    S_PAIN_DIE4
    S_PAIN_DIE5
    S_PAIN_DIE6
    S_PAIN_RAISE1
    S_PAIN_RAISE2
    S_PAIN_RAISE3
    S_PAIN_RAISE4
    S_PAIN_RAISE5
    S_PAIN_RAISE6
    S_SSWV_STND
    S_SSWV_STND2
    S_SSWV_RUN1
    S_SSWV_RUN2
    S_SSWV_RUN3
    S_SSWV_RUN4
    S_SSWV_RUN5
    S_SSWV_RUN6
    S_SSWV_RUN7
    S_SSWV_RUN8
    S_SSWV_ATK1
    S_SSWV_ATK2
    S_SSWV_ATK3
    S_SSWV_ATK4
    S_SSWV_ATK5
    S_SSWV_ATK6
    S_SSWV_PAIN
    S_SSWV_PAIN2
    S_SSWV_DIE1
    S_SSWV_DIE2
    S_SSWV_DIE3
    S_SSWV_DIE4
    S_SSWV_DIE5
    S_SSWV_XDIE1
    S_SSWV_XDIE2
    S_SSWV_XDIE3
    S_SSWV_XDIE4
    S_SSWV_XDIE5
    S_SSWV_XDIE6
    S_SSWV_XDIE7
    S_SSWV_XDIE8
    S_SSWV_XDIE9
    S_SSWV_RAISE1
    S_SSWV_RAISE2
    S_SSWV_RAISE3
    S_SSWV_RAISE4
    S_SSWV_RAISE5
    S_KEENSTND
    S_COMMKEEN
    S_COMMKEEN2
    S_COMMKEEN3
    S_COMMKEEN4
    S_COMMKEEN5
    S_COMMKEEN6
    S_COMMKEEN7
    S_COMMKEEN8
    S_COMMKEEN9
    S_COMMKEEN10
    S_COMMKEEN11
    S_COMMKEEN12
    S_KEENPAIN
    S_KEENPAIN2
    S_BRAIN
    S_BRAIN_PAIN
    S_BRAIN_DIE1
    S_BRAIN_DIE2
    S_BRAIN_DIE3
    S_BRAIN_DIE4
    S_BRAINEYE
    S_BRAINEYESEE
    S_BRAINEYE1
    S_SPAWN1
    S_SPAWN2
    S_SPAWN3
    S_SPAWN4
    S_SPAWNFIRE1
    S_SPAWNFIRE2
    S_SPAWNFIRE3
    S_SPAWNFIRE4
    S_SPAWNFIRE5
    S_SPAWNFIRE6
    S_SPAWNFIRE7
    S_SPAWNFIRE8
    S_BRAINEXPLODE1
    S_BRAINEXPLODE2
    S_BRAINEXPLODE3
    S_ARM1
    S_ARM1A
    S_ARM2
    S_ARM2A
    S_BAR1
    S_BAR2
    S_BEXP
    S_BEXP2
    S_BEXP3
    S_BEXP4
    S_BEXP5
    S_BBAR1
    S_BBAR2
    S_BBAR3
    S_BON1
    S_BON1A
    S_BON1B
    S_BON1C
    S_BON1D
    S_BON1E
    S_BON2
    S_BON2A
    S_BON2B
    S_BON2C
    S_BON2D
    S_BON2E
    S_BKEY
    S_BKEY2
    S_RKEY
    S_RKEY2
    S_YKEY
    S_YKEY2
    S_BSKULL
    S_BSKULL2
    S_RSKULL
    S_RSKULL2
    S_YSKULL
    S_YSKULL2
    S_STIM
    S_MEDI
    S_SOUL
    S_SOUL2
    S_SOUL3
    S_SOUL4
    S_SOUL5
    S_SOUL6
    S_PINV
    S_PINV2
    S_PINV3
    S_PINV4
    S_PSTR
    S_PINS
    S_PINS2
    S_PINS3
    S_PINS4
    S_MEGA
    S_MEGA2
    S_MEGA3
    S_MEGA4
    S_SUIT
    S_PMAP
    S_PMAP2
    S_PMAP3
    S_PMAP4
    S_PMAP5
    S_PMAP6
    S_PVIS
    S_PVIS2
    S_CLIP
    S_AMMO
    S_ROCK
    S_BROK
    S_CELL
    S_CELP
    S_SHEL
    S_SBOX
    S_BPAK
    S_BFUG
    S_MGUN
    S_CSAW
    S_LAUN
    S_PLAS
    S_SHOT
    S_SHOT2
    S_COLU
    S_STALAG
    S_BLOODYTWITCH
    S_BLOODYTWITCH2
    S_BLOODYTWITCH3
    S_BLOODYTWITCH4
    S_DEADTORSO
    S_DEADBOTTOM
    S_HEADSONSTICK
    S_GIBS
    S_HEADONASTICK
    S_HEADCANDLES
    S_HEADCANDLES2
    S_DEADSTICK
    S_LIVESTICK
    S_LIVESTICK2
    S_MEAT2
    S_MEAT3
    S_MEAT4
    S_MEAT5
    S_STALAGTITE
    S_TALLGRNCOL
    S_SHRTGRNCOL
    S_TALLREDCOL
    S_SHRTREDCOL
    S_CANDLESTIK
    S_CANDELABRA
    S_SKULLCOL
    S_TORCHTREE
    S_BIGTREE
    S_TECHPILLAR
    S_EVILEYE
    S_EVILEYE2
    S_EVILEYE3
    S_EVILEYE4
    S_FLOATSKULL
    S_FLOATSKULL2
    S_FLOATSKULL3
    S_HEARTCOL
    S_HEARTCOL2
    S_BLUETORCH
    S_BLUETORCH2
    S_BLUETORCH3
    S_BLUETORCH4
    S_GREENTORCH
    S_GREENTORCH2
    S_GREENTORCH3
    S_GREENTORCH4
    S_REDTORCH
    S_REDTORCH2
    S_REDTORCH3
    S_REDTORCH4
    S_BTORCHSHRT
    S_BTORCHSHRT2
    S_BTORCHSHRT3
    S_BTORCHSHRT4
    S_GTORCHSHRT
    S_GTORCHSHRT2
    S_GTORCHSHRT3
    S_GTORCHSHRT4
    S_RTORCHSHRT
    S_RTORCHSHRT2
    S_RTORCHSHRT3
    S_RTORCHSHRT4
    S_HANGNOGUTS
    S_HANGBNOBRAIN
    S_HANGTLOOKDN
    S_HANGTSKULL
    S_HANGTLOOKUP
    S_HANGTNOBRAIN
    S_COLONGIBS
    S_SMALLPOOL
    S_BRAINSTEM
    S_TECHLAMP
    S_TECHLAMP2
    S_TECHLAMP3
    S_TECHLAMP4
    S_TECH2LAMP
    S_TECH2LAMP2
    S_TECH2LAMP3
    S_TECH2LAMP4
    NUMSTATES
  end

  struct State
    sprite : Spritenum
    frame : LibC::LongLong
    tics : LibC::LongLong
    action : Void*
    nextstate : Statenum
    misc1 : LibC::LongLong
    misc2 : LibC::LongLong
  end

  enum Mobjtype
    MT_PLAYER
    MT_POSSESSED
    MT_SHOTGUY
    MT_VILE
    MT_FIRE
    MT_UNDEAD
    MT_TRACER
    MT_SMOKE
    MT_FATSO
    MT_FATSHOT
    MT_CHAINGUY
    MT_TROOP
    MT_SERGEANT
    MT_SHADOWS
    MT_HEAD
    MT_BRUISER
    MT_BRUISERSHOT
    MT_KNIGHT
    MT_SKULL
    MT_SPIDER
    MT_BABY
    MT_CYBORG
    MT_PAIN
    MT_WOLFSS
    MT_KEEN
    MT_BOSSBRAIN
    MT_BOSSSPIT
    MT_BOSSTARGET
    MT_SPAWNSHOT
    MT_SPAWNFIRE
    MT_BARREL
    MT_TROOPSHOT
    MT_HEADSHOT
    MT_ROCKET
    MT_PLASMA
    MT_BFG
    MT_ARACHPLAZ
    MT_PUFF
    MT_BLOOD
    MT_TFOG
    MT_IFOG
    MT_TELEPORTMAN
    MT_EXTRABFG
    MT_MISC0
    MT_MISC1
    MT_MISC2
    MT_MISC3
    MT_MISC4
    MT_MISC5
    MT_MISC6
    MT_MISC7
    MT_MISC8
    MT_MISC9
    MT_MISC10
    MT_MISC11
    MT_MISC12
    MT_INV
    MT_MISC13
    MT_INS
    MT_MISC14
    MT_MISC15
    MT_MISC16
    MT_MEGA
    MT_CLIP
    MT_MISC17
    MT_MISC18
    MT_MISC19
    MT_MISC20
    MT_MISC21
    MT_MISC22
    MT_MISC23
    MT_MISC24
    MT_MISC25
    MT_CHAINGUN
    MT_MISC26
    MT_MISC27
    MT_MISC28
    MT_SHOTGUN
    MT_SUPERSHOTGUN
    MT_MISC29
    MT_MISC30
    MT_MISC31
    MT_MISC32
    MT_MISC33
    MT_MISC34
    MT_MISC35
    MT_MISC36
    MT_MISC37
    MT_MISC38
    MT_MISC39
    MT_MISC40
    MT_MISC41
    MT_MISC42
    MT_MISC43
    MT_MISC44
    MT_MISC45
    MT_MISC46
    MT_MISC47
    MT_MISC48
    MT_MISC49
    MT_MISC50
    MT_MISC51
    MT_MISC52
    MT_MISC53
    MT_MISC54
    MT_MISC55
    MT_MISC56
    MT_MISC57
    MT_MISC58
    MT_MISC59
    MT_MISC60
    MT_MISC61
    MT_MISC62
    MT_MISC63
    MT_MISC64
    MT_MISC65
    MT_MISC66
    MT_MISC67
    MT_MISC68
    MT_MISC69
    MT_MISC70
    MT_MISC71
    MT_MISC72
    MT_MISC73
    MT_MISC74
    MT_MISC75
    MT_MISC76
    MT_MISC77
    MT_MISC78
    MT_MISC79
    MT_MISC80
    MT_MISC81
    MT_MISC82
    MT_MISC83
    MT_MISC84
    MT_MISC85
    MT_MISC86
    NUMMOBJTYPES
  end

  struct Mobjinfo
    doomednum : LibC::Int
    spawnstate : LibC::Int
    spawnhealth : LibC::Int
    seestate : LibC::Int
    seesound : LibC::Int
    reactiontime : LibC::Int
    attacksound : LibC::Int
    painstate : LibC::Int
    painchance : LibC::Int
    painsound : LibC::Int
    meleestate : LibC::Int
    missilestate : LibC::Int
    deathstate : LibC::Int
    xdeathstate : LibC::Int
    deathsound : LibC::Int
    speed : LibC::Int
    radius : LibC::Int
    height : LibC::Int
    mass : LibC::Int
    damage : LibC::Int
    activesound : LibC::Int
    flags : LibC::Int
    raisestate : LibC::Int
  end

  # __M__ARGV__

  # __M_CHEAT__

  #
  # CHEAT SEQUENCE PACKAGE
  #

  struct Cheatseq
    sequence : LibC::UChar*
    p : LibC::UChar*
  end

  fun cht_check_cheat = cht_CheckCheat(cht : Cheatseq*, key : LibC::Char) : LibC::Int
  fun cht_get_param = cht_GetParam(cht : Cheatseq*, buffer : LibC::Char*)

  # __M_FIXED__

  #
  # Fixed point, 32bit as 16.16.
  #

  alias Fixed = LibC::Int

  fun fixed_mul = FixedMul(a : Fixed, b : Fixed) : Fixed
  fun fixed_div = FixedDiv(a : Fixed, b : Fixed) : Fixed
  fun fixed_div2 = FixedDiv2(a : Fixed, b : Fixed) : Fixed

  # __M_BBOX__

  # Bounding box coordinate storage.
  BOXTOP    = 0
  BOXBOTTOM = 1
  BOXLEFT   = 2
  BOXRIGHT  = 3
  # bbox coordinates

  # Bounding box functions
  fun m_clear_box = M_ClearBox(box : Fixed*)
  fun m_add_to_box = M_AddToBox(box : Fixed*, x : Fixed, y : Fixed)

  # __M_MENU__

  #
  # MENUS
  #

  # Called by main loop,
  # only used for menu (skull cursor) animation.
  fun m_ticker = M_Ticker

  # Called by main loop,
  # draws the menus directly into the screen buffer.
  fun m_drawer = M_Drawer

  # Called by intro code to force menu up upon a keypress,
  # does nothing if menu is already up.
  fun m_start_control_panel = M_StartControlPanel

  # __M_MISC__

  #
  # MISC
  #
  fun m_write_file = M_WriteFile(name : LibC::Char*, source : Void*, length : LibC::Int) : DoomBool
  fun m_read_file = M_ReadFile(name : LibC::Char*, buffer : Byte**) : LibC::Int
  fun m_screenshot = M_ScreenShot
  fun m_load_defaults = M_LoadDefaults
  fun m_save_defaults = M_SaveDefaults
  fun m_draw_text(x : LibC::Int, y : LibC::Int, direct : DoomBool, string : LibC::Char*) : LibC::Int

  # __M_RANDOM__

  # Returns a number from 0 to 255,
  # from a lookup table.
  fun m_random = M_Random : LibC::Int

  # As M_Random, but used only by the play simulation.
  fun p_random = P_Random : LibC::Int

  # Fix randoms for demos.
  fun m_clear_random = M_ClearRandom

  # __P_SAVEG__

  # Persistent storage/archiving.
  # These are the load / save game routines.
  fun p_archive_players = P_ArchivePlayers
  fun p_unarchive_players = P_UnArchivePlayers
  fun p_archive_world = P_ArchiveWorld
  fun p_unarchive_world = P_UnArchiveWorld
  fun p_archive_thinkers = P_ArchiveThinkers
  fun p_unarchive_thinkers = P_UnArchiveThinkers
  fun p_archive_specials = P_ArchiveSpecials
  fun p_unarchive_specials = P_UnArchiveSpecials


  # __P_SETUP__

  # NOT called by W_Ticker. Fixme.
  fun p_setup_level = P_SetupLevel(episode : LibC::Int, map : LibC::Int, playermask : LibC::Int, skill : Skill)

  # Called by startup code.
  fun p_init = P_Init

  # __P_TICK__

  # Called by C_Ticker,
  # can call G_PlayerExited.
  # Carries out all thinking of monsters and players.
  fun p_ticker = P_Ticker

  # __R_SKY__

  # SKY, store the number for name.
  SKYFLATNAME = "F_SKY1"

  # The sky map is 256*128*4 maps.
  ANGLETOSKYSHIFT = 22

  # Called whenever the view size changes.
  fun r_init_sky_map = R_InitSkyMap

  # __S_SOUND__

  #
  # Initializes sound stuff, including volume
  # Sets channels, SFX and music volume,
  # allocates channel buffer, sets S_sfx lookup.
  #
  fun s_init = S_Init(sfx_volume : LibC::Int, music_volume : LibC::Int)

  #
  # Per level startup code.
  # Kills playing sounds at start of level,
  #  determines music if any, changes music.
  #
  fun s_start = S_Start

  #
  # Start sound for thing at <origin>
  #  using <sound_id> from sounds.h
  #
  fun s_start_sound = S_StartSound(origin : Void*, sfx_id : LibC::Int)

  # Will start a sound at a given volume.
  fun s_start_sound_at_volume = S_StartSoundAtVolume(origin_p : Void*, sfx_id : LibC::Int, volume : LibC::Int)

  # Stop sound for thing at <origin>
  fun s_stop_sound = S_StopSound(origin : Void*)

  # Start music using <music_id> from sounds.h
  fun s_start_music = S_StartMusic(music_id : LibC::Int)

  # Start music using <music_id> from sounds.h,
  # and set whether looping
  fun s_change_music = S_ChangeMusic(music_id : LibC::Int, looping : LibC::Int)

  # Stops the music fer sure.
  fun s_stop_music = S_StopMusic

  # Stop and resume music, during game PAUSE.
  fun s_pause_sound = S_PauseSound
  fun s_resume_sound = S_ResumeSound

  #
  # Updates music & sounds
  #
  fun s_update_sounds = S_UpdateSounds(listener_p : Void*)

  fun s_set_music_volume = S_SetMusicVolume(volume : LibC::Int)

  # __SOUNDS__

  #
  # SoundFX struct.
  #
  struct Sfxinfo
    name : LibC::Char*
    singularity : LibC::Int
    priority : LibC::Int
    link : Sfxinfo*
    pitch : LibC::Int
    volume : LibC::Int
    data : Void*
    usefulness : LibC::Int
    lumpnum : LibC::Int
  end

  #
  #
  # Identifiers for all music in game.
  #
  enum Musicenum
    MUS_None
    MUS_e1m1
    MUS_e1m2
    MUS_e1m3
    MUS_e1m4
    MUS_e1m5
    MUS_e1m6
    MUS_e1m7
    MUS_e1m8
    MUS_e1m9
    MUS_e2m1
    MUS_e2m2
    MUS_e2m3
    MUS_e2m4
    MUS_e2m5
    MUS_e2m6
    MUS_e2m7
    MUS_e2m8
    MUS_e2m9
    MUS_e3m1
    MUS_e3m2
    MUS_e3m3
    MUS_e3m4
    MUS_e3m5
    MUS_e3m6
    MUS_e3m7
    MUS_e3m8
    MUS_e3m9
    MUS_inter
    MUS_intro
    MUS_bunny
    MUS_victor
    MUS_introa
    MUS_runnin
    MUS_stalks
    MUS_countd
    MUS_betwee
    MUS_doom
    MUS_the_da
    MUS_shawn
    MUS_ddtblu
    MUS_in_cit
    MUS_dead
    MUS_stlks2
    MUS_theda2
    MUS_doom2
    MUS_ddtbl2
    MUS_runni2
    MUS_dead2
    MUS_stlks3
    MUS_romero
    MUS_shawn2
    MUS_messag
    MUS_count2
    MUS_ddtbl3
    MUS_ampie
    MUS_theda3
    MUS_adrian
    MUS_messg2
    MUS_romer2
    MUS_tense
    MUS_shawn3
    MUS_openin
    MUS_evil
    MUS_ultima
    MUS_read_m
    MUS_dm2ttl
    MUS_dm2int
    NUMMUSIC
  end

  #
  # Identifiers for all sfx in game.
  #
  enum Sfxenum
    SFX_None
    SFX_pistol
    SFX_shotgn
    SFX_sgcock
    SFX_dshtgn
    SFX_dbopn
    SFX_dbcls
    SFX_dbload
    SFX_plasma
    SFX_bfg
    SFX_sawup
    SFX_sawidl
    SFX_sawful
    SFX_sawhit
    SFX_rlaunc
    SFX_rxplod
    SFX_firsht
    SFX_firxpl
    SFX_pstart
    SFX_pstop
    SFX_doropn
    SFX_dorcls
    SFX_stnmov
    SFX_swtchn
    SFX_swtchx
    SFX_plpain
    SFX_dmpain
    SFX_popain
    SFX_vipain
    SFX_mnpain
    SFX_pepain
    SFX_slop
    SFX_itemup
    SFX_wpnup
    SFX_oof
    SFX_telept
    SFX_posit1
    SFX_posit2
    SFX_posit3
    SFX_bgsit1
    SFX_bgsit2
    SFX_sgtsit
    SFX_cacsit
    SFX_brssit
    SFX_cybsit
    SFX_spisit
    SFX_bspsit
    SFX_kntsit
    SFX_vilsit
    SFX_mansit
    SFX_pesit
    SFX_sklatk
    SFX_sgtatk
    SFX_skepch
    SFX_vilatk
    SFX_claw
    SFX_skeswg
    SFX_pldeth
    SFX_pdiehi
    SFX_podth1
    SFX_podth2
    SFX_podth3
    SFX_bgdth1
    SFX_bgdth2
    SFX_sgtdth
    SFX_cacdth
    SFX_skldth
    SFX_brsdth
    SFX_cybdth
    SFX_spidth
    SFX_bspdth
    SFX_vildth
    SFX_kntdth
    SFX_pedth
    SFX_skedth
    SFX_posact
    SFX_bgact
    SFX_dmact
    SFX_bspact
    SFX_bspwlk
    SFX_vilact
    SFX_noway
    SFX_barexp
    SFX_punch
    SFX_hoof
    SFX_metal
    SFX_chgun
    SFX_tink
    SFX_bdopn
    SFX_bdcls
    SFX_itmbk
    SFX_flame
    SFX_flamst
    SFX_getpow
    SFX_bospit
    SFX_boscub
    SFX_bossit
    SFX_bospn
    SFX_bosdth
    SFX_manatk
    SFX_mandth
    SFX_sssit
    SFX_ssdth
    SFX_keenpn
    SFX_keendt
    SFX_skeact
    SFX_skesit
    SFX_skeatk
    SFX_radio
    NUMSFX
  end

  # __STSTUFF_H__

  # Size of statusbar.
  # Now sensitive for scaling.
  ST_HEIGHT = (32 * SCREEN_MUL)
  ST_WIDTH  = SCREENWIDTH
  ST_Y      = (SCREENHEIGHT - ST_HEIGHT)

  #
  # STATUS BAR
  #

  # Called by main loop.
  fun st_responder = ST_Responder(ev : Event*) : DoomBool

  # Called by main loop.
  fun st_ticker = ST_Ticker

  # Called by main loop.
  fun st_drawer = ST_Drawer(fullscreen : DoomBool, refresh : DoomBool)

  # Called when the console player is spawned on each level.
  fun st_start = ST_Start

  # Called by startup code.
  fun st_init = ST_Init

  # States for status bar code.
  enum ST_Statenum
    AutomapState
    FirstPersonState
  end

  # States for the chat code.
  enum ST_Chatstateenum
    StartChatState
    WaitDestState
    GetChatState
  end

  # __TABLES__

  FINEANGLES = 8192
  FINEMASK   = (FINEANGLES - 1)

  # 0x100000000 to 0x2000
  ANGLETOFINESHIFT = 19

  # Effective size is 10240.

  # Re-use data, is just PI/2 pahse shift.

  # Effective size is 4096.

  alias Angle = LibC::UInt

  # Effective size is 2049;
  # The +1 size is to handle the case when x==y
  #  without additional checking.

  # Utility function,
  #  called by R_PointToAngle.
  fun slope_div = SlopeDiv(num : LibC::UInt, den : LibC::UInt) : LibC::Int

  # __P_MOBJ__

  #
  # NOTES: mobj_t
  #
  # mobj_ts are used to tell the refresh where to draw an image,
  # tell the world simulation when objects are contacted,
  # and tell the sound driver how to position a sound.
  #
  # The refresh uses the next and prev links to follow
  # lists of things in sectors as they are being drawn.
  # The sprite, frame, and angle elements determine which patch_t
  # is used to draw the sprite if it is visible.
  # The sprite and frame values are allmost allways set
  # from state_t structures.
  # The statescr.exe utility generates the states.h and states.c
  # files that contain the sprite/frame numbers from the
  # statescr.txt source file.
  # The xyz origin point represents a point at the bottom middle
  # of the sprite (between the feet of a biped).
  # This is the default origin position for patch_ts grabbed
  # with lumpy.exe.
  # A walking creature will have its z equal to the floor
  # it is standing on.
  #
  # The sound code uses the x,y, and subsector fields
  # to do stereo positioning of any sound effited by the mobj_t.
  #
  # The play simulation uses the blocklinks, x,y,z, radius, height
  # to determine when mobj_ts are touching each other,
  # touching lines in the map, or hit by trace lines (gunshots,
  # lines of sight, etc).
  # The mobj_t->flags element has various bit flags
  # used by the simulation.
  #
  # Every mobj_t is linked into a single sector
  # based on its origin coordinates.
  # The subsector_t is found with R_PointInSubsector(x,y),
  # and the sector_t can be found with subsector->sector.
  # The sector links are only used by the rendering code,
  # the play simulation does not care about them at all.
  #
  # Any mobj_t that needs to be acted upon by something else
  # in the play world (block movement, be shot, etc) will also
  # need to be linked into the blockmap.
  # If the thing has the MF_NOBLOCK flag set, it will not use
  # the block links. It can still interact with other things,
  # but only as the instigator (missiles will run into other
  # things, but nothing can run into a missile).
  # Each block in the grid is 128*128 units, and knows about
  # every line_t that it contains a piece of, and every
  # interactable mobj_t that has its origin contained.
  #
  # A valid mobj_t is a mobj_t that has the proper subsector_t
  # filled in for its xy coordinates and is linked into the
  # sector from which the subsector was made, or has the
  # MF_NOSECTOR flag set (the subsector_t needs to be valid
  # even if MF_NOSECTOR is set), and is linked into a blockmap
  # block or has the MF_NOBLOCKMAP flag set.
  # Links should only be modified by the P_[Un]SetThingPosition()
  # functions.
  # Do not change the MF_NO? flags while a thing is valid.
  #
  # Any questions?
  #

  #
  # Misc. mobj flags
  #
  enum Mobjflag
    # Call P_SpecialThing when touched.
    MF_SPECIAL = 1
    # Blocks.
    MF_SOLID = 2
    # Can be hit.
    MF_SHOOTABLE = 4
    # Don't use the sector links (invisible but touchable).
    MF_NOSECTOR = 8
    # Don't use the blocklinks (inert but displayable)
    MF_NOBLOCKMAP = 16

    # Not to be activated by sound, deaf monster.
    MF_AMBUSH = 32
    # Will try to attack right back.
    MF_JUSTHIT = 64
    # Will take at least one step before attacking.
    MF_JUSTATTACKED = 128
    # On level spawning (initial position),
    #  hang from ceiling instead of stand on floor.
    MF_SPAWNCEILING = 256
    # Don't apply gravity (every tic),
    #  that is, object will float, keeping current height
    #  or changing it actively.
    MF_NOGRAVITY = 512

    # Movement flags.
    # This allows jumps from high places.
    MF_DROPOFF = 0x400
    # For players, will pick up items.
    MF_PICKUP = 0x800
    # Player cheat. ???
    MF_NOCLIP = 0x1000
    # Player: keep info about sliding along walls.
    MF_SLIDE = 0x2000
    # Allow moves to any height, no gravity.
    # For active floaters, e.g. cacodemons, pain elementals.
    MF_FLOAT = 0x4000
    # Don't cross lines
    #   ??? or look at heights on teleport.
    MF_TELEPORT = 0x8000
    # Don't hit same species, explode on block.
    # Player missiles as well as fireballs of various kinds.
    MF_MISSILE = 0x10000
    # Dropped by a demon, not level spawned.
    # E.g. ammo clips dropped by dying former humans.
    MF_DROPPED = 0x20000
    # Use fuzzy draw (shadow demons or spectres),
    #  temporary player invisibility powerup.
    MF_SHADOW = 0x40000
    # Flag: don't bleed when shot (use puff),
    #  barrels and shootable furniture shall not bleed.
    MF_NOBLOOD = 0x80000
    # Don't stop moving halfway off a step,
    #  that is, have dead bodies slide down all the way.
    MF_CORPSE = 0x100000
    # Floating to a height for a move, ???
    #  don't auto float to target's height.
    MF_INFLOAT = 0x200000

    # On kill, count this enemy object
    #  towards intermission kill total.
    # Happy gathering.
    MF_COUNTKILL = 0x400000

    # On picking up, count this item object
    #  towards intermission item total.
    MF_COUNTITEM = 0x800000

    # Special handling: skull in flight.
    # Neither a cacodemon nor a missile.
    MF_SKULLFLY = 0x1000000

    # Don't spawn this object
    #  in death match mode (e.g. key cards).
    MF_NOTDMATCH = 0x2000000

    # Player sprites in multiplayer modes are modified
    #  using an internal color lookup table for re-indexing.
    # If 0x4 0x8 or 0xc,
    #  use a translation table for player colormaps
    MF_TRANSLATION = 0xc000000
    # Hmm ???.
    MF_TRANSSHIFT = 26
  end

  # Map Object definition.
  struct Mobj
    # List: thinker links.
    thinker : Thinker

    # Info for drawing: position.
    x : Fixed
    y : Fixed
    z : Fixed

    # More list: links in sector (if needed)
    snext : Mobj*
    sprev : Mobj*

    # More drawing info: to determine current sprite.
    angle : Angle      # orientation
    sprite : Spritenum # used to find patch_t and flip value
    frame : LibC::Int  # might be ORed with FF_FULLBRIGHT

    # Interaction info, by BLOCKMAP.
    # Links in blocks (if needed).
    bnext : Mobj*
    bprev : Mobj*

    subsector : Subsector*

    # The closest interval over all contacted Sectors.
    floorz : Fixed
    ceilingz : Fixed

    # For movement checking.
    radius : Fixed
    height : Fixed

    # Momentums, used to update position.
    momx : Fixed
    momy : Fixed
    momz : Fixed

    # If == validcount, already checked.
    # increment every time a check is made
    validcount : LibC::Int

    type : Mobjtype
    info : Mobjinfo* # &mobjinfo[mobj->type]

    tics : LibC::Int # state tic counter
    state : State*
    flags : LibC::Int
    health : LibC::Int

    # Movement direction, movement generation (zig-zagging).
    movedir : LibC::Int   # 0-7
    movecount : LibC::Int # when 0, select a new dir

    # Thing being chased/attacked (or 0),
    # also the originator for missiles.
    target : Mobj*

    # Reaction time: if non 0, don't attack yet.
    # Used by player to freeze a bit after teleporting.
    reactiontime : LibC::Int

    # If >0, the target will be chased
    # no matter what (even if shot)
    threshold : LibC::Int

    # Additional info record for player avatars only.
    # Only valid if type == MT_PLAYER
    player : Player*

    # Player number last looked for.
    lastlook : LibC::Int

    # For nightmare respawn.
    spawnpoint : Mapthing

    # Thing being chased/attacked for tracers.
    tracer : Mobj*
  end

  # __P_PSPR__

  #
  # Frame flags:
  # handles maximum brightness (torches, muzzle flare, light sources)
  #
  FF_FULLBRIGHT = 0x8000
  FF_FRAMEMASK  = 0x7fff

  #
  # Overlay psprites are scaled shapes
  # drawn directly on the view screen,
  # coordinates are given for a 320*200 view screen.
  #
  enum Psprnum
    Weapon
    Flash
    NUMPSPRITES
  end

  struct Pspdef
    state : State* # a 0 state means not active
    tics : LibC::Int
    sx : Fixed
    sy : Fixed
  end

  # __D_PLAYER__

  #
  # Player states.
  #
  enum Playerstate
    # Playing or camping.
    PST_LIVE
    # Dead on the ground, view follows killer.
    PST_DEAD
    # Ready to restart/respawn???
    PST_REBORN
  end

  #
  # Player internal flags, for cheats and debug.
  #
  @[Flags]
  enum Cheat
    # No clipping, walk through barriers.
    CF_NOCLIP
    # No damage, no health loss.
    CF_GODMODE
    # Not really a cheat, just a debug aid.
    CF_NOMOMENTUM
    # Me!
    CF_ME
  end

  #
  # Extended player object info: player_t
  #
  struct Player
    mo : Mobj*
    playerstate : Playerstate
    cmd : Ticcmd

    # Determine POV,
    #  including viewpoint bobbing during movement.
    # Focal origin above r.z
    viewz : Fixed
    # Base height above floor for viewz.
    viewheight : Fixed
    # Bob/squat speed.
    deltaviewheight : Fixed
    # bounded/scaled total momentum.
    bob : Fixed

    # This is only used between levels,
    # mo->health is used during levels.
    health : LibC::Int
    armorpoints : LibC::Int
    # Armor type is 0-2.
    armortype : LibC::Int

    # Power ups. invinc and invis are tic counters.
    powers : LibC::Int[Powertype::NUMPOWERS]
    cards : DoomBool[Card::NUMCARDS]
    backpack : DoomBool

    # Frags, kills of other players.
    frags : LibC::Int[MAXPLAYERS]
    readyweapon : Weapontype

    # Is wp_nochange if not changing.
    pendingweapon : Weapontype

    weaponowned : DoomBool[Weapontype::NUMWEAPONS]
    ammo : LibC::Int[Ammotype::NUMAMMO]
    maxammo : LibC::Int[Ammotype::NUMAMMO]

    # True if button down last tic.
    attackdown : LibC::Int
    usedown : LibC::Int

    # Bit flags, for cheats and debug.
    # See cheat_t, above.
    cheats : LibC::Int

    # Refired shots are less accurate.
    refire : LibC::Int

    # For intermission stats.
    killcount : LibC::Int
    itemcount : LibC::Int
    secretcount : LibC::Int

    # Hint messages.
    message : LibC::Char*

    # For screen flashing (red or bright).
    damagecount : LibC::Int
    bonuscount : LibC::Int

    # Who did damage (0 for floors/ceilings).
    attacker : Mobj*

    # So gun flashes light up areas.
    extralight : LibC::Int

    # Current PLAYPAL, ???
    #  can be set to REDCOLORMAP for pain, etc.
    fixedcolormap : LibC::Int

    # Player skin colorshift,
    #  0-3 for which color to draw player.
    colormap : LibC::Int

    # Overlay view sprites (gun, etc).
    psprites : Pspdef[Psprnum::NUMPSPRITES]

    # True if secret level has been done.
    didsecret : DoomBool
  end

  # __D_NET__

  #
  # Network play related stuff.
  # There is a data struct that stores network
  # communication related stuff, and another
  # one that defines the actual packets to
  # be transmitted.
  #

  DOOMCOM_ID = 0x12345678

  # Max computers/players in a game.
  MAXNETNODES = 8

  # Networking and tick handling related.
  BACKUPTICS = 24

  struct AltNetData
    gametic : Int32
    maketic : Int32
    section : UInt8[1024]
  end

  enum Command
    SEND = 1
    GET  = 2
  end

  #
  # Network packet data.
  #
  struct Doomdata
    # High bit is retransmit request.
    checksum : LibC::UInt
    # Only valid if NCMD_RETRANSMIT.
    retransmitfrom : Byte

    starttic : Byte
    player : Byte
    numtics : Byte
    cmds : Ticcmd[BACKUPTICS]
  end

  struct Doomcom
    # Supposed to be DOOMCOM_ID?
    id : LibC::LongLong

    # DOOM executes an int to execute commands.
    intnum : LibC::Short
    # Communication between DOOM and the driver.
    # Is CMD_SEND or CMD_GET.
    command : LibC::Short
    # Is dest for send, set by get (-1 = no packet).
    remotenode : LibC::Short

    # Number of bytes in doomdata to be sent
    datalength : LibC::Short

    # Info common to all nodes.
    # Console is allways node 0.
    numnodes : LibC::Short
    # Flag: 1 = no duplication, 2-5 = dup for slow nets.
    ticdup : LibC::Short
    # Flag: 1 = send a backup tic in every packet.
    extratics : LibC::Short
    # Flag: 1 = deathmatch.
    deathmatch : LibC::Short
    # Flag: -1 = new game, 0-5 = load savegame
    savegame : LibC::Short
    episode : LibC::Short # 1-3
    map : LibC::Short     # 1-9
    skill : LibC::Short   # 1-5

    # Info specific to this node.
    consoleplayer : LibC::Short
    numplayers : LibC::Short

    # These are related to the 3-display mode,
    #  in which two drones looking left and right
    #  were used to render two additional views
    #  on two additional computers.
    # Probably not operational anymore.
    # 1 = left, 0 = center, -1 = right
    angleoffset : LibC::Short
    # 1 = drone
    drone : LibC::Short

    # The packet data to be sent.
    data : Doomdata
  end

  # Create any new ticcmds and broadcast to other players.
  fun net_update = NetUpdate

  # Broadcasts special packets to other players
  #  to notify of game exit
  fun d_quit_net_game = D_QuitNetGame

  # ? how many ticks to run?
  fun try_run_tics = TryRunTics

  # __D_STATE__

  # ------------------------
  # Command line parameters.
  #
  # -----------------------------------------------------
  # Game Mode - identify IWAD as shareware, retail etc.
  #
  # Set if homebrew PWAD stuff has been added.
  # -------------------------------------------
  # Language.
  # -------------------------------------------
  # Selected skill type, map etc.
  #

  # Defaults for menu, methinks.
  # Selected by user.
  # Nightmare mode flag, single player.
  # Netgame? Only true if >1 player.
  # Flag: true only if started as net deathmatch.
  # An enum might handle altdeath/cooperative better.
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

  # -------------------------
  # Status flags for refresh.
  #

  # Depending on view size - no status bar?
  # Note that there is no way to disable the
  #  status bar explicitely.

  # This one is related to the 3-screen display mode.
  # Doocr::ANG90 = left side, ANG270 = right

  # Player taking events, and displaying.

  # -------------------------------------
  # Scores, rating.
  # Statistics on a given map, for intermission.
  #
  # Timer, for scores.
  # --------------------------------------
  # DEMO playback/recording related stuff.
  # No demo, there is a human player in charge?
  # Disable save/end game?
  # ?
  # Quit after playing a demo from cmdline.
  # ?
  # -----------------------------
  # Internal parameters, fixed.
  # These are set by the engine, and not changed
  # according to user inputs. Partly load from
  # WAD, partly set at startup time.

  # Bookkeeping on players - state.

  # Alive? Disconnected?

  # Player spawn spots for deathmatch.
  MAX_DM_STARTS = 10

  # Player spawn spots.

  # Intermission stats.
  # Parameters for world map / intermission.
  # LUT of ammunition limits for each kind.
  # This doubles with BackPack powerup item.

  # -----------------------------------------
  # Internal parameters, used for engine.
  #

  # File handling stuff.

  # if true, load all graphics at level load

  # wipegamestate can be set to -1
  # to force a wipe on the next draw

  # ?
  # debug flag to cancel adaptiveness


  # Needed to store the number of the dummy sky flat.
  # Used for rendering,
  #  as well as tracking projectiles etc.

  # Netgame stuff (buffers and pointers, i.e. indices).

  # This is ???
  # doomcom is owned by Doocr.

  # This points inside doomcom.




  # __I_SOUND__

  # Init at program start...
  fun i_init_sound = I_InitSound

  # ... update sound buffer and audio device at runtime...
  fun i_update_sound = I_UpdateSound
  fun i_submit_sound = I_SubmitSound

  # ... shut down and relase at program termination.
  fun i_shutdown_sound = I_ShutdownSound

  #
  #  SFX I/O
  #

  # Initialize channels?
  fun i_set_channels = I_SetChannels

  # Get raw data lump index for sound descriptor.
  fun i_get_sfx_lump_num = I_GetSfxLumpNum(sfx : Sfxinfo*) : LibC::Int

  # Starts a sound in a particular sound channel.
  fun i_start_sound = I_StartSound(id : LibC::Int, vol : LibC::Int, sep : LibC::Int, pitch : LibC::Int, priority : LibC::Int) : LibC::Int

  # Stops a sound channel.
  fun i_stop_sound = I_StopSound(handle : LibC::Int)

  # Called by S_*() functions
  #  to see if a channel is still playing.
  # Returns 0 if no longer playing, 1 if playing.
  fun i_sound_is_playing = I_SoundIsPlaying(handle : LibC::Int) : LibC::Int

  # Updates the volume, separation,
  #  and pitch of a sound channel.
  fun i_update_sound_params = I_UpdateSoundParams(handle : LibC::Int, vol : LibC::Int, sep : LibC::Int, pitch : LibC::Int)

  #
  #  MUSIC I/O
  #
  fun i_init_music = I_InitMusic
  fun i_shutdown_music = I_ShutdownMusic

  # Volume.
  fun i_set_music_volume = I_SetMusicVolume(volume : LibC::Int)

  # PAUSE game handling.
  fun i_pause_song = I_PauseSong(handle : LibC::Int)
  fun i_resume_song = I_ResumeSong(handle : LibC::Int)

  # Registers a song handle to song data.
  fun i_register_song = I_RegisterSong(data : Void*) : LibC::Int

  # Called by anything that wishes to start music.
  #  plays a song, and when the song is done,
  #  starts playing it again in an endless loop.
  # Horrible thing to do, considering.
  fun i_play_song = I_PlaySong(handle : LibC::Int, looping : LibC::Int)

  # Stops a song over 3 seconds.
  fun i_stop_song = I_StopSong(handle : LibC::Int)

  # See above (register), then think backwards
  fun i_unregister_song = I_UnRegisterSong(handle : LibC::Int)

  # Get next MIDI message
  fun i_tick_song = I_TickSong : LibC::ULongLong

  # __P_INTER__

  fun p_give_power = P_GivePower(player : Player*, power : LibC::Int) : DoomBool

  # __R_DEFS__

  # Silhouette, needed for clipping Segs (mainly)
  # and sprites representing things.
  SIL_NONE   = 0
  SIL_BOTTOM = 1
  SIL_TOP    = 2
  SIL_BOTH   = 3

  MAXDRAWSEGS = 256

  #
  # INTERNAL MAP TYPES
  # used by play and refresh
  #

  #
  # Your plain vanilla vertex.
  # Note: transformed values not buffered locally,
  # like some DOOM-alikes ("wt", "WebView") did.
  #
  struct Vertex
    x : Fixed
    y : Fixed
  end

  # Each sector has a degenmobj_t in its center
  # for sound origin purposes.
  # I suppose this does not handle sound from
  # moving objects (doppler), because
  # position is prolly just buffered, not
  # updated.
  struct Degenmobj
    thinker : Thinker # not used for anything
    x : Fixed
    y : Fixed
    z : Fixed
  end

  #
  # The SECTORS record, at runtime.
  # Stores things/mobjs.
  #
  struct Sector
    floorheight : Fixed
    ceilingheight : Fixed
    floorpic : LibC::Short
    ceilingpic : LibC::Short
    lightlevel : LibC::Short
    special : LibC::Short
    tag : LibC::Short

    # 0 = untraversed, 1,2 = sndlines - 1
    soundtraversed : LibC::Int

    # thing that made a sound (or null)
    soundtarget : Mobj*

    # mapblock bounding box for height changes
    blockbox : LibC::Int[4]

    # origin for any sounds played by the sector
    soundorg : Degenmobj

    # if == validcount, already checked
    validcount : LibC::Int

    # list of mobjs in sector
    thinglist : Mobj*

    # thinker_t for reversable actions
    specialdata : Void*

    linecount : LibC::Int
    lines : Line** # [linecount] size
  end

  #
  # The SideDef.
  #
  struct Side
    # add this to the calculated texture column
    textureoffset : Fixed

    # add this to the calculated texture top
    rowoffset : Fixed

    # Texture indices.
    # We do not maintain names here.
    toptexture : LibC::Short
    bottomtexture : LibC::Short
    midtexture : LibC::Short

    # Sector the SideDef is facing.
    sector : Sector*
  end

  #
  # Move clipping aid for LineDefs.
  #
  enum Slopetype
    HORIZONTAL
    VERTICAL
    POSITIVE
    NEGATIVE
  end

  struct Line
    # Vertices, from v1 to v2.
    v1 : Vertex*
    v2 : Vertex*

    # Precalculated v2 - v1 for side checking.
    dx : Fixed
    dy : Fixed

    # Animation related.
    flags : LibC::Short
    special : LibC::Short
    tag : LibC::Short

    # Visual appearance: SideDefs.
    # sidenum[1] will be -1 if one sided
    sidenum : LibC::Short[2]

    # Neat. Another bounding box, for the extent
    # of the LineDef.
    bbox : Fixed[4]

    # To aid move clipping.
    slopetype : Slopetype

    # Front and back sector.
    # Note: redundant? Can be retrieved from SideDefs.
    frontsector : Sector*
    backsector : Sector*

    # if == validcount, already checked
    validcount : LibC::Int

    # thinker_t for reversable actions
    specialdata : Void*
  end

  #
  # A SubSector.
  # References a Sector.
  # Basically, this is a list of LineSegs,
  # indicating the visible walls that define
  # (all or some) sides of a convex BSP leaf.
  #
  struct Subsector
    sector : Sector*
    numlines : LibC::Short
    firstline : LibC::Short
  end

  #
  # The LineSeg.
  #
  struct Seg
    v1 : Vertex*
    v2 : Vertex*

    offset : Fixed

    angle : Angle

    sidedef : Side*
    linedef : Line*

    # Sector references.
    # Could be retrieved from linedef, too.
    # backsector is 0 for one sided lines
    frontsector : Sector*
    backsector : Sector*
  end

  #
  # BSP node.
  #
  struct Node
    # Partition line.
    x : Fixed
    y : Fixed
    dx : Fixed
    dy : Fixed

    # Bounding box for each child.
    bbox : Fixed[4][2]

    # If NF_SUBSECTOR its a subsector.
    children : LibC::UShort[2]
  end

  # posts are runs of non masked source pixels
  struct Post
    topdelta : Byte # -1 is the last post in a column
    length : Byte   # length data bytes follows
  end

  # column_t is a list of 0 or more post_t, (byte)-1 terminated
  alias Column = Post

  #
  # OTHER TYPES
  #

  # This could be wider for >8 bit display.
  # Indeed, true color support is posibble
  #  precalculating 24bpp lightmap/colormap LUT.
  #  from darkening PLAYPAL to all black.
  # Could even us emore than 32 levels.
  alias Lighttable = Byte

  #
  # ?
  #
  struct Drawseg
    curline : Seg*
    x1 : LibC::Int
    x2 : LibC::Int

    scale1 : Fixed
    scale2 : Fixed
    scalestep : Fixed

    # 0=none, 1=bottom, 2=top, 3=both
    silhouette : LibC::Int

    # do not clip sprites above this
    bsilheight : Fixed

    # do not clip sprites below this
    tsilheight : Fixed

    # Pointers to lists for sprite clipping,
    #  all three adjusted so [x1] is first value.
    sprtopclip : LibC::Short*
    sprbottomclip : LibC::Short*
    maskedtexturecol : LibC::Short*
  end

  # Patches.
  # A patch holds one or more columns.
  # Patches are used for sprites and all masked pictures,
  # and we compose textures from the TEXTURE1/2 lists
  # of patches.
  struct Patch
    width : LibC::Short # bounding box size
    height : LibC::Short
    leftoffset : LibC::Short # pixels to the left of origin
    topoffset : LibC::Short  # pixels below the origin
    columnofs : LibC::Int[8] # only [width] used
    # the [0] is &columnofs[width]
  end

  # A vissprite_t is a thing
  #  that will be drawn during a refresh.
  # I.e. a sprite object that is partly visible.
  struct Vissprite
    # Doubly linked list.
    prev : Vissprite*
    next : Vissprite*

    x1 : LibC::Int
    x2 : LibC::Int

    # for line side calculation
    gx : Fixed
    gy : Fixed

    # global bottom / top for silhouette clipping
    gz : Fixed
    gzt : Fixed

    # horizontal position of x1
    startfrac : Fixed

    scale : Fixed

    # negative if flipped
    xiscale : Fixed

    texturemid : Fixed
    patch : LibC::Int

    # for color translation and shadow draw,
    #  maxbright frames as well
    colormap : Lighttable*

    mobjflags : LibC::Int
  end

  #
  # Sprites are patches with a special naming convention
  #  so they can be recognized by R_InitSprites.
  # The base name is NNNNFx or NNNNFxFx, with
  #  x indicating the rotation, x = 0, 1-7.
  # The sprite and frame specified by a thing_t
  #  is range checked at run time.
  # A sprite is a patch_t that is assumed to represent
  #  a three dimensional object and may have multiple
  #  rotations pre drawn.
  # Horizontal flipping is used to save space,
  #  thus NNNNF2F5 defines a mirrored patch.
  # Some sprites will only have one picture used
  # for all views: NNNNF0
  #
  struct Spriteframe
    # If false use 0 for any position.
    # Note: as eight entries are available,
    #  we might as well insert the same name eight times.
    rotate : DoomBool

    # Lump to use for view angles 0-7.
    lump : LibC::Short[8]

    # Flip bit (1 = flip) to use for view angles 0-7.
    flip : Byte[8]
  end

  #
  # A sprite definition:
  #  a number of animation frames.
  #
  struct Spritedef
    numframes : LibC::Int
    spriteframes : Spriteframe*
  end

  #
  # Now what is a visplane, anyway?
  #
  struct Visplane
    height : Fixed
    picnum : LibC::Int
    lightlevel : LibC::Int
    minx : LibC::Int
    maxx : LibC::Int

    # leave pads for [minx-1]/[maxx+1]

    pad1 : Byte
    # Here lies the rub for all
    #  dynamic resize/change of resolution.
    top : Byte[SCREENWIDTH]
    pad2 : Byte
    pad3 : Byte
    # See above.
    bottom : Byte[SCREENWIDTH]
    pad4 : Byte
  end

  # __HULIB__

  # background and foreground screen numbers
  # different from other modules.
  BG = 1
  FG = 0

  # font stuff
  HU_CHARERASE = KEY_BACKSPACE

  HU_MAXLINES      =  4
  HU_MAXLINELENGTH = 80

  #
  # Typedefs of widgets
  #

  # Text Line widget
  #  (parent of Scrolling Text and Input Text widgets)
  LINEOFTEXT_SIZE = HU_MAXLINELENGTH + 1

  struct HU_Textline
    # left-justified position of scrolling text window
    x : LibC::Int
    y : LibC::Int

    f : Patch**                     # font
    sc : LibC::Int                  # start character
    l : LibC::Char[LINEOFTEXT_SIZE] # line of text
    len : LibC::Int                 # current line length

    # whether this line needs to be udpated
    needsupdate : LibC::Int
  end

  # Scrolling Text window widget
  #  (child of Text Line widget)
  struct HU_Stext
    l : HU_Textline[HU_MAXLINES] # text lines to draw
    h : LibC::Int                # height in lines
    cl : LibC::Int               # current line number

    # pointer to doom_boolean stating whether to update window
    on : DoomBool*
    laston : DoomBool # last value of *->on.
  end

  # Input Text Line widget
  #  (child of Text Line widget)
  struct HU_Itext
    l : HU_Textline # text line to input on

    # left margin past which I am not to delete characters
    lm : LibC::Int

    # pointer to doom_boolean stating whether to update window
    on : DoomBool*
    laston : DoomBool # last value of *->on
  end

  #
  # Widget creation, access, and update routines
  #

  # initializes heads-up widget library
  fun hulib_init = HUlib_init

  #
  # textline code
  #

  # clear a line of text
  fun hulib_clear_text_line = HUlib_clearTextLine(t : HU_Textline*)

  fun hulib_init_text_line = HUlib_initTextLine(t : HU_Textline*, x : LibC::Int, y : LibC::Int, f : Patch**, sc : LibC::Int)

  # returns success
  fun hulib_add_char_to_text_line = HUlib_addCharToTextLine(t : HU_Textline*, ch : LibC::Char) : DoomBool

  # returns success
  fun hulib_del_char_from_text_line = HUlib_delCharFromTextLine(t : HU_Textline*) : DoomBool

  # draws tline
  fun hulib_draw_text_line = HUlib_drawTextLine(l : HU_Textline*, drawcursor : DoomBool)

  # erases text line
  fun hulib_erase_text_line = HUlib_eraseTextLine(l : HU_Textline*)

  #
  # Scrolling Text window widget routines
  #

  # ?
  fun hulib_init_s_text = HUlib_initSText(s : HU_Stext*,
                                          x : LibC::Int,
                                          y : LibC::Int,
                                          h : LibC::Int,
                                          font : Patch**,
                                          startchar : LibC::Int,
                                          on : DoomBool*)

  # add a new line
  fun hulib_add_line_to_s_text = HUlib_addLineToSText(s : HU_Stext*)

  # ?
  fun hulib_add_message_to_s_text = HUlib_addMessageToSText(s : HU_Stext*, prefix : LibC::Char*, msg : LibC::Char*)

  # draws stext
  fun hulib_draw_s_text = HUlib_drawSText(s : HU_Stext*)

  # erases all stext lines
  fun hulib_erase_s_text = HUlib_eraseSText(s : HU_Stext*)

  # Input Text Line widget routines
  fun hulib_init_i_text = HUlib_initIText(it : HU_Itext*,
                                          x : LibC::Int,
                                          y : LibC::Int,
                                          font : Patch**,
                                          startchar : LibC::Int,
                                          on : DoomBool*)

  # enforces left margin
  fun hulib_del_char_from_i_text = HUlib_delCharFromIText(it : HU_Itext*)

  # enforces left margin
  fun hulib_erase_line_from_i_text = HUlib_eraseLineFromIText(it : HU_Itext*)

  # resets line and left margin
  fun hulib_reset_i_text = HUlib_resetIText(it : HU_Itext*)

  # left of left-margin
  fun hulib_add_prefix_to_i_text = HUlib_addPrefixToIText(it : HU_Itext*, str : LibC::Char*)

  # whether eaten
  fun hulib_key_in_i_text = HUlib_keyInIText(it : HU_Itext*, ch : LibC::UChar) : DoomBool

  fun hulib_draw_i_text = HUlib_drawIText(it : HU_Itext*)

  # erases all itext lines
  fun hulib_erase_i_text = HUlib_eraseIText(it : HU_Itext*)

  # __P_SPEC__

  #
  # End-level timer (-TIMER option)
  #

  # Define values for map objects
  MO_TELEPORTMAN = 14

  # at game start
  fun p_init_pic_anims = P_InitPicAnims

  # at map load
  fun p_spawn_specials = P_SpawnSpecials

  # every tic
  fun p_update_specials = P_UpdateSpecials

  # when needed
  fun p_use_special_line = P_UseSpecialLine(thing : Mobj*, line : Line*, side : LibC::Int) : DoomBool

  fun p_shoot_special_line = P_ShootSpecialLine(thing : Mobj*, line : Line*)
  fun p_cross_special_line = P_CrossSpecialLine(linenum : LibC::Int, side : LibC::Int, thing : Mobj*)
  fun p_player_in_special_sector = P_PlayerInSpecialSector(player : Player*)
  fun two_sided = twoSided(sector : LibC::Int, line : LibC::Int) : LibC::Int
  fun get_sector = getSector(current_sector : LibC::Int, line : LibC::Int, side : LibC::Int) : Sector*
  fun get_side = getSide(current_sector : LibC::Int, line : LibC::Int, side : LibC::Int) : Side*
  fun p_find_lowest_floor_surrounding = P_FindLowestFloorSurrounding(sec : Sector*) : Fixed
  fun p_find_highest_floor_surrounding = P_FindHighestFloorSurrounding(sec : Sector*) : Fixed
  fun p_find_next_highest_floor = P_FindNextHighestFloor(sec : Sector*, currentheight : LibC::Int) : Fixed
  fun p_find_lowest_ceiling_surrounding = P_FindLowestCeilingSurrounding(sec : Sector*) : Fixed
  fun p_find_highest_ceiling_surrounding = P_FindHighestCeilingSurrounding(sec : Sector*) : Fixed
  fun p_find_sector_from_line_tag = P_FindSectorFromLineTag(line : Line*, start : LibC::Int) : LibC::Int
  fun p_find_min_surrounding_light = P_FindMinSurroundingLight(sector : Sector*, max : LibC::Int) : LibC::Int
  fun get_next_sector = getNextSector(line : Line*, sec : Sector*) : Sector*

  #
  # SPECIAL
  #
  fun ev_do_donut = EV_DoDonut(line : Line*) : LibC::Int

  #
  # P_LIGHTS
  #
  struct Fireflicker
    thinker : Thinker
    sector : Sector*
    count : LibC::Int
    maxlight : LibC::Int
    minlight : LibC::Int
  end

  struct Lightflash
    thinker : Thinker
    sector : Sector*
    count : LibC::Int
    maxlight : LibC::Int
    minlight : LibC::Int
    maxtime : LibC::Int
    mintime : LibC::Int
  end

  struct Strobe
    thinker : Thinker
    sector : Sector*
    count : LibC::Int
    minlight : LibC::Int
    maxlight : LibC::Int
    darktime : LibC::Int
    brighttime : LibC::Int
  end

  struct Glow
    thinker : Thinker
    sector : Sector*
    minlight : LibC::Int
    maxlight : LibC::Int
    direction : LibC::Int
  end

  GLOWSPEED    =  8
  STROBEBRIGHT =  5
  FASTDARK     = 15
  SLOWDARK     = 35

  fun p_spawn_fire_flicker = P_SpawnFireFlicker(sector : Sector*)
  fun t_light_flash = T_LightFlash(flash : Lightflash*)
  fun p_spawn_light_flash = P_SpawnLightFlash(sector : Sector*)
  fun t_strobe_flash = T_StrobeFlash(flash : Strobe*)

  fun p_spawn_strobe_flash = P_SpawnStrobeFlash(sector : Sector*, fast_or_slow : LibC::Int, in_sync : LibC::Int)
  fun ev_start_light_strobing = EV_StartLightStrobing(line : Line*)
  fun ev_turn_tag_lights_off = EV_TurnTagLightsOff(line : Line*)

  fun ev_light_turn_on = EV_LightTurnOn(line : Line*, bright : LibC::Int)

  fun t_glow = T_Glow(g : Glow*)
  fun p_spawn_glowing_light = P_SpawnGlowingLight(sector : Sector*)

  #
  # P_SWITCH
  #
  enum Bwhere
    Top
    Middle
    Bottom
  end

  # max # of wall switches in a level
  MAXSWITCHES = 50

  # 4 players, 4 buttons each at once, max.
  MAXBUTTONS = 16

  # 1 second, in ticks.
  BUTTONTIME = 35

  fun p_change_switch_texture = P_ChangeSwitchTexture(line : Line*, use_again : LibC::Int)
  fun p_init_switch_list = P_InitSwitchList

  #
  # P_PLATS
  #
  enum Platenum
    Up
    Down
    Waiting
    InStasis
  end

  enum Plattype
    PerpetualRaise
    DownWaitUpStay
    RaiseAndChange
    RaiseToNearestAndChange
    BlazeDWUS
  end

  struct Plat
    thinker : Thinker
    sector : Sector*
    speed : Fixed
    low : Fixed
    high : Fixed
    wait : LibC::Int
    count : LibC::Int
    status : Platenum
    oldstatus : Platenum
    crush : DoomBool
    tag : LibC::Int
    type : Plattype
  end

  PLATWAIT  = 3
  PLATSPEED = Doocr::FRACUNIT
  MAXPLATS  = 30


  fun t_plat_raise = T_PlatRaise(plat : Plat*)
  fun ev_do_plat = EV_DoPlat(line : Line*, type : Plattype, amount : LibC::Int) : LibC::Int
  fun p_add_active_plat = P_AddActivePlat(plat : Plat*)
  fun p_remove_active_plat = P_RemoveActivePlat(plat : Plat*)
  fun ev_stop_plat = EV_StopPlat(line : Line*)
  fun p_activate_in_stasis = P_ActivateInStasis(tag : LibC::Int)

  #
  # P_DOORS
  #
  enum Vldoorenum
    DoorNormal
    Close30ThenOpen
    DoorClose
    DoorOpen
    RaiseIn5Mins
    BlazeRaise
    BlazeOpen
    BlazeClose
  end

  struct Vldoor
    thinker : Thinker
    type : Vldoorenum
    sector : Sector*
    topheight : Fixed
    speed : Fixed

    # 1 = up, 0 = waiting at top, -1 = down
    direction : LibC::Int

    # tics to wait at the top
    topwait : LibC::Int

    # (keep in case a door going down is reset)
    # when it reaches 0, start going down
    topcountdown : LibC::Int
  end

  VDOORSPEED = Doocr::FRACUNIT*2
  VDOORWAIT  = 150

  fun ev_vertical_door = EV_VerticalDoor(line : Line*, thing : Mobj*)
  fun ev_do_door = EV_DoDoor(line : Line*, type : Vldoorenum) : LibC::Int
  fun ev_do_locked_door = EV_DoLockedDoor(line : Line*, type : Vldoorenum, thing : Mobj*) : LibC::Int
  fun t_vertical_door = T_VerticalDoor(door : Vldoor*)
  fun p_spawn_door_close_in_30 = P_SpawnDoorCloseIn30(sec : Sector*)
  fun p_spawn_door_raise_in_5_mins = P_SpawnDoorRaiseIn5Mins(sec : Sector*, secnum : LibC::Int)

  #
  # P_CEILNG
  #
  enum Ceilingenum
    LowerToFloor
    RaiseToHighest
    LowerAndCrush
    CrushAndRaise
    FastCrushAndRaise
    SilentCrushAndRaise
  end

  struct Ceiling
    thinker : Thinker
    type : Ceilingenum
    sector : Sector*
    bottomheight : Fixed
    topheight : Fixed
    speed : Fixed
    crush : DoomBool

    # 1 = up, 0 = waiting, -1 = down
    direction : LibC::Int

    # ID
    tag : LibC::Int
    olddirection : LibC::Int
  end

  CEILSPEED   = Doocr::FRACUNIT
  CEILWAIT    = 150
  MAXCEILINGS =  30


  fun ev_do_ceiling = EV_DoCeiling(line : Line*, type : Ceilingenum) : LibC::Int
  fun t_move_ceiling = T_MoveCeiling(ceiling : Ceiling*)
  fun p_add_active_ceiling = P_AddActiveCeiling(c : Ceiling*)
  fun p_remove_active_ceiling = P_RemoveActiveCeiling(c : Ceiling*)
  fun ev_ceiling_crush_stop = EV_CeilingCrushStop(line : Line*) : LibC::Int
  fun p_activate_in_stasis_ceiling = P_ActivateInStasisCeiling(line : Line*)

  #
  # P_FLOOR
  #
  enum Floorenum
    # lower floor to highest surrounding floor
    LowerFloor

    # lower floor to lowest surrounding floor
    LowerFloorToLowest

    # lower floor to highest surrounding floor VERY FAST
    TurboLower

    # raise floor to lowest surrounding CEILING
    RaiseFloor

    # raise floor to next highest surrounding floor
    RaiseFloorToNearest

    # raise floor to shortest height texture around it
    RaiseToTexture

    # lower floor to lowest surrounding floor
    #  and change floorpic
    LowerAndChange

    RaiseFloor24
    RaiseFloor24AndChange
    RaiseFloorCrush

    # raise to next highest floor, turbo-speed
    RaiseFloorTurbo
    DonutRaise
    RaiseFloor512
  end

  enum Stairenum
    Build8  # slowly build by 8
    Turbo16 # quickly build by 16
  end

  struct Floormove
    thinker : Thinker
    type : Floorenum
    crush : DoomBool
    sector : Sector*
    direction : LibC::Int
    newspecial : LibC::Int
    texture : LibC::Short
    floordestheight : Fixed
    speed : Fixed
  end

  FLOORSPEED = Doocr::FRACUNIT

  enum Result
    Ok
    Crushed
    Pastdest
  end

  fun t_move_plane = T_MovePlane(sector : Sector*, speed : Fixed, dest : Fixed, crush : DoomBool, floor_or_ceiling : LibC::Int, direction : LibC::Int) : Result
  fun ev_build_stairs = EV_BuildStairs(line : Line*, type : Stairenum) : LibC::Int
  fun ev_do_floor = EV_DoFloor(line : Line*, floortype : Floorenum) : LibC::Int
  fun t_move_floor = T_MoveFloor(floor : Floormove*)

  #
  # P_TELEPT
  #
  fun ev_teleport = EV_Teleport(line : Line*, side : LibC::Int, thing : Mobj*) : LibC::Int

  # __R_BSP__



  # false if the back side is the same plane





  alias Drawfunc = Proc(LibC::Int, LibC::Int, Nil)

  # BSP?
  fun r_clear_clip_segs = R_ClearClipSegs
  fun r_clear_draw_segs = R_ClearDrawSegs
  fun r_render_bsp_node = R_RenderBSPNode(bspnum : LibC::Int)

  # __R_DRAW__


  # first pixel in a column

  # The span blitting interface.
  # Hook in assembler or system specific BLT
  #  here.
  fun r_draw_column = R_DrawColumn

  # The Spectre/Invisibility effect.
  fun r_draw_fuzz_column = R_DrawFuzzColumn

  # Draw with color translation tables,
  #  for player sprite rendering,
  #  Green/Red/Blue/Indigo shirts.
  fun r_draw_translated_column = R_DrawTranslatedColumn

  fun r_video_erase = R_VideoErase(ofs : LibC::UInt, count : LibC::Int)




  # start of a 64*64 tile image


  # Span blitting for rows, floor/ceiling.
  # No Sepctre effect needed.
  fun r_draw_span = R_DrawSpan

  # Low resolution mode, 160x200?
  fun r_draw_span_low = R_DrawSpanLow

  fun r_init_buffer = R_InitBuffer(width : LibC::Int, height : LibC::Int)

  # Initialize color translation tables,
  #  for player rendering etc.
  fun r_init_translation_tables = R_InitTranslationTables

  # Rendering function.
  fun r_fill_back_screen = R_FillBackScreen

  # If the view size is not full screen, draws a border around it.
  fun r_draw_view_border = R_DrawViewBorder

  # __R_SEGS__

  fun r_render_masked_seg_range = R_RenderMaskedSegRange(ds : Drawseg*, x1 : LibC::Int, x2 : LibC::Int)

  # __R_STATE__

  # needed for texture pegging

  # needed for pre rendering (fracs)





  # for global animation

  # Sprite....

  #
  # Lookup tables for map data.
  #

  #
  # POV data.
  #


  # ?

  VIEWANGLETOX_SIZE = FINEANGLES//2
  XTOVIEWANGLE_SIZE = SCREENWIDTH + 1


  # angle to line origin

  # Segs count?

  # __R_DATA__

  # Retrieve column data for span blitting.
  fun r_get_column = R_GetColumn(tex : LibC::Int, col : LibC::Int) : Byte*

  # I/O, setting up the stuff.
  fun r_init_data = R_InitData
  fun r_precache_level = R_PrecacheLevel

  # Retrieval.
  # Floor/ceiling opaque texture tiles,
  # lookup by name. For animation?
  fun r_flat_num_for_name = R_FlatNumForName(name : LibC::Char*) : LibC::Int

  # Called by P_Ticker for switches and animations,
  # returns the texture number for the texture name.
  fun r_texture_num_for_name = R_TextureNumForName(name : LibC::Char*) : LibC::Int
  fun r_check_texture_num_for_name = R_CheckTextureNumForName(name : LibC::Char*) : LibC::Int

  # __R_MAIN__

  #
  # POV related.
  #






  #
  # Lighting LUT.
  # Used for z-depth cuing per column/row,
  # and other lighting effects (sector ambient, flash).
  #

  # Lighting constants.
  # Now why not 32 levels here?
  LIGHTLEVELS   = 16
  LIGHTSEGSHIFT =  4

  MAXLIGHTSCALE   =  48
  LIGHTSCALESHIFT =  12
  MAXLIGHTZ       = 128
  LIGHTZSHIFT     =  20



  # Number of diminishing brightness levels.
  # There a 0-31, i.e. 32 LUT in the COLORMAP lump.
  NUMCOLORMAPS = 32

  # Blocky/low detail mode.
  # B remove this?
  #  0 = high, 1 = low

  #
  # Function pointers to switch refresh/drawing functions.
  # Used to select shadow mode etc.
  #
  alias Colfunc = Proc(Nil)
  alias Basecolfunc = Proc(Nil)
  alias Fuzzcolfunc = Proc(Nil)
  # No shadow effects on floors.
  alias Spanfunc = Proc(Nil)

  #
  # Utility functions.
  fun r_point_on_side = R_PointOnSide(x : Fixed, y : Fixed, node : Node*) : LibC::Int
  fun r_point_on_seg_side = R_PointOnSegSide(x : Fixed, y : Fixed, line : Seg*) : LibC::Int
  fun r_point_to_angle = R_PointToAngle(x : Fixed, y : Fixed) : Angle
  fun r_point_to_angle2 = R_PointToAngle2(x1 : Fixed, y1 : Fixed, x2 : Fixed, y2 : Fixed) : Angle
  fun r_point_to_dist = R_PointToDist(x : Fixed, y : Fixed) : Fixed
  fun r_scale_from_global_angle = R_ScaleFromGlobalAngle(visangle : Angle) : Fixed
  fun r_point_in_subsector = R_PointInSubsector(x : Fixed, y : Fixed) : Subsector*
  fun r_add_point_to_box = R_AddPointToBox(x : LibC::Int, y : LibC::Int, box : Fixed*)

  #
  # REFRESH - the actual rendering functions.
  #

  # Called by G_Drawer.
  fun r_render_player_view = R_RenderPlayerView(player : Player*)

  # Called by startup code.
  fun r_init = R_Init

  # Called by M_Responder.
  fun r_set_view_size = R_SetViewSize(blocks : LibC::Int, detail : LibC::Int)

  # __R_PLANE__

  # Visplane related.



  fun r_init_planes = R_InitPlanes
  fun r_clear_planes = R_ClearPlanes
  fun r_map_plane = R_MapPlane(y : LibC::Int, x1 : LibC::Int, x2 : LibC::Int)
  fun r_make_spans = R_MakeSpans(x : LibC::Int, t1 : LibC::Int, b1 : LibC::Int, t2 : LibC::Int, b2 : LibC::Int)
  fun r_draw_planes = R_DrawPlanes

  # __R_THINGS__

  MAXVISSPRITES = 128


  # Constant arrays used for psprite clipping
  # and initializing clipping.

  # vars for R_DrawMaskedColumn


  fun r_draw_masked_column = R_DrawMaskedColumn(column : Column*)
  fun r_sort_vis_sprites = R_SortVisSprites
  fun r_add_sprites = R_AddSprites(sec : Sector*)
  fun r_clear_sprites = R_ClearSprites
  fun r_draw_masked = R_DrawMasked

  # __R_LOCAL__

  FLOATSPEED = (Doocr::FRACUNIT*4)

  MAXHEALTH  = 100
  VIEWHEIGHT = (41*Doocr::FRACUNIT)

  # mapblocks are used to check movement
  # against lines and things
  MAPBLOCKUNITS = 128
  MAPBLOCKSIZE  = (MAPBLOCKUNITS*Doocr::FRACUNIT)
  MAPBLOCKSHIFT = (Doocr::FRACBITS + 7)
  MAPBMASK      = (MAPBLOCKSIZE - 1)
  MAPBTOFRAC    = (MAPBLOCKSHIFT - Doocr::FRACBITS)

  # player radius for movement checking
  PLAYERRADIUS = 16*Doocr::FRACUNIT

  # MAXRADIUS is for precalculated sector block boxes
  # the spider demon is larger,
  # but we do not have any moving sectors nearby
  MAXRADIUS = 32*Doocr::FRACUNIT

  GRAVITY = Doocr::FRACUNIT
  MAXMOVE = (30*Doocr::FRACUNIT)

  USERANGE     = (64*Doocr::FRACUNIT)
  MELEERANGE   = (64*Doocr::FRACUNIT)
  MISSILERANGE = (32*64*Doocr::FRACUNIT)

  # follow a player exlusively for 3 seconds
  BASETHRESHOLD = 100

  #
  # P_TICK
  #

  # both the head and tail of the thinker list

  fun p_init_thinkers = P_InitThinkers
  fun p_add_thinker = P_AddThinker(thinker : Thinker*)
  fun p_remove_thinker = P_RemoveThinker(thinker : Thinker*)

  #
  # P_PSPR
  #
  fun p_setup_psprites = P_SetupPsprites(curplayer : Player*)
  fun p_move_psprites = P_MovePsprites(curplayer : Player*)
  fun p_drop_weapon = P_DropWeapon(player : Player*)

  #
  # P_USER
  #
  fun p_player_think = P_PlayerThink(player : Player*)

  #
  # P_MOBJ
  #
  ONFLOORZ   = LibC::Int::MIN
  ONCEILINGZ = LibC::Int::MAX

  # Time interval for item respawning.
  ITEMQUESIZE = 128


  fun p_respawn_specials = P_RespawnSpecials
  fun p_spawn_mobj = P_SpawnMobj(x : Fixed, y : Fixed, z : Fixed, type : Mobjtype) : Mobj*
  fun p_remove_mobj = P_RemoveMobj(mobj : Mobj*)
  fun p_set_mobj_state = P_SetMobjState(mobj : Mobj*, state : Statenum) : DoomBool
  fun p_mobj_thinker = P_MobjThinker(mobj : Mobj*)
  fun p_spawn_puff = P_SpawnPuff(x : Fixed, y : Fixed, z : Fixed)
  fun p_spawn_blood = P_SpawnBlood(x : Fixed, y : Fixed, z : Fixed, damage : LibC::Int)
  fun p_spawn_missile = P_SpawnMissile(source : Mobj*, dest : Mobj*, type : Mobjtype) : Mobj*
  fun p_spawn_player_missile = P_SpawnPlayerMissile(source : Mobj*, type : Mobjtype)

  #
  # P_ENEMY
  #
  fun p_noise_alert = P_NoiseAlert(target : Mobj*, emmiter : Mobj*)

  #
  # P_MAPUTL
  #
  struct Divline
    x : Fixed
    y : Fixed
    dx : Fixed
    dy : Fixed
  end

  union InterceptD
    thing : Mobj*
    line : Line*
  end

  struct Intercept
    frac : Fixed # along trace line
    isaline : DoomBool
    d : InterceptD
  end

  MAXINTERCEPTS = 128

  alias Traverser = Proc(Intercept*, DoomBool)

  fun p_aprox_distance = P_AproxDistance(dx : Fixed, dy : Fixed) : Fixed
  fun p_point_on_line_side = P_PointOnLineSide(x : Fixed, y : Fixed, line : Line*) : LibC::Int
  fun p_point_on_divline_side = P_PointOnDivlineSide(x : Fixed, y : Fixed, line : Divline*) : LibC::Int
  fun p_make_divline = P_MakeDivline(li : Line*, dl : Divline*)
  fun p_intercept_vector = P_InterceptVector(v2 : Divline*, v1 : Divline*) : Fixed
  fun p_box_on_line_side = P_BoxOnLineSide(tmbox : Fixed*, ld : Line*) : LibC::Int


  fun p_line_opening = P_LineOpening(linedef : Line*)

  fun p_block_lines_iterator = P_BlockLinesIterator(x : LibC::Int, y : LibC::Int, func : Proc(Line*, DoomBool)) : DoomBool
  fun p_block_things_iterator = P_BlockThingsIterator(x : LibC::Int, y : LibC::Int, func : Proc(Mobj*, DoomBool)) : DoomBool

  PT_ADDLINES  = 1
  PT_ADDTHINGS = 2
  PT_EARLYOUT  = 4


  fun p_path_traverse = P_PathTraverse(x1 : Fixed, y1 : Fixed, x2 : Fixed, y2 : Fixed, flags : LibC::Int, trav : Proc(Intercept*, DoomBool)) : DoomBool
  fun p_unset_thing_position = P_UnsetThingPosition(thing : Mobj*)
  fun p_set_thing_position = P_SetThingPosition(thing : Mobj*)

  #
  # P_MAP
  #

  # If "floatok" true, move would be ok
  # if within "tmfloorz - tmceilingz".

  # keep track of the line that lowers the ceiling,
  # so missiles don't explode against sky hack walls

  fun p_check_position = P_CheckPosition(thing : Mobj*, x : Fixed, y : Fixed) : DoomBool
  fun p_try_move = P_TryMove(thing : Mobj*, x : Fixed, y : Fixed) : DoomBool
  fun p_teleport_move = P_TeleportMove(thing : Mobj*, x : Fixed, y : Fixed) : DoomBool
  fun p_slide_move = P_SlideMove(mo : Mobj*)
  fun p_check_sight = P_CheckSight(t1 : Mobj*, t2 : Mobj*) : DoomBool
  fun p_use_lines = P_UseLines(player : Player*)
  fun p_change_sector = P_ChangeSector(sector : Sector*, crunch : DoomBool) : DoomBool


  fun p_aim_line_attack = P_AimLineAttack(t1 : Mobj*, angle : Angle, distance : Fixed) : Fixed
  fun p_line_attack = P_LineAttack(t1 : Mobj*, angle : Angle, distance : Fixed, slope : Fixed, damage : LibC::Int)
  fun p_radius_attack = P_RadiusAttack(spot : Mobj*, source : Mobj*, damage : LibC::Int)

  #
  # P_SETUP
  #

  #
  # P_INTER
  #

  fun p_touch_special_thing = P_TouchSpecialThing(special : Mobj*, toucher : Mobj*)
  fun p_damage_mobj = P_DamageMobj(target : Mobj*, inflictor : Mobj*, source : Mobj*, damage : LibC::Int)

  # __STLIB__

  #
  # Background and foreground screen numbers
  #
  STLIB_BG = 4
  STLIB_FG = 0

  #
  # Typedefs of widgets
  #

  # Number widget
  struct ST_Number
    # upper right-hand corner
    #  of the number (right-justified)
    x : LibC::Int
    y : LibC::Int

    # max # of digits in number
    width : LibC::Int

    # last number value
    oldnum : LibC::Int

    # pointer to current value
    num : LibC::Int*

    # pointer to doom_boolean stating
    #  whether to update number
    on : DoomBool*

    # list of patches for 0-9
    p : Patch**

    # user data
    data : LibC::Int
  end

  # Percent widget ("child" of number widget,
  #  or, more precisely, contains a number widget.)
  struct ST_Percent
    # number information
    n : ST_Number

    # percent sign graphic
    p : Patch*
  end

  # Multiple Icon widget
  struct ST_Multicon
    # center-justified location of icons
    x : LibC::Int
    y : LibC::Int

    # last icon number
    oldinum : LibC::Int

    # pointer to current icon
    inum : LibC::Int*

    # pointer to doom_boolean stating
    #  whether to update icon
    on : DoomBool*

    # list of icons
    p : Patch**

    # user data
    data : LibC::Int
  end

  # Binary Icon widget
  struct ST_Binicon
    # center-justified location of icons
    x : LibC::Int
    y : LibC::Int

    # last icon value
    oldval : LibC::Int

    # pointer to current icon status
    val : DoomBool*

    # pointer to bool
    #  stating whether to update icon
    on : DoomBool*

    p : Patch*       # icon
    data : LibC::Int # user data
  end

  #
  # Widget creation, access, and update routines
  #

  # Initializes widget library.
  # More precisely, initialize STMINUS,
  # everything else is done somewhere else.
  #
  fun stlib_init = STlib_init

  # Number widget routines
  fun stlib_init_num = STlib_initNum(n : ST_Number*,
                                     x : LibC::Int,
                                     y : LibC::Int,
                                     pl : Patch**,
                                     num : LibC::Int*,
                                     on : DoomBool*,
                                     width : LibC::Int)

  fun stlib_update_num = STlib_updateNum(n : ST_Number*, refresh : DoomBool)

  # Percent widget routines
  fun stlib_init_percent = STlib_initPercent(p : ST_Percent*,
                                             x : LibC::Int,
                                             y : LibC::Int,
                                             pl : Patch**,
                                             num : LibC::Int*,
                                             on : DoomBool*,
                                             percent : Patch*)

  fun stlib_update_percent = STlib_updatePercent(per : ST_Percent*, refresh : LibC::Int)

  # Multiple Icon widget routines
  fun stlib_init_mult_icon = STlib_initMultIcon(mi : ST_Multicon*,
                                                x : LibC::Int,
                                                y : LibC::Int,
                                                il : Patch**,
                                                inum : LibC::Int*,
                                                on : DoomBool*)

  fun stlib_update_mult_icon = STlib_updateMultIcon(mi : ST_Multicon*, refresh : DoomBool)

  # Binary Icon widget routines
  fun stlib_init_bin_icon = STlib_initBinIcon(b : ST_Binicon*,
                                              x : LibC::Int,
                                              y : LibC::Int,
                                              i : Patch*,
                                              val : DoomBool*,
                                              on : DoomBool*)

  fun stlib_update_bin_icon = STlib_updateBinIcon(bi : ST_Binicon*, refresh : DoomBool)

  # __V_VIDEO__

  #
  # VIDEO
  #

  CENTERY = (SCREENHEIGHT//2)

  # Screen 0 is the screen updated by I_Update screen.
  # Screen 1 is an extra buffer.

  # Allocates buffer screens, call before R_Init.
  fun v_init = V_Init

  fun v_copy_rect = V_CopyRect(srcx : LibC::Int,
                               srcy : LibC::Int,
                               srcscrn : LibC::Int,
                               width : LibC::Int,
                               height : LibC::Int,
                               destx : LibC::Int,
                               desty : LibC::Int,
                               destscrn : LibC::Int,)

  fun v_draw_patch = V_DrawPatch(x : LibC::Int,
                                 y : LibC::Int,
                                 scrn : LibC::Int,
                                 patch : Patch*)

  fun v_draw_patch_direct = V_DrawPatchDirect(x : LibC::Int,
                                              y : LibC::Int,
                                              scrn : LibC::Int,
                                              patch : Patch*)

  fun v_draw_patch_rect_direct = V_DrawPatchRectDirect(x : LibC::Int, y : LibC::Int, scrn : LibC::Int, patch : Patch*, src_x : LibC::Int, src_w : LibC::Int)

  # Draw a linear block of pixels into the view buffer.
  fun v_draw_block = V_DrawBlock(x : LibC::Int,
                                 y : LibC::Int,
                                 scrn : LibC::Int,
                                 width : LibC::Int,
                                 height : LibC::Int,
                                 src : Byte*)

  # Reads a linear block of pixels into the view buffer.
  fun v_get_block = V_GetBlock(x : LibC::Int,
                               y : LibC::Int,
                               scrn : LibC::Int,
                               width : LibC::Int,
                               height : LibC::Int,
                               dest : Byte*)

  fun v_mark_rect = V_MarkRect(x : LibC::Int,
                               y : LibC::Int,
                               width : LibC::Int,
                               height : LibC::Int)

  # __W_WAD__

  #
  # TYPES
  #
  struct Filelump
    filepos : LibC::Int
    size : LibC::Int
    name : LibC::Char[8]
  end

  #
  # WADFILE I/O related stuff.
  #

  fun w_init_multiple_files = W_InitMultipleFiles(filenames : LibC::Char**)
  fun w_reload = W_Reload

  fun w_check_num_for_name = W_CheckNumForName(name : LibC::Char*) : LibC::Int
  fun w_get_num_for_name = W_GetNumForName(name : LibC::Char*) : LibC::Int

  fun w_lump_length = W_LumpLength(lump : LibC::Int) : LibC::Int
  fun w_read_lump = W_ReadLump(lump : LibC::Int, dest : Void*)

  fun w_cache_lump_num = W_CacheLumpNum(lump : LibC::Int, tag : LibC::Int) : Void*
  fun w_cache_lump_name = W_CacheLumpName(name : LibC::Char*, tag : LibC::Int) : Void*

  # __WI_STUFF__

  # States for the intermission
  enum Stateenum
    NoState     = -1
    StatCount
    ShowNextLoc
  end

  # Called by main loop, animate the intermission.
  fun wi_ticker = WI_Ticker

  # Called by main loop,
  # draws the intermission directly into the screen buffer.
  fun wi_drawer = WI_Drawer

  # Setup for an intermission screen.
  # __Z_ZONE__

  #
  # ZONE MEMORY
  # PU - purge tags.
  # Rags < 100 are not overwritten until freed.
  PU_STATIC  =  1 # static entire execution time
  PU_SOUND   =  2 # static while playing
  PU_MUSIC   =  3 # static while playing
  PU_DAVE    =  4 # anything else Dave wants static
  PU_LEVEL   = 50 # static until level exited
  PU_LEVSPEC = 51 # a special thinker in a level
  # Tags >= 100 are purgable whenever needed.
  PU_PURGELEVEL = 100
  PU_CACHE      = 101

  fun z_init = Z_Init
  fun z_malloc = Z_Malloc(size : LibC::Int, tag : LibC::Int, ptr : Void*) : Void*
  fun z_free = Z_Free(ptr : Void*)
  fun z_free_tags = Z_FreeTags(lowtag : LibC::Int, hightag : LibC::Int)
  fun z_check_heap = Z_CheckHeap
  fun z_change_tag2 = Z_ChangeTag2(ptr : Void*, tag : LibC::Int)

  struct Memblock
    size : LibC::Int # including the header and possibly tiny fragments
    user : Void**    # 0 if a free block
    tag : LibC::Int  # purgelevel
    id : LibC::Int   # should be ZONEID
    next : Memblock*
    prev : Memblock*
  end

  # IMPLEMENTATION

  SCREEN_PALETTE_SIZE = 256 * 3



  fun d_doom_loop = D_DoomLoop
  fun d_update_wipe = D_UpdateWipe

  REDS        = (256 - 5*16)
  REDRANGE    = 16
  BLUES       = (256 - 4*16 + 8)
  BLUERANGE   = 8
  GREENS      = (7*16)
  GREENRANGE  = 16
  GRAYS       = (6*16)
  GRAYSRANGE  = 16
  BROWNS      = (4*16)
  BROWNRANGE  = 16
  YELLOWS     = (256 - 32 + 7)
  YELLOWRANGE = 1
  BLACK       = 0
  WHITE       = (256 - 47)

  # Automap colors
  BACKGROUND       = BLACK
  YOURCOLORS       = WHITE
  YOURRANGE        = 0
  WALLCOLORS       = REDS
  WALLRANGE        = REDRANGE
  TSWALLCOLORS     = GRAYS
  TSWALLRANGE      = GRAYSRANGE
  FDWALLCOLORS     = BROWNS
  FDWALLRANGE      = BROWNRANGE
  CDWALLCOLORS     = YELLOWS
  CDWALLRANGE      = YELLOWRANGE
  THINGCOLORS      = GREENS
  THINGRANGE       = GREENRANGE
  SECRETWALLCOLORS = WALLCOLORS
  SECRETWALLRANGE  = WALLRANGE
  GRIDCOLORS       = (GRAYS + GRAYSRANGE/2)
  GRIDRANGE        = 0
  XHAIRCOLORS      = GRAYS

  # drawing stuff
  FB = 0

  AM_PANDOWNKEY   = KEY_DOWNARROW
  AM_PANUPKEY     = KEY_UPARROW
  AM_PANRIGHTKEY  = KEY_RIGHTARROW
  AM_PANLEFTKEY   = KEY_LEFTARROW
  AM_ZOOMINKEY    = '='
  AM_ZOOMOUTKEY   = '-'
  AM_STARTKEY     = KEY_TAB
  AM_ENDKEY       = KEY_TAB
  AM_GOBIGKEY     = '0'
  AM_FOLLOWKEY    = 'f'
  AM_GRIDKEY      = 'g'
  AM_MARKKEY      = 'm'
  AM_CLEARMARKKEY = 'c'

  AM_NUMMARKPOINTS = 10

  # scale on entry
  INITSCALEMTOF = (0.2*Doocr::FRACUNIT)
  # how much the automap moves window per tic in frame-buffer coordinates
  # moves 140 pixels in 1 second
  F_PANINC = 4
  # how much zoom-in per tic
  # goes to 2x in 1 second
  M_ZOOMIN = (1.02*Doocr::FRACUNIT).to_i32
  # how much zoom-out per tic
  # pulls out to 0.5x in 1 second
  M_ZOOMOUT = (Doocr::FRACUNIT/1.02).to_i32

  # the following is crap
  LINE_NEVERSEE = ML_DONTDRAW

  #
  # The vector graphics for the automap.
  # A line drawing of the player pointing right,
  # starting from the middle.
  #
  R                 = ((8*PLAYERRADIUS)//7)
  NUMPLYRLINES      = 7
  NUMCHEATPLYRLINES = 16

  NUMTRIANGLEGUYLINES     = 3
  NUMTHINTRIANGLEGUYLINES = 3




  # location of window on screen

  # size of window on screen



  # LL x,y where the window is on the map (map coords)
  # UR x,y where the window is on the map (map coords)

  #
  # width/height of window on map (map coords)
  #

  # based on level size


  # based on player size


  # old stuff for recovery later

  # old location used by the Follower routine
  # used by MTOF to scale from map-to-frame-buffer coords
  # used by FTOM to scale from frame-buffer-to-map coords (=1/scale_mtof)







  MAXARGVS = 100








  #
  # EVENT HANDLING
  #
  # Events are asynchronous inputs generally generated by the game user.
  # Events can be discarded if no responder claims them
  #
  # wipegamestate can be set to -1 to force a wipe on the next draw
  fun r_execute_set_view_size = R_ExecuteSetViewSize

  # print title for every printed line

  fun d_doom_loop = D_DoomLoop
  fun d_check_net_game = D_CheckNetGame
  fun d_process_events = D_ProcessEvents
  fun g_build_ticcmd = G_BuildTiccmd(cmd : Ticcmd*)
  fun d_do_advance_demo = D_DoAdvanceDemo

  fun d_post_event = D_PostEvent(ev : Event*)

  fun d_process_events = D_ProcessEvents

  fun d_display = D_Display

  fun d_update_wipe = D_UpdateWipe

  fun d_doom_loop = D_DoomLoop

  #
  # DEMO LOOP
  #

  fun d_page_ticker = D_PageTicker

  fun d_page_drawer = D_PageDrawer

  fun d_advance_demo = D_AdvanceDemo

  fun d_do_advance_demo = D_DoAdvanceDemo

  fun d_start_title = D_StartTitle

  fun d_add_file = D_AddFile(file : LibC::Char*)

  fun identify_version = IdentifyVersion

  fun find_response_file = FindResponseFile





  fun d_process_events = D_ProcessEvents
  fun g_build_ticcmd = G_BuildTiccmd(cmd : Ticcmd*)
  fun d_do_advance_demo = D_DoAdvanceDemo

  fun net_buffer_size = NetBufferSize : LibC::Int

  fun net_buffer_checksum = NetbufferChecksum : LibC::UInt

  fun expand_tics = ExpandTics(low : LibC::Int) : LibC::Int

  fun h_send_packet = HSendPacket(node : LibC::Int, flags : LibC::Int)

  fun h_get_packet = HGetPacket : DoomBool

  fun get_packets = GetPackets

  fun net_update = NetUpdate

  fun check_abort = CheckAbort

  fun d_arbitrate_net_start = D_ArbitrateNetStart

  fun d_check_net_game = D_CheckNetGame

  fun d_quit_net_game = D_QuitNetGame

  fun try_run_tics = TryRunTics

  TEXTSPEED =   3
  TEXTWAIT  = 250




  #
  # f_start_cast
  #

  fun f_start_cast = F_StartCast
  fun f_cast_ticker = F_CastTicker
  fun f_cast_responder = F_CastResponder(ev : Event*) : DoomBool
  fun f_cast_drawer = F_CastDrawer
  fun v_draw_patch_flipped = V_DrawPatchFlipped(x : LibC::Int, y : LibC::Int, scrn : LibC::Int, patch : Patch*)

  fun f_start_finale = F_StartFinale

  fun f_responder = F_Responder(event : Event*) : DoomBool

  fun f_ticker = F_Ticker

  fun f_text_write = F_TextWrite

  fun f_start_cast = F_StartCast

  fun f_cast_ticker = F_CastTicker

  fun f_cast_responder = F_CastResponder(ev : Event*) : DoomBool

  fun f_cast_print = F_CastPrint(text : LibC::Char*)

  fun f_cast_drawer = F_CastDrawer

  fun f_draw_patch_col = F_DrawPatchCol(x : LibC::Int, patch : Patch*, col : LibC::Int)

  fun f_bunny_scroll = F_BunnyScroll

  fun f_drawer = F_Drawer




  fun wipe_shitty_col_major_x_form = wipe_shittyColMajorXform(array : LibC::Short*, width : LibC::Int, height : LibC::Int)

  fun wipe_init_color_x_form = wipe_initColorXForm(width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int

  fun wipe_do_color_x_form = wipe_doColorXForm(width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int

  fun wipe_exit_color_x_form = wipe_exitColorXForm(width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int

  fun wipe_init_melt = wipe_initMelt(width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int

  fun wipe_do_melt = wipe_doMelt(width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int

  fun wipe_exit_melt = wipe_exitMelt(width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int

  fun wipe_start_screen = wipe_StartScreen(x : LibC::Int, y : LibC::Int, width : LibC::Int, height : LibC::Int) : LibC::Int

  fun wipe_end_screen = wipe_EndScreen(x : LibC::Int, y : LibC::Int, width : LibC::Int, height : LibC::Int) : LibC::Int

  fun wipe_screen_wipe = wipe_ScreenWipe(wipeno : LibC::Int, x : LibC::Int, y : LibC::Int, width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int

  SAVEGAMESIZE   = 0x2c000
  SAVESTRINGSIZE =      24
  TURBOTHRESHOLD =    0x32
  SLOWTURNTICS   =       6
  NUMKEYS        =     256
  BODYQUESIZE    =      32
  VERSIONSIZE    =      16
  DEMOMARKER     =    0x80

  # Prototypes
  fun g_check_demo_status = G_CheckDemoStatus : DoomBool
  fun g_read_demo_ticcmd = G_ReadDemoTiccmd(cmd : Ticcmd*)
  fun g_write_demo_ticcmd = G_WriteDemoTiccmd(cmd : Ticcmd*)
  fun g_player_reborn = G_PlayerReborn(player : LibC::Int)
  fun g_init_new = G_InitNew(skill : Skill, episode : LibC::Int, map : LibC::Int)
  fun g_do_reborn = G_DoReborn(playernum : LibC::Int)
  fun g_do_load_level = G_DoLoadLevel
  fun g_do_new_game = G_DoNewGame
  fun g_do_load_game = G_DoLoadGame
  fun g_do_play_demo = G_DoPlayDemo
  fun g_do_completed = G_DoCompleted
  fun g_do_world_done = G_DoWorldDone
  fun g_do_save_game = G_DoSaveGame
  fun p_spawn_player = P_SpawnPlayer(mthing : Mapthing*)
  fun r_execute_set_view_size = R_ExecuteSetViewSize





  #
  # controls (have defaults)
  #




  # joystick values are repeated




  # DOOM Par Times






  fun g_build_ticcmd = G_BuildTiccmd(cmd : Ticcmd*)

  fun g_init_player = G_InitPlayer(player : LibC::Int)

  fun g_player_finish_level = G_PlayerFinishLevel(player : LibC::Int)

  fun g_player_reborn = G_PlayerReborn(player : LibC::Int)

  fun g_check_spot = G_CheckSpot(playernum : LibC::Int, mthing : Mapthing*) : DoomBool

  fun g_deathmatch_spawn_player = G_DeathMatchSpawnPlayer(playernum : LibC::Int)

  NOTERASED = CDoom.viewwindowx

  HU_TITLEHEIGHT = 1
  HU_INPUTTOGGLE = 't'.ord
  HU_INPUTWIDTH  =  64
  HU_INPUTHEIGHT =   1
  QUEUESIZE      = 128










  # DOOM shareware/registered/retail (Ultimate) names.

  # DOOM 2 map names.



  fun foreign_translation = ForeignTranslation(ch : LibC::Char) : LibC::Char

  fun hu_stop = HU_Stop

  fun hu_queue_chat_char = HU_queueChatChar(c : LibC::Char)

  IPPORT_USERRESERVED = 5000

  SAMPLECOUNT  = 512
  NUM_CHANNELS =  16
  # It is 2 for 16bit, and 2 for two channels.
  BUFMUL        = 4
  MIXBUFFERSIZE = SAMPLECOUNT * BUFMUL

  SAMPLERATE = 11025 # Hz
  SAMPLESIZE =     2 # 16bit

  MAX_QUEUED_MIDI_MSGS = 256

  EVENT_RELEASE_NOTE   = 0
  EVENT_PLAY_NOTE      = 1
  EVENT_PITCH_BEND     = 2
  EVENT_SYSTEM_EVENT   = 3
  EVENT_CONTROLLER     = 4
  EVENT_END_OF_MEASURE = 5
  EVENT_FINISH         = 6
  EVENT_UNUSED         = 7

  CONTROLLER_EVENT_ALL_SOUNDS_OFF        = 10
  CONTROLLER_EVENT_ALL_NOTES_OFF         = 11
  CONTROLLER_EVENT_MONO                  = 12
  CONTROLLER_EVENT_POLY                  = 13
  CONTROLLER_EVENT_RESET_ALL_CONTROLLERS = 14
  CONTROLLER_EVENT_EVENT                 = 15

  CONTROLLER_CHANGE_INSTRUMENT = 0
  CONTROLLER_BANK_SELECT       = 1
  CONTROLLER_MODULATION        = 2
  CONTROLLER_VOLUME            = 3
  CONTROLLER_PAN               = 4
  CONTROLLER_EXPRESSION        = 5
  CONTROLLER_REVERB            = 6
  CONTROLLER_CHORUS            = 7
  CONTROLLER_SUSTAIN           = 8
  CONTROLLER_SOFT              = 9

  # A quick hack to establish a protocol between
  # synchronous mix buffer updates and asynchronous
  # audio writes. Probably redundant with gametic.



  # The number of internal mixing channels,
  #  the samples calculated for each mixing step,
  #  the size of the 16bit, 2 hardware channel (stereo)
  #  mixing buffer, and the samplerate of the raw data.

  # The global mixing buffer.
  # Basically, samples from all active internal channels
  #  are modifed and added, and stored in the buffer
  #  that is submitted to the audio device.

  # The channel step amount...
  # ... and a 0.16 bit remainder of last step.

  # The channel data pointers, start and end.

  # Time/gametic that the channel started playing,
  #  used to determine oldest, which automatically
  #  has lowest priority.
  # In case number of active sounds exceeds
  #  available channels.

  # The sound in channel handles,
  #  determined on registration,
  #  might be used to unregister/stop/modify,
  #  currently unused.

  # SFX id of the playing sound effect.
  # Used to catch duplicates (like chainsaw).

  # Pitch to stepping lookup, unused.

  # Volume lookups.

  # Hardware left and right channel volume lookup.


  fun tick_song = TickSong

  fun getsfx(sfxname : LibC::Char*, len : LibC::Int*) : Void*
  fun addsfx(sfxid : LibC::Int, volume : LibC::Int, step : LibC::Int, seperation : LibC::Int) : LibC::Int

  fun i_set_music_volume = I_SetMusicVolume(volume : LibC::Int)

  fun reset_all_channels

  fun i_qry_song_playing = I_QrySongPlaying(handle : LibC::Int) : LibC::Int


  fun i_get_heap_size = I_GetHeapSize : LibC::Int

  fun a_light0 = A_Light0(player : Player*, psp : Pspdef*)
  fun a_weapon_ready = A_WeaponReady(player : Player*, psp : Pspdef*)
  fun a_lower = A_Lower(player : Player*, psp : Pspdef*)
  fun a_raise = A_Raise(player : Player*, psp : Pspdef*)
  fun a_punch = A_Punch(player : Player*, psp : Pspdef*)
  fun a_refire = A_ReFire(player : Player*, psp : Pspdef*)
  fun a_fire_pistol = A_FirePistol(player : Player*, psp : Pspdef*)
  fun a_light1 = A_Light1(player : Player*, psp : Pspdef*)
  fun a_fire_shotgun = A_FireShotgun(player : Player*, psp : Pspdef*)
  fun a_light2 = A_Light2(player : Player*, psp : Pspdef*)
  fun a_fire_shotgun2 = A_FireShotgun2(player : Player*, psp : Pspdef*)
  fun a_check_reload = A_CheckReload(player : Player*, psp : Pspdef*)
  fun a_open_shotgun2 = A_OpenShotgun2(player : Player*, psp : Pspdef*)
  fun a_load_shotgun2 = A_LoadShotgun2(player : Player*, psp : Pspdef*)
  fun a_close_shotgun2 = A_CloseShotgun2(player : Player*, psp : Pspdef*)
  fun a_fire_cgun = A_FireCGun(player : Player*, psp : Pspdef*)
  fun a_gun_flash = A_GunFlash(player : Player*, psp : Pspdef*)
  fun a_fire_missile = A_FireMissile(player : Player*, psp : Pspdef*)
  fun a_saw = A_Saw(player : Player*, psp : Pspdef*)
  fun a_fire_plasma = A_FirePlasma(player : Player*, psp : Pspdef*)
  fun a_bfg_sound = A_BFGsound(player : Player*, psp : Pspdef*)
  fun a_fire_bfg = A_FireBFG(player : Player*, psp : Pspdef*)
  fun a_bfg_spray = A_BFGSpray(mo : Mobj*)
  fun a_explode = A_Explode(thingy : Mobj*)
  fun a_pain = A_Pain(actor : Mobj*)
  fun a_player_scream = A_PlayerScream(mo : Mobj*)
  fun a_fall = A_Fall(actor : Mobj*)
  fun a_xscream = A_XScream(actor : Mobj*)
  fun a_look = A_Look(actor : Mobj*)
  fun a_chase = A_Chase(actor : Mobj*)
  fun a_face_target = A_FaceTarget(actor : Mobj*)
  fun a_pos_attack = A_PosAttack(actor : Mobj*)
  fun a_scream = A_Scream(actor : Mobj*)
  fun a_spos_attack = A_SPosAttack(actor : Mobj*)
  fun a_vile_chase = A_VileChase(actor : Mobj*)
  fun a_vile_start = A_VileStart(actor : Mobj*)
  fun a_vile_target = A_VileTarget(actor : Mobj*)
  fun a_vile_attack = A_VileAttack(actor : Mobj*)
  fun a_start_fire = A_StartFire(actor : Mobj*)
  fun a_fire = A_Fire(actor : Mobj*)
  fun a_fire_crackle = A_FireCrackle(actor : Mobj*)
  fun a_tracer = A_Tracer(actor : Mobj*)
  fun a_skel_whoosh = A_SkelWhoosh(actor : Mobj*)
  fun a_skel_fist = A_SkelFist(actor : Mobj*)
  fun a_skel_missile = A_SkelMissile(actor : Mobj*)
  fun a_fat_raise = A_FatRaise(actor : Mobj*)
  fun a_fat_attack1 = A_FatAttack1(actor : Mobj*)
  fun a_fat_attack2 = A_FatAttack2(actor : Mobj*)
  fun a_fat_attack3 = A_FatAttack3(actor : Mobj*)
  fun a_boss_death = A_BossDeath(mo : Mobj*)
  fun a_cpos_attack = A_CPosAttack(actor : Mobj*)
  fun a_cpos_refire = A_CPosRefire(actor : Mobj*)
  fun a_troop_attack = A_TroopAttack(actor : Mobj*)
  fun a_sarg_attack = A_SargAttack(actor : Mobj*)
  fun a_head_attack = A_HeadAttack(actor : Mobj*)
  fun a_bruis_attack = A_BruisAttack(actor : Mobj*)
  fun a_skull_attack = A_SkullAttack(actor : Mobj*)
  fun a_metal = A_Metal(mo : Mobj*)
  fun a_spid_refire = A_SpidRefire(actor : Mobj*)
  fun a_baby_metal = A_BabyMetal(mo : Mobj*)
  fun a_bspi_attack = A_BspiAttack(actor : Mobj*)
  fun a_hoof = A_Hoof(mo : Mobj*)
  fun a_cyber_attack = A_CyberAttack(actor : Mobj*)
  fun a_pain_attack = A_PainAttack(actor : Mobj*)
  fun a_pain_die = A_PainDie(actor : Mobj*)
  fun a_keen_die = A_KeenDie(mo : Mobj*)
  fun a_brain_pain = A_BrainPain(mo : Mobj*)
  fun a_brain_scream = A_BrainScream(mo : Mobj*)
  fun a_brain_die = A_BrainDie(mo : Mobj*)
  fun a_brain_awake = A_BrainAwake(mo : Mobj*)
  fun a_brain_spit = A_BrainSpit(mo : Mobj*)
  fun a_spawn_sound = A_SpawnSound(mo : Mobj*)
  fun a_spawn_fly = A_SpawnFly(mo : Mobj*)
  fun a_brain_explode = A_BrainExplode(mo : Mobj*)

  SKULLXOFF  = -32
  LINEHEIGHT =  16

  #
  # MENU TYPEDEFS
  #

  # Blocky mode, has default, 0 = high, 1 = normal

  # temp for screenblocks (0-9)

  # -1 = no quicksave slot picked!

  # 1 = message to be printed
  # ...and here is the message string!

  # message x & y

  # timed message = no input from user



  # we are going to be entering a savegame string



  # graphic name of skulls
  # warning: initializer-string for array of chars is too long

  # current menudef

  # We create new menu text by cutting into existing graphics and pasting them to create the new text.
  # This way we don't ship code with embeded graphics that come from WAD files.





  # DOOM MENU
  #
  enum Mainenum
    Newgame
    Options
    Loadgame
    Savegame
    Readthis
    Quitdoom
    MainEnd
  end

  #
  # EPISODE SELECT
  #
  enum Episodesenum
    Ep1
    Ep2
    Ep3
    Ep4
    EpEnd
  end

  #
  # NEW GAME
  #
  enum NewgameEnum
    Killthings
    Toorough
    Hurtme
    Violence
    Nightmare
    NewgEnd
  end

  #
  # OPTIONS MENU
  #
  enum OptionsEnum
    Endgame
    Messages
    Scrnsize
    Optionempty1
    Mousesensitivity
    Optionempty2
    Soundvol
    More
    OptEnd
  end

  #
  # MOUSE OPTIONS
  #
  enum MouseoptionsEnum
    Mousemov
    Mousesens
    Mouseoptionempty1
    MouseOptEnd
  end

  #
  # Read This! MENU 1 & 2
  #
  enum Readenum
    Rdthsempty1
    Read1End
  end

  enum Read2enum
    Rdthsempty2
    Read2End
  end

  #
  # SOUND VOLUME MENU
  #
  enum Soundenum
    Sfxvol
    Sfxempty1
    Musicvol
    Sfxempty2
    SoundEnd
  end

  #
  # LOAD GAME MENU
  #
  enum Loadenum
    Load1
    Load2
    Load3
    Load4
    Load5
    Load6
    LoadEnd
  end

  fun m_do_save = M_DoSave(slot : LibC::Int)

  fun m_quicksave_response = M_QuickSaveResponse(ch : LibC::Int)

  fun m_quickload_response = M_QuickLoadResponse(ch : LibC::Int)

  fun m_verify_nightmare = M_VerifyNightmare(ch : LibC::Int)

  fun m_endgame_response = M_EndGameResponse(ch : LibC::Int)

  fun m_quit_response = M_QuitResponse(ch : LibC::Int)

  STRING_VALUE = 0xffff

  #
  # SCREEN SHOTS
  #





  fun p_random = P_Random : LibC::Int

  MAXSPECIALCROSS = 8
  FATSPREAD       = Doocr::ANG90 // 8
  SKULLSPEED      = 20*Doocr::FRACUNIT

  enum Dirtype
    East
    NorthEast
    North
    NorthWest
    West
    SouthWest
    South
    SouthEast
    NoDir
    NUMDIRS
  end



  # keep track of special lines as they are hit,
  # but don't process them until the move is proven valid

  fun p_recursive_sound = P_RecursiveSound(sec : Sector*, soundblocks : LibC::Int)

  fun p_check_melee_range = P_CheckMeleeRange(actor : Mobj*) : DoomBool

  fun p_check_missile_range = P_CheckMissileRange(actor : Mobj*) : DoomBool

  fun p_move = P_Move(actor : Mobj*) : DoomBool

  fun p_try_walk = P_TryWalk(actor : Mobj*) : DoomBool

  fun p_new_chase_dir = P_NewChaseDir(actor : Mobj*)

  fun p_look_for_players = P_LookForPlayers(actor : Mobj*, allaround : DoomBool) : DoomBool

  fun pit_vile_check = PIT_VileCheck(thing : Mobj*) : DoomBool

  fun a_pain_shoot_skull = A_PainShootSkull(actor : Mobj*, angle : Angle)

  BONUSADD = 6

  fun p_give_ammo = P_GiveAmmo(player : Player*, ammo : Ammotype, num : LibC::Int) : DoomBool
  fun p_give_weapon = P_GiveWeapon(player : Player*, weapon : Weapontype, dropped : DoomBool) : DoomBool
  fun p_give_body = P_GiveBody(player : Player*, num : LibC::Int) : DoomBool
  fun p_give_armor = P_GiveArmor(player : Player*, armortype : LibC::Int) : DoomBool
  fun p_give_card = P_GiveCard(player : Player*, card : Card)

  fun p_kill_mobj = P_KillMobj(source : Mobj*, target : Mobj*)

  fun t_fire_flicker = T_FireFlicker(flick : Fireflicker*)


  # Height if not aiming up or down
  # ???: use slope for monsters?



  # slopes to top and bottom of target

  fun pit_stomp_thing = PIT_StompThing(thing : Mobj*) : DoomBool
  fun pit_check_line = PIT_CheckLine(ld : Line*) : DoomBool

  fun pit_check_thing = PIT_CheckThing(thing : Mobj*) : DoomBool
  fun p_thing_height_clip = P_ThingHeightClip(thing : Mobj*) : DoomBool





  fun p_hit_slide_line = P_HitSlideLine(ld : Line*)
  fun ptr_slide_traverse = PTR_SlideTraverse(int : Intercept*) : DoomBool
  fun ptr_aim_traverse = PTR_AimTraverse(int : Intercept*) : DoomBool
  fun ptr_shoot_traverse = PTR_ShootTraverse(int : Intercept*) : DoomBool
  fun ptr_use_traverse = PTR_UseTraverse(int : Intercept*) : DoomBool

  fun pit_radius_attack = PIT_RadiusAttack(thing : Mobj*) : DoomBool
  fun pit_change_sector = PIT_ChangeSector(thing : Mobj*) : DoomBool


  fun pit_add_line_intercepts = PIT_AddLineIntercepts(ld : Line*) : DoomBool
  fun pit_add_thing_intercepts = PIT_AddThingIntercepts(thing : Mobj*) : DoomBool
  fun p_traverse_intercepts = P_TraverseIntercepts(func : Traverser, maxfrac : Fixed) : DoomBool

  STOPSPEED = 0x1000
  FRICTION  = 0xe800

  fun p_explode_missile = P_ExplodeMissile(mo : Mobj*)

  fun p_xymovement = P_XYMovement(mo : Mobj*)
  fun p_zmovement = P_ZMovement(mo : Mobj*)

  fun p_nightmare_respawn = P_NightmareRespawn(mobj : Mobj*)

  fun p_spawn_map_thing = P_SpawnMapThing(mthing : Mapthing*)

  fun p_check_missile_spawn = P_CheckMissileSpawn(th : Mobj*)

  LOWERSPEED = Doocr::FRACUNIT*6
  RAISESPEED = Doocr::FRACUNIT*6

  WEAPONBOTTOM = 128*Doocr::FRACUNIT
  WEAPONTOP    = 32*Doocr::FRACUNIT

  # plasma cells for a bfg attack
  BFGCELLS = 40


  fun p_set_psprite = P_SetPsprite(player : Player*, position : LibC::Int, stnum : Statenum)
  fun p_bring_up_weapon = P_BringUpWeapon(player : Player*)
  fun p_check_ammo = P_CheckAmmo(player : Player*) : DoomBool
  fun p_fire_weapon = P_FireWeapon(player : Player*)
  fun p_bullet_slope = P_BulletSlope(mo : Mobj*)
  fun p_gunshot = P_GunShot(mo : Mobj*, accurate : DoomBool)


  enum Thinkerclass : Byte
    End
    Mobj
  end

  enum Specials : Byte
    Ceiling
    Door
    Floor
    Plat
    Flash
    Strobe
    Glow
    End
  end

  MAX_DEATHMATCH_STARTS = 10

  fun p_load_vertexes = P_LoadVertexes(lump : LibC::Int)
  fun p_load_segs = P_LoadSegs(lump : LibC::Int)
  fun p_load_subsectors = P_LoadSubsectors(lump : LibC::Int)
  fun p_load_sectors = P_LoadSectors(lump : LibC::Int)
  fun p_load_nodes = P_LoadNodes(lump : LibC::Int)
  fun p_load_things = P_LoadThings(lump : LibC::Int)
  fun p_load_linedefs = P_LoadLineDefs(lump : LibC::Int)
  fun p_load_sidedefs = P_LoadSideDefs(lump : LibC::Int)
  fun p_group_lines = P_GroupLines



  fun p_divline_side = P_DivlineSide(x : Fixed, y : Fixed, node : Divline*) : LibC::Int
  fun p_intercept_vector2 = P_InterceptVector2(v2 : Divline*, v1 : Divline*) : Fixed
  fun p_cross_subsector = P_CrossSubsector(num : LibC::Int) : DoomBool
  fun p_cross_bsp_node = P_CrossBSPNode(bspnum : LibC::Int) : DoomBool

  MAXANIMS     = 32
  MAXLINEANIMS = 64

  # 20 adjoining sectors max! [dsl] Useless comment is useless [ds] Useless comment addition is useless
  MAX_ADJOINING_SECTORS = 20

  #
  # Animating textures and planes
  # There is another anim_t used in wi_stuff, unrelated.
  #
  SWITCHLIST_SIZE = MAXSWITCHES * 2

  fun p_start_button = P_StartButton(line : Line*, w : Bwhere, texture : LibC::Int, time : LibC::Int)
  fun p_run_thinkers = P_RunThinkers
  INVERSECOLORMAP = 32

  # 16 pixels of bob
  MAXBOB = 0x100000

  ANG5 = Doocr::ANG90//18


  fun p_thrust = P_Thrust(player : Player*, angle : Angle, move : Fixed)
  fun p_calc_height = P_CalcHeight(player : Player*)
  fun p_move_player = P_MovePlayer(player : Player*)
  fun p_death_think = P_DeathThink(player : Player*)

  MAXSEGS = 32

  #
  # Clips the given range of columns
  # and includes it in the new clip list.
  #
  fun r_store_wall_range = R_StoreWallRange(start : LibC::Int, stop : LibC::Int)
  fun r_clip_solid_wall_segment = R_ClipSolidWallSegment(first : LibC::Int, last : LibC::Int)
  fun r_clip_pass_wall_segment = R_ClipPassWallSegment(first : LibC::Int, last : LibC::Int)
  fun r_addline = R_AddLine(line : Seg*)
  fun r_check_bbox = R_CheckBBox(bspcoord : Fixed*) : DoomBool
  fun r_subsector = R_Subsector(num : LibC::Int)

  #
  # Texture definition.
  # Each texture is composed of one or more patches,
  # with patches being lumps stored in the WAD.
  # The lumps are referenced by number, and patched
  # into the rectangular texture space using origin
  # and possibly other attributes.
  #
  struct Mappatch
    originx : LibC::Short
    originy : LibC::Short
    patch : LibC::Short
    stepdir : LibC::Short
    colormap : LibC::Short
  end

  #
  # Texture definition.
  # A DOOM wall texture is a list of patches
  # which are to be combined in a predefined order.
  #
  struct Maptexture
    name : LibC::Char[8]
    masked : DoomBool
    width : LibC::Short
    height : LibC::Short
    columndirectory : LibC::Int # [pd] If it's not used, at least make sure it's the right size! Pointers are 8 bytes in x64
    patchcount : LibC::Short
    patches : Mappatch[1]
  end

  # A single patch from a texture definition,
  # basically a rectangular area within
  # the texture rectangle.
  struct Texpatch
    # Block origin (allways UL),
    # which has allready accounted
    # for the internal origin of the patch.
    originx : LibC::Int
    originy : LibC::Int
    patch : LibC::Int
  end

  # A maptexturedef_t describes a rectangular texture,
  # which is composed of one or more mappatch_t structures
  # that arrange graphic patches.
  struct Texture
    # Keep name for switch changing, etc.
    name : LibC::Char[8]
    width : LibC::Short
    height : LibC::Short

    # All the patches[patchcount]
    #  are drawn back to front into the cached texture.
    patchcount : LibC::Short
    patches : Texpatch[1]
  end






  fun r_draw_column_in_cache = R_DrawColumnInCache(patch : Column*, cache : Byte*, originy : LibC::Int, cacheheight : LibC::Int)
  fun r_generate_composite = R_GenerateComposite(texnum : LibC::Int)
  fun r_generate_lookup = R_GenerateLookup(texnum : LibC::Int)
  fun r_init_textures = R_InitTextures
  fun r_init_flats = R_InitFlats
  fun r_init_sprite_lumps = R_InitSpriteLumps
  fun r_init_colormaps = R_InitColormaps

  MAXWIDTH  = 1120
  MAXHEIGHT =  832

  # status bar height at bottom of screen
  SBARHEIGHT = 32

  FUZZTABLE = 50
  FUZZOFF   = SCREENWIDTH


  # just for profiling


  # just for profiling

  FIELDOFVIEW = 2048 # Fineangles in the SCREENWIDTH wide window.
  DISTMAP     =    2

  # just for profiling purposes


  fun r_init_tables = R_InitTables
  fun r_init_texture_mapping = R_InitTextureMapping
  fun r_init_light_tables = R_InitLightTables

  fun r_setup_frame = R_SetupFrame(player : Player*)

  MAXVISPLANES = 128
  MAXOPENINGS  = SCREENWIDTH*64


  #
  # opening
  #

  # Here comes the obnoxious "visplane".


  #
  # spanstart holds the start of a plane span
  # initialized to 0 at start
  #

  #
  # texture mapping
  #

  



  HEIGHTBITS = 12
  HEIGHTUNIT = 1 << HEIGHTBITS

  # OPTIMIZE: closed two sided lines as single sided







  fun r_render_seg_loop = R_RenderSegLoop

  MINZ        = Doocr::FRACUNIT * 4
  BASEYCENTER = 100

  struct Maskdraw
    x1 : LibC::Int
    x2 : LibC::Int

    column : LibC::Int
    topclip : LibC::Int
    bottomclip : LibC::Int
  end

  #
  # Sprite rotation 0 is facing the viewer,
  #  rotation 1 is one angle turn CLOCKWISE around the axis.
  # This is not the same as the angle,
  #  which increases counter clockwise (protractor).
  # There was a lot of stuff grabbed wrong, so I changed it...
  #



  fun r_install_sprite_lump = R_InstallSpriteLump(lump : LibC::Int, frame : LibC::UInt, rotation : LibC::UInt, flipped : DoomBool)


  fun r_new_vis_sprite = R_NewVisSprite : Vissprite*
  fun r_draw_vis_sprite = R_DrawVisSprite(vis : Vissprite*, x1 : LibC::Int, x2 : LibC::Int)
  fun r_project_sprite = R_ProjectSprite(thing : Mobj*)
  fun r_draw_psprite = R_DrawPSprite(psp : Pspdef*)
  fun r_draw_player_sprites = R_DrawPlayerSprites
  fun r_draw_sprite = R_DrawSprite(spr : Vissprite*)

  S_MAX_VOLUME = 127

  # when to clip out sounds
  # Does not fit the large outdoor areas.
  S_CLIPPING_DIST = (1200*0x10000)

  # Distance tp origin when sounds should be maxed out.
  # This should relate to movement clipping resolution
  # (see BLOCKMAP handling).
  # Originally: (200*0x10000).
  S_CLOSE_DIST = (160*0x10000)

  S_ATTENUATOR = ((S_CLIPPING_DIST - S_CLOSE_DIST) >> Doocr::FRACBITS)

  NORM_PITCH    = 128
  NORM_PRIORITY =  64
  NORM_SEP      = 128

  S_PITCH_PERTURB = 1
  S_STEREO_SWING  = (96*0x10000)

  # percent attenuation from front to back
  S_IFRACVOL = 30

  NA            = 0
  S_NUMCHANNELS = 2

  struct Channel
    # sound information (if null, channel avail.)
    sfxinfo : Sfxinfo*

    # origin of sound
    origin : Void*

    # handle of the sound being played
    handle : LibC::Int
  end

  # the set of channels available

  # whether songs are mus_paused

  # music currently being played

  fun s_get_channel = S_getChannel(origin : Void*, sfxinfo : Sfxinfo*) : LibC::Int
  fun s_adjust_sound_params = S_AdjustSoundParams(listener : Mobj*, source : Mobj*, vol : LibC::Int*, sep : LibC::Int*, pitch : LibC::Int*) : LibC::Int
  fun s_stop_channel = S_StopChannel(cnum : LibC::Int)

  #
  # Hack display negative frags.
  #  Loads and store the stminus lump.
  #

  fun stlib_draw_num = STlib_drawNum(n : ST_Number*, refresh : DoomBool)

  STARTREDPALS   = 1
  STARTBONUSPALS = 9
  NUMREDPALS     = 8
  NUMBONUSPALS   = 4
  # Radiation suit, green shift.
  RADIATIONPAL = 13

  # Location of status bar
  ST_X = 0

  ST_FX = 143

  # Number of status faces.
  ST_NUMPAINFACES     = 5
  ST_NUMSTRAIGHTFACES = 3
  ST_NUMTURNFACES     = 2
  ST_NUMSPECIALFACES  = 3

  ST_FACESTRIDE = (ST_NUMSTRAIGHTFACES + ST_NUMTURNFACES + ST_NUMSPECIALFACES)

  ST_NUMEXTRAFACES = 2

  ST_NUMFACES = (ST_FACESTRIDE * ST_NUMPAINFACES + ST_NUMEXTRAFACES)

  ST_TURNOFFSET     = (ST_NUMSTRAIGHTFACES)
  ST_OUCHOFFSET     = (ST_TURNOFFSET + ST_NUMTURNFACES)
  ST_EVILGRINOFFSET = (ST_OUCHOFFSET + 1)
  ST_RAMPAGEOFFSET  = (ST_EVILGRINOFFSET + 1)
  ST_GODFACE        = (ST_NUMPAINFACES*ST_FACESTRIDE)
  ST_DEADFACE       = (ST_GODFACE + 1)

  ST_FACESX = 143
  ST_FACESY = 168

  ST_EVILGRINCOUNT     = (2*TICRATE)
  ST_STRAIGHTFACECOUNT = (TICRATE/2)
  ST_TURNCOUNT         = (1*TICRATE)
  ST_OUCHCOUNT         = (1*TICRATE)
  ST_RAMPAGEDELAY      = (2*TICRATE)

  ST_MUCHPAIN = 20

  # Location and size of statistics,
  # justified according to widget type.
  # Problem is, within which space? STbar? Screen?
  # Note: this could be read in by a lump.
  #       Problem is, is the stuff rendered
  #       into a buffer,
  #       or into the frame buffer?

  # AMMO number pos.
  ST_AMMOWIDTH =   3
  ST_AMMOX     =  44
  ST_AMMOY     = 171

  # HEALTH number pos.
  ST_HEALTHX =  90
  ST_HEALTHY = 171

  # Weapon pos.
  ST_ARMSX      = 111
  ST_ARMSY      = 172
  ST_ARMSBGX    = 104
  ST_ARMSBGY    = 168
  ST_ARMSXSPACE =  12
  ST_ARMSYSPACE =  10

  # Frags pos.
  ST_FRAGSX     = 138
  ST_FRAGSY     = 171
  ST_FRAGSWIDTH =   2

  # ARMOR number pos.
  ST_ARMORX = 221
  ST_ARMORY = 171

  # Key icon positions.
  ST_KEY0WIDTH =   8
  ST_KEY0X     = 239
  ST_KEY0Y     = 171
  ST_KEY1WIDTH = ST_KEY0WIDTH
  ST_KEY1X     = 239
  ST_KEY1Y     = 181
  ST_KEY2WIDTH = ST_KEY0WIDTH
  ST_KEY2X     = 239
  ST_KEY2Y     = 191

  # Ammunition counter.
  ST_AMMO0WIDTH =   3
  ST_AMMO0X     = 288
  ST_AMMO0Y     = 173
  ST_AMMO1WIDTH = ST_AMMO0WIDTH
  ST_AMMO1X     = 288
  ST_AMMO1Y     = 179
  ST_AMMO2WIDTH = ST_AMMO0WIDTH
  ST_AMMO2X     = 288
  ST_AMMO2Y     = 191
  ST_AMMO3WIDTH = ST_AMMO0WIDTH
  ST_AMMO3X     = 288
  ST_AMMO3Y     = 185

  # Indicate maximum ammunition.
  # Only needed because backpack exists.
  ST_MAXAMMO0WIDTH =   3
  ST_MAXAMMO0X     = 314
  ST_MAXAMMO0Y     = 173
  ST_MAXAMMO1WIDTH = ST_MAXAMMO0WIDTH
  ST_MAXAMMO1X     = 314
  ST_MAXAMMO1Y     = 179
  ST_MAXAMMO2WIDTH = ST_MAXAMMO0WIDTH
  ST_MAXAMMO2X     = 314
  ST_MAXAMMO2Y     = 191
  ST_MAXAMMO3WIDTH = ST_MAXAMMO0WIDTH
  ST_MAXAMMO3X     = 314
  ST_MAXAMMO3Y     = 185

  # Dimensions given in characters.
  ST_MSGWIDTH = 52


  # Massive bunches of cheat shit
  #  to keep it from being easy to figure them out.
  # Yeah, right...

  # Smashing Pumpkins Into Samml Piles Of Putried Debris.



  # my position cheat

  # Now what?



  fun st_stop = ST_Stop

  fun st_refresh_background = ST_refreshBackground

  fun st_calc_pain_offset = ST_calcPainOffset : LibC::Int
  fun st_update_face_widget = ST_updateFaceWidget
  fun st_update_widgets = ST_updateWidgets
  fun st_do_palette_stuff = ST_doPaletteStuff
  fun st_draw_widgets = ST_drawWidgets(refresh : DoomBool)
  fun st_do_refresh = ST_doRefresh
  fun st_diff_draw = ST_diffDraw
  fun st_load_graphics = ST_loadGraphics
  fun st_load_data = ST_loadData
  fun st_unload_graphics = ST_unloadGraphics
  fun st_unload_data = ST_unloadData
  fun st_init_data = ST_initData
  fun st_create_widgets = ST_createWidgets


  fun doom_strupr(s : LibC::Char*)

  fun extract_file_base = ExtractFileBase(path : LibC::Char*, dest : LibC::Char*)

  fun w_add_file = W_AddFile(filename : LibC::Char*)

  NUMEPISODES = 4
  NUMMAPS     = 9

  # GLOBAL LOCATIONS
  WI_TITLEY   =  2
  WI_SPACINGY = 33

  # SINGPLE-PLAYER STUFF
  SP_STATSX = 50
  SP_STATSY = 50

  SP_TIMEX = 16
  SP_TIMEY = (SCREENHEIGHT - 32)

  # NET GAME STUFF
  NG_STATSY = 50

  NG_SPACINGX = 64

  # DEATHMATCH STUFF
  DM_MATRIXX = 42
  DM_MATRIXY = 68

  DM_SPACINGX = 40

  DM_TOTALSX = 269

  DM_KILLERSX =  10
  DM_KILLERSY = 100
  DM_VICTIMSX =   5
  DM_VICTIMSY =  50

  # States for single-player
  SP_KILLS  = 0
  SP_ITEMS  = 2
  SP_SECRET = 4
  SP_FRAGS  = 6
  SP_TIME   = 8
  SP_PAR    = ST_TIME

  SP_PAUSE = 1

  # in seconds
  SHOWNEXTLOCDELAY = 4

  enum Animenum
    Always
    Random
    Level
  end

  struct AnimPoint
    x : LibC::Int
    y : LibC::Int
  end

  #
  # GENERAL DATA
  #

  #
  # Locally used stuff.
  #

  # used to accelerate or skip a stage

  # wbs->pnum

  # specifies current state

  # contains information passed into intermission
  # used for general timing

  # used for timing of background animation

  # signals to refresh everything for one frame


  # # of commercial levels

  #
  # GRAPHICS
  #

  # background (map of levels).

  # You Are Here graphic

  # splat

  # %, : graphics

  # 0-9 graphic

  # minus sign

  # "Finished!" graphics

  # "Entering" graphic

  # "secret"

  # "Kills", "Scrt", "Items", "Frags"

  # Time sucks.

  # "killers", "victims"

  # "Total", your face, your dead face

  # "red P[1..MAXPLAYERS]"

  # "gray P[1..MAXPLAYERS]"

  # Name graphics of each level (centered)


  #
  # CODE
  #

  fun wi_slam_background = WI_slamBackground

  fun wi_draw_lf = WI_drawLF
  fun wi_draw_el = WI_drawEL
  fun wi_draw_on_lnode = WI_drawOnLnode(n : LibC::Int, c : Patch**)
  fun wi_init_animated_back = WI_initAnimatedBack
  fun wi_update_animated_back = WI_updateAnimatedBack
  fun wi_draw_animated_back = WI_drawAnimatedBack

  fun wi_draw_num = WI_drawNum(x : LibC::Int, y : LibC::Int, n : LibC::Int, digits : LibC::Int) : LibC::Int
  fun wi_draw_percent = WI_drawPercent(x : LibC::Int, y : LibC::Int, p : LibC::Int)
  fun wi_draw_time = WI_drawTime(x : LibC::Int, y : LibC::Int, t : LibC::Int)
  fun wi_unload_data = WI_unloadData
  fun wi_end = WI_End

  fun wi_init_no_state = WI_initNoState
  fun wi_update_no_state = WI_updateNoState
  fun wi_init_show_next_loc = WI_initShowNextLoc
  fun wi_update_show_next_loc = WI_updateShowNextLoc
  fun wi_draw_show_next_loc = WI_drawShowNextLoc
  fun wi_draw_no_state = WI_drawNoState
  fun wi_frag_sum = WI_fragSum(playernum : LibC::Int) : LibC::Int
  fun wi_init_deathmatch_stats = WI_initDeathmatchStats
  fun wi_update_deathmatch_stats = WI_updateDeathmatchStats
  fun wi_draw_deathmatch_stats = WI_drawDeathmatchStats
  fun wi_init_netgame_stats = WI_initNetgameStats
  fun wi_update_netgame_stats = WI_updateNetgameStats
  fun wi_draw_netgame_stats = WI_drawNetgameStats
  fun wi_init_stats = WI_initStats
  fun wi_update_stats = WI_updateStats
  fun wi_draw_stats = WI_drawStats
  fun wi_check_for_accelerate = WI_checkForAccelerate
  fun wi_load_data = WI_loadData
  ZONEID      = 0x1d4a11
  MINFRAGMENT =       64
  MEM_ALIGN   = sizeof(Void*)

  struct Memzone
    # total bytes malloced, including header
    size : LibC::Int

    # start / end cap for linked list
    blocklist : Memblock

    rover : Memblock*
  end


  fun z_clear_zone = Z_ClearZone(zone : Memzone*)
end
