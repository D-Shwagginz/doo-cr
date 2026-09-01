module Doocr
  @@oldentertics : Int32 = 0

  #
  # try_run_tics
  #
  def self.try_run_tics
    # get real tics
    entertic = CDoom.i_get_time // CDoom.ticdup
    realtics = entertic - @@oldentertics
    @@oldentertics = entertic

    # get available tics
    CDoom.net_update

    lowtic = Int32::MAX
    numplaying = 0
    CDoom.doomcom.value.numnodes.times do |i|
      if CDoom.nodeingame[i] != 0
        numplaying += 1
        lowtic = CDoom.nettics[i] if CDoom.nettics[i] < lowtic
      end
    end
    availabletics = lowtic - CDoom.gametic // CDoom.ticdup

    counts = availabletics
    # decide how many tics to run
    if realtics < availabletics - 1
      counts = realtics + 1
    elsif realtics < availabletics
      counts = realtics
    end

    counts = 1 if counts < 1

    CDoom.frameon += 1

    if !CDoom.debugfile.null?
      CDoom.doom_fprint(CDoom.debugfile, "=======real: ")
      CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(realtics, 10))
      CDoom.doom_fprint(CDoom.debugfile, "  avail: ")
      CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(availabletics, 10))
      CDoom.doom_fprint(CDoom.debugfile, "  game: ")
      CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(counts, 10))
      CDoom.doom_fprint(CDoom.debugfile, "\n")
    end

    if CDoom.demoplayback == 0
      i = 0
      while i < CDoom::MAXPLAYERS
        break if CDoom.playeringame[i] != 0
        i += 1
      end
      if CDoom.consoleplayer == i
        # the key player does not adapt
      else
        if CDoom.nettics[0] <= CDoom.nettics[CDoom.nodeforplayer[i]]
          CDoom.gametime -= 1
        end
        CDoom.frameskip[CDoom.frameon & 3] = (CDoom.oldnettics > CDoom.nettics[CDoom.nodeforplayer[i]]).to_unsafe
        CDoom.oldnettics = CDoom.nettics[0]
        if CDoom.frameskip[0] != 0 && CDoom.frameskip[1] != 0 && CDoom.frameskip[2] != 0 && CDoom.frameskip[3] != 0
          CDoom.skiptics = 1
        end
      end
    end

    # wait for new tics if needed
    while lowtic < CDoom.gametic // CDoom.ticdup + counts
      i_poll_mouse
      CDoom.net_update
      lowtic = Int32::MAX

      CDoom.doomcom.value.numnodes.times do |i|
        lowtic = CDoom.nettics[i] if CDoom.nodeingame[i] != 0 && CDoom.nettics[i] < lowtic
      end

      CDoom.i_error("Error: try_run_tics: lowtic < CDoom.gametic") if lowtic < CDoom.gametic // CDoom.ticdup

      # don't stay in here forever -- give the menu a chance to work
      if CDoom.i_get_time // CDoom.ticdup - entertic >= 20
        CDoom.m_ticker
        return
      end
    end

    # run the count * ticdup dics
    while counts != 0
      CDoom.ticdup.times do |i|
        CDoom.i_error("Error: gametic>lowtic") if CDoom.gametic // CDoom.ticdup > lowtic
        CDoom.d_do_advance_demo if CDoom.advancedemo != 0
        CDoom.m_ticker
        CDoom.g_ticker
        CDoom.gametic &+= 1

        # modify command for duplicated tics
        if i != CDoom.ticdup - 1
          buf = (CDoom.gametic // CDoom.ticdup) % CDoom::BACKUPTICS
          CDoom::MAXPLAYERS.times do |j|
            cmd = (CDoom.netcmds.to_unsafe + j).value.to_unsafe + buf
            cmd.value.chatchar = 0
            cmd.value.buttons = 0 if cmd.value.buttons & CDoom::Buttoncode::BT_SPECIAL.value != 0
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
      CDoom.consistancy[CDoom.consoleplayer][CDoom.maketic % CDoom::BACKUPTICS]

    unless CDoom.menuactive != 0
      strafe = (CDoom.gamekeydown[CDoom.key_strafe] != 0 || CDoom.mousebuttons[CDoom.mousebstrafe] != 0 ||
                CDoom.joybuttons[CDoom.joybstrafe] != 0).to_unsafe

      running = CDoom.always_run != 0 ? (CDoom.gamekeydown[CDoom.key_speed] != 0 ? false : true) : (CDoom.gamekeydown[CDoom.key_speed] != 0 ? true : false)
      speed = (running || CDoom.joybuttons[CDoom.joybspeed] != 0).to_unsafe

      forward = 0
      side = 0

      # use two stage accelerative turning
      # on the keyboard and joystick
      if CDoom.joyxmove < 0 ||
         CDoom.joyxmove > 0 ||
         CDoom.gamekeydown[CDoom.key_right] != 0 ||
         CDoom.gamekeydown[CDoom.key_left] != 0
        CDoom.turnheld += CDoom.ticdup
      else
        CDoom.turnheld = 0
      end

      tspeed = speed
      tspeed = 2 if CDoom.turnheld < CDoom::SLOWTURNTICS # slow turn

      # let movement keys cancel each other out
      if strafe != 0
        side += CDoom.sidemove[speed] if CDoom.gamekeydown[CDoom.key_right] != 0
        side -= CDoom.sidemove[speed] if CDoom.gamekeydown[CDoom.key_left] != 0
        side += CDoom.sidemove[speed] if CDoom.joyxmove > 0
        side -= CDoom.sidemove[speed] if CDoom.joyxmove < 0
      else
        cmd.value.angleturn = cmd.value.angleturn - CDoom.angleturn[tspeed] if CDoom.gamekeydown[CDoom.key_right] != 0
        cmd.value.angleturn = cmd.value.angleturn + CDoom.angleturn[tspeed] if CDoom.gamekeydown[CDoom.key_left] != 0
        cmd.value.angleturn = cmd.value.angleturn - CDoom.angleturn[tspeed] if CDoom.joyxmove > 0
        cmd.value.angleturn = cmd.value.angleturn + CDoom.angleturn[tspeed] if CDoom.joyxmove < 0
      end

      forward += CDoom.forwardmove[speed] if CDoom.gamekeydown[CDoom.key_up] != 0
      forward -= CDoom.forwardmove[speed] if CDoom.gamekeydown[CDoom.key_down] != 0
      forward += CDoom.forwardmove[speed] if CDoom.joyymove < 0
      forward -= CDoom.forwardmove[speed] if CDoom.joyymove > 0

      side += CDoom.sidemove[speed] if CDoom.gamekeydown[CDoom.key_straferight] != 0
      side -= CDoom.sidemove[speed] if CDoom.gamekeydown[CDoom.key_strafeleft] != 0

      # buttons
      cmd.value.chatchar = CDoom.hu_dequeue_chat_char

      if CDoom.gamekeydown[CDoom.key_fire] != 0 || CDoom.mousebuttons[CDoom.mousebfire] != 0 ||
         CDoom.joybuttons[CDoom.joybfire] != 0
        cmd.value.buttons = cmd.value.buttons | CDoom::Buttoncode::BT_ATTACK.value
      end

      if CDoom.gamekeydown[CDoom.key_use] != 0 || CDoom.joybuttons[CDoom.joybuse] != 0
        cmd.value.buttons = cmd.value.buttons | CDoom::Buttoncode::BT_USE.value
        # clear double clicks if hit use button
        CDoom.dclicks = 0
      end

      # chainsaw overrides
      (CDoom::Weapontype::NUMWEAPONS.value - 1).times do |i|
        if CDoom.gamekeydown['1'.ord + i] != 0
          cmd.value.buttons = cmd.value.buttons | CDoom::Buttoncode::BT_CHANGE.value
          cmd.value.buttons = cmd.value.buttons | i << CDoom::Buttoncode::BT_WEAPONSHIFT.value
          break
        end
      end

      # mouse
      forward += CDoom.forwardmove[speed] if CDoom.mousebuttons[CDoom.mousebforward] != 0

      # forward double click
      if CDoom.mousebuttons[CDoom.mousebforward] != CDoom.dclickstate && CDoom.dclicktime > 1
        CDoom.dclickstate = CDoom.mousebuttons[CDoom.mousebforward]
        CDoom.dclicks += 1 if CDoom.dclickstate != 0
        if CDoom.dclicks == 2
          cmd.value.buttons = cmd.value.buttons | CDoom::Buttoncode::BT_USE.value
          CDoom.dclicks = 0
        else
          CDoom.dclicktime = 0
        end
      else
        CDoom.dclicktime += CDoom.ticdup
        if CDoom.dclicktime > 20
          CDoom.dclicks = 0
          CDoom.dclickstate = 0
        end
      end

      # strafe double click
      bstrafe =
        (CDoom.mousebuttons[CDoom.mousebstrafe] != 0 ||
          CDoom.joybuttons[CDoom.joybstrafe] != 0).to_unsafe
      if bstrafe != CDoom.dclickstate2 && CDoom.dclicktime2 > 1
        CDoom.dclickstate2 = bstrafe
        CDoom.dclicks2 += 1 if CDoom.dclickstate2 != 0
        if CDoom.dclicks2 == 2
          cmd.value.buttons = cmd.value.buttons | CDoom::Buttoncode::BT_USE.value
          CDoom.dclicks2 = 0
        else
          CDoom.dclicktime2 = 0
        end
      else
        CDoom.dclicktime2 += CDoom.ticdup
        if CDoom.dclicktime2 > 20
          CDoom.dclicks2 = 0
          CDoom.dclickstate2 = 0
        end
      end

      forward += @@mousey if CDoom.mousemove != 0
      if strafe != 0
        side += @@mousex * 2
      else
        cmd.value.angleturn = cmd.value.angleturn &- @@mousex * 0x8
      end

      @@mousex = 0
      @@mousey = 0

      maxplmove = CDoom.forwardmove[1]

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
    if CDoom.sendpause != 0
      CDoom.sendpause = 0
      cmd.value.buttons = CDoom::Buttoncode::BT_SPECIAL.value | CDoom::Buttoncode::BTS_PAUSE.value
    end

    if CDoom.sendsave != 0
      CDoom.sendsave = 0
      cmd.value.buttons = CDoom::Buttoncode::BT_SPECIAL.value | CDoom::Buttoncode::BTS_SAVEGAME.value | (CDoom.savegameslot << CDoom::Buttoncode::BTS_SAVESHIFT.value)
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
    CDoom.skyflatnum = CDoom.r_flat_num_for_name(CDoom::SKYFLATNAME)

    # DOOM determines the sky texture to be used
    # depending on the current episode, and the game version.
    if CDoom.gamemode == CDoom::GameMode::Commercial ||
       CDoom.gamemission == CDoom::GameMission::PackTnt ||
       CDoom.gamemission == CDoom::GameMission::PackPlut
      CDoom.skytexture = CDoom.r_texture_num_for_name("SKY3")
      if CDoom.gamemap < 12
        CDoom.skytexture = CDoom.r_texture_num_for_name("SKY1")
      elsif CDoom.gamemap < 21
        CDoom.skytexture = CDoom.r_texture_num_for_name("SKY2")
      end
    end

    CDoom.levelstarttic = CDoom.gametic # for time calculation

    CDoom.wipegamestate = CDoom::Gamestate::Needwipe if CDoom.wipegamestate == CDoom::Gamestate::Level # force a wipe

    CDoom.gamestate = CDoom::Gamestate::Level

    CDoom::MAXPLAYERS.times do |i|
      if CDoom.playeringame[i] != 0 && CDoom.players[i].playerstate == CDoom::Playerstate::PST_DEAD
        (CDoom.players.to_unsafe + i).value.playerstate = CDoom::Playerstate::PST_REBORN
      end
      CDoom.doom_memset(CDoom.players[i].frags, 0, sizeof(typeof(CDoom.players[i].frags)))
    end

    CDoom.p_setup_level(CDoom.gameepisode, CDoom.gamemap, 0, CDoom.gameskill)
    CDoom.displayplayer = CDoom.consoleplayer # view the guy you are playing
    CDoom.starttime = CDoom.i_get_time
    CDoom.gameaction = CDoom::Gameaction::Nothing
    CDoom.z_check_heap

    # clear cmd building stuff
    CDoom.doom_memset(CDoom.gamekeydown, 0, sizeof(typeof(CDoom.gamekeydown)))
    CDoom.joyxmove = 0
    CDoom.joyymove = 0
    @@mousex = 0
    @@mousey = 0
    CDoom.sendpause = 0
    CDoom.sendsave = 0
    CDoom.paused = 0
    CDoom.doom_memset(CDoom.mousebuttons, 0, sizeof(typeof(CDoom.mousebuttons.value)) * 3)
    CDoom.doom_memset(CDoom.joybuttons, 0, sizeof(typeof(CDoom.joybuttons.value)) * 3)
  end

  @@mouse_scale_remx = 0
  @@mouse_scale_remy = 0

  def self.g_responder(ev : CDoom::Event*) : CDoom::DoomBool
    # allow spy mode changes even during the demo
    if CDoom.gamestate == CDoom::Gamestate::Level && ev.value.type == CDoom::Evtype::Keydown &&
       ev.value.data1 == CDoom::KEY_F12 && (CDoom.singledemo != 0 || CDoom.deathmatch == 0)
      # spy mode
      loop do
        CDoom.displayplayer += 1
        CDoom.displayplayer = 0 if CDoom.displayplayer == CDoom::MAXPLAYERS

        break unless CDoom.playeringame[CDoom.displayplayer] == 0 && CDoom.displayplayer != CDoom.consoleplayer
      end
      return 1
    end

    # any other key pops up menu if in demos
    if CDoom.gameaction == CDoom::Gameaction::Nothing && CDoom.singledemo == 0 &&
       (CDoom.demoplayback != 0 || CDoom.gamestate == CDoom::Gamestate::Demoscreen)
      if ev.value.type == CDoom::Evtype::Keydown ||
         (ev.value.type == CDoom::Evtype::Mouse && ev.value.data1 != 0) ||
         (ev.value.type == CDoom::Evtype::Joystick && ev.value.data1 != 0)
        CDoom.m_start_control_panel
        return 1
      end
      return 0
    end

    if CDoom.gamestate == CDoom::Gamestate::Level
      {% if false %}
        if CDoom.devparm != 0 && ev.value.type == CDoom::Evtype::Keydown && ev.value.data1 == ';'.ord
          CDoom.g_deathmatch_spawn_player(0)
          return 1
        end
      {% end %}
      return 1 if CDoom.hu_responder(ev) != 0 # chat ate the event
      return 1 if CDoom.st_responder(ev) != 0 # status window ate it
      return 1 if CDoom.am_responder(ev) != 0 # automap ate it
    end

    if CDoom.gamestate == CDoom::Gamestate::Finale
      return 1 if CDoom.f_responder(ev) != 0 # finale ate the event
    end

    case ev.value.type
    when CDoom::Evtype::Keydown
      if ev.value.data1 == CDoom::KEY_PAUSE
        CDoom.sendpause = 1
        return 1
      end
      CDoom.gamekeydown[ev.value.data1] = 1 if ev.value.data1 < CDoom::NUMKEYS
      return 1 # eat key down events
    when CDoom::Evtype::Keyup
      CDoom.gamekeydown[ev.value.data1] = 0 if ev.value.data1 < CDoom::NUMKEYS
      return 0 # always let key up events filter down
    when CDoom::Evtype::Mouse
      CDoom.mousebuttons[0] = ev.value.data1 & 1
      CDoom.mousebuttons[1] = ev.value.data1 & 2
      CDoom.mousebuttons[2] = ev.value.data1 & 4
      scaled_x = ev.value.data2 * (CDoom.mouse_sensitivity + 5) + @@mouse_scale_remx
      scaled_y = ev.value.data3 * (CDoom.mouse_sensitivity + 5) + @@mouse_scale_remy
      @@mousex = scaled_x // 10
      @@mousey = scaled_y // 10
      @@mouse_scale_remx = scaled_x % 10
      @@mouse_scale_remy = scaled_y % 10
      return 1 # eat events
    when CDoom::Evtype::Joystick
      CDoom.joybuttons[0] = ev.value.data1 & 1
      CDoom.joybuttons[1] = ev.value.data1 & 2
      CDoom.joybuttons[2] = ev.value.data1 & 4
      CDoom.joybuttons[3] = ev.value.data1 & 8
      CDoom.joyxmove = ev.value.data2
      CDoom.joyymove = ev.value.data3
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
      CDoom.g_do_reborn(i) if CDoom.playeringame[i] != 0 && CDoom.players[i].playerstate == CDoom::Playerstate::PST_REBORN
    end

    # do things to change the game state
    while CDoom.gameaction != CDoom::Gameaction::Nothing
      case CDoom.gameaction
      when CDoom::Gameaction::Loadlevel
        CDoom.g_do_load_level
      when CDoom::Gameaction::Newgame
        CDoom.g_do_new_game
      when CDoom::Gameaction::Loadgame
        CDoom.g_do_load_game
      when CDoom::Gameaction::Savegame
        CDoom.g_do_save_game
      when CDoom::Gameaction::Playdemo
        CDoom.g_do_play_demo
      when CDoom::Gameaction::Completed
        CDoom.g_do_completed
      when CDoom::Gameaction::Victory
        CDoom.f_start_finale
      when CDoom::Gameaction::Worlddone
        CDoom.g_do_world_done
      when CDoom::Gameaction::Screenshot
        CDoom.m_screenshot
        CDoom.gameaction = CDoom::Gameaction::Nothing
      when CDoom::Gameaction::Nothing
      end
    end

    # get commands, check consistancy,
    # and build new consistancy check
    buf = (CDoom.gametic // CDoom.ticdup) % CDoom::BACKUPTICS

    CDoom::MAXPLAYERS.times do |i|
      if CDoom.playeringame[i] != 0
        cmd = (pointerof((CDoom.players.to_unsafe + i).value.@cmd)) # THERE WAS A BETTER WAY TO DO THIS

        CDoom.doom_memcpy(cmd, (CDoom.netcmds.to_unsafe + i).value.to_unsafe + buf, sizeof(CDoom::Ticcmd))

        CDoom.g_read_demo_ticcmd(cmd) if CDoom.demoplayback != 0
        CDoom.g_write_demo_ticcmd(cmd) if CDoom.demorecording != 0

        # check for turbo cheats
        if cmd.value.forwardmove > CDoom::TURBOTHRESHOLD &&
           (CDoom.gametic & 31) == 0 && (CDoom.gametic >> 5) & 3 == i
          CDoom.doom_strcpy(@@turbomessage, CDoom.player_names[i])
          CDoom.doom_concat(@@turbomessage, " is turbo!")
          (CDoom.players.to_unsafe + CDoom.consoleplayer).value.message = @@turbomessage
        end

        if CDoom.netgame != 0 && CDoom.netdemo == 0 && (CDoom.gametic % CDoom.ticdup) == 0
          if CDoom.gametic > CDoom::BACKUPTICS &&
             CDoom.consistancy[i][buf] != cmd.value.consistancy
            CDoom.i_error("Error: consistency failure (#{cmd.value.consistancy} should be #{CDoom.consistancy[i][buf]})")
          end
          if !CDoom.players[i].mo.null?
            CDoom.consistancy[i][buf] = CDoom.players[i].mo.value.x.to_i16!
          else
            CDoom.consistancy[i][buf] = CDoom.rndindex.to_i16!
          end
        end
      end
    end

    # check for special buttons
    CDoom::MAXPLAYERS.times do |i|
      if CDoom.playeringame[i] != 0
        if CDoom.players[i].cmd.buttons & CDoom::Buttoncode::BT_SPECIAL.value != 0
          case CDoom::Buttoncode.new(CDoom.players[i].cmd.buttons & CDoom::Buttoncode::BT_SPECIALMASK.value)
          when CDoom::Buttoncode::BTS_PAUSE
            CDoom.paused ^= 1
            if CDoom.paused != 0
              CDoom.s_pause_sound
            else
              CDoom.s_resume_sound
            end
          when CDoom::Buttoncode::BTS_SAVEGAME
            if CDoom.savedescription[0] == '\0'.ord && CDoom.netgame != 0
              # Let single player game save empty descriptions
              CDoom.doom_strcpy(CDoom.savedescription, "NET GAME")
            end
            CDoom.savegameslot =
              (CDoom.players[i].cmd.buttons & CDoom::Buttoncode::BTS_SAVEMASK.value) >> CDoom::Buttoncode::BTS_SAVESHIFT.value
            CDoom.gameaction = CDoom::Gameaction::Savegame
          end
        end
      end
    end

    # do main actions
    case CDoom.gamestate
    when CDoom::Gamestate::Level
      CDoom.p_ticker
      CDoom.st_ticker
      CDoom.am_ticker
      CDoom.hu_ticker
    when CDoom::Gamestate::Intermission
      CDoom.wi_ticker
    when CDoom::Gamestate::Finale
      CDoom.f_ticker
    when CDoom::Gamestate::Demoscreen
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
    p = CDoom.players.to_unsafe + player

    # clear everything else to defaults
    CDoom.g_player_reborn(player)
  end

  #
  # g_player_finish_level
  # Can when a player completes a level.
  #
  def self.g_player_finish_level(player : Int32)
    p = CDoom.players.to_unsafe + player

    CDoom.doom_memset(p.value.powers.to_unsafe, 0, sizeof(typeof(p.value.powers)))
    CDoom.doom_memset(p.value.cards.to_unsafe, 0, sizeof(typeof(p.value.cards)))
    p.value.mo.value.flags = p.value.mo.value.flags & ~CDoom::Mobjflag::MF_SHADOW.value # cancel invisibility
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

    CDoom.doom_memcpy(frags.to_unsafe, CDoom.players[player].frags.to_unsafe, sizeof(typeof(frags)))
    killcount = CDoom.players[player].killcount
    itemcount = CDoom.players[player].itemcount
    secretcount = CDoom.players[player].secretcount

    p = CDoom.players.to_unsafe + player
    CDoom.doom_memset(p, 0, sizeof(typeof(p.value)))

    CDoom.doom_memcpy(p.value.frags.to_unsafe, frags.to_unsafe, sizeof(typeof(CDoom.players[player].frags)))
    (CDoom.players.to_unsafe + player).value.killcount = killcount
    (CDoom.players.to_unsafe + player).value.itemcount = itemcount
    (CDoom.players.to_unsafe + player).value.secretcount = secretcount

    p.value.usedown = 0 # don't do anything immediately
    p.value.attackdown = 0
    p.value.playerstate = CDoom::Playerstate::PST_LIVE
    p.value.health = @@deh_initial_health
    p.value.readyweapon = CDoom::Weapontype::Pistol
    p.value.pendingweapon = CDoom::Weapontype::Pistol
    p.value.weaponowned[CDoom::Weapontype::Fist.value] = 1
    p.value.weaponowned[CDoom::Weapontype::Pistol.value] = 1
    p.value.ammo[CDoom::Ammotype::Clip.value] = @@deh_initial_bullets

    CDoom::Ammotype::NUMAMMO.value.times do |i|
      p.value.maxammo[i] = CDoom.maxammo[i]
    end
  end

  def self.g_check_spot(playernum : Int32, mthing : CDoom::Mapthing*) : CDoom::DoomBool
    if CDoom.players[playernum].mo.null?
      # first spawn of level, before corpses
      playernum.times do |i|
        return 0 if (CDoom.players[i].mo.value.x == mthing.value.x.to_i32! << FRACBITS &&
                    CDoom.players[i].mo.value.y == mthing.value.y.to_i32! << FRACBITS)
      end
      return 1
    end

    x = mthing.value.x.to_i32! << FRACBITS
    y = mthing.value.y.to_i32! << FRACBITS

    return 0 if CDoom.p_check_position(CDoom.players[playernum].mo, x, y) == 0

    # flush an old corpse if needed
    if CDoom.bodyqueslot >= CDoom::BODYQUESIZE
      CDoom.p_remove_mobj(CDoom.bodyque[CDoom.bodyqueslot % CDoom::BODYQUESIZE])
    end
    CDoom.bodyque[CDoom.bodyqueslot % CDoom::BODYQUESIZE] = CDoom.players[playernum].mo
    CDoom.bodyqueslot += 1

    # spawn a teleport fog
    ss = CDoom.r_point_in_subsector(x, y)
    an = (ANG45 &* (mthing.value.angle.tdiv(45))) >> CDoom::ANGLETOFINESHIFT

    mo = CDoom.p_spawn_mobj(x + 20 * @@finecosine[an], y + 20 * @@finesine[an],
      ss.value.sector.value.floorheight, CDoom::Mobjtype::MT_TFOG)

    CDoom.s_start_sound(mo, CDoom::Sfxenum::SFX_telept) if CDoom.players[CDoom.consoleplayer].viewz != 1 # don't start sound on first frame

    return 1
  end

  def self.g_deathmatch_spawn_player(playernum : Int32)
    selections = (CDoom.deathmatch_p - CDoom.deathmatchstarts.to_unsafe).to_i32!
    if selections < 4
      CDoom.i_error("Error: Only #{selections} deathmatch spots, 4 required")
    end

    selections.times do |j|
      i = CDoom.p_random % selections
      if CDoom.g_check_spot(playernum, CDoom.deathmatchstarts.to_unsafe + i) != 0
        (CDoom.deathmatchstarts.to_unsafe + i).value.type = playernum + 1
        CDoom.p_spawn_player(CDoom.deathmatchstarts.to_unsafe + i)
        return
      end
    end

    # no good spot, so the player will probably get stuck
    CDoom.p_spawn_player(CDoom.playerstarts.to_unsafe + playernum)
  end

  def self.g_despawn_player(playernum : Int32)
    pmo = CDoom.players[playernum].mo

    x = pmo.value.x.to_i32!
    y = pmo.value.y.to_i32!

    # spawn a teleport fog
    ss = CDoom.r_point_in_subsector(x, y)
    an = (ANG45 &* (pmo.value.angle.tdiv(45))) >> CDoom::ANGLETOFINESHIFT

    mo = CDoom.p_spawn_mobj(x + 20 * @@finecosine[an], y + 20 * @@finesine[an],
      ss.value.sector.value.floorheight, CDoom::Mobjtype::MT_TFOG)

    CDoom.s_start_sound(mo, CDoom::Sfxenum::SFX_telept) if CDoom.players[CDoom.consoleplayer].viewz != 1 # don't start sound on first frame

    # Despawn player mobj
    p_remove_mobj(pmo)
    (CDoom.players.to_unsafe + playernum).value.mo = Pointer(CDoom::Mobj).null
  end

  #
  # g_do_reborn
  #
  def self.g_do_reborn(playernum : Int32)
    if CDoom.netgame == 0
      # reload the level from scatch
      CDoom.gameaction = CDoom::Gameaction::Loadlevel
    else
      # respawn at the start

      # first dissasociate the corpse
      CDoom.players[playernum].mo.value.player = Pointer(CDoom::Player).null

      # spawn at random spot if in death match
      if CDoom.deathmatch != 0
        CDoom.g_deathmatch_spawn_player(playernum)
        return
      end

      if CDoom.g_check_spot(playernum, CDoom.playerstarts.to_unsafe + playernum) != 0
        CDoom.p_spawn_player(CDoom.playerstarts.to_unsafe + playernum)
        return
      end

      # try to spawn at one of the other players spots
      CDoom::MAXPLAYERS.times do |i|
        if CDoom.g_check_spot(playernum, CDoom.playerstarts.to_unsafe + i) != 0
          (CDoom.playerstarts.to_unsafe + i).value.type = playernum + 1 # fake as other player
          CDoom.p_spawn_player(CDoom.playerstarts.to_unsafe + i)        # restore
          return
        end
        # he's going to be inside something. Too bad.
      end
      CDoom.p_spawn_player(CDoom.playerstarts.to_unsafe + playernum)
    end
  end

  def self.g_screenshot
    CDoom.gameaction = CDoom::Gameaction::Screenshot
  end

  def self.g_exit_level
    CDoom.secretexit = 0
    CDoom.gameaction = CDoom::Gameaction::Completed
  end

  # Here's for the german edition. Literally 1984
  def self.g_secret_exit_level
    # IF NO WOLF3D LEVELS, NO SECRET EXIT!
    if CDoom.gamemode == CDoom::GameMode::Commercial &&
       CDoom.w_check_num_for_name("map31") < 0
      CDoom.secretexit = 0
    else
      CDoom.secretexit = 1
    end
    CDoom.gameaction = CDoom::Gameaction::Completed
  end

  def self.g_do_completed
    CDoom.gameaction = CDoom::Gameaction::Nothing

    CDoom::MAXPLAYERS.times do |i|
      CDoom.g_player_finish_level(i) if CDoom.playeringame[i] != 0 # take away cards and stuff
    end

    CDoom.am_stop if CDoom.automapactive != 0

    if CDoom.gamemode != CDoom::GameMode::Commercial
      case CDoom.gamemap
      when 8
        # victory
        CDoom.gameaction = CDoom::Gameaction::Victory
        return
      when 9
        # exit secret level
        CDoom::MAXPLAYERS.times do |i|
          (CDoom.players.to_unsafe + i).value.didsecret = 1
        end
      end
    end

    CDoom.wminfo.didsecret = (CDoom.players.to_unsafe + CDoom.consoleplayer).value.didsecret
    CDoom.wminfo.epsd = CDoom.gameepisode - 1
    CDoom.wminfo.last = CDoom.gamemap - 1

    # wminfo.next is 0 biased, unlike gamemap
    if CDoom.gamemode == CDoom::GameMode::Commercial
      if CDoom.secretexit != 0
        case CDoom.gamemap
        when 15
          CDoom.wminfo.next = 30
        when 31
          CDoom.wminfo.next = 31
        end
      else
        case CDoom.gamemap
        when 31, 32
          CDoom.wminfo.next = 15
        else CDoom.wminfo.next = CDoom.gamemap
        end
      end
    else
      if CDoom.secretexit != 0
        CDoom.wminfo.next = 8 # go to secret level
      elsif CDoom.gamemap == 9
        # returning from secret level
        case CDoom.gameepisode
        when 1
          CDoom.wminfo.next = 3
        when 2
          CDoom.wminfo.next = 5
        when 3
          CDoom.wminfo.next = 6
        when 4
          CDoom.wminfo.next = 2
        end
      else
        CDoom.wminfo.next = CDoom.gamemap # go to next level
      end
    end

    CDoom.wminfo.maxkills = CDoom.totalkills
    CDoom.wminfo.maxitems = CDoom.totalitems
    CDoom.wminfo.maxsecret = CDoom.totalsecret
    CDoom.wminfo.maxfrags = 0
    if CDoom.gamemode == CDoom::GameMode::Commercial
      CDoom.wminfo.partime = 35 * CDoom.cpars[CDoom.gamemap - 1]
    else
      CDoom.wminfo.partime = 35 * CDoom.pars[CDoom.gameepisode - 1][CDoom.gamemap - 1]
    end
    CDoom.wminfo.pnum = CDoom.consoleplayer

    CDoom::MAXPLAYERS.times do |i|
      (CDoom.wminfo.plyr.to_unsafe + i).value.in = CDoom.playeringame[i]
      (CDoom.wminfo.plyr.to_unsafe + i).value.skills = CDoom.players[i].killcount
      (CDoom.wminfo.plyr.to_unsafe + i).value.sitems = CDoom.players[i].itemcount
      (CDoom.wminfo.plyr.to_unsafe + i).value.ssecret = CDoom.players[i].secretcount
      (CDoom.wminfo.plyr.to_unsafe + i).value.stime = CDoom.leveltime
      CDoom.doom_memcpy((CDoom.wminfo.plyr.to_unsafe + i).value.frags, CDoom.players[i].frags,
        sizeof(typeof(CDoom.wminfo.plyr[i].frags)))
    end

    CDoom.gamestate = CDoom::Gamestate::Intermission
    CDoom.viewactive = 0
    CDoom.automapactive = 0

    if !CDoom.statcopy.null?
      CDoom.doom_memcpy(CDoom.statcopy, pointerof(CDoom.wminfo), sizeof(typeof(CDoom.wminfo)))
    end

    CDoom.wi_start(pointerof(CDoom.wminfo))
  end

  #
  # g_world_done
  #
  def self.g_world_done
    CDoom.gameaction = CDoom::Gameaction::Worlddone

    (CDoom.players.to_unsafe + CDoom.consoleplayer).value.didsecret = 1 if CDoom.secretexit != 0

    if CDoom.gamemode == CDoom::GameMode::Commercial
      case CDoom.gamemap
      when 15, 31
        CDoom.f_start_finale if CDoom.secretexit == 0
      when 6, 11, 20, 30
        CDoom.f_start_finale
      end
    end
  end

  #
  # g_do_world_done
  #
  def self.g_do_world_done
    CDoom.gamestate = CDoom::Gamestate::Level
    CDoom.gamemap = CDoom.wminfo.next + 1
    CDoom.g_do_load_level
    CDoom.gameaction = CDoom::Gameaction::Nothing
    CDoom.viewactive = 1
  end

  #
  # g_load_game
  # Can be called by the startup code or the menu task.
  #
  def self.g_load_game(name : UInt8*)
    CDoom.doom_strcpy(CDoom.savename, name)
    CDoom.gameaction = CDoom::Gameaction::Loadgame
  end

  @@saveleveltime = 0

  def self.g_do_load_game
    CDoom.gameaction = CDoom::Gameaction::Nothing

    response = Channel({Bytes, Bool}).new
    @@io_jobs.send({String.new(CDoom.savename.to_unsafe), "rb", nil, response})
    data, ok = response.receive
    return unless ok

    IO::Memory.new(data).tap do |file|
      file.pos += CDoom::SAVESTRINGSIZE
      # skip the description field
      vcheck = "version #{SAVEVERSION}".ljust(CDoom::VERSIONSIZE, '\0')
      return if CDoom.doom_strcmp(file.read_string(CDoom::VERSIONSIZE).to_unsafe, vcheck.to_unsafe) != 0 # bad version

      CDoom.gameskill = CDoom::Skill.new(file.read_bytes(UInt8))
      CDoom.gameepisode = file.read_bytes(UInt8)
      CDoom.gamemap = file.read_bytes(UInt8)
      CDoom::MAXPLAYERS.times do |i|
        CDoom.playeringame[i] = file.read_bytes(UInt8)
      end

      # load a base level
      CDoom.g_init_new(CDoom.gameskill, CDoom.gameepisode, CDoom.gamemap)

      # get the times
      a = file.read_bytes(UInt8).to_u32
      b = file.read_bytes(UInt8).to_u32
      c = file.read_bytes(UInt8).to_u32
      CDoom.leveltime = (a << 16) + (b << 8) + c

      # dearchive all the modifications
      p_unarchive_players(file)
      p_unarchive_world(file)
      p_unarchive_thinkers(file)
      p_unarchive_specials(file)

      CDoom.i_error("Error: Bad savegame") if file.read_bytes(UInt8) != 0x1d
    end

    CDoom.r_execute_set_view_size if CDoom.setsizeneeded != 0

    # draw the pattern into the back screen
    CDoom.r_fill_back_screen
  end

  #
  # g_save_game
  # Called by the menu task.
  # Description is a 24 byte text string
  #
  def self.g_save_game(slot : Int32, description : UInt8*)
    CDoom.savegameslot = slot
    CDoom.doom_strcpy(CDoom.savedescription, description)
    CDoom.sendsave = 1
  end

  def self.g_do_save_game
    name = "#{@@deh_savegamename}#{CDoom.savegameslot}.dsg"
    description = CDoom.savedescription.to_slice
    buf = IO::Memory.new
    buf.write_string(description[0...CDoom::SAVESTRINGSIZE])

    name2 = "version #{SAVEVERSION}".ljust(CDoom::VERSIONSIZE, '\0')
    buf.write_string(name2.to_slice)

    buf.write_byte(CDoom.gameskill.value.to_u8!)
    buf.write_byte(CDoom.gameepisode.to_u8!)
    buf.write_byte(CDoom.gamemap.to_u8!)

    CDoom::MAXPLAYERS.times do |i|
      buf.write_byte(CDoom.playeringame[i].to_u8!)
    end
    buf.write_byte((CDoom.leveltime >> 16).to_u8!)
    buf.write_byte((CDoom.leveltime >> 8).to_u8!)
    buf.write_byte((CDoom.leveltime).to_u8!)

    p_archive_players(buf)
    p_archive_world(buf)
    p_archive_thinkers(buf)
    p_archive_specials(buf)

    buf.write_byte(0x1d)

    response = Channel({Bytes, Bool}).new
    @@io_jobs.send({name, "wb", buf.to_slice, response})
    response.receive

    CDoom.gameaction = CDoom::Gameaction::Nothing
    CDoom.savedescription[0] = 0

    (CDoom.players.to_unsafe + CDoom.consoleplayer).value.message = @@deh_ggsaved

    # draw the pattern into the back screen
    CDoom.r_fill_back_screen
  end

  #
  # g_init_new
  # Can be called by the startup code or the menu task,
  # consoleplayer, displayplayer, playeringame[] should be set.
  #
  def self.g_defered_init_new(skill : CDoom::Skill, episode : Int32, map : Int32)
    CDoom.d_skill = skill
    CDoom.d_episode = episode
    CDoom.d_map = map
    CDoom.gameaction = CDoom::Gameaction::Newgame
  end

  def self.g_do_new_game
    CDoom.demoplayback = 0
    CDoom.netdemo = 0
    CDoom.netgame = 0
    CDoom.deathmatch = 0
    CDoom.playeringame[1] = 0
    CDoom.playeringame[2] = 0
    CDoom.playeringame[3] = 0
    CDoom.respawnparm = 0
    CDoom.fastparm = 0
    CDoom.nomonsters = 0
    CDoom.consoleplayer = 0
    CDoom.g_init_new(CDoom.d_skill, CDoom.d_episode, CDoom.d_map)
    CDoom.gameaction = CDoom::Gameaction::Nothing
  end

  def self.g_init_new(skill : CDoom::Skill, episode : Int32, map : Int32)
    if CDoom.paused != 0
      CDoom.paused = 0
      CDoom.s_resume_sound
    end

    skill = CDoom::Skill::Nightmare if skill > CDoom::Skill::Nightmare

    # This was quite messy with SPECIAL and commented parts.
    # Supposedly hacks to make the latest edition work.
    # It might not work properly.
    episode = 1 if episode < 1

    if CDoom.gamemode == CDoom::GameMode::Retail
      episode = 4 if episode > 4
    elsif CDoom.gamemode == CDoom::GameMode::Shareware
      episode = 1 if episode > 1 # only start episode 1 on shareware
    else
      episode = 3 if episode > 3
    end

    map = 1 if map < 1

    map = 9 if map > 9 && CDoom.gamemode != CDoom::GameMode::Commercial

    CDoom.m_clear_random

    if skill == CDoom::Skill::Nightmare || CDoom.respawnparm != 0
      CDoom.respawnmonsters = 1
    else
      CDoom.respawnmonsters = 0
    end

    if CDoom.fastparm != 0 || (skill == CDoom::Skill::Nightmare && CDoom.gameskill != CDoom::Skill::Nightmare)
      i = CDoom::Statenum::S_SARG_RUN1.value
      while i <= CDoom::Statenum::S_SARG_PAIN2.value
        (CDoom.states + i).value.tics = CDoom.states[i].tics >> 1
        i += 1
      end
      (CDoom.mobjinfo + CDoom::Mobjtype::MT_BRUISERSHOT.value).value.speed = 20 * FRACUNIT
      (CDoom.mobjinfo + CDoom::Mobjtype::MT_HEADSHOT.value).value.speed = 20 * FRACUNIT
      (CDoom.mobjinfo + CDoom::Mobjtype::MT_TROOPSHOT.value).value.speed = 20 * FRACUNIT
    elsif skill != CDoom::Skill::Nightmare && CDoom.gameskill == CDoom::Skill::Nightmare
      i = CDoom::Statenum::S_SARG_RUN1.value
      while i <= CDoom::Statenum::S_SARG_PAIN2.value
        (CDoom.states + i).value.tics = CDoom.states[i].tics << 1
        i += 1
      end
      (CDoom.mobjinfo + CDoom::Mobjtype::MT_BRUISERSHOT.value).value.speed = 15 * FRACUNIT
      (CDoom.mobjinfo + CDoom::Mobjtype::MT_HEADSHOT.value).value.speed = 10 * FRACUNIT
      (CDoom.mobjinfo + CDoom::Mobjtype::MT_TROOPSHOT.value).value.speed = 10 * FRACUNIT
    end

    # force players to be initialized upon first level load
    CDoom::MAXPLAYERS.times { |i| (CDoom.players.to_unsafe + i).value.playerstate = CDoom::Playerstate::PST_REBORN }

    CDoom.usergame = 1 # will be set false if a demo
    CDoom.paused = 0
    CDoom.demoplayback = 0
    CDoom.automapactive = 0
    CDoom.viewactive = 1
    CDoom.gameepisode = episode
    CDoom.gamemap = map
    CDoom.gameskill = skill

    # set the sky map for the episode
    if CDoom.gamemode == CDoom::GameMode::Commercial
      CDoom.skytexture = CDoom.r_texture_num_for_name("SKY3")
      if CDoom.gamemap < 12
        CDoom.skytexture = CDoom.r_texture_num_for_name("SKY1")
      elsif CDoom.gamemap < 21
        CDoom.skytexture = CDoom.r_texture_num_for_name("SKY2")
      end
    else
      case episode
      when 1
        CDoom.skytexture = CDoom.r_texture_num_for_name("SKY1")
      when 2
        CDoom.skytexture = CDoom.r_texture_num_for_name("SKY2")
      when 3
        CDoom.skytexture = CDoom.r_texture_num_for_name("SKY3")
      when 4 # Special Edition sky
        CDoom.skytexture = CDoom.r_texture_num_for_name("SKY4")
      end
    end

    CDoom.g_do_load_level
  end

  #
  # DEMO RECORDING
  #
  def self.g_read_demo_ticcmd(cmd : CDoom::Ticcmd*)
    if CDoom.demo_p.value == CDoom::DEMOMARKER
      # end of demo data stream
      CDoom.g_check_demo_status
      return
    end
    cmd.value.forwardmove = CDoom.demo_p.value.to_i8!
    CDoom.demo_p += 1
    cmd.value.sidemove = CDoom.demo_p.value.to_i8!
    CDoom.demo_p += 1
    cmd.value.angleturn = (CDoom.demo_p.value.to_u8!).to_i32 << 8
    CDoom.demo_p += 1
    cmd.value.buttons = CDoom.demo_p.value.to_u8!
    CDoom.demo_p += 1
  end

  @@prevstate : CDoom::Playerstate = CDoom::Playerstate::PST_LIVE

  def self.g_write_demo_ticcmd(cmd : CDoom::Ticcmd*)
    pstate = CDoom.players[CDoom.consoleplayer].playerstate
    CDoom.g_check_demo_status if CDoom.gamekeydown['q'.ord] != 0 # ||                                                         # press q to end demo recording
    # (@@prevstate == CDoom::Playerstate::PST_DEAD && pstate == CDoom::Playerstate::PST_LIVE) || # or if player is respawning
    # CDoom.gamestate != CDoom::Gamestate::Level                                                 # or if we are no longer on a level
    @@prevstate = pstate
    CDoom.demo_p.value = cmd.value.forwardmove.to_u8!
    CDoom.demo_p += 1
    CDoom.demo_p.value = cmd.value.sidemove.to_u8!
    CDoom.demo_p += 1
    CDoom.demo_p.value = ((cmd.value.angleturn.to_i32 + 128) >> 8).to_u8!
    CDoom.demo_p += 1
    CDoom.demo_p.value = cmd.value.buttons.to_u8!
    CDoom.demo_p += 1
    CDoom.demo_p -= 4
    if CDoom.demo_p > CDoom.demoend - 16
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
    CDoom.usergame = 0
    CDoom.doom_strcpy(CDoom.demoname, name)
    CDoom.doom_concat(CDoom.demoname, ".lmp")
    maxsize = 0x20000
    i = ARGV.index("-maxdemo")
    maxsize = ARGV[i + 1].to_i * 1024 if i && i < ARGV.size - 1
    CDoom.demobuffer = CDoom.z_malloc(maxsize, CDoom::PU_STATIC, Pointer(Void).null).as(UInt8*)
    CDoom.demoend = CDoom.demobuffer + maxsize

    CDoom.demorecording = 1
  end

  def self.g_begin_recording
    @@prevstate = CDoom::Playerstate::PST_LIVE

    CDoom.demo_p = CDoom.demobuffer

    CDoom.demo_p.value = DEMOVERSION.to_u8
    CDoom.demo_p += 1
    CDoom.demo_p.value = CDoom.gameskill.value.to_u8
    CDoom.demo_p += 1
    CDoom.demo_p.value = CDoom.gameepisode.to_u8
    CDoom.demo_p += 1
    CDoom.demo_p.value = CDoom.gamemap.to_u8
    CDoom.demo_p += 1
    CDoom.demo_p.value = CDoom.deathmatch.to_u8
    CDoom.demo_p += 1
    CDoom.demo_p.value = CDoom.respawnparm.to_u8
    CDoom.demo_p += 1
    CDoom.demo_p.value = CDoom.fastparm.to_u8
    CDoom.demo_p += 1
    CDoom.demo_p.value = CDoom.nomonsters.to_u8
    CDoom.demo_p += 1
    CDoom.demo_p.value = CDoom.consoleplayer.to_u8
    CDoom.demo_p += 1

    CDoom::MAXPLAYERS.times do |i|
      CDoom.demo_p.value = CDoom.playeringame[i].to_u8
      CDoom.demo_p += 1
    end
  end

  #
  # g_play_demo
  #

  def self.g_defered_play_demo(name : UInt8*)
    CDoom.defdemoname = name
    CDoom.gameaction = CDoom::Gameaction::Playdemo
  end

  def self.g_do_play_demo
    CDoom.gameaction = CDoom::Gameaction::Nothing
    CDoom.demobuffer = CDoom.w_cache_lump_name(CDoom.defdemoname, CDoom::PU_STATIC).as(UInt8*)
    CDoom.demo_p = CDoom.demobuffer
    demo_version = CDoom.demo_p.value
    CDoom.demo_p += 1
    if demo_version != DEMOVERSION && demo_version != 109 # Demos seem to run fine with version 109
      puts "Demo is from a different game version! Demo Verson = #{demo_version}, this version = #{DEMOVERSION}"
      CDoom.gameaction = CDoom::Gameaction::Nothing
      return
    end

    skill = CDoom::Skill.new(CDoom.demo_p.value)
    CDoom.demo_p += 1
    episode = CDoom.demo_p.value
    CDoom.demo_p += 1
    map = CDoom.demo_p.value
    CDoom.demo_p += 1
    CDoom.deathmatch = CDoom.demo_p.value
    CDoom.demo_p += 1
    CDoom.respawnparm = CDoom.demo_p.value
    CDoom.demo_p += 1
    CDoom.fastparm = CDoom.demo_p.value
    CDoom.demo_p += 1
    CDoom.nomonsters = CDoom.demo_p.value
    CDoom.demo_p += 1
    CDoom.consoleplayer = CDoom.demo_p.value
    CDoom.demo_p += 1

    CDoom::MAXPLAYERS.times do |i|
      CDoom.playeringame[i] = CDoom.demo_p.value
      CDoom.demo_p += 1
    end
    if CDoom.playeringame[1] != 0
      CDoom.netgame = 1
      CDoom.netdemo = 1
    end

    # don't spend a lot of time in loadlevel
    CDoom.precache = 0
    CDoom.g_init_new(skill, episode, map)
    CDoom.precache = 1

    CDoom.usergame = 0
    CDoom.demoplayback = 1
  end

  #
  # g_time_demo
  #
  def self.g_time_demo(name : UInt8*)
    CDoom.nodrawers = ARGV.includes?("-nodraw") ? 1 : 0
    CDoom.noblit = ARGV.includes?("-noblit") ? 1 : 0
    CDoom.timingdemo = 1
    CDoom.singletics = 1

    CDoom.defdemoname = name
    CDoom.gameaction = CDoom::Gameaction::Playdemo
  end

  # ===================
  # =
  # = g_check_demo_status
  # =
  # = Called after a death or level completion to allow demos to be cleaned up
  # = Returns true if a new demo loop action will take place
  # ===================
  def self.g_check_demo_status : CDoom::DoomBool
    if CDoom.timingdemo != 0
      endtime = CDoom.i_get_time

      CDoom.i_error("Error: timed #{CDoom.gametic} gametics in #{endtime - CDoom.starttime} realtics")
    end

    if CDoom.demoplayback != 0
      CDoom.i_quit if CDoom.singledemo != 0

      z_change_tag(CDoom.demobuffer, CDoom::PU_CACHE)
      CDoom.demoplayback = 0
      CDoom.netdemo = 0
      CDoom.netgame = 0
      CDoom.deathmatch = 0
      CDoom.playeringame[1] = 0
      CDoom.playeringame[2] = 0
      CDoom.playeringame[3] = 0
      CDoom.respawnparm = 0
      CDoom.fastparm = 0
      CDoom.nomonsters = 0
      CDoom.consoleplayer = 0
      CDoom.d_advance_demo
      return 1
    end

    if CDoom.demorecording != 0
      CDoom.demo_p.value = CDoom::DEMOMARKER.to_u8
      CDoom.demo_p += 1
      CDoom.m_write_file(CDoom.demoname, CDoom.demobuffer, (CDoom.demo_p - CDoom.demobuffer).to_i32!)
      CDoom.z_free(CDoom.demobuffer)
      CDoom.demorecording = 0

      CDoom.i_error("Error: Demo #{String.new(CDoom.demoname.to_unsafe)} recorded")
    end

    return 0
  end
end
