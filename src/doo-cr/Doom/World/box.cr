module Doocr
  module Box
    TOP    = 0
    BOTTOM = 1
    LEFT   = 2
    RIGHT  = 3

    def self.clear(box : Array(Fixed))
      box[TOP] = Fixed.min_value
      box[RIGHT] = Fixed.min_value
      box[BOTTOM] = Fixed.max_value
      box[LEFT] = Fixed.max_value
    end

    def self.add_point(box : Array(Fixed), x : Fixed, y : Fixed)
      if x < box[LEFT]
        box[LEFT] = x
      elsif x > box[RIGHT]
        box[RIGHT] = x
      end

      if y < box[BOTTOM]
        box[BOTTOM] = y
      elsif y > box[TOP]
        box[TOP] = y
      end
    end
  end
end
