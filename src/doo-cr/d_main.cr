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
# ==> Init/General code

module Doocr
  #
  # d_post_event
  # Called by the I/O functions when input is detected
  #
  def self.d_post_event(ev : CDoom::Event*)
    CDoom.events[CDoom.eventhead] = ev.value
    CDoom.eventhead += 1
    CDoom.eventhead = (CDoom.eventhead) & (CDoom::MAXEVENTS - 1)
  end

  #
  # d_process_events
  # Send all the events of the given timestamp down the responder chain
  #
  def self.d_process_events
    # IF STORE DEMO, DO NOT ACCEPT INPUT
    return if CDoom.gamemode == CDoom::GameMode::Commercial &&
              CDoom.w_check_num_for_name("map01") < 0

    while CDoom.eventtail != CDoom.eventhead
      ev = CDoom.events.to_unsafe + CDoom.eventtail
      CDoom.g_responder(ev) if m_responder(ev) == 0
      # else menu ate the event
      CDoom.eventtail += 1
      CDoom.eventtail = (CDoom.eventtail) & (CDoom::MAXEVENTS - 1)
    end
  end

  @@viewactivestate = false
  @@menuactivestate = false
  @@inhelpscreenstate = false
  @@fullscreen = false
  @@oldgamestate = -1
  @@borderdrawcount = 0

  def self.d_display_load
    if !@@loading_patch.null?
      x = CDoom::SCREENWIDTH - @@loading_patch.value.width
        y = CDoom::SCREENHEIGHT - @@loading_patch.value.height
        v_copy_rect(x, y, 0, 
        @@loading_patch.value.width, @@loading_patch.value.height,
        x, y, 4)

        CDoom.v_draw_patch(x, y, 0, @@loading_patch)
        @@loading_disk_shown = true
    end
        @@do_loading_disk = false
  end

  def self.d_display_clear_load
if !@@loading_patch.null?
  x = CDoom::SCREENWIDTH - @@loading_patch.value.width
        y = CDoom::SCREENHEIGHT - @@loading_patch.value.height
        v_copy_rect(x, y, 4, 
        @@loading_patch.value.width, @@loading_patch.value.height,
        x, y, 0)
end
 @@loading_disk_shown = false
end

  #
  # d_display
  #  draw current display, possibly wiping it from the previous
  #
  def self.d_display
    if @@was_focused != Raylib.window_focused?
      if (@@was_focused = Raylib.window_focused?)
        Raylib.disable_cursor
      else
        Raylib.enable_cursor
      end
    end

    return if CDoom.nodrawers != 0 # for comparative timing / profiling

    redrawsbar = !@@software_rendering # Always redraw for transparency issues

    # change the view size if needed
    if CDoom.setsizeneeded != 0
      CDoom.r_execute_set_view_size
      @@oldgamestate = -1 # force background redraw
      @@borderdrawcount = 3
    end

    wipe = false
    # save the current screen if about to wipe
    if CDoom.gamestate != CDoom.wipegamestate
      wipe = true
      d_display_load
      i_finish_update
      CDoom.wipe_start_screen(0, 0, CDoom::SCREENWIDTH, CDoom::SCREENHEIGHT)
    end
    CDoom.screens[0].fill(CDoom::SCREENHEIGHT * CDoom::SCREENWIDTH, 255) unless @@software_rendering

    d_display_clear_load if @@loading_disk_shown

    CDoom.hu_erase if CDoom.gamestate == CDoom::Gamestate::Level && CDoom.gametic != 0

    # do buffered drawing
    case CDoom.gamestate
    when CDoom::Gamestate::Level
      if CDoom.gametic != 0
        CDoom.am_drawer if CDoom.automapactive != 0 && @@amactivedraw == 0
        redrawsbar = true if wipe || (CDoom.viewheight != 200 && @@fullscreen)
        redrawsbar = true if @@inhelpscreenstate && CDoom.inhelpscreens == 0 # just put away the help screen
        CDoom.st_drawer((CDoom.viewheight == 200).to_unsafe, redrawsbar.to_unsafe)
        @@fullscreen = CDoom.viewheight == 200
      end
    when CDoom::Gamestate::Intermission
      CDoom.wi_drawer
    when CDoom::Gamestate::Finale
      CDoom.f_drawer
    when CDoom::Gamestate::Demoscreen
      CDoom.d_page_drawer
    end

    # draw buffered stuff to screen
    CDoom.i_update_no_blit

    # draw the view directly
    if CDoom.gamestate == CDoom::Gamestate::Level && CDoom.gametic != 0
      if CDoom.automapactive != 0
        if @@amactivedraw != 0
          CDoom.r_render_player_view(CDoom.players.to_unsafe + CDoom.displayplayer)
          CDoom.am_drawer
        end
      else
        CDoom.r_render_player_view(CDoom.players.to_unsafe + CDoom.displayplayer)
      end
    end

    CDoom.hu_drawer if CDoom.gamestate == CDoom::Gamestate::Level && CDoom.gametic != 0

    # clean up border stuff
    if CDoom.gamestate.value != @@oldgamestate && CDoom.gamestate != CDoom::Gamestate::Level
      CDoom.i_set_palette(CDoom.w_cache_lump_name("PLAYPAL", CDoom::PU_CACHE).as(UInt8*))
    end

    # see if the border needs to be initially drawn
    if CDoom.gamestate == CDoom::Gamestate::Level && @@oldgamestate != CDoom::Gamestate::Level.value
      @@viewactivestate = false # view was not active
      CDoom.r_fill_back_screen  # draw the pattern into the back screen
    end

    # see if the border needs to be updated to the screen
    if CDoom.gamestate == CDoom::Gamestate::Level && CDoom.automapactive == 0 && CDoom.scaledviewwidth != 320
      CDoom.r_draw_view_border unless @@software_rendering
      @@borderdrawcount = 3 if CDoom.menuactive != 0 || @@menuactivestate || !@@viewactivestate
      if @@borderdrawcount != 0
        CDoom.r_draw_view_border # erase old menu stuff
        @@borderdrawcount -= 1
      end
    end

    @@menuactivestate = CDoom.menuactive != 0
    @@viewactivestate = CDoom.viewactive != 0
    @@inhelpscreenstate = CDoom.inhelpscreens != 0
    @@oldgamestate = CDoom.gamestate.value
    CDoom.wipegamestate = CDoom.gamestate

    # draw pause pic
    if CDoom.paused != 0
      y = 0
      if CDoom.automapactive != 0
        y = 4
      else
        y = CDoom.viewwindowy + 4
      end
      CDoom.v_draw_patch_direct(CDoom.viewwindowx + (CDoom.scaledviewwidth - 68) // 2,
        y, 0, CDoom.w_cache_lump_name("M_PAUSE", CDoom::PU_CACHE).as(CDoom::Patch*))
    end

    # menus go directly to the screen
    CDoom.m_drawer   # menu is drawn even on top of everything
    CDoom.net_update # send out any new accumulation

    d_display_load if @@do_loading_disk

    # normal update
    if !wipe
      CDoom.i_finish_update # page flip or blit buffer
      return
    end

    # wipe update
    unless @@software_rendering
      @@viewport_target.try do |vt|
        update_viewport(vt)
      end
    end

    d_display_clear_load if @@loading_disk_shown

    CDoom.wipe_end_screen(0, 0, CDoom::SCREENWIDTH, CDoom::SCREENHEIGHT)

    wipestart = i_get_time - 1
    done = 0
    tics = 0
    nowtime = 0

    loop do
      loop do
        nowtime = i_get_time
        tics = nowtime - wipestart
        break if tics != 0
      end
      wipestart = nowtime
      done = CDoom.wipe_screen_wipe(CDoom::WIPE_MELT, 0, 0, CDoom::SCREENWIDTH, CDoom::SCREENHEIGHT, 1)

      i_update_no_blit
      m_drawer        # menu is drawn even on top of wipes
      i_finish_update # page flip or blit buffer

      break if done != 0
    end
  end

  def self.d_doom_loop
    until Raylib.close_window?
      # frame syncronous IO operations
      CDoom.i_start_frame

      # process one or more tics
      if CDoom.singletics != 0
        i_start_tic
        CDoom.d_process_events
        CDoom.g_build_ticcmd((CDoom.netcmds.to_unsafe + CDoom.consoleplayer).value.to_unsafe + CDoom.maketic % CDoom::BACKUPTICS)
        CDoom.d_do_advance_demo if CDoom.advancedemo != 0
        CDoom.m_ticker
        CDoom.g_ticker
        CDoom.gametic &+= 1
        CDoom.maketic += 1
      else
        CDoom.try_run_tics # will run at least one tic
      end

      CDoom.s_update_sounds(CDoom.players[CDoom.consoleplayer].mo) # move positional sounds
      # Update display, next frame, with current state.
      CDoom.d_display
    end

    i_quit
  end

  #
  # d_page_ticker
  # Handles timing for warped projection
  #
  def self.d_page_ticker
    CDoom.pagetic -= 1
    CDoom.d_advance_demo if CDoom.pagetic < 0
  end

  def self.d_page_drawer
    CDoom.v_draw_patch(0, 0, 0, CDoom.w_cache_lump_name(CDoom.pagename, CDoom::PU_CACHE).as(CDoom::Patch*))
  end

  #
  # d_advance_demo
  # Called after each demo or intro demosequence finishes
  #
  def self.d_advance_demo
    CDoom.advancedemo = 1
  end

  #
  # This cycles through the demo sequences.
  # Todo: FIXME - version dependend demo numbers?
  #
  def self.d_do_advance_demo
    (CDoom.players.to_unsafe + CDoom.consoleplayer).value.playerstate = CDoom::Playerstate::PST_LIVE # not reborn
    CDoom.advancedemo = 0
    CDoom.usergame = 0 # no save / end game here
    CDoom.paused = 0
    CDoom.gameaction = CDoom::Gameaction::Nothing

    if CDoom.gamemode == CDoom::GameMode::Retail
      CDoom.demosequence = (CDoom.demosequence + 1) % 7
    else
      CDoom.demosequence = (CDoom.demosequence + 1) % 6
    end

    case CDoom.demosequence
    when 0
      if CDoom.gamemode == CDoom::GameMode::Commercial
        CDoom.pagetic = 35 * 11
      else
        CDoom.pagetic = 170
      end
      CDoom.gamestate = CDoom::Gamestate::Demoscreen
      CDoom.pagename = "TITLEPIC"
      if CDoom.gamemode == CDoom::GameMode::Commercial
        CDoom.s_start_music(CDoom::Musicenum::MUS_dm2ttl)
      else
        CDoom.s_start_music(CDoom::Musicenum::MUS_intro)
      end
    when 1
      CDoom.g_defered_play_demo("demo1")
    when 2
      CDoom.pagetic = 200
      CDoom.gamestate = CDoom::Gamestate::Demoscreen
      CDoom.pagename = "CREDIT"
    when 3
      CDoom.g_defered_play_demo("demo2")
    when 4
      CDoom.gamestate = CDoom::Gamestate::Demoscreen
      if CDoom.gamemode == CDoom::GameMode::Commercial
        CDoom.pagetic = 35 * 11
        CDoom.pagename = "TITLEPIC"
        CDoom.s_start_music(CDoom::Musicenum::MUS_dm2ttl)
      else
        CDoom.pagetic = 200

        if CDoom.gamemode == CDoom::GameMode::Retail
          CDoom.pagename = "CREDIT"
        else
          CDoom.pagename = "HELP2"
        end
      end
    when 5
      CDoom.g_defered_play_demo("demo3")
      # THE DEFINITIVE DOOM Special Edition demo
    when 6
      CDoom.g_defered_play_demo("demo4")
    end
  end

  def self.d_start_title
    CDoom.gameaction = CDoom::Gameaction::Nothing
    CDoom.demosequence = -1
    CDoom.d_advance_demo
  end

  def self.d_add_file(file : UInt8*)
    numwadfiles = 0
    until CDoom.wadfiles[numwadfiles].null?
      numwadfiles += 1
    end

    newfile = GC.malloc(doom_strlen(file) + 1)
    CDoom.doom_strcpy(newfile.as(UInt8*), file)

    CDoom.wadfiles[numwadfiles] = newfile.as(UInt8*)
  end

  def self.d_merge_file(file : String)
    @@merge_files << file
  end

  #
  # Confirms a WAD files type
  # based off of data in the WAD
  #
  def self.confirm_version
    if w_check_num_for_name("map01".to_unsafe) != -1 && # Doom 2
       # w_check_num_for_name("map32".to_unsafe) != -1 && # Custom Wads might not have all maps
       w_check_num_for_name("interpic".to_unsafe) != -1 &&
       w_check_num_for_name("d_runnin".to_unsafe) != -1
      CDoom.gamemode = CDoom::GameMode::Commercial
      # Don't overwrite Packs
      if CDoom.gamemission == CDoom::GameMission::None ||
         CDoom.gamemission == CDoom::GameMission::Doom
        CDoom.gamemission = CDoom::GameMission::Doom2
      end
      return
    end

    if w_check_num_for_name("e1m1".to_unsafe) != -1 # Shareware
      CDoom.gamemission = CDoom::GameMission::Doom

      if w_check_num_for_name("e2m1".to_unsafe) != -1 && # Registered
         w_check_num_for_name("e3m1".to_unsafe) != -1
        if w_check_num_for_name("e4m1".to_unsafe) != -1 && # Retail
           w_check_num_for_name("interpic".to_unsafe) != -1
          CDoom.gamemode = CDoom::GameMode::Retail
        else
          CDoom.gamemode = CDoom::GameMode::Registered
        end
        return
      else
        CDoom.gamemode = CDoom::GameMode::Shareware
      end
    end
  end

  #
  # identify_version
  # Checks availability of IWAD files by name,
  # to determine whether registered/commercial features
  # should be executed (notably loading PWAD's).
  #
  def self.identify_version
    doomwaddir = Pointer(UInt8).null
    ENV["DOOMWADDIR"]?.try { |env| doomwaddir = env.to_unsafe }
    doomwaddir = ".".to_unsafe if doomwaddir.null?

    # Commercial.
    doom2wad = String.new(doomwaddir) + "/doom2.wad"

    # Retail.
    doomuwad = String.new(doomwaddir) + "/doomu.wad"

    # Registered.
    doomwad = String.new(doomwaddir) + "/doom.wad"

    # Shareware.
    doom1wad = String.new(doomwaddir) + "/doom1.wad"

    # Bug, dear Shawn.
    # Insufficient malloc, caused spurious realloc errors.
    plutoniawad = String.new(doomwaddir) + "/plutonia.wad"

    tntwad = String.new(doomwaddir) + "/tnt.wad"

    # French stuff
    doom2fwad = String.new(doomwaddir) + "/doom2f.wad"

    home = ".".to_unsafe # Don't be cute. Just use binary dir

    CDoom.doom_strcpy(CDoom.basedefault, home)
    CDoom.doom_concat(CDoom.basedefault, "/config.cfg")

    # Custom. Prioritize over other parmgs
    customwad = Pointer(UInt8*).null
    force = false
    p = ARGV.index("-iwad")
    if !p
      p = ARGV.index("-fwad")
      forced = !p.nil?
    end

    if p && p < ARGV.size - 1
      CDoom.modifiedgame = 1 # I hope so?
      customwad = String.new(doomwaddir) + "/" + ARGV[p + 1]
      if (handle = doom_open(customwad.to_unsafe, "rb".to_unsafe)).null?
        # Wad not found, give them a chance
        CDoom.doom_concat(customwad, ".wad".to_unsafe)
        if (handle = doom_open(customwad.to_unsafe, "rb".to_unsafe)).null?
          CDoom.i_error("Error: identify_version: '-iwad #{customwad}' could not find file specified")
        end
      end
      # Wad is real. Check for IWAD unless forced
      unless forced
        header = CDoom::Wadinfo.new
        doom_read(handle, pointerof(header).as(Void*), sizeof(typeof(header)))
        doom_close(handle)
        if CDoom.doom_strncmp(header.identification, "IWAD", 4) != 0
          CDoom.i_error("Error: identify_version: '-iwad #{customwad}' found, but is not an IWAD")
        end
      end

      CDoom.gamemode = CDoom::GameMode::Indetermined
      CDoom.gamemission = CDoom::GameMission::None
      CDoom.d_add_file(customwad)
      return
    end

    if ARGV.includes?("-shdev")
      CDoom.gamemode = CDoom::GameMode::Shareware
      CDoom.gamemission = CDoom::GameMission::Doom
      CDoom.devparm = 1
      CDoom.d_add_file(CDoom::DEVDATA + "doom1.wad")
      CDoom.d_add_file(CDoom::DEVMAPS + "data_se/texture1.lmp")
      CDoom.d_add_file(CDoom::DEVMAPS + "data_se/pnames.lmp")
      CDoom.doom_strcpy(CDoom.basedefault, CDoom::DEVDATA + "default.cfg")
      return
    end

    if ARGV.includes?("-regdev")
      CDoom.gamemode = CDoom::GameMode::Registered
      CDoom.gamemission = CDoom::GameMission::Doom
      CDoom.devparm = 1
      CDoom.d_add_file(CDoom::DEVDATA + "doom.wad")
      CDoom.d_add_file(CDoom::DEVMAPS + "data_se/texture1.lmp")
      CDoom.d_add_file(CDoom::DEVMAPS + "data_se/texture2.lmp")
      CDoom.d_add_file(CDoom::DEVMAPS + "data_se/pnames.lmp")
      CDoom.doom_strcpy(CDoom.basedefault, CDoom::DEVDATA + "default.cfg")
      return
    end

    if ARGV.includes?("-comdev")
      CDoom.gamemode = CDoom::GameMode::Commercial
      CDoom.gamemission = CDoom::GameMission::Doom2
      CDoom.devparm = 1
      CDoom.d_add_file(CDoom::DEVDATA + "doom2.wad")

      CDoom.d_add_file(CDoom::DEVMAPS + "cdata/texture1.lmp")
      CDoom.d_add_file(CDoom::DEVMAPS + "cdata/pnames.lmp")
      CDoom.doom_strcpy(CDoom.basedefault, CDoom::DEVDATA + "default.cfg")
      return
    end

    if !(f = doom_open(doom2fwad.to_unsafe, "rb".to_unsafe)).null?
      doom_close(f)
      CDoom.gamemode = CDoom::GameMode::Commercial
      CDoom.gamemission = CDoom::GameMission::Doom2
      # C'est ridicule!
      # Let's handle languages in config files, okay?
      CDoom.language = CDoom::Language::French
      puts "French version"
      CDoom.d_add_file(doom2fwad)
      return
    end

    if !(f = doom_open(doom2wad.to_unsafe, "rb".to_unsafe)).null?
      doom_close(f)
      CDoom.gamemode = CDoom::GameMode::Commercial
      CDoom.gamemission = CDoom::GameMission::Doom2
      CDoom.d_add_file(doom2wad)
      return
    end

    if !(f = doom_open(plutoniawad.to_unsafe, "rb".to_unsafe)).null?
      doom_close(f)
      CDoom.gamemode = CDoom::GameMode::Commercial
      CDoom.gamemission = CDoom::GameMission::PackPlut
      CDoom.d_add_file(plutoniawad)
      return
    end

    if !(f = doom_open(tntwad.to_unsafe, "rb".to_unsafe)).null?
      doom_close(f)
      CDoom.gamemode = CDoom::GameMode::Commercial
      CDoom.gamemission = CDoom::GameMission::PackTnt
      CDoom.d_add_file(tntwad)
      return
    end

    if !(f = doom_open(doomuwad.to_unsafe, "rb".to_unsafe)).null?
      doom_close(f)
      CDoom.gamemode = CDoom::GameMode::Retail
      CDoom.gamemission = CDoom::GameMission::Doom
      CDoom.d_add_file(doomuwad)
      return
    end

    if !(f = doom_open(doomwad.to_unsafe, "rb".to_unsafe)).null?
      doom_close(f)
      CDoom.gamemode = CDoom::GameMode::Registered
      CDoom.gamemission = CDoom::GameMission::Doom
      CDoom.d_add_file(doomwad)
      return
    end

    if !(f = doom_open(doom1wad.to_unsafe, "rb".to_unsafe)).null?
      doom_close(f)
      CDoom.gamemode = CDoom::GameMode::Shareware
      CDoom.gamemission = CDoom::GameMission::Doom
      CDoom.d_add_file(doom1wad)
      return
    end

    puts "Game mode indeterminate."
    CDoom.gamemode = CDoom::GameMode::Indetermined
  end

  #
  # Find a Response File
  #
  def self.find_response_file
    (ARGV.size - 1).times do |i|
      i += 1

      if ARGV[i][0] == '@'
        moreargs = uninitialized StaticArray(UInt8*, 20)

        # READ THE RESPONSE FILE INTO MEMORY
        handle = doom_open(ARGV_UNSAFE[i] + 1, "rb".to_unsafe)
        if handle.null?
          print "\nNo such response file!"
          exit(1)
        end
        puts "Found response file #{ARGV[i][1..]}!"
        doom_seek(handle, 0, CDoom::DoomSeek::DOOM_SEEK_END)
        size = doom_tell(handle)
        doom_seek(handle, 0, CDoom::DoomSeek::DOOM_SEEK_SET)
        file = GC.malloc(size)
        doom_read(handle, file, size * 1)
        doom_close(handle)

        # KEEP ALL CMDLINE ARGS FOLLOWING @RESPONSEFILE ARG
        index = 0
        k = i + 1
        while k < ARGV.size
          moreargs[index] = ARGV_UNSAFE[k]
          index += 1
          k += 1
        end

        infile = file.as(UInt8*)
        indexinfile = 0
        k = 0
        indexinfile += 1 # SKIP PAST ARGV[0] (KEEP IT)
        loop do
          ARGV[indexinfile] = String.new(infile + k)
          indexinfile += 1
          while k < size &&
                (((infile + k).value >= ' '.ord + 1) && ((infile + k).value <= 'z'.ord))
            k += 1
          end
          (infile + k).value = 0
          while k < size &&
                (((infile + k).value <= ' '.ord) || ((infile + k).value > 'z'.ord))
            k += 1
          end

          break if !(k < size)
        end

        k = 0
        while k < index
          ARGV[indexinfile] = String.new(moreargs[k])
          indexinfile += 1
          k += 1
        end

        # DISPLAY ARGS
        puts "#{ARGV.size} command-line args"
        k = 1
        while k < ARGV.size
          puts ARGV[k]
          k += 1
        end

        break
      end
    end
  end

  @@title = ""

  #
  # d_doom_main
  #
  def self.d_doom_main
    Raylib.set_trace_log_level(Raylib::TraceLogLevel::Error)

    if ARGV.includes?("-v")
      puts "DOO-CR v#{VERSION_STR} - DEMO v#{DEMOVERSION} | SAVE v#{SAVEVERSION} | NET v#{NETVERSION}"
      puts "Built #{BUILD_TIME}"
      exit(0)
    end

    CDoom.find_response_file

    CDoom.identify_version

    CDoom.modifiedgame = 0

    CDoom.nomonsters = ARGV.includes?("-nomonsters") ? 1 : 0
    CDoom.respawnparm = ARGV.includes?("-respawn") ? 1 : 0
    CDoom.fastparm = ARGV.includes?("-fast") ? 1 : 0
    CDoom.devparm = ARGV.includes?("-devparm") ? 1 : 0
    if ARGV.includes?("-altdeath")
      CDoom.deathmatch = 2
    elsif ARGV.includes?("-deathmatch")
      CDoom.deathmatch = 1
    end

    fr, fgc, fb = SHELLCOLORS[14]
    br, bgc, bb = SHELLCOLORS[1]

    print "\e[2J\e[H"
    print "\e[?25l"
    print "\e[1;1H\e[2K\e"
    print "\e[38;2;#{fr};#{fgc};#{fb}m"
    print "\e[48;2;#{br};#{bgc};#{bb}m"
    puts "DOO-CR Operating System v#{VERSION_STR} ".center(77)
    puts " DEMO v#{DEMOVERSION} | SAVE v#{SAVEVERSION} | NET v#{NETVERSION} ".center(77)
    print "\e[0m"
    print "\e[3;1H\e[38;5;250m\e[49m"

    print @@deh_d_devstr if CDoom.devparm != 0

    # turbo option
    if p = ARGV.index("-turbo")
      scale = 200

      if p < ARGV.size - 1
        scale = ARGV[p + 1].to_i
      end
      scale = 10 if scale < 10
      scale = 400 if scale > 400
      puts "turbo scale: #{scale}%"
      CDoom.forwardmove[0] = CDoom.forwardmove[0] * scale // 100
      CDoom.forwardmove[1] = CDoom.forwardmove[1] * scale // 100
      CDoom.sidemove[0] = CDoom.sidemove[0] * scale // 100
      CDoom.sidemove[1] = CDoom.sidemove[1] * scale // 100
    end

    # add any files specified on the command line with -file wadfile
    # to the wad list
    #
    # convenience hack to allow -wart e m to add a wad file
    # prepend a tilde to the filename so wadfile will be reloadable
    p = ARGV.index("-wart")
    if p
      ARGV[p] = ARGV[p].sub(4, 'p') # big hack, change to -warp

      # Map name handling
      case CDoom.gamemode
      when CDoom::GameMode::Shareware, CDoom::GameMode::Retail, CDoom::GameMode::Registered
        file = "~#{CDoom::DEVMAPS}E" +
               ARGV[p + 1][0] + "M" + ARGV[p + 2][0] + ".wad"
        puts "Warping to Episode #{ARGV[p + 1]}" +
             ", Map #{ARGV[p + 2]}."
        # when CDoom::GameMode::Commercial
      else
        p = ARGV[p + 1].to_i
        if p < 10
          file = "~#{CDoom::DEVMAPS}cdata/map0#{p}.wad"
        else
          file = "~#{CDoom::DEVMAPS}cdata/map#{p}.wad"
        end
      end
      CDoom.d_add_file(file)
    end

    p = ARGV.index("-file")
    if p
      # the parms after p are wadfile/lump names,
      # until end of parms or another - preceded parm
      CDoom.modifiedgame = 1 # homebrew levels
      p += 1
      while (p != ARGV.size) && ARGV[p][0] != '-'
        CDoom.d_add_file(ARGV[p])
        p += 1
      end
    end

    p = ARGV.index("-merge")
    if p
      # the parms after p are wadfile/lump names,
      # until end of parms or another - preceded parm
      CDoom.modifiedgame = 1 # homebrew levels
      p += 1
      while (p != ARGV.size) && ARGV[p][0] != '-'
        d_merge_file(ARGV[p])
        p += 1
      end
    end

    p = ARGV.index("-playdemo")

    p = ARGV.index("-timedemo") unless p

    if p && p < ARGV.size - 1
      file = ARGV[p + 1] + ".lmp"
      CDoom.d_add_file(file)
      puts "Playing demo #{ARGV[p + 1]}.lmp."
    end

    # get skill / episode / map from parms
    CDoom.startskill = CDoom::Skill::Medium
    CDoom.startepisode = 1
    CDoom.startmap = 1
    CDoom.autostart = 0

    p = ARGV.index("-skill")
    if p && p < ARGV.size - 1
      CDoom.startskill = CDoom::Skill.new(ARGV[p + 1][0] - '1')
      CDoom.autostart = 1
    end

    p = ARGV.index("-episode")
    if p && p < ARGV.size - 1
      CDoom.startepisode = ARGV[p + 1][0] - '0'
      CDoom.startmap = 1
      CDoom.autostart = 1
    end

    p = ARGV.index("-timer")
    if p && p < ARGV.size - 1 && CDoom.deathmatch != 0
      time = ARGV[p + 1].to_i
      puts "Levels will end after #{time} minute" + (time > 1 ? "s" : "") + "."
    end

    p = ARGV.index("-avg")
    if p && p < ARGV.size - 1 && CDoom.deathmatch != 0
      puts "Austin Virtual Gaming: Levels will end after 20 minutes"
    end

    p = ARGV.index("-warp")
    if p
      if p < ARGV.size - 1 && CDoom.gamemode == CDoom::GameMode::Commercial
        CDoom.startmap = ARGV[p + 1].to_i
      elsif p < ARGV.size - 2
        CDoom.startepisode = ARGV[p + 1][0] - '0'
        CDoom.startmap = ARGV[p + 2][0] - '0'
      end
      CDoom.autostart = 1
    end

    # Set mbs of memory to allocate
    ARGV.index("-mem").try do |p|
      if p = ARGV[p + 1]?
        CDoom.mb_used = p.to_u32
      end
    end

    i = 0
    ARGV.index("-deh").try do |p|
      ARGV[(p + 1)..].each do |a|
        break if a[0] == '-'
        @@dehackeds << a
      end
    end

    # init subsystems
    puts "v_init: Allocate screens."
    CDoom.v_init

    puts "m_load_defaults: Load system defaults."
    CDoom.m_load_defaults # load before initing other systems

    print "z_init: Init zone memory - "
    CDoom.z_init

    puts "w_init: Init Wadfiles."
    CDoom.w_init_multiple_files(CDoom.wadfiles)

    puts "        Init Mergefiles." if ARGV.includes?("-merge")
    w_merge_multiple_files(@@merge_files)

    if @@dehackeds.size > 0 || w_check_num_for_name("DEHACKED".to_unsafe) != -1
      puts "        Init DeHackEd."
      deh_init_dehacked
    end

    sync_deh_strings

    confirm_version()

    case CDoom.gamemode
    when CDoom::GameMode::Retail
      @@title = "The Ultimate DOOM Startup"
    when CDoom::GameMode::Shareware
      @@title = "DOOM Shareware Startup"
    when CDoom::GameMode::Registered
      @@title = "DOOM Registered Startup"
    when CDoom::GameMode::Commercial
      case CDoom.gamemission
      when CDoom::GameMission::PackPlut
        @@title = "Final Doom: The Plutonia Experiment"
      when CDoom::GameMission::PackTnt
        @@title = "Final Doom: TNT: Evilution"
      else
        @@title = "DOOM 2: Hell on Earth"
      end
    else
      @@title = "Public DOOM"
    end

    puts @@title.center(77)
    puts "".ljust(77, '=')
    puts "Doo-cr is licensed under the GNU General Public License v3.0 license".center(77)
    puts "Doo-cr comes with ABSOLUTELY NO WARRANTY".center(77)
    puts "Doo-cr is free software, and you are welcome to redistribute it".center(77)
    puts "".ljust(77, '=')

    # Check for -file in shareware
    if CDoom.modifiedgame != 0
      # These are the lumps that will be checked in IWAD,
      # if any one is not present, execution will be aborted.
      name = [
        "e2m1", "e2m2", "e2m3", "e2m4", "e2m5", "e2m6", "e2m7", "e2m8", "e2m9",
        "e3m1", "e3m3", "e3m3", "e3m4", "e3m5", "e3m6", "e3m7", "e3m8", "e3m9",
        "dphoof", "bfgga0", "heada1", "cybra1", "spida1d1",
      ]

      if CDoom.gamemode == CDoom::GameMode::Shareware
        CDoom.i_error("Error: \nYou cannot -file with the shareware version. Register!")
      end

      # Check for fake IWAD with right name,
      # but w/o all the lumps of the registered version.
      if CDoom.gamemode == CDoom::GameMode::Registered
        23.times do |i|
          if CDoom.w_check_num_for_name(name[i]) < 0
            CDoom.i_error("Error: \nThis is not the registered version.")
          end
        end
      end
    end

    puts "m_init: Init miscellaneous info."
    m_init

    print "r_init: Init DOO-CR refresh daemon - "
    CDoom.r_init

    puts "p_init: Init Playloop state."
    CDoom.p_init

    puts "i_init: Setting up machine state."
    CDoom.i_init

    puts "s_init: Setting up sound."
    CDoom.s_init(@@snd_sfx_volume, CDoom.snd_music_volume)

    puts "hu_init: Setting up heads up display."
    CDoom.hu_init

    puts "d_check_net_game: Checking network game status."
    CDoom.d_check_net_game

    puts "st_init: Init status bar."
    CDoom.st_init

    # check for a driver that wants intermission stats
    {% if false %}
      # [pd] Unsure how to test this
      p = ARGV.index("-statcopy")
      if p && p < ARGV.size - 1
        # for statistics driver
        CDoom.statcopy = String.new(ARGV[p + 1]).to_i64.as(Void*)
        puts "External statistics registered."
      end
    {% end %}

    # start the apropriate game based on parms
    p = ARGV.index("-record")

    if p && p < ARGV.size - 1
      CDoom.g_record_demo(ARGV[p + 1])
      CDoom.autostart = 1
    end

    demo_deferred = false
    p = ARGV.index("-playdemo")
    if p && p < ARGV.size - 1
      CDoom.singledemo = 1 # quit after one demo
      CDoom.g_defered_play_demo(ARGV[p + 1])
      CDoom.d_doom_loop # never returns
      demo_deferred = true
    end

    p = ARGV.index("-timedemo")
    if p && p < ARGV.size - 1
      CDoom.g_time_demo(ARGV[p + 1])
      CDoom.d_doom_loop # never returns
      demo_deferred = true
    end

    p = ARGV.index("-loadgame")
    if p && p < ARGV.size - 1
      file = @@deh_savegamename + ARGV[p + 1][0] + ".dsg"
      CDoom.g_load_game(file)
    end

    if CDoom.gameaction != CDoom::Gameaction::Loadgame && !demo_deferred
      if CDoom.autostart != 0 || CDoom.netgame != 0
        CDoom.g_init_new(CDoom.startskill, CDoom.startepisode, CDoom.startmap)
      else
        CDoom.d_start_title # start up intro loop
      end
    end

    CDoom.g_begin_recording if CDoom.demorecording != 0

    if ARGV.includes?("-debugfile")
      filename = "debug#{CDoom.consoleplayer}.txt"
      puts "debug output to: #{filename}"
      CDoom.debugfile = doom_open(filename.to_unsafe, "w".to_unsafe)
    end

    CDoom.d_doom_loop # never returns [ddos] Called by app
  end
end
