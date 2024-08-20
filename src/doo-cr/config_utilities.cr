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
  module ConfigUtilities
    class_getter iwad_names : Array(String) = [
      "DOOM2.WAD",
      "PLUTONIA.WAD",
      "TNT.WAD",
      "DOOM.WAD",
      "DOOM1.WAD",
      "FREEDOOM2.WAD",
      "FREEDOOM1.WAD",
    ]

    def self.get_exe_directory : String
      return Path["__FILE__"].dirname
    end

    def self.get_config_path : String
      return Path.new(get_exe_directory(), "doo-cr.cfg")
    end

    def self.get_default_iwad_path : String
      exe_directory = get_exe_directory()
      @@iwad_names.each do |name|
        path = Path.new(exe_directory, name)
        return path if File.exists?(path)
      end

      current_directory = Dir.current
      @@iwad_names.each do |name|
        path = Path.new(current_directory, name)
        return path if File.exists?(path)
      end

      raise "No IWAD was found!"
    end

    def self.is_iwad(path : String) : Bool
      name = Path[path].basename.upcase
      return @@iwad_names.includes?(name)
    end

    def self.get_wad_paths(args : CommandLineArgs) : Array(String)
      wad_paths = [] of String

      if args.iwad.present
        wad_paths << args.iwad.value
      else
        wad_paths << ConfigUtilities.get_default_iwad_path
      end

      wad_paths << args.file.value if args.file.present

      return wad_paths
    end
  end
end
