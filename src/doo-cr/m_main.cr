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
# ==> Misc and menu

module Doocr
  def self.m_clear_box(box : LibC::Int*)
    (box + Doocr::BOXTOP).value = Int32::MIN
    (box + Doocr::BOXRIGHT).value = Int32::MIN
    (box + Doocr::BOXLEFT).value = Int32::MAX
    (box + Doocr::BOXBOTTOM).value = Int32::MAX
  end

  def self.m_add_to_box(box : LibC::Int*, x : LibC::Int, y : LibC::Int)
    if x < box[Doocr::BOXLEFT]
      (box + Doocr::BOXLEFT).value = x
    elsif x > box[Doocr::BOXRIGHT]
      (box + Doocr::BOXRIGHT).value = x
    end
    if y < box[Doocr::BOXBOTTOM]
      (box + Doocr::BOXBOTTOM).value = y
    elsif y > box[Doocr::BOXTOP]
      (box + Doocr::BOXTOP).value = y
    end
  end

  #
  # m_read_save_strings
  # read the strings from the savegame files
  #
  def self.m_read_save_strings
    Doocr::Loadenum::LoadEnd.value.times do |i|
      name = "#{@@deh_savegamename}#{i}.dsg"

      if !File.exists?(name)
        @@savegamestrings[i] = @@deh_emptystring
        (@@loadmenu.to_unsafe + i).value.status = 0
        next
      end
      open(name, "r") do |file|
        @@savegamestrings[i] = file.read_string(Doocr::SAVESTRINGSIZE).split('\0', 2)[0]
      end
      (@@loadmenu.to_unsafe + i).value.status = 1
    end
  end

  # m_draw_load & Cie
  def self.m_draw_load
    CDoom.v_draw_patch_direct(72, 28, 0, CDoom.w_cache_lump_name("M_LOADG", Doocr::PU_CACHE).as(CDoom::Patch*))
    Doocr::Loadenum::LoadEnd.value.times do |i|
      m_draw_save_load_border(@@loaddef.x, @@loaddef.y + Doocr::LINEHEIGHT * i)
      m_write_text(@@loaddef.x, @@loaddef.y + Doocr::LINEHEIGHT * i, @@savegamestrings[i])
    end
  end

  #
  # Draw border for the savegame description
  #
  def self.m_draw_save_load_border(x : Int32, y : Int32)
    CDoom.v_draw_patch_direct(x - 8, y + 7, 0, CDoom.w_cache_lump_name("M_LSLEFT", Doocr::PU_CACHE).as(CDoom::Patch*))

    24.times do |i|
      CDoom.v_draw_patch_direct(x, y + 7, 0, CDoom.w_cache_lump_name("M_LSCNTR", Doocr::PU_CACHE).as(CDoom::Patch*))
      x += 8
    end

    CDoom.v_draw_patch_direct(x, y + 7, 0, CDoom.w_cache_lump_name("M_LSRGHT", Doocr::PU_CACHE).as(CDoom::Patch*))
  end

  #
  # User wants to load this game
  #
  def self.m_load_select(choice : Int32)
    name = uninitialized StaticArray(UInt8, 256)

    CDoom.doom_strcpy(name, @@deh_savegamename)
    CDoom.doom_concat(name, CDoom.doom_itoa(choice, 10))
    CDoom.doom_concat(name, ".dsg")

    CDoom.g_load_game(name)
    m_clear_menus
  end

  #
  # Selected from DOOM menu
  #
  def self.m_load_game(choice : Int32)
    if Doocr.netgame != 0
      m_start_message(@@deh_load_net, NULL_PROCP1, 0)
      return
    end

    m_setup_next_menu(@@loaddef)
    m_read_save_strings
  end

  #
  #  m_save_game & Cie.
  #
  def self.m_draw_save
    CDoom.v_draw_patch_direct(72, 28, 0, CDoom.w_cache_lump_name("M_SAVEG", Doocr::PU_CACHE).as(CDoom::Patch*))
    Doocr::Loadenum::LoadEnd.value.times do |i|
      m_draw_save_load_border(@@loaddef.x, @@loaddef.y + Doocr::LINEHEIGHT * i)
      m_write_text(@@loaddef.x, @@loaddef.y + Doocr::LINEHEIGHT * i, @@savegamestrings[i])
    end

    if Doocr.save_string_enter != 0
      i = m_string_width(@@savegamestrings[Doocr.save_slot])
      m_write_text(@@loaddef.x + i, @@loaddef.y + Doocr::LINEHEIGHT * Doocr.save_slot, "_")
    end
  end

  #
  # m_responder calls this when user is finished
  #
  def self.m_do_save(slot : Int32)
    CDoom.g_save_game(slot, @@savegamestrings[slot])
    m_clear_menus

    # PICK QUICKSAVE SLOT YET?
    Doocr.quick_save_slot = slot if Doocr.quick_save_slot == -2
  end

  #
  # User wants to save. Start string input for m_responder
  #
  def self.m_save_select(choice : Int32)
    # we are going to be intercepting all chars
    Doocr.save_string_enter = 1

    Doocr.save_slot = choice

    @@save_old_string = @@savegamestrings[choice]
    if @@savegamestrings[choice] == @@deh_emptystring
      @@savegamestrings[choice] = ""
    end
  end

  #
  # Selected from DOOM menu
  #
  def self.m_save_game(choice : Int32)
    if Doocr.usergame == 0
      m_start_message(@@deh_save_dead, NULL_PROCP1, 0)
      return
    end

    return if Doocr.gamestate != Doocr::Gamestate::Level

    m_setup_next_menu(@@savedef)
    m_read_save_strings
  end

  #
  # m_quicksave
  #
  def self.m_quicksave_response(ch : Int32)
    if ch == 'y'.ord
      CDoom.m_do_save(Doocr.quick_save_slot)
      Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_swtchx)
    end
  end

  def self.m_quicksave
    if Doocr.usergame == 0
      Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_oof)
      return
    end

    return if Doocr.gamestate != Doocr::Gamestate::Level

    if Doocr.quick_save_slot < 0
      CDoom.m_start_control_panel
      m_read_save_strings
      m_setup_next_menu(@@savedef)
      Doocr.quick_save_slot = -2 # means to pick a slot now
      return
    end
    m_start_message(@@deh_qsprompt_1 + @@savegamestrings[Doocr.quick_save_slot] + @@deh_qsprompt_2,
      ->CDoom.m_quicksave_response(Int32), 1)
  end

  #
  # m_quickload
  #
  def self.m_quickload_response(ch : Int32)
    if ch == 'y'.ord
      m_load_select(Doocr.quick_save_slot)
      Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_swtchx)
    end
  end

  def self.m_quickload
    if Doocr.netgame != 0
      m_start_message(@@deh_qload_net, NULL_PROCP1, 0)
      return
    end

    if Doocr.quick_save_slot < 0
      m_start_message(@@deh_qsave_spot, NULL_PROCP1, 0)
      return
    end
    m_start_message(@@deh_qlprompt_1 + @@savegamestrings[Doocr.quick_save_slot] + @@deh_qlprompt_2,
      ->CDoom.m_quickload_response(Int32), 1)
  end

  #
  # Read This Menus
  # Had a "quick hack to fix romero bug"
  #
  def self.m_draw_readthis1
    Doocr.inhelpscreens = 1
    CDoom.v_draw_patch_direct(0, 0, 0, CDoom.w_cache_lump_name("HELP2", Doocr::PU_CACHE).as(CDoom::Patch*))
  end

  #
  # Read This Menus - optional second page.
  #
  def self.m_draw_readthis2
    Doocr.inhelpscreens = 1
    CDoom.v_draw_patch_direct(0, 0, 0, CDoom.w_cache_lump_name("HELP1", Doocr::PU_CACHE).as(CDoom::Patch*))
  end

  def self.m_draw_commercial
    Doocr.inhelpscreens = 1
    CDoom.v_draw_patch_direct(0, 0, 0, CDoom.w_cache_lump_name("HELP", Doocr::PU_CACHE).as(CDoom::Patch*))
  end

  #
  # Change Sfx & Music volumes
  #
  def self.m_draw_sound
    CDoom.v_draw_patch_direct(60, 38, 0, CDoom.w_cache_lump_name("M_SVOL", Doocr::PU_CACHE).as(CDoom::Patch*))

    m_draw_thermo(@@sounddef.x, @@sounddef.y + Doocr::LINEHEIGHT * (Doocr::Soundenum::Sfxvol.value + 1),
      16, @@snd_sfx_volume)

    m_draw_thermo(@@sounddef.x, @@sounddef.y + Doocr::LINEHEIGHT * (Doocr::Soundenum::Musicvol.value + 1),
      16, Doocr.snd_music_volume)
  end

  def self.m_sound(choice : Int32)
    m_setup_next_menu(@@sounddef)
  end

  def self.m_sfxvol(choice : Int32)
    case choice
    when 0
      @@snd_sfx_volume -= 1 if @@snd_sfx_volume > 0
    when 1
      @@snd_sfx_volume += 1 if @@snd_sfx_volume < 15
    end
  end

  def self.m_musicvol(choice : Int32)
    case choice
    when 0
      Doocr.snd_music_volume -= 1 if Doocr.snd_music_volume > 0
    when 1
      Doocr.snd_music_volume += 1 if Doocr.snd_music_volume < 15
    end

    CDoom.s_set_music_volume(Doocr.snd_music_volume)
  end

  #
  # m_draw_mainmenu
  #
  def self.m_draw_mainmenu
    CDoom.v_draw_patch_direct(94, 2, 0, CDoom.w_cache_lump_name("M_DOOM", Doocr::PU_CACHE).as(CDoom::Patch*))
  end

  #
  # m_newgame
  #
  def self.m_draw_newgame
    CDoom.v_draw_patch_direct(96, 14, 0, CDoom.w_cache_lump_name("M_NEWG", Doocr::PU_CACHE).as(CDoom::Patch*))
    CDoom.v_draw_patch_direct(54, 38, 0, CDoom.w_cache_lump_name("M_SKILL", Doocr::PU_CACHE).as(CDoom::Patch*))
  end

  def self.m_new_game(choice : Int32)
    if Doocr.netgame != 0 && Doocr.demoplayback == 0
      m_start_message(@@deh_newgame, NULL_PROCP1, 0)
      return
    end

    if Doocr.gamemode == Doocr::GameMode::Commercial
      m_setup_next_menu(@@newdef)
    else
      m_setup_next_menu(@@epidef)
    end
  end

  #
  # m_episode
  #
  def self.m_draw_episode
    CDoom.v_draw_patch_direct(54, 38, 0, CDoom.w_cache_lump_name("M_EPISOD", Doocr::PU_CACHE).as(CDoom::Patch*))
  end

  def self.m_verify_nightmare(ch : Int32)
    return if ch != 'y'.ord

    CDoom.g_defered_init_new(Doocr::Skill::Nightmare, Doocr.epi + 1, 1)
    m_clear_menus
  end

  def self.m_choose_skill(choice : Int32)
    if choice == Doocr::Skill::Nightmare.value
      m_start_message(@@deh_nightmare, ->CDoom.m_verify_nightmare(Int32), 1)
      return
    end

    CDoom.g_defered_init_new(Doocr::Skill.new(choice), Doocr.epi + 1, 1)
    m_clear_menus
  end

  def self.m_episode(choice : Int32)
    if Doocr.gamemode == Doocr::GameMode::Shareware && choice != 0
      m_start_message(@@deh_swstring, NULL_PROCP1, 0)
      m_setup_next_menu(@@readdef1)
      return
    end

    # Yet another hack...
    if Doocr.gamemode == Doocr::GameMode::Registered && choice > 2
      puts "m_episode: 4th episode requires Ultimate DOOM"
      choice = 0
    end

    Doocr.epi = choice
    m_setup_next_menu(@@newdef)
  end

  #
  # m_options
  #
  def self.m_draw_options
    CDoom.v_draw_patch_direct(108, 15, 0, CDoom.w_cache_lump_name("M_OPTTTL", Doocr::PU_CACHE).as(CDoom::Patch*))

    CDoom.v_draw_patch_direct(@@optionsdef.x + 120, @@optionsdef.y + Doocr::LINEHEIGHT * Doocr::OptionsEnum::Messages.value, 0, CDoom.w_cache_lump_name(Doocr.msg_names[Doocr.show_messages].to_unsafe, Doocr::PU_CACHE).as(CDoom::Patch*))

    m_draw_thermo(@@optionsdef.x, @@optionsdef.y + Doocr::LINEHEIGHT * (Doocr::OptionsEnum::Scrnsize.value + 1),
      9, Doocr.screen_size)

    m_draw_thermo(@@optionsdef.x, @@optionsdef.y + Doocr::LINEHEIGHT * (Doocr::OptionsEnum::Mousesensitivity.value + 1),
      10, Doocr.mouse_sensitivity)

    m_write_text(@@optionsdef.x, @@optionsdef.y +
                                 Doocr::LINEHEIGHT * Doocr::OptionsEnum::More.value + Doocr.hu_font[0].value.height // 2,
      "more options")
  end

  def self.m_options(choice : Int32)
    m_setup_next_menu(@@optionsdef)
  end

  #
  # Toggle messages on/off
  #
  def self.m_change_messages(choice : Int32)
    # warning: unused parameter `choice : Int32'
    choice = 0
    Doocr.show_messages = 1 - Doocr.show_messages

    if Doocr.show_messages == 0
      (@@players.to_unsafe + Doocr.consoleplayer).value.message = @@deh_msgoff
    else
      (@@players.to_unsafe + Doocr.consoleplayer).value.message = @@deh_msgon
    end

    Doocr.message_dontfuckwithme = 1
  end

  def self.m_moreoptions(choice : Int32)
    m_setup_next_menu(@@moreoptions_def)
  end

  def self.m_draw_moreoptions
    CDoom.v_draw_patch_direct(108, 8, 0, CDoom.w_cache_lump_name("M_OPTTTL", Doocr::PU_CACHE).as(CDoom::Patch*))

    @@moreoptions_menus[@@current_options_menu].each_with_index do |item, i|
      m_write_text(@@moreoptions_def.x, @@moreoptions_def.y +
                                        Doocr::LINEHEIGHT * i + Doocr.hu_font[0].value.height // 2,
        item.text + (
          (item.bool.null? ? "" : (item.bool.value != 0 ? "on" : "off")) +
          (item.num.null? ? "" : "#{item.num.value + 1}")
        ))
    end
  end

  def self.m_change_options_menu(choice : Int32)
    @@current_options_menu -= 1 if choice == 0 && @@current_options_menu > 0
    @@current_options_menu += 1 if choice == 1 && @@current_options_menu < @@moreoptions_menus.size - 1
    @@moreoptions_def.menuitems = @@moreoptions_menus[@@current_options_menu]
  end

  def self.m_change_midibank(choice : Int32)
    @@midibank -= 1 if choice == 0 && @@midibank > 0
    @@midibank += 1 if choice == 1 && @@midibank < 78
    ADLMIDI.adl_setBank(@@adl_player.not_nil!, @@midibank)
  end

  def self.m_edit_controls(choice : Int32)
    m_setup_next_menu(@@editcontrols_def)
  end

  @@selected_edit = Pointer(Int32).null

  def self.m_draw_key(key : Pointer(Int32)) : String
    str = "NIL"

    Doocr::DoomKey.from_value?(key.value).try do |dkey|
      case dkey
      when Doocr::DoomKey::UNKNOWN
      when Doocr::DoomKey::TAB
        str = "TAB"
      when Doocr::DoomKey::ENTER
        str = "ENTER"
      when Doocr::DoomKey::ESCAPE
        str = "ESCAPE"
      when Doocr::DoomKey::SPACE
        str = "SPACE"
      when Doocr::DoomKey::BACKSPACE
        str = "BACKSPACE"
      when Doocr::DoomKey::CTRL
        str = "CTRL"
      when Doocr::DoomKey::LEFT_ARROW
        str = "LEFT ARROW"
      when Doocr::DoomKey::UP_ARROW
        str = "UP ARROW"
      when Doocr::DoomKey::RIGHT_ARROW
        str = "RIGHT ARROW"
      when Doocr::DoomKey::DOWN_ARROW
        str = "DOWN ARROW"
      when Doocr::DoomKey::SHIFT
        str = "SHIFT"
      when Doocr::DoomKey::ALT
        str = "ALT"
      when Doocr::DoomKey::F1
        str = "F1"
      when Doocr::DoomKey::F2
        str = "F2"
      when Doocr::DoomKey::F3
        str = "F3"
      when Doocr::DoomKey::F4
        str = "F4"
      when Doocr::DoomKey::F5
        str = "F5"
      when Doocr::DoomKey::F6
        str = "F6"
      when Doocr::DoomKey::F7
        str = "F7"
      when Doocr::DoomKey::F8
        str = "F8"
      when Doocr::DoomKey::F9
        str = "F0"
      when Doocr::DoomKey::F10
        str = "F10"
      when Doocr::DoomKey::F11
        str = "F11"
      when Doocr::DoomKey::F12
        str = "F12"
      when Doocr::DoomKey::PAUSE
        str = "PAUSE"
      else
        str = "#{key.value.chr.upcase}"
      end
    end

    str = @@selected_edit == key ? "-#{str}-" : " #{str}"
    return str
  end

  def self.m_draw_edit_controls
    m_write_text(CDoom::SCREENWIDTH // 2 - "Controls".size // 2, @@editcontrols_def.y +
                                                                 -Doocr::LINEHEIGHT + Doocr.hu_font[0].value.height // 2,
      "Controls")

    @@editcontrols_menu.each_with_index do |item, i|
      m_write_text(@@editcontrols_def.x, @@editcontrols_def.y +
                                         Doocr::LINEHEIGHT * i + Doocr.hu_font[0].value.height // 2,
        item.text + (item.num.null? ? "" : m_draw_key(item.num)))
    end
  end

  def self.m_edit_forward(choice : Int32)
    @@selected_edit = pointerof(@@key_up)
  end

  def self.m_edit_backward(choice : Int32)
    @@selected_edit = pointerof(@@key_down)
  end

  def self.m_edit_tleft(choice : Int32)
    @@selected_edit = pointerof(@@key_left)
  end

  def self.m_edit_tright(choice : Int32)
    @@selected_edit = pointerof(@@key_right)
  end

  def self.m_edit_sleft(choice : Int32)
    @@selected_edit = pointerof(@@key_strafeleft)
  end

  def self.m_edit_sright(choice : Int32)
    @@selected_edit = pointerof(@@key_straferight)
  end

  def self.m_edit_sprint(choice : Int32)
    @@selected_edit = pointerof(@@key_speed)
  end

  def self.m_edit_shoot(choice : Int32)
    @@selected_edit = pointerof(@@key_fire)
  end

  def self.m_edit_use(choice : Int32)
    @@selected_edit = pointerof(@@key_use)
  end

  #
  # Toggle crosshair on/off
  #
  def self.m_change_crosshair(choice : Int32)
    # warning: unused parameter `choice : Int32'
    choice = 0
    Doocr.crosshair = 1 - Doocr.crosshair
  end

  #
  # Toggle always-run on/off
  #
  def self.m_change_alwaysrun(choice : Int32)
    # warning: unused parameter `choice : Int32'
    choice = 0
    Doocr.always_run = 1 - Doocr.always_run
  end

  def self.m_toggle_fullscreen(choice : Int32)
    @@rlfullscreen = 1 - @@rlfullscreen
    Raylib.toggle_borderless_windowed unless @@headless
  end

  def self.m_toggle_smoothpan(choice : Int32)
    @@midismoothpan = 1 - @@midismoothpan
    @@adl_player.try { |ap| ADLMIDI.adl_setSoftPanEnabled(ap, @@midismoothpan) }
  end

  def self.m_toggle_pitching(choice : Int32)
    @@randompitch = 1 - @@randompitch
  end

  def self.m_toggle_amactivedraw(choice : Int32)
    @@amactivedraw = 1 - @@amactivedraw
  end

  def self.m_toggle_weaponfirecentered(choice : Int32)
    @@weaponfirecentered = 1 - @@weaponfirecentered
  end

  #
  # m_endgame
  #
  def self.m_endgame_response(ch : Int32)
    return if ch != 'y'.ord

    @@current_menu.last_on = Doocr.item_on
    m_clear_menus
    CDoom.d_start_title
  end

  def self.m_endgame(choice : Int32)
    choice = 0
    if Doocr.usergame == 0
      Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_oof)
      return
    end

    if Doocr.netgame != 0
      m_start_message(@@deh_netend, NULL_PROCP1, 0)
      return
    end

    m_start_message(@@deh_endgame, ->CDoom.m_endgame_response(Int32), 1)
  end

  #
  # m_readthis
  #
  def self.m_readthis(choice : Int32)
    choice = 0
    m_setup_next_menu(@@readdef1)
  end

  def self.m_readthis2(choice : Int32)
    choice = 0
    m_setup_next_menu(@@readdef2)
  end

  def self.m_finish_readthis(choice : Int32)
    choice = 0
    m_setup_next_menu(@@maindef)
  end

  #
  # m_quitdoom
  #
  def self.m_quit_response(ch : Int32)
    return if ch != 'y'.ord
    if Doocr.netgame == 0
      if Doocr.gamemode == Doocr::GameMode::Commercial
        Doocr.s_start_sound(Pointer(Void).null, Doocr.quitsounds2[(Doocr.gametic >> 2) & 7])
      else
        Doocr.s_start_sound(Pointer(Void).null, Doocr.quitsounds[(Doocr.gametic >> 2) & 7])
      end
      CDoom.i_wait_vbl(105)
    end
    CDoom.i_quit
  end

  def self.m_quitdoom(choice : Int32)
    # We pick index 0 which is language sensitive,
    #  or one at random, between 1 and maximum number.
    string = ""
    if Doocr.language != Doocr::Language::English
      string = @@doom1_endmsg[0]
    else
      if Doocr.gamemode == Doocr::GameMode::Commercial
        string = @@doom2_endmsg.sample(Random.new(Doocr.gametime))
      else
        string = @@doom1_endmsg.sample(Random.new(Doocr.gametime))
      end
    end
    string += "\n\n(press y to quit)"

    m_start_message(string, ->CDoom.m_quit_response(Int32), 1)
  end

  def self.m_change_sensitivity(choice : Int32)
    case choice
    when 0
      Doocr.mouse_sensitivity -= 1 if Doocr.mouse_sensitivity > 0
    when 1
      Doocr.mouse_sensitivity += 1 if Doocr.mouse_sensitivity < 9
    end
  end

  def self.m_mouse_move(choice : Int32)
    choice = 0
    Doocr.mousemove = 1 - Doocr.mousemove
  end

  def self.m_size_display(choice : Int32)
    case choice
    when 0
      if Doocr.screen_size > 0
        Doocr.screenblocks -= 1
        Doocr.screen_size -= 1
      end
    when 1
      if Doocr.screen_size < 8
        Doocr.screenblocks += 1
        Doocr.screen_size += 1
      end
    end

    CDoom.r_set_view_size(Doocr.screenblocks, Doocr.detail_level)
  end

  #
  # Menu Methods
  #
  def self.m_draw_thermo(x : LibC::Int, y : LibC::Int, therm_width : LibC::Int, therm_dot : LibC::Int)
    xx = x
    CDoom.v_draw_patch_direct(xx, y, 0, CDoom.w_cache_lump_name("M_THERML", Doocr::PU_CACHE).as(CDoom::Patch*))
    xx += 8
    therm_width.times do |i|
      CDoom.v_draw_patch_direct(xx, y, 0, CDoom.w_cache_lump_name("M_THERMM", Doocr::PU_CACHE).as(CDoom::Patch*))
      xx += 8
    end
    CDoom.v_draw_patch_direct(xx, y, 0, CDoom.w_cache_lump_name("M_THERMR", Doocr::PU_CACHE).as(CDoom::Patch*))

    CDoom.v_draw_patch_direct((x + 8) + therm_dot * 8, y, 0, CDoom.w_cache_lump_name("M_THERMO", Doocr::PU_CACHE).as(CDoom::Patch*))
  end

  def self.m_draw_empty_cell(menu : CDoom::Menu*, item : Int32)
    CDoom.v_draw_patch_direct(menu.value.x - 10, menu.value.y + item * Doocr::LINEHEIGHT - 1, 0,
      CDoom.w_cache_lump_name("M_CELL1", Doocr::PU_CACHE).as(CDoom::Patch*))
  end

  def self.m_draw_selcell(menu : CDoom::Menu*, item : Int32)
    CDoom.v_draw_patch_direct(menu.value.x - 10, menu.value.y + item * Doocr::LINEHEIGHT - 1, 0,
      CDoom.w_cache_lump_name("M_CELL2", Doocr::PU_CACHE).as(CDoom::Patch*))
  end

  def self.m_start_message(string : String, routine : Proc(Int32, Nil), input : LibC::Int)
    Doocr.message_last_menu_active = Doocr.menuactive
    Doocr.message_to_print = 1
    Doocr.message_string = string.to_unsafe
    Doocr.message_routine = routine
    Doocr.message_needs_input = input
    Doocr.menuactive = 1
  end

  def self.m_stop_message
    Doocr.menuactive = Doocr.message_last_menu_active
    Doocr.message_to_print = 0
  end

  #
  # Find string width from hu_font chars
  #
  def self.m_string_width(string : String) : Int32
    w = 0

    string.each_char do |c|
      c = c.upcase.ord - Doocr::HU_FONTSTART
      if c < 0 || c >= Doocr::HU_FONTSIZE
        w += 4
      else
        w += Doocr.hu_font[c].value.width.to_i16!
      end
    end

    return w
  end

  #
  # Find string height from hu_font chars
  #
  def self.m_string_height(string : UInt8*) : Int32
    height = Doocr.hu_font[0].value.height.to_i16!.to_i32

    h = height
    CDoom.doom_strlen(string).times do |i|
      h += height if string[i] == '\n'.ord
    end

    return h
  end

  #
  # Write a string using the hu_font
  #
  def self.m_write_text(x : Int, y : Int, string : String)
    cx = x
    cy = y

    string.each_char do |c|
      break if c == '\0'
      if c == '\n'
        cx = x
        cy += 12
        next
      end

      c = c.upcase.ord - Doocr::HU_FONTSTART
      if c < 0 || c >= Doocr::HU_FONTSIZE
        cx += 4
        next
      end

      w = Doocr.hu_font[c].value.width.to_i16!
      break if cx + w > CDoom::SCREENWIDTH
      CDoom.v_draw_patch_direct(cx, cy, 0, Doocr.hu_font[c])
      cx += w
    end
  end

  @@joywait = 0
  @@mousewait = 0
  @@menumousey = 0
  @@lasty = 0
  @@menumousex = 0
  @@lastx = 0
  @@mousex = 0
  @@mousey = 0

  #
  # m_responder
  #
  def self.m_responder(ev : CDoom::Event*) : LibC::Int
    ch = -1

    if ev.value.type == Doocr::Evtype::Joystick && @@joywait < CDoom.i_get_time
      if ev.value.data3 == -1
        ch = Doocr::KEY_UPARROW
        @@joywait = CDoom.i_get_time + 5
      elsif ev.value.data3 == 1
        ch = Doocr::KEY_DOWNARROW
        @@joywait = CDoom.i_get_time + 5
      end

      if ev.value.data2 == -1
        ch = Doocr::KEY_LEFTARROW
        @@joywait = CDoom.i_get_time + 2
      elsif ev.value.data2 == 1
        ch = Doocr::KEY_RIGHTARROW
        @@joywait = CDoom.i_get_time + 2
      end

      if ev.value.data1 & 1 != 0
        ch = Doocr::KEY_ENTER
        @@joywait = CDoom.i_get_time + 5
      end
      if ev.value.data1 & 2 != 0
        ch = Doocr::KEY_BACKSPACE
        @@joywait = CDoom.i_get_time + 5
      end
    else
      if ev.value.type == Doocr::Evtype::Mouse && @@mousewait < CDoom.i_get_time
        @@menumousey += ev.value.data3

        if @@menumousey < @@lasty - MENU_SCROLL_DEADZONE
          ch = Doocr::KEY_DOWNARROW
          @@mousewait = CDoom.i_get_time + 5
          @@lasty -= MENU_SCROLL_DEADZONE
          @@menumousey = @@lasty
        elsif @@menumousey > @@lasty + MENU_SCROLL_DEADZONE
          ch = Doocr::KEY_UPARROW
          @@mousewait = CDoom.i_get_time + 5
          @@lasty += MENU_SCROLL_DEADZONE
          @@menumousey = @@lasty
        end

        @@menumousex += ev.value.data2
        if @@menumousex < @@lastx - MENU_SCROLL_DEADZONE
          ch = Doocr::KEY_LEFTARROW
          @@mousewait = CDoom.i_get_time + 5
          @@lastx -= MENU_SCROLL_DEADZONE
          @@menumousex = @@lastx
        elsif @@menumousex > @@lastx + MENU_SCROLL_DEADZONE
          ch = Doocr::KEY_RIGHTARROW
          @@mousewait = CDoom.i_get_time + 5
          @@lastx += MENU_SCROLL_DEADZONE
          @@menumousex = @@lastx
        end

        if ev.value.data1 & 2 != 0
          ch = Doocr::KEY_BACKSPACE
          @@mousewait = CDoom.i_get_time + 15
        elsif ev.value.data1 & 1 != 0
          ch = Doocr::KEY_ENTER
          @@mousewait = CDoom.i_get_time + 15
        end
      else
        ch = ev.value.data1 if ev.value.type == Doocr::Evtype::Keydown
      end
    end

    return 0 if ch == -1

    # Edit selected control
    if !@@selected_edit.null?
      unless Doocr::DoomKey.from_value?(ch).nil?
        @@selected_edit.value = ch
        @@selected_edit = Pointer(Int32).null
        return 1
      end
    end

    # Save Game string input
    if Doocr.save_string_enter != 0
      case ch
      when Doocr::KEY_BACKSPACE
        if @@savegamestrings[Doocr.save_slot].size > 0
          @@savegamestrings[Doocr.save_slot] = @@savegamestrings[Doocr.save_slot].rchop
        end
      when Doocr::KEY_ESCAPE
        Doocr.save_string_enter = 0
        @@savegamestrings[Doocr.save_slot] = @@save_old_string
      when Doocr::KEY_ENTER
        Doocr.save_string_enter = 0
        CDoom.m_do_save(Doocr.save_slot) # if CDoom.savegamestrings[Doocr.save_slot][0] != 0 allows empty saves
      else
        ch = CDoom.doom_toupper(ch)
        unless ch != 32 && (ch - Doocr::HU_FONTSTART < 0 || ch - Doocr::HU_FONTSTART >= Doocr::HU_FONTSIZE)
          if ch >= 32 && ch <= 127 &&
             @@savegamestrings[Doocr.save_slot].size < Doocr::SAVESTRINGSIZE - 1 &&
             m_string_width(@@savegamestrings[Doocr.save_slot]) <
               (Doocr::SAVESTRINGSIZE - 2) * 8
            @@savegamestrings[Doocr.save_slot] += ch.chr
          end
        end
      end

      return 1
    end

    # Take care of any messages that need input
    if Doocr.message_to_print != 0
      return 0 if Doocr.message_needs_input != 0 &&
                  !(ch == ' '.ord || ch == 'n'.ord || ch == 'y'.ord || ch == Doocr::KEY_ESCAPE)

      Doocr.menuactive = Doocr.message_last_menu_active
      Doocr.message_to_print = 0
      Doocr.message_routine.call(ch) unless Doocr.message_routine.pointer.null?

      Doocr.menuactive = 0
      Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_swtchx)
      return 1
    end

    if Doocr.devparm != 0 && ch == Doocr::KEY_F1
      CDoom.g_screenshot
      return 1
    end

    # F-Keys
    if Doocr.menuactive == 0
      case ch
      when Doocr::KEY_MINUS # Screen size down
        return 0 if Doocr.automapactive != 0 || Doocr.chat_on != 0
        m_size_display(0)
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_stnmov)
        return 1
      when Doocr::KEY_EQUALS # Screen size up
        return 0 if Doocr.automapactive != 0 || Doocr.chat_on != 0
        m_size_display(1)
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_stnmov)
        return 1
      when Doocr::KEY_F1 # Help key
        CDoom.m_start_control_panel

        @@current_menu = @@readdef1

        Doocr.item_on = 0
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_swtchn)
        return 1
      when Doocr::KEY_F2 # Save
        CDoom.m_start_control_panel
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_swtchn)
        m_save_game(0)
        return 1
      when Doocr::KEY_F3 # Load
        CDoom.m_start_control_panel
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_swtchn)
        m_load_game(0)
        return 1
      when Doocr::KEY_F4 # Sound Volume
        CDoom.m_start_control_panel
        @@current_menu = @@sounddef
        Doocr.item_on = Doocr::Soundenum::Sfxvol.value
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_swtchn)
        return 1
      when Doocr::KEY_F5
        CDoom.m_start_control_panel
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_swtchn)
        m_moreoptions(0)
        return 1
      when Doocr::KEY_F6 # Quicksave
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_swtchn)
        m_quicksave
        return 1
      when Doocr::KEY_F7 # End game
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_swtchn)
        m_endgame(0)
        return 1
      when Doocr::KEY_F8 # Toggle messages
        m_change_messages(0)
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_swtchn)
        return 1
      when Doocr::KEY_F9 # Quickload
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_swtchn)
        m_quickload
        return 1
      when Doocr::KEY_F10 # Quit DOOM
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_swtchn)
        m_quitdoom(0)
        return 1
      when Doocr::KEY_F11 # gamma toggle
        Doocr.usegamma += 1
        Doocr.usegamma = 0 if Doocr.usegamma > 4
        (@@players.to_unsafe + Doocr.consoleplayer).value.message = Doocr.gammamsg[Doocr.usegamma].to_unsafe
        CDoom.i_set_palette(CDoom.w_cache_lump_name("PLAYPAL", Doocr::PU_CACHE).as(UInt8*))
        return 1
      end
    end

    # Pop-up menu?
    if Doocr.menuactive == 0
      if ch == Doocr::KEY_ESCAPE
        CDoom.m_start_control_panel
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_swtchn)
        return 1
      end
      return 0
    end

    # Keys usable within menu
    case ch
    when Doocr::KEY_DOWNARROW
      loop do
        Doocr.item_on = Doocr.item_on + 1 > @@current_menu.menuitems.size - 1 ? 0 : Doocr.item_on + 1
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_pstop)
        break unless @@current_menu.menuitems[Doocr.item_on].status == -1
      end
      return 1
    when Doocr::KEY_UPARROW
      loop do
        Doocr.item_on = Doocr.item_on == 0 ? @@current_menu.menuitems.size - 1 : Doocr.item_on - 1
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_pstop)
        break unless @@current_menu.menuitems[Doocr.item_on].status == -1
      end
      return 1
    when Doocr::KEY_LEFTARROW
      if !@@current_menu.menuitems[Doocr.item_on].routine.pointer.null? &&
         @@current_menu.menuitems[Doocr.item_on].status == 2
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_stnmov)
        @@current_menu.menuitems[Doocr.item_on].routine.call(0)
      end
      return 1
    when Doocr::KEY_RIGHTARROW
      if !@@current_menu.menuitems[Doocr.item_on].routine.pointer.null? &&
         @@current_menu.menuitems[Doocr.item_on].status == 2
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_stnmov)
        @@current_menu.menuitems[Doocr.item_on].routine.call(1)
      end
      return 1
    when Doocr::KEY_ENTER
      if !@@current_menu.menuitems[Doocr.item_on].routine.pointer.null? &&
         @@current_menu.menuitems[Doocr.item_on].status != 0
        @@current_menu.last_on = Doocr.item_on
        if @@current_menu.menuitems[Doocr.item_on].status == 2
          @@current_menu.menuitems[Doocr.item_on].routine.call(1)
          Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_stnmov)
        else
          @@current_menu.menuitems[Doocr.item_on].routine.call(Doocr.item_on.to_i32)
          Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_pistol)
        end
      end
      return 1
    when Doocr::KEY_ESCAPE
      @@current_menu.last_on = Doocr.item_on
      m_clear_menus
      Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_swtchx)
      return 1
    when Doocr::KEY_BACKSPACE
      @@current_menu.last_on = Doocr.item_on
      if prev = @@current_menu.prev_menu
        @@current_menu = prev
        Doocr.item_on = @@current_menu.last_on
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_swtchn)
      end
      return 1
    else
      i = Doocr.item_on + 1
      while i < @@current_menu.menuitems.size
        if @@current_menu.menuitems[i].alpha_key == ch.chr
          Doocr.item_on = i
          Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_pstop)
          return 1
        end
        i += 1
      end
      (Doocr.item_on + 1).times do |i|
        if @@current_menu.menuitems[i].alpha_key == ch.chr
          Doocr.item_on = i
          Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_pstop)
          return 1
        end
      end
    end

    return 0
  end

  def self.m_start_control_panel
    # intro might call this repeatedly
    return if Doocr.menuactive != 0

    Doocr.menuactive = 1
    @@current_menu = @@maindef             # JDC
    Doocr.item_on = @@current_menu.last_on # JDC
  end

  @@x = 0
  @@y = 0

  #
  # m_drawer
  # Called after the view has been rendered,
  # but before it has been blitted.
  #
  def self.m_drawer
    string = ""
    i = 0
    Doocr.inhelpscreens = 0

    # Horiz. & Vertically center string and print it.
    if Doocr.message_to_print != 0
      start = 0
      @@y = 100 - m_string_height(Doocr.message_string) // 2
      while (Doocr.message_string.not_nil! + start).value != 0
        i = 0
        while i < CDoom.doom_strlen(Doocr.message_string + start)
          if (Doocr.message_string.not_nil! + start + i).value == '\n'.ord
            string = String.new(Doocr.message_string.not_nil! + start, i)
            start += i + 1
            break
          end
          i += 1
        end

        if i == CDoom.doom_strlen(Doocr.message_string + start)
          string = String.new(Doocr.message_string.not_nil! + start)
          start += i
        end

        @@x = 160 - m_string_width(string) // 2
        m_write_text(@@x, @@y, string)
        @@y += Doocr.hu_font[0].value.height.to_i16!
      end
      return
    end

    return if Doocr.menuactive == 0

    # Darken background so the menu is more readable.
    @@current_menu.routine.call unless @@current_menu.routine.pointer.null?

    # DRAW MENU
    @@x = @@current_menu.x.to_i32
    @@y = @@current_menu.y.to_i32
    max = @@current_menu.menuitems.size
    max.times do |i|
      menuitem = @@current_menu.menuitems[i]

      unless menuitem.name.empty?
        CDoom.v_draw_patch_direct(@@x, @@y, 0, CDoom.w_cache_lump_name(menuitem.name, Doocr::PU_CACHE).as(CDoom::Patch*))
      end
      @@y += Doocr::LINEHEIGHT
    end

    # DRAW SKULL
    CDoom.v_draw_patch_direct(@@x + Doocr::SKULLXOFF, @@current_menu.y - 5 + Doocr.item_on * Doocr::LINEHEIGHT, 0,
      CDoom.w_cache_lump_name(Doocr.skull_name[Doocr.which_skull].to_unsafe, Doocr::PU_CACHE).as(CDoom::Patch*))
  end

  def self.m_clear_menus
    Doocr.menuactive = 0
  end

  def self.m_setup_next_menu(menudef : Menu)
    @@current_menu = menudef
    Doocr.item_on = @@current_menu.last_on
  end

  def self.m_ticker
    Doocr.skull_anim_counter &-= 1
    if Doocr.skull_anim_counter <= 0
      Doocr.which_skull ^= 1
      Doocr.skull_anim_counter = 8
    end
  end

  def self.m_init
    @@current_menu = @@maindef
    Doocr.menuactive = 0
    Doocr.item_on = @@current_menu.last_on
    Doocr.which_skull = 0
    Doocr.skull_anim_counter = 10
    Doocr.screen_size = Doocr.screenblocks - 3
    Doocr.message_to_print = 0
    Doocr.message_string = Pointer(UInt8).null
    Doocr.message_last_menu_active = Doocr.menuactive
    Doocr.quick_save_slot = -1

    # Here we could catch other version dependencies,
    #  like HELP1/2, and four episodes.

    case Doocr.gamemode
    when Doocr::GameMode::Commercial
      # Setup read menu for Doom II
      @@mainmenu[Doocr::Mainenum::Readthis.value] = @@mainmenu[Doocr::Mainenum::Quitdoom.value]
      @@maindef.menuitems.pop
      @@maindef.y = @@maindef.y + 8
      @@newdef.prev_menu = @@maindef
      @@readdef1.routine = ->m_draw_commercial
      @@readdef1.x = 330
      @@readdef1.y = 165
      @@readmenu1.to_unsafe.value.routine = ->m_finish_readthis(Int32)
    when Doocr::GameMode::Retail
      # Skip first menu on Ultimate Doom
      pointerof(@@readdef1).value = @@readdef2
    when Doocr::GameMode::Shareware, Doocr::GameMode::Registered
      # Episode 2 and 3 are handled,
      #  branching to an ad screen.
      #
      # We need to remove the fourth episode.
      @@epidef.menuitems.pop
    end
  end

  def self.m_draw_text(x : Int32, y : Int32, direct : LibC::Int, string : LibC::Char*) : LibC::Int
    while string.value != 0
      c = CDoom.doom_toupper(string.value) - Doocr::HU_FONTSTART
      string += 1
      if c < 0 || c > Doocr::HU_FONTSIZE
        x += 4
        next
      end

      w = Doocr.hu_font[c].value.width.to_i16!.to_i32
      break if x + w > CDoom::SCREENWIDTH
      if direct != 0
        CDoom.v_draw_patch_direct(x, y, 0, Doocr.hu_font[c])
      else
        CDoom.v_draw_patch(x, y, 0, Doocr.hu_font[c])
      end
      x += w
    end

    return x
  end

  def self.m_write_file(name : LibC::Char*, source : Void*, length : LibC::Int) : LibC::Int
    begin
      File.open(String.new(name), "wb") do |file|
        file.write(Slice.new(source.as(UInt8*), length))
      end
      1
    rescue
      0
    end
  end

  def self.m_read_file(name : LibC::Char*, buffer : UInt8**) : LibC::Int
    begin
      data = File.read(String.new(name)).to_slice
    rescue
      CDoom.i_error("Error: Couldn't read file #{name}")
    end
    buf = CDoom.z_malloc(data.size, Doocr::PU_STATIC, Pointer(Void).null).as(UInt8*)
    buf.copy_from(data.to_unsafe, data.size)
    buffer.value = buf
    data.size
  end

  def self.m_save_defaults
    begin
      File.open(Doocr.defaultfile, "w") do |file|
        @@defaults.size.times do |i|
          if @@defaults[i].defaultvalue > -0xfff && @@defaults[i].defaultvalue < 0xfff
            value = @@defaults[i].name == "snd_channels" ? Doocr.num_channels : @@defaults[i].location.not_nil!.value
            file << "#{@@defaults[i].name}\t\t#{value}\n"
          else
            text = @@defaults[i].name.starts_with?("chatmacro") ? Doocr.chat_macros[@@defaults[i].name[9].to_i] : String.new(@@defaults[i].text_location.not_nil!.value)
            file << "#{@@defaults[i].name}\t\t\"#{text}\"\n"
          end
        end
      end
    rescue
    end
  end

  def self.m_load_defaults
    defa = uninitialized StaticArray(UInt8, 80)
    strparm = uninitialized StaticArray(UInt8, 100)

    @@defaults.size.times do |i|
      if @@defaults[i].defaultvalue == 0xffff
        if @@defaults[i].name.starts_with?("chatmacro")
          Doocr.chat_macros[@@defaults[i].name[9].to_i] = @@defaults[i].default_text_value
        else
          @@defaults[i].text_location.not_nil!.value = @@defaults[i].default_text_value.to_unsafe
        end
      else
        if @@defaults[i].name == "snd_channels"
          Doocr.num_channels = @@defaults[i].defaultvalue
        else
          @@defaults[i].location.not_nil!.value = @@defaults[i].defaultvalue.to_i32!
        end
      end
    end

    # check for a custom default file
    i = ARGV.index("-config")
    if i && i < ARGV.size - 1
      Doocr.defaultfile = ARGV[i + 1]
      puts "        default file: #{Doocr.defaultfile}"
    else
      Doocr.defaultfile = Doocr.basedefault
    end

    begin
      File.each_line(Doocr.defaultfile) do |line|
        parts = line.split('\t', 2)
        next unless parts.size == 2
        name = parts[0].strip
        value = parts[1].strip
        @@defaults.size.times do |i|
          next unless @@defaults[i].name == name
          if value.starts_with?('"')
            text = value.strip('"').to_unsafe
            if @@defaults[i].name.starts_with?("chatmacro")
              Doocr.chat_macros[@@defaults[i].name[9].to_i] = value.strip('"')
            else
              @@defaults[i].text_location.not_nil!.value = text
            end
          elsif value.starts_with?("0x")
            parsed = CDoom.doom_atox(value.to_unsafe)
            if name == "snd_channels"
              Doocr.num_channels = parsed
            else
              @@defaults[i].location.not_nil!.value = parsed
            end
          else
            parsed = CDoom.doom_atoi(value.to_unsafe)
            if name == "snd_channels"
              Doocr.num_channels = parsed
            else
              @@defaults[i].location.not_nil!.value = parsed
            end
          end
          break
        end
      end
    rescue
    end
  end

  def self.write_pcx_file(filename : LibC::Char*, data : UInt8*, width : LibC::Int, height : LibC::Int, palette : UInt8*)
    output = IO::Memory.new
    output.write_byte(0x0a_u8)
    output.write_byte(5_u8)
    output.write_byte(1_u8)
    output.write_byte(8_u8)
    output.write_bytes(0_u16, IO::ByteFormat::LittleEndian)
    output.write_bytes(0_u16, IO::ByteFormat::LittleEndian)
    output.write_bytes((width - 1).to_u16!, IO::ByteFormat::LittleEndian)
    output.write_bytes((height - 1).to_u16!, IO::ByteFormat::LittleEndian)
    output.write_bytes(width.to_u16!, IO::ByteFormat::LittleEndian)
    output.write_bytes(height.to_u16!, IO::ByteFormat::LittleEndian)
    output.write(Bytes.new(48, 0_u8))
    output.write_byte(0_u8)
    output.write_byte(1_u8)
    output.write_bytes(width.to_u16!, IO::ByteFormat::LittleEndian)
    output.write_bytes(2_u16, IO::ByteFormat::LittleEndian)
    output.write(Bytes.new(58, 0_u8))

    (width * height).times do |i|
      if (data.value & 0xc0) != 0xc0
        output.write_byte(data.value)
        data += 1
      else
        output.write_byte(0xc1_u8)
        output.write_byte(data.value)
        data += 1
      end
    end

    # write the palette
    output.write_byte(0x0c_u8)
    768.times do |i|
      output.write_byte(palette.value)
      palette += 1
    end

    File.write(String.new(filename), output.to_slice)
  end

  def self.m_screenshot
    lbmname = uninitialized StaticArray(UInt8, 12)

    # munge planar buffer to linear
    linear = Doocr.screens[2]
    CDoom.i_read_screen(linear)

    # find a file name to save it to
    CDoom.doom_strcpy(lbmname, "DOOM00.pcx")
    i = 0
    while i < 99
      lbmname[4] = (i // 10 + '0'.ord).to_u8!
      lbmname[5] = (i % 10 + '0'.ord).to_u8!
      if !File.exists?(String.new(lbmname.to_slice))
        break # file doesn't exist
      end
      i += 1
    end
    CDoom.i_error("Error: m_screenshot: Couldn't create a PCX") if i == 100

    # save the pcs file
    Doocr.write_pcx_file(lbmname.to_unsafe, linear,
      CDoom::SCREENWIDTH, CDoom::SCREENHEIGHT,
      CDoom.w_cache_lump_name("PLAYPAL", Doocr::PU_CACHE).as(UInt8*))

    (@@players.to_unsafe + Doocr.consoleplayer).value.message = "screen shot"
  end
end
