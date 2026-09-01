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
# ==> Every method of DOOM

# The majority of this file will be rewritten to be modernized,
# Crystalized, and overall improved (changed to be how I want it lol)
#
# A lot of this should scare you. It sure scared me.
# 99% of this is one to one with C, specifically PureDoom.
# I reworked a lot of stuff already but even then the first line
#  in this module is still a null pointer... so... it needs more work :)

module Doocr
  NULL_PROC   = Proc(Nil).new(Pointer(Void).null, Pointer(Void).null)
  NULL_PROCP1 = Proc(Int32, Nil).new(Pointer(Void).null, Pointer(Void).null)

  alias DoomHandle = {String, IO::Memory, Bool} # path, buffer, write_mode

  def self.open(filename : String, mode : String) : IO
    response = Channel({Bytes, Bool}).new
    @@io_jobs.send({filename, "rb", nil, response})
    data, ok = response.receive
    return IO::Memory.new(data)
  end

  def self.open(filename : String, mode : String, &)
    yield open(filename, mode)
  end

  def self.doom_open(filename : UInt8*, mode : UInt8*) : Void*
    path = String.new(filename)
    m = String.new(mode)
    write_mode = m.includes?('w') || m.includes?('a')
    begin
      if write_mode
        return Box.box({path, IO::Memory.new, true})
      else
        response = Channel({Bytes, Bool}).new
        @@io_jobs.send({path, "rb", nil, response})
        data, ok = response.receive
        return Pointer(Void).null unless ok
        return Box.box({path, IO::Memory.new(data), false})
      end
    rescue
    end
    return Pointer(Void).null
  end

  def self.doom_close(handle : Void*)
    path, io, write_mode = Box(DoomHandle).unbox(handle)
    return unless write_mode

    response = Channel({Bytes, Bool}).new
    @@io_jobs.send({path, "wb", io.to_slice, response})
    response.receive
  end

  def self.doom_read(handle : Void*, buf : Void*, count : Int32) : Int32
    slice = Slice.new(buf.as(UInt8*), count)
    _, io, _ = Box(DoomHandle).unbox(handle)
    return io.read(slice)
  end

  def self.doom_write(handle : Void*, buf : Void*, count : Int32) : Int32
    slice = Slice.new(buf.as(UInt8*), count)
    _, io, _ = Box(DoomHandle).unbox(handle)
    io.write(slice)
    return count
  end

  def self.doom_seek(handle : Void*, offset : Int32, origin : CDoom::DoomSeek) : Int32
    _, io, _ = Box(DoomHandle).unbox(handle)
    begin
      io.seek(offset, IO::Seek.from_value(origin.value))
    rescue
      return 1
    end
    return 0
  end

  def self.doom_tell(handle : Void*) : Int32
    _, io, _ = Box(DoomHandle).unbox(handle)
    return io.pos.to_i32
  end

  def self.doom_eof(handle : Void*) : Int32
    _, io, _ = Box(DoomHandle).unbox(handle)
    return io.pos >= io.size ? 1 : 0
  end

  def self.doom_memset(ptr : Void*, value : Int32, num : Int32)
    ptr.as(UInt8*).fill(num, value.to_u8!)
  end

  def self.doom_memcpy(destination : Void*, source : Void*, num : Int32) : Void*
    destination.as(UInt8*).copy_from(source.as(UInt8*), num)
    return destination
  end

  def self.doom_strlen(str : UInt8*) : Int32
    return String.new(str).size
  end

  def self.doom_concat(dst : UInt8*, src : UInt8*) : UInt8*
    concat = String.new(dst) + String.new(src)
    concat.to_slice.copy_to(dst, concat.bytesize)
    dst[concat.bytesize] = 0
    return dst
  end

  def self.doom_strcpy(dst : UInt8*, src : UInt8*) : UInt8*
    cpy = String.new(src)
    cpy.to_slice.copy_to(dst, cpy.bytesize)
    dst[cpy.bytesize] = 0
    return dst
  end

  def self.doom_strncpy(dst : UInt8*, src : UInt8*, num : Int32) : UInt8*
    len = doom_strlen(src) < num ? doom_strlen(src) : num
    diff = num - len
    dst.copy_from(src, len)
    (dst + len).fill(diff, 0_u8)
    return dst
  end

  def self.doom_strcmp(str1 : UInt8*, str2 : UInt8*) : Int32
    return str1.memcmp(str2, doom_strlen(str1) + 1).clamp(-1, 1)
  end

  def self.doom_strncmp(str1 : UInt8*, str2 : UInt8*, n : Int32) : Int32
    n.times do |i|
      c1 = str1[i]
      c2 = str2[i]
      return (c1.to_i32 - c2.to_i32).clamp(-1, 1) if c1 != c2
      return 0 if c1 == 0
    end
    return 0
  end

  def self.doom_toupper(c : Int32) : Int32
    return c - 'a'.ord + 'A'.ord if c >= 'a'.ord && c <= 'z'.ord
    return c
  end

  def self.doom_strcasecmp(str1 : UInt8*, str2 : UInt8*) : Int32
    return String.new(str1).compare(String.new(str2), case_insensitive: true)
  end

  def self.doom_strncasecmp(str1 : UInt8*, str2 : UInt8*, n : Int32) : Int32
    n.times do |i|
      c1 = doom_toupper(str1[i].to_i32)
      c2 = doom_toupper(str2[i].to_i32)
      return (c1 - c2).clamp(-1, 1) if c1 != c2
      return 0 if c1 == 0
    end
    return 0
  end

  def self.doom_atoi(str : UInt8*) : Int32
    String.new(str).to_i?(strict: false).try { |i| return i }
    return 0
  end

  def self.doom_atox(str : UInt8*) : Int32
    String.new(str).to_i?(base: 16, strict: false).try { |i| return i }
    return 0
  end

  def self.doom_itoa(k : Int32, radix : Int32) : UInt8*
    a = k.to_s(radix)
    a.to_slice.copy_to(CDoom.itoa_buf.to_unsafe, a.bytesize)
    CDoom.itoa_buf[a.bytesize] = 0
    return CDoom.itoa_buf.to_unsafe
  end

  def self.doom_ctoa(c : UInt8) : UInt8*
    CDoom.itoa_buf[0] = c
    CDoom.itoa_buf[1] = 0
    return CDoom.itoa_buf.to_unsafe
  end

  def self.doom_ptoa(p : Void*) : UInt8*
    a = "0x" + p.address.to_s(16).upcase
    a.to_slice.copy_to(CDoom.itoa_buf.to_unsafe, a.bytesize)
    CDoom.itoa_buf[a.bytesize] = 0
    return CDoom.itoa_buf.to_unsafe
  end

  def self.doom_fprint(handle : Void*, str : UInt8*) : Int32
    return doom_write(handle, str.as(Void*), doom_strlen(str))
  end

  def self.doom_init
    CDoom.screen_buffer = GC.malloc(CDoom::SCREENWIDTH * CDoom::SCREENHEIGHT).as(UInt8*)
    CDoom.final_screen_buffer = GC.malloc(CDoom::SCREENWIDTH * CDoom::SCREENHEIGHT * 4).as(UInt8*)
    CDoom.last_update_time = CDoom.i_get_time

    d_doom_main
  end

  def self.fixed_mul(a : CDoom::Fixed, b : CDoom::Fixed) : CDoom::Fixed
    return ((a.to_i64 * b.to_i64) >> FRACBITS).to_i32!
  end

  def self.fixed_div(a : CDoom::Fixed, b : CDoom::Fixed) : CDoom::Fixed
    return (a ^ b) < 0 ? Int32::MIN : Int32::MAX if (doom_abs(a) >> 14) >= doom_abs(b)
    return CDoom.fixed_div2(a, b)
  end

  def self.fixed_div2(a : CDoom::Fixed, b : CDoom::Fixed) : CDoom::Fixed
    c = (a.to_f64 / b.to_f64) * FRACUNIT

    CDoom.i_error("Error: fixed_div: divide by zero") if c >= 2147483648.0 || c < -2147483648.0
    return c.to_i32!
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
    Raylib.toggle_borderless_windowed
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

  # Which one is deterministic?
  def self.p_random : Int32
    CDoom.prndindex = (CDoom.prndindex + 1) & 0xff
    return CDoom.rndtable[CDoom.prndindex].to_i32
  end

  def self.m_random : Int32
    CDoom.rndindex = (CDoom.rndindex + 1) & 0xff
    return CDoom.rndtable[CDoom.rndindex].to_i32
  end

  def self.m_clear_random
    CDoom.rndindex = 0
    CDoom.prndindex = 0
  end

  def self.t_move_ceiling(ceiling : CDoom::Ceiling*)
    case ceiling.value.direction
    when 0
      # IN STASIS
    when 1
      # UP
      res = CDoom.t_move_plane(ceiling.value.sector,
        ceiling.value.speed,
        ceiling.value.topheight,
        0, 1, ceiling.value.direction)

      if (CDoom.leveltime & 7) == 0
        case ceiling.value.type
        when CDoom::Ceilingenum::SilentCrushAndRaise
        else
          CDoom.s_start_sound(pointerof(ceiling.value.sector.value.@soundorg),
            CDoom::Sfxenum::SFX_stnmov)
        end
      end

      if res == CDoom::Result::Pastdest
        case ceiling.value.type
        when CDoom::Ceilingenum::RaiseToHighest
          CDoom.p_remove_active_ceiling(ceiling)
        when CDoom::Ceilingenum::SilentCrushAndRaise
          CDoom.s_start_sound(pointerof(ceiling.value.sector.value.@soundorg),
            CDoom::Sfxenum::SFX_pstop)
        when CDoom::Ceilingenum::FastCrushAndRaise, CDoom::Ceilingenum::CrushAndRaise
          ceiling.value.direction = -1
        end
      end
    when -1
      # DOWN
      res = CDoom.t_move_plane(ceiling.value.sector,
        ceiling.value.speed,
        ceiling.value.bottomheight,
        ceiling.value.crush, 1, ceiling.value.direction)

      if (CDoom.leveltime & 7) == 0
        case ceiling.value.type
        when CDoom::Ceilingenum::SilentCrushAndRaise
        else
          CDoom.s_start_sound(pointerof(ceiling.value.sector.value.@soundorg),
            CDoom::Sfxenum::SFX_stnmov)
        end
      end

      if res == CDoom::Result::Pastdest
        case ceiling.value.type
        when CDoom::Ceilingenum::SilentCrushAndRaise
          CDoom.s_start_sound(pointerof(ceiling.value.sector.value.@soundorg),
            CDoom::Sfxenum::SFX_pstop)
        when CDoom::Ceilingenum::CrushAndRaise
          ceiling.value.speed = CDoom::CEILSPEED
        when CDoom::Ceilingenum::FastCrushAndRaise
          ceiling.value.direction = 1
        when CDoom::Ceilingenum::LowerAndCrush, CDoom::Ceilingenum::LowerToFloor
          CDoom.p_remove_active_ceiling(ceiling)
        end
      else
        if res == CDoom::Result::Crushed
          case ceiling.value.type
          when CDoom::Ceilingenum::SilentCrushAndRaise, CDoom::Ceilingenum::CrushAndRaise, CDoom::Ceilingenum::LowerAndCrush
            ceiling.value.speed = CDoom::CEILSPEED // 8
          end
        end
      end
    end
  end

  #
  # Move a ceiling up/down and all around!
  #
  def self.ev_do_ceiling(line : CDoom::Line*, type : CDoom::Ceilingenum) : LibC::Int
    secnum = -1
    rtn = 0

    # Reactivate in-stasis ceilings...for cetain types.
    case type
    when CDoom::Ceilingenum::FastCrushAndRaise, CDoom::Ceilingenum::SilentCrushAndRaise, CDoom::Ceilingenum::CrushAndRaise
      CDoom.p_activate_in_stasis_ceiling(line)
    end

    while (secnum = CDoom.p_find_sector_from_line_tag(line, secnum)) >= 0
      sec = CDoom.sectors + secnum
      next unless sec.value.specialdata.null?

      # new door thinker
      rtn = 1
      ceiling = CDoom.z_malloc(sizeof(CDoom::Ceiling), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Ceiling*)
      CDoom.p_add_thinker(pointerof(ceiling.value.@thinker))
      sec.value.specialdata = ceiling
      pointerof(ceiling.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_move_ceiling).pointer, Pointer(Void).null)
      ceiling.value.sector = sec
      ceiling.value.crush = 0

      case type
      when CDoom::Ceilingenum::FastCrushAndRaise
        ceiling.value.crush = 1
        ceiling.value.topheight = sec.value.ceilingheight
        ceiling.value.bottomheight = sec.value.floorheight + (8 * FRACUNIT)
        ceiling.value.direction = -1
        ceiling.value.speed = CDoom::CEILSPEED * 2
      when CDoom::Ceilingenum::SilentCrushAndRaise, CDoom::Ceilingenum::CrushAndRaise
        ceiling.value.crush = 1
        ceiling.value.topheight = sec.value.ceilingheight
      when CDoom::Ceilingenum::LowerAndCrush, CDoom::Ceilingenum::LowerToFloor
        ceiling.value.bottomheight = sec.value.floorheight
        if type != CDoom::Ceilingenum::LowerToFloor
          ceiling.value.bottomheight = ceiling.value.bottomheight + 8 * FRACUNIT
        end
        ceiling.value.direction = -1
        ceiling.value.speed = CDoom::CEILSPEED
      when CDoom::Ceilingenum::RaiseToHighest
        ceiling.value.topheight = CDoom.p_find_highest_ceiling_surrounding(sec)
        ceiling.value.direction = 1
        ceiling.value.speed = CDoom::CEILSPEED
      end

      ceiling.value.tag = sec.value.tag
      ceiling.value.type = type
      CDoom.p_add_active_ceiling(ceiling)
    end

    return rtn
  end

  #
  # Add an active ceiling
  #
  def self.p_add_active_ceiling(c : CDoom::Ceiling*)
    CDoom::MAXCEILINGS.times do |i|
      if CDoom.activeceilings[i].null?
        CDoom.activeceilings[i] = c
        return
      end
    end
  end

  #
  # Remove a ceiling's thinker
  #
  def self.p_remove_active_ceiling(c : CDoom::Ceiling*)
    CDoom::MAXCEILINGS.times do |i|
      if CDoom.activeceilings[i] == c
        CDoom.activeceilings[i].value.sector.value.specialdata = Pointer(Void).null
        CDoom.p_remove_thinker(pointerof(CDoom.activeceilings[i].value.@thinker))
        CDoom.activeceilings[i] = Pointer(CDoom::Ceiling).null
        break
      end
    end
  end

  #
  # Restart a ceiling that's in-stasis
  #
  def self.p_activate_in_stasis_ceiling(line : CDoom::Line*)
    CDoom::MAXCEILINGS.times do |i|
      if !CDoom.activeceilings[i].null? &&
         (CDoom.activeceilings[i].value.tag == line.value.tag) &&
         (CDoom.activeceilings[i].value.direction == 0)
        CDoom.activeceilings[i].value.direction = CDoom.activeceilings[i].value.olddirection
        pointerof(CDoom.activeceilings[i].value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_move_ceiling).pointer, Pointer(Void).null)
      end
    end
  end

  #
  # Stop a ceiling from crushing!
  #
  def self.ev_ceiling_crush_stop(line : CDoom::Line*) : LibC::Int
    rtn = 0
    CDoom::MAXCEILINGS.times do |i|
      if !CDoom.activeceilings[i].null? &&
         CDoom.activeceilings[i].value.tag == line.value.tag &&
         CDoom.activeceilings[i].value.direction != 0
        CDoom.activeceilings[i].value.olddirection = CDoom.activeceilings[i].value.direction
        pointerof(CDoom.activeceilings[i].value.@thinker.@function).as(CDoom::ActionfV*).value = NULL_PROC
        CDoom.activeceilings[i].value.direction = 0 # in-stasis
        rtn = 1
      end
    end

    return rtn
  end

  #
  # Move a locked door up/down
  #
  def self.t_vertical_door(door : CDoom::Vldoor*)
    case door.value.direction
    when 0
      # WAITING
      door.value.topcountdown = door.value.topcountdown - 1
      if door.value.topcountdown == 0
        case door.value.type
        when CDoom::Vldoorenum::BlazeRaise
          door.value.direction = -1 # time to go back down
          CDoom.s_start_sound(pointerof(door.value.sector.value.@soundorg),
            CDoom::Sfxenum::SFX_bdcls)
        when CDoom::Vldoorenum::DoorNormal
          door.value.direction = -1 # time to go back down
          CDoom.s_start_sound(pointerof(door.value.sector.value.@soundorg),
            CDoom::Sfxenum::SFX_dorcls)
        when CDoom::Vldoorenum::Close30ThenOpen
          door.value.direction = 1
          CDoom.s_start_sound(pointerof(door.value.sector.value.@soundorg),
            CDoom::Sfxenum::SFX_doropn)
        end
      end
    when 2
      # INITIAL WAIT
      door.value.topcountdown = door.value.topcountdown - 1
      if door.value.topcountdown == 0
        case door.value.type
        when CDoom::Vldoorenum::RaiseIn5Mins
          door.value.direction = 1
          door.value.type = CDoom::Vldoorenum::DoorNormal
          CDoom.s_start_sound(pointerof(door.value.sector.value.@soundorg),
            CDoom::Sfxenum::SFX_doropn)
        end
      end
    when -1
      # DOWN
      res = CDoom.t_move_plane(door.value.sector,
        door.value.speed,
        door.value.sector.value.floorheight,
        0, 1, door.value.direction)
      if res == CDoom::Result::Pastdest
        case door.value.type
        when CDoom::Vldoorenum::BlazeRaise, CDoom::Vldoorenum::BlazeClose
          door.value.sector.value.specialdata = Pointer(Void).null
          CDoom.p_remove_thinker(pointerof(door.value.@thinker)) # unlink and free
          CDoom.s_start_sound(pointerof(door.value.sector.value.@soundorg),
            CDoom::Sfxenum::SFX_bdcls)
        when CDoom::Vldoorenum::DoorNormal, CDoom::Vldoorenum::DoorClose
          door.value.sector.value.specialdata = Pointer(Void).null
          CDoom.p_remove_thinker(pointerof(door.value.@thinker)) # unlink and free
        when CDoom::Vldoorenum::Close30ThenOpen
          door.value.direction = 0
          door.value.topcountdown = 35 * 30
        end
      elsif res == CDoom::Result::Crushed
        case door.value.type
        when CDoom::Vldoorenum::BlazeClose, CDoom::Vldoorenum::DoorClose
          # DO NOT GO BACK UP!
        else
          door.value.direction = 1
          CDoom.s_start_sound(pointerof(door.value.sector.value.@soundorg),
            CDoom::Sfxenum::SFX_doropn)
        end
      end
    when 1
      # UP
      res = CDoom.t_move_plane(door.value.sector,
        door.value.speed,
        door.value.topheight,
        0, 1, door.value.direction)

      if res == CDoom::Result::Pastdest
        case door.value.type
        when CDoom::Vldoorenum::BlazeRaise, CDoom::Vldoorenum::DoorNormal
          door.value.direction = 0 # wait at top
          door.value.topcountdown = door.value.topwait
        when CDoom::Vldoorenum::Close30ThenOpen, CDoom::Vldoorenum::BlazeOpen, CDoom::Vldoorenum::DoorOpen
          door.value.sector.value.specialdata = Pointer(Void).null
          CDoom.p_remove_thinker(pointerof(door.value.@thinker)) # unlink and free
        end
      end
    end
  end

  def self.ev_do_locked_door(line : CDoom::Line*, type : CDoom::Vldoorenum, thing : CDoom::Mobj*) : LibC::Int
    p = thing.value.player

    return 0 if p.null?

    case line.value.special
    when 99, 133 # Blue Lock
      if p.value.cards[CDoom::Card::Bluecard.value] == 0 && p.value.cards[CDoom::Card::Blueskull.value] == 0
        p.value.message = @@deh_pd_blueo
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_oof)
        return 0
      end
    when 134, 135 # Red Lock
      if p.value.cards[CDoom::Card::Redcard.value] == 0 && p.value.cards[CDoom::Card::Redskull.value] == 0
        p.value.message = @@deh_pd_redo
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_oof)
        return 0
      end
    when 136, 137 # Yellow Lock
      if p.value.cards[CDoom::Card::Yellowcard.value] == 0 && p.value.cards[CDoom::Card::Yellowskull.value] == 0
        p.value.message = @@deh_pd_yellowo
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_oof)
        return 0
      end
    end

    return CDoom.ev_do_door(line, type)
  end

  #
  # open a door manually, no tag value
  #
  def self.ev_do_door(line : CDoom::Line*, type : CDoom::Vldoorenum) : LibC::Int
    secnum = -1
    rtn = 0

    while (secnum = CDoom.p_find_sector_from_line_tag(line, secnum)) >= 0
      sec = CDoom.sectors + secnum
      next unless sec.value.specialdata.null?

      # new door thinker
      rtn = 1
      door = CDoom.z_malloc(sizeof(CDoom::Vldoor), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Vldoor*)
      CDoom.p_add_thinker(pointerof(door.value.@thinker))
      sec.value.specialdata = door

      pointerof(door.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_vertical_door).pointer, Pointer(Void).null)
      door.value.sector = sec
      door.value.type = type
      door.value.topwait = CDoom::VDOORWAIT
      door.value.speed = CDoom::VDOORSPEED

      case type
      when CDoom::Vldoorenum::BlazeClose
        door.value.topheight = CDoom.p_find_lowest_ceiling_surrounding(sec)
        door.value.topheight = door.value.topheight - 4 * FRACUNIT
        door.value.direction = -1
        door.value.speed = CDoom::VDOORSPEED * 4
        CDoom.s_start_sound(pointerof(door.value.sector.value.@soundorg),
          CDoom::Sfxenum::SFX_bdcls)
      when CDoom::Vldoorenum::DoorClose
        door.value.topheight = CDoom.p_find_lowest_ceiling_surrounding(sec)
        door.value.topheight = door.value.topheight - 4 * FRACUNIT
        door.value.direction = -1
        CDoom.s_start_sound(pointerof(door.value.sector.value.@soundorg),
          CDoom::Sfxenum::SFX_dorcls)
      when CDoom::Vldoorenum::Close30ThenOpen
        door.value.topheight = sec.value.ceilingheight
        door.value.direction = -1
        CDoom.s_start_sound(pointerof(door.value.sector.value.@soundorg),
          CDoom::Sfxenum::SFX_dorcls)
      when CDoom::Vldoorenum::BlazeRaise, CDoom::Vldoorenum::BlazeOpen
        door.value.direction = 1
        door.value.topheight = CDoom.p_find_lowest_ceiling_surrounding(sec)
        door.value.topheight = door.value.topheight - 4 * FRACUNIT
        door.value.speed = CDoom::VDOORSPEED * 4
        CDoom.s_start_sound(pointerof(door.value.sector.value.@soundorg),
          CDoom::Sfxenum::SFX_bdopn) if door.value.topheight != sec.value.ceilingheight
      when CDoom::Vldoorenum::DoorNormal, CDoom::Vldoorenum::DoorOpen
        door.value.direction = 1
        door.value.topheight = CDoom.p_find_lowest_ceiling_surrounding(sec)
        door.value.topheight = door.value.topheight - 4 * FRACUNIT
        CDoom.s_start_sound(pointerof(door.value.sector.value.@soundorg),
          CDoom::Sfxenum::SFX_doropn) if door.value.topheight != sec.value.ceilingheight
      end
    end

    return rtn
  end

  def self.ev_vertical_door(line : CDoom::Line*, thing : CDoom::Mobj*)
    side = 0 # only front sides can be used

    # Check for locks
    player = thing.value.player

    case line.value.special
    when 26, 32 # Blue Lock
      return if player.null?

      if player.value.cards[CDoom::Card::Bluecard.value] == 0 && player.value.cards[CDoom::Card::Blueskull.value] == 0
        player.value.message = @@deh_pd_bluek
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_oof)
        return
      end
    when 27, 34 # Yellow Lock
      return if player.null?

      if player.value.cards[CDoom::Card::Yellowcard.value] == 0 && player.value.cards[CDoom::Card::Yellowskull.value] == 0
        player.value.message = @@deh_pd_yellowk
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_oof)
        return
      end
    when 28, 33 # Red Lock
      return if player.null?

      if player.value.cards[CDoom::Card::Redcard.value] == 0 && player.value.cards[CDoom::Card::Redskull.value] == 0
        player.value.message = @@deh_pd_redk
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_oof)
        return
      end
    end

    # if the sector has an active thinker, use it
    sec = CDoom.sides[line.value.sidenum[side ^ 1]].sector
    secnum = (sec - CDoom.sectors).to_i32!

    unless sec.value.specialdata.null?
      door = sec.value.specialdata.as(CDoom::Vldoor*)
      case line.value.special
      when 1, 26, 27, 28, 117 # ONLY FOR "RAISE" DOORS, NOT "OPEN"s
        if door.value.direction == -1
          door.value.direction = 1 # go back up
        else
          return if thing.value.player.null? # JDC: bad guys never close doors

          door.value.direction = -1 # start going down immediately
        end
        return
      end
    end

    # for proper sound
    case line.value.special
    when 117, 118 # BLAZING DOOR RAISE, OPEN
      CDoom.s_start_sound(pointerof(sec.value.@soundorg),
        CDoom::Sfxenum::SFX_bdopn)
    when 1, 31 # NORMAL DOOR SOUND
      CDoom.s_start_sound(pointerof(sec.value.@soundorg),
        CDoom::Sfxenum::SFX_doropn)
    else # LOCKED DOOR SOUND
      CDoom.s_start_sound(pointerof(sec.value.@soundorg),
        CDoom::Sfxenum::SFX_doropn)
    end

    # new door thinker
    door = CDoom.z_malloc(sizeof(CDoom::Vldoor), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Vldoor*)
    CDoom.p_add_thinker(pointerof(door.value.@thinker))
    sec.value.specialdata = door
    pointerof(door.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_vertical_door).pointer, Pointer(Void).null)
    door.value.sector = sec
    door.value.direction = 1
    door.value.speed = CDoom::VDOORSPEED
    door.value.topwait = CDoom::VDOORWAIT

    case line.value.special
    when 1, 26, 27, 28
      door.value.type = CDoom::Vldoorenum::DoorNormal
    when 31, 32, 33, 34
      door.value.type = CDoom::Vldoorenum::DoorOpen
      line.value.special = 0
    when 117 # blazing door raise
      door.value.type = CDoom::Vldoorenum::BlazeRaise
      door.value.speed = CDoom::VDOORSPEED * 4
    when 118 # blazing door open
      door.value.type = CDoom::Vldoorenum::BlazeOpen
      line.value.special = 0
      door.value.speed = CDoom::VDOORSPEED * 4
    end

    # find the top and bottom of the movement range
    door.value.topheight = CDoom.p_find_lowest_ceiling_surrounding(sec)
    door.value.topheight = door.value.topheight - 4 * FRACUNIT
  end

  #
  # Spawn a door that closes after 30 seconds
  #
  def self.p_spawn_door_close_in_30(sec : CDoom::Sector*)
    door = CDoom.z_malloc(sizeof(CDoom::Vldoor), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Vldoor*)

    CDoom.p_add_thinker(pointerof(door.value.@thinker))

    sec.value.specialdata = door
    sec.value.special = 0

    pointerof(door.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_vertical_door).pointer, Pointer(Void).null)
    door.value.sector = sec
    door.value.direction = 0
    door.value.type = CDoom::Vldoorenum::DoorNormal
    door.value.speed = CDoom::VDOORSPEED
    door.value.topcountdown = 30 * 35
  end

  #
  # Spawn a door that opens after 5 minutes
  #
  def self.p_spawn_door_raise_in_5_mins(sec : CDoom::Sector*, secnum : LibC::Int)
    door = CDoom.z_malloc(sizeof(CDoom::Vldoor), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Vldoor*)

    CDoom.p_add_thinker(pointerof(door.value.@thinker))

    sec.value.specialdata = door
    sec.value.special = 0

    pointerof(door.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_vertical_door).pointer, Pointer(Void).null)
    door.value.sector = sec
    door.value.direction = 2
    door.value.type = CDoom::Vldoorenum::RaiseIn5Mins
    door.value.speed = CDoom::VDOORSPEED
    door.value.topheight = CDoom.p_find_lowest_ceiling_surrounding(sec)
    door.value.topheight = door.value.topheight - 4 * FRACUNIT
    door.value.topwait = CDoom::VDOORWAIT
    door.value.topcountdown = 5 * 60 * 35
  end

  #
  # ENEMY THINKING
  # Enemies are allways spawned
  # with targetplayer = -1, threshold = 0
  # Most monsters are spawned unaware of all players,
  # but some can be made preaware
  #

  #
  # Called by p_noise_alert.
  # Recursively traverse adjacent sectors,
  # sound blocking lines cut off traversal.
  #
  def self.p_recursive_sound(sec : CDoom::Sector*, soundblocks : LibC::Int)
    # wake up all monsters in this sector
    if sec.value.validcount == CDoom.validcount &&
       sec.value.soundtraversed <= soundblocks + 1
      return # already flooded
    end

    sec.value.validcount = CDoom.validcount
    sec.value.soundtraversed = soundblocks + 1
    sec.value.soundtarget = CDoom.soundtarget

    sec.value.linecount.times do |i|
      check = sec.value.lines[i]
      next if check.value.flags & CDoom::ML_TWOSIDED == 0

      CDoom.p_line_opening(check)

      next if CDoom.openrange <= 0 # closed door

      other = CDoom.sides[check.value.sidenum[0]].sector
      if CDoom.sides[check.value.sidenum[0]].sector == sec
        other = CDoom.sides[check.value.sidenum[1]].sector
      end

      if check.value.flags & CDoom::ML_SOUNDBLOCK != 0
        CDoom.p_recursive_sound(other, 1) if soundblocks == 0
      else
        CDoom.p_recursive_sound(other, soundblocks)
      end
    end
  end

  #
  # If a monster yells at a player,
  # it will alert other monsters to the player.
  #
  def self.p_noise_alert(target : CDoom::Mobj*, emmiter : CDoom::Mobj*)
    CDoom.soundtarget = target
    CDoom.validcount += 1
    CDoom.p_recursive_sound(emmiter.value.subsector.value.sector, 0)
  end

  def self.p_check_melee_range(actor : CDoom::Mobj*) : CDoom::DoomBool
    return 0 if actor.value.target.null?

    pl = actor.value.target
    dist = CDoom.p_aprox_distance(pl.value.x - actor.value.x, pl.value.y - actor.value.y)

    return 0 if dist >= CDoom::MELEERANGE - 20 * FRACUNIT + pl.value.info.value.radius

    return 0 if CDoom.p_check_sight(actor, actor.value.target) == 0

    return 1
  end

  def self.p_check_missile_range(actor : CDoom::Mobj*) : CDoom::DoomBool
    return 0 if CDoom.p_check_sight(actor, actor.value.target) == 0

    if actor.value.flags & CDoom::Mobjflag::MF_JUSTHIT.value != 0
      # the target just hit the enemy,
      # so fight back!
      actor.value.flags = actor.value.flags & ~CDoom::Mobjflag::MF_JUSTHIT.value
      return 1
    end

    return 0 if actor.value.reactiontime != 0 # do not attack yet

    # OPTIMIZE: get this from a global checksight
    dist = CDoom.p_aprox_distance(actor.value.x - actor.value.target.value.x,
      actor.value.y - actor.value.target.value.y) - 64 * FRACUNIT

    dist -= 128 * FRACUNIT if actor.value.info.value.meleestate == 0 # no melee attack, so fire more

    dist >>= 16

    if actor.value.type == CDoom::Mobjtype::MT_VILE
      return 0 if dist > 14 * 64 # too far away
    end

    if actor.value.type == CDoom::Mobjtype::MT_UNDEAD
      return 0 if dist < 196 # close for fist attack
      dist >>= 1
    end

    if actor.value.type == CDoom::Mobjtype::MT_CYBORG ||
       actor.value.type == CDoom::Mobjtype::MT_SPIDER ||
       actor.value.type == CDoom::Mobjtype::MT_SKULL
      dist >>= 1
    end

    dist = 200 if dist > 200
    dist = 160 if actor.value.type == CDoom::Mobjtype::MT_CYBORG && dist > 160

    return 0 if CDoom.p_random < dist

    return 1
  end

  def self.p_move(actor : CDoom::Mobj*) : CDoom::DoomBool
    return 0 if actor.value.movedir == CDoom::Dirtype::NoDir.value

    CDoom.i_error("Error: Weird actor.value.movedir!") if actor.value.movedir.to_u32! >= 8

    tryx = actor.value.x + actor.value.info.value.speed * CDoom.xspeed[actor.value.movedir]
    tryy = actor.value.y + actor.value.info.value.speed * CDoom.yspeed[actor.value.movedir]

    try_ok = CDoom.p_try_move(actor, tryx, tryy)

    if try_ok == 0
      # open any specials
      if actor.value.flags & CDoom::Mobjflag::MF_FLOAT.value != 0 && CDoom.floatok != 0
        # must adjust height
        if actor.value.z < CDoom.tmfloorz
          actor.value.z = actor.value.z + CDoom::FLOATSPEED
        else
          actor.value.z = actor.value.z - CDoom::FLOATSPEED
        end
        actor.value.flags = actor.value.flags | CDoom::Mobjflag::MF_INFLOAT.value
        return 1
      end

      return 0 if CDoom.numspechit == 0

      actor.value.movedir = CDoom::Dirtype::NoDir.value
      good = 0
      while CDoom.numspechit != 0
        CDoom.numspechit -= 1
        ld = CDoom.spechit[CDoom.numspechit]
        # if the special is not a door
        # that can be opened,
        # return false
        good = 1 if CDoom.p_use_special_line(actor, ld, 0) != 0
      end
      return good
    else
      actor.value.flags = actor.value.flags & ~CDoom::Mobjflag::MF_INFLOAT.value
    end

    actor.value.z = actor.value.floorz if actor.value.flags & CDoom::Mobjflag::MF_FLOAT.value == 0

    return 1
  end

  #
  # Attempts to move actor on
  # in its current (ob->moveangle) direction.
  # If blocked by either a wall or an actor
  # returns FALSE
  # If move is either clear or blocked only by a door,
  # returns TRUE and sets...
  # If a door is in the way,
  # an OpenDoor call is made to start it opening.
  #
  def self.p_try_walk(actor : CDoom::Mobj*) : CDoom::DoomBool
    return 0 if CDoom.p_move(actor) == 0

    actor.value.movecount = CDoom.p_random & 15
    return 1
  end

  def self.p_new_chase_dir(actor : CDoom::Mobj*)
    d = uninitialized StaticArray(CDoom::Dirtype, 3)

    CDoom.i_error("Error: p_new_chase_dir: called with no target") if actor.value.target.null?

    olddir = actor.value.movedir
    turnaround = CDoom.opposite[olddir]

    deltax = actor.value.target.value.x - actor.value.x
    deltay = actor.value.target.value.y - actor.value.y

    if deltax > 10 * FRACUNIT
      d[1] = CDoom::Dirtype::East
    elsif deltax < -10 * FRACUNIT
      d[1] = CDoom::Dirtype::West
    else
      d[1] = CDoom::Dirtype::NoDir
    end

    if deltay < -10 * FRACUNIT
      d[2] = CDoom::Dirtype::South
    elsif deltay > 10 * FRACUNIT
      d[2] = CDoom::Dirtype::North
    else
      d[2] = CDoom::Dirtype::NoDir
    end

    # try direct route
    if d[1] != CDoom::Dirtype::NoDir &&
       d[2] != CDoom::Dirtype::NoDir
      actor.value.movedir = CDoom.diags[((deltay < 0).to_unsafe << 1) + (deltax > 0).to_unsafe].value
      return if actor.value.movedir != turnaround.value && CDoom.p_try_walk(actor) != 0
    end

    # try other directions
    if CDoom.p_random > 200 ||
       doom_abs(deltay) > doom_abs(deltax)
      tdir = d[1]
      d[1] = d[2]
      d[2] = tdir
    end

    d[1] = CDoom::Dirtype::NoDir if d[1] == turnaround
    d[2] = CDoom::Dirtype::NoDir if d[2] == turnaround

    if d[1] != CDoom::Dirtype::NoDir
      actor.value.movedir = d[1].value
      return if CDoom.p_try_walk(actor) != 0 # either moved toward or attacked
    end

    if d[2] != CDoom::Dirtype::NoDir
      actor.value.movedir = d[2].value
      return if CDoom.p_try_walk(actor) != 0
    end

    # there is no direct path to the player,
    # so pick another direction.
    if olddir != CDoom::Dirtype::NoDir.value
      actor.value.movedir = olddir
      return if CDoom.p_try_walk(actor) != 0
    end

    # randomly determine direction of search
    if CDoom.p_random & 1 != 0
      tdir = CDoom::Dirtype::East.value
      while tdir <= CDoom::Dirtype::SouthEast.value
        if tdir != turnaround.value
          actor.value.movedir = tdir

          return if CDoom.p_try_walk(actor) != 0
        end
        tdir += 1
      end
    else
      tdir = CDoom::Dirtype::SouthEast.value
      while tdir != (CDoom::Dirtype::East.value - 1)
        if tdir != turnaround.value
          actor.value.movedir = tdir

          return if CDoom.p_try_walk(actor) != 0
        end
        tdir -= 1
      end
    end

    if turnaround != CDoom::Dirtype::NoDir
      actor.value.movedir = turnaround.value
      return if CDoom.p_try_walk(actor) != 0
    end

    actor.value.movedir = CDoom::Dirtype::NoDir.value # can not move
  end

  def self.p_look_for_players(actor : CDoom::Mobj*, allaround : CDoom::DoomBool) : CDoom::DoomBool
    sector = actor.value.subsector.value.sector

    c = 0
    stop = (actor.value.lastlook - 1) & 3

    loop do
      if CDoom.playeringame[actor.value.lastlook] == 0
        actor.value.lastlook = (actor.value.lastlook + 1) & 3
        next
      end

      c += 1
      if c == 3 || actor.value.lastlook == stop
        # done looking
        return 0
      end

      player = CDoom.players.to_unsafe + actor.value.lastlook

      if player.value.health <= 0
        actor.value.lastlook = (actor.value.lastlook + 1) & 3
        next # dead
      end

      if CDoom.p_check_sight(actor, player.value.mo) == 0
        actor.value.lastlook = (actor.value.lastlook + 1) & 3
        next # out of sight
      end

      if allaround == 0
        an : CDoom::Angle = CDoom.r_point_to_angle2(actor.value.x,
          actor.value.y,
          player.value.mo.value.x,
          player.value.mo.value.y) &- actor.value.angle

        if an > ANG90 && an < ANG270
          dist = CDoom.p_aprox_distance(player.value.mo.value.x - actor.value.x,
            player.value.mo.value.y - actor.value.y)
          # if real close, react anyway
          if dist > CDoom::MELEERANGE
            actor.value.lastlook = (actor.value.lastlook + 1) & 3
            next # behind back
          end
        end
      end

      actor.value.target = player.value.mo
      return 1
    end

    return 0
  end

  def self.a_keen_die(mo : CDoom::Mobj*)
    CDoom.a_fall(mo)

    # scan the remaining thinkers
    # to see if all Keens are dead
    th = CDoom.thinkercap.next
    while th != pointerof(CDoom.thinkercap)
      if th.value.function.acp1.pointer != (->CDoom.p_mobj_thinker).pointer
        th = th.value.next
        next
      end

      mo2 = th.as(CDoom::Mobj*)
      if mo2 != mo &&
         mo2.value.type == mo.value.type &&
         mo2.value.health > 0
        # other Keen not dead
        return
      end
      th = th.value.next
    end

    junk = CDoom::Line.new(tag: 666)
    CDoom.ev_do_door(pointerof(junk), CDoom::Vldoorenum::DoorOpen)
  end

  #
  # ACTION ROUTINES
  #

  #
  # Stay in state until a player is sighted.
  #
  def self.a_look(actor : CDoom::Mobj*)
    seeyou = false

    actor.value.threshold = 0 # any shot will wake up
    targ = actor.value.subsector.value.sector.value.soundtarget

    if !targ.null? &&
       (targ.value.flags & CDoom::Mobjflag::MF_SHOOTABLE.value) != 0
      actor.value.target = targ

      if actor.value.flags & CDoom::Mobjflag::MF_AMBUSH.value != 0
        seeyou = true if CDoom.p_check_sight(actor, actor.value.target) != 0
      else
        seeyou = true
      end
    end

    return if !seeyou && CDoom.p_look_for_players(actor, 0) == 0

    # go into chase state
    if actor.value.info.value.seesound != 0
      sound = 0

      case actor.value.info.value.seesound
      when CDoom::Sfxenum::SFX_posit1.value, CDoom::Sfxenum::SFX_posit2.value, CDoom::Sfxenum::SFX_posit3.value
        sound = CDoom::Sfxenum::SFX_posit1.value + CDoom.p_random % 3
      when CDoom::Sfxenum::SFX_bgsit1.value, CDoom::Sfxenum::SFX_bgsit2.value
        sound = CDoom::Sfxenum::SFX_bgsit1.value + CDoom.p_random % 2
      else
        sound = actor.value.info.value.seesound
      end

      if actor.value.type == CDoom::Mobjtype::MT_SPIDER ||
         actor.value.type == CDoom::Mobjtype::MT_CYBORG
        # full volume
        CDoom.s_start_sound(Pointer(Void).null, sound)
      else
        CDoom.s_start_sound(actor, sound)
      end
    end

    CDoom.p_set_mobj_state(actor, CDoom::Statenum.new(actor.value.info.value.seestate))
  end

  #
  # Actor has a melee attack,
  # so it tries to close as fast as possible
  #
  def self.a_chase(actor : CDoom::Mobj*)
    actor.value.reactiontime = actor.value.reactiontime - 1 if actor.value.reactiontime != 0

    # modify target threshold
    if actor.value.threshold != 0
      if actor.value.target.null? ||
         actor.value.target.value.health <= 0
        actor.value.threshold = 0
      else
        actor.value.threshold = actor.value.threshold - 1
      end
    end

    # turn towards movement direction if not there yet
    if actor.value.movedir < 8
      actor.value.angle = actor.value.angle & (7 << 29)
      delta = (actor.value.angle &- (actor.value.movedir.to_u32! << 29)).to_i32!

      if delta > 0
        actor.value.angle = actor.value.angle &- ANG90.tdiv(2)
      elsif delta < 0
        actor.value.angle = actor.value.angle &+ ANG90.tdiv(2)
      end
    end

    if actor.value.target.null? ||
       actor.value.target.value.flags & CDoom::Mobjflag::MF_SHOOTABLE.value == 0
      # look for a new target
      return if CDoom.p_look_for_players(actor, 1) != 0 # got a new target

      CDoom.p_set_mobj_state(actor, CDoom::Statenum.new(actor.value.info.value.spawnstate))
      return
    end

    # do not attack twice in a row
    if actor.value.flags & CDoom::Mobjflag::MF_JUSTATTACKED.value != 0
      actor.value.flags = actor.value.flags & ~CDoom::Mobjflag::MF_JUSTATTACKED.value
      CDoom.p_new_chase_dir(actor) if CDoom.gameskill != CDoom::Skill::Nightmare && CDoom.fastparm == 0
      return
    end

    # check for melee attack
    if actor.value.info.value.meleestate != 0 &&
       CDoom.p_check_melee_range(actor) != 0
      CDoom.s_start_sound(actor, actor.value.info.value.attacksound) if actor.value.info.value.attacksound != 0

      CDoom.p_set_mobj_state(actor, CDoom::Statenum.new(actor.value.info.value.meleestate))
      return
    end

    nomissile = false
    # check for missile attack
    if actor.value.info.value.missilestate != 0
      if CDoom.gameskill < CDoom::Skill::Nightmare &&
         CDoom.fastparm == 0 && actor.value.movecount != 0
        nomissile = true
      end

      unless nomissile
        nomissile = true if CDoom.p_check_missile_range(actor) == 0

        unless nomissile
          CDoom.p_set_mobj_state(actor, CDoom::Statenum.new(actor.value.info.value.missilestate))
          actor.value.flags = actor.value.flags | CDoom::Mobjflag::MF_JUSTATTACKED.value
          return
        end
      end
    end

    # possibly choose another target
    if CDoom.netgame != 0 &&
       actor.value.threshold == 0 &&
       CDoom.p_check_sight(actor, actor.value.target) == 0
      return if CDoom.p_look_for_players(actor, 1) != 0 # got a new target
    end

    # chase towards player
    actor.value.movecount = actor.value.movecount - 1
    if actor.value.movecount < 0 ||
       CDoom.p_move(actor) == 0
      CDoom.p_new_chase_dir(actor)
    end

    # make active sound
    if actor.value.info.value.activesound != 0 &&
       CDoom.p_random < 3
      CDoom.s_start_sound(actor, actor.value.info.value.activesound)
    end
  end

  def self.a_face_target(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    actor.value.flags = actor.value.flags & ~CDoom::Mobjflag::MF_AMBUSH.value

    actor.value.angle = CDoom.r_point_to_angle2(actor.value.x,
      actor.value.y,
      actor.value.target.value.x,
      actor.value.target.value.y)

    if actor.value.target.value.flags & CDoom::Mobjflag::MF_SHADOW.value != 0
      actor.value.angle = actor.value.angle &+ ((CDoom.p_random - CDoom.p_random) << 21)
    end
  end

  def self.a_pos_attack(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.a_face_target(actor)
    angle = actor.value.angle
    slope = CDoom.p_aim_line_attack(actor, angle, CDoom::MISSILERANGE)

    CDoom.s_start_sound(actor, CDoom::Sfxenum::SFX_pistol.value)
    angle &+= (CDoom.p_random - CDoom.p_random) << 20
    damage = ((CDoom.p_random % 5) + 1) * 3
    CDoom.p_line_attack(actor, angle, CDoom::MISSILERANGE, slope, damage)
  end

  def self.a_spos_attack(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.s_start_sound(actor, CDoom::Sfxenum::SFX_shotgn.value)
    CDoom.a_face_target(actor)
    bangle = actor.value.angle
    slope = CDoom.p_aim_line_attack(actor, bangle, CDoom::MISSILERANGE)

    3.times do |i|
      angle = bangle &+ ((CDoom.p_random - CDoom.p_random) << 20)
      damage = ((CDoom.p_random % 5) + 1) * 3
      CDoom.p_line_attack(actor, angle, CDoom::MISSILERANGE, slope, damage)
    end
  end

  def self.a_cpos_attack(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.s_start_sound(actor, CDoom::Sfxenum::SFX_shotgn.value)
    CDoom.a_face_target(actor)
    bangle = actor.value.angle
    slope = CDoom.p_aim_line_attack(actor, bangle, CDoom::MISSILERANGE)

    angle = bangle &+ ((CDoom.p_random - CDoom.p_random) << 20)
    damage = ((CDoom.p_random % 5) + 1) * 3
    CDoom.p_line_attack(actor, angle, CDoom::MISSILERANGE, slope, damage)
  end

  def self.a_cpos_refire(actor : CDoom::Mobj*)
    # keep firing unless target got out of sight
    CDoom.a_face_target(actor)

    return if CDoom.p_random < 40

    if actor.value.target.null? ||
       actor.value.target.value.health <= 0 ||
       CDoom.p_check_sight(actor, actor.value.target) == 0
      CDoom.p_set_mobj_state(actor, CDoom::Statenum.new(actor.value.info.value.seestate))
    end
  end

  def self.a_spid_refire(actor : CDoom::Mobj*)
    # keep firing unless target got out of sight
    CDoom.a_face_target(actor)

    return if CDoom.p_random < 10

    if actor.value.target.null? ||
       actor.value.target.value.health <= 0 ||
       CDoom.p_check_sight(actor, actor.value.target) == 0
      CDoom.p_set_mobj_state(actor, CDoom::Statenum.new(actor.value.info.value.seestate))
    end
  end

  def self.a_bspi_attack(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.a_face_target(actor)

    # launch a missile
    CDoom.p_spawn_missile(actor, actor.value.target, CDoom::Mobjtype::MT_ARACHPLAZ)
  end

  def self.a_troop_attack(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.a_face_target(actor)
    if CDoom.p_check_melee_range(actor) != 0
      CDoom.s_start_sound(actor, CDoom::Sfxenum::SFX_claw.value)
      damage = (CDoom.p_random % 8 + 1) * 3
      CDoom.p_damage_mobj(actor.value.target, actor, actor, damage)
      return
    end

    # launch a missile
    CDoom.p_spawn_missile(actor, actor.value.target, CDoom::Mobjtype::MT_TROOPSHOT)
  end

  def self.a_sarg_attack(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.a_face_target(actor)
    if CDoom.p_check_melee_range(actor) != 0
      damage = ((CDoom.p_random % 10) + 1) * 4
      CDoom.p_damage_mobj(actor.value.target, actor, actor, damage)
    end
  end

  def self.a_head_attack(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.a_face_target(actor)
    if CDoom.p_check_melee_range(actor) != 0
      damage = (CDoom.p_random % 6 + 1) * 10
      CDoom.p_damage_mobj(actor.value.target, actor, actor, damage)
      return
    end

    # launch a missile
    CDoom.p_spawn_missile(actor, actor.value.target, CDoom::Mobjtype::MT_HEADSHOT)
  end

  def self.a_cyber_attack(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.a_face_target(actor)

    # launch a missile
    CDoom.p_spawn_missile(actor, actor.value.target, CDoom::Mobjtype::MT_ROCKET)
  end

  def self.a_bruis_attack(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.a_face_target(actor)
    if CDoom.p_check_melee_range(actor) != 0
      damage = (CDoom.p_random % 8 + 1) * 10
      CDoom.p_damage_mobj(actor.value.target, actor, actor, damage)
      return
    end

    # launch a missile
    CDoom.p_spawn_missile(actor, actor.value.target, CDoom::Mobjtype::MT_BRUISERSHOT)
  end

  def self.a_skel_missile(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.a_face_target(actor)
    actor.value.z = actor.value.z + 16 * FRACUNIT # so missile spawns higher
    mo = CDoom.p_spawn_missile(actor, actor.value.target, CDoom::Mobjtype::MT_TRACER)
    actor.value.z = actor.value.z - 16 * FRACUNIT # back to normal

    mo.value.x = mo.value.x + mo.value.momx
    mo.value.y = mo.value.y + mo.value.momy
    mo.value.tracer = actor.value.target
  end

  def self.a_tracer(actor : CDoom::Mobj*)
    return if CDoom.gametic & 3 != 0

    # spawn a puff of smoke behind the rocket
    CDoom.p_spawn_puff(actor.value.x, actor.value.y, actor.value.z)

    th = CDoom.p_spawn_mobj(actor.value.x - actor.value.momx,
      actor.value.y - actor.value.momy,
      actor.value.z, CDoom::Mobjtype::MT_SMOKE)

    th.value.momz = FRACUNIT
    th.value.tics = th.value.tics - (CDoom.p_random & 3)
    th.value.tics = 1 if th.value.tics < 1

    # adjust direction
    dest = actor.value.tracer

    return if dest.null? || dest.value.health <= 0

    # change angle
    exact = CDoom.r_point_to_angle2(actor.value.x,
      actor.value.y,
      dest.value.x,
      dest.value.y)

    if exact != actor.value.angle
      if exact &- actor.value.angle > 0x80000000
        actor.value.angle = actor.value.angle &- CDoom.traceangle
        actor.value.angle = exact if exact &- actor.value.angle < 0x80000000
      else
        actor.value.angle = actor.value.angle &+ CDoom.traceangle
        actor.value.angle = exact if exact &- actor.value.angle > 0x80000000
      end
    end

    exact = actor.value.angle >> CDoom::ANGLETOFINESHIFT
    actor.value.momx = CDoom.fixed_mul(actor.value.info.value.speed, @@finecosine[exact])
    actor.value.momy = CDoom.fixed_mul(actor.value.info.value.speed, @@finesine[exact])

    # change slope
    dist = CDoom.p_aprox_distance(dest.value.x - actor.value.x,
      dest.value.y - actor.value.y)

    dist = dist.tdiv(actor.value.info.value.speed)

    dist = 1 if dist < 1
    slope = (dest.value.z + 40 * FRACUNIT - actor.value.z).tdiv(dist)

    if slope < actor.value.momz
      actor.value.momz = actor.value.momz - FRACUNIT.tdiv(8)
    else
      actor.value.momz = actor.value.momz + FRACUNIT.tdiv(8)
    end
  end

  def self.a_skel_whoosh(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.a_face_target(actor)
    CDoom.s_start_sound(actor, CDoom::Sfxenum::SFX_skeswg.value)
  end

  def self.a_skel_fist(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.a_face_target(actor)

    if CDoom.p_check_melee_range(actor) != 0
      damage = ((CDoom.p_random % 10) + 1) * 6
      CDoom.s_start_sound(actor, CDoom::Sfxenum::SFX_skepch.value)
      CDoom.p_damage_mobj(actor.value.target, actor, actor, damage)
    end
  end

  #
  # Detect a corpse that could be raised.
  #
  def self.pit_vile_check(thing : CDoom::Mobj*) : CDoom::DoomBool
    return 1 if thing.value.flags & CDoom::Mobjflag::MF_CORPSE.value == 0 # not a monster

    return 1 if thing.value.tics != -1 # not lying still yet

    return 1 if thing.value.info.value.raisestate == CDoom::Statenum::S_NULL.value # monster doesn't have a raise state

    maxdist = thing.value.info.value.radius + CDoom.mobjinfo[CDoom::Mobjtype::MT_VILE.value].radius

    return 1 if doom_abs(thing.value.x - CDoom.viletryx) > maxdist ||
                doom_abs(thing.value.y - CDoom.viletryy) > maxdist # not actually touching

    CDoom.corpsehit = thing
    CDoom.corpsehit.value.momx = 0
    CDoom.corpsehit.value.momy = 0
    CDoom.corpsehit.value.height = CDoom.corpsehit.value.height << 2
    check = CDoom.p_check_position(CDoom.corpsehit, CDoom.corpsehit.value.x, CDoom.corpsehit.value.y)
    CDoom.corpsehit.value.height = CDoom.corpsehit.value.height >> 2

    return 1 if check == 0 # doesn't fit here

    return 0 # got one, so stop checking
  end

  #
  # Check for ressurecting a body
  #
  def self.a_vile_chase(actor : CDoom::Mobj*)
    if actor.value.movedir != CDoom::Dirtype::NoDir.value
      # check for corpses to raise
      CDoom.viletryx =
        actor.value.x + actor.value.info.value.speed * CDoom.xspeed[actor.value.movedir]
      CDoom.viletryy =
        actor.value.y + actor.value.info.value.speed * CDoom.yspeed[actor.value.movedir]

      xl = (CDoom.viletryx - CDoom.bmaporgx - CDoom::MAXRADIUS * 2) >> CDoom::MAPBLOCKSHIFT
      xh = (CDoom.viletryx - CDoom.bmaporgx + CDoom::MAXRADIUS * 2) >> CDoom::MAPBLOCKSHIFT
      yl = (CDoom.viletryy - CDoom.bmaporgy - CDoom::MAXRADIUS * 2) >> CDoom::MAPBLOCKSHIFT
      yh = (CDoom.viletryy - CDoom.bmaporgy + CDoom::MAXRADIUS * 2) >> CDoom::MAPBLOCKSHIFT

      vileobj = actor
      bx = xl
      while bx <= xh
        by = yl
        while by <= yh
          # Call pit_vile_check to check
          # whether object is a corpse
          # that canbe raised.
          if CDoom.p_block_things_iterator(bx, by, ->CDoom.pit_vile_check) == 0
            # got one!
            temp = actor.value.target
            actor.value.target = CDoom.corpsehit
            CDoom.a_face_target(actor)
            actor.value.target = temp

            CDoom.p_set_mobj_state(actor, CDoom::Statenum::S_VILE_HEAL1)
            CDoom.s_start_sound(CDoom.corpsehit, CDoom::Sfxenum::SFX_slop.value)
            info = CDoom.corpsehit.value.info

            CDoom.p_set_mobj_state(CDoom.corpsehit, CDoom::Statenum.new(info.value.raisestate))
            CDoom.corpsehit.value.height = CDoom.corpsehit.value.height << 2
            CDoom.corpsehit.value.flags = info.value.flags
            CDoom.corpsehit.value.health = info.value.spawnhealth
            CDoom.corpsehit.value.target = Pointer(CDoom::Mobj).null

            return
          end

          by += 1
        end

        bx += 1
      end
    end

    # Return to normal attack.
    CDoom.a_chase(actor)
  end

  def self.a_vile_start(actor : CDoom::Mobj*)
    CDoom.s_start_sound(actor, CDoom::Sfxenum::SFX_vilatk.value)
  end

  #
  # Keep fire in front of player unless out of sight
  #
  def self.a_start_fire(actor : CDoom::Mobj*)
    CDoom.s_start_sound(actor, CDoom::Sfxenum::SFX_flamst.value)
    CDoom.a_fire(actor)
  end

  def self.a_fire_crackle(actor : CDoom::Mobj*)
    CDoom.s_start_sound(actor, CDoom::Sfxenum::SFX_flame.value)
    CDoom.a_fire(actor)
  end

  def self.a_fire(actor : CDoom::Mobj*)
    dest = actor.value.tracer
    return if dest.null?

    # don't move it if the vile lost sight
    return if CDoom.p_check_sight(actor.value.target, dest) == 0

    an = dest.value.angle >> CDoom::ANGLETOFINESHIFT

    CDoom.p_unset_thing_position(actor)
    actor.value.x = dest.value.x + CDoom.fixed_mul(24 * FRACUNIT, @@finecosine[an])
    actor.value.y = dest.value.y + CDoom.fixed_mul(24 * FRACUNIT, @@finesine[an])
    actor.value.z = dest.value.z
    CDoom.p_set_thing_position(actor)
  end

  #
  # Spawn the hellfire
  #
  def self.a_vile_target(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.a_face_target(actor)

    fog = CDoom.p_spawn_mobj(actor.value.target.value.x,
      actor.value.target.value.y,
      actor.value.target.value.z, CDoom::Mobjtype::MT_FIRE)

    actor.value.tracer = fog
    fog.value.target = actor
    fog.value.tracer = actor.value.target
    CDoom.a_fire(fog)
  end

  def self.a_vile_attack(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.a_face_target(actor)

    return if CDoom.p_check_sight(actor, actor.value.target) == 0

    CDoom.s_start_sound(actor, CDoom::Sfxenum::SFX_barexp.value)
    CDoom.p_damage_mobj(actor.value.target, actor, actor, 20)
    actor.value.target.value.momz = 1000 * FRACUNIT // actor.value.target.value.info.value.mass

    an = actor.value.angle >> CDoom::ANGLETOFINESHIFT

    fire = actor.value.tracer

    return if fire.null?

    # move the fire between the vile and the player
    fire.value.x = actor.value.target.value.x - CDoom.fixed_mul(24 * FRACUNIT, @@finecosine[an])
    fire.value.y = actor.value.target.value.y - CDoom.fixed_mul(24 * FRACUNIT, @@finesine[an])
    CDoom.p_radius_attack(fire, actor, 70)
  end

  #
  # firing three missiles (bruisers)
  # in three different directions?
  # Doesn't look like it.
  #
  def self.a_fat_raise(actor : CDoom::Mobj*)
    CDoom.a_face_target(actor)
    CDoom.s_start_sound(actor, CDoom::Sfxenum::SFX_manatk.value)
  end

  def self.a_fat_attack1(actor : CDoom::Mobj*)
    CDoom.a_face_target(actor)
    # Change direction  to ...
    actor.value.angle = actor.value.angle &+ CDoom::FATSPREAD
    CDoom.p_spawn_missile(actor, actor.value.target, CDoom::Mobjtype::MT_FATSHOT)

    mo = CDoom.p_spawn_missile(actor, actor.value.target, CDoom::Mobjtype::MT_FATSHOT)
    mo.value.angle = mo.value.angle &+ CDoom::FATSPREAD
    an = mo.value.angle >> CDoom::ANGLETOFINESHIFT
    mo.value.momx = CDoom.fixed_mul(mo.value.info.value.speed, @@finecosine[an])
    mo.value.momy = CDoom.fixed_mul(mo.value.info.value.speed, @@finesine[an])
  end

  def self.a_fat_attack2(actor : CDoom::Mobj*)
    CDoom.a_face_target(actor)
    # Now here choose opposite deviation.
    actor.value.angle = actor.value.angle &- CDoom::FATSPREAD
    CDoom.p_spawn_missile(actor, actor.value.target, CDoom::Mobjtype::MT_FATSHOT)

    mo = CDoom.p_spawn_missile(actor, actor.value.target, CDoom::Mobjtype::MT_FATSHOT)
    mo.value.angle = mo.value.angle &- CDoom::FATSPREAD * 2
    an = mo.value.angle >> CDoom::ANGLETOFINESHIFT
    mo.value.momx = CDoom.fixed_mul(mo.value.info.value.speed, @@finecosine[an])
    mo.value.momy = CDoom.fixed_mul(mo.value.info.value.speed, @@finesine[an])
  end

  def self.a_fat_attack3(actor : CDoom::Mobj*)
    CDoom.a_face_target(actor)

    mo = CDoom.p_spawn_missile(actor, actor.value.target, CDoom::Mobjtype::MT_FATSHOT)
    mo.value.angle = mo.value.angle &- CDoom::FATSPREAD.tdiv(2)
    an = mo.value.angle >> CDoom::ANGLETOFINESHIFT
    mo.value.momx = CDoom.fixed_mul(mo.value.info.value.speed, @@finecosine[an])
    mo.value.momy = CDoom.fixed_mul(mo.value.info.value.speed, @@finesine[an])

    mo = CDoom.p_spawn_missile(actor, actor.value.target, CDoom::Mobjtype::MT_FATSHOT)
    mo.value.angle = mo.value.angle &+ CDoom::FATSPREAD.tdiv(2)
    an = mo.value.angle >> CDoom::ANGLETOFINESHIFT
    mo.value.momx = CDoom.fixed_mul(mo.value.info.value.speed, @@finecosine[an])
    mo.value.momy = CDoom.fixed_mul(mo.value.info.value.speed, @@finesine[an])
  end

  #
  # Fly at the player like a missile
  #
  def self.a_skull_attack(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    dest = actor.value.target
    actor.value.flags = actor.value.flags | CDoom::Mobjflag::MF_SKULLFLY.value

    CDoom.s_start_sound(actor, actor.value.info.value.attacksound)
    CDoom.a_face_target(actor)
    an = actor.value.angle >> CDoom::ANGLETOFINESHIFT
    actor.value.momx = CDoom.fixed_mul(CDoom::SKULLSPEED, @@finecosine[an])
    actor.value.momy = CDoom.fixed_mul(CDoom::SKULLSPEED, @@finesine[an])
    dist = CDoom.p_aprox_distance(dest.value.x - actor.value.x, dest.value.y - actor.value.y)
    dist = dist.tdiv(CDoom::SKULLSPEED)

    dist = 1 if dist < 1
    actor.value.momz = (dest.value.z + (dest.value.height >> 1) - actor.value.z).tdiv(dist)
  end

  def self.a_pain_shoot_skull(actor : CDoom::Mobj*, angle : CDoom::Angle)
    # count total number of skull currently on the level
    count = 0

    currentthinker = CDoom.thinkercap.next
    while currentthinker != pointerof(CDoom.thinkercap)
      if (currentthinker.value.function.acp1.pointer == (->CDoom.p_mobj_thinker).pointer) &&
         currentthinker.as(CDoom::Mobj*).value.type == CDoom::Mobjtype::MT_SKULL
        count += 1
      end
      currentthinker = currentthinker.value.next
    end

    # if there are allready 20 skulls on the level,
    # don't spit another one
    return if count > 20

    # okay, there's playe for another one
    an = angle >> CDoom::ANGLETOFINESHIFT

    prestep = 4 * FRACUNIT +
              3 * (actor.value.info.value.radius + CDoom.mobjinfo[CDoom::Mobjtype::MT_SKULL.value].radius) // 2

    x = actor.value.x + CDoom.fixed_mul(prestep, @@finecosine[an])
    y = actor.value.y + CDoom.fixed_mul(prestep, @@finesine[an])
    z = actor.value.z + 8 * FRACUNIT

    newmobj = CDoom.p_spawn_mobj(x, y, z, CDoom::Mobjtype::MT_SKULL)

    # Check for movements.
    if CDoom.p_try_move(newmobj, newmobj.value.x, newmobj.value.y) == 0
      # kill it immediately
      CDoom.p_damage_mobj(newmobj, actor, actor, 10000)
      return
    end

    newmobj.value.target = actor.value.target
    CDoom.a_skull_attack(newmobj)
  end

  def self.a_pain_attack(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.a_face_target(actor)
    CDoom.a_pain_shoot_skull(actor, actor.value.angle)
  end

  def self.a_pain_die(actor : CDoom::Mobj*)
    CDoom.a_fall(actor)
    CDoom.a_pain_shoot_skull(actor, actor.value.angle &+ ANG90)
    CDoom.a_pain_shoot_skull(actor, actor.value.angle &+ ANG180)
    CDoom.a_pain_shoot_skull(actor, actor.value.angle &+ ANG270)
  end

  def self.a_scream(actor : CDoom::Mobj*)
    sound = 0

    case actor.value.info.value.deathsound
    when 0
      return
    when CDoom::Sfxenum::SFX_podth1.value, CDoom::Sfxenum::SFX_podth2.value, CDoom::Sfxenum::SFX_podth3.value
      sound = CDoom::Sfxenum::SFX_podth1.value + CDoom.p_random % 3
    when CDoom::Sfxenum::SFX_bgdth1.value, CDoom::Sfxenum::SFX_bgdth2.value
      sound = CDoom::Sfxenum::SFX_bgdth1.value + CDoom.p_random % 2
    else
      sound = actor.value.info.value.deathsound
    end

    # Check for bosses.
    if actor.value.type == CDoom::Mobjtype::MT_SPIDER ||
       actor.value.type == CDoom::Mobjtype::MT_CYBORG
      # full volume
      CDoom.s_start_sound(Pointer(Void).null, sound)
    else
      CDoom.s_start_sound(actor, sound)
    end
  end

  def self.a_xscream(actor : CDoom::Mobj*)
    CDoom.s_start_sound(actor, CDoom::Sfxenum::SFX_slop.value)
  end

  def self.a_pain(actor : CDoom::Mobj*)
    if actor.value.info.value.painsound != 0
      CDoom.s_start_sound(actor, actor.value.info.value.painsound)
    end
  end

  def self.a_fall(actor : CDoom::Mobj*)
    # actor is on ground, it can be walked over
    actor.value.flags = actor.value.flags & ~CDoom::Mobjflag::MF_SOLID.value

    #  So change this if corpse objects
    # are meant to be obstacles.
  end

  def self.a_explode(thingy : CDoom::Mobj*)
    thingy = thingy.as(CDoom::Mobj*)
    CDoom.p_radius_attack(thingy, thingy.value.target, 128)
  end

  #
  # Possibly trigger special effects
  # if on first boss level
  #
  def self.a_boss_death(mo : CDoom::Mobj*)
    if CDoom.gamemode == CDoom::GameMode::Commercial
      return if CDoom.gamemap != 7

      return if mo.value.type != CDoom::Mobjtype::MT_FATSO &&
                mo.value.type != CDoom::Mobjtype::MT_BABY
    else
      case CDoom.gameepisode
      when 1
        return if CDoom.gamemap != 8
        return if mo.value.type != CDoom::Mobjtype::MT_BRUISER
      when 2
        return if CDoom.gamemap != 8
        return if mo.value.type != CDoom::Mobjtype::MT_CYBORG
      when 3
        return if CDoom.gamemap != 8
        return if mo.value.type != CDoom::Mobjtype::MT_SPIDER
      when 4
        case CDoom.gamemap
        when 6
          return if mo.value.type != CDoom::Mobjtype::MT_CYBORG
        when 8
          return if mo.value.type != CDoom::Mobjtype::MT_SPIDER
        else
          return
        end
      else
        return if CDoom.gamemap != 8
      end
    end

    # make sure there is a player alive for victory
    i = 0
    while i < CDoom::MAXPLAYERS
      break if CDoom.playeringame[i] != 0 && CDoom.players[i].health > 0
      i += 1
    end

    return if i == CDoom::MAXPLAYERS # no one left alive, so do not end game

    # scan the remaining thinkers to see
    # if all bosses are dead
    th = CDoom.thinkercap.next
    while th != pointerof(CDoom.thinkercap)
      if th.value.function.acp1.pointer != (->CDoom.p_mobj_thinker).pointer
        th = th.value.next
        next
      end

      mo2 = th.as(CDoom::Mobj*)
      if mo2 != mo &&
         mo2.value.type == mo.value.type &&
         mo2.value.health > 0
        # other boss not dead
        return
      end

      th = th.value.next
    end

    junk = CDoom::Line.new
    # victory!
    if CDoom.gamemode == CDoom::GameMode::Commercial
      if CDoom.gamemap == 7
        if mo.value.type == CDoom::Mobjtype::MT_FATSO
          junk.tag = 666
          CDoom.ev_do_floor(pointerof(junk), CDoom::Floorenum::LowerFloorToLowest)
          return
        end

        if mo.value.type == CDoom::Mobjtype::MT_BABY
          junk.tag = 667
          CDoom.ev_do_floor(pointerof(junk), CDoom::Floorenum::RaiseToTexture)
          return
        end
      end
    else
      case CDoom.gameepisode
      when 1
        junk.tag = 666
        CDoom.ev_do_floor(pointerof(junk), CDoom::Floorenum::LowerFloorToLowest)
        return
      when 4
        case CDoom.gamemap
        when 6
          junk.tag = 666
          CDoom.ev_do_door(pointerof(junk), CDoom::Vldoorenum::BlazeOpen)
          return
        when 8
          junk.tag = 666
          CDoom.ev_do_floor(pointerof(junk), CDoom::Floorenum::LowerFloorToLowest)
          return
        end
      end
    end

    CDoom.g_exit_level
  end

  def self.a_hoof(mo : CDoom::Mobj*)
    CDoom.s_start_sound(mo, CDoom::Sfxenum::SFX_hoof)
    CDoom.a_chase(mo)
  end

  def self.a_metal(mo : CDoom::Mobj*)
    CDoom.s_start_sound(mo, CDoom::Sfxenum::SFX_metal)
    CDoom.a_chase(mo)
  end

  def self.a_baby_metal(mo : CDoom::Mobj*)
    CDoom.s_start_sound(mo, CDoom::Sfxenum::SFX_bspwlk)
    CDoom.a_chase(mo)
  end

  def self.a_open_shotgun2(player : CDoom::Player*, psp : CDoom::Pspdef*)
    CDoom.s_start_sound(player.value.mo, CDoom::Sfxenum::SFX_dbopn)
  end

  def self.a_load_shotgun2(player : CDoom::Player*, psp : CDoom::Pspdef*)
    CDoom.s_start_sound(player.value.mo, CDoom::Sfxenum::SFX_dbload)
  end

  def self.a_close_shotgun2(player : CDoom::Player*, psp : CDoom::Pspdef*)
    CDoom.s_start_sound(player.value.mo, CDoom::Sfxenum::SFX_dbcls)
    CDoom.a_refire(player, psp)
  end

  def self.a_brain_awake(mo : CDoom::Mobj*)
    # find all the target spots
    CDoom.numbraintargets = 0
    CDoom.braintargeton = 0

    thinker = CDoom.thinkercap.next
    while thinker != pointerof(CDoom.thinkercap)
      if thinker.value.function.acp1.pointer != (->CDoom.p_mobj_thinker).pointer
        thinker = thinker.value.next
        next # not a mobj
      end

      m = thinker.as(CDoom::Mobj*)

      if m.value.type == CDoom::Mobjtype::MT_BOSSTARGET
        (CDoom.braintargets.to_unsafe + CDoom.numbraintargets).value = m
        CDoom.numbraintargets += 1
      end
      thinker = thinker.value.next
    end

    CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_bossit.value)
  end

  def self.a_brain_pain(mo : CDoom::Mobj*)
    CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_bospn)
  end

  def self.a_brain_scream(mo : CDoom::Mobj*)
    x = mo.value.x - 196 * FRACUNIT
    while x < mo.value.x + 320 * FRACUNIT
      y = mo.value.y - 320 * FRACUNIT
      z = 128 + CDoom.p_random * 2 * FRACUNIT
      th = CDoom.p_spawn_mobj(x, y, z, CDoom::Mobjtype::MT_ROCKET)
      th.value.momz = CDoom.p_random * 512

      CDoom.p_set_mobj_state(th, CDoom::Statenum::S_BRAINEXPLODE1)

      th.value.tics = th.value.tics - (CDoom.p_random & 7)
      th.value.tics = 1 if th.value.tics < 1

      x += FRACUNIT * 8
    end

    CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_bosdth)
  end

  def self.a_brain_explode(mo : CDoom::Mobj*)
    x = mo.value.x + (CDoom.p_random - CDoom.p_random) * 2048
    y = mo.value.y
    z = 128 + CDoom.p_random * 2 * FRACUNIT
    th = CDoom.p_spawn_mobj(x, y, z, CDoom::Mobjtype::MT_ROCKET)
    th.value.momz = CDoom.p_random * 512

    CDoom.p_set_mobj_state(th, CDoom::Statenum::S_BRAINEXPLODE1)

    th.value.tics = th.value.tics - (CDoom.p_random & 7)
    th.value.tics = 1 if th.value.tics < 1
  end

  def self.a_brain_die(mo : CDoom::Mobj*)
    CDoom.g_exit_level
  end

  @@easy = 0

  def self.a_brain_spit(mo : CDoom::Mobj*)
    @@easy ^= 1
    return if CDoom.gameskill <= CDoom::Skill::Easy && @@easy == 0

    # shoot a cube at current target
    targ = CDoom.braintargets[CDoom.braintargeton]
    CDoom.braintargeton = (CDoom.braintargeton + 1) % CDoom.numbraintargets

    # spawn brain missile
    newmobj = CDoom.p_spawn_missile(mo, targ, CDoom::Mobjtype::MT_SPAWNSHOT)
    newmobj.value.target = targ
    newmobj.value.reactiontime =
      ((targ.value.y - mo.value.y).tdiv(newmobj.value.momy)).tdiv(newmobj.value.state.value.tics)

    CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_bospit.value)
  end

  # travelling cube sound
  def self.a_spawn_sound(mo : CDoom::Mobj*)
    CDoom.s_start_sound(mo, CDoom::Sfxenum::SFX_boscub.value)
    CDoom.a_spawn_fly(mo)
  end

  def self.a_spawn_fly(mo : CDoom::Mobj*)
    mo.value.reactiontime = mo.value.reactiontime - 1
    return if mo.value.reactiontime != 0 # still flying

    targ = mo.value.target

    # First spawn teleport fog
    fog = CDoom.p_spawn_mobj(targ.value.x, targ.value.y, targ.value.z, CDoom::Mobjtype::MT_SPAWNFIRE)
    CDoom.s_start_sound(fog, CDoom::Sfxenum::SFX_telept.value)

    # Randomly select monster to spawn.
    r = CDoom.p_random

    type = CDoom::Mobjtype::MT_BRUISER
    # Probability distribution (kind of :),
    # decreasing likelihood
    if r < 50
      type = CDoom::Mobjtype::MT_TROOP
    elsif r < 90
      type = CDoom::Mobjtype::MT_SERGEANT
    elsif r < 120
      type = CDoom::Mobjtype::MT_SHADOWS
    elsif r < 130
      type = CDoom::Mobjtype::MT_PAIN
    elsif r < 160
      type = CDoom::Mobjtype::MT_HEAD
    elsif r < 162
      type = CDoom::Mobjtype::MT_VILE
    elsif r < 172
      type = CDoom::Mobjtype::MT_UNDEAD
    elsif r < 192
      type = CDoom::Mobjtype::MT_BABY
    elsif r < 222
      type = CDoom::Mobjtype::MT_FATSO
    elsif r < 246
      type = CDoom::Mobjtype::MT_KNIGHT
    end

    newmobj = CDoom.p_spawn_mobj(targ.value.x, targ.value.y, targ.value.z, type)
    CDoom.p_set_mobj_state(newmobj, CDoom::Statenum.new(newmobj.value.info.value.seestate)) if CDoom.p_look_for_players(newmobj, 1) != 0

    # telefrag anything in this spot
    CDoom.p_teleport_move(newmobj, newmobj.value.x, newmobj.value.y)

    # remove self (i.e., cube).
    CDoom.p_remove_mobj(mo)
  end

  def self.a_player_scream(mo : CDoom::Mobj*)
    # Default death sound.
    sound = CDoom::Sfxenum::SFX_pldeth

    if CDoom.gamemode == CDoom::GameMode::Commercial &&
       mo.value.health < -50
      # IF THE PLAYER DIES
      # LESS THAN -50% WITHOUT GIBBING
      sound = CDoom::Sfxenum::SFX_pdiehi
    end

    CDoom.s_start_sound(mo, sound.value)
  end

  def self.t_move_plane(sector : CDoom::Sector*, speed : CDoom::Fixed, dest : CDoom::Fixed, crush : CDoom::DoomBool, floor_or_ceiling : LibC::Int, direction : LibC::Int) : CDoom::Result
    case floor_or_ceiling
    when 0
      # FLOOR
      case direction
      when -1
        # DOWN
        if sector.value.floorheight - speed < dest
          lastpos = sector.value.floorheight
          sector.value.floorheight = dest
          flag = CDoom.p_change_sector(sector, crush)
          if flag != 0
            sector.value.floorheight = lastpos
            CDoom.p_change_sector(sector, crush)
            # return CDoom::Result::Crushed
          end
          return CDoom::Result::Pastdest
        else
          lastpos = sector.value.floorheight
          sector.value.floorheight = sector.value.floorheight - speed
          flag = CDoom.p_change_sector(sector, crush)
          if flag != 0
            sector.value.floorheight = lastpos
            CDoom.p_change_sector(sector, crush)
            return CDoom::Result::Crushed
          end
        end
      when 1
        # UP
        if sector.value.floorheight + speed > dest
          lastpos = sector.value.floorheight
          sector.value.floorheight = dest
          flag = CDoom.p_change_sector(sector, crush)
          if flag != 0
            sector.value.floorheight = lastpos
            CDoom.p_change_sector(sector, crush)
            # return CDoom::Result::Crushed
          end
          return CDoom::Result::Pastdest
        else
          # COULD GET CRUSHED
          lastpos = sector.value.floorheight
          sector.value.floorheight = sector.value.floorheight + speed
          flag = CDoom.p_change_sector(sector, crush)
          if flag != 0
            return CDoom::Result::Crushed if crush != 0
            sector.value.floorheight = lastpos
            CDoom.p_change_sector(sector, crush)
            return CDoom::Result::Crushed
          end
        end
      end
    when 1
      # CEILING
      case direction
      when -1
        # DOWN
        if sector.value.ceilingheight - speed < dest
          lastpos = sector.value.ceilingheight
          sector.value.ceilingheight = dest
          flag = CDoom.p_change_sector(sector, crush)

          if flag != 0
            sector.value.ceilingheight = lastpos
            CDoom.p_change_sector(sector, crush)
            # return CDoom::Result::Crushed
          end
          return CDoom::Result::Pastdest
        else
          # COULD GET CRUSHED
          lastpos = sector.value.ceilingheight
          sector.value.ceilingheight = sector.value.ceilingheight - speed
          flag = CDoom.p_change_sector(sector, crush)

          if flag != 0
            return CDoom::Result::Crushed if crush != 0
            sector.value.ceilingheight = lastpos
            CDoom.p_change_sector(sector, crush)
            return CDoom::Result::Crushed
          end
        end
      when 1
        # UP
        if sector.value.ceilingheight + speed > dest
          lastpos = sector.value.ceilingheight
          sector.value.ceilingheight = dest
          flag = CDoom.p_change_sector(sector, crush)
          if flag != 0
            sector.value.ceilingheight = lastpos
            CDoom.p_change_sector(sector, crush)
            # return CDoom::Result::Crushed
          end
          return CDoom::Result::Pastdest
        else
          lastpos = sector.value.ceilingheight
          sector.value.ceilingheight = sector.value.ceilingheight + speed
          flag = CDoom.p_change_sector(sector, crush)
          # UNUSED

          # if flag != 0
          #   sector.value.ceilingheight = lastpos
          #   CDoom.p_change_sector(sector, crush)
          #   return CDoom::Result::Crushed
        end
      end
    end

    return CDoom::Result::Ok
  end

  #
  # MOVE A FLOOR TO IT'S DESTINATION (UP OR DOWN)
  #
  def self.t_move_floor(floor : CDoom::Floormove*)
    res = CDoom.t_move_plane(floor.value.sector,
      floor.value.speed,
      floor.value.floordestheight,
      floor.value.crush, 0, floor.value.direction)

    CDoom.s_start_sound(pointerof(floor.value.sector.value.@soundorg),
      CDoom::Sfxenum::SFX_stnmov) if CDoom.leveltime & 7 == 0

    if res == CDoom::Result::Pastdest
      floor.value.sector.value.specialdata = Pointer(Void).null

      if floor.value.direction == 1
        case floor.value.type
        when CDoom::Floorenum::DonutRaise
          floor.value.sector.value.special = floor.value.newspecial
          floor.value.sector.value.floorpic = floor.value.texture
        end
      elsif floor.value.direction == -1
        case floor.value.type
        when CDoom::Floorenum::LowerAndChange
          floor.value.sector.value.special = floor.value.newspecial
          floor.value.sector.value.floorpic = floor.value.texture
        end
      end
      CDoom.p_remove_thinker(pointerof(floor.value.@thinker))

      CDoom.s_start_sound(pointerof(floor.value.sector.value.@soundorg),
        CDoom::Sfxenum::SFX_pstop)
    end
  end

  def self.ev_do_floor(line : CDoom::Line*, floortype : CDoom::Floorenum) : LibC::Int
    secnum = -1
    rtn = 0
    while (secnum = CDoom.p_find_sector_from_line_tag(line, secnum)) >= 0
      sec = CDoom.sectors + secnum

      # ALREADY MOVING?  IF SO, KEEP GOING...
      next unless sec.value.specialdata.null?

      # new floor thinker
      rtn = 1
      floor = CDoom.z_malloc(sizeof(CDoom::Floormove), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Floormove*)
      CDoom.p_add_thinker(pointerof(floor.value.@thinker))
      sec.value.specialdata = floor
      pointerof(floor.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_move_floor).pointer, Pointer(Void).null)
      floor.value.type = floortype
      floor.value.crush = 0

      case floortype
      when CDoom::Floorenum::LowerFloor
        floor.value.direction = -1
        floor.value.sector = sec
        floor.value.speed = CDoom::FLOORSPEED
        floor.value.floordestheight =
          CDoom.p_find_highest_floor_surrounding(sec)
      when CDoom::Floorenum::LowerFloorToLowest
        floor.value.direction = -1
        floor.value.sector = sec
        floor.value.speed = CDoom::FLOORSPEED
        floor.value.floordestheight =
          CDoom.p_find_lowest_floor_surrounding(sec)
      when CDoom::Floorenum::TurboLower
        floor.value.direction = -1
        floor.value.sector = sec
        floor.value.speed = CDoom::FLOORSPEED * 4
        floor.value.floordestheight =
          CDoom.p_find_highest_floor_surrounding(sec)
        if floor.value.floordestheight != sec.value.floorheight
          floor.value.floordestheight = floor.value.floordestheight + 8 * FRACUNIT
        end
      when CDoom::Floorenum::RaiseFloor, CDoom::Floorenum::RaiseFloorCrush
        floor.value.crush = 1 if floortype == CDoom::Floorenum::RaiseFloorCrush
        floor.value.direction = 1
        floor.value.sector = sec
        floor.value.speed = CDoom::FLOORSPEED
        floor.value.floordestheight =
          CDoom.p_find_lowest_ceiling_surrounding(sec)
        if floor.value.floordestheight > sec.value.ceilingheight
          floor.value.floordestheight = sec.value.ceilingheight
        end
        floor.value.floordestheight = floor.value.floordestheight - ((8 * FRACUNIT) * (floortype == CDoom::Floorenum::RaiseFloorCrush).to_unsafe)
      when CDoom::Floorenum::RaiseFloorTurbo
        floor.value.direction = 1
        floor.value.sector = sec
        floor.value.speed = CDoom::FLOORSPEED * 4
        floor.value.floordestheight =
          CDoom.p_find_next_highest_floor(sec, sec.value.floorheight)
      when CDoom::Floorenum::RaiseFloorToNearest
        floor.value.direction = 1
        floor.value.sector = sec
        floor.value.speed = CDoom::FLOORSPEED
        floor.value.floordestheight =
          CDoom.p_find_next_highest_floor(sec, sec.value.floorheight)
      when CDoom::Floorenum::RaiseFloor24
        floor.value.direction = 1
        floor.value.sector = sec
        floor.value.speed = CDoom::FLOORSPEED
        floor.value.floordestheight = floor.value.sector.value.floorheight +
                                      24 * FRACUNIT
      when CDoom::Floorenum::RaiseFloor512
        floor.value.direction = 1
        floor.value.sector = sec
        floor.value.speed = CDoom::FLOORSPEED
        floor.value.floordestheight = floor.value.sector.value.floorheight +
                                      512 * FRACUNIT
      when CDoom::Floorenum::RaiseFloor24AndChange
        floor.value.direction = 1
        floor.value.sector = sec
        floor.value.speed = CDoom::FLOORSPEED
        floor.value.floordestheight = floor.value.sector.value.floorheight +
                                      24 * FRACUNIT
        sec.value.floorpic = line.value.frontsector.value.floorpic
        sec.value.special = line.value.frontsector.value.special
      when CDoom::Floorenum::RaiseToTexture
        minsize = Int32::MAX

        floor.value.direction = 1
        floor.value.sector = sec
        floor.value.speed = CDoom::FLOORSPEED
        sec.value.linecount.times do |i|
          if CDoom.two_sided(secnum, i) != 0
            side = CDoom.get_side(secnum, i, 0)
            if side.value.bottomtexture >= 0
              if CDoom.textureheight[side.value.bottomtexture] < minsize
                minsize = CDoom.textureheight[side.value.bottomtexture]
              end
            end
            side = CDoom.get_side(secnum, i, 1)
            if side.value.bottomtexture >= 0
              if CDoom.textureheight[side.value.bottomtexture] < minsize
                minsize = CDoom.textureheight[side.value.bottomtexture]
              end
            end
          end
        end
        floor.value.floordestheight =
          floor.value.sector.value.floorheight + minsize
      when CDoom::Floorenum::LowerAndChange
        floor.value.direction = -1
        floor.value.sector = sec
        floor.value.speed = CDoom::FLOORSPEED
        floor.value.floordestheight =
          CDoom.p_find_lowest_floor_surrounding(sec)
        floor.value.texture = sec.value.floorpic

        sec.value.linecount.times do |i|
          if CDoom.two_sided(secnum, i) != 0
            if CDoom.get_side(secnum, i, 0).value.sector - CDoom.sectors == secnum
              sec = CDoom.get_sector(secnum, i, 1)

              if sec.value.floorheight == floor.value.floordestheight
                floor.value.texture = sec.value.floorpic
                floor.value.newspecial = sec.value.special
                break
              end
            else
              sec = CDoom.get_sector(secnum, i, 0)

              if sec.value.floorheight == floor.value.floordestheight
                floor.value.texture = sec.value.floorpic
                floor.value.newspecial = sec.value.special
                break
              end
            end
          end
        end
      end
    end

    return rtn
  end

  #
  # BUILD A STAIRCASE!
  #
  def self.ev_build_stairs(line : CDoom::Line*, type : CDoom::Stairenum) : LibC::Int
    secnum = -1
    rtn = 0
    while (secnum = CDoom.p_find_sector_from_line_tag(line, secnum)) >= 0
      sec = CDoom.sectors + secnum

      # ALREADY MOVING?  IF SO, KEEP GOING...
      next unless sec.value.specialdata.null?

      # new floor thinker
      rtn = 1
      floor = CDoom.z_malloc(sizeof(CDoom::Floormove), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Floormove*)
      CDoom.p_add_thinker(pointerof(floor.value.@thinker))
      sec.value.specialdata = floor
      pointerof(floor.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_move_floor).pointer, Pointer(Void).null)
      floor.value.direction = 1
      floor.value.sector = sec
      speed = 0
      stairsize = 0
      case type
      when CDoom::Stairenum::Build8
        speed = CDoom::FLOORSPEED // 4
        stairsize = 8 * FRACUNIT
      when CDoom::Stairenum::Turbo16
        speed = CDoom::FLOORSPEED * 4
        stairsize = 16 * FRACUNIT
      end
      floor.value.speed = speed
      height = sec.value.floorheight + stairsize
      floor.value.floordestheight = height

      texture = sec.value.floorpic
      # Find next sector to raise
      # 1.        Find 2-sided line with same sector side[0]
      # 2.        Other side is the next sector to raise
      loop do
        ok = 0
        sec.value.linecount.times do |i|
          next if ((sec.value.lines[i]).value.flags & CDoom::ML_TWOSIDED) == 0

          tsec = (sec.value.lines[i]).value.frontsector
          newsecnum = (tsec - CDoom.sectors).to_i32!

          next if secnum != newsecnum

          tsec = (sec.value.lines[i]).value.backsector
          newsecnum = (tsec - CDoom.sectors).to_i32!

          next if tsec.value.floorpic != texture

          height += stairsize

          next unless tsec.value.specialdata.null?

          sec = tsec
          secnum = newsecnum
          floor = CDoom.z_malloc(sizeof(CDoom::Floormove), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Floormove*)

          CDoom.p_add_thinker(pointerof(floor.value.@thinker))

          sec.value.specialdata = floor
          pointerof(floor.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_move_floor).pointer, Pointer(Void).null)
          floor.value.direction = 1
          floor.value.sector = sec
          floor.value.speed = speed
          floor.value.floordestheight = height
          ok = 1
          break
        end
        break unless ok != 0
      end
    end
    return rtn
  end

  #
  # GET STUFF
  #

  #
  # Num is the number of clip loads,
  # not the individual count (0= 1/2 clip).
  # Returns false if the ammo can't be picked up at all
  #
  def self.p_give_ammo(player : CDoom::Player*, ammo : CDoom::Ammotype, num : LibC::Int) : CDoom::DoomBool
    return 0 if ammo == CDoom::Ammotype::Noammo

    if ammo.value < 0 || ammo.value > CDoom::Ammotype::NUMAMMO.value
      CDoom.i_error("p_give_ammo: bad type #{ammo}")
    end

    return 0 if player.value.ammo[ammo.value] == player.value.maxammo[ammo.value]

    if num != 0
      num *= CDoom.clipammo[ammo.value]
    else
      num = CDoom.clipammo[ammo.value] // 2
    end

    if CDoom.gameskill == CDoom::Skill::Baby ||
       CDoom.gameskill == CDoom::Skill::Nightmare
      # give double ammo in trainer mode,
      # you'll need in nightmare
      num <<= 1
    end

    oldammo = player.value.ammo[ammo.value]
    (player.value.ammo.to_unsafe + ammo.value).value = player.value.ammo[ammo.value] + num

    (player.value.ammo.to_unsafe + ammo.value).value = player.value.maxammo[ammo.value] if player.value.ammo[ammo.value] > player.value.maxammo[ammo.value]

    # If non zero ammo,
    # don't change up weapons,
    # player was lower on purpose.
    return 1 if oldammo != 0

    # We were down to zero,
    # so select a new weapon.
    # Preferences are not user selectable.
    case ammo
    when CDoom::Ammotype::Clip
      if player.value.readyweapon == CDoom::Weapontype::Fist
        if player.value.weaponowned[CDoom::Weapontype::Chaingun.value] != 0
          player.value.pendingweapon = CDoom::Weapontype::Chaingun
        else
          player.value.pendingweapon = CDoom::Weapontype::Pistol
        end
      end
    when CDoom::Ammotype::Shell
      if player.value.readyweapon == CDoom::Weapontype::Fist ||
         player.value.readyweapon == CDoom::Weapontype::Pistol
        if player.value.weaponowned[CDoom::Weapontype::Shotgun.value] != 0
          player.value.pendingweapon = CDoom::Weapontype::Shotgun
        end
      end
    when CDoom::Ammotype::Cell
      if player.value.readyweapon == CDoom::Weapontype::Fist ||
         player.value.readyweapon == CDoom::Weapontype::Pistol
        if player.value.weaponowned[CDoom::Weapontype::Plasma.value] != 0
          player.value.pendingweapon = CDoom::Weapontype::Plasma
        end
      end
    when CDoom::Ammotype::Misl
      if player.value.readyweapon == CDoom::Weapontype::Fist
        if player.value.weaponowned[CDoom::Weapontype::Missile.value] != 0
          player.value.pendingweapon = CDoom::Weapontype::Missile
        end
      end
    end
    return 1
  end

  #
  # The weapon name may have a MF_DROPPED flag ored in.
  #
  def self.p_give_weapon(player : CDoom::Player*, weapon : CDoom::Weapontype, dropped : CDoom::DoomBool) : CDoom::DoomBool
    gaveammo = 0
    gaveweapon = 0

    if CDoom.netgame != 0 &&
       CDoom.deathmatch != 2 &&
       dropped == 0
      # leave placed weapons forever on net games
      return 0 if player.value.weaponowned[weapon.value] != 0

      player.value.bonuscount = player.value.bonuscount + CDoom::BONUSADD
      player.value.weaponowned[weapon.value] = 1

      if CDoom.deathmatch != 0
        CDoom.p_give_ammo(player, CDoom.weaponinfo[weapon.value].ammo, 5)
      else
        CDoom.p_give_ammo(player, CDoom.weaponinfo[weapon.value].ammo, 2)
      end
      player.value.pendingweapon = weapon

      if player == CDoom.players.to_unsafe + CDoom.consoleplayer
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_wpnup)
      end
      return 0
    end

    if CDoom.weaponinfo[weapon.value].ammo != CDoom::Ammotype::Noammo
      # give one clip with a dropped weapon,
      # two clips with a found weapon
      if dropped != 0
        gaveammo = CDoom.p_give_ammo(player, CDoom.weaponinfo[weapon.value].ammo, 1)
      else
        gaveammo = CDoom.p_give_ammo(player, CDoom.weaponinfo[weapon.value].ammo, 2)
      end
    else
      gaveammo = 0
    end

    if player.value.weaponowned[weapon.value] != 0
      gaveweapon = 0
    else
      gaveweapon = 1
      player.value.weaponowned[weapon.value] = 1
      player.value.pendingweapon = weapon
    end

    return (gaveweapon != 0 || gaveammo != 0).to_unsafe
  end

  #
  # Returns false if the body isn't needed at all
  #
  def self.p_give_body(player : CDoom::Player*, num : LibC::Int) : CDoom::DoomBool
    return 0 if player.value.health >= CDoom::MAXHEALTH

    player.value.health = player.value.health + num
    player.value.health = CDoom::MAXHEALTH if player.value.health > CDoom::MAXHEALTH
    player.value.mo.value.health = player.value.health

    return 1
  end

  #
  # Returns false if the armor is worse
  # than the current armor.
  #
  def self.p_give_armor(player : CDoom::Player*, armortype : LibC::Int) : CDoom::DoomBool
    hits = armortype*100
    return 0 if player.value.armorpoints >= hits # don't pick up
    player.value.armortype = armortype
    player.value.armorpoints = hits

    return 1
  end

  def self.p_give_card(player : CDoom::Player*, card : CDoom::Card)
    return if player.value.cards[card.value] != 0

    player.value.bonuscount = CDoom::BONUSADD
    player.value.cards[card.value] = 1
  end

  def self.p_give_power(player : CDoom::Player*, power : LibC::Int) : CDoom::DoomBool
    if power == CDoom::Powertype::Invulnerability.value
      player.value.powers[power] = CDoom::Powerduration::INVULNTICS.value
      return 1
    end

    if power == CDoom::Powertype::Invisibility.value
      player.value.powers[power] = CDoom::Powerduration::INVISTICS.value
      player.value.mo.value.flags = player.value.mo.value.flags | CDoom::Mobjflag::MF_SHADOW.value
      return 1
    end

    if power == CDoom::Powertype::Infrared.value
      player.value.powers[power] = CDoom::Powerduration::INFRATICS.value
      return 1
    end

    if power == CDoom::Powertype::Ironfeet.value
      player.value.powers[power] = CDoom::Powerduration::IRONTICS.value
      return 1
    end

    if power == CDoom::Powertype::Strength.value
      CDoom.p_give_body(player, 100)
      player.value.powers[power] = 1
      return 1
    end

    return 0 if player.value.powers[power] != 0 # already got it

    player.value.powers[power] = 1
    return 1
  end

  def self.p_touch_special_thing(special : CDoom::Mobj*, toucher : CDoom::Mobj*)
    delta = special.value.z - toucher.value.z

    if delta > toucher.value.height ||
       delta < -8*FRACUNIT
      # out of reach
      return
    end

    sound = CDoom::Sfxenum::SFX_itemup
    player = toucher.value.player

    # Dead thing touching.
    # Can happen with a sliding player corpse.
    return if toucher.value.health <= 0

    # Identify by sprite
    case special.value.sprite
    # armor
    when CDoom::Spritenum::SPR_ARM1
      return if CDoom.p_give_armor(player, @@deh_green_armor_class) == 0
      player.value.message = @@deh_gotarmor
    when CDoom::Spritenum::SPR_ARM2
      return if CDoom.p_give_armor(player, @@deh_blue_armor_class) == 0
      player.value.message = @@deh_gotmega

      # bonus items
    when CDoom::Spritenum::SPR_BON1
      player.value.health = player.value.health + 1 # can go over 100%
      player.value.health = @@deh_max_health if player.value.health > @@deh_max_health
      player.value.mo.value.health = player.value.health
      player.value.message = @@deh_goththbonus
    when CDoom::Spritenum::SPR_BON2
      player.value.armorpoints = player.value.armorpoints + 1 # can go over 100%
      player.value.armorpoints = @@deh_max_armor if player.value.armorpoints > @@deh_max_armor
      player.value.armortype = 1 if player.value.armortype == 0
      player.value.message = @@deh_gotarmbonus
    when CDoom::Spritenum::SPR_SOUL
      player.value.health = player.value.health + @@deh_soulsphere_health
      player.value.health = @@deh_max_soulsphere if player.value.health > @@deh_max_soulsphere
      player.value.mo.value.health = player.value.health
      player.value.message = @@deh_gotsuper
      sound = CDoom::Sfxenum::SFX_getpow
    when CDoom::Spritenum::SPR_MEGA
      return if CDoom.gamemode != CDoom::GameMode::Commercial
      player.value.health = @@deh_megasphere_health
      player.value.mo.value.health = player.value.health
      CDoom.p_give_armor(player, 2)
      player.value.message = @@deh_gotmsphere
      sound = CDoom::Sfxenum::SFX_getpow

      # card
      # leave cards for everyone
    when CDoom::Spritenum::SPR_BKEY
      if player.value.cards[CDoom::Card::Bluecard.value] == 0
        player.value.message = @@deh_gotbluecard
      end
      CDoom.p_give_card(player, CDoom::Card::Bluecard)
      return if CDoom.netgame != 0
    when CDoom::Spritenum::SPR_YKEY
      if player.value.cards[CDoom::Card::Yellowcard.value] == 0
        player.value.message = @@deh_gotyelwcard
      end
      CDoom.p_give_card(player, CDoom::Card::Yellowcard)
      return if CDoom.netgame != 0
    when CDoom::Spritenum::SPR_RKEY
      if player.value.cards[CDoom::Card::Redcard.value] == 0
        player.value.message = @@deh_gotredcard
      end
      CDoom.p_give_card(player, CDoom::Card::Redcard)
      return if CDoom.netgame != 0
    when CDoom::Spritenum::SPR_BSKU
      if player.value.cards[CDoom::Card::Blueskull.value] == 0
        player.value.message = @@deh_gotblueskul
      end
      CDoom.p_give_card(player, CDoom::Card::Blueskull)
      return if CDoom.netgame != 0
    when CDoom::Spritenum::SPR_RSKU
      if player.value.cards[CDoom::Card::Redskull.value] == 0
        player.value.message = @@deh_gotredskull
      end
      CDoom.p_give_card(player, CDoom::Card::Redskull)
      return if CDoom.netgame != 0
    when CDoom::Spritenum::SPR_YSKU
      if player.value.cards[CDoom::Card::Yellowskull.value] == 0
        player.value.message = @@deh_gotyelwskul
      end
      CDoom.p_give_card(player, CDoom::Card::Yellowskull)
      return if CDoom.netgame != 0

      # medikits, heals
    when CDoom::Spritenum::SPR_STIM
      return if CDoom.p_give_body(player, 10) == 0
      player.value.message = @@deh_gotstim
    when CDoom::Spritenum::SPR_MEDI
      return if CDoom.p_give_body(player, 25) == 0

      if (player.value.health - 25) < 25
        player.value.message = @@deh_gotmedineed
      else
        player.value.message = @@deh_gotmedikit
      end
    when CDoom::Spritenum::SPR_PINV
      return if CDoom.p_give_power(player, CDoom::Powertype::Invulnerability.value) == 0
      player.value.message = @@deh_gotinvul
      sound = CDoom::Sfxenum::SFX_getpow
    when CDoom::Spritenum::SPR_PSTR
      return if CDoom.p_give_power(player, CDoom::Powertype::Strength.value) == 0
      player.value.message = @@deh_gotberserk
      player.value.pendingweapon = CDoom::Weapontype::Fist if player.value.readyweapon != CDoom::Weapontype::Fist
      sound = CDoom::Sfxenum::SFX_getpow
    when CDoom::Spritenum::SPR_PINS
      return if CDoom.p_give_power(player, CDoom::Powertype::Invisibility.value) == 0
      player.value.message = @@deh_gotinvis
      sound = CDoom::Sfxenum::SFX_getpow
    when CDoom::Spritenum::SPR_SUIT
      return if CDoom.p_give_power(player, CDoom::Powertype::Ironfeet.value) == 0
      player.value.message = @@deh_gotsuit
      sound = CDoom::Sfxenum::SFX_getpow
    when CDoom::Spritenum::SPR_PMAP
      return if CDoom.p_give_power(player, CDoom::Powertype::Allmap.value) == 0
      player.value.message = @@deh_gotmap
      sound = CDoom::Sfxenum::SFX_getpow
    when CDoom::Spritenum::SPR_PVIS
      return if CDoom.p_give_power(player, CDoom::Powertype::Infrared.value) == 0
      player.value.message = @@deh_gotvisor
      sound = CDoom::Sfxenum::SFX_getpow

      # ammo
    when CDoom::Spritenum::SPR_CLIP
      if special.value.flags & CDoom::Mobjflag::MF_DROPPED.value != 0
        return if CDoom.p_give_ammo(player, CDoom::Ammotype::Clip, 0) == 0
      else
        return if CDoom.p_give_ammo(player, CDoom::Ammotype::Clip, 1) == 0
      end
      player.value.message = @@deh_gotclip
    when CDoom::Spritenum::SPR_AMMO
      return if CDoom.p_give_ammo(player, CDoom::Ammotype::Clip, 5) == 0
      player.value.message = @@deh_gotclipbox
    when CDoom::Spritenum::SPR_ROCK
      return if CDoom.p_give_ammo(player, CDoom::Ammotype::Misl, 1) == 0
      player.value.message = @@deh_gotrocket
    when CDoom::Spritenum::SPR_BROK
      return if CDoom.p_give_ammo(player, CDoom::Ammotype::Misl, 5) == 0
      player.value.message = @@deh_gotrockbox
    when CDoom::Spritenum::SPR_CELL
      return if CDoom.p_give_ammo(player, CDoom::Ammotype::Cell, 1) == 0
      player.value.message = @@deh_gotcell
    when CDoom::Spritenum::SPR_CELP
      return if CDoom.p_give_ammo(player, CDoom::Ammotype::Cell, 5) == 0
      player.value.message = @@deh_gotcellbox
    when CDoom::Spritenum::SPR_SHEL
      return if CDoom.p_give_ammo(player, CDoom::Ammotype::Shell, 1) == 0
      player.value.message = @@deh_gotshells
    when CDoom::Spritenum::SPR_SBOX
      return if CDoom.p_give_ammo(player, CDoom::Ammotype::Shell, 5) == 0
      player.value.message = @@deh_gotshellbox
    when CDoom::Spritenum::SPR_BPAK
      if player.value.backpack == 0
        CDoom::Ammotype::NUMAMMO.value.times do |i|
          player.value.maxammo[i] = player.value.maxammo[i] * 2
        end
        player.value.backpack = 1
      end
      CDoom::Ammotype::NUMAMMO.value.times do |i|
        CDoom.p_give_ammo(player, CDoom::Ammotype.new(i), 1)
      end
      player.value.message = @@deh_gotbackpack

      # weapons
    when CDoom::Spritenum::SPR_BFUG
      return if CDoom.p_give_weapon(player, CDoom::Weapontype::Bfg, 0) == 0
      player.value.message = @@deh_gotbfg9000
      sound = CDoom::Sfxenum::SFX_wpnup
    when CDoom::Spritenum::SPR_MGUN
      return if CDoom.p_give_weapon(player, CDoom::Weapontype::Chaingun, (special.value.flags & CDoom::Mobjflag::MF_DROPPED.value != 0).to_unsafe) == 0
      player.value.message = @@deh_gotchaingun
      sound = CDoom::Sfxenum::SFX_wpnup
    when CDoom::Spritenum::SPR_CSAW
      return if CDoom.p_give_weapon(player, CDoom::Weapontype::Chainsaw, 0) == 0
      player.value.message = @@deh_gotchainsaw
      sound = CDoom::Sfxenum::SFX_wpnup
    when CDoom::Spritenum::SPR_LAUN
      return if CDoom.p_give_weapon(player, CDoom::Weapontype::Missile, 0) == 0
      player.value.message = @@deh_gotlauncher
      sound = CDoom::Sfxenum::SFX_wpnup
    when CDoom::Spritenum::SPR_PLAS
      return if CDoom.p_give_weapon(player, CDoom::Weapontype::Plasma, 0) == 0
      player.value.message = @@deh_gotplasma
      sound = CDoom::Sfxenum::SFX_wpnup
    when CDoom::Spritenum::SPR_SHOT
      return if CDoom.p_give_weapon(player, CDoom::Weapontype::Shotgun, (special.value.flags & CDoom::Mobjflag::MF_DROPPED.value != 0).to_unsafe) == 0
      player.value.message = @@deh_gotshotgun
      sound = CDoom::Sfxenum::SFX_wpnup
    when CDoom::Spritenum::SPR_SGN2
      return if CDoom.p_give_weapon(player, CDoom::Weapontype::Supershotgun, (special.value.flags & CDoom::Mobjflag::MF_DROPPED.value != 0).to_unsafe) == 0
      player.value.message = @@deh_gotshotgun2
      sound = CDoom::Sfxenum::SFX_wpnup
    else
      CDoom.i_error("p_special_thing: Unknown gettable thing")
    end

    player.value.itemcount = player.value.itemcount + 1 if special.value.flags & CDoom::Mobjflag::MF_COUNTITEM.value != 0
    CDoom.p_remove_mobj(special)
    player.value.bonuscount = player.value.bonuscount + CDoom::BONUSADD
    CDoom.s_start_sound(Pointer(Void).null, sound.value) if player == CDoom.players.to_unsafe + CDoom.consoleplayer
  end

  def self.p_kill_mobj(source : CDoom::Mobj*, target : CDoom::Mobj*)
    target.value.flags = target.value.flags & ~(CDoom::Mobjflag::MF_SHOOTABLE.value | CDoom::Mobjflag::MF_FLOAT.value | CDoom::Mobjflag::MF_SKULLFLY.value)

    target.value.flags = target.value.flags & ~CDoom::Mobjflag::MF_NOGRAVITY.value if target.value.type != CDoom::Mobjtype::MT_SKULL

    target.value.flags = target.value.flags | (CDoom::Mobjflag::MF_CORPSE.value | CDoom::Mobjflag::MF_DROPOFF.value)
    target.value.height = target.value.height >> 2

    if !source.null? && !source.value.player.null?
      # count for intermission
      source.value.player.value.killcount = source.value.player.value.killcount + 1 if target.value.flags & CDoom::Mobjflag::MF_COUNTKILL.value != 0

      if !target.value.player.null?
        unless CDoom.netgame == 0
          srcplr = source.value.player - CDoom.players.to_unsafe
          trgtplr = target.value.player - CDoom.players.to_unsafe
          source.value.player.value.frags[trgtplr] =
            source.value.player.value.frags[trgtplr] + 1

          if srcplr == trgtplr
            # Suicide
            strings = CDoom.consoleplayer == srcplr ? @@suic_strings : @@suic_see_strings
          else
            strings = CDoom.deathmatch != 0 ? # Deathmatch strings
(CDoom.consoleplayer == srcplr ? @@death_kill_strings : (
              CDoom.consoleplayer == trgtplr ? @@death_dead_strings : @@death_nut_strings
            ) # Coop strings
) : CDoom.consoleplayer == srcplr ? @@net_kill_strings : (
              CDoom.consoleplayer == trgtplr ? @@net_dead_strings : @@net_nut_strings
            )
          end

          (CDoom.players.to_unsafe + CDoom.consoleplayer).value.message =
            strings.sample(Random.new(CDoom.m_random)).gsub(
              '1', String.new(CDoom.player_names[srcplr])[...-2]).gsub(
              '2', String.new(CDoom.player_names[trgtplr])[...-2])
        end
      end
    elsif CDoom.netgame == 0 && target.value.flags & CDoom::Mobjflag::MF_COUNTKILL.value != 0
      # count all monster deaths,
      # even those caused by other monsters
      CDoom.players.to_unsafe.value.killcount = CDoom.players[0].killcount + 1
    end

    if !target.value.player.null?
      if source.null? || source.value.player.null? &&                         # Player was not killed by player
         target.value.player - CDoom.players.to_unsafe != CDoom.consoleplayer # Isn't self. They know they died
        (CDoom.players.to_unsafe + CDoom.consoleplayer).value.message =
          @@died_strings.sample(Random.new(CDoom.m_random)).gsub(
            '1', String.new(CDoom.player_names[target.value.player - CDoom.players.to_unsafe])[...-2])
      end

      # count environment kills against you
      target.value.player.value.frags[target.value.player - CDoom.players.to_unsafe] =
        target.value.player.value.frags[target.value.player - CDoom.players.to_unsafe] + 1 if source.null?

      target.value.flags = target.value.flags & ~CDoom::Mobjflag::MF_SOLID.value
      target.value.player.value.playerstate = CDoom::Playerstate::PST_DEAD
      CDoom.p_drop_weapon(target.value.player)

      if target.value.player == CDoom.players.to_unsafe + CDoom.consoleplayer &&
         CDoom.automapactive != 0
        # don't die in automap,
        # siwtch view prior to dying
        CDoom.am_stop
      end
    end

    if target.value.health < -target.value.info.value.spawnhealth &&
       target.value.info.value.xdeathstate != 0
      CDoom.p_set_mobj_state(target, CDoom::Statenum.new(target.value.info.value.xdeathstate))
    else
      CDoom.p_set_mobj_state(target, CDoom::Statenum.new(target.value.info.value.deathstate))
    end

    target.value.tics = target.value.tics - (CDoom.p_random & 3)

    target.value.tics = 1 if target.value.tics < 1

    item = CDoom::Mobjtype::MT_CLIP
    # Drop stuff.
    # This determines the kind of object spawned
    # during the death frame of a thing.
    case target.value.type
    when CDoom::Mobjtype::MT_WOLFSS, CDoom::Mobjtype::MT_POSSESSED
      item = CDoom::Mobjtype::MT_CLIP
    when CDoom::Mobjtype::MT_SHOTGUY
      item = CDoom::Mobjtype::MT_SHOTGUN
    when CDoom::Mobjtype::MT_CHAINGUY
      item = CDoom::Mobjtype::MT_CHAINGUN
    else
      return
    end

    mo = CDoom.p_spawn_mobj(target.value.x, target.value.y, CDoom::ONFLOORZ, item)

    mo.value.flags = mo.value.flags | CDoom::Mobjflag::MF_DROPPED.value # special versions of items
  end

  #
  # Damages both enemies and players
  # "inflictor" is the thing that caused the damage
  #  creature or missile, can be 0 (slime, etc)
  # "source" is the thing to target after taking damage
  #  creature or 0
  # Source and inflictor are the same for melee attacks.
  # Source can be 0 for slime, barrel explosions
  # and other environmental stuff.
  #
  def self.p_damage_mobj(target : CDoom::Mobj*, inflictor : CDoom::Mobj*, source : CDoom::Mobj*, damage : LibC::Int)
    return if target.value.flags & CDoom::Mobjflag::MF_SHOOTABLE.value == 0 # shouldn't happen...

    return if target.value.health <= 0

    if target.value.flags & CDoom::Mobjflag::MF_SKULLFLY.value != 0
      target.value.momx = 0
      target.value.momy = 0
      target.value.momz = 0
    end

    damage <<= 1 if !source.null? &&
                    !source.value.player.null? &&
                    source.value.player.value.cheats & CDoom::Cheat::CF_ME.value != 0 # Double damage in me mode!

    player = target.value.player
    damage >>= 1 if !player.null? && CDoom.gameskill == CDoom::Skill::Baby # take half damage in trainer mode

    # Some close combat weapons should not
    # inflict thrust and push the victim out of reach,
    # thus kick away unless using the chainsaw.
    if !inflictor.null? &&
       target.value.flags & CDoom::Mobjflag::MF_NOCLIP.value == 0 &&
       (source.null? ||
       source.value.player.null? ||
       source.value.player.value.readyweapon != CDoom::Weapontype::Chainsaw)
      ang = CDoom.r_point_to_angle2(inflictor.value.x,
        inflictor.value.y,
        target.value.x,
        target.value.y)

      thrust = damage*(FRACUNIT >> 3) &* 100.tdiv(target.value.info.value.mass)

      # make fall forwards sometimes
      if damage < 40 &&
         damage > target.value.health &&
         target.value.z - inflictor.value.z > 64*FRACUNIT &&
         (CDoom.p_random & 1) != 0
        ang &+= ANG180
        thrust *= 4
      end

      ang >>= CDoom::ANGLETOFINESHIFT
      target.value.momx = target.value.momx + CDoom.fixed_mul(thrust, @@finecosine[ang])
      target.value.momy = target.value.momy + CDoom.fixed_mul(thrust, @@finesine[ang])
    end

    # player specific
    if !player.null?
      # end of game hell hack
      if target.value.subsector.value.sector.value.special == 11 &&
         damage >= target.value.health
        damage = target.value.health - 1
      end

      # Below certain threshold,
      # ignore damage in GOD mode, or with INVUL power.
      if damage < 1000 &&
         (player.value.cheats & CDoom::Cheat::CF_GODMODE.value != 0 ||
         player.value.powers[CDoom::Powertype::Invulnerability.value] != 0)
        return
      end

      if player.value.armortype != 0
        saved = damage//2
        saved = damage//3 if player.value.armortype == 1

        if player.value.armorpoints <= saved
          # armor is used up
          saved = player.value.armorpoints
          player.value.armortype = 0
        end

        player.value.armorpoints = player.value.armorpoints - saved
        damage -= saved
      end
      player.value.health = player.value.health - damage # mirror mobj health here for Dave
      player.value.health = 0 if player.value.health < 0

      player.value.attacker = source
      player.value.damagecount = player.value.damagecount + damage # add damage after armor / invuln

      player.value.damagecount = 100 if player.value.damagecount > 100 # teleport does 10k points...

      temp = damage < 100 ? damage : 100

      if player == CDoom.players.to_unsafe + CDoom.consoleplayer
        CDoom.i_tactile(40, 10, 40 + temp*2)
      end
    end

    # do the damage
    target.value.health = target.value.health - damage
    if target.value.health <= 0
      CDoom.p_kill_mobj(source, target)
      return
    end

    if CDoom.p_random < target.value.info.value.painchance &&
       target.value.flags & CDoom::Mobjflag::MF_SKULLFLY.value == 0
      target.value.flags = target.value.flags | CDoom::Mobjflag::MF_JUSTHIT.value # fight back!

      CDoom.p_set_mobj_state(target, CDoom::Statenum.new(target.value.info.value.painstate))
    end

    target.value.reactiontime = 0 # we're awake now...

    if (target.value.threshold == 0 || target.value.type == CDoom::Mobjtype::MT_VILE) &&
       !source.null? && source != target && source.value.type != CDoom::Mobjtype::MT_VILE
      # if not intent on another player,
      # chase after this one
      target.value.target = source
      target.value.threshold = CDoom::BASETHRESHOLD
      if target.value.state == CDoom.states + target.value.info.value.spawnstate &&
         target.value.info.value.seestate != CDoom::Statenum::S_NULL.value
        CDoom.p_set_mobj_state(target, CDoom::Statenum.new(target.value.info.value.seestate))
      end
    end
  end

  def self.t_fire_flicker(flick : CDoom::Fireflicker*)
    flick.value.count = flick.value.count - 1
    return if flick.value.count != 0

    amount = (CDoom.p_random & 3) * 16

    if flick.value.sector.value.lightlevel - amount < flick.value.minlight
      flick.value.sector.value.lightlevel = flick.value.minlight
    else
      flick.value.sector.value.lightlevel = flick.value.maxlight - amount
    end

    flick.value.count = 4
  end

  def self.p_spawn_fire_flicker(sector : CDoom::Sector*)
    # Note that we are resetting sector attributes.
    # Nothing special about it during gameplay.
    sector.value.special = 0

    flick = CDoom.z_malloc(sizeof(CDoom::Fireflicker), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Fireflicker*)

    CDoom.p_add_thinker(pointerof(flick.value.@thinker))

    pointerof(flick.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_fire_flicker).pointer, Pointer(Void).null)
    flick.value.sector = sector
    flick.value.maxlight = sector.value.lightlevel
    flick.value.minlight = CDoom.p_find_min_surrounding_light(sector, sector.value.lightlevel) + 16
    flick.value.count = 4
  end

  #
  # BROKEN LIGHT FLASHING
  #

  #
  # Do flashing lights.
  #
  def self.t_light_flash(flash : CDoom::Lightflash*)
    flash.value.count = flash.value.count - 1
    return if flash.value.count != 0

    if flash.value.sector.value.lightlevel == flash.value.maxlight
      flash.value.sector.value.lightlevel = flash.value.minlight
      flash.value.count = (CDoom.p_random & flash.value.mintime) + 1
    else
      flash.value.sector.value.lightlevel = flash.value.maxlight
      flash.value.count = (CDoom.p_random & flash.value.maxtime) + 1
    end
  end

  #
  # After the map has been loaded, scan each sector
  # for specials that spawn thinkers
  #
  def self.p_spawn_light_flash(sector : CDoom::Sector*)
    # Nothing special about it during gameplay.
    sector.value.special = 0

    flash = CDoom.z_malloc(sizeof(CDoom::Lightflash), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Lightflash*)

    CDoom.p_add_thinker(pointerof(flash.value.@thinker))

    pointerof(flash.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_light_flash).pointer, Pointer(Void).null)
    flash.value.sector = sector
    flash.value.maxlight = sector.value.lightlevel

    flash.value.minlight = CDoom.p_find_min_surrounding_light(sector, sector.value.lightlevel)
    flash.value.maxtime = 64
    flash.value.mintime = 7
    flash.value.count = (CDoom.p_random & flash.value.maxtime) + 1
  end

  #
  # STROBE LIGHT FLASHING
  #

  def self.t_strobe_flash(flash : CDoom::Strobe*)
    flash.value.count = flash.value.count - 1
    return if flash.value.count != 0

    if flash.value.sector.value.lightlevel == flash.value.minlight
      flash.value.sector.value.lightlevel = flash.value.maxlight
      flash.value.count = flash.value.brighttime
    else
      flash.value.sector.value.lightlevel = flash.value.minlight
      flash.value.count = flash.value.darktime
    end
  end

  #
  # After the map has been loaded, scan each sector
  # for specials that spawn thinkers
  #
  def self.p_spawn_strobe_flash(sector : CDoom::Sector*, fast_or_slow : LibC::Int, in_sync : LibC::Int)
    flash = CDoom.z_malloc(sizeof(CDoom::Strobe), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Strobe*)

    CDoom.p_add_thinker(pointerof(flash.value.@thinker))

    flash.value.sector = sector
    flash.value.darktime = fast_or_slow
    flash.value.brighttime = CDoom::STROBEBRIGHT
    pointerof(flash.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_strobe_flash).pointer, Pointer(Void).null)
    flash.value.maxlight = sector.value.lightlevel
    flash.value.minlight = CDoom.p_find_min_surrounding_light(sector, sector.value.lightlevel)

    flash.value.minlight = 0 if flash.value.minlight == flash.value.maxlight

    # nothing special about it during gameplay
    sector.value.special = 0

    if in_sync == 0
      flash.value.count = (CDoom.p_random & 7) + 1
    else
      flash.value.count = 1
    end
  end

  #
  # Start strobing lights (usually from a trigger)
  #
  def self.ev_start_light_strobing(line : CDoom::Line*)
    secnum = -1
    while (secnum = CDoom.p_find_sector_from_line_tag(line, secnum)) >= 0
      sec = CDoom.sectors + secnum
      next if !sec.value.specialdata.null?

      CDoom.p_spawn_strobe_flash(sec, CDoom::SLOWDARK, 0)
    end
  end

  #
  # TURN LINE'S TAG LIGHTS OFF
  #
  def self.ev_turn_tag_lights_off(line : CDoom::Line*)
    sector = CDoom.sectors

    CDoom.numsectors.times do |j|
      if sector.value.tag == line.value.tag
        min = sector.value.lightlevel
        sector.value.linecount.times do |i|
          templine = sector.value.lines[i]
          tsec = CDoom.get_next_sector(templine, sector)
          next if tsec.null?
          min = tsec.value.lightlevel if tsec.value.lightlevel < min
        end
        sector.value.lightlevel = min
      end
      sector += 1
    end
  end

  def self.ev_light_turn_on(line : CDoom::Line*, bright : LibC::Int)
    sector = CDoom.sectors

    CDoom.numsectors.times do |j|
      if sector.value.tag == line.value.tag
        # bright = 0 means to search
        # for highest light level
        # surrounding sector
        if bright == 0
          sector.value.linecount.times do |i|
            templine = sector.value.lines[i]
            temp = CDoom.get_next_sector(templine, sector)
            next if temp.null?
            bright = temp.value.lightlevel if temp.value.lightlevel > bright
          end
        end
        sector.value.lightlevel = bright
      end
      sector += 1
    end
  end

  def self.t_glow(g : CDoom::Glow*)
    case g.value.direction
    when -1
      # DOWN
      g.value.sector.value.lightlevel = g.value.sector.value.lightlevel - CDoom::GLOWSPEED
      if g.value.sector.value.lightlevel <= g.value.minlight
        g.value.sector.value.lightlevel = g.value.sector.value.lightlevel + CDoom::GLOWSPEED
        g.value.direction = 1
      end
    when 1
      # UP
      g.value.sector.value.lightlevel = g.value.sector.value.lightlevel + CDoom::GLOWSPEED
      if g.value.sector.value.lightlevel >= g.value.maxlight
        g.value.sector.value.lightlevel = g.value.sector.value.lightlevel - CDoom::GLOWSPEED
        g.value.direction = -1
      end
    end
  end

  def self.p_spawn_glowing_light(sector : CDoom::Sector*)
    g = CDoom.z_malloc(sizeof(CDoom::Glow), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Glow*)

    CDoom.p_add_thinker(pointerof(g.value.@thinker))

    g.value.sector = sector
    g.value.minlight = CDoom.p_find_min_surrounding_light(sector, sector.value.lightlevel)
    g.value.maxlight = sector.value.lightlevel
    pointerof(g.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_glow).pointer, Pointer(Void).null)
    g.value.direction = -1

    sector.value.special = 0
  end

  #
  # TELEPORT MOVE
  #

  def self.pit_stomp_thing(thing : CDoom::Mobj*) : CDoom::DoomBool
    return 1 if thing.value.flags & CDoom::Mobjflag::MF_SHOOTABLE.value == 0

    blockdist = thing.value.radius + CDoom.tmthing.value.radius

    if doom_abs(thing.value.x - CDoom.tmx) >= blockdist ||
       doom_abs(thing.value.y - CDoom.tmy) >= blockdist
      # didn't hit it
      return 1
    end

    # don't clip against self
    return 1 if thing == CDoom.tmthing

    # monsters don't stomp things except on boss level
    return 0 if CDoom.tmthing.value.player.null? && CDoom.gamemap != 30

    CDoom.p_damage_mobj(thing, CDoom.tmthing, CDoom.tmthing, 10000)

    return 1
  end

  def self.p_teleport_move(thing : CDoom::Mobj*, x : CDoom::Fixed, y : CDoom::Fixed) : CDoom::DoomBool
    # kill anything occupying the position
    CDoom.tmthing = thing
    CDoom.tmflags = thing.value.flags

    CDoom.tmx = x
    CDoom.tmy = y

    CDoom.tmbbox[CDoom::BOXTOP] = y + CDoom.tmthing.value.radius
    CDoom.tmbbox[CDoom::BOXBOTTOM] = y - CDoom.tmthing.value.radius
    CDoom.tmbbox[CDoom::BOXRIGHT] = x + CDoom.tmthing.value.radius
    CDoom.tmbbox[CDoom::BOXLEFT] = x - CDoom.tmthing.value.radius

    newsubsec = CDoom.r_point_in_subsector(x, y)
    CDoom.ceilingline = Pointer(CDoom::Line).null

    # The base floor/ceiling is from the subsector
    # that contains the point.
    # Any contacted lines the step closer together
    # will adjust them.
    CDoom.tmfloorz = newsubsec.value.sector.value.floorheight
    CDoom.tmdropoffz = CDoom.tmfloorz
    CDoom.tmceilingz = newsubsec.value.sector.value.ceilingheight

    CDoom.validcount += 1
    CDoom.numspechit = 0

    # stomp on anythings contacted
    xl = (CDoom.tmbbox[CDoom::BOXLEFT] - CDoom.bmaporgx - CDoom::MAXRADIUS) >> CDoom::MAPBLOCKSHIFT
    xh = (CDoom.tmbbox[CDoom::BOXRIGHT] - CDoom.bmaporgx + CDoom::MAXRADIUS) >> CDoom::MAPBLOCKSHIFT
    yl = (CDoom.tmbbox[CDoom::BOXBOTTOM] - CDoom.bmaporgy - CDoom::MAXRADIUS) >> CDoom::MAPBLOCKSHIFT
    yh = (CDoom.tmbbox[CDoom::BOXTOP] - CDoom.bmaporgy + CDoom::MAXRADIUS) >> CDoom::MAPBLOCKSHIFT

    bx = xl
    while bx <= xh
      by = yl
      while by <= yh
        return 0 if CDoom.p_block_things_iterator(bx, by, ->CDoom.pit_stomp_thing) == 0
        by += 1
      end
      bx += 1
    end

    # the move is ok,
    # so link the thing into its new position
    CDoom.p_unset_thing_position(thing)

    thing.value.floorz = CDoom.tmfloorz
    thing.value.ceilingz = CDoom.tmceilingz
    thing.value.x = x
    thing.value.y = y

    CDoom.p_set_thing_position(thing)

    return 1
  end

  #
  # MOVEMENT ITERATOR FUNCTIONS
  #

  #
  # Adjusts tmfloorz and tmceilingz as lines are contacted
  #
  def self.pit_check_line(ld : CDoom::Line*) : CDoom::DoomBool
    if CDoom.tmbbox[CDoom::BOXRIGHT] <= ld.value.bbox[CDoom::BOXLEFT] ||
       CDoom.tmbbox[CDoom::BOXLEFT] >= ld.value.bbox[CDoom::BOXRIGHT] ||
       CDoom.tmbbox[CDoom::BOXTOP] <= ld.value.bbox[CDoom::BOXBOTTOM] ||
       CDoom.tmbbox[CDoom::BOXBOTTOM] >= ld.value.bbox[CDoom::BOXTOP]
      return 1
    end

    return 1 if CDoom.p_box_on_line_side(CDoom.tmbbox, ld) != -1

    # A line has been hit

    # The moving thing's destination position will cross
    # the given line.
    # If this should not be allowed, return false.
    # If the line is special, keep track of it
    # to process later if the move is proven ok.
    # NOTE: specials are NOT sorted by order,
    # so two special lines that are only 8 pixels apart
    # could be crossed in either order.

    return 0 if ld.value.backsector.null? # one sided line

    if CDoom.tmthing.value.flags & CDoom::Mobjflag::MF_MISSILE.value == 0
      return 0 if ld.value.flags & CDoom::ML_BLOCKING != 0 # explicitly blocking everything

      return 0 if CDoom.tmthing.value.player.null? && ld.value.flags & CDoom::ML_BLOCKMONSTERS != 0 # block monsters only
    end

    # set openrange, opentop, openbottom
    CDoom.p_line_opening(ld)

    # adjust floor / ceiling heights
    if CDoom.opentop < CDoom.tmceilingz
      CDoom.tmceilingz = CDoom.opentop
      CDoom.ceilingline = ld
    end

    CDoom.tmfloorz = CDoom.openbottom if CDoom.openbottom > CDoom.tmfloorz

    CDoom.tmdropoffz = CDoom.lowfloor if CDoom.lowfloor < CDoom.tmdropoffz

    # if contacted a special line, add it to the list
    if ld.value.special != 0
      CDoom.spechit[CDoom.numspechit] = ld
      CDoom.numspechit += 1
    end

    return 1
  end

  def self.pit_check_thing(thing : CDoom::Mobj*) : CDoom::DoomBool
    return 1 if thing.value.flags & (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SPECIAL.value | CDoom::Mobjflag::MF_SHOOTABLE.value) == 0

    blockdist = thing.value.radius + CDoom.tmthing.value.radius

    if doom_abs(thing.value.x - CDoom.tmx) >= blockdist ||
       doom_abs(thing.value.y - CDoom.tmy) >= blockdist
      # didn't hit it
      return 1
    end

    # don't clip against self
    return 1 if thing == CDoom.tmthing

    # check for skulls slamming into things
    if CDoom.tmthing.value.flags & CDoom::Mobjflag::MF_SKULLFLY.value != 0
      damage = ((CDoom.p_random % 8) + 1) * CDoom.tmthing.value.info.value.damage

      CDoom.p_damage_mobj(thing, CDoom.tmthing, CDoom.tmthing, damage)

      CDoom.tmthing.value.flags = CDoom.tmthing.value.flags & ~CDoom::Mobjflag::MF_SKULLFLY.value
      CDoom.tmthing.value.momx = 0
      CDoom.tmthing.value.momy = 0
      CDoom.tmthing.value.momz = 0

      CDoom.p_set_mobj_state(CDoom.tmthing, CDoom::Statenum.new(CDoom.tmthing.value.info.value.spawnstate))

      return 0 # stop moving
    end

    # missiles can hit other things
    if CDoom.tmthing.value.flags & CDoom::Mobjflag::MF_MISSILE.value != 0
      # see if it went over / under
      return 1 if CDoom.tmthing.value.z > thing.value.z + thing.value.height         # overhead
      return 1 if CDoom.tmthing.value.z + CDoom.tmthing.value.height < thing.value.z # underneath

      if !CDoom.tmthing.value.target.null? && (
           CDoom.tmthing.value.target.value.type == thing.value.type ||
           (CDoom.tmthing.value.target.value.type == CDoom::Mobjtype::MT_KNIGHT && thing.value.type == CDoom::Mobjtype::MT_BRUISER) ||
           (CDoom.tmthing.value.target.value.type == CDoom::Mobjtype::MT_BRUISER && thing.value.type == CDoom::Mobjtype::MT_KNIGHT)
         )
        # Don't hit same species as originator.
        return 1 if thing == CDoom.tmthing.value.target

        if thing.value.type != CDoom::Mobjtype::MT_PLAYER && @@deh_species_infighting == 0
          # Explode, but do no damage.
          # Let players missile other players.
          return 0
        end
      end

      if thing.value.flags & CDoom::Mobjflag::MF_SHOOTABLE.value == 0
        # didn't do any damage
        return (thing.value.flags & CDoom::Mobjflag::MF_SOLID.value == 0).to_unsafe
      end

      # damage / explode
      damage = ((CDoom.p_random % 8) + 1) * CDoom.tmthing.value.info.value.damage
      CDoom.p_damage_mobj(thing, CDoom.tmthing, CDoom.tmthing.value.target, damage)

      # don't traverse any more
      return 0
    end

    # check for special pickup
    if thing.value.flags & CDoom::Mobjflag::MF_SPECIAL.value != 0
      solid = thing.value.flags & CDoom::Mobjflag::MF_SOLID.value != 0
      if CDoom.tmflags & CDoom::Mobjflag::MF_PICKUP.value != 0
        # can remove thing
        CDoom.p_touch_special_thing(thing, CDoom.tmthing)
      end
      return (!solid).to_unsafe
    end

    return (thing.value.flags & CDoom::Mobjflag::MF_SOLID.value == 0).to_unsafe
  end

  #
  # MOVEMENT CLIPPING
  #

  #
  # This is purely informative, nothing is modified
  # (except things picked up).
  #
  # in:
  #  a mobj_t (can be valid or invalid)
  #  a position to be checked
  #   (doesn't need to be related to the mobj_t->x,y)
  #
  # during:
  #  special things are touched if MF_PICKUP
  #  early out on solid lines?
  #
  # out:
  #  newsubsec
  #  floorz
  #  ceilingz
  #  tmdropoffz
  #   the lowest point contacted
  #   (monsters won't move to a dropoff)
  #  speciallines[]
  #  numspeciallines
  #
  def self.p_check_position(thing : CDoom::Mobj*, x : CDoom::Fixed, y : CDoom::Fixed) : CDoom::DoomBool
    CDoom.tmthing = thing
    CDoom.tmflags = thing.value.flags

    CDoom.tmx = x
    CDoom.tmy = y

    CDoom.tmbbox[CDoom::BOXTOP] = y &+ CDoom.tmthing.value.radius
    CDoom.tmbbox[CDoom::BOXBOTTOM] = y &- CDoom.tmthing.value.radius
    CDoom.tmbbox[CDoom::BOXRIGHT] = x &+ CDoom.tmthing.value.radius
    CDoom.tmbbox[CDoom::BOXLEFT] = x &- CDoom.tmthing.value.radius

    newsubsec = CDoom.r_point_in_subsector(x, y)
    CDoom.ceilingline = Pointer(CDoom::Line).null

    # The base floor/ceiling is from the subsector
    # that contains the point.
    # Any contacted lines the step closer together
    # will adjust them.
    CDoom.tmfloorz = newsubsec.value.sector.value.floorheight
    CDoom.tmdropoffz = CDoom.tmfloorz
    CDoom.tmceilingz = newsubsec.value.sector.value.ceilingheight

    CDoom.validcount += 1
    CDoom.numspechit = 0

    return 1 if CDoom.tmflags & CDoom::Mobjflag::MF_NOCLIP.value != 0

    # Check things first, possibly picking things up.
    # The bounding box is extended by MAXRADIUS
    # because mobj_ts are grouped into mapblocks
    # based on their origin point, and can overlap
    # into adjacent blocks by up to MAXRADIUS units.
    xl = (CDoom.tmbbox[CDoom::BOXLEFT] &- CDoom.bmaporgx &- CDoom::MAXRADIUS) >> CDoom::MAPBLOCKSHIFT
    xh = (CDoom.tmbbox[CDoom::BOXRIGHT] &- CDoom.bmaporgx &+ CDoom::MAXRADIUS) >> CDoom::MAPBLOCKSHIFT
    yl = (CDoom.tmbbox[CDoom::BOXBOTTOM] &- CDoom.bmaporgy &- CDoom::MAXRADIUS) >> CDoom::MAPBLOCKSHIFT
    yh = (CDoom.tmbbox[CDoom::BOXTOP] &- CDoom.bmaporgy &+ CDoom::MAXRADIUS) >> CDoom::MAPBLOCKSHIFT

    bx = xl
    while bx <= xh
      by = yl
      while by <= yh
        return 0 if CDoom.p_block_things_iterator(bx, by, ->CDoom.pit_check_thing) == 0
        by += 1
      end
      bx += 1
    end

    # check lines
    xl = (CDoom.tmbbox[CDoom::BOXLEFT] &- CDoom.bmaporgx) >> CDoom::MAPBLOCKSHIFT
    xh = (CDoom.tmbbox[CDoom::BOXRIGHT] &- CDoom.bmaporgx) >> CDoom::MAPBLOCKSHIFT
    yl = (CDoom.tmbbox[CDoom::BOXBOTTOM] &- CDoom.bmaporgy) >> CDoom::MAPBLOCKSHIFT
    yh = (CDoom.tmbbox[CDoom::BOXTOP] &- CDoom.bmaporgy) >> CDoom::MAPBLOCKSHIFT

    bx = xl
    while bx <= xh
      by = yl
      while by <= yh
        return 0 if CDoom.p_block_lines_iterator(bx, by, ->CDoom.pit_check_line) == 0
        by += 1
      end
      bx += 1
    end

    return 1
  end

  #
  # Attempt to move to a new position,
  # crossing special lines unless MF_TELEPORT is set.
  #
  def self.p_try_move(thing : CDoom::Mobj*, x : CDoom::Fixed, y : CDoom::Fixed) : CDoom::DoomBool
    CDoom.floatok = 0
    return 0 if CDoom.p_check_position(thing, x, y) == 0 # solid wall or thing

    if thing.value.flags & CDoom::Mobjflag::MF_NOCLIP.value == 0
      return 0 if CDoom.tmceilingz - CDoom.tmfloorz < thing.value.height # doesn't fit

      CDoom.floatok = 1

      if thing.value.flags & CDoom::Mobjflag::MF_TELEPORT.value == 0 &&
         CDoom.tmceilingz - thing.value.z < thing.value.height
        return 0 # mobj must lower itself to fit
      end

      if thing.value.flags & CDoom::Mobjflag::MF_TELEPORT.value == 0 &&
         CDoom.tmfloorz - thing.value.z > 24 * FRACUNIT
        return 0 # too big a step up
      end

      if thing.value.flags & (CDoom::Mobjflag::MF_DROPOFF.value | CDoom::Mobjflag::MF_FLOAT.value) == 0 &&
         CDoom.tmfloorz - CDoom.tmdropoffz > 24 * FRACUNIT
        return 0 # don't stand over a dropoff
      end
    end

    # the move is ok,
    # so link the thing into its new position
    CDoom.p_unset_thing_position(thing)

    oldx = thing.value.x
    oldy = thing.value.y
    thing.value.floorz = CDoom.tmfloorz
    thing.value.ceilingz = CDoom.tmceilingz
    thing.value.x = x
    thing.value.y = y

    CDoom.p_set_thing_position(thing)

    # if any special lines were hit, do the effect
    if thing.value.flags & (CDoom::Mobjflag::MF_TELEPORT.value | CDoom::Mobjflag::MF_NOCLIP.value) == 0
      while CDoom.numspechit != 0
        CDoom.numspechit -= 1
        # see if the line was crossed
        ld = CDoom.spechit[CDoom.numspechit]
        side = CDoom.p_point_on_line_side(thing.value.x, thing.value.y, ld)
        oldside = CDoom.p_point_on_line_side(oldx, oldy, ld)
        if side != oldside
          CDoom.p_cross_special_line((ld - CDoom.lines).to_i32!, oldside, thing) if ld.value.special != 0
        end
      end
    end

    return 1
  end

  def self.p_thing_height_clip(thing : CDoom::Mobj*) : CDoom::DoomBool
    onfloor = (thing.value.z == thing.value.floorz).to_unsafe

    CDoom.p_check_position(thing, thing.value.x, thing.value.y)
    # what about stranding a monster partially off an edge?

    thing.value.floorz = CDoom.tmfloorz
    thing.value.ceilingz = CDoom.tmceilingz

    if onfloor != 0
      # walking monsters rise and fall with the floor
      thing.value.z = thing.value.floorz
    else
      # don't adjust a floating monster unless forced to
      if thing.value.z + thing.value.height > thing.value.ceilingz
        thing.value.z = thing.value.ceilingz - thing.value.height
      end
    end

    return 0 if thing.value.ceilingz - thing.value.floorz < thing.value.height

    return 1
  end

  #
  # SLIDE MOVE
  # Allows the player to slide along any angled walls.
  #

  #
  # Adjusts the xmove / ymove
  # so that the next move will slide along the wall.
  #
  def self.p_hit_slide_line(ld : CDoom::Line*)
    if ld.value.slopetype == CDoom::Slopetype::HORIZONTAL
      CDoom.tmymove = 0
      return
    end

    if ld.value.slopetype == CDoom::Slopetype::VERTICAL
      CDoom.tmxmove = 0
      return
    end

    side = CDoom.p_point_on_line_side(CDoom.slidemo.value.x, CDoom.slidemo.value.y, ld)

    lineangle = CDoom.r_point_to_angle2(0, 0, ld.value.dx, ld.value.dy)

    lineangle &+= ANG180 if side == 1

    moveangle = CDoom.r_point_to_angle2(0, 0, CDoom.tmxmove, CDoom.tmymove)
    deltaangle = moveangle &- lineangle

    deltaangle &+= ANG180 if deltaangle > ANG180

    lineangle >>= CDoom::ANGLETOFINESHIFT
    deltaangle >>= CDoom::ANGLETOFINESHIFT

    movelen = CDoom.p_aprox_distance(CDoom.tmxmove, CDoom.tmymove)
    newlen = CDoom.fixed_mul(movelen, @@finecosine[deltaangle])

    CDoom.tmxmove = CDoom.fixed_mul(newlen, @@finecosine[lineangle])
    CDoom.tmymove = CDoom.fixed_mul(newlen, @@finesine[lineangle])
  end

  def self.ptr_slide_traverse(int : CDoom::Intercept*) : CDoom::DoomBool
    if int.value.isaline == 0
      CDoom.i_error("Error: ptr_slide-traverse: not a line?")
    end

    li = int.value.d.line

    isblocking = false

    if li.value.flags & CDoom::ML_TWOSIDED == 0
      if CDoom.p_point_on_line_side(CDoom.slidemo.value.x, CDoom.slidemo.value.y, li) != 0
        # don't hit the back side
        return 1
      end
      isblocking = true
    end

    unless isblocking
      # set openrange, opentop, openbottom
      CDoom.p_line_opening(li)

      if CDoom.openrange < CDoom.slidemo.value.height ||                       # doesn't fit
         CDoom.opentop - CDoom.slidemo.value.z < CDoom.slidemo.value.height || # mobj is too hight
         CDoom.openbottom - CDoom.slidemo.value.z > 24 * FRACUNIT              # too big a step up
        isblocking = true
      end

      # this line doesn't block movement
      return 1 unless isblocking
    end

    # the line does block movement,
    # see if it is closer than best so far
    if int.value.frac < CDoom.bestslidefrac
      CDoom.secondslidefrac = CDoom.bestslidefrac
      CDoom.secondslideline = CDoom.bestslideline
      CDoom.bestslidefrac = int.value.frac
      CDoom.bestslideline = li
    end

    return 0 # stop
  end

  #
  # The momx / momy move is bad, so try to slide
  # along a wall.
  # Find the first line hit, move flush to it,
  # and slide along it
  #
  # This is a kludgy mess.
  #
  def self.p_slide_move(mo : CDoom::Mobj*)
    CDoom.slidemo = mo
    hitcount = 0

    loop do
      hitcount += 1
      stairstep = hitcount == 3 ? true : false # don't loop forever

      unless stairstep
        # trace along the three leading corners
        if mo.value.momx > 0
          leadx = mo.value.x + mo.value.radius
          trailx = mo.value.x - mo.value.radius
        else
          leadx = mo.value.x - mo.value.radius
          trailx = mo.value.x + mo.value.radius
        end

        if mo.value.momy > 0
          leady = mo.value.y + mo.value.radius
          traily = mo.value.y - mo.value.radius
        else
          leady = mo.value.y - mo.value.radius
          traily = mo.value.y + mo.value.radius
        end

        CDoom.bestslidefrac = FRACUNIT + 1

        CDoom.p_path_traverse(leadx, leady, leadx + mo.value.momx, leady + mo.value.momy,
          CDoom::PT_ADDLINES, ->CDoom.ptr_slide_traverse)
        CDoom.p_path_traverse(trailx, leady, trailx + mo.value.momx, leady + mo.value.momy,
          CDoom::PT_ADDLINES, ->CDoom.ptr_slide_traverse)
        CDoom.p_path_traverse(leadx, traily, leadx + mo.value.momx, traily + mo.value.momy,
          CDoom::PT_ADDLINES, ->CDoom.ptr_slide_traverse)
      end

      # move up to the wall
      loop do
        if stairstep || CDoom.bestslidefrac == FRACUNIT + 1
          # the move most have hit the middle, so stairstep
          if CDoom.p_try_move(mo, mo.value.x, mo.value.y + mo.value.momy) == 0
            CDoom.p_try_move(mo, mo.value.x + mo.value.momx, mo.value.y)
          end
          return
        end

        # fudge a bit to make sure it doesn't hit
        CDoom.bestslidefrac -= 0x800
        if CDoom.bestslidefrac > 0
          newx = CDoom.fixed_mul(mo.value.momx, CDoom.bestslidefrac)
          newy = CDoom.fixed_mul(mo.value.momy, CDoom.bestslidefrac)

          if CDoom.p_try_move(mo, mo.value.x + newx, mo.value.y + newy) == 0
            stairstep = true
            next
          end
        end
        break
      end

      # Now continue along the wall.
      # First calculate remainder.
      CDoom.bestslidefrac = FRACUNIT - (CDoom.bestslidefrac + 0x800)

      CDoom.bestslidefrac = FRACUNIT if CDoom.bestslidefrac > FRACUNIT
      return if CDoom.bestslidefrac <= 0

      CDoom.tmxmove = CDoom.fixed_mul(mo.value.momx, CDoom.bestslidefrac)
      CDoom.tmymove = CDoom.fixed_mul(mo.value.momy, CDoom.bestslidefrac)

      CDoom.p_hit_slide_line(CDoom.bestslideline) # clip the moves

      mo.value.momx = CDoom.tmxmove
      mo.value.momy = CDoom.tmymove

      next if CDoom.p_try_move(mo, mo.value.x + CDoom.tmxmove, mo.value.y + CDoom.tmymove) == 0

      break
    end
  end

  #
  # Sets linetaget and aimslope when a target is aimed at.
  #
  def self.ptr_aim_traverse(int : CDoom::Intercept*) : CDoom::DoomBool
    if int.value.isaline != 0
      li = int.value.d.line

      return 0 if li.value.flags & CDoom::ML_TWOSIDED == 0 # stop

      # Crosses a two sided line.
      # A two sided line will restrict
      # the possible target ranges.
      CDoom.p_line_opening(li)

      return 0 if CDoom.openbottom >= CDoom.opentop # stop

      dist = CDoom.fixed_mul(CDoom.attackrange, int.value.frac)

      if li.value.frontsector.value.floorheight != li.value.backsector.value.floorheight
        slope = CDoom.fixed_div(CDoom.openbottom - CDoom.shootz, dist)
        CDoom.bottomslope = slope if slope > CDoom.bottomslope
      end

      if li.value.frontsector.value.ceilingheight != li.value.backsector.value.ceilingheight
        slope = CDoom.fixed_div(CDoom.opentop - CDoom.shootz, dist)
        CDoom.topslope = slope if slope < CDoom.topslope
      end

      return 0 if CDoom.topslope <= CDoom.bottomslope # stop

      return 1 # shot continues
    end

    # shoot a thing
    th = int.value.d.thing
    return 1 if th == CDoom.shootthing # can't shoot self

    return 1 if th.value.flags & CDoom::Mobjflag::MF_SHOOTABLE.value == 0 # corpse or something

    # check angles to see if the thing can be aimed at
    dist = CDoom.fixed_mul(CDoom.attackrange, int.value.frac)
    thingtopslope = CDoom.fixed_div(th.value.z + th.value.height - CDoom.shootz, dist)

    return 1 if thingtopslope < CDoom.bottomslope # shot over the thing

    thingbottomslope = CDoom.fixed_div(th.value.z - CDoom.shootz, dist)

    return 1 if thingbottomslope > CDoom.topslope # shot under the thing

    # this thing can be hit!
    thingtopslope = CDoom.topslope if thingtopslope > CDoom.topslope
    thingbottomslope = CDoom.bottomslope if thingbottomslope < CDoom.bottomslope

    CDoom.aimslope = (thingtopslope + thingbottomslope).tdiv(2)
    CDoom.linetarget = th

    return 0 # don't go any farther
  end

  def self.ptr_shoot_traverse(int : CDoom::Intercept*) : CDoom::DoomBool
    if int.value.isaline != 0
      li = int.value.d.line

      CDoom.p_shoot_special_line(CDoom.shootthing, li) if li.value.special != 0

      hitline = li.value.flags & CDoom::ML_TWOSIDED == 0 ? true : false

      unless hitline
        # crosses a two sided line
        CDoom.p_line_opening(li)

        dist = CDoom.fixed_mul(CDoom.attackrange, int.value.frac)

        if li.value.frontsector.value.floorheight != li.value.backsector.value.floorheight
          slope = CDoom.fixed_div(CDoom.openbottom - CDoom.shootz, dist)
          hitline = slope > CDoom.aimslope
        end

        if !hitline && li.value.frontsector.value.ceilingheight != li.value.backsector.value.ceilingheight
          slope = CDoom.fixed_div(CDoom.opentop - CDoom.shootz, dist)
          hitline = slope < CDoom.aimslope
        end

        return 1 unless hitline # shot continues
      end

      # hit line
      # position a bit closer
      frac = int.value.frac - CDoom.fixed_div(4 * FRACUNIT, CDoom.attackrange)
      x = CDoom.trace.x + CDoom.fixed_mul(CDoom.trace.dx, frac)
      y = CDoom.trace.y + CDoom.fixed_mul(CDoom.trace.dy, frac)
      z = CDoom.shootz + CDoom.fixed_mul(CDoom.aimslope, CDoom.fixed_mul(frac, CDoom.attackrange))

      if li.value.frontsector.value.ceilingpic == CDoom.skyflatnum
        # don't shoot the sky!
        return 0 if z > li.value.frontsector.value.ceilingheight

        # it's a sky hack wall
        return 0 if !li.value.backsector.null? && li.value.backsector.value.ceilingpic == CDoom.skyflatnum
      end

      # Spawn bullet puffs.
      CDoom.p_spawn_puff(x, y, z)

      # don't go any farther
      return 0
    end

    # shoot a thing
    th = int.value.d.thing
    return 1 if th == CDoom.shootthing # can't shoot self

    return 1 if th.value.flags & CDoom::Mobjflag::MF_SHOOTABLE.value == 0 # corpse or something

    # check angles to see if the thing can be aimed at
    dist = CDoom.fixed_mul(CDoom.attackrange, int.value.frac)
    thingtopslope = CDoom.fixed_div(th.value.z + th.value.height - CDoom.shootz, dist)

    return 1 if thingtopslope < CDoom.aimslope # shot over the thing

    thingbottomslope = CDoom.fixed_div(th.value.z - CDoom.shootz, dist)

    return 1 if thingbottomslope > CDoom.aimslope # shot under the thing

    # hit thing
    # position a bit closer
    frac = int.value.frac - CDoom.fixed_div(10 * FRACUNIT, CDoom.attackrange)

    x = CDoom.trace.x + CDoom.fixed_mul(CDoom.trace.dx, frac)
    y = CDoom.trace.y + CDoom.fixed_mul(CDoom.trace.dy, frac)
    z = CDoom.shootz + CDoom.fixed_mul(CDoom.aimslope, CDoom.fixed_mul(frac, CDoom.attackrange))

    # Spawn bullet puffs or blod spots,
    # depending on target type.
    if int.value.d.thing.value.flags & CDoom::Mobjflag::MF_NOBLOOD.value != 0
      CDoom.p_spawn_puff(x, y, z)
    else
      CDoom.p_spawn_blood(x, y, z, CDoom.la_damage)
    end

    CDoom.p_damage_mobj(th, CDoom.shootthing, CDoom.shootthing, CDoom.la_damage) if CDoom.la_damage != 0

    # don't go any farther
    return 0
  end

  def self.p_aim_line_attack(t1 : CDoom::Mobj*, angle : CDoom::Angle, distance : CDoom::Fixed) : CDoom::Fixed
    angle >>= CDoom::ANGLETOFINESHIFT
    CDoom.shootthing = t1

    x2 = t1.value.x + (distance >> FRACBITS) * @@finecosine[angle]
    y2 = t1.value.y + (distance >> FRACBITS) * @@finesine[angle]
    CDoom.shootz = t1.value.z + (t1.value.height >> 1) + 8 * FRACUNIT

    # can't shoot outside view angles
    CDoom.topslope = 100 * FRACUNIT // 160
    CDoom.bottomslope = -100 * FRACUNIT // 160

    CDoom.attackrange = distance
    CDoom.linetarget = Pointer(CDoom::Mobj).null

    CDoom.p_path_traverse(t1.value.x, t1.value.y,
      x2, y2,
      CDoom::PT_ADDLINES | CDoom::PT_ADDTHINGS,
      ->CDoom.ptr_aim_traverse)

    return CDoom.aimslope unless CDoom.linetarget.null?

    return 0
  end

  #
  # If damage == 0, it is just a test trace
  # that will leave linetarget set.
  #
  def self.p_line_attack(t1 : CDoom::Mobj*, angle : CDoom::Angle, distance : CDoom::Fixed, slope : CDoom::Fixed, damage : LibC::Int)
    angle >>= CDoom::ANGLETOFINESHIFT
    CDoom.shootthing = t1
    CDoom.la_damage = damage
    x2 = t1.value.x + (distance >> FRACBITS) * @@finecosine[angle]
    y2 = t1.value.y + (distance >> FRACBITS) * @@finesine[angle]
    CDoom.shootz = t1.value.z + (t1.value.height >> 1) + 8 * FRACUNIT
    CDoom.attackrange = distance
    CDoom.aimslope = slope

    CDoom.p_path_traverse(t1.value.x, t1.value.y,
      x2, y2,
      CDoom::PT_ADDLINES | CDoom::PT_ADDTHINGS,
      ->CDoom.ptr_shoot_traverse)
  end

  def self.ptr_use_traverse(int : CDoom::Intercept*) : CDoom::DoomBool
    if int.value.d.line.value.special == 0
      CDoom.p_line_opening(int.value.d.line)
      if CDoom.openrange <= 0
        CDoom.s_start_sound(CDoom.usething, CDoom::Sfxenum::SFX_noway.value)

        # can't use through a wall
        return 0
      end
      # not a special line, but keep checking
      return 1
    end

    side = 0
    side = 1 if CDoom.p_point_on_line_side(CDoom.usething.value.x, CDoom.usething.value.y, int.value.d.line) == 1

    CDoom.p_use_special_line(CDoom.usething, int.value.d.line, side)

    # can't use for than one special line in a row
    return 0
  end

  #
  # Looks for special lines in front of the player to activate.
  #
  def self.p_use_lines(player : CDoom::Player*)
    CDoom.usething = player.value.mo

    angle = player.value.mo.value.angle >> CDoom::ANGLETOFINESHIFT

    x1 = player.value.mo.value.x
    y1 = player.value.mo.value.y
    x2 = x1 + (CDoom::USERANGE >> FRACBITS) * @@finecosine[angle]
    y2 = y1 + (CDoom::USERANGE >> FRACBITS) * @@finesine[angle]

    CDoom.p_path_traverse(x1, y1, x2, y2, CDoom::PT_ADDLINES, ->CDoom.ptr_use_traverse)
  end

  #
  # RADIUS ATTACK
  #

  #
  # "bombsource" is the creature
  # that caused the explosion at "bombspot".
  #
  def self.pit_radius_attack(thing : CDoom::Mobj*) : CDoom::DoomBool
    return 1 if thing.value.flags & CDoom::Mobjflag::MF_SHOOTABLE.value == 0

    # Boss spider and cyborg
    # take no damage from concussion.
    return 1 if thing.value.type == CDoom::Mobjtype::MT_CYBORG ||
                thing.value.type == CDoom::Mobjtype::MT_SPIDER

    dx = doom_abs(thing.value.x - CDoom.bombspot.value.x)
    dy = doom_abs(thing.value.y - CDoom.bombspot.value.y)

    dist = dx > dy ? dx : dy
    dist = (dist - thing.value.radius) >> FRACBITS

    dist = 0 if dist < 0

    return 1 if dist >= CDoom.bombdamage # out of range

    if CDoom.p_check_sight(thing, CDoom.bombspot) != 0
      # must be in direct path
      CDoom.p_damage_mobj(thing, CDoom.bombspot, CDoom.bombsource, CDoom.bombdamage - dist)
    end

    return 1
  end

  #
  # Source is the creature that caused the explosion at spot.
  #
  def self.p_radius_attack(spot : CDoom::Mobj*, source : CDoom::Mobj*, damage : LibC::Int)
    dist = (damage + CDoom::MAXRADIUS) << FRACBITS
    yh = (spot.value.y + dist - CDoom.bmaporgy) >> CDoom::MAPBLOCKSHIFT
    yl = (spot.value.y - dist - CDoom.bmaporgy) >> CDoom::MAPBLOCKSHIFT
    xh = (spot.value.x + dist - CDoom.bmaporgx) >> CDoom::MAPBLOCKSHIFT
    xl = (spot.value.x - dist - CDoom.bmaporgx) >> CDoom::MAPBLOCKSHIFT
    CDoom.bombspot = spot
    CDoom.bombsource = source
    CDoom.bombdamage = damage

    y = yl
    while y <= yh
      x = xl
      while x <= xh
        CDoom.p_block_things_iterator(x, y, ->CDoom.pit_radius_attack)
        x += 1
      end
      y += 1
    end
  end

  def self.pit_change_sector(thing : CDoom::Mobj*) : CDoom::DoomBool
    return 1 if CDoom.p_thing_height_clip(thing) != 0 # keep checking

    # crunch bodies to giblets
    if thing.value.health <= 0
      CDoom.p_set_mobj_state(thing, CDoom::Statenum::S_GIBS)

      thing.value.flags = thing.value.flags & ~CDoom::Mobjflag::MF_SOLID.value
      thing.value.height = 0
      thing.value.radius = 0

      # keep checking
      return 1
    end

    # crunch dropped items
    if thing.value.flags & CDoom::Mobjflag::MF_DROPPED.value != 0
      CDoom.p_remove_mobj(thing)

      # keep checking
      return 1
    end

    if thing.value.flags & CDoom::Mobjflag::MF_SHOOTABLE.value == 0
      # assume it is bloody gibs or something
      return 1
    end

    CDoom.nofit = 1

    if CDoom.crushchange && CDoom.leveltime & 3 == 0
      CDoom.p_damage_mobj(thing, Pointer(CDoom::Mobj).null, Pointer(CDoom::Mobj).null, 10)

      # spray blood in a random direction
      mo = CDoom.p_spawn_mobj(thing.value.x,
        thing.value.y,
        thing.value.z + thing.value.height.tdiv(2), CDoom::Mobjtype::MT_BLOOD)

      mo.value.momx = (CDoom.p_random - CDoom.p_random) << 12
      mo.value.momy = (CDoom.p_random - CDoom.p_random) << 12
    end

    # keep checking (crush other things)
    return 1
  end

  def self.p_change_sector(sector : CDoom::Sector*, crunch : CDoom::DoomBool) : CDoom::DoomBool
    CDoom.nofit = 0
    CDoom.crushchange = crunch

    # re-check heights for all things near the moving sector
    x = sector.value.blockbox[CDoom::BOXLEFT]
    while x <= sector.value.blockbox[CDoom::BOXRIGHT]
      y = sector.value.blockbox[CDoom::BOXBOTTOM]
      while y <= sector.value.blockbox[CDoom::BOXTOP]
        CDoom.p_block_things_iterator(x, y, ->CDoom.pit_change_sector)
        y += 1
      end

      x += 1
    end

    return CDoom.nofit
  end

  #
  # Gives an estimation of distance (not exact)
  #
  def self.p_aprox_distance(dx : CDoom::Fixed, dy : CDoom::Fixed) : CDoom::Fixed
    dx = doom_abs(dx)
    dy = doom_abs(dy)
    return dx + dy - (dx >> 1) if dx < dy
    return dx + dy - (dy >> 1)
  end

  #
  # Returns 0 or 1
  #
  def self.p_point_on_line_side(x : CDoom::Fixed, y : CDoom::Fixed, line : CDoom::Line*) : LibC::Int
    if line.value.dx == 0
      return (line.value.dy > 0).to_unsafe if x <= line.value.v1.value.x

      return (line.value.dy < 0).to_unsafe
    end
    if line.value.dy == 0
      return (line.value.dx < 0).to_unsafe if y <= line.value.v1.value.y

      return (line.value.dx > 0).to_unsafe
    end

    dx = (x - line.value.v1.value.x)
    dy = (y - line.value.v1.value.y)

    left = CDoom.fixed_mul(line.value.dy >> FRACBITS, dx)
    right = CDoom.fixed_mul(dy, line.value.dx >> FRACBITS)

    return 0 if right < left # front side
    return 1                 # back side
  end

  #
  # Considers the line to be infinite
  # Returns side 0 or 1, -1 if box crosses the line.
  #
  def self.p_box_on_line_side(tmbox : CDoom::Fixed*, ld : CDoom::Line*) : LibC::Int
    p1 = 0
    p2 = 0

    case ld.value.slopetype
    when CDoom::Slopetype::HORIZONTAL
      p1 = (tmbox[CDoom::BOXTOP] > ld.value.v1.value.y).to_unsafe
      p2 = (tmbox[CDoom::BOXBOTTOM] > ld.value.v1.value.y).to_unsafe
      if ld.value.dx < 0
        p1 ^= 1
        p2 ^= 1
      end
    when CDoom::Slopetype::VERTICAL
      p1 = (tmbox[CDoom::BOXRIGHT] < ld.value.v1.value.x).to_unsafe
      p2 = (tmbox[CDoom::BOXLEFT] < ld.value.v1.value.x).to_unsafe
      if ld.value.dy < 0
        p1 ^= 1
        p2 ^= 1
      end
    when CDoom::Slopetype::POSITIVE
      p1 = CDoom.p_point_on_line_side(tmbox[CDoom::BOXLEFT], tmbox[CDoom::BOXTOP], ld)
      p2 = CDoom.p_point_on_line_side(tmbox[CDoom::BOXRIGHT], tmbox[CDoom::BOXBOTTOM], ld)
    when CDoom::Slopetype::NEGATIVE
      p1 = CDoom.p_point_on_line_side(tmbox[CDoom::BOXRIGHT], tmbox[CDoom::BOXTOP], ld)
      p2 = CDoom.p_point_on_line_side(tmbox[CDoom::BOXLEFT], tmbox[CDoom::BOXBOTTOM], ld)
    end

    return p1 if p1 == p2
    return -1
  end

  def self.p_point_on_divline_side(x : CDoom::Fixed, y : CDoom::Fixed, line : CDoom::Divline*) : LibC::Int
    if line.value.dx == 0
      return (line.value.dy > 0).to_unsafe if x <= line.value.x

      return (line.value.dy < 0).to_unsafe
    end
    if line.value.dy == 0
      return (line.value.dx < 0).to_unsafe if y <= line.value.y

      return (line.value.dx > 0).to_unsafe
    end

    dx = (x - line.value.x)
    dy = (y - line.value.y)

    # try to quickly decide by looking at sign bits
    if (line.value.dy ^ line.value.dx ^ dx ^ dy) & 0x80000000 != 0
      return 1 if (line.value.dy ^ dx) & 0x80000000 != 0 # (left is negative)
      return 0
    end

    left = CDoom.fixed_mul(line.value.dy >> 8, dx >> 8)
    right = CDoom.fixed_mul(dy >> 8, line.value.dx >> 8)

    return 0 if right < left # front side
    return 1                 # back side
  end

  def self.p_make_divline(li : CDoom::Line*, dl : CDoom::Divline*)
    dl.value.x = li.value.v1.value.x
    dl.value.y = li.value.v1.value.y
    dl.value.dx = li.value.dx
    dl.value.dy = li.value.dy
  end

  #
  # Returns the fractional intercept point
  # along the first divline.
  # This is only called by the addthings
  # and addlines traversers.
  #
  def self.p_intercept_vector(v2 : CDoom::Divline*, v1 : CDoom::Divline*) : CDoom::Fixed
    den = CDoom.fixed_mul(v1.value.dy >> 8, v2.value.dx) &- CDoom.fixed_mul(v1.value.dx >> 8, v2.value.dy)

    return 0 if den == 0

    num =
      CDoom.fixed_mul((v1.value.x &- v2.value.x) >> 8, v1.value.dy) &+
        CDoom.fixed_mul((v2.value.y &- v1.value.y) >> 8, v1.value.dx)
    frac = CDoom.fixed_div(num, den)

    return frac
  end

  #
  # Sets opentop and openbottom to the window
  # through a two sided line.
  # OPTIMIZE: keep this precalculated
  #
  def self.p_line_opening(linedef : CDoom::Line*)
    if linedef.value.sidenum[1] == -1
      # single sided line
      CDoom.openrange = 0
      return
    end

    front = linedef.value.frontsector
    back = linedef.value.backsector

    if front.value.ceilingheight < back.value.ceilingheight
      CDoom.opentop = front.value.ceilingheight
    else
      CDoom.opentop = back.value.ceilingheight
    end

    if front.value.floorheight > back.value.floorheight
      CDoom.openbottom = front.value.floorheight
      CDoom.lowfloor = back.value.floorheight
    else
      CDoom.openbottom = back.value.floorheight
      CDoom.lowfloor = front.value.floorheight
    end

    CDoom.openrange = CDoom.opentop - CDoom.openbottom
  end

  #
  # THING POSITION SETTING
  #

  #
  # Unlinks a thing from block map and sectors.
  # On each position change, BLOCKMAP and other
  # lookups maintaining lists ot things inside
  # these structures need to be updated.
  #
  def self.p_unset_thing_position(thing : CDoom::Mobj*)
    if thing.value.flags & CDoom::Mobjflag::MF_NOSECTOR.value == 0
      # inert things don't need to be in blockmap?
      # unlink from subsector
      thing.value.snext.value.sprev = thing.value.sprev unless thing.value.snext.null?

      if !thing.value.sprev.null?
        thing.value.sprev.value.snext = thing.value.snext
      else
        thing.value.subsector.value.sector.value.thinglist = thing.value.snext
      end
    end

    if thing.value.flags & CDoom::Mobjflag::MF_NOBLOCKMAP.value == 0
      # inert things don't need to be in blockmap
      # unlink from block map
      thing.value.bnext.value.bprev = thing.value.bprev unless thing.value.bnext.null?

      if !thing.value.bprev.null?
        thing.value.bprev.value.bnext = thing.value.bnext
      else
        blockx = (thing.value.x - CDoom.bmaporgx) >> CDoom::MAPBLOCKSHIFT
        blocky = (thing.value.y - CDoom.bmaporgy) >> CDoom::MAPBLOCKSHIFT

        if blockx >= 0 && blockx < CDoom.bmapwidth &&
           blocky >= 0 && blocky < CDoom.bmapheight
          CDoom.blocklinks[blocky * CDoom.bmapwidth + blockx] = thing.value.bnext
        end
      end
    end
  end

  def self.p_set_thing_position(thing : CDoom::Mobj*)
    # link into subsector
    ss = CDoom.r_point_in_subsector(thing.value.x, thing.value.y)
    thing.value.subsector = ss

    if thing.value.flags & CDoom::Mobjflag::MF_NOSECTOR.value == 0
      # invisible things don't go into the sector links
      sec = ss.value.sector

      thing.value.sprev = Pointer(CDoom::Mobj).null
      thing.value.snext = sec.value.thinglist

      sec.value.thinglist.value.sprev = thing unless sec.value.thinglist.null?

      sec.value.thinglist = thing
    end

    # link into blockmap
    if thing.value.flags & CDoom::Mobjflag::MF_NOBLOCKMAP.value == 0
      # inert things don't need to be in blockmap
      blockx = (thing.value.x - CDoom.bmaporgx) >> CDoom::MAPBLOCKSHIFT
      blocky = (thing.value.y - CDoom.bmaporgy) >> CDoom::MAPBLOCKSHIFT

      if blockx >= 0 && blockx < CDoom.bmapwidth &&
         blocky >= 0 && blocky < CDoom.bmapheight
        link = CDoom.blocklinks + (blocky * CDoom.bmapwidth + blockx)
        thing.value.bprev = Pointer(CDoom::Mobj).null
        thing.value.bnext = link.value
        link.value.value.bprev = thing unless link.value.null?

        link.value = thing
      else
        # thing is off the map
        thing.value.bnext = Pointer(CDoom::Mobj).null
        thing.value.bprev = Pointer(CDoom::Mobj).null
      end
    end
  end

  #
  # BLOCK MAP ITERATORS
  # For each line/thing in the given mapblock,
  # call the passed PIT_* function.
  # If the function returns false,
  # exit with false without checking anything else.
  #

  #
  # The validcount flags are used to avoid checking lines
  # that are marked in multiple mapblocks,
  # so increment validcount before the first call
  # to P_BlockLinesIterator, then make one or more calls
  # to it.
  #
  def self.p_block_lines_iterator(x : LibC::Int, y : LibC::Int, func : Proc(CDoom::Line*, CDoom::DoomBool)) : CDoom::DoomBool
    return 1 if x < 0 || y < 0 || x >= CDoom.bmapwidth || y >= CDoom.bmapheight

    offset = y * CDoom.bmapwidth + x

    offset = (CDoom.blockmap + offset).value

    list = CDoom.blockmaplump + offset
    while list.value != -1
      ld = CDoom.lines + list.value

      if ld.value.validcount == CDoom.validcount
        list += 1
        next # line has already been checked
      end

      ld.value.validcount = CDoom.validcount

      return 0 if func.call(ld) == 0

      list += 1
    end

    return 1 # everything was checked
  end

  def self.p_block_things_iterator(x : LibC::Int, y : LibC::Int, func : Proc(CDoom::Mobj*, CDoom::DoomBool)) : CDoom::DoomBool
    return 1 if x < 0 || y < 0 || x >= CDoom.bmapwidth || y >= CDoom.bmapheight

    mobj = CDoom.blocklinks[y * CDoom.bmapwidth + x]
    while !mobj.null?
      return 0 if func.call(mobj) == 0

      mobj = mobj.value.bnext
    end

    return 1
  end

  #
  # INTERCEPT ROUTINES
  #

  #
  # Looks for lines in the given block
  # that intercept the given trace
  # to add to the intercepts list.
  #
  # A line is crossed if its endpoints
  # are on opposite sides of the trace.
  # Returns true if earlyout and a solid line hit.
  #
  def self.pit_add_line_intercepts(ld : CDoom::Line*) : CDoom::DoomBool
    s1 = 0
    s2 = 0
    dl = CDoom::Divline.new
    # avoid precision problems with two routines
    if CDoom.trace.dx > FRACUNIT * 16 ||
       CDoom.trace.dy > FRACUNIT * 16 ||
       CDoom.trace.dx < -FRACUNIT * 16 ||
       CDoom.trace.dy < -FRACUNIT * 16
      s1 = CDoom.p_point_on_divline_side(ld.value.v1.value.x, ld.value.v1.value.y, pointerof(CDoom.trace))
      s2 = CDoom.p_point_on_divline_side(ld.value.v2.value.x, ld.value.v2.value.y, pointerof(CDoom.trace))
    else
      s1 = CDoom.p_point_on_line_side(CDoom.trace.x, CDoom.trace.y, ld)
      s2 = CDoom.p_point_on_line_side(CDoom.trace.x + CDoom.trace.dx, CDoom.trace.y + CDoom.trace.dy, ld)
    end

    return 1 if s1 == s2 # line isn't crossed

    # hit the line
    CDoom.p_make_divline(ld, pointerof(dl))
    frac = CDoom.p_intercept_vector(pointerof(CDoom.trace), pointerof(dl))

    return 1 if frac < 0 # behind source

    # try to early out the check
    if CDoom.earlyout != 0 &&
       frac < FRACUNIT &&
       ld.value.backsector.null?
      return 0 # stop checking
    end

    CDoom.intercept_p.value.frac = frac
    CDoom.intercept_p.value.isaline = 1
    CDoom.intercept_p.value.d.line = ld

    CDoom.intercept_p += 1

    return 1 # continue
  end

  def self.pit_add_thing_intercepts(thing : CDoom::Mobj*) : CDoom::DoomBool
    tracepositive = ((CDoom.trace.dx ^ CDoom.trace.dy) > 0).to_unsafe

    # check a corner to corner crossection for hit
    if tracepositive != 0
      x1 = thing.value.x - thing.value.radius
      y1 = thing.value.y + thing.value.radius

      x2 = thing.value.x + thing.value.radius
      y2 = thing.value.y - thing.value.radius
    else
      x1 = thing.value.x - thing.value.radius
      y1 = thing.value.y - thing.value.radius

      x2 = thing.value.x + thing.value.radius
      y2 = thing.value.y + thing.value.radius
    end

    s1 = CDoom.p_point_on_divline_side(x1, y1, pointerof(CDoom.trace))
    s2 = CDoom.p_point_on_divline_side(x2, y2, pointerof(CDoom.trace))

    return 1 if s1 == s2 # line isn't crossed

    dl = CDoom::Divline.new(
      x: x1,
      y: y1,
      dx: x2 - x1,
      dy: y2 - y1
    )

    frac = CDoom.p_intercept_vector(pointerof(CDoom.trace), pointerof(dl))

    return 1 if frac < 0 # behind source

    CDoom.intercept_p.value.frac = frac
    CDoom.intercept_p.value.isaline = 0
    CDoom.intercept_p.value.d.thing = thing

    CDoom.intercept_p += 1

    return 1 # keep going
  end

  #
  # Returns true if the traverser function returns true
  # for all lines.
  #
  def self.p_traverse_intercepts(func : CDoom::Traverser, maxfrac : CDoom::Fixed) : CDoom::DoomBool
    count = (CDoom.intercept_p - CDoom.intercepts.to_unsafe).to_i32!

    int = Pointer(CDoom::Intercept).null # shut up compiler warning

    while count != 0
      count -= 1
      dist = Int32::MAX
      scan = CDoom.intercepts.to_unsafe
      while scan < CDoom.intercept_p
        if scan.value.frac < dist
          dist = scan.value.frac
          int = scan
        end
        scan += 1
      end

      return 1 if dist > maxfrac # checked everything in range

      # Unused block here in original source. I'm not porting #if 0 sections

      return 0 if func.call(int) == 0 # don't bother going farther

      int.value.frac = Int32::MAX
    end

    return 1 # everything was traversed
  end

  #
  # Traces a line from x1,y1 to x2,y2,
  # calling the traverser function for each.
  # Returns true if the traverser function returns true
  # for all lines.
  #
  def self.p_path_traverse(x1 : CDoom::Fixed, y1 : CDoom::Fixed, x2 : CDoom::Fixed, y2 : CDoom::Fixed, flags : LibC::Int, trav : Proc(CDoom::Intercept*, CDoom::DoomBool)) : CDoom::DoomBool
    CDoom.earlyout = flags & CDoom::PT_EARLYOUT != 0

    CDoom.validcount += 1
    CDoom.intercept_p = CDoom.intercepts.to_unsafe

    x1 += FRACUNIT if (x1 - CDoom.bmaporgx) & (CDoom::MAPBLOCKSIZE - 1) == 0 # don't side exactly on a line

    y1 += FRACUNIT if (y1 - CDoom.bmaporgy) & (CDoom::MAPBLOCKSIZE - 1) == 0 # don't side exactly on a line

    CDoom.trace.x = x1
    CDoom.trace.y = y1
    CDoom.trace.dx = x2 - x1
    CDoom.trace.dy = y2 - y1

    x1 -= CDoom.bmaporgx
    y1 -= CDoom.bmaporgy
    xt1 = x1 >> CDoom::MAPBLOCKSHIFT
    yt1 = y1 >> CDoom::MAPBLOCKSHIFT

    x2 -= CDoom.bmaporgx
    y2 -= CDoom.bmaporgy
    xt2 = x2 >> CDoom::MAPBLOCKSHIFT
    yt2 = y2 >> CDoom::MAPBLOCKSHIFT

    if xt2 > xt1
      mapxstep = 1
      partial = FRACUNIT - ((x1 >> CDoom::MAPBTOFRAC) & (FRACUNIT - 1))
      ystep = CDoom.fixed_div(y2 - y1, doom_abs(x2 - x1))
    elsif xt2 < xt1
      mapxstep = -1
      partial = (x1 >> CDoom::MAPBTOFRAC) & (FRACUNIT - 1)
      ystep = CDoom.fixed_div(y2 - y1, doom_abs(x2 - x1))
    else
      mapxstep = 0
      partial = FRACUNIT
      ystep = 256 * FRACUNIT
    end

    yintercept = (y1 >> CDoom::MAPBTOFRAC) + CDoom.fixed_mul(partial, ystep)

    if yt2 > yt1
      mapystep = 1
      partial = FRACUNIT - ((y1 >> CDoom::MAPBTOFRAC) & (FRACUNIT - 1))
      xstep = CDoom.fixed_div(x2 - x1, doom_abs(y2 - y1))
    elsif yt2 < yt1
      mapystep = -1
      partial = (y1 >> CDoom::MAPBTOFRAC) & (FRACUNIT - 1)
      xstep = CDoom.fixed_div(x2 - x1, doom_abs(y2 - y1))
    else
      mapystep = 0
      partial = FRACUNIT
      xstep = 256 * FRACUNIT
    end

    xintercept = (x1 >> CDoom::MAPBTOFRAC) + CDoom.fixed_mul(partial, xstep)

    # Step through map blocks.
    # Count is present to prevent a round off error
    # from skipping the break.
    mapx = xt1
    mapy = yt1

    64.times do |count|
      if flags & CDoom::PT_ADDLINES != 0
        if CDoom.p_block_lines_iterator(mapx, mapy, ->CDoom.pit_add_line_intercepts) == 0
          return 0 # early out
        end
      end

      if flags & CDoom::PT_ADDTHINGS != 0
        if CDoom.p_block_things_iterator(mapx, mapy, ->CDoom.pit_add_thing_intercepts) == 0
          return 0 # early out
        end
      end

      break if mapx == xt2 && mapy == yt2

      if (yintercept >> FRACBITS) == mapy
        yintercept += ystep
        mapx += mapxstep
      elsif (xintercept >> FRACBITS) == mapx
        xintercept += xstep
        mapy += mapystep
      end
    end

    # go through the sorted list
    return CDoom.p_traverse_intercepts(trav, FRACUNIT)
  end

  def self.p_set_mobj_state(mobj : CDoom::Mobj*, state : CDoom::Statenum) : CDoom::DoomBool
    loop do
      if state == CDoom::Statenum::S_NULL
        mobj.value.state = Pointer(CDoom::State).new(CDoom::Statenum::S_NULL.value.to_u64!)
        CDoom.p_remove_mobj(mobj)
        return 0
      end

      st = CDoom.states + state.value
      mobj.value.state = st
      mobj.value.tics = st.value.tics
      mobj.value.sprite = st.value.sprite
      mobj.value.frame = st.value.frame

      # Modified handling.
      # Call action functions when the state is set
      if !st.value.action.null?
        CDoom::ActionfP1.new(st.value.action, Pointer(Void).null).call(mobj.as(Void*))
      end

      state = st.value.nextstate
      break unless mobj.value.tics == 0
    end

    return 1
  end

  def self.p_explode_missile(mo : CDoom::Mobj*)
    mo.value.momx = 0
    mo.value.momy = 0
    mo.value.momz = 0

    CDoom.p_set_mobj_state(mo, CDoom::Statenum.new(CDoom.mobjinfo[mo.value.type.value].deathstate))

    mo.value.tics = mo.value.tics - (CDoom.p_random & 3)

    mo.value.tics = 1 if mo.value.tics < 1

    mo.value.flags = mo.value.flags & ~CDoom::Mobjflag::MF_MISSILE.value

    CDoom.s_start_sound(mo, mo.value.info.value.deathsound) if mo.value.info.value.deathsound != 0
  end

  def self.p_xymovement(mo : CDoom::Mobj*)
    if mo.value.momx == 0 && mo.value.momy == 0
      if mo.value.flags & CDoom::Mobjflag::MF_SKULLFLY.value != 0
        # the skull slammed into something
        mo.value.flags = mo.value.flags & ~CDoom::Mobjflag::MF_SKULLFLY.value
        mo.value.momx = 0
        mo.value.momy = 0
        mo.value.momz = 0

        CDoom.p_set_mobj_state(mo, CDoom::Statenum.new(mo.value.info.value.spawnstate))
      end
      return
    end

    player = mo.value.player

    if mo.value.momx > CDoom::MAXMOVE
      mo.value.momx = CDoom::MAXMOVE
    elsif mo.value.momx < -CDoom::MAXMOVE
      mo.value.momx = -CDoom::MAXMOVE
    end

    if mo.value.momy > CDoom::MAXMOVE
      mo.value.momy = CDoom::MAXMOVE
    elsif mo.value.momy < -CDoom::MAXMOVE
      mo.value.momy = -CDoom::MAXMOVE
    end

    xmove = mo.value.momx
    ymove = mo.value.momy

    loop do
      if xmove > CDoom::MAXMOVE // 2 || ymove > CDoom::MAXMOVE // 2
        ptryx = mo.value.x &+ xmove.tdiv(2)
        ptryy = mo.value.y &+ ymove.tdiv(2)
        xmove >>= 1
        ymove >>= 1
      else
        ptryx = mo.value.x &+ xmove
        ptryy = mo.value.y &+ ymove
        xmove = 0
        ymove = 0
      end

      if CDoom.p_try_move(mo, ptryx, ptryy) == 0
        # blocked move
        if !mo.value.player.null?
          CDoom.p_slide_move(mo) # try to slide along it
        elsif mo.value.flags & CDoom::Mobjflag::MF_MISSILE.value != 0
          # explode a missile
          if !CDoom.ceilingline.null? &&
             !CDoom.ceilingline.value.backsector.null? &&
             CDoom.ceilingline.value.backsector.value.ceilingpic == CDoom.skyflatnum
            # Hack to prevent missiles exploding
            # against the sky.
            # Does not handle sky floors.
            CDoom.p_remove_mobj(mo)
            return
          end
          CDoom.p_explode_missile(mo)
        else
          mo.value.momx = 0
          mo.value.momy = 0
        end
      end

      break unless xmove != 0 || ymove != 0
    end

    # slow down
    if !player.null? && player.value.cheats & CDoom::Cheat::CF_NOMOMENTUM.value != 0
      # debug option for no sliding at all
      mo.value.momx = 0
      mo.value.momy = 0
      return
    end

    # no friction for missiles ever
    return if mo.value.flags & (CDoom::Mobjflag::MF_MISSILE.value | CDoom::Mobjflag::MF_SKULLFLY.value) != 0

    # no friction when airborne
    return if mo.value.z > mo.value.floorz

    if (mo.value.flags & CDoom::Mobjflag::MF_CORPSE.value != 0) &&
       (mo.value.momx > FRACUNIT.tdiv(4) ||
       mo.value.momx < -FRACUNIT.tdiv(4) ||
       mo.value.momy > FRACUNIT.tdiv(4) ||
       mo.value.momy < -FRACUNIT.tdiv(4)) &&
       (mo.value.floorz != mo.value.subsector.value.sector.value.floorheight)
      # do not stop sliding
      # if halfway off a step with some momentum
      return
    end

    if mo.value.momx > -CDoom::STOPSPEED &&
       mo.value.momx < CDoom::STOPSPEED &&
       mo.value.momy > -CDoom::STOPSPEED &&
       mo.value.momy < CDoom::STOPSPEED &&
       (player.null? || (
         player.value.cmd.forwardmove == 0 &&
         player.value.cmd.sidemove == 0
       ))
      # if in a walking frame, stop moving
      if !player.null? && ((player.value.mo.value.state - CDoom.states) - CDoom::Statenum::S_PLAY_RUN1.value).to_u32! < 4
        CDoom.p_set_mobj_state(player.value.mo, CDoom::Statenum::S_PLAY)
      end

      mo.value.momx = 0
      mo.value.momy = 0
    else
      mo.value.momx = CDoom.fixed_mul(mo.value.momx, CDoom::FRICTION)
      mo.value.momy = CDoom.fixed_mul(mo.value.momy, CDoom::FRICTION)
    end
  end

  def self.p_zmovement(mo : CDoom::Mobj*)
    # check for smooth step up
    if !mo.value.player.null? && mo.value.z < mo.value.floorz
      mo.value.player.value.viewheight = mo.value.player.value.viewheight - (mo.value.floorz - mo.value.z)

      mo.value.player.value.deltaviewheight = (CDoom::VIEWHEIGHT - mo.value.player.value.viewheight) >> 3
    end

    # adjust height
    mo.value.z = mo.value.z + mo.value.momz

    if mo.value.flags & CDoom::Mobjflag::MF_FLOAT.value != 0 &&
       !mo.value.target.null?
      # float down towards target if too close
      if mo.value.flags & CDoom::Mobjflag::MF_SKULLFLY.value == 0 &&
         mo.value.flags & CDoom::Mobjflag::MF_INFLOAT.value == 0
        dist = CDoom.p_aprox_distance(mo.value.x - mo.value.target.value.x,
          mo.value.y - mo.value.target.value.y)

        delta = (mo.value.target.value.z + (mo.value.height >> 1)) - mo.value.z

        if delta < 0 && dist < -(delta * 3)
          mo.value.z = mo.value.z - CDoom::FLOATSPEED
        elsif delta > 0 && dist < (delta * 3)
          mo.value.z = mo.value.z + CDoom::FLOATSPEED
        end
      end
    end

    # clip movement
    if mo.value.z <= mo.value.floorz
      # hit the floor

      # Note (id):
      #  somebody left this after the setting momz to 0,
      #  kinda useless there.
      if mo.value.flags & CDoom::Mobjflag::MF_SKULLFLY.value != 0
        # the skull slammed into something
        mo.value.momz = -mo.value.momz
      end

      if mo.value.momz < 0
        if !mo.value.player.null? &&
           mo.value.momz < -CDoom::GRAVITY * 8
          # Squat down.
          # Decrease viewheight for a moment
          # after hitting the ground (hard),
          # and utter appropriate sound.
          mo.value.player.value.deltaviewheight = mo.value.momz >> 3
          CDoom.s_start_sound(mo, CDoom::Sfxenum::SFX_oof.value)
        end
        mo.value.momz = 0
      end
      mo.value.z = mo.value.floorz

      if mo.value.flags & CDoom::Mobjflag::MF_MISSILE.value != 0 &&
         mo.value.flags & CDoom::Mobjflag::MF_NOCLIP.value == 0
        CDoom.p_explode_missile(mo)
        return
      end
    elsif mo.value.flags & CDoom::Mobjflag::MF_NOGRAVITY.value == 0
      if mo.value.momz == 0
        mo.value.momz = -CDoom::GRAVITY * 2
      else
        mo.value.momz = mo.value.momz - CDoom::GRAVITY
      end
    end

    if mo.value.z + mo.value.height > mo.value.ceilingz
      # hit the ceiling
      mo.value.momz = 0 if mo.value.momz > 0
      mo.value.z = mo.value.ceilingz - mo.value.height

      if mo.value.flags & CDoom::Mobjflag::MF_SKULLFLY.value != 0
        # the skull slammed into something
        mo.value.momz = -mo.value.momz
      end

      if mo.value.flags & CDoom::Mobjflag::MF_MISSILE.value != 0 &&
         mo.value.flags & CDoom::Mobjflag::MF_NOCLIP.value == 0
        CDoom.p_explode_missile(mo)
        return
      end
    end
  end

  def self.p_nightmare_respawn(mobj : CDoom::Mobj*)
    x = mobj.value.spawnpoint.x.to_i32 << FRACBITS
    y = mobj.value.spawnpoint.y.to_i32 << FRACBITS

    # somthing is occupying it's position?
    return if CDoom.p_check_position(mobj, x, y) == 0 # no respwan

    # spawn a teleport fog at old spot
    # because of removal of the body?
    mo = CDoom.p_spawn_mobj(mobj.value.x,
      mobj.value.y,
      mobj.value.subsector.value.sector.value.floorheight, CDoom::Mobjtype::MT_TFOG)
    # initiate teleport sound
    CDoom.s_start_sound(mo, CDoom::Sfxenum::SFX_telept.value)

    # spawn a teleport fog at the new spot
    ss = CDoom.r_point_in_subsector(x, y)

    mo = CDoom.p_spawn_mobj(x, y, ss.value.sector.value.floorheight, CDoom::Mobjtype::MT_TFOG)

    CDoom.s_start_sound(mo, CDoom::Sfxenum::SFX_telept.value)

    # spawn the new monster
    mthing = pointerof(mobj.value.@spawnpoint)

    # spawn it
    if mobj.value.info.value.flags & CDoom::Mobjflag::MF_SPAWNCEILING.value != 0
      z = CDoom::ONCEILINGZ
    else
      z = CDoom::ONFLOORZ
    end

    # inherit attributes from deceased one
    mo = CDoom.p_spawn_mobj(x, y, z, mobj.value.type)
    mo.value.spawnpoint = mobj.value.spawnpoint
    mo.value.angle = ANG45 &* (mthing.value.angle.tdiv(45))

    if mthing.value.options & CDoom::MTF_AMBUSH != 0
      mo.value.flags = mo.value.flags | CDoom::Mobjflag::MF_AMBUSH.value
    end

    mo.value.reactiontime = 18

    # remove the old monster,
    CDoom.p_remove_mobj(mobj)
  end

  def self.p_mobj_thinker(mobj : CDoom::Mobj*)
    mobj = mobj.as(CDoom::Mobj*)
    # momentum movement
    if mobj.value.momx != 0 ||
       mobj.value.momy != 0 ||
       (mobj.value.flags & CDoom::Mobjflag::MF_SKULLFLY.value != 0)
      CDoom.p_xymovement(mobj)

      return if mobj.value.thinker.remove != 0 # mobj was removed
    end
    if mobj.value.z != mobj.value.floorz ||
       mobj.value.momz != 0
      CDoom.p_zmovement(mobj)

      return if mobj.value.thinker.remove != 0 # mobj was removed
    end

    # cycle through states,
    # calling action functions at transitions
    if mobj.value.tics != -1
      mobj.value.tics = mobj.value.tics - 1

      # you can cycle through multiple states in a tic
      if mobj.value.tics == 0 &&
         CDoom.p_set_mobj_state(mobj, CDoom::Statenum.new(mobj.value.state.value.nextstate)) == 0
        return # freed itself
      end
    else
      # check for nightmare respawn
      return if mobj.value.flags & CDoom::Mobjflag::MF_COUNTKILL.value == 0

      return if CDoom.respawnmonsters == 0

      mobj.value.movecount = mobj.value.movecount + 1

      return if mobj.value.movecount < 12 * 35

      return if CDoom.leveltime & 31 != 0

      return if CDoom.p_random > 4

      CDoom.p_nightmare_respawn(mobj)
    end
  end

  def self.p_spawn_mobj(x : CDoom::Fixed, y : CDoom::Fixed, z : CDoom::Fixed, type : CDoom::Mobjtype) : CDoom::Mobj*
    mobj = CDoom.z_malloc(sizeof(CDoom::Mobj), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Mobj*)
    CDoom.doom_memset(mobj, 0, sizeof(CDoom::Mobj))
    info = CDoom.mobjinfo + type.value

    mobj.value.type = type
    mobj.value.info = info
    mobj.value.x = x
    mobj.value.y = y
    mobj.value.radius = info.value.radius
    mobj.value.height = info.value.height
    mobj.value.flags = info.value.flags
    mobj.value.health = info.value.spawnhealth

    mobj.value.reactiontime = info.value.reactiontime if CDoom.gameskill != CDoom::Skill::Nightmare

    mobj.value.lastlook = CDoom.p_random % CDoom::MAXPLAYERS
    # do not set the state with p_set_mobj_state,
    # because action routines can not be called yet
    st = CDoom.states + info.value.spawnstate

    mobj.value.state = st
    mobj.value.tics = st.value.tics
    mobj.value.sprite = st.value.sprite
    mobj.value.frame = st.value.frame

    # set subsector and/or block links
    CDoom.p_set_thing_position(mobj)

    mobj.value.floorz = mobj.value.subsector.value.sector.value.floorheight
    mobj.value.ceilingz = mobj.value.subsector.value.sector.value.ceilingheight

    if z == CDoom::ONFLOORZ
      mobj.value.z = mobj.value.floorz
    elsif z == CDoom::ONCEILINGZ
      mobj.value.z = mobj.value.ceilingz - mobj.value.info.value.height
    else
      mobj.value.z = z
    end

    pointerof(mobj.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.p_mobj_thinker).pointer, Pointer(Void).null)

    CDoom.p_add_thinker(pointerof(mobj.value.@thinker))

    return mobj
  end

  def self.p_remove_mobj(mobj : CDoom::Mobj*)
    if mobj.value.flags & CDoom::Mobjflag::MF_SPECIAL.value != 0 &&
       mobj.value.flags & CDoom::Mobjflag::MF_DROPPED.value == 0 &&
       mobj.value.type != CDoom::Mobjtype::MT_INV &&
       mobj.value.type != CDoom::Mobjtype::MT_INS
      CDoom.itemrespawnque[CDoom.iquehead] = mobj.value.spawnpoint
      CDoom.itemrespawntime[CDoom.iquehead] = CDoom.leveltime
      CDoom.iquehead = (CDoom.iquehead + 1) & (CDoom::ITEMQUESIZE - 1)

      # lose one off the end?
      CDoom.iquetail = (CDoom.iquetail + 1) & (CDoom::ITEMQUESIZE - 1) if CDoom.iquehead == CDoom.iquetail
    end

    # unlink from sector and block lists
    CDoom.p_unset_thing_position(mobj)

    # stop any playing sound
    CDoom.s_stop_sound(mobj)

    # free block
    CDoom.p_remove_thinker(mobj.as(CDoom::Thinker*))
  end

  def self.p_respawn_specials
    # only respawn items in deathmatch
    return if CDoom.deathmatch != 2

    # nothing left to respawn?
    return if CDoom.iquehead == CDoom.iquetail

    # wait at least 30 seconds
    return if CDoom.leveltime - CDoom.itemrespawntime[CDoom.iquetail] < 30 * 35

    mthing = CDoom.itemrespawnque.to_unsafe + CDoom.iquetail

    x = mthing.value.x.to_i32 << FRACBITS
    y = mthing.value.y.to_i32 << FRACBITS

    # spawn a teleport fog at the new spot
    ss = CDoom.r_point_in_subsector(x, y)

    mo = CDoom.p_spawn_mobj(x, y, ss.value.sector.value.floorheight, CDoom::Mobjtype::MT_IFOG)
    CDoom.s_start_sound(mo, CDoom::Sfxenum::SFX_itmbk.value)

    # find which type to spawn
    i = 0
    while i < CDoom::Mobjtype::NUMMOBJTYPES.value
      break if mthing.value.type == CDoom.mobjinfo[i].doomednum
      i += 1
    end

    # spawn it
    if CDoom.mobjinfo[i].flags & CDoom::Mobjflag::MF_SPAWNCEILING.value != 0
      z = CDoom::ONCEILINGZ
    else
      z = CDoom::ONFLOORZ
    end

    mo = CDoom.p_spawn_mobj(x, y, z, CDoom::Mobjtype.new(i))
    mo.value.spawnpoint = mthing.value
    mo.value.angle = ANG45 &* (mthing.value.angle.tdiv(45))

    # pull it from the que
    CDoom.iquetail = (CDoom.iquetail + 1) & (CDoom::ITEMQUESIZE - 1)
  end

  #
  # Called when a player is spawned on the level.
  # Most of the player structure stays unchanged
  # between levels.
  #
  def self.p_spawn_player(mthing : CDoom::Mapthing*)
    # not playing?
    return if CDoom.playeringame[mthing.value.type - 1] == 0

    p = CDoom.players.to_unsafe + mthing.value.type - 1

    if p.value.playerstate == CDoom::Playerstate::PST_REBORN
      CDoom.g_player_reborn(mthing.value.type - 1)
    end

    x = mthing.value.x.to_i32 << FRACBITS
    y = mthing.value.y.to_i32 << FRACBITS
    z = CDoom::ONFLOORZ
    mobj = CDoom.p_spawn_mobj(x, y, z, CDoom::Mobjtype::MT_PLAYER)

    # set color translations for player sprites
    if mthing.value.type > 1
      mobj.value.flags = mobj.value.flags | ((mthing.value.type - 1).to_i32 << CDoom::Mobjflag::MF_TRANSSHIFT.value)
    end

    mobj.value.angle = ANG45 &* (mthing.value.angle.tdiv(45))
    mobj.value.player = p
    mobj.value.health = p.value.health

    p.value.mo = mobj
    p.value.playerstate = CDoom::Playerstate::PST_LIVE
    p.value.refire = 0
    p.value.message = Pointer(UInt8).null
    p.value.damagecount = 0
    p.value.bonuscount = 0
    p.value.extralight = 0
    p.value.fixedcolormap = 0
    p.value.viewheight = CDoom::VIEWHEIGHT

    # setup gun psprite
    CDoom.p_setup_psprites(p)

    # give all cards in death match mode
    if CDoom.deathmatch != 0
      CDoom::Card::NUMCARDS.value.times do |i|
        p.value.cards[i] = 1
      end
    end

    if mthing.value.type - 1 == CDoom.consoleplayer
      # wake up the status bar
      CDoom.st_start
      # wake up the heads up text
      CDoom.hu_start
    end
  end

  #
  # The fields of the mapthing should
  # already be in host byte order.
  #
  def self.p_spawn_map_thing(mthing : CDoom::Mapthing*)
    # count deathmatch start positions
    if mthing.value.type == 11
      if CDoom.deathmatch_p < CDoom.deathmatchstarts.to_unsafe + 10
        CDoom.doom_memcpy(CDoom.deathmatch_p, mthing, sizeof(CDoom::Mapthing))
        CDoom.deathmatch_p += 1
      end
      return
    end

    # check for players specially
    if mthing.value.type <= 4
      # save spots for respawning in network games
      (CDoom.playerstarts.to_unsafe + (mthing.value.type - 1)).value = mthing.value
      CDoom.p_spawn_player(mthing) if CDoom.deathmatch == 0

      return
    end

    # check for apropriate skill level
    return if CDoom.netgame == 0 && mthing.value.options & 16 != 0

    if CDoom.gameskill == CDoom::Skill::Baby
      bit = 1
    elsif CDoom.gameskill == CDoom::Skill::Nightmare
      bit = 4
    else
      bit = 1 << (CDoom.gameskill.value - 1)
    end

    return if mthing.value.options & bit == 0

    # find which type to spawn
    i = 0
    while i < CDoom::Mobjtype::NUMMOBJTYPES.value
      break if mthing.value.type == CDoom.mobjinfo[i].doomednum
      i += 1
    end

    if i == CDoom::Mobjtype::NUMMOBJTYPES.value
      CDoom.i_error("Error: p_spawn_map_thing: Unknown type #{mthing.value.type} at (#{mthing.value.x},#{mthing.value.y})")
    end

    # don't spawn keycards and players in deathmatch
    return if CDoom.deathmatch != 0 && CDoom.mobjinfo[i].flags & CDoom::Mobjflag::MF_NOTDMATCH.value != 0

    # don't spawn any monsters if -nomonsters
    if CDoom.nomonsters != 0 &&
       (i == CDoom::Mobjtype::MT_SKULL.value ||
       (CDoom.mobjinfo[i].flags & CDoom::Mobjflag::MF_COUNTKILL.value != 0))
      return
    end

    # spawn it
    x = mthing.value.x.to_i32 << FRACBITS
    y = mthing.value.y.to_i32 << FRACBITS

    if CDoom.mobjinfo[i].flags & CDoom::Mobjflag::MF_SPAWNCEILING.value != 0
      z = CDoom::ONCEILINGZ
    else
      z = CDoom::ONFLOORZ
    end

    mobj = CDoom.p_spawn_mobj(x, y, z, CDoom::Mobjtype.new(i))
    mobj.value.spawnpoint = mthing.value

    if mobj.value.tics > 0
      mobj.value.tics = 1 + (CDoom.p_random % mobj.value.tics)
    end
    if mobj.value.flags & CDoom::Mobjflag::MF_COUNTKILL.value != 0
      CDoom.totalkills += 1
    end
    if mobj.value.flags & CDoom::Mobjflag::MF_COUNTITEM.value != 0
      CDoom.totalitems += 1
    end

    mobj.value.angle = ANG45 &* (mthing.value.angle.tdiv(45))
    if mthing.value.options & CDoom::MTF_AMBUSH != 0
      mobj.value.flags = mobj.value.flags | CDoom::Mobjflag::MF_AMBUSH.value
    end
  end

  #
  # GAME SPAWN FUNCTIONS
  #

  def self.p_spawn_puff(x : CDoom::Fixed, y : CDoom::Fixed, z : CDoom::Fixed)
    z += (CDoom.p_random - CDoom.p_random) << 10

    th = CDoom.p_spawn_mobj(x, y, z, CDoom::Mobjtype::MT_PUFF)
    th.value.momz = FRACUNIT
    th.value.tics = th.value.tics - (CDoom.p_random & 3)

    th.value.tics = 1 if th.value.tics < 1

    # don't make punches spark on the wall
    CDoom.p_set_mobj_state(th, CDoom::Statenum::S_PUFF3) if CDoom.attackrange == CDoom::MELEERANGE
  end

  def self.p_spawn_blood(x : CDoom::Fixed, y : CDoom::Fixed, z : CDoom::Fixed, damage : Int32)
    z += (CDoom.p_random - CDoom.p_random) << 10
    th = CDoom.p_spawn_mobj(x, y, z, CDoom::Mobjtype::MT_BLOOD)
    th.value.momz = FRACUNIT * 2
    th.value.tics = th.value.tics - (CDoom.p_random & 3)

    th.value.tics = 1 if th.value.tics < 1

    if damage <= 12 && damage >= 9
      CDoom.p_set_mobj_state(th, CDoom::Statenum::S_BLOOD2)
    elsif damage < 9
      CDoom.p_set_mobj_state(th, CDoom::Statenum::S_BLOOD3)
    end
  end

  #
  # Moves the missile forward a bit
  #  and possibly explodes it right there.
  #
  def self.p_check_missile_spawn(th : CDoom::Mobj*)
    th.value.tics = th.value.tics - (CDoom.p_random & 3)
    th.value.tics = 1 if th.value.tics < 1

    # move a little forward so an angle can
    # be computed if it immediately explodes
    th.value.x = th.value.x + (th.value.momx >> 1)
    th.value.y = th.value.y + (th.value.momy >> 1)
    th.value.z = th.value.z + (th.value.momz >> 1)

    CDoom.p_explode_missile(th) if CDoom.p_try_move(th, th.value.x, th.value.y) == 0
  end

  def self.p_spawn_missile(source : CDoom::Mobj*, dest : CDoom::Mobj*, type : CDoom::Mobjtype) : CDoom::Mobj*
    th = CDoom.p_spawn_mobj(source.value.x,
      source.value.y,
      source.value.z + 4 * 8 * FRACUNIT, type)

    CDoom.s_start_sound(th, th.value.info.value.seesound) if th.value.info.value.seesound != 0

    th.value.target = source # where it came from
    an = CDoom.r_point_to_angle2(source.value.x, source.value.y, dest.value.x, dest.value.y)

    # fuzzy player
    an &+= (CDoom.p_random - CDoom.p_random) << 20 if dest.value.flags & CDoom::Mobjflag::MF_SHADOW.value != 0

    th.value.angle = an
    an >>= CDoom::ANGLETOFINESHIFT
    th.value.momx = CDoom.fixed_mul(th.value.info.value.speed, @@finecosine[an])
    th.value.momy = CDoom.fixed_mul(th.value.info.value.speed, @@finesine[an])

    dist = CDoom.p_aprox_distance(dest.value.x - source.value.x, dest.value.y - source.value.y)
    dist = dist.tdiv(th.value.info.value.speed)

    dist = 1 if dist < 1

    th.value.momz = (dest.value.z - source.value.z).tdiv(dist)
    CDoom.p_check_missile_spawn(th)

    return th
  end

  #
  # Tries to aim at a nearby monster
  #
  def self.p_spawn_player_missile(source : CDoom::Mobj*, type : CDoom::Mobjtype)
    # see which target is to be aimed at
    an = source.value.angle
    slope = CDoom.p_aim_line_attack(source, an, 16 * 64 * FRACUNIT)

    if CDoom.linetarget.null?
      an &+= 1 << 26
      slope = CDoom.p_aim_line_attack(source, an, 16 * 64 * FRACUNIT)

      if CDoom.linetarget.null?
        an &-= 2 << 26
        slope = CDoom.p_aim_line_attack(source, an, 16 * 64 * FRACUNIT)
      end

      if CDoom.linetarget.null?
        an = source.value.angle
        slope = 0
      end
    end

    x = source.value.x
    y = source.value.y
    z = source.value.z + 4 * 8 * FRACUNIT

    th = CDoom.p_spawn_mobj(x, y, z, type)

    CDoom.s_start_sound(th, th.value.info.value.seesound) if th.value.info.value.seesound != 0

    th.value.target = source
    th.value.angle = an
    th.value.momx = CDoom.fixed_mul(th.value.info.value.speed,
      @@finecosine[an >> CDoom::ANGLETOFINESHIFT])
    th.value.momy = CDoom.fixed_mul(th.value.info.value.speed,
      @@finesine[an >> CDoom::ANGLETOFINESHIFT])
    th.value.momz = CDoom.fixed_mul(th.value.info.value.speed, slope)

    CDoom.p_check_missile_spawn(th)
  end

  #
  # Move a plat up and down
  #
  def self.t_plat_raise(plat : CDoom::Plat*)
    case plat.value.status
    when CDoom::Platenum::Up
      res = CDoom.t_move_plane(plat.value.sector,
        plat.value.speed,
        plat.value.high,
        plat.value.crush, 0, 1)

      if plat.value.type == CDoom::Plattype::RaiseAndChange ||
         plat.value.type == CDoom::Plattype::RaiseToNearestAndChange
        CDoom.s_start_sound(pointerof(plat.value.sector.value.@soundorg),
          CDoom::Sfxenum::SFX_stnmov) if CDoom.leveltime & 7 == 0
      end

      if res == CDoom::Result::Crushed && plat.value.crush == 0
        plat.value.count = plat.value.wait
        plat.value.status = CDoom::Platenum::Down
        CDoom.s_start_sound(pointerof(plat.value.sector.value.@soundorg),
          CDoom::Sfxenum::SFX_pstart)
      else
        if res == CDoom::Result::Pastdest
          plat.value.count = plat.value.wait
          plat.value.status = CDoom::Platenum::Waiting
          CDoom.s_start_sound(pointerof(plat.value.sector.value.@soundorg),
            CDoom::Sfxenum::SFX_pstop)

          case plat.value.type
          when CDoom::Plattype::BlazeDWUS, CDoom::Plattype::DownWaitUpStay
            CDoom.p_remove_active_plat(plat)
          when CDoom::Plattype::RaiseAndChange, CDoom::Plattype::RaiseToNearestAndChange
            CDoom.p_remove_active_plat(plat)
          end
        end
      end
    when CDoom::Platenum::Down
      res = CDoom.t_move_plane(plat.value.sector, plat.value.speed, plat.value.low, 0, 0, -1)

      if res == CDoom::Result::Pastdest
        plat.value.count = plat.value.wait
        plat.value.status = CDoom::Platenum::Waiting
        CDoom.s_start_sound(pointerof(plat.value.sector.value.@soundorg),
          CDoom::Sfxenum::SFX_pstop)
      end
    when CDoom::Platenum::Waiting
      plat.value.count = plat.value.count - 1
      if plat.value.count == 0
        if plat.value.sector.value.floorheight == plat.value.low
          plat.value.status = CDoom::Platenum::Up
        else
          plat.value.status = CDoom::Platenum::Down
        end
        CDoom.s_start_sound(pointerof(plat.value.sector.value.@soundorg),
          CDoom::Sfxenum::SFX_pstart)
      end
    when CDoom::Platenum::InStasis
    end
  end

  #
  # Do Platforms
  #  "amount" is only used for SOME platforms.
  #
  def self.ev_do_plat(line : CDoom::Line*, type : CDoom::Plattype, amount : LibC::Int) : LibC::Int
    secnum = -1
    rtn = 0

    # Activate all <type> plats that are in_stasis
    case type
    when CDoom::Plattype::PerpetualRaise
      CDoom.p_activate_in_stasis(line.value.tag)
    end

    while (secnum = CDoom.p_find_sector_from_line_tag(line, secnum)) >= 0
      sec = CDoom.sectors + secnum

      next if !sec.value.specialdata.null?

      # Find lowest & highest floors around sector
      rtn = 1
      plat = CDoom.z_malloc(sizeof(CDoom::Plat), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Plat*)
      CDoom.p_add_thinker(pointerof(plat.value.@thinker))

      plat.value.type = type
      plat.value.sector = sec
      plat.value.sector.value.specialdata = plat
      pointerof(plat.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_plat_raise).pointer, Pointer(Void).null)
      plat.value.crush = 0
      plat.value.tag = line.value.tag

      case type
      when CDoom::Plattype::RaiseToNearestAndChange
        plat.value.speed = CDoom::PLATSPEED // 2
        sec.value.floorpic = CDoom.sides[line.value.sidenum[0]].sector.value.floorpic
        plat.value.high = CDoom.p_find_next_highest_floor(sec, sec.value.floorheight)
        plat.value.wait = 0
        plat.value.status = CDoom::Platenum::Up
        # NO MORE DAMAGE, IF APPLICABLE
        sec.value.special = 0
        CDoom.s_start_sound(pointerof(sec.value.@soundorg),
          CDoom::Sfxenum::SFX_stnmov)
      when CDoom::Plattype::RaiseAndChange
        plat.value.speed = CDoom::PLATSPEED // 2
        sec.value.floorpic = CDoom.sides[line.value.sidenum[0]].sector.value.floorpic
        plat.value.high = sec.value.floorheight + amount * FRACUNIT
        plat.value.wait = 0
        plat.value.status = CDoom::Platenum::Up

        CDoom.s_start_sound(pointerof(sec.value.@soundorg),
          CDoom::Sfxenum::SFX_stnmov)
      when CDoom::Plattype::DownWaitUpStay
        plat.value.speed = CDoom::PLATSPEED * 4
        plat.value.low = CDoom.p_find_lowest_floor_surrounding(sec)

        plat.value.low = sec.value.floorheight if plat.value.low > sec.value.floorheight

        plat.value.high = sec.value.floorheight
        plat.value.wait = 35 * CDoom::PLATWAIT
        plat.value.status = CDoom::Platenum::Down
        CDoom.s_start_sound(pointerof(sec.value.@soundorg),
          CDoom::Sfxenum::SFX_pstart)
      when CDoom::Plattype::BlazeDWUS
        plat.value.speed = CDoom::PLATSPEED * 8
        plat.value.low = CDoom.p_find_lowest_floor_surrounding(sec)

        plat.value.low = sec.value.floorheight if plat.value.low > sec.value.floorheight

        plat.value.high = sec.value.floorheight
        plat.value.wait = 35 * CDoom::PLATWAIT
        plat.value.status = CDoom::Platenum::Down
        CDoom.s_start_sound(pointerof(sec.value.@soundorg),
          CDoom::Sfxenum::SFX_pstart)
      when CDoom::Plattype::PerpetualRaise
        plat.value.speed = CDoom::PLATSPEED
        plat.value.low = CDoom.p_find_lowest_floor_surrounding(sec)

        plat.value.low = sec.value.floorheight if plat.value.low > sec.value.floorheight

        plat.value.high = CDoom.p_find_highest_floor_surrounding(sec)

        plat.value.high = sec.value.floorheight if plat.value.high < sec.value.floorheight

        plat.value.wait = 35 * CDoom::PLATWAIT
        plat.value.status = CDoom::Platenum.new(CDoom.p_random & 1)
        CDoom.s_start_sound(pointerof(sec.value.@soundorg),
          CDoom::Sfxenum::SFX_pstart)
      end
      CDoom.p_add_active_plat(plat)
    end

    return rtn
  end

  def self.p_activate_in_stasis(tag : LibC::Int)
    CDoom::MAXPLATS.times do |i|
      if !CDoom.activeplats[i].null? &&
         CDoom.activeplats[i].value.tag == tag &&
         CDoom.activeplats[i].value.status == CDoom::Platenum::InStasis
        CDoom.activeplats[i].value.status = CDoom.activeplats[i].value.oldstatus
        pointerof(CDoom.activeplats[i].value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_plat_raise).pointer, Pointer(Void).null)
      end
    end
  end

  def self.ev_stop_plat(line : CDoom::Line*)
    CDoom::MAXPLATS.times do |i|
      if !CDoom.activeplats[i].null? &&
         CDoom.activeplats[i].value.status != CDoom::Platenum::InStasis &&
         CDoom.activeplats[i].value.tag == line.value.tag
        CDoom.activeplats[i].value.oldstatus = CDoom.activeplats[i].value.status
        CDoom.activeplats[i].value.status = CDoom::Platenum::InStasis
        pointerof(CDoom.activeplats[i].value.@thinker.@function).as(CDoom::ActionfV*).value = NULL_PROC
      end
    end
  end

  def self.p_add_active_plat(plat : CDoom::Plat*)
    CDoom::MAXPLATS.times do |i|
      if CDoom.activeplats[i].null?
        CDoom.activeplats[i] = plat
        return
      end
    end
    CDoom.i_error("Error: p_add_active_plat: no more plats!")
  end

  def self.p_remove_active_plat(plat : CDoom::Plat*)
    CDoom::MAXPLATS.times do |i|
      if plat == CDoom.activeplats[i]
        CDoom.activeplats[i].value.sector.value.specialdata = Pointer(Void).null
        CDoom.p_remove_thinker(pointerof(CDoom.activeplats[i].value.@thinker))
        CDoom.activeplats[i] = Pointer(CDoom::Plat).null

        return
      end
    end
    CDoom.i_error("Error: p_remove_active_plat: can't find plat!")
  end

  def self.p_set_psprite(player : CDoom::Player*, position : LibC::Int, stnum : CDoom::Statenum)
    psp = player.value.psprites.to_unsafe + position

    loop do
      if stnum.value == 0
        # object removed itself
        psp.value.state = Pointer(CDoom::State).null
        break
      end

      state = CDoom.states + stnum.value
      psp.value.state = state
      psp.value.tics = state.value.tics # could be 0

      if state.value.misc1 != 0
        # coordinate set
        psp.value.sx = state.value.misc1 << FRACBITS
        psp.value.sy = state.value.misc2 << FRACBITS
      end

      # Call action routine.
      # Modified handling.
      if !state.value.action.null?
        CDoom::ActionfP2.new(state.value.action, Pointer(Void).null).call(player.as(Void*), psp.as(Void*))
        break if psp.value.state.null?
      end

      stnum = psp.value.state.value.nextstate

      break unless psp.value.tics == 0
    end
    # an initial state of 0 could cycle through
  end

  #
  # Starts bringing the pending weapon up
  # from the bottom of the screen.
  # Uses player
  #
  def self.p_bring_up_weapon(player : CDoom::Player*)
    player.value.pendingweapon = player.value.readyweapon if player.value.pendingweapon == CDoom::Weapontype::Nochange

    CDoom.s_start_sound(player.value.mo, CDoom::Sfxenum::SFX_sawup.value) if player.value.pendingweapon == CDoom::Weapontype::Chainsaw

    newstate = CDoom.weaponinfo[player.value.pendingweapon.value].upstate

    player.value.pendingweapon = CDoom::Weapontype::Nochange
    (player.value.psprites.to_unsafe + CDoom::Psprnum::Weapon.value).value.sy = CDoom::WEAPONBOTTOM

    CDoom.p_set_psprite(player, CDoom::Psprnum::Weapon, CDoom::Statenum.new(newstate))
  end

  #
  # Returns true if there is enough ammo to shoot.
  # If not, selects the next weapon to use.
  #
  def self.p_check_ammo(player : CDoom::Player*) : CDoom::DoomBool
    ammo = CDoom::Ammotype.new(CDoom.weaponinfo[player.value.readyweapon.value].ammo)

    # Minimal amount for one shot varies.
    if player.value.readyweapon == CDoom::Weapontype::Bfg
      count = @@deh_bfg_cells_per_shot
    elsif player.value.readyweapon == CDoom::Weapontype::Supershotgun
      count = 2 # Double barrel.
    else
      count = 1 # Regular.
    end

    # Some do not need ammunition anyway.
    # Return if current ammunition sufficient.
    return 1 if ammo == CDoom::Ammotype::Noammo || player.value.ammo[ammo.value] >= count

    # Out of ammo, pick a weapon to change to.
    # Preferences are set here.
    loop do
      if player.value.weaponowned[CDoom::Weapontype::Plasma.value] != 0 &&
         player.value.ammo[CDoom::Ammotype::Cell.value] != 0 &&
         CDoom.gamemode != CDoom::GameMode::Shareware
        player.value.pendingweapon = CDoom::Weapontype::Plasma
      elsif player.value.weaponowned[CDoom::Weapontype::Supershotgun.value] != 0 &&
            player.value.ammo[CDoom::Ammotype::Shell.value] > 2 &&
            CDoom.gamemode == CDoom::GameMode::Commercial
        player.value.pendingweapon = CDoom::Weapontype::Supershotgun
      elsif player.value.weaponowned[CDoom::Weapontype::Chaingun.value] != 0 &&
            player.value.ammo[CDoom::Ammotype::Clip.value] != 0
        player.value.pendingweapon = CDoom::Weapontype::Chaingun
      elsif player.value.weaponowned[CDoom::Weapontype::Shotgun.value] != 0 &&
            player.value.ammo[CDoom::Ammotype::Shell.value] != 0
        player.value.pendingweapon = CDoom::Weapontype::Shotgun
      elsif player.value.ammo[CDoom::Ammotype::Clip.value] != 0
        player.value.pendingweapon = CDoom::Weapontype::Pistol
      elsif player.value.weaponowned[CDoom::Weapontype::Chainsaw.value] != 0
        player.value.pendingweapon = CDoom::Weapontype::Chainsaw
      elsif player.value.weaponowned[CDoom::Weapontype::Missile.value] != 0 &&
            player.value.ammo[CDoom::Ammotype::Misl.value] != 0
        player.value.pendingweapon = CDoom::Weapontype::Missile
      elsif player.value.weaponowned[CDoom::Weapontype::Bfg.value] != 0 &&
            player.value.ammo[CDoom::Ammotype::Cell.value] > 40 &&
            CDoom.gamemode != CDoom::GameMode::Shareware
        player.value.pendingweapon = CDoom::Weapontype::Bfg
      else
        # If everything fails.
        player.value.pendingweapon = CDoom::Weapontype::Fist
      end

      break unless player.value.pendingweapon == CDoom::Weapontype::Nochange
    end

    # Now set appropriate weapon overlay.
    CDoom.p_set_psprite(player,
      CDoom::Psprnum::Weapon,
      CDoom::Statenum.new(CDoom.weaponinfo[player.value.readyweapon.value].downstate))

    return 0
  end

  def self.p_fire_weapon(player : CDoom::Player*)
    return if CDoom.p_check_ammo(player) == 0

    CDoom.p_set_mobj_state(player.value.mo, CDoom::Statenum::S_PLAY_ATK1)
    newstate = CDoom::Statenum.new(CDoom.weaponinfo[player.value.readyweapon.value].atkstate)
    CDoom.p_set_psprite(player, CDoom::Psprnum::Weapon, newstate)
    CDoom.p_noise_alert(player.value.mo, player.value.mo)

    # Pause gun bobbing based off setting
    if @@weaponfirecentered != 0
      psp = player.value.psprites.to_unsafe + CDoom::Psprnum::Weapon.value
      psp.value.sx = FRACUNIT
      psp.value.sy = CDoom::WEAPONTOP
    end
  end

  #
  # Player died, so put the weapon away.
  #
  def self.p_drop_weapon(player : CDoom::Player*)
    CDoom.p_set_psprite(player,
      CDoom::Psprnum::Weapon,
      CDoom::Statenum.new(CDoom.weaponinfo[player.value.readyweapon.value].downstate))
  end

  #
  # The player can fire the weapon
  # or change to another weapon at this time.
  # Follows after getting weapon up,
  # or after previous attack/fire sequence.
  #
  def self.a_weapon_ready(player : CDoom::Player*, psp : CDoom::Pspdef*)
    # get out of attack state
    if player.value.mo.value.state == CDoom.states + CDoom::Statenum::S_PLAY_ATK1.value ||
       player.value.mo.value.state == CDoom.states + CDoom::Statenum::S_PLAY_ATK2.value
      CDoom.p_set_mobj_state(player.value.mo, CDoom::Statenum::S_PLAY)
    end

    if player.value.readyweapon == CDoom::Weapontype::Chainsaw &&
       psp.value.state == CDoom.states + CDoom::Statenum::S_SAW.value
      CDoom.s_start_sound(player.value.mo, CDoom::Sfxenum::SFX_sawidl.value)
    end

    # check for change
    #  if player is dead, put the weapon away
    if player.value.pendingweapon != CDoom::Weapontype::Nochange || player.value.health == 0
      # change weapon
      #  (pending weapon should allready be validated)
      newstate = CDoom::Statenum.new(CDoom.weaponinfo[player.value.readyweapon.value].downstate)
      CDoom.p_set_psprite(player, CDoom::Psprnum::Weapon, newstate)
      return
    end

    # check for fire
    #  the missile launcher and bfg do not auto fire
    if player.value.cmd.buttons & CDoom::Buttoncode::BT_ATTACK.value != 0
      if player.value.attackdown == 0 ||
         (player.value.readyweapon != CDoom::Weapontype::Missile &&
         player.value.readyweapon != CDoom::Weapontype::Bfg)
        player.value.attackdown = 1
        CDoom.p_fire_weapon(player)
        return
      end
    else
      player.value.attackdown = 0
    end

    # bob the weapon based on movement speed
    angle = (128 * CDoom.leveltime) & CDoom::FINEMASK
    psp.value.sx = FRACUNIT + CDoom.fixed_mul(player.value.bob, @@finecosine[angle])
    angle &= CDoom::FINEANGLES.tdiv(2) - 1
    psp.value.sy = CDoom::WEAPONTOP + CDoom.fixed_mul(player.value.bob, @@finesine[angle])
  end

  #
  # The player can re-fire the weapon
  # without lowering it entirely.
  #
  def self.a_refire(player : CDoom::Player*, psp : CDoom::Pspdef*)
    # check for fire
    #  (if a weaponchange is pending, let it go through instead)
    if (player.value.cmd.buttons & CDoom::Buttoncode::BT_ATTACK.value != 0) &&
       player.value.pendingweapon == CDoom::Weapontype::Nochange &&
       player.value.health != 0
      player.value.refire = player.value.refire + 1
      CDoom.p_fire_weapon(player)
    else
      player.value.refire = 0
      CDoom.p_check_ammo(player)
    end
  end

  def self.a_check_reload(player : CDoom::Player*, psp : CDoom::Pspdef*)
    CDoom.p_check_ammo(player)
  end

  #
  # Lowers current weapon,
  #  and changes weapon at bottom.
  #
  def self.a_lower(player : CDoom::Player*, psp : CDoom::Pspdef*)
    psp.value.sy = psp.value.sy + CDoom::LOWERSPEED

    # Is already down.
    return if psp.value.sy < CDoom::WEAPONBOTTOM

    # Player is dead.
    if player.value.playerstate == CDoom::Playerstate::PST_DEAD
      psp.value.sy = CDoom::WEAPONBOTTOM

      # don't bring weapon back up
      return
    end

    # The old weapon has been lowered off the screen,
    # so change the weapon and start raising it
    if player.value.health == 0
      # Player is dead, so keep the weapon off screen.
      CDoom.p_set_psprite(player, CDoom::Psprnum::Weapon, CDoom::Statenum::S_NULL)
      return
    end

    player.value.readyweapon = player.value.pendingweapon

    CDoom.p_bring_up_weapon(player)
  end

  def self.a_raise(player : CDoom::Player*, psp : CDoom::Pspdef*)
    psp.value.sy = psp.value.sy - CDoom::RAISESPEED

    return if psp.value.sy > CDoom::WEAPONTOP

    psp.value.sy = CDoom::WEAPONTOP

    # The weapon has been raised all the way,
    #  so change to the ready state.
    newstate = CDoom::Statenum.new(CDoom.weaponinfo[player.value.readyweapon.value].readystate)

    CDoom.p_set_psprite(player, CDoom::Psprnum::Weapon, newstate)
  end

  def self.a_gun_flash(player : CDoom::Player*, psp : CDoom::Pspdef*)
    CDoom.p_set_mobj_state(player.value.mo, CDoom::Statenum::S_PLAY_ATK2)
    CDoom.p_set_psprite(player, CDoom::Psprnum::Flash, CDoom::Statenum.new(CDoom.weaponinfo[player.value.readyweapon.value].flashstate))
  end

  #
  # WEAPON ATTACKS
  #

  def self.a_punch(player : CDoom::Player*, psp : CDoom::Pspdef*)
    damage = (CDoom.p_random % 10 + 1) << 1

    damage *= 10 if player.value.powers[CDoom::Powertype::Strength.value] != 0

    angle = player.value.mo.value.angle
    angle &+= (CDoom.p_random - CDoom.p_random) << 18
    slope = CDoom.p_aim_line_attack(player.value.mo, angle, CDoom::MELEERANGE)
    CDoom.p_line_attack(player.value.mo, angle, CDoom::MELEERANGE, slope, damage)

    # turn to face target
    if !CDoom.linetarget.null?
      CDoom.s_start_sound(player.value.mo, CDoom::Sfxenum::SFX_punch.value)
      player.value.mo.value.angle = CDoom.r_point_to_angle2(player.value.mo.value.x,
        player.value.mo.value.y,
        CDoom.linetarget.value.x,
        CDoom.linetarget.value.y)
    end
  end

  def self.a_saw(player : CDoom::Player*, psp : CDoom::Pspdef*)
    damage = 2 * (CDoom.p_random % 10 + 1)
    angle = player.value.mo.value.angle
    angle &+= (CDoom.p_random - CDoom.p_random) << 18

    # use meleerange + 1 se the puff doesn't skip the flash
    slope = CDoom.p_aim_line_attack(player.value.mo, angle, CDoom::MELEERANGE + 1)
    CDoom.p_line_attack(player.value.mo, angle, CDoom::MELEERANGE + 1, slope, damage)

    if CDoom.linetarget.null?
      CDoom.s_start_sound(player.value.mo, CDoom::Sfxenum::SFX_sawful.value)
      return
    end
    CDoom.s_start_sound(player.value.mo, CDoom::Sfxenum::SFX_sawhit.value)

    # turn to face target
    angle = CDoom.r_point_to_angle2(player.value.mo.value.x,
      player.value.mo.value.y,
      CDoom.linetarget.value.x,
      CDoom.linetarget.value.y)
    if angle &- player.value.mo.value.angle > ANG180
      if angle &- player.value.mo.value.angle < (-ANG90).tdiv(20)
        player.value.mo.value.angle = angle &+ ANG90.tdiv(21)
      else
        player.value.mo.value.angle = player.value.mo.value.angle &- ANG90.tdiv(20)
      end
    else
      if angle &- player.value.mo.value.angle > ANG90.tdiv(20)
        player.value.mo.value.angle = angle &- ANG90.tdiv(21)
      else
        player.value.mo.value.angle = player.value.mo.value.angle &+ ANG90.tdiv(20)
      end
    end
    player.value.mo.value.flags = player.value.mo.value.flags | CDoom::Mobjflag::MF_JUSTATTACKED.value
  end

  def self.a_fire_missile(player : CDoom::Player*, psp : CDoom::Pspdef*)
    player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] =
      player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] - 1
    CDoom.p_spawn_player_missile(player.value.mo, CDoom::Mobjtype::MT_ROCKET)
  end

  def self.a_fire_bfg(player : CDoom::Player*, psp : CDoom::Pspdef*)
    player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] =
      player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] - @@deh_bfg_cells_per_shot
    CDoom.p_spawn_player_missile(player.value.mo, CDoom::Mobjtype::MT_BFG)
  end

  def self.a_fire_plasma(player : CDoom::Player*, psp : CDoom::Pspdef*)
    player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] =
      player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] - 1
    CDoom.p_set_psprite(player,
      CDoom::Psprnum::Flash,
      CDoom::Statenum.new(CDoom.weaponinfo[player.value.readyweapon.value].flashstate + (CDoom.p_random & 1)))

    CDoom.p_spawn_player_missile(player.value.mo, CDoom::Mobjtype::MT_PLASMA)
  end

  #
  # Sets a slope so a near miss is at aproximately
  # the height of the intended target
  #
  def self.p_bullet_slope(mo : CDoom::Mobj*)
    # see which target is to be aimed at
    an = mo.value.angle
    CDoom.bulletslope = CDoom.p_aim_line_attack(mo, an, 16 * 64 * FRACUNIT)

    if CDoom.linetarget.null?
      an &+= 1 << 26
      CDoom.bulletslope = CDoom.p_aim_line_attack(mo, an, 16 * 64 * FRACUNIT)
      if CDoom.linetarget.null?
        an &-= 2 << 26
        CDoom.bulletslope = CDoom.p_aim_line_attack(mo, an, 16 * 64 * FRACUNIT)
      end
    end
  end

  def self.p_gunshot(mo : CDoom::Mobj*, accurate : CDoom::DoomBool)
    damage = 5 * (CDoom.p_random % 3 + 1)
    angle = mo.value.angle

    angle &+= (CDoom.p_random - CDoom.p_random) << 18 if accurate == 0

    CDoom.p_line_attack(mo, angle, CDoom::MISSILERANGE, CDoom.bulletslope, damage)
  end

  def self.a_fire_pistol(player : CDoom::Player*, psp : CDoom::Pspdef*)
    CDoom.s_start_sound(player.value.mo, CDoom::Sfxenum::SFX_pistol.value)

    CDoom.p_set_mobj_state(player.value.mo, CDoom::Statenum::S_PLAY_ATK2)
    player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] =
      player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] - 1

    CDoom.p_set_psprite(player,
      CDoom::Psprnum::Flash,
      CDoom::Statenum.new(CDoom.weaponinfo[player.value.readyweapon.value].flashstate))

    CDoom.p_bullet_slope(player.value.mo)
    CDoom.p_gunshot(player.value.mo, (player.value.refire == 0).to_unsafe)
  end

  def self.a_fire_shotgun(player : CDoom::Player*, psp : CDoom::Pspdef*)
    CDoom.s_start_sound(player.value.mo, CDoom::Sfxenum::SFX_shotgn.value)
    CDoom.p_set_mobj_state(player.value.mo, CDoom::Statenum::S_PLAY_ATK2)

    player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] =
      player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] - 1

    CDoom.p_set_psprite(player,
      CDoom::Psprnum::Flash,
      CDoom::Statenum.new(CDoom.weaponinfo[player.value.readyweapon.value].flashstate))

    CDoom.p_bullet_slope(player.value.mo)

    7.times do |i|
      CDoom.p_gunshot(player.value.mo, 0)
    end
  end

  def self.a_fire_shotgun2(player : CDoom::Player*, psp : CDoom::Pspdef*)
    CDoom.s_start_sound(player.value.mo, CDoom::Sfxenum::SFX_dshtgn.value)
    CDoom.p_set_mobj_state(player.value.mo, CDoom::Statenum::S_PLAY_ATK2)

    player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] =
      player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] - 2

    CDoom.p_set_psprite(player,
      CDoom::Psprnum::Flash,
      CDoom::Statenum.new(CDoom.weaponinfo[player.value.readyweapon.value].flashstate))

    CDoom.p_bullet_slope(player.value.mo)

    20.times do |i|
      damage = 5 * (CDoom.p_random % 3 + 1)
      angle = player.value.mo.value.angle
      angle &+= (CDoom.p_random - CDoom.p_random) << 19
      CDoom.p_line_attack(player.value.mo,
        angle,
        CDoom::MISSILERANGE,
        CDoom.bulletslope + ((CDoom.p_random - CDoom.p_random) << 5), damage)
    end
  end

  def self.a_fire_cgun(player : CDoom::Player*, psp : CDoom::Pspdef*)
    CDoom.s_start_sound(player.value.mo, CDoom::Sfxenum::SFX_pistol.value)

    return if player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] == 0

    CDoom.p_set_mobj_state(player.value.mo, CDoom::Statenum::S_PLAY_ATK2)
    player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] =
      player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] - 1

    CDoom.p_set_psprite(player,
      CDoom::Psprnum::Flash,
      CDoom::Statenum.new(CDoom.weaponinfo[player.value.readyweapon.value].flashstate +
                          (psp.value.state - (CDoom.states + CDoom::Statenum::S_CHAIN1.value)).to_i32!))

    CDoom.p_bullet_slope(player.value.mo)

    CDoom.p_gunshot(player.value.mo, (player.value.refire == 0).to_unsafe)
  end

  def self.a_light0(player : CDoom::Player*, psp : CDoom::Pspdef*)
    player.value.extralight = 0
  end

  def self.a_light1(player : CDoom::Player*, psp : CDoom::Pspdef*)
    player.value.extralight = 1
  end

  def self.a_light2(player : CDoom::Player*, psp : CDoom::Pspdef*)
    player.value.extralight = 2
  end

  #
  # Spawn a BFG explosion on every monster in view
  #
  def self.a_bfg_spray(mo : CDoom::Mobj*)
    # offset angles from its attack angle
    40.times do |i|
      an = mo.value.angle &- ANG90.tdiv(2) &+ ANG90.tdiv(40) &* i

      # mo->target is the originator (player)
      #  of the missile
      CDoom.p_aim_line_attack(mo.value.target, an, 16 * 64 * FRACUNIT)

      next if CDoom.linetarget.null?

      CDoom.p_spawn_mobj(CDoom.linetarget.value.x,
        CDoom.linetarget.value.y,
        CDoom.linetarget.value.z + (CDoom.linetarget.value.height >> 2),
        CDoom::Mobjtype::MT_EXTRABFG)

      damage = 0
      15.times do |j|
        damage += (CDoom.p_random & 7) + 1
      end

      CDoom.p_damage_mobj(CDoom.linetarget, mo.value.target, mo.value.target, damage)
    end
  end

  def self.a_bfg_sound(player : CDoom::Player*, psp : CDoom::Pspdef*)
    CDoom.s_start_sound(player.value.mo, CDoom::Sfxenum::SFX_bfg.value)
  end

  #
  # Called at start of level for each player.
  #
  def self.p_setup_psprites(player : CDoom::Player*)
    # remove all psprites
    CDoom::Psprnum::NUMPSPRITES.value.times do |i|
      (player.value.psprites.to_unsafe + i).value.state = Pointer(CDoom::State).null
    end

    # spawn the gun
    player.value.pendingweapon = player.value.readyweapon
    CDoom.p_bring_up_weapon(player)
  end

  #
  # Called every tic by player thinking routine.
  #
  def self.p_move_psprites(player : CDoom::Player*)
    psp = (player.value.psprites.to_unsafe)
    CDoom::Psprnum::NUMPSPRITES.value.times do |i|
      # a null state means not active
      if !(state = psp.value.state).null?
        # drop tic count and possibly change state

        # a -1 tic count never changes
        if psp.value.tics != -1
          psp.value.tics = psp.value.tics - 1
          CDoom.p_set_psprite(player, CDoom::Psprnum.new(i), psp.value.state.value.nextstate) if psp.value.tics == 0
        end
      end
      psp += 1
    end

    (player.value.psprites.to_unsafe + CDoom::Psprnum::Flash.value).value.sx = player.value.psprites[CDoom::Psprnum::Weapon.value].sx
    (player.value.psprites.to_unsafe + CDoom::Psprnum::Flash.value).value.sy = player.value.psprites[CDoom::Psprnum::Weapon.value].sy
  end

  def self.p_archive_players(file : IO)
    CDoom::MAXPLAYERS.times do |i|
      next if CDoom.playeringame[i] == 0

      player = CDoom.players[i]
      CDoom::Psprnum::NUMPSPRITES.value.times do |j|
        if !player.psprites[j].state.null?
          (player.psprites.to_unsafe + j).value.state =
            Pointer(CDoom::State).new((player.psprites[j].state - CDoom.states).to_u64!)
        end
      end
      file.write(pointerof(player).as(UInt8*).to_slice(sizeof(CDoom::Player)))
    end
  end

  def self.p_unarchive_players(file : IO)
    CDoom::MAXPLAYERS.times do |i|
      next if CDoom.playeringame[i] == 0

      player = Slice.new((CDoom.players.to_unsafe + i).as(UInt8*), sizeof(CDoom::Player))
      file.read_fully(player)

      # will be set when unarc thinker
      (CDoom.players.to_unsafe + i).value.mo = Pointer(CDoom::Mobj).null
      (CDoom.players.to_unsafe + i).value.message = Pointer(UInt8).null
      (CDoom.players.to_unsafe + i).value.attacker = Pointer(CDoom::Mobj).null

      CDoom::Psprnum::NUMPSPRITES.value.times do |j|
        if !CDoom.players[i].psprites[j].state.null?
          ((CDoom.players.to_unsafe + i).value.psprites.to_unsafe + j).value.state =
            CDoom.states + CDoom.players[i].psprites[j].state.address
        end
      end
    end
  end

  def self.p_archive_world(file : IO)
    sec = CDoom.sectors
    # do sectors
    CDoom.numsectors.times do |i|
      file.write_bytes((sec.value.floorheight >> FRACBITS).to_i16!)
      file.write_bytes((sec.value.ceilingheight >> FRACBITS).to_i16!)
      file.write_bytes(sec.value.floorpic)
      file.write_bytes(sec.value.ceilingpic)
      file.write_bytes(sec.value.lightlevel)
      file.write_bytes(sec.value.special) # needed?
      file.write_bytes(sec.value.tag)     # needed?

      sec += 1
    end

    li = CDoom.lines
    # do lines
    CDoom.numlines.times do |i|
      file.write_bytes(li.value.flags)
      file.write_bytes(li.value.special)
      file.write_bytes(li.value.tag)
      2.times do |j|
        next if li.value.sidenum[j] == -1

        si = CDoom.sides + li.value.sidenum[j]

        file.write_bytes((si.value.textureoffset >> FRACBITS).to_i16!)
        file.write_bytes((si.value.rowoffset >> FRACBITS).to_i16!)
        file.write_bytes(si.value.toptexture)
        file.write_bytes(si.value.bottomtexture)
        file.write_bytes(si.value.midtexture)
      end
      li += 1
    end
  end

  def self.p_unarchive_world(file : IO)
    sec = CDoom.sectors
    # do sectors
    CDoom.numsectors.times do |i|
      sec.value.floorheight = file.read_bytes(Int16).to_i32 << FRACBITS
      sec.value.ceilingheight = file.read_bytes(Int16).to_i32 << FRACBITS
      sec.value.floorpic = file.read_bytes(Int16)
      sec.value.ceilingpic = file.read_bytes(Int16)
      sec.value.lightlevel = file.read_bytes(Int16)
      sec.value.special = file.read_bytes(Int16) # needed?
      sec.value.tag = file.read_bytes(Int16)     # needed?
      sec.value.specialdata = Pointer(Void).null
      sec.value.soundtarget = Pointer(CDoom::Mobj).null

      sec += 1
    end

    li = CDoom.lines
    # do lines
    CDoom.numlines.times do |i|
      li.value.flags = file.read_bytes(Int16)
      li.value.special = file.read_bytes(Int16)
      li.value.tag = file.read_bytes(Int16)
      2.times do |j|
        next if li.value.sidenum[j] == -1
        si = CDoom.sides + li.value.sidenum[j]
        si.value.textureoffset = file.read_bytes(Int16).to_i32 << FRACBITS
        si.value.rowoffset = file.read_bytes(Int16).to_i32 << FRACBITS
        si.value.toptexture = file.read_bytes(Int16)
        si.value.bottomtexture = file.read_bytes(Int16)
        si.value.midtexture = file.read_bytes(Int16)
      end

      li += 1
    end
  end

  def self.p_archive_thinkers(file : IO)
    # save off the current thinkers
    th = CDoom.thinkercap.next
    while th != pointerof(CDoom.thinkercap)
      if th.value.function.acp1.pointer == (->CDoom.p_mobj_thinker).pointer
        file.write_byte(CDoom::Thinkerclass::Mobj.value)
        mobj = th.as(CDoom::Mobj*).value
        mobj.state = Pointer(CDoom::State).new((mobj.state - CDoom.states).to_u64!)

        mobj.player = Pointer(CDoom::Player).new(((mobj.player - CDoom.players.to_unsafe) + 1).to_u64!) if !mobj.player.null?

        file.write(pointerof(mobj).as(UInt8*).to_slice(sizeof(CDoom::Mobj)))
      end

      th = th.value.next
    end

    # add a terminating marker
    file.write_byte(CDoom::Thinkerclass::End.value)
  end

  def self.p_unarchive_thinkers(file : IO)
    # remove all the current thinkers
    currentthinker = CDoom.thinkercap.next
    while currentthinker != pointerof(CDoom.thinkercap)
      nextt = currentthinker.value.next

      if currentthinker.value.function.acp1.pointer == (->CDoom.p_mobj_thinker).pointer
        CDoom.p_remove_mobj(currentthinker.as(CDoom::Mobj*))
      else
        CDoom.z_free(currentthinker)
      end
      currentthinker = nextt
    end
    CDoom.p_init_thinkers

    # read in saved thinkers
    loop do
      tclass = CDoom::Thinkerclass.new(file.read_bytes(UInt8))
      case tclass
      when CDoom::Thinkerclass::End
        return # end of list
      when CDoom::Thinkerclass::Mobj
        mobj = CDoom.z_malloc(sizeof(CDoom::Mobj), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Mobj*)
        mjslice = Slice.new(mobj.as(UInt8*), sizeof(CDoom::Mobj))
        file.read_fully(mjslice)
        mobj.value.state = CDoom.states + mobj.value.state.address
        mobj.value.target = Pointer(CDoom::Mobj).null
        if !mobj.value.player.null?
          mobj.value.player = CDoom.players.to_unsafe + (mobj.value.player.address - 1)
          mobj.value.player.value.mo = mobj
        end
        CDoom.p_set_thing_position(mobj)
        mobj.value.info = CDoom.mobjinfo + mobj.value.type.value
        mobj.value.floorz = mobj.value.subsector.value.sector.value.floorheight
        mobj.value.ceilingz = mobj.value.subsector.value.sector.value.ceilingheight
        pointerof(mobj.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.p_mobj_thinker).pointer, Pointer(Void).null)
        CDoom.p_add_thinker(pointerof(mobj.value.@thinker))
      else
        CDoom.i_error("Error: Unknown tclass #{tclass} in savegame")
      end
    end
  end

  #
  # Things to handle:
  #
  # T_MoveCeiling, (ceiling_t: sector_t * swizzle), - active list
  # T_VerticalDoor, (vldoor_t: sector_t * swizzle),
  # T_MoveFloor, (floormove_t: sector_t * swizzle),
  # T_LightFlash, (lightflash_t: sector_t * swizzle),
  # T_StrobeFlash, (strobe_t: sector_t *),
  # T_Glow, (glow_t: sector_t *),
  # T_PlatRaise, (plat_t: sector_t *), - active list
  #
  def self.p_archive_specials(file : IO)
    # save off the current thinkers
    th = CDoom.thinkercap.next
    while th != pointerof(CDoom.thinkercap)
      if th.value.function.acv.pointer.null?
        i = 0
        while i < CDoom::MAXCEILINGS
          break if CDoom.activeceilings[i] == th.as(CDoom::Ceiling*)
          i += 1
        end

        if i < CDoom::MAXCEILINGS
          file.write_byte(CDoom::Specials::Ceiling.value)
          ceiling = th.as(CDoom::Ceiling*).value
          ceiling.sector = Pointer(CDoom::Sector).new((ceiling.sector - CDoom.sectors).to_u64!)
          file.write(pointerof(ceiling).as(UInt8*).to_slice(sizeof(CDoom::Ceiling)))
        end
        th = th.value.next
        next
      end

      if th.value.function.acp1.pointer == (->CDoom.t_move_ceiling).pointer
        file.write_byte(CDoom::Specials::Ceiling.value)
        ceiling = th.as(CDoom::Ceiling*).value
        ceiling.sector = Pointer(CDoom::Sector).new((ceiling.sector - CDoom.sectors).to_u64!)
        th = th.value.next
        file.write(pointerof(ceiling).as(UInt8*).to_slice(sizeof(CDoom::Ceiling)))
        next
      end

      if th.value.function.acp1.pointer == (->CDoom.t_vertical_door).pointer
        file.write_byte(CDoom::Specials::Door.value)
        door = th.as(CDoom::Vldoor*).value
        door.sector = Pointer(CDoom::Sector).new((door.sector - CDoom.sectors).to_u64!)
        th = th.value.next
        file.write(pointerof(door).as(UInt8*).to_slice(sizeof(CDoom::Vldoor)))
        next
      end

      if th.value.function.acp1.pointer == (->CDoom.t_move_floor).pointer
        file.write_byte(CDoom::Specials::Floor.value)
        floor = th.as(CDoom::Floormove*).value
        floor.sector = Pointer(CDoom::Sector).new((floor.sector - CDoom.sectors).to_u64!)
        th = th.value.next
        file.write(pointerof(floor).as(UInt8*).to_slice(sizeof(CDoom::Floormove)))

        next
      end

      if th.value.function.acp1.pointer == (->CDoom.t_plat_raise).pointer
        file.write_byte(CDoom::Specials::Plat.value)
        plat = th.as(CDoom::Plat*).value
        plat.sector = Pointer(CDoom::Sector).new((plat.sector - CDoom.sectors).to_u64!)
        th = th.value.next
        file.write(pointerof(plat).as(UInt8*).to_slice(sizeof(CDoom::Plat)))
        next
      end

      if th.value.function.acp1.pointer == (->CDoom.t_light_flash).pointer
        file.write_byte(CDoom::Specials::Flash.value)
        flash = th.as(CDoom::Lightflash*).value
        flash.sector = Pointer(CDoom::Sector).new((flash.sector - CDoom.sectors).to_u64!)
        th = th.value.next
        file.write(pointerof(flash).as(UInt8*).to_slice(sizeof(CDoom::Lightflash)))
        next
      end

      if th.value.function.acp1.pointer == (->CDoom.t_strobe_flash).pointer
        file.write_byte(CDoom::Specials::Strobe.value)
        strobe = th.as(CDoom::Strobe*).value
        strobe.sector = Pointer(CDoom::Sector).new((strobe.sector - CDoom.sectors).to_u64!)
        th = th.value.next
        file.write(pointerof(strobe).as(UInt8*).to_slice(sizeof(CDoom::Strobe)))

        next
      end

      if th.value.function.acp1.pointer == (->CDoom.t_glow).pointer
        file.write_byte(CDoom::Specials::Glow.value)
        glow = th.as(CDoom::Glow*).value
        glow.sector = Pointer(CDoom::Sector).new((glow.sector - CDoom.sectors).to_u64!)
        th = th.value.next
        file.write(pointerof(glow).as(UInt8*).to_slice(sizeof(CDoom::Glow)))
        next
      end

      th = th.value.next
    end

    # add a terminating marker
    file.write_byte(CDoom::Specials::End.value)
  end

  def self.p_unarchive_specials(file : IO)
    # read in saved thinkers
    loop do
      tclass = CDoom::Specials.new(file.read_bytes(UInt8))
      case tclass
      when CDoom::Specials::End
        return # end of list
      when CDoom::Specials::Ceiling
        ceiling = CDoom.z_malloc(sizeof(CDoom::Ceiling), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Ceiling*)
        slice = Slice.new(ceiling.as(UInt8*), sizeof(CDoom::Ceiling))
        file.read_fully(slice)

        ceiling.value.sector = CDoom.sectors + ceiling.value.sector.address

        ceiling.value.sector.value.specialdata = ceiling

        if !ceiling.value.thinker.function.acp1.pointer.null?
          pointerof(ceiling.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_move_ceiling).pointer, Pointer(Void).null)
        end

        CDoom.p_add_thinker(pointerof(ceiling.value.@thinker))
        CDoom.p_add_active_ceiling(ceiling)
      when CDoom::Specials::Door
        door = CDoom.z_malloc(sizeof(CDoom::Vldoor), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Vldoor*)
        slice = Slice.new(door.as(UInt8*), sizeof(CDoom::Vldoor))
        file.read_fully(slice)
        door.value.sector = CDoom.sectors + door.value.sector.address
        door.value.sector.value.specialdata = door
        pointerof(door.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_vertical_door).pointer, Pointer(Void).null)

        CDoom.p_add_thinker(pointerof(door.value.@thinker))
      when CDoom::Specials::Floor
        floor = CDoom.z_malloc(sizeof(CDoom::Floormove), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Floormove*)
        slice = Slice.new(floor.as(UInt8*), sizeof(CDoom::Floormove))
        file.read_fully(slice)
        floor.value.sector = CDoom.sectors + floor.value.sector.address
        floor.value.sector.value.specialdata = floor
        pointerof(floor.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_move_floor).pointer, Pointer(Void).null)

        CDoom.p_add_thinker(pointerof(floor.value.@thinker))
      when CDoom::Specials::Plat
        plat = CDoom.z_malloc(sizeof(CDoom::Plat), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Plat*)
        slice = Slice.new(plat.as(UInt8*), sizeof(CDoom::Plat))
        file.read_fully(slice)
        plat.value.sector = CDoom.sectors + plat.value.sector.address
        plat.value.sector.value.specialdata = plat
        if !plat.value.thinker.function.acp1.pointer.null?
          pointerof(plat.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_plat_raise).pointer, Pointer(Void).null)
        end

        CDoom.p_add_thinker(pointerof(plat.value.@thinker))
        CDoom.p_add_active_plat(plat)
      when CDoom::Specials::Flash
        flash = CDoom.z_malloc(sizeof(CDoom::Lightflash), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Lightflash*)
        slice = Slice.new(flash.as(UInt8*), sizeof(CDoom::Lightflash))
        file.read_fully(slice)
        flash.value.sector = CDoom.sectors + flash.value.sector.address
        pointerof(flash.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_light_flash).pointer, Pointer(Void).null)

        CDoom.p_add_thinker(pointerof(flash.value.@thinker))
      when CDoom::Specials::Strobe
        strobe = CDoom.z_malloc(sizeof(CDoom::Strobe), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Strobe*)
        slice = Slice.new(strobe.as(UInt8*), sizeof(CDoom::Strobe))
        file.read_fully(slice)
        strobe.value.sector = CDoom.sectors + strobe.value.sector.address
        pointerof(strobe.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_strobe_flash).pointer, Pointer(Void).null)

        CDoom.p_add_thinker(pointerof(strobe.value.@thinker))
      when CDoom::Specials::Glow
        glow = CDoom.z_malloc(sizeof(CDoom::Glow), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Glow*)
        slice = Slice.new(glow.as(UInt8*), sizeof(CDoom::Glow))
        file.read_fully(slice)
        glow.value.sector = CDoom.sectors + glow.value.sector.address
        pointerof(glow.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_glow).pointer, Pointer(Void).null)

        CDoom.p_add_thinker(pointerof(glow.value.@thinker))
      else
        CDoom.i_error("Error: p_unarchive_specials: Unknown tclass #{tclass} in savegame")
      end
    end
  end

  def self.p_load_vertexes(lump : LibC::Int)
    # Determine number of lumps:
    #  total lump length / vertex record length.
    CDoom.numvertexes = CDoom.w_lump_length(lump) // sizeof(CDoom::Mapvertex)

    # Allocate zone memory for buffer.
    CDoom.vertexes = CDoom.z_malloc(CDoom.numvertexes * sizeof(CDoom::Vertex), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Vertex*)

    # Load data into cache.
    data = CDoom.w_cache_lump_num(lump, CDoom::PU_STATIC).as(CDoom::Byte*)

    ml = data.as(CDoom::Mapvertex*)
    li = CDoom.vertexes

    # Copy and convert vertex coordinates,
    # internal representation as fixed.
    CDoom.numvertexes.times do |i|
      li.value.x = ml.value.x.to_i32 << FRACBITS
      li.value.y = ml.value.y.to_i32 << FRACBITS

      li += 1
      ml += 1
    end

    # Free buffer memory.
    CDoom.z_free(data)
  end

  def self.p_load_segs(lump : LibC::Int)
    CDoom.numsegs = CDoom.w_lump_length(lump) // sizeof(CDoom::Mapseg)
    CDoom.segs = CDoom.z_malloc(CDoom.numsegs * sizeof(CDoom::Seg), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Seg*)
    CDoom.doom_memset(CDoom.segs, 0, CDoom.numsegs * sizeof(CDoom::Seg))
    data = CDoom.w_cache_lump_num(lump, CDoom::PU_STATIC).as(CDoom::Byte*)

    ml = data.as(CDoom::Mapseg*)
    li = CDoom.segs
    CDoom.numsegs.times do |i|
      li.value.v1 = CDoom.vertexes + ml.value.v1
      li.value.v2 = CDoom.vertexes + ml.value.v2

      li.value.angle = ml.value.angle.to_i32 << 16
      li.value.offset = ml.value.offset.to_i32 << 16
      linedef = ml.value.linedef
      ldef = CDoom.lines + linedef
      li.value.linedef = ldef
      side = ml.value.side
      li.value.sidedef = CDoom.sides + ldef.value.sidenum[side]
      li.value.frontsector = CDoom.sides[ldef.value.sidenum[side]].sector
      if ldef.value.flags & CDoom::ML_TWOSIDED != 0
        li.value.backsector = CDoom.sides[ldef.value.sidenum[side ^ 1]].sector
      else
        li.value.backsector = Pointer(CDoom::Sector).null
      end

      li += 1
      ml += 1
    end

    CDoom.z_free(data)
  end

  def self.p_load_subsectors(lump : LibC::Int)
    CDoom.numsubsectors = CDoom.w_lump_length(lump) // sizeof(CDoom::Mapsubsector)
    CDoom.subsectors = CDoom.z_malloc(CDoom.numsubsectors * sizeof(CDoom::Subsector), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Subsector*)
    data = CDoom.w_cache_lump_num(lump, CDoom::PU_STATIC).as(CDoom::Byte*)

    ms = data.as(CDoom::Mapsubsector*)
    CDoom.doom_memset(CDoom.subsectors, 0, CDoom.numsubsectors * sizeof(CDoom::Subsector))
    ss = CDoom.subsectors

    CDoom.numsubsectors.times do |i|
      ss.value.numlines = ms.value.numsegs
      ss.value.firstline = ms.value.firstseg

      ss += 1
      ms += 1
    end

    CDoom.z_free(data)
  end

  def self.p_load_sectors(lump : LibC::Int)
    CDoom.numsectors = CDoom.w_lump_length(lump) // sizeof(CDoom::Mapsector)
    CDoom.sectors = CDoom.z_malloc(CDoom.numsectors * sizeof(CDoom::Sector), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Sector*)
    CDoom.doom_memset(CDoom.sectors, 0, CDoom.numsectors * sizeof(CDoom::Sector))
    data = CDoom.w_cache_lump_num(lump, CDoom::PU_STATIC).as(CDoom::Byte*)

    ms = data.as(CDoom::Mapsector*)
    ss = CDoom.sectors

    CDoom.numsectors.times do |i|
      ss.value.floorheight = ms.value.floorheight.to_i32 << FRACBITS
      ss.value.ceilingheight = ms.value.ceilingheight.to_i32 << FRACBITS
      ss.value.floorpic = CDoom.r_flat_num_for_name(ms.value.floorpic)
      ss.value.ceilingpic = CDoom.r_flat_num_for_name(ms.value.ceilingpic)
      ss.value.lightlevel = ms.value.lightlevel
      ss.value.special = ms.value.special
      ss.value.tag = ms.value.tag
      ss.value.thinglist = Pointer(CDoom::Mobj).null

      ss += 1
      ms += 1
    end

    CDoom.z_free(data)
  end

  def self.p_load_nodes(lump : LibC::Int)
    CDoom.numnodes = CDoom.w_lump_length(lump) // sizeof(CDoom::Mapnode)
    CDoom.nodes = CDoom.z_malloc(CDoom.numnodes * sizeof(CDoom::Node), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Node*)
    data = CDoom.w_cache_lump_num(lump, CDoom::PU_STATIC).as(CDoom::Byte*)

    mn = data.as(CDoom::Mapnode*)
    no = CDoom.nodes

    CDoom.numnodes.times do |i|
      no.value.x = mn.value.x.to_i32 << FRACBITS
      no.value.y = mn.value.y.to_i32 << FRACBITS
      no.value.dx = mn.value.dx.to_i32 << FRACBITS
      no.value.dy = mn.value.dy.to_i32 << FRACBITS

      2.times do |j|
        no.value.children[j] = mn.value.children[j]
        4.times do |k|
          ((no.value.bbox.to_unsafe + j).value.to_unsafe + k).value = mn.value.bbox[j][k].to_i32 << FRACBITS
        end
      end

      no += 1
      mn += 1
    end

    CDoom.z_free(data)
  end

  def self.p_load_things(lump : LibC::Int)
    data = CDoom.w_cache_lump_num(lump, CDoom::PU_STATIC).as(CDoom::Byte*)
    numthings = CDoom.w_lump_length(lump) // sizeof(CDoom::Mapthing)

    mt = data.as(CDoom::Mapthing*)

    numthings.times do |i|
      spawnt = true

      # Do not spawn cool, new monsters if !commercial
      if CDoom.gamemode != CDoom::GameMode::Commercial
        case mt.value.type
        when 68, # Arachnotron
             64, # Archvile
             88, # Boss Brain
             89, # Boss Shooter
             69, # Hell Knight
             67, # Mancubus
             71, # Pain Elemental
             65, # Former Human Commando
             66, # Revenant
             84  # Wolf SS
          spawnt = false
        end
      end

      if spawnt == false
        mt += 1
        next
      end

      # Do spawn all other stuff.
      # [ds] Pointless?
      mt.value.x = mt.value.x
      mt.value.x = mt.value.x
      mt.value.angle = mt.value.angle
      mt.value.type = mt.value.type
      mt.value.options = mt.value.options

      CDoom.p_spawn_map_thing(mt)
      mt += 1
    end

    CDoom.z_free(data)
  end

  #
  # Also counts secret lines for intermissions.
  #
  def self.p_load_linedefs(lump : LibC::Int)
    CDoom.numlines = CDoom.w_lump_length(lump) // sizeof(CDoom::Maplinedef)
    CDoom.lines = CDoom.z_malloc(CDoom.numlines * sizeof(CDoom::Line), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Line*)
    CDoom.doom_memset(CDoom.lines, 0, CDoom.numlines * sizeof(CDoom::Line))
    data = CDoom.w_cache_lump_num(lump, CDoom::PU_STATIC).as(CDoom::Byte*)

    mld = data.as(CDoom::Maplinedef*)
    ld = CDoom.lines

    CDoom.numlines.times do |i|
      ld.value.flags = mld.value.flags
      ld.value.special = mld.value.special
      ld.value.tag = mld.value.tag
      v1 = CDoom.vertexes + mld.value.v1
      ld.value.v1 = v1
      v2 = CDoom.vertexes + mld.value.v2
      ld.value.v2 = v2
      ld.value.dx = v2.value.x - v1.value.x
      ld.value.dy = v2.value.y - v1.value.y

      if ld.value.dx == 0
        ld.value.slopetype = CDoom::Slopetype::VERTICAL
      elsif ld.value.dy == 0
        ld.value.slopetype = CDoom::Slopetype::HORIZONTAL
      else
        if CDoom.fixed_div(ld.value.dy, ld.value.dx) > 0
          ld.value.slopetype = CDoom::Slopetype::POSITIVE
        else
          ld.value.slopetype = CDoom::Slopetype::NEGATIVE
        end
      end

      if v1.value.x < v2.value.x
        ld.value.bbox[CDoom::BOXLEFT] = v1.value.x
        ld.value.bbox[CDoom::BOXRIGHT] = v2.value.x
      else
        ld.value.bbox[CDoom::BOXLEFT] = v2.value.x
        ld.value.bbox[CDoom::BOXRIGHT] = v1.value.x
      end

      if v1.value.y < v2.value.y
        ld.value.bbox[CDoom::BOXBOTTOM] = v1.value.y
        ld.value.bbox[CDoom::BOXTOP] = v2.value.y
      else
        ld.value.bbox[CDoom::BOXBOTTOM] = v2.value.y
        ld.value.bbox[CDoom::BOXTOP] = v1.value.y
      end

      ld.value.sidenum[0] = mld.value.sidenum[0]
      ld.value.sidenum[1] = mld.value.sidenum[1]

      if ld.value.sidenum[0] != -1
        ld.value.frontsector = CDoom.sides[ld.value.sidenum[0]].sector
      else
        ld.value.frontsector = Pointer(CDoom::Sector).null
      end

      if ld.value.sidenum[1] != -1
        ld.value.backsector = CDoom.sides[ld.value.sidenum[1]].sector
      else
        ld.value.backsector = Pointer(CDoom::Sector).null
      end

      mld += 1
      ld += 1
    end

    CDoom.z_free(data)
  end

  def self.p_load_sidedefs(lump : LibC::Int)
    CDoom.numsides = CDoom.w_lump_length(lump) // sizeof(CDoom::Mapsidedef)
    CDoom.sides = CDoom.z_malloc(CDoom.numsides * sizeof(CDoom::Side), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Side*)
    CDoom.doom_memset(CDoom.sides, 0, CDoom.numsides * sizeof(CDoom::Side))
    data = CDoom.w_cache_lump_num(lump, CDoom::PU_STATIC).as(CDoom::Byte*)

    msd = data.as(CDoom::Mapsidedef*)
    sd = CDoom.sides

    CDoom.numsides.times do |i|
      sd.value.textureoffset = msd.value.textureoffset.to_i32 << FRACBITS
      sd.value.rowoffset = msd.value.rowoffset.to_i32 << FRACBITS
      sd.value.toptexture = CDoom.r_texture_num_for_name(msd.value.toptexture)
      sd.value.bottomtexture = CDoom.r_texture_num_for_name(msd.value.bottomtexture)
      sd.value.midtexture = CDoom.r_texture_num_for_name(msd.value.midtexture)
      sd.value.sector = CDoom.sectors + msd.value.sector

      msd += 1
      sd += 1
    end

    CDoom.z_free(data)
  end

  def self.p_load_blockmap(lump : LibC::Int)
    CDoom.blockmaplump = CDoom.w_cache_lump_num(lump, CDoom::PU_STATIC).as(Int16*)
    CDoom.blockmap = CDoom.blockmaplump + 4
    count = CDoom.w_lump_length(lump) // 2

    count.times do |i|
      CDoom.blockmaplump[i] = CDoom.blockmaplump[i] # [ds] pointless?
    end

    CDoom.bmaporgx = CDoom.blockmaplump[0].to_i32 << FRACBITS
    CDoom.bmaporgy = CDoom.blockmaplump[1].to_i32 << FRACBITS
    CDoom.bmapwidth = CDoom.blockmaplump[2]
    CDoom.bmapheight = CDoom.blockmaplump[3]

    # clear out mobj chains
    count = sizeof(CDoom::Mobj*) * CDoom.bmapwidth * CDoom.bmapheight
    CDoom.blocklinks = CDoom.z_malloc(count, CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Mobj**)
    CDoom.doom_memset(CDoom.blocklinks, 0, count)
  end

  #
  # Builds sector line lists and subsector sector numbers.
  # Finds block bounding boxes for sectors.
  #
  def self.p_group_lines
    # look up sector number for each subsector
    ss = CDoom.subsectors
    CDoom.numsubsectors.times do |i|
      seg = CDoom.segs + ss.value.firstline
      ss.value.sector = seg.value.sidedef.value.sector

      ss += 1
    end

    # count number of lines in each sector
    li = CDoom.lines
    total = 0
    CDoom.numlines.times do |i|
      total += 1
      li.value.frontsector.value.linecount = li.value.frontsector.value.linecount + 1

      if !li.value.backsector.null? && li.value.backsector != li.value.frontsector
        li.value.backsector.value.linecount = li.value.backsector.value.linecount + 1
        total += 1
      end

      li += 1
    end

    # build line tables for each sector
    linebuffer = CDoom.z_malloc(total * sizeof(CDoom::Line*), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Line**)
    sector = CDoom.sectors
    bbox = Pointer(CDoom::Fixed).malloc(4)
    CDoom.numsectors.times do |i|
      CDoom.m_clear_box(bbox)
      sector.value.lines = linebuffer
      li = CDoom.lines
      CDoom.numlines.times do |j|
        if li.value.frontsector == sector || li.value.backsector == sector
          linebuffer.value = li
          linebuffer += 1
          CDoom.m_add_to_box(bbox, li.value.v1.value.x, li.value.v1.value.y)
          CDoom.m_add_to_box(bbox, li.value.v2.value.x, li.value.v2.value.y)
        end

        li += 1
      end
      if (linebuffer - sector.value.lines) != sector.value.linecount
        CDoom.i_error("Error: p_group_lines: miscounted")
      end

      # set the degenmobj_t to the middle of the bounding box
      soundorg = pointerof(sector.value.@soundorg)
      soundorg.value.x = (bbox[CDoom::BOXRIGHT] &+ bbox[CDoom::BOXLEFT]) // 2
      soundorg.value.y = (bbox[CDoom::BOXTOP] &+ bbox[CDoom::BOXBOTTOM]) // 2

      # adjust bounding box to map blocks
      block = (bbox[CDoom::BOXTOP] &- CDoom.bmaporgy + CDoom::MAXRADIUS) >> CDoom::MAPBLOCKSHIFT
      block = block >= CDoom.bmapheight ? CDoom.bmapheight - 1 : block
      sector.value.blockbox[CDoom::BOXTOP] = block

      block = (bbox[CDoom::BOXBOTTOM] &- CDoom.bmaporgy - CDoom::MAXRADIUS) >> CDoom::MAPBLOCKSHIFT
      block = block < 0 ? 0 : block
      sector.value.blockbox[CDoom::BOXBOTTOM] = block

      block = (bbox[CDoom::BOXRIGHT] &- CDoom.bmaporgx + CDoom::MAXRADIUS) >> CDoom::MAPBLOCKSHIFT
      block = block >= CDoom.bmapwidth ? CDoom.bmapwidth - 1 : block
      sector.value.blockbox[CDoom::BOXRIGHT] = block

      block = (bbox[CDoom::BOXLEFT] &- CDoom.bmaporgx - CDoom::MAXRADIUS) >> CDoom::MAPBLOCKSHIFT
      block = block < 0 ? 0 : block
      sector.value.blockbox[CDoom::BOXLEFT] = block

      sector += 1
    end
  end

  def self.p_setup_level(episode : LibC::Int, map : LibC::Int, playermask : LibC::Int, skill : CDoom::Skill)
    lumpname = Pointer(UInt8).malloc(9)

    CDoom.totalkills = 0
    CDoom.totalitems = 0
    CDoom.totalsecret = 0
    CDoom.wminfo.maxfrags = 0
    CDoom.wminfo.partime = 180
    CDoom::MAXPLAYERS.times do |i|
      (CDoom.players.to_unsafe + i).value.killcount = 0
      (CDoom.players.to_unsafe + i).value.secretcount = 0
      (CDoom.players.to_unsafe + i).value.itemcount = 0
    end

    # Initial height of PointOfView
    # will be set by player think.
    (CDoom.players.to_unsafe + CDoom.consoleplayer).value.viewz = 1

    # Make sure all sounds are stopped before Z_FreeTags.
    CDoom.s_start

    CDoom.z_free_tags(CDoom::PU_LEVEL, CDoom::PU_PURGELEVEL - 1)

    CDoom.p_init_thinkers

    # if working with a devlopment map, reload it
    CDoom.w_reload

    # find map name
    if CDoom.gamemode == CDoom::GameMode::Commercial
      if map < 10
        CDoom.doom_strcpy(lumpname, "map0")
        CDoom.doom_concat(lumpname, CDoom.doom_itoa(map, 10))
      else
        CDoom.doom_strcpy(lumpname, "map")
        CDoom.doom_concat(lumpname, CDoom.doom_itoa(map, 10))
      end
    else
      lumpname[0] = 'E'.ord.to_u8
      lumpname[1] = '0'.ord.to_u8 + episode
      lumpname[2] = 'M'.ord.to_u8
      lumpname[3] = '0'.ord.to_u8 + map
      lumpname[4] = 0
    end

    lumpnum = CDoom.w_get_num_for_name(lumpname)

    CDoom.leveltime = 0

    # note: most of this ordering is important
    CDoom.p_load_blockmap(lumpnum + CDoom::ML_BLOCKMAP)
    CDoom.p_load_vertexes(lumpnum + CDoom::ML_VERTEXES)
    CDoom.p_load_sectors(lumpnum + CDoom::ML_SECTORS)
    CDoom.p_load_sidedefs(lumpnum + CDoom::ML_SIDEDEFS)

    CDoom.p_load_linedefs(lumpnum + CDoom::ML_LINEDEFS)
    CDoom.p_load_subsectors(lumpnum + CDoom::ML_SSECTORS)
    CDoom.p_load_nodes(lumpnum + CDoom::ML_NODES)
    CDoom.p_load_segs(lumpnum + CDoom::ML_SEGS)

    CDoom.rejectmatrix = CDoom.w_cache_lump_num(lumpnum + CDoom::ML_REJECT, CDoom::PU_LEVEL).as(UInt8*)
    CDoom.p_group_lines

    CDoom.bodyqueslot = 0
    CDoom.deathmatch_p = CDoom.deathmatchstarts.to_unsafe
    CDoom.p_load_things(lumpnum + CDoom::ML_THINGS)

    # if deathmatch, randomly spawn the active players
    if CDoom.deathmatch != 0
      CDoom::MAXPLAYERS.times do |i|
        if CDoom.playeringame[i] != 0
          (CDoom.players.to_unsafe + i).value.mo = Pointer(CDoom::Mobj).null
          CDoom.g_deathmatch_spawn_player(i)
        end
      end
    end

    # clear special respawning que
    CDoom.iquehead = 0
    CDoom.iquetail = 0

    # set up world state
    CDoom.p_spawn_specials

    # preload graphics
    CDoom.r_precache_level if CDoom.precache != 0
  end

  def self.p_init
    CDoom.p_init_switch_list
    CDoom.p_init_pic_anims
    CDoom.r_init_sprites(CDoom.sprnames)
  end

  #
  # Returns side 0 (front), 1 (back), or 2 (on).
  #
  def self.p_divline_side(x : CDoom::Fixed, y : CDoom::Fixed, node : CDoom::Divline*) : LibC::Int
    if node.value.dx == 0
      return 2 if x == node.value.x

      return (node.value.dy > 0).to_unsafe if x <= node.value.x

      return (node.value.dy < 0).to_unsafe
    end

    if node.value.dy == 0
      return 2 if x == node.value.y

      return (node.value.dx < 0).to_unsafe if y <= node.value.y

      return (node.value.dx > 0).to_unsafe
    end

    dx = x - node.value.x
    dy = y - node.value.y

    left = (node.value.dy >> FRACBITS) * (dx >> FRACBITS)
    right = (dy >> FRACBITS) * (node.value.dx >> FRACBITS)

    return 0 if right < left # front side

    return 2 if left == right
    return 1 # back side
  end

  #
  # Returns the fractional intercept point
  # along the first divline.
  # This is only called by the addthings and addlines traversers.
  #
  def self.p_intercept_vector2(v2 : CDoom::Divline*, v1 : CDoom::Divline*) : CDoom::Fixed
    den = CDoom.fixed_mul(v1.value.dy >> 8, v2.value.dx) - CDoom.fixed_mul(v1.value.dx >> 8, v2.value.dy)

    return 0 if den == 0

    num = CDoom.fixed_mul((v1.value.x - v2.value.x) >> 8, v1.value.dy) +
          CDoom.fixed_mul((v2.value.y - v1.value.y) >> 8, v1.value.dx)
    frac = CDoom.fixed_div(num, den)

    return frac
  end

  #
  # Returns true
  #  if strace crosses the given subsector successfully.
  #
  def self.p_cross_subsector(num : LibC::Int) : CDoom::DoomBool
    {% if flag?("RANGECHECK") %}
      if num >= CDoom.numsubsectors
        CDoom.i_error("Error: p_cross_subsector: ss #{num} with numss = #{CDoom.numsubsectors}")
      end
    {% end %}

    sub = CDoom.subsectors + num

    # check lines
    count = sub.value.numlines
    seg = CDoom.segs + sub.value.firstline

    divl = CDoom::Divline.new

    while count != 0
      line = seg.value.linedef

      # allready checked other size?
      if line.value.validcount == CDoom.validcount
        seg += 1
        count -= 1
        next
      end

      line.value.validcount = CDoom.validcount

      v1 = line.value.v1
      v2 = line.value.v2
      s1 = CDoom.p_divline_side(v1.value.x, v1.value.y, pointerof(CDoom.strace))
      s2 = CDoom.p_divline_side(v2.value.x, v2.value.y, pointerof(CDoom.strace))

      # line isn't crossed?
      if s1 == s2
        seg += 1
        count -= 1
        next
      end

      divl.x = v1.value.x
      divl.y = v1.value.y
      divl.dx = v2.value.x - v1.value.x
      divl.dy = v2.value.y - v1.value.y
      s1 = CDoom.p_divline_side(CDoom.strace.x, CDoom.strace.y, pointerof(divl))
      s2 = CDoom.p_divline_side(CDoom.t2x, CDoom.t2y, pointerof(divl))

      # line isn't crossed?
      if s1 == s2
        seg += 1
        count -= 1
        next
      end

      # stop because it is not two sided anyway
      # might do this after updating validcount?
      return 0 if line.value.flags & CDoom::ML_TWOSIDED == 0

      # crosses a two sided line
      front = seg.value.frontsector
      back = seg.value.backsector

      # no wall to block sight with?
      if front.value.floorheight == back.value.floorheight &&
         front.value.ceilingheight == back.value.ceilingheight
        seg += 1
        count -= 1
        next
      end

      # possible occluder
      # because of ceiling height differences
      if front.value.ceilingheight < back.value.ceilingheight
        opentop = front.value.ceilingheight
      else
        opentop = back.value.ceilingheight
      end

      # because of ceiling height differences
      if front.value.floorheight > back.value.floorheight
        openbottom = front.value.floorheight
      else
        openbottom = back.value.floorheight
      end

      # quick test for totally closed doors
      return 0 if openbottom >= opentop # stop

      frac = CDoom.p_intercept_vector2(pointerof(CDoom.strace), pointerof(divl))

      if front.value.floorheight != back.value.floorheight
        slope = CDoom.fixed_div(openbottom - CDoom.sightzstart, frac)
        CDoom.bottomslope = slope if slope > CDoom.bottomslope
      end

      if front.value.ceilingheight != back.value.ceilingheight
        slope = CDoom.fixed_div(opentop - CDoom.sightzstart, frac)
        CDoom.topslope = slope if slope < CDoom.topslope
      end

      return 0 if CDoom.topslope <= CDoom.bottomslope # stop

      seg += 1
      count -= 1
    end

    # passed the subsector ok
    return 1
  end

  #
  # Returns true
  #  if strace crosses the given node successfully.
  #
  def self.p_cross_bsp_node(bspnum : LibC::Int) : CDoom::DoomBool
    if bspnum & CDoom::NF_SUBSECTOR != 0
      if bspnum == -1
        return CDoom.p_cross_subsector(0)
      else
        return CDoom.p_cross_subsector(bspnum & (~CDoom::NF_SUBSECTOR))
      end
    end

    bsp = CDoom.nodes + bspnum

    # decide which side the start point is on
    side = CDoom.p_divline_side(CDoom.strace.x, CDoom.strace.y, bsp.as(CDoom::Divline*))
    side = 0 if side == 2 # an "on" should cross both sides

    # cross the starting side
    return 0 if CDoom.p_cross_bsp_node(bsp.value.children[side]) == 0

    # the partition plane is crossed here
    if side == CDoom.p_divline_side(CDoom.t2x, CDoom.t2y, bsp.as(CDoom::Divline*))
      # the line doesn't touch the other side
      return 1
    end

    # cross the ending side
    return CDoom.p_cross_bsp_node(bsp.value.children[side ^ 1])
  end

  #
  # Returns true
  #  if a straight line between t1 and t2 is unobstructed.
  # Uses REJECT.
  #
  def self.p_check_sight(t1 : CDoom::Mobj*, t2 : CDoom::Mobj*) : CDoom::DoomBool
    # First check for trivial rejection.

    # Determine subsector entries in REJECT table.
    s1 = t1.value.subsector.value.sector - CDoom.sectors
    s2 = t2.value.subsector.value.sector - CDoom.sectors
    pnum = s1 * CDoom.numsectors + s2
    bytenum = pnum >> 3
    bitnum = 1 << (pnum & 7)

    # Check in REJECT table.
    if CDoom.rejectmatrix[bytenum] & bitnum != 0
      CDoom.sightcounts[0] = CDoom.sightcounts[0] + 1

      # can't possibly be connected
      return 0
    end

    # An unobstructed LOS is possible.
    # Now look from eyes of t1 to any part of t2.
    CDoom.sightcounts[1] = CDoom.sightcounts[1] + 1

    CDoom.validcount += 1

    CDoom.sightzstart = t1.value.z + t1.value.height - (t1.value.height >> 2)
    CDoom.topslope = (t2.value.z + t2.value.height) - CDoom.sightzstart
    CDoom.bottomslope = (t2.value.z) - CDoom.sightzstart

    CDoom.strace.x = t1.value.x
    CDoom.strace.y = t1.value.y
    CDoom.t2x = t2.value.x
    CDoom.t2y = t2.value.y
    CDoom.strace.dx = t2.value.x - t1.value.x
    CDoom.strace.dy = t2.value.y - t1.value.y

    # the head node is the last node output
    return CDoom.p_cross_bsp_node(CDoom.numnodes - 1)
  end

  def self.p_init_pic_anims
    # Init animation
    CDoom.lastanim = CDoom.anims
    i = 0
    while CDoom.animdefs[i].istexture != -1
      if CDoom.animdefs[i].istexture != 0
        # different episode ?
        if CDoom.r_check_texture_num_for_name(CDoom.animdefs[i].startname) == -1
          i += 1
          next
        end

        CDoom.lastanim.value.picnum = CDoom.r_texture_num_for_name(CDoom.animdefs[i].endname)
        CDoom.lastanim.value.basepic = CDoom.r_texture_num_for_name(CDoom.animdefs[i].startname)
      else
        if CDoom.w_check_num_for_name(CDoom.animdefs[i].startname) == -1
          i += 1
          next
        end

        CDoom.lastanim.value.picnum = CDoom.r_flat_num_for_name(CDoom.animdefs[i].endname)
        CDoom.lastanim.value.basepic = CDoom.r_flat_num_for_name(CDoom.animdefs[i].startname)
      end

      CDoom.lastanim.value.istexture = CDoom.animdefs[i].istexture
      CDoom.lastanim.value.numpics = CDoom.lastanim.value.picnum - CDoom.lastanim.value.basepic + 1

      if CDoom.lastanim.value.numpics < 2
        CDoom.i_error("Error: p_init_pic_anims: bad cycle from #{CDoom.animdefs[i].startname} to #{CDoom.animdefs[i].endname}")
      end

      CDoom.lastanim.value.speed = CDoom.animdefs[i].speed
      CDoom.lastanim += 1

      i += 1
    end
  end

  #
  # Will return a side_t*
  #  given the number of the current sector,
  #  the line number, and the side (0/1) that you want.
  #
  def self.get_side(current_sector : LibC::Int, line : LibC::Int, side : LibC::Int) : CDoom::Side*
    return CDoom.sides + CDoom.sectors[current_sector].lines[line].value.sidenum[side]
  end

  #
  # Will return a sector_t*
  #  given the number of the current sector,
  #  the line number and the side (0/1) that you want.
  #
  def self.get_sector(current_sector : LibC::Int, line : LibC::Int, side : LibC::Int) : CDoom::Sector*
    return CDoom.sides[CDoom.sectors[current_sector].lines[line].value.sidenum[side]].sector
  end

  #
  # Given the sector number and the line number,
  #  it will tell you whether the line is two-sided or not.
  #
  def self.two_sided(sector : LibC::Int, line : LibC::Int) : LibC::Int
    return CDoom.sectors[sector].lines[line].value.flags.to_i32 & CDoom::ML_TWOSIDED
  end

  #
  # Return sector_t * of sector next to current.
  # 0 if not two-sided line
  #
  def self.get_next_sector(line : CDoom::Line*, sec : CDoom::Sector*) : CDoom::Sector*
    return Pointer(CDoom::Sector).null if line.value.flags & CDoom::ML_TWOSIDED == 0

    return line.value.backsector if line.value.frontsector == sec

    return line.value.frontsector
  end

  #
  # FIND LOWEST FLOOR HEIGHT IN SURROUNDING SECTORS
  #
  def self.p_find_lowest_floor_surrounding(sec : CDoom::Sector*) : CDoom::Fixed
    floor = sec.value.floorheight

    sec.value.linecount.times do |i|
      check = sec.value.lines[i]
      other = CDoom.get_next_sector(check, sec)

      next if other.null?

      floor = other.value.floorheight if other.value.floorheight < floor
    end

    return floor
  end

  #
  # FIND HIGHEST FLOOR HEIGHT IN SURROUNDING SECTORS
  #
  def self.p_find_highest_floor_surrounding(sec : CDoom::Sector*) : CDoom::Fixed
    floor = -500 * FRACUNIT

    sec.value.linecount.times do |i|
      check = sec.value.lines[i]
      other = CDoom.get_next_sector(check, sec)

      next if other.null?

      floor = other.value.floorheight if other.value.floorheight > floor
    end

    return floor
  end

  #
  # FIND NEXT HIGHEST FLOOR IN SURROUNDING SECTORS
  # Note: this should be doable w/o a fixed array.
  #
  def self.p_find_next_highest_floor(sec : CDoom::Sector*, currentheight : LibC::Int) : CDoom::Fixed
    height = currentheight

    heightlist = uninitialized StaticArray(CDoom::Fixed, CDoom::MAX_ADJOINING_SECTORS)

    h = 0
    sec.value.linecount.times do |i|
      check = sec.value.lines[i]
      other = CDoom.get_next_sector(check, sec)

      next if other.null?

      if other.value.floorheight > height
        heightlist[h] = other.value.floorheight
        h += 1
      end

      # Check for overflow. Exit.
      if h >= CDoom::MAX_ADJOINING_SECTORS
        puts "Sector with more than 20 adjoining sectors"
        break
      end
    end

    # Find lowest height in list
    return currentheight if h == 0

    min = heightlist[0]

    # Range checking?
    i = 1
    while i < h
      min = heightlist[i] if heightlist[i] < min
      i += 1
    end

    return min
  end

  #
  # FIND LOWEST CEILING IN THE SURROUNDING SECTORS
  #
  def self.p_find_lowest_ceiling_surrounding(sec : CDoom::Sector*) : CDoom::Fixed
    height = Int32::MAX

    sec.value.linecount.times do |i|
      check = sec.value.lines[i]
      other = CDoom.get_next_sector(check, sec)

      next if other.null?

      height = other.value.ceilingheight if other.value.ceilingheight < height
    end

    return height
  end

  #
  # FIND HIGHEST CEILING IN THE SURROUNDING SECTORS
  #
  def self.p_find_highest_ceiling_surrounding(sec : CDoom::Sector*) : CDoom::Fixed
    height = 0

    sec.value.linecount.times do |i|
      check = sec.value.lines[i]
      other = CDoom.get_next_sector(check, sec)

      next if other.null?

      height = other.value.ceilingheight if other.value.ceilingheight > height
    end

    return height
  end

  #
  # RETURN NEXT SECTOR # THAT LINE TAG REFERS TO
  #
  def self.p_find_sector_from_line_tag(line : CDoom::Line*, start : LibC::Int) : LibC::Int
    i = start + 1
    while i < CDoom.numsectors
      return i if CDoom.sectors[i].tag == line.value.tag
      i += 1
    end

    return -1
  end

  #
  # Find minimum light from an adjacent sector
  #
  def self.p_find_min_surrounding_light(sector : CDoom::Sector*, max : LibC::Int) : LibC::Int
    min = max
    sector.value.linecount.times do |i|
      line = sector.value.lines[i]
      check = CDoom.get_next_sector(line, sector)

      next if check.null?

      min = check.value.lightlevel.to_i32 if check.value.lightlevel < min
    end

    return min
  end

  #
  # EVENTS
  # Events are operations triggered by using, crossing,
  # or shooting special lines, or by timed thinkers.
  #

  #
  # Called every time a thing origin is about
  #  to cross a line with a non 0 special.
  #
  def self.p_cross_special_line(linenum : LibC::Int, side : LibC::Int, thing : CDoom::Mobj*)
    line = CDoom.lines + linenum

    #        Triggers that other things can activate
    if thing.value.player.null?
      # Things that should NOT trigger specials...
      case thing.value.type
      when CDoom::Mobjtype::MT_ROCKET,
           CDoom::Mobjtype::MT_PLASMA,
           CDoom::Mobjtype::MT_BFG,
           CDoom::Mobjtype::MT_TROOPSHOT,
           CDoom::Mobjtype::MT_HEADSHOT,
           CDoom::Mobjtype::MT_BRUISERSHOT
        return
      end

      # [ds] Point of ok?
      ok = 0
      case line.value.special
      when 39,  # TELEPORT TRIGGER
           97,  # TELEPORT RETRIGGER
           125, # TELEPORT MONSTERONLY TRIGGER
           126, # TELEPORT MONSTERONLY RETRIGGER
           4,   # RAISE DOOR
           10,  # PLAT DOWN-WAIT-UP-STAY TRIGGER
           88   # PLAT DOWN-WAIT-UP-STAY RETRIGGER
        ok = 1
      end

      return if ok == 0
    end

    # Note: could use some const's here.
    case line.value.special
    # TRIGGERS.
    # All from here to RETRIGGERS.
    when 2
      # Open Door
      CDoom.ev_do_door(line, CDoom::Vldoorenum::DoorOpen)
      line.value.special = 0
    when 3
      # Close Door
      CDoom.ev_do_door(line, CDoom::Vldoorenum::DoorClose)
      line.value.special = 0
    when 4
      # Raise Door
      CDoom.ev_do_door(line, CDoom::Vldoorenum::DoorNormal)
      line.value.special = 0
    when 5
      # Raise Floor
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloor)
      line.value.special = 0
    when 6
      # Fast Ceiling Crush & Raise
      CDoom.ev_do_ceiling(line, CDoom::Ceilingenum::FastCrushAndRaise)
      line.value.special = 0
    when 8
      # Build Stairs
      CDoom.ev_build_stairs(line, CDoom::Stairenum::Build8)
      line.value.special = 0
    when 10
      # PlatDownWaitUp
      CDoom.ev_do_plat(line, CDoom::Plattype::DownWaitUpStay, 0)
      line.value.special = 0
    when 12
      # Light Turn On - brightest near
      CDoom.ev_light_turn_on(line, 0)
      line.value.special = 0
    when 13
      # Light Turn On 255
      CDoom.ev_light_turn_on(line, 255)
      line.value.special = 0
    when 16
      # Close Door 30
      CDoom.ev_do_door(line, CDoom::Vldoorenum::Close30ThenOpen)
      line.value.special = 0
    when 17
      # Start Light Strobing
      CDoom.ev_start_light_strobing(line)
      line.value.special = 0
    when 19
      # Lower Floor
      CDoom.ev_do_floor(line, CDoom::Floorenum::LowerFloor)
      line.value.special = 0
    when 22
      # Raise floor to nearest height and change texture
      CDoom.ev_do_plat(line, CDoom::Plattype::RaiseToNearestAndChange, 0)
      line.value.special = 0
    when 25
      # Ceiling Crush and Raise
      CDoom.ev_do_ceiling(line, CDoom::Ceilingenum::CrushAndRaise)
      line.value.special = 0
    when 30
      # Raise floor to shortest texture height
      #  on either side of lines.
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseToTexture)
      line.value.special = 0
    when 35
      # Lights Very Dark
      CDoom.ev_light_turn_on(line, 35)
      line.value.special = 0
    when 36
      # Lower Floor (TURBO)
      CDoom.ev_do_floor(line, CDoom::Floorenum::TurboLower)
      line.value.special = 0
    when 37
      # LowerAndChange
      CDoom.ev_do_floor(line, CDoom::Floorenum::LowerAndChange)
      line.value.special = 0
    when 38
      # Lower Floor to Lowest
      CDoom.ev_do_floor(line, CDoom::Floorenum::LowerFloorToLowest)
      line.value.special = 0
    when 39
      # TELEPORT!
      CDoom.ev_teleport(line, side, thing)
      line.value.special = 0
    when 40
      # RaiseCeilingLowerFloor
      CDoom.ev_do_ceiling(line, CDoom::Ceilingenum::RaiseToHighest)
      CDoom.ev_do_floor(line, CDoom::Floorenum::LowerFloorToLowest)
      line.value.special = 0
    when 44
      # Ceiling Crush
      CDoom.ev_do_ceiling(line, CDoom::Ceilingenum::LowerAndCrush)
      line.value.special = 0
    when 52
      # EXIT!
      CDoom.g_exit_level
    when 53
      # Perpetual Platform Raise
      CDoom.ev_do_plat(line, CDoom::Plattype::PerpetualRaise, 0)
      line.value.special = 0
    when 54
      # Platform Stop
      CDoom.ev_stop_plat(line)
      line.value.special = 0
    when 56
      # Raise Floor Crush
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloorCrush)
      line.value.special = 0
    when 57
      # Ceiling Crush Stop
      CDoom.ev_ceiling_crush_stop(line)
      line.value.special = 0
    when 58
      # Raise Floor 24
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloor24)
      line.value.special = 0
    when 59
      # Raise Floor 24 And Change
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloor24AndChange)
      line.value.special = 0
    when 104
      # Turn lights off in sector(tag)
      CDoom.ev_turn_tag_lights_off(line)
      line.value.special = 0
    when 108
      # Blazing Door Raise (faster than TURBO!)
      CDoom.ev_do_door(line, CDoom::Vldoorenum::BlazeRaise)
      line.value.special = 0
    when 109
      # Blazing Door Open (faster than TURBO!)
      CDoom.ev_do_door(line, CDoom::Vldoorenum::BlazeOpen)
      line.value.special = 0
    when 100
      # Build Stairs Turbo 16
      CDoom.ev_build_stairs(line, CDoom::Stairenum::Turbo16)
      line.value.special = 0
    when 110
      # Blazing Door Close (faster than TURBO!)
      CDoom.ev_do_door(line, CDoom::Vldoorenum::BlazeClose)
      line.value.special = 0
    when 119
      # Raise floor to nearest surr. floor
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloorToNearest)
      line.value.special = 0
    when 121
      # Blazing PlatDownWaitUpStay
      CDoom.ev_do_plat(line, CDoom::Plattype::BlazeDWUS, 0)
      line.value.special = 0
    when 124
      # Secret EXIT
      CDoom.g_secret_exit_level
    when 125
      # TELEPORT MonsterONLY
      if thing.value.player.null?
        CDoom.ev_teleport(line, side, thing)
        line.value.special = 0
      end
    when 130
      # Raise Floor Turbo
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloorTurbo)
      line.value.special = 0
    when 141
      # Silent Ceiling Crush & Raise
      CDoom.ev_do_ceiling(line, CDoom::Ceilingenum::SilentCrushAndRaise)
      line.value.special = 0
      # RETRIGGERS.  All from here till end.
    when 72
      # Ceiling Crush
      CDoom.ev_do_ceiling(line, CDoom::Ceilingenum::LowerAndCrush)
    when 73
      # Ceiling Crush and Raise
      CDoom.ev_do_ceiling(line, CDoom::Ceilingenum::CrushAndRaise)
    when 74
      # Ceiling Crush Stop
      CDoom.ev_ceiling_crush_stop(line)
    when 75
      # Close Door
      CDoom.ev_do_door(line, CDoom::Vldoorenum::DoorClose)
    when 76
      # Close Door 30
      CDoom.ev_do_door(line, CDoom::Vldoorenum::Close30ThenOpen)
    when 77
      # FastCeiling Crush & Raise
      CDoom.ev_do_ceiling(line, CDoom::Ceilingenum::FastCrushAndRaise)
    when 79
      # Lights Very Dark
      CDoom.ev_light_turn_on(line, 35)
    when 80
      # Light Turn On - brightest near
      CDoom.ev_light_turn_on(line, 0)
    when 81
      # Light Turn On 255
      CDoom.ev_light_turn_on(line, 255)
    when 82
      # Lower Floor To Lowest
      CDoom.ev_do_floor(line, CDoom::Floorenum::LowerFloorToLowest)
    when 83
      # Lower Floor
      CDoom.ev_do_floor(line, CDoom::Floorenum::LowerFloor)
    when 84
      # LowerAndChange
      CDoom.ev_do_floor(line, CDoom::Floorenum::LowerAndChange)
    when 86
      # Open Door
      CDoom.ev_do_door(line, CDoom::Vldoorenum::DoorOpen)
    when 87
      # Perpetual Platform Raise
      CDoom.ev_do_plat(line, CDoom::Plattype::PerpetualRaise, 0)
    when 88
      # PlatDownWaitUp
      CDoom.ev_do_plat(line, CDoom::Plattype::DownWaitUpStay, 0)
    when 89
      # Platform Stop
      CDoom.ev_stop_plat(line)
    when 90
      # Raise Door
      CDoom.ev_do_door(line, CDoom::Vldoorenum::DoorNormal)
    when 91
      # Raise Floor
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloor)
    when 92
      # Raise Floor 24
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloor24)
    when 93
      # Raise Floor 24 And Change
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloor24AndChange)
    when 94
      # Raise Floor Crush
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloorCrush)
    when 95
      # Raise floor to nearest height
      # and change texture.
      CDoom.ev_do_plat(line, CDoom::Plattype::RaiseToNearestAndChange, 0)
    when 96
      # Raise floor to shortest texture height
      # on either side of lines.
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseToTexture)
    when 97
      # TELEPORT !
      CDoom.ev_teleport(line, side, thing)
    when 98
      # Lower Floor (TURBO)
      CDoom.ev_do_floor(line, CDoom::Floorenum::TurboLower)
    when 105
      # Blazing Door Raise (faster than TURBO!)
      CDoom.ev_do_door(line, CDoom::Vldoorenum::BlazeRaise)
    when 106
      # Blazing Door Open (faster than TURBO!)
      CDoom.ev_do_door(line, CDoom::Vldoorenum::BlazeOpen)
    when 107
      # Blazing Door Close (faster than TURBO!)
      CDoom.ev_do_door(line, CDoom::Vldoorenum::BlazeClose)
    when 120
      # Blazing PlatDownWaitUpStay.
      CDoom.ev_do_plat(line, CDoom::Plattype::BlazeDWUS, 0)
    when 126
      # TELEPORT MonsterONLY>
      if thing.value.player.null?
        CDoom.ev_teleport(line, side, thing)
      end
    when 128
      # Raise to Nearest Floor
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloorToNearest)
    when 129
      # Raise Floor Turbo
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloorTurbo)
    end
  end

  #
  # Called when a thing shoots a special line.
  #
  def self.p_shoot_special_line(thing : CDoom::Mobj*, line : CDoom::Line*)
    # Impacts that other things can activate.
    if thing.value.player.null?
      ok = 0 # [ds] Pointless ok again?
      case line.value.special
      when 46
        # OPEN DOOR IMPACT
        ok = 1
      end
      return if ok == 0
    end

    case line.value.special
    when 24
      # RAISE FLOOR
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloor)
      CDoom.p_change_switch_texture(line, 0)
    when 46
      # OPEN DOOR
      CDoom.ev_do_door(line, CDoom::Vldoorenum::DoorOpen)
      CDoom.p_change_switch_texture(line, 1)
    when 47
      # RAISE FLOOR NEAR AND CHANGE
      CDoom.ev_do_plat(line, CDoom::Plattype::RaiseToNearestAndChange, 0)
      CDoom.p_change_switch_texture(line, 0)
    end
  end

  #
  # Called every tic frame
  #  that the player origin is in a special sector
  #
  def self.p_player_in_special_sector(player : CDoom::Player*)
    sector = player.value.mo.value.subsector.value.sector

    # Falling, not all the way down yet?
    return if player.value.mo.value.z != sector.value.floorheight

    # Has hitten ground.
    case sector.value.special
    when 5
      # HELLSLIME DAMAGE
      if player.value.powers[CDoom::Powertype::Ironfeet.value] == 0 &&
         CDoom.leveltime & 0x1f == 0
        CDoom.p_damage_mobj(player.value.mo, Pointer(CDoom::Mobj).null, Pointer(CDoom::Mobj).null, 10)
      end
    when 7
      # NUKAGE DAMAGE
      if player.value.powers[CDoom::Powertype::Ironfeet.value] == 0 &&
         CDoom.leveltime & 0x1f == 0
        CDoom.p_damage_mobj(player.value.mo, Pointer(CDoom::Mobj).null, Pointer(CDoom::Mobj).null, 5)
      end
    when 16, # SUPER HELLSLIME DAMAGE
         4   # STROBE HURT
      if (player.value.powers[CDoom::Powertype::Ironfeet.value] == 0 ||
         CDoom.p_random < 5) && CDoom.leveltime & 0x1f == 0
        CDoom.p_damage_mobj(player.value.mo, Pointer(CDoom::Mobj).null, Pointer(CDoom::Mobj).null, 20)
      end
    when 9
      # SECRET SECTOR
      player.value.secretcount = player.value.secretcount + 1
      player.value.message = "A secret is revealed!"
      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_getpow.value)
      sector.value.special = 0
    when 11
      # EXIT SUPER DAMAGE! (for E1M8 finale)
      player.value.cheats = player.value.cheats & ~CDoom::Cheat::CF_GODMODE.value

      CDoom.p_damage_mobj(player.value.mo, Pointer(CDoom::Mobj).null, Pointer(CDoom::Mobj).null, 20) if CDoom.leveltime & 0x1f == 0

      CDoom.g_exit_level if player.value.health <= 10
    else
      CDoom.i_error("Error: p_player_in_special_sector: unknown special #{sector.value.special}")
    end
  end

  #
  # Animate planes, scroll walls, etc.
  #
  def self.p_update_specials
    # LEVEL TIMER
    if CDoom.level_timer != 0
      CDoom.level_time_count -= 1
      CDoom.g_exit_level if CDoom.level_time_count == 0
    end

    # ANIMATE FLATS AND TEXTURES GLOBALLY
    anim = CDoom.anims.to_unsafe
    while anim < CDoom.lastanim
      i = anim.value.basepic
      while i < anim.value.basepic + anim.value.numpics
        pic = anim.value.basepic + ((CDoom.leveltime // anim.value.speed + i) % anim.value.numpics)
        if anim.value.istexture != 0
          CDoom.texturetranslation[i] = pic
        else
          CDoom.flattranslation[i] = pic
        end

        i += 1
      end

      anim += 1
    end

    # ANIMATE LINE SPECIALS
    CDoom.numlinespecials.times do |i|
      line = CDoom.linespeciallist[i]
      case line.value.special
      when 48
        # EFFECT FIRSTCOL SCROLL +
        (CDoom.sides + line.value.sidenum[0]).value.textureoffset = CDoom.sides[line.value.sidenum[0]].textureoffset + FRACUNIT
      end
    end

    # DO BUTTONS
    CDoom::MAXBUTTONS.times do |i|
      if CDoom.buttonlist[i].btimer != 0
        (CDoom.buttonlist.to_unsafe + i).value.btimer = CDoom.buttonlist[i].btimer - 1
        if CDoom.buttonlist[i].btimer == 0
          case CDoom.buttonlist[i].where
          when CDoom::Bwhere::Top
            (CDoom.sides + CDoom.buttonlist[i].line.value.sidenum[0]).value.toptexture =
              CDoom.buttonlist[i].btexture
          when CDoom::Bwhere::Middle
            (CDoom.sides + CDoom.buttonlist[i].line.value.sidenum[0]).value.midtexture =
              CDoom.buttonlist[i].btexture
          when CDoom::Bwhere::Bottom
            (CDoom.sides + CDoom.buttonlist[i].line.value.sidenum[0]).value.bottomtexture =
              CDoom.buttonlist[i].btexture
          end
          CDoom.s_start_sound(pointerof((CDoom.buttonlist.to_unsafe + i).value.@soundorg),
            CDoom::Sfxenum::SFX_swtchn.value)
          CDoom.doom_memset(CDoom.buttonlist.to_unsafe + i, 0, sizeof(CDoom::Button))
        end
      end
    end
  end

  #
  # Special Stuff that can not be categorized
  #
  def self.ev_do_donut(line : CDoom::Line*) : LibC::Int
    secnum = -1
    rtn = 0
    while (secnum = CDoom.p_find_sector_from_line_tag(line, secnum)) >= 0
      s1 = CDoom.sectors + secnum

      # ALREADY MOVING?  IF SO, KEEP GOING...
      next if !s1.value.specialdata.null?

      rtn = 1
      s2 = CDoom.get_next_sector(s1.value.lines[0], s1)
      s2.value.linecount.times do |i|
        if s2.value.lines[i].value.flags & CDoom::ML_TWOSIDED == 0 ||
           s2.value.lines[i].value.backsector == s1
          next
        end
        s3 = s2.value.lines[i].value.backsector

        #        Spawn rising slime
        floor = CDoom.z_malloc(sizeof(CDoom::Floormove), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Floormove*)
        CDoom.p_add_thinker(pointerof(floor.value.@thinker))
        s2.value.specialdata = floor
        pointerof(floor.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_move_floor).pointer, Pointer(Void).null)
        floor.value.type = CDoom::Floorenum::DonutRaise
        floor.value.crush = 0
        floor.value.direction = 1
        floor.value.sector = s2
        floor.value.speed = CDoom::FLOORSPEED // 2
        floor.value.texture = s3.value.floorpic
        floor.value.newspecial = 0
        floor.value.floordestheight = s3.value.floorheight

        #        Spawn lowering donut-hole
        floor = CDoom.z_malloc(sizeof(CDoom::Floormove), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Floormove*)
        CDoom.p_add_thinker(pointerof(floor.value.@thinker))
        s1.value.specialdata = floor
        pointerof(floor.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_move_floor).pointer, Pointer(Void).null)
        floor.value.type = CDoom::Floorenum::LowerFloor
        floor.value.crush = 0
        floor.value.direction = -1
        floor.value.sector = s1
        floor.value.speed = CDoom::FLOORSPEED // 2
        floor.value.floordestheight = s3.value.floorheight
        break
      end
    end

    return rtn
  end

  #
  # SPECIAL SPAWNING
  #

  #
  # After the map has been loaded, scan for specials
  #  that spawn thinkers
  #

  # Parses command line parameters.
  def self.p_spawn_specials
    episode = 1
    episode = 2 if CDoom.w_check_num_for_name("texture2") >= 0

    # See if -TIMER needs to be used.
    CDoom.level_timer = 0

    i = ARGV.index("-avg")
    if i && CDoom.deathmatch != 0
      CDoom.level_timer = 1
      CDoom.level_time_count = 20 * 60 * 35
    end

    i = ARGV.index("-timer")
    if i && CDoom.deathmatch != 0
      time = CDoom.doom_atoi(ARGV[i + 1]) * 60 * 35
      CDoom.level_timer = 1
      CDoom.level_time_count = time
    end

    #        Init special SECTORs.
    sector = CDoom.sectors
    CDoom.numsectors.times do |i|
      if sector.value.special == 0
        sector += 1
        next
      end

      case sector.value.special
      when 1
        # FLICKERING LIGHTS
        CDoom.p_spawn_light_flash(sector)
      when 2
        # STROBE FAST
        CDoom.p_spawn_strobe_flash(sector, CDoom::FASTDARK, 0)
      when 3
        # STROBE SLOW
        CDoom.p_spawn_strobe_flash(sector, CDoom::SLOWDARK, 0)
      when 4
        CDoom.p_spawn_strobe_flash(sector, CDoom::FASTDARK, 0)
        sector.value.special = 4
      when 8
        # GLOWING LIGHT
        CDoom.p_spawn_glowing_light(sector)
      when 9
        # SECRET SECTOR
        CDoom.totalsecret += 1
      when 10
        # DOOR CLOSE IN 30 SECONDS
        CDoom.p_spawn_door_close_in_30(sector)
      when 12
        # SYNC STROBE SLOW
        CDoom.p_spawn_strobe_flash(sector, CDoom::SLOWDARK, 1)
      when 13
        # SYNC STROBE FAST
        CDoom.p_spawn_strobe_flash(sector, CDoom::FASTDARK, 1)
      when 14
        # DOOR RAISE IN 5 MINUTES
        CDoom.p_spawn_door_raise_in_5_mins(sector, i)
      when 17
        CDoom.p_spawn_fire_flicker(sector)
      end

      sector += 1
    end

    # Init line EFFECTs
    CDoom.numlinespecials = 0
    CDoom.numlines.times do |i|
      case CDoom.lines[i].special
      when 48
        # EFFECT FIRSTCOL SCROLL+
        CDoom.linespeciallist[CDoom.numlinespecials] = CDoom.lines + i
        CDoom.numlinespecials += 1
      end
    end

    # Init other misc stuff
    CDoom::MAXCEILINGS.times { |i| CDoom.activeceilings[i] = Pointer(CDoom::Ceiling).null }

    CDoom::MAXPLATS.times { |i| CDoom.activeplats[i] = Pointer(CDoom::Plat).null }

    CDoom::MAXBUTTONS.times { |i| CDoom.doom_memset(CDoom.buttonlist.to_unsafe + i, 0, sizeof(CDoom::Button)) }
  end

  #
  # Only called at game initialization
  #
  def self.p_init_switch_list
    episode = 1

    if CDoom.gamemode == CDoom::GameMode::Registered || CDoom.gamemode == CDoom::GameMode::Retail
      episode = 2
    else
      episode = 3 if CDoom.gamemode == CDoom::GameMode::Commercial
    end

    index = 0
    CDoom::MAXSWITCHES.times do |i|
      if CDoom.alph_switch_list[i].episode == 0
        CDoom.numswitches = index // 2
        CDoom.switchlist[index] = -1
        break
      end

      if CDoom.alph_switch_list[i].episode <= episode
        CDoom.switchlist[index] = CDoom.r_texture_num_for_name(CDoom.alph_switch_list[i].name1)
        index += 1
        CDoom.switchlist[index] = CDoom.r_texture_num_for_name(CDoom.alph_switch_list[i].name2)
        index += 1
      end
    end

    CDoom.numswitches.times { |i| @@switch_origins << CDoom::Degenmobj.new }
  end

  #
  # Start a button counting down till it turns off.
  #
  def self.p_start_button(line : CDoom::Line*, w : CDoom::Bwhere, origin : CDoom::Degenmobj*, texture : LibC::Int, time : LibC::Int)
    # See if button is already pressed
    CDoom::MAXBUTTONS.times do |i|
      return if CDoom.buttonlist[i].btimer != 0 &&
                CDoom.buttonlist[i].line == line
    end

    CDoom::MAXBUTTONS.times do |i|
      if CDoom.buttonlist[i].btimer == 0
        (CDoom.buttonlist.to_unsafe + i).value.line = line
        (CDoom.buttonlist.to_unsafe + i).value.where = w
        (CDoom.buttonlist.to_unsafe + i).value.btexture = texture
        (CDoom.buttonlist.to_unsafe + i).value.btimer = time
        (CDoom.buttonlist.to_unsafe + i).value.soundorg = origin.as(CDoom::Mobj*)

        return
      end
    end

    CDoom.i_error("Error: p_start_button: no button slots left!")
  end

  #
  # Function that changes wall texture.
  # Tell it if switch is ok to use again (1=yes, it's a button).
  #
  def self.p_change_switch_texture(line : CDoom::Line*, use_again : LibC::Int)
    line.value.special = 0 if use_again == 0

    tex_top = CDoom.sides[line.value.sidenum[0]].toptexture
    tex_mid = CDoom.sides[line.value.sidenum[0]].midtexture
    tex_bot = CDoom.sides[line.value.sidenum[0]].bottomtexture
    sound = CDoom::Sfxenum::SFX_swtchn.value

    # EXIT SWITCH?
    if line.value.special == 11
      sound = CDoom::Sfxenum::SFX_swtchx.value
    end

    (CDoom.numswitches * 2).times do |i|
      if CDoom.switchlist[i] == tex_top
        origin = (@@switch_origins.to_unsafe + (i // 2))
        origin.value.x = (line.value.v1.value.x &+ line.value.v2.value.x) // 2
        origin.value.y = (line.value.v1.value.y &+ line.value.v2.value.y) // 2

        CDoom.s_start_sound(origin.as(CDoom::Mobj*), sound)
        (CDoom.sides + line.value.sidenum[0]).value.toptexture = CDoom.switchlist[i ^ 1]

        p_start_button(line, CDoom::Bwhere::Top, origin, CDoom.switchlist[i], CDoom::BUTTONTIME) if use_again != 0

        return
      elsif CDoom.switchlist[i] == tex_mid
        origin = (@@switch_origins.to_unsafe + (i // 2))
        origin.value.x = (line.value.v1.value.x &+ line.value.v2.value.x) // 2
        origin.value.y = (line.value.v1.value.y &+ line.value.v2.value.y) // 2

        CDoom.s_start_sound(origin.as(CDoom::Mobj*), sound)
        (CDoom.sides + line.value.sidenum[0]).value.midtexture = CDoom.switchlist[i ^ 1]

        p_start_button(line, CDoom::Bwhere::Middle, origin, CDoom.switchlist[i], CDoom::BUTTONTIME) if use_again != 0

        return
      elsif CDoom.switchlist[i] == tex_bot
        origin = (@@switch_origins.to_unsafe + (i // 2))
        origin.value.x = (line.value.v1.value.x &+ line.value.v2.value.x) // 2
        origin.value.y = (line.value.v1.value.y &+ line.value.v2.value.y) // 2

        CDoom.s_start_sound(origin.as(CDoom::Mobj*), sound)
        (CDoom.sides + line.value.sidenum[0]).value.bottomtexture = CDoom.switchlist[i ^ 1]

        p_start_button(line, CDoom::Bwhere::Bottom, origin, CDoom.switchlist[i], CDoom::BUTTONTIME) if use_again != 0

        return
      end
    end
  end

  #
  # Called when a thing uses a special line.
  # Only the front sides of lines are usable.
  #
  def self.p_use_special_line(thing : CDoom::Mobj*, line : CDoom::Line*, side : LibC::Int) : CDoom::DoomBool
    # Err...
    # Use the back sides of VERY SPECIAL lines...
    if side != 0
      case line.value.special
      when 124
        # Sliding door open&close
        # UNUSED?
      else
        return 0
      end
    end

    # Switches that other things can activate.
    if thing.value.player.null?
      # never open secret doors
      return 0 if line.value.flags & CDoom::ML_SECRET != 0

      case line.value.special
      when 1,  # MANUAL DOOR RAISE
           32, # MANUAL BLUE
           33, # MANUAL RED
           34  # MANUAL YELLOW
      else
        return 0
      end
    end

    # do something
    case line.value.special
    # MANUALS
    when 1,  # Vertical Door
         26, # Blue Door/Locked
         27, # Yellow Door /Locked
         28, # Red Door /Locked

         31, # Manual door open
         32, # Blue locked door open
         33, # Red locked door open
         34, # Yellow locked door open

         117, # Blazing door raise
         118  # Blazing door open
      CDoom.ev_vertical_door(line, thing)
      # UNUSED - Door Slide Open&Close
      # when 124
      # CDoom.ev_sliding_door(line, thing)

      # SWITCHES
    when 7
      # Build Stairs
      if CDoom.ev_build_stairs(line, CDoom::Stairenum::Build8) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 9
      # Change Donut
      if CDoom.ev_do_donut(line) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 11
      # Exit level
      CDoom.p_change_switch_texture(line, 0)
      CDoom.g_exit_level
    when 14
      # Raise Floor 32 and change texture
      if CDoom.ev_do_plat(line, CDoom::Plattype::RaiseAndChange, 32) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 15
      # Raise Floor 24 and change texture
      if CDoom.ev_do_plat(line, CDoom::Plattype::RaiseAndChange, 24) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 18
      # Raise Floor to next highest floor
      if CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloorToNearest) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 20
      # Raise Plat next highest floor and change texture
      if CDoom.ev_do_plat(line, CDoom::Plattype::RaiseToNearestAndChange, 0) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 21
      # PlatDownWaitUpStay
      if CDoom.ev_do_plat(line, CDoom::Plattype::DownWaitUpStay, 0) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 23
      # Lower Floor to Lowest
      if CDoom.ev_do_floor(line, CDoom::Floorenum::LowerFloorToLowest) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 29
      # Raise Door
      if CDoom.ev_do_door(line, CDoom::Vldoorenum::DoorNormal) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 41
      # Lower Ceiling to Floor
      if CDoom.ev_do_ceiling(line, CDoom::Ceilingenum::LowerToFloor) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 71
      # Turbo Lower Floor
      if CDoom.ev_do_floor(line, CDoom::Floorenum::TurboLower) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 49
      # Ceiling Crush And Raise
      if CDoom.ev_do_ceiling(line, CDoom::Ceilingenum::CrushAndRaise) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 50
      # Close Door
      if CDoom.ev_do_door(line, CDoom::Vldoorenum::DoorClose) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 51
      # Secret EXIT
      CDoom.p_change_switch_texture(line, 0)
      CDoom.g_secret_exit_level
    when 55
      # Raise Floor Crush
      if CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloorCrush) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 101
      # Raise Floor
      if CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloor) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 102
      # Lower Floor to Surrounding floor height
      if CDoom.ev_do_floor(line, CDoom::Floorenum::LowerFloor) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 103
      # Open Door
      if CDoom.ev_do_door(line, CDoom::Vldoorenum::DoorOpen) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 111
      # Blazing Door Raise (faster than TURBO!)
      if CDoom.ev_do_door(line, CDoom::Vldoorenum::BlazeRaise) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 112
      # Blazing Door Open (faster than TURBO!)
      if CDoom.ev_do_door(line, CDoom::Vldoorenum::BlazeOpen) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 113
      # Blazing Door Raise (faster than TURBO!)
      if CDoom.ev_do_door(line, CDoom::Vldoorenum::BlazeClose) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 122
      # Blazing PlatDownWaitUpStay
      if CDoom.ev_do_plat(line, CDoom::Plattype::BlazeDWUS, 0) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 127
      # Build Stairs Turbo 16
      if CDoom.ev_build_stairs(line, CDoom::Stairenum::Turbo16) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 131
      # Raise Floor Turbo
      if CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloorTurbo) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 133, # BlzOpenDoor BLUE
         135, # BlzOpenDoor RED
         137  # BlzOpenDoor YELLOW
      if CDoom.ev_do_locked_door(line, CDoom::Vldoorenum::BlazeOpen, thing) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 140
      # Raise Floor 512
      if CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloor512) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
      # BUTTONS
    when 42
      # Close Door
      if CDoom.ev_do_door(line, CDoom::Vldoorenum::DoorClose) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 43
      # Lower Ceiling to Floor
      if CDoom.ev_do_ceiling(line, CDoom::Ceilingenum::LowerToFloor) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 45
      # Lower Floor to Surrounding floor height
      if CDoom.ev_do_floor(line, CDoom::Floorenum::LowerFloor) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 60
      # Raise Floor to Lowest
      if CDoom.ev_do_floor(line, CDoom::Floorenum::LowerFloorToLowest) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 61
      # Open Door
      if CDoom.ev_do_door(line, CDoom::Vldoorenum::DoorOpen) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 62
      # PlatDownWaitUpStay
      if CDoom.ev_do_plat(line, CDoom::Plattype::DownWaitUpStay, 1) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 63
      # Raise Door
      if CDoom.ev_do_door(line, CDoom::Vldoorenum::DoorNormal) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 64
      # Raise Floor to ceiling
      if CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloor) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 66
      # Raise Floor 24 and change texture
      if CDoom.ev_do_plat(line, CDoom::Plattype::RaiseAndChange, 24) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 67
      # Raise Floor 32 and change texture
      if CDoom.ev_do_plat(line, CDoom::Plattype::RaiseAndChange, 32) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 65
      # Raise Floor Crush
      if CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloorCrush) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 68
      # Raise Plat to next highest floor and change texture
      if CDoom.ev_do_plat(line, CDoom::Plattype::RaiseToNearestAndChange, 0) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 69
      # Raise Floor to next highest floor
      if CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloorToNearest) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 70
      # Turbo Lower Floor
      if CDoom.ev_do_floor(line, CDoom::Floorenum::TurboLower) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 114
      # Blazing Door Raise (faster than TURBO!)
      if CDoom.ev_do_door(line, CDoom::Vldoorenum::BlazeRaise) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 115
      # Blazing Door Open (faster than TURBO!)
      if CDoom.ev_do_door(line, CDoom::Vldoorenum::BlazeOpen) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 116
      # Blazing Door Close (faster than TURBO!)
      if CDoom.ev_do_door(line, CDoom::Vldoorenum::BlazeClose) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 123
      # Blazing PlatDownWaitUpStay
      if CDoom.ev_do_plat(line, CDoom::Plattype::BlazeDWUS, 0) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 132
      # Raise Floor Turbo
      if CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloorTurbo) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 99,  # BlzOpenDoor BLUE
         134, # BlzOpenDoor RED
         136  # BlzOpenDoor YELLOW
      if CDoom.ev_do_locked_door(line, CDoom::Vldoorenum::BlazeOpen, thing) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 138
      # Light Turn On
      CDoom.ev_light_turn_on(line, 255)
      CDoom.p_change_switch_texture(line, 1)
    when 139
      # Light Turn Off
      CDoom.ev_light_turn_on(line, 35)
      CDoom.p_change_switch_texture(line, 1)
    end
    return 1
  end

  def self.ev_teleport(line : CDoom::Line*, side : LibC::Int, thing : CDoom::Mobj*) : LibC::Int
    # don't teleport missiles
    return 0 if thing.value.flags & CDoom::Mobjflag::MF_MISSILE.value != 0

    # Don't teleport if hit back of line,
    #  so you can get out of teleporter.
    return 0 if side == 1

    tag = line.value.tag
    CDoom.numsectors.times do |i|
      if CDoom.sectors[i].tag == tag
        thinker = CDoom.thinkercap.next
        while thinker != pointerof(CDoom.thinkercap)
          # not a mobj
          if thinker.value.function.acp1.pointer != (->CDoom.p_mobj_thinker).pointer
            thinker = thinker.value.next
            next
          end

          m = thinker.as(CDoom::Mobj*)

          # not a teleportman
          if m.value.type != CDoom::Mobjtype::MT_TELEPORTMAN
            thinker = thinker.value.next
            next
          end

          sector = m.value.subsector.value.sector
          # wrong sector
          if sector - CDoom.sectors != i
            thinker = thinker.value.next
            next
          end

          oldx = thing.value.x
          oldy = thing.value.y
          oldz = thing.value.z

          return 0 if CDoom.p_teleport_move(thing, m.value.x, m.value.y) == 0

          thing.value.z = thing.value.floorz # fixme: not needed?
          thing.value.player.value.viewz = thing.value.z + thing.value.player.value.viewheight if !thing.value.player.null?

          # spawn a teleport fog at source and destination
          fog = CDoom.p_spawn_mobj(oldx, oldy, oldz, CDoom::Mobjtype::MT_TFOG)
          CDoom.s_start_sound(fog, CDoom::Sfxenum::SFX_telept.value)
          an = m.value.angle >> CDoom::ANGLETOFINESHIFT
          fog = CDoom.p_spawn_mobj(m.value.x + 20 * @@finecosine[an], m.value.y + 20 * @@finesine[an],
            thing.value.z, CDoom::Mobjtype::MT_TFOG)

          # emit sound, where?
          CDoom.s_start_sound(fog, CDoom::Sfxenum::SFX_telept.value)

          # don't move for a bit
          thing.value.reactiontime = 18 if !thing.value.player.null?

          thing.value.angle = m.value.angle
          thing.value.momx = 0
          thing.value.momy = 0
          thing.value.momz = 0
          return 1

          thinker = thinker.value.next
        end
      end
    end

    return 0
  end

  #
  # THINKERS
  # All thinkers should be allocated by Z_Malloc
  # so they can be operated on uniformly.
  # The actual structures will vary in size,
  # but the first element must be thinker_t.
  #

  def self.p_init_thinkers
    CDoom.thinkercap.prev = pointerof(CDoom.thinkercap)
    CDoom.thinkercap.next = pointerof(CDoom.thinkercap)
  end

  #
  # Adds a new thinker at the end of the list.
  #
  def self.p_add_thinker(thinker : CDoom::Thinker*)
    CDoom.thinkercap.prev.value.next = thinker
    thinker.value.next = pointerof(CDoom.thinkercap)
    thinker.value.prev = CDoom.thinkercap.prev
    CDoom.thinkercap.prev = thinker
    thinker.value.remove = 0
  end

  #
  # Deallocation is lazy -- it will not actually be freed
  # until its thinking turn comes up.
  #
  def self.p_remove_thinker(thinker : CDoom::Thinker*)
    thinker.value.remove = 1
  end

  def self.p_run_thinkers
    currentthinker = CDoom.thinkercap.next
    while currentthinker != pointerof(CDoom.thinkercap)
      if currentthinker.value.remove != 0
        # time to remove it
        currentthinker.value.next.value.prev = currentthinker.value.prev
        currentthinker.value.prev.value.next = currentthinker.value.next
        CDoom.z_free(currentthinker)
      else
        currentthinker.value.function.acp1.call(currentthinker.as(Void*)) if !currentthinker.value.function.acp1.pointer.null?
      end
      currentthinker = currentthinker.value.next
    end
  end

  def self.p_ticker
    # run the tic
    return if CDoom.paused != 0

    # pause if in menu and at least one tic has been run
    if CDoom.netgame == 0 &&
       CDoom.menuactive != 0 &&
       CDoom.demoplayback == 0 &&
       CDoom.players[CDoom.consoleplayer].viewz != 1
      return
    end
    CDoom::MAXPLAYERS.times { |i| CDoom.p_player_think(CDoom.players.to_unsafe + i) if CDoom.playeringame[i] != 0 }

    CDoom.p_run_thinkers
    CDoom.p_update_specials
    CDoom.p_respawn_specials

    # for par times
    CDoom.leveltime += 1
  end

  #
  # Movement.
  #

  #
  # Moves the given origin along a given angle.
  #
  def self.p_thrust(player : CDoom::Player*, angle : CDoom::Angle, move : CDoom::Fixed)
    angle >>= CDoom::ANGLETOFINESHIFT

    player.value.mo.value.momx = player.value.mo.value.momx + CDoom.fixed_mul(move, @@finecosine[angle])
    player.value.mo.value.momy = player.value.mo.value.momy + CDoom.fixed_mul(move, @@finesine[angle])
  end

  #
  # Calculate the walking / running height adjustment
  #
  def self.p_calc_height(player : CDoom::Player*)
    # Regular movement bobbing
    # (needs to be calculated for gun swing
    # even if not on ground)
    # OPTIMIZE: tablify angle
    # Note: a LUT allows for effects
    #  like a ramp with low health.
    player.value.bob =
      CDoom.fixed_mul(player.value.mo.value.momx, player.value.mo.value.momx) +
        CDoom.fixed_mul(player.value.mo.value.momy, player.value.mo.value.momy)

    player.value.bob = player.value.bob >> 2

    player.value.bob = CDoom::MAXBOB if player.value.bob > CDoom::MAXBOB

    if player.value.cheats & CDoom::Cheat::CF_NOMOMENTUM.value != 0 || CDoom.onground == 0
      player.value.viewz = player.value.mo.value.z + CDoom::VIEWHEIGHT

      if player.value.viewz > player.value.mo.value.ceilingz - 4 * FRACUNIT
        player.value.viewz = player.value.mo.value.ceilingz - 4 * FRACUNIT
      end

      player.value.viewz = player.value.mo.value.z + player.value.viewheight
      return
    end

    angle = (CDoom::FINEANGLES.tdiv(20) * CDoom.leveltime) & CDoom::FINEMASK
    bob = CDoom.fixed_mul(player.value.bob.tdiv(2), @@finesine[angle])

    # move viewheight
    if player.value.playerstate == CDoom::Playerstate::PST_LIVE
      player.value.viewheight = player.value.viewheight + player.value.deltaviewheight

      if player.value.viewheight > CDoom::VIEWHEIGHT
        player.value.viewheight = CDoom::VIEWHEIGHT
        player.value.deltaviewheight = 0
      end

      if player.value.viewheight < CDoom::VIEWHEIGHT // 2
        player.value.viewheight = CDoom::VIEWHEIGHT // 2
        player.value.deltaviewheight = 1 if player.value.deltaviewheight <= 0
      end

      if player.value.deltaviewheight != 0
        player.value.deltaviewheight = player.value.deltaviewheight + FRACUNIT // 4
        player.value.deltaviewheight = 1 if player.value.deltaviewheight == 0
      end
    end

    player.value.viewz = player.value.mo.value.z + player.value.viewheight + bob

    if player.value.viewz > player.value.mo.value.ceilingz - 4 * FRACUNIT
      player.value.viewz = player.value.mo.value.ceilingz - 4 * FRACUNIT
    end
  end

  def self.p_move_player(player : CDoom::Player*)
    cmd = pointerof(player.value.@cmd)

    player.value.mo.value.angle = player.value.mo.value.angle &+ (cmd.value.angleturn.to_i32 << 16)

    # Do not let the player control movement
    #  if not onground.
    CDoom.onground = (player.value.mo.value.z <= player.value.mo.value.floorz).to_unsafe

    CDoom.p_thrust(player, player.value.mo.value.angle, cmd.value.forwardmove.to_i32 * 2048) if cmd.value.forwardmove != 0 && CDoom.onground != 0

    CDoom.p_thrust(player, player.value.mo.value.angle &- ANG90, cmd.value.sidemove.to_i32 * 2048) if cmd.value.sidemove != 0 && CDoom.onground != 0

    if (cmd.value.forwardmove != 0 || cmd.value.sidemove != 0) &&
       player.value.mo.value.state == CDoom.states + CDoom::Statenum::S_PLAY.value
      CDoom.p_set_mobj_state(player.value.mo, CDoom::Statenum::S_PLAY_RUN1)
    end
  end

  #
  # Fall on your face when dying.
  # Decrease POV height to floor height.
  #

  def self.p_death_think(player : CDoom::Player*)
    CDoom.p_move_psprites(player)

    # fall to the ground
    player.value.viewheight = player.value.viewheight - FRACUNIT if player.value.viewheight > 6 * FRACUNIT

    player.value.viewheight = 6 * FRACUNIT if player.value.viewheight < 6 * FRACUNIT

    player.value.deltaviewheight = 0
    CDoom.onground = (player.value.mo.value.z <= player.value.mo.value.floorz).to_unsafe
    CDoom.p_calc_height(player)

    if !player.value.attacker.null? && player.value.attacker != player.value.mo
      angle = CDoom.r_point_to_angle2(player.value.mo.value.x,
        player.value.mo.value.y,
        player.value.attacker.value.x,
        player.value.attacker.value.y)

      delta = angle &- player.value.mo.value.angle

      if delta < CDoom::ANG5 || delta > (-CDoom::ANG5).to_u32!
        # Looking at killer,
        #  so fade damage flash down.
        player.value.mo.value.angle = angle

        player.value.damagecount = player.value.damagecount - 1 if player.value.damagecount != 0
      elsif delta < ANG180
        player.value.mo.value.angle = player.value.mo.value.angle &+ CDoom::ANG5
      else
        player.value.mo.value.angle = player.value.mo.value.angle &- CDoom::ANG5
      end
    elsif player.value.damagecount != 0
      player.value.damagecount = player.value.damagecount - 1
    end

    player.value.playerstate = CDoom::Playerstate::PST_REBORN if player.value.cmd.buttons & CDoom::Buttoncode::BT_USE.value != 0
  end

  def self.p_player_think(player : CDoom::Player*)
    if player.value.cheats & CDoom::Cheat::CF_NOCLIP.value != 0
      player.value.mo.value.flags = player.value.mo.value.flags | CDoom::Mobjflag::MF_NOCLIP.value
    else
      player.value.mo.value.flags = player.value.mo.value.flags & ~CDoom::Mobjflag::MF_NOCLIP.value
    end

    # chain saw run forward
    cmd = pointerof(player.value.@cmd)
    if player.value.mo.value.flags & CDoom::Mobjflag::MF_JUSTATTACKED.value != 0
      cmd.value.angleturn = 0
      cmd.value.forwardmove = 0xc800 // 512
      cmd.value.sidemove = 0
      player.value.mo.value.flags = player.value.mo.value.flags & ~CDoom::Mobjflag::MF_JUSTATTACKED.value
    end

    if player.value.playerstate == CDoom::Playerstate::PST_DEAD
      CDoom.p_death_think(player)
      return
    end

    # Move around.
    # Reactiontime is used to prevent movement
    #  for a bit after a teleport.
    if player.value.mo.value.reactiontime != 0
      player.value.mo.value.reactiontime = player.value.mo.value.reactiontime - 1
    else
      CDoom.p_move_player(player)
    end

    CDoom.p_calc_height(player)

    CDoom.p_player_in_special_sector(player) if player.value.mo.value.subsector.value.sector.value.special != 0

    # Check for weapon change.

    # A special event has no other buttons.
    cmd.value.buttons = 0 if cmd.value.buttons & CDoom::Buttoncode::BT_SPECIAL.value != 0

    if cmd.value.buttons & CDoom::Buttoncode::BT_CHANGE.value != 0
      # The actual changing of the weapon is done
      #  when the weapon psprite can do it
      #  (read: not in the middle of an attack).
      newweapon = CDoom::Weapontype.new((cmd.value.buttons & CDoom::Buttoncode::BT_WEAPONMASK.value) >> CDoom::Buttoncode::BT_WEAPONSHIFT.value)

      if newweapon == CDoom::Weapontype::Fist &&
         player.value.weaponowned[CDoom::Weapontype::Chainsaw.value] != 0 &&
         !(player.value.readyweapon == CDoom::Weapontype::Chainsaw &&
         player.value.powers[CDoom::Powertype::Strength.value] != 0)
        newweapon = CDoom::Weapontype::Chainsaw
      end

      if CDoom.gamemode == CDoom::GameMode::Commercial &&
         newweapon == CDoom::Weapontype::Shotgun &&
         player.value.weaponowned[CDoom::Weapontype::Supershotgun.value] != 0 &&
         player.value.readyweapon != CDoom::Weapontype::Supershotgun
        newweapon = CDoom::Weapontype::Supershotgun
      end

      if player.value.weaponowned[newweapon.value] != 0 &&
         newweapon != player.value.readyweapon
        # Do not go to plasma or BFG in shareware,
        #  even if cheated.
        if (newweapon != CDoom::Weapontype::Plasma &&
           newweapon != CDoom::Weapontype::Bfg) ||
           CDoom.gamemode != CDoom::GameMode::Shareware
          player.value.pendingweapon = newweapon
        end
      end
    end

    # check for use
    if cmd.value.buttons & CDoom::Buttoncode::BT_USE.value != 0
      if player.value.usedown == 0
        CDoom.p_use_lines(player)
        player.value.usedown = 1
      end
    else
      player.value.usedown = 0
    end

    # cycle psprites
    CDoom.p_move_psprites(player)

    # Counters, time dependend power ups.

    # Strength counts up to diminish fade
    if player.value.powers[CDoom::Powertype::Strength.value] != 0
      player.value.powers[CDoom::Powertype::Strength.value] =
        player.value.powers[CDoom::Powertype::Strength.value] &+ 1
    end

    if player.value.powers[CDoom::Powertype::Invulnerability.value] != 0
      player.value.powers[CDoom::Powertype::Invulnerability.value] =
        player.value.powers[CDoom::Powertype::Invulnerability.value] - 1
    end

    if player.value.powers[CDoom::Powertype::Invisibility.value] != 0
      player.value.powers[CDoom::Powertype::Invisibility.value] =
        player.value.powers[CDoom::Powertype::Invisibility.value] - 1
      if player.value.powers[CDoom::Powertype::Invisibility.value] == 0
        player.value.mo.value.flags = player.value.mo.value.flags & ~CDoom::Mobjflag::MF_SHADOW.value
      end
    end

    if player.value.powers[CDoom::Powertype::Infrared.value] != 0
      player.value.powers[CDoom::Powertype::Infrared.value] =
        player.value.powers[CDoom::Powertype::Infrared.value] - 1
    end

    if player.value.powers[CDoom::Powertype::Ironfeet.value] != 0
      player.value.powers[CDoom::Powertype::Ironfeet.value] =
        player.value.powers[CDoom::Powertype::Ironfeet.value] - 1
    end

    player.value.damagecount = player.value.damagecount - 1 if player.value.damagecount != 0

    player.value.bonuscount = player.value.bonuscount - 1 if player.value.bonuscount != 0

    # Handling colormaps.
    if player.value.powers[CDoom::Powertype::Invulnerability.value] != 0
      if player.value.powers[CDoom::Powertype::Invulnerability.value] > 4 * 32 ||
         player.value.powers[CDoom::Powertype::Invulnerability.value] & 8 != 0
        player.value.fixedcolormap = CDoom::INVERSECOLORMAP
      else
        player.value.fixedcolormap = 0
      end
    elsif player.value.powers[CDoom::Powertype::Infrared.value] != 0
      if player.value.powers[CDoom::Powertype::Infrared.value] > 4 * 32 ||
         player.value.powers[CDoom::Powertype::Infrared.value] & 8 != 0
        # almost full bright
        player.value.fixedcolormap = 1
      else
        player.value.fixedcolormap = 0
      end
    else
      player.value.fixedcolormap = 0
    end
  end

  def self.r_clear_draw_segs
    CDoom.ds_p = CDoom.drawsegs.to_unsafe
  end

  #
  # Does handle solid walls,
  #  e.g. single sided LineDefs (middle texture)
  #  that entirely block the view.
  #
  def self.r_clip_solid_wall_segment(first : LibC::Int, last : LibC::Int)
    # Find the first range that touches the range
    #  (adjacent pixels are touching).
    start = CDoom.solidsegs.to_unsafe
    while start.value.last < first - 1
      start += 1
    end

    if first < start.value.first
      if last < start.value.first - 1
        # Post is entirely visible (above start),
        #  so insert a new clippost.
        CDoom.r_store_wall_range(first, last)
        nextc = CDoom.newend
        CDoom.newend += 1

        while nextc != start
          nextc.value = (nextc - 1).value
          nextc -= 1
        end
        nextc.value.first = first
        nextc.value.last = last
        return
      end

      # There is a fragment above start.value.
      CDoom.r_store_wall_range(first, start.value.first - 1)
      # Now adjust the clip size.
      start.value.first = first
    end

    # Bottom contained in start?
    return if last <= start.value.last

    nextc = start
    crunch = false
    while last >= (nextc + 1).value.first - 1
      # There is a fragment between two posts.
      CDoom.r_store_wall_range(nextc.value.last + 1, (nextc + 1).value.first - 1)
      nextc += 1

      if last <= nextc.value.last
        # Bottom is contained in next.
        # Adjust the clip size.
        start.value.last = nextc.value.last
        crunch = true
        break
      end
    end

    unless crunch
      # There is a fragment after nextc.value.
      CDoom.r_store_wall_range(nextc.value.last + 1, last)
      # Adjust the clip size.
      start.value.last = last
    end

    # Remove start+1 to next from the clip list,
    # because start now covers their area.
    if nextc == start
      # Post just extended past the bottom of one post.
      return
    end

    while nextc != CDoom.newend
      nextc += 1
      # Remove a post
      start += 1
      start.value = nextc.value
    end

    CDoom.newend = start + 1
  end

  #
  # Clips the given range of columns,
  #  but does not includes it in the clip list.
  # Does handle windows,
  #  e.g. LineDefs with upper and lower texture.
  #
  def self.r_clip_pass_wall_segment(first : LibC::Int, last : LibC::Int)
    # Find the first range that touches the range
    #  (adjacent pixels are touching).
    start = CDoom.solidsegs.to_unsafe
    while start.value.last < first - 1
      start += 1
    end

    if first < start.value.first
      if last < start.value.first - 1
        # Post is entirely visible (above start).
        CDoom.r_store_wall_range(first, last)
        return
      end

      # There is a fragment above start.value.
      CDoom.r_store_wall_range(first, start.value.first - 1)
    end

    # Bottom contained in start?
    return if last <= start.value.last

    while last >= (start + 1).value.first - 1
      # There is a fragment between two posts.
      CDoom.r_store_wall_range(start.value.last + 1, (start + 1).value.first - 1)
      start += 1

      return if last <= start.value.last
    end

    # There is a fragment after next.value.
    CDoom.r_store_wall_range(start.value.last + 1, last)
  end

  def self.r_clear_clip_segs
    (CDoom.solidsegs.to_unsafe).value.first = -0x7fffffff
    (CDoom.solidsegs.to_unsafe).value.last = -1
    (CDoom.solidsegs.to_unsafe + 1).value.first = CDoom.viewwidth
    (CDoom.solidsegs.to_unsafe + 1).value.last = 0x7fffffff
    CDoom.newend = CDoom.solidsegs.to_unsafe + 2
  end

  #
  # Clips the given segment
  # and adds any visible pieces to the line list.
  #
  def self.r_addline(line : CDoom::Seg*)
    CDoom.curline = line

    # OPTIMIZE: quickly reject orthogonal back sides.
    angle1 = CDoom.r_point_to_angle(line.value.v1.value.x, line.value.v1.value.y)
    angle2 = CDoom.r_point_to_angle(line.value.v2.value.x, line.value.v2.value.y)

    # Clip to view edges.
    # OPTIMIZE: make constant out of 2*clipangle (FIELDOFVIEW).
    span = angle1 &- angle2

    # Back side? I.e. backface culling?
    return if span >= ANG180

    # Global angle needed by segcalc.
    CDoom.rw_angle1 = angle1
    angle1 &-= CDoom.viewangle
    angle2 &-= CDoom.viewangle

    tspan = angle1 &+ CDoom.clipangle
    if tspan > 2 &* CDoom.clipangle
      tspan &-= 2 &* CDoom.clipangle

      # Totally off the left edge?
      return if tspan >= span

      angle1 = CDoom.clipangle
    end
    tspan = CDoom.clipangle &- angle2
    if tspan > 2 &* CDoom.clipangle
      tspan &-= 2 &* CDoom.clipangle

      # Totally off the left edge?
      return if tspan >= span

      angle2 = -(CDoom.clipangle.to_i32!)
    end

    # The seg is in the view range,
    # but not necessarily visible.
    angle1 = (angle1 &+ ANG90) >> CDoom::ANGLETOFINESHIFT
    angle2 = (angle2 &+ ANG90) >> CDoom::ANGLETOFINESHIFT
    x1 = CDoom.viewangletox[angle1]
    x2 = CDoom.viewangletox[angle2]

    # Does not cross a pixel?
    return if (x1 == x2)

    CDoom.backsector = line.value.backsector

    # Single sided line?
    if CDoom.backsector.null?
      CDoom.r_clip_solid_wall_segment(x1, x2 - 1)
      return
    end

    # Closed door.
    if CDoom.backsector.value.ceilingheight <= CDoom.frontsector.value.floorheight ||
       CDoom.backsector.value.floorheight >= CDoom.frontsector.value.ceilingheight
      CDoom.r_clip_solid_wall_segment(x1, x2 - 1)
      return
    end

    # Window.
    if CDoom.backsector.value.ceilingheight != CDoom.frontsector.value.ceilingheight ||
       CDoom.backsector.value.floorheight != CDoom.frontsector.value.floorheight
      CDoom.r_clip_pass_wall_segment(x1, x2 - 1)
      return
    end

    # Reject empty lines used for triggers
    #  and special events.
    # Identical floor and ceiling on both sides,
    # identical light levels on both sides,
    # and no middle texture.
    if CDoom.backsector.value.ceilingpic == CDoom.frontsector.value.ceilingpic &&
       CDoom.backsector.value.floorpic == CDoom.frontsector.value.floorpic &&
       CDoom.backsector.value.lightlevel == CDoom.frontsector.value.lightlevel &&
       CDoom.curline.value.sidedef.value.midtexture == 0
      return
    end

    CDoom.r_clip_pass_wall_segment(x1, x2 - 1)
    return
  end

  #
  # Checks BSP node/subtree bounding box.
  # Returns true
  #  if some part of the bbox might be visible.
  #
  def self.r_check_bbox(bspcoord : CDoom::Fixed*) : CDoom::DoomBool
    # Find the corners of the box
    # that define the edges from current viewpoint.
    if CDoom.viewx <= bspcoord[CDoom::BOXLEFT]
      boxx = 0
    elsif CDoom.viewx < bspcoord[CDoom::BOXRIGHT]
      boxx = 1
    else
      boxx = 2
    end

    if CDoom.viewy >= bspcoord[CDoom::BOXTOP]
      boxy = 0
    elsif CDoom.viewy > bspcoord[CDoom::BOXBOTTOM]
      boxy = 1
    else
      boxy = 2
    end

    boxpos = (boxy << 2) + boxx
    return 1 if boxpos == 5

    x1 = bspcoord[CDoom.checkcoord[boxpos][0]]
    y1 = bspcoord[CDoom.checkcoord[boxpos][1]]
    x2 = bspcoord[CDoom.checkcoord[boxpos][2]]
    y2 = bspcoord[CDoom.checkcoord[boxpos][3]]

    # check clip list for an open space
    angle1 = CDoom.r_point_to_angle(x1, y1) &- CDoom.viewangle
    angle2 = CDoom.r_point_to_angle(x2, y2) &- CDoom.viewangle

    span = angle1 &- angle2

    # Sitting on a line?
    return 1 if span >= ANG180

    tspan = angle1 &+ CDoom.clipangle

    if tspan > 2 &* CDoom.clipangle
      tspan &-= 2 &* CDoom.clipangle

      # Totally off the left edge?
      return 0 if tspan >= span

      angle1 = CDoom.clipangle
    end
    tspan = CDoom.clipangle &- angle2
    if tspan > 2 &* CDoom.clipangle
      tspan &-= 2 &* CDoom.clipangle

      # Totally off the left edge?
      return 0 if tspan >= span

      angle2 = -(CDoom.clipangle.to_i32!)
    end

    # Find the first clippost
    #  that touches the source post
    #  (adjacent pixels are touching).
    angle1 = (angle1 &+ ANG90) >> CDoom::ANGLETOFINESHIFT
    angle2 = (angle2 &+ ANG90) >> CDoom::ANGLETOFINESHIFT
    sx1 = CDoom.viewangletox[angle1]
    sx2 = CDoom.viewangletox[angle2]

    # Does not cross a pixel.
    return 0 if sx1 == sx2
    sx2 -= 1

    start = CDoom.solidsegs.to_unsafe
    while start.value.last < sx2
      start += 1
    end

    if sx1 >= start.value.first &&
       sx2 <= start.value.last
      # The clippost contains the new span.
      return 0
    end

    return 1
  end

  #
  # Determine floor/ceiling planes.
  # Add sprites of things in sector.
  # Draw one or more line segments.
  #
  def self.r_subsector(num : LibC::Int)
    {% if flag?("RANGECHECK") %}
      if num >= CDoom.numsubsectors
        CDoom.i_error("Error: r_subsector: ss #{num} with numss = #{CDoom.numsubsectors}")
      end
    {% end %}

    CDoom.sscount += 1
    sub = CDoom.subsectors + num
    CDoom.frontsector = sub.value.sector
    count = sub.value.numlines
    line = CDoom.segs + sub.value.firstline

    if CDoom.frontsector.value.floorheight < CDoom.viewz
      @@floorplane = r_find_plane(CDoom.frontsector.value.floorheight,
        CDoom.frontsector.value.floorpic,
        CDoom.frontsector.value.lightlevel)
    else
      @@floorplane = -1
    end

    if CDoom.frontsector.value.ceilingheight > CDoom.viewz ||
       CDoom.frontsector.value.ceilingpic == CDoom.skyflatnum
      @@ceilingplane = r_find_plane(CDoom.frontsector.value.ceilingheight,
        CDoom.frontsector.value.ceilingpic,
        CDoom.frontsector.value.lightlevel)
    else
      @@ceilingplane = -1
    end

    CDoom.r_add_sprites(CDoom.frontsector)

    while count != 0
      count -= 1
      CDoom.r_addline(line)
      line += 1
    end
  end

  #
  # Renders all subsectors below a given node,
  #  traversing subtree recursively.
  # Just call with BSP root.
  #
  def self.r_render_bsp_node(bspnum : LibC::Int)
    # Found a subsector?
    if bspnum & CDoom::NF_SUBSECTOR != 0
      if bspnum == -1
        CDoom.r_subsector(0)
      else
        CDoom.r_subsector(bspnum & (~CDoom::NF_SUBSECTOR))
      end
      return
    end

    bsp = CDoom.nodes + bspnum

    # Decide which side the view point is on.
    side = CDoom.r_point_on_side(CDoom.viewx, CDoom.viewy, bsp)

    # Recursively divide front space.
    CDoom.r_render_bsp_node(bsp.value.children[side])

    # Possibly divide back space.
    CDoom.r_render_bsp_node(bsp.value.children[side ^ 1]) if CDoom.r_check_bbox(bsp.value.bbox[side ^ 1]) != 0
  end

  #
  # Graphics.
  # DOOM graphics for walls and sprites
  # is stored in vertical runs of opaque pixels (posts).
  # A column is composed of zero or more posts,
  # a patch or sprite is composed of zero or more columns.
  #

  #
  # MAPTEXTURE_T CACHING
  # When a texture is first needed,
  #  it counts the number of composite columns
  #  required in the texture and allocates space
  #  for a column directory and any new columns.
  # The directory will simply point inside other patches
  #  if there is only one patch in a given column,
  #  but any columns with multiple patches
  #  will have new column_ts generated.
  #

  # Clip and draw a column
  #  from a patch into a cached post.
  def self.r_draw_column_in_cache(patch : CDoom::Column*, cache : CDoom::Byte*, originy : LibC::Int, cacheheight : LibC::Int)
    dest = cache + 3

    while patch.value.topdelta != 0xff
      source = patch.as(CDoom::Byte*) + 3
      count = patch.value.length
      position = originy + patch.value.topdelta

      if position < 0
        count += position
        position = 0
      end

      count = cacheheight - position if position + count > cacheheight

      CDoom.doom_memcpy(cache + position, source, count) if count > 0

      patch = (patch.as(CDoom::Byte*) + patch.value.length + 4).as(CDoom::Column*)
    end
  end

  # Using the texture definition,
  #  the composite texture is created from the patches,
  #  and each column is cached.
  def self.r_generate_composite(texnum : LibC::Int)
    texture = CDoom.textures[texnum]

    block = CDoom.z_malloc(CDoom.texturecompositesize[texnum],
      CDoom::PU_STATIC,
      CDoom.texturecomposite + texnum).as(CDoom::Byte*)

    collump = CDoom.texturecolumnlump[texnum]
    colofs = CDoom.texturecolumnofs[texnum]

    # Composite the columns together.
    patch = texture.value.patches.to_unsafe

    texture.value.patchcount.times do |i|
      realpatch = CDoom.w_cache_lump_num(patch.value.patch, CDoom::PU_CACHE).as(CDoom::Patch*)
      x1 = patch.value.originx
      x2 = x1 + realpatch.value.width

      if x1 < 0
        x = 0
      else
        x = x1
      end

      x2 = texture.value.width if x2 > texture.value.width

      while x < x2
        # Column does not have multiple patches?
        if collump[x] >= 0
          x += 1
          next
        end

        patchcol = (realpatch.as(CDoom::Byte*) + (realpatch.value.columnofs.to_unsafe + (x - x1)).value).as(CDoom::Column*)

        CDoom.r_draw_column_in_cache(patchcol,
          block + colofs[x],
          patch.value.originy,
          texture.value.height)

        x += 1
      end

      patch += 1
    end

    # Now that the texture has been built in column cache,
    #  it is purgable from zone memory.
    z_change_tag(block, CDoom::PU_CACHE)
  end

  def self.r_generate_lookup(texnum : LibC::Int)
    texture = CDoom.textures[texnum]

    # Composited texture not created yet
    CDoom.texturecomposite[texnum] = Pointer(CDoom::Byte).null

    CDoom.texturecompositesize[texnum] = 0
    collump = CDoom.texturecolumnlump[texnum]
    colofs = CDoom.texturecolumnofs[texnum]

    # Now count the number of columns
    #  that are covered by more than one patch.
    # Fill in the lump / offset, so columns
    #  with only a single patch are all done.
    patchcount = GC.malloc(texture.value.width.to_i32).as(CDoom::Byte*)
    CDoom.doom_memset(patchcount, 0, texture.value.width)
    patch = texture.value.patches.to_unsafe

    texture.value.patchcount.times do |i|
      realpatch = CDoom.w_cache_lump_num(patch.value.patch, CDoom::PU_CACHE).as(CDoom::Patch*)
      x1 = patch.value.originx
      x2 = x1 + realpatch.value.width

      if x1 < 0
        x = 0
      else
        x = x1
      end

      x2 = texture.value.width if x2 > texture.value.width

      while x < x2
        patchcount[x] = patchcount[x] + 1
        collump[x] = patch.value.patch.to_i16!
        colofs[x] = ((realpatch.value.columnofs.to_unsafe + (x - x1)).value + 3).to_u16!

        x += 1
      end

      patch += 1
    end

    texture.value.width.times do |x|
      if patchcount[x] == 0
        puts "r_generate_lookup: column without a patch (#{String.new(texture.value.name.to_unsafe)})"
        return
      end

      if patchcount[x] > 1
        # Use the cached block.
        collump[x] = -1
        colofs[x] = CDoom.texturecompositesize[texnum].to_u16!

        if CDoom.texturecompositesize[texnum] > 0x10000 - texture.value.height
          CDoom.i_error("Error: r_generate_lookup: texture #{texnum} is >64k")
        end

        CDoom.texturecompositesize[texnum] = CDoom.texturecompositesize[texnum] + texture.value.height
      end
    end

    GC.free(patchcount.as(Void*))
  end

  def self.r_get_column(tex : LibC::Int, col : LibC::Int) : CDoom::Byte*
    col &= CDoom.texturewidthmask[tex]
    lump = CDoom.texturecolumnlump[tex][col]
    ofs = CDoom.texturecolumnofs[tex][col]

    return CDoom.w_cache_lump_num(lump, CDoom::PU_CACHE).as(CDoom::Byte*) + ofs if lump > 0

    CDoom.r_generate_composite(tex) if CDoom.texturecomposite[tex].null?

    return CDoom.texturecomposite[tex] + ofs
  end

  #
  # Initializes the texture list
  #  with the textures from the world map.
  #
  def self.r_init_textures
    name = Pointer(UInt8).malloc(9)

    # Load the patch names from pnames.lmp.
    name[8] = 0
    names = CDoom.w_cache_lump_name("PNAMES", CDoom::PU_STATIC).as(UInt8*)
    nummappatches = names.as(Int32*).value
    name_p = names + 4
    patchlookup = GC.malloc(nummappatches * sizeof(Int32)).as(Int32*)

    nummappatches.times do |i|
      CDoom.doom_strncpy(name, name_p + i * 8, 8)
      patchlookup[i] = CDoom.w_check_num_for_name(name)
    end
    CDoom.z_free(names)

    # Load the map texture definitions from textures.lmp.
    # The data is contained in one or two lumps,
    #  TEXTURE1 for shareware, plus TEXTURE2 for commercial.
    maptex = CDoom.w_cache_lump_name("TEXTURE1", CDoom::PU_STATIC).as(Int32*)
    maptex1 = maptex
    numtextures1 = maptex.value
    maxoff = CDoom.w_lump_length(CDoom.w_get_num_for_name("TEXTURE1"))
    directory = maptex + 1

    if CDoom.w_check_num_for_name("TEXTURE2") != -1
      maptex2 = CDoom.w_cache_lump_name("TEXTURE2", CDoom::PU_STATIC).as(Int32*)
      numtextures2 = maptex2.value
      maxoff2 = CDoom.w_lump_length(CDoom.w_get_num_for_name("TEXTURE2"))
    else
      maptex2 = Pointer(Int32).null
      numtextures2 = 0
      maxoff2 = 0
    end
    CDoom.numtextures = numtextures1 + numtextures2

    CDoom.textures = CDoom.z_malloc(CDoom.numtextures * sizeof(CDoom::Texture*), CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Texture**)
    CDoom.texturecolumnlump = CDoom.z_malloc(CDoom.numtextures * sizeof(Int16*), CDoom::PU_STATIC, Pointer(Void).null).as(Int16**)
    CDoom.texturecolumnofs = CDoom.z_malloc(CDoom.numtextures * sizeof(UInt16*), CDoom::PU_STATIC, Pointer(Void).null).as(UInt16**)
    CDoom.texturecomposite = CDoom.z_malloc(CDoom.numtextures * sizeof(CDoom::Byte*), CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Byte**)
    CDoom.texturecompositesize = CDoom.z_malloc(CDoom.numtextures * sizeof(Int32), CDoom::PU_STATIC, Pointer(Void).null).as(Int32*)
    CDoom.texturewidthmask = CDoom.z_malloc(CDoom.numtextures * sizeof(Int32), CDoom::PU_STATIC, Pointer(Void).null).as(Int32*)
    CDoom.textureheight = CDoom.z_malloc(CDoom.numtextures * sizeof(CDoom::Fixed), CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Fixed*)

    totalwidth = 0

    CDoom.numtextures.times do |i|
      print "." if i & 63 == 0

      if i == numtextures1
        # Start looking in second texture file.
        maptex = maptex2
        maxoff = maxoff2
        directory = maptex + 1
      end

      offset = directory.value

      CDoom.i_error("Error: r_init_textures: bad texture directory") if offset > maxoff

      mtexture = (maptex.as(CDoom::Byte*) + offset).as(CDoom::Maptexture*)

      texture = CDoom.z_malloc(sizeof(CDoom::Texture) +
                               sizeof(CDoom::Texpatch) * (mtexture.value.patchcount - 1),
        CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Texture*)
      CDoom.textures[i] = texture

      texture.value.width = mtexture.value.width
      texture.value.height = mtexture.value.height
      texture.value.patchcount = mtexture.value.patchcount

      CDoom.doom_memcpy(texture.value.name, mtexture.value.name, sizeof(typeof(texture.value.name)))
      mpatch = mtexture.value.patches.to_unsafe
      patch = texture.value.patches.to_unsafe

      texture.value.patchcount.times do |j|
        patch.value.originx = mpatch.value.originx
        patch.value.originy = mpatch.value.originy
        patch.value.patch = patchlookup[mpatch.value.patch]
        if patch.value.patch == -1
          CDoom.i_error("Error: r_init_textures: Missing patch in texture #{String.new(texture.value.name.to_unsafe, 8)}")
        end

        mpatch += 1
        patch += 1
      end
      CDoom.texturecolumnlump[i] = CDoom.z_malloc(texture.value.width * sizeof(Int16), CDoom::PU_STATIC, Pointer(Void).null).as(Int16*)
      CDoom.texturecolumnofs[i] = CDoom.z_malloc(texture.value.width * sizeof(UInt16), CDoom::PU_STATIC, Pointer(Void).null).as(UInt16*)

      j = 1
      while j * 2 <= texture.value.width
        j <<= 1
      end

      CDoom.texturewidthmask[i] = j - 1
      CDoom.textureheight[i] = texture.value.height.to_i32 << FRACBITS

      totalwidth += texture.value.width
      directory += 1
    end

    CDoom.z_free(maptex1)
    CDoom.z_free(maptex2) unless maptex2.null?

    # Precalculate whatever possible.
    CDoom.numtextures.times { |i| CDoom.r_generate_lookup(i) }

    # Create translation table for global animation.
    CDoom.texturetranslation = CDoom.z_malloc((CDoom.numtextures + 1) * sizeof(Int32), CDoom::PU_STATIC, Pointer(Void).null).as(Int32*)

    CDoom.numtextures.times { |i| CDoom.texturetranslation[i] = i }

    GC.free(patchlookup.as(Void*))
  end

  def self.r_init_flats
    # Create translation table for global animation.
    CDoom.flattranslation = CDoom.z_malloc((CDoom.numflats + 1) * sizeof(Int32), CDoom::PU_STATIC, Pointer(Void).null).as(Int32*)

    CDoom.numflats.times do |i|
      print "." if i & 63 == 0
      CDoom.flattranslation[i] = i
    end
  end

  #
  # Finds the width and hoffset of all sprites in the wad,
  #  so the sprite does not need to be cached completely
  #  just for having the header info ready during rendering.
  #
  def self.r_init_sprite_lumps
    CDoom.spritewidth = CDoom.z_malloc(CDoom.numspritelumps * sizeof(CDoom::Fixed), CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Fixed*)
    CDoom.spriteoffset = CDoom.z_malloc(CDoom.numspritelumps * sizeof(CDoom::Fixed), CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Fixed*)
    CDoom.spritetopoffset = CDoom.z_malloc(CDoom.numspritelumps * sizeof(CDoom::Fixed), CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Fixed*)

    CDoom.numspritelumps.times do |i|
      print "." if i & 63 == 0

      patch = CDoom.w_cache_lump_num(CDoom.firstspritelump + i, CDoom::PU_CACHE).as(CDoom::Patch*)
      CDoom.spritewidth[i] = patch.value.width.to_i32 << FRACBITS
      CDoom.spriteoffset[i] = patch.value.leftoffset.to_i32 << FRACBITS
      CDoom.spritetopoffset[i] = patch.value.topoffset.to_i32 << FRACBITS
    end
  end

  def self.r_init_colormaps
    # Load in the light tables,
    #  256 byte align tables.
    lump = CDoom.w_get_num_for_name("COLORMAP")
    length = CDoom.w_lump_length(lump) + 255
    CDoom.colormaps = CDoom.z_malloc(length, CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Lighttable*)
    CDoom.colormaps = Pointer(CDoom::Lighttable).new(((CDoom.colormaps.address + 255) & ~0xff))
    CDoom.w_read_lump(lump, CDoom.colormaps)
  end

  def self.r_order_lump_section(starts : Array(String), ends : Array(String))
    # Musical lumps!

    # Find all lump sections
    sections = [] of Tuple(Int32, Int32)
    start = -1
    @@lumpinfo.each_with_index do |lump, i|
      starts.each do |s|
        if doom_strncmp(lump.name.to_unsafe, s.to_unsafe, 8) == 0
          start = i
          break
        end
      end

      if start != 1
        ends.each do |e|
          if doom_strncmp(lump.name.to_unsafe, e.to_unsafe, 8) == 0
            sections << {start, i}
            start = -1
          end
        end
      end
    end

    lumps = [] of CDoom::Lumpinfo
    lumps << CDoom::Lumpinfo.new
    doom_strcpy(lumps.to_unsafe.value.name.to_unsafe, starts[0].to_unsafe)
    # Reverse so deleting doesn't mess with alignment
    sections.reverse.each do |section|
      lumps.concat(@@lumpinfo[(section[0] + 1)...section[1]]) # Respect s_start/end lumps
      @@lumpinfo.delete_at(section[0]..section[1])
    end
    lumps << CDoom::Lumpinfo.new
    doom_strcpy((lumps.to_unsafe + lumps.size - 1).value.name.to_unsafe, ends[0].to_unsafe)

    # Now all are in order, add back onto end with start and end lumps
    @@lumpinfo.concat(lumps)
  end

  #
  # Locates all the lumps
  #  that will be used by all views
  # Must be called after W_Init.
  #
  def self.r_init_data
    r_order_lump_section(["S_START", "SS_START"], ["S_END", "SS_END"])
    r_order_lump_section(["F_START", "FF_START"], ["F_END", "FF_END"])

    CDoom.numlumps = @@lumpinfo.size
    CDoom.lumpcache.clear(CDoom.numlumps)

    CDoom.firstspritelump = CDoom.w_get_num_for_name("S_START") + 1
    CDoom.lastspritelump = CDoom.w_get_num_for_name("S_END") - 1
    CDoom.numspritelumps = CDoom.lastspritelump - CDoom.firstspritelump + 1

    CDoom.firstflat = CDoom.w_get_num_for_name("F_START") + 1
    CDoom.lastflat = CDoom.w_get_num_for_name("F_END") - 1
    CDoom.numflats = CDoom.lastflat - CDoom.firstflat + 1

    nums = (CDoom.numtextures + 63) // 64 +
           (CDoom.numflats + 63) // 64 +
           (CDoom.numspritelumps + 63) // 64

    # Really complex printing shit...
    print "["
    nums.times { |i| print " " }
    print "]"
    (nums + 1).times { |i| print "\b" }

    CDoom.r_init_textures
    CDoom.r_init_flats
    CDoom.r_init_sprite_lumps
    CDoom.r_init_colormaps
    puts "]"
  end

  #
  # Retrieval, get a flat number for a flat name.
  #
  def self.r_flat_num_for_name(name : LibC::Char*) : LibC::Int
    namet = uninitialized StaticArray(UInt8, 9)

    i = CDoom.w_check_num_for_name(name)

    if i == -1
      namet[8] = 0
      CDoom.doom_memcpy(namet, name, 8)

      CDoom.i_error("Error: r_flat_num_for_name #{namet} not found")
    end
    return i - CDoom.firstflat
  end

  #
  # Check whether texture is available.
  # Filter out NoTexture indicator.
  #
  def self.r_check_texture_num_for_name(name : LibC::Char*) : LibC::Int
    # "NoTexture" marker.
    return 0 if name[0] == '-'.ord

    CDoom.numtextures.times { |i| return i if CDoom.doom_strncasecmp(CDoom.textures[i].value.name, name, 8) == 0 }

    return -1
  end

  #
  # Calls R_CheckTextureNumForName,
  #  aborts with error message.
  #
  def self.r_texture_num_for_name(name : LibC::Char*) : LibC::Int
    i = CDoom.r_check_texture_num_for_name(name)

    if i == -1
      CDoom.i_error("Error: r_texture_num_for_name: #{name} not found")
    end

    return i
  end

  #
  # Preloads all relevant graphics for the level.
  #
  def self.r_precache_level
    return if CDoom.demoplayback != 0

    # Precache flats.
    flatpresent = GC.malloc(CDoom.numflats).as(UInt8*)
    CDoom.doom_memset(flatpresent, 0, CDoom.numflats)

    CDoom.numsectors.times do |i|
      flatpresent[CDoom.sectors[i].floorpic] = 1
      flatpresent[CDoom.sectors[i].ceilingpic] = 1
    end

    CDoom.flatmemory = 0

    CDoom.numflats.times do |i|
      if flatpresent[i] != 0
        lump = CDoom.firstflat + i
        CDoom.flatmemory += @@lumpinfo[lump].size
        CDoom.w_cache_lump_num(lump, CDoom::PU_CACHE)
      end
    end

    # Precache textures.
    texturepresent = GC.malloc(CDoom.numtextures).as(UInt8*)
    CDoom.doom_memset(texturepresent, 0, CDoom.numtextures)

    CDoom.numsides.times do |i|
      texturepresent[CDoom.sides[i].toptexture] = 1
      texturepresent[CDoom.sides[i].midtexture] = 1
      texturepresent[CDoom.sides[i].bottomtexture] = 1
    end

    # Sky texture is always present.
    # Note that F_SKY1 is the name used to
    #  indicate a sky floor/ceiling as a flat,
    #  while the sky texture is stored like
    #  a wall texture, with an episode dependend
    #  name.
    texturepresent[CDoom.skytexture] = 1

    CDoom.texturememory = 0
    CDoom.numtextures.times do |i|
      next if texturepresent[i] == 0

      texture = CDoom.textures[i]

      texture.value.patchcount.times do |j|
        lump = (texture.value.patches.to_unsafe + j).value.patch
        CDoom.texturememory += @@lumpinfo[lump].size
        CDoom.w_cache_lump_num(lump, CDoom::PU_CACHE)
      end
    end

    # Precache sprites.
    spritepresent = GC.malloc(CDoom.numsprites).as(UInt8*)
    CDoom.doom_memset(spritepresent, 0, CDoom.numsprites)

    th = CDoom.thinkercap.next
    while th != pointerof(CDoom.thinkercap)
      if th.value.function.acp1.pointer == (->CDoom.p_mobj_thinker).pointer
        spritepresent[th.as(CDoom::Mobj*).value.sprite.value] = 1
      end

      th = th.value.next
    end

    CDoom.spritememory = 0
    CDoom.numsprites.times do |i|
      next if spritepresent[i] == 0

      CDoom.sprites[i].numframes.times do |j|
        sf = (CDoom.sprites + i).value.spriteframes + j
        8.times do |k|
          lump = CDoom.firstspritelump + sf.value.lump[k]
          CDoom.spritememory += @@lumpinfo[lump].size
          CDoom.w_cache_lump_num(lump, CDoom::PU_CACHE)
        end
      end
    end

    GC.free(texturepresent.as(Void*))
    GC.free(flatpresent.as(Void*))
    GC.free(spritepresent.as(Void*))
  end

  #
  # All drawing to the view buffer is accomplished in this file.
  # The other refresh files only know about ccordinates,
  #  not the architecture of the frame buffer.
  # Conveniently, the frame buffer is a linear one,
  #  and we need only the base address,
  #  and the total size == width*height*depth/8.,
  #

  #
  # A column is a vertical slice/span from a wall texture that,
  # given the DOOM style restrictions on the view orientation,
  # will always have constant z depth.
  # Thus a special case loop for very fast rendering can
  # be used. It has also been used with Wolfenstein 3D.
  #
  def self.r_draw_column
    count = CDoom.dc_yh - CDoom.dc_yl

    # Zero length, column does not exceed a pixel.
    return if count < 0

    {% if flag?("RANGECHECK") %}
      if CDoom.dc_x.to_u32! >= CDoom::SCREENWIDTH ||
         CDoom.dc_yl < 0 || CDoom.dc_yh >= CDoom::SCREENHEIGHT
        CDoom.i_error("Error: r_draw_column: #{CDoom.dc_yl} to #{CDoom.dc_yh} at #{CDoom.dc_x}")
      end
    {% end %}

    # Framebuffer destination address.
    # Use ylookup LUT to avoid multiply with ScreenWidth.
    # Use columnofs LUT for subwindows?
    dest = CDoom.ylookup[CDoom.dc_yl] + CDoom.columnofs[CDoom.dc_x]

    # Determine scaling,
    #  which is the only mapping to be done.
    fracstep = CDoom.dc_iscale
    frac = CDoom.dc_texturemid + (CDoom.dc_yl - CDoom.centery) * fracstep

    # Inner loop that does the actual texture mapping,
    #  e.g. a DDA-lile scaling.
    # This is as fast as it gets.
    loop do
      # Re-map color indices from wall texture column
      #  using a lighting/special effects LUT.
      dest.value = CDoom.dc_colormap[CDoom.dc_source[(frac >> FRACBITS) & 127]]

      dest += CDoom::SCREENWIDTH
      frac += fracstep

      break unless count != 0
      count -= 1
    end
  end

  #
  # Spectre/Invisibility.
  #

  #
  # Framebuffer postprocessing.
  # Creates a fuzzy image by copying pixels
  #  from adjacent ones to left and right.
  # Used with an all black colormap, this
  #  could create the SHADOW effect,
  #  i.e. spectres and invisible players.
  #
  def self.r_draw_fuzz_column
    # Adjust borders. Low...
    CDoom.dc_yl = 1 if CDoom.dc_yl == 0

    # .. and high.
    CDoom.dc_yh = CDoom.viewheight - 2 if CDoom.dc_yh == CDoom.viewheight - 1

    count = CDoom.dc_yh - CDoom.dc_yl

    # Zero length.
    return if count < 0

    {% if flag?("RANGECHECK") %}
      if CDoom.dc_x.to_u32! >= CDoom::SCREENWIDTH ||
         CDoom.dc_yl < 0 || CDoom.dc_yh >= CDoom::SCREENHEIGHT
        CDoom.i_error("Error: r_draw_fuzz_column: #{CDoom.dc_yl} to #{CDoom.dc_yh} at #{CDoom.dc_x}")
      end
    {% end %}

    # Does not work with blocky mode.
    dest = CDoom.ylookup[CDoom.dc_yl] + CDoom.columnofs[CDoom.dc_x]

    # Looks familiar.
    fracstep = CDoom.dc_iscale
    frac = CDoom.dc_texturemid + (CDoom.dc_yl - CDoom.centery) * fracstep

    # Looks like an attempt at dithering,
    #  using the colormap #6 (of 0-31, a bit
    #  brighter than average).
    loop do
      # Lookup framebuffer, and retrieve
      #  a pixel that is either one column
      #  left or right of the current one.
      # Add index from colormap to index.
      dest.value = CDoom.colormaps[6 * 256 + dest[CDoom.fuzzoffset[CDoom.fuzzpos]]]

      # Clamp table lookup index.
      CDoom.fuzzpos += 1
      CDoom.fuzzpos = 0 if CDoom.fuzzpos == CDoom::FUZZTABLE

      dest += CDoom::SCREENWIDTH

      frac += fracstep
      break unless count != 0
      count -= 1
    end
  end

  #
  # Used to draw player sprites
  #  with the green colorramp mapped to others.
  # Could be used with different translation
  #  tables, e.g. the lighter colored version
  #  of the BaronOfHell, the HellKnight, uses
  #  identical sprites, kinda brightened up.
  #
  def self.r_draw_translated_column
    count = CDoom.dc_yh - CDoom.dc_yl
    return if count < 0
    {% if flag?("RANGECHECK") %}
      if CDoom.dc_x.to_u32! >= CDoom::SCREENWIDTH ||
         CDoom.dc_yl < 0 || CDoom.dc_yh >= CDoom::SCREENHEIGHT
        CDoom.i_error("Error: r_draw_column: #{CDoom.dc_yl} to #{CDoom.dc_yh} at #{CDoom.dc_x}")
      end
    {% end %}

    # FIXME. As above.
    dest = CDoom.ylookup[CDoom.dc_yl] + CDoom.columnofs[CDoom.dc_x]

    # Looks familiar.
    fracstep = CDoom.dc_iscale
    frac = CDoom.dc_texturemid + (CDoom.dc_yl - CDoom.centery) * fracstep

    # Here we do an additional index re-mapping.
    loop do
      # Translation tables are used
      #  to map certain colorramps to other ones,
      #  used with PLAY sprites.
      # Thus the "green" ramp of the player 0 sprite
      #  is mapped to gray, red, black/indigo.
      dest.value = CDoom.dc_colormap[CDoom.dc_translation[CDoom.dc_source[frac >> FRACBITS]]]
      dest += CDoom::SCREENWIDTH

      frac += fracstep
      break unless count != 0
      count -= 1
    end
  end

  #
  # Creates the translation tables to map
  # the green color ramp to gray, brown, red.
  # Assumes a given structure of the PLAYPAL.
  # Could be read from a lump instead.
  #
  def self.r_init_translation_tables
    CDoom.translationtables = CDoom.z_malloc(256 * 3 + 255, CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Byte*)
    CDoom.translationtables = Pointer(CDoom::Byte).new((CDoom.translationtables.address + 255) & ~255)

    # translate just the 16 green colors
    256.times do |i|
      if i >= 0x70 && i <= 0x7f
        # map green ramp to gray, brown, red
        CDoom.translationtables[i] = 0x60_u8 + (i & 0xf)
        CDoom.translationtables[i + 256] = 0x40_u8 + (i & 0xf)
        CDoom.translationtables[i + 512] = 0x20_u8 + (i & 0xf)
      else
        # Keep all other colors as is.
        CDoom.translationtables[i] = i.to_u8!
        CDoom.translationtables[i + 256] = i.to_u8!
        CDoom.translationtables[i + 512] = i.to_u8!
      end
    end
  end

  #
  # With DOOM style restrictions on view orientation,
  # the floors and ceilings consist of horizontal slices
  # or spans with constant z depth.
  # However, rotation around the world z axis is possible,
  # thus this mapping, while simpler and faster than
  # perspective correct texture mapping, has to traverse
  # the texture at an angle in all but a few cases.
  # In consequence, flats are not stored by column (like walls),
  # and the inner loop has to step in texture space u and v.
  #

  #
  # Draws the actual span.
  #
  def self.r_draw_span
    {% if flag?("RANGECHECK") %}
      if CDoom.ds_x2 < CDoom.ds_x1 ||
         CDoom.ds_x1 < 0 ||
         CDoom.ds_x2 >= CDoom::SCREENWIDTH ||
         CDoom.ds_y.to_u32! > CDoom::SCREENHEIGHT
        CDoom.i_error("Error: r_draw_span: #{CDoom.ds_x1} to #{CDoom.ds_x2} at #{CDoom.ds_y}")
      end
    {% end %}

    xfrac = CDoom.ds_xfrac
    yfrac = CDoom.ds_yfrac

    dest = CDoom.ylookup[CDoom.ds_y] + CDoom.columnofs[CDoom.ds_x1]

    # We do not check for zero spans here?
    count = CDoom.ds_x2 - CDoom.ds_x1

    loop do
      # Current texture index in u,v
      spot = ((yfrac >> (16 - 6)) & (63 * 64)) + ((xfrac >> 16) & 63)

      # Lookup pixel from flat texture tile,
      #  re-index using light/colormap.
      dest.value = CDoom.ds_colormap[CDoom.ds_source[spot]]
      dest += 1

      # Next step in u,v.
      xfrac += CDoom.ds_xstep
      yfrac += CDoom.ds_ystep

      break unless count != 0
      count -= 1
    end
  end

  #
  # Creats lookup tables that avoid
  #  multiplies and other hazzles
  #  for getting the framebuffer address
  #  of a pixel to draw.
  #
  def self.r_init_buffer(width : LibC::Int, height : LibC::Int)
    # Handle resize,
    #  e.g. smaller view windows
    #  with border and/or status bar.
    CDoom.viewwindowx = (CDoom::SCREENWIDTH - width) >> 1

    # Column offset. For windows.
    width.times { |i| CDoom.columnofs[i] = CDoom.viewwindowx + i }

    # Samw with base row offset.
    if width == CDoom::SCREENWIDTH
      CDoom.viewwindowy = 0
    else
      CDoom.viewwindowy = (CDoom::SCREENHEIGHT - CDoom::SBARHEIGHT - height) >> 1
    end
    # Preclaculate all row offsets.
    screen = @@software_rendering ? CDoom.screens[0] : @@software_screen.to_unsafe
    height.times { |i| CDoom.ylookup[i] = screen + (i + CDoom.viewwindowy) * CDoom::SCREENWIDTH }
  end

  #
  # Fills the back screen with a pattern
  #  for variable screen sizes
  # Also draws a beveled edge.
  #
  def self.r_fill_back_screen
    # DOOM border patch.
    name1 = "FLOOR7_2"

    # DOOM II border patch.
    name2 = "GRNROCK"

    name : UInt8*

    return if CDoom.scaledviewwidth == 320

    if CDoom.gamemode == CDoom::GameMode::Commercial
      name = name2.to_unsafe
    else
      name = name1.to_unsafe
    end

    src = CDoom.w_cache_lump_name(name, CDoom::PU_CACHE).as(CDoom::Byte*)
    dest = CDoom.screens[1]

    (CDoom::SCREENHEIGHT - CDoom::SBARHEIGHT).times do |y|
      (CDoom::SCREENWIDTH // 64).times do |x|
        CDoom.doom_memcpy(dest, src + ((y & 63) << 6), 64)
        dest += 64
      end

      if CDoom::SCREENWIDTH & 63 != 0
        CDoom.doom_memcpy(dest, src + ((y & 63) << 6), CDoom::SCREENWIDTH & 63)
        dest += CDoom::SCREENWIDTH & 63
      end
    end

    patch = CDoom.w_cache_lump_name("brdr_t", CDoom::PU_CACHE).as(CDoom::Patch*)

    x = 0
    while x < CDoom.scaledviewwidth
      CDoom.v_draw_patch(CDoom.viewwindowx + x, CDoom.viewwindowy - 8, 1, patch)
      x += 8
    end
    patch = CDoom.w_cache_lump_name("brdr_b", CDoom::PU_CACHE).as(CDoom::Patch*)

    x = 0
    while x < CDoom.scaledviewwidth
      CDoom.v_draw_patch(CDoom.viewwindowx + x, CDoom.viewwindowy + CDoom.viewheight, 1, patch)
      x += 8
    end
    patch = CDoom.w_cache_lump_name("brdr_l", CDoom::PU_CACHE).as(CDoom::Patch*)

    y = 0
    while y < CDoom.viewheight
      CDoom.v_draw_patch(CDoom.viewwindowx - 8, CDoom.viewwindowy + y, 1, patch)
      y += 8
    end
    patch = CDoom.w_cache_lump_name("brdr_r", CDoom::PU_CACHE).as(CDoom::Patch*)

    y = 0
    while y < CDoom.viewheight
      CDoom.v_draw_patch(CDoom.viewwindowx + CDoom.scaledviewwidth, CDoom.viewwindowy + y, 1, patch)
      y += 8
    end

    # Draw beveled edge.
    CDoom.v_draw_patch(CDoom.viewwindowx - 8,
      CDoom.viewwindowy - 8,
      1,
      CDoom.w_cache_lump_name("brdr_tl", CDoom::PU_CACHE).as(CDoom::Patch*))

    CDoom.v_draw_patch(CDoom.viewwindowx + CDoom.scaledviewwidth,
      CDoom.viewwindowy - 8,
      1,
      CDoom.w_cache_lump_name("brdr_tr", CDoom::PU_CACHE).as(CDoom::Patch*))

    CDoom.v_draw_patch(CDoom.viewwindowx - 8,
      CDoom.viewwindowy + CDoom.viewheight,
      1,
      CDoom.w_cache_lump_name("brdr_bl", CDoom::PU_CACHE).as(CDoom::Patch*))

    CDoom.v_draw_patch(CDoom.viewwindowx + CDoom.scaledviewwidth,
      CDoom.viewwindowy + CDoom.viewheight,
      1,
      CDoom.w_cache_lump_name("brdr_br", CDoom::PU_CACHE).as(CDoom::Patch*))
  end

  #
  # Copy a screen buffer.
  #
  def self.r_video_erase(ofs : LibC::UInt, count : LibC::Int)
    # LFB copy.
    # This might not be a good idea if memcpy
    #  is not optiomal, e.g. byte by byte on
    #  a 32bit CPU, as GNU GCC/Linux libc did
    #  at one point.
    CDoom.doom_memcpy(CDoom.screens[0] + ofs, CDoom.screens[1] + ofs, count)
  end

  #
  # Draws the border around the view
  #  for different size windows?
  #
  def self.r_draw_view_border
    return if CDoom.scaledviewwidth == CDoom::SCREENWIDTH

    top = ((CDoom::SCREENHEIGHT - CDoom::SBARHEIGHT) - CDoom.viewheight) // 2
    side = (CDoom::SCREENWIDTH - CDoom.scaledviewwidth) // 2

    # copy top and one line of left side
    CDoom.r_video_erase(0, top * CDoom::SCREENWIDTH + side)

    # copy one line of right side and bottom
    ofs = (CDoom.viewheight + top) * CDoom::SCREENWIDTH - side
    CDoom.r_video_erase(ofs, top * CDoom::SCREENWIDTH + side)

    # copy sides using wraparound
    ofs = top * CDoom::SCREENWIDTH + CDoom::SCREENWIDTH - side
    side <<= 1

    i = 1
    while i < CDoom.viewheight
      CDoom.r_video_erase(ofs, side)
      ofs += CDoom::SCREENWIDTH

      i += 1
    end

    # ?
    CDoom.v_mark_rect(0, 0, CDoom::SCREENWIDTH, CDoom::SCREENHEIGHT - CDoom::SBARHEIGHT)
  end

  #
  # Expand a given bbox
  # so that it encloses a given point.
  #
  def self.r_add_point_to_box(x : LibC::Int, y : LibC::Int, box : CDoom::Fixed*)
    box[CDoom::BOXLEFT] = x if x < box[CDoom::BOXLEFT]
    box[CDoom::BOXRIGHT] = x if x > box[CDoom::BOXRIGHT]
    box[CDoom::BOXBOTTOM] = y if y < box[CDoom::BOXBOTTOM]
    box[CDoom::BOXTOP] = y if y > box[CDoom::BOXTOP]
  end

  #
  # Traverse BSP (sub) tree,
  #  check point against partition plane.
  # Returns side 0 (front) or 1 (back).
  #
  def self.r_point_on_side(x : CDoom::Fixed, y : CDoom::Fixed, node : CDoom::Node*) : LibC::Int
    if node.value.dx == 0
      return (node.value.dy > 0).to_unsafe if x <= node.value.x

      return (node.value.dy < 0).to_unsafe
    end
    if node.value.dy == 0
      return (node.value.dx < 0).to_unsafe if y <= node.value.y

      return (node.value.dx > 0).to_unsafe
    end

    dx = (x - node.value.x)
    dy = (y - node.value.y)

    # Try to quickly decide by looking at sign bits.
    if (node.value.dy ^ node.value.dx ^ dx ^ dy) & 0x80000000 != 0
      if (node.value.dy ^ dx) & 0x80000000 != 0
        # (left is negative)
        return 1
      end
      return 0
    end

    left = CDoom.fixed_mul(node.value.dy >> FRACBITS, dx)
    right = CDoom.fixed_mul(dy, node.value.dx >> FRACBITS)

    if right < left
      # front side
      return 0
    end
    # back side
    return 1
  end

  def self.r_point_on_seg_side(x : CDoom::Fixed, y : CDoom::Fixed, line : CDoom::Seg*) : LibC::Int
    lx = line.value.v1.value.x
    ly = line.value.v1.value.y

    ldx = line.value.v2.value.x - lx
    ldy = line.value.v2.value.y - ly

    if ldx == 0
      return (ldy > 0).to_unsafe if x <= lx

      return (ldy < 0).to_unsafe
    end
    if ldy == 0
      return (ldx < 0).to_unsafe if y <= ly

      return (ldx > 0).to_unsafe
    end

    dx = (x - lx)
    dy = (y - ly)

    # Try to quickly decide by looking at sign bits.
    if (ldy ^ ldx ^ dx ^ dy) & 0x80000000 != 0
      if (ldy ^ dx) & 0x80000000 != 0
        # (left is negative)
        return 1
      end
      return 0
    end

    left = CDoom.fixed_mul(ldy >> FRACBITS, dx)
    right = CDoom.fixed_mul(dy, ldx >> FRACBITS)

    if right < left
      # front side
      return 0
    end
    # back side
    return 1
  end

  #
  # To get a global angle from cartesian coordinates,
  #  the coordinates are flipped until they are in
  #  the first octant of the coordinate system, then
  #  the y (<=x) is scaled and divided by x to get a
  #  tangent (slope) value which is looked up in the
  #  tantoangle[] table.
  #
  def self.r_point_to_angle(x : CDoom::Fixed, y : CDoom::Fixed) : CDoom::Angle
    x -= CDoom.viewx
    y -= CDoom.viewy

    return 0_u32 if x == 0 && y == 0

    if x >= 0
      if y >= 0
        if x > y
          # octant 0
          return @@tantoangle[CDoom.slope_div(y, x)].to_u32!
        else
          # octant 1
          return (ANG90 &- 1 &- @@tantoangle[CDoom.slope_div(x, y)]).to_u32!
        end
      else
        y = -y

        if x > y
          # octant 8
          return (-(@@tantoangle[CDoom.slope_div(y, x)].to_i32!)).to_u32!
        else
          # octant 7
          return (ANG270 &+ @@tantoangle[CDoom.slope_div(x, y)]).to_u32!
        end
      end
    else
      x = -x

      if y >= 0
        if x > y
          # octant 3
          return (ANG180 &- 1 &- @@tantoangle[CDoom.slope_div(y, x)]).to_u32!
        else
          # octant 2
          return (ANG90 &+ @@tantoangle[CDoom.slope_div(x, y)]).to_u32!
        end
      else
        y = -y

        if x > y
          # octant 4
          return (ANG180 &+ @@tantoangle[CDoom.slope_div(y, x)]).to_u32!
        else
          # octant 5
          return (ANG270 &- 1 &- @@tantoangle[CDoom.slope_div(x, y)]).to_u32
        end
      end
    end

    return 0_u32
  end

  def self.r_point_to_angle2(x1 : CDoom::Fixed, y1 : CDoom::Fixed, x2 : CDoom::Fixed, y2 : CDoom::Fixed) : CDoom::Angle
    CDoom.viewx = x1
    CDoom.viewy = y1

    return CDoom.r_point_to_angle(x2, y2)
  end

  def self.r_point_to_dist(x : CDoom::Fixed, y : CDoom::Fixed) : CDoom::Fixed
    dx = doom_abs(x - CDoom.viewx)
    dy = doom_abs(y - CDoom.viewy)

    if dy > dx
      temp = dx
      dx = dy
      dy = temp
    end

    angle = (@@tantoangle[CDoom.fixed_div(dy, dx) >> DBITS] &+ ANG90) >> CDoom::ANGLETOFINESHIFT

    # use as cosine
    dist = CDoom.fixed_div(dx, @@finesine[angle])

    return dist
  end

  #
  # Returns the texture mapping scale
  #  for the current line (horizontal span)
  #  at the given angle.
  # rw_distance must be calculated first.
  #
  def self.r_scale_from_global_angle(visangle : CDoom::Angle) : CDoom::Fixed
    anglea = ANG90 &+ (visangle &- CDoom.viewangle)
    angleb = ANG90 &+ (visangle &- CDoom.rw_normalangle)

    # both sines are allways positive
    sinea = @@finesine[anglea >> CDoom::ANGLETOFINESHIFT]
    sineb = @@finesine[angleb >> CDoom::ANGLETOFINESHIFT]
    num = CDoom.fixed_mul(CDoom.projection, sineb)
    den = CDoom.fixed_mul(CDoom.rw_distance, sinea)

    if den > num >> 16
      scale = CDoom.fixed_div(num, den)

      if scale > 64 * FRACUNIT
        scale = 64 * FRACUNIT
      elsif scale < 256
        scale = 256
      end
    else
      scale = 64 * FRACUNIT
    end

    return scale
  end

  def self.r_init_tables
    {% unless flag?("PRECOMPUTED") %}
      # FINE TANGENT COMPUTE
      puts " - COMPUTE"
      print "         finetangent - ["
      ((FINETANGENT_SIZE + 255) // 256).times { |i| print " " }
      print "]"
      (((FINETANGENT_SIZE + 255) // 256) + 1).times { |i| print "\b" }

      FINETANGENT_SIZE.times do |i|
        print "." if i & 255 == 0

        deg = -90.0 + i * (180.0 / FINETANGENT_SIZE)
        rad = (i - FINEANGLES/4 + 0.5) * (2.0 * PI / FINEANGLES)
        val = Math.tan(rad) * FRACUNIT
        # clamp near the asymptotes instead of letting it blow up
        if val > Int32::MAX.to_f64
          @@finetangent << Int32::MAX
        elsif val < Int32::MIN.to_f64
          @@finetangent << Int32::MIN
        else
          @@finetangent << val.to_i32
        end
      end
      puts "]"

      # FINE SINE COMPUTE
      print "         finesine    - ["
      ((FINESINE_SIZE + 255) // 256).times { |i| print " " }
      print "]"
      (((FINESINE_SIZE + 255) // 256) + 1).times { |i| print "\b" }

      FINESINE_SIZE.times do |i|
        print "." if i & 255 == 0

        rad = (i + 0.5) * (2.0 * PI / FINEANGLES)
        @@finesine << (Math.sin(rad) * FRACUNIT).to_i32
      end
      puts "]"

      # TANTOANGLE COMPUTE
      print "         tantoangle  - ["
      ((TANTOANGLE_SIZE + 255) // 256).times { |i| print " " }
      print "]"
      (((TANTOANGLE_SIZE + 255) // 256) + 1).times { |i| print "\b" }

      TANTOANGLE_SIZE.times do |i|
        print "." if i & 255 == 0

        slope = i.to_f64 / SLOPERANGE
        rad = Math.atan(slope)
        @@tantoangle << (rad * (ANG180.to_f64 / PI)).to_u32
      end
      puts "]"
    {% else %}
      puts " - PRECOMPUTED"
    {% end %}

    @@finecosine = @@finesine.dup.rotate(FINEANGLES // 4)
  end

  def self.r_init_texture_mapping
    # Use tangent table to generate viewangletox:
    # viewangletox will give the next greatest x
    # after the view angle.
    #
    # Calc focallength
    # so FIELDOFVIEW angles covers SCREENWIDTH.
    focallength = CDoom.fixed_div(CDoom.centerxfrac,
      @@finetangent[CDoom::FINEANGLES // 4 + CDoom::FIELDOFVIEW // 2])

    (CDoom::FINEANGLES // 2).times do |i|
      if @@finetangent[i] > FRACUNIT * 2
        t = -1
      elsif @@finetangent[i] < -FRACUNIT * 2
        t = CDoom.viewwidth + 1
      else
        t = CDoom.fixed_mul(@@finetangent[i], focallength)
        t = (CDoom.centerxfrac - t + FRACUNIT - 1) >> FRACBITS

        if t < -1
          t = -1
        elsif t > CDoom.viewwidth + 1
          t = CDoom.viewwidth + 1
        end
      end
      CDoom.viewangletox[i] = t
    end

    # Scan viewangletox[] to generate xtoviewangle[]:
    # xtoviewangle will give the smallest view angle
    # that maps to x.
    x = 0
    while x <= CDoom.viewwidth
      i = 0
      while CDoom.viewangletox[i] > x
        i += 1
      end
      CDoom.xtoviewangle[x] = (i.to_u32! << CDoom::ANGLETOFINESHIFT) &- ANG90

      x += 1
    end

    # Take out the fencepost cases from viewangletox.
    (CDoom::FINEANGLES // 2).times do |i|
      t = CDoom.fixed_mul(@@finetangent[i], focallength)
      t = CDoom.centerx - t

      if CDoom.viewangletox[i] == -1
        CDoom.viewangletox[i] = 0
      elsif CDoom.viewangletox[i] == CDoom.viewwidth + 1
        CDoom.viewangletox[i] = CDoom.viewwidth
      end
    end

    CDoom.clipangle = CDoom.xtoviewangle[0]
  end

  #
  # Only inits the zlight table,
  # because the scalelight table changes with view size.
  #
  def self.r_init_light_tables
    # Calculate the light levels to use
    #  for each level / distance combination.
    CDoom::LIGHTLEVELS.times do |i|
      startmap = ((CDoom::LIGHTLEVELS - 1 - i) * 2) * CDoom::NUMCOLORMAPS // CDoom::LIGHTLEVELS
      CDoom::MAXLIGHTZ.times do |j|
        scale = CDoom.fixed_div((CDoom::SCREENWIDTH // 2 * FRACUNIT), (j + 1) << CDoom::LIGHTZSHIFT)
        scale >>= CDoom::LIGHTSCALESHIFT
        level = startmap - scale // CDoom::DISTMAP

        level = 0 if level < 0

        level = CDoom::NUMCOLORMAPS - 1 if level >= CDoom::NUMCOLORMAPS

        ((CDoom.zlight.to_unsafe + i).value.to_unsafe + j).value = CDoom.colormaps + level * 256
      end
    end
  end

  #
  # Do not really change anything here,
  #  because it might be in the middle of a refresh.
  # The change will take effect next refresh.
  #
  def self.r_set_view_size(blocks : LibC::Int, detail : LibC::Int)
    CDoom.setsizeneeded = 1
    CDoom.setblocks = blocks
    CDoom.setdetail = detail
  end

  def self.r_execute_set_view_size
    CDoom.setsizeneeded = 0

    if CDoom.setblocks == 11
      CDoom.scaledviewwidth = CDoom::SCREENWIDTH
      CDoom.viewheight = CDoom::SCREENHEIGHT
    else
      CDoom.scaledviewwidth = CDoom.setblocks * 32
      CDoom.viewheight = (CDoom.setblocks * 168 // 10) & ~7
    end

    CDoom.detailshift = CDoom.setdetail
    CDoom.viewwidth = CDoom.scaledviewwidth

    CDoom.centery = CDoom.viewheight // 2
    CDoom.centerx = CDoom.viewwidth // 2
    CDoom.centerxfrac = CDoom.centerx << FRACBITS
    CDoom.centeryfrac = CDoom.centery << FRACBITS
    CDoom.projection = CDoom.centerxfrac

    CDoom.colfunc = ->CDoom.r_draw_column

    CDoom.r_init_buffer(CDoom.scaledviewwidth, CDoom.viewheight)

    CDoom.r_init_texture_mapping

    # psprite scales
    CDoom.pspritescale = FRACUNIT * CDoom.viewwidth // CDoom::SCREENWIDTH
    CDoom.pspriteiscale = FRACUNIT * CDoom::SCREENWIDTH // CDoom.viewwidth

    # thing clipping
    CDoom.viewwidth.times { |i| CDoom.screenheightarray[i] = CDoom.viewheight.to_i16! }

    # planes
    CDoom.viewheight.times do |i|
      dy = ((i - CDoom.viewheight // 2) << FRACBITS) + FRACUNIT // 2
      dy = doom_abs(dy)
      CDoom.yslope[i] = CDoom.fixed_div(CDoom.viewwidth // 2 * FRACUNIT, dy)
    end

    CDoom.viewwidth.times do |i|
      cosadj = doom_abs(@@finecosine[CDoom.xtoviewangle[i] >> CDoom::ANGLETOFINESHIFT])
      CDoom.distscale[i] = CDoom.fixed_div(FRACUNIT, cosadj)
    end

    # Calculate the light levels to use
    #  for each level / scale combination.
    CDoom::LIGHTLEVELS.times do |i|
      startmap = ((CDoom::LIGHTLEVELS - 1 - i) * 2) * CDoom::NUMCOLORMAPS // CDoom::LIGHTLEVELS
      CDoom::MAXLIGHTSCALE.times do |j|
        level = startmap - j * CDoom::SCREENWIDTH // CDoom.viewwidth // CDoom::DISTMAP

        level = 0 if level < 0

        level = CDoom::NUMCOLORMAPS - 1 if level >= CDoom::NUMCOLORMAPS

        ((CDoom.scalelight.to_unsafe + i).value.to_unsafe + j).value = CDoom.colormaps + level * 256
      end
    end
  end

  def self.r_init
    # print "\nr_init_data"
    CDoom.r_init_data

    # viewwidth / viewheight / detailLevel are set by the defaults
    print "        Tables"
    CDoom.r_init_tables

    CDoom.r_set_view_size(CDoom.screenblocks, CDoom.detail_level)

    CDoom.r_init_light_tables
    CDoom.r_init_sky_map
    CDoom.r_init_translation_tables

    CDoom.framecount = 0
  end

  def self.r_point_in_subsector(x : CDoom::Fixed, y : CDoom::Fixed) : CDoom::Subsector*
    # single subsector is a special case
    return CDoom.subsectors if CDoom.numnodes == 0

    nodenum = CDoom.numnodes - 1

    while nodenum & CDoom::NF_SUBSECTOR == 0
      node = CDoom.nodes + nodenum
      side = CDoom.r_point_on_side(x, y, node)
      nodenum = node.value.children[side]
    end

    return CDoom.subsectors + (nodenum & ~CDoom::NF_SUBSECTOR)
  end

  def self.r_setup_frame(player : CDoom::Player*)
    CDoom.viewplayer = player
    CDoom.viewx = player.value.mo.value.x
    CDoom.viewy = player.value.mo.value.y
    CDoom.viewangle = player.value.mo.value.angle &+ CDoom.viewangleoffset
    CDoom.extralight = player.value.extralight

    CDoom.viewz = player.value.viewz

    CDoom.viewsin = @@finesine[CDoom.viewangle >> CDoom::ANGLETOFINESHIFT]
    CDoom.viewcos = @@finecosine[CDoom.viewangle >> CDoom::ANGLETOFINESHIFT]

    CDoom.sscount = 0

    if player.value.fixedcolormap != 0
      CDoom.fixedcolormap =
        CDoom.colormaps +
          player.value.fixedcolormap * 256 * sizeof(CDoom::Lighttable)

      CDoom.walllights = CDoom.scalelightfixed

      CDoom::MAXLIGHTSCALE.times { |i| CDoom.scalelightfixed[i] = CDoom.fixedcolormap }
    else
      CDoom.fixedcolormap = Pointer(CDoom::Lighttable).null
    end

    CDoom.framecount += 1
    CDoom.validcount += 1
  end

  def self.r_render_player_view(player : CDoom::Player*)
    @@software_screen.fill(255) unless @@software_rendering
    CDoom.r_setup_frame(player)

    # Clear buffers.
    CDoom.r_clear_clip_segs
    CDoom.r_clear_draw_segs
    CDoom.r_clear_planes
    CDoom.r_clear_sprites

    # check for new console commands.
    CDoom.net_update

    # The head node is the last node output.
    CDoom.r_render_bsp_node(CDoom.numnodes - 1)

    # Check for console commands.
    CDoom.net_update

    CDoom.r_draw_planes

    # Check for new console commands.
    CDoom.net_update

    CDoom.r_draw_masked

    # Check for new console commands.
    CDoom.net_update
  end

  #
  # Uses global vars:
  #  planeheight
  #  ds_source
  #  basexscale
  #  baseyscale
  #  viewx
  #  viewy
  #
  # BASIC PRIMITIVE
  #
  def self.r_map_plane(y : LibC::Int, x1 : LibC::Int, x2 : LibC::Int)
    {% if flag?("RANGECHECK") %}
      if x2 < x1 ||
         x1 < 0 ||
         x2 >= CDoom.viewwidth ||
         y.to_u32! > CDoom.viewheight.to_u32!
        CDoom.i_error("Error: r_map_plane: #{x1} to #{x2} at #{y}")
      end
    {% end %}

    if CDoom.planeheight != CDoom.cachedheight[y]
      CDoom.cachedheight[y] = CDoom.planeheight
      CDoom.cacheddistance[y] = CDoom.fixed_mul(CDoom.planeheight, CDoom.yslope[y])
      distance = CDoom.cacheddistance[y]
      CDoom.cachedxstep[y] = CDoom.fixed_mul(distance, CDoom.basexscale)
      CDoom.ds_xstep = CDoom.cachedxstep[y]
      CDoom.cachedystep[y] = CDoom.fixed_mul(distance, CDoom.baseyscale)
      CDoom.ds_ystep = CDoom.cachedystep[y]
    else
      distance = CDoom.cacheddistance[y]
      CDoom.ds_xstep = CDoom.cachedxstep[y]
      CDoom.ds_ystep = CDoom.cachedystep[y]
    end

    length = CDoom.fixed_mul(distance, CDoom.distscale[x1])
    angle = (CDoom.viewangle &+ CDoom.xtoviewangle[x1]) >> CDoom::ANGLETOFINESHIFT
    CDoom.ds_xfrac = CDoom.viewx &+ CDoom.fixed_mul(@@finecosine[angle], length)
    CDoom.ds_yfrac = -CDoom.viewy &- CDoom.fixed_mul(@@finesine[angle], length)

    if !CDoom.fixedcolormap.null?
      CDoom.ds_colormap = CDoom.fixedcolormap
    else
      index = distance.to_u32! >> CDoom::LIGHTZSHIFT

      index = CDoom::MAXLIGHTZ - 1 if index >= CDoom::MAXLIGHTZ

      CDoom.ds_colormap = CDoom.planezlight[index]
    end

    CDoom.ds_y = y
    CDoom.ds_x1 = x1
    CDoom.ds_x2 = x2

    CDoom.r_draw_span
  end

  #
  # At begining of frame.
  #
  def self.r_clear_planes
    # opening / clipping determination
    CDoom.viewwidth.times do |i|
      CDoom.floorclip[i] = CDoom.viewheight.to_i16!
      CDoom.ceilingclip[i] = -1
    end

    @@visplanes.clear
    @@visplanes << CDoom::Visplane.new
    @@lastvisplane = 0
    CDoom.lastopening = CDoom.openings

    # texture calculation
    CDoom.doom_memset(CDoom.cachedheight, 0, sizeof(typeof(CDoom.cachedheight)))

    # left to right mapping
    angle = (CDoom.viewangle &- ANG90) >> CDoom::ANGLETOFINESHIFT

    # scale will be unit scale at SCREENWIDTH/2 distance
    CDoom.basexscale = CDoom.fixed_div(@@finecosine[angle], CDoom.centerxfrac)
    CDoom.baseyscale = -CDoom.fixed_div(@@finesine[angle], CDoom.centerxfrac)
  end

  def self.r_find_plane(height : CDoom::Fixed, picnum : LibC::Int, lightlevel : LibC::Int) : Int32
    if picnum == CDoom.skyflatnum
      height = 0 # all skys map together
      lightlevel = 0
    end

    check = 0
    while check < @@lastvisplane
      if height == @@visplanes[check].height &&
         picnum == @@visplanes[check].picnum &&
         lightlevel == @@visplanes[check].lightlevel
        break
      end

      check += 1
    end

    return check if check < @@lastvisplane

    @@visplanes << CDoom::Visplane.new if @@lastvisplane == @@visplanes.size - 1

    @@lastvisplane = check + 1

    checkp = @@visplanes.to_unsafe + check
    checkp.value.height = height
    checkp.value.picnum = picnum
    checkp.value.lightlevel = lightlevel
    checkp.value.minx = CDoom::SCREENWIDTH
    checkp.value.maxx = -1

    CDoom.doom_memset(checkp.value.top, 0xff, sizeof(typeof(checkp.value.top)))

    return check
  end

  def self.r_check_plane(plv : Int32, start : LibC::Int, stop : LibC::Int) : Int32
  pl = @@visplanes.to_unsafe + plv

  if start < pl.value.minx
    intrl = pl.value.minx
    unionl = start
  else
    unionl = pl.value.minx
    intrl = start
  end

  if stop > pl.value.maxx
    intrh = pl.value.maxx
    unionh = stop
  else
    unionh = pl.value.maxx
    intrh = stop
  end

  x = intrl
  while x <= intrh
    break if pl.value.top[x] != 0xff
    x += 1
  end

  if x > intrh
    pl.value.minx = unionl
    pl.value.maxx = unionh

    # use the same one
    return plv
  end

  # make a new visplane
  @@visplanes << CDoom::Visplane.new if @@lastvisplane == @@visplanes.size - 1
  new_index = @@lastvisplane
  @@lastvisplane += 1

  src = @@visplanes.to_unsafe + plv        # re-derive after the push, not before
  dst = @@visplanes.to_unsafe + new_index
  dst.value.height = src.value.height
  dst.value.picnum = src.value.picnum
  dst.value.lightlevel = src.value.lightlevel
  dst.value.minx = start
  dst.value.maxx = stop

  CDoom.doom_memset(dst.value.top, 0xff, sizeof(typeof(dst.value.top)))

  new_index
end

  def self.r_make_spans(x : LibC::Int, t1 : LibC::Int, b1 : LibC::Int, t2 : LibC::Int, b2 : LibC::Int)
    while t1 < t2 && t1 <= b1
      CDoom.r_map_plane(t1, CDoom.spanstart[t1], x - 1)
      t1 += 1
    end
    while b1 > b2 && b1 >= t1
      CDoom.r_map_plane(b1, CDoom.spanstart[b1], x - 1)
      b1 -= 1
    end

    while t2 < t1 && t2 <= b2
      CDoom.spanstart[t2] = x
      t2 += 1
    end
    while b2 > b1 && b2 >= t2
      CDoom.spanstart[b2] = x
      b2 -= 1
    end
  end

  #
  # At the end of each frame.
  #
  def self.r_draw_planes
    {% if flag?("RANGECHECK") %}
      if CDoom.ds_p - CDoom.drawsegs.to_unsafe > CDoom::MAXDRAWSEGS
        CDoom.i_error("Error: r_draw_planes: drawsegs overflow (#{CDoom.ds_p - CDoom.drawsegs.to_unsafe})")
      end

      if @@lastvisplane > @@visplanes.size - 1
        CDoom.i_error("Error: r_draw_planes: visplane overflow (#{@@lastvisplane})")
      end

      if CDoom.lastopening - CDoom.openings.to_unsafe > CDoom::MAXOPENINGS
        CDoom.i_error("Error: r_draw_planes: opening overflow (#{CDoom.lastopening - CDoom.openings.to_unsafe})")
      end
    {% end %}

    pl = @@visplanes.to_unsafe
    while pl - @@visplanes.to_unsafe < @@lastvisplane
      if pl.value.minx > pl.value.maxx
        pl += 1
        next
      end

      # sky flat
      if pl.value.picnum == CDoom.skyflatnum
        CDoom.dc_iscale = CDoom.pspriteiscale

        # Sky is allways drawn full bright,
        #  i.e. colormaps[0] is used.
        # Because of this hack, sky is not affected
        #  by INVUL inverse mapping.
        CDoom.dc_colormap = CDoom.colormaps
        CDoom.dc_texturemid = CDoom.skytexturemid
        x = pl.value.minx
        while x <= pl.value.maxx
          CDoom.dc_yl = pl.value.top[x]
          CDoom.dc_yh = pl.value.bottom[x]

          if CDoom.dc_yl <= CDoom.dc_yh
            angle = (CDoom.viewangle &+ CDoom.xtoviewangle[x]) >> CDoom::ANGLETOSKYSHIFT
            CDoom.dc_x = x
            CDoom.dc_source = CDoom.r_get_column(CDoom.skytexture, angle)
            CDoom.colfunc.call
          end

          x += 1
        end
        pl += 1
        next
      end

      # regular flat
      CDoom.ds_source = CDoom.w_cache_lump_num(CDoom.firstflat +
                                               CDoom.flattranslation[pl.value.picnum],
        CDoom::PU_STATIC).as(CDoom::Byte*)

      CDoom.planeheight = doom_abs(pl.value.height - CDoom.viewz)
      light = (pl.value.lightlevel >> CDoom::LIGHTSEGSHIFT) + CDoom.extralight

      light = CDoom::LIGHTLEVELS - 1 if light >= CDoom::LIGHTLEVELS

      light = 0 if light < 0

      CDoom.planezlight = CDoom.zlight[light]

      (pl.value.top.to_unsafe + (pl.value.maxx + 1)).value = 0xff
      (pl.value.top.to_unsafe + (pl.value.minx - 1)).value = 0xff

      stop = pl.value.maxx + 1

      x = pl.value.minx
      while x <= stop
        CDoom.r_make_spans(x, (pl.value.top.to_unsafe + (x - 1)).value,
          (pl.value.bottom.to_unsafe + (x - 1)).value,
          (pl.value.top.to_unsafe + x).value,
          (pl.value.bottom.to_unsafe + x).value)

        x += 1
      end

      pl += 1
      z_change_tag(CDoom.ds_source, CDoom::PU_CACHE)
    end
  end

  def self.r_render_masked_seg_range(ds : CDoom::Drawseg*, x1 : LibC::Int, x2 : LibC::Int)
    # Calculate light table.
    # Use different light tables
    #   for horizontal / vertical / diagonal. Diagonal?
    # OPTIMIZE: get rid of LIGHTSEGSHIFT globally
    CDoom.curline = ds.value.curline
    CDoom.frontsector = CDoom.curline.value.frontsector
    CDoom.backsector = CDoom.curline.value.backsector
    texnum = CDoom.texturetranslation[CDoom.curline.value.sidedef.value.midtexture]

    lightnum = (CDoom.frontsector.value.lightlevel >> CDoom::LIGHTSEGSHIFT) + CDoom.extralight

    if CDoom.curline.value.v1.value.y == CDoom.curline.value.v2.value.y
      lightnum -= 1
    elsif CDoom.curline.value.v1.value.x == CDoom.curline.value.v2.value.x
      lightnum += 1
    end

    if lightnum < 0
      CDoom.walllights = CDoom.scalelight[0]
    elsif lightnum >= CDoom::LIGHTLEVELS
      CDoom.walllights = CDoom.scalelight[CDoom::LIGHTLEVELS - 1]
    else
      CDoom.walllights = CDoom.scalelight[lightnum]
    end

    CDoom.maskedtexturecol = ds.value.maskedtexturecol

    CDoom.rw_scalestep = ds.value.scalestep
    CDoom.spryscale = ds.value.scale1 + (x1 - ds.value.x1) * CDoom.rw_scalestep
    CDoom.mfloorclip = ds.value.sprbottomclip
    CDoom.mceilingclip = ds.value.sprtopclip

    # find positioning
    if CDoom.curline.value.linedef.value.flags & CDoom::ML_DONTPEGBOTTOM != 0
      CDoom.dc_texturemid = CDoom.frontsector.value.floorheight > CDoom.backsector.value.floorheight ? CDoom.frontsector.value.floorheight : CDoom.backsector.value.floorheight
      CDoom.dc_texturemid = CDoom.dc_texturemid + CDoom.textureheight[texnum] - CDoom.viewz
    else
      CDoom.dc_texturemid = CDoom.frontsector.value.ceilingheight < CDoom.backsector.value.ceilingheight ? CDoom.frontsector.value.ceilingheight : CDoom.backsector.value.ceilingheight
      CDoom.dc_texturemid = CDoom.dc_texturemid - CDoom.viewz
    end
    CDoom.dc_texturemid += CDoom.curline.value.sidedef.value.rowoffset

    CDoom.dc_colormap = CDoom.fixedcolormap if !CDoom.fixedcolormap.null?

    # draw the columns
    CDoom.dc_x = x1
    while CDoom.dc_x <= x2
      # calculate lighting
      if CDoom.maskedtexturecol[CDoom.dc_x] != Int16::MAX
        if CDoom.fixedcolormap.null?
          index = CDoom.spryscale >> CDoom::LIGHTSCALESHIFT

          index = CDoom::MAXLIGHTSCALE - 1 if index >= CDoom::MAXLIGHTSCALE

          CDoom.dc_colormap = CDoom.walllights[index]
        end

        CDoom.sprtopscreen = CDoom.centeryfrac - CDoom.fixed_mul(CDoom.dc_texturemid, CDoom.spryscale)
        CDoom.dc_iscale = 0xffffffff_u32 // CDoom.spryscale.to_u32!

        # draw the texture
        col = (CDoom.r_get_column(texnum, CDoom.maskedtexturecol[CDoom.dc_x]) - 3).as(CDoom::Column*)

        CDoom.r_draw_masked_column(col)
        CDoom.maskedtexturecol[CDoom.dc_x] = Int16::MAX
      end
      CDoom.spryscale += CDoom.rw_scalestep
      CDoom.dc_x += 1
    end
  end

  #
  # Draws zero, one, or two textures (and possibly a masked
  #  texture) for walls.
  # Can draw or mark the starting pixel of floor and ceiling
  #  textures.
  # CALLED: CORE LOOPING ROUTINE.
  #
  def self.r_render_seg_loop
    while CDoom.rw_x < CDoom.rw_stopx
      # mark floor / ceiling areas
      yl = (CDoom.topfrac + CDoom::HEIGHTUNIT - 1) >> CDoom::HEIGHTBITS

      # no space above wall?
      yl = CDoom.ceilingclip[CDoom.rw_x] + 1 if yl < CDoom.ceilingclip[CDoom.rw_x] + 1

      if CDoom.markceiling != 0
        top = CDoom.ceilingclip[CDoom.rw_x] + 1
        bottom = yl - 1

        bottom = CDoom.floorclip[CDoom.rw_x] - 1 if bottom >= CDoom.floorclip[CDoom.rw_x]

        if top <= bottom
          ((@@visplanes.to_unsafe + @@ceilingplane).value.top.to_unsafe + CDoom.rw_x).value = top.to_u8!
          ((@@visplanes.to_unsafe + @@ceilingplane).value.bottom.to_unsafe + CDoom.rw_x).value = bottom.to_u8!
        end
      end

      yh = CDoom.bottomfrac >> CDoom::HEIGHTBITS

      yh = CDoom.floorclip[CDoom.rw_x] - 1 if yh >= CDoom.floorclip[CDoom.rw_x]

      if CDoom.markfloor != 0
        top = yh + 1
        bottom = CDoom.floorclip[CDoom.rw_x] - 1
        top = CDoom.ceilingclip[CDoom.rw_x] + 1 if top <= CDoom.ceilingclip[CDoom.rw_x]
        if top <= bottom
          ((@@visplanes.to_unsafe + @@floorplane).value.top.to_unsafe + CDoom.rw_x).value = top.to_u8!
          ((@@visplanes.to_unsafe + @@floorplane).value.bottom.to_unsafe + CDoom.rw_x).value = bottom.to_u8!
        end
      end

      texturecolumn = 0

      # texturecolumn and lighting are independent of wall tiers
      if CDoom.segtextured != 0
        # calculate texture offset
        angle = (CDoom.rw_centerangle &+ CDoom.xtoviewangle[CDoom.rw_x]) >> CDoom::ANGLETOFINESHIFT
        angle = 0_u32 if angle >= (FINEANGLES.tdiv(2))
        texturecolumn = CDoom.rw_offset - CDoom.fixed_mul(@@finetangent[angle], CDoom.rw_distance)
        texturecolumn >>= FRACBITS
        # calculate lighting
        index = CDoom.rw_scale >> CDoom::LIGHTSCALESHIFT

        index = CDoom::MAXLIGHTSCALE - 1 if index >= CDoom::MAXLIGHTSCALE

        CDoom.dc_colormap = CDoom.walllights[index]
        CDoom.dc_x = CDoom.rw_x
        CDoom.dc_iscale = 0xffffffff_u32 // CDoom.rw_scale.to_u32!
      end

      # draw the wall tiers
      if CDoom.midtexture != 0
        # single sided line
        CDoom.dc_yl = yl
        CDoom.dc_yh = yh
        CDoom.dc_texturemid = CDoom.rw_midtexturemid
        CDoom.dc_source = CDoom.r_get_column(CDoom.midtexture, texturecolumn)
        CDoom.colfunc.call
        CDoom.ceilingclip[CDoom.rw_x] = CDoom.viewheight.to_i16!
        CDoom.floorclip[CDoom.rw_x] = -1
      else
        # two sided line
        if CDoom.toptexture != 0
          # top wall
          mid = CDoom.pixhigh >> CDoom::HEIGHTBITS
          CDoom.pixhigh += CDoom.pixhighstep

          mid = CDoom.floorclip[CDoom.rw_x] - 1 if mid >= CDoom.floorclip[CDoom.rw_x]

          if mid >= yl
            CDoom.dc_yl = yl
            CDoom.dc_yh = mid
            CDoom.dc_texturemid = CDoom.rw_toptexturemid
            CDoom.dc_source = CDoom.r_get_column(CDoom.toptexture, texturecolumn)
            CDoom.colfunc.call
            CDoom.ceilingclip[CDoom.rw_x] = mid.to_i16!
          else
            CDoom.ceilingclip[CDoom.rw_x] = yl.to_i16! - 1
          end
        else
          # no top wall
          CDoom.ceilingclip[CDoom.rw_x] = yl.to_i16! - 1 if CDoom.markceiling != 0
        end

        if CDoom.bottomtexture != 0
          # bottom wall
          mid = (CDoom.pixlow + CDoom::HEIGHTUNIT - 1) >> CDoom::HEIGHTBITS
          CDoom.pixlow += CDoom.pixlowstep

          # no space above wall?
          mid = CDoom.ceilingclip[CDoom.rw_x] + 1 if mid <= CDoom.ceilingclip[CDoom.rw_x]

          if mid <= yh
            CDoom.dc_yl = mid
            CDoom.dc_yh = yh
            CDoom.dc_texturemid = CDoom.rw_bottomtexturemid
            CDoom.dc_source = CDoom.r_get_column(CDoom.bottomtexture,
              texturecolumn)
            CDoom.colfunc.call
            CDoom.floorclip[CDoom.rw_x] = mid.to_i16!
          else
            CDoom.floorclip[CDoom.rw_x] = yh.to_i16! + 1
          end
        else
          # no bottom wall
          CDoom.floorclip[CDoom.rw_x] = yh.to_i16! + 1 if CDoom.markfloor != 0
        end

        if CDoom.maskedtexture != 0
          # save texturecol
          #  for backdrawing of masked mid texture
          CDoom.maskedtexturecol[CDoom.rw_x] = texturecolumn.to_i16!
        end
      end

      CDoom.rw_scale += CDoom.rw_scalestep
      CDoom.topfrac += CDoom.topstep
      CDoom.bottomfrac += CDoom.bottomstep

      CDoom.rw_x += 1
    end
  end

  #
  # A wall segment will be drawn
  #  between start and stop pixels (inclusive).
  #
  def self.r_store_wall_range(start : LibC::Int, stop : LibC::Int)
    # don't overflow and crash
    return if CDoom.ds_p == CDoom.drawsegs.to_unsafe + CDoom::MAXDRAWSEGS

    {% if flag?("RANGECHECK") %}
      if start >= CDoom.viewwidth || start > stop
        CDoom.i_error("Error: bad r_render_wall_range: #{start} to #{stop}")
      end
    {% end %}

    CDoom.sidedef = CDoom.curline.value.sidedef
    CDoom.linedef = CDoom.curline.value.linedef

    # mark the segment as visible for auto map
    CDoom.linedef.value.flags = CDoom.linedef.value.flags | CDoom::ML_MAPPED

    # calculate rw_distance for scale calculation
    CDoom.rw_normalangle = CDoom.curline.value.angle &+ ANG90
    offsetangle = CDoom.rw_normalangle &- CDoom.rw_angle1
    offsetangle = (-(offsetangle.to_i32!)).to_u32! if offsetangle > ANG180

    offsetangle = ANG90 if offsetangle > ANG90

    distangle = ANG90 &- offsetangle
    hyp = CDoom.r_point_to_dist(CDoom.curline.value.v1.value.x, CDoom.curline.value.v1.value.y)
    sineval = @@finesine[distangle >> CDoom::ANGLETOFINESHIFT]
    CDoom.rw_distance = CDoom.fixed_mul(hyp, sineval)

    CDoom.ds_p.value.x1 = start
    CDoom.rw_x = start
    CDoom.ds_p.value.x2 = stop
    CDoom.ds_p.value.curline = CDoom.curline
    CDoom.rw_stopx = stop + 1

    # calculate scale at both ends and step
    CDoom.ds_p.value.scale1 = CDoom.r_scale_from_global_angle(CDoom.viewangle &+ CDoom.xtoviewangle[start])
    CDoom.rw_scale = CDoom.ds_p.value.scale1

    if stop > start
      CDoom.ds_p.value.scale2 = CDoom.r_scale_from_global_angle(CDoom.viewangle &+ CDoom.xtoviewangle[stop])
      CDoom.ds_p.value.scalestep = (CDoom.ds_p.value.scale2 - CDoom.rw_scale).tdiv(stop - start)
      CDoom.rw_scalestep = CDoom.ds_p.value.scalestep
    else
      CDoom.ds_p.value.scale2 = CDoom.ds_p.value.scale1
    end

    # calculate texture boundaries
    #  and decide if floor / ceiling marks are needed
    CDoom.worldtop = CDoom.frontsector.value.ceilingheight - CDoom.viewz
    CDoom.worldbottom = CDoom.frontsector.value.floorheight - CDoom.viewz

    CDoom.midtexture = 0
    CDoom.toptexture = 0
    CDoom.bottomtexture = 0
    CDoom.maskedtexture = 0
    CDoom.ds_p.value.maskedtexturecol = Pointer(Int16).null

    if CDoom.backsector.null?
      # single sided line
      CDoom.midtexture = CDoom.texturetranslation[CDoom.sidedef.value.midtexture]
      # a single sided line is terminal, so it must mark ends
      CDoom.markfloor = 1
      CDoom.markceiling = 1
      if CDoom.linedef.value.flags & CDoom::ML_DONTPEGBOTTOM != 0
        vtop = CDoom.frontsector.value.floorheight +
               CDoom.textureheight[CDoom.sidedef.value.midtexture]
        # bottom of texture at bottom
        CDoom.rw_midtexturemid = vtop - CDoom.viewz
      else
        # top of texture at top
        CDoom.rw_midtexturemid = CDoom.worldtop
      end
      CDoom.rw_midtexturemid += CDoom.sidedef.value.rowoffset

      CDoom.ds_p.value.silhouette = CDoom::SIL_BOTH
      CDoom.ds_p.value.sprtopclip = CDoom.screenheightarray
      CDoom.ds_p.value.sprbottomclip = CDoom.negonearray
      CDoom.ds_p.value.bsilheight = Int32::MAX
      CDoom.ds_p.value.tsilheight = Int32::MIN
    else
      # two sided line
      CDoom.ds_p.value.sprtopclip = Pointer(Int16).null
      CDoom.ds_p.value.sprbottomclip = Pointer(Int16).null
      CDoom.ds_p.value.silhouette = 0

      if CDoom.frontsector.value.floorheight > CDoom.backsector.value.floorheight
        CDoom.ds_p.value.silhouette = CDoom::SIL_BOTTOM
        CDoom.ds_p.value.bsilheight = CDoom.frontsector.value.floorheight
      elsif CDoom.backsector.value.floorheight > CDoom.viewz
        CDoom.ds_p.value.silhouette = CDoom::SIL_BOTTOM
        CDoom.ds_p.value.bsilheight = Int32::MAX
      end

      if CDoom.frontsector.value.ceilingheight < CDoom.backsector.value.ceilingheight
        CDoom.ds_p.value.silhouette = CDoom.ds_p.value.silhouette | CDoom::SIL_TOP
        CDoom.ds_p.value.tsilheight = CDoom.frontsector.value.ceilingheight
      elsif CDoom.backsector.value.ceilingheight < CDoom.viewz
        CDoom.ds_p.value.silhouette = CDoom.ds_p.value.silhouette | CDoom::SIL_TOP
        CDoom.ds_p.value.tsilheight = Int32::MIN
      end

      if CDoom.backsector.value.ceilingheight <= CDoom.frontsector.value.floorheight
        CDoom.ds_p.value.sprbottomclip = CDoom.negonearray
        CDoom.ds_p.value.bsilheight = Int32::MAX
        CDoom.ds_p.value.silhouette = CDoom.ds_p.value.silhouette | CDoom::SIL_BOTTOM
      end

      if CDoom.backsector.value.floorheight >= CDoom.frontsector.value.ceilingheight
        CDoom.ds_p.value.sprtopclip = CDoom.screenheightarray
        CDoom.ds_p.value.tsilheight = Int32::MIN
        CDoom.ds_p.value.silhouette = CDoom.ds_p.value.silhouette | CDoom::SIL_TOP
      end

      CDoom.worldhigh = CDoom.backsector.value.ceilingheight - CDoom.viewz
      CDoom.worldlow = CDoom.backsector.value.floorheight - CDoom.viewz

      # hack to allow height changes in outdoor areas
      if CDoom.frontsector.value.ceilingpic == CDoom.skyflatnum &&
         CDoom.backsector.value.ceilingpic == CDoom.skyflatnum
        CDoom.worldtop = CDoom.worldhigh
      end

      if CDoom.worldlow != CDoom.worldbottom ||
         CDoom.backsector.value.floorpic != CDoom.frontsector.value.floorpic ||
         CDoom.backsector.value.lightlevel != CDoom.frontsector.value.lightlevel
        CDoom.markfloor = 1
      else
        # same plane on both sides
        CDoom.markfloor = 0
      end

      if CDoom.worldhigh != CDoom.worldtop ||
         CDoom.backsector.value.ceilingpic != CDoom.frontsector.value.ceilingpic ||
         CDoom.backsector.value.lightlevel != CDoom.frontsector.value.lightlevel
        CDoom.markceiling = 1
      else
        # same plane on both sides
        CDoom.markceiling = 0
      end

      if CDoom.backsector.value.ceilingheight <= CDoom.frontsector.value.floorheight ||
         CDoom.backsector.value.floorheight >= CDoom.frontsector.value.ceilingheight
        # closed door
        CDoom.markceiling = 1
        CDoom.markfloor = 1
      end

      if CDoom.worldhigh < CDoom.worldtop
        # top texture
        CDoom.toptexture = CDoom.texturetranslation[CDoom.sidedef.value.toptexture]
        if CDoom.linedef.value.flags & CDoom::ML_DONTPEGTOP != 0
          # top of texture at top
          CDoom.rw_toptexturemid = CDoom.worldtop
        else
          vtop = CDoom.backsector.value.ceilingheight + CDoom.textureheight[CDoom.sidedef.value.toptexture]
          # bottom of texture
          CDoom.rw_toptexturemid = vtop - CDoom.viewz
        end
      end
      if CDoom.worldlow > CDoom.worldbottom
        # bottom texture
        CDoom.bottomtexture = CDoom.texturetranslation[CDoom.sidedef.value.bottomtexture]
        if CDoom.linedef.value.flags & CDoom::ML_DONTPEGBOTTOM != 0
          # bottom of texture at bottom
          # top of texture at top
          CDoom.rw_bottomtexturemid = CDoom.worldtop
        else # top of texture at top
          CDoom.rw_bottomtexturemid = CDoom.worldlow
        end
      end
      CDoom.rw_toptexturemid &+= CDoom.sidedef.value.rowoffset
      CDoom.rw_bottomtexturemid &+= CDoom.sidedef.value.rowoffset

      # allocate space for masked texture tables
      if CDoom.sidedef.value.midtexture != 0
        CDoom.maskedtexture = 1
        CDoom.ds_p.value.maskedtexturecol = CDoom.lastopening - CDoom.rw_x
        CDoom.maskedtexturecol = CDoom.ds_p.value.maskedtexturecol
        CDoom.lastopening += CDoom.rw_stopx - CDoom.rw_x
      end
    end

    # calculate rw_offset (only needed for textured lines)
    CDoom.segtextured = CDoom.midtexture | CDoom.toptexture | CDoom.bottomtexture | CDoom.maskedtexture

    if CDoom.segtextured != 0
      offsetangle = CDoom.rw_normalangle &- CDoom.rw_angle1

      offsetangle = (-(offsetangle.to_i32!)).to_u32! if offsetangle > ANG180

      offsetangle = ANG90 if offsetangle > ANG90

      sineval = @@finesine[offsetangle >> CDoom::ANGLETOFINESHIFT]
      CDoom.rw_offset = CDoom.fixed_mul(hyp, sineval)

      CDoom.rw_offset = -CDoom.rw_offset if CDoom.rw_normalangle &- CDoom.rw_angle1 < ANG180

      CDoom.rw_offset += CDoom.sidedef.value.textureoffset + CDoom.curline.value.offset
      CDoom.rw_centerangle = ANG90 &+ CDoom.viewangle &- CDoom.rw_normalangle

      # calculate light table
      #  use different light tables
      #  for horizontal / vertical / diagonal
      # OPTIMIZE: get rid of LIGHTSEGSHIFT globally
      if CDoom.fixedcolormap.null?
        lightnum = (CDoom.frontsector.value.lightlevel >> CDoom::LIGHTSEGSHIFT) + CDoom.extralight

        if CDoom.curline.value.v1.value.y == CDoom.curline.value.v2.value.y
          lightnum -= 1
        elsif CDoom.curline.value.v1.value.x == CDoom.curline.value.v2.value.x
          lightnum += 1
        end

        if lightnum < 0
          CDoom.walllights = CDoom.scalelight[0]
        elsif lightnum >= CDoom::LIGHTLEVELS
          CDoom.walllights = CDoom.scalelight[CDoom::LIGHTLEVELS - 1]
        else
          CDoom.walllights = CDoom.scalelight[lightnum]
        end
      end
    end

    # if a floor / ceiling plane is on the wrong side
    #  of the view plane, it is definitely invisible
    #  and doesn't need to be marked.

    if CDoom.frontsector.value.floorheight >= CDoom.viewz
      # above view plane
      CDoom.markfloor = 0
    end

    if CDoom.frontsector.value.ceilingheight <= CDoom.viewz &&
       CDoom.frontsector.value.ceilingpic != CDoom.skyflatnum
      # below view plane
      CDoom.markceiling = 0
    end

    # calculate incremental stepping values for texture edges
    CDoom.worldtop >>= 4
    CDoom.worldbottom >>= 4

    CDoom.topstep = -CDoom.fixed_mul(CDoom.rw_scalestep, CDoom.worldtop)
    CDoom.topfrac = (CDoom.centeryfrac >> 4) - CDoom.fixed_mul(CDoom.worldtop, CDoom.rw_scale)

    CDoom.bottomstep = -CDoom.fixed_mul(CDoom.rw_scalestep, CDoom.worldbottom)
    CDoom.bottomfrac = (CDoom.centeryfrac >> 4) - CDoom.fixed_mul(CDoom.worldbottom, CDoom.rw_scale)

    if !CDoom.backsector.null?
      CDoom.worldhigh >>= 4
      CDoom.worldlow >>= 4

      if CDoom.worldhigh < CDoom.worldtop
        CDoom.pixhigh = (CDoom.centeryfrac >> 4) - CDoom.fixed_mul(CDoom.worldhigh, CDoom.rw_scale)
        CDoom.pixhighstep = -CDoom.fixed_mul(CDoom.rw_scalestep, CDoom.worldhigh)
      end

      if CDoom.worldlow > CDoom.worldbottom
        CDoom.pixlow = (CDoom.centeryfrac >> 4) - CDoom.fixed_mul(CDoom.worldlow, CDoom.rw_scale)
        CDoom.pixlowstep = -CDoom.fixed_mul(CDoom.rw_scalestep, CDoom.worldlow)
      end
    end

    # render it
    @@ceilingplane = r_check_plane(@@ceilingplane, CDoom.rw_x, CDoom.rw_stopx - 1) if CDoom.markceiling != 0

    @@floorplane = r_check_plane(@@floorplane, CDoom.rw_x, CDoom.rw_stopx - 1) if CDoom.markfloor != 0

    CDoom.r_render_seg_loop

    # save sprite clipping info
    if ((CDoom.ds_p.value.silhouette & CDoom::SIL_TOP != 0) || CDoom.maskedtexture != 0) &&
       CDoom.ds_p.value.sprtopclip.null?
      CDoom.doom_memcpy(CDoom.lastopening, CDoom.ceilingclip.to_unsafe + start, 2 * (CDoom.rw_stopx - start))
      CDoom.ds_p.value.sprtopclip = CDoom.lastopening - start
      CDoom.lastopening += CDoom.rw_stopx - start
    end

    if ((CDoom.ds_p.value.silhouette & CDoom::SIL_BOTTOM != 0) || CDoom.maskedtexture != 0) &&
       CDoom.ds_p.value.sprbottomclip.null?
      CDoom.doom_memcpy(CDoom.lastopening, CDoom.floorclip.to_unsafe + start, 2 * (CDoom.rw_stopx - start))
      CDoom.ds_p.value.sprbottomclip = CDoom.lastopening - start
      CDoom.lastopening += CDoom.rw_stopx - start
    end

    if CDoom.maskedtexture != 0 && CDoom.ds_p.value.silhouette & CDoom::SIL_TOP == 0
      CDoom.ds_p.value.silhouette = CDoom.ds_p.value.silhouette | CDoom::SIL_TOP
      CDoom.ds_p.value.tsilheight = Int32::MIN
    end
    if CDoom.maskedtexture != 0 && CDoom.ds_p.value.silhouette & CDoom::SIL_BOTTOM == 0
      CDoom.ds_p.value.silhouette = CDoom.ds_p.value.silhouette | CDoom::SIL_BOTTOM
      CDoom.ds_p.value.bsilheight = Int32::MAX
    end
    CDoom.ds_p += 1
  end

  #
  # Called whenever the view size changes.
  #
  def self.r_init_sky_map
    CDoom.skytexturemid = 100 * FRACUNIT
  end

  #
  # INITIALIZATION FUNCTIONS
  #

  #
  # Local function for R_InitSprites.
  #
  def self.r_install_sprite_lump(lump : LibC::Int, frame : LibC::UInt, rotation : LibC::UInt, flipped : CDoom::DoomBool)
    if frame >= 29 || rotation > 8
      CDoom.i_error("Error: r_install_sprite_lump: Bad frame characters in lump #{lump}")
    end

    CDoom.maxframe = frame if frame.to_i32! > CDoom.maxframe

    if rotation == 0
      # the lump should be used for all rotations
      if CDoom.sprtemp[frame].rotate == 0
        STDERR.puts "Warning: r_install_sprite_lump: Sprite  #{String.new(CDoom.spritename)} frame #{'A' + frame} has multip rot=0 lump, using lump #{lump}"
      end

      if CDoom.sprtemp[frame].rotate == 1
        STDERR.puts "Warning: r_install_sprite_lump: Sprite  #{String.new(CDoom.spritename)} frame #{'A' + frame} has rotations, overriding with rot=0 lump #{lump}"
      end

      (CDoom.sprtemp.to_unsafe + frame).value.rotate = 0
      8.times do |r|
        ((CDoom.sprtemp.to_unsafe + frame).value.lump.to_unsafe + r).value = (lump - CDoom.firstspritelump).to_i16!
        ((CDoom.sprtemp.to_unsafe + frame).value.flip.to_unsafe + r).value = flipped.to_u8!
      end
      return
    end

    # the lump is only used for one rotation
    if CDoom.sprtemp[frame].rotate == 0
      STDERR.puts "Warning: r_install_sprite_lump: Sprite  #{String.new(CDoom.spritename)} frame #{'A' + frame} has rotations, but a rot=0 lump was already set; discarding it"
      # Reset to the -1 "unset" sentinel (matches sprtemp's initial memset) so
      # partial per-rotation data can take over cleanly instead of leaving
      # stale rot=0 lump indices (which could otherwise look like valid,
      # already-filled rotation slots and silently mask missing rotations).
      8.times do |r|
        ((CDoom.sprtemp.to_unsafe + frame).value.lump.to_unsafe + r).value = -1_i16
      end
    end

    (CDoom.sprtemp.to_unsafe + frame).value.rotate = 1

    # make - based
    rotation -= 1
    if CDoom.sprtemp[frame].lump[rotation] != -1
      STDERR.puts "Warning: r_install_sprite_lump: Sprite #{String.new(CDoom.spritename)} : #{'A' + frame} : #{'1' + rotation} has two lumps mapped to it, using lump #{lump}"
    end

    ((CDoom.sprtemp.to_unsafe + frame).value.lump.to_unsafe + rotation).value = (lump - CDoom.firstspritelump).to_i16!
    ((CDoom.sprtemp.to_unsafe + frame).value.flip.to_unsafe + rotation).value = flipped.to_u8!
  end

  #
  # Pass a null terminated list of sprite names
  #  (4 chars exactly) to be used.
  # Builds the sprite rotation matrixes to account
  #  for horizontally flipped sprites.
  # Will report an error if the lumps are inconsistant.
  # Only called at startup.
  #
  # Sprite lump names are 4 characters for the actor,
  #  a letter for the frame, and a number for the rotation.
  # A sprite that is flippable will have an additional
  #  letter/number appended.
  # The rotation character can be 0 to signify no rotations.
  #
  def self.r_init_sprite_defs(namelist : LibC::Char**)
    # count the number of sprite names
    check = namelist

    while !check.value.null?
      check += 1
    end

    CDoom.numsprites = check - namelist

    return if CDoom.numsprites == 0

    CDoom.sprites = CDoom.z_malloc(CDoom.numsprites * sizeof(CDoom::Spritedef), CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Spritedef*)

    start = CDoom.firstspritelump - 1
    endl = CDoom.lastspritelump + 1

    # scan all the lump names for each of the names,
    #  noting the highest frame letter.
    # Just compare 4 characters as ints
    CDoom.numsprites.times do |i|
      CDoom.spritename = namelist[i]
      CDoom.doom_memset(CDoom.sprtemp, -1, sizeof(typeof(CDoom.sprtemp)))
      CDoom.maxframe = -1
      intname = namelist[i].as(Int32*).value

      # scan the lumps,
      #  filling in the frames for whatever is found
      l = start + 1
      while l < endl
        if @@lumpinfo[l].name.to_unsafe.as(Int32*).value == intname
          frame = @@lumpinfo[l].name[4] - 'A'.ord
          rotation = @@lumpinfo[l].name[5] - '0'.ord

          if CDoom.modifiedgame != 0
            patched = CDoom.w_get_num_for_name(@@lumpinfo[l].name)
          else
            patched = l
          end

          CDoom.r_install_sprite_lump(patched, frame, rotation, 0)

          if @@lumpinfo[l].name[6] != 0
            frame = @@lumpinfo[l].name[6] - 'A'.ord
            rotation = @@lumpinfo[l].name[7] - '0'.ord
            CDoom.r_install_sprite_lump(l, frame, rotation, 1)
          end
        end

        l += 1
      end

      # check the frames that were found for completeness
      if CDoom.maxframe == -1
        CDoom.sprites[i].numframes = 0
        next
      end

      CDoom.maxframe += 1

      CDoom.maxframe.times do |frame|
        case CDoom.sprtemp[frame].rotate
        when -1
          CDoom.i_error("Error: r_init_sprite_defs: No patches found for #{String.new(namelist[i])} frame #{'A' + frame}")
        when 0
          # only the first rotation is needed
        when 1
          # must have all 8 frames
          8.times do |rotation|
            if CDoom.sprtemp[frame].lump[rotation] == -1
              CDoom.i_error("Error: r_init_sprite_defs: Sprite #{String.new(namelist[i])} frame #{'A' + frame} is missing rotations")
            end
          end
        end
      end

      # allocate space for the frames present and copy sprtemp to it
      (CDoom.sprites + i).value.numframes = CDoom.maxframe
      (CDoom.sprites + i).value.spriteframes =
        CDoom.z_malloc(CDoom.maxframe * sizeof(CDoom::Spriteframe), CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Spriteframe*)
      CDoom.doom_memcpy(CDoom.sprites[i].spriteframes, CDoom.sprtemp, CDoom.maxframe * sizeof(CDoom::Spriteframe))
    end
  end

  #
  # GAME FUNCTIONS
  #

  #
  # Called at program start.
  #
  def self.r_init_sprites(namelist : LibC::Char**)
    CDoom::SCREENWIDTH.times { |i| CDoom.negonearray[i] = -1 }
    CDoom.r_init_sprite_defs(namelist)
  end

  #
  # Called at frame start.
  #
  def self.r_clear_sprites
    CDoom.vissprite_p = CDoom.vissprites.to_unsafe
  end

  def self.r_new_vis_sprite : CDoom::Vissprite*
    return pointerof(CDoom.overflowsprite) if CDoom.vissprite_p == CDoom.vissprites.to_unsafe + CDoom::MAXVISSPRITES

    CDoom.vissprite_p += 1
    return CDoom.vissprite_p - 1
  end

  #
  # Used for sprites and masked mid textures.
  # Masked means: partly transparent, i.e. stored
  #  in posts/runs of opaque pixels.
  #
  def self.r_draw_masked_column(column : CDoom::Column*)
    basetexturemid = CDoom.dc_texturemid

    until column.value.topdelta == 0xff
      # calculate unclipped screen coordinates
      #  for post
      topscreen = CDoom.sprtopscreen + CDoom.spryscale * column.value.topdelta
      bottomscreen = topscreen + CDoom.spryscale * column.value.length

      CDoom.dc_yl = (topscreen + FRACUNIT - 1) >> FRACBITS
      CDoom.dc_yh = (bottomscreen - 1) >> FRACBITS

      CDoom.dc_yh = CDoom.mfloorclip[CDoom.dc_x] - 1 if CDoom.dc_yh >= CDoom.mfloorclip[CDoom.dc_x]
      CDoom.dc_yl = CDoom.mceilingclip[CDoom.dc_x] + 1 if CDoom.dc_yl <= CDoom.mceilingclip[CDoom.dc_x]

      if CDoom.dc_yl <= CDoom.dc_yh
        CDoom.dc_source = column.as(UInt8*) + 3
        CDoom.dc_texturemid = basetexturemid - (column.value.topdelta.to_i32 << FRACBITS)

        # Drawn by either r_draw_column
        #  or (SHADOW) r_draw_fuzz_column
        CDoom.colfunc.call
      end
      column = (column.as(UInt8*) + column.value.length + 4).as(CDoom::Column*)
    end
    CDoom.dc_texturemid = basetexturemid
  end

  def self.r_draw_vis_sprite(vis : CDoom::Vissprite*, x1 : LibC::Int, x2 : LibC::Int)
    patch = CDoom.w_cache_lump_num(vis.value.patch + CDoom.firstspritelump, CDoom::PU_CACHE).as(CDoom::Patch*)

    CDoom.dc_colormap = vis.value.colormap

    if CDoom.dc_colormap.null?
      # 0 colormap = shadow draw
      CDoom.colfunc = ->CDoom.r_draw_fuzz_column
    elsif vis.value.mobjflags & CDoom::Mobjflag::MF_TRANSLATION.value != 0
      CDoom.colfunc = ->CDoom.r_draw_translated_column
      CDoom.dc_translation = CDoom.translationtables - 256 +
                             ((vis.value.mobjflags & CDoom::Mobjflag::MF_TRANSLATION.value) >> (CDoom::Mobjflag::MF_TRANSSHIFT.value - 8))
    end

    CDoom.dc_iscale = doom_abs(vis.value.xiscale)
    CDoom.dc_texturemid = vis.value.texturemid
    frac = vis.value.startfrac
    CDoom.spryscale = vis.value.scale
    CDoom.sprtopscreen = CDoom.centeryfrac - CDoom.fixed_mul(CDoom.dc_texturemid, CDoom.spryscale)

    CDoom.dc_x = vis.value.x1
    while CDoom.dc_x <= vis.value.x2
      texturecolumn = frac >> FRACBITS
      {% if flag?("RANGECHECK") %}
        if texturecolumn < 0 || texturecolumn >= patch.value.width
          CDoom.i_error("Error: r_draw_vis_sprite: bad texturecolumn")
        end
      {% end %}
      column = (patch.as(UInt8*) + (patch.value.columnofs.to_unsafe + texturecolumn).value).as(CDoom::Column*)
      CDoom.r_draw_masked_column(column)

      CDoom.dc_x += 1
      frac += vis.value.xiscale
    end

    CDoom.colfunc = ->CDoom.r_draw_column
  end

  #
  # Generates a vissprite for a thing
  #  if it might be visible.
  #
  def self.r_project_sprite(thing : CDoom::Mobj*)
    return if thing.value.sprite == CDoom::Spritenum::SPR_TNT

    # transform the origin point
    tr_x = thing.value.x - CDoom.viewx
    tr_y = thing.value.y - CDoom.viewy

    gxt = CDoom.fixed_mul(tr_x, CDoom.viewcos)
    gyt = -CDoom.fixed_mul(tr_y, CDoom.viewsin)

    tz = gxt - gyt

    # thing is behind view plane?
    return if tz < CDoom::MINZ

    xscale = CDoom.fixed_div(CDoom.projection, tz)

    gxt = -CDoom.fixed_mul(tr_x, CDoom.viewsin)
    gyt = CDoom.fixed_mul(tr_y, CDoom.viewcos)
    tx = -(gyt + gxt)

    # too far off the side?
    return if doom_abs(tx) > (tz << 2)

    # decide which patch to use for sprite relative to player
    {% if flag?("RANGECHECK") %}
      if thing.value.sprite.to_u32! >= CDoom.numsprites.to_u32!
        CDoom.i_error("Error: r_project_sprite: invalid sprite number #{thing.value.sprite.value} ")
      end
    {% end %}
    sprdef = CDoom.sprites + thing.value.sprite.value
    {% if flag?("RANGECHECK") %}
      if thing.value.frame & CDoom::FF_FRAMEMASK >= sprdef.value.numframes
        CDoom.i_error("Error: r_project_sprite: invalid sprite frame #{thing.value.sprite.value} : #{thing.value.frame} ")
      end
    {% end %}
    sprframe = sprdef.value.spriteframes + (thing.value.frame & CDoom::FF_FRAMEMASK)

    if sprframe.value.rotate != 0
      # choose a different rotation based on player view
      ang = CDoom.r_point_to_angle(thing.value.x, thing.value.y)
      rot = (ang &- thing.value.angle &+ (ANG45.tdiv(2)).to_u32! * 9) >> 29
      lump = sprframe.value.lump[rot]
      flip = sprframe.value.flip[rot]
    else
      # use single rotation for all views
      lump = sprframe.value.lump[0]
      flip = sprframe.value.flip[0]
    end

    # calculate edges of the shape
    tx -= CDoom.spriteoffset[lump]
    x1 = (CDoom.centerxfrac + CDoom.fixed_mul(tx, xscale)) >> FRACBITS

    # off the right side?
    return if x1 > CDoom.viewwidth

    tx += CDoom.spritewidth[lump]
    x2 = ((CDoom.centerxfrac + CDoom.fixed_mul(tx, xscale)) >> FRACBITS) - 1

    # off the left side
    return if x2 < 0

    # store information in a vissprite
    vis = CDoom.r_new_vis_sprite
    vis.value.mobjflags = thing.value.flags
    vis.value.scale = xscale
    vis.value.gx = thing.value.x
    vis.value.gy = thing.value.y
    vis.value.gz = thing.value.z
    vis.value.gzt = thing.value.z + CDoom.spritetopoffset[lump]
    vis.value.texturemid = vis.value.gzt - CDoom.viewz
    vis.value.x1 = x1 < 0 ? 0 : x1
    vis.value.x2 = x2 >= CDoom.viewwidth ? CDoom.viewwidth - 1 : x2
    iscale = CDoom.fixed_div(FRACUNIT, xscale)

    if flip != 0
      vis.value.startfrac = CDoom.spritewidth[lump] - 1
      vis.value.xiscale = -iscale
    else
      vis.value.startfrac = 0
      vis.value.xiscale = iscale
    end

    if vis.value.x1 > x1
      vis.value.startfrac = vis.value.startfrac + vis.value.xiscale * (vis.value.x1 - x1)
    end
    vis.value.patch = lump

    # get light level
    if thing.value.flags & CDoom::Mobjflag::MF_SHADOW.value != 0
      # shadow draw
      vis.value.colormap = Pointer(CDoom::Lighttable).null
    elsif !CDoom.fixedcolormap.null?
      # fixed map
      vis.value.colormap = CDoom.fixedcolormap
    elsif thing.value.frame & CDoom::FF_FULLBRIGHT != 0
      # full bright
      vis.value.colormap = CDoom.colormaps
    else
      # diminished light
      index = xscale >> CDoom::LIGHTSCALESHIFT

      index = CDoom::MAXLIGHTSCALE - 1 if index >= CDoom::MAXLIGHTSCALE

      vis.value.colormap = CDoom.spritelights[index]
    end
  end

  #
  # During BSP traversal, this adds sprites by sector.
  #
  def self.r_add_sprites(sec : CDoom::Sector*)
    # BSP is traversed by subsector.
    # A sector might have been split into several
    #  subsectors during BSP building.
    # Thus we check whether its already added.
    return if sec.value.validcount == CDoom.validcount

    # Well, now it will be done.
    sec.value.validcount = CDoom.validcount

    lightnum = (sec.value.lightlevel >> CDoom::LIGHTSEGSHIFT) + CDoom.extralight

    if lightnum < 0
      CDoom.spritelights = CDoom.scalelight[0]
    elsif lightnum >= CDoom::LIGHTLEVELS
      CDoom.spritelights = CDoom.scalelight[CDoom::LIGHTLEVELS - 1]
    else
      CDoom.spritelights = CDoom.scalelight[lightnum]
    end

    # Handle all things in sector.
    thing = sec.value.thinglist
    until thing.null?
      CDoom.r_project_sprite(thing)
      thing = thing.value.snext
    end
  end

  def self.r_draw_psprite(psp : CDoom::Pspdef*)
    return if psp.value.state.value.sprite == CDoom::Spritenum::SPR_TNT

    # decide which patch to use
    {% if flag?("RANGECHECK") %}
      if psp.value.state.value.sprite.value >= CDoom.numsprites
        CDoom.i_error("Error: r_draw_psprite: invalid sprite number #{psp.value.state.value.sprite.value} ")
      end
    {% end %}
    sprdef = CDoom.sprites + psp.value.state.value.sprite.value
    {% if flag?("RANGECHECK") %}
      if psp.value.state.value.frame & CDoom::FF_FRAMEMASK >= sprdef.value.numframes
        CDoom.i_error("Error: r_draw_psprite: invalid sprite frame #{psp.value.state.value.sprite.value} : #{psp.value.state.value.frame} ")
      end
    {% end %}
    sprframe = sprdef.value.spriteframes + (psp.value.state.value.frame & CDoom::FF_FRAMEMASK)

    lump = sprframe.value.lump[0]
    flip = sprframe.value.flip[0]

    # calculate edges of the shape
    tx = psp.value.sx - 160 * FRACUNIT

    tx -= CDoom.spriteoffset[lump]
    x1 = (CDoom.centerxfrac + CDoom.fixed_mul(tx, CDoom.pspritescale)) >> FRACBITS

    # off the right side?
    return if x1 > CDoom.viewwidth

    tx += CDoom.spritewidth[lump]
    x2 = ((CDoom.centerxfrac + CDoom.fixed_mul(tx, CDoom.pspritescale)) >> FRACBITS) - 1

    # off the left side
    return if x2 < 0

    avis = CDoom::Vissprite.new
    # store information in a vissprite
    vis = pointerof(avis)
    vis.value.mobjflags = 0
    vis.value.texturemid = (CDoom::BASEYCENTER << FRACBITS) + FRACUNIT // 2 - (psp.value.sy - CDoom.spritetopoffset[lump])
    vis.value.x1 = x1 < 0 ? 0 : x1
    vis.value.x2 = x2 >= CDoom.viewwidth ? CDoom.viewwidth - 1 : x2
    vis.value.scale = CDoom.pspritescale

    if flip != 0
      vis.value.xiscale = -CDoom.pspriteiscale
      vis.value.startfrac = CDoom.spritewidth[lump] - 1
    else
      vis.value.xiscale = CDoom.pspriteiscale
      vis.value.startfrac = 0
    end

    if vis.value.x1 > x1
      vis.value.startfrac = vis.value.startfrac + vis.value.xiscale * (vis.value.x1 - x1)
    end
    vis.value.patch = lump

    # get light level
    if CDoom.viewplayer.value.powers[CDoom::Powertype::Invisibility.value] > 4 * 32 ||
       CDoom.viewplayer.value.powers[CDoom::Powertype::Invisibility.value] & 8 != 0
      # shadow draw
      vis.value.colormap = Pointer(CDoom::Lighttable).null
    elsif !CDoom.fixedcolormap.null?
      # fixed map
      vis.value.colormap = CDoom.fixedcolormap
    elsif psp.value.state.value.frame & CDoom::FF_FULLBRIGHT != 0
      # full bright
      vis.value.colormap = CDoom.colormaps
    else
      # local light
      vis.value.colormap = CDoom.spritelights[CDoom::MAXLIGHTSCALE - 1]
    end

    CDoom.r_draw_vis_sprite(vis, vis.value.x1, vis.value.x2)
  end

  def self.r_draw_player_sprites
    # get light level
    lightnum =
      (CDoom.viewplayer.value.mo.value.subsector.value.sector.value.lightlevel >> CDoom::LIGHTSEGSHIFT) +
        CDoom.extralight

    if lightnum < 0
      CDoom.spritelights = CDoom.scalelight[0]
    elsif lightnum >= CDoom::LIGHTLEVELS
      CDoom.spritelights = CDoom.scalelight[CDoom::LIGHTLEVELS - 1]
    else
      CDoom.spritelights = CDoom.scalelight[lightnum]
    end

    # clip to screen bounds
    CDoom.mfloorclip = CDoom.screenheightarray
    CDoom.mceilingclip = CDoom.negonearray

    # add all active psprites
    psp = CDoom.viewplayer.value.psprites.to_unsafe
    CDoom::Psprnum::NUMPSPRITES.value.times do |i|
      CDoom.r_draw_psprite(psp) unless psp.value.state.null?
      psp += 1
    end
  end

  def self.r_sort_vis_sprites
    count = CDoom.vissprite_p - CDoom.vissprites.to_unsafe

    unsorted = CDoom::Vissprite.new
    unsorted.next = pointerof(unsorted)
    unsorted.prev = unsorted.next

    return if count == 0

    ds = CDoom.vissprites.to_unsafe
    while ds < CDoom.vissprite_p
      ds.value.next = ds + 1
      ds.value.prev = ds - 1
      ds += 1
    end

    CDoom.vissprites.to_unsafe.value.prev = pointerof(unsorted)
    unsorted.next = CDoom.vissprites.to_unsafe
    (CDoom.vissprite_p - 1).value.next = pointerof(unsorted)
    unsorted.prev = CDoom.vissprite_p - 1

    # pull the vissprites out by scale
    CDoom.vsprsortedhead.next = pointerof(CDoom.vsprsortedhead)
    CDoom.vsprsortedhead.prev = CDoom.vsprsortedhead.next
    best = Pointer(CDoom::Vissprite).null # shut up the compiler warning
    count.times do |i|
      bestscale = Int32::MAX
      ds = unsorted.next
      while ds != pointerof(unsorted)
        if ds.value.scale < bestscale
          bestscale = ds.value.scale
          best = ds
        end
        ds = ds.value.next
      end
      best.value.next.value.prev = best.value.prev
      best.value.prev.value.next = best.value.next
      best.value.next = pointerof(CDoom.vsprsortedhead)
      best.value.prev = CDoom.vsprsortedhead.prev
      CDoom.vsprsortedhead.prev.value.next = best
      CDoom.vsprsortedhead.prev = best
    end
  end

  def self.r_draw_sprite(spr : CDoom::Vissprite*)
    clipbot = uninitialized StaticArray(Int16, CDoom::SCREENWIDTH)
    cliptop = uninitialized StaticArray(Int16, CDoom::SCREENWIDTH)

    x = spr.value.x1
    while x <= spr.value.x2
      clipbot[x] = -2
      cliptop[x] = -2
      x += 1
    end

    # Scan drawsegs from end to start for obscuring segs.
    # The first drawseg that has a greater scale
    #  is the clip seg.
    ds = CDoom.ds_p - 1
    while ds >= CDoom.drawsegs.to_unsafe
      # determine if the drawseg obscures the sprite
      if ds.value.x1 > spr.value.x2 ||
         ds.value.x2 < spr.value.x1 ||
         (ds.value.silhouette == 0 &&
         ds.value.maskedtexturecol.null?)
        # does not cover sprite
        ds -= 1
        next
      end

      r1 = ds.value.x1 < spr.value.x1 ? spr.value.x1 : ds.value.x1
      r2 = ds.value.x2 > spr.value.x2 ? spr.value.x2 : ds.value.x2

      if ds.value.scale1 > ds.value.scale2
        lowscale = ds.value.scale2
        scale = ds.value.scale1
      else
        lowscale = ds.value.scale1
        scale = ds.value.scale2
      end

      if scale < spr.value.scale ||
         (lowscale < spr.value.scale &&
         CDoom.r_point_on_seg_side(spr.value.gx, spr.value.gy, ds.value.curline) == 0)
        # masked mid texture?
        CDoom.r_render_masked_seg_range(ds, r1, r2) unless ds.value.maskedtexturecol.null?
        # seg is behind sprite
        ds -= 1
        next
      end

      # clip this piece of the sprite
      silhouette = ds.value.silhouette

      silhouette &= ~CDoom::SIL_BOTTOM if spr.value.gz >= ds.value.bsilheight

      silhouette &= ~CDoom::SIL_TOP if spr.value.gzt <= ds.value.tsilheight

      if silhouette == 1
        # bottom sil
        x = r1
        while x <= r2
          clipbot[x] = ds.value.sprbottomclip[x] if clipbot[x] == -2
          x += 1
        end
      elsif silhouette == 2
        # top sil
        x = r1
        while x <= r2
          cliptop[x] = ds.value.sprtopclip[x] if cliptop[x] == -2
          x += 1
        end
      elsif silhouette == 3
        # both
        x = r1
        while x <= r2
          clipbot[x] = ds.value.sprbottomclip[x] if clipbot[x] == -2
          cliptop[x] = ds.value.sprtopclip[x] if cliptop[x] == -2
          x += 1
        end
      end

      ds -= 1
    end

    # all clipping has been performed, so draw the sprite

    # check for unclipped columns
    x = spr.value.x1
    while x <= spr.value.x2
      clipbot[x] = CDoom.viewheight.to_i16! if clipbot[x] == -2
      cliptop[x] = -1 if cliptop[x] == -2
      x += 1
    end

    CDoom.mfloorclip = clipbot
    CDoom.mceilingclip = cliptop
    CDoom.r_draw_vis_sprite(spr, spr.value.x1, spr.value.x2)
  end

  def self.r_draw_masked
    CDoom.r_sort_vis_sprites

    if CDoom.vissprite_p > CDoom.vissprites.to_unsafe
      # draw all vissprites back to front
      spr = CDoom.vsprsortedhead.next
      while spr != pointerof(CDoom.vsprsortedhead)
        CDoom.r_draw_sprite(spr)
        spr = spr.value.next
      end
    end

    # render any remaining masked mid textures
    ds = CDoom.ds_p - 1
    while ds >= CDoom.drawsegs.to_unsafe
      unless ds.value.maskedtexturecol.null?
        CDoom.r_render_masked_seg_range(ds, ds.value.x1, ds.value.x2)
      end
      ds -= 1
    end

    # draw the psprites on top of everything
    #  but does not draw on side views
    CDoom.r_draw_player_sprites if CDoom.viewangleoffset == 0
  end

  #
  # Initializes sound stuff, including volume
  # Sets channels, SFX and music volume,
  #  allocates channel buffer, sets S_sfx lookup.
  #
  def self.s_init(sfx_volume : LibC::Int, music_volume : LibC::Int)
    # Whatever these did with DMX, these are rather dummies now. [ds] or are they...
    CDoom.i_set_channels

    @@snd_sfx_volume = sfx_volume
    # No music with Linux - another dummy. [ds] this didn't age well.
    CDoom.s_set_music_volume(music_volume)

    # Allocating the internal channels for mixing
    # (the maximum numer of sounds rendered
    # simultaneously) within zone memory.
    CDoom.channels_s_sound =
      CDoom.z_malloc(CDoom.num_channels * sizeof(CDoom::Channel), CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Channel*)

    # Free all channels for use
    CDoom.num_channels.times do |i|
      (CDoom.channels_s_sound + i).value.sfxinfo = Pointer(CDoom::Sfxinfo).null
    end

    # no sounds are playing, and they are not mus_paused
    CDoom.mus_paused = 0

    # Note that sounds have not been cached (yet)
    i = 1
    while i < CDoom::Sfxenum::NUMSFX.value
      (CDoom.s_sfx + i).value.lumpnum = -1
      (CDoom.s_sfx + i).value.usefulness = -1
      i += 1
    end
  end

  @@regmus = [
    # Song - Who? - Where?

    CDoom::Musicenum::MUS_e3m4, # American        e4m1
    CDoom::Musicenum::MUS_e3m2, # Romero        e4m2
    CDoom::Musicenum::MUS_e3m3, # Shawn        e4m3
    CDoom::Musicenum::MUS_e1m5, # American        e4m4
    CDoom::Musicenum::MUS_e2m7, # Tim         e4m5
    CDoom::Musicenum::MUS_e2m4, # Romero        e4m6
    CDoom::Musicenum::MUS_e2m6, # J.Anderson        e4m7 CHIRON.WAD
    CDoom::Musicenum::MUS_e2m5, # Shawn        e4m8
    CDoom::Musicenum::MUS_e1m9, # Tim                e4m9
  ]

  #
  # Per level startup code.
  # Kills playing sounds at start of level,
  #  determines music if any, changes music.
  #
  def self.s_start
    # kill all playing sounds at start of level
    #  (trust me - a good idea)
    CDoom.num_channels.times do |cnum|
      CDoom.s_stop_channel(cnum) unless CDoom.channels_s_sound[cnum].sfxinfo.null?
    end

    # start new music for the level
    CDoom.mus_paused = 0

    if CDoom.gamemode == CDoom::GameMode::Commercial
      mnum = CDoom::Musicenum::MUS_runnin.value + CDoom.gamemap - 1
    else
      if CDoom.gameepisode < 4
        mnum = CDoom::Musicenum::MUS_e1m1.value + (CDoom.gameepisode - 1) * 9 + CDoom.gamemap - 1
      else
        mnum = @@regmus[CDoom.gamemap - 1].value
      end
    end

    CDoom.s_change_music(mnum, 1)

    CDoom.nextcleanup = 15
  end

  def self.s_start_sound_at_volume(origin_p : Void*, sfx_id : LibC::Int, volume : LibC::Int)
    origin = origin_p.as(CDoom::Mobj*)

    # check for bogus sound #
    if sfx_id < 1 || sfx_id > CDoom::Sfxenum::NUMSFX.value
      CDoom.i_error("Error: Bad sfx #: #{sfx_id}")
    end

    sfx = CDoom.s_sfx + sfx_id

    # Initialize sound parameters
    unless sfx.value.link.null?
      pitch = sfx.value.pitch
      priority = sfx.value.priority
      volume += sfx.value.volume

      return if volume < 1

      volume = 15 if volume > 15
    else
      pitch = CDoom::NORM_PITCH
      priority = CDoom::NORM_PRIORITY
    end

    # Check to see if it is audible,
    #  and if not, modify the params
    sep = CDoom::NORM_SEP
    if !origin.null? && origin != CDoom.players[CDoom.consoleplayer].mo
      rc = CDoom.s_adjust_sound_params(CDoom.players[CDoom.consoleplayer].mo,
        origin,
        pointerof(volume),
        pointerof(sep),
        pointerof(pitch))

      if origin.value.x == CDoom.players[CDoom.consoleplayer].mo.value.x &&
         origin.value.y == CDoom.players[CDoom.consoleplayer].mo.value.y
        sep = CDoom::NORM_SEP
      end

      return if rc == 0
    end

    # hacks to vary the sfx pitches
    if sfx_id >= CDoom::Sfxenum::SFX_sawup.value &&
       sfx_id <= CDoom::Sfxenum::SFX_sawhit.value
      pitch += 8 - (CDoom.m_random & 15)

      if pitch < 0
        pitch = 0
      elsif pitch > 255
        pitch = 255
      end
    elsif sfx_id != CDoom::Sfxenum::SFX_itemup.value &&
          sfx_id != CDoom::Sfxenum::SFX_tink.value
      pitch += 16 - (CDoom.m_random & 31)

      if pitch < 0
        pitch = 0
      elsif pitch > 255
        pitch = 255
      end
    end

    # kill old sound
    CDoom.s_stop_sound(origin)

    # try to find a channel
    cnum = CDoom.s_get_channel(origin, sfx)

    return if cnum < 0

    #
    # This is supposed to handle the loading/caching.
    # For some odd reason, the caching is done nearly
    #  each time the sound is needed?
    #

    # get lumpnum if necessary
    sfx.value.lumpnum = CDoom.i_get_sfx_lump_num(sfx) if sfx.value.lumpnum < 0

    # increase the usefulness
    if sfx.value.usefulness < 0
      sfx.value.usefulness = 1
    else
      sfx.value.usefulness = sfx.value.usefulness + 1
    end

    # Assigns the handle to one of the channels in the
    #  mix/output buffer.
    (CDoom.channels_s_sound + cnum).value.handle = CDoom.i_start_sound(sfx_id,
      volume,
      sep,
      pitch,
      priority)
  end

  def self.s_start_sound(origin : Void*, sfx_id : LibC::Int)
    Doocr.s_start_sound_at_volume(origin, sfx_id, 15)
  end

  def self.s_stop_sound(origin : Void*)
    CDoom.num_channels.times do |cnum|
      if !CDoom.channels_s_sound[cnum].sfxinfo.null? && CDoom.channels_s_sound[cnum].origin == origin
        CDoom.s_stop_channel(cnum)
        break
      end
    end
  end

  #
  # Stop and resume music, during game PAUSE.
  #
  def self.s_pause_sound
    if !CDoom.mus_playing_s_sound.null? && CDoom.mus_paused == 0
      CDoom.i_pause_song(CDoom.mus_playing_s_sound.value.handle)
      CDoom.mus_paused = 1
    end
  end

  def self.s_resume_sound
    if !CDoom.mus_playing_s_sound.null? && CDoom.mus_paused != 0
      CDoom.i_resume_song(CDoom.mus_playing_s_sound.value.handle)
      CDoom.mus_paused = 0
    end
  end

  #
  # Updates music & sounds
  #
  def self.s_update_sounds(listener_p : Void*)
    listener = listener_p.as(CDoom::Mobj*)

    CDoom.num_channels.times do |cnum|
      c = CDoom.channels_s_sound + cnum
      sfx = c.value.sfxinfo

      unless c.value.sfxinfo.null?
        if CDoom.i_sound_is_playing(c.value.handle) != 0
          # initialize parameters
          volume = 15
          pitch = CDoom::NORM_PITCH
          sep = CDoom::NORM_SEP

          unless sfx.value.link.null?
            pitch = sfx.value.pitch
            volume += sfx.value.volume
            if volume < 1
              CDoom.s_stop_channel(cnum)
              next
            elsif volume > 15
              volume = 15
            end
          end

          # check non-local sounds for distance clipping
          #  or modify their params
          if !c.value.origin.null? && listener_p != c.value.origin
            audible = CDoom.s_adjust_sound_params(listener,
              c.value.origin.as(CDoom::Mobj*),
              pointerof(volume),
              pointerof(sep),
              pointerof(pitch))

            if audible == 0
              CDoom.s_stop_channel(cnum)
            else
              CDoom.i_update_sound_params(c.value.handle, volume, sep, pitch)
            end
          end
        else
          # if channel is allocated but sound has stopped,
          #  free it
          CDoom.s_stop_channel(cnum)
        end
      end
    end
  end

  def self.s_set_music_volume(volume : LibC::Int)
    if volume < 0 || volume > 127
      CDoom.i_error("Error: Attempt to set music volume at #{volume}")
    end

    CDoom.snd_music_volume = volume
    CDoom.i_set_music_volume(volume)
  end

  #
  # Starts some music with the music id found in sounds.h.
  #
  def self.s_start_music(m_id : LibC::Int)
    CDoom.s_change_music(m_id, 0)
  end

  def self.s_change_music(musicnum : LibC::Int, looping : LibC::Int)
    music = CDoom.s_music + musicnum

    if musicnum <= CDoom::Musicenum::MUS_None.value ||
       musicnum >= CDoom::Musicenum::NUMMUSIC.value
      CDoom.i_error("Error: Bad music number #{musicnum}")
    end

    return if CDoom.mus_playing_s_sound == music

    # shutdown old music
    CDoom.s_stop_music

    # get lumpnum if neccessary
    if music.value.lumpnum == 0
      music.value.lumpnum = CDoom.w_get_num_for_name("d_#{String.new(music.value.name)}")
    end
    # load & register it
    music.value.data = CDoom.w_cache_lump_num(music.value.lumpnum, CDoom::PU_MUSIC)
    music.value.handle = CDoom.i_register_song(music.value.data)
    # play it
    CDoom.mus_playing_s_sound = music

    CDoom.i_play_song(music.value.handle, looping)
  end

  def self.s_stop_music
    unless CDoom.mus_playing_s_sound.null?
      if CDoom.mus_paused != 0
        CDoom.i_resume_song(CDoom.mus_playing_s_sound.value.handle)
      end

      CDoom.i_stop_song(CDoom.mus_playing_s_sound.value.handle)
      CDoom.i_unregister_song(CDoom.mus_playing_s_sound.value.handle)
      z_change_tag(CDoom.mus_playing_s_sound.value.data, CDoom::PU_CACHE)

      CDoom.mus_playing_s_sound.value.data = Pointer(Void).null
      CDoom.mus_playing_s_sound = Pointer(CDoom::Musicinfo).null
    end
  end

  def self.s_stop_channel(cnum : LibC::Int)
    c = CDoom.channels_s_sound + cnum

    unless c.value.sfxinfo.null?
      # stop the sound playing
      CDoom.i_stop_sound(c.value.handle) if CDoom.i_sound_is_playing(c.value.handle) != 0

      # check to see
      #  if other channels are playing the sound
      i = 0
      while i < CDoom.num_channels
        if cnum != i &&
           c.value.sfxinfo == CDoom.channels_s_sound[i].sfxinfo
          break
        end

        i += 1
      end

      # degrade usefulness of sound data
      c.value.sfxinfo.value.usefulness = c.value.sfxinfo.value.usefulness - 1

      c.value.sfxinfo = Pointer(CDoom::Sfxinfo).null
    end
  end

  #
  # Changes volume, stereo-separation, and pitch variables
  #  from the norm of a sound effect to be played.
  # If the sound is not audible, returns a 0.
  # Otherwise, modifies parameters and returns 1.
  #
  def self.s_adjust_sound_params(listener : CDoom::Mobj*, source : CDoom::Mobj*, vol : LibC::Int*, sep : LibC::Int*, pitch : LibC::Int*) : LibC::Int
    # calculate the distance to sound origin
    #  and clip it if necessary
    adx = doom_abs(listener.value.x - source.value.x)
    ady = doom_abs(listener.value.y - source.value.y)

    # From _GG1_ p.428. Appox. eucledian distance fast.
    approx_dist = adx + ady - ((adx < ady ? adx : ady) >> 1)

    return 0 if CDoom.gamemap != 8 &&
                approx_dist > CDoom::S_CLIPPING_DIST

    # angle of source to listener
    angle = CDoom.r_point_to_angle2(listener.value.x,
      listener.value.y,
      source.value.x,
      source.value.y)

    if angle > listener.value.angle
      angle = angle &- listener.value.angle
    else
      angle = angle &+ (0xffffffff &- listener.value.angle)
    end

    angle >>= CDoom::ANGLETOFINESHIFT

    # stereo separation
    sep.value = 128 - (CDoom.fixed_mul(CDoom::S_STEREO_SWING, @@finesine[angle]) >> FRACBITS)

    # volume calculation
    if approx_dist < CDoom::S_CLOSE_DIST
      vol.value = 15
    elsif CDoom.gamemap == 8
      vol.value = 15
    else
      # distance effect
      vol.value = (15 *
                   ((CDoom::S_CLIPPING_DIST - approx_dist) >> FRACBITS)) // CDoom::S_ATTENUATOR
    end

    return (vol.value > 0).to_unsafe
  end

  #
  # If none available, return -1.  Otherwise channel #.
  #
  def self.s_get_channel(origin : Void*, sfxinfo : CDoom::Sfxinfo*) : LibC::Int
    # channel number to use
    cnum = 0

    # Find an open channel
    while cnum < CDoom.num_channels
      if CDoom.channels_s_sound[cnum].sfxinfo.null?
        break
      elsif !origin.null? && CDoom.channels_s_sound[cnum].origin == origin
        CDoom.s_stop_channel(cnum)
        break
      end

      cnum += 1
    end

    # None available
    if cnum == CDoom.num_channels
      # Look for lower priority
      cnum = 0
      while cnum < CDoom.num_channels
        if CDoom.channels_s_sound[cnum].sfxinfo.value.priority >= sfxinfo.value.priority
          break
        end

        cnum += 1
      end

      if cnum == CDoom.num_channels
        # FUCK!  No lower priority.  Sorry, Charlie.
        return -1
      else
        # Otherwise, kick out lower priority
        CDoom.s_stop_channel(cnum)
      end
    end

    c = CDoom.channels_s_sound + cnum

    # channel is decided to be cnum.
    c.value.sfxinfo = sfxinfo
    c.value.origin = origin

    return cnum
  end

  def self.stlib_init
    CDoom.sttminus = CDoom.w_cache_lump_name("STTMINUS", CDoom::PU_STATIC).as(CDoom::Patch*)
  end

  # ?
  def self.stlib_init_num(n : CDoom::ST_Number*,
                          x : LibC::Int,
                          y : LibC::Int,
                          pl : CDoom::Patch**,
                          num : LibC::Int*,
                          on : CDoom::DoomBool*,
                          width : LibC::Int)
    n.value.x = x
    n.value.y = y
    n.value.oldnum = 0
    n.value.width = width
    n.value.num = num
    n.value.on = on
    n.value.p = pl
  end

  #
  # A fairly efficient way to draw a number
  #  based on differences from the old number.
  # Note: worth the trouble?
  #
  def self.stlib_draw_num(n : CDoom::ST_Number*, refresh : CDoom::DoomBool)
    numdigits = n.value.width
    num = n.value.num.value

    w = n.value.p[0].value.width
    h = n.value.p[0].value.height
    x = n.value.x

    n.value.oldnum = n.value.num.value

    neg = num < 0

    if neg
      if numdigits == 2 && num < -9
        num = -9
      elsif numdigits == 3 && num < -99
        num = -99
      end

      num = -num
    end

    # clear the area
    x = n.value.x - numdigits * w

    if n.value.y - CDoom::ST_Y < 0
      CDoom.i_error("Error: stlib_draw_num: n.value.y - CDoom::ST_Y < 0")
    end

    CDoom.v_copy_rect(x, n.value.y - CDoom::ST_Y, CDoom::STLIB_BG, w * numdigits, h, x, n.value.y, CDoom::STLIB_FG)

    # if non-number, do not draw it
    return if num == 1994

    x = n.value.x

    # in the special case of 0, you draw 0
    if num == 0
      CDoom.v_draw_patch(x - w, n.value.y, CDoom::STLIB_FG, n.value.p[0])
    end

    # draw the new number
    while num != 0 && numdigits != 0
      numdigits -= 1
      x -= w
      CDoom.v_draw_patch(x, n.value.y, CDoom::STLIB_FG, n.value.p[num % 10])
      num //= 10
    end

    # draw a minus sign if necessary
    if neg
      CDoom.v_draw_patch(x - 8, n.value.y, CDoom::STLIB_FG, CDoom.sttminus)
    end
  end

  def self.stlib_update_num(n : CDoom::ST_Number*, refresh : CDoom::DoomBool)
    CDoom.stlib_draw_num(n, refresh) if n.value.on.value != 0
  end

  def self.stlib_init_percent(p : CDoom::ST_Percent*,
                              x : LibC::Int,
                              y : LibC::Int,
                              pl : CDoom::Patch**,
                              num : LibC::Int*,
                              on : CDoom::DoomBool*,
                              percent : CDoom::Patch*)
    CDoom.stlib_init_num(
      pointerof(p.value.@n),
      x, y, pl, num, on, 3)
    p.value.p = percent
  end

  def self.stlib_update_percent(per : CDoom::ST_Percent*, refresh : LibC::Int)
    if refresh != 0 && per.value.n.on.value != 0
      CDoom.v_draw_patch(per.value.n.x, per.value.n.y, CDoom::STLIB_FG, per.value.p)
    end

    CDoom.stlib_update_num(
      pointerof(per.value.@n),
      refresh
    )
  end

  def self.stlib_init_mult_icon(i : CDoom::ST_Multicon*,
                                x : LibC::Int,
                                y : LibC::Int,
                                il : CDoom::Patch**,
                                inum : LibC::Int*,
                                on : CDoom::DoomBool*)
    i.value.x = x
    i.value.y = y
    i.value.oldinum = -1
    i.value.inum = inum
    i.value.on = on
    i.value.p = il
  end

  def self.stlib_update_mult_icon(mi : CDoom::ST_Multicon*,
                                  refresh : CDoom::DoomBool)
    # Lazy ssg number hack to use whichever shotgun is active
    if CDoom.gamemode == CDoom::GameMode::Commercial &&
       mi.value.inum == CDoom.plyr.value.weaponowned.to_unsafe + CDoom::Weapontype::Shotgun.value &&
       mi.value.inum.value < (ssgnum = (CDoom.plyr.value.weaponowned.to_unsafe + CDoom::Weapontype::Supershotgun.value)).value
      mi.value.inum = ssgnum
    end

    if mi.value.on.value != 0 &&
       (mi.value.oldinum != mi.value.inum.value || refresh != 0) &&
       mi.value.inum.value != -1
      if mi.value.oldinum != -1
        x = mi.value.x - mi.value.p[mi.value.oldinum].value.leftoffset
        y = mi.value.y - mi.value.p[mi.value.oldinum].value.topoffset
        w = mi.value.p[mi.value.oldinum].value.width
        h = mi.value.p[mi.value.oldinum].value.height

        if y - CDoom::ST_Y < 0
          CDoom.i_error("Error: stlib_update_multi_icon: y - CDoom::ST_Y < 0")
        end

        CDoom.v_copy_rect(x, y - CDoom::ST_Y, CDoom::STLIB_BG, w, h, x, y, CDoom::STLIB_FG)
      end
      CDoom.v_draw_patch(mi.value.x, mi.value.y, CDoom::STLIB_FG, mi.value.p[mi.value.inum.value])
      mi.value.oldinum = mi.value.inum.value
    end
  end

  def self.stlib_init_bin_icon(b : CDoom::ST_Binicon*,
                               x : LibC::Int,
                               y : LibC::Int,
                               i : CDoom::Patch*,
                               val : CDoom::DoomBool*,
                               on : CDoom::DoomBool*)
    b.value.x = x
    b.value.y = y
    b.value.oldval = 0
    b.value.val = val
    b.value.on = on
    b.value.p = i
  end

  def self.stlib_update_bin_icon(bi : CDoom::ST_Binicon*, refresh : CDoom::DoomBool)
    if bi.value.on.value != 0 && (bi.value.oldval != bi.value.val.value || refresh != 0)
      x = bi.value.x - bi.value.p.value.leftoffset
      y = bi.value.y - bi.value.p.value.topoffset
      w = bi.value.p.value.width
      h = bi.value.p.value.height

      if y - CDoom::ST_Y < 0
        CDoom.i_error("Error: stlib_update_bin_icon: y - CDoom::ST_Y < 0")
      end

      if bi.value.val.value != 0
        CDoom.v_draw_patch(bi.value.x, bi.value.y, CDoom::STLIB_FG, bi.value.p)
      else
        CDoom.v_copy_rect(x, y - CDoom::ST_Y, CDoom::STLIB_BG, w, h, x, y, CDoom::STLIB_FG)
      end

      bi.value.oldval = bi.value.val.value
    end
  end

  #
  # STATUS BAR CODE
  #

  def self.st_refresh_background
    if CDoom.st_statusbaron != 0
      CDoom.v_draw_patch(CDoom::ST_X, 0, CDoom::STLIB_BG, CDoom.sbar)

      CDoom.v_draw_patch(CDoom::ST_FX, 0, CDoom::STLIB_BG, CDoom.faceback) if CDoom.netgame != 0

      CDoom.v_copy_rect(CDoom::ST_X, 0, CDoom::STLIB_BG, CDoom::ST_WIDTH, CDoom::ST_HEIGHT, CDoom::ST_X, CDoom::ST_Y, CDoom::STLIB_FG)
    end
  end

  @@buf = Pointer(UInt8).malloc(CDoom::ST_MSGWIDTH)

  # Respond to keyboard input events,
  #  intercept cheats.
  def self.st_responder(ev : CDoom::Event*) : CDoom::DoomBool
    # Filter automap on/off.
    if ev.value.type == CDoom::Evtype::Keyup &&
       (ev.value.data1 & 0xffff0000) == CDoom::AM_MSGHEADER
      case ev.value.data1
      when CDoom::AM_MSGENTERED
        CDoom.st_gamestate = CDoom::ST_Statenum::AutomapState
        CDoom.st_firsttime = 1
      when CDoom::AM_MSGEXITED
        CDoom.st_gamestate = CDoom::ST_Statenum::FirstPersonState
      end

      # if a user keypress...
    elsif ev.value.type == CDoom::Evtype::Keydown
      if CDoom.netgame == 0
        # my little cheat
        if cht_check_cheat(pointerof(@@cheat_me), ev.value.data1.to_u8) != 0
          CDoom.plyr.value.cheats = CDoom.plyr.value.cheats ^ CDoom::Cheat::CF_ME.value
          CDoom.plyr.value.message = "#{(CDoom.plyr.value.cheats & CDoom::Cheat::CF_ME.value != 0 ? "yea" : "no")} baby!"
          if CDoom.plyr.value.cheats & CDoom::Cheat::CF_ME.value != 0
            if CDoom.plyr.value.backpack == 0
              CDoom::Ammotype::NUMAMMO.value.times do |i|
                CDoom.plyr.value.maxammo[i] = CDoom.plyr.value.maxammo[i] * 2
              end
              CDoom.plyr.value.backpack = 1
            end
            CDoom::Ammotype::NUMAMMO.value.times do |i|
              CDoom.plyr.value.ammo[i] = CDoom.plyr.value.maxammo[i]
            end
          end
        end

        # 'dqd' cheat of toggleable god mode
        if CDoom.cht_check_cheat(pointerof(CDoom.cheat_god), ev.value.data1) != 0
          CDoom.plyr.value.cheats = CDoom.plyr.value.cheats ^ CDoom::Cheat::CF_GODMODE.value
          if CDoom.plyr.value.cheats & CDoom::Cheat::CF_GODMODE.value != 0
            CDoom.plyr.value.mo.value.health = @@deh_god_mode_health unless CDoom.plyr.value.mo.null?

            CDoom.plyr.value.health = @@deh_god_mode_health
            CDoom.plyr.value.message = @@deh_ststr_dqdon
          else
            CDoom.plyr.value.message = @@deh_ststr_dqdoff
          end

          # 'fa' cheat for killer fucking arsenal
        elsif CDoom.cht_check_cheat(pointerof(CDoom.cheat_ammonokey), ev.value.data1) != 0
          CDoom.plyr.value.armorpoints = @@deh_idfa_armor
          CDoom.plyr.value.armortype = @@deh_idfa_armor_class

          CDoom::Weapontype::NUMWEAPONS.value.times { |i| CDoom.plyr.value.weaponowned[i] = 1 }

          CDoom::Ammotype::NUMAMMO.value.times { |i| CDoom.plyr.value.ammo[i] = CDoom.plyr.value.maxammo[i] }

          CDoom.plyr.value.message = @@deh_ststr_faadded

          # 'kfa' cheat for key full ammo
        elsif CDoom.cht_check_cheat(pointerof(CDoom.cheat_ammo), ev.value.data1) != 0
          CDoom.plyr.value.armorpoints = @@deh_idkfa_armor
          CDoom.plyr.value.armortype = @@deh_idkfa_armor_class

          CDoom::Weapontype::NUMWEAPONS.value.times { |i| CDoom.plyr.value.weaponowned[i] = 1 }

          CDoom::Ammotype::NUMAMMO.value.times { |i| CDoom.plyr.value.ammo[i] = CDoom.plyr.value.maxammo[i] }

          CDoom::Card::NUMCARDS.value.times { |i| CDoom.plyr.value.cards[i] = 1 }

          CDoom.plyr.value.message = @@deh_ststr_kfaadded

          # 'mus' cheat for changing music
        elsif CDoom.cht_check_cheat(pointerof(CDoom.cheat_mus), ev.value.data1) != 0
          buf = Pointer(UInt8).malloc(3)

          CDoom.plyr.value.message = @@deh_ststr_mus
          CDoom.cht_get_param(pointerof(CDoom.cheat_mus), buf)

          if CDoom.gamemode == CDoom::GameMode::Commercial
            map = ((buf[0] - '0'.ord) * 10 + buf[1] - '0'.ord) &- 1
            musnum = CDoom::Musicenum::MUS_runnin.value + map

            if map > 31
              CDoom.plyr.value.message = @@deh_ststr_nomus
            else
              CDoom.s_change_music(musnum, 1)
            end
          else
            e = (buf[0] &- '1'.ord)
            m = (buf[1] &- '1'.ord)

            if m > 8 || (e > 3 && CDoom.gamemode == CDoom::GameMode::Retail) ||
               (e > 2 && CDoom.gamemode == CDoom::GameMode::Registered) ||
               (e > 0 && CDoom.gamemode == CDoom::GameMode::Shareware)
              CDoom.plyr.value.message = @@deh_ststr_nomus
            else
              mus = CDoom.gamemode == CDoom::GameMode::Retail ? @@regmus[m].value : CDoom::Musicenum::MUS_e1m1.value + e * 9 + m
              CDoom.s_change_music(mus, 1)
            end
          end

          # Simplified, accepting both "noclip" and "idspispopd".
          # no clipping mode cheat
        elsif CDoom.cht_check_cheat(pointerof(CDoom.cheat_noclip), ev.value.data1) != 0 ||
              CDoom.cht_check_cheat(pointerof(CDoom.cheat_commercial_noclip), ev.value.data1) != 0
          CDoom.plyr.value.cheats = CDoom.plyr.value.cheats ^ CDoom::Cheat::CF_NOCLIP.value

          if CDoom.plyr.value.cheats & CDoom::Cheat::CF_NOCLIP.value != 0
            CDoom.plyr.value.message = @@deh_ststr_ncon
          else
            CDoom.plyr.value.message = @@deh_ststr_ncoff
          end
        end

        # 'behold?' power-up cheats
        6.times do |i|
          if CDoom.cht_check_cheat(CDoom.cheat_powerup.to_unsafe + i, ev.value.data1) != 0
            if CDoom.plyr.value.powers[i] == 0
              CDoom.p_give_power(CDoom.plyr, i)
            elsif i != CDoom::Powertype::Strength.value
              CDoom.plyr.value.powers[i] = 1
            else
              CDoom.plyr.value.powers[i] = 0
            end

            CDoom.plyr.value.message = @@deh_ststr_beholdx
          end
        end

        # 'behold' power-up menu
        if CDoom.cht_check_cheat(CDoom.cheat_powerup.to_unsafe + 6, ev.value.data1) != 0
          CDoom.plyr.value.message = @@deh_ststr_behold

          # 'choppers' invulnerability & chainsaw
        elsif CDoom.cht_check_cheat(pointerof(CDoom.cheat_choppers), ev.value.data1) != 0
          CDoom.plyr.value.weaponowned[CDoom::Weapontype::Chainsaw.value] = 1
          CDoom.plyr.value.powers[CDoom::Powertype::Invulnerability.value] = 1
          CDoom.plyr.value.message = @@deh_ststr_choppers

          # 'mypos' for player position
        elsif CDoom.cht_check_cheat(pointerof(CDoom.cheat_mypos), ev.value.data1) != 0
          CDoom.doom_strcpy(@@buf, "ang=0x")
          CDoom.doom_concat(@@buf, CDoom.doom_itoa(CDoom.players[CDoom.consoleplayer].mo.value.angle, 16))
          CDoom.doom_concat(@@buf, ";x,y=(0x")
          CDoom.doom_concat(@@buf, CDoom.doom_itoa(CDoom.players[CDoom.consoleplayer].mo.value.x, 16))
          CDoom.doom_concat(@@buf, ",0x")
          CDoom.doom_concat(@@buf, CDoom.doom_itoa(CDoom.players[CDoom.consoleplayer].mo.value.y, 16))
          CDoom.doom_concat(@@buf, ")")
          CDoom.plyr.value.message = @@buf
        end

        # 'clev' change-level cheat
        if CDoom.cht_check_cheat(pointerof(CDoom.cheat_clev), ev.value.data1) != 0
          buf = Pointer(UInt8).malloc(3)

          CDoom.cht_get_param(pointerof(CDoom.cheat_clev), buf)

          if CDoom.gamemode == CDoom::GameMode::Commercial
            epsd = 0
            map = (buf[0] - '0'.ord) * 10 + buf[1] - '0'.ord
          else
            epsd = buf[0] - '0'.ord
            map = buf[1] - '0'.ord
          end

          # Catch invalid maps
          return 0 if CDoom.gamemode != CDoom::GameMode::Commercial && epsd < 1

          return 0 if map < 1

          # Ohmygod - this is not going to work.
          return 0 if CDoom.gamemode == CDoom::GameMode::Retail &&
                      (epsd > 4 || map > 9)

          return 0 if CDoom.gamemode == CDoom::GameMode::Registered &&
                      (epsd > 3 || map > 9)

          return 0 if CDoom.gamemode == CDoom::GameMode::Shareware &&
                      (epsd > 1 || map > 9)

          return 0 if CDoom.gamemode == CDoom::GameMode::Commercial &&
                      map > 32

          # So be it.
          CDoom.plyr.value.message = @@deh_ststr_clev
          CDoom.g_defered_init_new(CDoom.gameskill, epsd, map)
        end
      end
    end
    return 0
  end

  @@lastcalc = 0
  @@oldhealth = -1

  def self.st_calc_pain_offset : LibC::Int
    health = CDoom.plyr.value.health > 100 ? 100 : CDoom.plyr.value.health

    if health != @@oldhealth
      @@lastcalc = CDoom::ST_FACESTRIDE * (((100 - health) * CDoom::ST_NUMPAINFACES) // 101)
      @@oldhealth = health
    end
    return @@lastcalc
  end

  #
  # This is a not-very-pretty routine which handles
  #  the face states and their timing.
  # the precedence of expressions is:
  #  dead > evil grin > turned head > straight ahead
  #
  @@lastattackdown = -1
  @@priority = 0

  def self.st_update_face_widget
    if @@priority < 10
      # dead
      if CDoom.plyr.value.health == 0
        @@priority = 9
        CDoom.st_faceindex = CDoom::ST_DEADFACE
        CDoom.st_facecount = 1
      end
    end

    if @@priority < 9
      if CDoom.plyr.value.bonuscount != 0
        # picking up bonuse
        doevilgrin = false

        CDoom::Weapontype::NUMWEAPONS.value.times do |i|
          if CDoom.oldweaponsowned[i] != CDoom.plyr.value.weaponowned[i]
            doevilgrin = true
            CDoom.oldweaponsowned[i] = CDoom.plyr.value.weaponowned[i]
          end
        end
        if doevilgrin
          # evil grin if just picked up weapon
          @@priority = 8
          CDoom.st_facecount = CDoom::ST_EVILGRINCOUNT
          CDoom.st_faceindex = CDoom.st_calc_pain_offset + CDoom::ST_EVILGRINOFFSET
        end
      end
    end

    if @@priority < 8
      if CDoom.plyr.value.damagecount != 0 &&
         !CDoom.plyr.value.attacker.null? &&
         CDoom.plyr.value.attacker != CDoom.plyr.value.mo
        # being attacked
        @@priority = 7

        if CDoom.plyr.value.health - CDoom.st_oldhealth > CDoom::ST_MUCHPAIN
          CDoom.st_facecount = CDoom::ST_TURNCOUNT
          CDoom.st_faceindex = CDoom.st_calc_pain_offset + CDoom::ST_OUCHOFFSET
        else
          badguyangle = CDoom.r_point_to_angle2(CDoom.plyr.value.mo.value.x,
            CDoom.plyr.value.mo.value.y,
            CDoom.plyr.value.attacker.value.x,
            CDoom.plyr.value.attacker.value.y)

          if badguyangle > CDoom.plyr.value.mo.value.angle
            # whether right or left
            diffang = badguyangle &- CDoom.plyr.value.mo.value.angle
            i = diffang > ANG180
          else
            # whether left or right
            diffang = CDoom.plyr.value.mo.value.angle &- badguyangle
            i = diffang <= ANG180
          end # confusing, aint it?

          CDoom.st_facecount = CDoom::ST_TURNCOUNT
          CDoom.st_faceindex = CDoom.st_calc_pain_offset

          if diffang < ANG45
            # head-on
            CDoom.st_faceindex += CDoom::ST_RAMPAGEOFFSET
          elsif i
            # turn face right
            CDoom.st_faceindex += CDoom::ST_TURNOFFSET
          else
            # turn face left
            CDoom.st_faceindex += CDoom::ST_TURNOFFSET + 1
          end
        end
      end
    end

    if @@priority < 7
      # getting hurt because of your own damn stupidity
      if CDoom.plyr.value.damagecount != 0
        if CDoom.plyr.value.health - CDoom.st_oldhealth > CDoom::ST_MUCHPAIN
          @@priority = 7
          CDoom.st_facecount = CDoom::ST_TURNCOUNT
          CDoom.st_faceindex = CDoom.st_calc_pain_offset + CDoom::ST_OUCHOFFSET
        else
          @@priority = 6
          CDoom.st_facecount = CDoom::ST_TURNCOUNT
          CDoom.st_faceindex = CDoom.st_calc_pain_offset + CDoom::ST_RAMPAGEOFFSET
        end
      end
    end

    if @@priority < 6
      # rapid firing
      if CDoom.plyr.value.attackdown != 0
        if @@lastattackdown == -1
          @@lastattackdown = CDoom::ST_RAMPAGEDELAY
        elsif (@@lastattackdown -= 1) == 0
          @@priority = 5
          CDoom.st_faceindex = CDoom.st_calc_pain_offset + CDoom::ST_RAMPAGEOFFSET
          CDoom.st_facecount = 1
          @@lastattackdown = 1
        end
      else
        @@lastattackdown = -1
      end
    end

    if @@priority < 5
      # invulnerability
      if CDoom.plyr.value.cheats & CDoom::Cheat::CF_GODMODE.value != 0 ||
         CDoom.plyr.value.powers[CDoom::Powertype::Invulnerability.value] != 0
        @@priority = 4

        CDoom.st_faceindex = CDoom::ST_GODFACE
        CDoom.st_facecount = 1
      end
    end

    # look left or look right if the facecount has timed out
    if CDoom.st_facecount == 0
      CDoom.st_faceindex = CDoom.st_calc_pain_offset + (CDoom.st_randomnumber % 3)
      CDoom.st_facecount = CDoom::ST_STRAIGHTFACECOUNT
      @@priority = 0
    end

    CDoom.st_facecount -= 1
  end

  @@largeammo = 1994 # means "n/a"

  def self.st_update_widgets
    if CDoom.weaponinfo[CDoom.plyr.value.readyweapon.value].ammo == CDoom::Ammotype::Noammo
      CDoom.w_ready.num = pointerof(@@largeammo)
    else
      CDoom.w_ready.num = CDoom.plyr.value.ammo.to_unsafe + CDoom.weaponinfo[CDoom.plyr.value.readyweapon.value].ammo.value
    end

    CDoom.w_ready.data = CDoom.plyr.value.readyweapon

    # update keycard multiple widgets
    3.times do |i|
      CDoom.keyboxes[i] = CDoom.plyr.value.cards[i] != 0 ? i : -1

      CDoom.keyboxes[i] = i + 3 if CDoom.plyr.value.cards[i + 3] != 0
    end

    # refresh everything if this is him coming back to life
    CDoom.st_update_face_widget

    # used by the w_armsbg widget
    CDoom.st_notdeathmatch = (CDoom.deathmatch == 0).to_unsafe

    # used by w_arms[] widgets
    CDoom.st_armson = (CDoom.st_statusbaron != 0 && CDoom.deathmatch == 0).to_unsafe

    # used by w_frags widget
    CDoom.st_fragson = (CDoom.deathmatch != 0 && CDoom.st_statusbaron != 0).to_unsafe
    CDoom.st_fragscount = 0

    CDoom::MAXPLAYERS.times do |i|
      if i != CDoom.consoleplayer
        CDoom.st_fragscount += CDoom.plyr.value.frags[i]
      else
        CDoom.st_fragscount -= CDoom.plyr.value.frags[i]
      end
    end

    # get rid of chat window if up because of message
    CDoom.st_chat = CDoom.st_oldchat if (CDoom.st_msgcounter -= 1) == 0
  end

  def self.st_ticker
    CDoom.st_clock += 1
    CDoom.st_randomnumber = CDoom.m_random
    CDoom.st_update_widgets
    CDoom.st_oldhealth = CDoom.plyr.value.health
  end

  def self.st_do_palette_stuff
    cnt = CDoom.plyr.value.damagecount

    if CDoom.plyr.value.powers[CDoom::Powertype::Strength.value] != 0
      # slowly fade the berzerk out
      bzc = 12 - (CDoom.plyr.value.powers[CDoom::Powertype::Strength.value] >> 6)

      cnt = bzc if bzc > cnt
    end

    if cnt != 0
      palette = (cnt + 7) >> 3

      palette = CDoom::NUMREDPALS - 1 if palette >= CDoom::NUMREDPALS

      palette += CDoom::STARTREDPALS
    elsif CDoom.plyr.value.bonuscount != 0
      palette = (CDoom.plyr.value.bonuscount + 7) >> 3

      palette = CDoom::NUMBONUSPALS - 1 if palette >= CDoom::NUMBONUSPALS

      palette += CDoom::STARTBONUSPALS
    elsif CDoom.plyr.value.powers[CDoom::Powertype::Ironfeet.value] > 4 * 32 ||
          CDoom.plyr.value.powers[CDoom::Powertype::Ironfeet.value] & 8 != 0
      palette = CDoom::RADIATIONPAL
    else
      palette = 0
    end

    if palette != CDoom.st_palette
      CDoom.st_palette = palette
      pal = CDoom.w_cache_lump_num(CDoom.lu_palette, CDoom::PU_CACHE).as(CDoom::Byte*) + palette * 768
      CDoom.i_set_palette(pal)
    end
  end

  def self.st_draw_widgets(refresh : CDoom::DoomBool)
    # used by w_arms[] idgets
    CDoom.st_armson = (CDoom.st_statusbaron != 0 && CDoom.deathmatch == 0).to_unsafe

    # used by w_frags widget
    CDoom.st_fragson = (CDoom.deathmatch != 0 && CDoom.st_statusbaron != 0).to_unsafe

    CDoom.stlib_update_num(pointerof(CDoom.w_ready), refresh)

    4.times do |i|
      CDoom.stlib_update_num(CDoom.w_ammo.to_unsafe + i, refresh)
      CDoom.stlib_update_num(CDoom.w_maxammo.to_unsafe + i, refresh)
    end

    CDoom.stlib_update_percent(pointerof(CDoom.w_health), refresh)
    CDoom.stlib_update_percent(pointerof(CDoom.w_armor), refresh)

    CDoom.stlib_update_bin_icon(pointerof(CDoom.w_armsbg), refresh)

    6.times { |i| CDoom.stlib_update_mult_icon(CDoom.w_arms.to_unsafe + i, refresh) }

    CDoom.stlib_update_mult_icon(pointerof(CDoom.w_faces), refresh)

    3.times { |i| CDoom.stlib_update_mult_icon(CDoom.w_keyboxes.to_unsafe + i, refresh) }

    CDoom.stlib_update_num(pointerof(CDoom.w_frags), refresh)
  end

  def self.st_do_refresh
    CDoom.st_firsttime = 0

    # draw status bar background to off-screen buff
    CDoom.st_refresh_background

    # and refresh all widgets
    CDoom.st_draw_widgets(true)
  end

  def self.st_diff_draw
    # update all widgets
    CDoom.st_draw_widgets(0)
  end

  def self.st_drawer(fullscreen : CDoom::DoomBool, refresh : CDoom::DoomBool)
    CDoom.st_statusbaron = (fullscreen == 0 || CDoom.automapactive != 0).to_unsafe
    CDoom.st_firsttime = (CDoom.st_firsttime != 0 || refresh != 0).to_unsafe

    # Do red-/gold-shifts from damage/items
    CDoom.st_do_palette_stuff

    # If just after st_start(), refresh all
    if CDoom.st_firsttime != 0
      CDoom.st_do_refresh
      # Otherwise, update as little as possible
    else
      CDoom.st_diff_draw
    end
  end

  def self.st_load_graphics
    namebuf = Pointer(UInt8).malloc(9)

    # Load the numbers, tall and short
    10.times do |i|
      CDoom.doom_strcpy(namebuf, "STTNUM")
      CDoom.doom_concat(namebuf, CDoom.doom_itoa(i, 10))
      CDoom.tallnum[i] = CDoom.w_cache_lump_name(namebuf, CDoom::PU_STATIC).as(CDoom::Patch*)

      CDoom.doom_strcpy(namebuf, "STYSNUM")
      CDoom.doom_concat(namebuf, CDoom.doom_itoa(i, 10))
      CDoom.shortnum[i] = CDoom.w_cache_lump_name(namebuf, CDoom::PU_STATIC).as(CDoom::Patch*)
    end

    # Load percent key.
    # Note: why not load STMINUS here, too?
    CDoom.tallpercent = CDoom.w_cache_lump_name("STTPRCNT", CDoom::PU_STATIC).as(CDoom::Patch*)

    # key card
    CDoom::Card::NUMCARDS.value.times do |i|
      CDoom.doom_strcpy(namebuf, "STKEYS")
      CDoom.doom_concat(namebuf, CDoom.doom_itoa(i, 10))
      CDoom.keys[i] = CDoom.w_cache_lump_name(namebuf, CDoom::PU_STATIC).as(CDoom::Patch*)
    end

    # arms background
    CDoom.armsbg = CDoom.w_cache_lump_name("STARMS", CDoom::PU_STATIC).as(CDoom::Patch*)

    # arms ownership widgets
    6.times do |i|
      CDoom.doom_strcpy(namebuf, "STGNUM")
      CDoom.doom_concat(namebuf, CDoom.doom_itoa(i + 2, 10))

      # gray #
      ((CDoom.arms.to_unsafe + i).value.to_unsafe + 0).value = CDoom.w_cache_lump_name(namebuf, CDoom::PU_STATIC).as(CDoom::Patch*)

      # yellow #
      ((CDoom.arms.to_unsafe + i).value.to_unsafe + 1).value = CDoom.shortnum[i + 2]
    end

    # face backgrounds for different color players
    CDoom.doom_strcpy(namebuf, "STFB")
    CDoom.doom_concat(namebuf, CDoom.doom_itoa(CDoom.consoleplayer, 10))
    CDoom.faceback = CDoom.w_cache_lump_name(namebuf, CDoom::PU_STATIC).as(CDoom::Patch*)

    # status bar background bits
    CDoom.sbar = CDoom.w_cache_lump_name("STBAR", CDoom::PU_STATIC).as(CDoom::Patch*)

    # face states
    facenum = 0
    CDoom::ST_NUMPAINFACES.times do |i|
      CDoom::ST_NUMSTRAIGHTFACES.times do |j|
        CDoom.doom_strcpy(namebuf, "STFST")
        CDoom.doom_concat(namebuf, CDoom.doom_itoa(i, 10))
        CDoom.doom_concat(namebuf, CDoom.doom_itoa(j, 10))
        CDoom.faces[facenum] = CDoom.w_cache_lump_name(namebuf, CDoom::PU_STATIC).as(CDoom::Patch*)
        facenum += 1
      end
      CDoom.doom_strcpy(namebuf, "STFTR")
      CDoom.doom_concat(namebuf, CDoom.doom_itoa(i, 10))
      CDoom.doom_concat(namebuf, "0")
      CDoom.faces[facenum] = CDoom.w_cache_lump_name(namebuf, CDoom::PU_STATIC).as(CDoom::Patch*)
      facenum += 1

      CDoom.doom_strcpy(namebuf, "STFTL")
      CDoom.doom_concat(namebuf, CDoom.doom_itoa(i, 10))
      CDoom.doom_concat(namebuf, "0")
      CDoom.faces[facenum] = CDoom.w_cache_lump_name(namebuf, CDoom::PU_STATIC).as(CDoom::Patch*)
      facenum += 1

      CDoom.doom_strcpy(namebuf, "STFOUCH")
      CDoom.doom_concat(namebuf, CDoom.doom_itoa(i, 10))
      CDoom.faces[facenum] = CDoom.w_cache_lump_name(namebuf, CDoom::PU_STATIC).as(CDoom::Patch*)
      facenum += 1

      CDoom.doom_strcpy(namebuf, "STFEVL")
      CDoom.doom_concat(namebuf, CDoom.doom_itoa(i, 10))
      CDoom.faces[facenum] = CDoom.w_cache_lump_name(namebuf, CDoom::PU_STATIC).as(CDoom::Patch*)
      facenum += 1

      CDoom.doom_strcpy(namebuf, "STFKILL")
      CDoom.doom_concat(namebuf, CDoom.doom_itoa(i, 10))
      CDoom.faces[facenum] = CDoom.w_cache_lump_name(namebuf, CDoom::PU_STATIC).as(CDoom::Patch*)
      facenum += 1
    end
    CDoom.faces[facenum] = CDoom.w_cache_lump_name("STFGOD0", CDoom::PU_STATIC).as(CDoom::Patch*)
    facenum += 1
    CDoom.faces[facenum] = CDoom.w_cache_lump_name("STFDEAD0", CDoom::PU_STATIC).as(CDoom::Patch*)
    facenum += 1
  end

  def self.st_load_data
    CDoom.lu_palette = CDoom.w_get_num_for_name("PLAYPAL")
    CDoom.st_load_graphics
  end

  def self.st_unload_graphics
    # unload the numbers, tall and short
    10.times do |i|
      z_change_tag(CDoom.tallnum[i], CDoom::PU_CACHE)
      z_change_tag(CDoom.shortnum[i], CDoom::PU_CACHE)
    end
    # unload tall percent
    z_change_tag(CDoom.tallpercent, CDoom::PU_CACHE)

    # unload arms background
    z_change_tag(CDoom.armsbg, CDoom::PU_CACHE)

    # unload gray #'s
    6.times { |i| z_change_tag(CDoom.arms[i][0], CDoom::PU_CACHE) }

    # unload the key cards
    CDoom::Card::NUMCARDS.value.times { |i| z_change_tag(CDoom.keys[i], CDoom::PU_CACHE) }

    z_change_tag(CDoom.sbar, CDoom::PU_CACHE)
    z_change_tag(CDoom.faceback, CDoom::PU_CACHE)

    CDoom::ST_NUMFACES.times { |i| z_change_tag(CDoom.faces[i], CDoom::PU_CACHE) }

    # Note: nobody ain't seen no unloading
    #   of stminus yet. Dude.
  end

  def self.st_unload_data
    CDoom.st_unload_graphics
  end

  def self.st_init_data
    CDoom.st_firsttime = 1
    CDoom.plyr = CDoom.players.to_unsafe + CDoom.consoleplayer

    CDoom.st_clock = 0
    CDoom.st_chatstate = CDoom::ST_Chatstateenum::StartChatState
    CDoom.st_gamestate = CDoom::ST_Statenum::FirstPersonState

    CDoom.st_statusbaron = 1
    CDoom.st_oldchat = 0
    CDoom.st_chat = 0
    CDoom.st_cursoron = 0

    CDoom.st_faceindex = 0
    CDoom.st_palette = -1

    CDoom.st_oldhealth = -1

    CDoom::Weapontype::NUMWEAPONS.value.times do |i|
      CDoom.oldweaponsowned[i] = CDoom.plyr.value.weaponowned[i]
    end

    3.times { |i| CDoom.keyboxes[i] = -1 }

    CDoom.stlib_init
  end

  def self.st_create_widgets
    # ready weapon ammo
    CDoom.stlib_init_num(pointerof(CDoom.w_ready),
      CDoom::ST_AMMOX,
      CDoom::ST_AMMOY,
      CDoom.tallnum,
      CDoom.plyr.value.ammo.to_unsafe + CDoom.weaponinfo[CDoom.plyr.value.readyweapon.value].ammo.value,
      pointerof(CDoom.st_statusbaron),
      CDoom::ST_AMMOWIDTH)

    # the last weapon type
    CDoom.w_ready.data = CDoom.plyr.value.readyweapon

    # health percentage
    CDoom.stlib_init_percent(pointerof(CDoom.w_health),
      CDoom::ST_HEALTHX,
      CDoom::ST_HEALTHY,
      CDoom.tallnum,
      pointerof(CDoom.plyr.value.@health),
      pointerof(CDoom.st_statusbaron),
      CDoom.tallpercent)

    # arms background
    CDoom.stlib_init_bin_icon(pointerof(CDoom.w_armsbg),
      CDoom::ST_ARMSBGX,
      CDoom::ST_ARMSBGY,
      CDoom.armsbg,
      pointerof(CDoom.st_notdeathmatch),
      pointerof(CDoom.st_statusbaron))

    # weapons owned
    6.times do |i|
      CDoom.stlib_init_mult_icon(CDoom.w_arms.to_unsafe + i,
        CDoom::ST_ARMSX + (i % 3) * CDoom::ST_ARMSXSPACE,
        CDoom::ST_ARMSY + (i // 3) * CDoom::ST_ARMSYSPACE,
        (CDoom.arms.to_unsafe + i).value,
        CDoom.plyr.value.weaponowned.to_unsafe + (i + 1),
        pointerof(CDoom.st_armson))
    end

    # frags sum
    CDoom.stlib_init_num(pointerof(CDoom.w_frags),
      CDoom::ST_FRAGSX,
      CDoom::ST_FRAGSY,
      CDoom.tallnum,
      pointerof(CDoom.st_fragscount),
      pointerof(CDoom.st_fragson),
      CDoom::ST_FRAGSWIDTH)

    # faces
    CDoom.stlib_init_mult_icon(pointerof(CDoom.w_faces),
      CDoom::ST_FACESX,
      CDoom::ST_FACESY,
      CDoom.faces,
      pointerof(CDoom.st_faceindex),
      pointerof(CDoom.st_statusbaron))

    # armor percentage - should be colored later
    CDoom.stlib_init_percent(pointerof(CDoom.w_armor),
      CDoom::ST_ARMORX,
      CDoom::ST_ARMORY,
      CDoom.tallnum,
      pointerof(CDoom.plyr.value.@armorpoints),
      pointerof(CDoom.st_statusbaron),
      CDoom.tallpercent)

    # keyboxes 0-2
    CDoom.stlib_init_mult_icon(CDoom.w_keyboxes.to_unsafe,
      CDoom::ST_KEY0X,
      CDoom::ST_KEY0Y,
      CDoom.keys,
      CDoom.keyboxes.to_unsafe,
      pointerof(CDoom.st_statusbaron))

    CDoom.stlib_init_mult_icon(CDoom.w_keyboxes.to_unsafe + 1,
      CDoom::ST_KEY1X,
      CDoom::ST_KEY1Y,
      CDoom.keys,
      CDoom.keyboxes.to_unsafe + 1,
      pointerof(CDoom.st_statusbaron))

    CDoom.stlib_init_mult_icon(CDoom.w_keyboxes.to_unsafe + 2,
      CDoom::ST_KEY2X,
      CDoom::ST_KEY2Y,
      CDoom.keys,
      CDoom.keyboxes.to_unsafe + 2,
      pointerof(CDoom.st_statusbaron))

    # ammo count (all four kinds)
    CDoom.stlib_init_num(CDoom.w_ammo.to_unsafe,
      CDoom::ST_AMMO0X,
      CDoom::ST_AMMO0Y,
      CDoom.shortnum,
      CDoom.plyr.value.ammo.to_unsafe,
      pointerof(CDoom.st_statusbaron),
      CDoom::ST_AMMO0WIDTH)

    CDoom.stlib_init_num(CDoom.w_ammo.to_unsafe + 1,
      CDoom::ST_AMMO1X,
      CDoom::ST_AMMO1Y,
      CDoom.shortnum,
      CDoom.plyr.value.ammo.to_unsafe + 1,
      pointerof(CDoom.st_statusbaron),
      CDoom::ST_AMMO1WIDTH)

    CDoom.stlib_init_num(CDoom.w_ammo.to_unsafe + 2,
      CDoom::ST_AMMO2X,
      CDoom::ST_AMMO2Y,
      CDoom.shortnum,
      CDoom.plyr.value.ammo.to_unsafe + 2,
      pointerof(CDoom.st_statusbaron),
      CDoom::ST_AMMO2WIDTH)

    CDoom.stlib_init_num(CDoom.w_ammo.to_unsafe + 3,
      CDoom::ST_AMMO3X,
      CDoom::ST_AMMO3Y,
      CDoom.shortnum,
      CDoom.plyr.value.ammo.to_unsafe + 3,
      pointerof(CDoom.st_statusbaron),
      CDoom::ST_AMMO3WIDTH)

    # max ammo count (all four kinds)
    CDoom.stlib_init_num(CDoom.w_maxammo.to_unsafe,
      CDoom::ST_MAXAMMO0X,
      CDoom::ST_MAXAMMO0Y,
      CDoom.shortnum,
      CDoom.plyr.value.maxammo.to_unsafe,
      pointerof(CDoom.st_statusbaron),
      CDoom::ST_MAXAMMO0WIDTH)

    CDoom.stlib_init_num(CDoom.w_maxammo.to_unsafe + 1,
      CDoom::ST_MAXAMMO1X,
      CDoom::ST_MAXAMMO1Y,
      CDoom.shortnum,
      CDoom.plyr.value.maxammo.to_unsafe + 1,
      pointerof(CDoom.st_statusbaron),
      CDoom::ST_MAXAMMO1WIDTH)

    CDoom.stlib_init_num(CDoom.w_maxammo.to_unsafe + 2,
      CDoom::ST_MAXAMMO2X,
      CDoom::ST_MAXAMMO2Y,
      CDoom.shortnum,
      CDoom.plyr.value.maxammo.to_unsafe + 2,
      pointerof(CDoom.st_statusbaron),
      CDoom::ST_MAXAMMO2WIDTH)

    CDoom.stlib_init_num(CDoom.w_maxammo.to_unsafe + 3,
      CDoom::ST_MAXAMMO3X,
      CDoom::ST_MAXAMMO3Y,
      CDoom.shortnum,
      CDoom.plyr.value.maxammo.to_unsafe + 3,
      pointerof(CDoom.st_statusbaron),
      CDoom::ST_MAXAMMO3WIDTH)
  end

  def self.st_start
    CDoom.st_stop if CDoom.st_stopped == 0

    CDoom.st_init_data
    CDoom.st_create_widgets
    CDoom.st_stopped = 0
  end

  def self.st_stop
    return if CDoom.st_stopped != 0

    CDoom.i_set_palette(CDoom.w_cache_lump_num(CDoom.lu_palette, CDoom::PU_CACHE).as(CDoom::Byte*))

    CDoom.st_stopped = 1
  end

  def self.st_init
    CDoom.veryfirsttime = 0
    CDoom.st_load_data
    CDoom.screens[4] = CDoom.z_malloc(CDoom::ST_WIDTH * CDoom::ST_HEIGHT, CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Byte*)
  end

  def self.slope_div(num : LibC::UInt, den : LibC::UInt) : LibC::Int
    return SLOPERANGE if den < 512

    ans = (num << 3)//(den >> 8)

    return ans <= SLOPERANGE ? ans.to_i32! : SLOPERANGE
  end

  def self.v_mark_rect(x : LibC::Int,
                       y : LibC::Int,
                       width : LibC::Int,
                       height : LibC::Int)
    CDoom.m_add_to_box(CDoom.dirtybox, x, y)
    CDoom.m_add_to_box(CDoom.dirtybox, x + width - 1, y + height - 1)
  end

  def self.v_copy_rect(srcx : LibC::Int,
                       srcy : LibC::Int,
                       srcscrn : LibC::Int,
                       width : LibC::Int,
                       height : LibC::Int,
                       destx : LibC::Int,
                       desty : LibC::Int,
                       destscrn : LibC::Int)
    {% if flag?("RANGECHECK") %}
      if srcx < 0 ||
         srcx + width > CDoom::SCREENWIDTH ||
         srcy < 0 || srcy + height > CDoom::SCREENHEIGHT ||
         destx < 0 || destx + width > CDoom::SCREENWIDTH ||
         desty < 0 ||
         desty + height > CDoom::SCREENHEIGHT ||
         srcscrn.to_u32! > 4 ||
         destscrn.to_u32! > 4
        CDoom.i_error("Error: Bad v_copy_rect")
      end
    {% end %}
    CDoom.v_mark_rect(destx, desty, width, height)

    src = CDoom.screens[srcscrn] + CDoom::SCREENWIDTH * srcy + srcx
    dest = CDoom.screens[destscrn] + CDoom::SCREENWIDTH * desty + destx

    while height > 0
      CDoom.doom_memcpy(dest, src, width)
      src += CDoom::SCREENWIDTH
      dest += CDoom::SCREENWIDTH
      height -= 1
    end
  end

  #
  # Masks a column based masked pic to the screen.
  #
  def self.v_draw_patch(x : LibC::Int,
                        y : LibC::Int,
                        scrn : LibC::Int,
                        patch : CDoom::Patch*)
    y -= patch.value.topoffset
    x -= patch.value.leftoffset
    {% if flag?("RANGECHECK") %}
      if x < 0 ||
         x + patch.value.width > CDoom::SCREENWIDTH ||
         y < 0 ||
         y + patch.value.height > CDoom::SCREENHEIGHT ||
         scrn.to_u32! > 4
        # No i_error abort - what is up with TNT.WAD?
        puts "Patch at #{x},#{y}, exceeds LFB"
        puts "v_draw_patch: bad patch (ignored)"
        return
      end
    {% end %}

    if scrn == 0
      CDoom.v_mark_rect(x, y, patch.value.width, patch.value.height)
    end

    col = 0
    desttop = CDoom.screens[scrn] + y * CDoom::SCREENWIDTH + x

    w = patch.value.width

    while col < w
      column = (patch.as(UInt8*) + (patch.value.columnofs.to_unsafe + col).value).as(CDoom::Column*)

      # step through the posts in a column
      until column.value.topdelta == 0xff
        source = column.as(UInt8*) + 3
        dest = desttop + column.value.topdelta.to_u64 * CDoom::SCREENWIDTH
        count = column.value.length

        while count != 0
          count -= 1
          dest.value = source.value
          source += 1
          dest += CDoom::SCREENWIDTH
        end
        column = (column.as(UInt8*) + column.value.length + 4).as(CDoom::Column*)
      end

      x += 1
      col += 1
      desttop += 1
    end
  end

  #
  # Masks a column based masked pic to the screen.
  # Flips horizontally, e.g. to mirror face.
  #
  def self.v_draw_patch_flipped(x : LibC::Int,
                                y : LibC::Int,
                                scrn : LibC::Int,
                                patch : CDoom::Patch*)
    y -= patch.value.topoffset
    x -= patch.value.leftoffset
    {% if flag?("RANGECHECK") %}
      if x < 0 ||
         x + patch.value.width > CDoom::SCREENWIDTH ||
         y < 0 ||
         y + patch.value.height > CDoom::SCREENHEIGHT ||
         scrn.to_u32! > 4
        puts "Patch origin #{x},#{y} exceeds LFB"
        CDoom.i_error("Error: Bad v_draw_patch in v_draw_patch_flipped")
      end
    {% end %}

    if scrn == 0
      CDoom.v_mark_rect(x, y, patch.value.width, patch.value.height)
    end

    col = 0
    desttop = CDoom.screens[scrn] + y * CDoom::SCREENWIDTH + x

    w = patch.value.width

    while col < w
      column = (patch.as(UInt8*) + (patch.value.columnofs.to_unsafe + (w - 1 - col)).value).as(CDoom::Column*)

      # step through the posts in a column
      until column.value.topdelta == 0xff
        source = column.as(UInt8*) + 3
        dest = desttop + column.value.topdelta.to_u64 * CDoom::SCREENWIDTH
        count = column.value.length

        while count != 0
          count -= 1
          dest.value = source.value
          source += 1
          dest += CDoom::SCREENWIDTH
        end
        column = (column.as(UInt8*) + column.value.length + 4).as(CDoom::Column*)
      end

      x += 1
      col += 1
      desttop += 1
    end
  end

  def self.v_draw_patch_rect_direct(x : LibC::Int, y : LibC::Int, scrn : LibC::Int, patch : CDoom::Patch*, src_x : LibC::Int, src_w : LibC::Int)
    y -= patch.value.topoffset
    x -= patch.value.leftoffset
    {% if flag?("RANGECHECK") %}
      if x < 0 ||
         x + patch.value.width > CDoom::SCREENWIDTH ||
         y < 0 ||
         y + patch.value.height > CDoom::SCREENHEIGHT ||
         scrn.to_u32! > 4
        puts "Patch at #{x},#{y}, exceeds LFB"
        # No i_error abort - what is up with TNT.WAD?
        puts "v_draw_patch_rect_direct: bad patch (ignored)"
        return
      end
    {% end %}

    if scrn == 0
      CDoom.v_mark_rect(x, y, src_w, patch.value.height)
    end

    col = 0
    desttop = CDoom.screens[scrn] + y * CDoom::SCREENWIDTH + x

    w = src_w

    while col < w
      column = (patch.as(UInt8*) + (patch.value.columnofs.to_unsafe + (col + src_x)).value).as(CDoom::Column*)

      # step through the posts in a column
      until column.value.topdelta == 0xff
        source = column.as(UInt8*) + 3
        dest = desttop + column.value.topdelta.to_u64 * CDoom::SCREENWIDTH
        count = column.value.length

        while count != 0
          count -= 1
          dest.value = source.value
          source += 1
          dest += CDoom::SCREENWIDTH
        end
        column = (column.as(UInt8*) + column.value.length + 4).as(CDoom::Column*)
      end

      x += 1
      col += 1
      desttop += 1
    end
  end

  #
  # Draws directly to the screen on the pc.
  #
  def self.v_draw_patch_direct(x : LibC::Int,
                               y : LibC::Int,
                               scrn : LibC::Int,
                               patch : CDoom::Patch*)
    CDoom.v_draw_patch(x, y, scrn, patch)
  end

  #
  # Draw a linear block of pixels into the view buffer.
  #
  def self.v_draw_block(x : LibC::Int,
                        y : LibC::Int,
                        scrn : LibC::Int,
                        width : LibC::Int,
                        height : LibC::Int,
                        src : CDoom::Byte*)
    {% if flag?("RANGECHECK") %}
      if x < 0 ||
         x > CDoom::SCREENWIDTH ||
         y < 0 ||
         y > CDoom::SCREENHEIGHT ||
         scrn.to_u32! > 4
        CDoom.i_error("Error: Bad v_draw_block")
      end
    {% end %}

    CDoom.v_mark_rect(x, y, width, height)

    dest = CDoom.screens[scrn] + y * CDoom::SCREENWIDTH + x

    while height != 0
      height -= 1
      CDoom.doom_memcpy(dest, src, width)
      src += width
      dest += CDoom::SCREENWIDTH
    end
  end

  def self.v_get_block(x : LibC::Int,
                       y : LibC::Int,
                       scrn : LibC::Int,
                       width : LibC::Int,
                       height : LibC::Int,
                       dest : CDoom::Byte*)
    {% if flag?("RANGECHECK") %}
      if x < 0 ||
         x > CDoom::SCREENWIDTH ||
         y < 0 ||
         y > CDoom::SCREENHEIGHT ||
         scrn.to_u32! > 4
        CDoom.i_error("Error: Bad v_get_block")
      end
    {% end %}

    src = CDoom.screens[scrn] + y * CDoom::SCREENWIDTH + x

    while height != 0
      height -= 1
      CDoom.doom_memcpy(dest, src, width)
      src += width
      dest += width
    end
  end

  def self.v_init
    # stick these in low dos memory on PCs

    base = CDoom.i_alloc_low(CDoom::SCREENWIDTH * CDoom::SCREENHEIGHT * 4)

    4.times do |i|
      CDoom.screens[i] = base + i * CDoom::SCREENWIDTH * CDoom::SCREENHEIGHT
    end
  end

  def self.doom_strupr(s : LibC::Char*)
    while s.value != 0
      s.value = CDoom.doom_toupper(s.value).to_u8!
      s += 1
    end
  end

  def self.extract_file_base(path : LibC::Char*, dest : LibC::Char*)
    src = path + CDoom.doom_strlen(path) - 1

    # back up until a \ or the start
    while src != path &&
          (src - 1).value != '\\'.ord &&
          (src - 1).value != '/'.ord
      src -= 1
    end

    # copy up to eight characters
    CDoom.doom_memset(dest, 0, 8)
    length = 0

    while src.value != 0 && src.value != '.'.ord
      length += 1
      if length == 9
        CDoom.i_error("Error: Filename base of #{path} >8 chars")
      end

      dest.value = CDoom.doom_toupper(src.value).to_u8!
      dest += 1
      src += 1
    end
  end

  #
  # LUMP BASED ROUTINES.
  #

  #
  # All files are optional, but at least one file must be
  #  found (PWAD, if all required lumps are present).
  # Files with a .wad extension are wadlink files
  #  with multiple lumps.
  # Other files are single lumps with the base filename
  #  for the lump name.
  #
  # If filename starts with a tilde, the file is handled
  #  specially to allow map reloads.
  # But: the reload feature is a fragile hack...
  #
  @@previous_realloc_size = 1

  def self.w_add_file(filename : LibC::Char*)
    allocated = Pointer(CDoom::Filelump).null

    # open the file and add to directory

    # handle reload indicator.
    if filename[0] == '~'.ord
      filename == 1
      CDoom.reloadname = filename
      CDoom.reloadlump = CDoom.numlumps
    end

    if (handle = doom_open(filename, "rb".to_unsafe)).null?
      puts " couldn't open #{String.new(filename)}"
      return
    end

    puts " adding #{String.new(filename)}"
    startlump = CDoom.numlumps

    header = CDoom::Wadinfo.new
    singleinfo = CDoom::Filelump.new

    if CDoom.doom_strcasecmp(filename + CDoom.doom_strlen(filename) - 3, "wad") != 0
      # single lump file
      fileinfo = pointerof(singleinfo)
      singleinfo.filepos = 0
      doom_seek(handle, 0, CDoom::DoomSeek::DOOM_SEEK_END)
      singleinfo.size = doom_tell(handle)
      doom_seek(handle, 0, CDoom::DoomSeek::DOOM_SEEK_SET)
      CDoom.extract_file_base(filename, singleinfo.name)
      CDoom.numlumps += 1
    else
      # WAD file
      doom_read(handle, pointerof(header).as(Void*), sizeof(typeof(header)))
      if CDoom.doom_strncmp(header.identification, "IWAD", 4) != 0
        # Homebrew levels?
        if CDoom.doom_strncmp(header.identification, "PWAD", 4) != 0
          CDoom.i_error("Error: Wad file #{filename} doesn't have IWAD or PWAD id")
        end

        # ???CDoom.modifiedgame = 1
      end
      header.numlumps = header.numlumps
      header.infotableofs = header.infotableofs
      length = header.numlumps * sizeof(CDoom::Filelump)
      fileinfo = GC.malloc(length).as(CDoom::Filelump*)
      allocated = fileinfo
      doom_seek(handle, header.infotableofs, CDoom::DoomSeek::DOOM_SEEK_SET)
      doom_read(handle, fileinfo.as(Void*), length)
      CDoom.numlumps += header.numlumps
    end

    # Fill in lumpinfo
    storehandle = !CDoom.reloadname.null? ? Pointer(Void).null : handle

    i = startlump
    while i < CDoom.numlumps.to_u32!
      @@lumpinfo << CDoom::Lumpinfo.new
      lump_p = @@lumpinfo.to_unsafe + i
      lump_p.value.handle = storehandle
      lump_p.value.position = fileinfo.value.filepos
      lump_p.value.size = fileinfo.value.size
      CDoom.doom_strncpy(lump_p.value.name, fileinfo.value.name, 8)
      i += 1
      fileinfo += 1
    end

    doom_close(handle) if !CDoom.reloadname.null?

    GC.free(allocated.as(Void*)) unless allocated.null?
  end

  def self.w_merge_file(filename : String)
    allocated = Pointer(CDoom::Filelump).null

    # open the file and add to directory

    # handle reload indicator.
    if filename[0] == '~'
      filename == 1
      CDoom.reloadname = filename
      CDoom.reloadlump = CDoom.numlumps
    end

    response = Channel({Bytes, Bool}).new
    @@io_jobs.send({filename, "rb", nil, response})
    data, ok = response.receive
    unless ok
      puts " couldn't open #{filename}"
      return
    end

    puts " adding #{filename}"
    startlump = CDoom.numlumps
    num_merge_lumps = 0

    header = CDoom::Wadinfo.new
    singleinfo = CDoom::Filelump.new
    file = IO::Memory.new(data)
    if filename[-3..-1].downcase.compare("wad") != 0
      # single lump file
      fileinfo = pointerof(singleinfo)
      singleinfo.filepos = 0
      singleinfo.size = file.size
      CDoom.extract_file_base(filename, singleinfo.name)
      num_merge_lumps += 1
    else
      # WAD file
      slice = Slice.new(pointerof(header).as(UInt8*), sizeof(typeof(header)))
      file.read(slice)
      if CDoom.doom_strncmp(header.identification, "IWAD", 4) != 0
        # Homebrew levels?
        if CDoom.doom_strncmp(header.identification, "PWAD", 4) != 0
          CDoom.i_error("Error: Wad file #{filename} doesn't have IWAD or PWAD id")
        end

        # ???CDoom.modifiedgame = 1
      end
      length = header.numlumps * sizeof(CDoom::Filelump)
      fileinfo = GC.malloc(length).as(CDoom::Filelump*)
      allocated = fileinfo
      file.seek(header.infotableofs, IO::Seek::Set)
      slice = Slice.new(fileinfo.as(UInt8*), length)
      file.read(slice)
      num_merge_lumps += header.numlumps
    end

    # Find files in lump and overwrite them
    # Starts from the beginning instead of the end to truly add as an iwad merging
    # Adds the lump if it isn't already found (same as -file)
    mlump = 0
    while mlump < num_merge_lumps
      name_str = String.new((fileinfo + mlump).value.name.to_unsafe, 8).downcase.delete('\0')
      ismap = (name_str[0]? == 'e' && name_str[2]? == 'm') || name_str.starts_with?("map")

      if name_str == "s_start" || name_str == "ss_start" ||
         name_str == "s_end" || name_str == "ss_end" || # Don't overwrite sprite or lump stuff
         name_str == "f_start" || name_str == "ff_start" ||
         name_str == "f_end" || name_str == "ff_end"
        lump_num = CDoom.numlumps
      else
        # Find lump
        lump_num = 0
        CDoom.numlumps.times do |j|
          if String.new(@@lumpinfo[j].name.to_unsafe, 8).downcase.delete('\0') == name_str
            break
          end
          lump_num += 1
        end
      end

      if lump_num == CDoom.numlumps
        # Not been loaded. Initialize lump
        CDoom.numlumps += ismap ? CDoom::ML_BLOCKMAP + 1 : 1

        (ismap ? CDoom::ML_BLOCKMAP + 1 : 1).times do |i|
          @@lumpinfo << CDoom::Lumpinfo.new
        end
        lump_p = @@lumpinfo.to_unsafe + startlump

        startlump += 1
      else
        # Lump exists
        lump_p = @@lumpinfo.to_unsafe + lump_num
      end
      # Set the lump
      if ismap
        (CDoom::ML_BLOCKMAP + 1).times do |m|
          lump_p.value.handle = !CDoom.reloadname.null? ? Pointer(Void).null : Box.box({filename, file, false})
          lump_p.value.position = fileinfo[mlump].filepos
          lump_p.value.size = fileinfo[mlump].size
          CDoom.doom_strncpy(lump_p.value.name, (fileinfo + mlump).value.name, 8)
          lump_p += 1
          mlump += 1
        end
      else
        lump_p.value.handle = !CDoom.reloadname.null? ? Pointer(Void).null : Box.box({filename, file, false})
        lump_p.value.position = fileinfo[mlump].filepos
        lump_p.value.size = fileinfo[mlump].size
        CDoom.doom_strncpy(lump_p.value.name, (fileinfo + mlump).value.name, 8)
        mlump += 1
      end
    end

    file.close if !CDoom.reloadname.null?

    GC.free(allocated.as(Void*)) unless allocated.null?
  end

  #
  # Flushes any of the reloadable lumps in memory
  #  and reloads the directory.
  #
  def self.w_reload
    return if CDoom.reloadname.null?

    if (handle = doom_open(CDoom.reloadname, "rb".to_unsafe)) == 0
      CDoom.i_error("Error: w_reload: couldn't open #{CDoom.reloadname}")
    end

    header = CDoom::Wadinfo.new

    doom_read(handle, pointerof(header).as(Void*), sizeof(typeof(header)))
    lumpcount = header.numlumps
    header.infotableofs = header.infotableofs
    length = lumpcount * sizeof(CDoom::Filelump)
    fileinfo = GC.malloc(length).as(CDoom::Filelump*)
    doom_seek(handle, header.infotableofs, CDoom::DoomSeek::DOOM_SEEK_SET)
    doom_read(handle, fileinfo.as(Void*), length)

    # Fill in lumpinfo
    lump_p = @@lumpinfo.to_unsafe + CDoom.reloadlump

    i = CDoom.reloadlump
    while i < (CDoom.reloadlump + lumpcount).to_u32!
      CDoom.z_free(CDoom.lumpcache[i]) unless CDoom.lumpcache[i].null?

      lump_p.value.position = fileinfo.value.filepos
      lump_p.value.size = fileinfo.value.size

      i += 1
      lump_p += 1
      fileinfo += 1
    end

    doom_close(handle)

    GC.free(fileinfo.as(Void*))
  end

  def self.w_merge_multiple_files(filenames : Array(String))
    # will be realloced as lumps are added

    filenames.each { |fn| w_merge_file(fn) }

    CDoom.i_error("Error: w_merge_multiple_files: no files found") if CDoom.numlumps == 0

    # set up caching
    size = CDoom.numlumps * sizeof(Void*)
    CDoom.lumpcache = GC.malloc(size).as(Void**)

    CDoom.i_error("Error: Couldn't allocate lumpcache") if CDoom.lumpcache.null?

    CDoom.doom_memset(CDoom.lumpcache, 0, size)
  end

  #
  # Pass a null terminated list of files to use.
  # All files are optional, but at least one file
  #  must be found.
  # Files with a .wad extension are idlink files
  #  with multiple lumps.
  # Other files are single lumps with the base filename
  #  for the lump name.
  # Lump names can appear multiple times.
  # The name searcher looks backwards, so a later file
  #  does override all earlier ones.
  #
  def self.w_init_multiple_files(filenames : LibC::Char**)
    # open all the files, load headers, and count lumps
    CDoom.numlumps = 0

    # will be realloced as lumps are added
    @@lumpinfo.clear

    until filenames.value.null?
      CDoom.w_add_file(filenames.value)
      filenames += 1
    end

    CDoom.i_error("Error: w_init_multiple_files: no files found") if CDoom.numlumps == 0

    # set up caching
    size = CDoom.numlumps * sizeof(Void*)
    CDoom.lumpcache = GC.malloc(size).as(Void**)

    CDoom.i_error("Error: Couldn't allocate lumpcache") if CDoom.lumpcache.null?

    CDoom.doom_memset(CDoom.lumpcache, 0, size)
  end

  #
  # Just initialize from a single file.
  #
  def self.w_init_file(filename : LibC::Char*)
    names = Pointer(UInt8*).malloc(2)

    names[0] = filename
    names[1] = Pointer(UInt8).null
    CDoom.w_init_multiple_files(names)
  end

  #
  # Returns -1 if name not found.
  #
  def self.w_check_num_for_name(name : LibC::Char*) : LibC::Int
    # make the name into two integers for easy compares
    name8 = CDoom::Name8.new
    CDoom.doom_strncpy(name8.s, name, 8)

    # in case the name was a fill 8 chars
    name8.s[8] = 0

    # case insensitive
    CDoom.doom_strupr(name8.s)

    v1 = name8.x[0]
    v2 = name8.x[1]

    # scan backwards so patch lump files take precedence
    lump_p = @@lumpinfo.to_unsafe + CDoom.numlumps

    while lump_p != @@lumpinfo.to_unsafe
      lump_p -= 1
      if lump_p.value.name.to_unsafe.as(Int32*).value == v1 &&
         (lump_p.value.name.to_unsafe + 4).as(Int32*).value == v2
        return (lump_p - @@lumpinfo.to_unsafe).to_i32!
      end
    end

    # TFB. Not found.
    return -1
  end

  #
  # Calls w_check_num_for_name, but bombs out if not found.
  #
  def self.w_get_num_for_name(name : LibC::Char*) : LibC::Int
    i = CDoom.w_check_num_for_name(name)

    if i == -1
      if CDoom.doom_strcmp(name, "HELP2") == 0
        name = "HELP1".to_unsafe # Ultimate Doom EXE was modified to use this instead
        i = CDoom.w_check_num_for_name(name)
      end
      if i == -1
        CDoom.i_error("Error: w_get_num_for_name: #{String.new(name)} not found!")
      end
    end

    return i
  end

  #
  # Returns the buffer size needed to load the given lump.
  #
  def self.w_lump_length(lump : LibC::Int) : LibC::Int
    if lump >= CDoom.numlumps
      CDoom.i_error("Error: w_lump_length: #{lump} >= numlumps")
    end

    return @@lumpinfo[lump].size
  end

  #
  # Loads the lump into the given buffer,
  #  which must be >= w_lump_length().
  #
  def self.w_read_lump(lump : LibC::Int, dest : Void*)
    if lump >= CDoom.numlumps
      CDoom.i_error("Error: w_read_lump: #{lump} >= numlumps")
    end

    l = @@lumpinfo.to_unsafe + lump

    if l.value.handle.null?
      # reloadable file, so use open / read / close
      if (handle = doom_open(CDoom.reloadname, "rb".to_unsafe)) == 0
        CDoom.i_error("Error: w_read_lump: couldn't open #{CDoom.reloadname}")
      end
    else
      handle = l.value.handle
    end

    doom_seek(handle, l.value.position, CDoom::DoomSeek::DOOM_SEEK_SET)
    c = doom_read(handle, dest, l.value.size)

    if c < l.value.size
      CDoom.i_error("Error: w_read_lump: only read #{c} of #{l.value.size} on lump #{lump}")
    end

    doom_close(handle) if l.value.handle.null?
  end

  def self.w_cache_lump_num(lump : LibC::Int, tag : LibC::Int) : Void*
    if lump.to_u32! >= CDoom.numlumps.to_u32!
      CDoom.i_error("Error: w_cache_lump_num #{lump} >= numlumps")
    end

    if CDoom.lumpcache[lump].null?
      # read the lump in

      ptr = CDoom.z_malloc(CDoom.w_lump_length(lump), tag, CDoom.lumpcache + lump).as(CDoom::Byte*)
      CDoom.w_read_lump(lump, CDoom.lumpcache[lump])
    else
      z_change_tag(CDoom.lumpcache[lump], tag)
    end

    return CDoom.lumpcache[lump]
  end

  def self.w_cache_lump_name(name : LibC::Char*, tag : LibC::Int) : Void*
    return CDoom.w_cache_lump_num(CDoom.w_get_num_for_name(name), tag)
  end

  def self.wi_slam_background
    CDoom.doom_memcpy(CDoom.screens[0], CDoom.screens[1], CDoom::SCREENWIDTH * CDoom::SCREENHEIGHT)
    CDoom.v_mark_rect(0, 0, CDoom::SCREENWIDTH, CDoom::SCREENHEIGHT)
  end

  #
  # Draws "<Levelname> Finished!"
  #
  def self.wi_draw_lf
    y = CDoom::WI_TITLEY

    # draw <LevelName>
    CDoom.v_draw_patch((CDoom::SCREENWIDTH - CDoom.lnames[CDoom.wbs.value.last].value.width) // 2,
      y, CDoom::FB, CDoom.lnames[CDoom.wbs.value.last])

    # draw "Finished!"
    y += (5 * CDoom.lnames[CDoom.wbs.value.last].value.height) // 4

    CDoom.v_draw_patch((CDoom::SCREENWIDTH - CDoom.finished.value.width) // 2,
      y, CDoom::FB, CDoom.finished)
  end

  #
  # Draws "Entering <LevelName>"
  #
  def self.wi_draw_el
    y = CDoom::WI_TITLEY

    # draw "Entering"
    CDoom.v_draw_patch((CDoom::SCREENWIDTH - CDoom.entering.value.width) // 2,
      y, CDoom::FB, CDoom.entering)

    # draw level
    y += (5 * CDoom.lnames[CDoom.wbs.value.next].value.height) // 4

    CDoom.v_draw_patch((CDoom::SCREENWIDTH - CDoom.lnames[CDoom.wbs.value.next].value.width) // 2,
      y, CDoom::FB, CDoom.lnames[CDoom.wbs.value.next])
  end

  def self.wi_draw_on_lnode(n : LibC::Int, c : CDoom::Patch**)
    fits = false

    i = 0
    loop do
      left = CDoom.lnodes[CDoom.wbs.value.epsd][n].x - c[i].value.leftoffset
      top = CDoom.lnodes[CDoom.wbs.value.epsd][n].y - c[i].value.topoffset
      right = left + c[i].value.width
      bottom = top + c[i].value.height

      if left >= 0 &&
         right < CDoom::SCREENWIDTH &&
         top >= 0 &&
         bottom < CDoom::SCREENHEIGHT
        fits = true
      else
        i += 1
      end

      break unless !fits && i != 2
    end

    if fits && i < 2
      CDoom.v_draw_patch(CDoom.lnodes[CDoom.wbs.value.epsd][n].x,
        CDoom.lnodes[CDoom.wbs.value.epsd][n].y,
        CDoom::FB, c[i])
    else
      # DEBUG
      puts "Could not place patch on level #{n + 1}"
    end
  end

  def self.wi_init_animated_back
    return if CDoom.gamemode == CDoom::GameMode::Commercial

    return if CDoom.wbs.value.epsd > 2

    CDoom.numanims[CDoom.wbs.value.epsd].times do |i|
      a = CDoom.anims_wi_stuff[CDoom.wbs.value.epsd] + i

      # init variables
      a.value.ctr = -1

      # specify the next time to draw it
      if a.value.type == CDoom::Animenum::Always
        a.value.nexttic = CDoom.bcnt + 1 + (CDoom.m_random % a.value.period)
      elsif a.value.type == CDoom::Animenum::Random
        a.value.nexttic = CDoom.bcnt + 1 + a.value.data2 + (CDoom.m_random % a.value.data1)
      elsif a.value.type == CDoom::Animenum::Level
        a.value.nexttic = CDoom.bcnt + 1
      end
    end
  end

  def self.wi_update_animated_back
    return if CDoom.gamemode == CDoom::GameMode::Commercial

    return if CDoom.wbs.value.epsd > 2

    CDoom.numanims[CDoom.wbs.value.epsd].times do |i|
      a = CDoom.anims_wi_stuff[CDoom.wbs.value.epsd] + i

      if CDoom.bcnt == a.value.nexttic
        case a.value.type
        when CDoom::Animenum::Always
          a.value.ctr = 0 if (a.value.ctr = a.value.ctr + 1) >= a.value.nanims
          a.value.nexttic = CDoom.bcnt + a.value.period
        when CDoom::Animenum::Random
          a.value.ctr = a.value.ctr + 1
          if a.value.ctr == a.value.nanims
            a.value.ctr = -1
            a.value.nexttic = CDoom.bcnt + a.value.data2 + (CDoom.m_random % a.value.data1)
          else
            a.value.nexttic = CDoom.bcnt + a.value.period
          end
        when CDoom::Animenum::Level
          # gawd-awful hack for level anims
          if !(CDoom.state == CDoom::Stateenum::StatCount && i == 7) &&
             CDoom.wbs.value.next == a.value.data1
            a.value.ctr = a.value.ctr + 1
            a.value.ctr = a.value.ctr - 1 if a.value.ctr == a.value.nanims
            a.value.nexttic = CDoom.bcnt + a.value.period
          end
        end
      end
    end
  end

  def self.wi_draw_animated_back
    return if CDoom.gamemode == CDoom::GameMode::Commercial

    return if CDoom.wbs.value.epsd > 2

    CDoom.numanims[CDoom.wbs.value.epsd].times do |i|
      a = CDoom.anims_wi_stuff[CDoom.wbs.value.epsd] + i

      CDoom.v_draw_patch(a.value.loc.x,
        a.value.loc.y,
        CDoom::FB,
        a.value.p[a.value.ctr]) if a.value.ctr >= 0
    end
  end

  #
  # Draws a number.
  # If digits > 0, then use that many digits minimum,
  #  otherwise only use as many as necessary.
  # Returns new x position.
  #
  def self.wi_draw_num(x : LibC::Int, y : LibC::Int, n : LibC::Int, digits : LibC::Int) : LibC::Int
    fontwidth = CDoom.num[0].value.width

    if digits < 0
      if n == 0
        # make variable-length zeros 1 digit long
        digits = 1
      else
        # figure out # of digits in #
        digits = 0
        temp = n

        while temp != 0
          temp //= 10
          digits += 1
        end
      end
    end

    neg = n < 0
    n = -n if neg

    # if non-number, do not draw it
    return 0 if n == 1994

    # draw the new number

    while digits != 0
      digits -= 1
      x -= fontwidth
      CDoom.v_draw_patch(x, y, CDoom::FB, CDoom.num[n % 10])
      n //= 10
    end

    # draw a minus sign if necessary
    CDoom.v_draw_patch(x -= 8, y, CDoom::FB, CDoom.wiminus) if neg

    return x
  end

  def self.wi_draw_percent(x : LibC::Int, y : LibC::Int, p : LibC::Int)
    return if p < 0

    CDoom.v_draw_patch(x, y, CDoom::FB, CDoom.percent)
    CDoom.wi_draw_num(x, y, p, -1)
  end

  #
  # Display level completion time and par,
  #  or "sucks" message if overflow.
  #
  def self.wi_draw_time(x : LibC::Int, y : LibC::Int, t : LibC::Int)
    return if t < 0

    if t <= 61 * 59
      div = 1

      loop do
        n = (t // div) % 60
        x = CDoom.wi_draw_num(x, y, n, 2) - CDoom.colon.value.width
        div *= 60

        # draw
        CDoom.v_draw_patch(x, y, CDoom::FB, CDoom.colon) if div == 60 || t // div != 0

        break unless t // div != 0
      end
    else
      # "sucks"
      CDoom.v_draw_patch(x - CDoom.sucks.value.width, y, CDoom::FB, CDoom.sucks)
    end
  end

  def self.wi_end
    CDoom.wi_unload_data
  end

  def self.wi_init_no_state
    CDoom.state = CDoom::Stateenum::NoState
    CDoom.acceleratestage = 0
    CDoom.cnt = 10
  end

  def self.wi_update_no_state
    CDoom.wi_update_animated_back

    if (CDoom.cnt -= 1) == 0
      CDoom.wi_end
      CDoom.g_world_done
    end
  end

  def self.wi_init_show_next_loc
    CDoom.state = CDoom::Stateenum::ShowNextLoc
    CDoom.acceleratestage = 0
    CDoom.cnt = CDoom::SHOWNEXTLOCDELAY * CDoom::TICRATE

    CDoom.wi_init_animated_back
  end

  def self.wi_update_show_next_loc
    CDoom.wi_update_animated_back

    if (CDoom.cnt -= 1) == 0 || CDoom.acceleratestage != 0
      CDoom.wi_init_no_state
    else
      CDoom.snl_pointeron = ((CDoom.cnt & 31) < 20).to_unsafe
    end
  end

  def self.wi_draw_show_next_loc
    CDoom.wi_slam_background

    # draw animated background
    CDoom.wi_draw_animated_back

    if CDoom.gamemode != CDoom::GameMode::Commercial
      if CDoom.wbs.value.epsd > 2
        CDoom.wi_draw_el
        return
      end

      last = (CDoom.wbs.value.last == 8) ? CDoom.wbs.value.next - 1 : CDoom.wbs.value.last

      # draw a splat on taken cities.
      (last + 1).times { |i| CDoom.wi_draw_on_lnode(i, pointerof(CDoom.splat)) }

      # splat the secret level?
      CDoom.wi_draw_on_lnode(8, pointerof(CDoom.splat)) if CDoom.wbs.value.didsecret != 0

      # draw flashint ptr
      CDoom.wi_draw_on_lnode(CDoom.wbs.value.next, CDoom.yah) if CDoom.snl_pointeron != 0
    end

    # draws which level yo uare entering..
    if CDoom.gamemode != CDoom::GameMode::Commercial ||
       CDoom.wbs.value.next != 30
      CDoom.wi_draw_el
    end
  end

  def self.wi_draw_no_state
    CDoom.snl_pointeron = 1
    CDoom.wi_draw_show_next_loc
  end

  def self.wi_frag_sum(playernum : LibC::Int) : LibC::Int
    frags = 0

    CDoom::MAXPLAYERS.times do |i|
      if CDoom.playeringame[i] != 0 &&
         i != playernum
        frags += CDoom.plrs[playernum].frags[i]
      end
    end

    # JDC hack - negative frags.
    frags -= CDoom.plrs[playernum].frags[playernum]

    return frags
  end

  def self.wi_init_deathmatch_stats
    CDoom.state = CDoom::Stateenum::StatCount
    CDoom.acceleratestage = 0
    CDoom.dm_state = 1

    CDoom.cnt_pause = CDoom::TICRATE

    CDoom::MAXPLAYERS.times do |i|
      if CDoom.playeringame[i] != 0
        CDoom::MAXPLAYERS.times do |j|
          ((CDoom.dm_frags.to_unsafe + i).value.to_unsafe + j).value = 0 if CDoom.playeringame[j] != 0
        end

        CDoom.dm_totals[i] = 0
      end
    end

    CDoom.wi_init_animated_back
  end

  def self.wi_update_deathmatch_stats
    CDoom.wi_update_animated_back

    if CDoom.acceleratestage != 0 && CDoom.dm_state != 4
      CDoom.acceleratestage = 0

      CDoom::MAXPLAYERS.times do |i|
        if CDoom.playeringame[i] != 0
          CDoom::MAXPLAYERS.times do |j|
            ((CDoom.dm_frags.to_unsafe + i).value.to_unsafe + j).value = CDoom.plrs[i].frags[j] if CDoom.playeringame[j] != 0
          end

          CDoom.dm_totals[i] = CDoom.wi_frag_sum(i)
        end
      end

      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_barexp.value)
      CDoom.dm_state = 4
    end

    if CDoom.dm_state == 2
      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_pistol.value) if CDoom.bcnt & 3 == 0

      stillticking = false

      CDoom::MAXPLAYERS.times do |i|
        if CDoom.playeringame[i] != 0
          CDoom::MAXPLAYERS.times do |j|
            if CDoom.playeringame[j] != 0 &&
               CDoom.dm_frags[i][j] != CDoom.plrs[i].frags[j]
              if CDoom.plrs[i].frags[j] < 0
                ((CDoom.dm_frags.to_unsafe + i).value.to_unsafe + j).value = CDoom.dm_frags[i][j] - 1
              else
                ((CDoom.dm_frags.to_unsafe + i).value.to_unsafe + j).value = CDoom.dm_frags[i][j] + 1
              end

              if CDoom.dm_frags[i][j] > 99
                ((CDoom.dm_frags.to_unsafe + i).value.to_unsafe + j).value = 99
              end
              if CDoom.dm_frags[i][j] < -99
                ((CDoom.dm_frags.to_unsafe + i).value.to_unsafe + j).value = -99
              end

              stillticking = true
            end
          end
          CDoom.dm_totals[i] = CDoom.wi_frag_sum(i)

          CDoom.dm_totals[i] = 99 if CDoom.dm_totals[i] > 99
          CDoom.dm_totals[i] = -99 if CDoom.dm_totals[i] < -99
        end
      end
      if !stillticking
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_barexp.value)
        CDoom.dm_state += 1
      end
    elsif CDoom.dm_state == 4
      if CDoom.acceleratestage != 0
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_slop.value)

        if CDoom.gamemode == CDoom::GameMode::Commercial
          CDoom.wi_init_no_state
        else
          CDoom.wi_init_show_next_loc
        end
      end
    elsif CDoom.dm_state & 1 != 0
      if (CDoom.cnt_pause -= 1) == 0
        CDoom.dm_state += 1
        CDoom.cnt_pause = CDoom::TICRATE
      end
    end
  end

  def self.wi_draw_deathmatch_stats
    lh = CDoom::WI_SPACINGY # line height

    CDoom.wi_slam_background

    # draw animated background
    CDoom.wi_draw_animated_back
    CDoom.wi_draw_lf

    # draw stat titles (top line)
    CDoom.v_draw_patch(CDoom::DM_TOTALSX - CDoom.total.value.width // 2,
      CDoom::DM_MATRIXY - CDoom::WI_SPACINGY + 10,
      CDoom::FB, CDoom.total)

    CDoom.v_draw_patch(CDoom::DM_KILLERSX, CDoom::DM_KILLERSY, CDoom::FB, CDoom.killers)
    CDoom.v_draw_patch(CDoom::DM_VICTIMSX, CDoom::DM_VICTIMSY, CDoom::FB, CDoom.victims)

    # draw P?
    x = CDoom::DM_MATRIXX + CDoom::DM_SPACINGX
    y = CDoom::DM_MATRIXY

    CDoom::MAXPLAYERS.times do |i|
      if CDoom.playeringame[i] != 0
        CDoom.v_draw_patch(x - CDoom.p[i].value.width // 2,
          CDoom::DM_MATRIXY - CDoom::WI_SPACINGY,
          CDoom::FB, CDoom.p[i])

        CDoom.v_draw_patch(CDoom::DM_MATRIXX - CDoom.p[i].value.width // 2,
          y,
          CDoom::FB, CDoom.p[i])

        if i == CDoom.me
          CDoom.v_draw_patch(x - CDoom.p[i].value.width // 2,
            CDoom::DM_MATRIXY - CDoom::WI_SPACINGY,
            CDoom::FB, CDoom.bstar)

          CDoom.v_draw_patch(CDoom::DM_MATRIXX - CDoom.p[i].value.width // 2,
            y,
            CDoom::FB, CDoom.star)
        end
      end
      x += CDoom::DM_SPACINGX
      y += CDoom::WI_SPACINGY
    end

    # draw stats
    y = CDoom::DM_MATRIXY + 10
    w = CDoom.num[0].value.width

    CDoom::MAXPLAYERS.times do |i|
      x = CDoom::DM_MATRIXX + CDoom::DM_SPACINGX

      if CDoom.playeringame[i] != 0
        CDoom::MAXPLAYERS.times do |j|
          CDoom.wi_draw_num(x + w, y, CDoom.dm_frags[i][j], 2) if CDoom.playeringame[j] != 0

          x += CDoom::DM_SPACINGX
        end
        CDoom.wi_draw_num(CDoom::DM_TOTALSX + w, y, CDoom.dm_totals[i], 2)
      end
      y += CDoom::WI_SPACINGY
    end
  end

  def self.wi_init_netgame_stats
    CDoom.state = CDoom::Stateenum::StatCount
    CDoom.acceleratestage = 0
    CDoom.ng_state = 1

    CDoom.cnt_pause = CDoom::TICRATE

    CDoom::MAXPLAYERS.times do |i|
      next if CDoom.playeringame[i] == 0

      CDoom.cnt_kills[i] = 0
      CDoom.cnt_items[i] = 0
      CDoom.cnt_secret[i] = 0
      CDoom.cnt_frags[i] = 0

      CDoom.dofrags += CDoom.wi_frag_sum(i)
    end

    CDoom.dofrags = ((CDoom.dofrags == 0).to_unsafe == 0).to_unsafe

    CDoom.wi_init_animated_back
  end

  def self.wi_update_netgame_stats
    CDoom.wi_update_animated_back

    if CDoom.acceleratestage != 0 && CDoom.ng_state != 10
      CDoom.acceleratestage = 0

      CDoom::MAXPLAYERS.times do |i|
        next if CDoom.playeringame[i] == 0

        CDoom.cnt_kills[i] = (CDoom.plrs[i].skills * 100) // CDoom.wbs.value.maxkills
        CDoom.cnt_items[i] = (CDoom.plrs[i].sitems * 100) // CDoom.wbs.value.maxitems
        CDoom.cnt_secret[i] = (CDoom.plrs[i].ssecret * 100) // CDoom.wbs.value.maxsecret

        CDoom.cnt_frags[i] = CDoom.wi_frag_sum(i) if CDoom.dofrags != 0
      end
      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_barexp.value)
      CDoom.ng_state = 10
    end

    if CDoom.ng_state == 2
      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_pistol.value) if CDoom.bcnt & 3 == 0

      stillticking = false

      CDoom::MAXPLAYERS.times do |i|
        next if CDoom.playeringame[i] == 0

        CDoom.cnt_kills[i] = CDoom.cnt_kills[i] + 2

        if CDoom.cnt_kills[i] >= (CDoom.plrs[i].skills * 100) // CDoom.wbs.value.maxkills
          CDoom.cnt_kills[i] = (CDoom.plrs[i].skills * 100) // CDoom.wbs.value.maxkills
        else
          stillticking = true
        end
      end

      if !stillticking
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_barexp.value)
        CDoom.ng_state += 1
      end
    elsif CDoom.ng_state == 4
      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_pistol.value) if CDoom.bcnt & 3 == 0

      stillticking = false

      CDoom::MAXPLAYERS.times do |i|
        next if CDoom.playeringame[i] == 0

        CDoom.cnt_items[i] = CDoom.cnt_items[i] + 2

        if CDoom.cnt_items[i] >= (CDoom.plrs[i].sitems * 100) // CDoom.wbs.value.maxitems
          CDoom.cnt_items[i] = (CDoom.plrs[i].sitems * 100) // CDoom.wbs.value.maxitems
        else
          stillticking = true
        end
      end

      if !stillticking
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_barexp.value)
        CDoom.ng_state += 1
      end
    elsif CDoom.ng_state == 6
      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_pistol.value) if CDoom.bcnt & 3 == 0

      stillticking = false

      CDoom::MAXPLAYERS.times do |i|
        next if CDoom.playeringame[i] == 0

        CDoom.cnt_secret[i] = CDoom.cnt_secret[i] + 2

        if CDoom.cnt_secret[i] >= (CDoom.plrs[i].ssecret * 100) // CDoom.wbs.value.maxsecret
          CDoom.cnt_secret[i] = (CDoom.plrs[i].ssecret * 100) // CDoom.wbs.value.maxsecret
        else
          stillticking = true
        end
      end

      if !stillticking
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_barexp.value)
        CDoom.ng_state += 1 + 2 * (CDoom.dofrags == 0).to_unsafe
      end
    elsif CDoom.ng_state == 8
      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_pistol.value) if CDoom.bcnt & 3 == 0

      stillticking = false

      CDoom::MAXPLAYERS.times do |i|
        next if CDoom.playeringame[i] == 0

        CDoom.cnt_frags[i] = CDoom.cnt_frags[i] + 1

        if CDoom.cnt_frags[i] >= (fsum = CDoom.wi_frag_sum(i))
          CDoom.cnt_frags[i] = fsum
        else
          stillticking = true
        end
      end

      if !stillticking
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_pldeth.value)
        CDoom.ng_state += 1
      end
    elsif CDoom.ng_state == 10
      if CDoom.acceleratestage != 0
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_sgcock.value)
        if CDoom.gamemode == CDoom::GameMode::Commercial
          CDoom.wi_init_no_state
        else
          CDoom.wi_init_show_next_loc
        end
      end
    elsif CDoom.ng_state & 1 != 0
      if (CDoom.cnt_pause -= 1) == 0
        CDoom.ng_state += 1
        CDoom.cnt_pause = CDoom::TICRATE
      end
    end
  end

  def self.wi_draw_netgame_stats
    pwidth = CDoom.percent.value.width

    CDoom.wi_slam_background

    # draw animated background
    CDoom.wi_draw_animated_back

    CDoom.wi_draw_lf

    # draw stat titles (top line)
    CDoom.v_draw_patch(ng_statsx + CDoom::NG_SPACINGX - CDoom.kills.value.width,
      CDoom::NG_STATSY, CDoom::FB, CDoom.kills)

    CDoom.v_draw_patch(ng_statsx + 2 * CDoom::NG_SPACINGX - CDoom.items.value.width,
      CDoom::NG_STATSY, CDoom::FB, CDoom.items)

    CDoom.v_draw_patch(ng_statsx + 3 * CDoom::NG_SPACINGX - CDoom.secret.value.width,
      CDoom::NG_STATSY, CDoom::FB, CDoom.secret)

    if CDoom.dofrags != 0
      CDoom.v_draw_patch(ng_statsx + 4 * CDoom::NG_SPACINGX - CDoom.frags.value.width,
        CDoom::NG_STATSY, CDoom::FB, CDoom.frags)
    end

    # draw stats
    y = CDoom::NG_STATSY + CDoom.kills.value.height

    CDoom::MAXPLAYERS.times do |i|
      next if CDoom.playeringame[i] == 0

      x = ng_statsx
      CDoom.v_draw_patch(x - CDoom.p[i].value.width, y, CDoom::FB, CDoom.p[i])

      CDoom.v_draw_patch(x - CDoom.p[i].value.width, y, CDoom::FB, CDoom.star) if i == CDoom.me

      x += CDoom::NG_SPACINGX
      CDoom.wi_draw_percent(x - pwidth, y + 10, CDoom.cnt_kills[i])
      x += CDoom::NG_SPACINGX
      CDoom.wi_draw_percent(x - pwidth, y + 10, CDoom.cnt_items[i])
      x += CDoom::NG_SPACINGX
      CDoom.wi_draw_percent(x - pwidth, y + 10, CDoom.cnt_secret[i])
      x += CDoom::NG_SPACINGX

      if CDoom.dofrags != 0
        CDoom.wi_draw_num(x, y + 10, CDoom.cnt_frags[i], -1)
      end

      y += CDoom::WI_SPACINGY
    end
  end

  def self.wi_init_stats
    CDoom.state = CDoom::Stateenum::StatCount
    CDoom.acceleratestage = 0
    CDoom.sp_state = 1
    CDoom.cnt_kills[0] = -1
    CDoom.cnt_items[0] = -1
    CDoom.cnt_secret[0] = -1
    CDoom.cnt_time = -1
    CDoom.cnt_par = -1
    CDoom.cnt_pause = CDoom::TICRATE

    CDoom.wi_init_animated_back
  end

  def self.wi_update_stats
    CDoom.wi_update_animated_back

    if CDoom.acceleratestage != 0 && CDoom.sp_state != 10
      CDoom.acceleratestage = 0

      CDoom.cnt_kills[0] = (CDoom.plrs[CDoom.me].skills * 100) // CDoom.wbs.value.maxkills
      CDoom.cnt_items[0] = (CDoom.plrs[CDoom.me].sitems * 100) // CDoom.wbs.value.maxitems
      CDoom.cnt_secret[0] = (CDoom.plrs[CDoom.me].ssecret * 100) // CDoom.wbs.value.maxsecret
      CDoom.cnt_time = CDoom.plrs[CDoom.me].stime // CDoom::TICRATE
      CDoom.cnt_par = CDoom.wbs.value.partime // CDoom::TICRATE
      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_barexp.value)
      CDoom.sp_state = 10
    end

    if CDoom.sp_state == 2
      CDoom.cnt_kills[0] = CDoom.cnt_kills[0] + 2

      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_pistol.value) if CDoom.bcnt & 3 == 0

      if CDoom.cnt_kills[0] >= (CDoom.plrs[CDoom.me].skills * 100) // CDoom.wbs.value.maxkills
        CDoom.cnt_kills[0] = (CDoom.plrs[CDoom.me].skills * 100) // CDoom.wbs.value.maxkills
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_barexp.value)
        CDoom.sp_state += 1
      end
    elsif CDoom.sp_state == 4
      CDoom.cnt_items[0] = CDoom.cnt_items[0] + 2

      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_pistol.value) if CDoom.bcnt & 3 == 0

      if CDoom.cnt_items[0] >= (CDoom.plrs[CDoom.me].sitems * 100) // CDoom.wbs.value.maxitems
        CDoom.cnt_items[0] = (CDoom.plrs[CDoom.me].sitems * 100) // CDoom.wbs.value.maxitems
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_barexp.value)
        CDoom.sp_state += 1
      end
    elsif CDoom.sp_state == 6
      CDoom.cnt_secret[0] = CDoom.cnt_secret[0] + 2

      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_pistol.value) if CDoom.bcnt & 3 == 0

      if CDoom.cnt_secret[0] >= (CDoom.plrs[CDoom.me].ssecret * 100) // CDoom.wbs.value.maxsecret
        CDoom.cnt_secret[0] = (CDoom.plrs[CDoom.me].ssecret * 100) // CDoom.wbs.value.maxsecret
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_barexp.value)
        CDoom.sp_state += 1
      end
    elsif CDoom.sp_state == 8
      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_pistol.value) if CDoom.bcnt & 3 == 0

      CDoom.cnt_time += 3

      if CDoom.cnt_time >= CDoom.plrs[CDoom.me].stime // CDoom::TICRATE
        CDoom.cnt_time = CDoom.plrs[CDoom.me].stime // CDoom::TICRATE
      end

      CDoom.cnt_par += 3

      if CDoom.cnt_par >= CDoom.wbs.value.partime // CDoom::TICRATE
        CDoom.cnt_par = CDoom.wbs.value.partime // CDoom::TICRATE

        if CDoom.cnt_time >= CDoom.plrs[CDoom.me].stime // CDoom::TICRATE
          CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_barexp.value)
          CDoom.sp_state += 1
        end
      end
    elsif CDoom.sp_state == 10
      if CDoom.acceleratestage != 0
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_sgcock.value)
        if CDoom.gamemode == CDoom::GameMode::Commercial
          CDoom.wi_init_no_state
        else
          CDoom.wi_init_show_next_loc
        end
      end
    elsif CDoom.sp_state & 1 != 0
      if (CDoom.cnt_pause -= 1) == 0
        CDoom.sp_state += 1
        CDoom.cnt_pause = CDoom::TICRATE
      end
    end
  end

  def self.wi_draw_stats
    lh = (3 * CDoom.num[0].value.height) // 2

    CDoom.wi_slam_background

    # draw animated background
    CDoom.wi_draw_animated_back

    CDoom.wi_draw_lf

    CDoom.v_draw_patch(CDoom::SP_STATSX, CDoom::SP_STATSY, CDoom::FB, CDoom.kills)
    CDoom.wi_draw_percent(CDoom::SCREENWIDTH - CDoom::SP_STATSX, CDoom::SP_STATSY, CDoom.cnt_kills[0])

    CDoom.v_draw_patch(CDoom::SP_STATSX, CDoom::SP_STATSY + lh, CDoom::FB, CDoom.items)
    CDoom.wi_draw_percent(CDoom::SCREENWIDTH - CDoom::SP_STATSX, CDoom::SP_STATSY + lh, CDoom.cnt_items[0])

    CDoom.v_draw_patch(CDoom::SP_STATSX, CDoom::SP_STATSY + 2 * lh, CDoom::FB, CDoom.sp_secret)
    CDoom.wi_draw_percent(CDoom::SCREENWIDTH - CDoom::SP_STATSX, CDoom::SP_STATSY + 2 * lh, CDoom.cnt_secret[0])

    CDoom.v_draw_patch(CDoom::SP_TIMEX, CDoom::SP_TIMEY, CDoom::FB, CDoom.time_patch)
    CDoom.wi_draw_time(CDoom::SCREENWIDTH // 2 - CDoom::SP_TIMEX, CDoom::SP_TIMEY, CDoom.cnt_time)

    CDoom.v_draw_patch(CDoom::SCREENWIDTH // 2 + CDoom::SP_TIMEX, CDoom::SP_TIMEY, CDoom::FB, CDoom.par)
    CDoom.wi_draw_time(CDoom::SCREENWIDTH - CDoom::SP_TIMEX, CDoom::SP_TIMEY, CDoom.cnt_par)
  end

  def self.wi_check_for_accelerate
    # check for button presses to skip delays
    player = CDoom.players.to_unsafe
    CDoom::MAXPLAYERS.times do |i|
      if CDoom.playeringame[i] != 0
        if player.value.cmd.buttons & CDoom::Buttoncode::BT_ATTACK.value != 0
          CDoom.acceleratestage = 1 if player.value.attackdown == 0
          player.value.attackdown = 1
        else
          player.value.attackdown = 0
        end
        if player.value.cmd.buttons & CDoom::Buttoncode::BT_USE.value != 0
          CDoom.acceleratestage = 1 if player.value.usedown == 0
          player.value.usedown = 1
        else
          player.value.usedown = 0
        end
      end

      player += 1
    end
  end

  #
  # Updates stuff each tick
  #
  def self.wi_ticker
    # counter for general background animation
    CDoom.bcnt += 1

    if CDoom.bcnt == 1
      # intermission music
      if CDoom.gamemode == CDoom::GameMode::Commercial
        CDoom.s_change_music(CDoom::Musicenum::MUS_dm2int, 1)
      else
        CDoom.s_change_music(CDoom::Musicenum::MUS_inter, 1)
      end
    end

    CDoom.wi_check_for_accelerate

    case CDoom.state
    when CDoom::Stateenum::StatCount
      if CDoom.deathmatch != 0
        CDoom.wi_update_deathmatch_stats
      elsif CDoom.netgame != 0
        CDoom.wi_update_netgame_stats
      else
        CDoom.wi_update_stats
      end
    when CDoom::Stateenum::ShowNextLoc
      CDoom.wi_update_show_next_loc
    when CDoom::Stateenum::NoState
      CDoom.wi_update_no_state
    end
  end

  def self.wi_load_data
    name = Pointer(UInt8).malloc(9)

    if CDoom.gamemode == CDoom::GameMode::Commercial
      CDoom.doom_strcpy(name, "INTERPIC")
    else
      CDoom.doom_strcpy(name, "WIMAP")
      CDoom.doom_concat(name, CDoom.doom_itoa(CDoom.wbs.value.epsd, 10))
    end

    if CDoom.gamemode == CDoom::GameMode::Retail &&
       CDoom.wbs.value.epsd == 3
      CDoom.doom_strcpy(name, "INTERPIC")
    end

    # background
    CDoom.bg = CDoom.w_cache_lump_name(name, CDoom::PU_CACHE).as(CDoom::Patch*)
    CDoom.v_draw_patch(0, 0, 1, CDoom.bg)

    if CDoom.gamemode == CDoom::GameMode::Commercial
      CDoom.numcmaps = 32
      CDoom.lnames = CDoom.z_malloc(sizeof(CDoom::Patch*) * CDoom.numcmaps,
        CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Patch**)

      CDoom.numcmaps.times do |i|
        CDoom.doom_strcpy(name, "CWILV")
        CDoom.doom_concat(name, "0") if i < 10
        CDoom.doom_concat(name, CDoom.doom_itoa(i, 10))
        CDoom.lnames[i] = CDoom.w_cache_lump_name(name, CDoom::PU_STATIC).as(CDoom::Patch*)
      end
    else
      CDoom.lnames = CDoom.z_malloc(sizeof(CDoom::Patch*) * CDoom::NUMMAPS,
        CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Patch**)

      CDoom::NUMMAPS.times do |i|
        CDoom.doom_strcpy(name, "WILV")
        CDoom.doom_concat(name, CDoom.doom_itoa(CDoom.wbs.value.epsd, 10))
        CDoom.doom_concat(name, CDoom.doom_itoa(i, 10))
        CDoom.lnames[i] = CDoom.w_cache_lump_name(name, CDoom::PU_STATIC).as(CDoom::Patch*)
      end

      # you are here
      CDoom.yah[0] = CDoom.w_cache_lump_name("WIURH0", CDoom::PU_STATIC).as(CDoom::Patch*)

      # you are here (alt.)
      CDoom.yah[1] = CDoom.w_cache_lump_name("WIURH1", CDoom::PU_STATIC).as(CDoom::Patch*)

      # splat
      CDoom.splat = CDoom.w_cache_lump_name("WISPLAT", CDoom::PU_STATIC).as(CDoom::Patch*)

      if CDoom.wbs.value.epsd < 3
        CDoom.numanims[CDoom.wbs.value.epsd].times do |j|
          a = CDoom.anims_wi_stuff[CDoom.wbs.value.epsd] + j
          a.value.nanims.times do |i|
            # MONDO HACK!
            if CDoom.wbs.value.epsd != 1 || j != 8
              # animations
              CDoom.doom_strcpy(name, "WIA")
              CDoom.doom_concat(name, CDoom.doom_itoa(CDoom.wbs.value.epsd, 10))
              CDoom.doom_concat(name, "0") if j < 10
              CDoom.doom_concat(name, CDoom.doom_itoa(j, 10))
              CDoom.doom_concat(name, "0") if i < 10
              CDoom.doom_concat(name, CDoom.doom_itoa(i, 10))
              a.value.p[i] = CDoom.w_cache_lump_name(name, CDoom::PU_STATIC).as(CDoom::Patch*)
            else
              # HACK ALERT!
              a.value.p[i] = CDoom.anims_wi_stuff[1][4].p[i]
            end
          end
        end
      end
    end

    # More hacks on minus sign
    CDoom.wiminus = CDoom.w_cache_lump_name("WIMINUS", CDoom::PU_STATIC).as(CDoom::Patch*)

    10.times do |i|
      CDoom.doom_strcpy(name, "WINUM")
      CDoom.doom_concat(name, CDoom.doom_itoa(i, 10))
      CDoom.num[i] = CDoom.w_cache_lump_name(name, CDoom::PU_STATIC).as(CDoom::Patch*)
    end

    # percent sign
    CDoom.percent = CDoom.w_cache_lump_name("WIPCNT", CDoom::PU_STATIC).as(CDoom::Patch*)

    # "finished"
    CDoom.finished = CDoom.w_cache_lump_name("WIF", CDoom::PU_STATIC).as(CDoom::Patch*)

    # "entering"
    CDoom.entering = CDoom.w_cache_lump_name("WIENTER", CDoom::PU_STATIC).as(CDoom::Patch*)

    # "kills"
    CDoom.kills = CDoom.w_cache_lump_name("WIOSTK", CDoom::PU_STATIC).as(CDoom::Patch*)

    # "scrt"
    CDoom.secret = CDoom.w_cache_lump_name("WIOSTS", CDoom::PU_STATIC).as(CDoom::Patch*)

    # "secret"
    CDoom.sp_secret = CDoom.w_cache_lump_name("WISCRT2", CDoom::PU_STATIC).as(CDoom::Patch*)

    # Yuck.
    if CDoom.language == CDoom::Language::French
      # "items"
      if CDoom.netgame != 0 && CDoom.deathmatch == 0
        CDoom.items = CDoom.w_cache_lump_name("WIOBJ", CDoom::PU_STATIC).as(CDoom::Patch*)
      else
        CDoom.items = CDoom.w_cache_lump_name("WIOSTI", CDoom::PU_STATIC).as(CDoom::Patch*)
      end
    else
      CDoom.items = CDoom.w_cache_lump_name("WIOSTI", CDoom::PU_STATIC).as(CDoom::Patch*)
    end

    # "frgs"
    CDoom.frags = CDoom.w_cache_lump_name("WIFRGS", CDoom::PU_STATIC).as(CDoom::Patch*)

    # ":"
    CDoom.colon = CDoom.w_cache_lump_name("WICOLON", CDoom::PU_STATIC).as(CDoom::Patch*)

    # "time"
    CDoom.time_patch = CDoom.w_cache_lump_name("WITIME", CDoom::PU_STATIC).as(CDoom::Patch*)

    # "sucks"
    CDoom.sucks = CDoom.w_cache_lump_name("WISUCKS", CDoom::PU_STATIC).as(CDoom::Patch*)

    # "par"
    CDoom.par = CDoom.w_cache_lump_name("WIPAR", CDoom::PU_STATIC).as(CDoom::Patch*)

    # "killers" (vertical)
    CDoom.killers = CDoom.w_cache_lump_name("WIKILRS", CDoom::PU_STATIC).as(CDoom::Patch*)

    # "victims" (horiz)
    CDoom.victims = CDoom.w_cache_lump_name("WIVCTMS", CDoom::PU_STATIC).as(CDoom::Patch*)

    # "total"
    CDoom.total = CDoom.w_cache_lump_name("WIMSTT", CDoom::PU_STATIC).as(CDoom::Patch*)

    # your face
    CDoom.star = CDoom.w_cache_lump_name("STFST01", CDoom::PU_STATIC).as(CDoom::Patch*)

    # dead face
    CDoom.bstar = CDoom.w_cache_lump_name("STFDEAD0", CDoom::PU_STATIC).as(CDoom::Patch*)

    CDoom::MAXPLAYERS.times do |i|
      CDoom.doom_strcpy(name, "STPB")
      CDoom.doom_concat(name, CDoom.doom_itoa(i, 10))
      CDoom.p[i] = CDoom.w_cache_lump_name(name, CDoom::PU_STATIC).as(CDoom::Patch*)

      CDoom.doom_strcpy(name, "WIBP")
      CDoom.doom_concat(name, CDoom.doom_itoa(i + 1, 10))
      CDoom.bp[i] = CDoom.w_cache_lump_name(name, CDoom::PU_STATIC).as(CDoom::Patch*)
    end
  end

  def self.wi_unload_data
    z_change_tag(CDoom.wiminus, CDoom::PU_CACHE)

    10.times do |i|
      z_change_tag(CDoom.num[i], CDoom::PU_CACHE)
    end

    if CDoom.gamemode == CDoom::GameMode::Commercial
      CDoom.numcmaps.times do |i|
        z_change_tag(CDoom.lnames[i], CDoom::PU_CACHE)
      end
    else
      z_change_tag(CDoom.yah[0], CDoom::PU_CACHE)
      z_change_tag(CDoom.yah[1], CDoom::PU_CACHE)

      z_change_tag(CDoom.splat, CDoom::PU_CACHE)

      CDoom::NUMMAPS.times do |i|
        z_change_tag(CDoom.lnames[i], CDoom::PU_CACHE)
      end

      if CDoom.wbs.value.epsd < 3
        CDoom.numanims[CDoom.wbs.value.epsd].times do |j|
          if CDoom.wbs.value.epsd != 1 || j != 8
            CDoom.anims_wi_stuff[CDoom.wbs.value.epsd][j].nanims.times do |i|
              z_change_tag(CDoom.anims_wi_stuff[CDoom.wbs.value.epsd][j].p[i], CDoom::PU_CACHE)
            end
          end
        end
      end
    end

    CDoom.z_free(CDoom.lnames)

    z_change_tag(CDoom.percent, CDoom::PU_CACHE)
    z_change_tag(CDoom.colon, CDoom::PU_CACHE)
    z_change_tag(CDoom.finished, CDoom::PU_CACHE)
    z_change_tag(CDoom.entering, CDoom::PU_CACHE)
    z_change_tag(CDoom.kills, CDoom::PU_CACHE)
    z_change_tag(CDoom.secret, CDoom::PU_CACHE)
    z_change_tag(CDoom.sp_secret, CDoom::PU_CACHE)
    z_change_tag(CDoom.items, CDoom::PU_CACHE)
    z_change_tag(CDoom.frags, CDoom::PU_CACHE)
    z_change_tag(CDoom.time_patch, CDoom::PU_CACHE)
    z_change_tag(CDoom.sucks, CDoom::PU_CACHE)
    z_change_tag(CDoom.par, CDoom::PU_CACHE)

    z_change_tag(CDoom.victims, CDoom::PU_CACHE)
    z_change_tag(CDoom.killers, CDoom::PU_CACHE)
    z_change_tag(CDoom.total, CDoom::PU_CACHE)

    CDoom::MAXPLAYERS.times do |i|
      z_change_tag(CDoom.p[i], CDoom::PU_CACHE)
    end

    CDoom::MAXPLAYERS.times do |i|
      z_change_tag(CDoom.bp[i], CDoom::PU_CACHE)
    end
  end

  def self.wi_drawer
    case CDoom.state
    when CDoom::Stateenum::StatCount
      if CDoom.deathmatch != 0
        CDoom.wi_draw_deathmatch_stats
      elsif CDoom.netgame != 0
        CDoom.wi_draw_netgame_stats
      else
        CDoom.wi_draw_stats
      end
    when CDoom::Stateenum::ShowNextLoc
      CDoom.wi_draw_show_next_loc
    when CDoom::Stateenum::NoState
      CDoom.wi_draw_no_state
    end
  end

  def self.wi_init_variables(wbstartstruct : CDoom::Wbstartstruct*)
    CDoom.wbs = wbstartstruct
    CDoom.acceleratestage = 0
    CDoom.cnt = 0
    CDoom.bcnt = 0
    CDoom.firstrefresh = 1
    CDoom.me = CDoom.wbs.value.pnum
    CDoom.plrs = CDoom.wbs.value.plyr

    CDoom.wbs.value.maxkills = 1 if CDoom.wbs.value.maxkills == 0
    CDoom.wbs.value.maxitems = 1 if CDoom.wbs.value.maxitems == 0
    CDoom.wbs.value.maxsecret = 1 if CDoom.wbs.value.maxsecret == 0

    if CDoom.gamemode != CDoom::GameMode::Retail
      CDoom.wbs.value.epsd -= 3 if CDoom.wbs.value.epsd > 2
    end
  end

  def self.wi_start(wbstartstruct : CDoom::Wbstartstruct*)
    CDoom.wi_init_variables(wbstartstruct)
    CDoom.wi_load_data

    if CDoom.deathmatch != 0
      CDoom.wi_init_deathmatch_stats
    elsif CDoom.netgame != 0
      CDoom.wi_init_netgame_stats
    else
      CDoom.wi_init_stats
    end
  end

  def self.z_init
    size = 0
    CDoom.mainzone = CDoom.i_zone_base(pointerof(size)).as(CDoom::Memzone*)
    CDoom.mainzone.value.size = size

    # set the entire zone to one free block
    block = (CDoom.mainzone.as(UInt8*) + sizeof(CDoom::Memzone)).as(CDoom::Memblock*)
    CDoom.mainzone.value.blocklist.next = block
    CDoom.mainzone.value.blocklist.prev = block

    CDoom.mainzone.value.blocklist.user = CDoom.mainzone.as(Void**)
    CDoom.mainzone.value.blocklist.tag = CDoom::PU_STATIC
    CDoom.mainzone.value.rover = block

    block.value.prev = pointerof(CDoom.mainzone.value.@blocklist)
    block.value.next = block.value.prev

    # 0 indicates a free block.
    block.value.user = Pointer(Void*).null

    block.value.size = CDoom.mainzone.value.size - sizeof(CDoom::Memzone)
    puts "#{CDoom.mb_used}MBs of memory allocated."
  end

  def self.z_free(ptr : Void*)
    block = (ptr.as(UInt8*) - sizeof(CDoom::Memblock)).as(CDoom::Memblock*)

    if block.value.id != CDoom::ZONEID
      CDoom.i_error("Error: z_free: freed a pointer without ZONEID")
    end

    if block.value.user.address > 0x100
      # smaller values are not pointers

      # clear the user's mark
      block.value.user.value = Pointer(Void).null
    end

    # mark as free
    block.value.user = Pointer(Void*).null
    block.value.tag = 0
    block.value.id = 0

    other = block.value.prev

    if other.value.user.null?
      # merge with previous free block
      other.value.size = other.value.size + block.value.size
      other.value.next = block.value.next
      other.value.next.value.prev = other

      CDoom.mainzone.value.rover = other if block == CDoom.mainzone.value.rover

      block = other
    end

    other = block.value.next
    if other.value.user.null?
      # merge the next free block onto the end
      block.value.size = block.value.size + other.value.size
      block.value.next = other.value.next
      block.value.next.value.prev = block

      CDoom.mainzone.value.rover = block if other == CDoom.mainzone.value.rover
    end
  end

  def self.z_malloc(size : LibC::Int, tag : LibC::Int, user : Void*) : Void*
    size = (size + CDoom::MEM_ALIGN - 1) & ~(CDoom::MEM_ALIGN - 1)

    # scan through the block list,
    # looking for the first free block
    # of sufficient size,
    # throwing out any purgable blocks along the way.

    # account for size of block header
    size += sizeof(CDoom::Memblock)

    # if there is a free block behind the rover,
    #  back up over them
    base = CDoom.mainzone.value.rover

    base = base.value.prev if base.value.prev.value.user.null?

    rover = base
    start = base.value.prev

    loop do
      if rover == start
        # scanned all the way around the list
        CDoom.i_error("Error: z_malloc: failed on allocation of #{size} bytes")
      end

      if !rover.value.user.null?
        if rover.value.tag < CDoom::PU_PURGELEVEL
          # hit a block that can't be purged,
          #  so move base past it
          base = rover.value.next
          rover = rover.value.next
        else
          # free the rover block (adding the size to base)

          # the rover can be the base block
          base = base.value.prev
          CDoom.z_free(rover.as(UInt8*) + sizeof(CDoom::Memblock))
          base = base.value.next
          rover = base.value.next
        end
      else
        rover = rover.value.next
      end

      break unless !base.value.user.null? || base.value.size < size
    end

    # found a block big enough
    extra = base.value.size - size

    if extra > CDoom::MINFRAGMENT
      # there will be a free fragment after the allocated block
      newblock = (base.as(UInt8*) + size).as(CDoom::Memblock*)
      newblock.value.size = extra

      # 0 indicates free block.
      newblock.value.user = Pointer(Void*).null
      newblock.value.tag = 0
      newblock.value.prev = base
      newblock.value.next = base.value.next
      newblock.value.next.value.prev = newblock

      base.value.next = newblock
      base.value.size = size
    end

    if !user.null?
      # mark as an in use block
      base.value.user = user.as(Void**)
      user.as(Void**).value = (base.as(UInt8*) + sizeof(CDoom::Memblock)).as(Void*)
    else
      if tag >= CDoom::PU_PURGELEVEL
        CDoom.i_error("Error: z_malloc: an owner is required for purgable blocks")
      end

      # mark as in use, but unowned
      base.value.user = Pointer(Void*).new(2_u64)
    end
    base.value.tag = tag

    # next allocation will start looking here
    CDoom.mainzone.value.rover = base.value.next

    base.value.id = CDoom::ZONEID

    return (base.as(UInt8*) + sizeof(CDoom::Memblock)).as(Void*)
  end

  def self.z_free_tags(lowtag : LibC::Int, hightag : LibC::Int)
    block = CDoom.mainzone.value.blocklist.next
    while block != pointerof(CDoom.mainzone.value.@blocklist)
      # get link before freeing
      nextb = block.value.next

      # free block?
      if block.value.user.null?
        block = nextb
        next
      end

      if block.value.tag >= lowtag && block.value.tag <= hightag
        CDoom.z_free(block.as(UInt8*) + sizeof(CDoom::Memblock))
      end

      block = nextb
    end
  end

  def self.z_check_heap
    block = CDoom.mainzone.value.blocklist.next

    loop do
      if block.value.next == pointerof(CDoom.mainzone.value.@blocklist)
        # all blocks have been hit
        break
      end

      if block.as(UInt8*) + block.value.size != block.value.next.as(UInt8*)
        CDoom.i_error("Error: z_check_heap: block size does not touch the next block\n")
      end

      if block.value.next.value.prev != block
        CDoom.i_error("Error: z_check_heap: next block doesn't have proper back link\n")
      end

      if block.value.user.null? && block.value.next.value.user.null?
        CDoom.i_error("Error: z_check_heap: two consecutive free blocks\n")
      end

      block = block.value.next
    end
  end

  def self.z_change_tag2(ptr : Void*, tag : LibC::Int)
    block = (ptr.as(UInt8*) - sizeof(CDoom::Memblock)).as(CDoom::Memblock*)

    if block.value.id != CDoom::ZONEID
      CDoom.i_error("Error: z_change_tag: freed a pointer without ZONEID")
    end

    if tag >= CDoom::PU_PURGELEVEL && block.value.user.address < 0x100
      CDoom.i_error("Error: z_change_tag: an owner is required for purgable blocks")
    end

    block.value.tag = tag
  end
end
