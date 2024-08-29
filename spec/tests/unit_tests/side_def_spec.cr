module Doocr::Test::SideDefTest
  DELTA = 1.0E-9

  describe SideDef, tags: "sidedef" do
    it "Load E1M1" do
      wad = Wad.new(WadPath::DOOM1)

      flats = DummyFlatLookup.new(wad)
      textures = TextureLookup.new(wad)
      map = wad.get_lump_number("E1M1")
      vertices = Vertex.from_wad(wad, map + 4)
      sectors = Sector.from_wad(wad, map + 8, flats)
      sides = SideDef.from_wad(wad, map + 3, textures, sectors)

      sides.size.should eq 666

      sides[0].texture_offset.to_f64.should be_close(0, DELTA)
      sides[0].row_offset.to_f64.should be_close(0, DELTA)
      sides[0].top_texture.should eq 0
      sides[0].bottom_texture.should eq 0
      textures[sides[0].middle_texture].name.as(String).should eq "DOOR3"
      sides[0].sector.should eq sectors[30]

      sides[480].texture_offset.to_f64.should be_close(32, DELTA)
      sides[480].row_offset.to_f64.should be_close(0, DELTA)
      textures[sides[480].top_texture].name.as(String).should eq "EXITSIGN"
      sides[480].bottom_texture.should eq 0
      sides[480].middle_texture.should eq 0
      sides[480].sector.should eq sectors[70]

      sides[650].texture_offset.to_f64.should be_close(0, DELTA)
      sides[650].row_offset.to_f64.should be_close(88, DELTA)
      textures[sides[650].top_texture].name.as(String).should eq "STARTAN3"
      textures[sides[650].bottom_texture].name.as(String).should eq "STARTAN3"
      sides[650].middle_texture.should eq 0
      sides[650].sector.should eq sectors[1]

      sides[665].texture_offset.to_f64.should be_close(0, DELTA)
      sides[665].row_offset.to_f64.should be_close(0, DELTA)
      sides[665].top_texture.should eq 0
      sides[665].bottom_texture.should eq 0
      sides[665].middle_texture.should eq 0
      sides[665].sector.should eq sectors[23]
    end

    it "Load Map01" do
      wad = Wad.new(WadPath::DOOM2)

      flats = DummyFlatLookup.new(wad)
      textures = TextureLookup.new(wad)
      map = wad.get_lump_number("MAP01")
      vertices = Vertex.from_wad(wad, map + 4)
      sectors = Sector.from_wad(wad, map + 8, flats)
      sides = SideDef.from_wad(wad, map + 3, textures, sectors)

      sides.size.should eq 529

      sides[0].texture_offset.to_f64.should be_close(0, DELTA)
      sides[0].row_offset.to_f64.should be_close(0, DELTA)
      sides[0].top_texture.should eq 0
      sides[0].bottom_texture.should eq 0
      textures[sides[0].middle_texture].name.as(String).should eq "BRONZE1"
      sides[0].sector.should eq sectors[9]

      sides[312].texture_offset.to_f64.should be_close(0, DELTA)
      sides[312].row_offset.to_f64.should be_close(0, DELTA)
      sides[312].top_texture.should eq 0
      sides[312].bottom_texture.should eq 0
      textures[sides[312].middle_texture].name.as(String).should eq "DOORTRAK"
      sides[312].sector.should eq sectors[31]

      sides[512].texture_offset.to_f64.should be_close(24, DELTA)
      sides[512].row_offset.to_f64.should be_close(0, DELTA)
      sides[512].top_texture.should eq 0
      sides[512].bottom_texture.should eq 0
      textures[sides[512].middle_texture].name.as(String).should eq "SUPPORT2"
      sides[512].sector.should eq sectors[52]

      sides[528].texture_offset.to_f64.should be_close(0, DELTA)
      sides[528].row_offset.to_f64.should be_close(0, DELTA)
      sides[528].top_texture.should eq 0
      sides[528].bottom_texture.should eq 0
      sides[528].middle_texture.should eq 0
      sides[528].sector.should eq sectors[11]
    end
  end
end
