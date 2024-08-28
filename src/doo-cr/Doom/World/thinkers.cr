#
# Copyright (C) 1993-1996 Id Software, Inc.
# Copyright (C) 2019-2020 Nobuaki Tanaka
# Copyright (C) 2024 Devin Shwagginz
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#

module Doocr
  class Thinkers
    @world : World

    def initialize(@world : World)
      init_thinkers()
    end

    getter cap : Thinker | Nil = nil

    private def init_thinkers
      @cap = Thinker.new
      @cap.as(Thinker).prev = @cap
      @cap.as(Thinker).next = @cap
    end

    def add(thinker : Thinker)
      @cap.as(Thinker).prev.as(Thinker).next = thinker
      thinker.next = @cap
      thinker.prev = @cap.as(Thinker).prev
      @cap.as(Thinker).prev = thinker
    end

    def remove(thinker : Thinker)
      thinker.thinker_state = ThinkerState::Removed
    end

    def run
      current = @cap.as(Thinker).next.as(Thinker)
      while current != @cap
        if current.as(Thinker).thinker_state == ThinkerState::Removed
          # Time to remove it
          current.as(Thinker).next.as(Thinker).prev = current.as(Thinker).prev
          current.as(Thinker).prev.as(Thinker).next = current.as(Thinker).next
        else
          if current.as(Thinker).thinker_state = ThinkerState::Active
            current.as(Thinker).run
          end
        end
        current = current.next.as(Thinker)
      end
    end

    def update_frame_interpolation_info
      current = @cap.as(Thinker).next.as(Thinker)
      while current != @cap
        current.update_frame_interpolation_info
        current = current.next.as(Thinker)
      end
    end

    def reset
      @cap.as(Thinker).prev = @cap.as(Thinker).next = @cap
    end

    def get_enumerator : ThinkerEnumerator
      return ThinkerEnumerator.new(self)
    end

    struct ThinkerEnumerator
      @thinkers : Thinkers
      getter current : Thinker

      def initialize(@thinkers : Thinkers)
        @current = @thinkers.cap.as(Thinker)
      end

      def move_next
        while true
          @current = @current.next.as(Thinker)
          if @current == @thinkers.cap.as(Thinker)
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
