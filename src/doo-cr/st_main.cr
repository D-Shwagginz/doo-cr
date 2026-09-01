module Doocr
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

        # 'clev' change-level cheat
        if CDoom.cht_check_cheat(pointerof(CDoom.cheat_clev), ev.value.data1) != 0
          buf = Pointer(UInt8).malloc(3)

          CDoom.cht_get_param(pointerof(CDoom.cheat_clev), buf)

          return 0 if (buf[0] < '0'.ord || buf[0] > '9'.ord) ||
          (buf[1] < '0'.ord || buf[1] > '9'.ord)

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
        
        return 0 if CDoom.gameskill == CDoom::Skill::Nightmare

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

          CDoom.cht_get_param(pointerof(CDoom.cheat_mus), buf)

          return 0 if (buf[0] < '0'.ord || buf[0] > '9'.ord) ||
          (buf[1] < '0'.ord || buf[1] > '9'.ord)
          
          CDoom.plyr.value.message = @@deh_ststr_mus


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
end
