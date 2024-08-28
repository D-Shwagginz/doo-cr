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
  class Specials
    @@max_button_count : Int32 = 32
    @@button_time : Int32 = 35

    @world : World | Nil = nil

    @level_timer : Bool = false
    @level_time_count : Int32 = 0

    @button_list : Array(Button) = Array(Button).new

    getter texture_translation : Array(Int32) = Array(Int32).new
    getter flat_translation : Array(Int32) = Array(Int32).new

    @scroll_lines : Array(LineDef) = Array(LineDef).new

    def initialize(@world : World)
      @level_timer = false

      @button_list = Array.new(@@max_button_count, Button.new)

      @texture_translation = Array.new(@world.as(World).map.as(Map).textures.as(ITextureLookup).size, 0)
      @world.as(World).map.as(Map).textures.as(ITextureLookup).size.times do |i|
        @texture_translation << i
      end

      @flat_translation = Array.new(@world.as(World).map.as(Map).flats.as(IFlatLookup).size, 0)
      @world.as(World).map.as(Map).flats.as(IFlatLookup).size.times do |i|
        @flat_translation << i
      end
    end

    # After the map has been loaded, scan for specials that spawn thinkers.
    def spawn_specials(level_time_count : Int32)
      @level_timer = true
      @level_time_count = level_time_count
      spawn_specials()
    end

    # After the map has been loaded, scan for specials that spawn thinkers.
    def spawn_specials
      # Init special sectors.
      lc = @world.as(World).lighting_change.as(LightingChange)
      sa = @world.as(World).sector_action.as(SectorAction)
      @world.as(World).map.as(Map).sectors.each do |sector|
        next if sector.special.to_i32 == 0

        case sector.special.to_i32
        when 1
          # Flickering lights.
          lc.spawn_light_flash(sector)
          break
        when 2
          # Strobe fast.
          lc.spawn_strobe_flash(sector, StrobeFlash.fast_dark, false)
          break
        when 3
          # Strobe slow
          lc.spawn_strobe_flash(sector, StrobeFlash.slow_dark, false)
          break
        when 4
          # Strobe fast / death slime.
          lc.spawn_strobe_flash(sector, StrobeFlash.fast_dark, false)
          sector.special = SectorSpecial.new(4)
          break
        when 8
          # Glowing light.
          lc.spawn_glowing_light(sector)
          break
        when 9
          # Secret sector.
          @world.as(World).total_secrets += 1
          break
        when 10
          # Door close in 30 seconds.
          sa.spawn_door_close_in_30(sector)
          break
        when 12
          # Sync strobe slow.
          lc.spawn_strobe_flash(sector, StrobeFlash.slow_dark, true)
          break
        when 13
          # Sync strobe fast
          lc.spawn_strobe_flash(sector, StrobeFlash.fast_dark, true)
          break
        when 14
          # Door raise in 5 minutes.
          sa.spawn_door_raise_in_5_mins(sector)
          break
        when 17
          lc.spawn_fire_flicker(sector)
          break
        end
      end

      scroll_list = [] of LineDef
      @world.as(World).map.as(Map).lines.each do |line|
        case line.special.to_i32
        when 48
          # Texture scroll.
          scroll_list << line
          break
        end
      end

      @scroll_lines = scroll_list
    end

    def change_switch_texture(line : LineDef, use_again : Bool)
      line.special = LineSpecial.new(0) if !use_again

      front_side = line.front_side.as(SideDef)
      top_texture = front_side.as(SideDef).top_texture
      middle_texture = front_side.as(SideDef).middle_texture
      bottom_texture = front_side.as(SideDef).bottom_texture

      sound = Sfx::SWTCHN

      # Exit switch?
      sound = Sfx::SWTCHX if line.special.to_i32 == 11

      switch_list = @world.as(World).map.as(Map).textures.as(ITextureLookup).switch_list

      switch_list.size.times do |i|
        if switch_list[i] == top_texture
          @world.as(World).start_sound(line.sound_origin.as(Mobj), sound, SfxType::Misc)
          front_side.top_texture = switch_list[i ^ 1]

          if use_again
            start_button(line, ButtonPosition::Top, switch_list[i], @@button_time)
          end

          return
        elsif switch_list[i] == middle_texture
          @world.as(World).start_sound(line.sound_origin.as(Mobj), sound, SfxType::Misc)
          front_side.middle_texture = switch_list[i ^ 1]

          if use_again
            start_button(line, ButtonPosition::Middle, switch_list[i], @@button_time)
          end

          return
        elsif switch_list[i] == bottom_texture
          @world.as(World).start_sound(line.sound_origin.as(Mobj), sound, SfxType::Misc)
          front_side.bottom_texture = switch_list[i ^ 1]

          if use_again
            start_button(line, ButtonPosition::Bottom, switch_list[i], @@button_time)
          end

          return
        end
      end
    end

    private def start_button(line : LineDef, w : ButtonPosition, texture : Int32, time : Int32)
      # See if button is already pressed
      @@max_button_count.times do |i|
        return if @button_list[i].timer != 0 && @button_list[i].line == line
      end

      @@max_button_count.times do |i|
        if @button_list[i].timer == 0
          @button_list[i].line = line
          @button_list[i].position = w
          @button_list[i].texture = texture
          @button_list[i].timer = time
          @button_list[i].sound_origin = line.sound_origin
          return
        end
      end

      raise "No button slots left!"
    end

    # Animate planes, scroll walls, etc.
    def update
      # Level timer
      if @level_timer
        @level_time_count -= 1
        if @level_time_count == 0
          @world.as(World).exit_level
        end
      end

      # Animate flats and textures globally.
      animations = @world.as(World).map.as(Map).animation.as(TextureAnimation).animations
      animations.size.times do |k|
        anim = animations[k]
        i = anim.base_pic
        while i < anim.base_pic + anim.num_pics
          pic = anim.base_pic + ((@world.as(World).level_time / anim.speed + i) % anim.num_pics)
          if anim.is_texture
            @texture_translation[i] = pic.to_i32
          else
            @flat_translation[i] = pic.to_i32

            i += 1
          end
        end
      end

      # Animate line specials.
      @scroll_lines.each do |line|
        line.front_side.as(SideDef).texture_offset += Fixed.one
      end

      # Do buttons.
      @@max_button_count.times do |i|
        if @button_list[i].timer > 0
          @button_list[i].timer -= 1

          if @button_list[i].timer == 0
            case @button_list[i].position
            when ButtonPosition::Top
              @button_list[i].line.as(LineDef).front_side.as(SideDef).top_texture = @button_list[i].texture
              break
            when ButtonPosition::Middle
              @button_list[i].line.as(LineDef).front_side.as(SideDef).middle_texture = @button_list[i].texture
              break
            when ButtonPosition::Bottom
              @button_list[i].line.as(LineDef).front_side.as(SideDef).bottom_texture = @button_list[i].texture
              break
            end

            @world.as(World).start_sound(@button_list[i].sound_origin.as(Mobj), Sfx::SWTCHN, SfxType::Misc, 50)
            @button_list[i].clear
          end
        end
      end
    end
  end
end
