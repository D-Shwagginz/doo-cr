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
# ==> Intermission screen

module Doocr
  def self.wi_slam_background
    CDoom.doom_memcpy(Doocr.screens[0], Doocr.screens[1], CDoom::SCREENWIDTH * CDoom::SCREENHEIGHT)
    CDoom.v_mark_rect(0, 0, CDoom::SCREENWIDTH, CDoom::SCREENHEIGHT)
  end

  #
  # Draws "<Levelname> Finished!"
  #
  def self.wi_draw_lf
    y = Doocr::WI_TITLEY

    # draw <LevelName>
    CDoom.v_draw_patch((CDoom::SCREENWIDTH - Doocr.lnames[@@wbs.last].value.width) // 2,
      y, Doocr::FB, Doocr.lnames[@@wbs.last])

    # draw "Finished!"
    y += (5 * Doocr.lnames[@@wbs.last].value.height) // 4

    CDoom.v_draw_patch((CDoom::SCREENWIDTH - Doocr.finished.value.width) // 2,
      y, Doocr::FB, Doocr.finished)
  end

  #
  # Draws "Entering <LevelName>"
  #
  def self.wi_draw_el
    y = Doocr::WI_TITLEY

    # draw "Entering"
    CDoom.v_draw_patch((CDoom::SCREENWIDTH - Doocr.entering.value.width) // 2,
      y, Doocr::FB, Doocr.entering)

    # draw level
    y += (5 * Doocr.lnames[@@wbs.next].value.height) // 4

    CDoom.v_draw_patch((CDoom::SCREENWIDTH - Doocr.lnames[@@wbs.next].value.width) // 2,
      y, Doocr::FB, Doocr.lnames[@@wbs.next])
  end

  def self.wi_draw_on_lnode(n : LibC::Int, c : CDoom::Patch**)
    fits = false

    i = 0
    loop do
      left = @@lnodes[@@wbs.epsd][n].x - c[i].value.leftoffset
      top = @@lnodes[@@wbs.epsd][n].y - c[i].value.topoffset
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
      CDoom.v_draw_patch(@@lnodes[@@wbs.epsd][n].x,
        @@lnodes[@@wbs.epsd][n].y,
        Doocr::FB, c[i])
    else
      # DEBUG
      puts "Could not place patch on level #{n + 1}"
    end
  end

  def self.wi_init_animated_back
    return if Doocr.gamemode == Doocr::GameMode::Commercial

    return if @@wbs.epsd > 2

    @@numanims[@@wbs.epsd].times do |i|
      a = @@anims_wi_stuff[@@wbs.epsd][i]

      # init variables
      a.ctr = -1

      # specify the next time to draw it
      if a.type == Doocr::Animenum::Always
        a.nexttic = Doocr.bcnt + 1 + (CDoom.m_random % a.period)
      elsif a.type == Doocr::Animenum::Random
        a.nexttic = Doocr.bcnt + 1 + a.data2 + (CDoom.m_random % a.data1)
      elsif a.type == Doocr::Animenum::Level
        a.nexttic = Doocr.bcnt + 1
      end
    end
  end

  def self.wi_update_animated_back
    return if Doocr.gamemode == Doocr::GameMode::Commercial

    return if @@wbs.epsd > 2

    @@numanims[@@wbs.epsd].times do |i|
      a = @@anims_wi_stuff[@@wbs.epsd][i]

      if Doocr.bcnt == a.nexttic
        case a.type
        when Doocr::Animenum::Always
          a.ctr = 0 if (a.ctr = a.ctr + 1) >= a.nanims
          a.nexttic = Doocr.bcnt + a.period
        when Doocr::Animenum::Random
          a.ctr = a.ctr + 1
          if a.ctr == a.nanims
            a.ctr = -1
            a.nexttic = Doocr.bcnt + a.data2 + (CDoom.m_random % a.data1)
          else
            a.nexttic = Doocr.bcnt + a.period
          end
        when Doocr::Animenum::Level
          # gawd-awful hack for level anims
          if !(Doocr.state == Doocr::Stateenum::StatCount && i == 7) &&
             @@wbs.next == a.data1
            a.ctr = a.ctr + 1
            a.ctr = a.ctr - 1 if a.ctr == a.nanims
            a.nexttic = Doocr.bcnt + a.period
          end
        end
      end
    end
  end

  def self.wi_draw_animated_back
    return if Doocr.gamemode == Doocr::GameMode::Commercial

    return if @@wbs.epsd > 2

    @@numanims[@@wbs.epsd].times do |i|
      a = @@anims_wi_stuff[@@wbs.epsd][i]

      CDoom.v_draw_patch(a.loc.x,
        a.loc.y,
        Doocr::FB,
        a.p[a.ctr]) if a.ctr >= 0
    end
  end

  #
  # Draws a number.
  # If digits > 0, then use that many digits minimum,
  #  otherwise only use as many as necessary.
  # Returns new x position.
  #
  def self.wi_draw_num(x : LibC::Int, y : LibC::Int, n : LibC::Int, digits : LibC::Int) : LibC::Int
    fontwidth = Doocr.num[0].value.width

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
      CDoom.v_draw_patch(x, y, Doocr::FB, Doocr.num[n % 10])
      n //= 10
    end

    # draw a minus sign if necessary
    CDoom.v_draw_patch(x -= 8, y, Doocr::FB, Doocr.wiminus) if neg

    return x
  end

  def self.wi_draw_percent(x : LibC::Int, y : LibC::Int, p : LibC::Int)
    return if p < 0

    CDoom.v_draw_patch(x, y, Doocr::FB, Doocr.percent)
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
        x = CDoom.wi_draw_num(x, y, n, 2) - Doocr.colon.value.width
        div *= 60

        # draw
        CDoom.v_draw_patch(x, y, Doocr::FB, Doocr.colon) if div == 60 || t // div != 0

        break unless t // div != 0
      end
    else
      # "sucks"
      CDoom.v_draw_patch(x - Doocr.sucks.value.width, y, Doocr::FB, Doocr.sucks)
    end
  end

  def self.wi_end
    CDoom.wi_unload_data
  end

  def self.wi_init_no_state
          Doocr.state = Doocr::Stateenum::NoState
    Doocr.acceleratestage = 0
    Doocr.cnt = 10
  end

  def self.wi_update_no_state
    CDoom.wi_update_animated_back

    if (Doocr.cnt -= 1) == 0
      CDoom.wi_end
      CDoom.g_world_done
    end
  end

  def self.wi_init_show_next_loc
    Doocr.state = Doocr::Stateenum::ShowNextLoc
    Doocr.acceleratestage = 0
    Doocr.cnt = Doocr::SHOWNEXTLOCDELAY * CDoom::TICRATE

    CDoom.wi_init_animated_back
  end

  def self.wi_update_show_next_loc
    CDoom.wi_update_animated_back

    if (Doocr.cnt -= 1) == 0 || Doocr.acceleratestage != 0
      CDoom.wi_init_no_state
    else
      Doocr.snl_pointeron = ((Doocr.cnt & 31) < 20).to_unsafe
    end
  end

  def self.wi_draw_show_next_loc
    CDoom.wi_slam_background

    # draw animated background
    CDoom.wi_draw_animated_back

    if Doocr.gamemode != Doocr::GameMode::Commercial
      if @@wbs.epsd > 2
        CDoom.wi_draw_el
        return
      end

      last = (@@wbs.last == 8) ? @@wbs.next - 1 : @@wbs.last

      # draw a splat on taken cities.
      Doocr.splat_pair[0] = Doocr.splat
      Doocr.splat_pair[1] = Doocr.splat
      (last + 1).times { |i| CDoom.wi_draw_on_lnode(i, Doocr.splat_pair.to_unsafe.as(CDoom::Patch**)) }

      # splat the secret level?
      CDoom.wi_draw_on_lnode(8, Doocr.splat_pair.to_unsafe.as(CDoom::Patch**)) if @@wbs.didsecret != 0

      # draw flashint ptr
      CDoom.wi_draw_on_lnode(@@wbs.next, Doocr.yah.to_unsafe.as(CDoom::Patch**)) if Doocr.snl_pointeron != 0
    end

    # draws which level yo uare entering..
    if Doocr.gamemode != Doocr::GameMode::Commercial ||
      @@wbs.next != 30
      CDoom.wi_draw_el
    end
  end

  def self.wi_draw_no_state
    Doocr.snl_pointeron = 1
    CDoom.wi_draw_show_next_loc
  end

  def self.wi_frag_sum(playernum : LibC::Int) : LibC::Int
    frags = 0

    CDoom::MAXPLAYERS.times do |i|
      if Doocr.playeringame[i] != 0 &&
         i != playernum
        frags += @@plrs[playernum].frags[i]
      end
    end

    # JDC hack - negative frags.
    frags -= @@plrs[playernum].frags[playernum]

    return frags
  end

  def self.wi_init_deathmatch_stats
    Doocr.state = Doocr::Stateenum::StatCount
    Doocr.acceleratestage = 0
    Doocr.dm_state = 1

    Doocr.cnt_pause = CDoom::TICRATE

    CDoom::MAXPLAYERS.times do |i|
      if Doocr.playeringame[i] != 0
        CDoom::MAXPLAYERS.times do |j|
          Doocr.dm_frags[i][j] = 0 if Doocr.playeringame[j] != 0
        end

        Doocr.dm_totals[i] = 0
      end
    end

    CDoom.wi_init_animated_back
  end

  def self.wi_update_deathmatch_stats
    CDoom.wi_update_animated_back

    if Doocr.acceleratestage != 0 && Doocr.dm_state != 4
      Doocr.acceleratestage = 0

      CDoom::MAXPLAYERS.times do |i|
        if Doocr.playeringame[i] != 0
          CDoom::MAXPLAYERS.times do |j|
            Doocr.dm_frags[i][j] = @@plrs[i].frags[j] if Doocr.playeringame[j] != 0
          end

          Doocr.dm_totals[i] = CDoom.wi_frag_sum(i)
        end
      end

      Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_barexp.value)
      Doocr.dm_state = 4
    end

    if Doocr.dm_state == 2
      Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_pistol.value) if Doocr.bcnt & 3 == 0

      stillticking = false

      CDoom::MAXPLAYERS.times do |i|
        if Doocr.playeringame[i] != 0
          CDoom::MAXPLAYERS.times do |j|
            if Doocr.playeringame[j] != 0 &&
               Doocr.dm_frags[i][j] != @@plrs[i].frags[j]
              if @@plrs[i].frags[j] < 0
                Doocr.dm_frags[i][j] = Doocr.dm_frags[i][j] - 1
              else
                Doocr.dm_frags[i][j] = Doocr.dm_frags[i][j] + 1
              end

              if Doocr.dm_frags[i][j] > 99
                Doocr.dm_frags[i][j] = 99
              end
              if Doocr.dm_frags[i][j] < -99
                Doocr.dm_frags[i][j] = -99
              end

              stillticking = true
            end
          end
          Doocr.dm_totals[i] = CDoom.wi_frag_sum(i)

          Doocr.dm_totals[i] = 99 if Doocr.dm_totals[i] > 99
          Doocr.dm_totals[i] = -99 if Doocr.dm_totals[i] < -99
        end
      end
      if !stillticking
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_barexp.value)
        Doocr.dm_state += 1
      end
    elsif Doocr.dm_state == 4
      if Doocr.acceleratestage != 0
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_slop.value)

        if Doocr.gamemode == Doocr::GameMode::Commercial
          CDoom.wi_init_no_state
        else
          CDoom.wi_init_show_next_loc
        end
      end
    elsif Doocr.dm_state & 1 != 0
      if (Doocr.cnt_pause -= 1) == 0
        Doocr.dm_state += 1
        Doocr.cnt_pause = CDoom::TICRATE
      end
    end
  end

  def self.wi_draw_deathmatch_stats
    lh = Doocr::WI_SPACINGY # line height

    CDoom.wi_slam_background

    # draw animated background
    CDoom.wi_draw_animated_back
    CDoom.wi_draw_lf

    # draw stat titles (top line)
    CDoom.v_draw_patch(Doocr::DM_TOTALSX - Doocr.total.value.width // 2,
      Doocr::DM_MATRIXY - Doocr::WI_SPACINGY + 10,
      Doocr::FB, Doocr.total)

    CDoom.v_draw_patch(Doocr::DM_KILLERSX, Doocr::DM_KILLERSY, Doocr::FB, Doocr.killers)
    CDoom.v_draw_patch(Doocr::DM_VICTIMSX, Doocr::DM_VICTIMSY, Doocr::FB, Doocr.victims)

    # draw P?
    x = Doocr::DM_MATRIXX + Doocr::DM_SPACINGX
    y = Doocr::DM_MATRIXY

    CDoom::MAXPLAYERS.times do |i|
      if Doocr.playeringame[i] != 0
        CDoom.v_draw_patch(x - Doocr.p[i].value.width // 2,
          Doocr::DM_MATRIXY - Doocr::WI_SPACINGY,
          Doocr::FB, Doocr.p[i])

        CDoom.v_draw_patch(Doocr::DM_MATRIXX - Doocr.p[i].value.width // 2,
          y,
          Doocr::FB, Doocr.p[i])

        if i == Doocr.me
          CDoom.v_draw_patch(x - Doocr.p[i].value.width // 2,
            Doocr::DM_MATRIXY - Doocr::WI_SPACINGY,
            Doocr::FB, Doocr.bstar)

          CDoom.v_draw_patch(Doocr::DM_MATRIXX - Doocr.p[i].value.width // 2,
            y,
            Doocr::FB, Doocr.star)
        end
      end
      x += Doocr::DM_SPACINGX
      y += Doocr::WI_SPACINGY
    end

    # draw stats
    y = Doocr::DM_MATRIXY + 10
    w = Doocr.num[0].value.width

    CDoom::MAXPLAYERS.times do |i|
      x = Doocr::DM_MATRIXX + Doocr::DM_SPACINGX

      if Doocr.playeringame[i] != 0
        CDoom::MAXPLAYERS.times do |j|
          CDoom.wi_draw_num(x + w, y, Doocr.dm_frags[i][j], 2) if Doocr.playeringame[j] != 0

          x += Doocr::DM_SPACINGX
        end
        CDoom.wi_draw_num(Doocr::DM_TOTALSX + w, y, Doocr.dm_totals[i], 2)
      end
      y += Doocr::WI_SPACINGY
    end
  end

  def self.wi_init_netgame_stats
    Doocr.state = Doocr::Stateenum::StatCount
    Doocr.acceleratestage = 0
    Doocr.ng_state = 1

    Doocr.cnt_pause = CDoom::TICRATE

    CDoom::MAXPLAYERS.times do |i|
      next if Doocr.playeringame[i] == 0

      Doocr.cnt_kills[i] = 0
      Doocr.cnt_items[i] = 0
      Doocr.cnt_secret[i] = 0
      Doocr.cnt_frags[i] = 0

      Doocr.dofrags += CDoom.wi_frag_sum(i)
    end

    Doocr.dofrags = ((Doocr.dofrags == 0).to_unsafe == 0).to_unsafe

    CDoom.wi_init_animated_back
  end

  def self.wi_update_netgame_stats
    CDoom.wi_update_animated_back

    if Doocr.acceleratestage != 0 && Doocr.ng_state != 10
      Doocr.acceleratestage = 0

      CDoom::MAXPLAYERS.times do |i|
        next if Doocr.playeringame[i] == 0

        Doocr.cnt_kills[i] = (@@plrs[i].skills * 100) // @@wbs.maxkills
        Doocr.cnt_items[i] = (@@plrs[i].sitems * 100) // @@wbs.maxitems
        Doocr.cnt_secret[i] = (@@plrs[i].ssecret * 100) // @@wbs.maxsecret

        Doocr.cnt_frags[i] = CDoom.wi_frag_sum(i) if Doocr.dofrags != 0
      end
      Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_barexp.value)
      Doocr.ng_state = 10
    end

    if Doocr.ng_state == 2
      Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_pistol.value) if Doocr.bcnt & 3 == 0

      stillticking = false

      CDoom::MAXPLAYERS.times do |i|
        next if Doocr.playeringame[i] == 0

        Doocr.cnt_kills[i] = Doocr.cnt_kills[i] + 2

        if Doocr.cnt_kills[i] >= (@@plrs[i].skills * 100) // @@wbs.maxkills
          Doocr.cnt_kills[i] = (@@plrs[i].skills * 100) // @@wbs.maxkills
        else
          stillticking = true
        end
      end

      if !stillticking
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_barexp.value)
        Doocr.ng_state += 1
      end
    elsif Doocr.ng_state == 4
      Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_pistol.value) if Doocr.bcnt & 3 == 0

      stillticking = false

      CDoom::MAXPLAYERS.times do |i|
        next if Doocr.playeringame[i] == 0

        Doocr.cnt_items[i] = Doocr.cnt_items[i] + 2

        if Doocr.cnt_items[i] >= (@@plrs[i].sitems * 100) // @@wbs.maxitems
          Doocr.cnt_items[i] = (@@plrs[i].sitems * 100) // @@wbs.maxitems
        else
          stillticking = true
        end
      end

      if !stillticking
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_barexp.value)
        Doocr.ng_state += 1
      end
    elsif Doocr.ng_state == 6
      Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_pistol.value) if Doocr.bcnt & 3 == 0

      stillticking = false

      CDoom::MAXPLAYERS.times do |i|
        next if Doocr.playeringame[i] == 0

        Doocr.cnt_secret[i] = Doocr.cnt_secret[i] + 2

        if Doocr.cnt_secret[i] >= (@@plrs[i].ssecret * 100) // @@wbs.maxsecret
          Doocr.cnt_secret[i] = (@@plrs[i].ssecret * 100) // @@wbs.maxsecret
        else
          stillticking = true
        end
      end

      if !stillticking
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_barexp.value)
        Doocr.ng_state += 1 + 2 * (Doocr.dofrags == 0).to_unsafe
      end
    elsif Doocr.ng_state == 8
      Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_pistol.value) if Doocr.bcnt & 3 == 0

      stillticking = false

      CDoom::MAXPLAYERS.times do |i|
        next if Doocr.playeringame[i] == 0

        Doocr.cnt_frags[i] = Doocr.cnt_frags[i] + 1

        if Doocr.cnt_frags[i] >= (fsum = CDoom.wi_frag_sum(i))
          Doocr.cnt_frags[i] = fsum
        else
          stillticking = true
        end
      end

      if !stillticking
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_pldeth.value)
        Doocr.ng_state += 1
      end
    elsif Doocr.ng_state == 10
      if Doocr.acceleratestage != 0
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_sgcock.value)
        if Doocr.gamemode == Doocr::GameMode::Commercial
          CDoom.wi_init_no_state
        else
          CDoom.wi_init_show_next_loc
        end
      end
    elsif Doocr.ng_state & 1 != 0
      if (Doocr.cnt_pause -= 1) == 0
        Doocr.ng_state += 1
        Doocr.cnt_pause = CDoom::TICRATE
      end
    end
  end

  def self.wi_draw_netgame_stats
    pwidth = Doocr.percent.value.width

    CDoom.wi_slam_background

    # draw animated background
    CDoom.wi_draw_animated_back

    CDoom.wi_draw_lf

    # draw stat titles (top line)
    CDoom.v_draw_patch(ng_statsx + Doocr::NG_SPACINGX - Doocr.kills.value.width,
      Doocr::NG_STATSY, Doocr::FB, Doocr.kills)

    CDoom.v_draw_patch(ng_statsx + 2 * Doocr::NG_SPACINGX - Doocr.items.value.width,
      Doocr::NG_STATSY, Doocr::FB, Doocr.items)

    CDoom.v_draw_patch(ng_statsx + 3 * Doocr::NG_SPACINGX - Doocr.secret.value.width,
      Doocr::NG_STATSY, Doocr::FB, Doocr.secret)

    if Doocr.dofrags != 0
      CDoom.v_draw_patch(ng_statsx + 4 * Doocr::NG_SPACINGX - Doocr.frags.value.width,
        Doocr::NG_STATSY, Doocr::FB, Doocr.frags)
    end

    # draw stats
    y = Doocr::NG_STATSY + Doocr.kills.value.height

    CDoom::MAXPLAYERS.times do |i|
      next if Doocr.playeringame[i] == 0

      x = ng_statsx
      CDoom.v_draw_patch(x - Doocr.p[i].value.width, y, Doocr::FB, Doocr.p[i])

      CDoom.v_draw_patch(x - Doocr.p[i].value.width, y, Doocr::FB, Doocr.star) if i == Doocr.me

      x += Doocr::NG_SPACINGX
      CDoom.wi_draw_percent(x - pwidth, y + 10, Doocr.cnt_kills[i])
      x += Doocr::NG_SPACINGX
      CDoom.wi_draw_percent(x - pwidth, y + 10, Doocr.cnt_items[i])
      x += Doocr::NG_SPACINGX
      CDoom.wi_draw_percent(x - pwidth, y + 10, Doocr.cnt_secret[i])
      x += Doocr::NG_SPACINGX

      if Doocr.dofrags != 0
        CDoom.wi_draw_num(x, y + 10, Doocr.cnt_frags[i], -1)
      end

      y += Doocr::WI_SPACINGY
    end
  end

  def self.wi_init_stats
    Doocr.state = Doocr::Stateenum::StatCount
    Doocr.acceleratestage = 0
    Doocr.sp_state = 1
    Doocr.cnt_kills[0] = -1
    Doocr.cnt_items[0] = -1
    Doocr.cnt_secret[0] = -1
    Doocr.cnt_time = -1
    Doocr.cnt_par = -1
    Doocr.cnt_pause = CDoom::TICRATE

    CDoom.wi_init_animated_back
  end

  def self.wi_update_stats
    CDoom.wi_update_animated_back

    if Doocr.acceleratestage != 0 && Doocr.sp_state != 10
      Doocr.acceleratestage = 0

      Doocr.cnt_kills[0] = (@@plrs[Doocr.me].skills * 100) // @@wbs.maxkills
      Doocr.cnt_items[0] = (@@plrs[Doocr.me].sitems * 100) // @@wbs.maxitems
      Doocr.cnt_secret[0] = (@@plrs[Doocr.me].ssecret * 100) // @@wbs.maxsecret
      Doocr.cnt_time = @@plrs[Doocr.me].stime // CDoom::TICRATE
      Doocr.cnt_par = @@wbs.partime // CDoom::TICRATE
      Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_barexp.value)
      Doocr.sp_state = 10
    end

    if Doocr.sp_state == 2
      Doocr.cnt_kills[0] = Doocr.cnt_kills[0] + 2

      Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_pistol.value) if Doocr.bcnt & 3 == 0

      if Doocr.cnt_kills[0] >= (@@plrs[Doocr.me].skills * 100) // @@wbs.maxkills
        Doocr.cnt_kills[0] = (@@plrs[Doocr.me].skills * 100) // @@wbs.maxkills
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_barexp.value)
        Doocr.sp_state += 1
      end
    elsif Doocr.sp_state == 4
      Doocr.cnt_items[0] = Doocr.cnt_items[0] + 2

      Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_pistol.value) if Doocr.bcnt & 3 == 0

      if Doocr.cnt_items[0] >= (@@plrs[Doocr.me].sitems * 100) // @@wbs.maxitems
        Doocr.cnt_items[0] = (@@plrs[Doocr.me].sitems * 100) // @@wbs.maxitems
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_barexp.value)
        Doocr.sp_state += 1
      end
    elsif Doocr.sp_state == 6
      Doocr.cnt_secret[0] = Doocr.cnt_secret[0] + 2

      Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_pistol.value) if Doocr.bcnt & 3 == 0

      if Doocr.cnt_secret[0] >= (@@plrs[Doocr.me].ssecret * 100) // @@wbs.maxsecret
        Doocr.cnt_secret[0] = (@@plrs[Doocr.me].ssecret * 100) // @@wbs.maxsecret
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_barexp.value)
        Doocr.sp_state += 1
      end
    elsif Doocr.sp_state == 8
      Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_pistol.value) if Doocr.bcnt & 3 == 0

      Doocr.cnt_time += 3

      if Doocr.cnt_time >= @@plrs[Doocr.me].stime // CDoom::TICRATE
        Doocr.cnt_time = @@plrs[Doocr.me].stime // CDoom::TICRATE
      end

      Doocr.cnt_par += 3

      if Doocr.cnt_par >= @@wbs.partime // CDoom::TICRATE
        Doocr.cnt_par = @@wbs.partime // CDoom::TICRATE

        if Doocr.cnt_time >= @@plrs[Doocr.me].stime // CDoom::TICRATE
          Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_barexp.value)
          Doocr.sp_state += 1
        end
      end
    elsif Doocr.sp_state == 10
      if Doocr.acceleratestage != 0
        Doocr.s_start_sound(Pointer(Void).null, Doocr::Sfxenum::SFX_sgcock.value)
        if Doocr.gamemode == Doocr::GameMode::Commercial
          CDoom.wi_init_no_state
        else
          CDoom.wi_init_show_next_loc
        end
      end
    elsif Doocr.sp_state & 1 != 0
      if (Doocr.cnt_pause -= 1) == 0
        Doocr.sp_state += 1
        Doocr.cnt_pause = CDoom::TICRATE
      end
    end
  end

  def self.wi_draw_stats
    lh = (3 * Doocr.num[0].value.height) // 2

    CDoom.wi_slam_background

    # draw animated background
    CDoom.wi_draw_animated_back

    CDoom.wi_draw_lf

    CDoom.v_draw_patch(Doocr::SP_STATSX, Doocr::SP_STATSY, Doocr::FB, Doocr.kills)
    CDoom.wi_draw_percent(CDoom::SCREENWIDTH - Doocr::SP_STATSX, Doocr::SP_STATSY, Doocr.cnt_kills[0])

    CDoom.v_draw_patch(Doocr::SP_STATSX, Doocr::SP_STATSY + lh, Doocr::FB, Doocr.items)
    CDoom.wi_draw_percent(CDoom::SCREENWIDTH - Doocr::SP_STATSX, Doocr::SP_STATSY + lh, Doocr.cnt_items[0])

    CDoom.v_draw_patch(Doocr::SP_STATSX, Doocr::SP_STATSY + 2 * lh, Doocr::FB, Doocr.sp_secret)
    CDoom.wi_draw_percent(CDoom::SCREENWIDTH - Doocr::SP_STATSX, Doocr::SP_STATSY + 2 * lh, Doocr.cnt_secret[0])

    CDoom.v_draw_patch(Doocr::SP_TIMEX, Doocr::SP_TIMEY, Doocr::FB, Doocr.time_patch)
    CDoom.wi_draw_time(CDoom::SCREENWIDTH // 2 - Doocr::SP_TIMEX, Doocr::SP_TIMEY, Doocr.cnt_time)

    CDoom.v_draw_patch(CDoom::SCREENWIDTH // 2 + Doocr::SP_TIMEX, Doocr::SP_TIMEY, Doocr::FB, Doocr.par)
    CDoom.wi_draw_time(CDoom::SCREENWIDTH - Doocr::SP_TIMEX, Doocr::SP_TIMEY, Doocr.cnt_par)
  end

  def self.wi_check_for_accelerate
    # check for button presses to skip delays
    player = @@players.to_unsafe
    CDoom::MAXPLAYERS.times do |i|
      if Doocr.playeringame[i] != 0
        if player.value.cmd.buttons & Doocr::Buttoncode::BT_ATTACK.value != 0
          Doocr.acceleratestage = 1 if player.value.attackdown == 0
          player.value.attackdown = 1
        else
          player.value.attackdown = 0
        end
        if player.value.cmd.buttons & Doocr::Buttoncode::BT_USE.value != 0
          Doocr.acceleratestage = 1 if player.value.usedown == 0
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
    Doocr.bcnt += 1

    if Doocr.bcnt == 1
      # intermission music
      if Doocr.gamemode == Doocr::GameMode::Commercial
        Doocr.s_change_music(Doocr::Musicenum::MUS_dm2int, 1)
      else
        Doocr.s_change_music(Doocr::Musicenum::MUS_inter, 1)
      end
    end

    CDoom.wi_check_for_accelerate

    case Doocr.state
    when Doocr::Stateenum::StatCount
      if Doocr.deathmatch != 0
        CDoom.wi_update_deathmatch_stats
      elsif Doocr.netgame != 0
        CDoom.wi_update_netgame_stats
      else
        CDoom.wi_update_stats
      end
    when Doocr::Stateenum::ShowNextLoc
      CDoom.wi_update_show_next_loc
    when Doocr::Stateenum::NoState
      CDoom.wi_update_no_state
    end
  end

  def self.wi_load_data
    name = Pointer(UInt8).malloc(9)

    if Doocr.gamemode == Doocr::GameMode::Commercial
      CDoom.doom_strcpy(name, "INTERPIC")
    else
      CDoom.doom_strcpy(name, "WIMAP")
      CDoom.doom_concat(name, CDoom.doom_itoa(@@wbs.epsd, 10))
    end

    if Doocr.gamemode == Doocr::GameMode::Retail &&
      @@wbs.epsd == 3
      CDoom.doom_strcpy(name, "INTERPIC")
    end

    # background
    Doocr.bg = CDoom.w_cache_lump_name(name, Doocr::PU_CACHE).as(CDoom::Patch*)
    CDoom.v_draw_patch(0, 0, 1, Doocr.bg)

    if Doocr.gamemode == Doocr::GameMode::Commercial
      Doocr.numcmaps = 32
      Doocr.lnames.clear

      Doocr.numcmaps.times do |i|
        CDoom.doom_strcpy(name, "CWILV")
        CDoom.doom_concat(name, "0") if i < 10
        CDoom.doom_concat(name, CDoom.doom_itoa(i, 10))
        Doocr.lnames << CDoom.w_cache_lump_name(name, Doocr::PU_STATIC).as(CDoom::Patch*)
      end
    else
      Doocr.lnames.clear

      Doocr::NUMMAPS.times do |i|
        CDoom.doom_strcpy(name, "WILV")
        CDoom.doom_concat(name, CDoom.doom_itoa(@@wbs.epsd, 10))
        CDoom.doom_concat(name, CDoom.doom_itoa(i, 10))
        Doocr.lnames << CDoom.w_cache_lump_name(name, Doocr::PU_STATIC).as(CDoom::Patch*)
      end

      # you are here
      Doocr.yah[0] = CDoom.w_cache_lump_name("WIURH0", Doocr::PU_STATIC).as(CDoom::Patch*)

      # you are here (alt.)
      Doocr.yah[1] = CDoom.w_cache_lump_name("WIURH1", Doocr::PU_STATIC).as(CDoom::Patch*)

      # splat
      Doocr.splat = CDoom.w_cache_lump_name("WISPLAT", Doocr::PU_STATIC).as(CDoom::Patch*)

      if @@wbs.epsd < 3
        @@numanims[@@wbs.epsd].times do |j|
          a = @@anims_wi_stuff[@@wbs.epsd][j]
          a.nanims.times do |i|
            # MONDO HACK!
            if @@wbs.epsd != 1 || j != 8
              # animations
              CDoom.doom_strcpy(name, "WIA")
              CDoom.doom_concat(name, CDoom.doom_itoa(@@wbs.epsd, 10))
              CDoom.doom_concat(name, "0") if j < 10
              CDoom.doom_concat(name, CDoom.doom_itoa(j, 10))
              CDoom.doom_concat(name, "0") if i < 10
              CDoom.doom_concat(name, CDoom.doom_itoa(i, 10))
              a.p[i] = CDoom.w_cache_lump_name(name, Doocr::PU_STATIC).as(CDoom::Patch*)
            else
              # HACK ALERT!
              a.p[i] = @@anims_wi_stuff[1][4].p[i]
            end
          end
        end
      end
    end

    # More hacks on minus sign
    Doocr.wiminus = CDoom.w_cache_lump_name("WIMINUS", Doocr::PU_STATIC).as(CDoom::Patch*)

    10.times do |i|
      CDoom.doom_strcpy(name, "WINUM")
      CDoom.doom_concat(name, CDoom.doom_itoa(i, 10))
      Doocr.num[i] = CDoom.w_cache_lump_name(name, Doocr::PU_STATIC).as(CDoom::Patch*)
    end

    # percent sign
    Doocr.percent = CDoom.w_cache_lump_name("WIPCNT", Doocr::PU_STATIC).as(CDoom::Patch*)

    # "finished"
    Doocr.finished = CDoom.w_cache_lump_name("WIF", Doocr::PU_STATIC).as(CDoom::Patch*)

    # "entering"
    Doocr.entering = CDoom.w_cache_lump_name("WIENTER", Doocr::PU_STATIC).as(CDoom::Patch*)

    # "kills"
    Doocr.kills = CDoom.w_cache_lump_name("WIOSTK", Doocr::PU_STATIC).as(CDoom::Patch*)

    # "scrt"
    Doocr.secret = CDoom.w_cache_lump_name("WIOSTS", Doocr::PU_STATIC).as(CDoom::Patch*)

    # "secret"
    Doocr.sp_secret = CDoom.w_cache_lump_name("WISCRT2", Doocr::PU_STATIC).as(CDoom::Patch*)

    # Yuck.
    if Doocr.language == Doocr::Language::French
      # "items"
      if Doocr.netgame != 0 && Doocr.deathmatch == 0
        Doocr.items = CDoom.w_cache_lump_name("WIOBJ", Doocr::PU_STATIC).as(CDoom::Patch*)
      else
        Doocr.items = CDoom.w_cache_lump_name("WIOSTI", Doocr::PU_STATIC).as(CDoom::Patch*)
      end
    else
      Doocr.items = CDoom.w_cache_lump_name("WIOSTI", Doocr::PU_STATIC).as(CDoom::Patch*)
    end

    # "frgs"
    Doocr.frags = CDoom.w_cache_lump_name("WIFRGS", Doocr::PU_STATIC).as(CDoom::Patch*)

    # ":"
    Doocr.colon = CDoom.w_cache_lump_name("WICOLON", Doocr::PU_STATIC).as(CDoom::Patch*)

    # "time"
    Doocr.time_patch = CDoom.w_cache_lump_name("WITIME", Doocr::PU_STATIC).as(CDoom::Patch*)

    # "sucks"
    Doocr.sucks = CDoom.w_cache_lump_name("WISUCKS", Doocr::PU_STATIC).as(CDoom::Patch*)

    # "par"
    Doocr.par = CDoom.w_cache_lump_name("WIPAR", Doocr::PU_STATIC).as(CDoom::Patch*)

    # "killers" (vertical)
    Doocr.killers = CDoom.w_cache_lump_name("WIKILRS", Doocr::PU_STATIC).as(CDoom::Patch*)

    # "victims" (horiz)
    Doocr.victims = CDoom.w_cache_lump_name("WIVCTMS", Doocr::PU_STATIC).as(CDoom::Patch*)

    # "total"
    Doocr.total = CDoom.w_cache_lump_name("WIMSTT", Doocr::PU_STATIC).as(CDoom::Patch*)

    # your face
    Doocr.star = CDoom.w_cache_lump_name("STFST01", Doocr::PU_STATIC).as(CDoom::Patch*)

    # dead face
    Doocr.bstar = CDoom.w_cache_lump_name("STFDEAD0", Doocr::PU_STATIC).as(CDoom::Patch*)

    CDoom::MAXPLAYERS.times do |i|
      CDoom.doom_strcpy(name, "STPB")
      CDoom.doom_concat(name, CDoom.doom_itoa(i, 10))
      Doocr.p[i] = CDoom.w_cache_lump_name(name, Doocr::PU_STATIC).as(CDoom::Patch*)

      CDoom.doom_strcpy(name, "WIBP")
      CDoom.doom_concat(name, CDoom.doom_itoa(i + 1, 10))
      Doocr.bp[i] = CDoom.w_cache_lump_name(name, Doocr::PU_STATIC).as(CDoom::Patch*)
    end
  end

  def self.wi_unload_data
    z_change_tag(Doocr.wiminus, Doocr::PU_CACHE)

    10.times do |i|
      z_change_tag(Doocr.num[i], Doocr::PU_CACHE)
    end

    if Doocr.gamemode == Doocr::GameMode::Commercial
      Doocr.numcmaps.times do |i|
        z_change_tag(Doocr.lnames[i], Doocr::PU_CACHE)
      end
    else
      z_change_tag(Doocr.yah[0], Doocr::PU_CACHE)
      z_change_tag(Doocr.yah[1], Doocr::PU_CACHE)

      z_change_tag(Doocr.splat, Doocr::PU_CACHE)

      Doocr::NUMMAPS.times do |i|
        z_change_tag(Doocr.lnames[i], Doocr::PU_CACHE)
      end

      if @@wbs.epsd < 3
        @@numanims[@@wbs.epsd].times do |j|
          if @@wbs.epsd != 1 || j != 8
            @@anims_wi_stuff[@@wbs.epsd][j].nanims.times do |i|
              z_change_tag(@@anims_wi_stuff[@@wbs.epsd][j].p[i], Doocr::PU_CACHE)
            end
          end
        end
      end
    end

    z_change_tag(Doocr.percent, Doocr::PU_CACHE)
    z_change_tag(Doocr.colon, Doocr::PU_CACHE)
    z_change_tag(Doocr.finished, Doocr::PU_CACHE)
    z_change_tag(Doocr.entering, Doocr::PU_CACHE)
    z_change_tag(Doocr.kills, Doocr::PU_CACHE)
    z_change_tag(Doocr.secret, Doocr::PU_CACHE)
    z_change_tag(Doocr.sp_secret, Doocr::PU_CACHE)
    z_change_tag(Doocr.items, Doocr::PU_CACHE)
    z_change_tag(Doocr.frags, Doocr::PU_CACHE)
    z_change_tag(Doocr.time_patch, Doocr::PU_CACHE)
    z_change_tag(Doocr.sucks, Doocr::PU_CACHE)
    z_change_tag(Doocr.par, Doocr::PU_CACHE)

    z_change_tag(Doocr.victims, Doocr::PU_CACHE)
    z_change_tag(Doocr.killers, Doocr::PU_CACHE)
    z_change_tag(Doocr.total, Doocr::PU_CACHE)

    CDoom::MAXPLAYERS.times do |i|
      z_change_tag(Doocr.p[i], Doocr::PU_CACHE)
    end

    CDoom::MAXPLAYERS.times do |i|
      z_change_tag(Doocr.bp[i], Doocr::PU_CACHE)
    end
  end

  def self.wi_drawer
    case Doocr.state
    when Doocr::Stateenum::StatCount
      if Doocr.deathmatch != 0
        CDoom.wi_draw_deathmatch_stats
      elsif Doocr.netgame != 0
        CDoom.wi_draw_netgame_stats
      else
        CDoom.wi_draw_stats
      end
    when Doocr::Stateenum::ShowNextLoc
      CDoom.wi_draw_show_next_loc
    when Doocr::Stateenum::NoState
      CDoom.wi_draw_no_state
    end
  end

  def self.wi_init_variables(wbstartstruct : Wbstart)
    @@wbs = wbstartstruct
    Doocr.acceleratestage = 0
    Doocr.cnt = 0
    Doocr.bcnt = 0
    Doocr.firstrefresh = 1
    Doocr.me = @@wbs.pnum
    @@plrs = @@wbs.plyr

    @@wbs.maxkills = 1 if @@wbs.maxkills == 0
    @@wbs.maxitems = 1 if @@wbs.maxitems == 0
    @@wbs.maxsecret = 1 if @@wbs.maxsecret == 0

    if Doocr.gamemode != Doocr::GameMode::Retail
      @@wbs.epsd -= 3 if @@wbs.epsd > 2
    end
  end

  def self.wi_start(wbstartstruct : Wbstart)
    wi_init_variables(wbstartstruct)
    CDoom.wi_load_data

    if Doocr.deathmatch != 0
      CDoom.wi_init_deathmatch_stats
    elsif Doocr.netgame != 0
      CDoom.wi_init_netgame_stats
    else
      CDoom.wi_init_stats
    end
  end
end
