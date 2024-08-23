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

module Doocr::Raylib
  def self.main
    puts(ApplicationInfo::TITLE)
    reader = Term::Reader.new

    begin
      quit_message : String = ""

      app = RaylibDoom.new(CommandLineArgs.new(ARGV))
      # app.Run
      quit_message = app.quit_message
      app = nil

      if quit_message != ""
        puts(quit_message)
        puts("Press any key to exit.")
        key_down = false
        until key_down
          reader.on_key { |key, event| key_down = true }
        end
      end
    rescue e
      puts(e)
      puts("Press any key to exit.")
      key_down = false
      until key_down
        reader.on_key { |key, event| key_down = true }
      end
    end
  end
end
