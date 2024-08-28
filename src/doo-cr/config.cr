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
  class Config
    property key_forward : KeyBinding = KeyBinding.new(
      [
        DoomKey::Up,
        DoomKey::W,
      ])
    property key_backward : KeyBinding = KeyBinding.new(
      [
        DoomKey::Down,
        DoomKey::S,
      ])
    property key_strafeleft : KeyBinding = KeyBinding.new(
      [
        DoomKey::A,
      ])
    property key_straferight : KeyBinding = KeyBinding.new(
      [
        DoomKey::D,
      ])
    property key_turnleft : KeyBinding = KeyBinding.new(
      [
        DoomKey::Left,
      ])
    property key_turnright : KeyBinding = KeyBinding.new(
      [
        DoomKey::Right,
      ])
    property key_fire : KeyBinding = KeyBinding.new(
      [
        DoomKey::LControl,
        DoomKey::RControl,
      ],
      [
        DoomMouseButton::Mouse1,
      ])
    property key_use : KeyBinding = KeyBinding.new(
      [
        DoomKey::Space,
      ],
      [
        DoomMouseButton::Mouse2,
      ])
    property key_run : KeyBinding = KeyBinding.new(
      [
        DoomKey::LShift,
        DoomKey::RShift,
      ])
    property key_strafe : KeyBinding = KeyBinding.new(
      [
        DoomKey::LAlt,
        DoomKey::RAlt,
      ])

    property mouse_sensitivity : Int32 = 8
    property mouse_disableyaxis : Bool = false

    property game_alwaysrun : Bool = true

    property video_screenwidth : Int32 = 640
    property video_screenheight : Int32 = 400
    property video_fullscreen : Bool = false
    property video_highresolution : Bool = true
    property video_gamescreensize : Int32 = 7
    property video_displaymessage : Bool = true
    property video_gammacorrection : Int32 = 2
    property video_fpsscale : Int32 = 2

    property audio_soundvolume : Int32 = 8
    property audio_musicvolume : Int32 = 8
    property audio_randompitch : Bool = true

    getter is_restored_from_file : Bool = false

    # Default settings.
    def load_default
      @key_forward = KeyBinding.new(
        [
          DoomKey::Up,
          DoomKey::W,
        ])
      @key_backward = KeyBinding.new(
        [
          DoomKey::Down,
          DoomKey::S,
        ])
      @key_strafeleft = KeyBinding.new(
        [
          DoomKey::A,
        ])
      @key_straferight = KeyBinding.new(
        [
          DoomKey::D,
        ])
      @key_turnleft = KeyBinding.new(
        [
          DoomKey::Left,
        ])
      @key_turnright = KeyBinding.new(
        [
          DoomKey::Right,
        ])
      @key_fire = KeyBinding.new(
        [
          DoomKey::LControl,
          DoomKey::RControl,
        ],
        [
          DoomMouseButton::Mouse1,
        ])
      @key_use = KeyBinding.new(
        [
          DoomKey::Space,
        ],
        [
          DoomMouseButton::Mouse2,
        ])
      @key_run = KeyBinding.new(
        [
          DoomKey::LShift,
          DoomKey::RShift,
        ])
      @key_strafe = KeyBinding.new(
        [
          DoomKey::LAlt,
          DoomKey::RAlt,
        ])

      @mouse_sensitivity = 8
      @mouse_disableyaxis = false

      @game_alwaysrun = true

      @video_screenwidth = 640
      @video_screenheight = 400
      @video_fullscreen = false
      @video_highresolution = true
      @video_gamescreensize = 7
      @video_displaymessage = true
      @video_gammacorrection = 2
      @video_fpsscale = 2

      @audio_soundvolume = 8
      @audio_musicvolume = 8
      @audio_randompitch = true
    end

    def initialize
      load_default
    end

    def initialize(path : String)
      begin
        print("Restore settings: ")

        hash = {} of String => String
        File.read_lines(path).each do |line|
          split = line.split('=', remove_empty: true)
          hash[split[0].strip] = split[1].strip if split.size == 2
        end

        @key_forward = get_key_binding(hash, "key_forward", @key_forward)
        @key_backward = get_key_binding(hash, "key_backward", @key_backward)
        @key_strafeleft = get_key_binding(hash, "key_strafeleft", @key_strafeleft)
        @key_straferight = get_key_binding(hash, "key_straferight", @key_straferight)
        @key_turnleft = get_key_binding(hash, "key_turnleft", @key_turnleft)
        @key_turnright = get_key_binding(hash, "key_turnright", @key_turnright)
        @key_fire = get_key_binding(hash, "key_fire", @key_fire)
        @key_use = get_key_binding(hash, "key_use", @key_use)
        @key_run = get_key_binding(hash, "key_run", @key_run)
        @key_strafe = get_key_binding(hash, "key_strafe", @key_strafe)

        @mouse_sensitivity = get_int(hash, "mouse_sensitivity", @mouse_sensitivity)
        @mouse_disableyaxis = get_bool(hash, "mouse_disableyaxis", @mouse_disableyaxis)

        @game_alwaysrun = get_bool(hash, "game_alwaysrun", @game_alwaysrun)

        @video_screenwidth = get_int(hash, "video_screenwidth", @video_screenwidth)
        @video_screenheight = get_int(hash, "video_screenheight", @video_screenheight)
        @video_fullscreen = get_bool(hash, "video_fullscreen", @video_fullscreen)
        @video_highresolution = get_bool(hash, "video_highresolution", @video_highresolution)
        @video_displaymessage = get_bool(hash, "video_displaymessage", @video_displaymessage)
        @video_gamescreensize = get_int(hash, "video_gamescreensize", @video_gamescreensize)
        @video_gammacorrection = get_int(hash, "video_gammacorrection", @video_gammacorrection)
        @video_fpsscale = get_int(hash, "video_fpsscale", @video_fpsscale)

        @audio_soundvolume = get_int(hash, "audio_soundvolume", @audio_soundvolume)
        @audio_musicvolume = get_int(hash, "audio_musicvolume", @audio_musicvolume)
        @audio_randompitch = get_bool(hash, "audio_randompitch", @audio_randompitch)

        @is_restored_from_file = true

        puts "OK"
      rescue e
        puts "Failed"
        load_default
      end
    end

    def save(path : String)
      begin
        File.open(path, "w") do |file|
          file.puts("key_forward = #{@key_forward}")
          file.puts("key_backward = #{@key_backward}")
          file.puts("key_strafeleft = #{@key_strafeleft}")
          file.puts("key_straferight = #{@key_straferight}")
          file.puts("key_turnleft = #{@key_turnleft}")
          file.puts("key_turnright = #{@key_turnright}")
          file.puts("key_fire = #{@key_fire}")
          file.puts("key_use = #{@key_use}")
          file.puts("key_run = #{@key_run}")
          file.puts("key_strafe = #{@key_strafe}")

          file.puts("mouse_sensitivity = #{@mouse_sensitivity}")
          file.puts("mouse_disableyaxis = #{bool_to_string(@mouse_disableyaxis)}")

          file.puts("game_alwaysrun = #{bool_to_string(@game_alwaysrun)}")

          file.puts("video_screenwidth = #{@video_screenwidth}")
          file.puts("video_screenheight = #{@video_screenheight}")
          file.puts("video_fullscreen = #{bool_to_string(@video_fullscreen)}")
          file.puts("video_highresolution = #{bool_to_string(@video_highresolution)}")
          file.puts("video_displaymessage = #{bool_to_string(@video_displaymessage)}")
          file.puts("video_gamescreensize = #{@video_gamescreensize}")
          file.puts("video_gammacorrection = #{@video_gammacorrection}")
          file.puts("video_fpsscale = #{@video_fpsscale}")

          file.puts("audio_soundvolume = #{@audio_soundvolume}")
          file.puts("audio_musicvolume = #{@audio_musicvolume}")
          file.puts("audio_randompitch = #{bool_to_string(@audio_randompitch)}")
        end
      rescue e
        raise e
      end
    end

    private def get_int(hash : Hash(String, String), name : String, default_value : Int32) : Int32
      if string_value = hash[name]?
        if value = string_value.to_i32?
          return value
        end
      end

      return default_value
    end

    private def get_string(hash : Hash(String, String), name : String, default_value : String) : String
      if string_value = hash[name]?
        return string_value
      end

      return default_value
    end

    private def get_bool(hash : Hash(String, String), name : String, default_value : Bool) : Bool
      if string_value = hash[name]?
        if string_value == "true"
          return true
        elsif string_value == "false"
          return false
        end
      end

      return default_value
    end

    private def get_key_binding(hash : Hash(String, String), name : String, default_value : KeyBinding) : KeyBinding
      if string_value = hash[name]?
        return KeyBinding.parse(string_value)
      end

      return default_value
    end

    private def bool_to_string(value : Bool) : String
      return value ? "true" : "false"
    end
  end
end
