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
# ==> Doom 2 finale code

module Doocr
  #
  # f_start_finale
  #
  def self.f_start_finale
    Doocr.gameaction = Doocr::Gameaction::Nothing
    Doocr.gamestate = Doocr::Gamestate::Finale
    Doocr.viewactive = 0
    Doocr.automapactive = 0

    # Okay - IWAD dependend stuff.
    # This has been changed severly, and
    #  some stuff might have changed in the process.
    case Doocr.gamemode
    # DOOM 1 - E1, E3 or E4, but each nine missions
    when Doocr::GameMode::Shareware, Doocr::GameMode::Registered, Doocr::GameMode::Retail
      Doocr.s_change_music(Doocr::Musicenum::MUS_victor, 1)

      case Doocr.gameepisode
      when 1
        Doocr.finaleflat = "FLOOR4_8"
        Doocr.finaletext = @@deh_e1text
      when 2
        Doocr.finaleflat = "SFLR6_1"
        Doocr.finaletext = @@deh_e2text
      when 3
        Doocr.finaleflat = "MFLR8_4"
        Doocr.finaletext = @@deh_e3text
      when 4
        Doocr.finaleflat = "MFLR8_3"
        Doocr.finaletext = @@deh_e4text
      else
        # Ouch.
      end
      # DOOM II and missions packs with E1, M34
    when Doocr::GameMode::Commercial
      Doocr.s_change_music(Doocr::Musicenum::MUS_read_m, 1)

      case Doocr.gamemap
      when 6
        Doocr.finaleflat = "SLIME16"
        Doocr.finaletext = @@deh_c1text
      when 11
        Doocr.finaleflat = "RROCK14"
        Doocr.finaletext = @@deh_c2text
      when 20
        Doocr.finaleflat = "RROCK07"
        Doocr.finaletext = @@deh_c3text
      when 30
        Doocr.finaleflat = "RROCK17"
        Doocr.finaletext = @@deh_c4text
      when 15
        Doocr.finaleflat = "RROCK13"
        Doocr.finaletext = @@deh_c5text
      when 31
        Doocr.finaleflat = "RROCK19"
        Doocr.finaletext = @@deh_c6text
      else
        # Ouch
      end

      # Indeterminate.
    else
      Doocr.s_change_music(Doocr::Musicenum::MUS_read_m, 1)
      Doocr.finaleflat = "F_SKY1"     # Not used anywhere else.
      Doocr.finaletext = @@deh_c1text # FIXME - other text, music?
    end

    Doocr.finalestage = 0
    Doocr.finalecount = 0
  end

  def self.f_responder(event : Doocr::Event) : LibC::Int
    return Doocr.f_cast_responder(event) if Doocr.finalestage == 2

    return 0
  end

  #
  # f_ticker
  #
  def self.f_ticker
    # check for skipping
    if Doocr.gamemode == Doocr::GameMode::Commercial && Doocr.finalecount > 50
      # go on to the next level
      i = 0
      CDoom::MAXPLAYERS.times do |j|
        break if @@players[i].cmd.buttons != 0
        i += 1
      end

      if i < CDoom::MAXPLAYERS
        if Doocr.gamemap == 30
          CDoom.f_start_cast
        else
          Doocr.gameaction = Doocr::Gameaction::Worlddone
        end
      end
    end

    # advance animation
    Doocr.finalecount += 1

    if Doocr.finalestage == 2
      CDoom.f_cast_ticker
      return
    end

    return if Doocr.gamemode == Doocr::GameMode::Commercial

    if Doocr.finalestage == 0 && Doocr.finalecount > CDoom.doom_strlen(Doocr.finaletext.to_unsafe) * Doocr::TEXTSPEED + Doocr::TEXTWAIT
      Doocr.finalecount = 0
      Doocr.finalestage = 1
      Doocr.wipegamestate = Doocr::Gamestate::Needwipe # force a wipe
      if Doocr.gameepisode == 3
        Doocr.s_start_music(Doocr::Musicenum::MUS_bunny)
      end
    end
  end

  #
  # f_text_write
  #
  def self.f_text_write
    # erase the entire screen to a tiled background
    src = CDoom.w_cache_lump_name(Doocr.finaleflat.to_unsafe, Doocr::PU_CACHE)
    dest = Doocr.screens[0]

    CDoom::SCREENHEIGHT.times do |y|
      (CDoom::SCREENWIDTH // 64).times do |x|
        CDoom.doom_memcpy(dest, src + ((y & 63) << 6), 64)
        dest += 64
      end
      if CDoom::SCREENWIDTH & 63 != 0
        CDoom.doom_memcpy(dest, src + ((y & 63) << 6), CDoom::SCREENWIDTH & 63)
        dest += CDoom::SCREENWIDTH & 63
      end
    end

    CDoom.v_mark_rect(0, 0, CDoom::SCREENWIDTH, CDoom::SCREENHEIGHT)

    # draw some of the text onto the screen
    cx = 10
    cy = 10
    ch = Doocr.finaletext.to_unsafe

    count = (Doocr.finalecount - 10) // Doocr::TEXTSPEED
    count = 0 if count < 0
    while count != 0
      c = ch.value
      ch += 1
      break if c == '\0'.ord
      if c == '\n'.ord
        cx = 10
        cy += 11
        next
      end

      c = CDoom.doom_toupper(c) - Doocr::HU_FONTSTART
      if c < 0 || c > Doocr::HU_FONTSIZE
        cx += 4
        next
      end

      w = Doocr.hu_font[c].value.width.to_i16!
      break if cx + w > CDoom::SCREENWIDTH
      CDoom.v_draw_patch(cx, cy, 0, Doocr.hu_font[c])
      cx += w

      count -= 1
    end
  end

  #
  # Final DOOM 2 animation
  # Casting by id Software.
  #   in order of appearance
  #
  def self.f_start_cast
    return if Doocr.finalestage == 2

    Doocr.wipegamestate = Doocr::Gamestate::Needwipe # force a screen wipe
    Doocr.castnum = 0
    Doocr.caststate = Doocr.states[Doocr.mobjinfo[@@castorder[Doocr.castnum].type.value].seestate]
    Doocr.casttics = Doocr.caststate.not_nil!.tics.to_i32
    Doocr.castdeath = 0
    Doocr.finalestage = 2
    Doocr.castframes = 0
    Doocr.castonmelee = 0
    Doocr.castattacking = 0
    Doocr.s_change_music(Doocr::Musicenum::MUS_evil, 1)
  end

  #
  # f_cast_ticker
  #
  def self.f_cast_ticker
    Doocr.casttics -= 1
    return if Doocr.casttics > 0 # not time to change state yet

    if Doocr.caststate.not_nil!.tics == -1 || Doocr.caststate.not_nil!.nextstate == Doocr::Statenum::S_NULL
      # switch from deathstate to next monster
      Doocr.castnum += 1
      Doocr.castdeath = 0
      Doocr.castnum = 0 if @@castorder[Doocr.castnum].name.empty?
      if Doocr.mobjinfo[@@castorder[Doocr.castnum].type.value].seesound != 0
        Doocr.s_start_sound(Pointer(Void).null, Doocr.mobjinfo[@@castorder[Doocr.castnum].type.value].seesound)
      end
      Doocr.caststate = Doocr.states[Doocr.mobjinfo[@@castorder[Doocr.castnum].type.value].seestate]
      Doocr.castframes = 0
    else
      # just advance to next state in amnimation
      if Doocr.caststate == Doocr.states[Doocr::Statenum::S_PLAY_ATK1.value]
        # Yes, it is a gross hack!
        Doocr.castattacking = 0
        Doocr.castframes = 0
        Doocr.caststate = Doocr.states[Doocr.mobjinfo[@@castorder[Doocr.castnum].type.value].seestate]
        Doocr.casttics = Doocr.caststate.not_nil!.tics.to_i32
        Doocr.casttics = 15 if Doocr.casttics == -1
        return
      end
      st = Doocr.caststate.not_nil!.nextstate
      Doocr.caststate = Doocr.states[st.value]
      Doocr.castframes += 1

      sfx = 0
      # sound hacks....
      case st
      when Doocr::Statenum::S_PLAY_ATK1
        sfx = Doocr::Sfxenum::SFX_dshtgn
      when Doocr::Statenum::S_POSS_ATK2
        sfx = Doocr::Sfxenum::SFX_pistol
      when Doocr::Statenum::S_SPOS_ATK2
        sfx = Doocr::Sfxenum::SFX_shotgn
      when Doocr::Statenum::S_VILE_ATK2
        sfx = Doocr::Sfxenum::SFX_vilatk
      when Doocr::Statenum::S_SKEL_FIST2
        sfx = Doocr::Sfxenum::SFX_skeswg
      when Doocr::Statenum::S_SKEL_FIST4
        sfx = Doocr::Sfxenum::SFX_skepch
      when Doocr::Statenum::S_SKEL_MISS2
        sfx = Doocr::Sfxenum::SFX_skeatk
      when Doocr::Statenum::S_FATT_ATK8, Doocr::Statenum::S_FATT_ATK5, Doocr::Statenum::S_FATT_ATK2
        sfx = Doocr::Sfxenum::SFX_firsht
      when Doocr::Statenum::S_CPOS_ATK2, Doocr::Statenum::S_CPOS_ATK3, Doocr::Statenum::S_CPOS_ATK4
        sfx = Doocr::Sfxenum::SFX_shotgn
      when Doocr::Statenum::S_TROO_ATK3
        sfx = Doocr::Sfxenum::SFX_claw
      when Doocr::Statenum::S_SARG_ATK2
        sfx = Doocr::Sfxenum::SFX_sgtatk
      when Doocr::Statenum::S_BOSS_ATK2, Doocr::Statenum::S_BOS2_ATK2, Doocr::Statenum::S_HEAD_ATK2
        sfx = Doocr::Sfxenum::SFX_firsht
      when Doocr::Statenum::S_SKULL_ATK2
        sfx = Doocr::Sfxenum::SFX_sklatk
      when Doocr::Statenum::S_SPID_ATK2, Doocr::Statenum::S_SPID_ATK3
        sfx = Doocr::Sfxenum::SFX_shotgn
      when Doocr::Statenum::S_BSPI_ATK2
        sfx = Doocr::Sfxenum::SFX_plasma
      when Doocr::Statenum::S_CYBER_ATK2, Doocr::Statenum::S_CYBER_ATK4, Doocr::Statenum::S_CYBER_ATK6
        sfx = Doocr::Sfxenum::SFX_rlaunc
      when Doocr::Statenum::S_PAIN_ATK3
        sfx = Doocr::Sfxenum::SFX_sklatk
      end

      Doocr.s_start_sound(Pointer(Void).null, sfx) if sfx != 0
    end

    if Doocr.castframes == 12
      # go into attack frame
      Doocr.castattacking = 1
      if Doocr.castonmelee != 0
        Doocr.caststate = Doocr.states[Doocr.mobjinfo[@@castorder[Doocr.castnum].type.value].meleestate]
      else
        Doocr.caststate = Doocr.states[Doocr.mobjinfo[@@castorder[Doocr.castnum].type.value].missilestate]
      end
      Doocr.castonmelee ^= 1
      if Doocr.caststate == Doocr.states[Doocr::Statenum::S_NULL.value]
        if Doocr.castonmelee != 0
          Doocr.caststate = Doocr.states[Doocr.mobjinfo[@@castorder[Doocr.castnum].type.value].meleestate]
        else
          Doocr.caststate = Doocr.states[Doocr.mobjinfo[@@castorder[Doocr.castnum].type.value].missilestate]
        end
      end
    end

    if Doocr.castattacking != 0
      if Doocr.castframes == 24 ||
         Doocr.caststate == @@states.to_unsafe + Doocr.mobjinfo[@@castorder[Doocr.castnum].type.value].seestate
        Doocr.castattacking = 0
        Doocr.castframes = 0
        Doocr.caststate = Doocr.states[Doocr.mobjinfo[@@castorder[Doocr.castnum].type.value].seestate]
      end
    end

    Doocr.casttics = Doocr.caststate.not_nil!.tics.to_i32
    Doocr.casttics = 15 if Doocr.casttics == -1
  end

  def self.f_cast_responder(ev : Doocr::Event) : LibC::Int
    return 0 if ev.type != Doocr::Evtype::Keydown &&
          (ev.type != Doocr::Evtype::Mouse || ev.data1 == 0)

    return 1 if Doocr.castdeath != 0 # already in dying frames

    # go into death frame
    Doocr.castdeath = 1
    Doocr.caststate = Doocr.states[Doocr.mobjinfo[@@castorder[Doocr.castnum].type.value].deathstate]
    Doocr.casttics = Doocr.caststate.not_nil!.tics.to_i32
    Doocr.castframes = 0
    Doocr.castattacking = 0
    if Doocr.mobjinfo[@@castorder[Doocr.castnum].type.value].deathsound != 0
      Doocr.s_start_sound(Pointer(Void).null, Doocr.mobjinfo[@@castorder[Doocr.castnum].type.value].deathsound)
    end

    return 1
  end

  def self.f_cast_print(text : UInt8*)
    # find width
    ch = text
    width = 0

    while ch != 0
      c = ch.value
      ch += 1
      break if c == '\0'.ord
      c = CDoom.doom_toupper(c) - Doocr::HU_FONTSTART
      if c < 0 || c > Doocr::HU_FONTSIZE
        width += 4
        next
      end

      w = Doocr.hu_font[c].value.width.to_i16!
      width += w
    end

    # draw it
    cx = 160 - width // 2
    ch = text
    while ch != 0
      c = ch.value
      ch += 1
      break if c == '\0'.ord
      c = CDoom.doom_toupper(c) - Doocr::HU_FONTSTART
      if c < 0 || c > Doocr::HU_FONTSIZE
        cx += 4
        next
      end

      w = Doocr.hu_font[c].value.width.to_i16!
      CDoom.v_draw_patch(cx, 180, 0, Doocr.hu_font[c])
      cx += w
    end
  end

  #
  # f_cast_drawer
  #
  def self.f_cast_drawer
    # erase the entire screen to a background
    CDoom.v_draw_patch(0, 0, 0, CDoom.w_cache_lump_name("BOSSBACK", Doocr::PU_CACHE).as(CDoom::Patch*))

    CDoom.f_cast_print(@@castorder[Doocr.castnum].name.to_unsafe)

    # draw the current frame in the middle of the screen
    caststate = Doocr.caststate.not_nil!
    sprdef = Doocr.sprites + caststate.sprite.value
    sprframe = sprdef.value.spriteframes + (caststate.frame & Doocr::FF_FRAMEMASK)
    lump = sprframe.value.lump[0]
    flip = sprframe.value.flip[0]

    patch = CDoom.w_cache_lump_num(lump + Doocr.firstspritelump, Doocr::PU_CACHE).as(CDoom::Patch*)
    if flip != 0
      CDoom.v_draw_patch_flipped(160, 170, 0, patch)
    else
      CDoom.v_draw_patch(160, 170, 0, patch)
    end
  end

  #
  # f_draw_patch_col
  #
  def self.f_draw_patch_col(x : Int32, patch : CDoom::Patch*, col : Int32)
    column = (patch.as(UInt8*) + (patch.value.columnofs.to_unsafe + col).value.to_i32!).as(CDoom::Post*)
    desttop = Doocr.screens[0] + x

    # step through the posts in a column
    while column.value.topdelta != 0xff
      source = column.as(UInt8*) + 3
      dest = desttop + column.value.topdelta * CDoom::SCREENWIDTH
      count = column.value.length

      while count != 0
        dest.value = source.value
        source += 1
        dest += CDoom::SCREENWIDTH
        count -= 1
      end
      column = (column.as(UInt8*) + column.value.length + 4).as(CDoom::Post*)
    end
  end

  @@laststage = 0

  #
  # f_bunny_scroll
  #
  def self.f_bunny_scroll
    p1 = CDoom.w_cache_lump_name("PFUB2", Doocr::PU_LEVEL).as(CDoom::Patch*)
    p2 = CDoom.w_cache_lump_name("PFUB1", Doocr::PU_LEVEL).as(CDoom::Patch*)

    CDoom.v_mark_rect(0, 0, CDoom::SCREENWIDTH, CDoom::SCREENHEIGHT)

    scrolled = 320 - (Doocr.finalecount - 230) // 2
    scrolled = 320 if scrolled > 320
    scrolled = 0 if scrolled < 0

    CDoom::SCREENWIDTH.times do |x|
      if x + scrolled < 320
        CDoom.f_draw_patch_col(x, p1, x + scrolled)
      else
        CDoom.f_draw_patch_col(x, p2, x + scrolled - 320)
      end
    end

    return if Doocr.finalecount < 1130
    if Doocr.finalecount < 1180
      CDoom.v_draw_patch((CDoom::SCREENWIDTH - 13 * 8) // 2,
        (CDoom::SCREENHEIGHT - 8 * 8) // 2, 0, CDoom.w_cache_lump_name("END0", Doocr::PU_CACHE).as(CDoom::Patch*))
      @@laststage = 0
      return
    end

    stage = (Doocr.finalecount - 1180) // 5
    stage = 6 if stage > 6
    if stage > @@laststage
      Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_pistol)
      @@laststage = stage
    end

    name = uninitialized StaticArray(UInt8, 10)

    CDoom.doom_strcpy(name.to_unsafe, "END")
    CDoom.doom_concat(name.to_unsafe, CDoom.doom_itoa(stage, 10))
    CDoom.v_draw_patch((CDoom::SCREENWIDTH - 13 * 8) // 2, (CDoom::SCREENHEIGHT - 8 * 8) // 2, 0, CDoom.w_cache_lump_name(name.to_unsafe, Doocr::PU_CACHE).as(CDoom::Patch*))
  end

  def self.f_drawer
    if Doocr.finalestage == 2
      CDoom.f_cast_drawer
      return
    end

    if Doocr.finalestage == 0
      CDoom.f_text_write
    else
      case Doocr.gameepisode
      when 1
        if Doocr.gamemode == Doocr::GameMode::Retail
          CDoom.v_draw_patch(0, 0, 0,
            CDoom.w_cache_lump_name("CREDIT", Doocr::PU_CACHE).as(CDoom::Patch*))
        else
          CDoom.v_draw_patch(0, 0, 0,
            CDoom.w_cache_lump_name("HELP2", Doocr::PU_CACHE).as(CDoom::Patch*))
        end
      when 2
        CDoom.v_draw_patch(0, 0, 0,
          CDoom.w_cache_lump_name("VICTORY2", Doocr::PU_CACHE).as(CDoom::Patch*))
      when 3
        CDoom.f_bunny_scroll
      when 4
        CDoom.v_draw_patch(0, 0, 0,
          CDoom.w_cache_lump_name("ENDPIC", Doocr::PU_CACHE).as(CDoom::Patch*))
      end
    end
  end
end
