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

module Doocr::SFML
  class SFMLDoom
    @args : CommandLineArgs

    @config : Config | Nil = nil
    @content : GameContent | Nil = nil

    @window : SF::RenderWindow | Nil = nil

    @video : SFMLVideo | Nil = nil

    @sound : SFMLSound | Nil = nil
    @music : SFMLMusic | Nil = nil

    @user_input : SFMLUserInput | Nil = nil

    @doom : Doom | Nil

    @fps_scale : Int32 = 0
    @frame_count : Int32 = 0

    getter exception : Exception | Nil

    def initialize(@args : CommandLineArgs)
      begin
        @config = SFMLConfigUtilities.get_config
        @content = GameContent.new(@args)

        @config.as(Config).video_screenwidth = @config.as(Config).video_screenwidth.clamp(320, 3200)
        @config.as(Config).video_screenheight = @config.as(Config).video_screenheight.clamp(200, 2000)

        style = @config.as(Config).video_fullscreen ? SF::Style::Fullscreen : SF::Style::Default
        @window = SF::RenderWindow.new(
          SF::VideoMode.new(
            @config.as(Config).video_screenwidth,
            @config.as(Config).video_screenheight
          ),
          ApplicationInfo::TITLE,
          style
        )
        @window.as(SF::RenderWindow).vertical_sync_enabled = false

        load
      rescue e
        raise e
      end
    end

    private def quit
      if @exception != nil
        raise @exception.as(Exception)
      end
    end

    private def load
      @window.as(SF::RenderWindow).clear
      @window.as(SF::RenderWindow).display

      @video = SFMLVideo.new(@config.as(Config), @content.as(GameContent), @window.as(SF::RenderWindow))

      @sound = SFMLSound.new(@config.as(Config), @content.as(GameContent)) if !@args.nosfx.present
      @music = SFMLConfigUtilities.get_music_instance(@config.as(Config), @content.as(GameContent)) if !@args.nomusic.present

      @user_input = SFMLUserInput.new(@config.as(Config), @window.as(SF::RenderWindow), self, !@args.nomouse.present)

      @doom = Doom.new(@args, @config.as(Config), @content.as(GameContent), @video.as(SFMLVideo), @sound.as(SFMLSound), @music.as(SFMLMusic), @user_input.as(SFMLUserInput))

      @fps_scale = @args.timedemo.present ? 1 : @config.as(Config).video_fpsscale
      @frame_count = -1
    end

    private def update
      begin
        @frame_count += 1
        if @frame_count % @fps_scale == 0
          if @doom.as(Doom).update == UpdateResult::Completed
            close
          end
        end
      rescue e
        @exception = e
      end

      quit if @exception != nil
    end

    private def render
      begin
        frame_frac = Fixed.from_i(@frame_count % @fps_scale + 1) / @fps_scale
        @video.as(SFMLVideo).render(@doom.as(Doom), frame_frac)
      rescue e
        @exception = e
      end
    end

    private def resize(width : Int32, height : Int32)
      @video.as(SFMLVideo).resize(width, height)
    end

    private def close
      if @user_input != nil
        @user_input.as(SFMLUserInput).finalize
        @user_input = nil
      end

      if @music != nil
        @music.as(SFMLMusic).finalize
        @music = nil
      end

      if @sound != nil
        @sound.as(SFMLSound).finalize
        @sound = nil
      end

      if @video != nil
        @video.as(SFMLVideo).finalize
        @video = nil
      end

      @config.as(Config).save(ConfigUtilities.get_config_path)
      finalize()
    end

    def key_down(key : SF::Keyboard::Key)
      @doom.post_event(DoomEvent.new(EventType::KeyDown, SFMLUserInput.sfml_to_doom(key)))
    end

    def key_up(key : SF::Keyboard::Key)
      @doom.post_event(DoomEvent.new(EventType::KeyUp, SFMLUserInput.sfml_to_doom(key)))
    end

    def finalize
      if @window != nil
        @window.as(SF::RenderWindow).close
        @window.as(SF::RenderWindow).finalize
        @window = nil
      end
    end

    def quit_message : String
      return @doom.as(Doom).quit_message.as?(String) ? @doom.as(Doom).quit_message.as(String) : ""
    end
  end
end
