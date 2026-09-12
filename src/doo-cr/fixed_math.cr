module Doocr
  def self.inverse_scale(scale : Int32) : Int32
    (0xffffffff_u32 // scale.to_u32!).to_i32!
  end
end
