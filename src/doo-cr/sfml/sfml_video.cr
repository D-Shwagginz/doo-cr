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

require "../video/i_video.cr"

module Doocr::SFML
  class SFMLVideo
    include Video::IVideo
    @renderer : Video::Renderer | Nil

    @texture_width : Int32 = 0
    @texture_height : Int32 = 0

    @texture_data : Array(UInt8) = [] of UInt8
    @texture : SF::Texture | Nil
    @sprite : SF::Sprite | Nil

    @window_width : Int32 = 0
    @window_height : Int32 = 0
    @window : SF::RenderWindow

    def wipe_band_count : Int32
      return @renderer.as(Video::Renderer).wipe_band_count
    end

    def wipe_height : Int32
      return @renderer.as(Video::Renderer).wipe_height
    end

    def max_window_size : Int32
      return @renderer.as(Video::Renderer).max_window_size
    end

    def window_size : Int32
      return @renderer.as(Video::Renderer).window_size
    end

    def window_size=(window_size : Int32)
      @renderer.as(Video::Renderer).window_size = window_size
    end

    def display_message : Bool
      return @renderer.as(Video::Renderer).display_message
    end

    def display_message=(display_message : Bool)
      @renderer.as(Video::Renderer).display_message = display_message
    end

    def max_gamma_correction_level : Int32
      return @renderer.as(Video::Renderer).max_gamma_correction_level
    end

    def gamma_correction_level : Int32
      return @renderer.as(Video::Renderer).gamma_correction_level
    end

    def gamma_correction_level=(gamma_correction_level : Int32)
      @renderer.as(Video::Renderer).gamma_correction_level = gamma_correction_level
    end

    def initialize(config : Config, content : GameContent, @window : SF::RenderWindow)
      begin
        print("Initialize video: ")

        @renderer = Video::Renderer.new(config, content)

        if config.video_highresolution
          @texture_width = 512
          @texture_height = 1024
        else
          @texture_width = 256
          @texture_height = 512
        end

        @texture_data = Array.new(4 * @renderer.as(Video::Renderer).width * @renderer.as(Video::Renderer).height, 0_u8)
        @texture = SF::Texture.new(@texture_width, @texture_height)
        @sprite = SF::Sprite.new(@texture.as(SF::Texture))

        resize(@window.size.x, @window.size.y)

        puts "OK"
      rescue e
        puts "Failed"
        raise e
      end
    end

    def render(doom : Doom, frame_frac : Fixed)
      @renderer.as(Video::Renderer).render(doom, @texture_data, frame_frac)

      @texture.as(SF::Texture).update(@texture_data.to_unsafe, @renderer.as(Video::Renderer).width, @renderer.as(Video::Renderer).height, 0, 0)

      @window.clear(SF::Color::Black)
      @window.draw(@sprite.as(SF::Sprite))
      @window.display
    end

    def resize(width : Int32, height : Int32)
      @window_width = width
      @window_height = height
      @window.view = SF::View.new(SF::FloatRect.new(0_f32, 0_f32, width.to_f32, height.to_f32))
    end

    def initialize_wipe
      @renderer.as(Video::Renderer).initialize_wipe
    end

    def has_focus : Bool
      @window.focus?
    end

    def finalize
      puts "Shutdown video."

      if @texture != nil
        @texture.as(SF::Texture).finalize
        @texture = nil
      end

      if @sprite != nil
        @sprite.as(SF::Sprite).finalize
        @sprite = nil
      end
    end
  end
end
