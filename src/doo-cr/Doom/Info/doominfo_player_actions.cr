module Doocr
  module DoomInfo
    class PlayerActions
      def light0(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.light0(player)
      end

      def weaponready(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.weaponready(player, psp)
      end

      def lower(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.lower(player, psp)
      end

      def raise(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.raise(player, psp)
      end

      def punch(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.punch(player)
      end

      def refire(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.refire(player)
      end

      def firepistol(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.firepistol(pistol)
      end

      def light1(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.light1(player)
      end

      def fireshotgun(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.fireshotgun(player)
      end

      def light2(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.light2(player)
      end

      def fireshotgun2(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.fireshotgun2(player)
      end

      def checkreload(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.checkreload(player)
      end

      def openshotgun2(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.openshotgun2(player)
      end

      def loadshotgun2(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.loadshotgun2(player)
      end

      def closeshotgun2(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.closeshotgun2(player)
      end

      def firecgun(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.firecgun(player, psp)
      end

      def gunflash(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.gunflash(player)
      end

      def firemissile(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.firemissile(player)
      end

      def saw(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.saw(player)
      end

      def fireplasma(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.fireplasma(player)
      end

      def bfgsound(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.a_bfgsound(player)
      end

      def firebfg(world : World, player : Player, psp : PlayerSpriteDef)
        world.weapon_behavior.firebfg(player)
      end
    end
  end
end
