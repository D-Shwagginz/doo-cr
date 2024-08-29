module Doocr::Test
  describe Wad, tags: "wad" do
    it "Lump Number Doom1" do
      wad = Wad.new(WadPath::DOOM1)
      wad.get_lump_number("PLAYPAL").should eq 0
      wad.get_lump_number("COLORMAP").should eq 1
      wad.get_lump_number("E1M1").should eq 7
      wad.get_lump_number("F_END").should eq 2306
      wad.lump_infos.size.should eq 2307
    end

    it "Lump Number Doom2" do
      wad = Wad.new(WadPath::DOOM2)
      wad.get_lump_number("PLAYPAL").should eq 0
      wad.get_lump_number("COLORMAP").should eq 1
      wad.get_lump_number("MAP01").should eq 6
      wad.get_lump_number("F_END").should eq 2924
      wad.lump_infos.size.should eq 2925
    end

    it "Flat Size Doom1" do
      wad = Wad.new(WadPath::DOOM1)

      start = wad.get_lump_number("F_START") + 1
      endl = wad.get_lump_number("F_END")
      lump = start
      while lump < endl
        size = wad.get_lump_size(lump)
        (size == 0 || size == 4096).should be_true

        lump += 1
      end
    end

    it "Flat Size Doom2" do
      wad = Wad.new(WadPath::DOOM2)

      start = wad.get_lump_number("F_START") + 1
      endl = wad.get_lump_number("F_END")
      lump = start
      while lump < endl
        size = wad.get_lump_size(lump)
        (size == 0 || size == 4096).should be_true

        lump += 1
      end
    end
  end
end
