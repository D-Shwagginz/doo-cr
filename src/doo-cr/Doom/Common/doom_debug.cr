#
# Copyright (C) 1993-1996 Id Software, Inc.
# Copyright (C) 2019-2020 Nobuaki Tanaka
# Copyright (C) 2024 Devin Shwagginz
#
# This program is free software you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#

module Doocr
  module DoomDebug
    def self.combine_hash(a : Int32, b : Int32) : Int32
      return (3 * a) ^ b
    end

    def self.get_mobj_hash(mobj : Mobj) : Int32
      hash = 0

      hash = combine_hash(hash, mobj.x.data)
      hash = combine_hash(hash, mobj.y.data)
      hash = combine_hash(hash, mobj.z.data)

      hash = combine_hash(hash, mobj.angle.data.to_i32)
      hash = combine_hash(hash, mobj.sprite.to_i32)
      hash = combine_hash(hash, mobj.frame)

      hash = combine_hash(hash, mobj.floor_z.data)
      hash = combine_hash(hash, mobj.ceiling_z.data)

      hash = combine_hash(hash, mobj.radius.data)
      hash = combine_hash(hash, mobj.height.data)

      hash = combine_hash(hash, mobj.mom_x.data)
      hash = combine_hash(hash, mobj.mom_y.data)
      hash = combine_hash(hash, mobj.mom_z.data)

      hash = combine_hash(hash, mobj.tics)
      hash = combine_hash(hash, mobj.flags.to_i32)
      hash = combine_hash(hash, mobj.health)

      hash = combine_hash(hash, mobj.move_dir.to_i32)
      hash = combine_hash(hash, mobj.move_count)

      hash = combine_hash(hash, mobj.reaction_time)
      hash = combine_hash(hash, mobj.threshold)

      return hash
    end

    def self.get_mobj_hash(world : World) : Int32
      hash = 0
      enumerator = world.as(World).thinkers.as(Thinkers).get_enumerator
      while true
        thinker = enumerator.current
        if mobj = thinker.as?(Mobj)
          hash = combine_hash(hash, get_mobj_hash(mobj))
        end
        break if !enumerator.move_next
      end
      return hash
    end

    def self.get_mobj_csv(mobj : Mobj) : String
      str = String.build do |sb|
        sb << "#{mobj.x.data},"
        sb << "#{mobj.y.data},"
        sb << "#{mobj.z.data},"

        sb << "#{mobj.angle.data.to_i32},"
        sb << "#{mobj.sprite.to_i32},"
        sb << "#{mobj.frame},"

        sb << "#{mobj.floor_z.data},"
        sb << "#{mobj.ceiling_z.data},"

        sb << "#{mobj.radius.data},"
        sb << "#{mobj.height.data},"

        sb << "#{mobj.mom_x.data},"
        sb << "#{mobj.mom_y.data},"
        sb << "#{mobj.mom_z.data},"

        sb << "#{mobj.tics.to_i32},"
        sb << "#{mobj.flags.to_i32},"
        sb << "#{mobj.health},"

        sb << "#{mobj.move_dir.to_i32},"
        sb << "#{mobj.move_count},"

        sb << "#{mobj.reaction_time},"
        sb << "#{mobj.threshold},"
      end

      return str
    end

    def self.dump_mobj_csv(path : String, world : World)
      File.open(string, "w") do |file|
        enumerator = @world.as(World).thinkers.as(Thinkers).get_enumerator
        while true
          thinker = enumerator.current
          if mobj = thinker.as?(Mobj)
            file.puts(get_mobj_csv(mobj))
          end
          break if !enumerator.move_next
        end
      end
    end

    def self.get_sector_hash(sector : Sector) : Int32
      hash = 0

      hash = combine_hash(hash, sector.floor_height.data)
      hash = combine_hash(hash, sector.ceiling_height.data)
      hash = combine_hash(hash, sector.light_level)

      return hash
    end

    def self.get_sector_hash(world : World) : Int32
      hash = 0
      world.map.as(Map).sectors.each do |sector|
        hash = combine_hash(hash, get_sector_hash(sector))
      end
      return hash
    end
  end
end
