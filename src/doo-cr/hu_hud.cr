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
# ==> Heads-up display

module Doocr
  def self.hulib_clear_text_line(t : CDoom::HU_Textline*)
    t.value.len = 0
    t.value.l[0] = 0
    t.value.needsupdate = true
  end

  def self.hulib_init_text_line(t : CDoom::HU_Textline*, x : Int32, y : Int32, f : CDoom::Patch**, sc : Int32)
    t.value.x = x
    t.value.y = y
    t.value.f = f
    t.value.sc = sc
    CDoom.hulib_clear_text_line(t)
  end

  def self.hulib_add_char_to_text_line(t : CDoom::HU_Textline*, ch : UInt8) : LibC::Int
    if t.value.len == Doocr::HU_MAXLINELENGTH
      return 0
    else
      t.value.l[t.value.len] = ch
      t.value.len = t.value.len + 1
      t.value.l[t.value.len] = 0
      t.value.needsupdate = 4
      return 1
    end
  end

  def self.hulib_del_char_from_text_line(t : CDoom::HU_Textline*) : LibC::Int
    if t.value.len == 0
      return 0
    else
      t.value.len = t.value.len - 1
      t.value.l[t.value.len] = 0
      t.value.needsupdate = 4
      return 1
    end
  end

  def self.hulib_draw_text_line(l : CDoom::HU_Textline*, drawcursor : LibC::Int)
    # draw the new stuff
    x = l.value.x
    l.value.len.times do |i|
      c = CDoom.doom_toupper(l.value.l[i])
      if c != ' '.ord &&
         c >= l.value.sc &&
         c <= '_'.ord
        w = l.value.f[c - l.value.sc].value.width.to_i16!
        break if x + w > CDoom::SCREENWIDTH
        CDoom.v_draw_patch_direct(x, l.value.y, CDoom::FG, l.value.f[c - l.value.sc])
        x += w
      else
        x += 4
        break if x >= CDoom::SCREENWIDTH
      end
    end

    # draw the cursor if requested
    if drawcursor != 0 && x + l.value.f['_'.ord - l.value.sc].value.width.to_i16! <= CDoom::SCREENWIDTH
      CDoom.v_draw_patch_direct(x, l.value.y, CDoom::FG, l.value.f['_'.ord - l.value.sc])
    end
  end

  @@lastautomapactive = 1

  # sorta called by hu_erase and just better darn get things straight
  def self.hulib_erase_text_line(l : CDoom::HU_Textline*)
    # Only erases when NOT in automap and the screen is reduced,
    # and the text must either need updating or refreshing
    # (because of a recent change back from the automap)

    if Doocr.automapactive == 0 && Doocr.viewwindowx != 0 && l.value.needsupdate != 0
      lh = l.value.f[0].value.height.to_i16! + 1
      y = l.value.y
      yoffset = y * CDoom::SCREENWIDTH
      while y < l.value.y + lh
        if y < Doocr.viewwindowy || y >= Doocr.viewwindowy + Doocr.viewheight
          CDoom.r_video_erase(yoffset, CDoom::SCREENWIDTH) # erase entire line
        else
          CDoom.r_video_erase(yoffset, Doocr.viewwindowx)                                       # erase left border
          CDoom.r_video_erase(yoffset + Doocr.viewwindowx + Doocr.viewwidth, Doocr.viewwindowx) # erase right border
        end

        y += 1
        yoffset += CDoom::SCREENWIDTH
      end
    end

    @@lastautomapactive = Doocr.automapactive
    l.value.needsupdate = l.value.needsupdate - 1 if l.value.needsupdate != 0
  end

  def self.hulib_init_s_text(s : CDoom::HU_Stext*,
                             x : Int32,
                             y : Int32,
                             h : Int32,
                             font : CDoom::Patch**,
                             startchar : Int32,
                             on : LibC::Int*)
    s.value.h = h
    s.value.on = on
    s.value.laston = 1
    s.value.cl = 0
    h.times do |i|
      CDoom.hulib_init_text_line(s.value.l.to_unsafe + i,
        x, y - i * (font[0].value.height.to_i16! + 1),
        font, startchar)
    end
  end

  def self.hulib_add_line_to_s_text(s : CDoom::HU_Stext*)
    # add a clear line
    s.value.cl = s.value.cl + 1
    s.value.cl = 0 if s.value.cl == s.value.h
    CDoom.hulib_clear_text_line(s.value.l.to_unsafe + s.value.cl)

    # everything needs updating
    s.value.h.times do |i|
      (s.value.l.to_unsafe + i).value.needsupdate = 4
    end
  end

  def self.hulib_add_message_to_s_text(s : CDoom::HU_Stext*, prefix : UInt8*, msg : UInt8*)
    CDoom.hulib_add_line_to_s_text(s)
    if !prefix.null?
      while prefix.value != 0
        CDoom.hulib_add_char_to_text_line(s.value.l.to_unsafe + s.value.cl, prefix.value)
        prefix += 1
      end
    end

    while msg.value != 0
      CDoom.hulib_add_char_to_text_line(s.value.l.to_unsafe + s.value.cl, msg.value)
      msg += 1
    end
  end

  def self.hulib_draw_s_text(s : CDoom::HU_Stext*)
    return if s.value.on.value == 0 # if not on, don't draw

    # draw everything
    s.value.h.times do |i|
      idx = s.value.cl - i
      idx += s.value.h if idx < 0 # handle queue of lines
      l = s.value.l.to_unsafe + idx

      # need a decision made here on whether to skip the draw
      CDoom.hulib_draw_text_line(l, 0) # no cursor, please
    end
  end

  def self.hulib_erase_s_text(s : CDoom::HU_Stext*)
    s.value.h.times do |i|
      if s.value.laston != 0 && s.value.on.value == 0
        (s.value.l.to_unsafe + i).value.needsupdate = 4
      end
      CDoom.hulib_erase_text_line(s.value.l.to_unsafe + i)
    end
    s.value.laston = s.value.on.value
  end

  def self.hulib_init_i_text(it : CDoom::HU_Itext*,
                             x : Int32,
                             y : Int32,
                             font : CDoom::Patch**,
                             startchar : Int32,
                             on : LibC::Int*)
    it.value.lm = 0 # default left margin is start of text
    it.value.on = on
    it.value.laston = 1
    CDoom.hulib_init_text_line(pointerof(it.value.@l), x, y, font, startchar)
  end

  # The following deletion routines adhere to the left margin restriction
  def self.hulib_del_char_from_i_text(it : CDoom::HU_Itext*)
    CDoom.hulib_del_char_from_text_line(pointerof(it.value.@l)) if it.value.l.len != it.value.lm
  end

  def self.hulib_erase_line_from_i_text(it : CDoom::HU_Itext*)
    while it.value.lm != it.value.l.len
      CDoom.hulib_del_char_from_text_line(pointerof(it.value.@l))
    end
  end

  # Resets left margin as well
  def self.hulib_reset_i_text(it : CDoom::HU_Itext*)
    it.value.lm = 0
    CDoom.hulib_clear_text_line(pointerof(it.value.@l))
  end

  def self.hulib_add_prefix_to_i_text(it : CDoom::HU_Itext*, str : UInt8*)
    while str.value != 0
      CDoom.hulib_add_char_to_text_line(pointerof(it.value.@l), str.value)
      str += 1
    end
    it.value.lm = it.value.l.len
  end

  # wrapper function for handling general keyed input.
  # returns true if it ate the key
  def self.hulib_key_in_i_text(it : CDoom::HU_Itext*, ch : UInt8) : LibC::Int
    if ch >= ' '.ord && ch <= '_'.ord
      CDoom.hulib_add_char_to_text_line(pointerof(it.value.@l), ch.to_i8!)
    else
      if ch == Doocr::KEY_BACKSPACE
        CDoom.hulib_del_char_from_i_text(it)
      elsif ch != Doocr::KEY_ENTER
        return 0 # did not eat key
      end
    end

    return 1 # ate the key
  end

  def self.hulib_draw_i_text(it : CDoom::HU_Itext*)
    l = pointerof(it.value.@l)

    return if it.value.on.value == 0
    CDoom.hulib_draw_text_line(l, 1) # draw the line w/ cursor
  end

  def self.hulib_erase_i_text(it : CDoom::HU_Itext*)
    if it.value.laston != 0 && it.value.on.value == 0
      it.value.l.needsupdate = 4
    end

    CDoom.hulib_erase_text_line(pointerof(it.value.@l))
    it.value.laston = it.value.on.value
  end

  def self.foreign_translation(ch : UInt8) : UInt8
    return ch < 128 ? Doocr.french_key_map[ch] : ch
  end

  def self.hu_init
    buffer = uninitialized StaticArray(UInt8, 9)

    if Doocr.language == Doocr::Language::French
      Doocr.shiftxform = Doocr.french_shiftxform
    else
      Doocr.shiftxform = Doocr.english_shiftxform
    end

    # load the heads-up font
    j = Doocr::HU_FONTSTART
    Doocr::HU_FONTSIZE.times do |i|
      CDoom.doom_strcpy(buffer, "STCFN")
      CDoom.doom_concat(buffer, "0") if j < 100
      CDoom.doom_concat(buffer, "0") if j < 10
      CDoom.doom_concat(buffer, CDoom.doom_itoa(j, 10))
      j += 1
      Doocr.hu_font[i] = CDoom.w_cache_lump_name(buffer, Doocr::PU_STATIC).as(CDoom::Patch*)
    end
  end

  def self.hu_stop
    Doocr.headsupactive = 0
  end

  def self.hu_start
    CDoom.hu_stop if Doocr.headsupactive != 0

    Doocr.plr = @@players.to_unsafe + Doocr.consoleplayer
    Doocr.message_on = 0
    Doocr.message_dontfuckwithme = 0
    Doocr.message_nottobefuckedwith = 0
    Doocr.chat_on = 0

    # create the message widget
    CDoom.hulib_init_s_text(Doocr.w_message.to_unsafe,
      Doocr::HU_MSGX, Doocr::HU_MSGY, Doocr::HU_MSGHEIGHT,
      Doocr.hu_font.to_unsafe.as(CDoom::Patch**), Doocr::HU_FONTSTART, pointerof(@@message_on))

    # # create the map title widget
    CDoom.hulib_init_text_line(Doocr.w_title.to_unsafe,
      0, 167 - Doocr.hu_font[0].value.height.to_i16!,
      Doocr.hu_font.to_unsafe.as(CDoom::Patch**), Doocr::HU_FONTSTART)

    s = ""
    case Doocr.gamemode
    when Doocr::GameMode::Shareware, Doocr::GameMode::Registered, Doocr::GameMode::Retail
      s = Doocr.mapnames[(Doocr.gameepisode - 1)*9 + Doocr.gamemap - 1]
    when Doocr::GameMode::Commercial
      case Doocr.gamemission
      when Doocr::GameMission::PackTnt
        s = Doocr.mapnamest[Doocr.gamemap - 1]
      when Doocr::GameMission::PackPlut
        s = Doocr.mapnamesp[Doocr.gamemap - 1]
      else
        s = Doocr.mapnames2[Doocr.gamemap - 1]
      end
    end

    s.each_byte do |char|
      CDoom.hulib_add_char_to_text_line(Doocr.w_title.to_unsafe, char)
    end

    # create the chat widget
    CDoom.hulib_init_i_text(Doocr.w_chat.to_unsafe, Doocr::HU_MSGX, Doocr::HU_MSGY + Doocr::HU_MSGHEIGHT*(Doocr.hu_font[0].value.height.to_i16! + 1),
      Doocr.hu_font.to_unsafe.as(CDoom::Patch**), Doocr::HU_FONTSTART, Doocr.chat_on_ptr)

    # create the inputbuffer widgets
    CDoom::MAXPLAYERS.times do |i|
      CDoom.hulib_init_i_text(Doocr.w_inputbuffer.to_unsafe + i, 0, 0, Pointer(Pointer(CDoom::Patch)).null, 0, Doocr.always_off_ptr)
    end

    Doocr.headsupactive = 1
  end

  def self.hu_drawer
    CDoom.hulib_draw_s_text(Doocr.w_message.to_unsafe)
    CDoom.hulib_draw_i_text(Doocr.w_chat.to_unsafe)
    CDoom.hulib_draw_text_line(Doocr.w_title.to_unsafe, 0) if Doocr.automapactive != 0
  end

  def self.hu_erase
    CDoom.hulib_erase_s_text(Doocr.w_message.to_unsafe)
    CDoom.hulib_erase_i_text(Doocr.w_chat.to_unsafe)
    CDoom.hulib_erase_text_line(Doocr.w_title.to_unsafe)
  end

  def self.hu_ticker
    # tick down message counter if message is up
    if Doocr.message_counter != 0 && (Doocr.message_counter -= 1) == 0
      Doocr.message_on = 0
      Doocr.message_nottobefuckedwith = 0
    end

    if Doocr.show_messages != 0 || Doocr.message_dontfuckwithme != 0
      # display message if necessary
      if (!Doocr.plr.value.message.null? && Doocr.message_nottobefuckedwith == 0) ||
         (!Doocr.plr.value.message.null? && Doocr.message_dontfuckwithme != 0)
        CDoom.hulib_add_message_to_s_text(Doocr.w_message.to_unsafe, Pointer(UInt8).null, Doocr.plr.value.message)
        Doocr.plr.value.message = Pointer(UInt8).null
        Doocr.message_on = 1
        Doocr.message_counter = Doocr::HU_MSGTIMEOUT
        Doocr.message_nottobefuckedwith = Doocr.message_dontfuckwithme
        Doocr.message_dontfuckwithme = 0
      end
    end

    # check for incoming chat characters
    if Doocr.netgame != 0
      CDoom::MAXPLAYERS.times do |i|
        next if Doocr.playeringame[i] == 0
        if i != Doocr.consoleplayer && (c = @@players[i].cmd.chatchar) != 0
          if c <= Doocr::HU_BROADCAST
            Doocr.chat_dest[i] = c.to_u8!
          else
            if c >= 'a'.ord && c <= 'z'.ord
              c = Doocr.shiftxform[c]
            end
            rc = CDoom.hulib_key_in_i_text(Doocr.w_inputbuffer.to_unsafe + i, c)
            if rc != 0 && c == Doocr::KEY_ENTER
              if Doocr.w_inputbuffer[i].l.len != 0 &&
                 (Doocr.chat_dest[i] == (Doocr.consoleplayer + 1).to_u8! ||
                 Doocr.chat_dest[i] == Doocr::HU_BROADCAST.to_u8!)
                CDoom.hulib_add_message_to_s_text(Doocr.w_message.to_unsafe,
                  Doocr.player_names[i].to_unsafe,
                  Doocr.w_inputbuffer[i].l.l)

                Doocr.message_nottobefuckedwith = 1
                Doocr.message_on = 1
                Doocr.message_counter = Doocr::HU_MSGTIMEOUT
                if Doocr.gamemode == Doocr::GameMode::Commercial
                  Doocr.s_start_sound(Pointer(CDoom::Mobj).null, Doocr::Sfxenum::SFX_radio)
                else
                  Doocr.s_start_sound(Pointer(CDoom::Mobj).null, Doocr::Sfxenum::SFX_tink)
                end
              end
              CDoom.hulib_reset_i_text(Doocr.w_inputbuffer.to_unsafe + i)
            end
          end
          pointerof((@@players.to_unsafe + i).value.@cmd).value.chatchar = 0
        end
      end
    end
  end

  def self.hu_queue_chat_char(c : UInt8)
    if ((Doocr.head + 1) & (Doocr::QUEUESIZE - 1)) == Doocr.tail
      Doocr.plr.value.message = @@deh_hustr_msgu
    else
      Doocr.chatchars[Doocr.head] = c.to_u8!
      Doocr.head = (Doocr.head + 1) & (Doocr::QUEUESIZE - 1)
    end
  end

  def self.hu_dequeue_chat_char : UInt8
    c = 0_u8
    if Doocr.head != Doocr.tail
      c = Doocr.chatchars[Doocr.tail]
      Doocr.tail = (Doocr.tail + 1) & (Doocr::QUEUESIZE - 1)
    end

    return c
  end

  LASTMESSAGE_SIZE = Doocr::HU_MAXLINELENGTH + 1
  @@lastmessage = uninitialized StaticArray(UInt8, LASTMESSAGE_SIZE)
  @@shiftdown = 0
  @@altdown = 0
  @@destination_keys : StaticArray(UInt8, CDoom::MAXPLAYERS) = StaticArray[
    Doocr::HUSTR_KEYGREEN.ord.to_u8,
    Doocr::HUSTR_KEYINDIGO.ord.to_u8,
    Doocr::HUSTR_KEYBROWN.ord.to_u8,
    Doocr::HUSTR_KEYRED.ord.to_u8,
  ]
  @@num_nobrainers = 0

  def self.hu_responder(ev : Doocr::Event) : LibC::Int
    eatkey = 0
    numplayers = 0
    CDoom::MAXPLAYERS.times { |i| numplayers += Doocr.playeringame[i] }

      if ev.data1 == Doocr::KEY_RSHIFT
        @@shiftdown = (ev.type == Doocr::Evtype::Keydown).to_unsafe
        return 0
      elsif ev.data1 == Doocr::KEY_RALT || ev.data1 == Doocr::KEY_LALT
        @@altdown = (ev.type == Doocr::Evtype::Keydown).to_unsafe
        return 0
    end

      return 0 if ev.type != Doocr::Evtype::Keydown

    if Doocr.chat_on == 0
      if ev.data1 == Doocr::HU_MSGREFRESH
        Doocr.message_on = 1
        Doocr.message_counter = Doocr::HU_MSGTIMEOUT
        eatkey = 1
      elsif Doocr.netgame != 0 && ev.data1 == Doocr::HU_INPUTTOGGLE
        eatkey = 1
        Doocr.chat_on = 1
        CDoom.hulib_reset_i_text(Doocr.w_chat.to_unsafe)
        CDoom.hu_queue_chat_char(Doocr::HU_BROADCAST)
      elsif Doocr.netgame != 0 && numplayers > 2
        CDoom::MAXPLAYERS.times do |i|
          if ev.data1 == @@destination_keys[i]
            if Doocr.playeringame[i] != 0 && i != Doocr.consoleplayer
              eatkey = 1
              Doocr.chat_on = 1
              CDoom.hulib_reset_i_text(Doocr.w_chat.to_unsafe)
              CDoom.hu_queue_chat_char(i + 1)
              break
            elsif i == Doocr.consoleplayer
              @@num_nobrainers += 1
              if @@num_nobrainers < 3
                Doocr.plr.value.message = @@deh_hustr_talktoself1
              elsif @@num_nobrainers < 6
                Doocr.plr.value.message = @@deh_hustr_talktoself2
              elsif @@num_nobrainers < 9
                Doocr.plr.value.message = @@deh_hustr_talktoself3
              elsif @@num_nobrainers < 32
                Doocr.plr.value.message = @@deh_hustr_talktoself4
              else
                Doocr.plr.value.message = @@deh_hustr_talktoself5
              end
            end
          end
        end
      end
    else
      c = ev.data1
      # send a macro
      if @@altdown != 0
        return 0 if c < '0'.ord || c > '9'.ord
        c = c - '0'.ord
        macromessage = Doocr.chat_macros[c]

        # kill last message with a '\n'
        CDoom.hu_queue_chat_char(Doocr::KEY_ENTER) # DEBUG!!!

        # send the macro message
        macromessage.each_byte do |byte|
          CDoom.hu_queue_chat_char(byte)
        end
        CDoom.hu_queue_chat_char(Doocr::KEY_ENTER)

        # leave chat mode and notify that it was sent
        Doocr.chat_on = 0
        CDoom.doom_strcpy(@@lastmessage, Doocr.chat_macros[c].to_unsafe)
        Doocr.plr.value.message = String.new(@@lastmessage.to_unsafe)
        eatkey = 1
      else
        c = CDoom.foreign_translation(c) if Doocr.language == Doocr::Language::French
        c = Doocr.shiftxform[c] if @@shiftdown != 0 || (c >= 'a'.ord && c <= 'z'.ord)
        eatkey = CDoom.hulib_key_in_i_text(Doocr.w_chat.to_unsafe, c)
        CDoom.hu_queue_chat_char(c) if eatkey != 0
        if c == Doocr::KEY_ENTER
          Doocr.chat_on = 0
          if Doocr.w_chat[0].l.len != 0
            CDoom.doom_strcpy(@@lastmessage, Doocr.w_chat[0].l.l)
            Doocr.plr.value.message = String.new(@@lastmessage.to_unsafe)
          end
        elsif c == Doocr::KEY_ESCAPE
          Doocr.chat_on = 0
        end
      end
    end

    return eatkey
  end
end
