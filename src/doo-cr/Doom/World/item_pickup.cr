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
  class ItemPickup
    @world : World | Nil = nil

    def initialize(@world)
    end

    # Give the player the ammo. <br>
    # amount : The number of clip loads, not the individual count (0 = 1/2 clip). <br>
    # returns : False if the ammo can't be picked up at all.
    def give_ammo(player : Player, ammo : AmmoType, amount : Int32) : Bool
      return false if ammo == AmmoType::NoAmmo

      if ammo.to_i32 < 0 || ammo.to_i32 > AmmoType::Count.to_i32
        raise "Bad ammo type: #{ammo}"
      end

      return false if player.ammo[ammo.to_i32] == player.max_ammo[ammo.to_i32]

      if amount != 0
        amount *= DoomInfo::AmmoInfos.clip[ammo.to_i32]
      else
        amount = (DoomInfo::AmmoInfos.clip[ammo.to_i32] / 2).to_i32
      end

      if (@world.as(World).options.skill == GameSkill::Baby ||
         @world.as(World).options.skill == GameSkill::Nightmare)
        # Give double ammo in trainer mode, you'll need in nightmare.
        amount <<= 1
      end

      oldammo = player.ammo[ammo.to_i32]
      player.ammo[ammo.to_i32] += amount

      if player.ammo[ammo.to_i32] > player.max_ammo[ammo.to_i32]
        player.ammo[ammo.to_i32] = player.max_ammo[ammo.to_i32]
      end

      # If non zero ammo, don't change up weapons, player was lower on purpose.
      return true if oldammo != 0

      # We were down to zero, so select a new weapon.
      # Preferences are not user selectable.
      case ammo
      when AmmoType::Clip
        if player.ready_weapon == WeaponType::Fist
          if player.weapon_owned[WeaponType::Chaingun.to_i32]
            player.pending_weapon = WeaponType::Chaingun
          else
            player.pending_weapon = WeaponType::Pistol
          end
        end
      when AmmoType::Shell
        if (player.ready_weapon == WeaponType::Fist ||
           player.ready_weapon == WeaponType::Pistol)
          if player.weapon_owned[WeaponType::Shotgun.to_i32]
            player.pending_weapon = WeaponType::Shotgun
          end
        end
      when AmmoType::Cell
        if (player.ready_weapon == WeaponType::Fist ||
           player.ready_weapon == WeaponType::Pistol)
          if player.weapon_owned[WeaponType::Plasma.to_i32]
            player.pending_weapon = WeaponType::Plasma
          end
        end
      when AmmoType::Missile
        if player.ready_weapon == WeaponType::Fist
          if player.weapon_owned[WeaponType::Missile.to_i32]
            player.pending_weapon = WeaponType::Missile
          end
        end
      else
      end

      return true
    end

    @@bonus_add : Int32 = 6

    # Give the weapon to the player. <br>
    # dropped : True if the weapons is dropped by a monster.
    def give_weapon(player : Player, weapon : WeaponType, dropped : Bool) : Bool
      if @world.as(World).options.net_game && (@world.as(World).options.deathmatch != 2) && dropped
        # Leave placed weapons forever on net games.
        return false if player.weapon_owned[weapon.to_i32]

        player.bonus_count += @@bonus_add
        player.weapon_owned[weapon.to_i32] = true

        if @world.as(World).options.deathmatch != 0
          give_ammo(player, DoomInfo.weapon_infos[weapon.to_i32].ammo, 5)
        else
          give_ammo(player, DoomInfo.weapon_infos[weapon.to_i32].ammo, 2)
        end

        player.pending_weapon = weapon

        if player == @world.as(World).console_player
          @world.as(World).start_sound(player.mobj.as(Mobj), Sfx::WPNUP, SfxType::Misc)
        end

        return false
      end

      gave_ammo : Bool = false
      if DoomInfo.weapon_infos[weapon.to_i32].ammo != AmmoType::NoAmmo
        # Give one clip with a dropped weapon, two clips with a found weapon.
        if dropped
          gave_ammo = give_ammo(player, DoomInfo.weapon_infos[weapon.to_i32].ammo, 1)
        else
          gave_ammo = give_ammo(player, DoomInfo.weapon_infos[weapon.to_i32].ammo, 2)
        end
      else
        gave_ammo = false
      end

      gave_weapon : Bool = false
      if player.weapon_owned[weapon.to_i32]
        gave_weapon = false
      else
        gave_weapon = true
        player.weapon_owned[weapon.to_i32] = true
        player.pending_weapon = weapon
      end

      return gave_weapon || gave_ammo
    end

    # Give the health point to the player. <br>
    # returns : False if the health point isn't needed at all.
    private def give_health(player : Player, amount : Int32) : Bool
      return false if player.health > DoomInfo::DeHackEdConst.initial_health

      player.health += amount
      if player.health > DoomInfo::DeHackEdConst.initial_health
        player.health = DoomInfo::DeHackEdConst.initial_health
      end

      player.mobj.as(Mobj).health = player.health

      return true
    end

    # Give the armor to the player. <br>
    # returns : False if the armor is worse than the current armor.
    private def give_armor(player : Player, type : Int32) : Bool
      hits = type * 100

      # Don't pick up.
      return false if player.armor_points >= hits

      player.armor_type = type
      player.armor_points = hits

      return true
    end

    # Give the card to the player.
    private def give_card(player : Player, card : CardType)
      return if player.cards[card.to_i32]

      player.bonus_count = @@bonus_add
      player.cards[card.to_i32] = true
    end

    # Give the power up to the player. <br>
    # returns : False if the power up is not necessary.
    private def give_power(player : Player, type : PowerType) : Bool
      if type == PowerType::Invulnerability
        player.powers[type.to_i32] = DoomInfo::PowerDuration.invulnerability
        return true
      end

      if type == PowerType::Invisibility
        player.powers[type.to_i32] = DoomInfo::PowerDuration.invisibility
        player.mobj.as(Mobj).flags |= MobjFlags::Shadow
        return true
      end

      if type == PowerType::Infrared
        player.powers[type.to_i32] = DoomInfo::PowerDuration.infrared
        return true
      end

      if type == PowerType::IronFeet
        player.powers[type.to_i32] = DoomInfo::PowerDuration.iron_feet
        return true
      end

      if type == PowerType::Strength
        give_health(player, 100)
        player.powers[type.to_i32] = 1
        return true
      end

      if player.powers[type.to_i32] != 0
        # Already got it.
        return false
      end

      player.powers[type.to_i32] = 1

      return true
    end

    # Check for item pickup.
    def touch_special_thing(special : Mobj, toucher : Mobj)
      delta = special.z - toucher.z

      # Out of reach.
      return if delta > toucher.height || delta < Fixed.from_i(-8)

      sound = Sfx::ITEMUP
      player = toucher.player.as(Player)

      # Dead thing touching.
      # Can happen with a sliding player courpse
      return if toucher.health <= 0

      # Identify by sprite.
      case special.sprite
      # Armor.
      when Sprite::ARM1
        return if !give_armor(player, DoomInfo::DeHackEdConst.green_armor_class)
        player.send_message(DoomInfo::Strings::GOTARMOR)
      when Sprite::ARM2
        return if !give_armor(player, DoomInfo::DeHackEdConst.blue_armor_class)
        player.send_message(DoomInfo::Strings::GOTMEGA)

        # Bonus items.
      when Sprite::BON1
        # Can go over 100%.
        player.health += 1
        if player.health > DoomInfo::DeHackEdConst.max_health
          player.health = DoomInfo::DeHackEdConst.max_health
        end
        player.mobj.as(Mobj).health = player.health
        player.send_message(DoomInfo::Strings::GOTHTHBONUS)
      when Sprite::BON2
        # Can go over 100%.
        player.armor_points += 1
        if player.armor_points > DoomInfo::DeHackEdConst.max_armor
          player.armor_points = DoomInfo::DeHackEdConst.max_armor
        end
        if player.armor_type == 0
          player.armor_type = DoomInfo::DeHackEdConst.green_armor_class
        end
        player.send_message(DoomInfo::Strings::GOTARMBONUS)
      when Sprite::SOUL
        player.health += DoomInfo::DeHackEdConst.soulsphere_health
        if player.health > DoomInfo::DeHackEdConst.max_soulsphere
          player.health = DoomInfo::DeHackEdConst.max_soulsphere
        end
        player.mobj.as(Mobj).health = player.health
        player.send_message(DoomInfo::Strings::GOTSUPER)
        sound = Sfx::GETPOW
      when Sprite::MEGA
        return if @world.as(World).options.game_mode != GameMode::Commercial

        player.health = DoomInfo::DeHackEdConst.megasphere_health
        player.mobj.as(Mobj).health = player.health
        give_armor(player, DoomInfo::DeHackEdConst.blue_armor_class)
        player.send_message(DoomInfo::Strings::GOTMSPHERE)
        sound = Sfx::GETPOW

        # Cards.
        # Leave cards for everyone.
      when Sprite::BKEY
        if !player.cards[CardType::BlueCard.to_i32]
          player.send_message(DoomInfo::Strings::GOTBLUECARD)
        end
        give_card(player, CardType::BlueCard)
        return if @world.as(World).options.net_game
      when Sprite::YKEY
        if !player.cards[CardType::YellowCard.to_i32]
          player.send_message(DoomInfo::Strings::GOTYELWCARD)
        end
        give_card(player, CardType::YellowCard)
        return if @world.as(World).options.net_game
      when Sprite::RKEY
        if !player.cards[CardType::RedCard.to_i32]
          player.send_message(DoomInfo::Strings::GOTREDCARD)
        end
        give_card(player, CardType::RedCard)
        return if @world.as(World).options.net_game
      when Sprite::BSKU
        if !player.cards[CardType::BlueSkull.to_i32]
          player.send_message(DoomInfo::Strings::GOTBLUESKUL)
        end
        give_card(player, CardType::BlueSkull)
        return if @world.as(World).options.net_game
      when Sprite::YSKU
        if !player.cards[CardType::YellowSkull.to_i32]
          player.send_message(DoomInfo::Strings::GOTYELWSKUL)
        end
        give_card(player, CardType::YellowSkull)
        return if @world.as(World).options.net_game
      when Sprite::RSKU
        if !player.cards[CardType::RedSkull.to_i32]
          player.send_message(DoomInfo::Strings::GOTREDSKULL)
        end
        give_card(player, CardType::RedSkull)
        return if @world.as(World).options.net_game

        # Medikits, heals.
      when Sprite::STIM
        return if !give_health(player, 10)
        player.send_message(DoomInfo::Strings::GOTSTIM)
      when Sprite::MEDI
        return if !give_health(player, 25)
        if player.health < 25
          player.send_message(DoomInfo::Strings::GOTMEDINEED)
        else
          player.send_message(DoomInfo::Strings::GOTMEDIKIT)
        end

        # Power ups.
      when Sprite::PINV
        return if !give_power(player, PowerType::Invulnerability)
        player.send_message(DoomInfo::Strings::GOTINVUL)
        sound = Sfx::GETPOW
      when Sprite::PSTR
        return if !give_power(player, PowerType::Strength)
        player.send_message(DoomInfo::Strings::GOTBERSERK)
        if player.ready_weapon != WeaponType::Fist
          player.pending_weapon = WeaponType::Fist
        end
        sound = Sfx::GETPOW
      when Sprite::PINS
        return if !give_power(player, PowerType::Invisibility)
        player.send_message(DoomInfo::Strings::GOTINVIS)
        sound = Sfx::GETPOW
      when Sprite::SUIT
        return if !give_power(player, PowerType::IronFeet)
        player.send_message(DoomInfo::Strings::GOTSUIT)
        sound = Sfx::GETPOW
      when Sprite::PMAP
        return if !give_power(player, PowerType::AllMap)
        player.send_message(DoomInfo::Strings::GOTMAP)
        sound = Sfx::GETPOW
      when Sprite::PVIS
        return if !give_power(player, PowerType::Infrared)
        player.send_message(DoomInfo::Strings::GOTVISOR)
        sound = Sfx::GETPOW

        # Ammo.
      when Sprite::CLIP
        if (special.flags & MobjFlags::Dropped).to_i32 != 0
          return if !give_ammo(player, AmmoType::Clip, 0)
        else
          return if !give_ammo(player, AmmoType::Clip, 1)
        end
        player.send_message(DoomInfo::Strings::GOTCLIP)
      when Sprite::AMMO
        return if !give_ammo(player, AmmoType::Clip, 5)
        player.send_message(DoomInfo::Strings::GOTCLIPBOX)
      when Sprite::ROCK
        return if !give_ammo(player, AmmoType::Missile, 1)
        player.send_message(DoomInfo::Strings::GOTROCKET)
      when Sprite::BROK
        return if !give_ammo(player, AmmoType::Missile, 5)
        player.send_message(DoomInfo::Strings::GOTROCKBOX)
      when Sprite::CELL
        return if !give_ammo(player, AmmoType::Cell, 1)
        player.send_message(DoomInfo::Strings::GOTCELL)
      when Sprite::CELP
        return if !give_ammo(player, AmmoType::Cell, 5)
        player.send_message(DoomInfo::Strings::GOTCELLBOX)
      when Sprite::SHEL
        return if !give_ammo(player, AmmoType::Shell, 1)
        player.send_message(DoomInfo::Strings::GOTSHELLS)
      when Sprite::SBOX
        return if !give_ammo(player, AmmoType::Shell, 5)
        player.send_message(DoomInfo::Strings::GOTSHELLBOX)
      when Sprite::BPAK
        if !player.backpack
          AmmoType::Count.to_i32.times do |i|
            player.max_ammo[i] *= 2
          end
          player.backpack = true
        end
        AmmoType::Count.to_i32.times do |i|
          give_ammo(player, AmmoType.new(i), 1)
        end
        player.send_message(DoomInfo::Strings::GOTBACKPACK)

        # Weapons.
      when Sprite::BFUG
        return if !give_weapon(player, WeaponType::Bfg, false)
        player.send_message(DoomInfo::Strings::GOTBFG9000)
        sound = Sfx::WPNUP
      when Sprite::MGUN
        return if !give_weapon(player, WeaponType::Chaingun, (special.flags & MobjFlags::Dropped).to_i32 != 0)
        player.send_message(DoomInfo::Strings::GOTCHAINGUN)
        sound = Sfx::WPNUP
      when Sprite::CSAW
        return if !give_weapon(player, WeaponType::Chainsaw, false)
        player.send_message(DoomInfo::Strings::GOTCHAINSAW)
        sound = Sfx::WPNUP
      when Sprite::LAUN
        return if !give_weapon(player, WeaponType::Missile, false)
        player.send_message(DoomInfo::Strings::GOTLAUNCHER)
        sound = Sfx::WPNUP
      when Sprite::PLAS
        return if !give_weapon(player, WeaponType::Plasma, false)
        player.send_message(DoomInfo::Strings::GOTPLASMA)
        sound = Sfx::WPNUP
      when Sprite::SHOT
        return if !give_weapon(player, WeaponType::Shotgun, (special.flags & MobjFlags::Dropped).to_i32 != 0)
        player.send_message(DoomInfo::Strings::GOTCHAINSAW)
        sound = Sfx::WPNUP
      when Sprite::SGN2
        return if !give_weapon(player, WeaponType::SuperShotgun, (special.flags & MobjFlags::Dropped).to_i32 != 0)
        player.send_message(DoomInfo::Strings::GOTSHOTGUN2)
        sound = Sfx::WPNUP
      else
        raise "Unknown gettable thing!"
      end

      player.item_count += 1 if (special.flags & MobjFlags::CountItem).to_i32 != 0

      @world.as(World).thing_allocation.as(ThingAllocation).remove_mobj(special)

      if player == @world.as(World).console_player
        @world.as(World).start_sound(player.mobj.as(Mobj), sound, SfxType::Misc)
      end
    end
  end
end
