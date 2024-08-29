module Doocr::Test::AngleTest
  DELTA = 1.0E-3

  describe Angle, tags: "angle" do
    it "To Radian" do
      (0.00 * Math::PI).should be_close(Angle.ang0.to_radian, DELTA)
      (0.25 * Math::PI).should be_close(Angle.ang45.to_radian, DELTA)
      (0.50 * Math::PI).should be_close(Angle.ang90.to_radian, DELTA)
      (1.00 * Math::PI).should be_close(Angle.ang180.to_radian, DELTA)
      (1.50 * Math::PI).should be_close(Angle.ang270.to_radian, DELTA)
    end

    it "From Degrees" do
      deg = -720
      while deg <= 720
        expected_sin = Math.sin(2 * Math::PI * deg / 360)
        expected_cos = Math.cos(2 * Math::PI * deg / 360)

        angle = Angle.from_degree(deg)
        actual_sin = Math.sin(angle.to_radian)
        actual_cos = Math.cos(angle.to_radian)

        expected_sin.should be_close(actual_sin, DELTA)
        expected_cos.should be_close(actual_cos, DELTA)
        deg += 1
      end
    end

    it "From Radian To Degrees" do
      (Angle.from_radian(0.00 * Math::PI).to_degree).should be_close(0, DELTA)
      (Angle.from_radian(0.25 * Math::PI).to_degree).should be_close(45, DELTA)
      (Angle.from_radian(0.50 * Math::PI).to_degree).should be_close(90, DELTA)
      (Angle.from_radian(1.00 * Math::PI).to_degree).should be_close(180, DELTA)
      (Angle.from_radian(1.50 * Math::PI).to_degree).should be_close(270, DELTA)
    end

    it "Sign" do
      random = Random.new(666)
      100.times do |i|
        a = random.rand(1440) - 720
        b = +a
        c = -a

        aa = Angle.from_degree(a)
        ab = +aa
        ac = -aa

        expected_sin = Math.sin(2 * Math::PI * b / 360)
        expected_cos = Math.cos(2 * Math::PI * b / 360)

        actual_sin = Math.sin(ab.to_radian)
        actual_cos = Math.cos(ab.to_radian)

        expected_sin.should be_close(actual_sin, DELTA)
        expected_cos.should be_close(actual_cos, DELTA)

        expected_sin = Math.sin(2 * Math::PI * c / 360)
        expected_cos = Math.cos(2 * Math::PI * c / 360)

        actual_sin = Math.sin(ac.to_radian)
        actual_cos = Math.cos(ac.to_radian)

        expected_sin.should be_close(actual_sin, DELTA)
        expected_cos.should be_close(actual_cos, DELTA)
      end
    end

    it "Abs" do
      random = Random.new(666)
      100.times do |i|
        a = random.rand(120) - 60
        b = a.abs

        aa = Angle.from_degree(a)
        ab = aa.abs

        expected_sin = Math.sin(2 * Math::PI * b / 360)
        expected_cos = Math.cos(2 * Math::PI * b / 360)

        actual_sin = Math.sin(ab.to_radian)
        actual_cos = Math.cos(ab.to_radian)

        expected_sin.should be_close(actual_sin, DELTA)
        expected_cos.should be_close(actual_cos, DELTA)
      end
    end

    it "Addition" do
      random = Random.new(666)
      100.times do |i|
        a = random.rand(1440) - 720
        b = random.rand(1440) - 720
        c = a + b

        fa = Angle.from_degree(a)
        fb = Angle.from_degree(b)
        fc = fa + fb

        expected_sin = Math.sin(2 * Math::PI * c / 360)
        expected_cos = Math.cos(2 * Math::PI * c / 360)

        actual_sin = Math.sin(fc.to_radian)
        actual_cos = Math.cos(fc.to_radian)

        expected_sin.should be_close(actual_sin, DELTA)
        expected_cos.should be_close(actual_cos, DELTA)
      end
    end

    it "Subtraction" do
      random = Random.new(666)
      100.times do |i|
        a = random.rand(1440) - 720
        b = random.rand(1440) - 720
        c = a - b

        fa = Angle.from_degree(a)
        fb = Angle.from_degree(b)
        fc = fa - fb

        expected_sin = Math.sin(2 * Math::PI * c / 360)
        expected_cos = Math.cos(2 * Math::PI * c / 360)

        actual_sin = Math.sin(fc.to_radian)
        actual_cos = Math.cos(fc.to_radian)

        expected_sin.should be_close(actual_sin, DELTA)
        expected_cos.should be_close(actual_cos, DELTA)
      end
    end

    it "Multiplication1" do
      random = Random.new(666)
      100.times do |i|
        a = random.rand(30).to_u32
        b = random.rand(12).to_u32
        c = a * b

        fa = Angle.from_degree(a)
        fc = fa * b

        c.should be_close(fc.to_degree, DELTA)
      end
    end

    it "Multiplication2" do
      random = Random.new(666)
      100.times do |i|
        a = random.rand(30).to_u32
        b = random.rand(12).to_u32
        c = a * b

        fb = Angle.from_degree(b)
        fc = fb * a

        c.should be_close(fc.to_degree, DELTA)
      end
    end

    it "Division" do
      random = Random.new(666)
      100.times do |i|
        a = random.rand(36).to_f64
        b = (random.rand(30) + 1).to_u32
        c = a / b

        fa = Angle.from_degree(a)
        fc = fa / b

        c.should be_close(fc.to_degree, DELTA)
      end
    end

    it "Comparison" do
      random = Random.new(666)
      10000.times do |i|
        a = random.rand(1140) - 720
        b = random.rand(1140) - 720

        fa = Angle.from_degree(a)
        fb = Angle.from_degree(b)

        a = ((a % 360) + 360) % 360
        b = ((b % 360) + 360) % 360

        ((a == b) == (fa == fb)).should be_true
        ((a != b) == (fa != fb)).should be_true
        ((a < b) == (fa < fb)).should be_true
        ((a > b) == (fa > fb)).should be_true
        ((a <= b) == (fa <= fb)).should be_true
        ((a >= b) == (fa >= fb)).should be_true
      end
    end
  end
end
