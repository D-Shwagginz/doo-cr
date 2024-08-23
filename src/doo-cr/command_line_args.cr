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
  class CommandLineArgs
    getter iwad : ArgV(String)
    getter file : ArgV(Array(String))
    getter deh : ArgV(Array(String))

    getter warp : ArgV(Tuple(Int32, Int32))
    getter episode : ArgV(Int32)
    getter skill : ArgV(Int32)

    getter deathmatch : Arg
    getter altdeath : Arg
    getter fast : Arg
    getter respawn : Arg
    getter nomonsters : Arg
    getter solonet : Arg

    getter playdemo : ArgV(String)
    getter timedemo : ArgV(String)

    getter loadgame : ArgV(Int32)

    getter nomouse : Arg
    getter nosound : Arg
    getter nosfx : Arg
    getter nomusic : Arg

    getter nodeh : Arg

    def initialize(args : Array(String))
      @iwad = get_string(args, "-iwad")
      @file = check_file(args)
      @deh = check_deh(args)

      @warp = check_warp(args)
      @episode = get_int(args, "-episode")
      @skill = get_int(args, "-skill")

      @deathmatch = Arg.new(args.includes?("-deathmatch"))
      @altdeath = Arg.new(args.includes?("-altdeath"))
      @fast = Arg.new(args.includes?("-fast"))
      @respawn = Arg.new(args.includes?("-respawn"))
      @nomonsters = Arg.new(args.includes?("-nomonsters"))
      @solonet = Arg.new(args.includes?("-solo-net"))

      @playdemo = get_string(args, "-playdemo")
      @timedemo = get_string(args, "-timedemo")

      @loadgame = get_int(args, "-loadgame")

      @nomouse = Arg.new(args.includes?("-nomouse"))
      @nosound = Arg.new(args.includes?("-nosound"))
      @nosfx = Arg.new(args.includes?("-nosfx"))
      @nomusic = Arg.new(args.includes?("-nomusic"))

      @nodeh = Arg.new(args.includes?("-nodeh"))

      # Check for drag & drop
      if args.size > 0 && args.all? { |arg| arg.chars.first { "" } != '-' }
        iwad_path : String = ""
        pwad_paths = [] of String
        deh_paths = [] of String

        args.each do |path|
          extension = Path[path].extension.downcase

          if extension == ".wad"
            if ConfigUtilities.is_iwad(path)
              iwad_path = path
            else
              pwad_paths << path
            end
          elsif extension == ".deh"
            deh_paths << path
          end
        end

        @iwad = ArgV(String).new(iwad_path) if iwad_path != ""
        @file = ArgV(Array(String)).new(pwad_paths) if pwad_paths.size > 0
        @deh = ArgV(Array(String)).new(deh_paths) if deh_paths.size > 0
      end
    end

    private def check_file(args : Array(String)) : ArgV(Array(String))
      values = get_values(args, "-file")
      return ArgV(Array(String)).new(values) if values.size >= 1
      return ArgV(Array(String)).new
    end

    private def check_deh(args : Array(String)) : ArgV(Array(String))
      values = get_values(args, "-deh")
      return ArgV(Array(String)).new(values) if values.size >= 1
      return ArgV(Array(String)).new
    end

    private def check_warp(args : Array(String)) : ArgV(Tuple(Int32, Int32))
      values = get_values(args, "-warp")
      if values.size == 1
        map = values[0].to_i?
        return ArgV(Tuple(Int32, Int32)).new({1, map}) if map
      elsif values.size == 2
        episode = values[0].to_i?
        map = values[1].to_i?
        return ArgV(Tuple(Int32, Int32)).new({episode, map}) if episode && map
      end

      return ArgV(Tuple(Int32, Int32)).new
    end

    private def get_string(args : Array(String), name : String) : ArgV(String)
      values = get_values(args, name)
      return ArgV(String).new(values[0]) if values.size == 1
      return ArgV(String).new
    end

    private def get_int(args : Array(String), name : String) : ArgV(Int32)
      values = get_values(args, name)
      if values.size == 1
        result = values[0].to_i?
        return ArgV(Int32).new(result) if result
      end

      return ArgV(Int32).new
    end

    private def get_values(args : Array(String), name : String) : Array(String)
      return args
        .skip_while { |arg| arg != name }
        .skip(1)
        .take_while { |arg| arg[0] != '-' }
    end

    class ArgV(T)
      getter present : Bool
      getter value : T | Nil = nil

      def initialize
        @present = false
        @value = nil
      end

      def initialize(value : T)
        @present = true
        @value = value
      end
    end

    class Arg
      getter present : Bool

      def initialize
        @present = false
      end

      def initialize(present : Bool)
        @present = present
      end
    end
  end
end
