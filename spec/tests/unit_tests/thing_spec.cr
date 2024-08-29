module Doocr::Test::ThingTest
  DELTA = 1.0E-9

  describe MapThing, tags: "thing" do
    it "Load E1M1" do
      wad = Wad.new(WadPath::DOOM1)

      map = wad.get_lump_number("E1M1")
      things = MapThing.from_wad(wad, map + 1)

      things.size.should eq 143

      things[0].x.to_f64.should be_close(1056, DELTA)
      things[0].y.to_f64.should be_close(-3616, DELTA)
      things[0].angle.to_degree.should be_close(90, DELTA)
      things[0].type.should eq 1
      things[0].flags.to_i32.should eq 7

      things[57].x.to_f64.should be_close(3072, DELTA)
      things[57].y.to_f64.should be_close(-4832, DELTA)
      things[57].angle.to_degree.should be_close(180, DELTA)
      things[57].type.should eq 2015
      things[57].flags.to_i32.should eq 7

      things[142].x.to_f64.should be_close(736, DELTA)
      things[142].y.to_f64.should be_close(-2976, DELTA)
      things[142].angle.to_degree.should be_close(90, DELTA)
      things[142].type.should eq 2001
      things[142].flags.to_i32.should eq 23
    end

    it "Load Map01" do
      wad = Wad.new(WadPath::DOOM2)

      map = wad.get_lump_number("MAP01")
      things = MapThing.from_wad(wad, map + 1)

      things.size.should eq 69

      things[0].x.to_f64.should be_close(-96, DELTA)
      things[0].y.to_f64.should be_close(784, DELTA)
      things[0].angle.to_degree.should be_close(90, DELTA)
      things[0].type.should eq 1
      things[0].flags.to_i32.should eq 7

      things[57].x.to_f64.should be_close(-288, DELTA)
      things[57].y.to_f64.should be_close(976, DELTA)
      things[57].angle.to_degree.should be_close(270, DELTA)
      things[57].type.should eq 2006
      things[57].flags.to_i32.should eq 23

      things[68].x.to_f64.should be_close(-480, DELTA)
      things[68].y.to_f64.should be_close(848, DELTA)
      things[68].angle.to_degree.should be_close(0, DELTA)
      things[68].type.should eq 2005
      things[68].flags.to_i32.should eq 7
    end
  end
end
