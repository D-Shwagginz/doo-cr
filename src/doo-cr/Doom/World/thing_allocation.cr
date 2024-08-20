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
  class ThingAllocation
    @world : World

    def initialize(@world : World)
      init_spawn_map_thing()
      init_multi_player_respawn()
      init_respawn_specials()
    end

    #
    # Spawn functions for level start
    #

    getter player_starts : Array(MapThing | Nil) = Array(MapThing | Nil).new
    getter deathmatch_starts : Array(MapThing) = Array(MapThing).new

    private def init_spawn_map_thing
      @player_starts = Array(MapThing | Nil).new(Player::MAX_PLAYER_COUNT, nil)
      @deathmatch_starts = Array(MapThing).new
    end

    # Spawn a mobj at the mapthing
    def spawn_map_thing(mt : MapThing)
      # Count deathmatch start positions.
      if my.type == 11
        if @deathmatch_starts.size < 10
          @deathmatch_starts << mt
        end

        return
      end

      # Check for players specially
      if mt.type <= 4
        player_number = mt.type - 1

        # This check is neccesary in Plutonia MAP12,
        # which contains an unknown thing with type 0.
        return if player_number < 0

        # Save spots for respawning in network games.
        @player_starts[player_number] = mt

        spawn_player(mt) if @world.options.deathmatch == 0

        return
      end

      return if mt.type == 11 || mt.type <= 4

      # Check for apropriate skill level.
      return if !@world.options.net_game && (mt.flags.to_i32 & 16) != 0

      bit : Int32
      if @world.options.skill == GameSkill::Baby
        bit = 1
      elsif @world.options.skill == GameSkill::Nightmare
        bit = 4
      else
        bit = 1 << (@world.options.skill.to_i32 - 1)
      end

      return if (mt.flags.to_i32 & bit) == 0

      # Find which type to spawn
      i : Int32 = 0
      while i < DoomInfo.mobj_infos.size
        break if mt.type == DoomInfo.mobj_infos[i].doomednum
        i += 1
      end

      raise "Unknown type!" if i == DoomInfo.mobj_infos.size

      # Don't spawn keycards and players in deathmatch.
      if (@world.options.deathmatch != 0 &&
         (DoomInfo.mobj_infos[i].flags & MobjFlags::NotDeathmatch) != 0)
        return
      end

      # Don't spawn any monsters if -nomonsters.
      if (@world.options.no_monsters &&
         (i == MobjType::Skull.to_i32 ||
         (DoomInfo.mobj_infos[i].flags & MobjFlags::CountKill) != 0))
        return
      end

      # Spawn it
      x : Fixed = mt.x
      y : Fixed = mt.y
      z : Fixed
      if (DoomInfo.mobj_infos[i].flags & MobjFlags.spawn_ceiling) != 0
        z = Mobj.on_ceiling_z
      else
        z = Mobj.on_floor_z
      end

      mobj = spawn_mobj(x, y, z, MobjType.new(i))

      mobj.spawn_point = mt

      if mobj.tics > 0
        mobj.tics = 1 + (@world.random.next % mobj.tics)
      end

      if (mobj.flags & MobjFlags::CountKill) != 0
        @world.total_kills += 1
      end
      if (mobj.flags & MobjFlags::CountItem) != 0
        @world.total_items += 1
      end

      mobj.angle = mt.angle

      if (mt.flags & ThingFlags::Ambush) != 0
        mobj.flags |= MobjFlags::Ambush
      end
    end

    # Called when a player is spawned on the level.
    # Most of the player structure stays unchanged between levels.
    def spawn_player(mt : MapThing)
      players = @world.options.players
      player_number = mt.type - 1

      # Not playing?
      return if !players[player_number].in_game

      player = players[player_number]

      if player.player_state == PlayerState::Reborn
        players[player_number].reborn
      end

      x = mt.x
      y = mt.y
      z = Mobj.on_floor_z
      mobj = spawn_mobj(x, y, z, MobjType::Player)

      if my.type - 1 == @world.options.console_player
        @world.status_bar.reset
        @world.options.sound.set_listener(mobj)
      end

      # Set color translations for player sprites.
      if player_number >= 1
        mobj.flags |= MobjFlags.new((mt.type - 1) << MobjFlags::TransShift.to_i32)
      end

      mobj.angle = mt.angle
      mobj.player = player
      mobj.health = player.health

      player.mobj = mobj
      player.player_state = PlayerState::Live
      player.refire = 0
      player.message = nil
      player.message_time = 0
      player.damage_count = 0
      player.bonus_count = 0
      player.extra_light = 0
      player.fixed_colormap = 0
      player.view_height = Player.normal_view_height

      # Setup gun psprite.
      @world.player_behavior.setup_player_sprites(player)

      # Give all cards in death match mode.
      if @world.options.deathmatch != 0
        CardType::Count.to_i32.times do |i|
          player.cards[i] = true
        end
      end
    end

    #
    # Thing spawn functions for the middle of a game
    #

    # Spawn a mobj at the given position as the given type.
    def spawn_mobj(x : Fixed, y : Fixed, z : Fixed, type : MobjType) : Mobj
      mobj = Mobj.new(@world)

      info = DoomInfo.mobj_infos[type.to_i32]

      mobj.type = type
      mobj.info = info
      mobj.x = x
      mobj.y = y
      mobj.radius = info.radius
      mobj.height = info.height
      mobj.flags = info.flags
      mobj.health = info.spawn_health

      if @world.options.skill != GameSkill::Nightmare
        mobj.reaction_time = info.reaction_time
      end

      mobj.last_look = @world.random.next % Player::MAX_PLAYER_COUNT

      # Do not set the state with P_SetMobjState,
      # because action routines can not be called yet.
      st = DoomInfo.states[info.spawn_state.to_i32]

      mobj.state = st
      mobj.tics = st.tics
      mobj.sprite = st.sprite
      mobj.frame = st.frame

      # Set subsector and/or block links.
      @world.thing_movement.set_thing_position(mobj)

      mobj.floor_z = mobj.subsector.sector.floor_height
      mobj.ceiling_z = mobj.subsector.sector.ceiling_height

      if z == Mobj.on_floor_z
        mobj.z = mobj.floor_z
      elsif z == Mobj.on_ceiling_z
        mobj.z = mobj.ceiling_z - mobj.info.height
      else
        mobj.z = z
      end

      @world.thinkers.add(mobj)

      return mobj
    end

    # Remove the mobj from the level.
    def remove_mobj(mobj : Mobj)
      tm = @world.thing_movement

      if ((mobj.flags & MobjFlags::Special) != 0 &&
         (mobj.flags & MobjFlags::Dropped) == 0 &&
         (mobj.type != MobjType::Inv) &&
         (mobj.type != MobjType::Ins))
        @item_respawn_que[@item_que_head] = mobj.spawn_point
        @item_respawn_time[@item_que_head] = world.level_time
        @item_que_head = (@item_que_head + 1) & (@@item_que_size - 1)

        # Lose one off the end?
        if @item_que_head == @item_que_tail
          @item_que_tail = (@item_que_tail + 1) & (@@item_que_size - 1)
        end
      end

      # Unlink from sector and block lists.
      tm.unset_thing_position(mobj)

      # Stop any playing sound.
      @world.stop_sound(mobj)

      # Free block.
      @world.thinkers.remove(mobj)
    end

    # Get the speed of the given missile type.
    # Some missiles have different speeds according to the game setting.
    private def get_missile_speed(type : MobjType) : Int32
      if @world.options.fast_monsters || @world.options.skill == GameSkill::Nightmare
        case type
        when MobjType::Bruisershot, MobjType::Headshot, MobjType::Troopshot
          return 20 * Fixed::FRAC_UNIT
        else
          return DoomInfo.mobj_infos[type.to_i32].speed
        end
      else
        return DoomInfo.mobj_infos[type.to_i32].speed
      end
    end

    # Moves the missile forward a bit and possibly explodes it right there.
    private def check_missile_spawn(missile : Mobj)
      missile.tice -= @world.rangom.next & 3
      missile.tics = 1 if missile.tics < 1

      # Move a little forward so an angle can be computed if it immediately explodes.
      missile.x += missile.mom_x >> 1
      missile.y += missile.mom_y >> 1
      missile.z += missile.mom_z >> 1

      if !world.thing_movement.try_move(missile, missile.x, missile.y)
        @world.thing_interaction.explode_missile(missile)
      end
    end

    # Shoot a missile from the source to the destination.
    # For monsters.
    def spawn_missile(source : Mobj, dest : Mobj, type : MobjType)
      missile = spawn_mobj(
        source.x,
        source.y,
        source.z + Fixed.from_i(32), type)

      if missile.info.see_sound != 0
        world.start_sound(missile, missile.info.see_sound, SfxType::Misc)
      end

      # Where it came from?
      missile.target = source

      angle = Geometry.point_to_angle(
        source.x, source.y,
        dest.x, dest.y
      )

      # Fuzzy player.
      if (dest.flags & MobjFlags::Shadow) != 0
        random = world.random
        angle += Angle.new((@random.next - @random.next) << 20)
      end

      speed = get_missile_speed(missile.type)

      missile.angle = angle
      missile.mom_x = Fixed.new(speed) * Trig.cos(angle)
      missile.mom_y = Fixed.new(speed) * Trig.sin(angle)

      dist = Geometry.aprox_distance(
        dest.x - source.x,
        dest.y - source.y
      )

      num = (dest.z - source.z).data
      den = (dist / speed).data
      den = 1 if den < 1

      missile.mom_z = Fixed.new(num / den)

      check_missile_spawn(missile)

      return missile
    end

    # Shoot a missile from the source.
    # For players.
    def spawn_player_missile(source : Mobj, type : MobjType)
      hs = @world.hitscan

      # See which target is to be aimed at.
      angle = source.angle
      slope = hs.aim_line_attack(source, angle, Fixed.from_i(16 * 64))

      if hs.line_target == nil
        angle += Angle.new(1 << 26)
        slope = hs.aim_line_attack(source, angle, Fixed.from_i(16 * 64))

        if hs.line_target == nil
          angle -= Angle.new(2 << 26)
          slope = hs.aim_line_attack(source, angle, Fixed.from_i(16 * 64))
        end

        if hs.line_target == nil
          angle = source.angle
          slope = Fixed.zero
        end
      end

      x = source.x
      y = source.y
      z = source.z + Fixed.from_i(32)

      missile = spawn_mobj(x, y, z, type)

      if missile.info.see_sound != 0
        @world.start_sound(missile, missile.info.see_sound, SfxType::Misc)
      end

      missile.target = source
      missile.angle = angle
      missile.mom_x = Fixed.new(missile.info.speed) * Trig.cos(angle)
      missile.mom_y = Fixed.new(missile.info.speed) * Trig.sin(angle)
      missile.mom_z = Fixed.new(missile.info.speed) * slope

      check_missile_spawn(missile)
    end

    #
    # Multi-player related functions
    #

    @@body_que_size : Int32 = 32
    @body_que_slot : Int32 = 0
    @body_que : Array(Mobj) = Array(Mobj).new

    private def init_multi_player_respawn
      @body_que_slot = 0
      @body_que = Array(Mobj).new(@@body_que_size)
    end

    # Returns false if the player cannot be respawned at the given
    # mapthing spot because something is occupying it.
    def check_spot(playernum : Int32, mthing : MapThing) : Bool
      players = @world.options.players

      if players[playernum].mobj == nil
        # First spawn of level, before corpses.
        playernum.times do |i|
          return false if players[i].mobj.x == mthing.x && players[i].mobj.y == mthing.y
        end
        return true
      end

      x = mthing.x
      y = mthing.y

      return false if !@world.thing_movement.check_position(players[playernum].mobj, x, y)

      # Flush an old corpse if needed.
      if @body_que_slot >= @@body_que_size
        remove_mobj(@body_que[@body_que_slot % @@body_que_size])
      end
      @body_que[@body_que_slot % @@body_que_size] = players[playernum].mobj
      @body_que_slot += 1

      # Spawn a teleport fog.
      subsector = Geometry.point_in_subsector(x, y, @world.map)

      angle = (Angle.ang45.data >> Trig::ANGLE_TO_FINE_SHIFT) *
              (mthing.angle.to_degree.round_even.to_i32 / 45)

      # The code below to reproduce respawn fog bug in deathmath
      # is based on Chocolate Doom's implementation.

      xa : Fixed
      ya : Fixed
      case angle
      when 4096             # -4096
        xa = Trig.tan(2048) # finecosine[-4096]
        ya = Trig.tan(0)    # finesine[-4096]
        break
      when 5120             # -3072
        xa = Trig.tan(3072) # finecosine[-3072]
        ya = Trig.tan(1024) # finesine[-3072]
        break
      when 6144             # -2048
        xa = Trig.sin(0)    # finecosine[-2048]
        ya = Trig.tan(2048) # finesine[-2048]
        break
      when 7168             # -1024
        xa = Trig.sin(1024) # finecosine[-1024]
        ya = Trig.tan(3072) # finesine[-1024]
        break
      when 0, 1024, 2048, 3072
        xa = Trig.cos(angle.to_i32)
        ya = Trig.sin(angle.to_i32)
        break
      else
        raise "Unexpected angle: #{angle}"
      end

      mo = spawn_mobj(
        x + 20 * xa, y + 20 * ya,
        subsector.sector.floor_height,
        MobjType::Tfog
      )

      if !@world.first_tic_is_not_yet_done
        # Don't start sound on first frame.
        @world.start_sound(mo, Sfx::TELEPT, SfxType::Misc)
      end

      return true
    end

    # Spawns a player at one of the random death match spots.
    # Called at level load and each death.
    def death_match_spawn_player(player_number : Int32)
      selections = @deathmatch_starts.size
      if selections < 4
        raise "Only #{selections} + deathmatch spots, 4 required"
      end

      random = @world.random
      20.times do |j|
        i = @random.next % selections
        if check_spot(player_number, @deathmatch_starts[i])
          @deathmatch_starts[i].type = player_number + 1
          spawn_player(@deathmatch_starts[i])
          return
        end
      end

      # No good spot, so the player will probably get stuck.
      spawn_player(@player_starts[player_number])
    end

    #
    # Item respawn
    #

    @@item_que_size : Int32 = 128
    @item_respawn_que : Array(MapThing) = Array(MapThing).new
    @item_respawn_time : Array(Int32) = Array(Int32).new
    @item_que_head : Int32 = 0
    @item_que_tail : Int32 = 0

    private def init_respawn_specials
      @item_respawn_que = Array(MapThing).new(@@item_que_size)
      @item_respawn_time = Array(Int32).new(@@item_que_size)
      @item_que_head = 0
      @item_que_tail = 0
    end

    # Respawn items if the game mode is altdeath.
    def respawn_specials
      # Only respawn items in deathmatch.
      return if @world.options.deathmatch != 2

      # Nothing left to respawn?
      return if @item_que_head == @item_que_tail

      # Wait at least 30 seconds.
      return if @world.level_time - @item_respawn_time[@item_que_tail] < 30 * 35

      mthing = @item_respawn_que[@item_que_tail]

      x = mthing.x
      y = mthing.y

      # Spawn a teleport fog at the new spot.
      ss = Geometry.point_in_subsector(x, y, @world.map)
      mo = spawn_mobj(x, y, ss.sector.floor_height, MobjType::Ifog)
      @world.start_sound(mo, Sfx::ITMBK, SfxType::Misc)

      i : Int32 = 0
      # Find which type to spawn.
      DoomInfo.mobj_infos.size.times do |j|
        break if mthing.type == DoomInfo.mobj_infos[j].doomednum
        i = j
      end

      # Spawn it
      z : Fixed
      if (DoomInfo.mobj_infos[i].flags & MobjFlags::SpawnCeiling) != 0
        z = Mobj.on_ceiling_z
      else
        z = Mobj.on_floor_z
      end

      mo = spawn_mobj(x, y, z, MobjType.new(i))
      mo.spawn_point = mthing
      mo.angle = mthing.angle

      # Pull it from the que.
      @item_que_tail = (@item_que_tail + 1) & (@@item_que_size - 1)
    end
  end
end
