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
  def self.m_clear_box(box : CDoom::Fixed*)
    (box + CDoom::BOXTOP).value = Int32::MIN
    (box + CDoom::BOXRIGHT).value = Int32::MIN
    (box + CDoom::BOXLEFT).value = Int32::MAX
    (box + CDoom::BOXBOTTOM).value = Int32::MAX
  end

  def self.m_add_to_box(box : CDoom::Fixed*, x : CDoom::Fixed, y : CDoom::Fixed)
    if x < box[CDoom::BOXLEFT]
      (box + CDoom::BOXLEFT).value = x
    elsif x > box[CDoom::BOXRIGHT]
      (box + CDoom::BOXRIGHT).value = x
    end
    if y < box[CDoom::BOXBOTTOM]
      (box + CDoom::BOXBOTTOM).value = y
    elsif y > box[CDoom::BOXTOP]
      (box + CDoom::BOXTOP).value = y
    end
  end

  #
  # m_read_save_strings
  # read the strings from the savegame files
  #
  def self.m_read_save_strings
    CDoom::Loadenum::LoadEnd.value.times do |i|
      name = "#{@@deh_savegamename}#{i}.dsg"

      if !File.exists?(name)
        @@savegamestrings[i] = @@deh_emptystring
        (@@loadmenu.to_unsafe + i).value.status = 0
        next
      end
      open(name, "r") do |file|
        @@savegamestrings[i] = file.read_string(CDoom::SAVESTRINGSIZE).split('\0', 2)[0]
      end
      (@@loadmenu.to_unsafe + i).value.status = 1
    end
  end

  # m_draw_load & Cie
  def self.m_draw_load
    CDoom.v_draw_patch_direct(72, 28, 0, CDoom.w_cache_lump_name("M_LOADG", CDoom::PU_CACHE).as(CDoom::Patch*))
    CDoom::Loadenum::LoadEnd.value.times do |i|
      m_draw_save_load_border(@@loaddef.x, @@loaddef.y + CDoom::LINEHEIGHT * i)
      m_write_text(@@loaddef.x, @@loaddef.y + CDoom::LINEHEIGHT * i, @@savegamestrings[i])
    end
  end

  #
  # Draw border for the savegame description
  #
  def self.m_draw_save_load_border(x : Int32, y : Int32)
    CDoom.v_draw_patch_direct(x - 8, y + 7, 0, CDoom.w_cache_lump_name("M_LSLEFT", CDoom::PU_CACHE).as(CDoom::Patch*))

    24.times do |i|
      CDoom.v_draw_patch_direct(x, y + 7, 0, CDoom.w_cache_lump_name("M_LSCNTR", CDoom::PU_CACHE).as(CDoom::Patch*))
      x += 8
    end

    CDoom.v_draw_patch_direct(x, y + 7, 0, CDoom.w_cache_lump_name("M_LSRGHT", CDoom::PU_CACHE).as(CDoom::Patch*))
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
    if CDoom.netgame != 0
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
    CDoom.v_draw_patch_direct(72, 28, 0, CDoom.w_cache_lump_name("M_SAVEG", CDoom::PU_CACHE).as(CDoom::Patch*))
    CDoom::Loadenum::LoadEnd.value.times do |i|
      m_draw_save_load_border(@@loaddef.x, @@loaddef.y + CDoom::LINEHEIGHT * i)
      m_write_text(@@loaddef.x, @@loaddef.y + CDoom::LINEHEIGHT * i, @@savegamestrings[i])
    end

    if CDoom.save_string_enter != 0
      i = m_string_width(@@savegamestrings[CDoom.save_slot])
      m_write_text(@@loaddef.x + i, @@loaddef.y + CDoom::LINEHEIGHT * CDoom.save_slot, "_")
    end
  end

  #
  # m_responder calls this when user is finished
  #
  def self.m_do_save(slot : Int32)
    CDoom.g_save_game(slot, @@savegamestrings[slot])
    m_clear_menus

    # PICK QUICKSAVE SLOT YET?
    CDoom.quick_save_slot = slot if CDoom.quick_save_slot == -2
  end

  #
  # User wants to save. Start string input for m_responder
  #
  def self.m_save_select(choice : Int32)
    # we are going to be intercepting all chars
    CDoom.save_string_enter = 1

    CDoom.save_slot = choice

    @@save_old_string = @@savegamestrings[choice]
    if @@savegamestrings[choice] == @@deh_emptystring
      @@savegamestrings[choice] = ""
    end
  end

  #
  # Selected from DOOM menu
  #
  def self.m_save_game(choice : Int32)
    if CDoom.usergame == 0
      m_start_message(@@deh_save_dead, NULL_PROCP1, 0)
      return
    end

    return if CDoom.gamestate != CDoom::Gamestate::Level

    m_setup_next_menu(@@savedef)
    m_read_save_strings
  end

  #
  # m_quicksave
  #
  def self.m_quicksave_response(ch : Int32)
    if ch == 'y'.ord
      CDoom.m_do_save(CDoom.quick_save_slot)
      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchx)
    end
  end

  def self.m_quicksave
    if CDoom.usergame == 0
      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_oof)
      return
    end

    return if CDoom.gamestate != CDoom::Gamestate::Level

    if CDoom.quick_save_slot < 0
      CDoom.m_start_control_panel
      m_read_save_strings
      m_setup_next_menu(@@savedef)
      CDoom.quick_save_slot = -2 # means to pick a slot now
      return
    end
    m_start_message(@@deh_qsprompt_1 + @@savegamestrings[CDoom.quick_save_slot] + @@deh_qsprompt_2,
      ->CDoom.m_quicksave_response(Int32), 1)
  end

  #
  # m_quickload
  #
  def self.m_quickload_response(ch : Int32)
    if ch == 'y'.ord
      m_load_select(CDoom.quick_save_slot)
      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchx)
    end
  end

  def self.m_quickload
    if CDoom.netgame != 0
      m_start_message(@@deh_qload_net, NULL_PROCP1, 0)
      return
    end

    if CDoom.quick_save_slot < 0
      m_start_message(@@deh_qsave_spot, NULL_PROCP1, 0)
      return
    end
    m_start_message(@@deh_qlprompt_1 + @@savegamestrings[CDoom.quick_save_slot] + @@deh_qlprompt_2,
      ->CDoom.m_quickload_response(Int32), 1)
  end

  #
  # Read This Menus
  # Had a "quick hack to fix romero bug"
  #
  def self.m_draw_readthis1
    CDoom.inhelpscreens = 1
    CDoom.v_draw_patch_direct(0, 0, 0, CDoom.w_cache_lump_name("HELP2", CDoom::PU_CACHE).as(CDoom::Patch*))
  end

  #
  # Read This Menus - optional second page.
  #
  def self.m_draw_readthis2
    CDoom.inhelpscreens = 1
    CDoom.v_draw_patch_direct(0, 0, 0, CDoom.w_cache_lump_name("HELP1", CDoom::PU_CACHE).as(CDoom::Patch*))
  end

  def self.m_draw_commercial
    CDoom.inhelpscreens = 1
    CDoom.v_draw_patch_direct(0, 0, 0, CDoom.w_cache_lump_name("HELP", CDoom::PU_CACHE).as(CDoom::Patch*))
  end

  #
  # Change Sfx & Music volumes
  #
  def self.m_draw_sound
    CDoom.v_draw_patch_direct(60, 38, 0, CDoom.w_cache_lump_name("M_SVOL", CDoom::PU_CACHE).as(CDoom::Patch*))

    m_draw_thermo(@@sounddef.x, @@sounddef.y + CDoom::LINEHEIGHT * (CDoom::Soundenum::Sfxvol.value + 1),
      16, @@snd_sfx_volume)

    m_draw_thermo(@@sounddef.x, @@sounddef.y + CDoom::LINEHEIGHT * (CDoom::Soundenum::Musicvol.value + 1),
      16, CDoom.snd_music_volume)
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
      CDoom.snd_music_volume -= 1 if CDoom.snd_music_volume > 0
    when 1
      CDoom.snd_music_volume += 1 if CDoom.snd_music_volume < 15
    end

    CDoom.s_set_music_volume(CDoom.snd_music_volume)
  end

  #
  # m_draw_mainmenu
  #
  def self.m_draw_mainmenu
    CDoom.v_draw_patch_direct(94, 2, 0, CDoom.w_cache_lump_name("M_DOOM", CDoom::PU_CACHE).as(CDoom::Patch*))
  end

  #
  # m_newgame
  #
  def self.m_draw_newgame
    CDoom.v_draw_patch_direct(96, 14, 0, CDoom.w_cache_lump_name("M_NEWG", CDoom::PU_CACHE).as(CDoom::Patch*))
    CDoom.v_draw_patch_direct(54, 38, 0, CDoom.w_cache_lump_name("M_SKILL", CDoom::PU_CACHE).as(CDoom::Patch*))
  end

  def self.m_new_game(choice : Int32)
    if CDoom.netgame != 0 && CDoom.demoplayback == 0
      m_start_message(@@deh_newgame, NULL_PROCP1, 0)
      return
    end

    if CDoom.gamemode == CDoom::GameMode::Commercial
      m_setup_next_menu(@@newdef)
    else
      m_setup_next_menu(@@epidef)
    end
  end

  #
  # m_episode
  #
  def self.m_draw_episode
    CDoom.v_draw_patch_direct(54, 38, 0, CDoom.w_cache_lump_name("M_EPISOD", CDoom::PU_CACHE).as(CDoom::Patch*))
  end

  def self.m_verify_nightmare(ch : Int32)
    return if ch != 'y'.ord

    CDoom.g_defered_init_new(CDoom::Skill::Nightmare, CDoom.epi + 1, 1)
    m_clear_menus
  end

  def self.m_choose_skill(choice : Int32)
    if choice == CDoom::Skill::Nightmare.value
      m_start_message(@@deh_nightmare, ->CDoom.m_verify_nightmare(Int32), 1)
      return
    end

    CDoom.g_defered_init_new(CDoom::Skill.new(choice), CDoom.epi + 1, 1)
    m_clear_menus
  end

  def self.m_episode(choice : Int32)
    if CDoom.gamemode == CDoom::GameMode::Shareware && choice != 0
      m_start_message(@@deh_swstring, NULL_PROCP1, 0)
      m_setup_next_menu(@@readdef1)
      return
    end

    # Yet another hack...
    if CDoom.gamemode == CDoom::GameMode::Registered && choice > 2
      puts "m_episode: 4th episode requires Ultimate DOOM"
      choice = 0
    end

    CDoom.epi = choice
    m_setup_next_menu(@@newdef)
  end

  #
  # m_options
  #
  def self.m_draw_options
    CDoom.v_draw_patch_direct(108, 15, 0, CDoom.w_cache_lump_name("M_OPTTTL", CDoom::PU_CACHE).as(CDoom::Patch*))

    CDoom.v_draw_patch_direct(@@optionsdef.x + 120, @@optionsdef.y + CDoom::LINEHEIGHT * CDoom::OptionsEnum::Messages.value, 0, CDoom.w_cache_lump_name(CDoom.msg_names[CDoom.show_messages], CDoom::PU_CACHE).as(CDoom::Patch*))

    m_draw_thermo(@@optionsdef.x, @@optionsdef.y + CDoom::LINEHEIGHT * (CDoom::OptionsEnum::Scrnsize.value + 1),
      9, CDoom.screen_size)

    m_draw_thermo(@@optionsdef.x, @@optionsdef.y + CDoom::LINEHEIGHT * (CDoom::OptionsEnum::Mousesensitivity.value + 1),
      10, CDoom.mouse_sensitivity)

    m_write_text(@@optionsdef.x, @@optionsdef.y +
                                 CDoom::LINEHEIGHT * CDoom::OptionsEnum::More.value + CDoom.hu_font[0].value.height // 2,
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
    CDoom.show_messages = 1 - CDoom.show_messages

    if CDoom.show_messages == 0
      (CDoom.players.to_unsafe + CDoom.consoleplayer).value.message = @@deh_msgoff
    else
      (CDoom.players.to_unsafe + CDoom.consoleplayer).value.message = @@deh_msgon
    end

    CDoom.message_dontfuckwithme = 1
  end

  def self.m_moreoptions(choice : Int32)
    m_setup_next_menu(@@moreoptions_def)
  end

  def self.m_draw_moreoptions
    CDoom.v_draw_patch_direct(108, 8, 0, CDoom.w_cache_lump_name("M_OPTTTL", CDoom::PU_CACHE).as(CDoom::Patch*))

    @@moreoptions_menus[@@current_options_menu].each_with_index do |item, i|
      m_write_text(@@moreoptions_def.x, @@moreoptions_def.y +
                                        CDoom::LINEHEIGHT * i + CDoom.hu_font[0].value.height // 2,
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

    CDoom::DoomKey.from_value?(key.value).try do |dkey|
      case dkey
      when CDoom::DoomKey::UNKNOWN
      when CDoom::DoomKey::TAB
        str = "TAB"
      when CDoom::DoomKey::ENTER
        str = "ENTER"
      when CDoom::DoomKey::ESCAPE
        str = "ESCAPE"
      when CDoom::DoomKey::SPACE
        str = "SPACE"
      when CDoom::DoomKey::BACKSPACE
        str = "BACKSPACE"
      when CDoom::DoomKey::CTRL
        str = "CTRL"
      when CDoom::DoomKey::LEFT_ARROW
        str = "LEFT ARROW"
      when CDoom::DoomKey::UP_ARROW
        str = "UP ARROW"
      when CDoom::DoomKey::RIGHT_ARROW
        str = "RIGHT ARROW"
      when CDoom::DoomKey::DOWN_ARROW
        str = "DOWN ARROW"
      when CDoom::DoomKey::SHIFT
        str = "SHIFT"
      when CDoom::DoomKey::ALT
        str = "ALT"
      when CDoom::DoomKey::F1
        str = "F1"
      when CDoom::DoomKey::F2
        str = "F2"
      when CDoom::DoomKey::F3
        str = "F3"
      when CDoom::DoomKey::F4
        str = "F4"
      when CDoom::DoomKey::F5
        str = "F5"
      when CDoom::DoomKey::F6
        str = "F6"
      when CDoom::DoomKey::F7
        str = "F7"
      when CDoom::DoomKey::F8
        str = "F8"
      when CDoom::DoomKey::F9
        str = "F0"
      when CDoom::DoomKey::F10
        str = "F10"
      when CDoom::DoomKey::F11
        str = "F11"
      when CDoom::DoomKey::F12
        str = "F12"
      when CDoom::DoomKey::PAUSE
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
                                                                 -CDoom::LINEHEIGHT + CDoom.hu_font[0].value.height // 2,
      "Controls")

    @@editcontrols_menu.each_with_index do |item, i|
      m_write_text(@@editcontrols_def.x, @@editcontrols_def.y +
                                         CDoom::LINEHEIGHT * i + CDoom.hu_font[0].value.height // 2,
        item.text + (item.num.null? ? "" : m_draw_key(item.num)))
    end
  end

  def self.m_edit_forward(choice : Int32)
    @@selected_edit = pointerof(CDoom.key_up)
  end

  def self.m_edit_backward(choice : Int32)
    @@selected_edit = pointerof(CDoom.key_down)
  end

  def self.m_edit_tleft(choice : Int32)
    @@selected_edit = pointerof(CDoom.key_left)
  end

  def self.m_edit_tright(choice : Int32)
    @@selected_edit = pointerof(CDoom.key_right)
  end

  def self.m_edit_sleft(choice : Int32)
    @@selected_edit = pointerof(CDoom.key_strafeleft)
  end

  def self.m_edit_sright(choice : Int32)
    @@selected_edit = pointerof(CDoom.key_straferight)
  end

  def self.m_edit_sprint(choice : Int32)
    @@selected_edit = pointerof(CDoom.key_speed)
  end

  def self.m_edit_shoot(choice : Int32)
    @@selected_edit = pointerof(CDoom.key_fire)
  end

  def self.m_edit_use(choice : Int32)
    @@selected_edit = pointerof(CDoom.key_use)
  end

  #
  # Toggle crosshair on/off
  #
  def self.m_change_crosshair(choice : Int32)
    # warning: unused parameter `choice : Int32'
    choice = 0
    CDoom.crosshair = 1 - CDoom.crosshair
  end

  #
  # Toggle always-run on/off
  #
  def self.m_change_alwaysrun(choice : Int32)
    # warning: unused parameter `choice : Int32'
    choice = 0
    CDoom.always_run = 1 - CDoom.always_run
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

    @@current_menu.last_on = CDoom.item_on
    m_clear_menus
    CDoom.d_start_title
  end

  def self.m_endgame(choice : Int32)
    choice = 0
    if CDoom.usergame == 0
      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_oof)
      return
    end

    if CDoom.netgame != 0
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
    if CDoom.netgame == 0
      if CDoom.gamemode == CDoom::GameMode::Commercial
        CDoom.s_start_sound(Pointer(Void).null, CDoom.quitsounds2[(CDoom.gametic >> 2) & 7])
      else
        CDoom.s_start_sound(Pointer(Void).null, CDoom.quitsounds[(CDoom.gametic >> 2) & 7])
      end
      CDoom.i_wait_vbl(105)
    end
    CDoom.i_quit
  end

  def self.m_quitdoom(choice : Int32)
    # We pick index 0 which is language sensitive,
    #  or one at random, between 1 and maximum number.
    string = ""
    if CDoom.language != CDoom::Language::English
      string = @@doom1_endmsg[0]
    else
      if CDoom.gamemode == CDoom::GameMode::Commercial
        string = @@doom2_endmsg.sample(Random.new(CDoom.gametime))
      else
        string = @@doom1_endmsg.sample(Random.new(CDoom.gametime))
      end
    end
    string += "\n\n(press y to quit)"

    m_start_message(string, ->CDoom.m_quit_response(Int32), 1)
  end

  def self.m_change_sensitivity(choice : Int32)
    case choice
    when 0
      CDoom.mouse_sensitivity -= 1 if CDoom.mouse_sensitivity > 0
    when 1
      CDoom.mouse_sensitivity += 1 if CDoom.mouse_sensitivity < 9
    end
  end

  def self.m_mouse_move(choice : Int32)
    choice = 0
    CDoom.mousemove = 1 - CDoom.mousemove
  end

  def self.m_size_display(choice : Int32)
    case choice
    when 0
      if CDoom.screen_size > 0
        CDoom.screenblocks -= 1
        CDoom.screen_size -= 1
      end
    when 1
      if CDoom.screen_size < 8
        CDoom.screenblocks += 1
        CDoom.screen_size += 1
      end
    end

    CDoom.r_set_view_size(CDoom.screenblocks, CDoom.detail_level)
  end

  #
  # Menu Methods
  #
  def self.m_draw_thermo(x : LibC::Int, y : LibC::Int, therm_width : LibC::Int, therm_dot : LibC::Int)
    xx = x
    CDoom.v_draw_patch_direct(xx, y, 0, CDoom.w_cache_lump_name("M_THERML", CDoom::PU_CACHE).as(CDoom::Patch*))
    xx += 8
    therm_width.times do |i|
      CDoom.v_draw_patch_direct(xx, y, 0, CDoom.w_cache_lump_name("M_THERMM", CDoom::PU_CACHE).as(CDoom::Patch*))
      xx += 8
    end
    CDoom.v_draw_patch_direct(xx, y, 0, CDoom.w_cache_lump_name("M_THERMR", CDoom::PU_CACHE).as(CDoom::Patch*))

    CDoom.v_draw_patch_direct((x + 8) + therm_dot * 8, y, 0, CDoom.w_cache_lump_name("M_THERMO", CDoom::PU_CACHE).as(CDoom::Patch*))
  end

  def self.m_draw_empty_cell(menu : CDoom::Menu*, item : Int32)
    CDoom.v_draw_patch_direct(menu.value.x - 10, menu.value.y + item * CDoom::LINEHEIGHT - 1, 0,
      CDoom.w_cache_lump_name("M_CELL1", CDoom::PU_CACHE).as(CDoom::Patch*))
  end

  def self.m_draw_selcell(menu : CDoom::Menu*, item : Int32)
    CDoom.v_draw_patch_direct(menu.value.x - 10, menu.value.y + item * CDoom::LINEHEIGHT - 1, 0,
      CDoom.w_cache_lump_name("M_CELL2", CDoom::PU_CACHE).as(CDoom::Patch*))
  end

  def self.m_start_message(string : String, routine : Proc(Int32, Nil), input : CDoom::DoomBool)
    CDoom.message_last_menu_active = CDoom.menuactive
    CDoom.message_to_print = 1
    CDoom.message_string = string
    CDoom.message_routine = routine
    CDoom.message_needs_input = input
    CDoom.menuactive = 1
  end

  def self.m_stop_message
    CDoom.menuactive = CDoom.message_last_menu_active
    CDoom.message_to_print = 0
  end

  #
  # Find string width from hu_font chars
  #
  def self.m_string_width(string : String) : Int32
    w = 0

    string.each_char do |c|
      c = c.upcase.ord - CDoom::HU_FONTSTART
      if c < 0 || c >= CDoom::HU_FONTSIZE
        w += 4
      else
        w += CDoom.hu_font[c].value.width.to_i16!
      end
    end

    return w
  end

  #
  # Find string height from hu_font chars
  #
  def self.m_string_height(string : UInt8*) : Int32
    height = CDoom.hu_font[0].value.height.to_i16!.to_i32

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

      c = c.upcase.ord - CDoom::HU_FONTSTART
      if c < 0 || c >= CDoom::HU_FONTSIZE
        cx += 4
        next
      end

      w = CDoom.hu_font[c].value.width.to_i16!
      break if cx + w > CDoom::SCREENWIDTH
      CDoom.v_draw_patch_direct(cx, cy, 0, CDoom.hu_font[c])
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
  def self.m_responder(ev : CDoom::Event*) : CDoom::DoomBool
    ch = -1

    if ev.value.type == CDoom::Evtype::Joystick && @@joywait < CDoom.i_get_time
      if ev.value.data3 == -1
        ch = CDoom::KEY_UPARROW
        @@joywait = CDoom.i_get_time + 5
      elsif ev.value.data3 == 1
        ch = CDoom::KEY_DOWNARROW
        @@joywait = CDoom.i_get_time + 5
      end

      if ev.value.data2 == -1
        ch = CDoom::KEY_LEFTARROW
        @@joywait = CDoom.i_get_time + 2
      elsif ev.value.data2 == 1
        ch = CDoom::KEY_RIGHTARROW
        @@joywait = CDoom.i_get_time + 2
      end

      if ev.value.data1 & 1 != 0
        ch = CDoom::KEY_ENTER
        @@joywait = CDoom.i_get_time + 5
      end
      if ev.value.data1 & 2 != 0
        ch = CDoom::KEY_BACKSPACE
        @@joywait = CDoom.i_get_time + 5
      end
    else
      if ev.value.type == CDoom::Evtype::Mouse && @@mousewait < CDoom.i_get_time
        @@menumousey += ev.value.data3

        if @@menumousey < @@lasty - MENU_SCROLL_DEADZONE
          ch = CDoom::KEY_DOWNARROW
          @@mousewait = CDoom.i_get_time + 5
          @@lasty -= MENU_SCROLL_DEADZONE
          @@menumousey = @@lasty
        elsif @@menumousey > @@lasty + MENU_SCROLL_DEADZONE
          ch = CDoom::KEY_UPARROW
          @@mousewait = CDoom.i_get_time + 5
          @@lasty += MENU_SCROLL_DEADZONE
          @@menumousey = @@lasty
        end

        @@menumousex += ev.value.data2
        if @@menumousex < @@lastx - MENU_SCROLL_DEADZONE
          ch = CDoom::KEY_LEFTARROW
          @@mousewait = CDoom.i_get_time + 5
          @@lastx -= MENU_SCROLL_DEADZONE
          @@menumousex = @@lastx
        elsif @@menumousex > @@lastx + MENU_SCROLL_DEADZONE
          ch = CDoom::KEY_RIGHTARROW
          @@mousewait = CDoom.i_get_time + 5
          @@lastx += MENU_SCROLL_DEADZONE
          @@menumousex = @@lastx
        end

        if ev.value.data1 & 2 != 0
          ch = CDoom::KEY_BACKSPACE
          @@mousewait = CDoom.i_get_time + 15
        elsif ev.value.data1 & 1 != 0
          ch = CDoom::KEY_ENTER
          @@mousewait = CDoom.i_get_time + 15
        end
      else
        ch = ev.value.data1 if ev.value.type == CDoom::Evtype::Keydown
      end
    end

    return 0 if ch == -1

    # Edit selected control
    if !@@selected_edit.null?
      unless CDoom::DoomKey.from_value?(ch).nil?
        @@selected_edit.value = ch
        @@selected_edit = Pointer(Int32).null
        return 1
      end
    end

    # Save Game string input
    if CDoom.save_string_enter != 0
      case ch
      when CDoom::KEY_BACKSPACE
        if @@savegamestrings[CDoom.save_slot].size > 0
          @@savegamestrings[CDoom.save_slot] = @@savegamestrings[CDoom.save_slot].rchop
        end
      when CDoom::KEY_ESCAPE
        CDoom.save_string_enter = 0
        @@savegamestrings[CDoom.save_slot] = @@save_old_string
      when CDoom::KEY_ENTER
        CDoom.save_string_enter = 0
        CDoom.m_do_save(CDoom.save_slot) # if CDoom.savegamestrings[CDoom.save_slot][0] != 0 allows empty saves
      else
        ch = CDoom.doom_toupper(ch)
        unless ch != 32 && (ch - CDoom::HU_FONTSTART < 0 || ch - CDoom::HU_FONTSTART >= CDoom::HU_FONTSIZE)
          if ch >= 32 && ch <= 127 &&
             @@savegamestrings[CDoom.save_slot].size < CDoom::SAVESTRINGSIZE - 1 &&
             m_string_width(@@savegamestrings[CDoom.save_slot]) <
               (CDoom::SAVESTRINGSIZE - 2) * 8
            @@savegamestrings[CDoom.save_slot] += ch.chr
          end
        end
      end

      return 1
    end

    # Take care of any messages that need input
    if CDoom.message_to_print != 0
      return 0 if CDoom.message_needs_input != 0 &&
                  !(ch == ' '.ord || ch == 'n'.ord || ch == 'y'.ord || ch == CDoom::KEY_ESCAPE)

      CDoom.menuactive = CDoom.message_last_menu_active
      CDoom.message_to_print = 0
      CDoom.message_routine.call(ch) unless CDoom.message_routine.pointer.null?

      CDoom.menuactive = 0
      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchx)
      return 1
    end

    if CDoom.devparm != 0 && ch == CDoom::KEY_F1
      CDoom.g_screenshot
      return 1
    end

    # F-Keys
    if CDoom.menuactive == 0
      case ch
      when CDoom::KEY_MINUS # Screen size down
        return 0 if CDoom.automapactive != 0 || CDoom.chat_on != 0
        m_size_display(0)
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_stnmov)
        return 1
      when CDoom::KEY_EQUALS # Screen size up
        return 0 if CDoom.automapactive != 0 || CDoom.chat_on != 0
        m_size_display(1)
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_stnmov)
        return 1
      when CDoom::KEY_F1 # Help key
        CDoom.m_start_control_panel

        @@current_menu = @@readdef1

        CDoom.item_on = 0
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchn)
        return 1
      when CDoom::KEY_F2 # Save
        CDoom.m_start_control_panel
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchn)
        m_save_game(0)
        return 1
      when CDoom::KEY_F3 # Load
        CDoom.m_start_control_panel
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchn)
        m_load_game(0)
        return 1
      when CDoom::KEY_F4 # Sound Volume
        CDoom.m_start_control_panel
        @@current_menu = @@sounddef
        CDoom.item_on = CDoom::Soundenum::Sfxvol
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchn)
        return 1
      when CDoom::KEY_F5
        CDoom.m_start_control_panel
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchn)
        m_moreoptions(0)
        return 1
      when CDoom::KEY_F6 # Quicksave
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchn)
        m_quicksave
        return 1
      when CDoom::KEY_F7 # End game
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchn)
        m_endgame(0)
        return 1
      when CDoom::KEY_F8 # Toggle messages
        m_change_messages(0)
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchn)
        return 1
      when CDoom::KEY_F9 # Quickload
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchn)
        m_quickload
        return 1
      when CDoom::KEY_F10 # Quit DOOM
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchn)
        m_quitdoom(0)
        return 1
      when CDoom::KEY_F11 # gamma toggle
        CDoom.usegamma += 1
        CDoom.usegamma = 0 if CDoom.usegamma > 4
        (CDoom.players.to_unsafe + CDoom.consoleplayer).value.message = CDoom.gammamsg[CDoom.usegamma]
        CDoom.i_set_palette(CDoom.w_cache_lump_name("PLAYPAL", CDoom::PU_CACHE).as(UInt8*))
        return 1
      end
    end

    # Pop-up menu?
    if CDoom.menuactive == 0
      if ch == CDoom::KEY_ESCAPE
        CDoom.m_start_control_panel
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchn)
        return 1
      end
      return 0
    end

    # Keys usable within menu
    case ch
    when CDoom::KEY_DOWNARROW
      loop do
        CDoom.item_on = CDoom.item_on + 1 > @@current_menu.menuitems.size - 1 ? 0 : CDoom.item_on + 1
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_pstop)
        break unless @@current_menu.menuitems[CDoom.item_on].status == -1
      end
      return 1
    when CDoom::KEY_UPARROW
      loop do
        CDoom.item_on = CDoom.item_on == 0 ? @@current_menu.menuitems.size - 1 : CDoom.item_on - 1
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_pstop)
        break unless @@current_menu.menuitems[CDoom.item_on].status == -1
      end
      return 1
    when CDoom::KEY_LEFTARROW
      if !@@current_menu.menuitems[CDoom.item_on].routine.pointer.null? &&
         @@current_menu.menuitems[CDoom.item_on].status == 2
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_stnmov)
        @@current_menu.menuitems[CDoom.item_on].routine.call(0)
      end
      return 1
    when CDoom::KEY_RIGHTARROW
      if !@@current_menu.menuitems[CDoom.item_on].routine.pointer.null? &&
         @@current_menu.menuitems[CDoom.item_on].status == 2
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_stnmov)
        @@current_menu.menuitems[CDoom.item_on].routine.call(1)
      end
      return 1
    when CDoom::KEY_ENTER
      if !@@current_menu.menuitems[CDoom.item_on].routine.pointer.null? &&
         @@current_menu.menuitems[CDoom.item_on].status != 0
        @@current_menu.last_on = CDoom.item_on
        if @@current_menu.menuitems[CDoom.item_on].status == 2
          @@current_menu.menuitems[CDoom.item_on].routine.call(1)
          CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_stnmov)
        else
          @@current_menu.menuitems[CDoom.item_on].routine.call(CDoom.item_on.to_i32)
          CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_pistol)
        end
      end
      return 1
    when CDoom::KEY_ESCAPE
      @@current_menu.last_on = CDoom.item_on
      m_clear_menus
      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchx)
      return 1
    when CDoom::KEY_BACKSPACE
      @@current_menu.last_on = CDoom.item_on
      if prev = @@current_menu.prev_menu
        @@current_menu = prev
        CDoom.item_on = @@current_menu.last_on
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchn)
      end
      return 1
    else
      i = CDoom.item_on + 1
      while i < @@current_menu.menuitems.size
        if @@current_menu.menuitems[i].alpha_key == ch.chr
          CDoom.item_on = i
          CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_pstop)
          return 1
        end
        i += 1
      end
      (CDoom.item_on + 1).times do |i|
        if @@current_menu.menuitems[i].alpha_key == ch.chr
          CDoom.item_on = i
          CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_pstop)
          return 1
        end
      end
    end

    return 0
  end

  def self.m_start_control_panel
    # intro might call this repeatedly
    return if CDoom.menuactive != 0

    CDoom.menuactive = 1
    @@current_menu = @@maindef             # JDC
    CDoom.item_on = @@current_menu.last_on # JDC
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
    CDoom.inhelpscreens = 0

    # Horiz. & Vertically center string and print it.
    if CDoom.message_to_print != 0
      start = 0
      @@y = 100 - m_string_height(CDoom.message_string) // 2
      while (CDoom.message_string + start).value != 0
        i = 0
        while i < CDoom.doom_strlen(CDoom.message_string + start)
          if (CDoom.message_string + start + i).value == '\n'.ord
            string = String.new(CDoom.message_string + start, i)
            start += i + 1
            break
          end
          i += 1
        end

        if i == CDoom.doom_strlen(CDoom.message_string + start)
          string = String.new(CDoom.message_string + start)
          start += i
        end

        @@x = 160 - m_string_width(string) // 2
        m_write_text(@@x, @@y, string)
        @@y += CDoom.hu_font[0].value.height.to_i16!
      end
      return
    end

    return if CDoom.menuactive == 0

    # Darken background so the menu is more readable.
    @@current_menu.routine.call unless @@current_menu.routine.pointer.null?

    # DRAW MENU
    @@x = @@current_menu.x.to_i32
    @@y = @@current_menu.y.to_i32
    max = @@current_menu.menuitems.size
    max.times do |i|
      menuitem = @@current_menu.menuitems[i]

      unless menuitem.name.empty?
        CDoom.v_draw_patch_direct(@@x, @@y, 0, CDoom.w_cache_lump_name(menuitem.name, CDoom::PU_CACHE).as(CDoom::Patch*))
      end
      @@y += CDoom::LINEHEIGHT
    end

    # DRAW SKULL
    CDoom.v_draw_patch_direct(@@x + CDoom::SKULLXOFF, @@current_menu.y - 5 + CDoom.item_on * CDoom::LINEHEIGHT, 0,
      CDoom.w_cache_lump_name(CDoom.skull_name[CDoom.which_skull], CDoom::PU_CACHE).as(CDoom::Patch*))
  end

  def self.m_clear_menus
    CDoom.menuactive = 0
  end

  def self.m_setup_next_menu(menudef : Menu)
    @@current_menu = menudef
    CDoom.item_on = @@current_menu.last_on
  end

  def self.m_ticker
    CDoom.skull_anim_counter &-= 1
    if CDoom.skull_anim_counter <= 0
      CDoom.which_skull ^= 1
      CDoom.skull_anim_counter = 8
    end
  end

  def self.m_init
    @@current_menu = @@maindef
    CDoom.menuactive = 0
    CDoom.item_on = @@current_menu.last_on
    CDoom.which_skull = 0
    CDoom.skull_anim_counter = 10
    CDoom.screen_size = CDoom.screenblocks - 3
    CDoom.message_to_print = 0
    CDoom.message_string = Pointer(UInt8).null
    CDoom.message_last_menu_active = CDoom.menuactive
    CDoom.quick_save_slot = -1

    # Here we could catch other version dependencies,
    #  like HELP1/2, and four episodes.

    case CDoom.gamemode
    when CDoom::GameMode::Commercial
      # Setup read menu for Doom II
      @@mainmenu[CDoom::Mainenum::Readthis.value] = @@mainmenu[CDoom::Mainenum::Quitdoom.value]
      @@maindef.menuitems.pop
      @@maindef.y = @@maindef.y + 8
      @@newdef.prev_menu = @@maindef
      @@readdef1.routine = ->m_draw_commercial
      @@readdef1.x = 330
      @@readdef1.y = 165
      @@readmenu1.to_unsafe.value.routine = ->m_finish_readthis(Int32)
    when CDoom::GameMode::Retail
      # Skip first menu on Ultimate Doom
      pointerof(@@readdef1).value = @@readdef2
    when CDoom::GameMode::Shareware, CDoom::GameMode::Registered
      # Episode 2 and 3 are handled,
      #  branching to an ad screen.
      #
      # We need to remove the fourth episode.
      @@epidef.menuitems.pop
    end
  end

  def self.m_draw_text(x : Int32, y : Int32, direct : CDoom::DoomBool, string : LibC::Char*) : LibC::Int
    while string.value != 0
      c = CDoom.doom_toupper(string.value) - CDoom::HU_FONTSTART
      string += 1
      if c < 0 || c > CDoom::HU_FONTSIZE
        x += 4
        next
      end

      w = CDoom.hu_font[c].value.width.to_i16!.to_i32
      break if x + w > CDoom::SCREENWIDTH
      if direct != 0
        CDoom.v_draw_patch_direct(x, y, 0, CDoom.hu_font[c])
      else
        CDoom.v_draw_patch(x, y, 0, CDoom.hu_font[c])
      end
      x += w
    end

    return x
  end

  def self.m_write_file(name : LibC::Char*, source : Void*, length : LibC::Int) : CDoom::DoomBool
    handle = doom_open(name, "wb".to_unsafe)

    return 0 if handle.null?

    count = doom_write(handle, source, length)
    doom_close(handle)

    return 0 if count < length

    return 1
  end

  def self.m_read_file(name : LibC::Char*, buffer : CDoom::Byte**) : LibC::Int
    handle = doom_open(name, "rb".to_unsafe)
    if handle.null?
      CDoom.i_error("Error: Couldn't read file #{name}")
    end
    doom_seek(handle, 0, CDoom::DoomSeek::DOOM_SEEK_END)
    length = doom_tell(handle)
    doom_seek(handle, 0, CDoom::DoomSeek::DOOM_SEEK_SET)
    buf = CDoom.z_malloc(length, CDoom::PU_STATIC, Pointer(Void).null)
    count = doom_read(handle, buf, length)
    doom_close(handle)

    if count < length
      CDoom.i_error("Error: Couldn't read file #{name}")
    end

    buffer.value = buf.as(UInt8*)
    return length
  end

  def self.m_save_defaults
    f = doom_open(CDoom.defaultfile, "w".to_unsafe)
    return if f.null? # can't write the file, but don't complain

    @@defaults.size.times do |i|
      if @@defaults[i].defaultvalue > -0xfff &&
         @@defaults[i].defaultvalue < 0xfff
        v = @@defaults[i].location.value
        CDoom.doom_fprint(f, @@defaults[i].name)
        CDoom.doom_fprint(f, "\t\t")
        CDoom.doom_fprint(f, CDoom.doom_itoa(v, 10))
        CDoom.doom_fprint(f, "\n")
      else
        CDoom.doom_fprint(f, @@defaults[i].name)
        CDoom.doom_fprint(f, "\t\t\"")
        CDoom.doom_fprint(f, @@defaults[i].text_location.as(UInt8**).value)
        CDoom.doom_fprint(f, "\"\n")
      end
    end

    doom_close(f)
  end

  def self.m_load_defaults
    defa = uninitialized StaticArray(UInt8, 80)
    strparm = uninitialized StaticArray(UInt8, 100)

    @@defaults.size.times do |i|
      if @@defaults[i].defaultvalue == 0xffff
        @@defaults[i].text_location.value = @@defaults[i].default_text_value
      else
        @@defaults[i].location.value = @@defaults[i].defaultvalue.to_i32!
      end
    end

    # check for a custom default file
    i = ARGV.index("-config")
    if i && i < ARGV.size - 1
      CDoom.defaultfile = ARGV[i + 1]
      puts "        default file: #{String.new(CDoom.defaultfile)}"
    else
      CDoom.defaultfile = CDoom.basedefault
    end

    # read the file in, overriding any set defaults
    f = doom_open(CDoom.defaultfile, "r".to_unsafe)
    unless f.null?
      while doom_eof(f) == 0
        arg_read = 0
        c = 0_u8
        i = 0
        while i < 79
          doom_read(f, pointerof(c).as(Void*), 1)
          if c == ' '.ord || c == '\n'.ord || c == '\t'.ord
            arg_read += 1 if i > 0
            break
          end
          defa[i] = c
          i += 1
        end
        defa[i] = '\0'.ord.to_u8

        # Ignore spaces
        if c != '\n'.ord
          loop do
            doom_read(f, pointerof(c).as(Void*), 1)
            break if c != ' '.ord && c != '\t'.ord
          end

          # strparam
          i = 0
          if c != '\n'.ord
            while i < 260
              strparm[i] = c
              i += 1
              doom_read(f, pointerof(c).as(Void*), 1)
              if c == '\n'.ord
                arg_read += 1 if i > 0
                break
              end
            end
          end
          strparm[i] = '\0'.ord.to_u8
        end

        isstring = false
        parm = 0
        newstring = Pointer(UInt8).null

        if arg_read == 2
          if strparm[0] == '"'.ord
            # get a string default
            isstring = true
            len = CDoom.doom_strlen(strparm).to_i32!
            newstring = GC.malloc(len).as(UInt8*)
            strparm[len - 1] = 0
            CDoom.doom_strcpy(newstring, strparm.to_unsafe + 1)
          elsif strparm[0] == '0'.ord && strparm[1] == 'x'.ord
            parm = CDoom.doom_atox(strparm.to_unsafe + 2)
          else
            parm = CDoom.doom_atoi(strparm.to_unsafe)
          end
          @@defaults.size.times do |i|
            if CDoom.doom_strcmp(defa, @@defaults[i].name) == 0
              if !isstring
                @@defaults[i].location.value = parm
              else
                @@defaults[i].text_location.value = newstring
              end
              break
            end
          end
        end
      end

      doom_close(f)
    end
  end

  def self.write_pcx_file(filename : LibC::Char*, data : CDoom::Byte*, width : LibC::Int, height : LibC::Int, palette : CDoom::Byte*)
    pcx = CDoom.z_malloc(width * height * 2 + 1000, CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::PCX*)

    pcx.value.manufacturer = 0x0a # PCX id
    pcx.value.version = 5         # 256 color
    pcx.value.encoding = 1        # uncompressed
    pcx.value.bits_per_pixel = 8  # 256 color
    pcx.value.xmin = 0
    pcx.value.ymin = 0
    pcx.value.xmax = (width - 1).to_i16!
    pcx.value.ymax = (height - 1).to_i16!
    pcx.value.hres = width.to_i16!
    pcx.value.vres = height.to_i16!
    CDoom.doom_memset(pcx.value.palette.to_unsafe, 0, sizeof(typeof(pcx.value.palette)))
    pcx.value.color_planes = 1 # chunky image
    pcx.value.bytes_per_line = width.to_i16!
    pcx.value.palette_type = 2_i16 # not a grey scale
    CDoom.doom_memset(pcx.value.filler.to_unsafe, 0, sizeof(typeof(pcx.value.filler)))

    # pack the image
    pack = pointerof(pcx.value.@data)

    (width * height).times do |i|
      if (data.value & 0xc0) != 0xc0
        pack.value = data.value
        pack += 1
        data += 1
      else
        pack.value = 0xc1
        pack += 1
        pack.value = data.value
        pack += 1
        data += 1
      end
    end

    # write the palette
    pack.value = 0x0c # palette ID byte
    pack += 1
    768.times do |i|
      pack.value = palette.value
      pack += 1
      palette += 1
    end

    # write output file
    length = (pack - pcx.as(UInt8*)).to_i32!
    CDoom.m_write_file(filename, pcx, length)

    CDoom.z_free(pcx)
  end

  def self.m_screenshot
    lbmname = uninitialized StaticArray(UInt8, 12)

    # munge planar buffer to linear
    linear = CDoom.screens[2]
    CDoom.i_read_screen(linear)

    # find a file name to save it to
    CDoom.doom_strcpy(lbmname, "DOOM00.pcx")
    i = 0
    while i < 99
      lbmname[4] = (i // 10 + '0'.ord).to_u8!
      lbmname[5] = (i % 10 + '0'.ord).to_u8!
      if (f = doom_open(lbmname.to_unsafe, "r".to_unsafe)).null?
        break # file doesn't exist
      end
      doom_close(f)
      i += 1
    end
    CDoom.i_error("Error: m_screenshot: Couldn't create a PCX") if i == 100

    # save the pcs file
    CDoom.write_pcx_file(lbmname, linear,
      CDoom::SCREENWIDTH, CDoom::SCREENHEIGHT,
      CDoom.w_cache_lump_name("PLAYPAL", CDoom::PU_CACHE).as(UInt8*))

    (CDoom.players.to_unsafe + CDoom.consoleplayer).value.message = "screen shot"
  end
end
