module Doocr
  class Thinkers
    @world : World

    def initialize(@world : World)
      init_thinkers()
    end

    @cap : Thinker | Nil

    private def init_thinkers
      @cap = Thinker.new
      @cap.prev = @cap
      @cap.next = @cap
    end

    def add(thinker : Thinker)
      @cap.prev.next = thinker
      thinker.next = cap
      thinker.prev = cap.prev
      cap.prev = thinker
    end

    def remove(thinker : Thinker)
      thinker.thinker_state = ThinkerState::Removed
    end

    def run
      current = @cap.next
      while current != @cap
        if current.thinker_state == ThinkerState::Removed
          # Time to remove it
          current.next.prev = current.prev
          current.prev.next = current.next
        else
          if current.thinker_state = ThinkerState::Active
            current.run
          end
        end
        current = current.next
      end
    end

    def update_frame_interpolation_info
      current = @cap.next
      while current != @cap
        current.update_frame_interpolation_info
        current = current.next
      end
    end

    def reset
      @cap.prev = @cap.next = @cap
    end

    def get_enumerator : ThinkerEnumerator
      return ThinkerEnumerator.new(self)
    end

    struct ThinkerEnumerator
      @thinkers : Thinkers
      getter current : Thinker

      def initialize(@thinkers : Thinkers)
        @current = @thinkers.cap
      end

      def move_next
        while true
          @current = @current.next
          if @current == @thinkers.cap
            return false
          elsif @current.thinker_state != ThinkerState::Removed
            return true
          end
        end
      end

      def reset
        @current = @thinkers.cap
      end
    end
  end
end
