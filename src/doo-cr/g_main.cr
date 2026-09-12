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
# ==> Main game loop/control

module Doocr
  @@oldentertics : Int32 = 0

  #
  # try_run_tics
  #
  def self.try_run_tics
    # get real tics
    entertic = CDoom.i_get_time // Doocr.ticdup
    realtics = entertic - @@oldentertics
    @@oldentertics = entertic

    # get available tics
    CDoom.net_update

    lowtic = Int32::MAX
    numplaying = 0
    Doocr.doomcom.value.numnodes.times do |i|
      if Doocr.nodeingame[i] != 0
        numplaying += 1
        lowtic = Doocr.nettics[i] if Doocr.nettics[i] < lowtic
      end
    end
    availabletics = lowtic - Doocr.gametic // Doocr.ticdup

    counts = availabletics
    # decide how many tics to run
    if realtics < availabletics - 1
      counts = realtics + 1
    elsif realtics < availabletics
      counts = realtics
    end

    counts = 1 if counts < 1

    Doocr.frameon += 1

    if Doocr.debugfile
      Doocr.debug_fprint("=======real: ")
      Doocr.debug_fprint(CDoom.doom_itoa(realtics, 10))
      Doocr.debug_fprint("  avail: ")
      Doocr.debug_fprint(CDoom.doom_itoa(availabletics, 10))
      Doocr.debug_fprint("  game: ")
      Doocr.debug_fprint(CDoom.doom_itoa(counts, 10))
      Doocr.debug_fprint("\n")
    end

    if Doocr.demoplayback == 0
      i = 0
      while i < CDoom::MAXPLAYERS
        break if Doocr.playeringame[i] != 0
        i += 1
      end
      if Doocr.consoleplayer == i
        # the key player does not adapt
      else
        if Doocr.nettics[0] <= Doocr.nettics[Doocr.nodeforplayer[i]]
          Doocr.gametime -= 1
        end
        Doocr.frameskip[Doocr.frameon & 3] = (Doocr.oldnettics > Doocr.nettics[Doocr.nodeforplayer[i]]).to_unsafe
        Doocr.oldnettics = Doocr.nettics[0]
        if Doocr.frameskip[0] != 0 && Doocr.frameskip[1] != 0 && Doocr.frameskip[2] != 0 && Doocr.frameskip[3] != 0
          Doocr.skiptics = 1
        end
      end
    end

    # wait for new tics if needed
    while lowtic < Doocr.gametic // Doocr.ticdup + counts
      i_poll_mouse
      CDoom.net_update
      lowtic = Int32::MAX

      Doocr.doomcom.value.numnodes.times do |i|
        lowtic = Doocr.nettics[i] if Doocr.nodeingame[i] != 0 && Doocr.nettics[i] < lowtic
      end

      CDoom.i_error("Error: try_run_tics: lowtic < Doocr.gametic") if lowtic < Doocr.gametic // Doocr.ticdup

      # don't stay in here forever -- give the menu a chance to work
      if CDoom.i_get_time // Doocr.ticdup - entertic >= 20
        CDoom.m_ticker
        return
      end
    end

    # run the count * ticdup dics
    while counts != 0
      Doocr.ticdup.times do |i|
        CDoom.i_error("Error: gametic>lowtic") if Doocr.gametic // Doocr.ticdup > lowtic
        CDoom.d_do_advance_demo if Doocr.advancedemo != 0
        CDoom.m_ticker
        CDoom.g_ticker
        Doocr.gametic &+= 1

        # modify command for duplicated tics
        if i != Doocr.ticdup - 1
          buf = (Doocr.gametic // Doocr.ticdup) % Doocr::BACKUPTICS
          CDoom::MAXPLAYERS.times do |j|
            cmd = (Doocr.netcmds.to_unsafe + j).value.to_unsafe + buf
            cmd.value.chatchar = 0
            cmd.value.buttons = 0 if cmd.value.buttons & Doocr::Buttoncode::BT_SPECIAL.value != 0
          end
        end
      end
      CDoom.net_update # check for new console commands

      counts -= 1
    end
  end

  #
  # g_build_ticcmd
  # Builds a ticcmd from all of the available inputs
  # or reads it from the demo buffer.
  # If recording a demo, write it out
  #
  def self.g_build_ticcmd(cmd : CDoom::Ticcmd*)
    base = CDoom.i_base_ticcmd # empty, or external driver
    CDoom.doom_memcpy(cmd, base, sizeof(typeof(cmd.value)))

    cmd.value.consistancy =
      Doocr.consistancy[Doocr.consoleplayer][Doocr.maketic % Doocr::BACKUPTICS]

    unless Doocr.menuactive != 0
      strafe = (Doocr.gamekeydown[Doocr.key_strafe] != 0 || Doocr.mousebuttons[Doocr.mousebstrafe] != 0 ||
                Doocr.joybuttons[Doocr.joybstrafe] != 0).to_unsafe

      running = Doocr.always_run != 0 ? (Doocr.gamekeydown[Doocr.key_speed] != 0 ? false : true) : (Doocr.gamekeydown[Doocr.key_speed] != 0 ? true : false)
      speed = (running || Doocr.joybuttons[Doocr.joybspeed] != 0).to_unsafe

      forward = 0
      side = 0

      # use two stage accelerative turning
      # on the keyboard and joystick
      if Doocr.joyxmove < 0 ||
         Doocr.joyxmove > 0 ||
         Doocr.gamekeydown[Doocr.key_right] != 0 ||
         Doocr.gamekeydown[Doocr.key_left] != 0
        Doocr.turnheld += Doocr.ticdup
      else
        Doocr.turnheld = 0
      end

      tspeed = speed
      tspeed = 2 if Doocr.turnheld < Doocr::SLOWTURNTICS # slow turn

      # let movement keys cancel each other out
      if strafe != 0
        side += Doocr.sidemove[speed] if Doocr.gamekeydown[Doocr.key_right] != 0
        side -= Doocr.sidemove[speed] if Doocr.gamekeydown[Doocr.key_left] != 0
        side += Doocr.sidemove[speed] if Doocr.joyxmove > 0
        side -= Doocr.sidemove[speed] if Doocr.joyxmove < 0
      else
        cmd.value.angleturn = cmd.value.angleturn - Doocr.angleturn[tspeed] if Doocr.gamekeydown[Doocr.key_right] != 0
        cmd.value.angleturn = cmd.value.angleturn + Doocr.angleturn[tspeed] if Doocr.gamekeydown[Doocr.key_left] != 0
        cmd.value.angleturn = cmd.value.angleturn - Doocr.angleturn[tspeed] if Doocr.joyxmove > 0
        cmd.value.angleturn = cmd.value.angleturn + Doocr.angleturn[tspeed] if Doocr.joyxmove < 0
      end

      forward += Doocr.forwardmove[speed] if Doocr.gamekeydown[Doocr.key_up] != 0
      forward -= Doocr.forwardmove[speed] if Doocr.gamekeydown[Doocr.key_down] != 0
      forward += Doocr.forwardmove[speed] if Doocr.joyymove < 0
      forward -= Doocr.forwardmove[speed] if Doocr.joyymove > 0

      side += Doocr.sidemove[speed] if Doocr.gamekeydown[Doocr.key_straferight] != 0
      side -= Doocr.sidemove[speed] if Doocr.gamekeydown[Doocr.key_strafeleft] != 0

      # buttons
      cmd.value.chatchar = CDoom.hu_dequeue_chat_char

      if Doocr.gamekeydown[Doocr.key_fire] != 0 || Doocr.mousebuttons[Doocr.mousebfire] != 0 ||
         Doocr.joybuttons[Doocr.joybfire] != 0
        cmd.value.buttons = cmd.value.buttons | Doocr::Buttoncode::BT_ATTACK.value
      end

      if Doocr.gamekeydown[Doocr.key_use] != 0 || Doocr.joybuttons[Doocr.joybuse] != 0
        cmd.value.buttons = cmd.value.buttons | Doocr::Buttoncode::BT_USE.value
        # clear double clicks if hit use button
        Doocr.dclicks = 0
      end

      # chainsaw overrides
      (Doocr::Weapontype::NUMWEAPONS.value - 1).times do |i|
        if Doocr.gamekeydown['1'.ord + i] != 0
          cmd.value.buttons = cmd.value.buttons | Doocr::Buttoncode::BT_CHANGE.value
          cmd.value.buttons = cmd.value.buttons | i << Doocr::Buttoncode::BT_WEAPONSHIFT.value
          break
        end
      end

      # mouse
      forward += Doocr.forwardmove[speed] if Doocr.mousebuttons[Doocr.mousebforward] != 0

      # forward double click
      if Doocr.mousebuttons[Doocr.mousebforward] != Doocr.dclickstate && Doocr.dclicktime > 1
        Doocr.dclickstate = Doocr.mousebuttons[Doocr.mousebforward]
        Doocr.dclicks += 1 if Doocr.dclickstate != 0
        if Doocr.dclicks == 2
          cmd.value.buttons = cmd.value.buttons | Doocr::Buttoncode::BT_USE.value
          Doocr.dclicks = 0
        else
          Doocr.dclicktime = 0
        end
      else
        Doocr.dclicktime += Doocr.ticdup
        if Doocr.dclicktime > 20
          Doocr.dclicks = 0
          Doocr.dclickstate = 0
        end
      end

      # strafe double click
      bstrafe =
        (Doocr.mousebuttons[Doocr.mousebstrafe] != 0 ||
          Doocr.joybuttons[Doocr.joybstrafe] != 0).to_unsafe
      if bstrafe != Doocr.dclickstate2 && Doocr.dclicktime2 > 1
        Doocr.dclickstate2 = bstrafe
        Doocr.dclicks2 += 1 if Doocr.dclickstate2 != 0
        if Doocr.dclicks2 == 2
          cmd.value.buttons = cmd.value.buttons | Doocr::Buttoncode::BT_USE.value
          Doocr.dclicks2 = 0
        else
          Doocr.dclicktime2 = 0
        end
      else
        Doocr.dclicktime2 += Doocr.ticdup
        if Doocr.dclicktime2 > 20
          Doocr.dclicks2 = 0
          Doocr.dclickstate2 = 0
        end
      end

      forward += @@mousey if Doocr.mousemove != 0
      if strafe != 0
        side += @@mousex * 2
      else
        cmd.value.angleturn = cmd.value.angleturn &- @@mousex * 0x8
      end

      @@mousex = 0
      @@mousey = 0

      maxplmove = Doocr.forwardmove[1]

      if forward > maxplmove
        forward = maxplmove
      elsif forward < -maxplmove
        forward = -maxplmove
      end
      if side > maxplmove
        side = maxplmove
      elsif side < -maxplmove
        side = -maxplmove
      end

      cmd.value.forwardmove = cmd.value.forwardmove &+ forward
      cmd.value.sidemove = cmd.value.sidemove &+ side
    end

    # special buttons
    if Doocr.sendpause != 0
      Doocr.sendpause = 0
      cmd.value.buttons = Doocr::Buttoncode::BT_SPECIAL.value | Doocr::Buttoncode::BTS_PAUSE.value
    end

    if Doocr.sendsave != 0
      Doocr.sendsave = 0
      cmd.value.buttons = Doocr::Buttoncode::BT_SPECIAL.value | Doocr::Buttoncode::BTS_SAVEGAME.value | (Doocr.savegameslot << Doocr::Buttoncode::BTS_SAVESHIFT.value)
    end
  end

  #
  # g_do_load_level
  #
  def self.g_do_load_level
    # Set the sky map.
    # First thing, we have a dummy sky texture name,
    #  a flat. The data is in the WAD only because
    #  we look for an actual index, instead of simply
    #  setting one.
    Doocr.skyflatnum = CDoom.r_flat_num_for_name(Doocr::SKYFLATNAME)

    # DOOM determines the sky texture to be used
    # depending on the current episode, and the game version.
    if Doocr.gamemode == Doocr::GameMode::Commercial ||
       Doocr.gamemission == Doocr::GameMission::PackTnt ||
       Doocr.gamemission == Doocr::GameMission::PackPlut
      Doocr.skytexture = CDoom.r_texture_num_for_name("SKY3")
      if Doocr.gamemap < 12
        Doocr.skytexture = CDoom.r_texture_num_for_name("SKY1")
      elsif Doocr.gamemap < 21
        Doocr.skytexture = CDoom.r_texture_num_for_name("SKY2")
      end
    end

    Doocr.levelstarttic = Doocr.gametic # for time calculation

    Doocr.wipegamestate = Doocr::Gamestate::Needwipe if Doocr.wipegamestate == Doocr::Gamestate::Level # force a wipe

    Doocr.gamestate = Doocr::Gamestate::Level

    CDoom::MAXPLAYERS.times do |i|
      if Doocr.playeringame[i] != 0 && @@players[i].playerstate == Doocr::Playerstate::PST_DEAD
        (@@players.to_unsafe + i).value.playerstate = Doocr::Playerstate::PST_REBORN
      end
      CDoom.doom_memset(@@players[i].frags, 0, sizeof(typeof(@@players[i].frags)))
    end

    CDoom.p_setup_level(Doocr.gameepisode, Doocr.gamemap, 0, Doocr.gameskill)
    Doocr.displayplayer = Doocr.consoleplayer # view the guy you are playing
    Doocr.starttime = CDoom.i_get_time
    Doocr.gameaction = Doocr::Gameaction::Nothing
    CDoom.z_check_heap

    # clear cmd building stuff
    Doocr.gamekeydown.fill(0)
    Doocr.joyxmove = 0
    Doocr.joyymove = 0
    @@mousex = 0
    @@mousey = 0
    Doocr.sendpause = 0
    Doocr.sendsave = 0
    Doocr.paused = 0
    Doocr.mousebuttons.fill(0)
    Doocr.joybuttons.fill(0)
  end

  @@mouse_scale_remx = 0
  @@mouse_scale_remy = 0

  def self.g_responder(ev : Doocr::Event) : LibC::Int
    # allow spy mode changes even during the demo
     if Doocr.gamestate == Doocr::Gamestate::Level && ev.type == Doocr::Evtype::Keydown &&
       ev.data1 == Doocr::KEY_F12 && (Doocr.singledemo != 0 || Doocr.deathmatch == 0)
      # spy mode
      loop do
        Doocr.displayplayer += 1
        Doocr.displayplayer = 0 if Doocr.displayplayer == CDoom::MAXPLAYERS

        break unless Doocr.playeringame[Doocr.displayplayer] == 0 && Doocr.displayplayer != Doocr.consoleplayer
      end
      return 1
    end

    # any other key pops up menu if in demos
    if Doocr.gameaction == Doocr::Gameaction::Nothing && Doocr.singledemo == 0 &&
       (Doocr.demoplayback != 0 || Doocr.gamestate == Doocr::Gamestate::Demoscreen)
      if ev.type == Doocr::Evtype::Keydown ||
        (ev.type == Doocr::Evtype::Mouse && ev.data1 != 0) ||
        (ev.type == Doocr::Evtype::Joystick && ev.data1 != 0)
        CDoom.m_start_control_panel
        return 1
      end
      return 0
    end

    if Doocr.gamestate == Doocr::Gamestate::Level
      {% if false %}
        if Doocr.devparm != 0 && ev.type == Doocr::Evtype::Keydown && ev.data1 == ';'.ord
          CDoom.g_deathmatch_spawn_player(0)
          return 1
        end
      {% end %}
      return 1 if Doocr.hu_responder(ev) != 0 # chat ate the event
      return 1 if Doocr.st_responder(ev) != 0 # status window ate it
      return 1 if Doocr.am_responder(ev) != 0 # automap ate it
    end

    if Doocr.gamestate == Doocr::Gamestate::Finale
      return 1 if Doocr.f_responder(ev) != 0 # finale ate the event
    end

    case ev.type
    when Doocr::Evtype::Keydown
      if ev.data1 == Doocr::KEY_PAUSE
        Doocr.sendpause = 1
        return 1
      end
      Doocr.gamekeydown[ev.data1] = 1 if ev.data1 < Doocr::NUMKEYS
      return 1 # eat key down events
    when Doocr::Evtype::Keyup
      Doocr.gamekeydown[ev.data1] = 0 if ev.data1 < Doocr::NUMKEYS
      return 0 # always let key up events filter down
    when Doocr::Evtype::Mouse
      Doocr.mousebuttons[0] = ev.data1 & 1
      Doocr.mousebuttons[1] = ev.data1 & 2
      Doocr.mousebuttons[2] = ev.data1 & 4
      scaled_x = ev.data2 * (Doocr.mouse_sensitivity + 5) + @@mouse_scale_remx
      scaled_y = ev.data3 * (Doocr.mouse_sensitivity + 5) + @@mouse_scale_remy
      @@mousex = scaled_x // 10
      @@mousey = scaled_y // 10
      @@mouse_scale_remx = scaled_x % 10
      @@mouse_scale_remy = scaled_y % 10
      return 1 # eat events
    when Doocr::Evtype::Joystick
      Doocr.joybuttons[0] = ev.data1 & 1
      Doocr.joybuttons[1] = ev.data1 & 2
      Doocr.joybuttons[2] = ev.data1 & 4
      Doocr.joybuttons[3] = ev.data1 & 8
      Doocr.joyxmove = ev.data2
      Doocr.joyymove = ev.data3
      return 1 # eat events
    end

    return 0
  end

  @@turbomessage = uninitialized StaticArray(UInt8, 80)

  #
  # g_ticker
  # Make ticcmds for the players.
  def self.g_ticker
    # do player reborns if needed
    CDoom::MAXPLAYERS.times do |i|
      CDoom.g_do_reborn(i) if Doocr.playeringame[i] != 0 && @@players[i].playerstate == Doocr::Playerstate::PST_REBORN
    end

    # do things to change the game state
    while Doocr.gameaction != Doocr::Gameaction::Nothing
      case Doocr.gameaction
      when Doocr::Gameaction::Loadlevel
        CDoom.g_do_load_level
      when Doocr::Gameaction::Newgame
        CDoom.g_do_new_game
      when Doocr::Gameaction::Loadgame
        CDoom.g_do_load_game
      when Doocr::Gameaction::Savegame
        CDoom.g_do_save_game
      when Doocr::Gameaction::Playdemo
        CDoom.g_do_play_demo
      when Doocr::Gameaction::Completed
        CDoom.g_do_completed
      when Doocr::Gameaction::Victory
        CDoom.f_start_finale
      when Doocr::Gameaction::Worlddone
        CDoom.g_do_world_done
      when Doocr::Gameaction::Screenshot
        CDoom.m_screenshot
        Doocr.gameaction = Doocr::Gameaction::Nothing
      when Doocr::Gameaction::Nothing
      end
    end

    # get commands, check consistancy,
    # and build new consistancy check
    buf = (Doocr.gametic // Doocr.ticdup) % Doocr::BACKUPTICS

    CDoom::MAXPLAYERS.times do |i|
      if Doocr.playeringame[i] != 0
        cmd = (pointerof((@@players.to_unsafe + i).value.@cmd)) # THERE WAS A BETTER WAY TO DO THIS

        CDoom.doom_memcpy(cmd, (Doocr.netcmds.to_unsafe + i).value.to_unsafe + buf, sizeof(CDoom::Ticcmd))

        CDoom.g_read_demo_ticcmd(cmd) if Doocr.demoplayback != 0
        CDoom.g_write_demo_ticcmd(cmd) if Doocr.demorecording != 0

        # check for turbo cheats
        if cmd.value.forwardmove > Doocr::TURBOTHRESHOLD &&
           (Doocr.gametic & 31) == 0 && (Doocr.gametic >> 5) & 3 == i
          CDoom.doom_strcpy(@@turbomessage, Doocr.player_names[i].to_unsafe)
          CDoom.doom_concat(@@turbomessage, " is turbo!")
          @@players[Doocr.consoleplayer].message = String.new(@@turbomessage.to_unsafe)
        end

        if Doocr.netgame != 0 && Doocr.netdemo == 0 && (Doocr.gametic % Doocr.ticdup) == 0
          if Doocr.gametic > Doocr::BACKUPTICS &&
             Doocr.consistancy[i][buf] != cmd.value.consistancy
            CDoom.i_error("Error: consistency failure (#{cmd.value.consistancy} should be #{Doocr.consistancy[i][buf]})")
          end
          if @@players[i].mo
            Doocr.consistancy[i][buf] = @@players[i].mo.not_nil!.x.to_i16!
          else
            Doocr.consistancy[i][buf] = Doocr.rndindex.to_i16!
          end
        end
      end
    end

    # check for special buttons
    CDoom::MAXPLAYERS.times do |i|
      if Doocr.playeringame[i] != 0
        if @@players[i].cmd.buttons & Doocr::Buttoncode::BT_SPECIAL.value != 0
          case Doocr::Buttoncode.new(@@players[i].cmd.buttons & Doocr::Buttoncode::BT_SPECIALMASK.value)
          when Doocr::Buttoncode::BTS_PAUSE
            Doocr.paused ^= 1
            if Doocr.paused != 0
              Doocr.s_pause_sound
            else
              Doocr.s_resume_sound
            end
          when Doocr::Buttoncode::BTS_SAVEGAME
            if Doocr.savedescription.empty? && Doocr.netgame != 0
              # Let single player game save empty descriptions
              Doocr.savedescription = "NET GAME"
            end
            Doocr.savegameslot =
              (@@players[i].cmd.buttons & Doocr::Buttoncode::BTS_SAVEMASK.value) >> Doocr::Buttoncode::BTS_SAVESHIFT.value
            Doocr.gameaction = Doocr::Gameaction::Savegame
          end
        end
      end
    end

    # do main actions
    case Doocr.gamestate
    when Doocr::Gamestate::Level
      CDoom.p_ticker
      CDoom.st_ticker
      Doocr.am_ticker
      CDoom.hu_ticker
    when Doocr::Gamestate::Intermission
      CDoom.wi_ticker
    when Doocr::Gamestate::Finale
      CDoom.f_ticker
    when Doocr::Gamestate::Demoscreen
      CDoom.d_page_ticker
    end
  end

  #
  # g_init_player
  # Called at the start.
  # Called by the game initialization functions.
  #
  def self.g_init_player(player : Int32)
    # set up the saved info
    p = @@players.to_unsafe + player

    # clear everything else to defaults
    CDoom.g_player_reborn(player)
  end

  #
  # g_player_finish_level
  # Can when a player completes a level.
  #
  def self.g_player_finish_level(player : Int32)
    p = @@players.to_unsafe + player

    CDoom.doom_memset(p.value.powers.to_unsafe, 0, sizeof(typeof(p.value.powers)))
    CDoom.doom_memset(p.value.cards.to_unsafe, 0, sizeof(typeof(p.value.cards)))
    p.value.mo.not_nil!.flags = p.value.mo.not_nil!.flags & ~Doocr::Mobjflag::MF_SHADOW.value # cancel invisibility
    p.value.extralight = 0                                                              # cancel gun flashes
    p.value.fixedcolormap = 0                                                           # cancel ir gogles
    p.value.damagecount = 0                                                             # no palette changes
    p.value.bonuscount = 0
  end

  #
  # g_player_reborn
  # Called after a player dies
  # almost everything is cleared and initialized
  #
  def self.g_player_reborn(player : Int32)
    frags = uninitialized StaticArray(Int32, CDoom::MAXPLAYERS)

    CDoom.doom_memcpy(frags.to_unsafe, @@players[player].frags.to_unsafe, sizeof(typeof(frags)))
    killcount = @@players[player].killcount
    itemcount = @@players[player].itemcount
    secretcount = @@players[player].secretcount

    p = @@players.to_unsafe + player
    CDoom.doom_memset(p, 0, sizeof(typeof(p.value)))

    CDoom.doom_memcpy(p.value.frags.to_unsafe, frags.to_unsafe, sizeof(typeof(@@players[player].frags)))
    (@@players.to_unsafe + player).value.killcount = killcount
    (@@players.to_unsafe + player).value.itemcount = itemcount
    (@@players.to_unsafe + player).value.secretcount = secretcount

    p.value.usedown = 0 # don't do anything immediately
    p.value.attackdown = 0
    p.value.playerstate = Doocr::Playerstate::PST_LIVE
    p.value.health = @@deh_initial_health
    p.value.readyweapon = Doocr::Weapontype::Pistol
    p.value.pendingweapon = Doocr::Weapontype::Pistol
    p.value.weaponowned[Doocr::Weapontype::Fist.value] = 1
    p.value.weaponowned[Doocr::Weapontype::Pistol.value] = 1
    p.value.ammo[Doocr::Ammotype::Clip.value] = @@deh_initial_bullets

    Doocr::Ammotype::NUMAMMO.value.times do |i|
      p.value.maxammo[i] = Doocr.maxammo[i]
    end
  end

  def self.g_check_spot(playernum : Int32, mthing : CDoom::Mapthing*) : LibC::Int
    if @@players[playernum].mo.nil?
      # first spawn of level, before corpses
      playernum.times do |i|
        return 0 if (@@players[i].mo.not_nil!.x == mthing.value.x.to_i32! << FRACBITS &&
              @@players[i].mo.not_nil!.y == mthing.value.y.to_i32! << FRACBITS)
      end
      return 1
    end

    x = mthing.value.x.to_i32! << FRACBITS
    y = mthing.value.y.to_i32! << FRACBITS

    return 0 if Doocr.p_check_position(@@players[playernum].mo.not_nil!, x, y) == 0

    # flush an old corpse if needed
    if Doocr.bodyqueslot >= Doocr::BODYQUESIZE
      p_remove_mobj(Doocr.bodyque[Doocr.bodyqueslot % Doocr::BODYQUESIZE].not_nil!)
    end
    Doocr.bodyque[Doocr.bodyqueslot % Doocr::BODYQUESIZE] = @@players[playernum].mo
    Doocr.bodyqueslot += 1

    # spawn a teleport fog
    ss = Doocr.r_point_in_subsector(x, y)
    an = (ANG45 &* (mthing.value.angle.tdiv(45))) >> Doocr::ANGLETOFINESHIFT

    mo = Doocr.p_spawn_mobj(x + 20 * @@finecosine[an], y + 20 * @@finesine[an],
      ss.sector.not_nil!.floorheight, Doocr::Mobjtype::MT_TFOG)

    Doocr.s_start_sound(mo, Doocr::Sfxenum::SFX_telept) if @@players[Doocr.consoleplayer].viewz != 1 # don't start sound on first frame

    return 1
  end

  def self.g_deathmatch_spawn_player(playernum : Int32)
    selections = Doocr.deathmatch_p
    if selections < 4
      CDoom.i_error("Error: Only #{selections} deathmatch spots, 4 required")
    end

    selections.times do |j|
      i = CDoom.p_random % selections
      if CDoom.g_check_spot(playernum, Doocr.deathmatchstarts.to_unsafe + i) != 0
        (Doocr.deathmatchstarts.to_unsafe + i).value.type = playernum + 1
        CDoom.p_spawn_player(Doocr.deathmatchstarts.to_unsafe + i)
        return
      end
    end

    # no good spot, so the player will probably get stuck
    CDoom.p_spawn_player(Doocr.playerstarts.to_unsafe + playernum)
  end

  def self.g_despawn_player(playernum : Int32)
    pmo = @@players[playernum].mo

    x = pmo.not_nil!.x.to_i32!
    y = pmo.not_nil!.y.to_i32!

    # spawn a teleport fog
    ss = Doocr.r_point_in_subsector(x, y)
    an = (ANG45 &* (pmo.not_nil!.angle.tdiv(45))) >> Doocr::ANGLETOFINESHIFT

    mo = Doocr.p_spawn_mobj(x + 20 * @@finecosine[an], y + 20 * @@finesine[an],
      ss.sector.not_nil!.floorheight, Doocr::Mobjtype::MT_TFOG)

    Doocr.s_start_sound(mo, Doocr::Sfxenum::SFX_telept) if @@players[Doocr.consoleplayer].viewz != 1 # don't start sound on first frame

    # Despawn player mobj
    Doocr.p_remove_mobj(pmo.not_nil!)
    @@players[playernum].mo = nil
  end

  #
  # g_do_reborn
  #
  def self.g_do_reborn(playernum : Int32)
    if Doocr.netgame == 0
      # reload the level from scatch
      Doocr.gameaction = Doocr::Gameaction::Loadlevel
    else
      # respawn at the start

      # first dissasociate the corpse
      @@players[playernum].mo.not_nil!.player = nil

      # spawn at random spot if in death match
      if Doocr.deathmatch != 0
        CDoom.g_deathmatch_spawn_player(playernum)
        return
      end

      if CDoom.g_check_spot(playernum, Doocr.playerstarts.to_unsafe + playernum) != 0
        CDoom.p_spawn_player(Doocr.playerstarts.to_unsafe + playernum)
        return
      end

      # try to spawn at one of the other players spots
      CDoom::MAXPLAYERS.times do |i|
        if CDoom.g_check_spot(playernum, Doocr.playerstarts.to_unsafe + i) != 0
          (Doocr.playerstarts.to_unsafe + i).value.type = playernum + 1 # fake as other player
          CDoom.p_spawn_player(Doocr.playerstarts.to_unsafe + i)        # restore
          return
        end
        # he's going to be inside something. Too bad.
      end
      CDoom.p_spawn_player(Doocr.playerstarts.to_unsafe + playernum)
    end
  end

  def self.g_screenshot
    Doocr.gameaction = Doocr::Gameaction::Screenshot
  end

  def self.g_exit_level
    Doocr.secretexit = 0
    Doocr.gameaction = Doocr::Gameaction::Completed
  end

  # Here's for the german edition. Literally 1984
  def self.g_secret_exit_level
    # IF NO WOLF3D LEVELS, NO SECRET EXIT!
    if Doocr.gamemode == Doocr::GameMode::Commercial &&
       CDoom.w_check_num_for_name("map31") < 0
      Doocr.secretexit = 0
    else
      Doocr.secretexit = 1
    end
    Doocr.gameaction = Doocr::Gameaction::Completed
  end

  def self.g_do_completed
    Doocr.gameaction = Doocr::Gameaction::Nothing

    CDoom::MAXPLAYERS.times do |i|
      CDoom.g_player_finish_level(i) if Doocr.playeringame[i] != 0 # take away cards and stuff
    end

    Doocr.am_stop if Doocr.automapactive != 0

    if Doocr.gamemode != Doocr::GameMode::Commercial
      case Doocr.gamemap
      when 8
        # victory
        Doocr.gameaction = Doocr::Gameaction::Victory
        return
      when 9
        # exit secret level
        CDoom::MAXPLAYERS.times do |i|
          (@@players.to_unsafe + i).value.didsecret = 1
        end
      end
    end

    @@wminfo.didsecret = (@@players.to_unsafe + Doocr.consoleplayer).value.didsecret
    @@wminfo.epsd = Doocr.gameepisode - 1
    @@wminfo.last = Doocr.gamemap - 1

    # wminfo.next is 0 biased, unlike gamemap
    if Doocr.gamemode == Doocr::GameMode::Commercial
      if Doocr.secretexit != 0
        case Doocr.gamemap
        when 15
          @@wminfo.next = 30
        when 31
          @@wminfo.next = 31
        end
      else
        case Doocr.gamemap
        when 31, 32
          @@wminfo.next = 15
        else @@wminfo.next = Doocr.gamemap
        end
      end
    else
      if Doocr.secretexit != 0
        @@wminfo.next = 8 # go to secret level
      elsif Doocr.gamemap == 9
        # returning from secret level
        case Doocr.gameepisode
        when 1
          @@wminfo.next = 3
        when 2
          @@wminfo.next = 5
        when 3
          @@wminfo.next = 6
        when 4
          @@wminfo.next = 2
        end
      else
        @@wminfo.next = Doocr.gamemap # go to next level
      end
    end

    @@wminfo.maxkills = Doocr.totalkills
    @@wminfo.maxitems = Doocr.totalitems
    @@wminfo.maxsecret = Doocr.totalsecret
    @@wminfo.maxfrags = 0
    if Doocr.gamemode == Doocr::GameMode::Commercial
      @@wminfo.partime = 35 * Doocr.cpars[Doocr.gamemap - 1]
    else
      @@wminfo.partime = 35 * Doocr.pars[Doocr.gameepisode - 1][Doocr.gamemap - 1]
    end
    @@wminfo.pnum = Doocr.consoleplayer

    CDoom::MAXPLAYERS.times do |i|
      @@wminfo.plyr[i].in = Doocr.playeringame[i]
      @@wminfo.plyr[i].skills = @@players[i].killcount
      @@wminfo.plyr[i].sitems = @@players[i].itemcount
      @@wminfo.plyr[i].ssecret = @@players[i].secretcount
      @@wminfo.plyr[i].stime = Doocr.leveltime
      4.times { |j| @@wminfo.plyr[i].frags[j] = @@players[i].frags[j] }
    end

    Doocr.gamestate = Doocr::Gamestate::Intermission
    Doocr.viewactive = 0
    Doocr.automapactive = 0

    Doocr.wi_start(@@wminfo)
  end

  #
  # g_world_done
  #
  def self.g_world_done
    Doocr.gameaction = Doocr::Gameaction::Worlddone

    (@@players.to_unsafe + Doocr.consoleplayer).value.didsecret = 1 if Doocr.secretexit != 0

    if Doocr.gamemode == Doocr::GameMode::Commercial
      case Doocr.gamemap
      when 15, 31
        CDoom.f_start_finale if Doocr.secretexit == 0
      when 6, 11, 20, 30
        CDoom.f_start_finale
      end
    end
  end

  #
  # g_do_world_done
  #
  def self.g_do_world_done
    Doocr.gamestate = Doocr::Gamestate::Level
    Doocr.gamemap = @@wminfo.next + 1
    CDoom.g_do_load_level
    Doocr.gameaction = Doocr::Gameaction::Nothing
    Doocr.viewactive = 1
  end

  #
  # g_load_game
  # Can be called by the startup code or the menu task.
  #
  def self.g_load_game(name : UInt8*)
    Doocr.savename = String.new(name)
    Doocr.gameaction = Doocr::Gameaction::Loadgame
  end

  @@saveleveltime = 0

  def self.g_do_load_game
    Doocr.gameaction = Doocr::Gameaction::Nothing

    response = Channel({Bytes, Bool}).new
    @@io_jobs.send({Doocr.savename, "rb", nil, response})
    data, ok = response.receive
    return unless ok

    IO::Memory.new(data).tap do |file|
      file.pos += Doocr::SAVESTRINGSIZE
      # skip the description field
      vcheck = "version #{SAVEVERSION}".ljust(Doocr::VERSIONSIZE, '\0')
      return if CDoom.doom_strcmp(file.read_string(Doocr::VERSIONSIZE).to_unsafe, vcheck.to_unsafe) != 0 # bad version

      Doocr.gameskill = Doocr::Skill.new(file.read_bytes(UInt8))
      Doocr.gameepisode = file.read_bytes(UInt8)
      Doocr.gamemap = file.read_bytes(UInt8)
      CDoom::MAXPLAYERS.times do |i|
        Doocr.playeringame[i] = file.read_bytes(UInt8)
      end

      # load a base level
      CDoom.g_init_new(Doocr.gameskill, Doocr.gameepisode, Doocr.gamemap)

      # get the times
      a = file.read_bytes(UInt8).to_u32
      b = file.read_bytes(UInt8).to_u32
      c = file.read_bytes(UInt8).to_u32
      Doocr.leveltime = ((a << 16) + (b << 8) + c).to_i32

      # dearchive all the modifications
      p_unarchive_players(file)
      p_unarchive_world(file)
      p_unarchive_thinkers(file)
      p_unarchive_specials(file)

      CDoom.i_error("Error: Bad savegame") if file.read_bytes(UInt8) != 0x1d
    end

    CDoom.r_execute_set_view_size if Doocr.setsizeneeded != 0

    # draw the pattern into the back screen
    CDoom.r_fill_back_screen
  end

  #
  # g_save_game
  # Called by the menu task.
  # Description is a 24 byte text string
  #
  def self.g_save_game(slot : Int32, description : UInt8*)
    Doocr.savegameslot = slot
    Doocr.savedescription = String.new(description)
    Doocr.sendsave = 1
  end

  def self.g_do_save_game
    name = "#{@@deh_savegamename}#{Doocr.savegameslot}.dsg"
    description = Doocr.savedescription.to_slice
    buf = IO::Memory.new
    buf.write_string(description[0...Doocr::SAVESTRINGSIZE])

    name2 = "version #{SAVEVERSION}".ljust(Doocr::VERSIONSIZE, '\0')
    buf.write_string(name2.to_slice)

    buf.write_byte(Doocr.gameskill.value.to_u8!)
    buf.write_byte(Doocr.gameepisode.to_u8!)
    buf.write_byte(Doocr.gamemap.to_u8!)

    CDoom::MAXPLAYERS.times do |i|
      buf.write_byte(Doocr.playeringame[i].to_u8!)
    end
    buf.write_byte((Doocr.leveltime >> 16).to_u8!)
    buf.write_byte((Doocr.leveltime >> 8).to_u8!)
    buf.write_byte((Doocr.leveltime).to_u8!)

    p_archive_players(buf)
    p_archive_world(buf)
    p_archive_thinkers(buf)
    p_archive_specials(buf)

    buf.write_byte(0x1d)

    response = Channel({Bytes, Bool}).new
    @@io_jobs.send({name, "wb", buf.to_slice, response})
    response.receive

    Doocr.gameaction = Doocr::Gameaction::Nothing
    Doocr.savedescription = ""

    (@@players.to_unsafe + Doocr.consoleplayer).value.message = @@deh_ggsaved

    # draw the pattern into the back screen
    CDoom.r_fill_back_screen
  end

  #
  # g_init_new
  # Can be called by the startup code or the menu task,
  # consoleplayer, displayplayer, playeringame[] should be set.
  #
  def self.g_defered_init_new(skill : Doocr::Skill, episode : Int32, map : Int32)
    Doocr.d_skill = skill
    Doocr.d_episode = episode
    Doocr.d_map = map
    Doocr.gameaction = Doocr::Gameaction::Newgame
  end

  def self.g_do_new_game
    Doocr.demoplayback = 0
    Doocr.netdemo = 0
    Doocr.netgame = 0
    Doocr.deathmatch = 0
    Doocr.playeringame[1] = 0
    Doocr.playeringame[2] = 0
    Doocr.playeringame[3] = 0
    Doocr.respawnparm = 0
    Doocr.fastparm = 0
    Doocr.nomonsters = 0
    Doocr.consoleplayer = 0
    CDoom.g_init_new(Doocr.d_skill, Doocr.d_episode, Doocr.d_map)
    Doocr.gameaction = Doocr::Gameaction::Nothing
  end

  def self.g_init_new(skill : Doocr::Skill, episode : Int32, map : Int32)
    if Doocr.paused != 0
      Doocr.paused = 0
      Doocr.s_resume_sound
    end

    skill = Doocr::Skill::Nightmare if skill > Doocr::Skill::Nightmare

    # This was quite messy with SPECIAL and commented parts.
    # Supposedly hacks to make the latest edition work.
    # It might not work properly.
    episode = 1 if episode < 1

    if Doocr.gamemode == Doocr::GameMode::Retail
      episode = 4 if episode > 4
    elsif Doocr.gamemode == Doocr::GameMode::Shareware
      episode = 1 if episode > 1 # only start episode 1 on shareware
    else
      episode = 3 if episode > 3
    end

    map = 1 if map < 1

    map = 9 if map > 9 && Doocr.gamemode != Doocr::GameMode::Commercial

    CDoom.m_clear_random

    if skill == Doocr::Skill::Nightmare || Doocr.respawnparm != 0
      Doocr.respawnmonsters = 1
    else
      Doocr.respawnmonsters = 0
    end

    if Doocr.fastparm != 0 || (skill == Doocr::Skill::Nightmare && Doocr.gameskill != Doocr::Skill::Nightmare)
      i = Doocr::Statenum::S_SARG_RUN1.value
      while i <= Doocr::Statenum::S_SARG_PAIN2.value
        (@@states.to_unsafe + i).value.tics = @@states[i].tics >> 1
        i += 1
      end
      Doocr.mobjinfo[Doocr::Mobjtype::MT_BRUISERSHOT.value].speed = 20 * FRACUNIT
      Doocr.mobjinfo[Doocr::Mobjtype::MT_HEADSHOT.value].speed = 20 * FRACUNIT
      Doocr.mobjinfo[Doocr::Mobjtype::MT_TROOPSHOT.value].speed = 20 * FRACUNIT
    elsif skill != Doocr::Skill::Nightmare && Doocr.gameskill == Doocr::Skill::Nightmare
      i = Doocr::Statenum::S_SARG_RUN1.value
      while i <= Doocr::Statenum::S_SARG_PAIN2.value
        (@@states.to_unsafe + i).value.tics = @@states[i].tics << 1
        i += 1
      end
      Doocr.mobjinfo[Doocr::Mobjtype::MT_BRUISERSHOT.value].speed = 15 * FRACUNIT
      Doocr.mobjinfo[Doocr::Mobjtype::MT_HEADSHOT.value].speed = 10 * FRACUNIT
      Doocr.mobjinfo[Doocr::Mobjtype::MT_TROOPSHOT.value].speed = 10 * FRACUNIT
    end

    # force players to be initialized upon first level load
    CDoom::MAXPLAYERS.times { |i| (@@players.to_unsafe + i).value.playerstate = Doocr::Playerstate::PST_REBORN }

    Doocr.usergame = 1 # will be set false if a demo
    Doocr.paused = 0
    Doocr.demoplayback = 0
    Doocr.automapactive = 0
    Doocr.viewactive = 1
    Doocr.gameepisode = episode
    Doocr.gamemap = map
    Doocr.gameskill = skill

    # set the sky map for the episode
    if Doocr.gamemode == Doocr::GameMode::Commercial
      Doocr.skytexture = CDoom.r_texture_num_for_name("SKY3")
      if Doocr.gamemap < 12
        Doocr.skytexture = CDoom.r_texture_num_for_name("SKY1")
      elsif Doocr.gamemap < 21
        Doocr.skytexture = CDoom.r_texture_num_for_name("SKY2")
      end
    else
      case episode
      when 1
        Doocr.skytexture = CDoom.r_texture_num_for_name("SKY1")
      when 2
        Doocr.skytexture = CDoom.r_texture_num_for_name("SKY2")
      when 3
        Doocr.skytexture = CDoom.r_texture_num_for_name("SKY3")
      when 4 # Special Edition sky
        Doocr.skytexture = CDoom.r_texture_num_for_name("SKY4")
      end
    end

    CDoom.g_do_load_level
  end

  #
  # DEMO RECORDING
  #
  def self.g_read_demo_ticcmd(cmd : CDoom::Ticcmd*)
    if Doocr.demo_p.value == Doocr::DEMOMARKER
      # end of demo data stream
      CDoom.g_check_demo_status
      return
    end
    cmd.value.forwardmove = Doocr.demo_p.value.to_i8!
    Doocr.demo_p += 1
    cmd.value.sidemove = Doocr.demo_p.value.to_i8!
    Doocr.demo_p += 1
    cmd.value.angleturn = (Doocr.demo_p.value.to_u8!).to_i32 << 8
    Doocr.demo_p += 1
    cmd.value.buttons = Doocr.demo_p.value.to_u8!
    Doocr.demo_p += 1
  end

  @@prevstate : Doocr::Playerstate = Doocr::Playerstate::PST_LIVE

  def self.g_write_demo_ticcmd(cmd : CDoom::Ticcmd*)
    pstate = @@players[Doocr.consoleplayer].playerstate
    CDoom.g_check_demo_status if Doocr.gamekeydown['q'.ord] != 0 # ||                                                         # press q to end demo recording
    # (@@prevstate == Doocr::Playerstate::PST_DEAD && pstate == Doocr::Playerstate::PST_LIVE) || # or if player is respawning
    # Doocr.gamestate != Doocr::Gamestate::Level                                                 # or if we are no longer on a level
    @@prevstate = pstate
    Doocr.demo_p.value = cmd.value.forwardmove.to_u8!
    Doocr.demo_p += 1
    Doocr.demo_p.value = cmd.value.sidemove.to_u8!
    Doocr.demo_p += 1
    Doocr.demo_p.value = ((cmd.value.angleturn.to_i32 + 128) >> 8).to_u8!
    Doocr.demo_p += 1
    Doocr.demo_p.value = cmd.value.buttons.to_u8!
    Doocr.demo_p += 1
    Doocr.demo_p -= 4
    if Doocr.demo_p > Doocr.demoend - 16
      # no more space
      CDoom.g_check_demo_status
      return
    end

    CDoom.g_read_demo_ticcmd(cmd) # make SURE it is exactly the same
  end

  #
  # g_record_demo
  #
  def self.g_record_demo(name : UInt8*)
    Doocr.usergame = 0
    Doocr.demoname = String.new(name) + ".lmp"
    maxsize = 0x20000
    i = ARGV.index("-maxdemo")
    maxsize = ARGV[i + 1].to_i * 1024 if i && i < ARGV.size - 1
    Doocr.demobuffer = CDoom.z_malloc(maxsize, Doocr::PU_STATIC, Pointer(Void).null).as(UInt8*)
    Doocr.demoend = Doocr.demobuffer + maxsize

    Doocr.demorecording = 1
  end

  def self.g_begin_recording
    @@prevstate = Doocr::Playerstate::PST_LIVE

    Doocr.demo_p = Doocr.demobuffer

    Doocr.demo_p.value = DEMOVERSION.to_u8
    Doocr.demo_p += 1
    Doocr.demo_p.value = Doocr.gameskill.value.to_u8
    Doocr.demo_p += 1
    Doocr.demo_p.value = Doocr.gameepisode.to_u8
    Doocr.demo_p += 1
    Doocr.demo_p.value = Doocr.gamemap.to_u8
    Doocr.demo_p += 1
    Doocr.demo_p.value = Doocr.deathmatch.to_u8
    Doocr.demo_p += 1
    Doocr.demo_p.value = Doocr.respawnparm.to_u8
    Doocr.demo_p += 1
    Doocr.demo_p.value = Doocr.fastparm.to_u8
    Doocr.demo_p += 1
    Doocr.demo_p.value = Doocr.nomonsters.to_u8
    Doocr.demo_p += 1
    Doocr.demo_p.value = Doocr.consoleplayer.to_u8
    Doocr.demo_p += 1

    CDoom::MAXPLAYERS.times do |i|
      Doocr.demo_p.value = Doocr.playeringame[i].to_u8
      Doocr.demo_p += 1
    end
  end

  #
  # g_play_demo
  #

  def self.g_defered_play_demo(name : UInt8*)
    Doocr.defdemoname = String.new(name)
    Doocr.gameaction = Doocr::Gameaction::Playdemo
  end

  def self.g_do_play_demo
    Doocr.gameaction = Doocr::Gameaction::Nothing
    Doocr.demobuffer = CDoom.w_cache_lump_name(Doocr.defdemoname.to_unsafe, Doocr::PU_STATIC).as(UInt8*)
    Doocr.demo_p = Doocr.demobuffer
    demo_version = Doocr.demo_p.value
    Doocr.demo_p += 1
    if demo_version != DEMOVERSION && demo_version != 109 # Demos seem to run fine with version 109
      puts "Demo is from a different game version! Demo Verson = #{demo_version}, this version = #{DEMOVERSION}"
      Doocr.gameaction = Doocr::Gameaction::Nothing
      return
    end

    skill = Doocr::Skill.new(Doocr.demo_p.value)
    Doocr.demo_p += 1
    episode = Doocr.demo_p.value
    Doocr.demo_p += 1
    map = Doocr.demo_p.value
    Doocr.demo_p += 1
    Doocr.deathmatch = Doocr.demo_p.value
    Doocr.demo_p += 1
    Doocr.respawnparm = Doocr.demo_p.value
    Doocr.demo_p += 1
    Doocr.fastparm = Doocr.demo_p.value
    Doocr.demo_p += 1
    Doocr.nomonsters = Doocr.demo_p.value
    Doocr.demo_p += 1
    Doocr.consoleplayer = Doocr.demo_p.value
    Doocr.demo_p += 1

    CDoom::MAXPLAYERS.times do |i|
      Doocr.playeringame[i] = Doocr.demo_p.value
      Doocr.demo_p += 1
    end
    if Doocr.playeringame[1] != 0
      Doocr.netgame = 1
      Doocr.netdemo = 1
    end

    # don't spend a lot of time in loadlevel
    Doocr.precache = 0
    CDoom.g_init_new(skill, episode, map)
    Doocr.precache = 1

    Doocr.usergame = 0
    Doocr.demoplayback = 1
  end

  #
  # g_time_demo
  #
  def self.g_time_demo(name : UInt8*)
    Doocr.nodrawers = ARGV.includes?("-nodraw") ? 1 : 0
    Doocr.noblit = ARGV.includes?("-noblit") ? 1 : 0
    Doocr.timingdemo = 1
    Doocr.singletics = 1

    Doocr.defdemoname = String.new(name)
    Doocr.gameaction = Doocr::Gameaction::Playdemo
  end

  # ===================
  # =
  # = g_check_demo_status
  # =
  # = Called after a death or level completion to allow demos to be cleaned up
  # = Returns true if a new demo loop action will take place
  # ===================
  def self.g_check_demo_status : LibC::Int
    if Doocr.timingdemo != 0
      endtime = CDoom.i_get_time

      puts " Timed #{Doocr.gametic} gametics in #{endtime - Doocr.starttime} realtics"
      i_quit
    end

    if Doocr.demoplayback != 0
      CDoom.i_quit if Doocr.singledemo != 0

      z_change_tag(Doocr.demobuffer, Doocr::PU_CACHE)
      Doocr.demoplayback = 0
      Doocr.netdemo = 0
      Doocr.netgame = 0
      Doocr.deathmatch = 0
      Doocr.playeringame[1] = 0
      Doocr.playeringame[2] = 0
      Doocr.playeringame[3] = 0
      Doocr.respawnparm = 0
      Doocr.fastparm = 0
      Doocr.nomonsters = 0
      Doocr.consoleplayer = 0
      CDoom.d_advance_demo
      return 1
    end

    if Doocr.demorecording != 0
      Doocr.demo_p.value = Doocr::DEMOMARKER.to_u8
      Doocr.demo_p += 1
      CDoom.m_write_file(Doocr.demoname.to_unsafe, Doocr.demobuffer, (Doocr.demo_p - Doocr.demobuffer).to_i32!)
      CDoom.z_free(Doocr.demobuffer)
      Doocr.demorecording = 0

      puts " Demo #{Doocr.demoname} recorded"
      i_quit
    end

    return 0
  end
end
