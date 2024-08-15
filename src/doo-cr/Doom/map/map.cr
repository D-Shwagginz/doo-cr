module Doocr
  class Map
    getter textures : ITextureLookup
    getter flats : IFlatLookup
    getter animation : TextureAnimation

    @world : World

    getter vertices : Array(Vertex)
    getter sectors : Array(Sector)
    getter sides : Array(SideDef)
    getter lines : Array(LineDef)
    getter segs : Array(Seg)
    getter subsectors : Array(Subsector)
    getter nodes : Array(Node)
    getter things : Array(MapThing)
    getter blockmap : BlockMap
    getter reject : Reject

    getter sky_texture : Texture

    getter title : String

    def sky_flat_number
      return @flats.sky_flat_number
    end

    def initialize(resources : GameContent, world : World)
      initialize(resources.wad, resources.textures, resources.flats, resources.animation, world)
    end

    def initialize(wad : Wad, textures : ITextureLookup, flats : IFlatLookup, animation : TextureAnimation, world : World)
      begin
        @textures = textures
        @flats = flats
        @animation = animation
        @world = world

        options = world.options

        name : String
        if wad.gamemode == GameMode::Commercial
          name = "MAP" + options.map.to_s(precision: 2)
        else
          name = "E" + options.episode + "M" + options.map
        end

        print("Load map '#{name}': ")

        map = wad.get_lump_number(name)

        if map == -1
          raise "Map '#{name}' was not found!"
        end

        @vertices = Vertex.from_wad(wad, map + 4)
        @sectors = Sector.from_wad(wad, map + 8, flats)
        @sides = SideDef.from_wad(wad, map + 3, textures, @sectors)
        @lines = LineDef.from_wad(wad, map + 2, @vertices, @sides)
        @segs = Seg.from_wad(wad, map + 5, @vertices, @lines)
        @subsectors = Subsector.from_wad(wad, map + 6, @segs)
        @nodes = Node.from_wad(wad, map + 7, @subsectors)
        @things = MapThing.from_wad(wad, map + 1)
        @blockmap = BlockMap.from_wad(wad, map + 10, @lines)
        @reject = Reject.from_wad(wad, map + 9, @sectors)

        group_lines()

        @sky_texture = get_sky_texture_by_map_name(name)

        if options.gamemode == GameMode::Commercial
          case options.mission_pack
          when MissionPack::Plutonia
            @title = DoomInfo::MapTitles.plutonia[options.map - 1]
            break
          when MissionPack::Tnt
            @title = DoomInfo::MapTitles.tnt[options.map - 1]
            break
          else
            @title = DoomInfo::MapTitles.doom2[option.map - 1]
          end
        else
          @title = DoomInfo::MapTitle.doom[options.episode - 1][options.map - 1]
        end

        puts("OK")
      rescue e
        puts("Failed")
        raise e
      end
    end

    private def group_lines
      sector_lines = [] of LineDef
      bounding_box = Array(Fixed).new(4)

      @lines.each do |line|
        if line.special.to_i32 != 0
          so = Mobj.new(@world)
          so.x = (line.vertex1.x + line.vertex2.x) / 2
          so.y = (line.vertex1.y + line.vertex2.y) / 2
          line.sound_origin = so
        end
      end

      @sectors.each do |sector|
        sector_lines.clear
        Box.clear(bounding_box)

        @lines.each do |line|
          if line.front_sector == sector || line.back_sector == sector
            sector_lines << line
            Box.add_point(bounding_box, line.vertex1.x, line.vertex1.y)
            Box.add_point(bounding_box, line.vertex2.x, line.vertex2.y)
          end
        end

        sector.lines = sector_lines.to_a

        # Set the degenmobj_t to the middle of the bounding box.
        sector.sound_origin = Mobj.new(@world)
        sector.sound_origin.x = (bounding_box[Box::RIGHT] + bounding_box[Box::LEFT]) / 2
        sector.sound_origin.y = (bounding_box[Box::TOP] + bounding_box[Box::BOTTOM]) / 2

        sector.block_box = Array(Int32).new(4)

        # Adjust bounding box to map blocks.
        block = (bounding_box[Box::TOP] - @blockmap.origin_y + GameConst.max_thing_radius).data >> BlockMap.frac_to_block_shift
        block = block >= @blockmap.height ? @blockmap.height - 1 : block
        sector.block_box[Box::TOP] = block

        block = (bounding_box[Box::BOTTOM] - @blockmap.origin_y - GameConst.max_thing_radius).data >> BlockMap.frac_to_block_shift
        block = block < 0 ? 0 : block
        sector.block_box[Box::BOTTOM] = block

        block = (bounding_box[Box::RIGHT] - @blockmap.origin_x + GameConst.max_thing_radius).data >> BlockMap.frac_to_block_shift
        block = block >= @blockmap.width ? @blockmap.width - 1 : block
        sector.block_box[Box::RIGHT] = block

        block = (bounding_box[Box::LEFT] - @blockmap.origin_x - GameConst.max_thing_radius).data >> BlockMap.frac_to_block_shift
        block = block < 0 ? 0 : block
        sector.block_box[Box::LEFT] = block
      end
    end

    private def get_sky_texture_by_map_name(name : String) : Texture
      if name.size == 4
        case name[1]
        when '1'
          return @textures["SKY1"]
        when '2'
          return @textures["SKY2"]
        when '3'
          return @textures["SKY3"]
        else
          return @textures["SKY4"]
        end
      else
        number = name[3..].to_i32
        if number <= 11
          return @textures["SKY1"]
        elsif number <= 21
          return @textures["SKY2"]
        else
          return @textuers["SKY3"]
        end
      end
    end

    @@e4_bgm_list : Array(Bgm) = [
      Bgm::E3M4, # American   e4m1
      Bgm::E3M2, # Romero     e4m2
      Bgm::E3M3, # Shawn      e4m3
      Bgm::E1M5, # American   e4m4
      Bgm::E2M7, # Tim        e4m5
      Bgm::E2M4, # Romero     e4m6
      Bgm::E2M6, # J.Anderson e4m7 CHIRON.WAD
      Bgm::E2M5, # Shawn      e4m8
      Bgm::E1M9, # Tim        e4m9
    ]

    def self.get_map_bgm(options : GameOptions) : Bgm
      bgm : Bgm
      if options.gamemode == GameMode::Commercial
        bgm = Bgm::RUNNIN + options.map - 1
      else
        if options.episode < 4
          bgm = Bgm::E1M1 + (options.episode - 1) * 9 + options.map - 1
        else
          bgm = @@e4_bgm_list[options.map - 1]
        end
      end

      return bgm
    end
  end
end
