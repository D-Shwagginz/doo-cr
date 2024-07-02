# Menu Code
module Doocr
  SAVESTRINGSIZE = 24

  SKULLXOFF  = -32
  LINEHEIGHT =  16

  @@detail_names : Array(String) = ["M_GDHIGH", "M_GDLOW"]
  @@msg_names : Array(String) = ["M_MSGOFF", "M_MSGON"]

  @@message_last_menu_active : Int32 = 0
  @@menuactive : Bool = false

  # 1 = message to be printed
  @@message_to_print : Int32 = 0
  # ...and here is the message string!
  @@message_string : String = ""

  # timed message = no input from user
  @@message_needs_input : Bool = false

  @@message_routine : Proc(Int32, Nil) = Proc(Int32, Nil).new { |x| nil }

  @@itemon : Int16 = 0             # menu item skull is on
  @@skull_anim_counter : Int16 = 0 # skull animation counter
  @@which_skull : Int16 = 0        # which skull to draw

  # temp for screenblocks (0-9)
  @@screen_size : Int32 = 0

  # -1 = no quicksave slot picked!
  @@quick_save_slot : Int32 = 0

  # Episode
  @@epi : Int32 = 0

  @@message_dontfuckwithme : Bool = false

  # we are going to be entering a savegame string
  @@save_string_enter : Int32 = 0
  @@save_slot : Int32 = 0       # which slot to save in
  @@save_char_index : Int32 = 0 # which char we're editing
  # old save description before edit
  @@save_old_string : String = ""

  @@savegamestrings : Array(String) = Array.new(10, "")

  @@quitsounds : Array(Int32) = [
    SFX::Pldeth.value,
    SFX::Dmpain.value,
    SFX::Popain.value,
    SFX::Slop.value,
    SFX::Telept.value,
    SFX::Posit1.value,
    SFX::Posit3.value,
    SFX::Sgtatk.value,
  ]

  @@quitsounds2 : Array(Int32) = [
    SFX::Vilact.value,
    SFX::Getpow.value,
    SFX::Boscub.value,
    SFX::Slop.value,
    SFX::Skeswg.value,
    SFX::Kntdth.value,
    SFX::Bspact.value,
    SFX::Sgtatk.value,
  ]

  struct MenuItem
    # 0 = no cursor here, 1 = ok, 2 = arrows ok
    property status : Int16

    property name : String

    # choice = menu item #
    #  if status = 2
    #       choice = 0:leftarrow, 1:rightarrow
    property routine : Proc(Int32, Nil)

    # hotkey in menu
    property alpha_key : Char | Nil

    def initialize(@status, @name, @routine, @alpha_key)
    end
  end

  class Menu
    property num_items : Int16
    property prev_menu : Menu | Nil
    property menu_items : Array(MenuItem)
    property routine : Proc(Nil)
    property x : Int16
    property y : Int16
    property last_on : Int16

    def initialize(@num_items, @prev_menu, @menu_items, @routine, @x, @y, @last_on)
    end
  end

  # Doom Menu
  enum Main
    NewGame  = 0
    Options
    LoadGame
    SaveGame
    ReadThis
    QuitDoom
    MainEnd
  end

  @@main_menu : Array(MenuItem) = [
    MenuItem.new(1, "M_NGAME", ->m_new_game(Int32), 'n'),
    MenuItem.new(1, "M_OPTION", ->m_options(Int32), 'o'),
    MenuItem.new(1, "M_LOADG", ->m_load_game(Int32), 'l'),
    MenuItem.new(1, "M_SAVEG", ->m_save_game(Int32), 's'),
    # Another hickup with Special edition.
    MenuItem.new(1, "M_RDTHIS", ->m_read_this(Int32), 'r'),
    MenuItem.new(1, "M_QUITG", ->m_quit_doom(Int32), 'q'),
  ]

  @@main_def : Menu = Menu.new(
    Main::MainEnd.value.to_i16,
    nil,
    @@main_menu,
    ->m_draw_main_menu,
    97_i16, 64_i16,
    0_i16
  )

  # Episode select
  enum Episodes
    Ep1
    Ep2
    Ep3
    Ep4
    EpEnd
  end

  @@episode_menu : Array(MenuItem) = [
    MenuItem.new(1, "M_EPI1", ->m_episode(Int32), 'k'),
    MenuItem.new(1, "M_EPI2", ->m_episode(Int32), 't'),
    MenuItem.new(1, "M_EPI3", ->m_episode(Int32), 'i'),
    MenuItem.new(1, "M_EPI4", ->m_episode(Int32), 't'),
  ]

  @@epi_def : Menu = Menu.new(
    Episodes::EpEnd.value.to_i16,
    @@main_def,
    @@episode_menu,
    ->m_draw_episode,
    48_i16, 63_i16,
    Episodes::Ep1.value.to_i16
  )

  enum NewGame
    KillThings
    TooRough
    HurtMe
    Violence
    Nightmare
    NewGEnd
  end

  @@new_game_menu : Array(MenuItem) = [
    MenuItem.new(1, "M_JKILL", ->m_choose_skill(Int32), 'i'),
    MenuItem.new(1, "M_ROUGH", ->m_choose_skill(Int32), 'h'),
    MenuItem.new(1, "M_HURT", ->m_choose_skill(Int32), 'h'),
    MenuItem.new(1, "M_ULTRA", ->m_choose_skill(Int32), 'u'),
    MenuItem.new(1, "M_NMARE", ->m_choose_skill(Int32), 'n'),
  ]

  @@new_def : Menu = Menu.new(
    NewGame::NewGEnd.value.to_i16,
    @@epi_def,
    @@new_game_menu,
    ->m_draw_new_game,
    48_i16, 63_i16,
    NewGame::HurtMe.value.to_i16
  )

  enum Options
    EndGame
    Messages
    Detail
    Scrnsize
    OptionEmpty1
    Mousesens
    OptionEmpty2
    Soundvol
    OptEnd
  end

  @@options_menu : Array(MenuItem) = [
    MenuItem.new(1, "M_ENDGAM", ->m_end_game(Int32), 'e'),
    MenuItem.new(1, "M_MESSG", ->m_change_messages(Int32), 'm'),
    MenuItem.new(1, "M_DETAIL", ->m_change_detail(Int32), 'g'),
    MenuItem.new(2, "M_SCRNSZ", ->m_size_display(Int32), 's'),
    MenuItem.new(-1, "", Proc(Int32, Nil).new { |x| nil }, nil),
    MenuItem.new(2, "M_MSENS", ->m_change_sensitivity(Int32), 'm'),
    MenuItem.new(-1, "", Proc(Int32, Nil).new { |x| nil }, nil),
    MenuItem.new(1, "M_SVOL", ->m_sound(Int32), 's'),
  ]

  @@options_def : Menu = Menu.new(
    Options::OptEnd.value.to_i16,
    @@main_def,
    @@options_menu,
    ->m_draw_options,
    60_i16, 37_i16,
    0_i16
  )

  # Read This! MENU 1 & 2

  enum Read
    RdThsEmpty1
    Read1End
  end

  @@read_menu_1 : Array(MenuItem) = [
    MenuItem.new(1, "", ->m_read_this_2(Int32), nil),
  ]

  @@read_def_1 : Menu = Menu.new(
    Read::Read1End.value.to_i16,
    @@main_def,
    @@read_menu_1,
    ->m_draw_read_this_1,
    280_i16, 185_i16,
    0_i16
  )

  enum Read2
    RdThsEmpty2
    Read2End
  end

  @@read_menu_2 : Array(MenuItem) = [
    MenuItem.new(1, "", ->m_finish_read_this(Int32), nil),
  ]

  @@read_def_2 : Menu = Menu.new(
    Read2::Read2End.value.to_i16,
    @@read_def_1,
    @@read_menu_2,
    ->m_draw_read_this_2,
    330_i16, 175_i16,
    0_i16
  )

  # Sound Volume Menu

  enum Sound
    SfxVol
    SfxEmpty1
    MusicVol
    SfxEmpty2
    SoundEnd
  end

  @@sound_menu : Array(MenuItem) = [
    MenuItem.new(2, "M_SFXVOL", ->m_sfx_vol(Int32), 's'),
    MenuItem.new(-1, "", Proc(Int32, Nil).new { |x| nil }, nil),
    MenuItem.new(2, "M_MUSVOL", ->m_music_vol(Int32), 'm'),
    MenuItem.new(-1, "", Proc(Int32, Nil).new { |x| nil }, nil),
  ]

  @@sound_def : Menu = Menu.new(
    Sound::SoundEnd.value.to_i16,
    @@options_def,
    @@sound_menu,
    ->m_draw_sound,
    80_i16, 64_i16,
    0_i16
  )

  # Load Game Menu

  enum Load
    Load1
    Load2
    Load3
    Load4
    Load5
    Load6
    LoadEnd
  end

  @@load_menu : Array(MenuItem) = [
    MenuItem.new(1, "", ->m_load_select(Int32), '1'),
    MenuItem.new(1, "", ->m_load_select(Int32), '2'),
    MenuItem.new(1, "", ->m_load_select(Int32), '3'),
    MenuItem.new(1, "", ->m_load_select(Int32), '4'),
    MenuItem.new(1, "", ->m_load_select(Int32), '5'),
    MenuItem.new(1, "", ->m_load_select(Int32), '6'),
  ]

  @@load_def : Menu = Menu.new(
    Load::LoadEnd.value.to_i16,
    @@main_def,
    @@load_menu,
    ->m_draw_load,
    80_i16, 54_i16,
    0_i16
  )

  # Save Game Menu

  @@save_menu : Array(MenuItem) = [
    MenuItem.new(1, "", ->m_save_select(Int32), '1'),
    MenuItem.new(1, "", ->m_save_select(Int32), '2'),
    MenuItem.new(1, "", ->m_save_select(Int32), '3'),
    MenuItem.new(1, "", ->m_save_select(Int32), '4'),
    MenuItem.new(1, "", ->m_save_select(Int32), '5'),
    MenuItem.new(1, "", ->m_save_select(Int32), '6'),
  ]

  @@save_def : Menu = Menu.new(
    Load::LoadEnd.value.to_i16,
    @@main_def,
    @@save_menu,
    ->m_draw_save,
    80_i16, 54_i16,
    0_i16
  )

  @@current_menu : Menu = @@main_def

  def self.m_init
    @@current_menu = @@main_def
    @@menuactive = false
    @@itemon = @@current_menu.last_on
    @@which_skull = 0
    @@skull_anim_counter = 10
    @@screen_size = @@config["screenblocks"].as(Int32) - 3
    @@message_to_print = 0
    @@message_string = ""
    @@message_last_menu_active = @@menuactive.to_unsafe
    @@quick_save_slot = -1

    # Here we could catch other version dependencies,
    #  like HELP1/2, and four episodes

    case @@gamemode
    when GameMode::Commercial
      # This is used because DOOM 2 had only one HELP
      #  page. I use CREDIT as second page now, but
      #  kept this hack for educational purposes.
      @@main_menu[Main::ReadThis.value] = @@main_menu[Main::QuitDoom.value]
      @@main_def.num_items -= 1
      @@main_def.y += 8
      @@new_def.prev_menu = @@main_def
      @@read_def_1.routine = ->m_draw_read_this_1
      @@read_def_1.x = 330
      @@read_def_1.y = 165
      @@read_menu_1[0].routine = ->m_finish_read_this(Int32)
    when GameMode::Shareware
      # Episode 2 and 3 are handled,
      #  branching to an ad screen.
    when GameMode::Registered
      @@epi_def.num_items -= 1
    when GameMode::Retail
      # We are fine.
    end
  end

  # --- Menu Options --- #

  def self.m_new_game(choice : Int32)
    if @@netgame && !@@demoplayback
      m_start_message(NEWGAME, Proc(Int32, Nil).new { |x| nil }, false)
      return nil
    end

    if @@gamemode == GameMode::Commercial
      m_setup_next_menu(@@new_def)
    else
      m_setup_next_menu(@@epi_def)
    end

    return nil
  end

  def self.m_episode(choice : Int32)
    if @@gamemode == GameMode::Shareware && choice > 0
      m_start_message(SWSTRING, Proc(Int32, Nil).new { |x| nil }, false)
      m_setup_next_menu(@@read_def_1)
      return nil
    end

    # Yet another hack...
    if @@gamemode == GameMode::Registered && choice > 2
      puts "episode: 4th episode requires UltimateDOOM"
      choice = 0
    end

    @@epi = choice
    m_setup_next_menu(@@new_def)
    return nil
  end

  def self.m_verify_nightmare(ch : Int32)
    return nil if ch != 'y'.to_i
    # g_defered_init_new(NewGame::Nightmare, @@epi + 1, 1)
    m_clear_menus()

    return nil
  end

  def self.m_choose_skill(choice : Int32)
    if choice == NewGame::Nightmare
      m_start_message(NIGHTMARE, ->m_verify_nightmare(Int32), true)
      return nil
    end

    # g_defered_init_new(choice, @@epi + 1, 1)
    m_clear_menus()
    return nil
  end

  def self.m_load_game(choice : Int32)
    if @@netgame
      m_start_message(LOADNET, Proc(Int32, Nil).new { |x| nil }, false)
      return nil
    end

    m_setup_next_menu(@@load_def)
    m_read_save_strings()
    return nil
  end

  def self.m_save_game(choice : Int32)
    if !@@usergame
      m_start_message(SAVEDEAD, Proc(Int32, Nil).new { |x| nil }, false)
      return nil
    end

    return nil if @@gamestate != Gamestate::Level

    m_setup_next_menu(@@save_def)
    m_read_save_strings()
    return nil
  end

  def self.m_options(choice : Int32)
    m_setup_next_menu(@@options_def)
  end

  def self.m_end_game_response(ch : Int32)
    return nil if ch != 'y'.to_i

    @@current_menu.last_on = @@itemon
    m_clear_menus()
    # d_start_title()

    return nil
  end

  def self.m_end_game(choice : Int32)
    choice = 0
    if !@@usergame
      # s_start_sound(nil, SFX::Oof)
      return nil
    end

    if @@netgame
      m_start_message(NETEND, Proc(Int32, Nil).new { |x| nil }, true)
      return nil
    end

    m_start_message(ENDGAME, ->m_end_game_response(Int32), true)
    return nil
  end

  def self.m_read_this(choice : Int32)
    choice = 0
    m_setup_next_menu(@@read_def_1)
    return nil
  end

  def self.m_read_this_2(choice : Int32)
    choice = 0
    m_setup_next_menu(@@read_def_2)
    return nil
  end

  def self.m_quit_response(ch : Int32)
    return nil if ch != 'y'.to_i

    if !@@netgame
      if @@gamemode == GameMode::Commercial
        # s_start_sound(nil, @@quitsounds2[(@@gametic >> 2) & 7])
      else
        # s_start_sound(nil, @@quitsounds[(@@gametic >> 2) & 2])
      end
      # i_wait_vbl(105)
    end
    # i_quit()

    return nil
  end

  def self.m_quit_doom(choice : Int32)
    # We pick index 0 which is language sensitive,
    #  or one at random, between 1 and maximum number.
    if @@language == Language::English
      endstring = "#{@@endmsg[0]}\n\n#{DOSY}"
    else
      endstring = "#{@@endmsg[(@@gametic % (NUM_QUITMESSAGES - 2)) + 1]}"
    end

    m_start_message(endstring, ->m_quit_response(Int32), true)
    return nil
  end

  # --- Menu Settings --- #

  def self.m_change_messages(choice : Int32)
    # warning: unused parameter 'choice'
    choice = 0
    @@config["show_messages"] = 1 - @@config["show_messages"].as(Int32)

    if @@config["show_messages"].as(Int32) > 0
      # @@players[@@console_player].message = MSGOFF
    else
      # @@players[@@console_player].message = MSGON
    end

    @@message_dontfuckwithme = true
  end

  def self.m_change_sensitivity(choice : Int32)
    case choice
    when 0
      if @@config["mouse_sensitivity"].as(Int32) > 0
        @@config["mouse_sensitivity"] = @@config["mouse_sensitivity"].as(Int32) - 1
      end
    when 1
      if @@config["mouse_sensitivity"].as(Int32) < 9
        @@config["mouse_sensitivity"] = @@config["mouse_sensitivity"].as(Int32) + 1
      end
    end
    return nil
  end

  def self.m_sfx_vol(choice : Int32)
    case choice
    when 0
      if @@config["sfx_volume"].as(Int32) > 0
        @@config["sfx_volume"] = @@config["sfx_volume"].as(Int32) - 1
      end
    when 1
      if @@config["sfx_volume"].as(Int32) < 15
        @@config["sfx_volume"] = @@config["sfx_volume"].as(Int32) + 1
      end
    end

    # s_set_sfx_volume(@@config["sfx_volume"]) # *8 )
    return nil
  end

  def self.m_music_vol(choice : Int32)
    case choice
    when 0
      if @@config["music_volume"].as(Int32) > 0
        @@config["music_volume"] = @@config["music_volume"].as(Int32) - 1
      end
    when 1
      if @@config["music_volume"].as(Int32) < 15
        @@config["music_volume"] = @@config["music_volume"].as(Int32) + 1
      end
    end

    # s_set_music_volume(@@config["music_volume"]) # *8 )
    return nil
  end

  def self.m_change_detail(choice : Int32)
    choice = 0
    @@config["detaillevel"] = 1 - @@config["detaillevel"].as(Int32)

    puts "change_detail: low detail mode #{@@config["detaillevel"]}"

    return nil

    # set_view_size(@@config["screenblocks"], @@config["detaillevel"])
    #
    # if @@config["detaillevel"] == 0
    #   @@players[@@console_player].message = DETAILHI
    # else
    #   @@players[@@console_player].message = DETAILLO
    # end
  end

  def self.m_size_display(choice : Int32)
    case choice
    when 0
      if @@screen_size > 0
        @@config["screenblocks"] = @@config["screenblocks"].as(Int32) - 1
        @@screen_size -= 1
      end
    when 1
      if @@screen_size < 8
        @@config["screenblocks"] = @@config["screenblocks"].as(Int32) + 1
        @@screen_size += 1
      end
    end

    return nil
  end

  def self.m_sound(choice : Int32)
    m_setup_next_menu(@@sound_def)
    return nil
  end

  # --- Menu Selects --- #

  def self.m_finish_read_this(choice : Int32)
    choice = 0
    m_setup_next_menu(@@main_def)

    return nil
  end

  def self.m_load_select(choice : Int32)
    if @@argv.index("-cdrom")
      name = "c:/doomdata/#{SAVEGAMENAME}#{choice}.dsg"
    else
      name = "./#{SAVEGAMENAME}#{choice}.dsg"
    end

    # g_load_game(name)
    m_clear_menus()

    return nil
  end

  def self.m_save_select(choice : Int32)
    # we are going to be intercepting all chars
    @@save_string_enter = 1

    @@save_slot = choice
    @@save_old_string = @@savegamestrings[choice]
    if @@savegamestrings[choice] == EMPTYSTRING
      @@savegamestrings[choice] = ""
    end

    @@save_char_index = choice

    return nil
  end

  def self.m_read_save_strings
    (Load::LoadEnd.value).times do |i|
      if @@argv.index("-cdrom")
        name = "c:/doomdata/#{SAVEGAMENAME}#{i}.dsg"
      else
        name = "./#{SAVEGAMENAME}#{i}.dsg"
      end

      if !File.exists?(name) || !File.readable?(name)
        @@savegamestrings[i] = EMPTYSTRING
        @@load_menu[i].status = 0
        next
      else
        handle = File.read(name)
        count = handle[0..SAVESTRINGSIZE]
        @@load_menu[i].status = 1
      end
    end

    return nil
  end

  def self.m_quick_save_response(ch : Int32)
    if ch = 'y'.to_i
      m_do_save(@@quick_save_slot)
      # s_start_sound(nil, SFX::Swtchx)
    end
    return nil
  end

  def self.m_quick_save
    if !@@usergame
      # s_start_sound(nil, SFX::Oof)
      return nil
    end

    return nil if @@gamestate != Gamestate::Level

    if @@quick_save_slot < 0
      m_start_control_panel()
      m_read_save_strings()
      m_setup_next_menu(@@save_def)
      @@quick_save_slot = -2 # means to pick a slot now
      return nil
    end
    tempstring = QSPROMPT.gsub("%s", @@savegamestrings[@@quick_save_slot])
    m_start_message(tempstring, m_quick_save_response, true)

    return nil
  end

  def self.m_quick_load_response(ch : Int32)
    if ch = 'y'.to_i
      m_load_select(@@quick_save_slot)
      # s_start_sound(nil, SFX::Swtchx)
    end
    return nil
  end

  def self.m_quick_load
    if @@netgame
      m_start_message(QLOADNET, Proc(Int32, Nil).new { |x| nil }, false)
      return nil
    end

    if @@quick_save_slot < 0
      m_start_message(QSAVESPOT, Proc(Int32, Nil).new { |x| nil }, false)
      return nil
    end
    tempstring = QLPROMPT.gsub("%s", @@savegamestrings[@@quick_save_slot])
    m_start_message(tempstring, m_quick_load_response, true)

    return nil
  end

  # --- Menu Draw --- #

  def self.m_draw_main_menu
    v_draw_patch_direct(94, 2, "M_DOOM")

    return nil
  end

  def self.m_draw_read_this_1
    @@inhelpscreens = true
    case @@gamemode
    when GameMode::Commercial
      v_draw_patch_direct(0, 0, "HELP")
    when GameMode::Shareware, GameMode::Registered, GameMode::Retail
      v_draw_patch_direct(0, 0, "HELP1")
    end

    return nil
  end

  def self.m_draw_read_this_2
    @@inhelpscreens = true
    case @@gamemode
    when GameMode::Retail, GameMode::Commercial
      # This hack keeps us from having to change menus.
      v_draw_patch_direct(0, 0, "CREDIT")
    when GameMode::Shareware, GameMode::Registered
      v_draw_patch_direct(0, 0, "HELP2")
    end

    return nil
  end

  def self.m_draw_new_game
    v_draw_patch_direct(94, 14, "M_NEWG")
    v_draw_patch_direct(54, 38, "M_SKILL")

    return nil
  end

  def self.m_draw_episode
    v_draw_patch_direct(54, 38, "M_EPISOD")

    return nil
  end

  def self.m_draw_options
    v_draw_patch_direct(108, 15, "M_OPTTTL")

    v_draw_patch_direct(@@options_def.x + 175, @@options_def.y + LINEHEIGHT*Options::Detail.value,
      @@detail_names[@@config["detaillevel"].as(Int32)])

    v_draw_patch_direct(@@options_def.x + 120, @@options_def.y + LINEHEIGHT*Options::Messages.value,
      @@msg_names[@@config["show_messages"].as(Int32)])

    m_draw_thermo(@@options_def.x, @@options_def.y + LINEHEIGHT*(Options::Mousesens.value + 1),
      10, @@config["mouse_sensitivity"].as(Int32))

    m_draw_thermo(@@options_def.x, @@options_def.y + LINEHEIGHT*(Options::Scrnsize.value + 1),
      10, @@screen_size)

    return nil
  end

  def self.m_draw_sound
    v_draw_patch_direct(60, 38, "M_SVOL")

    m_draw_thermo(@@sound_def.x, @@sound_def.y + LINEHEIGHT*(Sound::SfxVol.value + 1),
      16, @@config["sfx_volume"].to_i32)

    m_draw_thermo(@@sound_def.x, @@sound_def.y + LINEHEIGHT*(Sound::MusicVol.value + 1),
      16, @@config["music_volume"].to_i32)

    return nil
  end

  def self.m_draw_load
    v_draw_patch_direct(72, 28, "M_LOADG")
    Load::LoadEnd.value.times do |i|
      m_draw_save_load_border(@@load_def.x, @@load_def.y + LINEHEIGHT*i)
      m_write_text(@@load_def.x, @@load_def.y + LINEHEIGHT*i, @@savegamestrings[i])
    end

    return nil
  end

  def self.m_draw_save
    v_draw_patch_direct(72, 28, "M_SAVEG")
    Load::LoadEnd.value.times do |i|
      m_draw_save_load_border(@@load_def.x, @@load_def.y + LINEHEIGHT*i)
      m_write_text(@@load_def.x, @@load_def.y + LINEHEIGHT*i, @@savegamestrings[i])
    end

    if @@save_string_enter
      i = m_string_width(@@savegamestrings[@@save_slot])
      m_write_text(@@load_def.x + i, @@load_def.y + LINEHEIGHT*@@save_slot, "_")
    end

    return nil
  end

  # --- Menu Funcs --- #

  def self.m_draw_save_load_border(x : Int32, y : Int32)
    v_draw_patch_direct(x - 8, y + 7, "M_LSLEFT")

    25.times do |i|
      v_draw_patch_direct(x, y + 7, "M_LSCNTR")
      x += 8
    end

    v_draw_patch_direct(x, y + 7, "M_LSRGHT")

    return nil
  end

  def self.m_setup_next_menu(menudef : Menu)
    @@current_menu = menudef
    @@itemon = @@current_menu.last_on
  end

  def self.m_draw_thermo(
    x : Int,
    y : Int,
    therm_width : Int,
    therm_dot : Int
  )
    xx = x
    v_draw_patch_direct(xx, y, "M_THERML")
    xx += 8
    therm_width.times do |i|
      v_draw_patch_direct(xx, y, "M_THERMM")
      xx += 8
    end
    v_draw_patch_direct(xx, y, "M_THERMR")

    v_draw_patch_direct((x + 8) + therm_dot*8, y, "M_THERMO")

    return nil
  end

  def self.m_draw_empty_cell(menu : Menu, item : Int32)
    v_draw_patch_direct(menu.x - 10, menu.y + item*LINEHEIGHT - 1, "M_CELL1")
    return nil
  end

  def self.m_draw_sel_cell(menu : Menu, item : Int32)
    v_draw_patch_direct(menu.x - 10, menu.y + item*LINEHEIGHT - 1, "M_CELL2")
    return nil
  end

  def self.m_write_text(x : Int32, y : Int32, string : String)
    cx = x
    cy = y

    string.each_char do |c|
      if c == '\n'
        cx = x
        cy += 12
        next
      end

      c = c.upcase - HU_FONTSTART
      if c.to_i < 0 || c >= HU_FONTSIZE
        cx += 4
        next
      end

      w = swap_short(@@hu_font[c.to_i].width.to_u16)
      break if cx + w > SCREENWIDTH
      v_draw_patch_direct(cx, cy, @@hu_font[c.to_i])
      cx += w
    end

    return nil
  end

  def self.m_string_width(string : String)
    w = 0

    string.size.times do |i|
      c = string[i].upcase - HU_FONTSTART
      if c < 0 || c >= HU_FONTSIZE
        w += 4
      else
        w += swap_short(@@hu_font[c.to_i].width.to_u16)
      end
    end

    return w
  end

  def self.m_string_height(string : String)
    height = swap_short(@@hu_font[0].height.to_u16)

    h = height
    string.times do |i|
      if string[i] == '\n'
        h += height
      end
    end

    return h
  end

  def self.m_start_control_panel
    # intro might call this repeatedly
    return nil if @@menuactive

    @@menuactive = 1
    @@current_menu = @@main_def
    @@itemon = @@current_menu.last_on

    return nil
  end

  def self.m_start_message(string : String, routine : Proc(Int32, Nil), input : Bool)
    @@message_last_menu_active = @@menuactive.to_unsafe
    @@message_to_print = 1
    @@message_string = string
    @@message_routine = routine
    @@message_needs_input = input
    @@menuactive = true
    return nil
  end

  def self.m_stop_message
    @@menuactive = @@message_last_menu_active
    @@message_to_print
    return nil
  end

  def self.m_clear_menus
    @@menuactive = false
    # if (!@@netgame && @@usergame && @@paused)
    #   @@sendpause = true
    # end
    return nil
  end
end
