module Doocr
  class Sector
    class_getter datasize : Int32 = 26

    getter number : Int32 = 0
    property floor_height : Fixed | Nil
    property ceiling_height : Fixed | Nil
    property floor_flat : Int32 = 0
    property ceiling_flat : Int32 = 0
    property light_level : Int32 = 0
    property special : SectorSpecial | Nil
    property tag : Int32 = 0

    # 0 = untraversed, 1, 2 = sndlines - 1.
    property sound_traversed : Int32 = 0

    # Thing that made a sound (or nil).
    property sound_target : Mobj | Nil

    # Mapblock bounding box for height changes.
    property block_box : Array(Int32) = Array(Int32).new

    # Origin for any sounds played by the sector.
    property sound_origin : Mobj | Nil

    # If == validcount, already checked.
    property valid_count : Int32 = 0

    # List of mobjs in sector.
    property thing_list : Mobj | Nil

    # Thinker for reversable actions.
    property special_data : Thinker | Nil

    property lines : Array(LineDef) = Array(LineDef).new

    # For frame interpolation.
    @old_floor_height : Fixed | Nil
    @old_ceiling_height : Fixed | Nil

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
      floor_flat_name = String.new(data[offset + 4, 8])
      ceiling_flat_name = String.new(data[offset + 12, 8])
      light_level = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 20, 2])
      special = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 22, 2])
      tag = IO::ByteFormat::LittleEndian.decode(Int16, data[offset + 24, 2])

      return Sector.new(
        number,
        Fixed.from_i(floor_height),
        Fixed.from_i(ceiling_height)
          .flats.get_number(floor_flat_name),
        flats.get_number(ceiling_flat_name),
        light_level,
        SectorSpecial.new(special),
        tag
      )
    end

    def self.from_wad(wad : Wad, lump : Int32, flats : IFlatLookup) : Array(Sector)
      length = wad.get_lump_size(lump)
      raise if length % @@datasize != 0

      data = wad.read_lump(lump)
      count = length / @@datasize
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
      getter current : Mobj

      def initialize(@sector : Sector)
        @thing = @sector.thing_list
        @current = nil
      end

      def move_next : Bool
        if @thing != nil
          @current = @thing
          @thing = @thing.sector_next
          return true
        else
          @current = nil
          return false
        end
      end

      def reset
        @thing = @sector.thing_list
        @current = nil
      end
    end
  end
end
