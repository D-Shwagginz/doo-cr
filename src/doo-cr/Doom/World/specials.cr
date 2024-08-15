module Doocr
  class Specials
    @@max_button_count : Int32 = 32
    @@buton_time : Int32 = 35

    @world : World

    @level_timer : Bool
    @level_time_count : Int32

    @button_list : Array(Button)

    getter texture_translation : Array(Int32)
    getter flat_translation : Array(Int32)

    @scroll_lines : Array(LineDef)

    def initialize(@world : World)
      @level_timer = false

      @button_list = Array.new(@@max_button_count, Button.new)

      @texture_translation = Array.new(@world.map.textures.size)
      @world.map.textures.size.times do |i|
        @texture_translation << i
      end

      @flat_translation = Array.new(@world.map.flats.size)
      @world.map.flats.size.times do |i|
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
      lc = @world.lighting_change
      sa = @world.sector_actiong
      @world.map.sectors.each do |sector|
        next if sector.special == 0

        case sector.special.to_i
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
          lc.spawn_strobe_flash(sector.StrobeFlash.fast_dark, false)
          sector.special = SectorSpecial.new(4)
          break
        when 8
          # Glowing light.
          lc.spawn_glowing_light(sector)
          break
        when 9
          # Secret sector.
          @world.total_secrets += 1
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
      @world.map.lines.each do |line|
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
      line.special = 0 if !use_again

      front_side = line.front_side
      top_texture = front_side.top_texture
      middle_texture = front_side.middle_texture
      bottom_texture = front_side.bottom_texture

      sound = Sfx::SWTCHN

      # Exit switch?
      sound = Sfx::SWTCHX if line.special.to_i32 == 11

      switch_list = @world.map.textures.switch_list

      switch_list.size.times do |i|
        if switch_list[i] == top_texture
          @world.start_sound(line.sound_origin, sound, SfxType::Misc)
          front_side.top_texture = switch_list[i ^ 1]

          if use_again
            start_button(line, ButtonPosition::Top, switch_list[i], @@button_time)
          end

          return
        elsif switch_list[i] == middle_texture
          @world.start_sound(line.sound_origin, sound, SfxType::Misc)
          front_side.middle_texture = switch_list[i ^ 1]

          if use_again
            start_button(line, ButtonPosition::Middle, switch_list[i], @@button_time)
          end

          return
        elsif switch_list[i] == bottom_texture
          @world.start_sound(line.sound_origin, sound, SfxType::Misc)
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
          @world.exit_level
        end
      end

      # Animate flats and textures globally.
      animations = @world.map.animation.animations
      animations.size.times do |k|
        anim = animations[k]
        i = anim.base_pic
        while i < anim.base_pic + anim.num_pics
          pic = anim.base_pic + ((@world.level_time / anim.speed + i) % anim.num_pics)
          if anim.is_texture
            @texture_translation[i] = pic
          else
            @flat_translation[i] = pic

            i += 1
          end
        end
      end

      # Animate line specials.
      @scroll_lines.each do |line|
        line.front_side.texture_offset += Fixed.one
      end

      # Do buttons.
      @@max_button_count.times do |i|
        if @button_list[i].timer > 0
          @button_list[i].timer -= 1

          if @button_list[i].timer == 0
            case @button_list[i].position
            when ButtonPosition::Top
              @button_list[i].line.front_side.top_texture = @button_list[i].texture
              break
            when ButtonPosition::Middle
              @button_list[i].line.front_side.middle_texture = @button_list[i].texture
              break
            when ButtonPosition::Bottom
              @button_list[i].line.front_side.bottom_texture = @button_list[i].texture
              break
            end

            @world.start_sound(@button_list[i].sound_origin, Sfx::SWTCHN, SfxType::Misc, 50)
            @button_list[i].clear
          end
        end
      end
    end
  end
end
