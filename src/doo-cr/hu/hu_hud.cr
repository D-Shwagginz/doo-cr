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

  def self.hulib_add_char_to_text_line(t : CDoom::HU_Textline*, ch : UInt8) : CDoom::DoomBool
    if t.value.len == CDoom::HU_MAXLINELENGTH
      return 0
    else
      t.value.l[t.value.len] = ch
      t.value.len = t.value.len + 1
      t.value.l[t.value.len] = 0
      t.value.needsupdate = 4
      return 1
    end
  end

  def self.hulib_del_char_from_text_line(t : CDoom::HU_Textline*) : CDoom::DoomBool
    if t.value.len == 0
      return 0
    else
      t.value.len = t.value.len - 1
      t.value.l[t.value.len] = 0
      t.value.needsupdate = 4
      return 1
    end
  end

  def self.hulib_draw_text_line(l : CDoom::HU_Textline*, drawcursor : CDoom::DoomBool)
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

    if CDoom.automapactive == 0 && CDoom.viewwindowx != 0 && l.value.needsupdate != 0
      lh = l.value.f[0].value.height.to_i16! + 1
      y = l.value.y
      yoffset = y * CDoom::SCREENWIDTH
      while y < l.value.y + lh
        if y < CDoom.viewwindowy || y >= CDoom.viewwindowy + CDoom.viewheight
          CDoom.r_video_erase(yoffset, CDoom::SCREENWIDTH) # erase entire line
        else
          CDoom.r_video_erase(yoffset, CDoom.viewwindowx)                                       # erase left border
          CDoom.r_video_erase(yoffset + CDoom.viewwindowx + CDoom.viewwidth, CDoom.viewwindowx) # erase right border
        end

        y += 1
        yoffset += CDoom::SCREENWIDTH
      end
    end

    @@lastautomapactive = CDoom.automapactive
    l.value.needsupdate = l.value.needsupdate - 1 if l.value.needsupdate != 0
  end

  def self.hulib_init_s_text(s : CDoom::HU_Stext*,
                             x : Int32,
                             y : Int32,
                             h : Int32,
                             font : CDoom::Patch**,
                             startchar : Int32,
                             on : CDoom::DoomBool*)
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
                             on : CDoom::DoomBool*)
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
  def self.hulib_key_in_i_text(it : CDoom::HU_Itext*, ch : UInt8) : CDoom::DoomBool
    if ch >= ' '.ord && ch <= '_'.ord
      CDoom.hulib_add_char_to_text_line(pointerof(it.value.@l), ch.to_i8!)
    else
      if ch == CDoom::KEY_BACKSPACE
        CDoom.hulib_del_char_from_i_text(it)
      elsif ch != CDoom::KEY_ENTER
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
    return ch < 128 ? CDoom.french_key_map[ch] : ch
  end

  def self.hu_init
    buffer = uninitialized StaticArray(UInt8, 9)

    if CDoom.language == CDoom::Language::French
      CDoom.shiftxform = CDoom.french_shiftxform
    else
      CDoom.shiftxform = CDoom.english_shiftxform
    end

    # load the heads-up font
    j = CDoom::HU_FONTSTART
    CDoom::HU_FONTSIZE.times do |i|
      CDoom.doom_strcpy(buffer, "STCFN")
      CDoom.doom_concat(buffer, "0") if j < 100
      CDoom.doom_concat(buffer, "0") if j < 10
      CDoom.doom_concat(buffer, CDoom.doom_itoa(j, 10))
      j += 1
      CDoom.hu_font[i] = CDoom.w_cache_lump_name(buffer, CDoom::PU_STATIC).as(CDoom::Patch*)
    end
  end

  def self.hu_stop
    CDoom.headsupactive = 0
  end

  def self.hu_start
    CDoom.hu_stop if CDoom.headsupactive != 0

    CDoom.plr = CDoom.players.to_unsafe + CDoom.consoleplayer
    CDoom.message_on = 0
    CDoom.message_dontfuckwithme = 0
    CDoom.message_nottobefuckedwith = 0
    CDoom.chat_on = 0

    # create the message widget
    CDoom.hulib_init_s_text(pointerof(CDoom.w_message),
      CDoom::HU_MSGX, CDoom::HU_MSGY, CDoom::HU_MSGHEIGHT,
      CDoom.hu_font, CDoom::HU_FONTSTART, pointerof(CDoom.message_on))

    # # create the map title widget
    CDoom.hulib_init_text_line(pointerof(CDoom.w_title),
      0, 167 - CDoom.hu_font[0].value.height.to_i16!,
      CDoom.hu_font, CDoom::HU_FONTSTART)

    s = "".to_unsafe
    case CDoom.gamemode
    when CDoom::GameMode::Shareware, CDoom::GameMode::Registered, CDoom::GameMode::Retail
      s = CDoom.mapnames[(CDoom.gameepisode - 1)*9 + CDoom.gamemap - 1]
    when CDoom::GameMode::Commercial
      case CDoom.gamemission
      when CDoom::GameMission::PackTnt
        s = CDoom.mapnamest[CDoom.gamemap - 1]
      when CDoom::GameMission::PackPlut
        s = CDoom.mapnamesp[CDoom.gamemap - 1]
      else
        s = CDoom.mapnames2[CDoom.gamemap - 1]
      end
    end

    while s.value != 0
      CDoom.hulib_add_char_to_text_line(pointerof(CDoom.w_title), s.value)
      s += 1
    end

    # create the chat widget
    CDoom.hulib_init_i_text(pointerof(CDoom.w_chat), CDoom::HU_MSGX, CDoom::HU_MSGY + CDoom::HU_MSGHEIGHT*(CDoom.hu_font[0].value.height.to_i16! + 1),
      CDoom.hu_font, CDoom::HU_FONTSTART, pointerof(CDoom.chat_on))

    # create the inputbuffer widgets
    CDoom::MAXPLAYERS.times do |i|
      CDoom.hulib_init_i_text(CDoom.w_inputbuffer.to_unsafe + i, 0, 0, Pointer(Pointer(CDoom::Patch)).null, 0, pointerof(CDoom.always_off))
    end

    CDoom.headsupactive = 1
  end

  def self.hu_drawer
    CDoom.hulib_draw_s_text(pointerof(CDoom.w_message))
    CDoom.hulib_draw_i_text(pointerof(CDoom.w_chat))
    CDoom.hulib_draw_text_line(pointerof(CDoom.w_title), 0) if CDoom.automapactive != 0
  end

  def self.hu_erase
    CDoom.hulib_erase_s_text(pointerof(CDoom.w_message))
    CDoom.hulib_erase_i_text(pointerof(CDoom.w_chat))
    CDoom.hulib_erase_text_line(pointerof(CDoom.w_title))
  end

  def self.hu_ticker
    # tick down message counter if message is up
    if CDoom.message_counter != 0 && (CDoom.message_counter -= 1) == 0
      CDoom.message_on = 0
      CDoom.message_nottobefuckedwith = 0
    end

    if CDoom.show_messages != 0 || CDoom.message_dontfuckwithme != 0
      # display message if necessary
      if (!CDoom.plr.value.message.null? && CDoom.message_nottobefuckedwith == 0) ||
         (!CDoom.plr.value.message.null? && CDoom.message_dontfuckwithme != 0)
        CDoom.hulib_add_message_to_s_text(pointerof(CDoom.w_message), Pointer(UInt8).null, CDoom.plr.value.message)
        CDoom.plr.value.message = Pointer(UInt8).null
        CDoom.message_on = 1
        CDoom.message_counter = CDoom::HU_MSGTIMEOUT
        CDoom.message_nottobefuckedwith = CDoom.message_dontfuckwithme
        CDoom.message_dontfuckwithme = 0
      end
    end

    # check for incoming chat characters
    if CDoom.netgame != 0
      CDoom::MAXPLAYERS.times do |i|
        next if CDoom.playeringame[i] == 0
        if i != CDoom.consoleplayer && (c = CDoom.players[i].cmd.chatchar) != 0
          if c <= CDoom::HU_BROADCAST
            CDoom.chat_dest[i] = c
          else
            if c >= 'a'.ord && c <= 'z'.ord
              c = CDoom.shiftxform[c]
            end
            rc = CDoom.hulib_key_in_i_text(CDoom.w_inputbuffer.to_unsafe + i, c)
            if rc != 0 && c == CDoom::KEY_ENTER
              if CDoom.w_inputbuffer[i].l.len != 0 &&
                 (CDoom.chat_dest[i] == CDoom.consoleplayer + 1 ||
                 CDoom.chat_dest[i] == CDoom::HU_BROADCAST)
                CDoom.hulib_add_message_to_s_text(pointerof(CDoom.w_message),
                  CDoom.player_names[i],
                  CDoom.w_inputbuffer[i].l.l)

                CDoom.message_nottobefuckedwith = 1
                CDoom.message_on = 1
                CDoom.message_counter = CDoom::HU_MSGTIMEOUT
                if CDoom.gamemode == CDoom::GameMode::Commercial
                  CDoom.s_start_sound(Pointer(CDoom::Mobj).null, CDoom::Sfxenum::SFX_radio)
                else
                  CDoom.s_start_sound(Pointer(CDoom::Mobj).null, CDoom::Sfxenum::SFX_tink)
                end
              end
              CDoom.hulib_reset_i_text(CDoom.w_inputbuffer.to_unsafe + i)
            end
          end
          pointerof((CDoom.players.to_unsafe + i).value.@cmd).value.chatchar = 0
        end
      end
    end
  end

  def self.hu_queue_chat_char(c : UInt8)
    if ((CDoom.head + 1) & (CDoom::QUEUESIZE - 1)) == CDoom.tail
      CDoom.plr.value.message = @@deh_hustr_msgu
    else
      CDoom.chatchars[CDoom.head] = c
      CDoom.head = (CDoom.head + 1) & (CDoom::QUEUESIZE - 1)
    end
  end

  def self.hu_dequeue_chat_char : UInt8
    c = 0_u8
    if CDoom.head != CDoom.tail
      c = CDoom.chatchars[CDoom.tail]
      CDoom.tail = (CDoom.tail + 1) & (CDoom::QUEUESIZE - 1)
    end

    return c
  end

  LASTMESSAGE_SIZE = CDoom::HU_MAXLINELENGTH + 1
  @@lastmessage = uninitialized StaticArray(UInt8, LASTMESSAGE_SIZE)
  @@shiftdown = 0
  @@altdown = 0
  @@destination_keys : StaticArray(UInt8, CDoom::MAXPLAYERS) = StaticArray[
    CDoom::HUSTR_KEYGREEN.ord.to_u8,
    CDoom::HUSTR_KEYINDIGO.ord.to_u8,
    CDoom::HUSTR_KEYBROWN.ord.to_u8,
    CDoom::HUSTR_KEYRED.ord.to_u8,
  ]
  @@num_nobrainers = 0

  def self.hu_responder(ev : CDoom::Event*) : CDoom::DoomBool
    eatkey = 0
    numplayers = 0
    CDoom::MAXPLAYERS.times { |i| numplayers += CDoom.playeringame[i] }

    if ev.value.data1 == CDoom::KEY_RSHIFT
      @@shiftdown = (ev.value.type == CDoom::Evtype::Keydown).to_unsafe
      return 0
    elsif ev.value.data1 == CDoom::KEY_RALT || ev.value.data1 == CDoom::KEY_LALT
      @@altdown = (ev.value.type == CDoom::Evtype::Keydown).to_unsafe
      return 0
    end

    return 0 if ev.value.type != CDoom::Evtype::Keydown

    if CDoom.chat_on == 0
      if ev.value.data1 == CDoom::HU_MSGREFRESH
        CDoom.message_on = 1
        CDoom.message_counter = CDoom::HU_MSGTIMEOUT
        eatkey = 1
      elsif CDoom.netgame != 0 && ev.value.data1 == CDoom::HU_INPUTTOGGLE
        eatkey = 1
        CDoom.chat_on = 1
        CDoom.hulib_reset_i_text(pointerof(CDoom.w_chat))
        CDoom.hu_queue_chat_char(CDoom::HU_BROADCAST)
      elsif CDoom.netgame != 0 && numplayers > 2
        CDoom::MAXPLAYERS.times do |i|
          if ev.value.data1 == @@destination_keys[i]
            if CDoom.playeringame[i] != 0 && i != CDoom.consoleplayer
              eatkey = 1
              CDoom.chat_on = 1
              CDoom.hulib_reset_i_text(pointerof(CDoom.w_chat))
              CDoom.hu_queue_chat_char(i + 1)
              break
            elsif i == CDoom.consoleplayer
              @@num_nobrainers += 1
              if @@num_nobrainers < 3
                CDoom.plr.value.message = @@deh_hustr_talktoself1
              elsif @@num_nobrainers < 6
                CDoom.plr.value.message = @@deh_hustr_talktoself2
              elsif @@num_nobrainers < 9
                CDoom.plr.value.message = @@deh_hustr_talktoself3
              elsif @@num_nobrainers < 32
                CDoom.plr.value.message = @@deh_hustr_talktoself4
              else
                CDoom.plr.value.message = @@deh_hustr_talktoself5
              end
            end
          end
        end
      end
    else
      c = ev.value.data1
      # send a macro
      if @@altdown != 0
        return 0 if c < '0'.ord || c > '9'.ord
        c = c - '0'.ord
        macromessage = CDoom.chat_macros[c]

        # kill last message with a '\n'
        CDoom.hu_queue_chat_char(CDoom::KEY_ENTER) # DEBUG!!!

        # send the macro message
        while macromessage.value != 0
          CDoom.hu_queue_chat_char(macromessage.value)
          macromessage += 1
        end
        CDoom.hu_queue_chat_char(CDoom::KEY_ENTER)

        # leave chat mode and notify that it was sent
        CDoom.chat_on = 0
        CDoom.doom_strcpy(@@lastmessage, CDoom.chat_macros[c])
        CDoom.plr.value.message = @@lastmessage
        eatkey = 1
      else
        c = CDoom.foreign_translation(c) if CDoom.language == CDoom::Language::French
        c = CDoom.shiftxform[c] if @@shiftdown != 0 || (c >= 'a'.ord && c <= 'z'.ord)
        eatkey = CDoom.hulib_key_in_i_text(pointerof(CDoom.w_chat), c)
        CDoom.hu_queue_chat_char(c) if eatkey != 0
        if c == CDoom::KEY_ENTER
          CDoom.chat_on = 0
          if CDoom.w_chat.l.len != 0
            CDoom.doom_strcpy(@@lastmessage, CDoom.w_chat.l.l)
            CDoom.plr.value.message = @@lastmessage
          end
        elsif c == CDoom::KEY_ESCAPE
          CDoom.chat_on = 0
        end
      end
    end

    return eatkey
  end
end
