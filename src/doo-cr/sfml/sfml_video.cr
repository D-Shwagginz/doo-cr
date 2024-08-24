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
    include IVideo
    @renderer : Video::Renderer | Nil = nil

    @texture_width : Int32 = 0
    @texture_height : Int32 = 0

    @texture_data : Bytes = Bytes.new(0)
    @texture : SF::Texture | Nil = nil
    @sprite : SF::Sprite | Nil = nil

    @window_width : Int32 = 0
    @window_height : Int32 = 0
    @window : SF::RenderWindow | Nil = nil

    def wipe_band_count : Int32
      return @renderer.wipe_band_count
    end

    def wipe_height : Int32
      return @renderer.wipe_height
    end

    def max_window_size : Int32
      return @renderer.max_window_size
    end

    def window_size : Int32
      return @renderer.window_size
    end

    def window_size=(window_size : Int32)
      @renderer.window_size = value
    end

    def display_message : Bool
      return @renderer.display_message
    end

    def display_message=(display_message : Bool)
      @renderer.display_message = value
    end

    def max_gamma_correction_level : Int32
      return @renderer.max_gamma_correction_level
    end

    def gamma_correction_level : Int32
      return @renderer.gamma_correction_level
    end

    def gamma_correction_level=(gamma_correction_level : Int32)
      @renderer.gamma_correction_level = value
    end

    def initialize(config : Config, content : GameContent, @window : SF::RenderWindow)
      begin
        print("Initialize video: ")

        @renderer = Renderer.new(config, content)

        if config.video_hightresolution
          @texture_width = 512
          @texture_height = 1024
        else
          @texture_width = 256
          @texture_height = 512
        end

        @texture_data = Bytes.new(4 * @renderer.width * @renderer.height)
        @texture = SF::RenderTexture.new(@texture_width, @texture_height)
        @sprite = SF::Sprite.new(@texture)

        resize(@window.size.x, @window.size.y)

        puts "OK"
      rescue e
        puts "Failed"
        finalize()
        raise e
      end
    end

    def render(doom : Doom, frame_frac : Fixed) : SF::Sprite
      @renderer.render(doom, @texture_data, frame_frac)

      @texture.update(@texture_data, @renderer.width, @renderer.height, 0, 0)

      @window.clear(SF::Color::Black)
      @window.draw(@sprite)
      @window.display
    end

    def resize(width : Int32, height : Int32)
      @window_width = width
      @window_height = height
      @window.view = RF::View.new(RF::FloatRect.new(0, 0, width, height))
    end

    def initialize_wipe
      @renderer.initialize_wipe
    end

    def has_focus : Bool
      return true
    end

    def finalize
      puts "Shutdown video."

      if @texture != nil
        @texture.finalize
        @texture = nil
      end

      if @sprite != nil
        @sprite.finalize
        @sprite = nil
      end

      if @window != nil
        @window = nil
      end
    end
  end
end
