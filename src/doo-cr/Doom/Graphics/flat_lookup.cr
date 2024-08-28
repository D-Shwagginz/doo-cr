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

require "./i_flat_lookup.cr"

module Doocr
  class FlatLookup
    include IFlatLookup
    @flats : Array(Flat) = Array(Flat).new

    @name_to_flat : Hash(String, Flat) = {} of String => Flat
    @name_to_number : Hash(String, Int32) = {} of String => Int32

    getter sky_flat_number : Int32 = 0
    getter sky_flat : Flat | Nil = nil

    def each(&)
      @flats.each do |t|
        yield t
      end
    end

    def size
      return @flats.size
    end

    def [](num : Int32)
      return @flats[num]
    end

    def [](name : String) : Flat
      @name_to_flat[name]
    end

    def initialize(wad : Wad)
      fstartcount = count_lump(wad, "F_START")
      fendcount = count_lump(wad, "F_END")
      ffstartcount = count_lump(wad, "FF_START")
      ffendcount = count_lump(wad, "FF_END")

      # Usual case.
      standard = (
        fstartcount == 1 &&
        fendcount == 1 &&
        ffstartcount == 0 &&
        ffendcount == 0
      )

      # A trick to add custom flats is used.
      # https://www.doomworld.com/tutorials/fx2.php
      custom_flat_trick = (
        fstartcount == 1 &&
        fendcount >= 2
      )

      # Need deutex to add flats.
      deutex_merge = (
        fstartcount + ffstartcount >= 2 &&
        fendcount + ffendcount >= 2
      )

      if standard || custom_flat_trick
        init_standard(wad)
      elsif deutex_merge
        init_deutex_merge(wad)
      else
        raise "Failed to read flats."
      end
    end

    private def init_standard(wad : Wad)
      begin
        print("Load flats: ")

        firstflat = wad.get_lump_number("F_START") + 1
        lastflat = wad.get_lump_number("F_END") - 1
        count = lastflat - firstflat + 1

        @flats = Array(Flat).new(count)

        @name_to_flat = {} of String => Flat
        @name_to_number = {} of String => Int32

        lump = firstflat
        while lump <= lastflat
          if wad.get_lump_size(lump) != 4096
            lump += 1
            next
          end

          number = lump - firstflat
          name = wad.lump_infos[lump].name
          flat = Flat.new(name, wad.read_lump(lump))

          @flats << flat
          @name_to_flat[name] = flat
          @name_to_number[name] = number
          lump += 1
        end

        @sky_flat_number = @name_to_number["F_SKY1"]
        @sky_flat = @name_to_flat["F_SKY1"]

        puts("OK (#{@name_to_flat.size} flats)")
      rescue e
        puts("Failed")
        raise e
      end
    end

    private def init_deutex_merge(wad : Wad)
      begin
        print("Load flats: ")

        allflats = [] of Int32
        flatzone = false
        wad.lump_infos.size.times do |lump|
          name = wad.lump_infos[lump].name
          if flatzone
            if name == "F_END" || name == "FF_END"
              flatzone = false
            else
              allflats << lump
            end
          else
            if name == "F_START" || name == "FF_START"
              flatzone = true
            end
          end
        end
        allflats.reverse

        dupcheck = [] of String
        distinct_flats = [] of Int32
        allflats.each do |lump|
          if !dupcheck.includes?(wad.lump_infos[lump].name)
            distinct_flats << lump
            dupcheck << wad.lump_infos[lump].name
          end
        end
        distinct_flats.reverse

        @flats = Array(Flat).new(distinct_flats.size)

        @name_to_flat = {} of String => Flat
        @name_to_number = {} of String => Int32

        distinct_flats.size.times do |number|
          lump = distinct_flats[number]

          next if wad.get_lump_size(lump) != 4096

          name = wad.lump_infos[lump].name
          flat = Flat.new(name, wad.read_lump(lump))

          @flats << flat
          @name_to_flat[name] = flat
          @name_to_number[name] = number
        end

        @sky_flat_number = @name_to_number["F_SKY1"]
        @sky_flat = @name_to_flat["F_SKY1"]

        puts("OK (#{@name_to_flat.size} flats)")
      rescue e
        puts("Failed")
        raise e
      end
    end

    def get_number(name : String) : Int32
      if @name_to_number.has_key?(name)
        return @name_to_number[name]
      else
        return -1
      end
    end

    private def count_lump(wad : Wad, name : String) : Int32
      count = 0
      wad.lump_infos.each do |lump|
        count += 1 if lump.name == name
      end
      return count
    end
  end
end
