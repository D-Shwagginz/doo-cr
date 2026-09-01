module Doocr
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
end
