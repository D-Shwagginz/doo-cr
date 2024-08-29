module Doocr::Test::NodeTest
  DELTA = 1.0E-9

  describe Node, tags: "node" do
    it "Load E1M1" do
      wad = Wad.new(WadPath::DOOM1)

      flats = DummyFlatLookup.new(wad)
      textures = DummyTextureLookup.new(wad)
      map = wad.get_lump_number("E1M1")
      vertices = Vertex.from_wad(wad, map + 4)
      sectors = Sector.from_wad(wad, map + 8, flats)
      sides = SideDef.from_wad(wad, map + 3, textures, sectors)
      lines = LineDef.from_wad(wad, map + 2, vertices, sides)
      segs = Seg.from_wad(wad, map + 5, vertices, lines)
      subsectors = Subsector.from_wad(wad, map + 6, segs)
      nodes = Node.from_wad(wad, map + 7, subsectors)

      nodes.size.should eq 238

      nodes[0].x.to_f64.should be_close(1784, DELTA)
      nodes[0].y.to_f64.should be_close(-3448, DELTA)
      nodes[0].dx.to_f64.should be_close(-240, DELTA)
      nodes[0].dy.to_f64.should be_close(64, DELTA)
      nodes[0].bounding_box[0][Box::TOP].to_f64.should be_close(-3104, DELTA)
      nodes[0].bounding_box[0][Box::BOTTOM].to_f64.should be_close(-3448, DELTA)
      nodes[0].bounding_box[0][Box::LEFT].to_f64.should be_close(1520, DELTA)
      nodes[0].bounding_box[0][Box::RIGHT].to_f64.should be_close(2128, DELTA)
      nodes[0].bounding_box[1][Box::TOP].to_f64.should be_close(-3384, DELTA)
      nodes[0].bounding_box[1][Box::BOTTOM].to_f64.should be_close(-3448, DELTA)
      nodes[0].bounding_box[1][Box::LEFT].to_f64.should be_close(1544, DELTA)
      nodes[0].bounding_box[1][Box::RIGHT].to_f64.should be_close(1784, DELTA)
      (nodes[0].children[0] + 0x10000).should eq 32768
      (nodes[0].children[1] + 0x10000).should eq 32769

      nodes[57].x.to_f64.should be_close(928, DELTA)
      nodes[57].y.to_f64.should be_close(-3360, DELTA)
      nodes[57].dx.to_f64.should be_close(0, DELTA)
      nodes[57].dy.to_f64.should be_close(256, DELTA)
      nodes[57].bounding_box[0][Box::TOP].to_f64.should be_close(-3104, DELTA)
      nodes[57].bounding_box[0][Box::BOTTOM].to_f64.should be_close(-3360, DELTA)
      nodes[57].bounding_box[0][Box::LEFT].to_f64.should be_close(928, DELTA)
      nodes[57].bounding_box[0][Box::RIGHT].to_f64.should be_close(1344, DELTA)
      nodes[57].bounding_box[1][Box::TOP].to_f64.should be_close(-3104, DELTA)
      nodes[57].bounding_box[1][Box::BOTTOM].to_f64.should be_close(-3360, DELTA)
      nodes[57].bounding_box[1][Box::LEFT].to_f64.should be_close(704, DELTA)
      nodes[57].bounding_box[1][Box::RIGHT].to_f64.should be_close(928, DELTA)
      (nodes[57].children[0] + 0x10000).should eq 32825
      (nodes[57].children[1]).should eq 56

      nodes[237].x.to_f64.should be_close(2176, DELTA)
      nodes[237].y.to_f64.should be_close(-2304, DELTA)
      nodes[237].dx.to_f64.should be_close(0, DELTA)
      nodes[237].dy.to_f64.should be_close(-256, DELTA)
      nodes[237].bounding_box[0][Box::TOP].to_f64.should be_close(-2048, DELTA)
      nodes[237].bounding_box[0][Box::BOTTOM].to_f64.should be_close(-4064, DELTA)
      nodes[237].bounding_box[0][Box::LEFT].to_f64.should be_close(-768, DELTA)
      nodes[237].bounding_box[0][Box::RIGHT].to_f64.should be_close(2176, DELTA)
      nodes[237].bounding_box[1][Box::TOP].to_f64.should be_close(-2048, DELTA)
      nodes[237].bounding_box[1][Box::BOTTOM].to_f64.should be_close(-4864, DELTA)
      nodes[237].bounding_box[1][Box::LEFT].to_f64.should be_close(2176, DELTA)
      nodes[237].bounding_box[1][Box::RIGHT].to_f64.should be_close(3808, DELTA)
      (nodes[237].children[0]).should eq 131
      (nodes[237].children[1]).should eq 236
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
      segs = Seg.from_wad(wad, map + 5, vertices, lines)
      subsectors = Subsector.from_wad(wad, map + 6, segs)
      nodes = Node.from_wad(wad, map + 7, subsectors)

      nodes.size.should eq 193

      nodes[0].x.to_f64.should be_close(64, DELTA)
      nodes[0].y.to_f64.should be_close(1024, DELTA)
      nodes[0].dx.to_f64.should be_close(0, DELTA)
      nodes[0].dy.to_f64.should be_close(-64, DELTA)
      nodes[0].bounding_box[0][Box::TOP].to_f64.should be_close(1173, DELTA)
      nodes[0].bounding_box[0][Box::BOTTOM].to_f64.should be_close(960, DELTA)
      nodes[0].bounding_box[0][Box::LEFT].to_f64.should be_close(-64, DELTA)
      nodes[0].bounding_box[0][Box::RIGHT].to_f64.should be_close(64, DELTA)
      nodes[0].bounding_box[1][Box::TOP].to_f64.should be_close(1280, DELTA)
      nodes[0].bounding_box[1][Box::BOTTOM].to_f64.should be_close(1024, DELTA)
      nodes[0].bounding_box[1][Box::LEFT].to_f64.should be_close(64, DELTA)
      nodes[0].bounding_box[1][Box::RIGHT].to_f64.should be_close(128, DELTA)
      (nodes[0].children[0] + 0x10000).should eq 32770
      (nodes[0].children[1] + 0x10000).should eq 32771

      nodes[57].x.to_f64.should be_close(640, DELTA)
      nodes[57].y.to_f64.should be_close(856, DELTA)
      nodes[57].dx.to_f64.should be_close(-88, DELTA)
      nodes[57].dy.to_f64.should be_close(-16, DELTA)
      nodes[57].bounding_box[0][Box::TOP].to_f64.should be_close(856, DELTA)
      nodes[57].bounding_box[0][Box::BOTTOM].to_f64.should be_close(840, DELTA)
      nodes[57].bounding_box[0][Box::LEFT].to_f64.should be_close(552, DELTA)
      nodes[57].bounding_box[0][Box::RIGHT].to_f64.should be_close(640, DELTA)
      nodes[57].bounding_box[1][Box::TOP].to_f64.should be_close(856, DELTA)
      nodes[57].bounding_box[1][Box::BOTTOM].to_f64.should be_close(760, DELTA)
      nodes[57].bounding_box[1][Box::LEFT].to_f64.should be_close(536, DELTA)
      nodes[57].bounding_box[1][Box::RIGHT].to_f64.should be_close(704, DELTA)
      (nodes[57].children[0] + 0x10000).should eq 32829
      (nodes[57].children[1]).should eq 56

      nodes[192].x.to_f64.should be_close(96, DELTA)
      nodes[192].y.to_f64.should be_close(1280, DELTA)
      nodes[192].dx.to_f64.should be_close(32, DELTA)
      nodes[192].dy.to_f64.should be_close(0, DELTA)
      nodes[192].bounding_box[0][Box::TOP].to_f64.should be_close(1280, DELTA)
      nodes[192].bounding_box[0][Box::BOTTOM].to_f64.should be_close(-960, DELTA)
      nodes[192].bounding_box[0][Box::LEFT].to_f64.should be_close(-1304, DELTA)
      nodes[192].bounding_box[0][Box::RIGHT].to_f64.should be_close(2072, DELTA)
      nodes[192].bounding_box[1][Box::TOP].to_f64.should be_close(2688, DELTA)
      nodes[192].bounding_box[1][Box::BOTTOM].to_f64.should be_close(1280, DELTA)
      nodes[192].bounding_box[1][Box::LEFT].to_f64.should be_close(-1304, DELTA)
      nodes[192].bounding_box[1][Box::RIGHT].to_f64.should be_close(2072, DELTA)
      (nodes[192].children[0]).should eq 147
      (nodes[192].children[1]).should eq 191
    end
  end
end
