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
  class ThingInteraction
    @world : World | Nil = nil

    def initialize(@world)
      init_radius_attack()
    end

    # Called when the target is killed.
    def kill_mobj(source : Mobj, target : Mobj)
      target.flags &= ~(MobjFlags::Shootable | MobjFlags::Float | MobjFlags::SkullFly)

      if target.type != MobjType::Skull
        target.flags &= ~MobjFlags::NoGravity
      end

      target.flags |= MobjFlags::Corpse | MobjFlags::DropOff
      target.height = Fixed.new(target.height.data >> 2)

      if source != nil && source.player != nil
        # Count for intermission.
        if (target.flags & MobjFlags::CountKill) != 0
          source.player.as(Player).kill_count += 1
        end

        if target.player != nil
          source.player.as(Player).frags[target.player.as(Player).number] += 1
        end
      elsif !@world.as(World).options.net_game && (target.flags & MobjFlags::CountKill) != 0
        # Count all monster deaths, even those caused by other monsters.
        @world.as(World).options.players[0].kill_count += 1
      end

      if target.player != nil
        # Count environment kills against you.
        if source == nil
          target.player.as(Player).frags[target.player.as(Player).number] += 1
        end

        target.flags &= ~MobjFlags::Solid
        target.player.as(Player).player_state = PlayerState::Dead
        @world.as(World).player_behavior.as(PlayerBehavior).drop_weapon(target.player.as(Player))

        am = @world.as(World).auto_map

        if target.player.as(Player).number == @world.as(World).options.console_player && am.as(AutoMap).visible
          # Don't die in auto map, switch view prior to dying.
          am.as(AutoMap).close
        end
      end

      if target.health < -target.info.as(MobjInfo).spawn_health && target.info.as(MobjInfo).xdeath_state != 0
        target.set_state(target.info.as(MobjInfo).xdeath_state)
      else
        target.set_state(target.info.as(MobjInfo).death_state)
      end

      target.tics -= @world.as(World).random.next & 3
      target.tics = 1 if target.tics < 1

      # Drop stuff.
      # This determines the kind of object spawned during the death frame of a thing.
      item : MobjType
      case target.type
      when MobjType::Wolfss, MobjType::Possessed
        item = MobjType::Clip
      when MobjType::Shotguy
        item = MobjType::Shotgun
      when MobjType::Chainguy
        item = MobjType::Chaingun
      else
        return
      end

      mo = @world.as(World).thing_allocation.as(ThingAllocation).spawn_mobj(target.x, target.y, Mobj.on_floor_z, item)

      # Special versions of items
      mo.flags |= MobjFlags::Dropped
    end

    @@base_threshold : Int32 = 100

    # Damages both enemies and players.
    # "inflictor" is the thing that caused the damage creature
    # or missile, can be null (slime, etc).
    # "source" is the thing to target after taking damage creature
    # or null.
    # Source and inflictor are the same for melee attacks.
    # Source can be null for slime, barrel explosions and other
    # environmental stuff.
    def damage_mobj(target : Mobj, inflictor : Mobj | Nil = nil, source : Mobj | Nil = nil, damage : Int32 = 0)
      if (target.flags & MobjFlags::Shootable) == 0
        # Shouldn't happen...
        return
      end

      return if target.health <= 0

      if (target.flags & MobjFlags::SkullFly) != 0
        target.mom_x = Fixed.zero
        target.mom_y = Fixed.zero
        target.mom_z = Fixed.zero
      end

      player = target.player
      if player != nil && @world.as(World).options.skill == GameSkill::Baby
        # Take half damage in trainer mode.
        damage >>= 1
      end

      # Some close combat weapons should not inflict thrust and
      # push the victim out of reach, thus kick away unless using the chainsaw.
      not_chainsaw_attack = (source == nil ||
                             source.as(Mobj).player == nil ||
                             source.as(Mobj).player.as(Player).ready_weapon != WeaponType::Chainsaw)

      inflictor.try do |inflictor|
        if (target.flags & MobjFlags::NoClip) == 0 && not_chainsaw_attack
          ang = Geometry.point_to_angle(
            inflictor.x,
            inflictor.y,
            target.as(Mobj).x,
            target.as(Mobj).y
          )

          thrust = Fixed.new(damage * (Fixed::FRAC_UNIT >> 3) * (100 / target.info.as(MobjInfo).mass).to_i32)

          # Make fall forwards sometimes.
          if (damage < 40 &&
             damage > target.health &&
             target.z - inflictor.as(Mobj).z > Fixed.from_i(64) &&
             (@world.as(World).random.next & 1) != 0)
            ang += Angle.ang180
            thrust *= 4
          end

          target.mom_x += thrust * Trig.cos(ang)
          target.mom_y += thrust * Trig.sin(ang)
        end
      end

      # Player specific
      if player != nil
        player = player.as(Player)
        # End of game hell hack.
        if target.subsector.as(Subsector).sector.special == SectorSpecial.new(11) && damage >= target.health
          damage = target.health - 1
        end

        # Below certain threshold, ignore damage in GOD mode, or with INVUL power.
        if (damage < 1000 && ((player.cheats & CheatFlags::GodMode) != 0 ||
           player.powers[PowerType::Invulnerability.to_i32] > 0))
          return
        end

        saved : Int32 = 0

        if player.armor_type != 0
          if player.armor_type == 1
            saved = (damage / 3).to_i32
          else
            saved = (damage / 2).to_i32
          end

          if player.armor_points <= saved
            # Armor is used up.
            saved = player.armor_points
            player.armor_type = 0
          end

          player.armor_points -= saved
          damage -= saved
        end

        # Mirror mobj health here for Dave.
        player.health -= damage
        player.health = 0 if player.health < 0

        player.attacker = source

        # Add damage after armor / invuln.
        player.damage_count += damage

        if player.damage_count > 100
          # Teleport stomp does 10k points...
          player.damage_count = 100
        end
      end

      # Do the damage.
      target.health -= damage
      if target.health <= 0
        kill_mobj(source.as(Mobj), target)
        return
      end

      if ((@world.as(World).random.next < target.info.as(MobjInfo).pain_chance) &&
         (target.flags & MobjFlags::SkullFly) == 0)
        # Fight back!
        target.flags |= MobjFlags::JustHit

        target.set_state(target.info.as(MobjInfo).pain_state)
      end

      # We're awake now...
      target.reaction_time = 0

      if ((target.threshold == 0 || target.type == MobjType::Vile) &&
         source != nil &&
         source != target &&
         source.as(Mobj).type != MobjType::Vile)
        # If not intent on another player, chase after this one.
        target.target = source
        target.threshold = @@base_threshold
        if (target.state == DoomInfo.states[target.info.as(MobjInfo).spawn_state.to_i32] &&
           target.info.as(MobjInfo).see_state != MobjState::Nil)
          target.set_state(target.info.as(MobjInfo).see_state)
        end
      end
    end

    # Called when the missile hits something (wall or thing).
    def explode_missile(thing : Mobj)
      thing.mom_x = Fixed.zero
      thing.mom_y = Fixed.zero
      thing.mom_z = Fixed.zero

      thing.set_state(DoomInfo.mobj_infos[thing.type.to_i32].death_state)

      thing.tics -= @world.as(World).random.next & 3

      thing.tics = 1 if thing.tics < 1

      thing.flags &= ~MobjFlags::Missile

      if thing.info.as(MobjInfo).death_sound != 0
        @world.as(World).start_sound(thing, thing.info.as(MobjInfo).death_sound, SfxType::Misc)
      end
    end

    @bomb_source : Mobj | Nil = nil
    @bomb_spot : Mobj | Nil = nil
    @bomb_damage : Int32 = 0

    @radius_attack_func : Proc(Mobj, Bool) | Nil = nil

    private def init_radius_attack
      @radius_attack_func = do_radius_attack()
    end

    # "bomb_source" is the creature that caused the explosion at "bomb_spot".
    private def do_radius_attack(thing : Mobj) : Bool
      return true if (thing.flags & MobjFlags::Shootable) == 0

      # Boss spider and cyborg take no damage from concussion.
      return true if thing.type == MobjType::Cyborg || thing.type == MobjType::Spider

      dx = (thing.x - @bomb_spot.x).abs
      dy = (thing.y - @bomb_spot.y).abs

      dist = dx > dy ? dx : dy
      dist = Fixed.new((dist - thing.radius).data >> Fixed::FRAC_BITS)

      dist = Fixed.zero if dist < Fixed.zero

      if dist.data >= @bomb_damage
        # Out of range.
        return true
      end

      if @world.as(World).visibility_check.check_sight(thing, @bomb_spot)
        # Must be in direct path.
        damage_mobj(thing, @bomb_spot, @bomb_source, @bomb_damage - dist.data)
      end

      return true
    end

    # Source is the creature that caused the explosion at spot.
    def radius_attack(spot : Mobj, source : Mobj, damage : Int32)
      bm = @world.as(World).map.as(Map).blockmap

      dist = Fixed.from_i(damage + GameConst.max_thing_radius.data)

      block_y1 = bm.get_block_y(spot.y - dist)
      block_y2 = bm.get_block_y(spot.y + dist)
      block_x1 = bm.get_block_x(spot.x - dist)
      block_x2 = bm.get_block_x(spot.x + dist)

      @bomb_spot = spot
      @bomb_source = source
      @bomb_damage = damage

      by = block_y1
      while by <= block_y2
        bx = block_x1
        while bx <= block_x2
          bm.iterate_things(bx, by, @radius_attack_func.as(Proc(Mobj, Bool)))
          bx += 1
        end
        by += 1
      end
    end
  end
end
