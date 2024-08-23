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
  class PlayerBehavior
    @@forward_move : Array(Int32) = [
      0x19,
      0x32,
    ]

    @@side_move : Array(Int32) = [
      0x18,
      0x28,
    ]

    @@angle_turn : Array(Int32) = [
      640,
      1280,
      320, # For slow turn.
    ]

    @@max_move : Int32 = @@forward_move[1]
    @@slow_turn_tics : Int32 = 6

    @world : World | Nil = nil

    def initialize(@world)
    end

    #
    # Player movement
    #

    # Called every frame to update player state.
    def player_think(player : Player)
      player.message_time -= 1 if player.message_time > 0

      if (player.cheats & CheatFlags::NoClip) != 0
        player.mobj.flags |= MobjFlags::NoClip
      else
        player.mobj.flags &= ~MobjFlags::NoClip
      end

      # Chain saw run forward.
      cmd = player.cmd
      if (player.mobj.flags & MobjFlags::JustAttacked) != 0
        cmd.angle_turn = 0
        cmd.forward_move = 0xC800 / 512
        cmd.side_move = 0
        player.mobj.flags &= ~MobjFlags::JustAttacked
      end

      if player.player_state == PlayerState::Dead
        death_think(player)
        return
      end

      # Move around.
      # Reactiontime is used to prevent movement for a bit after a teleport.
      if player.mobj.reaction_time > 0
        player.mobj.reaction_time -= 1
      else
        move_player(player)
      end

      calc_height(player)

      if player.mobj.subsector.sector.special != 0
        player_in_special_sector(player)
      end

      # Check for weapon change.

      # A special event has no other buttons.
      cmd.buttons = 0 if (cmd.buttons & TicCmdButtons.special) != 0

      if (cmd.buttons & TicCmdButtons.change) != 0
        # The actual changing of the weapon is done when the weapon psprite can do it.
        # Not in the middle of an attack.
        new_weapon = (cmd.buttons & TicCmdButtons.weapon_mask) >> TicCmdButtons.weapon_shift

        if (new_weapon == WeaponType::Fist.to_i32 &&
           player.weapon_owned[WeaponType::Chainsaw] &&
           !(player.ready_weapon == WeaponType::Chainsaw && player.powers[PowerType::Strength.to_i32] != 0))
          new_weapon = WeaponType::Chainsaw.to_i32
        end

        if ((@world.as(World).options.game_mode == GameMode::Commercial) &&
           new_weapon == WeaponType::Shotgun.to_i32 &&
           player.weapon_owned[WeaponType::SuperShotgun.to_i32] &&
           player.ready_weapon != WeaponType::SuperShotgun)
          new_weapon = WeaponType::SuperShotgun.to_i32
        end

        if (player.weapon_owned[new_weapon] &&
           new_weapon != player.ready_weapon.to_i32)
          # Do not go to plasma or BFG in shareware, even if cheated.
          if ((new_weapon != WeaponType::Plasma && new_weapon != WeaponType::Bfg.to_i32) ||
             (@world.as(World).options.game_mode != GameMode::Shareware))
            player.pending_weapon = WeaponType.new(new_weapon)
          end
        end
      end

      # Check for use.
      if (cmd.buttons & TicCmdButtons.use) != 0
        if !player.use_down
          @world.as(World).map_interaction.use_lines(player)
          player.use_down = true
        end
      else
        player.use_down = false
      end

      # Cycle player sprites.
      move_player_sprites(player)

      # Counters, time dependend power ups.

      # Strength counts up to diminish fade.
      if player.powers[PowerType::Strength.to_i32] != 0
        player.powers[PowerType::Strength.to_i32] += 1
      end

      if player.powers[PowerType::Invulnerabillity.to_i32] > 0
        player.powers[PowerType::Invulnerabillity.to_i32] -= 1
      end

      if player.powers[PowerType::Invisibility.to_i32] > 0
        player.powers[PowerType::Invisibility.to_i32] -= 1
        if player.powers[PowerType::Invisibility] == 0
          player.mobj.flags &= ~MobjFlags::Shadow
        end
      end

      if player.powers[PowerType::Infrared.to_i32] > 0
        player.powers[PowerType::Infrared.to_i32] -= 1
      end

      if player.powers[PowerType::IronFeet.to_i32] > 0
        player.powers[PowerType::IronFeet.to_i32] -= 1
      end

      player.damage_count -= 1 if player.damage_count > 0

      player.bonus_count -= 1 if player.bonus_count > 0

      # Handling colormaps.
      if player.powers[PowerType::Invulnerabillity.to_i32] > 0
        if (player.powers[PowerType::Invulnerabillity.to_i32] > 4 * 32 ||
           (player.powers[PowerType::Invulnerabillity] * 8) != 0)
          player.fixed_color_map = ColorMap.inverse
        else
          player.fixed_color_map = 0
        end
      elsif player.powers[PowerType::Infrared.to_i32] > 0
        if (player.powers[PowerType::Infrared.to_i32] > 4 * 32 ||
           (player.powers[PowerType::Infrared] * 8) != 0)
          # Almost full bright.
          player.fixed_color_map = 1
        else
          player.fixed_color_map = 0
        end
      else
        player.fixed_color_map = 0
      end
    end

    @@max_bob : Fixed = Fixed.new(0x100000)

    @on_ground : Bool = false

    # Move the player according to TicCmd.
    def move_player(player : Player)
      cmd = player.cmd

      player.mobj.angle += Angle.new(cmd.angle_turn << 16)

      # Do not let the player control movement if not onground.
      @on_ground = player.mobj.z <= player.mobj.floor_z

      if cmd.forward_move != 0 && @on_ground
        thrust(player, player.mobj.angle, Fixed.new(cmd.forward_move * 2048))
      end

      if cmd.side_move != 0 && @on_ground
        thrust(player, player.mobj.angle - Angle.ang90, Fixed.new(cmd.side_move * 2048))
      end

      if ((cmd.forward_move != 0 || cmd.side_move != 0) &&
         player.mobj.state == DoomInfo.states[MobjState::Play.to_i32])
        player.mobj.set_state(MobjState::PlayRun1)
      end
    end

    # Calculate the walking / running height adjustment.
    def calc_height(player : Player)
      # Regular movement bobbing.
      # It needs to be calculated for gun swing even if not on ground.
      player.bob = player.mobj.mom_x * player.mobj.mom_x + player.mobj.mom_y * player.mobj.mom_y
      player.bob >>= 2
      player.bob = @@max_bob if player.bob > @@max_bob

      if (player.cheats & CheatFlags::NoMomentum) != 0 || !@on_ground
        player.view_z = player.mobj.z + Player.normal_view_height

        if player.view_z > player.mobj.ceiling_z - Fixed.from_i(4)
          player.view_z = player.mobj.ceiling_z - Fixed.from_i(4)
        end

        player.view_z = player.mobj.z + player.view_height

        return
      end

      angle = (Trig::FINE_ANGLE_COUNT / 20 * @world.as(World).level_time) & Trig::FINE_MASK

      bob = player.bob / 2 * Trig.sin(angle)

      # Move viewheight.
      if player.player_state == PlayerState::Live
        player.view_height += player.delta_view_height

        if player.view_height > Player.normal_view_height
          player.view_height = Player.normal_view_height
          player.delta_view_height = Fixed.zero
        end

        if player.view_height < Player.normal_view_height / 2
          player.view_height = Player.normal_view_height / 2

          if player.delta_view_height <= Fixed.zero
            player.delta_view_height = Fixed.new(1)
          end
        end
      end

      player.view_z = player.mobj.z + player.view_height + bob

      if player.view_z > player.mobj.ceiling_z - Fixed.from_i(4)
        player.view_z = player.mobj.ceiling_z - Fixed.from_i(4)
      end
    end

    # Moves the given origin along a given angle.
    def thrust(player : Player, angle : Angle, move : Fixed)
      player.mobj.mom_x += move * Trig.cos(angle)
      player.mobj.mom_y += move * Trig.sin(angle)
    end

    # Called every tic frame that the player origin is in a special sector.
    private def player_in_special_sector(player : Player)
      sector = player.mobj.subsector.sector

      # Falling, not all the way down yet?
      return if player.mobj.z != sector.floor_height

      ti = @world.as(World).thing_interaction

      # Has hitten ground.
      case sector.special.to_i32
      when 5
        # Hell slime damage.
        if player.powers[PowerType::IronFeet] == 0
          if (@world.as(World).level_time & 0x1f) == 0
            ti.damage_mobj(player.mobj, nil, nil, 10)
          end
        end
        break
      when 7
        # Nukage damage.
        if player.powers[PowerType::IronFeet] == 0
          if (@world.as(World).level_time & 0x1f) == 0
            ti.damage_mobj(player.mobj, nil, nil, 5)
          end
        end
        break
      when 16, 4 # Super hell slime damage, strobe hurt.
        if player.powers[PowerType::IronFeet] == 0 || (@world.as(World).random.next < 5)
          if (@world.as(World).level_time & 0x1f) == 0
            ti.damage_mobj(player.mobj, nil, nil, 20)
          end
        end
        break
      when 9
        # Secret sector.
        player.secret_count += 1
        sector.special = 0
        break
      when 11
        # Exit super damage for E1M8 finale.
        player.cheats &= ~CheatFlags::GodMode
        if (@world.as(World).level_time & 0x1f) == 0
          ti.damage_mobj(player.mobj, nil, nil, 20)
        end
        if player.health <= 10
          @world.as(World).exit_level
        end
        break
      else
        raise "Unknown sector special: #{sector.special.to_i32}"
      end
    end

    @@ang5 : Angle = Angle.new((Angle.ang90.data / 18).to_i32)

    # Fall on your face when dying.
    # Decrease POV height to floor height.
    private def death_think(player : Player)
      move_player_sprites(player)

      # Fall to the ground.
      if player.view_height > Fixed.from_i(6)
        player.view_height -= Fixed.one
      end

      if player.view_height < Fixed.from_i(6)
        player.view_height = Fixed.from_i(6)
      end

      player.delta_view_height = Fixed.zero
      @on_ground = player.mobj <= player.mobj.floor_z
      calc_height(player)

      if player.attacker != nil && player.attacker != player.mobj
        angle = Geometry.point_to_angle(
          player.mobj.x, player.mobj.y,
          player.attacker.x, player.attacker.y
        )

        delta = angle - player.mobj.angle

        if delta < @@ang5 || delta.data > (-@@ang5).data
          # Looking at killer, so fade damage flash down.
          player.mobj.angle = angle

          player.damage_count -= 1 if player.damage_count > 0
        elsif delta < Angle.ang180
          player.mobj.angle += @@ang5
        else
          player.mobj.angle -= @@ang5
        end
      elsif player.damage_count > 0
        player.damage_count -= 1
      end

      if (player.cmd.buttons & TicCmdButtons.use) != 0
        player.player_state = PlayerState::Reborn
      end
    end

    #
    # Player's weapon sprites
    #

    # Called at start of level for each player.
    def setup_player_sprites(player : Player)
      # Remove all psprites.
      PlayerSprite::Count.to_i32.times do |i|
        player.player_sprites[i].state = nil
      end

      # Spawn the gun.
      player.pending_weapon = player.ready_weapon
      bring_up_weapon(player)
    end

    # Starts bringing the pending weapon up from the bottom of the screen.
    def bring_up_weapon(player : Player)
      if player.pending_weapon == WeaponType::NoChange
        player.pending_weapon = player.ready_weapon
      end

      if player.pending_weapon == WeaponType::Chainsaw
        @world.as(World).start_sound(player.mobj.as(Mobj), Sfx::SAWUP, SfxType::Weapon)
      end

      new_state = DoomInfo.weapon_infos[player.pending_weapon.to_i32].up_state

      player.pending_weapon = WeaponType::NoChange
      player.player_sprites[PlayerSprite::Weapon.to_i32].sy = WeaponBehavior.weapon_bottom

      set_player_sprite(player, PlayerSprite::Weapon, new_state)
    end

    # Change the player's weapon sprite.
    def set_player_sprite(player : Player, position : PlayerSprite, state : MobjState)
      psp = player.player_sprites[position.to_i32]

      x = true
      while x || psp.tics == 0
        x = false
        if state == MobjState::Nil
          # Object removed itself.
          psp.state = nil
          break
        end

        state_def = DoomInfo.states[state.to_i32]
        psp.state = state_def
        psp.tics = state_def.tics # Could be 0

        if state_def.misc1 != 0
          # Coordinate set.
          psp.sx = Fixed.from_i(state_def.misc1)
          psp.sy = Fixed.from_i(state_def.misc2)
        end

        # Call action routine.
        # Modified handling.
        if state_def.player_action != nil
          state_def.player_action.as(Proc(World, Player, PlayerSpriteDef, Nil)).call(@world.as(World), player, psp)
          break if psp.state == nil
        end
        state = psp.state.as(MobjStateDef).next
      end
      # An initial state of 0 could cycle through.
    end

    # Called every tic by player thinking routine.
    private def move_player_sprites(player : Player)
      PlayerSprite::Count.to_i32.times do |i|
        psp = player.player_sprites[i]

        # A null state means not active.
        if (psp.state != nil)
          # Drop tic count and possibly change state.

          # A -1 tic count never changes.
          if psp.tics != -1
            psp.tics -= 1
            if psp.tics == 0
              set_player_sprite(player, PlayerState.new(i), psp.state.next)
            end
          end
        end
      end

      player.player_sprites[PlayerSprite::Flash.to_i32].sx = player.player_sprites[PlayerSprite::Weapon.to_i32].sx
      player.player_sprites[PlayerSprite::Flash.to_i32].sy = player.player_sprites[PlayerSprite::Weapon.to_i32].sy
    end

    # Player died, so put the weapon away.
    def drop_weapon(player : Player)
      set_player_sprite(
        player,
        PlayerSprite::Weapon,
        DoomInfo.weapon_infos[player.ready_weapon.to_i32].down_state
      )
    end

    #
    # Miscellaneous
    #

    # Play the player's death sound.
    def player_scream(player : Mobj)
      sound = Sfx::PLDETH

      if (@world.as(World).options.game_mode == GameMode::Commercial) && (player.health < -50)
        # If the player dies less than -50% without gibbing.
        sound = Sfx::PDIEHI
      end

      @world.as(World).start_sound(player, sound, SfxType::Voice)
    end
  end
end
