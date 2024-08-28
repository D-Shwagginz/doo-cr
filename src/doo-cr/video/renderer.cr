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
  class Renderer
    @@gamma_correction_parameters : Array(Float64) = [
      1.00,
      0.95,
      0.90,
      0.85,
      0.80,
      0.75,
      0.70,
      0.65,
      0.60,
      0.55,
      0.50,
    ]

    @config : Config

    @palette : Palette

    @screen : DrawScreen

    @menu : MenuRenderer
    @three_d : ThreeDRenderer
    @status_bar : StatusBarRenderer
    @intermission : IntermissionRenderer
    @opening_sequence : OpeningSequenceRenderer | Nil = nil
    @auto_map : AutoMapRenderer | Nil = nil
    @finale : FinaleRenderer | Nil = nil

    @pause : Patch | Nil = nil

    @wipe_band_width : Int32 = 0
    getter wipe_band_count : Int32 = 0
    getter wipe_height : Int32 = 0
    @wipe_buffer : Array(UInt8) = [] of UInt8

    def width : Int32
      return @screen.width
    end

    def height : Int32
      return @screen.height
    end

    def max_window_size : Int32
      return ThreeDRenderer.max_screen_size
    end

    def window_size : Int32
      return @three_d.window_size
    end

    def window_size=(value : Int32)
      @config.video_gamescreensize = value
      @three_d.window_size = value
    end

    def display_message : Bool
      return @config.video_displaymessage
    end

    def display_message=(value : Bool)
      @config.video_displaymessage = value
    end

    def max_gamma_correction_level : Int32
      return @@gamma_correction_parameters.size - 1
    end

    def gamma_correction_level : Int32
      return @config.video_gammacorrection
    end

    def gamma_correction_level=(value : Int32)
      @config.video_gammacorrection = value
      @palette.reset_colors(@@gamma_correction_parameters[@config.video_gammacorrection])
    end

    def initialize(@config, content : GameContent)
      @palette = content.palette

      if @config.video_highresolution
        @screen = DrawScreen.new(content.wad.as(Wad), 640, 400)
      else
        @screen = DrawScreen.new(content.wad.as(Wad), 320, 200)
      end

      @config.video_gamescreensize = @config.video_gamescreensize.clamp(0, max_window_size)
      @config.video_gammacorrection = @config.video_gammacorrection.clamp(0, max_gamma_correction_level)

      @menu = MenuRenderer.new(content.wad.as(Wad), @screen)
      @three_d = ThreeDRenderer.new(content, @screen, @config.video_gamescreensize)
      @status_bar = StatusBarRenderer.new(content.wad.as(Wad), @screen)
      @intermission = IntermissionRenderer.new(content.wad.as(Wad), @screen)
      @opening_sequence = OpeningSequenceRenderer.new(content.wad.as(Wad), @screen, self)
      @auto_map = AutoMapRenderer.new(content.wad.as(Wad), @screen)
      @finale = FinaleRenderer.new(content, @screen)

      @pause = Patch.from_wad(content.wad.as(Wad), "M_PAUSE")

      scale = (@screen.width / 320).to_i32
      @wipe_band_width = 2 * scale
      @wipe_band_count = (@screen.width / @wipe_band_width).to_i32 + 1
      @wipe_height = (@screen.height / scale).to_i32
      @wipe_buffer = Array.new(@screen.data.size, 0_u8)

      @palette.reset_colors(@@gamma_correction_parameters[@config.video_gammacorrection])
    end

    def render_doom(doom : Doom, frame_frac : Fixed)
      if doom.current_state == DoomState::Opening
        @opening_sequence.as(OpeningSequenceRenderer).render(doom.opening.as(OpeningSequence), frame_frac)
      elsif doom.current_state == DoomState::DemoPlayback
        render_game(doom.demo_playback.as(DemoPlayback).game, frame_frac)
      elsif doom.current_state == DoomState::Game
        render_game(doom.game.as(DoomGame), frame_frac)
      end

      if (!doom.menu.as(DoomMenu).active &&
         doom.current_state == DoomState::Game &&
         doom.game.as(DoomGame).game_state == GameState::Level &&
         doom.game.as(DoomGame).paused)
        scale = (@screen.width / 320).to_i32
        @screen.draw_patch(
          @pause.as(Patch),
          ((@screen.width - scale * @pause.as(Patch).width) / 2).to_i32,
          4 * scale,
          scale
        )
      end
    end

    def render_menu(doom : Doom)
      @menu.render(doom.menu.as(DoomMenu)) if doom.menu.as(DoomMenu).active
    end

    def render_game(game : DoomGame, frame_frac : Fixed)
      frame_frac = Fixed.one if game.paused

      if game.game_state == GameState::Level
        console_player = game.world.as(World).console_player
        display_player = game.world.as(World).display_player

        if game.world.as(World).auto_map.as(AutoMap).visible
          @auto_map.as(AutoMapRenderer).render(console_player)
          @status_bar.as(StatusBarRenderer).render(console_player, true)
        else
          @three_d.render(display_player, frame_frac)
          if @three_d.window_size < 8
            @status_bar.as(StatusBarRenderer).render(console_player, true)
          elsif @three_d.window_size == ThreeDRenderer.max_screen_size
            @status_bar.as(StatusBarRenderer).render(console_player, false)
          end
        end

        message = console_player.message.nil? ? "NIL" : console_player.message.as(String)
        if @config.video_displaymessage || message.same?(DoomInfo::Strings::MSGOFF.to_s)
          if console_player.message_time > 0
            scale = (@screen.width / 320).to_i32
            @screen.draw_text(message, 0, 7 * scale, scale)
          end
        end
      elsif game.game_state == GameState::Intermission
        @intermission.render(game.intermission.as(Intermission))
      elsif game.game_state == GameState::Finale
        @finale.as(FinaleRenderer).render(game.finale.as(Finale))
      end
    end

    def render(doom : Doom, destination : Array(UInt8), frame_frac : Fixed)
      if doom.wiping
        render_wipe(doom, destination)
        return
      end

      render_doom(doom, frame_frac)
      render_menu(doom)

      colors = @palette[0]
      if (doom.current_state == DoomState::Game &&
         doom.game.as(DoomGame).game_state == GameState::Level)
        colors = @palette[get_palette_number(doom.game.as(DoomGame).world.as(World).console_player)]
      elsif (doom.current_state == DoomState::Opening &&
            doom.opening.as(OpeningSequence).state == OpeningSequenceState::Demo &&
            doom.opening.as(OpeningSequence).game.as(DoomGame).game_state == GameState::Level)
        colors = @palette[get_palette_number(doom.opening.as(OpeningSequence).game.as(DoomGame).world.as(World).console_player)]
      elsif (doom.current_state == DoomState::DemoPlayback &&
            doom.demo_playback.as(DemoPlayback).game.as(DoomGame).game_state == GameState::Level)
        colors = @palette[get_palette_number(doom.demo_playback.as(DemoPlayback).game.as(DoomGame).world.as(World).console_player)]
      end

      write_data(colors, destination)
    end

    private def render_wipe(doom : Doom, destination : Array(UInt8))
      render_doom(doom, Fixed.one)

      wipe = doom.wipe_effect.as((WipeEffect))
      scale = (@screen.width / 320).to_i32
      (@wipe_band_count - 1).times do |i|
        x1 = @wipe_band_width * i
        x2 = x1 + @wipe_band_width
        y1 = Math.max(scale * wipe.y[i], 0)
        y2 = Math.max(scale * wipe.y[i + 1], 0)
        dy = (y2 - y1).to_f32 / @wipe_band_width
        x = x1
        while x < x2
          y = (y1 + dy * ((x - x1) / 2 * 2)).round_even.to_i32
          copy_length = @screen.height - y
          if copy_length > 0
            src_pos = @screen.height * x
            dst_pos = @screen.height * x + y
            @screen.data[dst_pos, copy_length] = @wipe_buffer[src_pos, copy_length]
          end
          x += 1
        end
      end

      render_menu(doom)

      write_data(@palette[0], destination)
    end

    def initialize_wipe
      @wipe_buffer = @screen.data.dup
    end

    private def write_data(colors : Array(UInt32), destination : Array(UInt8))
      screen_data = @screen.data
      x = 0
      y = 0
      while x < destination.size
        j = colors[screen_data[y]].to_s(2, precision: 32)
        r = j[0, 8].to_i(2).to_u8
        g = j[8, 8].to_i(2).to_u8
        b = j[16, 8].to_i(2).to_u8
        a = j[24, 8].to_i(2).to_u8

        destination[x] = r
        x += 1
        destination[x] = g
        x += 1
        destination[x] = b
        x += 1
        destination[x] = a
        x += 1
        y += 1
      end
    end

    private def get_palette_number(player : Player) : Int32
      count = player.damage_count

      if player.powers[PowerType::Strength.to_i32] != 0
        # Slowly fade the berzer out.
        bzc = 12 - (player.powers[PowerType::Strength.to_i32] >> 6)
        count = bzc if bzc > count
      end

      palette : Int32

      if count != 0
        palette = (count + 7) >> 3

        if palette >= Palette.damage_count
          palette = Palette.damage_count - 1
        end

        palette += Palette.damage_start
      elsif player.bonus_count != 0
        palette = (player.bonus_count + 7) >> 3

        if palette >= Palette.bonus_count
          palette = Palette.bonus_count - 1
        end

        palette += Palette.bonus_start
      elsif (player.powers[PowerType::IronFeet.to_i32] > 4 * 32 ||
            (player.powers[PowerType::IronFeet.to_i32] & 8) != 0)
        palette = Palette.ironfeet
      else
        palette = 0
      end

      return palette
    end
  end
end
