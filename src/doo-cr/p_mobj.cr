# Map Objects, MObj, definition and handling.

module Doocr
  enum Mobjflag
    # Call P_SpecialThing when touched.
    SPECIAL = 1
    # Blocks.
    SOLID = 2
    # Can be hit.
    SHOOTABLE = 4
    # Don't use the sector links (invisible but touchable).
    NOSECTOR = 8
    # Don't use the blocklinks (inert but displayable)
    NOBLOCKMAP = 16

    # Not to be activated by sound, deaf monster.
    AMBUSH = 32
    # Will try to attack right back.
    JUSTHIT = 64
    # Will take at least one step before attacking.
    JUSTATTACKED = 128
    # On level spawning (initial position),
    #  hang from ceiling instead of stand on floor.
    SPAWNCEILING = 256
    # Don't apply gravity (every tic),
    #  that is, object will float, keeping current height
    #  or changing it actively.
    NOGRAVITY = 512

    # Movement flags.
    # This allows jumps from high places.
    DROPOFF = 0x400
    # For players, will pick up items.
    PICKUP = 0x800
    # Player cheat. ???
    NOCLIP = 0x1000
    # Player: keep info about sliding along walls.
    SLIDE = 0x2000
    # Allow moves to any height, no gravity.
    # For active floaters, e.g. cacodemons, pain elementals.
    FLOAT = 0x4000
    # Don't cross lines
    #   ??? or look at heights on teleport.
    TELEPORT = 0x8000
    # Don't hit same species, explode on block.
    # Player missiles as well as fireballs of various kinds.
    MISSILE = 0x10000
    # Dropped by a demon, not level spawned.
    # E.g. ammo clips dropped by dying former humans.
    DROPPED = 0x20000
    # Use fuzzy draw (shadow demons or spectres),
    #  temporary player invisibility powerup.
    SHADOW = 0x40000
    # Flag: don't bleed when shot (use puff),
    #  barrels and shootable furniture shall not bleed.
    NOBLOOD = 0x80000
    # Don't stop moving halfway off a step,
    #  that is, have dead bodies slide down all the way.
    CORPSE = 0x100000
    # Floating to a height for a move, ???
    #  don't auto float to target's height.
    INFLOAT = 0x200000

    # On kill, count this enemy object
    #  towards intermission kill total.
    # Happy gathering.
    COUNTKILL = 0x400000

    # On picking up, count this item object
    #  towards intermission item total.
    COUNTITEM = 0x800000

    # Special handling: skull in flight.
    # Neither a cacodemon nor a missile.
    SKULLFLY = 0x1000000

    # Don't spawn this object
    #  in death match mode (e.g. key cards).
    NOTDMATCH = 0x2000000

    # Player sprites in multiplayer modes are modified
    #  using an internal color lookup table for re-indexing.
    # If 0x4 0x8 or 0xc,
    #  use a translation table for player colormaps
    TRANSLATION = 0xc000000
    # Hmm ???.
    TRANSSHIFT = 26
  end
end
