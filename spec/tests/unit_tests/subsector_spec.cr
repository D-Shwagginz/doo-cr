module Doocr::Test
  describe Subsector, tags: "subsector" do
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

      subsectors.size.should eq 239

      subsectors[0].seg_count.should eq 8
      8.times do |i|
        segs[subsectors[0].first_seg + i].should eq segs[0 + i]
      end

      subsectors[54].seg_count.should eq 1
      1.times do |i|
        segs[subsectors[54].first_seg + i].should eq segs[181 + i]
      end

      subsectors[238].seg_count.should eq 2
      2.times do |i|
        segs[subsectors[238].first_seg + i].should eq segs[745 + i]
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
      segs = Seg.from_wad(wad, map + 5, vertices, lines)
      subsectors = Subsector.from_wad(wad, map + 6, segs)

      subsectors.size.should eq 194

      subsectors[0].seg_count.should eq 4
      4.times do |i|
        segs[subsectors[0].first_seg + i].should eq segs[0 + i]
      end

      subsectors[57].seg_count.should eq 4
      4.times do |i|
        segs[subsectors[57].first_seg + i].should eq segs[179 + i]
      end

      subsectors[193].seg_count.should eq 4
      4.times do |i|
        segs[subsectors[193].first_seg + i].should eq segs[597 + i]
      end
    end
  end
end
