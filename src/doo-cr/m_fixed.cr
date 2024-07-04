# Fixed point arithemtics, implementation.

module Doocr
  # Fixed point, 32bit as 16.16.
  FRACBITS = 16
  FRACUNIT = (1 << FRACBITS)

  def self.fixedmul(a : Int32, b : Int32)
    return ((a.to_i64 * b.to_i64) >> FRACBITS).to_i32
  end

  def self.fixeddiv(a : Int32, b : Int32)
    if ((a.abs >> 14) >= b.abs)
      return (a ^ b) < 0 ? Int32::MIN : Int32::MAX
    end
    return fixeddiv2(a, b)
  end

  def self.fixeddiv2(a : Int32, b : Int32)
    c = a.to_f64 / b.to_f64 * FRACUNIT

    raise "fixeddiv: divide by zero" if c >= 2147483648.0 || c < -2147483648.0
    return c.to_i32
  end
end
