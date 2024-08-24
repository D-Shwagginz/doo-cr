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
    module MobjActions
      def self.bfgspray(world : World, actor : Mobj)
        world.weapon_behavior.as(WeaponBehavior).bfgspray(actor)
      end

      def self.explode(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).explode(actor)
      end

      def self.pain(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).pain(actor)
      end

      def self.player_scream(world : World, actor : Mobj)
        world.player_behavior.as(PlayerBehavior).player_scream(actor)
      end

      def self.fall(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).fall(actor)
      end

      def self.xscream(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).xscream(actor)
      end

      def self.look(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).look(actor)
      end

      def self.chase(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).chase(actor)
      end

      def self.face_target(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).face_target(actor)
      end

      def self.pos_attack(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).pos_attack(actor)
      end

      def self.scream(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).scream(actor)
      end

      def self.spos_attack(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).spos_attack(actor)
      end

      def self.vile_chase(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).vile_chase(actor)
      end

      def self.vile_start(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).vile_start(actor)
      end

      def self.vile_target(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).vile_target(actor)
      end

      def self.vile_attack(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).vile_attack(actor)
      end

      def self.start_fire(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).start_fire(actor)
      end

      def self.fire(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).fire(actor)
      end

      def self.fire_crackle(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).fire_crackle(actor)
      end

      def self.tracer(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).tracer(actor)
      end

      def self.skel_whoosh(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).skel_whoosh(actor)
      end

      def self.skel_fist(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).skel_fist(actor)
      end

      def self.skel_missile(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).skel_missile(actor)
      end

      def self.fat_raise(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).fat_raise(actor)
      end

      def self.fat_attack1(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).fat_attack1(actor)
      end

      def self.fat_attack2(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).fat_attack2(actor)
      end

      def self.fat_attack3(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).fat_attack3(actor)
      end

      def self.boss_death(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).boss_death(actor)
      end

      def self.cpos_attack(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).cpos_attack(actor)
      end

      def self.cpos_refire(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).cpos_refire(actor)
      end

      def self.troop_attack(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).troop_attack(actor)
      end

      def self.sarg_attack(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).sarg_attack(actor)
      end

      def self.head_attack(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).head_attack(actor)
      end

      def self.bruis_attack(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).bruis_attack(actor)
      end

      def self.skull_attack(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).skull_attack(actor)
      end

      def self.metal(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).metal(actor)
      end

      def self.spid_refire(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).spid_refire(actor)
      end

      def self.baby_metal(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).baby_metal(actor)
      end

      def self.bspi_attack(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).bspi_attack(actor)
      end

      def self.hoof(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).hoof(actor)
      end

      def self.cyber_attack(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).cyber_attack(actor)
      end

      def self.pain_attack(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).pain_attack(actor)
      end

      def self.pain_die(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).pain_die(actor)
      end

      def self.keen_die(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).keen_die(actor)
      end

      def self.brain_pain(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).brain_pain(actor)
      end

      def self.brain_scream(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).brain_scream(actor)
      end

      def self.brain_die(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).brain_die(actor)
      end

      def self.brain_awake(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).brain_awake(actor)
      end

      def self.brain_spit(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).brain_spit(actor)
      end

      def self.spawn_sound(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).spawn_sound(actor)
      end

      def self.spawn_fly(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).spawn_fly(actor)
      end

      def self.brain_explode(world : World, actor : Mobj)
        world.monster_behavior.as(MonsterBehavior).brain_explode(actor)
      end
    end
  end
end
