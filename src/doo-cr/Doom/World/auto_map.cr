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
  class AutoMap
    @world : World | Nil = nil

    getter min_x : Fixed = Fixed.zero
    getter max_x : Fixed = Fixed.zero
    getter min_y : Fixed = Fixed.zero
    getter max_y : Fixed = Fixed.zero

    getter view_x : Fixed = Fixed.zero
    getter view_y : Fixed = Fixed.zero

    getter visible : Bool = false
    getter state : AutoMapState = AutoMapState.new(0)

    getter zoom : Fixed = Fixed.zero
    getter follow : Bool = false

    @zoom_in : Bool = false
    @zoom_out : Bool = false

    @left : Bool = false
    @right : Bool = false
    @up : Bool = false
    @down : Bool = false

    getter marks : Array(Vertex) = [] of Vertex
    @next_mark_number : Int32 = 0

    def initialize(@world)
      @min_x = Fixed.max_value
      @max_x = Fixed.min_value
      @min_y = Fixed.max_value
      @max_y = Fixed.min_value
      @world.as(World).map.vertices.each do |vertex|
        @min_x = vertex.x if vertex.x < @min_x
        @max_x = vertex.x if vertex.x > @max_x
        @min_y = vertex.y if vertex.y < @min_y
        @max_y = vertex.y if vertex.y > @max_y
      end

      @view_x = @min_x + (@max_x - @min_x) / 2
      @view_y = @min_y + (@max_y - @min_y) / 2

      @visible = false
      @state = AutoMapState::None

      @zoom = Fixed.one
      @follow = true

      @zoom_in = false
      @zoom_out = false
      @left = false
      @right = false
      @up = false
      @down = false

      @marks = [] of Vertex
      @next_mark_number = 0
    end

    def update
      @zoom += @zoom / 16 if @zoom_in

      @zoom -= @zoom / 16 if @zoom_out

      if @zoom < Fixed.one / 2
        @zoom = Fixed.one / 2
      elsif @zoom > Fixed.one * 32
        @zoom = Fixed.one * 32
      end

      @view_x -= 64 / @zoom if @left

      @view_x += 64 / @zoom if @right

      @view_y += 64 / @zoom if @up

      @view_y -= 64 / @zoom if @down

      if @view_x < @min_x
        @view_x = @min_x
      elsif @view_x > @max_x
        @view_x = @max_x
      end

      if @view_y < @min_y
        @view_y = @min_y
      elsif @view_y > @max_y
        @view_x = @max_y
      end

      if @follow
        player = @world.as(World).console_player.mobj
        @view_x = player.x
        @view_y = player.y
      end
    end

    def do_event(e : DoomEvent) : Bool
      if e.key == DoomKey::Add || e.key == DoomKey::Quote || e.key == DoomKey::Equal
        if e.type == EventType::KeyDown
          @zoom_in = true
        elsif e.type == EventType::KeyUp
          @zoom_in = false
        end

        return true
      elsif e.key == DoomKey::Subtract || e.key == DoomKey::Hyphen || e.key == DoomKey::Semicolon
        if e.type == EventType::KeyDown
          @zoom_out = true
        elsif e.type == EventType::KeyUp
          @zoom_out = false
        end

        return true
      elsif e.key == DoomKey::Left
        if e.type == EventType::KeyDown
          @left = true
        elsif e.type == EventType::KeyUp
          @left = false
        end

        return true
      elsif e.key == DoomKey::Right
        if e.type == EventType::KeyDown
          @right = true
        elsif e.type == EventType::KeyUp
          @right = false
        end

        return true
      elsif e.key == DoomKey::Up
        if e.type == EventType::KeyDown
          @up = true
        elsif e.type == EventType::KeyUp
          @up = false
        end

        return true
      elsif e.key == DoomKey::Down
        if e.type == EventType::KeyDown
          @down = true
        elsif e.type == EventType::KeyUp
          @down = false
        end

        return true
      elsif e.key == DoomKey::F
        if e.type == EventType::KeyDown
          @follow = !@follow
          if @follow
            @world.as(World).console_player.send_message(DoomInfo::Strings::AMSTR_FOLLOWON)
          else
            @world.as(World).console_player.send_message(DoomInfo::Strings::AMSTR_FOLLOWOFF)
          end
          return true
        end
      elsif e.key == DoomKey::M
        if e.type == EventType::KeyDown
          if @marks.size < 10
            @marks << Vertex.new(@view_x, @view_y)
          else
            @marks[@next_mark_number] = Vertex.new(@view_x, @view_y)
          end
          @next_mark_number += 1
          @next_mark_number = 0 if @next_mark_number == 10
          @world.as(World).console_player.send_message(DoomInfo::Strings::AMSTR_MARKEDSPOT)
          return true
        end
      elsif e.key == DoomKey::C
        if e.type == EventType::KeyDown
          @marks.clear
          @next_mark_number = 0
          @world.as(World).console_player.send_message(DoomInfo::Strings::AMSTR_MARKSCLEARED)
          return true
        end
      end

      return false
    end

    def open
      @visible = true
    end

    def close
      @visible = false
      @zoom_in = false
      @zoom_out = false
      @left = false
      @right = false
      @up = false
      @down = false
    end

    def toggle_cheat
      @state += 1
      if @state.to_i32 == 3
        @state = AutoMapState::None
      end
    end
  end
end
