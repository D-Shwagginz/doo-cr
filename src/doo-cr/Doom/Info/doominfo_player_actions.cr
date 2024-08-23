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
  module DoomInfo
    class PlayerActions
      def light0(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.as(WeaponBehavior).light0(player)
      end

      def weaponready(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.as(WeaponBehavior).weaponready(player, psp)
      end

      def lower(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.as(WeaponBehavior).lower(player, psp)
      end

      def raise(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.as(WeaponBehavior).raise(player, psp)
      end

      def punch(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.as(WeaponBehavior).punch(player)
      end

      def refire(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.as(WeaponBehavior).refire(player)
      end

      def firepistol(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.as(WeaponBehavior).firepistol(player)
      end

      def light1(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.as(WeaponBehavior).light1(player)
      end

      def fireshotgun(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.as(WeaponBehavior).fireshotgun(player)
      end

      def light2(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.as(WeaponBehavior).light2(player)
      end

      def fireshotgun2(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.as(WeaponBehavior).fireshotgun2(player)
      end

      def checkreload(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.as(WeaponBehavior).checkreload(player)
      end

      def openshotgun2(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.as(WeaponBehavior).openshotgun2(player)
      end

      def loadshotgun2(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.as(WeaponBehavior).loadshotgun2(player)
      end

      def closeshotgun2(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.as(WeaponBehavior).closeshotgun2(player)
      end

      def firecgun(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.as(WeaponBehavior).firecgun(player, psp)
      end

      def gunflash(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.as(WeaponBehavior).gunflash(player)
      end

      def firemissile(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.as(WeaponBehavior).firemissile(player)
      end

      def saw(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.as(WeaponBehavior).saw(player)
      end

      def fireplasma(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.as(WeaponBehavior).fireplasma(player)
      end

      def bfgsound(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.as(WeaponBehavior).a_bfgsound(player)
      end

      def firebfg(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.as(WeaponBehavior).firebfg(player)
      end
    end
  end
end
