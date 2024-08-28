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
  class WeaponBehavior
    class_getter melee_range : Fixed = Fixed.from_i(64)
    class_getter missile_range : Fixed = Fixed.from_i(32 * 64)

    class_getter weapon_top : Fixed = Fixed.from_i(32)
    class_getter weapon_bottom : Fixed = Fixed.from_i(128)

    @@raise_speed : Fixed = Fixed.from_i(6)
    @@lower_speed : Fixed = Fixed.from_i(6)

    @world : World | Nil = nil

    @current_bullet_slope : Fixed = Fixed.zero

    def initialize(@world)
    end

    def light0(player : Player)
      player.extra_light = 0
    end

    def weaponready(player : Player, psp : PlayerSpriteDef)
      pb = @world.as(World).player_behavior.as(PlayerBehavior)

      # Get out of attack state.
      if (player.mobj.as(Mobj).state == DoomInfo.states[MobjState::PlayAtk1.to_i32] ||
         player.mobj.as(Mobj).state == DoomInfo.states[MobjState::PlayAtk2.to_i32])
        player.mobj.as(Mobj).set_state(MobjState::Play)
      end

      if (player.ready_weapon == WeaponType::Chainsaw &&
         psp.state == DoomInfo.states[MobjState::Saw.to_i32])
        @world.as(World).start_sound(player.mobj.as(Mobj), Sfx::SAWIDL, SfxType::Weapon)
      end

      # Check for weapon change.
      # If player is dead, put the weapon away.
      if player.pending_weapon != WeaponType::NoChange || player.health == 0
        # Change weapon.
        # Pending weapon should allready be validated.
        new_state = DoomInfo.weapon_infos[player.ready_weapon.to_i32].down_state
        pb.set_player_sprite(player, PlayerSprite::Weapon, new_state)
        return
      end

      # Check for fire.
      # The missile launcher and bfg do not auto fire.
      if (player.cmd.as(TicCmd).buttons & TicCmdButtons.attack).to_i32 != 0
        if (!player.attack_down ||
           (player.ready_weapon != WeaponType::Missile && player.ready_weapon != WeaponType::Bfg))
          player.attack_down = true
          fire_weapon(player)
          return
        end
      else
        player.attack_down = false
      end

      # Bob the weapon based on movement speed.
      angle = (128 * player.mobj.as(Mobj).world.as(World).level_time) & Trig::FINE_MASK
      psp.sx = Fixed.one + player.bob * Trig.cos(angle)

      angle &= (Trig::FINE_ANGLE_COUNT / 2).to_i32 - 1
      psp.sy = @@weapon_top + player.bob * Trig.sin(angle)
    end

    private def check_ammo(player : Player) : Bool
      ammo = DoomInfo.weapon_infos[player.ready_weapon.to_i32].ammo

      # Minimal amount for one shot varies.
      count : Int32 = 0
      if player.ready_weapon == WeaponType::Bfg
        count = DoomInfo::DeHackEdConst.bfg_cells_per_shot
      elsif player.ready_weapon == WeaponType::SuperShotgun
        # Double barrel.
        count = 2
      else
        # Regular.
        count = 1
      end

      # Some do not need ammunition anyway.
      # Return if current ammunition sufficient.
      return true if ammo == AmmoType::NoAmmo || player.ammo[ammo.to_i32] >= count

      # Out of ammo, pick a weapon to change to.
      # Preferences are set here.
      x = true

      while x || player.pending_weapon == WeaponType::NoChange
        x = false
        if (player.weapon_owned[WeaponType::Plasma.to_i32] &&
           player.ammo[AmmoType::Cell.to_i32] > 0 &&
           @world.as(World).options.game_mode != GameMode::Shareware)
          player.pending_weapon = WeaponType::Plasma
        elsif (player.weapon_owned[WeaponType::SuperShotgun.to_i32] &&
              player.ammo[AmmoType::Shell.to_i32] > 2 &&
              @world.as(World).options.game_mode == GameMode::Commercial)
          player.pending_weapon = WeaponType::SuperShotgun
        elsif (player.weapon_owned[WeaponType::Chaingun.to_i32] &&
              player.ammo[AmmoType::Clip.to_i32] > 0)
          player.pending_weapon = WeaponType::Chaingun
        elsif (player.weapon_owned[WeaponType::Shotgun.to_i32] &&
              player.ammo[AmmoType::Shell.to_i32] > 0)
        elsif player.ammo[AmmoType::Clip.to_i32] > 0
          player.pending_weapon = WeaponType::Pistol
        elsif player.weapon_owned[WeaponType::Chainsaw.to_i32]
          player.pending_weapon = WeaponType::Chainsaw
        elsif (player.weapon_owned[WeaponType::Missile.to_i32] &&
              player.ammo[AmmoType::Missile.to_i32] > 0)
          player.pending_weapon = WeaponType::Missile
        elsif (player.weapon_owned[WeaponType::Bfg.to_i32] &&
              player.ammo[AmmoType::Cell.to_i32] > DoomInfo::DeHackEdConst.bfg_cells_per_shot &&
              @world.as(World).options.game_mode != GameMode::Shareware)
          player.pending_weapon = WeaponType::Bfg
        else
          # If everything fails.
          player.pending_weapon = WeaponType::Fist
        end
      end

      # Now set appropriate weapon overlay.
      @world.as(World).player_behavior.as(PlayerBehavior).set_player_sprite(
        player,
        PlayerSprite::Weapon,
        DoomInfo.weapon_infos[player.ready_weapon.to_i32].down_state
      )

      return false
    end

    private def recursive_sound(sec : Sector, soundblocks : Int32, soundtarget : Mobj, valid_count : Int32)
      # Wake up all monsters in this sector.
      if sec.valid_count == valid_count && sec.sound_traversed <= soundblocks + 1
        # Already flooded.
        return
      end

      sec.valid_count = valid_count
      sec.sound_traversed = soundblocks + 1
      sec.sound_target = soundtarget

      mc = @world.as(World).map_collision.as(MapCollision)

      sec.lines.size.times do |i|
        check = sec.lines[i]
        next if (check.flags & LineFlags::TwoSided).to_i32 == 0

        mc.line_opening(check)

        # Closed door.
        next if mc.open_range <= Fixed.zero

        other : Sector
        if check.front_side.as(SideDef).sector == sec
          other = check.back_side.as(SideDef).sector.as(Sector)
        else
          other = check.front_side.as(SideDef).sector.as(Sector)
        end

        if (check.flags & LineFlags::SoundBlock).to_i32 != 0
          if soundblocks == 0
            recursive_sound(other, 1, soundtarget, valid_count)
          end
        else
          recursive_sound(other, soundblocks, soundtarget, valid_count)
        end
      end
    end

    private def noise_alert(target : Mobj, emitter : Mobj)
      recursive_sound(
        emitter.subsector.as(Subsector).sector,
        0,
        target,
        @world.as(World).get_new_valid_count
      )
    end

    private def fire_weapon(player : Player)
      return if !check_ammo(player)

      player.mobj.as(Mobj).set_state(MobjState::PlayAtk1)

      new_state = DoomInfo.weapon_infos[player.ready_weapon.to_i32].attack_state
      @world.as(World).player_behavior.as(PlayerBehavior).set_player_sprite(player, PlayerSprite::Weapon, new_state)

      noise_alert(player.mobj.as(Mobj), player.mobj.as(Mobj))
    end

    def lower(player : Player, psp : PlayerSpriteDef)
      psp.sy += @@lower_speed

      # Is already down.
      return if psp.sy < @@weapon_bottom

      # Player is dead.
      if player.player_state == PlayerState::Dead
        psp.sy = @@weapon_bottom

        # Don't bring weapon back up.
        return
      end

      pb = @world.as(World).player_behavior.as(PlayerBehavior)

      # The old weapon has been lowered off the screen,
      # so change the weapon and start raising it.
      if player.health == 0
        # Player is dead, so keep the weapon off screen
        pb.set_player_sprite(player, PlayerSprite::Weapon, MobjState::Nil)
        return
      end

      player.ready_weapon = player.pending_weapon

      pb.bring_up_weapon(player)
    end

    def raise(player : Player, psp : PlayerSpriteDef)
      psp.sy -= @@raise_speed

      return if psp.sy > @@weapon_top

      psp.sy = @@weapon_top

      # The weapon has been raise all the way, so change to the ready state.
      new_state = DoomInfo.weapon_infos[player.ready_weapon.to_i32].ready_state

      @world.as(World).player_behavior.as(PlayerBehavior).set_player_sprite(player, PlayerSprite::Weapon, new_state)
    end

    def punch(player : Player)
      random = @world.as(World).random

      damage = (random.next % 10 + 1) << 1

      if (player.powers[PowerType::Strength.to_i32] != 0)
        damage *= 10
      end

      hs = @world.as(World).hitscan.as(Hitscan)

      angle = player.mobj.as(Mobj).angle
      angle += Angle.new((random.next - random.next) << 18)

      slope = hs.aim_line_attack(player.mobj.as(Mobj), angle, @@melee_range)
      hs.line_attack(player.mobj.as(Mobj), angle, @@melee_range, slope, damage)

      # Turn to face target.
      if hs.line_target != nil
        @world.as(World).start_sound(player.mobj.as(Mobj), Sfx::PUNCH, SfxType::Weapon)

        player.mobj.as(Mobj).angle = Geometry.point_to_angle(
          player.mobj.as(Mobj).x, player.mobj.as(Mobj).y,
          hs.line_target.as(Mobj).x, hs.line_target.as(Mobj).y
        )
      end
    end

    def saw(player : Player)
      damage = 2 * (@world.as(World).random.next % 10 + 1)

      random = @world.as(World).random

      attack_angle = player.mobj.as(Mobj).angle
      attack_angle += Angle.new((random.next - random.next) << 18)

      hs = @world.as(World).hitscan.as(Hitscan)

      # Use MeleeRange + Fixed.Epsilon so that the puff doesn't skip the flash.
      slope = hs.aim_line_attack(player.mobj.as(Mobj), attack_angle, @@melee_range + Fixed.epsilon)
      hs.line_attack(player.mobj.as(Mobj), attack_angle, @@melee_range + Fixed.epsilon, slope, damage)

      if hs.line_target == nil
        @world.as(World).start_sound(player.mobj.as(Mobj), Sfx::SAWFUL, SfxType::Weapon)
        return
      end

      @world.as(World).start_sound(player.mobj.as(Mobj), Sfx::SAWHIT, SfxType::Weapon)

      # Turn to face target.
      target_angle = Geometry.point_to_angle(
        player.mobj.as(Mobj).x, player.mobj.as(Mobj).y,
        hs.line_target.as(Mobj).x, hs.line_target.as(Mobj).y
      )

      if target_angle - player.mobj.as(Mobj).angle > Angle.ang180
        # The code below is based on Mocha Doom's implementation.
        # It is still unclear for me why this code works like the original verion...
        if (target_angle - player.mobj.as(Mobj).angle).data.to_i32 < (Angle.ang90.data * -1) / 20
          player.mobj.as(Mobj).angle = target_angle + Angle.ang90 / 21
        else
          player.mobj.as(Mobj).angle -= Angle.ang90 / 20
        end
      else
        if target_angle - player.mobj.as(Mobj).angle > Angle.ang90 / 20
          player.mobj.as(Mobj).angle = target_angle - Angle.ang90 / 21
        else
          player.mobj.as(Mobj).angle += Angle.ang90 / 20
        end
      end

      player.mobj.as(Mobj).flags |= MobjFlags::JustAttacked
    end

    def refire(player : Player)
      # Check for fire.
      # If a weaponchange is pending, let it go through instead.
      if ((player.cmd.as(TicCmd).buttons & TicCmdButtons.attack).to_i32 != 0 &&
         player.pending_weapon == WeaponType::NoChange &&
         player.health != 0)
        player.refire += 1
        fire_weapon(player)
      else
        player.refire = 0
        check_ammo(player)
      end
    end

    private def bullet_slope(mo : Mobj)
      hs = @world.as(World).hitscan.as(Hitscan)

      # See which target is to be aimed at.
      angle = mo.angle

      @current_bullet_slope = hs.aim_line_attack(mo, angle, Fixed.from_i(1024))

      if hs.line_target == nil
        angle += Angle.new(1 << 26)
        @current_bullet_slope = hs.aim_line_attack(mo, angle, Fixed.from_i(1024))
        if hs.line_target == nil
          angle -= Angle.new(2 << 26)
          @current_bullet_slope = hs.aim_line_attack(mo, angle, Fixed.from_i(1024))
        end
      end
    end

    private def gun_shot(mo : Mobj, accurate : Bool)
      random = @world.as(World).random

      damage = 5 * (random.next % 3 + 1)

      angle = mo.angle

      if !accurate
        angle += Angle.new((random.next - random.next) << 18)
      end

      @world.as(World).hitscan.as(Hitscan).line_attack(mo, angle, @@missile_range, @current_bullet_slope, damage)
    end

    def firepistol(player : Player)
      @world.as(World).start_sound(player.mobj.as(Mobj), Sfx::PISTOL, SfxType::Weapon)

      player.mobj.as(Mobj).set_state(MobjState::PlayAtk2)

      player.ammo[DoomInfo.weapon_infos[player.ready_weapon.to_i32].ammo.to_i32] -= 1

      @world.as(World).player_behavior.as(PlayerBehavior).set_player_sprite(
        player,
        PlayerSprite::Flash,
        DoomInfo.weapon_infos[player.ready_weapon.to_i32].flash_state
      )

      bullet_slope(player.mobj.as(Mobj))

      gun_shot(player.mobj.as(Mobj), player.refire == 0)
    end

    def light1(player : Player)
      player.extra_light = 1
    end

    def fireshotgun(player : Player)
      @world.as(World).start_sound(player.mobj.as(Mobj), Sfx::SHOTGN, SfxType::Weapon)

      player.mobj.as(Mobj).set_state(MobjState::PlayAtk2)

      player.ammo[DoomInfo.weapon_infos[player.ready_weapon.to_i32].ammo.to_i32] -= 1

      @world.as(World).player_behavior.as(PlayerBehavior).set_player_sprite(
        player,
        PlayerSprite::Flash,
        DoomInfo.weapon_infos[player.ready_weapon.to_i32].flash_state
      )

      bullet_slope(player.mobj.as(Mobj))

      7.times do |i|
        gun_shot(player.mobj.as(Mobj), false)
      end
    end

    def light2(player : Player)
      player.extra_light = 2
    end

    def firecgun(player : Player, psp : PlayerSpriteDef)
      @world.as(World).start_sound(player.mobj.as(Mobj), Sfx::PISTOL, SfxType::Weapon)

      return if player.ammo[DoomInfo.weapon_infos[player.ready_weapon.to_i32].ammo.to_i32] == 0

      player.mobj.as(Mobj).set_state(MobjState::PlayAtk2)

      player.ammo[DoomInfo.weapon_infos[player.ready_weapon.to_i32].ammo.to_i32] -= 1

      @world.as(World).player_behavior.as(PlayerBehavior).set_player_sprite(
        player,
        PlayerSprite::Flash,
        DoomInfo.weapon_infos[player.ready_weapon.to_i32].flash_state +
        psp.state.as(MobjStateDef).number - DoomInfo.states[MobjState::Chain1.to_i32].number
      )

      bullet_slope(player.mobj.as(Mobj))

      gun_shot(player.mobj.as(Mobj), player.refire == 0)
    end

    def fireshotgun2(player : Player)
      @world.as(World).start_sound(player.mobj.as(Mobj), Sfx::DSHTGN, SfxType::Weapon)

      player.mobj.as(Mobj).set_state(MobjState::PlayAtk2)

      player.ammo[DoomInfo.weapon_infos[player.ready_weapon.to_i32].ammo.to_i32] -= 2

      @world.as(World).player_behavior.as(PlayerBehavior).set_player_sprite(
        player,
        PlayerSprite::Flash,
        DoomInfo.weapon_infos[player.ready_weapon.to_i32].flash_state
      )

      bullet_slope(player.mobj.as(Mobj))

      random = @world.as(World).random.as(DoomRandom)
      hs = @world.as(World).hitscan.as(Hitscan)

      20.times do |i|
        damage = 5 * (random.next % 3 + 1)
        angle = player.mobj.as(Mobj).angle
        angle += Angle.new((random.next - random.next) << 19)
        hs.line_attack(
          player.mobj.as(Mobj),
          angle,
          @@missile_range,
          @current_bullet_slope + Fixed.new((random.next - random.next) << 5),
          damage
        )
      end
    end

    def checkreload(player : Player)
      check_ammo(player)
    end

    def openshotgun2(player : Player)
      @world.as(World).start_sound(player.mobj.as(Mobj), Sfx::DBOPN, SfxType::Weapon)
    end

    def loadshotgun2(player : Player)
      @world.as(World).start_sound(player.mobj.as(Mobj), Sfx::DBLOAD, SfxType::Weapon)
    end

    def closeshotgun2(player : Player)
      @world.as(World).start_sound(player.mobj.as(Mobj), Sfx::DBCLS, SfxType::Weapon)
      refire(player)
    end

    def gunflash(player : Player)
      player.mobj.as(Mobj).set_state(MobjState::PlayAtk2)

      @world.as(World).player_behavior.as(PlayerBehavior).set_player_sprite(
        player,
        PlayerSprite::Flash,
        DoomInfo.weapon_infos[player.ready_weapon.to_i32].flash_state
      )
    end

    def firemissile(player : Player)
      player.ammo[DoomInfo.weapon_infos[player.ready_weapon.to_i32].ammo.to_i32] -= 1

      @world.as(World).thing_allocation.as(ThingAllocation).spawn_player_missile(player.mobj.as(Mobj), MobjType::Rocket)
    end

    def fireplasma(player : Player)
      player.ammo[DoomInfo.weapon_infos[player.ready_weapon.to_i32].ammo.to_i32] -= 1

      @world.as(World).player_behavior.as(PlayerBehavior).set_player_sprite(
        player,
        PlayerSprite::Flash,
        DoomInfo.weapon_infos[player.ready_weapon.to_i32].flash_state + (@world.as(World).random.next % 1)
      )

      @world.as(World).thing_allocation.as(ThingAllocation).spawn_player_missile(player.mobj.as(Mobj), MobjType::Plasma)
    end

    def a_bfgsound(player : Player)
      @world.as(World).start_sound(player.mobj.as(Mobj), Sfx::BFG, SfxType::Weapon)
    end

    def firebfg(player : Player)
      player.ammo[DoomInfo.weapon_infos[player.ready_weapon.to_i32].ammo.to_i32] -= DoomInfo::DeHackEdConst.bfg_cells_per_shot

      @world.as(World).thing_allocation.as(ThingAllocation).spawn_player_missile(player.mobj.as(Mobj), MobjType::Bfg)
    end

    def bfgspray(bfg_ball : Mobj)
      hs = @world.as(World).hitscan.as(Hitscan)
      random = @world.as(World).random

      # Offset angles from its attack angle.
      40.times do |i|
        an = bfg_ball.angle - Angle.ang90 / 2 + Angle.ang90 / 40 * i.to_u32

        # bfg_ball.Target is the originator (player) of the missile.
        hs.aim_line_attack(bfg_ball.target.as(Mobj), an, Fixed.from_i(16 * 64))

        next if hs.line_target == nil

        @world.as(World).thing_allocation.as(ThingAllocation).spawn_mobj(
          hs.line_target.as(Mobj).x,
          hs.line_target.as(Mobj).y,
          hs.line_target.as(Mobj).z + (hs.line_target.as(Mobj).height >> 2),
          MobjType::Extrabfg
        )

        damage = 0
        15.times do |i|
          damage += (random.next & 7) + 1
        end

        @world.as(World).thing_interaction.as(ThingInteraction).damage_mobj(
          hs.line_target.as(Mobj),
          bfg_ball.target,
          bfg_ball.target,
          damage
        )
      end
    end
  end
end
