module Doocr::Test::VertexTest
  DELTA = 1.0E-9
  describe Vertex, tags: "vertex" do
    it "Load E1M1" do
      wad = Wad.new(WadPath::DOOM1)

      map = wad.get_lump_number("E1M1")
      vertices = Vertex.from_wad(wad, map + 4)

      vertices.size.should eq 470

      vertices[0].x.to_f64.should be_close(1088, DELTA)
      vertices[0].y.to_f64.should be_close(-3680, DELTA)

      vertices[57].x.to_f64.should be_close(128, DELTA)
      vertices[57].y.to_f64.should be_close(-3008, DELTA)

      vertices[469].x.to_f64.should be_close(2435, DELTA)
      vertices[469].y.to_f64.should be_close(-3920, DELTA)
    end

    it "Load Map01" do
      wad = Wad.new(WadPath::DOOM2)

      map = wad.get_lump_number("MAP01")
      vertices = Vertex.from_wad(wad, map + 4)

      vertices.size.should eq 383

      vertices[0].x.to_f64.should be_close(-448, DELTA)
      vertices[0].y.to_f64.should be_close(768, DELTA)

      vertices[57].x.to_f64.should be_close(128, DELTA)
      vertices[57].y.to_f64.should be_close(1808, DELTA)

      vertices[382].x.to_f64.should be_close(-64, DELTA)
      vertices[382].y.to_f64.should be_close(2240, DELTA)
    end
  end
end
