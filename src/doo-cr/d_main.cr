# Main General and Initialization Code

module Doocr
  MAXWADFILES =  20
  BGCOLOR     =   7
  FGCOLOR     =   8
  MAXARGS     = 100

  @@statcopy : String | Nil = nil

  def self.doom_main
    find_response_file()

    puts "Warning, too many command-line args: #{@@argv.size}" if @@argv.size > MAXARGS
    @@argv = @@argv[0...MAXARGS]

    identify_version()

    @@modifiedgame = false

    @@nomonsters = @@argv.any?("-nomonsters")
    @@respawnparm = @@argv.any?("-respawn")
    @@fastparm = @@argv.any?("-fast")
    @@devparm = @@argv.any?("-devparm")
    if @@argv.index("-altdeath")
      @@deathmatch = 2
    elsif @@argv.index("-deathmatch")
      @@deathmatch = 1
    end

    case @@gamemode
    when GameMode::Retail
      puts "The Ultimate DOOM Startup v#{D_VERSION/100}.#{D_VERSION % 100}"
    when GameMode::Shareware
      puts "DOOM Shareware Startup v#{D_VERSION/100}.#{D_VERSION % 100}"
    when GameMode::Registered
      puts "DOOM Registered Startup v#{D_VERSION/100}.#{D_VERSION % 100}"
    when GameMode::Commercial
      puts "DOOM 2: Hell on Earth v#{D_VERSION/100}.#{D_VERSION % 100}"
    else
      puts "Public DOOM - v#{D_VERSION/100}.#{D_VERSION % 100}"
    end

    puts D_DEVSTR if @@devparm

    if @@argv.index("-cdrom")
      puts D_CDROM
      Dir.mkdir("c:/doomdata")
      @@basedefault = "c:/doomdata/default.cfg"
    end

    if p = @@argv.index("-turbo")
      scale = 200
      forwardmove = Array.new(2, 0)
      sidemove = Array.new(2, 0)

      scale = @@argv[p + 1].to_i if p < @@argv.size - 1
      scale = 10 if scale < 10
      scale = 400 if scale > 400
      puts "turbo scale: #{scale}%"
      @@forwardmove[0] = @@forwardmove[0]*(scale/100).to_i32
      @@forwardmove[1] = @@forwardmove[1]*(scale/100).to_i32
      @@sidemove[0] = @@sidemove[0]*(scale/100).to_i32
      @@sidemove[1] = @@sidemove[1]*(scale/100).to_i32
    end

    # add any files specified on the command line with -file wadfile
    # to the wad list
    #
    # convenience hack to allow -wart e m to add a wad file
    # prepend a tilde to the filename so wadfile will be reloadable
    p = @@argv.index("-wart")
    if p
      @@argv[p] = @@argv[p][..3] + "p" + @@argv[p][5..] # big hack, change to -warp
      file = ""
      # Map name handling
      case @@gamemode
      when GameMode::Shareware, GameMode::Retail, GameMode::Registered
        file = "./" + DEVMAPS + "E#{@@argv[p + 1][0]}M#{@@argv[p + 2][0]}"
        puts file
        puts "Warping to Episode #{@@argv[p + 1]}, Map #{@@argv[p + 2]}."
      else
        p = @@argv[p + 1].to_i32
        if p < 10
          file = "./" + DEVMAPS + "cdata/map0#{p}.wad"
          puts file
        else
          file = "./" + DEVMAPS + "cdata/map#{p}.wad"
          puts file
        end
      end
      @@wadfiles << file
    end

    p = @@argv.index("-file")
    if p
      # the parms after p are wadfile/lump names,
      # until end of parms or another - preceded parm
      @@modifiedgame = true # homebrew levels

      while (p + 1 != @@argv.size - 1 && @@argv[p][0] != '-')
        p += 1
        @@wadfiles << @@argv[p]
      end
    end

    p = @@argv.index("-playdemo")
    p = @@argv.index("-timedemo") if !p

    if (p && p < @@argv.size - 1)
      file = "#{@@argv[p + 1]}.lmp"
      puts file
      @@wadfiles << file
      puts "Playing demo #{@@argv[p + 1]}.lmp."
    end

    # get skill / episode / map from params
    @@start_skill = Skill::Medium
    @@start_episode = 1
    @@start_map = 1
    @@autostart = false

    p = @@argv.index("-skill")
    if (p && p < @@argv.size - 1)
      @@start_skill = Skill.new(@@argv[p + 1][0].to_i)
      @@autostart = true
    end

    p = @@argv.index("-episode")
    if (p && p < @@argv.size - 1)
      @@start_episode = @@argv[p + 1][0].to_i32
      @@start_map = 1
      @@autostart = true
    end

    p = @@argv.index("-timer")
    if (p && p < @@argv.size - 1 && @@deathmatch > 0)
      time = @@argv[p + 1].to_i
      print "Levels will end after #{time} minute"
      print "s" if time > 1
      puts "."
    end

    p = @@argv.index("-avg")
    if (p && p < @@argv.size - 1 && @@deathmatch > 0)
      puts "Austin Virtual Gaming: Levels will end after 20 minutes"
    end

    p = @@argv.index("-warp")
    if (p && p < @@argv.size - 1)
      if @@gamemode == GameMode::Commercial
        @@start_map = @@argv[p + 1].to_i32
      else
        @@start_episode = @@argv[p + 1][0].to_i32
        @@start_map = @@argv[p + 2][0].to_i32
      end
      @@autostart = true
    end

    # Init subsystems
    puts "v_init: Start Raylib."
    v_init()

    puts "Load system defaults."
    @@config = DEFAULTCONFIG

    puts "init_multiple_files: Init WAD and Lump files"
    init_multiple_files(@@wadfiles)

    # Check for -file in shareware
    if @@modifiedgame
      name = [
        "e2m1", "e2m2", "e2m3", "e2m4", "e2m5", "e2m6", "e2m7", "e2m8", "e2m9",
        "e3m1", "e3m3", "e3m3", "e3m4", "e3m5", "e3m6", "e3m7", "e3m8", "e3m9",
        "dphoof", "bfgga0", "heada1", "cybra1", "spida1d1",
      ]

      if @@gamemode == GameMode::Shareware
        raise "You cannot -file with the shareware version. Register!"
      end

      # Check for fake IWAD with right name
      # but w/o all the lumps of the registered version
      if @@gamemode == GameMode::Registered
        name.each do |n|
          raise "This is not the registered version." if !@@lumps.keys.any?(n)
        end
      end
    end

    # If additional PWAD files are used, print modified banner
    if @@modifiedgame
      "===========================================================================\n" \
      "ATTENTION:  This version of DOOM has been modified.  If you would like to\n" \
      "get a copy of the original game, call 1-800-IDGAMES or see the readme file.\n" \
      "        You will not receive technical support for modified games.\n" \
      "                      press enter to continue\n" \
      "===========================================================================\n"
      gets
    end

    # Check and print which version is executed
    case @@gamemode
    when GameMode::Shareware, GameMode::Indetermined
      puts "===========================================================================\n" \
           "                                Shareware!\n" \
           "===========================================================================\n"
    when GameMode::Registered, GameMode::Retail, GameMode::Commercial
      puts "===========================================================================\n" \
           "                 Commercial product - do not distribute!\n" \
           "         Please report software piracy to the SPA: 1-800-388-PIR8\n" \
           "===========================================================================\n"
    else
      # Ouch.
    end

    puts "m_init: Init menu."
    m_init()

    print "r_init: Init DOOM refresh daemon - "
    r_init()

    puts "\np_init: Init Playloop state."
    p_init()

    puts "i_init: Setting up machine state."
    i_init()

    puts "d_check_net_game: Checking network game status."
    d_check_net_game()

    puts "s_init: Setting up sound."
    s_init(@@config["sfx_volume"].as(Int32), @@config["music_volume"].as(Int32))

    puts "hu_init: Setting up heads up display."
    hu_init()

    puts "st_init: Init status bar."
    st_init()

    # check for a driver that wants intermission stats
    p = @@argv.index("-statcopy")
    if (p && p < @@argv.size - 1)
      @@statcopy = @@argv[p + 1]
      puts "External statistics registered."
    end

    # start the apropriate game based on parms
    p = @@argv.index("-record")
    if (p && p < @@argv.size - 1)
      g_record_demo(@@argv[p + 1])
      @@autostart
    end

    p = @@argv.index("-playdemo")
    if (p && p < @@argv.size - 1)
      @@singledemo = true
      g_defered_play_demo(@@argv[p + 1])
      d_doomloop()
    end

    p = @@argv.index("-timedemo")
    if (p && p < @@argv.size - 1)
      g_timedemo(@@argv[p + 1])
      d_doomloop()
    end

    p = @@argv.index("-loadgame")
    if (p && p < @@argv.size - 1)
      file = ""
      if @@argv.index("-cdrom")
        file = "c:/doomdata/#{SAVEGAMENAME}#{@@argv[p + 1][0]}.dsg"
      else
        file = "#{SAVEGAMENAME}#{@@argv[p + 1][0]}.dsg"
      end
      g_loadgame(file)
    end

    if @@gameaction != GameAction::Loadgame
      if @@autostart || @@netgame
        g_initnew(@@start_skill, @@start_episode, @@start_map)
      else
        d_starttitle() # start up intro loop
      end
    end

    d_doomloop() # never returns
  end

  # Finds a response file and loads it in
  def self.find_response_file
    @@argv.each do |arg|
      if arg[0] == '!'
        raise "No such response file!" if !File.exists?(arg[1..])
        handle = File.open(arg[1..], "rb")
        puts "Found response file #{arg[1..]}!"
        handle.each_line do |line|
          @@argv << line
        end
        handle.close

        # Display Args
        puts "#{@@argv.size} command-line args:"
        @@argv.each do |arg|
          puts arg
        end
      end
    end
  end

  # Checks availability of IWAD files by name,
  # to determine whether registered/commercial features
  # should be executed (notably loading PWAD's).
  def self.identify_version
    if @@argv.index("-shdev")
      @@gamemode = GameMode::Shareware
      @@devparm = true
      @@wadfiles << (DEVDATA + "doom1.wad")
      @@wadfiles << (DEVMAPS + "data_se/texture1.lmp")
      @@wadfiles << (DEVMAPS + "data_se/pnames.lmp")
      @@basedefault = (DEVDATA + "default.cfg")
      return
    end

    if @@argv.index("-regdev")
      @@gamemode = GameMode::Registered
      @@devparm = true
      @@wadfiles << (DEVDATA + "doom1.wad")
      @@wadfiles << (DEVMAPS + "data_se/texture1.lmp")
      @@wadfiles << (DEVMAPS + "data_se/texture2.lmp")
      @@wadfiles << (DEVMAPS + "data_se/pnames.lmp")
      @@basedefault = (DEVDATA + "default.cfg")
      return
    end

    if @@argv.index("-comdev")
      @@gamemode = GameMode::Commercial
      @@devparm = true
      @@wadfiles << (DEVDATA + "doom2.wad")
      @@wadfiles << (DEVMAPS + "data_se/texture1.lmp")
      @@wadfiles << (DEVMAPS + "data_se/pnames.lmp")
      @@basedefault = (DEVDATA + "default.cfg")
      return
    end

    if File.readable?("./doom2f.wad")
      @@gamemode = GameMode::Commercial
      # C'est ridicule!
      # Let's handle languages in config files, okay?
      @@language = Language::French
      puts "French version"
      @@wadfiles << "./doom2f.wad"
      return
    end

    if File.readable?("./doom2.wad")
      @@gamemode = GameMode::Commercial
      @@wadfiles << "./doom2.wad"
      return
    end

    if File.readable?("./plutonia.wad")
      @@gamemode = GameMode::Commercial
      @@wadfiles << "./plutonia.wad"
      return
    end

    if File.readable?("./tnt.wad")
      @@gamemode = GameMode::Commercial
      @@wadfiles << "./tnt.wad"
      return
    end

    if File.readable?("./doomu.wad")
      @@gamemode = GameMode::Retail
      @@wadfiles << "./doomu.wad"
      return
    end

    if File.readable?("./doom.wad")
      @@gamemode = GameMode::Registered
      @@wadfiles << "./doom.wad"
      return
    end

    if File.readable?("./doom1.wad")
      @@gamemode = GameMode::Commercial
      @@wadfiles << "./doom1.wad"
      return
    end

    puts "Game mode indeterminate."
    @@gamemode = GameMode::Indetermined

    # We don't abort. Let's see what the PWAD contains.
    # raise "Game mode indeterminate"
  end
end
