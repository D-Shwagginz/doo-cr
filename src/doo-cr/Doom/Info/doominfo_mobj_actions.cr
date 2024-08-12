module Doocr
  class MobjActions
    def bfgspray(world : World, actor : Mobj)
      world.WeaponBehavior.bfgspray(actor)
    end

    def explode(world : World, actor : Mobj)
      world.monster_behavior.explode(actor)
    end

    def pain(world : World, actor : Mobj)
      world.monster_behavior.pain(actor)
    end

    def player_scream(world : World, actor : Mobj)
      world.PlayerBehavior.player_scream(actor)
    end

    def fall(world : World, actor : Mobj)
      world.monster_behavior.fall(actor)
    end

    def xscream(world : World, actor : Mobj)
      world.monster_behavior.xscream(actor)
    end

    def look(world : World, actor : Mobj)
      world.monster_behavior.look(actor)
    end

    def chase(world : World, actor : Mobj)
      world.monster_behavior.chase(actor)
    end

    def face_target(world : World, actor : Mobj)
      world.monster_behavior.face_target(actor)
    end

    def pos_attack(world : World, actor : Mobj)
      world.monster_behavior.pos_attack(actor)
    end

    def scream(world : World, actor : Mobj)
      world.monster_behavior.scream(actor)
    end

    def spos_attack(world : World, actor : Mobj)
      world.monster_behavior.spos_attack(actor)
    end

    def vile_chase(world : World, actor : Mobj)
      world.monster_behavior.vile_chase(actor)
    end

    def vile_start(world : World, actor : Mobj)
      world.monster_behavior.vile_start(actor)
    end

    def vile_target(world : World, actor : Mobj)
      world.monster_behavior.vile_target(actor)
    end

    def vile_attack(world : World, actor : Mobj)
      world.monster_behavior.vile_attack(actor)
    end

    def start_fire(world : World, actor : Mobj)
      world.monster_behavior.start_fire(actor)
    end

    def fire(world : World, actor : Mobj)
      world.monster_behavior.fire(actor)
    end

    def fire_crackle(world : World, actor : Mobj)
      world.monster_behavior.fire_crackle(actor)
    end

    def tracer(world : World, actor : Mobj)
      world.monster_behavior.tracer(actor)
    end

    def skel_whoosh(world : World, actor : Mobj)
      world.monster_behavior.skel_whoosh(actor)
    end

    def skel_fist(world : World, actor : Mobj)
      world.monster_behavior.skel_fist(actor)
    end

    def skel_missile(world : World, actor : Mobj)
      world.monster_behavior.skel_missile(actor)
    end

    def fat_raise(world : World, actor : Mobj)
      world.monster_behavior.fat_raise(actor)
    end

    def fat_attack1(world : World, actor : Mobj)
      world.monster_behavior.fat_attack1(actor)
    end

    def fat_attack2(world : World, actor : Mobj)
      world.monster_behavior.fat_attack2(actor)
    end

    def fat_attack3(world : World, actor : Mobj)
      world.monster_behavior.fat_attack3(actor)
    end

    def boss_death(world : World, actor : Mobj)
      world.monster_behavior.boss_death(actor)
    end

    def cpos_attack(world : World, actor : Mobj)
      world.monster_behavior.cpos_attack(actor)
    end

    def cpos_refire(world : World, actor : Mobj)
      world.monster_behavior.cpos_refire(actor)
    end

    def troop_attack(world : World, actor : Mobj)
      world.monster_behavior.troop_attack(actor)
    end

    def sarg_attack(world : World, actor : Mobj)
      world.monster_behavior.sarg_attack(actor)
    end

    def head_attack(world : World, actor : Mobj)
      world.monster_behavior.head_attack(actor)
    end

    def bruis_attack(world : World, actor : Mobj)
      world.monster_behavior.bruis_attack(actor)
    end

    def skull_attack(world : World, actor : Mobj)
      world.monster_behavior.skull_attack(actor)
    end

    def metal(world : World, actor : Mobj)
      world.monster_behavior.metal(actor)
    end

    def spid_refire(world : World, actor : Mobj)
      world.monster_behavior.spid_refire(actor)
    end

    def baby_metal(world : World, actor : Mobj)
      world.monster_behavior.baby_metal(actor)
    end

    def bspi_attack(world : World, actor : Mobj)
      world.monster_behavior.bspi_attack(actor)
    end

    def hoof(world : World, actor : Mobj)
      world.monster_behavior.hoof(actor)
    end

    def cyber_attack(world : World, actor : Mobj)
      world.monster_behavior.cyber_attack(actor)
    end

    def pain_attack(world : World, actor : Mobj)
      world.monster_behavior.pain_attack(actor)
    end

    def pain_die(world : World, actor : Mobj)
      world.monster_behavior.pain_die(actor)
    end

    def keen_die(world : World, actor : Mobj)
      world.monster_behavior.keen_die(actor)
    end

    def brain_pain(world : World, actor : Mobj)
      world.monster_behavior.brain_pain(actor)
    end

    def brain_scream(world : World, actor : Mobj)
      world.monster_behavior.brain_scream(actor)
    end

    def brain_die(world : World, actor : Mobj)
      world.monster_behavior.brain_die(actor)
    end

    def brain_awake(world : World, actor : Mobj)
      world.monster_behavior.brain_awake(actor)
    end

    def brain_spit(world : World, actor : Mobj)
      world.monster_behavior.brain_spit(actor)
    end

    def spawn_sound(world : World, actor : Mobj)
      world.monster_behavior.spawn_sound(actor)
    end

    def spawn_fly(world : World, actor : Mobj)
      world.monster_behavior.spawn_fly(actor)
    end

    def brain_explode(world : World, actor : Mobj)
      world.monster_behavior.brain_explode(actor)
    end
  end
end
