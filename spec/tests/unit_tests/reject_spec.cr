module Doocr::Test
  describe Reject, tags: "reject" do
    it "Load E1M1" do
      wad = Wad.new(WadPath::DOOM1)

      flats = DummyFlatLookup.new(wad)
      textures = DummyTextureLookup.new(wad)
      map = wad.get_lump_number("E1M1")
      vertices = Vertex.from_wad(wad, map + 4)
      sectors = Sector.from_wad(wad, map + 8, flats)
      sides = SideDef.from_wad(wad, map + 3, textures, sectors)
      lines = LineDef.from_wad(wad, map + 2, vertices, sides)
      reject = Reject.from_wad(wad, map + 9, sectors)

      sectors.each do |sector|
        reject.check(sector, sector).should be_false
      end

      lines.each do |line|
        if line.back_sector != nil
          reject.check(line.front_sector.as(Sector), line.back_sector.as(Sector)).should be_false
        end
      end

      sectors.each do |s1|
        sectors.each do |s2|
          result1 = reject.check(s1, s2)
          result2 = reject.check(s2, s1)
          result1.should eq result2
        end
      end

      reject.check(sectors[41], sectors[70]).should be_true
      reject.check(sectors[60], sectors[79]).should be_true
      reject.check(sectors[24], sectors[80]).should be_true
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
      reject = Reject.from_wad(wad, map + 9, sectors)

      sectors.each do |sector|
        reject.check(sector, sector).should be_false
      end

      lines.each do |line|
        if line.back_sector != nil
          reject.check(line.front_sector.as(Sector), line.back_sector.as(Sector)).should be_false
        end
      end

      sectors.each do |s1|
        sectors.each do |s2|
          result1 = reject.check(s1, s2)
          result2 = reject.check(s2, s1)
          result1.should eq result2
        end
      end

      reject.check(sectors[10], sectors[49]).should be_true
      reject.check(sectors[7], sectors[36]).should be_true
      reject.check(sectors[17], sectors[57]).should be_true
    end
  end
end
