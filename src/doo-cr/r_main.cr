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
# ==> Rendering

module Doocr
  def self.r_clear_draw_segs
    Doocr.ds_p = Doocr.drawsegs.to_unsafe
  end

  #
  # Does handle solid walls,
  #  e.g. single sided LineDefs (middle texture)
  #  that entirely block the view.
  #
  def self.r_clip_solid_wall_segment(first : LibC::Int, last : LibC::Int)
    # Find the first range that touches the range
    #  (adjacent pixels are touching).
    start = 0
    while Doocr.solidsegs[start].last < first - 1
      start += 1
    end

    if first < Doocr.solidsegs[start].first
      if last < Doocr.solidsegs[start].first - 1
        # Post is entirely visible (above start),
        #  so insert a new clippost.
        CDoom.r_store_wall_range(first, last)
        nextc = Doocr.newend
        Doocr.newend += 1

        while nextc != start
          Doocr.solidsegs[nextc].first = Doocr.solidsegs[nextc - 1].first
          Doocr.solidsegs[nextc].last = Doocr.solidsegs[nextc - 1].last
          nextc -= 1
        end
        Doocr.solidsegs[nextc].first = first
        Doocr.solidsegs[nextc].last = last
        return
      end

      # There is a fragment above start.value.
      CDoom.r_store_wall_range(first, Doocr.solidsegs[start].first - 1)
      # Now adjust the clip size.
      Doocr.solidsegs[start].first = first
    end

    # Bottom contained in start?
    return if last <= Doocr.solidsegs[start].last

    nextc = start
    crunch = false
    while last >= Doocr.solidsegs[nextc + 1].first - 1
      # There is a fragment between two posts.
      CDoom.r_store_wall_range(Doocr.solidsegs[nextc].last + 1, Doocr.solidsegs[nextc + 1].first - 1)
      nextc += 1

      if last <= Doocr.solidsegs[nextc].last
        # Bottom is contained in next.
        # Adjust the clip size.
        Doocr.solidsegs[start].last = Doocr.solidsegs[nextc].last
        crunch = true
        break
      end
    end

    unless crunch
      # There is a fragment after nextc.value.
      CDoom.r_store_wall_range(Doocr.solidsegs[nextc].last + 1, last)
      # Adjust the clip size.
      Doocr.solidsegs[start].last = last
    end

    # Remove start+1 to next from the clip list,
    # because start now covers their area.
    if nextc == start
      # Post just extended past the bottom of one post.
      return
    end

    while nextc != Doocr.newend - 1
      nextc += 1
      # Remove a post
      start += 1
      Doocr.solidsegs[start].first = Doocr.solidsegs[nextc].first
      Doocr.solidsegs[start].last = Doocr.solidsegs[nextc].last
    end

      Doocr.newend = start + 1
  end

  #
  # Clips the given range of columns,
  #  but does not includes it in the clip list.
  # Does handle windows,
  #  e.g. LineDefs with upper and lower texture.
  #
  def self.r_clip_pass_wall_segment(first : LibC::Int, last : LibC::Int)
    # Find the first range that touches the range
    #  (adjacent pixels are touching).
    start = 0
    while Doocr.solidsegs[start].last < first - 1
      start += 1
    end

    if first < Doocr.solidsegs[start].first
      if last < Doocr.solidsegs[start].first - 1
        # Post is entirely visible (above start).
        CDoom.r_store_wall_range(first, last)
        return
      end
          # There is a fragment above start.value.
      CDoom.r_store_wall_range(first, Doocr.solidsegs[start].first - 1)
    end

    # Bottom contained in start?
    return if last <= Doocr.solidsegs[start].last

    while last >= Doocr.solidsegs[start + 1].first - 1
      # There is a fragment between two posts.
      CDoom.r_store_wall_range(Doocr.solidsegs[start].last + 1, Doocr.solidsegs[start + 1].first - 1)
      start += 1

      return if last <= Doocr.solidsegs[start].last
    end

    # There is a fragment after next.value.
    CDoom.r_store_wall_range(Doocr.solidsegs[start].last + 1, last)
  end

  def self.r_clear_clip_segs
    Doocr.solidsegs[0].first = -0x7fffffff
    Doocr.solidsegs[0].last = -1
    Doocr.solidsegs[1].first = Doocr.viewwidth
    Doocr.solidsegs[1].last = 0x7fffffff
    Doocr.newend = 2
  end

  #
  # Clips the given segment
  # and adds any visible pieces to the line list.
  #
  def self.r_addline(line : CDoom::Seg*)
    Doocr.curline = line

    # OPTIMIZE: quickly reject orthogonal back sides.
    angle1 = CDoom.r_point_to_angle(line.value.v1.value.x, line.value.v1.value.y)
    angle2 = CDoom.r_point_to_angle(line.value.v2.value.x, line.value.v2.value.y)

    # Clip to view edges.
    # OPTIMIZE: make constant out of 2*clipangle (FIELDOFVIEW).
    span = angle1 &- angle2

    # Back side? I.e. backface culling?
    return if span >= ANG180

    # Global angle needed by segcalc.
    Doocr.rw_angle1 = angle1
    angle1 &-= Doocr.viewangle
    angle2 &-= Doocr.viewangle

    tspan = angle1 &+ Doocr.clipangle
    if tspan > 2 &* Doocr.clipangle
      tspan &-= 2 &* Doocr.clipangle

      # Totally off the left edge?
      return if tspan >= span

      angle1 = Doocr.clipangle
    end
    tspan = Doocr.clipangle &- angle2
    if tspan > 2 &* Doocr.clipangle
      tspan &-= 2 &* Doocr.clipangle

      # Totally off the left edge?
      return if tspan >= span

      angle2 = -(Doocr.clipangle.to_i32!)
    end

    # The seg is in the view range,
    # but not necessarily visible.
    angle1 = (angle1 &+ ANG90) >> Doocr::ANGLETOFINESHIFT
    angle2 = (angle2 &+ ANG90) >> Doocr::ANGLETOFINESHIFT
    x1 = Doocr.viewangletox[angle1]
    x2 = Doocr.viewangletox[angle2]

    # Does not cross a pixel?
    return if (x1 == x2)

    Doocr.backsector = line.value.backsector

    # Single sided line?
    if Doocr.backsector.null?
      CDoom.r_clip_solid_wall_segment(x1, x2 - 1)
      return
    end

    # Closed door.
    if Doocr.backsector.value.ceilingheight <= Doocr.frontsector.value.floorheight ||
       Doocr.backsector.value.floorheight >= Doocr.frontsector.value.ceilingheight
      CDoom.r_clip_solid_wall_segment(x1, x2 - 1)
      return
    end

    # Window.
    if Doocr.backsector.value.ceilingheight != Doocr.frontsector.value.ceilingheight ||
       Doocr.backsector.value.floorheight != Doocr.frontsector.value.floorheight
      CDoom.r_clip_pass_wall_segment(x1, x2 - 1)
      return
    end

    # Reject empty lines used for triggers
    #  and special events.
    # Identical floor and ceiling on both sides,
    # identical light levels on both sides,
    # and no middle texture.
    if Doocr.backsector.value.ceilingpic == Doocr.frontsector.value.ceilingpic &&
       Doocr.backsector.value.floorpic == Doocr.frontsector.value.floorpic &&
       Doocr.backsector.value.lightlevel == Doocr.frontsector.value.lightlevel &&
       Doocr.curline.value.sidedef.value.midtexture == 0
      return
    end

    CDoom.r_clip_pass_wall_segment(x1, x2 - 1)
    return
  end

  #
  # Checks BSP node/subtree bounding box.
  # Returns true
  #  if some part of the bbox might be visible.
  #
  def self.r_check_bbox(bspcoord : LibC::Int*) : LibC::Int
    # Find the corners of the box
    # that define the edges from current viewpoint.
    if Doocr.viewx <= bspcoord[Doocr::BOXLEFT]
      boxx = 0
    elsif Doocr.viewx < bspcoord[Doocr::BOXRIGHT]
      boxx = 1
    else
      boxx = 2
    end

    if Doocr.viewy >= bspcoord[Doocr::BOXTOP]
      boxy = 0
    elsif Doocr.viewy > bspcoord[Doocr::BOXBOTTOM]
      boxy = 1
    else
      boxy = 2
    end

    boxpos = (boxy << 2) + boxx
    return 1 if boxpos == 5

    x1 = bspcoord[Doocr.checkcoord[boxpos][0]]
    y1 = bspcoord[Doocr.checkcoord[boxpos][1]]
    x2 = bspcoord[Doocr.checkcoord[boxpos][2]]
    y2 = bspcoord[Doocr.checkcoord[boxpos][3]]

    # check clip list for an open space
    angle1 = CDoom.r_point_to_angle(x1, y1) &- Doocr.viewangle
    angle2 = CDoom.r_point_to_angle(x2, y2) &- Doocr.viewangle

    span = angle1 &- angle2

    # Sitting on a line?
    return 1 if span >= ANG180

    tspan = angle1 &+ Doocr.clipangle

    if tspan > 2 &* Doocr.clipangle
      tspan &-= 2 &* Doocr.clipangle

      # Totally off the left edge?
      return 0 if tspan >= span

      angle1 = Doocr.clipangle
    end
    tspan = Doocr.clipangle &- angle2
    if tspan > 2 &* Doocr.clipangle
      tspan &-= 2 &* Doocr.clipangle

      # Totally off the left edge?
      return 0 if tspan >= span

      angle2 = -(Doocr.clipangle.to_i32!)
    end

    # Find the first clippost
    #  that touches the source post
    #  (adjacent pixels are touching).
    angle1 = (angle1 &+ ANG90) >> Doocr::ANGLETOFINESHIFT
    angle2 = (angle2 &+ ANG90) >> Doocr::ANGLETOFINESHIFT
    sx1 = Doocr.viewangletox[angle1]
    sx2 = Doocr.viewangletox[angle2]

    # Does not cross a pixel.
    return 0 if sx1 == sx2
    sx2 -= 1

    start = 0
    while Doocr.solidsegs[start].last < sx2
      start += 1
    end

    if sx1 >= Doocr.solidsegs[start].first &&
       sx2 <= Doocr.solidsegs[start].last
      # The clippost contains the new span.
      return 0
    end

    return 1
  end

  #
  # Determine floor/ceiling planes.
  # Add sprites of things in sector.
  # Draw one or more line segments.
  #
  def self.r_subsector(num : LibC::Int)
    {% if flag?("RANGECHECK") %}
      if num >= Doocr.numsubsectors
        CDoom.i_error("Error: r_subsector: ss #{num} with numss = #{Doocr.numsubsectors}")
      end
    {% end %}

    Doocr.sscount += 1
    sub = Doocr.subsectors + num
    Doocr.frontsector = sub.value.sector
    count = sub.value.numlines
    line = Doocr.segs + sub.value.firstline

    if Doocr.frontsector.value.floorheight < Doocr.viewz
      @@floorplane = r_find_plane(Doocr.frontsector.value.floorheight,
        Doocr.frontsector.value.floorpic,
        Doocr.frontsector.value.lightlevel)
    else
      @@floorplane = -1
    end

    if Doocr.frontsector.value.ceilingheight > Doocr.viewz ||
       Doocr.frontsector.value.ceilingpic == Doocr.skyflatnum
      @@ceilingplane = r_find_plane(Doocr.frontsector.value.ceilingheight,
        Doocr.frontsector.value.ceilingpic,
        Doocr.frontsector.value.lightlevel)
    else
      @@ceilingplane = -1
    end

    # Ceiling and Floor fix for f_sky1
    if @@ceilingplane == @@floorplane && @@ceilingplane != -1
      @@visplanes << CDoom::Visplane.new if @@lastvisplane == @@visplanes.size - 1
      new_index = @@lastvisplane
      @@lastvisplane += 1
      dst = @@visplanes.to_unsafe + new_index
      src = @@visplanes.to_unsafe + @@floorplane
      dst.value.height = src.value.height
      dst.value.picnum = src.value.picnum
      dst.value.lightlevel = src.value.lightlevel
      dst.value.minx = CDoom::SCREENWIDTH
      dst.value.maxx = -1
      CDoom.doom_memset(dst.value.top, 0xff, sizeof(typeof(dst.value.top)))
      @@ceilingplane = new_index
    end

    CDoom.r_add_sprites(Doocr.frontsector)

    while count != 0
      count -= 1
      CDoom.r_addline(line)
      line += 1
    end
  end

  #
  # Renders all subsectors below a given node,
  #  traversing subtree recursively.
  # Just call with BSP root.
  #
  def self.r_render_bsp_node(bspnum : LibC::Int)
    # Found a subsector?
    if bspnum & Doocr::NF_SUBSECTOR != 0
      if bspnum == -1
        CDoom.r_subsector(0)
      else
        CDoom.r_subsector(bspnum & (~Doocr::NF_SUBSECTOR))
      end
      return
    end

    bsp = Doocr.nodes + bspnum

    # Decide which side the view point is on.
    side = CDoom.r_point_on_side(Doocr.viewx, Doocr.viewy, bsp)

    # Recursively divide front space.
    CDoom.r_render_bsp_node(bsp.value.children[side])

    # Possibly divide back space.
    CDoom.r_render_bsp_node(bsp.value.children[side ^ 1]) if CDoom.r_check_bbox(bsp.value.bbox[side ^ 1]) != 0
  end

  #
  # Graphics.
  # DOOM graphics for walls and sprites
  # is stored in vertical runs of opaque pixels (posts).
  # A column is composed of zero or more posts,
  # a patch or sprite is composed of zero or more columns.
  #

  #
  # MAPTEXTURE_T CACHING
  # When a texture is first needed,
  #  it counts the number of composite columns
  #  required in the texture and allocates space
  #  for a column directory and any new columns.
  # The directory will simply point inside other patches
  #  if there is only one patch in a given column,
  #  but any columns with multiple patches
  #  will have new column_ts generated.
  #

  # Clip and draw a column
  #  from a patch into a cached post.
  def self.r_draw_column_in_cache(patch : CDoom::Post*, cache : UInt8*, originy : LibC::Int, cacheheight : LibC::Int)
    dest = cache + 3

    while patch.value.topdelta != 0xff
      source = patch.as(UInt8*) + 3
      count = patch.value.length
      position = originy + patch.value.topdelta

      if position < 0
        count += position
        position = 0
      end

      count = cacheheight - position if position + count > cacheheight

      CDoom.doom_memcpy(cache + position, source, count) if count > 0

      patch = (patch.as(UInt8*) + patch.value.length + 4).as(CDoom::Post*)
    end
  end

  # Using the texture definition,
  #  the composite texture is created from the patches,
  #  and each column is cached.
  def self.r_generate_composite(texnum : LibC::Int)
    texture = Doocr.textures[texnum]

    block = CDoom.z_malloc(Doocr.texturecompositesize[texnum],
      Doocr::PU_STATIC,
      (Doocr.texturecomposite.to_unsafe + texnum).as(Void*)).as(UInt8*)

    Doocr.texturecomposite[texnum] = block
    collump = Doocr.texturecolumnlump[texnum]
    colofs = Doocr.texturecolumnofs[texnum]

    # Composite the columns together.
    patch = texture.value.patches.to_unsafe

    texture.value.patchcount.times do |i|
      realpatch = CDoom.w_cache_lump_num(patch.value.patch, Doocr::PU_CACHE).as(CDoom::Patch*)
      x1 = patch.value.originx
      x2 = x1 + realpatch.value.width

      if x1 < 0
        x = 0
      else
        x = x1
      end

      x2 = texture.value.width if x2 > texture.value.width

      while x < x2
        # Column does not have multiple patches?
        if collump[x] >= 0
          x += 1
          next
        end

        patchcol = (realpatch.as(UInt8*) + (realpatch.value.columnofs.to_unsafe + (x - x1)).value).as(CDoom::Post*)

        CDoom.r_draw_column_in_cache(patchcol,
          block + colofs[x],
          patch.value.originy,
          texture.value.height)

        x += 1
      end

      patch += 1
    end

    # Now that the texture has been built in column cache,
    #  it is purgable from zone memory.
    z_change_tag(block, Doocr::PU_CACHE)
  end

  def self.r_generate_lookup(texnum : LibC::Int)
    texture = Doocr.textures[texnum]

    # Composited texture not created yet
    Doocr.texturecomposite[texnum] = Pointer(UInt8).null

    Doocr.texturecompositesize[texnum] = 0
    collump = Doocr.texturecolumnlump[texnum]
    colofs = Doocr.texturecolumnofs[texnum]

    # Now count the number of columns
    #  that are covered by more than one patch.
    # Fill in the lump / offset, so columns
    #  with only a single patch are all done.
    patchcount = GC.malloc(texture.value.width.to_i32).as(UInt8*)
    CDoom.doom_memset(patchcount, 0, texture.value.width)
    patch = texture.value.patches.to_unsafe

    texture.value.patchcount.times do |i|
      realpatch = CDoom.w_cache_lump_num(patch.value.patch, Doocr::PU_CACHE).as(CDoom::Patch*)
      x1 = patch.value.originx
      x2 = x1 + realpatch.value.width

      if x1 < 0
        x = 0
      else
        x = x1
      end

      x2 = texture.value.width if x2 > texture.value.width

      while x < x2
        patchcount[x] = patchcount[x] + 1
        collump[x] = patch.value.patch.to_i16!
        colofs[x] = ((realpatch.value.columnofs.to_unsafe + (x - x1)).value + 3).to_u16!

        x += 1
      end

      patch += 1
    end

    texture.value.width.times do |x|
      if patchcount[x] == 0
        puts "r_generate_lookup: column without a patch (#{String.new(texture.value.name.to_unsafe)})"
        return
      end

      if patchcount[x] > 1
        # Use the cached block.
        collump[x] = -1
        colofs[x] = Doocr.texturecompositesize[texnum].to_u16!

        if Doocr.texturecompositesize[texnum] > 0x10000 - texture.value.height
          CDoom.i_error("Error: r_generate_lookup: texture #{texnum} is >64k")
        end

        Doocr.texturecompositesize[texnum] = Doocr.texturecompositesize[texnum] + texture.value.height
      end
    end

    GC.free(patchcount.as(Void*))
  end

  def self.r_get_column(tex : LibC::Int, col : LibC::Int) : UInt8*
    col &= Doocr.texturewidthmask[tex]
    lump = Doocr.texturecolumnlump[tex][col]
    ofs = Doocr.texturecolumnofs[tex][col]

    return CDoom.w_cache_lump_num(lump, Doocr::PU_CACHE).as(UInt8*) + ofs if lump > 0

    CDoom.r_generate_composite(tex) if Doocr.texturecomposite[tex].null?

    return Doocr.texturecomposite[tex] + ofs
  end

  #
  # Initializes the texture list
  #  with the textures from the world map.
  #
  def self.r_init_textures
    name = Pointer(UInt8).malloc(9)

    # Load the patch names from pnames.lmp.
    name[8] = 0
    names = CDoom.w_cache_lump_name("PNAMES", Doocr::PU_STATIC).as(UInt8*)
    nummappatches = names.as(Int32*).value
    name_p = names + 4
    patchlookup = GC.malloc(nummappatches * sizeof(Int32)).as(Int32*)

    nummappatches.times do |i|
      CDoom.doom_strncpy(name, name_p + i * 8, 8)
      patchlookup[i] = CDoom.w_check_num_for_name(name)
    end
    CDoom.z_free(names)

    # Load the map texture definitions from textures.lmp.
    # The data is contained in one or two lumps,
    #  TEXTURE1 for shareware, plus TEXTURE2 for commercial.
    maptex = CDoom.w_cache_lump_name("TEXTURE1", Doocr::PU_STATIC).as(Int32*)
    maptex1 = maptex
    numtextures1 = maptex.value
    maxoff = CDoom.w_lump_length(CDoom.w_get_num_for_name("TEXTURE1"))
    directory = maptex + 1

    if CDoom.w_check_num_for_name("TEXTURE2") != -1
      maptex2 = CDoom.w_cache_lump_name("TEXTURE2", Doocr::PU_STATIC).as(Int32*)
      numtextures2 = maptex2.value
      maxoff2 = CDoom.w_lump_length(CDoom.w_get_num_for_name("TEXTURE2"))
    else
      maptex2 = Pointer(Int32).null
      numtextures2 = 0
      maxoff2 = 0
    end
    Doocr.numtextures = numtextures1 + numtextures2

    Doocr.textures.clear
    Doocr.numtextures.times { Doocr.textures << Pointer(CDoom::Texture).null }
    Doocr.texturecolumnlump.clear
    Doocr.texturecolumnofs.clear
    Doocr.texturecomposite.clear
    Doocr.texturecompositesize.clear
    Doocr.texturewidthmask.clear
    Doocr.numtextures.times do
      Doocr.texturecolumnlump << Pointer(Int16).null
      Doocr.texturecolumnofs << Pointer(UInt16).null
      Doocr.texturecomposite << Pointer(UInt8).null
      Doocr.texturecompositesize << 0
      Doocr.texturewidthmask << 0
    end
    Doocr.textureheight.clear
    Doocr.numtextures.times { Doocr.textureheight << 0 }

    totalwidth = 0

    Doocr.numtextures.times do |i|
      print "." if i & 63 == 0

      if i == numtextures1
        # Start looking in second texture file.
        maptex = maptex2
        maxoff = maxoff2
        directory = maptex + 1
      end

      offset = directory.value

      CDoom.i_error("Error: r_init_textures: bad texture directory") if offset > maxoff

      mtexture = (maptex.as(UInt8*) + offset).as(CDoom::Maptexture*)

      texture = CDoom.z_malloc(sizeof(CDoom::Texture) +
                               sizeof(CDoom::Texpatch) * (mtexture.value.patchcount - 1),
        Doocr::PU_STATIC, Pointer(Void).null).as(CDoom::Texture*)
      Doocr.textures[i] = texture

      texture.value.width = mtexture.value.width
      texture.value.height = mtexture.value.height
      texture.value.patchcount = mtexture.value.patchcount

      CDoom.doom_memcpy(texture.value.name, mtexture.value.name, sizeof(typeof(texture.value.name)))
      mpatch = mtexture.value.patches.to_unsafe
      patch = texture.value.patches.to_unsafe

      texture.value.patchcount.times do |j|
        patch.value.originx = mpatch.value.originx
        patch.value.originy = mpatch.value.originy
        patch.value.patch = patchlookup[mpatch.value.patch]
        if patch.value.patch == -1
          CDoom.i_error("Error: r_init_textures: Missing patch in texture #{String.new(texture.value.name.to_unsafe, 8)}")
        end

        mpatch += 1
        patch += 1
      end
      Doocr.texturecolumnlump[i] = CDoom.z_malloc(texture.value.width * sizeof(Int16), Doocr::PU_STATIC, Pointer(Void).null).as(Int16*)
      Doocr.texturecolumnofs[i] = CDoom.z_malloc(texture.value.width * sizeof(UInt16), Doocr::PU_STATIC, Pointer(Void).null).as(UInt16*)

      j = 1
      while j * 2 <= texture.value.width
        j <<= 1
      end

      Doocr.texturewidthmask[i] = j - 1
      Doocr.textureheight[i] = texture.value.height.to_i32 << FRACBITS

      totalwidth += texture.value.width
      directory += 1
    end

    CDoom.z_free(maptex1)
    CDoom.z_free(maptex2) unless maptex2.null?

    # Precalculate whatever possible.
    Doocr.numtextures.times { |i| CDoom.r_generate_lookup(i) }

    # Create translation table for global animation.
    Doocr.texturetranslation.clear
    (Doocr.numtextures + 1).times { Doocr.texturetranslation << 0 }

    Doocr.numtextures.times { |i| Doocr.texturetranslation[i] = i }

    GC.free(patchlookup.as(Void*))
  end

  def self.r_init_flats
    # Create translation table for global animation.
    Doocr.flattranslation.clear
    (Doocr.numflats + 1).times { Doocr.flattranslation << 0 }

    Doocr.numflats.times do |i|
      print "." if i & 63 == 0
      Doocr.flattranslation[i] = i
    end
  end

  #
  # Finds the width and hoffset of all sprites in the wad,
  #  so the sprite does not need to be cached completely
  #  just for having the header info ready during rendering.
  #
  def self.r_init_sprite_lumps
    Doocr.spritewidth.clear
    Doocr.spriteoffset.clear
    Doocr.spritetopoffset.clear

    Doocr.numspritelumps.times do |i|
      print "." if i & 63 == 0

      patch = CDoom.w_cache_lump_num(Doocr.firstspritelump + i, Doocr::PU_CACHE).as(CDoom::Patch*)
      Doocr.spritewidth << (patch.value.width.to_i32 << FRACBITS)
      Doocr.spriteoffset << (patch.value.leftoffset.to_i32 << FRACBITS)
      Doocr.spritetopoffset << (patch.value.topoffset.to_i32 << FRACBITS)
    end
  end

  def self.r_init_colormaps
    # Load in the light tables,
    #  256 byte align tables.
    lump = CDoom.w_get_num_for_name("COLORMAP")
    length = CDoom.w_lump_length(lump) + 255
    Doocr.colormaps = CDoom.z_malloc(length, Doocr::PU_STATIC, Pointer(Void).null).as(UInt8*)
    Doocr.colormaps = Pointer(UInt8).new(((Doocr.colormaps.address + 255) & ~0xff))
    CDoom.w_read_lump(lump, Doocr.colormaps)
  end

  def self.r_order_lump_section(starts : Array(String), ends : Array(String))
    # Musical lumps!

    # Find all lump sections
    sections = [] of Tuple(Int32, Int32)
    start = -1
    @@lumpinfo.each_with_index do |lump, i|
      starts.each do |s|
        if lump.name.downcase.delete('\0') == s.downcase
          start = i
          break
        end
      end

      if start != 1
        ends.each do |e|
          if lump.name.downcase.delete('\0') == e.downcase
            sections << {start, i}
            start = -1
          end
        end
      end
    end

    lumps = [] of Array(Lumpinfo)
    # Reverse so deleting doesn't mess with alignment
    sections.reverse.each do |section|
      lumps << @@lumpinfo[(section[0] + 1)...section[1]] # Respect s_start/end lumps
      @@lumpinfo.delete_at(section[0]..section[1])
    end

    # Now all are in order, add back onto end with start and end lumps
    @@lumpinfo << Lumpinfo.new
    @@lumpinfo.last.name = starts[0]
    lumps.reverse.each { |section| @@lumpinfo.concat(section) }
    @@lumpinfo << Lumpinfo.new
    @@lumpinfo.last.name = ends[0]
  end

  #
  # Locates all the lumps
  #  that will be used by all views
  # Must be called after W_Init.
  #
  def self.r_init_data
    r_order_lump_section(["S_START", "SS_START"], ["S_END", "SS_END"])
    r_order_lump_section(["F_START", "FF_START"], ["F_END", "FF_END"])

    Doocr.numlumps = @@lumpinfo.size
    Doocr.lumpcache.clear
    Doocr.numlumps.times { Doocr.lumpcache << Pointer(Void).null }

    Doocr.firstspritelump = CDoom.w_get_num_for_name("S_START") + 1
    Doocr.lastspritelump = CDoom.w_get_num_for_name("S_END") - 1
    Doocr.numspritelumps = Doocr.lastspritelump - Doocr.firstspritelump + 1

    Doocr.firstflat = CDoom.w_get_num_for_name("F_START") + 1
    Doocr.lastflat = CDoom.w_get_num_for_name("F_END") - 1
    Doocr.numflats = Doocr.lastflat - Doocr.firstflat + 1

    nums = (Doocr.numtextures + 63) // 64 +
           (Doocr.numflats + 63) // 64 +
           (Doocr.numspritelumps + 63) // 64

    # Really complex printing shit...
    print "["
    nums.times { |i| print " " }
    print "]"
    (nums + 1).times { |i| print "\b" }

    CDoom.r_init_textures
    CDoom.r_init_flats
    CDoom.r_init_sprite_lumps
    CDoom.r_init_colormaps
    puts "]"
  end

  #
  # Retrieval, get a flat number for a flat name.
  #
  def self.r_flat_num_for_name(name : LibC::Char*) : LibC::Int
    namet = uninitialized StaticArray(UInt8, 9)

    i = CDoom.w_check_num_for_name(name)

    if i == -1
      namet[8] = 0
      CDoom.doom_memcpy(namet, name, 8)

      CDoom.i_error("Error: r_flat_num_for_name #{String.new(namet.to_unsafe, 8)} not found")
    end
    return i - Doocr.firstflat
  end

  #
  # Check whether texture is available.
  # Filter out NoTexture indicator.
  #
  def self.r_check_texture_num_for_name(name : LibC::Char*) : LibC::Int
    # "NoTexture" marker.
    return 0 if name[0] == '-'.ord

    Doocr.numtextures.times { |i| return i if CDoom.doom_strncasecmp(Doocr.textures[i].value.name, name, 8) == 0 }

    return -1
  end

  #
  # Calls R_CheckTextureNumForName,
  #  aborts with error message.
  #
  def self.r_texture_num_for_name(name : LibC::Char*) : LibC::Int
    i = CDoom.r_check_texture_num_for_name(name)

    if i == -1
      CDoom.i_error("Error: r_texture_num_for_name: #{name} not found")
    end

    return i
  end

  #
  # Preloads all relevant graphics for the level.
  #
  def self.r_precache_level
    return if Doocr.demoplayback != 0

    # Precache flats.
    flatpresent = GC.malloc(Doocr.numflats).as(UInt8*)
    CDoom.doom_memset(flatpresent, 0, Doocr.numflats)

    Doocr.numsectors.times do |i|
      flatpresent[Doocr.sectors[i].floorpic] = 1
      flatpresent[Doocr.sectors[i].ceilingpic] = 1
    end

    Doocr.flatmemory = 0

    Doocr.numflats.times do |i|
      if flatpresent[i] != 0
        lump = Doocr.firstflat + i
        Doocr.flatmemory += @@lumpinfo[lump].size
        CDoom.w_cache_lump_num(lump, Doocr::PU_CACHE)
      end
    end

    # Precache textures.
    texturepresent = GC.malloc(Doocr.numtextures).as(UInt8*)
    CDoom.doom_memset(texturepresent, 0, Doocr.numtextures)

    Doocr.numsides.times do |i|
      texturepresent[Doocr.sides[i].toptexture] = 1
      texturepresent[Doocr.sides[i].midtexture] = 1
      texturepresent[Doocr.sides[i].bottomtexture] = 1
    end

    # Sky texture is always present.
    # Note that F_SKY1 is the name used to
    #  indicate a sky floor/ceiling as a flat,
    #  while the sky texture is stored like
    #  a wall texture, with an episode dependend
    #  name.
    texturepresent[Doocr.skytexture] = 1

    Doocr.texturememory = 0
    Doocr.numtextures.times do |i|
      next if texturepresent[i] == 0

      texture = Doocr.textures[i]

      texture.value.patchcount.times do |j|
        lump = (texture.value.patches.to_unsafe + j).value.patch
        Doocr.texturememory += @@lumpinfo[lump].size
        CDoom.w_cache_lump_num(lump, Doocr::PU_CACHE)
      end
    end

    # Precache sprites.
    spritepresent = GC.malloc(@@sprnames.size).as(UInt8*)
    CDoom.doom_memset(spritepresent, 0, @@sprnames.size)

    th = Doocr.thinkercap.to_unsafe.value.next
    while th != Doocr.thinkercap.to_unsafe
      if th.value.function.acp1.pointer == (->CDoom.p_mobj_thinker).pointer
        spritepresent[th.as(CDoom::Mobj*).value.sprite.value] = 1
      end

      th = th.value.next
    end

    Doocr.spritememory = 0
    @@sprnames.size.times do |i|
      next if spritepresent[i] == 0

      Doocr.sprites[i].numframes.times do |j|
        sf = (Doocr.sprites + i).value.spriteframes + j
        8.times do |k|
          lump = Doocr.firstspritelump + sf.value.lump[k]
          Doocr.spritememory += @@lumpinfo[lump].size
          CDoom.w_cache_lump_num(lump, Doocr::PU_CACHE)
        end
      end
    end

    GC.free(texturepresent.as(Void*))
    GC.free(flatpresent.as(Void*))
    GC.free(spritepresent.as(Void*))
  end

  #
  # All drawing to the view buffer is accomplished in this file.
  # The other refresh files only know about ccordinates,
  #  not the architecture of the frame buffer.
  # Conveniently, the frame buffer is a linear one,
  #  and we need only the base address,
  #  and the total size == width*height*depth/8.,
  #

  #
  # A column is a vertical slice/span from a wall texture that,
  # given the DOOM style restrictions on the view orientation,
  # will always have constant z depth.
  # Thus a special case loop for very fast rendering can
  # be used. It has also been used with Wolfenstein 3D.
  #
  def self.r_draw_column
    count = Doocr.dc_yh - Doocr.dc_yl

    # Zero length, column does not exceed a pixel.
    return if count < 0

    {% if flag?("RANGECHECK") %}
      if Doocr.dc_x.to_u32! >= CDoom::SCREENWIDTH ||
         Doocr.dc_yl < 0 || Doocr.dc_yh >= CDoom::SCREENHEIGHT
        CDoom.i_error("Error: r_draw_column: #{Doocr.dc_yl} to #{Doocr.dc_yh} at #{Doocr.dc_x}")
      end
    {% end %}

    # Framebuffer destination address.
    # Use ylookup LUT to avoid multiply with ScreenWidth.
    # Use columnofs LUT for subwindows?
    dest = Doocr.ylookup[Doocr.dc_yl] + Doocr.columnofs[Doocr.dc_x]

    # Determine scaling,
    #  which is the only mapping to be done.
    fracstep = Doocr.dc_iscale
    frac = Doocr.dc_texturemid + (Doocr.dc_yl - Doocr.centery) * fracstep

    # Inner loop that does the actual texture mapping,
    #  e.g. a DDA-lile scaling.
    # This is as fast as it gets.
    loop do
      # Re-map color indices from wall texture column
      #  using a lighting/special effects LUT.
      dest.value = Doocr.dc_colormap[Doocr.dc_source[(frac >> FRACBITS) & 127]]

      dest += CDoom::SCREENWIDTH
      frac += fracstep

      break unless count != 0
      count -= 1
    end
  end

  #
  # Spectre/Invisibility.
  #

  #
  # Framebuffer postprocessing.
  # Creates a fuzzy image by copying pixels
  #  from adjacent ones to left and right.
  # Used with an all black colormap, this
  #  could create the SHADOW effect,
  #  i.e. spectres and invisible players.
  #
  def self.r_draw_fuzz_column
    # Adjust borders. Low...
    Doocr.dc_yl = 1 if Doocr.dc_yl == 0

    # .. and high.
    Doocr.dc_yh = Doocr.viewheight - 2 if Doocr.dc_yh == Doocr.viewheight - 1

    count = Doocr.dc_yh - Doocr.dc_yl

    # Zero length.
    return if count < 0

    {% if flag?("RANGECHECK") %}
      if Doocr.dc_x.to_u32! >= CDoom::SCREENWIDTH ||
         Doocr.dc_yl < 0 || Doocr.dc_yh >= CDoom::SCREENHEIGHT
        CDoom.i_error("Error: r_draw_fuzz_column: #{Doocr.dc_yl} to #{Doocr.dc_yh} at #{Doocr.dc_x}")
      end
    {% end %}

    # Does not work with blocky mode.
    dest = Doocr.ylookup[Doocr.dc_yl] + Doocr.columnofs[Doocr.dc_x]

    # Looks familiar.
    fracstep = Doocr.dc_iscale
    frac = Doocr.dc_texturemid + (Doocr.dc_yl - Doocr.centery) * fracstep

    # Looks like an attempt at dithering,
    #  using the colormap #6 (of 0-31, a bit
    #  brighter than average).
    loop do
      # Lookup framebuffer, and retrieve
      #  a pixel that is either one column
      #  left or right of the current one.
      # Add index from colormap to index.
      dest.value = Doocr.colormaps[6 * 256 + dest[Doocr.fuzzoffset[Doocr.fuzzpos]]]

      # Clamp table lookup index.
      Doocr.fuzzpos += 1
      Doocr.fuzzpos = 0 if Doocr.fuzzpos == Doocr::FUZZTABLE

      dest += CDoom::SCREENWIDTH

      frac += fracstep
      break unless count != 0
      count -= 1
    end
  end

  #
  # Used to draw player sprites
  #  with the green colorramp mapped to others.
  # Could be used with different translation
  #  tables, e.g. the lighter colored version
  #  of the BaronOfHell, the HellKnight, uses
  #  identical sprites, kinda brightened up.
  #
  def self.r_draw_translated_column
    count = Doocr.dc_yh - Doocr.dc_yl
    return if count < 0
    {% if flag?("RANGECHECK") %}
      if Doocr.dc_x.to_u32! >= CDoom::SCREENWIDTH ||
         Doocr.dc_yl < 0 || Doocr.dc_yh >= CDoom::SCREENHEIGHT
        CDoom.i_error("Error: r_draw_column: #{Doocr.dc_yl} to #{Doocr.dc_yh} at #{Doocr.dc_x}")
      end
    {% end %}

    # FIXME. As above.
    dest = Doocr.ylookup[Doocr.dc_yl] + Doocr.columnofs[Doocr.dc_x]

    # Looks familiar.
    fracstep = Doocr.dc_iscale
    frac = Doocr.dc_texturemid + (Doocr.dc_yl - Doocr.centery) * fracstep

    # Here we do an additional index re-mapping.
    loop do
      # Translation tables are used
      #  to map certain colorramps to other ones,
      #  used with PLAY sprites.
      # Thus the "green" ramp of the player 0 sprite
      #  is mapped to gray, red, black/indigo.
      dest.value = Doocr.dc_colormap[Doocr.dc_translation[Doocr.dc_source[frac >> FRACBITS]]]
      dest += CDoom::SCREENWIDTH

      frac += fracstep
      break unless count != 0
      count -= 1
    end
  end

  #
  # Creates the translation tables to map
  # the green color ramp to gray, brown, red.
  # Assumes a given structure of the PLAYPAL.
  # Could be read from a lump instead.
  #
  def self.r_init_translation_tables
    Doocr.translationtables.fill(0_u8)

    # translate just the 16 green colors
    256.times do |i|
      if i >= 0x70 && i <= 0x7f
        # map green ramp to gray, brown, red
        Doocr.translationtables[i] = 0x60_u8 + (i & 0xf)
        Doocr.translationtables[i + 256] = 0x40_u8 + (i & 0xf)
        Doocr.translationtables[i + 512] = 0x20_u8 + (i & 0xf)
      else
        # Keep all other colors as is.
        Doocr.translationtables[i] = i.to_u8!
        Doocr.translationtables[i + 256] = i.to_u8!
        Doocr.translationtables[i + 512] = i.to_u8!
      end
    end
  end

  #
  # With DOOM style restrictions on view orientation,
  # the floors and ceilings consist of horizontal slices
  # or spans with constant z depth.
  # However, rotation around the world z axis is possible,
  # thus this mapping, while simpler and faster than
  # perspective correct texture mapping, has to traverse
  # the texture at an angle in all but a few cases.
  # In consequence, flats are not stored by column (like walls),
  # and the inner loop has to step in texture space u and v.
  #

  #
  # Draws the actual span.
  #
  def self.r_draw_span
    {% if flag?("RANGECHECK") %}
      if Doocr.ds_x2 < Doocr.ds_x1 ||
         Doocr.ds_x1 < 0 ||
         Doocr.ds_x2 >= CDoom::SCREENWIDTH ||
         Doocr.ds_y.to_u32! > CDoom::SCREENHEIGHT
        CDoom.i_error("Error: r_draw_span: #{Doocr.ds_x1} to #{Doocr.ds_x2} at #{Doocr.ds_y}")
      end
    {% end %}

    xfrac = Doocr.ds_xfrac
    yfrac = Doocr.ds_yfrac

    dest = Doocr.ylookup[Doocr.ds_y] + Doocr.columnofs[Doocr.ds_x1]

    # We do not check for zero spans here?
    count = Doocr.ds_x2 - Doocr.ds_x1

    loop do
      # Current texture index in u,v
      spot = ((yfrac >> (16 - 6)) & (63 * 64)) + ((xfrac >> 16) & 63)

      # Lookup pixel from flat texture tile,
      #  re-index using light/colormap.
      dest.value = Doocr.ds_colormap[Doocr.ds_source[spot]]
      dest += 1

      # Next step in u,v.
      xfrac += Doocr.ds_xstep
      yfrac += Doocr.ds_ystep

      break unless count != 0
      count -= 1
    end
  end

  #
  # Creats lookup tables that avoid
  #  multiplies and other hazzles
  #  for getting the framebuffer address
  #  of a pixel to draw.
  #
  def self.r_init_buffer(width : LibC::Int, height : LibC::Int)
    # Handle resize,
    #  e.g. smaller view windows
    #  with border and/or status bar.
    Doocr.viewwindowx = (CDoom::SCREENWIDTH - width) >> 1

    # Column offset. For windows.
    width.times { |i| Doocr.columnofs[i] = Doocr.viewwindowx + i }

    # Samw with base row offset.
    if width == CDoom::SCREENWIDTH
      Doocr.viewwindowy = 0
    else
      Doocr.viewwindowy = (CDoom::SCREENHEIGHT - Doocr::SBARHEIGHT - height) >> 1
    end
    # Preclaculate all row offsets.
    screen = @@software_rendering ? Doocr.screens[0] : @@software_screen.to_unsafe
    height.times { |i| Doocr.ylookup[i] = screen + (i + Doocr.viewwindowy) * CDoom::SCREENWIDTH }
  end

  #
  # Fills the back screen with a pattern
  #  for variable screen sizes
  # Also draws a beveled edge.
  #
  def self.r_fill_back_screen
    # DOOM border patch.
    name1 = "FLOOR7_2"

    # DOOM II border patch.
    name2 = "GRNROCK"

    name : UInt8*

    return if Doocr.scaledviewwidth == 320

    if Doocr.gamemode == Doocr::GameMode::Commercial
      name = name2.to_unsafe
    else
      name = name1.to_unsafe
    end

    src = CDoom.w_cache_lump_name(name, Doocr::PU_CACHE).as(UInt8*)
    dest = Doocr.screens[1]

    (CDoom::SCREENHEIGHT - Doocr::SBARHEIGHT).times do |y|
      (CDoom::SCREENWIDTH // 64).times do |x|
        CDoom.doom_memcpy(dest, src + ((y & 63) << 6), 64)
        dest += 64
      end

      if CDoom::SCREENWIDTH & 63 != 0
        CDoom.doom_memcpy(dest, src + ((y & 63) << 6), CDoom::SCREENWIDTH & 63)
        dest += CDoom::SCREENWIDTH & 63
      end
    end

    patch = CDoom.w_cache_lump_name("brdr_t", Doocr::PU_CACHE).as(CDoom::Patch*)

    x = 0
    while x < Doocr.scaledviewwidth
      CDoom.v_draw_patch(Doocr.viewwindowx + x, Doocr.viewwindowy - 8, 1, patch)
      x += 8
    end
    patch = CDoom.w_cache_lump_name("brdr_b", Doocr::PU_CACHE).as(CDoom::Patch*)

    x = 0
    while x < Doocr.scaledviewwidth
      CDoom.v_draw_patch(Doocr.viewwindowx + x, Doocr.viewwindowy + Doocr.viewheight, 1, patch)
      x += 8
    end
    patch = CDoom.w_cache_lump_name("brdr_l", Doocr::PU_CACHE).as(CDoom::Patch*)

    y = 0
    while y < Doocr.viewheight
      CDoom.v_draw_patch(Doocr.viewwindowx - 8, Doocr.viewwindowy + y, 1, patch)
      y += 8
    end
    patch = CDoom.w_cache_lump_name("brdr_r", Doocr::PU_CACHE).as(CDoom::Patch*)

    y = 0
    while y < Doocr.viewheight
      CDoom.v_draw_patch(Doocr.viewwindowx + Doocr.scaledviewwidth, Doocr.viewwindowy + y, 1, patch)
      y += 8
    end

    # Draw beveled edge.
    CDoom.v_draw_patch(Doocr.viewwindowx - 8,
      Doocr.viewwindowy - 8,
      1,
      CDoom.w_cache_lump_name("brdr_tl", Doocr::PU_CACHE).as(CDoom::Patch*))

    CDoom.v_draw_patch(Doocr.viewwindowx + Doocr.scaledviewwidth,
      Doocr.viewwindowy - 8,
      1,
      CDoom.w_cache_lump_name("brdr_tr", Doocr::PU_CACHE).as(CDoom::Patch*))

    CDoom.v_draw_patch(Doocr.viewwindowx - 8,
      Doocr.viewwindowy + Doocr.viewheight,
      1,
      CDoom.w_cache_lump_name("brdr_bl", Doocr::PU_CACHE).as(CDoom::Patch*))

    CDoom.v_draw_patch(Doocr.viewwindowx + Doocr.scaledviewwidth,
      Doocr.viewwindowy + Doocr.viewheight,
      1,
      CDoom.w_cache_lump_name("brdr_br", Doocr::PU_CACHE).as(CDoom::Patch*))
  end

  #
  # Copy a screen buffer.
  #
  def self.r_video_erase(ofs : LibC::UInt, count : LibC::Int)
    # LFB copy.
    # This might not be a good idea if memcpy
    #  is not optiomal, e.g. byte by byte on
    #  a 32bit CPU, as GNU GCC/Linux libc did
    #  at one point.
    CDoom.doom_memcpy(Doocr.screens[0] + ofs, Doocr.screens[1] + ofs, count)
  end

  #
  # Draws the border around the view
  #  for different size windows?
  #
  def self.r_draw_view_border
    return if Doocr.scaledviewwidth == CDoom::SCREENWIDTH

    top = ((CDoom::SCREENHEIGHT - Doocr::SBARHEIGHT) - Doocr.viewheight) // 2
    side = (CDoom::SCREENWIDTH - Doocr.scaledviewwidth) // 2

    # copy top and one line of left side
    CDoom.r_video_erase(0, top * CDoom::SCREENWIDTH + side)

    # copy one line of right side and bottom
    ofs = (Doocr.viewheight + top) * CDoom::SCREENWIDTH - side
    CDoom.r_video_erase(ofs, top * CDoom::SCREENWIDTH + side)

    # copy sides using wraparound
    ofs = top * CDoom::SCREENWIDTH + CDoom::SCREENWIDTH - side
    side <<= 1

    i = 1
    while i < Doocr.viewheight
      CDoom.r_video_erase(ofs, side)
      ofs += CDoom::SCREENWIDTH

      i += 1
    end

    # ?
    CDoom.v_mark_rect(0, 0, CDoom::SCREENWIDTH, CDoom::SCREENHEIGHT - Doocr::SBARHEIGHT)
  end

  #
  # Expand a given bbox
  # so that it encloses a given point.
  #
  def self.r_add_point_to_box(x : LibC::Int, y : LibC::Int, box : LibC::Int*)
    box[Doocr::BOXLEFT] = x if x < box[Doocr::BOXLEFT]
    box[Doocr::BOXRIGHT] = x if x > box[Doocr::BOXRIGHT]
    box[Doocr::BOXBOTTOM] = y if y < box[Doocr::BOXBOTTOM]
    box[Doocr::BOXTOP] = y if y > box[Doocr::BOXTOP]
  end

  #
  # Traverse BSP (sub) tree,
  #  check point against partition plane.
  # Returns side 0 (front) or 1 (back).
  #
  def self.r_point_on_side(x : LibC::Int, y : LibC::Int, node : CDoom::Node*) : LibC::Int
    if node.value.dx == 0
      return (node.value.dy > 0).to_unsafe if x <= node.value.x

      return (node.value.dy < 0).to_unsafe
    end
    if node.value.dy == 0
      return (node.value.dx < 0).to_unsafe if y <= node.value.y

      return (node.value.dx > 0).to_unsafe
    end

    dx = (x &- node.value.x)
    dy = (y &- node.value.y)

    # Try to quickly decide by looking at sign bits.
    if (node.value.dy ^ node.value.dx ^ dx ^ dy) & 0x80000000 != 0
      if (node.value.dy ^ dx) & 0x80000000 != 0
        # (left is negative)
        return 1
      end
      return 0
    end

    left = CDoom.fixed_mul(node.value.dy >> FRACBITS, dx)
    right = CDoom.fixed_mul(dy, node.value.dx >> FRACBITS)

    if right < left
      # front side
      return 0
    end
    # back side
    return 1
  end

  def self.r_point_on_seg_side(x : LibC::Int, y : LibC::Int, line : CDoom::Seg*) : LibC::Int
    lx = line.value.v1.value.x
    ly = line.value.v1.value.y

    ldx = line.value.v2.value.x - lx
    ldy = line.value.v2.value.y - ly

    if ldx == 0
      return (ldy > 0).to_unsafe if x <= lx

      return (ldy < 0).to_unsafe
    end
    if ldy == 0
      return (ldx < 0).to_unsafe if y <= ly

      return (ldx > 0).to_unsafe
    end

    dx = (x - lx)
    dy = (y - ly)

    # Try to quickly decide by looking at sign bits.
    if (ldy ^ ldx ^ dx ^ dy) & 0x80000000 != 0
      if (ldy ^ dx) & 0x80000000 != 0
        # (left is negative)
        return 1
      end
      return 0
    end

    left = CDoom.fixed_mul(ldy >> FRACBITS, dx)
    right = CDoom.fixed_mul(dy, ldx >> FRACBITS)

    if right < left
      # front side
      return 0
    end
    # back side
    return 1
  end

  #
  # To get a global angle from cartesian coordinates,
  #  the coordinates are flipped until they are in
  #  the first octant of the coordinate system, then
  #  the y (<=x) is scaled and divided by x to get a
  #  tangent (slope) value which is looked up in the
  #  tantoangle[] table.
  #
  def self.r_point_to_angle(x : LibC::Int, y : LibC::Int) : LibC::UInt
    x -= Doocr.viewx
    y -= Doocr.viewy

    return 0_u32 if x == 0 && y == 0

    if x >= 0
      if y >= 0
        if x > y
          # octant 0
          return @@tantoangle[CDoom.slope_div(y, x)].to_u32!
        else
          # octant 1
          return (ANG90 &- 1 &- @@tantoangle[CDoom.slope_div(x, y)]).to_u32!
        end
      else
        y = -y

        if x > y
          # octant 8
          return (-(@@tantoangle[CDoom.slope_div(y, x)].to_i32!)).to_u32!
        else
          # octant 7
          return (ANG270 &+ @@tantoangle[CDoom.slope_div(x, y)]).to_u32!
        end
      end
    else
      x = -x

      if y >= 0
        if x > y
          # octant 3
          return (ANG180 &- 1 &- @@tantoangle[CDoom.slope_div(y, x)]).to_u32!
        else
          # octant 2
          return (ANG90 &+ @@tantoangle[CDoom.slope_div(x, y)]).to_u32!
        end
      else
        y = -y

        if x > y
          # octant 4
          return (ANG180 &+ @@tantoangle[CDoom.slope_div(y, x)]).to_u32!
        else
          # octant 5
          return (ANG270 &- 1 &- @@tantoangle[CDoom.slope_div(x, y)]).to_u32
        end
      end
    end

    return 0_u32
  end

  def self.r_point_to_angle2(x1 : LibC::Int, y1 : LibC::Int, x2 : LibC::Int, y2 : LibC::Int) : LibC::UInt
    Doocr.viewx = x1
    Doocr.viewy = y1

    return CDoom.r_point_to_angle(x2, y2)
  end

  def self.r_point_to_dist(x : LibC::Int, y : LibC::Int) : LibC::Int
    dx = doom_abs(x - Doocr.viewx)
    dy = doom_abs(y - Doocr.viewy)

    if dy > dx
      temp = dx
      dx = dy
      dy = temp
    end

    angle = (@@tantoangle[CDoom.fixed_div(dy, dx) >> DBITS] &+ ANG90) >> Doocr::ANGLETOFINESHIFT

    # use as cosine
    dist = CDoom.fixed_div(dx, @@finesine[angle])

    return dist
  end

  #
  # Returns the texture mapping scale
  #  for the current line (horizontal span)
  #  at the given angle.
  # rw_distance must be calculated first.
  #
  def self.r_scale_from_global_angle(visangle : LibC::UInt) : LibC::Int
    anglea = ANG90 &+ (visangle &- Doocr.viewangle)
    angleb = ANG90 &+ (visangle &- Doocr.rw_normalangle)

    # both sines are allways positive
    sinea = @@finesine[anglea >> Doocr::ANGLETOFINESHIFT]
    sineb = @@finesine[angleb >> Doocr::ANGLETOFINESHIFT]
    num = CDoom.fixed_mul(Doocr.projection, sineb)
    den = CDoom.fixed_mul(Doocr.rw_distance, sinea)

    if den > num >> 16
      scale = CDoom.fixed_div(num, den)

      if scale > 64 * FRACUNIT
        scale = 64 * FRACUNIT
      elsif scale < 256
        scale = 256
      end
    else
      scale = 64 * FRACUNIT
    end

    return scale
  end

  def self.r_init_tables
    {% unless flag?("PRECOMPUTED") %}
      # FINE TANGENT COMPUTE
      puts " - COMPUTE"
      print "         finetangent - ["
      ((FINETANGENT_SIZE + 255) // 256).times { |i| print " " }
      print "]"
      (((FINETANGENT_SIZE + 255) // 256) + 1).times { |i| print "\b" }

      FINETANGENT_SIZE.times do |i|
        print "." if i & 255 == 0

        deg = -90.0 + i * (180.0 / FINETANGENT_SIZE)
        rad = (i - FINEANGLES/4 + 0.5) * (2.0 * PI / FINEANGLES)
        val = Math.tan(rad) * FRACUNIT
        # clamp near the asymptotes instead of letting it blow up
        if val > Int32::MAX.to_f64
          @@finetangent << Int32::MAX
        elsif val < Int32::MIN.to_f64
          @@finetangent << Int32::MIN
        else
          @@finetangent << val.to_i32
        end
      end
      puts "]"

      # FINE SINE COMPUTE
      print "         finesine    - ["
      ((FINESINE_SIZE + 255) // 256).times { |i| print " " }
      print "]"
      (((FINESINE_SIZE + 255) // 256) + 1).times { |i| print "\b" }

      FINESINE_SIZE.times do |i|
        print "." if i & 255 == 0

        rad = (i + 0.5) * (2.0 * PI / FINEANGLES)
        @@finesine << (Math.sin(rad) * FRACUNIT).to_i32
      end
      puts "]"

      # TANTOANGLE COMPUTE
      print "         tantoangle  - ["
      ((TANTOANGLE_SIZE + 255) // 256).times { |i| print " " }
      print "]"
      (((TANTOANGLE_SIZE + 255) // 256) + 1).times { |i| print "\b" }

      TANTOANGLE_SIZE.times do |i|
        print "." if i & 255 == 0

        slope = i.to_f64 / SLOPERANGE
        rad = Math.atan(slope)
        @@tantoangle << (rad * (ANG180.to_f64 / PI)).to_u32
      end
      puts "]"
    {% else %}
      puts " - PRECOMPUTED"
    {% end %}

    @@finecosine = @@finesine.dup.rotate(FINEANGLES // 4)
  end

  def self.r_init_texture_mapping
    # Use tangent table to generate viewangletox:
    # viewangletox will give the next greatest x
    # after the view angle.
    #
    # Calc focallength
    # so FIELDOFVIEW angles covers SCREENWIDTH.
    focallength = CDoom.fixed_div(Doocr.centerxfrac,
      @@finetangent[Doocr::FINEANGLES // 4 + Doocr::FIELDOFVIEW // 2])

    (Doocr::FINEANGLES // 2).times do |i|
      if @@finetangent[i] > FRACUNIT * 2
        t = -1
      elsif @@finetangent[i] < -FRACUNIT * 2
        t = Doocr.viewwidth + 1
      else
        t = CDoom.fixed_mul(@@finetangent[i], focallength)
        t = (Doocr.centerxfrac - t + FRACUNIT - 1) >> FRACBITS

        if t < -1
          t = -1
        elsif t > Doocr.viewwidth + 1
          t = Doocr.viewwidth + 1
        end
      end
      Doocr.viewangletox[i] = t
    end

    # Scan viewangletox[] to generate xtoviewangle[]:
    # xtoviewangle will give the smallest view angle
    # that maps to x.
    x = 0
    while x <= Doocr.viewwidth
      i = 0
      while Doocr.viewangletox[i] > x
        i += 1
      end
      Doocr.xtoviewangle[x] = (i.to_u32! << Doocr::ANGLETOFINESHIFT) &- ANG90

      x += 1
    end

    # Take out the fencepost cases from viewangletox.
    (Doocr::FINEANGLES // 2).times do |i|
      t = CDoom.fixed_mul(@@finetangent[i], focallength)
      t = Doocr.centerx - t

      if Doocr.viewangletox[i] == -1
        Doocr.viewangletox[i] = 0
      elsif Doocr.viewangletox[i] == Doocr.viewwidth + 1
        Doocr.viewangletox[i] = Doocr.viewwidth
      end
    end

    Doocr.clipangle = Doocr.xtoviewangle[0]
  end

  #
  # Only inits the zlight table,
  # because the scalelight table changes with view size.
  #
  def self.r_init_light_tables
    # Calculate the light levels to use
    #  for each level / distance combination.
    Doocr::LIGHTLEVELS.times do |i|
      startmap = ((Doocr::LIGHTLEVELS - 1 - i) * 2) * Doocr::NUMCOLORMAPS // Doocr::LIGHTLEVELS
      Doocr::MAXLIGHTZ.times do |j|
        scale = CDoom.fixed_div((CDoom::SCREENWIDTH // 2 * FRACUNIT), (j + 1) << Doocr::LIGHTZSHIFT)
        scale >>= Doocr::LIGHTSCALESHIFT
        level = startmap - scale // Doocr::DISTMAP

        level = 0 if level < 0

        level = Doocr::NUMCOLORMAPS - 1 if level >= Doocr::NUMCOLORMAPS

        Doocr.zlight[i * Doocr::MAXLIGHTZ + j] = Doocr.colormaps + level * 256
      end
    end
  end

  #
  # Do not really change anything here,
  #  because it might be in the middle of a refresh.
  # The change will take effect next refresh.
  #
  def self.r_set_view_size(blocks : LibC::Int, detail : LibC::Int)
    Doocr.setsizeneeded = 1
    Doocr.setblocks = blocks
    Doocr.setdetail = detail
  end

  def self.r_execute_set_view_size
    Doocr.setsizeneeded = 0

    if Doocr.setblocks == 11
      Doocr.scaledviewwidth = CDoom::SCREENWIDTH
      Doocr.viewheight = CDoom::SCREENHEIGHT
    else
      Doocr.scaledviewwidth = Doocr.setblocks * 32
      Doocr.viewheight = (Doocr.setblocks * 168 // 10) & ~7
    end

    Doocr.detailshift = Doocr.setdetail
    Doocr.viewwidth = Doocr.scaledviewwidth

    Doocr.centery = Doocr.viewheight // 2
    Doocr.centerx = Doocr.viewwidth // 2
    Doocr.centerxfrac = Doocr.centerx << FRACBITS
    Doocr.centeryfrac = Doocr.centery << FRACBITS
    Doocr.projection = Doocr.centerxfrac

    Doocr.colfunc = ->CDoom.r_draw_column

    CDoom.r_init_buffer(Doocr.scaledviewwidth, Doocr.viewheight)

    CDoom.r_init_texture_mapping

    # psprite scales
    Doocr.pspritescale = FRACUNIT * Doocr.viewwidth // CDoom::SCREENWIDTH
    Doocr.pspriteiscale = FRACUNIT * CDoom::SCREENWIDTH // Doocr.viewwidth

    # thing clipping
    Doocr.viewwidth.times { |i| Doocr.screenheightarray[i] = Doocr.viewheight.to_i16! }

    # planes
    Doocr.viewheight.times do |i|
      dy = ((i - Doocr.viewheight // 2) << FRACBITS) + FRACUNIT // 2
      dy = doom_abs(dy)
      Doocr.yslope[i] = CDoom.fixed_div(Doocr.viewwidth // 2 * FRACUNIT, dy)
    end

    Doocr.viewwidth.times do |i|
      cosadj = doom_abs(@@finecosine[Doocr.xtoviewangle[i] >> Doocr::ANGLETOFINESHIFT])
      Doocr.distscale[i] = CDoom.fixed_div(FRACUNIT, cosadj)
    end

    # Calculate the light levels to use
    #  for each level / scale combination.
    Doocr::LIGHTLEVELS.times do |i|
      startmap = ((Doocr::LIGHTLEVELS - 1 - i) * 2) * Doocr::NUMCOLORMAPS // Doocr::LIGHTLEVELS
      Doocr::MAXLIGHTSCALE.times do |j|
        level = startmap - j * CDoom::SCREENWIDTH // Doocr.viewwidth // Doocr::DISTMAP

        level = 0 if level < 0

        level = Doocr::NUMCOLORMAPS - 1 if level >= Doocr::NUMCOLORMAPS

        Doocr.scalelight[i][j] = Doocr.colormaps + level * 256
      end
    end
  end

  def self.r_init
    # print "\nr_init_data"
    CDoom.r_init_data

    # viewwidth / viewheight / detailLevel are set by the defaults
    print "        Tables"
    CDoom.r_init_tables

    CDoom.r_set_view_size(Doocr.screenblocks, Doocr.detail_level)

    CDoom.r_init_light_tables
    CDoom.r_init_sky_map
    CDoom.r_init_translation_tables

    Doocr.framecount = 0
  end

  def self.r_point_in_subsector(x : LibC::Int, y : LibC::Int) : CDoom::Subsector*
    # single subsector is a special case
    return Doocr.subsectors if Doocr.numnodes == 0

    nodenum = Doocr.numnodes - 1

    while nodenum & Doocr::NF_SUBSECTOR == 0
      node = Doocr.nodes + nodenum
      side = CDoom.r_point_on_side(x, y, node)
      nodenum = node.value.children[side]
    end

    return Doocr.subsectors + (nodenum & ~Doocr::NF_SUBSECTOR)
  end

  def self.r_setup_frame(player : CDoom::Player*)
    Doocr.viewplayer = player
    Doocr.viewx = player.value.mo.value.x
    Doocr.viewy = player.value.mo.value.y
    Doocr.viewangle = player.value.mo.value.angle &+ Doocr.viewangleoffset
    Doocr.extralight = player.value.extralight

    Doocr.viewz = player.value.viewz

    Doocr.viewsin = @@finesine[Doocr.viewangle >> Doocr::ANGLETOFINESHIFT]
    Doocr.viewcos = @@finecosine[Doocr.viewangle >> Doocr::ANGLETOFINESHIFT]

    Doocr.sscount = 0

    if player.value.fixedcolormap != 0
      Doocr.fixedcolormap =
        Doocr.colormaps +
          player.value.fixedcolormap * 256 * sizeof(UInt8)

      Doocr.walllights = Doocr.scalelightfixed.to_unsafe

      Doocr::MAXLIGHTSCALE.times { |i| Doocr.scalelightfixed[i] = Doocr.fixedcolormap }
    else
      Doocr.fixedcolormap = Pointer(UInt8).null
    end

    Doocr.framecount += 1
    Doocr.validcount += 1
  end

  def self.r_render_player_view(player : CDoom::Player*)
    @@software_screen.fill(255) unless @@software_rendering
    CDoom.r_setup_frame(player)

    # Clear buffers.
    CDoom.r_clear_clip_segs
    CDoom.r_clear_draw_segs
    CDoom.r_clear_planes
    CDoom.r_clear_sprites

    # check for new console commands.
    CDoom.net_update

    # The head node is the last node output.
    CDoom.r_render_bsp_node(Doocr.numnodes - 1)

    # Check for console commands.
    CDoom.net_update

    CDoom.r_draw_planes

    # Check for new console commands.
    CDoom.net_update

    CDoom.r_draw_masked

    # Check for new console commands.
    CDoom.net_update
  end

  #
  # Uses global vars:
  #  planeheight
  #  ds_source
  #  basexscale
  #  baseyscale
  #  viewx
  #  viewy
  #
  # BASIC PRIMITIVE
  #
  def self.r_map_plane(y : LibC::Int, x1 : LibC::Int, x2 : LibC::Int)
    {% if flag?("RANGECHECK") %}
      if x2 < x1 ||
         x1 < 0 ||
         x2 >= Doocr.viewwidth ||
         y.to_u32! > Doocr.viewheight.to_u32!
        CDoom.i_error("Error: r_map_plane: #{x1} to #{x2} at #{y}")
      end
    {% end %}

    if Doocr.planeheight != Doocr.cachedheight[y]
      Doocr.cachedheight[y] = Doocr.planeheight
      Doocr.cacheddistance[y] = CDoom.fixed_mul(Doocr.planeheight, Doocr.yslope[y])
      distance = Doocr.cacheddistance[y]
      Doocr.cachedxstep[y] = CDoom.fixed_mul(distance, Doocr.basexscale)
      Doocr.ds_xstep = Doocr.cachedxstep[y]
      Doocr.cachedystep[y] = CDoom.fixed_mul(distance, Doocr.baseyscale)
      Doocr.ds_ystep = Doocr.cachedystep[y]
    else
      distance = Doocr.cacheddistance[y]
      Doocr.ds_xstep = Doocr.cachedxstep[y]
      Doocr.ds_ystep = Doocr.cachedystep[y]
    end

    length = CDoom.fixed_mul(distance, Doocr.distscale[x1])
    angle = (Doocr.viewangle &+ Doocr.xtoviewangle[x1]) >> Doocr::ANGLETOFINESHIFT
    Doocr.ds_xfrac = Doocr.viewx &+ CDoom.fixed_mul(@@finecosine[angle], length)
    Doocr.ds_yfrac = -Doocr.viewy &- CDoom.fixed_mul(@@finesine[angle], length)

    if !Doocr.fixedcolormap.null?
      Doocr.ds_colormap = Doocr.fixedcolormap
    else
      index = distance.to_u32! >> Doocr::LIGHTZSHIFT

      index = Doocr::MAXLIGHTZ - 1 if index >= Doocr::MAXLIGHTZ

      Doocr.ds_colormap = Doocr.planezlight[index]
    end

    Doocr.ds_y = y
    Doocr.ds_x1 = x1
    Doocr.ds_x2 = x2

    CDoom.r_draw_span
  end

  #
  # At begining of frame.
  #
  def self.r_clear_planes
    # opening / clipping determination
    Doocr.viewwidth.times do |i|
      Doocr.floorclip[i] = Doocr.viewheight.to_i16!
      Doocr.ceilingclip[i] = -1
    end

    @@visplanes.clear
    @@visplanes << CDoom::Visplane.new
    @@lastvisplane = 0
    Doocr.lastopening = Doocr.openings.to_unsafe

    # texture calculation
    Doocr.cachedheight.fill(0)

    # left to right mapping
    angle = (Doocr.viewangle &- ANG90) >> Doocr::ANGLETOFINESHIFT

    # scale will be unit scale at SCREENWIDTH/2 distance
    Doocr.basexscale = CDoom.fixed_div(@@finecosine[angle], Doocr.centerxfrac)
    Doocr.baseyscale = -CDoom.fixed_div(@@finesine[angle], Doocr.centerxfrac)
  end

  def self.r_find_plane(height : LibC::Int, picnum : LibC::Int, lightlevel : LibC::Int) : Int32
    if picnum == Doocr.skyflatnum
      height = 0 # all skys map together
      lightlevel = 0
    end

    check = 0
    while check < @@lastvisplane
      if height == @@visplanes[check].height &&
         picnum == @@visplanes[check].picnum &&
         lightlevel == @@visplanes[check].lightlevel
        break
      end

      check += 1
    end

    return check if check < @@lastvisplane

    @@visplanes << CDoom::Visplane.new if @@lastvisplane == @@visplanes.size - 1

    @@lastvisplane = check + 1

    checkp = @@visplanes.to_unsafe + check
    checkp.value.height = height
    checkp.value.picnum = picnum
    checkp.value.lightlevel = lightlevel
    checkp.value.minx = CDoom::SCREENWIDTH
    checkp.value.maxx = -1

    CDoom.doom_memset(checkp.value.top, 0xff, sizeof(typeof(checkp.value.top)))

    return check
  end

  def self.r_check_plane(plv : Int32, start : LibC::Int, stop : LibC::Int) : Int32
    pl = @@visplanes.to_unsafe + plv

    if start < pl.value.minx
      intrl = pl.value.minx
      unionl = start
    else
      unionl = pl.value.minx
      intrl = start
    end

    if stop > pl.value.maxx
      intrh = pl.value.maxx
      unionh = stop
    else
      unionh = pl.value.maxx
      intrh = stop
    end

    x = intrl
    while x <= intrh
      break if pl.value.top[x] != 0xff
      x += 1
    end

    if x > intrh
      pl.value.minx = unionl
      pl.value.maxx = unionh

      # use the same one
      return plv
    end

    # make a new visplane
    @@visplanes << CDoom::Visplane.new if @@lastvisplane == @@visplanes.size - 1
    new_index = @@lastvisplane
    @@lastvisplane += 1

    src = @@visplanes.to_unsafe + plv # re-derive after the push, not before
    dst = @@visplanes.to_unsafe + new_index
    dst.value.height = src.value.height
    dst.value.picnum = src.value.picnum
    dst.value.lightlevel = src.value.lightlevel
    dst.value.minx = start
    dst.value.maxx = stop

    CDoom.doom_memset(dst.value.top, 0xff, sizeof(typeof(dst.value.top)))

    new_index
  end

  def self.r_make_spans(x : LibC::Int, t1 : LibC::Int, b1 : LibC::Int, t2 : LibC::Int, b2 : LibC::Int)
    while t1 < t2 && t1 <= b1
      CDoom.r_map_plane(t1, Doocr.spanstart[t1], x - 1)
      t1 += 1
    end
    while b1 > b2 && b1 >= t1
      CDoom.r_map_plane(b1, Doocr.spanstart[b1], x - 1)
      b1 -= 1
    end

    while t2 < t1 && t2 <= b2
      Doocr.spanstart[t2] = x
      t2 += 1
    end
    while b2 > b1 && b2 >= t2
      Doocr.spanstart[b2] = x
      b2 -= 1
    end
  end

  #
  # At the end of each frame.
  #
  def self.r_draw_planes
    {% if flag?("RANGECHECK") %}
      if Doocr.ds_p - Doocr.drawsegs.to_unsafe > Doocr::MAXDRAWSEGS
        CDoom.i_error("Error: r_draw_planes: drawsegs overflow (#{Doocr.ds_p - Doocr.drawsegs.to_unsafe})")
      end

      if @@lastvisplane > @@visplanes.size - 1
        CDoom.i_error("Error: r_draw_planes: visplane overflow (#{@@lastvisplane})")
      end

      if Doocr.lastopening - Doocr.openings.to_unsafe > Doocr::MAXOPENINGS
        CDoom.i_error("Error: r_draw_planes: opening overflow (#{Doocr.lastopening - Doocr.openings.to_unsafe})")
      end
    {% end %}

    pl = @@visplanes.to_unsafe
    while pl - @@visplanes.to_unsafe < @@lastvisplane
      if pl.value.minx > pl.value.maxx
        pl += 1
        next
      end

      # sky flat
      if pl.value.picnum == Doocr.skyflatnum
        Doocr.dc_iscale = Doocr.pspriteiscale

        # Sky is allways drawn full bright,
        #  i.e. colormaps[0] is used.
        # Because of this hack, sky is not affected
        #  by INVUL inverse mapping.
        Doocr.dc_colormap = Doocr.colormaps
        Doocr.dc_texturemid = Doocr.skytexturemid
        x = pl.value.minx
        while x <= pl.value.maxx
          Doocr.dc_yl = pl.value.top[x]
          Doocr.dc_yh = pl.value.bottom[x]

          if Doocr.dc_yl <= Doocr.dc_yh
            angle = (Doocr.viewangle &+ Doocr.xtoviewangle[x]) >> Doocr::ANGLETOSKYSHIFT
            Doocr.dc_x = x
            Doocr.dc_source = CDoom.r_get_column(Doocr.skytexture, angle)
            Doocr.colfunc.call
          end

          x += 1
        end
        pl += 1
        next
      end

      # regular flat
      Doocr.ds_source = CDoom.w_cache_lump_num(Doocr.firstflat +
                                               Doocr.flattranslation[pl.value.picnum],
        Doocr::PU_STATIC).as(UInt8*)

      Doocr.planeheight = doom_abs(pl.value.height - Doocr.viewz)
      light = (pl.value.lightlevel >> Doocr::LIGHTSEGSHIFT) + Doocr.extralight

      light = Doocr::LIGHTLEVELS - 1 if light >= Doocr::LIGHTLEVELS

      light = 0 if light < 0

      Doocr.planezlight = Doocr.zlight.to_unsafe + light * Doocr::MAXLIGHTZ

      (pl.value.top.to_unsafe + (pl.value.maxx + 1)).value = 0xff
      (pl.value.top.to_unsafe + (pl.value.minx - 1)).value = 0xff

      stop = pl.value.maxx + 1

      x = pl.value.minx
      while x <= stop
        CDoom.r_make_spans(x, (pl.value.top.to_unsafe + (x - 1)).value,
          (pl.value.bottom.to_unsafe + (x - 1)).value,
          (pl.value.top.to_unsafe + x).value,
          (pl.value.bottom.to_unsafe + x).value)

        x += 1
      end

      pl += 1
      z_change_tag(Doocr.ds_source, Doocr::PU_CACHE)
    end
  end

  def self.r_render_masked_seg_range(ds : CDoom::Drawseg*, x1 : LibC::Int, x2 : LibC::Int)
    # Calculate light table.
    # Use different light tables
    #   for horizontal / vertical / diagonal. Diagonal?
    # OPTIMIZE: get rid of LIGHTSEGSHIFT globally
    Doocr.curline = ds.value.curline
    Doocr.frontsector = Doocr.curline.value.frontsector
    Doocr.backsector = Doocr.curline.value.backsector
    texnum = Doocr.texturetranslation[Doocr.curline.value.sidedef.value.midtexture]

    lightnum = (Doocr.frontsector.value.lightlevel >> Doocr::LIGHTSEGSHIFT) + Doocr.extralight

    if Doocr.curline.value.v1.value.y == Doocr.curline.value.v2.value.y
      lightnum -= 1
    elsif Doocr.curline.value.v1.value.x == Doocr.curline.value.v2.value.x
      lightnum += 1
    end

    if lightnum < 0
      Doocr.walllights = Doocr.scalelight[0].to_unsafe
    elsif lightnum >= Doocr::LIGHTLEVELS
      Doocr.walllights = Doocr.scalelight[Doocr::LIGHTLEVELS - 1].to_unsafe
    else
      Doocr.walllights = Doocr.scalelight[lightnum].to_unsafe
    end

    Doocr.maskedtexturecol = ds.value.maskedtexturecol

    Doocr.rw_scalestep = ds.value.scalestep
    Doocr.spryscale = ds.value.scale1 + (x1 - ds.value.x1) * Doocr.rw_scalestep
    Doocr.mfloorclip = ds.value.sprbottomclip
    Doocr.mceilingclip = ds.value.sprtopclip

    # find positioning
    if Doocr.curline.value.linedef.value.flags & Doocr::ML_DONTPEGBOTTOM != 0
      Doocr.dc_texturemid = Doocr.frontsector.value.floorheight > Doocr.backsector.value.floorheight ? Doocr.frontsector.value.floorheight : Doocr.backsector.value.floorheight
      Doocr.dc_texturemid = Doocr.dc_texturemid + Doocr.textureheight[texnum] - Doocr.viewz
    else
      Doocr.dc_texturemid = Doocr.frontsector.value.ceilingheight < Doocr.backsector.value.ceilingheight ? Doocr.frontsector.value.ceilingheight : Doocr.backsector.value.ceilingheight
      Doocr.dc_texturemid = Doocr.dc_texturemid - Doocr.viewz
    end
    Doocr.dc_texturemid += Doocr.curline.value.sidedef.value.rowoffset

    Doocr.dc_colormap = Doocr.fixedcolormap if !Doocr.fixedcolormap.null?

    # draw the columns
    Doocr.dc_x = x1
    while Doocr.dc_x <= x2
      # calculate lighting
      if Doocr.maskedtexturecol[Doocr.dc_x] != Int16::MAX
        if Doocr.fixedcolormap.null?
          index = Doocr.spryscale >> Doocr::LIGHTSCALESHIFT

          index = Doocr::MAXLIGHTSCALE - 1 if index >= Doocr::MAXLIGHTSCALE

          Doocr.dc_colormap = Doocr.walllights[index]
        end

        Doocr.sprtopscreen = Doocr.centeryfrac - CDoom.fixed_mul(Doocr.dc_texturemid, Doocr.spryscale)
        Doocr.dc_iscale = Doocr.inverse_scale(Doocr.spryscale)

        # draw the texture
        col = (CDoom.r_get_column(texnum, Doocr.maskedtexturecol[Doocr.dc_x]) - 3).as(CDoom::Post*)

        CDoom.r_draw_masked_column(col)
        Doocr.maskedtexturecol[Doocr.dc_x] = Int16::MAX
      end
      Doocr.spryscale += Doocr.rw_scalestep
      Doocr.dc_x += 1
    end
  end

  #
  # Draws zero, one, or two textures (and possibly a masked
  #  texture) for walls.
  # Can draw or mark the starting pixel of floor and ceiling
  #  textures.
  # CALLED: CORE LOOPING ROUTINE.
  #
  def self.r_render_seg_loop
    while Doocr.rw_x < Doocr.rw_stopx
      # mark floor / ceiling areas
      yl = (Doocr.topfrac + Doocr::HEIGHTUNIT - 1) >> Doocr::HEIGHTBITS

      # no space above wall?
      yl = Doocr.ceilingclip[Doocr.rw_x] + 1 if yl < Doocr.ceilingclip[Doocr.rw_x] + 1

      if Doocr.markceiling != 0
        top = Doocr.ceilingclip[Doocr.rw_x] + 1
        bottom = yl - 1

        bottom = Doocr.floorclip[Doocr.rw_x] - 1 if bottom >= Doocr.floorclip[Doocr.rw_x]

        if top <= bottom
          ((@@visplanes.to_unsafe + @@ceilingplane).value.top.to_unsafe + Doocr.rw_x).value = top.to_u8!
          ((@@visplanes.to_unsafe + @@ceilingplane).value.bottom.to_unsafe + Doocr.rw_x).value = bottom.to_u8!
        end
      end

      yh = Doocr.bottomfrac >> Doocr::HEIGHTBITS

      yh = Doocr.floorclip[Doocr.rw_x] - 1 if yh >= Doocr.floorclip[Doocr.rw_x]

      if Doocr.markfloor != 0
        top = yh + 1
        bottom = Doocr.floorclip[Doocr.rw_x] - 1
        top = Doocr.ceilingclip[Doocr.rw_x] + 1 if top <= Doocr.ceilingclip[Doocr.rw_x]
        if top <= bottom
          ((@@visplanes.to_unsafe + @@floorplane).value.top.to_unsafe + Doocr.rw_x).value = top.to_u8!
          ((@@visplanes.to_unsafe + @@floorplane).value.bottom.to_unsafe + Doocr.rw_x).value = bottom.to_u8!
        end
      end

      texturecolumn = 0

      # texturecolumn and lighting are independent of wall tiers
      if Doocr.segtextured != 0
        # calculate texture offset
        angle = (Doocr.rw_centerangle &+ Doocr.xtoviewangle[Doocr.rw_x]) >> Doocr::ANGLETOFINESHIFT
        angle = 0_u32 if angle >= (FINEANGLES.tdiv(2))
        texturecolumn = Doocr.rw_offset - CDoom.fixed_mul(@@finetangent[angle], Doocr.rw_distance)
        texturecolumn >>= FRACBITS
        # calculate lighting
        index = Doocr.rw_scale >> Doocr::LIGHTSCALESHIFT

        index = Doocr::MAXLIGHTSCALE - 1 if index >= Doocr::MAXLIGHTSCALE

        Doocr.dc_colormap = Doocr.walllights[index]
        Doocr.dc_x = Doocr.rw_x
        Doocr.dc_iscale = Doocr.inverse_scale(Doocr.rw_scale)
      end

      # draw the wall tiers
      if Doocr.midtexture != 0
        # single sided line
        Doocr.dc_yl = yl.to_i32!
        Doocr.dc_yh = yh.to_i32!
        Doocr.dc_texturemid = Doocr.rw_midtexturemid
        Doocr.dc_source = CDoom.r_get_column(Doocr.midtexture, texturecolumn)
        Doocr.colfunc.call
        Doocr.ceilingclip[Doocr.rw_x] = Doocr.viewheight.to_i16!
        Doocr.floorclip[Doocr.rw_x] = -1
      else
        # two sided line
        if Doocr.toptexture != 0
          # top wall
          mid = Doocr.pixhigh >> Doocr::HEIGHTBITS
          Doocr.pixhigh += Doocr.pixhighstep

          mid = Doocr.floorclip[Doocr.rw_x] - 1 if mid >= Doocr.floorclip[Doocr.rw_x]

          if mid >= yl
            Doocr.dc_yl = yl.to_i32!
            Doocr.dc_yh = mid.to_i32!
            Doocr.dc_texturemid = Doocr.rw_toptexturemid
            Doocr.dc_source = CDoom.r_get_column(Doocr.toptexture, texturecolumn)
            Doocr.colfunc.call
            Doocr.ceilingclip[Doocr.rw_x] = mid.to_i16!
          else
            Doocr.ceilingclip[Doocr.rw_x] = yl.to_i16! - 1
          end
        else
          # no top wall
          Doocr.ceilingclip[Doocr.rw_x] = yl.to_i16! - 1 if Doocr.markceiling != 0
        end

        if Doocr.bottomtexture != 0
          # bottom wall
          mid = (Doocr.pixlow + Doocr::HEIGHTUNIT - 1) >> Doocr::HEIGHTBITS
          Doocr.pixlow += Doocr.pixlowstep

          # no space above wall?
          mid = Doocr.ceilingclip[Doocr.rw_x] + 1 if mid <= Doocr.ceilingclip[Doocr.rw_x]

          if mid <= yh
            Doocr.dc_yl = mid.to_i32!
            Doocr.dc_yh = yh.to_i32!
            Doocr.dc_texturemid = Doocr.rw_bottomtexturemid
            Doocr.dc_source = CDoom.r_get_column(Doocr.bottomtexture,
              texturecolumn)
            Doocr.colfunc.call
            Doocr.floorclip[Doocr.rw_x] = mid.to_i16!
          else
            Doocr.floorclip[Doocr.rw_x] = yh.to_i16! + 1
          end
        else
          # no bottom wall
          Doocr.floorclip[Doocr.rw_x] = yh.to_i16! + 1 if Doocr.markfloor != 0
        end

        if Doocr.maskedtexture != 0
          # save texturecol
          #  for backdrawing of masked mid texture
          Doocr.maskedtexturecol[Doocr.rw_x] = texturecolumn.to_i16!
        end
      end

      Doocr.rw_scale += Doocr.rw_scalestep
      Doocr.topfrac += Doocr.topstep
      Doocr.bottomfrac += Doocr.bottomstep

      Doocr.rw_x += 1
    end
  end

  #
  # A wall segment will be drawn
  #  between start and stop pixels (inclusive).
  #
  def self.r_store_wall_range(start : LibC::Int, stop : LibC::Int)
    # don't overflow and crash
    return if Doocr.ds_p == Doocr.drawsegs.to_unsafe + Doocr::MAXDRAWSEGS

    {% if flag?("RANGECHECK") %}
      if start >= Doocr.viewwidth || start > stop
        CDoom.i_error("Error: bad r_render_wall_range: #{start} to #{stop}")
      end
    {% end %}

    Doocr.sidedef = Doocr.curline.value.sidedef
    Doocr.linedef = Doocr.curline.value.linedef

    # mark the segment as visible for auto map
    Doocr.linedef.value.flags = Doocr.linedef.value.flags | Doocr::ML_MAPPED

    # calculate rw_distance for scale calculation
    Doocr.rw_normalangle = Doocr.curline.value.angle &+ ANG90
    offsetangle = Doocr.rw_normalangle &- Doocr.rw_angle1
    offsetangle = (-(offsetangle.to_i32!)).to_u32! if offsetangle > ANG180

    offsetangle = ANG90 if offsetangle > ANG90

    distangle = ANG90 &- offsetangle
    hyp = CDoom.r_point_to_dist(Doocr.curline.value.v1.value.x, Doocr.curline.value.v1.value.y)
    sineval = @@finesine[distangle >> Doocr::ANGLETOFINESHIFT]
    Doocr.rw_distance = CDoom.fixed_mul(hyp, sineval)

    Doocr.ds_p.value.x1 = start
    Doocr.rw_x = start
    Doocr.ds_p.value.x2 = stop
    Doocr.ds_p.value.curline = Doocr.curline
    Doocr.rw_stopx = stop + 1

    # calculate scale at both ends and step
    Doocr.ds_p.value.scale1 = CDoom.r_scale_from_global_angle(Doocr.viewangle &+ Doocr.xtoviewangle[start])
    Doocr.rw_scale = Doocr.ds_p.value.scale1

    if stop > start
      Doocr.ds_p.value.scale2 = CDoom.r_scale_from_global_angle(Doocr.viewangle &+ Doocr.xtoviewangle[stop])
      Doocr.ds_p.value.scalestep = (Doocr.ds_p.value.scale2 - Doocr.rw_scale).tdiv(stop - start)
      Doocr.rw_scalestep = Doocr.ds_p.value.scalestep
    else
      Doocr.ds_p.value.scale2 = Doocr.ds_p.value.scale1
    end

    # calculate texture boundaries
    #  and decide if floor / ceiling marks are needed
    Doocr.worldtop = Doocr.frontsector.value.ceilingheight - Doocr.viewz
    Doocr.worldbottom = Doocr.frontsector.value.floorheight - Doocr.viewz

    Doocr.midtexture = 0
    Doocr.toptexture = 0
    Doocr.bottomtexture = 0
    Doocr.maskedtexture = 0
    Doocr.ds_p.value.maskedtexturecol = Pointer(Int16).null

    if Doocr.backsector.null?
      # single sided line
      Doocr.midtexture = Doocr.texturetranslation[Doocr.sidedef.value.midtexture]
      # a single sided line is terminal, so it must mark ends
      Doocr.markfloor = 1
      Doocr.markceiling = 1
      if Doocr.linedef.value.flags & Doocr::ML_DONTPEGBOTTOM != 0
        vtop = Doocr.frontsector.value.floorheight +
               Doocr.textureheight[Doocr.sidedef.value.midtexture]
        # bottom of texture at bottom
        Doocr.rw_midtexturemid = vtop - Doocr.viewz
      else
        # top of texture at top
        Doocr.rw_midtexturemid = Doocr.worldtop
      end
      Doocr.rw_midtexturemid += Doocr.sidedef.value.rowoffset

      Doocr.ds_p.value.silhouette = Doocr::SIL_BOTH
      Doocr.ds_p.value.sprtopclip = Doocr.screenheightarray.to_unsafe
      Doocr.ds_p.value.sprbottomclip = Doocr.negonearray.to_unsafe
      Doocr.ds_p.value.bsilheight = Int32::MAX
      Doocr.ds_p.value.tsilheight = Int32::MIN
    else
      # two sided line
      Doocr.ds_p.value.sprtopclip = Pointer(Int16).null
      Doocr.ds_p.value.sprbottomclip = Pointer(Int16).null
      Doocr.ds_p.value.silhouette = 0

      if Doocr.frontsector.value.floorheight > Doocr.backsector.value.floorheight
        Doocr.ds_p.value.silhouette = Doocr::SIL_BOTTOM
        Doocr.ds_p.value.bsilheight = Doocr.frontsector.value.floorheight
      elsif Doocr.backsector.value.floorheight > Doocr.viewz
        Doocr.ds_p.value.silhouette = Doocr::SIL_BOTTOM
        Doocr.ds_p.value.bsilheight = Int32::MAX
      end

      if Doocr.frontsector.value.ceilingheight < Doocr.backsector.value.ceilingheight
        Doocr.ds_p.value.silhouette = Doocr.ds_p.value.silhouette | Doocr::SIL_TOP
        Doocr.ds_p.value.tsilheight = Doocr.frontsector.value.ceilingheight
      elsif Doocr.backsector.value.ceilingheight < Doocr.viewz
        Doocr.ds_p.value.silhouette = Doocr.ds_p.value.silhouette | Doocr::SIL_TOP
        Doocr.ds_p.value.tsilheight = Int32::MIN
      end

      if Doocr.backsector.value.ceilingheight <= Doocr.frontsector.value.floorheight
        Doocr.ds_p.value.sprbottomclip = Doocr.negonearray.to_unsafe
        Doocr.ds_p.value.bsilheight = Int32::MAX
        Doocr.ds_p.value.silhouette = Doocr.ds_p.value.silhouette | Doocr::SIL_BOTTOM
      end

      if Doocr.backsector.value.floorheight >= Doocr.frontsector.value.ceilingheight
        Doocr.ds_p.value.sprtopclip = Doocr.screenheightarray.to_unsafe
        Doocr.ds_p.value.tsilheight = Int32::MIN
        Doocr.ds_p.value.silhouette = Doocr.ds_p.value.silhouette | Doocr::SIL_TOP
      end

      Doocr.worldhigh = Doocr.backsector.value.ceilingheight - Doocr.viewz
      Doocr.worldlow = Doocr.backsector.value.floorheight - Doocr.viewz

      # hack to allow height changes in outdoor areas
      if Doocr.frontsector.value.ceilingpic == Doocr.skyflatnum &&
         Doocr.backsector.value.ceilingpic == Doocr.skyflatnum
        Doocr.worldtop = Doocr.worldhigh
      end

      if Doocr.worldlow != Doocr.worldbottom ||
         Doocr.backsector.value.floorpic != Doocr.frontsector.value.floorpic ||
         Doocr.backsector.value.lightlevel != Doocr.frontsector.value.lightlevel
        Doocr.markfloor = 1
      else
        # same plane on both sides
        Doocr.markfloor = 0
      end

      if Doocr.worldhigh != Doocr.worldtop ||
         Doocr.backsector.value.ceilingpic != Doocr.frontsector.value.ceilingpic ||
         Doocr.backsector.value.lightlevel != Doocr.frontsector.value.lightlevel
        Doocr.markceiling = 1
      else
        # same plane on both sides
        Doocr.markceiling = 0
      end

      if Doocr.backsector.value.ceilingheight <= Doocr.frontsector.value.floorheight ||
         Doocr.backsector.value.floorheight >= Doocr.frontsector.value.ceilingheight
        # closed door
        Doocr.markceiling = 1
        Doocr.markfloor = 1
      end

      if Doocr.worldhigh < Doocr.worldtop
        # top texture
        Doocr.toptexture = Doocr.texturetranslation[Doocr.sidedef.value.toptexture]
        if Doocr.linedef.value.flags & Doocr::ML_DONTPEGTOP != 0
          # top of texture at top
          Doocr.rw_toptexturemid = Doocr.worldtop
        else
          vtop = Doocr.backsector.value.ceilingheight + Doocr.textureheight[Doocr.sidedef.value.toptexture]
          # bottom of texture
          Doocr.rw_toptexturemid = vtop - Doocr.viewz
        end
      end
      if Doocr.worldlow > Doocr.worldbottom
        # bottom texture
        Doocr.bottomtexture = Doocr.texturetranslation[Doocr.sidedef.value.bottomtexture]
        if Doocr.linedef.value.flags & Doocr::ML_DONTPEGBOTTOM != 0
          # bottom of texture at bottom
          # top of texture at top
          Doocr.rw_bottomtexturemid = Doocr.worldtop
        else # top of texture at top
          Doocr.rw_bottomtexturemid = Doocr.worldlow
        end
      end
      Doocr.rw_toptexturemid &+= Doocr.sidedef.value.rowoffset
      Doocr.rw_bottomtexturemid &+= Doocr.sidedef.value.rowoffset

      # allocate space for masked texture tables
      if Doocr.sidedef.value.midtexture != 0
        Doocr.maskedtexture = 1
        Doocr.ds_p.value.maskedtexturecol = Doocr.lastopening - Doocr.rw_x
        Doocr.maskedtexturecol = Doocr.ds_p.value.maskedtexturecol
        Doocr.lastopening += Doocr.rw_stopx - Doocr.rw_x
      end
    end

    # calculate rw_offset (only needed for textured lines)
    Doocr.segtextured = Doocr.midtexture | Doocr.toptexture | Doocr.bottomtexture | Doocr.maskedtexture

    if Doocr.segtextured != 0
      offsetangle = Doocr.rw_normalangle &- Doocr.rw_angle1

      offsetangle = (-(offsetangle.to_i32!)).to_u32! if offsetangle > ANG180

      offsetangle = ANG90 if offsetangle > ANG90

      sineval = @@finesine[offsetangle >> Doocr::ANGLETOFINESHIFT]
      Doocr.rw_offset = CDoom.fixed_mul(hyp, sineval)

      Doocr.rw_offset = -Doocr.rw_offset if Doocr.rw_normalangle &- Doocr.rw_angle1 < ANG180

      Doocr.rw_offset += Doocr.sidedef.value.textureoffset + Doocr.curline.value.offset
      Doocr.rw_centerangle = (ANG90 &+ Doocr.viewangle &- Doocr.rw_normalangle).to_u32!

      # calculate light table
      #  use different light tables
      #  for horizontal / vertical / diagonal
      # OPTIMIZE: get rid of LIGHTSEGSHIFT globally
      if Doocr.fixedcolormap.null?
        lightnum = (Doocr.frontsector.value.lightlevel >> Doocr::LIGHTSEGSHIFT) + Doocr.extralight

        if Doocr.curline.value.v1.value.y == Doocr.curline.value.v2.value.y
          lightnum -= 1
        elsif Doocr.curline.value.v1.value.x == Doocr.curline.value.v2.value.x
          lightnum += 1
        end

        if lightnum < 0
          Doocr.walllights = Doocr.scalelight[0].to_unsafe
        elsif lightnum >= Doocr::LIGHTLEVELS
          Doocr.walllights = Doocr.scalelight[Doocr::LIGHTLEVELS - 1].to_unsafe
        else
          Doocr.walllights = Doocr.scalelight[lightnum].to_unsafe
        end
      end
    end

    # if a floor / ceiling plane is on the wrong side
    #  of the view plane, it is definitely invisible
    #  and doesn't need to be marked.

    if Doocr.frontsector.value.floorheight >= Doocr.viewz
      # above view plane
      Doocr.markfloor = 0
    end

    if Doocr.frontsector.value.ceilingheight <= Doocr.viewz &&
       Doocr.frontsector.value.ceilingpic != Doocr.skyflatnum
      # below view plane
      Doocr.markceiling = 0
    end

    # calculate incremental stepping values for texture edges
    Doocr.worldtop >>= 4
    Doocr.worldbottom >>= 4

    Doocr.topstep = -CDoom.fixed_mul(Doocr.rw_scalestep, Doocr.worldtop)
    Doocr.topfrac = (Doocr.centeryfrac >> 4) - CDoom.fixed_mul(Doocr.worldtop, Doocr.rw_scale)

    Doocr.bottomstep = -CDoom.fixed_mul(Doocr.rw_scalestep, Doocr.worldbottom)
    Doocr.bottomfrac = (Doocr.centeryfrac >> 4) - CDoom.fixed_mul(Doocr.worldbottom, Doocr.rw_scale)

    if !Doocr.backsector.null?
      Doocr.worldhigh >>= 4
      Doocr.worldlow >>= 4

      if Doocr.worldhigh < Doocr.worldtop
        Doocr.pixhigh = (Doocr.centeryfrac >> 4) - CDoom.fixed_mul(Doocr.worldhigh, Doocr.rw_scale)
        Doocr.pixhighstep = -CDoom.fixed_mul(Doocr.rw_scalestep, Doocr.worldhigh)
      end

      if Doocr.worldlow > Doocr.worldbottom
        Doocr.pixlow = (Doocr.centeryfrac >> 4) - CDoom.fixed_mul(Doocr.worldlow, Doocr.rw_scale)
        Doocr.pixlowstep = -CDoom.fixed_mul(Doocr.rw_scalestep, Doocr.worldlow)
      end
    end

    # render it
    @@ceilingplane = r_check_plane(@@ceilingplane, Doocr.rw_x, Doocr.rw_stopx - 1) if Doocr.markceiling != 0

    @@floorplane = r_check_plane(@@floorplane, Doocr.rw_x, Doocr.rw_stopx - 1) if Doocr.markfloor != 0

    CDoom.r_render_seg_loop

    # save sprite clipping info
    if ((Doocr.ds_p.value.silhouette & Doocr::SIL_TOP != 0) || Doocr.maskedtexture != 0) &&
       Doocr.ds_p.value.sprtopclip.null?
      CDoom.doom_memcpy(Doocr.lastopening, Doocr.ceilingclip.to_unsafe + start, 2 * (Doocr.rw_stopx - start))
      Doocr.ds_p.value.sprtopclip = Doocr.lastopening - start
      Doocr.lastopening += Doocr.rw_stopx - start
    end

    if ((Doocr.ds_p.value.silhouette & Doocr::SIL_BOTTOM != 0) || Doocr.maskedtexture != 0) &&
       Doocr.ds_p.value.sprbottomclip.null?
      CDoom.doom_memcpy(Doocr.lastopening, Doocr.floorclip.to_unsafe + start, 2 * (Doocr.rw_stopx - start))
      Doocr.ds_p.value.sprbottomclip = Doocr.lastopening - start
      Doocr.lastopening += Doocr.rw_stopx - start
    end

    if Doocr.maskedtexture != 0 && Doocr.ds_p.value.silhouette & Doocr::SIL_TOP == 0
      Doocr.ds_p.value.silhouette = Doocr.ds_p.value.silhouette | Doocr::SIL_TOP
      Doocr.ds_p.value.tsilheight = Int32::MIN
    end
    if Doocr.maskedtexture != 0 && Doocr.ds_p.value.silhouette & Doocr::SIL_BOTTOM == 0
      Doocr.ds_p.value.silhouette = Doocr.ds_p.value.silhouette | Doocr::SIL_BOTTOM
      Doocr.ds_p.value.bsilheight = Int32::MAX
    end
    Doocr.ds_p += 1
  end

  #
  # Called whenever the view size changes.
  #
  def self.r_init_sky_map
    Doocr.skytexturemid = 100 * FRACUNIT
  end

  #
  # INITIALIZATION FUNCTIONS
  #

  #
  # Local function for R_InitSprites.
  #
  def self.r_install_sprite_lump(lump : LibC::Int, frame : LibC::UInt, rotation : LibC::UInt, flipped : LibC::Int)
    if frame >= 29 || rotation > 8
      CDoom.i_error("Error: r_install_sprite_lump: Bad frame characters in lump #{lump}")
    end

    Doocr.maxframe = frame.to_i32! if frame.to_i32! > Doocr.maxframe

    if rotation == 0
      # the lump should be used for all rotations
      if Doocr.sprtemp[frame].rotate == 0
        STDERR.puts "Warning: r_install_sprite_lump: Sprite  #{Doocr.spritename} frame #{'A' + frame} has multip rot=0 lump, using lump #{lump}"
      end

      if Doocr.sprtemp[frame].rotate == 1
        STDERR.puts "Warning: r_install_sprite_lump: Sprite  #{Doocr.spritename} frame #{'A' + frame} has rotations, overriding with rot=0 lump #{lump}"
      end

      Doocr.sprtemp[frame].rotate = 0
      8.times do |r|
        Doocr.sprtemp[frame].lump[r] = (lump - Doocr.firstspritelump).to_i16!
        Doocr.sprtemp[frame].flip[r] = flipped.to_u8!
      end
      return
    end

    # the lump is only used for one rotation
    if Doocr.sprtemp[frame].rotate == 0
      STDERR.puts "Warning: r_install_sprite_lump: Sprite  #{Doocr.spritename} frame #{'A' + frame} has rotations, but a rot=0 lump was already set; discarding it"
      # Reset to the -1 "unset" sentinel (matches sprtemp's initial memset) so
      # partial per-rotation data can take over cleanly instead of leaving
      # stale rot=0 lump indices (which could otherwise look like valid,
      # already-filled rotation slots and silently mask missing rotations).
      8.times do |r|
        Doocr.sprtemp[frame].lump[r] = -1_i16
      end
    end

    Doocr.sprtemp[frame].rotate = 1

    # make - based
    rotation -= 1
    if Doocr.sprtemp[frame].lump[rotation] != -1
      STDERR.puts "Warning: r_install_sprite_lump: Sprite #{Doocr.spritename} : #{'A' + frame} : #{'1' + rotation} has two lumps mapped to it, using lump #{lump}"
    end

    Doocr.sprtemp[frame].lump[rotation] = (lump - Doocr.firstspritelump).to_i16!
    Doocr.sprtemp[frame].flip[rotation] = flipped.to_u8!
  end

  #
  # Pass a null terminated list of sprite names
  #  (4 chars exactly) to be used.
  # Builds the sprite rotation matrixes to account
  #  for horizontally flipped sprites.
  # Will report an error if the lumps are inconsistant.
  # Only called at startup.
  #
  # Sprite lump names are 4 characters for the actor,
  #  a letter for the frame, and a number for the rotation.
  # A sprite that is flippable will have an additional
  #  letter/number appended.
  # The rotation character can be 0 to signify no rotations.
  #
  def self.r_init_sprite_defs(namelist : Array(String))
    return if @@sprnames.size == 0

    Doocr.sprites = CDoom.z_malloc(@@sprnames.size * sizeof(CDoom::Spritedef), Doocr::PU_STATIC, Pointer(Void).null).as(CDoom::Spritedef*)

    start = Doocr.firstspritelump - 1
    endl = Doocr.lastspritelump + 1

    # scan all the lump names for each of the names,
    #  noting the highest frame letter.
    # Just compare 4 characters as ints
    @@sprnames.size.times do |i|
      Doocr.spritename = namelist[i]
      29.times do |frame_index|
        Doocr.sprtemp[frame_index].rotate = -1
        8.times do |rotation_index|
          Doocr.sprtemp[frame_index].lump[rotation_index] = -1_i16
          Doocr.sprtemp[frame_index].flip[rotation_index] = 0xff_u8
        end
      end
      Doocr.maxframe = -1
      sprite_name = namelist[i][0, 4].upcase

      # scan the lumps,
      #  filling in the frames for whatever is found
      l = start + 1
      while l < endl
        lump_name = @@lumpinfo[l].name
        if lump_name.size >= 6 && lump_name[0, 4].upcase == sprite_name
          frame = (lump_name[4].ord - 'A'.ord).to_u32!
          rotation = (lump_name[5].ord - '0'.ord).to_u32!

          if Doocr.modifiedgame != 0
            patched = CDoom.w_get_num_for_name(lump_name.to_unsafe)
          else
            patched = l
          end

          Doocr.r_install_sprite_lump(patched, frame, rotation, 0)

          if lump_name.size >= 8 && lump_name[6] != '\0'
            frame = (lump_name[6].ord - 'A'.ord).to_u32!
            rotation = (lump_name[7].ord - '0'.ord).to_u32!
            Doocr.r_install_sprite_lump(l, frame, rotation, 1)
          end
        end

        l += 1
      end

      # check the frames that were found for completeness
      if Doocr.maxframe == -1
        Doocr.sprites[i].numframes = 0
        next
      end

      Doocr.maxframe += 1

      Doocr.maxframe.times do |frame|
        case Doocr.sprtemp[frame].rotate
        when -1
          CDoom.i_error("Error: r_init_sprite_defs: No patches found for #{namelist[i]} frame #{'A' + frame}")
        when 0
          # only the first rotation is needed
        when 1
          # must have all 8 frames
          8.times do |rotation|
            if Doocr.sprtemp[frame].lump[rotation] == -1
              CDoom.i_error("Error: r_init_sprite_defs: Sprite #{namelist[i]} frame #{'A' + frame} is missing rotations")
            end
          end
        end
      end

      # allocate space for the frames present and copy sprtemp to it
      (Doocr.sprites + i).value.numframes = Doocr.maxframe
      (Doocr.sprites + i).value.spriteframes =
        CDoom.z_malloc(Doocr.maxframe * sizeof(CDoom::Spriteframe), Doocr::PU_STATIC, Pointer(Void).null).as(CDoom::Spriteframe*)
      Doocr.maxframe.times do |frame|
        native_frame = (Doocr.sprites + i).value.spriteframes + frame
        native_frame.value.rotate = Doocr.sprtemp[frame].rotate
        8.times do |rotation|
          native_frame.value.lump[rotation] = Doocr.sprtemp[frame].lump[rotation]
          native_frame.value.flip[rotation] = Doocr.sprtemp[frame].flip[rotation]
        end
      end
    end
  end

  #
  # GAME FUNCTIONS
  #

  #
  # Called at program start.
  #
  def self.r_init_sprites(namelist : Array(String))
    CDoom::SCREENWIDTH.times { |i| Doocr.negonearray[i] = -1 }
    r_init_sprite_defs(namelist)
  end

  #
  # Called at frame start.
  #
  def self.r_clear_sprites
    Doocr.vissprite_count = 0
  end

  def self.r_new_vis_sprite : CDoom::Vissprite*
    return Doocr.overflowsprite.to_unsafe if Doocr.vissprite_count == Doocr::MAXVISSPRITES

    sprite = Doocr.vissprites.to_unsafe + Doocr.vissprite_count
    Doocr.vissprite_count += 1
    return sprite
  end

  #
  # Used for sprites and masked mid textures.
  # Masked means: partly transparent, i.e. stored
  #  in posts/runs of opaque pixels.
  #
  def self.r_draw_masked_column(column : CDoom::Post*)
    basetexturemid = Doocr.dc_texturemid

    until column.value.topdelta == 0xff
      # calculate unclipped screen coordinates
      #  for post
      topscreen = Doocr.sprtopscreen + Doocr.spryscale * column.value.topdelta
      bottomscreen = topscreen + Doocr.spryscale * column.value.length

      Doocr.dc_yl = (topscreen + FRACUNIT - 1) >> FRACBITS
      Doocr.dc_yh = (bottomscreen - 1) >> FRACBITS

      Doocr.dc_yh = Doocr.mfloorclip[Doocr.dc_x] - 1 if Doocr.dc_yh >= Doocr.mfloorclip[Doocr.dc_x]
      Doocr.dc_yl = Doocr.mceilingclip[Doocr.dc_x] + 1 if Doocr.dc_yl <= Doocr.mceilingclip[Doocr.dc_x]

      if Doocr.dc_yl <= Doocr.dc_yh
        Doocr.dc_source = column.as(UInt8*) + 3
        Doocr.dc_texturemid = basetexturemid - (column.value.topdelta.to_i32 << FRACBITS)

        # Drawn by either r_draw_column
        #  or (SHADOW) r_draw_fuzz_column
        Doocr.colfunc.call
      end
      column = (column.as(UInt8*) + column.value.length + 4).as(CDoom::Post*)
    end
    Doocr.dc_texturemid = basetexturemid
  end

  def self.r_draw_vis_sprite(vis : CDoom::Vissprite*, x1 : LibC::Int, x2 : LibC::Int)
    patch = CDoom.w_cache_lump_num(vis.value.patch + Doocr.firstspritelump, Doocr::PU_CACHE).as(CDoom::Patch*)

    Doocr.dc_colormap = vis.value.colormap

    if Doocr.dc_colormap.null?
      # 0 colormap = shadow draw
      Doocr.colfunc = ->CDoom.r_draw_fuzz_column
    elsif vis.value.mobjflags & Doocr::Mobjflag::MF_TRANSLATION.value != 0
      Doocr.colfunc = ->CDoom.r_draw_translated_column
      Doocr.dc_translation = Doocr.translationtables.to_unsafe - 256 +
                             ((vis.value.mobjflags & Doocr::Mobjflag::MF_TRANSLATION.value) >> (Doocr::Mobjflag::MF_TRANSSHIFT.value - 8))
    end

    Doocr.dc_iscale = doom_abs(vis.value.xiscale)
    Doocr.dc_texturemid = vis.value.texturemid
    frac = vis.value.startfrac
    Doocr.spryscale = vis.value.scale
    Doocr.sprtopscreen = Doocr.centeryfrac - CDoom.fixed_mul(Doocr.dc_texturemid, Doocr.spryscale)

    Doocr.dc_x = vis.value.x1
    while Doocr.dc_x <= vis.value.x2
      texturecolumn = frac >> FRACBITS
      {% if flag?("RANGECHECK") %}
        if texturecolumn < 0 || texturecolumn >= patch.value.width
          CDoom.i_error("Error: r_draw_vis_sprite: bad texturecolumn")
        end
      {% end %}
      column = (patch.as(UInt8*) + (patch.value.columnofs.to_unsafe + texturecolumn).value).as(CDoom::Post*)
      CDoom.r_draw_masked_column(column)

      Doocr.dc_x += 1
      frac += vis.value.xiscale
    end

    Doocr.colfunc = ->CDoom.r_draw_column
  end

  #
  # Generates a vissprite for a thing
  #  if it might be visible.
  #
  def self.r_project_sprite(thing : CDoom::Mobj*)
    return if thing.value.sprite == Doocr::Spritenum::SPR_TNT

    # transform the origin point
    tr_x = thing.value.x - Doocr.viewx
    tr_y = thing.value.y - Doocr.viewy

    gxt = CDoom.fixed_mul(tr_x, Doocr.viewcos)
    gyt = -CDoom.fixed_mul(tr_y, Doocr.viewsin)

    tz = gxt &- gyt

    # thing is behind view plane?
    return if tz < Doocr::MINZ

    xscale = CDoom.fixed_div(Doocr.projection, tz)

    gxt = -CDoom.fixed_mul(tr_x, Doocr.viewsin)
    gyt = CDoom.fixed_mul(tr_y, Doocr.viewcos)
    tx = -(gyt + gxt)

    # too far off the side?
    return if doom_abs(tx) > (tz << 2)

    # decide which patch to use for sprite relative to player
    {% if flag?("RANGECHECK") %}
      if thing.value.sprite.to_u32! >= @@sprnames.size.to_u32!
        CDoom.i_error("Error: r_project_sprite: invalid sprite number #{thing.value.sprite.value} ")
      end
    {% end %}
    sprdef = Doocr.sprites + thing.value.sprite.value
    {% if flag?("RANGECHECK") %}
      if thing.value.frame & Doocr::FF_FRAMEMASK >= sprdef.value.numframes
        CDoom.i_error("Error: r_project_sprite: invalid sprite frame #{thing.value.sprite.value} : #{thing.value.frame} ")
      end
    {% end %}
    sprframe = sprdef.value.spriteframes + (thing.value.frame & Doocr::FF_FRAMEMASK)

    if sprframe.value.rotate != 0
      # choose a different rotation based on player view
      ang = CDoom.r_point_to_angle(thing.value.x, thing.value.y)
      rot = (ang &- thing.value.angle &+ (ANG45.tdiv(2)).to_u32! * 9) >> 29
      lump = sprframe.value.lump[rot]
      flip = sprframe.value.flip[rot]
    else
      # use single rotation for all views
      lump = sprframe.value.lump[0]
      flip = sprframe.value.flip[0]
    end

    # calculate edges of the shape
    tx -= Doocr.spriteoffset[lump]
    x1 = (Doocr.centerxfrac + CDoom.fixed_mul(tx, xscale)) >> FRACBITS

    # off the right side?
    return if x1 > Doocr.viewwidth

    tx += Doocr.spritewidth[lump]
    x2 = ((Doocr.centerxfrac + CDoom.fixed_mul(tx, xscale)) >> FRACBITS) - 1

    # off the left side
    return if x2 < 0

    # store information in a vissprite
    vis = CDoom.r_new_vis_sprite
    vis.value.mobjflags = thing.value.flags
    vis.value.scale = xscale
    vis.value.gx = thing.value.x
    vis.value.gy = thing.value.y
    vis.value.gz = thing.value.z
    vis.value.gzt = thing.value.z + Doocr.spritetopoffset[lump]
    vis.value.texturemid = vis.value.gzt - Doocr.viewz
    vis.value.x1 = x1 < 0 ? 0 : x1
    vis.value.x2 = x2 >= Doocr.viewwidth ? Doocr.viewwidth - 1 : x2
    iscale = CDoom.fixed_div(FRACUNIT, xscale)

    if flip != 0
      vis.value.startfrac = Doocr.spritewidth[lump] - 1
      vis.value.xiscale = -iscale
    else
      vis.value.startfrac = 0
      vis.value.xiscale = iscale
    end

    if vis.value.x1 > x1
      vis.value.startfrac = vis.value.startfrac + vis.value.xiscale * (vis.value.x1 - x1)
    end
    vis.value.patch = lump

    # get light level
    if thing.value.flags & Doocr::Mobjflag::MF_SHADOW.value != 0
      # shadow draw
      vis.value.colormap = Pointer(UInt8).null
    elsif !Doocr.fixedcolormap.null?
      # fixed map
      vis.value.colormap = Doocr.fixedcolormap
    elsif thing.value.frame & Doocr::FF_FULLBRIGHT != 0
      # full bright
      vis.value.colormap = Doocr.colormaps
    else
      # diminished light
      index = xscale >> Doocr::LIGHTSCALESHIFT

      index = Doocr::MAXLIGHTSCALE - 1 if index >= Doocr::MAXLIGHTSCALE

      vis.value.colormap = Doocr.spritelights[index]
    end
  end

  #
  # During BSP traversal, this adds sprites by sector.
  #
  def self.r_add_sprites(sec : CDoom::Sector*)
    # BSP is traversed by subsector.
    # A sector might have been split into several
    #  subsectors during BSP building.
    # Thus we check whether its already added.
    return if sec.value.validcount == Doocr.validcount

    # Well, now it will be done.
    sec.value.validcount = Doocr.validcount

    lightnum = (sec.value.lightlevel >> Doocr::LIGHTSEGSHIFT) + Doocr.extralight

    if lightnum < 0
      Doocr.spritelights = Doocr.scalelight[0].to_unsafe
    elsif lightnum >= Doocr::LIGHTLEVELS
      Doocr.spritelights = Doocr.scalelight[Doocr::LIGHTLEVELS - 1].to_unsafe
    else
      Doocr.spritelights = Doocr.scalelight[lightnum].to_unsafe
    end

    # Handle all things in sector.
    thing = sec.value.thinglist
    until thing.null?
      CDoom.r_project_sprite(thing)
      thing = thing.value.snext
    end
  end

  def self.r_draw_psprite(psp : CDoom::Pspdef*)
    return if psp.value.state.value.sprite == Doocr::Spritenum::SPR_TNT

    # decide which patch to use
    {% if flag?("RANGECHECK") %}
      if psp.value.state.value.sprite.value >= @@sprnames.size
        CDoom.i_error("Error: r_draw_psprite: invalid sprite number #{psp.value.state.value.sprite.value} ")
      end
    {% end %}
    sprdef = Doocr.sprites + psp.value.state.value.sprite.value
    {% if flag?("RANGECHECK") %}
      if psp.value.state.value.frame & Doocr::FF_FRAMEMASK >= sprdef.value.numframes
        CDoom.i_error("Error: r_draw_psprite: invalid sprite frame #{psp.value.state.value.sprite.value} : #{psp.value.state.value.frame} ")
      end
    {% end %}
    sprframe = sprdef.value.spriteframes + (psp.value.state.value.frame & Doocr::FF_FRAMEMASK)

    lump = sprframe.value.lump[0]
    flip = sprframe.value.flip[0]

    # calculate edges of the shape
    tx = psp.value.sx - 160 * FRACUNIT

    tx -= Doocr.spriteoffset[lump]
    x1 = (Doocr.centerxfrac + CDoom.fixed_mul(tx, Doocr.pspritescale)) >> FRACBITS

    # off the right side?
    return if x1 > Doocr.viewwidth

    tx += Doocr.spritewidth[lump]
    x2 = ((Doocr.centerxfrac + CDoom.fixed_mul(tx, Doocr.pspritescale)) >> FRACBITS) - 1

    # off the left side
    return if x2 < 0

    avis = CDoom::Vissprite.new
    # store information in a vissprite
    vis = pointerof(avis)
    vis.value.mobjflags = 0
    vis.value.texturemid = (Doocr::BASEYCENTER << FRACBITS) + FRACUNIT // 2 - (psp.value.sy - Doocr.spritetopoffset[lump])
    vis.value.x1 = x1 < 0 ? 0 : x1
    vis.value.x2 = x2 >= Doocr.viewwidth ? Doocr.viewwidth - 1 : x2
    vis.value.scale = Doocr.pspritescale

    if flip != 0
      vis.value.xiscale = -Doocr.pspriteiscale
      vis.value.startfrac = Doocr.spritewidth[lump] - 1
    else
      vis.value.xiscale = Doocr.pspriteiscale
      vis.value.startfrac = 0
    end

    if vis.value.x1 > x1
      vis.value.startfrac = vis.value.startfrac + vis.value.xiscale * (vis.value.x1 - x1)
    end
    vis.value.patch = lump

    # get light level
    if Doocr.viewplayer.value.powers[Doocr::Powertype::Invisibility.value] > 4 * 32 ||
       Doocr.viewplayer.value.powers[Doocr::Powertype::Invisibility.value] & 8 != 0
      # shadow draw
      vis.value.colormap = Pointer(UInt8).null
    elsif !Doocr.fixedcolormap.null?
      # fixed map
      vis.value.colormap = Doocr.fixedcolormap
    elsif psp.value.state.value.frame & Doocr::FF_FULLBRIGHT != 0
      # full bright
      vis.value.colormap = Doocr.colormaps
    else
      # local light
      vis.value.colormap = Doocr.spritelights[Doocr::MAXLIGHTSCALE - 1]
    end

    CDoom.r_draw_vis_sprite(vis, vis.value.x1, vis.value.x2)
  end

  def self.r_draw_player_sprites
    # get light level
    lightnum =
      (Doocr.viewplayer.value.mo.value.subsector.value.sector.value.lightlevel >> Doocr::LIGHTSEGSHIFT) +
        Doocr.extralight

    if lightnum < 0
      Doocr.spritelights = Doocr.scalelight[0].to_unsafe
    elsif lightnum >= Doocr::LIGHTLEVELS
      Doocr.spritelights = Doocr.scalelight[Doocr::LIGHTLEVELS - 1].to_unsafe
    else
      Doocr.spritelights = Doocr.scalelight[lightnum].to_unsafe
    end

    # clip to screen bounds
    Doocr.mfloorclip = Doocr.screenheightarray.to_unsafe
    Doocr.mceilingclip = Doocr.negonearray.to_unsafe

    # add all active psprites
    psp = Doocr.viewplayer.value.psprites.to_unsafe
    Doocr::Psprnum::NUMPSPRITES.value.times do |i|
      CDoom.r_draw_psprite(psp) unless psp.value.state.null?
      psp += 1
    end
  end

  def self.r_sort_vis_sprites
    count = Doocr.vissprite_count

    unsorted = CDoom::Vissprite.new
    unsorted.next = pointerof(unsorted)
    unsorted.prev = unsorted.next

    return if count == 0

    ds = Doocr.vissprites.to_unsafe
    while ds < Doocr.vissprites.to_unsafe + Doocr.vissprite_count
      ds.value.next = ds + 1
      ds.value.prev = ds - 1
      ds += 1
    end

    Doocr.vissprites.to_unsafe.value.prev = pointerof(unsorted)
    unsorted.next = Doocr.vissprites.to_unsafe
    (Doocr.vissprites.to_unsafe + Doocr.vissprite_count - 1).value.next = pointerof(unsorted)
    unsorted.prev = Doocr.vissprites.to_unsafe + Doocr.vissprite_count - 1

    # pull the vissprites out by scale
    Doocr.vsprsortedhead.to_unsafe.value.next = Doocr.vsprsortedhead.to_unsafe
    Doocr.vsprsortedhead.to_unsafe.value.prev = Doocr.vsprsortedhead.to_unsafe.value.next
    best = Pointer(CDoom::Vissprite).null # shut up the compiler warning
    count.times do |i|
      bestscale = Int32::MAX
      ds = unsorted.next
      while ds != pointerof(unsorted)
        if ds.value.scale < bestscale
          bestscale = ds.value.scale
          best = ds
        end
        ds = ds.value.next
      end
      best.value.next.value.prev = best.value.prev
      best.value.prev.value.next = best.value.next
      best.value.next = Doocr.vsprsortedhead.to_unsafe
      best.value.prev = Doocr.vsprsortedhead.to_unsafe.value.prev
      Doocr.vsprsortedhead.to_unsafe.value.prev.value.next = best
      Doocr.vsprsortedhead.to_unsafe.value.prev = best
    end
  end

  def self.r_draw_sprite(spr : CDoom::Vissprite*)
    clipbot = uninitialized StaticArray(Int16, CDoom::SCREENWIDTH)
    cliptop = uninitialized StaticArray(Int16, CDoom::SCREENWIDTH)

    x = spr.value.x1
    while x <= spr.value.x2
      clipbot[x] = -2
      cliptop[x] = -2
      x += 1
    end

    # Scan drawsegs from end to start for obscuring segs.
    # The first drawseg that has a greater scale
    #  is the clip seg.
    ds = Doocr.ds_p - 1
    while ds >= Doocr.drawsegs.to_unsafe
      # determine if the drawseg obscures the sprite
      if ds.value.x1 > spr.value.x2 ||
         ds.value.x2 < spr.value.x1 ||
         (ds.value.silhouette == 0 &&
         ds.value.maskedtexturecol.null?)
        # does not cover sprite
        ds -= 1
        next
      end

      r1 = ds.value.x1 < spr.value.x1 ? spr.value.x1 : ds.value.x1
      r2 = ds.value.x2 > spr.value.x2 ? spr.value.x2 : ds.value.x2

      if ds.value.scale1 > ds.value.scale2
        lowscale = ds.value.scale2
        scale = ds.value.scale1
      else
        lowscale = ds.value.scale1
        scale = ds.value.scale2
      end

      if scale < spr.value.scale ||
         (lowscale < spr.value.scale &&
         CDoom.r_point_on_seg_side(spr.value.gx, spr.value.gy, ds.value.curline) == 0)
        # masked mid texture?
        CDoom.r_render_masked_seg_range(ds, r1, r2) unless ds.value.maskedtexturecol.null?
        # seg is behind sprite
        ds -= 1
        next
      end

      # clip this piece of the sprite
      silhouette = ds.value.silhouette

      silhouette &= ~Doocr::SIL_BOTTOM if spr.value.gz >= ds.value.bsilheight

      silhouette &= ~Doocr::SIL_TOP if spr.value.gzt <= ds.value.tsilheight

      if silhouette == 1
        # bottom sil
        x = r1
        while x <= r2
          clipbot[x] = ds.value.sprbottomclip[x] if clipbot[x] == -2
          x += 1
        end
      elsif silhouette == 2
        # top sil
        x = r1
        while x <= r2
          cliptop[x] = ds.value.sprtopclip[x] if cliptop[x] == -2
          x += 1
        end
      elsif silhouette == 3
        # both
        x = r1
        while x <= r2
          clipbot[x] = ds.value.sprbottomclip[x] if clipbot[x] == -2
          cliptop[x] = ds.value.sprtopclip[x] if cliptop[x] == -2
          x += 1
        end
      end

      ds -= 1
    end

    # all clipping has been performed, so draw the sprite

    # check for unclipped columns
    x = spr.value.x1
    while x <= spr.value.x2
      clipbot[x] = Doocr.viewheight.to_i16! if clipbot[x] == -2
      cliptop[x] = -1 if cliptop[x] == -2
      x += 1
    end

    Doocr.mfloorclip = clipbot.to_unsafe
    Doocr.mceilingclip = cliptop.to_unsafe
    CDoom.r_draw_vis_sprite(spr, spr.value.x1, spr.value.x2)
  end

  def self.r_draw_masked
    CDoom.r_sort_vis_sprites

    if Doocr.vissprite_count > 0
      # draw all vissprites back to front
      spr = Doocr.vsprsortedhead.to_unsafe.value.next
      while spr != Doocr.vsprsortedhead.to_unsafe
        CDoom.r_draw_sprite(spr)
        spr = spr.value.next
      end
    end

    # render any remaining masked mid textures
    ds = Doocr.ds_p - 1
    while ds >= Doocr.drawsegs.to_unsafe
      unless ds.value.maskedtexturecol.null?
        CDoom.r_render_masked_seg_range(ds, ds.value.x1, ds.value.x2)
      end
      ds -= 1
    end

    # draw the psprites on top of everything
    #  but does not draw on side views
    CDoom.r_draw_player_sprites if Doocr.viewangleoffset == 0
  end
end
