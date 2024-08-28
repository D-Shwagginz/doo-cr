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

module Doocr::Video
  class IntermissionRenderer
    # GLOBAL LOCATIONS
    @@title_y : Int32 = 2
    @@spacing_y : Int32 = 33

    # SINGLE-PLAYER STUFF
    @@sp_stats_x : Int32 = 50
    @@sp_stats_y : Int32 = 50
    @@sp_time_x : Int32 = 16
    @@sp_time_y : Int32 = 200 - 32

    # NET GAME STUFF
    @@ng_stats_y : Int32 = 50
    @@ng_spacing_x : Int32 = 64

    # DEATHMATCH STUFF
    @@dm_matrix_x : Int32 = 42
    @@dm_matrix_y : Int32 = 68
    @@dm_spacing_x : Int32 = 40
    @@dm_totals_x : Int32 = 269
    @@dm_killers_x : Int32 = 10
    @@dm_killers_y : Int32 = 100
    @@dm_victims_x : Int32 = 5
    @@dm_victims_y : Int32 = 50

    @map_pictures : Array(String) = [
      "WIMAP0",
      "WIMAP1",
      "WIMAP2",
    ]

    @@player_boxes : Array(String) = [
      "STPB0",
      "STPB1",
      "STPB2",
      "STPB3",
    ]

    @@you_are_here : Array(String) = [
      "WIURH0",
      "WIURH1",
    ]

    @@doom_levels : Array(Array(String)) = [] of Array(String)
    @@doom2_levels : Array(String) = [] of String

    @wad : Wad
    @screen : DrawScreen

    @cache : PatchCache

    @minus : Patch
    @numbers : Array(Patch)
    @percent : Patch
    @colon : Patch

    @scale : Int32

    def initialize(@wad, @screen)
      if @@doom_levels.size == 0
        4.times do |e|
          @@doom_levels << Array.new(9, "")
          9.times do |m|
            @@doom_levels[e] << "WILV#{e}#{m}"
          end
        end
      end

      if @@doom2_levels.size == 0
        32.times do |m|
          @@doom2_levels << "CWILV" + m.to_s(precision: 2)
        end
      end

      @cache = PatchCache.new(@wad)

      @minus = Patch.from_wad(@wad, "WIMINUS")
      @numbers = Array(Patch).new(10)
      10.times do |i|
        @numbers << Patch.from_wad(@wad, "WINUM#{i}")
      end
      @percent = Patch.from_wad(@wad, "WIPCNT")
      @colon = Patch.from_wad(@wad, "WICOLON")

      @scale = (@screen.width / 320).to_i32
    end

    private def draw_patch(patch : Patch, x : Int32, y : Int32)
      @screen.draw_patch(patch, @scale * x, @scale * y, @scale)
    end

    private def draw_patch(name : String, x : Int32, y : Int32)
      scale = (@screen.width / 320).to_i32
      @screen.draw_patch(@cache[name], scale * x, scale * y, scale)
    end

    private def get_width(name : String) : Int32
      return @cache.get_width(name)
    end

    private def get_height(name : String) : Int32
      return @cache.get_height(name)
    end

    def render(im : Intermission)
      case im.state
      when IntermissionState::StatCount
        if im.options.as(GameOptions).deathmatch != 0
          draw_deathmatch_stats(im)
        elsif im.options.as(GameOptions).net_game
          draw_net_game_stats(im)
        else
          draw_single_player_stats(im)
        end
      when IntermissionState::ShowNextLoc
        draw_show_next_loc(im)
      when IntermissionState::NoState
        draw_no_state(im)
      end
    end

    private def draw_background(im : Intermission)
      if im.options.as(GameOptions).game_mode == GameMode::Commercial
        draw_patch("INTERPIC", 0, 0)
      else
        e = im.options.as(GameOptions).episode - 1
        if e < @map_pictures.size
          draw_patch(@map_pictures[e], 0, 0)
        else
          draw_patch("INTERPIC", 0, 0)
        end
      end
    end

    private def draw_single_player_stats(im : Intermission)
      draw_background(im)

      # Draw animated background.
      draw_background_animation(im)

      # Draw level name.
      draw_finished_level_name(im)

      # Line height.
      line_height = 3 * (@numbers[0].height / 2).to_i32

      draw_patch(
        "WIOSTK", # KILLS
        @@sp_stats_x,
        @@sp_stats_y
      )

      draw_percent(
        320 - @@sp_stats_x,
        @@sp_stats_y,
        im.kill_count[0]
      )

      draw_patch(
        "WIOSTI", # ITEMS
        @@sp_stats_x,
        @@sp_stats_y + line_height
      )

      draw_percent(
        320 - @@sp_stats_x,
        @@sp_stats_y + line_height,
        im.item_count[0]
      )

      draw_patch(
        "WISCRT2", # SECRET
        @@sp_stats_x,
        @@sp_stats_y + 2 * line_height
      )

      draw_percent(
        320 - @@sp_stats_x,
        @@sp_stats_y + 2 * line_height,
        im.secret_count[0]
      )

      draw_patch(
        "WITIME", # TIME
        @@sp_time_x,
        @@sp_time_y
      )

      draw_time(
        (320 / 2).to_i32 - @@sp_time_x,
        @@sp_time_y,
        im.time_count
      )

      if im.info.as(IntermissionInfo).episode < 3
        draw_patch(
          "WIPAR", # PAR
          (320 / 2).to_i32 + @@sp_time_x,
          @@sp_time_y
        )

        draw_time(
          320 - @@sp_time_x,
          @@sp_time_y,
          im.par_count
        )
      end
    end

    private def draw_net_game_stats(im : Intermission)
      draw_background(im)

      # Draw animated background.
      draw_background_animation(im)

      # Draw level name.
      draw_finished_level_name(im)

      ng_stats_x = 32 + (get_width("STFST01") / 2).to_i32
      ng_stats_x += 32 if !im.do_frags

      #  Draw stat titles (top line).
      draw_patch(
        "WIOSTK", # KILLS
        ng_stats_x + @@ng_spacing_x - get_width("WIOSTK"),
        @@ng_stats_y
      )

      draw_patch(
        "WIOSTI", # ITEMS
        ng_stats_x + 2 * @@ng_spacing_x - get_width("WIOSTI"),
        @@ng_stats_y
      )

      draw_patch(
        "WIOSTS", # SCRT
        ng_stats_x + 3 * @@ng_spacing_x - get_width("WIOSTS"),
        @@ng_stats_y
      )

      if im.do_frags
        draw_patch(
          "WIFRGS", # FRAGS
          ng_stats_x + 4 * @@ng_spacing_x - get_width("WIFRGS"),
          @@ng_stats_y
        )
      end

      # Draw stats.
      y = @@ng_stats_y + get_height("WIOSTK")

      Player::MAX_PLAYER_COUNT.times do |i|
        next if !im.options.as(GameOptions).players[i].in_game

        x = ng_stats_x

        draw_patch(
          @@player_boxes[i],
          x - get_width(@@player_boxes[i]),
          y
        )

        if i == im.options.as(GameOptions).console_player
          draw_patch(
            "STFST01", # Player face
            x - get_width(@@player_boxes[i]),
            y
          )
        end

        x += @@ng_spacing_x

        draw_percent(x - @percent.width, y + 10, im.kill_count[i])
        x += @@ng_spacing_x

        draw_percent(x - @percent.width, y + 10, im.item_count[i])
        x += @@ng_spacing_x

        draw_percent(x - @percent.width, y + 10, im.secret_count[i])
        x += @@ng_spacing_x

        draw_number(x, y + 10, im.frag_count[i], -1) if im.do_frags

        y += @@spacing_y
      end
    end

    private def draw_deathmatch_stats(im : Intermission)
      draw_background(im)

      # Draw animated background.
      draw_background_animation(im)

      # Draw level name.
      draw_finished_level_name(im)

      # Draw stat titles (top line).
      draw_patch(
        "WIMSTT", # TOTAL
        @@dm_totals_x - (get_width("WIMSTT") / 2).to_i32,
        @@dm_matrix_y - @@spacing_y + 10
      )

      draw_patch(
        "WIKILRS", # KILLERS
        @@dm_killers_x,
        @@dm_killers_y
      )

      draw_patch(
        "WIVCTMS", # VICTIMS
        @@dm_victims_x,
        @@dm_victims_y
      )

      # Draw player boxes.
      x = @@dm_matrix_x + @@dm_spacing_x
      y = @@dm_matrix_y

      Player::MAX_PLAYER_COUNT.times do |i|
        if im.options.as(GameOptions).players[i].in_game
          draw_patch(
            @@player_boxes[i],
            x - (get_width(@@player_boxes[i]) / 2).to_i32,
            @@dm_matrix_y - @@spacing_y
          )

          draw_patch(
            @@player_boxes[i],
            @@dm_matrix_x - (get_width(@@player_boxes[i]) / 2).to_i32,
            y
          )

          if i == im.options.as(GameOptions).console_player
            draw_patch(
              "STFDEAD0", # Player face (dead)
              x - (get_width(@@player_boxes[i]) / 2).to_i32,
              @@dm_matrix_y - @@spacing_y
            )

            draw_patch(
              "STFST01", # Player face
              @@dm_matrix_x - (get_width(@@player_boxes[i]) / 2).to_i32,
              y
            )
          end
        else
          # V_DrawPatch(x-SHORT(bp[i]->width)/2,
          #   DM_MATRIXY - WI_SPACINGY, FB, bp[i]);
          # V_DrawPatch(DM_MATRIXX-SHORT(bp[i]->width)/2,
          #   y, FB, bp[i]);
        end

        x += @@dm_spacing_x
        y += @@spacing_y
      end

      # Draw stats.c
      y = @@dm_matrix_y + 10
      w = @numbers[0].width

      Player::MAX_PLAYER_COUNT.times do |i|
        x = @@dm_matrix_x + @@dm_spacing_x

        if im.options.as(GameOptions).players[i].in_game
          Player::MAX_PLAYER_COUNT.times do |j|
            if im.options.as(GameOptions).players[j].in_game
              draw_number(x + w, y, im.dm_frag_count[i][j], 2)
            end

            x += @@dm_spacing_x
          end

          draw_number(@@dm_totals_x + w, y, im.dm_total_count[i], 2)
        end

        y += @@spacing_y
      end
    end

    private def draw_no_state(im : Intermission)
      draw_show_next_loc(im)
    end

    private def draw_show_next_loc(im : Intermission)
      draw_background(im)

      # Draw animated background.
      draw_background_animation(im)

      if im.options.as(GameOptions).game_mode != GameMode::Commercial
        if im.info.as(IntermissionInfo).episode > 2
          draw_entering_level_name(im)
          return
        end

        last = (im.info.as(IntermissionInfo).last_level == 8) ? im.info.as(IntermissionInfo).next_level - 1 : im.info.as(IntermissionInfo).last_level

        # Draw a splat on taken cities.
        last.times do |i|
          x = WorldMap.locations[im.info.as(IntermissionInfo).episode][i].x
          y = WorldMap.locations[im.info.as(IntermissionInfo).episode][i].y
          draw_patch("WISPLAT", x, y)
        end

        # Splat the secret level?
        if im.info.as(IntermissionInfo).did_secret
          x = WorldMap.locations[im.info.as(IntermissionInfo).episode][8].x
          y = WorldMap.locations[im.info.as(IntermissionInfo).episode][8].y
          draw_patch("WISPLAT", x, y)
        end

        # Draw "you are here".
        if im.show_you_are_here
          x = WorldMap.locations[im.info.as(IntermissionInfo).episode][im.info.as(IntermissionInfo).next_level].x
          y = WorldMap.locations[im.info.as(IntermissionInfo).episode][im.info.as(IntermissionInfo).next_level].y
          draw_suitable_patch(@@you_are_here, x, y)
        end
      end

      # Draw next level name.
      if (im.options.as(GameOptions).game_mode != GameMode::Commercial) || im.info.as(IntermissionInfo).next_level != 30
        draw_entering_level_name(im)
      end
    end

    private def draw_finished_level_name(intermission : Intermission)
      wbs = intermission.info.as(IntermissionInfo)
      y = @@title_y

      level_name : String = ""
      if intermission.options.as(GameOptions).game_mode != GameMode::Commercial
        e = intermission.options.as(GameOptions).episode - 1
        level_name = @@doom_levels[e][wbs.last_level]
      else
        level_name = @@doom2_levels[wbs.last_level]
      end

      # Draw level name.
      draw_patch(
        level_name,
        ((320 - get_width(level_name)) / 2).to_i32,
        y
      )

      # Draw "Finished!".
      y += 5 * (get_height(level_name) / 4).to_i32

      draw_patch(
        "WIF",
        ((320 - get_width("WIF")) / 2).to_i32,
        y
      )
    end

    private def draw_entering_level_name(im : Intermission)
      wbs = im.info.as(IntermissionInfo)
      y = @@title_y

      level_name : String
      if im.options.as(GameOptions).game_mode != GameMode::Commercial
        e = im.options.as(GameOptions).episode - 1
        level_name = @@doom_levels[e][wbs.next_level]
      else
        level_name = @@doom2_levels[wbs.next_level]
      end

      # Draw level name.
      draw_patch(
        "WIENTER",
        ((320 - get_width("WIENTER")) / 2).to_i32,
        y
      )

      # Draw "Finished!".
      y += 5 * (get_height(level_name) / 4).to_i32

      draw_patch(
        level_name,
        ((320 - get_width(level_name)) / 2).to_i32,
        y
      )
    end

    private def draw_number(x : Int32, y : Int32, n : Int32, digits : Int32) : Int32
      if digits < 0
        if n == 0
          # Make variable-length zeros 1 digit long.
          digits = 1
        else
          # Figure out number of digits.
          digits = 0
          temp = n
          while temp != 0
            temp /= 10
            digits += 1
          end
        end
      end

      neg = n < 0
      n = -n if neg

      # If non-number, do not draw it.
      return 0 if n == 1994

      font_width = @numbers[0].width

      # Draw the new number.
      while digits != 0
        digits -= 1
        x -= font_width
        draw_patch(@numbers[(n % 10).to_i32], x, y)
        n /= 10
      end

      # Draw a minus sign if necessary.
      draw_patch(@minus, x -= 8, y) if neg

      return x
    end

    private def draw_percent(x : Int32, y : Int32, p : Int32)
      return if p < 0

      draw_patch(@percent, x, y)
      draw_number(x, y, p, -1)
    end

    private def draw_time(x : Int32, y : Int32, t : Int32)
      return if t < 0

      if t <= 61 * 59
        div = 1

        j = true
        while j || (t / div != 0)
          j = false
          n = (t / div % 60).to_i32
          x = draw_number(x, y, n, 2) - @colon.width
          div *= 60

          # Draw.
          draw_patch(@colon, x, y) if div == 60 || t / div != 0
        end
      else
        draw_patch(
          "WISUCKS", # SUCKS
          x - get_width("WISUCKS"),
          y
        )
      end
    end

    private def draw_background_animation(im : Intermission)
      return if im.options.as(GameOptions).game_mode == GameMode::Commercial

      return if im.info.as(IntermissionInfo).episode > 2

      im.animations.size.times do |i|
        a = im.animations[i]
        if a.patch_number >= 0
          draw_patch(a.patches[a.patch_number], a.location_x, a.location_y)
        end
      end
    end

    private def draw_suitable_patch(candidates : Array(String), x : Int32, y : Int32)
      fits = false
      i = 0

      j = true
      while j || (!fits && i < 2)
        j = false
        patch = @cache[candidates[i]]

        left = x - patch.left_offset
        top = y - patch.top_offset
        right = left + patch.width
        bottom = top + patch.height

        if left >= 0 && right < 320 && top >= 0 && bottom < 320
          fits = true
        else
          i += 1
        end
      end

      if fits && i < 2
        draw_patch(candidates[i], x, y)
      else
        raise "Could not place patch!"
      end
    end
  end
end
