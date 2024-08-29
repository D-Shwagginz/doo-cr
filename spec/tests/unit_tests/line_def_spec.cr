module Doocr::Test
  describe LineDef, tags: "linedef" do
    it "Load E1M1" do
      wad = Wad.new(WadPath::DOOM1)

      flats = DummyFlatLookup.new(wad)
      textures = DummyTextureLookup.new(wad)
      map = wad.get_lump_number("E1M1")
      vertices = Vertex.from_wad(wad, map + 4)
      sectors = Sector.from_wad(wad, map + 8, flats)
      sides = SideDef.from_wad(wad, map + 3, textures, sectors)
      lines = LineDef.from_wad(wad, map + 2, vertices, sides)

      lines.size.should eq 486

      lines[0].vertex1.should eq vertices[0]
      lines[0].vertex2.should eq vertices[1]
      lines[0].flags.to_i32.should eq 1
      lines[0].special.to_i32.should eq 0
      lines[0].tag.should eq 0
      lines[0].front_side.should eq sides[0]
      lines[0].back_side.should be_nil
      lines[0].front_sector.should eq sides[0].sector
      lines[0].back_sector.should be_nil

      lines[136].vertex1.should eq vertices[110]
      lines[136].vertex2.should eq vertices[111]
      lines[136].flags.to_i32.should eq 28
      lines[136].special.to_i32.should eq 63
      lines[136].tag.should eq 3
      lines[136].front_side.should eq sides[184]
      lines[136].back_side.should eq sides[185]
      lines[136].front_sector.should eq sides[184].sector
      lines[136].back_sector.should eq sides[185].sector

      lines[485].vertex1.should eq vertices[309]
      lines[485].vertex2.should eq vertices[294]
      lines[485].flags.to_i32.should eq 12
      lines[485].special.to_i32.should eq 0
      lines[485].tag.should eq 0
      lines[485].front_side.should eq sides[664]
      lines[485].back_side.should eq sides[665]
      lines[485].front_sector.should eq sides[664].sector
      lines[485].back_sector.should eq sides[665].sector
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

      lines.size.should eq 370

      lines[0].vertex1.should eq vertices[0]
      lines[0].vertex2.should eq vertices[1]
      lines[0].flags.to_i32.should eq 1
      lines[0].special.to_i32.should eq 0
      lines[0].tag.should eq 0
      lines[0].front_side.should eq sides[0]
      lines[0].back_side.should be_nil
      lines[0].front_sector.should eq sides[0].sector
      lines[0].back_sector.should be_nil

      lines[75].vertex1.should eq vertices[73]
      lines[75].vertex2.should eq vertices[74]
      lines[75].flags.to_i32.should eq 4
      lines[75].special.to_i32.should eq 103
      lines[75].tag.should eq 4
      lines[75].front_side.should eq sides[97]
      lines[75].back_side.should eq sides[98]
      lines[75].front_sector.should eq sides[97].sector
      lines[75].back_sector.should eq sides[98].sector

      lines[369].vertex1.should eq vertices[293]
      lines[369].vertex2.should eq vertices[299]
      lines[369].flags.to_i32.should eq 21
      lines[369].special.to_i32.should eq 0
      lines[369].tag.should eq 0
      lines[369].front_side.should eq sides[527]
      lines[369].back_side.should eq sides[528]
      lines[369].front_sector.should eq sides[527].sector
      lines[369].back_sector.should eq sides[528].sector
    end
  end
end
