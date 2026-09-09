require "./spec_helper"

describe "Doocr renderer math" do
  it "matches the unsigned fixed-point inverse-scale table" do
    {
      {65_536, 65_535},
      {131_072, 32_767},
      {262_144, 16_383},
      {524_288, 8_191},
    }.each do |scale, expected|
      Doocr.inverse_scale(scale).should eq(expected)
    end
  end

  it "keeps texture steps positive and decreasing as wall scale grows" do
    previous = Int32::MAX

    [65_536, 131_072, 262_144, 524_288].each do |scale|
      step = Doocr.inverse_scale(scale)
      step.should be > 0
      step.should be < previous
      previous = step
    end
  end
end
