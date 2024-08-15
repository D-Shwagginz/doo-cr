module Doocr
  class DoomEvent
    getter type : EventType
    getter key : DoomKey

    def initialize(@type : EventType, @key : DoomKey)
    end
  end
end
