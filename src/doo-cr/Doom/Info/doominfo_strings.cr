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
    module Strings
      PRESSKEY  = DoomString.new("PRESSKEY", "press a key.")
      PRESSYN   = DoomString.new("PRESSYN", "press y or n.")
      QUITMSG   = DoomString.new("QUITMSG", "are you sure you want to\nquit this great game?")
      LOADNET   = DoomString.new("LOADNET", "you can't do load while in a net game!\n\n" + PRESSKEY)
      QLOADNET  = DoomString.new("QLOADNET", "you can't quickload during a netgame!\n\n" + PRESSKEY)
      QSAVESPOT = DoomString.new("QSAVESPOT", "you haven't picked a quicksave slot yet!\n\n" + PRESSKEY)
      SAVEDEAD  = DoomString.new("SAVEDEAD", "you can't save if you aren't playing!\n\n" + PRESSKEY)
      QSPROMPT  = DoomString.new("QSPROMPT", "quicksave over your game named\n\n'%s'?\n\n" + PRESSYN)
      QLPROMPT  = DoomString.new("QLPROMPT", "do you want to quickload the game named\n\n'%s'?\n\n" + PRESSYN)

      NEWGAME = DoomString.new("NEWGAME",
        "you can't start a new game\n" +
        "while in a network game.\n\n" + PRESSKEY)

      NIGHTMARE = DoomString.new("NIGHTMARE",
        "are you sure? this skill level\n" +
        "isn't even remotely fair.\n\n" + PRESSYN)

      SWSTRING = DoomString.new("SWSTRING",
        "this is the shareware version of doom.\n\n" +
        "you need to order the entire trilogy.\n\n" + PRESSKEY)

      MSGOFF             = DoomString.new("MSGOFF", "Messages OFF")
      MSGON              = DoomString.new("MSGON", "Messages ON")
      NETEND             = DoomString.new("NETEND", "you can't end a netgame!\n\n" + PRESSKEY)
      ENDGAME            = DoomString.new("ENDGAME", "are you sure you want to end the game?\n\n" + PRESSYN)
      DOSY               = DoomString.new("DOSY", "(press y to quit)")
      GAMMALVL0          = DoomString.new("GAMMALVL0", "Gamma correction OFF")
      GAMMALVL1          = DoomString.new("GAMMALVL1", "Gamma correction level 1")
      GAMMALVL2          = DoomString.new("GAMMALVL2", "Gamma correction level 2")
      GAMMALVL3          = DoomString.new("GAMMALVL3", "Gamma correction level 3")
      GAMMALVL4          = DoomString.new("GAMMALVL4", "Gamma correction level 4")
      EMPTYSTRING        = DoomString.new("EMPTYSTRING", "empty slot")
      GOTARMOR           = DoomString.new("GOTARMOR", "Picked up the armor.")
      GOTMEGA            = DoomString.new("GOTMEGA", "Picked up the MegaArmor!")
      GOTHTHBONUS        = DoomString.new("GOTHTHBONUS", "Picked up a health bonus.")
      GOTARMBONUS        = DoomString.new("GOTARMBONUS", "Picked up an armor bonus.")
      GOTSTIM            = DoomString.new("GOTSTIM", "Picked up a stimpack.")
      GOTMEDINEED        = DoomString.new("GOTMEDINEED", "Picked up a medikit that you REALLY need!")
      GOTMEDIKIT         = DoomString.new("GOTMEDIKIT", "Picked up a medikit.")
      GOTSUPER           = DoomString.new("GOTSUPER", "Supercharge!")
      GOTBLUECARD        = DoomString.new("GOTBLUECARD", "Picked up a blue keycard.")
      GOTYELWCARD        = DoomString.new("GOTYELWCARD", "Picked up a yellow keycard.")
      GOTREDCARD         = DoomString.new("GOTREDCARD", "Picked up a red keycard.")
      GOTBLUESKUL        = DoomString.new("GOTBLUESKUL", "Picked up a blue skull key.")
      GOTYELWSKUL        = DoomString.new("GOTYELWSKUL", "Picked up a yellow skull key.")
      GOTREDSKULL        = DoomString.new("GOTREDSKULL", "Picked up a red skull key.")
      GOTINVUL           = DoomString.new("GOTINVUL", "Invulnerability!")
      GOTBERSERK         = DoomString.new("GOTBERSERK", "Berserk!")
      GOTINVIS           = DoomString.new("GOTINVIS", "Partial Invisibility")
      GOTSUIT            = DoomString.new("GOTSUIT", "Radiation Shielding Suit")
      GOTMAP             = DoomString.new("GOTMAP", "Computer Area Map")
      GOTVISOR           = DoomString.new("GOTVISOR", "Light Amplification Visor")
      GOTMSPHERE         = DoomString.new("GOTMSPHERE", "MegaSphere!")
      GOTCLIP            = DoomString.new("GOTCLIP", "Picked up a clip.")
      GOTCLIPBOX         = DoomString.new("GOTCLIPBOX", "Picked up a box of bullets.")
      GOTROCKET          = DoomString.new("GOTROCKET", "Picked up a rocket.")
      GOTROCKBOX         = DoomString.new("GOTROCKBOX", "Picked up a box of rockets.")
      GOTCELL            = DoomString.new("GOTCELL", "Picked up an energy cell.")
      GOTCELLBOX         = DoomString.new("GOTCELLBOX", "Picked up an energy cell pack.")
      GOTSHELLS          = DoomString.new("GOTSHELLS", "Picked up 4 shotgun shells.")
      GOTSHELLBOX        = DoomString.new("GOTSHELLBOX", "Picked up a box of shotgun shells.")
      GOTBACKPACK        = DoomString.new("GOTBACKPACK", "Picked up a backpack full of ammo!")
      GOTBFG9000         = DoomString.new("GOTBFG9000", "You got the BFG9000!  Oh, yes.")
      GOTCHAINGUN        = DoomString.new("GOTCHAINGUN", "You got the chaingun!")
      GOTCHAINSAW        = DoomString.new("GOTCHAINSAW", "A chainsaw!  Find some meat!")
      GOTLAUNCHER        = DoomString.new("GOTLAUNCHER", "You got the rocket launcher!")
      GOTPLASMA          = DoomString.new("GOTPLASMA", "You got the plasma gun!")
      GOTSHOTGUN         = DoomString.new("GOTSHOTGUN", "You got the shotgun!")
      GOTSHOTGUN2        = DoomString.new("GOTSHOTGUN2", "You got the super shotgun!")
      PD_BLUEO           = DoomString.new("PD_BLUEO", "You need a blue key to activate this object")
      PD_REDO            = DoomString.new("PD_REDO", "You need a red key to activate this object")
      PD_YELLOWO         = DoomString.new("PD_YELLOWO", "You need a yellow key to activate this object")
      PD_BLUEK           = DoomString.new("PD_BLUEK", "You need a blue key to open this door")
      PD_REDK            = DoomString.new("PD_REDK", "You need a red key to open this door")
      PD_YELLOWK         = DoomString.new("PD_YELLOWK", "You need a yellow key to open this door")
      GGSAVED            = DoomString.new("GGSAVED", "game saved.")
      HUSTR_E1M1         = DoomString.new("HUSTR_E1M1", "E1M1: Hangar")
      HUSTR_E1M2         = DoomString.new("HUSTR_E1M2", "E1M2: Nuclear Plant")
      HUSTR_E1M3         = DoomString.new("HUSTR_E1M3", "E1M3: Toxin Refinery")
      HUSTR_E1M4         = DoomString.new("HUSTR_E1M4", "E1M4: Command Control")
      HUSTR_E1M5         = DoomString.new("HUSTR_E1M5", "E1M5: Phobos Lab")
      HUSTR_E1M6         = DoomString.new("HUSTR_E1M6", "E1M6: Central Processing")
      HUSTR_E1M7         = DoomString.new("HUSTR_E1M7", "E1M7: Computer Station")
      HUSTR_E1M8         = DoomString.new("HUSTR_E1M8", "E1M8: Phobos Anomaly")
      HUSTR_E1M9         = DoomString.new("HUSTR_E1M9", "E1M9: Military Base")
      HUSTR_E2M1         = DoomString.new("HUSTR_E2M1", "E2M1: Deimos Anomaly")
      HUSTR_E2M2         = DoomString.new("HUSTR_E2M2", "E2M2: Containment Area")
      HUSTR_E2M3         = DoomString.new("HUSTR_E2M3", "E2M3: Refinery")
      HUSTR_E2M4         = DoomString.new("HUSTR_E2M4", "E2M4: Deimos Lab")
      HUSTR_E2M5         = DoomString.new("HUSTR_E2M5", "E2M5: Command Center")
      HUSTR_E2M6         = DoomString.new("HUSTR_E2M6", "E2M6: Halls of the Damned")
      HUSTR_E2M7         = DoomString.new("HUSTR_E2M7", "E2M7: Spawning Vats")
      HUSTR_E2M8         = DoomString.new("HUSTR_E2M8", "E2M8: Tower of Babel")
      HUSTR_E2M9         = DoomString.new("HUSTR_E2M9", "E2M9: Fortress of Mystery")
      HUSTR_E3M1         = DoomString.new("HUSTR_E3M1", "E3M1: Hell Keep")
      HUSTR_E3M2         = DoomString.new("HUSTR_E3M2", "E3M2: Slough of Despair")
      HUSTR_E3M3         = DoomString.new("HUSTR_E3M3", "E3M3: Pandemonium")
      HUSTR_E3M4         = DoomString.new("HUSTR_E3M4", "E3M4: House of Pain")
      HUSTR_E3M5         = DoomString.new("HUSTR_E3M5", "E3M5: Unholy Cathedral")
      HUSTR_E3M6         = DoomString.new("HUSTR_E3M6", "E3M6: Mt. Erebus")
      HUSTR_E3M7         = DoomString.new("HUSTR_E3M7", "E3M7: Limbo")
      HUSTR_E3M8         = DoomString.new("HUSTR_E3M8", "E3M8: Dis")
      HUSTR_E3M9         = DoomString.new("HUSTR_E3M9", "E3M9: Warrens")
      HUSTR_E4M1         = DoomString.new("HUSTR_E4M1", "E4M1: Hell Beneath")
      HUSTR_E4M2         = DoomString.new("HUSTR_E4M2", "E4M2: Perfect Hatred")
      HUSTR_E4M3         = DoomString.new("HUSTR_E4M3", "E4M3: Sever The Wicked")
      HUSTR_E4M4         = DoomString.new("HUSTR_E4M4", "E4M4: Unruly Evil")
      HUSTR_E4M5         = DoomString.new("HUSTR_E4M5", "E4M5: They Will Repent")
      HUSTR_E4M6         = DoomString.new("HUSTR_E4M6", "E4M6: Against Thee Wickedly")
      HUSTR_E4M7         = DoomString.new("HUSTR_E4M7", "E4M7: And Hell Followed")
      HUSTR_E4M8         = DoomString.new("HUSTR_E4M8", "E4M8: Unto The Cruel")
      HUSTR_E4M9         = DoomString.new("HUSTR_E4M9", "E4M9: Fear")
      HUSTR_1            = DoomString.new("HUSTR_1", "level 1: entryway")
      HUSTR_2            = DoomString.new("HUSTR_2", "level 2: underhalls")
      HUSTR_3            = DoomString.new("HUSTR_3", "level 3: the gantlet")
      HUSTR_4            = DoomString.new("HUSTR_4", "level 4: the focus")
      HUSTR_5            = DoomString.new("HUSTR_5", "level 5: the waste tunnels")
      HUSTR_6            = DoomString.new("HUSTR_6", "level 6: the crusher")
      HUSTR_7            = DoomString.new("HUSTR_7", "level 7: dead simple")
      HUSTR_8            = DoomString.new("HUSTR_8", "level 8: tricks and traps")
      HUSTR_9            = DoomString.new("HUSTR_9", "level 9: the pit")
      HUSTR_10           = DoomString.new("HUSTR_10", "level 10: refueling base")
      HUSTR_11           = DoomString.new("HUSTR_11", "level 11: 'o' of destruction!")
      HUSTR_12           = DoomString.new("HUSTR_12", "level 12: the factory")
      HUSTR_13           = DoomString.new("HUSTR_13", "level 13: downtown")
      HUSTR_14           = DoomString.new("HUSTR_14", "level 14: the inmost dens")
      HUSTR_15           = DoomString.new("HUSTR_15", "level 15: industrial zone")
      HUSTR_16           = DoomString.new("HUSTR_16", "level 16: suburbs")
      HUSTR_17           = DoomString.new("HUSTR_17", "level 17: tenements")
      HUSTR_18           = DoomString.new("HUSTR_18", "level 18: the courtyard")
      HUSTR_19           = DoomString.new("HUSTR_19", "level 19: the citadel")
      HUSTR_20           = DoomString.new("HUSTR_20", "level 20: gotcha!")
      HUSTR_21           = DoomString.new("HUSTR_21", "level 21: nirvana")
      HUSTR_22           = DoomString.new("HUSTR_22", "level 22: the catacombs")
      HUSTR_23           = DoomString.new("HUSTR_23", "level 23: barrels o' fun")
      HUSTR_24           = DoomString.new("HUSTR_24", "level 24: the chasm")
      HUSTR_25           = DoomString.new("HUSTR_25", "level 25: bloodfalls")
      HUSTR_26           = DoomString.new("HUSTR_26", "level 26: the abandoned mines")
      HUSTR_27           = DoomString.new("HUSTR_27", "level 27: monster condo")
      HUSTR_28           = DoomString.new("HUSTR_28", "level 28: the spirit world")
      HUSTR_29           = DoomString.new("HUSTR_29", "level 29: the living end")
      HUSTR_30           = DoomString.new("HUSTR_30", "level 30: icon of sin")
      HUSTR_31           = DoomString.new("HUSTR_31", "level 31: wolfenstein")
      HUSTR_32           = DoomString.new("HUSTR_32", "level 32: grosse")
      PHUSTR_1           = DoomString.new("PHUSTR_1", "level 1: congo")
      PHUSTR_2           = DoomString.new("PHUSTR_2", "level 2: well of souls")
      PHUSTR_3           = DoomString.new("PHUSTR_3", "level 3: aztec")
      PHUSTR_4           = DoomString.new("PHUSTR_4", "level 4: caged")
      PHUSTR_5           = DoomString.new("PHUSTR_5", "level 5: ghost town")
      PHUSTR_6           = DoomString.new("PHUSTR_6", "level 6: baron's lair")
      PHUSTR_7           = DoomString.new("PHUSTR_7", "level 7: caughtyard")
      PHUSTR_8           = DoomString.new("PHUSTR_8", "level 8: realm")
      PHUSTR_9           = DoomString.new("PHUSTR_9", "level 9: abattoire")
      PHUSTR_10          = DoomString.new("PHUSTR_10", "level 10: onslaught")
      PHUSTR_11          = DoomString.new("PHUSTR_11", "level 11: hunted")
      PHUSTR_12          = DoomString.new("PHUSTR_12", "level 12: speed")
      PHUSTR_13          = DoomString.new("PHUSTR_13", "level 13: the crypt")
      PHUSTR_14          = DoomString.new("PHUSTR_14", "level 14: genesis")
      PHUSTR_15          = DoomString.new("PHUSTR_15", "level 15: the twilight")
      PHUSTR_16          = DoomString.new("PHUSTR_16", "level 16: the omen")
      PHUSTR_17          = DoomString.new("PHUSTR_17", "level 17: compound")
      PHUSTR_18          = DoomString.new("PHUSTR_18", "level 18: neurosphere")
      PHUSTR_19          = DoomString.new("PHUSTR_19", "level 19: nme")
      PHUSTR_20          = DoomString.new("PHUSTR_20", "level 20: the death domain")
      PHUSTR_21          = DoomString.new("PHUSTR_21", "level 21: slayer")
      PHUSTR_22          = DoomString.new("PHUSTR_22", "level 22: impossible mission")
      PHUSTR_23          = DoomString.new("PHUSTR_23", "level 23: tombstone")
      PHUSTR_24          = DoomString.new("PHUSTR_24", "level 24: the final frontier")
      PHUSTR_25          = DoomString.new("PHUSTR_25", "level 25: the temple of darkness")
      PHUSTR_26          = DoomString.new("PHUSTR_26", "level 26: bunker")
      PHUSTR_27          = DoomString.new("PHUSTR_27", "level 27: anti-christ")
      PHUSTR_28          = DoomString.new("PHUSTR_28", "level 28: the sewers")
      PHUSTR_29          = DoomString.new("PHUSTR_29", "level 29: odyssey of noises")
      PHUSTR_30          = DoomString.new("PHUSTR_30", "level 30: the gateway of hell")
      PHUSTR_31          = DoomString.new("PHUSTR_31", "level 31: cyberden")
      PHUSTR_32          = DoomString.new("PHUSTR_32", "level 32: go 2 it")
      THUSTR_1           = DoomString.new("THUSTR_1", "level 1: system control")
      THUSTR_2           = DoomString.new("THUSTR_2", "level 2: human bbq")
      THUSTR_3           = DoomString.new("THUSTR_3", "level 3: power control")
      THUSTR_4           = DoomString.new("THUSTR_4", "level 4: wormhole")
      THUSTR_5           = DoomString.new("THUSTR_5", "level 5: hanger")
      THUSTR_6           = DoomString.new("THUSTR_6", "level 6: open season")
      THUSTR_7           = DoomString.new("THUSTR_7", "level 7: prison")
      THUSTR_8           = DoomString.new("THUSTR_8", "level 8: metal")
      THUSTR_9           = DoomString.new("THUSTR_9", "level 9: stronghold")
      THUSTR_10          = DoomString.new("THUSTR_10", "level 10: redemption")
      THUSTR_11          = DoomString.new("THUSTR_11", "level 11: storage facility")
      THUSTR_12          = DoomString.new("THUSTR_12", "level 12: crater")
      THUSTR_13          = DoomString.new("THUSTR_13", "level 13: nukage processing")
      THUSTR_14          = DoomString.new("THUSTR_14", "level 14: steel works")
      THUSTR_15          = DoomString.new("THUSTR_15", "level 15: dead zone")
      THUSTR_16          = DoomString.new("THUSTR_16", "level 16: deepest reaches")
      THUSTR_17          = DoomString.new("THUSTR_17", "level 17: processing area")
      THUSTR_18          = DoomString.new("THUSTR_18", "level 18: mill")
      THUSTR_19          = DoomString.new("THUSTR_19", "level 19: shipping/respawning")
      THUSTR_20          = DoomString.new("THUSTR_20", "level 20: central processing")
      THUSTR_21          = DoomString.new("THUSTR_21", "level 21: administration center")
      THUSTR_22          = DoomString.new("THUSTR_22", "level 22: habitat")
      THUSTR_23          = DoomString.new("THUSTR_23", "level 23: lunar mining project")
      THUSTR_24          = DoomString.new("THUSTR_24", "level 24: quarry")
      THUSTR_25          = DoomString.new("THUSTR_25", "level 25: baron's den")
      THUSTR_26          = DoomString.new("THUSTR_26", "level 26: ballistyx")
      THUSTR_27          = DoomString.new("THUSTR_27", "level 27: mount pain")
      THUSTR_28          = DoomString.new("THUSTR_28", "level 28: heck")
      THUSTR_29          = DoomString.new("THUSTR_29", "level 29: river styx")
      THUSTR_30          = DoomString.new("THUSTR_30", "level 30: last call")
      THUSTR_31          = DoomString.new("THUSTR_31", "level 31: pharaoh")
      THUSTR_32          = DoomString.new("THUSTR_32", "level 32: caribbean")
      AMSTR_FOLLOWON     = DoomString.new("AMSTR_FOLLOWON", "Follow Mode ON")
      AMSTR_FOLLOWOFF    = DoomString.new("AMSTR_FOLLOWOFF", "Follow Mode OFF")
      AMSTR_GRIDON       = DoomString.new("AMSTR_GRIDON", "Grid ON")
      AMSTR_GRIDOFF      = DoomString.new("AMSTR_GRIDOFF", "Grid OFF")
      AMSTR_MARKEDSPOT   = DoomString.new("AMSTR_MARKEDSPOT", "Marked Spot")
      AMSTR_MARKSCLEARED = DoomString.new("AMSTR_MARKSCLEARED", "All Marks Cleared")
      STSTR_MUS          = DoomString.new("STSTR_MUS", "Music Change")
      STSTR_NOMUS        = DoomString.new("STSTR_NOMUS", "IMPOSSIBLE SELECTION")
      STSTR_DQDON        = DoomString.new("STSTR_DQDON", "Degreelessness Mode On")
      STSTR_DQDOFF       = DoomString.new("STSTR_DQDOFF", "Degreelessness Mode Off")
      STSTR_KFAADDED     = DoomString.new("STSTR_KFAADDED", "Very Happy Ammo Added")
      STSTR_FAADDED      = DoomString.new("STSTR_FAADDED", "Ammo (no keys) Added")
      STSTR_NCON         = DoomString.new("STSTR_NCON", "No Clipping Mode ON")
      STSTR_NCOFF        = DoomString.new("STSTR_NCOFF", "No Clipping Mode OFF")
      STSTR_BEHOLD       = DoomString.new("STSTR_BEHOLD", "inVuln, Str, Inviso, Rad, Allmap, or Lite-amp")
      STSTR_BEHOLDX      = DoomString.new("STSTR_BEHOLDX", "Power-up Toggled")
      STSTR_CHOPPERS     = DoomString.new("STSTR_CHOPPERS", "... doesn't suck - GM")
      STSTR_CLEV         = DoomString.new("STSTR_CLEV", "Changing Level...")

      E1TEXT = DoomString.new("E1TEXT",
        "Once you beat the big badasses and\n" +
        "clean out the moon base you're supposed\n" +
        "to win, aren't you? Aren't you? Where's\n" +
        "your fat reward and ticket home? What\n" +
        "the hell is this? It's not supposed to\n" +
        "end this way!\n" +
        "\n" +
        "It stinks like rotten meat, but looks\n" +
        "like the lost Deimos base.  Looks like\n" +
        "you're stuck on The Shores of Hell.\n" +
        "The only way out is through.\n" +
        "\n" +
        "To continue the DOOM experience, play\n" +
        "The Shores of Hell and its amazing\n" +
        "sequel, Inferno!\n")

      E2TEXT = DoomString.new("E2TEXT",
        "You've done it! The hideous cyber-\n" +
        "demon lord that ruled the lost Deimos\n" +
        "moon base has been slain and you\n" +
        "are triumphant! But ... where are\n" +
        "you? You clamber to the edge of the\n" +
        "moon and look down to see the awful\n" +
        "truth.\n" +
        "\n" +
        "Deimos floats above Hell itself!\n" +
        "You've never heard of anyone escaping\n" +
        "from Hell, but you'll make the bastards\n" +
        "sorry they ever heard of you! Quickly,\n" +
        "you rappel down to  the surface of\n" +
        "Hell.\n" +
        "\n" +
        "Now, it's on to the final chapter of\n" +
        "DOOM! -- Inferno.")

      E3TEXT = DoomString.new("E3TEXT",
        "The loathsome spiderdemon that\n" +
        "masterminded the invasion of the moon\n" +
        "bases and caused so much death has had\n" +
        "its ass kicked for all time.\n" +
        "\n" +
        "A hidden doorway opens and you enter.\n" +
        "You've proven too tough for Hell to\n" +
        "contain, and now Hell at last plays\n" +
        "fair -- for you emerge from the door\n" +
        "to see the green fields of Earth!\n" +
        "Home at last.\n" +
        "\n" +
        "You wonder what's been happening on\n" +
        "Earth while you were battling evil\n" +
        "unleashed. It's good that no Hell-\n" +
        "spawn could have come through that\n" +
        "door with you ...")

      E4TEXT = DoomString.new("E4TEXT",
        "the spider mastermind must have sent forth\n" +
        "its legions of hellspawn before your\n" +
        "final confrontation with that terrible\n" +
        "beast from hell.  but you stepped forward\n" +
        "and brought forth eternal damnation and\n" +
        "suffering upon the horde as a true hero\n" +
        "would in the face of something so evil.\n" +
        "\n" +
        "besides, someone was gonna pay for what\n" +
        "happened to daisy, your pet rabbit.\n" +
        "\n" +
        "but now, you see spread before you more\n" +
        "potential pain and gibbitude as a nation\n" +
        "of demons run amok among our cities.\n" +
        "\n" +
        "next stop, hell on earth!")

      C1TEXT = DoomString.new("C1TEXT",
        "YOU HAVE ENTERED DEEPLY INTO THE INFESTED\n" +
        "STARPORT. BUT SOMETHING IS WRONG. THE\n" +
        "MONSTERS HAVE BROUGHT THEIR OWN REALITY\n" +
        "WITH THEM, AND THE STARPORT'S TECHNOLOGY\n" +
        "IS BEING SUBVERTED BY THEIR PRESENCE.\n" +
        "\n" +
        "AHEAD, YOU SEE AN OUTPOST OF HELL, A\n" +
        "FORTIFIED ZONE. IF YOU CAN GET PAST IT,\n" +
        "YOU CAN PENETRATE INTO THE HAUNTED HEART\n" +
        "OF THE STARBASE AND FIND THE CONTROLLING\n" +
        "SWITCH WHICH HOLDS EARTH'S POPULATION\n" +
        "HOSTAGE.")

      C2TEXT = DoomString.new("C2TEXT",
        "YOU HAVE WON! YOUR VICTORY HAS ENABLED\n" +
        "HUMANKIND TO EVACUATE EARTH AND ESCAPE\n" +
        "THE NIGHTMARE.  NOW YOU ARE THE ONLY\n" +
        "HUMAN LEFT ON THE FACE OF THE PLANET.\n" +
        "CANNIBAL MUTATIONS, CARNIVOROUS ALIENS,\n" +
        "AND EVIL SPIRITS ARE YOUR ONLY NEIGHBORS.\n" +
        "YOU SIT BACK AND WAIT FOR DEATH, CONTENT\n" +
        "THAT YOU HAVE SAVED YOUR SPECIES.\n" +
        "\n" +
        "BUT THEN, EARTH CONTROL BEAMS DOWN A\n" +
        "MESSAGE FROM SPACE: \"SENSORS HAVE LOCATED\n" +
        "THE SOURCE OF THE ALIEN INVASION. IF YOU\n" +
        "GO THERE, YOU MAY BE ABLE TO BLOCK THEIR\n" +
        "ENTRY.  THE ALIEN BASE IS IN THE HEART OF\n" +
        "YOUR OWN HOME CITY, NOT FAR FROM THE\n" +
        "STARPORT.\" SLOWLY AND PAINFULLY YOU GET\n" +
        "UP AND RETURN TO THE FRAY.")

      C3TEXT = DoomString.new("C3TEXT",
        "YOU ARE AT THE CORRUPT HEART OF THE CITY,\n" +
        "SURROUNDED BY THE CORPSES OF YOUR ENEMIES.\n" +
        "YOU SEE NO WAY TO DESTROY THE CREATURES'\n" +
        "ENTRYWAY ON THIS SIDE, SO YOU CLENCH YOUR\n" +
        "TEETH AND PLUNGE THROUGH IT.\n" +
        "\n" +
        "THERE MUST BE A WAY TO CLOSE IT ON THE\n" +
        "OTHER SIDE. WHAT DO YOU CARE IF YOU'VE\n" +
        "GOT TO GO THROUGH HELL TO GET TO IT?")

      C4TEXT = DoomString.new("C4TEXT",
        "THE HORRENDOUS VISAGE OF THE BIGGEST\n" +
        "DEMON YOU'VE EVER SEEN CRUMBLES BEFORE\n" +
        "YOU, AFTER YOU PUMP YOUR ROCKETS INTO\n" +
        "HIS EXPOSED BRAIN. THE MONSTER SHRIVELS\n" +
        "UP AND DIES, ITS THRASHING LIMBS\n" +
        "DEVASTATING UNTOLD MILES OF HELL'S\n" +
        "SURFACE.\n" +
        "\n" +
        "YOU'VE DONE IT. THE INVASION IS OVER.\n" +
        "EARTH IS SAVED. HELL IS A WRECK. YOU\n" +
        "WONDER WHERE BAD FOLKS WILL GO WHEN THEY\n" +
        "DIE, NOW. WIPING THE SWEAT FROM YOUR\n" +
        "FOREHEAD YOU BEGIN THE LONG TREK BACK\n" +
        "HOME. REBUILDING EARTH OUGHT TO BE A\n" +
        "LOT MORE FUN THAN RUINING IT WAS.\n")

      C5TEXT = DoomString.new("C5TEXT",
        "CONGRATULATIONS, YOU'VE FOUND THE SECRET\n" +
        "LEVEL! LOOKS LIKE IT'S BEEN BUILT BY\n" +
        "HUMANS, RATHER THAN DEMONS. YOU WONDER\n" +
        "WHO THE INMATES OF THIS CORNER OF HELL\n" +
        "WILL BE.")

      C6TEXT = DoomString.new("C6TEXT",
        "CONGRATULATIONS, YOU'VE FOUND THE\n" +
        "SUPER SECRET LEVEL!  YOU'D BETTER\n" +
        "BLAZE THROUGH THIS ONE!\n")

      P1TEXT = DoomString.new("P1TEXT",
        "You gloat over the steaming carcass of the\n" +
        "Guardian.  With its death, you've wrested\n" +
        "the Accelerator from the stinking claws\n" +
        "of Hell.  You relax and glance around the\n" +
        "room.  Damn!  There was supposed to be at\n" +
        "least one working prototype, but you can't\n" +
        "see it. The demons must have taken it.\n" +
        "\n" +
        "You must find the prototype, or all your\n" +
        "struggles will have been wasted. Keep\n" +
        "moving, keep fighting, keep killing.\n" +
        "Oh yes, keep living, too.")

      P2TEXT = DoomString.new("P2TEXT",
        "Even the deadly Arch-Vile labyrinth could\n" +
        "not stop you, and you've gotten to the\n" +
        "prototype Accelerator which is soon\n" +
        "efficiently and permanently deactivated.\n" +
        "\n" +
        "You're good at that kind of thing.")

      P3TEXT = DoomString.new("P3TEXT",
        "You've bashed and battered your way into\n" +
        "the heart of the devil-hive.  Time for a\n" +
        "Search-and-Destroy mission, aimed at the\n" +
        "Gatekeeper, whose foul offspring is\n" +
        "cascading to Earth.  Yeah, he's bad. But\n" +
        "you know who's worse!\n" +
        "\n" +
        "Grinning evilly, you check your gear, and\n" +
        "get ready to give the bastard a little Hell\n" +
        "of your own making!")

      P4TEXT = DoomString.new("P4TEXT",
        "The Gatekeeper's evil face is splattered\n" +
        "all over the place.  As its tattered corpse\n" +
        "collapses, an inverted Gate forms and\n" +
        "sucks down the shards of the last\n" +
        "prototype Accelerator, not to mention the\n" +
        "few remaining demons.  You're done. Hell\n" +
        "has gone back to pounding bad dead folks \n" +
        "instead of good live ones.  Remember to\n" +
        "tell your grandkids to put a rocket\n" +
        "launcher in your coffin. If you go to Hell\n" +
        "when you die, you'll need it for some\n" +
        "final cleaning-up ...")

      P5TEXT = DoomString.new("P5TEXT",
        "You've found the second-hardest level we\n" +
        "got. Hope you have a saved game a level or\n" +
        "two previous.  If not, be prepared to die\n" +
        "aplenty. For master marines only.")

      P6TEXT = DoomString.new("P6TEXT",
        "Betcha wondered just what WAS the hardest\n" +
        "level we had ready for ya?  Now you know.\n" +
        "No one gets out alive.")

      T1TEXT = DoomString.new("T1TEXT",
        "You've fought your way out of the infested\n" +
        "experimental labs.   It seems that UAC has\n" +
        "once again gulped it down.  With their\n" +
        "high turnover, it must be hard for poor\n" +
        "old UAC to buy corporate health insurance\n" +
        "nowadays..\n" +
        "\n" +
        "Ahead lies the military complex, now\n" +
        "swarming with diseased horrors hot to get\n" +
        "their teeth into you. With luck, the\n" +
        "complex still has some warlike ordnance\n" +
        "laying around.")

      T2TEXT = DoomString.new("T2TEXT",
        "You hear the grinding of heavy machinery\n" +
        "ahead.  You sure hope they're not stamping\n" +
        "out new hellspawn, but you're ready to\n" +
        "ream out a whole herd if you have to.\n" +
        "They might be planning a blood feast, but\n" +
        "you feel about as mean as two thousand\n" +
        "maniacs packed into one mad killer.\n" +
        "\n" +
        "You don't plan to go down easy.")

      T3TEXT = DoomString.new("T3TEXT",
        "The vista opening ahead looks real damn\n" +
        "familiar. Smells familiar, too -- like\n" +
        "fried excrement. You didn't like this\n" +
        "place before, and you sure as hell ain't\n" +
        "planning to like it now. The more you\n" +
        "brood on it, the madder you get.\n" +
        "Hefting your gun, an evil grin trickles\n" +
        "onto your face. Time to take some names.")

      T4TEXT = DoomString.new("T4TEXT",
        "Suddenly, all is silent, from one horizon\n" +
        "to the other. The agonizing echo of Hell\n" +
        "fades away, the nightmare sky turns to\n" +
        "blue, the heaps of monster corpses start \n" +
        "to evaporate along with the evil stench \n" +
        "that filled the air. Jeeze, maybe you've\n" +
        "done it. Have you really won?\n" +
        "\n" +
        "Something rumbles in the distance.\n" +
        "A blue light begins to glow inside the\n" +
        "ruined skull of the demon-spitter.")

      T5TEXT = DoomString.new("T5TEXT",
        "What now? Looks totally different. Kind\n" +
        "of like King Tut's condo. Well,\n" +
        "whatever's here can't be any worse\n" +
        "than usual. Can it?  Or maybe it's best\n" +
        "to let sleeping gods lie..")

      T6TEXT = DoomString.new("T6TEXT",
        "Time for a vacation. You've burst the\n" +
        "bowels of hell and by golly you're ready\n" +
        "for a break. You mutter to yourself,\n" +
        "Maybe someone else can kick Hell's ass\n" +
        "next time around. Ahead lies a quiet town,\n" +
        "with peaceful flowing water, quaint\n" +
        "buildings, and presumably no Hellspawn.\n" +
        "\n" +
        "As you step off the transport, you hear\n" +
        "the stomp of a cyberdemon's iron shoe.")

      CC_ZOMBIE  = DoomString.new("CC_ZOMBIE", "ZOMBIEMAN")
      CC_SHOTGUN = DoomString.new("CC_SHOTGUN", "SHOTGUN GUY")
      CC_HEAVY   = DoomString.new("CC_HEAVY", "HEAVY WEAPON DUDE")
      CC_IMP     = DoomString.new("CC_IMP", "IMP")
      CC_DEMON   = DoomString.new("CC_DEMON", "DEMON")
      CC_LOST    = DoomString.new("CC_LOST", "LOST SOUL")
      CC_CACO    = DoomString.new("CC_CACO", "CACODEMON")
      CC_HELL    = DoomString.new("CC_HELL", "HELL KNIGHT")
      CC_BARON   = DoomString.new("CC_BARON", "BARON OF HELL")
      CC_ARACH   = DoomString.new("CC_ARACH", "ARACHNOTRON")
      CC_PAIN    = DoomString.new("CC_PAIN", "PAIN ELEMENTAL")
      CC_REVEN   = DoomString.new("CC_REVEN", "REVENANT")
      CC_MANCU   = DoomString.new("CC_MANCU", "MANCUBUS")
      CC_ARCH    = DoomString.new("CC_ARCH", "ARCH-VILE")
      CC_SPIDER  = DoomString.new("CC_SPIDER", "THE SPIDER MASTERMIND")
      CC_CYBER   = DoomString.new("CC_CYBER", "THE CYBERDEMON")
      CC_HERO    = DoomString.new("CC_HERO", "OUR HERO")
    end
  end
end
