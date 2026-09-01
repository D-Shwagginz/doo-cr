module Doocr
  # Which one is deterministic?
  def self.p_random : Int32
    CDoom.prndindex = (CDoom.prndindex + 1) & 0xff
    return CDoom.rndtable[CDoom.prndindex].to_i32
  end

  def self.m_random : Int32
    CDoom.rndindex = (CDoom.rndindex + 1) & 0xff
    return CDoom.rndtable[CDoom.rndindex].to_i32
  end

  def self.m_clear_random
    CDoom.rndindex = 0
    CDoom.prndindex = 0
  end

  def self.t_move_ceiling(ceiling : CDoom::Ceiling*)
    case ceiling.value.direction
    when 0
      # IN STASIS
    when 1
      # UP
      res = CDoom.t_move_plane(ceiling.value.sector,
        ceiling.value.speed,
        ceiling.value.topheight,
        0, 1, ceiling.value.direction)

      if (CDoom.leveltime & 7) == 0
        case ceiling.value.type
        when CDoom::Ceilingenum::SilentCrushAndRaise
        else
          CDoom.s_start_sound(pointerof(ceiling.value.sector.value.@soundorg),
            CDoom::Sfxenum::SFX_stnmov)
        end
      end

      if res == CDoom::Result::Pastdest
        case ceiling.value.type
        when CDoom::Ceilingenum::RaiseToHighest
          CDoom.p_remove_active_ceiling(ceiling)
        when CDoom::Ceilingenum::SilentCrushAndRaise
          CDoom.s_start_sound(pointerof(ceiling.value.sector.value.@soundorg),
            CDoom::Sfxenum::SFX_pstop)
        when CDoom::Ceilingenum::FastCrushAndRaise, CDoom::Ceilingenum::CrushAndRaise
          ceiling.value.direction = -1
        end
      end
    when -1
      # DOWN
      res = CDoom.t_move_plane(ceiling.value.sector,
        ceiling.value.speed,
        ceiling.value.bottomheight,
        ceiling.value.crush, 1, ceiling.value.direction)

      if (CDoom.leveltime & 7) == 0
        case ceiling.value.type
        when CDoom::Ceilingenum::SilentCrushAndRaise
        else
          CDoom.s_start_sound(pointerof(ceiling.value.sector.value.@soundorg),
            CDoom::Sfxenum::SFX_stnmov)
        end
      end

      if res == CDoom::Result::Pastdest
        case ceiling.value.type
        when CDoom::Ceilingenum::SilentCrushAndRaise
          CDoom.s_start_sound(pointerof(ceiling.value.sector.value.@soundorg),
            CDoom::Sfxenum::SFX_pstop)
        when CDoom::Ceilingenum::CrushAndRaise
          ceiling.value.speed = CDoom::CEILSPEED
        when CDoom::Ceilingenum::FastCrushAndRaise
          ceiling.value.direction = 1
        when CDoom::Ceilingenum::LowerAndCrush, CDoom::Ceilingenum::LowerToFloor
          CDoom.p_remove_active_ceiling(ceiling)
        end
      else
        if res == CDoom::Result::Crushed
          case ceiling.value.type
          when CDoom::Ceilingenum::SilentCrushAndRaise, CDoom::Ceilingenum::CrushAndRaise, CDoom::Ceilingenum::LowerAndCrush
            ceiling.value.speed = CDoom::CEILSPEED // 8
          end
        end
      end
    end
  end

  #
  # Move a ceiling up/down and all around!
  #
  def self.ev_do_ceiling(line : CDoom::Line*, type : CDoom::Ceilingenum) : LibC::Int
    secnum = -1
    rtn = 0

    # Reactivate in-stasis ceilings...for cetain types.
    case type
    when CDoom::Ceilingenum::FastCrushAndRaise, CDoom::Ceilingenum::SilentCrushAndRaise, CDoom::Ceilingenum::CrushAndRaise
      CDoom.p_activate_in_stasis_ceiling(line)
    end

    while (secnum = CDoom.p_find_sector_from_line_tag(line, secnum)) >= 0
      sec = CDoom.sectors + secnum
      next unless sec.value.specialdata.null?

      # new door thinker
      rtn = 1
      ceiling = CDoom.z_malloc(sizeof(CDoom::Ceiling), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Ceiling*)
      CDoom.p_add_thinker(pointerof(ceiling.value.@thinker))
      sec.value.specialdata = ceiling
      pointerof(ceiling.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_move_ceiling).pointer, Pointer(Void).null)
      ceiling.value.sector = sec
      ceiling.value.crush = 0

      case type
      when CDoom::Ceilingenum::FastCrushAndRaise
        ceiling.value.crush = 1
        ceiling.value.topheight = sec.value.ceilingheight
        ceiling.value.bottomheight = sec.value.floorheight + (8 * FRACUNIT)
        ceiling.value.direction = -1
        ceiling.value.speed = CDoom::CEILSPEED * 2
      when CDoom::Ceilingenum::SilentCrushAndRaise, CDoom::Ceilingenum::CrushAndRaise
        ceiling.value.crush = 1
        ceiling.value.topheight = sec.value.ceilingheight
      when CDoom::Ceilingenum::LowerAndCrush, CDoom::Ceilingenum::LowerToFloor
        ceiling.value.bottomheight = sec.value.floorheight
        if type != CDoom::Ceilingenum::LowerToFloor
          ceiling.value.bottomheight = ceiling.value.bottomheight + 8 * FRACUNIT
        end
        ceiling.value.direction = -1
        ceiling.value.speed = CDoom::CEILSPEED
      when CDoom::Ceilingenum::RaiseToHighest
        ceiling.value.topheight = CDoom.p_find_highest_ceiling_surrounding(sec)
        ceiling.value.direction = 1
        ceiling.value.speed = CDoom::CEILSPEED
      end

      ceiling.value.tag = sec.value.tag
      ceiling.value.type = type
      CDoom.p_add_active_ceiling(ceiling)
    end

    return rtn
  end

  #
  # Add an active ceiling
  #
  def self.p_add_active_ceiling(c : CDoom::Ceiling*)
    CDoom::MAXCEILINGS.times do |i|
      if CDoom.activeceilings[i].null?
        CDoom.activeceilings[i] = c
        return
      end
    end
  end

  #
  # Remove a ceiling's thinker
  #
  def self.p_remove_active_ceiling(c : CDoom::Ceiling*)
    CDoom::MAXCEILINGS.times do |i|
      if CDoom.activeceilings[i] == c
        CDoom.activeceilings[i].value.sector.value.specialdata = Pointer(Void).null
        CDoom.p_remove_thinker(pointerof(CDoom.activeceilings[i].value.@thinker))
        CDoom.activeceilings[i] = Pointer(CDoom::Ceiling).null
        break
      end
    end
  end

  #
  # Restart a ceiling that's in-stasis
  #
  def self.p_activate_in_stasis_ceiling(line : CDoom::Line*)
    CDoom::MAXCEILINGS.times do |i|
      if !CDoom.activeceilings[i].null? &&
         (CDoom.activeceilings[i].value.tag == line.value.tag) &&
         (CDoom.activeceilings[i].value.direction == 0)
        CDoom.activeceilings[i].value.direction = CDoom.activeceilings[i].value.olddirection
        pointerof(CDoom.activeceilings[i].value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_move_ceiling).pointer, Pointer(Void).null)
      end
    end
  end

  #
  # Stop a ceiling from crushing!
  #
  def self.ev_ceiling_crush_stop(line : CDoom::Line*) : LibC::Int
    rtn = 0
    CDoom::MAXCEILINGS.times do |i|
      if !CDoom.activeceilings[i].null? &&
         CDoom.activeceilings[i].value.tag == line.value.tag &&
         CDoom.activeceilings[i].value.direction != 0
        CDoom.activeceilings[i].value.olddirection = CDoom.activeceilings[i].value.direction
        pointerof(CDoom.activeceilings[i].value.@thinker.@function).as(CDoom::ActionfV*).value = NULL_PROC
        CDoom.activeceilings[i].value.direction = 0 # in-stasis
        rtn = 1
      end
    end

    return rtn
  end

  #
  # Move a locked door up/down
  #
  def self.t_vertical_door(door : CDoom::Vldoor*)
    case door.value.direction
    when 0
      # WAITING
      door.value.topcountdown = door.value.topcountdown - 1
      if door.value.topcountdown == 0
        case door.value.type
        when CDoom::Vldoorenum::BlazeRaise
          door.value.direction = -1 # time to go back down
          CDoom.s_start_sound(pointerof(door.value.sector.value.@soundorg),
            CDoom::Sfxenum::SFX_bdcls)
        when CDoom::Vldoorenum::DoorNormal
          door.value.direction = -1 # time to go back down
          CDoom.s_start_sound(pointerof(door.value.sector.value.@soundorg),
            CDoom::Sfxenum::SFX_dorcls)
        when CDoom::Vldoorenum::Close30ThenOpen
          door.value.direction = 1
          CDoom.s_start_sound(pointerof(door.value.sector.value.@soundorg),
            CDoom::Sfxenum::SFX_doropn)
        end
      end
    when 2
      # INITIAL WAIT
      door.value.topcountdown = door.value.topcountdown - 1
      if door.value.topcountdown == 0
        case door.value.type
        when CDoom::Vldoorenum::RaiseIn5Mins
          door.value.direction = 1
          door.value.type = CDoom::Vldoorenum::DoorNormal
          CDoom.s_start_sound(pointerof(door.value.sector.value.@soundorg),
            CDoom::Sfxenum::SFX_doropn)
        end
      end
    when -1
      # DOWN
      res = CDoom.t_move_plane(door.value.sector,
        door.value.speed,
        door.value.sector.value.floorheight,
        0, 1, door.value.direction)
      if res == CDoom::Result::Pastdest
        case door.value.type
        when CDoom::Vldoorenum::BlazeRaise, CDoom::Vldoorenum::BlazeClose
          door.value.sector.value.specialdata = Pointer(Void).null
          CDoom.p_remove_thinker(pointerof(door.value.@thinker)) # unlink and free
          CDoom.s_start_sound(pointerof(door.value.sector.value.@soundorg),
            CDoom::Sfxenum::SFX_bdcls)
        when CDoom::Vldoorenum::DoorNormal, CDoom::Vldoorenum::DoorClose
          door.value.sector.value.specialdata = Pointer(Void).null
          CDoom.p_remove_thinker(pointerof(door.value.@thinker)) # unlink and free
        when CDoom::Vldoorenum::Close30ThenOpen
          door.value.direction = 0
          door.value.topcountdown = 35 * 30
        end
      elsif res == CDoom::Result::Crushed
        case door.value.type
        when CDoom::Vldoorenum::BlazeClose, CDoom::Vldoorenum::DoorClose
          # DO NOT GO BACK UP!
        else
          door.value.direction = 1
          CDoom.s_start_sound(pointerof(door.value.sector.value.@soundorg),
            CDoom::Sfxenum::SFX_doropn)
        end
      end
    when 1
      # UP
      res = CDoom.t_move_plane(door.value.sector,
        door.value.speed,
        door.value.topheight,
        0, 1, door.value.direction)

      if res == CDoom::Result::Pastdest
        case door.value.type
        when CDoom::Vldoorenum::BlazeRaise, CDoom::Vldoorenum::DoorNormal
          door.value.direction = 0 # wait at top
          door.value.topcountdown = door.value.topwait
        when CDoom::Vldoorenum::Close30ThenOpen, CDoom::Vldoorenum::BlazeOpen, CDoom::Vldoorenum::DoorOpen
          door.value.sector.value.specialdata = Pointer(Void).null
          CDoom.p_remove_thinker(pointerof(door.value.@thinker)) # unlink and free
        end
      end
    end
  end

  def self.ev_do_locked_door(line : CDoom::Line*, type : CDoom::Vldoorenum, thing : CDoom::Mobj*) : LibC::Int
    p = thing.value.player

    return 0 if p.null?

    case line.value.special
    when 99, 133 # Blue Lock
      if p.value.cards[CDoom::Card::Bluecard.value] == 0 && p.value.cards[CDoom::Card::Blueskull.value] == 0
        p.value.message = @@deh_pd_blueo
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_oof)
        return 0
      end
    when 134, 135 # Red Lock
      if p.value.cards[CDoom::Card::Redcard.value] == 0 && p.value.cards[CDoom::Card::Redskull.value] == 0
        p.value.message = @@deh_pd_redo
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_oof)
        return 0
      end
    when 136, 137 # Yellow Lock
      if p.value.cards[CDoom::Card::Yellowcard.value] == 0 && p.value.cards[CDoom::Card::Yellowskull.value] == 0
        p.value.message = @@deh_pd_yellowo
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_oof)
        return 0
      end
    end

    return CDoom.ev_do_door(line, type)
  end

  #
  # open a door manually, no tag value
  #
  def self.ev_do_door(line : CDoom::Line*, type : CDoom::Vldoorenum) : LibC::Int
    secnum = -1
    rtn = 0

    while (secnum = CDoom.p_find_sector_from_line_tag(line, secnum)) >= 0
      sec = CDoom.sectors + secnum
      next unless sec.value.specialdata.null?

      # new door thinker
      rtn = 1
      door = CDoom.z_malloc(sizeof(CDoom::Vldoor), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Vldoor*)
      CDoom.p_add_thinker(pointerof(door.value.@thinker))
      sec.value.specialdata = door

      pointerof(door.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_vertical_door).pointer, Pointer(Void).null)
      door.value.sector = sec
      door.value.type = type
      door.value.topwait = CDoom::VDOORWAIT
      door.value.speed = CDoom::VDOORSPEED

      case type
      when CDoom::Vldoorenum::BlazeClose
        door.value.topheight = CDoom.p_find_lowest_ceiling_surrounding(sec)
        door.value.topheight = door.value.topheight - 4 * FRACUNIT
        door.value.direction = -1
        door.value.speed = CDoom::VDOORSPEED * 4
        CDoom.s_start_sound(pointerof(door.value.sector.value.@soundorg),
          CDoom::Sfxenum::SFX_bdcls)
      when CDoom::Vldoorenum::DoorClose
        door.value.topheight = CDoom.p_find_lowest_ceiling_surrounding(sec)
        door.value.topheight = door.value.topheight - 4 * FRACUNIT
        door.value.direction = -1
        CDoom.s_start_sound(pointerof(door.value.sector.value.@soundorg),
          CDoom::Sfxenum::SFX_dorcls)
      when CDoom::Vldoorenum::Close30ThenOpen
        door.value.topheight = sec.value.ceilingheight
        door.value.direction = -1
        CDoom.s_start_sound(pointerof(door.value.sector.value.@soundorg),
          CDoom::Sfxenum::SFX_dorcls)
      when CDoom::Vldoorenum::BlazeRaise, CDoom::Vldoorenum::BlazeOpen
        door.value.direction = 1
        door.value.topheight = CDoom.p_find_lowest_ceiling_surrounding(sec)
        door.value.topheight = door.value.topheight - 4 * FRACUNIT
        door.value.speed = CDoom::VDOORSPEED * 4
        CDoom.s_start_sound(pointerof(door.value.sector.value.@soundorg),
          CDoom::Sfxenum::SFX_bdopn) if door.value.topheight != sec.value.ceilingheight
      when CDoom::Vldoorenum::DoorNormal, CDoom::Vldoorenum::DoorOpen
        door.value.direction = 1
        door.value.topheight = CDoom.p_find_lowest_ceiling_surrounding(sec)
        door.value.topheight = door.value.topheight - 4 * FRACUNIT
        CDoom.s_start_sound(pointerof(door.value.sector.value.@soundorg),
          CDoom::Sfxenum::SFX_doropn) if door.value.topheight != sec.value.ceilingheight
      end
    end

    return rtn
  end

  def self.ev_vertical_door(line : CDoom::Line*, thing : CDoom::Mobj*)
    side = 0 # only front sides can be used

    # Check for locks
    player = thing.value.player

    case line.value.special
    when 26, 32 # Blue Lock
      return if player.null?

      if player.value.cards[CDoom::Card::Bluecard.value] == 0 && player.value.cards[CDoom::Card::Blueskull.value] == 0
        player.value.message = @@deh_pd_bluek
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_oof)
        return
      end
    when 27, 34 # Yellow Lock
      return if player.null?

      if player.value.cards[CDoom::Card::Yellowcard.value] == 0 && player.value.cards[CDoom::Card::Yellowskull.value] == 0
        player.value.message = @@deh_pd_yellowk
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_oof)
        return
      end
    when 28, 33 # Red Lock
      return if player.null?

      if player.value.cards[CDoom::Card::Redcard.value] == 0 && player.value.cards[CDoom::Card::Redskull.value] == 0
        player.value.message = @@deh_pd_redk
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_oof)
        return
      end
    end

    # if the sector has an active thinker, use it
    sec = CDoom.sides[line.value.sidenum[side ^ 1]].sector
    secnum = (sec - CDoom.sectors).to_i32!

    unless sec.value.specialdata.null?
      door = sec.value.specialdata.as(CDoom::Vldoor*)
      case line.value.special
      when 1, 26, 27, 28, 117 # ONLY FOR "RAISE" DOORS, NOT "OPEN"s
        if door.value.direction == -1
          door.value.direction = 1 # go back up
        else
          return if thing.value.player.null? # JDC: bad guys never close doors

          door.value.direction = -1 # start going down immediately
        end
        return
      end
    end

    # for proper sound
    case line.value.special
    when 117, 118 # BLAZING DOOR RAISE, OPEN
      CDoom.s_start_sound(pointerof(sec.value.@soundorg),
        CDoom::Sfxenum::SFX_bdopn)
    when 1, 31 # NORMAL DOOR SOUND
      CDoom.s_start_sound(pointerof(sec.value.@soundorg),
        CDoom::Sfxenum::SFX_doropn)
    else # LOCKED DOOR SOUND
      CDoom.s_start_sound(pointerof(sec.value.@soundorg),
        CDoom::Sfxenum::SFX_doropn)
    end

    # new door thinker
    door = CDoom.z_malloc(sizeof(CDoom::Vldoor), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Vldoor*)
    CDoom.p_add_thinker(pointerof(door.value.@thinker))
    sec.value.specialdata = door
    pointerof(door.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_vertical_door).pointer, Pointer(Void).null)
    door.value.sector = sec
    door.value.direction = 1
    door.value.speed = CDoom::VDOORSPEED
    door.value.topwait = CDoom::VDOORWAIT

    case line.value.special
    when 1, 26, 27, 28
      door.value.type = CDoom::Vldoorenum::DoorNormal
    when 31, 32, 33, 34
      door.value.type = CDoom::Vldoorenum::DoorOpen
      line.value.special = 0
    when 117 # blazing door raise
      door.value.type = CDoom::Vldoorenum::BlazeRaise
      door.value.speed = CDoom::VDOORSPEED * 4
    when 118 # blazing door open
      door.value.type = CDoom::Vldoorenum::BlazeOpen
      line.value.special = 0
      door.value.speed = CDoom::VDOORSPEED * 4
    end

    # find the top and bottom of the movement range
    door.value.topheight = CDoom.p_find_lowest_ceiling_surrounding(sec)
    door.value.topheight = door.value.topheight - 4 * FRACUNIT
  end

  #
  # Spawn a door that closes after 30 seconds
  #
  def self.p_spawn_door_close_in_30(sec : CDoom::Sector*)
    door = CDoom.z_malloc(sizeof(CDoom::Vldoor), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Vldoor*)

    CDoom.p_add_thinker(pointerof(door.value.@thinker))

    sec.value.specialdata = door
    sec.value.special = 0

    pointerof(door.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_vertical_door).pointer, Pointer(Void).null)
    door.value.sector = sec
    door.value.direction = 0
    door.value.type = CDoom::Vldoorenum::DoorNormal
    door.value.speed = CDoom::VDOORSPEED
    door.value.topcountdown = 30 * 35
  end

  #
  # Spawn a door that opens after 5 minutes
  #
  def self.p_spawn_door_raise_in_5_mins(sec : CDoom::Sector*, secnum : LibC::Int)
    door = CDoom.z_malloc(sizeof(CDoom::Vldoor), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Vldoor*)

    CDoom.p_add_thinker(pointerof(door.value.@thinker))

    sec.value.specialdata = door
    sec.value.special = 0

    pointerof(door.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_vertical_door).pointer, Pointer(Void).null)
    door.value.sector = sec
    door.value.direction = 2
    door.value.type = CDoom::Vldoorenum::RaiseIn5Mins
    door.value.speed = CDoom::VDOORSPEED
    door.value.topheight = CDoom.p_find_lowest_ceiling_surrounding(sec)
    door.value.topheight = door.value.topheight - 4 * FRACUNIT
    door.value.topwait = CDoom::VDOORWAIT
    door.value.topcountdown = 5 * 60 * 35
  end

  #
  # ENEMY THINKING
  # Enemies are allways spawned
  # with targetplayer = -1, threshold = 0
  # Most monsters are spawned unaware of all players,
  # but some can be made preaware
  #

  #
  # Called by p_noise_alert.
  # Recursively traverse adjacent sectors,
  # sound blocking lines cut off traversal.
  #
  def self.p_recursive_sound(sec : CDoom::Sector*, soundblocks : LibC::Int)
    # wake up all monsters in this sector
    if sec.value.validcount == CDoom.validcount &&
       sec.value.soundtraversed <= soundblocks + 1
      return # already flooded
    end

    sec.value.validcount = CDoom.validcount
    sec.value.soundtraversed = soundblocks + 1
    sec.value.soundtarget = CDoom.soundtarget

    sec.value.linecount.times do |i|
      check = sec.value.lines[i]
      next if check.value.flags & CDoom::ML_TWOSIDED == 0

      CDoom.p_line_opening(check)

      next if CDoom.openrange <= 0 # closed door

      other = CDoom.sides[check.value.sidenum[0]].sector
      if CDoom.sides[check.value.sidenum[0]].sector == sec
        other = CDoom.sides[check.value.sidenum[1]].sector
      end

      if check.value.flags & CDoom::ML_SOUNDBLOCK != 0
        CDoom.p_recursive_sound(other, 1) if soundblocks == 0
      else
        CDoom.p_recursive_sound(other, soundblocks)
      end
    end
  end

  #
  # If a monster yells at a player,
  # it will alert other monsters to the player.
  #
  def self.p_noise_alert(target : CDoom::Mobj*, emmiter : CDoom::Mobj*)
    CDoom.soundtarget = target
    CDoom.validcount += 1
    CDoom.p_recursive_sound(emmiter.value.subsector.value.sector, 0)
  end

  def self.p_check_melee_range(actor : CDoom::Mobj*) : CDoom::DoomBool
    return 0 if actor.value.target.null?

    pl = actor.value.target
    dist = CDoom.p_aprox_distance(pl.value.x - actor.value.x, pl.value.y - actor.value.y)

    return 0 if dist >= CDoom::MELEERANGE - 20 * FRACUNIT + pl.value.info.value.radius

    return 0 if CDoom.p_check_sight(actor, actor.value.target) == 0

    return 1
  end

  def self.p_check_missile_range(actor : CDoom::Mobj*) : CDoom::DoomBool
    return 0 if CDoom.p_check_sight(actor, actor.value.target) == 0

    if actor.value.flags & CDoom::Mobjflag::MF_JUSTHIT.value != 0
      # the target just hit the enemy,
      # so fight back!
      actor.value.flags = actor.value.flags & ~CDoom::Mobjflag::MF_JUSTHIT.value
      return 1
    end

    return 0 if actor.value.reactiontime != 0 # do not attack yet

    # OPTIMIZE: get this from a global checksight
    dist = CDoom.p_aprox_distance(actor.value.x - actor.value.target.value.x,
      actor.value.y - actor.value.target.value.y) - 64 * FRACUNIT

    dist -= 128 * FRACUNIT if actor.value.info.value.meleestate == 0 # no melee attack, so fire more

    dist >>= 16

    if actor.value.type == CDoom::Mobjtype::MT_VILE
      return 0 if dist > 14 * 64 # too far away
    end

    if actor.value.type == CDoom::Mobjtype::MT_UNDEAD
      return 0 if dist < 196 # close for fist attack
      dist >>= 1
    end

    if actor.value.type == CDoom::Mobjtype::MT_CYBORG ||
       actor.value.type == CDoom::Mobjtype::MT_SPIDER ||
       actor.value.type == CDoom::Mobjtype::MT_SKULL
      dist >>= 1
    end

    dist = 200 if dist > 200
    dist = 160 if actor.value.type == CDoom::Mobjtype::MT_CYBORG && dist > 160

    return 0 if CDoom.p_random < dist

    return 1
  end

  def self.p_move(actor : CDoom::Mobj*) : CDoom::DoomBool
    return 0 if actor.value.movedir == CDoom::Dirtype::NoDir.value

    CDoom.i_error("Error: Weird actor.value.movedir!") if actor.value.movedir.to_u32! >= 8

    tryx = actor.value.x + actor.value.info.value.speed * CDoom.xspeed[actor.value.movedir]
    tryy = actor.value.y + actor.value.info.value.speed * CDoom.yspeed[actor.value.movedir]

    try_ok = CDoom.p_try_move(actor, tryx, tryy)

    if try_ok == 0
      # open any specials
      if actor.value.flags & CDoom::Mobjflag::MF_FLOAT.value != 0 && CDoom.floatok != 0
        # must adjust height
        if actor.value.z < CDoom.tmfloorz
          actor.value.z = actor.value.z + CDoom::FLOATSPEED
        else
          actor.value.z = actor.value.z - CDoom::FLOATSPEED
        end
        actor.value.flags = actor.value.flags | CDoom::Mobjflag::MF_INFLOAT.value
        return 1
      end

      return 0 if CDoom.numspechit == 0

      actor.value.movedir = CDoom::Dirtype::NoDir.value
      good = 0
      while CDoom.numspechit != 0
        CDoom.numspechit -= 1
        ld = CDoom.spechit[CDoom.numspechit]
        # if the special is not a door
        # that can be opened,
        # return false
        good = 1 if CDoom.p_use_special_line(actor, ld, 0) != 0
      end
      return good
    else
      actor.value.flags = actor.value.flags & ~CDoom::Mobjflag::MF_INFLOAT.value
    end

    actor.value.z = actor.value.floorz if actor.value.flags & CDoom::Mobjflag::MF_FLOAT.value == 0

    return 1
  end

  #
  # Attempts to move actor on
  # in its current (ob->moveangle) direction.
  # If blocked by either a wall or an actor
  # returns FALSE
  # If move is either clear or blocked only by a door,
  # returns TRUE and sets...
  # If a door is in the way,
  # an OpenDoor call is made to start it opening.
  #
  def self.p_try_walk(actor : CDoom::Mobj*) : CDoom::DoomBool
    return 0 if CDoom.p_move(actor) == 0

    actor.value.movecount = CDoom.p_random & 15
    return 1
  end

  def self.p_new_chase_dir(actor : CDoom::Mobj*)
    d = uninitialized StaticArray(CDoom::Dirtype, 3)

    CDoom.i_error("Error: p_new_chase_dir: called with no target") if actor.value.target.null?

    olddir = actor.value.movedir
    turnaround = CDoom.opposite[olddir]

    deltax = actor.value.target.value.x - actor.value.x
    deltay = actor.value.target.value.y - actor.value.y

    if deltax > 10 * FRACUNIT
      d[1] = CDoom::Dirtype::East
    elsif deltax < -10 * FRACUNIT
      d[1] = CDoom::Dirtype::West
    else
      d[1] = CDoom::Dirtype::NoDir
    end

    if deltay < -10 * FRACUNIT
      d[2] = CDoom::Dirtype::South
    elsif deltay > 10 * FRACUNIT
      d[2] = CDoom::Dirtype::North
    else
      d[2] = CDoom::Dirtype::NoDir
    end

    # try direct route
    if d[1] != CDoom::Dirtype::NoDir &&
       d[2] != CDoom::Dirtype::NoDir
      actor.value.movedir = CDoom.diags[((deltay < 0).to_unsafe << 1) + (deltax > 0).to_unsafe].value
      return if actor.value.movedir != turnaround.value && CDoom.p_try_walk(actor) != 0
    end

    # try other directions
    if CDoom.p_random > 200 ||
       doom_abs(deltay) > doom_abs(deltax)
      tdir = d[1]
      d[1] = d[2]
      d[2] = tdir
    end

    d[1] = CDoom::Dirtype::NoDir if d[1] == turnaround
    d[2] = CDoom::Dirtype::NoDir if d[2] == turnaround

    if d[1] != CDoom::Dirtype::NoDir
      actor.value.movedir = d[1].value
      return if CDoom.p_try_walk(actor) != 0 # either moved toward or attacked
    end

    if d[2] != CDoom::Dirtype::NoDir
      actor.value.movedir = d[2].value
      return if CDoom.p_try_walk(actor) != 0
    end

    # there is no direct path to the player,
    # so pick another direction.
    if olddir != CDoom::Dirtype::NoDir.value
      actor.value.movedir = olddir
      return if CDoom.p_try_walk(actor) != 0
    end

    # randomly determine direction of search
    if CDoom.p_random & 1 != 0
      tdir = CDoom::Dirtype::East.value
      while tdir <= CDoom::Dirtype::SouthEast.value
        if tdir != turnaround.value
          actor.value.movedir = tdir

          return if CDoom.p_try_walk(actor) != 0
        end
        tdir += 1
      end
    else
      tdir = CDoom::Dirtype::SouthEast.value
      while tdir != (CDoom::Dirtype::East.value - 1)
        if tdir != turnaround.value
          actor.value.movedir = tdir

          return if CDoom.p_try_walk(actor) != 0
        end
        tdir -= 1
      end
    end

    if turnaround != CDoom::Dirtype::NoDir
      actor.value.movedir = turnaround.value
      return if CDoom.p_try_walk(actor) != 0
    end

    actor.value.movedir = CDoom::Dirtype::NoDir.value # can not move
  end

  def self.p_look_for_players(actor : CDoom::Mobj*, allaround : CDoom::DoomBool) : CDoom::DoomBool
    sector = actor.value.subsector.value.sector

    c = 0
    stop = (actor.value.lastlook - 1) & 3

    loop do
      if CDoom.playeringame[actor.value.lastlook] == 0
        actor.value.lastlook = (actor.value.lastlook + 1) & 3
        next
      end

      c += 1
      if c == 3 || actor.value.lastlook == stop
        # done looking
        return 0
      end

      player = CDoom.players.to_unsafe + actor.value.lastlook

      if player.value.health <= 0
        actor.value.lastlook = (actor.value.lastlook + 1) & 3
        next # dead
      end

      if CDoom.p_check_sight(actor, player.value.mo) == 0
        actor.value.lastlook = (actor.value.lastlook + 1) & 3
        next # out of sight
      end

      if allaround == 0
        an : CDoom::Angle = CDoom.r_point_to_angle2(actor.value.x,
          actor.value.y,
          player.value.mo.value.x,
          player.value.mo.value.y) &- actor.value.angle

        if an > ANG90 && an < ANG270
          dist = CDoom.p_aprox_distance(player.value.mo.value.x - actor.value.x,
            player.value.mo.value.y - actor.value.y)
          # if real close, react anyway
          if dist > CDoom::MELEERANGE
            actor.value.lastlook = (actor.value.lastlook + 1) & 3
            next # behind back
          end
        end
      end

      actor.value.target = player.value.mo
      return 1
    end

    return 0
  end

  def self.a_keen_die(mo : CDoom::Mobj*)
    CDoom.a_fall(mo)

    # scan the remaining thinkers
    # to see if all Keens are dead
    th = CDoom.thinkercap.next
    while th != pointerof(CDoom.thinkercap)
      if th.value.function.acp1.pointer != (->CDoom.p_mobj_thinker).pointer
        th = th.value.next
        next
      end

      mo2 = th.as(CDoom::Mobj*)
      if mo2 != mo &&
         mo2.value.type == mo.value.type &&
         mo2.value.health > 0
        # other Keen not dead
        return
      end
      th = th.value.next
    end

    junk = CDoom::Line.new(tag: 666)
    CDoom.ev_do_door(pointerof(junk), CDoom::Vldoorenum::DoorOpen)
  end

  #
  # ACTION ROUTINES
  #

  #
  # Stay in state until a player is sighted.
  #
  def self.a_look(actor : CDoom::Mobj*)
    seeyou = false

    actor.value.threshold = 0 # any shot will wake up
    targ = actor.value.subsector.value.sector.value.soundtarget

    if !targ.null? &&
       (targ.value.flags & CDoom::Mobjflag::MF_SHOOTABLE.value) != 0
      actor.value.target = targ

      if actor.value.flags & CDoom::Mobjflag::MF_AMBUSH.value != 0
        seeyou = true if CDoom.p_check_sight(actor, actor.value.target) != 0
      else
        seeyou = true
      end
    end

    return if !seeyou && CDoom.p_look_for_players(actor, 0) == 0

    # go into chase state
    if actor.value.info.value.seesound != 0
      sound = 0

      case actor.value.info.value.seesound
      when CDoom::Sfxenum::SFX_posit1.value, CDoom::Sfxenum::SFX_posit2.value, CDoom::Sfxenum::SFX_posit3.value
        sound = CDoom::Sfxenum::SFX_posit1.value + CDoom.p_random % 3
      when CDoom::Sfxenum::SFX_bgsit1.value, CDoom::Sfxenum::SFX_bgsit2.value
        sound = CDoom::Sfxenum::SFX_bgsit1.value + CDoom.p_random % 2
      else
        sound = actor.value.info.value.seesound
      end

      if actor.value.type == CDoom::Mobjtype::MT_SPIDER ||
         actor.value.type == CDoom::Mobjtype::MT_CYBORG
        # full volume
        CDoom.s_start_sound(Pointer(Void).null, sound)
      else
        CDoom.s_start_sound(actor, sound)
      end
    end

    CDoom.p_set_mobj_state(actor, CDoom::Statenum.new(actor.value.info.value.seestate))
  end

  #
  # Actor has a melee attack,
  # so it tries to close as fast as possible
  #
  def self.a_chase(actor : CDoom::Mobj*)
    actor.value.reactiontime = actor.value.reactiontime - 1 if actor.value.reactiontime != 0

    # modify target threshold
    if actor.value.threshold != 0
      if actor.value.target.null? ||
         actor.value.target.value.health <= 0
        actor.value.threshold = 0
      else
        actor.value.threshold = actor.value.threshold - 1
      end
    end

    # turn towards movement direction if not there yet
    if actor.value.movedir < 8
      actor.value.angle = actor.value.angle & (7 << 29)
      delta = (actor.value.angle &- (actor.value.movedir.to_u32! << 29)).to_i32!

      if delta > 0
        actor.value.angle = actor.value.angle &- ANG90.tdiv(2)
      elsif delta < 0
        actor.value.angle = actor.value.angle &+ ANG90.tdiv(2)
      end
    end

    if actor.value.target.null? ||
       actor.value.target.value.flags & CDoom::Mobjflag::MF_SHOOTABLE.value == 0
      # look for a new target
      return if CDoom.p_look_for_players(actor, 1) != 0 # got a new target

      CDoom.p_set_mobj_state(actor, CDoom::Statenum.new(actor.value.info.value.spawnstate))
      return
    end

    # do not attack twice in a row
    if actor.value.flags & CDoom::Mobjflag::MF_JUSTATTACKED.value != 0
      actor.value.flags = actor.value.flags & ~CDoom::Mobjflag::MF_JUSTATTACKED.value
      CDoom.p_new_chase_dir(actor) if CDoom.gameskill != CDoom::Skill::Nightmare && CDoom.fastparm == 0
      return
    end

    # check for melee attack
    if actor.value.info.value.meleestate != 0 &&
       CDoom.p_check_melee_range(actor) != 0
      CDoom.s_start_sound(actor, actor.value.info.value.attacksound) if actor.value.info.value.attacksound != 0

      CDoom.p_set_mobj_state(actor, CDoom::Statenum.new(actor.value.info.value.meleestate))
      return
    end

    nomissile = false
    # check for missile attack
    if actor.value.info.value.missilestate != 0
      if CDoom.gameskill < CDoom::Skill::Nightmare &&
         CDoom.fastparm == 0 && actor.value.movecount != 0
        nomissile = true
      end

      unless nomissile
        nomissile = true if CDoom.p_check_missile_range(actor) == 0

        unless nomissile
          CDoom.p_set_mobj_state(actor, CDoom::Statenum.new(actor.value.info.value.missilestate))
          actor.value.flags = actor.value.flags | CDoom::Mobjflag::MF_JUSTATTACKED.value
          return
        end
      end
    end

    # possibly choose another target
    if CDoom.netgame != 0 &&
       actor.value.threshold == 0 &&
       CDoom.p_check_sight(actor, actor.value.target) == 0
      return if CDoom.p_look_for_players(actor, 1) != 0 # got a new target
    end

    # chase towards player
    actor.value.movecount = actor.value.movecount - 1
    if actor.value.movecount < 0 ||
       CDoom.p_move(actor) == 0
      CDoom.p_new_chase_dir(actor)
    end

    # make active sound
    if actor.value.info.value.activesound != 0 &&
       CDoom.p_random < 3
      CDoom.s_start_sound(actor, actor.value.info.value.activesound)
    end
  end

  def self.a_face_target(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    actor.value.flags = actor.value.flags & ~CDoom::Mobjflag::MF_AMBUSH.value

    actor.value.angle = CDoom.r_point_to_angle2(actor.value.x,
      actor.value.y,
      actor.value.target.value.x,
      actor.value.target.value.y)

    if actor.value.target.value.flags & CDoom::Mobjflag::MF_SHADOW.value != 0
      actor.value.angle = actor.value.angle &+ ((CDoom.p_random - CDoom.p_random) << 21)
    end
  end

  def self.a_pos_attack(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.a_face_target(actor)
    angle = actor.value.angle
    slope = CDoom.p_aim_line_attack(actor, angle, CDoom::MISSILERANGE)

    CDoom.s_start_sound(actor, CDoom::Sfxenum::SFX_pistol.value)
    angle &+= (CDoom.p_random - CDoom.p_random) << 20
    damage = ((CDoom.p_random % 5) + 1) * 3
    CDoom.p_line_attack(actor, angle, CDoom::MISSILERANGE, slope, damage)
  end

  def self.a_spos_attack(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.s_start_sound(actor, CDoom::Sfxenum::SFX_shotgn.value)
    CDoom.a_face_target(actor)
    bangle = actor.value.angle
    slope = CDoom.p_aim_line_attack(actor, bangle, CDoom::MISSILERANGE)

    3.times do |i|
      angle = bangle &+ ((CDoom.p_random - CDoom.p_random) << 20)
      damage = ((CDoom.p_random % 5) + 1) * 3
      CDoom.p_line_attack(actor, angle, CDoom::MISSILERANGE, slope, damage)
    end
  end

  def self.a_cpos_attack(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.s_start_sound(actor, CDoom::Sfxenum::SFX_shotgn.value)
    CDoom.a_face_target(actor)
    bangle = actor.value.angle
    slope = CDoom.p_aim_line_attack(actor, bangle, CDoom::MISSILERANGE)

    angle = bangle &+ ((CDoom.p_random - CDoom.p_random) << 20)
    damage = ((CDoom.p_random % 5) + 1) * 3
    CDoom.p_line_attack(actor, angle, CDoom::MISSILERANGE, slope, damage)
  end

  def self.a_cpos_refire(actor : CDoom::Mobj*)
    # keep firing unless target got out of sight
    CDoom.a_face_target(actor)

    return if CDoom.p_random < 40

    if actor.value.target.null? ||
       actor.value.target.value.health <= 0 ||
       CDoom.p_check_sight(actor, actor.value.target) == 0
      CDoom.p_set_mobj_state(actor, CDoom::Statenum.new(actor.value.info.value.seestate))
    end
  end

  def self.a_spid_refire(actor : CDoom::Mobj*)
    # keep firing unless target got out of sight
    CDoom.a_face_target(actor)

    return if CDoom.p_random < 10

    if actor.value.target.null? ||
       actor.value.target.value.health <= 0 ||
       CDoom.p_check_sight(actor, actor.value.target) == 0
      CDoom.p_set_mobj_state(actor, CDoom::Statenum.new(actor.value.info.value.seestate))
    end
  end

  def self.a_bspi_attack(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.a_face_target(actor)

    # launch a missile
    CDoom.p_spawn_missile(actor, actor.value.target, CDoom::Mobjtype::MT_ARACHPLAZ)
  end

  def self.a_troop_attack(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.a_face_target(actor)
    if CDoom.p_check_melee_range(actor) != 0
      CDoom.s_start_sound(actor, CDoom::Sfxenum::SFX_claw.value)
      damage = (CDoom.p_random % 8 + 1) * 3
      CDoom.p_damage_mobj(actor.value.target, actor, actor, damage)
      return
    end

    # launch a missile
    CDoom.p_spawn_missile(actor, actor.value.target, CDoom::Mobjtype::MT_TROOPSHOT)
  end

  def self.a_sarg_attack(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.a_face_target(actor)
    if CDoom.p_check_melee_range(actor) != 0
      damage = ((CDoom.p_random % 10) + 1) * 4
      CDoom.p_damage_mobj(actor.value.target, actor, actor, damage)
    end
  end

  def self.a_head_attack(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.a_face_target(actor)
    if CDoom.p_check_melee_range(actor) != 0
      damage = (CDoom.p_random % 6 + 1) * 10
      CDoom.p_damage_mobj(actor.value.target, actor, actor, damage)
      return
    end

    # launch a missile
    CDoom.p_spawn_missile(actor, actor.value.target, CDoom::Mobjtype::MT_HEADSHOT)
  end

  def self.a_cyber_attack(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.a_face_target(actor)

    # launch a missile
    CDoom.p_spawn_missile(actor, actor.value.target, CDoom::Mobjtype::MT_ROCKET)
  end

  def self.a_bruis_attack(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.a_face_target(actor)
    if CDoom.p_check_melee_range(actor) != 0
      damage = (CDoom.p_random % 8 + 1) * 10
      CDoom.p_damage_mobj(actor.value.target, actor, actor, damage)
      return
    end

    # launch a missile
    CDoom.p_spawn_missile(actor, actor.value.target, CDoom::Mobjtype::MT_BRUISERSHOT)
  end

  def self.a_skel_missile(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.a_face_target(actor)
    actor.value.z = actor.value.z + 16 * FRACUNIT # so missile spawns higher
    mo = CDoom.p_spawn_missile(actor, actor.value.target, CDoom::Mobjtype::MT_TRACER)
    actor.value.z = actor.value.z - 16 * FRACUNIT # back to normal

    mo.value.x = mo.value.x + mo.value.momx
    mo.value.y = mo.value.y + mo.value.momy
    mo.value.tracer = actor.value.target
  end

  def self.a_tracer(actor : CDoom::Mobj*)
    return if CDoom.gametic & 3 != 0

    # spawn a puff of smoke behind the rocket
    CDoom.p_spawn_puff(actor.value.x, actor.value.y, actor.value.z)

    th = CDoom.p_spawn_mobj(actor.value.x - actor.value.momx,
      actor.value.y - actor.value.momy,
      actor.value.z, CDoom::Mobjtype::MT_SMOKE)

    th.value.momz = FRACUNIT
    th.value.tics = th.value.tics - (CDoom.p_random & 3)
    th.value.tics = 1 if th.value.tics < 1

    # adjust direction
    dest = actor.value.tracer

    return if dest.null? || dest.value.health <= 0

    # change angle
    exact = CDoom.r_point_to_angle2(actor.value.x,
      actor.value.y,
      dest.value.x,
      dest.value.y)

    if exact != actor.value.angle
      if exact &- actor.value.angle > 0x80000000
        actor.value.angle = actor.value.angle &- CDoom.traceangle
        actor.value.angle = exact if exact &- actor.value.angle < 0x80000000
      else
        actor.value.angle = actor.value.angle &+ CDoom.traceangle
        actor.value.angle = exact if exact &- actor.value.angle > 0x80000000
      end
    end

    exact = actor.value.angle >> CDoom::ANGLETOFINESHIFT
    actor.value.momx = CDoom.fixed_mul(actor.value.info.value.speed, @@finecosine[exact])
    actor.value.momy = CDoom.fixed_mul(actor.value.info.value.speed, @@finesine[exact])

    # change slope
    dist = CDoom.p_aprox_distance(dest.value.x - actor.value.x,
      dest.value.y - actor.value.y)

    dist = dist.tdiv(actor.value.info.value.speed)

    dist = 1 if dist < 1
    slope = (dest.value.z + 40 * FRACUNIT - actor.value.z).tdiv(dist)

    if slope < actor.value.momz
      actor.value.momz = actor.value.momz - FRACUNIT.tdiv(8)
    else
      actor.value.momz = actor.value.momz + FRACUNIT.tdiv(8)
    end
  end

  def self.a_skel_whoosh(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.a_face_target(actor)
    CDoom.s_start_sound(actor, CDoom::Sfxenum::SFX_skeswg.value)
  end

  def self.a_skel_fist(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.a_face_target(actor)

    if CDoom.p_check_melee_range(actor) != 0
      damage = ((CDoom.p_random % 10) + 1) * 6
      CDoom.s_start_sound(actor, CDoom::Sfxenum::SFX_skepch.value)
      CDoom.p_damage_mobj(actor.value.target, actor, actor, damage)
    end
  end

  #
  # Detect a corpse that could be raised.
  #
  def self.pit_vile_check(thing : CDoom::Mobj*) : CDoom::DoomBool
    return 1 if thing.value.flags & CDoom::Mobjflag::MF_CORPSE.value == 0 # not a monster

    return 1 if thing.value.tics != -1 # not lying still yet

    return 1 if thing.value.info.value.raisestate == CDoom::Statenum::S_NULL.value # monster doesn't have a raise state

    maxdist = thing.value.info.value.radius + CDoom.mobjinfo[CDoom::Mobjtype::MT_VILE.value].radius

    return 1 if doom_abs(thing.value.x - CDoom.viletryx) > maxdist ||
                doom_abs(thing.value.y - CDoom.viletryy) > maxdist # not actually touching

    CDoom.corpsehit = thing
    CDoom.corpsehit.value.momx = 0
    CDoom.corpsehit.value.momy = 0
    CDoom.corpsehit.value.height = CDoom.corpsehit.value.height << 2
    check = CDoom.p_check_position(CDoom.corpsehit, CDoom.corpsehit.value.x, CDoom.corpsehit.value.y)
    CDoom.corpsehit.value.height = CDoom.corpsehit.value.height >> 2

    return 1 if check == 0 # doesn't fit here

    return 0 # got one, so stop checking
  end

  #
  # Check for ressurecting a body
  #
  def self.a_vile_chase(actor : CDoom::Mobj*)
    if actor.value.movedir != CDoom::Dirtype::NoDir.value
      # check for corpses to raise
      CDoom.viletryx =
        actor.value.x + actor.value.info.value.speed * CDoom.xspeed[actor.value.movedir]
      CDoom.viletryy =
        actor.value.y + actor.value.info.value.speed * CDoom.yspeed[actor.value.movedir]

      xl = (CDoom.viletryx - CDoom.bmaporgx - CDoom::MAXRADIUS * 2) >> CDoom::MAPBLOCKSHIFT
      xh = (CDoom.viletryx - CDoom.bmaporgx + CDoom::MAXRADIUS * 2) >> CDoom::MAPBLOCKSHIFT
      yl = (CDoom.viletryy - CDoom.bmaporgy - CDoom::MAXRADIUS * 2) >> CDoom::MAPBLOCKSHIFT
      yh = (CDoom.viletryy - CDoom.bmaporgy + CDoom::MAXRADIUS * 2) >> CDoom::MAPBLOCKSHIFT

      vileobj = actor
      bx = xl
      while bx <= xh
        by = yl
        while by <= yh
          # Call pit_vile_check to check
          # whether object is a corpse
          # that canbe raised.
          if CDoom.p_block_things_iterator(bx, by, ->CDoom.pit_vile_check) == 0
            # got one!
            temp = actor.value.target
            actor.value.target = CDoom.corpsehit
            CDoom.a_face_target(actor)
            actor.value.target = temp

            CDoom.p_set_mobj_state(actor, CDoom::Statenum::S_VILE_HEAL1)
            CDoom.s_start_sound(CDoom.corpsehit, CDoom::Sfxenum::SFX_slop.value)
            info = CDoom.corpsehit.value.info

            CDoom.p_set_mobj_state(CDoom.corpsehit, CDoom::Statenum.new(info.value.raisestate))
            CDoom.corpsehit.value.height = CDoom.corpsehit.value.height << 2
            CDoom.corpsehit.value.flags = info.value.flags
            CDoom.corpsehit.value.health = info.value.spawnhealth
            CDoom.corpsehit.value.target = Pointer(CDoom::Mobj).null

            return
          end

          by += 1
        end

        bx += 1
      end
    end

    # Return to normal attack.
    CDoom.a_chase(actor)
  end

  def self.a_vile_start(actor : CDoom::Mobj*)
    CDoom.s_start_sound(actor, CDoom::Sfxenum::SFX_vilatk.value)
  end

  #
  # Keep fire in front of player unless out of sight
  #
  def self.a_start_fire(actor : CDoom::Mobj*)
    CDoom.s_start_sound(actor, CDoom::Sfxenum::SFX_flamst.value)
    CDoom.a_fire(actor)
  end

  def self.a_fire_crackle(actor : CDoom::Mobj*)
    CDoom.s_start_sound(actor, CDoom::Sfxenum::SFX_flame.value)
    CDoom.a_fire(actor)
  end

  def self.a_fire(actor : CDoom::Mobj*)
    dest = actor.value.tracer
    return if dest.null?

    # don't move it if the vile lost sight
    return if CDoom.p_check_sight(actor.value.target, dest) == 0

    an = dest.value.angle >> CDoom::ANGLETOFINESHIFT

    CDoom.p_unset_thing_position(actor)
    actor.value.x = dest.value.x + CDoom.fixed_mul(24 * FRACUNIT, @@finecosine[an])
    actor.value.y = dest.value.y + CDoom.fixed_mul(24 * FRACUNIT, @@finesine[an])
    actor.value.z = dest.value.z
    CDoom.p_set_thing_position(actor)
  end

  #
  # Spawn the hellfire
  #
  def self.a_vile_target(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.a_face_target(actor)

    fog = CDoom.p_spawn_mobj(actor.value.target.value.x,
      actor.value.target.value.y,
      actor.value.target.value.z, CDoom::Mobjtype::MT_FIRE)

    actor.value.tracer = fog
    fog.value.target = actor
    fog.value.tracer = actor.value.target
    CDoom.a_fire(fog)
  end

  def self.a_vile_attack(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.a_face_target(actor)

    return if CDoom.p_check_sight(actor, actor.value.target) == 0

    CDoom.s_start_sound(actor, CDoom::Sfxenum::SFX_barexp.value)
    CDoom.p_damage_mobj(actor.value.target, actor, actor, 20)
    actor.value.target.value.momz = 1000 * FRACUNIT // actor.value.target.value.info.value.mass

    an = actor.value.angle >> CDoom::ANGLETOFINESHIFT

    fire = actor.value.tracer

    return if fire.null?

    # move the fire between the vile and the player
    fire.value.x = actor.value.target.value.x - CDoom.fixed_mul(24 * FRACUNIT, @@finecosine[an])
    fire.value.y = actor.value.target.value.y - CDoom.fixed_mul(24 * FRACUNIT, @@finesine[an])
    CDoom.p_radius_attack(fire, actor, 70)
  end

  #
  # firing three missiles (bruisers)
  # in three different directions?
  # Doesn't look like it.
  #
  def self.a_fat_raise(actor : CDoom::Mobj*)
    CDoom.a_face_target(actor)
    CDoom.s_start_sound(actor, CDoom::Sfxenum::SFX_manatk.value)
  end

  def self.a_fat_attack1(actor : CDoom::Mobj*)
    CDoom.a_face_target(actor)
    # Change direction  to ...
    actor.value.angle = actor.value.angle &+ CDoom::FATSPREAD
    CDoom.p_spawn_missile(actor, actor.value.target, CDoom::Mobjtype::MT_FATSHOT)

    mo = CDoom.p_spawn_missile(actor, actor.value.target, CDoom::Mobjtype::MT_FATSHOT)
    mo.value.angle = mo.value.angle &+ CDoom::FATSPREAD
    an = mo.value.angle >> CDoom::ANGLETOFINESHIFT
    mo.value.momx = CDoom.fixed_mul(mo.value.info.value.speed, @@finecosine[an])
    mo.value.momy = CDoom.fixed_mul(mo.value.info.value.speed, @@finesine[an])
  end

  def self.a_fat_attack2(actor : CDoom::Mobj*)
    CDoom.a_face_target(actor)
    # Now here choose opposite deviation.
    actor.value.angle = actor.value.angle &- CDoom::FATSPREAD
    CDoom.p_spawn_missile(actor, actor.value.target, CDoom::Mobjtype::MT_FATSHOT)

    mo = CDoom.p_spawn_missile(actor, actor.value.target, CDoom::Mobjtype::MT_FATSHOT)
    mo.value.angle = mo.value.angle &- CDoom::FATSPREAD * 2
    an = mo.value.angle >> CDoom::ANGLETOFINESHIFT
    mo.value.momx = CDoom.fixed_mul(mo.value.info.value.speed, @@finecosine[an])
    mo.value.momy = CDoom.fixed_mul(mo.value.info.value.speed, @@finesine[an])
  end

  def self.a_fat_attack3(actor : CDoom::Mobj*)
    CDoom.a_face_target(actor)

    mo = CDoom.p_spawn_missile(actor, actor.value.target, CDoom::Mobjtype::MT_FATSHOT)
    mo.value.angle = mo.value.angle &- CDoom::FATSPREAD.tdiv(2)
    an = mo.value.angle >> CDoom::ANGLETOFINESHIFT
    mo.value.momx = CDoom.fixed_mul(mo.value.info.value.speed, @@finecosine[an])
    mo.value.momy = CDoom.fixed_mul(mo.value.info.value.speed, @@finesine[an])

    mo = CDoom.p_spawn_missile(actor, actor.value.target, CDoom::Mobjtype::MT_FATSHOT)
    mo.value.angle = mo.value.angle &+ CDoom::FATSPREAD.tdiv(2)
    an = mo.value.angle >> CDoom::ANGLETOFINESHIFT
    mo.value.momx = CDoom.fixed_mul(mo.value.info.value.speed, @@finecosine[an])
    mo.value.momy = CDoom.fixed_mul(mo.value.info.value.speed, @@finesine[an])
  end

  #
  # Fly at the player like a missile
  #
  def self.a_skull_attack(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    dest = actor.value.target
    actor.value.flags = actor.value.flags | CDoom::Mobjflag::MF_SKULLFLY.value

    CDoom.s_start_sound(actor, actor.value.info.value.attacksound)
    CDoom.a_face_target(actor)
    an = actor.value.angle >> CDoom::ANGLETOFINESHIFT
    actor.value.momx = CDoom.fixed_mul(CDoom::SKULLSPEED, @@finecosine[an])
    actor.value.momy = CDoom.fixed_mul(CDoom::SKULLSPEED, @@finesine[an])
    dist = CDoom.p_aprox_distance(dest.value.x - actor.value.x, dest.value.y - actor.value.y)
    dist = dist.tdiv(CDoom::SKULLSPEED)

    dist = 1 if dist < 1
    actor.value.momz = (dest.value.z + (dest.value.height >> 1) - actor.value.z).tdiv(dist)
  end

  def self.a_pain_shoot_skull(actor : CDoom::Mobj*, angle : CDoom::Angle)
    # count total number of skull currently on the level
    count = 0

    currentthinker = CDoom.thinkercap.next
    while currentthinker != pointerof(CDoom.thinkercap)
      if (currentthinker.value.function.acp1.pointer == (->CDoom.p_mobj_thinker).pointer) &&
         currentthinker.as(CDoom::Mobj*).value.type == CDoom::Mobjtype::MT_SKULL
        count += 1
      end
      currentthinker = currentthinker.value.next
    end

    # if there are allready 20 skulls on the level,
    # don't spit another one
    return if count > 20

    # okay, there's playe for another one
    an = angle >> CDoom::ANGLETOFINESHIFT

    prestep = 4 * FRACUNIT +
              3 * (actor.value.info.value.radius + CDoom.mobjinfo[CDoom::Mobjtype::MT_SKULL.value].radius) // 2

    x = actor.value.x + CDoom.fixed_mul(prestep, @@finecosine[an])
    y = actor.value.y + CDoom.fixed_mul(prestep, @@finesine[an])
    z = actor.value.z + 8 * FRACUNIT

    newmobj = CDoom.p_spawn_mobj(x, y, z, CDoom::Mobjtype::MT_SKULL)

    # Check for movements.
    if CDoom.p_try_move(newmobj, newmobj.value.x, newmobj.value.y) == 0
      # kill it immediately
      CDoom.p_damage_mobj(newmobj, actor, actor, 10000)
      return
    end

    newmobj.value.target = actor.value.target
    CDoom.a_skull_attack(newmobj)
  end

  def self.a_pain_attack(actor : CDoom::Mobj*)
    return if actor.value.target.null?

    CDoom.a_face_target(actor)
    CDoom.a_pain_shoot_skull(actor, actor.value.angle)
  end

  def self.a_pain_die(actor : CDoom::Mobj*)
    CDoom.a_fall(actor)
    CDoom.a_pain_shoot_skull(actor, actor.value.angle &+ ANG90)
    CDoom.a_pain_shoot_skull(actor, actor.value.angle &+ ANG180)
    CDoom.a_pain_shoot_skull(actor, actor.value.angle &+ ANG270)
  end

  def self.a_scream(actor : CDoom::Mobj*)
    sound = 0

    case actor.value.info.value.deathsound
    when 0
      return
    when CDoom::Sfxenum::SFX_podth1.value, CDoom::Sfxenum::SFX_podth2.value, CDoom::Sfxenum::SFX_podth3.value
      sound = CDoom::Sfxenum::SFX_podth1.value + CDoom.p_random % 3
    when CDoom::Sfxenum::SFX_bgdth1.value, CDoom::Sfxenum::SFX_bgdth2.value
      sound = CDoom::Sfxenum::SFX_bgdth1.value + CDoom.p_random % 2
    else
      sound = actor.value.info.value.deathsound
    end

    # Check for bosses.
    if actor.value.type == CDoom::Mobjtype::MT_SPIDER ||
       actor.value.type == CDoom::Mobjtype::MT_CYBORG
      # full volume
      CDoom.s_start_sound(Pointer(Void).null, sound)
    else
      CDoom.s_start_sound(actor, sound)
    end
  end

  def self.a_xscream(actor : CDoom::Mobj*)
    CDoom.s_start_sound(actor, CDoom::Sfxenum::SFX_slop.value)
  end

  def self.a_pain(actor : CDoom::Mobj*)
    if actor.value.info.value.painsound != 0
      CDoom.s_start_sound(actor, actor.value.info.value.painsound)
    end
  end

  def self.a_fall(actor : CDoom::Mobj*)
    # actor is on ground, it can be walked over
    actor.value.flags = actor.value.flags & ~CDoom::Mobjflag::MF_SOLID.value

    #  So change this if corpse objects
    # are meant to be obstacles.
  end

  def self.a_explode(thingy : CDoom::Mobj*)
    thingy = thingy.as(CDoom::Mobj*)
    CDoom.p_radius_attack(thingy, thingy.value.target, 128)
  end

  #
  # Possibly trigger special effects
  # if on first boss level
  #
  def self.a_boss_death(mo : CDoom::Mobj*)
    if CDoom.gamemode == CDoom::GameMode::Commercial
      return if CDoom.gamemap != 7

      return if mo.value.type != CDoom::Mobjtype::MT_FATSO &&
                mo.value.type != CDoom::Mobjtype::MT_BABY
    else
      case CDoom.gameepisode
      when 1
        return if CDoom.gamemap != 8
        return if mo.value.type != CDoom::Mobjtype::MT_BRUISER
      when 2
        return if CDoom.gamemap != 8
        return if mo.value.type != CDoom::Mobjtype::MT_CYBORG
      when 3
        return if CDoom.gamemap != 8
        return if mo.value.type != CDoom::Mobjtype::MT_SPIDER
      when 4
        case CDoom.gamemap
        when 6
          return if mo.value.type != CDoom::Mobjtype::MT_CYBORG
        when 8
          return if mo.value.type != CDoom::Mobjtype::MT_SPIDER
        else
          return
        end
      else
        return if CDoom.gamemap != 8
      end
    end

    # make sure there is a player alive for victory
    i = 0
    while i < CDoom::MAXPLAYERS
      break if CDoom.playeringame[i] != 0 && CDoom.players[i].health > 0
      i += 1
    end

    return if i == CDoom::MAXPLAYERS # no one left alive, so do not end game

    # scan the remaining thinkers to see
    # if all bosses are dead
    th = CDoom.thinkercap.next
    while th != pointerof(CDoom.thinkercap)
      if th.value.function.acp1.pointer != (->CDoom.p_mobj_thinker).pointer
        th = th.value.next
        next
      end

      mo2 = th.as(CDoom::Mobj*)
      if mo2 != mo &&
         mo2.value.type == mo.value.type &&
         mo2.value.health > 0
        # other boss not dead
        return
      end

      th = th.value.next
    end

    junk = CDoom::Line.new
    # victory!
    if CDoom.gamemode == CDoom::GameMode::Commercial
      if CDoom.gamemap == 7
        if mo.value.type == CDoom::Mobjtype::MT_FATSO
          junk.tag = 666
          CDoom.ev_do_floor(pointerof(junk), CDoom::Floorenum::LowerFloorToLowest)
          return
        end

        if mo.value.type == CDoom::Mobjtype::MT_BABY
          junk.tag = 667
          CDoom.ev_do_floor(pointerof(junk), CDoom::Floorenum::RaiseToTexture)
          return
        end
      end
    else
      case CDoom.gameepisode
      when 1
        junk.tag = 666
        CDoom.ev_do_floor(pointerof(junk), CDoom::Floorenum::LowerFloorToLowest)
        return
      when 4
        case CDoom.gamemap
        when 6
          junk.tag = 666
          CDoom.ev_do_door(pointerof(junk), CDoom::Vldoorenum::BlazeOpen)
          return
        when 8
          junk.tag = 666
          CDoom.ev_do_floor(pointerof(junk), CDoom::Floorenum::LowerFloorToLowest)
          return
        end
      end
    end

    CDoom.g_exit_level
  end

  def self.a_hoof(mo : CDoom::Mobj*)
    CDoom.s_start_sound(mo, CDoom::Sfxenum::SFX_hoof)
    CDoom.a_chase(mo)
  end

  def self.a_metal(mo : CDoom::Mobj*)
    CDoom.s_start_sound(mo, CDoom::Sfxenum::SFX_metal)
    CDoom.a_chase(mo)
  end

  def self.a_baby_metal(mo : CDoom::Mobj*)
    CDoom.s_start_sound(mo, CDoom::Sfxenum::SFX_bspwlk)
    CDoom.a_chase(mo)
  end

  def self.a_open_shotgun2(player : CDoom::Player*, psp : CDoom::Pspdef*)
    CDoom.s_start_sound(player.value.mo, CDoom::Sfxenum::SFX_dbopn)
  end

  def self.a_load_shotgun2(player : CDoom::Player*, psp : CDoom::Pspdef*)
    CDoom.s_start_sound(player.value.mo, CDoom::Sfxenum::SFX_dbload)
  end

  def self.a_close_shotgun2(player : CDoom::Player*, psp : CDoom::Pspdef*)
    CDoom.s_start_sound(player.value.mo, CDoom::Sfxenum::SFX_dbcls)
    CDoom.a_refire(player, psp)
  end

  def self.a_brain_awake(mo : CDoom::Mobj*)
    # find all the target spots
    CDoom.numbraintargets = 0
    CDoom.braintargeton = 0

    thinker = CDoom.thinkercap.next
    while thinker != pointerof(CDoom.thinkercap)
      if thinker.value.function.acp1.pointer != (->CDoom.p_mobj_thinker).pointer
        thinker = thinker.value.next
        next # not a mobj
      end

      m = thinker.as(CDoom::Mobj*)

      if m.value.type == CDoom::Mobjtype::MT_BOSSTARGET
        (CDoom.braintargets.to_unsafe + CDoom.numbraintargets).value = m
        CDoom.numbraintargets += 1
      end
      thinker = thinker.value.next
    end

    CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_bossit.value)
  end

  def self.a_brain_pain(mo : CDoom::Mobj*)
    CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_bospn)
  end

  def self.a_brain_scream(mo : CDoom::Mobj*)
    x = mo.value.x - 196 * FRACUNIT
    while x < mo.value.x + 320 * FRACUNIT
      y = mo.value.y - 320 * FRACUNIT
      z = 128 + CDoom.p_random * 2 * FRACUNIT
      th = CDoom.p_spawn_mobj(x, y, z, CDoom::Mobjtype::MT_ROCKET)
      th.value.momz = CDoom.p_random * 512

      CDoom.p_set_mobj_state(th, CDoom::Statenum::S_BRAINEXPLODE1)

      th.value.tics = th.value.tics - (CDoom.p_random & 7)
      th.value.tics = 1 if th.value.tics < 1

      x += FRACUNIT * 8
    end

    CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_bosdth)
  end

  def self.a_brain_explode(mo : CDoom::Mobj*)
    x = mo.value.x + (CDoom.p_random - CDoom.p_random) * 2048
    y = mo.value.y
    z = 128 + CDoom.p_random * 2 * FRACUNIT
    th = CDoom.p_spawn_mobj(x, y, z, CDoom::Mobjtype::MT_ROCKET)
    th.value.momz = CDoom.p_random * 512

    CDoom.p_set_mobj_state(th, CDoom::Statenum::S_BRAINEXPLODE1)

    th.value.tics = th.value.tics - (CDoom.p_random & 7)
    th.value.tics = 1 if th.value.tics < 1
  end

  def self.a_brain_die(mo : CDoom::Mobj*)
    CDoom.g_exit_level
  end

  @@easy = 0

  def self.a_brain_spit(mo : CDoom::Mobj*)
    @@easy ^= 1
    return if CDoom.gameskill <= CDoom::Skill::Easy && @@easy == 0

    # shoot a cube at current target
    targ = CDoom.braintargets[CDoom.braintargeton]
    CDoom.braintargeton = (CDoom.braintargeton + 1) % CDoom.numbraintargets

    # spawn brain missile
    newmobj = CDoom.p_spawn_missile(mo, targ, CDoom::Mobjtype::MT_SPAWNSHOT)
    newmobj.value.target = targ
    newmobj.value.reactiontime =
      ((targ.value.y - mo.value.y).tdiv(newmobj.value.momy)).tdiv(newmobj.value.state.value.tics)

    CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_bospit.value)
  end

  # travelling cube sound
  def self.a_spawn_sound(mo : CDoom::Mobj*)
    CDoom.s_start_sound(mo, CDoom::Sfxenum::SFX_boscub.value)
    CDoom.a_spawn_fly(mo)
  end

  def self.a_spawn_fly(mo : CDoom::Mobj*)
    mo.value.reactiontime = mo.value.reactiontime - 1
    return if mo.value.reactiontime != 0 # still flying

    targ = mo.value.target

    # First spawn teleport fog
    fog = CDoom.p_spawn_mobj(targ.value.x, targ.value.y, targ.value.z, CDoom::Mobjtype::MT_SPAWNFIRE)
    CDoom.s_start_sound(fog, CDoom::Sfxenum::SFX_telept.value)

    # Randomly select monster to spawn.
    r = CDoom.p_random

    type = CDoom::Mobjtype::MT_BRUISER
    # Probability distribution (kind of :),
    # decreasing likelihood
    if r < 50
      type = CDoom::Mobjtype::MT_TROOP
    elsif r < 90
      type = CDoom::Mobjtype::MT_SERGEANT
    elsif r < 120
      type = CDoom::Mobjtype::MT_SHADOWS
    elsif r < 130
      type = CDoom::Mobjtype::MT_PAIN
    elsif r < 160
      type = CDoom::Mobjtype::MT_HEAD
    elsif r < 162
      type = CDoom::Mobjtype::MT_VILE
    elsif r < 172
      type = CDoom::Mobjtype::MT_UNDEAD
    elsif r < 192
      type = CDoom::Mobjtype::MT_BABY
    elsif r < 222
      type = CDoom::Mobjtype::MT_FATSO
    elsif r < 246
      type = CDoom::Mobjtype::MT_KNIGHT
    end

    newmobj = CDoom.p_spawn_mobj(targ.value.x, targ.value.y, targ.value.z, type)
    CDoom.p_set_mobj_state(newmobj, CDoom::Statenum.new(newmobj.value.info.value.seestate)) if CDoom.p_look_for_players(newmobj, 1) != 0

    # telefrag anything in this spot
    CDoom.p_teleport_move(newmobj, newmobj.value.x, newmobj.value.y)

    # remove self (i.e., cube).
    CDoom.p_remove_mobj(mo)
  end

  def self.a_player_scream(mo : CDoom::Mobj*)
    # Default death sound.
    sound = CDoom::Sfxenum::SFX_pldeth

    if CDoom.gamemode == CDoom::GameMode::Commercial &&
       mo.value.health < -50
      # IF THE PLAYER DIES
      # LESS THAN -50% WITHOUT GIBBING
      sound = CDoom::Sfxenum::SFX_pdiehi
    end

    CDoom.s_start_sound(mo, sound.value)
  end

  def self.t_move_plane(sector : CDoom::Sector*, speed : CDoom::Fixed, dest : CDoom::Fixed, crush : CDoom::DoomBool, floor_or_ceiling : LibC::Int, direction : LibC::Int) : CDoom::Result
    case floor_or_ceiling
    when 0
      # FLOOR
      case direction
      when -1
        # DOWN
        if sector.value.floorheight - speed < dest
          lastpos = sector.value.floorheight
          sector.value.floorheight = dest
          flag = CDoom.p_change_sector(sector, crush)
          if flag != 0
            sector.value.floorheight = lastpos
            CDoom.p_change_sector(sector, crush)
            # return CDoom::Result::Crushed
          end
          return CDoom::Result::Pastdest
        else
          lastpos = sector.value.floorheight
          sector.value.floorheight = sector.value.floorheight - speed
          flag = CDoom.p_change_sector(sector, crush)
          if flag != 0
            sector.value.floorheight = lastpos
            CDoom.p_change_sector(sector, crush)
            return CDoom::Result::Crushed
          end
        end
      when 1
        # UP
        if sector.value.floorheight + speed > dest
          lastpos = sector.value.floorheight
          sector.value.floorheight = dest
          flag = CDoom.p_change_sector(sector, crush)
          if flag != 0
            sector.value.floorheight = lastpos
            CDoom.p_change_sector(sector, crush)
            # return CDoom::Result::Crushed
          end
          return CDoom::Result::Pastdest
        else
          # COULD GET CRUSHED
          lastpos = sector.value.floorheight
          sector.value.floorheight = sector.value.floorheight + speed
          flag = CDoom.p_change_sector(sector, crush)
          if flag != 0
            return CDoom::Result::Crushed if crush != 0
            sector.value.floorheight = lastpos
            CDoom.p_change_sector(sector, crush)
            return CDoom::Result::Crushed
          end
        end
      end
    when 1
      # CEILING
      case direction
      when -1
        # DOWN
        if sector.value.ceilingheight - speed < dest
          lastpos = sector.value.ceilingheight
          sector.value.ceilingheight = dest
          flag = CDoom.p_change_sector(sector, crush)

          if flag != 0
            sector.value.ceilingheight = lastpos
            CDoom.p_change_sector(sector, crush)
            # return CDoom::Result::Crushed
          end
          return CDoom::Result::Pastdest
        else
          # COULD GET CRUSHED
          lastpos = sector.value.ceilingheight
          sector.value.ceilingheight = sector.value.ceilingheight - speed
          flag = CDoom.p_change_sector(sector, crush)

          if flag != 0
            return CDoom::Result::Crushed if crush != 0
            sector.value.ceilingheight = lastpos
            CDoom.p_change_sector(sector, crush)
            return CDoom::Result::Crushed
          end
        end
      when 1
        # UP
        if sector.value.ceilingheight + speed > dest
          lastpos = sector.value.ceilingheight
          sector.value.ceilingheight = dest
          flag = CDoom.p_change_sector(sector, crush)
          if flag != 0
            sector.value.ceilingheight = lastpos
            CDoom.p_change_sector(sector, crush)
            # return CDoom::Result::Crushed
          end
          return CDoom::Result::Pastdest
        else
          lastpos = sector.value.ceilingheight
          sector.value.ceilingheight = sector.value.ceilingheight + speed
          flag = CDoom.p_change_sector(sector, crush)
          # UNUSED

          # if flag != 0
          #   sector.value.ceilingheight = lastpos
          #   CDoom.p_change_sector(sector, crush)
          #   return CDoom::Result::Crushed
        end
      end
    end

    return CDoom::Result::Ok
  end

  #
  # MOVE A FLOOR TO IT'S DESTINATION (UP OR DOWN)
  #
  def self.t_move_floor(floor : CDoom::Floormove*)
    res = CDoom.t_move_plane(floor.value.sector,
      floor.value.speed,
      floor.value.floordestheight,
      floor.value.crush, 0, floor.value.direction)

    CDoom.s_start_sound(pointerof(floor.value.sector.value.@soundorg),
      CDoom::Sfxenum::SFX_stnmov) if CDoom.leveltime & 7 == 0

    if res == CDoom::Result::Pastdest
      floor.value.sector.value.specialdata = Pointer(Void).null

      if floor.value.direction == 1
        case floor.value.type
        when CDoom::Floorenum::DonutRaise
          floor.value.sector.value.special = floor.value.newspecial
          floor.value.sector.value.floorpic = floor.value.texture
        end
      elsif floor.value.direction == -1
        case floor.value.type
        when CDoom::Floorenum::LowerAndChange
          floor.value.sector.value.special = floor.value.newspecial
          floor.value.sector.value.floorpic = floor.value.texture
        end
      end
      CDoom.p_remove_thinker(pointerof(floor.value.@thinker))

      CDoom.s_start_sound(pointerof(floor.value.sector.value.@soundorg),
        CDoom::Sfxenum::SFX_pstop)
    end
  end

  def self.ev_do_floor(line : CDoom::Line*, floortype : CDoom::Floorenum) : LibC::Int
    secnum = -1
    rtn = 0
    while (secnum = CDoom.p_find_sector_from_line_tag(line, secnum)) >= 0
      sec = CDoom.sectors + secnum

      # ALREADY MOVING?  IF SO, KEEP GOING...
      next unless sec.value.specialdata.null?

      # new floor thinker
      rtn = 1
      floor = CDoom.z_malloc(sizeof(CDoom::Floormove), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Floormove*)
      CDoom.p_add_thinker(pointerof(floor.value.@thinker))
      sec.value.specialdata = floor
      pointerof(floor.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_move_floor).pointer, Pointer(Void).null)
      floor.value.type = floortype
      floor.value.crush = 0

      case floortype
      when CDoom::Floorenum::LowerFloor
        floor.value.direction = -1
        floor.value.sector = sec
        floor.value.speed = CDoom::FLOORSPEED
        floor.value.floordestheight =
          CDoom.p_find_highest_floor_surrounding(sec)
      when CDoom::Floorenum::LowerFloorToLowest
        floor.value.direction = -1
        floor.value.sector = sec
        floor.value.speed = CDoom::FLOORSPEED
        floor.value.floordestheight =
          CDoom.p_find_lowest_floor_surrounding(sec)
      when CDoom::Floorenum::TurboLower
        floor.value.direction = -1
        floor.value.sector = sec
        floor.value.speed = CDoom::FLOORSPEED * 4
        floor.value.floordestheight =
          CDoom.p_find_highest_floor_surrounding(sec)
        if floor.value.floordestheight != sec.value.floorheight
          floor.value.floordestheight = floor.value.floordestheight + 8 * FRACUNIT
        end
      when CDoom::Floorenum::RaiseFloor, CDoom::Floorenum::RaiseFloorCrush
        floor.value.crush = 1 if floortype == CDoom::Floorenum::RaiseFloorCrush
        floor.value.direction = 1
        floor.value.sector = sec
        floor.value.speed = CDoom::FLOORSPEED
        floor.value.floordestheight =
          CDoom.p_find_lowest_ceiling_surrounding(sec)
        if floor.value.floordestheight > sec.value.ceilingheight
          floor.value.floordestheight = sec.value.ceilingheight
        end
        floor.value.floordestheight = floor.value.floordestheight - ((8 * FRACUNIT) * (floortype == CDoom::Floorenum::RaiseFloorCrush).to_unsafe)
      when CDoom::Floorenum::RaiseFloorTurbo
        floor.value.direction = 1
        floor.value.sector = sec
        floor.value.speed = CDoom::FLOORSPEED * 4
        floor.value.floordestheight =
          CDoom.p_find_next_highest_floor(sec, sec.value.floorheight)
      when CDoom::Floorenum::RaiseFloorToNearest
        floor.value.direction = 1
        floor.value.sector = sec
        floor.value.speed = CDoom::FLOORSPEED
        floor.value.floordestheight =
          CDoom.p_find_next_highest_floor(sec, sec.value.floorheight)
      when CDoom::Floorenum::RaiseFloor24
        floor.value.direction = 1
        floor.value.sector = sec
        floor.value.speed = CDoom::FLOORSPEED
        floor.value.floordestheight = floor.value.sector.value.floorheight +
                                      24 * FRACUNIT
      when CDoom::Floorenum::RaiseFloor512
        floor.value.direction = 1
        floor.value.sector = sec
        floor.value.speed = CDoom::FLOORSPEED
        floor.value.floordestheight = floor.value.sector.value.floorheight +
                                      512 * FRACUNIT
      when CDoom::Floorenum::RaiseFloor24AndChange
        floor.value.direction = 1
        floor.value.sector = sec
        floor.value.speed = CDoom::FLOORSPEED
        floor.value.floordestheight = floor.value.sector.value.floorheight +
                                      24 * FRACUNIT
        sec.value.floorpic = line.value.frontsector.value.floorpic
        sec.value.special = line.value.frontsector.value.special
      when CDoom::Floorenum::RaiseToTexture
        minsize = Int32::MAX

        floor.value.direction = 1
        floor.value.sector = sec
        floor.value.speed = CDoom::FLOORSPEED
        sec.value.linecount.times do |i|
          if CDoom.two_sided(secnum, i) != 0
            side = CDoom.get_side(secnum, i, 0)
            if side.value.bottomtexture >= 0
              if CDoom.textureheight[side.value.bottomtexture] < minsize
                minsize = CDoom.textureheight[side.value.bottomtexture]
              end
            end
            side = CDoom.get_side(secnum, i, 1)
            if side.value.bottomtexture >= 0
              if CDoom.textureheight[side.value.bottomtexture] < minsize
                minsize = CDoom.textureheight[side.value.bottomtexture]
              end
            end
          end
        end
        floor.value.floordestheight =
          floor.value.sector.value.floorheight + minsize
      when CDoom::Floorenum::LowerAndChange
        floor.value.direction = -1
        floor.value.sector = sec
        floor.value.speed = CDoom::FLOORSPEED
        floor.value.floordestheight =
          CDoom.p_find_lowest_floor_surrounding(sec)
        floor.value.texture = sec.value.floorpic

        sec.value.linecount.times do |i|
          if CDoom.two_sided(secnum, i) != 0
            if CDoom.get_side(secnum, i, 0).value.sector - CDoom.sectors == secnum
              sec = CDoom.get_sector(secnum, i, 1)

              if sec.value.floorheight == floor.value.floordestheight
                floor.value.texture = sec.value.floorpic
                floor.value.newspecial = sec.value.special
                break
              end
            else
              sec = CDoom.get_sector(secnum, i, 0)

              if sec.value.floorheight == floor.value.floordestheight
                floor.value.texture = sec.value.floorpic
                floor.value.newspecial = sec.value.special
                break
              end
            end
          end
        end
      end
    end

    return rtn
  end

  #
  # BUILD A STAIRCASE!
  #
  def self.ev_build_stairs(line : CDoom::Line*, type : CDoom::Stairenum) : LibC::Int
    secnum = -1
    rtn = 0
    while (secnum = CDoom.p_find_sector_from_line_tag(line, secnum)) >= 0
      sec = CDoom.sectors + secnum

      # ALREADY MOVING?  IF SO, KEEP GOING...
      next unless sec.value.specialdata.null?

      # new floor thinker
      rtn = 1
      floor = CDoom.z_malloc(sizeof(CDoom::Floormove), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Floormove*)
      CDoom.p_add_thinker(pointerof(floor.value.@thinker))
      sec.value.specialdata = floor
      pointerof(floor.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_move_floor).pointer, Pointer(Void).null)
      floor.value.direction = 1
      floor.value.sector = sec
      speed = 0
      stairsize = 0
      case type
      when CDoom::Stairenum::Build8
        speed = CDoom::FLOORSPEED // 4
        stairsize = 8 * FRACUNIT
      when CDoom::Stairenum::Turbo16
        speed = CDoom::FLOORSPEED * 4
        stairsize = 16 * FRACUNIT
      end
      floor.value.speed = speed
      height = sec.value.floorheight + stairsize
      floor.value.floordestheight = height

      texture = sec.value.floorpic
      # Find next sector to raise
      # 1.        Find 2-sided line with same sector side[0]
      # 2.        Other side is the next sector to raise
      loop do
        ok = 0
        sec.value.linecount.times do |i|
          next if ((sec.value.lines[i]).value.flags & CDoom::ML_TWOSIDED) == 0

          tsec = (sec.value.lines[i]).value.frontsector
          newsecnum = (tsec - CDoom.sectors).to_i32!

          next if secnum != newsecnum

          tsec = (sec.value.lines[i]).value.backsector
          newsecnum = (tsec - CDoom.sectors).to_i32!

          next if tsec.value.floorpic != texture

          height += stairsize

          next unless tsec.value.specialdata.null?

          sec = tsec
          secnum = newsecnum
          floor = CDoom.z_malloc(sizeof(CDoom::Floormove), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Floormove*)

          CDoom.p_add_thinker(pointerof(floor.value.@thinker))

          sec.value.specialdata = floor
          pointerof(floor.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_move_floor).pointer, Pointer(Void).null)
          floor.value.direction = 1
          floor.value.sector = sec
          floor.value.speed = speed
          floor.value.floordestheight = height
          ok = 1
          break
        end
        break unless ok != 0
      end
    end
    return rtn
  end

  #
  # GET STUFF
  #

  #
  # Num is the number of clip loads,
  # not the individual count (0= 1/2 clip).
  # Returns false if the ammo can't be picked up at all
  #
  def self.p_give_ammo(player : CDoom::Player*, ammo : CDoom::Ammotype, num : LibC::Int) : CDoom::DoomBool
    return 0 if ammo == CDoom::Ammotype::Noammo

    if ammo.value < 0 || ammo.value > CDoom::Ammotype::NUMAMMO.value
      CDoom.i_error("p_give_ammo: bad type #{ammo}")
    end

    return 0 if player.value.ammo[ammo.value] == player.value.maxammo[ammo.value]

    if num != 0
      num *= CDoom.clipammo[ammo.value]
    else
      num = CDoom.clipammo[ammo.value] // 2
    end

    if CDoom.gameskill == CDoom::Skill::Baby ||
       CDoom.gameskill == CDoom::Skill::Nightmare
      # give double ammo in trainer mode,
      # you'll need in nightmare
      num <<= 1
    end

    oldammo = player.value.ammo[ammo.value]
    (player.value.ammo.to_unsafe + ammo.value).value = player.value.ammo[ammo.value] + num

    (player.value.ammo.to_unsafe + ammo.value).value = player.value.maxammo[ammo.value] if player.value.ammo[ammo.value] > player.value.maxammo[ammo.value]

    # If non zero ammo,
    # don't change up weapons,
    # player was lower on purpose.
    return 1 if oldammo != 0

    # We were down to zero,
    # so select a new weapon.
    # Preferences are not user selectable.
    case ammo
    when CDoom::Ammotype::Clip
      if player.value.readyweapon == CDoom::Weapontype::Fist
        if player.value.weaponowned[CDoom::Weapontype::Chaingun.value] != 0
          player.value.pendingweapon = CDoom::Weapontype::Chaingun
        else
          player.value.pendingweapon = CDoom::Weapontype::Pistol
        end
      end
    when CDoom::Ammotype::Shell
      if player.value.readyweapon == CDoom::Weapontype::Fist ||
         player.value.readyweapon == CDoom::Weapontype::Pistol
        if player.value.weaponowned[CDoom::Weapontype::Shotgun.value] != 0
          player.value.pendingweapon = CDoom::Weapontype::Shotgun
        end
      end
    when CDoom::Ammotype::Cell
      if player.value.readyweapon == CDoom::Weapontype::Fist ||
         player.value.readyweapon == CDoom::Weapontype::Pistol
        if player.value.weaponowned[CDoom::Weapontype::Plasma.value] != 0
          player.value.pendingweapon = CDoom::Weapontype::Plasma
        end
      end
    when CDoom::Ammotype::Misl
      if player.value.readyweapon == CDoom::Weapontype::Fist
        if player.value.weaponowned[CDoom::Weapontype::Missile.value] != 0
          player.value.pendingweapon = CDoom::Weapontype::Missile
        end
      end
    end
    return 1
  end

  #
  # The weapon name may have a MF_DROPPED flag ored in.
  #
  def self.p_give_weapon(player : CDoom::Player*, weapon : CDoom::Weapontype, dropped : CDoom::DoomBool) : CDoom::DoomBool
    gaveammo = 0
    gaveweapon = 0

    if CDoom.netgame != 0 &&
       CDoom.deathmatch != 2 &&
       dropped == 0
      # leave placed weapons forever on net games
      return 0 if player.value.weaponowned[weapon.value] != 0

      player.value.bonuscount = player.value.bonuscount + CDoom::BONUSADD
      player.value.weaponowned[weapon.value] = 1

      if CDoom.deathmatch != 0
        CDoom.p_give_ammo(player, CDoom.weaponinfo[weapon.value].ammo, 5)
      else
        CDoom.p_give_ammo(player, CDoom.weaponinfo[weapon.value].ammo, 2)
      end
      player.value.pendingweapon = weapon

      if player == CDoom.players.to_unsafe + CDoom.consoleplayer
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_wpnup)
      end
      return 0
    end

    if CDoom.weaponinfo[weapon.value].ammo != CDoom::Ammotype::Noammo
      # give one clip with a dropped weapon,
      # two clips with a found weapon
      if dropped != 0
        gaveammo = CDoom.p_give_ammo(player, CDoom.weaponinfo[weapon.value].ammo, 1)
      else
        gaveammo = CDoom.p_give_ammo(player, CDoom.weaponinfo[weapon.value].ammo, 2)
      end
    else
      gaveammo = 0
    end

    if player.value.weaponowned[weapon.value] != 0
      gaveweapon = 0
    else
      gaveweapon = 1
      player.value.weaponowned[weapon.value] = 1
      player.value.pendingweapon = weapon
    end

    return (gaveweapon != 0 || gaveammo != 0).to_unsafe
  end

  #
  # Returns false if the body isn't needed at all
  #
  def self.p_give_body(player : CDoom::Player*, num : LibC::Int) : CDoom::DoomBool
    return 0 if player.value.health >= CDoom::MAXHEALTH

    player.value.health = player.value.health + num
    player.value.health = CDoom::MAXHEALTH if player.value.health > CDoom::MAXHEALTH
    player.value.mo.value.health = player.value.health

    return 1
  end

  #
  # Returns false if the armor is worse
  # than the current armor.
  #
  def self.p_give_armor(player : CDoom::Player*, armortype : LibC::Int) : CDoom::DoomBool
    hits = armortype*100
    return 0 if player.value.armorpoints >= hits # don't pick up
    player.value.armortype = armortype
    player.value.armorpoints = hits

    return 1
  end

  def self.p_give_card(player : CDoom::Player*, card : CDoom::Card)
    return if player.value.cards[card.value] != 0

    player.value.bonuscount = CDoom::BONUSADD
    player.value.cards[card.value] = 1
  end

  def self.p_give_power(player : CDoom::Player*, power : LibC::Int) : CDoom::DoomBool
    if power == CDoom::Powertype::Invulnerability.value
      player.value.powers[power] = CDoom::Powerduration::INVULNTICS.value
      return 1
    end

    if power == CDoom::Powertype::Invisibility.value
      player.value.powers[power] = CDoom::Powerduration::INVISTICS.value
      player.value.mo.value.flags = player.value.mo.value.flags | CDoom::Mobjflag::MF_SHADOW.value
      return 1
    end

    if power == CDoom::Powertype::Infrared.value
      player.value.powers[power] = CDoom::Powerduration::INFRATICS.value
      return 1
    end

    if power == CDoom::Powertype::Ironfeet.value
      player.value.powers[power] = CDoom::Powerduration::IRONTICS.value
      return 1
    end

    if power == CDoom::Powertype::Strength.value
      CDoom.p_give_body(player, 100)
      player.value.powers[power] = 1
      return 1
    end

    return 0 if player.value.powers[power] != 0 # already got it

    player.value.powers[power] = 1
    return 1
  end

  def self.p_touch_special_thing(special : CDoom::Mobj*, toucher : CDoom::Mobj*)
    delta = special.value.z - toucher.value.z

    if delta > toucher.value.height ||
       delta < -8*FRACUNIT
      # out of reach
      return
    end

    sound = CDoom::Sfxenum::SFX_itemup
    player = toucher.value.player

    # Dead thing touching.
    # Can happen with a sliding player corpse.
    return if toucher.value.health <= 0

    # Identify by sprite
    case special.value.sprite
    # armor
    when CDoom::Spritenum::SPR_ARM1
      return if CDoom.p_give_armor(player, @@deh_green_armor_class) == 0
      player.value.message = @@deh_gotarmor
    when CDoom::Spritenum::SPR_ARM2
      return if CDoom.p_give_armor(player, @@deh_blue_armor_class) == 0
      player.value.message = @@deh_gotmega

      # bonus items
    when CDoom::Spritenum::SPR_BON1
      player.value.health = player.value.health + 1 # can go over 100%
      player.value.health = @@deh_max_health if player.value.health > @@deh_max_health
      player.value.mo.value.health = player.value.health
      player.value.message = @@deh_goththbonus
    when CDoom::Spritenum::SPR_BON2
      player.value.armorpoints = player.value.armorpoints + 1 # can go over 100%
      player.value.armorpoints = @@deh_max_armor if player.value.armorpoints > @@deh_max_armor
      player.value.armortype = 1 if player.value.armortype == 0
      player.value.message = @@deh_gotarmbonus
    when CDoom::Spritenum::SPR_SOUL
      player.value.health = player.value.health + @@deh_soulsphere_health
      player.value.health = @@deh_max_soulsphere if player.value.health > @@deh_max_soulsphere
      player.value.mo.value.health = player.value.health
      player.value.message = @@deh_gotsuper
      sound = CDoom::Sfxenum::SFX_getpow
    when CDoom::Spritenum::SPR_MEGA
      return if CDoom.gamemode != CDoom::GameMode::Commercial
      player.value.health = @@deh_megasphere_health
      player.value.mo.value.health = player.value.health
      CDoom.p_give_armor(player, 2)
      player.value.message = @@deh_gotmsphere
      sound = CDoom::Sfxenum::SFX_getpow

      # card
      # leave cards for everyone
    when CDoom::Spritenum::SPR_BKEY
      if player.value.cards[CDoom::Card::Bluecard.value] == 0
        player.value.message = @@deh_gotbluecard
      end
      CDoom.p_give_card(player, CDoom::Card::Bluecard)
      return if CDoom.netgame != 0
    when CDoom::Spritenum::SPR_YKEY
      if player.value.cards[CDoom::Card::Yellowcard.value] == 0
        player.value.message = @@deh_gotyelwcard
      end
      CDoom.p_give_card(player, CDoom::Card::Yellowcard)
      return if CDoom.netgame != 0
    when CDoom::Spritenum::SPR_RKEY
      if player.value.cards[CDoom::Card::Redcard.value] == 0
        player.value.message = @@deh_gotredcard
      end
      CDoom.p_give_card(player, CDoom::Card::Redcard)
      return if CDoom.netgame != 0
    when CDoom::Spritenum::SPR_BSKU
      if player.value.cards[CDoom::Card::Blueskull.value] == 0
        player.value.message = @@deh_gotblueskul
      end
      CDoom.p_give_card(player, CDoom::Card::Blueskull)
      return if CDoom.netgame != 0
    when CDoom::Spritenum::SPR_RSKU
      if player.value.cards[CDoom::Card::Redskull.value] == 0
        player.value.message = @@deh_gotredskull
      end
      CDoom.p_give_card(player, CDoom::Card::Redskull)
      return if CDoom.netgame != 0
    when CDoom::Spritenum::SPR_YSKU
      if player.value.cards[CDoom::Card::Yellowskull.value] == 0
        player.value.message = @@deh_gotyelwskul
      end
      CDoom.p_give_card(player, CDoom::Card::Yellowskull)
      return if CDoom.netgame != 0

      # medikits, heals
    when CDoom::Spritenum::SPR_STIM
      return if CDoom.p_give_body(player, 10) == 0
      player.value.message = @@deh_gotstim
    when CDoom::Spritenum::SPR_MEDI
      return if CDoom.p_give_body(player, 25) == 0

      if (player.value.health - 25) < 25
        player.value.message = @@deh_gotmedineed
      else
        player.value.message = @@deh_gotmedikit
      end
    when CDoom::Spritenum::SPR_PINV
      return if CDoom.p_give_power(player, CDoom::Powertype::Invulnerability.value) == 0
      player.value.message = @@deh_gotinvul
      sound = CDoom::Sfxenum::SFX_getpow
    when CDoom::Spritenum::SPR_PSTR
      return if CDoom.p_give_power(player, CDoom::Powertype::Strength.value) == 0
      player.value.message = @@deh_gotberserk
      player.value.pendingweapon = CDoom::Weapontype::Fist if player.value.readyweapon != CDoom::Weapontype::Fist
      sound = CDoom::Sfxenum::SFX_getpow
    when CDoom::Spritenum::SPR_PINS
      return if CDoom.p_give_power(player, CDoom::Powertype::Invisibility.value) == 0
      player.value.message = @@deh_gotinvis
      sound = CDoom::Sfxenum::SFX_getpow
    when CDoom::Spritenum::SPR_SUIT
      return if CDoom.p_give_power(player, CDoom::Powertype::Ironfeet.value) == 0
      player.value.message = @@deh_gotsuit
      sound = CDoom::Sfxenum::SFX_getpow
    when CDoom::Spritenum::SPR_PMAP
      return if CDoom.p_give_power(player, CDoom::Powertype::Allmap.value) == 0
      player.value.message = @@deh_gotmap
      sound = CDoom::Sfxenum::SFX_getpow
    when CDoom::Spritenum::SPR_PVIS
      return if CDoom.p_give_power(player, CDoom::Powertype::Infrared.value) == 0
      player.value.message = @@deh_gotvisor
      sound = CDoom::Sfxenum::SFX_getpow

      # ammo
    when CDoom::Spritenum::SPR_CLIP
      if special.value.flags & CDoom::Mobjflag::MF_DROPPED.value != 0
        return if CDoom.p_give_ammo(player, CDoom::Ammotype::Clip, 0) == 0
      else
        return if CDoom.p_give_ammo(player, CDoom::Ammotype::Clip, 1) == 0
      end
      player.value.message = @@deh_gotclip
    when CDoom::Spritenum::SPR_AMMO
      return if CDoom.p_give_ammo(player, CDoom::Ammotype::Clip, 5) == 0
      player.value.message = @@deh_gotclipbox
    when CDoom::Spritenum::SPR_ROCK
      return if CDoom.p_give_ammo(player, CDoom::Ammotype::Misl, 1) == 0
      player.value.message = @@deh_gotrocket
    when CDoom::Spritenum::SPR_BROK
      return if CDoom.p_give_ammo(player, CDoom::Ammotype::Misl, 5) == 0
      player.value.message = @@deh_gotrockbox
    when CDoom::Spritenum::SPR_CELL
      return if CDoom.p_give_ammo(player, CDoom::Ammotype::Cell, 1) == 0
      player.value.message = @@deh_gotcell
    when CDoom::Spritenum::SPR_CELP
      return if CDoom.p_give_ammo(player, CDoom::Ammotype::Cell, 5) == 0
      player.value.message = @@deh_gotcellbox
    when CDoom::Spritenum::SPR_SHEL
      return if CDoom.p_give_ammo(player, CDoom::Ammotype::Shell, 1) == 0
      player.value.message = @@deh_gotshells
    when CDoom::Spritenum::SPR_SBOX
      return if CDoom.p_give_ammo(player, CDoom::Ammotype::Shell, 5) == 0
      player.value.message = @@deh_gotshellbox
    when CDoom::Spritenum::SPR_BPAK
      if player.value.backpack == 0
        CDoom::Ammotype::NUMAMMO.value.times do |i|
          player.value.maxammo[i] = player.value.maxammo[i] * 2
        end
        player.value.backpack = 1
      end
      CDoom::Ammotype::NUMAMMO.value.times do |i|
        CDoom.p_give_ammo(player, CDoom::Ammotype.new(i), 1)
      end
      player.value.message = @@deh_gotbackpack

      # weapons
    when CDoom::Spritenum::SPR_BFUG
      return if CDoom.p_give_weapon(player, CDoom::Weapontype::Bfg, 0) == 0
      player.value.message = @@deh_gotbfg9000
      sound = CDoom::Sfxenum::SFX_wpnup
    when CDoom::Spritenum::SPR_MGUN
      return if CDoom.p_give_weapon(player, CDoom::Weapontype::Chaingun, (special.value.flags & CDoom::Mobjflag::MF_DROPPED.value != 0).to_unsafe) == 0
      player.value.message = @@deh_gotchaingun
      sound = CDoom::Sfxenum::SFX_wpnup
    when CDoom::Spritenum::SPR_CSAW
      return if CDoom.p_give_weapon(player, CDoom::Weapontype::Chainsaw, 0) == 0
      player.value.message = @@deh_gotchainsaw
      sound = CDoom::Sfxenum::SFX_wpnup
    when CDoom::Spritenum::SPR_LAUN
      return if CDoom.p_give_weapon(player, CDoom::Weapontype::Missile, 0) == 0
      player.value.message = @@deh_gotlauncher
      sound = CDoom::Sfxenum::SFX_wpnup
    when CDoom::Spritenum::SPR_PLAS
      return if CDoom.p_give_weapon(player, CDoom::Weapontype::Plasma, 0) == 0
      player.value.message = @@deh_gotplasma
      sound = CDoom::Sfxenum::SFX_wpnup
    when CDoom::Spritenum::SPR_SHOT
      return if CDoom.p_give_weapon(player, CDoom::Weapontype::Shotgun, (special.value.flags & CDoom::Mobjflag::MF_DROPPED.value != 0).to_unsafe) == 0
      player.value.message = @@deh_gotshotgun
      sound = CDoom::Sfxenum::SFX_wpnup
    when CDoom::Spritenum::SPR_SGN2
      return if CDoom.p_give_weapon(player, CDoom::Weapontype::Supershotgun, (special.value.flags & CDoom::Mobjflag::MF_DROPPED.value != 0).to_unsafe) == 0
      player.value.message = @@deh_gotshotgun2
      sound = CDoom::Sfxenum::SFX_wpnup
    else
      CDoom.i_error("p_special_thing: Unknown gettable thing")
    end

    player.value.itemcount = player.value.itemcount + 1 if special.value.flags & CDoom::Mobjflag::MF_COUNTITEM.value != 0
    CDoom.p_remove_mobj(special)
    player.value.bonuscount = player.value.bonuscount + CDoom::BONUSADD
    CDoom.s_start_sound(Pointer(Void).null, sound.value) if player == CDoom.players.to_unsafe + CDoom.consoleplayer
  end

  def self.p_kill_mobj(source : CDoom::Mobj*, target : CDoom::Mobj*)
    target.value.flags = target.value.flags & ~(CDoom::Mobjflag::MF_SHOOTABLE.value | CDoom::Mobjflag::MF_FLOAT.value | CDoom::Mobjflag::MF_SKULLFLY.value)

    target.value.flags = target.value.flags & ~CDoom::Mobjflag::MF_NOGRAVITY.value if target.value.type != CDoom::Mobjtype::MT_SKULL

    target.value.flags = target.value.flags | (CDoom::Mobjflag::MF_CORPSE.value | CDoom::Mobjflag::MF_DROPOFF.value)
    target.value.height = target.value.height >> 2

    if !source.null? && !source.value.player.null?
      # count for intermission
      source.value.player.value.killcount = source.value.player.value.killcount + 1 if target.value.flags & CDoom::Mobjflag::MF_COUNTKILL.value != 0

      if !target.value.player.null?
        unless CDoom.netgame == 0
          srcplr = source.value.player - CDoom.players.to_unsafe
          trgtplr = target.value.player - CDoom.players.to_unsafe
          source.value.player.value.frags[trgtplr] =
            source.value.player.value.frags[trgtplr] + 1

          if srcplr == trgtplr
            # Suicide
            strings = CDoom.consoleplayer == srcplr ? @@suic_strings : @@suic_see_strings
          else
            strings = CDoom.deathmatch != 0 ? # Deathmatch strings
(CDoom.consoleplayer == srcplr ? @@death_kill_strings : (
              CDoom.consoleplayer == trgtplr ? @@death_dead_strings : @@death_nut_strings
            ) # Coop strings
) : CDoom.consoleplayer == srcplr ? @@net_kill_strings : (
              CDoom.consoleplayer == trgtplr ? @@net_dead_strings : @@net_nut_strings
            )
          end

          (CDoom.players.to_unsafe + CDoom.consoleplayer).value.message =
            strings.sample(Random.new(CDoom.m_random)).gsub(
              '1', String.new(CDoom.player_names[srcplr])[...-2]).gsub(
              '2', String.new(CDoom.player_names[trgtplr])[...-2])
        end
      end
    elsif CDoom.netgame == 0 && target.value.flags & CDoom::Mobjflag::MF_COUNTKILL.value != 0
      # count all monster deaths,
      # even those caused by other monsters
      CDoom.players.to_unsafe.value.killcount = CDoom.players[0].killcount + 1
    end

    if !target.value.player.null?
      if source.null? || source.value.player.null? &&                         # Player was not killed by player
         target.value.player - CDoom.players.to_unsafe != CDoom.consoleplayer # Isn't self. They know they died
        (CDoom.players.to_unsafe + CDoom.consoleplayer).value.message =
          @@died_strings.sample(Random.new(CDoom.m_random)).gsub(
            '1', String.new(CDoom.player_names[target.value.player - CDoom.players.to_unsafe])[...-2])
      end

      # count environment kills against you
      target.value.player.value.frags[target.value.player - CDoom.players.to_unsafe] =
        target.value.player.value.frags[target.value.player - CDoom.players.to_unsafe] + 1 if source.null?

      target.value.flags = target.value.flags & ~CDoom::Mobjflag::MF_SOLID.value
      target.value.player.value.playerstate = CDoom::Playerstate::PST_DEAD
      CDoom.p_drop_weapon(target.value.player)

      if target.value.player == CDoom.players.to_unsafe + CDoom.consoleplayer &&
         CDoom.automapactive != 0
        # don't die in automap,
        # siwtch view prior to dying
        CDoom.am_stop
      end
    end

    if target.value.health < -target.value.info.value.spawnhealth &&
       target.value.info.value.xdeathstate != 0
      CDoom.p_set_mobj_state(target, CDoom::Statenum.new(target.value.info.value.xdeathstate))
    else
      CDoom.p_set_mobj_state(target, CDoom::Statenum.new(target.value.info.value.deathstate))
    end

    target.value.tics = target.value.tics - (CDoom.p_random & 3)

    target.value.tics = 1 if target.value.tics < 1

    item = CDoom::Mobjtype::MT_CLIP
    # Drop stuff.
    # This determines the kind of object spawned
    # during the death frame of a thing.
    case target.value.type
    when CDoom::Mobjtype::MT_WOLFSS, CDoom::Mobjtype::MT_POSSESSED
      item = CDoom::Mobjtype::MT_CLIP
    when CDoom::Mobjtype::MT_SHOTGUY
      item = CDoom::Mobjtype::MT_SHOTGUN
    when CDoom::Mobjtype::MT_CHAINGUY
      item = CDoom::Mobjtype::MT_CHAINGUN
    else
      return
    end

    mo = CDoom.p_spawn_mobj(target.value.x, target.value.y, CDoom::ONFLOORZ, item)

    mo.value.flags = mo.value.flags | CDoom::Mobjflag::MF_DROPPED.value # special versions of items
  end

  #
  # Damages both enemies and players
  # "inflictor" is the thing that caused the damage
  #  creature or missile, can be 0 (slime, etc)
  # "source" is the thing to target after taking damage
  #  creature or 0
  # Source and inflictor are the same for melee attacks.
  # Source can be 0 for slime, barrel explosions
  # and other environmental stuff.
  #
  def self.p_damage_mobj(target : CDoom::Mobj*, inflictor : CDoom::Mobj*, source : CDoom::Mobj*, damage : LibC::Int)
    return if target.value.flags & CDoom::Mobjflag::MF_SHOOTABLE.value == 0 # shouldn't happen...

    return if target.value.health <= 0

    if target.value.flags & CDoom::Mobjflag::MF_SKULLFLY.value != 0
      target.value.momx = 0
      target.value.momy = 0
      target.value.momz = 0
    end

    damage <<= 1 if !source.null? &&
                    !source.value.player.null? &&
                    source.value.player.value.cheats & CDoom::Cheat::CF_ME.value != 0 # Double damage in me mode!

    player = target.value.player
    damage >>= 1 if !player.null? && CDoom.gameskill == CDoom::Skill::Baby # take half damage in trainer mode

    # Some close combat weapons should not
    # inflict thrust and push the victim out of reach,
    # thus kick away unless using the chainsaw.
    if !inflictor.null? &&
       target.value.flags & CDoom::Mobjflag::MF_NOCLIP.value == 0 &&
       (source.null? ||
       source.value.player.null? ||
       source.value.player.value.readyweapon != CDoom::Weapontype::Chainsaw)
      ang = CDoom.r_point_to_angle2(inflictor.value.x,
        inflictor.value.y,
        target.value.x,
        target.value.y)

      thrust = damage*(FRACUNIT >> 3) &* 100.tdiv(target.value.info.value.mass)

      # make fall forwards sometimes
      if damage < 40 &&
         damage > target.value.health &&
         target.value.z - inflictor.value.z > 64*FRACUNIT &&
         (CDoom.p_random & 1) != 0
        ang &+= ANG180
        thrust *= 4
      end

      ang >>= CDoom::ANGLETOFINESHIFT
      target.value.momx = target.value.momx + CDoom.fixed_mul(thrust, @@finecosine[ang])
      target.value.momy = target.value.momy + CDoom.fixed_mul(thrust, @@finesine[ang])
    end

    # player specific
    if !player.null?
      # end of game hell hack
      if target.value.subsector.value.sector.value.special == 11 &&
         damage >= target.value.health
        damage = target.value.health - 1
      end

      # Below certain threshold,
      # ignore damage in GOD mode, or with INVUL power.
      if damage < 1000 &&
         (player.value.cheats & CDoom::Cheat::CF_GODMODE.value != 0 ||
         player.value.powers[CDoom::Powertype::Invulnerability.value] != 0)
        return
      end

      if player.value.armortype != 0
        saved = damage//2
        saved = damage//3 if player.value.armortype == 1

        if player.value.armorpoints <= saved
          # armor is used up
          saved = player.value.armorpoints
          player.value.armortype = 0
        end

        player.value.armorpoints = player.value.armorpoints - saved
        damage -= saved
      end
      player.value.health = player.value.health - damage # mirror mobj health here for Dave
      player.value.health = 0 if player.value.health < 0

      player.value.attacker = source
      player.value.damagecount = player.value.damagecount + damage # add damage after armor / invuln

      player.value.damagecount = 100 if player.value.damagecount > 100 # teleport does 10k points...

      temp = damage < 100 ? damage : 100

      if player == CDoom.players.to_unsafe + CDoom.consoleplayer
        CDoom.i_tactile(40, 10, 40 + temp*2)
      end
    end

    # do the damage
    target.value.health = target.value.health - damage
    if target.value.health <= 0
      CDoom.p_kill_mobj(source, target)
      return
    end

    if CDoom.p_random < target.value.info.value.painchance &&
       target.value.flags & CDoom::Mobjflag::MF_SKULLFLY.value == 0
      target.value.flags = target.value.flags | CDoom::Mobjflag::MF_JUSTHIT.value # fight back!

      CDoom.p_set_mobj_state(target, CDoom::Statenum.new(target.value.info.value.painstate))
    end

    target.value.reactiontime = 0 # we're awake now...

    if (target.value.threshold == 0 || target.value.type == CDoom::Mobjtype::MT_VILE) &&
       !source.null? && source != target && source.value.type != CDoom::Mobjtype::MT_VILE
      # if not intent on another player,
      # chase after this one
      target.value.target = source
      target.value.threshold = CDoom::BASETHRESHOLD
      if target.value.state == CDoom.states + target.value.info.value.spawnstate &&
         target.value.info.value.seestate != CDoom::Statenum::S_NULL.value
        CDoom.p_set_mobj_state(target, CDoom::Statenum.new(target.value.info.value.seestate))
      end
    end
  end

  def self.t_fire_flicker(flick : CDoom::Fireflicker*)
    flick.value.count = flick.value.count - 1
    return if flick.value.count != 0

    amount = (CDoom.p_random & 3) * 16

    if flick.value.sector.value.lightlevel - amount < flick.value.minlight
      flick.value.sector.value.lightlevel = flick.value.minlight
    else
      flick.value.sector.value.lightlevel = flick.value.maxlight - amount
    end

    flick.value.count = 4
  end

  def self.p_spawn_fire_flicker(sector : CDoom::Sector*)
    # Note that we are resetting sector attributes.
    # Nothing special about it during gameplay.
    sector.value.special = 0

    flick = CDoom.z_malloc(sizeof(CDoom::Fireflicker), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Fireflicker*)

    CDoom.p_add_thinker(pointerof(flick.value.@thinker))

    pointerof(flick.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_fire_flicker).pointer, Pointer(Void).null)
    flick.value.sector = sector
    flick.value.maxlight = sector.value.lightlevel
    flick.value.minlight = CDoom.p_find_min_surrounding_light(sector, sector.value.lightlevel) + 16
    flick.value.count = 4
  end

  #
  # BROKEN LIGHT FLASHING
  #

  #
  # Do flashing lights.
  #
  def self.t_light_flash(flash : CDoom::Lightflash*)
    flash.value.count = flash.value.count - 1
    return if flash.value.count != 0

    if flash.value.sector.value.lightlevel == flash.value.maxlight
      flash.value.sector.value.lightlevel = flash.value.minlight
      flash.value.count = (CDoom.p_random & flash.value.mintime) + 1
    else
      flash.value.sector.value.lightlevel = flash.value.maxlight
      flash.value.count = (CDoom.p_random & flash.value.maxtime) + 1
    end
  end

  #
  # After the map has been loaded, scan each sector
  # for specials that spawn thinkers
  #
  def self.p_spawn_light_flash(sector : CDoom::Sector*)
    # Nothing special about it during gameplay.
    sector.value.special = 0

    flash = CDoom.z_malloc(sizeof(CDoom::Lightflash), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Lightflash*)

    CDoom.p_add_thinker(pointerof(flash.value.@thinker))

    pointerof(flash.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_light_flash).pointer, Pointer(Void).null)
    flash.value.sector = sector
    flash.value.maxlight = sector.value.lightlevel

    flash.value.minlight = CDoom.p_find_min_surrounding_light(sector, sector.value.lightlevel)
    flash.value.maxtime = 64
    flash.value.mintime = 7
    flash.value.count = (CDoom.p_random & flash.value.maxtime) + 1
  end

  #
  # STROBE LIGHT FLASHING
  #

  def self.t_strobe_flash(flash : CDoom::Strobe*)
    flash.value.count = flash.value.count - 1
    return if flash.value.count != 0

    if flash.value.sector.value.lightlevel == flash.value.minlight
      flash.value.sector.value.lightlevel = flash.value.maxlight
      flash.value.count = flash.value.brighttime
    else
      flash.value.sector.value.lightlevel = flash.value.minlight
      flash.value.count = flash.value.darktime
    end
  end

  #
  # After the map has been loaded, scan each sector
  # for specials that spawn thinkers
  #
  def self.p_spawn_strobe_flash(sector : CDoom::Sector*, fast_or_slow : LibC::Int, in_sync : LibC::Int)
    flash = CDoom.z_malloc(sizeof(CDoom::Strobe), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Strobe*)

    CDoom.p_add_thinker(pointerof(flash.value.@thinker))

    flash.value.sector = sector
    flash.value.darktime = fast_or_slow
    flash.value.brighttime = CDoom::STROBEBRIGHT
    pointerof(flash.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_strobe_flash).pointer, Pointer(Void).null)
    flash.value.maxlight = sector.value.lightlevel
    flash.value.minlight = CDoom.p_find_min_surrounding_light(sector, sector.value.lightlevel)

    flash.value.minlight = 0 if flash.value.minlight == flash.value.maxlight

    # nothing special about it during gameplay
    sector.value.special = 0

    if in_sync == 0
      flash.value.count = (CDoom.p_random & 7) + 1
    else
      flash.value.count = 1
    end
  end

  #
  # Start strobing lights (usually from a trigger)
  #
  def self.ev_start_light_strobing(line : CDoom::Line*)
    secnum = -1
    while (secnum = CDoom.p_find_sector_from_line_tag(line, secnum)) >= 0
      sec = CDoom.sectors + secnum
      next if !sec.value.specialdata.null?

      CDoom.p_spawn_strobe_flash(sec, CDoom::SLOWDARK, 0)
    end
  end

  #
  # TURN LINE'S TAG LIGHTS OFF
  #
  def self.ev_turn_tag_lights_off(line : CDoom::Line*)
    sector = CDoom.sectors

    CDoom.numsectors.times do |j|
      if sector.value.tag == line.value.tag
        min = sector.value.lightlevel
        sector.value.linecount.times do |i|
          templine = sector.value.lines[i]
          tsec = CDoom.get_next_sector(templine, sector)
          next if tsec.null?
          min = tsec.value.lightlevel if tsec.value.lightlevel < min
        end
        sector.value.lightlevel = min
      end
      sector += 1
    end
  end

  def self.ev_light_turn_on(line : CDoom::Line*, bright : LibC::Int)
    sector = CDoom.sectors

    CDoom.numsectors.times do |j|
      if sector.value.tag == line.value.tag
        # bright = 0 means to search
        # for highest light level
        # surrounding sector
        if bright == 0
          sector.value.linecount.times do |i|
            templine = sector.value.lines[i]
            temp = CDoom.get_next_sector(templine, sector)
            next if temp.null?
            bright = temp.value.lightlevel if temp.value.lightlevel > bright
          end
        end
        sector.value.lightlevel = bright
      end
      sector += 1
    end
  end

  def self.t_glow(g : CDoom::Glow*)
    case g.value.direction
    when -1
      # DOWN
      g.value.sector.value.lightlevel = g.value.sector.value.lightlevel - CDoom::GLOWSPEED
      if g.value.sector.value.lightlevel <= g.value.minlight
        g.value.sector.value.lightlevel = g.value.sector.value.lightlevel + CDoom::GLOWSPEED
        g.value.direction = 1
      end
    when 1
      # UP
      g.value.sector.value.lightlevel = g.value.sector.value.lightlevel + CDoom::GLOWSPEED
      if g.value.sector.value.lightlevel >= g.value.maxlight
        g.value.sector.value.lightlevel = g.value.sector.value.lightlevel - CDoom::GLOWSPEED
        g.value.direction = -1
      end
    end
  end

  def self.p_spawn_glowing_light(sector : CDoom::Sector*)
    g = CDoom.z_malloc(sizeof(CDoom::Glow), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Glow*)

    CDoom.p_add_thinker(pointerof(g.value.@thinker))

    g.value.sector = sector
    g.value.minlight = CDoom.p_find_min_surrounding_light(sector, sector.value.lightlevel)
    g.value.maxlight = sector.value.lightlevel
    pointerof(g.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_glow).pointer, Pointer(Void).null)
    g.value.direction = -1

    sector.value.special = 0
  end

  #
  # TELEPORT MOVE
  #

  def self.pit_stomp_thing(thing : CDoom::Mobj*) : CDoom::DoomBool
    return 1 if thing.value.flags & CDoom::Mobjflag::MF_SHOOTABLE.value == 0

    blockdist = thing.value.radius + CDoom.tmthing.value.radius

    if doom_abs(thing.value.x - CDoom.tmx) >= blockdist ||
       doom_abs(thing.value.y - CDoom.tmy) >= blockdist
      # didn't hit it
      return 1
    end

    # don't clip against self
    return 1 if thing == CDoom.tmthing

    # monsters don't stomp things except on boss level
    return 0 if CDoom.tmthing.value.player.null? && CDoom.gamemap != 30

    CDoom.p_damage_mobj(thing, CDoom.tmthing, CDoom.tmthing, 10000)

    return 1
  end

  def self.p_teleport_move(thing : CDoom::Mobj*, x : CDoom::Fixed, y : CDoom::Fixed) : CDoom::DoomBool
    # kill anything occupying the position
    CDoom.tmthing = thing
    CDoom.tmflags = thing.value.flags

    CDoom.tmx = x
    CDoom.tmy = y

    CDoom.tmbbox[CDoom::BOXTOP] = y + CDoom.tmthing.value.radius
    CDoom.tmbbox[CDoom::BOXBOTTOM] = y - CDoom.tmthing.value.radius
    CDoom.tmbbox[CDoom::BOXRIGHT] = x + CDoom.tmthing.value.radius
    CDoom.tmbbox[CDoom::BOXLEFT] = x - CDoom.tmthing.value.radius

    newsubsec = CDoom.r_point_in_subsector(x, y)
    CDoom.ceilingline = Pointer(CDoom::Line).null

    # The base floor/ceiling is from the subsector
    # that contains the point.
    # Any contacted lines the step closer together
    # will adjust them.
    CDoom.tmfloorz = newsubsec.value.sector.value.floorheight
    CDoom.tmdropoffz = CDoom.tmfloorz
    CDoom.tmceilingz = newsubsec.value.sector.value.ceilingheight

    CDoom.validcount += 1
    CDoom.numspechit = 0

    # stomp on anythings contacted
    xl = (CDoom.tmbbox[CDoom::BOXLEFT] - CDoom.bmaporgx - CDoom::MAXRADIUS) >> CDoom::MAPBLOCKSHIFT
    xh = (CDoom.tmbbox[CDoom::BOXRIGHT] - CDoom.bmaporgx + CDoom::MAXRADIUS) >> CDoom::MAPBLOCKSHIFT
    yl = (CDoom.tmbbox[CDoom::BOXBOTTOM] - CDoom.bmaporgy - CDoom::MAXRADIUS) >> CDoom::MAPBLOCKSHIFT
    yh = (CDoom.tmbbox[CDoom::BOXTOP] - CDoom.bmaporgy + CDoom::MAXRADIUS) >> CDoom::MAPBLOCKSHIFT

    bx = xl
    while bx <= xh
      by = yl
      while by <= yh
        return 0 if CDoom.p_block_things_iterator(bx, by, ->CDoom.pit_stomp_thing) == 0
        by += 1
      end
      bx += 1
    end

    # the move is ok,
    # so link the thing into its new position
    CDoom.p_unset_thing_position(thing)

    thing.value.floorz = CDoom.tmfloorz
    thing.value.ceilingz = CDoom.tmceilingz
    thing.value.x = x
    thing.value.y = y

    CDoom.p_set_thing_position(thing)

    return 1
  end

  #
  # MOVEMENT ITERATOR FUNCTIONS
  #

  #
  # Adjusts tmfloorz and tmceilingz as lines are contacted
  #
  def self.pit_check_line(ld : CDoom::Line*) : CDoom::DoomBool
    if CDoom.tmbbox[CDoom::BOXRIGHT] <= ld.value.bbox[CDoom::BOXLEFT] ||
       CDoom.tmbbox[CDoom::BOXLEFT] >= ld.value.bbox[CDoom::BOXRIGHT] ||
       CDoom.tmbbox[CDoom::BOXTOP] <= ld.value.bbox[CDoom::BOXBOTTOM] ||
       CDoom.tmbbox[CDoom::BOXBOTTOM] >= ld.value.bbox[CDoom::BOXTOP]
      return 1
    end

    return 1 if CDoom.p_box_on_line_side(CDoom.tmbbox, ld) != -1

    # A line has been hit

    # The moving thing's destination position will cross
    # the given line.
    # If this should not be allowed, return false.
    # If the line is special, keep track of it
    # to process later if the move is proven ok.
    # NOTE: specials are NOT sorted by order,
    # so two special lines that are only 8 pixels apart
    # could be crossed in either order.

    return 0 if ld.value.backsector.null? # one sided line

    if CDoom.tmthing.value.flags & CDoom::Mobjflag::MF_MISSILE.value == 0
      return 0 if ld.value.flags & CDoom::ML_BLOCKING != 0 # explicitly blocking everything

      return 0 if CDoom.tmthing.value.player.null? && ld.value.flags & CDoom::ML_BLOCKMONSTERS != 0 # block monsters only
    end

    # set openrange, opentop, openbottom
    CDoom.p_line_opening(ld)

    # adjust floor / ceiling heights
    if CDoom.opentop < CDoom.tmceilingz
      CDoom.tmceilingz = CDoom.opentop
      CDoom.ceilingline = ld
    end

    CDoom.tmfloorz = CDoom.openbottom if CDoom.openbottom > CDoom.tmfloorz

    CDoom.tmdropoffz = CDoom.lowfloor if CDoom.lowfloor < CDoom.tmdropoffz

    # if contacted a special line, add it to the list
    if ld.value.special != 0
      CDoom.spechit[CDoom.numspechit] = ld
      CDoom.numspechit += 1
    end

    return 1
  end

  def self.pit_check_thing(thing : CDoom::Mobj*) : CDoom::DoomBool
    return 1 if thing.value.flags & (CDoom::Mobjflag::MF_SOLID.value | CDoom::Mobjflag::MF_SPECIAL.value | CDoom::Mobjflag::MF_SHOOTABLE.value) == 0

    blockdist = thing.value.radius + CDoom.tmthing.value.radius

    if doom_abs(thing.value.x - CDoom.tmx) >= blockdist ||
       doom_abs(thing.value.y - CDoom.tmy) >= blockdist
      # didn't hit it
      return 1
    end

    # don't clip against self
    return 1 if thing == CDoom.tmthing

    # check for skulls slamming into things
    if CDoom.tmthing.value.flags & CDoom::Mobjflag::MF_SKULLFLY.value != 0
      damage = ((CDoom.p_random % 8) + 1) * CDoom.tmthing.value.info.value.damage

      CDoom.p_damage_mobj(thing, CDoom.tmthing, CDoom.tmthing, damage)

      CDoom.tmthing.value.flags = CDoom.tmthing.value.flags & ~CDoom::Mobjflag::MF_SKULLFLY.value
      CDoom.tmthing.value.momx = 0
      CDoom.tmthing.value.momy = 0
      CDoom.tmthing.value.momz = 0

      CDoom.p_set_mobj_state(CDoom.tmthing, CDoom::Statenum.new(CDoom.tmthing.value.info.value.spawnstate))

      return 0 # stop moving
    end

    # missiles can hit other things
    if CDoom.tmthing.value.flags & CDoom::Mobjflag::MF_MISSILE.value != 0
      # see if it went over / under
      return 1 if CDoom.tmthing.value.z > thing.value.z + thing.value.height         # overhead
      return 1 if CDoom.tmthing.value.z + CDoom.tmthing.value.height < thing.value.z # underneath

      if !CDoom.tmthing.value.target.null? && (
           CDoom.tmthing.value.target.value.type == thing.value.type ||
           (CDoom.tmthing.value.target.value.type == CDoom::Mobjtype::MT_KNIGHT && thing.value.type == CDoom::Mobjtype::MT_BRUISER) ||
           (CDoom.tmthing.value.target.value.type == CDoom::Mobjtype::MT_BRUISER && thing.value.type == CDoom::Mobjtype::MT_KNIGHT)
         )
        # Don't hit same species as originator.
        return 1 if thing == CDoom.tmthing.value.target

        if thing.value.type != CDoom::Mobjtype::MT_PLAYER && @@deh_species_infighting == 0
          # Explode, but do no damage.
          # Let players missile other players.
          return 0
        end
      end

      if thing.value.flags & CDoom::Mobjflag::MF_SHOOTABLE.value == 0
        # didn't do any damage
        return (thing.value.flags & CDoom::Mobjflag::MF_SOLID.value == 0).to_unsafe
      end

      # damage / explode
      damage = ((CDoom.p_random % 8) + 1) * CDoom.tmthing.value.info.value.damage
      CDoom.p_damage_mobj(thing, CDoom.tmthing, CDoom.tmthing.value.target, damage)

      # don't traverse any more
      return 0
    end

    # check for special pickup
    if thing.value.flags & CDoom::Mobjflag::MF_SPECIAL.value != 0
      solid = thing.value.flags & CDoom::Mobjflag::MF_SOLID.value != 0
      if CDoom.tmflags & CDoom::Mobjflag::MF_PICKUP.value != 0
        # can remove thing
        CDoom.p_touch_special_thing(thing, CDoom.tmthing)
      end
      return (!solid).to_unsafe
    end

    return (thing.value.flags & CDoom::Mobjflag::MF_SOLID.value == 0).to_unsafe
  end

  #
  # MOVEMENT CLIPPING
  #

  #
  # This is purely informative, nothing is modified
  # (except things picked up).
  #
  # in:
  #  a mobj_t (can be valid or invalid)
  #  a position to be checked
  #   (doesn't need to be related to the mobj_t->x,y)
  #
  # during:
  #  special things are touched if MF_PICKUP
  #  early out on solid lines?
  #
  # out:
  #  newsubsec
  #  floorz
  #  ceilingz
  #  tmdropoffz
  #   the lowest point contacted
  #   (monsters won't move to a dropoff)
  #  speciallines[]
  #  numspeciallines
  #
  def self.p_check_position(thing : CDoom::Mobj*, x : CDoom::Fixed, y : CDoom::Fixed) : CDoom::DoomBool
    CDoom.tmthing = thing
    CDoom.tmflags = thing.value.flags

    CDoom.tmx = x
    CDoom.tmy = y

    CDoom.tmbbox[CDoom::BOXTOP] = y &+ CDoom.tmthing.value.radius
    CDoom.tmbbox[CDoom::BOXBOTTOM] = y &- CDoom.tmthing.value.radius
    CDoom.tmbbox[CDoom::BOXRIGHT] = x &+ CDoom.tmthing.value.radius
    CDoom.tmbbox[CDoom::BOXLEFT] = x &- CDoom.tmthing.value.radius

    newsubsec = CDoom.r_point_in_subsector(x, y)
    CDoom.ceilingline = Pointer(CDoom::Line).null

    # The base floor/ceiling is from the subsector
    # that contains the point.
    # Any contacted lines the step closer together
    # will adjust them.
    CDoom.tmfloorz = newsubsec.value.sector.value.floorheight
    CDoom.tmdropoffz = CDoom.tmfloorz
    CDoom.tmceilingz = newsubsec.value.sector.value.ceilingheight

    CDoom.validcount += 1
    CDoom.numspechit = 0

    return 1 if CDoom.tmflags & CDoom::Mobjflag::MF_NOCLIP.value != 0

    # Check things first, possibly picking things up.
    # The bounding box is extended by MAXRADIUS
    # because mobj_ts are grouped into mapblocks
    # based on their origin point, and can overlap
    # into adjacent blocks by up to MAXRADIUS units.
    xl = (CDoom.tmbbox[CDoom::BOXLEFT] &- CDoom.bmaporgx &- CDoom::MAXRADIUS) >> CDoom::MAPBLOCKSHIFT
    xh = (CDoom.tmbbox[CDoom::BOXRIGHT] &- CDoom.bmaporgx &+ CDoom::MAXRADIUS) >> CDoom::MAPBLOCKSHIFT
    yl = (CDoom.tmbbox[CDoom::BOXBOTTOM] &- CDoom.bmaporgy &- CDoom::MAXRADIUS) >> CDoom::MAPBLOCKSHIFT
    yh = (CDoom.tmbbox[CDoom::BOXTOP] &- CDoom.bmaporgy &+ CDoom::MAXRADIUS) >> CDoom::MAPBLOCKSHIFT

    bx = xl
    while bx <= xh
      by = yl
      while by <= yh
        return 0 if CDoom.p_block_things_iterator(bx, by, ->CDoom.pit_check_thing) == 0
        by += 1
      end
      bx += 1
    end

    # check lines
    xl = (CDoom.tmbbox[CDoom::BOXLEFT] &- CDoom.bmaporgx) >> CDoom::MAPBLOCKSHIFT
    xh = (CDoom.tmbbox[CDoom::BOXRIGHT] &- CDoom.bmaporgx) >> CDoom::MAPBLOCKSHIFT
    yl = (CDoom.tmbbox[CDoom::BOXBOTTOM] &- CDoom.bmaporgy) >> CDoom::MAPBLOCKSHIFT
    yh = (CDoom.tmbbox[CDoom::BOXTOP] &- CDoom.bmaporgy) >> CDoom::MAPBLOCKSHIFT

    bx = xl
    while bx <= xh
      by = yl
      while by <= yh
        return 0 if CDoom.p_block_lines_iterator(bx, by, ->CDoom.pit_check_line) == 0
        by += 1
      end
      bx += 1
    end

    return 1
  end

  #
  # Attempt to move to a new position,
  # crossing special lines unless MF_TELEPORT is set.
  #
  def self.p_try_move(thing : CDoom::Mobj*, x : CDoom::Fixed, y : CDoom::Fixed) : CDoom::DoomBool
    CDoom.floatok = 0
    return 0 if CDoom.p_check_position(thing, x, y) == 0 # solid wall or thing

    if thing.value.flags & CDoom::Mobjflag::MF_NOCLIP.value == 0
      return 0 if CDoom.tmceilingz - CDoom.tmfloorz < thing.value.height # doesn't fit

      CDoom.floatok = 1

      if thing.value.flags & CDoom::Mobjflag::MF_TELEPORT.value == 0 &&
         CDoom.tmceilingz - thing.value.z < thing.value.height
        return 0 # mobj must lower itself to fit
      end

      if thing.value.flags & CDoom::Mobjflag::MF_TELEPORT.value == 0 &&
         CDoom.tmfloorz - thing.value.z > 24 * FRACUNIT
        return 0 # too big a step up
      end

      if thing.value.flags & (CDoom::Mobjflag::MF_DROPOFF.value | CDoom::Mobjflag::MF_FLOAT.value) == 0 &&
         CDoom.tmfloorz - CDoom.tmdropoffz > 24 * FRACUNIT
        return 0 # don't stand over a dropoff
      end
    end

    # the move is ok,
    # so link the thing into its new position
    CDoom.p_unset_thing_position(thing)

    oldx = thing.value.x
    oldy = thing.value.y
    thing.value.floorz = CDoom.tmfloorz
    thing.value.ceilingz = CDoom.tmceilingz
    thing.value.x = x
    thing.value.y = y

    CDoom.p_set_thing_position(thing)

    # if any special lines were hit, do the effect
    if thing.value.flags & (CDoom::Mobjflag::MF_TELEPORT.value | CDoom::Mobjflag::MF_NOCLIP.value) == 0
      while CDoom.numspechit != 0
        CDoom.numspechit -= 1
        # see if the line was crossed
        ld = CDoom.spechit[CDoom.numspechit]
        side = CDoom.p_point_on_line_side(thing.value.x, thing.value.y, ld)
        oldside = CDoom.p_point_on_line_side(oldx, oldy, ld)
        if side != oldside
          CDoom.p_cross_special_line((ld - CDoom.lines).to_i32!, oldside, thing) if ld.value.special != 0
        end
      end
    end

    return 1
  end

  def self.p_thing_height_clip(thing : CDoom::Mobj*) : CDoom::DoomBool
    onfloor = (thing.value.z == thing.value.floorz).to_unsafe

    CDoom.p_check_position(thing, thing.value.x, thing.value.y)
    # what about stranding a monster partially off an edge?

    thing.value.floorz = CDoom.tmfloorz
    thing.value.ceilingz = CDoom.tmceilingz

    if onfloor != 0
      # walking monsters rise and fall with the floor
      thing.value.z = thing.value.floorz
    else
      # don't adjust a floating monster unless forced to
      if thing.value.z + thing.value.height > thing.value.ceilingz
        thing.value.z = thing.value.ceilingz - thing.value.height
      end
    end

    return 0 if thing.value.ceilingz - thing.value.floorz < thing.value.height

    return 1
  end

  #
  # SLIDE MOVE
  # Allows the player to slide along any angled walls.
  #

  #
  # Adjusts the xmove / ymove
  # so that the next move will slide along the wall.
  #
  def self.p_hit_slide_line(ld : CDoom::Line*)
    if ld.value.slopetype == CDoom::Slopetype::HORIZONTAL
      CDoom.tmymove = 0
      return
    end

    if ld.value.slopetype == CDoom::Slopetype::VERTICAL
      CDoom.tmxmove = 0
      return
    end

    side = CDoom.p_point_on_line_side(CDoom.slidemo.value.x, CDoom.slidemo.value.y, ld)

    lineangle = CDoom.r_point_to_angle2(0, 0, ld.value.dx, ld.value.dy)

    lineangle &+= ANG180 if side == 1

    moveangle = CDoom.r_point_to_angle2(0, 0, CDoom.tmxmove, CDoom.tmymove)
    deltaangle = moveangle &- lineangle

    deltaangle &+= ANG180 if deltaangle > ANG180

    lineangle >>= CDoom::ANGLETOFINESHIFT
    deltaangle >>= CDoom::ANGLETOFINESHIFT

    movelen = CDoom.p_aprox_distance(CDoom.tmxmove, CDoom.tmymove)
    newlen = CDoom.fixed_mul(movelen, @@finecosine[deltaangle])

    CDoom.tmxmove = CDoom.fixed_mul(newlen, @@finecosine[lineangle])
    CDoom.tmymove = CDoom.fixed_mul(newlen, @@finesine[lineangle])
  end

  def self.ptr_slide_traverse(int : CDoom::Intercept*) : CDoom::DoomBool
    if int.value.isaline == 0
      CDoom.i_error("Error: ptr_slide-traverse: not a line?")
    end

    li = int.value.d.line

    isblocking = false

    if li.value.flags & CDoom::ML_TWOSIDED == 0
      if CDoom.p_point_on_line_side(CDoom.slidemo.value.x, CDoom.slidemo.value.y, li) != 0
        # don't hit the back side
        return 1
      end
      isblocking = true
    end

    unless isblocking
      # set openrange, opentop, openbottom
      CDoom.p_line_opening(li)

      if CDoom.openrange < CDoom.slidemo.value.height ||                       # doesn't fit
         CDoom.opentop - CDoom.slidemo.value.z < CDoom.slidemo.value.height || # mobj is too hight
         CDoom.openbottom - CDoom.slidemo.value.z > 24 * FRACUNIT              # too big a step up
        isblocking = true
      end

      # this line doesn't block movement
      return 1 unless isblocking
    end

    # the line does block movement,
    # see if it is closer than best so far
    if int.value.frac < CDoom.bestslidefrac
      CDoom.secondslidefrac = CDoom.bestslidefrac
      CDoom.secondslideline = CDoom.bestslideline
      CDoom.bestslidefrac = int.value.frac
      CDoom.bestslideline = li
    end

    return 0 # stop
  end

  #
  # The momx / momy move is bad, so try to slide
  # along a wall.
  # Find the first line hit, move flush to it,
  # and slide along it
  #
  # This is a kludgy mess.
  #
  def self.p_slide_move(mo : CDoom::Mobj*)
    CDoom.slidemo = mo
    hitcount = 0

    loop do
      hitcount += 1
      stairstep = hitcount == 3 ? true : false # don't loop forever

      unless stairstep
        # trace along the three leading corners
        if mo.value.momx > 0
          leadx = mo.value.x + mo.value.radius
          trailx = mo.value.x - mo.value.radius
        else
          leadx = mo.value.x - mo.value.radius
          trailx = mo.value.x + mo.value.radius
        end

        if mo.value.momy > 0
          leady = mo.value.y + mo.value.radius
          traily = mo.value.y - mo.value.radius
        else
          leady = mo.value.y - mo.value.radius
          traily = mo.value.y + mo.value.radius
        end

        CDoom.bestslidefrac = FRACUNIT + 1

        CDoom.p_path_traverse(leadx, leady, leadx + mo.value.momx, leady + mo.value.momy,
          CDoom::PT_ADDLINES, ->CDoom.ptr_slide_traverse)
        CDoom.p_path_traverse(trailx, leady, trailx + mo.value.momx, leady + mo.value.momy,
          CDoom::PT_ADDLINES, ->CDoom.ptr_slide_traverse)
        CDoom.p_path_traverse(leadx, traily, leadx + mo.value.momx, traily + mo.value.momy,
          CDoom::PT_ADDLINES, ->CDoom.ptr_slide_traverse)
      end

      # move up to the wall
      loop do
        if stairstep || CDoom.bestslidefrac == FRACUNIT + 1
          # the move most have hit the middle, so stairstep
          if CDoom.p_try_move(mo, mo.value.x, mo.value.y + mo.value.momy) == 0
            CDoom.p_try_move(mo, mo.value.x + mo.value.momx, mo.value.y)
          end
          return
        end

        # fudge a bit to make sure it doesn't hit
        CDoom.bestslidefrac -= 0x800
        if CDoom.bestslidefrac > 0
          newx = CDoom.fixed_mul(mo.value.momx, CDoom.bestslidefrac)
          newy = CDoom.fixed_mul(mo.value.momy, CDoom.bestslidefrac)

          if CDoom.p_try_move(mo, mo.value.x + newx, mo.value.y + newy) == 0
            stairstep = true
            next
          end
        end
        break
      end

      # Now continue along the wall.
      # First calculate remainder.
      CDoom.bestslidefrac = FRACUNIT - (CDoom.bestslidefrac + 0x800)

      CDoom.bestslidefrac = FRACUNIT if CDoom.bestslidefrac > FRACUNIT
      return if CDoom.bestslidefrac <= 0

      CDoom.tmxmove = CDoom.fixed_mul(mo.value.momx, CDoom.bestslidefrac)
      CDoom.tmymove = CDoom.fixed_mul(mo.value.momy, CDoom.bestslidefrac)

      CDoom.p_hit_slide_line(CDoom.bestslideline) # clip the moves

      mo.value.momx = CDoom.tmxmove
      mo.value.momy = CDoom.tmymove

      next if CDoom.p_try_move(mo, mo.value.x + CDoom.tmxmove, mo.value.y + CDoom.tmymove) == 0

      break
    end
  end

  #
  # Sets linetaget and aimslope when a target is aimed at.
  #
  def self.ptr_aim_traverse(int : CDoom::Intercept*) : CDoom::DoomBool
    if int.value.isaline != 0
      li = int.value.d.line

      return 0 if li.value.flags & CDoom::ML_TWOSIDED == 0 # stop

      # Crosses a two sided line.
      # A two sided line will restrict
      # the possible target ranges.
      CDoom.p_line_opening(li)

      return 0 if CDoom.openbottom >= CDoom.opentop # stop

      dist = CDoom.fixed_mul(CDoom.attackrange, int.value.frac)

      if li.value.frontsector.value.floorheight != li.value.backsector.value.floorheight
        slope = CDoom.fixed_div(CDoom.openbottom - CDoom.shootz, dist)
        CDoom.bottomslope = slope if slope > CDoom.bottomslope
      end

      if li.value.frontsector.value.ceilingheight != li.value.backsector.value.ceilingheight
        slope = CDoom.fixed_div(CDoom.opentop - CDoom.shootz, dist)
        CDoom.topslope = slope if slope < CDoom.topslope
      end

      return 0 if CDoom.topslope <= CDoom.bottomslope # stop

      return 1 # shot continues
    end

    # shoot a thing
    th = int.value.d.thing
    return 1 if th == CDoom.shootthing # can't shoot self

    return 1 if th.value.flags & CDoom::Mobjflag::MF_SHOOTABLE.value == 0 # corpse or something

    # check angles to see if the thing can be aimed at
    dist = CDoom.fixed_mul(CDoom.attackrange, int.value.frac)
    thingtopslope = CDoom.fixed_div(th.value.z + th.value.height - CDoom.shootz, dist)

    return 1 if thingtopslope < CDoom.bottomslope # shot over the thing

    thingbottomslope = CDoom.fixed_div(th.value.z - CDoom.shootz, dist)

    return 1 if thingbottomslope > CDoom.topslope # shot under the thing

    # this thing can be hit!
    thingtopslope = CDoom.topslope if thingtopslope > CDoom.topslope
    thingbottomslope = CDoom.bottomslope if thingbottomslope < CDoom.bottomslope

    CDoom.aimslope = (thingtopslope + thingbottomslope).tdiv(2)
    CDoom.linetarget = th

    return 0 # don't go any farther
  end

  def self.ptr_shoot_traverse(int : CDoom::Intercept*) : CDoom::DoomBool
    if int.value.isaline != 0
      li = int.value.d.line

      CDoom.p_shoot_special_line(CDoom.shootthing, li) if li.value.special != 0

      hitline = li.value.flags & CDoom::ML_TWOSIDED == 0 ? true : false

      unless hitline
        # crosses a two sided line
        CDoom.p_line_opening(li)

        dist = CDoom.fixed_mul(CDoom.attackrange, int.value.frac)

        if li.value.frontsector.value.floorheight != li.value.backsector.value.floorheight
          slope = CDoom.fixed_div(CDoom.openbottom - CDoom.shootz, dist)
          hitline = slope > CDoom.aimslope
        end

        if !hitline && li.value.frontsector.value.ceilingheight != li.value.backsector.value.ceilingheight
          slope = CDoom.fixed_div(CDoom.opentop - CDoom.shootz, dist)
          hitline = slope < CDoom.aimslope
        end

        return 1 unless hitline # shot continues
      end

      # hit line
      # position a bit closer
      frac = int.value.frac - CDoom.fixed_div(4 * FRACUNIT, CDoom.attackrange)
      x = CDoom.trace.x + CDoom.fixed_mul(CDoom.trace.dx, frac)
      y = CDoom.trace.y + CDoom.fixed_mul(CDoom.trace.dy, frac)
      z = CDoom.shootz + CDoom.fixed_mul(CDoom.aimslope, CDoom.fixed_mul(frac, CDoom.attackrange))

      if li.value.frontsector.value.ceilingpic == CDoom.skyflatnum
        # don't shoot the sky!
        return 0 if z > li.value.frontsector.value.ceilingheight

        # it's a sky hack wall
        return 0 if !li.value.backsector.null? && li.value.backsector.value.ceilingpic == CDoom.skyflatnum
      end

      # Spawn bullet puffs.
      CDoom.p_spawn_puff(x, y, z)

      # don't go any farther
      return 0
    end

    # shoot a thing
    th = int.value.d.thing
    return 1 if th == CDoom.shootthing # can't shoot self

    return 1 if th.value.flags & CDoom::Mobjflag::MF_SHOOTABLE.value == 0 # corpse or something

    # check angles to see if the thing can be aimed at
    dist = CDoom.fixed_mul(CDoom.attackrange, int.value.frac)
    thingtopslope = CDoom.fixed_div(th.value.z + th.value.height - CDoom.shootz, dist)

    return 1 if thingtopslope < CDoom.aimslope # shot over the thing

    thingbottomslope = CDoom.fixed_div(th.value.z - CDoom.shootz, dist)

    return 1 if thingbottomslope > CDoom.aimslope # shot under the thing

    # hit thing
    # position a bit closer
    frac = int.value.frac - CDoom.fixed_div(10 * FRACUNIT, CDoom.attackrange)

    x = CDoom.trace.x + CDoom.fixed_mul(CDoom.trace.dx, frac)
    y = CDoom.trace.y + CDoom.fixed_mul(CDoom.trace.dy, frac)
    z = CDoom.shootz + CDoom.fixed_mul(CDoom.aimslope, CDoom.fixed_mul(frac, CDoom.attackrange))

    # Spawn bullet puffs or blod spots,
    # depending on target type.
    if int.value.d.thing.value.flags & CDoom::Mobjflag::MF_NOBLOOD.value != 0
      CDoom.p_spawn_puff(x, y, z)
    else
      CDoom.p_spawn_blood(x, y, z, CDoom.la_damage)
    end

    CDoom.p_damage_mobj(th, CDoom.shootthing, CDoom.shootthing, CDoom.la_damage) if CDoom.la_damage != 0

    # don't go any farther
    return 0
  end

  def self.p_aim_line_attack(t1 : CDoom::Mobj*, angle : CDoom::Angle, distance : CDoom::Fixed) : CDoom::Fixed
    angle >>= CDoom::ANGLETOFINESHIFT
    CDoom.shootthing = t1

    x2 = t1.value.x + (distance >> FRACBITS) * @@finecosine[angle]
    y2 = t1.value.y + (distance >> FRACBITS) * @@finesine[angle]
    CDoom.shootz = t1.value.z + (t1.value.height >> 1) + 8 * FRACUNIT

    # can't shoot outside view angles
    CDoom.topslope = 100 * FRACUNIT // 160
    CDoom.bottomslope = -100 * FRACUNIT // 160

    CDoom.attackrange = distance
    CDoom.linetarget = Pointer(CDoom::Mobj).null

    CDoom.p_path_traverse(t1.value.x, t1.value.y,
      x2, y2,
      CDoom::PT_ADDLINES | CDoom::PT_ADDTHINGS,
      ->CDoom.ptr_aim_traverse)

    return CDoom.aimslope unless CDoom.linetarget.null?

    return 0
  end

  #
  # If damage == 0, it is just a test trace
  # that will leave linetarget set.
  #
  def self.p_line_attack(t1 : CDoom::Mobj*, angle : CDoom::Angle, distance : CDoom::Fixed, slope : CDoom::Fixed, damage : LibC::Int)
    angle >>= CDoom::ANGLETOFINESHIFT
    CDoom.shootthing = t1
    CDoom.la_damage = damage
    x2 = t1.value.x + (distance >> FRACBITS) * @@finecosine[angle]
    y2 = t1.value.y + (distance >> FRACBITS) * @@finesine[angle]
    CDoom.shootz = t1.value.z + (t1.value.height >> 1) + 8 * FRACUNIT
    CDoom.attackrange = distance
    CDoom.aimslope = slope

    CDoom.p_path_traverse(t1.value.x, t1.value.y,
      x2, y2,
      CDoom::PT_ADDLINES | CDoom::PT_ADDTHINGS,
      ->CDoom.ptr_shoot_traverse)
  end

  def self.ptr_use_traverse(int : CDoom::Intercept*) : CDoom::DoomBool
    if int.value.d.line.value.special == 0
      CDoom.p_line_opening(int.value.d.line)
      if CDoom.openrange <= 0
        CDoom.s_start_sound(CDoom.usething, CDoom::Sfxenum::SFX_noway.value)

        # can't use through a wall
        return 0
      end
      # not a special line, but keep checking
      return 1
    end

    side = 0
    side = 1 if CDoom.p_point_on_line_side(CDoom.usething.value.x, CDoom.usething.value.y, int.value.d.line) == 1

    CDoom.p_use_special_line(CDoom.usething, int.value.d.line, side)

    # can't use for than one special line in a row
    return 0
  end

  #
  # Looks for special lines in front of the player to activate.
  #
  def self.p_use_lines(player : CDoom::Player*)
    CDoom.usething = player.value.mo

    angle = player.value.mo.value.angle >> CDoom::ANGLETOFINESHIFT

    x1 = player.value.mo.value.x
    y1 = player.value.mo.value.y
    x2 = x1 + (CDoom::USERANGE >> FRACBITS) * @@finecosine[angle]
    y2 = y1 + (CDoom::USERANGE >> FRACBITS) * @@finesine[angle]

    CDoom.p_path_traverse(x1, y1, x2, y2, CDoom::PT_ADDLINES, ->CDoom.ptr_use_traverse)
  end

  #
  # RADIUS ATTACK
  #

  #
  # "bombsource" is the creature
  # that caused the explosion at "bombspot".
  #
  def self.pit_radius_attack(thing : CDoom::Mobj*) : CDoom::DoomBool
    return 1 if thing.value.flags & CDoom::Mobjflag::MF_SHOOTABLE.value == 0

    # Boss spider and cyborg
    # take no damage from concussion.
    return 1 if thing.value.type == CDoom::Mobjtype::MT_CYBORG ||
                thing.value.type == CDoom::Mobjtype::MT_SPIDER

    dx = doom_abs(thing.value.x - CDoom.bombspot.value.x)
    dy = doom_abs(thing.value.y - CDoom.bombspot.value.y)

    dist = dx > dy ? dx : dy
    dist = (dist - thing.value.radius) >> FRACBITS

    dist = 0 if dist < 0

    return 1 if dist >= CDoom.bombdamage # out of range

    if CDoom.p_check_sight(thing, CDoom.bombspot) != 0
      # must be in direct path
      CDoom.p_damage_mobj(thing, CDoom.bombspot, CDoom.bombsource, CDoom.bombdamage - dist)
    end

    return 1
  end

  #
  # Source is the creature that caused the explosion at spot.
  #
  def self.p_radius_attack(spot : CDoom::Mobj*, source : CDoom::Mobj*, damage : LibC::Int)
    dist = (damage + CDoom::MAXRADIUS) << FRACBITS
    yh = (spot.value.y + dist - CDoom.bmaporgy) >> CDoom::MAPBLOCKSHIFT
    yl = (spot.value.y - dist - CDoom.bmaporgy) >> CDoom::MAPBLOCKSHIFT
    xh = (spot.value.x + dist - CDoom.bmaporgx) >> CDoom::MAPBLOCKSHIFT
    xl = (spot.value.x - dist - CDoom.bmaporgx) >> CDoom::MAPBLOCKSHIFT
    CDoom.bombspot = spot
    CDoom.bombsource = source
    CDoom.bombdamage = damage

    y = yl
    while y <= yh
      x = xl
      while x <= xh
        CDoom.p_block_things_iterator(x, y, ->CDoom.pit_radius_attack)
        x += 1
      end
      y += 1
    end
  end

  def self.pit_change_sector(thing : CDoom::Mobj*) : CDoom::DoomBool
    return 1 if CDoom.p_thing_height_clip(thing) != 0 # keep checking

    # crunch bodies to giblets
    if thing.value.health <= 0
      CDoom.p_set_mobj_state(thing, CDoom::Statenum::S_GIBS)

      thing.value.flags = thing.value.flags & ~CDoom::Mobjflag::MF_SOLID.value
      thing.value.height = 0
      thing.value.radius = 0

      # keep checking
      return 1
    end

    # crunch dropped items
    if thing.value.flags & CDoom::Mobjflag::MF_DROPPED.value != 0
      CDoom.p_remove_mobj(thing)

      # keep checking
      return 1
    end

    if thing.value.flags & CDoom::Mobjflag::MF_SHOOTABLE.value == 0
      # assume it is bloody gibs or something
      return 1
    end

    CDoom.nofit = 1

    if CDoom.crushchange && CDoom.leveltime & 3 == 0
      CDoom.p_damage_mobj(thing, Pointer(CDoom::Mobj).null, Pointer(CDoom::Mobj).null, 10)

      # spray blood in a random direction
      mo = CDoom.p_spawn_mobj(thing.value.x,
        thing.value.y,
        thing.value.z + thing.value.height.tdiv(2), CDoom::Mobjtype::MT_BLOOD)

      mo.value.momx = (CDoom.p_random - CDoom.p_random) << 12
      mo.value.momy = (CDoom.p_random - CDoom.p_random) << 12
    end

    # keep checking (crush other things)
    return 1
  end

  def self.p_change_sector(sector : CDoom::Sector*, crunch : CDoom::DoomBool) : CDoom::DoomBool
    CDoom.nofit = 0
    CDoom.crushchange = crunch

    # re-check heights for all things near the moving sector
    x = sector.value.blockbox[CDoom::BOXLEFT]
    while x <= sector.value.blockbox[CDoom::BOXRIGHT]
      y = sector.value.blockbox[CDoom::BOXBOTTOM]
      while y <= sector.value.blockbox[CDoom::BOXTOP]
        CDoom.p_block_things_iterator(x, y, ->CDoom.pit_change_sector)
        y += 1
      end

      x += 1
    end

    return CDoom.nofit
  end

  #
  # Gives an estimation of distance (not exact)
  #
  def self.p_aprox_distance(dx : CDoom::Fixed, dy : CDoom::Fixed) : CDoom::Fixed
    dx = doom_abs(dx)
    dy = doom_abs(dy)
    return dx + dy - (dx >> 1) if dx < dy
    return dx + dy - (dy >> 1)
  end

  #
  # Returns 0 or 1
  #
  def self.p_point_on_line_side(x : CDoom::Fixed, y : CDoom::Fixed, line : CDoom::Line*) : LibC::Int
    if line.value.dx == 0
      return (line.value.dy > 0).to_unsafe if x <= line.value.v1.value.x

      return (line.value.dy < 0).to_unsafe
    end
    if line.value.dy == 0
      return (line.value.dx < 0).to_unsafe if y <= line.value.v1.value.y

      return (line.value.dx > 0).to_unsafe
    end

    dx = (x - line.value.v1.value.x)
    dy = (y - line.value.v1.value.y)

    left = CDoom.fixed_mul(line.value.dy >> FRACBITS, dx)
    right = CDoom.fixed_mul(dy, line.value.dx >> FRACBITS)

    return 0 if right < left # front side
    return 1                 # back side
  end

  #
  # Considers the line to be infinite
  # Returns side 0 or 1, -1 if box crosses the line.
  #
  def self.p_box_on_line_side(tmbox : CDoom::Fixed*, ld : CDoom::Line*) : LibC::Int
    p1 = 0
    p2 = 0

    case ld.value.slopetype
    when CDoom::Slopetype::HORIZONTAL
      p1 = (tmbox[CDoom::BOXTOP] > ld.value.v1.value.y).to_unsafe
      p2 = (tmbox[CDoom::BOXBOTTOM] > ld.value.v1.value.y).to_unsafe
      if ld.value.dx < 0
        p1 ^= 1
        p2 ^= 1
      end
    when CDoom::Slopetype::VERTICAL
      p1 = (tmbox[CDoom::BOXRIGHT] < ld.value.v1.value.x).to_unsafe
      p2 = (tmbox[CDoom::BOXLEFT] < ld.value.v1.value.x).to_unsafe
      if ld.value.dy < 0
        p1 ^= 1
        p2 ^= 1
      end
    when CDoom::Slopetype::POSITIVE
      p1 = CDoom.p_point_on_line_side(tmbox[CDoom::BOXLEFT], tmbox[CDoom::BOXTOP], ld)
      p2 = CDoom.p_point_on_line_side(tmbox[CDoom::BOXRIGHT], tmbox[CDoom::BOXBOTTOM], ld)
    when CDoom::Slopetype::NEGATIVE
      p1 = CDoom.p_point_on_line_side(tmbox[CDoom::BOXRIGHT], tmbox[CDoom::BOXTOP], ld)
      p2 = CDoom.p_point_on_line_side(tmbox[CDoom::BOXLEFT], tmbox[CDoom::BOXBOTTOM], ld)
    end

    return p1 if p1 == p2
    return -1
  end

  def self.p_point_on_divline_side(x : CDoom::Fixed, y : CDoom::Fixed, line : CDoom::Divline*) : LibC::Int
    if line.value.dx == 0
      return (line.value.dy > 0).to_unsafe if x <= line.value.x

      return (line.value.dy < 0).to_unsafe
    end
    if line.value.dy == 0
      return (line.value.dx < 0).to_unsafe if y <= line.value.y

      return (line.value.dx > 0).to_unsafe
    end

    dx = (x - line.value.x)
    dy = (y - line.value.y)

    # try to quickly decide by looking at sign bits
    if (line.value.dy ^ line.value.dx ^ dx ^ dy) & 0x80000000 != 0
      return 1 if (line.value.dy ^ dx) & 0x80000000 != 0 # (left is negative)
      return 0
    end

    left = CDoom.fixed_mul(line.value.dy >> 8, dx >> 8)
    right = CDoom.fixed_mul(dy >> 8, line.value.dx >> 8)

    return 0 if right < left # front side
    return 1                 # back side
  end

  def self.p_make_divline(li : CDoom::Line*, dl : CDoom::Divline*)
    dl.value.x = li.value.v1.value.x
    dl.value.y = li.value.v1.value.y
    dl.value.dx = li.value.dx
    dl.value.dy = li.value.dy
  end

  #
  # Returns the fractional intercept point
  # along the first divline.
  # This is only called by the addthings
  # and addlines traversers.
  #
  def self.p_intercept_vector(v2 : CDoom::Divline*, v1 : CDoom::Divline*) : CDoom::Fixed
    den = CDoom.fixed_mul(v1.value.dy >> 8, v2.value.dx) &- CDoom.fixed_mul(v1.value.dx >> 8, v2.value.dy)

    return 0 if den == 0

    num =
      CDoom.fixed_mul((v1.value.x &- v2.value.x) >> 8, v1.value.dy) &+
        CDoom.fixed_mul((v2.value.y &- v1.value.y) >> 8, v1.value.dx)
    frac = CDoom.fixed_div(num, den)

    return frac
  end

  #
  # Sets opentop and openbottom to the window
  # through a two sided line.
  # OPTIMIZE: keep this precalculated
  #
  def self.p_line_opening(linedef : CDoom::Line*)
    if linedef.value.sidenum[1] == -1
      # single sided line
      CDoom.openrange = 0
      return
    end

    front = linedef.value.frontsector
    back = linedef.value.backsector

    if front.value.ceilingheight < back.value.ceilingheight
      CDoom.opentop = front.value.ceilingheight
    else
      CDoom.opentop = back.value.ceilingheight
    end

    if front.value.floorheight > back.value.floorheight
      CDoom.openbottom = front.value.floorheight
      CDoom.lowfloor = back.value.floorheight
    else
      CDoom.openbottom = back.value.floorheight
      CDoom.lowfloor = front.value.floorheight
    end

    CDoom.openrange = CDoom.opentop - CDoom.openbottom
  end

  #
  # THING POSITION SETTING
  #

  #
  # Unlinks a thing from block map and sectors.
  # On each position change, BLOCKMAP and other
  # lookups maintaining lists ot things inside
  # these structures need to be updated.
  #
  def self.p_unset_thing_position(thing : CDoom::Mobj*)
    if thing.value.flags & CDoom::Mobjflag::MF_NOSECTOR.value == 0
      # inert things don't need to be in blockmap?
      # unlink from subsector
      thing.value.snext.value.sprev = thing.value.sprev unless thing.value.snext.null?

      if !thing.value.sprev.null?
        thing.value.sprev.value.snext = thing.value.snext
      else
        thing.value.subsector.value.sector.value.thinglist = thing.value.snext
      end
    end

    if thing.value.flags & CDoom::Mobjflag::MF_NOBLOCKMAP.value == 0
      # inert things don't need to be in blockmap
      # unlink from block map
      thing.value.bnext.value.bprev = thing.value.bprev unless thing.value.bnext.null?

      if !thing.value.bprev.null?
        thing.value.bprev.value.bnext = thing.value.bnext
      else
        blockx = (thing.value.x - CDoom.bmaporgx) >> CDoom::MAPBLOCKSHIFT
        blocky = (thing.value.y - CDoom.bmaporgy) >> CDoom::MAPBLOCKSHIFT

        if blockx >= 0 && blockx < CDoom.bmapwidth &&
           blocky >= 0 && blocky < CDoom.bmapheight
          CDoom.blocklinks[blocky * CDoom.bmapwidth + blockx] = thing.value.bnext
        end
      end
    end
  end

  def self.p_set_thing_position(thing : CDoom::Mobj*)
    # link into subsector
    ss = CDoom.r_point_in_subsector(thing.value.x, thing.value.y)
    thing.value.subsector = ss

    if thing.value.flags & CDoom::Mobjflag::MF_NOSECTOR.value == 0
      # invisible things don't go into the sector links
      sec = ss.value.sector

      thing.value.sprev = Pointer(CDoom::Mobj).null
      thing.value.snext = sec.value.thinglist

      sec.value.thinglist.value.sprev = thing unless sec.value.thinglist.null?

      sec.value.thinglist = thing
    end

    # link into blockmap
    if thing.value.flags & CDoom::Mobjflag::MF_NOBLOCKMAP.value == 0
      # inert things don't need to be in blockmap
      blockx = (thing.value.x - CDoom.bmaporgx) >> CDoom::MAPBLOCKSHIFT
      blocky = (thing.value.y - CDoom.bmaporgy) >> CDoom::MAPBLOCKSHIFT

      if blockx >= 0 && blockx < CDoom.bmapwidth &&
         blocky >= 0 && blocky < CDoom.bmapheight
        link = CDoom.blocklinks + (blocky * CDoom.bmapwidth + blockx)
        thing.value.bprev = Pointer(CDoom::Mobj).null
        thing.value.bnext = link.value
        link.value.value.bprev = thing unless link.value.null?

        link.value = thing
      else
        # thing is off the map
        thing.value.bnext = Pointer(CDoom::Mobj).null
        thing.value.bprev = Pointer(CDoom::Mobj).null
      end
    end
  end

  #
  # BLOCK MAP ITERATORS
  # For each line/thing in the given mapblock,
  # call the passed PIT_* function.
  # If the function returns false,
  # exit with false without checking anything else.
  #

  #
  # The validcount flags are used to avoid checking lines
  # that are marked in multiple mapblocks,
  # so increment validcount before the first call
  # to P_BlockLinesIterator, then make one or more calls
  # to it.
  #
  def self.p_block_lines_iterator(x : LibC::Int, y : LibC::Int, func : Proc(CDoom::Line*, CDoom::DoomBool)) : CDoom::DoomBool
    return 1 if x < 0 || y < 0 || x >= CDoom.bmapwidth || y >= CDoom.bmapheight

    offset = y * CDoom.bmapwidth + x

    offset = (CDoom.blockmap + offset).value

    list = CDoom.blockmaplump + offset
    while list.value != -1
      ld = CDoom.lines + list.value

      if ld.value.validcount == CDoom.validcount
        list += 1
        next # line has already been checked
      end

      ld.value.validcount = CDoom.validcount

      return 0 if func.call(ld) == 0

      list += 1
    end

    return 1 # everything was checked
  end

  def self.p_block_things_iterator(x : LibC::Int, y : LibC::Int, func : Proc(CDoom::Mobj*, CDoom::DoomBool)) : CDoom::DoomBool
    return 1 if x < 0 || y < 0 || x >= CDoom.bmapwidth || y >= CDoom.bmapheight

    mobj = CDoom.blocklinks[y * CDoom.bmapwidth + x]
    while !mobj.null?
      return 0 if func.call(mobj) == 0

      mobj = mobj.value.bnext
    end

    return 1
  end

  #
  # INTERCEPT ROUTINES
  #

  #
  # Looks for lines in the given block
  # that intercept the given trace
  # to add to the intercepts list.
  #
  # A line is crossed if its endpoints
  # are on opposite sides of the trace.
  # Returns true if earlyout and a solid line hit.
  #
  def self.pit_add_line_intercepts(ld : CDoom::Line*) : CDoom::DoomBool
    s1 = 0
    s2 = 0
    dl = CDoom::Divline.new
    # avoid precision problems with two routines
    if CDoom.trace.dx > FRACUNIT * 16 ||
       CDoom.trace.dy > FRACUNIT * 16 ||
       CDoom.trace.dx < -FRACUNIT * 16 ||
       CDoom.trace.dy < -FRACUNIT * 16
      s1 = CDoom.p_point_on_divline_side(ld.value.v1.value.x, ld.value.v1.value.y, pointerof(CDoom.trace))
      s2 = CDoom.p_point_on_divline_side(ld.value.v2.value.x, ld.value.v2.value.y, pointerof(CDoom.trace))
    else
      s1 = CDoom.p_point_on_line_side(CDoom.trace.x, CDoom.trace.y, ld)
      s2 = CDoom.p_point_on_line_side(CDoom.trace.x + CDoom.trace.dx, CDoom.trace.y + CDoom.trace.dy, ld)
    end

    return 1 if s1 == s2 # line isn't crossed

    # hit the line
    CDoom.p_make_divline(ld, pointerof(dl))
    frac = CDoom.p_intercept_vector(pointerof(CDoom.trace), pointerof(dl))

    return 1 if frac < 0 # behind source

    # try to early out the check
    if CDoom.earlyout != 0 &&
       frac < FRACUNIT &&
       ld.value.backsector.null?
      return 0 # stop checking
    end

    CDoom.intercept_p.value.frac = frac
    CDoom.intercept_p.value.isaline = 1
    CDoom.intercept_p.value.d.line = ld

    CDoom.intercept_p += 1

    return 1 # continue
  end

  def self.pit_add_thing_intercepts(thing : CDoom::Mobj*) : CDoom::DoomBool
    tracepositive = ((CDoom.trace.dx ^ CDoom.trace.dy) > 0).to_unsafe

    # check a corner to corner crossection for hit
    if tracepositive != 0
      x1 = thing.value.x - thing.value.radius
      y1 = thing.value.y + thing.value.radius

      x2 = thing.value.x + thing.value.radius
      y2 = thing.value.y - thing.value.radius
    else
      x1 = thing.value.x - thing.value.radius
      y1 = thing.value.y - thing.value.radius

      x2 = thing.value.x + thing.value.radius
      y2 = thing.value.y + thing.value.radius
    end

    s1 = CDoom.p_point_on_divline_side(x1, y1, pointerof(CDoom.trace))
    s2 = CDoom.p_point_on_divline_side(x2, y2, pointerof(CDoom.trace))

    return 1 if s1 == s2 # line isn't crossed

    dl = CDoom::Divline.new(
      x: x1,
      y: y1,
      dx: x2 - x1,
      dy: y2 - y1
    )

    frac = CDoom.p_intercept_vector(pointerof(CDoom.trace), pointerof(dl))

    return 1 if frac < 0 # behind source

    CDoom.intercept_p.value.frac = frac
    CDoom.intercept_p.value.isaline = 0
    CDoom.intercept_p.value.d.thing = thing

    CDoom.intercept_p += 1

    return 1 # keep going
  end

  #
  # Returns true if the traverser function returns true
  # for all lines.
  #
  def self.p_traverse_intercepts(func : CDoom::Traverser, maxfrac : CDoom::Fixed) : CDoom::DoomBool
    count = (CDoom.intercept_p - CDoom.intercepts.to_unsafe).to_i32!

    int = Pointer(CDoom::Intercept).null # shut up compiler warning

    while count != 0
      count -= 1
      dist = Int32::MAX
      scan = CDoom.intercepts.to_unsafe
      while scan < CDoom.intercept_p
        if scan.value.frac < dist
          dist = scan.value.frac
          int = scan
        end
        scan += 1
      end

      return 1 if dist > maxfrac # checked everything in range

      # Unused block here in original source. I'm not porting #if 0 sections

      return 0 if func.call(int) == 0 # don't bother going farther

      int.value.frac = Int32::MAX
    end

    return 1 # everything was traversed
  end

  #
  # Traces a line from x1,y1 to x2,y2,
  # calling the traverser function for each.
  # Returns true if the traverser function returns true
  # for all lines.
  #
  def self.p_path_traverse(x1 : CDoom::Fixed, y1 : CDoom::Fixed, x2 : CDoom::Fixed, y2 : CDoom::Fixed, flags : LibC::Int, trav : Proc(CDoom::Intercept*, CDoom::DoomBool)) : CDoom::DoomBool
    CDoom.earlyout = flags & CDoom::PT_EARLYOUT != 0

    CDoom.validcount += 1
    CDoom.intercept_p = CDoom.intercepts.to_unsafe

    x1 += FRACUNIT if (x1 - CDoom.bmaporgx) & (CDoom::MAPBLOCKSIZE - 1) == 0 # don't side exactly on a line

    y1 += FRACUNIT if (y1 - CDoom.bmaporgy) & (CDoom::MAPBLOCKSIZE - 1) == 0 # don't side exactly on a line

    CDoom.trace.x = x1
    CDoom.trace.y = y1
    CDoom.trace.dx = x2 - x1
    CDoom.trace.dy = y2 - y1

    x1 -= CDoom.bmaporgx
    y1 -= CDoom.bmaporgy
    xt1 = x1 >> CDoom::MAPBLOCKSHIFT
    yt1 = y1 >> CDoom::MAPBLOCKSHIFT

    x2 -= CDoom.bmaporgx
    y2 -= CDoom.bmaporgy
    xt2 = x2 >> CDoom::MAPBLOCKSHIFT
    yt2 = y2 >> CDoom::MAPBLOCKSHIFT

    if xt2 > xt1
      mapxstep = 1
      partial = FRACUNIT - ((x1 >> CDoom::MAPBTOFRAC) & (FRACUNIT - 1))
      ystep = CDoom.fixed_div(y2 - y1, doom_abs(x2 - x1))
    elsif xt2 < xt1
      mapxstep = -1
      partial = (x1 >> CDoom::MAPBTOFRAC) & (FRACUNIT - 1)
      ystep = CDoom.fixed_div(y2 - y1, doom_abs(x2 - x1))
    else
      mapxstep = 0
      partial = FRACUNIT
      ystep = 256 * FRACUNIT
    end

    yintercept = (y1 >> CDoom::MAPBTOFRAC) + CDoom.fixed_mul(partial, ystep)

    if yt2 > yt1
      mapystep = 1
      partial = FRACUNIT - ((y1 >> CDoom::MAPBTOFRAC) & (FRACUNIT - 1))
      xstep = CDoom.fixed_div(x2 - x1, doom_abs(y2 - y1))
    elsif yt2 < yt1
      mapystep = -1
      partial = (y1 >> CDoom::MAPBTOFRAC) & (FRACUNIT - 1)
      xstep = CDoom.fixed_div(x2 - x1, doom_abs(y2 - y1))
    else
      mapystep = 0
      partial = FRACUNIT
      xstep = 256 * FRACUNIT
    end

    xintercept = (x1 >> CDoom::MAPBTOFRAC) + CDoom.fixed_mul(partial, xstep)

    # Step through map blocks.
    # Count is present to prevent a round off error
    # from skipping the break.
    mapx = xt1
    mapy = yt1

    64.times do |count|
      if flags & CDoom::PT_ADDLINES != 0
        if CDoom.p_block_lines_iterator(mapx, mapy, ->CDoom.pit_add_line_intercepts) == 0
          return 0 # early out
        end
      end

      if flags & CDoom::PT_ADDTHINGS != 0
        if CDoom.p_block_things_iterator(mapx, mapy, ->CDoom.pit_add_thing_intercepts) == 0
          return 0 # early out
        end
      end

      break if mapx == xt2 && mapy == yt2

      if (yintercept >> FRACBITS) == mapy
        yintercept += ystep
        mapx += mapxstep
      elsif (xintercept >> FRACBITS) == mapx
        xintercept += xstep
        mapy += mapystep
      end
    end

    # go through the sorted list
    return CDoom.p_traverse_intercepts(trav, FRACUNIT)
  end

  def self.p_set_mobj_state(mobj : CDoom::Mobj*, state : CDoom::Statenum) : CDoom::DoomBool
    loop do
      if state == CDoom::Statenum::S_NULL
        mobj.value.state = Pointer(CDoom::State).new(CDoom::Statenum::S_NULL.value.to_u64!)
        CDoom.p_remove_mobj(mobj)
        return 0
      end

      st = CDoom.states + state.value
      mobj.value.state = st
      mobj.value.tics = st.value.tics
      mobj.value.sprite = st.value.sprite
      mobj.value.frame = st.value.frame

      # Modified handling.
      # Call action functions when the state is set
      if !st.value.action.null?
        CDoom::ActionfP1.new(st.value.action, Pointer(Void).null).call(mobj.as(Void*))
      end

      state = st.value.nextstate
      break unless mobj.value.tics == 0
    end

    return 1
  end

  def self.p_explode_missile(mo : CDoom::Mobj*)
    mo.value.momx = 0
    mo.value.momy = 0
    mo.value.momz = 0

    CDoom.p_set_mobj_state(mo, CDoom::Statenum.new(CDoom.mobjinfo[mo.value.type.value].deathstate))

    mo.value.tics = mo.value.tics - (CDoom.p_random & 3)

    mo.value.tics = 1 if mo.value.tics < 1

    mo.value.flags = mo.value.flags & ~CDoom::Mobjflag::MF_MISSILE.value

    CDoom.s_start_sound(mo, mo.value.info.value.deathsound) if mo.value.info.value.deathsound != 0
  end

  def self.p_xymovement(mo : CDoom::Mobj*)
    if mo.value.momx == 0 && mo.value.momy == 0
      if mo.value.flags & CDoom::Mobjflag::MF_SKULLFLY.value != 0
        # the skull slammed into something
        mo.value.flags = mo.value.flags & ~CDoom::Mobjflag::MF_SKULLFLY.value
        mo.value.momx = 0
        mo.value.momy = 0
        mo.value.momz = 0

        CDoom.p_set_mobj_state(mo, CDoom::Statenum.new(mo.value.info.value.spawnstate))
      end
      return
    end

    player = mo.value.player

    if mo.value.momx > CDoom::MAXMOVE
      mo.value.momx = CDoom::MAXMOVE
    elsif mo.value.momx < -CDoom::MAXMOVE
      mo.value.momx = -CDoom::MAXMOVE
    end

    if mo.value.momy > CDoom::MAXMOVE
      mo.value.momy = CDoom::MAXMOVE
    elsif mo.value.momy < -CDoom::MAXMOVE
      mo.value.momy = -CDoom::MAXMOVE
    end

    xmove = mo.value.momx
    ymove = mo.value.momy

    loop do
      if xmove > CDoom::MAXMOVE // 2 || ymove > CDoom::MAXMOVE // 2
        ptryx = mo.value.x &+ xmove.tdiv(2)
        ptryy = mo.value.y &+ ymove.tdiv(2)
        xmove >>= 1
        ymove >>= 1
      else
        ptryx = mo.value.x &+ xmove
        ptryy = mo.value.y &+ ymove
        xmove = 0
        ymove = 0
      end

      if CDoom.p_try_move(mo, ptryx, ptryy) == 0
        # blocked move
        if !mo.value.player.null?
          CDoom.p_slide_move(mo) # try to slide along it
        elsif mo.value.flags & CDoom::Mobjflag::MF_MISSILE.value != 0
          # explode a missile
          if !CDoom.ceilingline.null? &&
             !CDoom.ceilingline.value.backsector.null? &&
             CDoom.ceilingline.value.backsector.value.ceilingpic == CDoom.skyflatnum
            # Hack to prevent missiles exploding
            # against the sky.
            # Does not handle sky floors.
            CDoom.p_remove_mobj(mo)
            return
          end
          CDoom.p_explode_missile(mo)
        else
          mo.value.momx = 0
          mo.value.momy = 0
        end
      end

      break unless xmove != 0 || ymove != 0
    end

    # slow down
    if !player.null? && player.value.cheats & CDoom::Cheat::CF_NOMOMENTUM.value != 0
      # debug option for no sliding at all
      mo.value.momx = 0
      mo.value.momy = 0
      return
    end

    # no friction for missiles ever
    return if mo.value.flags & (CDoom::Mobjflag::MF_MISSILE.value | CDoom::Mobjflag::MF_SKULLFLY.value) != 0

    # no friction when airborne
    return if mo.value.z > mo.value.floorz

    if (mo.value.flags & CDoom::Mobjflag::MF_CORPSE.value != 0) &&
       (mo.value.momx > FRACUNIT.tdiv(4) ||
       mo.value.momx < -FRACUNIT.tdiv(4) ||
       mo.value.momy > FRACUNIT.tdiv(4) ||
       mo.value.momy < -FRACUNIT.tdiv(4)) &&
       (mo.value.floorz != mo.value.subsector.value.sector.value.floorheight)
      # do not stop sliding
      # if halfway off a step with some momentum
      return
    end

    if mo.value.momx > -CDoom::STOPSPEED &&
       mo.value.momx < CDoom::STOPSPEED &&
       mo.value.momy > -CDoom::STOPSPEED &&
       mo.value.momy < CDoom::STOPSPEED &&
       (player.null? || (
         player.value.cmd.forwardmove == 0 &&
         player.value.cmd.sidemove == 0
       ))
      # if in a walking frame, stop moving
      if !player.null? && ((player.value.mo.value.state - CDoom.states) - CDoom::Statenum::S_PLAY_RUN1.value).to_u32! < 4
        CDoom.p_set_mobj_state(player.value.mo, CDoom::Statenum::S_PLAY)
      end

      mo.value.momx = 0
      mo.value.momy = 0
    else
      mo.value.momx = CDoom.fixed_mul(mo.value.momx, CDoom::FRICTION)
      mo.value.momy = CDoom.fixed_mul(mo.value.momy, CDoom::FRICTION)
    end
  end

  def self.p_zmovement(mo : CDoom::Mobj*)
    # check for smooth step up
    if !mo.value.player.null? && mo.value.z < mo.value.floorz
      mo.value.player.value.viewheight = mo.value.player.value.viewheight - (mo.value.floorz - mo.value.z)

      mo.value.player.value.deltaviewheight = (CDoom::VIEWHEIGHT - mo.value.player.value.viewheight) >> 3
    end

    # adjust height
    mo.value.z = mo.value.z + mo.value.momz

    if mo.value.flags & CDoom::Mobjflag::MF_FLOAT.value != 0 &&
       !mo.value.target.null?
      # float down towards target if too close
      if mo.value.flags & CDoom::Mobjflag::MF_SKULLFLY.value == 0 &&
         mo.value.flags & CDoom::Mobjflag::MF_INFLOAT.value == 0
        dist = CDoom.p_aprox_distance(mo.value.x - mo.value.target.value.x,
          mo.value.y - mo.value.target.value.y)

        delta = (mo.value.target.value.z + (mo.value.height >> 1)) - mo.value.z

        if delta < 0 && dist < -(delta * 3)
          mo.value.z = mo.value.z - CDoom::FLOATSPEED
        elsif delta > 0 && dist < (delta * 3)
          mo.value.z = mo.value.z + CDoom::FLOATSPEED
        end
      end
    end

    # clip movement
    if mo.value.z <= mo.value.floorz
      # hit the floor

      # Note (id):
      #  somebody left this after the setting momz to 0,
      #  kinda useless there.
      if mo.value.flags & CDoom::Mobjflag::MF_SKULLFLY.value != 0
        # the skull slammed into something
        mo.value.momz = -mo.value.momz
      end

      if mo.value.momz < 0
        if !mo.value.player.null? &&
           mo.value.momz < -CDoom::GRAVITY * 8
          # Squat down.
          # Decrease viewheight for a moment
          # after hitting the ground (hard),
          # and utter appropriate sound.
          mo.value.player.value.deltaviewheight = mo.value.momz >> 3
          CDoom.s_start_sound(mo, CDoom::Sfxenum::SFX_oof.value)
        end
        mo.value.momz = 0
      end
      mo.value.z = mo.value.floorz

      if mo.value.flags & CDoom::Mobjflag::MF_MISSILE.value != 0 &&
         mo.value.flags & CDoom::Mobjflag::MF_NOCLIP.value == 0
        CDoom.p_explode_missile(mo)
        return
      end
    elsif mo.value.flags & CDoom::Mobjflag::MF_NOGRAVITY.value == 0
      if mo.value.momz == 0
        mo.value.momz = -CDoom::GRAVITY * 2
      else
        mo.value.momz = mo.value.momz - CDoom::GRAVITY
      end
    end

    if mo.value.z + mo.value.height > mo.value.ceilingz
      # hit the ceiling
      mo.value.momz = 0 if mo.value.momz > 0
      mo.value.z = mo.value.ceilingz - mo.value.height

      if mo.value.flags & CDoom::Mobjflag::MF_SKULLFLY.value != 0
        # the skull slammed into something
        mo.value.momz = -mo.value.momz
      end

      if mo.value.flags & CDoom::Mobjflag::MF_MISSILE.value != 0 &&
         mo.value.flags & CDoom::Mobjflag::MF_NOCLIP.value == 0
        CDoom.p_explode_missile(mo)
        return
      end
    end
  end

  def self.p_nightmare_respawn(mobj : CDoom::Mobj*)
    x = mobj.value.spawnpoint.x.to_i32 << FRACBITS
    y = mobj.value.spawnpoint.y.to_i32 << FRACBITS

    # somthing is occupying it's position?
    return if CDoom.p_check_position(mobj, x, y) == 0 # no respwan

    # spawn a teleport fog at old spot
    # because of removal of the body?
    mo = CDoom.p_spawn_mobj(mobj.value.x,
      mobj.value.y,
      mobj.value.subsector.value.sector.value.floorheight, CDoom::Mobjtype::MT_TFOG)
    # initiate teleport sound
    CDoom.s_start_sound(mo, CDoom::Sfxenum::SFX_telept.value)

    # spawn a teleport fog at the new spot
    ss = CDoom.r_point_in_subsector(x, y)

    mo = CDoom.p_spawn_mobj(x, y, ss.value.sector.value.floorheight, CDoom::Mobjtype::MT_TFOG)

    CDoom.s_start_sound(mo, CDoom::Sfxenum::SFX_telept.value)

    # spawn the new monster
    mthing = pointerof(mobj.value.@spawnpoint)

    # spawn it
    if mobj.value.info.value.flags & CDoom::Mobjflag::MF_SPAWNCEILING.value != 0
      z = CDoom::ONCEILINGZ
    else
      z = CDoom::ONFLOORZ
    end

    # inherit attributes from deceased one
    mo = CDoom.p_spawn_mobj(x, y, z, mobj.value.type)
    mo.value.spawnpoint = mobj.value.spawnpoint
    mo.value.angle = ANG45 &* (mthing.value.angle.tdiv(45))

    if mthing.value.options & CDoom::MTF_AMBUSH != 0
      mo.value.flags = mo.value.flags | CDoom::Mobjflag::MF_AMBUSH.value
    end

    mo.value.reactiontime = 18

    # remove the old monster,
    CDoom.p_remove_mobj(mobj)
  end

  def self.p_mobj_thinker(mobj : CDoom::Mobj*)
    mobj = mobj.as(CDoom::Mobj*)
    # momentum movement
    if mobj.value.momx != 0 ||
       mobj.value.momy != 0 ||
       (mobj.value.flags & CDoom::Mobjflag::MF_SKULLFLY.value != 0)
      CDoom.p_xymovement(mobj)

      return if mobj.value.thinker.remove != 0 # mobj was removed
    end
    if mobj.value.z != mobj.value.floorz ||
       mobj.value.momz != 0
      CDoom.p_zmovement(mobj)

      return if mobj.value.thinker.remove != 0 # mobj was removed
    end

    # cycle through states,
    # calling action functions at transitions
    if mobj.value.tics != -1
      mobj.value.tics = mobj.value.tics - 1

      # you can cycle through multiple states in a tic
      if mobj.value.tics == 0 &&
         CDoom.p_set_mobj_state(mobj, CDoom::Statenum.new(mobj.value.state.value.nextstate)) == 0
        return # freed itself
      end
    else
      # check for nightmare respawn
      return if mobj.value.flags & CDoom::Mobjflag::MF_COUNTKILL.value == 0

      return if CDoom.respawnmonsters == 0

      mobj.value.movecount = mobj.value.movecount + 1

      return if mobj.value.movecount < 12 * 35

      return if CDoom.leveltime & 31 != 0

      return if CDoom.p_random > 4

      CDoom.p_nightmare_respawn(mobj)
    end
  end

  def self.p_spawn_mobj(x : CDoom::Fixed, y : CDoom::Fixed, z : CDoom::Fixed, type : CDoom::Mobjtype) : CDoom::Mobj*
    mobj = CDoom.z_malloc(sizeof(CDoom::Mobj), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Mobj*)
    CDoom.doom_memset(mobj, 0, sizeof(CDoom::Mobj))
    info = CDoom.mobjinfo + type.value

    mobj.value.type = type
    mobj.value.info = info
    mobj.value.x = x
    mobj.value.y = y
    mobj.value.radius = info.value.radius
    mobj.value.height = info.value.height
    mobj.value.flags = info.value.flags
    mobj.value.health = info.value.spawnhealth

    mobj.value.reactiontime = info.value.reactiontime if CDoom.gameskill != CDoom::Skill::Nightmare

    mobj.value.lastlook = CDoom.p_random % CDoom::MAXPLAYERS
    # do not set the state with p_set_mobj_state,
    # because action routines can not be called yet
    st = CDoom.states + info.value.spawnstate

    mobj.value.state = st
    mobj.value.tics = st.value.tics
    mobj.value.sprite = st.value.sprite
    mobj.value.frame = st.value.frame

    # set subsector and/or block links
    CDoom.p_set_thing_position(mobj)

    mobj.value.floorz = mobj.value.subsector.value.sector.value.floorheight
    mobj.value.ceilingz = mobj.value.subsector.value.sector.value.ceilingheight

    if z == CDoom::ONFLOORZ
      mobj.value.z = mobj.value.floorz
    elsif z == CDoom::ONCEILINGZ
      mobj.value.z = mobj.value.ceilingz - mobj.value.info.value.height
    else
      mobj.value.z = z
    end

    pointerof(mobj.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.p_mobj_thinker).pointer, Pointer(Void).null)

    CDoom.p_add_thinker(pointerof(mobj.value.@thinker))

    return mobj
  end

  def self.p_remove_mobj(mobj : CDoom::Mobj*)
    if mobj.value.flags & CDoom::Mobjflag::MF_SPECIAL.value != 0 &&
       mobj.value.flags & CDoom::Mobjflag::MF_DROPPED.value == 0 &&
       mobj.value.type != CDoom::Mobjtype::MT_INV &&
       mobj.value.type != CDoom::Mobjtype::MT_INS
      CDoom.itemrespawnque[CDoom.iquehead] = mobj.value.spawnpoint
      CDoom.itemrespawntime[CDoom.iquehead] = CDoom.leveltime
      CDoom.iquehead = (CDoom.iquehead + 1) & (CDoom::ITEMQUESIZE - 1)

      # lose one off the end?
      CDoom.iquetail = (CDoom.iquetail + 1) & (CDoom::ITEMQUESIZE - 1) if CDoom.iquehead == CDoom.iquetail
    end

    # unlink from sector and block lists
    CDoom.p_unset_thing_position(mobj)

    # stop any playing sound
    CDoom.s_stop_sound(mobj)

    # free block
    CDoom.p_remove_thinker(mobj.as(CDoom::Thinker*))
  end

  def self.p_respawn_specials
    # only respawn items in deathmatch
    return if CDoom.deathmatch != 2

    # nothing left to respawn?
    return if CDoom.iquehead == CDoom.iquetail

    # wait at least 30 seconds
    return if CDoom.leveltime - CDoom.itemrespawntime[CDoom.iquetail] < 30 * 35

    mthing = CDoom.itemrespawnque.to_unsafe + CDoom.iquetail

    x = mthing.value.x.to_i32 << FRACBITS
    y = mthing.value.y.to_i32 << FRACBITS

    # spawn a teleport fog at the new spot
    ss = CDoom.r_point_in_subsector(x, y)

    mo = CDoom.p_spawn_mobj(x, y, ss.value.sector.value.floorheight, CDoom::Mobjtype::MT_IFOG)
    CDoom.s_start_sound(mo, CDoom::Sfxenum::SFX_itmbk.value)

    # find which type to spawn
    i = 0
    while i < CDoom::Mobjtype::NUMMOBJTYPES.value
      break if mthing.value.type == CDoom.mobjinfo[i].doomednum
      i += 1
    end

    # spawn it
    if CDoom.mobjinfo[i].flags & CDoom::Mobjflag::MF_SPAWNCEILING.value != 0
      z = CDoom::ONCEILINGZ
    else
      z = CDoom::ONFLOORZ
    end

    mo = CDoom.p_spawn_mobj(x, y, z, CDoom::Mobjtype.new(i))
    mo.value.spawnpoint = mthing.value
    mo.value.angle = ANG45 &* (mthing.value.angle.tdiv(45))

    # pull it from the que
    CDoom.iquetail = (CDoom.iquetail + 1) & (CDoom::ITEMQUESIZE - 1)
  end

  #
  # Called when a player is spawned on the level.
  # Most of the player structure stays unchanged
  # between levels.
  #
  def self.p_spawn_player(mthing : CDoom::Mapthing*)
    # not playing?
    return if CDoom.playeringame[mthing.value.type - 1] == 0

    p = CDoom.players.to_unsafe + mthing.value.type - 1

    if p.value.playerstate == CDoom::Playerstate::PST_REBORN
      CDoom.g_player_reborn(mthing.value.type - 1)
    end

    x = mthing.value.x.to_i32 << FRACBITS
    y = mthing.value.y.to_i32 << FRACBITS
    z = CDoom::ONFLOORZ
    mobj = CDoom.p_spawn_mobj(x, y, z, CDoom::Mobjtype::MT_PLAYER)

    # set color translations for player sprites
    if mthing.value.type > 1
      mobj.value.flags = mobj.value.flags | ((mthing.value.type - 1).to_i32 << CDoom::Mobjflag::MF_TRANSSHIFT.value)
    end

    mobj.value.angle = ANG45 &* (mthing.value.angle.tdiv(45))
    mobj.value.player = p
    mobj.value.health = p.value.health

    p.value.mo = mobj
    p.value.playerstate = CDoom::Playerstate::PST_LIVE
    p.value.refire = 0
    p.value.message = Pointer(UInt8).null
    p.value.damagecount = 0
    p.value.bonuscount = 0
    p.value.extralight = 0
    p.value.fixedcolormap = 0
    p.value.viewheight = CDoom::VIEWHEIGHT

    # setup gun psprite
    CDoom.p_setup_psprites(p)

    # give all cards in death match mode
    if CDoom.deathmatch != 0
      CDoom::Card::NUMCARDS.value.times do |i|
        p.value.cards[i] = 1
      end
    end

    if mthing.value.type - 1 == CDoom.consoleplayer
      # wake up the status bar
      CDoom.st_start
      # wake up the heads up text
      CDoom.hu_start
    end
  end

  #
  # The fields of the mapthing should
  # already be in host byte order.
  #
  def self.p_spawn_map_thing(mthing : CDoom::Mapthing*)
    # count deathmatch start positions
    if mthing.value.type == 11
      if CDoom.deathmatch_p < CDoom.deathmatchstarts.to_unsafe + 10
        CDoom.doom_memcpy(CDoom.deathmatch_p, mthing, sizeof(CDoom::Mapthing))
        CDoom.deathmatch_p += 1
      end
      return
    end

    # check for players specially
    if mthing.value.type <= 4
      # save spots for respawning in network games
      (CDoom.playerstarts.to_unsafe + (mthing.value.type - 1)).value = mthing.value
      CDoom.p_spawn_player(mthing) if CDoom.deathmatch == 0

      return
    end

    # check for apropriate skill level
    return if CDoom.netgame == 0 && mthing.value.options & 16 != 0

    if CDoom.gameskill == CDoom::Skill::Baby
      bit = 1
    elsif CDoom.gameskill == CDoom::Skill::Nightmare
      bit = 4
    else
      bit = 1 << (CDoom.gameskill.value - 1)
    end

    return if mthing.value.options & bit == 0

    # find which type to spawn
    i = 0
    while i < CDoom::Mobjtype::NUMMOBJTYPES.value
      break if mthing.value.type == CDoom.mobjinfo[i].doomednum
      i += 1
    end

    if i == CDoom::Mobjtype::NUMMOBJTYPES.value
      CDoom.i_error("Error: p_spawn_map_thing: Unknown type #{mthing.value.type} at (#{mthing.value.x},#{mthing.value.y})")
    end

    # don't spawn keycards and players in deathmatch
    return if CDoom.deathmatch != 0 && CDoom.mobjinfo[i].flags & CDoom::Mobjflag::MF_NOTDMATCH.value != 0

    # don't spawn any monsters if -nomonsters
    if CDoom.nomonsters != 0 &&
       (i == CDoom::Mobjtype::MT_SKULL.value ||
       (CDoom.mobjinfo[i].flags & CDoom::Mobjflag::MF_COUNTKILL.value != 0))
      return
    end

    # spawn it
    x = mthing.value.x.to_i32 << FRACBITS
    y = mthing.value.y.to_i32 << FRACBITS

    if CDoom.mobjinfo[i].flags & CDoom::Mobjflag::MF_SPAWNCEILING.value != 0
      z = CDoom::ONCEILINGZ
    else
      z = CDoom::ONFLOORZ
    end

    mobj = CDoom.p_spawn_mobj(x, y, z, CDoom::Mobjtype.new(i))
    mobj.value.spawnpoint = mthing.value

    if mobj.value.tics > 0
      mobj.value.tics = 1 + (CDoom.p_random % mobj.value.tics)
    end
    if mobj.value.flags & CDoom::Mobjflag::MF_COUNTKILL.value != 0
      CDoom.totalkills += 1
    end
    if mobj.value.flags & CDoom::Mobjflag::MF_COUNTITEM.value != 0
      CDoom.totalitems += 1
    end

    mobj.value.angle = ANG45 &* (mthing.value.angle.tdiv(45))
    if mthing.value.options & CDoom::MTF_AMBUSH != 0
      mobj.value.flags = mobj.value.flags | CDoom::Mobjflag::MF_AMBUSH.value
    end
  end

  #
  # GAME SPAWN FUNCTIONS
  #

  def self.p_spawn_puff(x : CDoom::Fixed, y : CDoom::Fixed, z : CDoom::Fixed)
    z += (CDoom.p_random - CDoom.p_random) << 10

    th = CDoom.p_spawn_mobj(x, y, z, CDoom::Mobjtype::MT_PUFF)
    th.value.momz = FRACUNIT
    th.value.tics = th.value.tics - (CDoom.p_random & 3)

    th.value.tics = 1 if th.value.tics < 1

    # don't make punches spark on the wall
    CDoom.p_set_mobj_state(th, CDoom::Statenum::S_PUFF3) if CDoom.attackrange == CDoom::MELEERANGE
  end

  def self.p_spawn_blood(x : CDoom::Fixed, y : CDoom::Fixed, z : CDoom::Fixed, damage : Int32)
    z += (CDoom.p_random - CDoom.p_random) << 10
    th = CDoom.p_spawn_mobj(x, y, z, CDoom::Mobjtype::MT_BLOOD)
    th.value.momz = FRACUNIT * 2
    th.value.tics = th.value.tics - (CDoom.p_random & 3)

    th.value.tics = 1 if th.value.tics < 1

    if damage <= 12 && damage >= 9
      CDoom.p_set_mobj_state(th, CDoom::Statenum::S_BLOOD2)
    elsif damage < 9
      CDoom.p_set_mobj_state(th, CDoom::Statenum::S_BLOOD3)
    end
  end

  #
  # Moves the missile forward a bit
  #  and possibly explodes it right there.
  #
  def self.p_check_missile_spawn(th : CDoom::Mobj*)
    th.value.tics = th.value.tics - (CDoom.p_random & 3)
    th.value.tics = 1 if th.value.tics < 1

    # move a little forward so an angle can
    # be computed if it immediately explodes
    th.value.x = th.value.x + (th.value.momx >> 1)
    th.value.y = th.value.y + (th.value.momy >> 1)
    th.value.z = th.value.z + (th.value.momz >> 1)

    CDoom.p_explode_missile(th) if CDoom.p_try_move(th, th.value.x, th.value.y) == 0
  end

  def self.p_spawn_missile(source : CDoom::Mobj*, dest : CDoom::Mobj*, type : CDoom::Mobjtype) : CDoom::Mobj*
    th = CDoom.p_spawn_mobj(source.value.x,
      source.value.y,
      source.value.z + 4 * 8 * FRACUNIT, type)

    CDoom.s_start_sound(th, th.value.info.value.seesound) if th.value.info.value.seesound != 0

    th.value.target = source # where it came from
    an = CDoom.r_point_to_angle2(source.value.x, source.value.y, dest.value.x, dest.value.y)

    # fuzzy player
    an &+= (CDoom.p_random - CDoom.p_random) << 20 if dest.value.flags & CDoom::Mobjflag::MF_SHADOW.value != 0

    th.value.angle = an
    an >>= CDoom::ANGLETOFINESHIFT
    th.value.momx = CDoom.fixed_mul(th.value.info.value.speed, @@finecosine[an])
    th.value.momy = CDoom.fixed_mul(th.value.info.value.speed, @@finesine[an])

    dist = CDoom.p_aprox_distance(dest.value.x - source.value.x, dest.value.y - source.value.y)
    dist = dist.tdiv(th.value.info.value.speed)

    dist = 1 if dist < 1

    th.value.momz = (dest.value.z - source.value.z).tdiv(dist)
    CDoom.p_check_missile_spawn(th)

    return th
  end

  #
  # Tries to aim at a nearby monster
  #
  def self.p_spawn_player_missile(source : CDoom::Mobj*, type : CDoom::Mobjtype)
    # see which target is to be aimed at
    an = source.value.angle
    slope = CDoom.p_aim_line_attack(source, an, 16 * 64 * FRACUNIT)

    if CDoom.linetarget.null?
      an &+= 1 << 26
      slope = CDoom.p_aim_line_attack(source, an, 16 * 64 * FRACUNIT)

      if CDoom.linetarget.null?
        an &-= 2 << 26
        slope = CDoom.p_aim_line_attack(source, an, 16 * 64 * FRACUNIT)
      end

      if CDoom.linetarget.null?
        an = source.value.angle
        slope = 0
      end
    end

    x = source.value.x
    y = source.value.y
    z = source.value.z + 4 * 8 * FRACUNIT

    th = CDoom.p_spawn_mobj(x, y, z, type)

    CDoom.s_start_sound(th, th.value.info.value.seesound) if th.value.info.value.seesound != 0

    th.value.target = source
    th.value.angle = an
    th.value.momx = CDoom.fixed_mul(th.value.info.value.speed,
      @@finecosine[an >> CDoom::ANGLETOFINESHIFT])
    th.value.momy = CDoom.fixed_mul(th.value.info.value.speed,
      @@finesine[an >> CDoom::ANGLETOFINESHIFT])
    th.value.momz = CDoom.fixed_mul(th.value.info.value.speed, slope)

    CDoom.p_check_missile_spawn(th)
  end

  #
  # Move a plat up and down
  #
  def self.t_plat_raise(plat : CDoom::Plat*)
    case plat.value.status
    when CDoom::Platenum::Up
      res = CDoom.t_move_plane(plat.value.sector,
        plat.value.speed,
        plat.value.high,
        plat.value.crush, 0, 1)

      if plat.value.type == CDoom::Plattype::RaiseAndChange ||
         plat.value.type == CDoom::Plattype::RaiseToNearestAndChange
        CDoom.s_start_sound(pointerof(plat.value.sector.value.@soundorg),
          CDoom::Sfxenum::SFX_stnmov) if CDoom.leveltime & 7 == 0
      end

      if res == CDoom::Result::Crushed && plat.value.crush == 0
        plat.value.count = plat.value.wait
        plat.value.status = CDoom::Platenum::Down
        CDoom.s_start_sound(pointerof(plat.value.sector.value.@soundorg),
          CDoom::Sfxenum::SFX_pstart)
      else
        if res == CDoom::Result::Pastdest
          plat.value.count = plat.value.wait
          plat.value.status = CDoom::Platenum::Waiting
          CDoom.s_start_sound(pointerof(plat.value.sector.value.@soundorg),
            CDoom::Sfxenum::SFX_pstop)

          case plat.value.type
          when CDoom::Plattype::BlazeDWUS, CDoom::Plattype::DownWaitUpStay
            CDoom.p_remove_active_plat(plat)
          when CDoom::Plattype::RaiseAndChange, CDoom::Plattype::RaiseToNearestAndChange
            CDoom.p_remove_active_plat(plat)
          end
        end
      end
    when CDoom::Platenum::Down
      res = CDoom.t_move_plane(plat.value.sector, plat.value.speed, plat.value.low, 0, 0, -1)

      if res == CDoom::Result::Pastdest
        plat.value.count = plat.value.wait
        plat.value.status = CDoom::Platenum::Waiting
        CDoom.s_start_sound(pointerof(plat.value.sector.value.@soundorg),
          CDoom::Sfxenum::SFX_pstop)
      end
    when CDoom::Platenum::Waiting
      plat.value.count = plat.value.count - 1
      if plat.value.count == 0
        if plat.value.sector.value.floorheight == plat.value.low
          plat.value.status = CDoom::Platenum::Up
        else
          plat.value.status = CDoom::Platenum::Down
        end
        CDoom.s_start_sound(pointerof(plat.value.sector.value.@soundorg),
          CDoom::Sfxenum::SFX_pstart)
      end
    when CDoom::Platenum::InStasis
    end
  end

  #
  # Do Platforms
  #  "amount" is only used for SOME platforms.
  #
  def self.ev_do_plat(line : CDoom::Line*, type : CDoom::Plattype, amount : LibC::Int) : LibC::Int
    secnum = -1
    rtn = 0

    # Activate all <type> plats that are in_stasis
    case type
    when CDoom::Plattype::PerpetualRaise
      CDoom.p_activate_in_stasis(line.value.tag)
    end

    while (secnum = CDoom.p_find_sector_from_line_tag(line, secnum)) >= 0
      sec = CDoom.sectors + secnum

      next if !sec.value.specialdata.null?

      # Find lowest & highest floors around sector
      rtn = 1
      plat = CDoom.z_malloc(sizeof(CDoom::Plat), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Plat*)
      CDoom.p_add_thinker(pointerof(plat.value.@thinker))

      plat.value.type = type
      plat.value.sector = sec
      plat.value.sector.value.specialdata = plat
      pointerof(plat.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_plat_raise).pointer, Pointer(Void).null)
      plat.value.crush = 0
      plat.value.tag = line.value.tag

      case type
      when CDoom::Plattype::RaiseToNearestAndChange
        plat.value.speed = CDoom::PLATSPEED // 2
        sec.value.floorpic = CDoom.sides[line.value.sidenum[0]].sector.value.floorpic
        plat.value.high = CDoom.p_find_next_highest_floor(sec, sec.value.floorheight)
        plat.value.wait = 0
        plat.value.status = CDoom::Platenum::Up
        # NO MORE DAMAGE, IF APPLICABLE
        sec.value.special = 0
        CDoom.s_start_sound(pointerof(sec.value.@soundorg),
          CDoom::Sfxenum::SFX_stnmov)
      when CDoom::Plattype::RaiseAndChange
        plat.value.speed = CDoom::PLATSPEED // 2
        sec.value.floorpic = CDoom.sides[line.value.sidenum[0]].sector.value.floorpic
        plat.value.high = sec.value.floorheight + amount * FRACUNIT
        plat.value.wait = 0
        plat.value.status = CDoom::Platenum::Up

        CDoom.s_start_sound(pointerof(sec.value.@soundorg),
          CDoom::Sfxenum::SFX_stnmov)
      when CDoom::Plattype::DownWaitUpStay
        plat.value.speed = CDoom::PLATSPEED * 4
        plat.value.low = CDoom.p_find_lowest_floor_surrounding(sec)

        plat.value.low = sec.value.floorheight if plat.value.low > sec.value.floorheight

        plat.value.high = sec.value.floorheight
        plat.value.wait = 35 * CDoom::PLATWAIT
        plat.value.status = CDoom::Platenum::Down
        CDoom.s_start_sound(pointerof(sec.value.@soundorg),
          CDoom::Sfxenum::SFX_pstart)
      when CDoom::Plattype::BlazeDWUS
        plat.value.speed = CDoom::PLATSPEED * 8
        plat.value.low = CDoom.p_find_lowest_floor_surrounding(sec)

        plat.value.low = sec.value.floorheight if plat.value.low > sec.value.floorheight

        plat.value.high = sec.value.floorheight
        plat.value.wait = 35 * CDoom::PLATWAIT
        plat.value.status = CDoom::Platenum::Down
        CDoom.s_start_sound(pointerof(sec.value.@soundorg),
          CDoom::Sfxenum::SFX_pstart)
      when CDoom::Plattype::PerpetualRaise
        plat.value.speed = CDoom::PLATSPEED
        plat.value.low = CDoom.p_find_lowest_floor_surrounding(sec)

        plat.value.low = sec.value.floorheight if plat.value.low > sec.value.floorheight

        plat.value.high = CDoom.p_find_highest_floor_surrounding(sec)

        plat.value.high = sec.value.floorheight if plat.value.high < sec.value.floorheight

        plat.value.wait = 35 * CDoom::PLATWAIT
        plat.value.status = CDoom::Platenum.new(CDoom.p_random & 1)
        CDoom.s_start_sound(pointerof(sec.value.@soundorg),
          CDoom::Sfxenum::SFX_pstart)
      end
      CDoom.p_add_active_plat(plat)
    end

    return rtn
  end

  def self.p_activate_in_stasis(tag : LibC::Int)
    CDoom::MAXPLATS.times do |i|
      if !CDoom.activeplats[i].null? &&
         CDoom.activeplats[i].value.tag == tag &&
         CDoom.activeplats[i].value.status == CDoom::Platenum::InStasis
        CDoom.activeplats[i].value.status = CDoom.activeplats[i].value.oldstatus
        pointerof(CDoom.activeplats[i].value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_plat_raise).pointer, Pointer(Void).null)
      end
    end
  end

  def self.ev_stop_plat(line : CDoom::Line*)
    CDoom::MAXPLATS.times do |i|
      if !CDoom.activeplats[i].null? &&
         CDoom.activeplats[i].value.status != CDoom::Platenum::InStasis &&
         CDoom.activeplats[i].value.tag == line.value.tag
        CDoom.activeplats[i].value.oldstatus = CDoom.activeplats[i].value.status
        CDoom.activeplats[i].value.status = CDoom::Platenum::InStasis
        pointerof(CDoom.activeplats[i].value.@thinker.@function).as(CDoom::ActionfV*).value = NULL_PROC
      end
    end
  end

  def self.p_add_active_plat(plat : CDoom::Plat*)
    CDoom::MAXPLATS.times do |i|
      if CDoom.activeplats[i].null?
        CDoom.activeplats[i] = plat
        return
      end
    end
    CDoom.i_error("Error: p_add_active_plat: no more plats!")
  end

  def self.p_remove_active_plat(plat : CDoom::Plat*)
    CDoom::MAXPLATS.times do |i|
      if plat == CDoom.activeplats[i]
        CDoom.activeplats[i].value.sector.value.specialdata = Pointer(Void).null
        CDoom.p_remove_thinker(pointerof(CDoom.activeplats[i].value.@thinker))
        CDoom.activeplats[i] = Pointer(CDoom::Plat).null

        return
      end
    end
    CDoom.i_error("Error: p_remove_active_plat: can't find plat!")
  end

  def self.p_set_psprite(player : CDoom::Player*, position : LibC::Int, stnum : CDoom::Statenum)
    psp = player.value.psprites.to_unsafe + position

    loop do
      if stnum.value == 0
        # object removed itself
        psp.value.state = Pointer(CDoom::State).null
        break
      end

      state = CDoom.states + stnum.value
      psp.value.state = state
      psp.value.tics = state.value.tics # could be 0

      if state.value.misc1 != 0
        # coordinate set
        psp.value.sx = state.value.misc1 << FRACBITS
        psp.value.sy = state.value.misc2 << FRACBITS
      end

      # Call action routine.
      # Modified handling.
      if !state.value.action.null?
        CDoom::ActionfP2.new(state.value.action, Pointer(Void).null).call(player.as(Void*), psp.as(Void*))
        break if psp.value.state.null?
      end

      stnum = psp.value.state.value.nextstate

      break unless psp.value.tics == 0
    end
    # an initial state of 0 could cycle through
  end

  #
  # Starts bringing the pending weapon up
  # from the bottom of the screen.
  # Uses player
  #
  def self.p_bring_up_weapon(player : CDoom::Player*)
    player.value.pendingweapon = player.value.readyweapon if player.value.pendingweapon == CDoom::Weapontype::Nochange

    CDoom.s_start_sound(player.value.mo, CDoom::Sfxenum::SFX_sawup.value) if player.value.pendingweapon == CDoom::Weapontype::Chainsaw

    newstate = CDoom.weaponinfo[player.value.pendingweapon.value].upstate

    player.value.pendingweapon = CDoom::Weapontype::Nochange
    (player.value.psprites.to_unsafe + CDoom::Psprnum::Weapon.value).value.sy = CDoom::WEAPONBOTTOM

    CDoom.p_set_psprite(player, CDoom::Psprnum::Weapon, CDoom::Statenum.new(newstate))
  end

  #
  # Returns true if there is enough ammo to shoot.
  # If not, selects the next weapon to use.
  #
  def self.p_check_ammo(player : CDoom::Player*) : CDoom::DoomBool
    ammo = CDoom::Ammotype.new(CDoom.weaponinfo[player.value.readyweapon.value].ammo)

    # Minimal amount for one shot varies.
    if player.value.readyweapon == CDoom::Weapontype::Bfg
      count = @@deh_bfg_cells_per_shot
    elsif player.value.readyweapon == CDoom::Weapontype::Supershotgun
      count = 2 # Double barrel.
    else
      count = 1 # Regular.
    end

    # Some do not need ammunition anyway.
    # Return if current ammunition sufficient.
    return 1 if ammo == CDoom::Ammotype::Noammo || player.value.ammo[ammo.value] >= count

    # Out of ammo, pick a weapon to change to.
    # Preferences are set here.
    loop do
      if player.value.weaponowned[CDoom::Weapontype::Plasma.value] != 0 &&
         player.value.ammo[CDoom::Ammotype::Cell.value] != 0 &&
         CDoom.gamemode != CDoom::GameMode::Shareware
        player.value.pendingweapon = CDoom::Weapontype::Plasma
      elsif player.value.weaponowned[CDoom::Weapontype::Supershotgun.value] != 0 &&
            player.value.ammo[CDoom::Ammotype::Shell.value] > 2 &&
            CDoom.gamemode == CDoom::GameMode::Commercial
        player.value.pendingweapon = CDoom::Weapontype::Supershotgun
      elsif player.value.weaponowned[CDoom::Weapontype::Chaingun.value] != 0 &&
            player.value.ammo[CDoom::Ammotype::Clip.value] != 0
        player.value.pendingweapon = CDoom::Weapontype::Chaingun
      elsif player.value.weaponowned[CDoom::Weapontype::Shotgun.value] != 0 &&
            player.value.ammo[CDoom::Ammotype::Shell.value] != 0
        player.value.pendingweapon = CDoom::Weapontype::Shotgun
      elsif player.value.ammo[CDoom::Ammotype::Clip.value] != 0
        player.value.pendingweapon = CDoom::Weapontype::Pistol
      elsif player.value.weaponowned[CDoom::Weapontype::Chainsaw.value] != 0
        player.value.pendingweapon = CDoom::Weapontype::Chainsaw
      elsif player.value.weaponowned[CDoom::Weapontype::Missile.value] != 0 &&
            player.value.ammo[CDoom::Ammotype::Misl.value] != 0
        player.value.pendingweapon = CDoom::Weapontype::Missile
      elsif player.value.weaponowned[CDoom::Weapontype::Bfg.value] != 0 &&
            player.value.ammo[CDoom::Ammotype::Cell.value] > 40 &&
            CDoom.gamemode != CDoom::GameMode::Shareware
        player.value.pendingweapon = CDoom::Weapontype::Bfg
      else
        # If everything fails.
        player.value.pendingweapon = CDoom::Weapontype::Fist
      end

      break unless player.value.pendingweapon == CDoom::Weapontype::Nochange
    end

    # Now set appropriate weapon overlay.
    CDoom.p_set_psprite(player,
      CDoom::Psprnum::Weapon,
      CDoom::Statenum.new(CDoom.weaponinfo[player.value.readyweapon.value].downstate))

    return 0
  end

  def self.p_fire_weapon(player : CDoom::Player*)
    return if CDoom.p_check_ammo(player) == 0

    CDoom.p_set_mobj_state(player.value.mo, CDoom::Statenum::S_PLAY_ATK1)
    newstate = CDoom::Statenum.new(CDoom.weaponinfo[player.value.readyweapon.value].atkstate)
    CDoom.p_set_psprite(player, CDoom::Psprnum::Weapon, newstate)
    CDoom.p_noise_alert(player.value.mo, player.value.mo)

    # Pause gun bobbing based off setting
    if @@weaponfirecentered != 0
      psp = player.value.psprites.to_unsafe + CDoom::Psprnum::Weapon.value
      psp.value.sx = FRACUNIT
      psp.value.sy = CDoom::WEAPONTOP
    end
  end

  #
  # Player died, so put the weapon away.
  #
  def self.p_drop_weapon(player : CDoom::Player*)
    CDoom.p_set_psprite(player,
      CDoom::Psprnum::Weapon,
      CDoom::Statenum.new(CDoom.weaponinfo[player.value.readyweapon.value].downstate))
  end

  #
  # The player can fire the weapon
  # or change to another weapon at this time.
  # Follows after getting weapon up,
  # or after previous attack/fire sequence.
  #
  def self.a_weapon_ready(player : CDoom::Player*, psp : CDoom::Pspdef*)
    # get out of attack state
    if player.value.mo.value.state == CDoom.states + CDoom::Statenum::S_PLAY_ATK1.value ||
       player.value.mo.value.state == CDoom.states + CDoom::Statenum::S_PLAY_ATK2.value
      CDoom.p_set_mobj_state(player.value.mo, CDoom::Statenum::S_PLAY)
    end

    if player.value.readyweapon == CDoom::Weapontype::Chainsaw &&
       psp.value.state == CDoom.states + CDoom::Statenum::S_SAW.value
      CDoom.s_start_sound(player.value.mo, CDoom::Sfxenum::SFX_sawidl.value)
    end

    # check for change
    #  if player is dead, put the weapon away
    if player.value.pendingweapon != CDoom::Weapontype::Nochange || player.value.health == 0
      # change weapon
      #  (pending weapon should allready be validated)
      newstate = CDoom::Statenum.new(CDoom.weaponinfo[player.value.readyweapon.value].downstate)
      CDoom.p_set_psprite(player, CDoom::Psprnum::Weapon, newstate)
      return
    end

    # check for fire
    #  the missile launcher and bfg do not auto fire
    if player.value.cmd.buttons & CDoom::Buttoncode::BT_ATTACK.value != 0
      if player.value.attackdown == 0 ||
         (player.value.readyweapon != CDoom::Weapontype::Missile &&
         player.value.readyweapon != CDoom::Weapontype::Bfg)
        player.value.attackdown = 1
        CDoom.p_fire_weapon(player)
        return
      end
    else
      player.value.attackdown = 0
    end

    # bob the weapon based on movement speed
    angle = (128 * CDoom.leveltime) & CDoom::FINEMASK
    psp.value.sx = FRACUNIT + CDoom.fixed_mul(player.value.bob, @@finecosine[angle])
    angle &= CDoom::FINEANGLES.tdiv(2) - 1
    psp.value.sy = CDoom::WEAPONTOP + CDoom.fixed_mul(player.value.bob, @@finesine[angle])
  end

  #
  # The player can re-fire the weapon
  # without lowering it entirely.
  #
  def self.a_refire(player : CDoom::Player*, psp : CDoom::Pspdef*)
    # check for fire
    #  (if a weaponchange is pending, let it go through instead)
    if (player.value.cmd.buttons & CDoom::Buttoncode::BT_ATTACK.value != 0) &&
       player.value.pendingweapon == CDoom::Weapontype::Nochange &&
       player.value.health != 0
      player.value.refire = player.value.refire + 1
      CDoom.p_fire_weapon(player)
    else
      player.value.refire = 0
      CDoom.p_check_ammo(player)
    end
  end

  def self.a_check_reload(player : CDoom::Player*, psp : CDoom::Pspdef*)
    CDoom.p_check_ammo(player)
  end

  #
  # Lowers current weapon,
  #  and changes weapon at bottom.
  #
  def self.a_lower(player : CDoom::Player*, psp : CDoom::Pspdef*)
    psp.value.sy = psp.value.sy + CDoom::LOWERSPEED

    # Is already down.
    return if psp.value.sy < CDoom::WEAPONBOTTOM

    # Player is dead.
    if player.value.playerstate == CDoom::Playerstate::PST_DEAD
      psp.value.sy = CDoom::WEAPONBOTTOM

      # don't bring weapon back up
      return
    end

    # The old weapon has been lowered off the screen,
    # so change the weapon and start raising it
    if player.value.health == 0
      # Player is dead, so keep the weapon off screen.
      CDoom.p_set_psprite(player, CDoom::Psprnum::Weapon, CDoom::Statenum::S_NULL)
      return
    end

    player.value.readyweapon = player.value.pendingweapon

    CDoom.p_bring_up_weapon(player)
  end

  def self.a_raise(player : CDoom::Player*, psp : CDoom::Pspdef*)
    psp.value.sy = psp.value.sy - CDoom::RAISESPEED

    return if psp.value.sy > CDoom::WEAPONTOP

    psp.value.sy = CDoom::WEAPONTOP

    # The weapon has been raised all the way,
    #  so change to the ready state.
    newstate = CDoom::Statenum.new(CDoom.weaponinfo[player.value.readyweapon.value].readystate)

    CDoom.p_set_psprite(player, CDoom::Psprnum::Weapon, newstate)
  end

  def self.a_gun_flash(player : CDoom::Player*, psp : CDoom::Pspdef*)
    CDoom.p_set_mobj_state(player.value.mo, CDoom::Statenum::S_PLAY_ATK2)
    CDoom.p_set_psprite(player, CDoom::Psprnum::Flash, CDoom::Statenum.new(CDoom.weaponinfo[player.value.readyweapon.value].flashstate))
  end

  #
  # WEAPON ATTACKS
  #

  def self.a_punch(player : CDoom::Player*, psp : CDoom::Pspdef*)
    damage = (CDoom.p_random % 10 + 1) << 1

    damage *= 10 if player.value.powers[CDoom::Powertype::Strength.value] != 0

    angle = player.value.mo.value.angle
    angle &+= (CDoom.p_random - CDoom.p_random) << 18
    slope = CDoom.p_aim_line_attack(player.value.mo, angle, CDoom::MELEERANGE)
    CDoom.p_line_attack(player.value.mo, angle, CDoom::MELEERANGE, slope, damage)

    # turn to face target
    if !CDoom.linetarget.null?
      CDoom.s_start_sound(player.value.mo, CDoom::Sfxenum::SFX_punch.value)
      player.value.mo.value.angle = CDoom.r_point_to_angle2(player.value.mo.value.x,
        player.value.mo.value.y,
        CDoom.linetarget.value.x,
        CDoom.linetarget.value.y)
    end
  end

  def self.a_saw(player : CDoom::Player*, psp : CDoom::Pspdef*)
    damage = 2 * (CDoom.p_random % 10 + 1)
    angle = player.value.mo.value.angle
    angle &+= (CDoom.p_random - CDoom.p_random) << 18

    # use meleerange + 1 se the puff doesn't skip the flash
    slope = CDoom.p_aim_line_attack(player.value.mo, angle, CDoom::MELEERANGE + 1)
    CDoom.p_line_attack(player.value.mo, angle, CDoom::MELEERANGE + 1, slope, damage)

    if CDoom.linetarget.null?
      CDoom.s_start_sound(player.value.mo, CDoom::Sfxenum::SFX_sawful.value)
      return
    end
    CDoom.s_start_sound(player.value.mo, CDoom::Sfxenum::SFX_sawhit.value)

    # turn to face target
    angle = CDoom.r_point_to_angle2(player.value.mo.value.x,
      player.value.mo.value.y,
      CDoom.linetarget.value.x,
      CDoom.linetarget.value.y)
    if angle &- player.value.mo.value.angle > ANG180
      if angle &- player.value.mo.value.angle < (-ANG90).tdiv(20)
        player.value.mo.value.angle = angle &+ ANG90.tdiv(21)
      else
        player.value.mo.value.angle = player.value.mo.value.angle &- ANG90.tdiv(20)
      end
    else
      if angle &- player.value.mo.value.angle > ANG90.tdiv(20)
        player.value.mo.value.angle = angle &- ANG90.tdiv(21)
      else
        player.value.mo.value.angle = player.value.mo.value.angle &+ ANG90.tdiv(20)
      end
    end
    player.value.mo.value.flags = player.value.mo.value.flags | CDoom::Mobjflag::MF_JUSTATTACKED.value
  end

  def self.a_fire_missile(player : CDoom::Player*, psp : CDoom::Pspdef*)
    player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] =
      player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] - 1
    CDoom.p_spawn_player_missile(player.value.mo, CDoom::Mobjtype::MT_ROCKET)
  end

  def self.a_fire_bfg(player : CDoom::Player*, psp : CDoom::Pspdef*)
    player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] =
      player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] - @@deh_bfg_cells_per_shot
    CDoom.p_spawn_player_missile(player.value.mo, CDoom::Mobjtype::MT_BFG)
  end

  def self.a_fire_plasma(player : CDoom::Player*, psp : CDoom::Pspdef*)
    player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] =
      player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] - 1
    CDoom.p_set_psprite(player,
      CDoom::Psprnum::Flash,
      CDoom::Statenum.new(CDoom.weaponinfo[player.value.readyweapon.value].flashstate + (CDoom.p_random & 1)))

    CDoom.p_spawn_player_missile(player.value.mo, CDoom::Mobjtype::MT_PLASMA)
  end

  #
  # Sets a slope so a near miss is at aproximately
  # the height of the intended target
  #
  def self.p_bullet_slope(mo : CDoom::Mobj*)
    # see which target is to be aimed at
    an = mo.value.angle
    CDoom.bulletslope = CDoom.p_aim_line_attack(mo, an, 16 * 64 * FRACUNIT)

    if CDoom.linetarget.null?
      an &+= 1 << 26
      CDoom.bulletslope = CDoom.p_aim_line_attack(mo, an, 16 * 64 * FRACUNIT)
      if CDoom.linetarget.null?
        an &-= 2 << 26
        CDoom.bulletslope = CDoom.p_aim_line_attack(mo, an, 16 * 64 * FRACUNIT)
      end
    end
  end

  def self.p_gunshot(mo : CDoom::Mobj*, accurate : CDoom::DoomBool)
    damage = 5 * (CDoom.p_random % 3 + 1)
    angle = mo.value.angle

    angle &+= (CDoom.p_random - CDoom.p_random) << 18 if accurate == 0

    CDoom.p_line_attack(mo, angle, CDoom::MISSILERANGE, CDoom.bulletslope, damage)
  end

  def self.a_fire_pistol(player : CDoom::Player*, psp : CDoom::Pspdef*)
    CDoom.s_start_sound(player.value.mo, CDoom::Sfxenum::SFX_pistol.value)

    CDoom.p_set_mobj_state(player.value.mo, CDoom::Statenum::S_PLAY_ATK2)
    player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] =
      player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] - 1

    CDoom.p_set_psprite(player,
      CDoom::Psprnum::Flash,
      CDoom::Statenum.new(CDoom.weaponinfo[player.value.readyweapon.value].flashstate))

    CDoom.p_bullet_slope(player.value.mo)
    CDoom.p_gunshot(player.value.mo, (player.value.refire == 0).to_unsafe)
  end

  def self.a_fire_shotgun(player : CDoom::Player*, psp : CDoom::Pspdef*)
    CDoom.s_start_sound(player.value.mo, CDoom::Sfxenum::SFX_shotgn.value)
    CDoom.p_set_mobj_state(player.value.mo, CDoom::Statenum::S_PLAY_ATK2)

    player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] =
      player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] - 1

    CDoom.p_set_psprite(player,
      CDoom::Psprnum::Flash,
      CDoom::Statenum.new(CDoom.weaponinfo[player.value.readyweapon.value].flashstate))

    CDoom.p_bullet_slope(player.value.mo)

    7.times do |i|
      CDoom.p_gunshot(player.value.mo, 0)
    end
  end

  def self.a_fire_shotgun2(player : CDoom::Player*, psp : CDoom::Pspdef*)
    CDoom.s_start_sound(player.value.mo, CDoom::Sfxenum::SFX_dshtgn.value)
    CDoom.p_set_mobj_state(player.value.mo, CDoom::Statenum::S_PLAY_ATK2)

    player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] =
      player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] - 2

    CDoom.p_set_psprite(player,
      CDoom::Psprnum::Flash,
      CDoom::Statenum.new(CDoom.weaponinfo[player.value.readyweapon.value].flashstate))

    CDoom.p_bullet_slope(player.value.mo)

    20.times do |i|
      damage = 5 * (CDoom.p_random % 3 + 1)
      angle = player.value.mo.value.angle
      angle &+= (CDoom.p_random - CDoom.p_random) << 19
      CDoom.p_line_attack(player.value.mo,
        angle,
        CDoom::MISSILERANGE,
        CDoom.bulletslope + ((CDoom.p_random - CDoom.p_random) << 5), damage)
    end
  end

  def self.a_fire_cgun(player : CDoom::Player*, psp : CDoom::Pspdef*)
    CDoom.s_start_sound(player.value.mo, CDoom::Sfxenum::SFX_pistol.value)

    return if player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] == 0

    CDoom.p_set_mobj_state(player.value.mo, CDoom::Statenum::S_PLAY_ATK2)
    player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] =
      player.value.ammo[CDoom.weaponinfo[player.value.readyweapon.value].ammo.value] - 1

    CDoom.p_set_psprite(player,
      CDoom::Psprnum::Flash,
      CDoom::Statenum.new(CDoom.weaponinfo[player.value.readyweapon.value].flashstate +
                          (psp.value.state - (CDoom.states + CDoom::Statenum::S_CHAIN1.value)).to_i32!))

    CDoom.p_bullet_slope(player.value.mo)

    CDoom.p_gunshot(player.value.mo, (player.value.refire == 0).to_unsafe)
  end

  def self.a_light0(player : CDoom::Player*, psp : CDoom::Pspdef*)
    player.value.extralight = 0
  end

  def self.a_light1(player : CDoom::Player*, psp : CDoom::Pspdef*)
    player.value.extralight = 1
  end

  def self.a_light2(player : CDoom::Player*, psp : CDoom::Pspdef*)
    player.value.extralight = 2
  end

  #
  # Spawn a BFG explosion on every monster in view
  #
  def self.a_bfg_spray(mo : CDoom::Mobj*)
    # offset angles from its attack angle
    40.times do |i|
      an = mo.value.angle &- ANG90.tdiv(2) &+ ANG90.tdiv(40) &* i

      # mo->target is the originator (player)
      #  of the missile
      CDoom.p_aim_line_attack(mo.value.target, an, 16 * 64 * FRACUNIT)

      next if CDoom.linetarget.null?

      CDoom.p_spawn_mobj(CDoom.linetarget.value.x,
        CDoom.linetarget.value.y,
        CDoom.linetarget.value.z + (CDoom.linetarget.value.height >> 2),
        CDoom::Mobjtype::MT_EXTRABFG)

      damage = 0
      15.times do |j|
        damage += (CDoom.p_random & 7) + 1
      end

      CDoom.p_damage_mobj(CDoom.linetarget, mo.value.target, mo.value.target, damage)
    end
  end

  def self.a_bfg_sound(player : CDoom::Player*, psp : CDoom::Pspdef*)
    CDoom.s_start_sound(player.value.mo, CDoom::Sfxenum::SFX_bfg.value)
  end

  #
  # Called at start of level for each player.
  #
  def self.p_setup_psprites(player : CDoom::Player*)
    # remove all psprites
    CDoom::Psprnum::NUMPSPRITES.value.times do |i|
      (player.value.psprites.to_unsafe + i).value.state = Pointer(CDoom::State).null
    end

    # spawn the gun
    player.value.pendingweapon = player.value.readyweapon
    CDoom.p_bring_up_weapon(player)
  end

  #
  # Called every tic by player thinking routine.
  #
  def self.p_move_psprites(player : CDoom::Player*)
    psp = (player.value.psprites.to_unsafe)
    CDoom::Psprnum::NUMPSPRITES.value.times do |i|
      # a null state means not active
      if !(state = psp.value.state).null?
        # drop tic count and possibly change state

        # a -1 tic count never changes
        if psp.value.tics != -1
          psp.value.tics = psp.value.tics - 1
          CDoom.p_set_psprite(player, CDoom::Psprnum.new(i), psp.value.state.value.nextstate) if psp.value.tics == 0
        end
      end
      psp += 1
    end

    (player.value.psprites.to_unsafe + CDoom::Psprnum::Flash.value).value.sx = player.value.psprites[CDoom::Psprnum::Weapon.value].sx
    (player.value.psprites.to_unsafe + CDoom::Psprnum::Flash.value).value.sy = player.value.psprites[CDoom::Psprnum::Weapon.value].sy
  end

  def self.p_archive_players(file : IO)
    CDoom::MAXPLAYERS.times do |i|
      next if CDoom.playeringame[i] == 0

      player = CDoom.players[i]
      CDoom::Psprnum::NUMPSPRITES.value.times do |j|
        if !player.psprites[j].state.null?
          (player.psprites.to_unsafe + j).value.state =
            Pointer(CDoom::State).new((player.psprites[j].state - CDoom.states).to_u64!)
        end
      end
      file.write(pointerof(player).as(UInt8*).to_slice(sizeof(CDoom::Player)))
    end
  end

  def self.p_unarchive_players(file : IO)
    CDoom::MAXPLAYERS.times do |i|
      next if CDoom.playeringame[i] == 0

      player = Slice.new((CDoom.players.to_unsafe + i).as(UInt8*), sizeof(CDoom::Player))
      file.read_fully(player)

      # will be set when unarc thinker
      (CDoom.players.to_unsafe + i).value.mo = Pointer(CDoom::Mobj).null
      (CDoom.players.to_unsafe + i).value.message = Pointer(UInt8).null
      (CDoom.players.to_unsafe + i).value.attacker = Pointer(CDoom::Mobj).null

      CDoom::Psprnum::NUMPSPRITES.value.times do |j|
        if !CDoom.players[i].psprites[j].state.null?
          ((CDoom.players.to_unsafe + i).value.psprites.to_unsafe + j).value.state =
            CDoom.states + CDoom.players[i].psprites[j].state.address
        end
      end
    end
  end

  def self.p_archive_world(file : IO)
    sec = CDoom.sectors
    # do sectors
    CDoom.numsectors.times do |i|
      file.write_bytes((sec.value.floorheight >> FRACBITS).to_i16!)
      file.write_bytes((sec.value.ceilingheight >> FRACBITS).to_i16!)
      file.write_bytes(sec.value.floorpic)
      file.write_bytes(sec.value.ceilingpic)
      file.write_bytes(sec.value.lightlevel)
      file.write_bytes(sec.value.special) # needed?
      file.write_bytes(sec.value.tag)     # needed?

      sec += 1
    end

    li = CDoom.lines
    # do lines
    CDoom.numlines.times do |i|
      file.write_bytes(li.value.flags)
      file.write_bytes(li.value.special)
      file.write_bytes(li.value.tag)
      2.times do |j|
        next if li.value.sidenum[j] == -1

        si = CDoom.sides + li.value.sidenum[j]

        file.write_bytes((si.value.textureoffset >> FRACBITS).to_i16!)
        file.write_bytes((si.value.rowoffset >> FRACBITS).to_i16!)
        file.write_bytes(si.value.toptexture)
        file.write_bytes(si.value.bottomtexture)
        file.write_bytes(si.value.midtexture)
      end
      li += 1
    end
  end

  def self.p_unarchive_world(file : IO)
    sec = CDoom.sectors
    # do sectors
    CDoom.numsectors.times do |i|
      sec.value.floorheight = file.read_bytes(Int16).to_i32 << FRACBITS
      sec.value.ceilingheight = file.read_bytes(Int16).to_i32 << FRACBITS
      sec.value.floorpic = file.read_bytes(Int16)
      sec.value.ceilingpic = file.read_bytes(Int16)
      sec.value.lightlevel = file.read_bytes(Int16)
      sec.value.special = file.read_bytes(Int16) # needed?
      sec.value.tag = file.read_bytes(Int16)     # needed?
      sec.value.specialdata = Pointer(Void).null
      sec.value.soundtarget = Pointer(CDoom::Mobj).null

      sec += 1
    end

    li = CDoom.lines
    # do lines
    CDoom.numlines.times do |i|
      li.value.flags = file.read_bytes(Int16)
      li.value.special = file.read_bytes(Int16)
      li.value.tag = file.read_bytes(Int16)
      2.times do |j|
        next if li.value.sidenum[j] == -1
        si = CDoom.sides + li.value.sidenum[j]
        si.value.textureoffset = file.read_bytes(Int16).to_i32 << FRACBITS
        si.value.rowoffset = file.read_bytes(Int16).to_i32 << FRACBITS
        si.value.toptexture = file.read_bytes(Int16)
        si.value.bottomtexture = file.read_bytes(Int16)
        si.value.midtexture = file.read_bytes(Int16)
      end

      li += 1
    end
  end

  def self.p_archive_thinkers(file : IO)
    # save off the current thinkers
    th = CDoom.thinkercap.next
    while th != pointerof(CDoom.thinkercap)
      if th.value.function.acp1.pointer == (->CDoom.p_mobj_thinker).pointer
        file.write_byte(CDoom::Thinkerclass::Mobj.value)
        mobj = th.as(CDoom::Mobj*).value
        mobj.state = Pointer(CDoom::State).new((mobj.state - CDoom.states).to_u64!)

        mobj.player = Pointer(CDoom::Player).new(((mobj.player - CDoom.players.to_unsafe) + 1).to_u64!) if !mobj.player.null?

        file.write(pointerof(mobj).as(UInt8*).to_slice(sizeof(CDoom::Mobj)))
      end

      th = th.value.next
    end

    # add a terminating marker
    file.write_byte(CDoom::Thinkerclass::End.value)
  end

  def self.p_unarchive_thinkers(file : IO)
    # remove all the current thinkers
    currentthinker = CDoom.thinkercap.next
    while currentthinker != pointerof(CDoom.thinkercap)
      nextt = currentthinker.value.next

      if currentthinker.value.function.acp1.pointer == (->CDoom.p_mobj_thinker).pointer
        CDoom.p_remove_mobj(currentthinker.as(CDoom::Mobj*))
      else
        CDoom.z_free(currentthinker)
      end
      currentthinker = nextt
    end
    CDoom.p_init_thinkers

    # read in saved thinkers
    loop do
      tclass = CDoom::Thinkerclass.new(file.read_bytes(UInt8))
      case tclass
      when CDoom::Thinkerclass::End
        return # end of list
      when CDoom::Thinkerclass::Mobj
        mobj = CDoom.z_malloc(sizeof(CDoom::Mobj), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Mobj*)
        mjslice = Slice.new(mobj.as(UInt8*), sizeof(CDoom::Mobj))
        file.read_fully(mjslice)
        mobj.value.state = CDoom.states + mobj.value.state.address
        mobj.value.target = Pointer(CDoom::Mobj).null
        if !mobj.value.player.null?
          mobj.value.player = CDoom.players.to_unsafe + (mobj.value.player.address - 1)
          mobj.value.player.value.mo = mobj
        end
        CDoom.p_set_thing_position(mobj)
        mobj.value.info = CDoom.mobjinfo + mobj.value.type.value
        mobj.value.floorz = mobj.value.subsector.value.sector.value.floorheight
        mobj.value.ceilingz = mobj.value.subsector.value.sector.value.ceilingheight
        pointerof(mobj.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.p_mobj_thinker).pointer, Pointer(Void).null)
        CDoom.p_add_thinker(pointerof(mobj.value.@thinker))
      else
        CDoom.i_error("Error: Unknown tclass #{tclass} in savegame")
      end
    end
  end

  #
  # Things to handle:
  #
  # T_MoveCeiling, (ceiling_t: sector_t * swizzle), - active list
  # T_VerticalDoor, (vldoor_t: sector_t * swizzle),
  # T_MoveFloor, (floormove_t: sector_t * swizzle),
  # T_LightFlash, (lightflash_t: sector_t * swizzle),
  # T_StrobeFlash, (strobe_t: sector_t *),
  # T_Glow, (glow_t: sector_t *),
  # T_PlatRaise, (plat_t: sector_t *), - active list
  #
  def self.p_archive_specials(file : IO)
    # save off the current thinkers
    th = CDoom.thinkercap.next
    while th != pointerof(CDoom.thinkercap)
      if th.value.function.acv.pointer.null?
        i = 0
        while i < CDoom::MAXCEILINGS
          break if CDoom.activeceilings[i] == th.as(CDoom::Ceiling*)
          i += 1
        end

        if i < CDoom::MAXCEILINGS
          file.write_byte(CDoom::Specials::Ceiling.value)
          ceiling = th.as(CDoom::Ceiling*).value
          ceiling.sector = Pointer(CDoom::Sector).new((ceiling.sector - CDoom.sectors).to_u64!)
          file.write(pointerof(ceiling).as(UInt8*).to_slice(sizeof(CDoom::Ceiling)))
        end
        th = th.value.next
        next
      end

      if th.value.function.acp1.pointer == (->CDoom.t_move_ceiling).pointer
        file.write_byte(CDoom::Specials::Ceiling.value)
        ceiling = th.as(CDoom::Ceiling*).value
        ceiling.sector = Pointer(CDoom::Sector).new((ceiling.sector - CDoom.sectors).to_u64!)
        th = th.value.next
        file.write(pointerof(ceiling).as(UInt8*).to_slice(sizeof(CDoom::Ceiling)))
        next
      end

      if th.value.function.acp1.pointer == (->CDoom.t_vertical_door).pointer
        file.write_byte(CDoom::Specials::Door.value)
        door = th.as(CDoom::Vldoor*).value
        door.sector = Pointer(CDoom::Sector).new((door.sector - CDoom.sectors).to_u64!)
        th = th.value.next
        file.write(pointerof(door).as(UInt8*).to_slice(sizeof(CDoom::Vldoor)))
        next
      end

      if th.value.function.acp1.pointer == (->CDoom.t_move_floor).pointer
        file.write_byte(CDoom::Specials::Floor.value)
        floor = th.as(CDoom::Floormove*).value
        floor.sector = Pointer(CDoom::Sector).new((floor.sector - CDoom.sectors).to_u64!)
        th = th.value.next
        file.write(pointerof(floor).as(UInt8*).to_slice(sizeof(CDoom::Floormove)))

        next
      end

      if th.value.function.acp1.pointer == (->CDoom.t_plat_raise).pointer
        file.write_byte(CDoom::Specials::Plat.value)
        plat = th.as(CDoom::Plat*).value
        plat.sector = Pointer(CDoom::Sector).new((plat.sector - CDoom.sectors).to_u64!)
        th = th.value.next
        file.write(pointerof(plat).as(UInt8*).to_slice(sizeof(CDoom::Plat)))
        next
      end

      if th.value.function.acp1.pointer == (->CDoom.t_light_flash).pointer
        file.write_byte(CDoom::Specials::Flash.value)
        flash = th.as(CDoom::Lightflash*).value
        flash.sector = Pointer(CDoom::Sector).new((flash.sector - CDoom.sectors).to_u64!)
        th = th.value.next
        file.write(pointerof(flash).as(UInt8*).to_slice(sizeof(CDoom::Lightflash)))
        next
      end

      if th.value.function.acp1.pointer == (->CDoom.t_strobe_flash).pointer
        file.write_byte(CDoom::Specials::Strobe.value)
        strobe = th.as(CDoom::Strobe*).value
        strobe.sector = Pointer(CDoom::Sector).new((strobe.sector - CDoom.sectors).to_u64!)
        th = th.value.next
        file.write(pointerof(strobe).as(UInt8*).to_slice(sizeof(CDoom::Strobe)))

        next
      end

      if th.value.function.acp1.pointer == (->CDoom.t_glow).pointer
        file.write_byte(CDoom::Specials::Glow.value)
        glow = th.as(CDoom::Glow*).value
        glow.sector = Pointer(CDoom::Sector).new((glow.sector - CDoom.sectors).to_u64!)
        th = th.value.next
        file.write(pointerof(glow).as(UInt8*).to_slice(sizeof(CDoom::Glow)))
        next
      end

      th = th.value.next
    end

    # add a terminating marker
    file.write_byte(CDoom::Specials::End.value)
  end

  def self.p_unarchive_specials(file : IO)
    # read in saved thinkers
    loop do
      tclass = CDoom::Specials.new(file.read_bytes(UInt8))
      case tclass
      when CDoom::Specials::End
        return # end of list
      when CDoom::Specials::Ceiling
        ceiling = CDoom.z_malloc(sizeof(CDoom::Ceiling), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Ceiling*)
        slice = Slice.new(ceiling.as(UInt8*), sizeof(CDoom::Ceiling))
        file.read_fully(slice)

        ceiling.value.sector = CDoom.sectors + ceiling.value.sector.address

        ceiling.value.sector.value.specialdata = ceiling

        if !ceiling.value.thinker.function.acp1.pointer.null?
          pointerof(ceiling.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_move_ceiling).pointer, Pointer(Void).null)
        end

        CDoom.p_add_thinker(pointerof(ceiling.value.@thinker))
        CDoom.p_add_active_ceiling(ceiling)
      when CDoom::Specials::Door
        door = CDoom.z_malloc(sizeof(CDoom::Vldoor), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Vldoor*)
        slice = Slice.new(door.as(UInt8*), sizeof(CDoom::Vldoor))
        file.read_fully(slice)
        door.value.sector = CDoom.sectors + door.value.sector.address
        door.value.sector.value.specialdata = door
        pointerof(door.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_vertical_door).pointer, Pointer(Void).null)

        CDoom.p_add_thinker(pointerof(door.value.@thinker))
      when CDoom::Specials::Floor
        floor = CDoom.z_malloc(sizeof(CDoom::Floormove), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Floormove*)
        slice = Slice.new(floor.as(UInt8*), sizeof(CDoom::Floormove))
        file.read_fully(slice)
        floor.value.sector = CDoom.sectors + floor.value.sector.address
        floor.value.sector.value.specialdata = floor
        pointerof(floor.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_move_floor).pointer, Pointer(Void).null)

        CDoom.p_add_thinker(pointerof(floor.value.@thinker))
      when CDoom::Specials::Plat
        plat = CDoom.z_malloc(sizeof(CDoom::Plat), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Plat*)
        slice = Slice.new(plat.as(UInt8*), sizeof(CDoom::Plat))
        file.read_fully(slice)
        plat.value.sector = CDoom.sectors + plat.value.sector.address
        plat.value.sector.value.specialdata = plat
        if !plat.value.thinker.function.acp1.pointer.null?
          pointerof(plat.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_plat_raise).pointer, Pointer(Void).null)
        end

        CDoom.p_add_thinker(pointerof(plat.value.@thinker))
        CDoom.p_add_active_plat(plat)
      when CDoom::Specials::Flash
        flash = CDoom.z_malloc(sizeof(CDoom::Lightflash), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Lightflash*)
        slice = Slice.new(flash.as(UInt8*), sizeof(CDoom::Lightflash))
        file.read_fully(slice)
        flash.value.sector = CDoom.sectors + flash.value.sector.address
        pointerof(flash.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_light_flash).pointer, Pointer(Void).null)

        CDoom.p_add_thinker(pointerof(flash.value.@thinker))
      when CDoom::Specials::Strobe
        strobe = CDoom.z_malloc(sizeof(CDoom::Strobe), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Strobe*)
        slice = Slice.new(strobe.as(UInt8*), sizeof(CDoom::Strobe))
        file.read_fully(slice)
        strobe.value.sector = CDoom.sectors + strobe.value.sector.address
        pointerof(strobe.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_strobe_flash).pointer, Pointer(Void).null)

        CDoom.p_add_thinker(pointerof(strobe.value.@thinker))
      when CDoom::Specials::Glow
        glow = CDoom.z_malloc(sizeof(CDoom::Glow), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Glow*)
        slice = Slice.new(glow.as(UInt8*), sizeof(CDoom::Glow))
        file.read_fully(slice)
        glow.value.sector = CDoom.sectors + glow.value.sector.address
        pointerof(glow.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_glow).pointer, Pointer(Void).null)

        CDoom.p_add_thinker(pointerof(glow.value.@thinker))
      else
        CDoom.i_error("Error: p_unarchive_specials: Unknown tclass #{tclass} in savegame")
      end
    end
  end

  def self.p_load_vertexes(lump : LibC::Int)
    # Determine number of lumps:
    #  total lump length / vertex record length.
    CDoom.numvertexes = CDoom.w_lump_length(lump) // sizeof(CDoom::Mapvertex)

    # Allocate zone memory for buffer.
    CDoom.vertexes = CDoom.z_malloc(CDoom.numvertexes * sizeof(CDoom::Vertex), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Vertex*)

    # Load data into cache.
    data = CDoom.w_cache_lump_num(lump, CDoom::PU_STATIC).as(CDoom::Byte*)

    ml = data.as(CDoom::Mapvertex*)
    li = CDoom.vertexes

    # Copy and convert vertex coordinates,
    # internal representation as fixed.
    CDoom.numvertexes.times do |i|
      li.value.x = ml.value.x.to_i32 << FRACBITS
      li.value.y = ml.value.y.to_i32 << FRACBITS

      li += 1
      ml += 1
    end

    # Free buffer memory.
    CDoom.z_free(data)
  end

  def self.p_load_segs(lump : LibC::Int)
    CDoom.numsegs = CDoom.w_lump_length(lump) // sizeof(CDoom::Mapseg)
    CDoom.segs = CDoom.z_malloc(CDoom.numsegs * sizeof(CDoom::Seg), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Seg*)
    CDoom.doom_memset(CDoom.segs, 0, CDoom.numsegs * sizeof(CDoom::Seg))
    data = CDoom.w_cache_lump_num(lump, CDoom::PU_STATIC).as(CDoom::Byte*)

    ml = data.as(CDoom::Mapseg*)
    li = CDoom.segs
    CDoom.numsegs.times do |i|
      li.value.v1 = CDoom.vertexes + ml.value.v1
      li.value.v2 = CDoom.vertexes + ml.value.v2

      li.value.angle = ml.value.angle.to_i32 << 16
      li.value.offset = ml.value.offset.to_i32 << 16
      linedef = ml.value.linedef
      ldef = CDoom.lines + linedef
      li.value.linedef = ldef
      side = ml.value.side
      li.value.sidedef = CDoom.sides + ldef.value.sidenum[side]
      li.value.frontsector = CDoom.sides[ldef.value.sidenum[side]].sector
      if ldef.value.flags & CDoom::ML_TWOSIDED != 0
        li.value.backsector = CDoom.sides[ldef.value.sidenum[side ^ 1]].sector
      else
        li.value.backsector = Pointer(CDoom::Sector).null
      end

      li += 1
      ml += 1
    end

    CDoom.z_free(data)
  end

  def self.p_load_subsectors(lump : LibC::Int)
    CDoom.numsubsectors = CDoom.w_lump_length(lump) // sizeof(CDoom::Mapsubsector)
    CDoom.subsectors = CDoom.z_malloc(CDoom.numsubsectors * sizeof(CDoom::Subsector), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Subsector*)
    data = CDoom.w_cache_lump_num(lump, CDoom::PU_STATIC).as(CDoom::Byte*)

    ms = data.as(CDoom::Mapsubsector*)
    CDoom.doom_memset(CDoom.subsectors, 0, CDoom.numsubsectors * sizeof(CDoom::Subsector))
    ss = CDoom.subsectors

    CDoom.numsubsectors.times do |i|
      ss.value.numlines = ms.value.numsegs
      ss.value.firstline = ms.value.firstseg

      ss += 1
      ms += 1
    end

    CDoom.z_free(data)
  end

  def self.p_load_sectors(lump : LibC::Int)
    CDoom.numsectors = CDoom.w_lump_length(lump) // sizeof(CDoom::Mapsector)
    CDoom.sectors = CDoom.z_malloc(CDoom.numsectors * sizeof(CDoom::Sector), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Sector*)
    CDoom.doom_memset(CDoom.sectors, 0, CDoom.numsectors * sizeof(CDoom::Sector))
    data = CDoom.w_cache_lump_num(lump, CDoom::PU_STATIC).as(CDoom::Byte*)

    ms = data.as(CDoom::Mapsector*)
    ss = CDoom.sectors

    CDoom.numsectors.times do |i|
      ss.value.floorheight = ms.value.floorheight.to_i32 << FRACBITS
      ss.value.ceilingheight = ms.value.ceilingheight.to_i32 << FRACBITS
      ss.value.floorpic = CDoom.r_flat_num_for_name(ms.value.floorpic)
      ss.value.ceilingpic = CDoom.r_flat_num_for_name(ms.value.ceilingpic)
      ss.value.lightlevel = ms.value.lightlevel
      ss.value.special = ms.value.special
      ss.value.tag = ms.value.tag
      ss.value.thinglist = Pointer(CDoom::Mobj).null

      ss += 1
      ms += 1
    end

    CDoom.z_free(data)
  end

  def self.p_load_nodes(lump : LibC::Int)
    CDoom.numnodes = CDoom.w_lump_length(lump) // sizeof(CDoom::Mapnode)
    CDoom.nodes = CDoom.z_malloc(CDoom.numnodes * sizeof(CDoom::Node), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Node*)
    data = CDoom.w_cache_lump_num(lump, CDoom::PU_STATIC).as(CDoom::Byte*)

    mn = data.as(CDoom::Mapnode*)
    no = CDoom.nodes

    CDoom.numnodes.times do |i|
      no.value.x = mn.value.x.to_i32 << FRACBITS
      no.value.y = mn.value.y.to_i32 << FRACBITS
      no.value.dx = mn.value.dx.to_i32 << FRACBITS
      no.value.dy = mn.value.dy.to_i32 << FRACBITS

      2.times do |j|
        no.value.children[j] = mn.value.children[j]
        4.times do |k|
          ((no.value.bbox.to_unsafe + j).value.to_unsafe + k).value = mn.value.bbox[j][k].to_i32 << FRACBITS
        end
      end

      no += 1
      mn += 1
    end

    CDoom.z_free(data)
  end

  def self.p_load_things(lump : LibC::Int)
    data = CDoom.w_cache_lump_num(lump, CDoom::PU_STATIC).as(CDoom::Byte*)
    numthings = CDoom.w_lump_length(lump) // sizeof(CDoom::Mapthing)

    mt = data.as(CDoom::Mapthing*)

    numthings.times do |i|
      spawnt = true

      # Do not spawn cool, new monsters if !commercial
      if CDoom.gamemode != CDoom::GameMode::Commercial
        case mt.value.type
        when 68, # Arachnotron
             64, # Archvile
             88, # Boss Brain
             89, # Boss Shooter
             69, # Hell Knight
             67, # Mancubus
             71, # Pain Elemental
             65, # Former Human Commando
             66, # Revenant
             84  # Wolf SS
          spawnt = false
        end
      end

      if spawnt == false
        mt += 1
        next
      end

      # Do spawn all other stuff.
      # [ds] Pointless?
      mt.value.x = mt.value.x
      mt.value.x = mt.value.x
      mt.value.angle = mt.value.angle
      mt.value.type = mt.value.type
      mt.value.options = mt.value.options

      CDoom.p_spawn_map_thing(mt)
      mt += 1
    end

    CDoom.z_free(data)
  end

  #
  # Also counts secret lines for intermissions.
  #
  def self.p_load_linedefs(lump : LibC::Int)
    CDoom.numlines = CDoom.w_lump_length(lump) // sizeof(CDoom::Maplinedef)
    CDoom.lines = CDoom.z_malloc(CDoom.numlines * sizeof(CDoom::Line), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Line*)
    CDoom.doom_memset(CDoom.lines, 0, CDoom.numlines * sizeof(CDoom::Line))
    data = CDoom.w_cache_lump_num(lump, CDoom::PU_STATIC).as(CDoom::Byte*)

    mld = data.as(CDoom::Maplinedef*)
    ld = CDoom.lines

    CDoom.numlines.times do |i|
      ld.value.flags = mld.value.flags
      ld.value.special = mld.value.special
      ld.value.tag = mld.value.tag
      v1 = CDoom.vertexes + mld.value.v1
      ld.value.v1 = v1
      v2 = CDoom.vertexes + mld.value.v2
      ld.value.v2 = v2
      ld.value.dx = v2.value.x - v1.value.x
      ld.value.dy = v2.value.y - v1.value.y

      if ld.value.dx == 0
        ld.value.slopetype = CDoom::Slopetype::VERTICAL
      elsif ld.value.dy == 0
        ld.value.slopetype = CDoom::Slopetype::HORIZONTAL
      else
        if CDoom.fixed_div(ld.value.dy, ld.value.dx) > 0
          ld.value.slopetype = CDoom::Slopetype::POSITIVE
        else
          ld.value.slopetype = CDoom::Slopetype::NEGATIVE
        end
      end

      if v1.value.x < v2.value.x
        ld.value.bbox[CDoom::BOXLEFT] = v1.value.x
        ld.value.bbox[CDoom::BOXRIGHT] = v2.value.x
      else
        ld.value.bbox[CDoom::BOXLEFT] = v2.value.x
        ld.value.bbox[CDoom::BOXRIGHT] = v1.value.x
      end

      if v1.value.y < v2.value.y
        ld.value.bbox[CDoom::BOXBOTTOM] = v1.value.y
        ld.value.bbox[CDoom::BOXTOP] = v2.value.y
      else
        ld.value.bbox[CDoom::BOXBOTTOM] = v2.value.y
        ld.value.bbox[CDoom::BOXTOP] = v1.value.y
      end

      ld.value.sidenum[0] = mld.value.sidenum[0]
      ld.value.sidenum[1] = mld.value.sidenum[1]

      if ld.value.sidenum[0] != -1
        ld.value.frontsector = CDoom.sides[ld.value.sidenum[0]].sector
      else
        ld.value.frontsector = Pointer(CDoom::Sector).null
      end

      if ld.value.sidenum[1] != -1
        ld.value.backsector = CDoom.sides[ld.value.sidenum[1]].sector
      else
        ld.value.backsector = Pointer(CDoom::Sector).null
      end

      mld += 1
      ld += 1
    end

    CDoom.z_free(data)
  end

  def self.p_load_sidedefs(lump : LibC::Int)
    CDoom.numsides = CDoom.w_lump_length(lump) // sizeof(CDoom::Mapsidedef)
    CDoom.sides = CDoom.z_malloc(CDoom.numsides * sizeof(CDoom::Side), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Side*)
    CDoom.doom_memset(CDoom.sides, 0, CDoom.numsides * sizeof(CDoom::Side))
    data = CDoom.w_cache_lump_num(lump, CDoom::PU_STATIC).as(CDoom::Byte*)

    msd = data.as(CDoom::Mapsidedef*)
    sd = CDoom.sides

    CDoom.numsides.times do |i|
      sd.value.textureoffset = msd.value.textureoffset.to_i32 << FRACBITS
      sd.value.rowoffset = msd.value.rowoffset.to_i32 << FRACBITS
      sd.value.toptexture = CDoom.r_texture_num_for_name(msd.value.toptexture)
      sd.value.bottomtexture = CDoom.r_texture_num_for_name(msd.value.bottomtexture)
      sd.value.midtexture = CDoom.r_texture_num_for_name(msd.value.midtexture)
      sd.value.sector = CDoom.sectors + msd.value.sector

      msd += 1
      sd += 1
    end

    CDoom.z_free(data)
  end

  def self.p_load_blockmap(lump : LibC::Int)
    CDoom.blockmaplump = CDoom.w_cache_lump_num(lump, CDoom::PU_STATIC).as(Int16*)
    CDoom.blockmap = CDoom.blockmaplump + 4
    count = CDoom.w_lump_length(lump) // 2

    count.times do |i|
      CDoom.blockmaplump[i] = CDoom.blockmaplump[i] # [ds] pointless?
    end

    CDoom.bmaporgx = CDoom.blockmaplump[0].to_i32 << FRACBITS
    CDoom.bmaporgy = CDoom.blockmaplump[1].to_i32 << FRACBITS
    CDoom.bmapwidth = CDoom.blockmaplump[2]
    CDoom.bmapheight = CDoom.blockmaplump[3]

    # clear out mobj chains
    count = sizeof(CDoom::Mobj*) * CDoom.bmapwidth * CDoom.bmapheight
    CDoom.blocklinks = CDoom.z_malloc(count, CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Mobj**)
    CDoom.doom_memset(CDoom.blocklinks, 0, count)
  end

  #
  # Builds sector line lists and subsector sector numbers.
  # Finds block bounding boxes for sectors.
  #
  def self.p_group_lines
    # look up sector number for each subsector
    ss = CDoom.subsectors
    CDoom.numsubsectors.times do |i|
      seg = CDoom.segs + ss.value.firstline
      ss.value.sector = seg.value.sidedef.value.sector

      ss += 1
    end

    # count number of lines in each sector
    li = CDoom.lines
    total = 0
    CDoom.numlines.times do |i|
      total += 1
      li.value.frontsector.value.linecount = li.value.frontsector.value.linecount + 1

      if !li.value.backsector.null? && li.value.backsector != li.value.frontsector
        li.value.backsector.value.linecount = li.value.backsector.value.linecount + 1
        total += 1
      end

      li += 1
    end

    # build line tables for each sector
    linebuffer = CDoom.z_malloc(total * sizeof(CDoom::Line*), CDoom::PU_LEVEL, Pointer(Void).null).as(CDoom::Line**)
    sector = CDoom.sectors
    bbox = Pointer(CDoom::Fixed).malloc(4)
    CDoom.numsectors.times do |i|
      CDoom.m_clear_box(bbox)
      sector.value.lines = linebuffer
      li = CDoom.lines
      CDoom.numlines.times do |j|
        if li.value.frontsector == sector || li.value.backsector == sector
          linebuffer.value = li
          linebuffer += 1
          CDoom.m_add_to_box(bbox, li.value.v1.value.x, li.value.v1.value.y)
          CDoom.m_add_to_box(bbox, li.value.v2.value.x, li.value.v2.value.y)
        end

        li += 1
      end
      if (linebuffer - sector.value.lines) != sector.value.linecount
        CDoom.i_error("Error: p_group_lines: miscounted")
      end

      # set the degenmobj_t to the middle of the bounding box
      soundorg = pointerof(sector.value.@soundorg)
      soundorg.value.x = (bbox[CDoom::BOXRIGHT] &+ bbox[CDoom::BOXLEFT]) // 2
      soundorg.value.y = (bbox[CDoom::BOXTOP] &+ bbox[CDoom::BOXBOTTOM]) // 2

      # adjust bounding box to map blocks
      block = (bbox[CDoom::BOXTOP] &- CDoom.bmaporgy + CDoom::MAXRADIUS) >> CDoom::MAPBLOCKSHIFT
      block = block >= CDoom.bmapheight ? CDoom.bmapheight - 1 : block
      sector.value.blockbox[CDoom::BOXTOP] = block

      block = (bbox[CDoom::BOXBOTTOM] &- CDoom.bmaporgy - CDoom::MAXRADIUS) >> CDoom::MAPBLOCKSHIFT
      block = block < 0 ? 0 : block
      sector.value.blockbox[CDoom::BOXBOTTOM] = block

      block = (bbox[CDoom::BOXRIGHT] &- CDoom.bmaporgx + CDoom::MAXRADIUS) >> CDoom::MAPBLOCKSHIFT
      block = block >= CDoom.bmapwidth ? CDoom.bmapwidth - 1 : block
      sector.value.blockbox[CDoom::BOXRIGHT] = block

      block = (bbox[CDoom::BOXLEFT] &- CDoom.bmaporgx - CDoom::MAXRADIUS) >> CDoom::MAPBLOCKSHIFT
      block = block < 0 ? 0 : block
      sector.value.blockbox[CDoom::BOXLEFT] = block

      sector += 1
    end
  end

  def self.p_setup_level(episode : LibC::Int, map : LibC::Int, playermask : LibC::Int, skill : CDoom::Skill)
    lumpname = Pointer(UInt8).malloc(9)

    CDoom.totalkills = 0
    CDoom.totalitems = 0
    CDoom.totalsecret = 0
    CDoom.wminfo.maxfrags = 0
    CDoom.wminfo.partime = 180
    CDoom::MAXPLAYERS.times do |i|
      (CDoom.players.to_unsafe + i).value.killcount = 0
      (CDoom.players.to_unsafe + i).value.secretcount = 0
      (CDoom.players.to_unsafe + i).value.itemcount = 0
    end

    # Initial height of PointOfView
    # will be set by player think.
    (CDoom.players.to_unsafe + CDoom.consoleplayer).value.viewz = 1

    # Make sure all sounds are stopped before Z_FreeTags.
    CDoom.s_start

    CDoom.z_free_tags(CDoom::PU_LEVEL, CDoom::PU_PURGELEVEL - 1)

    CDoom.p_init_thinkers

    # if working with a devlopment map, reload it
    CDoom.w_reload

    # find map name
    if CDoom.gamemode == CDoom::GameMode::Commercial
      if map < 10
        CDoom.doom_strcpy(lumpname, "map0")
        CDoom.doom_concat(lumpname, CDoom.doom_itoa(map, 10))
      else
        CDoom.doom_strcpy(lumpname, "map")
        CDoom.doom_concat(lumpname, CDoom.doom_itoa(map, 10))
      end
    else
      lumpname[0] = 'E'.ord.to_u8
      lumpname[1] = '0'.ord.to_u8 + episode
      lumpname[2] = 'M'.ord.to_u8
      lumpname[3] = '0'.ord.to_u8 + map
      lumpname[4] = 0
    end

    lumpnum = CDoom.w_get_num_for_name(lumpname)

    CDoom.leveltime = 0

    # note: most of this ordering is important
    CDoom.p_load_blockmap(lumpnum + CDoom::ML_BLOCKMAP)
    CDoom.p_load_vertexes(lumpnum + CDoom::ML_VERTEXES)
    CDoom.p_load_sectors(lumpnum + CDoom::ML_SECTORS)
    CDoom.p_load_sidedefs(lumpnum + CDoom::ML_SIDEDEFS)

    CDoom.p_load_linedefs(lumpnum + CDoom::ML_LINEDEFS)
    CDoom.p_load_subsectors(lumpnum + CDoom::ML_SSECTORS)
    CDoom.p_load_nodes(lumpnum + CDoom::ML_NODES)
    CDoom.p_load_segs(lumpnum + CDoom::ML_SEGS)

    CDoom.rejectmatrix = CDoom.w_cache_lump_num(lumpnum + CDoom::ML_REJECT, CDoom::PU_LEVEL).as(UInt8*)
    CDoom.p_group_lines

    CDoom.bodyqueslot = 0
    CDoom.deathmatch_p = CDoom.deathmatchstarts.to_unsafe
    CDoom.p_load_things(lumpnum + CDoom::ML_THINGS)

    # if deathmatch, randomly spawn the active players
    if CDoom.deathmatch != 0
      CDoom::MAXPLAYERS.times do |i|
        if CDoom.playeringame[i] != 0
          (CDoom.players.to_unsafe + i).value.mo = Pointer(CDoom::Mobj).null
          CDoom.g_deathmatch_spawn_player(i)
        end
      end
    end

    # clear special respawning que
    CDoom.iquehead = 0
    CDoom.iquetail = 0

    # set up world state
    CDoom.p_spawn_specials

    # preload graphics
    CDoom.r_precache_level if CDoom.precache != 0
  end

  def self.p_init
    CDoom.p_init_switch_list
    CDoom.p_init_pic_anims
    CDoom.r_init_sprites(CDoom.sprnames)
  end

  #
  # Returns side 0 (front), 1 (back), or 2 (on).
  #
  def self.p_divline_side(x : CDoom::Fixed, y : CDoom::Fixed, node : CDoom::Divline*) : LibC::Int
    if node.value.dx == 0
      return 2 if x == node.value.x

      return (node.value.dy > 0).to_unsafe if x <= node.value.x

      return (node.value.dy < 0).to_unsafe
    end

    if node.value.dy == 0
      return 2 if x == node.value.y

      return (node.value.dx < 0).to_unsafe if y <= node.value.y

      return (node.value.dx > 0).to_unsafe
    end

    dx = x - node.value.x
    dy = y - node.value.y

    left = (node.value.dy >> FRACBITS) * (dx >> FRACBITS)
    right = (dy >> FRACBITS) * (node.value.dx >> FRACBITS)

    return 0 if right < left # front side

    return 2 if left == right
    return 1 # back side
  end

  #
  # Returns the fractional intercept point
  # along the first divline.
  # This is only called by the addthings and addlines traversers.
  #
  def self.p_intercept_vector2(v2 : CDoom::Divline*, v1 : CDoom::Divline*) : CDoom::Fixed
    den = CDoom.fixed_mul(v1.value.dy >> 8, v2.value.dx) - CDoom.fixed_mul(v1.value.dx >> 8, v2.value.dy)

    return 0 if den == 0

    num = CDoom.fixed_mul((v1.value.x - v2.value.x) >> 8, v1.value.dy) +
          CDoom.fixed_mul((v2.value.y - v1.value.y) >> 8, v1.value.dx)
    frac = CDoom.fixed_div(num, den)

    return frac
  end

  #
  # Returns true
  #  if strace crosses the given subsector successfully.
  #
  def self.p_cross_subsector(num : LibC::Int) : CDoom::DoomBool
    {% if flag?("RANGECHECK") %}
      if num >= CDoom.numsubsectors
        CDoom.i_error("Error: p_cross_subsector: ss #{num} with numss = #{CDoom.numsubsectors}")
      end
    {% end %}

    sub = CDoom.subsectors + num

    # check lines
    count = sub.value.numlines
    seg = CDoom.segs + sub.value.firstline

    divl = CDoom::Divline.new

    while count != 0
      line = seg.value.linedef

      # allready checked other size?
      if line.value.validcount == CDoom.validcount
        seg += 1
        count -= 1
        next
      end

      line.value.validcount = CDoom.validcount

      v1 = line.value.v1
      v2 = line.value.v2
      s1 = CDoom.p_divline_side(v1.value.x, v1.value.y, pointerof(CDoom.strace))
      s2 = CDoom.p_divline_side(v2.value.x, v2.value.y, pointerof(CDoom.strace))

      # line isn't crossed?
      if s1 == s2
        seg += 1
        count -= 1
        next
      end

      divl.x = v1.value.x
      divl.y = v1.value.y
      divl.dx = v2.value.x - v1.value.x
      divl.dy = v2.value.y - v1.value.y
      s1 = CDoom.p_divline_side(CDoom.strace.x, CDoom.strace.y, pointerof(divl))
      s2 = CDoom.p_divline_side(CDoom.t2x, CDoom.t2y, pointerof(divl))

      # line isn't crossed?
      if s1 == s2
        seg += 1
        count -= 1
        next
      end

      # stop because it is not two sided anyway
      # might do this after updating validcount?
      return 0 if line.value.flags & CDoom::ML_TWOSIDED == 0

      # crosses a two sided line
      front = seg.value.frontsector
      back = seg.value.backsector

      # no wall to block sight with?
      if front.value.floorheight == back.value.floorheight &&
         front.value.ceilingheight == back.value.ceilingheight
        seg += 1
        count -= 1
        next
      end

      # possible occluder
      # because of ceiling height differences
      if front.value.ceilingheight < back.value.ceilingheight
        opentop = front.value.ceilingheight
      else
        opentop = back.value.ceilingheight
      end

      # because of ceiling height differences
      if front.value.floorheight > back.value.floorheight
        openbottom = front.value.floorheight
      else
        openbottom = back.value.floorheight
      end

      # quick test for totally closed doors
      return 0 if openbottom >= opentop # stop

      frac = CDoom.p_intercept_vector2(pointerof(CDoom.strace), pointerof(divl))

      if front.value.floorheight != back.value.floorheight
        slope = CDoom.fixed_div(openbottom - CDoom.sightzstart, frac)
        CDoom.bottomslope = slope if slope > CDoom.bottomslope
      end

      if front.value.ceilingheight != back.value.ceilingheight
        slope = CDoom.fixed_div(opentop - CDoom.sightzstart, frac)
        CDoom.topslope = slope if slope < CDoom.topslope
      end

      return 0 if CDoom.topslope <= CDoom.bottomslope # stop

      seg += 1
      count -= 1
    end

    # passed the subsector ok
    return 1
  end

  #
  # Returns true
  #  if strace crosses the given node successfully.
  #
  def self.p_cross_bsp_node(bspnum : LibC::Int) : CDoom::DoomBool
    if bspnum & CDoom::NF_SUBSECTOR != 0
      if bspnum == -1
        return CDoom.p_cross_subsector(0)
      else
        return CDoom.p_cross_subsector(bspnum & (~CDoom::NF_SUBSECTOR))
      end
    end

    bsp = CDoom.nodes + bspnum

    # decide which side the start point is on
    side = CDoom.p_divline_side(CDoom.strace.x, CDoom.strace.y, bsp.as(CDoom::Divline*))
    side = 0 if side == 2 # an "on" should cross both sides

    # cross the starting side
    return 0 if CDoom.p_cross_bsp_node(bsp.value.children[side]) == 0

    # the partition plane is crossed here
    if side == CDoom.p_divline_side(CDoom.t2x, CDoom.t2y, bsp.as(CDoom::Divline*))
      # the line doesn't touch the other side
      return 1
    end

    # cross the ending side
    return CDoom.p_cross_bsp_node(bsp.value.children[side ^ 1])
  end

  #
  # Returns true
  #  if a straight line between t1 and t2 is unobstructed.
  # Uses REJECT.
  #
  def self.p_check_sight(t1 : CDoom::Mobj*, t2 : CDoom::Mobj*) : CDoom::DoomBool
    # First check for trivial rejection.

    # Determine subsector entries in REJECT table.
    s1 = t1.value.subsector.value.sector - CDoom.sectors
    s2 = t2.value.subsector.value.sector - CDoom.sectors
    pnum = s1 * CDoom.numsectors + s2
    bytenum = pnum >> 3
    bitnum = 1 << (pnum & 7)

    # Check in REJECT table.
    if CDoom.rejectmatrix[bytenum] & bitnum != 0
      CDoom.sightcounts[0] = CDoom.sightcounts[0] + 1

      # can't possibly be connected
      return 0
    end

    # An unobstructed LOS is possible.
    # Now look from eyes of t1 to any part of t2.
    CDoom.sightcounts[1] = CDoom.sightcounts[1] + 1

    CDoom.validcount += 1

    CDoom.sightzstart = t1.value.z + t1.value.height - (t1.value.height >> 2)
    CDoom.topslope = (t2.value.z + t2.value.height) - CDoom.sightzstart
    CDoom.bottomslope = (t2.value.z) - CDoom.sightzstart

    CDoom.strace.x = t1.value.x
    CDoom.strace.y = t1.value.y
    CDoom.t2x = t2.value.x
    CDoom.t2y = t2.value.y
    CDoom.strace.dx = t2.value.x - t1.value.x
    CDoom.strace.dy = t2.value.y - t1.value.y

    # the head node is the last node output
    return CDoom.p_cross_bsp_node(CDoom.numnodes - 1)
  end

  def self.p_init_pic_anims
    # Init animation
    CDoom.lastanim = CDoom.anims
    i = 0
    while CDoom.animdefs[i].istexture != -1
      if CDoom.animdefs[i].istexture != 0
        # different episode ?
        if CDoom.r_check_texture_num_for_name(CDoom.animdefs[i].startname) == -1
          i += 1
          next
        end

        CDoom.lastanim.value.picnum = CDoom.r_texture_num_for_name(CDoom.animdefs[i].endname)
        CDoom.lastanim.value.basepic = CDoom.r_texture_num_for_name(CDoom.animdefs[i].startname)
      else
        if CDoom.w_check_num_for_name(CDoom.animdefs[i].startname) == -1
          i += 1
          next
        end

        CDoom.lastanim.value.picnum = CDoom.r_flat_num_for_name(CDoom.animdefs[i].endname)
        CDoom.lastanim.value.basepic = CDoom.r_flat_num_for_name(CDoom.animdefs[i].startname)
      end

      CDoom.lastanim.value.istexture = CDoom.animdefs[i].istexture
      CDoom.lastanim.value.numpics = CDoom.lastanim.value.picnum - CDoom.lastanim.value.basepic + 1

      if CDoom.lastanim.value.numpics < 2
        CDoom.i_error("Error: p_init_pic_anims: bad cycle from #{CDoom.animdefs[i].startname} to #{CDoom.animdefs[i].endname}")
      end

      CDoom.lastanim.value.speed = CDoom.animdefs[i].speed
      CDoom.lastanim += 1

      i += 1
    end
  end

  #
  # Will return a side_t*
  #  given the number of the current sector,
  #  the line number, and the side (0/1) that you want.
  #
  def self.get_side(current_sector : LibC::Int, line : LibC::Int, side : LibC::Int) : CDoom::Side*
    return CDoom.sides + CDoom.sectors[current_sector].lines[line].value.sidenum[side]
  end

  #
  # Will return a sector_t*
  #  given the number of the current sector,
  #  the line number and the side (0/1) that you want.
  #
  def self.get_sector(current_sector : LibC::Int, line : LibC::Int, side : LibC::Int) : CDoom::Sector*
    return CDoom.sides[CDoom.sectors[current_sector].lines[line].value.sidenum[side]].sector
  end

  #
  # Given the sector number and the line number,
  #  it will tell you whether the line is two-sided or not.
  #
  def self.two_sided(sector : LibC::Int, line : LibC::Int) : LibC::Int
    return CDoom.sectors[sector].lines[line].value.flags.to_i32 & CDoom::ML_TWOSIDED
  end

  #
  # Return sector_t * of sector next to current.
  # 0 if not two-sided line
  #
  def self.get_next_sector(line : CDoom::Line*, sec : CDoom::Sector*) : CDoom::Sector*
    return Pointer(CDoom::Sector).null if line.value.flags & CDoom::ML_TWOSIDED == 0

    return line.value.backsector if line.value.frontsector == sec

    return line.value.frontsector
  end

  #
  # FIND LOWEST FLOOR HEIGHT IN SURROUNDING SECTORS
  #
  def self.p_find_lowest_floor_surrounding(sec : CDoom::Sector*) : CDoom::Fixed
    floor = sec.value.floorheight

    sec.value.linecount.times do |i|
      check = sec.value.lines[i]
      other = CDoom.get_next_sector(check, sec)

      next if other.null?

      floor = other.value.floorheight if other.value.floorheight < floor
    end

    return floor
  end

  #
  # FIND HIGHEST FLOOR HEIGHT IN SURROUNDING SECTORS
  #
  def self.p_find_highest_floor_surrounding(sec : CDoom::Sector*) : CDoom::Fixed
    floor = -500 * FRACUNIT

    sec.value.linecount.times do |i|
      check = sec.value.lines[i]
      other = CDoom.get_next_sector(check, sec)

      next if other.null?

      floor = other.value.floorheight if other.value.floorheight > floor
    end

    return floor
  end

  #
  # FIND NEXT HIGHEST FLOOR IN SURROUNDING SECTORS
  # Note: this should be doable w/o a fixed array.
  #
  def self.p_find_next_highest_floor(sec : CDoom::Sector*, currentheight : LibC::Int) : CDoom::Fixed
    height = currentheight

    heightlist = uninitialized StaticArray(CDoom::Fixed, CDoom::MAX_ADJOINING_SECTORS)

    h = 0
    sec.value.linecount.times do |i|
      check = sec.value.lines[i]
      other = CDoom.get_next_sector(check, sec)

      next if other.null?

      if other.value.floorheight > height
        heightlist[h] = other.value.floorheight
        h += 1
      end

      # Check for overflow. Exit.
      if h >= CDoom::MAX_ADJOINING_SECTORS
        puts "Sector with more than 20 adjoining sectors"
        break
      end
    end

    # Find lowest height in list
    return currentheight if h == 0

    min = heightlist[0]

    # Range checking?
    i = 1
    while i < h
      min = heightlist[i] if heightlist[i] < min
      i += 1
    end

    return min
  end

  #
  # FIND LOWEST CEILING IN THE SURROUNDING SECTORS
  #
  def self.p_find_lowest_ceiling_surrounding(sec : CDoom::Sector*) : CDoom::Fixed
    height = Int32::MAX

    sec.value.linecount.times do |i|
      check = sec.value.lines[i]
      other = CDoom.get_next_sector(check, sec)

      next if other.null?

      height = other.value.ceilingheight if other.value.ceilingheight < height
    end

    return height
  end

  #
  # FIND HIGHEST CEILING IN THE SURROUNDING SECTORS
  #
  def self.p_find_highest_ceiling_surrounding(sec : CDoom::Sector*) : CDoom::Fixed
    height = 0

    sec.value.linecount.times do |i|
      check = sec.value.lines[i]
      other = CDoom.get_next_sector(check, sec)

      next if other.null?

      height = other.value.ceilingheight if other.value.ceilingheight > height
    end

    return height
  end

  #
  # RETURN NEXT SECTOR # THAT LINE TAG REFERS TO
  #
  def self.p_find_sector_from_line_tag(line : CDoom::Line*, start : LibC::Int) : LibC::Int
    i = start + 1
    while i < CDoom.numsectors
      return i if CDoom.sectors[i].tag == line.value.tag
      i += 1
    end

    return -1
  end

  #
  # Find minimum light from an adjacent sector
  #
  def self.p_find_min_surrounding_light(sector : CDoom::Sector*, max : LibC::Int) : LibC::Int
    min = max
    sector.value.linecount.times do |i|
      line = sector.value.lines[i]
      check = CDoom.get_next_sector(line, sector)

      next if check.null?

      min = check.value.lightlevel.to_i32 if check.value.lightlevel < min
    end

    return min
  end

  #
  # EVENTS
  # Events are operations triggered by using, crossing,
  # or shooting special lines, or by timed thinkers.
  #

  #
  # Called every time a thing origin is about
  #  to cross a line with a non 0 special.
  #
  def self.p_cross_special_line(linenum : LibC::Int, side : LibC::Int, thing : CDoom::Mobj*)
    line = CDoom.lines + linenum

    #        Triggers that other things can activate
    if thing.value.player.null?
      # Things that should NOT trigger specials...
      case thing.value.type
      when CDoom::Mobjtype::MT_ROCKET,
           CDoom::Mobjtype::MT_PLASMA,
           CDoom::Mobjtype::MT_BFG,
           CDoom::Mobjtype::MT_TROOPSHOT,
           CDoom::Mobjtype::MT_HEADSHOT,
           CDoom::Mobjtype::MT_BRUISERSHOT
        return
      end

      # [ds] Point of ok?
      ok = 0
      case line.value.special
      when 39,  # TELEPORT TRIGGER
           97,  # TELEPORT RETRIGGER
           125, # TELEPORT MONSTERONLY TRIGGER
           126, # TELEPORT MONSTERONLY RETRIGGER
           4,   # RAISE DOOR
           10,  # PLAT DOWN-WAIT-UP-STAY TRIGGER
           88   # PLAT DOWN-WAIT-UP-STAY RETRIGGER
        ok = 1
      end

      return if ok == 0
    end

    # Note: could use some const's here.
    case line.value.special
    # TRIGGERS.
    # All from here to RETRIGGERS.
    when 2
      # Open Door
      CDoom.ev_do_door(line, CDoom::Vldoorenum::DoorOpen)
      line.value.special = 0
    when 3
      # Close Door
      CDoom.ev_do_door(line, CDoom::Vldoorenum::DoorClose)
      line.value.special = 0
    when 4
      # Raise Door
      CDoom.ev_do_door(line, CDoom::Vldoorenum::DoorNormal)
      line.value.special = 0
    when 5
      # Raise Floor
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloor)
      line.value.special = 0
    when 6
      # Fast Ceiling Crush & Raise
      CDoom.ev_do_ceiling(line, CDoom::Ceilingenum::FastCrushAndRaise)
      line.value.special = 0
    when 8
      # Build Stairs
      CDoom.ev_build_stairs(line, CDoom::Stairenum::Build8)
      line.value.special = 0
    when 10
      # PlatDownWaitUp
      CDoom.ev_do_plat(line, CDoom::Plattype::DownWaitUpStay, 0)
      line.value.special = 0
    when 12
      # Light Turn On - brightest near
      CDoom.ev_light_turn_on(line, 0)
      line.value.special = 0
    when 13
      # Light Turn On 255
      CDoom.ev_light_turn_on(line, 255)
      line.value.special = 0
    when 16
      # Close Door 30
      CDoom.ev_do_door(line, CDoom::Vldoorenum::Close30ThenOpen)
      line.value.special = 0
    when 17
      # Start Light Strobing
      CDoom.ev_start_light_strobing(line)
      line.value.special = 0
    when 19
      # Lower Floor
      CDoom.ev_do_floor(line, CDoom::Floorenum::LowerFloor)
      line.value.special = 0
    when 22
      # Raise floor to nearest height and change texture
      CDoom.ev_do_plat(line, CDoom::Plattype::RaiseToNearestAndChange, 0)
      line.value.special = 0
    when 25
      # Ceiling Crush and Raise
      CDoom.ev_do_ceiling(line, CDoom::Ceilingenum::CrushAndRaise)
      line.value.special = 0
    when 30
      # Raise floor to shortest texture height
      #  on either side of lines.
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseToTexture)
      line.value.special = 0
    when 35
      # Lights Very Dark
      CDoom.ev_light_turn_on(line, 35)
      line.value.special = 0
    when 36
      # Lower Floor (TURBO)
      CDoom.ev_do_floor(line, CDoom::Floorenum::TurboLower)
      line.value.special = 0
    when 37
      # LowerAndChange
      CDoom.ev_do_floor(line, CDoom::Floorenum::LowerAndChange)
      line.value.special = 0
    when 38
      # Lower Floor to Lowest
      CDoom.ev_do_floor(line, CDoom::Floorenum::LowerFloorToLowest)
      line.value.special = 0
    when 39
      # TELEPORT!
      CDoom.ev_teleport(line, side, thing)
      line.value.special = 0
    when 40
      # RaiseCeilingLowerFloor
      CDoom.ev_do_ceiling(line, CDoom::Ceilingenum::RaiseToHighest)
      CDoom.ev_do_floor(line, CDoom::Floorenum::LowerFloorToLowest)
      line.value.special = 0
    when 44
      # Ceiling Crush
      CDoom.ev_do_ceiling(line, CDoom::Ceilingenum::LowerAndCrush)
      line.value.special = 0
    when 52
      # EXIT!
      CDoom.g_exit_level
    when 53
      # Perpetual Platform Raise
      CDoom.ev_do_plat(line, CDoom::Plattype::PerpetualRaise, 0)
      line.value.special = 0
    when 54
      # Platform Stop
      CDoom.ev_stop_plat(line)
      line.value.special = 0
    when 56
      # Raise Floor Crush
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloorCrush)
      line.value.special = 0
    when 57
      # Ceiling Crush Stop
      CDoom.ev_ceiling_crush_stop(line)
      line.value.special = 0
    when 58
      # Raise Floor 24
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloor24)
      line.value.special = 0
    when 59
      # Raise Floor 24 And Change
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloor24AndChange)
      line.value.special = 0
    when 104
      # Turn lights off in sector(tag)
      CDoom.ev_turn_tag_lights_off(line)
      line.value.special = 0
    when 108
      # Blazing Door Raise (faster than TURBO!)
      CDoom.ev_do_door(line, CDoom::Vldoorenum::BlazeRaise)
      line.value.special = 0
    when 109
      # Blazing Door Open (faster than TURBO!)
      CDoom.ev_do_door(line, CDoom::Vldoorenum::BlazeOpen)
      line.value.special = 0
    when 100
      # Build Stairs Turbo 16
      CDoom.ev_build_stairs(line, CDoom::Stairenum::Turbo16)
      line.value.special = 0
    when 110
      # Blazing Door Close (faster than TURBO!)
      CDoom.ev_do_door(line, CDoom::Vldoorenum::BlazeClose)
      line.value.special = 0
    when 119
      # Raise floor to nearest surr. floor
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloorToNearest)
      line.value.special = 0
    when 121
      # Blazing PlatDownWaitUpStay
      CDoom.ev_do_plat(line, CDoom::Plattype::BlazeDWUS, 0)
      line.value.special = 0
    when 124
      # Secret EXIT
      CDoom.g_secret_exit_level
    when 125
      # TELEPORT MonsterONLY
      if thing.value.player.null?
        CDoom.ev_teleport(line, side, thing)
        line.value.special = 0
      end
    when 130
      # Raise Floor Turbo
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloorTurbo)
      line.value.special = 0
    when 141
      # Silent Ceiling Crush & Raise
      CDoom.ev_do_ceiling(line, CDoom::Ceilingenum::SilentCrushAndRaise)
      line.value.special = 0
      # RETRIGGERS.  All from here till end.
    when 72
      # Ceiling Crush
      CDoom.ev_do_ceiling(line, CDoom::Ceilingenum::LowerAndCrush)
    when 73
      # Ceiling Crush and Raise
      CDoom.ev_do_ceiling(line, CDoom::Ceilingenum::CrushAndRaise)
    when 74
      # Ceiling Crush Stop
      CDoom.ev_ceiling_crush_stop(line)
    when 75
      # Close Door
      CDoom.ev_do_door(line, CDoom::Vldoorenum::DoorClose)
    when 76
      # Close Door 30
      CDoom.ev_do_door(line, CDoom::Vldoorenum::Close30ThenOpen)
    when 77
      # FastCeiling Crush & Raise
      CDoom.ev_do_ceiling(line, CDoom::Ceilingenum::FastCrushAndRaise)
    when 79
      # Lights Very Dark
      CDoom.ev_light_turn_on(line, 35)
    when 80
      # Light Turn On - brightest near
      CDoom.ev_light_turn_on(line, 0)
    when 81
      # Light Turn On 255
      CDoom.ev_light_turn_on(line, 255)
    when 82
      # Lower Floor To Lowest
      CDoom.ev_do_floor(line, CDoom::Floorenum::LowerFloorToLowest)
    when 83
      # Lower Floor
      CDoom.ev_do_floor(line, CDoom::Floorenum::LowerFloor)
    when 84
      # LowerAndChange
      CDoom.ev_do_floor(line, CDoom::Floorenum::LowerAndChange)
    when 86
      # Open Door
      CDoom.ev_do_door(line, CDoom::Vldoorenum::DoorOpen)
    when 87
      # Perpetual Platform Raise
      CDoom.ev_do_plat(line, CDoom::Plattype::PerpetualRaise, 0)
    when 88
      # PlatDownWaitUp
      CDoom.ev_do_plat(line, CDoom::Plattype::DownWaitUpStay, 0)
    when 89
      # Platform Stop
      CDoom.ev_stop_plat(line)
    when 90
      # Raise Door
      CDoom.ev_do_door(line, CDoom::Vldoorenum::DoorNormal)
    when 91
      # Raise Floor
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloor)
    when 92
      # Raise Floor 24
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloor24)
    when 93
      # Raise Floor 24 And Change
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloor24AndChange)
    when 94
      # Raise Floor Crush
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloorCrush)
    when 95
      # Raise floor to nearest height
      # and change texture.
      CDoom.ev_do_plat(line, CDoom::Plattype::RaiseToNearestAndChange, 0)
    when 96
      # Raise floor to shortest texture height
      # on either side of lines.
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseToTexture)
    when 97
      # TELEPORT !
      CDoom.ev_teleport(line, side, thing)
    when 98
      # Lower Floor (TURBO)
      CDoom.ev_do_floor(line, CDoom::Floorenum::TurboLower)
    when 105
      # Blazing Door Raise (faster than TURBO!)
      CDoom.ev_do_door(line, CDoom::Vldoorenum::BlazeRaise)
    when 106
      # Blazing Door Open (faster than TURBO!)
      CDoom.ev_do_door(line, CDoom::Vldoorenum::BlazeOpen)
    when 107
      # Blazing Door Close (faster than TURBO!)
      CDoom.ev_do_door(line, CDoom::Vldoorenum::BlazeClose)
    when 120
      # Blazing PlatDownWaitUpStay.
      CDoom.ev_do_plat(line, CDoom::Plattype::BlazeDWUS, 0)
    when 126
      # TELEPORT MonsterONLY>
      if thing.value.player.null?
        CDoom.ev_teleport(line, side, thing)
      end
    when 128
      # Raise to Nearest Floor
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloorToNearest)
    when 129
      # Raise Floor Turbo
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloorTurbo)
    end
  end

  #
  # Called when a thing shoots a special line.
  #
  def self.p_shoot_special_line(thing : CDoom::Mobj*, line : CDoom::Line*)
    # Impacts that other things can activate.
    if thing.value.player.null?
      ok = 0 # [ds] Pointless ok again?
      case line.value.special
      when 46
        # OPEN DOOR IMPACT
        ok = 1
      end
      return if ok == 0
    end

    case line.value.special
    when 24
      # RAISE FLOOR
      CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloor)
      CDoom.p_change_switch_texture(line, 0)
    when 46
      # OPEN DOOR
      CDoom.ev_do_door(line, CDoom::Vldoorenum::DoorOpen)
      CDoom.p_change_switch_texture(line, 1)
    when 47
      # RAISE FLOOR NEAR AND CHANGE
      CDoom.ev_do_plat(line, CDoom::Plattype::RaiseToNearestAndChange, 0)
      CDoom.p_change_switch_texture(line, 0)
    end
  end

  #
  # Called every tic frame
  #  that the player origin is in a special sector
  #
  def self.p_player_in_special_sector(player : CDoom::Player*)
    sector = player.value.mo.value.subsector.value.sector

    # Falling, not all the way down yet?
    return if player.value.mo.value.z != sector.value.floorheight

    # Has hitten ground.
    case sector.value.special
    when 5
      # HELLSLIME DAMAGE
      if player.value.powers[CDoom::Powertype::Ironfeet.value] == 0 &&
         CDoom.leveltime & 0x1f == 0
        CDoom.p_damage_mobj(player.value.mo, Pointer(CDoom::Mobj).null, Pointer(CDoom::Mobj).null, 10)
      end
    when 7
      # NUKAGE DAMAGE
      if player.value.powers[CDoom::Powertype::Ironfeet.value] == 0 &&
         CDoom.leveltime & 0x1f == 0
        CDoom.p_damage_mobj(player.value.mo, Pointer(CDoom::Mobj).null, Pointer(CDoom::Mobj).null, 5)
      end
    when 16, # SUPER HELLSLIME DAMAGE
         4   # STROBE HURT
      if (player.value.powers[CDoom::Powertype::Ironfeet.value] == 0 ||
         CDoom.p_random < 5) && CDoom.leveltime & 0x1f == 0
        CDoom.p_damage_mobj(player.value.mo, Pointer(CDoom::Mobj).null, Pointer(CDoom::Mobj).null, 20)
      end
    when 9
      # SECRET SECTOR
      player.value.secretcount = player.value.secretcount + 1
      player.value.message = "A secret is revealed!"
      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_getpow.value)
      sector.value.special = 0
    when 11
      # EXIT SUPER DAMAGE! (for E1M8 finale)
      player.value.cheats = player.value.cheats & ~CDoom::Cheat::CF_GODMODE.value

      CDoom.p_damage_mobj(player.value.mo, Pointer(CDoom::Mobj).null, Pointer(CDoom::Mobj).null, 20) if CDoom.leveltime & 0x1f == 0

      CDoom.g_exit_level if player.value.health <= 10
    else
      CDoom.i_error("Error: p_player_in_special_sector: unknown special #{sector.value.special}")
    end
  end

  #
  # Animate planes, scroll walls, etc.
  #
  def self.p_update_specials
    # LEVEL TIMER
    if CDoom.level_timer != 0
      CDoom.level_time_count -= 1
      CDoom.g_exit_level if CDoom.level_time_count == 0
    end

    # ANIMATE FLATS AND TEXTURES GLOBALLY
    anim = CDoom.anims.to_unsafe
    while anim < CDoom.lastanim
      i = anim.value.basepic
      while i < anim.value.basepic + anim.value.numpics
        pic = anim.value.basepic + ((CDoom.leveltime // anim.value.speed + i) % anim.value.numpics)
        if anim.value.istexture != 0
          CDoom.texturetranslation[i] = pic
        else
          CDoom.flattranslation[i] = pic
        end

        i += 1
      end

      anim += 1
    end

    # ANIMATE LINE SPECIALS
    CDoom.numlinespecials.times do |i|
      line = CDoom.linespeciallist[i]
      case line.value.special
      when 48
        # EFFECT FIRSTCOL SCROLL +
        (CDoom.sides + line.value.sidenum[0]).value.textureoffset = CDoom.sides[line.value.sidenum[0]].textureoffset + FRACUNIT
      end
    end

    # DO BUTTONS
    CDoom::MAXBUTTONS.times do |i|
      if CDoom.buttonlist[i].btimer != 0
        (CDoom.buttonlist.to_unsafe + i).value.btimer = CDoom.buttonlist[i].btimer - 1
        if CDoom.buttonlist[i].btimer == 0
          case CDoom.buttonlist[i].where
          when CDoom::Bwhere::Top
            (CDoom.sides + CDoom.buttonlist[i].line.value.sidenum[0]).value.toptexture =
              CDoom.buttonlist[i].btexture
          when CDoom::Bwhere::Middle
            (CDoom.sides + CDoom.buttonlist[i].line.value.sidenum[0]).value.midtexture =
              CDoom.buttonlist[i].btexture
          when CDoom::Bwhere::Bottom
            (CDoom.sides + CDoom.buttonlist[i].line.value.sidenum[0]).value.bottomtexture =
              CDoom.buttonlist[i].btexture
          end
          CDoom.s_start_sound(pointerof((CDoom.buttonlist.to_unsafe + i).value.@soundorg),
            CDoom::Sfxenum::SFX_swtchn.value)
          CDoom.doom_memset(CDoom.buttonlist.to_unsafe + i, 0, sizeof(CDoom::Button))
        end
      end
    end
  end

  #
  # Special Stuff that can not be categorized
  #
  def self.ev_do_donut(line : CDoom::Line*) : LibC::Int
    secnum = -1
    rtn = 0
    while (secnum = CDoom.p_find_sector_from_line_tag(line, secnum)) >= 0
      s1 = CDoom.sectors + secnum

      # ALREADY MOVING?  IF SO, KEEP GOING...
      next if !s1.value.specialdata.null?

      rtn = 1
      s2 = CDoom.get_next_sector(s1.value.lines[0], s1)
      s2.value.linecount.times do |i|
        if s2.value.lines[i].value.flags & CDoom::ML_TWOSIDED == 0 ||
           s2.value.lines[i].value.backsector == s1
          next
        end
        s3 = s2.value.lines[i].value.backsector

        #        Spawn rising slime
        floor = CDoom.z_malloc(sizeof(CDoom::Floormove), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Floormove*)
        CDoom.p_add_thinker(pointerof(floor.value.@thinker))
        s2.value.specialdata = floor
        pointerof(floor.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_move_floor).pointer, Pointer(Void).null)
        floor.value.type = CDoom::Floorenum::DonutRaise
        floor.value.crush = 0
        floor.value.direction = 1
        floor.value.sector = s2
        floor.value.speed = CDoom::FLOORSPEED // 2
        floor.value.texture = s3.value.floorpic
        floor.value.newspecial = 0
        floor.value.floordestheight = s3.value.floorheight

        #        Spawn lowering donut-hole
        floor = CDoom.z_malloc(sizeof(CDoom::Floormove), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Floormove*)
        CDoom.p_add_thinker(pointerof(floor.value.@thinker))
        s1.value.specialdata = floor
        pointerof(floor.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_move_floor).pointer, Pointer(Void).null)
        floor.value.type = CDoom::Floorenum::LowerFloor
        floor.value.crush = 0
        floor.value.direction = -1
        floor.value.sector = s1
        floor.value.speed = CDoom::FLOORSPEED // 2
        floor.value.floordestheight = s3.value.floorheight
        break
      end
    end

    return rtn
  end

  #
  # SPECIAL SPAWNING
  #

  #
  # After the map has been loaded, scan for specials
  #  that spawn thinkers
  #

  # Parses command line parameters.
  def self.p_spawn_specials
    episode = 1
    episode = 2 if CDoom.w_check_num_for_name("texture2") >= 0

    # See if -TIMER needs to be used.
    CDoom.level_timer = 0

    i = ARGV.index("-avg")
    if i && CDoom.deathmatch != 0
      CDoom.level_timer = 1
      CDoom.level_time_count = 20 * 60 * 35
    end

    i = ARGV.index("-timer")
    if i && CDoom.deathmatch != 0
      time = CDoom.doom_atoi(ARGV[i + 1]) * 60 * 35
      CDoom.level_timer = 1
      CDoom.level_time_count = time
    end

    #        Init special SECTORs.
    sector = CDoom.sectors
    CDoom.numsectors.times do |i|
      if sector.value.special == 0
        sector += 1
        next
      end

      case sector.value.special
      when 1
        # FLICKERING LIGHTS
        CDoom.p_spawn_light_flash(sector)
      when 2
        # STROBE FAST
        CDoom.p_spawn_strobe_flash(sector, CDoom::FASTDARK, 0)
      when 3
        # STROBE SLOW
        CDoom.p_spawn_strobe_flash(sector, CDoom::SLOWDARK, 0)
      when 4
        CDoom.p_spawn_strobe_flash(sector, CDoom::FASTDARK, 0)
        sector.value.special = 4
      when 8
        # GLOWING LIGHT
        CDoom.p_spawn_glowing_light(sector)
      when 9
        # SECRET SECTOR
        CDoom.totalsecret += 1
      when 10
        # DOOR CLOSE IN 30 SECONDS
        CDoom.p_spawn_door_close_in_30(sector)
      when 12
        # SYNC STROBE SLOW
        CDoom.p_spawn_strobe_flash(sector, CDoom::SLOWDARK, 1)
      when 13
        # SYNC STROBE FAST
        CDoom.p_spawn_strobe_flash(sector, CDoom::FASTDARK, 1)
      when 14
        # DOOR RAISE IN 5 MINUTES
        CDoom.p_spawn_door_raise_in_5_mins(sector, i)
      when 17
        CDoom.p_spawn_fire_flicker(sector)
      end

      sector += 1
    end

    # Init line EFFECTs
    CDoom.numlinespecials = 0
    CDoom.numlines.times do |i|
      case CDoom.lines[i].special
      when 48
        # EFFECT FIRSTCOL SCROLL+
        CDoom.linespeciallist[CDoom.numlinespecials] = CDoom.lines + i
        CDoom.numlinespecials += 1
      end
    end

    # Init other misc stuff
    CDoom::MAXCEILINGS.times { |i| CDoom.activeceilings[i] = Pointer(CDoom::Ceiling).null }

    CDoom::MAXPLATS.times { |i| CDoom.activeplats[i] = Pointer(CDoom::Plat).null }

    CDoom::MAXBUTTONS.times { |i| CDoom.doom_memset(CDoom.buttonlist.to_unsafe + i, 0, sizeof(CDoom::Button)) }
  end

  #
  # Only called at game initialization
  #
  def self.p_init_switch_list
    episode = 1

    if CDoom.gamemode == CDoom::GameMode::Registered || CDoom.gamemode == CDoom::GameMode::Retail
      episode = 2
    else
      episode = 3 if CDoom.gamemode == CDoom::GameMode::Commercial
    end

    index = 0
    CDoom::MAXSWITCHES.times do |i|
      if CDoom.alph_switch_list[i].episode == 0
        CDoom.numswitches = index // 2
        CDoom.switchlist[index] = -1
        break
      end

      if CDoom.alph_switch_list[i].episode <= episode
        CDoom.switchlist[index] = CDoom.r_texture_num_for_name(CDoom.alph_switch_list[i].name1)
        index += 1
        CDoom.switchlist[index] = CDoom.r_texture_num_for_name(CDoom.alph_switch_list[i].name2)
        index += 1
      end
    end

    CDoom.numswitches.times { |i| @@switch_origins << CDoom::Degenmobj.new }
  end

  #
  # Start a button counting down till it turns off.
  #
  def self.p_start_button(line : CDoom::Line*, w : CDoom::Bwhere, origin : CDoom::Degenmobj*, texture : LibC::Int, time : LibC::Int)
    # See if button is already pressed
    CDoom::MAXBUTTONS.times do |i|
      return if CDoom.buttonlist[i].btimer != 0 &&
                CDoom.buttonlist[i].line == line
    end

    CDoom::MAXBUTTONS.times do |i|
      if CDoom.buttonlist[i].btimer == 0
        (CDoom.buttonlist.to_unsafe + i).value.line = line
        (CDoom.buttonlist.to_unsafe + i).value.where = w
        (CDoom.buttonlist.to_unsafe + i).value.btexture = texture
        (CDoom.buttonlist.to_unsafe + i).value.btimer = time
        (CDoom.buttonlist.to_unsafe + i).value.soundorg = origin.as(CDoom::Mobj*)

        return
      end
    end

    CDoom.i_error("Error: p_start_button: no button slots left!")
  end

  #
  # Function that changes wall texture.
  # Tell it if switch is ok to use again (1=yes, it's a button).
  #
  def self.p_change_switch_texture(line : CDoom::Line*, use_again : LibC::Int)
    line.value.special = 0 if use_again == 0

    tex_top = CDoom.sides[line.value.sidenum[0]].toptexture
    tex_mid = CDoom.sides[line.value.sidenum[0]].midtexture
    tex_bot = CDoom.sides[line.value.sidenum[0]].bottomtexture
    sound = CDoom::Sfxenum::SFX_swtchn.value

    # EXIT SWITCH?
    if line.value.special == 11
      sound = CDoom::Sfxenum::SFX_swtchx.value
    end

    (CDoom.numswitches * 2).times do |i|
      if CDoom.switchlist[i] == tex_top
        origin = (@@switch_origins.to_unsafe + (i // 2))
        origin.value.x = (line.value.v1.value.x &+ line.value.v2.value.x) // 2
        origin.value.y = (line.value.v1.value.y &+ line.value.v2.value.y) // 2

        CDoom.s_start_sound(origin.as(CDoom::Mobj*), sound)
        (CDoom.sides + line.value.sidenum[0]).value.toptexture = CDoom.switchlist[i ^ 1]

        p_start_button(line, CDoom::Bwhere::Top, origin, CDoom.switchlist[i], CDoom::BUTTONTIME) if use_again != 0

        return
      elsif CDoom.switchlist[i] == tex_mid
        origin = (@@switch_origins.to_unsafe + (i // 2))
        origin.value.x = (line.value.v1.value.x &+ line.value.v2.value.x) // 2
        origin.value.y = (line.value.v1.value.y &+ line.value.v2.value.y) // 2

        CDoom.s_start_sound(origin.as(CDoom::Mobj*), sound)
        (CDoom.sides + line.value.sidenum[0]).value.midtexture = CDoom.switchlist[i ^ 1]

        p_start_button(line, CDoom::Bwhere::Middle, origin, CDoom.switchlist[i], CDoom::BUTTONTIME) if use_again != 0

        return
      elsif CDoom.switchlist[i] == tex_bot
        origin = (@@switch_origins.to_unsafe + (i // 2))
        origin.value.x = (line.value.v1.value.x &+ line.value.v2.value.x) // 2
        origin.value.y = (line.value.v1.value.y &+ line.value.v2.value.y) // 2

        CDoom.s_start_sound(origin.as(CDoom::Mobj*), sound)
        (CDoom.sides + line.value.sidenum[0]).value.bottomtexture = CDoom.switchlist[i ^ 1]

        p_start_button(line, CDoom::Bwhere::Bottom, origin, CDoom.switchlist[i], CDoom::BUTTONTIME) if use_again != 0

        return
      end
    end
  end

  #
  # Called when a thing uses a special line.
  # Only the front sides of lines are usable.
  #
  def self.p_use_special_line(thing : CDoom::Mobj*, line : CDoom::Line*, side : LibC::Int) : CDoom::DoomBool
    # Err...
    # Use the back sides of VERY SPECIAL lines...
    if side != 0
      case line.value.special
      when 124
        # Sliding door open&close
        # UNUSED?
      else
        return 0
      end
    end

    # Switches that other things can activate.
    if thing.value.player.null?
      # never open secret doors
      return 0 if line.value.flags & CDoom::ML_SECRET != 0

      case line.value.special
      when 1,  # MANUAL DOOR RAISE
           32, # MANUAL BLUE
           33, # MANUAL RED
           34  # MANUAL YELLOW
      else
        return 0
      end
    end

    # do something
    case line.value.special
    # MANUALS
    when 1,  # Vertical Door
         26, # Blue Door/Locked
         27, # Yellow Door /Locked
         28, # Red Door /Locked

         31, # Manual door open
         32, # Blue locked door open
         33, # Red locked door open
         34, # Yellow locked door open

         117, # Blazing door raise
         118  # Blazing door open
      CDoom.ev_vertical_door(line, thing)
      # UNUSED - Door Slide Open&Close
      # when 124
      # CDoom.ev_sliding_door(line, thing)

      # SWITCHES
    when 7
      # Build Stairs
      if CDoom.ev_build_stairs(line, CDoom::Stairenum::Build8) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 9
      # Change Donut
      if CDoom.ev_do_donut(line) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 11
      # Exit level
      CDoom.p_change_switch_texture(line, 0)
      CDoom.g_exit_level
    when 14
      # Raise Floor 32 and change texture
      if CDoom.ev_do_plat(line, CDoom::Plattype::RaiseAndChange, 32) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 15
      # Raise Floor 24 and change texture
      if CDoom.ev_do_plat(line, CDoom::Plattype::RaiseAndChange, 24) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 18
      # Raise Floor to next highest floor
      if CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloorToNearest) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 20
      # Raise Plat next highest floor and change texture
      if CDoom.ev_do_plat(line, CDoom::Plattype::RaiseToNearestAndChange, 0) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 21
      # PlatDownWaitUpStay
      if CDoom.ev_do_plat(line, CDoom::Plattype::DownWaitUpStay, 0) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 23
      # Lower Floor to Lowest
      if CDoom.ev_do_floor(line, CDoom::Floorenum::LowerFloorToLowest) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 29
      # Raise Door
      if CDoom.ev_do_door(line, CDoom::Vldoorenum::DoorNormal) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 41
      # Lower Ceiling to Floor
      if CDoom.ev_do_ceiling(line, CDoom::Ceilingenum::LowerToFloor) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 71
      # Turbo Lower Floor
      if CDoom.ev_do_floor(line, CDoom::Floorenum::TurboLower) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 49
      # Ceiling Crush And Raise
      if CDoom.ev_do_ceiling(line, CDoom::Ceilingenum::CrushAndRaise) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 50
      # Close Door
      if CDoom.ev_do_door(line, CDoom::Vldoorenum::DoorClose) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 51
      # Secret EXIT
      CDoom.p_change_switch_texture(line, 0)
      CDoom.g_secret_exit_level
    when 55
      # Raise Floor Crush
      if CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloorCrush) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 101
      # Raise Floor
      if CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloor) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 102
      # Lower Floor to Surrounding floor height
      if CDoom.ev_do_floor(line, CDoom::Floorenum::LowerFloor) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 103
      # Open Door
      if CDoom.ev_do_door(line, CDoom::Vldoorenum::DoorOpen) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 111
      # Blazing Door Raise (faster than TURBO!)
      if CDoom.ev_do_door(line, CDoom::Vldoorenum::BlazeRaise) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 112
      # Blazing Door Open (faster than TURBO!)
      if CDoom.ev_do_door(line, CDoom::Vldoorenum::BlazeOpen) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 113
      # Blazing Door Raise (faster than TURBO!)
      if CDoom.ev_do_door(line, CDoom::Vldoorenum::BlazeClose) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 122
      # Blazing PlatDownWaitUpStay
      if CDoom.ev_do_plat(line, CDoom::Plattype::BlazeDWUS, 0) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 127
      # Build Stairs Turbo 16
      if CDoom.ev_build_stairs(line, CDoom::Stairenum::Turbo16) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 131
      # Raise Floor Turbo
      if CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloorTurbo) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 133, # BlzOpenDoor BLUE
         135, # BlzOpenDoor RED
         137  # BlzOpenDoor YELLOW
      if CDoom.ev_do_locked_door(line, CDoom::Vldoorenum::BlazeOpen, thing) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
    when 140
      # Raise Floor 512
      if CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloor512) != 0
        CDoom.p_change_switch_texture(line, 0)
      end
      # BUTTONS
    when 42
      # Close Door
      if CDoom.ev_do_door(line, CDoom::Vldoorenum::DoorClose) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 43
      # Lower Ceiling to Floor
      if CDoom.ev_do_ceiling(line, CDoom::Ceilingenum::LowerToFloor) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 45
      # Lower Floor to Surrounding floor height
      if CDoom.ev_do_floor(line, CDoom::Floorenum::LowerFloor) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 60
      # Raise Floor to Lowest
      if CDoom.ev_do_floor(line, CDoom::Floorenum::LowerFloorToLowest) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 61
      # Open Door
      if CDoom.ev_do_door(line, CDoom::Vldoorenum::DoorOpen) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 62
      # PlatDownWaitUpStay
      if CDoom.ev_do_plat(line, CDoom::Plattype::DownWaitUpStay, 1) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 63
      # Raise Door
      if CDoom.ev_do_door(line, CDoom::Vldoorenum::DoorNormal) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 64
      # Raise Floor to ceiling
      if CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloor) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 66
      # Raise Floor 24 and change texture
      if CDoom.ev_do_plat(line, CDoom::Plattype::RaiseAndChange, 24) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 67
      # Raise Floor 32 and change texture
      if CDoom.ev_do_plat(line, CDoom::Plattype::RaiseAndChange, 32) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 65
      # Raise Floor Crush
      if CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloorCrush) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 68
      # Raise Plat to next highest floor and change texture
      if CDoom.ev_do_plat(line, CDoom::Plattype::RaiseToNearestAndChange, 0) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 69
      # Raise Floor to next highest floor
      if CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloorToNearest) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 70
      # Turbo Lower Floor
      if CDoom.ev_do_floor(line, CDoom::Floorenum::TurboLower) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 114
      # Blazing Door Raise (faster than TURBO!)
      if CDoom.ev_do_door(line, CDoom::Vldoorenum::BlazeRaise) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 115
      # Blazing Door Open (faster than TURBO!)
      if CDoom.ev_do_door(line, CDoom::Vldoorenum::BlazeOpen) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 116
      # Blazing Door Close (faster than TURBO!)
      if CDoom.ev_do_door(line, CDoom::Vldoorenum::BlazeClose) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 123
      # Blazing PlatDownWaitUpStay
      if CDoom.ev_do_plat(line, CDoom::Plattype::BlazeDWUS, 0) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 132
      # Raise Floor Turbo
      if CDoom.ev_do_floor(line, CDoom::Floorenum::RaiseFloorTurbo) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 99,  # BlzOpenDoor BLUE
         134, # BlzOpenDoor RED
         136  # BlzOpenDoor YELLOW
      if CDoom.ev_do_locked_door(line, CDoom::Vldoorenum::BlazeOpen, thing) != 0
        CDoom.p_change_switch_texture(line, 1)
      end
    when 138
      # Light Turn On
      CDoom.ev_light_turn_on(line, 255)
      CDoom.p_change_switch_texture(line, 1)
    when 139
      # Light Turn Off
      CDoom.ev_light_turn_on(line, 35)
      CDoom.p_change_switch_texture(line, 1)
    end
    return 1
  end

  def self.ev_teleport(line : CDoom::Line*, side : LibC::Int, thing : CDoom::Mobj*) : LibC::Int
    # don't teleport missiles
    return 0 if thing.value.flags & CDoom::Mobjflag::MF_MISSILE.value != 0

    # Don't teleport if hit back of line,
    #  so you can get out of teleporter.
    return 0 if side == 1

    tag = line.value.tag
    CDoom.numsectors.times do |i|
      if CDoom.sectors[i].tag == tag
        thinker = CDoom.thinkercap.next
        while thinker != pointerof(CDoom.thinkercap)
          # not a mobj
          if thinker.value.function.acp1.pointer != (->CDoom.p_mobj_thinker).pointer
            thinker = thinker.value.next
            next
          end

          m = thinker.as(CDoom::Mobj*)

          # not a teleportman
          if m.value.type != CDoom::Mobjtype::MT_TELEPORTMAN
            thinker = thinker.value.next
            next
          end

          sector = m.value.subsector.value.sector
          # wrong sector
          if sector - CDoom.sectors != i
            thinker = thinker.value.next
            next
          end

          oldx = thing.value.x
          oldy = thing.value.y
          oldz = thing.value.z

          return 0 if CDoom.p_teleport_move(thing, m.value.x, m.value.y) == 0

          thing.value.z = thing.value.floorz # fixme: not needed?
          thing.value.player.value.viewz = thing.value.z + thing.value.player.value.viewheight if !thing.value.player.null?

          # spawn a teleport fog at source and destination
          fog = CDoom.p_spawn_mobj(oldx, oldy, oldz, CDoom::Mobjtype::MT_TFOG)
          CDoom.s_start_sound(fog, CDoom::Sfxenum::SFX_telept.value)
          an = m.value.angle >> CDoom::ANGLETOFINESHIFT
          fog = CDoom.p_spawn_mobj(m.value.x + 20 * @@finecosine[an], m.value.y + 20 * @@finesine[an],
            thing.value.z, CDoom::Mobjtype::MT_TFOG)

          # emit sound, where?
          CDoom.s_start_sound(fog, CDoom::Sfxenum::SFX_telept.value)

          # don't move for a bit
          thing.value.reactiontime = 18 if !thing.value.player.null?

          thing.value.angle = m.value.angle
          thing.value.momx = 0
          thing.value.momy = 0
          thing.value.momz = 0
          return 1

          thinker = thinker.value.next
        end
      end
    end

    return 0
  end

  #
  # THINKERS
  # All thinkers should be allocated by Z_Malloc
  # so they can be operated on uniformly.
  # The actual structures will vary in size,
  # but the first element must be thinker_t.
  #

  def self.p_init_thinkers
    CDoom.thinkercap.prev = pointerof(CDoom.thinkercap)
    CDoom.thinkercap.next = pointerof(CDoom.thinkercap)
  end

  #
  # Adds a new thinker at the end of the list.
  #
  def self.p_add_thinker(thinker : CDoom::Thinker*)
    CDoom.thinkercap.prev.value.next = thinker
    thinker.value.next = pointerof(CDoom.thinkercap)
    thinker.value.prev = CDoom.thinkercap.prev
    CDoom.thinkercap.prev = thinker
    thinker.value.remove = 0
  end

  #
  # Deallocation is lazy -- it will not actually be freed
  # until its thinking turn comes up.
  #
  def self.p_remove_thinker(thinker : CDoom::Thinker*)
    thinker.value.remove = 1
  end

  def self.p_run_thinkers
    currentthinker = CDoom.thinkercap.next
    while currentthinker != pointerof(CDoom.thinkercap)
      if currentthinker.value.remove != 0
        # time to remove it
        currentthinker.value.next.value.prev = currentthinker.value.prev
        currentthinker.value.prev.value.next = currentthinker.value.next
        CDoom.z_free(currentthinker)
      else
        currentthinker.value.function.acp1.call(currentthinker.as(Void*)) if !currentthinker.value.function.acp1.pointer.null?
      end
      currentthinker = currentthinker.value.next
    end
  end

  def self.p_ticker
    # run the tic
    return if CDoom.paused != 0

    # pause if in menu and at least one tic has been run
    if CDoom.netgame == 0 &&
       CDoom.menuactive != 0 &&
       CDoom.demoplayback == 0 &&
       CDoom.players[CDoom.consoleplayer].viewz != 1
      return
    end
    CDoom::MAXPLAYERS.times { |i| CDoom.p_player_think(CDoom.players.to_unsafe + i) if CDoom.playeringame[i] != 0 }

    CDoom.p_run_thinkers
    CDoom.p_update_specials
    CDoom.p_respawn_specials

    # for par times
    CDoom.leveltime += 1
  end

  #
  # Movement.
  #

  #
  # Moves the given origin along a given angle.
  #
  def self.p_thrust(player : CDoom::Player*, angle : CDoom::Angle, move : CDoom::Fixed)
    angle >>= CDoom::ANGLETOFINESHIFT

    player.value.mo.value.momx = player.value.mo.value.momx + CDoom.fixed_mul(move, @@finecosine[angle])
    player.value.mo.value.momy = player.value.mo.value.momy + CDoom.fixed_mul(move, @@finesine[angle])
  end

  #
  # Calculate the walking / running height adjustment
  #
  def self.p_calc_height(player : CDoom::Player*)
    # Regular movement bobbing
    # (needs to be calculated for gun swing
    # even if not on ground)
    # OPTIMIZE: tablify angle
    # Note: a LUT allows for effects
    #  like a ramp with low health.
    player.value.bob =
      CDoom.fixed_mul(player.value.mo.value.momx, player.value.mo.value.momx) +
        CDoom.fixed_mul(player.value.mo.value.momy, player.value.mo.value.momy)

    player.value.bob = player.value.bob >> 2

    player.value.bob = CDoom::MAXBOB if player.value.bob > CDoom::MAXBOB

    if player.value.cheats & CDoom::Cheat::CF_NOMOMENTUM.value != 0 || CDoom.onground == 0
      player.value.viewz = player.value.mo.value.z + CDoom::VIEWHEIGHT

      if player.value.viewz > player.value.mo.value.ceilingz - 4 * FRACUNIT
        player.value.viewz = player.value.mo.value.ceilingz - 4 * FRACUNIT
      end

      player.value.viewz = player.value.mo.value.z + player.value.viewheight
      return
    end

    angle = (CDoom::FINEANGLES.tdiv(20) * CDoom.leveltime) & CDoom::FINEMASK
    bob = CDoom.fixed_mul(player.value.bob.tdiv(2), @@finesine[angle])

    # move viewheight
    if player.value.playerstate == CDoom::Playerstate::PST_LIVE
      player.value.viewheight = player.value.viewheight + player.value.deltaviewheight

      if player.value.viewheight > CDoom::VIEWHEIGHT
        player.value.viewheight = CDoom::VIEWHEIGHT
        player.value.deltaviewheight = 0
      end

      if player.value.viewheight < CDoom::VIEWHEIGHT // 2
        player.value.viewheight = CDoom::VIEWHEIGHT // 2
        player.value.deltaviewheight = 1 if player.value.deltaviewheight <= 0
      end

      if player.value.deltaviewheight != 0
        player.value.deltaviewheight = player.value.deltaviewheight + FRACUNIT // 4
        player.value.deltaviewheight = 1 if player.value.deltaviewheight == 0
      end
    end

    player.value.viewz = player.value.mo.value.z + player.value.viewheight + bob

    if player.value.viewz > player.value.mo.value.ceilingz - 4 * FRACUNIT
      player.value.viewz = player.value.mo.value.ceilingz - 4 * FRACUNIT
    end
  end

  def self.p_move_player(player : CDoom::Player*)
    cmd = pointerof(player.value.@cmd)

    player.value.mo.value.angle = player.value.mo.value.angle &+ (cmd.value.angleturn.to_i32 << 16)

    # Do not let the player control movement
    #  if not onground.
    CDoom.onground = (player.value.mo.value.z <= player.value.mo.value.floorz).to_unsafe

    CDoom.p_thrust(player, player.value.mo.value.angle, cmd.value.forwardmove.to_i32 * 2048) if cmd.value.forwardmove != 0 && CDoom.onground != 0

    CDoom.p_thrust(player, player.value.mo.value.angle &- ANG90, cmd.value.sidemove.to_i32 * 2048) if cmd.value.sidemove != 0 && CDoom.onground != 0

    if (cmd.value.forwardmove != 0 || cmd.value.sidemove != 0) &&
       player.value.mo.value.state == CDoom.states + CDoom::Statenum::S_PLAY.value
      CDoom.p_set_mobj_state(player.value.mo, CDoom::Statenum::S_PLAY_RUN1)
    end
  end

  #
  # Fall on your face when dying.
  # Decrease POV height to floor height.
  #

  def self.p_death_think(player : CDoom::Player*)
    CDoom.p_move_psprites(player)

    # fall to the ground
    player.value.viewheight = player.value.viewheight - FRACUNIT if player.value.viewheight > 6 * FRACUNIT

    player.value.viewheight = 6 * FRACUNIT if player.value.viewheight < 6 * FRACUNIT

    player.value.deltaviewheight = 0
    CDoom.onground = (player.value.mo.value.z <= player.value.mo.value.floorz).to_unsafe
    CDoom.p_calc_height(player)

    if !player.value.attacker.null? && player.value.attacker != player.value.mo
      angle = CDoom.r_point_to_angle2(player.value.mo.value.x,
        player.value.mo.value.y,
        player.value.attacker.value.x,
        player.value.attacker.value.y)

      delta = angle &- player.value.mo.value.angle

      if delta < CDoom::ANG5 || delta > (-CDoom::ANG5).to_u32!
        # Looking at killer,
        #  so fade damage flash down.
        player.value.mo.value.angle = angle

        player.value.damagecount = player.value.damagecount - 1 if player.value.damagecount != 0
      elsif delta < ANG180
        player.value.mo.value.angle = player.value.mo.value.angle &+ CDoom::ANG5
      else
        player.value.mo.value.angle = player.value.mo.value.angle &- CDoom::ANG5
      end
    elsif player.value.damagecount != 0
      player.value.damagecount = player.value.damagecount - 1
    end

    player.value.playerstate = CDoom::Playerstate::PST_REBORN if player.value.cmd.buttons & CDoom::Buttoncode::BT_USE.value != 0
  end

  def self.p_player_think(player : CDoom::Player*)
    if player.value.cheats & CDoom::Cheat::CF_NOCLIP.value != 0
      player.value.mo.value.flags = player.value.mo.value.flags | CDoom::Mobjflag::MF_NOCLIP.value
    else
      player.value.mo.value.flags = player.value.mo.value.flags & ~CDoom::Mobjflag::MF_NOCLIP.value
    end

    # chain saw run forward
    cmd = pointerof(player.value.@cmd)
    if player.value.mo.value.flags & CDoom::Mobjflag::MF_JUSTATTACKED.value != 0
      cmd.value.angleturn = 0
      cmd.value.forwardmove = 0xc800 // 512
      cmd.value.sidemove = 0
      player.value.mo.value.flags = player.value.mo.value.flags & ~CDoom::Mobjflag::MF_JUSTATTACKED.value
    end

    if player.value.playerstate == CDoom::Playerstate::PST_DEAD
      CDoom.p_death_think(player)
      return
    end

    # Move around.
    # Reactiontime is used to prevent movement
    #  for a bit after a teleport.
    if player.value.mo.value.reactiontime != 0
      player.value.mo.value.reactiontime = player.value.mo.value.reactiontime - 1
    else
      CDoom.p_move_player(player)
    end

    CDoom.p_calc_height(player)

    CDoom.p_player_in_special_sector(player) if player.value.mo.value.subsector.value.sector.value.special != 0

    # Check for weapon change.

    # A special event has no other buttons.
    cmd.value.buttons = 0 if cmd.value.buttons & CDoom::Buttoncode::BT_SPECIAL.value != 0

    if cmd.value.buttons & CDoom::Buttoncode::BT_CHANGE.value != 0
      # The actual changing of the weapon is done
      #  when the weapon psprite can do it
      #  (read: not in the middle of an attack).
      newweapon = CDoom::Weapontype.new((cmd.value.buttons & CDoom::Buttoncode::BT_WEAPONMASK.value) >> CDoom::Buttoncode::BT_WEAPONSHIFT.value)

      if newweapon == CDoom::Weapontype::Fist &&
         player.value.weaponowned[CDoom::Weapontype::Chainsaw.value] != 0 &&
         !(player.value.readyweapon == CDoom::Weapontype::Chainsaw &&
         player.value.powers[CDoom::Powertype::Strength.value] != 0)
        newweapon = CDoom::Weapontype::Chainsaw
      end

      if CDoom.gamemode == CDoom::GameMode::Commercial &&
         newweapon == CDoom::Weapontype::Shotgun &&
         player.value.weaponowned[CDoom::Weapontype::Supershotgun.value] != 0 &&
         player.value.readyweapon != CDoom::Weapontype::Supershotgun
        newweapon = CDoom::Weapontype::Supershotgun
      end

      if player.value.weaponowned[newweapon.value] != 0 &&
         newweapon != player.value.readyweapon
        # Do not go to plasma or BFG in shareware,
        #  even if cheated.
        if (newweapon != CDoom::Weapontype::Plasma &&
           newweapon != CDoom::Weapontype::Bfg) ||
           CDoom.gamemode != CDoom::GameMode::Shareware
          player.value.pendingweapon = newweapon
        end
      end
    end

    # check for use
    if cmd.value.buttons & CDoom::Buttoncode::BT_USE.value != 0
      if player.value.usedown == 0
        CDoom.p_use_lines(player)
        player.value.usedown = 1
      end
    else
      player.value.usedown = 0
    end

    # cycle psprites
    CDoom.p_move_psprites(player)

    # Counters, time dependend power ups.

    # Strength counts up to diminish fade
    if player.value.powers[CDoom::Powertype::Strength.value] != 0
      player.value.powers[CDoom::Powertype::Strength.value] =
        player.value.powers[CDoom::Powertype::Strength.value] &+ 1
    end

    if player.value.powers[CDoom::Powertype::Invulnerability.value] != 0
      player.value.powers[CDoom::Powertype::Invulnerability.value] =
        player.value.powers[CDoom::Powertype::Invulnerability.value] - 1
    end

    if player.value.powers[CDoom::Powertype::Invisibility.value] != 0
      player.value.powers[CDoom::Powertype::Invisibility.value] =
        player.value.powers[CDoom::Powertype::Invisibility.value] - 1
      if player.value.powers[CDoom::Powertype::Invisibility.value] == 0
        player.value.mo.value.flags = player.value.mo.value.flags & ~CDoom::Mobjflag::MF_SHADOW.value
      end
    end

    if player.value.powers[CDoom::Powertype::Infrared.value] != 0
      player.value.powers[CDoom::Powertype::Infrared.value] =
        player.value.powers[CDoom::Powertype::Infrared.value] - 1
    end

    if player.value.powers[CDoom::Powertype::Ironfeet.value] != 0
      player.value.powers[CDoom::Powertype::Ironfeet.value] =
        player.value.powers[CDoom::Powertype::Ironfeet.value] - 1
    end

    player.value.damagecount = player.value.damagecount - 1 if player.value.damagecount != 0

    player.value.bonuscount = player.value.bonuscount - 1 if player.value.bonuscount != 0

    # Handling colormaps.
    if player.value.powers[CDoom::Powertype::Invulnerability.value] != 0
      if player.value.powers[CDoom::Powertype::Invulnerability.value] > 4 * 32 ||
         player.value.powers[CDoom::Powertype::Invulnerability.value] & 8 != 0
        player.value.fixedcolormap = CDoom::INVERSECOLORMAP
      else
        player.value.fixedcolormap = 0
      end
    elsif player.value.powers[CDoom::Powertype::Infrared.value] != 0
      if player.value.powers[CDoom::Powertype::Infrared.value] > 4 * 32 ||
         player.value.powers[CDoom::Powertype::Infrared.value] & 8 != 0
        # almost full bright
        player.value.fixedcolormap = 1
      else
        player.value.fixedcolormap = 0
      end
    else
      player.value.fixedcolormap = 0
    end
  end
end
