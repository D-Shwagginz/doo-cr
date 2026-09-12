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
# ==> Status bar

module Doocr
  def self.stlib_init
    Doocr.sttminus = CDoom.w_cache_lump_name("STTMINUS", Doocr::PU_STATIC).as(CDoom::Patch*)
  end

  # ?
  def self.stlib_init_num(n : Doocr::ST_Number,
                          x : LibC::Int,
                          y : LibC::Int,
                          pl : CDoom::Patch**,
                          num : LibC::Int*,
                          on : LibC::Int*,
                          width : LibC::Int)
    n.x = x
    n.y = y
    n.oldnum = 0
    n.width = width
    n.num = num
    n.on = on
    n.p = pl
  end

  #
  # A fairly efficient way to draw a number
  #  based on differences from the old number.
  # Note: worth the trouble?
  #
  def self.stlib_draw_num(n : Doocr::ST_Number, refresh : LibC::Int)
    numdigits = n.width
    num = n.num.value

    w = n.p[0].value.width
    h = n.p[0].value.height
    x = n.x

    n.oldnum = n.num.value

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
    x = n.x - numdigits * w

    if n.y - Doocr::ST_Y < 0
      CDoom.i_error("Error: stlib_draw_num: n.y - Doocr::ST_Y < 0")
    end

    CDoom.v_copy_rect(x, n.y - Doocr::ST_Y, Doocr::STLIB_BG, w * numdigits, h, x, n.y, Doocr::STLIB_FG)

    # if non-number, do not draw it
    return if num == 1994

    x = n.x

    # in the special case of 0, you draw 0
    if num == 0
      CDoom.v_draw_patch(x - w, n.y, Doocr::STLIB_FG, n.p[0])
    end

    # draw the new number
    while num != 0 && numdigits != 0
      numdigits -= 1
      x -= w
      CDoom.v_draw_patch(x, n.y, Doocr::STLIB_FG, n.p[num % 10])
      num //= 10
    end

    # draw a minus sign if necessary
    if neg
      CDoom.v_draw_patch(x - 8, n.y, Doocr::STLIB_FG, Doocr.sttminus)
    end
  end

  def self.stlib_update_num(n : Doocr::ST_Number, refresh : LibC::Int)
    Doocr.stlib_draw_num(n, refresh) if n.on.value != 0
  end

  def self.stlib_init_percent(p : Doocr::ST_Percent,
                              x : LibC::Int,
                              y : LibC::Int,
                              pl : CDoom::Patch**,
                              num : LibC::Int*,
                              on : LibC::Int*,
                              percent : CDoom::Patch*)
    Doocr.stlib_init_num(
      p.n,
      x, y, pl, num, on, 3)
    p.p = percent
  end

  def self.stlib_update_percent(per : Doocr::ST_Percent, refresh : LibC::Int)
    if refresh != 0 && per.n.on.value != 0
      CDoom.v_draw_patch(per.n.x, per.n.y, Doocr::STLIB_FG, per.p)
    end

    Doocr.stlib_update_num(
      per.n,
      refresh
    )
  end

  def self.stlib_init_mult_icon(i : Doocr::ST_Multicon,
                                x : LibC::Int,
                                y : LibC::Int,
                                il : CDoom::Patch**,
                                inum : LibC::Int*,
                                on : LibC::Int*)
    i.x = x
    i.y = y
    i.oldinum = -1
    i.inum = inum
    i.on = on
    i.p = il
  end

  def self.stlib_update_mult_icon(mi : Doocr::ST_Multicon,
                                  refresh : LibC::Int)
    # Lazy ssg number hack to use whichever shotgun is active
    if Doocr.gamemode == Doocr::GameMode::Commercial &&
       mi.inum == Doocr.plyr.value.weaponowned.to_unsafe + Doocr::Weapontype::Shotgun.value &&
       mi.inum.value < (ssgnum = (Doocr.plyr.value.weaponowned.to_unsafe + Doocr::Weapontype::Supershotgun.value)).value
      mi.inum = ssgnum
    end

    if mi.on.value != 0 &&
       (mi.oldinum != mi.inum.value || refresh != 0) &&
       mi.inum.value != -1
      if mi.oldinum != -1
        x = mi.x - mi.p[mi.oldinum].value.leftoffset
        y = mi.y - mi.p[mi.oldinum].value.topoffset
        w = mi.p[mi.oldinum].value.width
        h = mi.p[mi.oldinum].value.height

        if y - Doocr::ST_Y < 0
          CDoom.i_error("Error: stlib_update_multi_icon: y - Doocr::ST_Y < 0")
        end

        CDoom.v_copy_rect(x, y - Doocr::ST_Y, Doocr::STLIB_BG, w, h, x, y, Doocr::STLIB_FG)
      end
      CDoom.v_draw_patch(mi.x, mi.y, Doocr::STLIB_FG, mi.p[mi.inum.value])
      mi.oldinum = mi.inum.value
    end
  end

  def self.stlib_init_bin_icon(b : Doocr::ST_Binicon,
                               x : LibC::Int,
                               y : LibC::Int,
                               i : CDoom::Patch*,
                               val : LibC::Int*,
                               on : LibC::Int*)
    b.x = x
    b.y = y
    b.oldval = 0
    b.val = val
    b.on = on
    b.p = i
  end

  def self.stlib_update_bin_icon(bi : Doocr::ST_Binicon, refresh : LibC::Int)
    if bi.on.value != 0 && (bi.oldval != bi.val.value || refresh != 0)
      x = bi.x - bi.p.value.leftoffset
      y = bi.y - bi.p.value.topoffset
      w = bi.p.value.width
      h = bi.p.value.height

      if y - Doocr::ST_Y < 0
        CDoom.i_error("Error: stlib_update_bin_icon: y - Doocr::ST_Y < 0")
      end

      if bi.val.value != 0
        CDoom.v_draw_patch(bi.x, bi.y, Doocr::STLIB_FG, bi.p)
      else
        CDoom.v_copy_rect(x, y - Doocr::ST_Y, Doocr::STLIB_BG, w, h, x, y, Doocr::STLIB_FG)
      end

      bi.oldval = bi.val.value
    end
  end

  #
  # STATUS BAR CODE
  #

  def self.st_refresh_background
    if Doocr.st_statusbaron != 0
      CDoom.v_draw_patch(Doocr::ST_X, 0, Doocr::STLIB_BG, Doocr.sbar)

      CDoom.v_draw_patch(Doocr::ST_FX, 0, Doocr::STLIB_BG, Doocr.faceback) if Doocr.netgame != 0

      CDoom.v_copy_rect(Doocr::ST_X, 0, Doocr::STLIB_BG, Doocr::ST_WIDTH, Doocr::ST_HEIGHT, Doocr::ST_X, Doocr::ST_Y, Doocr::STLIB_FG)
    end
  end

  @@buf = Pointer(UInt8).malloc(Doocr::ST_MSGWIDTH)

  # Respond to keyboard input events,
  #  intercept cheats.
  def self.st_responder(ev : Doocr::Event) : LibC::Int
    # Filter automap on/off.
     if ev.type == Doocr::Evtype::Keyup &&
       (ev.data1 & 0xffff0000) == Doocr::AM_MSGHEADER
      case ev.data1
      when Doocr::AM_MSGENTERED
        Doocr.st_gamestate = Doocr::ST_Statenum::AutomapState
        Doocr.st_firsttime = 1
      when Doocr::AM_MSGEXITED
        Doocr.st_gamestate = Doocr::ST_Statenum::FirstPersonState
      end

      # if a user keypress...
    elsif ev.type == Doocr::Evtype::Keydown
      if Doocr.netgame == 0
        # 'clev' change-level cheat
        if Doocr.cht_check_cheat(Doocr.cheat_clev, ev.data1.to_u8!) != 0
          buf = Pointer(UInt8).malloc(3)

          Doocr.cht_get_param(Doocr.cheat_clev, buf)

          return 0 if (buf[0] < '0'.ord || buf[0] > '9'.ord) ||
                      (buf[1] < '0'.ord || buf[1] > '9'.ord)

          if Doocr.gamemode == Doocr::GameMode::Commercial
            epsd = 0
            map = (buf[0] - '0'.ord) * 10 + buf[1] - '0'.ord
          else
            epsd = buf[0] - '0'.ord
            map = buf[1] - '0'.ord
          end

          # Catch invalid maps
          return 0 if Doocr.gamemode != Doocr::GameMode::Commercial && epsd < 1

          return 0 if map < 1

          # Ohmygod - this is not going to work.
          return 0 if Doocr.gamemode == Doocr::GameMode::Retail &&
                      (epsd > 4 || map > 9)

          return 0 if Doocr.gamemode == Doocr::GameMode::Registered &&
                      (epsd > 3 || map > 9)

          return 0 if Doocr.gamemode == Doocr::GameMode::Shareware &&
                      (epsd > 1 || map > 9)

          return 0 if Doocr.gamemode == Doocr::GameMode::Commercial &&
                      map > 32

          # So be it.
          Doocr.plyr.not_nil!.message = @@deh_ststr_clev
          CDoom.g_defered_init_new(Doocr.gameskill, epsd, map)
        end

        return 0 if Doocr.gameskill == Doocr::Skill::Nightmare

        # my little cheat
        if Doocr.cht_check_cheat(Doocr.cheat_me, ev.data1.to_u8) != 0
          Doocr.plyr.value.cheats = Doocr.plyr.value.cheats ^ Doocr::Cheat::CF_ME.value
          Doocr.plyr.value.message = "#{(Doocr.plyr.value.cheats & Doocr::Cheat::CF_ME.value != 0 ? "yea" : "no")} baby!"
          if Doocr.plyr.value.cheats & Doocr::Cheat::CF_ME.value != 0
            if Doocr.plyr.value.backpack == 0
              Doocr::Ammotype::NUMAMMO.value.times do |i|
                Doocr.plyr.value.maxammo[i] = Doocr.plyr.value.maxammo[i] * 2
              end
              Doocr.plyr.value.backpack = 1
            end
            Doocr::Ammotype::NUMAMMO.value.times do |i|
              Doocr.plyr.value.ammo[i] = Doocr.plyr.value.maxammo[i]
            end
          end
        end

        # 'dqd' cheat of toggleable god mode
        if Doocr.cht_check_cheat(Doocr.cheat_god, ev.data1.to_u8!) != 0
          Doocr.plyr.value.cheats = Doocr.plyr.value.cheats ^ Doocr::Cheat::CF_GODMODE.value
          if Doocr.plyr.value.cheats & Doocr::Cheat::CF_GODMODE.value != 0
            Doocr.plyr.value.mo.not_nil!.health = @@deh_god_mode_health if Doocr.plyr.value.mo

            Doocr.plyr.value.health = @@deh_god_mode_health
            Doocr.plyr.value.message = @@deh_ststr_dqdon
          else
            Doocr.plyr.value.message = @@deh_ststr_dqdoff
          end

          # 'fa' cheat for killer fucking arsenal
        elsif Doocr.cht_check_cheat(Doocr.cheat_ammonokey, ev.data1.to_u8!) != 0
          Doocr.plyr.value.armorpoints = @@deh_idfa_armor
          Doocr.plyr.value.armortype = @@deh_idfa_armor_class

          Doocr::Weapontype::NUMWEAPONS.value.times { |i| Doocr.plyr.value.weaponowned[i] = 1 }

          Doocr::Ammotype::NUMAMMO.value.times { |i| Doocr.plyr.value.ammo[i] = Doocr.plyr.value.maxammo[i] }

          Doocr.plyr.value.message = @@deh_ststr_faadded

          # 'kfa' cheat for key full ammo
        elsif Doocr.cht_check_cheat(Doocr.cheat_ammo, ev.data1.to_u8!) != 0
          Doocr.plyr.value.armorpoints = @@deh_idkfa_armor
          Doocr.plyr.value.armortype = @@deh_idkfa_armor_class

          Doocr::Weapontype::NUMWEAPONS.value.times { |i| Doocr.plyr.value.weaponowned[i] = 1 }

          Doocr::Ammotype::NUMAMMO.value.times { |i| Doocr.plyr.value.ammo[i] = Doocr.plyr.value.maxammo[i] }

          Doocr::Card::NUMCARDS.value.times { |i| Doocr.plyr.value.cards[i] = 1 }

          Doocr.plyr.value.message = @@deh_ststr_kfaadded

          # 'mus' cheat for changing music
        elsif Doocr.cht_check_cheat(Doocr.cheat_mus, ev.data1.to_u8!) != 0
          buf = Pointer(UInt8).malloc(3)

          Doocr.cht_get_param(Doocr.cheat_mus, buf)

          return 0 if (buf[0] < '0'.ord || buf[0] > '9'.ord) ||
                      (buf[1] < '0'.ord || buf[1] > '9'.ord)

          Doocr.plyr.value.message = @@deh_ststr_mus

          if Doocr.gamemode == Doocr::GameMode::Commercial
            map = ((buf[0] - '0'.ord) * 10 + buf[1] - '0'.ord) &- 1
            musnum = Doocr::Musicenum::MUS_runnin.value + map

            if map > 31
              Doocr.plyr.value.message = @@deh_ststr_nomus
            else
              Doocr.s_change_music(musnum, 1)
            end
          else
            e = (buf[0] &- '1'.ord)
            m = (buf[1] &- '1'.ord)

            if m > 8 || (e > 3 && Doocr.gamemode == Doocr::GameMode::Retail) ||
               (e > 2 && Doocr.gamemode == Doocr::GameMode::Registered) ||
               (e > 0 && Doocr.gamemode == Doocr::GameMode::Shareware)
              Doocr.plyr.value.message = @@deh_ststr_nomus
            else
              mus = Doocr.gamemode == Doocr::GameMode::Retail ? @@regmus[m].value : Doocr::Musicenum::MUS_e1m1.value + e * 9 + m
              Doocr.s_change_music(mus, 1)
            end
          end

          # Simplified, accepting both "noclip" and "idspispopd".
          # no clipping mode cheat
                elsif Doocr.cht_check_cheat(Doocr.cheat_noclip, ev.data1.to_u8!) != 0 ||
                  Doocr.cht_check_cheat(Doocr.cheat_commercial_noclip, ev.data1.to_u8!) != 0
          Doocr.plyr.value.cheats = Doocr.plyr.value.cheats ^ Doocr::Cheat::CF_NOCLIP.value

          if Doocr.plyr.value.cheats & Doocr::Cheat::CF_NOCLIP.value != 0
            Doocr.plyr.value.message = @@deh_ststr_ncon
          else
            Doocr.plyr.value.message = @@deh_ststr_ncoff
          end
        end

        # 'behold?' power-up cheats
        6.times do |i|
          if Doocr.cht_check_cheat(Doocr.cheat_powerup[i], ev.data1.to_u8!) != 0
            if Doocr.plyr.value.powers[i] == 0
              Doocr.p_give_power(Doocr.plyr.not_nil!, i)
            elsif i != Doocr::Powertype::Strength.value
              Doocr.plyr.value.powers[i] = 1
            else
              Doocr.plyr.value.powers[i] = 0
            end

            Doocr.plyr.value.message = @@deh_ststr_beholdx
          end
        end

        # 'behold' power-up menu
        if Doocr.cht_check_cheat(Doocr.cheat_powerup[6], ev.data1.to_u8!) != 0
          Doocr.plyr.value.message = @@deh_ststr_behold

          # 'choppers' invulnerability & chainsaw
        elsif Doocr.cht_check_cheat(Doocr.cheat_choppers, ev.data1.to_u8!) != 0
          Doocr.plyr.value.weaponowned[Doocr::Weapontype::Chainsaw.value] = 1
          Doocr.plyr.value.powers[Doocr::Powertype::Invulnerability.value] = 1
          Doocr.plyr.value.message = @@deh_ststr_choppers

          # 'mypos' for player position
        elsif Doocr.cht_check_cheat(Doocr.cheat_mypos, ev.data1.to_u8!) != 0
          CDoom.doom_strcpy(@@buf, "ang=0x")
          CDoom.doom_concat(@@buf, CDoom.doom_itoa(@@players[Doocr.consoleplayer].mo.not_nil!.angle, 16))
          CDoom.doom_concat(@@buf, ";x,y=(0x")
          CDoom.doom_concat(@@buf, CDoom.doom_itoa(@@players[Doocr.consoleplayer].mo.not_nil!.x, 16))
          CDoom.doom_concat(@@buf, ",0x")
          CDoom.doom_concat(@@buf, CDoom.doom_itoa(@@players[Doocr.consoleplayer].mo.not_nil!.y, 16))
          CDoom.doom_concat(@@buf, ")")
          Doocr.plyr.value.message = String.new(@@buf)
        end
      end
    end
    return 0
  end

  @@lastcalc = 0
  @@oldhealth = -1

  def self.st_calc_pain_offset : LibC::Int
    health = Doocr.plyr.value.health > 100 ? 100 : Doocr.plyr.value.health

    if health != @@oldhealth
      @@lastcalc = Doocr::ST_FACESTRIDE * (((100 - health) * Doocr::ST_NUMPAINFACES) // 101)
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
      if Doocr.plyr.value.health == 0
        @@priority = 9
        Doocr.st_faceindex = Doocr::ST_DEADFACE
        Doocr.st_facecount = 1
      end
    end

    if @@priority < 9
      if Doocr.plyr.value.bonuscount != 0
        # picking up bonuse
        doevilgrin = false

        Doocr::Weapontype::NUMWEAPONS.value.times do |i|
          if Doocr.oldweaponsowned[i] != Doocr.plyr.value.weaponowned[i]
            doevilgrin = true
            Doocr.oldweaponsowned[i] = Doocr.plyr.value.weaponowned[i]
          end
        end
        if doevilgrin
          # evil grin if just picked up weapon
          @@priority = 8
          Doocr.st_facecount = Doocr::ST_EVILGRINCOUNT
          Doocr.st_faceindex = CDoom.st_calc_pain_offset + Doocr::ST_EVILGRINOFFSET
        end
      end
    end

    if @@priority < 8
      if Doocr.plyr.value.damagecount != 0 &&
         !Doocr.plyr.value.attacker.null? &&
         Doocr.plyr.value.attacker != Doocr.plyr.value.mo
        # being attacked
        @@priority = 7

        if Doocr.plyr.value.health - Doocr.st_oldhealth > Doocr::ST_MUCHPAIN
          Doocr.st_facecount = Doocr::ST_TURNCOUNT
          Doocr.st_faceindex = CDoom.st_calc_pain_offset + Doocr::ST_OUCHOFFSET
        else
          badguyangle = CDoom.r_point_to_angle2(Doocr.plyr.value.mo.value.x,
            Doocr.plyr.value.mo.value.y,
            Doocr.plyr.value.attacker.value.x,
            Doocr.plyr.value.attacker.value.y)

          if badguyangle > Doocr.plyr.value.mo.value.angle
            # whether right or left
            diffang = badguyangle &- Doocr.plyr.value.mo.value.angle
            i = diffang > ANG180
          else
            # whether left or right
            diffang = Doocr.plyr.value.mo.value.angle &- badguyangle
            i = diffang <= ANG180
          end # confusing, aint it?

          Doocr.st_facecount = Doocr::ST_TURNCOUNT
          Doocr.st_faceindex = CDoom.st_calc_pain_offset

          if diffang < ANG45
            # head-on
            Doocr.st_faceindex += Doocr::ST_RAMPAGEOFFSET
          elsif i
            # turn face right
            Doocr.st_faceindex += Doocr::ST_TURNOFFSET
          else
            # turn face left
            Doocr.st_faceindex += Doocr::ST_TURNOFFSET + 1
          end
        end
      end
    end

    if @@priority < 7
      # getting hurt because of your own damn stupidity
      if Doocr.plyr.value.damagecount != 0
        if Doocr.plyr.value.health - Doocr.st_oldhealth > Doocr::ST_MUCHPAIN
          @@priority = 7
          Doocr.st_facecount = Doocr::ST_TURNCOUNT
          Doocr.st_faceindex = CDoom.st_calc_pain_offset + Doocr::ST_OUCHOFFSET
        else
          @@priority = 6
          Doocr.st_facecount = Doocr::ST_TURNCOUNT
          Doocr.st_faceindex = CDoom.st_calc_pain_offset + Doocr::ST_RAMPAGEOFFSET
        end
      end
    end

    if @@priority < 6
      # rapid firing
      if Doocr.plyr.value.attackdown != 0
        if @@lastattackdown == -1
          @@lastattackdown = Doocr::ST_RAMPAGEDELAY
        elsif (@@lastattackdown -= 1) == 0
          @@priority = 5
          Doocr.st_faceindex = CDoom.st_calc_pain_offset + Doocr::ST_RAMPAGEOFFSET
          Doocr.st_facecount = 1
          @@lastattackdown = 1
        end
      else
        @@lastattackdown = -1
      end
    end

    if @@priority < 5
      # invulnerability
      if Doocr.plyr.value.cheats & Doocr::Cheat::CF_GODMODE.value != 0 ||
         Doocr.plyr.value.powers[Doocr::Powertype::Invulnerability.value] != 0
        @@priority = 4

        Doocr.st_faceindex = Doocr::ST_GODFACE
        Doocr.st_facecount = 1
      end
    end

    # look left or look right if the facecount has timed out
    if Doocr.st_facecount == 0
      Doocr.st_faceindex = CDoom.st_calc_pain_offset + (Doocr.st_randomnumber % 3)
      Doocr.st_facecount = Doocr::ST_STRAIGHTFACECOUNT.to_i32!
      @@priority = 0
    end

    Doocr.st_facecount -= 1
  end

  @@largeammo = 1994 # means "n/a"

  def self.st_update_widgets
    if Doocr.weaponinfo[Doocr.plyr.value.readyweapon.value].ammo == Doocr::Ammotype::Noammo
      Doocr.w_ready[0].num = pointerof(@@largeammo)
    else
      Doocr.w_ready[0].num = Doocr.plyr.value.ammo.to_unsafe + Doocr.weaponinfo[Doocr.plyr.value.readyweapon.value].ammo.value
    end

    Doocr.w_ready[0].data = Doocr.plyr.value.readyweapon.value

    # update keycard multiple widgets
    3.times do |i|
      Doocr.keyboxes[i] = Doocr.plyr.value.cards[i] != 0 ? i : -1

      Doocr.keyboxes[i] = i + 3 if Doocr.plyr.value.cards[i + 3] != 0
    end

    # refresh everything if this is him coming back to life
    CDoom.st_update_face_widget

    # used by the w_armsbg widget
    Doocr.st_notdeathmatch = (Doocr.deathmatch == 0).to_unsafe

    # used by w_arms[] widgets
    Doocr.st_armson = (Doocr.st_statusbaron != 0 && Doocr.deathmatch == 0).to_unsafe

    # used by w_frags widget
    Doocr.st_fragson = (Doocr.deathmatch != 0 && Doocr.st_statusbaron != 0).to_unsafe
    Doocr.st_fragscount = 0

    CDoom::MAXPLAYERS.times do |i|
      if i != Doocr.consoleplayer
        Doocr.st_fragscount += Doocr.plyr.value.frags[i]
      else
        Doocr.st_fragscount -= Doocr.plyr.value.frags[i]
      end
    end

    # get rid of chat window if up because of message
    Doocr.st_chat = Doocr.st_oldchat if (Doocr.st_msgcounter -= 1) == 0
  end

  def self.st_ticker
    Doocr.st_clock += 1
    Doocr.st_randomnumber = CDoom.m_random
    CDoom.st_update_widgets
    Doocr.st_oldhealth = Doocr.plyr.value.health
  end

  def self.st_do_palette_stuff
    cnt = Doocr.plyr.value.damagecount

    if Doocr.plyr.value.powers[Doocr::Powertype::Strength.value] != 0
      # slowly fade the berzerk out
      bzc = 12 - (Doocr.plyr.value.powers[Doocr::Powertype::Strength.value] >> 6)

      cnt = bzc if bzc > cnt
    end

    if cnt != 0
      palette = (cnt + 7) >> 3

      palette = Doocr::NUMREDPALS - 1 if palette >= Doocr::NUMREDPALS

      palette += Doocr::STARTREDPALS
    elsif Doocr.plyr.value.bonuscount != 0
      palette = (Doocr.plyr.value.bonuscount + 7) >> 3

      palette = Doocr::NUMBONUSPALS - 1 if palette >= Doocr::NUMBONUSPALS

      palette += Doocr::STARTBONUSPALS
    elsif Doocr.plyr.value.powers[Doocr::Powertype::Ironfeet.value] > 4 * 32 ||
          Doocr.plyr.value.powers[Doocr::Powertype::Ironfeet.value] & 8 != 0
      palette = Doocr::RADIATIONPAL
    else
      palette = 0
    end

    if palette != Doocr.st_palette
      Doocr.st_palette = palette
      pal = CDoom.w_cache_lump_num(Doocr.lu_palette, Doocr::PU_CACHE).as(UInt8*) + palette * 768
      CDoom.i_set_palette(pal)
    end
  end

  def self.st_draw_widgets(refresh : LibC::Int)
    # used by w_arms[] idgets
    Doocr.st_armson = (Doocr.st_statusbaron != 0 && Doocr.deathmatch == 0).to_unsafe

    # used by w_frags widget
    Doocr.st_fragson = (Doocr.deathmatch != 0 && Doocr.st_statusbaron != 0).to_unsafe

    Doocr.stlib_update_num(Doocr.w_ready[0], refresh)

    4.times do |i|
      Doocr.stlib_update_num(Doocr.w_ammo[i], refresh)
      Doocr.stlib_update_num(Doocr.w_maxammo[i], refresh)
    end

    Doocr.stlib_update_percent(Doocr.w_health[0], refresh)
    Doocr.stlib_update_percent(Doocr.w_armor[0], refresh)

    Doocr.stlib_update_bin_icon(Doocr.w_armsbg[0], refresh)

    6.times { |i| Doocr.stlib_update_mult_icon(Doocr.w_arms[i], refresh) }

    Doocr.stlib_update_mult_icon(Doocr.w_faces[0], refresh)

    3.times { |i| Doocr.stlib_update_mult_icon(Doocr.w_keyboxes[i], refresh) }

    Doocr.stlib_update_num(Doocr.w_frags[0], refresh)
  end

  def self.st_do_refresh
    Doocr.st_firsttime = 0

    # draw status bar background to off-screen buff
    CDoom.st_refresh_background

    # and refresh all widgets
    CDoom.st_draw_widgets(true)
  end

  def self.st_diff_draw
    # update all widgets
    CDoom.st_draw_widgets(0)
  end

  def self.st_drawer(fullscreen : LibC::Int, refresh : LibC::Int)
    Doocr.st_statusbaron = (fullscreen == 0 || Doocr.automapactive != 0).to_unsafe
    Doocr.st_firsttime = (Doocr.st_firsttime != 0 || refresh != 0).to_unsafe

    # Do red-/gold-shifts from damage/items
    CDoom.st_do_palette_stuff

    # If just after st_start(), refresh all
    if Doocr.st_firsttime != 0
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
      Doocr.tallnum[i] = CDoom.w_cache_lump_name(namebuf, Doocr::PU_STATIC).as(CDoom::Patch*)

      CDoom.doom_strcpy(namebuf, "STYSNUM")
      CDoom.doom_concat(namebuf, CDoom.doom_itoa(i, 10))
      Doocr.shortnum[i] = CDoom.w_cache_lump_name(namebuf, Doocr::PU_STATIC).as(CDoom::Patch*)
    end

    # Load percent key.
    # Note: why not load STMINUS here, too?
    Doocr.tallpercent = CDoom.w_cache_lump_name("STTPRCNT", Doocr::PU_STATIC).as(CDoom::Patch*)

    # key card
    Doocr::Card::NUMCARDS.value.times do |i|
      CDoom.doom_strcpy(namebuf, "STKEYS")
      CDoom.doom_concat(namebuf, CDoom.doom_itoa(i, 10))
      Doocr.keys[i] = CDoom.w_cache_lump_name(namebuf, Doocr::PU_STATIC).as(CDoom::Patch*)
    end

    # arms background
    Doocr.armsbg = CDoom.w_cache_lump_name("STARMS", Doocr::PU_STATIC).as(CDoom::Patch*)

    # arms ownership widgets
    6.times do |i|
      CDoom.doom_strcpy(namebuf, "STGNUM")
      CDoom.doom_concat(namebuf, CDoom.doom_itoa(i + 2, 10))

      # gray #
      Doocr.arms[i][0] = CDoom.w_cache_lump_name(namebuf, Doocr::PU_STATIC).as(CDoom::Patch*)

      # yellow #
      Doocr.arms[i][1] = Doocr.shortnum[i + 2]
    end

    # face backgrounds for different color players
    CDoom.doom_strcpy(namebuf, "STFB")
    CDoom.doom_concat(namebuf, CDoom.doom_itoa(Doocr.consoleplayer, 10))
    Doocr.faceback = CDoom.w_cache_lump_name(namebuf, Doocr::PU_STATIC).as(CDoom::Patch*)

    # status bar background bits
    Doocr.sbar = CDoom.w_cache_lump_name("STBAR", Doocr::PU_STATIC).as(CDoom::Patch*)

    # face states
    facenum = 0
    Doocr::ST_NUMPAINFACES.times do |i|
      Doocr::ST_NUMSTRAIGHTFACES.times do |j|
        CDoom.doom_strcpy(namebuf, "STFST")
        CDoom.doom_concat(namebuf, CDoom.doom_itoa(i, 10))
        CDoom.doom_concat(namebuf, CDoom.doom_itoa(j, 10))
        Doocr.faces[facenum] = CDoom.w_cache_lump_name(namebuf, Doocr::PU_STATIC).as(CDoom::Patch*)
        facenum += 1
      end
      CDoom.doom_strcpy(namebuf, "STFTR")
      CDoom.doom_concat(namebuf, CDoom.doom_itoa(i, 10))
      CDoom.doom_concat(namebuf, "0")
      Doocr.faces[facenum] = CDoom.w_cache_lump_name(namebuf, Doocr::PU_STATIC).as(CDoom::Patch*)
      facenum += 1

      CDoom.doom_strcpy(namebuf, "STFTL")
      CDoom.doom_concat(namebuf, CDoom.doom_itoa(i, 10))
      CDoom.doom_concat(namebuf, "0")
      Doocr.faces[facenum] = CDoom.w_cache_lump_name(namebuf, Doocr::PU_STATIC).as(CDoom::Patch*)
      facenum += 1

      CDoom.doom_strcpy(namebuf, "STFOUCH")
      CDoom.doom_concat(namebuf, CDoom.doom_itoa(i, 10))
      Doocr.faces[facenum] = CDoom.w_cache_lump_name(namebuf, Doocr::PU_STATIC).as(CDoom::Patch*)
      facenum += 1

      CDoom.doom_strcpy(namebuf, "STFEVL")
      CDoom.doom_concat(namebuf, CDoom.doom_itoa(i, 10))
      Doocr.faces[facenum] = CDoom.w_cache_lump_name(namebuf, Doocr::PU_STATIC).as(CDoom::Patch*)
      facenum += 1

      CDoom.doom_strcpy(namebuf, "STFKILL")
      CDoom.doom_concat(namebuf, CDoom.doom_itoa(i, 10))
      Doocr.faces[facenum] = CDoom.w_cache_lump_name(namebuf, Doocr::PU_STATIC).as(CDoom::Patch*)
      facenum += 1
    end
    Doocr.faces[facenum] = CDoom.w_cache_lump_name("STFGOD0", Doocr::PU_STATIC).as(CDoom::Patch*)
    facenum += 1
    Doocr.faces[facenum] = CDoom.w_cache_lump_name("STFDEAD0", Doocr::PU_STATIC).as(CDoom::Patch*)
    facenum += 1
  end

  def self.st_load_data
    Doocr.lu_palette = CDoom.w_get_num_for_name("PLAYPAL")
    CDoom.st_load_graphics
  end

  def self.st_unload_graphics
    # unload the numbers, tall and short
    10.times do |i|
      z_change_tag(Doocr.tallnum[i], Doocr::PU_CACHE)
      z_change_tag(Doocr.shortnum[i], Doocr::PU_CACHE)
    end
    # unload tall percent
    z_change_tag(Doocr.tallpercent, Doocr::PU_CACHE)

    # unload arms background
    z_change_tag(Doocr.armsbg, Doocr::PU_CACHE)

    # unload gray #'s
    6.times { |i| z_change_tag(Doocr.arms[i][0], Doocr::PU_CACHE) }

    # unload the key cards
    Doocr::Card::NUMCARDS.value.times { |i| z_change_tag(Doocr.keys[i], Doocr::PU_CACHE) }

    z_change_tag(Doocr.sbar, Doocr::PU_CACHE)
    z_change_tag(Doocr.faceback, Doocr::PU_CACHE)

    Doocr::ST_NUMFACES.times { |i| z_change_tag(Doocr.faces[i], Doocr::PU_CACHE) }

    # Note: nobody ain't seen no unloading
    #   of stminus yet. Dude.
  end

  def self.st_unload_data
    CDoom.st_unload_graphics
  end

  def self.st_init_data
    Doocr.st_firsttime = 1
    Doocr.plyr = @@players.to_unsafe + Doocr.consoleplayer

    Doocr.st_clock = 0
    Doocr.st_chatstate = Doocr::ST_Chatstateenum::StartChatState
    Doocr.st_gamestate = Doocr::ST_Statenum::FirstPersonState

    Doocr.st_statusbaron = 1
    Doocr.st_oldchat = 0
    Doocr.st_chat = 0
    Doocr.st_cursoron = 0

    Doocr.st_faceindex = 0
    Doocr.st_palette = -1

    Doocr.st_oldhealth = -1

    Doocr::Weapontype::NUMWEAPONS.value.times do |i|
      Doocr.oldweaponsowned[i] = Doocr.plyr.value.weaponowned[i]
    end

    3.times { |i| Doocr.keyboxes[i] = -1 }

    Doocr.stlib_init
  end

  def self.st_create_widgets
    # ready weapon ammo
    Doocr.stlib_init_num(Doocr.w_ready[0],
      Doocr::ST_AMMOX,
      Doocr::ST_AMMOY,
      Doocr.tallnum.to_unsafe.as(CDoom::Patch**),
      Doocr.plyr.value.ammo.to_unsafe + Doocr.weaponinfo[Doocr.plyr.value.readyweapon.value].ammo.value,
      Doocr.st_statusbaron_ptr,
      Doocr::ST_AMMOWIDTH)

    # the last weapon type
    Doocr.w_ready[0].data = Doocr.plyr.value.readyweapon.value

    # health percentage
    Doocr.stlib_init_percent(Doocr.w_health[0],
      Doocr::ST_HEALTHX,
      Doocr::ST_HEALTHY,
      Doocr.tallnum.to_unsafe.as(CDoom::Patch**),
      pointerof(Doocr.plyr.value.@health),
      Doocr.st_statusbaron_ptr,
      Doocr.tallpercent)

    # arms background
    Doocr.stlib_init_bin_icon(Doocr.w_armsbg[0],
      Doocr::ST_ARMSBGX,
      Doocr::ST_ARMSBGY,
      Doocr.armsbg,
      Doocr.st_notdeathmatch_ptr,
      Doocr.st_statusbaron_ptr)

    # weapons owned
    6.times do |i|
      Doocr.stlib_init_mult_icon(Doocr.w_arms[i],
        Doocr::ST_ARMSX + (i % 3) * Doocr::ST_ARMSXSPACE,
        Doocr::ST_ARMSY + (i // 3) * Doocr::ST_ARMSYSPACE,
        Doocr.arms[i].to_unsafe,
        Doocr.plyr.value.weaponowned.to_unsafe + (i + 1),
        Doocr.st_armson_ptr)
    end

    # frags sum
    Doocr.stlib_init_num(Doocr.w_frags[0],
      Doocr::ST_FRAGSX,
      Doocr::ST_FRAGSY,
      Doocr.tallnum.to_unsafe.as(CDoom::Patch**),
      Doocr.st_fragscount_ptr,
      Doocr.st_fragson_ptr,
      Doocr::ST_FRAGSWIDTH)

    # faces
    Doocr.stlib_init_mult_icon(Doocr.w_faces[0],
      Doocr::ST_FACESX,
      Doocr::ST_FACESY,
      Doocr.faces.to_unsafe.as(CDoom::Patch**),
      Doocr.st_faceindex_ptr,
      Doocr.st_statusbaron_ptr)

    # armor percentage - should be colored later
    Doocr.stlib_init_percent(Doocr.w_armor[0],
      Doocr::ST_ARMORX,
      Doocr::ST_ARMORY,
      Doocr.tallnum.to_unsafe.as(CDoom::Patch**),
      pointerof(Doocr.plyr.value.@armorpoints),
      Doocr.st_statusbaron_ptr,
      Doocr.tallpercent)

    # keyboxes 0-2
    Doocr.stlib_init_mult_icon(Doocr.w_keyboxes[0],
      Doocr::ST_KEY0X,
      Doocr::ST_KEY0Y,
      Doocr.keys.to_unsafe.as(CDoom::Patch**),
      Doocr.keyboxes.to_unsafe,
      Doocr.st_statusbaron_ptr)

    Doocr.stlib_init_mult_icon(Doocr.w_keyboxes[1],
      Doocr::ST_KEY1X,
      Doocr::ST_KEY1Y,
      Doocr.keys.to_unsafe.as(CDoom::Patch**),
      Doocr.keyboxes.to_unsafe + 1,
      Doocr.st_statusbaron_ptr)

    Doocr.stlib_init_mult_icon(Doocr.w_keyboxes[2],
      Doocr::ST_KEY2X,
      Doocr::ST_KEY2Y,
      Doocr.keys.to_unsafe.as(CDoom::Patch**),
      Doocr.keyboxes.to_unsafe + 2,
      Doocr.st_statusbaron_ptr)

    # ammo count (all four kinds)
    Doocr.stlib_init_num(Doocr.w_ammo[0],
      Doocr::ST_AMMO0X,
      Doocr::ST_AMMO0Y,
      Doocr.shortnum.to_unsafe.as(CDoom::Patch**),
      Doocr.plyr.value.ammo.to_unsafe,
      Doocr.st_statusbaron_ptr,
      Doocr::ST_AMMO0WIDTH)

    Doocr.stlib_init_num(Doocr.w_ammo[1],
      Doocr::ST_AMMO1X,
      Doocr::ST_AMMO1Y,
      Doocr.shortnum.to_unsafe.as(CDoom::Patch**),
      Doocr.plyr.value.ammo.to_unsafe + 1,
      Doocr.st_statusbaron_ptr,
      Doocr::ST_AMMO1WIDTH)

    Doocr.stlib_init_num(Doocr.w_ammo[2],
      Doocr::ST_AMMO2X,
      Doocr::ST_AMMO2Y,
      Doocr.shortnum.to_unsafe.as(CDoom::Patch**),
      Doocr.plyr.value.ammo.to_unsafe + 2,
      Doocr.st_statusbaron_ptr,
      Doocr::ST_AMMO2WIDTH)

    Doocr.stlib_init_num(Doocr.w_ammo[3],
      Doocr::ST_AMMO3X,
      Doocr::ST_AMMO3Y,
      Doocr.shortnum.to_unsafe.as(CDoom::Patch**),
      Doocr.plyr.value.ammo.to_unsafe + 3,
      Doocr.st_statusbaron_ptr,
      Doocr::ST_AMMO3WIDTH)

    # max ammo count (all four kinds)
    Doocr.stlib_init_num(Doocr.w_maxammo[0],
      Doocr::ST_MAXAMMO0X,
      Doocr::ST_MAXAMMO0Y,
      Doocr.shortnum.to_unsafe.as(CDoom::Patch**),
      Doocr.plyr.value.maxammo.to_unsafe,
      Doocr.st_statusbaron_ptr,
      Doocr::ST_MAXAMMO0WIDTH)

    Doocr.stlib_init_num(Doocr.w_maxammo[1],
      Doocr::ST_MAXAMMO1X,
      Doocr::ST_MAXAMMO1Y,
      Doocr.shortnum.to_unsafe.as(CDoom::Patch**),
      Doocr.plyr.value.maxammo.to_unsafe + 1,
      Doocr.st_statusbaron_ptr,
      Doocr::ST_MAXAMMO1WIDTH)

    Doocr.stlib_init_num(Doocr.w_maxammo[2],
      Doocr::ST_MAXAMMO2X,
      Doocr::ST_MAXAMMO2Y,
      Doocr.shortnum.to_unsafe.as(CDoom::Patch**),
      Doocr.plyr.value.maxammo.to_unsafe + 2,
      Doocr.st_statusbaron_ptr,
      Doocr::ST_MAXAMMO2WIDTH)

    Doocr.stlib_init_num(Doocr.w_maxammo[3],
      Doocr::ST_MAXAMMO3X,
      Doocr::ST_MAXAMMO3Y,
      Doocr.shortnum.to_unsafe.as(CDoom::Patch**),
      Doocr.plyr.value.maxammo.to_unsafe + 3,
      Doocr.st_statusbaron_ptr,
      Doocr::ST_MAXAMMO3WIDTH)
  end

  def self.st_start
    CDoom.st_stop if Doocr.st_stopped == 0

    CDoom.st_init_data
    CDoom.st_create_widgets
    Doocr.st_stopped = 0
  end

  def self.st_stop
    return if Doocr.st_stopped != 0

    CDoom.i_set_palette(CDoom.w_cache_lump_num(Doocr.lu_palette, Doocr::PU_CACHE).as(UInt8*))

    Doocr.st_stopped = 1
  end

  def self.st_init
    Doocr.veryfirsttime = 0
    CDoom.st_load_data
    Doocr.screens[4] = CDoom.z_malloc(CDoom::SCREENWIDTH * CDoom::SCREENHEIGHT, Doocr::PU_STATIC, Pointer(Void).null).as(UInt8*)
  end
end
