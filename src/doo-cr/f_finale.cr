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
    CDoom.gameaction = CDoom::Gameaction::Nothing
    CDoom.gamestate = CDoom::Gamestate::Finale
    CDoom.viewactive = 0
    CDoom.automapactive = 0

    # Okay - IWAD dependend stuff.
    # This has been changed severly, and
    #  some stuff might have changed in the process.
    case CDoom.gamemode
    # DOOM 1 - E1, E3 or E4, but each nine missions
    when CDoom::GameMode::Shareware, CDoom::GameMode::Registered, CDoom::GameMode::Retail
      CDoom.s_change_music(CDoom::Musicenum::MUS_victor, 1)

      case CDoom.gameepisode
      when 1
        CDoom.finaleflat = "FLOOR4_8"
        CDoom.finaletext = @@deh_e1text
      when 2
        CDoom.finaleflat = "SFLR6_1"
        CDoom.finaletext = @@deh_e2text
      when 3
        CDoom.finaleflat = "MFLR8_4"
        CDoom.finaletext = @@deh_e3text
      when 4
        CDoom.finaleflat = "MFLR8_3"
        CDoom.finaletext = @@deh_e4text
      else
        # Ouch.
      end
      # DOOM II and missions packs with E1, M34
    when CDoom::GameMode::Commercial
      CDoom.s_change_music(CDoom::Musicenum::MUS_read_m, 1)

      case CDoom.gamemap
      when 6
        CDoom.finaleflat = "SLIME16"
        CDoom.finaletext = @@deh_c1text
      when 11
        CDoom.finaleflat = "RROCK14"
        CDoom.finaletext = @@deh_c2text
      when 20
        CDoom.finaleflat = "RROCK07"
        CDoom.finaletext = @@deh_c3text
      when 30
        CDoom.finaleflat = "RROCK17"
        CDoom.finaletext = @@deh_c4text
      when 15
        CDoom.finaleflat = "RROCK13"
        CDoom.finaletext = @@deh_c5text
      when 31
        CDoom.finaleflat = "RROCK19"
        CDoom.finaletext = @@deh_c6text
      else
        # Ouch
      end

      # Indeterminate.
    else
      CDoom.s_change_music(CDoom::Musicenum::MUS_read_m, 1)
      CDoom.finaleflat = "F_SKY1"     # Not used anywhere else.
      CDoom.finaletext = @@deh_c1text # FIXME - other text, music?
    end

    CDoom.finalestage = 0
    CDoom.finalecount = 0
  end

  def self.f_responder(event : CDoom::Event*) : CDoom::DoomBool
    return CDoom.f_cast_responder(event) if CDoom.finalestage == 2

    return 0
  end

  #
  # f_ticker
  #
  def self.f_ticker
    # check for skipping
    if CDoom.gamemode == CDoom::GameMode::Commercial && CDoom.finalecount > 50
      # go on to the next level
      i = 0
      CDoom::MAXPLAYERS.times do |j|
        break if CDoom.players[i].cmd.buttons != 0
        i += 1
      end

      if i < CDoom::MAXPLAYERS
        if CDoom.gamemap == 30
          CDoom.f_start_cast
        else
          CDoom.gameaction = CDoom::Gameaction::Worlddone
        end
      end
    end

    # advance animation
    CDoom.finalecount += 1

    if CDoom.finalestage == 2
      CDoom.f_cast_ticker
      return
    end

    return if CDoom.gamemode == CDoom::GameMode::Commercial

    if CDoom.finalestage == 0 && CDoom.finalecount > CDoom.doom_strlen(CDoom.finaletext) * CDoom::TEXTSPEED + CDoom::TEXTWAIT
      CDoom.finalecount = 0
      CDoom.finalestage = 1
      CDoom.wipegamestate = CDoom::Gamestate::Needwipe # force a wipe
      if CDoom.gameepisode == 3
        CDoom.s_start_music(CDoom::Musicenum::MUS_bunny)
      end
    end
  end

  #
  # f_text_write
  #
  def self.f_text_write
    # erase the entire screen to a tiled background
    src = CDoom.w_cache_lump_name(CDoom.finaleflat, CDoom::PU_CACHE)
    dest = CDoom.screens[0]

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
    ch = CDoom.finaletext

    count = (CDoom.finalecount - 10) // CDoom::TEXTSPEED
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

      c = CDoom.doom_toupper(c) - CDoom::HU_FONTSTART
      if c < 0 || c > CDoom::HU_FONTSIZE
        cx += 4
        next
      end

      w = CDoom.hu_font[c].value.width.to_i16!
      break if cx + w > CDoom::SCREENWIDTH
      CDoom.v_draw_patch(cx, cy, 0, CDoom.hu_font[c])
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
    return if CDoom.finalestage == 2

    CDoom.wipegamestate = CDoom::Gamestate::Needwipe # force a screen wipe
    CDoom.castnum = 0
    CDoom.caststate = CDoom.states + CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].seestate
    CDoom.casttics = CDoom.caststate.value.tics
    CDoom.castdeath = 0
    CDoom.finalestage = 2
    CDoom.castframes = 0
    CDoom.castonmelee = 0
    CDoom.castattacking = 0
    CDoom.s_change_music(CDoom::Musicenum::MUS_evil, 1)
  end

  #
  # f_cast_ticker
  #
  def self.f_cast_ticker
    CDoom.casttics -= 1
    return if CDoom.casttics > 0 # not time to change state yet

    if CDoom.caststate.value.tics == -1 || CDoom.caststate.value.nextstate == CDoom::Statenum::S_NULL
      # switch from deathstate to next monster
      CDoom.castnum += 1
      CDoom.castdeath = 0
      CDoom.castnum = 0 if CDoom.castorder[CDoom.castnum].name.null?
      if CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].seesound != 0
        CDoom.s_start_sound(Pointer(Void).null, CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].seesound)
      end
      CDoom.caststate = CDoom.states + CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].seestate
      CDoom.castframes = 0
    else
      # just advance to next state in amnimation
      if CDoom.caststate == CDoom.states + CDoom::Statenum::S_PLAY_ATK1.value
        # Yes, it is a gross hack!
        CDoom.castattacking = 0
        CDoom.castframes = 0
        CDoom.caststate = CDoom.states + CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].seestate
        CDoom.casttics = CDoom.caststate.value.tics
        CDoom.casttics = 15 if CDoom.casttics == -1
        return
      end
      st = CDoom.caststate.value.nextstate
      CDoom.caststate = CDoom.states + st.value
      CDoom.castframes += 1

      sfx = 0
      # sound hacks....
      case st
      when CDoom::Statenum::S_PLAY_ATK1
        sfx = CDoom::Sfxenum::SFX_dshtgn
      when CDoom::Statenum::S_POSS_ATK2
        sfx = CDoom::Sfxenum::SFX_pistol
      when CDoom::Statenum::S_SPOS_ATK2
        sfx = CDoom::Sfxenum::SFX_shotgn
      when CDoom::Statenum::S_VILE_ATK2
        sfx = CDoom::Sfxenum::SFX_vilatk
      when CDoom::Statenum::S_SKEL_FIST2
        sfx = CDoom::Sfxenum::SFX_skeswg
      when CDoom::Statenum::S_SKEL_FIST4
        sfx = CDoom::Sfxenum::SFX_skepch
      when CDoom::Statenum::S_SKEL_MISS2
        sfx = CDoom::Sfxenum::SFX_skeatk
      when CDoom::Statenum::S_FATT_ATK8, CDoom::Statenum::S_FATT_ATK5, CDoom::Statenum::S_FATT_ATK2
        sfx = CDoom::Sfxenum::SFX_firsht
      when CDoom::Statenum::S_CPOS_ATK2, CDoom::Statenum::S_CPOS_ATK3, CDoom::Statenum::S_CPOS_ATK4
        sfx = CDoom::Sfxenum::SFX_shotgn
      when CDoom::Statenum::S_TROO_ATK3
        sfx = CDoom::Sfxenum::SFX_claw
      when CDoom::Statenum::S_SARG_ATK2
        sfx = CDoom::Sfxenum::SFX_sgtatk
      when CDoom::Statenum::S_BOSS_ATK2, CDoom::Statenum::S_BOS2_ATK2, CDoom::Statenum::S_HEAD_ATK2
        sfx = CDoom::Sfxenum::SFX_firsht
      when CDoom::Statenum::S_SKULL_ATK2
        sfx = CDoom::Sfxenum::SFX_sklatk
      when CDoom::Statenum::S_SPID_ATK2, CDoom::Statenum::S_SPID_ATK3
        sfx = CDoom::Sfxenum::SFX_shotgn
      when CDoom::Statenum::S_BSPI_ATK2
        sfx = CDoom::Sfxenum::SFX_plasma
      when CDoom::Statenum::S_CYBER_ATK2, CDoom::Statenum::S_CYBER_ATK4, CDoom::Statenum::S_CYBER_ATK6
        sfx = CDoom::Sfxenum::SFX_rlaunc
      when CDoom::Statenum::S_PAIN_ATK3
        sfx = CDoom::Sfxenum::SFX_sklatk
      end

      CDoom.s_start_sound(Pointer(Void).null, sfx) if sfx != 0
    end

    if CDoom.castframes == 12
      # go into attack frame
      CDoom.castattacking = 1
      if CDoom.castonmelee != 0
        CDoom.caststate = CDoom.states + CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].meleestate
      else
        CDoom.caststate = CDoom.states + CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].missilestate
      end
      CDoom.castonmelee ^= 1
      if CDoom.caststate == CDoom.states + CDoom::Statenum::S_NULL.value
        if CDoom.castonmelee != 0
          CDoom.caststate = CDoom.states + CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].meleestate
        else
          CDoom.caststate = CDoom.states + CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].missilestate
        end
      end
    end

    if CDoom.castattacking != 0
      if CDoom.castframes == 24 ||
         CDoom.caststate == CDoom.states + CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].seestate
        CDoom.castattacking = 0
        CDoom.castframes = 0
        CDoom.caststate = CDoom.states + CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].seestate
      end
    end

    CDoom.casttics = CDoom.caststate.value.tics
    CDoom.casttics = 15 if CDoom.casttics == -1
  end

  def self.f_cast_responder(ev : CDoom::Event*) : CDoom::DoomBool
    return 0 if ev.value.type != CDoom::Evtype::Keydown &&
                (ev.value.type != CDoom::Evtype::Mouse || ev.value.data1 == 0)

    return 1 if CDoom.castdeath != 0 # already in dying frames

    # go into death frame
    CDoom.castdeath = 1
    CDoom.caststate = CDoom.states + CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].deathstate
    CDoom.casttics = CDoom.caststate.value.tics
    CDoom.castframes = 0
    CDoom.castattacking = 0
    if CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].deathsound != 0
      CDoom.s_start_sound(Pointer(Void).null, CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].deathsound)
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
      c = CDoom.doom_toupper(c) - CDoom::HU_FONTSTART
      if c < 0 || c > CDoom::HU_FONTSIZE
        width += 4
        next
      end

      w = CDoom.hu_font[c].value.width.to_i16!
      width += w
    end

    # draw it
    cx = 160 - width // 2
    ch = text
    while ch != 0
      c = ch.value
      ch += 1
      break if c == '\0'.ord
      c = CDoom.doom_toupper(c) - CDoom::HU_FONTSTART
      if c < 0 || c > CDoom::HU_FONTSIZE
        cx += 4
        next
      end

      w = CDoom.hu_font[c].value.width.to_i16!
      CDoom.v_draw_patch(cx, 180, 0, CDoom.hu_font[c])
      cx += w
    end
  end

  #
  # f_cast_drawer
  #
  def self.f_cast_drawer
    # erase the entire screen to a background
    CDoom.v_draw_patch(0, 0, 0, CDoom.w_cache_lump_name("BOSSBACK", CDoom::PU_CACHE).as(CDoom::Patch*))

    CDoom.f_cast_print(CDoom.castorder[CDoom.castnum].name)

    # draw the current frame in the middle of the screen
    sprdef = CDoom.sprites + CDoom.caststate.value.sprite.value
    sprframe = sprdef.value.spriteframes + (CDoom.caststate.value.frame & CDoom::FF_FRAMEMASK)
    lump = sprframe.value.lump[0]
    flip = sprframe.value.flip[0]

    patch = CDoom.w_cache_lump_num(lump + CDoom.firstspritelump, CDoom::PU_CACHE).as(CDoom::Patch*)
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
    column = (patch.as(UInt8*) + (patch.value.columnofs.to_unsafe + col).value.to_i32!).as(CDoom::Column*)
    desttop = CDoom.screens[0] + x

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
      column = (column.as(UInt8*) + column.value.length + 4).as(CDoom::Column*)
    end
  end

  @@laststage = 0

  #
  # f_bunny_scroll
  #
  def self.f_bunny_scroll
    p1 = CDoom.w_cache_lump_name("PFUB2", CDoom::PU_LEVEL).as(CDoom::Patch*)
    p2 = CDoom.w_cache_lump_name("PFUB1", CDoom::PU_LEVEL).as(CDoom::Patch*)

    CDoom.v_mark_rect(0, 0, CDoom::SCREENWIDTH, CDoom::SCREENHEIGHT)

    scrolled = 320 - (CDoom.finalecount - 230) // 2
    scrolled = 320 if scrolled > 320
    scrolled = 0 if scrolled < 0

    CDoom::SCREENWIDTH.times do |x|
      if x + scrolled < 320
        CDoom.f_draw_patch_col(x, p1, x + scrolled)
      else
        CDoom.f_draw_patch_col(x, p2, x + scrolled - 320)
      end
    end

    return if CDoom.finalecount < 1130
    if CDoom.finalecount < 1180
      CDoom.v_draw_patch((CDoom::SCREENWIDTH - 13 * 8) // 2,
        (CDoom::SCREENHEIGHT - 8 * 8) // 2, 0, CDoom.w_cache_lump_name("END0", CDoom::PU_CACHE).as(CDoom::Patch*))
      @@laststage = 0
      return
    end

    stage = (CDoom.finalecount - 1180) // 5
    stage = 6 if stage > 6
    if stage > @@laststage
      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_pistol)
      @@laststage = stage
    end

    name = uninitialized StaticArray(UInt8, 10)

    CDoom.doom_strcpy(name.to_unsafe, "END")
    CDoom.doom_concat(name.to_unsafe, CDoom.doom_itoa(stage, 10))
    CDoom.v_draw_patch((CDoom::SCREENWIDTH - 13 * 8) // 2, (CDoom::SCREENHEIGHT - 8 * 8) // 2, 0, CDoom.w_cache_lump_name(name.to_unsafe, CDoom::PU_CACHE).as(CDoom::Patch*))
  end

  def self.f_drawer
    if CDoom.finalestage == 2
      CDoom.f_cast_drawer
      return
    end

    if CDoom.finalestage == 0
      CDoom.f_text_write
    else
      case CDoom.gameepisode
      when 1
        if CDoom.gamemode == CDoom::GameMode::Retail
          CDoom.v_draw_patch(0, 0, 0,
            CDoom.w_cache_lump_name("CREDIT", CDoom::PU_CACHE).as(CDoom::Patch*))
        else
          CDoom.v_draw_patch(0, 0, 0,
            CDoom.w_cache_lump_name("HELP2", CDoom::PU_CACHE).as(CDoom::Patch*))
        end
      when 2
        CDoom.v_draw_patch(0, 0, 0,
          CDoom.w_cache_lump_name("VICTORY2", CDoom::PU_CACHE).as(CDoom::Patch*))
      when 3
        CDoom.f_bunny_scroll
      when 4
        CDoom.v_draw_patch(0, 0, 0,
          CDoom.w_cache_lump_name("ENDPIC", CDoom::PU_CACHE).as(CDoom::Patch*))
      end
    end
  end
end
