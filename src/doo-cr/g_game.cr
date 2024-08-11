# Main Game Functions

module Doocr
  @@gameaction : GameAction = GameAction::Nothing
  @@usergame : Bool = false # ok to save / end game
  @@demobuffer : WAD::Demo = WAD::Demo.new
  @@maxdemostates : UInt32 = 0
  @@demorecording : Bool = false

  @@defdemoname : String = ""

  @@timingdemo : Bool = false
  @@nodrawers : Bool = false
  @@noblit : Bool = false

  @@paused : Bool = false

  @@respawnmonsters : Bool = false

  @@gameepisode : Int32 = 0
  @@gamemap : Int32 = 0
  @@gameskill : Skill = Skill::Medium

  @@viewactive : Bool = false

  def self.g_record_demo(name : String)
    @@usergame = false
    name = name + ".lmp"
    maxsize = 0x20000
    i = @@argv.index("-maxdemo")
    if i && i < @@argv.size - 1
      maxsize = @@argv[i + 1].to_i*1024
    end
    @@demobuffer = WAD::Demo.new
    @@maxdemostates = ((maxsize - 13)/4).to_u32

    @@demorecording = true
  end

  def self.g_defered_play_demo(name : String)
    @@defdemoname = name
    @@gameaction = GameAction::Playdemo
  end

  def self.g_time_demo(name : String)
    @@nodrawers = @@argv.any?("-nodraw")
    @@noblit = @@argv.any?("noblit")
    @@timingdemo = true
    @@singletics = true

    @@defdemoname = name
    @@gameaction = GameAction::Playdemo
  end

  def self.g_initnew(skill : Skill, episode : Int32, map : Int32)
    if @@paused
      @@paused = false
      s_resume_sound()
    end

    skill = Skill::Nightmare.value if skill > Skill::Nightmare.value

    episode = 1 if episode < 1

    if @@gamemode == GameMode::Retail
      episode = 4 if episode > 4
    elsif @@gamemode == GameMode::Shareware
      episode = 1 if episode > 1
    else
      episode = 3 if episode > 3
    end

    map = 1 if map < 1

    map = 9 if map > 9 && @@gamemode != GameMode::Commercial

    m_clear_random()

    if skill == Skill::Nightmare.value || @@respawnparm
      @@respawnmonsters = true
    else
      @@respawnmonsters = false
    end

    if @@fastparm || (skill == Skill::Nightmare.value && @@gameskill != Skill::Nightmare)
      i = Statenum::SARG_RUN1.value
      while i <= Statenum::SARG_PAIN2.value
        @@states[i].tics = @@states[i].tics >> 1
        i += 1
      end
      @@mobjinfo[Mobjtype::BRUISERSHOT.value].speed = 20*FRACUNIT
      @@mobjinfo[Mobjtype::HEADSHOT.value].speed = 20*FRACUNIT
      @@mobjinfo[Mobjtype::TROOPSHOT.value].speed = 20*FRACUNIT
    elsif skill != Skill::Nightmare.value && @@gameskill == Skill::Nightmare
      i = Statenum::SARG_RUN1.value
      while i <= Statenum::SARG_PAIN2.value
        @@states[i].tics = @@states[i].tics << 1
        i += 1
      end
      @@mobjinfo[Mobjtype::BRUISERSHOT.value].speed = 15*FRACUNIT
      @@mobjinfo[Mobjtype::HEADSHOT.value].speed = 10*FRACUNIT
      @@mobjinfo[Mobjtype::TROOPSHOT.value].speed = 10*FRACUNIT
    end

    # force players to be initialized upon first level load
    MAXPLAYERS.times do |i|
      @@players[i].playerstate = Playerstate::REBORN
    end

    @@usergame = true
    @@paused = false
    @@demoplayback = false
    @@automapactive = false
    @@viewactive = true
    @@gameepisode = episode
    @@gamemap = map
    @@gameskill = skill

    @@viewactive - true

    # set the sky map for the episode
    if @@gamemode == GameMode::Commercial
      @@skytexture == 
  end
end
