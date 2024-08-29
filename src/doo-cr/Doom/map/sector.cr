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
  class Sector
    class_getter datasize : Int32 = 26

    getter number : Int32 = 0
    property floor_height : Fixed = Fixed.zero
    property ceiling_height : Fixed = Fixed.zero
    property floor_flat : Int32 = 0
    property ceiling_flat : Int32 = 0
    property light_level : Int32 = 0
    property special : SectorSpecial = SectorSpecial.new(0)
    property tag : Int32 = 0

    # 0 = untraversed, 1, 2 = sndlines - 1.
    property sound_traversed : Int32 = 0

    # Thing that made a sound (or nil).
    property sound_target : Mobj | Nil = nil

    # Mapblock bounding box for height changes.
    property block_box : Array(Int32) = Array(Int32).new

    # Origin for any sounds played by the sector.
    property sound_origin : Mobj | Nil = nil

    # If == validcount, already checked.
    property valid_count : Int32 = 0

    # List of mobjs in sector.
    property thing_list : Mobj | Nil = nil

    # Thinker for reversable actions.
    property special_data : Thinker | Nil = nil

    property lines : Array(LineDef) = Array(LineDef).new

    # For frame interpolation.
    @old_floor_height : Fixed = Fixed.zero
    @old_ceiling_height : Fixed = Fixed.zero

    def initialize(
      @number : Int32,
      @floor_height : Fixed,
      @ceiling_height : Fixed,
      @floor_flat : Int32,
      @ceiling_flat : Int32,
      @light_level : Int32,
      @special : SectorSpecial,
      @tag : Int32
    )
      @old_floor_height = @floor_height
      @old_ceiling_height = @ceiling_height
    end

    def self.from_data(data : Bytes, offset : Int32, number : Int32, flats : IFlatLookup) : Sector
      floor_height = IO::ByteFormat::LittleEndian.decode(Int16, data[offset, 2])
      ceiling_height = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 2, 2])
      floor_flat_name = DoomInterop.to_s(data, offset + 4, 8)
      ceiling_flat_name = DoomInterop.to_s(data, offset + 12, 8)
      light_level = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 20, 2])
      special = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 22, 2])
      tag = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 24, 2])

      return Sector.new(
        number,
        Fixed.from_i(floor_height),
        Fixed.from_i(ceiling_height),
        flats.get_number(floor_flat_name),
        flats.get_number(ceiling_flat_name),
        light_level,
        SectorSpecial.new(special),
        tag
      )
    end

    def self.from_wad(wad : Wad, lump : Int32, flats : IFlatLookup) : Array(Sector)
      length = wad.get_lump_size(lump)
      raise "" if length % @@datasize != 0

      data = wad.read_lump(lump)
      count = (length / @@datasize).to_i32
      sectors = Array(Sector).new(count)
      count.times do |i|
        offset = @@datasize * i
        sectors << from_data(data, offset, i, flats)
      end

      return sectors
    end

    def update_frame_interpolation_info
      @old_floor_height = @floor_height
      @old_ceiling_height = @ceiling_height
    end

    def get_interpolated_floor_height(frame_frac : Fixed) : Fixed
      return @old_floor_height + frame_frac * (@floor_height - @old_floor_height)
    end

    def get_interpolated_ceiling_height(frame_frac : Fixed) : Fixed
      return @old_ceiling_height + frame_frac * (@ceiling_height - @old_ceiling_height)
    end

    def disable_frame_interpolation_for_one_frame
      @old_floor_height = @floor_height
      @old_ceiling_height = @ceiling_height
    end

    def get_enumerator : ThingEnumerator
      return ThingEnumerator.new(self)
    end

    struct ThingEnumerator
      @sector : Sector
      @thing : Mobj
      getter current : Mobj | Nil

      def initialize(@sector : Sector)
        @thing = @sector.as(Sector).thing_list.as(Mobj)
        @current = nil
      end

      def move_next : Bool
        if @thing != nil
          @current = @thing
          @thing = @thing.sector_next.as(Mobj)
          return true
        else
          @current = nil
          return false
        end
      end

      def reset
        @thing = @sector.as(Sector).thing_list
        @current = nil
      end
    end
  end
end
