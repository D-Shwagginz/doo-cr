module Doocr
  def self.swap_short(x : Int16 | UInt16)
    x = x.to_u16
    return ((x >> 8) | (x << 8)).to_i16
  end

  def self.swap_long(x : Int32 | UInt32)
    x = x.to_u32
    return (
      (x >> 24) |
        ((x >> 8) & 0xff00) |
        ((x << 8) & 0xff0000) |
        (x << 24)
    ).to_i32
  end
end
