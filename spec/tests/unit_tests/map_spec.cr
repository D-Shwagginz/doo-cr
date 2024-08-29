module Doocr::Test::MapTest
  MAX_RADIUS = 32_f64

  describe Map, tags: "map" do
    it "Load E1M1" do
      content = GameContent.create_dummy(WadPath::DOOM1)

      options = GameOptions.new
      world = World.new(content, options, nil)
      map = Map.new(content, world)

      map_min_x = map.lines.min_of { |line| Fixed.min(line.vertex1.as(Vertex).x, line.vertex2.as(Vertex).x).to_f64 }
      map_max_x = map.lines.max_of { |line| Fixed.max(line.vertex1.as(Vertex).x, line.vertex2.as(Vertex).x).to_f64 }
      map_min_y = map.lines.min_of { |line| Fixed.min(line.vertex1.as(Vertex).y, line.vertex2.as(Vertex).y).to_f64 }
      map_max_y = map.lines.max_of { |line| Fixed.max(line.vertex1.as(Vertex).y, line.vertex2.as(Vertex).y).to_f64 }

      map.sectors.size.times do |i|
        sector = map.sectors[i]
        s_lines = map.lines.select { |line| line.front_sector == sector || line.back_sector == sector }

        (s_lines == sector.lines).should be_true

        min_x = s_lines.min_of { |line| Fixed.min(line.vertex1.as(Vertex).x, line.vertex2.as(Vertex).x).to_f64 } - MAX_RADIUS
        min_x = Math.max(min_x, map_min_x)
        max_x = s_lines.max_of { |line| Fixed.max(line.vertex1.as(Vertex).x, line.vertex2.as(Vertex).x).to_f64 } + MAX_RADIUS
        max_x = Math.min(max_x, map_max_x)
        min_y = s_lines.min_of { |line| Fixed.min(line.vertex1.as(Vertex).y, line.vertex2.as(Vertex).y).to_f64 } - MAX_RADIUS
        min_y = Math.max(min_y, map_min_y)
        max_y = s_lines.max_of { |line| Fixed.max(line.vertex1.as(Vertex).y, line.vertex2.as(Vertex).y).to_f64 } + MAX_RADIUS
        max_y = Math.min(max_y, map_max_y)

        blockmap = map.blockmap.as(BlockMap)
        bbox_top = (blockmap.origin_y + BlockMap.block_size * (sector.block_box[Box::TOP] + 1)).to_f64
        bbox_bottom = (blockmap.origin_y + BlockMap.block_size * sector.block_box[Box::BOTTOM]).to_f64
        bbox_left = (blockmap.origin_x + BlockMap.block_size * sector.block_box[Box::LEFT]).to_f64
        bbox_right = (blockmap.origin_x + BlockMap.block_size * (sector.block_box[Box::RIGHT] + 1)).to_f64

        bbox_left.should be <= min_x
        bbox_right.should be >= max_x
        bbox_top.should be >= max_y
        bbox_bottom.should be <= min_y

        (bbox_left - min_x).abs.should be <= 128
        (bbox_right - max_x).abs.should be <= 128
        (bbox_top - max_y).abs.should be <= 128
        (bbox_bottom - min_y).abs.should be <= 128
      end
    end

    it "Load Map01" do
      content = GameContent.create_dummy(WadPath::DOOM2)

      options = GameOptions.new
      world = World.new(content, options, nil)
      map = Map.new(content, world)

      map_min_x = map.lines.min_of { |line| Fixed.min(line.vertex1.as(Vertex).x, line.vertex2.as(Vertex).x).to_f64 }
      map_max_x = map.lines.max_of { |line| Fixed.max(line.vertex1.as(Vertex).x, line.vertex2.as(Vertex).x).to_f64 }
      map_min_y = map.lines.min_of { |line| Fixed.min(line.vertex1.as(Vertex).y, line.vertex2.as(Vertex).y).to_f64 }
      map_max_y = map.lines.max_of { |line| Fixed.max(line.vertex1.as(Vertex).y, line.vertex2.as(Vertex).y).to_f64 }

      map.sectors.size.times do |i|
        sector = map.sectors[i]
        s_lines = map.lines.select { |line| line.front_sector == sector || line.back_sector == sector }

        (s_lines == sector.lines).should be_true

        min_x = s_lines.min_of { |line| Fixed.min(line.vertex1.as(Vertex).x, line.vertex2.as(Vertex).x).to_f64 } - MAX_RADIUS
        min_x = Math.max(min_x, map_min_x)
        max_x = s_lines.max_of { |line| Fixed.max(line.vertex1.as(Vertex).x, line.vertex2.as(Vertex).x).to_f64 } + MAX_RADIUS
        max_x = Math.min(max_x, map_max_x)
        min_y = s_lines.min_of { |line| Fixed.min(line.vertex1.as(Vertex).y, line.vertex2.as(Vertex).y).to_f64 } - MAX_RADIUS
        min_y = Math.max(min_y, map_min_y)
        max_y = s_lines.max_of { |line| Fixed.max(line.vertex1.as(Vertex).y, line.vertex2.as(Vertex).y).to_f64 } + MAX_RADIUS
        max_y = Math.min(max_y, map_max_y)

        blockmap = map.blockmap.as(BlockMap)
        bbox_top = (blockmap.origin_y + BlockMap.block_size * (sector.block_box[Box::TOP] + 1)).to_f64
        bbox_bottom = (blockmap.origin_y + BlockMap.block_size * sector.block_box[Box::BOTTOM]).to_f64
        bbox_left = (blockmap.origin_x + BlockMap.block_size * sector.block_box[Box::LEFT]).to_f64
        bbox_right = (blockmap.origin_x + BlockMap.block_size * (sector.block_box[Box::RIGHT] + 1)).to_f64

        bbox_left.should be <= min_x
        bbox_right.should be >= max_x
        bbox_top.should be >= max_y
        bbox_bottom.should be <= min_y

        (bbox_left - min_x).abs.should be <= 128
        (bbox_right - max_x).abs.should be <= 128
        (bbox_top - max_y).abs.should be <= 128
        (bbox_bottom - min_y).abs.should be <= 128
      end
    end
  end
end
