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
