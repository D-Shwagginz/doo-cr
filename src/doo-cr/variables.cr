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
# ==> Most "global" variables and constants
#
# Essentially the "Header" file for doo-cr

module LibDoom
  PI = 3.141592657

  FRACBITS = 16
  FRACUNIT = (1 << FRACBITS)

  FINEANGLES       = 8192
  FINEMASK         = (FINEANGLES - 1)
  FINETANGENT_SIZE = FINEANGLES//2
  FINESINE_SIZE    = 5 * FINEANGLES//4

  SLOPERANGE = 2048
  SLOPEBITS  =   11
  DBITS      = (FRACBITS - SLOPEBITS)

  TANTOANGLE_SIZE = SLOPERANGE + 1

  # Binary Angle Measument, BAM.
  ANG45  = 0x20000000
  ANG90  = 0x40000000
  ANG180 = 0x80000000
  ANG270 = 0xc0000000

  NEEDS_BYTE_SWAP = IO::ByteFormat::SystemEndian != IO::ByteFormat::NetworkEndian

  MENU_SCROLL_DEADZONE = 80

  CDoom.precache = 1

  class_getter keystates = Array(Bool).new(CDoom::NUMKEYS, false)

  @@st_notify : CDoom::Event = CDoom::Event.new
  @@lastlevel = -1
  @@lastepisode = -1
  @@cheatstate = 0
  @@bigstate = 0
  @@buffer : UInt8* = Pointer(UInt8).malloc(20)
  @@nexttic = 0
  @@litelevels : StaticArray(Int32, 8) = StaticArray[0, 4, 7, 10, 12, 14, 15, 15]
  @@litelevelscnt = 0

  NCMD_EXIT       = 0x80000000
  NCMD_RETRANSMIT = 0x40000000
  NCMD_SETUP      = 0x20000000
  NCMD_KILL       = 0x10000000 # kill game
  NCMD_CONNECT    = 0x08000000
  NCMD_DISTRIBUTE = 0x04000000
  NCMD_CHECKSUM   = 0x03ffffff

  RESENDCOUNT =   10
  PL_DRONE    = 0x80        # bit flag in doomdata->player
  @@doomport : Int32 = 5029 # CDoom::IPPORT_USERRESERVED + 0x1d

  @@insocket : UDPSocket? = nil
  @@sendsocket : UDPSocket? = nil
  @@sendaddress = Array(Socket::IPAddress?).new(CDoom::MAXNETNODES, nil)
  @@recv_channel = Channel(Tuple(CDoom::Doomdata, Int32, Socket::IPAddress)).new(CDoom::MAXEVENTS)

  @@netget : Proc(Nil) = -> { nil }
  @@netsend : Proc(Nil) = -> { nil }

  @@closing = false

  @@software_rendering : Bool = true

  @@screen_texture : Raylib::Texture?
  @@viewport_target : Raylib::RenderTexture?
  @@render_target : Raylib::RenderTexture?

  @@software_screen = Bytes.new(CDoom::SCREENWIDTH * CDoom::SCREENHEIGHT)

  @@audio_stream : RAudio::AudioStream?
  @@adl_player : ADLMIDI::Player*?
  @@music_stream : RAudio::AudioStream?
  @@last_time = 0
  @@music_buffer = Pointer(Int16).null
  @@midi_tick_accumulator = 0.0

  @@switch_origins : Array(CDoom::Degenmobj) = [] of CDoom::Degenmobj

  CDoom.screen_buffer = Pointer(UInt8).null
  CDoom.final_screen_buffer = Pointer(UInt8).null
  CDoom.last_update_time = 0
  CDoom.button_states = StaticArray(Int32, 3).new(0)

  CDoom.doom_malloc = CDoom::DoomMallocFn.new(Pointer(Void).null, Pointer(Void).null)
  CDoom.doom_free = CDoom::DoomFreeFn.new(Pointer(Void).null, Pointer(Void).null)
  CDoom.doom_open = CDoom::DoomOpenFn.new(Pointer(Void).null, Pointer(Void).null)
  CDoom.doom_close = CDoom::DoomCloseFn.new(Pointer(Void).null, Pointer(Void).null)
  CDoom.doom_read = CDoom::DoomReadFn.new(Pointer(Void).null, Pointer(Void).null)
  CDoom.doom_write = CDoom::DoomWriteFn.new(Pointer(Void).null, Pointer(Void).null)
  CDoom.doom_seek = CDoom::DoomSeekFn.new(Pointer(Void).null, Pointer(Void).null)
  CDoom.doom_tell = CDoom::DoomTellFn.new(Pointer(Void).null, Pointer(Void).null)
  CDoom.doom_eof = CDoom::DoomEofFn.new(Pointer(Void).null, Pointer(Void).null)
  CDoom.doom_gettime = CDoom::DoomGettimeFn.new(Pointer(Void).null, Pointer(Void).null)
  CDoom.doom_exit = CDoom::DoomExitFn.new(Pointer(Void).null, Pointer(Void).null)
  CDoom.doom_getenv = CDoom::DoomGetenvFn.new(Pointer(Void).null, Pointer(Void).null)

  CDoom.player_arrow[0] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R + CDoom::R // 8, y: 0), b: CDoom::Mpoint.new(x: CDoom::R, y: 0)) # -----
  CDoom.player_arrow[1] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: CDoom::R, y: 0), b: CDoom::Mpoint.new(x: CDoom::R - CDoom::R // 2, y: CDoom::R // 4)) # ----->
  CDoom.player_arrow[2] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: CDoom::R, y: 0), b: CDoom::Mpoint.new(x: CDoom::R - CDoom::R // 2, y: -CDoom::R // 4))
  CDoom.player_arrow[3] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R + CDoom::R // 8, y: 0), b: CDoom::Mpoint.new(x: -CDoom::R - CDoom::R // 8, y: CDoom::R // 4)) # >---->
  CDoom.player_arrow[4] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R + CDoom::R // 8, y: 0), b: CDoom::Mpoint.new(x: -CDoom::R - CDoom::R // 8, y: -CDoom::R // 4))
  CDoom.player_arrow[5] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R + 3 * CDoom::R // 8, y: 0), b: CDoom::Mpoint.new(x: -CDoom::R + CDoom::R // 8, y: CDoom::R // 4)) # >>--->
  CDoom.player_arrow[6] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R + 3 * CDoom::R // 8, y: 0), b: CDoom::Mpoint.new(x: -CDoom::R + CDoom::R // 8, y: -CDoom::R // 4))

  CDoom.cheat_player_arrow[0] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R + CDoom::R // 8, y: 0), b: CDoom::Mpoint.new(x: CDoom::R, y: 0)) # -----
  CDoom.cheat_player_arrow[1] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: CDoom::R, y: 0), b: CDoom::Mpoint.new(x: CDoom::R - CDoom::R // 2, y: CDoom::R // 6)) # ----->
  CDoom.cheat_player_arrow[2] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: CDoom::R, y: 0), b: CDoom::Mpoint.new(x: CDoom::R - CDoom::R // 2, y: -CDoom::R // 6))
  CDoom.cheat_player_arrow[3] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R + CDoom::R // 8, y: 0), b: CDoom::Mpoint.new(x: -CDoom::R - CDoom::R // 8, y: CDoom::R // 6)) # >----->
  CDoom.cheat_player_arrow[4] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R + CDoom::R // 8, y: 0), b: CDoom::Mpoint.new(x: -CDoom::R - CDoom::R // 8, y: -CDoom::R // 6))
  CDoom.cheat_player_arrow[5] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R + 3 * CDoom::R // 8, y: 0), b: CDoom::Mpoint.new(x: -CDoom::R + CDoom::R // 8, y: CDoom::R // 6)) # >>----->
  CDoom.cheat_player_arrow[6] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R + 3 * CDoom::R // 8, y: 0), b: CDoom::Mpoint.new(x: -CDoom::R + CDoom::R // 8, y: -CDoom::R // 6))
  CDoom.cheat_player_arrow[7] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R // 2, y: 0), b: CDoom::Mpoint.new(x: -CDoom::R // 2, y: -CDoom::R // 6)) # >>-d--->
  CDoom.cheat_player_arrow[8] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R // 2, y: -CDoom::R // 6), b: CDoom::Mpoint.new(x: -CDoom::R // 2 + CDoom::R // 6, y: -CDoom::R // 6))
  CDoom.cheat_player_arrow[9] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R // 2 + CDoom::R // 6, y: -CDoom::R // 6), b: CDoom::Mpoint.new(x: -CDoom::R // 2 + CDoom::R // 6, y: CDoom::R // 4))
  CDoom.cheat_player_arrow[10] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R // 6, y: 0), b: CDoom::Mpoint.new(x: -CDoom::R // 6, y: -CDoom::R // 6)) # >>-dd-->
  CDoom.cheat_player_arrow[11] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R // 6, y: -CDoom::R // 6), b: CDoom::Mpoint.new(x: 0, y: -CDoom::R // 6))
  CDoom.cheat_player_arrow[12] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: 0, y: -CDoom::R // 6), b: CDoom::Mpoint.new(x: 0, y: CDoom::R // 4))
  CDoom.cheat_player_arrow[13] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: CDoom::R // 6, y: CDoom::R // 4), b: CDoom::Mpoint.new(x: CDoom::R // 6, y: -CDoom::R // 7)) # >>-ddt->
  CDoom.cheat_player_arrow[14] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: CDoom::R // 6, y: -CDoom::R // 7), b: CDoom::Mpoint.new(x: CDoom::R // 6 + CDoom::R // 32, y: -CDoom::R // 7 - CDoom::R // 32))
  CDoom.cheat_player_arrow[15] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: CDoom::R // 6 + CDoom::R // 32, y: -CDoom::R // 7 - CDoom::R // 32), b: CDoom::Mpoint.new(x: CDoom::R // 6 + CDoom::R // 10, y: -CDoom::R // 7))

  CDoom.triangle_guy[0] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: (-0.867 * FRACUNIT).to_i32!, y: (-0.5 * FRACUNIT).to_i32!), b: CDoom::Mpoint.new(x: (0.867 * FRACUNIT).to_i32!, y: (-0.5 * FRACUNIT).to_i32!))
  CDoom.triangle_guy[1] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: (0.867 * FRACUNIT).to_i32!, y: (-0.5 * FRACUNIT).to_i32!), b: CDoom::Mpoint.new(x: 0, y: FRACUNIT))
  CDoom.triangle_guy[2] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: 0, y: FRACUNIT), b: CDoom::Mpoint.new(x: (-0.867 * FRACUNIT).to_i32!, y: (-0.5 * FRACUNIT).to_i32!))

  CDoom.thintriangle_guy[0] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: (-0.5 * FRACUNIT).to_i32!, y: (-0.7 * FRACUNIT).to_i32!), b: CDoom::Mpoint.new(x: FRACUNIT, y: 0))
  CDoom.thintriangle_guy[1] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: FRACUNIT, y: 0), b: CDoom::Mpoint.new(x: (-0.5 * FRACUNIT).to_i32!, y: (0.7 * FRACUNIT).to_i32!))
  CDoom.thintriangle_guy[2] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: (-0.5 * FRACUNIT).to_i32!, y: (0.7 * FRACUNIT).to_i32!), b: CDoom::Mpoint.new(x: (-0.5 * FRACUNIT).to_i32, y: (-0.7 * FRACUNIT).to_i32!))

  CDoom.cheating = 0
  CDoom.grid = 0

  CDoom.leveljuststarted = 1

  CDoom.finit_width = CDoom::SCREENWIDTH
  CDoom.finit_height = CDoom::SCREENHEIGHT - 32

  CDoom.scale_mtof = CDoom::INITSCALEMTOF.to_i32!

  CDoom.markpointnum = 0

  CDoom.followplayer = 1

  @@died_strings = [
    "1 has died",
    "something got 1",
    "1 has been slain",
    "1 will be missed",
  ]

  @@suic_strings = [
    "You have taken your own life!",
    "You will be missed",
    "Due to a rocket no doubt",
    "Good thing you can respawn!",
  ]

  @@suic_see_strings = [
    "1 killed themselves",
    "1 has blown themselves up",
    "1 couldn't take it anymore",
    "who killed 1?",
  ]

  @@death_kill_strings = [
    "You killed 2",
    "You got 2",
    "You showed 2",
    "You fragged 2",
  ]
  @@death_dead_strings = [
    "1 killed you",
    "You have been taken by 1",
    "You got smoked by 1",
    "1 fragged you",
  ]
  @@death_nut_strings = [
    "1 killed 2",
    "1 has claimed 2's soul",
    "2 just got pwned by 1",
    "2 has been fragged by 1",
  ]

  @@net_kill_strings = [
    "You killed 2",
    "2 will remember that...",
    "2 hopes that was an accident",
  ]
  @@net_dead_strings = [
    "You were killed by 1",
    "I bet 1 did that on purpose",
    "1 thought this was deathmatch",
  ]
  @@net_nut_strings = [
    "1 killed 2",
    "1 showed 2 what for",
    "2 has been slain by 1",
    "1 and 2 have a new rivalry",
  ]

  c_array(CDoom.cheat_amap_seq,
    0xb2, 0x26, 0x26, 0x2e, 0xff
  )
  CDoom.cheat_amap.sequence = CDoom.cheat_amap_seq.to_unsafe.as(UInt8*)
  CDoom.cheat_amap.p = Pointer(UInt8).null

  CDoom.stopped = 1

  CDoom.automapactive = 0

  CDoom.weaponinfo[0] = CDoom::Weaponinfo.new(
    # fist
    ammo: CDoom::Ammotype::Noammo,
    upstate: CDoom::Statenum::S_PUNCHUP,
    downstate: CDoom::Statenum::S_PUNCHDOWN,
    readystate: CDoom::Statenum::S_PUNCH,
    atkstate: CDoom::Statenum::S_PUNCH1,
    flashstate: CDoom::Statenum::S_NULL
  )
  CDoom.weaponinfo[1] = CDoom::Weaponinfo.new(
    # pistol
    ammo: CDoom::Ammotype::Clip,
    upstate: CDoom::Statenum::S_PISTOLUP,
    downstate: CDoom::Statenum::S_PISTOLDOWN,
    readystate: CDoom::Statenum::S_PISTOL,
    atkstate: CDoom::Statenum::S_PISTOL1,
    flashstate: CDoom::Statenum::S_PISTOLFLASH
  )
  CDoom.weaponinfo[2] = CDoom::Weaponinfo.new(
    # shotgun
    ammo: CDoom::Ammotype::Shell,
    upstate: CDoom::Statenum::S_SGUNUP,
    downstate: CDoom::Statenum::S_SGUNDOWN,
    readystate: CDoom::Statenum::S_SGUN,
    atkstate: CDoom::Statenum::S_SGUN1,
    flashstate: CDoom::Statenum::S_SGUNFLASH1
  )
  CDoom.weaponinfo[3] = CDoom::Weaponinfo.new(
    # chaingun
    ammo: CDoom::Ammotype::Clip,
    upstate: CDoom::Statenum::S_CHAINUP,
    downstate: CDoom::Statenum::S_CHAINDOWN,
    readystate: CDoom::Statenum::S_CHAIN,
    atkstate: CDoom::Statenum::S_CHAIN1,
    flashstate: CDoom::Statenum::S_CHAINFLASH1
  )
  CDoom.weaponinfo[4] = CDoom::Weaponinfo.new(
    # missile launcher
    ammo: CDoom::Ammotype::Misl,
    upstate: CDoom::Statenum::S_MISSILEUP,
    downstate: CDoom::Statenum::S_MISSILEDOWN,
    readystate: CDoom::Statenum::S_MISSILE,
    atkstate: CDoom::Statenum::S_MISSILE1,
    flashstate: CDoom::Statenum::S_MISSILEFLASH1
  )
  CDoom.weaponinfo[5] = CDoom::Weaponinfo.new(
    # plasma rifle
    ammo: CDoom::Ammotype::Cell,
    upstate: CDoom::Statenum::S_PLASMAUP,
    downstate: CDoom::Statenum::S_PLASMADOWN,
    readystate: CDoom::Statenum::S_PLASMA,
    atkstate: CDoom::Statenum::S_PLASMA1,
    flashstate: CDoom::Statenum::S_PLASMAFLASH1
  )
  CDoom.weaponinfo[6] = CDoom::Weaponinfo.new(
    # bfg 9000
    ammo: CDoom::Ammotype::Cell,
    upstate: CDoom::Statenum::S_BFGUP,
    downstate: CDoom::Statenum::S_BFGDOWN,
    readystate: CDoom::Statenum::S_BFG,
    atkstate: CDoom::Statenum::S_BFG1,
    flashstate: CDoom::Statenum::S_BFGFLASH1
  )
  CDoom.weaponinfo[7] = CDoom::Weaponinfo.new(
    # chainsaw
    ammo: CDoom::Ammotype::Noammo,
    upstate: CDoom::Statenum::S_SAWUP,
    downstate: CDoom::Statenum::S_SAWDOWN,
    readystate: CDoom::Statenum::S_SAW,
    atkstate: CDoom::Statenum::S_SAW1,
    flashstate: CDoom::Statenum::S_NULL
  )
  CDoom.weaponinfo[8] = CDoom::Weaponinfo.new(
    # fist
    ammo: CDoom::Ammotype::Shell,
    upstate: CDoom::Statenum::S_DSGUNUP,
    downstate: CDoom::Statenum::S_DSGUNDOWN,
    readystate: CDoom::Statenum::S_DSGUN,
    atkstate: CDoom::Statenum::S_DSGUN1,
    flashstate: CDoom::Statenum::S_DSGUNFLASH1
  )

  CDoom.singletics = 0

  CDoom.is_wiping_screen = 0

  CDoom.debugfile = Pointer(Void).null

  CDoom.wipegamestate = CDoom::Gamestate::Demoscreen

  CDoom.forwardmove[0] = 0x19
  CDoom.forwardmove[1] = 0x32
  CDoom.sidemove[0] = 0x18
  CDoom.sidemove[1] = 0x28
  CDoom.angleturn[0] = 640
  CDoom.angleturn[1] = 1280
  CDoom.angleturn[2] = 320

  CDoom.gamemode = CDoom::GameMode::Indetermined
  CDoom.gamemission = CDoom::GameMission::Doom

  # Language.
  CDoom.language = CDoom::Language::English

  # Set if homebrew PWAD stuff has been added.
  CDoom.modifiedgame
  # DOOM1
  CDoom.doom1_endmsg[0] = CDoom::QUITMSG.to_unsafe
  CDoom.doom1_endmsg[1] = "please don't leave, there's more\ndemons to toast!".to_unsafe
  CDoom.doom1_endmsg[2] = "let's beat it -- this is turning\ninto a bloodbath!".to_unsafe
  CDoom.doom1_endmsg[3] = "i wouldn't leave if i were you.\ndos is much worse.".to_unsafe
  CDoom.doom1_endmsg[4] = "you're trying to say you like dos\nbetter than me, right?".to_unsafe
  CDoom.doom1_endmsg[5] = "don't leave yet -- there's a\ndemon around that corner!".to_unsafe
  CDoom.doom1_endmsg[6] = "ya know, next time you come in here\ni'm gonna toast ya.".to_unsafe
  CDoom.doom1_endmsg[7] = "go ahead and leave. see if i care.".to_unsafe

  # QuitDOOM II messages
  CDoom.doom2_endmsg[0] = CDoom::QUITMSG.to_unsafe
  CDoom.doom2_endmsg[1] = "you want to quit?\nthen, thou hast lost an eighth!".to_unsafe
  CDoom.doom2_endmsg[2] = "don't go now, there's a \ndimensional shambler waiting\nat the dos prompt!".to_unsafe
  CDoom.doom2_endmsg[3] = "get outta here and go back\nto your boring programs.".to_unsafe
  CDoom.doom2_endmsg[4] = "if i were your boss, i'd \n deathmatch ya in a minute!".to_unsafe
  CDoom.doom2_endmsg[5] = "look, bud. you leave now\nand you forfeit your body count!".to_unsafe
  CDoom.doom2_endmsg[6] = "just leave. when you come\nback, i'll be waiting with a bat.".to_unsafe
  CDoom.doom2_endmsg[7] = "you're lucky i don't smack\nyou for thinking about leaving.".to_unsafe

  # Stage of animation:
  #  0 = text, 1 = art screen, 2 = character cast
  # CDoom.finalstage

  CDoom.e1text = CDoom::E1TEXT
  CDoom.e2text = CDoom::E2TEXT
  CDoom.e3text = CDoom::E3TEXT
  CDoom.e4text = CDoom::E4TEXT

  CDoom.c1text = CDoom::C1TEXT
  CDoom.c2text = CDoom::C2TEXT
  CDoom.c3text = CDoom::C3TEXT
  CDoom.c4text = CDoom::C4TEXT
  CDoom.c5text = CDoom::C5TEXT
  CDoom.c6text = CDoom::C6TEXT

  CDoom.p1text = CDoom::P1TEXT
  CDoom.p2text = CDoom::P2TEXT
  CDoom.p3text = CDoom::P3TEXT
  CDoom.p4text = CDoom::P4TEXT
  CDoom.p5text = CDoom::P5TEXT
  CDoom.p6text = CDoom::P6TEXT

  CDoom.t1text = CDoom::T1TEXT
  CDoom.t2text = CDoom::T2TEXT
  CDoom.t3text = CDoom::T3TEXT
  CDoom.t4text = CDoom::T4TEXT
  CDoom.t5text = CDoom::T5TEXT
  CDoom.t6text = CDoom::T6TEXT

  CDoom.castorder[0] = CDoom::Castinfo.new(name: CDoom::CC_ZOMBIE, type: CDoom::Mobjtype::MT_POSSESSED)
  CDoom.castorder[1] = CDoom::Castinfo.new(name: CDoom::CC_SHOTGUN, type: CDoom::Mobjtype::MT_SHOTGUY)
  CDoom.castorder[2] = CDoom::Castinfo.new(name: CDoom::CC_HEAVY, type: CDoom::Mobjtype::MT_CHAINGUY)
  CDoom.castorder[3] = CDoom::Castinfo.new(name: CDoom::CC_IMP, type: CDoom::Mobjtype::MT_TROOP)
  CDoom.castorder[4] = CDoom::Castinfo.new(name: CDoom::CC_DEMON, type: CDoom::Mobjtype::MT_SERGEANT)
  CDoom.castorder[5] = CDoom::Castinfo.new(name: CDoom::CC_LOST, type: CDoom::Mobjtype::MT_SKULL)
  CDoom.castorder[6] = CDoom::Castinfo.new(name: CDoom::CC_CACO, type: CDoom::Mobjtype::MT_HEAD)
  CDoom.castorder[7] = CDoom::Castinfo.new(name: CDoom::CC_HELL, type: CDoom::Mobjtype::MT_KNIGHT)
  CDoom.castorder[8] = CDoom::Castinfo.new(name: CDoom::CC_BARON, type: CDoom::Mobjtype::MT_BRUISER)
  CDoom.castorder[9] = CDoom::Castinfo.new(name: CDoom::CC_ARACH, type: CDoom::Mobjtype::MT_BABY)
  CDoom.castorder[10] = CDoom::Castinfo.new(name: CDoom::CC_PAIN, type: CDoom::Mobjtype::MT_PAIN)
  CDoom.castorder[11] = CDoom::Castinfo.new(name: CDoom::CC_REVEN, type: CDoom::Mobjtype::MT_UNDEAD)
  CDoom.castorder[12] = CDoom::Castinfo.new(name: CDoom::CC_MANCU, type: CDoom::Mobjtype::MT_FATSO)
  CDoom.castorder[13] = CDoom::Castinfo.new(name: CDoom::CC_ARCH, type: CDoom::Mobjtype::MT_VILE)
  CDoom.castorder[14] = CDoom::Castinfo.new(name: CDoom::CC_SPIDER, type: CDoom::Mobjtype::MT_SPIDER)
  CDoom.castorder[15] = CDoom::Castinfo.new(name: CDoom::CC_CYBER, type: CDoom::Mobjtype::MT_CYBORG)
  CDoom.castorder[16] = CDoom::Castinfo.new(name: CDoom::CC_HERO, type: CDoom::Mobjtype::MT_PLAYER)

  CDoom.castorder[17] = CDoom::Castinfo.new

  CDoom.go = 0

  CDoom.mousebuttons = CDoom.mousearray.to_unsafe + 1

  CDoom.joybuttons = CDoom.joyarray.to_unsafe + 1

  # DOOM Par Times
  c_array((CDoom.pars.to_unsafe).value,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  )
  c_array((CDoom.pars.to_unsafe + 1).value,
    0, 30, 75, 120, 90, 165, 180, 180, 30, 165
  )
  c_array((CDoom.pars.to_unsafe + 2).value,
    0, 90, 90, 90, 120, 90, 360, 240, 30, 170
  )
  c_array((CDoom.pars.to_unsafe + 3).value,
    0, 90, 45, 90, 150, 90, 90, 165, 30, 135
  )

  c_array(CDoom.cpars,
    30, 90, 120, 120, 90, 150, 120, 120, 270, 90,     #  1-10
    210, 150, 150, 150, 210, 150, 420, 150, 210, 150, # 11-20
    240, 150, 180, 150, 150, 300, 330, 420, 300, 180, # 21-30
    120, 30                                           # 31-32
  )

  CDoom.always_off = 0
  CDoom.headsupactive = 0
  CDoom.head = 0
  CDoom.tail = 0

  CDoom.chat_macros[0] = CDoom::HUSTR_CHATMACRO0.to_unsafe
  CDoom.chat_macros[1] = CDoom::HUSTR_CHATMACRO1.to_unsafe
  CDoom.chat_macros[2] = CDoom::HUSTR_CHATMACRO2.to_unsafe
  CDoom.chat_macros[3] = CDoom::HUSTR_CHATMACRO3.to_unsafe
  CDoom.chat_macros[4] = CDoom::HUSTR_CHATMACRO4.to_unsafe
  CDoom.chat_macros[5] = CDoom::HUSTR_CHATMACRO5.to_unsafe
  CDoom.chat_macros[6] = CDoom::HUSTR_CHATMACRO6.to_unsafe
  CDoom.chat_macros[7] = CDoom::HUSTR_CHATMACRO7.to_unsafe
  CDoom.chat_macros[8] = CDoom::HUSTR_CHATMACRO8.to_unsafe
  CDoom.chat_macros[9] = CDoom::HUSTR_CHATMACRO9.to_unsafe

  c_array(CDoom.player_names,
    CDoom::HUSTR_PLRGREEN.to_unsafe,
    CDoom::HUSTR_PLRINDIGO.to_unsafe,
    CDoom::HUSTR_PLRBROWN.to_unsafe,
    CDoom::HUSTR_PLRRED.to_unsafe)

  CDoom.french_shiftxform[0] = 0_u8
  CDoom.french_shiftxform[1] = 1
  CDoom.french_shiftxform[2] = 2
  CDoom.french_shiftxform[3] = 3
  CDoom.french_shiftxform[4] = 4
  CDoom.french_shiftxform[5] = 5
  CDoom.french_shiftxform[6] = 6
  CDoom.french_shiftxform[7] = 7
  CDoom.french_shiftxform[8] = 8
  CDoom.french_shiftxform[9] = 9
  CDoom.french_shiftxform[10] = 10
  CDoom.french_shiftxform[11] = 11
  CDoom.french_shiftxform[12] = 12
  CDoom.french_shiftxform[13] = 13
  CDoom.french_shiftxform[14] = 14
  CDoom.french_shiftxform[15] = 15
  CDoom.french_shiftxform[16] = 16
  CDoom.french_shiftxform[17] = 17
  CDoom.french_shiftxform[18] = 18
  CDoom.french_shiftxform[19] = 19
  CDoom.french_shiftxform[20] = 20
  CDoom.french_shiftxform[21] = 21
  CDoom.french_shiftxform[22] = 22
  CDoom.french_shiftxform[23] = 23
  CDoom.french_shiftxform[24] = 24
  CDoom.french_shiftxform[25] = 25
  CDoom.french_shiftxform[26] = 26
  CDoom.french_shiftxform[27] = 27
  CDoom.french_shiftxform[28] = 28
  CDoom.french_shiftxform[29] = 29
  CDoom.french_shiftxform[30] = 30
  CDoom.french_shiftxform[31] = 31
  CDoom.french_shiftxform[32] = ' '.ord.to_u8
  CDoom.french_shiftxform[33] = '!'.ord.to_u8
  CDoom.french_shiftxform[34] = '"'.ord.to_u8
  CDoom.french_shiftxform[35] = '#'.ord.to_u8
  CDoom.french_shiftxform[36] = '$'.ord.to_u8
  CDoom.french_shiftxform[37] = '%'.ord.to_u8
  CDoom.french_shiftxform[38] = '&'.ord.to_u8
  CDoom.french_shiftxform[39] = '"'.ord.to_u8
  CDoom.french_shiftxform[40] = '('.ord.to_u8
  CDoom.french_shiftxform[41] = ')'.ord.to_u8
  CDoom.french_shiftxform[42] = '*'.ord.to_u8
  CDoom.french_shiftxform[43] = '+'.ord.to_u8
  CDoom.french_shiftxform[44] = '?'.ord.to_u8
  CDoom.french_shiftxform[45] = '_'.ord.to_u8
  CDoom.french_shiftxform[46] = '>'.ord.to_u8
  CDoom.french_shiftxform[47] = '?'.ord.to_u8
  CDoom.french_shiftxform[48] = '0'.ord.to_u8
  CDoom.french_shiftxform[49] = '1'.ord.to_u8
  CDoom.french_shiftxform[50] = '2'.ord.to_u8
  CDoom.french_shiftxform[51] = '3'.ord.to_u8
  CDoom.french_shiftxform[52] = '4'.ord.to_u8
  CDoom.french_shiftxform[53] = '5'.ord.to_u8
  CDoom.french_shiftxform[54] = '6'.ord.to_u8
  CDoom.french_shiftxform[55] = '7'.ord.to_u8
  CDoom.french_shiftxform[56] = '8'.ord.to_u8
  CDoom.french_shiftxform[57] = '9'.ord.to_u8
  CDoom.french_shiftxform[58] = '/'.ord.to_u8
  CDoom.french_shiftxform[59] = '.'.ord.to_u8
  CDoom.french_shiftxform[60] = '<'.ord.to_u8
  CDoom.french_shiftxform[61] = '+'.ord.to_u8
  CDoom.french_shiftxform[62] = '>'.ord.to_u8
  CDoom.french_shiftxform[63] = '?'.ord.to_u8
  CDoom.french_shiftxform[64] = '@'.ord.to_u8
  CDoom.french_shiftxform[65] = 'A'.ord.to_u8
  CDoom.french_shiftxform[66] = 'B'.ord.to_u8
  CDoom.french_shiftxform[67] = 'C'.ord.to_u8
  CDoom.french_shiftxform[68] = 'D'.ord.to_u8
  CDoom.french_shiftxform[69] = 'E'.ord.to_u8
  CDoom.french_shiftxform[70] = 'F'.ord.to_u8
  CDoom.french_shiftxform[71] = 'G'.ord.to_u8
  CDoom.french_shiftxform[72] = 'H'.ord.to_u8
  CDoom.french_shiftxform[73] = 'I'.ord.to_u8
  CDoom.french_shiftxform[74] = 'J'.ord.to_u8
  CDoom.french_shiftxform[75] = 'K'.ord.to_u8
  CDoom.french_shiftxform[76] = 'L'.ord.to_u8
  CDoom.french_shiftxform[77] = 'M'.ord.to_u8
  CDoom.french_shiftxform[78] = 'N'.ord.to_u8
  CDoom.french_shiftxform[79] = 'O'.ord.to_u8
  CDoom.french_shiftxform[80] = 'P'.ord.to_u8
  CDoom.french_shiftxform[81] = 'Q'.ord.to_u8
  CDoom.french_shiftxform[82] = 'R'.ord.to_u8
  CDoom.french_shiftxform[83] = 'S'.ord.to_u8
  CDoom.french_shiftxform[84] = 'T'.ord.to_u8
  CDoom.french_shiftxform[85] = 'U'.ord.to_u8
  CDoom.french_shiftxform[86] = 'V'.ord.to_u8
  CDoom.french_shiftxform[87] = 'W'.ord.to_u8
  CDoom.french_shiftxform[88] = 'X'.ord.to_u8
  CDoom.french_shiftxform[89] = 'Y'.ord.to_u8
  CDoom.french_shiftxform[90] = 'Z'.ord.to_u8
  CDoom.french_shiftxform[91] = '['.ord.to_u8
  CDoom.french_shiftxform[92] = '!'.ord.to_u8
  CDoom.french_shiftxform[93] = ']'.ord.to_u8
  CDoom.french_shiftxform[94] = '"'.ord.to_u8
  CDoom.french_shiftxform[95] = '_'.ord.to_u8
  CDoom.french_shiftxform[96] = '\''.ord.to_u8
  CDoom.french_shiftxform[97] = 'A'.ord.to_u8
  CDoom.french_shiftxform[98] = 'B'.ord.to_u8
  CDoom.french_shiftxform[99] = 'C'.ord.to_u8
  CDoom.french_shiftxform[100] = 'D'.ord.to_u8
  CDoom.french_shiftxform[101] = 'E'.ord.to_u8
  CDoom.french_shiftxform[102] = 'F'.ord.to_u8
  CDoom.french_shiftxform[103] = 'G'.ord.to_u8
  CDoom.french_shiftxform[104] = 'H'.ord.to_u8
  CDoom.french_shiftxform[105] = 'I'.ord.to_u8
  CDoom.french_shiftxform[106] = 'J'.ord.to_u8
  CDoom.french_shiftxform[107] = 'K'.ord.to_u8
  CDoom.french_shiftxform[108] = 'L'.ord.to_u8
  CDoom.french_shiftxform[109] = 'M'.ord.to_u8
  CDoom.french_shiftxform[110] = 'N'.ord.to_u8
  CDoom.french_shiftxform[111] = 'O'.ord.to_u8
  CDoom.french_shiftxform[112] = 'P'.ord.to_u8
  CDoom.french_shiftxform[113] = 'Q'.ord.to_u8
  CDoom.french_shiftxform[114] = 'R'.ord.to_u8
  CDoom.french_shiftxform[115] = 'S'.ord.to_u8
  CDoom.french_shiftxform[116] = 'T'.ord.to_u8
  CDoom.french_shiftxform[117] = 'U'.ord.to_u8
  CDoom.french_shiftxform[118] = 'V'.ord.to_u8
  CDoom.french_shiftxform[119] = 'W'.ord.to_u8
  CDoom.french_shiftxform[120] = 'X'.ord.to_u8
  CDoom.french_shiftxform[121] = 'Y'.ord.to_u8
  CDoom.french_shiftxform[122] = 'Z'.ord.to_u8
  CDoom.french_shiftxform[123] = '{'.ord.to_u8
  CDoom.french_shiftxform[124] = '|'.ord.to_u8
  CDoom.french_shiftxform[125] = '}'.ord.to_u8
  CDoom.french_shiftxform[126] = '~'.ord.to_u8
  CDoom.french_shiftxform[127] = 127

  CDoom.english_shiftxform[0] = 0
  CDoom.english_shiftxform[1] = 1
  CDoom.english_shiftxform[2] = 2
  CDoom.english_shiftxform[3] = 3
  CDoom.english_shiftxform[4] = 4
  CDoom.english_shiftxform[5] = 5
  CDoom.english_shiftxform[6] = 6
  CDoom.english_shiftxform[7] = 7
  CDoom.english_shiftxform[8] = 8
  CDoom.english_shiftxform[9] = 9
  CDoom.english_shiftxform[10] = 10
  CDoom.english_shiftxform[11] = 11
  CDoom.english_shiftxform[12] = 12
  CDoom.english_shiftxform[13] = 13
  CDoom.english_shiftxform[14] = 14
  CDoom.english_shiftxform[15] = 15
  CDoom.english_shiftxform[16] = 16
  CDoom.english_shiftxform[17] = 17
  CDoom.english_shiftxform[18] = 18
  CDoom.english_shiftxform[19] = 19
  CDoom.english_shiftxform[20] = 20
  CDoom.english_shiftxform[21] = 21
  CDoom.english_shiftxform[22] = 22
  CDoom.english_shiftxform[23] = 23
  CDoom.english_shiftxform[24] = 24
  CDoom.english_shiftxform[25] = 25
  CDoom.english_shiftxform[26] = 26
  CDoom.english_shiftxform[27] = 27
  CDoom.english_shiftxform[28] = 28
  CDoom.english_shiftxform[29] = 29
  CDoom.english_shiftxform[30] = 30
  CDoom.english_shiftxform[31] = 31
  CDoom.english_shiftxform[32] = ' '.ord.to_u8
  CDoom.english_shiftxform[33] = '!'.ord.to_u8
  CDoom.english_shiftxform[34] = '"'.ord.to_u8
  CDoom.english_shiftxform[35] = '#'.ord.to_u8
  CDoom.english_shiftxform[36] = '$'.ord.to_u8
  CDoom.english_shiftxform[37] = '%'.ord.to_u8
  CDoom.english_shiftxform[38] = '&'.ord.to_u8
  CDoom.english_shiftxform[39] = '"'.ord.to_u8
  CDoom.english_shiftxform[40] = '('.ord.to_u8
  CDoom.english_shiftxform[41] = ')'.ord.to_u8
  CDoom.english_shiftxform[42] = '*'.ord.to_u8
  CDoom.english_shiftxform[43] = '+'.ord.to_u8
  CDoom.english_shiftxform[44] = '<'.ord.to_u8
  CDoom.english_shiftxform[45] = '_'.ord.to_u8
  CDoom.english_shiftxform[46] = '>'.ord.to_u8
  CDoom.english_shiftxform[47] = '?'.ord.to_u8
  CDoom.english_shiftxform[48] = ')'.ord.to_u8
  CDoom.english_shiftxform[49] = '!'.ord.to_u8
  CDoom.english_shiftxform[50] = '@'.ord.to_u8
  CDoom.english_shiftxform[51] = '#'.ord.to_u8
  CDoom.english_shiftxform[52] = '$'.ord.to_u8
  CDoom.english_shiftxform[53] = '%'.ord.to_u8
  CDoom.english_shiftxform[54] = '^'.ord.to_u8
  CDoom.english_shiftxform[55] = '&'.ord.to_u8
  CDoom.english_shiftxform[56] = '*'.ord.to_u8
  CDoom.english_shiftxform[57] = '('.ord.to_u8
  CDoom.english_shiftxform[58] = ':'.ord.to_u8
  CDoom.english_shiftxform[59] = ':'.ord.to_u8
  CDoom.english_shiftxform[60] = '<'.ord.to_u8
  CDoom.english_shiftxform[61] = '+'.ord.to_u8
  CDoom.english_shiftxform[62] = '>'.ord.to_u8
  CDoom.english_shiftxform[63] = '?'.ord.to_u8
  CDoom.english_shiftxform[64] = '@'.ord.to_u8
  CDoom.english_shiftxform[65] = 'A'.ord.to_u8
  CDoom.english_shiftxform[66] = 'B'.ord.to_u8
  CDoom.english_shiftxform[67] = 'C'.ord.to_u8
  CDoom.english_shiftxform[68] = 'D'.ord.to_u8
  CDoom.english_shiftxform[69] = 'E'.ord.to_u8
  CDoom.english_shiftxform[70] = 'F'.ord.to_u8
  CDoom.english_shiftxform[71] = 'G'.ord.to_u8
  CDoom.english_shiftxform[72] = 'H'.ord.to_u8
  CDoom.english_shiftxform[73] = 'I'.ord.to_u8
  CDoom.english_shiftxform[74] = 'J'.ord.to_u8
  CDoom.english_shiftxform[75] = 'K'.ord.to_u8
  CDoom.english_shiftxform[76] = 'L'.ord.to_u8
  CDoom.english_shiftxform[77] = 'M'.ord.to_u8
  CDoom.english_shiftxform[78] = 'N'.ord.to_u8
  CDoom.english_shiftxform[79] = 'O'.ord.to_u8
  CDoom.english_shiftxform[80] = 'P'.ord.to_u8
  CDoom.english_shiftxform[81] = 'Q'.ord.to_u8
  CDoom.english_shiftxform[82] = 'R'.ord.to_u8
  CDoom.english_shiftxform[83] = 'S'.ord.to_u8
  CDoom.english_shiftxform[84] = 'T'.ord.to_u8
  CDoom.english_shiftxform[85] = 'U'.ord.to_u8
  CDoom.english_shiftxform[86] = 'V'.ord.to_u8
  CDoom.english_shiftxform[87] = 'W'.ord.to_u8
  CDoom.english_shiftxform[88] = 'X'.ord.to_u8
  CDoom.english_shiftxform[89] = 'Y'.ord.to_u8
  CDoom.english_shiftxform[90] = 'Z'.ord.to_u8
  CDoom.english_shiftxform[91] = '['.ord.to_u8
  CDoom.english_shiftxform[92] = '!'.ord.to_u8
  CDoom.english_shiftxform[93] = ']'.ord.to_u8
  CDoom.english_shiftxform[94] = '"'.ord.to_u8
  CDoom.english_shiftxform[95] = '_'.ord.to_u8
  CDoom.english_shiftxform[96] = '\''.ord.to_u8
  CDoom.english_shiftxform[97] = 'A'.ord.to_u8
  CDoom.english_shiftxform[98] = 'B'.ord.to_u8
  CDoom.english_shiftxform[99] = 'C'.ord.to_u8
  CDoom.english_shiftxform[100] = 'D'.ord.to_u8
  CDoom.english_shiftxform[101] = 'E'.ord.to_u8
  CDoom.english_shiftxform[102] = 'F'.ord.to_u8
  CDoom.english_shiftxform[103] = 'G'.ord.to_u8
  CDoom.english_shiftxform[104] = 'H'.ord.to_u8
  CDoom.english_shiftxform[105] = 'I'.ord.to_u8
  CDoom.english_shiftxform[106] = 'J'.ord.to_u8
  CDoom.english_shiftxform[107] = 'K'.ord.to_u8
  CDoom.english_shiftxform[108] = 'L'.ord.to_u8
  CDoom.english_shiftxform[109] = 'M'.ord.to_u8
  CDoom.english_shiftxform[110] = 'N'.ord.to_u8
  CDoom.english_shiftxform[111] = 'O'.ord.to_u8
  CDoom.english_shiftxform[112] = 'P'.ord.to_u8
  CDoom.english_shiftxform[113] = 'Q'.ord.to_u8
  CDoom.english_shiftxform[114] = 'R'.ord.to_u8
  CDoom.english_shiftxform[115] = 'S'.ord.to_u8
  CDoom.english_shiftxform[116] = 'T'.ord.to_u8
  CDoom.english_shiftxform[117] = 'U'.ord.to_u8
  CDoom.english_shiftxform[118] = 'V'.ord.to_u8
  CDoom.english_shiftxform[119] = 'W'.ord.to_u8
  CDoom.english_shiftxform[120] = 'X'.ord.to_u8
  CDoom.english_shiftxform[121] = 'Y'.ord.to_u8
  CDoom.english_shiftxform[122] = 'Z'.ord.to_u8
  CDoom.english_shiftxform[123] = '{'.ord.to_u8
  CDoom.english_shiftxform[124] = '|'.ord.to_u8
  CDoom.english_shiftxform[125] = '}'.ord.to_u8
  CDoom.english_shiftxform[126] = '~'.ord.to_u8
  CDoom.english_shiftxform[127] = 127

  CDoom.french_key_map[0] = 0
  CDoom.french_key_map[1] = 1
  CDoom.french_key_map[2] = 2
  CDoom.french_key_map[3] = 3
  CDoom.french_key_map[4] = 4
  CDoom.french_key_map[5] = 5
  CDoom.french_key_map[6] = 6
  CDoom.french_key_map[7] = 7
  CDoom.french_key_map[8] = 8
  CDoom.french_key_map[9] = 9
  CDoom.french_key_map[10] = 10
  CDoom.french_key_map[11] = 11
  CDoom.french_key_map[12] = 12
  CDoom.french_key_map[13] = 13
  CDoom.french_key_map[14] = 14
  CDoom.french_key_map[15] = 15
  CDoom.french_key_map[16] = 16
  CDoom.french_key_map[17] = 17
  CDoom.french_key_map[18] = 18
  CDoom.french_key_map[19] = 19
  CDoom.french_key_map[20] = 20
  CDoom.french_key_map[21] = 21
  CDoom.french_key_map[22] = 22
  CDoom.french_key_map[23] = 23
  CDoom.french_key_map[24] = 24
  CDoom.french_key_map[25] = 25
  CDoom.french_key_map[26] = 26
  CDoom.french_key_map[27] = 27
  CDoom.french_key_map[28] = 28
  CDoom.french_key_map[29] = 29
  CDoom.french_key_map[30] = 30
  CDoom.french_key_map[31] = 31
  CDoom.french_key_map[32] = ' '.ord.to_u8
  CDoom.french_key_map[33] = '!'.ord.to_u8
  CDoom.french_key_map[34] = '"'.ord.to_u8
  CDoom.french_key_map[35] = '#'.ord.to_u8
  CDoom.french_key_map[36] = '$'.ord.to_u8
  CDoom.french_key_map[37] = '%'.ord.to_u8
  CDoom.french_key_map[38] = '&'.ord.to_u8
  CDoom.french_key_map[39] = '%'.ord.to_u8
  CDoom.french_key_map[40] = '('.ord.to_u8
  CDoom.french_key_map[41] = ')'.ord.to_u8
  CDoom.french_key_map[42] = '*'.ord.to_u8
  CDoom.french_key_map[43] = '+'.ord.to_u8
  CDoom.french_key_map[44] = ';'.ord.to_u8
  CDoom.french_key_map[45] = '-'.ord.to_u8
  CDoom.french_key_map[46] = ':'.ord.to_u8
  CDoom.french_key_map[47] = '!'.ord.to_u8
  CDoom.french_key_map[48] = '0'.ord.to_u8
  CDoom.french_key_map[49] = '1'.ord.to_u8
  CDoom.french_key_map[50] = '2'.ord.to_u8
  CDoom.french_key_map[51] = '3'.ord.to_u8
  CDoom.french_key_map[52] = '4'.ord.to_u8
  CDoom.french_key_map[53] = '5'.ord.to_u8
  CDoom.french_key_map[54] = '6'.ord.to_u8
  CDoom.french_key_map[55] = '7'.ord.to_u8
  CDoom.french_key_map[56] = '8'.ord.to_u8
  CDoom.french_key_map[57] = '9'.ord.to_u8
  CDoom.french_key_map[58] = ':'.ord.to_u8
  CDoom.french_key_map[59] = 'M'.ord.to_u8
  CDoom.french_key_map[60] = '<'.ord.to_u8
  CDoom.french_key_map[61] = '='.ord.to_u8
  CDoom.french_key_map[62] = '>'.ord.to_u8
  CDoom.french_key_map[63] = '?'.ord.to_u8
  CDoom.french_key_map[64] = '@'.ord.to_u8
  CDoom.french_key_map[65] = 'Q'.ord.to_u8
  CDoom.french_key_map[66] = 'B'.ord.to_u8
  CDoom.french_key_map[67] = 'C'.ord.to_u8
  CDoom.french_key_map[68] = 'D'.ord.to_u8
  CDoom.french_key_map[69] = 'E'.ord.to_u8
  CDoom.french_key_map[70] = 'F'.ord.to_u8
  CDoom.french_key_map[71] = 'G'.ord.to_u8
  CDoom.french_key_map[72] = 'H'.ord.to_u8
  CDoom.french_key_map[73] = 'I'.ord.to_u8
  CDoom.french_key_map[74] = 'J'.ord.to_u8
  CDoom.french_key_map[75] = 'K'.ord.to_u8
  CDoom.french_key_map[76] = 'L'.ord.to_u8
  CDoom.french_key_map[77] = ','.ord.to_u8
  CDoom.french_key_map[78] = 'N'.ord.to_u8
  CDoom.french_key_map[79] = 'O'.ord.to_u8
  CDoom.french_key_map[80] = 'P'.ord.to_u8
  CDoom.french_key_map[81] = 'A'.ord.to_u8
  CDoom.french_key_map[82] = 'R'.ord.to_u8
  CDoom.french_key_map[83] = 'S'.ord.to_u8
  CDoom.french_key_map[84] = 'T'.ord.to_u8
  CDoom.french_key_map[85] = 'U'.ord.to_u8
  CDoom.french_key_map[86] = 'V'.ord.to_u8
  CDoom.french_key_map[87] = 'Z'.ord.to_u8
  CDoom.french_key_map[88] = 'X'.ord.to_u8
  CDoom.french_key_map[89] = 'Y'.ord.to_u8
  CDoom.french_key_map[90] = 'W'.ord.to_u8
  CDoom.french_key_map[91] = '^'.ord.to_u8
  CDoom.french_key_map[92] = '\\'.ord.to_u8
  CDoom.french_key_map[93] = '$'.ord.to_u8
  CDoom.french_key_map[94] = '^'.ord.to_u8
  CDoom.french_key_map[95] = '_'.ord.to_u8
  CDoom.french_key_map[96] = '@'.ord.to_u8
  CDoom.french_key_map[97] = 'Q'.ord.to_u8
  CDoom.french_key_map[98] = 'B'.ord.to_u8
  CDoom.french_key_map[99] = 'C'.ord.to_u8
  CDoom.french_key_map[100] = 'D'.ord.to_u8
  CDoom.french_key_map[101] = 'E'.ord.to_u8
  CDoom.french_key_map[102] = 'F'.ord.to_u8
  CDoom.french_key_map[103] = 'G'.ord.to_u8
  CDoom.french_key_map[104] = 'H'.ord.to_u8
  CDoom.french_key_map[105] = 'I'.ord.to_u8
  CDoom.french_key_map[106] = 'J'.ord.to_u8
  CDoom.french_key_map[107] = 'K'.ord.to_u8
  CDoom.french_key_map[108] = 'L'.ord.to_u8
  CDoom.french_key_map[109] = ','.ord.to_u8
  CDoom.french_key_map[110] = 'N'.ord.to_u8
  CDoom.french_key_map[111] = 'O'.ord.to_u8
  CDoom.french_key_map[112] = 'P'.ord.to_u8
  CDoom.french_key_map[113] = 'A'.ord.to_u8
  CDoom.french_key_map[114] = 'R'.ord.to_u8
  CDoom.french_key_map[115] = 'S'.ord.to_u8
  CDoom.french_key_map[116] = 'T'.ord.to_u8
  CDoom.french_key_map[117] = 'U'.ord.to_u8
  CDoom.french_key_map[118] = 'V'.ord.to_u8
  CDoom.french_key_map[119] = 'Z'.ord.to_u8
  CDoom.french_key_map[120] = 'X'.ord.to_u8
  CDoom.french_key_map[121] = 'Y'.ord.to_u8
  CDoom.french_key_map[122] = 'W'.ord.to_u8
  CDoom.french_key_map[123] = '^'.ord.to_u8
  CDoom.french_key_map[124] = '\\'.ord.to_u8
  CDoom.french_key_map[125] = '$'.ord.to_u8
  CDoom.french_key_map[126] = '^'.ord.to_u8
  CDoom.french_key_map[127] = 127

  #
  # Builtin map names.
  # The actual names can be found in DStrings.h.
  #

  # DOOM shareware/registered/retail (Ultimate) names.
  CDoom.mapnames[0] = CDoom::HUSTR_E1M1.to_unsafe
  CDoom.mapnames[1] = CDoom::HUSTR_E1M2.to_unsafe
  CDoom.mapnames[2] = CDoom::HUSTR_E1M3.to_unsafe
  CDoom.mapnames[3] = CDoom::HUSTR_E1M4.to_unsafe
  CDoom.mapnames[4] = CDoom::HUSTR_E1M5.to_unsafe
  CDoom.mapnames[5] = CDoom::HUSTR_E1M6.to_unsafe
  CDoom.mapnames[6] = CDoom::HUSTR_E1M7.to_unsafe
  CDoom.mapnames[7] = CDoom::HUSTR_E1M8.to_unsafe
  CDoom.mapnames[8] = CDoom::HUSTR_E1M9.to_unsafe

  CDoom.mapnames[9] = CDoom::HUSTR_E2M1.to_unsafe
  CDoom.mapnames[10] = CDoom::HUSTR_E2M2.to_unsafe
  CDoom.mapnames[11] = CDoom::HUSTR_E2M3.to_unsafe
  CDoom.mapnames[12] = CDoom::HUSTR_E2M4.to_unsafe
  CDoom.mapnames[13] = CDoom::HUSTR_E2M5.to_unsafe
  CDoom.mapnames[14] = CDoom::HUSTR_E2M6.to_unsafe
  CDoom.mapnames[15] = CDoom::HUSTR_E2M7.to_unsafe
  CDoom.mapnames[16] = CDoom::HUSTR_E2M8.to_unsafe
  CDoom.mapnames[17] = CDoom::HUSTR_E2M9.to_unsafe

  CDoom.mapnames[18] = CDoom::HUSTR_E3M1.to_unsafe
  CDoom.mapnames[19] = CDoom::HUSTR_E3M2.to_unsafe
  CDoom.mapnames[20] = CDoom::HUSTR_E3M3.to_unsafe
  CDoom.mapnames[21] = CDoom::HUSTR_E3M4.to_unsafe
  CDoom.mapnames[22] = CDoom::HUSTR_E3M5.to_unsafe
  CDoom.mapnames[23] = CDoom::HUSTR_E3M6.to_unsafe
  CDoom.mapnames[24] = CDoom::HUSTR_E3M7.to_unsafe
  CDoom.mapnames[25] = CDoom::HUSTR_E3M8.to_unsafe
  CDoom.mapnames[26] = CDoom::HUSTR_E3M9.to_unsafe

  CDoom.mapnames[27] = CDoom::HUSTR_E4M1.to_unsafe
  CDoom.mapnames[28] = CDoom::HUSTR_E4M2.to_unsafe
  CDoom.mapnames[29] = CDoom::HUSTR_E4M3.to_unsafe
  CDoom.mapnames[30] = CDoom::HUSTR_E4M4.to_unsafe
  CDoom.mapnames[31] = CDoom::HUSTR_E4M5.to_unsafe
  CDoom.mapnames[32] = CDoom::HUSTR_E4M6.to_unsafe
  CDoom.mapnames[33] = CDoom::HUSTR_E4M7.to_unsafe
  CDoom.mapnames[34] = CDoom::HUSTR_E4M8.to_unsafe
  CDoom.mapnames[35] = CDoom::HUSTR_E4M9.to_unsafe

  CDoom.mapnames[36] = "NEWLEVEL".to_unsafe
  CDoom.mapnames[37] = "NEWLEVEL".to_unsafe
  CDoom.mapnames[38] = "NEWLEVEL".to_unsafe
  CDoom.mapnames[39] = "NEWLEVEL".to_unsafe
  CDoom.mapnames[40] = "NEWLEVEL".to_unsafe
  CDoom.mapnames[41] = "NEWLEVEL".to_unsafe
  CDoom.mapnames[42] = "NEWLEVEL".to_unsafe
  CDoom.mapnames[43] = "NEWLEVEL".to_unsafe
  CDoom.mapnames[44] = "NEWLEVEL".to_unsafe

  # DOOM 2 map names.
  CDoom.mapnames2[0] = CDoom::HUSTR_1.to_unsafe
  CDoom.mapnames2[1] = CDoom::HUSTR_2.to_unsafe
  CDoom.mapnames2[2] = CDoom::HUSTR_3.to_unsafe
  CDoom.mapnames2[3] = CDoom::HUSTR_4.to_unsafe
  CDoom.mapnames2[4] = CDoom::HUSTR_5.to_unsafe
  CDoom.mapnames2[5] = CDoom::HUSTR_6.to_unsafe
  CDoom.mapnames2[6] = CDoom::HUSTR_7.to_unsafe
  CDoom.mapnames2[7] = CDoom::HUSTR_8.to_unsafe
  CDoom.mapnames2[8] = CDoom::HUSTR_9.to_unsafe
  CDoom.mapnames2[9] = CDoom::HUSTR_10.to_unsafe
  CDoom.mapnames2[10] = CDoom::HUSTR_11.to_unsafe

  CDoom.mapnames2[11] = CDoom::HUSTR_12.to_unsafe
  CDoom.mapnames2[12] = CDoom::HUSTR_13.to_unsafe
  CDoom.mapnames2[13] = CDoom::HUSTR_14.to_unsafe
  CDoom.mapnames2[14] = CDoom::HUSTR_15.to_unsafe
  CDoom.mapnames2[15] = CDoom::HUSTR_16.to_unsafe
  CDoom.mapnames2[16] = CDoom::HUSTR_17.to_unsafe
  CDoom.mapnames2[17] = CDoom::HUSTR_18.to_unsafe
  CDoom.mapnames2[18] = CDoom::HUSTR_19.to_unsafe
  CDoom.mapnames2[19] = CDoom::HUSTR_20.to_unsafe

  CDoom.mapnames2[20] = CDoom::HUSTR_21.to_unsafe
  CDoom.mapnames2[21] = CDoom::HUSTR_22.to_unsafe
  CDoom.mapnames2[22] = CDoom::HUSTR_23.to_unsafe
  CDoom.mapnames2[23] = CDoom::HUSTR_24.to_unsafe
  CDoom.mapnames2[24] = CDoom::HUSTR_25.to_unsafe
  CDoom.mapnames2[25] = CDoom::HUSTR_26.to_unsafe
  CDoom.mapnames2[26] = CDoom::HUSTR_27.to_unsafe
  CDoom.mapnames2[27] = CDoom::HUSTR_28.to_unsafe
  CDoom.mapnames2[28] = CDoom::HUSTR_29.to_unsafe
  CDoom.mapnames2[29] = CDoom::HUSTR_30.to_unsafe
  CDoom.mapnames2[30] = CDoom::HUSTR_31.to_unsafe
  CDoom.mapnames2[31] = CDoom::HUSTR_32.to_unsafe

  # Plutonia WAD map names.
  CDoom.mapnamesp[0] = CDoom::PHUSTR_1.to_unsafe
  CDoom.mapnamesp[1] = CDoom::PHUSTR_2.to_unsafe
  CDoom.mapnamesp[2] = CDoom::PHUSTR_3.to_unsafe
  CDoom.mapnamesp[3] = CDoom::PHUSTR_4.to_unsafe
  CDoom.mapnamesp[4] = CDoom::PHUSTR_5.to_unsafe
  CDoom.mapnamesp[5] = CDoom::PHUSTR_6.to_unsafe
  CDoom.mapnamesp[6] = CDoom::PHUSTR_7.to_unsafe
  CDoom.mapnamesp[7] = CDoom::PHUSTR_8.to_unsafe
  CDoom.mapnamesp[8] = CDoom::PHUSTR_9.to_unsafe
  CDoom.mapnamesp[9] = CDoom::PHUSTR_10.to_unsafe
  CDoom.mapnamesp[10] = CDoom::PHUSTR_11.to_unsafe

  CDoom.mapnamesp[11] = CDoom::PHUSTR_12.to_unsafe
  CDoom.mapnamesp[12] = CDoom::PHUSTR_13.to_unsafe
  CDoom.mapnamesp[13] = CDoom::PHUSTR_14.to_unsafe
  CDoom.mapnamesp[14] = CDoom::PHUSTR_15.to_unsafe
  CDoom.mapnamesp[15] = CDoom::PHUSTR_16.to_unsafe
  CDoom.mapnamesp[16] = CDoom::PHUSTR_17.to_unsafe
  CDoom.mapnamesp[17] = CDoom::PHUSTR_18.to_unsafe
  CDoom.mapnamesp[18] = CDoom::PHUSTR_19.to_unsafe
  CDoom.mapnamesp[19] = CDoom::PHUSTR_20.to_unsafe

  CDoom.mapnamesp[20] = CDoom::PHUSTR_21.to_unsafe
  CDoom.mapnamesp[21] = CDoom::PHUSTR_22.to_unsafe
  CDoom.mapnamesp[22] = CDoom::PHUSTR_23.to_unsafe
  CDoom.mapnamesp[23] = CDoom::PHUSTR_24.to_unsafe
  CDoom.mapnamesp[24] = CDoom::PHUSTR_25.to_unsafe
  CDoom.mapnamesp[25] = CDoom::PHUSTR_26.to_unsafe
  CDoom.mapnamesp[26] = CDoom::PHUSTR_27.to_unsafe
  CDoom.mapnamesp[27] = CDoom::PHUSTR_28.to_unsafe
  CDoom.mapnamesp[28] = CDoom::PHUSTR_29.to_unsafe
  CDoom.mapnamesp[29] = CDoom::PHUSTR_30.to_unsafe
  CDoom.mapnamesp[30] = CDoom::PHUSTR_31.to_unsafe
  CDoom.mapnamesp[31] = CDoom::PHUSTR_32.to_unsafe

  # TNT WAD map names.
  CDoom.mapnamest[0] = CDoom::THUSTR_1.to_unsafe
  CDoom.mapnamest[1] = CDoom::THUSTR_2.to_unsafe
  CDoom.mapnamest[2] = CDoom::THUSTR_3.to_unsafe
  CDoom.mapnamest[3] = CDoom::THUSTR_4.to_unsafe
  CDoom.mapnamest[4] = CDoom::THUSTR_5.to_unsafe
  CDoom.mapnamest[5] = CDoom::THUSTR_6.to_unsafe
  CDoom.mapnamest[6] = CDoom::THUSTR_7.to_unsafe
  CDoom.mapnamest[7] = CDoom::THUSTR_8.to_unsafe
  CDoom.mapnamest[8] = CDoom::THUSTR_9.to_unsafe
  CDoom.mapnamest[9] = CDoom::THUSTR_10.to_unsafe
  CDoom.mapnamest[10] = CDoom::THUSTR_11.to_unsafe

  CDoom.mapnamest[11] = CDoom::THUSTR_12.to_unsafe
  CDoom.mapnamest[12] = CDoom::THUSTR_13.to_unsafe
  CDoom.mapnamest[13] = CDoom::THUSTR_14.to_unsafe
  CDoom.mapnamest[14] = CDoom::THUSTR_15.to_unsafe
  CDoom.mapnamest[15] = CDoom::THUSTR_16.to_unsafe
  CDoom.mapnamest[16] = CDoom::THUSTR_17.to_unsafe
  CDoom.mapnamest[17] = CDoom::THUSTR_18.to_unsafe
  CDoom.mapnamest[18] = CDoom::THUSTR_19.to_unsafe
  CDoom.mapnamest[19] = CDoom::THUSTR_20.to_unsafe

  CDoom.mapnamest[20] = CDoom::THUSTR_21.to_unsafe
  CDoom.mapnamest[21] = CDoom::THUSTR_22.to_unsafe
  CDoom.mapnamest[22] = CDoom::THUSTR_23.to_unsafe
  CDoom.mapnamest[23] = CDoom::THUSTR_24.to_unsafe
  CDoom.mapnamest[24] = CDoom::THUSTR_25.to_unsafe
  CDoom.mapnamest[25] = CDoom::THUSTR_26.to_unsafe
  CDoom.mapnamest[26] = CDoom::THUSTR_27.to_unsafe
  CDoom.mapnamest[27] = CDoom::THUSTR_28.to_unsafe
  CDoom.mapnamest[28] = CDoom::THUSTR_29.to_unsafe
  CDoom.mapnamest[29] = CDoom::THUSTR_30.to_unsafe
  CDoom.mapnamest[30] = CDoom::THUSTR_31.to_unsafe
  CDoom.mapnamest[31] = CDoom::THUSTR_32.to_unsafe

  CDoom.flag = 0

  CDoom.mus_data = Pointer(UInt8).null
  CDoom.mus_offset = 0
  CDoom.mus_delay = 0
  CDoom.mus_loop = 0
  CDoom.mus_playing = 0
  CDoom.mus_volume = 127
  c_array(CDoom.mus_channel_volumes, 127, 127, 127, 127,
    127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127)

  CDoom.looping = 0
  CDoom.musicdies = -1

  CDoom.queue_midi_head = 0
  CDoom.queue_midi_tail = 0

  CDoom.mb_used = 12

  @@sprnames = ["TROO".to_unsafe, "SHTG".to_unsafe, "PUNG".to_unsafe, "PISG".to_unsafe, "PISF".to_unsafe, "SHTF".to_unsafe, "SHT2".to_unsafe, "CHGG".to_unsafe, "CHGF".to_unsafe, "MISG".to_unsafe,
                "MISF".to_unsafe, "SAWG".to_unsafe, "PLSG".to_unsafe, "PLSF".to_unsafe, "BFGG".to_unsafe, "BFGF".to_unsafe, "BLUD".to_unsafe, "PUFF".to_unsafe, "BAL1".to_unsafe, "BAL2".to_unsafe,
                "PLSS".to_unsafe, "PLSE".to_unsafe, "MISL".to_unsafe, "BFS1".to_unsafe, "BFE1".to_unsafe, "BFE2".to_unsafe, "TFOG".to_unsafe, "IFOG".to_unsafe, "PLAY".to_unsafe, "POSS".to_unsafe,
                "SPOS".to_unsafe, "VILE".to_unsafe, "FIRE".to_unsafe, "FATB".to_unsafe, "FBXP".to_unsafe, "SKEL".to_unsafe, "MANF".to_unsafe, "FATT".to_unsafe, "CPOS".to_unsafe, "SARG".to_unsafe,
                "HEAD".to_unsafe, "BAL7".to_unsafe, "BOSS".to_unsafe, "BOS2".to_unsafe, "SKUL".to_unsafe, "SPID".to_unsafe, "BSPI".to_unsafe, "APLS".to_unsafe, "APBX".to_unsafe, "CYBR".to_unsafe,
                "PAIN".to_unsafe, "SSWV".to_unsafe, "KEEN".to_unsafe, "BBRN".to_unsafe, "BOSF".to_unsafe, "ARM1".to_unsafe, "ARM2".to_unsafe, "BAR1".to_unsafe, "BEXP".to_unsafe, "FCAN".to_unsafe,
                "BON1".to_unsafe, "BON2".to_unsafe, "BKEY".to_unsafe, "RKEY".to_unsafe, "YKEY".to_unsafe, "BSKU".to_unsafe, "RSKU".to_unsafe, "YSKU".to_unsafe, "STIM".to_unsafe, "MEDI".to_unsafe,
                "SOUL".to_unsafe, "PINV".to_unsafe, "PSTR".to_unsafe, "PINS".to_unsafe, "MEGA".to_unsafe, "SUIT".to_unsafe, "PMAP".to_unsafe, "PVIS".to_unsafe, "CLIP".to_unsafe, "AMMO".to_unsafe,
                "ROCK".to_unsafe, "BROK".to_unsafe, "CELL".to_unsafe, "CELP".to_unsafe, "SHEL".to_unsafe, "SBOX".to_unsafe, "BPAK".to_unsafe, "BFUG".to_unsafe, "MGUN".to_unsafe, "CSAW".to_unsafe,
                "LAUN".to_unsafe, "PLAS".to_unsafe, "SHOT".to_unsafe, "SGN2".to_unsafe, "COLU".to_unsafe, "SMT2".to_unsafe, "GOR1".to_unsafe, "POL2".to_unsafe, "POL5".to_unsafe, "POL4".to_unsafe,
                "POL3".to_unsafe, "POL1".to_unsafe, "POL6".to_unsafe, "GOR2".to_unsafe, "GOR3".to_unsafe, "GOR4".to_unsafe, "GOR5".to_unsafe, "SMIT".to_unsafe, "COL1".to_unsafe, "COL2".to_unsafe,
                "COL3".to_unsafe, "COL4".to_unsafe, "CAND".to_unsafe, "CBRA".to_unsafe, "COL6".to_unsafe, "TRE1".to_unsafe, "TRE2".to_unsafe, "ELEC".to_unsafe, "CEYE".to_unsafe, "FSKU".to_unsafe,
                "COL5".to_unsafe, "TBLU".to_unsafe, "TGRN".to_unsafe, "TRED".to_unsafe, "SMBT".to_unsafe, "SMGT".to_unsafe, "SMRT".to_unsafe, "HDB1".to_unsafe, "HDB2".to_unsafe, "HDB3".to_unsafe,
                "HDB4".to_unsafe, "HDB5".to_unsafe, "HDB6".to_unsafe, "POB1".to_unsafe, "POB2".to_unsafe, "BRS1".to_unsafe, "TLMP".to_unsafe, "TLP2".to_unsafe, "\0".to_unsafe]

  CDoom.sprnames = @@sprnames.to_unsafe

  @@statedata : Array(Tuple(CDoom::Spritenum, Int32, Int32, Void*, CDoom::Statenum, Int32, Int32)) = [
    {CDoom::Spritenum::SPR_TROO, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_NULL
    {CDoom::Spritenum::SPR_SHTG, 4, 0, (->CDoom.a_light0).pointer, CDoom::Statenum::S_NULL, 0, 0},                 # S_LIGHTDONE
    {CDoom::Spritenum::SPR_PUNG, 0, 1, (->CDoom.a_weapon_ready).pointer, CDoom::Statenum::S_PUNCH, 0, 0},          # S_PUNCH
    {CDoom::Spritenum::SPR_PUNG, 0, 1, (->CDoom.a_lower).pointer, CDoom::Statenum::S_PUNCHDOWN, 0, 0},             # S_PUNCHDOWN
    {CDoom::Spritenum::SPR_PUNG, 0, 1, (->CDoom.a_raise).pointer, CDoom::Statenum::S_PUNCHUP, 0, 0},               # S_PUNCHUP
    {CDoom::Spritenum::SPR_PUNG, 1, 4, Pointer(Void).null, CDoom::Statenum::S_PUNCH2, 0, 0},                       # S_PUNCH1
    {CDoom::Spritenum::SPR_PUNG, 2, 4, (->CDoom.a_punch).pointer, CDoom::Statenum::S_PUNCH3, 0, 0},                # S_PUNCH2
    {CDoom::Spritenum::SPR_PUNG, 3, 5, Pointer(Void).null, CDoom::Statenum::S_PUNCH4, 0, 0},                       # S_PUNCH3
    {CDoom::Spritenum::SPR_PUNG, 2, 4, Pointer(Void).null, CDoom::Statenum::S_PUNCH5, 0, 0},                       # S_PUNCH4
    {CDoom::Spritenum::SPR_PUNG, 1, 5, (->CDoom.a_refire).pointer, CDoom::Statenum::S_PUNCH, 0, 0},                # S_PUNCH5
    {CDoom::Spritenum::SPR_PISG, 0, 1, (->CDoom.a_weapon_ready).pointer, CDoom::Statenum::S_PISTOL, 0, 0},         # S_PISTOL
    {CDoom::Spritenum::SPR_PISG, 0, 1, (->CDoom.a_lower).pointer, CDoom::Statenum::S_PISTOLDOWN, 0, 0},            # S_PISTOLDOWN
    {CDoom::Spritenum::SPR_PISG, 0, 1, (->CDoom.a_raise).pointer, CDoom::Statenum::S_PISTOLUP, 0, 0},              # S_PISTOLUP
    {CDoom::Spritenum::SPR_PISG, 0, 4, Pointer(Void).null, CDoom::Statenum::S_PISTOL2, 0, 0},                      # S_PISTOL1
    {CDoom::Spritenum::SPR_PISG, 1, 6, (->CDoom.a_fire_pistol).pointer, CDoom::Statenum::S_PISTOL3, 0, 0},         # S_PISTOL2
    {CDoom::Spritenum::SPR_PISG, 2, 4, Pointer(Void).null, CDoom::Statenum::S_PISTOL4, 0, 0},                      # S_PISTOL3
    {CDoom::Spritenum::SPR_PISG, 1, 5, (->CDoom.a_refire).pointer, CDoom::Statenum::S_PISTOL, 0, 0},               # S_PISTOL4
    {CDoom::Spritenum::SPR_PISF, 32768, 7, (->CDoom.a_light1).pointer, CDoom::Statenum::S_LIGHTDONE, 0, 0},        # S_PISTOLFLASH
    {CDoom::Spritenum::SPR_SHTG, 0, 1, (->CDoom.a_weapon_ready).pointer, CDoom::Statenum::S_SGUN, 0, 0},           # S_SGUN
    {CDoom::Spritenum::SPR_SHTG, 0, 1, (->CDoom.a_lower).pointer, CDoom::Statenum::S_SGUNDOWN, 0, 0},              # S_SGUNDOWN
    {CDoom::Spritenum::SPR_SHTG, 0, 1, (->CDoom.a_raise).pointer, CDoom::Statenum::S_SGUNUP, 0, 0},                # S_SGUNUP
    {CDoom::Spritenum::SPR_SHTG, 0, 3, Pointer(Void).null, CDoom::Statenum::S_SGUN2, 0, 0},                        # S_SGUN1
    {CDoom::Spritenum::SPR_SHTG, 0, 7, (->CDoom.a_fire_shotgun).pointer, CDoom::Statenum::S_SGUN3, 0, 0},          # S_SGUN2
    {CDoom::Spritenum::SPR_SHTG, 1, 5, Pointer(Void).null, CDoom::Statenum::S_SGUN4, 0, 0},                        # S_SGUN3
    {CDoom::Spritenum::SPR_SHTG, 2, 5, Pointer(Void).null, CDoom::Statenum::S_SGUN5, 0, 0},                        # S_SGUN4
    {CDoom::Spritenum::SPR_SHTG, 3, 4, Pointer(Void).null, CDoom::Statenum::S_SGUN6, 0, 0},                        # S_SGUN5
    {CDoom::Spritenum::SPR_SHTG, 2, 5, Pointer(Void).null, CDoom::Statenum::S_SGUN7, 0, 0},                        # S_SGUN6
    {CDoom::Spritenum::SPR_SHTG, 1, 5, Pointer(Void).null, CDoom::Statenum::S_SGUN8, 0, 0},                        # S_SGUN7
    {CDoom::Spritenum::SPR_SHTG, 0, 3, Pointer(Void).null, CDoom::Statenum::S_SGUN9, 0, 0},                        # S_SGUN8
    {CDoom::Spritenum::SPR_SHTG, 0, 7, (->CDoom.a_refire).pointer, CDoom::Statenum::S_SGUN, 0, 0},                 # S_SGUN9
    {CDoom::Spritenum::SPR_SHTF, 32768, 4, (->CDoom.a_light1).pointer, CDoom::Statenum::S_SGUNFLASH2, 0, 0},       # S_SGUNFLASH1
    {CDoom::Spritenum::SPR_SHTF, 32769, 3, (->CDoom.a_light2).pointer, CDoom::Statenum::S_LIGHTDONE, 0, 0},        # S_SGUNFLASH2
    {CDoom::Spritenum::SPR_SHT2, 0, 1, (->CDoom.a_weapon_ready).pointer, CDoom::Statenum::S_DSGUN, 0, 0},          # S_DSGUN
    {CDoom::Spritenum::SPR_SHT2, 0, 1, (->CDoom.a_lower).pointer, CDoom::Statenum::S_DSGUNDOWN, 0, 0},             # S_DSGUNDOWN
    {CDoom::Spritenum::SPR_SHT2, 0, 1, (->CDoom.a_raise).pointer, CDoom::Statenum::S_DSGUNUP, 0, 0},               # S_DSGUNUP
    {CDoom::Spritenum::SPR_SHT2, 0, 3, Pointer(Void).null, CDoom::Statenum::S_DSGUN2, 0, 0},                       # S_DSGUN1
    {CDoom::Spritenum::SPR_SHT2, 0, 7, (->CDoom.a_fire_shotgun2).pointer, CDoom::Statenum::S_DSGUN3, 0, 0},        # S_DSGUN2
    {CDoom::Spritenum::SPR_SHT2, 1, 7, Pointer(Void).null, CDoom::Statenum::S_DSGUN4, 0, 0},                       # S_DSGUN3
    {CDoom::Spritenum::SPR_SHT2, 2, 7, (->CDoom.a_check_reload).pointer, CDoom::Statenum::S_DSGUN5, 0, 0},         # S_DSGUN4
    {CDoom::Spritenum::SPR_SHT2, 3, 7, (->CDoom.a_open_shotgun2).pointer, CDoom::Statenum::S_DSGUN6, 0, 0},        # S_DSGUN5
    {CDoom::Spritenum::SPR_SHT2, 4, 7, Pointer(Void).null, CDoom::Statenum::S_DSGUN7, 0, 0},                       # S_DSGUN6
    {CDoom::Spritenum::SPR_SHT2, 5, 7, (->CDoom.a_load_shotgun2).pointer, CDoom::Statenum::S_DSGUN8, 0, 0},        # S_DSGUN7
    {CDoom::Spritenum::SPR_SHT2, 6, 6, Pointer(Void).null, CDoom::Statenum::S_DSGUN9, 0, 0},                       # S_DSGUN8
    {CDoom::Spritenum::SPR_SHT2, 7, 6, (->CDoom.a_close_shotgun2).pointer, CDoom::Statenum::S_DSGUN10, 0, 0},      # S_DSGUN9
    {CDoom::Spritenum::SPR_SHT2, 0, 5, (->CDoom.a_refire).pointer, CDoom::Statenum::S_DSGUN, 0, 0},                # S_DSGUN10
    {CDoom::Spritenum::SPR_SHT2, 1, 7, Pointer(Void).null, CDoom::Statenum::S_DSNR2, 0, 0},                        # S_DSNR1
    {CDoom::Spritenum::SPR_SHT2, 0, 3, Pointer(Void).null, CDoom::Statenum::S_DSGUNDOWN, 0, 0},                    # S_DSNR2
    {CDoom::Spritenum::SPR_SHT2, 32776, 5, (->CDoom.a_light1).pointer, CDoom::Statenum::S_DSGUNFLASH2, 0, 0},      # S_DSGUNFLASH1
    {CDoom::Spritenum::SPR_SHT2, 32777, 4, (->CDoom.a_light2).pointer, CDoom::Statenum::S_LIGHTDONE, 0, 0},        # S_DSGUNFLASH2
    {CDoom::Spritenum::SPR_CHGG, 0, 1, (->CDoom.a_weapon_ready).pointer, CDoom::Statenum::S_CHAIN, 0, 0},          # S_CHAIN
    {CDoom::Spritenum::SPR_CHGG, 0, 1, (->CDoom.a_lower).pointer, CDoom::Statenum::S_CHAINDOWN, 0, 0},             # S_CHAINDOWN
    {CDoom::Spritenum::SPR_CHGG, 0, 1, (->CDoom.a_raise).pointer, CDoom::Statenum::S_CHAINUP, 0, 0},               # S_CHAINUP
    {CDoom::Spritenum::SPR_CHGG, 0, 4, (->CDoom.a_fire_cgun).pointer, CDoom::Statenum::S_CHAIN2, 0, 0},            # S_CHAIN1
    {CDoom::Spritenum::SPR_CHGG, 1, 4, (->CDoom.a_fire_cgun).pointer, CDoom::Statenum::S_CHAIN3, 0, 0},            # S_CHAIN2
    {CDoom::Spritenum::SPR_CHGG, 1, 0, (->CDoom.a_refire).pointer, CDoom::Statenum::S_CHAIN, 0, 0},                # S_CHAIN3
    {CDoom::Spritenum::SPR_CHGF, 32768, 5, (->CDoom.a_light1).pointer, CDoom::Statenum::S_LIGHTDONE, 0, 0},        # S_CHAINFLASH1
    {CDoom::Spritenum::SPR_CHGF, 32769, 5, (->CDoom.a_light2).pointer, CDoom::Statenum::S_LIGHTDONE, 0, 0},        # S_CHAINFLASH2
    {CDoom::Spritenum::SPR_MISG, 0, 1, (->CDoom.a_weapon_ready).pointer, CDoom::Statenum::S_MISSILE, 0, 0},        # S_MISSILE
    {CDoom::Spritenum::SPR_MISG, 0, 1, (->CDoom.a_lower).pointer, CDoom::Statenum::S_MISSILEDOWN, 0, 0},           # S_MISSILEDOWN
    {CDoom::Spritenum::SPR_MISG, 0, 1, (->CDoom.a_raise).pointer, CDoom::Statenum::S_MISSILEUP, 0, 0},             # S_MISSILEUP
    {CDoom::Spritenum::SPR_MISG, 1, 8, (->CDoom.a_gun_flash).pointer, CDoom::Statenum::S_MISSILE2, 0, 0},          # S_MISSILE1
    {CDoom::Spritenum::SPR_MISG, 1, 12, (->CDoom.a_fire_missile).pointer, CDoom::Statenum::S_MISSILE3, 0, 0},      # S_MISSILE2
    {CDoom::Spritenum::SPR_MISG, 1, 0, (->CDoom.a_refire).pointer, CDoom::Statenum::S_MISSILE, 0, 0},              # S_MISSILE3
    {CDoom::Spritenum::SPR_MISF, 32768, 3, (->CDoom.a_light1).pointer, CDoom::Statenum::S_MISSILEFLASH2, 0, 0},    # S_MISSILEFLASH1
    {CDoom::Spritenum::SPR_MISF, 32769, 4, Pointer(Void).null, CDoom::Statenum::S_MISSILEFLASH3, 0, 0},            # S_MISSILEFLASH2
    {CDoom::Spritenum::SPR_MISF, 32770, 4, (->CDoom.a_light2).pointer, CDoom::Statenum::S_MISSILEFLASH4, 0, 0},    # S_MISSILEFLASH3
    {CDoom::Spritenum::SPR_MISF, 32771, 4, (->CDoom.a_light2).pointer, CDoom::Statenum::S_LIGHTDONE, 0, 0},        # S_MISSILEFLASH4
    {CDoom::Spritenum::SPR_SAWG, 2, 4, (->CDoom.a_weapon_ready).pointer, CDoom::Statenum::S_SAWB, 0, 0},           # S_SAW
    {CDoom::Spritenum::SPR_SAWG, 3, 4, (->CDoom.a_weapon_ready).pointer, CDoom::Statenum::S_SAW, 0, 0},            # S_SAWB
    {CDoom::Spritenum::SPR_SAWG, 2, 1, (->CDoom.a_lower).pointer, CDoom::Statenum::S_SAWDOWN, 0, 0},               # S_SAWDOWN
    {CDoom::Spritenum::SPR_SAWG, 2, 1, (->CDoom.a_raise).pointer, CDoom::Statenum::S_SAWUP, 0, 0},                 # S_SAWUP
    {CDoom::Spritenum::SPR_SAWG, 0, 4, (->CDoom.a_saw).pointer, CDoom::Statenum::S_SAW2, 0, 0},                    # S_SAW1
    {CDoom::Spritenum::SPR_SAWG, 1, 4, (->CDoom.a_saw).pointer, CDoom::Statenum::S_SAW3, 0, 0},                    # S_SAW2
    {CDoom::Spritenum::SPR_SAWG, 1, 0, (->CDoom.a_refire).pointer, CDoom::Statenum::S_SAW, 0, 0},                  # S_SAW3
    {CDoom::Spritenum::SPR_PLSG, 0, 1, (->CDoom.a_weapon_ready).pointer, CDoom::Statenum::S_PLASMA, 0, 0},         # S_PLASMA
    {CDoom::Spritenum::SPR_PLSG, 0, 1, (->CDoom.a_lower).pointer, CDoom::Statenum::S_PLASMADOWN, 0, 0},            # S_PLASMADOWN
    {CDoom::Spritenum::SPR_PLSG, 0, 1, (->CDoom.a_raise).pointer, CDoom::Statenum::S_PLASMAUP, 0, 0},              # S_PLASMAUP
    {CDoom::Spritenum::SPR_PLSG, 0, 3, (->CDoom.a_fire_plasma).pointer, CDoom::Statenum::S_PLASMA2, 0, 0},         # S_PLASMA1
    {CDoom::Spritenum::SPR_PLSG, 1, 20, (->CDoom.a_refire).pointer, CDoom::Statenum::S_PLASMA, 0, 0},              # S_PLASMA2
    {CDoom::Spritenum::SPR_PLSF, 32768, 4, (->CDoom.a_light1).pointer, CDoom::Statenum::S_LIGHTDONE, 0, 0},        # S_PLASMAFLASH1
    {CDoom::Spritenum::SPR_PLSF, 32769, 4, (->CDoom.a_light1).pointer, CDoom::Statenum::S_LIGHTDONE, 0, 0},        # S_PLASMAFLASH2
    {CDoom::Spritenum::SPR_BFGG, 0, 1, (->CDoom.a_weapon_ready).pointer, CDoom::Statenum::S_BFG, 0, 0},            # S_BFG
    {CDoom::Spritenum::SPR_BFGG, 0, 1, (->CDoom.a_lower).pointer, CDoom::Statenum::S_BFGDOWN, 0, 0},               # S_BFGDOWN
    {CDoom::Spritenum::SPR_BFGG, 0, 1, (->CDoom.a_raise).pointer, CDoom::Statenum::S_BFGUP, 0, 0},                 # S_BFGUP
    {CDoom::Spritenum::SPR_BFGG, 0, 20, (->CDoom.a_bfg_sound).pointer, CDoom::Statenum::S_BFG2, 0, 0},             # S_BFG1
    {CDoom::Spritenum::SPR_BFGG, 1, 10, (->CDoom.a_gun_flash).pointer, CDoom::Statenum::S_BFG3, 0, 0},             # S_BFG2
    {CDoom::Spritenum::SPR_BFGG, 1, 10, (->CDoom.a_fire_bfg).pointer, CDoom::Statenum::S_BFG4, 0, 0},              # S_BFG3
    {CDoom::Spritenum::SPR_BFGG, 1, 20, (->CDoom.a_refire).pointer, CDoom::Statenum::S_BFG, 0, 0},                 # S_BFG4
    {CDoom::Spritenum::SPR_BFGF, 32768, 11, (->CDoom.a_light1).pointer, CDoom::Statenum::S_BFGFLASH2, 0, 0},       # S_BFGFLASH1
    {CDoom::Spritenum::SPR_BFGF, 32769, 6, (->CDoom.a_light2).pointer, CDoom::Statenum::S_LIGHTDONE, 0, 0},        # S_BFGFLASH2
    {CDoom::Spritenum::SPR_BLUD, 2, 8, Pointer(Void).null, CDoom::Statenum::S_BLOOD2, 0, 0},                       # S_BLOOD1
    {CDoom::Spritenum::SPR_BLUD, 1, 8, Pointer(Void).null, CDoom::Statenum::S_BLOOD3, 0, 0},                       # S_BLOOD2
    {CDoom::Spritenum::SPR_BLUD, 0, 8, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                         # S_BLOOD3
    {CDoom::Spritenum::SPR_PUFF, 32768, 4, Pointer(Void).null, CDoom::Statenum::S_PUFF2, 0, 0},                    # S_PUFF1
    {CDoom::Spritenum::SPR_PUFF, 1, 4, Pointer(Void).null, CDoom::Statenum::S_PUFF3, 0, 0},                        # S_PUFF2
    {CDoom::Spritenum::SPR_PUFF, 2, 4, Pointer(Void).null, CDoom::Statenum::S_PUFF4, 0, 0},                        # S_PUFF3
    {CDoom::Spritenum::SPR_PUFF, 3, 4, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                         # S_PUFF4
    {CDoom::Spritenum::SPR_BAL1, 32768, 4, Pointer(Void).null, CDoom::Statenum::S_TBALL2, 0, 0},                   # S_TBALL1
    {CDoom::Spritenum::SPR_BAL1, 32769, 4, Pointer(Void).null, CDoom::Statenum::S_TBALL1, 0, 0},                   # S_TBALL2
    {CDoom::Spritenum::SPR_BAL1, 32770, 6, Pointer(Void).null, CDoom::Statenum::S_TBALLX2, 0, 0},                  # S_TBALLX1
    {CDoom::Spritenum::SPR_BAL1, 32771, 6, Pointer(Void).null, CDoom::Statenum::S_TBALLX3, 0, 0},                  # S_TBALLX2
    {CDoom::Spritenum::SPR_BAL1, 32772, 6, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                     # S_TBALLX3
    {CDoom::Spritenum::SPR_BAL2, 32768, 4, Pointer(Void).null, CDoom::Statenum::S_RBALL2, 0, 0},                   # S_RBALL1
    {CDoom::Spritenum::SPR_BAL2, 32769, 4, Pointer(Void).null, CDoom::Statenum::S_RBALL1, 0, 0},                   # S_RBALL2
    {CDoom::Spritenum::SPR_BAL2, 32770, 6, Pointer(Void).null, CDoom::Statenum::S_RBALLX2, 0, 0},                  # S_RBALLX1
    {CDoom::Spritenum::SPR_BAL2, 32771, 6, Pointer(Void).null, CDoom::Statenum::S_RBALLX3, 0, 0},                  # S_RBALLX2
    {CDoom::Spritenum::SPR_BAL2, 32772, 6, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                     # S_RBALLX3
    {CDoom::Spritenum::SPR_PLSS, 32768, 6, Pointer(Void).null, CDoom::Statenum::S_PLASBALL2, 0, 0},                # S_PLASBALL
    {CDoom::Spritenum::SPR_PLSS, 32769, 6, Pointer(Void).null, CDoom::Statenum::S_PLASBALL, 0, 0},                 # S_PLASBALL2
    {CDoom::Spritenum::SPR_PLSE, 32768, 4, Pointer(Void).null, CDoom::Statenum::S_PLASEXP2, 0, 0},                 # S_PLASEXP
    {CDoom::Spritenum::SPR_PLSE, 32769, 4, Pointer(Void).null, CDoom::Statenum::S_PLASEXP3, 0, 0},                 # S_PLASEXP2
    {CDoom::Spritenum::SPR_PLSE, 32770, 4, Pointer(Void).null, CDoom::Statenum::S_PLASEXP4, 0, 0},                 # S_PLASEXP3
    {CDoom::Spritenum::SPR_PLSE, 32771, 4, Pointer(Void).null, CDoom::Statenum::S_PLASEXP5, 0, 0},                 # S_PLASEXP4
    {CDoom::Spritenum::SPR_PLSE, 32772, 4, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                     # S_PLASEXP5
    {CDoom::Spritenum::SPR_MISL, 32768, 1, Pointer(Void).null, CDoom::Statenum::S_ROCKET, 0, 0},                   # S_ROCKET
    {CDoom::Spritenum::SPR_BFS1, 32768, 4, Pointer(Void).null, CDoom::Statenum::S_BFGSHOT2, 0, 0},                 # S_BFGSHOT
    {CDoom::Spritenum::SPR_BFS1, 32769, 4, Pointer(Void).null, CDoom::Statenum::S_BFGSHOT, 0, 0},                  # S_BFGSHOT2
    {CDoom::Spritenum::SPR_BFE1, 32768, 8, Pointer(Void).null, CDoom::Statenum::S_BFGLAND2, 0, 0},                 # S_BFGLAND
    {CDoom::Spritenum::SPR_BFE1, 32769, 8, Pointer(Void).null, CDoom::Statenum::S_BFGLAND3, 0, 0},                 # S_BFGLAND2
    {CDoom::Spritenum::SPR_BFE1, 32770, 8, (->CDoom.a_bfg_spray).pointer, CDoom::Statenum::S_BFGLAND4, 0, 0},      # S_BFGLAND3
    {CDoom::Spritenum::SPR_BFE1, 32771, 8, Pointer(Void).null, CDoom::Statenum::S_BFGLAND5, 0, 0},                 # S_BFGLAND4
    {CDoom::Spritenum::SPR_BFE1, 32772, 8, Pointer(Void).null, CDoom::Statenum::S_BFGLAND6, 0, 0},                 # S_BFGLAND5
    {CDoom::Spritenum::SPR_BFE1, 32773, 8, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                     # S_BFGLAND6
    {CDoom::Spritenum::SPR_BFE2, 32768, 8, Pointer(Void).null, CDoom::Statenum::S_BFGEXP2, 0, 0},                  # S_BFGEXP
    {CDoom::Spritenum::SPR_BFE2, 32769, 8, Pointer(Void).null, CDoom::Statenum::S_BFGEXP3, 0, 0},                  # S_BFGEXP2
    {CDoom::Spritenum::SPR_BFE2, 32770, 8, Pointer(Void).null, CDoom::Statenum::S_BFGEXP4, 0, 0},                  # S_BFGEXP3
    {CDoom::Spritenum::SPR_BFE2, 32771, 8, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                     # S_BFGEXP4
    {CDoom::Spritenum::SPR_MISL, 32769, 8, (->CDoom.a_explode).pointer, CDoom::Statenum::S_EXPLODE2, 0, 0},        # S_EXPLODE1
    {CDoom::Spritenum::SPR_MISL, 32770, 6, Pointer(Void).null, CDoom::Statenum::S_EXPLODE3, 0, 0},                 # S_EXPLODE2
    {CDoom::Spritenum::SPR_MISL, 32771, 4, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                     # S_EXPLODE3
    {CDoom::Spritenum::SPR_TFOG, 32768, 6, Pointer(Void).null, CDoom::Statenum::S_TFOG01, 0, 0},                   # S_TFOG
    {CDoom::Spritenum::SPR_TFOG, 32769, 6, Pointer(Void).null, CDoom::Statenum::S_TFOG02, 0, 0},                   # S_TFOG01
    {CDoom::Spritenum::SPR_TFOG, 32768, 6, Pointer(Void).null, CDoom::Statenum::S_TFOG2, 0, 0},                    # S_TFOG02
    {CDoom::Spritenum::SPR_TFOG, 32769, 6, Pointer(Void).null, CDoom::Statenum::S_TFOG3, 0, 0},                    # S_TFOG2
    {CDoom::Spritenum::SPR_TFOG, 32770, 6, Pointer(Void).null, CDoom::Statenum::S_TFOG4, 0, 0},                    # S_TFOG3
    {CDoom::Spritenum::SPR_TFOG, 32771, 6, Pointer(Void).null, CDoom::Statenum::S_TFOG5, 0, 0},                    # S_TFOG4
    {CDoom::Spritenum::SPR_TFOG, 32772, 6, Pointer(Void).null, CDoom::Statenum::S_TFOG6, 0, 0},                    # S_TFOG5
    {CDoom::Spritenum::SPR_TFOG, 32773, 6, Pointer(Void).null, CDoom::Statenum::S_TFOG7, 0, 0},                    # S_TFOG6
    {CDoom::Spritenum::SPR_TFOG, 32774, 6, Pointer(Void).null, CDoom::Statenum::S_TFOG8, 0, 0},                    # S_TFOG7
    {CDoom::Spritenum::SPR_TFOG, 32775, 6, Pointer(Void).null, CDoom::Statenum::S_TFOG9, 0, 0},                    # S_TFOG8
    {CDoom::Spritenum::SPR_TFOG, 32776, 6, Pointer(Void).null, CDoom::Statenum::S_TFOG10, 0, 0},                   # S_TFOG9
    {CDoom::Spritenum::SPR_TFOG, 32777, 6, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                     # S_TFOG10
    {CDoom::Spritenum::SPR_IFOG, 32768, 6, Pointer(Void).null, CDoom::Statenum::S_IFOG01, 0, 0},                   # S_IFOG
    {CDoom::Spritenum::SPR_IFOG, 32769, 6, Pointer(Void).null, CDoom::Statenum::S_IFOG02, 0, 0},                   # S_IFOG01
    {CDoom::Spritenum::SPR_IFOG, 32768, 6, Pointer(Void).null, CDoom::Statenum::S_IFOG2, 0, 0},                    # S_IFOG02
    {CDoom::Spritenum::SPR_IFOG, 32769, 6, Pointer(Void).null, CDoom::Statenum::S_IFOG3, 0, 0},                    # S_IFOG2
    {CDoom::Spritenum::SPR_IFOG, 32770, 6, Pointer(Void).null, CDoom::Statenum::S_IFOG4, 0, 0},                    # S_IFOG3
    {CDoom::Spritenum::SPR_IFOG, 32771, 6, Pointer(Void).null, CDoom::Statenum::S_IFOG5, 0, 0},                    # S_IFOG4
    {CDoom::Spritenum::SPR_IFOG, 32772, 6, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                     # S_IFOG5
    {CDoom::Spritenum::SPR_PLAY, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_PLAY
    {CDoom::Spritenum::SPR_PLAY, 0, 4, Pointer(Void).null, CDoom::Statenum::S_PLAY_RUN2, 0, 0},                    # S_PLAY_RUN1
    {CDoom::Spritenum::SPR_PLAY, 1, 4, Pointer(Void).null, CDoom::Statenum::S_PLAY_RUN3, 0, 0},                    # S_PLAY_RUN2
    {CDoom::Spritenum::SPR_PLAY, 2, 4, Pointer(Void).null, CDoom::Statenum::S_PLAY_RUN4, 0, 0},                    # S_PLAY_RUN3
    {CDoom::Spritenum::SPR_PLAY, 3, 4, Pointer(Void).null, CDoom::Statenum::S_PLAY_RUN1, 0, 0},                    # S_PLAY_RUN4
    {CDoom::Spritenum::SPR_PLAY, 4, 12, Pointer(Void).null, CDoom::Statenum::S_PLAY, 0, 0},                        # S_PLAY_ATK1
    {CDoom::Spritenum::SPR_PLAY, 32773, 6, Pointer(Void).null, CDoom::Statenum::S_PLAY_ATK1, 0, 0},                # S_PLAY_ATK2
    {CDoom::Spritenum::SPR_PLAY, 6, 4, Pointer(Void).null, CDoom::Statenum::S_PLAY_PAIN2, 0, 0},                   # S_PLAY_PAIN
    {CDoom::Spritenum::SPR_PLAY, 6, 4, (->CDoom.a_pain).pointer, CDoom::Statenum::S_PLAY, 0, 0},                   # S_PLAY_PAIN2
    {CDoom::Spritenum::SPR_PLAY, 7, 10, Pointer(Void).null, CDoom::Statenum::S_PLAY_DIE2, 0, 0},                   # S_PLAY_DIE1
    {CDoom::Spritenum::SPR_PLAY, 8, 10, (->CDoom.a_player_scream).pointer, CDoom::Statenum::S_PLAY_DIE3, 0, 0},    # S_PLAY_DIE2
    {CDoom::Spritenum::SPR_PLAY, 9, 10, (->CDoom.a_fall).pointer, CDoom::Statenum::S_PLAY_DIE4, 0, 0},             # S_PLAY_DIE3
    {CDoom::Spritenum::SPR_PLAY, 10, 10, Pointer(Void).null, CDoom::Statenum::S_PLAY_DIE5, 0, 0},                  # S_PLAY_DIE4
    {CDoom::Spritenum::SPR_PLAY, 11, 10, Pointer(Void).null, CDoom::Statenum::S_PLAY_DIE6, 0, 0},                  # S_PLAY_DIE5
    {CDoom::Spritenum::SPR_PLAY, 12, 10, Pointer(Void).null, CDoom::Statenum::S_PLAY_DIE7, 0, 0},                  # S_PLAY_DIE6
    {CDoom::Spritenum::SPR_PLAY, 13, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                       # S_PLAY_DIE7
    {CDoom::Spritenum::SPR_PLAY, 14, 5, Pointer(Void).null, CDoom::Statenum::S_PLAY_XDIE2, 0, 0},                  # S_PLAY_XDIE1
    {CDoom::Spritenum::SPR_PLAY, 15, 5, (->CDoom.a_xscream).pointer, CDoom::Statenum::S_PLAY_XDIE3, 0, 0},         # S_PLAY_XDIE2
    {CDoom::Spritenum::SPR_PLAY, 16, 5, (->CDoom.a_fall).pointer, CDoom::Statenum::S_PLAY_XDIE4, 0, 0},            # S_PLAY_XDIE3
    {CDoom::Spritenum::SPR_PLAY, 17, 5, Pointer(Void).null, CDoom::Statenum::S_PLAY_XDIE5, 0, 0},                  # S_PLAY_XDIE4
    {CDoom::Spritenum::SPR_PLAY, 18, 5, Pointer(Void).null, CDoom::Statenum::S_PLAY_XDIE6, 0, 0},                  # S_PLAY_XDIE5
    {CDoom::Spritenum::SPR_PLAY, 19, 5, Pointer(Void).null, CDoom::Statenum::S_PLAY_XDIE7, 0, 0},                  # S_PLAY_XDIE6
    {CDoom::Spritenum::SPR_PLAY, 20, 5, Pointer(Void).null, CDoom::Statenum::S_PLAY_XDIE8, 0, 0},                  # S_PLAY_XDIE7
    {CDoom::Spritenum::SPR_PLAY, 21, 5, Pointer(Void).null, CDoom::Statenum::S_PLAY_XDIE9, 0, 0},                  # S_PLAY_XDIE8
    {CDoom::Spritenum::SPR_PLAY, 22, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                       # S_PLAY_XDIE9
    {CDoom::Spritenum::SPR_POSS, 0, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_POSS_STND2, 0, 0},            # S_POSS_STND
    {CDoom::Spritenum::SPR_POSS, 1, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_POSS_STND, 0, 0},             # S_POSS_STND2
    {CDoom::Spritenum::SPR_POSS, 0, 4, (->CDoom.a_chase).pointer, CDoom::Statenum::S_POSS_RUN2, 0, 0},             # S_POSS_RUN1
    {CDoom::Spritenum::SPR_POSS, 0, 4, (->CDoom.a_chase).pointer, CDoom::Statenum::S_POSS_RUN3, 0, 0},             # S_POSS_RUN2
    {CDoom::Spritenum::SPR_POSS, 1, 4, (->CDoom.a_chase).pointer, CDoom::Statenum::S_POSS_RUN4, 0, 0},             # S_POSS_RUN3
    {CDoom::Spritenum::SPR_POSS, 1, 4, (->CDoom.a_chase).pointer, CDoom::Statenum::S_POSS_RUN5, 0, 0},             # S_POSS_RUN4
    {CDoom::Spritenum::SPR_POSS, 2, 4, (->CDoom.a_chase).pointer, CDoom::Statenum::S_POSS_RUN6, 0, 0},             # S_POSS_RUN5
    {CDoom::Spritenum::SPR_POSS, 2, 4, (->CDoom.a_chase).pointer, CDoom::Statenum::S_POSS_RUN7, 0, 0},             # S_POSS_RUN6
    {CDoom::Spritenum::SPR_POSS, 3, 4, (->CDoom.a_chase).pointer, CDoom::Statenum::S_POSS_RUN8, 0, 0},             # S_POSS_RUN7
    {CDoom::Spritenum::SPR_POSS, 3, 4, (->CDoom.a_chase).pointer, CDoom::Statenum::S_POSS_RUN1, 0, 0},             # S_POSS_RUN8
    {CDoom::Spritenum::SPR_POSS, 4, 10, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_POSS_ATK2, 0, 0},      # S_POSS_ATK1
    {CDoom::Spritenum::SPR_POSS, 5, 8, (->CDoom.a_pos_attack).pointer, CDoom::Statenum::S_POSS_ATK3, 0, 0},        # S_POSS_ATK2
    {CDoom::Spritenum::SPR_POSS, 4, 8, Pointer(Void).null, CDoom::Statenum::S_POSS_RUN1, 0, 0},                    # S_POSS_ATK3
    {CDoom::Spritenum::SPR_POSS, 6, 3, Pointer(Void).null, CDoom::Statenum::S_POSS_PAIN2, 0, 0},                   # S_POSS_PAIN
    {CDoom::Spritenum::SPR_POSS, 6, 3, (->CDoom.a_pain).pointer, CDoom::Statenum::S_POSS_RUN1, 0, 0},              # S_POSS_PAIN2
    {CDoom::Spritenum::SPR_POSS, 7, 5, Pointer(Void).null, CDoom::Statenum::S_POSS_DIE2, 0, 0},                    # S_POSS_DIE1
    {CDoom::Spritenum::SPR_POSS, 8, 5, (->CDoom.a_scream).pointer, CDoom::Statenum::S_POSS_DIE3, 0, 0},            # S_POSS_DIE2
    {CDoom::Spritenum::SPR_POSS, 9, 5, (->CDoom.a_fall).pointer, CDoom::Statenum::S_POSS_DIE4, 0, 0},              # S_POSS_DIE3
    {CDoom::Spritenum::SPR_POSS, 10, 5, Pointer(Void).null, CDoom::Statenum::S_POSS_DIE5, 0, 0},                   # S_POSS_DIE4
    {CDoom::Spritenum::SPR_POSS, 11, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                       # S_POSS_DIE5
    {CDoom::Spritenum::SPR_POSS, 12, 5, Pointer(Void).null, CDoom::Statenum::S_POSS_XDIE2, 0, 0},                  # S_POSS_XDIE1
    {CDoom::Spritenum::SPR_POSS, 13, 5, (->CDoom.a_xscream).pointer, CDoom::Statenum::S_POSS_XDIE3, 0, 0},         # S_POSS_XDIE2
    {CDoom::Spritenum::SPR_POSS, 14, 5, (->CDoom.a_fall).pointer, CDoom::Statenum::S_POSS_XDIE4, 0, 0},            # S_POSS_XDIE3
    {CDoom::Spritenum::SPR_POSS, 15, 5, Pointer(Void).null, CDoom::Statenum::S_POSS_XDIE5, 0, 0},                  # S_POSS_XDIE4
    {CDoom::Spritenum::SPR_POSS, 16, 5, Pointer(Void).null, CDoom::Statenum::S_POSS_XDIE6, 0, 0},                  # S_POSS_XDIE5
    {CDoom::Spritenum::SPR_POSS, 17, 5, Pointer(Void).null, CDoom::Statenum::S_POSS_XDIE7, 0, 0},                  # S_POSS_XDIE6
    {CDoom::Spritenum::SPR_POSS, 18, 5, Pointer(Void).null, CDoom::Statenum::S_POSS_XDIE8, 0, 0},                  # S_POSS_XDIE7
    {CDoom::Spritenum::SPR_POSS, 19, 5, Pointer(Void).null, CDoom::Statenum::S_POSS_XDIE9, 0, 0},                  # S_POSS_XDIE8
    {CDoom::Spritenum::SPR_POSS, 20, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                       # S_POSS_XDIE9
    {CDoom::Spritenum::SPR_POSS, 10, 5, Pointer(Void).null, CDoom::Statenum::S_POSS_RAISE2, 0, 0},                 # S_POSS_RAISE1
    {CDoom::Spritenum::SPR_POSS, 9, 5, Pointer(Void).null, CDoom::Statenum::S_POSS_RAISE3, 0, 0},                  # S_POSS_RAISE2
    {CDoom::Spritenum::SPR_POSS, 8, 5, Pointer(Void).null, CDoom::Statenum::S_POSS_RAISE4, 0, 0},                  # S_POSS_RAISE3
    {CDoom::Spritenum::SPR_POSS, 7, 5, Pointer(Void).null, CDoom::Statenum::S_POSS_RUN1, 0, 0},                    # S_POSS_RAISE4
    {CDoom::Spritenum::SPR_SPOS, 0, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_SPOS_STND2, 0, 0},            # S_SPOS_STND
    {CDoom::Spritenum::SPR_SPOS, 1, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_SPOS_STND, 0, 0},             # S_SPOS_STND2
    {CDoom::Spritenum::SPR_SPOS, 0, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SPOS_RUN2, 0, 0},             # S_SPOS_RUN1
    {CDoom::Spritenum::SPR_SPOS, 0, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SPOS_RUN3, 0, 0},             # S_SPOS_RUN2
    {CDoom::Spritenum::SPR_SPOS, 1, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SPOS_RUN4, 0, 0},             # S_SPOS_RUN3
    {CDoom::Spritenum::SPR_SPOS, 1, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SPOS_RUN5, 0, 0},             # S_SPOS_RUN4
    {CDoom::Spritenum::SPR_SPOS, 2, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SPOS_RUN6, 0, 0},             # S_SPOS_RUN5
    {CDoom::Spritenum::SPR_SPOS, 2, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SPOS_RUN7, 0, 0},             # S_SPOS_RUN6
    {CDoom::Spritenum::SPR_SPOS, 3, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SPOS_RUN8, 0, 0},             # S_SPOS_RUN7
    {CDoom::Spritenum::SPR_SPOS, 3, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SPOS_RUN1, 0, 0},             # S_SPOS_RUN8
    {CDoom::Spritenum::SPR_SPOS, 4, 10, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_SPOS_ATK2, 0, 0},      # S_SPOS_ATK1
    {CDoom::Spritenum::SPR_SPOS, 32773, 10, (->CDoom.a_spos_attack).pointer, CDoom::Statenum::S_SPOS_ATK3, 0, 0},  # S_SPOS_ATK2
    {CDoom::Spritenum::SPR_SPOS, 4, 10, Pointer(Void).null, CDoom::Statenum::S_SPOS_RUN1, 0, 0},                   # S_SPOS_ATK3
    {CDoom::Spritenum::SPR_SPOS, 6, 3, Pointer(Void).null, CDoom::Statenum::S_SPOS_PAIN2, 0, 0},                   # S_SPOS_PAIN
    {CDoom::Spritenum::SPR_SPOS, 6, 3, (->CDoom.a_pain).pointer, CDoom::Statenum::S_SPOS_RUN1, 0, 0},              # S_SPOS_PAIN2
    {CDoom::Spritenum::SPR_SPOS, 7, 5, Pointer(Void).null, CDoom::Statenum::S_SPOS_DIE2, 0, 0},                    # S_SPOS_DIE1
    {CDoom::Spritenum::SPR_SPOS, 8, 5, (->CDoom.a_scream).pointer, CDoom::Statenum::S_SPOS_DIE3, 0, 0},            # S_SPOS_DIE2
    {CDoom::Spritenum::SPR_SPOS, 9, 5, (->CDoom.a_fall).pointer, CDoom::Statenum::S_SPOS_DIE4, 0, 0},              # S_SPOS_DIE3
    {CDoom::Spritenum::SPR_SPOS, 10, 5, Pointer(Void).null, CDoom::Statenum::S_SPOS_DIE5, 0, 0},                   # S_SPOS_DIE4
    {CDoom::Spritenum::SPR_SPOS, 11, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                       # S_SPOS_DIE5
    {CDoom::Spritenum::SPR_SPOS, 12, 5, Pointer(Void).null, CDoom::Statenum::S_SPOS_XDIE2, 0, 0},                  # S_SPOS_XDIE1
    {CDoom::Spritenum::SPR_SPOS, 13, 5, (->CDoom.a_xscream).pointer, CDoom::Statenum::S_SPOS_XDIE3, 0, 0},         # S_SPOS_XDIE2
    {CDoom::Spritenum::SPR_SPOS, 14, 5, (->CDoom.a_fall).pointer, CDoom::Statenum::S_SPOS_XDIE4, 0, 0},            # S_SPOS_XDIE3
    {CDoom::Spritenum::SPR_SPOS, 15, 5, Pointer(Void).null, CDoom::Statenum::S_SPOS_XDIE5, 0, 0},                  # S_SPOS_XDIE4
    {CDoom::Spritenum::SPR_SPOS, 16, 5, Pointer(Void).null, CDoom::Statenum::S_SPOS_XDIE6, 0, 0},                  # S_SPOS_XDIE5
    {CDoom::Spritenum::SPR_SPOS, 17, 5, Pointer(Void).null, CDoom::Statenum::S_SPOS_XDIE7, 0, 0},                  # S_SPOS_XDIE6
    {CDoom::Spritenum::SPR_SPOS, 18, 5, Pointer(Void).null, CDoom::Statenum::S_SPOS_XDIE8, 0, 0},                  # S_SPOS_XDIE7
    {CDoom::Spritenum::SPR_SPOS, 19, 5, Pointer(Void).null, CDoom::Statenum::S_SPOS_XDIE9, 0, 0},                  # S_SPOS_XDIE8
    {CDoom::Spritenum::SPR_SPOS, 20, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                       # S_SPOS_XDIE9
    {CDoom::Spritenum::SPR_SPOS, 11, 5, Pointer(Void).null, CDoom::Statenum::S_SPOS_RAISE2, 0, 0},                 # S_SPOS_RAISE1
    {CDoom::Spritenum::SPR_SPOS, 10, 5, Pointer(Void).null, CDoom::Statenum::S_SPOS_RAISE3, 0, 0},                 # S_SPOS_RAISE2
    {CDoom::Spritenum::SPR_SPOS, 9, 5, Pointer(Void).null, CDoom::Statenum::S_SPOS_RAISE4, 0, 0},                  # S_SPOS_RAISE3
    {CDoom::Spritenum::SPR_SPOS, 8, 5, Pointer(Void).null, CDoom::Statenum::S_SPOS_RAISE5, 0, 0},                  # S_SPOS_RAISE4
    {CDoom::Spritenum::SPR_SPOS, 7, 5, Pointer(Void).null, CDoom::Statenum::S_SPOS_RUN1, 0, 0},                    # S_SPOS_RAISE5
    {CDoom::Spritenum::SPR_VILE, 0, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_VILE_STND2, 0, 0},            # S_VILE_STND
    {CDoom::Spritenum::SPR_VILE, 1, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_VILE_STND, 0, 0},             # S_VILE_STND2
    {CDoom::Spritenum::SPR_VILE, 0, 2, (->CDoom.a_vile_chase).pointer, CDoom::Statenum::S_VILE_RUN2, 0, 0},        # S_VILE_RUN1
    {CDoom::Spritenum::SPR_VILE, 0, 2, (->CDoom.a_vile_chase).pointer, CDoom::Statenum::S_VILE_RUN3, 0, 0},        # S_VILE_RUN2
    {CDoom::Spritenum::SPR_VILE, 1, 2, (->CDoom.a_vile_chase).pointer, CDoom::Statenum::S_VILE_RUN4, 0, 0},        # S_VILE_RUN3
    {CDoom::Spritenum::SPR_VILE, 1, 2, (->CDoom.a_vile_chase).pointer, CDoom::Statenum::S_VILE_RUN5, 0, 0},        # S_VILE_RUN4
    {CDoom::Spritenum::SPR_VILE, 2, 2, (->CDoom.a_vile_chase).pointer, CDoom::Statenum::S_VILE_RUN6, 0, 0},        # S_VILE_RUN5
    {CDoom::Spritenum::SPR_VILE, 2, 2, (->CDoom.a_vile_chase).pointer, CDoom::Statenum::S_VILE_RUN7, 0, 0},        # S_VILE_RUN6
    {CDoom::Spritenum::SPR_VILE, 3, 2, (->CDoom.a_vile_chase).pointer, CDoom::Statenum::S_VILE_RUN8, 0, 0},        # S_VILE_RUN7
    {CDoom::Spritenum::SPR_VILE, 3, 2, (->CDoom.a_vile_chase).pointer, CDoom::Statenum::S_VILE_RUN9, 0, 0},        # S_VILE_RUN8
    {CDoom::Spritenum::SPR_VILE, 4, 2, (->CDoom.a_vile_chase).pointer, CDoom::Statenum::S_VILE_RUN10, 0, 0},       # S_VILE_RUN9
    {CDoom::Spritenum::SPR_VILE, 4, 2, (->CDoom.a_vile_chase).pointer, CDoom::Statenum::S_VILE_RUN11, 0, 0},       # S_VILE_RUN10
    {CDoom::Spritenum::SPR_VILE, 5, 2, (->CDoom.a_vile_chase).pointer, CDoom::Statenum::S_VILE_RUN12, 0, 0},       # S_VILE_RUN11
    {CDoom::Spritenum::SPR_VILE, 5, 2, (->CDoom.a_vile_chase).pointer, CDoom::Statenum::S_VILE_RUN1, 0, 0},        # S_VILE_RUN12
    {CDoom::Spritenum::SPR_VILE, 32774, 0, (->CDoom.a_vile_start).pointer, CDoom::Statenum::S_VILE_ATK2, 0, 0},    # S_VILE_ATK1
    {CDoom::Spritenum::SPR_VILE, 32774, 10, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_VILE_ATK3, 0, 0},  # S_VILE_ATK2
    {CDoom::Spritenum::SPR_VILE, 32775, 8, (->CDoom.a_vile_target).pointer, CDoom::Statenum::S_VILE_ATK4, 0, 0},   # S_VILE_ATK3
    {CDoom::Spritenum::SPR_VILE, 32776, 8, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_VILE_ATK5, 0, 0},   # S_VILE_ATK4
    {CDoom::Spritenum::SPR_VILE, 32777, 8, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_VILE_ATK6, 0, 0},   # S_VILE_ATK5
    {CDoom::Spritenum::SPR_VILE, 32778, 8, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_VILE_ATK7, 0, 0},   # S_VILE_ATK6
    {CDoom::Spritenum::SPR_VILE, 32779, 8, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_VILE_ATK8, 0, 0},   # S_VILE_ATK7
    {CDoom::Spritenum::SPR_VILE, 32780, 8, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_VILE_ATK9, 0, 0},   # S_VILE_ATK8
    {CDoom::Spritenum::SPR_VILE, 32781, 8, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_VILE_ATK10, 0, 0},  # S_VILE_ATK9
    {CDoom::Spritenum::SPR_VILE, 32782, 8, (->CDoom.a_vile_attack).pointer, CDoom::Statenum::S_VILE_ATK11, 0, 0},  # S_VILE_ATK10
    {CDoom::Spritenum::SPR_VILE, 32783, 20, Pointer(Void).null, CDoom::Statenum::S_VILE_RUN1, 0, 0},               # S_VILE_ATK11
    {CDoom::Spritenum::SPR_VILE, 32794, 10, Pointer(Void).null, CDoom::Statenum::S_VILE_HEAL2, 0, 0},              # S_VILE_HEAL1
    {CDoom::Spritenum::SPR_VILE, 32795, 10, Pointer(Void).null, CDoom::Statenum::S_VILE_HEAL3, 0, 0},              # S_VILE_HEAL2
    {CDoom::Spritenum::SPR_VILE, 32796, 10, Pointer(Void).null, CDoom::Statenum::S_VILE_RUN1, 0, 0},               # S_VILE_HEAL3
    {CDoom::Spritenum::SPR_VILE, 16, 5, Pointer(Void).null, CDoom::Statenum::S_VILE_PAIN2, 0, 0},                  # S_VILE_PAIN
    {CDoom::Spritenum::SPR_VILE, 16, 5, (->CDoom.a_pain).pointer, CDoom::Statenum::S_VILE_RUN1, 0, 0},             # S_VILE_PAIN2
    {CDoom::Spritenum::SPR_VILE, 16, 7, Pointer(Void).null, CDoom::Statenum::S_VILE_DIE2, 0, 0},                   # S_VILE_DIE1
    {CDoom::Spritenum::SPR_VILE, 17, 7, (->CDoom.a_scream).pointer, CDoom::Statenum::S_VILE_DIE3, 0, 0},           # S_VILE_DIE2
    {CDoom::Spritenum::SPR_VILE, 18, 7, (->CDoom.a_fall).pointer, CDoom::Statenum::S_VILE_DIE4, 0, 0},             # S_VILE_DIE3
    {CDoom::Spritenum::SPR_VILE, 19, 7, Pointer(Void).null, CDoom::Statenum::S_VILE_DIE5, 0, 0},                   # S_VILE_DIE4
    {CDoom::Spritenum::SPR_VILE, 20, 7, Pointer(Void).null, CDoom::Statenum::S_VILE_DIE6, 0, 0},                   # S_VILE_DIE5
    {CDoom::Spritenum::SPR_VILE, 21, 7, Pointer(Void).null, CDoom::Statenum::S_VILE_DIE7, 0, 0},                   # S_VILE_DIE6
    {CDoom::Spritenum::SPR_VILE, 22, 7, Pointer(Void).null, CDoom::Statenum::S_VILE_DIE8, 0, 0},                   # S_VILE_DIE7
    {CDoom::Spritenum::SPR_VILE, 23, 5, Pointer(Void).null, CDoom::Statenum::S_VILE_DIE9, 0, 0},                   # S_VILE_DIE8
    {CDoom::Spritenum::SPR_VILE, 24, 5, Pointer(Void).null, CDoom::Statenum::S_VILE_DIE10, 0, 0},                  # S_VILE_DIE9
    {CDoom::Spritenum::SPR_VILE, 25, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                       # S_VILE_DIE10
    {CDoom::Spritenum::SPR_FIRE, 32768, 2, (->CDoom.a_start_fire).pointer, CDoom::Statenum::S_FIRE2, 0, 0},        # S_FIRE1
    {CDoom::Spritenum::SPR_FIRE, 32769, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_FIRE3, 0, 0},              # S_FIRE2
    {CDoom::Spritenum::SPR_FIRE, 32768, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_FIRE4, 0, 0},              # S_FIRE3
    {CDoom::Spritenum::SPR_FIRE, 32769, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_FIRE5, 0, 0},              # S_FIRE4
    {CDoom::Spritenum::SPR_FIRE, 32770, 2, (->CDoom.a_fire_crackle).pointer, CDoom::Statenum::S_FIRE6, 0, 0},      # S_FIRE5
    {CDoom::Spritenum::SPR_FIRE, 32769, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_FIRE7, 0, 0},              # S_FIRE6
    {CDoom::Spritenum::SPR_FIRE, 32770, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_FIRE8, 0, 0},              # S_FIRE7
    {CDoom::Spritenum::SPR_FIRE, 32769, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_FIRE9, 0, 0},              # S_FIRE8
    {CDoom::Spritenum::SPR_FIRE, 32770, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_FIRE10, 0, 0},             # S_FIRE9
    {CDoom::Spritenum::SPR_FIRE, 32771, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_FIRE11, 0, 0},             # S_FIRE10
    {CDoom::Spritenum::SPR_FIRE, 32770, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_FIRE12, 0, 0},             # S_FIRE11
    {CDoom::Spritenum::SPR_FIRE, 32771, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_FIRE13, 0, 0},             # S_FIRE12
    {CDoom::Spritenum::SPR_FIRE, 32770, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_FIRE14, 0, 0},             # S_FIRE13
    {CDoom::Spritenum::SPR_FIRE, 32771, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_FIRE15, 0, 0},             # S_FIRE14
    {CDoom::Spritenum::SPR_FIRE, 32772, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_FIRE16, 0, 0},             # S_FIRE15
    {CDoom::Spritenum::SPR_FIRE, 32771, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_FIRE17, 0, 0},             # S_FIRE16
    {CDoom::Spritenum::SPR_FIRE, 32772, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_FIRE18, 0, 0},             # S_FIRE17
    {CDoom::Spritenum::SPR_FIRE, 32771, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_FIRE19, 0, 0},             # S_FIRE18
    {CDoom::Spritenum::SPR_FIRE, 32772, 2, (->CDoom.a_fire_crackle).pointer, CDoom::Statenum::S_FIRE20, 0, 0},     # S_FIRE19
    {CDoom::Spritenum::SPR_FIRE, 32773, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_FIRE21, 0, 0},             # S_FIRE20
    {CDoom::Spritenum::SPR_FIRE, 32772, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_FIRE22, 0, 0},             # S_FIRE21
    {CDoom::Spritenum::SPR_FIRE, 32773, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_FIRE23, 0, 0},             # S_FIRE22
    {CDoom::Spritenum::SPR_FIRE, 32772, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_FIRE24, 0, 0},             # S_FIRE23
    {CDoom::Spritenum::SPR_FIRE, 32773, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_FIRE25, 0, 0},             # S_FIRE24
    {CDoom::Spritenum::SPR_FIRE, 32774, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_FIRE26, 0, 0},             # S_FIRE25
    {CDoom::Spritenum::SPR_FIRE, 32775, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_FIRE27, 0, 0},             # S_FIRE26
    {CDoom::Spritenum::SPR_FIRE, 32774, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_FIRE28, 0, 0},             # S_FIRE27
    {CDoom::Spritenum::SPR_FIRE, 32775, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_FIRE29, 0, 0},             # S_FIRE28
    {CDoom::Spritenum::SPR_FIRE, 32774, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_FIRE30, 0, 0},             # S_FIRE29
    {CDoom::Spritenum::SPR_FIRE, 32775, 2, (->CDoom.a_fire).pointer, CDoom::Statenum::S_NULL, 0, 0},               # S_FIRE30
    {CDoom::Spritenum::SPR_PUFF, 1, 4, Pointer(Void).null, CDoom::Statenum::S_SMOKE2, 0, 0},                       # S_SMOKE1
    {CDoom::Spritenum::SPR_PUFF, 2, 4, Pointer(Void).null, CDoom::Statenum::S_SMOKE3, 0, 0},                       # S_SMOKE2
    {CDoom::Spritenum::SPR_PUFF, 1, 4, Pointer(Void).null, CDoom::Statenum::S_SMOKE4, 0, 0},                       # S_SMOKE3
    {CDoom::Spritenum::SPR_PUFF, 2, 4, Pointer(Void).null, CDoom::Statenum::S_SMOKE5, 0, 0},                       # S_SMOKE4
    {CDoom::Spritenum::SPR_PUFF, 3, 4, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                         # S_SMOKE5
    {CDoom::Spritenum::SPR_FATB, 32768, 2, (->CDoom.a_tracer).pointer, CDoom::Statenum::S_TRACER2, 0, 0},          # S_TRACER
    {CDoom::Spritenum::SPR_FATB, 32769, 2, (->CDoom.a_tracer).pointer, CDoom::Statenum::S_TRACER, 0, 0},           # S_TRACER2
    {CDoom::Spritenum::SPR_FBXP, 32768, 8, Pointer(Void).null, CDoom::Statenum::S_TRACEEXP2, 0, 0},                # S_TRACEEXP1
    {CDoom::Spritenum::SPR_FBXP, 32769, 6, Pointer(Void).null, CDoom::Statenum::S_TRACEEXP3, 0, 0},                # S_TRACEEXP2
    {CDoom::Spritenum::SPR_FBXP, 32770, 4, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                     # S_TRACEEXP3
    {CDoom::Spritenum::SPR_SKEL, 0, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_SKEL_STND2, 0, 0},            # S_SKEL_STND
    {CDoom::Spritenum::SPR_SKEL, 1, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_SKEL_STND, 0, 0},             # S_SKEL_STND2
    {CDoom::Spritenum::SPR_SKEL, 0, 2, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SKEL_RUN2, 0, 0},             # S_SKEL_RUN1
    {CDoom::Spritenum::SPR_SKEL, 0, 2, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SKEL_RUN3, 0, 0},             # S_SKEL_RUN2
    {CDoom::Spritenum::SPR_SKEL, 1, 2, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SKEL_RUN4, 0, 0},             # S_SKEL_RUN3
    {CDoom::Spritenum::SPR_SKEL, 1, 2, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SKEL_RUN5, 0, 0},             # S_SKEL_RUN4
    {CDoom::Spritenum::SPR_SKEL, 2, 2, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SKEL_RUN6, 0, 0},             # S_SKEL_RUN5
    {CDoom::Spritenum::SPR_SKEL, 2, 2, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SKEL_RUN7, 0, 0},             # S_SKEL_RUN6
    {CDoom::Spritenum::SPR_SKEL, 3, 2, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SKEL_RUN8, 0, 0},             # S_SKEL_RUN7
    {CDoom::Spritenum::SPR_SKEL, 3, 2, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SKEL_RUN9, 0, 0},             # S_SKEL_RUN8
    {CDoom::Spritenum::SPR_SKEL, 4, 2, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SKEL_RUN10, 0, 0},            # S_SKEL_RUN9
    {CDoom::Spritenum::SPR_SKEL, 4, 2, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SKEL_RUN11, 0, 0},            # S_SKEL_RUN10
    {CDoom::Spritenum::SPR_SKEL, 5, 2, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SKEL_RUN12, 0, 0},            # S_SKEL_RUN11
    {CDoom::Spritenum::SPR_SKEL, 5, 2, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SKEL_RUN1, 0, 0},             # S_SKEL_RUN12
    {CDoom::Spritenum::SPR_SKEL, 6, 0, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_SKEL_FIST2, 0, 0},      # S_SKEL_FIST1
    {CDoom::Spritenum::SPR_SKEL, 6, 6, (->CDoom.a_skel_whoosh).pointer, CDoom::Statenum::S_SKEL_FIST3, 0, 0},      # S_SKEL_FIST2
    {CDoom::Spritenum::SPR_SKEL, 7, 6, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_SKEL_FIST4, 0, 0},      # S_SKEL_FIST3
    {CDoom::Spritenum::SPR_SKEL, 8, 6, (->CDoom.a_skel_fist).pointer, CDoom::Statenum::S_SKEL_RUN1, 0, 0},         # S_SKEL_FIST4
    {CDoom::Spritenum::SPR_SKEL, 32777, 0, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_SKEL_MISS2, 0, 0},  # S_SKEL_MISS1
    {CDoom::Spritenum::SPR_SKEL, 32777, 10, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_SKEL_MISS3, 0, 0}, # S_SKEL_MISS2
    {CDoom::Spritenum::SPR_SKEL, 10, 10, (->CDoom.a_skel_missile).pointer, CDoom::Statenum::S_SKEL_MISS4, 0, 0},   # S_SKEL_MISS3
    {CDoom::Spritenum::SPR_SKEL, 10, 10, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_SKEL_RUN1, 0, 0},     # S_SKEL_MISS4
    {CDoom::Spritenum::SPR_SKEL, 11, 5, Pointer(Void).null, CDoom::Statenum::S_SKEL_PAIN2, 0, 0},                  # S_SKEL_PAIN
    {CDoom::Spritenum::SPR_SKEL, 11, 5, (->CDoom.a_pain).pointer, CDoom::Statenum::S_SKEL_RUN1, 0, 0},             # S_SKEL_PAIN2
    {CDoom::Spritenum::SPR_SKEL, 11, 7, Pointer(Void).null, CDoom::Statenum::S_SKEL_DIE2, 0, 0},                   # S_SKEL_DIE1
    {CDoom::Spritenum::SPR_SKEL, 12, 7, Pointer(Void).null, CDoom::Statenum::S_SKEL_DIE3, 0, 0},                   # S_SKEL_DIE2
    {CDoom::Spritenum::SPR_SKEL, 13, 7, (->CDoom.a_scream).pointer, CDoom::Statenum::S_SKEL_DIE4, 0, 0},           # S_SKEL_DIE3
    {CDoom::Spritenum::SPR_SKEL, 14, 7, (->CDoom.a_fall).pointer, CDoom::Statenum::S_SKEL_DIE5, 0, 0},             # S_SKEL_DIE4
    {CDoom::Spritenum::SPR_SKEL, 15, 7, Pointer(Void).null, CDoom::Statenum::S_SKEL_DIE6, 0, 0},                   # S_SKEL_DIE5
    {CDoom::Spritenum::SPR_SKEL, 16, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                       # S_SKEL_DIE6
    {CDoom::Spritenum::SPR_SKEL, 16, 5, Pointer(Void).null, CDoom::Statenum::S_SKEL_RAISE2, 0, 0},                 # S_SKEL_RAISE1
    {CDoom::Spritenum::SPR_SKEL, 15, 5, Pointer(Void).null, CDoom::Statenum::S_SKEL_RAISE3, 0, 0},                 # S_SKEL_RAISE2
    {CDoom::Spritenum::SPR_SKEL, 14, 5, Pointer(Void).null, CDoom::Statenum::S_SKEL_RAISE4, 0, 0},                 # S_SKEL_RAISE3
    {CDoom::Spritenum::SPR_SKEL, 13, 5, Pointer(Void).null, CDoom::Statenum::S_SKEL_RAISE5, 0, 0},                 # S_SKEL_RAISE4
    {CDoom::Spritenum::SPR_SKEL, 12, 5, Pointer(Void).null, CDoom::Statenum::S_SKEL_RAISE6, 0, 0},                 # S_SKEL_RAISE5
    {CDoom::Spritenum::SPR_SKEL, 11, 5, Pointer(Void).null, CDoom::Statenum::S_SKEL_RUN1, 0, 0},                   # S_SKEL_RAISE6
    {CDoom::Spritenum::SPR_MANF, 32768, 4, Pointer(Void).null, CDoom::Statenum::S_FATSHOT2, 0, 0},                 # S_FATSHOT1
    {CDoom::Spritenum::SPR_MANF, 32769, 4, Pointer(Void).null, CDoom::Statenum::S_FATSHOT1, 0, 0},                 # S_FATSHOT2
    {CDoom::Spritenum::SPR_MISL, 32769, 8, Pointer(Void).null, CDoom::Statenum::S_FATSHOTX2, 0, 0},                # S_FATSHOTX1
    {CDoom::Spritenum::SPR_MISL, 32770, 6, Pointer(Void).null, CDoom::Statenum::S_FATSHOTX3, 0, 0},                # S_FATSHOTX2
    {CDoom::Spritenum::SPR_MISL, 32771, 4, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                     # S_FATSHOTX3
    {CDoom::Spritenum::SPR_FATT, 0, 15, (->CDoom.a_look).pointer, CDoom::Statenum::S_FATT_STND2, 0, 0},            # S_FATT_STND
    {CDoom::Spritenum::SPR_FATT, 1, 15, (->CDoom.a_look).pointer, CDoom::Statenum::S_FATT_STND, 0, 0},             # S_FATT_STND2
    {CDoom::Spritenum::SPR_FATT, 0, 4, (->CDoom.a_chase).pointer, CDoom::Statenum::S_FATT_RUN2, 0, 0},             # S_FATT_RUN1
    {CDoom::Spritenum::SPR_FATT, 0, 4, (->CDoom.a_chase).pointer, CDoom::Statenum::S_FATT_RUN3, 0, 0},             # S_FATT_RUN2
    {CDoom::Spritenum::SPR_FATT, 1, 4, (->CDoom.a_chase).pointer, CDoom::Statenum::S_FATT_RUN4, 0, 0},             # S_FATT_RUN3
    {CDoom::Spritenum::SPR_FATT, 1, 4, (->CDoom.a_chase).pointer, CDoom::Statenum::S_FATT_RUN5, 0, 0},             # S_FATT_RUN4
    {CDoom::Spritenum::SPR_FATT, 2, 4, (->CDoom.a_chase).pointer, CDoom::Statenum::S_FATT_RUN6, 0, 0},             # S_FATT_RUN5
    {CDoom::Spritenum::SPR_FATT, 2, 4, (->CDoom.a_chase).pointer, CDoom::Statenum::S_FATT_RUN7, 0, 0},             # S_FATT_RUN6
    {CDoom::Spritenum::SPR_FATT, 3, 4, (->CDoom.a_chase).pointer, CDoom::Statenum::S_FATT_RUN8, 0, 0},             # S_FATT_RUN7
    {CDoom::Spritenum::SPR_FATT, 3, 4, (->CDoom.a_chase).pointer, CDoom::Statenum::S_FATT_RUN9, 0, 0},             # S_FATT_RUN8
    {CDoom::Spritenum::SPR_FATT, 4, 4, (->CDoom.a_chase).pointer, CDoom::Statenum::S_FATT_RUN10, 0, 0},            # S_FATT_RUN9
    {CDoom::Spritenum::SPR_FATT, 4, 4, (->CDoom.a_chase).pointer, CDoom::Statenum::S_FATT_RUN11, 0, 0},            # S_FATT_RUN10
    {CDoom::Spritenum::SPR_FATT, 5, 4, (->CDoom.a_chase).pointer, CDoom::Statenum::S_FATT_RUN12, 0, 0},            # S_FATT_RUN11
    {CDoom::Spritenum::SPR_FATT, 5, 4, (->CDoom.a_chase).pointer, CDoom::Statenum::S_FATT_RUN1, 0, 0},             # S_FATT_RUN12
    {CDoom::Spritenum::SPR_FATT, 6, 20, (->CDoom.a_fat_raise).pointer, CDoom::Statenum::S_FATT_ATK2, 0, 0},        # S_FATT_ATK1
    {CDoom::Spritenum::SPR_FATT, 32775, 10, (->CDoom.a_fat_attack1).pointer, CDoom::Statenum::S_FATT_ATK3, 0, 0},  # S_FATT_ATK2
    {CDoom::Spritenum::SPR_FATT, 8, 5, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_FATT_ATK4, 0, 0},       # S_FATT_ATK3
    {CDoom::Spritenum::SPR_FATT, 6, 5, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_FATT_ATK5, 0, 0},       # S_FATT_ATK4
    {CDoom::Spritenum::SPR_FATT, 32775, 10, (->CDoom.a_fat_attack2).pointer, CDoom::Statenum::S_FATT_ATK6, 0, 0},  # S_FATT_ATK5
    {CDoom::Spritenum::SPR_FATT, 8, 5, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_FATT_ATK7, 0, 0},       # S_FATT_ATK6
    {CDoom::Spritenum::SPR_FATT, 6, 5, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_FATT_ATK8, 0, 0},       # S_FATT_ATK7
    {CDoom::Spritenum::SPR_FATT, 32775, 10, (->CDoom.a_fat_attack3).pointer, CDoom::Statenum::S_FATT_ATK9, 0, 0},  # S_FATT_ATK8
    {CDoom::Spritenum::SPR_FATT, 8, 5, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_FATT_ATK10, 0, 0},      # S_FATT_ATK9
    {CDoom::Spritenum::SPR_FATT, 6, 5, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_FATT_RUN1, 0, 0},       # S_FATT_ATK10
    {CDoom::Spritenum::SPR_FATT, 9, 3, Pointer(Void).null, CDoom::Statenum::S_FATT_PAIN2, 0, 0},                   # S_FATT_PAIN
    {CDoom::Spritenum::SPR_FATT, 9, 3, (->CDoom.a_pain).pointer, CDoom::Statenum::S_FATT_RUN1, 0, 0},              # S_FATT_PAIN2
    {CDoom::Spritenum::SPR_FATT, 10, 6, Pointer(Void).null, CDoom::Statenum::S_FATT_DIE2, 0, 0},                   # S_FATT_DIE1
    {CDoom::Spritenum::SPR_FATT, 11, 6, (->CDoom.a_scream).pointer, CDoom::Statenum::S_FATT_DIE3, 0, 0},           # S_FATT_DIE2
    {CDoom::Spritenum::SPR_FATT, 12, 6, (->CDoom.a_fall).pointer, CDoom::Statenum::S_FATT_DIE4, 0, 0},             # S_FATT_DIE3
    {CDoom::Spritenum::SPR_FATT, 13, 6, Pointer(Void).null, CDoom::Statenum::S_FATT_DIE5, 0, 0},                   # S_FATT_DIE4
    {CDoom::Spritenum::SPR_FATT, 14, 6, Pointer(Void).null, CDoom::Statenum::S_FATT_DIE6, 0, 0},                   # S_FATT_DIE5
    {CDoom::Spritenum::SPR_FATT, 15, 6, Pointer(Void).null, CDoom::Statenum::S_FATT_DIE7, 0, 0},                   # S_FATT_DIE6
    {CDoom::Spritenum::SPR_FATT, 16, 6, Pointer(Void).null, CDoom::Statenum::S_FATT_DIE8, 0, 0},                   # S_FATT_DIE7
    {CDoom::Spritenum::SPR_FATT, 17, 6, Pointer(Void).null, CDoom::Statenum::S_FATT_DIE9, 0, 0},                   # S_FATT_DIE8
    {CDoom::Spritenum::SPR_FATT, 18, 6, Pointer(Void).null, CDoom::Statenum::S_FATT_DIE10, 0, 0},                  # S_FATT_DIE9
    {CDoom::Spritenum::SPR_FATT, 19, -1, (->CDoom.a_boss_death).pointer, CDoom::Statenum::S_NULL, 0, 0},           # S_FATT_DIE10
    {CDoom::Spritenum::SPR_FATT, 17, 5, Pointer(Void).null, CDoom::Statenum::S_FATT_RAISE2, 0, 0},                 # S_FATT_RAISE1
    {CDoom::Spritenum::SPR_FATT, 16, 5, Pointer(Void).null, CDoom::Statenum::S_FATT_RAISE3, 0, 0},                 # S_FATT_RAISE2
    {CDoom::Spritenum::SPR_FATT, 15, 5, Pointer(Void).null, CDoom::Statenum::S_FATT_RAISE4, 0, 0},                 # S_FATT_RAISE3
    {CDoom::Spritenum::SPR_FATT, 14, 5, Pointer(Void).null, CDoom::Statenum::S_FATT_RAISE5, 0, 0},                 # S_FATT_RAISE4
    {CDoom::Spritenum::SPR_FATT, 13, 5, Pointer(Void).null, CDoom::Statenum::S_FATT_RAISE6, 0, 0},                 # S_FATT_RAISE5
    {CDoom::Spritenum::SPR_FATT, 12, 5, Pointer(Void).null, CDoom::Statenum::S_FATT_RAISE7, 0, 0},                 # S_FATT_RAISE6
    {CDoom::Spritenum::SPR_FATT, 11, 5, Pointer(Void).null, CDoom::Statenum::S_FATT_RAISE8, 0, 0},                 # S_FATT_RAISE7
    {CDoom::Spritenum::SPR_FATT, 10, 5, Pointer(Void).null, CDoom::Statenum::S_FATT_RUN1, 0, 0},                   # S_FATT_RAISE8
    {CDoom::Spritenum::SPR_CPOS, 0, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_CPOS_STND2, 0, 0},            # S_CPOS_STND
    {CDoom::Spritenum::SPR_CPOS, 1, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_CPOS_STND, 0, 0},             # S_CPOS_STND2
    {CDoom::Spritenum::SPR_CPOS, 0, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_CPOS_RUN2, 0, 0},             # S_CPOS_RUN1
    {CDoom::Spritenum::SPR_CPOS, 0, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_CPOS_RUN3, 0, 0},             # S_CPOS_RUN2
    {CDoom::Spritenum::SPR_CPOS, 1, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_CPOS_RUN4, 0, 0},             # S_CPOS_RUN3
    {CDoom::Spritenum::SPR_CPOS, 1, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_CPOS_RUN5, 0, 0},             # S_CPOS_RUN4
    {CDoom::Spritenum::SPR_CPOS, 2, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_CPOS_RUN6, 0, 0},             # S_CPOS_RUN5
    {CDoom::Spritenum::SPR_CPOS, 2, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_CPOS_RUN7, 0, 0},             # S_CPOS_RUN6
    {CDoom::Spritenum::SPR_CPOS, 3, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_CPOS_RUN8, 0, 0},             # S_CPOS_RUN7
    {CDoom::Spritenum::SPR_CPOS, 3, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_CPOS_RUN1, 0, 0},             # S_CPOS_RUN8
    {CDoom::Spritenum::SPR_CPOS, 4, 10, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_CPOS_ATK2, 0, 0},      # S_CPOS_ATK1
    {CDoom::Spritenum::SPR_CPOS, 32773, 4, (->CDoom.a_cpos_attack).pointer, CDoom::Statenum::S_CPOS_ATK3, 0, 0},   # S_CPOS_ATK2
    {CDoom::Spritenum::SPR_CPOS, 32772, 4, (->CDoom.a_cpos_attack).pointer, CDoom::Statenum::S_CPOS_ATK4, 0, 0},   # S_CPOS_ATK3
    {CDoom::Spritenum::SPR_CPOS, 5, 1, (->CDoom.a_cpos_refire).pointer, CDoom::Statenum::S_CPOS_ATK2, 0, 0},       # S_CPOS_ATK4
    {CDoom::Spritenum::SPR_CPOS, 6, 3, Pointer(Void).null, CDoom::Statenum::S_CPOS_PAIN2, 0, 0},                   # S_CPOS_PAIN
    {CDoom::Spritenum::SPR_CPOS, 6, 3, (->CDoom.a_pain).pointer, CDoom::Statenum::S_CPOS_RUN1, 0, 0},              # S_CPOS_PAIN2
    {CDoom::Spritenum::SPR_CPOS, 7, 5, Pointer(Void).null, CDoom::Statenum::S_CPOS_DIE2, 0, 0},                    # S_CPOS_DIE1
    {CDoom::Spritenum::SPR_CPOS, 8, 5, (->CDoom.a_scream).pointer, CDoom::Statenum::S_CPOS_DIE3, 0, 0},            # S_CPOS_DIE2
    {CDoom::Spritenum::SPR_CPOS, 9, 5, (->CDoom.a_fall).pointer, CDoom::Statenum::S_CPOS_DIE4, 0, 0},              # S_CPOS_DIE3
    {CDoom::Spritenum::SPR_CPOS, 10, 5, Pointer(Void).null, CDoom::Statenum::S_CPOS_DIE5, 0, 0},                   # S_CPOS_DIE4
    {CDoom::Spritenum::SPR_CPOS, 11, 5, Pointer(Void).null, CDoom::Statenum::S_CPOS_DIE6, 0, 0},                   # S_CPOS_DIE5
    {CDoom::Spritenum::SPR_CPOS, 12, 5, Pointer(Void).null, CDoom::Statenum::S_CPOS_DIE7, 0, 0},                   # S_CPOS_DIE6
    {CDoom::Spritenum::SPR_CPOS, 13, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                       # S_CPOS_DIE7
    {CDoom::Spritenum::SPR_CPOS, 14, 5, Pointer(Void).null, CDoom::Statenum::S_CPOS_XDIE2, 0, 0},                  # S_CPOS_XDIE1
    {CDoom::Spritenum::SPR_CPOS, 15, 5, (->CDoom.a_xscream).pointer, CDoom::Statenum::S_CPOS_XDIE3, 0, 0},         # S_CPOS_XDIE2
    {CDoom::Spritenum::SPR_CPOS, 16, 5, (->CDoom.a_fall).pointer, CDoom::Statenum::S_CPOS_XDIE4, 0, 0},            # S_CPOS_XDIE3
    {CDoom::Spritenum::SPR_CPOS, 17, 5, Pointer(Void).null, CDoom::Statenum::S_CPOS_XDIE5, 0, 0},                  # S_CPOS_XDIE4
    {CDoom::Spritenum::SPR_CPOS, 18, 5, Pointer(Void).null, CDoom::Statenum::S_CPOS_XDIE6, 0, 0},                  # S_CPOS_XDIE5
    {CDoom::Spritenum::SPR_CPOS, 19, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                       # S_CPOS_XDIE6
    {CDoom::Spritenum::SPR_CPOS, 13, 5, Pointer(Void).null, CDoom::Statenum::S_CPOS_RAISE2, 0, 0},                 # S_CPOS_RAISE1
    {CDoom::Spritenum::SPR_CPOS, 12, 5, Pointer(Void).null, CDoom::Statenum::S_CPOS_RAISE3, 0, 0},                 # S_CPOS_RAISE2
    {CDoom::Spritenum::SPR_CPOS, 11, 5, Pointer(Void).null, CDoom::Statenum::S_CPOS_RAISE4, 0, 0},                 # S_CPOS_RAISE3
    {CDoom::Spritenum::SPR_CPOS, 10, 5, Pointer(Void).null, CDoom::Statenum::S_CPOS_RAISE5, 0, 0},                 # S_CPOS_RAISE4
    {CDoom::Spritenum::SPR_CPOS, 9, 5, Pointer(Void).null, CDoom::Statenum::S_CPOS_RAISE6, 0, 0},                  # S_CPOS_RAISE5
    {CDoom::Spritenum::SPR_CPOS, 8, 5, Pointer(Void).null, CDoom::Statenum::S_CPOS_RAISE7, 0, 0},                  # S_CPOS_RAISE6
    {CDoom::Spritenum::SPR_CPOS, 7, 5, Pointer(Void).null, CDoom::Statenum::S_CPOS_RUN1, 0, 0},                    # S_CPOS_RAISE7
    {CDoom::Spritenum::SPR_TROO, 0, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_TROO_STND2, 0, 0},            # S_TROO_STND
    {CDoom::Spritenum::SPR_TROO, 1, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_TROO_STND, 0, 0},             # S_TROO_STND2
    {CDoom::Spritenum::SPR_TROO, 0, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_TROO_RUN2, 0, 0},             # S_TROO_RUN1
    {CDoom::Spritenum::SPR_TROO, 0, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_TROO_RUN3, 0, 0},             # S_TROO_RUN2
    {CDoom::Spritenum::SPR_TROO, 1, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_TROO_RUN4, 0, 0},             # S_TROO_RUN3
    {CDoom::Spritenum::SPR_TROO, 1, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_TROO_RUN5, 0, 0},             # S_TROO_RUN4
    {CDoom::Spritenum::SPR_TROO, 2, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_TROO_RUN6, 0, 0},             # S_TROO_RUN5
    {CDoom::Spritenum::SPR_TROO, 2, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_TROO_RUN7, 0, 0},             # S_TROO_RUN6
    {CDoom::Spritenum::SPR_TROO, 3, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_TROO_RUN8, 0, 0},             # S_TROO_RUN7
    {CDoom::Spritenum::SPR_TROO, 3, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_TROO_RUN1, 0, 0},             # S_TROO_RUN8
    {CDoom::Spritenum::SPR_TROO, 4, 8, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_TROO_ATK2, 0, 0},       # S_TROO_ATK1
    {CDoom::Spritenum::SPR_TROO, 5, 8, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_TROO_ATK3, 0, 0},       # S_TROO_ATK2
    {CDoom::Spritenum::SPR_TROO, 6, 6, (->CDoom.a_troop_attack).pointer, CDoom::Statenum::S_TROO_RUN1, 0, 0},      # S_TROO_ATK3
    {CDoom::Spritenum::SPR_TROO, 7, 2, Pointer(Void).null, CDoom::Statenum::S_TROO_PAIN2, 0, 0},                   # S_TROO_PAIN
    {CDoom::Spritenum::SPR_TROO, 7, 2, (->CDoom.a_pain).pointer, CDoom::Statenum::S_TROO_RUN1, 0, 0},              # S_TROO_PAIN2
    {CDoom::Spritenum::SPR_TROO, 8, 8, Pointer(Void).null, CDoom::Statenum::S_TROO_DIE2, 0, 0},                    # S_TROO_DIE1
    {CDoom::Spritenum::SPR_TROO, 9, 8, (->CDoom.a_scream).pointer, CDoom::Statenum::S_TROO_DIE3, 0, 0},            # S_TROO_DIE2
    {CDoom::Spritenum::SPR_TROO, 10, 6, Pointer(Void).null, CDoom::Statenum::S_TROO_DIE4, 0, 0},                   # S_TROO_DIE3
    {CDoom::Spritenum::SPR_TROO, 11, 6, (->CDoom.a_fall).pointer, CDoom::Statenum::S_TROO_DIE5, 0, 0},             # S_TROO_DIE4
    {CDoom::Spritenum::SPR_TROO, 12, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                       # S_TROO_DIE5
    {CDoom::Spritenum::SPR_TROO, 13, 5, Pointer(Void).null, CDoom::Statenum::S_TROO_XDIE2, 0, 0},                  # S_TROO_XDIE1
    {CDoom::Spritenum::SPR_TROO, 14, 5, (->CDoom.a_xscream).pointer, CDoom::Statenum::S_TROO_XDIE3, 0, 0},         # S_TROO_XDIE2
    {CDoom::Spritenum::SPR_TROO, 15, 5, Pointer(Void).null, CDoom::Statenum::S_TROO_XDIE4, 0, 0},                  # S_TROO_XDIE3
    {CDoom::Spritenum::SPR_TROO, 16, 5, (->CDoom.a_fall).pointer, CDoom::Statenum::S_TROO_XDIE5, 0, 0},            # S_TROO_XDIE4
    {CDoom::Spritenum::SPR_TROO, 17, 5, Pointer(Void).null, CDoom::Statenum::S_TROO_XDIE6, 0, 0},                  # S_TROO_XDIE5
    {CDoom::Spritenum::SPR_TROO, 18, 5, Pointer(Void).null, CDoom::Statenum::S_TROO_XDIE7, 0, 0},                  # S_TROO_XDIE6
    {CDoom::Spritenum::SPR_TROO, 19, 5, Pointer(Void).null, CDoom::Statenum::S_TROO_XDIE8, 0, 0},                  # S_TROO_XDIE7
    {CDoom::Spritenum::SPR_TROO, 20, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                       # S_TROO_XDIE8
    {CDoom::Spritenum::SPR_TROO, 12, 8, Pointer(Void).null, CDoom::Statenum::S_TROO_RAISE2, 0, 0},                 # S_TROO_RAISE1
    {CDoom::Spritenum::SPR_TROO, 11, 8, Pointer(Void).null, CDoom::Statenum::S_TROO_RAISE3, 0, 0},                 # S_TROO_RAISE2
    {CDoom::Spritenum::SPR_TROO, 10, 6, Pointer(Void).null, CDoom::Statenum::S_TROO_RAISE4, 0, 0},                 # S_TROO_RAISE3
    {CDoom::Spritenum::SPR_TROO, 9, 6, Pointer(Void).null, CDoom::Statenum::S_TROO_RAISE5, 0, 0},                  # S_TROO_RAISE4
    {CDoom::Spritenum::SPR_TROO, 8, 6, Pointer(Void).null, CDoom::Statenum::S_TROO_RUN1, 0, 0},                    # S_TROO_RAISE5
    {CDoom::Spritenum::SPR_SARG, 0, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_SARG_STND2, 0, 0},            # S_SARG_STND
    {CDoom::Spritenum::SPR_SARG, 1, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_SARG_STND, 0, 0},             # S_SARG_STND2
    {CDoom::Spritenum::SPR_SARG, 0, 2, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SARG_RUN2, 0, 0},             # S_SARG_RUN1
    {CDoom::Spritenum::SPR_SARG, 0, 2, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SARG_RUN3, 0, 0},             # S_SARG_RUN2
    {CDoom::Spritenum::SPR_SARG, 1, 2, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SARG_RUN4, 0, 0},             # S_SARG_RUN3
    {CDoom::Spritenum::SPR_SARG, 1, 2, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SARG_RUN5, 0, 0},             # S_SARG_RUN4
    {CDoom::Spritenum::SPR_SARG, 2, 2, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SARG_RUN6, 0, 0},             # S_SARG_RUN5
    {CDoom::Spritenum::SPR_SARG, 2, 2, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SARG_RUN7, 0, 0},             # S_SARG_RUN6
    {CDoom::Spritenum::SPR_SARG, 3, 2, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SARG_RUN8, 0, 0},             # S_SARG_RUN7
    {CDoom::Spritenum::SPR_SARG, 3, 2, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SARG_RUN1, 0, 0},             # S_SARG_RUN8
    {CDoom::Spritenum::SPR_SARG, 4, 8, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_SARG_ATK2, 0, 0},       # S_SARG_ATK1
    {CDoom::Spritenum::SPR_SARG, 5, 8, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_SARG_ATK3, 0, 0},       # S_SARG_ATK2
    {CDoom::Spritenum::SPR_SARG, 6, 8, (->CDoom.a_sarg_attack).pointer, CDoom::Statenum::S_SARG_RUN1, 0, 0},       # S_SARG_ATK3
    {CDoom::Spritenum::SPR_SARG, 7, 2, Pointer(Void).null, CDoom::Statenum::S_SARG_PAIN2, 0, 0},                   # S_SARG_PAIN
    {CDoom::Spritenum::SPR_SARG, 7, 2, (->CDoom.a_pain).pointer, CDoom::Statenum::S_SARG_RUN1, 0, 0},              # S_SARG_PAIN2
    {CDoom::Spritenum::SPR_SARG, 8, 8, Pointer(Void).null, CDoom::Statenum::S_SARG_DIE2, 0, 0},                    # S_SARG_DIE1
    {CDoom::Spritenum::SPR_SARG, 9, 8, (->CDoom.a_scream).pointer, CDoom::Statenum::S_SARG_DIE3, 0, 0},            # S_SARG_DIE2
    {CDoom::Spritenum::SPR_SARG, 10, 4, Pointer(Void).null, CDoom::Statenum::S_SARG_DIE4, 0, 0},                   # S_SARG_DIE3
    {CDoom::Spritenum::SPR_SARG, 11, 4, (->CDoom.a_fall).pointer, CDoom::Statenum::S_SARG_DIE5, 0, 0},             # S_SARG_DIE4
    {CDoom::Spritenum::SPR_SARG, 12, 4, Pointer(Void).null, CDoom::Statenum::S_SARG_DIE6, 0, 0},                   # S_SARG_DIE5
    {CDoom::Spritenum::SPR_SARG, 13, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                       # S_SARG_DIE6
    {CDoom::Spritenum::SPR_SARG, 13, 5, Pointer(Void).null, CDoom::Statenum::S_SARG_RAISE2, 0, 0},                 # S_SARG_RAISE1
    {CDoom::Spritenum::SPR_SARG, 12, 5, Pointer(Void).null, CDoom::Statenum::S_SARG_RAISE3, 0, 0},                 # S_SARG_RAISE2
    {CDoom::Spritenum::SPR_SARG, 11, 5, Pointer(Void).null, CDoom::Statenum::S_SARG_RAISE4, 0, 0},                 # S_SARG_RAISE3
    {CDoom::Spritenum::SPR_SARG, 10, 5, Pointer(Void).null, CDoom::Statenum::S_SARG_RAISE5, 0, 0},                 # S_SARG_RAISE4
    {CDoom::Spritenum::SPR_SARG, 9, 5, Pointer(Void).null, CDoom::Statenum::S_SARG_RAISE6, 0, 0},                  # S_SARG_RAISE5
    {CDoom::Spritenum::SPR_SARG, 8, 5, Pointer(Void).null, CDoom::Statenum::S_SARG_RUN1, 0, 0},                    # S_SARG_RAISE6
    {CDoom::Spritenum::SPR_HEAD, 0, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_HEAD_STND, 0, 0},             # S_HEAD_STND
    {CDoom::Spritenum::SPR_HEAD, 0, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_HEAD_RUN1, 0, 0},             # S_HEAD_RUN1
    {CDoom::Spritenum::SPR_HEAD, 1, 5, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_HEAD_ATK2, 0, 0},       # S_HEAD_ATK1
    {CDoom::Spritenum::SPR_HEAD, 2, 5, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_HEAD_ATK3, 0, 0},       # S_HEAD_ATK2
    {CDoom::Spritenum::SPR_HEAD, 32771, 5, (->CDoom.a_head_attack).pointer, CDoom::Statenum::S_HEAD_RUN1, 0, 0},   # S_HEAD_ATK3
    {CDoom::Spritenum::SPR_HEAD, 4, 3, Pointer(Void).null, CDoom::Statenum::S_HEAD_PAIN2, 0, 0},                   # S_HEAD_PAIN
    {CDoom::Spritenum::SPR_HEAD, 4, 3, (->CDoom.a_pain).pointer, CDoom::Statenum::S_HEAD_PAIN3, 0, 0},             # S_HEAD_PAIN2
    {CDoom::Spritenum::SPR_HEAD, 5, 6, Pointer(Void).null, CDoom::Statenum::S_HEAD_RUN1, 0, 0},                    # S_HEAD_PAIN3
    {CDoom::Spritenum::SPR_HEAD, 6, 8, Pointer(Void).null, CDoom::Statenum::S_HEAD_DIE2, 0, 0},                    # S_HEAD_DIE1
    {CDoom::Spritenum::SPR_HEAD, 7, 8, (->CDoom.a_scream).pointer, CDoom::Statenum::S_HEAD_DIE3, 0, 0},            # S_HEAD_DIE2
    {CDoom::Spritenum::SPR_HEAD, 8, 8, Pointer(Void).null, CDoom::Statenum::S_HEAD_DIE4, 0, 0},                    # S_HEAD_DIE3
    {CDoom::Spritenum::SPR_HEAD, 9, 8, Pointer(Void).null, CDoom::Statenum::S_HEAD_DIE5, 0, 0},                    # S_HEAD_DIE4
    {CDoom::Spritenum::SPR_HEAD, 10, 8, (->CDoom.a_fall).pointer, CDoom::Statenum::S_HEAD_DIE6, 0, 0},             # S_HEAD_DIE5
    {CDoom::Spritenum::SPR_HEAD, 11, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                       # S_HEAD_DIE6
    {CDoom::Spritenum::SPR_HEAD, 11, 8, Pointer(Void).null, CDoom::Statenum::S_HEAD_RAISE2, 0, 0},                 # S_HEAD_RAISE1
    {CDoom::Spritenum::SPR_HEAD, 10, 8, Pointer(Void).null, CDoom::Statenum::S_HEAD_RAISE3, 0, 0},                 # S_HEAD_RAISE2
    {CDoom::Spritenum::SPR_HEAD, 9, 8, Pointer(Void).null, CDoom::Statenum::S_HEAD_RAISE4, 0, 0},                  # S_HEAD_RAISE3
    {CDoom::Spritenum::SPR_HEAD, 8, 8, Pointer(Void).null, CDoom::Statenum::S_HEAD_RAISE5, 0, 0},                  # S_HEAD_RAISE4
    {CDoom::Spritenum::SPR_HEAD, 7, 8, Pointer(Void).null, CDoom::Statenum::S_HEAD_RAISE6, 0, 0},                  # S_HEAD_RAISE5
    {CDoom::Spritenum::SPR_HEAD, 6, 8, Pointer(Void).null, CDoom::Statenum::S_HEAD_RUN1, 0, 0},                    # S_HEAD_RAISE6
    {CDoom::Spritenum::SPR_BAL7, 32768, 4, Pointer(Void).null, CDoom::Statenum::S_BRBALL2, 0, 0},                  # S_BRBALL1
    {CDoom::Spritenum::SPR_BAL7, 32769, 4, Pointer(Void).null, CDoom::Statenum::S_BRBALL1, 0, 0},                  # S_BRBALL2
    {CDoom::Spritenum::SPR_BAL7, 32770, 6, Pointer(Void).null, CDoom::Statenum::S_BRBALLX2, 0, 0},                 # S_BRBALLX1
    {CDoom::Spritenum::SPR_BAL7, 32771, 6, Pointer(Void).null, CDoom::Statenum::S_BRBALLX3, 0, 0},                 # S_BRBALLX2
    {CDoom::Spritenum::SPR_BAL7, 32772, 6, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                     # S_BRBALLX3
    {CDoom::Spritenum::SPR_BOSS, 0, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_BOSS_STND2, 0, 0},            # S_BOSS_STND
    {CDoom::Spritenum::SPR_BOSS, 1, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_BOSS_STND, 0, 0},             # S_BOSS_STND2
    {CDoom::Spritenum::SPR_BOSS, 0, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_BOSS_RUN2, 0, 0},             # S_BOSS_RUN1
    {CDoom::Spritenum::SPR_BOSS, 0, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_BOSS_RUN3, 0, 0},             # S_BOSS_RUN2
    {CDoom::Spritenum::SPR_BOSS, 1, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_BOSS_RUN4, 0, 0},             # S_BOSS_RUN3
    {CDoom::Spritenum::SPR_BOSS, 1, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_BOSS_RUN5, 0, 0},             # S_BOSS_RUN4
    {CDoom::Spritenum::SPR_BOSS, 2, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_BOSS_RUN6, 0, 0},             # S_BOSS_RUN5
    {CDoom::Spritenum::SPR_BOSS, 2, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_BOSS_RUN7, 0, 0},             # S_BOSS_RUN6
    {CDoom::Spritenum::SPR_BOSS, 3, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_BOSS_RUN8, 0, 0},             # S_BOSS_RUN7
    {CDoom::Spritenum::SPR_BOSS, 3, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_BOSS_RUN1, 0, 0},             # S_BOSS_RUN8
    {CDoom::Spritenum::SPR_BOSS, 4, 8, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_BOSS_ATK2, 0, 0},       # S_BOSS_ATK1
    {CDoom::Spritenum::SPR_BOSS, 5, 8, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_BOSS_ATK3, 0, 0},       # S_BOSS_ATK2
    {CDoom::Spritenum::SPR_BOSS, 6, 8, (->CDoom.a_bruis_attack).pointer, CDoom::Statenum::S_BOSS_RUN1, 0, 0},      # S_BOSS_ATK3
    {CDoom::Spritenum::SPR_BOSS, 7, 2, Pointer(Void).null, CDoom::Statenum::S_BOSS_PAIN2, 0, 0},                   # S_BOSS_PAIN
    {CDoom::Spritenum::SPR_BOSS, 7, 2, (->CDoom.a_pain).pointer, CDoom::Statenum::S_BOSS_RUN1, 0, 0},              # S_BOSS_PAIN2
    {CDoom::Spritenum::SPR_BOSS, 8, 8, Pointer(Void).null, CDoom::Statenum::S_BOSS_DIE2, 0, 0},                    # S_BOSS_DIE1
    {CDoom::Spritenum::SPR_BOSS, 9, 8, (->CDoom.a_scream).pointer, CDoom::Statenum::S_BOSS_DIE3, 0, 0},            # S_BOSS_DIE2
    {CDoom::Spritenum::SPR_BOSS, 10, 8, Pointer(Void).null, CDoom::Statenum::S_BOSS_DIE4, 0, 0},                   # S_BOSS_DIE3
    {CDoom::Spritenum::SPR_BOSS, 11, 8, (->CDoom.a_fall).pointer, CDoom::Statenum::S_BOSS_DIE5, 0, 0},             # S_BOSS_DIE4
    {CDoom::Spritenum::SPR_BOSS, 12, 8, Pointer(Void).null, CDoom::Statenum::S_BOSS_DIE6, 0, 0},                   # S_BOSS_DIE5
    {CDoom::Spritenum::SPR_BOSS, 13, 8, Pointer(Void).null, CDoom::Statenum::S_BOSS_DIE7, 0, 0},                   # S_BOSS_DIE6
    {CDoom::Spritenum::SPR_BOSS, 14, -1, (->CDoom.a_boss_death).pointer, CDoom::Statenum::S_NULL, 0, 0},           # S_BOSS_DIE7
    {CDoom::Spritenum::SPR_BOSS, 14, 8, Pointer(Void).null, CDoom::Statenum::S_BOSS_RAISE2, 0, 0},                 # S_BOSS_RAISE1
    {CDoom::Spritenum::SPR_BOSS, 13, 8, Pointer(Void).null, CDoom::Statenum::S_BOSS_RAISE3, 0, 0},                 # S_BOSS_RAISE2
    {CDoom::Spritenum::SPR_BOSS, 12, 8, Pointer(Void).null, CDoom::Statenum::S_BOSS_RAISE4, 0, 0},                 # S_BOSS_RAISE3
    {CDoom::Spritenum::SPR_BOSS, 11, 8, Pointer(Void).null, CDoom::Statenum::S_BOSS_RAISE5, 0, 0},                 # S_BOSS_RAISE4
    {CDoom::Spritenum::SPR_BOSS, 10, 8, Pointer(Void).null, CDoom::Statenum::S_BOSS_RAISE6, 0, 0},                 # S_BOSS_RAISE5
    {CDoom::Spritenum::SPR_BOSS, 9, 8, Pointer(Void).null, CDoom::Statenum::S_BOSS_RAISE7, 0, 0},                  # S_BOSS_RAISE6
    {CDoom::Spritenum::SPR_BOSS, 8, 8, Pointer(Void).null, CDoom::Statenum::S_BOSS_RUN1, 0, 0},                    # S_BOSS_RAISE7
    {CDoom::Spritenum::SPR_BOS2, 0, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_BOS2_STND2, 0, 0},            # S_BOS2_STND
    {CDoom::Spritenum::SPR_BOS2, 1, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_BOS2_STND, 0, 0},             # S_BOS2_STND2
    {CDoom::Spritenum::SPR_BOS2, 0, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_BOS2_RUN2, 0, 0},             # S_BOS2_RUN1
    {CDoom::Spritenum::SPR_BOS2, 0, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_BOS2_RUN3, 0, 0},             # S_BOS2_RUN2
    {CDoom::Spritenum::SPR_BOS2, 1, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_BOS2_RUN4, 0, 0},             # S_BOS2_RUN3
    {CDoom::Spritenum::SPR_BOS2, 1, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_BOS2_RUN5, 0, 0},             # S_BOS2_RUN4
    {CDoom::Spritenum::SPR_BOS2, 2, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_BOS2_RUN6, 0, 0},             # S_BOS2_RUN5
    {CDoom::Spritenum::SPR_BOS2, 2, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_BOS2_RUN7, 0, 0},             # S_BOS2_RUN6
    {CDoom::Spritenum::SPR_BOS2, 3, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_BOS2_RUN8, 0, 0},             # S_BOS2_RUN7
    {CDoom::Spritenum::SPR_BOS2, 3, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_BOS2_RUN1, 0, 0},             # S_BOS2_RUN8
    {CDoom::Spritenum::SPR_BOS2, 4, 8, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_BOS2_ATK2, 0, 0},       # S_BOS2_ATK1
    {CDoom::Spritenum::SPR_BOS2, 5, 8, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_BOS2_ATK3, 0, 0},       # S_BOS2_ATK2
    {CDoom::Spritenum::SPR_BOS2, 6, 8, (->CDoom.a_bruis_attack).pointer, CDoom::Statenum::S_BOS2_RUN1, 0, 0},      # S_BOS2_ATK3
    {CDoom::Spritenum::SPR_BOS2, 7, 2, Pointer(Void).null, CDoom::Statenum::S_BOS2_PAIN2, 0, 0},                   # S_BOS2_PAIN
    {CDoom::Spritenum::SPR_BOS2, 7, 2, (->CDoom.a_pain).pointer, CDoom::Statenum::S_BOS2_RUN1, 0, 0},              # S_BOS2_PAIN2
    {CDoom::Spritenum::SPR_BOS2, 8, 8, Pointer(Void).null, CDoom::Statenum::S_BOS2_DIE2, 0, 0},                    # S_BOS2_DIE1
    {CDoom::Spritenum::SPR_BOS2, 9, 8, (->CDoom.a_scream).pointer, CDoom::Statenum::S_BOS2_DIE3, 0, 0},            # S_BOS2_DIE2
    {CDoom::Spritenum::SPR_BOS2, 10, 8, Pointer(Void).null, CDoom::Statenum::S_BOS2_DIE4, 0, 0},                   # S_BOS2_DIE3
    {CDoom::Spritenum::SPR_BOS2, 11, 8, (->CDoom.a_fall).pointer, CDoom::Statenum::S_BOS2_DIE5, 0, 0},             # S_BOS2_DIE4
    {CDoom::Spritenum::SPR_BOS2, 12, 8, Pointer(Void).null, CDoom::Statenum::S_BOS2_DIE6, 0, 0},                   # S_BOS2_DIE5
    {CDoom::Spritenum::SPR_BOS2, 13, 8, Pointer(Void).null, CDoom::Statenum::S_BOS2_DIE7, 0, 0},                   # S_BOS2_DIE6
    {CDoom::Spritenum::SPR_BOS2, 14, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                       # S_BOS2_DIE7
    {CDoom::Spritenum::SPR_BOS2, 14, 8, Pointer(Void).null, CDoom::Statenum::S_BOS2_RAISE2, 0, 0},                 # S_BOS2_RAISE1
    {CDoom::Spritenum::SPR_BOS2, 13, 8, Pointer(Void).null, CDoom::Statenum::S_BOS2_RAISE3, 0, 0},                 # S_BOS2_RAISE2
    {CDoom::Spritenum::SPR_BOS2, 12, 8, Pointer(Void).null, CDoom::Statenum::S_BOS2_RAISE4, 0, 0},                 # S_BOS2_RAISE3
    {CDoom::Spritenum::SPR_BOS2, 11, 8, Pointer(Void).null, CDoom::Statenum::S_BOS2_RAISE5, 0, 0},                 # S_BOS2_RAISE4
    {CDoom::Spritenum::SPR_BOS2, 10, 8, Pointer(Void).null, CDoom::Statenum::S_BOS2_RAISE6, 0, 0},                 # S_BOS2_RAISE5
    {CDoom::Spritenum::SPR_BOS2, 9, 8, Pointer(Void).null, CDoom::Statenum::S_BOS2_RAISE7, 0, 0},                  # S_BOS2_RAISE6
    {CDoom::Spritenum::SPR_BOS2, 8, 8, Pointer(Void).null, CDoom::Statenum::S_BOS2_RUN1, 0, 0},                    # S_BOS2_RAISE7
    {CDoom::Spritenum::SPR_SKUL, 32768, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_SKULL_STND2, 0, 0},       # S_SKULL_STND
    {CDoom::Spritenum::SPR_SKUL, 32769, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_SKULL_STND, 0, 0},        # S_SKULL_STND2
    {CDoom::Spritenum::SPR_SKUL, 32768, 6, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SKULL_RUN2, 0, 0},        # S_SKULL_RUN1
    {CDoom::Spritenum::SPR_SKUL, 32769, 6, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SKULL_RUN1, 0, 0},        # S_SKULL_RUN2
    {CDoom::Spritenum::SPR_SKUL, 32770, 10, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_SKULL_ATK2, 0, 0}, # S_SKULL_ATK1
    {CDoom::Spritenum::SPR_SKUL, 32771, 4, (->CDoom.a_skull_attack).pointer, CDoom::Statenum::S_SKULL_ATK3, 0, 0}, # S_SKULL_ATK2
    {CDoom::Spritenum::SPR_SKUL, 32770, 4, Pointer(Void).null, CDoom::Statenum::S_SKULL_ATK4, 0, 0},               # S_SKULL_ATK3
    {CDoom::Spritenum::SPR_SKUL, 32771, 4, Pointer(Void).null, CDoom::Statenum::S_SKULL_ATK3, 0, 0},               # S_SKULL_ATK4
    {CDoom::Spritenum::SPR_SKUL, 32772, 3, Pointer(Void).null, CDoom::Statenum::S_SKULL_PAIN2, 0, 0},              # S_SKULL_PAIN
    {CDoom::Spritenum::SPR_SKUL, 32772, 3, (->CDoom.a_pain).pointer, CDoom::Statenum::S_SKULL_RUN1, 0, 0},         # S_SKULL_PAIN2
    {CDoom::Spritenum::SPR_SKUL, 32773, 6, Pointer(Void).null, CDoom::Statenum::S_SKULL_DIE2, 0, 0},               # S_SKULL_DIE1
    {CDoom::Spritenum::SPR_SKUL, 32774, 6, (->CDoom.a_scream).pointer, CDoom::Statenum::S_SKULL_DIE3, 0, 0},       # S_SKULL_DIE2
    {CDoom::Spritenum::SPR_SKUL, 32775, 6, Pointer(Void).null, CDoom::Statenum::S_SKULL_DIE4, 0, 0},               # S_SKULL_DIE3
    {CDoom::Spritenum::SPR_SKUL, 32776, 6, (->CDoom.a_fall).pointer, CDoom::Statenum::S_SKULL_DIE5, 0, 0},         # S_SKULL_DIE4
    {CDoom::Spritenum::SPR_SKUL, 9, 6, Pointer(Void).null, CDoom::Statenum::S_SKULL_DIE6, 0, 0},                   # S_SKULL_DIE5
    {CDoom::Spritenum::SPR_SKUL, 10, 6, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_SKULL_DIE6
    {CDoom::Spritenum::SPR_SPID, 0, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_SPID_STND2, 0, 0},            # S_SPID_STND
    {CDoom::Spritenum::SPR_SPID, 1, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_SPID_STND, 0, 0},             # S_SPID_STND2
    {CDoom::Spritenum::SPR_SPID, 0, 3, (->CDoom.a_metal).pointer, CDoom::Statenum::S_SPID_RUN2, 0, 0},             # S_SPID_RUN1
    {CDoom::Spritenum::SPR_SPID, 0, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SPID_RUN3, 0, 0},             # S_SPID_RUN2
    {CDoom::Spritenum::SPR_SPID, 1, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SPID_RUN4, 0, 0},             # S_SPID_RUN3
    {CDoom::Spritenum::SPR_SPID, 1, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SPID_RUN5, 0, 0},             # S_SPID_RUN4
    {CDoom::Spritenum::SPR_SPID, 2, 3, (->CDoom.a_metal).pointer, CDoom::Statenum::S_SPID_RUN6, 0, 0},             # S_SPID_RUN5
    {CDoom::Spritenum::SPR_SPID, 2, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SPID_RUN7, 0, 0},             # S_SPID_RUN6
    {CDoom::Spritenum::SPR_SPID, 3, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SPID_RUN8, 0, 0},             # S_SPID_RUN7
    {CDoom::Spritenum::SPR_SPID, 3, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SPID_RUN9, 0, 0},             # S_SPID_RUN8
    {CDoom::Spritenum::SPR_SPID, 4, 3, (->CDoom.a_metal).pointer, CDoom::Statenum::S_SPID_RUN10, 0, 0},            # S_SPID_RUN9
    {CDoom::Spritenum::SPR_SPID, 4, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SPID_RUN11, 0, 0},            # S_SPID_RUN10
    {CDoom::Spritenum::SPR_SPID, 5, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SPID_RUN12, 0, 0},            # S_SPID_RUN11
    {CDoom::Spritenum::SPR_SPID, 5, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SPID_RUN1, 0, 0},             # S_SPID_RUN12
    {CDoom::Spritenum::SPR_SPID, 32768, 20, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_SPID_ATK2, 0, 0},  # S_SPID_ATK1
    {CDoom::Spritenum::SPR_SPID, 32774, 4, (->CDoom.a_spos_attack).pointer, CDoom::Statenum::S_SPID_ATK3, 0, 0},   # S_SPID_ATK2
    {CDoom::Spritenum::SPR_SPID, 32775, 4, (->CDoom.a_spos_attack).pointer, CDoom::Statenum::S_SPID_ATK4, 0, 0},   # S_SPID_ATK3
    {CDoom::Spritenum::SPR_SPID, 32775, 1, (->CDoom.a_spid_refire).pointer, CDoom::Statenum::S_SPID_ATK2, 0, 0},   # S_SPID_ATK4
    {CDoom::Spritenum::SPR_SPID, 8, 3, Pointer(Void).null, CDoom::Statenum::S_SPID_PAIN2, 0, 0},                   # S_SPID_PAIN
    {CDoom::Spritenum::SPR_SPID, 8, 3, (->CDoom.a_pain).pointer, CDoom::Statenum::S_SPID_RUN1, 0, 0},              # S_SPID_PAIN2
    {CDoom::Spritenum::SPR_SPID, 9, 20, (->CDoom.a_scream).pointer, CDoom::Statenum::S_SPID_DIE2, 0, 0},           # S_SPID_DIE1
    {CDoom::Spritenum::SPR_SPID, 10, 10, (->CDoom.a_fall).pointer, CDoom::Statenum::S_SPID_DIE3, 0, 0},            # S_SPID_DIE2
    {CDoom::Spritenum::SPR_SPID, 11, 10, Pointer(Void).null, CDoom::Statenum::S_SPID_DIE4, 0, 0},                  # S_SPID_DIE3
    {CDoom::Spritenum::SPR_SPID, 12, 10, Pointer(Void).null, CDoom::Statenum::S_SPID_DIE5, 0, 0},                  # S_SPID_DIE4
    {CDoom::Spritenum::SPR_SPID, 13, 10, Pointer(Void).null, CDoom::Statenum::S_SPID_DIE6, 0, 0},                  # S_SPID_DIE5
    {CDoom::Spritenum::SPR_SPID, 14, 10, Pointer(Void).null, CDoom::Statenum::S_SPID_DIE7, 0, 0},                  # S_SPID_DIE6
    {CDoom::Spritenum::SPR_SPID, 15, 10, Pointer(Void).null, CDoom::Statenum::S_SPID_DIE8, 0, 0},                  # S_SPID_DIE7
    {CDoom::Spritenum::SPR_SPID, 16, 10, Pointer(Void).null, CDoom::Statenum::S_SPID_DIE9, 0, 0},                  # S_SPID_DIE8
    {CDoom::Spritenum::SPR_SPID, 17, 10, Pointer(Void).null, CDoom::Statenum::S_SPID_DIE10, 0, 0},                 # S_SPID_DIE9
    {CDoom::Spritenum::SPR_SPID, 18, 30, Pointer(Void).null, CDoom::Statenum::S_SPID_DIE11, 0, 0},                 # S_SPID_DIE10
    {CDoom::Spritenum::SPR_SPID, 18, -1, (->CDoom.a_boss_death).pointer, CDoom::Statenum::S_NULL, 0, 0},           # S_SPID_DIE11
    {CDoom::Spritenum::SPR_BSPI, 0, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_BSPI_STND2, 0, 0},            # S_BSPI_STND
    {CDoom::Spritenum::SPR_BSPI, 1, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_BSPI_STND, 0, 0},             # S_BSPI_STND2
    {CDoom::Spritenum::SPR_BSPI, 0, 20, Pointer(Void).null, CDoom::Statenum::S_BSPI_RUN1, 0, 0},                   # S_BSPI_SIGHT
    {CDoom::Spritenum::SPR_BSPI, 0, 3, (->CDoom.a_baby_metal).pointer, CDoom::Statenum::S_BSPI_RUN2, 0, 0},        # S_BSPI_RUN1
    {CDoom::Spritenum::SPR_BSPI, 0, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_BSPI_RUN3, 0, 0},             # S_BSPI_RUN2
    {CDoom::Spritenum::SPR_BSPI, 1, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_BSPI_RUN4, 0, 0},             # S_BSPI_RUN3
    {CDoom::Spritenum::SPR_BSPI, 1, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_BSPI_RUN5, 0, 0},             # S_BSPI_RUN4
    {CDoom::Spritenum::SPR_BSPI, 2, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_BSPI_RUN6, 0, 0},             # S_BSPI_RUN5
    {CDoom::Spritenum::SPR_BSPI, 2, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_BSPI_RUN7, 0, 0},             # S_BSPI_RUN6
    {CDoom::Spritenum::SPR_BSPI, 3, 3, (->CDoom.a_baby_metal).pointer, CDoom::Statenum::S_BSPI_RUN8, 0, 0},        # S_BSPI_RUN7
    {CDoom::Spritenum::SPR_BSPI, 3, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_BSPI_RUN9, 0, 0},             # S_BSPI_RUN8
    {CDoom::Spritenum::SPR_BSPI, 4, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_BSPI_RUN10, 0, 0},            # S_BSPI_RUN9
    {CDoom::Spritenum::SPR_BSPI, 4, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_BSPI_RUN11, 0, 0},            # S_BSPI_RUN10
    {CDoom::Spritenum::SPR_BSPI, 5, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_BSPI_RUN12, 0, 0},            # S_BSPI_RUN11
    {CDoom::Spritenum::SPR_BSPI, 5, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_BSPI_RUN1, 0, 0},             # S_BSPI_RUN12
    {CDoom::Spritenum::SPR_BSPI, 32768, 20, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_BSPI_ATK2, 0, 0},  # S_BSPI_ATK1
    {CDoom::Spritenum::SPR_BSPI, 32774, 4, (->CDoom.a_bspi_attack).pointer, CDoom::Statenum::S_BSPI_ATK3, 0, 0},   # S_BSPI_ATK2
    {CDoom::Spritenum::SPR_BSPI, 32775, 4, Pointer(Void).null, CDoom::Statenum::S_BSPI_ATK4, 0, 0},                # S_BSPI_ATK3
    {CDoom::Spritenum::SPR_BSPI, 32775, 1, (->CDoom.a_spid_refire).pointer, CDoom::Statenum::S_BSPI_ATK2, 0, 0},   # S_BSPI_ATK4
    {CDoom::Spritenum::SPR_BSPI, 8, 3, Pointer(Void).null, CDoom::Statenum::S_BSPI_PAIN2, 0, 0},                   # S_BSPI_PAIN
    {CDoom::Spritenum::SPR_BSPI, 8, 3, (->CDoom.a_pain).pointer, CDoom::Statenum::S_BSPI_RUN1, 0, 0},              # S_BSPI_PAIN2
    {CDoom::Spritenum::SPR_BSPI, 9, 20, (->CDoom.a_scream).pointer, CDoom::Statenum::S_BSPI_DIE2, 0, 0},           # S_BSPI_DIE1
    {CDoom::Spritenum::SPR_BSPI, 10, 7, (->CDoom.a_fall).pointer, CDoom::Statenum::S_BSPI_DIE3, 0, 0},             # S_BSPI_DIE2
    {CDoom::Spritenum::SPR_BSPI, 11, 7, Pointer(Void).null, CDoom::Statenum::S_BSPI_DIE4, 0, 0},                   # S_BSPI_DIE3
    {CDoom::Spritenum::SPR_BSPI, 12, 7, Pointer(Void).null, CDoom::Statenum::S_BSPI_DIE5, 0, 0},                   # S_BSPI_DIE4
    {CDoom::Spritenum::SPR_BSPI, 13, 7, Pointer(Void).null, CDoom::Statenum::S_BSPI_DIE6, 0, 0},                   # S_BSPI_DIE5
    {CDoom::Spritenum::SPR_BSPI, 14, 7, Pointer(Void).null, CDoom::Statenum::S_BSPI_DIE7, 0, 0},                   # S_BSPI_DIE6
    {CDoom::Spritenum::SPR_BSPI, 15, -1, (->CDoom.a_boss_death).pointer, CDoom::Statenum::S_NULL, 0, 0},           # S_BSPI_DIE7
    {CDoom::Spritenum::SPR_BSPI, 15, 5, Pointer(Void).null, CDoom::Statenum::S_BSPI_RAISE2, 0, 0},                 # S_BSPI_RAISE1
    {CDoom::Spritenum::SPR_BSPI, 14, 5, Pointer(Void).null, CDoom::Statenum::S_BSPI_RAISE3, 0, 0},                 # S_BSPI_RAISE2
    {CDoom::Spritenum::SPR_BSPI, 13, 5, Pointer(Void).null, CDoom::Statenum::S_BSPI_RAISE4, 0, 0},                 # S_BSPI_RAISE3
    {CDoom::Spritenum::SPR_BSPI, 12, 5, Pointer(Void).null, CDoom::Statenum::S_BSPI_RAISE5, 0, 0},                 # S_BSPI_RAISE4
    {CDoom::Spritenum::SPR_BSPI, 11, 5, Pointer(Void).null, CDoom::Statenum::S_BSPI_RAISE6, 0, 0},                 # S_BSPI_RAISE5
    {CDoom::Spritenum::SPR_BSPI, 10, 5, Pointer(Void).null, CDoom::Statenum::S_BSPI_RAISE7, 0, 0},                 # S_BSPI_RAISE6
    {CDoom::Spritenum::SPR_BSPI, 9, 5, Pointer(Void).null, CDoom::Statenum::S_BSPI_RUN1, 0, 0},                    # S_BSPI_RAISE7
    {CDoom::Spritenum::SPR_APLS, 32768, 5, Pointer(Void).null, CDoom::Statenum::S_ARACH_PLAZ2, 0, 0},              # S_ARACH_PLAZ
    {CDoom::Spritenum::SPR_APLS, 32769, 5, Pointer(Void).null, CDoom::Statenum::S_ARACH_PLAZ, 0, 0},               # S_ARACH_PLAZ2
    {CDoom::Spritenum::SPR_APBX, 32768, 5, Pointer(Void).null, CDoom::Statenum::S_ARACH_PLEX2, 0, 0},              # S_ARACH_PLEX
    {CDoom::Spritenum::SPR_APBX, 32769, 5, Pointer(Void).null, CDoom::Statenum::S_ARACH_PLEX3, 0, 0},              # S_ARACH_PLEX2
    {CDoom::Spritenum::SPR_APBX, 32770, 5, Pointer(Void).null, CDoom::Statenum::S_ARACH_PLEX4, 0, 0},              # S_ARACH_PLEX3
    {CDoom::Spritenum::SPR_APBX, 32771, 5, Pointer(Void).null, CDoom::Statenum::S_ARACH_PLEX5, 0, 0},              # S_ARACH_PLEX4
    {CDoom::Spritenum::SPR_APBX, 32772, 5, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                     # S_ARACH_PLEX5
    {CDoom::Spritenum::SPR_CYBR, 0, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_CYBER_STND2, 0, 0},           # S_CYBER_STND
    {CDoom::Spritenum::SPR_CYBR, 1, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_CYBER_STND, 0, 0},            # S_CYBER_STND2
    {CDoom::Spritenum::SPR_CYBR, 0, 3, (->CDoom.a_hoof).pointer, CDoom::Statenum::S_CYBER_RUN2, 0, 0},             # S_CYBER_RUN1
    {CDoom::Spritenum::SPR_CYBR, 0, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_CYBER_RUN3, 0, 0},            # S_CYBER_RUN2
    {CDoom::Spritenum::SPR_CYBR, 1, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_CYBER_RUN4, 0, 0},            # S_CYBER_RUN3
    {CDoom::Spritenum::SPR_CYBR, 1, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_CYBER_RUN5, 0, 0},            # S_CYBER_RUN4
    {CDoom::Spritenum::SPR_CYBR, 2, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_CYBER_RUN6, 0, 0},            # S_CYBER_RUN5
    {CDoom::Spritenum::SPR_CYBR, 2, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_CYBER_RUN7, 0, 0},            # S_CYBER_RUN6
    {CDoom::Spritenum::SPR_CYBR, 3, 3, (->CDoom.a_metal).pointer, CDoom::Statenum::S_CYBER_RUN8, 0, 0},            # S_CYBER_RUN7
    {CDoom::Spritenum::SPR_CYBR, 3, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_CYBER_RUN1, 0, 0},            # S_CYBER_RUN8
    {CDoom::Spritenum::SPR_CYBR, 4, 6, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_CYBER_ATK2, 0, 0},      # S_CYBER_ATK1
    {CDoom::Spritenum::SPR_CYBR, 5, 12, (->CDoom.a_cyber_attack).pointer, CDoom::Statenum::S_CYBER_ATK3, 0, 0},    # S_CYBER_ATK2
    {CDoom::Spritenum::SPR_CYBR, 4, 12, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_CYBER_ATK4, 0, 0},     # S_CYBER_ATK3
    {CDoom::Spritenum::SPR_CYBR, 5, 12, (->CDoom.a_cyber_attack).pointer, CDoom::Statenum::S_CYBER_ATK5, 0, 0},    # S_CYBER_ATK4
    {CDoom::Spritenum::SPR_CYBR, 4, 12, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_CYBER_ATK6, 0, 0},     # S_CYBER_ATK5
    {CDoom::Spritenum::SPR_CYBR, 5, 12, (->CDoom.a_cyber_attack).pointer, CDoom::Statenum::S_CYBER_RUN1, 0, 0},    # S_CYBER_ATK6
    {CDoom::Spritenum::SPR_CYBR, 6, 10, (->CDoom.a_pain).pointer, CDoom::Statenum::S_CYBER_RUN1, 0, 0},            # S_CYBER_PAIN
    {CDoom::Spritenum::SPR_CYBR, 7, 10, Pointer(Void).null, CDoom::Statenum::S_CYBER_DIE2, 0, 0},                  # S_CYBER_DIE1
    {CDoom::Spritenum::SPR_CYBR, 8, 10, (->CDoom.a_scream).pointer, CDoom::Statenum::S_CYBER_DIE3, 0, 0},          # S_CYBER_DIE2
    {CDoom::Spritenum::SPR_CYBR, 9, 10, Pointer(Void).null, CDoom::Statenum::S_CYBER_DIE4, 0, 0},                  # S_CYBER_DIE3
    {CDoom::Spritenum::SPR_CYBR, 10, 10, Pointer(Void).null, CDoom::Statenum::S_CYBER_DIE5, 0, 0},                 # S_CYBER_DIE4
    {CDoom::Spritenum::SPR_CYBR, 11, 10, Pointer(Void).null, CDoom::Statenum::S_CYBER_DIE6, 0, 0},                 # S_CYBER_DIE5
    {CDoom::Spritenum::SPR_CYBR, 12, 10, (->CDoom.a_fall).pointer, CDoom::Statenum::S_CYBER_DIE7, 0, 0},           # S_CYBER_DIE6
    {CDoom::Spritenum::SPR_CYBR, 13, 10, Pointer(Void).null, CDoom::Statenum::S_CYBER_DIE8, 0, 0},                 # S_CYBER_DIE7
    {CDoom::Spritenum::SPR_CYBR, 14, 10, Pointer(Void).null, CDoom::Statenum::S_CYBER_DIE9, 0, 0},                 # S_CYBER_DIE8
    {CDoom::Spritenum::SPR_CYBR, 15, 30, Pointer(Void).null, CDoom::Statenum::S_CYBER_DIE10, 0, 0},                # S_CYBER_DIE9
    {CDoom::Spritenum::SPR_CYBR, 15, -1, (->CDoom.a_boss_death).pointer, CDoom::Statenum::S_NULL, 0, 0},           # S_CYBER_DIE10
    {CDoom::Spritenum::SPR_PAIN, 0, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_PAIN_STND, 0, 0},             # S_PAIN_STND
    {CDoom::Spritenum::SPR_PAIN, 0, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_PAIN_RUN2, 0, 0},             # S_PAIN_RUN1
    {CDoom::Spritenum::SPR_PAIN, 0, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_PAIN_RUN3, 0, 0},             # S_PAIN_RUN2
    {CDoom::Spritenum::SPR_PAIN, 1, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_PAIN_RUN4, 0, 0},             # S_PAIN_RUN3
    {CDoom::Spritenum::SPR_PAIN, 1, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_PAIN_RUN5, 0, 0},             # S_PAIN_RUN4
    {CDoom::Spritenum::SPR_PAIN, 2, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_PAIN_RUN6, 0, 0},             # S_PAIN_RUN5
    {CDoom::Spritenum::SPR_PAIN, 2, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_PAIN_RUN1, 0, 0},             # S_PAIN_RUN6
    {CDoom::Spritenum::SPR_PAIN, 3, 5, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_PAIN_ATK2, 0, 0},       # S_PAIN_ATK1
    {CDoom::Spritenum::SPR_PAIN, 4, 5, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_PAIN_ATK3, 0, 0},       # S_PAIN_ATK2
    {CDoom::Spritenum::SPR_PAIN, 32773, 5, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_PAIN_ATK4, 0, 0},   # S_PAIN_ATK3
    {CDoom::Spritenum::SPR_PAIN, 32773, 0, (->CDoom.a_pain_attack).pointer, CDoom::Statenum::S_PAIN_RUN1, 0, 0},   # S_PAIN_ATK4
    {CDoom::Spritenum::SPR_PAIN, 6, 6, Pointer(Void).null, CDoom::Statenum::S_PAIN_PAIN2, 0, 0},                   # S_PAIN_PAIN
    {CDoom::Spritenum::SPR_PAIN, 6, 6, (->CDoom.a_pain).pointer, CDoom::Statenum::S_PAIN_RUN1, 0, 0},              # S_PAIN_PAIN2
    {CDoom::Spritenum::SPR_PAIN, 32775, 8, Pointer(Void).null, CDoom::Statenum::S_PAIN_DIE2, 0, 0},                # S_PAIN_DIE1
    {CDoom::Spritenum::SPR_PAIN, 32776, 8, (->CDoom.a_scream).pointer, CDoom::Statenum::S_PAIN_DIE3, 0, 0},        # S_PAIN_DIE2
    {CDoom::Spritenum::SPR_PAIN, 32777, 8, Pointer(Void).null, CDoom::Statenum::S_PAIN_DIE4, 0, 0},                # S_PAIN_DIE3
    {CDoom::Spritenum::SPR_PAIN, 32778, 8, Pointer(Void).null, CDoom::Statenum::S_PAIN_DIE5, 0, 0},                # S_PAIN_DIE4
    {CDoom::Spritenum::SPR_PAIN, 32779, 8, (->CDoom.a_pain_die).pointer, CDoom::Statenum::S_PAIN_DIE6, 0, 0},      # S_PAIN_DIE5
    {CDoom::Spritenum::SPR_PAIN, 32780, 8, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                     # S_PAIN_DIE6
    {CDoom::Spritenum::SPR_PAIN, 12, 8, Pointer(Void).null, CDoom::Statenum::S_PAIN_RAISE2, 0, 0},                 # S_PAIN_RAISE1
    {CDoom::Spritenum::SPR_PAIN, 11, 8, Pointer(Void).null, CDoom::Statenum::S_PAIN_RAISE3, 0, 0},                 # S_PAIN_RAISE2
    {CDoom::Spritenum::SPR_PAIN, 10, 8, Pointer(Void).null, CDoom::Statenum::S_PAIN_RAISE4, 0, 0},                 # S_PAIN_RAISE3
    {CDoom::Spritenum::SPR_PAIN, 9, 8, Pointer(Void).null, CDoom::Statenum::S_PAIN_RAISE5, 0, 0},                  # S_PAIN_RAISE4
    {CDoom::Spritenum::SPR_PAIN, 8, 8, Pointer(Void).null, CDoom::Statenum::S_PAIN_RAISE6, 0, 0},                  # S_PAIN_RAISE5
    {CDoom::Spritenum::SPR_PAIN, 7, 8, Pointer(Void).null, CDoom::Statenum::S_PAIN_RUN1, 0, 0},                    # S_PAIN_RAISE6
    {CDoom::Spritenum::SPR_SSWV, 0, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_SSWV_STND2, 0, 0},            # S_SSWV_STND
    {CDoom::Spritenum::SPR_SSWV, 1, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_SSWV_STND, 0, 0},             # S_SSWV_STND2
    {CDoom::Spritenum::SPR_SSWV, 0, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SSWV_RUN2, 0, 0},             # S_SSWV_RUN1
    {CDoom::Spritenum::SPR_SSWV, 0, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SSWV_RUN3, 0, 0},             # S_SSWV_RUN2
    {CDoom::Spritenum::SPR_SSWV, 1, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SSWV_RUN4, 0, 0},             # S_SSWV_RUN3
    {CDoom::Spritenum::SPR_SSWV, 1, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SSWV_RUN5, 0, 0},             # S_SSWV_RUN4
    {CDoom::Spritenum::SPR_SSWV, 2, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SSWV_RUN6, 0, 0},             # S_SSWV_RUN5
    {CDoom::Spritenum::SPR_SSWV, 2, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SSWV_RUN7, 0, 0},             # S_SSWV_RUN6
    {CDoom::Spritenum::SPR_SSWV, 3, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SSWV_RUN8, 0, 0},             # S_SSWV_RUN7
    {CDoom::Spritenum::SPR_SSWV, 3, 3, (->CDoom.a_chase).pointer, CDoom::Statenum::S_SSWV_RUN1, 0, 0},             # S_SSWV_RUN8
    {CDoom::Spritenum::SPR_SSWV, 4, 10, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_SSWV_ATK2, 0, 0},      # S_SSWV_ATK1
    {CDoom::Spritenum::SPR_SSWV, 5, 10, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_SSWV_ATK3, 0, 0},      # S_SSWV_ATK2
    {CDoom::Spritenum::SPR_SSWV, 32774, 4, (->CDoom.a_cpos_attack).pointer, CDoom::Statenum::S_SSWV_ATK4, 0, 0},   # S_SSWV_ATK3
    {CDoom::Spritenum::SPR_SSWV, 5, 6, (->CDoom.a_face_target).pointer, CDoom::Statenum::S_SSWV_ATK5, 0, 0},       # S_SSWV_ATK4
    {CDoom::Spritenum::SPR_SSWV, 32774, 4, (->CDoom.a_cpos_attack).pointer, CDoom::Statenum::S_SSWV_ATK6, 0, 0},   # S_SSWV_ATK5
    {CDoom::Spritenum::SPR_SSWV, 5, 1, (->CDoom.a_cpos_refire).pointer, CDoom::Statenum::S_SSWV_ATK2, 0, 0},       # S_SSWV_ATK6
    {CDoom::Spritenum::SPR_SSWV, 7, 3, Pointer(Void).null, CDoom::Statenum::S_SSWV_PAIN2, 0, 0},                   # S_SSWV_PAIN
    {CDoom::Spritenum::SPR_SSWV, 7, 3, (->CDoom.a_pain).pointer, CDoom::Statenum::S_SSWV_RUN1, 0, 0},              # S_SSWV_PAIN2
    {CDoom::Spritenum::SPR_SSWV, 8, 5, Pointer(Void).null, CDoom::Statenum::S_SSWV_DIE2, 0, 0},                    # S_SSWV_DIE1
    {CDoom::Spritenum::SPR_SSWV, 9, 5, (->CDoom.a_scream).pointer, CDoom::Statenum::S_SSWV_DIE3, 0, 0},            # S_SSWV_DIE2
    {CDoom::Spritenum::SPR_SSWV, 10, 5, (->CDoom.a_fall).pointer, CDoom::Statenum::S_SSWV_DIE4, 0, 0},             # S_SSWV_DIE3
    {CDoom::Spritenum::SPR_SSWV, 11, 5, Pointer(Void).null, CDoom::Statenum::S_SSWV_DIE5, 0, 0},                   # S_SSWV_DIE4
    {CDoom::Spritenum::SPR_SSWV, 12, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                       # S_SSWV_DIE5
    {CDoom::Spritenum::SPR_SSWV, 13, 5, Pointer(Void).null, CDoom::Statenum::S_SSWV_XDIE2, 0, 0},                  # S_SSWV_XDIE1
    {CDoom::Spritenum::SPR_SSWV, 14, 5, (->CDoom.a_xscream).pointer, CDoom::Statenum::S_SSWV_XDIE3, 0, 0},         # S_SSWV_XDIE2
    {CDoom::Spritenum::SPR_SSWV, 15, 5, (->CDoom.a_fall).pointer, CDoom::Statenum::S_SSWV_XDIE4, 0, 0},            # S_SSWV_XDIE3
    {CDoom::Spritenum::SPR_SSWV, 16, 5, Pointer(Void).null, CDoom::Statenum::S_SSWV_XDIE5, 0, 0},                  # S_SSWV_XDIE4
    {CDoom::Spritenum::SPR_SSWV, 17, 5, Pointer(Void).null, CDoom::Statenum::S_SSWV_XDIE6, 0, 0},                  # S_SSWV_XDIE5
    {CDoom::Spritenum::SPR_SSWV, 18, 5, Pointer(Void).null, CDoom::Statenum::S_SSWV_XDIE7, 0, 0},                  # S_SSWV_XDIE6
    {CDoom::Spritenum::SPR_SSWV, 19, 5, Pointer(Void).null, CDoom::Statenum::S_SSWV_XDIE8, 0, 0},                  # S_SSWV_XDIE7
    {CDoom::Spritenum::SPR_SSWV, 20, 5, Pointer(Void).null, CDoom::Statenum::S_SSWV_XDIE9, 0, 0},                  # S_SSWV_XDIE8
    {CDoom::Spritenum::SPR_SSWV, 21, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                       # S_SSWV_XDIE9
    {CDoom::Spritenum::SPR_SSWV, 12, 5, Pointer(Void).null, CDoom::Statenum::S_SSWV_RAISE2, 0, 0},                 # S_SSWV_RAISE1
    {CDoom::Spritenum::SPR_SSWV, 11, 5, Pointer(Void).null, CDoom::Statenum::S_SSWV_RAISE3, 0, 0},                 # S_SSWV_RAISE2
    {CDoom::Spritenum::SPR_SSWV, 10, 5, Pointer(Void).null, CDoom::Statenum::S_SSWV_RAISE4, 0, 0},                 # S_SSWV_RAISE3
    {CDoom::Spritenum::SPR_SSWV, 9, 5, Pointer(Void).null, CDoom::Statenum::S_SSWV_RAISE5, 0, 0},                  # S_SSWV_RAISE4
    {CDoom::Spritenum::SPR_SSWV, 8, 5, Pointer(Void).null, CDoom::Statenum::S_SSWV_RUN1, 0, 0},                    # S_SSWV_RAISE5
    {CDoom::Spritenum::SPR_KEEN, 0, -1, Pointer(Void).null, CDoom::Statenum::S_KEENSTND, 0, 0},                    # S_KEENSTND
    {CDoom::Spritenum::SPR_KEEN, 0, 6, Pointer(Void).null, CDoom::Statenum::S_COMMKEEN2, 0, 0},                    # S_COMMKEEN
    {CDoom::Spritenum::SPR_KEEN, 1, 6, Pointer(Void).null, CDoom::Statenum::S_COMMKEEN3, 0, 0},                    # S_COMMKEEN2
    {CDoom::Spritenum::SPR_KEEN, 2, 6, (->CDoom.a_scream).pointer, CDoom::Statenum::S_COMMKEEN4, 0, 0},            # S_COMMKEEN3
    {CDoom::Spritenum::SPR_KEEN, 3, 6, Pointer(Void).null, CDoom::Statenum::S_COMMKEEN5, 0, 0},                    # S_COMMKEEN4
    {CDoom::Spritenum::SPR_KEEN, 4, 6, Pointer(Void).null, CDoom::Statenum::S_COMMKEEN6, 0, 0},                    # S_COMMKEEN5
    {CDoom::Spritenum::SPR_KEEN, 5, 6, Pointer(Void).null, CDoom::Statenum::S_COMMKEEN7, 0, 0},                    # S_COMMKEEN6
    {CDoom::Spritenum::SPR_KEEN, 6, 6, Pointer(Void).null, CDoom::Statenum::S_COMMKEEN8, 0, 0},                    # S_COMMKEEN7
    {CDoom::Spritenum::SPR_KEEN, 7, 6, Pointer(Void).null, CDoom::Statenum::S_COMMKEEN9, 0, 0},                    # S_COMMKEEN8
    {CDoom::Spritenum::SPR_KEEN, 8, 6, Pointer(Void).null, CDoom::Statenum::S_COMMKEEN10, 0, 0},                   # S_COMMKEEN9
    {CDoom::Spritenum::SPR_KEEN, 9, 6, Pointer(Void).null, CDoom::Statenum::S_COMMKEEN11, 0, 0},                   # S_COMMKEEN10
    {CDoom::Spritenum::SPR_KEEN, 10, 6, (->CDoom.a_keen_die).pointer, CDoom::Statenum::S_COMMKEEN12, 0, 0},        # S_COMMKEEN11
    {CDoom::Spritenum::SPR_KEEN, 11, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                       # S_COMMKEEN12
    {CDoom::Spritenum::SPR_KEEN, 12, 4, Pointer(Void).null, CDoom::Statenum::S_KEENPAIN2, 0, 0},                   # S_KEENPAIN
    {CDoom::Spritenum::SPR_KEEN, 12, 8, (->CDoom.a_pain).pointer, CDoom::Statenum::S_KEENSTND, 0, 0},              # S_KEENPAIN2
    {CDoom::Spritenum::SPR_BBRN, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_BRAIN
    {CDoom::Spritenum::SPR_BBRN, 1, 36, (->CDoom.a_brain_pain).pointer, CDoom::Statenum::S_BRAIN, 0, 0},           # S_BRAIN_PAIN
    {CDoom::Spritenum::SPR_BBRN, 0, 100, (->CDoom.a_brain_scream).pointer, CDoom::Statenum::S_BRAIN_DIE2, 0, 0},   # S_BRAIN_DIE1
    {CDoom::Spritenum::SPR_BBRN, 0, 10, Pointer(Void).null, CDoom::Statenum::S_BRAIN_DIE3, 0, 0},                  # S_BRAIN_DIE2
    {CDoom::Spritenum::SPR_BBRN, 0, 10, Pointer(Void).null, CDoom::Statenum::S_BRAIN_DIE4, 0, 0},                  # S_BRAIN_DIE3
    {CDoom::Spritenum::SPR_BBRN, 0, -1, (->CDoom.a_brain_die).pointer, CDoom::Statenum::S_NULL, 0, 0},             # S_BRAIN_DIE4
    {CDoom::Spritenum::SPR_SSWV, 0, 10, (->CDoom.a_look).pointer, CDoom::Statenum::S_BRAINEYE, 0, 0},              # S_BRAINEYE
    {CDoom::Spritenum::SPR_SSWV, 0, 181, (->CDoom.a_brain_awake).pointer, CDoom::Statenum::S_BRAINEYE1, 0, 0},     # S_BRAINEYESEE
    {CDoom::Spritenum::SPR_SSWV, 0, 150, (->CDoom.a_brain_spit).pointer, CDoom::Statenum::S_BRAINEYE1, 0, 0},      # S_BRAINEYE1
    {CDoom::Spritenum::SPR_BOSF, 32768, 3, (->CDoom.a_spawn_sound).pointer, CDoom::Statenum::S_SPAWN2, 0, 0},      # S_SPAWN1
    {CDoom::Spritenum::SPR_BOSF, 32769, 3, (->CDoom.a_spawn_fly).pointer, CDoom::Statenum::S_SPAWN3, 0, 0},        # S_SPAWN2
    {CDoom::Spritenum::SPR_BOSF, 32770, 3, (->CDoom.a_spawn_fly).pointer, CDoom::Statenum::S_SPAWN4, 0, 0},        # S_SPAWN3
    {CDoom::Spritenum::SPR_BOSF, 32771, 3, (->CDoom.a_spawn_fly).pointer, CDoom::Statenum::S_SPAWN1, 0, 0},        # S_SPAWN4
    {CDoom::Spritenum::SPR_FIRE, 32768, 4, (->CDoom.a_fire).pointer, CDoom::Statenum::S_SPAWNFIRE2, 0, 0},         # S_SPAWNFIRE1
    {CDoom::Spritenum::SPR_FIRE, 32769, 4, (->CDoom.a_fire).pointer, CDoom::Statenum::S_SPAWNFIRE3, 0, 0},         # S_SPAWNFIRE2
    {CDoom::Spritenum::SPR_FIRE, 32770, 4, (->CDoom.a_fire).pointer, CDoom::Statenum::S_SPAWNFIRE4, 0, 0},         # S_SPAWNFIRE3
    {CDoom::Spritenum::SPR_FIRE, 32771, 4, (->CDoom.a_fire).pointer, CDoom::Statenum::S_SPAWNFIRE5, 0, 0},         # S_SPAWNFIRE4
    {CDoom::Spritenum::SPR_FIRE, 32772, 4, (->CDoom.a_fire).pointer, CDoom::Statenum::S_SPAWNFIRE6, 0, 0},         # S_SPAWNFIRE5
    {CDoom::Spritenum::SPR_FIRE, 32773, 4, (->CDoom.a_fire).pointer, CDoom::Statenum::S_SPAWNFIRE7, 0, 0},         # S_SPAWNFIRE6
    {CDoom::Spritenum::SPR_FIRE, 32774, 4, (->CDoom.a_fire).pointer, CDoom::Statenum::S_SPAWNFIRE8, 0, 0},         # S_SPAWNFIRE7
    {CDoom::Spritenum::SPR_FIRE, 32775, 4, (->CDoom.a_fire).pointer, CDoom::Statenum::S_NULL, 0, 0},               # S_SPAWNFIRE8
    {CDoom::Spritenum::SPR_MISL, 32769, 10, Pointer(Void).null, CDoom::Statenum::S_BRAINEXPLODE2, 0, 0},           # S_BRAINEXPLODE1
    {CDoom::Spritenum::SPR_MISL, 32770, 10, Pointer(Void).null, CDoom::Statenum::S_BRAINEXPLODE3, 0, 0},           # S_BRAINEXPLODE2
    {CDoom::Spritenum::SPR_MISL, 32771, 10, (->CDoom.a_brain_explode).pointer, CDoom::Statenum::S_NULL, 0, 0},     # S_BRAINEXPLODE3
    {CDoom::Spritenum::SPR_ARM1, 0, 6, Pointer(Void).null, CDoom::Statenum::S_ARM1A, 0, 0},                        # S_ARM1
    {CDoom::Spritenum::SPR_ARM1, 32769, 7, Pointer(Void).null, CDoom::Statenum::S_ARM1, 0, 0},                     # S_ARM1A
    {CDoom::Spritenum::SPR_ARM2, 0, 6, Pointer(Void).null, CDoom::Statenum::S_ARM2A, 0, 0},                        # S_ARM2
    {CDoom::Spritenum::SPR_ARM2, 32769, 6, Pointer(Void).null, CDoom::Statenum::S_ARM2, 0, 0},                     # S_ARM2A
    {CDoom::Spritenum::SPR_BAR1, 0, 6, Pointer(Void).null, CDoom::Statenum::S_BAR2, 0, 0},                         # S_BAR1
    {CDoom::Spritenum::SPR_BAR1, 1, 6, Pointer(Void).null, CDoom::Statenum::S_BAR1, 0, 0},                         # S_BAR2
    {CDoom::Spritenum::SPR_BEXP, 32768, 5, Pointer(Void).null, CDoom::Statenum::S_BEXP2, 0, 0},                    # S_BEXP
    {CDoom::Spritenum::SPR_BEXP, 32769, 5, (->CDoom.a_scream).pointer, CDoom::Statenum::S_BEXP3, 0, 0},            # S_BEXP2
    {CDoom::Spritenum::SPR_BEXP, 32770, 5, Pointer(Void).null, CDoom::Statenum::S_BEXP4, 0, 0},                    # S_BEXP3
    {CDoom::Spritenum::SPR_BEXP, 32771, 10, (->CDoom.a_explode).pointer, CDoom::Statenum::S_BEXP5, 0, 0},          # S_BEXP4
    {CDoom::Spritenum::SPR_BEXP, 32772, 10, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                    # S_BEXP5
    {CDoom::Spritenum::SPR_FCAN, 32768, 4, Pointer(Void).null, CDoom::Statenum::S_BBAR2, 0, 0},                    # S_BBAR1
    {CDoom::Spritenum::SPR_FCAN, 32769, 4, Pointer(Void).null, CDoom::Statenum::S_BBAR3, 0, 0},                    # S_BBAR2
    {CDoom::Spritenum::SPR_FCAN, 32770, 4, Pointer(Void).null, CDoom::Statenum::S_BBAR1, 0, 0},                    # S_BBAR3
    {CDoom::Spritenum::SPR_BON1, 0, 6, Pointer(Void).null, CDoom::Statenum::S_BON1A, 0, 0},                        # S_BON1
    {CDoom::Spritenum::SPR_BON1, 1, 6, Pointer(Void).null, CDoom::Statenum::S_BON1B, 0, 0},                        # S_BON1A
    {CDoom::Spritenum::SPR_BON1, 2, 6, Pointer(Void).null, CDoom::Statenum::S_BON1C, 0, 0},                        # S_BON1B
    {CDoom::Spritenum::SPR_BON1, 3, 6, Pointer(Void).null, CDoom::Statenum::S_BON1D, 0, 0},                        # S_BON1C
    {CDoom::Spritenum::SPR_BON1, 2, 6, Pointer(Void).null, CDoom::Statenum::S_BON1E, 0, 0},                        # S_BON1D
    {CDoom::Spritenum::SPR_BON1, 1, 6, Pointer(Void).null, CDoom::Statenum::S_BON1, 0, 0},                         # S_BON1E
    {CDoom::Spritenum::SPR_BON2, 0, 6, Pointer(Void).null, CDoom::Statenum::S_BON2A, 0, 0},                        # S_BON2
    {CDoom::Spritenum::SPR_BON2, 1, 6, Pointer(Void).null, CDoom::Statenum::S_BON2B, 0, 0},                        # S_BON2A
    {CDoom::Spritenum::SPR_BON2, 2, 6, Pointer(Void).null, CDoom::Statenum::S_BON2C, 0, 0},                        # S_BON2B
    {CDoom::Spritenum::SPR_BON2, 3, 6, Pointer(Void).null, CDoom::Statenum::S_BON2D, 0, 0},                        # S_BON2C
    {CDoom::Spritenum::SPR_BON2, 2, 6, Pointer(Void).null, CDoom::Statenum::S_BON2E, 0, 0},                        # S_BON2D
    {CDoom::Spritenum::SPR_BON2, 1, 6, Pointer(Void).null, CDoom::Statenum::S_BON2, 0, 0},                         # S_BON2E
    {CDoom::Spritenum::SPR_BKEY, 0, 10, Pointer(Void).null, CDoom::Statenum::S_BKEY2, 0, 0},                       # S_BKEY
    {CDoom::Spritenum::SPR_BKEY, 32769, 10, Pointer(Void).null, CDoom::Statenum::S_BKEY, 0, 0},                    # S_BKEY2
    {CDoom::Spritenum::SPR_RKEY, 0, 10, Pointer(Void).null, CDoom::Statenum::S_RKEY2, 0, 0},                       # S_RKEY
    {CDoom::Spritenum::SPR_RKEY, 32769, 10, Pointer(Void).null, CDoom::Statenum::S_RKEY, 0, 0},                    # S_RKEY2
    {CDoom::Spritenum::SPR_YKEY, 0, 10, Pointer(Void).null, CDoom::Statenum::S_YKEY2, 0, 0},                       # S_YKEY
    {CDoom::Spritenum::SPR_YKEY, 32769, 10, Pointer(Void).null, CDoom::Statenum::S_YKEY, 0, 0},                    # S_YKEY2
    {CDoom::Spritenum::SPR_BSKU, 0, 10, Pointer(Void).null, CDoom::Statenum::S_BSKULL2, 0, 0},                     # S_BSKULL
    {CDoom::Spritenum::SPR_BSKU, 32769, 10, Pointer(Void).null, CDoom::Statenum::S_BSKULL, 0, 0},                  # S_BSKULL2
    {CDoom::Spritenum::SPR_RSKU, 0, 10, Pointer(Void).null, CDoom::Statenum::S_RSKULL2, 0, 0},                     # S_RSKULL
    {CDoom::Spritenum::SPR_RSKU, 32769, 10, Pointer(Void).null, CDoom::Statenum::S_RSKULL, 0, 0},                  # S_RSKULL2
    {CDoom::Spritenum::SPR_YSKU, 0, 10, Pointer(Void).null, CDoom::Statenum::S_YSKULL2, 0, 0},                     # S_YSKULL
    {CDoom::Spritenum::SPR_YSKU, 32769, 10, Pointer(Void).null, CDoom::Statenum::S_YSKULL, 0, 0},                  # S_YSKULL2
    {CDoom::Spritenum::SPR_STIM, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_STIM
    {CDoom::Spritenum::SPR_MEDI, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_MEDI
    {CDoom::Spritenum::SPR_SOUL, 32768, 6, Pointer(Void).null, CDoom::Statenum::S_SOUL2, 0, 0},                    # S_SOUL
    {CDoom::Spritenum::SPR_SOUL, 32769, 6, Pointer(Void).null, CDoom::Statenum::S_SOUL3, 0, 0},                    # S_SOUL2
    {CDoom::Spritenum::SPR_SOUL, 32770, 6, Pointer(Void).null, CDoom::Statenum::S_SOUL4, 0, 0},                    # S_SOUL3
    {CDoom::Spritenum::SPR_SOUL, 32771, 6, Pointer(Void).null, CDoom::Statenum::S_SOUL5, 0, 0},                    # S_SOUL4
    {CDoom::Spritenum::SPR_SOUL, 32770, 6, Pointer(Void).null, CDoom::Statenum::S_SOUL6, 0, 0},                    # S_SOUL5
    {CDoom::Spritenum::SPR_SOUL, 32769, 6, Pointer(Void).null, CDoom::Statenum::S_SOUL, 0, 0},                     # S_SOUL6
    {CDoom::Spritenum::SPR_PINV, 32768, 6, Pointer(Void).null, CDoom::Statenum::S_PINV2, 0, 0},                    # S_PINV
    {CDoom::Spritenum::SPR_PINV, 32769, 6, Pointer(Void).null, CDoom::Statenum::S_PINV3, 0, 0},                    # S_PINV2
    {CDoom::Spritenum::SPR_PINV, 32770, 6, Pointer(Void).null, CDoom::Statenum::S_PINV4, 0, 0},                    # S_PINV3
    {CDoom::Spritenum::SPR_PINV, 32771, 6, Pointer(Void).null, CDoom::Statenum::S_PINV, 0, 0},                     # S_PINV4
    {CDoom::Spritenum::SPR_PSTR, 32768, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                    # S_PSTR
    {CDoom::Spritenum::SPR_PINS, 32768, 6, Pointer(Void).null, CDoom::Statenum::S_PINS2, 0, 0},                    # S_PINS
    {CDoom::Spritenum::SPR_PINS, 32769, 6, Pointer(Void).null, CDoom::Statenum::S_PINS3, 0, 0},                    # S_PINS2
    {CDoom::Spritenum::SPR_PINS, 32770, 6, Pointer(Void).null, CDoom::Statenum::S_PINS4, 0, 0},                    # S_PINS3
    {CDoom::Spritenum::SPR_PINS, 32771, 6, Pointer(Void).null, CDoom::Statenum::S_PINS, 0, 0},                     # S_PINS4
    {CDoom::Spritenum::SPR_MEGA, 32768, 6, Pointer(Void).null, CDoom::Statenum::S_MEGA2, 0, 0},                    # S_MEGA
    {CDoom::Spritenum::SPR_MEGA, 32769, 6, Pointer(Void).null, CDoom::Statenum::S_MEGA3, 0, 0},                    # S_MEGA2
    {CDoom::Spritenum::SPR_MEGA, 32770, 6, Pointer(Void).null, CDoom::Statenum::S_MEGA4, 0, 0},                    # S_MEGA3
    {CDoom::Spritenum::SPR_MEGA, 32771, 6, Pointer(Void).null, CDoom::Statenum::S_MEGA, 0, 0},                     # S_MEGA4
    {CDoom::Spritenum::SPR_SUIT, 32768, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                    # S_SUIT
    {CDoom::Spritenum::SPR_PMAP, 32768, 6, Pointer(Void).null, CDoom::Statenum::S_PMAP2, 0, 0},                    # S_PMAP
    {CDoom::Spritenum::SPR_PMAP, 32769, 6, Pointer(Void).null, CDoom::Statenum::S_PMAP3, 0, 0},                    # S_PMAP2
    {CDoom::Spritenum::SPR_PMAP, 32770, 6, Pointer(Void).null, CDoom::Statenum::S_PMAP4, 0, 0},                    # S_PMAP3
    {CDoom::Spritenum::SPR_PMAP, 32771, 6, Pointer(Void).null, CDoom::Statenum::S_PMAP5, 0, 0},                    # S_PMAP4
    {CDoom::Spritenum::SPR_PMAP, 32770, 6, Pointer(Void).null, CDoom::Statenum::S_PMAP6, 0, 0},                    # S_PMAP5
    {CDoom::Spritenum::SPR_PMAP, 32769, 6, Pointer(Void).null, CDoom::Statenum::S_PMAP, 0, 0},                     # S_PMAP6
    {CDoom::Spritenum::SPR_PVIS, 32768, 6, Pointer(Void).null, CDoom::Statenum::S_PVIS2, 0, 0},                    # S_PVIS
    {CDoom::Spritenum::SPR_PVIS, 1, 6, Pointer(Void).null, CDoom::Statenum::S_PVIS, 0, 0},                         # S_PVIS2
    {CDoom::Spritenum::SPR_CLIP, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_CLIP
    {CDoom::Spritenum::SPR_AMMO, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_AMMO
    {CDoom::Spritenum::SPR_ROCK, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_ROCK
    {CDoom::Spritenum::SPR_BROK, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_BROK
    {CDoom::Spritenum::SPR_CELL, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_CELL
    {CDoom::Spritenum::SPR_CELP, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_CELP
    {CDoom::Spritenum::SPR_SHEL, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_SHEL
    {CDoom::Spritenum::SPR_SBOX, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_SBOX
    {CDoom::Spritenum::SPR_BPAK, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_BPAK
    {CDoom::Spritenum::SPR_BFUG, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_BFUG
    {CDoom::Spritenum::SPR_MGUN, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_MGUN
    {CDoom::Spritenum::SPR_CSAW, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_CSAW
    {CDoom::Spritenum::SPR_LAUN, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_LAUN
    {CDoom::Spritenum::SPR_PLAS, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_PLAS
    {CDoom::Spritenum::SPR_SHOT, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_SHOT
    {CDoom::Spritenum::SPR_SGN2, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_SHOT2
    {CDoom::Spritenum::SPR_COLU, 32768, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                    # S_COLU
    {CDoom::Spritenum::SPR_SMT2, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_STALAG
    {CDoom::Spritenum::SPR_GOR1, 0, 10, Pointer(Void).null, CDoom::Statenum::S_BLOODYTWITCH2, 0, 0},               # S_BLOODYTWITCH
    {CDoom::Spritenum::SPR_GOR1, 1, 15, Pointer(Void).null, CDoom::Statenum::S_BLOODYTWITCH3, 0, 0},               # S_BLOODYTWITCH2
    {CDoom::Spritenum::SPR_GOR1, 2, 8, Pointer(Void).null, CDoom::Statenum::S_BLOODYTWITCH4, 0, 0},                # S_BLOODYTWITCH3
    {CDoom::Spritenum::SPR_GOR1, 1, 6, Pointer(Void).null, CDoom::Statenum::S_BLOODYTWITCH, 0, 0},                 # S_BLOODYTWITCH4
    {CDoom::Spritenum::SPR_PLAY, 13, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                       # S_DEADTORSO
    {CDoom::Spritenum::SPR_PLAY, 18, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                       # S_DEADBOTTOM
    {CDoom::Spritenum::SPR_POL2, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_HEADSONSTICK
    {CDoom::Spritenum::SPR_POL5, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_GIBS
    {CDoom::Spritenum::SPR_POL4, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_HEADONASTICK
    {CDoom::Spritenum::SPR_POL3, 32768, 6, Pointer(Void).null, CDoom::Statenum::S_HEADCANDLES2, 0, 0},             # S_HEADCANDLES
    {CDoom::Spritenum::SPR_POL3, 32769, 6, Pointer(Void).null, CDoom::Statenum::S_HEADCANDLES, 0, 0},              # S_HEADCANDLES2
    {CDoom::Spritenum::SPR_POL1, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_DEADSTICK
    {CDoom::Spritenum::SPR_POL6, 0, 6, Pointer(Void).null, CDoom::Statenum::S_LIVESTICK2, 0, 0},                   # S_LIVESTICK
    {CDoom::Spritenum::SPR_POL6, 1, 8, Pointer(Void).null, CDoom::Statenum::S_LIVESTICK, 0, 0},                    # S_LIVESTICK2
    {CDoom::Spritenum::SPR_GOR2, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_MEAT2
    {CDoom::Spritenum::SPR_GOR3, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_MEAT3
    {CDoom::Spritenum::SPR_GOR4, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_MEAT4
    {CDoom::Spritenum::SPR_GOR5, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_MEAT5
    {CDoom::Spritenum::SPR_SMIT, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_STALAGTITE
    {CDoom::Spritenum::SPR_COL1, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_TALLGRNCOL
    {CDoom::Spritenum::SPR_COL2, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_SHRTGRNCOL
    {CDoom::Spritenum::SPR_COL3, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_TALLREDCOL
    {CDoom::Spritenum::SPR_COL4, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_SHRTREDCOL
    {CDoom::Spritenum::SPR_CAND, 32768, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                    # S_CANDLESTIK
    {CDoom::Spritenum::SPR_CBRA, 32768, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                    # S_CANDELABRA
    {CDoom::Spritenum::SPR_COL6, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_SKULLCOL
    {CDoom::Spritenum::SPR_TRE1, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_TORCHTREE
    {CDoom::Spritenum::SPR_TRE2, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_BIGTREE
    {CDoom::Spritenum::SPR_ELEC, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_TECHPILLAR
    {CDoom::Spritenum::SPR_CEYE, 32768, 6, Pointer(Void).null, CDoom::Statenum::S_EVILEYE2, 0, 0},                 # S_EVILEYE
    {CDoom::Spritenum::SPR_CEYE, 32769, 6, Pointer(Void).null, CDoom::Statenum::S_EVILEYE3, 0, 0},                 # S_EVILEYE2
    {CDoom::Spritenum::SPR_CEYE, 32770, 6, Pointer(Void).null, CDoom::Statenum::S_EVILEYE4, 0, 0},                 # S_EVILEYE3
    {CDoom::Spritenum::SPR_CEYE, 32769, 6, Pointer(Void).null, CDoom::Statenum::S_EVILEYE, 0, 0},                  # S_EVILEYE4
    {CDoom::Spritenum::SPR_FSKU, 32768, 6, Pointer(Void).null, CDoom::Statenum::S_FLOATSKULL2, 0, 0},              # S_FLOATSKULL
    {CDoom::Spritenum::SPR_FSKU, 32769, 6, Pointer(Void).null, CDoom::Statenum::S_FLOATSKULL3, 0, 0},              # S_FLOATSKULL2
    {CDoom::Spritenum::SPR_FSKU, 32770, 6, Pointer(Void).null, CDoom::Statenum::S_FLOATSKULL, 0, 0},               # S_FLOATSKULL3
    {CDoom::Spritenum::SPR_COL5, 0, 14, Pointer(Void).null, CDoom::Statenum::S_HEARTCOL2, 0, 0},                   # S_HEARTCOL
    {CDoom::Spritenum::SPR_COL5, 1, 14, Pointer(Void).null, CDoom::Statenum::S_HEARTCOL, 0, 0},                    # S_HEARTCOL2
    {CDoom::Spritenum::SPR_TBLU, 32768, 4, Pointer(Void).null, CDoom::Statenum::S_BLUETORCH2, 0, 0},               # S_BLUETORCH
    {CDoom::Spritenum::SPR_TBLU, 32769, 4, Pointer(Void).null, CDoom::Statenum::S_BLUETORCH3, 0, 0},               # S_BLUETORCH2
    {CDoom::Spritenum::SPR_TBLU, 32770, 4, Pointer(Void).null, CDoom::Statenum::S_BLUETORCH4, 0, 0},               # S_BLUETORCH3
    {CDoom::Spritenum::SPR_TBLU, 32771, 4, Pointer(Void).null, CDoom::Statenum::S_BLUETORCH, 0, 0},                # S_BLUETORCH4
    {CDoom::Spritenum::SPR_TGRN, 32768, 4, Pointer(Void).null, CDoom::Statenum::S_GREENTORCH2, 0, 0},              # S_GREENTORCH
    {CDoom::Spritenum::SPR_TGRN, 32769, 4, Pointer(Void).null, CDoom::Statenum::S_GREENTORCH3, 0, 0},              # S_GREENTORCH2
    {CDoom::Spritenum::SPR_TGRN, 32770, 4, Pointer(Void).null, CDoom::Statenum::S_GREENTORCH4, 0, 0},              # S_GREENTORCH3
    {CDoom::Spritenum::SPR_TGRN, 32771, 4, Pointer(Void).null, CDoom::Statenum::S_GREENTORCH, 0, 0},               # S_GREENTORCH4
    {CDoom::Spritenum::SPR_TRED, 32768, 4, Pointer(Void).null, CDoom::Statenum::S_REDTORCH2, 0, 0},                # S_REDTORCH
    {CDoom::Spritenum::SPR_TRED, 32769, 4, Pointer(Void).null, CDoom::Statenum::S_REDTORCH3, 0, 0},                # S_REDTORCH2
    {CDoom::Spritenum::SPR_TRED, 32770, 4, Pointer(Void).null, CDoom::Statenum::S_REDTORCH4, 0, 0},                # S_REDTORCH3
    {CDoom::Spritenum::SPR_TRED, 32771, 4, Pointer(Void).null, CDoom::Statenum::S_REDTORCH, 0, 0},                 # S_REDTORCH4
    {CDoom::Spritenum::SPR_SMBT, 32768, 4, Pointer(Void).null, CDoom::Statenum::S_BTORCHSHRT2, 0, 0},              # S_BTORCHSHRT
    {CDoom::Spritenum::SPR_SMBT, 32769, 4, Pointer(Void).null, CDoom::Statenum::S_BTORCHSHRT3, 0, 0},              # S_BTORCHSHRT2
    {CDoom::Spritenum::SPR_SMBT, 32770, 4, Pointer(Void).null, CDoom::Statenum::S_BTORCHSHRT4, 0, 0},              # S_BTORCHSHRT3
    {CDoom::Spritenum::SPR_SMBT, 32771, 4, Pointer(Void).null, CDoom::Statenum::S_BTORCHSHRT, 0, 0},               # S_BTORCHSHRT4
    {CDoom::Spritenum::SPR_SMGT, 32768, 4, Pointer(Void).null, CDoom::Statenum::S_GTORCHSHRT2, 0, 0},              # S_GTORCHSHRT
    {CDoom::Spritenum::SPR_SMGT, 32769, 4, Pointer(Void).null, CDoom::Statenum::S_GTORCHSHRT3, 0, 0},              # S_GTORCHSHRT2
    {CDoom::Spritenum::SPR_SMGT, 32770, 4, Pointer(Void).null, CDoom::Statenum::S_GTORCHSHRT4, 0, 0},              # S_GTORCHSHRT3
    {CDoom::Spritenum::SPR_SMGT, 32771, 4, Pointer(Void).null, CDoom::Statenum::S_GTORCHSHRT, 0, 0},               # S_GTORCHSHRT4
    {CDoom::Spritenum::SPR_SMRT, 32768, 4, Pointer(Void).null, CDoom::Statenum::S_RTORCHSHRT2, 0, 0},              # S_RTORCHSHRT
    {CDoom::Spritenum::SPR_SMRT, 32769, 4, Pointer(Void).null, CDoom::Statenum::S_RTORCHSHRT3, 0, 0},              # S_RTORCHSHRT2
    {CDoom::Spritenum::SPR_SMRT, 32770, 4, Pointer(Void).null, CDoom::Statenum::S_RTORCHSHRT4, 0, 0},              # S_RTORCHSHRT3
    {CDoom::Spritenum::SPR_SMRT, 32771, 4, Pointer(Void).null, CDoom::Statenum::S_RTORCHSHRT, 0, 0},               # S_RTORCHSHRT4
    {CDoom::Spritenum::SPR_HDB1, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_HANGNOGUTS
    {CDoom::Spritenum::SPR_HDB2, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_HANGBNOBRAIN
    {CDoom::Spritenum::SPR_HDB3, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_HANGTLOOKDN
    {CDoom::Spritenum::SPR_HDB4, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_HANGTSKULL
    {CDoom::Spritenum::SPR_HDB5, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_HANGTLOOKUP
    {CDoom::Spritenum::SPR_HDB6, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_HANGTNOBRAIN
    {CDoom::Spritenum::SPR_POB1, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_COLONGIBS
    {CDoom::Spritenum::SPR_POB2, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_SMALLPOOL
    {CDoom::Spritenum::SPR_BRS1, 0, -1, Pointer(Void).null, CDoom::Statenum::S_NULL, 0, 0},                        # S_BRAINSTEM
    {CDoom::Spritenum::SPR_TLMP, 32768, 4, Pointer(Void).null, CDoom::Statenum::S_TECHLAMP2, 0, 0},                # S_TECHLAMP
    {CDoom::Spritenum::SPR_TLMP, 32769, 4, Pointer(Void).null, CDoom::Statenum::S_TECHLAMP3, 0, 0},                # S_TECHLAMP2
    {CDoom::Spritenum::SPR_TLMP, 32770, 4, Pointer(Void).null, CDoom::Statenum::S_TECHLAMP4, 0, 0},                # S_TECHLAMP3
    {CDoom::Spritenum::SPR_TLMP, 32771, 4, Pointer(Void).null, CDoom::Statenum::S_TECHLAMP, 0, 0},                 # S_TECHLAMP4
    {CDoom::Spritenum::SPR_TLP2, 32768, 4, Pointer(Void).null, CDoom::Statenum::S_TECH2LAMP2, 0, 0},               # S_TECH2LAMP
    {CDoom::Spritenum::SPR_TLP2, 32769, 4, Pointer(Void).null, CDoom::Statenum::S_TECH2LAMP3, 0, 0},               # S_TECH2LAMP2
    {CDoom::Spritenum::SPR_TLP2, 32770, 4, Pointer(Void).null, CDoom::Statenum::S_TECH2LAMP4, 0, 0},               # S_TECH2LAMP3
    {CDoom::Spritenum::SPR_TLP2, 32771, 4, Pointer(Void).null, CDoom::Statenum::S_TECH2LAMP, 0, 0},                # S_TECH2LAMP4
  ]
  @@states : Array(CDoom::State) = Array.new(CDoom::Statenum::NUMSTATES.value, CDoom::State.new)
  @@statedata.each_with_index do |elm, i|
    (@@states.to_unsafe + i).value.sprite = elm[0]
    (@@states.to_unsafe + i).value.frame = elm[1]
    (@@states.to_unsafe + i).value.tics = elm[2]
    (@@states.to_unsafe + i).value.action = elm[3]
    (@@states.to_unsafe + i).value.nextstate = elm[4]
    (@@states.to_unsafe + i).value.misc1 = elm[5]
    (@@states.to_unsafe + i).value.misc2 = elm[6]
  end

  CDoom.states = @@states.to_unsafe

  @@mobjinfo_data : Array(Tuple(
    LibC::Int,
    LibC::Int,
    LibC::Int,
    LibC::Int,
    LibC::Int,
    LibC::Int,
    LibC::Int,
    LibC::Int,
    LibC::Int,
    LibC::Int,
    LibC::Int,
    LibC::Int,
    LibC::Int,
    LibC::Int,
    LibC::Int,
    LibC::Int,
    LibC::Int,
    LibC::Int,
    LibC::Int,
    LibC::Int,
    LibC::Int,
    LibC::Int,
    LibC::Int,
  )) = [
    {                                                                                                                                                                                       # MT_PLAYER
      -1,                                                                                                                                                                                   # doomednum
      CDoom::Statenum::S_PLAY.value,                                                                                                                                                        # spawnstate
      100,                                                                                                                                                                                  # spawnhealth
      CDoom::Statenum::S_PLAY_RUN1.value,                                                                                                                                                   # seestate
      CDoom::Sfxenum::SFX_None.value,                                                                                                                                                       # seesound
      0,                                                                                                                                                                                    # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                                                                                                                       # attacksound
      CDoom::Statenum::S_PLAY_PAIN.value,                                                                                                                                                   # painstate
      255,                                                                                                                                                                                  # painchance
      CDoom::Sfxenum::SFX_plpain.value,                                                                                                                                                     # painsound
      CDoom::Statenum::S_NULL.value,                                                                                                                                                        # meleestate
      CDoom::Statenum::S_PLAY_ATK1.value,                                                                                                                                                   # missilestate
      CDoom::Statenum::S_PLAY_DIE1.value,                                                                                                                                                   # deathstate
      CDoom::Statenum::S_PLAY_XDIE1.value,                                                                                                                                                  # xdeathstate
      CDoom::Sfxenum::SFX_pldeth.value,                                                                                                                                                     # deathsound
      0,                                                                                                                                                                                    # speed
      16 * FRACUNIT,                                                                                                                                                                        # radius
      56 * FRACUNIT,                                                                                                                                                                        # height
      100,                                                                                                                                                                                  # mass
      0,                                                                                                                                                                                    # damage
      CDoom::Sfxenum::SFX_None.value,                                                                                                                                                       # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SHOOTABLE.value | CDoom::Mobjflag::MF_DROPOFF.value | CDoom::Mobjflag::MF_PICKUP.value | CDoom::Mobjflag::MF_NOTDMATCH.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                                                                                        # raisestate
    },
    {                                                                                                                # MT_POSSESSED
      3004,                                                                                                          # doomednum
      CDoom::Statenum::S_POSS_STND.value,                                                                            # spawnstate
      20,                                                                                                            # spawnhealth
      CDoom::Statenum::S_POSS_RUN1.value,                                                                            # seestate
      CDoom::Sfxenum::SFX_posit1.value,                                                                              # seesound
      8,                                                                                                             # reactiontime
      CDoom::Sfxenum::SFX_pistol.value,                                                                              # attacksound
      CDoom::Statenum::S_POSS_PAIN.value,                                                                            # painstate
      200,                                                                                                           # painchance
      CDoom::Sfxenum::SFX_popain.value,                                                                              # painsound
      0,                                                                                                             # meleestate
      CDoom::Statenum::S_POSS_ATK1.value,                                                                            # missilestate
      CDoom::Statenum::S_POSS_DIE1.value,                                                                            # deathstate
      CDoom::Statenum::S_POSS_XDIE1.value,                                                                           # xdeathstate
      CDoom::Sfxenum::SFX_podth1.value,                                                                              # deathsound
      8,                                                                                                             # speed
      20 * FRACUNIT,                                                                                                 # radius
      56 * FRACUNIT,                                                                                                 # height
      100,                                                                                                           # mass
      0,                                                                                                             # damage
      CDoom::Sfxenum::SFX_posact.value,                                                                              # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SHOOTABLE.value | CDoom::Mobjflag::MF_COUNTKILL.value), # flags
      CDoom::Statenum::S_POSS_RAISE1.value,                                                                          # raisestate
    },
    {                                                                                                                # MT_SHOTGUY
      9,                                                                                                             # doomednum
      CDoom::Statenum::S_SPOS_STND.value,                                                                            # spawnstate
      30,                                                                                                            # spawnhealth
      CDoom::Statenum::S_SPOS_RUN1.value,                                                                            # seestate
      CDoom::Sfxenum::SFX_posit2.value,                                                                              # seesound
      8,                                                                                                             # reactiontime
      0,                                                                                                             # attacksound
      CDoom::Statenum::S_SPOS_PAIN.value,                                                                            # painstate
      170,                                                                                                           # painchance
      CDoom::Sfxenum::SFX_popain.value,                                                                              # painsound
      0,                                                                                                             # meleestate
      CDoom::Statenum::S_SPOS_ATK1.value,                                                                            # missilestate
      CDoom::Statenum::S_SPOS_DIE1.value,                                                                            # deathstate
      CDoom::Statenum::S_SPOS_XDIE1.value,                                                                           # xdeathstate
      CDoom::Sfxenum::SFX_podth2.value,                                                                              # deathsound
      8,                                                                                                             # speed
      20 * FRACUNIT,                                                                                                 # radius
      56 * FRACUNIT,                                                                                                 # height
      100,                                                                                                           # mass
      0,                                                                                                             # damage
      CDoom::Sfxenum::SFX_posact.value,                                                                              # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SHOOTABLE.value | CDoom::Mobjflag::MF_COUNTKILL.value), # flags
      CDoom::Statenum::S_SPOS_RAISE1.value,                                                                          # raisestate
    },
    {                                                                                                                # MT_VILE
      64,                                                                                                            # doomednum
      CDoom::Statenum::S_VILE_STND.value,                                                                            # spawnstate
      700,                                                                                                           # spawnhealth
      CDoom::Statenum::S_VILE_RUN1.value,                                                                            # seestate
      CDoom::Sfxenum::SFX_vilsit.value,                                                                              # seesound
      8,                                                                                                             # reactiontime
      0,                                                                                                             # attacksound
      CDoom::Statenum::S_VILE_PAIN.value,                                                                            # painstate
      10,                                                                                                            # painchance
      CDoom::Sfxenum::SFX_vipain.value,                                                                              # painsound
      0,                                                                                                             # meleestate
      CDoom::Statenum::S_VILE_ATK1.value,                                                                            # missilestate
      CDoom::Statenum::S_VILE_DIE1.value,                                                                            # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                 # xdeathstate
      CDoom::Sfxenum::SFX_vildth.value,                                                                              # deathsound
      15,                                                                                                            # speed
      20 * FRACUNIT,                                                                                                 # radius
      56 * FRACUNIT,                                                                                                 # height
      500,                                                                                                           # mass
      0,                                                                                                             # damage
      CDoom::Sfxenum::SFX_vilact.value,                                                                              # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SHOOTABLE.value | CDoom::Mobjflag::MF_COUNTKILL.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                 # raisestate
    },
    {                                                                               # MT_FIRE
      -1,                                                                           # doomednum
      CDoom::Statenum::S_FIRE1.value,                                               # spawnstate
      1000,                                                                         # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                # seestate
      CDoom::Sfxenum::SFX_None.value,                                               # seesound
      8,                                                                            # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                               # attacksound
      CDoom::Statenum::S_NULL.value,                                                # painstate
      0,                                                                            # painchance
      CDoom::Sfxenum::SFX_None.value,                                               # painsound
      CDoom::Statenum::S_NULL.value,                                                # meleestate
      CDoom::Statenum::S_NULL.value,                                                # missilestate
      CDoom::Statenum::S_NULL.value,                                                # deathstate
      CDoom::Statenum::S_NULL.value,                                                # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                               # deathsound
      0,                                                                            # speed
      20 * FRACUNIT,                                                                # radius
      16 * FRACUNIT,                                                                # height
      100,                                                                          # mass
      0,                                                                            # damage
      CDoom::Sfxenum::SFX_None.value,                                               # activesound
      (CDoom::Mobjflag::MF_NOBLOCKMAP.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                # raisestate
    },
    {                                                                                                                # MT_UNDEAD
      66,                                                                                                            # doomednum
      CDoom::Statenum::S_SKEL_STND.value,                                                                            # spawnstate
      300,                                                                                                           # spawnhealth
      CDoom::Statenum::S_SKEL_RUN1.value,                                                                            # seestate
      CDoom::Sfxenum::SFX_skesit.value,                                                                              # seesound
      8,                                                                                                             # reactiontime
      0,                                                                                                             # attacksound
      CDoom::Statenum::S_SKEL_PAIN.value,                                                                            # painstate
      100,                                                                                                           # painchance
      CDoom::Sfxenum::SFX_popain.value,                                                                              # painsound
      CDoom::Statenum::S_SKEL_FIST1.value,                                                                           # meleestate
      CDoom::Statenum::S_SKEL_MISS1.value,                                                                           # missilestate
      CDoom::Statenum::S_SKEL_DIE1.value,                                                                            # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                 # xdeathstate
      CDoom::Sfxenum::SFX_skedth.value,                                                                              # deathsound
      10,                                                                                                            # speed
      20 * FRACUNIT,                                                                                                 # radius
      56 * FRACUNIT,                                                                                                 # height
      500,                                                                                                           # mass
      0,                                                                                                             # damage
      CDoom::Sfxenum::SFX_skeact.value,                                                                              # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SHOOTABLE.value | CDoom::Mobjflag::MF_COUNTKILL.value), # flags
      CDoom::Statenum::S_SKEL_RAISE1.value,                                                                          # raisestate
    },
    {                                                                                                                                                       # MT_TRACER
      -1,                                                                                                                                                   # doomednum
      CDoom::Statenum::S_TRACER.value,                                                                                                                      # spawnstate
      1000,                                                                                                                                                 # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                                                                                        # seestate
      CDoom::Sfxenum::SFX_skeatk.value,                                                                                                                     # seesound
      8,                                                                                                                                                    # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # attacksound
      CDoom::Statenum::S_NULL.value,                                                                                                                        # painstate
      0,                                                                                                                                                    # painchance
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # painsound
      CDoom::Statenum::S_NULL.value,                                                                                                                        # meleestate
      CDoom::Statenum::S_NULL.value,                                                                                                                        # missilestate
      CDoom::Statenum::S_TRACEEXP1.value,                                                                                                                   # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                                                        # xdeathstate
      CDoom::Sfxenum::SFX_barexp.value,                                                                                                                     # deathsound
      10 * FRACUNIT,                                                                                                                                        # speed
      11 * FRACUNIT,                                                                                                                                        # radius
      8 * FRACUNIT,                                                                                                                                         # height
      100,                                                                                                                                                  # mass
      10,                                                                                                                                                   # damage
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # activesound
      (CDoom::Mobjflag::MF_NOBLOCKMAP.value | CDoom::Mobjflag::MF_MISSILE.value | CDoom::Mobjflag::MF_DROPOFF.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                                                        # raisestate
    },
    {                                                                               # MT_SMOKE
      -1,                                                                           # doomednum
      CDoom::Statenum::S_SMOKE1.value,                                              # spawnstate
      1000,                                                                         # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                # seestate
      CDoom::Sfxenum::SFX_None.value,                                               # seesound
      8,                                                                            # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                               # attacksound
      CDoom::Statenum::S_NULL.value,                                                # painstate
      0,                                                                            # painchance
      CDoom::Sfxenum::SFX_None.value,                                               # painsound
      CDoom::Statenum::S_NULL.value,                                                # meleestate
      CDoom::Statenum::S_NULL.value,                                                # missilestate
      CDoom::Statenum::S_NULL.value,                                                # deathstate
      CDoom::Statenum::S_NULL.value,                                                # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                               # deathsound
      0,                                                                            # speed
      20 * FRACUNIT,                                                                # radius
      16 * FRACUNIT,                                                                # height
      100,                                                                          # mass
      0,                                                                            # damage
      CDoom::Sfxenum::SFX_None.value,                                               # activesound
      (CDoom::Mobjflag::MF_NOBLOCKMAP.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                # raisestate
    },
    {                                                                                                                # MT_FATSO
      67,                                                                                                            # doomednum
      CDoom::Statenum::S_FATT_STND.value,                                                                            # spawnstate
      600,                                                                                                           # spawnhealth
      CDoom::Statenum::S_FATT_RUN1.value,                                                                            # seestate
      CDoom::Sfxenum::SFX_mansit.value,                                                                              # seesound
      8,                                                                                                             # reactiontime
      0,                                                                                                             # attacksound
      CDoom::Statenum::S_FATT_PAIN.value,                                                                            # painstate
      80,                                                                                                            # painchance
      CDoom::Sfxenum::SFX_mnpain.value,                                                                              # painsound
      0,                                                                                                             # meleestate
      CDoom::Statenum::S_FATT_ATK1.value,                                                                            # missilestate
      CDoom::Statenum::S_FATT_DIE1.value,                                                                            # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                 # xdeathstate
      CDoom::Sfxenum::SFX_mandth.value,                                                                              # deathsound
      8,                                                                                                             # speed
      48 * FRACUNIT,                                                                                                 # radius
      64 * FRACUNIT,                                                                                                 # height
      1000,                                                                                                          # mass
      0,                                                                                                             # damage
      CDoom::Sfxenum::SFX_posact.value,                                                                              # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SHOOTABLE.value | CDoom::Mobjflag::MF_COUNTKILL.value), # flags
      CDoom::Statenum::S_FATT_RAISE1.value,                                                                          # raisestate
    },
    {                                                                                                                                                       # MT_FATSHOT
      -1,                                                                                                                                                   # doomednum
      CDoom::Statenum::S_FATSHOT1.value,                                                                                                                    # spawnstate
      1000,                                                                                                                                                 # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                                                                                        # seestate
      CDoom::Sfxenum::SFX_firsht.value,                                                                                                                     # seesound
      8,                                                                                                                                                    # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # attacksound
      CDoom::Statenum::S_NULL.value,                                                                                                                        # painstate
      0,                                                                                                                                                    # painchance
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # painsound
      CDoom::Statenum::S_NULL.value,                                                                                                                        # meleestate
      CDoom::Statenum::S_NULL.value,                                                                                                                        # missilestate
      CDoom::Statenum::S_FATSHOTX1.value,                                                                                                                   # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                                                        # xdeathstate
      CDoom::Sfxenum::SFX_firxpl.value,                                                                                                                     # deathsound
      20 * FRACUNIT,                                                                                                                                        # speed
      6 * FRACUNIT,                                                                                                                                         # radius
      8 * FRACUNIT,                                                                                                                                         # height
      100,                                                                                                                                                  # mass
      8,                                                                                                                                                    # damage
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # activesound
      (CDoom::Mobjflag::MF_NOBLOCKMAP.value | CDoom::Mobjflag::MF_MISSILE.value | CDoom::Mobjflag::MF_DROPOFF.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                                                        # raisestate
    },
    {                                                                                                                # MT_CHAINGUY
      65,                                                                                                            # doomednum
      CDoom::Statenum::S_CPOS_STND.value,                                                                            # spawnstate
      70,                                                                                                            # spawnhealth
      CDoom::Statenum::S_CPOS_RUN1.value,                                                                            # seestate
      CDoom::Sfxenum::SFX_posit2.value,                                                                              # seesound
      8,                                                                                                             # reactiontime
      0,                                                                                                             # attacksound
      CDoom::Statenum::S_CPOS_PAIN.value,                                                                            # painstate
      170,                                                                                                           # painchance
      CDoom::Sfxenum::SFX_popain.value,                                                                              # painsound
      0,                                                                                                             # meleestate
      CDoom::Statenum::S_CPOS_ATK1.value,                                                                            # missilestate
      CDoom::Statenum::S_CPOS_DIE1.value,                                                                            # deathstate
      CDoom::Statenum::S_CPOS_XDIE1.value,                                                                           # xdeathstate
      CDoom::Sfxenum::SFX_podth2.value,                                                                              # deathsound
      8,                                                                                                             # speed
      20 * FRACUNIT,                                                                                                 # radius
      56 * FRACUNIT,                                                                                                 # height
      100,                                                                                                           # mass
      0,                                                                                                             # damage
      CDoom::Sfxenum::SFX_posact.value,                                                                              # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SHOOTABLE.value | CDoom::Mobjflag::MF_COUNTKILL.value), # flags
      CDoom::Statenum::S_CPOS_RAISE1.value,                                                                          # raisestate
    },
    {                                                                                                                # MT_TROOP
      3001,                                                                                                          # doomednum
      CDoom::Statenum::S_TROO_STND.value,                                                                            # spawnstate
      60,                                                                                                            # spawnhealth
      CDoom::Statenum::S_TROO_RUN1.value,                                                                            # seestate
      CDoom::Sfxenum::SFX_bgsit1.value,                                                                              # seesound
      8,                                                                                                             # reactiontime
      0,                                                                                                             # attacksound
      CDoom::Statenum::S_TROO_PAIN.value,                                                                            # painstate
      200,                                                                                                           # painchance
      CDoom::Sfxenum::SFX_popain.value,                                                                              # painsound
      CDoom::Statenum::S_TROO_ATK1.value,                                                                            # meleestate
      CDoom::Statenum::S_TROO_ATK1.value,                                                                            # missilestate
      CDoom::Statenum::S_TROO_DIE1.value,                                                                            # deathstate
      CDoom::Statenum::S_TROO_XDIE1.value,                                                                           # xdeathstate
      CDoom::Sfxenum::SFX_bgdth1.value,                                                                              # deathsound
      8,                                                                                                             # speed
      20 * FRACUNIT,                                                                                                 # radius
      56 * FRACUNIT,                                                                                                 # height
      100,                                                                                                           # mass
      0,                                                                                                             # damage
      CDoom::Sfxenum::SFX_bgact.value,                                                                               # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SHOOTABLE.value | CDoom::Mobjflag::MF_COUNTKILL.value), # flags
      CDoom::Statenum::S_TROO_RAISE1.value,                                                                          # raisestate
    },
    {                                                                                                                # MT_SERGEANT
      3002,                                                                                                          # doomednum
      CDoom::Statenum::S_SARG_STND.value,                                                                            # spawnstate
      150,                                                                                                           # spawnhealth
      CDoom::Statenum::S_SARG_RUN1.value,                                                                            # seestate
      CDoom::Sfxenum::SFX_sgtsit.value,                                                                              # seesound
      8,                                                                                                             # reactiontime
      CDoom::Sfxenum::SFX_sgtatk.value,                                                                              # attacksound
      CDoom::Statenum::S_SARG_PAIN.value,                                                                            # painstate
      180,                                                                                                           # painchance
      CDoom::Sfxenum::SFX_dmpain.value,                                                                              # painsound
      CDoom::Statenum::S_SARG_ATK1.value,                                                                            # meleestate
      0,                                                                                                             # missilestate
      CDoom::Statenum::S_SARG_DIE1.value,                                                                            # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                 # xdeathstate
      CDoom::Sfxenum::SFX_sgtdth.value,                                                                              # deathsound
      10,                                                                                                            # speed
      30 * FRACUNIT,                                                                                                 # radius
      56 * FRACUNIT,                                                                                                 # height
      400,                                                                                                           # mass
      0,                                                                                                             # damage
      CDoom::Sfxenum::SFX_dmact.value,                                                                               # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SHOOTABLE.value | CDoom::Mobjflag::MF_COUNTKILL.value), # flags
      CDoom::Statenum::S_SARG_RAISE1.value,                                                                          # raisestate
    },
    {                                                                                                                                                   # MT_SHADOWS
      58,                                                                                                                                               # doomednum
      CDoom::Statenum::S_SARG_STND.value,                                                                                                               # spawnstate
      150,                                                                                                                                              # spawnhealth
      CDoom::Statenum::S_SARG_RUN1.value,                                                                                                               # seestate
      CDoom::Sfxenum::SFX_sgtsit.value,                                                                                                                 # seesound
      8,                                                                                                                                                # reactiontime
      CDoom::Sfxenum::SFX_sgtatk.value,                                                                                                                 # attacksound
      CDoom::Statenum::S_SARG_PAIN.value,                                                                                                               # painstate
      180,                                                                                                                                              # painchance
      CDoom::Sfxenum::SFX_dmpain.value,                                                                                                                 # painsound
      CDoom::Statenum::S_SARG_ATK1.value,                                                                                                               # meleestate
      0,                                                                                                                                                # missilestate
      CDoom::Statenum::S_SARG_DIE1.value,                                                                                                               # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                                                    # xdeathstate
      CDoom::Sfxenum::SFX_sgtdth.value,                                                                                                                 # deathsound
      10,                                                                                                                                               # speed
      30 * FRACUNIT,                                                                                                                                    # radius
      56 * FRACUNIT,                                                                                                                                    # height
      400,                                                                                                                                              # mass
      0,                                                                                                                                                # damage
      CDoom::Sfxenum::SFX_dmact.value,                                                                                                                  # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SHOOTABLE.value | CDoom::Mobjflag::MF_SHADOW.value | CDoom::Mobjflag::MF_COUNTKILL.value), # flags
      CDoom::Statenum::S_SARG_RAISE1.value,                                                                                                             # raisestate
    },
    {                                                                                                                                                                                        # MT_HEAD
      3005,                                                                                                                                                                                  # doomednum
      CDoom::Statenum::S_HEAD_STND.value,                                                                                                                                                    # spawnstate
      400,                                                                                                                                                                                   # spawnhealth
      CDoom::Statenum::S_HEAD_RUN1.value,                                                                                                                                                    # seestate
      CDoom::Sfxenum::SFX_cacsit.value,                                                                                                                                                      # seesound
      8,                                                                                                                                                                                     # reactiontime
      0,                                                                                                                                                                                     # attacksound
      CDoom::Statenum::S_HEAD_PAIN.value,                                                                                                                                                    # painstate
      128,                                                                                                                                                                                   # painchance
      CDoom::Sfxenum::SFX_dmpain.value,                                                                                                                                                      # painsound
      0,                                                                                                                                                                                     # meleestate
      CDoom::Statenum::S_HEAD_ATK1.value,                                                                                                                                                    # missilestate
      CDoom::Statenum::S_HEAD_DIE1.value,                                                                                                                                                    # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                                                                                         # xdeathstate
      CDoom::Sfxenum::SFX_cacdth.value,                                                                                                                                                      # deathsound
      8,                                                                                                                                                                                     # speed
      31 * FRACUNIT,                                                                                                                                                                         # radius
      56 * FRACUNIT,                                                                                                                                                                         # height
      400,                                                                                                                                                                                   # mass
      0,                                                                                                                                                                                     # damage
      CDoom::Sfxenum::SFX_dmact.value,                                                                                                                                                       # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SHOOTABLE.value | CDoom::Mobjflag::MF_FLOAT.value | CDoom::Mobjflag::MF_NOGRAVITY.value | CDoom::Mobjflag::MF_COUNTKILL.value), # flags
      CDoom::Statenum::S_HEAD_RAISE1.value,                                                                                                                                                  # raisestate
    },
    {                                                                                                                # MT_BRUISER
      3003,                                                                                                          # doomednum
      CDoom::Statenum::S_BOSS_STND.value,                                                                            # spawnstate
      1000,                                                                                                          # spawnhealth
      CDoom::Statenum::S_BOSS_RUN1.value,                                                                            # seestate
      CDoom::Sfxenum::SFX_brssit.value,                                                                              # seesound
      8,                                                                                                             # reactiontime
      0,                                                                                                             # attacksound
      CDoom::Statenum::S_BOSS_PAIN.value,                                                                            # painstate
      50,                                                                                                            # painchance
      CDoom::Sfxenum::SFX_dmpain.value,                                                                              # painsound
      CDoom::Statenum::S_BOSS_ATK1.value,                                                                            # meleestate
      CDoom::Statenum::S_BOSS_ATK1.value,                                                                            # missilestate
      CDoom::Statenum::S_BOSS_DIE1.value,                                                                            # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                 # xdeathstate
      CDoom::Sfxenum::SFX_brsdth.value,                                                                              # deathsound
      8,                                                                                                             # speed
      24 * FRACUNIT,                                                                                                 # radius
      64 * FRACUNIT,                                                                                                 # height
      1000,                                                                                                          # mass
      0,                                                                                                             # damage
      CDoom::Sfxenum::SFX_dmact.value,                                                                               # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SHOOTABLE.value | CDoom::Mobjflag::MF_COUNTKILL.value), # flags
      CDoom::Statenum::S_BOSS_RAISE1.value,                                                                          # raisestate
    },
    {                                                                                                                                                       # MT_BRUISERSHOT
      -1,                                                                                                                                                   # doomednum
      CDoom::Statenum::S_BRBALL1.value,                                                                                                                     # spawnstate
      1000,                                                                                                                                                 # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                                                                                        # seestate
      CDoom::Sfxenum::SFX_firsht.value,                                                                                                                     # seesound
      8,                                                                                                                                                    # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # attacksound
      CDoom::Statenum::S_NULL.value,                                                                                                                        # painstate
      0,                                                                                                                                                    # painchance
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # painsound
      CDoom::Statenum::S_NULL.value,                                                                                                                        # meleestate
      CDoom::Statenum::S_NULL.value,                                                                                                                        # missilestate
      CDoom::Statenum::S_BRBALLX1.value,                                                                                                                    # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                                                        # xdeathstate
      CDoom::Sfxenum::SFX_firxpl.value,                                                                                                                     # deathsound
      15 * FRACUNIT,                                                                                                                                        # speed
      6 * FRACUNIT,                                                                                                                                         # radius
      8 * FRACUNIT,                                                                                                                                         # height
      100,                                                                                                                                                  # mass
      8,                                                                                                                                                    # damage
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # activesound
      (CDoom::Mobjflag::MF_NOBLOCKMAP.value | CDoom::Mobjflag::MF_MISSILE.value | CDoom::Mobjflag::MF_DROPOFF.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                                                        # raisestate
    },
    {                                                                                                                # MT_KNIGHT
      69,                                                                                                            # doomednum
      CDoom::Statenum::S_BOS2_STND.value,                                                                            # spawnstate
      500,                                                                                                           # spawnhealth
      CDoom::Statenum::S_BOS2_RUN1.value,                                                                            # seestate
      CDoom::Sfxenum::SFX_kntsit.value,                                                                              # seesound
      8,                                                                                                             # reactiontime
      0,                                                                                                             # attacksound
      CDoom::Statenum::S_BOS2_PAIN.value,                                                                            # painstate
      50,                                                                                                            # painchance
      CDoom::Sfxenum::SFX_dmpain.value,                                                                              # painsound
      CDoom::Statenum::S_BOS2_ATK1.value,                                                                            # meleestate
      CDoom::Statenum::S_BOS2_ATK1.value,                                                                            # missilestate
      CDoom::Statenum::S_BOS2_DIE1.value,                                                                            # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                 # xdeathstate
      CDoom::Sfxenum::SFX_kntdth.value,                                                                              # deathsound
      8,                                                                                                             # speed
      24 * FRACUNIT,                                                                                                 # radius
      64 * FRACUNIT,                                                                                                 # height
      1000,                                                                                                          # mass
      0,                                                                                                             # damage
      CDoom::Sfxenum::SFX_dmact.value,                                                                               # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SHOOTABLE.value | CDoom::Mobjflag::MF_COUNTKILL.value), # flags
      CDoom::Statenum::S_BOS2_RAISE1.value,                                                                          # raisestate
    },
    {                                                                                                                                                  # MT_SKULL
      3006,                                                                                                                                            # doomednum
      CDoom::Statenum::S_SKULL_STND.value,                                                                                                             # spawnstate
      100,                                                                                                                                             # spawnhealth
      CDoom::Statenum::S_SKULL_RUN1.value,                                                                                                             # seestate
      0,                                                                                                                                               # seesound
      8,                                                                                                                                               # reactiontime
      CDoom::Sfxenum::SFX_sklatk.value,                                                                                                                # attacksound
      CDoom::Statenum::S_SKULL_PAIN.value,                                                                                                             # painstate
      256,                                                                                                                                             # painchance
      CDoom::Sfxenum::SFX_dmpain.value,                                                                                                                # painsound
      0,                                                                                                                                               # meleestate
      CDoom::Statenum::S_SKULL_ATK1.value,                                                                                                             # missilestate
      CDoom::Statenum::S_SKULL_DIE1.value,                                                                                                             # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                                                   # xdeathstate
      CDoom::Sfxenum::SFX_firxpl.value,                                                                                                                # deathsound
      8,                                                                                                                                               # speed
      16 * FRACUNIT,                                                                                                                                   # radius
      56 * FRACUNIT,                                                                                                                                   # height
      50,                                                                                                                                              # mass
      3,                                                                                                                                               # damage
      CDoom::Sfxenum::SFX_dmact.value,                                                                                                                 # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SHOOTABLE.value | CDoom::Mobjflag::MF_FLOAT.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                                                   # raisestate
    },
    {                                                                                                                # MT_SPIDER
      7,                                                                                                             # doomednum
      CDoom::Statenum::S_SPID_STND.value,                                                                            # spawnstate
      3000,                                                                                                          # spawnhealth
      CDoom::Statenum::S_SPID_RUN1.value,                                                                            # seestate
      CDoom::Sfxenum::SFX_spisit.value,                                                                              # seesound
      8,                                                                                                             # reactiontime
      CDoom::Sfxenum::SFX_shotgn.value,                                                                              # attacksound
      CDoom::Statenum::S_SPID_PAIN.value,                                                                            # painstate
      40,                                                                                                            # painchance
      CDoom::Sfxenum::SFX_dmpain.value,                                                                              # painsound
      0,                                                                                                             # meleestate
      CDoom::Statenum::S_SPID_ATK1.value,                                                                            # missilestate
      CDoom::Statenum::S_SPID_DIE1.value,                                                                            # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                 # xdeathstate
      CDoom::Sfxenum::SFX_spidth.value,                                                                              # deathsound
      12,                                                                                                            # speed
      128 * FRACUNIT,                                                                                                # radius
      100 * FRACUNIT,                                                                                                # height
      1000,                                                                                                          # mass
      0,                                                                                                             # damage
      CDoom::Sfxenum::SFX_dmact.value,                                                                               # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SHOOTABLE.value | CDoom::Mobjflag::MF_COUNTKILL.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                 # raisestate
    },
    {                                                                                                                # MT_BABY
      68,                                                                                                            # doomednum
      CDoom::Statenum::S_BSPI_STND.value,                                                                            # spawnstate
      500,                                                                                                           # spawnhealth
      CDoom::Statenum::S_BSPI_SIGHT.value,                                                                           # seestate
      CDoom::Sfxenum::SFX_bspsit.value,                                                                              # seesound
      8,                                                                                                             # reactiontime
      0,                                                                                                             # attacksound
      CDoom::Statenum::S_BSPI_PAIN.value,                                                                            # painstate
      128,                                                                                                           # painchance
      CDoom::Sfxenum::SFX_dmpain.value,                                                                              # painsound
      0,                                                                                                             # meleestate
      CDoom::Statenum::S_BSPI_ATK1.value,                                                                            # missilestate
      CDoom::Statenum::S_BSPI_DIE1.value,                                                                            # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                 # xdeathstate
      CDoom::Sfxenum::SFX_bspdth.value,                                                                              # deathsound
      12,                                                                                                            # speed
      64 * FRACUNIT,                                                                                                 # radius
      64 * FRACUNIT,                                                                                                 # height
      600,                                                                                                           # mass
      0,                                                                                                             # damage
      CDoom::Sfxenum::SFX_bspact.value,                                                                              # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SHOOTABLE.value | CDoom::Mobjflag::MF_COUNTKILL.value), # flags
      CDoom::Statenum::S_BSPI_RAISE1.value,                                                                          # raisestate
    },
    {                                                                                                                # MT_CYBORG
      16,                                                                                                            # doomednum
      CDoom::Statenum::S_CYBER_STND.value,                                                                           # spawnstate
      4000,                                                                                                          # spawnhealth
      CDoom::Statenum::S_CYBER_RUN1.value,                                                                           # seestate
      CDoom::Sfxenum::SFX_cybsit.value,                                                                              # seesound
      8,                                                                                                             # reactiontime
      0,                                                                                                             # attacksound
      CDoom::Statenum::S_CYBER_PAIN.value,                                                                           # painstate
      20,                                                                                                            # painchance
      CDoom::Sfxenum::SFX_dmpain.value,                                                                              # painsound
      0,                                                                                                             # meleestate
      CDoom::Statenum::S_CYBER_ATK1.value,                                                                           # missilestate
      CDoom::Statenum::S_CYBER_DIE1.value,                                                                           # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                 # xdeathstate
      CDoom::Sfxenum::SFX_cybdth.value,                                                                              # deathsound
      16,                                                                                                            # speed
      40 * FRACUNIT,                                                                                                 # radius
      110 * FRACUNIT,                                                                                                # height
      1000,                                                                                                          # mass
      0,                                                                                                             # damage
      CDoom::Sfxenum::SFX_dmact.value,                                                                               # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SHOOTABLE.value | CDoom::Mobjflag::MF_COUNTKILL.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                 # raisestate
    },
    {                                                                                                                                                                                        # MT_PAIN
      71,                                                                                                                                                                                    # doomednum
      CDoom::Statenum::S_PAIN_STND.value,                                                                                                                                                    # spawnstate
      400,                                                                                                                                                                                   # spawnhealth
      CDoom::Statenum::S_PAIN_RUN1.value,                                                                                                                                                    # seestate
      CDoom::Sfxenum::SFX_pesit.value,                                                                                                                                                       # seesound
      8,                                                                                                                                                                                     # reactiontime
      0,                                                                                                                                                                                     # attacksound
      CDoom::Statenum::S_PAIN_PAIN.value,                                                                                                                                                    # painstate
      128,                                                                                                                                                                                   # painchance
      CDoom::Sfxenum::SFX_pepain.value,                                                                                                                                                      # painsound
      0,                                                                                                                                                                                     # meleestate
      CDoom::Statenum::S_PAIN_ATK1.value,                                                                                                                                                    # missilestate
      CDoom::Statenum::S_PAIN_DIE1.value,                                                                                                                                                    # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                                                                                         # xdeathstate
      CDoom::Sfxenum::SFX_pedth.value,                                                                                                                                                       # deathsound
      8,                                                                                                                                                                                     # speed
      31 * FRACUNIT,                                                                                                                                                                         # radius
      56 * FRACUNIT,                                                                                                                                                                         # height
      400,                                                                                                                                                                                   # mass
      0,                                                                                                                                                                                     # damage
      CDoom::Sfxenum::SFX_dmact.value,                                                                                                                                                       # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SHOOTABLE.value | CDoom::Mobjflag::MF_FLOAT.value | CDoom::Mobjflag::MF_NOGRAVITY.value | CDoom::Mobjflag::MF_COUNTKILL.value), # flags
      CDoom::Statenum::S_PAIN_RAISE1.value,                                                                                                                                                  # raisestate
    },
    {                                                                                                                # MT_WOLFSS
      84,                                                                                                            # doomednum
      CDoom::Statenum::S_SSWV_STND.value,                                                                            # spawnstate
      50,                                                                                                            # spawnhealth
      CDoom::Statenum::S_SSWV_RUN1.value,                                                                            # seestate
      CDoom::Sfxenum::SFX_sssit.value,                                                                               # seesound
      8,                                                                                                             # reactiontime
      0,                                                                                                             # attacksound
      CDoom::Statenum::S_SSWV_PAIN.value,                                                                            # painstate
      170,                                                                                                           # painchance
      CDoom::Sfxenum::SFX_popain.value,                                                                              # painsound
      0,                                                                                                             # meleestate
      CDoom::Statenum::S_SSWV_ATK1.value,                                                                            # missilestate
      CDoom::Statenum::S_SSWV_DIE1.value,                                                                            # deathstate
      CDoom::Statenum::S_SSWV_XDIE1.value,                                                                           # xdeathstate
      CDoom::Sfxenum::SFX_ssdth.value,                                                                               # deathsound
      8,                                                                                                             # speed
      20 * FRACUNIT,                                                                                                 # radius
      56 * FRACUNIT,                                                                                                 # height
      100,                                                                                                           # mass
      0,                                                                                                             # damage
      CDoom::Sfxenum::SFX_posact.value,                                                                              # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SHOOTABLE.value | CDoom::Mobjflag::MF_COUNTKILL.value), # flags
      CDoom::Statenum::S_SSWV_RAISE1.value,                                                                          # raisestate
    },
    {                                                                                                                                                                                               # MT_KEEN
      72,                                                                                                                                                                                           # doomednum
      CDoom::Statenum::S_KEENSTND.value,                                                                                                                                                            # spawnstate
      100,                                                                                                                                                                                          # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                                                                                                                                # seestate
      CDoom::Sfxenum::SFX_None.value,                                                                                                                                                               # seesound
      8,                                                                                                                                                                                            # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                                                                                                                               # attacksound
      CDoom::Statenum::S_KEENPAIN.value,                                                                                                                                                            # painstate
      256,                                                                                                                                                                                          # painchance
      CDoom::Sfxenum::SFX_keenpn.value,                                                                                                                                                             # painsound
      CDoom::Statenum::S_NULL.value,                                                                                                                                                                # meleestate
      CDoom::Statenum::S_NULL.value,                                                                                                                                                                # missilestate
      CDoom::Statenum::S_COMMKEEN.value,                                                                                                                                                            # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                                                                                                # xdeathstate
      CDoom::Sfxenum::SFX_keendt.value,                                                                                                                                                             # deathsound
      0,                                                                                                                                                                                            # speed
      16 * FRACUNIT,                                                                                                                                                                                # radius
      72 * FRACUNIT,                                                                                                                                                                                # height
      10000000,                                                                                                                                                                                     # mass
      0,                                                                                                                                                                                            # damage
      CDoom::Sfxenum::SFX_None.value,                                                                                                                                                               # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SPAWNCEILING.value | CDoom::Mobjflag::MF_NOGRAVITY.value | CDoom::Mobjflag::MF_SHOOTABLE.value | CDoom::Mobjflag::MF_COUNTKILL.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                                                                                                # raisestate
    },
    {                                                                          # MT_BOSSBRAIN
      88,                                                                      # doomednum
      CDoom::Statenum::S_BRAIN.value,                                          # spawnstate
      250,                                                                     # spawnhealth
      CDoom::Statenum::S_NULL.value,                                           # seestate
      CDoom::Sfxenum::SFX_None.value,                                          # seesound
      8,                                                                       # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                          # attacksound
      CDoom::Statenum::S_BRAIN_PAIN.value,                                     # painstate
      255,                                                                     # painchance
      CDoom::Sfxenum::SFX_bospn.value,                                         # painsound
      CDoom::Statenum::S_NULL.value,                                           # meleestate
      CDoom::Statenum::S_NULL.value,                                           # missilestate
      CDoom::Statenum::S_BRAIN_DIE1.value,                                     # deathstate
      CDoom::Statenum::S_NULL.value,                                           # xdeathstate
      CDoom::Sfxenum::SFX_bosdth.value,                                        # deathsound
      0,                                                                       # speed
      16 * FRACUNIT,                                                           # radius
      16 * FRACUNIT,                                                           # height
      10000000,                                                                # mass
      0,                                                                       # damage
      CDoom::Sfxenum::SFX_None.value,                                          # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SHOOTABLE.value), # flags
      CDoom::Statenum::S_NULL.value,                                           # raisestate
    },
    {                                                                              # MT_BOSSSPIT
      89,                                                                          # doomednum
      CDoom::Statenum::S_BRAINEYE.value,                                           # spawnstate
      1000,                                                                        # spawnhealth
      CDoom::Statenum::S_BRAINEYESEE.value,                                        # seestate
      CDoom::Sfxenum::SFX_None.value,                                              # seesound
      8,                                                                           # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                              # attacksound
      CDoom::Statenum::S_NULL.value,                                               # painstate
      0,                                                                           # painchance
      CDoom::Sfxenum::SFX_None.value,                                              # painsound
      CDoom::Statenum::S_NULL.value,                                               # meleestate
      CDoom::Statenum::S_NULL.value,                                               # missilestate
      CDoom::Statenum::S_NULL.value,                                               # deathstate
      CDoom::Statenum::S_NULL.value,                                               # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                              # deathsound
      0,                                                                           # speed
      20 * FRACUNIT,                                                               # radius
      32 * FRACUNIT,                                                               # height
      100,                                                                         # mass
      0,                                                                           # damage
      CDoom::Sfxenum::SFX_None.value,                                              # activesound
      (CDoom::Mobjflag::MF_NOBLOCKMAP.value | CDoom::Mobjflag::MF_NOSECTOR.value), # flags
      CDoom::Statenum::S_NULL.value,                                               # raisestate
    },
    {                                                                              # MT_BOSSTARGET
      87,                                                                          # doomednum
      CDoom::Statenum::S_NULL.value,                                               # spawnstate
      1000,                                                                        # spawnhealth
      CDoom::Statenum::S_NULL.value,                                               # seestate
      CDoom::Sfxenum::SFX_None.value,                                              # seesound
      8,                                                                           # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                              # attacksound
      CDoom::Statenum::S_NULL.value,                                               # painstate
      0,                                                                           # painchance
      CDoom::Sfxenum::SFX_None.value,                                              # painsound
      CDoom::Statenum::S_NULL.value,                                               # meleestate
      CDoom::Statenum::S_NULL.value,                                               # missilestate
      CDoom::Statenum::S_NULL.value,                                               # deathstate
      CDoom::Statenum::S_NULL.value,                                               # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                              # deathsound
      0,                                                                           # speed
      20 * FRACUNIT,                                                               # radius
      32 * FRACUNIT,                                                               # height
      100,                                                                         # mass
      0,                                                                           # damage
      CDoom::Sfxenum::SFX_None.value,                                              # activesound
      (CDoom::Mobjflag::MF_NOBLOCKMAP.value | CDoom::Mobjflag::MF_NOSECTOR.value), # flags
      CDoom::Statenum::S_NULL.value,                                               # raisestate
    },
    {                                                                                                                                                                                          # MT_SPAWNSHOT
      -1,                                                                                                                                                                                      # doomednum
      CDoom::Statenum::S_SPAWN1.value,                                                                                                                                                         # spawnstate
      1000,                                                                                                                                                                                    # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                                                                                                                           # seestate
      CDoom::Sfxenum::SFX_bospit.value,                                                                                                                                                        # seesound
      8,                                                                                                                                                                                       # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                                                                                                                          # attacksound
      CDoom::Statenum::S_NULL.value,                                                                                                                                                           # painstate
      0,                                                                                                                                                                                       # painchance
      CDoom::Sfxenum::SFX_None.value,                                                                                                                                                          # painsound
      CDoom::Statenum::S_NULL.value,                                                                                                                                                           # meleestate
      CDoom::Statenum::S_NULL.value,                                                                                                                                                           # missilestate
      CDoom::Statenum::S_NULL.value,                                                                                                                                                           # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                                                                                           # xdeathstate
      CDoom::Sfxenum::SFX_firxpl.value,                                                                                                                                                        # deathsound
      10 * FRACUNIT,                                                                                                                                                                           # speed
      6 * FRACUNIT,                                                                                                                                                                            # radius
      32 * FRACUNIT,                                                                                                                                                                           # height
      100,                                                                                                                                                                                     # mass
      3,                                                                                                                                                                                       # damage
      CDoom::Sfxenum::SFX_None.value,                                                                                                                                                          # activesound
      (CDoom::Mobjflag::MF_NOBLOCKMAP.value | CDoom::Mobjflag::MF_MISSILE.value | CDoom::Mobjflag::MF_DROPOFF.value | CDoom::Mobjflag::MF_NOGRAVITY.value | CDoom::Mobjflag::MF_NOCLIP.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                                                                                           # raisestate
    },
    {                                                                               # MT_SPAWNFIRE
      -1,                                                                           # doomednum
      CDoom::Statenum::S_SPAWNFIRE1.value,                                          # spawnstate
      1000,                                                                         # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                # seestate
      CDoom::Sfxenum::SFX_None.value,                                               # seesound
      8,                                                                            # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                               # attacksound
      CDoom::Statenum::S_NULL.value,                                                # painstate
      0,                                                                            # painchance
      CDoom::Sfxenum::SFX_None.value,                                               # painsound
      CDoom::Statenum::S_NULL.value,                                                # meleestate
      CDoom::Statenum::S_NULL.value,                                                # missilestate
      CDoom::Statenum::S_NULL.value,                                                # deathstate
      CDoom::Statenum::S_NULL.value,                                                # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                               # deathsound
      0,                                                                            # speed
      20 * FRACUNIT,                                                                # radius
      16 * FRACUNIT,                                                                # height
      100,                                                                          # mass
      0,                                                                            # damage
      CDoom::Sfxenum::SFX_None.value,                                               # activesound
      (CDoom::Mobjflag::MF_NOBLOCKMAP.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                # raisestate
    },
    {                                                                                                              # MT_BARREL
      2035,                                                                                                        # doomednum
      CDoom::Statenum::S_BAR1.value,                                                                               # spawnstate
      20,                                                                                                          # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                                               # seestate
      CDoom::Sfxenum::SFX_None.value,                                                                              # seesound
      8,                                                                                                           # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                                              # attacksound
      CDoom::Statenum::S_NULL.value,                                                                               # painstate
      0,                                                                                                           # painchance
      CDoom::Sfxenum::SFX_None.value,                                                                              # painsound
      CDoom::Statenum::S_NULL.value,                                                                               # meleestate
      CDoom::Statenum::S_NULL.value,                                                                               # missilestate
      CDoom::Statenum::S_BEXP.value,                                                                               # deathstate
      CDoom::Statenum::S_NULL.value,                                                                               # xdeathstate
      CDoom::Sfxenum::SFX_barexp.value,                                                                            # deathsound
      0,                                                                                                           # speed
      10 * FRACUNIT,                                                                                               # radius
      42 * FRACUNIT,                                                                                               # height
      100,                                                                                                         # mass
      0,                                                                                                           # damage
      CDoom::Sfxenum::SFX_None.value,                                                                              # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SHOOTABLE.value | CDoom::Mobjflag::MF_NOBLOOD.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                               # raisestate
    },
    {                                                                                                                                                       # MT_TROOPSHOT
      -1,                                                                                                                                                   # doomednum
      CDoom::Statenum::S_TBALL1.value,                                                                                                                      # spawnstate
      1000,                                                                                                                                                 # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                                                                                        # seestate
      CDoom::Sfxenum::SFX_firsht.value,                                                                                                                     # seesound
      8,                                                                                                                                                    # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # attacksound
      CDoom::Statenum::S_NULL.value,                                                                                                                        # painstate
      0,                                                                                                                                                    # painchance
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # painsound
      CDoom::Statenum::S_NULL.value,                                                                                                                        # meleestate
      CDoom::Statenum::S_NULL.value,                                                                                                                        # missilestate
      CDoom::Statenum::S_TBALLX1.value,                                                                                                                     # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                                                        # xdeathstate
      CDoom::Sfxenum::SFX_firxpl.value,                                                                                                                     # deathsound
      10 * FRACUNIT,                                                                                                                                        # speed
      6 * FRACUNIT,                                                                                                                                         # radius
      8 * FRACUNIT,                                                                                                                                         # height
      100,                                                                                                                                                  # mass
      3,                                                                                                                                                    # damage
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # activesound
      (CDoom::Mobjflag::MF_NOBLOCKMAP.value | CDoom::Mobjflag::MF_MISSILE.value | CDoom::Mobjflag::MF_DROPOFF.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                                                        # raisestate
    },
    {                                                                                                                                                       # MT_HEADSHOT
      -1,                                                                                                                                                   # doomednum
      CDoom::Statenum::S_RBALL1.value,                                                                                                                      # spawnstate
      1000,                                                                                                                                                 # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                                                                                        # seestate
      CDoom::Sfxenum::SFX_firsht.value,                                                                                                                     # seesound
      8,                                                                                                                                                    # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # attacksound
      CDoom::Statenum::S_NULL.value,                                                                                                                        # painstate
      0,                                                                                                                                                    # painchance
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # painsound
      CDoom::Statenum::S_NULL.value,                                                                                                                        # meleestate
      CDoom::Statenum::S_NULL.value,                                                                                                                        # missilestate
      CDoom::Statenum::S_RBALLX1.value,                                                                                                                     # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                                                        # xdeathstate
      CDoom::Sfxenum::SFX_firxpl.value,                                                                                                                     # deathsound
      10 * FRACUNIT,                                                                                                                                        # speed
      6 * FRACUNIT,                                                                                                                                         # radius
      8 * FRACUNIT,                                                                                                                                         # height
      100,                                                                                                                                                  # mass
      5,                                                                                                                                                    # damage
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # activesound
      (CDoom::Mobjflag::MF_NOBLOCKMAP.value | CDoom::Mobjflag::MF_MISSILE.value | CDoom::Mobjflag::MF_DROPOFF.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                                                        # raisestate
    },
    {                                                                                                                                                       # MT_ROCKET
      -1,                                                                                                                                                   # doomednum
      CDoom::Statenum::S_ROCKET.value,                                                                                                                      # spawnstate
      1000,                                                                                                                                                 # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                                                                                        # seestate
      CDoom::Sfxenum::SFX_rlaunc.value,                                                                                                                     # seesound
      8,                                                                                                                                                    # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # attacksound
      CDoom::Statenum::S_NULL.value,                                                                                                                        # painstate
      0,                                                                                                                                                    # painchance
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # painsound
      CDoom::Statenum::S_NULL.value,                                                                                                                        # meleestate
      CDoom::Statenum::S_NULL.value,                                                                                                                        # missilestate
      CDoom::Statenum::S_EXPLODE1.value,                                                                                                                    # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                                                        # xdeathstate
      CDoom::Sfxenum::SFX_barexp.value,                                                                                                                     # deathsound
      20 * FRACUNIT,                                                                                                                                        # speed
      11 * FRACUNIT,                                                                                                                                        # radius
      8 * FRACUNIT,                                                                                                                                         # height
      100,                                                                                                                                                  # mass
      20,                                                                                                                                                   # damage
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # activesound
      (CDoom::Mobjflag::MF_NOBLOCKMAP.value | CDoom::Mobjflag::MF_MISSILE.value | CDoom::Mobjflag::MF_DROPOFF.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                                                        # raisestate
    },
    {                                                                                                                                                       # MT_PLASMA
      -1,                                                                                                                                                   # doomednum
      CDoom::Statenum::S_PLASBALL.value,                                                                                                                    # spawnstate
      1000,                                                                                                                                                 # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                                                                                        # seestate
      CDoom::Sfxenum::SFX_plasma.value,                                                                                                                     # seesound
      8,                                                                                                                                                    # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # attacksound
      CDoom::Statenum::S_NULL.value,                                                                                                                        # painstate
      0,                                                                                                                                                    # painchance
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # painsound
      CDoom::Statenum::S_NULL.value,                                                                                                                        # meleestate
      CDoom::Statenum::S_NULL.value,                                                                                                                        # missilestate
      CDoom::Statenum::S_PLASEXP.value,                                                                                                                     # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                                                        # xdeathstate
      CDoom::Sfxenum::SFX_firxpl.value,                                                                                                                     # deathsound
      25 * FRACUNIT,                                                                                                                                        # speed
      13 * FRACUNIT,                                                                                                                                        # radius
      8 * FRACUNIT,                                                                                                                                         # height
      100,                                                                                                                                                  # mass
      5,                                                                                                                                                    # damage
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # activesound
      (CDoom::Mobjflag::MF_NOBLOCKMAP.value | CDoom::Mobjflag::MF_MISSILE.value | CDoom::Mobjflag::MF_DROPOFF.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                                                        # raisestate
    },
    {                                                                                                                                                       # MT_BFG
      -1,                                                                                                                                                   # doomednum
      CDoom::Statenum::S_BFGSHOT.value,                                                                                                                     # spawnstate
      1000,                                                                                                                                                 # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                                                                                        # seestate
      0,                                                                                                                                                    # seesound
      8,                                                                                                                                                    # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # attacksound
      CDoom::Statenum::S_NULL.value,                                                                                                                        # painstate
      0,                                                                                                                                                    # painchance
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # painsound
      CDoom::Statenum::S_NULL.value,                                                                                                                        # meleestate
      CDoom::Statenum::S_NULL.value,                                                                                                                        # missilestate
      CDoom::Statenum::S_BFGLAND.value,                                                                                                                     # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                                                        # xdeathstate
      CDoom::Sfxenum::SFX_rxplod.value,                                                                                                                     # deathsound
      25 * FRACUNIT,                                                                                                                                        # speed
      13 * FRACUNIT,                                                                                                                                        # radius
      8 * FRACUNIT,                                                                                                                                         # height
      100,                                                                                                                                                  # mass
      100,                                                                                                                                                  # damage
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # activesound
      (CDoom::Mobjflag::MF_NOBLOCKMAP.value | CDoom::Mobjflag::MF_MISSILE.value | CDoom::Mobjflag::MF_DROPOFF.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                                                        # raisestate
    },
    {                                                                                                                                                       # MT_ARACHPLAZ
      -1,                                                                                                                                                   # doomednum
      CDoom::Statenum::S_ARACH_PLAZ.value,                                                                                                                  # spawnstate
      1000,                                                                                                                                                 # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                                                                                        # seestate
      CDoom::Sfxenum::SFX_plasma.value,                                                                                                                     # seesound
      8,                                                                                                                                                    # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # attacksound
      CDoom::Statenum::S_NULL.value,                                                                                                                        # painstate
      0,                                                                                                                                                    # painchance
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # painsound
      CDoom::Statenum::S_NULL.value,                                                                                                                        # meleestate
      CDoom::Statenum::S_NULL.value,                                                                                                                        # missilestate
      CDoom::Statenum::S_ARACH_PLEX.value,                                                                                                                  # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                                                        # xdeathstate
      CDoom::Sfxenum::SFX_firxpl.value,                                                                                                                     # deathsound
      25 * FRACUNIT,                                                                                                                                        # speed
      13 * FRACUNIT,                                                                                                                                        # radius
      8 * FRACUNIT,                                                                                                                                         # height
      100,                                                                                                                                                  # mass
      5,                                                                                                                                                    # damage
      CDoom::Sfxenum::SFX_None.value,                                                                                                                       # activesound
      (CDoom::Mobjflag::MF_NOBLOCKMAP.value | CDoom::Mobjflag::MF_MISSILE.value | CDoom::Mobjflag::MF_DROPOFF.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                                                        # raisestate
    },
    {                                                                               # MT_PUFF
      -1,                                                                           # doomednum
      CDoom::Statenum::S_PUFF1.value,                                               # spawnstate
      1000,                                                                         # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                # seestate
      CDoom::Sfxenum::SFX_None.value,                                               # seesound
      8,                                                                            # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                               # attacksound
      CDoom::Statenum::S_NULL.value,                                                # painstate
      0,                                                                            # painchance
      CDoom::Sfxenum::SFX_None.value,                                               # painsound
      CDoom::Statenum::S_NULL.value,                                                # meleestate
      CDoom::Statenum::S_NULL.value,                                                # missilestate
      CDoom::Statenum::S_NULL.value,                                                # deathstate
      CDoom::Statenum::S_NULL.value,                                                # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                               # deathsound
      0,                                                                            # speed
      20 * FRACUNIT,                                                                # radius
      16 * FRACUNIT,                                                                # height
      100,                                                                          # mass
      0,                                                                            # damage
      CDoom::Sfxenum::SFX_None.value,                                               # activesound
      (CDoom::Mobjflag::MF_NOBLOCKMAP.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                # raisestate
    },
    {                                       # MT_BLOOD
      -1,                                   # doomednum
      CDoom::Statenum::S_BLOOD1.value,      # spawnstate
      1000,                                 # spawnhealth
      CDoom::Statenum::S_NULL.value,        # seestate
      CDoom::Sfxenum::SFX_None.value,       # seesound
      8,                                    # reactiontime
      CDoom::Sfxenum::SFX_None.value,       # attacksound
      CDoom::Statenum::S_NULL.value,        # painstate
      0,                                    # painchance
      CDoom::Sfxenum::SFX_None.value,       # painsound
      CDoom::Statenum::S_NULL.value,        # meleestate
      CDoom::Statenum::S_NULL.value,        # missilestate
      CDoom::Statenum::S_NULL.value,        # deathstate
      CDoom::Statenum::S_NULL.value,        # xdeathstate
      CDoom::Sfxenum::SFX_None.value,       # deathsound
      0,                                    # speed
      20 * FRACUNIT,                        # radius
      16 * FRACUNIT,                        # height
      100,                                  # mass
      0,                                    # damage
      CDoom::Sfxenum::SFX_None.value,       # activesound
      CDoom::Mobjflag::MF_NOBLOCKMAP.value, # flags
      CDoom::Statenum::S_NULL.value,        # raisestate
    },
    {                                                                               # MT_TFOG
      -1,                                                                           # doomednum
      CDoom::Statenum::S_TFOG.value,                                                # spawnstate
      1000,                                                                         # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                # seestate
      CDoom::Sfxenum::SFX_None.value,                                               # seesound
      8,                                                                            # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                               # attacksound
      CDoom::Statenum::S_NULL.value,                                                # painstate
      0,                                                                            # painchance
      CDoom::Sfxenum::SFX_None.value,                                               # painsound
      CDoom::Statenum::S_NULL.value,                                                # meleestate
      CDoom::Statenum::S_NULL.value,                                                # missilestate
      CDoom::Statenum::S_NULL.value,                                                # deathstate
      CDoom::Statenum::S_NULL.value,                                                # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                               # deathsound
      0,                                                                            # speed
      20 * FRACUNIT,                                                                # radius
      16 * FRACUNIT,                                                                # height
      100,                                                                          # mass
      0,                                                                            # damage
      CDoom::Sfxenum::SFX_None.value,                                               # activesound
      (CDoom::Mobjflag::MF_NOBLOCKMAP.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                # raisestate
    },
    {                                                                               # MT_IFOG
      -1,                                                                           # doomednum
      CDoom::Statenum::S_IFOG.value,                                                # spawnstate
      1000,                                                                         # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                # seestate
      CDoom::Sfxenum::SFX_None.value,                                               # seesound
      8,                                                                            # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                               # attacksound
      CDoom::Statenum::S_NULL.value,                                                # painstate
      0,                                                                            # painchance
      CDoom::Sfxenum::SFX_None.value,                                               # painsound
      CDoom::Statenum::S_NULL.value,                                                # meleestate
      CDoom::Statenum::S_NULL.value,                                                # missilestate
      CDoom::Statenum::S_NULL.value,                                                # deathstate
      CDoom::Statenum::S_NULL.value,                                                # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                               # deathsound
      0,                                                                            # speed
      20 * FRACUNIT,                                                                # radius
      16 * FRACUNIT,                                                                # height
      100,                                                                          # mass
      0,                                                                            # damage
      CDoom::Sfxenum::SFX_None.value,                                               # activesound
      (CDoom::Mobjflag::MF_NOBLOCKMAP.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                # raisestate
    },
    {                                                                              # MT_TELEPORTMAN
      14,                                                                          # doomednum
      CDoom::Statenum::S_NULL.value,                                               # spawnstate
      1000,                                                                        # spawnhealth
      CDoom::Statenum::S_NULL.value,                                               # seestate
      CDoom::Sfxenum::SFX_None.value,                                              # seesound
      8,                                                                           # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                              # attacksound
      CDoom::Statenum::S_NULL.value,                                               # painstate
      0,                                                                           # painchance
      CDoom::Sfxenum::SFX_None.value,                                              # painsound
      CDoom::Statenum::S_NULL.value,                                               # meleestate
      CDoom::Statenum::S_NULL.value,                                               # missilestate
      CDoom::Statenum::S_NULL.value,                                               # deathstate
      CDoom::Statenum::S_NULL.value,                                               # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                              # deathsound
      0,                                                                           # speed
      20 * FRACUNIT,                                                               # radius
      16 * FRACUNIT,                                                               # height
      100,                                                                         # mass
      0,                                                                           # damage
      CDoom::Sfxenum::SFX_None.value,                                              # activesound
      (CDoom::Mobjflag::MF_NOBLOCKMAP.value | CDoom::Mobjflag::MF_NOSECTOR.value), # flags
      CDoom::Statenum::S_NULL.value,                                               # raisestate
    },
    {                                                                               # MT_EXTRABFG
      -1,                                                                           # doomednum
      CDoom::Statenum::S_BFGEXP.value,                                              # spawnstate
      1000,                                                                         # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                # seestate
      CDoom::Sfxenum::SFX_None.value,                                               # seesound
      8,                                                                            # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                               # attacksound
      CDoom::Statenum::S_NULL.value,                                                # painstate
      0,                                                                            # painchance
      CDoom::Sfxenum::SFX_None.value,                                               # painsound
      CDoom::Statenum::S_NULL.value,                                                # meleestate
      CDoom::Statenum::S_NULL.value,                                                # missilestate
      CDoom::Statenum::S_NULL.value,                                                # deathstate
      CDoom::Statenum::S_NULL.value,                                                # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                               # deathsound
      0,                                                                            # speed
      20 * FRACUNIT,                                                                # radius
      16 * FRACUNIT,                                                                # height
      100,                                                                          # mass
      0,                                                                            # damage
      CDoom::Sfxenum::SFX_None.value,                                               # activesound
      (CDoom::Mobjflag::MF_NOBLOCKMAP.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                # raisestate
    },
    {                                    # MT_MISC0
      2018,                              # doomednum
      CDoom::Statenum::S_ARM1.value,     # spawnstate
      1000,                              # spawnhealth
      CDoom::Statenum::S_NULL.value,     # seestate
      CDoom::Sfxenum::SFX_None.value,    # seesound
      8,                                 # reactiontime
      CDoom::Sfxenum::SFX_None.value,    # attacksound
      CDoom::Statenum::S_NULL.value,     # painstate
      0,                                 # painchance
      CDoom::Sfxenum::SFX_None.value,    # painsound
      CDoom::Statenum::S_NULL.value,     # meleestate
      CDoom::Statenum::S_NULL.value,     # missilestate
      CDoom::Statenum::S_NULL.value,     # deathstate
      CDoom::Statenum::S_NULL.value,     # xdeathstate
      CDoom::Sfxenum::SFX_None.value,    # deathsound
      0,                                 # speed
      20 * FRACUNIT,                     # radius
      16 * FRACUNIT,                     # height
      100,                               # mass
      0,                                 # damage
      CDoom::Sfxenum::SFX_None.value,    # activesound
      CDoom::Mobjflag::MF_SPECIAL.value, # flags
      CDoom::Statenum::S_NULL.value,     # raisestate
    },
    {                                    # MT_MISC1
      2019,                              # doomednum
      CDoom::Statenum::S_ARM2.value,     # spawnstate
      1000,                              # spawnhealth
      CDoom::Statenum::S_NULL.value,     # seestate
      CDoom::Sfxenum::SFX_None.value,    # seesound
      8,                                 # reactiontime
      CDoom::Sfxenum::SFX_None.value,    # attacksound
      CDoom::Statenum::S_NULL.value,     # painstate
      0,                                 # painchance
      CDoom::Sfxenum::SFX_None.value,    # painsound
      CDoom::Statenum::S_NULL.value,     # meleestate
      CDoom::Statenum::S_NULL.value,     # missilestate
      CDoom::Statenum::S_NULL.value,     # deathstate
      CDoom::Statenum::S_NULL.value,     # xdeathstate
      CDoom::Sfxenum::SFX_None.value,    # deathsound
      0,                                 # speed
      20 * FRACUNIT,                     # radius
      16 * FRACUNIT,                     # height
      100,                               # mass
      0,                                 # damage
      CDoom::Sfxenum::SFX_None.value,    # activesound
      CDoom::Mobjflag::MF_SPECIAL.value, # flags
      CDoom::Statenum::S_NULL.value,     # raisestate
    },
    {                                                                            # MT_MISC2
      2014,                                                                      # doomednum
      CDoom::Statenum::S_BON1.value,                                             # spawnstate
      1000,                                                                      # spawnhealth
      CDoom::Statenum::S_NULL.value,                                             # seestate
      CDoom::Sfxenum::SFX_None.value,                                            # seesound
      8,                                                                         # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                            # attacksound
      CDoom::Statenum::S_NULL.value,                                             # painstate
      0,                                                                         # painchance
      CDoom::Sfxenum::SFX_None.value,                                            # painsound
      CDoom::Statenum::S_NULL.value,                                             # meleestate
      CDoom::Statenum::S_NULL.value,                                             # missilestate
      CDoom::Statenum::S_NULL.value,                                             # deathstate
      CDoom::Statenum::S_NULL.value,                                             # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                            # deathsound
      0,                                                                         # speed
      20 * FRACUNIT,                                                             # radius
      16 * FRACUNIT,                                                             # height
      100,                                                                       # mass
      0,                                                                         # damage
      CDoom::Sfxenum::SFX_None.value,                                            # activesound
      (CDoom::Mobjflag::MF_SPECIAL.value | CDoom::Mobjflag::MF_COUNTITEM.value), # flags
      CDoom::Statenum::S_NULL.value,                                             # raisestate
    },
    {                                                                            # MT_MISC3
      2015,                                                                      # doomednum
      CDoom::Statenum::S_BON2.value,                                             # spawnstate
      1000,                                                                      # spawnhealth
      CDoom::Statenum::S_NULL.value,                                             # seestate
      CDoom::Sfxenum::SFX_None.value,                                            # seesound
      8,                                                                         # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                            # attacksound
      CDoom::Statenum::S_NULL.value,                                             # painstate
      0,                                                                         # painchance
      CDoom::Sfxenum::SFX_None.value,                                            # painsound
      CDoom::Statenum::S_NULL.value,                                             # meleestate
      CDoom::Statenum::S_NULL.value,                                             # missilestate
      CDoom::Statenum::S_NULL.value,                                             # deathstate
      CDoom::Statenum::S_NULL.value,                                             # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                            # deathsound
      0,                                                                         # speed
      20 * FRACUNIT,                                                             # radius
      16 * FRACUNIT,                                                             # height
      100,                                                                       # mass
      0,                                                                         # damage
      CDoom::Sfxenum::SFX_None.value,                                            # activesound
      (CDoom::Mobjflag::MF_SPECIAL.value | CDoom::Mobjflag::MF_COUNTITEM.value), # flags
      CDoom::Statenum::S_NULL.value,                                             # raisestate
    },
    {                                                                            # MT_MISC4
      5,                                                                         # doomednum
      CDoom::Statenum::S_BKEY.value,                                             # spawnstate
      1000,                                                                      # spawnhealth
      CDoom::Statenum::S_NULL.value,                                             # seestate
      CDoom::Sfxenum::SFX_None.value,                                            # seesound
      8,                                                                         # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                            # attacksound
      CDoom::Statenum::S_NULL.value,                                             # painstate
      0,                                                                         # painchance
      CDoom::Sfxenum::SFX_None.value,                                            # painsound
      CDoom::Statenum::S_NULL.value,                                             # meleestate
      CDoom::Statenum::S_NULL.value,                                             # missilestate
      CDoom::Statenum::S_NULL.value,                                             # deathstate
      CDoom::Statenum::S_NULL.value,                                             # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                            # deathsound
      0,                                                                         # speed
      20 * FRACUNIT,                                                             # radius
      16 * FRACUNIT,                                                             # height
      100,                                                                       # mass
      0,                                                                         # damage
      CDoom::Sfxenum::SFX_None.value,                                            # activesound
      (CDoom::Mobjflag::MF_SPECIAL.value | CDoom::Mobjflag::MF_NOTDMATCH.value), # flags
      CDoom::Statenum::S_NULL.value,                                             # raisestate
    },
    {                                                                            # MT_MISC5
      13,                                                                        # doomednum
      CDoom::Statenum::S_RKEY.value,                                             # spawnstate
      1000,                                                                      # spawnhealth
      CDoom::Statenum::S_NULL.value,                                             # seestate
      CDoom::Sfxenum::SFX_None.value,                                            # seesound
      8,                                                                         # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                            # attacksound
      CDoom::Statenum::S_NULL.value,                                             # painstate
      0,                                                                         # painchance
      CDoom::Sfxenum::SFX_None.value,                                            # painsound
      CDoom::Statenum::S_NULL.value,                                             # meleestate
      CDoom::Statenum::S_NULL.value,                                             # missilestate
      CDoom::Statenum::S_NULL.value,                                             # deathstate
      CDoom::Statenum::S_NULL.value,                                             # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                            # deathsound
      0,                                                                         # speed
      20 * FRACUNIT,                                                             # radius
      16 * FRACUNIT,                                                             # height
      100,                                                                       # mass
      0,                                                                         # damage
      CDoom::Sfxenum::SFX_None.value,                                            # activesound
      (CDoom::Mobjflag::MF_SPECIAL.value | CDoom::Mobjflag::MF_NOTDMATCH.value), # flags
      CDoom::Statenum::S_NULL.value,                                             # raisestate
    },
    {                                                                            # MT_MISC6
      6,                                                                         # doomednum
      CDoom::Statenum::S_YKEY.value,                                             # spawnstate
      1000,                                                                      # spawnhealth
      CDoom::Statenum::S_NULL.value,                                             # seestate
      CDoom::Sfxenum::SFX_None.value,                                            # seesound
      8,                                                                         # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                            # attacksound
      CDoom::Statenum::S_NULL.value,                                             # painstate
      0,                                                                         # painchance
      CDoom::Sfxenum::SFX_None.value,                                            # painsound
      CDoom::Statenum::S_NULL.value,                                             # meleestate
      CDoom::Statenum::S_NULL.value,                                             # missilestate
      CDoom::Statenum::S_NULL.value,                                             # deathstate
      CDoom::Statenum::S_NULL.value,                                             # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                            # deathsound
      0,                                                                         # speed
      20 * FRACUNIT,                                                             # radius
      16 * FRACUNIT,                                                             # height
      100,                                                                       # mass
      0,                                                                         # damage
      CDoom::Sfxenum::SFX_None.value,                                            # activesound
      (CDoom::Mobjflag::MF_SPECIAL.value | CDoom::Mobjflag::MF_NOTDMATCH.value), # flags
      CDoom::Statenum::S_NULL.value,                                             # raisestate
    },
    {                                                                            # MT_MISC7
      39,                                                                        # doomednum
      CDoom::Statenum::S_YSKULL.value,                                           # spawnstate
      1000,                                                                      # spawnhealth
      CDoom::Statenum::S_NULL.value,                                             # seestate
      CDoom::Sfxenum::SFX_None.value,                                            # seesound
      8,                                                                         # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                            # attacksound
      CDoom::Statenum::S_NULL.value,                                             # painstate
      0,                                                                         # painchance
      CDoom::Sfxenum::SFX_None.value,                                            # painsound
      CDoom::Statenum::S_NULL.value,                                             # meleestate
      CDoom::Statenum::S_NULL.value,                                             # missilestate
      CDoom::Statenum::S_NULL.value,                                             # deathstate
      CDoom::Statenum::S_NULL.value,                                             # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                            # deathsound
      0,                                                                         # speed
      20 * FRACUNIT,                                                             # radius
      16 * FRACUNIT,                                                             # height
      100,                                                                       # mass
      0,                                                                         # damage
      CDoom::Sfxenum::SFX_None.value,                                            # activesound
      (CDoom::Mobjflag::MF_SPECIAL.value | CDoom::Mobjflag::MF_NOTDMATCH.value), # flags
      CDoom::Statenum::S_NULL.value,                                             # raisestate
    },
    {                                                                            # MT_MISC8
      38,                                                                        # doomednum
      CDoom::Statenum::S_RSKULL.value,                                           # spawnstate
      1000,                                                                      # spawnhealth
      CDoom::Statenum::S_NULL.value,                                             # seestate
      CDoom::Sfxenum::SFX_None.value,                                            # seesound
      8,                                                                         # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                            # attacksound
      CDoom::Statenum::S_NULL.value,                                             # painstate
      0,                                                                         # painchance
      CDoom::Sfxenum::SFX_None.value,                                            # painsound
      CDoom::Statenum::S_NULL.value,                                             # meleestate
      CDoom::Statenum::S_NULL.value,                                             # missilestate
      CDoom::Statenum::S_NULL.value,                                             # deathstate
      CDoom::Statenum::S_NULL.value,                                             # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                            # deathsound
      0,                                                                         # speed
      20 * FRACUNIT,                                                             # radius
      16 * FRACUNIT,                                                             # height
      100,                                                                       # mass
      0,                                                                         # damage
      CDoom::Sfxenum::SFX_None.value,                                            # activesound
      (CDoom::Mobjflag::MF_SPECIAL.value | CDoom::Mobjflag::MF_NOTDMATCH.value), # flags
      CDoom::Statenum::S_NULL.value,                                             # raisestate
    },
    {                                                                            # MT_MISC9
      40,                                                                        # doomednum
      CDoom::Statenum::S_BSKULL.value,                                           # spawnstate
      1000,                                                                      # spawnhealth
      CDoom::Statenum::S_NULL.value,                                             # seestate
      CDoom::Sfxenum::SFX_None.value,                                            # seesound
      8,                                                                         # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                            # attacksound
      CDoom::Statenum::S_NULL.value,                                             # painstate
      0,                                                                         # painchance
      CDoom::Sfxenum::SFX_None.value,                                            # painsound
      CDoom::Statenum::S_NULL.value,                                             # meleestate
      CDoom::Statenum::S_NULL.value,                                             # missilestate
      CDoom::Statenum::S_NULL.value,                                             # deathstate
      CDoom::Statenum::S_NULL.value,                                             # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                            # deathsound
      0,                                                                         # speed
      20 * FRACUNIT,                                                             # radius
      16 * FRACUNIT,                                                             # height
      100,                                                                       # mass
      0,                                                                         # damage
      CDoom::Sfxenum::SFX_None.value,                                            # activesound
      (CDoom::Mobjflag::MF_SPECIAL.value | CDoom::Mobjflag::MF_NOTDMATCH.value), # flags
      CDoom::Statenum::S_NULL.value,                                             # raisestate
    },
    {                                    # MT_MISC10
      2011,                              # doomednum
      CDoom::Statenum::S_STIM.value,     # spawnstate
      1000,                              # spawnhealth
      CDoom::Statenum::S_NULL.value,     # seestate
      CDoom::Sfxenum::SFX_None.value,    # seesound
      8,                                 # reactiontime
      CDoom::Sfxenum::SFX_None.value,    # attacksound
      CDoom::Statenum::S_NULL.value,     # painstate
      0,                                 # painchance
      CDoom::Sfxenum::SFX_None.value,    # painsound
      CDoom::Statenum::S_NULL.value,     # meleestate
      CDoom::Statenum::S_NULL.value,     # missilestate
      CDoom::Statenum::S_NULL.value,     # deathstate
      CDoom::Statenum::S_NULL.value,     # xdeathstate
      CDoom::Sfxenum::SFX_None.value,    # deathsound
      0,                                 # speed
      20 * FRACUNIT,                     # radius
      16 * FRACUNIT,                     # height
      100,                               # mass
      0,                                 # damage
      CDoom::Sfxenum::SFX_None.value,    # activesound
      CDoom::Mobjflag::MF_SPECIAL.value, # flags
      CDoom::Statenum::S_NULL.value,     # raisestate
    },
    {                                    # MT_MISC11
      2012,                              # doomednum
      CDoom::Statenum::S_MEDI.value,     # spawnstate
      1000,                              # spawnhealth
      CDoom::Statenum::S_NULL.value,     # seestate
      CDoom::Sfxenum::SFX_None.value,    # seesound
      8,                                 # reactiontime
      CDoom::Sfxenum::SFX_None.value,    # attacksound
      CDoom::Statenum::S_NULL.value,     # painstate
      0,                                 # painchance
      CDoom::Sfxenum::SFX_None.value,    # painsound
      CDoom::Statenum::S_NULL.value,     # meleestate
      CDoom::Statenum::S_NULL.value,     # missilestate
      CDoom::Statenum::S_NULL.value,     # deathstate
      CDoom::Statenum::S_NULL.value,     # xdeathstate
      CDoom::Sfxenum::SFX_None.value,    # deathsound
      0,                                 # speed
      20 * FRACUNIT,                     # radius
      16 * FRACUNIT,                     # height
      100,                               # mass
      0,                                 # damage
      CDoom::Sfxenum::SFX_None.value,    # activesound
      CDoom::Mobjflag::MF_SPECIAL.value, # flags
      CDoom::Statenum::S_NULL.value,     # raisestate
    },
    {                                                                            # MT_MISC12
      2013,                                                                      # doomednum
      CDoom::Statenum::S_SOUL.value,                                             # spawnstate
      1000,                                                                      # spawnhealth
      CDoom::Statenum::S_NULL.value,                                             # seestate
      CDoom::Sfxenum::SFX_None.value,                                            # seesound
      8,                                                                         # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                            # attacksound
      CDoom::Statenum::S_NULL.value,                                             # painstate
      0,                                                                         # painchance
      CDoom::Sfxenum::SFX_None.value,                                            # painsound
      CDoom::Statenum::S_NULL.value,                                             # meleestate
      CDoom::Statenum::S_NULL.value,                                             # missilestate
      CDoom::Statenum::S_NULL.value,                                             # deathstate
      CDoom::Statenum::S_NULL.value,                                             # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                            # deathsound
      0,                                                                         # speed
      20 * FRACUNIT,                                                             # radius
      16 * FRACUNIT,                                                             # height
      100,                                                                       # mass
      0,                                                                         # damage
      CDoom::Sfxenum::SFX_None.value,                                            # activesound
      (CDoom::Mobjflag::MF_SPECIAL.value | CDoom::Mobjflag::MF_COUNTITEM.value), # flags
      CDoom::Statenum::S_NULL.value,                                             # raisestate
    },
    {                                                                            # MT_INV
      2022,                                                                      # doomednum
      CDoom::Statenum::S_PINV.value,                                             # spawnstate
      1000,                                                                      # spawnhealth
      CDoom::Statenum::S_NULL.value,                                             # seestate
      CDoom::Sfxenum::SFX_None.value,                                            # seesound
      8,                                                                         # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                            # attacksound
      CDoom::Statenum::S_NULL.value,                                             # painstate
      0,                                                                         # painchance
      CDoom::Sfxenum::SFX_None.value,                                            # painsound
      CDoom::Statenum::S_NULL.value,                                             # meleestate
      CDoom::Statenum::S_NULL.value,                                             # missilestate
      CDoom::Statenum::S_NULL.value,                                             # deathstate
      CDoom::Statenum::S_NULL.value,                                             # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                            # deathsound
      0,                                                                         # speed
      20 * FRACUNIT,                                                             # radius
      16 * FRACUNIT,                                                             # height
      100,                                                                       # mass
      0,                                                                         # damage
      CDoom::Sfxenum::SFX_None.value,                                            # activesound
      (CDoom::Mobjflag::MF_SPECIAL.value | CDoom::Mobjflag::MF_COUNTITEM.value), # flags
      CDoom::Statenum::S_NULL.value,                                             # raisestate
    },
    {                                                                            # MT_MISC13
      2023,                                                                      # doomednum
      CDoom::Statenum::S_PSTR.value,                                             # spawnstate
      1000,                                                                      # spawnhealth
      CDoom::Statenum::S_NULL.value,                                             # seestate
      CDoom::Sfxenum::SFX_None.value,                                            # seesound
      8,                                                                         # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                            # attacksound
      CDoom::Statenum::S_NULL.value,                                             # painstate
      0,                                                                         # painchance
      CDoom::Sfxenum::SFX_None.value,                                            # painsound
      CDoom::Statenum::S_NULL.value,                                             # meleestate
      CDoom::Statenum::S_NULL.value,                                             # missilestate
      CDoom::Statenum::S_NULL.value,                                             # deathstate
      CDoom::Statenum::S_NULL.value,                                             # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                            # deathsound
      0,                                                                         # speed
      20 * FRACUNIT,                                                             # radius
      16 * FRACUNIT,                                                             # height
      100,                                                                       # mass
      0,                                                                         # damage
      CDoom::Sfxenum::SFX_None.value,                                            # activesound
      (CDoom::Mobjflag::MF_SPECIAL.value | CDoom::Mobjflag::MF_COUNTITEM.value), # flags
      CDoom::Statenum::S_NULL.value,                                             # raisestate
    },
    {                                                                            # MT_INS
      2024,                                                                      # doomednum
      CDoom::Statenum::S_PINS.value,                                             # spawnstate
      1000,                                                                      # spawnhealth
      CDoom::Statenum::S_NULL.value,                                             # seestate
      CDoom::Sfxenum::SFX_None.value,                                            # seesound
      8,                                                                         # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                            # attacksound
      CDoom::Statenum::S_NULL.value,                                             # painstate
      0,                                                                         # painchance
      CDoom::Sfxenum::SFX_None.value,                                            # painsound
      CDoom::Statenum::S_NULL.value,                                             # meleestate
      CDoom::Statenum::S_NULL.value,                                             # missilestate
      CDoom::Statenum::S_NULL.value,                                             # deathstate
      CDoom::Statenum::S_NULL.value,                                             # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                            # deathsound
      0,                                                                         # speed
      20 * FRACUNIT,                                                             # radius
      16 * FRACUNIT,                                                             # height
      100,                                                                       # mass
      0,                                                                         # damage
      CDoom::Sfxenum::SFX_None.value,                                            # activesound
      (CDoom::Mobjflag::MF_SPECIAL.value | CDoom::Mobjflag::MF_COUNTITEM.value), # flags
      CDoom::Statenum::S_NULL.value,                                             # raisestate
    },
    {                                    # MT_MISC14
      2025,                              # doomednum
      CDoom::Statenum::S_SUIT.value,     # spawnstate
      1000,                              # spawnhealth
      CDoom::Statenum::S_NULL.value,     # seestate
      CDoom::Sfxenum::SFX_None.value,    # seesound
      8,                                 # reactiontime
      CDoom::Sfxenum::SFX_None.value,    # attacksound
      CDoom::Statenum::S_NULL.value,     # painstate
      0,                                 # painchance
      CDoom::Sfxenum::SFX_None.value,    # painsound
      CDoom::Statenum::S_NULL.value,     # meleestate
      CDoom::Statenum::S_NULL.value,     # missilestate
      CDoom::Statenum::S_NULL.value,     # deathstate
      CDoom::Statenum::S_NULL.value,     # xdeathstate
      CDoom::Sfxenum::SFX_None.value,    # deathsound
      0,                                 # speed
      20 * FRACUNIT,                     # radius
      16 * FRACUNIT,                     # height
      100,                               # mass
      0,                                 # damage
      CDoom::Sfxenum::SFX_None.value,    # activesound
      CDoom::Mobjflag::MF_SPECIAL.value, # flags
      CDoom::Statenum::S_NULL.value,     # raisestate
    },
    {                                                                            # MT_MISC15
      2026,                                                                      # doomednum
      CDoom::Statenum::S_PMAP.value,                                             # spawnstate
      1000,                                                                      # spawnhealth
      CDoom::Statenum::S_NULL.value,                                             # seestate
      CDoom::Sfxenum::SFX_None.value,                                            # seesound
      8,                                                                         # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                            # attacksound
      CDoom::Statenum::S_NULL.value,                                             # painstate
      0,                                                                         # painchance
      CDoom::Sfxenum::SFX_None.value,                                            # painsound
      CDoom::Statenum::S_NULL.value,                                             # meleestate
      CDoom::Statenum::S_NULL.value,                                             # missilestate
      CDoom::Statenum::S_NULL.value,                                             # deathstate
      CDoom::Statenum::S_NULL.value,                                             # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                            # deathsound
      0,                                                                         # speed
      20 * FRACUNIT,                                                             # radius
      16 * FRACUNIT,                                                             # height
      100,                                                                       # mass
      0,                                                                         # damage
      CDoom::Sfxenum::SFX_None.value,                                            # activesound
      (CDoom::Mobjflag::MF_SPECIAL.value | CDoom::Mobjflag::MF_COUNTITEM.value), # flags
      CDoom::Statenum::S_NULL.value,                                             # raisestate
    },
    {                                                                            # MT_MISC16
      2045,                                                                      # doomednum
      CDoom::Statenum::S_PVIS.value,                                             # spawnstate
      1000,                                                                      # spawnhealth
      CDoom::Statenum::S_NULL.value,                                             # seestate
      CDoom::Sfxenum::SFX_None.value,                                            # seesound
      8,                                                                         # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                            # attacksound
      CDoom::Statenum::S_NULL.value,                                             # painstate
      0,                                                                         # painchance
      CDoom::Sfxenum::SFX_None.value,                                            # painsound
      CDoom::Statenum::S_NULL.value,                                             # meleestate
      CDoom::Statenum::S_NULL.value,                                             # missilestate
      CDoom::Statenum::S_NULL.value,                                             # deathstate
      CDoom::Statenum::S_NULL.value,                                             # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                            # deathsound
      0,                                                                         # speed
      20 * FRACUNIT,                                                             # radius
      16 * FRACUNIT,                                                             # height
      100,                                                                       # mass
      0,                                                                         # damage
      CDoom::Sfxenum::SFX_None.value,                                            # activesound
      (CDoom::Mobjflag::MF_SPECIAL.value | CDoom::Mobjflag::MF_COUNTITEM.value), # flags
      CDoom::Statenum::S_NULL.value,                                             # raisestate
    },
    {                                                                            # MT_MEGA
      83,                                                                        # doomednum
      CDoom::Statenum::S_MEGA.value,                                             # spawnstate
      1000,                                                                      # spawnhealth
      CDoom::Statenum::S_NULL.value,                                             # seestate
      CDoom::Sfxenum::SFX_None.value,                                            # seesound
      8,                                                                         # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                            # attacksound
      CDoom::Statenum::S_NULL.value,                                             # painstate
      0,                                                                         # painchance
      CDoom::Sfxenum::SFX_None.value,                                            # painsound
      CDoom::Statenum::S_NULL.value,                                             # meleestate
      CDoom::Statenum::S_NULL.value,                                             # missilestate
      CDoom::Statenum::S_NULL.value,                                             # deathstate
      CDoom::Statenum::S_NULL.value,                                             # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                            # deathsound
      0,                                                                         # speed
      20 * FRACUNIT,                                                             # radius
      16 * FRACUNIT,                                                             # height
      100,                                                                       # mass
      0,                                                                         # damage
      CDoom::Sfxenum::SFX_None.value,                                            # activesound
      (CDoom::Mobjflag::MF_SPECIAL.value | CDoom::Mobjflag::MF_COUNTITEM.value), # flags
      CDoom::Statenum::S_NULL.value,                                             # raisestate
    },
    {                                    # MT_CLIP
      2007,                              # doomednum
      CDoom::Statenum::S_CLIP.value,     # spawnstate
      1000,                              # spawnhealth
      CDoom::Statenum::S_NULL.value,     # seestate
      CDoom::Sfxenum::SFX_None.value,    # seesound
      8,                                 # reactiontime
      CDoom::Sfxenum::SFX_None.value,    # attacksound
      CDoom::Statenum::S_NULL.value,     # painstate
      0,                                 # painchance
      CDoom::Sfxenum::SFX_None.value,    # painsound
      CDoom::Statenum::S_NULL.value,     # meleestate
      CDoom::Statenum::S_NULL.value,     # missilestate
      CDoom::Statenum::S_NULL.value,     # deathstate
      CDoom::Statenum::S_NULL.value,     # xdeathstate
      CDoom::Sfxenum::SFX_None.value,    # deathsound
      0,                                 # speed
      20 * FRACUNIT,                     # radius
      16 * FRACUNIT,                     # height
      100,                               # mass
      0,                                 # damage
      CDoom::Sfxenum::SFX_None.value,    # activesound
      CDoom::Mobjflag::MF_SPECIAL.value, # flags
      CDoom::Statenum::S_NULL.value,     # raisestate
    },
    {                                    # MT_MISC17
      2048,                              # doomednum
      CDoom::Statenum::S_AMMO.value,     # spawnstate
      1000,                              # spawnhealth
      CDoom::Statenum::S_NULL.value,     # seestate
      CDoom::Sfxenum::SFX_None.value,    # seesound
      8,                                 # reactiontime
      CDoom::Sfxenum::SFX_None.value,    # attacksound
      CDoom::Statenum::S_NULL.value,     # painstate
      0,                                 # painchance
      CDoom::Sfxenum::SFX_None.value,    # painsound
      CDoom::Statenum::S_NULL.value,     # meleestate
      CDoom::Statenum::S_NULL.value,     # missilestate
      CDoom::Statenum::S_NULL.value,     # deathstate
      CDoom::Statenum::S_NULL.value,     # xdeathstate
      CDoom::Sfxenum::SFX_None.value,    # deathsound
      0,                                 # speed
      20 * FRACUNIT,                     # radius
      16 * FRACUNIT,                     # height
      100,                               # mass
      0,                                 # damage
      CDoom::Sfxenum::SFX_None.value,    # activesound
      CDoom::Mobjflag::MF_SPECIAL.value, # flags
      CDoom::Statenum::S_NULL.value,     # raisestate
    },
    {                                    # MT_MISC18
      2010,                              # doomednum
      CDoom::Statenum::S_ROCK.value,     # spawnstate
      1000,                              # spawnhealth
      CDoom::Statenum::S_NULL.value,     # seestate
      CDoom::Sfxenum::SFX_None.value,    # seesound
      8,                                 # reactiontime
      CDoom::Sfxenum::SFX_None.value,    # attacksound
      CDoom::Statenum::S_NULL.value,     # painstate
      0,                                 # painchance
      CDoom::Sfxenum::SFX_None.value,    # painsound
      CDoom::Statenum::S_NULL.value,     # meleestate
      CDoom::Statenum::S_NULL.value,     # missilestate
      CDoom::Statenum::S_NULL.value,     # deathstate
      CDoom::Statenum::S_NULL.value,     # xdeathstate
      CDoom::Sfxenum::SFX_None.value,    # deathsound
      0,                                 # speed
      20 * FRACUNIT,                     # radius
      16 * FRACUNIT,                     # height
      100,                               # mass
      0,                                 # damage
      CDoom::Sfxenum::SFX_None.value,    # activesound
      CDoom::Mobjflag::MF_SPECIAL.value, # flags
      CDoom::Statenum::S_NULL.value,     # raisestate
    },
    {                                    # MT_MISC19
      2046,                              # doomednum
      CDoom::Statenum::S_BROK.value,     # spawnstate
      1000,                              # spawnhealth
      CDoom::Statenum::S_NULL.value,     # seestate
      CDoom::Sfxenum::SFX_None.value,    # seesound
      8,                                 # reactiontime
      CDoom::Sfxenum::SFX_None.value,    # attacksound
      CDoom::Statenum::S_NULL.value,     # painstate
      0,                                 # painchance
      CDoom::Sfxenum::SFX_None.value,    # painsound
      CDoom::Statenum::S_NULL.value,     # meleestate
      CDoom::Statenum::S_NULL.value,     # missilestate
      CDoom::Statenum::S_NULL.value,     # deathstate
      CDoom::Statenum::S_NULL.value,     # xdeathstate
      CDoom::Sfxenum::SFX_None.value,    # deathsound
      0,                                 # speed
      20 * FRACUNIT,                     # radius
      16 * FRACUNIT,                     # height
      100,                               # mass
      0,                                 # damage
      CDoom::Sfxenum::SFX_None.value,    # activesound
      CDoom::Mobjflag::MF_SPECIAL.value, # flags
      CDoom::Statenum::S_NULL.value,     # raisestate
    },
    {                                    # MT_MISC20
      2047,                              # doomednum
      CDoom::Statenum::S_CELL.value,     # spawnstate
      1000,                              # spawnhealth
      CDoom::Statenum::S_NULL.value,     # seestate
      CDoom::Sfxenum::SFX_None.value,    # seesound
      8,                                 # reactiontime
      CDoom::Sfxenum::SFX_None.value,    # attacksound
      CDoom::Statenum::S_NULL.value,     # painstate
      0,                                 # painchance
      CDoom::Sfxenum::SFX_None.value,    # painsound
      CDoom::Statenum::S_NULL.value,     # meleestate
      CDoom::Statenum::S_NULL.value,     # missilestate
      CDoom::Statenum::S_NULL.value,     # deathstate
      CDoom::Statenum::S_NULL.value,     # xdeathstate
      CDoom::Sfxenum::SFX_None.value,    # deathsound
      0,                                 # speed
      20 * FRACUNIT,                     # radius
      16 * FRACUNIT,                     # height
      100,                               # mass
      0,                                 # damage
      CDoom::Sfxenum::SFX_None.value,    # activesound
      CDoom::Mobjflag::MF_SPECIAL.value, # flags
      CDoom::Statenum::S_NULL.value,     # raisestate
    },
    {                                    # MT_MISC21
      17,                                # doomednum
      CDoom::Statenum::S_CELP.value,     # spawnstate
      1000,                              # spawnhealth
      CDoom::Statenum::S_NULL.value,     # seestate
      CDoom::Sfxenum::SFX_None.value,    # seesound
      8,                                 # reactiontime
      CDoom::Sfxenum::SFX_None.value,    # attacksound
      CDoom::Statenum::S_NULL.value,     # painstate
      0,                                 # painchance
      CDoom::Sfxenum::SFX_None.value,    # painsound
      CDoom::Statenum::S_NULL.value,     # meleestate
      CDoom::Statenum::S_NULL.value,     # missilestate
      CDoom::Statenum::S_NULL.value,     # deathstate
      CDoom::Statenum::S_NULL.value,     # xdeathstate
      CDoom::Sfxenum::SFX_None.value,    # deathsound
      0,                                 # speed
      20 * FRACUNIT,                     # radius
      16 * FRACUNIT,                     # height
      100,                               # mass
      0,                                 # damage
      CDoom::Sfxenum::SFX_None.value,    # activesound
      CDoom::Mobjflag::MF_SPECIAL.value, # flags
      CDoom::Statenum::S_NULL.value,     # raisestate
    },
    {                                    # MT_MISC22
      2008,                              # doomednum
      CDoom::Statenum::S_SHEL.value,     # spawnstate
      1000,                              # spawnhealth
      CDoom::Statenum::S_NULL.value,     # seestate
      CDoom::Sfxenum::SFX_None.value,    # seesound
      8,                                 # reactiontime
      CDoom::Sfxenum::SFX_None.value,    # attacksound
      CDoom::Statenum::S_NULL.value,     # painstate
      0,                                 # painchance
      CDoom::Sfxenum::SFX_None.value,    # painsound
      CDoom::Statenum::S_NULL.value,     # meleestate
      CDoom::Statenum::S_NULL.value,     # missilestate
      CDoom::Statenum::S_NULL.value,     # deathstate
      CDoom::Statenum::S_NULL.value,     # xdeathstate
      CDoom::Sfxenum::SFX_None.value,    # deathsound
      0,                                 # speed
      20 * FRACUNIT,                     # radius
      16 * FRACUNIT,                     # height
      100,                               # mass
      0,                                 # damage
      CDoom::Sfxenum::SFX_None.value,    # activesound
      CDoom::Mobjflag::MF_SPECIAL.value, # flags
      CDoom::Statenum::S_NULL.value,     # raisestate
    },
    {                                    # MT_MISC23
      2049,                              # doomednum
      CDoom::Statenum::S_SBOX.value,     # spawnstate
      1000,                              # spawnhealth
      CDoom::Statenum::S_NULL.value,     # seestate
      CDoom::Sfxenum::SFX_None.value,    # seesound
      8,                                 # reactiontime
      CDoom::Sfxenum::SFX_None.value,    # attacksound
      CDoom::Statenum::S_NULL.value,     # painstate
      0,                                 # painchance
      CDoom::Sfxenum::SFX_None.value,    # painsound
      CDoom::Statenum::S_NULL.value,     # meleestate
      CDoom::Statenum::S_NULL.value,     # missilestate
      CDoom::Statenum::S_NULL.value,     # deathstate
      CDoom::Statenum::S_NULL.value,     # xdeathstate
      CDoom::Sfxenum::SFX_None.value,    # deathsound
      0,                                 # speed
      20 * FRACUNIT,                     # radius
      16 * FRACUNIT,                     # height
      100,                               # mass
      0,                                 # damage
      CDoom::Sfxenum::SFX_None.value,    # activesound
      CDoom::Mobjflag::MF_SPECIAL.value, # flags
      CDoom::Statenum::S_NULL.value,     # raisestate
    },
    {                                    # MT_MISC24
      8,                                 # doomednum
      CDoom::Statenum::S_BPAK.value,     # spawnstate
      1000,                              # spawnhealth
      CDoom::Statenum::S_NULL.value,     # seestate
      CDoom::Sfxenum::SFX_None.value,    # seesound
      8,                                 # reactiontime
      CDoom::Sfxenum::SFX_None.value,    # attacksound
      CDoom::Statenum::S_NULL.value,     # painstate
      0,                                 # painchance
      CDoom::Sfxenum::SFX_None.value,    # painsound
      CDoom::Statenum::S_NULL.value,     # meleestate
      CDoom::Statenum::S_NULL.value,     # missilestate
      CDoom::Statenum::S_NULL.value,     # deathstate
      CDoom::Statenum::S_NULL.value,     # xdeathstate
      CDoom::Sfxenum::SFX_None.value,    # deathsound
      0,                                 # speed
      20 * FRACUNIT,                     # radius
      16 * FRACUNIT,                     # height
      100,                               # mass
      0,                                 # damage
      CDoom::Sfxenum::SFX_None.value,    # activesound
      CDoom::Mobjflag::MF_SPECIAL.value, # flags
      CDoom::Statenum::S_NULL.value,     # raisestate
    },
    {                                    # MT_MISC25
      2006,                              # doomednum
      CDoom::Statenum::S_BFUG.value,     # spawnstate
      1000,                              # spawnhealth
      CDoom::Statenum::S_NULL.value,     # seestate
      CDoom::Sfxenum::SFX_None.value,    # seesound
      8,                                 # reactiontime
      CDoom::Sfxenum::SFX_None.value,    # attacksound
      CDoom::Statenum::S_NULL.value,     # painstate
      0,                                 # painchance
      CDoom::Sfxenum::SFX_None.value,    # painsound
      CDoom::Statenum::S_NULL.value,     # meleestate
      CDoom::Statenum::S_NULL.value,     # missilestate
      CDoom::Statenum::S_NULL.value,     # deathstate
      CDoom::Statenum::S_NULL.value,     # xdeathstate
      CDoom::Sfxenum::SFX_None.value,    # deathsound
      0,                                 # speed
      20 * FRACUNIT,                     # radius
      16 * FRACUNIT,                     # height
      100,                               # mass
      0,                                 # damage
      CDoom::Sfxenum::SFX_None.value,    # activesound
      CDoom::Mobjflag::MF_SPECIAL.value, # flags
      CDoom::Statenum::S_NULL.value,     # raisestate
    },
    {                                    # MT_CHAINGUN
      2002,                              # doomednum
      CDoom::Statenum::S_MGUN.value,     # spawnstate
      1000,                              # spawnhealth
      CDoom::Statenum::S_NULL.value,     # seestate
      CDoom::Sfxenum::SFX_None.value,    # seesound
      8,                                 # reactiontime
      CDoom::Sfxenum::SFX_None.value,    # attacksound
      CDoom::Statenum::S_NULL.value,     # painstate
      0,                                 # painchance
      CDoom::Sfxenum::SFX_None.value,    # painsound
      CDoom::Statenum::S_NULL.value,     # meleestate
      CDoom::Statenum::S_NULL.value,     # missilestate
      CDoom::Statenum::S_NULL.value,     # deathstate
      CDoom::Statenum::S_NULL.value,     # xdeathstate
      CDoom::Sfxenum::SFX_None.value,    # deathsound
      0,                                 # speed
      20 * FRACUNIT,                     # radius
      16 * FRACUNIT,                     # height
      100,                               # mass
      0,                                 # damage
      CDoom::Sfxenum::SFX_None.value,    # activesound
      CDoom::Mobjflag::MF_SPECIAL.value, # flags
      CDoom::Statenum::S_NULL.value,     # raisestate
    },
    {                                    # MT_MISC26
      2005,                              # doomednum
      CDoom::Statenum::S_CSAW.value,     # spawnstate
      1000,                              # spawnhealth
      CDoom::Statenum::S_NULL.value,     # seestate
      CDoom::Sfxenum::SFX_None.value,    # seesound
      8,                                 # reactiontime
      CDoom::Sfxenum::SFX_None.value,    # attacksound
      CDoom::Statenum::S_NULL.value,     # painstate
      0,                                 # painchance
      CDoom::Sfxenum::SFX_None.value,    # painsound
      CDoom::Statenum::S_NULL.value,     # meleestate
      CDoom::Statenum::S_NULL.value,     # missilestate
      CDoom::Statenum::S_NULL.value,     # deathstate
      CDoom::Statenum::S_NULL.value,     # xdeathstate
      CDoom::Sfxenum::SFX_None.value,    # deathsound
      0,                                 # speed
      20 * FRACUNIT,                     # radius
      16 * FRACUNIT,                     # height
      100,                               # mass
      0,                                 # damage
      CDoom::Sfxenum::SFX_None.value,    # activesound
      CDoom::Mobjflag::MF_SPECIAL.value, # flags
      CDoom::Statenum::S_NULL.value,     # raisestate
    },
    {                                    # MT_MISC27
      2003,                              # doomednum
      CDoom::Statenum::S_LAUN.value,     # spawnstate
      1000,                              # spawnhealth
      CDoom::Statenum::S_NULL.value,     # seestate
      CDoom::Sfxenum::SFX_None.value,    # seesound
      8,                                 # reactiontime
      CDoom::Sfxenum::SFX_None.value,    # attacksound
      CDoom::Statenum::S_NULL.value,     # painstate
      0,                                 # painchance
      CDoom::Sfxenum::SFX_None.value,    # painsound
      CDoom::Statenum::S_NULL.value,     # meleestate
      CDoom::Statenum::S_NULL.value,     # missilestate
      CDoom::Statenum::S_NULL.value,     # deathstate
      CDoom::Statenum::S_NULL.value,     # xdeathstate
      CDoom::Sfxenum::SFX_None.value,    # deathsound
      0,                                 # speed
      20 * FRACUNIT,                     # radius
      16 * FRACUNIT,                     # height
      100,                               # mass
      0,                                 # damage
      CDoom::Sfxenum::SFX_None.value,    # activesound
      CDoom::Mobjflag::MF_SPECIAL.value, # flags
      CDoom::Statenum::S_NULL.value,     # raisestate
    },
    {                                    # MT_MISC28
      2004,                              # doomednum
      CDoom::Statenum::S_PLAS.value,     # spawnstate
      1000,                              # spawnhealth
      CDoom::Statenum::S_NULL.value,     # seestate
      CDoom::Sfxenum::SFX_None.value,    # seesound
      8,                                 # reactiontime
      CDoom::Sfxenum::SFX_None.value,    # attacksound
      CDoom::Statenum::S_NULL.value,     # painstate
      0,                                 # painchance
      CDoom::Sfxenum::SFX_None.value,    # painsound
      CDoom::Statenum::S_NULL.value,     # meleestate
      CDoom::Statenum::S_NULL.value,     # missilestate
      CDoom::Statenum::S_NULL.value,     # deathstate
      CDoom::Statenum::S_NULL.value,     # xdeathstate
      CDoom::Sfxenum::SFX_None.value,    # deathsound
      0,                                 # speed
      20 * FRACUNIT,                     # radius
      16 * FRACUNIT,                     # height
      100,                               # mass
      0,                                 # damage
      CDoom::Sfxenum::SFX_None.value,    # activesound
      CDoom::Mobjflag::MF_SPECIAL.value, # flags
      CDoom::Statenum::S_NULL.value,     # raisestate
    },
    {                                    # MT_SHOTGUN
      2001,                              # doomednum
      CDoom::Statenum::S_SHOT.value,     # spawnstate
      1000,                              # spawnhealth
      CDoom::Statenum::S_NULL.value,     # seestate
      CDoom::Sfxenum::SFX_None.value,    # seesound
      8,                                 # reactiontime
      CDoom::Sfxenum::SFX_None.value,    # attacksound
      CDoom::Statenum::S_NULL.value,     # painstate
      0,                                 # painchance
      CDoom::Sfxenum::SFX_None.value,    # painsound
      CDoom::Statenum::S_NULL.value,     # meleestate
      CDoom::Statenum::S_NULL.value,     # missilestate
      CDoom::Statenum::S_NULL.value,     # deathstate
      CDoom::Statenum::S_NULL.value,     # xdeathstate
      CDoom::Sfxenum::SFX_None.value,    # deathsound
      0,                                 # speed
      20 * FRACUNIT,                     # radius
      16 * FRACUNIT,                     # height
      100,                               # mass
      0,                                 # damage
      CDoom::Sfxenum::SFX_None.value,    # activesound
      CDoom::Mobjflag::MF_SPECIAL.value, # flags
      CDoom::Statenum::S_NULL.value,     # raisestate
    },
    {                                    # MT_SUPERSHOTGUN
      82,                                # doomednum
      CDoom::Statenum::S_SHOT2.value,    # spawnstate
      1000,                              # spawnhealth
      CDoom::Statenum::S_NULL.value,     # seestate
      CDoom::Sfxenum::SFX_None.value,    # seesound
      8,                                 # reactiontime
      CDoom::Sfxenum::SFX_None.value,    # attacksound
      CDoom::Statenum::S_NULL.value,     # painstate
      0,                                 # painchance
      CDoom::Sfxenum::SFX_None.value,    # painsound
      CDoom::Statenum::S_NULL.value,     # meleestate
      CDoom::Statenum::S_NULL.value,     # missilestate
      CDoom::Statenum::S_NULL.value,     # deathstate
      CDoom::Statenum::S_NULL.value,     # xdeathstate
      CDoom::Sfxenum::SFX_None.value,    # deathsound
      0,                                 # speed
      20 * FRACUNIT,                     # radius
      16 * FRACUNIT,                     # height
      100,                               # mass
      0,                                 # damage
      CDoom::Sfxenum::SFX_None.value,    # activesound
      CDoom::Mobjflag::MF_SPECIAL.value, # flags
      CDoom::Statenum::S_NULL.value,     # raisestate
    },
    {                                    # MT_MISC29
      85,                                # doomednum
      CDoom::Statenum::S_TECHLAMP.value, # spawnstate
      1000,                              # spawnhealth
      CDoom::Statenum::S_NULL.value,     # seestate
      CDoom::Sfxenum::SFX_None.value,    # seesound
      8,                                 # reactiontime
      CDoom::Sfxenum::SFX_None.value,    # attacksound
      CDoom::Statenum::S_NULL.value,     # painstate
      0,                                 # painchance
      CDoom::Sfxenum::SFX_None.value,    # painsound
      CDoom::Statenum::S_NULL.value,     # meleestate
      CDoom::Statenum::S_NULL.value,     # missilestate
      CDoom::Statenum::S_NULL.value,     # deathstate
      CDoom::Statenum::S_NULL.value,     # xdeathstate
      CDoom::Sfxenum::SFX_None.value,    # deathsound
      0,                                 # speed
      16 * FRACUNIT,                     # radius
      16 * FRACUNIT,                     # height
      100,                               # mass
      0,                                 # damage
      CDoom::Sfxenum::SFX_None.value,    # activesound
      CDoom::Mobjflag::MF_SOLID.value,   # flags
      CDoom::Statenum::S_NULL.value,     # raisestate
    },
    {                                     # MT_MISC30
      86,                                 # doomednum
      CDoom::Statenum::S_TECH2LAMP.value, # spawnstate
      1000,                               # spawnhealth
      CDoom::Statenum::S_NULL.value,      # seestate
      CDoom::Sfxenum::SFX_None.value,     # seesound
      8,                                  # reactiontime
      CDoom::Sfxenum::SFX_None.value,     # attacksound
      CDoom::Statenum::S_NULL.value,      # painstate
      0,                                  # painchance
      CDoom::Sfxenum::SFX_None.value,     # painsound
      CDoom::Statenum::S_NULL.value,      # meleestate
      CDoom::Statenum::S_NULL.value,      # missilestate
      CDoom::Statenum::S_NULL.value,      # deathstate
      CDoom::Statenum::S_NULL.value,      # xdeathstate
      CDoom::Sfxenum::SFX_None.value,     # deathsound
      0,                                  # speed
      16 * FRACUNIT,                      # radius
      16 * FRACUNIT,                      # height
      100,                                # mass
      0,                                  # damage
      CDoom::Sfxenum::SFX_None.value,     # activesound
      CDoom::Mobjflag::MF_SOLID.value,    # flags
      CDoom::Statenum::S_NULL.value,      # raisestate
    },
    {                                  # MT_MISC31
      2028,                            # doomednum
      CDoom::Statenum::S_COLU.value,   # spawnstate
      1000,                            # spawnhealth
      CDoom::Statenum::S_NULL.value,   # seestate
      CDoom::Sfxenum::SFX_None.value,  # seesound
      8,                               # reactiontime
      CDoom::Sfxenum::SFX_None.value,  # attacksound
      CDoom::Statenum::S_NULL.value,   # painstate
      0,                               # painchance
      CDoom::Sfxenum::SFX_None.value,  # painsound
      CDoom::Statenum::S_NULL.value,   # meleestate
      CDoom::Statenum::S_NULL.value,   # missilestate
      CDoom::Statenum::S_NULL.value,   # deathstate
      CDoom::Statenum::S_NULL.value,   # xdeathstate
      CDoom::Sfxenum::SFX_None.value,  # deathsound
      0,                               # speed
      16 * FRACUNIT,                   # radius
      16 * FRACUNIT,                   # height
      100,                             # mass
      0,                               # damage
      CDoom::Sfxenum::SFX_None.value,  # activesound
      CDoom::Mobjflag::MF_SOLID.value, # flags
      CDoom::Statenum::S_NULL.value,   # raisestate
    },
    {                                      # MT_MISC32
      30,                                  # doomednum
      CDoom::Statenum::S_TALLGRNCOL.value, # spawnstate
      1000,                                # spawnhealth
      CDoom::Statenum::S_NULL.value,       # seestate
      CDoom::Sfxenum::SFX_None.value,      # seesound
      8,                                   # reactiontime
      CDoom::Sfxenum::SFX_None.value,      # attacksound
      CDoom::Statenum::S_NULL.value,       # painstate
      0,                                   # painchance
      CDoom::Sfxenum::SFX_None.value,      # painsound
      CDoom::Statenum::S_NULL.value,       # meleestate
      CDoom::Statenum::S_NULL.value,       # missilestate
      CDoom::Statenum::S_NULL.value,       # deathstate
      CDoom::Statenum::S_NULL.value,       # xdeathstate
      CDoom::Sfxenum::SFX_None.value,      # deathsound
      0,                                   # speed
      16 * FRACUNIT,                       # radius
      16 * FRACUNIT,                       # height
      100,                                 # mass
      0,                                   # damage
      CDoom::Sfxenum::SFX_None.value,      # activesound
      CDoom::Mobjflag::MF_SOLID.value,     # flags
      CDoom::Statenum::S_NULL.value,       # raisestate
    },
    {                                      # MT_MISC33
      31,                                  # doomednum
      CDoom::Statenum::S_SHRTGRNCOL.value, # spawnstate
      1000,                                # spawnhealth
      CDoom::Statenum::S_NULL.value,       # seestate
      CDoom::Sfxenum::SFX_None.value,      # seesound
      8,                                   # reactiontime
      CDoom::Sfxenum::SFX_None.value,      # attacksound
      CDoom::Statenum::S_NULL.value,       # painstate
      0,                                   # painchance
      CDoom::Sfxenum::SFX_None.value,      # painsound
      CDoom::Statenum::S_NULL.value,       # meleestate
      CDoom::Statenum::S_NULL.value,       # missilestate
      CDoom::Statenum::S_NULL.value,       # deathstate
      CDoom::Statenum::S_NULL.value,       # xdeathstate
      CDoom::Sfxenum::SFX_None.value,      # deathsound
      0,                                   # speed
      16 * FRACUNIT,                       # radius
      16 * FRACUNIT,                       # height
      100,                                 # mass
      0,                                   # damage
      CDoom::Sfxenum::SFX_None.value,      # activesound
      CDoom::Mobjflag::MF_SOLID.value,     # flags
      CDoom::Statenum::S_NULL.value,       # raisestate
    },
    {                                      # MT_MISC34
      32,                                  # doomednum
      CDoom::Statenum::S_TALLREDCOL.value, # spawnstate
      1000,                                # spawnhealth
      CDoom::Statenum::S_NULL.value,       # seestate
      CDoom::Sfxenum::SFX_None.value,      # seesound
      8,                                   # reactiontime
      CDoom::Sfxenum::SFX_None.value,      # attacksound
      CDoom::Statenum::S_NULL.value,       # painstate
      0,                                   # painchance
      CDoom::Sfxenum::SFX_None.value,      # painsound
      CDoom::Statenum::S_NULL.value,       # meleestate
      CDoom::Statenum::S_NULL.value,       # missilestate
      CDoom::Statenum::S_NULL.value,       # deathstate
      CDoom::Statenum::S_NULL.value,       # xdeathstate
      CDoom::Sfxenum::SFX_None.value,      # deathsound
      0,                                   # speed
      16 * FRACUNIT,                       # radius
      16 * FRACUNIT,                       # height
      100,                                 # mass
      0,                                   # damage
      CDoom::Sfxenum::SFX_None.value,      # activesound
      CDoom::Mobjflag::MF_SOLID.value,     # flags
      CDoom::Statenum::S_NULL.value,       # raisestate
    },
    {                                      # MT_MISC35
      33,                                  # doomednum
      CDoom::Statenum::S_SHRTREDCOL.value, # spawnstate
      1000,                                # spawnhealth
      CDoom::Statenum::S_NULL.value,       # seestate
      CDoom::Sfxenum::SFX_None.value,      # seesound
      8,                                   # reactiontime
      CDoom::Sfxenum::SFX_None.value,      # attacksound
      CDoom::Statenum::S_NULL.value,       # painstate
      0,                                   # painchance
      CDoom::Sfxenum::SFX_None.value,      # painsound
      CDoom::Statenum::S_NULL.value,       # meleestate
      CDoom::Statenum::S_NULL.value,       # missilestate
      CDoom::Statenum::S_NULL.value,       # deathstate
      CDoom::Statenum::S_NULL.value,       # xdeathstate
      CDoom::Sfxenum::SFX_None.value,      # deathsound
      0,                                   # speed
      16 * FRACUNIT,                       # radius
      16 * FRACUNIT,                       # height
      100,                                 # mass
      0,                                   # damage
      CDoom::Sfxenum::SFX_None.value,      # activesound
      CDoom::Mobjflag::MF_SOLID.value,     # flags
      CDoom::Statenum::S_NULL.value,       # raisestate
    },
    {                                    # MT_MISC36
      37,                                # doomednum
      CDoom::Statenum::S_SKULLCOL.value, # spawnstate
      1000,                              # spawnhealth
      CDoom::Statenum::S_NULL.value,     # seestate
      CDoom::Sfxenum::SFX_None.value,    # seesound
      8,                                 # reactiontime
      CDoom::Sfxenum::SFX_None.value,    # attacksound
      CDoom::Statenum::S_NULL.value,     # painstate
      0,                                 # painchance
      CDoom::Sfxenum::SFX_None.value,    # painsound
      CDoom::Statenum::S_NULL.value,     # meleestate
      CDoom::Statenum::S_NULL.value,     # missilestate
      CDoom::Statenum::S_NULL.value,     # deathstate
      CDoom::Statenum::S_NULL.value,     # xdeathstate
      CDoom::Sfxenum::SFX_None.value,    # deathsound
      0,                                 # speed
      16 * FRACUNIT,                     # radius
      16 * FRACUNIT,                     # height
      100,                               # mass
      0,                                 # damage
      CDoom::Sfxenum::SFX_None.value,    # activesound
      CDoom::Mobjflag::MF_SOLID.value,   # flags
      CDoom::Statenum::S_NULL.value,     # raisestate
    },
    {                                    # MT_MISC37
      36,                                # doomednum
      CDoom::Statenum::S_HEARTCOL.value, # spawnstate
      1000,                              # spawnhealth
      CDoom::Statenum::S_NULL.value,     # seestate
      CDoom::Sfxenum::SFX_None.value,    # seesound
      8,                                 # reactiontime
      CDoom::Sfxenum::SFX_None.value,    # attacksound
      CDoom::Statenum::S_NULL.value,     # painstate
      0,                                 # painchance
      CDoom::Sfxenum::SFX_None.value,    # painsound
      CDoom::Statenum::S_NULL.value,     # meleestate
      CDoom::Statenum::S_NULL.value,     # missilestate
      CDoom::Statenum::S_NULL.value,     # deathstate
      CDoom::Statenum::S_NULL.value,     # xdeathstate
      CDoom::Sfxenum::SFX_None.value,    # deathsound
      0,                                 # speed
      16 * FRACUNIT,                     # radius
      16 * FRACUNIT,                     # height
      100,                               # mass
      0,                                 # damage
      CDoom::Sfxenum::SFX_None.value,    # activesound
      CDoom::Mobjflag::MF_SOLID.value,   # flags
      CDoom::Statenum::S_NULL.value,     # raisestate
    },
    {                                   # MT_MISC38
      41,                               # doomednum
      CDoom::Statenum::S_EVILEYE.value, # spawnstate
      1000,                             # spawnhealth
      CDoom::Statenum::S_NULL.value,    # seestate
      CDoom::Sfxenum::SFX_None.value,   # seesound
      8,                                # reactiontime
      CDoom::Sfxenum::SFX_None.value,   # attacksound
      CDoom::Statenum::S_NULL.value,    # painstate
      0,                                # painchance
      CDoom::Sfxenum::SFX_None.value,   # painsound
      CDoom::Statenum::S_NULL.value,    # meleestate
      CDoom::Statenum::S_NULL.value,    # missilestate
      CDoom::Statenum::S_NULL.value,    # deathstate
      CDoom::Statenum::S_NULL.value,    # xdeathstate
      CDoom::Sfxenum::SFX_None.value,   # deathsound
      0,                                # speed
      16 * FRACUNIT,                    # radius
      16 * FRACUNIT,                    # height
      100,                              # mass
      0,                                # damage
      CDoom::Sfxenum::SFX_None.value,   # activesound
      CDoom::Mobjflag::MF_SOLID.value,  # flags
      CDoom::Statenum::S_NULL.value,    # raisestate
    },
    {                                      # MT_MISC39
      42,                                  # doomednum
      CDoom::Statenum::S_FLOATSKULL.value, # spawnstate
      1000,                                # spawnhealth
      CDoom::Statenum::S_NULL.value,       # seestate
      CDoom::Sfxenum::SFX_None.value,      # seesound
      8,                                   # reactiontime
      CDoom::Sfxenum::SFX_None.value,      # attacksound
      CDoom::Statenum::S_NULL.value,       # painstate
      0,                                   # painchance
      CDoom::Sfxenum::SFX_None.value,      # painsound
      CDoom::Statenum::S_NULL.value,       # meleestate
      CDoom::Statenum::S_NULL.value,       # missilestate
      CDoom::Statenum::S_NULL.value,       # deathstate
      CDoom::Statenum::S_NULL.value,       # xdeathstate
      CDoom::Sfxenum::SFX_None.value,      # deathsound
      0,                                   # speed
      16 * FRACUNIT,                       # radius
      16 * FRACUNIT,                       # height
      100,                                 # mass
      0,                                   # damage
      CDoom::Sfxenum::SFX_None.value,      # activesound
      CDoom::Mobjflag::MF_SOLID.value,     # flags
      CDoom::Statenum::S_NULL.value,       # raisestate
    },
    {                                     # MT_MISC40
      43,                                 # doomednum
      CDoom::Statenum::S_TORCHTREE.value, # spawnstate
      1000,                               # spawnhealth
      CDoom::Statenum::S_NULL.value,      # seestate
      CDoom::Sfxenum::SFX_None.value,     # seesound
      8,                                  # reactiontime
      CDoom::Sfxenum::SFX_None.value,     # attacksound
      CDoom::Statenum::S_NULL.value,      # painstate
      0,                                  # painchance
      CDoom::Sfxenum::SFX_None.value,     # painsound
      CDoom::Statenum::S_NULL.value,      # meleestate
      CDoom::Statenum::S_NULL.value,      # missilestate
      CDoom::Statenum::S_NULL.value,      # deathstate
      CDoom::Statenum::S_NULL.value,      # xdeathstate
      CDoom::Sfxenum::SFX_None.value,     # deathsound
      0,                                  # speed
      16 * FRACUNIT,                      # radius
      16 * FRACUNIT,                      # height
      100,                                # mass
      0,                                  # damage
      CDoom::Sfxenum::SFX_None.value,     # activesound
      CDoom::Mobjflag::MF_SOLID.value,    # flags
      CDoom::Statenum::S_NULL.value,      # raisestate
    },
    {                                     # MT_MISC41
      44,                                 # doomednum
      CDoom::Statenum::S_BLUETORCH.value, # spawnstate
      1000,                               # spawnhealth
      CDoom::Statenum::S_NULL.value,      # seestate
      CDoom::Sfxenum::SFX_None.value,     # seesound
      8,                                  # reactiontime
      CDoom::Sfxenum::SFX_None.value,     # attacksound
      CDoom::Statenum::S_NULL.value,      # painstate
      0,                                  # painchance
      CDoom::Sfxenum::SFX_None.value,     # painsound
      CDoom::Statenum::S_NULL.value,      # meleestate
      CDoom::Statenum::S_NULL.value,      # missilestate
      CDoom::Statenum::S_NULL.value,      # deathstate
      CDoom::Statenum::S_NULL.value,      # xdeathstate
      CDoom::Sfxenum::SFX_None.value,     # deathsound
      0,                                  # speed
      16 * FRACUNIT,                      # radius
      16 * FRACUNIT,                      # height
      100,                                # mass
      0,                                  # damage
      CDoom::Sfxenum::SFX_None.value,     # activesound
      CDoom::Mobjflag::MF_SOLID.value,    # flags
      CDoom::Statenum::S_NULL.value,      # raisestate
    },
    {                                      # MT_MISC42
      45,                                  # doomednum
      CDoom::Statenum::S_GREENTORCH.value, # spawnstate
      1000,                                # spawnhealth
      CDoom::Statenum::S_NULL.value,       # seestate
      CDoom::Sfxenum::SFX_None.value,      # seesound
      8,                                   # reactiontime
      CDoom::Sfxenum::SFX_None.value,      # attacksound
      CDoom::Statenum::S_NULL.value,       # painstate
      0,                                   # painchance
      CDoom::Sfxenum::SFX_None.value,      # painsound
      CDoom::Statenum::S_NULL.value,       # meleestate
      CDoom::Statenum::S_NULL.value,       # missilestate
      CDoom::Statenum::S_NULL.value,       # deathstate
      CDoom::Statenum::S_NULL.value,       # xdeathstate
      CDoom::Sfxenum::SFX_None.value,      # deathsound
      0,                                   # speed
      16 * FRACUNIT,                       # radius
      16 * FRACUNIT,                       # height
      100,                                 # mass
      0,                                   # damage
      CDoom::Sfxenum::SFX_None.value,      # activesound
      CDoom::Mobjflag::MF_SOLID.value,     # flags
      CDoom::Statenum::S_NULL.value,       # raisestate
    },
    {                                    # MT_MISC43
      46,                                # doomednum
      CDoom::Statenum::S_REDTORCH.value, # spawnstate
      1000,                              # spawnhealth
      CDoom::Statenum::S_NULL.value,     # seestate
      CDoom::Sfxenum::SFX_None.value,    # seesound
      8,                                 # reactiontime
      CDoom::Sfxenum::SFX_None.value,    # attacksound
      CDoom::Statenum::S_NULL.value,     # painstate
      0,                                 # painchance
      CDoom::Sfxenum::SFX_None.value,    # painsound
      CDoom::Statenum::S_NULL.value,     # meleestate
      CDoom::Statenum::S_NULL.value,     # missilestate
      CDoom::Statenum::S_NULL.value,     # deathstate
      CDoom::Statenum::S_NULL.value,     # xdeathstate
      CDoom::Sfxenum::SFX_None.value,    # deathsound
      0,                                 # speed
      16 * FRACUNIT,                     # radius
      16 * FRACUNIT,                     # height
      100,                               # mass
      0,                                 # damage
      CDoom::Sfxenum::SFX_None.value,    # activesound
      CDoom::Mobjflag::MF_SOLID.value,   # flags
      CDoom::Statenum::S_NULL.value,     # raisestate
    },
    {                                      # MT_MISC44
      55,                                  # doomednum
      CDoom::Statenum::S_BTORCHSHRT.value, # spawnstate
      1000,                                # spawnhealth
      CDoom::Statenum::S_NULL.value,       # seestate
      CDoom::Sfxenum::SFX_None.value,      # seesound
      8,                                   # reactiontime
      CDoom::Sfxenum::SFX_None.value,      # attacksound
      CDoom::Statenum::S_NULL.value,       # painstate
      0,                                   # painchance
      CDoom::Sfxenum::SFX_None.value,      # painsound
      CDoom::Statenum::S_NULL.value,       # meleestate
      CDoom::Statenum::S_NULL.value,       # missilestate
      CDoom::Statenum::S_NULL.value,       # deathstate
      CDoom::Statenum::S_NULL.value,       # xdeathstate
      CDoom::Sfxenum::SFX_None.value,      # deathsound
      0,                                   # speed
      16 * FRACUNIT,                       # radius
      16 * FRACUNIT,                       # height
      100,                                 # mass
      0,                                   # damage
      CDoom::Sfxenum::SFX_None.value,      # activesound
      CDoom::Mobjflag::MF_SOLID.value,     # flags
      CDoom::Statenum::S_NULL.value,       # raisestate
    },
    {                                      # MT_MISC45
      56,                                  # doomednum
      CDoom::Statenum::S_GTORCHSHRT.value, # spawnstate
      1000,                                # spawnhealth
      CDoom::Statenum::S_NULL.value,       # seestate
      CDoom::Sfxenum::SFX_None.value,      # seesound
      8,                                   # reactiontime
      CDoom::Sfxenum::SFX_None.value,      # attacksound
      CDoom::Statenum::S_NULL.value,       # painstate
      0,                                   # painchance
      CDoom::Sfxenum::SFX_None.value,      # painsound
      CDoom::Statenum::S_NULL.value,       # meleestate
      CDoom::Statenum::S_NULL.value,       # missilestate
      CDoom::Statenum::S_NULL.value,       # deathstate
      CDoom::Statenum::S_NULL.value,       # xdeathstate
      CDoom::Sfxenum::SFX_None.value,      # deathsound
      0,                                   # speed
      16 * FRACUNIT,                       # radius
      16 * FRACUNIT,                       # height
      100,                                 # mass
      0,                                   # damage
      CDoom::Sfxenum::SFX_None.value,      # activesound
      CDoom::Mobjflag::MF_SOLID.value,     # flags
      CDoom::Statenum::S_NULL.value,       # raisestate
    },
    {                                      # MT_MISC46
      57,                                  # doomednum
      CDoom::Statenum::S_RTORCHSHRT.value, # spawnstate
      1000,                                # spawnhealth
      CDoom::Statenum::S_NULL.value,       # seestate
      CDoom::Sfxenum::SFX_None.value,      # seesound
      8,                                   # reactiontime
      CDoom::Sfxenum::SFX_None.value,      # attacksound
      CDoom::Statenum::S_NULL.value,       # painstate
      0,                                   # painchance
      CDoom::Sfxenum::SFX_None.value,      # painsound
      CDoom::Statenum::S_NULL.value,       # meleestate
      CDoom::Statenum::S_NULL.value,       # missilestate
      CDoom::Statenum::S_NULL.value,       # deathstate
      CDoom::Statenum::S_NULL.value,       # xdeathstate
      CDoom::Sfxenum::SFX_None.value,      # deathsound
      0,                                   # speed
      16 * FRACUNIT,                       # radius
      16 * FRACUNIT,                       # height
      100,                                 # mass
      0,                                   # damage
      CDoom::Sfxenum::SFX_None.value,      # activesound
      CDoom::Mobjflag::MF_SOLID.value,     # flags
      CDoom::Statenum::S_NULL.value,       # raisestate
    },
    {                                      # MT_MISC47
      47,                                  # doomednum
      CDoom::Statenum::S_STALAGTITE.value, # spawnstate
      1000,                                # spawnhealth
      CDoom::Statenum::S_NULL.value,       # seestate
      CDoom::Sfxenum::SFX_None.value,      # seesound
      8,                                   # reactiontime
      CDoom::Sfxenum::SFX_None.value,      # attacksound
      CDoom::Statenum::S_NULL.value,       # painstate
      0,                                   # painchance
      CDoom::Sfxenum::SFX_None.value,      # painsound
      CDoom::Statenum::S_NULL.value,       # meleestate
      CDoom::Statenum::S_NULL.value,       # missilestate
      CDoom::Statenum::S_NULL.value,       # deathstate
      CDoom::Statenum::S_NULL.value,       # xdeathstate
      CDoom::Sfxenum::SFX_None.value,      # deathsound
      0,                                   # speed
      16 * FRACUNIT,                       # radius
      16 * FRACUNIT,                       # height
      100,                                 # mass
      0,                                   # damage
      CDoom::Sfxenum::SFX_None.value,      # activesound
      CDoom::Mobjflag::MF_SOLID.value,     # flags
      CDoom::Statenum::S_NULL.value,       # raisestate
    },
    {                                      # MT_MISC48
      48,                                  # doomednum
      CDoom::Statenum::S_TECHPILLAR.value, # spawnstate
      1000,                                # spawnhealth
      CDoom::Statenum::S_NULL.value,       # seestate
      CDoom::Sfxenum::SFX_None.value,      # seesound
      8,                                   # reactiontime
      CDoom::Sfxenum::SFX_None.value,      # attacksound
      CDoom::Statenum::S_NULL.value,       # painstate
      0,                                   # painchance
      CDoom::Sfxenum::SFX_None.value,      # painsound
      CDoom::Statenum::S_NULL.value,       # meleestate
      CDoom::Statenum::S_NULL.value,       # missilestate
      CDoom::Statenum::S_NULL.value,       # deathstate
      CDoom::Statenum::S_NULL.value,       # xdeathstate
      CDoom::Sfxenum::SFX_None.value,      # deathsound
      0,                                   # speed
      16 * FRACUNIT,                       # radius
      16 * FRACUNIT,                       # height
      100,                                 # mass
      0,                                   # damage
      CDoom::Sfxenum::SFX_None.value,      # activesound
      CDoom::Mobjflag::MF_SOLID.value,     # flags
      CDoom::Statenum::S_NULL.value,       # raisestate
    },
    {                                      # MT_MISC49
      34,                                  # doomednum
      CDoom::Statenum::S_CANDLESTIK.value, # spawnstate
      1000,                                # spawnhealth
      CDoom::Statenum::S_NULL.value,       # seestate
      CDoom::Sfxenum::SFX_None.value,      # seesound
      8,                                   # reactiontime
      CDoom::Sfxenum::SFX_None.value,      # attacksound
      CDoom::Statenum::S_NULL.value,       # painstate
      0,                                   # painchance
      CDoom::Sfxenum::SFX_None.value,      # painsound
      CDoom::Statenum::S_NULL.value,       # meleestate
      CDoom::Statenum::S_NULL.value,       # missilestate
      CDoom::Statenum::S_NULL.value,       # deathstate
      CDoom::Statenum::S_NULL.value,       # xdeathstate
      CDoom::Sfxenum::SFX_None.value,      # deathsound
      0,                                   # speed
      20 * FRACUNIT,                       # radius
      16 * FRACUNIT,                       # height
      100,                                 # mass
      0,                                   # damage
      CDoom::Sfxenum::SFX_None.value,      # activesound
      0,                                   # flags
      CDoom::Statenum::S_NULL.value,       # raisestate
    },
    {                                      # MT_MISC50
      35,                                  # doomednum
      CDoom::Statenum::S_CANDELABRA.value, # spawnstate
      1000,                                # spawnhealth
      CDoom::Statenum::S_NULL.value,       # seestate
      CDoom::Sfxenum::SFX_None.value,      # seesound
      8,                                   # reactiontime
      CDoom::Sfxenum::SFX_None.value,      # attacksound
      CDoom::Statenum::S_NULL.value,       # painstate
      0,                                   # painchance
      CDoom::Sfxenum::SFX_None.value,      # painsound
      CDoom::Statenum::S_NULL.value,       # meleestate
      CDoom::Statenum::S_NULL.value,       # missilestate
      CDoom::Statenum::S_NULL.value,       # deathstate
      CDoom::Statenum::S_NULL.value,       # xdeathstate
      CDoom::Sfxenum::SFX_None.value,      # deathsound
      0,                                   # speed
      16 * FRACUNIT,                       # radius
      16 * FRACUNIT,                       # height
      100,                                 # mass
      0,                                   # damage
      CDoom::Sfxenum::SFX_None.value,      # activesound
      CDoom::Mobjflag::MF_SOLID.value,     # flags
      CDoom::Statenum::S_NULL.value,       # raisestate
    },
    {                                                                                                                   # MT_MISC51
      49,                                                                                                               # doomednum
      CDoom::Statenum::S_BLOODYTWITCH.value,                                                                            # spawnstate
      1000,                                                                                                             # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                                                    # seestate
      CDoom::Sfxenum::SFX_None.value,                                                                                   # seesound
      8,                                                                                                                # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                                                   # attacksound
      CDoom::Statenum::S_NULL.value,                                                                                    # painstate
      0,                                                                                                                # painchance
      CDoom::Sfxenum::SFX_None.value,                                                                                   # painsound
      CDoom::Statenum::S_NULL.value,                                                                                    # meleestate
      CDoom::Statenum::S_NULL.value,                                                                                    # missilestate
      CDoom::Statenum::S_NULL.value,                                                                                    # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                    # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                                                                   # deathsound
      0,                                                                                                                # speed
      16 * FRACUNIT,                                                                                                    # radius
      68 * FRACUNIT,                                                                                                    # height
      100,                                                                                                              # mass
      0,                                                                                                                # damage
      CDoom::Sfxenum::SFX_None.value,                                                                                   # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SPAWNCEILING.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                    # raisestate
    },
    {                                                                                                                   # MT_MISC52
      50,                                                                                                               # doomednum
      CDoom::Statenum::S_MEAT2.value,                                                                                   # spawnstate
      1000,                                                                                                             # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                                                    # seestate
      CDoom::Sfxenum::SFX_None.value,                                                                                   # seesound
      8,                                                                                                                # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                                                   # attacksound
      CDoom::Statenum::S_NULL.value,                                                                                    # painstate
      0,                                                                                                                # painchance
      CDoom::Sfxenum::SFX_None.value,                                                                                   # painsound
      CDoom::Statenum::S_NULL.value,                                                                                    # meleestate
      CDoom::Statenum::S_NULL.value,                                                                                    # missilestate
      CDoom::Statenum::S_NULL.value,                                                                                    # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                    # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                                                                   # deathsound
      0,                                                                                                                # speed
      16 * FRACUNIT,                                                                                                    # radius
      84 * FRACUNIT,                                                                                                    # height
      100,                                                                                                              # mass
      0,                                                                                                                # damage
      CDoom::Sfxenum::SFX_None.value,                                                                                   # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SPAWNCEILING.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                    # raisestate
    },
    {                                                                                                                   # MT_MISC53
      51,                                                                                                               # doomednum
      CDoom::Statenum::S_MEAT3.value,                                                                                   # spawnstate
      1000,                                                                                                             # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                                                    # seestate
      CDoom::Sfxenum::SFX_None.value,                                                                                   # seesound
      8,                                                                                                                # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                                                   # attacksound
      CDoom::Statenum::S_NULL.value,                                                                                    # painstate
      0,                                                                                                                # painchance
      CDoom::Sfxenum::SFX_None.value,                                                                                   # painsound
      CDoom::Statenum::S_NULL.value,                                                                                    # meleestate
      CDoom::Statenum::S_NULL.value,                                                                                    # missilestate
      CDoom::Statenum::S_NULL.value,                                                                                    # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                    # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                                                                   # deathsound
      0,                                                                                                                # speed
      16 * FRACUNIT,                                                                                                    # radius
      84 * FRACUNIT,                                                                                                    # height
      100,                                                                                                              # mass
      0,                                                                                                                # damage
      CDoom::Sfxenum::SFX_None.value,                                                                                   # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SPAWNCEILING.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                    # raisestate
    },
    {                                                                                                                   # MT_MISC54
      52,                                                                                                               # doomednum
      CDoom::Statenum::S_MEAT4.value,                                                                                   # spawnstate
      1000,                                                                                                             # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                                                    # seestate
      CDoom::Sfxenum::SFX_None.value,                                                                                   # seesound
      8,                                                                                                                # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                                                   # attacksound
      CDoom::Statenum::S_NULL.value,                                                                                    # painstate
      0,                                                                                                                # painchance
      CDoom::Sfxenum::SFX_None.value,                                                                                   # painsound
      CDoom::Statenum::S_NULL.value,                                                                                    # meleestate
      CDoom::Statenum::S_NULL.value,                                                                                    # missilestate
      CDoom::Statenum::S_NULL.value,                                                                                    # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                    # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                                                                   # deathsound
      0,                                                                                                                # speed
      16 * FRACUNIT,                                                                                                    # radius
      68 * FRACUNIT,                                                                                                    # height
      100,                                                                                                              # mass
      0,                                                                                                                # damage
      CDoom::Sfxenum::SFX_None.value,                                                                                   # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SPAWNCEILING.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                    # raisestate
    },
    {                                                                                                                   # MT_MISC55
      53,                                                                                                               # doomednum
      CDoom::Statenum::S_MEAT5.value,                                                                                   # spawnstate
      1000,                                                                                                             # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                                                    # seestate
      CDoom::Sfxenum::SFX_None.value,                                                                                   # seesound
      8,                                                                                                                # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                                                   # attacksound
      CDoom::Statenum::S_NULL.value,                                                                                    # painstate
      0,                                                                                                                # painchance
      CDoom::Sfxenum::SFX_None.value,                                                                                   # painsound
      CDoom::Statenum::S_NULL.value,                                                                                    # meleestate
      CDoom::Statenum::S_NULL.value,                                                                                    # missilestate
      CDoom::Statenum::S_NULL.value,                                                                                    # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                    # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                                                                   # deathsound
      0,                                                                                                                # speed
      16 * FRACUNIT,                                                                                                    # radius
      52 * FRACUNIT,                                                                                                    # height
      100,                                                                                                              # mass
      0,                                                                                                                # damage
      CDoom::Sfxenum::SFX_None.value,                                                                                   # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SPAWNCEILING.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                    # raisestate
    },
    {                                                                                 # MT_MISC56
      59,                                                                             # doomednum
      CDoom::Statenum::S_MEAT2.value,                                                 # spawnstate
      1000,                                                                           # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                  # seestate
      CDoom::Sfxenum::SFX_None.value,                                                 # seesound
      8,                                                                              # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                 # attacksound
      CDoom::Statenum::S_NULL.value,                                                  # painstate
      0,                                                                              # painchance
      CDoom::Sfxenum::SFX_None.value,                                                 # painsound
      CDoom::Statenum::S_NULL.value,                                                  # meleestate
      CDoom::Statenum::S_NULL.value,                                                  # missilestate
      CDoom::Statenum::S_NULL.value,                                                  # deathstate
      CDoom::Statenum::S_NULL.value,                                                  # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                                 # deathsound
      0,                                                                              # speed
      20 * FRACUNIT,                                                                  # radius
      84 * FRACUNIT,                                                                  # height
      100,                                                                            # mass
      0,                                                                              # damage
      CDoom::Sfxenum::SFX_None.value,                                                 # activesound
      (CDoom::Mobjflag::MF_SPAWNCEILING.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                  # raisestate
    },
    {                                                                                 # MT_MISC57
      60,                                                                             # doomednum
      CDoom::Statenum::S_MEAT4.value,                                                 # spawnstate
      1000,                                                                           # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                  # seestate
      CDoom::Sfxenum::SFX_None.value,                                                 # seesound
      8,                                                                              # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                 # attacksound
      CDoom::Statenum::S_NULL.value,                                                  # painstate
      0,                                                                              # painchance
      CDoom::Sfxenum::SFX_None.value,                                                 # painsound
      CDoom::Statenum::S_NULL.value,                                                  # meleestate
      CDoom::Statenum::S_NULL.value,                                                  # missilestate
      CDoom::Statenum::S_NULL.value,                                                  # deathstate
      CDoom::Statenum::S_NULL.value,                                                  # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                                 # deathsound
      0,                                                                              # speed
      20 * FRACUNIT,                                                                  # radius
      68 * FRACUNIT,                                                                  # height
      100,                                                                            # mass
      0,                                                                              # damage
      CDoom::Sfxenum::SFX_None.value,                                                 # activesound
      (CDoom::Mobjflag::MF_SPAWNCEILING.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                  # raisestate
    },
    {                                                                                 # MT_MISC58
      61,                                                                             # doomednum
      CDoom::Statenum::S_MEAT3.value,                                                 # spawnstate
      1000,                                                                           # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                  # seestate
      CDoom::Sfxenum::SFX_None.value,                                                 # seesound
      8,                                                                              # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                 # attacksound
      CDoom::Statenum::S_NULL.value,                                                  # painstate
      0,                                                                              # painchance
      CDoom::Sfxenum::SFX_None.value,                                                 # painsound
      CDoom::Statenum::S_NULL.value,                                                  # meleestate
      CDoom::Statenum::S_NULL.value,                                                  # missilestate
      CDoom::Statenum::S_NULL.value,                                                  # deathstate
      CDoom::Statenum::S_NULL.value,                                                  # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                                 # deathsound
      0,                                                                              # speed
      20 * FRACUNIT,                                                                  # radius
      52 * FRACUNIT,                                                                  # height
      100,                                                                            # mass
      0,                                                                              # damage
      CDoom::Sfxenum::SFX_None.value,                                                 # activesound
      (CDoom::Mobjflag::MF_SPAWNCEILING.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                  # raisestate
    },
    {                                                                                 # MT_MISC59
      62,                                                                             # doomednum
      CDoom::Statenum::S_MEAT5.value,                                                 # spawnstate
      1000,                                                                           # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                  # seestate
      CDoom::Sfxenum::SFX_None.value,                                                 # seesound
      8,                                                                              # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                 # attacksound
      CDoom::Statenum::S_NULL.value,                                                  # painstate
      0,                                                                              # painchance
      CDoom::Sfxenum::SFX_None.value,                                                 # painsound
      CDoom::Statenum::S_NULL.value,                                                  # meleestate
      CDoom::Statenum::S_NULL.value,                                                  # missilestate
      CDoom::Statenum::S_NULL.value,                                                  # deathstate
      CDoom::Statenum::S_NULL.value,                                                  # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                                 # deathsound
      0,                                                                              # speed
      20 * FRACUNIT,                                                                  # radius
      52 * FRACUNIT,                                                                  # height
      100,                                                                            # mass
      0,                                                                              # damage
      CDoom::Sfxenum::SFX_None.value,                                                 # activesound
      (CDoom::Mobjflag::MF_SPAWNCEILING.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                  # raisestate
    },
    {                                                                                 # MT_MISC60
      63,                                                                             # doomednum
      CDoom::Statenum::S_BLOODYTWITCH.value,                                          # spawnstate
      1000,                                                                           # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                  # seestate
      CDoom::Sfxenum::SFX_None.value,                                                 # seesound
      8,                                                                              # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                 # attacksound
      CDoom::Statenum::S_NULL.value,                                                  # painstate
      0,                                                                              # painchance
      CDoom::Sfxenum::SFX_None.value,                                                 # painsound
      CDoom::Statenum::S_NULL.value,                                                  # meleestate
      CDoom::Statenum::S_NULL.value,                                                  # missilestate
      CDoom::Statenum::S_NULL.value,                                                  # deathstate
      CDoom::Statenum::S_NULL.value,                                                  # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                                 # deathsound
      0,                                                                              # speed
      20 * FRACUNIT,                                                                  # radius
      68 * FRACUNIT,                                                                  # height
      100,                                                                            # mass
      0,                                                                              # damage
      CDoom::Sfxenum::SFX_None.value,                                                 # activesound
      (CDoom::Mobjflag::MF_SPAWNCEILING.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                  # raisestate
    },
    {                                     # MT_MISC61
      22,                                 # doomednum
      CDoom::Statenum::S_HEAD_DIE6.value, # spawnstate
      1000,                               # spawnhealth
      CDoom::Statenum::S_NULL.value,      # seestate
      CDoom::Sfxenum::SFX_None.value,     # seesound
      8,                                  # reactiontime
      CDoom::Sfxenum::SFX_None.value,     # attacksound
      CDoom::Statenum::S_NULL.value,      # painstate
      0,                                  # painchance
      CDoom::Sfxenum::SFX_None.value,     # painsound
      CDoom::Statenum::S_NULL.value,      # meleestate
      CDoom::Statenum::S_NULL.value,      # missilestate
      CDoom::Statenum::S_NULL.value,      # deathstate
      CDoom::Statenum::S_NULL.value,      # xdeathstate
      CDoom::Sfxenum::SFX_None.value,     # deathsound
      0,                                  # speed
      20 * FRACUNIT,                      # radius
      16 * FRACUNIT,                      # height
      100,                                # mass
      0,                                  # damage
      CDoom::Sfxenum::SFX_None.value,     # activesound
      0,                                  # flags
      CDoom::Statenum::S_NULL.value,      # raisestate
    },
    {                                     # MT_MISC62
      15,                                 # doomednum
      CDoom::Statenum::S_PLAY_DIE7.value, # spawnstate
      1000,                               # spawnhealth
      CDoom::Statenum::S_NULL.value,      # seestate
      CDoom::Sfxenum::SFX_None.value,     # seesound
      8,                                  # reactiontime
      CDoom::Sfxenum::SFX_None.value,     # attacksound
      CDoom::Statenum::S_NULL.value,      # painstate
      0,                                  # painchance
      CDoom::Sfxenum::SFX_None.value,     # painsound
      CDoom::Statenum::S_NULL.value,      # meleestate
      CDoom::Statenum::S_NULL.value,      # missilestate
      CDoom::Statenum::S_NULL.value,      # deathstate
      CDoom::Statenum::S_NULL.value,      # xdeathstate
      CDoom::Sfxenum::SFX_None.value,     # deathsound
      0,                                  # speed
      20 * FRACUNIT,                      # radius
      16 * FRACUNIT,                      # height
      100,                                # mass
      0,                                  # damage
      CDoom::Sfxenum::SFX_None.value,     # activesound
      0,                                  # flags
      CDoom::Statenum::S_NULL.value,      # raisestate
    },
    {                                     # MT_MISC63
      18,                                 # doomednum
      CDoom::Statenum::S_POSS_DIE5.value, # spawnstate
      1000,                               # spawnhealth
      CDoom::Statenum::S_NULL.value,      # seestate
      CDoom::Sfxenum::SFX_None.value,     # seesound
      8,                                  # reactiontime
      CDoom::Sfxenum::SFX_None.value,     # attacksound
      CDoom::Statenum::S_NULL.value,      # painstate
      0,                                  # painchance
      CDoom::Sfxenum::SFX_None.value,     # painsound
      CDoom::Statenum::S_NULL.value,      # meleestate
      CDoom::Statenum::S_NULL.value,      # missilestate
      CDoom::Statenum::S_NULL.value,      # deathstate
      CDoom::Statenum::S_NULL.value,      # xdeathstate
      CDoom::Sfxenum::SFX_None.value,     # deathsound
      0,                                  # speed
      20 * FRACUNIT,                      # radius
      16 * FRACUNIT,                      # height
      100,                                # mass
      0,                                  # damage
      CDoom::Sfxenum::SFX_None.value,     # activesound
      0,                                  # flags
      CDoom::Statenum::S_NULL.value,      # raisestate
    },
    {                                     # MT_MISC64
      21,                                 # doomednum
      CDoom::Statenum::S_SARG_DIE6.value, # spawnstate
      1000,                               # spawnhealth
      CDoom::Statenum::S_NULL.value,      # seestate
      CDoom::Sfxenum::SFX_None.value,     # seesound
      8,                                  # reactiontime
      CDoom::Sfxenum::SFX_None.value,     # attacksound
      CDoom::Statenum::S_NULL.value,      # painstate
      0,                                  # painchance
      CDoom::Sfxenum::SFX_None.value,     # painsound
      CDoom::Statenum::S_NULL.value,      # meleestate
      CDoom::Statenum::S_NULL.value,      # missilestate
      CDoom::Statenum::S_NULL.value,      # deathstate
      CDoom::Statenum::S_NULL.value,      # xdeathstate
      CDoom::Sfxenum::SFX_None.value,     # deathsound
      0,                                  # speed
      20 * FRACUNIT,                      # radius
      16 * FRACUNIT,                      # height
      100,                                # mass
      0,                                  # damage
      CDoom::Sfxenum::SFX_None.value,     # activesound
      0,                                  # flags
      CDoom::Statenum::S_NULL.value,      # raisestate
    },
    {                                      # MT_MISC65
      23,                                  # doomednum
      CDoom::Statenum::S_SKULL_DIE6.value, # spawnstate
      1000,                                # spawnhealth
      CDoom::Statenum::S_NULL.value,       # seestate
      CDoom::Sfxenum::SFX_None.value,      # seesound
      8,                                   # reactiontime
      CDoom::Sfxenum::SFX_None.value,      # attacksound
      CDoom::Statenum::S_NULL.value,       # painstate
      0,                                   # painchance
      CDoom::Sfxenum::SFX_None.value,      # painsound
      CDoom::Statenum::S_NULL.value,       # meleestate
      CDoom::Statenum::S_NULL.value,       # missilestate
      CDoom::Statenum::S_NULL.value,       # deathstate
      CDoom::Statenum::S_NULL.value,       # xdeathstate
      CDoom::Sfxenum::SFX_None.value,      # deathsound
      0,                                   # speed
      20 * FRACUNIT,                       # radius
      16 * FRACUNIT,                       # height
      100,                                 # mass
      0,                                   # damage
      CDoom::Sfxenum::SFX_None.value,      # activesound
      0,                                   # flags
      CDoom::Statenum::S_NULL.value,       # raisestate
    },
    {                                     # MT_MISC66
      20,                                 # doomednum
      CDoom::Statenum::S_TROO_DIE5.value, # spawnstate
      1000,                               # spawnhealth
      CDoom::Statenum::S_NULL.value,      # seestate
      CDoom::Sfxenum::SFX_None.value,     # seesound
      8,                                  # reactiontime
      CDoom::Sfxenum::SFX_None.value,     # attacksound
      CDoom::Statenum::S_NULL.value,      # painstate
      0,                                  # painchance
      CDoom::Sfxenum::SFX_None.value,     # painsound
      CDoom::Statenum::S_NULL.value,      # meleestate
      CDoom::Statenum::S_NULL.value,      # missilestate
      CDoom::Statenum::S_NULL.value,      # deathstate
      CDoom::Statenum::S_NULL.value,      # xdeathstate
      CDoom::Sfxenum::SFX_None.value,     # deathsound
      0,                                  # speed
      20 * FRACUNIT,                      # radius
      16 * FRACUNIT,                      # height
      100,                                # mass
      0,                                  # damage
      CDoom::Sfxenum::SFX_None.value,     # activesound
      0,                                  # flags
      CDoom::Statenum::S_NULL.value,      # raisestate
    },
    {                                     # MT_MISC67
      19,                                 # doomednum
      CDoom::Statenum::S_SPOS_DIE5.value, # spawnstate
      1000,                               # spawnhealth
      CDoom::Statenum::S_NULL.value,      # seestate
      CDoom::Sfxenum::SFX_None.value,     # seesound
      8,                                  # reactiontime
      CDoom::Sfxenum::SFX_None.value,     # attacksound
      CDoom::Statenum::S_NULL.value,      # painstate
      0,                                  # painchance
      CDoom::Sfxenum::SFX_None.value,     # painsound
      CDoom::Statenum::S_NULL.value,      # meleestate
      CDoom::Statenum::S_NULL.value,      # missilestate
      CDoom::Statenum::S_NULL.value,      # deathstate
      CDoom::Statenum::S_NULL.value,      # xdeathstate
      CDoom::Sfxenum::SFX_None.value,     # deathsound
      0,                                  # speed
      20 * FRACUNIT,                      # radius
      16 * FRACUNIT,                      # height
      100,                                # mass
      0,                                  # damage
      CDoom::Sfxenum::SFX_None.value,     # activesound
      0,                                  # flags
      CDoom::Statenum::S_NULL.value,      # raisestate
    },
    {                                      # MT_MISC68
      10,                                  # doomednum
      CDoom::Statenum::S_PLAY_XDIE9.value, # spawnstate
      1000,                                # spawnhealth
      CDoom::Statenum::S_NULL.value,       # seestate
      CDoom::Sfxenum::SFX_None.value,      # seesound
      8,                                   # reactiontime
      CDoom::Sfxenum::SFX_None.value,      # attacksound
      CDoom::Statenum::S_NULL.value,       # painstate
      0,                                   # painchance
      CDoom::Sfxenum::SFX_None.value,      # painsound
      CDoom::Statenum::S_NULL.value,       # meleestate
      CDoom::Statenum::S_NULL.value,       # missilestate
      CDoom::Statenum::S_NULL.value,       # deathstate
      CDoom::Statenum::S_NULL.value,       # xdeathstate
      CDoom::Sfxenum::SFX_None.value,      # deathsound
      0,                                   # speed
      20 * FRACUNIT,                       # radius
      16 * FRACUNIT,                       # height
      100,                                 # mass
      0,                                   # damage
      CDoom::Sfxenum::SFX_None.value,      # activesound
      0,                                   # flags
      CDoom::Statenum::S_NULL.value,       # raisestate
    },
    {                                      # MT_MISC69
      12,                                  # doomednum
      CDoom::Statenum::S_PLAY_XDIE9.value, # spawnstate
      1000,                                # spawnhealth
      CDoom::Statenum::S_NULL.value,       # seestate
      CDoom::Sfxenum::SFX_None.value,      # seesound
      8,                                   # reactiontime
      CDoom::Sfxenum::SFX_None.value,      # attacksound
      CDoom::Statenum::S_NULL.value,       # painstate
      0,                                   # painchance
      CDoom::Sfxenum::SFX_None.value,      # painsound
      CDoom::Statenum::S_NULL.value,       # meleestate
      CDoom::Statenum::S_NULL.value,       # missilestate
      CDoom::Statenum::S_NULL.value,       # deathstate
      CDoom::Statenum::S_NULL.value,       # xdeathstate
      CDoom::Sfxenum::SFX_None.value,      # deathsound
      0,                                   # speed
      20 * FRACUNIT,                       # radius
      16 * FRACUNIT,                       # height
      100,                                 # mass
      0,                                   # damage
      CDoom::Sfxenum::SFX_None.value,      # activesound
      0,                                   # flags
      CDoom::Statenum::S_NULL.value,       # raisestate
    },
    {                                        # MT_MISC70
      28,                                    # doomednum
      CDoom::Statenum::S_HEADSONSTICK.value, # spawnstate
      1000,                                  # spawnhealth
      CDoom::Statenum::S_NULL.value,         # seestate
      CDoom::Sfxenum::SFX_None.value,        # seesound
      8,                                     # reactiontime
      CDoom::Sfxenum::SFX_None.value,        # attacksound
      CDoom::Statenum::S_NULL.value,         # painstate
      0,                                     # painchance
      CDoom::Sfxenum::SFX_None.value,        # painsound
      CDoom::Statenum::S_NULL.value,         # meleestate
      CDoom::Statenum::S_NULL.value,         # missilestate
      CDoom::Statenum::S_NULL.value,         # deathstate
      CDoom::Statenum::S_NULL.value,         # xdeathstate
      CDoom::Sfxenum::SFX_None.value,        # deathsound
      0,                                     # speed
      16 * FRACUNIT,                         # radius
      16 * FRACUNIT,                         # height
      100,                                   # mass
      0,                                     # damage
      CDoom::Sfxenum::SFX_None.value,        # activesound
      CDoom::Mobjflag::MF_SOLID.value,       # flags
      CDoom::Statenum::S_NULL.value,         # raisestate
    },
    {                                 # MT_MISC71
      24,                             # doomednum
      CDoom::Statenum::S_GIBS.value,  # spawnstate
      1000,                           # spawnhealth
      CDoom::Statenum::S_NULL.value,  # seestate
      CDoom::Sfxenum::SFX_None.value, # seesound
      8,                              # reactiontime
      CDoom::Sfxenum::SFX_None.value, # attacksound
      CDoom::Statenum::S_NULL.value,  # painstate
      0,                              # painchance
      CDoom::Sfxenum::SFX_None.value, # painsound
      CDoom::Statenum::S_NULL.value,  # meleestate
      CDoom::Statenum::S_NULL.value,  # missilestate
      CDoom::Statenum::S_NULL.value,  # deathstate
      CDoom::Statenum::S_NULL.value,  # xdeathstate
      CDoom::Sfxenum::SFX_None.value, # deathsound
      0,                              # speed
      20 * FRACUNIT,                  # radius
      16 * FRACUNIT,                  # height
      100,                            # mass
      0,                              # damage
      CDoom::Sfxenum::SFX_None.value, # activesound
      0,                              # flags
      CDoom::Statenum::S_NULL.value,  # raisestate
    },
    {                                        # MT_MISC72
      27,                                    # doomednum
      CDoom::Statenum::S_HEADONASTICK.value, # spawnstate
      1000,                                  # spawnhealth
      CDoom::Statenum::S_NULL.value,         # seestate
      CDoom::Sfxenum::SFX_None.value,        # seesound
      8,                                     # reactiontime
      CDoom::Sfxenum::SFX_None.value,        # attacksound
      CDoom::Statenum::S_NULL.value,         # painstate
      0,                                     # painchance
      CDoom::Sfxenum::SFX_None.value,        # painsound
      CDoom::Statenum::S_NULL.value,         # meleestate
      CDoom::Statenum::S_NULL.value,         # missilestate
      CDoom::Statenum::S_NULL.value,         # deathstate
      CDoom::Statenum::S_NULL.value,         # xdeathstate
      CDoom::Sfxenum::SFX_None.value,        # deathsound
      0,                                     # speed
      16 * FRACUNIT,                         # radius
      16 * FRACUNIT,                         # height
      100,                                   # mass
      0,                                     # damage
      CDoom::Sfxenum::SFX_None.value,        # activesound
      CDoom::Mobjflag::MF_SOLID.value,       # flags
      CDoom::Statenum::S_NULL.value,         # raisestate
    },
    {                                       # MT_MISC73
      29,                                   # doomednum
      CDoom::Statenum::S_HEADCANDLES.value, # spawnstate
      1000,                                 # spawnhealth
      CDoom::Statenum::S_NULL.value,        # seestate
      CDoom::Sfxenum::SFX_None.value,       # seesound
      8,                                    # reactiontime
      CDoom::Sfxenum::SFX_None.value,       # attacksound
      CDoom::Statenum::S_NULL.value,        # painstate
      0,                                    # painchance
      CDoom::Sfxenum::SFX_None.value,       # painsound
      CDoom::Statenum::S_NULL.value,        # meleestate
      CDoom::Statenum::S_NULL.value,        # missilestate
      CDoom::Statenum::S_NULL.value,        # deathstate
      CDoom::Statenum::S_NULL.value,        # xdeathstate
      CDoom::Sfxenum::SFX_None.value,       # deathsound
      0,                                    # speed
      16 * FRACUNIT,                        # radius
      16 * FRACUNIT,                        # height
      100,                                  # mass
      0,                                    # damage
      CDoom::Sfxenum::SFX_None.value,       # activesound
      CDoom::Mobjflag::MF_SOLID.value,      # flags
      CDoom::Statenum::S_NULL.value,        # raisestate
    },
    {                                     # MT_MISC74
      25,                                 # doomednum
      CDoom::Statenum::S_DEADSTICK.value, # spawnstate
      1000,                               # spawnhealth
      CDoom::Statenum::S_NULL.value,      # seestate
      CDoom::Sfxenum::SFX_None.value,     # seesound
      8,                                  # reactiontime
      CDoom::Sfxenum::SFX_None.value,     # attacksound
      CDoom::Statenum::S_NULL.value,      # painstate
      0,                                  # painchance
      CDoom::Sfxenum::SFX_None.value,     # painsound
      CDoom::Statenum::S_NULL.value,      # meleestate
      CDoom::Statenum::S_NULL.value,      # missilestate
      CDoom::Statenum::S_NULL.value,      # deathstate
      CDoom::Statenum::S_NULL.value,      # xdeathstate
      CDoom::Sfxenum::SFX_None.value,     # deathsound
      0,                                  # speed
      16 * FRACUNIT,                      # radius
      16 * FRACUNIT,                      # height
      100,                                # mass
      0,                                  # damage
      CDoom::Sfxenum::SFX_None.value,     # activesound
      CDoom::Mobjflag::MF_SOLID.value,    # flags
      CDoom::Statenum::S_NULL.value,      # raisestate
    },
    {                                     # MT_MISC75
      26,                                 # doomednum
      CDoom::Statenum::S_LIVESTICK.value, # spawnstate
      1000,                               # spawnhealth
      CDoom::Statenum::S_NULL.value,      # seestate
      CDoom::Sfxenum::SFX_None.value,     # seesound
      8,                                  # reactiontime
      CDoom::Sfxenum::SFX_None.value,     # attacksound
      CDoom::Statenum::S_NULL.value,      # painstate
      0,                                  # painchance
      CDoom::Sfxenum::SFX_None.value,     # painsound
      CDoom::Statenum::S_NULL.value,      # meleestate
      CDoom::Statenum::S_NULL.value,      # missilestate
      CDoom::Statenum::S_NULL.value,      # deathstate
      CDoom::Statenum::S_NULL.value,      # xdeathstate
      CDoom::Sfxenum::SFX_None.value,     # deathsound
      0,                                  # speed
      16 * FRACUNIT,                      # radius
      16 * FRACUNIT,                      # height
      100,                                # mass
      0,                                  # damage
      CDoom::Sfxenum::SFX_None.value,     # activesound
      CDoom::Mobjflag::MF_SOLID.value,    # flags
      CDoom::Statenum::S_NULL.value,      # raisestate
    },
    {                                   # MT_MISC76
      54,                               # doomednum
      CDoom::Statenum::S_BIGTREE.value, # spawnstate
      1000,                             # spawnhealth
      CDoom::Statenum::S_NULL.value,    # seestate
      CDoom::Sfxenum::SFX_None.value,   # seesound
      8,                                # reactiontime
      CDoom::Sfxenum::SFX_None.value,   # attacksound
      CDoom::Statenum::S_NULL.value,    # painstate
      0,                                # painchance
      CDoom::Sfxenum::SFX_None.value,   # painsound
      CDoom::Statenum::S_NULL.value,    # meleestate
      CDoom::Statenum::S_NULL.value,    # missilestate
      CDoom::Statenum::S_NULL.value,    # deathstate
      CDoom::Statenum::S_NULL.value,    # xdeathstate
      CDoom::Sfxenum::SFX_None.value,   # deathsound
      0,                                # speed
      32 * FRACUNIT,                    # radius
      16 * FRACUNIT,                    # height
      100,                              # mass
      0,                                # damage
      CDoom::Sfxenum::SFX_None.value,   # activesound
      CDoom::Mobjflag::MF_SOLID.value,  # flags
      CDoom::Statenum::S_NULL.value,    # raisestate
    },
    {                                  # MT_MISC77
      70,                              # doomednum
      CDoom::Statenum::S_BBAR1.value,  # spawnstate
      1000,                            # spawnhealth
      CDoom::Statenum::S_NULL.value,   # seestate
      CDoom::Sfxenum::SFX_None.value,  # seesound
      8,                               # reactiontime
      CDoom::Sfxenum::SFX_None.value,  # attacksound
      CDoom::Statenum::S_NULL.value,   # painstate
      0,                               # painchance
      CDoom::Sfxenum::SFX_None.value,  # painsound
      CDoom::Statenum::S_NULL.value,   # meleestate
      CDoom::Statenum::S_NULL.value,   # missilestate
      CDoom::Statenum::S_NULL.value,   # deathstate
      CDoom::Statenum::S_NULL.value,   # xdeathstate
      CDoom::Sfxenum::SFX_None.value,  # deathsound
      0,                               # speed
      16 * FRACUNIT,                   # radius
      16 * FRACUNIT,                   # height
      100,                             # mass
      0,                               # damage
      CDoom::Sfxenum::SFX_None.value,  # activesound
      CDoom::Mobjflag::MF_SOLID.value, # flags
      CDoom::Statenum::S_NULL.value,   # raisestate
    },
    {                                                                                                                   # MT_MISC78
      73,                                                                                                               # doomednum
      CDoom::Statenum::S_HANGNOGUTS.value,                                                                              # spawnstate
      1000,                                                                                                             # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                                                    # seestate
      CDoom::Sfxenum::SFX_None.value,                                                                                   # seesound
      8,                                                                                                                # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                                                   # attacksound
      CDoom::Statenum::S_NULL.value,                                                                                    # painstate
      0,                                                                                                                # painchance
      CDoom::Sfxenum::SFX_None.value,                                                                                   # painsound
      CDoom::Statenum::S_NULL.value,                                                                                    # meleestate
      CDoom::Statenum::S_NULL.value,                                                                                    # missilestate
      CDoom::Statenum::S_NULL.value,                                                                                    # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                    # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                                                                   # deathsound
      0,                                                                                                                # speed
      16 * FRACUNIT,                                                                                                    # radius
      88 * FRACUNIT,                                                                                                    # height
      100,                                                                                                              # mass
      0,                                                                                                                # damage
      CDoom::Sfxenum::SFX_None.value,                                                                                   # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SPAWNCEILING.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                    # raisestate
    },
    {                                                                                                                   # MT_MISC79
      74,                                                                                                               # doomednum
      CDoom::Statenum::S_HANGBNOBRAIN.value,                                                                            # spawnstate
      1000,                                                                                                             # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                                                    # seestate
      CDoom::Sfxenum::SFX_None.value,                                                                                   # seesound
      8,                                                                                                                # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                                                   # attacksound
      CDoom::Statenum::S_NULL.value,                                                                                    # painstate
      0,                                                                                                                # painchance
      CDoom::Sfxenum::SFX_None.value,                                                                                   # painsound
      CDoom::Statenum::S_NULL.value,                                                                                    # meleestate
      CDoom::Statenum::S_NULL.value,                                                                                    # missilestate
      CDoom::Statenum::S_NULL.value,                                                                                    # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                    # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                                                                   # deathsound
      0,                                                                                                                # speed
      16 * FRACUNIT,                                                                                                    # radius
      88 * FRACUNIT,                                                                                                    # height
      100,                                                                                                              # mass
      0,                                                                                                                # damage
      CDoom::Sfxenum::SFX_None.value,                                                                                   # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SPAWNCEILING.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                    # raisestate
    },
    {                                                                                                                   # MT_MISC80
      75,                                                                                                               # doomednum
      CDoom::Statenum::S_HANGTLOOKDN.value,                                                                             # spawnstate
      1000,                                                                                                             # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                                                    # seestate
      CDoom::Sfxenum::SFX_None.value,                                                                                   # seesound
      8,                                                                                                                # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                                                   # attacksound
      CDoom::Statenum::S_NULL.value,                                                                                    # painstate
      0,                                                                                                                # painchance
      CDoom::Sfxenum::SFX_None.value,                                                                                   # painsound
      CDoom::Statenum::S_NULL.value,                                                                                    # meleestate
      CDoom::Statenum::S_NULL.value,                                                                                    # missilestate
      CDoom::Statenum::S_NULL.value,                                                                                    # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                    # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                                                                   # deathsound
      0,                                                                                                                # speed
      16 * FRACUNIT,                                                                                                    # radius
      64 * FRACUNIT,                                                                                                    # height
      100,                                                                                                              # mass
      0,                                                                                                                # damage
      CDoom::Sfxenum::SFX_None.value,                                                                                   # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SPAWNCEILING.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                    # raisestate
    },
    {                                                                                                                   # MT_MISC81
      76,                                                                                                               # doomednum
      CDoom::Statenum::S_HANGTSKULL.value,                                                                              # spawnstate
      1000,                                                                                                             # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                                                    # seestate
      CDoom::Sfxenum::SFX_None.value,                                                                                   # seesound
      8,                                                                                                                # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                                                   # attacksound
      CDoom::Statenum::S_NULL.value,                                                                                    # painstate
      0,                                                                                                                # painchance
      CDoom::Sfxenum::SFX_None.value,                                                                                   # painsound
      CDoom::Statenum::S_NULL.value,                                                                                    # meleestate
      CDoom::Statenum::S_NULL.value,                                                                                    # missilestate
      CDoom::Statenum::S_NULL.value,                                                                                    # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                    # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                                                                   # deathsound
      0,                                                                                                                # speed
      16 * FRACUNIT,                                                                                                    # radius
      64 * FRACUNIT,                                                                                                    # height
      100,                                                                                                              # mass
      0,                                                                                                                # damage
      CDoom::Sfxenum::SFX_None.value,                                                                                   # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SPAWNCEILING.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                    # raisestate
    },
    {                                                                                                                   # MT_MISC82
      77,                                                                                                               # doomednum
      CDoom::Statenum::S_HANGTLOOKUP.value,                                                                             # spawnstate
      1000,                                                                                                             # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                                                    # seestate
      CDoom::Sfxenum::SFX_None.value,                                                                                   # seesound
      8,                                                                                                                # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                                                   # attacksound
      CDoom::Statenum::S_NULL.value,                                                                                    # painstate
      0,                                                                                                                # painchance
      CDoom::Sfxenum::SFX_None.value,                                                                                   # painsound
      CDoom::Statenum::S_NULL.value,                                                                                    # meleestate
      CDoom::Statenum::S_NULL.value,                                                                                    # missilestate
      CDoom::Statenum::S_NULL.value,                                                                                    # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                    # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                                                                   # deathsound
      0,                                                                                                                # speed
      16 * FRACUNIT,                                                                                                    # radius
      64 * FRACUNIT,                                                                                                    # height
      100,                                                                                                              # mass
      0,                                                                                                                # damage
      CDoom::Sfxenum::SFX_None.value,                                                                                   # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SPAWNCEILING.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                    # raisestate
    },
    {                                                                                                                   # MT_MISC83
      78,                                                                                                               # doomednum
      CDoom::Statenum::S_HANGTNOBRAIN.value,                                                                            # spawnstate
      1000,                                                                                                             # spawnhealth
      CDoom::Statenum::S_NULL.value,                                                                                    # seestate
      CDoom::Sfxenum::SFX_None.value,                                                                                   # seesound
      8,                                                                                                                # reactiontime
      CDoom::Sfxenum::SFX_None.value,                                                                                   # attacksound
      CDoom::Statenum::S_NULL.value,                                                                                    # painstate
      0,                                                                                                                # painchance
      CDoom::Sfxenum::SFX_None.value,                                                                                   # painsound
      CDoom::Statenum::S_NULL.value,                                                                                    # meleestate
      CDoom::Statenum::S_NULL.value,                                                                                    # missilestate
      CDoom::Statenum::S_NULL.value,                                                                                    # deathstate
      CDoom::Statenum::S_NULL.value,                                                                                    # xdeathstate
      CDoom::Sfxenum::SFX_None.value,                                                                                   # deathsound
      0,                                                                                                                # speed
      16 * FRACUNIT,                                                                                                    # radius
      64 * FRACUNIT,                                                                                                    # height
      100,                                                                                                              # mass
      0,                                                                                                                # damage
      CDoom::Sfxenum::SFX_None.value,                                                                                   # activesound
      (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SPAWNCEILING.value | CDoom::Mobjflag::MF_NOGRAVITY.value), # flags
      CDoom::Statenum::S_NULL.value,                                                                                    # raisestate
    },
    {                                       # MT_MISC84
      79,                                   # doomednum
      CDoom::Statenum::S_COLONGIBS.value,   # spawnstate
      1000,                                 # spawnhealth
      CDoom::Statenum::S_NULL.value,        # seestate
      CDoom::Sfxenum::SFX_None.value,       # seesound
      8,                                    # reactiontime
      CDoom::Sfxenum::SFX_None.value,       # attacksound
      CDoom::Statenum::S_NULL.value,        # painstate
      0,                                    # painchance
      CDoom::Sfxenum::SFX_None.value,       # painsound
      CDoom::Statenum::S_NULL.value,        # meleestate
      CDoom::Statenum::S_NULL.value,        # missilestate
      CDoom::Statenum::S_NULL.value,        # deathstate
      CDoom::Statenum::S_NULL.value,        # xdeathstate
      CDoom::Sfxenum::SFX_None.value,       # deathsound
      0,                                    # speed
      20 * FRACUNIT,                        # radius
      16 * FRACUNIT,                        # height
      100,                                  # mass
      0,                                    # damage
      CDoom::Sfxenum::SFX_None.value,       # activesound
      CDoom::Mobjflag::MF_NOBLOCKMAP.value, # flags
      CDoom::Statenum::S_NULL.value,        # raisestate
    },
    {                                       # MT_MISC85
      80,                                   # doomednum
      CDoom::Statenum::S_SMALLPOOL.value,   # spawnstate
      1000,                                 # spawnhealth
      CDoom::Statenum::S_NULL.value,        # seestate
      CDoom::Sfxenum::SFX_None.value,       # seesound
      8,                                    # reactiontime
      CDoom::Sfxenum::SFX_None.value,       # attacksound
      CDoom::Statenum::S_NULL.value,        # painstate
      0,                                    # painchance
      CDoom::Sfxenum::SFX_None.value,       # painsound
      CDoom::Statenum::S_NULL.value,        # meleestate
      CDoom::Statenum::S_NULL.value,        # missilestate
      CDoom::Statenum::S_NULL.value,        # deathstate
      CDoom::Statenum::S_NULL.value,        # xdeathstate
      CDoom::Sfxenum::SFX_None.value,       # deathsound
      0,                                    # speed
      20 * FRACUNIT,                        # radius
      16 * FRACUNIT,                        # height
      100,                                  # mass
      0,                                    # damage
      CDoom::Sfxenum::SFX_None.value,       # activesound
      CDoom::Mobjflag::MF_NOBLOCKMAP.value, # flags
      CDoom::Statenum::S_NULL.value,        # raisestate
    },
    {                                       # MT_MISC86
      81,                                   # doomednum
      CDoom::Statenum::S_BRAINSTEM.value,   # spawnstate
      1000,                                 # spawnhealth
      CDoom::Statenum::S_NULL.value,        # seestate
      CDoom::Sfxenum::SFX_None.value,       # seesound
      8,                                    # reactiontime
      CDoom::Sfxenum::SFX_None.value,       # attacksound
      CDoom::Statenum::S_NULL.value,        # painstate
      0,                                    # painchance
      CDoom::Sfxenum::SFX_None.value,       # painsound
      CDoom::Statenum::S_NULL.value,        # meleestate
      CDoom::Statenum::S_NULL.value,        # missilestate
      CDoom::Statenum::S_NULL.value,        # deathstate
      CDoom::Statenum::S_NULL.value,        # xdeathstate
      CDoom::Sfxenum::SFX_None.value,       # deathsound
      0,                                    # speed
      20 * FRACUNIT,                        # radius
      16 * FRACUNIT,                        # height
      100,                                  # mass
      0,                                    # damage
      CDoom::Sfxenum::SFX_None.value,       # activesound
      CDoom::Mobjflag::MF_NOBLOCKMAP.value, # flags
      CDoom::Statenum::S_NULL.value,        # raisestate
    },
  ]
  @@mobjinfo : Array(CDoom::Mobjinfo) = Array.new(CDoom::Mobjtype::NUMMOBJTYPES.value, CDoom::Mobjinfo.new)
  @@mobjinfo_data.each_with_index do |elm, i|
    (@@mobjinfo.to_unsafe + i).value.doomednum = elm[0]
    (@@mobjinfo.to_unsafe + i).value.spawnstate = elm[1]
    (@@mobjinfo.to_unsafe + i).value.spawnhealth = elm[2]
    (@@mobjinfo.to_unsafe + i).value.seestate = elm[3]
    (@@mobjinfo.to_unsafe + i).value.seesound = elm[4]
    (@@mobjinfo.to_unsafe + i).value.reactiontime = elm[5]
    (@@mobjinfo.to_unsafe + i).value.attacksound = elm[6]
    (@@mobjinfo.to_unsafe + i).value.painstate = elm[7]
    (@@mobjinfo.to_unsafe + i).value.painchance = elm[8]
    (@@mobjinfo.to_unsafe + i).value.painsound = elm[9]
    (@@mobjinfo.to_unsafe + i).value.meleestate = elm[10]
    (@@mobjinfo.to_unsafe + i).value.missilestate = elm[11]
    (@@mobjinfo.to_unsafe + i).value.deathstate = elm[12]
    (@@mobjinfo.to_unsafe + i).value.xdeathstate = elm[13]
    (@@mobjinfo.to_unsafe + i).value.deathsound = elm[14]
    (@@mobjinfo.to_unsafe + i).value.speed = elm[15]
    (@@mobjinfo.to_unsafe + i).value.radius = elm[16]
    (@@mobjinfo.to_unsafe + i).value.height = elm[17]
    (@@mobjinfo.to_unsafe + i).value.mass = elm[18]
    (@@mobjinfo.to_unsafe + i).value.damage = elm[19]
    (@@mobjinfo.to_unsafe + i).value.activesound = elm[20]
    (@@mobjinfo.to_unsafe + i).value.flags = elm[21]
    (@@mobjinfo.to_unsafe + i).value.raisestate = elm[22]
  end
  CDoom.mobjinfo = @@mobjinfo.to_unsafe

  c_array_strings(CDoom.gammamsg,
    CDoom::GAMMALVL0,
    CDoom::GAMMALVL1,
    CDoom::GAMMALVL2,
    CDoom::GAMMALVL3,
    CDoom::GAMMALVL4)

  c_array_strings(CDoom.skull_name,
    "M_SKULL1",
    "M_SKULL2")

  c_array_strings(CDoom.detail_names,
    "M_GDHIGH", "M_GDLOW")
  c_array_strings(CDoom.msg_names,
    "M_MSGOFF", "M_MSGON")

  c_array(CDoom.quitsounds,
    CDoom::Sfxenum::SFX_pldeth.value,
    CDoom::Sfxenum::SFX_dmpain.value,
    CDoom::Sfxenum::SFX_popain.value,
    CDoom::Sfxenum::SFX_slop.value,
    CDoom::Sfxenum::SFX_telept.value,
    CDoom::Sfxenum::SFX_posit1.value,
    CDoom::Sfxenum::SFX_posit3.value,
    CDoom::Sfxenum::SFX_sgtatk.value)

  c_array(CDoom.quitsounds2,
    CDoom::Sfxenum::SFX_vilact.value,
    CDoom::Sfxenum::SFX_getpow.value,
    CDoom::Sfxenum::SFX_boscub.value,
    CDoom::Sfxenum::SFX_slop.value,
    CDoom::Sfxenum::SFX_skeswg.value,
    CDoom::Sfxenum::SFX_kntdth.value,
    CDoom::Sfxenum::SFX_bspact.value,
    CDoom::Sfxenum::SFX_sgtatk.value)

  @@mainmenu = [
    CDoom::Menuitem.new(status: 1, name: "M_NGAME".to_unsafe, routine: ->CDoom.m_new_game(Int32), alpha_key: 'n'.ord),
    CDoom::Menuitem.new(status: 1, name: "M_OPTION".to_unsafe, routine: ->CDoom.m_options(Int32), alpha_key: 'o'.ord),
    CDoom::Menuitem.new(status: 1, name: "M_LOADG".to_unsafe, routine: ->CDoom.m_load_game(Int32), alpha_key: 'l'.ord),
    CDoom::Menuitem.new(status: 1, name: "M_SAVEG".to_unsafe, routine: ->CDoom.m_save_game(Int32), alpha_key: 's'.ord),
    # Another hickup with Special edition.
    CDoom::Menuitem.new(status: 1, name: "M_RDTHIS".to_unsafe, routine: ->CDoom.m_readthis(Int32), alpha_key: 'r'.ord),
    CDoom::Menuitem.new(status: 1, name: "M_QUITG".to_unsafe, routine: ->CDoom.m_quitdoom(Int32), alpha_key: 'q'.ord),
  ]

  @@maindef = CDoom::Menu.new(
    numitems: @@mainmenu.size,
    prev_menu: Pointer(CDoom::Menu).null,
    menuitems: @@mainmenu.to_unsafe,
    routine: ->CDoom.m_draw_mainmenu,
    x: 97, y: 64,
    last_on: 0)

  @@episodemenu = [
    CDoom::Menuitem.new(status: 1, name: "M_EPI1".to_unsafe, routine: ->CDoom.m_episode(Int32), alpha_key: 'k'.ord),
    CDoom::Menuitem.new(status: 1, name: "M_EPI2".to_unsafe, routine: ->CDoom.m_episode(Int32), alpha_key: 't'.ord),
    CDoom::Menuitem.new(status: 1, name: "M_EPI3".to_unsafe, routine: ->CDoom.m_episode(Int32), alpha_key: 'i'.ord),
    CDoom::Menuitem.new(status: 1, name: "M_EPI4".to_unsafe, routine: ->CDoom.m_episode(Int32), alpha_key: 't'.ord),
  ]

  @@epidef = CDoom::Menu.new(
    numitems: @@episodemenu.size,
    prev_menu: pointerof(@@maindef),
    menuitems: @@episodemenu.to_unsafe,
    routine: ->CDoom.m_draw_episode,
    x: 48, y: 63,
    last_on: CDoom::Episodesenum::Ep1.value
  )

  @@newgame_menu = [
    CDoom::Menuitem.new(status: 1, name: "M_JKILL".to_unsafe, routine: ->CDoom.m_choose_skill(Int32), alpha_key: 'i'.ord),
    CDoom::Menuitem.new(status: 1, name: "M_ROUGH".to_unsafe, routine: ->CDoom.m_choose_skill(Int32), alpha_key: 'h'.ord),
    CDoom::Menuitem.new(status: 1, name: "M_HURT".to_unsafe, routine: ->CDoom.m_choose_skill(Int32), alpha_key: 'h'.ord),
    CDoom::Menuitem.new(status: 1, name: "M_ULTRA".to_unsafe, routine: ->CDoom.m_choose_skill(Int32), alpha_key: 'u'.ord),
    CDoom::Menuitem.new(status: 1, name: "M_NMARE".to_unsafe, routine: ->CDoom.m_choose_skill(Int32), alpha_key: 'n'.ord),
  ]

  @@newdef = CDoom::Menu.new(
    numitems: @@newgame_menu.size,
    prev_menu: pointerof(@@epidef),
    menuitems: @@newgame_menu.to_unsafe,
    routine: ->CDoom.m_draw_newgame,
    x: 48, y: 63,
    last_on: CDoom::NewgameEnum::Hurtme.value
  )

  @@options_menu = [
    CDoom::Menuitem.new(status: 1, name: "M_ENDGAM".to_unsafe, routine: ->CDoom.m_endgame(Int32), alpha_key: 'e'.ord),
    CDoom::Menuitem.new(status: 1, name: "M_MESSG".to_unsafe, routine: ->CDoom.m_change_messages(Int32), alpha_key: 'm'.ord),
    CDoom::Menuitem.new(status: 2, name: "M_SCRNSZ".to_unsafe, routine: ->CDoom.m_size_display(Int32), alpha_key: 's'.ord),
    CDoom::Menuitem.new(status: -1, name: "".to_unsafe),
    CDoom::Menuitem.new(status: 2, name: "M_MSENS".to_unsafe, routine: ->CDoom.m_change_sensitivity(Int32), alpha_key: 'm'.ord),
    CDoom::Menuitem.new(status: -1, name: "".to_unsafe),
    CDoom::Menuitem.new(status: 1, name: "M_SVOL".to_unsafe, routine: ->CDoom.m_sound(Int32), alpha_key: 's'.ord),
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->m_moreoptions(Int32), alpha_key: 'm'.ord),
  ]

  @@optionsdef = CDoom::Menu.new(
    numitems: @@options_menu.size,
    prev_menu: pointerof(@@maindef),
    menuitems: @@options_menu.to_unsafe,
    routine: ->CDoom.m_draw_options,
    x: 60, y: 37,
    last_on: 0
  )

  @@current_options_menu = 0

  @@moreoptions_menus = [[
    CDoom::Menuitem.new(status: 2, text: "page ", num: pointerof(@@current_options_menu), routine: ->m_change_options_menu(Int32), alpha_key: 'e'.ord),
    CDoom::Menuitem.new(status: 1, text: "edit controls ->", routine: ->m_edit_controls(Int32), alpha_key: 'e'.ord),
    CDoom::Menuitem.new(status: 1, text: "toggle fullscreen", routine: ->m_toggle_fullscreen(Int32), alpha_key: 't'.ord),
    CDoom::Menuitem.new(status: 1, text: "always run: ", bool: pointerof(CDoom.always_run), routine: ->m_change_alwaysrun(Int32), alpha_key: 'a'.ord),
    CDoom::Menuitem.new(status: 1, text: "smooth midi panning: ", bool: pointerof(@@midismoothpan), routine: ->m_toggle_smoothpan(Int32), alpha_key: 's'.ord),
    CDoom::Menuitem.new(status: 2, text: "midi bank: ", num: pointerof(@@midibank), routine: ->m_change_midibank(Int32), alpha_key: 'm'.ord),
    CDoom::Menuitem.new(status: 1, text: "random audio pitch: ", bool: pointerof(@@randompitch), routine: ->m_toggle_pitching(Int32), alpha_key: 'r'.ord),
    CDoom::Menuitem.new(status: 1, text: "active automap drawing: ", bool: pointerof(@@amactivedraw), routine: ->m_toggle_amactivedraw(Int32), alpha_key: 'a'.ord),
  ],
                         [
                           CDoom::Menuitem.new(status: 2, text: "page ", num: pointerof(@@current_options_menu), routine: ->m_change_options_menu(Int32), alpha_key: 'e'.ord),
                           CDoom::Menuitem.new(status: 1, text: "Mouse Y movement: ", bool: pointerof(CDoom.mousemove), routine: ->m_mouse_move(Int32), alpha_key: 'm'.ord),
                           CDoom::Menuitem.new(status: 1, text: "Fire weapon centered: ", bool: pointerof(@@weaponfirecentered), routine: ->m_toggle_weaponfirecentered(Int32), alpha_key: 'f'.ord),
                           CDoom::Menuitem.new(status: 1, text: "crosshair: ", bool: pointerof(CDoom.crosshair), routine: ->m_change_crosshair(Int32), alpha_key: 'c'.ord),
                         ],
  ]

  @@moreoptions_def = CDoom::Menu.new(
    numitems: @@moreoptions_menus[0].size,
    prev_menu: pointerof(@@optionsdef),
    menuitems: @@moreoptions_menus.to_unsafe.value.to_unsafe,
    routine: ->m_draw_moreoptions,
    x: 70, y: 30,
    last_on: 0
  )

  @@editcontrols_menu = [
    CDoom::Menuitem.new(status: 1, text: "Forward =", num: pointerof(CDoom.key_up), routine: ->m_edit_forward(Int32), alpha_key: 'f'.ord),
    CDoom::Menuitem.new(status: 1, text: "Backward =", num: pointerof(CDoom.key_down), routine: ->m_edit_backward(Int32), alpha_key: 'b'.ord),
    CDoom::Menuitem.new(status: 1, text: "Strafe Left =", num: pointerof(CDoom.key_strafeleft), routine: ->m_edit_sleft(Int32), alpha_key: 's'.ord),
    CDoom::Menuitem.new(status: 1, text: "Strafe Right =", num: pointerof(CDoom.key_straferight), routine: ->m_edit_sright(Int32), alpha_key: 's'.ord),
    CDoom::Menuitem.new(status: 1, text: "Turn Left =", num: pointerof(CDoom.key_left), routine: ->m_edit_tleft(Int32), alpha_key: 't'.ord),
    CDoom::Menuitem.new(status: 1, text: "Turn Right =", num: pointerof(CDoom.key_right), routine: ->m_edit_tright(Int32), alpha_key: 't'.ord),
    CDoom::Menuitem.new(status: 1, text: "Sprint =", num: pointerof(CDoom.key_speed), routine: ->m_edit_sprint(Int32), alpha_key: 's'.ord),
    CDoom::Menuitem.new(status: 1, text: "Shoot =", num: pointerof(CDoom.key_fire), routine: ->m_edit_shoot(Int32), alpha_key: 's'.ord),
    CDoom::Menuitem.new(status: 1, text: "Use =", num: pointerof(CDoom.key_use), routine: ->m_edit_use(Int32), alpha_key: 'u'.ord),
  ]

  @@editcontrols_def = CDoom::Menu.new(
    numitems: @@editcontrols_menu.size,
    prev_menu: pointerof(@@moreoptions_def),
    menuitems: @@editcontrols_menu.to_unsafe,
    routine: ->m_draw_edit_controls,
    x: 70, y: 25,
    last_on: 0
  )

  @@readmenu1 = [
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_readthis2(Int32)),
  ]

  @@readdef1 = CDoom::Menu.new(
    numitems: @@readmenu1.size,
    prev_menu: pointerof(@@maindef),
    menuitems: @@readmenu1.to_unsafe,
    routine: ->CDoom.m_draw_readthis1,
    x: 280, y: 185,
    last_on: 0
  )

  @@readmenu2 = [
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_finish_readthis(Int32)),
  ]

  @@readdef2 = CDoom::Menu.new(
    numitems: @@readmenu2.size,
    prev_menu: pointerof(@@readdef1),
    menuitems: @@readmenu2.to_unsafe,
    routine: ->CDoom.m_draw_readthis2,
    x: 330, y: 175,
    last_on: 0
  )

  @@soundmenu = [
    CDoom::Menuitem.new(status: 2, name: "M_SFXVOL".to_unsafe, routine: ->CDoom.m_sfxvol(Int32), alpha_key: 's'.ord),
    CDoom::Menuitem.new(status: -1, name: "".to_unsafe),
    CDoom::Menuitem.new(status: 2, name: "M_MUSVOL".to_unsafe, routine: ->CDoom.m_musicvol(Int32), alpha_key: 'm'.ord),
    CDoom::Menuitem.new(status: -1, name: "".to_unsafe),
  ]

  @@sounddef = CDoom::Menu.new(
    numitems: @@soundmenu.size,
    prev_menu: pointerof(@@optionsdef),
    menuitems: @@soundmenu.to_unsafe,
    routine: ->CDoom.m_draw_sound,
    x: 80, y: 64,
    last_on: 0
  )

  @@loadmenu = [
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_load_select(Int32), alpha_key: '1'.ord),
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_load_select(Int32), alpha_key: '2'.ord),
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_load_select(Int32), alpha_key: '3'.ord),
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_load_select(Int32), alpha_key: '4'.ord),
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_load_select(Int32), alpha_key: '5'.ord),
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_load_select(Int32), alpha_key: '6'.ord),
  ]

  @@loaddef = CDoom::Menu.new(
    numitems: @@loadmenu.size,
    prev_menu: pointerof(@@maindef),
    menuitems: @@loadmenu.to_unsafe,
    routine: ->CDoom.m_draw_load,
    x: 80, y: 54,
    last_on: 0
  )

  @@savemenu = [
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_save_select(Int32), alpha_key: '1'.ord),
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_save_select(Int32), alpha_key: '2'.ord),
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_save_select(Int32), alpha_key: '3'.ord),
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_save_select(Int32), alpha_key: '4'.ord),
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_save_select(Int32), alpha_key: '5'.ord),
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_save_select(Int32), alpha_key: '6'.ord),
  ]

  @@savedef = CDoom::Menu.new(
    numitems: @@savemenu.size,
    prev_menu: pointerof(@@maindef),
    menuitems: @@savemenu.to_unsafe,
    routine: ->CDoom.m_draw_save,
    x: 80, y: 54,
    last_on: 0
  )

  @@rlfullscreen = 0
  @@midismoothpan = 1
  @@randompitch = 0
  @@amactivedraw = 1
  @@weaponfirecentered = 1
  @@midibank = 16

  @@defaults = [CDoom::Default.new(name: "mouse_sensitivity", location: pointerof(CDoom.mouse_sensitivity), defaultvalue: 5),
                CDoom::Default.new(name: "sfx_volume", location: pointerof(CDoom.snd_sfx_volume), defaultvalue: 8),
                CDoom::Default.new(name: "music_volume", location: pointerof(CDoom.snd_music_volume), defaultvalue: 8),
                CDoom::Default.new(name: "show_messages", location: pointerof(CDoom.show_messages), defaultvalue: 1),

                CDoom::Default.new(name: "key_right", location: pointerof(CDoom.key_right), defaultvalue: CDoom::KEY_RIGHTARROW),
                CDoom::Default.new(name: "key_left", location: pointerof(CDoom.key_left), defaultvalue: CDoom::KEY_LEFTARROW),
                CDoom::Default.new(name: "key_up", location: pointerof(CDoom.key_up), defaultvalue: CDoom::DoomKey::W),
                CDoom::Default.new(name: "key_down", location: pointerof(CDoom.key_down), defaultvalue: CDoom::DoomKey::S),
                CDoom::Default.new(name: "key_strafeleft", location: pointerof(CDoom.key_strafeleft), defaultvalue: CDoom::DoomKey::A),
                CDoom::Default.new(name: "key_straferight", location: pointerof(CDoom.key_straferight), defaultvalue: CDoom::DoomKey::D),

                CDoom::Default.new(name: "key_fire", location: pointerof(CDoom.key_fire), defaultvalue: CDoom::KEY_RCTRL),
                CDoom::Default.new(name: "key_use", location: pointerof(CDoom.key_use), defaultvalue: ' '.ord),
                CDoom::Default.new(name: "key_strafe", location: pointerof(CDoom.key_strafe), defaultvalue: CDoom::KEY_RALT),
                CDoom::Default.new(name: "key_speed", location: pointerof(CDoom.key_speed), defaultvalue: CDoom::KEY_RSHIFT),

                CDoom::Default.new(name: "use_mouse", location: pointerof(CDoom.usemouse), defaultvalue: 1),
                CDoom::Default.new(name: "mouseb_fire", location: pointerof(CDoom.mousebfire), defaultvalue: 0),
                CDoom::Default.new(name: "mouseb_strafe", location: pointerof(CDoom.mousebstrafe), defaultvalue: 1),
                CDoom::Default.new(name: "mouseb_forward", location: pointerof(CDoom.mousebforward), defaultvalue: 2),
                CDoom::Default.new(name: "mouse_move", location: pointerof(CDoom.mousemove), defaultvalue: 0),

                CDoom::Default.new(name: "use_joystick", location: pointerof(CDoom.usejoystick), defaultvalue: 0),
                CDoom::Default.new(name: "joyb_fire", location: pointerof(CDoom.joybfire), defaultvalue: 0),
                CDoom::Default.new(name: "joyb_strafe", location: pointerof(CDoom.joybstrafe), defaultvalue: 1),
                CDoom::Default.new(name: "joyb_use", location: pointerof(CDoom.joybuse), defaultvalue: 3),
                CDoom::Default.new(name: "joyb_speed", location: pointerof(CDoom.joybspeed), defaultvalue: 2),

                CDoom::Default.new(name: "screenblocks", location: pointerof(CDoom.screenblocks), defaultvalue: 9),
                CDoom::Default.new(name: "detaillevel", location: pointerof(CDoom.detail_level), defaultvalue: 0),
                CDoom::Default.new(name: "crosshair", location: pointerof(CDoom.crosshair), defaultvalue: 0),
                CDoom::Default.new(name: "always_run", location: pointerof(CDoom.always_run), defaultvalue: 0),

                CDoom::Default.new(name: "snd_channels", location: pointerof(CDoom.num_channels), defaultvalue: 16),

                CDoom::Default.new(name: "usegamma", location: pointerof(CDoom.usegamma), defaultvalue: 0),

                CDoom::Default.new(name: "chatmacro0", defaultvalue: CDoom::STRING_VALUE, text_location: CDoom.chat_macros.to_unsafe, default_text_value: CDoom::HUSTR_CHATMACRO0),
                CDoom::Default.new(name: "chatmacro1", defaultvalue: CDoom::STRING_VALUE, text_location: CDoom.chat_macros.to_unsafe + 1, default_text_value: CDoom::HUSTR_CHATMACRO1),
                CDoom::Default.new(name: "chatmacro2", defaultvalue: CDoom::STRING_VALUE, text_location: CDoom.chat_macros.to_unsafe + 2, default_text_value: CDoom::HUSTR_CHATMACRO2),
                CDoom::Default.new(name: "chatmacro3", defaultvalue: CDoom::STRING_VALUE, text_location: CDoom.chat_macros.to_unsafe + 3, default_text_value: CDoom::HUSTR_CHATMACRO3),
                CDoom::Default.new(name: "chatmacro4", defaultvalue: CDoom::STRING_VALUE, text_location: CDoom.chat_macros.to_unsafe + 4, default_text_value: CDoom::HUSTR_CHATMACRO4),
                CDoom::Default.new(name: "chatmacro5", defaultvalue: CDoom::STRING_VALUE, text_location: CDoom.chat_macros.to_unsafe + 5, default_text_value: CDoom::HUSTR_CHATMACRO5),
                CDoom::Default.new(name: "chatmacro6", defaultvalue: CDoom::STRING_VALUE, text_location: CDoom.chat_macros.to_unsafe + 6, default_text_value: CDoom::HUSTR_CHATMACRO6),
                CDoom::Default.new(name: "chatmacro7", defaultvalue: CDoom::STRING_VALUE, text_location: CDoom.chat_macros.to_unsafe + 7, default_text_value: CDoom::HUSTR_CHATMACRO7),
                CDoom::Default.new(name: "chatmacro8", defaultvalue: CDoom::STRING_VALUE, text_location: CDoom.chat_macros.to_unsafe + 8, default_text_value: CDoom::HUSTR_CHATMACRO8),
                CDoom::Default.new(name: "chatmacro9", defaultvalue: CDoom::STRING_VALUE, text_location: CDoom.chat_macros.to_unsafe + 9, default_text_value: CDoom::HUSTR_CHATMACRO9),
                CDoom::Default.new(name: "fullscreen", location: pointerof(@@rlfullscreen), defaultvalue: 0),
                CDoom::Default.new(name: "midismoothpan", location: pointerof(@@midismoothpan), defaultvalue: 1),
                CDoom::Default.new(name: "randompitching", location: pointerof(@@randompitch), defaultvalue: 0),
                CDoom::Default.new(name: "amactivedraw", location: pointerof(@@amactivedraw), defaultvalue: 1),
                CDoom::Default.new(name: "weaponfirecentered", location: pointerof(@@weaponfirecentered), defaultvalue: 1),
                CDoom::Default.new(name: "midibank", location: pointerof(@@midibank), defaultvalue: 16),
  ]

  c_array(CDoom.rndtable,
    0, 8, 109, 220, 222, 241, 149, 107, 75, 248, 254, 140, 16, 66,
    74, 21, 211, 47, 80, 242, 154, 27, 205, 128, 161, 89, 77, 36,
    95, 110, 85, 48, 212, 140, 211, 249, 22, 79, 200, 50, 28, 188,
    52, 140, 202, 120, 68, 145, 62, 70, 184, 190, 91, 197, 152, 224,
    149, 104, 25, 178, 252, 182, 202, 182, 141, 197, 4, 81, 181, 242,
    145, 42, 39, 227, 156, 198, 225, 193, 219, 93, 122, 175, 249, 0,
    175, 143, 70, 239, 46, 246, 163, 53, 163, 109, 168, 135, 2, 235,
    25, 92, 20, 145, 138, 77, 69, 166, 78, 176, 173, 212, 166, 113,
    94, 161, 41, 50, 239, 49, 111, 164, 70, 60, 2, 37, 171, 75,
    136, 156, 11, 56, 42, 146, 138, 229, 73, 146, 77, 61, 98, 196,
    135, 106, 63, 197, 195, 86, 96, 203, 113, 101, 170, 247, 181, 113,
    80, 250, 108, 7, 255, 237, 129, 226, 79, 107, 112, 166, 103, 241,
    24, 223, 239, 120, 198, 58, 60, 82, 128, 3, 184, 66, 143, 224,
    145, 224, 81, 206, 163, 45, 63, 90, 168, 114, 59, 33, 159, 95,
    28, 139, 123, 98, 125, 196, 15, 70, 194, 253, 54, 14, 109, 226,
    71, 17, 161, 93, 186, 87, 244, 138, 20, 52, 123, 251, 26, 36,
    17, 46, 52, 231, 232, 76, 31, 221, 84, 37, 216, 165, 212, 106,
    197, 242, 98, 43, 39, 175, 254, 145, 190, 84, 118, 222, 187, 136,
    120, 163, 236, 249
  )

  CDoom.rndindex = 0
  CDoom.prndindex = 0

  # a weapon is found with two clip loads,
  # a big item has five clip loads
  c_array(CDoom.maxammo, 200, 50, 300, 50)
  c_array(CDoom.clipammo, 10, 4, 20, 1)

  #
  # p_new_chase_dire related LUT.
  #
  c_array(CDoom.opposite,
    CDoom::Dirtype::West, CDoom::Dirtype::SouthWest, CDoom::Dirtype::South, CDoom::Dirtype::SouthEast,
    CDoom::Dirtype::East, CDoom::Dirtype::NorthEast, CDoom::Dirtype::North, CDoom::Dirtype::NorthWest, CDoom::Dirtype::NoDir)

  c_array(CDoom.diags,
    CDoom::Dirtype::NorthWest, CDoom::Dirtype::NorthEast, CDoom::Dirtype::SouthWest, CDoom::Dirtype::SouthEast)

  c_array(CDoom.xspeed, FRACUNIT, 47000, 0, -47000, -FRACUNIT, -47000, 0, 47000)
  c_array(CDoom.yspeed, 0, 47000, FRACUNIT, 47000, 0, -47000, -FRACUNIT, -47000)
  CDoom.traceangle = 0xc000000

  @@merge_files : Array(String) = [] of String

  # Floor/ceiling animation sequences,
  #  defined by first and last frame,
  #  i.e. the flat (64x64 tile) name to
  #  be used.
  # The full animation sequence is given
  #  using all the flats between the start
  #  and end entry, in the order found in
  #  the WAD file.
  @@animdef_data : Array(Tuple(CDoom::DoomBool, String, String, Int32)) = [
    {0, "NUKAGE3", "NUKAGE1", 8},
    {0, "FWATER4", "FWATER1", 8},
    {0, "SWATER4", "SWATER1", 8},
    {0, "LAVA4", "LAVA1", 8},
    {0, "BLOOD3", "BLOOD1", 8},

    # DOOM II flat animations.
    {0, "RROCK08", "RROCK05", 8},
    {0, "SLIME04", "SLIME01", 8},
    {0, "SLIME08", "SLIME05", 8},
    {0, "SLIME12", "SLIME09", 8},

    {1, "BLODGR4", "BLODGR1", 8},
    {1, "SLADRIP3", "SLADRIP1", 8},

    {1, "BLODRIP4", "BLODRIP1", 8},
    {1, "FIREWALL", "FIREWALA", 8},
    {1, "GSTFONT3", "GSTFONT1", 8},
    {1, "FIRELAVA", "FIRELAV3", 8},
    {1, "FIREMAG3", "FIREMAG1", 8},
    {1, "FIREBLU2", "FIREBLU1", 8},
    {1, "ROCKRED3", "ROCKRED1", 8},

    {1, "BFALL4", "BFALL1", 8},
    {1, "SFALL4", "SFALL1", 8},
    {1, "WFALL4", "WFALL1", 8},
    {1, "DBRAIN4", "DBRAIN1", 8},

    {-1, "", "", -1},
  ]
  @@animdefs : Array(CDoom::Animdef) = Array.new(@@animdef_data.size, CDoom::Animdef.new)
  @@animdef_data.each_with_index do |elm, i|
    (@@animdefs.to_unsafe + i).value.istexture = elm[0]
    (@@animdefs.to_unsafe + i).value.endname = elm[1].to_unsafe
    (@@animdefs.to_unsafe + i).value.startname = elm[2].to_unsafe
    (@@animdefs.to_unsafe + i).value.speed = elm[3]
  end
  CDoom.animdefs = @@animdefs.to_unsafe

  @@alph_switch_list_data : Array(Tuple(String, String, Int32)) = [
    # Doom shareware episode 1 switches
    {"SW1BRCOM", "SW2BRCOM", 1},
    {"SW1BRN1", "SW2BRN1", 1},
    {"SW1BRN2", "SW2BRN2", 1},
    {"SW1BRNGN", "SW2BRNGN", 1},
    {"SW1BROWN", "SW2BROWN", 1},
    {"SW1COMM", "SW2COMM", 1},
    {"SW1COMP", "SW2COMP", 1},
    {"SW1DIRT", "SW2DIRT", 1},
    {"SW1EXIT", "SW2EXIT", 1},
    {"SW1GRAY", "SW2GRAY", 1},
    {"SW1GRAY1", "SW2GRAY1", 1},
    {"SW1METAL", "SW2METAL", 1},
    {"SW1PIPE", "SW2PIPE", 1},
    {"SW1SLAD", "SW2SLAD", 1},
    {"SW1STARG", "SW2STARG", 1},
    {"SW1STON1", "SW2STON1", 1},
    {"SW1STON2", "SW2STON2", 1},
    {"SW1STONE", "SW2STONE", 1},
    {"SW1STRTN", "SW2STRTN", 1},

    # Doom registered episodes 2&3 switches
    {"SW1BLUE", "SW2BLUE", 2},
    {"SW1CMT", "SW2CMT", 2},
    {"SW1GARG", "SW2GARG", 2},
    {"SW1GSTON", "SW2GSTON", 2},
    {"SW1HOT", "SW2HOT", 2},
    {"SW1LION", "SW2LION", 2},
    {"SW1SATYR", "SW2SATYR", 2},
    {"SW1SKIN", "SW2SKIN", 2},
    {"SW1VINE", "SW2VINE", 2},
    {"SW1WOOD", "SW2WOOD", 2},

    # Doom II switches
    {"SW1PANEL", "SW2PANEL", 3},
    {"SW1ROCK", "SW2ROCK", 3},
    {"SW1MET2", "SW2MET2", 3},
    {"SW1WDMET", "SW2WDMET", 3},
    {"SW1BRIK", "SW2BRIK", 3},
    {"SW1MOD1", "SW2MOD1", 3},
    {"SW1ZIM", "SW2ZIM", 3},
    {"SW1STON6", "SW2STON6", 3},
    {"SW1TEK", "SW2TEK", 3},
    {"SW1MARB", "SW2MARB", 3},
    {"SW1SKULL", "SW2SKULL", 3},

    {"\0", "\0", 0},
  ]
  @@alph_switch_list : Array(CDoom::Switchlist) = Array.new(@@alph_switch_list_data.size, CDoom::Switchlist.new)
  @@alph_switch_list_data.each_with_index do |elm, i|
    (@@alph_switch_list.to_unsafe + i).value.name1 = elm[0].to_unsafe
    (@@alph_switch_list.to_unsafe + i).value.name2 = elm[1].to_unsafe
    (@@alph_switch_list.to_unsafe + i).value.episode = elm[2]
  end
  CDoom.alph_switch_list = @@alph_switch_list.to_unsafe

  c_array((CDoom.checkcoord.to_unsafe).value, 3, 0, 2, 1)
  c_array((CDoom.checkcoord.to_unsafe + 1).value, 3, 0, 2, 0)
  c_array((CDoom.checkcoord.to_unsafe + 2).value, 3, 1, 2, 0)
  c_array((CDoom.checkcoord.to_unsafe + 3).value, 0, 0, 0, 0)
  c_array((CDoom.checkcoord.to_unsafe + 4).value, 2, 0, 2, 1)
  c_array((CDoom.checkcoord.to_unsafe + 5).value, 0, 0, 0, 0)
  c_array((CDoom.checkcoord.to_unsafe + 6).value, 3, 1, 3, 0)
  c_array((CDoom.checkcoord.to_unsafe + 7).value, 0, 0, 0, 0)
  c_array((CDoom.checkcoord.to_unsafe + 8).value, 2, 0, 3, 1)
  c_array((CDoom.checkcoord.to_unsafe + 9).value, 2, 1, 3, 1)
  c_array((CDoom.checkcoord.to_unsafe + 10).value, 2, 1, 3, 0)
  c_array((CDoom.checkcoord.to_unsafe + 11).value, 0, 0, 0, 0)

  c_array(CDoom.fuzzoffset,
    CDoom::FUZZOFF, -CDoom::FUZZOFF, CDoom::FUZZOFF, -CDoom::FUZZOFF, CDoom::FUZZOFF, CDoom::FUZZOFF, -CDoom::FUZZOFF,
    CDoom::FUZZOFF, CDoom::FUZZOFF, -CDoom::FUZZOFF, CDoom::FUZZOFF, CDoom::FUZZOFF, CDoom::FUZZOFF, -CDoom::FUZZOFF,
    CDoom::FUZZOFF, CDoom::FUZZOFF, CDoom::FUZZOFF, -CDoom::FUZZOFF, -CDoom::FUZZOFF, -CDoom::FUZZOFF, -CDoom::FUZZOFF,
    CDoom::FUZZOFF, -CDoom::FUZZOFF, -CDoom::FUZZOFF, CDoom::FUZZOFF, CDoom::FUZZOFF, CDoom::FUZZOFF, CDoom::FUZZOFF, -CDoom::FUZZOFF,
    CDoom::FUZZOFF, -CDoom::FUZZOFF, CDoom::FUZZOFF, CDoom::FUZZOFF, -CDoom::FUZZOFF, -CDoom::FUZZOFF, CDoom::FUZZOFF,
    CDoom::FUZZOFF, -CDoom::FUZZOFF, -CDoom::FUZZOFF, -CDoom::FUZZOFF, -CDoom::FUZZOFF, CDoom::FUZZOFF, CDoom::FUZZOFF,
    CDoom::FUZZOFF, CDoom::FUZZOFF, -CDoom::FUZZOFF, CDoom::FUZZOFF, CDoom::FUZZOFF, -CDoom::FUZZOFF, CDoom::FUZZOFF
  )

  CDoom.fuzzpos = 0

  CDoom.validcount = 1

  CDoom.mus_playing_s_sound = Pointer(CDoom::Musicinfo).null

  CDoom.snd_sfx_volume = 15

  CDoom.snd_music_volume = 15

  @@s_music_data : Array(Tuple(String, Int32)) = [
    {"\0", 0},
    {"e1m1", 0},
    {"e1m2", 0},
    {"e1m3", 0},
    {"e1m4", 0},
    {"e1m5", 0},
    {"e1m6", 0},
    {"e1m7", 0},
    {"e1m8", 0},
    {"e1m9", 0},
    {"e2m1", 0},
    {"e2m2", 0},
    {"e2m3", 0},
    {"e2m4", 0},
    {"e2m5", 0},
    {"e2m6", 0},
    {"e2m7", 0},
    {"e2m8", 0},
    {"e2m9", 0},
    {"e3m1", 0},
    {"e3m2", 0},
    {"e3m3", 0},
    {"e3m4", 0},
    {"e3m5", 0},
    {"e3m6", 0},
    {"e3m7", 0},
    {"e3m8", 0},
    {"e3m9", 0},
    {"inter", 0},
    {"intro", 0},
    {"bunny", 0},
    {"victor", 0},
    {"introa", 0},
    {"runnin", 0},
    {"stalks", 0},
    {"countd", 0},
    {"betwee", 0},
    {"doom", 0},
    {"the_da", 0},
    {"shawn", 0},
    {"ddtblu", 0},
    {"in_cit", 0},
    {"dead", 0},
    {"stlks2", 0},
    {"theda2", 0},
    {"doom2", 0},
    {"ddtbl2", 0},
    {"runni2", 0},
    {"dead2", 0},
    {"stlks3", 0},
    {"romero", 0},
    {"shawn2", 0},
    {"messag", 0},
    {"count2", 0},
    {"ddtbl3", 0},
    {"ampie", 0},
    {"theda3", 0},
    {"adrian", 0},
    {"messg2", 0},
    {"romer2", 0},
    {"tense", 0},
    {"shawn3", 0},
    {"openin", 0},
    {"evil", 0},
    {"ultima", 0},
    {"read_m", 0},
    {"dm2ttl", 0},
    {"dm2int", 0},
  ]
  @@s_music : Array(CDoom::Musicinfo) = Array(CDoom::Musicinfo).new(68, CDoom::Musicinfo.new)
  @@s_music_data.each_with_index do |elm, i|
    (@@s_music.to_unsafe + i).value.name = elm[0].to_unsafe
    (@@s_music.to_unsafe + i).value.lumpnum = elm[1]
  end
  CDoom.s_music = @@s_music.to_unsafe

  @@s_sfx_data : Array(Tuple(String, Bool, Int32, Pointer(CDoom::Sfxinfo), Int32, Int32, Int32)) = [
    # S_sfx[0] needs to be a dummy for odd reasons.
    {"none", false, 0, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"pistol", false, 64, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"shotgn", false, 64, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"sgcock", false, 64, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"dshtgn", false, 64, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"dbopn", false, 64, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"dbcls", false, 64, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"dbload", false, 64, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"plasma", false, 64, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"bfg", false, 64, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"sawup", false, 64, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"sawidl", false, 118, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"sawful", false, 64, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"sawhit", false, 64, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"rlaunc", false, 64, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"rxplod", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"firsht", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"firxpl", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"pstart", false, 100, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"pstop", false, 100, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"doropn", false, 100, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"dorcls", false, 100, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"stnmov", false, 119, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"swtchn", false, 78, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"swtchx", false, 78, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"plpain", false, 96, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"dmpain", false, 96, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"popain", false, 96, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"vipain", false, 96, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"mnpain", false, 96, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"pepain", false, 96, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"slop", false, 78, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"itemup", true, 78, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"wpnup", true, 78, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"oof", false, 96, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"telept", false, 32, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"posit1", true, 98, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"posit2", true, 98, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"posit3", true, 98, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"bgsit1", true, 98, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"bgsit2", true, 98, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"sgtsit", true, 98, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"cacsit", true, 98, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"brssit", true, 94, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"cybsit", true, 92, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"spisit", true, 90, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"bspsit", true, 90, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"kntsit", true, 90, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"vilsit", true, 90, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"mansit", true, 90, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"pesit", true, 90, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"sklatk", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"sgtatk", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"skepch", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"vilatk", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"claw", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"skeswg", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"pldeth", false, 32, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"pdiehi", false, 32, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"podth1", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"podth2", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"podth3", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"bgdth1", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"bgdth2", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"sgtdth", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"cacdth", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"skldth", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"brsdth", false, 32, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"cybdth", false, 32, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"spidth", false, 32, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"bspdth", false, 32, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"vildth", false, 32, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"kntdth", false, 32, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"pedth", false, 32, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"skedth", false, 32, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"posact", true, 120, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"bgact", true, 120, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"dmact", true, 120, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"bspact", true, 100, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"bspwlk", true, 100, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"vilact", true, 100, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"noway", false, 78, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"barexp", false, 60, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"punch", false, 64, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"hoof", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"metal", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"chgun", false, 64, @@s_sfx.to_unsafe + CDoom::Sfxenum::SFX_pistol.value, 150, 0, 0},
    {"tink", false, 60, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"bdopn", false, 100, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"bdcls", false, 100, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"itmbk", false, 100, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"flame", false, 32, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"flamst", false, 32, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"getpow", false, 60, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"bospit", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"boscub", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"bossit", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"bospn", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"bosdth", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"manatk", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"mandth", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"sssit", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"ssdth", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"keenpn", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"keendt", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"skeact", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"skesit", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"skeatk", false, 70, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
    {"radio", false, 60, Pointer(CDoom::Sfxinfo).null, -1, -1, 0},
  ]
  @@s_sfx : Array(CDoom::Sfxinfo) = Array(CDoom::Sfxinfo).new(109, CDoom::Sfxinfo.new)
  @@s_sfx_data.each_with_index do |elm, i|
    (@@s_sfx.to_unsafe + i).value.name = elm[0].to_unsafe
    (@@s_sfx.to_unsafe + i).value.singularity = elm[1].to_unsafe
    (@@s_sfx.to_unsafe + i).value.priority = elm[2]
    (@@s_sfx.to_unsafe + i).value.link = elm[3]
    (@@s_sfx.to_unsafe + i).value.pitch = elm[4]
    (@@s_sfx.to_unsafe + i).value.volume = elm[5]
    (@@s_sfx.to_unsafe + i).value.data = Pointer(Void).new(elm[6].to_u64!)
  end
  CDoom.s_sfx = @@s_sfx.to_unsafe

  CDoom.veryfirsttime = 1
  CDoom.st_msgcounter = 0
  CDoom.st_oldhealth = -1
  CDoom.st_facecount = 0
  CDoom.st_faceindex = 0
  CDoom.st_palette = 0
  CDoom.st_stopped = 1

  c_array(CDoom.cheat_mus_seq,
    0xb2, 0x26, 0xb6, 0xae, 0xea, 1, 0, 0, 0xff
  )

  c_array(CDoom.cheat_choppers_seq,
    0xb2, 0x26, 0xe2, 0x32, 0xf6, 0x2a, 0x2a, 0xa6, 0x6a, 0xea, 0xff # id...
  )

  c_array(CDoom.cheat_god_seq,
    0xb2, 0x26, 0x26, 0xaa, 0x26, 0xff # iddqd
  )

  c_array(CDoom.cheat_ammo_seq,
    0xb2, 0x26, 0xf2, 0x66, 0xa2, 0xff # idkfa
  )

  c_array(CDoom.cheat_ammonokey_seq,
    0xb2, 0x26, 0x66, 0xa2, 0xff # idfa
  )

  c_array(CDoom.cheat_noclip_seq,
    0xb2, 0x26, 0xea, 0x2a, 0xb2, # idspispopd
    0xea, 0x2a, 0xf6, 0x2a, 0x26, 0xff
  )

  c_array(CDoom.cheat_commercial_noclip_seq,
    0xb2, 0x26, 0xe2, 0x36, 0xb2, 0x2a, 0xff # idclip
  )

  c_array(CDoom.cheat_powerup_seq.to_unsafe.value,
    0xb2, 0x26, 0x62, 0xa6, 0x32, 0xf6, 0x36, 0x26, 0x6e, 0xff # beholdv
  )
  c_array((CDoom.cheat_powerup_seq.to_unsafe + 1).value,
    0xb2, 0x26, 0x62, 0xa6, 0x32, 0xf6, 0x36, 0x26, 0xea, 0xff # beholds
  )
  c_array((CDoom.cheat_powerup_seq.to_unsafe + 2).value,
    0xb2, 0x26, 0x62, 0xa6, 0x32, 0xf6, 0x36, 0x26, 0xb2, 0xff # beholdi
  )
  c_array((CDoom.cheat_powerup_seq.to_unsafe + 3).value,
    0xb2, 0x26, 0x62, 0xa6, 0x32, 0xf6, 0x36, 0x26, 0x6a, 0xff # beholdr
  )
  c_array((CDoom.cheat_powerup_seq.to_unsafe + 4).value,
    0xb2, 0x26, 0x62, 0xa6, 0x32, 0xf6, 0x36, 0x26, 0xa2, 0xff # beholda
  )
  c_array((CDoom.cheat_powerup_seq.to_unsafe + 5).value,
    0xb2, 0x26, 0x62, 0xa6, 0x32, 0xf6, 0x36, 0x26, 0x36, 0xff # beholdl
  )
  c_array((CDoom.cheat_powerup_seq.to_unsafe + 6).value,
    0xb2, 0x26, 0x62, 0xa6, 0x32, 0xf6, 0x36, 0x26, 0xff # behold
  )

  c_array(CDoom.cheat_clev_seq,
    0xb2, 0x26, 0xe2, 0x36, 0xa6, 0x6e, 1, 0, 0, 0xff # idclev
  )

  c_array(CDoom.cheat_mypos_seq,
    0xb2, 0x26, 0xb6, 0xba, 0x2a, 0xf6, 0xea, 0xff # idmypos
  )

  @@cheat_me_seq = [0x26, 0xA2, 0xEA, 0x32, 0xEE, 0xA2, 0xE6, 0xFF] of UInt8

  CDoom.cheat_mus.sequence = CDoom.cheat_mus_seq.to_unsafe
  CDoom.cheat_mus.p = Pointer(UInt8).null
  CDoom.cheat_god.sequence = CDoom.cheat_god_seq.to_unsafe
  CDoom.cheat_god.p = Pointer(UInt8).null
  CDoom.cheat_ammo.sequence = CDoom.cheat_ammo_seq.to_unsafe
  CDoom.cheat_ammo.p = Pointer(UInt8).null
  CDoom.cheat_ammonokey.sequence = CDoom.cheat_ammonokey_seq.to_unsafe
  CDoom.cheat_ammonokey.p = Pointer(UInt8).null
  CDoom.cheat_noclip.sequence = CDoom.cheat_noclip_seq.to_unsafe
  CDoom.cheat_noclip.p = Pointer(UInt8).null
  CDoom.cheat_commercial_noclip.sequence = CDoom.cheat_commercial_noclip_seq.to_unsafe
  CDoom.cheat_commercial_noclip.p = Pointer(UInt8).null
  @@cheat_me = CDoom::Cheatseq.new(sequence: @@cheat_me_seq.to_unsafe, p: Pointer(UInt8).null)

  c_array_cheat(CDoom.cheat_powerup,
    {CDoom.cheat_powerup_seq[0].to_unsafe, Pointer(UInt8).null},
    {CDoom.cheat_powerup_seq[1].to_unsafe, Pointer(UInt8).null},
    {CDoom.cheat_powerup_seq[2].to_unsafe, Pointer(UInt8).null},
    {CDoom.cheat_powerup_seq[3].to_unsafe, Pointer(UInt8).null},
    {CDoom.cheat_powerup_seq[4].to_unsafe, Pointer(UInt8).null},
    {CDoom.cheat_powerup_seq[5].to_unsafe, Pointer(UInt8).null},
    {CDoom.cheat_powerup_seq[6].to_unsafe, Pointer(UInt8).null}
  )

  CDoom.cheat_choppers.sequence = CDoom.cheat_choppers_seq.to_unsafe
  CDoom.cheat_choppers.p = Pointer(UInt8).null
  CDoom.cheat_clev.sequence = CDoom.cheat_clev_seq.to_unsafe
  CDoom.cheat_clev.p = Pointer(UInt8).null
  CDoom.cheat_mypos.sequence = CDoom.cheat_mypos_seq.to_unsafe
  CDoom.cheat_mypos.p = Pointer(UInt8).null

  {% if flag?("PRECOMPUTED") %}
    @@finetangent = [
      -170910304, -56965752, -34178904, -24413316, -18988036, -15535599, -13145455, -11392683,
      -10052327, -8994149, -8137527, -7429880, -6835455, -6329090, -5892567, -5512368,
      -5178251, -4882318, -4618375, -4381502, -4167737, -3973855, -3797206, -3635590,
      -3487165, -3350381, -3223918, -3106651, -2997613, -2895966, -2800983, -2712030,
      -2628549, -2550052, -2476104, -2406322, -2340362, -2277919, -2218719, -2162516,
      -2109087, -2058233, -2009771, -1963536, -1919378, -1877161, -1836758, -1798063,
      -1760956, -1725348, -1691149, -1658278, -1626658, -1596220, -1566898, -1538632,
      -1511367, -1485049, -1459630, -1435065, -1411312, -1388330, -1366084, -1344537,
      -1323658, -1303416, -1283783, -1264730, -1246234, -1228269, -1210813, -1193846,
      -1177345, -1161294, -1145673, -1130465, -1115654, -1101225, -1087164, -1073455,
      -1060087, -1047046, -1034322, -1021901, -1009774, -997931, -986361, -975054,
      -964003, -953199, -942633, -932298, -922186, -912289, -902602, -893117,
      -883829, -874730, -865817, -857081, -848520, -840127, -831898, -823827,
      -815910, -808143, -800521, -793041, -785699, -778490, -771411, -764460,
      -757631, -750922, -744331, -737853, -731486, -725227, -719074, -713023,
      -707072, -701219, -695462, -689797, -684223, -678737, -673338, -668024,
      -662792, -657640, -652568, -647572, -642651, -637803, -633028, -628323,
      -623686, -619117, -614613, -610174, -605798, -601483, -597229, -593033,
      -588896, -584815, -580789, -576818, -572901, -569035, -565221, -561456,
      -557741, -554074, -550455, -546881, -543354, -539870, -536431, -533034,
      -529680, -526366, -523094, -519861, -516667, -513512, -510394, -507313,
      -504269, -501261, -498287, -495348, -492443, -489571, -486732, -483925,
      -481150, -478406, -475692, -473009, -470355, -467730, -465133, -462565,
      -460024, -457511, -455024, -452564, -450129, -447720, -445337, -442978,
      -440643, -438332, -436045, -433781, -431540, -429321, -427125, -424951,
      -422798, -420666, -418555, -416465, -414395, -412344, -410314, -408303,
      -406311, -404338, -402384, -400448, -398530, -396630, -394747, -392882,
      -391034, -389202, -387387, -385589, -383807, -382040, -380290, -378555,
      -376835, -375130, -373440, -371765, -370105, -368459, -366826, -365208,
      -363604, -362013, -360436, -358872, -357321, -355783, -354257, -352744,
      -351244, -349756, -348280, -346816, -345364, -343924, -342495, -341078,
      -339671, -338276, -336892, -335519, -334157, -332805, -331464, -330133,
      -328812, -327502, -326201, -324910, -323629, -322358, -321097, -319844,
      -318601, -317368, -316143, -314928, -313721, -312524, -311335, -310154,
      -308983, -307819, -306664, -305517, -304379, -303248, -302126, -301011,
      -299904, -298805, -297714, -296630, -295554, -294485, -293423, -292369,
      -291322, -290282, -289249, -288223, -287204, -286192, -285186, -284188,
      -283195, -282210, -281231, -280258, -279292, -278332, -277378, -276430,
      -275489, -274553, -273624, -272700, -271782, -270871, -269965, -269064,
      -268169, -267280, -266397, -265519, -264646, -263779, -262917, -262060,
      -261209, -260363, -259522, -258686, -257855, -257029, -256208, -255392,
      -254581, -253774, -252973, -252176, -251384, -250596, -249813, -249035,
      -248261, -247492, -246727, -245966, -245210, -244458, -243711, -242967,
      -242228, -241493, -240763, -240036, -239314, -238595, -237881, -237170,
      -236463, -235761, -235062, -234367, -233676, -232988, -232304, -231624,
      -230948, -230275, -229606, -228941, -228279, -227621, -226966, -226314,
      -225666, -225022, -224381, -223743, -223108, -222477, -221849, -221225,
      -220603, -219985, -219370, -218758, -218149, -217544, -216941, -216341,
      -215745, -215151, -214561, -213973, -213389, -212807, -212228, -211652,
      -211079, -210509, -209941, -209376, -208815, -208255, -207699, -207145,
      -206594, -206045, -205500, -204956, -204416, -203878, -203342, -202809,
      -202279, -201751, -201226, -200703, -200182, -199664, -199149, -198636,
      -198125, -197616, -197110, -196606, -196105, -195606, -195109, -194614,
      -194122, -193631, -193143, -192658, -192174, -191693, -191213, -190736,
      -190261, -189789, -189318, -188849, -188382, -187918, -187455, -186995,
      -186536, -186080, -185625, -185173, -184722, -184274, -183827, -183382,
      -182939, -182498, -182059, -181622, -181186, -180753, -180321, -179891,
      -179463, -179037, -178612, -178190, -177769, -177349, -176932, -176516,
      -176102, -175690, -175279, -174870, -174463, -174057, -173653, -173251,
      -172850, -172451, -172053, -171657, -171263, -170870, -170479, -170089,
      -169701, -169315, -168930, -168546, -168164, -167784, -167405, -167027,
      -166651, -166277, -165904, -165532, -165162, -164793, -164426, -164060,
      -163695, -163332, -162970, -162610, -162251, -161893, -161537, -161182,
      -160828, -160476, -160125, -159775, -159427, -159079, -158734, -158389,
      -158046, -157704, -157363, -157024, -156686, -156349, -156013, -155678,
      -155345, -155013, -154682, -154352, -154024, -153697, -153370, -153045,
      -152722, -152399, -152077, -151757, -151438, -151120, -150803, -150487,
      -150172, -149859, -149546, -149235, -148924, -148615, -148307, -148000,
      -147693, -147388, -147084, -146782, -146480, -146179, -145879, -145580,
      -145282, -144986, -144690, -144395, -144101, -143808, -143517, -143226,
      -142936, -142647, -142359, -142072, -141786, -141501, -141217, -140934,
      -140651, -140370, -140090, -139810, -139532, -139254, -138977, -138701,
      -138426, -138152, -137879, -137607, -137335, -137065, -136795, -136526,
      -136258, -135991, -135725, -135459, -135195, -134931, -134668, -134406,
      -134145, -133884, -133625, -133366, -133108, -132851, -132594, -132339,
      -132084, -131830, -131576, -131324, -131072, -130821, -130571, -130322,
      -130073, -129825, -129578, -129332, -129086, -128841, -128597, -128353,
      -128111, -127869, -127627, -127387, -127147, -126908, -126669, -126432,
      -126195, -125959, -125723, -125488, -125254, -125020, -124787, -124555,
      -124324, -124093, -123863, -123633, -123404, -123176, -122949, -122722,
      -122496, -122270, -122045, -121821, -121597, -121374, -121152, -120930,
      -120709, -120489, -120269, -120050, -119831, -119613, -119396, -119179,
      -118963, -118747, -118532, -118318, -118104, -117891, -117678, -117466,
      -117254, -117044, -116833, -116623, -116414, -116206, -115998, -115790,
      -115583, -115377, -115171, -114966, -114761, -114557, -114354, -114151,
      -113948, -113746, -113545, -113344, -113143, -112944, -112744, -112546,
      -112347, -112150, -111952, -111756, -111560, -111364, -111169, -110974,
      -110780, -110586, -110393, -110200, -110008, -109817, -109626, -109435,
      -109245, -109055, -108866, -108677, -108489, -108301, -108114, -107927,
      -107741, -107555, -107369, -107184, -107000, -106816, -106632, -106449,
      -106266, -106084, -105902, -105721, -105540, -105360, -105180, -105000,
      -104821, -104643, -104465, -104287, -104109, -103933, -103756, -103580,
      -103404, -103229, -103054, -102880, -102706, -102533, -102360, -102187,
      -102015, -101843, -101671, -101500, -101330, -101159, -100990, -100820,
      -100651, -100482, -100314, -100146, -99979, -99812, -99645, -99479,
      -99313, -99148, -98982, -98818, -98653, -98489, -98326, -98163,
      -98000, -97837, -97675, -97513, -97352, -97191, -97030, -96870,
      -96710, -96551, -96391, -96233, -96074, -95916, -95758, -95601,
      -95444, -95287, -95131, -94975, -94819, -94664, -94509, -94354,
      -94200, -94046, -93892, -93739, -93586, -93434, -93281, -93129,
      -92978, -92826, -92675, -92525, -92375, -92225, -92075, -91926,
      -91777, -91628, -91480, -91332, -91184, -91036, -90889, -90742,
      -90596, -90450, -90304, -90158, -90013, -89868, -89724, -89579,
      -89435, -89292, -89148, -89005, -88862, -88720, -88577, -88435,
      -88294, -88152, -88011, -87871, -87730, -87590, -87450, -87310,
      -87171, -87032, -86893, -86755, -86616, -86479, -86341, -86204,
      -86066, -85930, -85793, -85657, -85521, -85385, -85250, -85114,
      -84980, -84845, -84710, -84576, -84443, -84309, -84176, -84043,
      -83910, -83777, -83645, -83513, -83381, -83250, -83118, -82987,
      -82857, -82726, -82596, -82466, -82336, -82207, -82078, -81949,
      -81820, -81691, -81563, -81435, -81307, -81180, -81053, -80925,
      -80799, -80672, -80546, -80420, -80294, -80168, -80043, -79918,
      -79793, -79668, -79544, -79420, -79296, -79172, -79048, -78925,
      -78802, -78679, -78557, -78434, -78312, -78190, -78068, -77947,
      -77826, -77705, -77584, -77463, -77343, -77223, -77103, -76983,
      -76864, -76744, -76625, -76506, -76388, -76269, -76151, -76033,
      -75915, -75797, -75680, -75563, -75446, -75329, -75213, -75096,
      -74980, -74864, -74748, -74633, -74517, -74402, -74287, -74172,
      -74058, -73944, -73829, -73715, -73602, -73488, -73375, -73262,
      -73149, -73036, -72923, -72811, -72699, -72587, -72475, -72363,
      -72252, -72140, -72029, -71918, -71808, -71697, -71587, -71477,
      -71367, -71257, -71147, -71038, -70929, -70820, -70711, -70602,
      -70494, -70385, -70277, -70169, -70061, -69954, -69846, -69739,
      -69632, -69525, -69418, -69312, -69205, -69099, -68993, -68887,
      -68781, -68676, -68570, -68465, -68360, -68255, -68151, -68046,
      -67942, -67837, -67733, -67629, -67526, -67422, -67319, -67216,
      -67113, -67010, -66907, -66804, -66702, -66600, -66498, -66396,
      -66294, -66192, -66091, -65989, -65888, -65787, -65686, -65586,
      -65485, -65385, -65285, -65185, -65085, -64985, -64885, -64786,
      -64687, -64587, -64488, -64389, -64291, -64192, -64094, -63996,
      -63897, -63799, -63702, -63604, -63506, -63409, -63312, -63215,
      -63118, -63021, -62924, -62828, -62731, -62635, -62539, -62443,
      -62347, -62251, -62156, -62060, -61965, -61870, -61775, -61680,
      -61585, -61491, -61396, -61302, -61208, -61114, -61020, -60926,
      -60833, -60739, -60646, -60552, -60459, -60366, -60273, -60181,
      -60088, -59996, -59903, -59811, -59719, -59627, -59535, -59444,
      -59352, -59261, -59169, -59078, -58987, -58896, -58805, -58715,
      -58624, -58534, -58443, -58353, -58263, -58173, -58083, -57994,
      -57904, -57815, -57725, -57636, -57547, -57458, -57369, -57281,
      -57192, -57104, -57015, -56927, -56839, -56751, -56663, -56575,
      -56487, -56400, -56312, -56225, -56138, -56051, -55964, -55877,
      -55790, -55704, -55617, -55531, -55444, -55358, -55272, -55186,
      -55100, -55015, -54929, -54843, -54758, -54673, -54587, -54502,
      -54417, -54333, -54248, -54163, -54079, -53994, -53910, -53826,
      -53741, -53657, -53574, -53490, -53406, -53322, -53239, -53156,
      -53072, -52989, -52906, -52823, -52740, -52657, -52575, -52492,
      -52410, -52327, -52245, -52163, -52081, -51999, -51917, -51835,
      -51754, -51672, -51591, -51509, -51428, -51347, -51266, -51185,
      -51104, -51023, -50942, -50862, -50781, -50701, -50621, -50540,
      -50460, -50380, -50300, -50221, -50141, -50061, -49982, -49902,
      -49823, -49744, -49664, -49585, -49506, -49427, -49349, -49270,
      -49191, -49113, -49034, -48956, -48878, -48799, -48721, -48643,
      -48565, -48488, -48410, -48332, -48255, -48177, -48100, -48022,
      -47945, -47868, -47791, -47714, -47637, -47560, -47484, -47407,
      -47331, -47254, -47178, -47102, -47025, -46949, -46873, -46797,
      -46721, -46646, -46570, -46494, -46419, -46343, -46268, -46193,
      -46118, -46042, -45967, -45892, -45818, -45743, -45668, -45593,
      -45519, -45444, -45370, -45296, -45221, -45147, -45073, -44999,
      -44925, -44851, -44778, -44704, -44630, -44557, -44483, -44410,
      -44337, -44263, -44190, -44117, -44044, -43971, -43898, -43826,
      -43753, -43680, -43608, -43535, -43463, -43390, -43318, -43246,
      -43174, -43102, -43030, -42958, -42886, -42814, -42743, -42671,
      -42600, -42528, -42457, -42385, -42314, -42243, -42172, -42101,
      -42030, -41959, -41888, -41817, -41747, -41676, -41605, -41535,
      -41465, -41394, -41324, -41254, -41184, -41113, -41043, -40973,
      -40904, -40834, -40764, -40694, -40625, -40555, -40486, -40416,
      -40347, -40278, -40208, -40139, -40070, -40001, -39932, -39863,
      -39794, -39726, -39657, -39588, -39520, -39451, -39383, -39314,
      -39246, -39178, -39110, -39042, -38973, -38905, -38837, -38770,
      -38702, -38634, -38566, -38499, -38431, -38364, -38296, -38229,
      -38161, -38094, -38027, -37960, -37893, -37826, -37759, -37692,
      -37625, -37558, -37491, -37425, -37358, -37291, -37225, -37158,
      -37092, -37026, -36959, -36893, -36827, -36761, -36695, -36629,
      -36563, -36497, -36431, -36365, -36300, -36234, -36168, -36103,
      -36037, -35972, -35907, -35841, -35776, -35711, -35646, -35580,
      -35515, -35450, -35385, -35321, -35256, -35191, -35126, -35062,
      -34997, -34932, -34868, -34803, -34739, -34675, -34610, -34546,
      -34482, -34418, -34354, -34289, -34225, -34162, -34098, -34034,
      -33970, -33906, -33843, -33779, -33715, -33652, -33588, -33525,
      -33461, -33398, -33335, -33272, -33208, -33145, -33082, -33019,
      -32956, -32893, -32830, -32767, -32705, -32642, -32579, -32516,
      -32454, -32391, -32329, -32266, -32204, -32141, -32079, -32017,
      -31955, -31892, -31830, -31768, -31706, -31644, -31582, -31520,
      -31458, -31396, -31335, -31273, -31211, -31150, -31088, -31026,
      -30965, -30904, -30842, -30781, -30719, -30658, -30597, -30536,
      -30474, -30413, -30352, -30291, -30230, -30169, -30108, -30048,
      -29987, -29926, -29865, -29805, -29744, -29683, -29623, -29562,
      -29502, -29441, -29381, -29321, -29260, -29200, -29140, -29080,
      -29020, -28959, -28899, -28839, -28779, -28719, -28660, -28600,
      -28540, -28480, -28420, -28361, -28301, -28241, -28182, -28122,
      -28063, -28003, -27944, -27884, -27825, -27766, -27707, -27647,
      -27588, -27529, -27470, -27411, -27352, -27293, -27234, -27175,
      -27116, -27057, -26998, -26940, -26881, -26822, -26763, -26705,
      -26646, -26588, -26529, -26471, -26412, -26354, -26295, -26237,
      -26179, -26120, -26062, -26004, -25946, -25888, -25830, -25772,
      -25714, -25656, -25598, -25540, -25482, -25424, -25366, -25308,
      -25251, -25193, -25135, -25078, -25020, -24962, -24905, -24847,
      -24790, -24732, -24675, -24618, -24560, -24503, -24446, -24389,
      -24331, -24274, -24217, -24160, -24103, -24046, -23989, -23932,
      -23875, -23818, -23761, -23704, -23647, -23591, -23534, -23477,
      -23420, -23364, -23307, -23250, -23194, -23137, -23081, -23024,
      -22968, -22911, -22855, -22799, -22742, -22686, -22630, -22573,
      -22517, -22461, -22405, -22349, -22293, -22237, -22181, -22125,
      -22069, -22013, -21957, -21901, -21845, -21789, -21733, -21678,
      -21622, -21566, -21510, -21455, -21399, -21343, -21288, -21232,
      -21177, -21121, -21066, -21010, -20955, -20900, -20844, -20789,
      -20734, -20678, -20623, -20568, -20513, -20457, -20402, -20347,
      -20292, -20237, -20182, -20127, -20072, -20017, -19962, -19907,
      -19852, -19797, -19742, -19688, -19633, -19578, -19523, -19469,
      -19414, -19359, -19305, -19250, -19195, -19141, -19086, -19032,
      -18977, -18923, -18868, -18814, -18760, -18705, -18651, -18597,
      -18542, -18488, -18434, -18380, -18325, -18271, -18217, -18163,
      -18109, -18055, -18001, -17946, -17892, -17838, -17784, -17731,
      -17677, -17623, -17569, -17515, -17461, -17407, -17353, -17300,
      -17246, -17192, -17138, -17085, -17031, -16977, -16924, -16870,
      -16817, -16763, -16710, -16656, -16603, -16549, -16496, -16442,
      -16389, -16335, -16282, -16229, -16175, -16122, -16069, -16015,
      -15962, -15909, -15856, -15802, -15749, -15696, -15643, -15590,
      -15537, -15484, -15431, -15378, -15325, -15272, -15219, -15166,
      -15113, -15060, -15007, -14954, -14901, -14848, -14795, -14743,
      -14690, -14637, -14584, -14531, -14479, -14426, -14373, -14321,
      -14268, -14215, -14163, -14110, -14057, -14005, -13952, -13900,
      -13847, -13795, -13742, -13690, -13637, -13585, -13533, -13480,
      -13428, -13375, -13323, -13271, -13218, -13166, -13114, -13062,
      -13009, -12957, -12905, -12853, -12800, -12748, -12696, -12644,
      -12592, -12540, -12488, -12436, -12383, -12331, -12279, -12227,
      -12175, -12123, -12071, -12019, -11967, -11916, -11864, -11812,
      -11760, -11708, -11656, -11604, -11552, -11501, -11449, -11397,
      -11345, -11293, -11242, -11190, -11138, -11086, -11035, -10983,
      -10931, -10880, -10828, -10777, -10725, -10673, -10622, -10570,
      -10519, -10467, -10415, -10364, -10312, -10261, -10209, -10158,
      -10106, -10055, -10004, -9952, -9901, -9849, -9798, -9747,
      -9695, -9644, -9592, -9541, -9490, -9438, -9387, -9336,
      -9285, -9233, -9182, -9131, -9080, -9028, -8977, -8926,
      -8875, -8824, -8772, -8721, -8670, -8619, -8568, -8517,
      -8466, -8414, -8363, -8312, -8261, -8210, -8159, -8108,
      -8057, -8006, -7955, -7904, -7853, -7802, -7751, -7700,
      -7649, -7598, -7547, -7496, -7445, -7395, -7344, -7293,
      -7242, -7191, -7140, -7089, -7038, -6988, -6937, -6886,
      -6835, -6784, -6733, -6683, -6632, -6581, -6530, -6480,
      -6429, -6378, -6327, -6277, -6226, -6175, -6124, -6074,
      -6023, -5972, -5922, -5871, -5820, -5770, -5719, -5668,
      -5618, -5567, -5517, -5466, -5415, -5365, -5314, -5264,
      -5213, -5162, -5112, -5061, -5011, -4960, -4910, -4859,
      -4808, -4758, -4707, -4657, -4606, -4556, -4505, -4455,
      -4404, -4354, -4303, -4253, -4202, -4152, -4101, -4051,
      -4001, -3950, -3900, -3849, -3799, -3748, -3698, -3648,
      -3597, -3547, -3496, -3446, -3395, -3345, -3295, -3244,
      -3194, -3144, -3093, -3043, -2992, -2942, -2892, -2841,
      -2791, -2741, -2690, -2640, -2590, -2539, -2489, -2439,
      -2388, -2338, -2288, -2237, -2187, -2137, -2086, -2036,
      -1986, -1935, -1885, -1835, -1784, -1734, -1684, -1633,
      -1583, -1533, -1483, -1432, -1382, -1332, -1281, -1231,
      -1181, -1131, -1080, -1030, -980, -929, -879, -829,
      -779, -728, -678, -628, -578, -527, -477, -427,
      -376, -326, -276, -226, -175, -125, -75, -25,
      25, 75, 125, 175, 226, 276, 326, 376,
      427, 477, 527, 578, 628, 678, 728, 779,
      829, 879, 929, 980, 1030, 1080, 1131, 1181,
      1231, 1281, 1332, 1382, 1432, 1483, 1533, 1583,
      1633, 1684, 1734, 1784, 1835, 1885, 1935, 1986,
      2036, 2086, 2137, 2187, 2237, 2288, 2338, 2388,
      2439, 2489, 2539, 2590, 2640, 2690, 2741, 2791,
      2841, 2892, 2942, 2992, 3043, 3093, 3144, 3194,
      3244, 3295, 3345, 3395, 3446, 3496, 3547, 3597,
      3648, 3698, 3748, 3799, 3849, 3900, 3950, 4001,
      4051, 4101, 4152, 4202, 4253, 4303, 4354, 4404,
      4455, 4505, 4556, 4606, 4657, 4707, 4758, 4808,
      4859, 4910, 4960, 5011, 5061, 5112, 5162, 5213,
      5264, 5314, 5365, 5415, 5466, 5517, 5567, 5618,
      5668, 5719, 5770, 5820, 5871, 5922, 5972, 6023,
      6074, 6124, 6175, 6226, 6277, 6327, 6378, 6429,
      6480, 6530, 6581, 6632, 6683, 6733, 6784, 6835,
      6886, 6937, 6988, 7038, 7089, 7140, 7191, 7242,
      7293, 7344, 7395, 7445, 7496, 7547, 7598, 7649,
      7700, 7751, 7802, 7853, 7904, 7955, 8006, 8057,
      8108, 8159, 8210, 8261, 8312, 8363, 8414, 8466,
      8517, 8568, 8619, 8670, 8721, 8772, 8824, 8875,
      8926, 8977, 9028, 9080, 9131, 9182, 9233, 9285,
      9336, 9387, 9438, 9490, 9541, 9592, 9644, 9695,
      9747, 9798, 9849, 9901, 9952, 10004, 10055, 10106,
      10158, 10209, 10261, 10312, 10364, 10415, 10467, 10519,
      10570, 10622, 10673, 10725, 10777, 10828, 10880, 10931,
      10983, 11035, 11086, 11138, 11190, 11242, 11293, 11345,
      11397, 11449, 11501, 11552, 11604, 11656, 11708, 11760,
      11812, 11864, 11916, 11967, 12019, 12071, 12123, 12175,
      12227, 12279, 12331, 12383, 12436, 12488, 12540, 12592,
      12644, 12696, 12748, 12800, 12853, 12905, 12957, 13009,
      13062, 13114, 13166, 13218, 13271, 13323, 13375, 13428,
      13480, 13533, 13585, 13637, 13690, 13742, 13795, 13847,
      13900, 13952, 14005, 14057, 14110, 14163, 14215, 14268,
      14321, 14373, 14426, 14479, 14531, 14584, 14637, 14690,
      14743, 14795, 14848, 14901, 14954, 15007, 15060, 15113,
      15166, 15219, 15272, 15325, 15378, 15431, 15484, 15537,
      15590, 15643, 15696, 15749, 15802, 15856, 15909, 15962,
      16015, 16069, 16122, 16175, 16229, 16282, 16335, 16389,
      16442, 16496, 16549, 16603, 16656, 16710, 16763, 16817,
      16870, 16924, 16977, 17031, 17085, 17138, 17192, 17246,
      17300, 17353, 17407, 17461, 17515, 17569, 17623, 17677,
      17731, 17784, 17838, 17892, 17946, 18001, 18055, 18109,
      18163, 18217, 18271, 18325, 18380, 18434, 18488, 18542,
      18597, 18651, 18705, 18760, 18814, 18868, 18923, 18977,
      19032, 19086, 19141, 19195, 19250, 19305, 19359, 19414,
      19469, 19523, 19578, 19633, 19688, 19742, 19797, 19852,
      19907, 19962, 20017, 20072, 20127, 20182, 20237, 20292,
      20347, 20402, 20457, 20513, 20568, 20623, 20678, 20734,
      20789, 20844, 20900, 20955, 21010, 21066, 21121, 21177,
      21232, 21288, 21343, 21399, 21455, 21510, 21566, 21622,
      21678, 21733, 21789, 21845, 21901, 21957, 22013, 22069,
      22125, 22181, 22237, 22293, 22349, 22405, 22461, 22517,
      22573, 22630, 22686, 22742, 22799, 22855, 22911, 22968,
      23024, 23081, 23137, 23194, 23250, 23307, 23364, 23420,
      23477, 23534, 23591, 23647, 23704, 23761, 23818, 23875,
      23932, 23989, 24046, 24103, 24160, 24217, 24274, 24331,
      24389, 24446, 24503, 24560, 24618, 24675, 24732, 24790,
      24847, 24905, 24962, 25020, 25078, 25135, 25193, 25251,
      25308, 25366, 25424, 25482, 25540, 25598, 25656, 25714,
      25772, 25830, 25888, 25946, 26004, 26062, 26120, 26179,
      26237, 26295, 26354, 26412, 26471, 26529, 26588, 26646,
      26705, 26763, 26822, 26881, 26940, 26998, 27057, 27116,
      27175, 27234, 27293, 27352, 27411, 27470, 27529, 27588,
      27647, 27707, 27766, 27825, 27884, 27944, 28003, 28063,
      28122, 28182, 28241, 28301, 28361, 28420, 28480, 28540,
      28600, 28660, 28719, 28779, 28839, 28899, 28959, 29020,
      29080, 29140, 29200, 29260, 29321, 29381, 29441, 29502,
      29562, 29623, 29683, 29744, 29805, 29865, 29926, 29987,
      30048, 30108, 30169, 30230, 30291, 30352, 30413, 30474,
      30536, 30597, 30658, 30719, 30781, 30842, 30904, 30965,
      31026, 31088, 31150, 31211, 31273, 31335, 31396, 31458,
      31520, 31582, 31644, 31706, 31768, 31830, 31892, 31955,
      32017, 32079, 32141, 32204, 32266, 32329, 32391, 32454,
      32516, 32579, 32642, 32705, 32767, 32830, 32893, 32956,
      33019, 33082, 33145, 33208, 33272, 33335, 33398, 33461,
      33525, 33588, 33652, 33715, 33779, 33843, 33906, 33970,
      34034, 34098, 34162, 34225, 34289, 34354, 34418, 34482,
      34546, 34610, 34675, 34739, 34803, 34868, 34932, 34997,
      35062, 35126, 35191, 35256, 35321, 35385, 35450, 35515,
      35580, 35646, 35711, 35776, 35841, 35907, 35972, 36037,
      36103, 36168, 36234, 36300, 36365, 36431, 36497, 36563,
      36629, 36695, 36761, 36827, 36893, 36959, 37026, 37092,
      37158, 37225, 37291, 37358, 37425, 37491, 37558, 37625,
      37692, 37759, 37826, 37893, 37960, 38027, 38094, 38161,
      38229, 38296, 38364, 38431, 38499, 38566, 38634, 38702,
      38770, 38837, 38905, 38973, 39042, 39110, 39178, 39246,
      39314, 39383, 39451, 39520, 39588, 39657, 39726, 39794,
      39863, 39932, 40001, 40070, 40139, 40208, 40278, 40347,
      40416, 40486, 40555, 40625, 40694, 40764, 40834, 40904,
      40973, 41043, 41113, 41184, 41254, 41324, 41394, 41465,
      41535, 41605, 41676, 41747, 41817, 41888, 41959, 42030,
      42101, 42172, 42243, 42314, 42385, 42457, 42528, 42600,
      42671, 42743, 42814, 42886, 42958, 43030, 43102, 43174,
      43246, 43318, 43390, 43463, 43535, 43608, 43680, 43753,
      43826, 43898, 43971, 44044, 44117, 44190, 44263, 44337,
      44410, 44483, 44557, 44630, 44704, 44778, 44851, 44925,
      44999, 45073, 45147, 45221, 45296, 45370, 45444, 45519,
      45593, 45668, 45743, 45818, 45892, 45967, 46042, 46118,
      46193, 46268, 46343, 46419, 46494, 46570, 46646, 46721,
      46797, 46873, 46949, 47025, 47102, 47178, 47254, 47331,
      47407, 47484, 47560, 47637, 47714, 47791, 47868, 47945,
      48022, 48100, 48177, 48255, 48332, 48410, 48488, 48565,
      48643, 48721, 48799, 48878, 48956, 49034, 49113, 49191,
      49270, 49349, 49427, 49506, 49585, 49664, 49744, 49823,
      49902, 49982, 50061, 50141, 50221, 50300, 50380, 50460,
      50540, 50621, 50701, 50781, 50862, 50942, 51023, 51104,
      51185, 51266, 51347, 51428, 51509, 51591, 51672, 51754,
      51835, 51917, 51999, 52081, 52163, 52245, 52327, 52410,
      52492, 52575, 52657, 52740, 52823, 52906, 52989, 53072,
      53156, 53239, 53322, 53406, 53490, 53574, 53657, 53741,
      53826, 53910, 53994, 54079, 54163, 54248, 54333, 54417,
      54502, 54587, 54673, 54758, 54843, 54929, 55015, 55100,
      55186, 55272, 55358, 55444, 55531, 55617, 55704, 55790,
      55877, 55964, 56051, 56138, 56225, 56312, 56400, 56487,
      56575, 56663, 56751, 56839, 56927, 57015, 57104, 57192,
      57281, 57369, 57458, 57547, 57636, 57725, 57815, 57904,
      57994, 58083, 58173, 58263, 58353, 58443, 58534, 58624,
      58715, 58805, 58896, 58987, 59078, 59169, 59261, 59352,
      59444, 59535, 59627, 59719, 59811, 59903, 59996, 60088,
      60181, 60273, 60366, 60459, 60552, 60646, 60739, 60833,
      60926, 61020, 61114, 61208, 61302, 61396, 61491, 61585,
      61680, 61775, 61870, 61965, 62060, 62156, 62251, 62347,
      62443, 62539, 62635, 62731, 62828, 62924, 63021, 63118,
      63215, 63312, 63409, 63506, 63604, 63702, 63799, 63897,
      63996, 64094, 64192, 64291, 64389, 64488, 64587, 64687,
      64786, 64885, 64985, 65085, 65185, 65285, 65385, 65485,
      65586, 65686, 65787, 65888, 65989, 66091, 66192, 66294,
      66396, 66498, 66600, 66702, 66804, 66907, 67010, 67113,
      67216, 67319, 67422, 67526, 67629, 67733, 67837, 67942,
      68046, 68151, 68255, 68360, 68465, 68570, 68676, 68781,
      68887, 68993, 69099, 69205, 69312, 69418, 69525, 69632,
      69739, 69846, 69954, 70061, 70169, 70277, 70385, 70494,
      70602, 70711, 70820, 70929, 71038, 71147, 71257, 71367,
      71477, 71587, 71697, 71808, 71918, 72029, 72140, 72252,
      72363, 72475, 72587, 72699, 72811, 72923, 73036, 73149,
      73262, 73375, 73488, 73602, 73715, 73829, 73944, 74058,
      74172, 74287, 74402, 74517, 74633, 74748, 74864, 74980,
      75096, 75213, 75329, 75446, 75563, 75680, 75797, 75915,
      76033, 76151, 76269, 76388, 76506, 76625, 76744, 76864,
      76983, 77103, 77223, 77343, 77463, 77584, 77705, 77826,
      77947, 78068, 78190, 78312, 78434, 78557, 78679, 78802,
      78925, 79048, 79172, 79296, 79420, 79544, 79668, 79793,
      79918, 80043, 80168, 80294, 80420, 80546, 80672, 80799,
      80925, 81053, 81180, 81307, 81435, 81563, 81691, 81820,
      81949, 82078, 82207, 82336, 82466, 82596, 82726, 82857,
      82987, 83118, 83250, 83381, 83513, 83645, 83777, 83910,
      84043, 84176, 84309, 84443, 84576, 84710, 84845, 84980,
      85114, 85250, 85385, 85521, 85657, 85793, 85930, 86066,
      86204, 86341, 86479, 86616, 86755, 86893, 87032, 87171,
      87310, 87450, 87590, 87730, 87871, 88011, 88152, 88294,
      88435, 88577, 88720, 88862, 89005, 89148, 89292, 89435,
      89579, 89724, 89868, 90013, 90158, 90304, 90450, 90596,
      90742, 90889, 91036, 91184, 91332, 91480, 91628, 91777,
      91926, 92075, 92225, 92375, 92525, 92675, 92826, 92978,
      93129, 93281, 93434, 93586, 93739, 93892, 94046, 94200,
      94354, 94509, 94664, 94819, 94975, 95131, 95287, 95444,
      95601, 95758, 95916, 96074, 96233, 96391, 96551, 96710,
      96870, 97030, 97191, 97352, 97513, 97675, 97837, 98000,
      98163, 98326, 98489, 98653, 98818, 98982, 99148, 99313,
      99479, 99645, 99812, 99979, 100146, 100314, 100482, 100651,
      100820, 100990, 101159, 101330, 101500, 101671, 101843, 102015,
      102187, 102360, 102533, 102706, 102880, 103054, 103229, 103404,
      103580, 103756, 103933, 104109, 104287, 104465, 104643, 104821,
      105000, 105180, 105360, 105540, 105721, 105902, 106084, 106266,
      106449, 106632, 106816, 107000, 107184, 107369, 107555, 107741,
      107927, 108114, 108301, 108489, 108677, 108866, 109055, 109245,
      109435, 109626, 109817, 110008, 110200, 110393, 110586, 110780,
      110974, 111169, 111364, 111560, 111756, 111952, 112150, 112347,
      112546, 112744, 112944, 113143, 113344, 113545, 113746, 113948,
      114151, 114354, 114557, 114761, 114966, 115171, 115377, 115583,
      115790, 115998, 116206, 116414, 116623, 116833, 117044, 117254,
      117466, 117678, 117891, 118104, 118318, 118532, 118747, 118963,
      119179, 119396, 119613, 119831, 120050, 120269, 120489, 120709,
      120930, 121152, 121374, 121597, 121821, 122045, 122270, 122496,
      122722, 122949, 123176, 123404, 123633, 123863, 124093, 124324,
      124555, 124787, 125020, 125254, 125488, 125723, 125959, 126195,
      126432, 126669, 126908, 127147, 127387, 127627, 127869, 128111,
      128353, 128597, 128841, 129086, 129332, 129578, 129825, 130073,
      130322, 130571, 130821, 131072, 131324, 131576, 131830, 132084,
      132339, 132594, 132851, 133108, 133366, 133625, 133884, 134145,
      134406, 134668, 134931, 135195, 135459, 135725, 135991, 136258,
      136526, 136795, 137065, 137335, 137607, 137879, 138152, 138426,
      138701, 138977, 139254, 139532, 139810, 140090, 140370, 140651,
      140934, 141217, 141501, 141786, 142072, 142359, 142647, 142936,
      143226, 143517, 143808, 144101, 144395, 144690, 144986, 145282,
      145580, 145879, 146179, 146480, 146782, 147084, 147388, 147693,
      148000, 148307, 148615, 148924, 149235, 149546, 149859, 150172,
      150487, 150803, 151120, 151438, 151757, 152077, 152399, 152722,
      153045, 153370, 153697, 154024, 154352, 154682, 155013, 155345,
      155678, 156013, 156349, 156686, 157024, 157363, 157704, 158046,
      158389, 158734, 159079, 159427, 159775, 160125, 160476, 160828,
      161182, 161537, 161893, 162251, 162610, 162970, 163332, 163695,
      164060, 164426, 164793, 165162, 165532, 165904, 166277, 166651,
      167027, 167405, 167784, 168164, 168546, 168930, 169315, 169701,
      170089, 170479, 170870, 171263, 171657, 172053, 172451, 172850,
      173251, 173653, 174057, 174463, 174870, 175279, 175690, 176102,
      176516, 176932, 177349, 177769, 178190, 178612, 179037, 179463,
      179891, 180321, 180753, 181186, 181622, 182059, 182498, 182939,
      183382, 183827, 184274, 184722, 185173, 185625, 186080, 186536,
      186995, 187455, 187918, 188382, 188849, 189318, 189789, 190261,
      190736, 191213, 191693, 192174, 192658, 193143, 193631, 194122,
      194614, 195109, 195606, 196105, 196606, 197110, 197616, 198125,
      198636, 199149, 199664, 200182, 200703, 201226, 201751, 202279,
      202809, 203342, 203878, 204416, 204956, 205500, 206045, 206594,
      207145, 207699, 208255, 208815, 209376, 209941, 210509, 211079,
      211652, 212228, 212807, 213389, 213973, 214561, 215151, 215745,
      216341, 216941, 217544, 218149, 218758, 219370, 219985, 220603,
      221225, 221849, 222477, 223108, 223743, 224381, 225022, 225666,
      226314, 226966, 227621, 228279, 228941, 229606, 230275, 230948,
      231624, 232304, 232988, 233676, 234367, 235062, 235761, 236463,
      237170, 237881, 238595, 239314, 240036, 240763, 241493, 242228,
      242967, 243711, 244458, 245210, 245966, 246727, 247492, 248261,
      249035, 249813, 250596, 251384, 252176, 252973, 253774, 254581,
      255392, 256208, 257029, 257855, 258686, 259522, 260363, 261209,
      262060, 262917, 263779, 264646, 265519, 266397, 267280, 268169,
      269064, 269965, 270871, 271782, 272700, 273624, 274553, 275489,
      276430, 277378, 278332, 279292, 280258, 281231, 282210, 283195,
      284188, 285186, 286192, 287204, 288223, 289249, 290282, 291322,
      292369, 293423, 294485, 295554, 296630, 297714, 298805, 299904,
      301011, 302126, 303248, 304379, 305517, 306664, 307819, 308983,
      310154, 311335, 312524, 313721, 314928, 316143, 317368, 318601,
      319844, 321097, 322358, 323629, 324910, 326201, 327502, 328812,
      330133, 331464, 332805, 334157, 335519, 336892, 338276, 339671,
      341078, 342495, 343924, 345364, 346816, 348280, 349756, 351244,
      352744, 354257, 355783, 357321, 358872, 360436, 362013, 363604,
      365208, 366826, 368459, 370105, 371765, 373440, 375130, 376835,
      378555, 380290, 382040, 383807, 385589, 387387, 389202, 391034,
      392882, 394747, 396630, 398530, 400448, 402384, 404338, 406311,
      408303, 410314, 412344, 414395, 416465, 418555, 420666, 422798,
      424951, 427125, 429321, 431540, 433781, 436045, 438332, 440643,
      442978, 445337, 447720, 450129, 452564, 455024, 457511, 460024,
      462565, 465133, 467730, 470355, 473009, 475692, 478406, 481150,
      483925, 486732, 489571, 492443, 495348, 498287, 501261, 504269,
      507313, 510394, 513512, 516667, 519861, 523094, 526366, 529680,
      533034, 536431, 539870, 543354, 546881, 550455, 554074, 557741,
      561456, 565221, 569035, 572901, 576818, 580789, 584815, 588896,
      593033, 597229, 601483, 605798, 610174, 614613, 619117, 623686,
      628323, 633028, 637803, 642651, 647572, 652568, 657640, 662792,
      668024, 673338, 678737, 684223, 689797, 695462, 701219, 707072,
      713023, 719074, 725227, 731486, 737853, 744331, 750922, 757631,
      764460, 771411, 778490, 785699, 793041, 800521, 808143, 815910,
      823827, 831898, 840127, 848520, 857081, 865817, 874730, 883829,
      893117, 902602, 912289, 922186, 932298, 942633, 953199, 964003,
      975054, 986361, 997931, 1009774, 1021901, 1034322, 1047046, 1060087,
      1073455, 1087164, 1101225, 1115654, 1130465, 1145673, 1161294, 1177345,
      1193846, 1210813, 1228269, 1246234, 1264730, 1283783, 1303416, 1323658,
      1344537, 1366084, 1388330, 1411312, 1435065, 1459630, 1485049, 1511367,
      1538632, 1566898, 1596220, 1626658, 1658278, 1691149, 1725348, 1760956,
      1798063, 1836758, 1877161, 1919378, 1963536, 2009771, 2058233, 2109087,
      2162516, 2218719, 2277919, 2340362, 2406322, 2476104, 2550052, 2628549,
      2712030, 2800983, 2895966, 2997613, 3106651, 3223918, 3350381, 3487165,
      3635590, 3797206, 3973855, 4167737, 4381502, 4618375, 4882318, 5178251,
      5512368, 5892567, 6329090, 6835455, 7429880, 8137527, 8994149, 10052327,
      11392683, 13145455, 15535599, 18988036, 24413316, 34178904, 56965752, 170910304,
    ]
    @@finesine = [
      25, 75, 125, 175, 226, 276, 326, 376,
      427, 477, 527, 578, 628, 678, 728, 779,
      829, 879, 929, 980, 1030, 1080, 1130, 1181,
      1231, 1281, 1331, 1382, 1432, 1482, 1532, 1583,
      1633, 1683, 1733, 1784, 1834, 1884, 1934, 1985,
      2035, 2085, 2135, 2186, 2236, 2286, 2336, 2387,
      2437, 2487, 2537, 2587, 2638, 2688, 2738, 2788,
      2839, 2889, 2939, 2989, 3039, 3090, 3140, 3190,
      3240, 3291, 3341, 3391, 3441, 3491, 3541, 3592,
      3642, 3692, 3742, 3792, 3843, 3893, 3943, 3993,
      4043, 4093, 4144, 4194, 4244, 4294, 4344, 4394,
      4445, 4495, 4545, 4595, 4645, 4695, 4745, 4796,
      4846, 4896, 4946, 4996, 5046, 5096, 5146, 5197,
      5247, 5297, 5347, 5397, 5447, 5497, 5547, 5597,
      5647, 5697, 5748, 5798, 5848, 5898, 5948, 5998,
      6048, 6098, 6148, 6198, 6248, 6298, 6348, 6398,
      6448, 6498, 6548, 6598, 6648, 6698, 6748, 6798,
      6848, 6898, 6948, 6998, 7048, 7098, 7148, 7198,
      7248, 7298, 7348, 7398, 7448, 7498, 7548, 7598,
      7648, 7697, 7747, 7797, 7847, 7897, 7947, 7997,
      8047, 8097, 8147, 8196, 8246, 8296, 8346, 8396,
      8446, 8496, 8545, 8595, 8645, 8695, 8745, 8794,
      8844, 8894, 8944, 8994, 9043, 9093, 9143, 9193,
      9243, 9292, 9342, 9392, 9442, 9491, 9541, 9591,
      9640, 9690, 9740, 9790, 9839, 9889, 9939, 9988,
      10038, 10088, 10137, 10187, 10237, 10286, 10336, 10386,
      10435, 10485, 10534, 10584, 10634, 10683, 10733, 10782,
      10832, 10882, 10931, 10981, 11030, 11080, 11129, 11179,
      11228, 11278, 11327, 11377, 11426, 11476, 11525, 11575,
      11624, 11674, 11723, 11773, 11822, 11872, 11921, 11970,
      12020, 12069, 12119, 12168, 12218, 12267, 12316, 12366,
      12415, 12464, 12514, 12563, 12612, 12662, 12711, 12760,
      12810, 12859, 12908, 12957, 13007, 13056, 13105, 13154,
      13204, 13253, 13302, 13351, 13401, 13450, 13499, 13548,
      13597, 13647, 13696, 13745, 13794, 13843, 13892, 13941,
      13990, 14040, 14089, 14138, 14187, 14236, 14285, 14334,
      14383, 14432, 14481, 14530, 14579, 14628, 14677, 14726,
      14775, 14824, 14873, 14922, 14971, 15020, 15069, 15118,
      15167, 15215, 15264, 15313, 15362, 15411, 15460, 15509,
      15557, 15606, 15655, 15704, 15753, 15802, 15850, 15899,
      15948, 15997, 16045, 16094, 16143, 16191, 16240, 16289,
      16338, 16386, 16435, 16484, 16532, 16581, 16629, 16678,
      16727, 16775, 16824, 16872, 16921, 16970, 17018, 17067,
      17115, 17164, 17212, 17261, 17309, 17358, 17406, 17455,
      17503, 17551, 17600, 17648, 17697, 17745, 17793, 17842,
      17890, 17939, 17987, 18035, 18084, 18132, 18180, 18228,
      18277, 18325, 18373, 18421, 18470, 18518, 18566, 18614,
      18663, 18711, 18759, 18807, 18855, 18903, 18951, 19000,
      19048, 19096, 19144, 19192, 19240, 19288, 19336, 19384,
      19432, 19480, 19528, 19576, 19624, 19672, 19720, 19768,
      19816, 19864, 19912, 19959, 20007, 20055, 20103, 20151,
      20199, 20246, 20294, 20342, 20390, 20438, 20485, 20533,
      20581, 20629, 20676, 20724, 20772, 20819, 20867, 20915,
      20962, 21010, 21057, 21105, 21153, 21200, 21248, 21295,
      21343, 21390, 21438, 21485, 21533, 21580, 21628, 21675,
      21723, 21770, 21817, 21865, 21912, 21960, 22007, 22054,
      22102, 22149, 22196, 22243, 22291, 22338, 22385, 22433,
      22480, 22527, 22574, 22621, 22668, 22716, 22763, 22810,
      22857, 22904, 22951, 22998, 23045, 23092, 23139, 23186,
      23233, 23280, 23327, 23374, 23421, 23468, 23515, 23562,
      23609, 23656, 23703, 23750, 23796, 23843, 23890, 23937,
      23984, 24030, 24077, 24124, 24171, 24217, 24264, 24311,
      24357, 24404, 24451, 24497, 24544, 24591, 24637, 24684,
      24730, 24777, 24823, 24870, 24916, 24963, 25009, 25056,
      25102, 25149, 25195, 25241, 25288, 25334, 25381, 25427,
      25473, 25520, 25566, 25612, 25658, 25705, 25751, 25797,
      25843, 25889, 25936, 25982, 26028, 26074, 26120, 26166,
      26212, 26258, 26304, 26350, 26396, 26442, 26488, 26534,
      26580, 26626, 26672, 26718, 26764, 26810, 26856, 26902,
      26947, 26993, 27039, 27085, 27131, 27176, 27222, 27268,
      27313, 27359, 27405, 27450, 27496, 27542, 27587, 27633,
      27678, 27724, 27770, 27815, 27861, 27906, 27952, 27997,
      28042, 28088, 28133, 28179, 28224, 28269, 28315, 28360,
      28405, 28451, 28496, 28541, 28586, 28632, 28677, 28722,
      28767, 28812, 28858, 28903, 28948, 28993, 29038, 29083,
      29128, 29173, 29218, 29263, 29308, 29353, 29398, 29443,
      29488, 29533, 29577, 29622, 29667, 29712, 29757, 29801,
      29846, 29891, 29936, 29980, 30025, 30070, 30114, 30159,
      30204, 30248, 30293, 30337, 30382, 30426, 30471, 30515,
      30560, 30604, 30649, 30693, 30738, 30782, 30826, 30871,
      30915, 30959, 31004, 31048, 31092, 31136, 31181, 31225,
      31269, 31313, 31357, 31402, 31446, 31490, 31534, 31578,
      31622, 31666, 31710, 31754, 31798, 31842, 31886, 31930,
      31974, 32017, 32061, 32105, 32149, 32193, 32236, 32280,
      32324, 32368, 32411, 32455, 32499, 32542, 32586, 32630,
      32673, 32717, 32760, 32804, 32847, 32891, 32934, 32978,
      33021, 33065, 33108, 33151, 33195, 33238, 33281, 33325,
      33368, 33411, 33454, 33498, 33541, 33584, 33627, 33670,
      33713, 33756, 33799, 33843, 33886, 33929, 33972, 34015,
      34057, 34100, 34143, 34186, 34229, 34272, 34315, 34358,
      34400, 34443, 34486, 34529, 34571, 34614, 34657, 34699,
      34742, 34785, 34827, 34870, 34912, 34955, 34997, 35040,
      35082, 35125, 35167, 35210, 35252, 35294, 35337, 35379,
      35421, 35464, 35506, 35548, 35590, 35633, 35675, 35717,
      35759, 35801, 35843, 35885, 35927, 35969, 36011, 36053,
      36095, 36137, 36179, 36221, 36263, 36305, 36347, 36388,
      36430, 36472, 36514, 36555, 36597, 36639, 36681, 36722,
      36764, 36805, 36847, 36889, 36930, 36972, 37013, 37055,
      37096, 37137, 37179, 37220, 37262, 37303, 37344, 37386,
      37427, 37468, 37509, 37551, 37592, 37633, 37674, 37715,
      37756, 37797, 37838, 37879, 37920, 37961, 38002, 38043,
      38084, 38125, 38166, 38207, 38248, 38288, 38329, 38370,
      38411, 38451, 38492, 38533, 38573, 38614, 38655, 38695,
      38736, 38776, 38817, 38857, 38898, 38938, 38979, 39019,
      39059, 39100, 39140, 39180, 39221, 39261, 39301, 39341,
      39382, 39422, 39462, 39502, 39542, 39582, 39622, 39662,
      39702, 39742, 39782, 39822, 39862, 39902, 39942, 39982,
      40021, 40061, 40101, 40141, 40180, 40220, 40260, 40300,
      40339, 40379, 40418, 40458, 40497, 40537, 40576, 40616,
      40655, 40695, 40734, 40773, 40813, 40852, 40891, 40931,
      40970, 41009, 41048, 41087, 41127, 41166, 41205, 41244,
      41283, 41322, 41361, 41400, 41439, 41478, 41517, 41556,
      41595, 41633, 41672, 41711, 41750, 41788, 41827, 41866,
      41904, 41943, 41982, 42020, 42059, 42097, 42136, 42174,
      42213, 42251, 42290, 42328, 42366, 42405, 42443, 42481,
      42520, 42558, 42596, 42634, 42672, 42711, 42749, 42787,
      42825, 42863, 42901, 42939, 42977, 43015, 43053, 43091,
      43128, 43166, 43204, 43242, 43280, 43317, 43355, 43393,
      43430, 43468, 43506, 43543, 43581, 43618, 43656, 43693,
      43731, 43768, 43806, 43843, 43880, 43918, 43955, 43992,
      44029, 44067, 44104, 44141, 44178, 44215, 44252, 44289,
      44326, 44363, 44400, 44437, 44474, 44511, 44548, 44585,
      44622, 44659, 44695, 44732, 44769, 44806, 44842, 44879,
      44915, 44952, 44989, 45025, 45062, 45098, 45135, 45171,
      45207, 45244, 45280, 45316, 45353, 45389, 45425, 45462,
      45498, 45534, 45570, 45606, 45642, 45678, 45714, 45750,
      45786, 45822, 45858, 45894, 45930, 45966, 46002, 46037,
      46073, 46109, 46145, 46180, 46216, 46252, 46287, 46323,
      46358, 46394, 46429, 46465, 46500, 46536, 46571, 46606,
      46642, 46677, 46712, 46747, 46783, 46818, 46853, 46888,
      46923, 46958, 46993, 47028, 47063, 47098, 47133, 47168,
      47203, 47238, 47273, 47308, 47342, 47377, 47412, 47446,
      47481, 47516, 47550, 47585, 47619, 47654, 47688, 47723,
      47757, 47792, 47826, 47860, 47895, 47929, 47963, 47998,
      48032, 48066, 48100, 48134, 48168, 48202, 48237, 48271,
      48305, 48338, 48372, 48406, 48440, 48474, 48508, 48542,
      48575, 48609, 48643, 48676, 48710, 48744, 48777, 48811,
      48844, 48878, 48911, 48945, 48978, 49012, 49045, 49078,
      49112, 49145, 49178, 49211, 49244, 49278, 49311, 49344,
      49377, 49410, 49443, 49476, 49509, 49542, 49575, 49608,
      49640, 49673, 49706, 49739, 49771, 49804, 49837, 49869,
      49902, 49935, 49967, 50000, 50032, 50065, 50097, 50129,
      50162, 50194, 50226, 50259, 50291, 50323, 50355, 50387,
      50420, 50452, 50484, 50516, 50548, 50580, 50612, 50644,
      50675, 50707, 50739, 50771, 50803, 50834, 50866, 50898,
      50929, 50961, 50993, 51024, 51056, 51087, 51119, 51150,
      51182, 51213, 51244, 51276, 51307, 51338, 51369, 51401,
      51432, 51463, 51494, 51525, 51556, 51587, 51618, 51649,
      51680, 51711, 51742, 51773, 51803, 51834, 51865, 51896,
      51926, 51957, 51988, 52018, 52049, 52079, 52110, 52140,
      52171, 52201, 52231, 52262, 52292, 52322, 52353, 52383,
      52413, 52443, 52473, 52503, 52534, 52564, 52594, 52624,
      52653, 52683, 52713, 52743, 52773, 52803, 52832, 52862,
      52892, 52922, 52951, 52981, 53010, 53040, 53069, 53099,
      53128, 53158, 53187, 53216, 53246, 53275, 53304, 53334,
      53363, 53392, 53421, 53450, 53479, 53508, 53537, 53566,
      53595, 53624, 53653, 53682, 53711, 53739, 53768, 53797,
      53826, 53854, 53883, 53911, 53940, 53969, 53997, 54026,
      54054, 54082, 54111, 54139, 54167, 54196, 54224, 54252,
      54280, 54308, 54337, 54365, 54393, 54421, 54449, 54477,
      54505, 54533, 54560, 54588, 54616, 54644, 54672, 54699,
      54727, 54755, 54782, 54810, 54837, 54865, 54892, 54920,
      54947, 54974, 55002, 55029, 55056, 55084, 55111, 55138,
      55165, 55192, 55219, 55246, 55274, 55300, 55327, 55354,
      55381, 55408, 55435, 55462, 55489, 55515, 55542, 55569,
      55595, 55622, 55648, 55675, 55701, 55728, 55754, 55781,
      55807, 55833, 55860, 55886, 55912, 55938, 55965, 55991,
      56017, 56043, 56069, 56095, 56121, 56147, 56173, 56199,
      56225, 56250, 56276, 56302, 56328, 56353, 56379, 56404,
      56430, 56456, 56481, 56507, 56532, 56557, 56583, 56608,
      56633, 56659, 56684, 56709, 56734, 56760, 56785, 56810,
      56835, 56860, 56885, 56910, 56935, 56959, 56984, 57009,
      57034, 57059, 57083, 57108, 57133, 57157, 57182, 57206,
      57231, 57255, 57280, 57304, 57329, 57353, 57377, 57402,
      57426, 57450, 57474, 57498, 57522, 57546, 57570, 57594,
      57618, 57642, 57666, 57690, 57714, 57738, 57762, 57785,
      57809, 57833, 57856, 57880, 57903, 57927, 57950, 57974,
      57997, 58021, 58044, 58067, 58091, 58114, 58137, 58160,
      58183, 58207, 58230, 58253, 58276, 58299, 58322, 58345,
      58367, 58390, 58413, 58436, 58459, 58481, 58504, 58527,
      58549, 58572, 58594, 58617, 58639, 58662, 58684, 58706,
      58729, 58751, 58773, 58795, 58818, 58840, 58862, 58884,
      58906, 58928, 58950, 58972, 58994, 59016, 59038, 59059,
      59081, 59103, 59125, 59146, 59168, 59190, 59211, 59233,
      59254, 59276, 59297, 59318, 59340, 59361, 59382, 59404,
      59425, 59446, 59467, 59488, 59509, 59530, 59551, 59572,
      59593, 59614, 59635, 59656, 59677, 59697, 59718, 59739,
      59759, 59780, 59801, 59821, 59842, 59862, 59883, 59903,
      59923, 59944, 59964, 59984, 60004, 60025, 60045, 60065,
      60085, 60105, 60125, 60145, 60165, 60185, 60205, 60225,
      60244, 60264, 60284, 60304, 60323, 60343, 60363, 60382,
      60402, 60421, 60441, 60460, 60479, 60499, 60518, 60537,
      60556, 60576, 60595, 60614, 60633, 60652, 60671, 60690,
      60709, 60728, 60747, 60766, 60785, 60803, 60822, 60841,
      60859, 60878, 60897, 60915, 60934, 60952, 60971, 60989,
      61007, 61026, 61044, 61062, 61081, 61099, 61117, 61135,
      61153, 61171, 61189, 61207, 61225, 61243, 61261, 61279,
      61297, 61314, 61332, 61350, 61367, 61385, 61403, 61420,
      61438, 61455, 61473, 61490, 61507, 61525, 61542, 61559,
      61577, 61594, 61611, 61628, 61645, 61662, 61679, 61696,
      61713, 61730, 61747, 61764, 61780, 61797, 61814, 61831,
      61847, 61864, 61880, 61897, 61913, 61930, 61946, 61963,
      61979, 61995, 62012, 62028, 62044, 62060, 62076, 62092,
      62108, 62125, 62141, 62156, 62172, 62188, 62204, 62220,
      62236, 62251, 62267, 62283, 62298, 62314, 62329, 62345,
      62360, 62376, 62391, 62407, 62422, 62437, 62453, 62468,
      62483, 62498, 62513, 62528, 62543, 62558, 62573, 62588,
      62603, 62618, 62633, 62648, 62662, 62677, 62692, 62706,
      62721, 62735, 62750, 62764, 62779, 62793, 62808, 62822,
      62836, 62850, 62865, 62879, 62893, 62907, 62921, 62935,
      62949, 62963, 62977, 62991, 63005, 63019, 63032, 63046,
      63060, 63074, 63087, 63101, 63114, 63128, 63141, 63155,
      63168, 63182, 63195, 63208, 63221, 63235, 63248, 63261,
      63274, 63287, 63300, 63313, 63326, 63339, 63352, 63365,
      63378, 63390, 63403, 63416, 63429, 63441, 63454, 63466,
      63479, 63491, 63504, 63516, 63528, 63541, 63553, 63565,
      63578, 63590, 63602, 63614, 63626, 63638, 63650, 63662,
      63674, 63686, 63698, 63709, 63721, 63733, 63745, 63756,
      63768, 63779, 63791, 63803, 63814, 63825, 63837, 63848,
      63859, 63871, 63882, 63893, 63904, 63915, 63927, 63938,
      63949, 63960, 63971, 63981, 63992, 64003, 64014, 64025,
      64035, 64046, 64057, 64067, 64078, 64088, 64099, 64109,
      64120, 64130, 64140, 64151, 64161, 64171, 64181, 64192,
      64202, 64212, 64222, 64232, 64242, 64252, 64261, 64271,
      64281, 64291, 64301, 64310, 64320, 64330, 64339, 64349,
      64358, 64368, 64377, 64387, 64396, 64405, 64414, 64424,
      64433, 64442, 64451, 64460, 64469, 64478, 64487, 64496,
      64505, 64514, 64523, 64532, 64540, 64549, 64558, 64566,
      64575, 64584, 64592, 64601, 64609, 64617, 64626, 64634,
      64642, 64651, 64659, 64667, 64675, 64683, 64691, 64699,
      64707, 64715, 64723, 64731, 64739, 64747, 64754, 64762,
      64770, 64777, 64785, 64793, 64800, 64808, 64815, 64822,
      64830, 64837, 64844, 64852, 64859, 64866, 64873, 64880,
      64887, 64895, 64902, 64908, 64915, 64922, 64929, 64936,
      64943, 64949, 64956, 64963, 64969, 64976, 64982, 64989,
      64995, 65002, 65008, 65015, 65021, 65027, 65033, 65040,
      65046, 65052, 65058, 65064, 65070, 65076, 65082, 65088,
      65094, 65099, 65105, 65111, 65117, 65122, 65128, 65133,
      65139, 65144, 65150, 65155, 65161, 65166, 65171, 65177,
      65182, 65187, 65192, 65197, 65202, 65207, 65212, 65217,
      65222, 65227, 65232, 65237, 65242, 65246, 65251, 65256,
      65260, 65265, 65270, 65274, 65279, 65283, 65287, 65292,
      65296, 65300, 65305, 65309, 65313, 65317, 65321, 65325,
      65329, 65333, 65337, 65341, 65345, 65349, 65352, 65356,
      65360, 65363, 65367, 65371, 65374, 65378, 65381, 65385,
      65388, 65391, 65395, 65398, 65401, 65404, 65408, 65411,
      65414, 65417, 65420, 65423, 65426, 65429, 65431, 65434,
      65437, 65440, 65442, 65445, 65448, 65450, 65453, 65455,
      65458, 65460, 65463, 65465, 65467, 65470, 65472, 65474,
      65476, 65478, 65480, 65482, 65484, 65486, 65488, 65490,
      65492, 65494, 65496, 65497, 65499, 65501, 65502, 65504,
      65505, 65507, 65508, 65510, 65511, 65513, 65514, 65515,
      65516, 65518, 65519, 65520, 65521, 65522, 65523, 65524,
      65525, 65526, 65527, 65527, 65528, 65529, 65530, 65530,
      65531, 65531, 65532, 65532, 65533, 65533, 65534, 65534,
      65534, 65535, 65535, 65535, 65535, 65535, 65535, 65535,
      65535, 65535, 65535, 65535, 65535, 65535, 65535, 65534,
      65534, 65534, 65533, 65533, 65532, 65532, 65531, 65531,
      65530, 65530, 65529, 65528, 65527, 65527, 65526, 65525,
      65524, 65523, 65522, 65521, 65520, 65519, 65518, 65516,
      65515, 65514, 65513, 65511, 65510, 65508, 65507, 65505,
      65504, 65502, 65501, 65499, 65497, 65496, 65494, 65492,
      65490, 65488, 65486, 65484, 65482, 65480, 65478, 65476,
      65474, 65472, 65470, 65467, 65465, 65463, 65460, 65458,
      65455, 65453, 65450, 65448, 65445, 65442, 65440, 65437,
      65434, 65431, 65429, 65426, 65423, 65420, 65417, 65414,
      65411, 65408, 65404, 65401, 65398, 65395, 65391, 65388,
      65385, 65381, 65378, 65374, 65371, 65367, 65363, 65360,
      65356, 65352, 65349, 65345, 65341, 65337, 65333, 65329,
      65325, 65321, 65317, 65313, 65309, 65305, 65300, 65296,
      65292, 65287, 65283, 65279, 65274, 65270, 65265, 65260,
      65256, 65251, 65246, 65242, 65237, 65232, 65227, 65222,
      65217, 65212, 65207, 65202, 65197, 65192, 65187, 65182,
      65177, 65171, 65166, 65161, 65155, 65150, 65144, 65139,
      65133, 65128, 65122, 65117, 65111, 65105, 65099, 65094,
      65088, 65082, 65076, 65070, 65064, 65058, 65052, 65046,
      65040, 65033, 65027, 65021, 65015, 65008, 65002, 64995,
      64989, 64982, 64976, 64969, 64963, 64956, 64949, 64943,
      64936, 64929, 64922, 64915, 64908, 64902, 64895, 64887,
      64880, 64873, 64866, 64859, 64852, 64844, 64837, 64830,
      64822, 64815, 64808, 64800, 64793, 64785, 64777, 64770,
      64762, 64754, 64747, 64739, 64731, 64723, 64715, 64707,
      64699, 64691, 64683, 64675, 64667, 64659, 64651, 64642,
      64634, 64626, 64617, 64609, 64600, 64592, 64584, 64575,
      64566, 64558, 64549, 64540, 64532, 64523, 64514, 64505,
      64496, 64487, 64478, 64469, 64460, 64451, 64442, 64433,
      64424, 64414, 64405, 64396, 64387, 64377, 64368, 64358,
      64349, 64339, 64330, 64320, 64310, 64301, 64291, 64281,
      64271, 64261, 64252, 64242, 64232, 64222, 64212, 64202,
      64192, 64181, 64171, 64161, 64151, 64140, 64130, 64120,
      64109, 64099, 64088, 64078, 64067, 64057, 64046, 64035,
      64025, 64014, 64003, 63992, 63981, 63971, 63960, 63949,
      63938, 63927, 63915, 63904, 63893, 63882, 63871, 63859,
      63848, 63837, 63825, 63814, 63803, 63791, 63779, 63768,
      63756, 63745, 63733, 63721, 63709, 63698, 63686, 63674,
      63662, 63650, 63638, 63626, 63614, 63602, 63590, 63578,
      63565, 63553, 63541, 63528, 63516, 63504, 63491, 63479,
      63466, 63454, 63441, 63429, 63416, 63403, 63390, 63378,
      63365, 63352, 63339, 63326, 63313, 63300, 63287, 63274,
      63261, 63248, 63235, 63221, 63208, 63195, 63182, 63168,
      63155, 63141, 63128, 63114, 63101, 63087, 63074, 63060,
      63046, 63032, 63019, 63005, 62991, 62977, 62963, 62949,
      62935, 62921, 62907, 62893, 62879, 62865, 62850, 62836,
      62822, 62808, 62793, 62779, 62764, 62750, 62735, 62721,
      62706, 62692, 62677, 62662, 62648, 62633, 62618, 62603,
      62588, 62573, 62558, 62543, 62528, 62513, 62498, 62483,
      62468, 62453, 62437, 62422, 62407, 62391, 62376, 62360,
      62345, 62329, 62314, 62298, 62283, 62267, 62251, 62236,
      62220, 62204, 62188, 62172, 62156, 62141, 62125, 62108,
      62092, 62076, 62060, 62044, 62028, 62012, 61995, 61979,
      61963, 61946, 61930, 61913, 61897, 61880, 61864, 61847,
      61831, 61814, 61797, 61780, 61764, 61747, 61730, 61713,
      61696, 61679, 61662, 61645, 61628, 61611, 61594, 61577,
      61559, 61542, 61525, 61507, 61490, 61473, 61455, 61438,
      61420, 61403, 61385, 61367, 61350, 61332, 61314, 61297,
      61279, 61261, 61243, 61225, 61207, 61189, 61171, 61153,
      61135, 61117, 61099, 61081, 61062, 61044, 61026, 61007,
      60989, 60971, 60952, 60934, 60915, 60897, 60878, 60859,
      60841, 60822, 60803, 60785, 60766, 60747, 60728, 60709,
      60690, 60671, 60652, 60633, 60614, 60595, 60576, 60556,
      60537, 60518, 60499, 60479, 60460, 60441, 60421, 60402,
      60382, 60363, 60343, 60323, 60304, 60284, 60264, 60244,
      60225, 60205, 60185, 60165, 60145, 60125, 60105, 60085,
      60065, 60045, 60025, 60004, 59984, 59964, 59944, 59923,
      59903, 59883, 59862, 59842, 59821, 59801, 59780, 59759,
      59739, 59718, 59697, 59677, 59656, 59635, 59614, 59593,
      59572, 59551, 59530, 59509, 59488, 59467, 59446, 59425,
      59404, 59382, 59361, 59340, 59318, 59297, 59276, 59254,
      59233, 59211, 59190, 59168, 59146, 59125, 59103, 59081,
      59059, 59038, 59016, 58994, 58972, 58950, 58928, 58906,
      58884, 58862, 58840, 58818, 58795, 58773, 58751, 58729,
      58706, 58684, 58662, 58639, 58617, 58594, 58572, 58549,
      58527, 58504, 58481, 58459, 58436, 58413, 58390, 58367,
      58345, 58322, 58299, 58276, 58253, 58230, 58207, 58183,
      58160, 58137, 58114, 58091, 58067, 58044, 58021, 57997,
      57974, 57950, 57927, 57903, 57880, 57856, 57833, 57809,
      57785, 57762, 57738, 57714, 57690, 57666, 57642, 57618,
      57594, 57570, 57546, 57522, 57498, 57474, 57450, 57426,
      57402, 57377, 57353, 57329, 57304, 57280, 57255, 57231,
      57206, 57182, 57157, 57133, 57108, 57083, 57059, 57034,
      57009, 56984, 56959, 56935, 56910, 56885, 56860, 56835,
      56810, 56785, 56760, 56734, 56709, 56684, 56659, 56633,
      56608, 56583, 56557, 56532, 56507, 56481, 56456, 56430,
      56404, 56379, 56353, 56328, 56302, 56276, 56250, 56225,
      56199, 56173, 56147, 56121, 56095, 56069, 56043, 56017,
      55991, 55965, 55938, 55912, 55886, 55860, 55833, 55807,
      55781, 55754, 55728, 55701, 55675, 55648, 55622, 55595,
      55569, 55542, 55515, 55489, 55462, 55435, 55408, 55381,
      55354, 55327, 55300, 55274, 55246, 55219, 55192, 55165,
      55138, 55111, 55084, 55056, 55029, 55002, 54974, 54947,
      54920, 54892, 54865, 54837, 54810, 54782, 54755, 54727,
      54699, 54672, 54644, 54616, 54588, 54560, 54533, 54505,
      54477, 54449, 54421, 54393, 54365, 54337, 54308, 54280,
      54252, 54224, 54196, 54167, 54139, 54111, 54082, 54054,
      54026, 53997, 53969, 53940, 53911, 53883, 53854, 53826,
      53797, 53768, 53739, 53711, 53682, 53653, 53624, 53595,
      53566, 53537, 53508, 53479, 53450, 53421, 53392, 53363,
      53334, 53304, 53275, 53246, 53216, 53187, 53158, 53128,
      53099, 53069, 53040, 53010, 52981, 52951, 52922, 52892,
      52862, 52832, 52803, 52773, 52743, 52713, 52683, 52653,
      52624, 52594, 52564, 52534, 52503, 52473, 52443, 52413,
      52383, 52353, 52322, 52292, 52262, 52231, 52201, 52171,
      52140, 52110, 52079, 52049, 52018, 51988, 51957, 51926,
      51896, 51865, 51834, 51803, 51773, 51742, 51711, 51680,
      51649, 51618, 51587, 51556, 51525, 51494, 51463, 51432,
      51401, 51369, 51338, 51307, 51276, 51244, 51213, 51182,
      51150, 51119, 51087, 51056, 51024, 50993, 50961, 50929,
      50898, 50866, 50834, 50803, 50771, 50739, 50707, 50675,
      50644, 50612, 50580, 50548, 50516, 50484, 50452, 50420,
      50387, 50355, 50323, 50291, 50259, 50226, 50194, 50162,
      50129, 50097, 50065, 50032, 50000, 49967, 49935, 49902,
      49869, 49837, 49804, 49771, 49739, 49706, 49673, 49640,
      49608, 49575, 49542, 49509, 49476, 49443, 49410, 49377,
      49344, 49311, 49278, 49244, 49211, 49178, 49145, 49112,
      49078, 49045, 49012, 48978, 48945, 48911, 48878, 48844,
      48811, 48777, 48744, 48710, 48676, 48643, 48609, 48575,
      48542, 48508, 48474, 48440, 48406, 48372, 48338, 48304,
      48271, 48237, 48202, 48168, 48134, 48100, 48066, 48032,
      47998, 47963, 47929, 47895, 47860, 47826, 47792, 47757,
      47723, 47688, 47654, 47619, 47585, 47550, 47516, 47481,
      47446, 47412, 47377, 47342, 47308, 47273, 47238, 47203,
      47168, 47133, 47098, 47063, 47028, 46993, 46958, 46923,
      46888, 46853, 46818, 46783, 46747, 46712, 46677, 46642,
      46606, 46571, 46536, 46500, 46465, 46429, 46394, 46358,
      46323, 46287, 46252, 46216, 46180, 46145, 46109, 46073,
      46037, 46002, 45966, 45930, 45894, 45858, 45822, 45786,
      45750, 45714, 45678, 45642, 45606, 45570, 45534, 45498,
      45462, 45425, 45389, 45353, 45316, 45280, 45244, 45207,
      45171, 45135, 45098, 45062, 45025, 44989, 44952, 44915,
      44879, 44842, 44806, 44769, 44732, 44695, 44659, 44622,
      44585, 44548, 44511, 44474, 44437, 44400, 44363, 44326,
      44289, 44252, 44215, 44178, 44141, 44104, 44067, 44029,
      43992, 43955, 43918, 43880, 43843, 43806, 43768, 43731,
      43693, 43656, 43618, 43581, 43543, 43506, 43468, 43430,
      43393, 43355, 43317, 43280, 43242, 43204, 43166, 43128,
      43091, 43053, 43015, 42977, 42939, 42901, 42863, 42825,
      42787, 42749, 42711, 42672, 42634, 42596, 42558, 42520,
      42481, 42443, 42405, 42366, 42328, 42290, 42251, 42213,
      42174, 42136, 42097, 42059, 42020, 41982, 41943, 41904,
      41866, 41827, 41788, 41750, 41711, 41672, 41633, 41595,
      41556, 41517, 41478, 41439, 41400, 41361, 41322, 41283,
      41244, 41205, 41166, 41127, 41088, 41048, 41009, 40970,
      40931, 40891, 40852, 40813, 40773, 40734, 40695, 40655,
      40616, 40576, 40537, 40497, 40458, 40418, 40379, 40339,
      40300, 40260, 40220, 40180, 40141, 40101, 40061, 40021,
      39982, 39942, 39902, 39862, 39822, 39782, 39742, 39702,
      39662, 39622, 39582, 39542, 39502, 39462, 39422, 39382,
      39341, 39301, 39261, 39221, 39180, 39140, 39100, 39059,
      39019, 38979, 38938, 38898, 38857, 38817, 38776, 38736,
      38695, 38655, 38614, 38573, 38533, 38492, 38451, 38411,
      38370, 38329, 38288, 38248, 38207, 38166, 38125, 38084,
      38043, 38002, 37961, 37920, 37879, 37838, 37797, 37756,
      37715, 37674, 37633, 37592, 37551, 37509, 37468, 37427,
      37386, 37344, 37303, 37262, 37220, 37179, 37137, 37096,
      37055, 37013, 36972, 36930, 36889, 36847, 36805, 36764,
      36722, 36681, 36639, 36597, 36556, 36514, 36472, 36430,
      36388, 36347, 36305, 36263, 36221, 36179, 36137, 36095,
      36053, 36011, 35969, 35927, 35885, 35843, 35801, 35759,
      35717, 35675, 35633, 35590, 35548, 35506, 35464, 35421,
      35379, 35337, 35294, 35252, 35210, 35167, 35125, 35082,
      35040, 34997, 34955, 34912, 34870, 34827, 34785, 34742,
      34699, 34657, 34614, 34571, 34529, 34486, 34443, 34400,
      34358, 34315, 34272, 34229, 34186, 34143, 34100, 34057,
      34015, 33972, 33929, 33886, 33843, 33799, 33756, 33713,
      33670, 33627, 33584, 33541, 33498, 33454, 33411, 33368,
      33325, 33281, 33238, 33195, 33151, 33108, 33065, 33021,
      32978, 32934, 32891, 32847, 32804, 32760, 32717, 32673,
      32630, 32586, 32542, 32499, 32455, 32411, 32368, 32324,
      32280, 32236, 32193, 32149, 32105, 32061, 32017, 31974,
      31930, 31886, 31842, 31798, 31754, 31710, 31666, 31622,
      31578, 31534, 31490, 31446, 31402, 31357, 31313, 31269,
      31225, 31181, 31136, 31092, 31048, 31004, 30959, 30915,
      30871, 30826, 30782, 30738, 30693, 30649, 30604, 30560,
      30515, 30471, 30426, 30382, 30337, 30293, 30248, 30204,
      30159, 30114, 30070, 30025, 29980, 29936, 29891, 29846,
      29801, 29757, 29712, 29667, 29622, 29577, 29533, 29488,
      29443, 29398, 29353, 29308, 29263, 29218, 29173, 29128,
      29083, 29038, 28993, 28948, 28903, 28858, 28812, 28767,
      28722, 28677, 28632, 28586, 28541, 28496, 28451, 28405,
      28360, 28315, 28269, 28224, 28179, 28133, 28088, 28042,
      27997, 27952, 27906, 27861, 27815, 27770, 27724, 27678,
      27633, 27587, 27542, 27496, 27450, 27405, 27359, 27313,
      27268, 27222, 27176, 27131, 27085, 27039, 26993, 26947,
      26902, 26856, 26810, 26764, 26718, 26672, 26626, 26580,
      26534, 26488, 26442, 26396, 26350, 26304, 26258, 26212,
      26166, 26120, 26074, 26028, 25982, 25936, 25889, 25843,
      25797, 25751, 25705, 25658, 25612, 25566, 25520, 25473,
      25427, 25381, 25334, 25288, 25241, 25195, 25149, 25102,
      25056, 25009, 24963, 24916, 24870, 24823, 24777, 24730,
      24684, 24637, 24591, 24544, 24497, 24451, 24404, 24357,
      24311, 24264, 24217, 24171, 24124, 24077, 24030, 23984,
      23937, 23890, 23843, 23796, 23750, 23703, 23656, 23609,
      23562, 23515, 23468, 23421, 23374, 23327, 23280, 23233,
      23186, 23139, 23092, 23045, 22998, 22951, 22904, 22857,
      22810, 22763, 22716, 22668, 22621, 22574, 22527, 22480,
      22433, 22385, 22338, 22291, 22243, 22196, 22149, 22102,
      22054, 22007, 21960, 21912, 21865, 21817, 21770, 21723,
      21675, 21628, 21580, 21533, 21485, 21438, 21390, 21343,
      21295, 21248, 21200, 21153, 21105, 21057, 21010, 20962,
      20915, 20867, 20819, 20772, 20724, 20676, 20629, 20581,
      20533, 20485, 20438, 20390, 20342, 20294, 20246, 20199,
      20151, 20103, 20055, 20007, 19959, 19912, 19864, 19816,
      19768, 19720, 19672, 19624, 19576, 19528, 19480, 19432,
      19384, 19336, 19288, 19240, 19192, 19144, 19096, 19048,
      19000, 18951, 18903, 18855, 18807, 18759, 18711, 18663,
      18614, 18566, 18518, 18470, 18421, 18373, 18325, 18277,
      18228, 18180, 18132, 18084, 18035, 17987, 17939, 17890,
      17842, 17793, 17745, 17697, 17648, 17600, 17551, 17503,
      17455, 17406, 17358, 17309, 17261, 17212, 17164, 17115,
      17067, 17018, 16970, 16921, 16872, 16824, 16775, 16727,
      16678, 16629, 16581, 16532, 16484, 16435, 16386, 16338,
      16289, 16240, 16191, 16143, 16094, 16045, 15997, 15948,
      15899, 15850, 15802, 15753, 15704, 15655, 15606, 15557,
      15509, 15460, 15411, 15362, 15313, 15264, 15215, 15167,
      15118, 15069, 15020, 14971, 14922, 14873, 14824, 14775,
      14726, 14677, 14628, 14579, 14530, 14481, 14432, 14383,
      14334, 14285, 14236, 14187, 14138, 14089, 14040, 13990,
      13941, 13892, 13843, 13794, 13745, 13696, 13646, 13597,
      13548, 13499, 13450, 13401, 13351, 13302, 13253, 13204,
      13154, 13105, 13056, 13007, 12957, 12908, 12859, 12810,
      12760, 12711, 12662, 12612, 12563, 12514, 12464, 12415,
      12366, 12316, 12267, 12218, 12168, 12119, 12069, 12020,
      11970, 11921, 11872, 11822, 11773, 11723, 11674, 11624,
      11575, 11525, 11476, 11426, 11377, 11327, 11278, 11228,
      11179, 11129, 11080, 11030, 10981, 10931, 10882, 10832,
      10782, 10733, 10683, 10634, 10584, 10534, 10485, 10435,
      10386, 10336, 10286, 10237, 10187, 10137, 10088, 10038,
      9988, 9939, 9889, 9839, 9790, 9740, 9690, 9640,
      9591, 9541, 9491, 9442, 9392, 9342, 9292, 9243,
      9193, 9143, 9093, 9043, 8994, 8944, 8894, 8844,
      8794, 8745, 8695, 8645, 8595, 8545, 8496, 8446,
      8396, 8346, 8296, 8246, 8196, 8147, 8097, 8047,
      7997, 7947, 7897, 7847, 7797, 7747, 7697, 7648,
      7598, 7548, 7498, 7448, 7398, 7348, 7298, 7248,
      7198, 7148, 7098, 7048, 6998, 6948, 6898, 6848,
      6798, 6748, 6698, 6648, 6598, 6548, 6498, 6448,
      6398, 6348, 6298, 6248, 6198, 6148, 6098, 6048,
      5998, 5948, 5898, 5848, 5798, 5748, 5697, 5647,
      5597, 5547, 5497, 5447, 5397, 5347, 5297, 5247,
      5197, 5146, 5096, 5046, 4996, 4946, 4896, 4846,
      4796, 4745, 4695, 4645, 4595, 4545, 4495, 4445,
      4394, 4344, 4294, 4244, 4194, 4144, 4093, 4043,
      3993, 3943, 3893, 3843, 3792, 3742, 3692, 3642,
      3592, 3541, 3491, 3441, 3391, 3341, 3291, 3240,
      3190, 3140, 3090, 3039, 2989, 2939, 2889, 2839,
      2788, 2738, 2688, 2638, 2587, 2537, 2487, 2437,
      2387, 2336, 2286, 2236, 2186, 2135, 2085, 2035,
      1985, 1934, 1884, 1834, 1784, 1733, 1683, 1633,
      1583, 1532, 1482, 1432, 1382, 1331, 1281, 1231,
      1181, 1130, 1080, 1030, 980, 929, 879, 829,
      779, 728, 678, 628, 578, 527, 477, 427,
      376, 326, 276, 226, 175, 125, 75, 25,
      -25, -75, -125, -175, -226, -276, -326, -376,
      -427, -477, -527, -578, -628, -678, -728, -779,
      -829, -879, -929, -980, -1030, -1080, -1130, -1181,
      -1231, -1281, -1331, -1382, -1432, -1482, -1532, -1583,
      -1633, -1683, -1733, -1784, -1834, -1884, -1934, -1985,
      -2035, -2085, -2135, -2186, -2236, -2286, -2336, -2387,
      -2437, -2487, -2537, -2588, -2638, -2688, -2738, -2788,
      -2839, -2889, -2939, -2989, -3039, -3090, -3140, -3190,
      -3240, -3291, -3341, -3391, -3441, -3491, -3541, -3592,
      -3642, -3692, -3742, -3792, -3843, -3893, -3943, -3993,
      -4043, -4093, -4144, -4194, -4244, -4294, -4344, -4394,
      -4445, -4495, -4545, -4595, -4645, -4695, -4745, -4796,
      -4846, -4896, -4946, -4996, -5046, -5096, -5146, -5197,
      -5247, -5297, -5347, -5397, -5447, -5497, -5547, -5597,
      -5647, -5697, -5748, -5798, -5848, -5898, -5948, -5998,
      -6048, -6098, -6148, -6198, -6248, -6298, -6348, -6398,
      -6448, -6498, -6548, -6598, -6648, -6698, -6748, -6798,
      -6848, -6898, -6948, -6998, -7048, -7098, -7148, -7198,
      -7248, -7298, -7348, -7398, -7448, -7498, -7548, -7598,
      -7648, -7697, -7747, -7797, -7847, -7897, -7947, -7997,
      -8047, -8097, -8147, -8196, -8246, -8296, -8346, -8396,
      -8446, -8496, -8545, -8595, -8645, -8695, -8745, -8794,
      -8844, -8894, -8944, -8994, -9043, -9093, -9143, -9193,
      -9243, -9292, -9342, -9392, -9442, -9491, -9541, -9591,
      -9640, -9690, -9740, -9790, -9839, -9889, -9939, -9988,
      -10038, -10088, -10137, -10187, -10237, -10286, -10336, -10386,
      -10435, -10485, -10534, -10584, -10634, -10683, -10733, -10782,
      -10832, -10882, -10931, -10981, -11030, -11080, -11129, -11179,
      -11228, -11278, -11327, -11377, -11426, -11476, -11525, -11575,
      -11624, -11674, -11723, -11773, -11822, -11872, -11921, -11970,
      -12020, -12069, -12119, -12168, -12218, -12267, -12316, -12366,
      -12415, -12464, -12514, -12563, -12612, -12662, -12711, -12760,
      -12810, -12859, -12908, -12957, -13007, -13056, -13105, -13154,
      -13204, -13253, -13302, -13351, -13401, -13450, -13499, -13548,
      -13597, -13647, -13696, -13745, -13794, -13843, -13892, -13941,
      -13990, -14040, -14089, -14138, -14187, -14236, -14285, -14334,
      -14383, -14432, -14481, -14530, -14579, -14628, -14677, -14726,
      -14775, -14824, -14873, -14922, -14971, -15020, -15069, -15118,
      -15167, -15215, -15264, -15313, -15362, -15411, -15460, -15509,
      -15557, -15606, -15655, -15704, -15753, -15802, -15850, -15899,
      -15948, -15997, -16045, -16094, -16143, -16191, -16240, -16289,
      -16338, -16386, -16435, -16484, -16532, -16581, -16629, -16678,
      -16727, -16775, -16824, -16872, -16921, -16970, -17018, -17067,
      -17115, -17164, -17212, -17261, -17309, -17358, -17406, -17455,
      -17503, -17551, -17600, -17648, -17697, -17745, -17793, -17842,
      -17890, -17939, -17987, -18035, -18084, -18132, -18180, -18228,
      -18277, -18325, -18373, -18421, -18470, -18518, -18566, -18614,
      -18663, -18711, -18759, -18807, -18855, -18903, -18951, -19000,
      -19048, -19096, -19144, -19192, -19240, -19288, -19336, -19384,
      -19432, -19480, -19528, -19576, -19624, -19672, -19720, -19768,
      -19816, -19864, -19912, -19959, -20007, -20055, -20103, -20151,
      -20199, -20246, -20294, -20342, -20390, -20438, -20485, -20533,
      -20581, -20629, -20676, -20724, -20772, -20819, -20867, -20915,
      -20962, -21010, -21057, -21105, -21153, -21200, -21248, -21295,
      -21343, -21390, -21438, -21485, -21533, -21580, -21628, -21675,
      -21723, -21770, -21817, -21865, -21912, -21960, -22007, -22054,
      -22102, -22149, -22196, -22243, -22291, -22338, -22385, -22433,
      -22480, -22527, -22574, -22621, -22668, -22716, -22763, -22810,
      -22857, -22904, -22951, -22998, -23045, -23092, -23139, -23186,
      -23233, -23280, -23327, -23374, -23421, -23468, -23515, -23562,
      -23609, -23656, -23703, -23750, -23796, -23843, -23890, -23937,
      -23984, -24030, -24077, -24124, -24171, -24217, -24264, -24311,
      -24357, -24404, -24451, -24497, -24544, -24591, -24637, -24684,
      -24730, -24777, -24823, -24870, -24916, -24963, -25009, -25056,
      -25102, -25149, -25195, -25241, -25288, -25334, -25381, -25427,
      -25473, -25520, -25566, -25612, -25658, -25705, -25751, -25797,
      -25843, -25889, -25936, -25982, -26028, -26074, -26120, -26166,
      -26212, -26258, -26304, -26350, -26396, -26442, -26488, -26534,
      -26580, -26626, -26672, -26718, -26764, -26810, -26856, -26902,
      -26947, -26993, -27039, -27085, -27131, -27176, -27222, -27268,
      -27313, -27359, -27405, -27450, -27496, -27542, -27587, -27633,
      -27678, -27724, -27770, -27815, -27861, -27906, -27952, -27997,
      -28042, -28088, -28133, -28179, -28224, -28269, -28315, -28360,
      -28405, -28451, -28496, -28541, -28586, -28632, -28677, -28722,
      -28767, -28812, -28858, -28903, -28948, -28993, -29038, -29083,
      -29128, -29173, -29218, -29263, -29308, -29353, -29398, -29443,
      -29488, -29533, -29577, -29622, -29667, -29712, -29757, -29801,
      -29846, -29891, -29936, -29980, -30025, -30070, -30114, -30159,
      -30204, -30248, -30293, -30337, -30382, -30426, -30471, -30515,
      -30560, -30604, -30649, -30693, -30738, -30782, -30826, -30871,
      -30915, -30959, -31004, -31048, -31092, -31136, -31181, -31225,
      -31269, -31313, -31357, -31402, -31446, -31490, -31534, -31578,
      -31622, -31666, -31710, -31754, -31798, -31842, -31886, -31930,
      -31974, -32017, -32061, -32105, -32149, -32193, -32236, -32280,
      -32324, -32368, -32411, -32455, -32499, -32542, -32586, -32630,
      -32673, -32717, -32760, -32804, -32847, -32891, -32934, -32978,
      -33021, -33065, -33108, -33151, -33195, -33238, -33281, -33325,
      -33368, -33411, -33454, -33498, -33541, -33584, -33627, -33670,
      -33713, -33756, -33799, -33843, -33886, -33929, -33972, -34015,
      -34057, -34100, -34143, -34186, -34229, -34272, -34315, -34358,
      -34400, -34443, -34486, -34529, -34571, -34614, -34657, -34699,
      -34742, -34785, -34827, -34870, -34912, -34955, -34997, -35040,
      -35082, -35125, -35167, -35210, -35252, -35294, -35337, -35379,
      -35421, -35464, -35506, -35548, -35590, -35633, -35675, -35717,
      -35759, -35801, -35843, -35885, -35927, -35969, -36011, -36053,
      -36095, -36137, -36179, -36221, -36263, -36305, -36347, -36388,
      -36430, -36472, -36514, -36555, -36597, -36639, -36681, -36722,
      -36764, -36805, -36847, -36889, -36930, -36972, -37013, -37055,
      -37096, -37137, -37179, -37220, -37262, -37303, -37344, -37386,
      -37427, -37468, -37509, -37551, -37592, -37633, -37674, -37715,
      -37756, -37797, -37838, -37879, -37920, -37961, -38002, -38043,
      -38084, -38125, -38166, -38207, -38248, -38288, -38329, -38370,
      -38411, -38451, -38492, -38533, -38573, -38614, -38655, -38695,
      -38736, -38776, -38817, -38857, -38898, -38938, -38979, -39019,
      -39059, -39100, -39140, -39180, -39221, -39261, -39301, -39341,
      -39382, -39422, -39462, -39502, -39542, -39582, -39622, -39662,
      -39702, -39742, -39782, -39822, -39862, -39902, -39942, -39982,
      -40021, -40061, -40101, -40141, -40180, -40220, -40260, -40299,
      -40339, -40379, -40418, -40458, -40497, -40537, -40576, -40616,
      -40655, -40695, -40734, -40773, -40813, -40852, -40891, -40931,
      -40970, -41009, -41048, -41087, -41127, -41166, -41205, -41244,
      -41283, -41322, -41361, -41400, -41439, -41478, -41517, -41556,
      -41595, -41633, -41672, -41711, -41750, -41788, -41827, -41866,
      -41904, -41943, -41982, -42020, -42059, -42097, -42136, -42174,
      -42213, -42251, -42290, -42328, -42366, -42405, -42443, -42481,
      -42520, -42558, -42596, -42634, -42672, -42711, -42749, -42787,
      -42825, -42863, -42901, -42939, -42977, -43015, -43053, -43091,
      -43128, -43166, -43204, -43242, -43280, -43317, -43355, -43393,
      -43430, -43468, -43506, -43543, -43581, -43618, -43656, -43693,
      -43731, -43768, -43806, -43843, -43880, -43918, -43955, -43992,
      -44029, -44067, -44104, -44141, -44178, -44215, -44252, -44289,
      -44326, -44363, -44400, -44437, -44474, -44511, -44548, -44585,
      -44622, -44659, -44695, -44732, -44769, -44806, -44842, -44879,
      -44915, -44952, -44989, -45025, -45062, -45098, -45135, -45171,
      -45207, -45244, -45280, -45316, -45353, -45389, -45425, -45462,
      -45498, -45534, -45570, -45606, -45642, -45678, -45714, -45750,
      -45786, -45822, -45858, -45894, -45930, -45966, -46002, -46037,
      -46073, -46109, -46145, -46180, -46216, -46252, -46287, -46323,
      -46358, -46394, -46429, -46465, -46500, -46536, -46571, -46606,
      -46642, -46677, -46712, -46747, -46783, -46818, -46853, -46888,
      -46923, -46958, -46993, -47028, -47063, -47098, -47133, -47168,
      -47203, -47238, -47273, -47308, -47342, -47377, -47412, -47446,
      -47481, -47516, -47550, -47585, -47619, -47654, -47688, -47723,
      -47757, -47792, -47826, -47860, -47895, -47929, -47963, -47998,
      -48032, -48066, -48100, -48134, -48168, -48202, -48236, -48271,
      -48304, -48338, -48372, -48406, -48440, -48474, -48508, -48542,
      -48575, -48609, -48643, -48676, -48710, -48744, -48777, -48811,
      -48844, -48878, -48911, -48945, -48978, -49012, -49045, -49078,
      -49112, -49145, -49178, -49211, -49244, -49278, -49311, -49344,
      -49377, -49410, -49443, -49476, -49509, -49542, -49575, -49608,
      -49640, -49673, -49706, -49739, -49771, -49804, -49837, -49869,
      -49902, -49935, -49967, -50000, -50032, -50065, -50097, -50129,
      -50162, -50194, -50226, -50259, -50291, -50323, -50355, -50387,
      -50420, -50452, -50484, -50516, -50548, -50580, -50612, -50644,
      -50675, -50707, -50739, -50771, -50803, -50834, -50866, -50898,
      -50929, -50961, -50993, -51024, -51056, -51087, -51119, -51150,
      -51182, -51213, -51244, -51276, -51307, -51338, -51369, -51401,
      -51432, -51463, -51494, -51525, -51556, -51587, -51618, -51649,
      -51680, -51711, -51742, -51773, -51803, -51834, -51865, -51896,
      -51926, -51957, -51988, -52018, -52049, -52079, -52110, -52140,
      -52171, -52201, -52231, -52262, -52292, -52322, -52353, -52383,
      -52413, -52443, -52473, -52503, -52534, -52564, -52594, -52624,
      -52653, -52683, -52713, -52743, -52773, -52803, -52832, -52862,
      -52892, -52922, -52951, -52981, -53010, -53040, -53069, -53099,
      -53128, -53158, -53187, -53216, -53246, -53275, -53304, -53334,
      -53363, -53392, -53421, -53450, -53479, -53508, -53537, -53566,
      -53595, -53624, -53653, -53682, -53711, -53739, -53768, -53797,
      -53826, -53854, -53883, -53911, -53940, -53969, -53997, -54026,
      -54054, -54082, -54111, -54139, -54167, -54196, -54224, -54252,
      -54280, -54308, -54337, -54365, -54393, -54421, -54449, -54477,
      -54505, -54533, -54560, -54588, -54616, -54644, -54672, -54699,
      -54727, -54755, -54782, -54810, -54837, -54865, -54892, -54920,
      -54947, -54974, -55002, -55029, -55056, -55084, -55111, -55138,
      -55165, -55192, -55219, -55246, -55274, -55300, -55327, -55354,
      -55381, -55408, -55435, -55462, -55489, -55515, -55542, -55569,
      -55595, -55622, -55648, -55675, -55701, -55728, -55754, -55781,
      -55807, -55833, -55860, -55886, -55912, -55938, -55965, -55991,
      -56017, -56043, -56069, -56095, -56121, -56147, -56173, -56199,
      -56225, -56250, -56276, -56302, -56328, -56353, -56379, -56404,
      -56430, -56456, -56481, -56507, -56532, -56557, -56583, -56608,
      -56633, -56659, -56684, -56709, -56734, -56760, -56785, -56810,
      -56835, -56860, -56885, -56910, -56935, -56959, -56984, -57009,
      -57034, -57059, -57083, -57108, -57133, -57157, -57182, -57206,
      -57231, -57255, -57280, -57304, -57329, -57353, -57377, -57402,
      -57426, -57450, -57474, -57498, -57522, -57546, -57570, -57594,
      -57618, -57642, -57666, -57690, -57714, -57738, -57762, -57785,
      -57809, -57833, -57856, -57880, -57903, -57927, -57950, -57974,
      -57997, -58021, -58044, -58067, -58091, -58114, -58137, -58160,
      -58183, -58207, -58230, -58253, -58276, -58299, -58322, -58345,
      -58367, -58390, -58413, -58436, -58459, -58481, -58504, -58527,
      -58549, -58572, -58594, -58617, -58639, -58662, -58684, -58706,
      -58729, -58751, -58773, -58795, -58818, -58840, -58862, -58884,
      -58906, -58928, -58950, -58972, -58994, -59016, -59038, -59059,
      -59081, -59103, -59125, -59146, -59168, -59190, -59211, -59233,
      -59254, -59276, -59297, -59318, -59340, -59361, -59382, -59404,
      -59425, -59446, -59467, -59488, -59509, -59530, -59551, -59572,
      -59593, -59614, -59635, -59656, -59677, -59697, -59718, -59739,
      -59759, -59780, -59801, -59821, -59842, -59862, -59883, -59903,
      -59923, -59944, -59964, -59984, -60004, -60025, -60045, -60065,
      -60085, -60105, -60125, -60145, -60165, -60185, -60205, -60225,
      -60244, -60264, -60284, -60304, -60323, -60343, -60363, -60382,
      -60402, -60421, -60441, -60460, -60479, -60499, -60518, -60537,
      -60556, -60576, -60595, -60614, -60633, -60652, -60671, -60690,
      -60709, -60728, -60747, -60766, -60785, -60803, -60822, -60841,
      -60859, -60878, -60897, -60915, -60934, -60952, -60971, -60989,
      -61007, -61026, -61044, -61062, -61081, -61099, -61117, -61135,
      -61153, -61171, -61189, -61207, -61225, -61243, -61261, -61279,
      -61297, -61314, -61332, -61350, -61367, -61385, -61403, -61420,
      -61438, -61455, -61473, -61490, -61507, -61525, -61542, -61559,
      -61577, -61594, -61611, -61628, -61645, -61662, -61679, -61696,
      -61713, -61730, -61747, -61764, -61780, -61797, -61814, -61831,
      -61847, -61864, -61880, -61897, -61913, -61930, -61946, -61963,
      -61979, -61995, -62012, -62028, -62044, -62060, -62076, -62092,
      -62108, -62125, -62141, -62156, -62172, -62188, -62204, -62220,
      -62236, -62251, -62267, -62283, -62298, -62314, -62329, -62345,
      -62360, -62376, -62391, -62407, -62422, -62437, -62453, -62468,
      -62483, -62498, -62513, -62528, -62543, -62558, -62573, -62588,
      -62603, -62618, -62633, -62648, -62662, -62677, -62692, -62706,
      -62721, -62735, -62750, -62764, -62779, -62793, -62808, -62822,
      -62836, -62850, -62865, -62879, -62893, -62907, -62921, -62935,
      -62949, -62963, -62977, -62991, -63005, -63019, -63032, -63046,
      -63060, -63074, -63087, -63101, -63114, -63128, -63141, -63155,
      -63168, -63182, -63195, -63208, -63221, -63235, -63248, -63261,
      -63274, -63287, -63300, -63313, -63326, -63339, -63352, -63365,
      -63378, -63390, -63403, -63416, -63429, -63441, -63454, -63466,
      -63479, -63491, -63504, -63516, -63528, -63541, -63553, -63565,
      -63578, -63590, -63602, -63614, -63626, -63638, -63650, -63662,
      -63674, -63686, -63698, -63709, -63721, -63733, -63745, -63756,
      -63768, -63779, -63791, -63803, -63814, -63825, -63837, -63848,
      -63859, -63871, -63882, -63893, -63904, -63915, -63927, -63938,
      -63949, -63960, -63971, -63981, -63992, -64003, -64014, -64025,
      -64035, -64046, -64057, -64067, -64078, -64088, -64099, -64109,
      -64120, -64130, -64140, -64151, -64161, -64171, -64181, -64192,
      -64202, -64212, -64222, -64232, -64242, -64252, -64261, -64271,
      -64281, -64291, -64301, -64310, -64320, -64330, -64339, -64349,
      -64358, -64368, -64377, -64387, -64396, -64405, -64414, -64424,
      -64433, -64442, -64451, -64460, -64469, -64478, -64487, -64496,
      -64505, -64514, -64523, -64532, -64540, -64549, -64558, -64566,
      -64575, -64584, -64592, -64601, -64609, -64617, -64626, -64634,
      -64642, -64651, -64659, -64667, -64675, -64683, -64691, -64699,
      -64707, -64715, -64723, -64731, -64739, -64747, -64754, -64762,
      -64770, -64777, -64785, -64793, -64800, -64808, -64815, -64822,
      -64830, -64837, -64844, -64852, -64859, -64866, -64873, -64880,
      -64887, -64895, -64902, -64908, -64915, -64922, -64929, -64936,
      -64943, -64949, -64956, -64963, -64969, -64976, -64982, -64989,
      -64995, -65002, -65008, -65015, -65021, -65027, -65033, -65040,
      -65046, -65052, -65058, -65064, -65070, -65076, -65082, -65088,
      -65094, -65099, -65105, -65111, -65117, -65122, -65128, -65133,
      -65139, -65144, -65150, -65155, -65161, -65166, -65171, -65177,
      -65182, -65187, -65192, -65197, -65202, -65207, -65212, -65217,
      -65222, -65227, -65232, -65237, -65242, -65246, -65251, -65256,
      -65260, -65265, -65270, -65274, -65279, -65283, -65287, -65292,
      -65296, -65300, -65305, -65309, -65313, -65317, -65321, -65325,
      -65329, -65333, -65337, -65341, -65345, -65349, -65352, -65356,
      -65360, -65363, -65367, -65371, -65374, -65378, -65381, -65385,
      -65388, -65391, -65395, -65398, -65401, -65404, -65408, -65411,
      -65414, -65417, -65420, -65423, -65426, -65429, -65431, -65434,
      -65437, -65440, -65442, -65445, -65448, -65450, -65453, -65455,
      -65458, -65460, -65463, -65465, -65467, -65470, -65472, -65474,
      -65476, -65478, -65480, -65482, -65484, -65486, -65488, -65490,
      -65492, -65494, -65496, -65497, -65499, -65501, -65502, -65504,
      -65505, -65507, -65508, -65510, -65511, -65513, -65514, -65515,
      -65516, -65518, -65519, -65520, -65521, -65522, -65523, -65524,
      -65525, -65526, -65527, -65527, -65528, -65529, -65530, -65530,
      -65531, -65531, -65532, -65532, -65533, -65533, -65534, -65534,
      -65534, -65535, -65535, -65535, -65535, -65535, -65535, -65535,
      -65535, -65535, -65535, -65535, -65535, -65535, -65535, -65534,
      -65534, -65534, -65533, -65533, -65532, -65532, -65531, -65531,
      -65530, -65530, -65529, -65528, -65527, -65527, -65526, -65525,
      -65524, -65523, -65522, -65521, -65520, -65519, -65518, -65516,
      -65515, -65514, -65513, -65511, -65510, -65508, -65507, -65505,
      -65504, -65502, -65501, -65499, -65497, -65496, -65494, -65492,
      -65490, -65488, -65486, -65484, -65482, -65480, -65478, -65476,
      -65474, -65472, -65470, -65467, -65465, -65463, -65460, -65458,
      -65455, -65453, -65450, -65448, -65445, -65442, -65440, -65437,
      -65434, -65431, -65429, -65426, -65423, -65420, -65417, -65414,
      -65411, -65408, -65404, -65401, -65398, -65395, -65391, -65388,
      -65385, -65381, -65378, -65374, -65371, -65367, -65363, -65360,
      -65356, -65352, -65349, -65345, -65341, -65337, -65333, -65329,
      -65325, -65321, -65317, -65313, -65309, -65305, -65300, -65296,
      -65292, -65287, -65283, -65279, -65274, -65270, -65265, -65260,
      -65256, -65251, -65246, -65242, -65237, -65232, -65227, -65222,
      -65217, -65212, -65207, -65202, -65197, -65192, -65187, -65182,
      -65177, -65171, -65166, -65161, -65155, -65150, -65144, -65139,
      -65133, -65128, -65122, -65117, -65111, -65105, -65099, -65094,
      -65088, -65082, -65076, -65070, -65064, -65058, -65052, -65046,
      -65040, -65033, -65027, -65021, -65015, -65008, -65002, -64995,
      -64989, -64982, -64976, -64969, -64963, -64956, -64949, -64943,
      -64936, -64929, -64922, -64915, -64908, -64902, -64895, -64887,
      -64880, -64873, -64866, -64859, -64852, -64844, -64837, -64830,
      -64822, -64815, -64808, -64800, -64793, -64785, -64777, -64770,
      -64762, -64754, -64747, -64739, -64731, -64723, -64715, -64707,
      -64699, -64691, -64683, -64675, -64667, -64659, -64651, -64642,
      -64634, -64626, -64617, -64609, -64601, -64592, -64584, -64575,
      -64566, -64558, -64549, -64540, -64532, -64523, -64514, -64505,
      -64496, -64487, -64478, -64469, -64460, -64451, -64442, -64433,
      -64424, -64414, -64405, -64396, -64387, -64377, -64368, -64358,
      -64349, -64339, -64330, -64320, -64310, -64301, -64291, -64281,
      -64271, -64261, -64252, -64242, -64232, -64222, -64212, -64202,
      -64192, -64181, -64171, -64161, -64151, -64140, -64130, -64120,
      -64109, -64099, -64088, -64078, -64067, -64057, -64046, -64035,
      -64025, -64014, -64003, -63992, -63981, -63971, -63960, -63949,
      -63938, -63927, -63915, -63904, -63893, -63882, -63871, -63859,
      -63848, -63837, -63825, -63814, -63803, -63791, -63779, -63768,
      -63756, -63745, -63733, -63721, -63709, -63698, -63686, -63674,
      -63662, -63650, -63638, -63626, -63614, -63602, -63590, -63578,
      -63565, -63553, -63541, -63528, -63516, -63504, -63491, -63479,
      -63466, -63454, -63441, -63429, -63416, -63403, -63390, -63378,
      -63365, -63352, -63339, -63326, -63313, -63300, -63287, -63274,
      -63261, -63248, -63235, -63221, -63208, -63195, -63182, -63168,
      -63155, -63141, -63128, -63114, -63101, -63087, -63074, -63060,
      -63046, -63032, -63019, -63005, -62991, -62977, -62963, -62949,
      -62935, -62921, -62907, -62893, -62879, -62865, -62850, -62836,
      -62822, -62808, -62793, -62779, -62764, -62750, -62735, -62721,
      -62706, -62692, -62677, -62662, -62648, -62633, -62618, -62603,
      -62588, -62573, -62558, -62543, -62528, -62513, -62498, -62483,
      -62468, -62453, -62437, -62422, -62407, -62391, -62376, -62360,
      -62345, -62329, -62314, -62298, -62283, -62267, -62251, -62236,
      -62220, -62204, -62188, -62172, -62156, -62141, -62125, -62108,
      -62092, -62076, -62060, -62044, -62028, -62012, -61995, -61979,
      -61963, -61946, -61930, -61913, -61897, -61880, -61864, -61847,
      -61831, -61814, -61797, -61780, -61764, -61747, -61730, -61713,
      -61696, -61679, -61662, -61645, -61628, -61611, -61594, -61577,
      -61559, -61542, -61525, -61507, -61490, -61473, -61455, -61438,
      -61420, -61403, -61385, -61367, -61350, -61332, -61314, -61297,
      -61279, -61261, -61243, -61225, -61207, -61189, -61171, -61153,
      -61135, -61117, -61099, -61081, -61062, -61044, -61026, -61007,
      -60989, -60971, -60952, -60934, -60915, -60897, -60878, -60859,
      -60841, -60822, -60803, -60785, -60766, -60747, -60728, -60709,
      -60690, -60671, -60652, -60633, -60614, -60595, -60576, -60556,
      -60537, -60518, -60499, -60479, -60460, -60441, -60421, -60402,
      -60382, -60363, -60343, -60323, -60304, -60284, -60264, -60244,
      -60225, -60205, -60185, -60165, -60145, -60125, -60105, -60085,
      -60065, -60045, -60025, -60004, -59984, -59964, -59944, -59923,
      -59903, -59883, -59862, -59842, -59821, -59801, -59780, -59759,
      -59739, -59718, -59697, -59677, -59656, -59635, -59614, -59593,
      -59572, -59551, -59530, -59509, -59488, -59467, -59446, -59425,
      -59404, -59382, -59361, -59340, -59318, -59297, -59276, -59254,
      -59233, -59211, -59189, -59168, -59146, -59125, -59103, -59081,
      -59059, -59038, -59016, -58994, -58972, -58950, -58928, -58906,
      -58884, -58862, -58840, -58818, -58795, -58773, -58751, -58729,
      -58706, -58684, -58662, -58639, -58617, -58594, -58572, -58549,
      -58527, -58504, -58481, -58459, -58436, -58413, -58390, -58367,
      -58345, -58322, -58299, -58276, -58253, -58230, -58207, -58183,
      -58160, -58137, -58114, -58091, -58067, -58044, -58021, -57997,
      -57974, -57950, -57927, -57903, -57880, -57856, -57833, -57809,
      -57785, -57762, -57738, -57714, -57690, -57666, -57642, -57618,
      -57594, -57570, -57546, -57522, -57498, -57474, -57450, -57426,
      -57402, -57377, -57353, -57329, -57304, -57280, -57255, -57231,
      -57206, -57182, -57157, -57133, -57108, -57083, -57059, -57034,
      -57009, -56984, -56959, -56935, -56910, -56885, -56860, -56835,
      -56810, -56785, -56760, -56734, -56709, -56684, -56659, -56633,
      -56608, -56583, -56557, -56532, -56507, -56481, -56456, -56430,
      -56404, -56379, -56353, -56328, -56302, -56276, -56250, -56225,
      -56199, -56173, -56147, -56121, -56095, -56069, -56043, -56017,
      -55991, -55965, -55938, -55912, -55886, -55860, -55833, -55807,
      -55781, -55754, -55728, -55701, -55675, -55648, -55622, -55595,
      -55569, -55542, -55515, -55489, -55462, -55435, -55408, -55381,
      -55354, -55327, -55300, -55274, -55246, -55219, -55192, -55165,
      -55138, -55111, -55084, -55056, -55029, -55002, -54974, -54947,
      -54920, -54892, -54865, -54837, -54810, -54782, -54755, -54727,
      -54699, -54672, -54644, -54616, -54588, -54560, -54533, -54505,
      -54477, -54449, -54421, -54393, -54365, -54337, -54308, -54280,
      -54252, -54224, -54196, -54167, -54139, -54111, -54082, -54054,
      -54026, -53997, -53969, -53940, -53911, -53883, -53854, -53826,
      -53797, -53768, -53739, -53711, -53682, -53653, -53624, -53595,
      -53566, -53537, -53508, -53479, -53450, -53421, -53392, -53363,
      -53334, -53304, -53275, -53246, -53216, -53187, -53158, -53128,
      -53099, -53069, -53040, -53010, -52981, -52951, -52922, -52892,
      -52862, -52832, -52803, -52773, -52743, -52713, -52683, -52653,
      -52624, -52594, -52564, -52534, -52503, -52473, -52443, -52413,
      -52383, -52353, -52322, -52292, -52262, -52231, -52201, -52171,
      -52140, -52110, -52079, -52049, -52018, -51988, -51957, -51926,
      -51896, -51865, -51834, -51803, -51773, -51742, -51711, -51680,
      -51649, -51618, -51587, -51556, -51525, -51494, -51463, -51432,
      -51401, -51369, -51338, -51307, -51276, -51244, -51213, -51182,
      -51150, -51119, -51087, -51056, -51024, -50993, -50961, -50929,
      -50898, -50866, -50834, -50803, -50771, -50739, -50707, -50675,
      -50644, -50612, -50580, -50548, -50516, -50484, -50452, -50420,
      -50387, -50355, -50323, -50291, -50259, -50226, -50194, -50162,
      -50129, -50097, -50065, -50032, -50000, -49967, -49935, -49902,
      -49869, -49837, -49804, -49771, -49739, -49706, -49673, -49640,
      -49608, -49575, -49542, -49509, -49476, -49443, -49410, -49377,
      -49344, -49311, -49278, -49244, -49211, -49178, -49145, -49112,
      -49078, -49045, -49012, -48978, -48945, -48911, -48878, -48844,
      -48811, -48777, -48744, -48710, -48676, -48643, -48609, -48575,
      -48542, -48508, -48474, -48440, -48406, -48372, -48338, -48305,
      -48271, -48237, -48202, -48168, -48134, -48100, -48066, -48032,
      -47998, -47963, -47929, -47895, -47860, -47826, -47792, -47757,
      -47723, -47688, -47654, -47619, -47585, -47550, -47516, -47481,
      -47446, -47412, -47377, -47342, -47307, -47273, -47238, -47203,
      -47168, -47133, -47098, -47063, -47028, -46993, -46958, -46923,
      -46888, -46853, -46818, -46783, -46747, -46712, -46677, -46642,
      -46606, -46571, -46536, -46500, -46465, -46429, -46394, -46358,
      -46323, -46287, -46251, -46216, -46180, -46145, -46109, -46073,
      -46037, -46002, -45966, -45930, -45894, -45858, -45822, -45786,
      -45750, -45714, -45678, -45642, -45606, -45570, -45534, -45498,
      -45462, -45425, -45389, -45353, -45316, -45280, -45244, -45207,
      -45171, -45135, -45098, -45062, -45025, -44989, -44952, -44915,
      -44879, -44842, -44806, -44769, -44732, -44695, -44659, -44622,
      -44585, -44548, -44511, -44474, -44437, -44400, -44363, -44326,
      -44289, -44252, -44215, -44178, -44141, -44104, -44067, -44029,
      -43992, -43955, -43918, -43880, -43843, -43806, -43768, -43731,
      -43693, -43656, -43618, -43581, -43543, -43506, -43468, -43430,
      -43393, -43355, -43317, -43280, -43242, -43204, -43166, -43128,
      -43091, -43053, -43015, -42977, -42939, -42901, -42863, -42825,
      -42787, -42749, -42711, -42672, -42634, -42596, -42558, -42520,
      -42481, -42443, -42405, -42366, -42328, -42290, -42251, -42213,
      -42174, -42136, -42097, -42059, -42020, -41982, -41943, -41904,
      -41866, -41827, -41788, -41750, -41711, -41672, -41633, -41595,
      -41556, -41517, -41478, -41439, -41400, -41361, -41322, -41283,
      -41244, -41205, -41166, -41127, -41087, -41048, -41009, -40970,
      -40931, -40891, -40852, -40813, -40773, -40734, -40695, -40655,
      -40616, -40576, -40537, -40497, -40458, -40418, -40379, -40339,
      -40299, -40260, -40220, -40180, -40141, -40101, -40061, -40021,
      -39982, -39942, -39902, -39862, -39822, -39782, -39742, -39702,
      -39662, -39622, -39582, -39542, -39502, -39462, -39422, -39382,
      -39341, -39301, -39261, -39221, -39180, -39140, -39100, -39059,
      -39019, -38979, -38938, -38898, -38857, -38817, -38776, -38736,
      -38695, -38655, -38614, -38573, -38533, -38492, -38451, -38411,
      -38370, -38329, -38288, -38248, -38207, -38166, -38125, -38084,
      -38043, -38002, -37961, -37920, -37879, -37838, -37797, -37756,
      -37715, -37674, -37633, -37592, -37550, -37509, -37468, -37427,
      -37386, -37344, -37303, -37262, -37220, -37179, -37137, -37096,
      -37055, -37013, -36972, -36930, -36889, -36847, -36805, -36764,
      -36722, -36681, -36639, -36597, -36556, -36514, -36472, -36430,
      -36388, -36347, -36305, -36263, -36221, -36179, -36137, -36095,
      -36053, -36011, -35969, -35927, -35885, -35843, -35801, -35759,
      -35717, -35675, -35633, -35590, -35548, -35506, -35464, -35421,
      -35379, -35337, -35294, -35252, -35210, -35167, -35125, -35082,
      -35040, -34997, -34955, -34912, -34870, -34827, -34785, -34742,
      -34699, -34657, -34614, -34571, -34529, -34486, -34443, -34400,
      -34358, -34315, -34272, -34229, -34186, -34143, -34100, -34057,
      -34015, -33972, -33929, -33886, -33843, -33799, -33756, -33713,
      -33670, -33627, -33584, -33541, -33498, -33454, -33411, -33368,
      -33325, -33281, -33238, -33195, -33151, -33108, -33065, -33021,
      -32978, -32934, -32891, -32847, -32804, -32760, -32717, -32673,
      -32630, -32586, -32542, -32499, -32455, -32411, -32368, -32324,
      -32280, -32236, -32193, -32149, -32105, -32061, -32017, -31974,
      -31930, -31886, -31842, -31798, -31754, -31710, -31666, -31622,
      -31578, -31534, -31490, -31446, -31402, -31357, -31313, -31269,
      -31225, -31181, -31136, -31092, -31048, -31004, -30959, -30915,
      -30871, -30826, -30782, -30738, -30693, -30649, -30604, -30560,
      -30515, -30471, -30426, -30382, -30337, -30293, -30248, -30204,
      -30159, -30114, -30070, -30025, -29980, -29936, -29891, -29846,
      -29801, -29757, -29712, -29667, -29622, -29577, -29533, -29488,
      -29443, -29398, -29353, -29308, -29263, -29218, -29173, -29128,
      -29083, -29038, -28993, -28948, -28903, -28858, -28812, -28767,
      -28722, -28677, -28632, -28586, -28541, -28496, -28451, -28405,
      -28360, -28315, -28269, -28224, -28179, -28133, -28088, -28042,
      -27997, -27952, -27906, -27861, -27815, -27770, -27724, -27678,
      -27633, -27587, -27542, -27496, -27450, -27405, -27359, -27313,
      -27268, -27222, -27176, -27131, -27085, -27039, -26993, -26947,
      -26902, -26856, -26810, -26764, -26718, -26672, -26626, -26580,
      -26534, -26488, -26442, -26396, -26350, -26304, -26258, -26212,
      -26166, -26120, -26074, -26028, -25982, -25936, -25889, -25843,
      -25797, -25751, -25705, -25658, -25612, -25566, -25520, -25473,
      -25427, -25381, -25334, -25288, -25241, -25195, -25149, -25102,
      -25056, -25009, -24963, -24916, -24870, -24823, -24777, -24730,
      -24684, -24637, -24591, -24544, -24497, -24451, -24404, -24357,
      -24311, -24264, -24217, -24171, -24124, -24077, -24030, -23984,
      -23937, -23890, -23843, -23796, -23750, -23703, -23656, -23609,
      -23562, -23515, -23468, -23421, -23374, -23327, -23280, -23233,
      -23186, -23139, -23092, -23045, -22998, -22951, -22904, -22857,
      -22810, -22763, -22716, -22668, -22621, -22574, -22527, -22480,
      -22432, -22385, -22338, -22291, -22243, -22196, -22149, -22102,
      -22054, -22007, -21960, -21912, -21865, -21817, -21770, -21723,
      -21675, -21628, -21580, -21533, -21485, -21438, -21390, -21343,
      -21295, -21248, -21200, -21153, -21105, -21057, -21010, -20962,
      -20915, -20867, -20819, -20772, -20724, -20676, -20629, -20581,
      -20533, -20485, -20438, -20390, -20342, -20294, -20246, -20199,
      -20151, -20103, -20055, -20007, -19959, -19912, -19864, -19816,
      -19768, -19720, -19672, -19624, -19576, -19528, -19480, -19432,
      -19384, -19336, -19288, -19240, -19192, -19144, -19096, -19048,
      -19000, -18951, -18903, -18855, -18807, -18759, -18711, -18663,
      -18614, -18566, -18518, -18470, -18421, -18373, -18325, -18277,
      -18228, -18180, -18132, -18084, -18035, -17987, -17939, -17890,
      -17842, -17793, -17745, -17697, -17648, -17600, -17551, -17503,
      -17455, -17406, -17358, -17309, -17261, -17212, -17164, -17115,
      -17067, -17018, -16970, -16921, -16872, -16824, -16775, -16727,
      -16678, -16629, -16581, -16532, -16484, -16435, -16386, -16338,
      -16289, -16240, -16191, -16143, -16094, -16045, -15997, -15948,
      -15899, -15850, -15802, -15753, -15704, -15655, -15606, -15557,
      -15509, -15460, -15411, -15362, -15313, -15264, -15215, -15167,
      -15118, -15069, -15020, -14971, -14922, -14873, -14824, -14775,
      -14726, -14677, -14628, -14579, -14530, -14481, -14432, -14383,
      -14334, -14285, -14236, -14187, -14138, -14089, -14040, -13990,
      -13941, -13892, -13843, -13794, -13745, -13696, -13647, -13597,
      -13548, -13499, -13450, -13401, -13351, -13302, -13253, -13204,
      -13154, -13105, -13056, -13007, -12957, -12908, -12859, -12810,
      -12760, -12711, -12662, -12612, -12563, -12514, -12464, -12415,
      -12366, -12316, -12267, -12217, -12168, -12119, -12069, -12020,
      -11970, -11921, -11872, -11822, -11773, -11723, -11674, -11624,
      -11575, -11525, -11476, -11426, -11377, -11327, -11278, -11228,
      -11179, -11129, -11080, -11030, -10981, -10931, -10882, -10832,
      -10782, -10733, -10683, -10634, -10584, -10534, -10485, -10435,
      -10386, -10336, -10286, -10237, -10187, -10137, -10088, -10038,
      -9988, -9939, -9889, -9839, -9790, -9740, -9690, -9640,
      -9591, -9541, -9491, -9442, -9392, -9342, -9292, -9243,
      -9193, -9143, -9093, -9043, -8994, -8944, -8894, -8844,
      -8794, -8745, -8695, -8645, -8595, -8545, -8496, -8446,
      -8396, -8346, -8296, -8246, -8196, -8147, -8097, -8047,
      -7997, -7947, -7897, -7847, -7797, -7747, -7697, -7648,
      -7598, -7548, -7498, -7448, -7398, -7348, -7298, -7248,
      -7198, -7148, -7098, -7048, -6998, -6948, -6898, -6848,
      -6798, -6748, -6698, -6648, -6598, -6548, -6498, -6448,
      -6398, -6348, -6298, -6248, -6198, -6148, -6098, -6048,
      -5998, -5948, -5898, -5848, -5798, -5747, -5697, -5647,
      -5597, -5547, -5497, -5447, -5397, -5347, -5297, -5247,
      -5197, -5146, -5096, -5046, -4996, -4946, -4896, -4846,
      -4796, -4745, -4695, -4645, -4595, -4545, -4495, -4445,
      -4394, -4344, -4294, -4244, -4194, -4144, -4093, -4043,
      -3993, -3943, -3893, -3843, -3792, -3742, -3692, -3642,
      -3592, -3541, -3491, -3441, -3391, -3341, -3291, -3240,
      -3190, -3140, -3090, -3039, -2989, -2939, -2889, -2839,
      -2788, -2738, -2688, -2638, -2588, -2537, -2487, -2437,
      -2387, -2336, -2286, -2236, -2186, -2135, -2085, -2035,
      -1985, -1934, -1884, -1834, -1784, -1733, -1683, -1633,
      -1583, -1532, -1482, -1432, -1382, -1331, -1281, -1231,
      -1181, -1130, -1080, -1030, -980, -929, -879, -829,
      -779, -728, -678, -628, -578, -527, -477, -427,
      -376, -326, -276, -226, -175, -125, -75, -25,
      25, 75, 125, 175, 226, 276, 326, 376,
      427, 477, 527, 578, 628, 678, 728, 779,
      829, 879, 929, 980, 1030, 1080, 1130, 1181,
      1231, 1281, 1331, 1382, 1432, 1482, 1532, 1583,
      1633, 1683, 1733, 1784, 1834, 1884, 1934, 1985,
      2035, 2085, 2135, 2186, 2236, 2286, 2336, 2387,
      2437, 2487, 2537, 2587, 2638, 2688, 2738, 2788,
      2839, 2889, 2939, 2989, 3039, 3090, 3140, 3190,
      3240, 3291, 3341, 3391, 3441, 3491, 3542, 3592,
      3642, 3692, 3742, 3792, 3843, 3893, 3943, 3993,
      4043, 4093, 4144, 4194, 4244, 4294, 4344, 4394,
      4445, 4495, 4545, 4595, 4645, 4695, 4745, 4796,
      4846, 4896, 4946, 4996, 5046, 5096, 5146, 5197,
      5247, 5297, 5347, 5397, 5447, 5497, 5547, 5597,
      5647, 5697, 5747, 5798, 5848, 5898, 5948, 5998,
      6048, 6098, 6148, 6198, 6248, 6298, 6348, 6398,
      6448, 6498, 6548, 6598, 6648, 6698, 6748, 6798,
      6848, 6898, 6948, 6998, 7048, 7098, 7148, 7198,
      7248, 7298, 7348, 7398, 7448, 7498, 7548, 7598,
      7648, 7697, 7747, 7797, 7847, 7897, 7947, 7997,
      8047, 8097, 8147, 8196, 8246, 8296, 8346, 8396,
      8446, 8496, 8545, 8595, 8645, 8695, 8745, 8794,
      8844, 8894, 8944, 8994, 9043, 9093, 9143, 9193,
      9243, 9292, 9342, 9392, 9442, 9491, 9541, 9591,
      9640, 9690, 9740, 9790, 9839, 9889, 9939, 9988,
      10038, 10088, 10137, 10187, 10237, 10286, 10336, 10386,
      10435, 10485, 10534, 10584, 10634, 10683, 10733, 10782,
      10832, 10882, 10931, 10981, 11030, 11080, 11129, 11179,
      11228, 11278, 11327, 11377, 11426, 11476, 11525, 11575,
      11624, 11674, 11723, 11773, 11822, 11872, 11921, 11970,
      12020, 12069, 12119, 12168, 12218, 12267, 12316, 12366,
      12415, 12464, 12514, 12563, 12612, 12662, 12711, 12760,
      12810, 12859, 12908, 12957, 13007, 13056, 13105, 13154,
      13204, 13253, 13302, 13351, 13401, 13450, 13499, 13548,
      13597, 13647, 13696, 13745, 13794, 13843, 13892, 13941,
      13990, 14040, 14089, 14138, 14187, 14236, 14285, 14334,
      14383, 14432, 14481, 14530, 14579, 14628, 14677, 14726,
      14775, 14824, 14873, 14922, 14971, 15020, 15069, 15118,
      15167, 15215, 15264, 15313, 15362, 15411, 15460, 15509,
      15557, 15606, 15655, 15704, 15753, 15802, 15850, 15899,
      15948, 15997, 16045, 16094, 16143, 16191, 16240, 16289,
      16338, 16386, 16435, 16484, 16532, 16581, 16629, 16678,
      16727, 16775, 16824, 16872, 16921, 16970, 17018, 17067,
      17115, 17164, 17212, 17261, 17309, 17358, 17406, 17455,
      17503, 17551, 17600, 17648, 17697, 17745, 17793, 17842,
      17890, 17939, 17987, 18035, 18084, 18132, 18180, 18228,
      18277, 18325, 18373, 18421, 18470, 18518, 18566, 18614,
      18663, 18711, 18759, 18807, 18855, 18903, 18951, 19000,
      19048, 19096, 19144, 19192, 19240, 19288, 19336, 19384,
      19432, 19480, 19528, 19576, 19624, 19672, 19720, 19768,
      19816, 19864, 19912, 19959, 20007, 20055, 20103, 20151,
      20199, 20246, 20294, 20342, 20390, 20438, 20485, 20533,
      20581, 20629, 20676, 20724, 20772, 20819, 20867, 20915,
      20962, 21010, 21057, 21105, 21153, 21200, 21248, 21295,
      21343, 21390, 21438, 21485, 21533, 21580, 21628, 21675,
      21723, 21770, 21817, 21865, 21912, 21960, 22007, 22054,
      22102, 22149, 22196, 22243, 22291, 22338, 22385, 22432,
      22480, 22527, 22574, 22621, 22668, 22716, 22763, 22810,
      22857, 22904, 22951, 22998, 23045, 23092, 23139, 23186,
      23233, 23280, 23327, 23374, 23421, 23468, 23515, 23562,
      23609, 23656, 23703, 23750, 23796, 23843, 23890, 23937,
      23984, 24030, 24077, 24124, 24171, 24217, 24264, 24311,
      24357, 24404, 24451, 24497, 24544, 24591, 24637, 24684,
      24730, 24777, 24823, 24870, 24916, 24963, 25009, 25056,
      25102, 25149, 25195, 25241, 25288, 25334, 25381, 25427,
      25473, 25520, 25566, 25612, 25658, 25705, 25751, 25797,
      25843, 25889, 25936, 25982, 26028, 26074, 26120, 26166,
      26212, 26258, 26304, 26350, 26396, 26442, 26488, 26534,
      26580, 26626, 26672, 26718, 26764, 26810, 26856, 26902,
      26947, 26993, 27039, 27085, 27131, 27176, 27222, 27268,
      27313, 27359, 27405, 27450, 27496, 27542, 27587, 27633,
      27678, 27724, 27770, 27815, 27861, 27906, 27952, 27997,
      28042, 28088, 28133, 28179, 28224, 28269, 28315, 28360,
      28405, 28451, 28496, 28541, 28586, 28632, 28677, 28722,
      28767, 28812, 28858, 28903, 28948, 28993, 29038, 29083,
      29128, 29173, 29218, 29263, 29308, 29353, 29398, 29443,
      29488, 29533, 29577, 29622, 29667, 29712, 29757, 29801,
      29846, 29891, 29936, 29980, 30025, 30070, 30114, 30159,
      30204, 30248, 30293, 30337, 30382, 30427, 30471, 30516,
      30560, 30604, 30649, 30693, 30738, 30782, 30826, 30871,
      30915, 30959, 31004, 31048, 31092, 31136, 31181, 31225,
      31269, 31313, 31357, 31402, 31446, 31490, 31534, 31578,
      31622, 31666, 31710, 31754, 31798, 31842, 31886, 31930,
      31974, 32017, 32061, 32105, 32149, 32193, 32236, 32280,
      32324, 32368, 32411, 32455, 32499, 32542, 32586, 32630,
      32673, 32717, 32760, 32804, 32847, 32891, 32934, 32978,
      33021, 33065, 33108, 33151, 33195, 33238, 33281, 33325,
      33368, 33411, 33454, 33498, 33541, 33584, 33627, 33670,
      33713, 33756, 33799, 33843, 33886, 33929, 33972, 34015,
      34057, 34100, 34143, 34186, 34229, 34272, 34315, 34358,
      34400, 34443, 34486, 34529, 34571, 34614, 34657, 34699,
      34742, 34785, 34827, 34870, 34912, 34955, 34997, 35040,
      35082, 35125, 35167, 35210, 35252, 35294, 35337, 35379,
      35421, 35464, 35506, 35548, 35590, 35633, 35675, 35717,
      35759, 35801, 35843, 35885, 35927, 35969, 36011, 36053,
      36095, 36137, 36179, 36221, 36263, 36305, 36347, 36388,
      36430, 36472, 36514, 36556, 36597, 36639, 36681, 36722,
      36764, 36805, 36847, 36889, 36930, 36972, 37013, 37055,
      37096, 37137, 37179, 37220, 37262, 37303, 37344, 37386,
      37427, 37468, 37509, 37551, 37592, 37633, 37674, 37715,
      37756, 37797, 37838, 37879, 37920, 37961, 38002, 38043,
      38084, 38125, 38166, 38207, 38248, 38288, 38329, 38370,
      38411, 38451, 38492, 38533, 38573, 38614, 38655, 38695,
      38736, 38776, 38817, 38857, 38898, 38938, 38979, 39019,
      39059, 39100, 39140, 39180, 39221, 39261, 39301, 39341,
      39382, 39422, 39462, 39502, 39542, 39582, 39622, 39662,
      39702, 39742, 39782, 39822, 39862, 39902, 39942, 39982,
      40021, 40061, 40101, 40141, 40180, 40220, 40260, 40299,
      40339, 40379, 40418, 40458, 40497, 40537, 40576, 40616,
      40655, 40695, 40734, 40773, 40813, 40852, 40891, 40931,
      40970, 41009, 41048, 41087, 41127, 41166, 41205, 41244,
      41283, 41322, 41361, 41400, 41439, 41478, 41517, 41556,
      41595, 41633, 41672, 41711, 41750, 41788, 41827, 41866,
      41904, 41943, 41982, 42020, 42059, 42097, 42136, 42174,
      42213, 42251, 42290, 42328, 42366, 42405, 42443, 42481,
      42520, 42558, 42596, 42634, 42672, 42711, 42749, 42787,
      42825, 42863, 42901, 42939, 42977, 43015, 43053, 43091,
      43128, 43166, 43204, 43242, 43280, 43317, 43355, 43393,
      43430, 43468, 43506, 43543, 43581, 43618, 43656, 43693,
      43731, 43768, 43806, 43843, 43880, 43918, 43955, 43992,
      44029, 44067, 44104, 44141, 44178, 44215, 44252, 44289,
      44326, 44363, 44400, 44437, 44474, 44511, 44548, 44585,
      44622, 44659, 44695, 44732, 44769, 44806, 44842, 44879,
      44915, 44952, 44989, 45025, 45062, 45098, 45135, 45171,
      45207, 45244, 45280, 45316, 45353, 45389, 45425, 45462,
      45498, 45534, 45570, 45606, 45642, 45678, 45714, 45750,
      45786, 45822, 45858, 45894, 45930, 45966, 46002, 46037,
      46073, 46109, 46145, 46180, 46216, 46252, 46287, 46323,
      46358, 46394, 46429, 46465, 46500, 46536, 46571, 46606,
      46642, 46677, 46712, 46747, 46783, 46818, 46853, 46888,
      46923, 46958, 46993, 47028, 47063, 47098, 47133, 47168,
      47203, 47238, 47273, 47308, 47342, 47377, 47412, 47446,
      47481, 47516, 47550, 47585, 47619, 47654, 47688, 47723,
      47757, 47792, 47826, 47861, 47895, 47929, 47963, 47998,
      48032, 48066, 48100, 48134, 48168, 48202, 48237, 48271,
      48305, 48338, 48372, 48406, 48440, 48474, 48508, 48542,
      48575, 48609, 48643, 48676, 48710, 48744, 48777, 48811,
      48844, 48878, 48911, 48945, 48978, 49012, 49045, 49078,
      49112, 49145, 49178, 49211, 49244, 49278, 49311, 49344,
      49377, 49410, 49443, 49476, 49509, 49542, 49575, 49608,
      49640, 49673, 49706, 49739, 49771, 49804, 49837, 49869,
      49902, 49935, 49967, 50000, 50032, 50064, 50097, 50129,
      50162, 50194, 50226, 50259, 50291, 50323, 50355, 50387,
      50420, 50452, 50484, 50516, 50548, 50580, 50612, 50644,
      50675, 50707, 50739, 50771, 50803, 50834, 50866, 50898,
      50929, 50961, 50993, 51024, 51056, 51087, 51119, 51150,
      51182, 51213, 51244, 51276, 51307, 51338, 51369, 51401,
      51432, 51463, 51494, 51525, 51556, 51587, 51618, 51649,
      51680, 51711, 51742, 51773, 51803, 51834, 51865, 51896,
      51926, 51957, 51988, 52018, 52049, 52079, 52110, 52140,
      52171, 52201, 52231, 52262, 52292, 52322, 52353, 52383,
      52413, 52443, 52473, 52503, 52534, 52564, 52594, 52624,
      52653, 52683, 52713, 52743, 52773, 52803, 52832, 52862,
      52892, 52922, 52951, 52981, 53010, 53040, 53069, 53099,
      53128, 53158, 53187, 53216, 53246, 53275, 53304, 53334,
      53363, 53392, 53421, 53450, 53479, 53508, 53537, 53566,
      53595, 53624, 53653, 53682, 53711, 53739, 53768, 53797,
      53826, 53854, 53883, 53912, 53940, 53969, 53997, 54026,
      54054, 54082, 54111, 54139, 54167, 54196, 54224, 54252,
      54280, 54309, 54337, 54365, 54393, 54421, 54449, 54477,
      54505, 54533, 54560, 54588, 54616, 54644, 54672, 54699,
      54727, 54755, 54782, 54810, 54837, 54865, 54892, 54920,
      54947, 54974, 55002, 55029, 55056, 55084, 55111, 55138,
      55165, 55192, 55219, 55246, 55274, 55300, 55327, 55354,
      55381, 55408, 55435, 55462, 55489, 55515, 55542, 55569,
      55595, 55622, 55648, 55675, 55701, 55728, 55754, 55781,
      55807, 55833, 55860, 55886, 55912, 55938, 55965, 55991,
      56017, 56043, 56069, 56095, 56121, 56147, 56173, 56199,
      56225, 56250, 56276, 56302, 56328, 56353, 56379, 56404,
      56430, 56456, 56481, 56507, 56532, 56557, 56583, 56608,
      56633, 56659, 56684, 56709, 56734, 56760, 56785, 56810,
      56835, 56860, 56885, 56910, 56935, 56959, 56984, 57009,
      57034, 57059, 57083, 57108, 57133, 57157, 57182, 57206,
      57231, 57255, 57280, 57304, 57329, 57353, 57377, 57402,
      57426, 57450, 57474, 57498, 57522, 57546, 57570, 57594,
      57618, 57642, 57666, 57690, 57714, 57738, 57762, 57785,
      57809, 57833, 57856, 57880, 57903, 57927, 57950, 57974,
      57997, 58021, 58044, 58067, 58091, 58114, 58137, 58160,
      58183, 58207, 58230, 58253, 58276, 58299, 58322, 58345,
      58367, 58390, 58413, 58436, 58459, 58481, 58504, 58527,
      58549, 58572, 58594, 58617, 58639, 58662, 58684, 58706,
      58729, 58751, 58773, 58795, 58818, 58840, 58862, 58884,
      58906, 58928, 58950, 58972, 58994, 59016, 59038, 59059,
      59081, 59103, 59125, 59146, 59168, 59190, 59211, 59233,
      59254, 59276, 59297, 59318, 59340, 59361, 59382, 59404,
      59425, 59446, 59467, 59488, 59509, 59530, 59551, 59572,
      59593, 59614, 59635, 59656, 59677, 59697, 59718, 59739,
      59759, 59780, 59801, 59821, 59842, 59862, 59883, 59903,
      59923, 59944, 59964, 59984, 60004, 60025, 60045, 60065,
      60085, 60105, 60125, 60145, 60165, 60185, 60205, 60225,
      60244, 60264, 60284, 60304, 60323, 60343, 60363, 60382,
      60402, 60421, 60441, 60460, 60479, 60499, 60518, 60537,
      60556, 60576, 60595, 60614, 60633, 60652, 60671, 60690,
      60709, 60728, 60747, 60766, 60785, 60803, 60822, 60841,
      60859, 60878, 60897, 60915, 60934, 60952, 60971, 60989,
      61007, 61026, 61044, 61062, 61081, 61099, 61117, 61135,
      61153, 61171, 61189, 61207, 61225, 61243, 61261, 61279,
      61297, 61314, 61332, 61350, 61367, 61385, 61403, 61420,
      61438, 61455, 61473, 61490, 61507, 61525, 61542, 61559,
      61577, 61594, 61611, 61628, 61645, 61662, 61679, 61696,
      61713, 61730, 61747, 61764, 61780, 61797, 61814, 61831,
      61847, 61864, 61880, 61897, 61913, 61930, 61946, 61963,
      61979, 61995, 62012, 62028, 62044, 62060, 62076, 62092,
      62108, 62125, 62141, 62156, 62172, 62188, 62204, 62220,
      62236, 62251, 62267, 62283, 62298, 62314, 62329, 62345,
      62360, 62376, 62391, 62407, 62422, 62437, 62453, 62468,
      62483, 62498, 62513, 62528, 62543, 62558, 62573, 62588,
      62603, 62618, 62633, 62648, 62662, 62677, 62692, 62706,
      62721, 62735, 62750, 62764, 62779, 62793, 62808, 62822,
      62836, 62850, 62865, 62879, 62893, 62907, 62921, 62935,
      62949, 62963, 62977, 62991, 63005, 63019, 63032, 63046,
      63060, 63074, 63087, 63101, 63114, 63128, 63141, 63155,
      63168, 63182, 63195, 63208, 63221, 63235, 63248, 63261,
      63274, 63287, 63300, 63313, 63326, 63339, 63352, 63365,
      63378, 63390, 63403, 63416, 63429, 63441, 63454, 63466,
      63479, 63491, 63504, 63516, 63528, 63541, 63553, 63565,
      63578, 63590, 63602, 63614, 63626, 63638, 63650, 63662,
      63674, 63686, 63698, 63709, 63721, 63733, 63745, 63756,
      63768, 63779, 63791, 63803, 63814, 63825, 63837, 63848,
      63859, 63871, 63882, 63893, 63904, 63915, 63927, 63938,
      63949, 63960, 63971, 63981, 63992, 64003, 64014, 64025,
      64035, 64046, 64057, 64067, 64078, 64088, 64099, 64109,
      64120, 64130, 64140, 64151, 64161, 64171, 64181, 64192,
      64202, 64212, 64222, 64232, 64242, 64252, 64261, 64271,
      64281, 64291, 64301, 64310, 64320, 64330, 64339, 64349,
      64358, 64368, 64377, 64387, 64396, 64405, 64414, 64424,
      64433, 64442, 64451, 64460, 64469, 64478, 64487, 64496,
      64505, 64514, 64523, 64532, 64540, 64549, 64558, 64566,
      64575, 64584, 64592, 64600, 64609, 64617, 64626, 64634,
      64642, 64651, 64659, 64667, 64675, 64683, 64691, 64699,
      64707, 64715, 64723, 64731, 64739, 64747, 64754, 64762,
      64770, 64777, 64785, 64793, 64800, 64808, 64815, 64822,
      64830, 64837, 64844, 64852, 64859, 64866, 64873, 64880,
      64887, 64895, 64902, 64908, 64915, 64922, 64929, 64936,
      64943, 64949, 64956, 64963, 64969, 64976, 64982, 64989,
      64995, 65002, 65008, 65015, 65021, 65027, 65033, 65040,
      65046, 65052, 65058, 65064, 65070, 65076, 65082, 65088,
      65094, 65099, 65105, 65111, 65117, 65122, 65128, 65133,
      65139, 65144, 65150, 65155, 65161, 65166, 65171, 65177,
      65182, 65187, 65192, 65197, 65202, 65207, 65212, 65217,
      65222, 65227, 65232, 65237, 65242, 65246, 65251, 65256,
      65260, 65265, 65270, 65274, 65279, 65283, 65287, 65292,
      65296, 65300, 65305, 65309, 65313, 65317, 65321, 65325,
      65329, 65333, 65337, 65341, 65345, 65349, 65352, 65356,
      65360, 65363, 65367, 65371, 65374, 65378, 65381, 65385,
      65388, 65391, 65395, 65398, 65401, 65404, 65408, 65411,
      65414, 65417, 65420, 65423, 65426, 65429, 65431, 65434,
      65437, 65440, 65442, 65445, 65448, 65450, 65453, 65455,
      65458, 65460, 65463, 65465, 65467, 65470, 65472, 65474,
      65476, 65478, 65480, 65482, 65484, 65486, 65488, 65490,
      65492, 65494, 65496, 65497, 65499, 65501, 65502, 65504,
      65505, 65507, 65508, 65510, 65511, 65513, 65514, 65515,
      65516, 65518, 65519, 65520, 65521, 65522, 65523, 65524,
      65525, 65526, 65527, 65527, 65528, 65529, 65530, 65530,
      65531, 65531, 65532, 65532, 65533, 65533, 65534, 65534,
      65534, 65535, 65535, 65535, 65535, 65535, 65535, 65535,
    ]
    @@tantoangle : Array(UInt32) = [
      0_u32, 333772_u32, 667544_u32, 1001315_u32, 1335086_u32, 1668857_u32, 2002626_u32, 2336395_u32,
      2670163_u32, 3003929_u32, 3337694_u32, 3671457_u32, 4005219_u32, 4338979_u32, 4672736_u32, 5006492_u32,
      5340245_u32, 5673995_u32, 6007743_u32, 6341488_u32, 6675230_u32, 7008968_u32, 7342704_u32, 7676435_u32,
      8010164_u32, 8343888_u32, 8677609_u32, 9011325_u32, 9345037_u32, 9678744_u32, 10012447_u32, 10346145_u32,
      10679838_u32, 11013526_u32, 11347209_u32, 11680887_u32, 12014558_u32, 12348225_u32, 12681885_u32, 13015539_u32,
      13349187_u32, 13682829_u32, 14016464_u32, 14350092_u32, 14683714_u32, 15017328_u32, 15350936_u32, 15684536_u32,
      16018129_u32, 16351714_u32, 16685291_u32, 17018860_u32, 17352422_u32, 17685974_u32, 18019518_u32, 18353054_u32,
      18686582_u32, 19020100_u32, 19353610_u32, 19687110_u32, 20020600_u32, 20354080_u32, 20687552_u32, 21021014_u32,
      21354466_u32, 21687906_u32, 22021338_u32, 22354758_u32, 22688168_u32, 23021568_u32, 23354956_u32, 23688332_u32,
      24021698_u32, 24355052_u32, 24688396_u32, 25021726_u32, 25355046_u32, 25688352_u32, 26021648_u32, 26354930_u32,
      26688200_u32, 27021456_u32, 27354702_u32, 27687932_u32, 28021150_u32, 28354356_u32, 28687548_u32, 29020724_u32,
      29353888_u32, 29687038_u32, 30020174_u32, 30353296_u32, 30686404_u32, 31019496_u32, 31352574_u32, 31685636_u32,
      32018684_u32, 32351718_u32, 32684734_u32, 33017736_u32, 33350722_u32, 33683692_u32, 34016648_u32, 34349584_u32,
      34682508_u32, 35015412_u32, 35348300_u32, 35681172_u32, 36014028_u32, 36346868_u32, 36679688_u32, 37012492_u32,
      37345276_u32, 37678044_u32, 38010792_u32, 38343524_u32, 38676240_u32, 39008936_u32, 39341612_u32, 39674272_u32,
      40006912_u32, 40339532_u32, 40672132_u32, 41004716_u32, 41337276_u32, 41669820_u32, 42002344_u32, 42334848_u32,
      42667332_u32, 42999796_u32, 43332236_u32, 43664660_u32, 43997060_u32, 44329444_u32, 44661800_u32, 44994140_u32,
      45326456_u32, 45658752_u32, 45991028_u32, 46323280_u32, 46655512_u32, 46987720_u32, 47319908_u32, 47652072_u32,
      47984212_u32, 48316332_u32, 48648428_u32, 48980500_u32, 49312548_u32, 49644576_u32, 49976580_u32, 50308556_u32,
      50640512_u32, 50972444_u32, 51304352_u32, 51636236_u32, 51968096_u32, 52299928_u32, 52631740_u32, 52963524_u32,
      53295284_u32, 53627020_u32, 53958728_u32, 54290412_u32, 54622068_u32, 54953704_u32, 55285308_u32, 55616888_u32,
      55948444_u32, 56279972_u32, 56611472_u32, 56942948_u32, 57274396_u32, 57605816_u32, 57937212_u32, 58268576_u32,
      58599916_u32, 58931228_u32, 59262512_u32, 59593768_u32, 59924992_u32, 60256192_u32, 60587364_u32, 60918508_u32,
      61249620_u32, 61580704_u32, 61911760_u32, 62242788_u32, 62573788_u32, 62904756_u32, 63235692_u32, 63566604_u32,
      63897480_u32, 64228332_u32, 64559148_u32, 64889940_u32, 65220696_u32, 65551424_u32, 65882120_u32, 66212788_u32,
      66543420_u32, 66874024_u32, 67204600_u32, 67535136_u32, 67865648_u32, 68196120_u32, 68526568_u32, 68856984_u32,
      69187360_u32, 69517712_u32, 69848024_u32, 70178304_u32, 70508560_u32, 70838776_u32, 71168960_u32, 71499112_u32,
      71829224_u32, 72159312_u32, 72489360_u32, 72819376_u32, 73149360_u32, 73479304_u32, 73809216_u32, 74139096_u32,
      74468936_u32, 74798744_u32, 75128520_u32, 75458264_u32, 75787968_u32, 76117632_u32, 76447264_u32, 76776864_u32,
      77106424_u32, 77435952_u32, 77765440_u32, 78094888_u32, 78424304_u32, 78753688_u32, 79083032_u32, 79412336_u32,
      79741608_u32, 80070840_u32, 80400032_u32, 80729192_u32, 81058312_u32, 81387392_u32, 81716432_u32, 82045440_u32,
      82374408_u32, 82703336_u32, 83032224_u32, 83361080_u32, 83689896_u32, 84018664_u32, 84347400_u32, 84676096_u32,
      85004760_u32, 85333376_u32, 85661952_u32, 85990488_u32, 86318984_u32, 86647448_u32, 86975864_u32, 87304240_u32,
      87632576_u32, 87960872_u32, 88289128_u32, 88617344_u32, 88945520_u32, 89273648_u32, 89601736_u32, 89929792_u32,
      90257792_u32, 90585760_u32, 90913688_u32, 91241568_u32, 91569408_u32, 91897200_u32, 92224960_u32, 92552672_u32,
      92880336_u32, 93207968_u32, 93535552_u32, 93863088_u32, 94190584_u32, 94518040_u32, 94845448_u32, 95172816_u32,
      95500136_u32, 95827416_u32, 96154648_u32, 96481832_u32, 96808976_u32, 97136080_u32, 97463136_u32, 97790144_u32,
      98117112_u32, 98444032_u32, 98770904_u32, 99097736_u32, 99424520_u32, 99751256_u32, 100077944_u32, 100404592_u32,
      100731192_u32, 101057744_u32, 101384248_u32, 101710712_u32, 102037128_u32, 102363488_u32, 102689808_u32, 103016080_u32,
      103342312_u32, 103668488_u32, 103994616_u32, 104320696_u32, 104646736_u32, 104972720_u32, 105298656_u32, 105624552_u32,
      105950392_u32, 106276184_u32, 106601928_u32, 106927624_u32, 107253272_u32, 107578872_u32, 107904416_u32, 108229920_u32,
      108555368_u32, 108880768_u32, 109206120_u32, 109531416_u32, 109856664_u32, 110181872_u32, 110507016_u32, 110832120_u32,
      111157168_u32, 111482168_u32, 111807112_u32, 112132008_u32, 112456856_u32, 112781648_u32, 113106392_u32, 113431080_u32,
      113755720_u32, 114080312_u32, 114404848_u32, 114729328_u32, 115053760_u32, 115378136_u32, 115702464_u32, 116026744_u32,
      116350960_u32, 116675128_u32, 116999248_u32, 117323312_u32, 117647320_u32, 117971272_u32, 118295176_u32, 118619024_u32,
      118942816_u32, 119266560_u32, 119590248_u32, 119913880_u32, 120237456_u32, 120560984_u32, 120884456_u32, 121207864_u32,
      121531224_u32, 121854528_u32, 122177784_u32, 122500976_u32, 122824112_u32, 123147200_u32, 123470224_u32, 123793200_u32,
      124116120_u32, 124438976_u32, 124761784_u32, 125084528_u32, 125407224_u32, 125729856_u32, 126052432_u32, 126374960_u32,
      126697424_u32, 127019832_u32, 127342184_u32, 127664472_u32, 127986712_u32, 128308888_u32, 128631008_u32, 128953072_u32,
      129275080_u32, 129597024_u32, 129918912_u32, 130240744_u32, 130562520_u32, 130884232_u32, 131205888_u32, 131527480_u32,
      131849016_u32, 132170496_u32, 132491912_u32, 132813272_u32, 133134576_u32, 133455816_u32, 133776992_u32, 134098120_u32,
      134419184_u32, 134740176_u32, 135061120_u32, 135382000_u32, 135702816_u32, 136023584_u32, 136344272_u32, 136664912_u32,
      136985488_u32, 137306016_u32, 137626464_u32, 137946864_u32, 138267184_u32, 138587456_u32, 138907664_u32, 139227808_u32,
      139547904_u32, 139867920_u32, 140187888_u32, 140507776_u32, 140827616_u32, 141147392_u32, 141467104_u32, 141786752_u32,
      142106336_u32, 142425856_u32, 142745312_u32, 143064720_u32, 143384048_u32, 143703312_u32, 144022512_u32, 144341664_u32,
      144660736_u32, 144979744_u32, 145298704_u32, 145617584_u32, 145936400_u32, 146255168_u32, 146573856_u32, 146892480_u32,
      147211040_u32, 147529536_u32, 147847968_u32, 148166336_u32, 148484640_u32, 148802880_u32, 149121056_u32, 149439152_u32,
      149757200_u32, 150075168_u32, 150393072_u32, 150710912_u32, 151028688_u32, 151346400_u32, 151664048_u32, 151981616_u32,
      152299136_u32, 152616576_u32, 152933952_u32, 153251264_u32, 153568496_u32, 153885680_u32, 154202784_u32, 154519824_u32,
      154836784_u32, 155153696_u32, 155470528_u32, 155787296_u32, 156104000_u32, 156420624_u32, 156737200_u32, 157053696_u32,
      157370112_u32, 157686480_u32, 158002768_u32, 158318976_u32, 158635136_u32, 158951216_u32, 159267232_u32, 159583168_u32,
      159899040_u32, 160214848_u32, 160530592_u32, 160846256_u32, 161161840_u32, 161477376_u32, 161792832_u32, 162108208_u32,
      162423520_u32, 162738768_u32, 163053952_u32, 163369040_u32, 163684080_u32, 163999040_u32, 164313936_u32, 164628752_u32,
      164943504_u32, 165258176_u32, 165572784_u32, 165887312_u32, 166201776_u32, 166516160_u32, 166830480_u32, 167144736_u32,
      167458912_u32, 167773008_u32, 168087040_u32, 168400992_u32, 168714880_u32, 169028688_u32, 169342432_u32, 169656096_u32,
      169969696_u32, 170283216_u32, 170596672_u32, 170910032_u32, 171223344_u32, 171536576_u32, 171849728_u32, 172162800_u32,
      172475808_u32, 172788736_u32, 173101600_u32, 173414384_u32, 173727104_u32, 174039728_u32, 174352288_u32, 174664784_u32,
      174977200_u32, 175289536_u32, 175601792_u32, 175913984_u32, 176226096_u32, 176538144_u32, 176850096_u32, 177161984_u32,
      177473792_u32, 177785536_u32, 178097200_u32, 178408784_u32, 178720288_u32, 179031728_u32, 179343088_u32, 179654368_u32,
      179965568_u32, 180276704_u32, 180587744_u32, 180898720_u32, 181209616_u32, 181520448_u32, 181831184_u32, 182141856_u32,
      182452448_u32, 182762960_u32, 183073408_u32, 183383760_u32, 183694048_u32, 184004240_u32, 184314368_u32, 184624416_u32,
      184934400_u32, 185244288_u32, 185554096_u32, 185863840_u32, 186173504_u32, 186483072_u32, 186792576_u32, 187102000_u32,
      187411344_u32, 187720608_u32, 188029808_u32, 188338912_u32, 188647936_u32, 188956896_u32, 189265760_u32, 189574560_u32,
      189883264_u32, 190191904_u32, 190500448_u32, 190808928_u32, 191117312_u32, 191425632_u32, 191733872_u32, 192042016_u32,
      192350096_u32, 192658096_u32, 192966000_u32, 193273840_u32, 193581584_u32, 193889264_u32, 194196848_u32, 194504352_u32,
      194811792_u32, 195119136_u32, 195426400_u32, 195733584_u32, 196040688_u32, 196347712_u32, 196654656_u32, 196961520_u32,
      197268304_u32, 197574992_u32, 197881616_u32, 198188144_u32, 198494592_u32, 198800960_u32, 199107248_u32, 199413456_u32,
      199719584_u32, 200025616_u32, 200331584_u32, 200637456_u32, 200943248_u32, 201248960_u32, 201554576_u32, 201860128_u32,
      202165584_u32, 202470960_u32, 202776256_u32, 203081456_u32, 203386592_u32, 203691632_u32, 203996592_u32, 204301472_u32,
      204606256_u32, 204910976_u32, 205215600_u32, 205520144_u32, 205824592_u32, 206128960_u32, 206433248_u32, 206737456_u32,
      207041584_u32, 207345616_u32, 207649568_u32, 207953424_u32, 208257216_u32, 208560912_u32, 208864512_u32, 209168048_u32,
      209471488_u32, 209774832_u32, 210078112_u32, 210381296_u32, 210684384_u32, 210987408_u32, 211290336_u32, 211593184_u32,
      211895936_u32, 212198608_u32, 212501184_u32, 212803680_u32, 213106096_u32, 213408432_u32, 213710672_u32, 214012816_u32,
      214314880_u32, 214616864_u32, 214918768_u32, 215220576_u32, 215522288_u32, 215823920_u32, 216125472_u32, 216426928_u32,
      216728304_u32, 217029584_u32, 217330784_u32, 217631904_u32, 217932928_u32, 218233856_u32, 218534704_u32, 218835472_u32,
      219136144_u32, 219436720_u32, 219737216_u32, 220037632_u32, 220337952_u32, 220638192_u32, 220938336_u32, 221238384_u32,
      221538352_u32, 221838240_u32, 222138032_u32, 222437728_u32, 222737344_u32, 223036880_u32, 223336304_u32, 223635664_u32,
      223934912_u32, 224234096_u32, 224533168_u32, 224832160_u32, 225131072_u32, 225429872_u32, 225728608_u32, 226027232_u32,
      226325776_u32, 226624240_u32, 226922608_u32, 227220880_u32, 227519056_u32, 227817152_u32, 228115168_u32, 228413088_u32,
      228710912_u32, 229008640_u32, 229306288_u32, 229603840_u32, 229901312_u32, 230198688_u32, 230495968_u32, 230793152_u32,
      231090256_u32, 231387280_u32, 231684192_u32, 231981024_u32, 232277760_u32, 232574416_u32, 232870960_u32, 233167440_u32,
      233463808_u32, 233760096_u32, 234056288_u32, 234352384_u32, 234648384_u32, 234944304_u32, 235240128_u32, 235535872_u32,
      235831504_u32, 236127056_u32, 236422512_u32, 236717888_u32, 237013152_u32, 237308336_u32, 237603424_u32, 237898416_u32,
      238193328_u32, 238488144_u32, 238782864_u32, 239077488_u32, 239372016_u32, 239666464_u32, 239960816_u32, 240255072_u32,
      240549232_u32, 240843312_u32, 241137280_u32, 241431168_u32, 241724960_u32, 242018656_u32, 242312256_u32, 242605776_u32,
      242899200_u32, 243192512_u32, 243485744_u32, 243778896_u32, 244071936_u32, 244364880_u32, 244657744_u32, 244950496_u32,
      245243168_u32, 245535744_u32, 245828224_u32, 246120608_u32, 246412912_u32, 246705104_u32, 246997216_u32, 247289216_u32,
      247581136_u32, 247872960_u32, 248164688_u32, 248456320_u32, 248747856_u32, 249039296_u32, 249330640_u32, 249621904_u32,
      249913056_u32, 250204128_u32, 250495088_u32, 250785968_u32, 251076736_u32, 251367424_u32, 251658016_u32, 251948512_u32,
      252238912_u32, 252529200_u32, 252819408_u32, 253109520_u32, 253399536_u32, 253689456_u32, 253979280_u32, 254269008_u32,
      254558640_u32, 254848176_u32, 255137632_u32, 255426976_u32, 255716224_u32, 256005376_u32, 256294432_u32, 256583392_u32,
      256872256_u32, 257161024_u32, 257449696_u32, 257738272_u32, 258026752_u32, 258315136_u32, 258603424_u32, 258891600_u32,
      259179696_u32, 259467696_u32, 259755600_u32, 260043392_u32, 260331104_u32, 260618704_u32, 260906224_u32, 261193632_u32,
      261480960_u32, 261768176_u32, 262055296_u32, 262342320_u32, 262629248_u32, 262916080_u32, 263202816_u32, 263489456_u32,
      263776000_u32, 264062432_u32, 264348784_u32, 264635024_u32, 264921168_u32, 265207216_u32, 265493168_u32, 265779024_u32,
      266064784_u32, 266350448_u32, 266636000_u32, 266921472_u32, 267206832_u32, 267492096_u32, 267777264_u32, 268062336_u32,
      268347312_u32, 268632192_u32, 268916960_u32, 269201632_u32, 269486208_u32, 269770688_u32, 270055072_u32, 270339360_u32,
      270623552_u32, 270907616_u32, 271191616_u32, 271475488_u32, 271759296_u32, 272042976_u32, 272326560_u32, 272610048_u32,
      272893440_u32, 273176736_u32, 273459936_u32, 273743040_u32, 274026048_u32, 274308928_u32, 274591744_u32, 274874432_u32,
      275157024_u32, 275439520_u32, 275721920_u32, 276004224_u32, 276286432_u32, 276568512_u32, 276850528_u32, 277132416_u32,
      277414240_u32, 277695936_u32, 277977536_u32, 278259040_u32, 278540448_u32, 278821728_u32, 279102944_u32, 279384032_u32,
      279665056_u32, 279945952_u32, 280226752_u32, 280507456_u32, 280788064_u32, 281068544_u32, 281348960_u32, 281629248_u32,
      281909472_u32, 282189568_u32, 282469568_u32, 282749440_u32, 283029248_u32, 283308960_u32, 283588544_u32, 283868032_u32,
      284147424_u32, 284426720_u32, 284705920_u32, 284985024_u32, 285264000_u32, 285542912_u32, 285821696_u32, 286100384_u32,
      286378976_u32, 286657440_u32, 286935840_u32, 287214112_u32, 287492320_u32, 287770400_u32, 288048384_u32, 288326240_u32,
      288604032_u32, 288881696_u32, 289159264_u32, 289436768_u32, 289714112_u32, 289991392_u32, 290268576_u32, 290545632_u32,
      290822592_u32, 291099456_u32, 291376224_u32, 291652896_u32, 291929440_u32, 292205888_u32, 292482272_u32, 292758528_u32,
      293034656_u32, 293310720_u32, 293586656_u32, 293862496_u32, 294138240_u32, 294413888_u32, 294689440_u32, 294964864_u32,
      295240192_u32, 295515424_u32, 295790560_u32, 296065600_u32, 296340512_u32, 296615360_u32, 296890080_u32, 297164704_u32,
      297439200_u32, 297713632_u32, 297987936_u32, 298262144_u32, 298536256_u32, 298810240_u32, 299084160_u32, 299357952_u32,
      299631648_u32, 299905248_u32, 300178720_u32, 300452128_u32, 300725408_u32, 300998592_u32, 301271680_u32, 301544640_u32,
      301817536_u32, 302090304_u32, 302362976_u32, 302635520_u32, 302908000_u32, 303180352_u32, 303452608_u32, 303724768_u32,
      303996800_u32, 304268768_u32, 304540608_u32, 304812320_u32, 305083968_u32, 305355520_u32, 305626944_u32, 305898272_u32,
      306169472_u32, 306440608_u32, 306711616_u32, 306982528_u32, 307253344_u32, 307524064_u32, 307794656_u32, 308065152_u32,
      308335552_u32, 308605856_u32, 308876032_u32, 309146112_u32, 309416096_u32, 309685984_u32, 309955744_u32, 310225408_u32,
      310494976_u32, 310764448_u32, 311033824_u32, 311303072_u32, 311572224_u32, 311841280_u32, 312110208_u32, 312379040_u32,
      312647776_u32, 312916416_u32, 313184960_u32, 313453376_u32, 313721696_u32, 313989920_u32, 314258016_u32, 314526016_u32,
      314793920_u32, 315061728_u32, 315329408_u32, 315597024_u32, 315864512_u32, 316131872_u32, 316399168_u32, 316666336_u32,
      316933408_u32, 317200384_u32, 317467232_u32, 317733984_u32, 318000640_u32, 318267200_u32, 318533632_u32, 318799968_u32,
      319066208_u32, 319332352_u32, 319598368_u32, 319864288_u32, 320130112_u32, 320395808_u32, 320661408_u32, 320926912_u32,
      321192320_u32, 321457632_u32, 321722816_u32, 321987904_u32, 322252864_u32, 322517760_u32, 322782528_u32, 323047200_u32,
      323311744_u32, 323576192_u32, 323840544_u32, 324104800_u32, 324368928_u32, 324632992_u32, 324896928_u32, 325160736_u32,
      325424448_u32, 325688096_u32, 325951584_u32, 326215008_u32, 326478304_u32, 326741504_u32, 327004608_u32, 327267584_u32,
      327530464_u32, 327793248_u32, 328055904_u32, 328318496_u32, 328580960_u32, 328843296_u32, 329105568_u32, 329367712_u32,
      329629760_u32, 329891680_u32, 330153536_u32, 330415264_u32, 330676864_u32, 330938400_u32, 331199808_u32, 331461120_u32,
      331722304_u32, 331983392_u32, 332244384_u32, 332505280_u32, 332766048_u32, 333026752_u32, 333287296_u32, 333547776_u32,
      333808128_u32, 334068384_u32, 334328544_u32, 334588576_u32, 334848512_u32, 335108352_u32, 335368064_u32, 335627712_u32,
      335887200_u32, 336146624_u32, 336405920_u32, 336665120_u32, 336924224_u32, 337183200_u32, 337442112_u32, 337700864_u32,
      337959552_u32, 338218112_u32, 338476576_u32, 338734944_u32, 338993184_u32, 339251328_u32, 339509376_u32, 339767296_u32,
      340025120_u32, 340282848_u32, 340540480_u32, 340797984_u32, 341055392_u32, 341312704_u32, 341569888_u32, 341826976_u32,
      342083968_u32, 342340832_u32, 342597600_u32, 342854272_u32, 343110848_u32, 343367296_u32, 343623648_u32, 343879904_u32,
      344136032_u32, 344392064_u32, 344648000_u32, 344903808_u32, 345159520_u32, 345415136_u32, 345670656_u32, 345926048_u32,
      346181344_u32, 346436512_u32, 346691616_u32, 346946592_u32, 347201440_u32, 347456224_u32, 347710880_u32, 347965440_u32,
      348219872_u32, 348474208_u32, 348728448_u32, 348982592_u32, 349236608_u32, 349490528_u32, 349744320_u32, 349998048_u32,
      350251648_u32, 350505152_u32, 350758528_u32, 351011808_u32, 351264992_u32, 351518048_u32, 351771040_u32, 352023872_u32,
      352276640_u32, 352529280_u32, 352781824_u32, 353034272_u32, 353286592_u32, 353538816_u32, 353790944_u32, 354042944_u32,
      354294880_u32, 354546656_u32, 354798368_u32, 355049952_u32, 355301440_u32, 355552800_u32, 355804096_u32, 356055264_u32,
      356306304_u32, 356557280_u32, 356808128_u32, 357058848_u32, 357309504_u32, 357560032_u32, 357810464_u32, 358060768_u32,
      358311008_u32, 358561088_u32, 358811104_u32, 359060992_u32, 359310784_u32, 359560480_u32, 359810048_u32, 360059520_u32,
      360308896_u32, 360558144_u32, 360807296_u32, 361056352_u32, 361305312_u32, 361554144_u32, 361802880_u32, 362051488_u32,
      362300032_u32, 362548448_u32, 362796736_u32, 363044960_u32, 363293056_u32, 363541024_u32, 363788928_u32, 364036704_u32,
      364284384_u32, 364531936_u32, 364779392_u32, 365026752_u32, 365274016_u32, 365521152_u32, 365768192_u32, 366015136_u32,
      366261952_u32, 366508672_u32, 366755296_u32, 367001792_u32, 367248192_u32, 367494496_u32, 367740704_u32, 367986784_u32,
      368232768_u32, 368478656_u32, 368724416_u32, 368970080_u32, 369215648_u32, 369461088_u32, 369706432_u32, 369951680_u32,
      370196800_u32, 370441824_u32, 370686752_u32, 370931584_u32, 371176288_u32, 371420896_u32, 371665408_u32, 371909792_u32,
      372154080_u32, 372398272_u32, 372642336_u32, 372886304_u32, 373130176_u32, 373373952_u32, 373617600_u32, 373861152_u32,
      374104608_u32, 374347936_u32, 374591168_u32, 374834304_u32, 375077312_u32, 375320224_u32, 375563040_u32, 375805760_u32,
      376048352_u32, 376290848_u32, 376533248_u32, 376775520_u32, 377017696_u32, 377259776_u32, 377501728_u32, 377743584_u32,
      377985344_u32, 378227008_u32, 378468544_u32, 378709984_u32, 378951328_u32, 379192544_u32, 379433664_u32, 379674688_u32,
      379915584_u32, 380156416_u32, 380397088_u32, 380637696_u32, 380878176_u32, 381118560_u32, 381358848_u32, 381599040_u32,
      381839104_u32, 382079072_u32, 382318912_u32, 382558656_u32, 382798304_u32, 383037856_u32, 383277280_u32, 383516640_u32,
      383755840_u32, 383994976_u32, 384233984_u32, 384472896_u32, 384711712_u32, 384950400_u32, 385188992_u32, 385427488_u32,
      385665888_u32, 385904160_u32, 386142336_u32, 386380384_u32, 386618368_u32, 386856224_u32, 387093984_u32, 387331616_u32,
      387569152_u32, 387806592_u32, 388043936_u32, 388281152_u32, 388518272_u32, 388755296_u32, 388992224_u32, 389229024_u32,
      389465728_u32, 389702336_u32, 389938816_u32, 390175200_u32, 390411488_u32, 390647680_u32, 390883744_u32, 391119712_u32,
      391355584_u32, 391591328_u32, 391826976_u32, 392062528_u32, 392297984_u32, 392533312_u32, 392768544_u32, 393003680_u32,
      393238720_u32, 393473632_u32, 393708448_u32, 393943168_u32, 394177760_u32, 394412256_u32, 394646656_u32, 394880960_u32,
      395115136_u32, 395349216_u32, 395583200_u32, 395817088_u32, 396050848_u32, 396284512_u32, 396518080_u32, 396751520_u32,
      396984864_u32, 397218112_u32, 397451264_u32, 397684288_u32, 397917248_u32, 398150080_u32, 398382784_u32, 398615424_u32,
      398847936_u32, 399080320_u32, 399312640_u32, 399544832_u32, 399776928_u32, 400008928_u32, 400240832_u32, 400472608_u32,
      400704288_u32, 400935872_u32, 401167328_u32, 401398720_u32, 401629984_u32, 401861120_u32, 402092192_u32, 402323136_u32,
      402553984_u32, 402784736_u32, 403015360_u32, 403245888_u32, 403476320_u32, 403706656_u32, 403936896_u32, 404167008_u32,
      404397024_u32, 404626944_u32, 404856736_u32, 405086432_u32, 405316032_u32, 405545536_u32, 405774912_u32, 406004224_u32,
      406233408_u32, 406462464_u32, 406691456_u32, 406920320_u32, 407149088_u32, 407377760_u32, 407606336_u32, 407834784_u32,
      408063136_u32, 408291392_u32, 408519520_u32, 408747584_u32, 408975520_u32, 409203360_u32, 409431072_u32, 409658720_u32,
      409886240_u32, 410113664_u32, 410340992_u32, 410568192_u32, 410795296_u32, 411022304_u32, 411249216_u32, 411476032_u32,
      411702720_u32, 411929312_u32, 412155808_u32, 412382176_u32, 412608480_u32, 412834656_u32, 413060736_u32, 413286720_u32,
      413512576_u32, 413738336_u32, 413964000_u32, 414189568_u32, 414415040_u32, 414640384_u32, 414865632_u32, 415090784_u32,
      415315840_u32, 415540800_u32, 415765632_u32, 415990368_u32, 416215008_u32, 416439552_u32, 416663968_u32, 416888288_u32,
      417112512_u32, 417336640_u32, 417560672_u32, 417784576_u32, 418008384_u32, 418232096_u32, 418455712_u32, 418679200_u32,
      418902624_u32, 419125920_u32, 419349120_u32, 419572192_u32, 419795200_u32, 420018080_u32, 420240864_u32, 420463552_u32,
      420686144_u32, 420908608_u32, 421130976_u32, 421353280_u32, 421575424_u32, 421797504_u32, 422019488_u32, 422241344_u32,
      422463104_u32, 422684768_u32, 422906336_u32, 423127776_u32, 423349120_u32, 423570400_u32, 423791520_u32, 424012576_u32,
      424233536_u32, 424454368_u32, 424675104_u32, 424895744_u32, 425116288_u32, 425336736_u32, 425557056_u32, 425777280_u32,
      425997408_u32, 426217440_u32, 426437376_u32, 426657184_u32, 426876928_u32, 427096544_u32, 427316064_u32, 427535488_u32,
      427754784_u32, 427974016_u32, 428193120_u32, 428412128_u32, 428631040_u32, 428849856_u32, 429068544_u32, 429287168_u32,
      429505664_u32, 429724064_u32, 429942368_u32, 430160576_u32, 430378656_u32, 430596672_u32, 430814560_u32, 431032352_u32,
      431250048_u32, 431467616_u32, 431685120_u32, 431902496_u32, 432119808_u32, 432336992_u32, 432554080_u32, 432771040_u32,
      432987936_u32, 433204736_u32, 433421408_u32, 433637984_u32, 433854464_u32, 434070848_u32, 434287104_u32, 434503296_u32,
      434719360_u32, 434935360_u32, 435151232_u32, 435367008_u32, 435582656_u32, 435798240_u32, 436013696_u32, 436229088_u32,
      436444352_u32, 436659520_u32, 436874592_u32, 437089568_u32, 437304416_u32, 437519200_u32, 437733856_u32, 437948416_u32,
      438162880_u32, 438377248_u32, 438591520_u32, 438805696_u32, 439019744_u32, 439233728_u32, 439447584_u32, 439661344_u32,
      439875008_u32, 440088576_u32, 440302048_u32, 440515392_u32, 440728672_u32, 440941824_u32, 441154880_u32, 441367872_u32,
      441580736_u32, 441793472_u32, 442006144_u32, 442218720_u32, 442431168_u32, 442643552_u32, 442855808_u32, 443067968_u32,
      443280032_u32, 443492000_u32, 443703872_u32, 443915648_u32, 444127296_u32, 444338880_u32, 444550336_u32, 444761696_u32,
      444972992_u32, 445184160_u32, 445395232_u32, 445606176_u32, 445817056_u32, 446027840_u32, 446238496_u32, 446449088_u32,
      446659552_u32, 446869920_u32, 447080192_u32, 447290400_u32, 447500448_u32, 447710432_u32, 447920320_u32, 448130112_u32,
      448339776_u32, 448549376_u32, 448758848_u32, 448968224_u32, 449177536_u32, 449386720_u32, 449595808_u32, 449804800_u32,
      450013664_u32, 450222464_u32, 450431168_u32, 450639776_u32, 450848256_u32, 451056640_u32, 451264960_u32, 451473152_u32,
      451681248_u32, 451889248_u32, 452097152_u32, 452304960_u32, 452512672_u32, 452720288_u32, 452927808_u32, 453135232_u32,
      453342528_u32, 453549760_u32, 453756864_u32, 453963904_u32, 454170816_u32, 454377632_u32, 454584384_u32, 454791008_u32,
      454997536_u32, 455203968_u32, 455410304_u32, 455616544_u32, 455822688_u32, 456028704_u32, 456234656_u32, 456440512_u32,
      456646240_u32, 456851904_u32, 457057472_u32, 457262912_u32, 457468256_u32, 457673536_u32, 457878688_u32, 458083744_u32,
      458288736_u32, 458493600_u32, 458698368_u32, 458903040_u32, 459107616_u32, 459312096_u32, 459516480_u32, 459720768_u32,
      459924960_u32, 460129056_u32, 460333056_u32, 460536960_u32, 460740736_u32, 460944448_u32, 461148064_u32, 461351584_u32,
      461554976_u32, 461758304_u32, 461961536_u32, 462164640_u32, 462367680_u32, 462570592_u32, 462773440_u32, 462976160_u32,
      463178816_u32, 463381344_u32, 463583776_u32, 463786144_u32, 463988384_u32, 464190560_u32, 464392608_u32, 464594560_u32,
      464796448_u32, 464998208_u32, 465199872_u32, 465401472_u32, 465602944_u32, 465804320_u32, 466005600_u32, 466206816_u32,
      466407904_u32, 466608896_u32, 466809824_u32, 467010624_u32, 467211328_u32, 467411936_u32, 467612480_u32, 467812896_u32,
      468013216_u32, 468213440_u32, 468413600_u32, 468613632_u32, 468813568_u32, 469013440_u32, 469213184_u32, 469412832_u32,
      469612416_u32, 469811872_u32, 470011232_u32, 470210528_u32, 470409696_u32, 470608800_u32, 470807776_u32, 471006688_u32,
      471205472_u32, 471404192_u32, 471602784_u32, 471801312_u32, 471999712_u32, 472198048_u32, 472396288_u32, 472594400_u32,
      472792448_u32, 472990400_u32, 473188256_u32, 473385984_u32, 473583648_u32, 473781216_u32, 473978688_u32, 474176064_u32,
      474373344_u32, 474570528_u32, 474767616_u32, 474964608_u32, 475161504_u32, 475358336_u32, 475555040_u32, 475751648_u32,
      475948192_u32, 476144608_u32, 476340928_u32, 476537184_u32, 476733312_u32, 476929376_u32, 477125344_u32, 477321184_u32,
      477516960_u32, 477712640_u32, 477908224_u32, 478103712_u32, 478299104_u32, 478494400_u32, 478689600_u32, 478884704_u32,
      479079744_u32, 479274656_u32, 479469504_u32, 479664224_u32, 479858880_u32, 480053408_u32, 480247872_u32, 480442240_u32,
      480636512_u32, 480830656_u32, 481024736_u32, 481218752_u32, 481412640_u32, 481606432_u32, 481800128_u32, 481993760_u32,
      482187264_u32, 482380704_u32, 482574016_u32, 482767264_u32, 482960416_u32, 483153472_u32, 483346432_u32, 483539296_u32,
      483732064_u32, 483924768_u32, 484117344_u32, 484309856_u32, 484502240_u32, 484694560_u32, 484886784_u32, 485078912_u32,
      485270944_u32, 485462880_u32, 485654720_u32, 485846464_u32, 486038144_u32, 486229696_u32, 486421184_u32, 486612576_u32,
      486803840_u32, 486995040_u32, 487186176_u32, 487377184_u32, 487568096_u32, 487758912_u32, 487949664_u32, 488140320_u32,
      488330880_u32, 488521312_u32, 488711712_u32, 488901984_u32, 489092160_u32, 489282240_u32, 489472256_u32, 489662176_u32,
      489851968_u32, 490041696_u32, 490231328_u32, 490420896_u32, 490610336_u32, 490799712_u32, 490988960_u32, 491178144_u32,
      491367232_u32, 491556224_u32, 491745120_u32, 491933920_u32, 492122656_u32, 492311264_u32, 492499808_u32, 492688256_u32,
      492876608_u32, 493064864_u32, 493253056_u32, 493441120_u32, 493629120_u32, 493817024_u32, 494004832_u32, 494192544_u32,
      494380160_u32, 494567712_u32, 494755136_u32, 494942496_u32, 495129760_u32, 495316928_u32, 495504000_u32, 495691008_u32,
      495877888_u32, 496064704_u32, 496251424_u32, 496438048_u32, 496624608_u32, 496811040_u32, 496997408_u32, 497183680_u32,
      497369856_u32, 497555936_u32, 497741920_u32, 497927840_u32, 498113632_u32, 498299360_u32, 498484992_u32, 498670560_u32,
      498856000_u32, 499041376_u32, 499226656_u32, 499411840_u32, 499596928_u32, 499781920_u32, 499966848_u32, 500151680_u32,
      500336416_u32, 500521056_u32, 500705600_u32, 500890080_u32, 501074464_u32, 501258752_u32, 501442944_u32, 501627040_u32,
      501811072_u32, 501995008_u32, 502178848_u32, 502362592_u32, 502546240_u32, 502729824_u32, 502913312_u32, 503096704_u32,
      503280000_u32, 503463232_u32, 503646368_u32, 503829408_u32, 504012352_u32, 504195200_u32, 504377984_u32, 504560672_u32,
      504743264_u32, 504925760_u32, 505108192_u32, 505290496_u32, 505472736_u32, 505654912_u32, 505836960_u32, 506018944_u32,
      506200832_u32, 506382624_u32, 506564320_u32, 506745952_u32, 506927488_u32, 507108928_u32, 507290272_u32, 507471552_u32,
      507652736_u32, 507833824_u32, 508014816_u32, 508195744_u32, 508376576_u32, 508557312_u32, 508737952_u32, 508918528_u32,
      509099008_u32, 509279392_u32, 509459680_u32, 509639904_u32, 509820032_u32, 510000064_u32, 510180000_u32, 510359872_u32,
      510539648_u32, 510719328_u32, 510898944_u32, 511078432_u32, 511257856_u32, 511437216_u32, 511616448_u32, 511795616_u32,
      511974688_u32, 512153664_u32, 512332576_u32, 512511392_u32, 512690112_u32, 512868768_u32, 513047296_u32, 513225792_u32,
      513404160_u32, 513582432_u32, 513760640_u32, 513938784_u32, 514116800_u32, 514294752_u32, 514472608_u32, 514650368_u32,
      514828064_u32, 515005664_u32, 515183168_u32, 515360608_u32, 515537952_u32, 515715200_u32, 515892352_u32, 516069440_u32,
      516246432_u32, 516423328_u32, 516600160_u32, 516776896_u32, 516953536_u32, 517130112_u32, 517306592_u32, 517482976_u32,
      517659264_u32, 517835488_u32, 518011616_u32, 518187680_u32, 518363648_u32, 518539520_u32, 518715296_u32, 518891008_u32,
      519066624_u32, 519242144_u32, 519417600_u32, 519592960_u32, 519768256_u32, 519943424_u32, 520118528_u32, 520293568_u32,
      520468480_u32, 520643328_u32, 520818112_u32, 520992800_u32, 521167392_u32, 521341888_u32, 521516320_u32, 521690656_u32,
      521864896_u32, 522039072_u32, 522213152_u32, 522387168_u32, 522561056_u32, 522734912_u32, 522908640_u32, 523082304_u32,
      523255872_u32, 523429376_u32, 523602784_u32, 523776096_u32, 523949312_u32, 524122464_u32, 524295552_u32, 524468512_u32,
      524641440_u32, 524814240_u32, 524986976_u32, 525159616_u32, 525332192_u32, 525504640_u32, 525677056_u32, 525849344_u32,
      526021568_u32, 526193728_u32, 526365792_u32, 526537760_u32, 526709632_u32, 526881440_u32, 527053152_u32, 527224800_u32,
      527396352_u32, 527567840_u32, 527739200_u32, 527910528_u32, 528081728_u32, 528252864_u32, 528423936_u32, 528594880_u32,
      528765760_u32, 528936576_u32, 529107296_u32, 529277920_u32, 529448480_u32, 529618944_u32, 529789344_u32, 529959648_u32,
      530129856_u32, 530300000_u32, 530470048_u32, 530640000_u32, 530809888_u32, 530979712_u32, 531149440_u32, 531319072_u32,
      531488608_u32, 531658080_u32, 531827488_u32, 531996800_u32, 532166016_u32, 532335168_u32, 532504224_u32, 532673184_u32,
      532842080_u32, 533010912_u32, 533179616_u32, 533348288_u32, 533516832_u32, 533685312_u32, 533853728_u32, 534022048_u32,
      534190272_u32, 534358432_u32, 534526496_u32, 534694496_u32, 534862400_u32, 535030240_u32, 535197984_u32, 535365632_u32,
      535533216_u32, 535700704_u32, 535868128_u32, 536035456_u32, 536202720_u32, 536369888_u32, 536536992_u32, 536704000_u32,
      536870912_u32,
    ]
  {% else %}
    @@finetangent = [] of CDoom::Fixed
    @@finesine = [] of CDoom::Fixed
    @@tantoangle : Array(UInt32) = [] of UInt32
  {% end %}
  @@finecosine : Array(CDoom::Fixed) = [] of CDoom::Fixed

  # Now where did these came from?
  c_array((CDoom.gammatable.to_unsafe).value,
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
    17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32,
    33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48,
    49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64,
    65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80,
    81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96,
    97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112,
    113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128,
    128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143,
    144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159,
    160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175,
    176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191,
    192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207,
    208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223,
    224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239,
    240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255
  )
  c_array((CDoom.gammatable.to_unsafe + 1).value,
    2, 4, 5, 7, 8, 10, 11, 12, 14, 15, 16, 18, 19, 20, 21, 23, 24, 25, 26, 27, 29, 30, 31,
    32, 33, 34, 36, 37, 38, 39, 40, 41, 42, 44, 45, 46, 47, 48, 49, 50, 51, 52, 54, 55,
    56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 69, 70, 71, 72, 73, 74, 75, 76, 77,
    78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98,
    99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114,
    115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 129,
    130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145,
    146, 147, 148, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160,
    161, 162, 163, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175,
    175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 186, 187, 188, 189,
    190, 191, 192, 193, 194, 195, 196, 196, 197, 198, 199, 200, 201, 202, 203, 204,
    205, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 214, 215, 216, 217, 218,
    219, 220, 221, 222, 222, 223, 224, 225, 226, 227, 228, 229, 230, 230, 231, 232,
    233, 234, 235, 236, 237, 237, 238, 239, 240, 241, 242, 243, 244, 245, 245, 246,
    247, 248, 249, 250, 251, 252, 252, 253, 254, 255
  )
  c_array((CDoom.gammatable.to_unsafe + 2).value,
    4, 7, 9, 11, 13, 15, 17, 19, 21, 22, 24, 26, 27, 29, 30, 32, 33, 35, 36, 38, 39, 40, 42,
    43, 45, 46, 47, 48, 50, 51, 52, 54, 55, 56, 57, 59, 60, 61, 62, 63, 65, 66, 67, 68, 69,
    70, 72, 73, 74, 75, 76, 77, 78, 79, 80, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93,
    94, 95, 96, 97, 98, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112,
    113, 114, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128,
    129, 130, 131, 132, 133, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144,
    144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 153, 154, 155, 156, 157, 158, 159,
    160, 160, 161, 162, 163, 164, 165, 166, 166, 167, 168, 169, 170, 171, 172, 172, 173,
    174, 175, 176, 177, 178, 178, 179, 180, 181, 182, 183, 183, 184, 185, 186, 187, 188,
    188, 189, 190, 191, 192, 193, 193, 194, 195, 196, 197, 197, 198, 199, 200, 201, 201,
    202, 203, 204, 205, 206, 206, 207, 208, 209, 210, 210, 211, 212, 213, 213, 214, 215,
    216, 217, 217, 218, 219, 220, 221, 221, 222, 223, 224, 224, 225, 226, 227, 228, 228,
    229, 230, 231, 231, 232, 233, 234, 235, 235, 236, 237, 238, 238, 239, 240, 241, 241,
    242, 243, 244, 244, 245, 246, 247, 247, 248, 249, 250, 251, 251, 252, 253, 254, 254,
    255
  )
  c_array((CDoom.gammatable.to_unsafe + 3).value,
    8, 12, 16, 19, 22, 24, 27, 29, 31, 34, 36, 38, 40, 41, 43, 45, 47, 49, 50, 52, 53, 55,
    57, 58, 60, 61, 63, 64, 65, 67, 68, 70, 71, 72, 74, 75, 76, 77, 79, 80, 81, 82, 84, 85,
    86, 87, 88, 90, 91, 92, 93, 94, 95, 96, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107,
    108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124,
    125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 135, 136, 137, 138, 139, 140,
    141, 142, 143, 143, 144, 145, 146, 147, 148, 149, 150, 150, 151, 152, 153, 154, 155,
    155, 156, 157, 158, 159, 160, 160, 161, 162, 163, 164, 165, 165, 166, 167, 168, 169,
    169, 170, 171, 172, 173, 173, 174, 175, 176, 176, 177, 178, 179, 180, 180, 181, 182,
    183, 183, 184, 185, 186, 186, 187, 188, 189, 189, 190, 191, 192, 192, 193, 194, 195,
    195, 196, 197, 197, 198, 199, 200, 200, 201, 202, 202, 203, 204, 205, 205, 206, 207,
    207, 208, 209, 210, 210, 211, 212, 212, 213, 214, 214, 215, 216, 216, 217, 218, 219,
    219, 220, 221, 221, 222, 223, 223, 224, 225, 225, 226, 227, 227, 228, 229, 229, 230,
    231, 231, 232, 233, 233, 234, 235, 235, 236, 237, 237, 238, 238, 239, 240, 240, 241,
    242, 242, 243, 244, 244, 245, 246, 246, 247, 247, 248, 249, 249, 250, 251, 251, 252,
    253, 253, 254, 254, 255
  )
  c_array((CDoom.gammatable.to_unsafe + 4).value,
    16, 23, 28, 32, 36, 39, 42, 45, 48, 50, 53, 55, 57, 60, 62, 64, 66, 68, 69, 71, 73, 75, 76,
    78, 80, 81, 83, 84, 86, 87, 89, 90, 92, 93, 94, 96, 97, 98, 100, 101, 102, 103, 105, 106,
    107, 108, 109, 110, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124,
    125, 126, 128, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141,
    142, 143, 143, 144, 145, 146, 147, 148, 149, 150, 150, 151, 152, 153, 154, 155, 155,
    156, 157, 158, 159, 159, 160, 161, 162, 163, 163, 164, 165, 166, 166, 167, 168, 169,
    169, 170, 171, 172, 172, 173, 174, 175, 175, 176, 177, 177, 178, 179, 180, 180, 181,
    182, 182, 183, 184, 184, 185, 186, 187, 187, 188, 189, 189, 190, 191, 191, 192, 193,
    193, 194, 195, 195, 196, 196, 197, 198, 198, 199, 200, 200, 201, 202, 202, 203, 203,
    204, 205, 205, 206, 207, 207, 208, 208, 209, 210, 210, 211, 211, 212, 213, 213, 214,
    214, 215, 216, 216, 217, 217, 218, 219, 219, 220, 220, 221, 221, 222, 223, 223, 224,
    224, 225, 225, 226, 227, 227, 228, 228, 229, 229, 230, 230, 231, 232, 232, 233, 233,
    234, 234, 235, 235, 236, 236, 237, 237, 238, 239, 239, 240, 240, 241, 241, 242, 242,
    243, 243, 244, 244, 245, 245, 246, 246, 247, 247, 248, 248, 249, 249, 250, 250, 251,
    251, 252, 252, 253, 254, 254, 255, 255
  )

  # Episode 0 World Map
  @@lnodes0 = [
    CDoom::Point.new(x: 185, y: 164), # location of level 0 (CJ)
    CDoom::Point.new(x: 148, y: 143), # location of level 1 (CJ)
    CDoom::Point.new(x: 69, y: 122),  # location of level 2 (CJ)
    CDoom::Point.new(x: 209, y: 102), # location of level 3 (CJ)
    CDoom::Point.new(x: 116, y: 89),  # location of level 4 (CJ)
    CDoom::Point.new(x: 166, y: 55),  # location of level 5 (CJ)
    CDoom::Point.new(x: 71, y: 56),   # location of level 6 (CJ)
    CDoom::Point.new(x: 135, y: 29),  # location of level 7 (CJ)
    CDoom::Point.new(x: 71, y: 24),   # location of level 8 (CJ)
  ]

  # Episode 1 World Map should go here
  @@lnodes1 = [
    CDoom::Point.new(x: 254, y: 25),  # location of level 0 (CJ)
    CDoom::Point.new(x: 97, y: 50),   # location of level 1 (CJ)
    CDoom::Point.new(x: 188, y: 64),  # location of level 2 (CJ)
    CDoom::Point.new(x: 128, y: 78),  # location of level 3 (CJ)
    CDoom::Point.new(x: 214, y: 92),  # location of level 4 (CJ)
    CDoom::Point.new(x: 133, y: 130), # location of level 5 (CJ)
    CDoom::Point.new(x: 208, y: 136), # location of level 6 (CJ)
    CDoom::Point.new(x: 148, y: 140), # location of level 7 (CJ)
    CDoom::Point.new(x: 235, y: 158), # location of level 8 (CJ)
  ]

  # Episode 2 World Map should go here
  @@lnodes2 = [
    CDoom::Point.new(x: 156, y: 168), # location of level 0 (CJ)
    CDoom::Point.new(x: 48, y: 154),  # location of level 1 (CJ)
    CDoom::Point.new(x: 174, y: 95),  # location of level 2 (CJ)
    CDoom::Point.new(x: 265, y: 75),  # location of level 3 (CJ)
    CDoom::Point.new(x: 130, y: 48),  # location of level 4 (CJ)
    CDoom::Point.new(x: 279, y: 23),  # location of level 5 (CJ)
    CDoom::Point.new(x: 198, y: 48),  # location of level 6 (CJ)
    CDoom::Point.new(x: 140, y: 25),  # location of level 7 (CJ)
    CDoom::Point.new(x: 281, y: 136), # location of level 8 (CJ)
  ]

  c_array(CDoom.lnodes,
    @@lnodes0.to_unsafe,
    @@lnodes1.to_unsafe,
    @@lnodes2.to_unsafe
  )

  c_array_animinfo(CDoom.epsd0animinfo,
    {CDoom::Animenum::Always, CDoom::TICRATE // 3, 3, {224, 104}, 0},
    {CDoom::Animenum::Always, CDoom::TICRATE // 3, 3, {184, 160}, 0},
    {CDoom::Animenum::Always, CDoom::TICRATE // 3, 3, {112, 136}, 0},
    {CDoom::Animenum::Always, CDoom::TICRATE // 3, 3, {72, 112}, 0},
    {CDoom::Animenum::Always, CDoom::TICRATE // 3, 3, {88, 96}, 0},
    {CDoom::Animenum::Always, CDoom::TICRATE // 3, 3, {64, 48}, 0},
    {CDoom::Animenum::Always, CDoom::TICRATE // 3, 3, {192, 40}, 0},
    {CDoom::Animenum::Always, CDoom::TICRATE // 3, 3, {136, 16}, 0},
    {CDoom::Animenum::Always, CDoom::TICRATE // 3, 3, {80, 16}, 0},
    {CDoom::Animenum::Always, CDoom::TICRATE // 3, 3, {64, 24}, 0}
  )

  c_array_animinfo(CDoom.epsd1animinfo,
    {CDoom::Animenum::Level, CDoom::TICRATE // 3, 1, {128, 136}, 1},
    {CDoom::Animenum::Level, CDoom::TICRATE // 3, 1, {128, 136}, 2},
    {CDoom::Animenum::Level, CDoom::TICRATE // 3, 1, {128, 136}, 3},
    {CDoom::Animenum::Level, CDoom::TICRATE // 3, 1, {128, 136}, 4},
    {CDoom::Animenum::Level, CDoom::TICRATE // 3, 1, {128, 136}, 5},
    {CDoom::Animenum::Level, CDoom::TICRATE // 3, 1, {128, 136}, 6},
    {CDoom::Animenum::Level, CDoom::TICRATE // 3, 1, {128, 136}, 7},
    {CDoom::Animenum::Level, CDoom::TICRATE // 3, 3, {192, 144}, 8},
    {CDoom::Animenum::Level, CDoom::TICRATE // 3, 1, {128, 136}, 8}
  )

  c_array_animinfo(CDoom.epsd2animinfo,
    {CDoom::Animenum::Always, CDoom::TICRATE // 3, 3, {104, 168}, 0},
    {CDoom::Animenum::Always, CDoom::TICRATE // 3, 3, {40, 136}, 0},
    {CDoom::Animenum::Always, CDoom::TICRATE // 3, 3, {160, 96}, 0},
    {CDoom::Animenum::Always, CDoom::TICRATE // 3, 3, {104, 80}, 0},
    {CDoom::Animenum::Always, CDoom::TICRATE // 3, 3, {120, 32}, 0},
    {CDoom::Animenum::Always, CDoom::TICRATE // 4, 3, {40, 0}, 0}
  )

  c_array(CDoom.numanims,
    sizeof(typeof(CDoom.epsd0animinfo)) // sizeof(CDoom::AnimWIStuff),
    sizeof(typeof(CDoom.epsd1animinfo)) // sizeof(CDoom::AnimWIStuff),
    sizeof(typeof(CDoom.epsd2animinfo)) // sizeof(CDoom::AnimWIStuff),
  )

  c_array(CDoom.anims_wi_stuff,
    CDoom.epsd0animinfo.to_unsafe,
    CDoom.epsd1animinfo.to_unsafe,
    CDoom.epsd2animinfo.to_unsafe
  )

  CDoom.snl_pointeron = 0
end
