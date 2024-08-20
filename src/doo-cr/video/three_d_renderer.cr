module Doocr::Video
  class ThreeDRenderer
    class_getter max_screen_size : Int32 = 9

    @colormap : ColorMap | Nil
    @textures : ITextureLookup | Nil
    @flats : IFlatLookup | Nil
    @sprites : ISpriteLookup | Nil

    @screen : DrawScreen | Nil
    @screen_width : Int32 = 0
    @screen_height : Int32 = 0
    @screen_data : Bytes = Bytes.new(0)
    @draw_scale : Int32 = 0

    @window_size : Int32 = 0

    @frame_frac : Fixed | Nil

    def initialize(content : GameContent, @screen : DrawScreen, @window_size : Int32)
      @colormap = content.colormap
      @textures = content.textures
      @flats = content.flats
      @sprites = content.sprites

      @screen_width = @screen.width
      @screen_height = @screen.height
      @screen_data = @screen.data
      @draw_scale = @screen_width / 320

      init_wall_rendering()
      init_plane_rendering()
      init_sky_rendering()
      init_lighting()
      init_rendering_history()
      init_sprite_rendering()
      init_weapon_rendering()
      init_fuzz_effect()
      init_color_translation()
      init_window_border(content.wad)

      set_window_size(@window_size)
    end

    private def set_window_size(size : Int32)
      scale = @screen_width / 320
      if size < 7
        width = scale * (96 + 32 * size)
        height = scale * (48 + 16 * size)
        x = (@screen_width - width) / 2
        y = (@screen_height - StatusBarRenderer.height * scale - height) / 2
        reset_window(x, y, width, height)
      elsif size == 7
        width = @screen_width
        height = @screen_height - StatusBarRenderer.height * scale
        reset_window(0, 0, width, height)
      else
        width = @screen_height
        height = @screen_height
        reset_window(0, 0, width, height)
      end

      reset_wall_rendering()
      reset_plane_rendering()
      reset_sky_rendering()
      reset_lighting()
      reset_rendering_history()
      reset_weapon_rendering()
    end

    #
    # Window settings
    #

    @window_x : Int32 = 0
    @window_y : Int32 = 0
    @window_width : Int32 = 0
    @window_height : Int32 = 0
    @center_x : Int32 = 0
    @center_y : Int32 = 0
    @center_x_frac : Fixed | Nil
    @center_y_frac : Fixed | Nil
    @projection : Fixed | Nil

    private def reset_window(x : Int32, y : Int32, width : Int32, height : Int32)
      @window_x = x
      @window_y = y
      @window_width = width
      @window_height = height
      @center_x = @window_width / 2
      @center_y = @window_height / 2
      @center_x_frac = Fixed.from_i(@center_x)
      @center_y_frac = Fixed.from_i(@center_y)
      @projection = @center_x_frac
    end

    #
    # Wall rendering
    #

    FINE_FOV = 2048

    @angle_to_x : Array(Int32) = Array(Int32).new
    @x_to_angle : Array(Angle) = Array(Angle).new
    @clip_angle : Angle | Nil
    @clip_angle2 : Angle | Nil

    private def init_wall_rendering
      @angle_to_x = Array(Int).new(Trig::FINE_ANGLE_COUNT / 2)
      @x_to_angle = Array(Angle).new(@screen_width)
    end

    private def reset_wall_rendering
      focal_length = @center_x_frac / Tric.tan(Trig::FINE_ANGLE_COUNT / 4 + FINE_FOV / 2)

      (Trig::FINE_ANGLE_COUNT / 2).times do |i|
        t : Int32

        if Trig.tan(i) > Fixed.from_i(2)
          t = -1
        elsif Trig.tan(i) < Fixed.from_i(-2)
          t = @window_width + 1
        else
          t = (@center_x_frac - Trig.tan(i) * focal_length).to_int_ceiling

          if t < -1
            t = -1
          elsif t > @window_width + 1
            t = @window_height + 1
          end

          @angle_to_x.clear
          @angle_to_x << t
        end
      end

      @x_to_angle.clear
      @window_width.times do |x|
        i = 0
        while @angle_to_x[i]? && @angle_to_x[i] > x
          i += 1
        end
        @x_to_angle << Angle.new((i << Trig::ANGLE_TO_FINE_SHIFT).to_u32) - Angle.ang90
      end

      (Trig::FINE_ANGLE_COUNT / 2).times do |i|
        if @angle_to_x[i] == -1
          @angle_to_x[i] = 0
        elsif @angle_to_x[i] == @window_width + 1
          @angle_to_x[i] = @window_width
        end
      end

      @clip_angle = @x_to_angle[0]
      @clip_angle2 = Angle.new(2 * @clip_angle.data)
    end

    #
    # Plane rendering
    #

    @plane_y_slope : Array(Fixed) = Array(Fixed).new
    @plane_dist_scale : Array(Fixed) = Array(Fixed).new
    @plane_base_x_scale : Fixed | Nil
    @plane_base_y_scale : Fixed | Nil

    @ceiling_prev_sector : Sector | Nil
    @ceiling_prev_x : Int32 = 0
    @ceiling_prev_y1 : Int32 = 0
    @ceiling_prev_y2 : Int32 = 0
    @ceiling_x_frac : Array(Fixed) = Array(Fixed).new
    @ceiling_y_frac : Array(Fixed) = Array(Fixed).new
    @ceiling_x_step : Array(Fixed) = Array(Fixed).new
    @ceiling_y_step : Array(Fixed) = Array(Fixed).new
    @ceiling_lights : Array(Array(UInt8)) = Array(Array(UInt8)).new

    @floor_prev_sector : Sector | Nil
    @floor_prev_x : Int32 = 0
    @floor_prev_y1 : Int32 = 0
    @floor_prev_y2 : Int32 = 0
    @floor_x_frac : Array(Fixed) = Array(Fixed).new
    @floor_y_frac : Array(Fixed) = Array(Fixed).new
    @floor_x_step : Array(Fixed) = Array(Fixed).new
    @floor_y_step : Array(Fixed) = Array(Fixed).new
    @floor_lights : Array(Array(UInt8)) = Array(Array(UInt8)).new

    private def init_plane_rendering
      @plane_y_slope = Array(Fixed).new(@screen_height)
      @plane_dist_scale = Array(Fixed).new(@screen_height)
      @ceiling_x_frac = Array(Fixed).new(@screen_height)
      @ceiling_y_frac = Array(Fixed).new(@screen_height)
      @ceiling_x_step = Array(Fixed).new(@screen_height)
      @ceiling_y_step = Array(Fixed).new(@screen_height)
      @ceiling_lights = Array(Array(UInt32)).new(@screen_height)
      @floor_x_frac = Array(Fixed).new(@screen_height)
      @floor_y_frac = Array(Fixed).new(@screen_height)
      @floor_x_step = Array(Fixed).new(@screen_height)
      @floor_y_step = Array(Fixed).new(@screen_height)
      @floor_lights = Array(Array(UInt32)).new(@screen_height)
    end

    private def reset_plane_rendering
      @plane_y_slope.clear
      @window_height.times do |i|
        dy = Fixed.from_i(i - @window_height / 2) + Fixed.one / 2
        dy = dy.abs
        @plane_y_slope << Fixed.from_i(@window_width / 2) / dy
      end

      @plane_dist_scale.clear
      @window_height.times do |i|
        cos = Trig.cos(@x_to_angle[i]).abs
        @plane_dist_scale << Fixed.one / cos
      end
    end

    private def clear_plane_rendering
      angle = @view_angle - Angle.ang90
      @plane_base_x_scale = Trig.cos(angle) / @center_x_frac
      @plane_base_y_scale = -(Trig.sin(angle) / @center_x_frac)

      @ceiling_prev_sector = nil
      @ceiling_prev_x = Int32::MAX

      @floor_prev_sector = nil
      @floor_prev_x = Int32::MAX
    end

    #
    # Sky rendering
    #

    ANGLE_TO_SKY_SHIFT = 22
    @sky_texture_alt : Fixed | Nil
    @sky_inv_scale : Fixed | Nil

    private def init_sky_rendering
      @sky_texture_alt = Fixed.from_i(100)
    end

    private def reset_sky_rendering
      # The code below is based on PrBoom+' sky rendering implementation.
      num = Fixed::FRAC_UNIT.to_f64 * @screen_width * 200
      den = @window_width * @screen_height
      @sky_inv_scale = Fixed.new((num / den).to_i32)
    end

    #
    # Lighting
    #

    LIGHT_LEVEL_COUNT = 16
    LIGHT_SEG_SHIFT   =  4
    SCALE_LIGHT_SHIFT = 12
    Z_LIGHT_SHIFT     = 20
    COLORMAP_COUNT    = 32

    @max_scale_light : Int32 = 0
    MAX_Z_LIGHT = 128

    @diminishing_scale_light : Array(Array(Array(UInt32))) = Array(Array(Array(UInt32))).new
    @diminishing_z_light : Array(Array(Array(UInt32))) = Array(Array(Array(UInt32))).new
    @fixed_light : Array(Array(Array(UInt32))) = Array(Array(Array(UInt32))).new

    @scale_light : Array(Array(Array(UInt32))) = Array(Array(Array(UInt32))).new
    @z_light : Array(Array(Array(UInt32))) = Array(Array(Array(UInt32))).new

    @extra_light : Int32 = 0
    @fixed_colormap : Int32 = 0

    private def init_lighting
      @max_scale_light = 48 * (@screen_width / 320)

      @diminishing_scale_light = Array(Array(Array(UInt32))).new(LIGHT_LEVEL_COUNT)
      @diminishing_z_light = Array(Array(Array(UInt32))).new(LIGHT_LEVEL_COUNT)
      @fixed_light = Array(Array(Array(UInt32))).new(LIGHT_LEVEL_COUNT)

      LIGHT_LEVEL_COUNT.times do |i|
        @diminishing_scale_light << Array(Array(UInt32)).new(@max_scale_light)
        @diminishing_z_light << Array(Array(UInt32)).new(MAX_Z_LIGHT)
        @fixed_light << Array(Array(Uint32)).new(Math.max(@max_scale_light, MAX_Z_LIGHT))
      end

      distmap = 2

      # Calculate the light levels to use for each level / distance combination.
      LIGHT_LEVEL_COUNT.times do |i|
        start = (LIGHT_LEVEL_COUNT - 1 - i) * 2 * COLORMAP_COUNT / LIGHT_LEVEL_COUNT
        arrayj = [] of Array(UInt32)
        MAX_Z_LIGHT.times do |j|
          scale = Fixed.from_i(320 / 2) / Fixed.new((j + 1) << Z_LIGHT_SHIFT)
          scale = Fixed.new(scale.data >> SCALE_LIGHT_SHIFT)

          level = start - scale.data / distmap
          level = 0 if level < 0
          level = COLORMAP_COUNT - 1 if level >= COLORMAP_COUNT

          arrayj << @colormap[level]
        end
        @diminishing_z_light << arrayj
      end
    end

    private def reset_lighting
      distmap = 2

      # Calculate the light levels to use for each level / scale combination.
      LIGHT_LEVEL_COUNT.times do |i|
        start = (LIGHT_LEVEL_COUNT - 1 - i) * 2 * COLORMAP_COUNT / LIGHT_LEVEL_COUNT
        arrayj = [] of Array(UInt32)
        @max_scale_light.times do |j|
          level = start - j * 320 / @window_width / distmap
          level = 0 if level < 0
          level = COLORMAP_COUNT - 1 if level >= COLORMAP_COUNT
          arrayj << @colormap[level]
        end
        @diminishing_scale_light << arrayj
      end
    end

    private def clear_lighting
      if @fixed_colormap == 0
        @scale_light = @diminishing_scale_light
        @z_light = @diminishing_z_light
        @fixed_light[0][0] = nil
      elsif @fixed_light[0][0] != @colormap[@fixed_colormap]
        LIGHT_LEVEL_COUNT.times do |i|
          arrayj = [] of Array(UInt32)
          @fixed_light[i].size.times do |j|
            arrayj << @colormap[@fixed_colormap]
          end
          @fixed_light << arrayj
        end
        @scale_light = @fixed_light
        @z_light = @fixed_light
      end
    end

    #
    # Rendering history
    #

    @upper_clip : Array(Int16) = Array(Int16).new
    @lower_clip : Array(Int16) = Array(Int16).new

    @neg_one_array : Int32 = 0
    @window_height_array : Int32 = 0
    @clip_range_count : Int32 = 0
    @clip_ranges : Array(ClipRange) = Array(ClipRange).new

    @clip_data_length : Int32 = 0
    @clip_data : Array(Int16) = Array(Int16).new

    @vis_wall_range_count : Int32 = 0
    @vis_wall_ranges : Array(VisWallRange) = Array(VisWallRange).new

    private def init_rendering_history
      @upper_clip = Array(Short).new(@screen_width)
      @lower_clip = Array(Short).new(@screen_width)

      @clip_ranges = Array(ClipRange).new(256)
      256.times do |i|
        @clip_ranges << ClipRange.new
      end

      @clip_data = Array(Int16).new(128 * @screen_width)

      @vis_wall_ranges = Array(VisWallRange).new(512)
      512.times do |i|
        @vis_wall_ranges << VisWallRange.new
      end
    end

    private def reset_rendering_history
      @window_width.times do |i|
        @clip_data[i] = -1
      end
      @neg_one_array = 0

      i = @window_width
      while i < 2 * @window_width
        @clip_data[i] = @window_height.to_i16
        i += 1
      end
      @window_height_array = @window_width
    end

    private def clear_rendering_history
      @window_width.times do |x|
        @upper_clip[x] = -1
        @lower_clip[x] = @window_height.to_i16
      end

      @clip_ranges[0].first = -0x7fffffff
      @clip_ranges[0].last = -1
      @clip_ranges[1].first = @window_width
      @clip_ranges[1].last = 0x7fffffff
      @clip_range_count = 2

      @clip_data_length = 2 * @window_width

      @vis_wall_range_count = 0
    end

    #
    # Sprite rendering
    #

    @@min_z : Fixed = Fixed.from_i(4)

    @vis_sprite_count : Int32 = 0
    @vis_sprites : Array(VisSprite) = Array(VisSprite).new

    private def init_sprite_rendering
      @vis_sprites = Array(VisSprite).new(256)
      256.times do |i|
        @vis_sprites << VisSprite.new
      end
    end

    private def clear_sprite_rendering
      @vis_sprite_count = 0
    end

    #
    # Weapon rendering
    #

    @weapon_sprite : VisSprite | Nil
    @weapon_scale : Fixed | Nil
    @weapon_inv_scale : Fixed | Nil

    private def init_weapon_rendering
      @weapon_sprite = VisSprite()
    end

    private def reset_weapon_rendering
      @weapon_scale = Fixed.new(Fixed::FRAC_UNIT * @window_width / 320)
      @weapon_inv_scale = Fixed.new(Fixed::FRAC_UNIT * 320 / @window_width)
    end

    #
    # Fuzz effect
    #

    @@fuzz_table : Array(Int8) = [
      1, -1, 1, -1, 1, 1, -1,
      1, 1, -1, 1, 1, 1, -1,
      1, 1, 1, -1, -1, -1, -1,
      1, -1, -1, 1, 1, 1, 1, -1,
      1, -1, 1, 1, -1, -1, 1,
      1, -1, -1, -1, -1, 1, 1,
      1, 1, -1, 1, 1, -1, 1,
    ]

    @fuzz_pos : Int32 = 0

    private def init_fuzz_effect
      @fuzz_pos = 0
    end

    #
    # Color translation
    #

    @green_to_gray : Array(UInt8) = Array(UInt8).new
    @green_to_brown : Array(UInt8) = Array(UInt8).new
    @green_to_red : Array(UInt8) = Array(UInt8).new

    private def init_color_translation
      @green_to_gray = Array(UInt8).new(256, 0_u8)
      @green_to_brown = Array(UInt8).new(256, 0_u8)
      @green_to_red = Array(UInt8).new(256, 0_u8)
      256.times do |i|
        @green_to_gray << i.to_u8
        @green_to_brown << i.to_u8
        @green_to_red << i.to_u8
      end

      i = 112
      while i < 128
        @green_to_gray[i] -= 16
        @green_to_brown[i] -= 48
        @green_to_red[i] -= 80
        i += 1
      end
    end

    #
    # Window border
    #

    @border_top_left : Patch | Nil
    @border_top_right : Patch | Nil
    @border_bottom_left : Patch | Nil
    @border_bottom_right : Patch | Nil
    @border_top : Patch | Nil
    @border_bottom : Patch | Nil
    @border_left : Patch | Nil
    @border_right : Patch | Nil
    @back_flat : Flat | Nil

    private def init_window_border(wad : Wad)
      @border_top_left = Patch.from_wad(wad, "BRDR_TL")
      @border_top_right = Patch.from_wad(wad, "BRDR_TR")
      @border_bottom_left = Patch.from_wad(wad, "BRDR_BL")
      @border_bottom_right = Patch.from_wad(wad, "BRDR_BR")
      @border_top = Patch.from_wad(wad, "BRDR_T")
      @border_bottom = Patch.from_wad(wad, "BRDR_B")
      @border_left = Patch.from_wad(wad, "BRDR_L")
      @border_right = Patch.from_wad(wad, "BRDR_R")

      if wad.gamemode == GameMode::Commercial
        @back_flat = @flats["GRNROCK"]
      else
        @back_flat = @flats["FLOOR7_2"]
      end
    end

    private def fill_back_screen
      fill_height = @screen_height - @draw_scale * StatusBarRenderer.height
      fill_rect(0, 0, @window_x, fill_height)
      fill_rect(@screen_width - @window_x, 0, @window_x, fill_height)
      fill_rect(@window_x, 0, @screen_width - 2 * @window_x, @window_y)
      fill_rect(@window_x, fill_height - @window_y, @screen_width - 2 * @window_x, @window_y)

      step = 8 * @draw_scale

      x = @window_x
      while x < @screen_width - @window_x
        @screen.draw_patch(@border_top, x, @window_y - step, @draw_scale)
        @screen.draw_patch(@border_bottom, x, fill_height - @window_y, @draw_scale)
        x += step
      end

      y = @window_y
      while y < fill_height - @window_y
        @screen.draw_patch(@border_left, @window_x - step, y, @draw_scale)
        @screen.draw_patch(@border_right, @screen_width - @window_x, y, @draw_scale)
        y += step
      end

      @screen.draw_patch(@border_top_left, @window_x - step, @window_y - step, @draw_scale)
      @screen.draw_patch(@border_top_right, @screen_width - @window_x, @window_y - step, @draw_scale)
      @screen.draw_patch(@border_bottom_left, @window_x - step, fill_height - @window_y, @draw_scale)
      @screen.draw_patch(@border_bottom_right, @screen_width - @window_x, fill_height - @window_y, @draw_scale)
    end

    private def fill_rect(x : Int32, y : Int32, width : Int32, height : Int32)
      data = @back_flat.data

      src_x = x / @draw_scale
      src_y = y / @draw_scale

      inv_scale = Fixed.one / @draw_scale
      x_frac = inv_scale - Fixed.epsilon

      width.times do |i|
        src = ((src_x + x_frac.to_int_floor) & 63) << 6
        dst = @screen_height * (x + i) + y
        y_frac = inv_scale - Fixed.epsilon
        height.times do |j|
          @screen_data[dst + j] = data[src | ((src_y + y_frac.to_int_floor) & 63)]
          y_frac += inv_scale
        end
        x_frac += inv_scale
      end
    end

    #
    # Camera view
    #

    @world : World | Nil

    @view_x : Fixed | Nil
    @view_y : Fixed | Nil
    @view_z : Fixed | Nil
    @view_angle : Fixed | Nil

    @view_sin : Fixed | Nil
    @view_cos : Fixed | Nil

    @valid_count : Int32 = 0

    def render(player : Player, frame_frac : Fixed)
      @frame_frac = frame_frac

      @world = player.mobj.world

      @view_x = player.mobj.get_interpolated_x(frame_frac)
      @view_y = player.mobj.get_interpolated_y(frame_frac)
      @view_z = player.get_interpolated_view_z(frame_frac)
      @view_angle = player.get_interpolated_angle(frame_frac)

      @view_sin = Trig.sin(@view_angle)
      @view_cos = Trig.cos(@view_angle)

      @valid_count = world.get_new_valid_count

      @extra_light = player.extra_light
      @fixed_colormap = player.fixed_colormap

      clear_plane_rendering()
      clear_lighting()
      clear_rendering_history()
      clear_sprite_rendering()

      render_bsp_node(@world.map.nodes.size - 1)
      render_sprites()
      render_masked_textures()
      draw_player_sprites(player)

      if @window_size < 7
        fill_back_screen()
      end
    end

    private def render_bsp_node(node : Int32)
      if Node.is_subsector(node)
        if node == -1
          draw_subsector(0)
        else
          draw_subsector(Node.get_subsector(node))
        end
        return
      end

      bsp = @world.map.nodes[node]

      # Decide which side the view point is on.
      side = Geometry.point_on_side(@view_x, @view_y, bsp)

      # Recursively divide front space.
      render_bsp_node(bsp.children[side])

      # Possibly divide back space.
      if is_potentially_visible(bsp.bounding_box[side ^ 1])
        render_bsp_node(bsp.children[side ^ 1])
      end
    end

    private def draw_subsector(subsector : Int32)
      target = @world.map.subsectors[subsector]

      add_sprites(target.sector, @valid_count)

      target.seg_count.times do |i|
        draw_seg(@world.map.segs[target.first_seg + i])
      end
    end

    @@view_pos_to_frustum_tangent : Array(Array(Int32)) = [
      [3, 0, 2, 1],
      [3, 0, 2, 0],
      [3, 1, 2, 0],
      [0],
      [2, 0, 2, 1],
      [0, 0, 0, 0],
      [3, 1, 3, 0],
      [0],
      [2, 0, 3, 1],
      [2, 1, 3, 1],
      [2, 1, 3, 0],
    ]

    private def is_potentially_visible(bbox : Array(Fixed)) : Bool
      bx : Int32
      by : Int32

      # Find the corners of the box that define the edges from
      # current viewpoint.
      if @view_x <= bbox[Box::LEFT]
        bx = 0
      elsif @view_x < bbox[Box::RIGHT]
        bx = 1
      else
        bx = 2
      end

      if @view_y >= bbox[Box::TOP]
        by = 0
      elsif @view_y > bbox[Box::BOTTOM]
        by = 1
      else
        by = 2
      end

      view_pos = (by << 2) + bx
      return if view_pos == 5

      x1 = bbox[@@view_pos_to_frustum_tangent[view_pos][0]]
      y1 = bbox[@@view_pos_to_frustum_tangent[view_pos][1]]
      x2 = bbox[@@view_pos_to_frustum_tangent[view_pos][2]]
      y2 = bbox[@@view_pos_to_frustum_tangent[view_pos][3]]

      # Check clip list for an open space.
      angle1 = Geometry.point_to_angle(@view_x, @view_y, x1, y1) - @view_angle
      angle2 = Geometry.point_to_angle(@view_x, @view_y, x2, y2) - @view_angle

      span = angle1 - angle2

      # Sitting on a line?
      return true if span >= Angle.ang180

      t_span1 = angle1 + @clip_angle

      if t_span1 > @clip_angle2
        t_span1 -= @clip_angle2

        # Totally off the left edge?
        return false if t_span1 >= span

        angle1 = @clip_angle
      end

      t_span2 = @clip_angle - angle2
      if t_span2 > @clip_angle2
        t_span2 -= @clip_angle2

        # Totally off the left edge?
        return false if t_span2 >= span

        angle2 = -@clip_angle
      end

      # Find the first clippost that touches the source post
      # (adjacent pixels are touching).
      sx1 = @angle_to_x[(angle1 + Angle.ang90).data >> Trig::ANGLE_TO_FINE_SHIFT]
      sx2 = @angle_to_x[(angle2 + Angle.ang90).data >> Trig::ANGLE_TO_FINE_SHIFT]

      # Does not cross a pixel.
      return false if sx1 == sx2

      sx2 -= 1

      start = 0
      while @clip_ranges[start].last < sx2
        start += 1
      end

      if sx1 >= @clip_ranges[start].first && sx2 <= @clip_ranges[start].last
        # The clippost contains the new span.
        return false
      end

      return true
    end

    private def draw_seg(seg : Seg)
      # OPTIMIZE: quickly reject orthogonal back sides.
      angle1 = Geometry.point_to_angle(@view_x, @view_y, seg.vertex1.x, seg.vertex1.y)
      angle2 = Geometry.point_to_angle(@view_x, @view_y, seg.vertex2.x, seg.vertex2.y)

      # Clip to view edges.
      # OPTIMIZE: make constant out of 2 * clipangle (FIELDOFVIEW).
      span = angle1 - angle2

      # Back side? I.e. backface culling?
      return if span >= Angle.ang180

      # Global angle needed by segcalc.
      rw_angle1 = angle1

      angle1 -= @view_angle
      angle2 -= @view_angle

      t_span1 = angle1 + @clip_angle
      if t_span1 > @clip_angle2
        t_span1 -= @clip_angle2

        # Totally off the left edge?
        return if t_span1 >= span

        angle1 = @clip_angle
      end

      t_span2 = @clip_angle - angle2
      if t_span2 > @clip_angle2
        t_span2 -= @clip_angle2

        # Totally off the left edge?
        return if t_span2 >= span

        angle2 = -@clip_angle
      end

      # The seg is in the view range, but not necessarily visible.
      x1 = @angle_to_x[(angle1 + Angle.ang90).data >> Trig::ANGLE_TO_FINE_SHIFT]
      x2 = @angle_to_x[(angle2 + Angle.ang90).data >> Trig::ANGLE_TO_FINE_SHIFT]

      # Does not cross a pixel?
      return if x1 == x2

      front_sector = seg.front_sector
      back_sector = seg.back_sector

      front_sector_floor_height = front_sector.get_interpolated_floor_height(@frame_frac)
      front_sector_ceiling_height = front_sector.get_interpolated_ceiling_height(@frame_frac)

      # Single sided line?
      if back_sector == nil
        draw_solid_wall(seg, rw_angle1)
        return
      end

      back_sector_floor_height = back_sector.get_interpolated_floor_height(@frame_frac)
      back_sector_ceiling_height = back_sector.get_interpolated_ceiling_height(@frame_frac)

      # Closed door.
      if (back_sector_ceiling_height <= front_sector_floor_height ||
         back_sector_floor_height >= front_sector_ceiling_height)
        draw_solid_wall(seg, rw_angle1, x1, x2 - 1)
        return
      end

      # Window.
      if (back_sector_ceiling_height != front_sector_ceiling_height ||
         back_sector_floor_height != front_sector_floor_height)
        draw_pass_wall(seg, rw_angle1, x1, x2 - 1)
        return
      end

      # Reject empty lines used for triggers and special events.
      # Identical floor and ceiling on both sides, identical
      # light levels on both sides, and no middle texture.
      if (back_sector.ceiling_flat == front_sector.ceiling_flat &&
         back_sector.floor_flat == front_sector.floor_flat &&
         back_sector.light_level == front_sector.light_level &&
         seg.side_def.middle_texture == 0)
        return
      end

      draw_pass_wall(seg, rw_angle1, x1, x2 - 1)
    end

    private def draw_solid_wall(seg : Seg, rw_angle1 : Angle, x1 : Int32, x2 : Int32)
      nexti : Int32
      start : Int32

      # Find the first range that touches the range
      # (adjacent pixels are touching).
      start = 0
      while @clip_ranges[start].last < x1 - 1
        start += 1
      end

      if x1 < @clip_ranges[start].first
        if x2 < @clip_ranges[start].first - 1
          # Post is entirely visible (above start),
          # so insert a new clippost.
          draw_solid_wall_range(seg, rw_angle1, x1, x2)
          nexti = @clip_range_count
          @clip_range_count += 1

          while nexti != start
            @clip_ranges[nexti].copy_from(@clip_ranges[nexti - 1])
            nexti -= 1
          end
          @clip_ranges[nexti].first = x1
          @clip_ranges[nexti].last = x2
          return
        end

        # There is a fragment above *start.
        draw_solid_wall_range(seg, rw_angle1, x1, @clip_ranges[start].first - 1)

        # Now adjust the clip size.
        @clip_ranges[start].first = x1
      end

      # Bottom contained in start?
      return if x2 <= @clip_ranges[start].last

      nexti = start
      x = true
      while x2 >= @clip_ranges[nexti + 1].first - 1
        # There is a fragment between two posts.
        draw_solid_wall_range(seg, rw_angle1, @clip_ranges[nexti].last + 1, @clip_ranges[nexti + 1].first - 1)
        nexti += 1

        if x2 <= @clip_ranges[nexti].last
          # Bottom is contained in next.
          # Adjust the clip size.
          @clip_ranges[start].last = @clip_ranges[nexti].last
          x = false
        end
      end

      if x
        # There is a fragment after *next.
        draw_solid_wall_range(seg, rw_angle1, @clip_ranges[nexti].last + 1, x2)

        # Adjust the clip size.
        @clip_ranges[start].last = x2
      end

      # Remove start + 1 to next from the clip list,
      # because start now covers their area.
      if nexti == start
        # Post just extended past the bottom of one post.
        return
      end

      while nexti != @clip_range_count
        nexti += 1
        # Remove a post.
        start += 1
        @clip_ranges[start].copy_from(@clip_ranges[nexti])
      end

      @clip_range_count = start + 1
    end

    private def draw_pass_wall(seg : Seg, rw_angle1 : Angle, x1 : Int32, x2 : Int32)
      start : Int32

      # Find the first range that touches the range
      # (adjacent pixels are touching).
      start = 0
      while @clip_ranges[start].last < x1 - 1
        start += 1
      end

      if x1 < @clip_ranges[start].first
        if x2 < @clip_ranges[start].first - 1
          # Post is entirely visible (above start).
          draw_pass_wall_range(seg, rw_angle1, x1, x2, false)
          return
        end

        # There is a fragment above *start.
        draw_pass_wall_range(seg, rw_angle1, x1, @clip_ranges[start].first - 1, false)
      end

      # Bottom contained in start?
      return if x2 <= @clip_ranges[start].last

      while x2 >= @clip_ranges[start + 1].first - 1
        # There is a fragment between two posts.
        draw_pass_wall_range(seg, rw_angle1, @clip_ranges[start].last + 1, @clip_ranges[start + 1].first - 1, false)
        start += 1

        return if x2 <= @clip_ranges[start].last
      end

      # There is a fragment after *next.
      draw_pass_wall_range(seg, rw_angle1, @clip_ranges[start].last + 1, x2, false)
    end

    private def scale_from_global_angle(vis_angle : Angle, view_angle : Angle, rw_normal : Angle, rw_distance : Angle) : Fixed
      num = @projection * Trig.sin(Angle.ang90 + (vis_angle - rw_normal))
      den = rw_distance * Trig.sin(Angle.ang90 + (vis_angle - view_angle))

      scale : Fixed
      if den.data > num.data >> 16
        scale = num / den

        if scale > Fixed.from_i(64)
          scale = Fixed.from_i(64)
        elsif scale.data < 256
          scale = Fixed.new(256)
        end
      else
        scale = Fixed.from_i(64)
      end

      return scale
    end

    HEIGHT_BITS = 12
    HEIGHT_UNIT = 1 << HEIGHT_BITS

    private def draw_solid_wall_range(seg : Seg, rw_angle1 : Angle, x1 : Int32, x2 : Int32)
      if seg.back_sector != nil
        draw_pass_wall_range(seg, rw_angle1, x1, x2, true)
        return
      end

      if @vis_wall_range_count == @vis_wall_ranges.size
        # Too many visible walls.
        return
      end

      # Make some aliases to shorten the following code.
      line = seg.line_def
      side = seg.side_def
      front_sector = seg.front_sector

      front_sector_floor_height = front_sector.get_interpolated_floor_height(@frame_frac)
      front_sector_ceiling_height = front_sector.get_interpolated_ceiling_height(@frame_frac)

      # Mark the segment as visible for auto map.
      line.flags |= LineFlags::Mapped

      # Calculate the relative plane heights of front and back sector.
      world_front_z1 = front_sector_ceiling_height - @view_z
      world_front_z2 = front_sector_floor_height - @view_z

      # Check which parts must be rendered.
      draw_wall = side.middle_texture != 0
      draw_ceiling = world_front_z1 > Fixed.zero || front_sector.ceiling_flat == @flats.sky_flat_number
      draw_floor = world_front_z2 < Fixed.zero

      #
      # Determine how the wall textures are vertically aligned.
      #

      wall_texture = @textures[@world.specials.texture_translation[side.middle]]
      wall_width_mask = wall_texture.width - 1

      middle_texture_alt : Fixed
      if (line.flags & LineFlags::DontPegBottom).to_i32 != 0
        v_top = front_sector_floor_height + Fixed.from_i(wall_texture.height)
        middle_texture_alt = v_top - @view_z
      else
        middle_texture_alt = world_front_z1
      end
      middle_texture_alt += side.row_offset

      #
      # Calculate the scaling factors of the left and right edges of the wall range.
      #

      rw_normal_angle = seg.angle + Angle.ang90

      offset_angle = (rw_normal_angle - rw_angle1).abs
      if offset_angle > Angle.ang90
        offset_angle = Angle.ang90
      end

      dist_angle = Angle.ang90 - offset_angle

      hypotenuse = Geometry.point_to_dist(@view_x, @view_y, seg.vertex1.x, seg.vertex1.y)

      rw_distance = hypotenuse * Trig.sin(dist_angle)

      rw_scale = scale_from_global_angle(view_angle + @x_to_angle[x1], view_angle, rw_normal_angle, rw_distance)

      scale1 : Fixed = rw_scale
      scale2 : Fixed
      rw_scale_step : Fixed
      if x2 > x1
        scale2 = scale_from_global_angle(view_angle + @x_to_angle[x2], view_angle, rw_normal_angle, rw_distance)
        rw_scale_step = (scale2 - rw_scale) / (x2 - x1)
      else
        scale2 = scale1
        rw_scale_step = Fixed.zero
      end

      #
      # Determine how the wall textures are horizontally aligned
      # and which color map is used according to the light level (if necessary).
      #

      texture_offset_angle = rw_normal_angle - rw_angle1
      if texture_offset_angle > Angle.ang180
        texture_offset_angle = -texture_offset_angle
      end
      if texture_offset_angle > Angle.ang90
        texture_offset_angle = Angle.ang90
      end

      rw_offset = hypotenuse * Trig.sin(texture_offset_angle)
      if rw_normal_angle - rw_angle1 < Angle.ang180
        rw_offset = -rw_offset
      end
      rw_offset += seg.offset + side.texture_offset

      rw_center_angle = Angle.ang90 + view_angle - rw_normal_angle

      wall_light_level = (front_sector.light_level >> LIGHT_SEG_SHIFT) + @extra_light
      if seg.vertex1.y == seg.vertex2.y
        wall_light_level -= 1
      elsif seg.vertex1.x == seg.vertex2.x
        wall_light_level += 1
      end

      wall_lights = @scale_light[Math.clamp(wall_light_level, 0, LIGHT_LEVEL_COUNT - 1)]

      #
      # Determine where on the screen the wall is drawn.
      #

      # These values are right shifted to avoid overflow in the following process (maybe).
      world_front_z1 >>= 4
      world_front_z2 >>= 4

      # The Y positions of the top / bottom edges of the wall on the screen.
      wall_y1_frac = (@center_y_frac >> 4) - world_front_z1 * rw_scale
      wall_y1_step = -(rw_scale_step * world_front_z1)
      wall_y2_frac = (@center_y_frac >> 4) - world_front_z2 * rw_scale
      wall_y2_step = -(rw_scale_step * world_front_z2)

      #
      # Determine which color map is used for the plane according to the light level.
      #

      plane_light_level = (front_sector.light_level >> LIGHT_SEG_SHIFT) + @extra_light
      plane_lights = @z_light[Math.clamp(plane_light_level, 0, LIGHT_LEVEL_COUNT - 1)]

      #
      # Prepare to record the rendering history.
      #

      vis_wall_range = @vis_wall_ranges[@vis_wall_range_count]
      @vis_wall_range_count += 1

      vis_wall_range.seg = seg
      vis_wall_range.x1 = x1
      vis_wall_range.x2 = x2
      vis_wall_range.scale1 = scale1
      vis_wall_range.scale2 = scale2
      vis_wall_range.scale_step = rw_scale_step
      vis_wall_range.silhouette = Silhouette::Both
      vis_wall_range.lower_sil_height = Fixed.max_value
      vis_wall_range.upper_sil_height = Fixed.min_value
      vis_wall_range.masked_texture_column = -1
      vis_wall_range.upper_clip = @window_height_array
      vis_wall_range.lower_clip = @neg_one_array
      vis_wall_range.front_sector_floor_height = front_sector_floor_height
      vis_wall_range.front_sector_ceiling_height = front_sector_ceiling_height

      #
      # Floor and ceiling.
      #

      ceiling_flat = @flats[@world.specials.flat_translation[front_sector.ceiling_flat]]
      floor_flat = @flats[@world.specials.flat_translation[front_sector.floor_flat]]

      #
      # Now the rendering is carried out.
      #

      x = x1
      while x <= x2
        draw_wall_y1 = (wall_y1_frac.data + HEIGHT_UNIT - 1) >> HEIGHT_BITS
        draw_wall_y2 = wall_y2_frac.data >> HEIGHT_BITS

        if draw_ceiling
          cy1 = upper_clip[x] + 1
          cy2 = Math.min(draw_wall_y1 - 1, lower_clip[x] - 1)
          draw_ceiling_column(front_sector, ceiling_flat, plane_lights, x, cy1, cy2, front_sector_ceiling_height)
        end

        if draw_wall
          wy1 = Math.max(draw_wall_y1, upper_clip[x] + 1)
          wy2 = Math.min(draw_wall_y2, lower_clip[x] - 1)

          angle = rw_center_angle + @x_to_angle[x]
          angle = Angle.new(angle.data & 0x7FFFFFFF)

          texture_column = (rw_offset - Trig.tan(angle) * rw_distance).to_int_floor
          source = wall_texture.composite.columns[texture_column & wall_width_mask]

          if source.size > 0
            light_index = rw_scale.data >> SCALE_LIGHT_SHIFT
            if light_index >= @max_scale_light
              light_index = @max_scale_light - 1
            end

            inv_scale = Fixed.new((0xffffffff_u32 / rw_scale.data.to_u32).to_i32)
            draw_column(source[0], wall_lights[light_index], x, wy1, wy2, inv_scale, middle_texture_alt)
          end
        end

        if draw_floor
          fy1 = Math.max(draw_wall_y2 + 1, upper_clip[x] + 1)
          fy2 = lower_clip[x] - 1
          draw_floor_column(front_sector, floor_flat, plane_lights, x, fy1, fy2, front_sector_floor_height)
        end

        rw_scale += rw_scale_step
        wall_y1_frac += wall_y1_step
        wall_y2_frac += wall_y2_step
        x += 1
      end
    end

    private def draw_pass_wall_range(seg : Seg, rw_angle1 : Angle, x1 : Int32, x2 : Int32, draw_as_solid_wall : Bool)
      if @vis_wall_range_count == @vis_wall_ranges.size
        # Too many visible walls
        return
      end

      range = x2 - x1 + 1

      if @clip_data_length + 3 * range >= @clip_data.size
        # Clip info buffer is not sufficient.
        return
      end

      # Make some aliases to shorten the following code.
      line = seg.line_def
      side = seg.side_def
      front_sector = seg.front_sector
      back_sector = seg.back_sector

      front_sector_floor_height = front_sector.get_interpolated_floor_height(@frame_frac)
      front_sector_ceiling_height = front_sector.get_interpolated_ceiling_height(@frame_frac)
      back_sector_floor_height = back_sector.get_interpolated_floor_height(@frame_frac)
      back_sector_ceiling_height = back_sector.get_interpolated_ceiling_height(@frame_frac)

      # Mark the segment as visible for auto map.
      line.flags |= LineFlags::Mapped

      # Calculate the relative plane heights of front and back sector.
      # These values are later 4 bits right shifted to calculate the rendering area.
      world_front_z1 = front_sector_ceiling_height - @view_z
      world_front_z2 = front_sector_floor_height - @view_z
      world_back_z1 = back_sector_ceiling_height - @view_z
      world_back_z2 = back_sector_floor_height - @view_z

      # The hack below enables ceiling height change in outdoor area without showing the upper wall.
      if (front_sector.ceiling_flat == @flats.sky_flat_number &&
         back_sector.ceiling_flat == @flats.sky_flat_number)
        world_front_z1 = world_back_z1
      end

      #
      # Check which parts must be rendered.
      #

      draw_upper_wall : Bool
      draw_ceiling : Bool
      if (draw_as_solid_wall ||
         world_front_z1 != world_back_z1 ||
         front_sector.ceiling_flat != back_sector.ceiling_flat ||
         front_sector.light_level != back_sector.light_level)
        draw_upper_wall = side.top_texture != 0 && world_back_z1 < world_front_z1
        draw_ceiling = world_front_z1 >= Fixed.zero || front_sector.ceiling_flat == @flats.sky_flat_number
      else
        draw_upper_wall = false
        draw_ceiling = false
      end

      draw_lower_wall : Bool
      draw_floor : Bool
      if (draw_as_solid_wall ||
         world_front_z2 != world_back_z2 ||
         front_sector.floor_flat != back_sector.floor_flat ||
         front_sector.light_level != back_sector.light_level)
        draw_lower_wall = side.bottom_texture != 0 && world_back_z2 > world_front_z2
        draw_floor = world_front_z2 <= Fixed.zero
      else
        draw_lower_wall = false
        draw_floor = false
      end

      draw_masked_texture = side.middle_texture != 0

      # If nothing must be rendered, we can skip this seg.
      return if !draw_upper_wall && !draw_ceiling && !draw_lower_wall && !draw_floor && !draw_masked_texture

      seg_textured = draw_upper_wall || draw_lower_wall || draw_masked_texture

      #
      # Determine how the wall textures are vertically aligned (if necessary).
      #

      upper_wall_texture : Texture
      upper_wall_width_mask : Int32
      upper_texture_alt : Fixed
      if draw_upper_wall
        upper_wall_texture = @textures[@world.specials.texture_translation[side.top_texture]]
        upper_wall_width_mask = upper_wall_texture.width - 1

        if (line.flags & LineFlags::DontPegTop).to_i32 != 0
          upper_texture_alt = world_front_z1
        else
          v_top = back_sector_ceiling_height + Fixed.from_i(upper_wall_texture.height)
          upper_texture_alt = v_top - @view_z
        end
        upper_texture_alt += side.row_offset
      end

      lower_wall_texture : Texture
      lower_wall_width_mask : Int32
      lower_texture_alt : Fixed
      if draw_lower_wall
        lower_wall_texture = @textures[@world.specials.texture_translation[side.bottom_texture]]
        lower_wall_width_mask = lower_wall_texture.width - 1

        if (line.flags & LineFlags::DontPegTop).to_i32 != 0
          lower_texture_alt = world_front_z1
        else
          lower_texture_alt = world_back_z2
        end
        lower_texture_alt += side.row_offset
      end

      #
      # Calculate the scaling factors of the left and right edges of the wall range.
      #
      rw_normal_angle = seg.angle + Angle.ang90

      offset_angle = (rw_normal_angle - rw_angle1).abs
      offset_angle = Angle.ang90 if offset_angle > Angle.ang90

      dist_angle = Angle.ang90 - offset_angle

      hypotenuse = Geometry.point_to_dist(@view_x, @view_y, seg.vertex1.x, seg.vertex1.y)

      rw_distance = hypotenuse * Tric.sin(dist_angle)

      rw_scale = scale_from_global_angle(view_angle + @x_to_angle[x1], view_angle, rw_normal_angle, rw_distance)

      scale1 : Fixed = rw_scale
      scale2 : Fixed
      rw_scale_step : Fixed
      if x2 > x1
        scale2 = scale_from_global_angle(view_angle + @x_to_angle[x2], view_angle, rw_normal_angle, rw_distance)
        rw_scale_step = (scale2 - rw_scale) / (x2 - x1)
      else
        scale2 = scale1
        rw_scale_step = Fixed.zero
      end

      #
      # Determine how the wall textures are horizontally aligned
      # and which color map is used according to the light level (if necessary).
      #

      rw_offset : Fixed
      rw_center_angle : Fixed
      wall_lights : Array(Array(UInt8))
      if seg_textured
        texture_offset_angle = rw_normal_angle - rw_angle1
        if texture_offset_angle > Angle.ang180
          texture_offset_angle = -texture_offset_angle
        end
        if texture_offset_angle > Angle.ang90
          texture_offset_angle = Angle.ang90
        end

        rw_offset = hypotenuse * Trig.sin(texture_offset_angle)
        if rw_normal_angle - rw_angle1 < Angle.ang180
          rw_offset = -rw_offset
        end
        rw_offset += seg.offset + side.texture_offset

        rw_center_angle = Angle.ang90 + view_angle - rw_normal_angle

        wall_light_level = (front_sector.light_level >> LIGHT_SEG_SHIFT) + @extra_light
        if seg.vertex1.y == seg.vertex2.y
          wall_light_level -= 1
        elsif seg.vertex1.x == seg.vertex2.x
          wall_light_level
        end

        wall_lights = @scale_light[Math.clamp(wall_light_level, 0, LIGHT_LEVEL_COUNT - 1)]
      end

      #
      # Determine where on the screen the wall is drawn.
      #

      # These values are right shifted to avoid overflow in the following process.
      world_front_z1 >>= 4
      world_front_z2 >>= 4
      world_back_z1 >>= 4
      world_back_z2 >>= 4

      # The Y positions of the top / bottom edges of the wall on the screen..
      wall_y1_frac = (@center_y_frac >> 4) - world_front_z1 * rw_scale
      wall_y1_step = -(rw_scale_step * world_front_z1)
      wall_y2_frac = (@center_y_frac >> 4) - world_front_z2 * rw_scale
      wall_y2_step = -(rw_scale_step * world_front_z2)

      # The Y position of the top edge of the portal (if visible).
      portal_y1_frac : Fixed
      portal_y1_step : Fixed
      if draw_upper_wall
        if world_back_z1 > world_front_z2
          portal_y1_frac = (@center_y_frac >> 4) - world_back_z1 * rw_scale
          portal_y1_step = -(rw_scale_step * world_back_z1)
        else
          portal_y1_frac = (@center_y_frac >> 4) - world_back_z2 * rw_scale
          portal_y1_step = -(rw_scale_step * world_back_z2)
        end
      end

      # The Y position of the bottom edge of the portal (if visible).
      portal_y2_frac : Fixed
      portal_y2_step : Fixed
      if draw_lower_wall
        if world_back_z2 < world_front_z1
          portal_y2_frac = (@center_y_frac >> 4) - world_back_z2 * rw_scale
          portal_y2_step = -(rw_scale_step * world_back_z2)
        else
          portal_y2_frac = (@center_y_frac >> 4) - world_back_z1 * rw_scale
          portal_y2_step = -(rw_scale_step * world_back_z1)
        end
      end

      #
      # Determine which color map is used for the plane according to the light level.
      #

      plane_light_level = (front_sector.light_level >> LIGHT_SEG_SHIFT) + @extra_light
      plane_lights = @z_light[Math.clamp(plane_light_level, 0, LIGHT_LEVEL_COUNT - 1)]

      #
      # Prepare to record the rendering history.
      #

      vis_wall_range = @vis_wall_ranges[@vis_wall_range_count]
      @vis_wall_range_count += 1

      vis_wall_range.seg = seg
      vis_wall_range.x1 = x1
      vis_wall_range.x2 = x2
      vis_wall_range.scale1 = scale1
      vis_wall_range.scale2 = scale2
      vis_wall_range.scale_step = rw_scale_step

      vis_wall_range.upper_clip = -1
      vis_wall_range.lower_clip = -1
      vis_wall_range.silhouette = 0

      if front_sector_floor_height > back_sector_floor_height
        vis_wall_range.silhouette = Silhouette::Lower
        vis_wall_range.lower_sil_height = front_sector_floor_height
      elsif back_sector_floor_height > @view_z
        vis_wall_range.silhouette = Silhouette::Lower
        vis_wall_range.lower_sil_height = Fixed.max_value
      end

      if front_sector_ceiling_height < back_sector_ceiling_height
        vis_wall_range.silhouette |= Silhouette::Upper
        vis_wall_range.upper_sil_height = front_sector_ceiling_height
      elsif back_sector_ceiling_height < @view_z
        vis_wall_range.silhouette | -Silhouette::Upper
        vis_wall_range.upper_sil_height = Fixed.min_value
      end

      if back_sector_ceiling_height <= front_sector_floor_height
        vis_wall_range.lower_clip = @neg_one_array
        vis_wall_range.lower_sil_height = Fixed.max_value
        vis_wall_range.silhouette |= Silhouette::Lower
      end

      if back_sector_floor_height >= front_sector_ceiling_height
        vis_wall_range.upper_clip = @window_height_array
        vis_wall_range.upper_sil_height = Fixed.min_value
        vis_wall_range.silhouette |= Silhouette::Upper
      end

      masked_texture_column : Int32
      if draw_masked_texture
        masked_texture_column = @clip_data_length - x1
        vis_wall_range.masked_texture_column = masked_texture_column
        @clip_data_length += range
      else
        vis_wall_range.masked_texture_column = -1
      end

      vis_wall_range.front_sector_floor_height = front_sector_floor_height
      vis_wall_range.front_sector_ceiling_height = front_sector_ceiling_height
      vis_wall_range.back_sector_floor_height = back_sector_floor_height
      vis_wall_range.back_sector_ceiling_height = back_sector_ceiling_height

      #
      # Floor and ceiling.
      #

      ceiling_flat = @flats[@world.specials.flat_translation[front_sector.ceiling_flat]]
      floor_flat = @flats[@world.specials.flat_translation[front_sector.floor_flat]]

      #
      # Now the rendering is carried out.
      #

      x = x1
      while x <= x2
        draw_wall_y1 = (wall_y1_frac.data + HEIGHT_UNIT - 1) >> HEIGHT_BITS
        draw_wall_y2 = wall_y2_frac.data >> HEIGHT_BITS

        texture_column : Int32
        light_index : Int32
        inv_scale : Fixed
        if seg_textured
          angle = rw_center_angle + @x_to_angle[x]
          angle = Angle.new(angle.data & 0x7FFFFFFF)
          texture_column = (rw_offset - Trig.tan(angle) * rw_distance).to_int_floor

          light_index = rw_scale.data >> SCALE_LIGHT_SHIFT
          if light_index >= @max_scale_light
            light_index = @max_scale_light - 1
          end

          inv_scale = Fixed.new((0xffffffff_u32 / rw_scale.data.to_u32).to_i32)
        end

        if draw_upper_wall
          draw_upper_wall_y1 = (wall_y1_frac.data + HEIGHT_UNIT - 1) >> HEIGHT_BITS
          draw_upper_wall_y2 = portal_y1_frac.data >> HEIGHT_BITS

          if draw_ceiling
            cy1 = upper_clip[x] + 1
            cy2 = Math.min(draw_wall_y1 - 1, lower_clip[x] - 1)
            draw_ceiling_column(front_sector, ceiling_flat, plane_lights, x, cy1, cy2, front_sector_ceiling_height)
          end

          wy1 = Math.max(draw_upper_wall_y1, upper_clip[x] + 1)
          wy2 = Math.min(draw_upper_wall_y2, lower_clip[x] - 1)
          if upper_wall_texture != nil
            source = upper_wall_texture.composite.columns[texture_column & upper_wall_width_mask]
            if source.size > 0
              draw_column(source[0], wall_lights[light_index], x, wy1, wy2, inv_scale, upper_texture_alt)
            end
          end

          if upper_clip[x] < wy2
            upper_clip[x] = wy2.to_i16
          end

          portal_y1_frac += portal_y1_step
        elsif draw_ceiling
          cy1 = upper_clip[x] + 1
          cy2 = Math.min(draw_wall_y1 - 1, lower_clip[x] - 1)
          draw_ceiling_column(front_sector, ceiling_flat, plane_lights, x, cy1, cy2, front_sector_ceiling_height)

          if upper_clip[x] < cy2
            upper_clip[x] = cy2.to_i16
          end
        end

        if draw_lower_wall
          draw_lower_wall_y1 = (portal_y2_frac.data + HEIGHT_UNIT - 1) >> HEIGHT_BITS
          draw_lower_wall_y2 = wall_y2_frac.data >> HEIGHT_BITS

          wy1 = Math.max(draw_lower_wall_y1, upper_clip[x] + 1)
          wy2 = Math.min(draw_lower_wall_y2, lower_clip[x] - 1)
          if lower_wall_texture != nil
            source = lower_wall_texture.composite.columns[texture_column & lower_wall_width_mask]
            if source.size > 0
              draw_column(source[0], wall_lights[light_index], x, wy1, wy2, inv_scale, lower_texture_alt)
            end
          end

          if draw_floor
            fy1 = Math.max(draw_wall_y2 + 1, upper_clip[x] + 1)
            fy2 = lower_clip[x] - 1
            draw_floor_column(front_sector, floor_flat, plane_lights, x, fy1, fy2, front_sector_floor_height)
          end

          if lower_clip[x] > wy1
            lower_clip[x] = wy1.to_i16
          end

          portal_y2_frac += portal_y2_step
        elsif draw_floor
          fy1 = Math.max(draw_wall_y2 + 1, upper_clip[x] + 1)
          fy2 = lower_clip[x] - 1
          draw_floor_column(front_sector, floor_flat, plane_lights, x, fy1, fy2, front_sector_floor_height)

          if lower_clip[x] > draw_wall_y2 + 1
            lower_clip[x] = fy1.to_i16
          end
        end

        if draw_masked_texture
          @clip_data[masked_texture_column + x] = texture_column.to_i16
        end

        rw_scale += rw_scale_step
        wall_y1_frac += wall_y1_step
        wall_y2_frac += wall_y2_step

        x += 1
      end

      #
      # Save sprite clipping info.
      #

      if (((vis_wall_range.silhouette & Silhouette::Upper).to_i32 != 0 ||
         draw_masked_texture) && vis_wall_range.upper_clip == -1)
        @clip_data[@clip_data_length..range] == upper_clip[x1..range]
        vis_wall_range.upper_clip = @clip_data_length - x1
        @clip_data_length += range
      end

      if (((vis_wall_range.silhouette & Silhouette::Lower).to_i32 != 0 ||
         draw_masked_texture) && vis_wall_range.lower_clip == -1)
        @clip_data[@clip_data_length..range] = lower_clip[x1..range]
      end

      if draw_masked_texture && (vis_wall_range.silhouette & Silhouette::Upper).to_i32 == 0
        vis_wall_range.silhouette |= Silhouette::Upper
        vis_wall_range.upper_sil_height = Fixed.min_value
      end

      if draw_masked_texture && (vis_wall_range.silhouette & Silhouette::Lower).to_i32 == 0
        vis_wall_range.silhouette |= Silhouette::Lower
        vis_wall_range.lower_sil_height = Fixed.max_value
      end
    end

    private def render_masked_textures
      i = @vis_wall_range_count - 1
      while i >= 0
        draw_seg = @vis_wall_ranges[i]
        if draw_seg.masked_texture_column != -1
          draw_masked_range(draw_seg, draw_seg.x1, draw_seg.x2)
        end

        i -= 1
      end
    end

    private def draw_masked_range(draw_seg : VisWallRange, x1 : Int32, x2 : Int32)
      seg = draw_seg.seg

      wall_light_level = (seg.front_sector.light_level >> LIGHT_SEG_SHIFT) + @extra_light
      if seg.vertex1.y == seg.vertex2.y
        wall_light_level -= 1
      elsif seg.vertex1.x == seg.vertex2.x
        wall_light_level += 1
      end

      wall_lights = @scale_light[Math.clamp(wall_light_level, 0, LIGHT_LEVEL_COUNT - 1)]

      wall_texture = @textures[@world.specials.texture_translation[seg.side_def.middle_texture]]
      mask = wall_texture.width - 1

      mid_texture_alt : Fixed
      if (seg.line_def.flags & LineFlags::DontPegBottom).to_i32 != 0
        mid_texture_alt = draw_seg.front_sector_floor_height > draw_seg.back_sector_floor_height ? draw_seg.front_sector_floor_height : draw_seg.back_sector_floor_height
        mid_texture_alt = mid_texture_alt + Fixed.from_i(wall_texture.height) - @view_z
      else
        mid_texture_alt = draw_seg.front_sector_ceiling_height > draw_seg.back_sector_ceiling_height ? draw_seg.front_sector_ceiling_height : draw_seg.back_sector_ceiling_height
        mid_texture_alt = mid_texture_alt - @view_z
      end
      mid_texture_alt += seg.side_def.scale_step
      scale = draw_seg.scale1 + (x1 - draw_seg.x1) * scale_step

      x = x1
      while x <= x2
        index = Math.min(scale.data >> SCALE_LIGHT_SHIFT, @max_scale_light - 1)

        col = @clip_data[draw_seg.masked_texture_column + x]

        if col != Int16::MAX
          top_y = @center_y_frac - mid_texture_alt * scale
          inv_scale = Fixed.new((0xffffffff_u32 / scale.data.to_u32).to_i32)
          ceil_clip = @clip_data[draw_seg.upper_clip + x]
          floor_clip = @clip_data[draw_seg.lower_clip + x]
          draw_masked_column(
            wall_texture.composite.columns[col & mask],
            wall_lights[index],
            x,
            top_y,
            scale,
            inv_scale,
            mid_texture_alt,
            ceil_clip,
            floor_clip
          )

          @clip_data[draw_seg.masked_texture_column + x] = Int16::MAX
        end

        scale += scale_step

        x += 1
      end
    end

    private def draw_ceiling_column(
      sector : Sector,
      flat : Flat,
      plane_lights : Array(Array(UInt8)),
      x : Int32,
      y1 : Int32,
      y2 : Int32,
      ceiling_height : Fixed
    )
      if flat == @flats.sky_flat
        draw_sky_column(x, y1, y2)
        return
      end

      return if y2 - y1 < 0

      height = (ceiling_height - @view_z).abs

      flat_data = flat.data

      if sector == @ceiling_prev_sector && @ceiling_prev_x == x - 1
        p1 = Math.max(y1, @ceiling_prev_y1)
        p2 = Math.min(y2, @ceiling_prev_y2)

        pos = @screen_height * (@window_x + x) + @window_y + y1

        y = y1
        while y < p1
          distance = height * @plane_y_slope[y]
          @ceiling_x_step[y] = distance * @plane_base_x_scale
          @ceiling_y_step[y] = distance * @plane_base_y_scale

          length = distance * @plane_dist_scale[x]
          angle = @view_angle + @x_to_angle[x]
          x_frac = @view_x + Trig.cos(angle) * length
          y_frac = -@view_y + Trig.sin(angle) * length
          @ceiling_x_frac[y] = x_frac
          @ceiling_y_frac[y] = y_frac

          colormap = plane_lights[Math.min((distance.data >> Z_LIGHT_SHIFT).to_u32, MAX_Z_LIGHT - 1)]
          @ceiling_lights[y] = colormap

          spot = ((y_frac.data >> (16 - 6)) & (63 * 64)) + ((x_frac.data >> 16) & 63)
          @screen_data[pos] = colormap[flat_data[spot]]
          pos += 1

          y += 1
        end

        y = p1
        while y <= p2
          x_frac = @ceiling_x_frac[y] + @ceiling_x_step[y]
          y_frac = @ceiling_y_frac[y] + @ceiling_y_step[y]

          spot - ((y_frac.data >> (16 - 6)) & (63 * 64)) + ((x_frac.data >> 16) & 63)
          @screen_data[pos] = @ceiling_lights[y][flat_data[spot]]
          pos += 1

          @ceiling_x_frac[y] = x_frac
          @ceiling_y_frac[y] = y_frac

          y += 1
        end

        y = p2 + 1
        while y < y2
          distance = height * @plane_y_slope[y]
          @ceiling_x_step[y] = distance * @plane_base_x_scale
          @ceiling_y_step[y] = distance * @plane_base_y_scale

          length = distance * @plane_dist_scale[x]
          angle = @view_angle + @x_to_angle[x]
          x_frac = @view_x + Trig.cos(angle) * length
          y_frac = -@view_y - Trig.sin(angle) * length
          @ceiling_x_frac[y] = x_frac
          @ceiling_y_frac[y] = y_frac

          colormap = plane_lights[Math.min((distance.data >> Z_LIGHT_SHIFT).to_u32, MAX_Z_LIGHT - 1)]
          @ceiling_lights[y] = colormap

          spot = ((y_frac.data >> (16 - 6)) & (63 * 64)) + ((x_frac.data >> 16) & 63)
          @screen_data[pos] = colormap[flat_data[spot]]
          pos += 1

          y += 1
        end
      else
        pos = @screen_height * (@window_x + x) + @window_y + y1

        y = y1
        while y <= y2
          distance = height * @plane_y_slope[y]
          @ceiling_x_step[y] = distance * @plane_base_x_scale
          @ceiling_y_step[y] = distance * @plane_base_y_scale

          length = distance * @plane_dist_scale[x]
          angle = @view_angle + @x_to_angle[x]
          x_frac = @view_x + Trig.cos(angle) * length
          y_frac = -@view_y - Trig.sin(angle) * length
          @ceiling_x_frac[y] = x_frac
          @ceiling_y_frac[y] = y_frac

          colormap = plane_lights[Math.min((distance.data >> Z_LIGHT_SHIFT).to_u32, MAX_Z_LIGHT - 1)]
          @ceiling_lights[y] = colormap

          spot = ((y_frac.data >> (16 - 6)) & (63 * 64)) + ((x_frac.data >> 16) & 63)
          @screen_data[pos] = colormap[flat_data[spot]]
          pos += 1

          y += 1
        end
      end

      @ceiling_prev_sector = sector
      @ceiling_prev_x = x
      @ceiling_prev_y1 = y1
      @ceiling_prev_y2 = y2
    end

    private def draw_floor_column(
      sector : Sector,
      flat : Flat,
      plane_lights : Array(Array(UInt8)),
      x : Int32,
      y1 : Int32,
      y2 : Int32,
      floor_height : Fixed
    )
      if flat == @flats.sky_flat
        draw_sky_column(x, y1, y2)
        return
      end

      return if y2 - y1 < 0

      height = (floor_height - @view_z).abs

      flat_data = flat.data

      if sector == @floor_prev_sector && @floor_prev_x == x - 1
        p1 = Math.max(y1, @floor_prev_y1)
        p2 = Math.min(y2, @floor_prev_y2)

        pos = @screen_height * (@window_x + x) + @window_y + y1

        y = y1
        while y < p1
          distance = height * @plane_y_slope[y]
          @floor_x_step[y] = distance * @plane_base_x_scale
          @floor_y_step[y] = distance * @plane_base_y_scale

          length = distance * @plane_dist_scale[x]
          angle = @view_angle + @x_to_angle[x]
          x_frac = @view_x + Trig.cos(angle) * length
          y_frac = -@view_y + Trig.sin(angle) * length
          @floor_x_frac[y] = x_frac
          @floor_y_frac[y] = y_frac

          colormap = plane_lights[Math.min((distance.data >> Z_LIGHT_SHIFT).to_u32, MAX_Z_LIGHT - 1)]
          @ceiling_lights[y] = colormap

          spot = ((y_frac.data >> (16 - 6)) & (63 * 64)) + ((x_frac.data >> 16) & 63)
          @screen_data[pos] = colormap[flat_data[spot]]
          pos += 1

          y += 1
        end

        y = p1
        while y <= p2
          x_frac = @floor_x_frac[y] + @floor_x_step[y]
          y_frac = @floor_y_frac[y] + @floor_y_step[y]

          spot - ((y_frac.data >> (16 - 6)) & (63 * 64)) + ((x_frac.data >> 16) & 63)
          @screen_data[pos] = @floor_lights[y][flat_data[spot]]
          pos += 1

          @floor_x_frac[y] = x_frac
          @floor_y_frac[y] = y_frac

          y += 1
        end

        y = p2 + 1
        while y < y2
          distance = height * @plane_y_slope[y]
          @floor_x_step[y] = distance * @plane_base_x_scale
          @floor_y_step[y] = distance * @plane_base_y_scale

          length = distance * @plane_dist_scale[x]
          angle = @view_angle + @x_to_angle[x]
          x_frac = @view_x + Trig.cos(angle) * length
          y_frac = -@view_y - Trig.sin(angle) * length
          @floor_x_frac[y] = x_frac
          @floor_y_frac[y] = y_frac

          colormap = plane_lights[Math.min((distance.data >> Z_LIGHT_SHIFT).to_u32, MAX_Z_LIGHT - 1)]
          @floor_lights[y] = colormap

          spot = ((y_frac.data >> (16 - 6)) & (63 * 64)) + ((x_frac.data >> 16) & 63)
          @screen_data[pos] = colormap[flat_data[spot]]
          pos += 1

          y += 1
        end
      else
        pos = @screen_height * (@window_x + x) + @window_y + y1

        y = y1
        while y <= y2
          distance = height * @plane_y_slope[y]
          @floor_x_step[y] = distance * @plane_base_x_scale
          @floor_y_step[y] = distance * @plane_base_y_scale

          length = distance * @plane_dist_scale[x]
          angle = @view_angle + @x_to_angle[x]
          x_frac = @view_x + Trig.cos(angle) * length
          y_frac = -@view_y - Trig.sin(angle) * length
          @floor_x_frac[y] = x_frac
          @floor_y_frac[y] = y_frac

          colormap = plane_lights[Math.min((distance.data >> Z_LIGHT_SHIFT).to_u32, MAX_Z_LIGHT - 1)]
          @floor_lights[y] = colormap

          spot = ((y_frac.data >> (16 - 6)) & (63 * 64)) + ((x_frac.data >> 16) & 63)
          @screen_data[pos] = colormap[flat_data[spot]]
          pos += 1

          y += 1
        end
      end

      @floor_prev_sector = sector
      @floor_prev_x = x
      @floor_prev_y1 = y1
      @floor_prev_y2 = y2
    end

    private def draw_column(
      column : Column,
      map : Array(UInt8),
      x : Int32,
      y1 : Int32,
      y2 : Int32,
      inv_scale : Fixed,
      texture_alt : Fixed
    )
      return if y2 - y1 < 0

      # Framebuffer destination address.
      # Use ylookup LUT to avoid multiply with ScreenWidth.
      # Use columnofs LUT for subwindows?
      pos1 = @screen_height * (@window_x + x) + @window_y + y1
      pos2 = pos1 + (y2 - y1)

      # Determine scaling, which is the only mapping to be done.
      frac_step = inv_scale
      frac = texture_alt + (y1 - @center_y) * frac_step

      # Inner loop that does the actual texture mapping,
      # e.g. a DDA-lile scaling.
      # This is as fast as it gets.
      source = column.data
      offset = column.offset
      pos = pos1
      while pos <= pos2
        # Re-map color indices from wall texture column
        # using a lighting/special effects LUT.
        @screen_data[pos] = map[source[offset + ((frac.data >> Fixed::FRAC_BITS) & 127)]]
        frac += frac_step
        pos += 1
      end
    end

    private def draw_column_translation(
      column : Column,
      translation : Array(UInt8),
      map : Array(UInt8),
      x : Int32,
      y1 : Int32,
      y2 : Int32,
      inv_scale : Fixed,
      texture_alt : Fixed
    )
      return if y2 - y1 < 0

      # Framebuffer destination address.
      # Use ylookup LUT to avoid multiply with ScreenWidth.
      # Use columnofs LUT for subwindows?
      pos1 = @screen_height * (@window_x + x) + @window_y + y1
      pos2 = pos1 + (y2 - y1)

      # Determine scaling, which is the only mapping to be done.
      frac_step = inv_scale
      frac = texture_alt + (y1 - @center_y) * frac_step

      # Inner loop that does the actual texture mapping,
      # e.g. a DDA-lile scaling.
      # This is as fast as it gets.
      source = column.data
      offset = column.offset
      pos = pos1
      while pos <= pos2
        # Re-map color indices from wall texture column
        # using a lighting/special effects LUT.
        @screen_data[pos] = map[translation[source[offset + ((frac.data >> Fixed::FRAC_BITS) & 127)]]]
        frac += frac_step
        pos += 1
      end
    end

    private def draw_fuzz_column(
      column : Column,
      x : Int32,
      y1 : Int32,
      y2 : Int32
    )
      return if y2 - y1 < 0

      y1 = 1 if y1 == 0

      y2 = @window_height - 2 if y2 == @window_height - 1

      pos1 = @screen_height * (@window_x + x) + @window_y + y1
      pos2 = pos1 + (y2 - y1)

      map = @colormap[6]
      pos = pos1
      while pos <= pos2
        @screen_data[pos] = map[@screen_data[pos + @@fuzz_table[@fuzz_pos]]]

        @fuzz_pos += 1
        if @fuzz_pos == @@fuzz_table.size
          @fuzz_pos = 0
        end

        pos += 1
      end
    end

    private def draw_sky_column(x : Int32, y1 : Int32, y2 : Int32)
      angle = (@view_angle + @x_to_angle[x]).data >> ANGLE_TO_SKY_SHIFT
      mask = @world.map.sky_texture.width - 1
      source = @world.map.sky_texture.composite.columns[angle & mask]
      draw_column(source[0], @colormap[0], x, y1, y2, @sky_inv_scale, @sky_texture_alt)
    end

    private def draw_masked_column(
      columns : Array(Column),
      map : Array(UInt8),
      x : Int32,
      top_y : Fixed,
      scale : Fixed,
      inv_scale : Fixed,
      texture_alt : Fixed,
      upper_clip : Int32,
      lower_clip : Int32
    )
      columns.each do |column|
        y1_frac = top_y + scale * column.top_delta
        y2_frac = y1_frac + scale * column.length
        y1 = (y1_frac.data + Fixed::FRAC_UNIT - 1) >> Fixed::FRAC_BITS
        y2 = (y2_frac.data - 1) >> Fixed::FRAC_BITS

        y1 = Math.max(y1, upper_clip + 1)
        y2 = Math.min(y2, lower_clip - 1)

        if y1 <= y2_frac
          alt = Fixed.new(texture_alt.data - (column.top_delta << Fixed::FRAC_BITS))
          draw_column(column, map, x, y1, y2, inv_scale, alt)
        end
      end
    end

    private def draw_masked_column_translation(
      columns : Array(Column),
      translation : Array(UInt8),
      map : Array(UInt8),
      x : Int32,
      top_y : Fixed,
      scale : Fixed,
      inv_scale : Fixed,
      texture_alt : Fixed,
      upper_clip : Int32,
      lower_clip : Int32
    )
      columns.each do |column|
        y1_frac = top_y + scale * column.top_delta
        y2_frac = y1_frac + scale * column.length
        y1 = (y1_frac.data + Fixed::FRAC_UNIT - 1) >> Fixed::FRAC_BITS
        y2 = (y2_frac.data - 1) >> Fixed::FRAC_BITS

        y1 = Math.max(y1, upper_clip + 1)
        y2 = Math.min(y2, lower_clip - 1)

        if y1 <= y2_frac
          alt = Fixed.new(texture_alt.data - (column.top_delta << Fixed::FRAC_BITS))
          draw_column_translation(column, translation, map, x, y1, y2, inv_scale, alt)
        end
      end
    end

    private def draw_masked_fuzz_column(
      columns : Array(Column),
      x : Int32,
      top_y : Fixed,
      scale : Fixed,
      upper_clip : Int32,
      lower_clip : Int32
    )
      columns.each do |column|
        y1_frac = top_y + scale * column.top_delta
        y2_frac = y1_frac + scale * column.length
        y1 = (y1_frac.data + Fixed::FRAC_UNIT - 1) >> Fixed::FRAC_BITS
        y2 = (y2_frac.data - 1) >> Fixed::FRAC_BITS

        y1 = Math.max(y1, upper_clip + 1)
        y2 = Math.min(y2, lower_clip - 1)

        if y1 <= y2
          draw_fuzz_column(column, x, y1, y2)
        end
      end
    end

    private def add_sprites(sector : Sector, valid_count : Int32)
      # BSP is traversed by subsector.
      # A sector might have been split into several subsectors during BSP building.
      # Thus we check whether its already added.
      return if secor.valid_count == valid_count

      # Well, now it will be done
      sector.valid_count = valid_count

      sprite_light_level = (sector.light_level >> LIGHT_SEG_SHIFT) + @extra_light
      sprite_lights = @scale_light[Math.clamp(sprite_light_level, 0, LIGHT_LEVEL_COUNT - 1)]

      # Handle all things in sector.
      things = sector.get_enumerator
      valid_thing = true
      while things.move_next
        project_sprite(things.current, sprite_lights)
      end
    end

    private def project_sprite(things : Mobj, sprite_lights : Array(Array(UInt8)))
      if @vis_sprite_count == @vis_sprites.size
        # Too many sprites.
        return
      end

      thing_x = thing.get_interpolated_x(@frame_frac)
      thing_y = thing.get_interpolated_y(@frame_frac)
      thing_z = thing.get_interpolated_z(@frame_frac)

      # Transform the origin point.
      tr_x = thing_x - @view_x
      tr_y = thing_y - @view_y

      gxt = tr_x * @view_cos
      gyt = -(tr_y * @view_sin)

      tz = gxt - gyt

      # Thing is behind view plane?
      return tz < @@min_z

      x_scale = @projection / tz

      gxt = -tr_x * @view_sin
      gyt = tr_y * @view_cos
      tx = -(gyt + gxt)

      # Too far off the side?
      return if tx.abs > (tz << 2)

      sprite_def = @sprites[thing.sprite]
      frame_number = thing.frame & 0x7F
      sprite_frame = sprite_def.frames[frame_number]

      lump : Patch
      flip : Bool
      if sprite_frame.rotate
        # Choose a different rotation based on player view.
        ang = Geometry.point_to_angle(@view_x, @view_y, thing_x, thing_y)
        rot = (ang.data - thing.angle.data + (Angle.ang45.data / 2) * 9) >> 29
        lump = sprite_frame.patches[rot]
        flip = sprite_frame.flip[rot]
      else
        # Use single rotation for all views.
        lump = sprite_frame.patches[0]
        flip = sprite_frame.flip[0]
      end

      # Calculate edges of the shape.
      tx -= Fixed.from_i(lump.left_offset)
      x1 = (@center_x_frac + (tx * x_scale)).data >> Fixed::FRAC_BITS

      # Off the right side?
      return if x1 > @window_width

      tx += Fixed.from_i(lump.width)
      x2 = ((@center_x_frac + (tx * x_scale)).data >> Fixed::FRAC_BITS) - 1

      # Off the left side?
      return if x2 < 0

      # Store information in a vissprite.

      vis = @vis_sprites[@vis_sprite_count]
      @vis_sprite_count += 1

      vis.mobj_flags = thing.flags
      vis.scale = x_scale
      vis.global_x = thing_x
      vis.global_y = thing_y
      vis.global_bottom_z = thing_z
      vis.global_top_z = thing_z + Fixed.from_i(lump.top_offset)
      vis.texture_alt = vis.global_top_z - @view_z
      vis.x1 = x1 < 0 ? 0 : x1
      vis.x2 = x2 >= @window_width ? @window_width - 1 : x2

      inv_scale = Fixed.one / x_scale

      if flip
        vis.start_frac = Fixed.new(Fixed.from_i(lump.width).data - 1)
        vis.inv_scale = -inv_scale
      else
        vis.start_frac = Fixed.zero
        vis.inv_scale = inv_scale
      end

      if vis.x1 > x1
        vis.start_frac += vis.inv_scale * (vis.x1 - x1)
      end

      vis.patch = lump

      if @fixed_colormap == 0
        if (thing.frame & 0x8000) == 0
          vis.colormap = sprite_lights[Math.min(x_scale.data >> SCALE_LIGHT_SHIFT, @max_scale_light - 1)]
        else
          vis.colormap.@colormap.full_bright
        end
      else
        vis.colormap = @colormap[@fixed_colormap]
      end
    end

    private def render_sprites
      @vis_sprites.sort! { |x, y| y.scale.data - x.scale.data }

      i = @vis_sprite_count - 1
      while i >= 0
        draw_sprite(@vis_sprites[i])
        i -= 1
      end
    end

    private def draw_sprite(sprite : VisSprite)
      x = sprite.x1
      while x <= sprite.x2
        @lower_clip[x] = -2
        @upper_clip[x] = -2
        x += 1
      end

      # Scan drawsegs from end to start for obscuring segs.
      # The first drawseg that has a greater scale is the clip seg.
      i = @vis_wall_range_count - 1
      while i >= 0
        wall = @vis_wall_ranges[i]

        # Determine if the drawseg obscures the sprite.
        if (wall.x1 > sprite.x2 ||
           wall.x2 < sprite.x1 ||
           (wall.silhouette.to_i32 == 0 && wall.masked_texture_column == -1))
          # Does not cover sprite.
          i -= 1
          next
        end

        r1 = wall.x1 < sprite.x1 ? sprite.x1 : wall.x1
        r2 = wall.x2 > sprite.x2 ? sprite.x2 : wall.x2

        low_scale : Fixed
        scale : Fixed
        if wall.scale1 > wall.scale2
          low_scale = wall.scale2
          scale = wall.scale1
        else
          low_scale = wall.scale1
          scale = wall.scale2
        end

        if (scale < sprite.scale ||
           (low_scale < sprite.scale &&
           Geometry.point_on_seg_side(sprite.global_x, sprite.global_y, wall.seg) == 0))
          # Masked mid texture?
          if wall.masked_texture_column != -1
            draw_masked_range(wall, r1, r2)
          end
          # Seg is behind sprite.
          i -= 1
          next
        end

        # Clip this piece of the sprite.
        silhouette = wall.Silhouette

        if sprite.global_bottom_z >= wall.lower_sil_height
          silhouette &= ~Silhouette::Lower
        end

        if sprite.global_top_z <= wall.upper_sil_height
          silhouette &= ~Silhouette::Upper
        end

        if silhouette == Silhouette::Lower
          # Bottom sil.
          x = r1
          while x <= r2
            if @lower_clip[x] == -2
              @lower_clip[x] = @clip_data[wall.lower_clip + x]
            end
            x += 1
          end
        elsif silhouette == Silhouette::Upper
          # Top sil.
          x = r1
          while x <= r2
            if @upper_clip[x] == -2
              @upper_clip[x] = @clip_data[wall.upper_clip + x]
            end
            x += 1
          end
        elsif silhouette == Silhouette::Both
          # Both.
          x = r1
          while x <= r2
            if @lower_clip[x] == -2
              @lower_clip[x] = @clip_data[wall.lower_clip + x]
            end
            if @upper_clip[x] == -2
              @upper_clip[x] = @clip_data[wall.upper_clip + x]
            end
            x += 1
          end
        end

        i -= 1
      end

      # All clipping has been performed, so draw the sprite.

      # Check for unclipped columns.
      x = sprite.x1
      while x <= sprite.x2
        if @lower_clip[x] == -2
          @lower_clip[x] = @window_height.to_i16
        end
        if @upper_clip[x] == -2
          @upper_clip[x] = -1
        end

        x += 1
      end

      if (sprite.mobj_flags & MobjFlags::Shadow).to_i32 != 0
        frac = sprite.start_frac
        x = sprite.x1
        while x <= sprite.x2
          texture_column = frac.to_int_floor
          draw_masked_fuzz_column(
            sprite.patch.columns[texture_column],
            x,
            @center_y_frac - (sprite.texture_alt * sprite.scale),
            sprite.scale,
            @upper_clip[x],
            @lower_clip[x]
          )
          frac += sprite.inv_scale

          x += 1
        end
      elsif ((sprite.mobj_flags & MobjFlags::Translation).to_i32 >> MobjFlags::TransShift.to_i32) != 0
        translation : Array(UInt8)
        case ((sprite.mobj_flags & MobjFlags::Translation).to_i32 >> MobjFlags::TransShift.to_i32)
        when 1
          translation = @green_to_gray
          break
        when 2
          translation = @green_to_brown
          break
        else
          translation = @green_to_red
          break
        end
        frac = sprite.start_frac
        x = sprite.x1
        while x <= sprite.x2
          texture_column = frac.to_int_floor
          draw_masked_column_translation(
            sprite.patch.columns[texture_column],
            translation,
            sprite.colormap,
            x,
            @center_y_frac - (sprite.texture_alt * sprite.scale),
            sprite.scale,
            sprite.inv_scale.abs,
            sprite.texture_alt,
            @upper_clip[x],
            @lower_clip[x]
          )
          frac += sprite.inv_scale

          x += 1
        end
      else
        frac = sprite.start_frac
        x = sprite.x1
        while x <= sprite.x2
          texture_column = frac.to_int_floor
          draw_masked_column(
            sprite.patch.columns[texture_column],
            sprite.colormap,
            x,
            @center_y_frac - (sprite.texture_alt * sprite.scale),
            sprite.scale,
            sprite.inv_scale.abs,
            sprite.texture_alt,
            @upper_clip[x],
            @lower_clip[x]
          )
          frac += sprite.inv_scale

          x += 1
        end
      end
    end

    private def draw_player_sprite(psp : PlayerSpriteDef, sprite_lights : Array(Array(UInt8)), fuzz : Bool)
      # Decide which patch to use.
      sprite_def = @sprites[psp.state.sprite]

      sprite_frame = sprite_def.frames[psp.state.frame & 0x7FFF]

      lump = sprite_frame.patches[0]
      flip = sprite_frame.flip[0]

      # Calculate edges of the shape.
      tx = psp.sx - Fixed.from_i(160)
      tx -= Fixed.from_i(lump.left_offset)
      x1 = (@center_x_frac + tx * @weapon_scale).data >> Fixed::FRAC_BITS

      # Off the right side?
      return if x1 > @window_height

      tx += Fixed.from_i(lump.width)
      x2 = ((@center_x_frac + tx * @weapon_scale).data >> Fixed::FRAC_BITS) - 1

      # Off the left side?
      return if x2 < 0

      # Store information in a vissprite.
      vis = @weapon_sprite
      vis.mobj_flags = 0
      # The code below is based on Crispy Doom's weapon rendering code.
      vis.texture_alt = Fixed.from_i(100) + Fixed.one / 4 - (psp.sy - Fixed.from_i(lump.top_offset))
      vis.x1 = x1 < 0 ? 0 : x1
      vis.x2 = x2 >= @window_width ? @window_width - 1 : x2
      vis.scale = @weapon_scale

      if flip
        vis.inv_scale = -@weapon_inv_scale
        vis.start_frac = Fixed.from_i(lump.width) - Fixed.new(1)
      else
        vis.inv_scale = @weapon_inv_scale
        vis.start_frac = Fixed.zero
      end

      if vis.x1 > x1
        vis.start_frac += vis.inv_scale * (vis.x1 - x1)
      end

      vis.patch = lump

      if @fixed_colormap == 0
        if (psp.state.frame & 0x8000) == 0
          vis.colormap = sprite_lights[@max_scale_light - 1]
        else
          vis.colormap = @colormap.full_bright
        end
      else
        vis.colormap = @colormap[@fixed_colormap]
      end

      if fuzz
        frac = vis.start_frac
        x = vis.x1
        while x <= vis.x2
          texture_column = frac.data >> Fixed::FRAC_BITS
          draw_masked_fuzz_column(
            vis.patch.columns[texture_column],
            x,
            @center_y_frac - (vis.texture_alt * vis.scale),
            vis.scale,
            -1,
            @window_height
          )
          frac += vis.inv_scale

          x += 1
        end
      else
        frac = vis.start_frac
        x = vis.x1
        while x <= vis.x2
          texture_column = frac.data >> Fixed::FRAC_BITS
          draw_masked_column(
            vis.patch.columns[texture_column],
            vis.colormap,
            x,
            @center_y_frac = (vis.texture_alt * vis.scale),
            vis.scale,
            vis.inv_scale.abs,
            vis.texture_alt,
            -1,
            @window_height
          )
          frac += vis.inv_scale

          x += 1
        end
      end
    end

    private def draw_player_sprites(player : Player)
      # Get light level.
      sprite_light_level = (player.mobj.subsector.sector.light_level >> LIGHT_SEG_SHIFT) + @extra_light

      sprite_lights : Array(Array(UInt8))
      if sprite_light_level
        sprite_lights = @scale_light[0]
      elsif sprite_light_level >= LIGHT_LEVEL_COUNT
        sprite_lights = @scale_light[LIGHT_LEVEL_COUNT - 1]
      else
        sprite_lights = @scale_light[sprite_light_level]
      end

      fuzz : Bool
      if (player.powers[PowerType::Invisibility.to_i32] > 4 * 32 ||
         (player.powers[PowerType::Invisibility.to_i32] & 8) != 0)
        # Shadow draw.
        fuzz = true
      else
        fuzz = false
      end

      # Add all active psprites.
      PlayerSprite::Count.times do |i|
        psp = player.player_sprites[i]
        if psp.state != nil
          draw_player_sprite(psp, sprite_lights, fuzz)
        end
      end
    end

    def window_size
      return @window_size
    end

    def window_size=(value : Int32)
      @window_size = value
      set_window_size(@window_size)
    end

    private class ClipRange
      getter first : Int32 = 0
      getter last : Int32 = 0

      def copy_from(range : ClipRange)
        @first = range.first
        @last = range.last
      end
    end

    private class VisWallRange
      property seg : Seg | Nil

      property x1 : Int32 = 0
      property x2 : Int32 = 0

      property scale1 : Fixed | Nil
      property scale2 : Fixed | Nil
      property scale_step : Fixed | Nil

      property silhouette : Silhouette = Silhouette.new(0)
      property upper_sil_height : Fixed | Nil
      property lower_sil_height : Fixed | Nil

      property upper_clip : Int32 = 0
      property lower_clip : Int32 = 0
      property masked_texture_column : Int32 = 0

      property front_sector_floor_height : Fixed | Nil
      property front_sector_ceiling_height : Fixed | Nil
      property back_sector_floor_height : Fixed | Nil
      property back_sector_ceiling_height : Fixed | Nil
    end

    @[Flags]
    private enum Silhouette
      Upper = 1
      Lower = 2
      Both  = 3
    end

    private class VisSprite
      property x1 : Int32 = 0
      property x2 : Int32 = 0

      # For line side calculation.
      property global_x : Fixed | Nil
      property global_y : Fixed | Nil

      # Global bottom / top for silhouette clipping
      property global_bottom_z : Fixed | Nil
      property global_top_z : Fixed | Nil

      # Horizontal position of x1
      property start_frac : Fixed | Nil

      property scale : Fixed | Nil

      # Negative if flipped.
      property inv_scale : Fixed | Nil

      property texture_alt : Fixed | Nil
      property patch : Patch | Nil

      # For color translation and shadow draw.
      property colormap : Array(UInt8) = Array(UInt8).new

      property mobj_flags : MobjFlags = MobjFlags.new(0)
    end
  end
end
