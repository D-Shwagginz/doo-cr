# Thing frame/state LUT

module Doocr
  struct Mobjinfo
    property doomednum : Int32
    property spawnstate : Int32
    property spawnhealth : Int32
    property seestate : Int32
    property seesound : Int32
    property reactiontime : Int32
    property attacksound : Int32
    property painstate : Int32
    property painchance : Int32
    property painsound : Int32
    property meleestate : Int32
    property missilestate : Int32
    property deathstate : Int32
    property xdeathstate : Int32
    property deathsound : Int32
    property speed : Int32
    property radius : Int32
    property height : Int32
    property mass : Int32
    property damage : Int32
    property activesound : Int32
    property flags : Int32
    property raisestate : Int32

    def initialize(
      doomednum,
      spawnstate,
      spawnhealth,
      seestate,
      seesound,
      reactiontime,
      attacksound,
      painstate,
      painchance,
      painsound,
      meleestate,
      missilestate,
      deathstate,
      xdeathstate,
      deathsound,
      speed,
      radius,
      height,
      mass,
      damage,
      activesound,
      flags,
      raisestate
    )
      if doomednum.is_a?(Enum)
        @doomednum = doomednum.as(Enum).value
      else
        @doomednum = doomednum.as(Int32)
      end

      if spawnstate.is_a?(Enum)
        @spawnstate = spawnstate.as(Enum).value
      else
        @spawnstate = spawnstate.as(Int32)
      end

      if spawnhealth.is_a?(Enum)
        @spawnhealth = spawnhealth.as(Enum).value
      else
        @spawnhealth = spawnhealth.as(Int32)
      end

      if seestate.is_a?(Enum)
        @seestate = seestate.as(Enum).value
      else
        @seestate = seestate.as(Int32)
      end

      if seesound.is_a?(Enum)
        @seesound = seesound.as(Enum).value
      else
        @seesound = seesound.as(Int32)
      end

      if reactiontime.is_a?(Enum)
        @reactiontime = reactiontime.as(Enum).value
      else
        @reactiontime = reactiontime.as(Int32)
      end

      if attacksound.is_a?(Enum)
        @attacksound = attacksound.as(Enum).value
      else
        @attacksound = attacksound.as(Int32)
      end

      if painstate.is_a?(Enum)
        @painstate = painstate.as(Enum).value
      else
        @painstate = painstate.as(Int32)
      end

      if painchance.is_a?(Enum)
        @painchance = painchance.as(Enum).value
      else
        @painchance = painchance.as(Int32)
      end

      if painsound.is_a?(Enum)
        @painsound = painsound.as(Enum).value
      else
        @painsound = painsound.as(Int32)
      end

      if meleestate.is_a?(Enum)
        @meleestate = meleestate.as(Enum).value
      else
        @meleestate = meleestate.as(Int32)
      end

      if missilestate.is_a?(Enum)
        @missilestate = missilestate.as(Enum).value
      else
        @missilestate = missilestate.as(Int32)
      end

      if deathstate.is_a?(Enum)
        @deathstate = deathstate.as(Enum).value
      else
        @deathstate = deathstate.as(Int32)
      end

      if xdeathstate.is_a?(Enum)
        @xdeathstate = xdeathstate.as(Enum).value
      else
        @xdeathstate = xdeathstate.as(Int32)
      end

      if deathsound.is_a?(Enum)
        @deathsound = deathsound.as(Enum).value
      else
        @deathsound = deathsound.as(Int32)
      end

      if speed.is_a?(Enum)
        @speed = speed.as(Enum).value
      else
        @speed = speed.as(Int32)
      end

      if radius.is_a?(Enum)
        @radius = radius.as(Enum).value
      else
        @radius = radius.as(Int32)
      end

      if height.is_a?(Enum)
        @height = height.as(Enum).value
      else
        @height = height.as(Int32)
      end

      if mass.is_a?(Enum)
        @mass = mass.as(Enum).value
      else
        @mass = mass.as(Int32)
      end

      if damage.is_a?(Enum)
        @damage = damage.as(Enum).value
      else
        @damage = damage.as(Int32)
      end

      if activesound.is_a?(Enum)
        @activesound = activesound.as(Enum).value
      else
        @activesound = activesound.as(Int32)
      end

      if flags.is_a?(Enum)
        @flags = flags.as(Enum).value
      else
        @flags = flags.as(Int32)
      end

      if raisestate.is_a?(Enum)
        @raisestate = raisestate.as(Enum).value
      else
        @raisestate = raisestate.as(Int32)
      end
    end
  end

  struct State
    property sprite : Spritenum
    property frame : Int32
    property tics : Int32
    property action : Actionf
    property nextstate : Statenum
    property misc1 : Int32
    property misc2 : Int32

    def initialize(@sprite, @frame, @tics, @action, @nextstate, @misc1, @misc2)
    end
  end

  @@mobjinfo : Array(Mobjinfo) = [
    Mobjinfo.new(                                                                                         # # MT_PLAYER
-1,                                                                                                       # # doomednum
      Statenum::PLAY,                                                                                     # # spawnstate
      100,                                                                                                # # spawnhealth
      Statenum::PLAY_RUN1,                                                                                # # seestate
      SFX::None,                                                                                          # # seesound
      0,                                                                                                  # # reactiontime
      SFX::None,                                                                                          # # attacksound
      Statenum::PLAY_PAIN,                                                                                # # painstate
      255,                                                                                                # # painchance
      SFX::Plpain,                                                                                        # # painsound
      Statenum::NULL,                                                                                     # # meleestate
      Statenum::PLAY_ATK1,                                                                                # # missilestate
      Statenum::PLAY_DIE1,                                                                                # # deathstate
      Statenum::PLAY_XDIE1,                                                                               # # xdeathstate
      SFX::Pldeth,                                                                                        # # deathsound
      0,                                                                                                  # # speed
      16*FRACUNIT,                                                                                        # # radius
      56*FRACUNIT,                                                                                        # # height
      100,                                                                                                # # mass
      0,                                                                                                  # # damage
      SFX::None,                                                                                          # # activesound
      Mobjflag::SOLID | Mobjflag::SHOOTABLE | Mobjflag::DROPOFF | Mobjflag::PICKUP | Mobjflag::NOTDMATCH, # # flags
      Statenum::NULL,                                                                                     # # raisestate
),

    Mobjinfo.new(                                                  # # MT_POSSESSED
3004,                                                              # # doomednum
      Statenum::POSS_STND,                                         # # spawnstate
      20,                                                          # # spawnhealth
      Statenum::POSS_RUN1,                                         # # seestate
      SFX::Posit1,                                                 # # seesound
      8,                                                           # # reactiontime
      SFX::Pistol,                                                 # # attacksound
      Statenum::POSS_PAIN,                                         # # painstate
      200,                                                         # # painchance
      SFX::Popain,                                                 # # painsound
      0,                                                           # # meleestate
      Statenum::POSS_ATK1,                                         # # missilestate
      Statenum::POSS_DIE1,                                         # # deathstate
      Statenum::POSS_XDIE1,                                        # # xdeathstate
      SFX::Podth1,                                                 # # deathsound
      8,                                                           # # speed
      20*FRACUNIT,                                                 # # radius
      56*FRACUNIT,                                                 # # height
      100,                                                         # # mass
      0,                                                           # # damage
      SFX::Posact,                                                 # # activesound
      Mobjflag::SOLID | Mobjflag::SHOOTABLE | Mobjflag::COUNTKILL, # # flags
      Statenum::POSS_RAISE1,                                       # # raisestate
),

    Mobjinfo.new(                                                  # # MT_SHOTGUY
9,                                                                 # # doomednum
      Statenum::SPOS_STND,                                         # # spawnstate
      30,                                                          # # spawnhealth
      Statenum::SPOS_RUN1,                                         # # seestate
      SFX::Posit2,                                                 # # seesound
      8,                                                           # # reactiontime
      0,                                                           # # attacksound
      Statenum::SPOS_PAIN,                                         # # painstate
      170,                                                         # # painchance
      SFX::Popain,                                                 # # painsound
      0,                                                           # # meleestate
      Statenum::SPOS_ATK1,                                         # # missilestate
      Statenum::SPOS_DIE1,                                         # # deathstate
      Statenum::SPOS_XDIE1,                                        # # xdeathstate
      SFX::Podth2,                                                 # # deathsound
      8,                                                           # # speed
      20*FRACUNIT,                                                 # # radius
      56*FRACUNIT,                                                 # # height
      100,                                                         # # mass
      0,                                                           # # damage
      SFX::Posact,                                                 # # activesound
      Mobjflag::SOLID | Mobjflag::SHOOTABLE | Mobjflag::COUNTKILL, # # flags
      Statenum::SPOS_RAISE1,                                       # # raisestate
),

    Mobjinfo.new(                                                  # # MT_VILE
64,                                                                # # doomednum
      Statenum::VILE_STND,                                         # # spawnstate
      700,                                                         # # spawnhealth
      Statenum::VILE_RUN1,                                         # # seestate
      SFX::Vilsit,                                                 # # seesound
      8,                                                           # # reactiontime
      0,                                                           # # attacksound
      Statenum::VILE_PAIN,                                         # # painstate
      10,                                                          # # painchance
      SFX::Vipain,                                                 # # painsound
      0,                                                           # # meleestate
      Statenum::VILE_ATK1,                                         # # missilestate
      Statenum::VILE_DIE1,                                         # # deathstate
      Statenum::NULL,                                              # # xdeathstate
      SFX::Vildth,                                                 # # deathsound
      15,                                                          # # speed
      20*FRACUNIT,                                                 # # radius
      56*FRACUNIT,                                                 # # height
      500,                                                         # # mass
      0,                                                           # # damage
      SFX::Vilact,                                                 # # activesound
      Mobjflag::SOLID | Mobjflag::SHOOTABLE | Mobjflag::COUNTKILL, # # flags
      Statenum::NULL,                                              # # raisestate
),

    Mobjinfo.new(                                 # # MT_FIRE
-1,                                               # # doomednum
      Statenum::FIRE1,                            # # spawnstate
      1000,                                       # # spawnhealth
      Statenum::NULL,                             # # seestate
      SFX::None,                                  # # seesound
      8,                                          # # reactiontime
      SFX::None,                                  # # attacksound
      Statenum::NULL,                             # # painstate
      0,                                          # # painchance
      SFX::None,                                  # # painsound
      Statenum::NULL,                             # # meleestate
      Statenum::NULL,                             # # missilestate
      Statenum::NULL,                             # # deathstate
      Statenum::NULL,                             # # xdeathstate
      SFX::None,                                  # # deathsound
      0,                                          # # speed
      20*FRACUNIT,                                # # radius
      16*FRACUNIT,                                # # height
      100,                                        # # mass
      0,                                          # # damage
      SFX::None,                                  # # activesound
      Mobjflag::NOBLOCKMAP | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                             # # raisestate
),

    Mobjinfo.new(                                                  # # MT_UNDEAD
66,                                                                # # doomednum
      Statenum::SKEL_STND,                                         # # spawnstate
      300,                                                         # # spawnhealth
      Statenum::SKEL_RUN1,                                         # # seestate
      SFX::Skesit,                                                 # # seesound
      8,                                                           # # reactiontime
      0,                                                           # # attacksound
      Statenum::SKEL_PAIN,                                         # # painstate
      100,                                                         # # painchance
      SFX::Popain,                                                 # # painsound
      Statenum::SKEL_FIST1,                                        # # meleestate
      Statenum::SKEL_MISS1,                                        # # missilestate
      Statenum::SKEL_DIE1,                                         # # deathstate
      Statenum::NULL,                                              # # xdeathstate
      SFX::Skedth,                                                 # # deathsound
      10,                                                          # # speed
      20*FRACUNIT,                                                 # # radius
      56*FRACUNIT,                                                 # # height
      500,                                                         # # mass
      0,                                                           # # damage
      SFX::Skeact,                                                 # # activesound
      Mobjflag::SOLID | Mobjflag::SHOOTABLE | Mobjflag::COUNTKILL, # # flags
      Statenum::SKEL_RAISE1,                                       # # raisestate
),

    Mobjinfo.new(                                                                         # # MT_TRACER
-1,                                                                                       # # doomednum
      Statenum::TRACER,                                                                   # # spawnstate
      1000,                                                                               # # spawnhealth
      Statenum::NULL,                                                                     # # seestate
      SFX::Skeatk,                                                                        # # seesound
      8,                                                                                  # # reactiontime
      SFX::None,                                                                          # # attacksound
      Statenum::NULL,                                                                     # # painstate
      0,                                                                                  # # painchance
      SFX::None,                                                                          # # painsound
      Statenum::NULL,                                                                     # # meleestate
      Statenum::NULL,                                                                     # # missilestate
      Statenum::TRACEEXP1,                                                                # # deathstate
      Statenum::NULL,                                                                     # # xdeathstate
      SFX::Barexp,                                                                        # # deathsound
      10*FRACUNIT,                                                                        # # speed
      11*FRACUNIT,                                                                        # # radius
      8*FRACUNIT,                                                                         # # height
      100,                                                                                # # mass
      10,                                                                                 # # damage
      SFX::None,                                                                          # # activesound
      Mobjflag::NOBLOCKMAP | Mobjflag::MISSILE | Mobjflag::DROPOFF | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                                                                     # # raisestate
),

    Mobjinfo.new(                                 # # MT_SMOKE
-1,                                               # # doomednum
      Statenum::SMOKE1,                           # # spawnstate
      1000,                                       # # spawnhealth
      Statenum::NULL,                             # # seestate
      SFX::None,                                  # # seesound
      8,                                          # # reactiontime
      SFX::None,                                  # # attacksound
      Statenum::NULL,                             # # painstate
      0,                                          # # painchance
      SFX::None,                                  # # painsound
      Statenum::NULL,                             # # meleestate
      Statenum::NULL,                             # # missilestate
      Statenum::NULL,                             # # deathstate
      Statenum::NULL,                             # # xdeathstate
      SFX::None,                                  # # deathsound
      0,                                          # # speed
      20*FRACUNIT,                                # # radius
      16*FRACUNIT,                                # # height
      100,                                        # # mass
      0,                                          # # damage
      SFX::None,                                  # # activesound
      Mobjflag::NOBLOCKMAP | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                             # # raisestate
),

    Mobjinfo.new(                                                  # # MT_FATSO
67,                                                                # # doomednum
      Statenum::FATT_STND,                                         # # spawnstate
      600,                                                         # # spawnhealth
      Statenum::FATT_RUN1,                                         # # seestate
      SFX::Mansit,                                                 # # seesound
      8,                                                           # # reactiontime
      0,                                                           # # attacksound
      Statenum::FATT_PAIN,                                         # # painstate
      80,                                                          # # painchance
      SFX::Mnpain,                                                 # # painsound
      0,                                                           # # meleestate
      Statenum::FATT_ATK1,                                         # # missilestate
      Statenum::FATT_DIE1,                                         # # deathstate
      Statenum::NULL,                                              # # xdeathstate
      SFX::Mandth,                                                 # # deathsound
      8,                                                           # # speed
      48*FRACUNIT,                                                 # # radius
      64*FRACUNIT,                                                 # # height
      1000,                                                        # # mass
      0,                                                           # # damage
      SFX::Posact,                                                 # # activesound
      Mobjflag::SOLID | Mobjflag::SHOOTABLE | Mobjflag::COUNTKILL, # # flags
      Statenum::FATT_RAISE1,                                       # # raisestate
),

    Mobjinfo.new(                                                                         # # MT_FATSHOT
-1,                                                                                       # # doomednum
      Statenum::FATSHOT1,                                                                 # # spawnstate
      1000,                                                                               # # spawnhealth
      Statenum::NULL,                                                                     # # seestate
      SFX::Firsht,                                                                        # # seesound
      8,                                                                                  # # reactiontime
      SFX::None,                                                                          # # attacksound
      Statenum::NULL,                                                                     # # painstate
      0,                                                                                  # # painchance
      SFX::None,                                                                          # # painsound
      Statenum::NULL,                                                                     # # meleestate
      Statenum::NULL,                                                                     # # missilestate
      Statenum::FATSHOTX1,                                                                # # deathstate
      Statenum::NULL,                                                                     # # xdeathstate
      SFX::Firxpl,                                                                        # # deathsound
      20*FRACUNIT,                                                                        # # speed
      6*FRACUNIT,                                                                         # # radius
      8*FRACUNIT,                                                                         # # height
      100,                                                                                # # mass
      8,                                                                                  # # damage
      SFX::None,                                                                          # # activesound
      Mobjflag::NOBLOCKMAP | Mobjflag::MISSILE | Mobjflag::DROPOFF | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                                                                     # # raisestate
),

    Mobjinfo.new(                                                  # # MT_CHAINGUY
65,                                                                # # doomednum
      Statenum::CPOS_STND,                                         # # spawnstate
      70,                                                          # # spawnhealth
      Statenum::CPOS_RUN1,                                         # # seestate
      SFX::Posit2,                                                 # # seesound
      8,                                                           # # reactiontime
      0,                                                           # # attacksound
      Statenum::CPOS_PAIN,                                         # # painstate
      170,                                                         # # painchance
      SFX::Popain,                                                 # # painsound
      0,                                                           # # meleestate
      Statenum::CPOS_ATK1,                                         # # missilestate
      Statenum::CPOS_DIE1,                                         # # deathstate
      Statenum::CPOS_XDIE1,                                        # # xdeathstate
      SFX::Podth2,                                                 # # deathsound
      8,                                                           # # speed
      20*FRACUNIT,                                                 # # radius
      56*FRACUNIT,                                                 # # height
      100,                                                         # # mass
      0,                                                           # # damage
      SFX::Posact,                                                 # # activesound
      Mobjflag::SOLID | Mobjflag::SHOOTABLE | Mobjflag::COUNTKILL, # # flags
      Statenum::CPOS_RAISE1,                                       # # raisestate
),

    Mobjinfo.new(                                                  # # MT_TROOP
3001,                                                              # # doomednum
      Statenum::TROO_STND,                                         # # spawnstate
      60,                                                          # # spawnhealth
      Statenum::TROO_RUN1,                                         # # seestate
      SFX::Bgsit1,                                                 # # seesound
      8,                                                           # # reactiontime
      0,                                                           # # attacksound
      Statenum::TROO_PAIN,                                         # # painstate
      200,                                                         # # painchance
      SFX::Popain,                                                 # # painsound
      Statenum::TROO_ATK1,                                         # # meleestate
      Statenum::TROO_ATK1,                                         # # missilestate
      Statenum::TROO_DIE1,                                         # # deathstate
      Statenum::TROO_XDIE1,                                        # # xdeathstate
      SFX::Bgdth1,                                                 # # deathsound
      8,                                                           # # speed
      20*FRACUNIT,                                                 # # radius
      56*FRACUNIT,                                                 # # height
      100,                                                         # # mass
      0,                                                           # # damage
      SFX::Bgact,                                                  # # activesound
      Mobjflag::SOLID | Mobjflag::SHOOTABLE | Mobjflag::COUNTKILL, # # flags
      Statenum::TROO_RAISE1,                                       # # raisestate
),

    Mobjinfo.new(                                                  # # MT_SERGEANT
3002,                                                              # # doomednum
      Statenum::SARG_STND,                                         # # spawnstate
      150,                                                         # # spawnhealth
      Statenum::SARG_RUN1,                                         # # seestate
      SFX::Sgtsit,                                                 # # seesound
      8,                                                           # # reactiontime
      SFX::Sgtatk,                                                 # # attacksound
      Statenum::SARG_PAIN,                                         # # painstate
      180,                                                         # # painchance
      SFX::Dmpain,                                                 # # painsound
      Statenum::SARG_ATK1,                                         # # meleestate
      0,                                                           # # missilestate
      Statenum::SARG_DIE1,                                         # # deathstate
      Statenum::NULL,                                              # # xdeathstate
      SFX::Sgtdth,                                                 # # deathsound
      10,                                                          # # speed
      30*FRACUNIT,                                                 # # radius
      56*FRACUNIT,                                                 # # height
      400,                                                         # # mass
      0,                                                           # # damage
      SFX::Dmact,                                                  # # activesound
      Mobjflag::SOLID | Mobjflag::SHOOTABLE | Mobjflag::COUNTKILL, # # flags
      Statenum::SARG_RAISE1,                                       # # raisestate
),

    Mobjinfo.new(                                                                     # # MT_SHADOWS
58,                                                                                   # # doomednum
      Statenum::SARG_STND,                                                            # # spawnstate
      150,                                                                            # # spawnhealth
      Statenum::SARG_RUN1,                                                            # # seestate
      SFX::Sgtsit,                                                                    # # seesound
      8,                                                                              # # reactiontime
      SFX::Sgtatk,                                                                    # # attacksound
      Statenum::SARG_PAIN,                                                            # # painstate
      180,                                                                            # # painchance
      SFX::Dmpain,                                                                    # # painsound
      Statenum::SARG_ATK1,                                                            # # meleestate
      0,                                                                              # # missilestate
      Statenum::SARG_DIE1,                                                            # # deathstate
      Statenum::NULL,                                                                 # # xdeathstate
      SFX::Sgtdth,                                                                    # # deathsound
      10,                                                                             # # speed
      30*FRACUNIT,                                                                    # # radius
      56*FRACUNIT,                                                                    # # height
      400,                                                                            # # mass
      0,                                                                              # # damage
      SFX::Dmact,                                                                     # # activesound
      Mobjflag::SOLID | Mobjflag::SHOOTABLE | Mobjflag::SHADOW | Mobjflag::COUNTKILL, # # flags
      Statenum::SARG_RAISE1,                                                          # # raisestate
),

    Mobjinfo.new(                                                                                          # # MT_HEAD
3005,                                                                                                      # # doomednum
      Statenum::HEAD_STND,                                                                                 # # spawnstate
      400,                                                                                                 # # spawnhealth
      Statenum::HEAD_RUN1,                                                                                 # # seestate
      SFX::Cacsit,                                                                                         # # seesound
      8,                                                                                                   # # reactiontime
      0,                                                                                                   # # attacksound
      Statenum::HEAD_PAIN,                                                                                 # # painstate
      128,                                                                                                 # # painchance
      SFX::Dmpain,                                                                                         # # painsound
      0,                                                                                                   # # meleestate
      Statenum::HEAD_ATK1,                                                                                 # # missilestate
      Statenum::HEAD_DIE1,                                                                                 # # deathstate
      Statenum::NULL,                                                                                      # # xdeathstate
      SFX::Cacdth,                                                                                         # # deathsound
      8,                                                                                                   # # speed
      31*FRACUNIT,                                                                                         # # radius
      56*FRACUNIT,                                                                                         # # height
      400,                                                                                                 # # mass
      0,                                                                                                   # # damage
      SFX::Dmact,                                                                                          # # activesound
      Mobjflag::SOLID | Mobjflag::SHOOTABLE | Mobjflag::FLOAT | Mobjflag::NOGRAVITY | Mobjflag::COUNTKILL, # # flags
      Statenum::HEAD_RAISE1,                                                                               # # raisestate
),

    Mobjinfo.new(                                                  # # MT_BRUISER
3003,                                                              # # doomednum
      Statenum::BOSS_STND,                                         # # spawnstate
      1000,                                                        # # spawnhealth
      Statenum::BOSS_RUN1,                                         # # seestate
      SFX::Brssit,                                                 # # seesound
      8,                                                           # # reactiontime
      0,                                                           # # attacksound
      Statenum::BOSS_PAIN,                                         # # painstate
      50,                                                          # # painchance
      SFX::Dmpain,                                                 # # painsound
      Statenum::BOSS_ATK1,                                         # # meleestate
      Statenum::BOSS_ATK1,                                         # # missilestate
      Statenum::BOSS_DIE1,                                         # # deathstate
      Statenum::NULL,                                              # # xdeathstate
      SFX::Brsdth,                                                 # # deathsound
      8,                                                           # # speed
      24*FRACUNIT,                                                 # # radius
      64*FRACUNIT,                                                 # # height
      1000,                                                        # # mass
      0,                                                           # # damage
      SFX::Dmact,                                                  # # activesound
      Mobjflag::SOLID | Mobjflag::SHOOTABLE | Mobjflag::COUNTKILL, # # flags
      Statenum::BOSS_RAISE1,                                       # # raisestate
),

    Mobjinfo.new(                                                                         # # MT_BRUISERSHOT
-1,                                                                                       # # doomednum
      Statenum::BRBALL1,                                                                  # # spawnstate
      1000,                                                                               # # spawnhealth
      Statenum::NULL,                                                                     # # seestate
      SFX::Firsht,                                                                        # # seesound
      8,                                                                                  # # reactiontime
      SFX::None,                                                                          # # attacksound
      Statenum::NULL,                                                                     # # painstate
      0,                                                                                  # # painchance
      SFX::None,                                                                          # # painsound
      Statenum::NULL,                                                                     # # meleestate
      Statenum::NULL,                                                                     # # missilestate
      Statenum::BRBALLX1,                                                                 # # deathstate
      Statenum::NULL,                                                                     # # xdeathstate
      SFX::Firxpl,                                                                        # # deathsound
      15*FRACUNIT,                                                                        # # speed
      6*FRACUNIT,                                                                         # # radius
      8*FRACUNIT,                                                                         # # height
      100,                                                                                # # mass
      8,                                                                                  # # damage
      SFX::None,                                                                          # # activesound
      Mobjflag::NOBLOCKMAP | Mobjflag::MISSILE | Mobjflag::DROPOFF | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                                                                     # # raisestate
),

    Mobjinfo.new(                                                  # # MT_KNIGHT
69,                                                                # # doomednum
      Statenum::BOS2_STND,                                         # # spawnstate
      500,                                                         # # spawnhealth
      Statenum::BOS2_RUN1,                                         # # seestate
      SFX::Kntsit,                                                 # # seesound
      8,                                                           # # reactiontime
      0,                                                           # # attacksound
      Statenum::BOS2_PAIN,                                         # # painstate
      50,                                                          # # painchance
      SFX::Dmpain,                                                 # # painsound
      Statenum::BOS2_ATK1,                                         # # meleestate
      Statenum::BOS2_ATK1,                                         # # missilestate
      Statenum::BOS2_DIE1,                                         # # deathstate
      Statenum::NULL,                                              # # xdeathstate
      SFX::Kntdth,                                                 # # deathsound
      8,                                                           # # speed
      24*FRACUNIT,                                                 # # radius
      64*FRACUNIT,                                                 # # height
      1000,                                                        # # mass
      0,                                                           # # damage
      SFX::Dmact,                                                  # # activesound
      Mobjflag::SOLID | Mobjflag::SHOOTABLE | Mobjflag::COUNTKILL, # # flags
      Statenum::BOS2_RAISE1,                                       # # raisestate
),

    Mobjinfo.new(                                                                    # # MT_SKULL
3006,                                                                                # # doomednum
      Statenum::SKULL_STND,                                                          # # spawnstate
      100,                                                                           # # spawnhealth
      Statenum::SKULL_RUN1,                                                          # # seestate
      0,                                                                             # # seesound
      8,                                                                             # # reactiontime
      SFX::Sklatk,                                                                   # # attacksound
      Statenum::SKULL_PAIN,                                                          # # painstate
      256,                                                                           # # painchance
      SFX::Dmpain,                                                                   # # painsound
      0,                                                                             # # meleestate
      Statenum::SKULL_ATK1,                                                          # # missilestate
      Statenum::SKULL_DIE1,                                                          # # deathstate
      Statenum::NULL,                                                                # # xdeathstate
      SFX::Firxpl,                                                                   # # deathsound
      8,                                                                             # # speed
      16*FRACUNIT,                                                                   # # radius
      56*FRACUNIT,                                                                   # # height
      50,                                                                            # # mass
      3,                                                                             # # damage
      SFX::Dmact,                                                                    # # activesound
      Mobjflag::SOLID | Mobjflag::SHOOTABLE | Mobjflag::FLOAT | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                                                                # # raisestate
),

    Mobjinfo.new(                                                  # # MT_SPIDER
7,                                                                 # # doomednum
      Statenum::SPID_STND,                                         # # spawnstate
      3000,                                                        # # spawnhealth
      Statenum::SPID_RUN1,                                         # # seestate
      SFX::Spisit,                                                 # # seesound
      8,                                                           # # reactiontime
      SFX::Shotgn,                                                 # # attacksound
      Statenum::SPID_PAIN,                                         # # painstate
      40,                                                          # # painchance
      SFX::Dmpain,                                                 # # painsound
      0,                                                           # # meleestate
      Statenum::SPID_ATK1,                                         # # missilestate
      Statenum::SPID_DIE1,                                         # # deathstate
      Statenum::NULL,                                              # # xdeathstate
      SFX::Spidth,                                                 # # deathsound
      12,                                                          # # speed
      128*FRACUNIT,                                                # # radius
      100*FRACUNIT,                                                # # height
      1000,                                                        # # mass
      0,                                                           # # damage
      SFX::Dmact,                                                  # # activesound
      Mobjflag::SOLID | Mobjflag::SHOOTABLE | Mobjflag::COUNTKILL, # # flags
      Statenum::NULL,                                              # # raisestate
),

    Mobjinfo.new(                                                  # # MT_BABY
68,                                                                # # doomednum
      Statenum::BSPI_STND,                                         # # spawnstate
      500,                                                         # # spawnhealth
      Statenum::BSPI_SIGHT,                                        # # seestate
      SFX::Bspsit,                                                 # # seesound
      8,                                                           # # reactiontime
      0,                                                           # # attacksound
      Statenum::BSPI_PAIN,                                         # # painstate
      128,                                                         # # painchance
      SFX::Dmpain,                                                 # # painsound
      0,                                                           # # meleestate
      Statenum::BSPI_ATK1,                                         # # missilestate
      Statenum::BSPI_DIE1,                                         # # deathstate
      Statenum::NULL,                                              # # xdeathstate
      SFX::Bspdth,                                                 # # deathsound
      12,                                                          # # speed
      64*FRACUNIT,                                                 # # radius
      64*FRACUNIT,                                                 # # height
      600,                                                         # # mass
      0,                                                           # # damage
      SFX::Bspact,                                                 # # activesound
      Mobjflag::SOLID | Mobjflag::SHOOTABLE | Mobjflag::COUNTKILL, # # flags
      Statenum::BSPI_RAISE1,                                       # # raisestate
),

    Mobjinfo.new(                                                  # # MT_CYBORG
16,                                                                # # doomednum
      Statenum::CYBER_STND,                                        # # spawnstate
      4000,                                                        # # spawnhealth
      Statenum::CYBER_RUN1,                                        # # seestate
      SFX::Cybsit,                                                 # # seesound
      8,                                                           # # reactiontime
      0,                                                           # # attacksound
      Statenum::CYBER_PAIN,                                        # # painstate
      20,                                                          # # painchance
      SFX::Dmpain,                                                 # # painsound
      0,                                                           # # meleestate
      Statenum::CYBER_ATK1,                                        # # missilestate
      Statenum::CYBER_DIE1,                                        # # deathstate
      Statenum::NULL,                                              # # xdeathstate
      SFX::Cybdth,                                                 # # deathsound
      16,                                                          # # speed
      40*FRACUNIT,                                                 # # radius
      110*FRACUNIT,                                                # # height
      1000,                                                        # # mass
      0,                                                           # # damage
      SFX::Dmact,                                                  # # activesound
      Mobjflag::SOLID | Mobjflag::SHOOTABLE | Mobjflag::COUNTKILL, # # flags
      Statenum::NULL,                                              # # raisestate
),

    Mobjinfo.new(                                                                                          # # MT_PAIN
71,                                                                                                        # # doomednum
      Statenum::PAIN_STND,                                                                                 # # spawnstate
      400,                                                                                                 # # spawnhealth
      Statenum::PAIN_RUN1,                                                                                 # # seestate
      SFX::Pesit,                                                                                          # # seesound
      8,                                                                                                   # # reactiontime
      0,                                                                                                   # # attacksound
      Statenum::PAIN_PAIN,                                                                                 # # painstate
      128,                                                                                                 # # painchance
      SFX::Pepain,                                                                                         # # painsound
      0,                                                                                                   # # meleestate
      Statenum::PAIN_ATK1,                                                                                 # # missilestate
      Statenum::PAIN_DIE1,                                                                                 # # deathstate
      Statenum::NULL,                                                                                      # # xdeathstate
      SFX::Pedth,                                                                                          # # deathsound
      8,                                                                                                   # # speed
      31*FRACUNIT,                                                                                         # # radius
      56*FRACUNIT,                                                                                         # # height
      400,                                                                                                 # # mass
      0,                                                                                                   # # damage
      SFX::Dmact,                                                                                          # # activesound
      Mobjflag::SOLID | Mobjflag::SHOOTABLE | Mobjflag::FLOAT | Mobjflag::NOGRAVITY | Mobjflag::COUNTKILL, # # flags
      Statenum::PAIN_RAISE1,                                                                               # # raisestate
),

    Mobjinfo.new(                                                  # # MT_WOLFSS
84,                                                                # # doomednum
      Statenum::SSWV_STND,                                         # # spawnstate
      50,                                                          # # spawnhealth
      Statenum::SSWV_RUN1,                                         # # seestate
      SFX::Sssit,                                                  # # seesound
      8,                                                           # # reactiontime
      0,                                                           # # attacksound
      Statenum::SSWV_PAIN,                                         # # painstate
      170,                                                         # # painchance
      SFX::Popain,                                                 # # painsound
      0,                                                           # # meleestate
      Statenum::SSWV_ATK1,                                         # # missilestate
      Statenum::SSWV_DIE1,                                         # # deathstate
      Statenum::SSWV_XDIE1,                                        # # xdeathstate
      SFX::Ssdth,                                                  # # deathsound
      8,                                                           # # speed
      20*FRACUNIT,                                                 # # radius
      56*FRACUNIT,                                                 # # height
      100,                                                         # # mass
      0,                                                           # # damage
      SFX::Posact,                                                 # # activesound
      Mobjflag::SOLID | Mobjflag::SHOOTABLE | Mobjflag::COUNTKILL, # # flags
      Statenum::SSWV_RAISE1,                                       # # raisestate
),

    Mobjinfo.new(                                                                                                 # # MT_KEEN
72,                                                                                                               # # doomednum
      Statenum::KEENSTND,                                                                                         # # spawnstate
      100,                                                                                                        # # spawnhealth
      Statenum::NULL,                                                                                             # # seestate
      SFX::None,                                                                                                  # # seesound
      8,                                                                                                          # # reactiontime
      SFX::None,                                                                                                  # # attacksound
      Statenum::KEENPAIN,                                                                                         # # painstate
      256,                                                                                                        # # painchance
      SFX::Keenpn,                                                                                                # # painsound
      Statenum::NULL,                                                                                             # # meleestate
      Statenum::NULL,                                                                                             # # missilestate
      Statenum::COMMKEEN,                                                                                         # # deathstate
      Statenum::NULL,                                                                                             # # xdeathstate
      SFX::Keendt,                                                                                                # # deathsound
      0,                                                                                                          # # speed
      16*FRACUNIT,                                                                                                # # radius
      72*FRACUNIT,                                                                                                # # height
      10000000,                                                                                                   # # mass
      0,                                                                                                          # # damage
      SFX::None,                                                                                                  # # activesound
      Mobjflag::SOLID | Mobjflag::SPAWNCEILING | Mobjflag::NOGRAVITY | Mobjflag::SHOOTABLE | Mobjflag::COUNTKILL, # # flags
      Statenum::NULL,                                                                                             # # raisestate
),

    Mobjinfo.new(                            # # MT_BOSSBRAIN
88,                                          # # doomednum
      Statenum::BRAIN,                       # # spawnstate
      250,                                   # # spawnhealth
      Statenum::NULL,                        # # seestate
      SFX::None,                             # # seesound
      8,                                     # # reactiontime
      SFX::None,                             # # attacksound
      Statenum::BRAIN_PAIN,                  # # painstate
      255,                                   # # painchance
      SFX::Bospn,                            # # painsound
      Statenum::NULL,                        # # meleestate
      Statenum::NULL,                        # # missilestate
      Statenum::BRAIN_DIE1,                  # # deathstate
      Statenum::NULL,                        # # xdeathstate
      SFX::Bosdth,                           # # deathsound
      0,                                     # # speed
      16*FRACUNIT,                           # # radius
      16*FRACUNIT,                           # # height
      10000000,                              # # mass
      0,                                     # # damage
      SFX::None,                             # # activesound
      Mobjflag::SOLID | Mobjflag::SHOOTABLE, # # flags
      Statenum::NULL,                        # # raisestate
),

    Mobjinfo.new(                                # # MT_BOSSSPIT
89,                                              # # doomednum
      Statenum::BRAINEYE,                        # # spawnstate
      1000,                                      # # spawnhealth
      Statenum::BRAINEYESEE,                     # # seestate
      SFX::None,                                 # # seesound
      8,                                         # # reactiontime
      SFX::None,                                 # # attacksound
      Statenum::NULL,                            # # painstate
      0,                                         # # painchance
      SFX::None,                                 # # painsound
      Statenum::NULL,                            # # meleestate
      Statenum::NULL,                            # # missilestate
      Statenum::NULL,                            # # deathstate
      Statenum::NULL,                            # # xdeathstate
      SFX::None,                                 # # deathsound
      0,                                         # # speed
      20*FRACUNIT,                               # # radius
      32*FRACUNIT,                               # # height
      100,                                       # # mass
      0,                                         # # damage
      SFX::None,                                 # # activesound
      Mobjflag::NOBLOCKMAP | Mobjflag::NOSECTOR, # # flags
      Statenum::NULL,                            # # raisestate
),

    Mobjinfo.new(                                # # MT_BOSSTARGET
87,                                              # # doomednum
      Statenum::NULL,                            # # spawnstate
      1000,                                      # # spawnhealth
      Statenum::NULL,                            # # seestate
      SFX::None,                                 # # seesound
      8,                                         # # reactiontime
      SFX::None,                                 # # attacksound
      Statenum::NULL,                            # # painstate
      0,                                         # # painchance
      SFX::None,                                 # # painsound
      Statenum::NULL,                            # # meleestate
      Statenum::NULL,                            # # missilestate
      Statenum::NULL,                            # # deathstate
      Statenum::NULL,                            # # xdeathstate
      SFX::None,                                 # # deathsound
      0,                                         # # speed
      20*FRACUNIT,                               # # radius
      32*FRACUNIT,                               # # height
      100,                                       # # mass
      0,                                         # # damage
      SFX::None,                                 # # activesound
      Mobjflag::NOBLOCKMAP | Mobjflag::NOSECTOR, # # flags
      Statenum::NULL,                            # # raisestate
),

    Mobjinfo.new(                                                                                            # # MT_SPAWNSHOT
-1,                                                                                                          # # doomednum
      Statenum::SPAWN1,                                                                                      # # spawnstate
      1000,                                                                                                  # # spawnhealth
      Statenum::NULL,                                                                                        # # seestate
      SFX::Bospit,                                                                                           # # seesound
      8,                                                                                                     # # reactiontime
      SFX::None,                                                                                             # # attacksound
      Statenum::NULL,                                                                                        # # painstate
      0,                                                                                                     # # painchance
      SFX::None,                                                                                             # # painsound
      Statenum::NULL,                                                                                        # # meleestate
      Statenum::NULL,                                                                                        # # missilestate
      Statenum::NULL,                                                                                        # # deathstate
      Statenum::NULL,                                                                                        # # xdeathstate
      SFX::Firxpl,                                                                                           # # deathsound
      10*FRACUNIT,                                                                                           # # speed
      6*FRACUNIT,                                                                                            # # radius
      32*FRACUNIT,                                                                                           # # height
      100,                                                                                                   # # mass
      3,                                                                                                     # # damage
      SFX::None,                                                                                             # # activesound
      Mobjflag::NOBLOCKMAP | Mobjflag::MISSILE | Mobjflag::DROPOFF | Mobjflag::NOGRAVITY | Mobjflag::NOCLIP, # # flags
      Statenum::NULL,                                                                                        # # raisestate
),

    Mobjinfo.new(                                 # # MT_SPAWNFIRE
-1,                                               # # doomednum
      Statenum::SPAWNFIRE1,                       # # spawnstate
      1000,                                       # # spawnhealth
      Statenum::NULL,                             # # seestate
      SFX::None,                                  # # seesound
      8,                                          # # reactiontime
      SFX::None,                                  # # attacksound
      Statenum::NULL,                             # # painstate
      0,                                          # # painchance
      SFX::None,                                  # # painsound
      Statenum::NULL,                             # # meleestate
      Statenum::NULL,                             # # missilestate
      Statenum::NULL,                             # # deathstate
      Statenum::NULL,                             # # xdeathstate
      SFX::None,                                  # # deathsound
      0,                                          # # speed
      20*FRACUNIT,                                # # radius
      16*FRACUNIT,                                # # height
      100,                                        # # mass
      0,                                          # # damage
      SFX::None,                                  # # activesound
      Mobjflag::NOBLOCKMAP | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                             # # raisestate
),

    Mobjinfo.new(                                                # # MT_BARREL
2035,                                                            # # doomednum
      Statenum::BAR1,                                            # # spawnstate
      20,                                                        # # spawnhealth
      Statenum::NULL,                                            # # seestate
      SFX::None,                                                 # # seesound
      8,                                                         # # reactiontime
      SFX::None,                                                 # # attacksound
      Statenum::NULL,                                            # # painstate
      0,                                                         # # painchance
      SFX::None,                                                 # # painsound
      Statenum::NULL,                                            # # meleestate
      Statenum::NULL,                                            # # missilestate
      Statenum::BEXP,                                            # # deathstate
      Statenum::NULL,                                            # # xdeathstate
      SFX::Barexp,                                               # # deathsound
      0,                                                         # # speed
      10*FRACUNIT,                                               # # radius
      42*FRACUNIT,                                               # # height
      100,                                                       # # mass
      0,                                                         # # damage
      SFX::None,                                                 # # activesound
      Mobjflag::SOLID | Mobjflag::SHOOTABLE | Mobjflag::NOBLOOD, # # flags
      Statenum::NULL,                                            # # raisestate
),

    Mobjinfo.new(                                                                         # # MT_TROOPSHOT
-1,                                                                                       # # doomednum
      Statenum::TBALL1,                                                                   # # spawnstate
      1000,                                                                               # # spawnhealth
      Statenum::NULL,                                                                     # # seestate
      SFX::Firsht,                                                                        # # seesound
      8,                                                                                  # # reactiontime
      SFX::None,                                                                          # # attacksound
      Statenum::NULL,                                                                     # # painstate
      0,                                                                                  # # painchance
      SFX::None,                                                                          # # painsound
      Statenum::NULL,                                                                     # # meleestate
      Statenum::NULL,                                                                     # # missilestate
      Statenum::TBALLX1,                                                                  # # deathstate
      Statenum::NULL,                                                                     # # xdeathstate
      SFX::Firxpl,                                                                        # # deathsound
      10*FRACUNIT,                                                                        # # speed
      6*FRACUNIT,                                                                         # # radius
      8*FRACUNIT,                                                                         # # height
      100,                                                                                # # mass
      3,                                                                                  # # damage
      SFX::None,                                                                          # # activesound
      Mobjflag::NOBLOCKMAP | Mobjflag::MISSILE | Mobjflag::DROPOFF | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                                                                     # # raisestate
),

    Mobjinfo.new(                                                                         # # MT_HEADSHOT
-1,                                                                                       # # doomednum
      Statenum::RBALL1,                                                                   # # spawnstate
      1000,                                                                               # # spawnhealth
      Statenum::NULL,                                                                     # # seestate
      SFX::Firsht,                                                                        # # seesound
      8,                                                                                  # # reactiontime
      SFX::None,                                                                          # # attacksound
      Statenum::NULL,                                                                     # # painstate
      0,                                                                                  # # painchance
      SFX::None,                                                                          # # painsound
      Statenum::NULL,                                                                     # # meleestate
      Statenum::NULL,                                                                     # # missilestate
      Statenum::RBALLX1,                                                                  # # deathstate
      Statenum::NULL,                                                                     # # xdeathstate
      SFX::Firxpl,                                                                        # # deathsound
      10*FRACUNIT,                                                                        # # speed
      6*FRACUNIT,                                                                         # # radius
      8*FRACUNIT,                                                                         # # height
      100,                                                                                # # mass
      5,                                                                                  # # damage
      SFX::None,                                                                          # # activesound
      Mobjflag::NOBLOCKMAP | Mobjflag::MISSILE | Mobjflag::DROPOFF | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                                                                     # # raisestate
),

    Mobjinfo.new(                                                                         # # MT_ROCKET
-1,                                                                                       # # doomednum
      Statenum::ROCKET,                                                                   # # spawnstate
      1000,                                                                               # # spawnhealth
      Statenum::NULL,                                                                     # # seestate
      SFX::Rlaunc,                                                                        # # seesound
      8,                                                                                  # # reactiontime
      SFX::None,                                                                          # # attacksound
      Statenum::NULL,                                                                     # # painstate
      0,                                                                                  # # painchance
      SFX::None,                                                                          # # painsound
      Statenum::NULL,                                                                     # # meleestate
      Statenum::NULL,                                                                     # # missilestate
      Statenum::EXPLODE1,                                                                 # # deathstate
      Statenum::NULL,                                                                     # # xdeathstate
      SFX::Barexp,                                                                        # # deathsound
      20*FRACUNIT,                                                                        # # speed
      11*FRACUNIT,                                                                        # # radius
      8*FRACUNIT,                                                                         # # height
      100,                                                                                # # mass
      20,                                                                                 # # damage
      SFX::None,                                                                          # # activesound
      Mobjflag::NOBLOCKMAP | Mobjflag::MISSILE | Mobjflag::DROPOFF | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                                                                     # # raisestate
),

    Mobjinfo.new(                                                                         # # MT_PLASMA
-1,                                                                                       # # doomednum
      Statenum::PLASBALL,                                                                 # # spawnstate
      1000,                                                                               # # spawnhealth
      Statenum::NULL,                                                                     # # seestate
      SFX::Plasma,                                                                        # # seesound
      8,                                                                                  # # reactiontime
      SFX::None,                                                                          # # attacksound
      Statenum::NULL,                                                                     # # painstate
      0,                                                                                  # # painchance
      SFX::None,                                                                          # # painsound
      Statenum::NULL,                                                                     # # meleestate
      Statenum::NULL,                                                                     # # missilestate
      Statenum::PLASEXP,                                                                  # # deathstate
      Statenum::NULL,                                                                     # # xdeathstate
      SFX::Firxpl,                                                                        # # deathsound
      25*FRACUNIT,                                                                        # # speed
      13*FRACUNIT,                                                                        # # radius
      8*FRACUNIT,                                                                         # # height
      100,                                                                                # # mass
      5,                                                                                  # # damage
      SFX::None,                                                                          # # activesound
      Mobjflag::NOBLOCKMAP | Mobjflag::MISSILE | Mobjflag::DROPOFF | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                                                                     # # raisestate
),

    Mobjinfo.new(                                                                         # # MT_BFG
-1,                                                                                       # # doomednum
      Statenum::BFGSHOT,                                                                  # # spawnstate
      1000,                                                                               # # spawnhealth
      Statenum::NULL,                                                                     # # seestate
      0,                                                                                  # # seesound
      8,                                                                                  # # reactiontime
      SFX::None,                                                                          # # attacksound
      Statenum::NULL,                                                                     # # painstate
      0,                                                                                  # # painchance
      SFX::None,                                                                          # # painsound
      Statenum::NULL,                                                                     # # meleestate
      Statenum::NULL,                                                                     # # missilestate
      Statenum::BFGLAND,                                                                  # # deathstate
      Statenum::NULL,                                                                     # # xdeathstate
      SFX::Rxplod,                                                                        # # deathsound
      25*FRACUNIT,                                                                        # # speed
      13*FRACUNIT,                                                                        # # radius
      8*FRACUNIT,                                                                         # # height
      100,                                                                                # # mass
      100,                                                                                # # damage
      SFX::None,                                                                          # # activesound
      Mobjflag::NOBLOCKMAP | Mobjflag::MISSILE | Mobjflag::DROPOFF | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                                                                     # # raisestate
),

    Mobjinfo.new(                                                                         # # MT_ARACHPLAZ
-1,                                                                                       # # doomednum
      Statenum::ARACH_PLAZ,                                                               # # spawnstate
      1000,                                                                               # # spawnhealth
      Statenum::NULL,                                                                     # # seestate
      SFX::Plasma,                                                                        # # seesound
      8,                                                                                  # # reactiontime
      SFX::None,                                                                          # # attacksound
      Statenum::NULL,                                                                     # # painstate
      0,                                                                                  # # painchance
      SFX::None,                                                                          # # painsound
      Statenum::NULL,                                                                     # # meleestate
      Statenum::NULL,                                                                     # # missilestate
      Statenum::ARACH_PLEX,                                                               # # deathstate
      Statenum::NULL,                                                                     # # xdeathstate
      SFX::Firxpl,                                                                        # # deathsound
      25*FRACUNIT,                                                                        # # speed
      13*FRACUNIT,                                                                        # # radius
      8*FRACUNIT,                                                                         # # height
      100,                                                                                # # mass
      5,                                                                                  # # damage
      SFX::None,                                                                          # # activesound
      Mobjflag::NOBLOCKMAP | Mobjflag::MISSILE | Mobjflag::DROPOFF | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                                                                     # # raisestate
),

    Mobjinfo.new(                                 # # MT_PUFF
-1,                                               # # doomednum
      Statenum::PUFF1,                            # # spawnstate
      1000,                                       # # spawnhealth
      Statenum::NULL,                             # # seestate
      SFX::None,                                  # # seesound
      8,                                          # # reactiontime
      SFX::None,                                  # # attacksound
      Statenum::NULL,                             # # painstate
      0,                                          # # painchance
      SFX::None,                                  # # painsound
      Statenum::NULL,                             # # meleestate
      Statenum::NULL,                             # # missilestate
      Statenum::NULL,                             # # deathstate
      Statenum::NULL,                             # # xdeathstate
      SFX::None,                                  # # deathsound
      0,                                          # # speed
      20*FRACUNIT,                                # # radius
      16*FRACUNIT,                                # # height
      100,                                        # # mass
      0,                                          # # damage
      SFX::None,                                  # # activesound
      Mobjflag::NOBLOCKMAP | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                             # # raisestate
),

    Mobjinfo.new(           # # MT_BLOOD
-1,                         # # doomednum
      Statenum::BLOOD1,     # # spawnstate
      1000,                 # # spawnhealth
      Statenum::NULL,       # # seestate
      SFX::None,            # # seesound
      8,                    # # reactiontime
      SFX::None,            # # attacksound
      Statenum::NULL,       # # painstate
      0,                    # # painchance
      SFX::None,            # # painsound
      Statenum::NULL,       # # meleestate
      Statenum::NULL,       # # missilestate
      Statenum::NULL,       # # deathstate
      Statenum::NULL,       # # xdeathstate
      SFX::None,            # # deathsound
      0,                    # # speed
      20*FRACUNIT,          # # radius
      16*FRACUNIT,          # # height
      100,                  # # mass
      0,                    # # damage
      SFX::None,            # # activesound
      Mobjflag::NOBLOCKMAP, # # flags
      Statenum::NULL,       # # raisestate
),

    Mobjinfo.new(                                 # # MT_TFOG
-1,                                               # # doomednum
      Statenum::TFOG,                             # # spawnstate
      1000,                                       # # spawnhealth
      Statenum::NULL,                             # # seestate
      SFX::None,                                  # # seesound
      8,                                          # # reactiontime
      SFX::None,                                  # # attacksound
      Statenum::NULL,                             # # painstate
      0,                                          # # painchance
      SFX::None,                                  # # painsound
      Statenum::NULL,                             # # meleestate
      Statenum::NULL,                             # # missilestate
      Statenum::NULL,                             # # deathstate
      Statenum::NULL,                             # # xdeathstate
      SFX::None,                                  # # deathsound
      0,                                          # # speed
      20*FRACUNIT,                                # # radius
      16*FRACUNIT,                                # # height
      100,                                        # # mass
      0,                                          # # damage
      SFX::None,                                  # # activesound
      Mobjflag::NOBLOCKMAP | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                             # # raisestate
),

    Mobjinfo.new(                                 # # MT_IFOG
-1,                                               # # doomednum
      Statenum::IFOG,                             # # spawnstate
      1000,                                       # # spawnhealth
      Statenum::NULL,                             # # seestate
      SFX::None,                                  # # seesound
      8,                                          # # reactiontime
      SFX::None,                                  # # attacksound
      Statenum::NULL,                             # # painstate
      0,                                          # # painchance
      SFX::None,                                  # # painsound
      Statenum::NULL,                             # # meleestate
      Statenum::NULL,                             # # missilestate
      Statenum::NULL,                             # # deathstate
      Statenum::NULL,                             # # xdeathstate
      SFX::None,                                  # # deathsound
      0,                                          # # speed
      20*FRACUNIT,                                # # radius
      16*FRACUNIT,                                # # height
      100,                                        # # mass
      0,                                          # # damage
      SFX::None,                                  # # activesound
      Mobjflag::NOBLOCKMAP | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                             # # raisestate
),

    Mobjinfo.new(                                # # MT_TELEPORTMAN
14,                                              # # doomednum
      Statenum::NULL,                            # # spawnstate
      1000,                                      # # spawnhealth
      Statenum::NULL,                            # # seestate
      SFX::None,                                 # # seesound
      8,                                         # # reactiontime
      SFX::None,                                 # # attacksound
      Statenum::NULL,                            # # painstate
      0,                                         # # painchance
      SFX::None,                                 # # painsound
      Statenum::NULL,                            # # meleestate
      Statenum::NULL,                            # # missilestate
      Statenum::NULL,                            # # deathstate
      Statenum::NULL,                            # # xdeathstate
      SFX::None,                                 # # deathsound
      0,                                         # # speed
      20*FRACUNIT,                               # # radius
      16*FRACUNIT,                               # # height
      100,                                       # # mass
      0,                                         # # damage
      SFX::None,                                 # # activesound
      Mobjflag::NOBLOCKMAP | Mobjflag::NOSECTOR, # # flags
      Statenum::NULL,                            # # raisestate
),

    Mobjinfo.new(                                 # # MT_EXTRABFG
-1,                                               # # doomednum
      Statenum::BFGEXP,                           # # spawnstate
      1000,                                       # # spawnhealth
      Statenum::NULL,                             # # seestate
      SFX::None,                                  # # seesound
      8,                                          # # reactiontime
      SFX::None,                                  # # attacksound
      Statenum::NULL,                             # # painstate
      0,                                          # # painchance
      SFX::None,                                  # # painsound
      Statenum::NULL,                             # # meleestate
      Statenum::NULL,                             # # missilestate
      Statenum::NULL,                             # # deathstate
      Statenum::NULL,                             # # xdeathstate
      SFX::None,                                  # # deathsound
      0,                                          # # speed
      20*FRACUNIT,                                # # radius
      16*FRACUNIT,                                # # height
      100,                                        # # mass
      0,                                          # # damage
      SFX::None,                                  # # activesound
      Mobjflag::NOBLOCKMAP | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                             # # raisestate
),

    Mobjinfo.new(        # # MT_MISC0
2018,                    # # doomednum
      Statenum::ARM1,    # # spawnstate
      1000,              # # spawnhealth
      Statenum::NULL,    # # seestate
      SFX::None,         # # seesound
      8,                 # # reactiontime
      SFX::None,         # # attacksound
      Statenum::NULL,    # # painstate
      0,                 # # painchance
      SFX::None,         # # painsound
      Statenum::NULL,    # # meleestate
      Statenum::NULL,    # # missilestate
      Statenum::NULL,    # # deathstate
      Statenum::NULL,    # # xdeathstate
      SFX::None,         # # deathsound
      0,                 # # speed
      20*FRACUNIT,       # # radius
      16*FRACUNIT,       # # height
      100,               # # mass
      0,                 # # damage
      SFX::None,         # # activesound
      Mobjflag::SPECIAL, # # flags
      Statenum::NULL,    # # raisestate
),

    Mobjinfo.new(        # # MT_MISC1
2019,                    # # doomednum
      Statenum::ARM2,    # # spawnstate
      1000,              # # spawnhealth
      Statenum::NULL,    # # seestate
      SFX::None,         # # seesound
      8,                 # # reactiontime
      SFX::None,         # # attacksound
      Statenum::NULL,    # # painstate
      0,                 # # painchance
      SFX::None,         # # painsound
      Statenum::NULL,    # # meleestate
      Statenum::NULL,    # # missilestate
      Statenum::NULL,    # # deathstate
      Statenum::NULL,    # # xdeathstate
      SFX::None,         # # deathsound
      0,                 # # speed
      20*FRACUNIT,       # # radius
      16*FRACUNIT,       # # height
      100,               # # mass
      0,                 # # damage
      SFX::None,         # # activesound
      Mobjflag::SPECIAL, # # flags
      Statenum::NULL,    # # raisestate
),

    Mobjinfo.new(                              # # MT_MISC2
2014,                                          # # doomednum
      Statenum::BON1,                          # # spawnstate
      1000,                                    # # spawnhealth
      Statenum::NULL,                          # # seestate
      SFX::None,                               # # seesound
      8,                                       # # reactiontime
      SFX::None,                               # # attacksound
      Statenum::NULL,                          # # painstate
      0,                                       # # painchance
      SFX::None,                               # # painsound
      Statenum::NULL,                          # # meleestate
      Statenum::NULL,                          # # missilestate
      Statenum::NULL,                          # # deathstate
      Statenum::NULL,                          # # xdeathstate
      SFX::None,                               # # deathsound
      0,                                       # # speed
      20*FRACUNIT,                             # # radius
      16*FRACUNIT,                             # # height
      100,                                     # # mass
      0,                                       # # damage
      SFX::None,                               # # activesound
      Mobjflag::SPECIAL | Mobjflag::COUNTITEM, # # flags
      Statenum::NULL,                          # # raisestate
),

    Mobjinfo.new(                              # # MT_MISC3
2015,                                          # # doomednum
      Statenum::BON2,                          # # spawnstate
      1000,                                    # # spawnhealth
      Statenum::NULL,                          # # seestate
      SFX::None,                               # # seesound
      8,                                       # # reactiontime
      SFX::None,                               # # attacksound
      Statenum::NULL,                          # # painstate
      0,                                       # # painchance
      SFX::None,                               # # painsound
      Statenum::NULL,                          # # meleestate
      Statenum::NULL,                          # # missilestate
      Statenum::NULL,                          # # deathstate
      Statenum::NULL,                          # # xdeathstate
      SFX::None,                               # # deathsound
      0,                                       # # speed
      20*FRACUNIT,                             # # radius
      16*FRACUNIT,                             # # height
      100,                                     # # mass
      0,                                       # # damage
      SFX::None,                               # # activesound
      Mobjflag::SPECIAL | Mobjflag::COUNTITEM, # # flags
      Statenum::NULL,                          # # raisestate
),

    Mobjinfo.new(                              # # MT_MISC4
5,                                             # # doomednum
      Statenum::BKEY,                          # # spawnstate
      1000,                                    # # spawnhealth
      Statenum::NULL,                          # # seestate
      SFX::None,                               # # seesound
      8,                                       # # reactiontime
      SFX::None,                               # # attacksound
      Statenum::NULL,                          # # painstate
      0,                                       # # painchance
      SFX::None,                               # # painsound
      Statenum::NULL,                          # # meleestate
      Statenum::NULL,                          # # missilestate
      Statenum::NULL,                          # # deathstate
      Statenum::NULL,                          # # xdeathstate
      SFX::None,                               # # deathsound
      0,                                       # # speed
      20*FRACUNIT,                             # # radius
      16*FRACUNIT,                             # # height
      100,                                     # # mass
      0,                                       # # damage
      SFX::None,                               # # activesound
      Mobjflag::SPECIAL | Mobjflag::NOTDMATCH, # # flags
      Statenum::NULL,                          # # raisestate
),

    Mobjinfo.new(                              # # MT_MISC5
13,                                            # # doomednum
      Statenum::RKEY,                          # # spawnstate
      1000,                                    # # spawnhealth
      Statenum::NULL,                          # # seestate
      SFX::None,                               # # seesound
      8,                                       # # reactiontime
      SFX::None,                               # # attacksound
      Statenum::NULL,                          # # painstate
      0,                                       # # painchance
      SFX::None,                               # # painsound
      Statenum::NULL,                          # # meleestate
      Statenum::NULL,                          # # missilestate
      Statenum::NULL,                          # # deathstate
      Statenum::NULL,                          # # xdeathstate
      SFX::None,                               # # deathsound
      0,                                       # # speed
      20*FRACUNIT,                             # # radius
      16*FRACUNIT,                             # # height
      100,                                     # # mass
      0,                                       # # damage
      SFX::None,                               # # activesound
      Mobjflag::SPECIAL | Mobjflag::NOTDMATCH, # # flags
      Statenum::NULL,                          # # raisestate
),

    Mobjinfo.new(                              # # MT_MISC6
6,                                             # # doomednum
      Statenum::YKEY,                          # # spawnstate
      1000,                                    # # spawnhealth
      Statenum::NULL,                          # # seestate
      SFX::None,                               # # seesound
      8,                                       # # reactiontime
      SFX::None,                               # # attacksound
      Statenum::NULL,                          # # painstate
      0,                                       # # painchance
      SFX::None,                               # # painsound
      Statenum::NULL,                          # # meleestate
      Statenum::NULL,                          # # missilestate
      Statenum::NULL,                          # # deathstate
      Statenum::NULL,                          # # xdeathstate
      SFX::None,                               # # deathsound
      0,                                       # # speed
      20*FRACUNIT,                             # # radius
      16*FRACUNIT,                             # # height
      100,                                     # # mass
      0,                                       # # damage
      SFX::None,                               # # activesound
      Mobjflag::SPECIAL | Mobjflag::NOTDMATCH, # # flags
      Statenum::NULL,                          # # raisestate
),

    Mobjinfo.new(                              # # MT_MISC7
39,                                            # # doomednum
      Statenum::YSKULL,                        # # spawnstate
      1000,                                    # # spawnhealth
      Statenum::NULL,                          # # seestate
      SFX::None,                               # # seesound
      8,                                       # # reactiontime
      SFX::None,                               # # attacksound
      Statenum::NULL,                          # # painstate
      0,                                       # # painchance
      SFX::None,                               # # painsound
      Statenum::NULL,                          # # meleestate
      Statenum::NULL,                          # # missilestate
      Statenum::NULL,                          # # deathstate
      Statenum::NULL,                          # # xdeathstate
      SFX::None,                               # # deathsound
      0,                                       # # speed
      20*FRACUNIT,                             # # radius
      16*FRACUNIT,                             # # height
      100,                                     # # mass
      0,                                       # # damage
      SFX::None,                               # # activesound
      Mobjflag::SPECIAL | Mobjflag::NOTDMATCH, # # flags
      Statenum::NULL,                          # # raisestate
),

    Mobjinfo.new(                              # # MT_MISC8
38,                                            # # doomednum
      Statenum::RSKULL,                        # # spawnstate
      1000,                                    # # spawnhealth
      Statenum::NULL,                          # # seestate
      SFX::None,                               # # seesound
      8,                                       # # reactiontime
      SFX::None,                               # # attacksound
      Statenum::NULL,                          # # painstate
      0,                                       # # painchance
      SFX::None,                               # # painsound
      Statenum::NULL,                          # # meleestate
      Statenum::NULL,                          # # missilestate
      Statenum::NULL,                          # # deathstate
      Statenum::NULL,                          # # xdeathstate
      SFX::None,                               # # deathsound
      0,                                       # # speed
      20*FRACUNIT,                             # # radius
      16*FRACUNIT,                             # # height
      100,                                     # # mass
      0,                                       # # damage
      SFX::None,                               # # activesound
      Mobjflag::SPECIAL | Mobjflag::NOTDMATCH, # # flags
      Statenum::NULL,                          # # raisestate
),

    Mobjinfo.new(                              # # MT_MISC9
40,                                            # # doomednum
      Statenum::BSKULL,                        # # spawnstate
      1000,                                    # # spawnhealth
      Statenum::NULL,                          # # seestate
      SFX::None,                               # # seesound
      8,                                       # # reactiontime
      SFX::None,                               # # attacksound
      Statenum::NULL,                          # # painstate
      0,                                       # # painchance
      SFX::None,                               # # painsound
      Statenum::NULL,                          # # meleestate
      Statenum::NULL,                          # # missilestate
      Statenum::NULL,                          # # deathstate
      Statenum::NULL,                          # # xdeathstate
      SFX::None,                               # # deathsound
      0,                                       # # speed
      20*FRACUNIT,                             # # radius
      16*FRACUNIT,                             # # height
      100,                                     # # mass
      0,                                       # # damage
      SFX::None,                               # # activesound
      Mobjflag::SPECIAL | Mobjflag::NOTDMATCH, # # flags
      Statenum::NULL,                          # # raisestate
),

    Mobjinfo.new(        # # MT_MISC10
2011,                    # # doomednum
      Statenum::STIM,    # # spawnstate
      1000,              # # spawnhealth
      Statenum::NULL,    # # seestate
      SFX::None,         # # seesound
      8,                 # # reactiontime
      SFX::None,         # # attacksound
      Statenum::NULL,    # # painstate
      0,                 # # painchance
      SFX::None,         # # painsound
      Statenum::NULL,    # # meleestate
      Statenum::NULL,    # # missilestate
      Statenum::NULL,    # # deathstate
      Statenum::NULL,    # # xdeathstate
      SFX::None,         # # deathsound
      0,                 # # speed
      20*FRACUNIT,       # # radius
      16*FRACUNIT,       # # height
      100,               # # mass
      0,                 # # damage
      SFX::None,         # # activesound
      Mobjflag::SPECIAL, # # flags
      Statenum::NULL,    # # raisestate
),

    Mobjinfo.new(        # # MT_MISC11
2012,                    # # doomednum
      Statenum::MEDI,    # # spawnstate
      1000,              # # spawnhealth
      Statenum::NULL,    # # seestate
      SFX::None,         # # seesound
      8,                 # # reactiontime
      SFX::None,         # # attacksound
      Statenum::NULL,    # # painstate
      0,                 # # painchance
      SFX::None,         # # painsound
      Statenum::NULL,    # # meleestate
      Statenum::NULL,    # # missilestate
      Statenum::NULL,    # # deathstate
      Statenum::NULL,    # # xdeathstate
      SFX::None,         # # deathsound
      0,                 # # speed
      20*FRACUNIT,       # # radius
      16*FRACUNIT,       # # height
      100,               # # mass
      0,                 # # damage
      SFX::None,         # # activesound
      Mobjflag::SPECIAL, # # flags
      Statenum::NULL,    # # raisestate
),

    Mobjinfo.new(                              # # MT_MISC12
2013,                                          # # doomednum
      Statenum::SOUL,                          # # spawnstate
      1000,                                    # # spawnhealth
      Statenum::NULL,                          # # seestate
      SFX::None,                               # # seesound
      8,                                       # # reactiontime
      SFX::None,                               # # attacksound
      Statenum::NULL,                          # # painstate
      0,                                       # # painchance
      SFX::None,                               # # painsound
      Statenum::NULL,                          # # meleestate
      Statenum::NULL,                          # # missilestate
      Statenum::NULL,                          # # deathstate
      Statenum::NULL,                          # # xdeathstate
      SFX::None,                               # # deathsound
      0,                                       # # speed
      20*FRACUNIT,                             # # radius
      16*FRACUNIT,                             # # height
      100,                                     # # mass
      0,                                       # # damage
      SFX::None,                               # # activesound
      Mobjflag::SPECIAL | Mobjflag::COUNTITEM, # # flags
      Statenum::NULL,                          # # raisestate
),

    Mobjinfo.new(                              # # MT_INV
2022,                                          # # doomednum
      Statenum::PINV,                          # # spawnstate
      1000,                                    # # spawnhealth
      Statenum::NULL,                          # # seestate
      SFX::None,                               # # seesound
      8,                                       # # reactiontime
      SFX::None,                               # # attacksound
      Statenum::NULL,                          # # painstate
      0,                                       # # painchance
      SFX::None,                               # # painsound
      Statenum::NULL,                          # # meleestate
      Statenum::NULL,                          # # missilestate
      Statenum::NULL,                          # # deathstate
      Statenum::NULL,                          # # xdeathstate
      SFX::None,                               # # deathsound
      0,                                       # # speed
      20*FRACUNIT,                             # # radius
      16*FRACUNIT,                             # # height
      100,                                     # # mass
      0,                                       # # damage
      SFX::None,                               # # activesound
      Mobjflag::SPECIAL | Mobjflag::COUNTITEM, # # flags
      Statenum::NULL,                          # # raisestate
),

    Mobjinfo.new(                              # # MT_MISC13
2023,                                          # # doomednum
      Statenum::PSTR,                          # # spawnstate
      1000,                                    # # spawnhealth
      Statenum::NULL,                          # # seestate
      SFX::None,                               # # seesound
      8,                                       # # reactiontime
      SFX::None,                               # # attacksound
      Statenum::NULL,                          # # painstate
      0,                                       # # painchance
      SFX::None,                               # # painsound
      Statenum::NULL,                          # # meleestate
      Statenum::NULL,                          # # missilestate
      Statenum::NULL,                          # # deathstate
      Statenum::NULL,                          # # xdeathstate
      SFX::None,                               # # deathsound
      0,                                       # # speed
      20*FRACUNIT,                             # # radius
      16*FRACUNIT,                             # # height
      100,                                     # # mass
      0,                                       # # damage
      SFX::None,                               # # activesound
      Mobjflag::SPECIAL | Mobjflag::COUNTITEM, # # flags
      Statenum::NULL,                          # # raisestate
),

    Mobjinfo.new(                              # # MT_INS
2024,                                          # # doomednum
      Statenum::PINS,                          # # spawnstate
      1000,                                    # # spawnhealth
      Statenum::NULL,                          # # seestate
      SFX::None,                               # # seesound
      8,                                       # # reactiontime
      SFX::None,                               # # attacksound
      Statenum::NULL,                          # # painstate
      0,                                       # # painchance
      SFX::None,                               # # painsound
      Statenum::NULL,                          # # meleestate
      Statenum::NULL,                          # # missilestate
      Statenum::NULL,                          # # deathstate
      Statenum::NULL,                          # # xdeathstate
      SFX::None,                               # # deathsound
      0,                                       # # speed
      20*FRACUNIT,                             # # radius
      16*FRACUNIT,                             # # height
      100,                                     # # mass
      0,                                       # # damage
      SFX::None,                               # # activesound
      Mobjflag::SPECIAL | Mobjflag::COUNTITEM, # # flags
      Statenum::NULL,                          # # raisestate
),

    Mobjinfo.new(        # # MT_MISC14
2025,                    # # doomednum
      Statenum::SUIT,    # # spawnstate
      1000,              # # spawnhealth
      Statenum::NULL,    # # seestate
      SFX::None,         # # seesound
      8,                 # # reactiontime
      SFX::None,         # # attacksound
      Statenum::NULL,    # # painstate
      0,                 # # painchance
      SFX::None,         # # painsound
      Statenum::NULL,    # # meleestate
      Statenum::NULL,    # # missilestate
      Statenum::NULL,    # # deathstate
      Statenum::NULL,    # # xdeathstate
      SFX::None,         # # deathsound
      0,                 # # speed
      20*FRACUNIT,       # # radius
      16*FRACUNIT,       # # height
      100,               # # mass
      0,                 # # damage
      SFX::None,         # # activesound
      Mobjflag::SPECIAL, # # flags
      Statenum::NULL,    # # raisestate
),

    Mobjinfo.new(                              # # MT_MISC15
2026,                                          # # doomednum
      Statenum::PMAP,                          # # spawnstate
      1000,                                    # # spawnhealth
      Statenum::NULL,                          # # seestate
      SFX::None,                               # # seesound
      8,                                       # # reactiontime
      SFX::None,                               # # attacksound
      Statenum::NULL,                          # # painstate
      0,                                       # # painchance
      SFX::None,                               # # painsound
      Statenum::NULL,                          # # meleestate
      Statenum::NULL,                          # # missilestate
      Statenum::NULL,                          # # deathstate
      Statenum::NULL,                          # # xdeathstate
      SFX::None,                               # # deathsound
      0,                                       # # speed
      20*FRACUNIT,                             # # radius
      16*FRACUNIT,                             # # height
      100,                                     # # mass
      0,                                       # # damage
      SFX::None,                               # # activesound
      Mobjflag::SPECIAL | Mobjflag::COUNTITEM, # # flags
      Statenum::NULL,                          # # raisestate
),

    Mobjinfo.new(                              # # MT_MISC16
2045,                                          # # doomednum
      Statenum::PVIS,                          # # spawnstate
      1000,                                    # # spawnhealth
      Statenum::NULL,                          # # seestate
      SFX::None,                               # # seesound
      8,                                       # # reactiontime
      SFX::None,                               # # attacksound
      Statenum::NULL,                          # # painstate
      0,                                       # # painchance
      SFX::None,                               # # painsound
      Statenum::NULL,                          # # meleestate
      Statenum::NULL,                          # # missilestate
      Statenum::NULL,                          # # deathstate
      Statenum::NULL,                          # # xdeathstate
      SFX::None,                               # # deathsound
      0,                                       # # speed
      20*FRACUNIT,                             # # radius
      16*FRACUNIT,                             # # height
      100,                                     # # mass
      0,                                       # # damage
      SFX::None,                               # # activesound
      Mobjflag::SPECIAL | Mobjflag::COUNTITEM, # # flags
      Statenum::NULL,                          # # raisestate
),

    Mobjinfo.new(                              # # MT_MEGA
83,                                            # # doomednum
      Statenum::MEGA,                          # # spawnstate
      1000,                                    # # spawnhealth
      Statenum::NULL,                          # # seestate
      SFX::None,                               # # seesound
      8,                                       # # reactiontime
      SFX::None,                               # # attacksound
      Statenum::NULL,                          # # painstate
      0,                                       # # painchance
      SFX::None,                               # # painsound
      Statenum::NULL,                          # # meleestate
      Statenum::NULL,                          # # missilestate
      Statenum::NULL,                          # # deathstate
      Statenum::NULL,                          # # xdeathstate
      SFX::None,                               # # deathsound
      0,                                       # # speed
      20*FRACUNIT,                             # # radius
      16*FRACUNIT,                             # # height
      100,                                     # # mass
      0,                                       # # damage
      SFX::None,                               # # activesound
      Mobjflag::SPECIAL | Mobjflag::COUNTITEM, # # flags
      Statenum::NULL,                          # # raisestate
),

    Mobjinfo.new(        # # MT_CLIP
2007,                    # # doomednum
      Statenum::CLIP,    # # spawnstate
      1000,              # # spawnhealth
      Statenum::NULL,    # # seestate
      SFX::None,         # # seesound
      8,                 # # reactiontime
      SFX::None,         # # attacksound
      Statenum::NULL,    # # painstate
      0,                 # # painchance
      SFX::None,         # # painsound
      Statenum::NULL,    # # meleestate
      Statenum::NULL,    # # missilestate
      Statenum::NULL,    # # deathstate
      Statenum::NULL,    # # xdeathstate
      SFX::None,         # # deathsound
      0,                 # # speed
      20*FRACUNIT,       # # radius
      16*FRACUNIT,       # # height
      100,               # # mass
      0,                 # # damage
      SFX::None,         # # activesound
      Mobjflag::SPECIAL, # # flags
      Statenum::NULL,    # # raisestate
),

    Mobjinfo.new(        # # MT_MISC17
2048,                    # # doomednum
      Statenum::AMMO,    # # spawnstate
      1000,              # # spawnhealth
      Statenum::NULL,    # # seestate
      SFX::None,         # # seesound
      8,                 # # reactiontime
      SFX::None,         # # attacksound
      Statenum::NULL,    # # painstate
      0,                 # # painchance
      SFX::None,         # # painsound
      Statenum::NULL,    # # meleestate
      Statenum::NULL,    # # missilestate
      Statenum::NULL,    # # deathstate
      Statenum::NULL,    # # xdeathstate
      SFX::None,         # # deathsound
      0,                 # # speed
      20*FRACUNIT,       # # radius
      16*FRACUNIT,       # # height
      100,               # # mass
      0,                 # # damage
      SFX::None,         # # activesound
      Mobjflag::SPECIAL, # # flags
      Statenum::NULL,    # # raisestate
),

    Mobjinfo.new(        # # MT_MISC18
2010,                    # # doomednum
      Statenum::ROCK,    # # spawnstate
      1000,              # # spawnhealth
      Statenum::NULL,    # # seestate
      SFX::None,         # # seesound
      8,                 # # reactiontime
      SFX::None,         # # attacksound
      Statenum::NULL,    # # painstate
      0,                 # # painchance
      SFX::None,         # # painsound
      Statenum::NULL,    # # meleestate
      Statenum::NULL,    # # missilestate
      Statenum::NULL,    # # deathstate
      Statenum::NULL,    # # xdeathstate
      SFX::None,         # # deathsound
      0,                 # # speed
      20*FRACUNIT,       # # radius
      16*FRACUNIT,       # # height
      100,               # # mass
      0,                 # # damage
      SFX::None,         # # activesound
      Mobjflag::SPECIAL, # # flags
      Statenum::NULL,    # # raisestate
),

    Mobjinfo.new(        # # MT_MISC19
2046,                    # # doomednum
      Statenum::BROK,    # # spawnstate
      1000,              # # spawnhealth
      Statenum::NULL,    # # seestate
      SFX::None,         # # seesound
      8,                 # # reactiontime
      SFX::None,         # # attacksound
      Statenum::NULL,    # # painstate
      0,                 # # painchance
      SFX::None,         # # painsound
      Statenum::NULL,    # # meleestate
      Statenum::NULL,    # # missilestate
      Statenum::NULL,    # # deathstate
      Statenum::NULL,    # # xdeathstate
      SFX::None,         # # deathsound
      0,                 # # speed
      20*FRACUNIT,       # # radius
      16*FRACUNIT,       # # height
      100,               # # mass
      0,                 # # damage
      SFX::None,         # # activesound
      Mobjflag::SPECIAL, # # flags
      Statenum::NULL,    # # raisestate
),

    Mobjinfo.new(        # # MT_MISC20
2047,                    # # doomednum
      Statenum::CELL,    # # spawnstate
      1000,              # # spawnhealth
      Statenum::NULL,    # # seestate
      SFX::None,         # # seesound
      8,                 # # reactiontime
      SFX::None,         # # attacksound
      Statenum::NULL,    # # painstate
      0,                 # # painchance
      SFX::None,         # # painsound
      Statenum::NULL,    # # meleestate
      Statenum::NULL,    # # missilestate
      Statenum::NULL,    # # deathstate
      Statenum::NULL,    # # xdeathstate
      SFX::None,         # # deathsound
      0,                 # # speed
      20*FRACUNIT,       # # radius
      16*FRACUNIT,       # # height
      100,               # # mass
      0,                 # # damage
      SFX::None,         # # activesound
      Mobjflag::SPECIAL, # # flags
      Statenum::NULL,    # # raisestate
),

    Mobjinfo.new(        # # MT_MISC21
17,                      # # doomednum
      Statenum::CELP,    # # spawnstate
      1000,              # # spawnhealth
      Statenum::NULL,    # # seestate
      SFX::None,         # # seesound
      8,                 # # reactiontime
      SFX::None,         # # attacksound
      Statenum::NULL,    # # painstate
      0,                 # # painchance
      SFX::None,         # # painsound
      Statenum::NULL,    # # meleestate
      Statenum::NULL,    # # missilestate
      Statenum::NULL,    # # deathstate
      Statenum::NULL,    # # xdeathstate
      SFX::None,         # # deathsound
      0,                 # # speed
      20*FRACUNIT,       # # radius
      16*FRACUNIT,       # # height
      100,               # # mass
      0,                 # # damage
      SFX::None,         # # activesound
      Mobjflag::SPECIAL, # # flags
      Statenum::NULL,    # # raisestate
),

    Mobjinfo.new(        # # MT_MISC22
2008,                    # # doomednum
      Statenum::SHEL,    # # spawnstate
      1000,              # # spawnhealth
      Statenum::NULL,    # # seestate
      SFX::None,         # # seesound
      8,                 # # reactiontime
      SFX::None,         # # attacksound
      Statenum::NULL,    # # painstate
      0,                 # # painchance
      SFX::None,         # # painsound
      Statenum::NULL,    # # meleestate
      Statenum::NULL,    # # missilestate
      Statenum::NULL,    # # deathstate
      Statenum::NULL,    # # xdeathstate
      SFX::None,         # # deathsound
      0,                 # # speed
      20*FRACUNIT,       # # radius
      16*FRACUNIT,       # # height
      100,               # # mass
      0,                 # # damage
      SFX::None,         # # activesound
      Mobjflag::SPECIAL, # # flags
      Statenum::NULL,    # # raisestate
),

    Mobjinfo.new(        # # MT_MISC23
2049,                    # # doomednum
      Statenum::SBOX,    # # spawnstate
      1000,              # # spawnhealth
      Statenum::NULL,    # # seestate
      SFX::None,         # # seesound
      8,                 # # reactiontime
      SFX::None,         # # attacksound
      Statenum::NULL,    # # painstate
      0,                 # # painchance
      SFX::None,         # # painsound
      Statenum::NULL,    # # meleestate
      Statenum::NULL,    # # missilestate
      Statenum::NULL,    # # deathstate
      Statenum::NULL,    # # xdeathstate
      SFX::None,         # # deathsound
      0,                 # # speed
      20*FRACUNIT,       # # radius
      16*FRACUNIT,       # # height
      100,               # # mass
      0,                 # # damage
      SFX::None,         # # activesound
      Mobjflag::SPECIAL, # # flags
      Statenum::NULL,    # # raisestate
),

    Mobjinfo.new(        # # MT_MISC24
8,                       # # doomednum
      Statenum::BPAK,    # # spawnstate
      1000,              # # spawnhealth
      Statenum::NULL,    # # seestate
      SFX::None,         # # seesound
      8,                 # # reactiontime
      SFX::None,         # # attacksound
      Statenum::NULL,    # # painstate
      0,                 # # painchance
      SFX::None,         # # painsound
      Statenum::NULL,    # # meleestate
      Statenum::NULL,    # # missilestate
      Statenum::NULL,    # # deathstate
      Statenum::NULL,    # # xdeathstate
      SFX::None,         # # deathsound
      0,                 # # speed
      20*FRACUNIT,       # # radius
      16*FRACUNIT,       # # height
      100,               # # mass
      0,                 # # damage
      SFX::None,         # # activesound
      Mobjflag::SPECIAL, # # flags
      Statenum::NULL,    # # raisestate
),

    Mobjinfo.new(        # # MT_MISC25
2006,                    # # doomednum
      Statenum::BFUG,    # # spawnstate
      1000,              # # spawnhealth
      Statenum::NULL,    # # seestate
      SFX::None,         # # seesound
      8,                 # # reactiontime
      SFX::None,         # # attacksound
      Statenum::NULL,    # # painstate
      0,                 # # painchance
      SFX::None,         # # painsound
      Statenum::NULL,    # # meleestate
      Statenum::NULL,    # # missilestate
      Statenum::NULL,    # # deathstate
      Statenum::NULL,    # # xdeathstate
      SFX::None,         # # deathsound
      0,                 # # speed
      20*FRACUNIT,       # # radius
      16*FRACUNIT,       # # height
      100,               # # mass
      0,                 # # damage
      SFX::None,         # # activesound
      Mobjflag::SPECIAL, # # flags
      Statenum::NULL,    # # raisestate
),

    Mobjinfo.new(        # # MT_CHAINGUN
2002,                    # # doomednum
      Statenum::MGUN,    # # spawnstate
      1000,              # # spawnhealth
      Statenum::NULL,    # # seestate
      SFX::None,         # # seesound
      8,                 # # reactiontime
      SFX::None,         # # attacksound
      Statenum::NULL,    # # painstate
      0,                 # # painchance
      SFX::None,         # # painsound
      Statenum::NULL,    # # meleestate
      Statenum::NULL,    # # missilestate
      Statenum::NULL,    # # deathstate
      Statenum::NULL,    # # xdeathstate
      SFX::None,         # # deathsound
      0,                 # # speed
      20*FRACUNIT,       # # radius
      16*FRACUNIT,       # # height
      100,               # # mass
      0,                 # # damage
      SFX::None,         # # activesound
      Mobjflag::SPECIAL, # # flags
      Statenum::NULL,    # # raisestate
),

    Mobjinfo.new(        # # MT_MISC26
2005,                    # # doomednum
      Statenum::CSAW,    # # spawnstate
      1000,              # # spawnhealth
      Statenum::NULL,    # # seestate
      SFX::None,         # # seesound
      8,                 # # reactiontime
      SFX::None,         # # attacksound
      Statenum::NULL,    # # painstate
      0,                 # # painchance
      SFX::None,         # # painsound
      Statenum::NULL,    # # meleestate
      Statenum::NULL,    # # missilestate
      Statenum::NULL,    # # deathstate
      Statenum::NULL,    # # xdeathstate
      SFX::None,         # # deathsound
      0,                 # # speed
      20*FRACUNIT,       # # radius
      16*FRACUNIT,       # # height
      100,               # # mass
      0,                 # # damage
      SFX::None,         # # activesound
      Mobjflag::SPECIAL, # # flags
      Statenum::NULL,    # # raisestate
),

    Mobjinfo.new(        # # MT_MISC27
2003,                    # # doomednum
      Statenum::LAUN,    # # spawnstate
      1000,              # # spawnhealth
      Statenum::NULL,    # # seestate
      SFX::None,         # # seesound
      8,                 # # reactiontime
      SFX::None,         # # attacksound
      Statenum::NULL,    # # painstate
      0,                 # # painchance
      SFX::None,         # # painsound
      Statenum::NULL,    # # meleestate
      Statenum::NULL,    # # missilestate
      Statenum::NULL,    # # deathstate
      Statenum::NULL,    # # xdeathstate
      SFX::None,         # # deathsound
      0,                 # # speed
      20*FRACUNIT,       # # radius
      16*FRACUNIT,       # # height
      100,               # # mass
      0,                 # # damage
      SFX::None,         # # activesound
      Mobjflag::SPECIAL, # # flags
      Statenum::NULL,    # # raisestate
),

    Mobjinfo.new(        # # MT_MISC28
2004,                    # # doomednum
      Statenum::PLAS,    # # spawnstate
      1000,              # # spawnhealth
      Statenum::NULL,    # # seestate
      SFX::None,         # # seesound
      8,                 # # reactiontime
      SFX::None,         # # attacksound
      Statenum::NULL,    # # painstate
      0,                 # # painchance
      SFX::None,         # # painsound
      Statenum::NULL,    # # meleestate
      Statenum::NULL,    # # missilestate
      Statenum::NULL,    # # deathstate
      Statenum::NULL,    # # xdeathstate
      SFX::None,         # # deathsound
      0,                 # # speed
      20*FRACUNIT,       # # radius
      16*FRACUNIT,       # # height
      100,               # # mass
      0,                 # # damage
      SFX::None,         # # activesound
      Mobjflag::SPECIAL, # # flags
      Statenum::NULL,    # # raisestate
),

    Mobjinfo.new(        # # MT_SHOTGUN
2001,                    # # doomednum
      Statenum::SHOT,    # # spawnstate
      1000,              # # spawnhealth
      Statenum::NULL,    # # seestate
      SFX::None,         # # seesound
      8,                 # # reactiontime
      SFX::None,         # # attacksound
      Statenum::NULL,    # # painstate
      0,                 # # painchance
      SFX::None,         # # painsound
      Statenum::NULL,    # # meleestate
      Statenum::NULL,    # # missilestate
      Statenum::NULL,    # # deathstate
      Statenum::NULL,    # # xdeathstate
      SFX::None,         # # deathsound
      0,                 # # speed
      20*FRACUNIT,       # # radius
      16*FRACUNIT,       # # height
      100,               # # mass
      0,                 # # damage
      SFX::None,         # # activesound
      Mobjflag::SPECIAL, # # flags
      Statenum::NULL,    # # raisestate
),

    Mobjinfo.new(        # # MT_SUPERSHOTGUN
82,                      # # doomednum
      Statenum::SHOT2,   # # spawnstate
      1000,              # # spawnhealth
      Statenum::NULL,    # # seestate
      SFX::None,         # # seesound
      8,                 # # reactiontime
      SFX::None,         # # attacksound
      Statenum::NULL,    # # painstate
      0,                 # # painchance
      SFX::None,         # # painsound
      Statenum::NULL,    # # meleestate
      Statenum::NULL,    # # missilestate
      Statenum::NULL,    # # deathstate
      Statenum::NULL,    # # xdeathstate
      SFX::None,         # # deathsound
      0,                 # # speed
      20*FRACUNIT,       # # radius
      16*FRACUNIT,       # # height
      100,               # # mass
      0,                 # # damage
      SFX::None,         # # activesound
      Mobjflag::SPECIAL, # # flags
      Statenum::NULL,    # # raisestate
),

    Mobjinfo.new(         # # MT_MISC29
85,                       # # doomednum
      Statenum::TECHLAMP, # # spawnstate
      1000,               # # spawnhealth
      Statenum::NULL,     # # seestate
      SFX::None,          # # seesound
      8,                  # # reactiontime
      SFX::None,          # # attacksound
      Statenum::NULL,     # # painstate
      0,                  # # painchance
      SFX::None,          # # painsound
      Statenum::NULL,     # # meleestate
      Statenum::NULL,     # # missilestate
      Statenum::NULL,     # # deathstate
      Statenum::NULL,     # # xdeathstate
      SFX::None,          # # deathsound
      0,                  # # speed
      16*FRACUNIT,        # # radius
      16*FRACUNIT,        # # height
      100,                # # mass
      0,                  # # damage
      SFX::None,          # # activesound
      Mobjflag::SOLID,    # # flags
      Statenum::NULL,     # # raisestate
),

    Mobjinfo.new(          # # MT_MISC30
86,                        # # doomednum
      Statenum::TECH2LAMP, # # spawnstate
      1000,                # # spawnhealth
      Statenum::NULL,      # # seestate
      SFX::None,           # # seesound
      8,                   # # reactiontime
      SFX::None,           # # attacksound
      Statenum::NULL,      # # painstate
      0,                   # # painchance
      SFX::None,           # # painsound
      Statenum::NULL,      # # meleestate
      Statenum::NULL,      # # missilestate
      Statenum::NULL,      # # deathstate
      Statenum::NULL,      # # xdeathstate
      SFX::None,           # # deathsound
      0,                   # # speed
      16*FRACUNIT,         # # radius
      16*FRACUNIT,         # # height
      100,                 # # mass
      0,                   # # damage
      SFX::None,           # # activesound
      Mobjflag::SOLID,     # # flags
      Statenum::NULL,      # # raisestate
),

    Mobjinfo.new(      # # MT_MISC31
2028,                  # # doomednum
      Statenum::COLU,  # # spawnstate
      1000,            # # spawnhealth
      Statenum::NULL,  # # seestate
      SFX::None,       # # seesound
      8,               # # reactiontime
      SFX::None,       # # attacksound
      Statenum::NULL,  # # painstate
      0,               # # painchance
      SFX::None,       # # painsound
      Statenum::NULL,  # # meleestate
      Statenum::NULL,  # # missilestate
      Statenum::NULL,  # # deathstate
      Statenum::NULL,  # # xdeathstate
      SFX::None,       # # deathsound
      0,               # # speed
      16*FRACUNIT,     # # radius
      16*FRACUNIT,     # # height
      100,             # # mass
      0,               # # damage
      SFX::None,       # # activesound
      Mobjflag::SOLID, # # flags
      Statenum::NULL,  # # raisestate
),

    Mobjinfo.new(           # # MT_MISC32
30,                         # # doomednum
      Statenum::TALLGRNCOL, # # spawnstate
      1000,                 # # spawnhealth
      Statenum::NULL,       # # seestate
      SFX::None,            # # seesound
      8,                    # # reactiontime
      SFX::None,            # # attacksound
      Statenum::NULL,       # # painstate
      0,                    # # painchance
      SFX::None,            # # painsound
      Statenum::NULL,       # # meleestate
      Statenum::NULL,       # # missilestate
      Statenum::NULL,       # # deathstate
      Statenum::NULL,       # # xdeathstate
      SFX::None,            # # deathsound
      0,                    # # speed
      16*FRACUNIT,          # # radius
      16*FRACUNIT,          # # height
      100,                  # # mass
      0,                    # # damage
      SFX::None,            # # activesound
      Mobjflag::SOLID,      # # flags
      Statenum::NULL,       # # raisestate
),

    Mobjinfo.new(           # # MT_MISC33
31,                         # # doomednum
      Statenum::SHRTGRNCOL, # # spawnstate
      1000,                 # # spawnhealth
      Statenum::NULL,       # # seestate
      SFX::None,            # # seesound
      8,                    # # reactiontime
      SFX::None,            # # attacksound
      Statenum::NULL,       # # painstate
      0,                    # # painchance
      SFX::None,            # # painsound
      Statenum::NULL,       # # meleestate
      Statenum::NULL,       # # missilestate
      Statenum::NULL,       # # deathstate
      Statenum::NULL,       # # xdeathstate
      SFX::None,            # # deathsound
      0,                    # # speed
      16*FRACUNIT,          # # radius
      16*FRACUNIT,          # # height
      100,                  # # mass
      0,                    # # damage
      SFX::None,            # # activesound
      Mobjflag::SOLID,      # # flags
      Statenum::NULL,       # # raisestate
),

    Mobjinfo.new(           # # MT_MISC34
32,                         # # doomednum
      Statenum::TALLREDCOL, # # spawnstate
      1000,                 # # spawnhealth
      Statenum::NULL,       # # seestate
      SFX::None,            # # seesound
      8,                    # # reactiontime
      SFX::None,            # # attacksound
      Statenum::NULL,       # # painstate
      0,                    # # painchance
      SFX::None,            # # painsound
      Statenum::NULL,       # # meleestate
      Statenum::NULL,       # # missilestate
      Statenum::NULL,       # # deathstate
      Statenum::NULL,       # # xdeathstate
      SFX::None,            # # deathsound
      0,                    # # speed
      16*FRACUNIT,          # # radius
      16*FRACUNIT,          # # height
      100,                  # # mass
      0,                    # # damage
      SFX::None,            # # activesound
      Mobjflag::SOLID,      # # flags
      Statenum::NULL,       # # raisestate
),

    Mobjinfo.new(           # # MT_MISC35
33,                         # # doomednum
      Statenum::SHRTREDCOL, # # spawnstate
      1000,                 # # spawnhealth
      Statenum::NULL,       # # seestate
      SFX::None,            # # seesound
      8,                    # # reactiontime
      SFX::None,            # # attacksound
      Statenum::NULL,       # # painstate
      0,                    # # painchance
      SFX::None,            # # painsound
      Statenum::NULL,       # # meleestate
      Statenum::NULL,       # # missilestate
      Statenum::NULL,       # # deathstate
      Statenum::NULL,       # # xdeathstate
      SFX::None,            # # deathsound
      0,                    # # speed
      16*FRACUNIT,          # # radius
      16*FRACUNIT,          # # height
      100,                  # # mass
      0,                    # # damage
      SFX::None,            # # activesound
      Mobjflag::SOLID,      # # flags
      Statenum::NULL,       # # raisestate
),

    Mobjinfo.new(         # # MT_MISC36
37,                       # # doomednum
      Statenum::SKULLCOL, # # spawnstate
      1000,               # # spawnhealth
      Statenum::NULL,     # # seestate
      SFX::None,          # # seesound
      8,                  # # reactiontime
      SFX::None,          # # attacksound
      Statenum::NULL,     # # painstate
      0,                  # # painchance
      SFX::None,          # # painsound
      Statenum::NULL,     # # meleestate
      Statenum::NULL,     # # missilestate
      Statenum::NULL,     # # deathstate
      Statenum::NULL,     # # xdeathstate
      SFX::None,          # # deathsound
      0,                  # # speed
      16*FRACUNIT,        # # radius
      16*FRACUNIT,        # # height
      100,                # # mass
      0,                  # # damage
      SFX::None,          # # activesound
      Mobjflag::SOLID,    # # flags
      Statenum::NULL,     # # raisestate
),

    Mobjinfo.new(         # # MT_MISC37
36,                       # # doomednum
      Statenum::HEARTCOL, # # spawnstate
      1000,               # # spawnhealth
      Statenum::NULL,     # # seestate
      SFX::None,          # # seesound
      8,                  # # reactiontime
      SFX::None,          # # attacksound
      Statenum::NULL,     # # painstate
      0,                  # # painchance
      SFX::None,          # # painsound
      Statenum::NULL,     # # meleestate
      Statenum::NULL,     # # missilestate
      Statenum::NULL,     # # deathstate
      Statenum::NULL,     # # xdeathstate
      SFX::None,          # # deathsound
      0,                  # # speed
      16*FRACUNIT,        # # radius
      16*FRACUNIT,        # # height
      100,                # # mass
      0,                  # # damage
      SFX::None,          # # activesound
      Mobjflag::SOLID,    # # flags
      Statenum::NULL,     # # raisestate
),

    Mobjinfo.new(        # # MT_MISC38
41,                      # # doomednum
      Statenum::EVILEYE, # # spawnstate
      1000,              # # spawnhealth
      Statenum::NULL,    # # seestate
      SFX::None,         # # seesound
      8,                 # # reactiontime
      SFX::None,         # # attacksound
      Statenum::NULL,    # # painstate
      0,                 # # painchance
      SFX::None,         # # painsound
      Statenum::NULL,    # # meleestate
      Statenum::NULL,    # # missilestate
      Statenum::NULL,    # # deathstate
      Statenum::NULL,    # # xdeathstate
      SFX::None,         # # deathsound
      0,                 # # speed
      16*FRACUNIT,       # # radius
      16*FRACUNIT,       # # height
      100,               # # mass
      0,                 # # damage
      SFX::None,         # # activesound
      Mobjflag::SOLID,   # # flags
      Statenum::NULL,    # # raisestate
),

    Mobjinfo.new(           # # MT_MISC39
42,                         # # doomednum
      Statenum::FLOATSKULL, # # spawnstate
      1000,                 # # spawnhealth
      Statenum::NULL,       # # seestate
      SFX::None,            # # seesound
      8,                    # # reactiontime
      SFX::None,            # # attacksound
      Statenum::NULL,       # # painstate
      0,                    # # painchance
      SFX::None,            # # painsound
      Statenum::NULL,       # # meleestate
      Statenum::NULL,       # # missilestate
      Statenum::NULL,       # # deathstate
      Statenum::NULL,       # # xdeathstate
      SFX::None,            # # deathsound
      0,                    # # speed
      16*FRACUNIT,          # # radius
      16*FRACUNIT,          # # height
      100,                  # # mass
      0,                    # # damage
      SFX::None,            # # activesound
      Mobjflag::SOLID,      # # flags
      Statenum::NULL,       # # raisestate
),

    Mobjinfo.new(          # # MT_MISC40
43,                        # # doomednum
      Statenum::TORCHTREE, # # spawnstate
      1000,                # # spawnhealth
      Statenum::NULL,      # # seestate
      SFX::None,           # # seesound
      8,                   # # reactiontime
      SFX::None,           # # attacksound
      Statenum::NULL,      # # painstate
      0,                   # # painchance
      SFX::None,           # # painsound
      Statenum::NULL,      # # meleestate
      Statenum::NULL,      # # missilestate
      Statenum::NULL,      # # deathstate
      Statenum::NULL,      # # xdeathstate
      SFX::None,           # # deathsound
      0,                   # # speed
      16*FRACUNIT,         # # radius
      16*FRACUNIT,         # # height
      100,                 # # mass
      0,                   # # damage
      SFX::None,           # # activesound
      Mobjflag::SOLID,     # # flags
      Statenum::NULL,      # # raisestate
),

    Mobjinfo.new(          # # MT_MISC41
44,                        # # doomednum
      Statenum::BLUETORCH, # # spawnstate
      1000,                # # spawnhealth
      Statenum::NULL,      # # seestate
      SFX::None,           # # seesound
      8,                   # # reactiontime
      SFX::None,           # # attacksound
      Statenum::NULL,      # # painstate
      0,                   # # painchance
      SFX::None,           # # painsound
      Statenum::NULL,      # # meleestate
      Statenum::NULL,      # # missilestate
      Statenum::NULL,      # # deathstate
      Statenum::NULL,      # # xdeathstate
      SFX::None,           # # deathsound
      0,                   # # speed
      16*FRACUNIT,         # # radius
      16*FRACUNIT,         # # height
      100,                 # # mass
      0,                   # # damage
      SFX::None,           # # activesound
      Mobjflag::SOLID,     # # flags
      Statenum::NULL,      # # raisestate
),

    Mobjinfo.new(           # # MT_MISC42
45,                         # # doomednum
      Statenum::GREENTORCH, # # spawnstate
      1000,                 # # spawnhealth
      Statenum::NULL,       # # seestate
      SFX::None,            # # seesound
      8,                    # # reactiontime
      SFX::None,            # # attacksound
      Statenum::NULL,       # # painstate
      0,                    # # painchance
      SFX::None,            # # painsound
      Statenum::NULL,       # # meleestate
      Statenum::NULL,       # # missilestate
      Statenum::NULL,       # # deathstate
      Statenum::NULL,       # # xdeathstate
      SFX::None,            # # deathsound
      0,                    # # speed
      16*FRACUNIT,          # # radius
      16*FRACUNIT,          # # height
      100,                  # # mass
      0,                    # # damage
      SFX::None,            # # activesound
      Mobjflag::SOLID,      # # flags
      Statenum::NULL,       # # raisestate
),

    Mobjinfo.new(         # # MT_MISC43
46,                       # # doomednum
      Statenum::REDTORCH, # # spawnstate
      1000,               # # spawnhealth
      Statenum::NULL,     # # seestate
      SFX::None,          # # seesound
      8,                  # # reactiontime
      SFX::None,          # # attacksound
      Statenum::NULL,     # # painstate
      0,                  # # painchance
      SFX::None,          # # painsound
      Statenum::NULL,     # # meleestate
      Statenum::NULL,     # # missilestate
      Statenum::NULL,     # # deathstate
      Statenum::NULL,     # # xdeathstate
      SFX::None,          # # deathsound
      0,                  # # speed
      16*FRACUNIT,        # # radius
      16*FRACUNIT,        # # height
      100,                # # mass
      0,                  # # damage
      SFX::None,          # # activesound
      Mobjflag::SOLID,    # # flags
      Statenum::NULL,     # # raisestate
),

    Mobjinfo.new(           # # MT_MISC44
55,                         # # doomednum
      Statenum::BTORCHSHRT, # # spawnstate
      1000,                 # # spawnhealth
      Statenum::NULL,       # # seestate
      SFX::None,            # # seesound
      8,                    # # reactiontime
      SFX::None,            # # attacksound
      Statenum::NULL,       # # painstate
      0,                    # # painchance
      SFX::None,            # # painsound
      Statenum::NULL,       # # meleestate
      Statenum::NULL,       # # missilestate
      Statenum::NULL,       # # deathstate
      Statenum::NULL,       # # xdeathstate
      SFX::None,            # # deathsound
      0,                    # # speed
      16*FRACUNIT,          # # radius
      16*FRACUNIT,          # # height
      100,                  # # mass
      0,                    # # damage
      SFX::None,            # # activesound
      Mobjflag::SOLID,      # # flags
      Statenum::NULL,       # # raisestate
),

    Mobjinfo.new(           # # MT_MISC45
56,                         # # doomednum
      Statenum::GTORCHSHRT, # # spawnstate
      1000,                 # # spawnhealth
      Statenum::NULL,       # # seestate
      SFX::None,            # # seesound
      8,                    # # reactiontime
      SFX::None,            # # attacksound
      Statenum::NULL,       # # painstate
      0,                    # # painchance
      SFX::None,            # # painsound
      Statenum::NULL,       # # meleestate
      Statenum::NULL,       # # missilestate
      Statenum::NULL,       # # deathstate
      Statenum::NULL,       # # xdeathstate
      SFX::None,            # # deathsound
      0,                    # # speed
      16*FRACUNIT,          # # radius
      16*FRACUNIT,          # # height
      100,                  # # mass
      0,                    # # damage
      SFX::None,            # # activesound
      Mobjflag::SOLID,      # # flags
      Statenum::NULL,       # # raisestate
),

    Mobjinfo.new(           # # MT_MISC46
57,                         # # doomednum
      Statenum::RTORCHSHRT, # # spawnstate
      1000,                 # # spawnhealth
      Statenum::NULL,       # # seestate
      SFX::None,            # # seesound
      8,                    # # reactiontime
      SFX::None,            # # attacksound
      Statenum::NULL,       # # painstate
      0,                    # # painchance
      SFX::None,            # # painsound
      Statenum::NULL,       # # meleestate
      Statenum::NULL,       # # missilestate
      Statenum::NULL,       # # deathstate
      Statenum::NULL,       # # xdeathstate
      SFX::None,            # # deathsound
      0,                    # # speed
      16*FRACUNIT,          # # radius
      16*FRACUNIT,          # # height
      100,                  # # mass
      0,                    # # damage
      SFX::None,            # # activesound
      Mobjflag::SOLID,      # # flags
      Statenum::NULL,       # # raisestate
),

    Mobjinfo.new(           # # MT_MISC47
47,                         # # doomednum
      Statenum::STALAGTITE, # # spawnstate
      1000,                 # # spawnhealth
      Statenum::NULL,       # # seestate
      SFX::None,            # # seesound
      8,                    # # reactiontime
      SFX::None,            # # attacksound
      Statenum::NULL,       # # painstate
      0,                    # # painchance
      SFX::None,            # # painsound
      Statenum::NULL,       # # meleestate
      Statenum::NULL,       # # missilestate
      Statenum::NULL,       # # deathstate
      Statenum::NULL,       # # xdeathstate
      SFX::None,            # # deathsound
      0,                    # # speed
      16*FRACUNIT,          # # radius
      16*FRACUNIT,          # # height
      100,                  # # mass
      0,                    # # damage
      SFX::None,            # # activesound
      Mobjflag::SOLID,      # # flags
      Statenum::NULL,       # # raisestate
),

    Mobjinfo.new(           # # MT_MISC48
48,                         # # doomednum
      Statenum::TECHPILLAR, # # spawnstate
      1000,                 # # spawnhealth
      Statenum::NULL,       # # seestate
      SFX::None,            # # seesound
      8,                    # # reactiontime
      SFX::None,            # # attacksound
      Statenum::NULL,       # # painstate
      0,                    # # painchance
      SFX::None,            # # painsound
      Statenum::NULL,       # # meleestate
      Statenum::NULL,       # # missilestate
      Statenum::NULL,       # # deathstate
      Statenum::NULL,       # # xdeathstate
      SFX::None,            # # deathsound
      0,                    # # speed
      16*FRACUNIT,          # # radius
      16*FRACUNIT,          # # height
      100,                  # # mass
      0,                    # # damage
      SFX::None,            # # activesound
      Mobjflag::SOLID,      # # flags
      Statenum::NULL,       # # raisestate
),

    Mobjinfo.new(           # # MT_MISC49
34,                         # # doomednum
      Statenum::CANDLESTIK, # # spawnstate
      1000,                 # # spawnhealth
      Statenum::NULL,       # # seestate
      SFX::None,            # # seesound
      8,                    # # reactiontime
      SFX::None,            # # attacksound
      Statenum::NULL,       # # painstate
      0,                    # # painchance
      SFX::None,            # # painsound
      Statenum::NULL,       # # meleestate
      Statenum::NULL,       # # missilestate
      Statenum::NULL,       # # deathstate
      Statenum::NULL,       # # xdeathstate
      SFX::None,            # # deathsound
      0,                    # # speed
      20*FRACUNIT,          # # radius
      16*FRACUNIT,          # # height
      100,                  # # mass
      0,                    # # damage
      SFX::None,            # # activesound
      0,                    # # flags
      Statenum::NULL,       # # raisestate
),

    Mobjinfo.new(           # # MT_MISC50
35,                         # # doomednum
      Statenum::CANDELABRA, # # spawnstate
      1000,                 # # spawnhealth
      Statenum::NULL,       # # seestate
      SFX::None,            # # seesound
      8,                    # # reactiontime
      SFX::None,            # # attacksound
      Statenum::NULL,       # # painstate
      0,                    # # painchance
      SFX::None,            # # painsound
      Statenum::NULL,       # # meleestate
      Statenum::NULL,       # # missilestate
      Statenum::NULL,       # # deathstate
      Statenum::NULL,       # # xdeathstate
      SFX::None,            # # deathsound
      0,                    # # speed
      16*FRACUNIT,          # # radius
      16*FRACUNIT,          # # height
      100,                  # # mass
      0,                    # # damage
      SFX::None,            # # activesound
      Mobjflag::SOLID,      # # flags
      Statenum::NULL,       # # raisestate
),

    Mobjinfo.new(                                                     # # MT_MISC51
49,                                                                   # # doomednum
      Statenum::BLOODYTWITCH,                                         # # spawnstate
      1000,                                                           # # spawnhealth
      Statenum::NULL,                                                 # # seestate
      SFX::None,                                                      # # seesound
      8,                                                              # # reactiontime
      SFX::None,                                                      # # attacksound
      Statenum::NULL,                                                 # # painstate
      0,                                                              # # painchance
      SFX::None,                                                      # # painsound
      Statenum::NULL,                                                 # # meleestate
      Statenum::NULL,                                                 # # missilestate
      Statenum::NULL,                                                 # # deathstate
      Statenum::NULL,                                                 # # xdeathstate
      SFX::None,                                                      # # deathsound
      0,                                                              # # speed
      16*FRACUNIT,                                                    # # radius
      68*FRACUNIT,                                                    # # height
      100,                                                            # # mass
      0,                                                              # # damage
      SFX::None,                                                      # # activesound
      Mobjflag::SOLID | Mobjflag::SPAWNCEILING | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                                                 # # raisestate
),

    Mobjinfo.new(                                                     # # MT_MISC52
50,                                                                   # # doomednum
      Statenum::MEAT2,                                                # # spawnstate
      1000,                                                           # # spawnhealth
      Statenum::NULL,                                                 # # seestate
      SFX::None,                                                      # # seesound
      8,                                                              # # reactiontime
      SFX::None,                                                      # # attacksound
      Statenum::NULL,                                                 # # painstate
      0,                                                              # # painchance
      SFX::None,                                                      # # painsound
      Statenum::NULL,                                                 # # meleestate
      Statenum::NULL,                                                 # # missilestate
      Statenum::NULL,                                                 # # deathstate
      Statenum::NULL,                                                 # # xdeathstate
      SFX::None,                                                      # # deathsound
      0,                                                              # # speed
      16*FRACUNIT,                                                    # # radius
      84*FRACUNIT,                                                    # # height
      100,                                                            # # mass
      0,                                                              # # damage
      SFX::None,                                                      # # activesound
      Mobjflag::SOLID | Mobjflag::SPAWNCEILING | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                                                 # # raisestate
),

    Mobjinfo.new(                                                     # # MT_MISC53
51,                                                                   # # doomednum
      Statenum::MEAT3,                                                # # spawnstate
      1000,                                                           # # spawnhealth
      Statenum::NULL,                                                 # # seestate
      SFX::None,                                                      # # seesound
      8,                                                              # # reactiontime
      SFX::None,                                                      # # attacksound
      Statenum::NULL,                                                 # # painstate
      0,                                                              # # painchance
      SFX::None,                                                      # # painsound
      Statenum::NULL,                                                 # # meleestate
      Statenum::NULL,                                                 # # missilestate
      Statenum::NULL,                                                 # # deathstate
      Statenum::NULL,                                                 # # xdeathstate
      SFX::None,                                                      # # deathsound
      0,                                                              # # speed
      16*FRACUNIT,                                                    # # radius
      84*FRACUNIT,                                                    # # height
      100,                                                            # # mass
      0,                                                              # # damage
      SFX::None,                                                      # # activesound
      Mobjflag::SOLID | Mobjflag::SPAWNCEILING | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                                                 # # raisestate
),

    Mobjinfo.new(                                                     # # MT_MISC54
52,                                                                   # # doomednum
      Statenum::MEAT4,                                                # # spawnstate
      1000,                                                           # # spawnhealth
      Statenum::NULL,                                                 # # seestate
      SFX::None,                                                      # # seesound
      8,                                                              # # reactiontime
      SFX::None,                                                      # # attacksound
      Statenum::NULL,                                                 # # painstate
      0,                                                              # # painchance
      SFX::None,                                                      # # painsound
      Statenum::NULL,                                                 # # meleestate
      Statenum::NULL,                                                 # # missilestate
      Statenum::NULL,                                                 # # deathstate
      Statenum::NULL,                                                 # # xdeathstate
      SFX::None,                                                      # # deathsound
      0,                                                              # # speed
      16*FRACUNIT,                                                    # # radius
      68*FRACUNIT,                                                    # # height
      100,                                                            # # mass
      0,                                                              # # damage
      SFX::None,                                                      # # activesound
      Mobjflag::SOLID | Mobjflag::SPAWNCEILING | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                                                 # # raisestate
),

    Mobjinfo.new(                                                     # # MT_MISC55
53,                                                                   # # doomednum
      Statenum::MEAT5,                                                # # spawnstate
      1000,                                                           # # spawnhealth
      Statenum::NULL,                                                 # # seestate
      SFX::None,                                                      # # seesound
      8,                                                              # # reactiontime
      SFX::None,                                                      # # attacksound
      Statenum::NULL,                                                 # # painstate
      0,                                                              # # painchance
      SFX::None,                                                      # # painsound
      Statenum::NULL,                                                 # # meleestate
      Statenum::NULL,                                                 # # missilestate
      Statenum::NULL,                                                 # # deathstate
      Statenum::NULL,                                                 # # xdeathstate
      SFX::None,                                                      # # deathsound
      0,                                                              # # speed
      16*FRACUNIT,                                                    # # radius
      52*FRACUNIT,                                                    # # height
      100,                                                            # # mass
      0,                                                              # # damage
      SFX::None,                                                      # # activesound
      Mobjflag::SOLID | Mobjflag::SPAWNCEILING | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                                                 # # raisestate
),

    Mobjinfo.new(                                   # # MT_MISC56
59,                                                 # # doomednum
      Statenum::MEAT2,                              # # spawnstate
      1000,                                         # # spawnhealth
      Statenum::NULL,                               # # seestate
      SFX::None,                                    # # seesound
      8,                                            # # reactiontime
      SFX::None,                                    # # attacksound
      Statenum::NULL,                               # # painstate
      0,                                            # # painchance
      SFX::None,                                    # # painsound
      Statenum::NULL,                               # # meleestate
      Statenum::NULL,                               # # missilestate
      Statenum::NULL,                               # # deathstate
      Statenum::NULL,                               # # xdeathstate
      SFX::None,                                    # # deathsound
      0,                                            # # speed
      20*FRACUNIT,                                  # # radius
      84*FRACUNIT,                                  # # height
      100,                                          # # mass
      0,                                            # # damage
      SFX::None,                                    # # activesound
      Mobjflag::SPAWNCEILING | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                               # # raisestate
),

    Mobjinfo.new(                                   # # MT_MISC57
60,                                                 # # doomednum
      Statenum::MEAT4,                              # # spawnstate
      1000,                                         # # spawnhealth
      Statenum::NULL,                               # # seestate
      SFX::None,                                    # # seesound
      8,                                            # # reactiontime
      SFX::None,                                    # # attacksound
      Statenum::NULL,                               # # painstate
      0,                                            # # painchance
      SFX::None,                                    # # painsound
      Statenum::NULL,                               # # meleestate
      Statenum::NULL,                               # # missilestate
      Statenum::NULL,                               # # deathstate
      Statenum::NULL,                               # # xdeathstate
      SFX::None,                                    # # deathsound
      0,                                            # # speed
      20*FRACUNIT,                                  # # radius
      68*FRACUNIT,                                  # # height
      100,                                          # # mass
      0,                                            # # damage
      SFX::None,                                    # # activesound
      Mobjflag::SPAWNCEILING | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                               # # raisestate
),

    Mobjinfo.new(                                   # # MT_MISC58
61,                                                 # # doomednum
      Statenum::MEAT3,                              # # spawnstate
      1000,                                         # # spawnhealth
      Statenum::NULL,                               # # seestate
      SFX::None,                                    # # seesound
      8,                                            # # reactiontime
      SFX::None,                                    # # attacksound
      Statenum::NULL,                               # # painstate
      0,                                            # # painchance
      SFX::None,                                    # # painsound
      Statenum::NULL,                               # # meleestate
      Statenum::NULL,                               # # missilestate
      Statenum::NULL,                               # # deathstate
      Statenum::NULL,                               # # xdeathstate
      SFX::None,                                    # # deathsound
      0,                                            # # speed
      20*FRACUNIT,                                  # # radius
      52*FRACUNIT,                                  # # height
      100,                                          # # mass
      0,                                            # # damage
      SFX::None,                                    # # activesound
      Mobjflag::SPAWNCEILING | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                               # # raisestate
),

    Mobjinfo.new(                                   # # MT_MISC59
62,                                                 # # doomednum
      Statenum::MEAT5,                              # # spawnstate
      1000,                                         # # spawnhealth
      Statenum::NULL,                               # # seestate
      SFX::None,                                    # # seesound
      8,                                            # # reactiontime
      SFX::None,                                    # # attacksound
      Statenum::NULL,                               # # painstate
      0,                                            # # painchance
      SFX::None,                                    # # painsound
      Statenum::NULL,                               # # meleestate
      Statenum::NULL,                               # # missilestate
      Statenum::NULL,                               # # deathstate
      Statenum::NULL,                               # # xdeathstate
      SFX::None,                                    # # deathsound
      0,                                            # # speed
      20*FRACUNIT,                                  # # radius
      52*FRACUNIT,                                  # # height
      100,                                          # # mass
      0,                                            # # damage
      SFX::None,                                    # # activesound
      Mobjflag::SPAWNCEILING | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                               # # raisestate
),

    Mobjinfo.new(                                   # # MT_MISC60
63,                                                 # # doomednum
      Statenum::BLOODYTWITCH,                       # # spawnstate
      1000,                                         # # spawnhealth
      Statenum::NULL,                               # # seestate
      SFX::None,                                    # # seesound
      8,                                            # # reactiontime
      SFX::None,                                    # # attacksound
      Statenum::NULL,                               # # painstate
      0,                                            # # painchance
      SFX::None,                                    # # painsound
      Statenum::NULL,                               # # meleestate
      Statenum::NULL,                               # # missilestate
      Statenum::NULL,                               # # deathstate
      Statenum::NULL,                               # # xdeathstate
      SFX::None,                                    # # deathsound
      0,                                            # # speed
      20*FRACUNIT,                                  # # radius
      68*FRACUNIT,                                  # # height
      100,                                          # # mass
      0,                                            # # damage
      SFX::None,                                    # # activesound
      Mobjflag::SPAWNCEILING | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                               # # raisestate
),

    Mobjinfo.new(          # # MT_MISC61
22,                        # # doomednum
      Statenum::HEAD_DIE6, # # spawnstate
      1000,                # # spawnhealth
      Statenum::NULL,      # # seestate
      SFX::None,           # # seesound
      8,                   # # reactiontime
      SFX::None,           # # attacksound
      Statenum::NULL,      # # painstate
      0,                   # # painchance
      SFX::None,           # # painsound
      Statenum::NULL,      # # meleestate
      Statenum::NULL,      # # missilestate
      Statenum::NULL,      # # deathstate
      Statenum::NULL,      # # xdeathstate
      SFX::None,           # # deathsound
      0,                   # # speed
      20*FRACUNIT,         # # radius
      16*FRACUNIT,         # # height
      100,                 # # mass
      0,                   # # damage
      SFX::None,           # # activesound
      0,                   # # flags
      Statenum::NULL,      # # raisestate
),

    Mobjinfo.new(          # # MT_MISC62
15,                        # # doomednum
      Statenum::PLAY_DIE7, # # spawnstate
      1000,                # # spawnhealth
      Statenum::NULL,      # # seestate
      SFX::None,           # # seesound
      8,                   # # reactiontime
      SFX::None,           # # attacksound
      Statenum::NULL,      # # painstate
      0,                   # # painchance
      SFX::None,           # # painsound
      Statenum::NULL,      # # meleestate
      Statenum::NULL,      # # missilestate
      Statenum::NULL,      # # deathstate
      Statenum::NULL,      # # xdeathstate
      SFX::None,           # # deathsound
      0,                   # # speed
      20*FRACUNIT,         # # radius
      16*FRACUNIT,         # # height
      100,                 # # mass
      0,                   # # damage
      SFX::None,           # # activesound
      0,                   # # flags
      Statenum::NULL,      # # raisestate
),

    Mobjinfo.new(          # # MT_MISC63
18,                        # # doomednum
      Statenum::POSS_DIE5, # # spawnstate
      1000,                # # spawnhealth
      Statenum::NULL,      # # seestate
      SFX::None,           # # seesound
      8,                   # # reactiontime
      SFX::None,           # # attacksound
      Statenum::NULL,      # # painstate
      0,                   # # painchance
      SFX::None,           # # painsound
      Statenum::NULL,      # # meleestate
      Statenum::NULL,      # # missilestate
      Statenum::NULL,      # # deathstate
      Statenum::NULL,      # # xdeathstate
      SFX::None,           # # deathsound
      0,                   # # speed
      20*FRACUNIT,         # # radius
      16*FRACUNIT,         # # height
      100,                 # # mass
      0,                   # # damage
      SFX::None,           # # activesound
      0,                   # # flags
      Statenum::NULL,      # # raisestate
),

    Mobjinfo.new(          # # MT_MISC64
21,                        # # doomednum
      Statenum::SARG_DIE6, # # spawnstate
      1000,                # # spawnhealth
      Statenum::NULL,      # # seestate
      SFX::None,           # # seesound
      8,                   # # reactiontime
      SFX::None,           # # attacksound
      Statenum::NULL,      # # painstate
      0,                   # # painchance
      SFX::None,           # # painsound
      Statenum::NULL,      # # meleestate
      Statenum::NULL,      # # missilestate
      Statenum::NULL,      # # deathstate
      Statenum::NULL,      # # xdeathstate
      SFX::None,           # # deathsound
      0,                   # # speed
      20*FRACUNIT,         # # radius
      16*FRACUNIT,         # # height
      100,                 # # mass
      0,                   # # damage
      SFX::None,           # # activesound
      0,                   # # flags
      Statenum::NULL,      # # raisestate
),

    Mobjinfo.new(           # # MT_MISC65
23,                         # # doomednum
      Statenum::SKULL_DIE6, # # spawnstate
      1000,                 # # spawnhealth
      Statenum::NULL,       # # seestate
      SFX::None,            # # seesound
      8,                    # # reactiontime
      SFX::None,            # # attacksound
      Statenum::NULL,       # # painstate
      0,                    # # painchance
      SFX::None,            # # painsound
      Statenum::NULL,       # # meleestate
      Statenum::NULL,       # # missilestate
      Statenum::NULL,       # # deathstate
      Statenum::NULL,       # # xdeathstate
      SFX::None,            # # deathsound
      0,                    # # speed
      20*FRACUNIT,          # # radius
      16*FRACUNIT,          # # height
      100,                  # # mass
      0,                    # # damage
      SFX::None,            # # activesound
      0,                    # # flags
      Statenum::NULL,       # # raisestate
),

    Mobjinfo.new(          # # MT_MISC66
20,                        # # doomednum
      Statenum::TROO_DIE5, # # spawnstate
      1000,                # # spawnhealth
      Statenum::NULL,      # # seestate
      SFX::None,           # # seesound
      8,                   # # reactiontime
      SFX::None,           # # attacksound
      Statenum::NULL,      # # painstate
      0,                   # # painchance
      SFX::None,           # # painsound
      Statenum::NULL,      # # meleestate
      Statenum::NULL,      # # missilestate
      Statenum::NULL,      # # deathstate
      Statenum::NULL,      # # xdeathstate
      SFX::None,           # # deathsound
      0,                   # # speed
      20*FRACUNIT,         # # radius
      16*FRACUNIT,         # # height
      100,                 # # mass
      0,                   # # damage
      SFX::None,           # # activesound
      0,                   # # flags
      Statenum::NULL,      # # raisestate
),

    Mobjinfo.new(          # # MT_MISC67
19,                        # # doomednum
      Statenum::SPOS_DIE5, # # spawnstate
      1000,                # # spawnhealth
      Statenum::NULL,      # # seestate
      SFX::None,           # # seesound
      8,                   # # reactiontime
      SFX::None,           # # attacksound
      Statenum::NULL,      # # painstate
      0,                   # # painchance
      SFX::None,           # # painsound
      Statenum::NULL,      # # meleestate
      Statenum::NULL,      # # missilestate
      Statenum::NULL,      # # deathstate
      Statenum::NULL,      # # xdeathstate
      SFX::None,           # # deathsound
      0,                   # # speed
      20*FRACUNIT,         # # radius
      16*FRACUNIT,         # # height
      100,                 # # mass
      0,                   # # damage
      SFX::None,           # # activesound
      0,                   # # flags
      Statenum::NULL,      # # raisestate
),

    Mobjinfo.new(           # # MT_MISC68
10,                         # # doomednum
      Statenum::PLAY_XDIE9, # # spawnstate
      1000,                 # # spawnhealth
      Statenum::NULL,       # # seestate
      SFX::None,            # # seesound
      8,                    # # reactiontime
      SFX::None,            # # attacksound
      Statenum::NULL,       # # painstate
      0,                    # # painchance
      SFX::None,            # # painsound
      Statenum::NULL,       # # meleestate
      Statenum::NULL,       # # missilestate
      Statenum::NULL,       # # deathstate
      Statenum::NULL,       # # xdeathstate
      SFX::None,            # # deathsound
      0,                    # # speed
      20*FRACUNIT,          # # radius
      16*FRACUNIT,          # # height
      100,                  # # mass
      0,                    # # damage
      SFX::None,            # # activesound
      0,                    # # flags
      Statenum::NULL,       # # raisestate
),

    Mobjinfo.new(           # # MT_MISC69
12,                         # # doomednum
      Statenum::PLAY_XDIE9, # # spawnstate
      1000,                 # # spawnhealth
      Statenum::NULL,       # # seestate
      SFX::None,            # # seesound
      8,                    # # reactiontime
      SFX::None,            # # attacksound
      Statenum::NULL,       # # painstate
      0,                    # # painchance
      SFX::None,            # # painsound
      Statenum::NULL,       # # meleestate
      Statenum::NULL,       # # missilestate
      Statenum::NULL,       # # deathstate
      Statenum::NULL,       # # xdeathstate
      SFX::None,            # # deathsound
      0,                    # # speed
      20*FRACUNIT,          # # radius
      16*FRACUNIT,          # # height
      100,                  # # mass
      0,                    # # damage
      SFX::None,            # # activesound
      0,                    # # flags
      Statenum::NULL,       # # raisestate
),

    Mobjinfo.new(             # # MT_MISC70
28,                           # # doomednum
      Statenum::HEADSONSTICK, # # spawnstate
      1000,                   # # spawnhealth
      Statenum::NULL,         # # seestate
      SFX::None,              # # seesound
      8,                      # # reactiontime
      SFX::None,              # # attacksound
      Statenum::NULL,         # # painstate
      0,                      # # painchance
      SFX::None,              # # painsound
      Statenum::NULL,         # # meleestate
      Statenum::NULL,         # # missilestate
      Statenum::NULL,         # # deathstate
      Statenum::NULL,         # # xdeathstate
      SFX::None,              # # deathsound
      0,                      # # speed
      16*FRACUNIT,            # # radius
      16*FRACUNIT,            # # height
      100,                    # # mass
      0,                      # # damage
      SFX::None,              # # activesound
      Mobjflag::SOLID,        # # flags
      Statenum::NULL,         # # raisestate
),

    Mobjinfo.new(     # # MT_MISC71
24,                   # # doomednum
      Statenum::GIBS, # # spawnstate
      1000,           # # spawnhealth
      Statenum::NULL, # # seestate
      SFX::None,      # # seesound
      8,              # # reactiontime
      SFX::None,      # # attacksound
      Statenum::NULL, # # painstate
      0,              # # painchance
      SFX::None,      # # painsound
      Statenum::NULL, # # meleestate
      Statenum::NULL, # # missilestate
      Statenum::NULL, # # deathstate
      Statenum::NULL, # # xdeathstate
      SFX::None,      # # deathsound
      0,              # # speed
      20*FRACUNIT,    # # radius
      16*FRACUNIT,    # # height
      100,            # # mass
      0,              # # damage
      SFX::None,      # # activesound
      0,              # # flags
      Statenum::NULL, # # raisestate
),

    Mobjinfo.new(             # # MT_MISC72
27,                           # # doomednum
      Statenum::HEADONASTICK, # # spawnstate
      1000,                   # # spawnhealth
      Statenum::NULL,         # # seestate
      SFX::None,              # # seesound
      8,                      # # reactiontime
      SFX::None,              # # attacksound
      Statenum::NULL,         # # painstate
      0,                      # # painchance
      SFX::None,              # # painsound
      Statenum::NULL,         # # meleestate
      Statenum::NULL,         # # missilestate
      Statenum::NULL,         # # deathstate
      Statenum::NULL,         # # xdeathstate
      SFX::None,              # # deathsound
      0,                      # # speed
      16*FRACUNIT,            # # radius
      16*FRACUNIT,            # # height
      100,                    # # mass
      0,                      # # damage
      SFX::None,              # # activesound
      Mobjflag::SOLID,        # # flags
      Statenum::NULL,         # # raisestate
),

    Mobjinfo.new(            # # MT_MISC73
29,                          # # doomednum
      Statenum::HEADCANDLES, # # spawnstate
      1000,                  # # spawnhealth
      Statenum::NULL,        # # seestate
      SFX::None,             # # seesound
      8,                     # # reactiontime
      SFX::None,             # # attacksound
      Statenum::NULL,        # # painstate
      0,                     # # painchance
      SFX::None,             # # painsound
      Statenum::NULL,        # # meleestate
      Statenum::NULL,        # # missilestate
      Statenum::NULL,        # # deathstate
      Statenum::NULL,        # # xdeathstate
      SFX::None,             # # deathsound
      0,                     # # speed
      16*FRACUNIT,           # # radius
      16*FRACUNIT,           # # height
      100,                   # # mass
      0,                     # # damage
      SFX::None,             # # activesound
      Mobjflag::SOLID,       # # flags
      Statenum::NULL,        # # raisestate
),

    Mobjinfo.new(          # # MT_MISC74
25,                        # # doomednum
      Statenum::DEADSTICK, # # spawnstate
      1000,                # # spawnhealth
      Statenum::NULL,      # # seestate
      SFX::None,           # # seesound
      8,                   # # reactiontime
      SFX::None,           # # attacksound
      Statenum::NULL,      # # painstate
      0,                   # # painchance
      SFX::None,           # # painsound
      Statenum::NULL,      # # meleestate
      Statenum::NULL,      # # missilestate
      Statenum::NULL,      # # deathstate
      Statenum::NULL,      # # xdeathstate
      SFX::None,           # # deathsound
      0,                   # # speed
      16*FRACUNIT,         # # radius
      16*FRACUNIT,         # # height
      100,                 # # mass
      0,                   # # damage
      SFX::None,           # # activesound
      Mobjflag::SOLID,     # # flags
      Statenum::NULL,      # # raisestate
),

    Mobjinfo.new(          # # MT_MISC75
26,                        # # doomednum
      Statenum::LIVESTICK, # # spawnstate
      1000,                # # spawnhealth
      Statenum::NULL,      # # seestate
      SFX::None,           # # seesound
      8,                   # # reactiontime
      SFX::None,           # # attacksound
      Statenum::NULL,      # # painstate
      0,                   # # painchance
      SFX::None,           # # painsound
      Statenum::NULL,      # # meleestate
      Statenum::NULL,      # # missilestate
      Statenum::NULL,      # # deathstate
      Statenum::NULL,      # # xdeathstate
      SFX::None,           # # deathsound
      0,                   # # speed
      16*FRACUNIT,         # # radius
      16*FRACUNIT,         # # height
      100,                 # # mass
      0,                   # # damage
      SFX::None,           # # activesound
      Mobjflag::SOLID,     # # flags
      Statenum::NULL,      # # raisestate
),

    Mobjinfo.new(        # # MT_MISC76
54,                      # # doomednum
      Statenum::BIGTREE, # # spawnstate
      1000,              # # spawnhealth
      Statenum::NULL,    # # seestate
      SFX::None,         # # seesound
      8,                 # # reactiontime
      SFX::None,         # # attacksound
      Statenum::NULL,    # # painstate
      0,                 # # painchance
      SFX::None,         # # painsound
      Statenum::NULL,    # # meleestate
      Statenum::NULL,    # # missilestate
      Statenum::NULL,    # # deathstate
      Statenum::NULL,    # # xdeathstate
      SFX::None,         # # deathsound
      0,                 # # speed
      32*FRACUNIT,       # # radius
      16*FRACUNIT,       # # height
      100,               # # mass
      0,                 # # damage
      SFX::None,         # # activesound
      Mobjflag::SOLID,   # # flags
      Statenum::NULL,    # # raisestate
),

    Mobjinfo.new(      # # MT_MISC77
70,                    # # doomednum
      Statenum::BBAR1, # # spawnstate
      1000,            # # spawnhealth
      Statenum::NULL,  # # seestate
      SFX::None,       # # seesound
      8,               # # reactiontime
      SFX::None,       # # attacksound
      Statenum::NULL,  # # painstate
      0,               # # painchance
      SFX::None,       # # painsound
      Statenum::NULL,  # # meleestate
      Statenum::NULL,  # # missilestate
      Statenum::NULL,  # # deathstate
      Statenum::NULL,  # # xdeathstate
      SFX::None,       # # deathsound
      0,               # # speed
      16*FRACUNIT,     # # radius
      16*FRACUNIT,     # # height
      100,             # # mass
      0,               # # damage
      SFX::None,       # # activesound
      Mobjflag::SOLID, # # flags
      Statenum::NULL,  # # raisestate
),

    Mobjinfo.new(                                                     # # MT_MISC78
73,                                                                   # # doomednum
      Statenum::HANGNOGUTS,                                           # # spawnstate
      1000,                                                           # # spawnhealth
      Statenum::NULL,                                                 # # seestate
      SFX::None,                                                      # # seesound
      8,                                                              # # reactiontime
      SFX::None,                                                      # # attacksound
      Statenum::NULL,                                                 # # painstate
      0,                                                              # # painchance
      SFX::None,                                                      # # painsound
      Statenum::NULL,                                                 # # meleestate
      Statenum::NULL,                                                 # # missilestate
      Statenum::NULL,                                                 # # deathstate
      Statenum::NULL,                                                 # # xdeathstate
      SFX::None,                                                      # # deathsound
      0,                                                              # # speed
      16*FRACUNIT,                                                    # # radius
      88*FRACUNIT,                                                    # # height
      100,                                                            # # mass
      0,                                                              # # damage
      SFX::None,                                                      # # activesound
      Mobjflag::SOLID | Mobjflag::SPAWNCEILING | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                                                 # # raisestate
),

    Mobjinfo.new(                                                     # # MT_MISC79
74,                                                                   # # doomednum
      Statenum::HANGBNOBRAIN,                                         # # spawnstate
      1000,                                                           # # spawnhealth
      Statenum::NULL,                                                 # # seestate
      SFX::None,                                                      # # seesound
      8,                                                              # # reactiontime
      SFX::None,                                                      # # attacksound
      Statenum::NULL,                                                 # # painstate
      0,                                                              # # painchance
      SFX::None,                                                      # # painsound
      Statenum::NULL,                                                 # # meleestate
      Statenum::NULL,                                                 # # missilestate
      Statenum::NULL,                                                 # # deathstate
      Statenum::NULL,                                                 # # xdeathstate
      SFX::None,                                                      # # deathsound
      0,                                                              # # speed
      16*FRACUNIT,                                                    # # radius
      88*FRACUNIT,                                                    # # height
      100,                                                            # # mass
      0,                                                              # # damage
      SFX::None,                                                      # # activesound
      Mobjflag::SOLID | Mobjflag::SPAWNCEILING | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                                                 # # raisestate
),

    Mobjinfo.new(                                                     # # MT_MISC80
75,                                                                   # # doomednum
      Statenum::HANGTLOOKDN,                                          # # spawnstate
      1000,                                                           # # spawnhealth
      Statenum::NULL,                                                 # # seestate
      SFX::None,                                                      # # seesound
      8,                                                              # # reactiontime
      SFX::None,                                                      # # attacksound
      Statenum::NULL,                                                 # # painstate
      0,                                                              # # painchance
      SFX::None,                                                      # # painsound
      Statenum::NULL,                                                 # # meleestate
      Statenum::NULL,                                                 # # missilestate
      Statenum::NULL,                                                 # # deathstate
      Statenum::NULL,                                                 # # xdeathstate
      SFX::None,                                                      # # deathsound
      0,                                                              # # speed
      16*FRACUNIT,                                                    # # radius
      64*FRACUNIT,                                                    # # height
      100,                                                            # # mass
      0,                                                              # # damage
      SFX::None,                                                      # # activesound
      Mobjflag::SOLID | Mobjflag::SPAWNCEILING | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                                                 # # raisestate
),

    Mobjinfo.new(                                                     # # MT_MISC81
76,                                                                   # # doomednum
      Statenum::HANGTSKULL,                                           # # spawnstate
      1000,                                                           # # spawnhealth
      Statenum::NULL,                                                 # # seestate
      SFX::None,                                                      # # seesound
      8,                                                              # # reactiontime
      SFX::None,                                                      # # attacksound
      Statenum::NULL,                                                 # # painstate
      0,                                                              # # painchance
      SFX::None,                                                      # # painsound
      Statenum::NULL,                                                 # # meleestate
      Statenum::NULL,                                                 # # missilestate
      Statenum::NULL,                                                 # # deathstate
      Statenum::NULL,                                                 # # xdeathstate
      SFX::None,                                                      # # deathsound
      0,                                                              # # speed
      16*FRACUNIT,                                                    # # radius
      64*FRACUNIT,                                                    # # height
      100,                                                            # # mass
      0,                                                              # # damage
      SFX::None,                                                      # # activesound
      Mobjflag::SOLID | Mobjflag::SPAWNCEILING | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                                                 # # raisestate
),

    Mobjinfo.new(                                                     # # MT_MISC82
77,                                                                   # # doomednum
      Statenum::HANGTLOOKUP,                                          # # spawnstate
      1000,                                                           # # spawnhealth
      Statenum::NULL,                                                 # # seestate
      SFX::None,                                                      # # seesound
      8,                                                              # # reactiontime
      SFX::None,                                                      # # attacksound
      Statenum::NULL,                                                 # # painstate
      0,                                                              # # painchance
      SFX::None,                                                      # # painsound
      Statenum::NULL,                                                 # # meleestate
      Statenum::NULL,                                                 # # missilestate
      Statenum::NULL,                                                 # # deathstate
      Statenum::NULL,                                                 # # xdeathstate
      SFX::None,                                                      # # deathsound
      0,                                                              # # speed
      16*FRACUNIT,                                                    # # radius
      64*FRACUNIT,                                                    # # height
      100,                                                            # # mass
      0,                                                              # # damage
      SFX::None,                                                      # # activesound
      Mobjflag::SOLID | Mobjflag::SPAWNCEILING | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                                                 # # raisestate
),

    Mobjinfo.new(                                                     # # MT_MISC83
78,                                                                   # # doomednum
      Statenum::HANGTNOBRAIN,                                         # # spawnstate
      1000,                                                           # # spawnhealth
      Statenum::NULL,                                                 # # seestate
      SFX::None,                                                      # # seesound
      8,                                                              # # reactiontime
      SFX::None,                                                      # # attacksound
      Statenum::NULL,                                                 # # painstate
      0,                                                              # # painchance
      SFX::None,                                                      # # painsound
      Statenum::NULL,                                                 # # meleestate
      Statenum::NULL,                                                 # # missilestate
      Statenum::NULL,                                                 # # deathstate
      Statenum::NULL,                                                 # # xdeathstate
      SFX::None,                                                      # # deathsound
      0,                                                              # # speed
      16*FRACUNIT,                                                    # # radius
      64*FRACUNIT,                                                    # # height
      100,                                                            # # mass
      0,                                                              # # damage
      SFX::None,                                                      # # activesound
      Mobjflag::SOLID | Mobjflag::SPAWNCEILING | Mobjflag::NOGRAVITY, # # flags
      Statenum::NULL,                                                 # # raisestate
),

    Mobjinfo.new(           # # MT_MISC84
79,                         # # doomednum
      Statenum::COLONGIBS,  # # spawnstate
      1000,                 # # spawnhealth
      Statenum::NULL,       # # seestate
      SFX::None,            # # seesound
      8,                    # # reactiontime
      SFX::None,            # # attacksound
      Statenum::NULL,       # # painstate
      0,                    # # painchance
      SFX::None,            # # painsound
      Statenum::NULL,       # # meleestate
      Statenum::NULL,       # # missilestate
      Statenum::NULL,       # # deathstate
      Statenum::NULL,       # # xdeathstate
      SFX::None,            # # deathsound
      0,                    # # speed
      20*FRACUNIT,          # # radius
      16*FRACUNIT,          # # height
      100,                  # # mass
      0,                    # # damage
      SFX::None,            # # activesound
      Mobjflag::NOBLOCKMAP, # # flags
      Statenum::NULL,       # # raisestate
),

    Mobjinfo.new(           # # MT_MISC85
80,                         # # doomednum
      Statenum::SMALLPOOL,  # # spawnstate
      1000,                 # # spawnhealth
      Statenum::NULL,       # # seestate
      SFX::None,            # # seesound
      8,                    # # reactiontime
      SFX::None,            # # attacksound
      Statenum::NULL,       # # painstate
      0,                    # # painchance
      SFX::None,            # # painsound
      Statenum::NULL,       # # meleestate
      Statenum::NULL,       # # missilestate
      Statenum::NULL,       # # deathstate
      Statenum::NULL,       # # xdeathstate
      SFX::None,            # # deathsound
      0,                    # # speed
      20*FRACUNIT,          # # radius
      16*FRACUNIT,          # # height
      100,                  # # mass
      0,                    # # damage
      SFX::None,            # # activesound
      Mobjflag::NOBLOCKMAP, # # flags
      Statenum::NULL,       # # raisestate
),

    Mobjinfo.new(           # # MT_MISC86
81,                         # # doomednum
      Statenum::BRAINSTEM,  # # spawnstate
      1000,                 # # spawnhealth
      Statenum::NULL,       # # seestate
      SFX::None,            # # seesound
      8,                    # # reactiontime
      SFX::None,            # # attacksound
      Statenum::NULL,       # # painstate
      0,                    # # painchance
      SFX::None,            # # painsound
      Statenum::NULL,       # # meleestate
      Statenum::NULL,       # # missilestate
      Statenum::NULL,       # # deathstate
      Statenum::NULL,       # # xdeathstate
      SFX::None,            # # deathsound
      0,                    # # speed
      20*FRACUNIT,          # # radius
      16*FRACUNIT,          # # height
      100,                  # # mass
      0,                    # # damage
      SFX::None,            # # activesound
      Mobjflag::NOBLOCKMAP, # # flags
      Statenum::NULL,       # # raisestate
),
  ]

  @@states : Array(State) = [
    State.new(Spritenum::TROO, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::NULL
    State.new(Spritenum::SHTG, 4, 0, ->a_Light0, Statenum::NULL, 0, 0),                # Statenum::LIGHTDONE
    State.new(Spritenum::PUNG, 0, 1, ->a_WeaponReady, Statenum::PUNCH, 0, 0),          # Statenum::PUNCH
    State.new(Spritenum::PUNG, 0, 1, ->a_Lower, Statenum::PUNCHDOWN, 0, 0),            # Statenum::PUNCHDOWN
    State.new(Spritenum::PUNG, 0, 1, ->a_Raise, Statenum::PUNCHUP, 0, 0),              # Statenum::PUNCHUP
    State.new(Spritenum::PUNG, 1, 4, nil, Statenum::PUNCH2, 0, 0),                     # Statenum::PUNCH1
    State.new(Spritenum::PUNG, 2, 4, ->a_Punch, Statenum::PUNCH3, 0, 0),               # Statenum::PUNCH2
    State.new(Spritenum::PUNG, 3, 5, nil, Statenum::PUNCH4, 0, 0),                     # Statenum::PUNCH3
    State.new(Spritenum::PUNG, 2, 4, nil, Statenum::PUNCH5, 0, 0),                     # Statenum::PUNCH4
    State.new(Spritenum::PUNG, 1, 5, ->a_ReFire, Statenum::PUNCH, 0, 0),               # Statenum::PUNCH5
    State.new(Spritenum::PISG, 0, 1, ->a_WeaponReady, Statenum::PISTOL, 0, 0),         # Statenum::PISTOL
    State.new(Spritenum::PISG, 0, 1, ->a_Lower, Statenum::PISTOLDOWN, 0, 0),           # Statenum::PISTOLDOWN
    State.new(Spritenum::PISG, 0, 1, ->a_Raise, Statenum::PISTOLUP, 0, 0),             # Statenum::PISTOLUP
    State.new(Spritenum::PISG, 0, 4, nil, Statenum::PISTOL2, 0, 0),                    # Statenum::PISTOL1
    State.new(Spritenum::PISG, 1, 6, ->a_FirePistol, Statenum::PISTOL3, 0, 0),         # Statenum::PISTOL2
    State.new(Spritenum::PISG, 2, 4, nil, Statenum::PISTOL4, 0, 0),                    # Statenum::PISTOL3
    State.new(Spritenum::PISG, 1, 5, ->a_ReFire, Statenum::PISTOL, 0, 0),              # Statenum::PISTOL4
    State.new(Spritenum::PISF, 32768, 7, ->a_Light1, Statenum::LIGHTDONE, 0, 0),       # Statenum::PISTOLFLASH
    State.new(Spritenum::SHTG, 0, 1, ->a_WeaponReady, Statenum::SGUN, 0, 0),           # Statenum::SGUN
    State.new(Spritenum::SHTG, 0, 1, ->a_Lower, Statenum::SGUNDOWN, 0, 0),             # Statenum::SGUNDOWN
    State.new(Spritenum::SHTG, 0, 1, ->a_Raise, Statenum::SGUNUP, 0, 0),               # Statenum::SGUNUP
    State.new(Spritenum::SHTG, 0, 3, nil, Statenum::SGUN2, 0, 0),                      # Statenum::SGUN1
    State.new(Spritenum::SHTG, 0, 7, ->a_FireShotgun, Statenum::SGUN3, 0, 0),          # Statenum::SGUN2
    State.new(Spritenum::SHTG, 1, 5, nil, Statenum::SGUN4, 0, 0),                      # Statenum::SGUN3
    State.new(Spritenum::SHTG, 2, 5, nil, Statenum::SGUN5, 0, 0),                      # Statenum::SGUN4
    State.new(Spritenum::SHTG, 3, 4, nil, Statenum::SGUN6, 0, 0),                      # Statenum::SGUN5
    State.new(Spritenum::SHTG, 2, 5, nil, Statenum::SGUN7, 0, 0),                      # Statenum::SGUN6
    State.new(Spritenum::SHTG, 1, 5, nil, Statenum::SGUN8, 0, 0),                      # Statenum::SGUN7
    State.new(Spritenum::SHTG, 0, 3, nil, Statenum::SGUN9, 0, 0),                      # Statenum::SGUN8
    State.new(Spritenum::SHTG, 0, 7, ->a_ReFire, Statenum::SGUN, 0, 0),                # Statenum::SGUN9
    State.new(Spritenum::SHTF, 32768, 4, ->a_Light1, Statenum::SGUNFLASH2, 0, 0),      # Statenum::SGUNFLASH1
    State.new(Spritenum::SHTF, 32769, 3, ->a_Light2, Statenum::LIGHTDONE, 0, 0),       # Statenum::SGUNFLASH2
    State.new(Spritenum::SHT2, 0, 1, ->a_WeaponReady, Statenum::DSGUN, 0, 0),          # Statenum::DSGUN
    State.new(Spritenum::SHT2, 0, 1, ->a_Lower, Statenum::DSGUNDOWN, 0, 0),            # Statenum::DSGUNDOWN
    State.new(Spritenum::SHT2, 0, 1, ->a_Raise, Statenum::DSGUNUP, 0, 0),              # Statenum::DSGUNUP
    State.new(Spritenum::SHT2, 0, 3, nil, Statenum::DSGUN2, 0, 0),                     # Statenum::DSGUN1
    State.new(Spritenum::SHT2, 0, 7, ->a_FireShotgun2, Statenum::DSGUN3, 0, 0),        # Statenum::DSGUN2
    State.new(Spritenum::SHT2, 1, 7, nil, Statenum::DSGUN4, 0, 0),                     # Statenum::DSGUN3
    State.new(Spritenum::SHT2, 2, 7, ->a_CheckReload, Statenum::DSGUN5, 0, 0),         # Statenum::DSGUN4
    State.new(Spritenum::SHT2, 3, 7, ->a_OpenShotgun2, Statenum::DSGUN6, 0, 0),        # Statenum::DSGUN5
    State.new(Spritenum::SHT2, 4, 7, nil, Statenum::DSGUN7, 0, 0),                     # Statenum::DSGUN6
    State.new(Spritenum::SHT2, 5, 7, ->a_LoadShotgun2, Statenum::DSGUN8, 0, 0),        # Statenum::DSGUN7
    State.new(Spritenum::SHT2, 6, 6, nil, Statenum::DSGUN9, 0, 0),                     # Statenum::DSGUN8
    State.new(Spritenum::SHT2, 7, 6, ->a_CloseShotgun2, Statenum::DSGUN10, 0, 0),      # Statenum::DSGUN9
    State.new(Spritenum::SHT2, 0, 5, ->a_ReFire, Statenum::DSGUN, 0, 0),               # Statenum::DSGUN10
    State.new(Spritenum::SHT2, 1, 7, nil, Statenum::DSNR2, 0, 0),                      # Statenum::DSNR1
    State.new(Spritenum::SHT2, 0, 3, nil, Statenum::DSGUNDOWN, 0, 0),                  # Statenum::DSNR2
    State.new(Spritenum::SHT2, 32776, 5, ->a_Light1, Statenum::DSGUNFLASH2, 0, 0),     # Statenum::DSGUNFLASH1
    State.new(Spritenum::SHT2, 32777, 4, ->a_Light2, Statenum::LIGHTDONE, 0, 0),       # Statenum::DSGUNFLASH2
    State.new(Spritenum::CHGG, 0, 1, ->a_WeaponReady, Statenum::CHAIN, 0, 0),          # Statenum::CHAIN
    State.new(Spritenum::CHGG, 0, 1, ->a_Lower, Statenum::CHAINDOWN, 0, 0),            # Statenum::CHAINDOWN
    State.new(Spritenum::CHGG, 0, 1, ->a_Raise, Statenum::CHAINUP, 0, 0),              # Statenum::CHAINUP
    State.new(Spritenum::CHGG, 0, 4, ->a_FireCGun, Statenum::CHAIN2, 0, 0),            # Statenum::CHAIN1
    State.new(Spritenum::CHGG, 1, 4, ->a_FireCGun, Statenum::CHAIN3, 0, 0),            # Statenum::CHAIN2
    State.new(Spritenum::CHGG, 1, 0, ->a_ReFire, Statenum::CHAIN, 0, 0),               # Statenum::CHAIN3
    State.new(Spritenum::CHGF, 32768, 5, ->a_Light1, Statenum::LIGHTDONE, 0, 0),       # Statenum::CHAINFLASH1
    State.new(Spritenum::CHGF, 32769, 5, ->a_Light2, Statenum::LIGHTDONE, 0, 0),       # Statenum::CHAINFLASH2
    State.new(Spritenum::MISG, 0, 1, ->a_WeaponReady, Statenum::MISSILE, 0, 0),        # Statenum::MISSILE
    State.new(Spritenum::MISG, 0, 1, ->a_Lower, Statenum::MISSILEDOWN, 0, 0),          # Statenum::MISSILEDOWN
    State.new(Spritenum::MISG, 0, 1, ->a_Raise, Statenum::MISSILEUP, 0, 0),            # Statenum::MISSILEUP
    State.new(Spritenum::MISG, 1, 8, ->a_GunFlash, Statenum::MISSILE2, 0, 0),          # Statenum::MISSILE1
    State.new(Spritenum::MISG, 1, 12, ->a_FireMissile, Statenum::MISSILE3, 0, 0),      # Statenum::MISSILE2
    State.new(Spritenum::MISG, 1, 0, ->a_ReFire, Statenum::MISSILE, 0, 0),             # Statenum::MISSILE3
    State.new(Spritenum::MISF, 32768, 3, ->a_Light1, Statenum::MISSILEFLASH2, 0, 0),   # Statenum::MISSILEFLASH1
    State.new(Spritenum::MISF, 32769, 4, nil, Statenum::MISSILEFLASH3, 0, 0),          # Statenum::MISSILEFLASH2
    State.new(Spritenum::MISF, 32770, 4, ->a_Light2, Statenum::MISSILEFLASH4, 0, 0),   # Statenum::MISSILEFLASH3
    State.new(Spritenum::MISF, 32771, 4, ->a_Light2, Statenum::LIGHTDONE, 0, 0),       # Statenum::MISSILEFLASH4
    State.new(Spritenum::SAWG, 2, 4, ->a_WeaponReady, Statenum::SAWB, 0, 0),           # Statenum::SAW
    State.new(Spritenum::SAWG, 3, 4, ->a_WeaponReady, Statenum::SAW, 0, 0),            # Statenum::SAWB
    State.new(Spritenum::SAWG, 2, 1, ->a_Lower, Statenum::SAWDOWN, 0, 0),              # Statenum::SAWDOWN
    State.new(Spritenum::SAWG, 2, 1, ->a_Raise, Statenum::SAWUP, 0, 0),                # Statenum::SAWUP
    State.new(Spritenum::SAWG, 0, 4, ->a_Saw, Statenum::SAW2, 0, 0),                   # Statenum::SAW1
    State.new(Spritenum::SAWG, 1, 4, ->a_Saw, Statenum::SAW3, 0, 0),                   # Statenum::SAW2
    State.new(Spritenum::SAWG, 1, 0, ->a_ReFire, Statenum::SAW, 0, 0),                 # Statenum::SAW3
    State.new(Spritenum::PLSG, 0, 1, ->a_WeaponReady, Statenum::PLASMA, 0, 0),         # Statenum::PLASMA
    State.new(Spritenum::PLSG, 0, 1, ->a_Lower, Statenum::PLASMADOWN, 0, 0),           # Statenum::PLASMADOWN
    State.new(Spritenum::PLSG, 0, 1, ->a_Raise, Statenum::PLASMAUP, 0, 0),             # Statenum::PLASMAUP
    State.new(Spritenum::PLSG, 0, 3, ->a_FirePlasma, Statenum::PLASMA2, 0, 0),         # Statenum::PLASMA1
    State.new(Spritenum::PLSG, 1, 20, ->a_ReFire, Statenum::PLASMA, 0, 0),             # Statenum::PLASMA2
    State.new(Spritenum::PLSF, 32768, 4, ->a_Light1, Statenum::LIGHTDONE, 0, 0),       # Statenum::PLASMAFLASH1
    State.new(Spritenum::PLSF, 32769, 4, ->a_Light1, Statenum::LIGHTDONE, 0, 0),       # Statenum::PLASMAFLASH2
    State.new(Spritenum::BFGG, 0, 1, ->a_WeaponReady, Statenum::BFG, 0, 0),            # Statenum::BFG
    State.new(Spritenum::BFGG, 0, 1, ->a_Lower, Statenum::BFGDOWN, 0, 0),              # Statenum::BFGDOWN
    State.new(Spritenum::BFGG, 0, 1, ->a_Raise, Statenum::BFGUP, 0, 0),                # Statenum::BFGUP
    State.new(Spritenum::BFGG, 0, 20, ->a_BFGsound, Statenum::BFG2, 0, 0),             # Statenum::BFG1
    State.new(Spritenum::BFGG, 1, 10, ->a_GunFlash, Statenum::BFG3, 0, 0),             # Statenum::BFG2
    State.new(Spritenum::BFGG, 1, 10, ->a_FireBFG, Statenum::BFG4, 0, 0),              # Statenum::BFG3
    State.new(Spritenum::BFGG, 1, 20, ->a_ReFire, Statenum::BFG, 0, 0),                # Statenum::BFG4
    State.new(Spritenum::BFGF, 32768, 11, ->a_Light1, Statenum::BFGFLASH2, 0, 0),      # Statenum::BFGFLASH1
    State.new(Spritenum::BFGF, 32769, 6, ->a_Light2, Statenum::LIGHTDONE, 0, 0),       # Statenum::BFGFLASH2
    State.new(Spritenum::BLUD, 2, 8, nil, Statenum::BLOOD2, 0, 0),                     # Statenum::BLOOD1
    State.new(Spritenum::BLUD, 1, 8, nil, Statenum::BLOOD3, 0, 0),                     # Statenum::BLOOD2
    State.new(Spritenum::BLUD, 0, 8, nil, Statenum::NULL, 0, 0),                       # Statenum::BLOOD3
    State.new(Spritenum::PUFF, 32768, 4, nil, Statenum::PUFF2, 0, 0),                  # Statenum::PUFF1
    State.new(Spritenum::PUFF, 1, 4, nil, Statenum::PUFF3, 0, 0),                      # Statenum::PUFF2
    State.new(Spritenum::PUFF, 2, 4, nil, Statenum::PUFF4, 0, 0),                      # Statenum::PUFF3
    State.new(Spritenum::PUFF, 3, 4, nil, Statenum::NULL, 0, 0),                       # Statenum::PUFF4
    State.new(Spritenum::BAL1, 32768, 4, nil, Statenum::TBALL2, 0, 0),                 # Statenum::TBALL1
    State.new(Spritenum::BAL1, 32769, 4, nil, Statenum::TBALL1, 0, 0),                 # Statenum::TBALL2
    State.new(Spritenum::BAL1, 32770, 6, nil, Statenum::TBALLX2, 0, 0),                # Statenum::TBALLX1
    State.new(Spritenum::BAL1, 32771, 6, nil, Statenum::TBALLX3, 0, 0),                # Statenum::TBALLX2
    State.new(Spritenum::BAL1, 32772, 6, nil, Statenum::NULL, 0, 0),                   # Statenum::TBALLX3
    State.new(Spritenum::BAL2, 32768, 4, nil, Statenum::RBALL2, 0, 0),                 # Statenum::RBALL1
    State.new(Spritenum::BAL2, 32769, 4, nil, Statenum::RBALL1, 0, 0),                 # Statenum::RBALL2
    State.new(Spritenum::BAL2, 32770, 6, nil, Statenum::RBALLX2, 0, 0),                # Statenum::RBALLX1
    State.new(Spritenum::BAL2, 32771, 6, nil, Statenum::RBALLX3, 0, 0),                # Statenum::RBALLX2
    State.new(Spritenum::BAL2, 32772, 6, nil, Statenum::NULL, 0, 0),                   # Statenum::RBALLX3
    State.new(Spritenum::PLSS, 32768, 6, nil, Statenum::PLASBALL2, 0, 0),              # Statenum::PLASBALL
    State.new(Spritenum::PLSS, 32769, 6, nil, Statenum::PLASBALL, 0, 0),               # Statenum::PLASBALL2
    State.new(Spritenum::PLSE, 32768, 4, nil, Statenum::PLASEXP2, 0, 0),               # Statenum::PLASEXP
    State.new(Spritenum::PLSE, 32769, 4, nil, Statenum::PLASEXP3, 0, 0),               # Statenum::PLASEXP2
    State.new(Spritenum::PLSE, 32770, 4, nil, Statenum::PLASEXP4, 0, 0),               # Statenum::PLASEXP3
    State.new(Spritenum::PLSE, 32771, 4, nil, Statenum::PLASEXP5, 0, 0),               # Statenum::PLASEXP4
    State.new(Spritenum::PLSE, 32772, 4, nil, Statenum::NULL, 0, 0),                   # Statenum::PLASEXP5
    State.new(Spritenum::MISL, 32768, 1, nil, Statenum::ROCKET, 0, 0),                 # Statenum::ROCKET
    State.new(Spritenum::BFS1, 32768, 4, nil, Statenum::BFGSHOT2, 0, 0),               # Statenum::BFGSHOT
    State.new(Spritenum::BFS1, 32769, 4, nil, Statenum::BFGSHOT, 0, 0),                # Statenum::BFGSHOT2
    State.new(Spritenum::BFE1, 32768, 8, nil, Statenum::BFGLAND2, 0, 0),               # Statenum::BFGLAND
    State.new(Spritenum::BFE1, 32769, 8, nil, Statenum::BFGLAND3, 0, 0),               # Statenum::BFGLAND2
    State.new(Spritenum::BFE1, 32770, 8, ->a_BFGSpray, Statenum::BFGLAND4, 0, 0),      # Statenum::BFGLAND3
    State.new(Spritenum::BFE1, 32771, 8, nil, Statenum::BFGLAND5, 0, 0),               # Statenum::BFGLAND4
    State.new(Spritenum::BFE1, 32772, 8, nil, Statenum::BFGLAND6, 0, 0),               # Statenum::BFGLAND5
    State.new(Spritenum::BFE1, 32773, 8, nil, Statenum::NULL, 0, 0),                   # Statenum::BFGLAND6
    State.new(Spritenum::BFE2, 32768, 8, nil, Statenum::BFGEXP2, 0, 0),                # Statenum::BFGEXP
    State.new(Spritenum::BFE2, 32769, 8, nil, Statenum::BFGEXP3, 0, 0),                # Statenum::BFGEXP2
    State.new(Spritenum::BFE2, 32770, 8, nil, Statenum::BFGEXP4, 0, 0),                # Statenum::BFGEXP3
    State.new(Spritenum::BFE2, 32771, 8, nil, Statenum::NULL, 0, 0),                   # Statenum::BFGEXP4
    State.new(Spritenum::MISL, 32769, 8, ->a_Explode, Statenum::EXPLODE2, 0, 0),       # Statenum::EXPLODE1
    State.new(Spritenum::MISL, 32770, 6, nil, Statenum::EXPLODE3, 0, 0),               # Statenum::EXPLODE2
    State.new(Spritenum::MISL, 32771, 4, nil, Statenum::NULL, 0, 0),                   # Statenum::EXPLODE3
    State.new(Spritenum::TFOG, 32768, 6, nil, Statenum::TFOG01, 0, 0),                 # Statenum::TFOG
    State.new(Spritenum::TFOG, 32769, 6, nil, Statenum::TFOG02, 0, 0),                 # Statenum::TFOG01
    State.new(Spritenum::TFOG, 32768, 6, nil, Statenum::TFOG2, 0, 0),                  # Statenum::TFOG02
    State.new(Spritenum::TFOG, 32769, 6, nil, Statenum::TFOG3, 0, 0),                  # Statenum::TFOG2
    State.new(Spritenum::TFOG, 32770, 6, nil, Statenum::TFOG4, 0, 0),                  # Statenum::TFOG3
    State.new(Spritenum::TFOG, 32771, 6, nil, Statenum::TFOG5, 0, 0),                  # Statenum::TFOG4
    State.new(Spritenum::TFOG, 32772, 6, nil, Statenum::TFOG6, 0, 0),                  # Statenum::TFOG5
    State.new(Spritenum::TFOG, 32773, 6, nil, Statenum::TFOG7, 0, 0),                  # Statenum::TFOG6
    State.new(Spritenum::TFOG, 32774, 6, nil, Statenum::TFOG8, 0, 0),                  # Statenum::TFOG7
    State.new(Spritenum::TFOG, 32775, 6, nil, Statenum::TFOG9, 0, 0),                  # Statenum::TFOG8
    State.new(Spritenum::TFOG, 32776, 6, nil, Statenum::TFOG10, 0, 0),                 # Statenum::TFOG9
    State.new(Spritenum::TFOG, 32777, 6, nil, Statenum::NULL, 0, 0),                   # Statenum::TFOG10
    State.new(Spritenum::IFOG, 32768, 6, nil, Statenum::IFOG01, 0, 0),                 # Statenum::IFOG
    State.new(Spritenum::IFOG, 32769, 6, nil, Statenum::IFOG02, 0, 0),                 # Statenum::IFOG01
    State.new(Spritenum::IFOG, 32768, 6, nil, Statenum::IFOG2, 0, 0),                  # Statenum::IFOG02
    State.new(Spritenum::IFOG, 32769, 6, nil, Statenum::IFOG3, 0, 0),                  # Statenum::IFOG2
    State.new(Spritenum::IFOG, 32770, 6, nil, Statenum::IFOG4, 0, 0),                  # Statenum::IFOG3
    State.new(Spritenum::IFOG, 32771, 6, nil, Statenum::IFOG5, 0, 0),                  # Statenum::IFOG4
    State.new(Spritenum::IFOG, 32772, 6, nil, Statenum::NULL, 0, 0),                   # Statenum::IFOG5
    State.new(Spritenum::PLAY, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::PLAY
    State.new(Spritenum::PLAY, 0, 4, nil, Statenum::PLAY_RUN2, 0, 0),                  # Statenum::PLAY_RUN1
    State.new(Spritenum::PLAY, 1, 4, nil, Statenum::PLAY_RUN3, 0, 0),                  # Statenum::PLAY_RUN2
    State.new(Spritenum::PLAY, 2, 4, nil, Statenum::PLAY_RUN4, 0, 0),                  # Statenum::PLAY_RUN3
    State.new(Spritenum::PLAY, 3, 4, nil, Statenum::PLAY_RUN1, 0, 0),                  # Statenum::PLAY_RUN4
    State.new(Spritenum::PLAY, 4, 12, nil, Statenum::PLAY, 0, 0),                      # Statenum::PLAY_ATK1
    State.new(Spritenum::PLAY, 32773, 6, nil, Statenum::PLAY_ATK1, 0, 0),              # Statenum::PLAY_ATK2
    State.new(Spritenum::PLAY, 6, 4, nil, Statenum::PLAY_PAIN2, 0, 0),                 # Statenum::PLAY_PAIN
    State.new(Spritenum::PLAY, 6, 4, ->a_Pain, Statenum::PLAY, 0, 0),                  # Statenum::PLAY_PAIN2
    State.new(Spritenum::PLAY, 7, 10, nil, Statenum::PLAY_DIE2, 0, 0),                 # Statenum::PLAY_DIE1
    State.new(Spritenum::PLAY, 8, 10, ->a_PlayerScream, Statenum::PLAY_DIE3, 0, 0),    # Statenum::PLAY_DIE2
    State.new(Spritenum::PLAY, 9, 10, ->a_Fall, Statenum::PLAY_DIE4, 0, 0),            # Statenum::PLAY_DIE3
    State.new(Spritenum::PLAY, 10, 10, nil, Statenum::PLAY_DIE5, 0, 0),                # Statenum::PLAY_DIE4
    State.new(Spritenum::PLAY, 11, 10, nil, Statenum::PLAY_DIE6, 0, 0),                # Statenum::PLAY_DIE5
    State.new(Spritenum::PLAY, 12, 10, nil, Statenum::PLAY_DIE7, 0, 0),                # Statenum::PLAY_DIE6
    State.new(Spritenum::PLAY, 13, -1, nil, Statenum::NULL, 0, 0),                     # Statenum::PLAY_DIE7
    State.new(Spritenum::PLAY, 14, 5, nil, Statenum::PLAY_XDIE2, 0, 0),                # Statenum::PLAY_XDIE1
    State.new(Spritenum::PLAY, 15, 5, ->a_XScream, Statenum::PLAY_XDIE3, 0, 0),        # Statenum::PLAY_XDIE2
    State.new(Spritenum::PLAY, 16, 5, ->a_Fall, Statenum::PLAY_XDIE4, 0, 0),           # Statenum::PLAY_XDIE3
    State.new(Spritenum::PLAY, 17, 5, nil, Statenum::PLAY_XDIE5, 0, 0),                # Statenum::PLAY_XDIE4
    State.new(Spritenum::PLAY, 18, 5, nil, Statenum::PLAY_XDIE6, 0, 0),                # Statenum::PLAY_XDIE5
    State.new(Spritenum::PLAY, 19, 5, nil, Statenum::PLAY_XDIE7, 0, 0),                # Statenum::PLAY_XDIE6
    State.new(Spritenum::PLAY, 20, 5, nil, Statenum::PLAY_XDIE8, 0, 0),                # Statenum::PLAY_XDIE7
    State.new(Spritenum::PLAY, 21, 5, nil, Statenum::PLAY_XDIE9, 0, 0),                # Statenum::PLAY_XDIE8
    State.new(Spritenum::PLAY, 22, -1, nil, Statenum::NULL, 0, 0),                     # Statenum::PLAY_XDIE9
    State.new(Spritenum::POSS, 0, 10, ->a_Look, Statenum::POSS_STND2, 0, 0),           # Statenum::POSS_STND
    State.new(Spritenum::POSS, 1, 10, ->a_Look, Statenum::POSS_STND, 0, 0),            # Statenum::POSS_STND2
    State.new(Spritenum::POSS, 0, 4, ->a_Chase, Statenum::POSS_RUN2, 0, 0),            # Statenum::POSS_RUN1
    State.new(Spritenum::POSS, 0, 4, ->a_Chase, Statenum::POSS_RUN3, 0, 0),            # Statenum::POSS_RUN2
    State.new(Spritenum::POSS, 1, 4, ->a_Chase, Statenum::POSS_RUN4, 0, 0),            # Statenum::POSS_RUN3
    State.new(Spritenum::POSS, 1, 4, ->a_Chase, Statenum::POSS_RUN5, 0, 0),            # Statenum::POSS_RUN4
    State.new(Spritenum::POSS, 2, 4, ->a_Chase, Statenum::POSS_RUN6, 0, 0),            # Statenum::POSS_RUN5
    State.new(Spritenum::POSS, 2, 4, ->a_Chase, Statenum::POSS_RUN7, 0, 0),            # Statenum::POSS_RUN6
    State.new(Spritenum::POSS, 3, 4, ->a_Chase, Statenum::POSS_RUN8, 0, 0),            # Statenum::POSS_RUN7
    State.new(Spritenum::POSS, 3, 4, ->a_Chase, Statenum::POSS_RUN1, 0, 0),            # Statenum::POSS_RUN8
    State.new(Spritenum::POSS, 4, 10, ->a_FaceTarget, Statenum::POSS_ATK2, 0, 0),      # Statenum::POSS_ATK1
    State.new(Spritenum::POSS, 5, 8, ->a_PosAttack, Statenum::POSS_ATK3, 0, 0),        # Statenum::POSS_ATK2
    State.new(Spritenum::POSS, 4, 8, nil, Statenum::POSS_RUN1, 0, 0),                  # Statenum::POSS_ATK3
    State.new(Spritenum::POSS, 6, 3, nil, Statenum::POSS_PAIN2, 0, 0),                 # Statenum::POSS_PAIN
    State.new(Spritenum::POSS, 6, 3, ->a_Pain, Statenum::POSS_RUN1, 0, 0),             # Statenum::POSS_PAIN2
    State.new(Spritenum::POSS, 7, 5, nil, Statenum::POSS_DIE2, 0, 0),                  # Statenum::POSS_DIE1
    State.new(Spritenum::POSS, 8, 5, ->a_Scream, Statenum::POSS_DIE3, 0, 0),           # Statenum::POSS_DIE2
    State.new(Spritenum::POSS, 9, 5, ->a_Fall, Statenum::POSS_DIE4, 0, 0),             # Statenum::POSS_DIE3
    State.new(Spritenum::POSS, 10, 5, nil, Statenum::POSS_DIE5, 0, 0),                 # Statenum::POSS_DIE4
    State.new(Spritenum::POSS, 11, -1, nil, Statenum::NULL, 0, 0),                     # Statenum::POSS_DIE5
    State.new(Spritenum::POSS, 12, 5, nil, Statenum::POSS_XDIE2, 0, 0),                # Statenum::POSS_XDIE1
    State.new(Spritenum::POSS, 13, 5, ->a_XScream, Statenum::POSS_XDIE3, 0, 0),        # Statenum::POSS_XDIE2
    State.new(Spritenum::POSS, 14, 5, ->a_Fall, Statenum::POSS_XDIE4, 0, 0),           # Statenum::POSS_XDIE3
    State.new(Spritenum::POSS, 15, 5, nil, Statenum::POSS_XDIE5, 0, 0),                # Statenum::POSS_XDIE4
    State.new(Spritenum::POSS, 16, 5, nil, Statenum::POSS_XDIE6, 0, 0),                # Statenum::POSS_XDIE5
    State.new(Spritenum::POSS, 17, 5, nil, Statenum::POSS_XDIE7, 0, 0),                # Statenum::POSS_XDIE6
    State.new(Spritenum::POSS, 18, 5, nil, Statenum::POSS_XDIE8, 0, 0),                # Statenum::POSS_XDIE7
    State.new(Spritenum::POSS, 19, 5, nil, Statenum::POSS_XDIE9, 0, 0),                # Statenum::POSS_XDIE8
    State.new(Spritenum::POSS, 20, -1, nil, Statenum::NULL, 0, 0),                     # Statenum::POSS_XDIE9
    State.new(Spritenum::POSS, 10, 5, nil, Statenum::POSS_RAISE2, 0, 0),               # Statenum::POSS_RAISE1
    State.new(Spritenum::POSS, 9, 5, nil, Statenum::POSS_RAISE3, 0, 0),                # Statenum::POSS_RAISE2
    State.new(Spritenum::POSS, 8, 5, nil, Statenum::POSS_RAISE4, 0, 0),                # Statenum::POSS_RAISE3
    State.new(Spritenum::POSS, 7, 5, nil, Statenum::POSS_RUN1, 0, 0),                  # Statenum::POSS_RAISE4
    State.new(Spritenum::SPOS, 0, 10, ->a_Look, Statenum::SPOS_STND2, 0, 0),           # Statenum::SPOS_STND
    State.new(Spritenum::SPOS, 1, 10, ->a_Look, Statenum::SPOS_STND, 0, 0),            # Statenum::SPOS_STND2
    State.new(Spritenum::SPOS, 0, 3, ->a_Chase, Statenum::SPOS_RUN2, 0, 0),            # Statenum::SPOS_RUN1
    State.new(Spritenum::SPOS, 0, 3, ->a_Chase, Statenum::SPOS_RUN3, 0, 0),            # Statenum::SPOS_RUN2
    State.new(Spritenum::SPOS, 1, 3, ->a_Chase, Statenum::SPOS_RUN4, 0, 0),            # Statenum::SPOS_RUN3
    State.new(Spritenum::SPOS, 1, 3, ->a_Chase, Statenum::SPOS_RUN5, 0, 0),            # Statenum::SPOS_RUN4
    State.new(Spritenum::SPOS, 2, 3, ->a_Chase, Statenum::SPOS_RUN6, 0, 0),            # Statenum::SPOS_RUN5
    State.new(Spritenum::SPOS, 2, 3, ->a_Chase, Statenum::SPOS_RUN7, 0, 0),            # Statenum::SPOS_RUN6
    State.new(Spritenum::SPOS, 3, 3, ->a_Chase, Statenum::SPOS_RUN8, 0, 0),            # Statenum::SPOS_RUN7
    State.new(Spritenum::SPOS, 3, 3, ->a_Chase, Statenum::SPOS_RUN1, 0, 0),            # Statenum::SPOS_RUN8
    State.new(Spritenum::SPOS, 4, 10, ->a_FaceTarget, Statenum::SPOS_ATK2, 0, 0),      # Statenum::SPOS_ATK1
    State.new(Spritenum::SPOS, 32773, 10, ->a_SPosAttack, Statenum::SPOS_ATK3, 0, 0),  # Statenum::SPOS_ATK2
    State.new(Spritenum::SPOS, 4, 10, nil, Statenum::SPOS_RUN1, 0, 0),                 # Statenum::SPOS_ATK3
    State.new(Spritenum::SPOS, 6, 3, nil, Statenum::SPOS_PAIN2, 0, 0),                 # Statenum::SPOS_PAIN
    State.new(Spritenum::SPOS, 6, 3, ->a_Pain, Statenum::SPOS_RUN1, 0, 0),             # Statenum::SPOS_PAIN2
    State.new(Spritenum::SPOS, 7, 5, nil, Statenum::SPOS_DIE2, 0, 0),                  # Statenum::SPOS_DIE1
    State.new(Spritenum::SPOS, 8, 5, ->a_Scream, Statenum::SPOS_DIE3, 0, 0),           # Statenum::SPOS_DIE2
    State.new(Spritenum::SPOS, 9, 5, ->a_Fall, Statenum::SPOS_DIE4, 0, 0),             # Statenum::SPOS_DIE3
    State.new(Spritenum::SPOS, 10, 5, nil, Statenum::SPOS_DIE5, 0, 0),                 # Statenum::SPOS_DIE4
    State.new(Spritenum::SPOS, 11, -1, nil, Statenum::NULL, 0, 0),                     # Statenum::SPOS_DIE5
    State.new(Spritenum::SPOS, 12, 5, nil, Statenum::SPOS_XDIE2, 0, 0),                # Statenum::SPOS_XDIE1
    State.new(Spritenum::SPOS, 13, 5, ->a_XScream, Statenum::SPOS_XDIE3, 0, 0),        # Statenum::SPOS_XDIE2
    State.new(Spritenum::SPOS, 14, 5, ->a_Fall, Statenum::SPOS_XDIE4, 0, 0),           # Statenum::SPOS_XDIE3
    State.new(Spritenum::SPOS, 15, 5, nil, Statenum::SPOS_XDIE5, 0, 0),                # Statenum::SPOS_XDIE4
    State.new(Spritenum::SPOS, 16, 5, nil, Statenum::SPOS_XDIE6, 0, 0),                # Statenum::SPOS_XDIE5
    State.new(Spritenum::SPOS, 17, 5, nil, Statenum::SPOS_XDIE7, 0, 0),                # Statenum::SPOS_XDIE6
    State.new(Spritenum::SPOS, 18, 5, nil, Statenum::SPOS_XDIE8, 0, 0),                # Statenum::SPOS_XDIE7
    State.new(Spritenum::SPOS, 19, 5, nil, Statenum::SPOS_XDIE9, 0, 0),                # Statenum::SPOS_XDIE8
    State.new(Spritenum::SPOS, 20, -1, nil, Statenum::NULL, 0, 0),                     # Statenum::SPOS_XDIE9
    State.new(Spritenum::SPOS, 11, 5, nil, Statenum::SPOS_RAISE2, 0, 0),               # Statenum::SPOS_RAISE1
    State.new(Spritenum::SPOS, 10, 5, nil, Statenum::SPOS_RAISE3, 0, 0),               # Statenum::SPOS_RAISE2
    State.new(Spritenum::SPOS, 9, 5, nil, Statenum::SPOS_RAISE4, 0, 0),                # Statenum::SPOS_RAISE3
    State.new(Spritenum::SPOS, 8, 5, nil, Statenum::SPOS_RAISE5, 0, 0),                # Statenum::SPOS_RAISE4
    State.new(Spritenum::SPOS, 7, 5, nil, Statenum::SPOS_RUN1, 0, 0),                  # Statenum::SPOS_RAISE5
    State.new(Spritenum::VILE, 0, 10, ->a_Look, Statenum::VILE_STND2, 0, 0),           # Statenum::VILE_STND
    State.new(Spritenum::VILE, 1, 10, ->a_Look, Statenum::VILE_STND, 0, 0),            # Statenum::VILE_STND2
    State.new(Spritenum::VILE, 0, 2, ->a_VileChase, Statenum::VILE_RUN2, 0, 0),        # Statenum::VILE_RUN1
    State.new(Spritenum::VILE, 0, 2, ->a_VileChase, Statenum::VILE_RUN3, 0, 0),        # Statenum::VILE_RUN2
    State.new(Spritenum::VILE, 1, 2, ->a_VileChase, Statenum::VILE_RUN4, 0, 0),        # Statenum::VILE_RUN3
    State.new(Spritenum::VILE, 1, 2, ->a_VileChase, Statenum::VILE_RUN5, 0, 0),        # Statenum::VILE_RUN4
    State.new(Spritenum::VILE, 2, 2, ->a_VileChase, Statenum::VILE_RUN6, 0, 0),        # Statenum::VILE_RUN5
    State.new(Spritenum::VILE, 2, 2, ->a_VileChase, Statenum::VILE_RUN7, 0, 0),        # Statenum::VILE_RUN6
    State.new(Spritenum::VILE, 3, 2, ->a_VileChase, Statenum::VILE_RUN8, 0, 0),        # Statenum::VILE_RUN7
    State.new(Spritenum::VILE, 3, 2, ->a_VileChase, Statenum::VILE_RUN9, 0, 0),        # Statenum::VILE_RUN8
    State.new(Spritenum::VILE, 4, 2, ->a_VileChase, Statenum::VILE_RUN10, 0, 0),       # Statenum::VILE_RUN9
    State.new(Spritenum::VILE, 4, 2, ->a_VileChase, Statenum::VILE_RUN11, 0, 0),       # Statenum::VILE_RUN10
    State.new(Spritenum::VILE, 5, 2, ->a_VileChase, Statenum::VILE_RUN12, 0, 0),       # Statenum::VILE_RUN11
    State.new(Spritenum::VILE, 5, 2, ->a_VileChase, Statenum::VILE_RUN1, 0, 0),        # Statenum::VILE_RUN12
    State.new(Spritenum::VILE, 32774, 0, ->a_VileStart, Statenum::VILE_ATK2, 0, 0),    # Statenum::VILE_ATK1
    State.new(Spritenum::VILE, 32774, 10, ->a_FaceTarget, Statenum::VILE_ATK3, 0, 0),  # Statenum::VILE_ATK2
    State.new(Spritenum::VILE, 32775, 8, ->a_VileTarget, Statenum::VILE_ATK4, 0, 0),   # Statenum::VILE_ATK3
    State.new(Spritenum::VILE, 32776, 8, ->a_FaceTarget, Statenum::VILE_ATK5, 0, 0),   # Statenum::VILE_ATK4
    State.new(Spritenum::VILE, 32777, 8, ->a_FaceTarget, Statenum::VILE_ATK6, 0, 0),   # Statenum::VILE_ATK5
    State.new(Spritenum::VILE, 32778, 8, ->a_FaceTarget, Statenum::VILE_ATK7, 0, 0),   # Statenum::VILE_ATK6
    State.new(Spritenum::VILE, 32779, 8, ->a_FaceTarget, Statenum::VILE_ATK8, 0, 0),   # Statenum::VILE_ATK7
    State.new(Spritenum::VILE, 32780, 8, ->a_FaceTarget, Statenum::VILE_ATK9, 0, 0),   # Statenum::VILE_ATK8
    State.new(Spritenum::VILE, 32781, 8, ->a_FaceTarget, Statenum::VILE_ATK10, 0, 0),  # Statenum::VILE_ATK9
    State.new(Spritenum::VILE, 32782, 8, ->a_VileAttack, Statenum::VILE_ATK11, 0, 0),  # Statenum::VILE_ATK10
    State.new(Spritenum::VILE, 32783, 20, nil, Statenum::VILE_RUN1, 0, 0),             # Statenum::VILE_ATK11
    State.new(Spritenum::VILE, 32794, 10, nil, Statenum::VILE_HEAL2, 0, 0),            # Statenum::VILE_HEAL1
    State.new(Spritenum::VILE, 32795, 10, nil, Statenum::VILE_HEAL3, 0, 0),            # Statenum::VILE_HEAL2
    State.new(Spritenum::VILE, 32796, 10, nil, Statenum::VILE_RUN1, 0, 0),             # Statenum::VILE_HEAL3
    State.new(Spritenum::VILE, 16, 5, nil, Statenum::VILE_PAIN2, 0, 0),                # Statenum::VILE_PAIN
    State.new(Spritenum::VILE, 16, 5, ->a_Pain, Statenum::VILE_RUN1, 0, 0),            # Statenum::VILE_PAIN2
    State.new(Spritenum::VILE, 16, 7, nil, Statenum::VILE_DIE2, 0, 0),                 # Statenum::VILE_DIE1
    State.new(Spritenum::VILE, 17, 7, ->a_Scream, Statenum::VILE_DIE3, 0, 0),          # Statenum::VILE_DIE2
    State.new(Spritenum::VILE, 18, 7, ->a_Fall, Statenum::VILE_DIE4, 0, 0),            # Statenum::VILE_DIE3
    State.new(Spritenum::VILE, 19, 7, nil, Statenum::VILE_DIE5, 0, 0),                 # Statenum::VILE_DIE4
    State.new(Spritenum::VILE, 20, 7, nil, Statenum::VILE_DIE6, 0, 0),                 # Statenum::VILE_DIE5
    State.new(Spritenum::VILE, 21, 7, nil, Statenum::VILE_DIE7, 0, 0),                 # Statenum::VILE_DIE6
    State.new(Spritenum::VILE, 22, 7, nil, Statenum::VILE_DIE8, 0, 0),                 # Statenum::VILE_DIE7
    State.new(Spritenum::VILE, 23, 5, nil, Statenum::VILE_DIE9, 0, 0),                 # Statenum::VILE_DIE8
    State.new(Spritenum::VILE, 24, 5, nil, Statenum::VILE_DIE10, 0, 0),                # Statenum::VILE_DIE9
    State.new(Spritenum::VILE, 25, -1, nil, Statenum::NULL, 0, 0),                     # Statenum::VILE_DIE10
    State.new(Spritenum::FIRE, 32768, 2, ->a_StartFire, Statenum::FIRE2, 0, 0),        # Statenum::FIRE1
    State.new(Spritenum::FIRE, 32769, 2, ->a_Fire, Statenum::FIRE3, 0, 0),             # Statenum::FIRE2
    State.new(Spritenum::FIRE, 32768, 2, ->a_Fire, Statenum::FIRE4, 0, 0),             # Statenum::FIRE3
    State.new(Spritenum::FIRE, 32769, 2, ->a_Fire, Statenum::FIRE5, 0, 0),             # Statenum::FIRE4
    State.new(Spritenum::FIRE, 32770, 2, ->a_FireCrackle, Statenum::FIRE6, 0, 0),      # Statenum::FIRE5
    State.new(Spritenum::FIRE, 32769, 2, ->a_Fire, Statenum::FIRE7, 0, 0),             # Statenum::FIRE6
    State.new(Spritenum::FIRE, 32770, 2, ->a_Fire, Statenum::FIRE8, 0, 0),             # Statenum::FIRE7
    State.new(Spritenum::FIRE, 32769, 2, ->a_Fire, Statenum::FIRE9, 0, 0),             # Statenum::FIRE8
    State.new(Spritenum::FIRE, 32770, 2, ->a_Fire, Statenum::FIRE10, 0, 0),            # Statenum::FIRE9
    State.new(Spritenum::FIRE, 32771, 2, ->a_Fire, Statenum::FIRE11, 0, 0),            # Statenum::FIRE10
    State.new(Spritenum::FIRE, 32770, 2, ->a_Fire, Statenum::FIRE12, 0, 0),            # Statenum::FIRE11
    State.new(Spritenum::FIRE, 32771, 2, ->a_Fire, Statenum::FIRE13, 0, 0),            # Statenum::FIRE12
    State.new(Spritenum::FIRE, 32770, 2, ->a_Fire, Statenum::FIRE14, 0, 0),            # Statenum::FIRE13
    State.new(Spritenum::FIRE, 32771, 2, ->a_Fire, Statenum::FIRE15, 0, 0),            # Statenum::FIRE14
    State.new(Spritenum::FIRE, 32772, 2, ->a_Fire, Statenum::FIRE16, 0, 0),            # Statenum::FIRE15
    State.new(Spritenum::FIRE, 32771, 2, ->a_Fire, Statenum::FIRE17, 0, 0),            # Statenum::FIRE16
    State.new(Spritenum::FIRE, 32772, 2, ->a_Fire, Statenum::FIRE18, 0, 0),            # Statenum::FIRE17
    State.new(Spritenum::FIRE, 32771, 2, ->a_Fire, Statenum::FIRE19, 0, 0),            # Statenum::FIRE18
    State.new(Spritenum::FIRE, 32772, 2, ->a_FireCrackle, Statenum::FIRE20, 0, 0),     # Statenum::FIRE19
    State.new(Spritenum::FIRE, 32773, 2, ->a_Fire, Statenum::FIRE21, 0, 0),            # Statenum::FIRE20
    State.new(Spritenum::FIRE, 32772, 2, ->a_Fire, Statenum::FIRE22, 0, 0),            # Statenum::FIRE21
    State.new(Spritenum::FIRE, 32773, 2, ->a_Fire, Statenum::FIRE23, 0, 0),            # Statenum::FIRE22
    State.new(Spritenum::FIRE, 32772, 2, ->a_Fire, Statenum::FIRE24, 0, 0),            # Statenum::FIRE23
    State.new(Spritenum::FIRE, 32773, 2, ->a_Fire, Statenum::FIRE25, 0, 0),            # Statenum::FIRE24
    State.new(Spritenum::FIRE, 32774, 2, ->a_Fire, Statenum::FIRE26, 0, 0),            # Statenum::FIRE25
    State.new(Spritenum::FIRE, 32775, 2, ->a_Fire, Statenum::FIRE27, 0, 0),            # Statenum::FIRE26
    State.new(Spritenum::FIRE, 32774, 2, ->a_Fire, Statenum::FIRE28, 0, 0),            # Statenum::FIRE27
    State.new(Spritenum::FIRE, 32775, 2, ->a_Fire, Statenum::FIRE29, 0, 0),            # Statenum::FIRE28
    State.new(Spritenum::FIRE, 32774, 2, ->a_Fire, Statenum::FIRE30, 0, 0),            # Statenum::FIRE29
    State.new(Spritenum::FIRE, 32775, 2, ->a_Fire, Statenum::NULL, 0, 0),              # Statenum::FIRE30
    State.new(Spritenum::PUFF, 1, 4, nil, Statenum::SMOKE2, 0, 0),                     # Statenum::SMOKE1
    State.new(Spritenum::PUFF, 2, 4, nil, Statenum::SMOKE3, 0, 0),                     # Statenum::SMOKE2
    State.new(Spritenum::PUFF, 1, 4, nil, Statenum::SMOKE4, 0, 0),                     # Statenum::SMOKE3
    State.new(Spritenum::PUFF, 2, 4, nil, Statenum::SMOKE5, 0, 0),                     # Statenum::SMOKE4
    State.new(Spritenum::PUFF, 3, 4, nil, Statenum::NULL, 0, 0),                       # Statenum::SMOKE5
    State.new(Spritenum::FATB, 32768, 2, ->a_Tracer, Statenum::TRACER2, 0, 0),         # Statenum::TRACER
    State.new(Spritenum::FATB, 32769, 2, ->a_Tracer, Statenum::TRACER, 0, 0),          # Statenum::TRACER2
    State.new(Spritenum::FBXP, 32768, 8, nil, Statenum::TRACEEXP2, 0, 0),              # Statenum::TRACEEXP1
    State.new(Spritenum::FBXP, 32769, 6, nil, Statenum::TRACEEXP3, 0, 0),              # Statenum::TRACEEXP2
    State.new(Spritenum::FBXP, 32770, 4, nil, Statenum::NULL, 0, 0),                   # Statenum::TRACEEXP3
    State.new(Spritenum::SKEL, 0, 10, ->a_Look, Statenum::SKEL_STND2, 0, 0),           # Statenum::SKEL_STND
    State.new(Spritenum::SKEL, 1, 10, ->a_Look, Statenum::SKEL_STND, 0, 0),            # Statenum::SKEL_STND2
    State.new(Spritenum::SKEL, 0, 2, ->a_Chase, Statenum::SKEL_RUN2, 0, 0),            # Statenum::SKEL_RUN1
    State.new(Spritenum::SKEL, 0, 2, ->a_Chase, Statenum::SKEL_RUN3, 0, 0),            # Statenum::SKEL_RUN2
    State.new(Spritenum::SKEL, 1, 2, ->a_Chase, Statenum::SKEL_RUN4, 0, 0),            # Statenum::SKEL_RUN3
    State.new(Spritenum::SKEL, 1, 2, ->a_Chase, Statenum::SKEL_RUN5, 0, 0),            # Statenum::SKEL_RUN4
    State.new(Spritenum::SKEL, 2, 2, ->a_Chase, Statenum::SKEL_RUN6, 0, 0),            # Statenum::SKEL_RUN5
    State.new(Spritenum::SKEL, 2, 2, ->a_Chase, Statenum::SKEL_RUN7, 0, 0),            # Statenum::SKEL_RUN6
    State.new(Spritenum::SKEL, 3, 2, ->a_Chase, Statenum::SKEL_RUN8, 0, 0),            # Statenum::SKEL_RUN7
    State.new(Spritenum::SKEL, 3, 2, ->a_Chase, Statenum::SKEL_RUN9, 0, 0),            # Statenum::SKEL_RUN8
    State.new(Spritenum::SKEL, 4, 2, ->a_Chase, Statenum::SKEL_RUN10, 0, 0),           # Statenum::SKEL_RUN9
    State.new(Spritenum::SKEL, 4, 2, ->a_Chase, Statenum::SKEL_RUN11, 0, 0),           # Statenum::SKEL_RUN10
    State.new(Spritenum::SKEL, 5, 2, ->a_Chase, Statenum::SKEL_RUN12, 0, 0),           # Statenum::SKEL_RUN11
    State.new(Spritenum::SKEL, 5, 2, ->a_Chase, Statenum::SKEL_RUN1, 0, 0),            # Statenum::SKEL_RUN12
    State.new(Spritenum::SKEL, 6, 0, ->a_FaceTarget, Statenum::SKEL_FIST2, 0, 0),      # Statenum::SKEL_FIST1
    State.new(Spritenum::SKEL, 6, 6, ->a_SkelWhoosh, Statenum::SKEL_FIST3, 0, 0),      # Statenum::SKEL_FIST2
    State.new(Spritenum::SKEL, 7, 6, ->a_FaceTarget, Statenum::SKEL_FIST4, 0, 0),      # Statenum::SKEL_FIST3
    State.new(Spritenum::SKEL, 8, 6, ->a_SkelFist, Statenum::SKEL_RUN1, 0, 0),         # Statenum::SKEL_FIST4
    State.new(Spritenum::SKEL, 32777, 0, ->a_FaceTarget, Statenum::SKEL_MISS2, 0, 0),  # Statenum::SKEL_MISS1
    State.new(Spritenum::SKEL, 32777, 10, ->a_FaceTarget, Statenum::SKEL_MISS3, 0, 0), # Statenum::SKEL_MISS2
    State.new(Spritenum::SKEL, 10, 10, ->a_SkelMissile, Statenum::SKEL_MISS4, 0, 0),   # Statenum::SKEL_MISS3
    State.new(Spritenum::SKEL, 10, 10, ->a_FaceTarget, Statenum::SKEL_RUN1, 0, 0),     # Statenum::SKEL_MISS4
    State.new(Spritenum::SKEL, 11, 5, nil, Statenum::SKEL_PAIN2, 0, 0),                # Statenum::SKEL_PAIN
    State.new(Spritenum::SKEL, 11, 5, ->a_Pain, Statenum::SKEL_RUN1, 0, 0),            # Statenum::SKEL_PAIN2
    State.new(Spritenum::SKEL, 11, 7, nil, Statenum::SKEL_DIE2, 0, 0),                 # Statenum::SKEL_DIE1
    State.new(Spritenum::SKEL, 12, 7, nil, Statenum::SKEL_DIE3, 0, 0),                 # Statenum::SKEL_DIE2
    State.new(Spritenum::SKEL, 13, 7, ->a_Scream, Statenum::SKEL_DIE4, 0, 0),          # Statenum::SKEL_DIE3
    State.new(Spritenum::SKEL, 14, 7, ->a_Fall, Statenum::SKEL_DIE5, 0, 0),            # Statenum::SKEL_DIE4
    State.new(Spritenum::SKEL, 15, 7, nil, Statenum::SKEL_DIE6, 0, 0),                 # Statenum::SKEL_DIE5
    State.new(Spritenum::SKEL, 16, -1, nil, Statenum::NULL, 0, 0),                     # Statenum::SKEL_DIE6
    State.new(Spritenum::SKEL, 16, 5, nil, Statenum::SKEL_RAISE2, 0, 0),               # Statenum::SKEL_RAISE1
    State.new(Spritenum::SKEL, 15, 5, nil, Statenum::SKEL_RAISE3, 0, 0),               # Statenum::SKEL_RAISE2
    State.new(Spritenum::SKEL, 14, 5, nil, Statenum::SKEL_RAISE4, 0, 0),               # Statenum::SKEL_RAISE3
    State.new(Spritenum::SKEL, 13, 5, nil, Statenum::SKEL_RAISE5, 0, 0),               # Statenum::SKEL_RAISE4
    State.new(Spritenum::SKEL, 12, 5, nil, Statenum::SKEL_RAISE6, 0, 0),               # Statenum::SKEL_RAISE5
    State.new(Spritenum::SKEL, 11, 5, nil, Statenum::SKEL_RUN1, 0, 0),                 # Statenum::SKEL_RAISE6
    State.new(Spritenum::MANF, 32768, 4, nil, Statenum::FATSHOT2, 0, 0),               # Statenum::FATSHOT1
    State.new(Spritenum::MANF, 32769, 4, nil, Statenum::FATSHOT1, 0, 0),               # Statenum::FATSHOT2
    State.new(Spritenum::MISL, 32769, 8, nil, Statenum::FATSHOTX2, 0, 0),              # Statenum::FATSHOTX1
    State.new(Spritenum::MISL, 32770, 6, nil, Statenum::FATSHOTX3, 0, 0),              # Statenum::FATSHOTX2
    State.new(Spritenum::MISL, 32771, 4, nil, Statenum::NULL, 0, 0),                   # Statenum::FATSHOTX3
    State.new(Spritenum::FATT, 0, 15, ->a_Look, Statenum::FATT_STND2, 0, 0),           # Statenum::FATT_STND
    State.new(Spritenum::FATT, 1, 15, ->a_Look, Statenum::FATT_STND, 0, 0),            # Statenum::FATT_STND2
    State.new(Spritenum::FATT, 0, 4, ->a_Chase, Statenum::FATT_RUN2, 0, 0),            # Statenum::FATT_RUN1
    State.new(Spritenum::FATT, 0, 4, ->a_Chase, Statenum::FATT_RUN3, 0, 0),            # Statenum::FATT_RUN2
    State.new(Spritenum::FATT, 1, 4, ->a_Chase, Statenum::FATT_RUN4, 0, 0),            # Statenum::FATT_RUN3
    State.new(Spritenum::FATT, 1, 4, ->a_Chase, Statenum::FATT_RUN5, 0, 0),            # Statenum::FATT_RUN4
    State.new(Spritenum::FATT, 2, 4, ->a_Chase, Statenum::FATT_RUN6, 0, 0),            # Statenum::FATT_RUN5
    State.new(Spritenum::FATT, 2, 4, ->a_Chase, Statenum::FATT_RUN7, 0, 0),            # Statenum::FATT_RUN6
    State.new(Spritenum::FATT, 3, 4, ->a_Chase, Statenum::FATT_RUN8, 0, 0),            # Statenum::FATT_RUN7
    State.new(Spritenum::FATT, 3, 4, ->a_Chase, Statenum::FATT_RUN9, 0, 0),            # Statenum::FATT_RUN8
    State.new(Spritenum::FATT, 4, 4, ->a_Chase, Statenum::FATT_RUN10, 0, 0),           # Statenum::FATT_RUN9
    State.new(Spritenum::FATT, 4, 4, ->a_Chase, Statenum::FATT_RUN11, 0, 0),           # Statenum::FATT_RUN10
    State.new(Spritenum::FATT, 5, 4, ->a_Chase, Statenum::FATT_RUN12, 0, 0),           # Statenum::FATT_RUN11
    State.new(Spritenum::FATT, 5, 4, ->a_Chase, Statenum::FATT_RUN1, 0, 0),            # Statenum::FATT_RUN12
    State.new(Spritenum::FATT, 6, 20, ->a_FatRaise, Statenum::FATT_ATK2, 0, 0),        # Statenum::FATT_ATK1
    State.new(Spritenum::FATT, 32775, 10, ->a_FatAttack1, Statenum::FATT_ATK3, 0, 0),  # Statenum::FATT_ATK2
    State.new(Spritenum::FATT, 8, 5, ->a_FaceTarget, Statenum::FATT_ATK4, 0, 0),       # Statenum::FATT_ATK3
    State.new(Spritenum::FATT, 6, 5, ->a_FaceTarget, Statenum::FATT_ATK5, 0, 0),       # Statenum::FATT_ATK4
    State.new(Spritenum::FATT, 32775, 10, ->a_FatAttack2, Statenum::FATT_ATK6, 0, 0),  # Statenum::FATT_ATK5
    State.new(Spritenum::FATT, 8, 5, ->a_FaceTarget, Statenum::FATT_ATK7, 0, 0),       # Statenum::FATT_ATK6
    State.new(Spritenum::FATT, 6, 5, ->a_FaceTarget, Statenum::FATT_ATK8, 0, 0),       # Statenum::FATT_ATK7
    State.new(Spritenum::FATT, 32775, 10, ->a_FatAttack3, Statenum::FATT_ATK9, 0, 0),  # Statenum::FATT_ATK8
    State.new(Spritenum::FATT, 8, 5, ->a_FaceTarget, Statenum::FATT_ATK10, 0, 0),      # Statenum::FATT_ATK9
    State.new(Spritenum::FATT, 6, 5, ->a_FaceTarget, Statenum::FATT_RUN1, 0, 0),       # Statenum::FATT_ATK10
    State.new(Spritenum::FATT, 9, 3, nil, Statenum::FATT_PAIN2, 0, 0),                 # Statenum::FATT_PAIN
    State.new(Spritenum::FATT, 9, 3, ->a_Pain, Statenum::FATT_RUN1, 0, 0),             # Statenum::FATT_PAIN2
    State.new(Spritenum::FATT, 10, 6, nil, Statenum::FATT_DIE2, 0, 0),                 # Statenum::FATT_DIE1
    State.new(Spritenum::FATT, 11, 6, ->a_Scream, Statenum::FATT_DIE3, 0, 0),          # Statenum::FATT_DIE2
    State.new(Spritenum::FATT, 12, 6, ->a_Fall, Statenum::FATT_DIE4, 0, 0),            # Statenum::FATT_DIE3
    State.new(Spritenum::FATT, 13, 6, nil, Statenum::FATT_DIE5, 0, 0),                 # Statenum::FATT_DIE4
    State.new(Spritenum::FATT, 14, 6, nil, Statenum::FATT_DIE6, 0, 0),                 # Statenum::FATT_DIE5
    State.new(Spritenum::FATT, 15, 6, nil, Statenum::FATT_DIE7, 0, 0),                 # Statenum::FATT_DIE6
    State.new(Spritenum::FATT, 16, 6, nil, Statenum::FATT_DIE8, 0, 0),                 # Statenum::FATT_DIE7
    State.new(Spritenum::FATT, 17, 6, nil, Statenum::FATT_DIE9, 0, 0),                 # Statenum::FATT_DIE8
    State.new(Spritenum::FATT, 18, 6, nil, Statenum::FATT_DIE10, 0, 0),                # Statenum::FATT_DIE9
    State.new(Spritenum::FATT, 19, -1, ->a_BossDeath, Statenum::NULL, 0, 0),           # Statenum::FATT_DIE10
    State.new(Spritenum::FATT, 17, 5, nil, Statenum::FATT_RAISE2, 0, 0),               # Statenum::FATT_RAISE1
    State.new(Spritenum::FATT, 16, 5, nil, Statenum::FATT_RAISE3, 0, 0),               # Statenum::FATT_RAISE2
    State.new(Spritenum::FATT, 15, 5, nil, Statenum::FATT_RAISE4, 0, 0),               # Statenum::FATT_RAISE3
    State.new(Spritenum::FATT, 14, 5, nil, Statenum::FATT_RAISE5, 0, 0),               # Statenum::FATT_RAISE4
    State.new(Spritenum::FATT, 13, 5, nil, Statenum::FATT_RAISE6, 0, 0),               # Statenum::FATT_RAISE5
    State.new(Spritenum::FATT, 12, 5, nil, Statenum::FATT_RAISE7, 0, 0),               # Statenum::FATT_RAISE6
    State.new(Spritenum::FATT, 11, 5, nil, Statenum::FATT_RAISE8, 0, 0),               # Statenum::FATT_RAISE7
    State.new(Spritenum::FATT, 10, 5, nil, Statenum::FATT_RUN1, 0, 0),                 # Statenum::FATT_RAISE8
    State.new(Spritenum::CPOS, 0, 10, ->a_Look, Statenum::CPOS_STND2, 0, 0),           # Statenum::CPOS_STND
    State.new(Spritenum::CPOS, 1, 10, ->a_Look, Statenum::CPOS_STND, 0, 0),            # Statenum::CPOS_STND2
    State.new(Spritenum::CPOS, 0, 3, ->a_Chase, Statenum::CPOS_RUN2, 0, 0),            # Statenum::CPOS_RUN1
    State.new(Spritenum::CPOS, 0, 3, ->a_Chase, Statenum::CPOS_RUN3, 0, 0),            # Statenum::CPOS_RUN2
    State.new(Spritenum::CPOS, 1, 3, ->a_Chase, Statenum::CPOS_RUN4, 0, 0),            # Statenum::CPOS_RUN3
    State.new(Spritenum::CPOS, 1, 3, ->a_Chase, Statenum::CPOS_RUN5, 0, 0),            # Statenum::CPOS_RUN4
    State.new(Spritenum::CPOS, 2, 3, ->a_Chase, Statenum::CPOS_RUN6, 0, 0),            # Statenum::CPOS_RUN5
    State.new(Spritenum::CPOS, 2, 3, ->a_Chase, Statenum::CPOS_RUN7, 0, 0),            # Statenum::CPOS_RUN6
    State.new(Spritenum::CPOS, 3, 3, ->a_Chase, Statenum::CPOS_RUN8, 0, 0),            # Statenum::CPOS_RUN7
    State.new(Spritenum::CPOS, 3, 3, ->a_Chase, Statenum::CPOS_RUN1, 0, 0),            # Statenum::CPOS_RUN8
    State.new(Spritenum::CPOS, 4, 10, ->a_FaceTarget, Statenum::CPOS_ATK2, 0, 0),      # Statenum::CPOS_ATK1
    State.new(Spritenum::CPOS, 32773, 4, ->a_CPosAttack, Statenum::CPOS_ATK3, 0, 0),   # Statenum::CPOS_ATK2
    State.new(Spritenum::CPOS, 32772, 4, ->a_CPosAttack, Statenum::CPOS_ATK4, 0, 0),   # Statenum::CPOS_ATK3
    State.new(Spritenum::CPOS, 5, 1, ->a_CPosRefire, Statenum::CPOS_ATK2, 0, 0),       # Statenum::CPOS_ATK4
    State.new(Spritenum::CPOS, 6, 3, nil, Statenum::CPOS_PAIN2, 0, 0),                 # Statenum::CPOS_PAIN
    State.new(Spritenum::CPOS, 6, 3, ->a_Pain, Statenum::CPOS_RUN1, 0, 0),             # Statenum::CPOS_PAIN2
    State.new(Spritenum::CPOS, 7, 5, nil, Statenum::CPOS_DIE2, 0, 0),                  # Statenum::CPOS_DIE1
    State.new(Spritenum::CPOS, 8, 5, ->a_Scream, Statenum::CPOS_DIE3, 0, 0),           # Statenum::CPOS_DIE2
    State.new(Spritenum::CPOS, 9, 5, ->a_Fall, Statenum::CPOS_DIE4, 0, 0),             # Statenum::CPOS_DIE3
    State.new(Spritenum::CPOS, 10, 5, nil, Statenum::CPOS_DIE5, 0, 0),                 # Statenum::CPOS_DIE4
    State.new(Spritenum::CPOS, 11, 5, nil, Statenum::CPOS_DIE6, 0, 0),                 # Statenum::CPOS_DIE5
    State.new(Spritenum::CPOS, 12, 5, nil, Statenum::CPOS_DIE7, 0, 0),                 # Statenum::CPOS_DIE6
    State.new(Spritenum::CPOS, 13, -1, nil, Statenum::NULL, 0, 0),                     # Statenum::CPOS_DIE7
    State.new(Spritenum::CPOS, 14, 5, nil, Statenum::CPOS_XDIE2, 0, 0),                # Statenum::CPOS_XDIE1
    State.new(Spritenum::CPOS, 15, 5, ->a_XScream, Statenum::CPOS_XDIE3, 0, 0),        # Statenum::CPOS_XDIE2
    State.new(Spritenum::CPOS, 16, 5, ->a_Fall, Statenum::CPOS_XDIE4, 0, 0),           # Statenum::CPOS_XDIE3
    State.new(Spritenum::CPOS, 17, 5, nil, Statenum::CPOS_XDIE5, 0, 0),                # Statenum::CPOS_XDIE4
    State.new(Spritenum::CPOS, 18, 5, nil, Statenum::CPOS_XDIE6, 0, 0),                # Statenum::CPOS_XDIE5
    State.new(Spritenum::CPOS, 19, -1, nil, Statenum::NULL, 0, 0),                     # Statenum::CPOS_XDIE6
    State.new(Spritenum::CPOS, 13, 5, nil, Statenum::CPOS_RAISE2, 0, 0),               # Statenum::CPOS_RAISE1
    State.new(Spritenum::CPOS, 12, 5, nil, Statenum::CPOS_RAISE3, 0, 0),               # Statenum::CPOS_RAISE2
    State.new(Spritenum::CPOS, 11, 5, nil, Statenum::CPOS_RAISE4, 0, 0),               # Statenum::CPOS_RAISE3
    State.new(Spritenum::CPOS, 10, 5, nil, Statenum::CPOS_RAISE5, 0, 0),               # Statenum::CPOS_RAISE4
    State.new(Spritenum::CPOS, 9, 5, nil, Statenum::CPOS_RAISE6, 0, 0),                # Statenum::CPOS_RAISE5
    State.new(Spritenum::CPOS, 8, 5, nil, Statenum::CPOS_RAISE7, 0, 0),                # Statenum::CPOS_RAISE6
    State.new(Spritenum::CPOS, 7, 5, nil, Statenum::CPOS_RUN1, 0, 0),                  # Statenum::CPOS_RAISE7
    State.new(Spritenum::TROO, 0, 10, ->a_Look, Statenum::TROO_STND2, 0, 0),           # Statenum::TROO_STND
    State.new(Spritenum::TROO, 1, 10, ->a_Look, Statenum::TROO_STND, 0, 0),            # Statenum::TROO_STND2
    State.new(Spritenum::TROO, 0, 3, ->a_Chase, Statenum::TROO_RUN2, 0, 0),            # Statenum::TROO_RUN1
    State.new(Spritenum::TROO, 0, 3, ->a_Chase, Statenum::TROO_RUN3, 0, 0),            # Statenum::TROO_RUN2
    State.new(Spritenum::TROO, 1, 3, ->a_Chase, Statenum::TROO_RUN4, 0, 0),            # Statenum::TROO_RUN3
    State.new(Spritenum::TROO, 1, 3, ->a_Chase, Statenum::TROO_RUN5, 0, 0),            # Statenum::TROO_RUN4
    State.new(Spritenum::TROO, 2, 3, ->a_Chase, Statenum::TROO_RUN6, 0, 0),            # Statenum::TROO_RUN5
    State.new(Spritenum::TROO, 2, 3, ->a_Chase, Statenum::TROO_RUN7, 0, 0),            # Statenum::TROO_RUN6
    State.new(Spritenum::TROO, 3, 3, ->a_Chase, Statenum::TROO_RUN8, 0, 0),            # Statenum::TROO_RUN7
    State.new(Spritenum::TROO, 3, 3, ->a_Chase, Statenum::TROO_RUN1, 0, 0),            # Statenum::TROO_RUN8
    State.new(Spritenum::TROO, 4, 8, ->a_FaceTarget, Statenum::TROO_ATK2, 0, 0),       # Statenum::TROO_ATK1
    State.new(Spritenum::TROO, 5, 8, ->a_FaceTarget, Statenum::TROO_ATK3, 0, 0),       # Statenum::TROO_ATK2
    State.new(Spritenum::TROO, 6, 6, ->a_TroopAttack, Statenum::TROO_RUN1, 0, 0),      # Statenum::TROO_ATK3
    State.new(Spritenum::TROO, 7, 2, nil, Statenum::TROO_PAIN2, 0, 0),                 # Statenum::TROO_PAIN
    State.new(Spritenum::TROO, 7, 2, ->a_Pain, Statenum::TROO_RUN1, 0, 0),             # Statenum::TROO_PAIN2
    State.new(Spritenum::TROO, 8, 8, nil, Statenum::TROO_DIE2, 0, 0),                  # Statenum::TROO_DIE1
    State.new(Spritenum::TROO, 9, 8, ->a_Scream, Statenum::TROO_DIE3, 0, 0),           # Statenum::TROO_DIE2
    State.new(Spritenum::TROO, 10, 6, nil, Statenum::TROO_DIE4, 0, 0),                 # Statenum::TROO_DIE3
    State.new(Spritenum::TROO, 11, 6, ->a_Fall, Statenum::TROO_DIE5, 0, 0),            # Statenum::TROO_DIE4
    State.new(Spritenum::TROO, 12, -1, nil, Statenum::NULL, 0, 0),                     # Statenum::TROO_DIE5
    State.new(Spritenum::TROO, 13, 5, nil, Statenum::TROO_XDIE2, 0, 0),                # Statenum::TROO_XDIE1
    State.new(Spritenum::TROO, 14, 5, ->a_XScream, Statenum::TROO_XDIE3, 0, 0),        # Statenum::TROO_XDIE2
    State.new(Spritenum::TROO, 15, 5, nil, Statenum::TROO_XDIE4, 0, 0),                # Statenum::TROO_XDIE3
    State.new(Spritenum::TROO, 16, 5, ->a_Fall, Statenum::TROO_XDIE5, 0, 0),           # Statenum::TROO_XDIE4
    State.new(Spritenum::TROO, 17, 5, nil, Statenum::TROO_XDIE6, 0, 0),                # Statenum::TROO_XDIE5
    State.new(Spritenum::TROO, 18, 5, nil, Statenum::TROO_XDIE7, 0, 0),                # Statenum::TROO_XDIE6
    State.new(Spritenum::TROO, 19, 5, nil, Statenum::TROO_XDIE8, 0, 0),                # Statenum::TROO_XDIE7
    State.new(Spritenum::TROO, 20, -1, nil, Statenum::NULL, 0, 0),                     # Statenum::TROO_XDIE8
    State.new(Spritenum::TROO, 12, 8, nil, Statenum::TROO_RAISE2, 0, 0),               # Statenum::TROO_RAISE1
    State.new(Spritenum::TROO, 11, 8, nil, Statenum::TROO_RAISE3, 0, 0),               # Statenum::TROO_RAISE2
    State.new(Spritenum::TROO, 10, 6, nil, Statenum::TROO_RAISE4, 0, 0),               # Statenum::TROO_RAISE3
    State.new(Spritenum::TROO, 9, 6, nil, Statenum::TROO_RAISE5, 0, 0),                # Statenum::TROO_RAISE4
    State.new(Spritenum::TROO, 8, 6, nil, Statenum::TROO_RUN1, 0, 0),                  # Statenum::TROO_RAISE5
    State.new(Spritenum::SARG, 0, 10, ->a_Look, Statenum::SARG_STND2, 0, 0),           # Statenum::SARG_STND
    State.new(Spritenum::SARG, 1, 10, ->a_Look, Statenum::SARG_STND, 0, 0),            # Statenum::SARG_STND2
    State.new(Spritenum::SARG, 0, 2, ->a_Chase, Statenum::SARG_RUN2, 0, 0),            # Statenum::SARG_RUN1
    State.new(Spritenum::SARG, 0, 2, ->a_Chase, Statenum::SARG_RUN3, 0, 0),            # Statenum::SARG_RUN2
    State.new(Spritenum::SARG, 1, 2, ->a_Chase, Statenum::SARG_RUN4, 0, 0),            # Statenum::SARG_RUN3
    State.new(Spritenum::SARG, 1, 2, ->a_Chase, Statenum::SARG_RUN5, 0, 0),            # Statenum::SARG_RUN4
    State.new(Spritenum::SARG, 2, 2, ->a_Chase, Statenum::SARG_RUN6, 0, 0),            # Statenum::SARG_RUN5
    State.new(Spritenum::SARG, 2, 2, ->a_Chase, Statenum::SARG_RUN7, 0, 0),            # Statenum::SARG_RUN6
    State.new(Spritenum::SARG, 3, 2, ->a_Chase, Statenum::SARG_RUN8, 0, 0),            # Statenum::SARG_RUN7
    State.new(Spritenum::SARG, 3, 2, ->a_Chase, Statenum::SARG_RUN1, 0, 0),            # Statenum::SARG_RUN8
    State.new(Spritenum::SARG, 4, 8, ->a_FaceTarget, Statenum::SARG_ATK2, 0, 0),       # Statenum::SARG_ATK1
    State.new(Spritenum::SARG, 5, 8, ->a_FaceTarget, Statenum::SARG_ATK3, 0, 0),       # Statenum::SARG_ATK2
    State.new(Spritenum::SARG, 6, 8, ->a_SargAttack, Statenum::SARG_RUN1, 0, 0),       # Statenum::SARG_ATK3
    State.new(Spritenum::SARG, 7, 2, nil, Statenum::SARG_PAIN2, 0, 0),                 # Statenum::SARG_PAIN
    State.new(Spritenum::SARG, 7, 2, ->a_Pain, Statenum::SARG_RUN1, 0, 0),             # Statenum::SARG_PAIN2
    State.new(Spritenum::SARG, 8, 8, nil, Statenum::SARG_DIE2, 0, 0),                  # Statenum::SARG_DIE1
    State.new(Spritenum::SARG, 9, 8, ->a_Scream, Statenum::SARG_DIE3, 0, 0),           # Statenum::SARG_DIE2
    State.new(Spritenum::SARG, 10, 4, nil, Statenum::SARG_DIE4, 0, 0),                 # Statenum::SARG_DIE3
    State.new(Spritenum::SARG, 11, 4, ->a_Fall, Statenum::SARG_DIE5, 0, 0),            # Statenum::SARG_DIE4
    State.new(Spritenum::SARG, 12, 4, nil, Statenum::SARG_DIE6, 0, 0),                 # Statenum::SARG_DIE5
    State.new(Spritenum::SARG, 13, -1, nil, Statenum::NULL, 0, 0),                     # Statenum::SARG_DIE6
    State.new(Spritenum::SARG, 13, 5, nil, Statenum::SARG_RAISE2, 0, 0),               # Statenum::SARG_RAISE1
    State.new(Spritenum::SARG, 12, 5, nil, Statenum::SARG_RAISE3, 0, 0),               # Statenum::SARG_RAISE2
    State.new(Spritenum::SARG, 11, 5, nil, Statenum::SARG_RAISE4, 0, 0),               # Statenum::SARG_RAISE3
    State.new(Spritenum::SARG, 10, 5, nil, Statenum::SARG_RAISE5, 0, 0),               # Statenum::SARG_RAISE4
    State.new(Spritenum::SARG, 9, 5, nil, Statenum::SARG_RAISE6, 0, 0),                # Statenum::SARG_RAISE5
    State.new(Spritenum::SARG, 8, 5, nil, Statenum::SARG_RUN1, 0, 0),                  # Statenum::SARG_RAISE6
    State.new(Spritenum::HEAD, 0, 10, ->a_Look, Statenum::HEAD_STND, 0, 0),            # Statenum::HEAD_STND
    State.new(Spritenum::HEAD, 0, 3, ->a_Chase, Statenum::HEAD_RUN1, 0, 0),            # Statenum::HEAD_RUN1
    State.new(Spritenum::HEAD, 1, 5, ->a_FaceTarget, Statenum::HEAD_ATK2, 0, 0),       # Statenum::HEAD_ATK1
    State.new(Spritenum::HEAD, 2, 5, ->a_FaceTarget, Statenum::HEAD_ATK3, 0, 0),       # Statenum::HEAD_ATK2
    State.new(Spritenum::HEAD, 32771, 5, ->a_HeadAttack, Statenum::HEAD_RUN1, 0, 0),   # Statenum::HEAD_ATK3
    State.new(Spritenum::HEAD, 4, 3, nil, Statenum::HEAD_PAIN2, 0, 0),                 # Statenum::HEAD_PAIN
    State.new(Spritenum::HEAD, 4, 3, ->a_Pain, Statenum::HEAD_PAIN3, 0, 0),            # Statenum::HEAD_PAIN2
    State.new(Spritenum::HEAD, 5, 6, nil, Statenum::HEAD_RUN1, 0, 0),                  # Statenum::HEAD_PAIN3
    State.new(Spritenum::HEAD, 6, 8, nil, Statenum::HEAD_DIE2, 0, 0),                  # Statenum::HEAD_DIE1
    State.new(Spritenum::HEAD, 7, 8, ->a_Scream, Statenum::HEAD_DIE3, 0, 0),           # Statenum::HEAD_DIE2
    State.new(Spritenum::HEAD, 8, 8, nil, Statenum::HEAD_DIE4, 0, 0),                  # Statenum::HEAD_DIE3
    State.new(Spritenum::HEAD, 9, 8, nil, Statenum::HEAD_DIE5, 0, 0),                  # Statenum::HEAD_DIE4
    State.new(Spritenum::HEAD, 10, 8, ->a_Fall, Statenum::HEAD_DIE6, 0, 0),            # Statenum::HEAD_DIE5
    State.new(Spritenum::HEAD, 11, -1, nil, Statenum::NULL, 0, 0),                     # Statenum::HEAD_DIE6
    State.new(Spritenum::HEAD, 11, 8, nil, Statenum::HEAD_RAISE2, 0, 0),               # Statenum::HEAD_RAISE1
    State.new(Spritenum::HEAD, 10, 8, nil, Statenum::HEAD_RAISE3, 0, 0),               # Statenum::HEAD_RAISE2
    State.new(Spritenum::HEAD, 9, 8, nil, Statenum::HEAD_RAISE4, 0, 0),                # Statenum::HEAD_RAISE3
    State.new(Spritenum::HEAD, 8, 8, nil, Statenum::HEAD_RAISE5, 0, 0),                # Statenum::HEAD_RAISE4
    State.new(Spritenum::HEAD, 7, 8, nil, Statenum::HEAD_RAISE6, 0, 0),                # Statenum::HEAD_RAISE5
    State.new(Spritenum::HEAD, 6, 8, nil, Statenum::HEAD_RUN1, 0, 0),                  # Statenum::HEAD_RAISE6
    State.new(Spritenum::BAL7, 32768, 4, nil, Statenum::BRBALL2, 0, 0),                # Statenum::BRBALL1
    State.new(Spritenum::BAL7, 32769, 4, nil, Statenum::BRBALL1, 0, 0),                # Statenum::BRBALL2
    State.new(Spritenum::BAL7, 32770, 6, nil, Statenum::BRBALLX2, 0, 0),               # Statenum::BRBALLX1
    State.new(Spritenum::BAL7, 32771, 6, nil, Statenum::BRBALLX3, 0, 0),               # Statenum::BRBALLX2
    State.new(Spritenum::BAL7, 32772, 6, nil, Statenum::NULL, 0, 0),                   # Statenum::BRBALLX3
    State.new(Spritenum::BOSS, 0, 10, ->a_Look, Statenum::BOSS_STND2, 0, 0),           # Statenum::BOSS_STND
    State.new(Spritenum::BOSS, 1, 10, ->a_Look, Statenum::BOSS_STND, 0, 0),            # Statenum::BOSS_STND2
    State.new(Spritenum::BOSS, 0, 3, ->a_Chase, Statenum::BOSS_RUN2, 0, 0),            # Statenum::BOSS_RUN1
    State.new(Spritenum::BOSS, 0, 3, ->a_Chase, Statenum::BOSS_RUN3, 0, 0),            # Statenum::BOSS_RUN2
    State.new(Spritenum::BOSS, 1, 3, ->a_Chase, Statenum::BOSS_RUN4, 0, 0),            # Statenum::BOSS_RUN3
    State.new(Spritenum::BOSS, 1, 3, ->a_Chase, Statenum::BOSS_RUN5, 0, 0),            # Statenum::BOSS_RUN4
    State.new(Spritenum::BOSS, 2, 3, ->a_Chase, Statenum::BOSS_RUN6, 0, 0),            # Statenum::BOSS_RUN5
    State.new(Spritenum::BOSS, 2, 3, ->a_Chase, Statenum::BOSS_RUN7, 0, 0),            # Statenum::BOSS_RUN6
    State.new(Spritenum::BOSS, 3, 3, ->a_Chase, Statenum::BOSS_RUN8, 0, 0),            # Statenum::BOSS_RUN7
    State.new(Spritenum::BOSS, 3, 3, ->a_Chase, Statenum::BOSS_RUN1, 0, 0),            # Statenum::BOSS_RUN8
    State.new(Spritenum::BOSS, 4, 8, ->a_FaceTarget, Statenum::BOSS_ATK2, 0, 0),       # Statenum::BOSS_ATK1
    State.new(Spritenum::BOSS, 5, 8, ->a_FaceTarget, Statenum::BOSS_ATK3, 0, 0),       # Statenum::BOSS_ATK2
    State.new(Spritenum::BOSS, 6, 8, ->a_BruisAttack, Statenum::BOSS_RUN1, 0, 0),      # Statenum::BOSS_ATK3
    State.new(Spritenum::BOSS, 7, 2, nil, Statenum::BOSS_PAIN2, 0, 0),                 # Statenum::BOSS_PAIN
    State.new(Spritenum::BOSS, 7, 2, ->a_Pain, Statenum::BOSS_RUN1, 0, 0),             # Statenum::BOSS_PAIN2
    State.new(Spritenum::BOSS, 8, 8, nil, Statenum::BOSS_DIE2, 0, 0),                  # Statenum::BOSS_DIE1
    State.new(Spritenum::BOSS, 9, 8, ->a_Scream, Statenum::BOSS_DIE3, 0, 0),           # Statenum::BOSS_DIE2
    State.new(Spritenum::BOSS, 10, 8, nil, Statenum::BOSS_DIE4, 0, 0),                 # Statenum::BOSS_DIE3
    State.new(Spritenum::BOSS, 11, 8, ->a_Fall, Statenum::BOSS_DIE5, 0, 0),            # Statenum::BOSS_DIE4
    State.new(Spritenum::BOSS, 12, 8, nil, Statenum::BOSS_DIE6, 0, 0),                 # Statenum::BOSS_DIE5
    State.new(Spritenum::BOSS, 13, 8, nil, Statenum::BOSS_DIE7, 0, 0),                 # Statenum::BOSS_DIE6
    State.new(Spritenum::BOSS, 14, -1, ->a_BossDeath, Statenum::NULL, 0, 0),           # Statenum::BOSS_DIE7
    State.new(Spritenum::BOSS, 14, 8, nil, Statenum::BOSS_RAISE2, 0, 0),               # Statenum::BOSS_RAISE1
    State.new(Spritenum::BOSS, 13, 8, nil, Statenum::BOSS_RAISE3, 0, 0),               # Statenum::BOSS_RAISE2
    State.new(Spritenum::BOSS, 12, 8, nil, Statenum::BOSS_RAISE4, 0, 0),               # Statenum::BOSS_RAISE3
    State.new(Spritenum::BOSS, 11, 8, nil, Statenum::BOSS_RAISE5, 0, 0),               # Statenum::BOSS_RAISE4
    State.new(Spritenum::BOSS, 10, 8, nil, Statenum::BOSS_RAISE6, 0, 0),               # Statenum::BOSS_RAISE5
    State.new(Spritenum::BOSS, 9, 8, nil, Statenum::BOSS_RAISE7, 0, 0),                # Statenum::BOSS_RAISE6
    State.new(Spritenum::BOSS, 8, 8, nil, Statenum::BOSS_RUN1, 0, 0),                  # Statenum::BOSS_RAISE7
    State.new(Spritenum::BOS2, 0, 10, ->a_Look, Statenum::BOS2_STND2, 0, 0),           # Statenum::BOS2_STND
    State.new(Spritenum::BOS2, 1, 10, ->a_Look, Statenum::BOS2_STND, 0, 0),            # Statenum::BOS2_STND2
    State.new(Spritenum::BOS2, 0, 3, ->a_Chase, Statenum::BOS2_RUN2, 0, 0),            # Statenum::BOS2_RUN1
    State.new(Spritenum::BOS2, 0, 3, ->a_Chase, Statenum::BOS2_RUN3, 0, 0),            # Statenum::BOS2_RUN2
    State.new(Spritenum::BOS2, 1, 3, ->a_Chase, Statenum::BOS2_RUN4, 0, 0),            # Statenum::BOS2_RUN3
    State.new(Spritenum::BOS2, 1, 3, ->a_Chase, Statenum::BOS2_RUN5, 0, 0),            # Statenum::BOS2_RUN4
    State.new(Spritenum::BOS2, 2, 3, ->a_Chase, Statenum::BOS2_RUN6, 0, 0),            # Statenum::BOS2_RUN5
    State.new(Spritenum::BOS2, 2, 3, ->a_Chase, Statenum::BOS2_RUN7, 0, 0),            # Statenum::BOS2_RUN6
    State.new(Spritenum::BOS2, 3, 3, ->a_Chase, Statenum::BOS2_RUN8, 0, 0),            # Statenum::BOS2_RUN7
    State.new(Spritenum::BOS2, 3, 3, ->a_Chase, Statenum::BOS2_RUN1, 0, 0),            # Statenum::BOS2_RUN8
    State.new(Spritenum::BOS2, 4, 8, ->a_FaceTarget, Statenum::BOS2_ATK2, 0, 0),       # Statenum::BOS2_ATK1
    State.new(Spritenum::BOS2, 5, 8, ->a_FaceTarget, Statenum::BOS2_ATK3, 0, 0),       # Statenum::BOS2_ATK2
    State.new(Spritenum::BOS2, 6, 8, ->a_BruisAttack, Statenum::BOS2_RUN1, 0, 0),      # Statenum::BOS2_ATK3
    State.new(Spritenum::BOS2, 7, 2, nil, Statenum::BOS2_PAIN2, 0, 0),                 # Statenum::BOS2_PAIN
    State.new(Spritenum::BOS2, 7, 2, ->a_Pain, Statenum::BOS2_RUN1, 0, 0),             # Statenum::BOS2_PAIN2
    State.new(Spritenum::BOS2, 8, 8, nil, Statenum::BOS2_DIE2, 0, 0),                  # Statenum::BOS2_DIE1
    State.new(Spritenum::BOS2, 9, 8, ->a_Scream, Statenum::BOS2_DIE3, 0, 0),           # Statenum::BOS2_DIE2
    State.new(Spritenum::BOS2, 10, 8, nil, Statenum::BOS2_DIE4, 0, 0),                 # Statenum::BOS2_DIE3
    State.new(Spritenum::BOS2, 11, 8, ->a_Fall, Statenum::BOS2_DIE5, 0, 0),            # Statenum::BOS2_DIE4
    State.new(Spritenum::BOS2, 12, 8, nil, Statenum::BOS2_DIE6, 0, 0),                 # Statenum::BOS2_DIE5
    State.new(Spritenum::BOS2, 13, 8, nil, Statenum::BOS2_DIE7, 0, 0),                 # Statenum::BOS2_DIE6
    State.new(Spritenum::BOS2, 14, -1, nil, Statenum::NULL, 0, 0),                     # Statenum::BOS2_DIE7
    State.new(Spritenum::BOS2, 14, 8, nil, Statenum::BOS2_RAISE2, 0, 0),               # Statenum::BOS2_RAISE1
    State.new(Spritenum::BOS2, 13, 8, nil, Statenum::BOS2_RAISE3, 0, 0),               # Statenum::BOS2_RAISE2
    State.new(Spritenum::BOS2, 12, 8, nil, Statenum::BOS2_RAISE4, 0, 0),               # Statenum::BOS2_RAISE3
    State.new(Spritenum::BOS2, 11, 8, nil, Statenum::BOS2_RAISE5, 0, 0),               # Statenum::BOS2_RAISE4
    State.new(Spritenum::BOS2, 10, 8, nil, Statenum::BOS2_RAISE6, 0, 0),               # Statenum::BOS2_RAISE5
    State.new(Spritenum::BOS2, 9, 8, nil, Statenum::BOS2_RAISE7, 0, 0),                # Statenum::BOS2_RAISE6
    State.new(Spritenum::BOS2, 8, 8, nil, Statenum::BOS2_RUN1, 0, 0),                  # Statenum::BOS2_RAISE7
    State.new(Spritenum::SKUL, 32768, 10, ->a_Look, Statenum::SKULL_STND2, 0, 0),      # Statenum::SKULL_STND
    State.new(Spritenum::SKUL, 32769, 10, ->a_Look, Statenum::SKULL_STND, 0, 0),       # Statenum::SKULL_STND2
    State.new(Spritenum::SKUL, 32768, 6, ->a_Chase, Statenum::SKULL_RUN2, 0, 0),       # Statenum::SKULL_RUN1
    State.new(Spritenum::SKUL, 32769, 6, ->a_Chase, Statenum::SKULL_RUN1, 0, 0),       # Statenum::SKULL_RUN2
    State.new(Spritenum::SKUL, 32770, 10, ->a_FaceTarget, Statenum::SKULL_ATK2, 0, 0), # Statenum::SKULL_ATK1
    State.new(Spritenum::SKUL, 32771, 4, ->a_SkullAttack, Statenum::SKULL_ATK3, 0, 0), # Statenum::SKULL_ATK2
    State.new(Spritenum::SKUL, 32770, 4, nil, Statenum::SKULL_ATK4, 0, 0),             # Statenum::SKULL_ATK3
    State.new(Spritenum::SKUL, 32771, 4, nil, Statenum::SKULL_ATK3, 0, 0),             # Statenum::SKULL_ATK4
    State.new(Spritenum::SKUL, 32772, 3, nil, Statenum::SKULL_PAIN2, 0, 0),            # Statenum::SKULL_PAIN
    State.new(Spritenum::SKUL, 32772, 3, ->a_Pain, Statenum::SKULL_RUN1, 0, 0),        # Statenum::SKULL_PAIN2
    State.new(Spritenum::SKUL, 32773, 6, nil, Statenum::SKULL_DIE2, 0, 0),             # Statenum::SKULL_DIE1
    State.new(Spritenum::SKUL, 32774, 6, ->a_Scream, Statenum::SKULL_DIE3, 0, 0),      # Statenum::SKULL_DIE2
    State.new(Spritenum::SKUL, 32775, 6, nil, Statenum::SKULL_DIE4, 0, 0),             # Statenum::SKULL_DIE3
    State.new(Spritenum::SKUL, 32776, 6, ->a_Fall, Statenum::SKULL_DIE5, 0, 0),        # Statenum::SKULL_DIE4
    State.new(Spritenum::SKUL, 9, 6, nil, Statenum::SKULL_DIE6, 0, 0),                 # Statenum::SKULL_DIE5
    State.new(Spritenum::SKUL, 10, 6, nil, Statenum::NULL, 0, 0),                      # Statenum::SKULL_DIE6
    State.new(Spritenum::SPID, 0, 10, ->a_Look, Statenum::SPID_STND2, 0, 0),           # Statenum::SPID_STND
    State.new(Spritenum::SPID, 1, 10, ->a_Look, Statenum::SPID_STND, 0, 0),            # Statenum::SPID_STND2
    State.new(Spritenum::SPID, 0, 3, ->a_Metal, Statenum::SPID_RUN2, 0, 0),            # Statenum::SPID_RUN1
    State.new(Spritenum::SPID, 0, 3, ->a_Chase, Statenum::SPID_RUN3, 0, 0),            # Statenum::SPID_RUN2
    State.new(Spritenum::SPID, 1, 3, ->a_Chase, Statenum::SPID_RUN4, 0, 0),            # Statenum::SPID_RUN3
    State.new(Spritenum::SPID, 1, 3, ->a_Chase, Statenum::SPID_RUN5, 0, 0),            # Statenum::SPID_RUN4
    State.new(Spritenum::SPID, 2, 3, ->a_Metal, Statenum::SPID_RUN6, 0, 0),            # Statenum::SPID_RUN5
    State.new(Spritenum::SPID, 2, 3, ->a_Chase, Statenum::SPID_RUN7, 0, 0),            # Statenum::SPID_RUN6
    State.new(Spritenum::SPID, 3, 3, ->a_Chase, Statenum::SPID_RUN8, 0, 0),            # Statenum::SPID_RUN7
    State.new(Spritenum::SPID, 3, 3, ->a_Chase, Statenum::SPID_RUN9, 0, 0),            # Statenum::SPID_RUN8
    State.new(Spritenum::SPID, 4, 3, ->a_Metal, Statenum::SPID_RUN10, 0, 0),           # Statenum::SPID_RUN9
    State.new(Spritenum::SPID, 4, 3, ->a_Chase, Statenum::SPID_RUN11, 0, 0),           # Statenum::SPID_RUN10
    State.new(Spritenum::SPID, 5, 3, ->a_Chase, Statenum::SPID_RUN12, 0, 0),           # Statenum::SPID_RUN11
    State.new(Spritenum::SPID, 5, 3, ->a_Chase, Statenum::SPID_RUN1, 0, 0),            # Statenum::SPID_RUN12
    State.new(Spritenum::SPID, 32768, 20, ->a_FaceTarget, Statenum::SPID_ATK2, 0, 0),  # Statenum::SPID_ATK1
    State.new(Spritenum::SPID, 32774, 4, ->a_SPosAttack, Statenum::SPID_ATK3, 0, 0),   # Statenum::SPID_ATK2
    State.new(Spritenum::SPID, 32775, 4, ->a_SPosAttack, Statenum::SPID_ATK4, 0, 0),   # Statenum::SPID_ATK3
    State.new(Spritenum::SPID, 32775, 1, ->a_SpidRefire, Statenum::SPID_ATK2, 0, 0),   # Statenum::SPID_ATK4
    State.new(Spritenum::SPID, 8, 3, nil, Statenum::SPID_PAIN2, 0, 0),                 # Statenum::SPID_PAIN
    State.new(Spritenum::SPID, 8, 3, ->a_Pain, Statenum::SPID_RUN1, 0, 0),             # Statenum::SPID_PAIN2
    State.new(Spritenum::SPID, 9, 20, ->a_Scream, Statenum::SPID_DIE2, 0, 0),          # Statenum::SPID_DIE1
    State.new(Spritenum::SPID, 10, 10, ->a_Fall, Statenum::SPID_DIE3, 0, 0),           # Statenum::SPID_DIE2
    State.new(Spritenum::SPID, 11, 10, nil, Statenum::SPID_DIE4, 0, 0),                # Statenum::SPID_DIE3
    State.new(Spritenum::SPID, 12, 10, nil, Statenum::SPID_DIE5, 0, 0),                # Statenum::SPID_DIE4
    State.new(Spritenum::SPID, 13, 10, nil, Statenum::SPID_DIE6, 0, 0),                # Statenum::SPID_DIE5
    State.new(Spritenum::SPID, 14, 10, nil, Statenum::SPID_DIE7, 0, 0),                # Statenum::SPID_DIE6
    State.new(Spritenum::SPID, 15, 10, nil, Statenum::SPID_DIE8, 0, 0),                # Statenum::SPID_DIE7
    State.new(Spritenum::SPID, 16, 10, nil, Statenum::SPID_DIE9, 0, 0),                # Statenum::SPID_DIE8
    State.new(Spritenum::SPID, 17, 10, nil, Statenum::SPID_DIE10, 0, 0),               # Statenum::SPID_DIE9
    State.new(Spritenum::SPID, 18, 30, nil, Statenum::SPID_DIE11, 0, 0),               # Statenum::SPID_DIE10
    State.new(Spritenum::SPID, 18, -1, ->a_BossDeath, Statenum::NULL, 0, 0),           # Statenum::SPID_DIE11
    State.new(Spritenum::BSPI, 0, 10, ->a_Look, Statenum::BSPI_STND2, 0, 0),           # Statenum::BSPI_STND
    State.new(Spritenum::BSPI, 1, 10, ->a_Look, Statenum::BSPI_STND, 0, 0),            # Statenum::BSPI_STND2
    State.new(Spritenum::BSPI, 0, 20, nil, Statenum::BSPI_RUN1, 0, 0),                 # Statenum::BSPI_SIGHT
    State.new(Spritenum::BSPI, 0, 3, ->a_BabyMetal, Statenum::BSPI_RUN2, 0, 0),        # Statenum::BSPI_RUN1
    State.new(Spritenum::BSPI, 0, 3, ->a_Chase, Statenum::BSPI_RUN3, 0, 0),            # Statenum::BSPI_RUN2
    State.new(Spritenum::BSPI, 1, 3, ->a_Chase, Statenum::BSPI_RUN4, 0, 0),            # Statenum::BSPI_RUN3
    State.new(Spritenum::BSPI, 1, 3, ->a_Chase, Statenum::BSPI_RUN5, 0, 0),            # Statenum::BSPI_RUN4
    State.new(Spritenum::BSPI, 2, 3, ->a_Chase, Statenum::BSPI_RUN6, 0, 0),            # Statenum::BSPI_RUN5
    State.new(Spritenum::BSPI, 2, 3, ->a_Chase, Statenum::BSPI_RUN7, 0, 0),            # Statenum::BSPI_RUN6
    State.new(Spritenum::BSPI, 3, 3, ->a_BabyMetal, Statenum::BSPI_RUN8, 0, 0),        # Statenum::BSPI_RUN7
    State.new(Spritenum::BSPI, 3, 3, ->a_Chase, Statenum::BSPI_RUN9, 0, 0),            # Statenum::BSPI_RUN8
    State.new(Spritenum::BSPI, 4, 3, ->a_Chase, Statenum::BSPI_RUN10, 0, 0),           # Statenum::BSPI_RUN9
    State.new(Spritenum::BSPI, 4, 3, ->a_Chase, Statenum::BSPI_RUN11, 0, 0),           # Statenum::BSPI_RUN10
    State.new(Spritenum::BSPI, 5, 3, ->a_Chase, Statenum::BSPI_RUN12, 0, 0),           # Statenum::BSPI_RUN11
    State.new(Spritenum::BSPI, 5, 3, ->a_Chase, Statenum::BSPI_RUN1, 0, 0),            # Statenum::BSPI_RUN12
    State.new(Spritenum::BSPI, 32768, 20, ->a_FaceTarget, Statenum::BSPI_ATK2, 0, 0),  # Statenum::BSPI_ATK1
    State.new(Spritenum::BSPI, 32774, 4, ->a_BspiAttack, Statenum::BSPI_ATK3, 0, 0),   # Statenum::BSPI_ATK2
    State.new(Spritenum::BSPI, 32775, 4, nil, Statenum::BSPI_ATK4, 0, 0),              # Statenum::BSPI_ATK3
    State.new(Spritenum::BSPI, 32775, 1, ->a_SpidRefire, Statenum::BSPI_ATK2, 0, 0),   # Statenum::BSPI_ATK4
    State.new(Spritenum::BSPI, 8, 3, nil, Statenum::BSPI_PAIN2, 0, 0),                 # Statenum::BSPI_PAIN
    State.new(Spritenum::BSPI, 8, 3, ->a_Pain, Statenum::BSPI_RUN1, 0, 0),             # Statenum::BSPI_PAIN2
    State.new(Spritenum::BSPI, 9, 20, ->a_Scream, Statenum::BSPI_DIE2, 0, 0),          # Statenum::BSPI_DIE1
    State.new(Spritenum::BSPI, 10, 7, ->a_Fall, Statenum::BSPI_DIE3, 0, 0),            # Statenum::BSPI_DIE2
    State.new(Spritenum::BSPI, 11, 7, nil, Statenum::BSPI_DIE4, 0, 0),                 # Statenum::BSPI_DIE3
    State.new(Spritenum::BSPI, 12, 7, nil, Statenum::BSPI_DIE5, 0, 0),                 # Statenum::BSPI_DIE4
    State.new(Spritenum::BSPI, 13, 7, nil, Statenum::BSPI_DIE6, 0, 0),                 # Statenum::BSPI_DIE5
    State.new(Spritenum::BSPI, 14, 7, nil, Statenum::BSPI_DIE7, 0, 0),                 # Statenum::BSPI_DIE6
    State.new(Spritenum::BSPI, 15, -1, ->a_BossDeath, Statenum::NULL, 0, 0),           # Statenum::BSPI_DIE7
    State.new(Spritenum::BSPI, 15, 5, nil, Statenum::BSPI_RAISE2, 0, 0),               # Statenum::BSPI_RAISE1
    State.new(Spritenum::BSPI, 14, 5, nil, Statenum::BSPI_RAISE3, 0, 0),               # Statenum::BSPI_RAISE2
    State.new(Spritenum::BSPI, 13, 5, nil, Statenum::BSPI_RAISE4, 0, 0),               # Statenum::BSPI_RAISE3
    State.new(Spritenum::BSPI, 12, 5, nil, Statenum::BSPI_RAISE5, 0, 0),               # Statenum::BSPI_RAISE4
    State.new(Spritenum::BSPI, 11, 5, nil, Statenum::BSPI_RAISE6, 0, 0),               # Statenum::BSPI_RAISE5
    State.new(Spritenum::BSPI, 10, 5, nil, Statenum::BSPI_RAISE7, 0, 0),               # Statenum::BSPI_RAISE6
    State.new(Spritenum::BSPI, 9, 5, nil, Statenum::BSPI_RUN1, 0, 0),                  # Statenum::BSPI_RAISE7
    State.new(Spritenum::APLS, 32768, 5, nil, Statenum::ARACH_PLAZ2, 0, 0),            # Statenum::ARACH_PLAZ
    State.new(Spritenum::APLS, 32769, 5, nil, Statenum::ARACH_PLAZ, 0, 0),             # Statenum::ARACH_PLAZ2
    State.new(Spritenum::APBX, 32768, 5, nil, Statenum::ARACH_PLEX2, 0, 0),            # Statenum::ARACH_PLEX
    State.new(Spritenum::APBX, 32769, 5, nil, Statenum::ARACH_PLEX3, 0, 0),            # Statenum::ARACH_PLEX2
    State.new(Spritenum::APBX, 32770, 5, nil, Statenum::ARACH_PLEX4, 0, 0),            # Statenum::ARACH_PLEX3
    State.new(Spritenum::APBX, 32771, 5, nil, Statenum::ARACH_PLEX5, 0, 0),            # Statenum::ARACH_PLEX4
    State.new(Spritenum::APBX, 32772, 5, nil, Statenum::NULL, 0, 0),                   # Statenum::ARACH_PLEX5
    State.new(Spritenum::CYBR, 0, 10, ->a_Look, Statenum::CYBER_STND2, 0, 0),          # Statenum::CYBER_STND
    State.new(Spritenum::CYBR, 1, 10, ->a_Look, Statenum::CYBER_STND, 0, 0),           # Statenum::CYBER_STND2
    State.new(Spritenum::CYBR, 0, 3, ->a_Hoof, Statenum::CYBER_RUN2, 0, 0),            # Statenum::CYBER_RUN1
    State.new(Spritenum::CYBR, 0, 3, ->a_Chase, Statenum::CYBER_RUN3, 0, 0),           # Statenum::CYBER_RUN2
    State.new(Spritenum::CYBR, 1, 3, ->a_Chase, Statenum::CYBER_RUN4, 0, 0),           # Statenum::CYBER_RUN3
    State.new(Spritenum::CYBR, 1, 3, ->a_Chase, Statenum::CYBER_RUN5, 0, 0),           # Statenum::CYBER_RUN4
    State.new(Spritenum::CYBR, 2, 3, ->a_Chase, Statenum::CYBER_RUN6, 0, 0),           # Statenum::CYBER_RUN5
    State.new(Spritenum::CYBR, 2, 3, ->a_Chase, Statenum::CYBER_RUN7, 0, 0),           # Statenum::CYBER_RUN6
    State.new(Spritenum::CYBR, 3, 3, ->a_Metal, Statenum::CYBER_RUN8, 0, 0),           # Statenum::CYBER_RUN7
    State.new(Spritenum::CYBR, 3, 3, ->a_Chase, Statenum::CYBER_RUN1, 0, 0),           # Statenum::CYBER_RUN8
    State.new(Spritenum::CYBR, 4, 6, ->a_FaceTarget, Statenum::CYBER_ATK2, 0, 0),      # Statenum::CYBER_ATK1
    State.new(Spritenum::CYBR, 5, 12, ->a_CyberAttack, Statenum::CYBER_ATK3, 0, 0),    # Statenum::CYBER_ATK2
    State.new(Spritenum::CYBR, 4, 12, ->a_FaceTarget, Statenum::CYBER_ATK4, 0, 0),     # Statenum::CYBER_ATK3
    State.new(Spritenum::CYBR, 5, 12, ->a_CyberAttack, Statenum::CYBER_ATK5, 0, 0),    # Statenum::CYBER_ATK4
    State.new(Spritenum::CYBR, 4, 12, ->a_FaceTarget, Statenum::CYBER_ATK6, 0, 0),     # Statenum::CYBER_ATK5
    State.new(Spritenum::CYBR, 5, 12, ->a_CyberAttack, Statenum::CYBER_RUN1, 0, 0),    # Statenum::CYBER_ATK6
    State.new(Spritenum::CYBR, 6, 10, ->a_Pain, Statenum::CYBER_RUN1, 0, 0),           # Statenum::CYBER_PAIN
    State.new(Spritenum::CYBR, 7, 10, nil, Statenum::CYBER_DIE2, 0, 0),                # Statenum::CYBER_DIE1
    State.new(Spritenum::CYBR, 8, 10, ->a_Scream, Statenum::CYBER_DIE3, 0, 0),         # Statenum::CYBER_DIE2
    State.new(Spritenum::CYBR, 9, 10, nil, Statenum::CYBER_DIE4, 0, 0),                # Statenum::CYBER_DIE3
    State.new(Spritenum::CYBR, 10, 10, nil, Statenum::CYBER_DIE5, 0, 0),               # Statenum::CYBER_DIE4
    State.new(Spritenum::CYBR, 11, 10, nil, Statenum::CYBER_DIE6, 0, 0),               # Statenum::CYBER_DIE5
    State.new(Spritenum::CYBR, 12, 10, ->a_Fall, Statenum::CYBER_DIE7, 0, 0),          # Statenum::CYBER_DIE6
    State.new(Spritenum::CYBR, 13, 10, nil, Statenum::CYBER_DIE8, 0, 0),               # Statenum::CYBER_DIE7
    State.new(Spritenum::CYBR, 14, 10, nil, Statenum::CYBER_DIE9, 0, 0),               # Statenum::CYBER_DIE8
    State.new(Spritenum::CYBR, 15, 30, nil, Statenum::CYBER_DIE10, 0, 0),              # Statenum::CYBER_DIE9
    State.new(Spritenum::CYBR, 15, -1, ->a_BossDeath, Statenum::NULL, 0, 0),           # Statenum::CYBER_DIE10
    State.new(Spritenum::PAIN, 0, 10, ->a_Look, Statenum::PAIN_STND, 0, 0),            # Statenum::PAIN_STND
    State.new(Spritenum::PAIN, 0, 3, ->a_Chase, Statenum::PAIN_RUN2, 0, 0),            # Statenum::PAIN_RUN1
    State.new(Spritenum::PAIN, 0, 3, ->a_Chase, Statenum::PAIN_RUN3, 0, 0),            # Statenum::PAIN_RUN2
    State.new(Spritenum::PAIN, 1, 3, ->a_Chase, Statenum::PAIN_RUN4, 0, 0),            # Statenum::PAIN_RUN3
    State.new(Spritenum::PAIN, 1, 3, ->a_Chase, Statenum::PAIN_RUN5, 0, 0),            # Statenum::PAIN_RUN4
    State.new(Spritenum::PAIN, 2, 3, ->a_Chase, Statenum::PAIN_RUN6, 0, 0),            # Statenum::PAIN_RUN5
    State.new(Spritenum::PAIN, 2, 3, ->a_Chase, Statenum::PAIN_RUN1, 0, 0),            # Statenum::PAIN_RUN6
    State.new(Spritenum::PAIN, 3, 5, ->a_FaceTarget, Statenum::PAIN_ATK2, 0, 0),       # Statenum::PAIN_ATK1
    State.new(Spritenum::PAIN, 4, 5, ->a_FaceTarget, Statenum::PAIN_ATK3, 0, 0),       # Statenum::PAIN_ATK2
    State.new(Spritenum::PAIN, 32773, 5, ->a_FaceTarget, Statenum::PAIN_ATK4, 0, 0),   # Statenum::PAIN_ATK3
    State.new(Spritenum::PAIN, 32773, 0, ->a_PainAttack, Statenum::PAIN_RUN1, 0, 0),   # Statenum::PAIN_ATK4
    State.new(Spritenum::PAIN, 6, 6, nil, Statenum::PAIN_PAIN2, 0, 0),                 # Statenum::PAIN_PAIN
    State.new(Spritenum::PAIN, 6, 6, ->a_Pain, Statenum::PAIN_RUN1, 0, 0),             # Statenum::PAIN_PAIN2
    State.new(Spritenum::PAIN, 32775, 8, nil, Statenum::PAIN_DIE2, 0, 0),              # Statenum::PAIN_DIE1
    State.new(Spritenum::PAIN, 32776, 8, ->a_Scream, Statenum::PAIN_DIE3, 0, 0),       # Statenum::PAIN_DIE2
    State.new(Spritenum::PAIN, 32777, 8, nil, Statenum::PAIN_DIE4, 0, 0),              # Statenum::PAIN_DIE3
    State.new(Spritenum::PAIN, 32778, 8, nil, Statenum::PAIN_DIE5, 0, 0),              # Statenum::PAIN_DIE4
    State.new(Spritenum::PAIN, 32779, 8, ->a_PainDie, Statenum::PAIN_DIE6, 0, 0),      # Statenum::PAIN_DIE5
    State.new(Spritenum::PAIN, 32780, 8, nil, Statenum::NULL, 0, 0),                   # Statenum::PAIN_DIE6
    State.new(Spritenum::PAIN, 12, 8, nil, Statenum::PAIN_RAISE2, 0, 0),               # Statenum::PAIN_RAISE1
    State.new(Spritenum::PAIN, 11, 8, nil, Statenum::PAIN_RAISE3, 0, 0),               # Statenum::PAIN_RAISE2
    State.new(Spritenum::PAIN, 10, 8, nil, Statenum::PAIN_RAISE4, 0, 0),               # Statenum::PAIN_RAISE3
    State.new(Spritenum::PAIN, 9, 8, nil, Statenum::PAIN_RAISE5, 0, 0),                # Statenum::PAIN_RAISE4
    State.new(Spritenum::PAIN, 8, 8, nil, Statenum::PAIN_RAISE6, 0, 0),                # Statenum::PAIN_RAISE5
    State.new(Spritenum::PAIN, 7, 8, nil, Statenum::PAIN_RUN1, 0, 0),                  # Statenum::PAIN_RAISE6
    State.new(Spritenum::SSWV, 0, 10, ->a_Look, Statenum::SSWV_STND2, 0, 0),           # Statenum::SSWV_STND
    State.new(Spritenum::SSWV, 1, 10, ->a_Look, Statenum::SSWV_STND, 0, 0),            # Statenum::SSWV_STND2
    State.new(Spritenum::SSWV, 0, 3, ->a_Chase, Statenum::SSWV_RUN2, 0, 0),            # Statenum::SSWV_RUN1
    State.new(Spritenum::SSWV, 0, 3, ->a_Chase, Statenum::SSWV_RUN3, 0, 0),            # Statenum::SSWV_RUN2
    State.new(Spritenum::SSWV, 1, 3, ->a_Chase, Statenum::SSWV_RUN4, 0, 0),            # Statenum::SSWV_RUN3
    State.new(Spritenum::SSWV, 1, 3, ->a_Chase, Statenum::SSWV_RUN5, 0, 0),            # Statenum::SSWV_RUN4
    State.new(Spritenum::SSWV, 2, 3, ->a_Chase, Statenum::SSWV_RUN6, 0, 0),            # Statenum::SSWV_RUN5
    State.new(Spritenum::SSWV, 2, 3, ->a_Chase, Statenum::SSWV_RUN7, 0, 0),            # Statenum::SSWV_RUN6
    State.new(Spritenum::SSWV, 3, 3, ->a_Chase, Statenum::SSWV_RUN8, 0, 0),            # Statenum::SSWV_RUN7
    State.new(Spritenum::SSWV, 3, 3, ->a_Chase, Statenum::SSWV_RUN1, 0, 0),            # Statenum::SSWV_RUN8
    State.new(Spritenum::SSWV, 4, 10, ->a_FaceTarget, Statenum::SSWV_ATK2, 0, 0),      # Statenum::SSWV_ATK1
    State.new(Spritenum::SSWV, 5, 10, ->a_FaceTarget, Statenum::SSWV_ATK3, 0, 0),      # Statenum::SSWV_ATK2
    State.new(Spritenum::SSWV, 32774, 4, ->a_CPosAttack, Statenum::SSWV_ATK4, 0, 0),   # Statenum::SSWV_ATK3
    State.new(Spritenum::SSWV, 5, 6, ->a_FaceTarget, Statenum::SSWV_ATK5, 0, 0),       # Statenum::SSWV_ATK4
    State.new(Spritenum::SSWV, 32774, 4, ->a_CPosAttack, Statenum::SSWV_ATK6, 0, 0),   # Statenum::SSWV_ATK5
    State.new(Spritenum::SSWV, 5, 1, ->a_CPosRefire, Statenum::SSWV_ATK2, 0, 0),       # Statenum::SSWV_ATK6
    State.new(Spritenum::SSWV, 7, 3, nil, Statenum::SSWV_PAIN2, 0, 0),                 # Statenum::SSWV_PAIN
    State.new(Spritenum::SSWV, 7, 3, ->a_Pain, Statenum::SSWV_RUN1, 0, 0),             # Statenum::SSWV_PAIN2
    State.new(Spritenum::SSWV, 8, 5, nil, Statenum::SSWV_DIE2, 0, 0),                  # Statenum::SSWV_DIE1
    State.new(Spritenum::SSWV, 9, 5, ->a_Scream, Statenum::SSWV_DIE3, 0, 0),           # Statenum::SSWV_DIE2
    State.new(Spritenum::SSWV, 10, 5, ->a_Fall, Statenum::SSWV_DIE4, 0, 0),            # Statenum::SSWV_DIE3
    State.new(Spritenum::SSWV, 11, 5, nil, Statenum::SSWV_DIE5, 0, 0),                 # Statenum::SSWV_DIE4
    State.new(Spritenum::SSWV, 12, -1, nil, Statenum::NULL, 0, 0),                     # Statenum::SSWV_DIE5
    State.new(Spritenum::SSWV, 13, 5, nil, Statenum::SSWV_XDIE2, 0, 0),                # Statenum::SSWV_XDIE1
    State.new(Spritenum::SSWV, 14, 5, ->a_XScream, Statenum::SSWV_XDIE3, 0, 0),        # Statenum::SSWV_XDIE2
    State.new(Spritenum::SSWV, 15, 5, ->a_Fall, Statenum::SSWV_XDIE4, 0, 0),           # Statenum::SSWV_XDIE3
    State.new(Spritenum::SSWV, 16, 5, nil, Statenum::SSWV_XDIE5, 0, 0),                # Statenum::SSWV_XDIE4
    State.new(Spritenum::SSWV, 17, 5, nil, Statenum::SSWV_XDIE6, 0, 0),                # Statenum::SSWV_XDIE5
    State.new(Spritenum::SSWV, 18, 5, nil, Statenum::SSWV_XDIE7, 0, 0),                # Statenum::SSWV_XDIE6
    State.new(Spritenum::SSWV, 19, 5, nil, Statenum::SSWV_XDIE8, 0, 0),                # Statenum::SSWV_XDIE7
    State.new(Spritenum::SSWV, 20, 5, nil, Statenum::SSWV_XDIE9, 0, 0),                # Statenum::SSWV_XDIE8
    State.new(Spritenum::SSWV, 21, -1, nil, Statenum::NULL, 0, 0),                     # Statenum::SSWV_XDIE9
    State.new(Spritenum::SSWV, 12, 5, nil, Statenum::SSWV_RAISE2, 0, 0),               # Statenum::SSWV_RAISE1
    State.new(Spritenum::SSWV, 11, 5, nil, Statenum::SSWV_RAISE3, 0, 0),               # Statenum::SSWV_RAISE2
    State.new(Spritenum::SSWV, 10, 5, nil, Statenum::SSWV_RAISE4, 0, 0),               # Statenum::SSWV_RAISE3
    State.new(Spritenum::SSWV, 9, 5, nil, Statenum::SSWV_RAISE5, 0, 0),                # Statenum::SSWV_RAISE4
    State.new(Spritenum::SSWV, 8, 5, nil, Statenum::SSWV_RUN1, 0, 0),                  # Statenum::SSWV_RAISE5
    State.new(Spritenum::KEEN, 0, -1, nil, Statenum::KEENSTND, 0, 0),                  # Statenum::KEENSTND
    State.new(Spritenum::KEEN, 0, 6, nil, Statenum::COMMKEEN2, 0, 0),                  # Statenum::COMMKEEN
    State.new(Spritenum::KEEN, 1, 6, nil, Statenum::COMMKEEN3, 0, 0),                  # Statenum::COMMKEEN2
    State.new(Spritenum::KEEN, 2, 6, ->a_Scream, Statenum::COMMKEEN4, 0, 0),           # Statenum::COMMKEEN3
    State.new(Spritenum::KEEN, 3, 6, nil, Statenum::COMMKEEN5, 0, 0),                  # Statenum::COMMKEEN4
    State.new(Spritenum::KEEN, 4, 6, nil, Statenum::COMMKEEN6, 0, 0),                  # Statenum::COMMKEEN5
    State.new(Spritenum::KEEN, 5, 6, nil, Statenum::COMMKEEN7, 0, 0),                  # Statenum::COMMKEEN6
    State.new(Spritenum::KEEN, 6, 6, nil, Statenum::COMMKEEN8, 0, 0),                  # Statenum::COMMKEEN7
    State.new(Spritenum::KEEN, 7, 6, nil, Statenum::COMMKEEN9, 0, 0),                  # Statenum::COMMKEEN8
    State.new(Spritenum::KEEN, 8, 6, nil, Statenum::COMMKEEN10, 0, 0),                 # Statenum::COMMKEEN9
    State.new(Spritenum::KEEN, 9, 6, nil, Statenum::COMMKEEN11, 0, 0),                 # Statenum::COMMKEEN10
    State.new(Spritenum::KEEN, 10, 6, ->a_KeenDie, Statenum::COMMKEEN12, 0, 0),        # Statenum::COMMKEEN11
    State.new(Spritenum::KEEN, 11, -1, nil, Statenum::NULL, 0, 0),                     # Statenum::COMMKEEN12
    State.new(Spritenum::KEEN, 12, 4, nil, Statenum::KEENPAIN2, 0, 0),                 # Statenum::KEENPAIN
    State.new(Spritenum::KEEN, 12, 8, ->a_Pain, Statenum::KEENSTND, 0, 0),             # Statenum::KEENPAIN2
    State.new(Spritenum::BBRN, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::BRAIN
    State.new(Spritenum::BBRN, 1, 36, ->a_BrainPain, Statenum::BRAIN, 0, 0),           # Statenum::BRAIN_PAIN
    State.new(Spritenum::BBRN, 0, 100, ->a_BrainScream, Statenum::BRAIN_DIE2, 0, 0),   # Statenum::BRAIN_DIE1
    State.new(Spritenum::BBRN, 0, 10, nil, Statenum::BRAIN_DIE3, 0, 0),                # Statenum::BRAIN_DIE2
    State.new(Spritenum::BBRN, 0, 10, nil, Statenum::BRAIN_DIE4, 0, 0),                # Statenum::BRAIN_DIE3
    State.new(Spritenum::BBRN, 0, -1, ->a_BrainDie, Statenum::NULL, 0, 0),             # Statenum::BRAIN_DIE4
    State.new(Spritenum::SSWV, 0, 10, ->a_Look, Statenum::BRAINEYE, 0, 0),             # Statenum::BRAINEYE
    State.new(Spritenum::SSWV, 0, 181, ->a_BrainAwake, Statenum::BRAINEYE1, 0, 0),     # Statenum::BRAINEYESEE
    State.new(Spritenum::SSWV, 0, 150, ->a_BrainSpit, Statenum::BRAINEYE1, 0, 0),      # Statenum::BRAINEYE1
    State.new(Spritenum::BOSF, 32768, 3, ->a_SpawnSound, Statenum::SPAWN2, 0, 0),      # Statenum::SPAWN1
    State.new(Spritenum::BOSF, 32769, 3, ->a_SpawnFly, Statenum::SPAWN3, 0, 0),        # Statenum::SPAWN2
    State.new(Spritenum::BOSF, 32770, 3, ->a_SpawnFly, Statenum::SPAWN4, 0, 0),        # Statenum::SPAWN3
    State.new(Spritenum::BOSF, 32771, 3, ->a_SpawnFly, Statenum::SPAWN1, 0, 0),        # Statenum::SPAWN4
    State.new(Spritenum::FIRE, 32768, 4, ->a_Fire, Statenum::SPAWNFIRE2, 0, 0),        # Statenum::SPAWNFIRE1
    State.new(Spritenum::FIRE, 32769, 4, ->a_Fire, Statenum::SPAWNFIRE3, 0, 0),        # Statenum::SPAWNFIRE2
    State.new(Spritenum::FIRE, 32770, 4, ->a_Fire, Statenum::SPAWNFIRE4, 0, 0),        # Statenum::SPAWNFIRE3
    State.new(Spritenum::FIRE, 32771, 4, ->a_Fire, Statenum::SPAWNFIRE5, 0, 0),        # Statenum::SPAWNFIRE4
    State.new(Spritenum::FIRE, 32772, 4, ->a_Fire, Statenum::SPAWNFIRE6, 0, 0),        # Statenum::SPAWNFIRE5
    State.new(Spritenum::FIRE, 32773, 4, ->a_Fire, Statenum::SPAWNFIRE7, 0, 0),        # Statenum::SPAWNFIRE6
    State.new(Spritenum::FIRE, 32774, 4, ->a_Fire, Statenum::SPAWNFIRE8, 0, 0),        # Statenum::SPAWNFIRE7
    State.new(Spritenum::FIRE, 32775, 4, ->a_Fire, Statenum::NULL, 0, 0),              # Statenum::SPAWNFIRE8
    State.new(Spritenum::MISL, 32769, 10, nil, Statenum::BRAINEXPLODE2, 0, 0),         # Statenum::BRAINEXPLODE1
    State.new(Spritenum::MISL, 32770, 10, nil, Statenum::BRAINEXPLODE3, 0, 0),         # Statenum::BRAINEXPLODE2
    State.new(Spritenum::MISL, 32771, 10, ->a_BrainExplode, Statenum::NULL, 0, 0),     # Statenum::BRAINEXPLODE3
    State.new(Spritenum::ARM1, 0, 6, nil, Statenum::ARM1A, 0, 0),                      # Statenum::ARM1
    State.new(Spritenum::ARM1, 32769, 7, nil, Statenum::ARM1, 0, 0),                   # Statenum::ARM1A
    State.new(Spritenum::ARM2, 0, 6, nil, Statenum::ARM2A, 0, 0),                      # Statenum::ARM2
    State.new(Spritenum::ARM2, 32769, 6, nil, Statenum::ARM2, 0, 0),                   # Statenum::ARM2A
    State.new(Spritenum::BAR1, 0, 6, nil, Statenum::BAR2, 0, 0),                       # Statenum::BAR1
    State.new(Spritenum::BAR1, 1, 6, nil, Statenum::BAR1, 0, 0),                       # Statenum::BAR2
    State.new(Spritenum::BEXP, 32768, 5, nil, Statenum::BEXP2, 0, 0),                  # Statenum::BEXP
    State.new(Spritenum::BEXP, 32769, 5, ->a_Scream, Statenum::BEXP3, 0, 0),           # Statenum::BEXP2
    State.new(Spritenum::BEXP, 32770, 5, nil, Statenum::BEXP4, 0, 0),                  # Statenum::BEXP3
    State.new(Spritenum::BEXP, 32771, 10, ->a_Explode, Statenum::BEXP5, 0, 0),         # Statenum::BEXP4
    State.new(Spritenum::BEXP, 32772, 10, nil, Statenum::NULL, 0, 0),                  # Statenum::BEXP5
    State.new(Spritenum::FCAN, 32768, 4, nil, Statenum::BBAR2, 0, 0),                  # Statenum::BBAR1
    State.new(Spritenum::FCAN, 32769, 4, nil, Statenum::BBAR3, 0, 0),                  # Statenum::BBAR2
    State.new(Spritenum::FCAN, 32770, 4, nil, Statenum::BBAR1, 0, 0),                  # Statenum::BBAR3
    State.new(Spritenum::BON1, 0, 6, nil, Statenum::BON1A, 0, 0),                      # Statenum::BON1
    State.new(Spritenum::BON1, 1, 6, nil, Statenum::BON1B, 0, 0),                      # Statenum::BON1A
    State.new(Spritenum::BON1, 2, 6, nil, Statenum::BON1C, 0, 0),                      # Statenum::BON1B
    State.new(Spritenum::BON1, 3, 6, nil, Statenum::BON1D, 0, 0),                      # Statenum::BON1C
    State.new(Spritenum::BON1, 2, 6, nil, Statenum::BON1E, 0, 0),                      # Statenum::BON1D
    State.new(Spritenum::BON1, 1, 6, nil, Statenum::BON1, 0, 0),                       # Statenum::BON1E
    State.new(Spritenum::BON2, 0, 6, nil, Statenum::BON2A, 0, 0),                      # Statenum::BON2
    State.new(Spritenum::BON2, 1, 6, nil, Statenum::BON2B, 0, 0),                      # Statenum::BON2A
    State.new(Spritenum::BON2, 2, 6, nil, Statenum::BON2C, 0, 0),                      # Statenum::BON2B
    State.new(Spritenum::BON2, 3, 6, nil, Statenum::BON2D, 0, 0),                      # Statenum::BON2C
    State.new(Spritenum::BON2, 2, 6, nil, Statenum::BON2E, 0, 0),                      # Statenum::BON2D
    State.new(Spritenum::BON2, 1, 6, nil, Statenum::BON2, 0, 0),                       # Statenum::BON2E
    State.new(Spritenum::BKEY, 0, 10, nil, Statenum::BKEY2, 0, 0),                     # Statenum::BKEY
    State.new(Spritenum::BKEY, 32769, 10, nil, Statenum::BKEY, 0, 0),                  # Statenum::BKEY2
    State.new(Spritenum::RKEY, 0, 10, nil, Statenum::RKEY2, 0, 0),                     # Statenum::RKEY
    State.new(Spritenum::RKEY, 32769, 10, nil, Statenum::RKEY, 0, 0),                  # Statenum::RKEY2
    State.new(Spritenum::YKEY, 0, 10, nil, Statenum::YKEY2, 0, 0),                     # Statenum::YKEY
    State.new(Spritenum::YKEY, 32769, 10, nil, Statenum::YKEY, 0, 0),                  # Statenum::YKEY2
    State.new(Spritenum::BSKU, 0, 10, nil, Statenum::BSKULL2, 0, 0),                   # Statenum::BSKULL
    State.new(Spritenum::BSKU, 32769, 10, nil, Statenum::BSKULL, 0, 0),                # Statenum::BSKULL2
    State.new(Spritenum::RSKU, 0, 10, nil, Statenum::RSKULL2, 0, 0),                   # Statenum::RSKULL
    State.new(Spritenum::RSKU, 32769, 10, nil, Statenum::RSKULL, 0, 0),                # Statenum::RSKULL2
    State.new(Spritenum::YSKU, 0, 10, nil, Statenum::YSKULL2, 0, 0),                   # Statenum::YSKULL
    State.new(Spritenum::YSKU, 32769, 10, nil, Statenum::YSKULL, 0, 0),                # Statenum::YSKULL2
    State.new(Spritenum::STIM, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::STIM
    State.new(Spritenum::MEDI, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::MEDI
    State.new(Spritenum::SOUL, 32768, 6, nil, Statenum::SOUL2, 0, 0),                  # Statenum::SOUL
    State.new(Spritenum::SOUL, 32769, 6, nil, Statenum::SOUL3, 0, 0),                  # Statenum::SOUL2
    State.new(Spritenum::SOUL, 32770, 6, nil, Statenum::SOUL4, 0, 0),                  # Statenum::SOUL3
    State.new(Spritenum::SOUL, 32771, 6, nil, Statenum::SOUL5, 0, 0),                  # Statenum::SOUL4
    State.new(Spritenum::SOUL, 32770, 6, nil, Statenum::SOUL6, 0, 0),                  # Statenum::SOUL5
    State.new(Spritenum::SOUL, 32769, 6, nil, Statenum::SOUL, 0, 0),                   # Statenum::SOUL6
    State.new(Spritenum::PINV, 32768, 6, nil, Statenum::PINV2, 0, 0),                  # Statenum::PINV
    State.new(Spritenum::PINV, 32769, 6, nil, Statenum::PINV3, 0, 0),                  # Statenum::PINV2
    State.new(Spritenum::PINV, 32770, 6, nil, Statenum::PINV4, 0, 0),                  # Statenum::PINV3
    State.new(Spritenum::PINV, 32771, 6, nil, Statenum::PINV, 0, 0),                   # Statenum::PINV4
    State.new(Spritenum::PSTR, 32768, -1, nil, Statenum::NULL, 0, 0),                  # Statenum::PSTR
    State.new(Spritenum::PINS, 32768, 6, nil, Statenum::PINS2, 0, 0),                  # Statenum::PINS
    State.new(Spritenum::PINS, 32769, 6, nil, Statenum::PINS3, 0, 0),                  # Statenum::PINS2
    State.new(Spritenum::PINS, 32770, 6, nil, Statenum::PINS4, 0, 0),                  # Statenum::PINS3
    State.new(Spritenum::PINS, 32771, 6, nil, Statenum::PINS, 0, 0),                   # Statenum::PINS4
    State.new(Spritenum::MEGA, 32768, 6, nil, Statenum::MEGA2, 0, 0),                  # Statenum::MEGA
    State.new(Spritenum::MEGA, 32769, 6, nil, Statenum::MEGA3, 0, 0),                  # Statenum::MEGA2
    State.new(Spritenum::MEGA, 32770, 6, nil, Statenum::MEGA4, 0, 0),                  # Statenum::MEGA3
    State.new(Spritenum::MEGA, 32771, 6, nil, Statenum::MEGA, 0, 0),                   # Statenum::MEGA4
    State.new(Spritenum::SUIT, 32768, -1, nil, Statenum::NULL, 0, 0),                  # Statenum::SUIT
    State.new(Spritenum::PMAP, 32768, 6, nil, Statenum::PMAP2, 0, 0),                  # Statenum::PMAP
    State.new(Spritenum::PMAP, 32769, 6, nil, Statenum::PMAP3, 0, 0),                  # Statenum::PMAP2
    State.new(Spritenum::PMAP, 32770, 6, nil, Statenum::PMAP4, 0, 0),                  # Statenum::PMAP3
    State.new(Spritenum::PMAP, 32771, 6, nil, Statenum::PMAP5, 0, 0),                  # Statenum::PMAP4
    State.new(Spritenum::PMAP, 32770, 6, nil, Statenum::PMAP6, 0, 0),                  # Statenum::PMAP5
    State.new(Spritenum::PMAP, 32769, 6, nil, Statenum::PMAP, 0, 0),                   # Statenum::PMAP6
    State.new(Spritenum::PVIS, 32768, 6, nil, Statenum::PVIS2, 0, 0),                  # Statenum::PVIS
    State.new(Spritenum::PVIS, 1, 6, nil, Statenum::PVIS, 0, 0),                       # Statenum::PVIS2
    State.new(Spritenum::CLIP, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::CLIP
    State.new(Spritenum::AMMO, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::AMMO
    State.new(Spritenum::ROCK, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::ROCK
    State.new(Spritenum::BROK, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::BROK
    State.new(Spritenum::CELL, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::CELL
    State.new(Spritenum::CELP, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::CELP
    State.new(Spritenum::SHEL, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::SHEL
    State.new(Spritenum::SBOX, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::SBOX
    State.new(Spritenum::BPAK, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::BPAK
    State.new(Spritenum::BFUG, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::BFUG
    State.new(Spritenum::MGUN, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::MGUN
    State.new(Spritenum::CSAW, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::CSAW
    State.new(Spritenum::LAUN, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::LAUN
    State.new(Spritenum::PLAS, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::PLAS
    State.new(Spritenum::SHOT, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::SHOT
    State.new(Spritenum::SGN2, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::SHOT2
    State.new(Spritenum::COLU, 32768, -1, nil, Statenum::NULL, 0, 0),                  # Statenum::COLU
    State.new(Spritenum::SMT2, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::STALAG
    State.new(Spritenum::GOR1, 0, 10, nil, Statenum::BLOODYTWITCH2, 0, 0),             # Statenum::BLOODYTWITCH
    State.new(Spritenum::GOR1, 1, 15, nil, Statenum::BLOODYTWITCH3, 0, 0),             # Statenum::BLOODYTWITCH2
    State.new(Spritenum::GOR1, 2, 8, nil, Statenum::BLOODYTWITCH4, 0, 0),              # Statenum::BLOODYTWITCH3
    State.new(Spritenum::GOR1, 1, 6, nil, Statenum::BLOODYTWITCH, 0, 0),               # Statenum::BLOODYTWITCH4
    State.new(Spritenum::PLAY, 13, -1, nil, Statenum::NULL, 0, 0),                     # Statenum::DEADTORSO
    State.new(Spritenum::PLAY, 18, -1, nil, Statenum::NULL, 0, 0),                     # Statenum::DEADBOTTOM
    State.new(Spritenum::POL2, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::HEADSONSTICK
    State.new(Spritenum::POL5, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::GIBS
    State.new(Spritenum::POL4, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::HEADONASTICK
    State.new(Spritenum::POL3, 32768, 6, nil, Statenum::HEADCANDLES2, 0, 0),           # Statenum::HEADCANDLES
    State.new(Spritenum::POL3, 32769, 6, nil, Statenum::HEADCANDLES, 0, 0),            # Statenum::HEADCANDLES2
    State.new(Spritenum::POL1, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::DEADSTICK
    State.new(Spritenum::POL6, 0, 6, nil, Statenum::LIVESTICK2, 0, 0),                 # Statenum::LIVESTICK
    State.new(Spritenum::POL6, 1, 8, nil, Statenum::LIVESTICK, 0, 0),                  # Statenum::LIVESTICK2
    State.new(Spritenum::GOR2, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::MEAT2
    State.new(Spritenum::GOR3, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::MEAT3
    State.new(Spritenum::GOR4, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::MEAT4
    State.new(Spritenum::GOR5, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::MEAT5
    State.new(Spritenum::SMIT, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::STALAGTITE
    State.new(Spritenum::COL1, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::TALLGRNCOL
    State.new(Spritenum::COL2, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::SHRTGRNCOL
    State.new(Spritenum::COL3, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::TALLREDCOL
    State.new(Spritenum::COL4, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::SHRTREDCOL
    State.new(Spritenum::CAND, 32768, -1, nil, Statenum::NULL, 0, 0),                  # Statenum::CANDLESTIK
    State.new(Spritenum::CBRA, 32768, -1, nil, Statenum::NULL, 0, 0),                  # Statenum::CANDELABRA
    State.new(Spritenum::COL6, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::SKULLCOL
    State.new(Spritenum::TRE1, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::TORCHTREE
    State.new(Spritenum::TRE2, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::BIGTREE
    State.new(Spritenum::ELEC, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::TECHPILLAR
    State.new(Spritenum::CEYE, 32768, 6, nil, Statenum::EVILEYE2, 0, 0),               # Statenum::EVILEYE
    State.new(Spritenum::CEYE, 32769, 6, nil, Statenum::EVILEYE3, 0, 0),               # Statenum::EVILEYE2
    State.new(Spritenum::CEYE, 32770, 6, nil, Statenum::EVILEYE4, 0, 0),               # Statenum::EVILEYE3
    State.new(Spritenum::CEYE, 32769, 6, nil, Statenum::EVILEYE, 0, 0),                # Statenum::EVILEYE4
    State.new(Spritenum::FSKU, 32768, 6, nil, Statenum::FLOATSKULL2, 0, 0),            # Statenum::FLOATSKULL
    State.new(Spritenum::FSKU, 32769, 6, nil, Statenum::FLOATSKULL3, 0, 0),            # Statenum::FLOATSKULL2
    State.new(Spritenum::FSKU, 32770, 6, nil, Statenum::FLOATSKULL, 0, 0),             # Statenum::FLOATSKULL3
    State.new(Spritenum::COL5, 0, 14, nil, Statenum::HEARTCOL2, 0, 0),                 # Statenum::HEARTCOL
    State.new(Spritenum::COL5, 1, 14, nil, Statenum::HEARTCOL, 0, 0),                  # Statenum::HEARTCOL2
    State.new(Spritenum::TBLU, 32768, 4, nil, Statenum::BLUETORCH2, 0, 0),             # Statenum::BLUETORCH
    State.new(Spritenum::TBLU, 32769, 4, nil, Statenum::BLUETORCH3, 0, 0),             # Statenum::BLUETORCH2
    State.new(Spritenum::TBLU, 32770, 4, nil, Statenum::BLUETORCH4, 0, 0),             # Statenum::BLUETORCH3
    State.new(Spritenum::TBLU, 32771, 4, nil, Statenum::BLUETORCH, 0, 0),              # Statenum::BLUETORCH4
    State.new(Spritenum::TGRN, 32768, 4, nil, Statenum::GREENTORCH2, 0, 0),            # Statenum::GREENTORCH
    State.new(Spritenum::TGRN, 32769, 4, nil, Statenum::GREENTORCH3, 0, 0),            # Statenum::GREENTORCH2
    State.new(Spritenum::TGRN, 32770, 4, nil, Statenum::GREENTORCH4, 0, 0),            # Statenum::GREENTORCH3
    State.new(Spritenum::TGRN, 32771, 4, nil, Statenum::GREENTORCH, 0, 0),             # Statenum::GREENTORCH4
    State.new(Spritenum::TRED, 32768, 4, nil, Statenum::REDTORCH2, 0, 0),              # Statenum::REDTORCH
    State.new(Spritenum::TRED, 32769, 4, nil, Statenum::REDTORCH3, 0, 0),              # Statenum::REDTORCH2
    State.new(Spritenum::TRED, 32770, 4, nil, Statenum::REDTORCH4, 0, 0),              # Statenum::REDTORCH3
    State.new(Spritenum::TRED, 32771, 4, nil, Statenum::REDTORCH, 0, 0),               # Statenum::REDTORCH4
    State.new(Spritenum::SMBT, 32768, 4, nil, Statenum::BTORCHSHRT2, 0, 0),            # Statenum::BTORCHSHRT
    State.new(Spritenum::SMBT, 32769, 4, nil, Statenum::BTORCHSHRT3, 0, 0),            # Statenum::BTORCHSHRT2
    State.new(Spritenum::SMBT, 32770, 4, nil, Statenum::BTORCHSHRT4, 0, 0),            # Statenum::BTORCHSHRT3
    State.new(Spritenum::SMBT, 32771, 4, nil, Statenum::BTORCHSHRT, 0, 0),             # Statenum::BTORCHSHRT4
    State.new(Spritenum::SMGT, 32768, 4, nil, Statenum::GTORCHSHRT2, 0, 0),            # Statenum::GTORCHSHRT
    State.new(Spritenum::SMGT, 32769, 4, nil, Statenum::GTORCHSHRT3, 0, 0),            # Statenum::GTORCHSHRT2
    State.new(Spritenum::SMGT, 32770, 4, nil, Statenum::GTORCHSHRT4, 0, 0),            # Statenum::GTORCHSHRT3
    State.new(Spritenum::SMGT, 32771, 4, nil, Statenum::GTORCHSHRT, 0, 0),             # Statenum::GTORCHSHRT4
    State.new(Spritenum::SMRT, 32768, 4, nil, Statenum::RTORCHSHRT2, 0, 0),            # Statenum::RTORCHSHRT
    State.new(Spritenum::SMRT, 32769, 4, nil, Statenum::RTORCHSHRT3, 0, 0),            # Statenum::RTORCHSHRT2
    State.new(Spritenum::SMRT, 32770, 4, nil, Statenum::RTORCHSHRT4, 0, 0),            # Statenum::RTORCHSHRT3
    State.new(Spritenum::SMRT, 32771, 4, nil, Statenum::RTORCHSHRT, 0, 0),             # Statenum::RTORCHSHRT4
    State.new(Spritenum::HDB1, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::HANGNOGUTS
    State.new(Spritenum::HDB2, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::HANGBNOBRAIN
    State.new(Spritenum::HDB3, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::HANGTLOOKDN
    State.new(Spritenum::HDB4, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::HANGTSKULL
    State.new(Spritenum::HDB5, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::HANGTLOOKUP
    State.new(Spritenum::HDB6, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::HANGTNOBRAIN
    State.new(Spritenum::POB1, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::COLONGIBS
    State.new(Spritenum::POB2, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::SMALLPOOL
    State.new(Spritenum::BRS1, 0, -1, nil, Statenum::NULL, 0, 0),                      # Statenum::BRAINSTEM
    State.new(Spritenum::TLMP, 32768, 4, nil, Statenum::TECHLAMP2, 0, 0),              # Statenum::TECHLAMP
    State.new(Spritenum::TLMP, 32769, 4, nil, Statenum::TECHLAMP3, 0, 0),              # Statenum::TECHLAMP2
    State.new(Spritenum::TLMP, 32770, 4, nil, Statenum::TECHLAMP4, 0, 0),              # Statenum::TECHLAMP3
    State.new(Spritenum::TLMP, 32771, 4, nil, Statenum::TECHLAMP, 0, 0),               # Statenum::TECHLAMP4
    State.new(Spritenum::TLP2, 32768, 4, nil, Statenum::TECH2LAMP2, 0, 0),             # Statenum::TECH2LAMP
    State.new(Spritenum::TLP2, 32769, 4, nil, Statenum::TECH2LAMP3, 0, 0),             # Statenum::TECH2LAMP2
    State.new(Spritenum::TLP2, 32770, 4, nil, Statenum::TECH2LAMP4, 0, 0),             # Statenum::TECH2LAMP3
    State.new(Spritenum::TLP2, 32771, 4, nil, Statenum::TECH2LAMP, 0, 0),              # Statenum::TECH2LAMP4
  ]

  @@sprnames = [
    "TROO", "SHTG", "PUNG", "PISG", "PISF", "SHTF", "SHT2", "CHGG", "CHGF", "MISG",
    "MISF", "SAWG", "PLSG", "PLSF", "BFGG", "BFGF", "BLUD", "PUFF", "BAL1", "BAL2",
    "PLSS", "PLSE", "MISL", "BFS1", "BFE1", "BFE2", "TFOG", "IFOG", "PLAY", "POSS",
    "SPOS", "VILE", "FIRE", "FATB", "FBXP", "SKEL", "MANF", "FATT", "CPOS", "SARG",
    "HEAD", "BAL7", "BOSS", "BOS2", "SKUL", "SPID", "BSPI", "APLS", "APBX", "CYBR",
    "PAIN", "SSWV", "KEEN", "BBRN", "BOSF", "ARM1", "ARM2", "BAR1", "BEXP", "FCAN",
    "BON1", "BON2", "BKEY", "RKEY", "YKEY", "BSKU", "RSKU", "YSKU", "STIM", "MEDI",
    "SOUL", "PINV", "PSTR", "PINS", "MEGA", "SUIT", "PMAP", "PVIS", "CLIP", "AMMO",
    "ROCK", "BROK", "CELL", "CELP", "SHEL", "SBOX", "BPAK", "BFUG", "MGUN", "CSAW",
    "LAUN", "PLAS", "SHOT", "SGN2", "COLU", "SMT2", "GOR1", "POL2", "POL5", "POL4",
    "POL3", "POL1", "POL6", "GOR2", "GOR3", "GOR4", "GOR5", "SMIT", "COL1", "COL2",
    "COL3", "COL4", "CAND", "CBRA", "COL6", "TRE1", "TRE2", "ELEC", "CEYE", "FSKU",
    "COL5", "TBLU", "TGRN", "TRED", "SMBT", "SMGT", "SMRT", "HDB1", "HDB2", "HDB3",
    "HDB4", "HDB5", "HDB6", "POB1", "POB2", "BRS1", "TLMP", "TLP2",
  ]

  enum Spritenum
    TROO
    SHTG
    PUNG
    PISG
    PISF
    SHTF
    SHT2
    CHGG
    CHGF
    MISG
    MISF
    SAWG
    PLSG
    PLSF
    BFGG
    BFGF
    BLUD
    PUFF
    BAL1
    BAL2
    PLSS
    PLSE
    MISL
    BFS1
    BFE1
    BFE2
    TFOG
    IFOG
    PLAY
    POSS
    SPOS
    VILE
    FIRE
    FATB
    FBXP
    SKEL
    MANF
    FATT
    CPOS
    SARG
    HEAD
    BAL7
    BOSS
    BOS2
    SKUL
    SPID
    BSPI
    APLS
    APBX
    CYBR
    PAIN
    SSWV
    KEEN
    BBRN
    BOSF
    ARM1
    ARM2
    BAR1
    BEXP
    FCAN
    BON1
    BON2
    BKEY
    RKEY
    YKEY
    BSKU
    RSKU
    YSKU
    STIM
    MEDI
    SOUL
    PINV
    PSTR
    PINS
    MEGA
    SUIT
    PMAP
    PVIS
    CLIP
    AMMO
    ROCK
    BROK
    CELL
    CELP
    SHEL
    SBOX
    BPAK
    BFUG
    MGUN
    CSAW
    LAUN
    PLAS
    SHOT
    SGN2
    COLU
    SMT2
    GOR1
    POL2
    POL5
    POL4
    POL3
    POL1
    POL6
    GOR2
    GOR3
    GOR4
    GOR5
    SMIT
    COL1
    COL2
    COL3
    COL4
    CAND
    CBRA
    COL6
    TRE1
    TRE2
    ELEC
    CEYE
    FSKU
    COL5
    TBLU
    TGRN
    TRED
    SMBT
    SMGT
    SMRT
    HDB1
    HDB2
    HDB3
    HDB4
    HDB5
    HDB6
    POB1
    POB2
    BRS1
    TLMP
    TLP2
    NUMSPRITES
  end

  enum Statenum
    NULL
    LIGHTDONE
    PUNCH
    PUNCHDOWN
    PUNCHUP
    PUNCH1
    PUNCH2
    PUNCH3
    PUNCH4
    PUNCH5
    PISTOL
    PISTOLDOWN
    PISTOLUP
    PISTOL1
    PISTOL2
    PISTOL3
    PISTOL4
    PISTOLFLASH
    SGUN
    SGUNDOWN
    SGUNUP
    SGUN1
    SGUN2
    SGUN3
    SGUN4
    SGUN5
    SGUN6
    SGUN7
    SGUN8
    SGUN9
    SGUNFLASH1
    SGUNFLASH2
    DSGUN
    DSGUNDOWN
    DSGUNUP
    DSGUN1
    DSGUN2
    DSGUN3
    DSGUN4
    DSGUN5
    DSGUN6
    DSGUN7
    DSGUN8
    DSGUN9
    DSGUN10
    DSNR1
    DSNR2
    DSGUNFLASH1
    DSGUNFLASH2
    CHAIN
    CHAINDOWN
    CHAINUP
    CHAIN1
    CHAIN2
    CHAIN3
    CHAINFLASH1
    CHAINFLASH2
    MISSILE
    MISSILEDOWN
    MISSILEUP
    MISSILE1
    MISSILE2
    MISSILE3
    MISSILEFLASH1
    MISSILEFLASH2
    MISSILEFLASH3
    MISSILEFLASH4
    SAW
    SAWB
    SAWDOWN
    SAWUP
    SAW1
    SAW2
    SAW3
    PLASMA
    PLASMADOWN
    PLASMAUP
    PLASMA1
    PLASMA2
    PLASMAFLASH1
    PLASMAFLASH2
    BFG
    BFGDOWN
    BFGUP
    BFG1
    BFG2
    BFG3
    BFG4
    BFGFLASH1
    BFGFLASH2
    BLOOD1
    BLOOD2
    BLOOD3
    PUFF1
    PUFF2
    PUFF3
    PUFF4
    TBALL1
    TBALL2
    TBALLX1
    TBALLX2
    TBALLX3
    RBALL1
    RBALL2
    RBALLX1
    RBALLX2
    RBALLX3
    PLASBALL
    PLASBALL2
    PLASEXP
    PLASEXP2
    PLASEXP3
    PLASEXP4
    PLASEXP5
    ROCKET
    BFGSHOT
    BFGSHOT2
    BFGLAND
    BFGLAND2
    BFGLAND3
    BFGLAND4
    BFGLAND5
    BFGLAND6
    BFGEXP
    BFGEXP2
    BFGEXP3
    BFGEXP4
    EXPLODE1
    EXPLODE2
    EXPLODE3
    TFOG
    TFOG01
    TFOG02
    TFOG2
    TFOG3
    TFOG4
    TFOG5
    TFOG6
    TFOG7
    TFOG8
    TFOG9
    TFOG10
    IFOG
    IFOG01
    IFOG02
    IFOG2
    IFOG3
    IFOG4
    IFOG5
    PLAY
    PLAY_RUN1
    PLAY_RUN2
    PLAY_RUN3
    PLAY_RUN4
    PLAY_ATK1
    PLAY_ATK2
    PLAY_PAIN
    PLAY_PAIN2
    PLAY_DIE1
    PLAY_DIE2
    PLAY_DIE3
    PLAY_DIE4
    PLAY_DIE5
    PLAY_DIE6
    PLAY_DIE7
    PLAY_XDIE1
    PLAY_XDIE2
    PLAY_XDIE3
    PLAY_XDIE4
    PLAY_XDIE5
    PLAY_XDIE6
    PLAY_XDIE7
    PLAY_XDIE8
    PLAY_XDIE9
    POSS_STND
    POSS_STND2
    POSS_RUN1
    POSS_RUN2
    POSS_RUN3
    POSS_RUN4
    POSS_RUN5
    POSS_RUN6
    POSS_RUN7
    POSS_RUN8
    POSS_ATK1
    POSS_ATK2
    POSS_ATK3
    POSS_PAIN
    POSS_PAIN2
    POSS_DIE1
    POSS_DIE2
    POSS_DIE3
    POSS_DIE4
    POSS_DIE5
    POSS_XDIE1
    POSS_XDIE2
    POSS_XDIE3
    POSS_XDIE4
    POSS_XDIE5
    POSS_XDIE6
    POSS_XDIE7
    POSS_XDIE8
    POSS_XDIE9
    POSS_RAISE1
    POSS_RAISE2
    POSS_RAISE3
    POSS_RAISE4
    SPOS_STND
    SPOS_STND2
    SPOS_RUN1
    SPOS_RUN2
    SPOS_RUN3
    SPOS_RUN4
    SPOS_RUN5
    SPOS_RUN6
    SPOS_RUN7
    SPOS_RUN8
    SPOS_ATK1
    SPOS_ATK2
    SPOS_ATK3
    SPOS_PAIN
    SPOS_PAIN2
    SPOS_DIE1
    SPOS_DIE2
    SPOS_DIE3
    SPOS_DIE4
    SPOS_DIE5
    SPOS_XDIE1
    SPOS_XDIE2
    SPOS_XDIE3
    SPOS_XDIE4
    SPOS_XDIE5
    SPOS_XDIE6
    SPOS_XDIE7
    SPOS_XDIE8
    SPOS_XDIE9
    SPOS_RAISE1
    SPOS_RAISE2
    SPOS_RAISE3
    SPOS_RAISE4
    SPOS_RAISE5
    VILE_STND
    VILE_STND2
    VILE_RUN1
    VILE_RUN2
    VILE_RUN3
    VILE_RUN4
    VILE_RUN5
    VILE_RUN6
    VILE_RUN7
    VILE_RUN8
    VILE_RUN9
    VILE_RUN10
    VILE_RUN11
    VILE_RUN12
    VILE_ATK1
    VILE_ATK2
    VILE_ATK3
    VILE_ATK4
    VILE_ATK5
    VILE_ATK6
    VILE_ATK7
    VILE_ATK8
    VILE_ATK9
    VILE_ATK10
    VILE_ATK11
    VILE_HEAL1
    VILE_HEAL2
    VILE_HEAL3
    VILE_PAIN
    VILE_PAIN2
    VILE_DIE1
    VILE_DIE2
    VILE_DIE3
    VILE_DIE4
    VILE_DIE5
    VILE_DIE6
    VILE_DIE7
    VILE_DIE8
    VILE_DIE9
    VILE_DIE10
    FIRE1
    FIRE2
    FIRE3
    FIRE4
    FIRE5
    FIRE6
    FIRE7
    FIRE8
    FIRE9
    FIRE10
    FIRE11
    FIRE12
    FIRE13
    FIRE14
    FIRE15
    FIRE16
    FIRE17
    FIRE18
    FIRE19
    FIRE20
    FIRE21
    FIRE22
    FIRE23
    FIRE24
    FIRE25
    FIRE26
    FIRE27
    FIRE28
    FIRE29
    FIRE30
    SMOKE1
    SMOKE2
    SMOKE3
    SMOKE4
    SMOKE5
    TRACER
    TRACER2
    TRACEEXP1
    TRACEEXP2
    TRACEEXP3
    SKEL_STND
    SKEL_STND2
    SKEL_RUN1
    SKEL_RUN2
    SKEL_RUN3
    SKEL_RUN4
    SKEL_RUN5
    SKEL_RUN6
    SKEL_RUN7
    SKEL_RUN8
    SKEL_RUN9
    SKEL_RUN10
    SKEL_RUN11
    SKEL_RUN12
    SKEL_FIST1
    SKEL_FIST2
    SKEL_FIST3
    SKEL_FIST4
    SKEL_MISS1
    SKEL_MISS2
    SKEL_MISS3
    SKEL_MISS4
    SKEL_PAIN
    SKEL_PAIN2
    SKEL_DIE1
    SKEL_DIE2
    SKEL_DIE3
    SKEL_DIE4
    SKEL_DIE5
    SKEL_DIE6
    SKEL_RAISE1
    SKEL_RAISE2
    SKEL_RAISE3
    SKEL_RAISE4
    SKEL_RAISE5
    SKEL_RAISE6
    FATSHOT1
    FATSHOT2
    FATSHOTX1
    FATSHOTX2
    FATSHOTX3
    FATT_STND
    FATT_STND2
    FATT_RUN1
    FATT_RUN2
    FATT_RUN3
    FATT_RUN4
    FATT_RUN5
    FATT_RUN6
    FATT_RUN7
    FATT_RUN8
    FATT_RUN9
    FATT_RUN10
    FATT_RUN11
    FATT_RUN12
    FATT_ATK1
    FATT_ATK2
    FATT_ATK3
    FATT_ATK4
    FATT_ATK5
    FATT_ATK6
    FATT_ATK7
    FATT_ATK8
    FATT_ATK9
    FATT_ATK10
    FATT_PAIN
    FATT_PAIN2
    FATT_DIE1
    FATT_DIE2
    FATT_DIE3
    FATT_DIE4
    FATT_DIE5
    FATT_DIE6
    FATT_DIE7
    FATT_DIE8
    FATT_DIE9
    FATT_DIE10
    FATT_RAISE1
    FATT_RAISE2
    FATT_RAISE3
    FATT_RAISE4
    FATT_RAISE5
    FATT_RAISE6
    FATT_RAISE7
    FATT_RAISE8
    CPOS_STND
    CPOS_STND2
    CPOS_RUN1
    CPOS_RUN2
    CPOS_RUN3
    CPOS_RUN4
    CPOS_RUN5
    CPOS_RUN6
    CPOS_RUN7
    CPOS_RUN8
    CPOS_ATK1
    CPOS_ATK2
    CPOS_ATK3
    CPOS_ATK4
    CPOS_PAIN
    CPOS_PAIN2
    CPOS_DIE1
    CPOS_DIE2
    CPOS_DIE3
    CPOS_DIE4
    CPOS_DIE5
    CPOS_DIE6
    CPOS_DIE7
    CPOS_XDIE1
    CPOS_XDIE2
    CPOS_XDIE3
    CPOS_XDIE4
    CPOS_XDIE5
    CPOS_XDIE6
    CPOS_RAISE1
    CPOS_RAISE2
    CPOS_RAISE3
    CPOS_RAISE4
    CPOS_RAISE5
    CPOS_RAISE6
    CPOS_RAISE7
    TROO_STND
    TROO_STND2
    TROO_RUN1
    TROO_RUN2
    TROO_RUN3
    TROO_RUN4
    TROO_RUN5
    TROO_RUN6
    TROO_RUN7
    TROO_RUN8
    TROO_ATK1
    TROO_ATK2
    TROO_ATK3
    TROO_PAIN
    TROO_PAIN2
    TROO_DIE1
    TROO_DIE2
    TROO_DIE3
    TROO_DIE4
    TROO_DIE5
    TROO_XDIE1
    TROO_XDIE2
    TROO_XDIE3
    TROO_XDIE4
    TROO_XDIE5
    TROO_XDIE6
    TROO_XDIE7
    TROO_XDIE8
    TROO_RAISE1
    TROO_RAISE2
    TROO_RAISE3
    TROO_RAISE4
    TROO_RAISE5
    SARG_STND
    SARG_STND2
    SARG_RUN1
    SARG_RUN2
    SARG_RUN3
    SARG_RUN4
    SARG_RUN5
    SARG_RUN6
    SARG_RUN7
    SARG_RUN8
    SARG_ATK1
    SARG_ATK2
    SARG_ATK3
    SARG_PAIN
    SARG_PAIN2
    SARG_DIE1
    SARG_DIE2
    SARG_DIE3
    SARG_DIE4
    SARG_DIE5
    SARG_DIE6
    SARG_RAISE1
    SARG_RAISE2
    SARG_RAISE3
    SARG_RAISE4
    SARG_RAISE5
    SARG_RAISE6
    HEAD_STND
    HEAD_RUN1
    HEAD_ATK1
    HEAD_ATK2
    HEAD_ATK3
    HEAD_PAIN
    HEAD_PAIN2
    HEAD_PAIN3
    HEAD_DIE1
    HEAD_DIE2
    HEAD_DIE3
    HEAD_DIE4
    HEAD_DIE5
    HEAD_DIE6
    HEAD_RAISE1
    HEAD_RAISE2
    HEAD_RAISE3
    HEAD_RAISE4
    HEAD_RAISE5
    HEAD_RAISE6
    BRBALL1
    BRBALL2
    BRBALLX1
    BRBALLX2
    BRBALLX3
    BOSS_STND
    BOSS_STND2
    BOSS_RUN1
    BOSS_RUN2
    BOSS_RUN3
    BOSS_RUN4
    BOSS_RUN5
    BOSS_RUN6
    BOSS_RUN7
    BOSS_RUN8
    BOSS_ATK1
    BOSS_ATK2
    BOSS_ATK3
    BOSS_PAIN
    BOSS_PAIN2
    BOSS_DIE1
    BOSS_DIE2
    BOSS_DIE3
    BOSS_DIE4
    BOSS_DIE5
    BOSS_DIE6
    BOSS_DIE7
    BOSS_RAISE1
    BOSS_RAISE2
    BOSS_RAISE3
    BOSS_RAISE4
    BOSS_RAISE5
    BOSS_RAISE6
    BOSS_RAISE7
    BOS2_STND
    BOS2_STND2
    BOS2_RUN1
    BOS2_RUN2
    BOS2_RUN3
    BOS2_RUN4
    BOS2_RUN5
    BOS2_RUN6
    BOS2_RUN7
    BOS2_RUN8
    BOS2_ATK1
    BOS2_ATK2
    BOS2_ATK3
    BOS2_PAIN
    BOS2_PAIN2
    BOS2_DIE1
    BOS2_DIE2
    BOS2_DIE3
    BOS2_DIE4
    BOS2_DIE5
    BOS2_DIE6
    BOS2_DIE7
    BOS2_RAISE1
    BOS2_RAISE2
    BOS2_RAISE3
    BOS2_RAISE4
    BOS2_RAISE5
    BOS2_RAISE6
    BOS2_RAISE7
    SKULL_STND
    SKULL_STND2
    SKULL_RUN1
    SKULL_RUN2
    SKULL_ATK1
    SKULL_ATK2
    SKULL_ATK3
    SKULL_ATK4
    SKULL_PAIN
    SKULL_PAIN2
    SKULL_DIE1
    SKULL_DIE2
    SKULL_DIE3
    SKULL_DIE4
    SKULL_DIE5
    SKULL_DIE6
    SPID_STND
    SPID_STND2
    SPID_RUN1
    SPID_RUN2
    SPID_RUN3
    SPID_RUN4
    SPID_RUN5
    SPID_RUN6
    SPID_RUN7
    SPID_RUN8
    SPID_RUN9
    SPID_RUN10
    SPID_RUN11
    SPID_RUN12
    SPID_ATK1
    SPID_ATK2
    SPID_ATK3
    SPID_ATK4
    SPID_PAIN
    SPID_PAIN2
    SPID_DIE1
    SPID_DIE2
    SPID_DIE3
    SPID_DIE4
    SPID_DIE5
    SPID_DIE6
    SPID_DIE7
    SPID_DIE8
    SPID_DIE9
    SPID_DIE10
    SPID_DIE11
    BSPI_STND
    BSPI_STND2
    BSPI_SIGHT
    BSPI_RUN1
    BSPI_RUN2
    BSPI_RUN3
    BSPI_RUN4
    BSPI_RUN5
    BSPI_RUN6
    BSPI_RUN7
    BSPI_RUN8
    BSPI_RUN9
    BSPI_RUN10
    BSPI_RUN11
    BSPI_RUN12
    BSPI_ATK1
    BSPI_ATK2
    BSPI_ATK3
    BSPI_ATK4
    BSPI_PAIN
    BSPI_PAIN2
    BSPI_DIE1
    BSPI_DIE2
    BSPI_DIE3
    BSPI_DIE4
    BSPI_DIE5
    BSPI_DIE6
    BSPI_DIE7
    BSPI_RAISE1
    BSPI_RAISE2
    BSPI_RAISE3
    BSPI_RAISE4
    BSPI_RAISE5
    BSPI_RAISE6
    BSPI_RAISE7
    ARACH_PLAZ
    ARACH_PLAZ2
    ARACH_PLEX
    ARACH_PLEX2
    ARACH_PLEX3
    ARACH_PLEX4
    ARACH_PLEX5
    CYBER_STND
    CYBER_STND2
    CYBER_RUN1
    CYBER_RUN2
    CYBER_RUN3
    CYBER_RUN4
    CYBER_RUN5
    CYBER_RUN6
    CYBER_RUN7
    CYBER_RUN8
    CYBER_ATK1
    CYBER_ATK2
    CYBER_ATK3
    CYBER_ATK4
    CYBER_ATK5
    CYBER_ATK6
    CYBER_PAIN
    CYBER_DIE1
    CYBER_DIE2
    CYBER_DIE3
    CYBER_DIE4
    CYBER_DIE5
    CYBER_DIE6
    CYBER_DIE7
    CYBER_DIE8
    CYBER_DIE9
    CYBER_DIE10
    PAIN_STND
    PAIN_RUN1
    PAIN_RUN2
    PAIN_RUN3
    PAIN_RUN4
    PAIN_RUN5
    PAIN_RUN6
    PAIN_ATK1
    PAIN_ATK2
    PAIN_ATK3
    PAIN_ATK4
    PAIN_PAIN
    PAIN_PAIN2
    PAIN_DIE1
    PAIN_DIE2
    PAIN_DIE3
    PAIN_DIE4
    PAIN_DIE5
    PAIN_DIE6
    PAIN_RAISE1
    PAIN_RAISE2
    PAIN_RAISE3
    PAIN_RAISE4
    PAIN_RAISE5
    PAIN_RAISE6
    SSWV_STND
    SSWV_STND2
    SSWV_RUN1
    SSWV_RUN2
    SSWV_RUN3
    SSWV_RUN4
    SSWV_RUN5
    SSWV_RUN6
    SSWV_RUN7
    SSWV_RUN8
    SSWV_ATK1
    SSWV_ATK2
    SSWV_ATK3
    SSWV_ATK4
    SSWV_ATK5
    SSWV_ATK6
    SSWV_PAIN
    SSWV_PAIN2
    SSWV_DIE1
    SSWV_DIE2
    SSWV_DIE3
    SSWV_DIE4
    SSWV_DIE5
    SSWV_XDIE1
    SSWV_XDIE2
    SSWV_XDIE3
    SSWV_XDIE4
    SSWV_XDIE5
    SSWV_XDIE6
    SSWV_XDIE7
    SSWV_XDIE8
    SSWV_XDIE9
    SSWV_RAISE1
    SSWV_RAISE2
    SSWV_RAISE3
    SSWV_RAISE4
    SSWV_RAISE5
    KEENSTND
    COMMKEEN
    COMMKEEN2
    COMMKEEN3
    COMMKEEN4
    COMMKEEN5
    COMMKEEN6
    COMMKEEN7
    COMMKEEN8
    COMMKEEN9
    COMMKEEN10
    COMMKEEN11
    COMMKEEN12
    KEENPAIN
    KEENPAIN2
    BRAIN
    BRAIN_PAIN
    BRAIN_DIE1
    BRAIN_DIE2
    BRAIN_DIE3
    BRAIN_DIE4
    BRAINEYE
    BRAINEYESEE
    BRAINEYE1
    SPAWN1
    SPAWN2
    SPAWN3
    SPAWN4
    SPAWNFIRE1
    SPAWNFIRE2
    SPAWNFIRE3
    SPAWNFIRE4
    SPAWNFIRE5
    SPAWNFIRE6
    SPAWNFIRE7
    SPAWNFIRE8
    BRAINEXPLODE1
    BRAINEXPLODE2
    BRAINEXPLODE3
    ARM1
    ARM1A
    ARM2
    ARM2A
    BAR1
    BAR2
    BEXP
    BEXP2
    BEXP3
    BEXP4
    BEXP5
    BBAR1
    BBAR2
    BBAR3
    BON1
    BON1A
    BON1B
    BON1C
    BON1D
    BON1E
    BON2
    BON2A
    BON2B
    BON2C
    BON2D
    BON2E
    BKEY
    BKEY2
    RKEY
    RKEY2
    YKEY
    YKEY2
    BSKULL
    BSKULL2
    RSKULL
    RSKULL2
    YSKULL
    YSKULL2
    STIM
    MEDI
    SOUL
    SOUL2
    SOUL3
    SOUL4
    SOUL5
    SOUL6
    PINV
    PINV2
    PINV3
    PINV4
    PSTR
    PINS
    PINS2
    PINS3
    PINS4
    MEGA
    MEGA2
    MEGA3
    MEGA4
    SUIT
    PMAP
    PMAP2
    PMAP3
    PMAP4
    PMAP5
    PMAP6
    PVIS
    PVIS2
    CLIP
    AMMO
    ROCK
    BROK
    CELL
    CELP
    SHEL
    SBOX
    BPAK
    BFUG
    MGUN
    CSAW
    LAUN
    PLAS
    SHOT
    SHOT2
    COLU
    STALAG
    BLOODYTWITCH
    BLOODYTWITCH2
    BLOODYTWITCH3
    BLOODYTWITCH4
    DEADTORSO
    DEADBOTTOM
    HEADSONSTICK
    GIBS
    HEADONASTICK
    HEADCANDLES
    HEADCANDLES2
    DEADSTICK
    LIVESTICK
    LIVESTICK2
    MEAT2
    MEAT3
    MEAT4
    MEAT5
    STALAGTITE
    TALLGRNCOL
    SHRTGRNCOL
    TALLREDCOL
    SHRTREDCOL
    CANDLESTIK
    CANDELABRA
    SKULLCOL
    TORCHTREE
    BIGTREE
    TECHPILLAR
    EVILEYE
    EVILEYE2
    EVILEYE3
    EVILEYE4
    FLOATSKULL
    FLOATSKULL2
    FLOATSKULL3
    HEARTCOL
    HEARTCOL2
    BLUETORCH
    BLUETORCH2
    BLUETORCH3
    BLUETORCH4
    GREENTORCH
    GREENTORCH2
    GREENTORCH3
    GREENTORCH4
    REDTORCH
    REDTORCH2
    REDTORCH3
    REDTORCH4
    BTORCHSHRT
    BTORCHSHRT2
    BTORCHSHRT3
    BTORCHSHRT4
    GTORCHSHRT
    GTORCHSHRT2
    GTORCHSHRT3
    GTORCHSHRT4
    RTORCHSHRT
    RTORCHSHRT2
    RTORCHSHRT3
    RTORCHSHRT4
    HANGNOGUTS
    HANGBNOBRAIN
    HANGTLOOKDN
    HANGTSKULL
    HANGTLOOKUP
    HANGTNOBRAIN
    COLONGIBS
    SMALLPOOL
    BRAINSTEM
    TECHLAMP
    TECHLAMP2
    TECHLAMP3
    TECHLAMP4
    TECH2LAMP
    TECH2LAMP2
    TECH2LAMP3
    TECH2LAMP4
    NUMSTATES
  end

  enum Mobjtype
    PLAYER
    POSSESSED
    SHOTGUY
    VILE
    FIRE
    UNDEAD
    TRACER
    SMOKE
    FATSO
    FATSHOT
    CHAINGUY
    TROOP
    SERGEANT
    SHADOWS
    HEAD
    BRUISER
    BRUISERSHOT
    KNIGHT
    SKULL
    SPIDER
    BABY
    CYBORG
    PAIN
    WOLFSS
    KEEN
    BOSSBRAIN
    BOSSSPIT
    BOSSTARGET
    SPAWNSHOT
    SPAWNFIRE
    BARREL
    TROOPSHOT
    HEADSHOT
    ROCKET
    PLASMA
    BFG
    ARACHPLAZ
    PUFF
    BLOOD
    TFOG
    IFOG
    TELEPORTMAN
    EXTRABFG
    MISC0
    MISC1
    MISC2
    MISC3
    MISC4
    MISC5
    MISC6
    MISC7
    MISC8
    MISC9
    MISC10
    MISC11
    MISC12
    INV
    MISC13
    INS
    MISC14
    MISC15
    MISC16
    MEGA
    CLIP
    MISC17
    MISC18
    MISC19
    MISC20
    MISC21
    MISC22
    MISC23
    MISC24
    MISC25
    CHAINGUN
    MISC26
    MISC27
    MISC28
    SHOTGUN
    SUPERSHOTGUN
    MISC29
    MISC30
    MISC31
    MISC32
    MISC33
    MISC34
    MISC35
    MISC36
    MISC37
    MISC38
    MISC39
    MISC40
    MISC41
    MISC42
    MISC43
    MISC44
    MISC45
    MISC46
    MISC47
    MISC48
    MISC49
    MISC50
    MISC51
    MISC52
    MISC53
    MISC54
    MISC55
    MISC56
    MISC57
    MISC58
    MISC59
    MISC60
    MISC61
    MISC62
    MISC63
    MISC64
    MISC65
    MISC66
    MISC67
    MISC68
    MISC69
    MISC70
    MISC71
    MISC72
    MISC73
    MISC74
    MISC75
    MISC76
    MISC77
    MISC78
    MISC79
    MISC80
    MISC81
    MISC82
    MISC83
    MISC84
    MISC85
    MISC86
    NUMMOBJTYPES
  end
end
