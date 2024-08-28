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
  module SFMLConfigUtilities
    def self.get_config : Config
      config = Config.new(ConfigUtilities.get_config_path)

      if !config.is_restored_from_file
        vm = get_default_video_mode()
        config.video_screenwidth = vm.width.to_i32
        config.video_screenheight = vm.height.to_i32
      end

      return config
    end

    def self.get_default_video_mode : SF::VideoMode
      monitor = SF::VideoMode.desktop_mode

      base_width = 640
      base_height = 400

      current_width = base_width
      current_height = base_height

      while true
        next_width = current_height + base_width
        next_height = current_height + base_height

        if (next_width >= 0.9 * monitor.width ||
           next_height >= 0.9 * monitor.height)
          break
        end

        current_width = next_width
        current_height = next_height
      end

      return SF::VideoMode.new(current_width, current_height)
    end

    def self.get_music_instance(config : Config, content : GameContent) : SFMLMusic
      return SFMLMusic.new(config, content)
    end
  end
end
