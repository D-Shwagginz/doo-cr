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
  class SectorAction
    # SECTOR HEIGHT CHANGING
    # After modifying a sectors floor or ceiling height,
    # call this routine to adjust the positions
    # of all things that touch the sector.
    #
    # If anything doesn't fit anymore, true will be returned.
    # If crunch is true, they will take damage
    # as they are being crushed.
    # If Crunch is false, you should set the sector height back
    # the way it was and call P_ChangeSector again
    # to undo the changes.

    @world : World | Nil = nil

    def initialize(@world)
      init_sector_change()
    end

    @crush_change : Bool = false
    @no_fit : Bool = false
    @crush_thing_func : Proc(Mobj, Bool) | Nil = nil

    private def init_sector_change
      @crush_thing_func = crush_thing()
    end

    private def thing_height_clip(thing : Mobj) : Bool
      on_floor = thing.z == thing.floor_z

      tm = @world.as(World).thing_movement

      tm.check_position(thing, thing.x, thing.y)
      # What about stranding a monster partially off an edge?

      thing.floor_z = tm.current_floor_z
      thing.ceiling_z = tm.current_ceiling_z

      if on_floor
        # Walking monsters rise and fall with the floor.
        thing.z = thing.floor_z
      else
        # Don't adjust a floating monster unless forced to.
        if thing.z + thing.height > thing.ceiling_z
          thing = thing.ceiling_z - thing.height
        end
      end

      return false if thing.ceiling_z - thing.floor_z < thing.height

      return true
    end

    private def crush_thing(thing : Mobj) : Bool
      if thing_height_clip(thing)
        # Keep checking.
        return true
      end

      # Crunch bodies to giblets.
      if thing.health <= 0
        thing.set_state(MobjState::Gibs)
        thing.flags &= ~MobjFlags::Solid
        thing.height = Fixed.zero
        thing.radius = Fixed.zero

        # Keep checking.
        return true
      end

      # Crunch dropped items.
      if (thing.flags & MobjFlags::Dropped) != 0
        @world.as(World).thing_allocation.remove_mobj(thing)

        # Keep checking.
        return true
      end

      if (thing.flags & MobjFlags::Shootable) == 0
        # Assume it is bloody gibs or something
        return true
      end

      @no_fit = true

      if @crush_change && (@world.as(World).level_time & 3) == 0
        @world.as(World).thing_interaction.damage_mobj(thing, nil, nil, 10)

        # Spray blood in a random direction.
        blood = @world.as(World).thing_allocation.spawn_mobj(
          thing.x,
          thing.y,
          thing.z + thing.height / 2,
          MobjType::Blood
        )

        random = @world.as(World).random
        blood.mom_x = Fixed.new((random.next - random.next) << 12)
        blood.mom_y = Fixed.new((random.next - random.next) << 12)
      end

      # Keep checking (crush other things).
      return true
    end

    private def change_sector(sector : Sector, crunch : Bool) : Bool
      @no_fit = false
      @crush_change = crunch

      bm = @world.as(World).map.blockmap
      block_box = sector.block_box

      # Re-check heights for all things near the moving sector.
      x = block_box.left
      while x <= block_box.right
        y = block_box.bottom
        while y <= block_box.top
          bm.iterate_things(x, y, @crush_thing_func)
          y += 1
        end
        x += 1
      end

      return @no_fit
    end

    # Move a plane (floor or ceiling) and check for crushing.
    def move_plane(
      sector : Sector,
      speed : Fixed,
      dest : Fixed,
      crush : Bool,
      floor_or_ceiling : Int32,
      direction : Int32
    ) : SectorActionResult
      case floor_or_ceiling
      when 0
        # Floor
        case direction
        when -1
          # Down.
          if sector.as(Sector).floor_height - speed < dest
            last_pos = sector.as(Sector).floor_height
            sector.as(Sector).floor_height = dest
            if change_sector(sector, crush)
              sector.as(Sector).floor_height = last_pos
              change_sector(sector, crush)
            end

            return SectorActionResult::PastDestination
          else
            last_pos = sector.as(Sector).floor_height
            sector.as(Sector).floor_height -= speed
            if change_sector(sector, crush)
              sector.as(Sector).floor_height = last_pos
              change_sector(sector, crush)

              return SectorActionResult::Crushed
            end
          end
        when 1
          # Up.
          if sector.as(Sector).floor_height + speed > dest
            last_pos = sector.as(Sector).floor_height
            sector.as(Sector).floor_height = dest
            if change_sector(sector, crush)
              sector.as(Sector).floor_height = last_pos
              change_sector(sector, crush)
            end

            return SectorActionResult::PastDestination
          else
            # Could get crushed.
            last_pos = sector.as(Sector).floor_height
            sector.as(Sector).floor_height += speed
            if change_sector(sector, crush)
              return SectorActionResult::Crushed if crush
              sector.as(Sector).floor_height = last_pos
              change_sector(sector, crush)

              return SectorActionResult::Crushed
            end
          end
        end
      when 1
        # Ceiling.
        case direction
        when -1
          # Down.
          if sector.ceiling_height - speed < dest
            last_pos = sector.ceiling_height
            sector.ceiling_height = dest
            if change_sector(sector, crush)
              sector.ceiling_height = last_pos
              change_sector(sector, crush)
            end

            return SectorActionResult::PastDestination
          else
            # Could get crushed.
            last_pos = sector.ceiling_height
            sector.ceiling_height -= speed
            if change_sector(sector, crush)
              return SectorActionResult::Crushed if crush
              sector.ceiling_height = last_pos
              change_sector(sector, crush)

              return SectorActionResult::Crushed
            end
          end
        when 1
          # Up
          if sector.ceiling_height + speed > dest
            last_pos = sector.ceiling_height
            sector.ceiling_height = dest
            if change_sector(sector, crush)
              sector.ceiling_height = last_pos
              change_sector(sector, crush)
            end

            return SectorActionResult::PastDestination
          else
            sector.ceiling_height += speed
            change_sector(sector, crush)
          end
        end
      end

      return SectorActionResult::OK
    end

    private def get_next_sector(line : LineDef, sector : Sector) : Sector | Nil
      return nil if (line.flags & LineFlags::TwoSided) == 0

      return line.back_sector if line.front_sector == sector

      return line.front_sector
    end

    private def find_lowest_floor_surrounding(sector : Sector) : Fixed
      floor = sector.as(Sector).floor_height

      sector.lines.size.times do |i|
        check = sector.lines[i]

        other = get_next_sector(check, sector).as(Sector)
        next if other == nil

        floor = other.floor_height if other.floor_height < floor
      end

      return floor
    end

    private def find_highest_floor_surrounding(sector : Sector) : Fixed
      floor = Fixed.from_i(-500)

      sector.lines.size.times do |i|
        check = sector.lines[i]

        other = get_next_sector(check, sector).as(Sector)
        next if other == nil

        floor = other.floor_height if other.floor_height > floor
      end

      return floor
    end

    private def find_lowest_ceiling_surrounding(sector : Sector) : Fixed
      height = Fixed.max_value

      sector.lines.size.times do |i|
        check = sector.lines[i]

        other = get_next_sector(check, sector)
        next if other == nil

        height = other.as(Sector).ceiling_height if other.as(Sector).ceiling_height < height
      end

      return height
    end

    private def find_highest_ceiling_surrounding(sector : Sector) : Fixed
      height = Fixed.zero

      sector.lines.size.times do |i|
        check = sector.lines[i]

        other = get_next_sector(check, sector)
        next if other == nil
        other = other.as(Sector)

        height = other.ceiling_height if other.ceiling_height > height
      end

      return height
    end

    private def find_sector_from_line_tag(line : LineDef, start : Int32) : Int32
      sectors = @world.as(World).map.as(Map).sectors

      i = start + 1
      while i < sectors.size
        return i if sectors[i].tag == line.tag
        i += 1
      end

      return -1
    end

    #
    # Door
    #

    @@door_speed : Fixed = Fixed.from_i(2)
    @@door_wait : Int32 = 150

    # Open a door manually, no tag value.
    def do_local_door(line : LineDef, thing : Mobj)
      # Check for locks.
      player = thing.player

      case line.special.to_i32
      # Blue Lock.
      when 26, 32
        return if player == nil
        player = player.as(Player)

        if (!player.cards[CardType::BlueCard.to_i32] &&
           !player.cards[CardType::BlueSkull.to_i32])
          player.send_message(DoomInfo::Strings::PD_BLUEK)
          @world.as(World).start_sound(player.mobj.as(Mobj), Sfx::OOF, SfxType::Voice)
          return
        end

        # Yellow Lock.
      when 27, 34
        return if player == nil
        player = player.as(Player)

        if (!player.cards[CardType::YellowCard.to_i32] &&
           !player.cards[CardType::YellowSkull.to_i32])
          player.send_message(DoomInfo::Strings::PD_YELLOWK)
          @world.as(World).start_sound(player.mobj.as(Mobj), Sfx::OOF, SfxType::Voice)
          return
        end

        # Red Lock.
      when 28, 33
        return if player == nil
        player = player.as(Player)

        if (!player.cards[CardType::RedCard.to_i32] &&
           !player.cards[CardType::RedSkull.to_i32])
          player.send_message(DoomInfo::Strings::PD_REDK)
          @world.as(World).start_sound(player.mobj.as(Mobj), Sfx::OOF, SfxType::Voice)
          return
        end
      end

      sector = line.back_side.as(SideDef).sector.as(Sector)

      # If the sector has an active thinker, use it.
      if sector.special_data != nil
        door = sector.special_data.as(VerticalDoor)
        case line.special.to_i32
        # Only for "raise" doors, not "open"s
        when 1, 26, 27, 28, 117
          if door.direction == -1
            # Go back up.
            door.direction = 1
          else
            # Bad guys never close doors.
            return if thing.player == nil

            # Start going down immediately
            door.direction = -1
          end
          return
        end
      end

      # For proper sound.
      case line.special.to_i32
      when 117, 118 # Blazing door raise, blazing door open.
        @world.as(World).start_sound(sector.sound_origin.as(Mobj), Sfx::BDOPN, SfxType::Misc)
        # Normal door sound.
      when 1, 31
        @world.as(World).start_sound(sector.sound_origin.as(Mobj), Sfx::DOROPN, SfxType::Misc)
        # Locked door sound.
      else
        @world.as(World).start_sound(sector.sound_origin.as(Mobj), Sfx::DOROPN, SfxType::Misc)
      end

      # New door thinker.
      new_door = VerticalDoor.new(@world.as(World))
      @world.as(World).thinkers.as(Thinkers).add(new_door)
      sector.special_data = new_door
      new_door.sector = sector
      new_door.direction = 1
      new_door.speed = @@door_speed
      new_door.top_wait = @@door_wait

      case line.special.to_i32
      when 1, 26, 27, 28
        new_door.type = VerticalDoorType::Normal
      when 31, 32, 33, 34
        new_door.type = VerticalDoorType::Open
        line.special = LineSpecial.new(0)

        # Blazing door raise.
      when 117
        new_door.type = VerticalDoorType::BlazeRaise
        new_door.speed = @@door_speed * 4

        # Blazing door open.
      when 118
        new_door.type = VerticalDoorType::BlazeOpen
        line.special = LineSpecial.new(0)
        new_door.speed = @@door_speed * 4
      end

      # Find the top and bottom of the movement range.
      new_door.top_height = find_lowest_ceiling_surrounding(sector)
      new_door.top_height -= Fixed.from_i(4)
    end

    def do_door(line : LineDef, type : VerticalDoorType) : Bool
      sectors = @world.as(World).map.as(Map).sectors
      sector_number = -1
      result = false

      while sector_number = find_sector_from_line_tag(line, sector_number)
        sector = sectors[sector_number]
        next if sector.special_data == nil

        result = true

        # New door thinker.
        door = VerticalDoor.new(@world.as(World))
        @world.as(World).thinkers.as(Thinkers).add(door)
        sector.special_data = door
        door.sector = sector
        door.type = type
        door.top_wait = @@door_wait
        door.speed = @@door_speed

        case type
        when VerticalDoorType::BlazeClose
          door.top_height = find_lowest_ceiling_surrounding(sector)
          door.top_height -= Fixed.from_i(4)
          door.direction = -1
          door.speed = @@door_speed * 4
          @world.as(World).start_sound(door.sector.as(Sector).sound_origin.as(Mobj), Sfx::BDCLS, SfxType::Misc)
        when VerticalDoorType::Close
          door.top_height = find_lowest_ceiling_surrounding(sector)
          door.top_height -= Fixed.from_i(4)
          door.direction = -1
          @world.as(World).start_sound(door.sector.as(Sector).sound_origin.as(Mobj), Sfx::DORCLS, SfxType::Misc)
        when VerticalDoorType::Close30ThenOpen
          door.top_height = sector.ceiling_height
          door.direction = -1
          @world.as(World).start_sound(door.sector.as(Sector).sound_origin.as(Mobj), Sfx::DORCLS, SfxType::Misc)
        when VerticalDoorType::BlazeRaise, VerticalDoorType::BlazeOpen
          door.direction = 1
          door.top_height = find_lowest_ceiling_surrounding(sector)
          door.top_height -= Fixed.from_i(4)
          door.speed = @@door_speed * 4
          if door.top_height != sector.ceiling_height
            @world.as(World).start_sound(door.sector.as(Sector).sound_origin.as(Mobj), Sfx::BDOPN, SfxType::Misc)
          end
        when VerticalDoorType::Normal, VerticalDoorType::Open
          door.direction = 1
          door.top_height = find_lowest_ceiling_surrounding(sector)
          door.top_height -= Fixed.from_i(4)
          if door.top_height != sector.ceiling_height
            @world.as(World).start_sound(door.sector.as(Sector).sound_origin.as(Mobj), Sfx::DOROPN, SfxType::Misc)
          end
        else
        end
      end

      return result
    end

    def do_locked_door(line : LineDef, type : VerticalDoorType, thing : Mobj) : Bool
      player = thing.player
      return false if player == nil
      player = player.as(Player)

      case line.special.to_i32
      # Blue Lock.
      when 99, 133
        if (!player.cards[CardType::BlueCard.to_i32] &&
           !player.cards[CardType::BlueSkull.to_i32])
          player.send_message(DoomInfo::Strings::PD_BLUEO)
          @world.as(World).start_sound(player.mobj.as(Mobj), Sfx::OOF, SfxType::Voice)
          return false
        end
        # Red Lock.
      when 134, 135
        if (!player.cards[CardType::RedCard.to_i32] &&
           !player.cards[CardType::RedSkull.to_i32])
          player.send_message(DoomInfo::Strings::PD_REDO)
          @world.as(World).start_sound(player.mobj.as(Mobj), Sfx::OOF, SfxType::Voice)
          return false
        end
        # Yellow Lock.
      when 136, 137
        if (!player.cards[CardType::YellowCard.to_i32] &&
           !player.cards[CardType::YellowSkull.to_i32])
          player.send_message(DoomInfo::Strings::PD_YELLOWO)
          @world.as(World).start_sound(player.mobj.as(Mobj), Sfx::OOF, SfxType::Voice)
          return false
        end
      end

      return do_door(line, type)
    end

    #
    # Platform
    #

    # In plutonia MAP23, number of adjoining sectors can be 44.
    @@max_adjoining_sector_count : Int32 = 64
    @height_list : Array(Fixed) = Array.new(@@max_adjoining_sector_count, Fixed.zero)

    private def find_next_highest_floor(sector : Sector, current_height : Fixed) : Fixed
      height = current_height
      h = 0

      sector.lines.size.times do |i|
        check = sector.lines[i]

        other = get_next_sector(check, sector)
        next if other == nil
        other = other.as(Sector)

        if other.floor_height > height
          @height_list[h] = other.floor_height
          h += 1
        end

        # Check for overflow.
        if h >= @height_list.size
          # Exit
          raise "Too many adjoining sectors!"
        end
      end

      # Find lowest height in list.
      return current_height if h == 0

      min = @height_list[0]

      # Range checking?
      i = 1
      while i < h
        min = @height_list[i] if @height_list[i] < min
        i += 1
      end

      return min
    end

    @@platform_wait : Int32 = 3
    @@platform_speed : Fixed = Fixed.one

    def do_platform(line : LineDef, type : PlatformType, amount : Int32) : Bool
      # Activate all <type> plats that are in stasis.
      case type
      when PlatformType::PerpetualRaise
        activate_in_stasis(line.tag)
      else
      end

      sectors = @world.as(World).map.as(Map).sectors
      sector_number = -1
      result = false

      while (sector_number = find_sector_from_line_tag(line, sector_number)) >= 0
        sector = sectors[sector_number]
        next if sector.special_data != nil

        result = true

        # Find lowest and highest floors around sector.
        plat = Platform.new(@world)
        @world.as(World).thinkers.as(Thinkers).add(plat)
        plat.type = type
        plat.sector = sector
        plat.sector.as(Sector).special_data = plat
        plat.crush = false
        plat.tag = line.tag

        case type
        when PlatformType::RaiseToNearestAndChange
          plat.speed = @@platform_speed / 2
          sector.floor_flat = line.front_side.as(SideDef).sector.as(Sector).floor_flat
          plat.high = find_next_highest_floor(sector, sector.as(Sector).floor_height)
          plat.wait = 0
          plat.status = PlatformState::Up
          # No more damage, if applicable
          sector.special = SectorSpecial.new(0)
          @world.as(World).start_sound(sector.sound_origin.as(Mobj), Sfx::STNMOV, SfxType::Misc)
        when PlatformType::RaiseAndChange
          plat.speed = @@platform_speed / 2
          sector.floor_flat = line.front_side.as(SideDef).sector.as(Sector).floor_flat
          plat.high = sector.as(Sector).floor_height + Fixed.one * amount
          plat.wait = 0
          plat.status = PlatformState::Up
          @world.as(World).start_sound(sector.sound_origin.as(Mobj), Sfx::STNMOV, SfxType::Misc)
        when PlatformType::DownWaitUpStay
          plat.speed = @@platform_speed * 4
          plat.low = find_lowest_floor_surrounding(sector)
          plat.low = sector.as(Sector).floor_height if plat.low > sector.as(Sector).floor_height
          plat.high = sector.as(Sector).floor_height
          plat.wait = 35 * @@platform_wait
          plat.status = PlatformState::Down
          @world.as(World).start_sound(sector.sound_origin.as(Mobj), Sfx::PSTART, SfxType::Misc)
        when PlatformType::BlazeDwus
          plat.speed = @@platform_speed * 8
          plat.low = find_lowest_floor_surrounding(sector)
          plat.low = sector.as(Sector).floor_height if plat.low > sector.as(Sector).floor_height
          plat.high = sector.as(Sector).floor_height
          plat.wait = 35 * @@platform_wait
          plat.status = PlatformState::Down
          @world.as(World).start_sound(sector.sound_origin.as(Mobj), Sfx::PSTART, SfxType::Misc)
        when PlatformType::PerpetualRaise
          plat.speed = @@platform_speed
          plat.low = find_lowest_floor_surrounding(sector)
          plat.low = sector.as(Sector).floor_height if plat.low > sector.as(Sector).floor_height
          plat.high = find_highest_floor_surrounding(sector)
          plat.high = sector.as(Sector).floor_height if plat.high < sector.as(Sector).floor_height
          plat.wait = 35 * @@platform_wait
          plat.status = PlatformState.new(@world.as(World).random.next & 1)
          @world.as(World).start_sound(sector.sound_origin.as(Mobj), Sfx::PSTART, SfxType::Misc)
        end

        add_active_platform(plat)
      end

      return result
    end

    @@max_platform_count : Int32 = 60
    @active_platforms : Array(Platform | Nil) = Array(Platform | Nil).new(@@max_platform_count, nil)

    def activate_in_stasis(tag : Int32)
      @active_platforms.size.times do |i|
        if (@active_platforms[i] != nil &&
           @active_platforms[i].as(Platform).tag == tag &&
           @active_platforms[i].as(Platform).status == PlatformState::InStasis)
          @active_platforms[i].as(Platform).status = @active_platforms[i].as(Platform).old_status
          @active_platforms[i].as(Platform).thinker_state = ThinkerState::Active
        end
      end
    end

    def stop_platform(line : LineDef)
      @active_platforms.size.times do |j|
        if (@active_platforms[j] != nil &&
           @active_platforms[j].as(Platform).status != PlatformState::InStasis &&
           @active_platforms[j].as(Platform).tag == line.tag
             )
          @active_platforms[j].as(Platform).old_status = @active_platforms[j].as(Platform).status
          @active_platforms[j].as(Platform).status = PlatformState::InStasis
          @active_platforms[j].as(Platform).thinker_state = ThinkerState::InStasis
        end
      end
    end

    def add_active_platform(platform : Platform)
      @active_platforms.size.times do |i|
        if @active_platforms[i] == nil
          @active_platforms[i] = platform

          return
        end
      end

      raise "Too many active platforms!"
    end

    def remove_active_platform(platform : Platform)
      @active_platforms.size.times do |i|
        if platform == @active_platforms[i]
          @active_platforms[i].sector.special_data = nil
          @world.as(World).thinkers.remove(@active_platforms[i])
          @active_platforms[i] = nil
          return
        end
      end

      raise "The platform was not found!"
    end

    #
    # Floor
    #

    @@floor_speed : Fixed = Fixed.one

    def do_floor(line : LineDef, type : FloorMoveType) : Bool
      sectors = @world.as(World).map.as(Map).sectors
      sector_number = -1
      result = false

      while (sector_number = find_sector_from_line_tag(line, sector_number)) >= 0
        sector = sectors[sector_number]

        # Already moving? If so, keep going...
        next if sector.special_data != nil

        result = true

        # New floor thinker.
        floor = FloorMove.new(@world.as(World))
        @world.as(World).thinkers.as(Thinkers).add(floor)
        sector.special_data = floor
        floor.type = type
        floor.crush = false

        case type
        when FloorMoveType::LowerFloor
          floor.direction = -1
          floor.sector = sector
          floor.speed = @@floor_speed
          floor.floor_dest_height = find_highest_floor_surrounding(sector)
        when FloorMoveType::LowerFloorToLowest
          floor.direction = -1
          floor.sector = sector
          floor.speed = @@floor_speed
          floor.floor_dest_height = find_lowest_floor_surrounding(sector)
        when FloorMoveType::TurboLower
          floor.direction = -1
          floor.sector = sector
          floor.speed = @@floor_speed * 4
          floor.floor_dest_height = find_highest_floor_surrounding(sector)
        when FloorMoveType::RaiseFloorCrush, FloorMoveType::RaiseFloor
          floor.crush = true if type == FloorMoveType::RaiseFloorCrush
          floor.direction = 1
          floor.sector = sector
          floor.speed = @@floor_speed
          floor.floor_dest_height = find_lowest_ceiling_surrounding(sector)
          floor.floor_dest_height = sector.ceiling_height if floor.floor_dest_height > sector.ceiling_height
          floor.floor_dest_height -= Fixed.from_i(8) * (type == FloorMoveType::RaiseFloorCrush ? 1 : 0)
        when FloorMoveType::RaiseFloorTurbo
          floor.direction = 1
          floor.sector = sector
          floor.speed = @@floor_speed * 4
          floor.floor_dest_height = find_next_highest_floor(sector, sector.as(Sector).floor_height)
        when FloorMoveType::RaiseFloorToNearest
          floor.direction = 1
          floor.sector = sector
          floor.speed = @@floor_speed
          floor.floor_dest_height = find_next_highest_floor(sector, sector.as(Sector).floor_height)
        when FloorMoveType::RaiseFloor24
          floor.direction = 1
          floor.sector = sector
          floor.speed = @@floor_speed
          floor.floor_dest_height = floor.sector.as(Sector).floor_height + Fixed.from_i(24)
        when FloorMoveType::RaiseFloor512
          floor.direction = 1
          floor.sector = sector
          floor.speed = @@floor_speed
          floor.floor_dest_height = floor.sector.as(Sector).floor_height + Fixed.from_i(512)
        when FloorMoveType::RaiseFloor24AndChange
          floor.direction = 1
          floor.sector = sector
          floor.speed = @@floor_speed
          floor.floor_dest_height = floor.sector.as(Sector).floor_height + Fixed.from_i(24)
          sector.floor_flat = line.front_sector.as(Sector).floor_flat
          sector.special = line.front_sector.as(Sector).special
        when FloorMoveType::RaiseToTexture
          min = Int32::MAX
          floor.direction = 1
          floor.sector = sector
          floor.speed = @@floor_speed
          textures = @world.as(World).map.as(Map).textures
          sector.lines.size.times do |i|
            if (sector.lines[i].flags & LineFlags::TwoSided) != 0
              front_side = sector.lines[i].front_side.as(SideDef)
              if front_side.bottom_texture >= 0
                if textures[front_side.bottom_texture].height < min
                  min = textures[front_side.bottom_texture].height
                end
              end
              back_side = sector.lines[i].back_side.as(SideDef)
              if back_side.bottom_texture >= 0
                if textures[back_side.bottom_texture].height < min
                  min = textures[back_side.bottom_texture].height
                end
              end
            end
          end
          floor.floor_dest_height = floor.sector.as(Sector).floor_height + Fixed.from_i(min)
        when FloorMoveType::LowerAndChange
          floor.direction = -1
          floor.sector = sector
          floor.speed = @@floor_speed
          floor.floor_dest_height = find_lowest_floor_surrounding(sector)
          floor.texture = sector.floor_flat
          sector.lines.size.times do |i|
            if (sector.as(Sector).lines[i].flags & LineFlags::TwoSided) != 0
              if sector.as(Sector).lines[i].front_side.as(SideDef).sector.as(Sector).number == sector_number
                sector = sector.as(Sector).lines[i].back_side.as(SideDef).sector
                if sector.as(Sector).floor_height == floor.floor_dest_height
                  floor.texture = sector.as(Sector).floor_flat
                  floor.new_special = sector.as(Sector).special.as(SectorSpecial)
                end
              else
                sector = sector.as(Sector).lines[i].front_side.as(SideDef).sector
                if sector.as(Sector).floor_height == floor.floor_dest_height
                  floor.texture = sector.as(Sector).floor_flat
                  floor.new_special = sector.as(Sector).special.as(SectorSpecial)
                end
              end
            end
          end
        end
      end

      return result
    end

    def build_stairs(line : LineDef, type : StairType) : Bool
      sectors = @world.as(World).map.as(Map).sectors
      sector_number = -1
      result = false

      while (sector_number = find_sector_from_line_tag(line, sector_number))
        sector = sectors[sector_number]

        # Already moving? If so, keep going...
        next if sector.special_data != nil

        result = true

        # New floor thinker.
        floor = FloorMove.new(@world.as(World))
        @world.as(World).thinkers.as(Thinkers).add(floor)
        sector.special_data = floor
        floor.direction = 1
        floor.sector = sector

        speed : Fixed
        stair_size : Fixed
        case type
        when StairType::Build8
          speed = @@floor_speed / 4
          stair_size = Fixed.from_i(8)
        when StairType::Turbo16
          speed = @@floor_speed * 4
          stair_size = Fixed.from_i(16)
        else
          raise "Unknown stair type!"
        end

        floor.speed = speed
        height = sector.as(Sector).floor_height + stair_size
        floor.floor_dest_height = height

        texture = sector.floor_flat

        # Find next sector to raise.
        #     1. Find 2-sided line with same sector side[0].
        #     2. Other side is the next sector to raise.
        j = true
        ok : Bool = false
        while j || ok
          j = false
          ok = false

          sector.lines.size.times do |i|
            next if (sector.lines[i].flags & LineFlags::TwoSided) == 0

            target = sector.lines[i].front_sector.as(Sector)
            new_sector_number = target.number

            next if sector_number != new_sector_number

            target = sector.lines[i].back_sector.as(Sector)
            new_sector_number = target.number

            next if target.floor_flat != texture

            height += stair_size

            next if target.special_data != nil

            sector = target
            sector_number = new_sector_number
            floor = FloorMove.new(@world.as(World))

            @world.as(World).thinkers.as(Thinkers).add(floor)

            sector.special_data = floor
            floor.direction = 1
            floor.sector = sector
            floor.speed = speed
            floor.floor_dest_height = height
            ok = true
            break
          end
        end
      end

      return result
    end

    #
    # Ceiling
    #

    def do_ceiling(line : LineDef, type : CeilingMoveType) : Bool
      # Reactivate in-stasis ceilings...for certain types.
      case type
      when CeilingMoveType::FastCrushAndRaise, CeilingMoveType::SilentCrushAndRaise, CeilingMoveType::CrushAndRaise
        activate_in_stasis_ceiling(line)
      else
      end

      sectors = @world.as(World).map.as(Map).sectors
      sector_number = -1
      result = false

      while (sector_number = find_sector_from_line_tag(line, sector_number))
        sector = sectors[sector_number]
        next if sector.special_data != nil

        result = true

        # New door thinker.
        ceiling = CeilingMove.new(@world.as(World))
        @world.as(World).thinkers.as(Thinkers).add(ceiling)
        sector.special_data = ceiling
        ceiling.sector = sector
        ceiling.crush = false

        case type
        when CeilingMoveType::FastCrushAndRaise
          ceiling.crush = true
          ceiling.top_height = sector.ceiling_height
          ceiling.bottom_height = sector.as(Sector).floor_height + Fixed.from_i(8)
          ceiling.direction = -1
          ceiling.speed = @@ceiling_speed * 2
        when CeilingMoveType::SilentCrushAndRaise, CeilingMoveType::CrushAndRaise, CeilingMoveType::LowerAndCrush, CeilingMoveType::LowerToFloor
          if (type == CeilingMoveType::SilentCrushAndRaise ||
             type == CeilingMoveType::CrushAndRaise)
            ceiling.crush = true
            ceiling.top_height = sector.ceiling_height
          end
          ceiling.bottom_height = sector.as(Sector).floor_height
          if type != CeilingMoveType::LowerToFloor
            ceiling.bottom_height += Fixed.from_i(8)
          end
          ceiling.direction = -1
          ceiling.speed = @@ceiling_speed
        when CeilingMoveType::RaiseToHighest
          ceiling.top_height = find_highest_ceiling_surrounding(sector)
          ceiling.direction = 1
          ceiling.speed = @@ceiling_speed
        end

        ceiling.tag = sector.tag
        ceiling.type = type
        add_active_ceiling(ceiling)
      end

      return result
    end

    @@ceiling_speed : Fixed = Fixed.one
    @@ceiling_w_wait : Int32 = 150

    @@max_ceiling_count : Int32 = 30

    @active_ceilings : Array(CeilingMove | Nil) = Array(CeilingMove | Nil).new(@@max_platform_count, nil)

    def add_active_ceiling(ceiling : CeilingMove)
      @active_ceilings.size.times do |i|
        if @active_ceilings[i] == nil
          @active_ceilings[i] = ceiling

          return
        end
      end
    end

    def remove_active_ceiling(ceiling : CeilingMove)
      @active_ceilings.size.times do |i|
        if @active_ceilings[i] == ceiling
          @active_ceilings[i].sector.special_data = nil
          @world.as(World).thinkers.remove(@active_ceilings[i])
          @active_ceilings[i] = nil
          break
        end
      end
    end

    def check_active_ceiling(ceiling : CeilingMove | Nil) : Bool
      return false if ceiling = nil

      @active_ceilings.size.times do |i|
        return true if @active_ceilings == ceiling
      end

      return false
    end

    def activate_in_stasis_ceiling(line : LineDef)
      @active_ceilings.size.times do |i|
        if (@active_ceilings[i] != nil &&
           @active_ceilings[i].as(CeilingMove).tag == line.tag &&
           @active_ceilings[i].as(CeilingMove).direction == 0)
          @active_ceilings[i].as(CeilingMove).direction = @active_ceilings[i].as(CeilingMove).old_direction
          @active_ceilings[i].as(CeilingMove).thinker_state = ThinkerState::Active
        end
      end
    end

    def ceiling_crush_stop(line : LineDef) : Bool
      result = false

      @active_ceilings.size.times do |i|
        if (@active_ceilings[i] != nil &&
           @active_ceilings[i].as(CeilingMove).tag == line.tag &&
           @active_ceilings[i].as(CeilingMove).direction != 0)
          @active_ceilings[i].as(CeilingMove).old_direction = @active_ceilings[i].as(CeilingMove).direction
          @active_ceilings[i].as(CeilingMove).thinker_state = ThinkerState::InStasis
          @active_ceilings[i].as(CeilingMove).direction = 0
          result = true
        end
      end

      return result
    end

    #
    # Teleport
    #

    def teleport(line : LineDef, side : Int32, thing : Mobj) : Bool
      # Don't teleport missiles.
      return false if (thing.flags & MobjFlags::Missile) != 0

      # Don't teleport if hit back of line, so you can get out of teleporter.
      return false if side == 1

      sectors = @world.as(World).map.as(Map).sectors
      tag = line.tag

      sectors.size.times do |i|
        if sectors[i].tag == tag
          enumerator = @world.as(World).thinkers.as(Thinkers).get_enumerator
          while true
            thinker = enumerator.current
            dest = thinker.as?(Mobj)

            # Not a mobj
            if dest == nil
              enumerator.move_next
              next
            end

            dest = dest.as(Mobj)

            # Not a teleportman
            if dest.type != MobjType::Teleportman
              enumerator.move_next
              next
            end

            sector = dest.subsector.as(Subsector).sector

            # Wrong sector.
            if sector.number != i
              enumerator.move_next
              next
            end

            old_x = thing.x
            old_y = thing.y
            old_z = thing.z

            return false if !@world.as(World).thing_movement.as(ThingMovement).teleport_move(thing, dest.x, dest.y)

            # This compatibility fix is based on Chocolate Doom's implementation.
            thing.z = thing.floor_z if @world.as(World).options.game_version != GameVersion::Final

            thing.player.as(Player).view_z = thing.z + thing.player.as(Player).view_height if thing.player != nil

            ta = @world.as(World).thing_allocation.as(ThingAllocation)

            # Spawn teleport fog at source position.
            fog1 = ta.spawn_mobj(
              old_x,
              old_y,
              old_z,
              MobjType::Tfog
            )
            @world.as(World).start_sound(fog1, Sfx::TELEPT, SfxType::Misc)

            # Destination position.
            angle = dest.angle
            fog2 = ta.spawn_mobj(
              dest.x + Trig.cos(angle) * 20,
              dest.y + Trig.sin(angle) * 20,
              thing.z,
              MobjType::Tfog
            )
            @world.as(World).start_sound(fog2, Sfx::TELEPT, SfxType::Misc)

            # Don't move for a bit.
            thing.reaction_time = 18 if thing.player != nil

            thing.angle = dest.angle
            thing.mom_x = Fixed.zero
            thing.mom_y = Fixed.zero
            thing.mom_z = Fixed.zero

            thing.disable_frame_interpolation_for_one_frame
            thing.player.as(Player).disable_frame_interpolation_for_one_frame if thing.player != nil

            return true
          end
        end
      end

      return false
    end

    #
    # Lighting
    #

    def turn_tag_lights_off(line : LineDef)
      sectors = @world.as(World).map.as(Map).sectors

      sectors.size.times do |i|
        sector = sectors[i]

        if sector.tag == line.tag
          min = sector.light_level

          sector.lines.size.times do |j|
            target = get_next_sector(sector.lines[j], sector)
            next if target == nil
            target = target.as(Sector)

            min = target.light_level if target.light_level < min
          end

          sector.light_level = min
        end
      end
    end

    def light_turn_on(line : LineDef, bright : Int32)
      sectors = @world.as(World).map.as(Map).sectors

      sectors.size.times do |i|
        sector = sectors[i]

        if sector.tag == line.tag
          # bright = 0 means to search for highest light level surrounding sector.
          if bright == 0
            sector.lines.size.times do |j|
              target = get_next_sector(sector.lines[j], sector)
              next if target == nil
              target = target.as(Sector)

              bright = target.light_level if target.light_level > bright
            end
          end
        end

        sector.light_level = bright
      end
    end

    def start_light_strobing(line : LineDef)
      sectors = @world.as(World).map.as(Map).sectors
      sector_number = -1

      while (sector_number = find_sector_from_line_tag(line, sector_number))
        sector = sectors[sector_number]

        next if sector.special_data != nil

        @world.as(World).lighting_change.as(LightingChange).spawn_strobe_flash(sector, StrobeFlash.slow_dark, false)
      end
    end

    #
    # Miscellaneous
    #

    def do_donut(line : LineDef) : Bool
      sectors = @world.as(World).map.as(Map).sectors
      sector_number = -1
      result = false

      while (sector_number = find_sector_from_line_tag(line, sector_number)) >= 0
        s1 = sectors[sector_number]

        # Already moving? If so, keep going...
        next if s1.special_data != nil

        result = true

        s2 = get_next_sector(s1.lines[0], s1)

        #
        # The code below is based on Chocolate Doom's implementation.
        #

        break if s2 == nil
        s2 = s2.as(Sector)

        s2.lines.size.times do |i|
          s3 = s2.lines[i].back_sector

          next if s3 == s1

          # Undefined behavior in Vanilla Doom.
          return result if s3 == nil
          s3 = s3.as(Sector)

          thinkers = @world.as(World).thinkers.as(Thinkers)

          # Spawn rising slime.
          floor1 = FloorMove.new(@world.as(World))
          thinkers.add(floor1)
          s2.special_data = floor1
          floor1.type = FloorMoveType::DonutRaise
          floor1.crush = false
          floor1.direction = 1
          floor1.sector = s2
          floor1.speed = @@floor_speed / 2
          floor1.texture = s3.floor_flat
          floor1.new_special = SectorSpecial.new(0)
          floor1.floor_dest_height = s3.floor_height

          # Spawn lowering donut-hole
          floor2 = FloorMove.new(@world.as(World))
          thinkers.add(floor2)
          s1.special_data = floor2
          floor2.type = FloorMoveType::LowerFloor
          floor2.crush = false
          floor2.direction = -1
          floor2.sector = s1
          floor2.speed = @@floor_speed / 2
          floor2.floor_dest_height = s3.floor_height

          break
        end
      end

      return result
    end

    def spawn_door_close_in_30(sector : Sector)
      door = VerticalDoor.new(@world.as(World))

      @world.as(World).thinkers.add(door)

      sector.special_data = door
      sector.special = SectorSpecial.new(0)

      door.sector = sector
      door.direction = 0
      door.type = VerticalDoorType::Normal
      door.speed = @@door_speed
      door.top_count_down = 30 * 35
    end

    def spawn_door_raise_in_5_mins(sector : Sector)
      door = VerticalDoor.new(@world.as(World))

      @world.as(World).thinkers.add(door)

      sector.special_data = door
      sector.special = SectorSpecial.new(0)

      door.sector = sector
      door.direction = 2
      door.type = VerticalDoorType::RaiseIn5Mins
      door.speed = @@door_speed
      door.top_height = find_lowest_ceiling_surrounding(sector)
      door.top_height -= Fixed.from_i(4)
      door.top_wait = @@door_wait
      door.top_count_down = 5 * 60 * 35
    end
  end
end
