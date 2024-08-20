module Doocr::UserInput
  module IUserInput
    abstract def build_tic_cmd(cmd : TicCmd)
    abstract def reset
    abstract def grab_mouse
    abstract def release_mouse

    abstract def max_mouse_sensitivity : Int32
    abstract def mouse_sensitivity : Int32
    abstract def mouse_sensitivity=(@mouse_sensitivity : Int32)
  end
end
