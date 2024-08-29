module Doocr::Test::SectorTest
  DELTA = 1.0E-9

  describe Sector, tags: "sector" do
    it "Load E1M1" do
      wad = Wad.new(WadPath::DOOM1)

      map = wad.get_lump_number("E1M1")
      flats = FlatLookup.new(wad)
      sectors = Sector.from_wad(wad, map + 8, flats)

      sectors.size.should eq 88

      sectors[0].floor_height.to_f64.should be_close(-80, DELTA)
      sectors[0].ceiling_height.to_f64.should be_close(216, DELTA)
      flats[sectors[0].floor_flat].name.as(String).delete('\0').should eq "NUKAGE3"
      flats[sectors[0].ceiling_flat].name.as(String).delete('\0').should eq "F_SKY1"
      sectors[0].light_level.should eq 255
      sectors[0].special.should eq SectorSpecial.new(7)
      sectors[0].tag.should eq 0

      sectors[42].floor_height.to_f64.should be_close(0, DELTA)
      sectors[42].ceiling_height.to_f64.should be_close(264, DELTA)
      flats[sectors[42].floor_flat].name.as(String).delete('\0').should eq "FLOOR7_1"
      flats[sectors[42].ceiling_flat].name.as(String).delete('\0').should eq "F_SKY1"
      sectors[42].light_level.should eq 255
      sectors[42].special.should eq SectorSpecial.new(0)
      sectors[42].tag.should eq 0

      sectors[87].floor_height.to_f64.should be_close(104, DELTA)
      sectors[87].ceiling_height.to_f64.should be_close(184, DELTA)
      flats[sectors[87].floor_flat].name.as(String).delete('\0').should eq "FLOOR4_8"
      flats[sectors[87].ceiling_flat].name.as(String).delete('\0').should eq "FLOOR6_2"
      sectors[87].light_level.should eq 128
      sectors[87].special.should eq SectorSpecial.new(9)
      sectors[87].tag.should eq 2
    end

    it "Load Map01" do
      wad = Wad.new(WadPath::DOOM2)

      map = wad.get_lump_number("MAP01")
      flats = FlatLookup.new(wad)
      sectors = Sector.from_wad(wad, map + 8, flats)

      sectors.size.should eq 59

      sectors[0].floor_height.to_f64.should be_close(8, DELTA)
      sectors[0].ceiling_height.to_f64.should be_close(264, DELTA)
      flats[sectors[0].floor_flat].name.as(String).delete('\0').should eq "FLOOR0_1"
      flats[sectors[0].ceiling_flat].name.as(String).delete('\0').should eq "FLOOR4_1"
      sectors[0].light_level.should eq 128
      sectors[0].special.should eq SectorSpecial::Normal
      sectors[0].tag.should eq 0

      sectors[57].floor_height.to_f64.should be_close(56, DELTA)
      sectors[57].ceiling_height.to_f64.should be_close(184, DELTA)
      flats[sectors[57].floor_flat].name.as(String).delete('\0').should eq "FLOOR3_3"
      flats[sectors[57].ceiling_flat].name.as(String).delete('\0').should eq "CEIL3_3"
      puts sectors[57].ceiling_flat
      sectors[57].light_level.should eq 144
      sectors[57].special.should eq SectorSpecial.new(9)
      sectors[57].tag.should eq 0

      sectors[58].floor_height.to_f64.should be_close(56, DELTA)
      sectors[58].ceiling_height.to_f64.should be_close(56, DELTA)
      flats[sectors[58].floor_flat].name.as(String).delete('\0').should eq "FLOOR3_3"
      flats[sectors[58].ceiling_flat].name.as(String).delete('\0').should eq "FLAT20"
      sectors[58].light_level.should eq 144
      sectors[58].special.should eq SectorSpecial::Normal
      sectors[58].tag.should eq 6
    end
  end
end
