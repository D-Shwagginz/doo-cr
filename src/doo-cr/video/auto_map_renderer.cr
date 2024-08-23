#
# Copyright (C) 1993-1996 Id Software, Inc.
# Copyright (C) 2019-2020 Nobuaki Tanaka
# Copyright (C) 2024 Devin Shwagginz
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#

module Doocr
  class AutoMapRenderer
    @@pr : Float32 = 8 * DoomInfo.mobj_infos[MobjType::Player.to_i32].radius.to_f32 / 7

    # The vector graphics for the automap.
    # A line drawing of the player pointing right, starting from the middle.
    @@player_arrow : Array(Float32) = [
      -@@pr + @@pr / 8_f32, 0_f32, @@pr, 0_f32,       # -----
      @@pr, 0_f32, @@pr - @@pr / 2_f32, @@pr / 4_f32, # ----->
      @@pr, 0_f32, @@pr - @@pr / 2_f32, -@@pr / 4_f32,
      -@@pr + @@pr / 8_f32, 0_f32, -@@pr - @@pr / 8_f32, @@pr / 4_f32, # >---->
      -@@pr + @@pr / 8_f32, 0_f32, -@@pr - @@pr / 8_f32, -@@pr / 4_f32,
      -@@pr + 3_f32 * @@pr / 8_f32, 0_f32, -@@pr + @@pr / 8_f32, @@pr / 4_f32, # >>--->
      -@@pr + 3_f32 * @@pr / 8_f32, 0_f32, -@@pr + @@pr / 8_f32, -@@pr / 4_f32,
    ]

    @@tr : Float32 = 16_f32

    @@thing_triangle : Array(Float32) = [
      -0.5_f32 * @@tr, -0.7_f32 * @@tr, @@tr, 0_f32,
      @@tr, 0_f32, -0.5_f32 * @@tr, 0.7_f32 * @@tr,
      -0.5_f32 * @@tr, 0.7_f32 * @@tr, -0.5_f32 * @@tr, -0.7_f32 * @@tr,
    ]

    # For use if I do walls with outsides / insides.
    @@reds : Int32 = 256 - 5 * 16
    @@red_range : Int32 = 16
    @@greens : Int32 = 7 * 16
    @@green_range : Int32 = 16
    @@grays : Int32 = 6 * 16
    @@gray_range : Int32 = 16
    @@browns : Int32 = 4 * 16
    @@brown_range : Int32 = 16
    @@yellows : Int32 = 256 - 32 + 7
    @@yellow_range : Int32 = 1
    @@black : Int32 = 0
    @@white : Int32 = 256 - 47

    # Automap colors.
    @@background : Int32 = @@black
    @@wall_colors : Int32 = @@reds
    @@wall_range : Int32 = @@red_range
    @@ts_wall_colors : Int32 = @@grays
    @@ts_wall_range : Int32 = @@gray_range
    @@fd_wall_colors : Int32 = @@browns
    @@fd_wall_range : Int32 = @@brown_range
    @@cd_wall_colors : Int32 = @@yellows
    @@cd_wall_range : Int32 = @@yellow_range
    @@thing_colors : Int32 = @@greens
    @@thing_range : Int32 = @@green_range
    @@secret_wall_colors : Int32 = @@wall_colors
    @@secret_wall_range : Int32 = @@wall_range

    @@player_colors : Array(Int32) = [
      @@greens,
      @@grays,
      @@browns,
      @@reds,
    ]

    @screen : Video::DrawScreen

    @scale : Int32 = 0
    @am_width : Int32
    @am_height : Int32
    @ppu : Float32

    @min_x : Float32 = 0_f32
    @max_x : Float32 = 0_f32
    @width : Float32 = 0_f32
    @min_y : Float32 = 0_f32
    @max_y : Float32 = 0_f32
    @height : Float32 = 0_f32

    @actual_view_x : Float32 = 0_f32
    @actual_view_y : Float32 = 0_f32
    @zoom : Float32 = 0_f32

    @render_view_x : Float32 = 0_f32
    @render_view_y : Float32 = 0_f32

    @mark_numbers : Array(Patch)

    def initialize(wad : Wad, @screen)
      @scale == @screen.width / 320
      @am_width = @screen.width
      @am_height = @screen.height - @scale * StatusBarRenderer.height
      @ppu = scale.to_f32 / 16

      @mark_numbers = Array.new(10, Patch.from_wad(wad, "AMMNUM" + i))
    end

    def render(player : Player)
      @screen.fill_rect(0, 0, @am_width, @am_height, @@background)

      world = player.mobj.world
      am = world.auto_map

      @min_x = am.min_x.to_f32
      @max_x = am.max_x.to_f32
      @width = @max_x - @min_x
      @min_y = am.min_y.to_f32
      @max_y = am.max_y.to_f32
      @height = @max_y - @min_y

      @actual_view_x = am.view_x.to_f32
      @actual_view_y = am.view_y.to_f32

      # This hack aligns the view point to an integer coordinate
      # so that line shake is reduced when the view point moves.
      @render_view_x = (@zoom * @ppu * @actual_view_x).round_even / (@zoom * @ppu)
      @render_view_y = (@zoom * @ppu * @actual_view_y).round_even / (@zoom * @ppu)

      world.map.lines.each do |line|
        v1 = to_screen_pos(line.vertex1)
        v2 = to_screen_pos(line.vertex2)

        cheating = am.state != AutoMapState::None

        if cheating || (line.flags & LineFlags::Mapped) != 0
          next if (line.flags & MobjFlags::DontDraw) != 0 && !cheating

          if line.back_sector == nil
            @screen.draw_line(v1.x, v1.y, v2.x, v2.y, @@wall_colors)
          else
            if line.special == LineSpecial.new(39)
              # Teleporters.
              @screen.draw_line(v1.x, v1.y, v2.x, v2.y, @@wall_colors + @@wall_range / 2)
            elsif (line.flags & LineFlags::Secret) != 0
              # Secret door.
              if cheating
                @screen.draw_line(v1.x, v1.y, v2.x, v2.y, @@secret_wall_colors)
              else
                @screen.draw_line(v1.x, v1.y, v2.x, v2.y, @@wall_colors)
              end
            elsif line.back_sector.floor_height != line.front_sector.floor_height
              # Floor level change.
              @screen.draw_line(v1.x, v1.y, v2.x, v2.y, @@fd_wall_colors)
            elsif line.back_sector.ceiling_height != line.front_sector.ceiling_height
              # Ceiling level change.
              @screen.draw_line(v1.x, v1.y, v2.x, v2.y, @@cd_wall_colors)
            elsif cheating
              @screen.draw_line(v1.x, v1.y, v2.x, v2.y, @@ts_wall_colors)
            end
          end
        elsif player.powers[PowerType::AllMap.to_i32] > 0
          if (line.flags & LineFlags::DontDraw.to_i32) == 0
            @screen.draw_line(v1.x, v1.y, v2.x, v2.y, @@grays + 3)
          end
        end
      end

      am.marks.size.times do |i|
        pos = to_screen_pos(am.marks[i])
        @screen.draw_patch(
          @mark_numbers[i],
          pos.x.round_even.to_i32,
          pos.y.round_even.to_i32,
          @scale
        )
      end

      draw_things(world) if am.state == AutoMapState::AllThings

      draw_players(world)

      if !am.follow
        @screen.draw_line(
          @am_width / 2 - 2 * @scale, @am_height / 2,
          @am_width / 2 + 2 * @scale, @am_height / 2,
          @@grays
        )

        @screen.draw_line(
          @am_width / 2, @am_height / 2 - 2 * @scale,
          @am_width / 2, @am_height / 2 + 2 * @scale,
          @@grays
        )
      end

      @screen.draw_text(
        world.map.title,
        0,
        @am_height - @scale,
        @scale
      )
    end

    private def draw_players(world : World)
      options = world.options
      player = options.players
      console_player = world.console_player

      if !options.net_game
        draw_character(console_player.mobj, @@player_arrow, @@white)
        return
      end

      Player::MAX_PLAYER_COUNT.times do |i|
        player = players[i]
        next if options.deathmatch != 0 && !options.demo_playback && player != console_player

        next if !player.in_game

        color : Int32
        if player.powers[PowerType::Invisibility] > 0
          # Close to black.
          color = 246
        else
          color = @@player_colors[i]
        end

        draw_character(player.mobj, @@player_arrow, color)
      end
    end

    private def draw_things(world : World)
      world.thinkers.each do |thinker|
        mobj = thinker.as?(Mobj)
        draw_character(mobj, @@thing_triangle, @@greens) if mobj != nil
      end
    end

    private def draw_character(mobj : Mobj, data : Array(Float32), color : Int32)
      pos = to_screen_pos(mobj.x, mobj.y)
      sin = Math.sin(mobj.angle.to_radian).to_f32
      cos = Math.cos(mobj.angle.to_radian).to_f32
      i = 0
      while i < data.size
        x1 = pos.x + @zoom * @ppu * (cos * data[i + 0] - sin * data[i + 1])
        y1 = pos.y - @zoom * @ppu * (sin * data[i + 0] + cos * data[i + 1])
        x2 = pos.x + @zoom * @ppu * (cos * data[i + 2] - sin * data[i + 3])
        y2 = pos.y - @zoom * @ppu * (sin * data[i + 2] + cos * data[i + 3])
        @screen.draw_line(x1, y1, x2, y2, color)
        i += 4
      end
    end

    private def to_screen_pos(x : Fixed, y : Fixed) : DrawPos
      pos_x = @zoom * @ppu * (x.to_f32 - @render_view_x) + @am_width / 2
      pos_y = -@zoom * @ppu * (y.to_f32 - @render_view_y) + @am_height / 2
      return DrawPos.new(pos_x, pos_y)
    end

    private def to_screen_pos(v : Vertex) : DrawPos
      pos_x = @zoom * @ppu * (v.x.to_f32 - @render_view_x) + @am_width / 2
      pos_y = -@zoom * @ppu * (v.y.to_f32 - @render_view_y) + @am_height / 2
      return DrawPos.new(pos_x, pos_y)
    end

    private struct DrawPos
      getter x : Float32
      getter y : Float32

      def initialize(@x, @y)
      end
    end
  end
end
