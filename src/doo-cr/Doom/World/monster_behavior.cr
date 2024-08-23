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
  class MonsterBehavior
    @world : World

    def initialize(@world)
      init_vile()
      init_boss_death()
      init_brain()
    end

    #
    # Sleeping monster
    #

    private def look_for_players(actor : Mobj, all_around : Bool) : Bool
      players = @world.as(World).options.players

      count = 0
      stop = (actor.last_look - 1) & 3

      while true
        if !players[actor.last_look].in_game
          actor.last_look = (actor.last_look + 1) & 3
          next
        end

        # Done looking.
        return false if count == 2 || actor.last_look == stop

        player = players[actor.last_look]

        # Player is dead.
        if player.health <= 0
          actor.last_look = (actor.last_look + 1) & 3
          next
        end

        # Out of sight.
        if !@world.as(World).visibility_check.as(VisibilityCheck).check_sight(actor, player.mobj.as(Mobj))
          actor.last_look = (actor.last_look + 1) & 3
          next
        end

        if !all_around
          angle = Geometry.point_to_angle(
            actor.x, actor.y,
            player.mobj.as(Mobj).x, player.mobj.as(Mobj).y
          ) - actor.angle

          if angle > Angle.ang90 && angle < Angle.ang270
            dist = Geometry.aprox_distance(
              player.mobj.as(Mobj).x - actor.x,
              player.mobj.as(Mobj).y - actor.y
            )

            # If real close, react anyway.
            if dist > WeaponBehavior.melee_range
              # Behind back.
              actor.last_look = (actor.last_look + 1) & 3
              next
            end
          end
        end

        actor.target = player.mobj

        return true
      end
    end

    def look(actor : Mobj)
      # Any shot will wake up.
      actor.threshold = 0

      target = actor.subsector.as(Subsector).sector.sound_target

      x = false

      if target != nil && (target.as(Mobj).flags & MobjFlags::Shootable) != 0
        actor.target = target

        if (actor.flags & MobjFlags::Ambush) != 0
          x = true if @world.as(World).visibility_check.as(VisibilityCheck).check_sight(actor, actor.target.as(Mobj))
        else
          x = true
        end
      end

      if !x
        return if !look_for_players(actor, false)
      end

      # Go into chase state:
      if actor.info.as(MobjInfo).see_sound != 0
        sound : Int32 = 0

        case actor.info.as(MobjInfo).see_sound
        when Sfx::POSIT1, Sfx::POSIT2, Sfx::POSIT3
          sound = Sfx::POSIT1.to_i32 + @world.as(World).random.next % 3
        when Sfx::BGSIT1, Sfx::BGSIT2
          sound = Sfx::BGSIT1.to_i32 + @world.as(World).random.next % 2
        else
          sound = actor.info.as(MobjInfo).see_sound.to_i32
        end

        if actor.type == MobjType::Spider || actor.type == MobjType::Cyborg
          # Full volume for boss monsters.
          @world.as(World).start_sound(actor, Sfx.new(sound), SfxType::Diffuse)
        else
          @world.as(World).start_sound(actor, Sfx.new(sound), SfxType::Voice)
        end
      end

      actor.set_state(actor.info.as(MobjInfo).see_state)
    end

    #
    # Monster AI
    #

    @@x_speed : Array(Fixed) = [
      Fixed.new(Fixed::FRAC_UNIT),
      Fixed.new(47000),
      Fixed.new(0),
      Fixed.new(-47000),
      Fixed.new(-Fixed::FRAC_UNIT),
      Fixed.new(-47000),
      Fixed.new(0),
      Fixed.new(47000),
    ]

    @@y_speed : Array(Fixed) = [
      Fixed.new(0),
      Fixed.new(47000),
      Fixed.new(Fixed::FRAC_UNIT),
      Fixed.new(47000),
      Fixed.new(0),
      Fixed.new(-47000),
      Fixed.new(-Fixed::FRAC_UNIT),
      Fixed.new(-47000),
    ]

    private def move(actor : Mobj) : Bool
      return false if actor.move_dir == Direction::None

      if actor.move_dir.to_i32 >= 8
        raise "Weird actor.move_dir!"
      end

      try_x = actor.x + @@x_speed[actor.move_dir.to_i32] * actor.info.as(MobjInfo).speed
      try_y = actor.y + @@y_speed[actor.move_dir.to_i32] * actor.info.as(MobjInfo).speed

      tm = @world.as(World).thing_movement.as(ThingMovement)

      try_ok = tm.try_move(actor, try_x, try_y)

      if !try_ok
        # Open any specials.
        if (actor.flags & MobjFlags::Float) != 0 && tm.float_ok
          # Must adjust height.
          if actor.z < tm.current_floor_z
            actor.z += ThingMovement.float_speed
          else
            actor.z -= ThingMovement.float_speed
          end

          actor.flags |= MobjFlags::InFloat

          return true
        end

        return false if tm.crossed_special_count == 0

        actor.move_dir = Direction::None
        good = false
        while tm.crossed_special_count > 0
          tm.crossed_special_count -= 1

          line = tm.crossed_specials[tm.crossed_special_count]
          # If the special is not a door that can be opened,
          # return false.
          good = true if @world.as(World).map_interaction.as(MapInteraction).use_special_line(actor, line, 0)
        end
        return good
      else
        actor.flags &= ~MobjFlags::InFloat
      end

      if (actor.flags & MobjFlags::Float) == 0
        actor.z = actor.floor_z
      end

      return true
    end

    private def try_walk(actor : Mobj) : Bool
      return false if !move(actor)

      actor.move_count = @world.as(World).random.next & 15

      return true
    end

    @@opposite : Array(Direction) = [
      Direction::West,
      Direction::Southwest,
      Direction::South,
      Direction::Southeast,
      Direction::East,
      Direction::Northeast,
      Direction::North,
      Direction::Northwest,
      Direction::None,
    ]

    @@diags : Array(Direction) = [
      Direction::Northwest,
      Direction::Northeast,
      Direction::Southwest,
      Direction::Southeast,
    ]

    @choices : Array(Direction) = Array.new(3, Direction.new(0))

    private def new_chase_dir(actor : Mobj | Nil)
      if actor.target == nil
        "Called with no target."
      end

      old_dir = actor.move_dir
      turn_around = @@opposite[old_dir.to_i32]

      delta_x = actor.target.as(Mobj).x - actor.x
      delta_y = actor.target.as(Mobj).y - actor.y

      if delta_x > Fixed.from_i(10)
        @choices[1] = Direction::East
      elsif delta_x < Fixed.from_i(-10)
        @choices[1] = Direction::West
      else
        @choices[1] = Direction::None
      end

      if delta_y < Fixed.from_i(-10)
        @choices[2] = Direction::South
      elsif delta_y > Fixed.from_i(10)
        @choices[2] = Direction::North
      else
        @choices[2] = Direction::None
      end

      # Try direct route.
      if @choices[1] != Direction::None && @choices[2] != Direction::None
        a = (delta_y < Fixed.zero) ? 1 : 0
        b = (delta_x > Fixed.zero) ? 1 : 0
        actor.move_dir = @@diags[(a << 1) + b]

        return if actor.move_dir != turn_around && try_walk(actor)
      end

      # Try other directions.
      if @world.as(World).random.next > 200 || delta_y.abs > delta_x.abs
        temp = @choices[1]
        @choices[1] = @choices[2]
        @choices[2] = temp
      end

      @choices[1] = Direction::None if @choices[1] == turn_around

      @choices[2] = Direction::None if @choices[2] == turn_around

      if @choices[1] != Direction::None
        actor.move_dir = @choices[1]

        # Either moved forward or attacked.
        return if try_walk(actor)
      end

      if @choices[2] != Direction::None
        actor.move_dir = @choices[2]

        return if try_walk(actor)
      end

      # There is no direct path to the player, so pick another direction.
      if old_dir != Direction::None
        actor.move_dir = old_dir

        return if try_walk(actor)
      end

      # Randomly determine direction of search.
      if (@world.as(World).random.next & 1) != 0
        dir = Direction::East.to_i32
        while dir <= Direction::Southeast.to_i32
          if Direction.new(dir) != turn_around
            actor.move_dir = Direction.new(dir)

            return if try_walk(actor)
          end
          dir += 1
        end
      else
        dir = Direction::Southeast.to_i32
        while dir != (Direction::East.to_i32 - 1)
          actor.move_dir = Direction.new(dir)

          return if try_walk(actor)

          dir -= 1
        end
      end

      if turn_around != Direction::None
        actor.move_dir = turn_around

        return if try_walk(actor)
      end

      # Can not move.
      actor.move_dir = Direction::None
    end

    private def check_melee_range(actor : Mobj)
      return false if actor.target == nil

      target = actor.target.as(Mobj)

      dist = Geometry.aprox_distance(target.x - actor.x, target.y - actor.y)

      return false if dist >= WeaponBehavior.melee_range - Fixed.from_i(20) + target.info.as(MobjInfo).radius

      return false if !@world.as(World).visibility_check.as(VisibilityCheck).check_sight(actor, actor.target.as(Mobj))

      return true
    end

    private def check_missile_range(actor : Mobj)
      return false if !@world.as(World).visibility_check.as(VisibilityCheck).check_sight(actor, actor.target.as(Mobj))

      if (actor.flags & MobjFlags::JustHit) != 0
        # The target just hit the enemy, so fight back!
        actor.flags &= ~MobjFlags::JustHit

        return true
      end

      # Do not attack yet.
      return false if actor.reaction_time > 0

      # OPTIMIZE: Get this from a global checksight.
      dist = Geometry.aprox_distance(
        actor.x - actor.target.as(Mobj).x,
        actor.y - actor.target.as(Mobj).y
      ) - Fixed.from_i(64)

      # No melee attack, so fire more.
      dist -= Fixed.from_i(128) if actor.info.as(MobjInfo).melee_state == 0

      attack_dist = dist.data >> 16

      # Too far away.
      return false if actor.type == MobjType::Vile && attack_dist > 14 * 64

      if actor.type == MobjType::Undead
        # Close for fist attack.
        return false if attack_dist < 196
        attack_dist >>= 1
      end

      if (actor.type == MobjType::Cyborg ||
         actor.type == MobjType::Spider ||
         actor.type == MobjType::Skull)
        attack_dist >>= 1
      end

      attack_dist = 200 if attack_dist > 200

      attack_dist = 160 if actor.type == MobjType::Cyborg && attack_dist > 160

      return false if @world.as(World).random.next < attack_dist

      return true
    end

    def chase(actor : Mobj)
      actor.reaction_time -= 1 if actor.reaction_time > 0

      # Modify target threshold.
      if actor.threshold > 0
        if actor.target == nil || actor.target.as(Mobj).health <= 0
          actor.threshold = 0
        else
          actor.threshold -= 1
        end
      end

      # Turn towards movement direction if not there yet.
      if actor.move_dir.to_i32 < 8
        actor.angle = Angle.new(actor.angle.data.to_i32 & (7 << 29))

        delta = (actor.angle - Angle.new(actor.move_dir.to_i32 << 29)).data.to_i32

        if delta > 0
          actor.angle -= Angle.new((Angle.ang90.data / 2).to_i32)
        elsif delta < 0
          actor.angle += Angle.new((Angle.ang90.data / 2).to_i32)
        end
      end

      if actor.target == nil || (actor.target.as(Mobj).flags & MobjFlags::Shootable) == 0
        # Look for a new target.
        if look_for_players(actor, true)
          # Got a new target.
          return
        end

        actor.set_state(actor.info.as(MobjInfo).spawn_state)

        return
      end

      # Do not attack twice in a row.
      if (actor.flags & MobjFlags::JustAttacked) != 0
        actor.flags &= ~MobjFlags::JustAttacked

        if (@world.as(World).options.skill != GameSkill::Nightmare &&
           !@world.as(World).options.fast_monsters)
          new_chase_dir(actor)
        end

        return
      end

      # Check for melee attack.
      if actor.info.as(MobjInfo).melee_state != 0 && check_melee_range(actor)
        if actor.info.as(MobjInfo).attack_sound != 0
          @world.as(World).start_sound(actor, actor.info.as(MobjInfo).attack_sound, SfxType::Weapon)
        end

        actor.set_state(actor.info.as(MobjInfo).melee_state)

        return
      end

      # Check for missile attack.
      begin
        if actor.info.as(MobjInfo).missile_state != 0
          if (@world.as(World).options.skill.as(GameSkill) < GameSkill::Nightmare &&
             !@world.as(World).options.fast_monsters &&
             actor.move_count != 0)
            raise ""
          end

          raise "" if !check_missile_range(actor)

          actor.set_state(actor.info.as(MobjInfo).missile_state)
          actor.flags |= MobjFlags::JustAttacked

          return
        end
      end

      # Possibly choose another target.
      if (@world.as(World).options.net_game &&
         actor.threshold == 0 &&
         !@world.as(World).visibility_check.as(VisibilityCheck).check_sight(actor, actor.target.as(Mobj)))
        if look_for_players(actor, true)
          # Got a new target.
          return
        end
      end

      # Chase towards player.
      actor.move_count -= 1
      if actor.move_count < 0 || !move(actor)
        new_chase_dir(actor)
      end

      # Make active sound.
      if actor.info.as(MobjInfo).active_sound != 0 && @world.as(World).random.next < 3
        @world.as(World).start_sound(actor, actor.info.as(MobjInfo).active_sound, SfxType::Voice)
      end
    end

    #
    # Monster death
    #

    def pain(actor : Mobj)
      if actor.info.as(MobjInfo).pain_sound != 0
        @world.as(World).start_sound(actor, actor.info.as(MobjInfo).pain_sound, SfxType::Voice)
      end
    end

    def scream(actor : Mobj)
      sound : Int32 = 0

      case actor.info.as(MobjInfo).death_sound
      when 0
        return
      when Sfx::PODTH1, Sfx::PODTH2, Sfx::PODTH3
        sound = Sfx::PODTH1.to_i32 + @world.as(World).random.next % 3
      when Sfx::BGDTH1, Sfx::BGDTH2
        sound = Sfx::BGDTH1.to_i32 + @world.as(World).random.next % 2
      else
        sound = actor.info.as(MobjInfo).death_sound.to_i32
      end

      # Check for bosses.
      if actor.type == MobjType::Spider || actor.type == MobjType::Cyborg
        # Full volume.
        @world.as(World).start_sound(actor, Sfx.new(sound), SfxType::Diffuse)
      else
        @world.as(World).start_sound(actor, Sfx.new(sound), SfxType::Voice)
      end
    end

    def xscream(actor : Mobj)
      @world.as(World).start_sound(actor, Sfx::SLOP, SfxType::Voice)
    end

    def fall(actor : Mobj)
      # Actor is on ground, it can be walked over.
      actor.flags &= ~MobjFlags::Solid
    end

    #
    # Monster attack
    #

    def face_target(actor : Mobj)
      return if actor.target == nil

      actor.flags &= ~MobjFlags::Ambush

      actor.angle = Geometry.point_to_angle(
        actor.x, actor.y,
        actor.target.as(Mobj).x, actor.target.as(Mobj).y
      )

      random = @world.as(World).random

      if (actor.target.as(Mobj).flags & MobjFlags::Shadow) != 0
        actor.angle += Angle.new((random.next - random.next) << 21)
      end
    end

    def pos_attack(actor : Mobj)
      return actor.target == nil

      face_target(actor)

      angle = actor.angle
      slope = @world.as(World).hitscan.aim_line_attack(actor, angle, WeaponBehavior.missile_range)

      @world.as(World).start_sound(actor, Sfx::PISTOL, SfxType::Weapon)

      random = @world.as(World).random
      angle += Angle.new((random.next - random.next) << 20)
      damage = ((random.next % 5) + 1) * 3

      @world.as(World).hitscan.line_attack(actor, angle, WeaponBehavior.missile_range, slope, damage)
    end

    def spos_attack(actor : Mobj)
      return if actor.target == nil

      @world.as(World).start_sound(actor, Sfx::SHOTGN, SfxType::Weapon)

      face_target(actor)

      center = actor.angle
      slope = @world.as(World).hitscan.as(Hitscan).aim_line_attack(actor, center, WeaponBehavior.missile_range)

      random = @world.as(World).random

      3.times do |i|
        angle = center + Angle.new((random.next - random.next) << 20)
        damage = ((random.next % 5) + 1) * 3

        @world.as(World).hitscan.as(Hitscan).line_attack(actor, angle, WeaponBehavior.missile_range, slope, damage)
      end
    end

    def cpos_attack(actor : Mobj)
      return if actor.target == nil

      @world.as(World).start_sound(actor, Sfx::SHOTGN, SfxType::Weapon)

      face_target(actor)

      center = actor.angle
      slope = @world.as(World).hitscan.as(Hitscan).aim_line_attack(actor, center, WeaponBehavior.missile_range)

      random = @world.as(World).random
      angle = center + Angle.new((random.next - random.next) << 20)
      damage = ((random.next % 5) + 1) * 3

      @world.as(World).hitscan.as(Hitscan).line_attack(actor, angle, WeaponBehavior.missile_range, slope, damage)
    end

    def cpos_refire(actor : Mobj)
      # Keep firing unless target got out of sight.
      face_target(actor)

      return if @world.as(World).random.next < 40

      if (actor.target == nil ||
         actor.target.as(Mobj).health <= 0 ||
         !@world.as(World).visibility_check.as(VisibilityCheck).check_sight(actor, actor.target.as(Mobj)))
        actor.set_state(actor.info.as(MobjInfo).see_state)
      end
    end

    def troop_attack(actor : Mobj)
      return if actor.target == nil

      face_target(actor)

      if check_melee_range(actor)
        @world.as(World).start_sound(actor, Sfx::CLAW, SfxType::Weapon)

        damage = (@world.as(World).random.next % 8 + 1) * 3
        @world.as(World).thing_interaction.as(ThingInteraction).damage_mobj(actor.target.as(Mobj), actor, actor, damage)

        return
      end

      # Launch a missile.
      @world.as(World).thing_allocation.as(ThingAllocation).spawn_missile(actor, actor.target.as(Mobj), MobjType::Troopshot)
    end

    def sarg_attack(actor : Mobj)
      return if actor.target == nil

      face_target(actor)

      if check_melee_range(actor)
        damage = ((@world.as(World).random.next % 10) + 1) * 4
        @world.as(World).thing_interaction.as(ThingInteraction).damage_mobj(actor.target.as(Mobj), actor, actor, damage)
      end
    end

    def head_attack(actor : Mobj)
      return if actor.target == nil

      face_target(actor)

      if check_melee_range(actor)
        damage = (@world.as(World).random.next % 6 + 1) * 10
        @world.as(World).thing_interaction.as(ThingInteraction).damage_mobj(actor.target.as(Mobj), actor, actor, damage)

        return
      end

      # Launch a missile.
      @world.as(World).thing_allocation.as(ThingAllocation).spawn_missile(actor, actor.target.as(Mobj), MobjType::Headshot)
    end

    def bruis_attack(actor : Mobj)
      return if actor.target == nil

      if check_melee_range(actor)
        @world.as(World).start_sound(actor, Sfx::CLAW, SfxType::Weapon)

        damage = (@world.as(World).random.next % 8 + 1) * 10
        @world.as(World).thing_interaction.as(ThingInteraction).damage_mobj(actor.target.as(Mobj), actor, actor, damage)

        return
      end

      # Launch a missile.
      @world.as(World).thing_allocation.as(ThingAllocation).spawn_missile(actor, actor.target.as(Mobj), MobjType::Bruisershot)
    end

    @@skull_speed : Fixed = Fixed.from_i(20)

    def skull_attack(actor : Mobj)
      return if actor.target == nil

      dest = actor.target.as(Mobj)

      actor.flags |= MobjFlags::SkullFly

      @world.as(World).start_sound(actor, actor.info.as(MobjInfo).attack_sound, SfxType::Voice)

      face_target(actor)

      angle = actor.angle
      actor.mom_x = @@skull_speed * Trig.cos(angle)
      actor.mom_y = @@skull_speed * Trig.sin(angle)

      dist = Geometry.aprox_distance(dest.x - actor.x, dest.y - actor.y)

      num = (dest.z + (dest.height >> 1) - actor.z).data
      den = dist.data / @@skull_speed.data
      den = 1 if den < 1

      actor.mom_z = Fixed.new((num / den).to_i32)
    end

    def fat_raise(actor : Mobj)
      face_target(actor)

      @world.as(World).start_sound(actor, Sfx::MANATK, SfxType::Voice)
    end

    @@fat_spread : Angle = Angle.ang90 / 8

    def fat_attack1(actor : Mobj)
      face_target(actor)

      ta = @world.as(World).thing_allocation.as(ThingAllocation)

      # Change direction to...
      actor.angle += @@fat_spread
      target = @world.as(World).subst_nil_mobj(actor.target)
      ta.spawn_missile(actor, target, MobjType::Fatshot)

      missile = ta.spawn_missile(actor, target, MobjType::Fatshot)
      missile.angle += @@fat_spread
      angle = missile.angle
      missile.mom_x = Fixed.new(missile.info.as(MobjInfo).speed) * Trig.cos(angle)
      missile.mom_y = Fixed.new(missile.info.as(MobjInfo).speed) * Trig.sin(angle)
    end

    def fat_attack2(actor : Mobj)
      face_target(actor)

      ta = @world.as(World).thing_allocation.as(ThingAllocation)

      # Now here choose opposite deviation.
      actor.angle -= @@fat_spread
      target = @world.as(World).subst_nil_mobj(actor.target)
      ta.spawn_missile(actor, target, MobjType::Fatshot)

      missile = ta.spawn_missile(actor, target, MobjType::Fatshot)
      missile.angle -= @@fat_spread * 2
      angle = missile.angle
      missile.mom_x = Fixed.new(missile.info.as(MobjInfo).speed) * Trig.cos(angle)
      missile.mom_y = Fixed.new(missile.info.as(MobjInfo).speed) * Trig.sin(angle)
    end

    def fat_attack3(actor : Mobj)
      face_target(actor)

      ta = @world.as(World).thing_allocation.as(ThingAllocation)

      target = @world.as(World).subst_nil_mobj(actor.target)

      missile1 = ta.spawn_missile(actor, target, MobjType::Fatshot)
      missile1.angle -= @@fat_spread / 2
      angle1 = missile1.angle
      missile1.mom_x = Fixed.new(missile1.info.as(MobjInfo).speed) * Trig.cos(angle1)
      missile1.mom_y = Fixed.new(missile1.info.as(MobjInfo).speed) * Trig.sin(angle1)

      missile2 = ta.spawn_missile(actor, target, MobjType::Fatshot)
      missile2.angle += @@fat_spread / 2
      angle2 = missile2.angle
      missile2.mom_x = Fixed.new(missile2.info.as(MobjInfo).speed) * Trig.cos(angle1)
      missile2.mom_y = Fixed.new(missile2.info.as(MobjInfo).speed) * Trig.sin(angle1)
    end

    def bspi_attack(actor : Mobj)
      return if actor.target == nil

      face_target(actor)

      # Launch a missile.
      @world.as(World).thing_allocation.as(ThingAllocation).spawn_missile(actor, actor.target.as(Mobj), MobjType::Arachplaz)
    end

    def spid_refire(actor : Mobj)
      # Keep firing unless target got out of sight.
      face_target(actor)

      return if @world.as(World).random.next < 10

      if (actor.target == nil ||
         actor.target.as(Mobj).health <= 0 ||
         !@world.as(World).visibility_check.as(VisibilityCheck).check_sight(actor, actor.target.as(Mobj)))
        actor.set_state(actor.info.as(MobjInfo).see_state)
      end
    end

    def cyber_attack(actor : Mobj)
      return if actor.target == nil

      face_target(actor)

      @world.as(World).thing_allocation.as(ThingAllocation).spawn_missile(actor, actor.target.as(Mobj), MobjType::Rocket)
    end

    #
    # Miscellaneous
    #

    def explode(actor : Mobj)
      @world.as(World).thing_interaction.as(ThingInteraction).radius_attack(actor, actor.target.as(Mobj), 128)
    end

    def metal(actor : Mobj)
      @world.as(World).start_sound(actor, Sfx::METAL, SfxType::Footstep)

      chase(actor)
    end

    def baby_metal(actor : Mobj)
      @world.as(World).start_sound(actor, Sfx::BSPWLK, SfxType::Footstep)

      chase(actor)
    end

    def hoof(actor : Mobj)
      @world.as(World).start_sound(actor, Sfx::HOOF, SfxType::Footstep)

      chase(actor)
    end

    #
    # Arch vile
    #

    @vile_check_func : Proc(Mobj, Bool) | Nil = nil
    @vile_target_corpse : Mobj | Nil = nil
    @vile_try_x : Fixed = Fixed.zero
    @vile_try_y : Fixed = Fixed.zero

    private def init_vile
      @vile_check_func = ->vile_check(Mobj)
    end

    private def vile_check(thing : Mobj)
      # Not a monster.
      return true if (thing.flags & MobjFlags::Corpse) == 0

      # Not lying still yet.
      return true if thing.tics != -1

      # Monster doesn't have a raise state.
      return true if thing.info.raise_state == MobjState::Nil

      max_dist = thing.info.radius + DoomInfo.mobj_infos[MobjType::Vile.to_i32].radius

      if ((thing.x - @vile_try_x).abs > max_dist ||
         (thing.y - @vile_try_y).abs > max_dist)
        # Not actually touching.
        return true
      end

      @vile_target_corpse = thing
      @vile_target_corpse.mom_x = Fixed.zero
      @vile_target_corpse.mom_y = Fixed.zero
      @vile_target_corpse.height <<= 2

      check = @world.as(World).thing_movement.check_position(
        @vile_target_corpse,
        @vile_target_corpse.x,
        @vile_target_corpse.y
      )

      @vile_target_corpse.height >>= 2

      # Doesn't fir here.
      return true if !check

      # Got one, so stop checking
      return false
    end

    def vile_chase(actor : Mobj)
      if actor.move_dir != Direction::None
        # Check for corpses to raise.
        @vile_try_x = actor.x + @@x_speed[actor.move_dir.to_i32] * actor.info.as(MobjInfo).speed
        @vile_try_y = actor.y + @@y_speed[actor.move_dir.to_i32] * actor.info.as(MobjInfo).speed

        bm = @world.as(World).map.as(Map).blockmap

        max_radius = GameConst.max_thing_radius * 2
        block_x1 = bm.get_block_x(@vile_try_x - max_radius)
        block_x2 = bm.get_block_x(@vile_try_x + max_radius)
        block_y1 = bm.get_block_x(@vile_try_y - max_radius)
        block_y2 = bm.get_block_x(@vile_try_y + max_radius)

        bx = block_x1
        while bx <= block_x2
          by = block_y1
          while by <= block_y2
            # Call vile_check to check whether object is a corpse that can be raised.
            if !bm.iterate_things(bx, by, @vile_check_func.as(Proc(Mobj, Bool)))
              # Got one!
              temp = actor.target
              actor.target = @vile_target_corpse
              face_target(actor)
              actor.target = temp
              actor.set_state(MobjState::VileHeal1)

              @world.as(World).start_sound(@vile_target_corpse.as(Mobj), Sfx::SLOP, SfxType::Misc)

              info = @vile_target_corpse.as(Mobj).info.as(MobjInfo)
              @vile_target_corpse.as(Mobj).set_state(info.raise_state)
              @vile_target_corpse.as(Mobj).height <<= 2
              @vile_target_corpse.as(Mobj).flags = info.flags
              @vile_target_corpse.as(Mobj).health = info.spawn_health
              @vile_target_corpse.as(Mobj).target = nil

              return
            end
            by += 1
          end
          bx += 1
        end
      end

      # Return to normal attack.
      chase(actor)
    end

    def vile_start(actor : Mobj)
      @world.as(World).start_sound(actor, Sfx::VILATK, SfxType::Weapon)
    end

    def start_fire(actor : Mobj)
      @world.as(World).start_sound(actor, Sfx::FLAMST, SfxType::Weapon)

      fire(actor)
    end

    def fire_crackle(actor : Mobj)
      @world.as(World).start_sound(actor, Sfx::FLAME, SfxType::Weapon)

      fire(actor)
    end

    def fire(actor : Mobj)
      dest = actor.tracer

      return if dest == nil
      dest = dest.as(Mobj)

      target = @world.as(World).subst_nil_mobj(actor.target)

      # Don't move it if the vile lost sight.
      return !@world.as(World).visibility_check.as(VisibilityCheck).check_sight(target, dest)

      @world.as(World).thing_movement.unset_thing_position(actor)

      angle = dest.angle
      actor.x = dest.x + Fixed.from_i(24) * Trig.cos(angle)
      actor.y = dest.y + Fixed.from_i(24) * Trig.sin(angle)
      actor.z = dest.z

      @world.as(World).thing_movement.set_thing_position(actor)
    end

    def vile_target(actor : Mobj)
      return actor.target == nil

      face_target(actor)

      fog = @world.as(World).thing_allocation.as(ThingAllocation).spawn_mobj(
        actor.target.x,
        actor.target.x,
        actor.target.z,
        MobjType::Fire
      )

      actor.tracer = fog
      fog.target = actor
      fog.tracer = actor.target
      fire(fog)
    end

    def vile_attack(actor : Mobj)
      return actor.target == nil

      face_target(actor)

      return if !@world.as(World).visibility_check.check_sight(actor, actor.target)

      @world.as(World).start_sound(actor, Sfx::BAREXP, SfxType::Weapon)
      @world.as(World).thing_interaction.damage_mobj(actor.target, actor, actor, 20)
      actor.target.mom_z = Fixed.from_i(1000) / actor.target.info.mass

      fire = actor.tracer
      return if fire == nil

      angle = actor.angle

      # Move the fire between the vile and the player.
      fire.x = actor.target.x - Fixed.from_i(24) * Trig.cos(angle)
      fire.y = actor.target.y - Fixed.from_i(24) * Trig.sin(angle)
      @world.as(World).thing_interaction.as(ThingInteraction).radius_attack(fire, actor, 70)
    end

    #
    # Revenant
    #

    def skel_missile(actor : Mobj)
      return if actor.target == nil
      target = actor.target.as(Mobj)

      face_target(actor)

      # Missile spawns higher.
      actor.z += Fixed.from_i(16)

      missile = @world.as(World).thing_allocation.as(ThingAllocation).spawn_missile(actor, target, MobjType::Tracer)

      # Back to normal.
      actor.z -= Fixed.from_i(16)

      missile.x += missile.mom_x
      missile.y += missile.mom_y
      missile.tracer = actor.target
    end

    @@trace_angle : Angle = Angle.new(0xc000000)

    def tracer(actor : Mobj)
      return if (@world.as(World).game_tic & 3) != 0

      # Spawn a puff of smoke behind the rocket.
      @world.as(World).hitscan.as(Hitscan).spawn_puff(actor.x, actor.y, actor.z)

      smoke = @world.as(World).thing_allocation.as(ThingAllocation).spawn_mobj(
        actor.x - actor.mom_x,
        actor.y - actor.mom_y,
        actor.z,
        MobjType::Smoke
      )

      smoke.mom_z = Fixed.one
      smoke.tics -= @world.as(World).random.next & 3
      smoke.tics = 1 if smoke.tics < 1

      # Adjust direction.
      dest = actor.tracer.as(Mobj)

      return if dest == nil || dest.health <= 0

      # Change angle.
      exact = Geometry.point_to_angle(
        actor.x, actor.y,
        dest.x, dest.y
      )

      if exact != actor.angle
        if exact - actor.angle > Angle.ang180
          actor.angle -= @@trace_angle
          if exact - actor.angle < Angle.ang180
            actor.angle = exact
          end
        else
          actor.angle += @@trace_angle
          if exact - actor.angle > Angle.ang180
            actor.angle = exact
          end
        end
      end

      exact = actor.angle
      actor.mom_x = Fixed.new(actor.info.as(MobjInfo).speed) * Trig.cos(exact)
      actor.mom_y = Fixed.new(actor.info.as(MobjInfo).speed) * Trig.sin(exact)

      # Change slope.
      dist = Geometry.aprox_distance(
        dest.x - actor.x,
        dest.y - actor.y
      )

      num = (dest.z + Fixed.from_i(40) - actor.z).data
      den = dist.data / actor.info.as(MobjInfo).speed
      den = 1 if den < 1

      slope = Fixed.new((num / den).to_i32)

      if slope < actor.mom_z
        actor.mom_z -= Fixed.one / 8
      else
        actor.mom_z += Fixed.one / 8
      end
    end

    def skel_whoosh(actor : Mobj)
      return if actor.target == nil

      face_target(actor)

      @world.as(World).start_sound(actor, Sfx::SKESWG, SfxType::Weapon)
    end

    def skel_fist(actor : Mobj)
      return if actor.target == nil
      target = actor.target.as(Mobj)

      face_target(target)

      if check_melee_range(actor)
        damage = ((@world.as(World).random.next % 10) + 1) * 6
        @world.as(World).start_sound(actor, Sfx::SKEPCH, SfxType::Weapon)
        @world.as(World).thing_interaction.as(ThingInteraction).damage_mobj(target, actor, actor, damage)
      end
    end

    #
    # Pain elemental
    #

    private def pain_shoot_skull(actor : Mobj, angle : Angle)
      # Count total number of skull currently on the level.
      count = 0

      enumerator = @world.as(World).thinkers.as(Thinkers).get_enumerator
      while true
        thinker = enumerator.current
        mobj = thinker.as?(Mobj)
        count += 1 if mobj != nil && mobj.as(Mobj).type == MobjType::Skull
        break if !enumerator.move_next
      end

      # If there are already 20 skulls on the level,
      # don't spit another one.
      return if count > 20

      # Okay, there's room for another one.
      pre_step = Fixed.from_i(4) + (actor.info.as(MobjInfo).radius + DoomInfo.mobj_infos[MobjType::Skull.to_i32].radius) / 2 * 3

      x = actor.x + pre_step * Trig.cos(angle)
      y = actor.y + pre_step * Trig.sin(angle)
      z = actor.z + Fixed.from_i(8)

      skull = @world.as(World).thing_allocation.as(ThingAllocation).spawn_mobj(x, y, z, MobjType::Skull)

      # Check for movements.
      if !@world.as(World).thing_movement.as(ThingMovement).try_move(skull, skull.x, skull.y)
        # Kill it immediately.
        @world.as(World).thing_interaction.as(ThingInteraction).damage_mobj(skull, actor, actor, 10000)
        return
      end

      skull.target = actor.target

      skull_attack(skull)
    end

    def pain_attack(actor : Mobj)
      return if actor.target == nil

      face_target(actor)

      pain_shoot_skull(actor, actor.angle)
    end

    def pain_die(actor : Mobj)
      fall(actor)

      pain_shoot_skull(actor, actor.angle + Angle.ang90)
      pain_shoot_skull(actor, actor.angle + Angle.ang180)
      pain_shoot_skull(actor, actor.angle + Angle.ang270)
    end

    #
    # Boss death
    #

    @junk : LineDef | Nil = nil

    private def init_boss_death
      v = Vertex.new(Fixed.zero, Fixed.zero)
      @junk = LineDef.new(v, v, 0, 0, 0, nil, nil)
    end

    def boss_death(actor : Mobj)
      options = @world.as(World).options
      if options.game_mode == GameMode::Commercial
        return if options.map != 7

        return if (actor.type != MobjType::Fatso) && (actor.type != MobjType::Baby)
      else
        case options.episode
        when 1
          return if options.map != 8 || actor.type != MobjType::Bruiser
        when 2
          return if options.map != 8 || actor.type != MobjType::Cyborg
        when 3
          return if options.map != 8 || actor.type != MobjType::Spider
        when 4
          case options.map
          when 6
            return if actor.type != MobjType::Cyborg
          when 8
            return if actor.type != MobjType::Spider
          else
            return
          end
        else
          return if options.map != 8
        end
      end

      # Make sure there is a player alive for victory.
      players = @world.as(World).options.players
      i : Int32 = 0
      while i < Player::MAX_PLAYER_COUNT
        break if players[i].in_game && players[i].health > 0
        i += 1
      end

      # No one left alive, so do not end game.
      return if i == Player::MAX_PLAYER_COUNT

      # Scan the remaining thinkers to see if all bosses are dead.
      enumerator = @world.as(World).thinkers.as(Thinkers).get_enumerator
      while true
        thinker = enumerator.current
        mo2 = thinker.as?(Mobj)
        if mo2 == nil
          enumerator.move_next
          next
        end
        mo2 = mo2.as(Mobj)

        # Other boss not dead.
        return if mo2 != actor && mo2.type == actor.type && mo2.health > 0
        break if !enumerator.move_next
      end

      # Victory!
      if options.game_mode == GameMode::Commercial
        if options.map == 7
          if actor.type == MobjType::Fatso
            @junk.as(LineDef).tag = 666
            @world.as(World).sector_action.as(SectorAction).do_floor(@junk.as(LineDef), FloorMoveType::LowerFloorToLowest)
            return
          end

          if actor.type == MobjType::Baby
            @junk.as(LineDef).tag = 667
            @world.as(World).sector_action.as(SectorAction).do_floor(@junk.as(LineDef), FloorMoveType::RaiseToTexture)
            return
          end
        end
      else
        case options.episode
        when 1
          @junk.as(LineDef).tag = 666
          @world.as(World).sector_action.as(SectorAction).do_floor(@junk.as(LineDef), FloorMoveType::LowerFloorToLowest)
          return
        when 4
          case options.map
          when 6
            @junk.as(LineDef).tag = 666
            @world.as(World).sector_action.as(SectorAction).do_door(@junk.as(LineDef), VerticalDoorType::BlazeOpen)
          when 8
            @junk.as(LineDef).tag = 666
            @world.as(World).sector_action.as(SectorAction).do_floor(@junk.as(LineDef), FloorMoveType::LowerFloorToLowest)
            return
          end
        end
      end

      @world.as(World).exit_level
    end

    def keen_die(actor : Mobj)
      fall(actor)

      # Scan the remaining thinkers
      # to see if all Keens are dead
      enumerator = @world.as(World).thinkers.as(Thinkers).get_enumerator
      while true
        thinker = enumerator.current
        mo2 = thinker.as?(Mobj)
        if mo2 == nil
          enumerator.move_next
          next
        end
        mo2 = mo2.as(Mobj)

        # Other Keen not dead
        return if mo2 != actor && mo2.type == actor.type && mo2.health > 0
        break if !enumerator.move_next
      end

      @junk.as(LineDef).tag = 666
      @world.as(World).sector_action.as(SectorAction).do_door(@junk.as(LineDef), VerticalDoorType::Open)
    end

    #
    # Icon of sin
    #

    @brain_targets : Array(Mobj | Nil) = [] of Mobj | Nil
    @brain_target_count : Int32 = 0
    @current_brain_target : Int32 = 0
    @easy : Bool = false

    private def init_brain
      @brain_targets = Array.new(32, nil)
      @brain_target_count = 0
      @current_brain_target = 0
      @easy = false
    end

    def brain_awake(actor : Mobj)
      # Find all the target spots.
      @brain_target_count = 0
      @current_brain_target = 0

      enumerator = @world.as(World).thinkers.as(Thinkers).get_enumerator
      while true
        thinker = enumerator.current
        mobj = thinker.as?(Mobj)
        # Not a mobj.
        if mobj == nil
          enumerator.move_next
          next
        end
        mobj = mobj.as(Mobj)

        if mobj.type == MobjType::Bosstarget
          @brain_targets[@brain_target_count] = mobj
          @brain_target_count += 1
        end
        break if !enumerator.move_next
      end

      @world.as(World).start_sound(actor, Sfx::BOSSIT, SfxType::Diffuse)
    end

    def brain_pain(actor : Mobj)
      @world.as(World).start_sound(actor, Sfx::BOSPN, SfxType::Diffuse)
    end

    def brain_scream(actor : Mobj)
      random = @world.as(World).random

      x = actor.x - Fixed.from_i(196)
      while x < actor.x + Fixed.from_i(320)
        y = actor.y - Fixed.from_i(320)
        z = Fixed.new(128) + Fixed.from_i(2) * random.next

        explosion = @world.as(World).thing_allocation.as(ThingAllocation).spawn_mobj(x, y, z, MobjType::Rocket)
        explosion.mom_z = Fixed.new(random.next * 512)
        explosion.set_state(MobjState::Brainexplode1)
        explosion.tics -= random.next & 7
        explosion.tics = 1 if explosion.tics < 1
        x += Fixed.from_i(8)
      end

      @world.as(World).start_sound(actor, Sfx::BOSDTH, SfxType::Diffuse)
    end

    def brain_explode(actor : Mobj)
      random = @world.as(World).random

      x = actor.x + Fixed.new((random.next - random.next) * 2048)
      y = actor.y
      z = Fixed.new(128) + Fixed.from_i(2) * random.next

      explosion = @world.as(World).thing_allocation.as(ThingAllocation).spawn_mobj(x, y, z, MobjType::Rocket)
      explosion.mom_z = Fixed.new(random.next * 512)
      explosion.set_state(MobjState::Brainexplode1)
      explosion.tics -= random.next & 7
      explosion.tics = 1 if explosion.tics < 1
    end

    def brain_die(actor : Mobj)
      @world.as(World).exit_level
    end

    def brain_spit(actor : Mobj)
      @easy = !@easy
      return if @world.as(World).options.skill.as(GameSkill) <= GameSkill::Easy && (!@easy)

      #  If the game is reconstructed from a savedata, brain targets might be cleared.
      # If so, re-initialize them to avoid crash.
      brain_awake(actor) if @brain_target_count == 0

      # Shoot a cube at current target.
      target = @brain_targets[@current_brain_target].as(Mobj)
      @current_brain_target = (@current_brain_target + 1) % @brain_target_count

      # Spawn brain missile.
      missile = @world.as(World).thing_allocation.as(ThingAllocation).spawn_missile(actor, target, MobjType::Spawnshot)
      missile.target = target
      missile.reaction_time = ((target.y - actor.y).data / missile.mom_y.data).to_i32

      @world.as(World).start_sound(actor, Sfx::BOSPIT, SfxType::Diffuse)
    end

    def spawn_sound(actor : Mobj)
      @world.as(World).start_sound(actor, Sfx::BOSCUB, SfxType::Misc)
      spawn_fly(actor)
    end

    def spawn_fly(actor : Mobj)
      actor.reaction_time -= 1
      # Still flying
      return if actor.reaction_time > 0

      target = actor.target

      # If the game is reconstructed from a savedata, the target might be null.
      # If so, use own position to spawn the monster.
      if target == nil
        target = actor
        actor.z = actor.subsector.as(Subsector).sector.floor_height
      end

      target = target.as(Mobj)

      ta = @world.as(World).thing_allocation.as(ThingAllocation)

      # First spawn teleport fog.
      fog = ta.spawn_mobj(target.x, target.y, target.z, MobjType::Spawnfire)
      @world.as(World).start_sound(fog, Sfx::TELEPT, SfxType::Misc)

      # Randomly select monster to spawn.
      r = @world.as(World).random.next

      # Probability distribution (kind of :), decreasing likelihood.
      type : MobjType = MobjType.new(0)
      if r < 50
        type = MobjType::Troop
      elsif r < 90
        type = MobjType::Sergeant
      elsif r < 120
        type = MobjType::Shadows
      elsif r < 130
        type = MobjType::Pain
      elsif r < 160
        type = MobjType::Head
      elsif r < 162
        type = MobjType::Vile
      elsif r < 172
        type = MobjType::Undead
      elsif r < 192
        type = MobjType::Baby
      elsif r < 222
        type = MobjType::Fatso
      elsif r < 246
        type = MobjType::Knight
      else
        type = MobjType::Bruiser
      end

      monster = ta.spawn_mobj(target.x, target.y, target.z, type)
      if look_for_players(monster, true)
        monster.set_state(monster.info.as(MobjInfo).see_state)
      end

      # Telefrag anything in this spot.
      @world.as(World).thing_movement.as(ThingMovement).teleport_move(monster, monster.x, monster.y)

      # Remove self (i.e., cube).
      @world.as(World).thing_allocation.as(ThingAllocation).remove_mobj(actor)
    end
  end
end
