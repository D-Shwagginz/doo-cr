module Doocr::Test::FixedTest
  DELTA = 1.0E-3

  describe Fixed, tags: "fixed" do
    it "Conversion" do
      random = Random.new(666)
      100.times do |i|
        da = 666 * random.next_float - 333
        sa = da.to_f32

        fda = Fixed.from_f64(da)
        fsa = Fixed.from_f32(sa)

        da.should be_close(fda.to_f64, DELTA)
        sa.should be_close(fsa.to_f32, DELTA)
      end
    end

    it "Abs1" do
      random = Random.new(666)
      100.times do |i|
        a = random.rand(666) - 333
        b = a.abs

        fa = Fixed.from_f64(a)
        fb = fa.abs

        b.should be_close(fb.to_f64, DELTA)
      end
    end

    it "Abs2" do
      random = Random.new(666)
      100.times do |i|
        a = 666 * random.next_float - 333
        b = a.abs

        fa = Fixed.from_f64(a)
        fb = fa.abs

        b.should be_close(fb.to_f64, DELTA)
      end
    end

    it "Sign1" do
      random = Random.new(666)
      100.times do |i|
        a = random.rand(666) - 333

        fa = Fixed.from_f64(a)

        (+a).should be_close((+fa).to_f64, DELTA)
        (-a).should be_close((-fa).to_f64, DELTA)
      end
    end

    it "Sign2" do
      random = Random.new(666)
      100.times do |i|
        a = 666 * random.next_float - 333

        fa = Fixed.from_f64(a)

        (+a).should be_close((+fa).to_f64, DELTA)
        (-a).should be_close((-fa).to_f64, DELTA)
      end
    end

    it "Addition1" do
      random = Random.new(666)
      100.times do |i|
        a = random.rand(666) - 333
        b = random.rand(666) - 333
        c = a + b

        fa = Fixed.from_i(a)
        fb = Fixed.from_i(b)
        fc = fa + fb

        c.should be_close(fc.to_f64, DELTA)
      end
    end

    it "Addition2" do
      random = Random.new(666)
      100.times do |i|
        a = 666 * random.next_float - 333
        b = 666 * random.next_float - 333
        c = a + b

        fa = Fixed.from_f64(a)
        fb = Fixed.from_f64(b)
        fc = fa + fb

        c.should be_close(fc.to_f64, DELTA)
      end
    end

    it "Subtraction1" do
      random = Random.new(666)
      100.times do |i|
        a = random.rand(666) - 333
        b = random.rand(666) - 333
        c = a - b

        fa = Fixed.from_i(a)
        fb = Fixed.from_i(b)
        fc = fa - fb

        c.should be_close(fc.to_f64, DELTA)
      end
    end

    it "Subtraction2" do
      random = Random.new(666)
      100.times do |i|
        a = 666 * random.next_float - 333
        b = 666 * random.next_float - 333
        c = a - b

        fa = Fixed.from_f64(a)
        fb = Fixed.from_f64(b)
        fc = fa - fb

        c.should be_close(fc.to_f64, DELTA)
      end
    end

    it "Multiplication1" do
      random = Random.new(666)
      100.times do |i|
        a = random.rand(66) - 33
        b = random.rand(66) - 33
        c = a * b

        fa = Fixed.from_i(a)
        fb = Fixed.from_i(b)
        fc = fa * fb

        c.should be_close(fc.to_f64, DELTA)
      end
    end

    it "Multiplication2" do
      random = Random.new(666)
      100.times do |i|
        a = 66 * random.next_float - 33
        b = 66 * random.next_float - 33
        c = a * b

        fa = Fixed.from_f64(a)
        fb = Fixed.from_f64(b)
        fc = fa * fb

        c.should be_close(fc.to_f64, DELTA)
      end
    end

    it "Multiplication3" do
      random = Random.new(666)
      100.times do |i|
        a = 66 * random.next_float - 33
        b = random.rand(66) - 33
        c = a * b

        fa = Fixed.from_f64(a)
        fc = fa * b

        c.should be_close(fc.to_f64, DELTA)
      end
    end

    it "Division1" do
      random = Random.new(666)
      100.times do |i|
        a = random.rand(66) - 33
        b = (2 * random.rand(2) - 1) * (random.rand(33) + 33)
        c = a.to_f64 / b

        fa = Fixed.from_i(a)
        fb = Fixed.from_i(b)
        fc = fa / fb

        c.should be_close(fc.to_f64, DELTA)
      end
    end

    it "Division2" do
      random = Random.new(666)
      100.times do |i|
        a = 66 * random.next_float - 33
        b = (2 * random.rand(2) - 1) * (33 * random.next_float + 33)
        c = a / b

        fa = Fixed.from_f64(a)
        fb = Fixed.from_f64(b)
        fc = fa / fb

        c.should be_close(fc.to_f64, DELTA)
      end
    end

    it "Division2" do
      random = Random.new(666)
      100.times do |i|
        a = 66 * random.next_float - 33
        b = (2 * random.rand(2) - 1) * (random.rand(33) + 33)
        c = a / b

        fa = Fixed.from_f64(a)
        fc = fa / b

        c.should be_close(fc.to_f64, DELTA)
      end
    end

    it "Bitshift" do
      random = Random.new(666)
      100.times do |i|
        a = random.rand(666666) - 333333
        b = random.rand(16)
        c = a << b
        d = a >> b

        fa = Fixed.new(a)
        fc = fa << b
        fd = fa >> b

        c.should eq fc.data
        d.should eq fd.data
      end
    end

    it "Comparison" do
      random = Random.new(666)
      100.times do |i|
        a = random.rand(5)
        b = random.rand(5)

        fa = Fixed.from_i(a)
        fb = Fixed.from_i(b)

        (a == b).should eq(fa == fb)
        (a != b).should eq(fa != fb)
        (a < b).should eq(fa < fb)
        (a > b).should eq(fa > fb)
        (a <= b).should eq(fa <= fb)
        (a >= b).should eq(fa >= fb)
      end
    end

    it "Min Max" do
      random = Random.new(666)
      100.times do |i|
        a = random.rand(5)
        b = random.rand(5)
        min = Math.min(a, b)
        max = Math.max(a, b)

        fa = Fixed.from_i(a)
        fb = Fixed.from_i(b)
        fmin = Fixed.min(fa, fb)
        fmax = Fixed.max(fa, fb)

        min.should be_close(fmin.to_f64, 1.0E-9)
        max.should be_close(fmax.to_f64, 1.0E-9)
      end
    end

    it "To Int1" do
      random = Random.new(666)
      100.times do |i|
        a = random.rand(666)

        fa = Fixed.from_f64(a)
        ffloor = fa.to_i_floor
        fceiling = fa.to_i_ceiling

        a.should be_close(ffloor, 1.0E-9)
        a.should be_close(fceiling, 1.0E-9)
      end
    end

    it "To Int2" do
      random = Random.new(666)
      100.times do |i|
        a = random.rand(666666).to_f64 / 1000
        floor = a.floor
        ceiling = a.ceil

        fa = Fixed.from_f64(a)
        ffloor = fa.to_i_floor
        fceiling = fa.to_i_ceiling

        floor.should be_close(ffloor, 1.0E-9)
        ceiling.should be_close(fceiling, 1.0E-9)
      end
    end
  end
end
