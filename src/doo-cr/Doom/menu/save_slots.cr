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
  class SaveSlots
    @@slot_count : Int32 = 6
    @@description_size : Int32 = 24

    @slots : Array(String) = [] of String

    private def read_slots
      @slots = Array.new(@@slot_count, "")

      directory = ConfigUtilities.get_exe_directory
      buffer = Bytes.new(@@description_size)
      @slots.size.times do |i|
        path = Path.new(directory, "doomsav#{i}.dsg")
        if File.exists?(path)
          File.open(path) do |file|
            buffer = file.getb_to_end
            @slots[i] = DoomInterop.to_s(buffer, 0, buffer.size)
          end
        end
      end
    end

    def [](number : Int32) : String
      if @slots.empty?
        read_slots()
      end

      return @slots[number]
    end

    def []?(number : Int32) : String | Nil
      if @slots.empty?
        read_slots()
      end

      return @slots[number]?
    end

    def []=(number : Int32, value : String)
      @slots[number] = value
    end

    def count : Int32
      return @slots.size
    end
  end
end
