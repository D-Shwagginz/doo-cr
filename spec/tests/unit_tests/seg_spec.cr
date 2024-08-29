module Doocr::Test::SegTest
  DELTA = 1.0E-9

  private def self.to_radian(angle : Int32) : Float64
    angle += 0x10000 if angle < 0
    return 2 * Math::PI * (angle.to_f64 / 0x10000)
  end

  describe Seg, tags: "seg" do
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

      segs.size.should eq 747

      segs[0].vertex1.should eq vertices[132]
      segs[0].vertex2.should eq vertices[133]
      segs[0].angle.to_radian.should be_close(to_radian(4156), DELTA)
      segs[0].line_def.should eq lines[160]
      (segs[0].line_def.as(LineDef).flags & LineFlags::TwoSided).should_not eq 0
      segs[0].front_sector.should eq segs[0].line_def.as(LineDef).front_side.as(SideDef).sector
      segs[0].back_sector.should eq segs[0].line_def.as(LineDef).back_side.as(SideDef).sector
      segs[0].offset.to_f64.should be_close(0, DELTA)

      segs[28].vertex1.should eq vertices[390]
      segs[28].vertex2.should eq vertices[131]
      segs[28].angle.to_radian.should be_close(to_radian(-32768), DELTA)
      segs[28].line_def.should eq lines[480]
      (segs[0].line_def.as(LineDef).flags & LineFlags::TwoSided).should_not eq 0
      segs[28].front_sector.should eq segs[28].line_def.as(LineDef).back_side.as(SideDef).sector
      segs[28].back_sector.should eq segs[28].line_def.as(LineDef).front_side.as(SideDef).sector
      segs[28].offset.to_f64.should be_close(0, DELTA)

      segs[744].vertex1.should eq vertices[446]
      segs[744].vertex2.should eq vertices[374]
      segs[744].angle.to_radian.should be_close(to_radian(-16384), DELTA)
      segs[744].line_def.should eq lines[452]
      (segs[744].line_def.as(LineDef).flags & LineFlags::TwoSided).should_not eq 0
      segs[744].front_sector.should eq segs[744].line_def.as(LineDef).front_side.as(SideDef).sector
      segs[744].back_sector.should be_nil
      segs[744].offset.to_f64.should be_close(154, DELTA)

      segs[746].vertex1.should eq vertices[374]
      segs[746].vertex2.should eq vertices[368]
      segs[746].angle.to_radian.should be_close(to_radian(-13828), DELTA)
      segs[746].line_def.should eq lines[451]
      (segs[746].line_def.as(LineDef).flags & LineFlags::TwoSided).should_not eq 0
      segs[746].front_sector.should eq segs[746].line_def.as(LineDef).front_side.as(SideDef).sector
      segs[746].back_sector.should be_nil
      segs[746].offset.to_f64.should be_close(0, DELTA)
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

      segs.size.should eq 601

      segs[0].vertex1.should eq vertices[9]
      segs[0].vertex2.should eq vertices[316]
      segs[0].angle.to_radian.should be_close(to_radian(-32768), DELTA)
      segs[0].line_def.should eq lines[8]
      (segs[0].line_def.as(LineDef).flags & LineFlags::TwoSided).should_not eq 0
      segs[0].front_sector.should eq segs[0].line_def.as(LineDef).front_side.as(SideDef).sector
      segs[0].back_sector.should eq segs[0].line_def.as(LineDef).back_side.as(SideDef).sector
      segs[0].offset.to_f64.should be_close(0, DELTA)

      segs[42].vertex1.should eq vertices[26]
      segs[42].vertex2.should eq vertices[320]
      segs[42].angle.to_radian.should be_close(to_radian(-22209), DELTA)
      segs[42].line_def.should eq lines[33]
      (segs[42].line_def.as(LineDef).flags & LineFlags::TwoSided).should_not eq 0
      segs[42].front_sector.should eq segs[42].line_def.as(LineDef).back_side.as(SideDef).sector
      segs[42].back_sector.should eq segs[42].line_def.as(LineDef).front_side.as(SideDef).sector
      segs[42].offset.to_f64.should be_close(0, DELTA)

      segs[103].vertex1.should eq vertices[331]
      segs[103].vertex2.should eq vertices[329]
      segs[103].angle.to_radian.should be_close(to_radian(16384), DELTA)
      segs[103].line_def.should eq lines[347]
      (segs[103].line_def.as(LineDef).flags & LineFlags::TwoSided).should_not eq 0
      segs[103].front_sector.should eq segs[103].line_def.as(LineDef).front_side.as(SideDef).sector
      segs[103].back_sector.should be_nil
      segs[103].offset.to_f64.should be_close(64, DELTA)

      segs[600].vertex1.should eq vertices[231]
      segs[600].vertex2.should eq vertices[237]
      segs[600].angle.to_radian.should be_close(to_radian(-16384), DELTA)
      segs[600].line_def.should eq lines[271]
      (segs[600].line_def.as(LineDef).flags & LineFlags::TwoSided).should_not eq 0
      segs[600].front_sector.should eq segs[600].line_def.as(LineDef).back_side.as(SideDef).sector
      segs[600].back_sector.should eq segs[600].line_def.as(LineDef).front_side.as(SideDef).sector
      segs[600].offset.to_f64.should be_close(0, DELTA)
    end
  end
end
