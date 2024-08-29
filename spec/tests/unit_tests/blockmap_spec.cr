module Doocr::Test
  describe BlockMap, tags: "blockmap" do
    it "Load E1M1" do
      wad = Wad.new(WadPath::DOOM1)

      flats = DummyFlatLookup.new(wad)
      textures = DummyTextureLookup.new(wad)
      map = wad.get_lump_number("E1M1")
      vertices = Vertex.from_wad(wad, map + 4)
      sectors = Sector.from_wad(wad, map + 8, flats)
      sides = SideDef.from_wad(wad, map + 3, textures, sectors)
      lines = LineDef.from_wad(wad, map + 2, vertices, sides)
      blockmap = BlockMap.from_wad(wad, map + 10, lines)

      vertices_x = Array.new(vertices.size, 0_f64)
      vertices_x.fill { |v| vertices[v].x.to_f64 }

      vertices_y = Array.new(vertices.size, 0_f64)
      vertices_y.fill { |v| vertices[v].y.to_f64 }

      min_x = vertices_x.min
      max_x = vertices_x.max
      min_y = vertices_y.min
      max_y = vertices_y.max

      blockmap.origin_x.to_f64.should be_close(min_x, 64)
      blockmap.origin_y.to_f64.should be_close(min_y, 64)
      (blockmap.origin_x + BlockMap.block_size * blockmap.width).to_f64.should be_close(max_x, 128)
      (blockmap.origin_y + BlockMap.block_size * blockmap.height).to_f64.should be_close(max_y, 128)

      spots = Array(Tuple(Int32, Int32)).new
      block_y = -2
      while block_y < blockmap.height + 2
        block_x = -2
        while block_x < blockmap.width + 2
          spots << {block_x, block_y}
          block_x += 1
        end
        block_y += 1
      end

      random = Random.new(666)

      50.times do |i|
        ordered = spots.sort_by { |x| random.next_float }

        total = 0

        ordered.each do |spot|
          block_x = spot[0]
          block_y = spot[1]

          min_x = Float64::MAX
          max_x = Float64::MIN
          min_y = Float64::MAX
          max_y = Float64::MIN
          count = 0

          blockmap.iterate_lines(
            block_x,
            block_y,
            ->(line : LineDef) {
              if count != 0
                min_x = Math.min(Math.min(line.vertex1.as(Vertex).x.to_f64, line.vertex2.as(Vertex).x.to_f64), min_x)
                max_x = Math.max(Math.max(line.vertex1.as(Vertex).x.to_f64, line.vertex2.as(Vertex).x.to_f64), max_x)
                min_y = Math.min(Math.min(line.vertex1.as(Vertex).y.to_f64, line.vertex2.as(Vertex).y.to_f64), min_y)
                max_y = Math.max(Math.max(line.vertex1.as(Vertex).y.to_f64, line.vertex2.as(Vertex).y.to_f64), max_y)
              end
              count += 1
              return true
            },
            i + 1
          )

          if count > 1
            (min_x <= (blockmap.origin_x + BlockMap.block_size * (block_x + 1)).to_f64).should be_true
            (max_x >= (blockmap.origin_x + BlockMap.block_size * block_x).to_f64).should be_true
            (min_y <= (blockmap.origin_y + BlockMap.block_size * (block_y + 1)).to_f64).should be_true
            (max_y >= (blockmap.origin_y + BlockMap.block_size * block_y).to_f64).should be_true
          end

          total += count
        end

        lines.size.should eq total
      end
    end

    it "Load Map01" do
      wad = Wad.new(WadPath::DOOM2)

      flats = DummyFlatLookup.new(wad)
      textures = DummyTextureLookup.new(wad)
      map = wad.get_lump_number("MAP01")
      vertices = Vertex.from_wad(wad, map + 4)
      sectors = Sector.from_wad(wad, map + 8, flats)
      sides = SideDef.from_wad(wad, map + 3, textures, sectors)
      lines = LineDef.from_wad(wad, map + 2, vertices, sides)
      blockmap = BlockMap.from_wad(wad, map + 10, lines)

      vertices_x = Array.new(vertices.size, 0_f64)
      vertices_x.fill { |v| vertices[v].x.to_f64 }

      vertices_y = Array.new(vertices.size, 0_f64)
      vertices_y.fill { |v| vertices[v].y.to_f64 }

      min_x = vertices_x.min
      max_x = vertices_x.max
      min_y = vertices_y.min
      max_y = vertices_y.max

      blockmap.origin_x.to_f64.should be_close(min_x, 64)
      blockmap.origin_y.to_f64.should be_close(min_y, 64)
      (blockmap.origin_x + BlockMap.block_size * blockmap.width).to_f64.should be_close(max_x, 128)
      (blockmap.origin_y + BlockMap.block_size * blockmap.height).to_f64.should be_close(max_y, 128)

      spots = Array(Tuple(Int32, Int32)).new
      block_y = -2
      while block_y < blockmap.height + 2
        block_x = -2
        while block_x < blockmap.width + 2
          spots << {block_x, block_y}
          block_x += 1
        end
        block_y += 1
      end

      random = Random.new(666)

      50.times do |i|
        ordered = spots.sort_by { |x| random.next_float }

        total = 0

        ordered.each do |spot|
          block_x = spot[0]
          block_y = spot[1]

          min_x = Float64::MAX
          max_x = Float64::MIN
          min_y = Float64::MAX
          max_y = Float64::MIN
          count = 0

          blockmap.iterate_lines(
            block_x,
            block_y,
            ->(line : LineDef) {
              if count != 0
                min_x = Math.min(Math.min(line.vertex1.as(Vertex).x.to_f64, line.vertex2.as(Vertex).x.to_f64), min_x)
                max_x = Math.max(Math.max(line.vertex1.as(Vertex).x.to_f64, line.vertex2.as(Vertex).x.to_f64), max_x)
                min_y = Math.min(Math.min(line.vertex1.as(Vertex).y.to_f64, line.vertex2.as(Vertex).y.to_f64), min_y)
                max_y = Math.max(Math.max(line.vertex1.as(Vertex).y.to_f64, line.vertex2.as(Vertex).y.to_f64), max_y)
              end
              count += 1
              return true
            },
            i + 1
          )

          if count > 1
            (min_x <= (blockmap.origin_x + BlockMap.block_size * (block_x + 1)).to_f64).should be_true
            (max_x >= (blockmap.origin_x + BlockMap.block_size * block_x).to_f64).should be_true
            (min_y <= (blockmap.origin_y + BlockMap.block_size * (block_y + 1)).to_f64).should be_true
            (max_y >= (blockmap.origin_y + BlockMap.block_size * block_y).to_f64).should be_true
          end

          total += count
        end

        lines.size.should eq total
      end
    end
  end
end
