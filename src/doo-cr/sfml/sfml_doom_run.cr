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

module Doocr::SFML
  class SFMLDoom
    {% if !flag?(:windows) %}
      def run
        if @args.timedemo.present
          @window.as(SF::RenderWindow).framerate_limit = 0
        else
          @config.as(Config).video_fpsscale = @config.as(Config).video_fpsscale.clamp(1, 100)
          target_fps = 35 * @config.as(Config).video_fpsscale
          @window.as(SF::RenderWindow).framerate_limit = target_fps
        end

        while window = @window.as?(SF::RenderWindow)
          while window.open?
            update
            render
            while event = window.poll_event
              case event
              when SF::Event::Closed
                close()
              when SF::Event::Resized
                resize(event.width.to_i32, event.height.to_i32)
              end
            end
          end
        end

        quit()
      end
    {% else %}
      def run
        @config.as(Config).video_fpsscale = @config.as(Config).video_fpsscale.clamp(1, 100)
        target_fps = 35 * @config.as(Config).video_fpsscale

        @window.as(SF::RenderWindow).framerate_limit = 0

        if @args.timedemo.present
          while window = @window.as?(SF::RenderWindow)
            while window.open?
              update
              render
              while event = window.poll_event
                case event
                when SF::Event::Closed
                  close()
                when SF::Event::Resized
                  resize(event.width.to_i32, event.height.to_i32)
                end
              end
            end
          end
        else
          game_time = SF::Time.new
          game_time_step = SF.seconds((1.0 / target_fps).to_i32)

          clock = SF::Clock.new

          while window = @window.as?(SF::RenderWindow)
            while true
              while event = window.poll_event
                case event
                when SF::Event::Closed
                  close()
                when SF::Event::Resized
                  resize(event.width.to_i32, event.height.to_i32)
                end
              end

              if window.open?
                update
                game_time += game_time_step
              end

              if window.open?
                if clock.elapsed_time < game_time
                  render
                  sleep_time = game_time - clock.elapsed_time
                  s = sleep_time.as_seconds.to_i32
                  sleep(s)
                end
              else
                break
              end
            end

            while event = window.poll_event
              case event
              when SF::Event::Closed
                close()
              when SF::Event::Resized
                resize(event.width.to_i32, event.height.to_i32)
              end
            end

            window.create(window.system_handle)
          end
        end
      end
    {% end %}
  end
end
