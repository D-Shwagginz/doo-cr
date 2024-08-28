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
  class Map
    getter textures : ITextureLookup | Nil
    getter flats : IFlatLookup | Nil
    getter animation : TextureAnimation | Nil

    @world : World | Nil

    getter vertices : Array(Vertex) = [] of Vertex
    getter sectors : Array(Sector) = [] of Sector
    getter sides : Array(SideDef) = [] of SideDef
    getter lines : Array(LineDef) = [] of LineDef
    getter segs : Array(Seg) = [] of Seg
    getter subsectors : Array(Subsector) = [] of Subsector
    getter nodes : Array(Node) = [] of Node
    getter things : Array(MapThing) = [] of MapThing
    getter blockmap : BlockMap | Nil
    getter reject : Reject | Nil

    getter sky_texture : Texture | Nil

    getter title : String = ""

    def sky_flat_number
      return @flats.as(IFlatLookup).sky_flat_number
    end

    def initialize(resources : GameContent, world : World)
      initialize(resources.wad.as(Wad), resources.textures, resources.flats, resources.animation, world)
    end

    def initialize(wad : Wad, textures : ITextureLookup, flats : IFlatLookup, animation : TextureAnimation, world : World)
      begin
        @textures = textures
        @flats = flats
        @animation = animation
        @world = world

        options = world.options

        name : String
        if wad.game_mode == GameMode::Commercial
          name = "MAP" + options.map.to_s(precision: 2)
        else
          name = "E#{options.episode}M#{options.map}"
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

        if options.game_mode == GameMode::Commercial
          case options.mission_pack
          when MissionPack::Plutonia
            @title = DoomInfo::MapTitles.plutonia[options.map - 1].to_s
          when MissionPack::Tnt
            @title = DoomInfo::MapTitles.tnt[options.map - 1].to_s
          else
            @title = DoomInfo::MapTitles.doom2[options.map - 1].to_s
          end
        else
          @title = DoomInfo::MapTitles.doom[options.episode - 1][options.map - 1].to_s
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
          so = Mobj.new(@world.as(World))
          so.x = (line.vertex1.as(Vertex).x + line.vertex2.as(Vertex).x) / 2
          so.y = (line.vertex1.as(Vertex).y + line.vertex2.as(Vertex).y) / 2
          line.sound_origin = so
        end
      end

      @sectors.each do |sector|
        sector_lines.clear
        Box.clear(bounding_box)

        @lines.each do |line|
          if line.front_sector == sector || line.back_sector == sector
            sector_lines << line
            Box.add_point(bounding_box, line.vertex1.as(Vertex).x, line.vertex1.as(Vertex).y)
            Box.add_point(bounding_box, line.vertex2.as(Vertex).x, line.vertex2.as(Vertex).y)
          end
        end

        sector.lines = sector_lines.to_a

        # Set the degenmobj_t to the middle of the bounding box.
        sector.sound_origin = Mobj.new(@world.as(World))
        sector.sound_origin.as(Mobj).x = (bounding_box[Box::RIGHT] + bounding_box[Box::LEFT]) / 2
        sector.sound_origin.as(Mobj).y = (bounding_box[Box::TOP] + bounding_box[Box::BOTTOM]) / 2

        sector.block_box = Array(Int32).new(4)

        # Adjust bounding box to map blocks.
        block = (bounding_box[Box::TOP] - @blockmap.as(BlockMap).origin_y + GameConst.max_thing_radius).data >> BlockMap.frac_to_block_shift
        block = block >= @blockmap.as(BlockMap).height ? @blockmap.as(BlockMap).height - 1 : block
        sector.block_box[Box::TOP] = block

        block = (bounding_box[Box::BOTTOM] - @blockmap.as(BlockMap).origin_y - GameConst.max_thing_radius).data >> BlockMap.frac_to_block_shift
        block = block < 0 ? 0 : block
        sector.block_box[Box::BOTTOM] = block

        block = (bounding_box[Box::RIGHT] - @blockmap.as(BlockMap).origin_x + GameConst.max_thing_radius).data >> BlockMap.frac_to_block_shift
        block = block >= @blockmap.as(BlockMap).width ? @blockmap.as(BlockMap).width - 1 : block
        sector.block_box[Box::RIGHT] = block

        block = (bounding_box[Box::LEFT] - @blockmap.as(BlockMap).origin_x - GameConst.max_thing_radius).data >> BlockMap.frac_to_block_shift
        block = block < 0 ? 0 : block
        sector.block_box[Box::LEFT] = block
      end
    end

    private def get_sky_texture_by_map_name(name : String) : Texture
      if name.size == 4
        case name[1]
        when '1'
          return @textures.as(ITextureLookup)["SKY1"]
        when '2'
          return @textures.as(ITextureLookup)["SKY2"]
        when '3'
          return @textures.as(ITextureLookup)["SKY3"]
        else
          return @textures.as(ITextureLookup)["SKY4"]
        end
      else
        number = name[3..].to_i32
        if number <= 11
          return @textures.as(ITextureLookup)["SKY1"]
        elsif number <= 21
          return @textures.as(ITextureLookup)["SKY2"]
        else
          return @textures.as(ITextureLookup)["SKY3"]
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
      if options.game_mode == GameMode::Commercial
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
