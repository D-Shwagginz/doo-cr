DELTA = 1.0E-3

describe Angle do
  it "to_radian()" do
    (0.00 * Math::PI).should be_close(Angle.ang0.to_radian, DELTA)
    (0.25 * Math::PI).should be_close(Angle.ang45.to_radian, DELTA)
    (0.50 * Math::PI).should be_close(Angle.ang90.to_radian, DELTA)
    (1.00 * Math::PI).should be_close(Angle.ang180.to_radian, DELTA)
    (1.50 * Math::PI).should be_close(Angle.ang270.to_radian, DELTA)
  end
end
