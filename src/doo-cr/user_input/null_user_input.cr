require "./i_user_input.cr"

module Doocr::UserInput
  class NullUserInput
    include IUserInput

    @@instance : NullUserInput | Nil

    def self.get_instance
      if @@instance == nil
        @@instance = NullUserInput.new
      end

      return @@instance
    end

    def reset
    end

    def grab_mouse
    end

    def release_mouse
    end

    def mouse_sensitivity=(mouse_sensitivity : Int32)
    end

    def build_tic_cmd(cmd : TicCmd)
      cmd.clear
    end

    def max_mouse_sensitivity : Int32
      return 9
    end

    def mouse_sensitivity : Int32
      return 3
    end
  end
end
