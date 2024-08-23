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
  class MobjActions
    def bfgspray(world : World, actor : Mobj)
      world.weapon_behavior.as(WeaponBehavior).bfgspray(actor)
    end

    def explode(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).explode(actor)
    end

    def pain(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).pain(actor)
    end

    def player_scream(world : World, actor : Mobj)
      world.player_behavior.as(PlayerBehavior).player_scream(actor)
    end

    def fall(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).fall(actor)
    end

    def xscream(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).xscream(actor)
    end

    def look(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).look(actor)
    end

    def chase(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).chase(actor)
    end

    def face_target(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).face_target(actor)
    end

    def pos_attack(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).pos_attack(actor)
    end

    def scream(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).scream(actor)
    end

    def spos_attack(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).spos_attack(actor)
    end

    def vile_chase(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).vile_chase(actor)
    end

    def vile_start(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).vile_start(actor)
    end

    def vile_target(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).vile_target(actor)
    end

    def vile_attack(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).vile_attack(actor)
    end

    def start_fire(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).start_fire(actor)
    end

    def fire(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).fire(actor)
    end

    def fire_crackle(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).fire_crackle(actor)
    end

    def tracer(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).tracer(actor)
    end

    def skel_whoosh(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).skel_whoosh(actor)
    end

    def skel_fist(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).skel_fist(actor)
    end

    def skel_missile(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).skel_missile(actor)
    end

    def fat_raise(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).fat_raise(actor)
    end

    def fat_attack1(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).fat_attack1(actor)
    end

    def fat_attack2(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).fat_attack2(actor)
    end

    def fat_attack3(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).fat_attack3(actor)
    end

    def boss_death(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).boss_death(actor)
    end

    def cpos_attack(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).cpos_attack(actor)
    end

    def cpos_refire(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).cpos_refire(actor)
    end

    def troop_attack(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).troop_attack(actor)
    end

    def sarg_attack(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).sarg_attack(actor)
    end

    def head_attack(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).head_attack(actor)
    end

    def bruis_attack(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).bruis_attack(actor)
    end

    def skull_attack(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).skull_attack(actor)
    end

    def metal(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).metal(actor)
    end

    def spid_refire(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).spid_refire(actor)
    end

    def baby_metal(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).baby_metal(actor)
    end

    def bspi_attack(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).bspi_attack(actor)
    end

    def hoof(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).hoof(actor)
    end

    def cyber_attack(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).cyber_attack(actor)
    end

    def pain_attack(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).pain_attack(actor)
    end

    def pain_die(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).pain_die(actor)
    end

    def keen_die(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).keen_die(actor)
    end

    def brain_pain(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).brain_pain(actor)
    end

    def brain_scream(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).brain_scream(actor)
    end

    def brain_die(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).brain_die(actor)
    end

    def brain_awake(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).brain_awake(actor)
    end

    def brain_spit(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).brain_spit(actor)
    end

    def spawn_sound(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).spawn_sound(actor)
    end

    def spawn_fly(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).spawn_fly(actor)
    end

    def brain_explode(world : World, actor : Mobj)
      world.monster_behavior.as(MonsterBehavior).brain_explode(actor)
    end
  end
end
