module Doocr
def self.m_clear_box(box : CDoom::Fixed*)
    (box + CDoom::BOXTOP).value = Int32::MIN
    (box + CDoom::BOXRIGHT).value = Int32::MIN
    (box + CDoom::BOXLEFT).value = Int32::MAX
    (box + CDoom::BOXBOTTOM).value = Int32::MAX
  end

  def self.m_add_to_box(box : CDoom::Fixed*, x : CDoom::Fixed, y : CDoom::Fixed)
    if x < box[CDoom::BOXLEFT]
      (box + CDoom::BOXLEFT).value = x
    elsif x > box[CDoom::BOXRIGHT]
      (box + CDoom::BOXRIGHT).value = x
    end
    if y < box[CDoom::BOXBOTTOM]
      (box + CDoom::BOXBOTTOM).value = y
    elsif y > box[CDoom::BOXTOP]
      (box + CDoom::BOXTOP).value = y
    end
  end
end