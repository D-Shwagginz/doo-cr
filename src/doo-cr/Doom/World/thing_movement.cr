module Doocr
  class ThingMovement
    @world : World

    def initialize(@world : World)
      init_thing_movement()
      init_slide_movement()
      init_teleport_movement()
    end

    #
    # General thing movement
    #

  end
end
