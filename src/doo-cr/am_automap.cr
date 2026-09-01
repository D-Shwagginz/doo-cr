module Doocr
  def self.am_activate_new_scale
    CDoom.m_x += CDoom.m_w // 2
    CDoom.m_y += CDoom.m_h // 2
    CDoom.m_w = ftom(CDoom.f_w)
    CDoom.m_h = ftom(CDoom.f_h)
    CDoom.m_x -= CDoom.m_w // 2
    CDoom.m_y -= CDoom.m_h // 2
    CDoom.m_x2 = CDoom.m_x + CDoom.m_w
    CDoom.m_y2 = CDoom.m_y + CDoom.m_h
  end

  def self.am_save_scale_and_loc
    CDoom.old_m_x = CDoom.m_x
    CDoom.old_m_y = CDoom.m_y
    CDoom.old_m_w = CDoom.m_w
    CDoom.old_m_h = CDoom.m_h
  end

  def self.am_restore_scale_and_loc
    CDoom.m_w = CDoom.old_m_w
    CDoom.m_h = CDoom.old_m_h
    if CDoom.followplayer == 0
      CDoom.m_x = CDoom.old_m_x
      CDoom.m_y = CDoom.old_m_y
    else
      CDoom.m_x = CDoom.plr.value.mo.value.x - CDoom.m_w // 2
      CDoom.m_y = CDoom.plr.value.mo.value.y - CDoom.m_h // 2
    end
    CDoom.m_x2 = CDoom.m_x + CDoom.m_w
    CDoom.m_y2 = CDoom.m_y + CDoom.m_h

    # Change the scaling multipliers
    CDoom.scale_mtof = CDoom.fixed_div(CDoom.f_w << FRACBITS, CDoom.m_w)
    CDoom.scale_ftom = CDoom.fixed_div(FRACUNIT, CDoom.scale_mtof)
  end

  #
  # adds a marker at the current location
  #
  def self.am_add_mark
    (CDoom.markpoints.to_unsafe.as(CDoom::Mpoint*) + CDoom.markpointnum).value.x = CDoom.m_x + CDoom.m_w // 2
    (CDoom.markpoints.to_unsafe.as(CDoom::Mpoint*) + CDoom.markpointnum).value.y = CDoom.m_y + CDoom.m_h // 2
    CDoom.markpointnum = (CDoom.markpointnum + 1) % CDoom::AM_NUMMARKPOINTS
  end

  #
  # Determines bounding box of all vertices,
  # sets global variables controlling zoom range.
  #
  def self.am_find_min_max_boundaries
    CDoom.min_x = Int32::MAX
    CDoom.min_y = Int32::MAX
    CDoom.max_x = -Int32::MAX
    CDoom.max_y = -Int32::MAX

    CDoom.numvertexes.times do |i|
      if CDoom.vertexes[i].x < CDoom.min_x
        CDoom.min_x = CDoom.vertexes[i].x
      elsif CDoom.vertexes[i].x > CDoom.max_x
        CDoom.max_x = CDoom.vertexes[i].x
      end

      if CDoom.vertexes[i].y < CDoom.min_y
        CDoom.min_y = CDoom.vertexes[i].y
      elsif CDoom.vertexes[i].y > CDoom.max_y
        CDoom.max_y = CDoom.vertexes[i].y
      end
    end

    CDoom.max_w = CDoom.max_x - CDoom.min_x
    CDoom.max_h = CDoom.max_y - CDoom.min_y

    CDoom.min_w = 2 * CDoom::PLAYERRADIUS # const? never changed?
    CDoom.min_h = 2 * CDoom::PLAYERRADIUS

    a = CDoom.fixed_div(CDoom.f_w << FRACBITS, CDoom.max_w)
    b = CDoom.fixed_div(CDoom.f_h << FRACBITS, CDoom.max_h)

    CDoom.min_scale_mtof = a < b ? a : b
    CDoom.max_scale_mtof = CDoom.fixed_div(CDoom.f_h << FRACBITS, 2 * CDoom::PLAYERRADIUS)
  end

  def self.am_change_window_loc
    if CDoom.m_paninc.x != 0 || CDoom.m_paninc.y != 0
      CDoom.followplayer = 0
      CDoom.f_oldloc.x = Int32::MAX
    end

    CDoom.m_x += CDoom.m_paninc.x
    CDoom.m_y += CDoom.m_paninc.y

    if CDoom.m_x + CDoom.m_w // 2 > CDoom.max_x
      CDoom.m_x = CDoom.max_x - CDoom.m_w // 2
    elsif CDoom.m_x + CDoom.m_w // 2 < CDoom.min_x
      CDoom.m_x = CDoom.min_x - CDoom.m_w // 2
    end

    if CDoom.m_y + CDoom.m_h // 2 > CDoom.max_y
      CDoom.m_y = CDoom.max_y - CDoom.m_h // 2
    elsif CDoom.m_y + CDoom.m_h // 2 < CDoom.min_y
      CDoom.m_y = CDoom.min_y - CDoom.m_h // 2
    end

    CDoom.m_x2 = CDoom.m_x + CDoom.m_w
    CDoom.m_y2 = CDoom.m_y + CDoom.m_h
  end

  def self.am_init_variables
    @@st_notify.type = CDoom::Evtype::Keyup
    @@st_notify.data1 = CDoom::AM_MSGENTERED

    CDoom.automapactive = 1
    CDoom.fb = CDoom.screens[0]
    CDoom.f_oldloc.x = Int32::MAX
    CDoom.amclock = 0
    CDoom.lightlev = 0

    CDoom.m_paninc.x = 0
    CDoom.m_paninc.y = 0
    CDoom.ftom_zoommul = FRACUNIT
    CDoom.mtof_zoommul = FRACUNIT

    CDoom.m_w = ftom(CDoom.f_w)
    CDoom.m_h = ftom(CDoom.f_h)

    pnum = CDoom.consoleplayer
    # find player to center on initially
    if CDoom.playeringame[pnum] == 0
      CDoom::MAXPLAYERS.times do |i|
        pnum = i
        break if CDoom.playeringame[pnum] != 0
      end
    end

    CDoom.plr = CDoom.players.to_unsafe.as(CDoom::Player*) + pnum
    CDoom.m_x = CDoom.plr.value.mo.value.x - CDoom.m_w // 2
    CDoom.m_y = CDoom.plr.value.mo.value.y - CDoom.m_h // 2
    CDoom.am_change_window_loc

    # for saving & restoring
    CDoom.old_m_x = CDoom.m_x
    CDoom.old_m_y = CDoom.m_y
    CDoom.old_m_w = CDoom.m_w
    CDoom.old_m_h = CDoom.m_h

    # inform the status bar of the change
    CDoom.st_responder(pointerof(@@st_notify))
  end

  def self.am_load_pics
    namebuf = uninitialized StaticArray(UInt8, 9)

    10.times do |i|
      CDoom.marknums[i] = CDoom.w_cache_lump_name("AMMNUM#{i}", CDoom::PU_STATIC).as(CDoom::Patch*)
    end
  end

  def self.am_unload_pics
    10.times { |i| z_change_tag(CDoom.marknums[i], CDoom::PU_CACHE) }
  end

  def self.am_clear_marks
    CDoom::AM_NUMMARKPOINTS.times do |i|
      (CDoom.markpoints.to_unsafe.as(CDoom::Mpoint*) + i).value.x = -1
    end
    CDoom.markpointnum = 0
  end

  #
  # should be called at the start of every level
  # right now, i figure it out myself
  #
  def self.am_level_init
    CDoom.leveljuststarted = 0

    CDoom.f_x = 0
    CDoom.f_y = 0
    CDoom.f_w = CDoom.finit_width
    CDoom.f_h = CDoom.finit_height

    CDoom.am_clear_marks

    CDoom.am_find_min_max_boundaries
    CDoom.scale_mtof = CDoom.fixed_div(CDoom.min_scale_mtof, (0.7 * FRACUNIT).to_i32!)
    CDoom.scale_mtof = CDoom.min_scale_mtof if CDoom.scale_mtof > CDoom.max_scale_mtof
    CDoom.scale_ftom = CDoom.fixed_div(FRACUNIT, CDoom.scale_mtof)
  end

  def self.am_stop
    @@st_notify.type = CDoom::Evtype.new(0)
    @@st_notify.data1 = CDoom::Evtype::Keyup.value
    @@st_notify.data2 = CDoom::AM_MSGENTERED

    CDoom.am_unload_pics
    CDoom.automapactive = 0
    CDoom.st_responder(pointerof(@@st_notify))
    CDoom.stopped = 1
  end

  def self.am_start
    CDoom.am_stop if CDoom.stopped == 0
    CDoom.stopped = 0
    if @@lastlevel != CDoom.gamemap || @@lastepisode != CDoom.gameepisode
      CDoom.am_level_init
      @@lastlevel = CDoom.gamemap
      @@lastepisode = CDoom.gameepisode
    end
    CDoom.am_init_variables
    CDoom.am_load_pics
  end

  #
  # set the window scale to the maximum size
  #
  def self.am_min_out_window_scale
    CDoom.scale_mtof = CDoom.min_scale_mtof
    CDoom.scale_ftom = CDoom.fixed_div(FRACUNIT, CDoom.scale_mtof)
    CDoom.am_activate_new_scale
  end

  #
  # set the window scale to the minimum size
  #
  def self.am_max_out_window_scale
    CDoom.scale_mtof = CDoom.max_scale_mtof
    CDoom.scale_ftom = CDoom.fixed_div(FRACUNIT, CDoom.scale_mtof)
    CDoom.am_activate_new_scale
  end

  #
  # Handle events (user inputs) in automap mode
  #
  def self.am_responder(ev : CDoom::Event*) : CDoom::DoomBool
    rc = 0

    if CDoom.automapactive == 0
      if ev.value.type == CDoom::Evtype::Keydown && ev.value.data1 == CDoom::AM_STARTKEY
        CDoom.am_start
        CDoom.viewactive = 0
        rc = 1
      end
    elsif ev.value.type == CDoom::Evtype::Keydown
      rc = 1
      case ev.value.data1
      when CDoom::AM_PANRIGHTKEY # pan right
        if CDoom.followplayer == 0
          CDoom.m_paninc.x = ftom(CDoom::F_PANINC)
        else
          rc = 0
        end
      when CDoom::AM_PANLEFTKEY # pan left
        if CDoom.followplayer == 0
          CDoom.m_paninc.x = -ftom(CDoom::F_PANINC)
        else
          rc = 0
        end
      when CDoom::AM_PANUPKEY # pan up
        if CDoom.followplayer == 0
          CDoom.m_paninc.y = ftom(CDoom::F_PANINC)
        else
          rc = 0
        end
      when CDoom::AM_PANDOWNKEY # pan down
        if CDoom.followplayer == 0
          CDoom.m_paninc.y = -ftom(CDoom::F_PANINC)
        else
          rc = 0
        end
      when CDoom::AM_ZOOMOUTKEY # zoom out
        CDoom.mtof_zoommul = CDoom::M_ZOOMOUT
        CDoom.ftom_zoommul = CDoom::M_ZOOMIN
      when CDoom::AM_ZOOMINKEY # zoom in
        CDoom.mtof_zoommul = CDoom::M_ZOOMIN
        CDoom.ftom_zoommul = CDoom::M_ZOOMOUT
      when CDoom::AM_ENDKEY
        @@bigstate = 0
        CDoom.viewactive = 1
        CDoom.am_stop
      when CDoom::AM_GOBIGKEY
        @@bigstate = @@bigstate != 0 ? 0 : 1
        if @@bigstate != 0
          CDoom.am_save_scale_and_loc
          CDoom.am_min_out_window_scale
        else
          CDoom.am_restore_scale_and_loc
        end
      when CDoom::AM_FOLLOWKEY
        CDoom.followplayer = CDoom.followplayer != 0 ? 0 : 1
        if CDoom.followplayer != 0 # Neat fix!
          CDoom.m_paninc.x = 0
          CDoom.m_paninc.y = 0
        end
        CDoom.f_oldloc.x = Int32::MAX
        CDoom.plr.value.message = CDoom.followplayer != 0 ? @@deh_amstr_followon : @@deh_amstr_followoff
      when CDoom::AM_GRIDKEY
        CDoom.grid = CDoom.grid != 0 ? 0 : 1
        CDoom.plr.value.message = CDoom.grid != 0 ? @@deh_amstr_gridon : @@deh_amstr_gridoff
      when CDoom::AM_MARKKEY
        CDoom.plr.value.message = "#{@@deh_amstr_markedspot} #{CDoom.markpointnum}"
        CDoom.am_add_mark
      when CDoom::AM_CLEARMARKKEY
        CDoom.am_clear_marks
        CDoom.plr.value.message = @@deh_amstr_markscleared
      else
        @@cheatstate = 0
        rc = 0
      end
      if CDoom.deathmatch == 0 && CDoom.cht_check_cheat(pointerof(CDoom.cheat_amap), ev.value.data1) != 0
        rc = 0
        CDoom.cheating = (CDoom.cheating + 1) % 3
      end
    elsif ev.value.type == CDoom::Evtype::Keyup
      rc = 0
      case ev.value.data1
      when CDoom::AM_PANRIGHTKEY
        CDoom.m_paninc.x = 0 if CDoom.followplayer == 0
      when CDoom::AM_PANLEFTKEY
        CDoom.m_paninc.x = 0 if CDoom.followplayer == 0
      when CDoom::AM_PANUPKEY
        CDoom.m_paninc.y = 0 if CDoom.followplayer == 0
      when CDoom::AM_PANDOWNKEY
        CDoom.m_paninc.y = 0 if CDoom.followplayer == 0
      when CDoom::AM_ZOOMOUTKEY, CDoom::AM_ZOOMINKEY
        CDoom.mtof_zoommul = FRACUNIT
        CDoom.ftom_zoommul = FRACUNIT
      end
    end

    return rc
  end

  #
  # Zooming
  #
  def self.am_change_window_scale
    # Change the scaling multipliers
    CDoom.scale_mtof = CDoom.fixed_mul(CDoom.scale_mtof, CDoom.mtof_zoommul)
    CDoom.scale_ftom = CDoom.fixed_div(FRACUNIT, CDoom.scale_mtof)

    if CDoom.scale_mtof < CDoom.min_scale_mtof
      CDoom.am_min_out_window_scale
    elsif CDoom.scale_mtof > CDoom.max_scale_mtof
      CDoom.am_max_out_window_scale
    else
      CDoom.am_activate_new_scale
    end
  end

  def self.am_do_follow_player
    if CDoom.f_oldloc.x != CDoom.plr.value.mo.value.x || CDoom.f_oldloc.y != CDoom.plr.value.mo.value.y
      CDoom.m_x = ftom(mtof(CDoom.plr.value.mo.value.x)) - CDoom.m_w // 2
      CDoom.m_y = ftom(mtof(CDoom.plr.value.mo.value.y)) - CDoom.m_h // 2
      CDoom.m_x2 = CDoom.m_x + CDoom.m_w
      CDoom.m_y2 = CDoom.m_y + CDoom.m_h
      CDoom.f_oldloc.x = CDoom.plr.value.mo.value.x
      CDoom.f_oldloc.y = CDoom.plr.value.mo.value.y
    end
  end

  def self.am_update_light_lev
    # Change light level
    if CDoom.amclock > @@nexttic
      CDoom.lightlev = @@litelevels[@@litelevelscnt]
      @@litelevelscnt += 1
      @@litelevelscnt = 0 if @@litelevelscnt == @@litelevels.size
      @@nexttic = CDoom.amclock + 6 - (CDoom.amclock % 6)
    end
  end

  #
  # Updates on Game Tick
  #
  def self.am_ticker
    return if CDoom.automapactive == 0

    CDoom.amclock += 1

    CDoom.am_do_follow_player if CDoom.followplayer != 0

    # Change the zoom if necessary
    CDoom.am_change_window_scale if CDoom.ftom_zoommul != FRACUNIT

    # Change x,y location
    CDoom.am_change_window_loc if CDoom.m_paninc.x != 0 || CDoom.m_paninc.y != 0

    # Update light level
    # CDoom.am_update_light_lev
  end

  #
  # Clear automap frame buffer.
  #
  def self.am_clear_fb(color : Int32)
    CDoom.doom_memset(CDoom.fb, color, CDoom.f_w * CDoom.f_h)
  end

  LEFT   = 1
  RIGHT  = 2
  BOTTOM = 4
  TOP    = 8

  macro dooutcode(oc, mx, my)
    {{oc}} = 0
    if ({{my}} < 0)
      {{oc}} |= TOP
    elsif ({{my}} >= CDoom.f_h)
      {{oc}} |= BOTTOM
    end
    if ({{mx}} < 0)
      {{oc}} |= LEFT
    elsif ({{mx}} >= CDoom.f_w)
      {{oc}} |= RIGHT
    end
  end

  #
  # Automap clipping of lines.
  #
  # Based on Cohen-Sutherland clipping algorithm but with a slightly
  # faster reject and precalculated slopes.  If the speed is needed,
  # use a hash algorithm to handle  the common cases.
  #
  def self.am_clip_mline(ml : CDoom::Mline*, fl : CDoom::Fline*) : CDoom::DoomBool
    outcode1 = 0
    outcode2 = 0
    outside = 0

    tmp = CDoom::Fpoint.new
    dx = 0
    dy = 0

    # do trivial rejects and outcodes
    if ml.value.a.y > CDoom.m_y2
      outcode1 = TOP
    elsif ml.value.a.y < CDoom.m_y
      outcode1 = BOTTOM
    end

    if ml.value.b.y > CDoom.m_y2
      outcode2 = TOP
    elsif ml.value.b.y < CDoom.m_y
      outcode2 = BOTTOM
    end

    return 0 if (outcode1 & outcode2) != 0 # trivially outside

    if ml.value.a.x < CDoom.m_x
      outcode1 |= LEFT
    elsif ml.value.a.x > CDoom.m_x2
      outcode1 |= RIGHT
    end

    if ml.value.b.x < CDoom.m_x
      outcode2 |= LEFT
    elsif ml.value.b.x > CDoom.m_x2
      outcode2 |= RIGHT
    end

    return 0 if (outcode1 & outcode2) != 0 # trivially outside

    # transform to frame-buffer coodinates.
    fl.value.a.x = cxmtof(ml.value.a.x)
    fl.value.a.y = cymtof(ml.value.a.y)
    fl.value.b.x = cxmtof(ml.value.b.x)
    fl.value.b.y = cymtof(ml.value.b.y)

    dooutcode(outcode1, fl.value.a.x, fl.value.a.y)
    dooutcode(outcode2, fl.value.b.x, fl.value.b.y)

    return 0 if (outcode1 & outcode2) != 0

    while (outcode1 | outcode2) != 0
      # may be partially inside box
      # find an outside point
      if outcode1 != 0
        outside = outcode1
      else
        outside = outcode2
      end

      # clip to each side
      if outside & TOP != 0
        dy = fl.value.a.y - fl.value.b.y
        dx = fl.value.b.x - fl.value.a.x
        tmp.x = fl.value.a.x + (dx * fl.value.a.y) // dy
        tmp.y = 0
      elsif outside & BOTTOM != 0
        dy = fl.value.a.y - fl.value.b.y
        dx = fl.value.b.x - fl.value.a.x
        tmp.x = fl.value.a.x + (dx * (fl.value.a.y - CDoom.f_h)) // dy
        tmp.y = CDoom.f_h - 1
      elsif outside & RIGHT != 0
        dy = fl.value.b.y - fl.value.a.y
        dx = fl.value.b.x - fl.value.a.x
        tmp.y = fl.value.a.y + (dy * (CDoom.f_w - 1 - fl.value.a.x)) // dx
        tmp.x = CDoom.f_w - 1
      elsif outside & LEFT != 0
        dy = fl.value.b.y - fl.value.a.y
        dx = fl.value.b.x - fl.value.a.x
        tmp.y = fl.value.a.y + (dy * (-fl.value.a.x)) // dx
        tmp.x = 0
      end

      if outside == outcode1
        fl.value.a = tmp
        dooutcode(outcode1, fl.value.a.x, fl.value.a.y)
      else
        fl.value.b = tmp
        dooutcode(outcode2, fl.value.b.x, fl.value.b.y)
      end

      return 0 if (outcode1 & outcode2) != 0 # trivially outside
    end

    return 1
  end

  macro putdot(xx, yy, cc)
    CDoom.fb[{{yy}}*CDoom.f_w+{{xx}}]={{cc}}
  end

  @@fuck = 0

  #
  # Classic Bresenham w/ whatever optimizations needed for speed
  #
  def self.am_draw_fline(fl : CDoom::Fline*, color : Int32)
    x = 0
    y = 0
    dx = 0
    dy = 0
    sx = 0
    sy = 0
    ax = 0
    ay = 0
    d = 0

    # For debugging only
    {% if false %}
      # [pd] Don't waste CPU cycles testing this then
      if (fl.value.a.x < 0 || fl.value.a.x >= CDoom.f_w ||
         fl.value.a.y < 0 || fl.value.a.y >= CDoom.f_h ||
         fl.value.b.x < 0 || fl.value.b.x >= CDoom.f_w ||
         fl.value.b.y < 0 || fl.value.b.y >= CDoom.f_h)
        print "fuck #{fuck}\r"
        @@fuck += 1
        return
      end
    {% end %}

    dx = fl.value.b.x - fl.value.a.x
    ax = 2 * (dx < 0 ? -dx : dx)
    sx = dx < 0 ? -1 : 1

    dy = fl.value.b.y - fl.value.a.y
    ay = 2 * (dy < 0 ? -dy : dy)
    sy = dy < 0 ? -1 : 1

    x = fl.value.a.x
    y = fl.value.a.y

    if ax > ay
      d = ay - ax // 2
      while true
        putdot(x, y, color.to_u8!)
        return if x == fl.value.b.x
        if d >= 0
          y += sy
          d -= ax
        end
        x += sx
        d += ay
      end
    else
      d = ax - ay // 2
      while true
        putdot(x, y, color.to_u8!)
        return if y == fl.value.b.y
        if d >= 0
          x += sx
          d -= ay
        end
        y += sy
        d += ax
      end
    end
  end

  @@fl : CDoom::Fline* = Pointer(CDoom::Fline).malloc

  #
  # Clip lines, draw visible part sof lines.
  #
  def self.am_draw_mline(ml : CDoom::Mline*, color : Int32)
    if CDoom.am_clip_mline(ml, @@fl) != 0
      CDoom.am_draw_fline(@@fl, color)
    end
  end

  #
  # Draws flat (floor/ceiling tile) aligned grid lines.
  #
  def self.am_draw_grid(color : Int32)
    # Figure out start of vertical gridlines
    start = CDoom.m_x
    ml = CDoom::Mline.new

    if (start - CDoom.bmaporgx).remainder(CDoom::MAPBLOCKUNITS << FRACBITS) != 0
      start += (CDoom::MAPBLOCKUNITS << FRACBITS) -
               (start - CDoom.bmaporgx).remainder(CDoom::MAPBLOCKUNITS << FRACBITS)
    end
    en = CDoom.m_x + CDoom.m_w

    # draw vertical gridlines
    ml.a.y = CDoom.m_y
    ml.b.y = CDoom.m_y + CDoom.m_h
    x = start
    while x < en
      ml.a.x = x
      ml.b.x = x
      CDoom.am_draw_mline(pointerof(ml), color)
      x += CDoom::MAPBLOCKUNITS << FRACBITS
    end

    # Figure out start of horizontal gridlines
    start = CDoom.m_y
    if (start - CDoom.bmaporgy) % (CDoom::MAPBLOCKUNITS << FRACBITS)
      start += (CDoom::MAPBLOCKUNITS << FRACBITS) -
               ((start - CDoom.bmaporgy) % (CDoom::MAPBLOCKUNITS << FRACBITS))
    end
    en = CDoom.m_y + CDoom.m_h

    # draw horizontal gridlines
    ml.a.x = CDoom.m_x
    ml.b.x = CDoom.m_x + CDoom.m_w
    y = start
    while y < en
      ml.a.y = y
      ml.b.y = y
      CDoom.am_draw_mline(pointerof(ml), color)
      y += (CDoom::MAPBLOCKUNITS << FRACBITS)
    end
  end

  @@l : CDoom::Mline = CDoom::Mline.new
  @@l

  #
  # Determines visible lines, draws them.
  # This is LineDef based, not LineSeg based.
  #
  def self.am_draw_walls
    CDoom.numlines.times do |i|
      @@l.a.x = CDoom.lines[i].v1.value.x
      @@l.a.y = CDoom.lines[i].v1.value.y
      @@l.b.x = CDoom.lines[i].v2.value.x
      @@l.b.y = CDoom.lines[i].v2.value.y
      if CDoom.cheating != 0 || (CDoom.lines[i].flags & CDoom::ML_MAPPED) != 0
        next if (CDoom.lines[i].flags & CDoom::LINE_NEVERSEE) != 0 && CDoom.cheating == 0
        if CDoom.lines[i].backsector.null?
          CDoom.am_draw_mline(pointerof(@@l), CDoom::WALLCOLORS + CDoom.lightlev)
        else
          if CDoom.lines[i].special == 39
            # teleporters
            CDoom.am_draw_mline(pointerof(@@l), CDoom::WALLCOLORS + CDoom::WALLRANGE // 2)
          elsif CDoom.lines[i].flags & CDoom::ML_SECRET != 0 # secret door
            if CDoom.cheating != 0
              CDoom.am_draw_mline(pointerof(@@l), CDoom::SECRETWALLCOLORS + CDoom.lightlev)
            else
              CDoom.am_draw_mline(pointerof(@@l), CDoom::WALLCOLORS + CDoom.lightlev)
            end
          elsif CDoom.lines[i].backsector.value.floorheight != CDoom.lines[i].frontsector.value.floorheight
            CDoom.am_draw_mline(pointerof(@@l), CDoom::FDWALLCOLORS + CDoom.lightlev) # floor level change
          elsif CDoom.lines[i].backsector.value.ceilingheight != CDoom.lines[i].frontsector.value.ceilingheight
            CDoom.am_draw_mline(pointerof(@@l), CDoom::CDWALLCOLORS + CDoom.lightlev) # ceiling level change
          elsif CDoom.cheating != 0
            CDoom.am_draw_mline(pointerof(@@l), CDoom::TSWALLCOLORS + CDoom.lightlev)
          end
        end
      elsif CDoom.plr.value.powers[CDoom::Powertype::Allmap.value] != 0
        CDoom.am_draw_mline(pointerof(@@l), CDoom::GRAYS + 3) if CDoom.lines[i].flags & CDoom::LINE_NEVERSEE == 0
      end
    end
  end

  #
  # Rotation in 2D.
  # Used to rotate player arrow line character.
  #
  def self.am_rotate(x : CDoom::Fixed*, y : CDoom::Fixed*, a : CDoom::Angle)
    tmpx = CDoom.fixed_mul(x.value, @@finecosine[a >> CDoom::ANGLETOFINESHIFT]) -
           CDoom.fixed_mul(y.value, @@finesine[a >> CDoom::ANGLETOFINESHIFT])

    y.value = CDoom.fixed_mul(x.value, @@finesine[a >> CDoom::ANGLETOFINESHIFT]) +
              CDoom.fixed_mul(y.value, @@finecosine[a >> CDoom::ANGLETOFINESHIFT])

    x.value = tmpx
  end

  def self.am_draw_line_character(lineguy : CDoom::Mline*,
                                  lineguylines : Int32,
                                  scale : CDoom::Fixed,
                                  angle : CDoom::Angle,
                                  color : Int32,
                                  x : CDoom::Fixed,
                                  y : CDoom::Fixed)
    l = CDoom::Mline.new
    lineguylines.times do |i|
      ax = lineguy[i].a.x
      ay = lineguy[i].a.y

      if scale != 0
        ax = CDoom.fixed_mul(scale, ax)
        ay = CDoom.fixed_mul(scale, ay)
      end

      l.a = CDoom::Mpoint.new(x: ax, y: ay)

      CDoom.am_rotate(
        pointerof(l.@a.@x),
        pointerof(l.@a.@y),
        angle) if angle != 0

      l.a = CDoom::Mpoint.new(x: l.a.x + x, y: l.a.y + y)

      bx = lineguy[i].b.x
      by = lineguy[i].b.y

      if scale != 0
        bx = CDoom.fixed_mul(scale, bx)
        by = CDoom.fixed_mul(scale, by)
      end

      l.b = CDoom::Mpoint.new(x: bx, y: by)

      CDoom.am_rotate(
        pointerof(l.@b.@x),
        pointerof(l.@b.@y),
        angle) if angle != 0

      l.b = CDoom::Mpoint.new(x: l.b.x + x, y: l.b.y + y)

      CDoom.am_draw_mline(pointerof(l), color)
    end
  end

  def self.am_draw_players
    p : CDoom::Player* = Pointer(CDoom::Player).null
    their_colors = [CDoom::GREENS, CDoom::GRAYS, CDoom::BROWNS, CDoom::REDS]
    their_color = -1
    color = 0

    if CDoom.netgame == 0
      if CDoom.cheating != 0
        CDoom.am_draw_line_character(
          CDoom.cheat_player_arrow, CDoom::NUMCHEATPLYRLINES, 0,
          CDoom.plr.value.mo.value.angle, CDoom::WHITE,
          CDoom.plr.value.mo.value.x, CDoom.plr.value.mo.value.y
        )
      else
        CDoom.am_draw_line_character(
          CDoom.player_arrow, CDoom::NUMPLYRLINES, 0, CDoom.plr.value.mo.value.angle,
          CDoom::WHITE, CDoom.plr.value.mo.value.x, CDoom.plr.value.mo.value.y
        )
      end
      return
    end

    CDoom::MAXPLAYERS.times do |i|
      their_color += 1
      p = CDoom.players.to_unsafe + i

      next if (CDoom.deathmatch != 0 && CDoom.singledemo == 0) && p != CDoom.plr
      next if CDoom.playeringame[i] == 0

      if p.value.powers[CDoom::Powertype::Invisibility.value] != 0
        color = 246 # *close* to black
      else
        color = their_colors[their_color]
      end

      CDoom.am_draw_line_character(
        CDoom.player_arrow, CDoom::NUMPLYRLINES, 0, p.value.mo.value.angle,
        color, p.value.mo.value.x, p.value.mo.value.y
      )
    end
  end

  def self.am_draw_things(colors : Int32, colorrange : Int32)
    CDoom.numsectors.times do |i|
      t = CDoom.sectors[i].thinglist
      until t.null?
        CDoom.am_draw_line_character(
          CDoom.thintriangle_guy, CDoom::NUMTHINTRIANGLEGUYLINES,
          16 << FRACBITS, t.value.angle, colors + CDoom.lightlev,
          t.value.x, t.value.y
        )
        t = t.value.snext
      end
    end
  end

  def self.am_draw_marks
    CDoom::AM_NUMMARKPOINTS.times do |i|
      if CDoom.markpoints[i].x != -1
        # w = CDoom.marknums[i].value.width.to_i16!
        # h = CDoom.marknums[i].value.height.to_i16!
        w = 5 # because somethings wrong with the wad, i guess
        h = 6 # because somethings wrong with the wad, i guess
        fx = cxmtof(CDoom.markpoints[i].x)
        fy = cymtof(CDoom.markpoints[i].y)
        if fx >= CDoom.f_x && fx <= CDoom.f_w - w && fy >= CDoom.f_y && fy <= CDoom.f_h - h
          CDoom.v_draw_patch(fx, fy, CDoom::FB, CDoom.marknums[i])
        end
      end
    end
  end

  def self.am_draw_crosshair(color : Int32)
    CDoom.fb[(CDoom.f_w * (CDoom.f_h + 1)) // 2] = color.to_u8! # single point for now
  end

  def self.am_drawer
    return if CDoom.automapactive == 0

    CDoom.am_clear_fb(CDoom::BACKGROUND)
    CDoom.am_draw_grid(CDoom::GRIDCOLORS) if CDoom.grid != 0
    CDoom.am_draw_walls
    CDoom.am_draw_players
    CDoom.am_draw_things(CDoom::THINGCOLORS, CDoom::THINGRANGE) if CDoom.cheating == 2
    CDoom.am_draw_crosshair(CDoom::XHAIRCOLORS)

    CDoom.am_draw_marks

    CDoom.v_mark_rect(CDoom.f_x, CDoom.f_y, CDoom.f_w, CDoom.f_h)
  end
end
