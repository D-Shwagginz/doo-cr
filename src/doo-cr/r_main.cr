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
    CDoom.ds_p = CDoom.drawsegs.to_unsafe
  end

  #
  # Does handle solid walls,
  #  e.g. single sided LineDefs (middle texture)
  #  that entirely block the view.
  #
  def self.r_clip_solid_wall_segment(first : LibC::Int, last : LibC::Int)
    # Find the first range that touches the range
    #  (adjacent pixels are touching).
    start = CDoom.solidsegs.to_unsafe
    while start.value.last < first - 1
      start += 1
    end

    if first < start.value.first
      if last < start.value.first - 1
        # Post is entirely visible (above start),
        #  so insert a new clippost.
        CDoom.r_store_wall_range(first, last)
        nextc = CDoom.newend
        CDoom.newend += 1

        while nextc != start
          nextc.value = (nextc - 1).value
          nextc -= 1
        end
        nextc.value.first = first
        nextc.value.last = last
        return
      end

      # There is a fragment above start.value.
      CDoom.r_store_wall_range(first, start.value.first - 1)
      # Now adjust the clip size.
      start.value.first = first
    end

    # Bottom contained in start?
    return if last <= start.value.last

    nextc = start
    crunch = false
    while last >= (nextc + 1).value.first - 1
      # There is a fragment between two posts.
      CDoom.r_store_wall_range(nextc.value.last + 1, (nextc + 1).value.first - 1)
      nextc += 1

      if last <= nextc.value.last
        # Bottom is contained in next.
        # Adjust the clip size.
        start.value.last = nextc.value.last
        crunch = true
        break
      end
    end

    unless crunch
      # There is a fragment after nextc.value.
      CDoom.r_store_wall_range(nextc.value.last + 1, last)
      # Adjust the clip size.
      start.value.last = last
    end

    # Remove start+1 to next from the clip list,
    # because start now covers their area.
    if nextc == start
      # Post just extended past the bottom of one post.
      return
    end

    while nextc != CDoom.newend
      nextc += 1
      # Remove a post
      start += 1
      start.value = nextc.value
    end

    CDoom.newend = start + 1
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
    start = CDoom.solidsegs.to_unsafe
    while start.value.last < first - 1
      start += 1
    end

    if first < start.value.first
      if last < start.value.first - 1
        # Post is entirely visible (above start).
        CDoom.r_store_wall_range(first, last)
        return
      end

      # There is a fragment above start.value.
      CDoom.r_store_wall_range(first, start.value.first - 1)
    end

    # Bottom contained in start?
    return if last <= start.value.last

    while last >= (start + 1).value.first - 1
      # There is a fragment between two posts.
      CDoom.r_store_wall_range(start.value.last + 1, (start + 1).value.first - 1)
      start += 1

      return if last <= start.value.last
    end

    # There is a fragment after next.value.
    CDoom.r_store_wall_range(start.value.last + 1, last)
  end

  def self.r_clear_clip_segs
    (CDoom.solidsegs.to_unsafe).value.first = -0x7fffffff
    (CDoom.solidsegs.to_unsafe).value.last = -1
    (CDoom.solidsegs.to_unsafe + 1).value.first = CDoom.viewwidth
    (CDoom.solidsegs.to_unsafe + 1).value.last = 0x7fffffff
    CDoom.newend = CDoom.solidsegs.to_unsafe + 2
  end

  #
  # Clips the given segment
  # and adds any visible pieces to the line list.
  #
  def self.r_addline(line : CDoom::Seg*)
    CDoom.curline = line

    # OPTIMIZE: quickly reject orthogonal back sides.
    angle1 = CDoom.r_point_to_angle(line.value.v1.value.x, line.value.v1.value.y)
    angle2 = CDoom.r_point_to_angle(line.value.v2.value.x, line.value.v2.value.y)

    # Clip to view edges.
    # OPTIMIZE: make constant out of 2*clipangle (FIELDOFVIEW).
    span = angle1 &- angle2

    # Back side? I.e. backface culling?
    return if span >= ANG180

    # Global angle needed by segcalc.
    CDoom.rw_angle1 = angle1
    angle1 &-= CDoom.viewangle
    angle2 &-= CDoom.viewangle

    tspan = angle1 &+ CDoom.clipangle
    if tspan > 2 &* CDoom.clipangle
      tspan &-= 2 &* CDoom.clipangle

      # Totally off the left edge?
      return if tspan >= span

      angle1 = CDoom.clipangle
    end
    tspan = CDoom.clipangle &- angle2
    if tspan > 2 &* CDoom.clipangle
      tspan &-= 2 &* CDoom.clipangle

      # Totally off the left edge?
      return if tspan >= span

      angle2 = -(CDoom.clipangle.to_i32!)
    end

    # The seg is in the view range,
    # but not necessarily visible.
    angle1 = (angle1 &+ ANG90) >> CDoom::ANGLETOFINESHIFT
    angle2 = (angle2 &+ ANG90) >> CDoom::ANGLETOFINESHIFT
    x1 = CDoom.viewangletox[angle1]
    x2 = CDoom.viewangletox[angle2]

    # Does not cross a pixel?
    return if (x1 == x2)

    CDoom.backsector = line.value.backsector

    # Single sided line?
    if CDoom.backsector.null?
      CDoom.r_clip_solid_wall_segment(x1, x2 - 1)
      return
    end

    # Closed door.
    if CDoom.backsector.value.ceilingheight <= CDoom.frontsector.value.floorheight ||
       CDoom.backsector.value.floorheight >= CDoom.frontsector.value.ceilingheight
      CDoom.r_clip_solid_wall_segment(x1, x2 - 1)
      return
    end

    # Window.
    if CDoom.backsector.value.ceilingheight != CDoom.frontsector.value.ceilingheight ||
       CDoom.backsector.value.floorheight != CDoom.frontsector.value.floorheight
      CDoom.r_clip_pass_wall_segment(x1, x2 - 1)
      return
    end

    # Reject empty lines used for triggers
    #  and special events.
    # Identical floor and ceiling on both sides,
    # identical light levels on both sides,
    # and no middle texture.
    if CDoom.backsector.value.ceilingpic == CDoom.frontsector.value.ceilingpic &&
       CDoom.backsector.value.floorpic == CDoom.frontsector.value.floorpic &&
       CDoom.backsector.value.lightlevel == CDoom.frontsector.value.lightlevel &&
       CDoom.curline.value.sidedef.value.midtexture == 0
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
  def self.r_check_bbox(bspcoord : CDoom::Fixed*) : CDoom::DoomBool
    # Find the corners of the box
    # that define the edges from current viewpoint.
    if CDoom.viewx <= bspcoord[CDoom::BOXLEFT]
      boxx = 0
    elsif CDoom.viewx < bspcoord[CDoom::BOXRIGHT]
      boxx = 1
    else
      boxx = 2
    end

    if CDoom.viewy >= bspcoord[CDoom::BOXTOP]
      boxy = 0
    elsif CDoom.viewy > bspcoord[CDoom::BOXBOTTOM]
      boxy = 1
    else
      boxy = 2
    end

    boxpos = (boxy << 2) + boxx
    return 1 if boxpos == 5

    x1 = bspcoord[CDoom.checkcoord[boxpos][0]]
    y1 = bspcoord[CDoom.checkcoord[boxpos][1]]
    x2 = bspcoord[CDoom.checkcoord[boxpos][2]]
    y2 = bspcoord[CDoom.checkcoord[boxpos][3]]

    # check clip list for an open space
    angle1 = CDoom.r_point_to_angle(x1, y1) &- CDoom.viewangle
    angle2 = CDoom.r_point_to_angle(x2, y2) &- CDoom.viewangle

    span = angle1 &- angle2

    # Sitting on a line?
    return 1 if span >= ANG180

    tspan = angle1 &+ CDoom.clipangle

    if tspan > 2 &* CDoom.clipangle
      tspan &-= 2 &* CDoom.clipangle

      # Totally off the left edge?
      return 0 if tspan >= span

      angle1 = CDoom.clipangle
    end
    tspan = CDoom.clipangle &- angle2
    if tspan > 2 &* CDoom.clipangle
      tspan &-= 2 &* CDoom.clipangle

      # Totally off the left edge?
      return 0 if tspan >= span

      angle2 = -(CDoom.clipangle.to_i32!)
    end

    # Find the first clippost
    #  that touches the source post
    #  (adjacent pixels are touching).
    angle1 = (angle1 &+ ANG90) >> CDoom::ANGLETOFINESHIFT
    angle2 = (angle2 &+ ANG90) >> CDoom::ANGLETOFINESHIFT
    sx1 = CDoom.viewangletox[angle1]
    sx2 = CDoom.viewangletox[angle2]

    # Does not cross a pixel.
    return 0 if sx1 == sx2
    sx2 -= 1

    start = CDoom.solidsegs.to_unsafe
    while start.value.last < sx2
      start += 1
    end

    if sx1 >= start.value.first &&
       sx2 <= start.value.last
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
      if num >= CDoom.numsubsectors
        CDoom.i_error("Error: r_subsector: ss #{num} with numss = #{CDoom.numsubsectors}")
      end
    {% end %}

    CDoom.sscount += 1
    sub = CDoom.subsectors + num
    CDoom.frontsector = sub.value.sector
    count = sub.value.numlines
    line = CDoom.segs + sub.value.firstline

    if CDoom.frontsector.value.floorheight < CDoom.viewz
      @@floorplane = r_find_plane(CDoom.frontsector.value.floorheight,
        CDoom.frontsector.value.floorpic,
        CDoom.frontsector.value.lightlevel)
    else
      @@floorplane = -1
    end

    if CDoom.frontsector.value.ceilingheight > CDoom.viewz ||
       CDoom.frontsector.value.ceilingpic == CDoom.skyflatnum
      @@ceilingplane = r_find_plane(CDoom.frontsector.value.ceilingheight,
        CDoom.frontsector.value.ceilingpic,
        CDoom.frontsector.value.lightlevel)
    else
      @@ceilingplane = -1
    end

    CDoom.r_add_sprites(CDoom.frontsector)

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
    if bspnum & CDoom::NF_SUBSECTOR != 0
      if bspnum == -1
        CDoom.r_subsector(0)
      else
        CDoom.r_subsector(bspnum & (~CDoom::NF_SUBSECTOR))
      end
      return
    end

    bsp = CDoom.nodes + bspnum

    # Decide which side the view point is on.
    side = CDoom.r_point_on_side(CDoom.viewx, CDoom.viewy, bsp)

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
  def self.r_draw_column_in_cache(patch : CDoom::Column*, cache : CDoom::Byte*, originy : LibC::Int, cacheheight : LibC::Int)
    dest = cache + 3

    while patch.value.topdelta != 0xff
      source = patch.as(CDoom::Byte*) + 3
      count = patch.value.length
      position = originy + patch.value.topdelta

      if position < 0
        count += position
        position = 0
      end

      count = cacheheight - position if position + count > cacheheight

      CDoom.doom_memcpy(cache + position, source, count) if count > 0

      patch = (patch.as(CDoom::Byte*) + patch.value.length + 4).as(CDoom::Column*)
    end
  end

  # Using the texture definition,
  #  the composite texture is created from the patches,
  #  and each column is cached.
  def self.r_generate_composite(texnum : LibC::Int)
    texture = CDoom.textures[texnum]

    block = CDoom.z_malloc(CDoom.texturecompositesize[texnum],
      CDoom::PU_STATIC,
      CDoom.texturecomposite + texnum).as(CDoom::Byte*)

    collump = CDoom.texturecolumnlump[texnum]
    colofs = CDoom.texturecolumnofs[texnum]

    # Composite the columns together.
    patch = texture.value.patches.to_unsafe

    texture.value.patchcount.times do |i|
      realpatch = CDoom.w_cache_lump_num(patch.value.patch, CDoom::PU_CACHE).as(CDoom::Patch*)
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

        patchcol = (realpatch.as(CDoom::Byte*) + (realpatch.value.columnofs.to_unsafe + (x - x1)).value).as(CDoom::Column*)

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
    z_change_tag(block, CDoom::PU_CACHE)
  end

  def self.r_generate_lookup(texnum : LibC::Int)
    texture = CDoom.textures[texnum]

    # Composited texture not created yet
    CDoom.texturecomposite[texnum] = Pointer(CDoom::Byte).null

    CDoom.texturecompositesize[texnum] = 0
    collump = CDoom.texturecolumnlump[texnum]
    colofs = CDoom.texturecolumnofs[texnum]

    # Now count the number of columns
    #  that are covered by more than one patch.
    # Fill in the lump / offset, so columns
    #  with only a single patch are all done.
    patchcount = GC.malloc(texture.value.width.to_i32).as(CDoom::Byte*)
    CDoom.doom_memset(patchcount, 0, texture.value.width)
    patch = texture.value.patches.to_unsafe

    texture.value.patchcount.times do |i|
      realpatch = CDoom.w_cache_lump_num(patch.value.patch, CDoom::PU_CACHE).as(CDoom::Patch*)
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
        colofs[x] = CDoom.texturecompositesize[texnum].to_u16!

        if CDoom.texturecompositesize[texnum] > 0x10000 - texture.value.height
          CDoom.i_error("Error: r_generate_lookup: texture #{texnum} is >64k")
        end

        CDoom.texturecompositesize[texnum] = CDoom.texturecompositesize[texnum] + texture.value.height
      end
    end

    GC.free(patchcount.as(Void*))
  end

  def self.r_get_column(tex : LibC::Int, col : LibC::Int) : CDoom::Byte*
    col &= CDoom.texturewidthmask[tex]
    lump = CDoom.texturecolumnlump[tex][col]
    ofs = CDoom.texturecolumnofs[tex][col]

    return CDoom.w_cache_lump_num(lump, CDoom::PU_CACHE).as(CDoom::Byte*) + ofs if lump > 0

    CDoom.r_generate_composite(tex) if CDoom.texturecomposite[tex].null?

    return CDoom.texturecomposite[tex] + ofs
  end

  #
  # Initializes the texture list
  #  with the textures from the world map.
  #
  def self.r_init_textures
    name = Pointer(UInt8).malloc(9)

    # Load the patch names from pnames.lmp.
    name[8] = 0
    names = CDoom.w_cache_lump_name("PNAMES", CDoom::PU_STATIC).as(UInt8*)
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
    maptex = CDoom.w_cache_lump_name("TEXTURE1", CDoom::PU_STATIC).as(Int32*)
    maptex1 = maptex
    numtextures1 = maptex.value
    maxoff = CDoom.w_lump_length(CDoom.w_get_num_for_name("TEXTURE1"))
    directory = maptex + 1

    if CDoom.w_check_num_for_name("TEXTURE2") != -1
      maptex2 = CDoom.w_cache_lump_name("TEXTURE2", CDoom::PU_STATIC).as(Int32*)
      numtextures2 = maptex2.value
      maxoff2 = CDoom.w_lump_length(CDoom.w_get_num_for_name("TEXTURE2"))
    else
      maptex2 = Pointer(Int32).null
      numtextures2 = 0
      maxoff2 = 0
    end
    CDoom.numtextures = numtextures1 + numtextures2

    CDoom.textures = CDoom.z_malloc(CDoom.numtextures * sizeof(CDoom::Texture*), CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Texture**)
    CDoom.texturecolumnlump = CDoom.z_malloc(CDoom.numtextures * sizeof(Int16*), CDoom::PU_STATIC, Pointer(Void).null).as(Int16**)
    CDoom.texturecolumnofs = CDoom.z_malloc(CDoom.numtextures * sizeof(UInt16*), CDoom::PU_STATIC, Pointer(Void).null).as(UInt16**)
    CDoom.texturecomposite = CDoom.z_malloc(CDoom.numtextures * sizeof(CDoom::Byte*), CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Byte**)
    CDoom.texturecompositesize = CDoom.z_malloc(CDoom.numtextures * sizeof(Int32), CDoom::PU_STATIC, Pointer(Void).null).as(Int32*)
    CDoom.texturewidthmask = CDoom.z_malloc(CDoom.numtextures * sizeof(Int32), CDoom::PU_STATIC, Pointer(Void).null).as(Int32*)
    CDoom.textureheight = CDoom.z_malloc(CDoom.numtextures * sizeof(CDoom::Fixed), CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Fixed*)

    totalwidth = 0

    CDoom.numtextures.times do |i|
      print "." if i & 63 == 0

      if i == numtextures1
        # Start looking in second texture file.
        maptex = maptex2
        maxoff = maxoff2
        directory = maptex + 1
      end

      offset = directory.value

      CDoom.i_error("Error: r_init_textures: bad texture directory") if offset > maxoff

      mtexture = (maptex.as(CDoom::Byte*) + offset).as(CDoom::Maptexture*)

      texture = CDoom.z_malloc(sizeof(CDoom::Texture) +
                               sizeof(CDoom::Texpatch) * (mtexture.value.patchcount - 1),
        CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Texture*)
      CDoom.textures[i] = texture

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
      CDoom.texturecolumnlump[i] = CDoom.z_malloc(texture.value.width * sizeof(Int16), CDoom::PU_STATIC, Pointer(Void).null).as(Int16*)
      CDoom.texturecolumnofs[i] = CDoom.z_malloc(texture.value.width * sizeof(UInt16), CDoom::PU_STATIC, Pointer(Void).null).as(UInt16*)

      j = 1
      while j * 2 <= texture.value.width
        j <<= 1
      end

      CDoom.texturewidthmask[i] = j - 1
      CDoom.textureheight[i] = texture.value.height.to_i32 << FRACBITS

      totalwidth += texture.value.width
      directory += 1
    end

    CDoom.z_free(maptex1)
    CDoom.z_free(maptex2) unless maptex2.null?

    # Precalculate whatever possible.
    CDoom.numtextures.times { |i| CDoom.r_generate_lookup(i) }

    # Create translation table for global animation.
    CDoom.texturetranslation = CDoom.z_malloc((CDoom.numtextures + 1) * sizeof(Int32), CDoom::PU_STATIC, Pointer(Void).null).as(Int32*)

    CDoom.numtextures.times { |i| CDoom.texturetranslation[i] = i }

    GC.free(patchlookup.as(Void*))
  end

  def self.r_init_flats
    # Create translation table for global animation.
    CDoom.flattranslation = CDoom.z_malloc((CDoom.numflats + 1) * sizeof(Int32), CDoom::PU_STATIC, Pointer(Void).null).as(Int32*)

    CDoom.numflats.times do |i|
      print "." if i & 63 == 0
      CDoom.flattranslation[i] = i
    end
  end

  #
  # Finds the width and hoffset of all sprites in the wad,
  #  so the sprite does not need to be cached completely
  #  just for having the header info ready during rendering.
  #
  def self.r_init_sprite_lumps
    CDoom.spritewidth = CDoom.z_malloc(CDoom.numspritelumps * sizeof(CDoom::Fixed), CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Fixed*)
    CDoom.spriteoffset = CDoom.z_malloc(CDoom.numspritelumps * sizeof(CDoom::Fixed), CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Fixed*)
    CDoom.spritetopoffset = CDoom.z_malloc(CDoom.numspritelumps * sizeof(CDoom::Fixed), CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Fixed*)

    CDoom.numspritelumps.times do |i|
      print "." if i & 63 == 0

      patch = CDoom.w_cache_lump_num(CDoom.firstspritelump + i, CDoom::PU_CACHE).as(CDoom::Patch*)
      CDoom.spritewidth[i] = patch.value.width.to_i32 << FRACBITS
      CDoom.spriteoffset[i] = patch.value.leftoffset.to_i32 << FRACBITS
      CDoom.spritetopoffset[i] = patch.value.topoffset.to_i32 << FRACBITS
    end
  end

  def self.r_init_colormaps
    # Load in the light tables,
    #  256 byte align tables.
    lump = CDoom.w_get_num_for_name("COLORMAP")
    length = CDoom.w_lump_length(lump) + 255
    CDoom.colormaps = CDoom.z_malloc(length, CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Lighttable*)
    CDoom.colormaps = Pointer(CDoom::Lighttable).new(((CDoom.colormaps.address + 255) & ~0xff))
    CDoom.w_read_lump(lump, CDoom.colormaps)
  end

  def self.r_order_lump_section(starts : Array(String), ends : Array(String))
    # Musical lumps!

    # Find all lump sections
    sections = [] of Tuple(Int32, Int32)
    start = -1
    @@lumpinfo.each_with_index do |lump, i|
      starts.each do |s|
        if doom_strncmp(lump.name.to_unsafe, s.to_unsafe, 8) == 0
          start = i
          break
        end
      end

      if start != 1
        ends.each do |e|
          if doom_strncmp(lump.name.to_unsafe, e.to_unsafe, 8) == 0
            sections << {start, i}
            start = -1
          end
        end
      end
    end

    lumps = [] of Array(CDoom::Lumpinfo)
    # Reverse so deleting doesn't mess with alignment
    sections.reverse.each do |section|
      lumps << @@lumpinfo[(section[0] + 1)...section[1]] # Respect s_start/end lumps
      @@lumpinfo.delete_at(section[0]..section[1])
    end

    # Now all are in order, add back onto end with start and end lumps
    @@lumpinfo << CDoom::Lumpinfo.new
    doom_strcpy((@@lumpinfo.to_unsafe + @@lumpinfo.size - 1).value.name.to_unsafe, starts[0].to_unsafe)
    lumps.reverse.each { |section| @@lumpinfo.concat(section) }
    @@lumpinfo << CDoom::Lumpinfo.new
    doom_strcpy((@@lumpinfo.to_unsafe + @@lumpinfo.size - 1).value.name.to_unsafe, ends[0].to_unsafe)
  end

  #
  # Locates all the lumps
  #  that will be used by all views
  # Must be called after W_Init.
  #
  def self.r_init_data
    r_order_lump_section(["S_START", "SS_START"], ["S_END", "SS_END"])
    r_order_lump_section(["F_START", "FF_START"], ["F_END", "FF_END"])

    CDoom.numlumps = @@lumpinfo.size
    CDoom.lumpcache.clear(CDoom.numlumps)

    CDoom.firstspritelump = CDoom.w_get_num_for_name("S_START") + 1
    CDoom.lastspritelump = CDoom.w_get_num_for_name("S_END") - 1
    CDoom.numspritelumps = CDoom.lastspritelump - CDoom.firstspritelump + 1

    CDoom.firstflat = CDoom.w_get_num_for_name("F_START") + 1
    CDoom.lastflat = CDoom.w_get_num_for_name("F_END") - 1
    CDoom.numflats = CDoom.lastflat - CDoom.firstflat + 1

    nums = (CDoom.numtextures + 63) // 64 +
           (CDoom.numflats + 63) // 64 +
           (CDoom.numspritelumps + 63) // 64

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
    return i - CDoom.firstflat
  end

  #
  # Check whether texture is available.
  # Filter out NoTexture indicator.
  #
  def self.r_check_texture_num_for_name(name : LibC::Char*) : LibC::Int
    # "NoTexture" marker.
    return 0 if name[0] == '-'.ord

    CDoom.numtextures.times { |i| return i if CDoom.doom_strncasecmp(CDoom.textures[i].value.name, name, 8) == 0 }

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
    return if CDoom.demoplayback != 0

    # Precache flats.
    flatpresent = GC.malloc(CDoom.numflats).as(UInt8*)
    CDoom.doom_memset(flatpresent, 0, CDoom.numflats)

    CDoom.numsectors.times do |i|
      flatpresent[CDoom.sectors[i].floorpic] = 1
      flatpresent[CDoom.sectors[i].ceilingpic] = 1
    end

    CDoom.flatmemory = 0

    CDoom.numflats.times do |i|
      if flatpresent[i] != 0
        lump = CDoom.firstflat + i
        CDoom.flatmemory += @@lumpinfo[lump].size
        CDoom.w_cache_lump_num(lump, CDoom::PU_CACHE)
      end
    end

    # Precache textures.
    texturepresent = GC.malloc(CDoom.numtextures).as(UInt8*)
    CDoom.doom_memset(texturepresent, 0, CDoom.numtextures)

    CDoom.numsides.times do |i|
      texturepresent[CDoom.sides[i].toptexture] = 1
      texturepresent[CDoom.sides[i].midtexture] = 1
      texturepresent[CDoom.sides[i].bottomtexture] = 1
    end

    # Sky texture is always present.
    # Note that F_SKY1 is the name used to
    #  indicate a sky floor/ceiling as a flat,
    #  while the sky texture is stored like
    #  a wall texture, with an episode dependend
    #  name.
    texturepresent[CDoom.skytexture] = 1

    CDoom.texturememory = 0
    CDoom.numtextures.times do |i|
      next if texturepresent[i] == 0

      texture = CDoom.textures[i]

      texture.value.patchcount.times do |j|
        lump = (texture.value.patches.to_unsafe + j).value.patch
        CDoom.texturememory += @@lumpinfo[lump].size
        CDoom.w_cache_lump_num(lump, CDoom::PU_CACHE)
      end
    end

    # Precache sprites.
    spritepresent = GC.malloc(CDoom.numsprites).as(UInt8*)
    CDoom.doom_memset(spritepresent, 0, CDoom.numsprites)

    th = CDoom.thinkercap.next
    while th != pointerof(CDoom.thinkercap)
      if th.value.function.acp1.pointer == (->CDoom.p_mobj_thinker).pointer
        spritepresent[th.as(CDoom::Mobj*).value.sprite.value] = 1
      end

      th = th.value.next
    end

    CDoom.spritememory = 0
    CDoom.numsprites.times do |i|
      next if spritepresent[i] == 0

      CDoom.sprites[i].numframes.times do |j|
        sf = (CDoom.sprites + i).value.spriteframes + j
        8.times do |k|
          lump = CDoom.firstspritelump + sf.value.lump[k]
          CDoom.spritememory += @@lumpinfo[lump].size
          CDoom.w_cache_lump_num(lump, CDoom::PU_CACHE)
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
    count = CDoom.dc_yh - CDoom.dc_yl

    # Zero length, column does not exceed a pixel.
    return if count < 0

    {% if flag?("RANGECHECK") %}
      if CDoom.dc_x.to_u32! >= CDoom::SCREENWIDTH ||
         CDoom.dc_yl < 0 || CDoom.dc_yh >= CDoom::SCREENHEIGHT
        CDoom.i_error("Error: r_draw_column: #{CDoom.dc_yl} to #{CDoom.dc_yh} at #{CDoom.dc_x}")
      end
    {% end %}

    # Framebuffer destination address.
    # Use ylookup LUT to avoid multiply with ScreenWidth.
    # Use columnofs LUT for subwindows?
    dest = CDoom.ylookup[CDoom.dc_yl] + CDoom.columnofs[CDoom.dc_x]

    # Determine scaling,
    #  which is the only mapping to be done.
    fracstep = CDoom.dc_iscale
    frac = CDoom.dc_texturemid + (CDoom.dc_yl - CDoom.centery) * fracstep

    # Inner loop that does the actual texture mapping,
    #  e.g. a DDA-lile scaling.
    # This is as fast as it gets.
    loop do
      # Re-map color indices from wall texture column
      #  using a lighting/special effects LUT.
      dest.value = CDoom.dc_colormap[CDoom.dc_source[(frac >> FRACBITS) & 127]]

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
    CDoom.dc_yl = 1 if CDoom.dc_yl == 0

    # .. and high.
    CDoom.dc_yh = CDoom.viewheight - 2 if CDoom.dc_yh == CDoom.viewheight - 1

    count = CDoom.dc_yh - CDoom.dc_yl

    # Zero length.
    return if count < 0

    {% if flag?("RANGECHECK") %}
      if CDoom.dc_x.to_u32! >= CDoom::SCREENWIDTH ||
         CDoom.dc_yl < 0 || CDoom.dc_yh >= CDoom::SCREENHEIGHT
        CDoom.i_error("Error: r_draw_fuzz_column: #{CDoom.dc_yl} to #{CDoom.dc_yh} at #{CDoom.dc_x}")
      end
    {% end %}

    # Does not work with blocky mode.
    dest = CDoom.ylookup[CDoom.dc_yl] + CDoom.columnofs[CDoom.dc_x]

    # Looks familiar.
    fracstep = CDoom.dc_iscale
    frac = CDoom.dc_texturemid + (CDoom.dc_yl - CDoom.centery) * fracstep

    # Looks like an attempt at dithering,
    #  using the colormap #6 (of 0-31, a bit
    #  brighter than average).
    loop do
      # Lookup framebuffer, and retrieve
      #  a pixel that is either one column
      #  left or right of the current one.
      # Add index from colormap to index.
      dest.value = CDoom.colormaps[6 * 256 + dest[CDoom.fuzzoffset[CDoom.fuzzpos]]]

      # Clamp table lookup index.
      CDoom.fuzzpos += 1
      CDoom.fuzzpos = 0 if CDoom.fuzzpos == CDoom::FUZZTABLE

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
    count = CDoom.dc_yh - CDoom.dc_yl
    return if count < 0
    {% if flag?("RANGECHECK") %}
      if CDoom.dc_x.to_u32! >= CDoom::SCREENWIDTH ||
         CDoom.dc_yl < 0 || CDoom.dc_yh >= CDoom::SCREENHEIGHT
        CDoom.i_error("Error: r_draw_column: #{CDoom.dc_yl} to #{CDoom.dc_yh} at #{CDoom.dc_x}")
      end
    {% end %}

    # FIXME. As above.
    dest = CDoom.ylookup[CDoom.dc_yl] + CDoom.columnofs[CDoom.dc_x]

    # Looks familiar.
    fracstep = CDoom.dc_iscale
    frac = CDoom.dc_texturemid + (CDoom.dc_yl - CDoom.centery) * fracstep

    # Here we do an additional index re-mapping.
    loop do
      # Translation tables are used
      #  to map certain colorramps to other ones,
      #  used with PLAY sprites.
      # Thus the "green" ramp of the player 0 sprite
      #  is mapped to gray, red, black/indigo.
      dest.value = CDoom.dc_colormap[CDoom.dc_translation[CDoom.dc_source[frac >> FRACBITS]]]
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
    CDoom.translationtables = CDoom.z_malloc(256 * 3 + 255, CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Byte*)
    CDoom.translationtables = Pointer(CDoom::Byte).new((CDoom.translationtables.address + 255) & ~255)

    # translate just the 16 green colors
    256.times do |i|
      if i >= 0x70 && i <= 0x7f
        # map green ramp to gray, brown, red
        CDoom.translationtables[i] = 0x60_u8 + (i & 0xf)
        CDoom.translationtables[i + 256] = 0x40_u8 + (i & 0xf)
        CDoom.translationtables[i + 512] = 0x20_u8 + (i & 0xf)
      else
        # Keep all other colors as is.
        CDoom.translationtables[i] = i.to_u8!
        CDoom.translationtables[i + 256] = i.to_u8!
        CDoom.translationtables[i + 512] = i.to_u8!
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
      if CDoom.ds_x2 < CDoom.ds_x1 ||
         CDoom.ds_x1 < 0 ||
         CDoom.ds_x2 >= CDoom::SCREENWIDTH ||
         CDoom.ds_y.to_u32! > CDoom::SCREENHEIGHT
        CDoom.i_error("Error: r_draw_span: #{CDoom.ds_x1} to #{CDoom.ds_x2} at #{CDoom.ds_y}")
      end
    {% end %}

    xfrac = CDoom.ds_xfrac
    yfrac = CDoom.ds_yfrac

    dest = CDoom.ylookup[CDoom.ds_y] + CDoom.columnofs[CDoom.ds_x1]

    # We do not check for zero spans here?
    count = CDoom.ds_x2 - CDoom.ds_x1

    loop do
      # Current texture index in u,v
      spot = ((yfrac >> (16 - 6)) & (63 * 64)) + ((xfrac >> 16) & 63)

      # Lookup pixel from flat texture tile,
      #  re-index using light/colormap.
      dest.value = CDoom.ds_colormap[CDoom.ds_source[spot]]
      dest += 1

      # Next step in u,v.
      xfrac += CDoom.ds_xstep
      yfrac += CDoom.ds_ystep

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
    CDoom.viewwindowx = (CDoom::SCREENWIDTH - width) >> 1

    # Column offset. For windows.
    width.times { |i| CDoom.columnofs[i] = CDoom.viewwindowx + i }

    # Samw with base row offset.
    if width == CDoom::SCREENWIDTH
      CDoom.viewwindowy = 0
    else
      CDoom.viewwindowy = (CDoom::SCREENHEIGHT - CDoom::SBARHEIGHT - height) >> 1
    end
    # Preclaculate all row offsets.
    screen = @@software_rendering ? CDoom.screens[0] : @@software_screen.to_unsafe
    height.times { |i| CDoom.ylookup[i] = screen + (i + CDoom.viewwindowy) * CDoom::SCREENWIDTH }
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

    return if CDoom.scaledviewwidth == 320

    if CDoom.gamemode == CDoom::GameMode::Commercial
      name = name2.to_unsafe
    else
      name = name1.to_unsafe
    end

    src = CDoom.w_cache_lump_name(name, CDoom::PU_CACHE).as(CDoom::Byte*)
    dest = CDoom.screens[1]

    (CDoom::SCREENHEIGHT - CDoom::SBARHEIGHT).times do |y|
      (CDoom::SCREENWIDTH // 64).times do |x|
        CDoom.doom_memcpy(dest, src + ((y & 63) << 6), 64)
        dest += 64
      end

      if CDoom::SCREENWIDTH & 63 != 0
        CDoom.doom_memcpy(dest, src + ((y & 63) << 6), CDoom::SCREENWIDTH & 63)
        dest += CDoom::SCREENWIDTH & 63
      end
    end

    patch = CDoom.w_cache_lump_name("brdr_t", CDoom::PU_CACHE).as(CDoom::Patch*)

    x = 0
    while x < CDoom.scaledviewwidth
      CDoom.v_draw_patch(CDoom.viewwindowx + x, CDoom.viewwindowy - 8, 1, patch)
      x += 8
    end
    patch = CDoom.w_cache_lump_name("brdr_b", CDoom::PU_CACHE).as(CDoom::Patch*)

    x = 0
    while x < CDoom.scaledviewwidth
      CDoom.v_draw_patch(CDoom.viewwindowx + x, CDoom.viewwindowy + CDoom.viewheight, 1, patch)
      x += 8
    end
    patch = CDoom.w_cache_lump_name("brdr_l", CDoom::PU_CACHE).as(CDoom::Patch*)

    y = 0
    while y < CDoom.viewheight
      CDoom.v_draw_patch(CDoom.viewwindowx - 8, CDoom.viewwindowy + y, 1, patch)
      y += 8
    end
    patch = CDoom.w_cache_lump_name("brdr_r", CDoom::PU_CACHE).as(CDoom::Patch*)

    y = 0
    while y < CDoom.viewheight
      CDoom.v_draw_patch(CDoom.viewwindowx + CDoom.scaledviewwidth, CDoom.viewwindowy + y, 1, patch)
      y += 8
    end

    # Draw beveled edge.
    CDoom.v_draw_patch(CDoom.viewwindowx - 8,
      CDoom.viewwindowy - 8,
      1,
      CDoom.w_cache_lump_name("brdr_tl", CDoom::PU_CACHE).as(CDoom::Patch*))

    CDoom.v_draw_patch(CDoom.viewwindowx + CDoom.scaledviewwidth,
      CDoom.viewwindowy - 8,
      1,
      CDoom.w_cache_lump_name("brdr_tr", CDoom::PU_CACHE).as(CDoom::Patch*))

    CDoom.v_draw_patch(CDoom.viewwindowx - 8,
      CDoom.viewwindowy + CDoom.viewheight,
      1,
      CDoom.w_cache_lump_name("brdr_bl", CDoom::PU_CACHE).as(CDoom::Patch*))

    CDoom.v_draw_patch(CDoom.viewwindowx + CDoom.scaledviewwidth,
      CDoom.viewwindowy + CDoom.viewheight,
      1,
      CDoom.w_cache_lump_name("brdr_br", CDoom::PU_CACHE).as(CDoom::Patch*))
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
    CDoom.doom_memcpy(CDoom.screens[0] + ofs, CDoom.screens[1] + ofs, count)
  end

  #
  # Draws the border around the view
  #  for different size windows?
  #
  def self.r_draw_view_border
    return if CDoom.scaledviewwidth == CDoom::SCREENWIDTH

    top = ((CDoom::SCREENHEIGHT - CDoom::SBARHEIGHT) - CDoom.viewheight) // 2
    side = (CDoom::SCREENWIDTH - CDoom.scaledviewwidth) // 2

    # copy top and one line of left side
    CDoom.r_video_erase(0, top * CDoom::SCREENWIDTH + side)

    # copy one line of right side and bottom
    ofs = (CDoom.viewheight + top) * CDoom::SCREENWIDTH - side
    CDoom.r_video_erase(ofs, top * CDoom::SCREENWIDTH + side)

    # copy sides using wraparound
    ofs = top * CDoom::SCREENWIDTH + CDoom::SCREENWIDTH - side
    side <<= 1

    i = 1
    while i < CDoom.viewheight
      CDoom.r_video_erase(ofs, side)
      ofs += CDoom::SCREENWIDTH

      i += 1
    end

    # ?
    CDoom.v_mark_rect(0, 0, CDoom::SCREENWIDTH, CDoom::SCREENHEIGHT - CDoom::SBARHEIGHT)
  end

  #
  # Expand a given bbox
  # so that it encloses a given point.
  #
  def self.r_add_point_to_box(x : LibC::Int, y : LibC::Int, box : CDoom::Fixed*)
    box[CDoom::BOXLEFT] = x if x < box[CDoom::BOXLEFT]
    box[CDoom::BOXRIGHT] = x if x > box[CDoom::BOXRIGHT]
    box[CDoom::BOXBOTTOM] = y if y < box[CDoom::BOXBOTTOM]
    box[CDoom::BOXTOP] = y if y > box[CDoom::BOXTOP]
  end

  #
  # Traverse BSP (sub) tree,
  #  check point against partition plane.
  # Returns side 0 (front) or 1 (back).
  #
  def self.r_point_on_side(x : CDoom::Fixed, y : CDoom::Fixed, node : CDoom::Node*) : LibC::Int
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

  def self.r_point_on_seg_side(x : CDoom::Fixed, y : CDoom::Fixed, line : CDoom::Seg*) : LibC::Int
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
  def self.r_point_to_angle(x : CDoom::Fixed, y : CDoom::Fixed) : CDoom::Angle
    x -= CDoom.viewx
    y -= CDoom.viewy

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

  def self.r_point_to_angle2(x1 : CDoom::Fixed, y1 : CDoom::Fixed, x2 : CDoom::Fixed, y2 : CDoom::Fixed) : CDoom::Angle
    CDoom.viewx = x1
    CDoom.viewy = y1

    return CDoom.r_point_to_angle(x2, y2)
  end

  def self.r_point_to_dist(x : CDoom::Fixed, y : CDoom::Fixed) : CDoom::Fixed
    dx = doom_abs(x - CDoom.viewx)
    dy = doom_abs(y - CDoom.viewy)

    if dy > dx
      temp = dx
      dx = dy
      dy = temp
    end

    angle = (@@tantoangle[CDoom.fixed_div(dy, dx) >> DBITS] &+ ANG90) >> CDoom::ANGLETOFINESHIFT

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
  def self.r_scale_from_global_angle(visangle : CDoom::Angle) : CDoom::Fixed
    anglea = ANG90 &+ (visangle &- CDoom.viewangle)
    angleb = ANG90 &+ (visangle &- CDoom.rw_normalangle)

    # both sines are allways positive
    sinea = @@finesine[anglea >> CDoom::ANGLETOFINESHIFT]
    sineb = @@finesine[angleb >> CDoom::ANGLETOFINESHIFT]
    num = CDoom.fixed_mul(CDoom.projection, sineb)
    den = CDoom.fixed_mul(CDoom.rw_distance, sinea)

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
    focallength = CDoom.fixed_div(CDoom.centerxfrac,
      @@finetangent[CDoom::FINEANGLES // 4 + CDoom::FIELDOFVIEW // 2])

    (CDoom::FINEANGLES // 2).times do |i|
      if @@finetangent[i] > FRACUNIT * 2
        t = -1
      elsif @@finetangent[i] < -FRACUNIT * 2
        t = CDoom.viewwidth + 1
      else
        t = CDoom.fixed_mul(@@finetangent[i], focallength)
        t = (CDoom.centerxfrac - t + FRACUNIT - 1) >> FRACBITS

        if t < -1
          t = -1
        elsif t > CDoom.viewwidth + 1
          t = CDoom.viewwidth + 1
        end
      end
      CDoom.viewangletox[i] = t
    end

    # Scan viewangletox[] to generate xtoviewangle[]:
    # xtoviewangle will give the smallest view angle
    # that maps to x.
    x = 0
    while x <= CDoom.viewwidth
      i = 0
      while CDoom.viewangletox[i] > x
        i += 1
      end
      CDoom.xtoviewangle[x] = (i.to_u32! << CDoom::ANGLETOFINESHIFT) &- ANG90

      x += 1
    end

    # Take out the fencepost cases from viewangletox.
    (CDoom::FINEANGLES // 2).times do |i|
      t = CDoom.fixed_mul(@@finetangent[i], focallength)
      t = CDoom.centerx - t

      if CDoom.viewangletox[i] == -1
        CDoom.viewangletox[i] = 0
      elsif CDoom.viewangletox[i] == CDoom.viewwidth + 1
        CDoom.viewangletox[i] = CDoom.viewwidth
      end
    end

    CDoom.clipangle = CDoom.xtoviewangle[0]
  end

  #
  # Only inits the zlight table,
  # because the scalelight table changes with view size.
  #
  def self.r_init_light_tables
    # Calculate the light levels to use
    #  for each level / distance combination.
    CDoom::LIGHTLEVELS.times do |i|
      startmap = ((CDoom::LIGHTLEVELS - 1 - i) * 2) * CDoom::NUMCOLORMAPS // CDoom::LIGHTLEVELS
      CDoom::MAXLIGHTZ.times do |j|
        scale = CDoom.fixed_div((CDoom::SCREENWIDTH // 2 * FRACUNIT), (j + 1) << CDoom::LIGHTZSHIFT)
        scale >>= CDoom::LIGHTSCALESHIFT
        level = startmap - scale // CDoom::DISTMAP

        level = 0 if level < 0

        level = CDoom::NUMCOLORMAPS - 1 if level >= CDoom::NUMCOLORMAPS

        ((CDoom.zlight.to_unsafe + i).value.to_unsafe + j).value = CDoom.colormaps + level * 256
      end
    end
  end

  #
  # Do not really change anything here,
  #  because it might be in the middle of a refresh.
  # The change will take effect next refresh.
  #
  def self.r_set_view_size(blocks : LibC::Int, detail : LibC::Int)
    CDoom.setsizeneeded = 1
    CDoom.setblocks = blocks
    CDoom.setdetail = detail
  end

  def self.r_execute_set_view_size
    CDoom.setsizeneeded = 0

    if CDoom.setblocks == 11
      CDoom.scaledviewwidth = CDoom::SCREENWIDTH
      CDoom.viewheight = CDoom::SCREENHEIGHT
    else
      CDoom.scaledviewwidth = CDoom.setblocks * 32
      CDoom.viewheight = (CDoom.setblocks * 168 // 10) & ~7
    end

    CDoom.detailshift = CDoom.setdetail
    CDoom.viewwidth = CDoom.scaledviewwidth

    CDoom.centery = CDoom.viewheight // 2
    CDoom.centerx = CDoom.viewwidth // 2
    CDoom.centerxfrac = CDoom.centerx << FRACBITS
    CDoom.centeryfrac = CDoom.centery << FRACBITS
    CDoom.projection = CDoom.centerxfrac

    CDoom.colfunc = ->CDoom.r_draw_column

    CDoom.r_init_buffer(CDoom.scaledviewwidth, CDoom.viewheight)

    CDoom.r_init_texture_mapping

    # psprite scales
    CDoom.pspritescale = FRACUNIT * CDoom.viewwidth // CDoom::SCREENWIDTH
    CDoom.pspriteiscale = FRACUNIT * CDoom::SCREENWIDTH // CDoom.viewwidth

    # thing clipping
    CDoom.viewwidth.times { |i| CDoom.screenheightarray[i] = CDoom.viewheight.to_i16! }

    # planes
    CDoom.viewheight.times do |i|
      dy = ((i - CDoom.viewheight // 2) << FRACBITS) + FRACUNIT // 2
      dy = doom_abs(dy)
      CDoom.yslope[i] = CDoom.fixed_div(CDoom.viewwidth // 2 * FRACUNIT, dy)
    end

    CDoom.viewwidth.times do |i|
      cosadj = doom_abs(@@finecosine[CDoom.xtoviewangle[i] >> CDoom::ANGLETOFINESHIFT])
      CDoom.distscale[i] = CDoom.fixed_div(FRACUNIT, cosadj)
    end

    # Calculate the light levels to use
    #  for each level / scale combination.
    CDoom::LIGHTLEVELS.times do |i|
      startmap = ((CDoom::LIGHTLEVELS - 1 - i) * 2) * CDoom::NUMCOLORMAPS // CDoom::LIGHTLEVELS
      CDoom::MAXLIGHTSCALE.times do |j|
        level = startmap - j * CDoom::SCREENWIDTH // CDoom.viewwidth // CDoom::DISTMAP

        level = 0 if level < 0

        level = CDoom::NUMCOLORMAPS - 1 if level >= CDoom::NUMCOLORMAPS

        ((CDoom.scalelight.to_unsafe + i).value.to_unsafe + j).value = CDoom.colormaps + level * 256
      end
    end
  end

  def self.r_init
    # print "\nr_init_data"
    CDoom.r_init_data

    # viewwidth / viewheight / detailLevel are set by the defaults
    print "        Tables"
    CDoom.r_init_tables

    CDoom.r_set_view_size(CDoom.screenblocks, CDoom.detail_level)

    CDoom.r_init_light_tables
    CDoom.r_init_sky_map
    CDoom.r_init_translation_tables

    CDoom.framecount = 0
  end

  def self.r_point_in_subsector(x : CDoom::Fixed, y : CDoom::Fixed) : CDoom::Subsector*
    # single subsector is a special case
    return CDoom.subsectors if CDoom.numnodes == 0

    nodenum = CDoom.numnodes - 1

    while nodenum & CDoom::NF_SUBSECTOR == 0
      node = CDoom.nodes + nodenum
      side = CDoom.r_point_on_side(x, y, node)
      nodenum = node.value.children[side]
    end

    return CDoom.subsectors + (nodenum & ~CDoom::NF_SUBSECTOR)
  end

  def self.r_setup_frame(player : CDoom::Player*)
    CDoom.viewplayer = player
    CDoom.viewx = player.value.mo.value.x
    CDoom.viewy = player.value.mo.value.y
    CDoom.viewangle = player.value.mo.value.angle &+ CDoom.viewangleoffset
    CDoom.extralight = player.value.extralight

    CDoom.viewz = player.value.viewz

    CDoom.viewsin = @@finesine[CDoom.viewangle >> CDoom::ANGLETOFINESHIFT]
    CDoom.viewcos = @@finecosine[CDoom.viewangle >> CDoom::ANGLETOFINESHIFT]

    CDoom.sscount = 0

    if player.value.fixedcolormap != 0
      CDoom.fixedcolormap =
        CDoom.colormaps +
          player.value.fixedcolormap * 256 * sizeof(CDoom::Lighttable)

      CDoom.walllights = CDoom.scalelightfixed

      CDoom::MAXLIGHTSCALE.times { |i| CDoom.scalelightfixed[i] = CDoom.fixedcolormap }
    else
      CDoom.fixedcolormap = Pointer(CDoom::Lighttable).null
    end

    CDoom.framecount += 1
    CDoom.validcount += 1
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
    CDoom.r_render_bsp_node(CDoom.numnodes - 1)

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
         x2 >= CDoom.viewwidth ||
         y.to_u32! > CDoom.viewheight.to_u32!
        CDoom.i_error("Error: r_map_plane: #{x1} to #{x2} at #{y}")
      end
    {% end %}

    if CDoom.planeheight != CDoom.cachedheight[y]
      CDoom.cachedheight[y] = CDoom.planeheight
      CDoom.cacheddistance[y] = CDoom.fixed_mul(CDoom.planeheight, CDoom.yslope[y])
      distance = CDoom.cacheddistance[y]
      CDoom.cachedxstep[y] = CDoom.fixed_mul(distance, CDoom.basexscale)
      CDoom.ds_xstep = CDoom.cachedxstep[y]
      CDoom.cachedystep[y] = CDoom.fixed_mul(distance, CDoom.baseyscale)
      CDoom.ds_ystep = CDoom.cachedystep[y]
    else
      distance = CDoom.cacheddistance[y]
      CDoom.ds_xstep = CDoom.cachedxstep[y]
      CDoom.ds_ystep = CDoom.cachedystep[y]
    end

    length = CDoom.fixed_mul(distance, CDoom.distscale[x1])
    angle = (CDoom.viewangle &+ CDoom.xtoviewangle[x1]) >> CDoom::ANGLETOFINESHIFT
    CDoom.ds_xfrac = CDoom.viewx &+ CDoom.fixed_mul(@@finecosine[angle], length)
    CDoom.ds_yfrac = -CDoom.viewy &- CDoom.fixed_mul(@@finesine[angle], length)

    if !CDoom.fixedcolormap.null?
      CDoom.ds_colormap = CDoom.fixedcolormap
    else
      index = distance.to_u32! >> CDoom::LIGHTZSHIFT

      index = CDoom::MAXLIGHTZ - 1 if index >= CDoom::MAXLIGHTZ

      CDoom.ds_colormap = CDoom.planezlight[index]
    end

    CDoom.ds_y = y
    CDoom.ds_x1 = x1
    CDoom.ds_x2 = x2

    CDoom.r_draw_span
  end

  #
  # At begining of frame.
  #
  def self.r_clear_planes
    # opening / clipping determination
    CDoom.viewwidth.times do |i|
      CDoom.floorclip[i] = CDoom.viewheight.to_i16!
      CDoom.ceilingclip[i] = -1
    end

    @@visplanes.clear
    @@visplanes << CDoom::Visplane.new
    @@lastvisplane = 0
    CDoom.lastopening = CDoom.openings

    # texture calculation
    CDoom.doom_memset(CDoom.cachedheight, 0, sizeof(typeof(CDoom.cachedheight)))

    # left to right mapping
    angle = (CDoom.viewangle &- ANG90) >> CDoom::ANGLETOFINESHIFT

    # scale will be unit scale at SCREENWIDTH/2 distance
    CDoom.basexscale = CDoom.fixed_div(@@finecosine[angle], CDoom.centerxfrac)
    CDoom.baseyscale = -CDoom.fixed_div(@@finesine[angle], CDoom.centerxfrac)
  end

  def self.r_find_plane(height : CDoom::Fixed, picnum : LibC::Int, lightlevel : LibC::Int) : Int32
    if picnum == CDoom.skyflatnum
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
      CDoom.r_map_plane(t1, CDoom.spanstart[t1], x - 1)
      t1 += 1
    end
    while b1 > b2 && b1 >= t1
      CDoom.r_map_plane(b1, CDoom.spanstart[b1], x - 1)
      b1 -= 1
    end

    while t2 < t1 && t2 <= b2
      CDoom.spanstart[t2] = x
      t2 += 1
    end
    while b2 > b1 && b2 >= t2
      CDoom.spanstart[b2] = x
      b2 -= 1
    end
  end

  #
  # At the end of each frame.
  #
  def self.r_draw_planes
    {% if flag?("RANGECHECK") %}
      if CDoom.ds_p - CDoom.drawsegs.to_unsafe > CDoom::MAXDRAWSEGS
        CDoom.i_error("Error: r_draw_planes: drawsegs overflow (#{CDoom.ds_p - CDoom.drawsegs.to_unsafe})")
      end

      if @@lastvisplane > @@visplanes.size - 1
        CDoom.i_error("Error: r_draw_planes: visplane overflow (#{@@lastvisplane})")
      end

      if CDoom.lastopening - CDoom.openings.to_unsafe > CDoom::MAXOPENINGS
        CDoom.i_error("Error: r_draw_planes: opening overflow (#{CDoom.lastopening - CDoom.openings.to_unsafe})")
      end
    {% end %}

    pl = @@visplanes.to_unsafe
    while pl - @@visplanes.to_unsafe < @@lastvisplane
      if pl.value.minx > pl.value.maxx
        pl += 1
        next
      end

      # sky flat
      if pl.value.picnum == CDoom.skyflatnum
        CDoom.dc_iscale = CDoom.pspriteiscale

        # Sky is allways drawn full bright,
        #  i.e. colormaps[0] is used.
        # Because of this hack, sky is not affected
        #  by INVUL inverse mapping.
        CDoom.dc_colormap = CDoom.colormaps
        CDoom.dc_texturemid = CDoom.skytexturemid
        x = pl.value.minx
        while x <= pl.value.maxx
          CDoom.dc_yl = pl.value.top[x]
          CDoom.dc_yh = pl.value.bottom[x]

          if CDoom.dc_yl <= CDoom.dc_yh
            angle = (CDoom.viewangle &+ CDoom.xtoviewangle[x]) >> CDoom::ANGLETOSKYSHIFT
            CDoom.dc_x = x
            CDoom.dc_source = CDoom.r_get_column(CDoom.skytexture, angle)
            CDoom.colfunc.call
          end

          x += 1
        end
        pl += 1
        next
      end

      # regular flat
      CDoom.ds_source = CDoom.w_cache_lump_num(CDoom.firstflat +
                                               CDoom.flattranslation[pl.value.picnum],
        CDoom::PU_STATIC).as(CDoom::Byte*)

      CDoom.planeheight = doom_abs(pl.value.height - CDoom.viewz)
      light = (pl.value.lightlevel >> CDoom::LIGHTSEGSHIFT) + CDoom.extralight

      light = CDoom::LIGHTLEVELS - 1 if light >= CDoom::LIGHTLEVELS

      light = 0 if light < 0

      CDoom.planezlight = CDoom.zlight[light]

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
      z_change_tag(CDoom.ds_source, CDoom::PU_CACHE)
    end
  end

  def self.r_render_masked_seg_range(ds : CDoom::Drawseg*, x1 : LibC::Int, x2 : LibC::Int)
    # Calculate light table.
    # Use different light tables
    #   for horizontal / vertical / diagonal. Diagonal?
    # OPTIMIZE: get rid of LIGHTSEGSHIFT globally
    CDoom.curline = ds.value.curline
    CDoom.frontsector = CDoom.curline.value.frontsector
    CDoom.backsector = CDoom.curline.value.backsector
    texnum = CDoom.texturetranslation[CDoom.curline.value.sidedef.value.midtexture]

    lightnum = (CDoom.frontsector.value.lightlevel >> CDoom::LIGHTSEGSHIFT) + CDoom.extralight

    if CDoom.curline.value.v1.value.y == CDoom.curline.value.v2.value.y
      lightnum -= 1
    elsif CDoom.curline.value.v1.value.x == CDoom.curline.value.v2.value.x
      lightnum += 1
    end

    if lightnum < 0
      CDoom.walllights = CDoom.scalelight[0]
    elsif lightnum >= CDoom::LIGHTLEVELS
      CDoom.walllights = CDoom.scalelight[CDoom::LIGHTLEVELS - 1]
    else
      CDoom.walllights = CDoom.scalelight[lightnum]
    end

    CDoom.maskedtexturecol = ds.value.maskedtexturecol

    CDoom.rw_scalestep = ds.value.scalestep
    CDoom.spryscale = ds.value.scale1 + (x1 - ds.value.x1) * CDoom.rw_scalestep
    CDoom.mfloorclip = ds.value.sprbottomclip
    CDoom.mceilingclip = ds.value.sprtopclip

    # find positioning
    if CDoom.curline.value.linedef.value.flags & CDoom::ML_DONTPEGBOTTOM != 0
      CDoom.dc_texturemid = CDoom.frontsector.value.floorheight > CDoom.backsector.value.floorheight ? CDoom.frontsector.value.floorheight : CDoom.backsector.value.floorheight
      CDoom.dc_texturemid = CDoom.dc_texturemid + CDoom.textureheight[texnum] - CDoom.viewz
    else
      CDoom.dc_texturemid = CDoom.frontsector.value.ceilingheight < CDoom.backsector.value.ceilingheight ? CDoom.frontsector.value.ceilingheight : CDoom.backsector.value.ceilingheight
      CDoom.dc_texturemid = CDoom.dc_texturemid - CDoom.viewz
    end
    CDoom.dc_texturemid += CDoom.curline.value.sidedef.value.rowoffset

    CDoom.dc_colormap = CDoom.fixedcolormap if !CDoom.fixedcolormap.null?

    # draw the columns
    CDoom.dc_x = x1
    while CDoom.dc_x <= x2
      # calculate lighting
      if CDoom.maskedtexturecol[CDoom.dc_x] != Int16::MAX
        if CDoom.fixedcolormap.null?
          index = CDoom.spryscale >> CDoom::LIGHTSCALESHIFT

          index = CDoom::MAXLIGHTSCALE - 1 if index >= CDoom::MAXLIGHTSCALE

          CDoom.dc_colormap = CDoom.walllights[index]
        end

        CDoom.sprtopscreen = CDoom.centeryfrac - CDoom.fixed_mul(CDoom.dc_texturemid, CDoom.spryscale)
        CDoom.dc_iscale = 0xffffffff_u32 // CDoom.spryscale.to_u32!

        # draw the texture
        col = (CDoom.r_get_column(texnum, CDoom.maskedtexturecol[CDoom.dc_x]) - 3).as(CDoom::Column*)

        CDoom.r_draw_masked_column(col)
        CDoom.maskedtexturecol[CDoom.dc_x] = Int16::MAX
      end
      CDoom.spryscale += CDoom.rw_scalestep
      CDoom.dc_x += 1
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
    while CDoom.rw_x < CDoom.rw_stopx
      # mark floor / ceiling areas
      yl = (CDoom.topfrac + CDoom::HEIGHTUNIT - 1) >> CDoom::HEIGHTBITS

      # no space above wall?
      yl = CDoom.ceilingclip[CDoom.rw_x] + 1 if yl < CDoom.ceilingclip[CDoom.rw_x] + 1

      if CDoom.markceiling != 0
        top = CDoom.ceilingclip[CDoom.rw_x] + 1
        bottom = yl - 1

        bottom = CDoom.floorclip[CDoom.rw_x] - 1 if bottom >= CDoom.floorclip[CDoom.rw_x]

        if top <= bottom
          ((@@visplanes.to_unsafe + @@ceilingplane).value.top.to_unsafe + CDoom.rw_x).value = top.to_u8!
          ((@@visplanes.to_unsafe + @@ceilingplane).value.bottom.to_unsafe + CDoom.rw_x).value = bottom.to_u8!
        end
      end

      yh = CDoom.bottomfrac >> CDoom::HEIGHTBITS

      yh = CDoom.floorclip[CDoom.rw_x] - 1 if yh >= CDoom.floorclip[CDoom.rw_x]

      if CDoom.markfloor != 0
        top = yh + 1
        bottom = CDoom.floorclip[CDoom.rw_x] - 1
        top = CDoom.ceilingclip[CDoom.rw_x] + 1 if top <= CDoom.ceilingclip[CDoom.rw_x]
        if top <= bottom
          ((@@visplanes.to_unsafe + @@floorplane).value.top.to_unsafe + CDoom.rw_x).value = top.to_u8!
          ((@@visplanes.to_unsafe + @@floorplane).value.bottom.to_unsafe + CDoom.rw_x).value = bottom.to_u8!
        end
      end

      texturecolumn = 0

      # texturecolumn and lighting are independent of wall tiers
      if CDoom.segtextured != 0
        # calculate texture offset
        angle = (CDoom.rw_centerangle &+ CDoom.xtoviewangle[CDoom.rw_x]) >> CDoom::ANGLETOFINESHIFT
        angle = 0_u32 if angle >= (FINEANGLES.tdiv(2))
        texturecolumn = CDoom.rw_offset - CDoom.fixed_mul(@@finetangent[angle], CDoom.rw_distance)
        texturecolumn >>= FRACBITS
        # calculate lighting
        index = CDoom.rw_scale >> CDoom::LIGHTSCALESHIFT

        index = CDoom::MAXLIGHTSCALE - 1 if index >= CDoom::MAXLIGHTSCALE

        CDoom.dc_colormap = CDoom.walllights[index]
        CDoom.dc_x = CDoom.rw_x
        CDoom.dc_iscale = 0xffffffff_u32 // CDoom.rw_scale.to_u32!
      end

      # draw the wall tiers
      if CDoom.midtexture != 0
        # single sided line
        CDoom.dc_yl = yl
        CDoom.dc_yh = yh
        CDoom.dc_texturemid = CDoom.rw_midtexturemid
        CDoom.dc_source = CDoom.r_get_column(CDoom.midtexture, texturecolumn)
        CDoom.colfunc.call
        CDoom.ceilingclip[CDoom.rw_x] = CDoom.viewheight.to_i16!
        CDoom.floorclip[CDoom.rw_x] = -1
      else
        # two sided line
        if CDoom.toptexture != 0
          # top wall
          mid = CDoom.pixhigh >> CDoom::HEIGHTBITS
          CDoom.pixhigh += CDoom.pixhighstep

          mid = CDoom.floorclip[CDoom.rw_x] - 1 if mid >= CDoom.floorclip[CDoom.rw_x]

          if mid >= yl
            CDoom.dc_yl = yl
            CDoom.dc_yh = mid
            CDoom.dc_texturemid = CDoom.rw_toptexturemid
            CDoom.dc_source = CDoom.r_get_column(CDoom.toptexture, texturecolumn)
            CDoom.colfunc.call
            CDoom.ceilingclip[CDoom.rw_x] = mid.to_i16!
          else
            CDoom.ceilingclip[CDoom.rw_x] = yl.to_i16! - 1
          end
        else
          # no top wall
          CDoom.ceilingclip[CDoom.rw_x] = yl.to_i16! - 1 if CDoom.markceiling != 0
        end

        if CDoom.bottomtexture != 0
          # bottom wall
          mid = (CDoom.pixlow + CDoom::HEIGHTUNIT - 1) >> CDoom::HEIGHTBITS
          CDoom.pixlow += CDoom.pixlowstep

          # no space above wall?
          mid = CDoom.ceilingclip[CDoom.rw_x] + 1 if mid <= CDoom.ceilingclip[CDoom.rw_x]

          if mid <= yh
            CDoom.dc_yl = mid
            CDoom.dc_yh = yh
            CDoom.dc_texturemid = CDoom.rw_bottomtexturemid
            CDoom.dc_source = CDoom.r_get_column(CDoom.bottomtexture,
              texturecolumn)
            CDoom.colfunc.call
            CDoom.floorclip[CDoom.rw_x] = mid.to_i16!
          else
            CDoom.floorclip[CDoom.rw_x] = yh.to_i16! + 1
          end
        else
          # no bottom wall
          CDoom.floorclip[CDoom.rw_x] = yh.to_i16! + 1 if CDoom.markfloor != 0
        end

        if CDoom.maskedtexture != 0
          # save texturecol
          #  for backdrawing of masked mid texture
          CDoom.maskedtexturecol[CDoom.rw_x] = texturecolumn.to_i16!
        end
      end

      CDoom.rw_scale += CDoom.rw_scalestep
      CDoom.topfrac += CDoom.topstep
      CDoom.bottomfrac += CDoom.bottomstep

      CDoom.rw_x += 1
    end
  end

  #
  # A wall segment will be drawn
  #  between start and stop pixels (inclusive).
  #
  def self.r_store_wall_range(start : LibC::Int, stop : LibC::Int)
    # don't overflow and crash
    return if CDoom.ds_p == CDoom.drawsegs.to_unsafe + CDoom::MAXDRAWSEGS

    {% if flag?("RANGECHECK") %}
      if start >= CDoom.viewwidth || start > stop
        CDoom.i_error("Error: bad r_render_wall_range: #{start} to #{stop}")
      end
    {% end %}

    CDoom.sidedef = CDoom.curline.value.sidedef
    CDoom.linedef = CDoom.curline.value.linedef

    # mark the segment as visible for auto map
    CDoom.linedef.value.flags = CDoom.linedef.value.flags | CDoom::ML_MAPPED

    # calculate rw_distance for scale calculation
    CDoom.rw_normalangle = CDoom.curline.value.angle &+ ANG90
    offsetangle = CDoom.rw_normalangle &- CDoom.rw_angle1
    offsetangle = (-(offsetangle.to_i32!)).to_u32! if offsetangle > ANG180

    offsetangle = ANG90 if offsetangle > ANG90

    distangle = ANG90 &- offsetangle
    hyp = CDoom.r_point_to_dist(CDoom.curline.value.v1.value.x, CDoom.curline.value.v1.value.y)
    sineval = @@finesine[distangle >> CDoom::ANGLETOFINESHIFT]
    CDoom.rw_distance = CDoom.fixed_mul(hyp, sineval)

    CDoom.ds_p.value.x1 = start
    CDoom.rw_x = start
    CDoom.ds_p.value.x2 = stop
    CDoom.ds_p.value.curline = CDoom.curline
    CDoom.rw_stopx = stop + 1

    # calculate scale at both ends and step
    CDoom.ds_p.value.scale1 = CDoom.r_scale_from_global_angle(CDoom.viewangle &+ CDoom.xtoviewangle[start])
    CDoom.rw_scale = CDoom.ds_p.value.scale1

    if stop > start
      CDoom.ds_p.value.scale2 = CDoom.r_scale_from_global_angle(CDoom.viewangle &+ CDoom.xtoviewangle[stop])
      CDoom.ds_p.value.scalestep = (CDoom.ds_p.value.scale2 - CDoom.rw_scale).tdiv(stop - start)
      CDoom.rw_scalestep = CDoom.ds_p.value.scalestep
    else
      CDoom.ds_p.value.scale2 = CDoom.ds_p.value.scale1
    end

    # calculate texture boundaries
    #  and decide if floor / ceiling marks are needed
    CDoom.worldtop = CDoom.frontsector.value.ceilingheight - CDoom.viewz
    CDoom.worldbottom = CDoom.frontsector.value.floorheight - CDoom.viewz

    CDoom.midtexture = 0
    CDoom.toptexture = 0
    CDoom.bottomtexture = 0
    CDoom.maskedtexture = 0
    CDoom.ds_p.value.maskedtexturecol = Pointer(Int16).null

    if CDoom.backsector.null?
      # single sided line
      CDoom.midtexture = CDoom.texturetranslation[CDoom.sidedef.value.midtexture]
      # a single sided line is terminal, so it must mark ends
      CDoom.markfloor = 1
      CDoom.markceiling = 1
      if CDoom.linedef.value.flags & CDoom::ML_DONTPEGBOTTOM != 0
        vtop = CDoom.frontsector.value.floorheight +
               CDoom.textureheight[CDoom.sidedef.value.midtexture]
        # bottom of texture at bottom
        CDoom.rw_midtexturemid = vtop - CDoom.viewz
      else
        # top of texture at top
        CDoom.rw_midtexturemid = CDoom.worldtop
      end
      CDoom.rw_midtexturemid += CDoom.sidedef.value.rowoffset

      CDoom.ds_p.value.silhouette = CDoom::SIL_BOTH
      CDoom.ds_p.value.sprtopclip = CDoom.screenheightarray
      CDoom.ds_p.value.sprbottomclip = CDoom.negonearray
      CDoom.ds_p.value.bsilheight = Int32::MAX
      CDoom.ds_p.value.tsilheight = Int32::MIN
    else
      # two sided line
      CDoom.ds_p.value.sprtopclip = Pointer(Int16).null
      CDoom.ds_p.value.sprbottomclip = Pointer(Int16).null
      CDoom.ds_p.value.silhouette = 0

      if CDoom.frontsector.value.floorheight > CDoom.backsector.value.floorheight
        CDoom.ds_p.value.silhouette = CDoom::SIL_BOTTOM
        CDoom.ds_p.value.bsilheight = CDoom.frontsector.value.floorheight
      elsif CDoom.backsector.value.floorheight > CDoom.viewz
        CDoom.ds_p.value.silhouette = CDoom::SIL_BOTTOM
        CDoom.ds_p.value.bsilheight = Int32::MAX
      end

      if CDoom.frontsector.value.ceilingheight < CDoom.backsector.value.ceilingheight
        CDoom.ds_p.value.silhouette = CDoom.ds_p.value.silhouette | CDoom::SIL_TOP
        CDoom.ds_p.value.tsilheight = CDoom.frontsector.value.ceilingheight
      elsif CDoom.backsector.value.ceilingheight < CDoom.viewz
        CDoom.ds_p.value.silhouette = CDoom.ds_p.value.silhouette | CDoom::SIL_TOP
        CDoom.ds_p.value.tsilheight = Int32::MIN
      end

      if CDoom.backsector.value.ceilingheight <= CDoom.frontsector.value.floorheight
        CDoom.ds_p.value.sprbottomclip = CDoom.negonearray
        CDoom.ds_p.value.bsilheight = Int32::MAX
        CDoom.ds_p.value.silhouette = CDoom.ds_p.value.silhouette | CDoom::SIL_BOTTOM
      end

      if CDoom.backsector.value.floorheight >= CDoom.frontsector.value.ceilingheight
        CDoom.ds_p.value.sprtopclip = CDoom.screenheightarray
        CDoom.ds_p.value.tsilheight = Int32::MIN
        CDoom.ds_p.value.silhouette = CDoom.ds_p.value.silhouette | CDoom::SIL_TOP
      end

      CDoom.worldhigh = CDoom.backsector.value.ceilingheight - CDoom.viewz
      CDoom.worldlow = CDoom.backsector.value.floorheight - CDoom.viewz

      # hack to allow height changes in outdoor areas
      if CDoom.frontsector.value.ceilingpic == CDoom.skyflatnum &&
         CDoom.backsector.value.ceilingpic == CDoom.skyflatnum
        CDoom.worldtop = CDoom.worldhigh
      end

      if CDoom.worldlow != CDoom.worldbottom ||
         CDoom.backsector.value.floorpic != CDoom.frontsector.value.floorpic ||
         CDoom.backsector.value.lightlevel != CDoom.frontsector.value.lightlevel
        CDoom.markfloor = 1
      else
        # same plane on both sides
        CDoom.markfloor = 0
      end

      if CDoom.worldhigh != CDoom.worldtop ||
         CDoom.backsector.value.ceilingpic != CDoom.frontsector.value.ceilingpic ||
         CDoom.backsector.value.lightlevel != CDoom.frontsector.value.lightlevel
        CDoom.markceiling = 1
      else
        # same plane on both sides
        CDoom.markceiling = 0
      end

      if CDoom.backsector.value.ceilingheight <= CDoom.frontsector.value.floorheight ||
         CDoom.backsector.value.floorheight >= CDoom.frontsector.value.ceilingheight
        # closed door
        CDoom.markceiling = 1
        CDoom.markfloor = 1
      end

      if CDoom.worldhigh < CDoom.worldtop
        # top texture
        CDoom.toptexture = CDoom.texturetranslation[CDoom.sidedef.value.toptexture]
        if CDoom.linedef.value.flags & CDoom::ML_DONTPEGTOP != 0
          # top of texture at top
          CDoom.rw_toptexturemid = CDoom.worldtop
        else
          vtop = CDoom.backsector.value.ceilingheight + CDoom.textureheight[CDoom.sidedef.value.toptexture]
          # bottom of texture
          CDoom.rw_toptexturemid = vtop - CDoom.viewz
        end
      end
      if CDoom.worldlow > CDoom.worldbottom
        # bottom texture
        CDoom.bottomtexture = CDoom.texturetranslation[CDoom.sidedef.value.bottomtexture]
        if CDoom.linedef.value.flags & CDoom::ML_DONTPEGBOTTOM != 0
          # bottom of texture at bottom
          # top of texture at top
          CDoom.rw_bottomtexturemid = CDoom.worldtop
        else # top of texture at top
          CDoom.rw_bottomtexturemid = CDoom.worldlow
        end
      end
      CDoom.rw_toptexturemid &+= CDoom.sidedef.value.rowoffset
      CDoom.rw_bottomtexturemid &+= CDoom.sidedef.value.rowoffset

      # allocate space for masked texture tables
      if CDoom.sidedef.value.midtexture != 0
        CDoom.maskedtexture = 1
        CDoom.ds_p.value.maskedtexturecol = CDoom.lastopening - CDoom.rw_x
        CDoom.maskedtexturecol = CDoom.ds_p.value.maskedtexturecol
        CDoom.lastopening += CDoom.rw_stopx - CDoom.rw_x
      end
    end

    # calculate rw_offset (only needed for textured lines)
    CDoom.segtextured = CDoom.midtexture | CDoom.toptexture | CDoom.bottomtexture | CDoom.maskedtexture

    if CDoom.segtextured != 0
      offsetangle = CDoom.rw_normalangle &- CDoom.rw_angle1

      offsetangle = (-(offsetangle.to_i32!)).to_u32! if offsetangle > ANG180

      offsetangle = ANG90 if offsetangle > ANG90

      sineval = @@finesine[offsetangle >> CDoom::ANGLETOFINESHIFT]
      CDoom.rw_offset = CDoom.fixed_mul(hyp, sineval)

      CDoom.rw_offset = -CDoom.rw_offset if CDoom.rw_normalangle &- CDoom.rw_angle1 < ANG180

      CDoom.rw_offset += CDoom.sidedef.value.textureoffset + CDoom.curline.value.offset
      CDoom.rw_centerangle = ANG90 &+ CDoom.viewangle &- CDoom.rw_normalangle

      # calculate light table
      #  use different light tables
      #  for horizontal / vertical / diagonal
      # OPTIMIZE: get rid of LIGHTSEGSHIFT globally
      if CDoom.fixedcolormap.null?
        lightnum = (CDoom.frontsector.value.lightlevel >> CDoom::LIGHTSEGSHIFT) + CDoom.extralight

        if CDoom.curline.value.v1.value.y == CDoom.curline.value.v2.value.y
          lightnum -= 1
        elsif CDoom.curline.value.v1.value.x == CDoom.curline.value.v2.value.x
          lightnum += 1
        end

        if lightnum < 0
          CDoom.walllights = CDoom.scalelight[0]
        elsif lightnum >= CDoom::LIGHTLEVELS
          CDoom.walllights = CDoom.scalelight[CDoom::LIGHTLEVELS - 1]
        else
          CDoom.walllights = CDoom.scalelight[lightnum]
        end
      end
    end

    # if a floor / ceiling plane is on the wrong side
    #  of the view plane, it is definitely invisible
    #  and doesn't need to be marked.

    if CDoom.frontsector.value.floorheight >= CDoom.viewz
      # above view plane
      CDoom.markfloor = 0
    end

    if CDoom.frontsector.value.ceilingheight <= CDoom.viewz &&
       CDoom.frontsector.value.ceilingpic != CDoom.skyflatnum
      # below view plane
      CDoom.markceiling = 0
    end

    # calculate incremental stepping values for texture edges
    CDoom.worldtop >>= 4
    CDoom.worldbottom >>= 4

    CDoom.topstep = -CDoom.fixed_mul(CDoom.rw_scalestep, CDoom.worldtop)
    CDoom.topfrac = (CDoom.centeryfrac >> 4) - CDoom.fixed_mul(CDoom.worldtop, CDoom.rw_scale)

    CDoom.bottomstep = -CDoom.fixed_mul(CDoom.rw_scalestep, CDoom.worldbottom)
    CDoom.bottomfrac = (CDoom.centeryfrac >> 4) - CDoom.fixed_mul(CDoom.worldbottom, CDoom.rw_scale)

    if !CDoom.backsector.null?
      CDoom.worldhigh >>= 4
      CDoom.worldlow >>= 4

      if CDoom.worldhigh < CDoom.worldtop
        CDoom.pixhigh = (CDoom.centeryfrac >> 4) - CDoom.fixed_mul(CDoom.worldhigh, CDoom.rw_scale)
        CDoom.pixhighstep = -CDoom.fixed_mul(CDoom.rw_scalestep, CDoom.worldhigh)
      end

      if CDoom.worldlow > CDoom.worldbottom
        CDoom.pixlow = (CDoom.centeryfrac >> 4) - CDoom.fixed_mul(CDoom.worldlow, CDoom.rw_scale)
        CDoom.pixlowstep = -CDoom.fixed_mul(CDoom.rw_scalestep, CDoom.worldlow)
      end
    end

    # render it
    @@ceilingplane = r_check_plane(@@ceilingplane, CDoom.rw_x, CDoom.rw_stopx - 1) if CDoom.markceiling != 0

    @@floorplane = r_check_plane(@@floorplane, CDoom.rw_x, CDoom.rw_stopx - 1) if CDoom.markfloor != 0

    CDoom.r_render_seg_loop

    # save sprite clipping info
    if ((CDoom.ds_p.value.silhouette & CDoom::SIL_TOP != 0) || CDoom.maskedtexture != 0) &&
       CDoom.ds_p.value.sprtopclip.null?
      CDoom.doom_memcpy(CDoom.lastopening, CDoom.ceilingclip.to_unsafe + start, 2 * (CDoom.rw_stopx - start))
      CDoom.ds_p.value.sprtopclip = CDoom.lastopening - start
      CDoom.lastopening += CDoom.rw_stopx - start
    end

    if ((CDoom.ds_p.value.silhouette & CDoom::SIL_BOTTOM != 0) || CDoom.maskedtexture != 0) &&
       CDoom.ds_p.value.sprbottomclip.null?
      CDoom.doom_memcpy(CDoom.lastopening, CDoom.floorclip.to_unsafe + start, 2 * (CDoom.rw_stopx - start))
      CDoom.ds_p.value.sprbottomclip = CDoom.lastopening - start
      CDoom.lastopening += CDoom.rw_stopx - start
    end

    if CDoom.maskedtexture != 0 && CDoom.ds_p.value.silhouette & CDoom::SIL_TOP == 0
      CDoom.ds_p.value.silhouette = CDoom.ds_p.value.silhouette | CDoom::SIL_TOP
      CDoom.ds_p.value.tsilheight = Int32::MIN
    end
    if CDoom.maskedtexture != 0 && CDoom.ds_p.value.silhouette & CDoom::SIL_BOTTOM == 0
      CDoom.ds_p.value.silhouette = CDoom.ds_p.value.silhouette | CDoom::SIL_BOTTOM
      CDoom.ds_p.value.bsilheight = Int32::MAX
    end
    CDoom.ds_p += 1
  end

  #
  # Called whenever the view size changes.
  #
  def self.r_init_sky_map
    CDoom.skytexturemid = 100 * FRACUNIT
  end

  #
  # INITIALIZATION FUNCTIONS
  #

  #
  # Local function for R_InitSprites.
  #
  def self.r_install_sprite_lump(lump : LibC::Int, frame : LibC::UInt, rotation : LibC::UInt, flipped : CDoom::DoomBool)
    if frame >= 29 || rotation > 8
      CDoom.i_error("Error: r_install_sprite_lump: Bad frame characters in lump #{lump}")
    end

    CDoom.maxframe = frame if frame.to_i32! > CDoom.maxframe

    if rotation == 0
      # the lump should be used for all rotations
      if CDoom.sprtemp[frame].rotate == 0
        STDERR.puts "Warning: r_install_sprite_lump: Sprite  #{String.new(CDoom.spritename)} frame #{'A' + frame} has multip rot=0 lump, using lump #{lump}"
      end

      if CDoom.sprtemp[frame].rotate == 1
        STDERR.puts "Warning: r_install_sprite_lump: Sprite  #{String.new(CDoom.spritename)} frame #{'A' + frame} has rotations, overriding with rot=0 lump #{lump}"
      end

      (CDoom.sprtemp.to_unsafe + frame).value.rotate = 0
      8.times do |r|
        ((CDoom.sprtemp.to_unsafe + frame).value.lump.to_unsafe + r).value = (lump - CDoom.firstspritelump).to_i16!
        ((CDoom.sprtemp.to_unsafe + frame).value.flip.to_unsafe + r).value = flipped.to_u8!
      end
      return
    end

    # the lump is only used for one rotation
    if CDoom.sprtemp[frame].rotate == 0
      STDERR.puts "Warning: r_install_sprite_lump: Sprite  #{String.new(CDoom.spritename)} frame #{'A' + frame} has rotations, but a rot=0 lump was already set; discarding it"
      # Reset to the -1 "unset" sentinel (matches sprtemp's initial memset) so
      # partial per-rotation data can take over cleanly instead of leaving
      # stale rot=0 lump indices (which could otherwise look like valid,
      # already-filled rotation slots and silently mask missing rotations).
      8.times do |r|
        ((CDoom.sprtemp.to_unsafe + frame).value.lump.to_unsafe + r).value = -1_i16
      end
    end

    (CDoom.sprtemp.to_unsafe + frame).value.rotate = 1

    # make - based
    rotation -= 1
    if CDoom.sprtemp[frame].lump[rotation] != -1
      STDERR.puts "Warning: r_install_sprite_lump: Sprite #{String.new(CDoom.spritename)} : #{'A' + frame} : #{'1' + rotation} has two lumps mapped to it, using lump #{lump}"
    end

    ((CDoom.sprtemp.to_unsafe + frame).value.lump.to_unsafe + rotation).value = (lump - CDoom.firstspritelump).to_i16!
    ((CDoom.sprtemp.to_unsafe + frame).value.flip.to_unsafe + rotation).value = flipped.to_u8!
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
  def self.r_init_sprite_defs(namelist : LibC::Char**)
    # count the number of sprite names
    check = namelist

    while !check.value.null?
      check += 1
    end

    CDoom.numsprites = check - namelist

    return if CDoom.numsprites == 0

    CDoom.sprites = CDoom.z_malloc(CDoom.numsprites * sizeof(CDoom::Spritedef), CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Spritedef*)

    start = CDoom.firstspritelump - 1
    endl = CDoom.lastspritelump + 1

    # scan all the lump names for each of the names,
    #  noting the highest frame letter.
    # Just compare 4 characters as ints
    CDoom.numsprites.times do |i|
      CDoom.spritename = namelist[i]
      CDoom.doom_memset(CDoom.sprtemp, -1, sizeof(typeof(CDoom.sprtemp)))
      CDoom.maxframe = -1
      intname = namelist[i].as(Int32*).value

      # scan the lumps,
      #  filling in the frames for whatever is found
      l = start + 1
      while l < endl
        if @@lumpinfo[l].name.to_unsafe.as(Int32*).value == intname
          frame = @@lumpinfo[l].name[4] - 'A'.ord
          rotation = @@lumpinfo[l].name[5] - '0'.ord

          if CDoom.modifiedgame != 0
            patched = CDoom.w_get_num_for_name(@@lumpinfo[l].name)
          else
            patched = l
          end

          CDoom.r_install_sprite_lump(patched, frame, rotation, 0)

          if @@lumpinfo[l].name[6] != 0
            frame = @@lumpinfo[l].name[6] - 'A'.ord
            rotation = @@lumpinfo[l].name[7] - '0'.ord
            CDoom.r_install_sprite_lump(l, frame, rotation, 1)
          end
        end

        l += 1
      end

      # check the frames that were found for completeness
      if CDoom.maxframe == -1
        CDoom.sprites[i].numframes = 0
        next
      end

      CDoom.maxframe += 1

      CDoom.maxframe.times do |frame|
        case CDoom.sprtemp[frame].rotate
        when -1
          CDoom.i_error("Error: r_init_sprite_defs: No patches found for #{String.new(namelist[i])} frame #{'A' + frame}")
        when 0
          # only the first rotation is needed
        when 1
          # must have all 8 frames
          8.times do |rotation|
            if CDoom.sprtemp[frame].lump[rotation] == -1
              CDoom.i_error("Error: r_init_sprite_defs: Sprite #{String.new(namelist[i])} frame #{'A' + frame} is missing rotations")
            end
          end
        end
      end

      # allocate space for the frames present and copy sprtemp to it
      (CDoom.sprites + i).value.numframes = CDoom.maxframe
      (CDoom.sprites + i).value.spriteframes =
        CDoom.z_malloc(CDoom.maxframe * sizeof(CDoom::Spriteframe), CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Spriteframe*)
      CDoom.doom_memcpy(CDoom.sprites[i].spriteframes, CDoom.sprtemp, CDoom.maxframe * sizeof(CDoom::Spriteframe))
    end
  end

  #
  # GAME FUNCTIONS
  #

  #
  # Called at program start.
  #
  def self.r_init_sprites(namelist : LibC::Char**)
    CDoom::SCREENWIDTH.times { |i| CDoom.negonearray[i] = -1 }
    CDoom.r_init_sprite_defs(namelist)
  end

  #
  # Called at frame start.
  #
  def self.r_clear_sprites
    CDoom.vissprite_p = CDoom.vissprites.to_unsafe
  end

  def self.r_new_vis_sprite : CDoom::Vissprite*
    return pointerof(CDoom.overflowsprite) if CDoom.vissprite_p == CDoom.vissprites.to_unsafe + CDoom::MAXVISSPRITES

    CDoom.vissprite_p += 1
    return CDoom.vissprite_p - 1
  end

  #
  # Used for sprites and masked mid textures.
  # Masked means: partly transparent, i.e. stored
  #  in posts/runs of opaque pixels.
  #
  def self.r_draw_masked_column(column : CDoom::Column*)
    basetexturemid = CDoom.dc_texturemid

    until column.value.topdelta == 0xff
      # calculate unclipped screen coordinates
      #  for post
      topscreen = CDoom.sprtopscreen + CDoom.spryscale * column.value.topdelta
      bottomscreen = topscreen + CDoom.spryscale * column.value.length

      CDoom.dc_yl = (topscreen + FRACUNIT - 1) >> FRACBITS
      CDoom.dc_yh = (bottomscreen - 1) >> FRACBITS

      CDoom.dc_yh = CDoom.mfloorclip[CDoom.dc_x] - 1 if CDoom.dc_yh >= CDoom.mfloorclip[CDoom.dc_x]
      CDoom.dc_yl = CDoom.mceilingclip[CDoom.dc_x] + 1 if CDoom.dc_yl <= CDoom.mceilingclip[CDoom.dc_x]

      if CDoom.dc_yl <= CDoom.dc_yh
        CDoom.dc_source = column.as(UInt8*) + 3
        CDoom.dc_texturemid = basetexturemid - (column.value.topdelta.to_i32 << FRACBITS)

        # Drawn by either r_draw_column
        #  or (SHADOW) r_draw_fuzz_column
        CDoom.colfunc.call
      end
      column = (column.as(UInt8*) + column.value.length + 4).as(CDoom::Column*)
    end
    CDoom.dc_texturemid = basetexturemid
  end

  def self.r_draw_vis_sprite(vis : CDoom::Vissprite*, x1 : LibC::Int, x2 : LibC::Int)
    patch = CDoom.w_cache_lump_num(vis.value.patch + CDoom.firstspritelump, CDoom::PU_CACHE).as(CDoom::Patch*)

    CDoom.dc_colormap = vis.value.colormap

    if CDoom.dc_colormap.null?
      # 0 colormap = shadow draw
      CDoom.colfunc = ->CDoom.r_draw_fuzz_column
    elsif vis.value.mobjflags & CDoom::Mobjflag::MF_TRANSLATION.value != 0
      CDoom.colfunc = ->CDoom.r_draw_translated_column
      CDoom.dc_translation = CDoom.translationtables - 256 +
                             ((vis.value.mobjflags & CDoom::Mobjflag::MF_TRANSLATION.value) >> (CDoom::Mobjflag::MF_TRANSSHIFT.value - 8))
    end

    CDoom.dc_iscale = doom_abs(vis.value.xiscale)
    CDoom.dc_texturemid = vis.value.texturemid
    frac = vis.value.startfrac
    CDoom.spryscale = vis.value.scale
    CDoom.sprtopscreen = CDoom.centeryfrac - CDoom.fixed_mul(CDoom.dc_texturemid, CDoom.spryscale)

    CDoom.dc_x = vis.value.x1
    while CDoom.dc_x <= vis.value.x2
      texturecolumn = frac >> FRACBITS
      {% if flag?("RANGECHECK") %}
        if texturecolumn < 0 || texturecolumn >= patch.value.width
          CDoom.i_error("Error: r_draw_vis_sprite: bad texturecolumn")
        end
      {% end %}
      column = (patch.as(UInt8*) + (patch.value.columnofs.to_unsafe + texturecolumn).value).as(CDoom::Column*)
      CDoom.r_draw_masked_column(column)

      CDoom.dc_x += 1
      frac += vis.value.xiscale
    end

    CDoom.colfunc = ->CDoom.r_draw_column
  end

  #
  # Generates a vissprite for a thing
  #  if it might be visible.
  #
  def self.r_project_sprite(thing : CDoom::Mobj*)
    return if thing.value.sprite == CDoom::Spritenum::SPR_TNT

    # transform the origin point
    tr_x = thing.value.x - CDoom.viewx
    tr_y = thing.value.y - CDoom.viewy

    gxt = CDoom.fixed_mul(tr_x, CDoom.viewcos)
    gyt = -CDoom.fixed_mul(tr_y, CDoom.viewsin)

    tz = gxt &- gyt

    # thing is behind view plane?
    return if tz < CDoom::MINZ

    xscale = CDoom.fixed_div(CDoom.projection, tz)

    gxt = -CDoom.fixed_mul(tr_x, CDoom.viewsin)
    gyt = CDoom.fixed_mul(tr_y, CDoom.viewcos)
    tx = -(gyt + gxt)

    # too far off the side?
    return if doom_abs(tx) > (tz << 2)

    # decide which patch to use for sprite relative to player
    {% if flag?("RANGECHECK") %}
      if thing.value.sprite.to_u32! >= CDoom.numsprites.to_u32!
        CDoom.i_error("Error: r_project_sprite: invalid sprite number #{thing.value.sprite.value} ")
      end
    {% end %}
    sprdef = CDoom.sprites + thing.value.sprite.value
    {% if flag?("RANGECHECK") %}
      if thing.value.frame & CDoom::FF_FRAMEMASK >= sprdef.value.numframes
        CDoom.i_error("Error: r_project_sprite: invalid sprite frame #{thing.value.sprite.value} : #{thing.value.frame} ")
      end
    {% end %}
    sprframe = sprdef.value.spriteframes + (thing.value.frame & CDoom::FF_FRAMEMASK)

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
    tx -= CDoom.spriteoffset[lump]
    x1 = (CDoom.centerxfrac + CDoom.fixed_mul(tx, xscale)) >> FRACBITS

    # off the right side?
    return if x1 > CDoom.viewwidth

    tx += CDoom.spritewidth[lump]
    x2 = ((CDoom.centerxfrac + CDoom.fixed_mul(tx, xscale)) >> FRACBITS) - 1

    # off the left side
    return if x2 < 0

    # store information in a vissprite
    vis = CDoom.r_new_vis_sprite
    vis.value.mobjflags = thing.value.flags
    vis.value.scale = xscale
    vis.value.gx = thing.value.x
    vis.value.gy = thing.value.y
    vis.value.gz = thing.value.z
    vis.value.gzt = thing.value.z + CDoom.spritetopoffset[lump]
    vis.value.texturemid = vis.value.gzt - CDoom.viewz
    vis.value.x1 = x1 < 0 ? 0 : x1
    vis.value.x2 = x2 >= CDoom.viewwidth ? CDoom.viewwidth - 1 : x2
    iscale = CDoom.fixed_div(FRACUNIT, xscale)

    if flip != 0
      vis.value.startfrac = CDoom.spritewidth[lump] - 1
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
    if thing.value.flags & CDoom::Mobjflag::MF_SHADOW.value != 0
      # shadow draw
      vis.value.colormap = Pointer(CDoom::Lighttable).null
    elsif !CDoom.fixedcolormap.null?
      # fixed map
      vis.value.colormap = CDoom.fixedcolormap
    elsif thing.value.frame & CDoom::FF_FULLBRIGHT != 0
      # full bright
      vis.value.colormap = CDoom.colormaps
    else
      # diminished light
      index = xscale >> CDoom::LIGHTSCALESHIFT

      index = CDoom::MAXLIGHTSCALE - 1 if index >= CDoom::MAXLIGHTSCALE

      vis.value.colormap = CDoom.spritelights[index]
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
    return if sec.value.validcount == CDoom.validcount

    # Well, now it will be done.
    sec.value.validcount = CDoom.validcount

    lightnum = (sec.value.lightlevel >> CDoom::LIGHTSEGSHIFT) + CDoom.extralight

    if lightnum < 0
      CDoom.spritelights = CDoom.scalelight[0]
    elsif lightnum >= CDoom::LIGHTLEVELS
      CDoom.spritelights = CDoom.scalelight[CDoom::LIGHTLEVELS - 1]
    else
      CDoom.spritelights = CDoom.scalelight[lightnum]
    end

    # Handle all things in sector.
    thing = sec.value.thinglist
    until thing.null?
      CDoom.r_project_sprite(thing)
      thing = thing.value.snext
    end
  end

  def self.r_draw_psprite(psp : CDoom::Pspdef*)
    return if psp.value.state.value.sprite == CDoom::Spritenum::SPR_TNT

    # decide which patch to use
    {% if flag?("RANGECHECK") %}
      if psp.value.state.value.sprite.value >= CDoom.numsprites
        CDoom.i_error("Error: r_draw_psprite: invalid sprite number #{psp.value.state.value.sprite.value} ")
      end
    {% end %}
    sprdef = CDoom.sprites + psp.value.state.value.sprite.value
    {% if flag?("RANGECHECK") %}
      if psp.value.state.value.frame & CDoom::FF_FRAMEMASK >= sprdef.value.numframes
        CDoom.i_error("Error: r_draw_psprite: invalid sprite frame #{psp.value.state.value.sprite.value} : #{psp.value.state.value.frame} ")
      end
    {% end %}
    sprframe = sprdef.value.spriteframes + (psp.value.state.value.frame & CDoom::FF_FRAMEMASK)

    lump = sprframe.value.lump[0]
    flip = sprframe.value.flip[0]

    # calculate edges of the shape
    tx = psp.value.sx - 160 * FRACUNIT

    tx -= CDoom.spriteoffset[lump]
    x1 = (CDoom.centerxfrac + CDoom.fixed_mul(tx, CDoom.pspritescale)) >> FRACBITS

    # off the right side?
    return if x1 > CDoom.viewwidth

    tx += CDoom.spritewidth[lump]
    x2 = ((CDoom.centerxfrac + CDoom.fixed_mul(tx, CDoom.pspritescale)) >> FRACBITS) - 1

    # off the left side
    return if x2 < 0

    avis = CDoom::Vissprite.new
    # store information in a vissprite
    vis = pointerof(avis)
    vis.value.mobjflags = 0
    vis.value.texturemid = (CDoom::BASEYCENTER << FRACBITS) + FRACUNIT // 2 - (psp.value.sy - CDoom.spritetopoffset[lump])
    vis.value.x1 = x1 < 0 ? 0 : x1
    vis.value.x2 = x2 >= CDoom.viewwidth ? CDoom.viewwidth - 1 : x2
    vis.value.scale = CDoom.pspritescale

    if flip != 0
      vis.value.xiscale = -CDoom.pspriteiscale
      vis.value.startfrac = CDoom.spritewidth[lump] - 1
    else
      vis.value.xiscale = CDoom.pspriteiscale
      vis.value.startfrac = 0
    end

    if vis.value.x1 > x1
      vis.value.startfrac = vis.value.startfrac + vis.value.xiscale * (vis.value.x1 - x1)
    end
    vis.value.patch = lump

    # get light level
    if CDoom.viewplayer.value.powers[CDoom::Powertype::Invisibility.value] > 4 * 32 ||
       CDoom.viewplayer.value.powers[CDoom::Powertype::Invisibility.value] & 8 != 0
      # shadow draw
      vis.value.colormap = Pointer(CDoom::Lighttable).null
    elsif !CDoom.fixedcolormap.null?
      # fixed map
      vis.value.colormap = CDoom.fixedcolormap
    elsif psp.value.state.value.frame & CDoom::FF_FULLBRIGHT != 0
      # full bright
      vis.value.colormap = CDoom.colormaps
    else
      # local light
      vis.value.colormap = CDoom.spritelights[CDoom::MAXLIGHTSCALE - 1]
    end

    CDoom.r_draw_vis_sprite(vis, vis.value.x1, vis.value.x2)
  end

  def self.r_draw_player_sprites
    # get light level
    lightnum =
      (CDoom.viewplayer.value.mo.value.subsector.value.sector.value.lightlevel >> CDoom::LIGHTSEGSHIFT) +
        CDoom.extralight

    if lightnum < 0
      CDoom.spritelights = CDoom.scalelight[0]
    elsif lightnum >= CDoom::LIGHTLEVELS
      CDoom.spritelights = CDoom.scalelight[CDoom::LIGHTLEVELS - 1]
    else
      CDoom.spritelights = CDoom.scalelight[lightnum]
    end

    # clip to screen bounds
    CDoom.mfloorclip = CDoom.screenheightarray
    CDoom.mceilingclip = CDoom.negonearray

    # add all active psprites
    psp = CDoom.viewplayer.value.psprites.to_unsafe
    CDoom::Psprnum::NUMPSPRITES.value.times do |i|
      CDoom.r_draw_psprite(psp) unless psp.value.state.null?
      psp += 1
    end
  end

  def self.r_sort_vis_sprites
    count = CDoom.vissprite_p - CDoom.vissprites.to_unsafe

    unsorted = CDoom::Vissprite.new
    unsorted.next = pointerof(unsorted)
    unsorted.prev = unsorted.next

    return if count == 0

    ds = CDoom.vissprites.to_unsafe
    while ds < CDoom.vissprite_p
      ds.value.next = ds + 1
      ds.value.prev = ds - 1
      ds += 1
    end

    CDoom.vissprites.to_unsafe.value.prev = pointerof(unsorted)
    unsorted.next = CDoom.vissprites.to_unsafe
    (CDoom.vissprite_p - 1).value.next = pointerof(unsorted)
    unsorted.prev = CDoom.vissprite_p - 1

    # pull the vissprites out by scale
    CDoom.vsprsortedhead.next = pointerof(CDoom.vsprsortedhead)
    CDoom.vsprsortedhead.prev = CDoom.vsprsortedhead.next
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
      best.value.next = pointerof(CDoom.vsprsortedhead)
      best.value.prev = CDoom.vsprsortedhead.prev
      CDoom.vsprsortedhead.prev.value.next = best
      CDoom.vsprsortedhead.prev = best
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
    ds = CDoom.ds_p - 1
    while ds >= CDoom.drawsegs.to_unsafe
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

      silhouette &= ~CDoom::SIL_BOTTOM if spr.value.gz >= ds.value.bsilheight

      silhouette &= ~CDoom::SIL_TOP if spr.value.gzt <= ds.value.tsilheight

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
      clipbot[x] = CDoom.viewheight.to_i16! if clipbot[x] == -2
      cliptop[x] = -1 if cliptop[x] == -2
      x += 1
    end

    CDoom.mfloorclip = clipbot
    CDoom.mceilingclip = cliptop
    CDoom.r_draw_vis_sprite(spr, spr.value.x1, spr.value.x2)
  end

  def self.r_draw_masked
    CDoom.r_sort_vis_sprites

    if CDoom.vissprite_p > CDoom.vissprites.to_unsafe
      # draw all vissprites back to front
      spr = CDoom.vsprsortedhead.next
      while spr != pointerof(CDoom.vsprsortedhead)
        CDoom.r_draw_sprite(spr)
        spr = spr.value.next
      end
    end

    # render any remaining masked mid textures
    ds = CDoom.ds_p - 1
    while ds >= CDoom.drawsegs.to_unsafe
      unless ds.value.maskedtexturecol.null?
        CDoom.r_render_masked_seg_range(ds, ds.value.x1, ds.value.x2)
      end
      ds -= 1
    end

    # draw the psprites on top of everything
    #  but does not draw on side views
    CDoom.r_draw_player_sprites if CDoom.viewangleoffset == 0
  end
end
