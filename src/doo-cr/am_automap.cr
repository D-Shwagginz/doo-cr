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
# ==> The automap code

module Doocr
  def self.am_activate_new_scale
    CDoom.m_x += CDoom.m_w // 2
    CDoom.m_y += CDoom.m_h // 2
    CDoom.m_w = ftom(Doocr.f_w)
    CDoom.m_h = ftom(Doocr.f_h)
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
    if Doocr.followplayer == 0
      CDoom.m_x = CDoom.old_m_x
      CDoom.m_y = CDoom.old_m_y
    else
      CDoom.m_x = CDoom.plr.value.mo.value.x - CDoom.m_w // 2
      CDoom.m_y = CDoom.plr.value.mo.value.y - CDoom.m_h // 2
    end
    CDoom.m_x2 = CDoom.m_x + CDoom.m_w
    CDoom.m_y2 = CDoom.m_y + CDoom.m_h

    # Change the scaling multipliers
    Doocr.scale_mtof = CDoom.fixed_div(Doocr.f_w << FRACBITS, CDoom.m_w)
    Doocr.scale_ftom = CDoom.fixed_div(FRACUNIT, Doocr.scale_mtof)
  end

  #
  # adds a marker at the current location
  #
  def self.am_add_mark
    @@markpoints[Doocr.markpointnum].x = CDoom.m_x + CDoom.m_w // 2
    @@markpoints[Doocr.markpointnum].y = CDoom.m_y + CDoom.m_h // 2
    Doocr.markpointnum = (Doocr.markpointnum + 1) % CDoom::AM_NUMMARKPOINTS
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

    Doocr.numvertexes.times do |i|
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

    a = CDoom.fixed_div(Doocr.f_w << FRACBITS, CDoom.max_w)
    b = CDoom.fixed_div(Doocr.f_h << FRACBITS, CDoom.max_h)

    CDoom.min_scale_mtof = a < b ? a : b
    CDoom.max_scale_mtof = CDoom.fixed_div(Doocr.f_h << FRACBITS, 2 * CDoom::PLAYERRADIUS)
  end

  def self.am_change_window_loc
    if @@m_paninc.x != 0 || @@m_paninc.y != 0
      Doocr.followplayer = 0
      @@f_oldloc.x = Int32::MAX
    end

    CDoom.m_x += @@m_paninc.x
    CDoom.m_y += @@m_paninc.y

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

    Doocr.automapactive = 1
    CDoom.fb = CDoom.screens[0]
    @@f_oldloc.x = Int32::MAX
    Doocr.amclock = 0
    Doocr.lightlev = 0

    @@m_paninc.x = 0
    @@m_paninc.y = 0
    CDoom.ftom_zoommul = FRACUNIT
    CDoom.mtof_zoommul = FRACUNIT

    CDoom.m_w = ftom(Doocr.f_w)
    CDoom.m_h = ftom(Doocr.f_h)

    pnum = Doocr.consoleplayer
    # find player to center on initially
    if Doocr.playeringame[pnum] == 0
      CDoom::MAXPLAYERS.times do |i|
        pnum = i
        break if Doocr.playeringame[pnum] != 0
      end
    end

    CDoom.plr = @@players.to_unsafe.as(CDoom::Player*) + pnum
    CDoom.m_x = CDoom.plr.value.mo.value.x - CDoom.m_w // 2
    CDoom.m_y = CDoom.plr.value.mo.value.y - CDoom.m_h // 2
    am_change_window_loc

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
      @@markpoints[i].x = -1
    end
    Doocr.markpointnum = 0
  end

  #
  # should be called at the start of every level
  # right now, i figure it out myself
  #
  def self.am_level_init
    Doocr.leveljuststarted = 0

    Doocr.f_x = 0
    Doocr.f_y = 0
    Doocr.f_w = Doocr.finit_width
    Doocr.f_h = Doocr.finit_height

    am_clear_marks

    am_find_min_max_boundaries
    Doocr.scale_mtof = CDoom.fixed_div(CDoom.min_scale_mtof, (0.7 * FRACUNIT).to_i32!)
    Doocr.scale_mtof = CDoom.min_scale_mtof if Doocr.scale_mtof > CDoom.max_scale_mtof
    Doocr.scale_ftom = CDoom.fixed_div(FRACUNIT, Doocr.scale_mtof)
  end

  def self.am_stop
    @@st_notify.type = CDoom::Evtype.new(0)
    @@st_notify.data1 = CDoom::Evtype::Keyup.value
    @@st_notify.data2 = CDoom::AM_MSGENTERED

    am_unload_pics
    Doocr.automapactive = 0
    CDoom.st_responder(pointerof(@@st_notify))
    Doocr.stopped = 1
  end

  def self.am_start
    am_stop if Doocr.stopped == 0
    Doocr.stopped = 0
    if @@lastlevel != Doocr.gamemap || @@lastepisode != Doocr.gameepisode
      am_level_init
      @@lastlevel = Doocr.gamemap
      @@lastepisode = Doocr.gameepisode
    end
    am_init_variables
    am_load_pics
  end

  #
  # set the window scale to the maximum size
  #
  def self.am_min_out_window_scale
    Doocr.scale_mtof = CDoom.min_scale_mtof
    Doocr.scale_ftom = CDoom.fixed_div(FRACUNIT, Doocr.scale_mtof)
    am_activate_new_scale
  end

  #
  # set the window scale to the minimum size
  #
  def self.am_max_out_window_scale
    Doocr.scale_mtof = CDoom.max_scale_mtof
    Doocr.scale_ftom = CDoom.fixed_div(FRACUNIT, Doocr.scale_mtof)
    am_activate_new_scale
  end

  #
  # Handle events (user inputs) in automap mode
  #
  def self.am_responder(ev : CDoom::Event*) : CDoom::DoomBool
    rc = 0

    if Doocr.automapactive == 0
      if ev.value.type == CDoom::Evtype::Keydown && ev.value.data1 == CDoom::AM_STARTKEY
        am_start
        Doocr.viewactive = 0
        rc = 1
      end
    elsif ev.value.type == CDoom::Evtype::Keydown
      rc = 1
      case ev.value.data1
      when CDoom::AM_PANRIGHTKEY # pan right
        if Doocr.followplayer == 0
          @@m_paninc.x = ftom(CDoom::F_PANINC)
        else
          rc = 0
        end
      when CDoom::AM_PANLEFTKEY # pan left
        if Doocr.followplayer == 0
          @@m_paninc.x = -ftom(CDoom::F_PANINC)
        else
          rc = 0
        end
      when CDoom::AM_PANUPKEY # pan up
        if Doocr.followplayer == 0
          @@m_paninc.y = ftom(CDoom::F_PANINC)
        else
          rc = 0
        end
      when CDoom::AM_PANDOWNKEY # pan down
        if Doocr.followplayer == 0
          @@m_paninc.y = -ftom(CDoom::F_PANINC)
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
        Doocr.viewactive = 1
        am_stop
      when CDoom::AM_GOBIGKEY
        @@bigstate = @@bigstate != 0 ? 0 : 1
        if @@bigstate != 0
          am_save_scale_and_loc
          am_min_out_window_scale
        else
          am_restore_scale_and_loc
        end
      when CDoom::AM_FOLLOWKEY
        Doocr.followplayer = Doocr.followplayer != 0 ? 0 : 1
        if Doocr.followplayer != 0 # Neat fix!
          @@m_paninc.x = 0
          @@m_paninc.y = 0
        end
        @@f_oldloc.x = Int32::MAX
        CDoom.plr.value.message = Doocr.followplayer != 0 ? @@deh_amstr_followon : @@deh_amstr_followoff
      when CDoom::AM_GRIDKEY
        Doocr.grid = Doocr.grid != 0 ? 0 : 1
        CDoom.plr.value.message = Doocr.grid != 0 ? @@deh_amstr_gridon : @@deh_amstr_gridoff
      when CDoom::AM_MARKKEY
        CDoom.plr.value.message = "#{@@deh_amstr_markedspot} #{Doocr.markpointnum}"
        am_add_mark
      when CDoom::AM_CLEARMARKKEY
        am_clear_marks
        CDoom.plr.value.message = @@deh_amstr_markscleared
      else
        @@cheatstate = 0
        rc = 0
      end
      if Doocr.netgame == 0 && Doocr.cht_check_cheat(Doocr.cheat_amap, ev.value.data1.to_u8!) != 0
        rc = 0
        Doocr.cheating = (Doocr.cheating + 1) % 3
      end
    elsif ev.value.type == CDoom::Evtype::Keyup
      rc = 0
      case ev.value.data1
      when CDoom::AM_PANRIGHTKEY
        @@m_paninc.x = 0 if Doocr.followplayer == 0
      when CDoom::AM_PANLEFTKEY
        @@m_paninc.x = 0 if Doocr.followplayer == 0
      when CDoom::AM_PANUPKEY
        @@m_paninc.y = 0 if Doocr.followplayer == 0
      when CDoom::AM_PANDOWNKEY
        @@m_paninc.y = 0 if Doocr.followplayer == 0
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
    Doocr.scale_mtof = CDoom.fixed_mul(Doocr.scale_mtof, CDoom.mtof_zoommul)
    Doocr.scale_ftom = CDoom.fixed_div(FRACUNIT, Doocr.scale_mtof)

    if Doocr.scale_mtof < CDoom.min_scale_mtof
      am_min_out_window_scale
    elsif Doocr.scale_mtof > CDoom.max_scale_mtof
      am_max_out_window_scale
    else
      am_activate_new_scale
    end
  end

  def self.am_do_follow_player
    if @@f_oldloc.x != CDoom.plr.value.mo.value.x || @@f_oldloc.y != CDoom.plr.value.mo.value.y
      CDoom.m_x = ftom(mtof(CDoom.plr.value.mo.value.x)) - CDoom.m_w // 2
      CDoom.m_y = ftom(mtof(CDoom.plr.value.mo.value.y)) - CDoom.m_h // 2
      CDoom.m_x2 = CDoom.m_x + CDoom.m_w
      CDoom.m_y2 = CDoom.m_y + CDoom.m_h
      @@f_oldloc.x = CDoom.plr.value.mo.value.x
      @@f_oldloc.y = CDoom.plr.value.mo.value.y
    end
  end

  def self.am_update_light_lev
    # Change light level
    if Doocr.amclock > @@nexttic
      Doocr.lightlev = @@litelevels[@@litelevelscnt]
      @@litelevelscnt += 1
      @@litelevelscnt = 0 if @@litelevelscnt == @@litelevels.size
      @@nexttic = Doocr.amclock + 6 - (Doocr.amclock % 6)
    end
  end

  #
  # Updates on Game Tick
  #
  def self.am_ticker
    return if Doocr.automapactive == 0

    Doocr.amclock += 1

    am_do_follow_player if Doocr.followplayer != 0

    # Change the zoom if necessary
    am_change_window_scale if CDoom.ftom_zoommul != FRACUNIT

    # Change x,y location
    am_change_window_loc if @@m_paninc.x != 0 || @@m_paninc.y != 0

    # Update light level
    # Lighting is updated by the status bar path.
  end

  #
  # Clear automap frame buffer.
  #
  def self.am_clear_fb(color : Int32)
    CDoom.doom_memset(CDoom.fb, color, Doocr.f_w * Doocr.f_h)
  end

  LEFT   = 1
  RIGHT  = 2
  BOTTOM = 4
  TOP    = 8

  macro dooutcode(oc, mx, my)
    {{oc}} = 0
    if ({{my}} < 0)
      {{oc}} |= TOP
    elsif ({{my}} >= Doocr.f_h)
      {{oc}} |= BOTTOM
    end
    if ({{mx}} < 0)
      {{oc}} |= LEFT
    elsif ({{mx}} >= Doocr.f_w)
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
  def self.am_clip_mline(ml : Mline, fl : Fline) : CDoom::DoomBool
    ma = ml.a.not_nil!
    mb = ml.b.not_nil!
    fa = fl.a.not_nil!
    fb = fl.b.not_nil!
    outcode1 = 0
    outcode2 = 0
    outside = 0

    tmp = Fpoint.new
    dx = 0
    dy = 0

    # do trivial rejects and outcodes
    if ma.y > CDoom.m_y2
      outcode1 = TOP
    elsif ma.y < CDoom.m_y
      outcode1 = BOTTOM
    end

    if mb.y > CDoom.m_y2
      outcode2 = TOP
    elsif mb.y < CDoom.m_y
      outcode2 = BOTTOM
    end

    return 0 if (outcode1 & outcode2) != 0 # trivially outside

    if ma.x < CDoom.m_x
      outcode1 |= LEFT
    elsif ma.x > CDoom.m_x2
      outcode1 |= RIGHT
    end

    if mb.x < CDoom.m_x
      outcode2 |= LEFT
    elsif mb.x > CDoom.m_x2
      outcode2 |= RIGHT
    end

    return 0 if (outcode1 & outcode2) != 0 # trivially outside

    # transform to frame-buffer coodinates.
    fa.x = cxmtof(ma.x)
    fa.y = cymtof(ma.y)
    fb.x = cxmtof(mb.x)
    fb.y = cymtof(mb.y)

    dooutcode(outcode1, fa.x, fa.y)
    dooutcode(outcode2, fb.x, fb.y)

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
        dy = fa.y - fb.y
        dx = fb.x - fa.x
        tmp.x = fa.x + (dx * fa.y) // dy
        tmp.y = 0
      elsif outside & BOTTOM != 0
        dy = fa.y - fb.y
        dx = fb.x - fa.x
        tmp.x = fa.x + (dx * (fa.y - Doocr.f_h)) // dy
        tmp.y = Doocr.f_h - 1
      elsif outside & RIGHT != 0
        dy = fb.y - fa.y
        dx = fb.x - fa.x
        tmp.y = fa.y + (dy * (Doocr.f_w - 1 - fa.x)) // dx
        tmp.x = Doocr.f_w - 1
      elsif outside & LEFT != 0
        dy = fb.y - fa.y
        dx = fb.x - fa.x
        tmp.y = fa.y + (dy * (-fa.x)) // dx
        tmp.x = 0
      end

      if outside == outcode1
        fa.x = tmp.x
        fa.y = tmp.y
        dooutcode(outcode1, fa.x, fa.y)
      else
        fb.x = tmp.x
        fb.y = tmp.y
        dooutcode(outcode2, fb.x, fb.y)
      end

      return 0 if (outcode1 & outcode2) != 0 # trivially outside
    end

    return 1
  end

  macro putdot(xx, yy, cc)
    CDoom.fb[{{yy}}*Doocr.f_w+{{xx}}]={{cc}}
  end

  @@fuck = 0

  #
  # Classic Bresenham w/ whatever optimizations needed for speed
  #
  def self.am_draw_fline(fl : Fline, color : Int32)
    fa = fl.a.not_nil!
    fb = fl.b.not_nil!
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
      if (fa.x < 0 || fa.x >= Doocr.f_w ||
        fa.y < 0 || fa.y >= Doocr.f_h ||
        fb.x < 0 || fb.x >= Doocr.f_w ||
        fb.y < 0 || fb.y >= Doocr.f_h)
        print "fuck #{fuck}\r"
        @@fuck += 1
        return
      end
    {% end %}

    dx = fb.x - fa.x
    ax = 2 * (dx < 0 ? -dx : dx)
    sx = dx < 0 ? -1 : 1

    dy = fb.y - fa.y
    ay = 2 * (dy < 0 ? -dy : dy)
    sy = dy < 0 ? -1 : 1

    x = fa.x
    y = fa.y

    if ax > ay
      d = ay - ax // 2
      while true
        putdot(x, y, color.to_u8!)
        return if x == fb.x
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
        return if y == fb.y
        if d >= 0
          x += sx
          d -= ay
        end
        y += sy
        d += ax
      end
    end
  end

  @@fl = Fline.new(Fpoint.new, Fpoint.new)

  #
  # Clip lines, draw visible part sof lines.
  #
  def self.am_draw_mline(ml : Mline, color : Int32)
    if am_clip_mline(ml, @@fl) != 0
      am_draw_fline(@@fl, color)
    end
  end

  #
  # Draws flat (floor/ceiling tile) aligned grid lines.
  #
  def self.am_draw_grid(color : Int32)
    # Figure out start of vertical gridlines
    start = CDoom.m_x
    ml = Mline.new(Mpoint.new, Mpoint.new)

    if (start - Doocr.bmaporgx).remainder(CDoom::MAPBLOCKUNITS << FRACBITS) != 0
      start += (CDoom::MAPBLOCKUNITS << FRACBITS) -
               (start - Doocr.bmaporgx).remainder(CDoom::MAPBLOCKUNITS << FRACBITS)
    end
    en = CDoom.m_x + CDoom.m_w

    # draw vertical gridlines
    ml.a.not_nil!.y = CDoom.m_y
    ml.b.not_nil!.y = CDoom.m_y + CDoom.m_h
    x = start
    while x < en
      ml.a.not_nil!.x = x
      ml.b.not_nil!.x = x
      am_draw_mline(ml, color)
      x += CDoom::MAPBLOCKUNITS << FRACBITS
    end

    # Figure out start of horizontal gridlines
    start = CDoom.m_y
    if (start - Doocr.bmaporgy) % (CDoom::MAPBLOCKUNITS << FRACBITS)
      start += (CDoom::MAPBLOCKUNITS << FRACBITS) -
               ((start - Doocr.bmaporgy) % (CDoom::MAPBLOCKUNITS << FRACBITS))
    end
    en = CDoom.m_y + CDoom.m_h

    # draw horizontal gridlines
    ml.a.not_nil!.x = CDoom.m_x
    ml.b.not_nil!.x = CDoom.m_x + CDoom.m_w
    y = start
    while y < en
      ml.a.not_nil!.y = y
      ml.b.not_nil!.y = y
      am_draw_mline(ml, color)
      y += (CDoom::MAPBLOCKUNITS << FRACBITS)
    end
  end

  @@l = Mline.new(Mpoint.new, Mpoint.new)
  @@l

  #
  # Determines visible lines, draws them.
  # This is LineDef based, not LineSeg based.
  #
  def self.am_draw_walls
    Doocr.numlines.times do |i|
      @@l.a.not_nil!.x = CDoom.lines[i].v1.value.x
      @@l.a.not_nil!.y = CDoom.lines[i].v1.value.y
      @@l.b.not_nil!.x = CDoom.lines[i].v2.value.x
      @@l.b.not_nil!.y = CDoom.lines[i].v2.value.y
      if Doocr.cheating != 0 || (CDoom.lines[i].flags & CDoom::ML_MAPPED) != 0
        next if (CDoom.lines[i].flags & CDoom::LINE_NEVERSEE) != 0 && Doocr.cheating == 0
        if CDoom.lines[i].backsector.null?
          am_draw_mline(@@l, CDoom::WALLCOLORS + Doocr.lightlev)
        else
          if CDoom.lines[i].special == 39
            # teleporters
            am_draw_mline(@@l, CDoom::WALLCOLORS + CDoom::WALLRANGE // 2)
          elsif CDoom.lines[i].flags & CDoom::ML_SECRET != 0 # secret door
            if Doocr.cheating != 0
              am_draw_mline(@@l, CDoom::SECRETWALLCOLORS + Doocr.lightlev)
            else
              am_draw_mline(@@l, CDoom::WALLCOLORS + Doocr.lightlev)
            end
          elsif CDoom.lines[i].backsector.value.floorheight != CDoom.lines[i].frontsector.value.floorheight
            am_draw_mline(@@l, CDoom::FDWALLCOLORS + Doocr.lightlev) # floor level change
          elsif CDoom.lines[i].backsector.value.ceilingheight != CDoom.lines[i].frontsector.value.ceilingheight
            am_draw_mline(@@l, CDoom::CDWALLCOLORS + Doocr.lightlev) # ceiling level change
          elsif Doocr.cheating != 0
            am_draw_mline(@@l, CDoom::TSWALLCOLORS + Doocr.lightlev)
          end
        end
      elsif CDoom.plr.value.powers[CDoom::Powertype::Allmap.value] != 0
        am_draw_mline(@@l, CDoom::GRAYS + 3) if CDoom.lines[i].flags & CDoom::LINE_NEVERSEE == 0
      end
    end
  end

  #
  # Rotation in 2D.
  # Used to rotate player arrow line character.
  #
    def self.am_rotate(x : CDoom::Fixed, y : CDoom::Fixed, a : CDoom::Angle) : Tuple(CDoom::Fixed, CDoom::Fixed)
      tmpx = CDoom.fixed_mul(x, @@finecosine[a >> CDoom::ANGLETOFINESHIFT]) -
        CDoom.fixed_mul(y, @@finesine[a >> CDoom::ANGLETOFINESHIFT])
      tmpy = CDoom.fixed_mul(x, @@finesine[a >> CDoom::ANGLETOFINESHIFT]) +
        CDoom.fixed_mul(y, @@finecosine[a >> CDoom::ANGLETOFINESHIFT])
      {tmpx, tmpy}
  end

    def self.am_draw_line_character(lineguy : Array(Mline),
                                  lineguylines : Int32,
                                  scale : CDoom::Fixed,
                                  angle : CDoom::Angle,
                                  color : Int32,
                                  x : CDoom::Fixed,
                                  y : CDoom::Fixed)
    l = Mline.new(Mpoint.new, Mpoint.new)
    lineguylines.times do |i|
      source_a = lineguy[i].a.not_nil!
      source_b = lineguy[i].b.not_nil!
      ax = source_a.x
      ay = source_a.y

      if scale != 0
        ax = CDoom.fixed_mul(scale, ax)
        ay = CDoom.fixed_mul(scale, ay)
      end

      ax, ay = am_rotate(ax, ay, angle) if angle != 0
      l.a.not_nil!.x = ax + x
      l.a.not_nil!.y = ay + y

      bx = source_b.x
      by = source_b.y

      if scale != 0
        bx = CDoom.fixed_mul(scale, bx)
        by = CDoom.fixed_mul(scale, by)
      end

      bx, by = am_rotate(bx, by, angle) if angle != 0
      l.b.not_nil!.x = bx + x
      l.b.not_nil!.y = by + y

      am_draw_mline(l, color)
    end
  end

  def self.am_draw_players
    p : CDoom::Player* = Pointer(CDoom::Player).null
    their_colors = [CDoom::GREENS, CDoom::GRAYS, CDoom::BROWNS, CDoom::REDS]
    their_color = -1
    color = 0

    if Doocr.netgame == 0
      if Doocr.cheating != 0
        am_draw_line_character(
          @@cheat_player_arrow, @@cheat_player_arrow.size, 0,
          CDoom.plr.value.mo.value.angle, CDoom::WHITE,
          CDoom.plr.value.mo.value.x, CDoom.plr.value.mo.value.y
        )
      else
        am_draw_line_character(
          @@player_arrow, @@player_arrow.size, 0, CDoom.plr.value.mo.value.angle,
          CDoom::WHITE, CDoom.plr.value.mo.value.x, CDoom.plr.value.mo.value.y
        )
      end
      return
    end

    CDoom::MAXPLAYERS.times do |i|
      their_color += 1
      p = @@players.to_unsafe + i

      next if (Doocr.deathmatch != 0 && Doocr.singledemo == 0) && p != CDoom.plr
      next if Doocr.playeringame[i] == 0

      if p.value.powers[CDoom::Powertype::Invisibility.value] != 0
        color = 246 # *close* to black
      else
        color = their_colors[their_color]
      end

      am_draw_line_character(
        @@player_arrow, @@player_arrow.size, 0, p.value.mo.value.angle,
        color, p.value.mo.value.x, p.value.mo.value.y
      )
    end
  end

  def self.am_draw_things(colors : Int32, colorrange : Int32)
    Doocr.numsectors.times do |i|
      t = CDoom.sectors[i].thinglist
      until t.null?
        am_draw_line_character(
          @@thintriangle_guy, @@thintriangle_guy.size,
          16 << FRACBITS, t.value.angle, colors + Doocr.lightlev,
          t.value.x, t.value.y
        )
        t = t.value.snext
      end
    end
  end

  def self.am_draw_marks
    CDoom::AM_NUMMARKPOINTS.times do |i|
      if @@markpoints[i].x != -1
        # w = CDoom.marknums[i].value.width.to_i16!
        # h = CDoom.marknums[i].value.height.to_i16!
        w = 5 # because somethings wrong with the wad, i guess
        h = 6 # because somethings wrong with the wad, i guess
        fx = cxmtof(@@markpoints[i].x)
        fy = cymtof(@@markpoints[i].y)
        if fx >= Doocr.f_x && fx <= Doocr.f_w - w && fy >= Doocr.f_y && fy <= Doocr.f_h - h
          CDoom.v_draw_patch(fx, fy, CDoom::FB, CDoom.marknums[i])
        end
      end
    end
  end

  def self.am_draw_crosshair(color : Int32)
    CDoom.fb[(Doocr.f_w * (Doocr.f_h + 1)) // 2] = color.to_u8! # single point for now
  end

  def self.am_drawer
    return if Doocr.automapactive == 0

    am_clear_fb(CDoom::BACKGROUND)
    am_draw_grid(CDoom::GRIDCOLORS.to_i32) if Doocr.grid != 0
    am_draw_walls
    am_draw_players
    am_draw_things(CDoom::THINGCOLORS, CDoom::THINGRANGE) if Doocr.cheating == 2
    am_draw_crosshair(CDoom::XHAIRCOLORS)

    am_draw_marks

    CDoom.v_mark_rect(Doocr.f_x, Doocr.f_y, Doocr.f_w, Doocr.f_h)
  end
end
