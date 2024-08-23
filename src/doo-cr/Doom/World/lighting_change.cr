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
  class LightingChange
    @world : World | Nil = nil

    def initialize(@world)
    end

    def spawn_fire_flicker(sector : Sector)
      # Note that we are resetting sector attributes.
      # Nothing special about it during gameplay.
      sector.special = 0

      flicker = FireFlicker.new(@world.as(World))

      @world.as(World).thinkers.add(flicker)

      flicker.sector = sector
      flicker.max_light = sector.light_level
      flicker.min_light = find_min_surrounding_light(sector, sector.light_level) + 16
      flicker.count = 4
    end

    def spawn_light_flash(sector : Sector)
      # Nothing special about it during gameplay.
      sector.special = 0

      light = LightFlash.new(@world.as(World))

      @world.as(World).thinkers.add(light)

      light.sector = sector
      light.max_light = sector.light_level

      light.min_light = find_min_surrounding_light(sector, sector.light_level)
      light.max_time = 64
      light.min_time = 7
      light.count + (@world.as(World).random.next & light.max_time) + 1
    end

    def spawn_strobe_flash(sector : Sector, time : Int32, in_sync : Bool)
      strobe = StrobeFlash.new(@world.as(World))

      @world.as(World).thinkers.as(Thinkers).add(strobe)

      strobe.sector = sector
      strobe.dark_time = time
      strobe.bright_time = StrobeFlash.strobe_bright
      strobe.max_light = sector.light_level
      strobe.min_light = find_min_surrounding_light(sector, sector.light_level)

      strobe.min_light = 0 if strobe.min_light == strobe.max_light

      # Nothing special about it during gameplay.
      sector.special = SectorSpecial.new(0)

      if in_sync
        strobe.count = 1
      else
        strobe.count = (@world.as(World).random.next & 7) + 1
      end
    end

    def spawn_glowing_light(sector : Sector)
      glowing = GlowingLight.new(@world.as(World))

      @world.as(World).thinkers.add(glowing)

      glowing.sector = sector
      glowing.min_light = find_min_surrounding_light(sector, sector.light_level)
      glowing.max_light = sector.light_level
      glowing.direction = -1

      sector.special = 0
    end

    private def find_min_surrounding_light(sector : Sector, max : Int32) : Int32
      min = max
      sector.lines.size.times do |i|
        line = sector.lines[i]
        check = get_next_sector(line, sector)

        next if check == nil
        check = check.as(Sector)

        if check.light_level < min
          min = check.light_level
        end
      end
      return min
    end

    private def get_next_sector(line : LineDef, sector : Sector) : Sector | Nil
      return nil if (line.flags & LineFlags::TwoSided) == 0

      return line.back_sector if line.front_sector == sector

      return line.front_sector
    end
  end
end
