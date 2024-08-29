module Doocr::Test
  describe Trig, tags: "trig" do
    it "Tan" do
      deg = 1
      while deg < 180
        angle = Angle.from_degree(deg)
        fine_angle = (angle.data >> Trig::ANGLE_TO_FINE_SHIFT).to_i32

        radian = 2 * Math::PI * (deg + 90) / 360
        expected = Math.tan(radian)

        actual = Trig.tan(angle).to_f64
        delta = Math.max(expected.abs / 50, 1.0E-3)
        expected.should be_close(actual, delta)

        actual = Trig.tan(fine_angle).to_f64
        delta = Math.max(expected.abs / 50, 1.0E-3)
        expected.should be_close(actual, delta)

        deg += 1
      end
    end

    it "Sin" do
      deg = -720
      while deg <= 720
        angle = Angle.from_degree(deg)
        fine_angle = (angle.data >> Trig::ANGLE_TO_FINE_SHIFT).to_i32

        radian = 2 * Math::PI * deg / 360
        expected = Math.sin(radian)

        actual = Trig.sin(angle).to_f64
        expected.should be_close(actual, 1.0E-3)

        actual = Trig.sin(fine_angle).to_f64
        expected.should be_close(actual, 1.0E-3)

        deg += 1
      end
    end

    it "Cos" do
      deg = -720
      while deg <= 720
        angle = Angle.from_degree(deg)
        fine_angle = (angle.data >> Trig::ANGLE_TO_FINE_SHIFT).to_i32

        radian = 2 * Math::PI * deg / 360
        expected = Math.cos(radian)

        actual = Trig.cos(angle).to_f64
        expected.should be_close(actual, 1.0E-3)

        actual = Trig.cos(fine_angle).to_f64
        expected.should be_close(actual, 1.0E-3)

        deg += 1
      end
    end
  end
end
