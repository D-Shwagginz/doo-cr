# Copyright (C) 2026 Devin Shwagginz
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# ==> BEX extended stuff mainly. Also Text blocks

module Doocr
  # Constant values to be changed with string and text

  PRESSKEY = "press a key."
  PRESSYN  = "press y or n."

  @@deh_d_devstr = "Development mode ON.\n"
  @@deh_d_devstr
  @@deh_quit_msg = "are you sure you want to\nquit this great game?"
  @@deh_quit_msg
  @@deh_load_net = "you can't do load while in a net game!\n\n" + PRESSKEY
  @@deh_load_net
  @@deh_qload_net = "you can't quickload during a netgame!\n\n" + PRESSKEY
  @@deh_qload_net
  @@deh_qsave_spot = "you haven't picked a quicksave slot yet!\n\n" + PRESSKEY
  @@deh_qsave_spot
  @@deh_save_dead = "you can't save if you aren't playing!\n\n" + PRESSKEY
  @@deh_save_dead
  @@deh_qsprompt_1 = "quicksave over your game named\n\n'"
  @@deh_qsprompt_1
  @@deh_qsprompt_2 = "'?\n\n" + PRESSYN
  @@deh_qsprompt_2
  @@deh_qlprompt_1 = "do you want to quickload the game named\n\n'"
  @@deh_qlprompt_1
  @@deh_qlprompt_2 = "'?\n\n" + PRESSYN
  @@deh_qlprompt_2
  @@deh_newgame = "you can't start a new game\n" +
                  "while in a network game.\n\n" + PRESSKEY
  @@deh_newgame
  @@deh_nightmare = "are you sure? this skill level\n" +
                    "isn't even remotely fair.\n\n" + PRESSYN
  @@deh_nightmare
  @@deh_swstring = "this is the shareware version of doom.\n\n" +
                   "you need to order the entire trilogy.\n\n" + PRESSKEY
  @@deh_swstring

  # Auto-generated from lib.cr constants matching the BEX string mnemonics table
  @@deh_amstr_followoff = "Follow Mode OFF"
  @@deh_amstr_followoff
  @@deh_amstr_followon = "Follow Mode ON"
  @@deh_amstr_followon
  @@deh_amstr_gridoff = "Grid OFF"
  @@deh_amstr_gridoff
  @@deh_amstr_gridon = "Grid ON"
  @@deh_amstr_gridon
  @@deh_amstr_markedspot = "Marked Spot"
  @@deh_amstr_markedspot
  @@deh_amstr_markscleared = "All Marks Cleared"
  @@deh_amstr_markscleared
  @@deh_c1text = "YOU HAVE ENTERED DEEPLY INTO THE INFESTED\n" +
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
                 "HOSTAGE."
  @@deh_c1text
  @@deh_c2text = "YOU HAVE WON! YOUR VICTORY HAS ENABLED\n" +
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
                 "UP AND RETURN TO THE FRAY."
  @@deh_c2text
  @@deh_c3text = "YOU ARE AT THE CORRUPT HEART OF THE CITY,\n" +
                 "SURROUNDED BY THE CORPSES OF YOUR ENEMIES.\n" +
                 "YOU SEE NO WAY TO DESTROY THE CREATURES'\n" +
                 "ENTRYWAY ON THIS SIDE, SO YOU CLENCH YOUR\n" +
                 "TEETH AND PLUNGE THROUGH IT.\n" +
                 "\n" +
                 "THERE MUST BE A WAY TO CLOSE IT ON THE\n" +
                 "OTHER SIDE. WHAT DO YOU CARE IF YOU'VE\n" +
                 "GOT TO GO THROUGH HELL TO GET TO IT?"
  @@deh_c3text
  @@deh_c4text = "THE HORRENDOUS VISAGE OF THE BIGGEST\n" +
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
                 "LOT MORE FUN THAN RUINING IT WAS.\n"
  @@deh_c4text
  @@deh_c5text = "CONGRATULATIONS, YOU'VE FOUND THE SECRET\n" +
                 "LEVEL! LOOKS LIKE IT'S BEEN BUILT BY\n" +
                 "HUMANS, RATHER THAN DEMONS. YOU WONDER\n" +
                 "WHO THE INMATES OF THIS CORNER OF HELL\n" +
                 "WILL BE."
  @@deh_c5text
  @@deh_c6text = "CONGRATULATIONS, YOU'VE FOUND THE\n" +
                 "SUPER SECRET LEVEL!  YOU'D BETTER\n" +
                 "BLAZE THROUGH THIS ONE!\n"
  @@deh_c6text
  @@deh_cc_arach = "ARACHNOTRON"
  @@deh_cc_arach
  @@deh_cc_arch = "ARCH-VILE"
  @@deh_cc_arch
  @@deh_cc_baron = "BARON OF HELL"
  @@deh_cc_baron
  @@deh_cc_caco = "CACODEMON"
  @@deh_cc_caco
  @@deh_cc_cyber = "THE CYBERDEMON"
  @@deh_cc_cyber
  @@deh_cc_demon = "DEMON"
  @@deh_cc_demon
  @@deh_cc_heavy = "HEAVY WEAPON DUDE"
  @@deh_cc_heavy
  @@deh_cc_hell = "HELL KNIGHT"
  @@deh_cc_hell
  @@deh_cc_hero = "OUR HERO"
  @@deh_cc_hero
  @@deh_cc_imp = "IMP"
  @@deh_cc_imp
  @@deh_cc_lost = "LOST SOUL"
  @@deh_cc_lost
  @@deh_cc_mancu = "MANCUBUS"
  @@deh_cc_mancu
  @@deh_cc_pain = "PAIN ELEMENTAL"
  @@deh_cc_pain
  @@deh_cc_reven = "REVENANT"
  @@deh_cc_reven
  @@deh_cc_shotgun = "SHOTGUN GUY"
  @@deh_cc_shotgun
  @@deh_cc_spider = "THE SPIDER MASTERMIND"
  @@deh_cc_spider
  @@deh_cc_zombie = "ZOMBIEMAN"
  @@deh_cc_zombie
  @@deh_detailhi = "High detail"
  @@deh_detailhi
  @@deh_detaillo = "Low detail"
  @@deh_detaillo
  @@deh_e1text = "Once you beat the big badasses and\n" +
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
                 "sequel, Inferno!\n"
  @@deh_e1text
  @@deh_e2text = "You've done it! The hideous cyber-\n" +
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
                 "DOOM! -- Inferno."
  @@deh_e2text
  @@deh_e3text = "The loathsome spiderdemon that\n" +
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
                 "door with you ..."
  @@deh_e3text
  @@deh_e4text = "the spider mastermind must have sent forth\n" +
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
                 "next stop, hell on earth!"
  @@deh_e4text
  @@deh_emptystring = "empty slot"
  @@deh_emptystring
  @@deh_endgame = "are you sure you want to end the game?\n\n" + PRESSYN
  @@deh_endgame
  @@deh_gammalvl0 = "Gamma correction OFF"
  @@deh_gammalvl0
  @@deh_gammalvl1 = "Gamma correction level 1"
  @@deh_gammalvl1
  @@deh_gammalvl2 = "Gamma correction level 2"
  @@deh_gammalvl2
  @@deh_gammalvl3 = "Gamma correction level 3"
  @@deh_gammalvl3
  @@deh_gammalvl4 = "Gamma correction level 4"
  @@deh_gammalvl4
  @@deh_ggsaved = "game saved."
  @@deh_ggsaved
  @@deh_gotarmbonus = "Picked up an armor bonus."
  @@deh_gotarmbonus
  @@deh_gotarmor = "Picked up the armor."
  @@deh_gotarmor
  @@deh_gotbackpack = "Picked up a backpack full of ammo!"
  @@deh_gotbackpack
  @@deh_gotberserk = "Berserk!"
  @@deh_gotberserk
  @@deh_gotbfg9000 = "You got the BFG9000!  Oh, yes."
  @@deh_gotbfg9000
  @@deh_gotbluecard = "Picked up a blue keycard."
  @@deh_gotbluecard
  @@deh_gotblueskul = "Picked up a blue skull key."
  @@deh_gotblueskul
  @@deh_gotcell = "Picked up an energy cell."
  @@deh_gotcell
  @@deh_gotcellbox = "Picked up an energy cell pack."
  @@deh_gotcellbox
  @@deh_gotchaingun = "You got the chaingun!"
  @@deh_gotchaingun
  @@deh_gotchainsaw = "A chainsaw!  Find some meat!"
  @@deh_gotchainsaw
  @@deh_gotclip = "Picked up a clip."
  @@deh_gotclip
  @@deh_gotclipbox = "Picked up a box of bullets."
  @@deh_gotclipbox
  @@deh_goththbonus = "Picked up a health bonus."
  @@deh_goththbonus
  @@deh_gotinvis = "Partial Invisibility"
  @@deh_gotinvis
  @@deh_gotinvul = "Invulnerability!"
  @@deh_gotinvul
  @@deh_gotlauncher = "You got the rocket launcher!"
  @@deh_gotlauncher
  @@deh_gotmap = "Computer Area Map"
  @@deh_gotmap
  @@deh_gotmedikit = "Picked up a medikit."
  @@deh_gotmedikit
  @@deh_gotmedineed = "Picked up a medikit that you REALLY need!"
  @@deh_gotmedineed
  @@deh_gotmega = "Picked up the MegaArmor!"
  @@deh_gotmega
  @@deh_gotmsphere = "MegaSphere!"
  @@deh_gotmsphere
  @@deh_gotplasma = "You got the plasma gun!"
  @@deh_gotplasma
  @@deh_gotredcard = "Picked up a red keycard."
  @@deh_gotredcard
  @@deh_gotredskull = "Picked up a red skull key."
  @@deh_gotredskull
  @@deh_gotrockbox = "Picked up a box of rockets."
  @@deh_gotrockbox
  @@deh_gotrocket = "Picked up a rocket."
  @@deh_gotrocket
  @@deh_gotshellbox = "Picked up a box of shotgun shells."
  @@deh_gotshellbox
  @@deh_gotshells = "Picked up 4 shotgun shells."
  @@deh_gotshells
  @@deh_gotshotgun = "You got the shotgun!"
  @@deh_gotshotgun
  @@deh_gotshotgun2 = "You got the super shotgun!"
  @@deh_gotshotgun2
  @@deh_gotstim = "Picked up a stimpack."
  @@deh_gotstim
  @@deh_gotsuit = "Radiation Shielding Suit"
  @@deh_gotsuit
  @@deh_gotsuper = "Supercharge!"
  @@deh_gotsuper
  @@deh_gotvisor = "Light Amplification Visor"
  @@deh_gotvisor
  @@deh_gotyelwcard = "Picked up a yellow keycard."
  @@deh_gotyelwcard
  @@deh_gotyelwskul = "Picked up a yellow skull key."
  @@deh_gotyelwskul
  @@deh_hustr_1 = "level 1: entryway"
  @@deh_hustr_1
  @@deh_hustr_10 = "level 10: refueling base"
  @@deh_hustr_10
  @@deh_hustr_11 = "level 11: 'o' of destruction!"
  @@deh_hustr_11
  @@deh_hustr_12 = "level 12: the factory"
  @@deh_hustr_12
  @@deh_hustr_13 = "level 13: downtown"
  @@deh_hustr_13
  @@deh_hustr_14 = "level 14: the inmost dens"
  @@deh_hustr_14
  @@deh_hustr_15 = "level 15: industrial zone"
  @@deh_hustr_15
  @@deh_hustr_16 = "level 16: suburbs"
  @@deh_hustr_16
  @@deh_hustr_17 = "level 17: tenements"
  @@deh_hustr_17
  @@deh_hustr_18 = "level 18: the courtyard"
  @@deh_hustr_18
  @@deh_hustr_19 = "level 19: the citadel"
  @@deh_hustr_19
  @@deh_hustr_2 = "level 2: underhalls"
  @@deh_hustr_2
  @@deh_hustr_20 = "level 20: gotcha!"
  @@deh_hustr_20
  @@deh_hustr_21 = "level 21: nirvana"
  @@deh_hustr_21
  @@deh_hustr_22 = "level 22: the catacombs"
  @@deh_hustr_22
  @@deh_hustr_23 = "level 23: barrels o' fun"
  @@deh_hustr_23
  @@deh_hustr_24 = "level 24: the chasm"
  @@deh_hustr_24
  @@deh_hustr_25 = "level 25: bloodfalls"
  @@deh_hustr_25
  @@deh_hustr_26 = "level 26: the abandoned mines"
  @@deh_hustr_26
  @@deh_hustr_27 = "level 27: monster condo"
  @@deh_hustr_27
  @@deh_hustr_28 = "level 28: the spirit world"
  @@deh_hustr_28
  @@deh_hustr_29 = "level 29: the living end"
  @@deh_hustr_29
  @@deh_hustr_3 = "level 3: the gantlet"
  @@deh_hustr_3
  @@deh_hustr_30 = "level 30: icon of sin"
  @@deh_hustr_30
  @@deh_hustr_31 = "level 31: wolfenstein"
  @@deh_hustr_31
  @@deh_hustr_32 = "level 32: grosse"
  @@deh_hustr_32
  @@deh_hustr_4 = "level 4: the focus"
  @@deh_hustr_4
  @@deh_hustr_5 = "level 5: the waste tunnels"
  @@deh_hustr_5
  @@deh_hustr_6 = "level 6: the crusher"
  @@deh_hustr_6
  @@deh_hustr_7 = "level 7: dead simple"
  @@deh_hustr_7
  @@deh_hustr_8 = "level 8: tricks and traps"
  @@deh_hustr_8
  @@deh_hustr_9 = "level 9: the pit"
  @@deh_hustr_9
  @@deh_hustr_chatmacro0 = "No"
  @@deh_hustr_chatmacro0
  @@deh_hustr_chatmacro1 = "I'm ready to kick butt!"
  @@deh_hustr_chatmacro1
  @@deh_hustr_chatmacro2 = "I'm OK."
  @@deh_hustr_chatmacro2
  @@deh_hustr_chatmacro3 = "I'm not looking too good!"
  @@deh_hustr_chatmacro3
  @@deh_hustr_chatmacro4 = "Help!"
  @@deh_hustr_chatmacro4
  @@deh_hustr_chatmacro5 = "You suck!"
  @@deh_hustr_chatmacro5
  @@deh_hustr_chatmacro6 = "Next time, scumbag..."
  @@deh_hustr_chatmacro6
  @@deh_hustr_chatmacro7 = "Come here!"
  @@deh_hustr_chatmacro7
  @@deh_hustr_chatmacro8 = "I'll take care of it."
  @@deh_hustr_chatmacro8
  @@deh_hustr_chatmacro9 = "Yes"
  @@deh_hustr_chatmacro9
  @@deh_hustr_e1m1 = "E1M1: Hangar"
  @@deh_hustr_e1m1
  @@deh_hustr_e1m2 = "E1M2: Nuclear Plant"
  @@deh_hustr_e1m2
  @@deh_hustr_e1m3 = "E1M3: Toxin Refinery"
  @@deh_hustr_e1m3
  @@deh_hustr_e1m4 = "E1M4: Command Control"
  @@deh_hustr_e1m4
  @@deh_hustr_e1m5 = "E1M5: Phobos Lab"
  @@deh_hustr_e1m5
  @@deh_hustr_e1m6 = "E1M6: Central Processing"
  @@deh_hustr_e1m6
  @@deh_hustr_e1m7 = "E1M7: Computer Station"
  @@deh_hustr_e1m7
  @@deh_hustr_e1m8 = "E1M8: Phobos Anomaly"
  @@deh_hustr_e1m8
  @@deh_hustr_e1m9 = "E1M9: Military Base"
  @@deh_hustr_e1m9
  @@deh_hustr_e2m1 = "E2M1: Deimos Anomaly"
  @@deh_hustr_e2m1
  @@deh_hustr_e2m2 = "E2M2: Containment Area"
  @@deh_hustr_e2m2
  @@deh_hustr_e2m3 = "E2M3: Refinery"
  @@deh_hustr_e2m3
  @@deh_hustr_e2m4 = "E2M4: Deimos Lab"
  @@deh_hustr_e2m4
  @@deh_hustr_e2m5 = "E2M5: Command Center"
  @@deh_hustr_e2m5
  @@deh_hustr_e2m6 = "E2M6: Halls of the Damned"
  @@deh_hustr_e2m6
  @@deh_hustr_e2m7 = "E2M7: Spawning Vats"
  @@deh_hustr_e2m7
  @@deh_hustr_e2m8 = "E2M8: Tower of Babel"
  @@deh_hustr_e2m8
  @@deh_hustr_e2m9 = "E2M9: Fortress of Mystery"
  @@deh_hustr_e2m9
  @@deh_hustr_e3m1 = "E3M1: Hell Keep"
  @@deh_hustr_e3m1
  @@deh_hustr_e3m2 = "E3M2: Slough of Despair"
  @@deh_hustr_e3m2
  @@deh_hustr_e3m3 = "E3M3: Pandemonium"
  @@deh_hustr_e3m3
  @@deh_hustr_e3m4 = "E3M4: House of Pain"
  @@deh_hustr_e3m4
  @@deh_hustr_e3m5 = "E3M5: Unholy Cathedral"
  @@deh_hustr_e3m5
  @@deh_hustr_e3m6 = "E3M6: Mt. Erebus"
  @@deh_hustr_e3m6
  @@deh_hustr_e3m7 = "E3M7: Limbo"
  @@deh_hustr_e3m7
  @@deh_hustr_e3m8 = "E3M8: Dis"
  @@deh_hustr_e3m8
  @@deh_hustr_e3m9 = "E3M9: Warrens"
  @@deh_hustr_e3m9
  @@deh_hustr_e4m1 = "E4M1: Hell Beneath"
  @@deh_hustr_e4m1
  @@deh_hustr_e4m2 = "E4M2: Perfect Hatred"
  @@deh_hustr_e4m2
  @@deh_hustr_e4m3 = "E4M3: Sever The Wicked"
  @@deh_hustr_e4m3
  @@deh_hustr_e4m4 = "E4M4: Unruly Evil"
  @@deh_hustr_e4m4
  @@deh_hustr_e4m5 = "E4M5: They Will Repent"
  @@deh_hustr_e4m5
  @@deh_hustr_e4m6 = "E4M6: Against Thee Wickedly"
  @@deh_hustr_e4m6
  @@deh_hustr_e4m7 = "E4M7: And Hell Followed"
  @@deh_hustr_e4m7
  @@deh_hustr_e4m8 = "E4M8: Unto The Cruel"
  @@deh_hustr_e4m8
  @@deh_hustr_e4m9 = "E4M9: Fear"
  @@deh_hustr_e4m9
  @@deh_hustr_messagesent = "[Message Sent]"
  @@deh_hustr_messagesent
  @@deh_hustr_msgu = "[Message unsent]"
  @@deh_hustr_msgu
  @@deh_hustr_plrbrown = "Brown: "
  @@deh_hustr_plrbrown
  @@deh_hustr_plrgreen = "Green: "
  @@deh_hustr_plrgreen
  @@deh_hustr_plrindigo = "Indigo: "
  @@deh_hustr_plrindigo
  @@deh_hustr_plrred = "Red: "
  @@deh_hustr_plrred
  @@deh_hustr_talktoself1 = "You mumble to yourself"
  @@deh_hustr_talktoself1
  @@deh_hustr_talktoself2 = "Who's there?"
  @@deh_hustr_talktoself2
  @@deh_hustr_talktoself3 = "You scare yourself"
  @@deh_hustr_talktoself3
  @@deh_hustr_talktoself4 = "You start to rave"
  @@deh_hustr_talktoself4
  @@deh_hustr_talktoself5 = "You've lost it..."
  @@deh_hustr_talktoself5
  @@deh_msgoff = "Messages OFF"
  @@deh_msgoff
  @@deh_msgon = "Messages ON"
  @@deh_msgon
  @@deh_netend = "you can't end a netgame!\n\n" + PRESSKEY
  @@deh_netend
  @@deh_p1text = "You gloat over the steaming carcass of the\n" +
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
                 "Oh yes, keep living, too."
  @@deh_p1text
  @@deh_p2text = "Even the deadly Arch-Vile labyrinth could\n" +
                 "not stop you, and you've gotten to the\n" +
                 "prototype Accelerator which is soon\n" +
                 "efficiently and permanently deactivated.\n" +
                 "\n" +
                 "You're good at that kind of thing."
  @@deh_p2text
  @@deh_p3text = "You've bashed and battered your way into\n" +
                 "the heart of the devil-hive.  Time for a\n" +
                 "Search-and-Destroy mission, aimed at the\n" +
                 "Gatekeeper, whose foul offspring is\n" +
                 "cascading to Earth.  Yeah, he's bad. But\n" +
                 "you know who's worse!\n" +
                 "\n" +
                 "Grinning evilly, you check your gear, and\n" +
                 "get ready to give the bastard a little Hell\n" +
                 "of your own making!"
  @@deh_p3text
  @@deh_p4text = "The Gatekeeper's evil face is splattered\n" +
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
                 "final cleaning-up ..."
  @@deh_p4text
  @@deh_p5text = "You've found the second-hardest level we\n" +
                 "got. Hope you have a saved game a level or\n" +
                 "two previous.  If not, be prepared to die\n" +
                 "aplenty. For master marines only."
  @@deh_p5text
  @@deh_p6text = "Betcha wondered just what WAS the hardest\n" +
                 "level we had ready for ya?  Now you know.\n" +
                 "No one gets out alive."
  @@deh_p6text
  @@deh_pd_bluek = "You need a blue key to open this door"
  @@deh_pd_bluek
  @@deh_pd_blueo = "You need a blue key to activate this object"
  @@deh_pd_blueo
  @@deh_pd_redk = "You need a red key to open this door"
  @@deh_pd_redk
  @@deh_pd_redo = "You need a red key to activate this object"
  @@deh_pd_redo
  @@deh_pd_yellowk = "You need a yellow key to open this door"
  @@deh_pd_yellowk
  @@deh_pd_yellowo = "You need a yellow key to activate this object"
  @@deh_pd_yellowo
  @@deh_phustr_1 = "level 1: congo"
  @@deh_phustr_1
  @@deh_phustr_10 = "level 10: onslaught"
  @@deh_phustr_10
  @@deh_phustr_11 = "level 11: hunted"
  @@deh_phustr_11
  @@deh_phustr_12 = "level 12: speed"
  @@deh_phustr_12
  @@deh_phustr_13 = "level 13: the crypt"
  @@deh_phustr_13
  @@deh_phustr_14 = "level 14: genesis"
  @@deh_phustr_14
  @@deh_phustr_15 = "level 15: the twilight"
  @@deh_phustr_15
  @@deh_phustr_16 = "level 16: the omen"
  @@deh_phustr_16
  @@deh_phustr_17 = "level 17: compound"
  @@deh_phustr_17
  @@deh_phustr_18 = "level 18: neurosphere"
  @@deh_phustr_18
  @@deh_phustr_19 = "level 19: nme"
  @@deh_phustr_19
  @@deh_phustr_2 = "level 2: well of souls"
  @@deh_phustr_2
  @@deh_phustr_20 = "level 20: the death domain"
  @@deh_phustr_20
  @@deh_phustr_21 = "level 21: slayer"
  @@deh_phustr_21
  @@deh_phustr_22 = "level 22: impossible mission"
  @@deh_phustr_22
  @@deh_phustr_23 = "level 23: tombstone"
  @@deh_phustr_23
  @@deh_phustr_24 = "level 24: the final frontier"
  @@deh_phustr_24
  @@deh_phustr_25 = "level 25: the temple of darkness"
  @@deh_phustr_25
  @@deh_phustr_26 = "level 26: bunker"
  @@deh_phustr_26
  @@deh_phustr_27 = "level 27: anti-christ"
  @@deh_phustr_27
  @@deh_phustr_28 = "level 28: the sewers"
  @@deh_phustr_28
  @@deh_phustr_29 = "level 29: odyssey of noises"
  @@deh_phustr_29
  @@deh_phustr_3 = "level 3: aztec"
  @@deh_phustr_3
  @@deh_phustr_30 = "level 30: the gateway of hell"
  @@deh_phustr_30
  @@deh_phustr_31 = "level 31: cyberden"
  @@deh_phustr_31
  @@deh_phustr_32 = "level 32: go 2 it"
  @@deh_phustr_32
  @@deh_phustr_4 = "level 4: caged"
  @@deh_phustr_4
  @@deh_phustr_5 = "level 5: ghost town"
  @@deh_phustr_5
  @@deh_phustr_6 = "level 6: baron's lair"
  @@deh_phustr_6
  @@deh_phustr_7 = "level 7: caughtyard"
  @@deh_phustr_7
  @@deh_phustr_8 = "level 8: realm"
  @@deh_phustr_8
  @@deh_phustr_9 = "level 9: abattoire"
  @@deh_phustr_9
  @@deh_savegamename = "doomsav"
  @@deh_savegamename
  @@deh_ststr_behold = "inVuln, Str, Inviso, Rad, Allmap, or Lite-amp"
  @@deh_ststr_behold
  @@deh_ststr_beholdx = "Power-up Toggled"
  @@deh_ststr_beholdx
  @@deh_ststr_choppers = "... doesn't suck - GM"
  @@deh_ststr_choppers
  @@deh_ststr_clev = "Changing Level..."
  @@deh_ststr_clev
  @@deh_ststr_dqdoff = "Degreelessness Mode Off"
  @@deh_ststr_dqdoff
  @@deh_ststr_dqdon = "Degreelessness Mode On"
  @@deh_ststr_dqdon
  @@deh_ststr_faadded = "Ammo (no keys) Added"
  @@deh_ststr_faadded
  @@deh_ststr_kfaadded = "Very Happy Ammo Added"
  @@deh_ststr_kfaadded
  @@deh_ststr_mus = "Music Change"
  @@deh_ststr_mus
  @@deh_ststr_ncoff = "No Clipping Mode OFF"
  @@deh_ststr_ncoff
  @@deh_ststr_ncon = "No Clipping Mode ON"
  @@deh_ststr_ncon
  @@deh_ststr_nomus = "IMPOSSIBLE SELECTION"
  @@deh_ststr_nomus
  @@deh_t1text = "You've fought your way out of the infested\n" +
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
                 "laying around."
  @@deh_t1text
  @@deh_t2text = "You hear the grinding of heavy machinery\n" +
                 "ahead.  You sure hope they're not stamping\n" +
                 "out new hellspawn, but you're ready to\n" +
                 "ream out a whole herd if you have to.\n" +
                 "They might be planning a blood feast, but\n" +
                 "you feel about as mean as two thousand\n" +
                 "maniacs packed into one mad killer.\n" +
                 "\n" +
                 "You don't plan to go down easy."
  @@deh_t2text
  @@deh_t3text = "The vista opening ahead looks real damn\n" +
                 "familiar. Smells familiar, too -- like\n" +
                 "fried excrement. You didn't like this\n" +
                 "place before, and you sure as hell ain't\n" +
                 "planning to like it now. The more you\n" +
                 "brood on it, the madder you get.\n" +
                 "Hefting your gun, an evil grin trickles\n" +
                 "onto your face. Time to take some names."
  @@deh_t3text
  @@deh_t4text = "Suddenly, all is silent, from one horizon\n" +
                 "to the other. The agonizing echo of Hell\n" +
                 "fades away, the nightmare sky turns to\n" +
                 "blue, the heaps of monster corpses start \n" +
                 "to evaporate along with the evil stench \n" +
                 "that filled the air. Jeeze, maybe you've\n" +
                 "done it. Have you really won?\n" +
                 "\n" +
                 "Something rumbles in the distance.\n" +
                 "A blue light begins to glow inside the\n" +
                 "ruined skull of the demon-spitter."
  @@deh_t4text
  @@deh_t5text = "What now? Looks totally different. Kind\n" +
                 "of like King Tut's condo. Well,\n" +
                 "whatever's here can't be any worse\n" +
                 "than usual. Can it?  Or maybe it's best\n" +
                 "to let sleeping gods lie.."
  @@deh_t5text
  @@deh_t6text = "Time for a vacation. You've burst the\n" +
                 "bowels of hell and by golly you're ready\n" +
                 "for a break. You mutter to yourself,\n" +
                 "Maybe someone else can kick Hell's ass\n" +
                 "next time around. Ahead lies a quiet town,\n" +
                 "with peaceful flowing water, quaint\n" +
                 "buildings, and presumably no Hellspawn.\n" +
                 "\n" +
                 "As you step off the transport, you hear\n" +
                 "the stomp of a cyberdemon's iron shoe."
  @@deh_t6text
  @@deh_thustr_1 = "level 1: system control"
  @@deh_thustr_1
  @@deh_thustr_10 = "level 10: redemption"
  @@deh_thustr_10
  @@deh_thustr_11 = "level 11: storage facility"
  @@deh_thustr_11
  @@deh_thustr_12 = "level 12: crater"
  @@deh_thustr_12
  @@deh_thustr_13 = "level 13: nukage processing"
  @@deh_thustr_13
  @@deh_thustr_14 = "level 14: steel works"
  @@deh_thustr_14
  @@deh_thustr_15 = "level 15: dead zone"
  @@deh_thustr_15
  @@deh_thustr_16 = "level 16: deepest reaches"
  @@deh_thustr_16
  @@deh_thustr_17 = "level 17: processing area"
  @@deh_thustr_17
  @@deh_thustr_18 = "level 18: mill"
  @@deh_thustr_18
  @@deh_thustr_19 = "level 19: shipping/respawning"
  @@deh_thustr_19
  @@deh_thustr_2 = "level 2: human bbq"
  @@deh_thustr_2
  @@deh_thustr_20 = "level 20: central processing"
  @@deh_thustr_20
  @@deh_thustr_21 = "level 21: administration center"
  @@deh_thustr_21
  @@deh_thustr_22 = "level 22: habitat"
  @@deh_thustr_22
  @@deh_thustr_23 = "level 23: lunar mining project"
  @@deh_thustr_23
  @@deh_thustr_24 = "level 24: quarry"
  @@deh_thustr_24
  @@deh_thustr_25 = "level 25: baron's den"
  @@deh_thustr_25
  @@deh_thustr_26 = "level 26: ballistyx"
  @@deh_thustr_26
  @@deh_thustr_27 = "level 27: mount pain"
  @@deh_thustr_27
  @@deh_thustr_28 = "level 28: heck"
  @@deh_thustr_28
  @@deh_thustr_29 = "level 29: river styx"
  @@deh_thustr_29
  @@deh_thustr_3 = "level 3: power control"
  @@deh_thustr_3
  @@deh_thustr_30 = "level 30: last call"
  @@deh_thustr_30
  @@deh_thustr_31 = "level 31: pharaoh"
  @@deh_thustr_31
  @@deh_thustr_32 = "level 32: caribbean"
  @@deh_thustr_32
  @@deh_thustr_4 = "level 4: wormhole"
  @@deh_thustr_4
  @@deh_thustr_5 = "level 5: hanger"
  @@deh_thustr_5
  @@deh_thustr_6 = "level 6: open season"
  @@deh_thustr_6
  @@deh_thustr_7 = "level 7: prison"
  @@deh_thustr_7
  @@deh_thustr_8 = "level 8: metal"
  @@deh_thustr_8
  @@deh_thustr_9 = "level 9: stronghold"
  @@deh_thustr_9

  # The C Constant string name mapped to it's variables
  # For cases interp, use to variables and split on '%s'
  DEH_STRINGS = {
    "D_DEVSTR"           => [pointerof(@@deh_d_devstr)],
    "QUITMSG"            => [pointerof(@@deh_quit_msg)],
    "LOADNET"            => [pointerof(@@deh_load_net)],
    "QLOADNET"           => [pointerof(@@deh_qload_net)],
    "QSAVESPOT"          => [pointerof(@@deh_qsave_spot)],
    "SAVEDEAD"           => [pointerof(@@deh_save_dead)],
    "QSPROMPT"           => [pointerof(@@deh_qsprompt_1), pointerof(@@deh_qsprompt_2)],
    "QLPROMPT"           => [pointerof(@@deh_qlprompt_1), pointerof(@@deh_qlprompt_2)],
    "NEWGAME"            => [pointerof(@@deh_newgame)],
    "NIGHTMARE"          => [pointerof(@@deh_nightmare)],
    "SWSTRING"           => [pointerof(@@deh_swstring)],
    "AMSTR_FOLLOWOFF"    => [pointerof(@@deh_amstr_followoff)],
    "AMSTR_FOLLOWON"     => [pointerof(@@deh_amstr_followon)],
    "AMSTR_GRIDOFF"      => [pointerof(@@deh_amstr_gridoff)],
    "AMSTR_GRIDON"       => [pointerof(@@deh_amstr_gridon)],
    "AMSTR_MARKEDSPOT"   => [pointerof(@@deh_amstr_markedspot)],
    "AMSTR_MARKSCLEARED" => [pointerof(@@deh_amstr_markscleared)],
    "C1TEXT"             => [pointerof(@@deh_c1text)],
    "C2TEXT"             => [pointerof(@@deh_c2text)],
    "C3TEXT"             => [pointerof(@@deh_c3text)],
    "C4TEXT"             => [pointerof(@@deh_c4text)],
    "C5TEXT"             => [pointerof(@@deh_c5text)],
    "C6TEXT"             => [pointerof(@@deh_c6text)],
    "CC_ARACH"           => [pointerof(@@deh_cc_arach)],
    "CC_ARCH"            => [pointerof(@@deh_cc_arch)],
    "CC_BARON"           => [pointerof(@@deh_cc_baron)],
    "CC_CACO"            => [pointerof(@@deh_cc_caco)],
    "CC_CYBER"           => [pointerof(@@deh_cc_cyber)],
    "CC_DEMON"           => [pointerof(@@deh_cc_demon)],
    "CC_HEAVY"           => [pointerof(@@deh_cc_heavy)],
    "CC_HELL"            => [pointerof(@@deh_cc_hell)],
    "CC_HERO"            => [pointerof(@@deh_cc_hero)],
    "CC_IMP"             => [pointerof(@@deh_cc_imp)],
    "CC_LOST"            => [pointerof(@@deh_cc_lost)],
    "CC_MANCU"           => [pointerof(@@deh_cc_mancu)],
    "CC_PAIN"            => [pointerof(@@deh_cc_pain)],
    "CC_REVEN"           => [pointerof(@@deh_cc_reven)],
    "CC_SHOTGUN"         => [pointerof(@@deh_cc_shotgun)],
    "CC_SPIDER"          => [pointerof(@@deh_cc_spider)],
    "CC_ZOMBIE"          => [pointerof(@@deh_cc_zombie)],
    "DETAILHI"           => [pointerof(@@deh_detailhi)],
    "DETAILLO"           => [pointerof(@@deh_detaillo)],
    "E1TEXT"             => [pointerof(@@deh_e1text)],
    "E2TEXT"             => [pointerof(@@deh_e2text)],
    "E3TEXT"             => [pointerof(@@deh_e3text)],
    "E4TEXT"             => [pointerof(@@deh_e4text)],
    "EMPTYSTRING"        => [pointerof(@@deh_emptystring)],
    "ENDGAME"            => [pointerof(@@deh_endgame)],
    "GAMMALVL0"          => [pointerof(@@deh_gammalvl0)],
    "GAMMALVL1"          => [pointerof(@@deh_gammalvl1)],
    "GAMMALVL2"          => [pointerof(@@deh_gammalvl2)],
    "GAMMALVL3"          => [pointerof(@@deh_gammalvl3)],
    "GAMMALVL4"          => [pointerof(@@deh_gammalvl4)],
    "GGSAVED"            => [pointerof(@@deh_ggsaved)],
    "GOTARMBONUS"        => [pointerof(@@deh_gotarmbonus)],
    "GOTARMOR"           => [pointerof(@@deh_gotarmor)],
    "GOTBACKPACK"        => [pointerof(@@deh_gotbackpack)],
    "GOTBERSERK"         => [pointerof(@@deh_gotberserk)],
    "GOTBFG9000"         => [pointerof(@@deh_gotbfg9000)],
    "GOTBLUECARD"        => [pointerof(@@deh_gotbluecard)],
    "GOTBLUESKUL"        => [pointerof(@@deh_gotblueskul)],
    "GOTCELL"            => [pointerof(@@deh_gotcell)],
    "GOTCELLBOX"         => [pointerof(@@deh_gotcellbox)],
    "GOTCHAINGUN"        => [pointerof(@@deh_gotchaingun)],
    "GOTCHAINSAW"        => [pointerof(@@deh_gotchainsaw)],
    "GOTCLIP"            => [pointerof(@@deh_gotclip)],
    "GOTCLIPBOX"         => [pointerof(@@deh_gotclipbox)],
    "GOTHTHBONUS"        => [pointerof(@@deh_goththbonus)],
    "GOTINVIS"           => [pointerof(@@deh_gotinvis)],
    "GOTINVUL"           => [pointerof(@@deh_gotinvul)],
    "GOTLAUNCHER"        => [pointerof(@@deh_gotlauncher)],
    "GOTMAP"             => [pointerof(@@deh_gotmap)],
    "GOTMEDIKIT"         => [pointerof(@@deh_gotmedikit)],
    "GOTMEDINEED"        => [pointerof(@@deh_gotmedineed)],
    "GOTMEGA"            => [pointerof(@@deh_gotmega)],
    "GOTMSPHERE"         => [pointerof(@@deh_gotmsphere)],
    "GOTPLASMA"          => [pointerof(@@deh_gotplasma)],
    "GOTREDCARD"         => [pointerof(@@deh_gotredcard)],
    "GOTREDSKULL"        => [pointerof(@@deh_gotredskull)],
    "GOTROCKBOX"         => [pointerof(@@deh_gotrockbox)],
    "GOTROCKET"          => [pointerof(@@deh_gotrocket)],
    "GOTSHELLBOX"        => [pointerof(@@deh_gotshellbox)],
    "GOTSHELLS"          => [pointerof(@@deh_gotshells)],
    "GOTSHOTGUN"         => [pointerof(@@deh_gotshotgun)],
    "GOTSHOTGUN2"        => [pointerof(@@deh_gotshotgun2)],
    "GOTSTIM"            => [pointerof(@@deh_gotstim)],
    "GOTSUIT"            => [pointerof(@@deh_gotsuit)],
    "GOTSUPER"           => [pointerof(@@deh_gotsuper)],
    "GOTVISOR"           => [pointerof(@@deh_gotvisor)],
    "GOTYELWCARD"        => [pointerof(@@deh_gotyelwcard)],
    "GOTYELWSKUL"        => [pointerof(@@deh_gotyelwskul)],
    "HUSTR_1"            => [pointerof(@@deh_hustr_1)],
    "HUSTR_10"           => [pointerof(@@deh_hustr_10)],
    "HUSTR_11"           => [pointerof(@@deh_hustr_11)],
    "HUSTR_12"           => [pointerof(@@deh_hustr_12)],
    "HUSTR_13"           => [pointerof(@@deh_hustr_13)],
    "HUSTR_14"           => [pointerof(@@deh_hustr_14)],
    "HUSTR_15"           => [pointerof(@@deh_hustr_15)],
    "HUSTR_16"           => [pointerof(@@deh_hustr_16)],
    "HUSTR_17"           => [pointerof(@@deh_hustr_17)],
    "HUSTR_18"           => [pointerof(@@deh_hustr_18)],
    "HUSTR_19"           => [pointerof(@@deh_hustr_19)],
    "HUSTR_2"            => [pointerof(@@deh_hustr_2)],
    "HUSTR_20"           => [pointerof(@@deh_hustr_20)],
    "HUSTR_21"           => [pointerof(@@deh_hustr_21)],
    "HUSTR_22"           => [pointerof(@@deh_hustr_22)],
    "HUSTR_23"           => [pointerof(@@deh_hustr_23)],
    "HUSTR_24"           => [pointerof(@@deh_hustr_24)],
    "HUSTR_25"           => [pointerof(@@deh_hustr_25)],
    "HUSTR_26"           => [pointerof(@@deh_hustr_26)],
    "HUSTR_27"           => [pointerof(@@deh_hustr_27)],
    "HUSTR_28"           => [pointerof(@@deh_hustr_28)],
    "HUSTR_29"           => [pointerof(@@deh_hustr_29)],
    "HUSTR_3"            => [pointerof(@@deh_hustr_3)],
    "HUSTR_30"           => [pointerof(@@deh_hustr_30)],
    "HUSTR_31"           => [pointerof(@@deh_hustr_31)],
    "HUSTR_32"           => [pointerof(@@deh_hustr_32)],
    "HUSTR_4"            => [pointerof(@@deh_hustr_4)],
    "HUSTR_5"            => [pointerof(@@deh_hustr_5)],
    "HUSTR_6"            => [pointerof(@@deh_hustr_6)],
    "HUSTR_7"            => [pointerof(@@deh_hustr_7)],
    "HUSTR_8"            => [pointerof(@@deh_hustr_8)],
    "HUSTR_9"            => [pointerof(@@deh_hustr_9)],
    "HUSTR_CHATMACRO0"   => [pointerof(@@deh_hustr_chatmacro0)],
    "HUSTR_CHATMACRO1"   => [pointerof(@@deh_hustr_chatmacro1)],
    "HUSTR_CHATMACRO2"   => [pointerof(@@deh_hustr_chatmacro2)],
    "HUSTR_CHATMACRO3"   => [pointerof(@@deh_hustr_chatmacro3)],
    "HUSTR_CHATMACRO4"   => [pointerof(@@deh_hustr_chatmacro4)],
    "HUSTR_CHATMACRO5"   => [pointerof(@@deh_hustr_chatmacro5)],
    "HUSTR_CHATMACRO6"   => [pointerof(@@deh_hustr_chatmacro6)],
    "HUSTR_CHATMACRO7"   => [pointerof(@@deh_hustr_chatmacro7)],
    "HUSTR_CHATMACRO8"   => [pointerof(@@deh_hustr_chatmacro8)],
    "HUSTR_CHATMACRO9"   => [pointerof(@@deh_hustr_chatmacro9)],
    "HUSTR_E1M1"         => [pointerof(@@deh_hustr_e1m1)],
    "HUSTR_E1M2"         => [pointerof(@@deh_hustr_e1m2)],
    "HUSTR_E1M3"         => [pointerof(@@deh_hustr_e1m3)],
    "HUSTR_E1M4"         => [pointerof(@@deh_hustr_e1m4)],
    "HUSTR_E1M5"         => [pointerof(@@deh_hustr_e1m5)],
    "HUSTR_E1M6"         => [pointerof(@@deh_hustr_e1m6)],
    "HUSTR_E1M7"         => [pointerof(@@deh_hustr_e1m7)],
    "HUSTR_E1M8"         => [pointerof(@@deh_hustr_e1m8)],
    "HUSTR_E1M9"         => [pointerof(@@deh_hustr_e1m9)],
    "HUSTR_E2M1"         => [pointerof(@@deh_hustr_e2m1)],
    "HUSTR_E2M2"         => [pointerof(@@deh_hustr_e2m2)],
    "HUSTR_E2M3"         => [pointerof(@@deh_hustr_e2m3)],
    "HUSTR_E2M4"         => [pointerof(@@deh_hustr_e2m4)],
    "HUSTR_E2M5"         => [pointerof(@@deh_hustr_e2m5)],
    "HUSTR_E2M6"         => [pointerof(@@deh_hustr_e2m6)],
    "HUSTR_E2M7"         => [pointerof(@@deh_hustr_e2m7)],
    "HUSTR_E2M8"         => [pointerof(@@deh_hustr_e2m8)],
    "HUSTR_E2M9"         => [pointerof(@@deh_hustr_e2m9)],
    "HUSTR_E3M1"         => [pointerof(@@deh_hustr_e3m1)],
    "HUSTR_E3M2"         => [pointerof(@@deh_hustr_e3m2)],
    "HUSTR_E3M3"         => [pointerof(@@deh_hustr_e3m3)],
    "HUSTR_E3M4"         => [pointerof(@@deh_hustr_e3m4)],
    "HUSTR_E3M5"         => [pointerof(@@deh_hustr_e3m5)],
    "HUSTR_E3M6"         => [pointerof(@@deh_hustr_e3m6)],
    "HUSTR_E3M7"         => [pointerof(@@deh_hustr_e3m7)],
    "HUSTR_E3M8"         => [pointerof(@@deh_hustr_e3m8)],
    "HUSTR_E3M9"         => [pointerof(@@deh_hustr_e3m9)],
    "HUSTR_E4M1"         => [pointerof(@@deh_hustr_e4m1)],
    "HUSTR_E4M2"         => [pointerof(@@deh_hustr_e4m2)],
    "HUSTR_E4M3"         => [pointerof(@@deh_hustr_e4m3)],
    "HUSTR_E4M4"         => [pointerof(@@deh_hustr_e4m4)],
    "HUSTR_E4M5"         => [pointerof(@@deh_hustr_e4m5)],
    "HUSTR_E4M6"         => [pointerof(@@deh_hustr_e4m6)],
    "HUSTR_E4M7"         => [pointerof(@@deh_hustr_e4m7)],
    "HUSTR_E4M8"         => [pointerof(@@deh_hustr_e4m8)],
    "HUSTR_E4M9"         => [pointerof(@@deh_hustr_e4m9)],
    "HUSTR_MESSAGESENT"  => [pointerof(@@deh_hustr_messagesent)],
    "HUSTR_MSGU"         => [pointerof(@@deh_hustr_msgu)],
    "HUSTR_PLRBROWN"     => [pointerof(@@deh_hustr_plrbrown)],
    "HUSTR_PLRGREEN"     => [pointerof(@@deh_hustr_plrgreen)],
    "HUSTR_PLRINDIGO"    => [pointerof(@@deh_hustr_plrindigo)],
    "HUSTR_PLRRED"       => [pointerof(@@deh_hustr_plrred)],
    "HUSTR_TALKTOSELF1"  => [pointerof(@@deh_hustr_talktoself1)],
    "HUSTR_TALKTOSELF2"  => [pointerof(@@deh_hustr_talktoself2)],
    "HUSTR_TALKTOSELF3"  => [pointerof(@@deh_hustr_talktoself3)],
    "HUSTR_TALKTOSELF4"  => [pointerof(@@deh_hustr_talktoself4)],
    "HUSTR_TALKTOSELF5"  => [pointerof(@@deh_hustr_talktoself5)],
    "MSGOFF"             => [pointerof(@@deh_msgoff)],
    "MSGON"              => [pointerof(@@deh_msgon)],
    "NETEND"             => [pointerof(@@deh_netend)],
    "P1TEXT"             => [pointerof(@@deh_p1text)],
    "P2TEXT"             => [pointerof(@@deh_p2text)],
    "P3TEXT"             => [pointerof(@@deh_p3text)],
    "P4TEXT"             => [pointerof(@@deh_p4text)],
    "P5TEXT"             => [pointerof(@@deh_p5text)],
    "P6TEXT"             => [pointerof(@@deh_p6text)],
    "PD_BLUEK"           => [pointerof(@@deh_pd_bluek)],
    "PD_BLUEO"           => [pointerof(@@deh_pd_blueo)],
    "PD_REDK"            => [pointerof(@@deh_pd_redk)],
    "PD_REDO"            => [pointerof(@@deh_pd_redo)],
    "PD_YELLOWK"         => [pointerof(@@deh_pd_yellowk)],
    "PD_YELLOWO"         => [pointerof(@@deh_pd_yellowo)],
    "PHUSTR_1"           => [pointerof(@@deh_phustr_1)],
    "PHUSTR_10"          => [pointerof(@@deh_phustr_10)],
    "PHUSTR_11"          => [pointerof(@@deh_phustr_11)],
    "PHUSTR_12"          => [pointerof(@@deh_phustr_12)],
    "PHUSTR_13"          => [pointerof(@@deh_phustr_13)],
    "PHUSTR_14"          => [pointerof(@@deh_phustr_14)],
    "PHUSTR_15"          => [pointerof(@@deh_phustr_15)],
    "PHUSTR_16"          => [pointerof(@@deh_phustr_16)],
    "PHUSTR_17"          => [pointerof(@@deh_phustr_17)],
    "PHUSTR_18"          => [pointerof(@@deh_phustr_18)],
    "PHUSTR_19"          => [pointerof(@@deh_phustr_19)],
    "PHUSTR_2"           => [pointerof(@@deh_phustr_2)],
    "PHUSTR_20"          => [pointerof(@@deh_phustr_20)],
    "PHUSTR_21"          => [pointerof(@@deh_phustr_21)],
    "PHUSTR_22"          => [pointerof(@@deh_phustr_22)],
    "PHUSTR_23"          => [pointerof(@@deh_phustr_23)],
    "PHUSTR_24"          => [pointerof(@@deh_phustr_24)],
    "PHUSTR_25"          => [pointerof(@@deh_phustr_25)],
    "PHUSTR_26"          => [pointerof(@@deh_phustr_26)],
    "PHUSTR_27"          => [pointerof(@@deh_phustr_27)],
    "PHUSTR_28"          => [pointerof(@@deh_phustr_28)],
    "PHUSTR_29"          => [pointerof(@@deh_phustr_29)],
    "PHUSTR_3"           => [pointerof(@@deh_phustr_3)],
    "PHUSTR_30"          => [pointerof(@@deh_phustr_30)],
    "PHUSTR_31"          => [pointerof(@@deh_phustr_31)],
    "PHUSTR_32"          => [pointerof(@@deh_phustr_32)],
    "PHUSTR_4"           => [pointerof(@@deh_phustr_4)],
    "PHUSTR_5"           => [pointerof(@@deh_phustr_5)],
    "PHUSTR_6"           => [pointerof(@@deh_phustr_6)],
    "PHUSTR_7"           => [pointerof(@@deh_phustr_7)],
    "PHUSTR_8"           => [pointerof(@@deh_phustr_8)],
    "PHUSTR_9"           => [pointerof(@@deh_phustr_9)],
    "SAVEGAMENAME"       => [pointerof(@@deh_savegamename)],
    "STSTR_BEHOLD"       => [pointerof(@@deh_ststr_behold)],
    "STSTR_BEHOLDX"      => [pointerof(@@deh_ststr_beholdx)],
    "STSTR_CHOPPERS"     => [pointerof(@@deh_ststr_choppers)],
    "STSTR_CLEV"         => [pointerof(@@deh_ststr_clev)],
    "STSTR_DQDOFF"       => [pointerof(@@deh_ststr_dqdoff)],
    "STSTR_DQDON"        => [pointerof(@@deh_ststr_dqdon)],
    "STSTR_FAADDED"      => [pointerof(@@deh_ststr_faadded)],
    "STSTR_KFAADDED"     => [pointerof(@@deh_ststr_kfaadded)],
    "STSTR_MUS"          => [pointerof(@@deh_ststr_mus)],
    "STSTR_NCOFF"        => [pointerof(@@deh_ststr_ncoff)],
    "STSTR_NCON"         => [pointerof(@@deh_ststr_ncon)],
    "STSTR_NOMUS"        => [pointerof(@@deh_ststr_nomus)],
    "T1TEXT"             => [pointerof(@@deh_t1text)],
    "T2TEXT"             => [pointerof(@@deh_t2text)],
    "T3TEXT"             => [pointerof(@@deh_t3text)],
    "T4TEXT"             => [pointerof(@@deh_t4text)],
    "T5TEXT"             => [pointerof(@@deh_t5text)],
    "T6TEXT"             => [pointerof(@@deh_t6text)],
    "THUSTR_1"           => [pointerof(@@deh_thustr_1)],
    "THUSTR_10"          => [pointerof(@@deh_thustr_10)],
    "THUSTR_11"          => [pointerof(@@deh_thustr_11)],
    "THUSTR_12"          => [pointerof(@@deh_thustr_12)],
    "THUSTR_13"          => [pointerof(@@deh_thustr_13)],
    "THUSTR_14"          => [pointerof(@@deh_thustr_14)],
    "THUSTR_15"          => [pointerof(@@deh_thustr_15)],
    "THUSTR_16"          => [pointerof(@@deh_thustr_16)],
    "THUSTR_17"          => [pointerof(@@deh_thustr_17)],
    "THUSTR_18"          => [pointerof(@@deh_thustr_18)],
    "THUSTR_19"          => [pointerof(@@deh_thustr_19)],
    "THUSTR_2"           => [pointerof(@@deh_thustr_2)],
    "THUSTR_20"          => [pointerof(@@deh_thustr_20)],
    "THUSTR_21"          => [pointerof(@@deh_thustr_21)],
    "THUSTR_22"          => [pointerof(@@deh_thustr_22)],
    "THUSTR_23"          => [pointerof(@@deh_thustr_23)],
    "THUSTR_24"          => [pointerof(@@deh_thustr_24)],
    "THUSTR_25"          => [pointerof(@@deh_thustr_25)],
    "THUSTR_26"          => [pointerof(@@deh_thustr_26)],
    "THUSTR_27"          => [pointerof(@@deh_thustr_27)],
    "THUSTR_28"          => [pointerof(@@deh_thustr_28)],
    "THUSTR_29"          => [pointerof(@@deh_thustr_29)],
    "THUSTR_3"           => [pointerof(@@deh_thustr_3)],
    "THUSTR_30"          => [pointerof(@@deh_thustr_30)],
    "THUSTR_31"          => [pointerof(@@deh_thustr_31)],
    "THUSTR_32"          => [pointerof(@@deh_thustr_32)],
    "THUSTR_4"           => [pointerof(@@deh_thustr_4)],
    "THUSTR_5"           => [pointerof(@@deh_thustr_5)],
    "THUSTR_6"           => [pointerof(@@deh_thustr_6)],
    "THUSTR_7"           => [pointerof(@@deh_thustr_7)],
    "THUSTR_8"           => [pointerof(@@deh_thustr_8)],
    "THUSTR_9"           => [pointerof(@@deh_thustr_9)],
  }

  # A mapping of the BEX code name to the Crystal pointer
  DEH_CODEPTRS = {
    # Player
    "light0"        => (->CDoom.a_light0).pointer,
    "weaponready"   => (->CDoom.a_weapon_ready).pointer,
    "lower"         => (->CDoom.a_lower).pointer,
    "raise"         => (->CDoom.a_raise).pointer,
    "punch"         => (->CDoom.a_punch).pointer,
    "refire"        => (->CDoom.a_refire).pointer,
    "firepistol"    => (->CDoom.a_fire_pistol).pointer,
    "light1"        => (->CDoom.a_light1).pointer,
    "fireshotgun"   => (->CDoom.a_fire_shotgun).pointer,
    "light2"        => (->CDoom.a_light2).pointer,
    "fireshotgun2"  => (->CDoom.a_fire_shotgun2).pointer,
    "checkreload"   => (->CDoom.a_check_reload).pointer,
    "openshotgun2"  => (->CDoom.a_open_shotgun2).pointer,
    "loadshotgun2"  => (->CDoom.a_load_shotgun2).pointer,
    "closeshotgun2" => (->CDoom.a_close_shotgun2).pointer,
    "firecgun"      => (->CDoom.a_fire_cgun).pointer,
    "gunflash"      => (->CDoom.a_gun_flash).pointer,
    "firemissile"   => (->CDoom.a_fire_missile).pointer,
    "saw"           => (->CDoom.a_saw).pointer,
    "fireplasma"    => (->CDoom.a_fire_plasma).pointer,
    "bfgsound"      => (->CDoom.a_bfg_sound).pointer,
    "firebfg"       => (->CDoom.a_fire_bfg).pointer,

    # Monster / thing
    "bfgspray"     => (->CDoom.a_bfg_spray).pointer,
    "explode"      => (->CDoom.a_explode).pointer,
    "pain"         => (->CDoom.a_pain).pointer,
    "playerscream" => (->CDoom.a_player_scream).pointer,
    "fall"         => (->CDoom.a_fall).pointer,
    "xscream"      => (->CDoom.a_xscream).pointer,
    "look"         => (->CDoom.a_look).pointer,
    "chase"        => (->CDoom.a_chase).pointer,
    "facetarget"   => (->CDoom.a_face_target).pointer,
    "posattack"    => (->CDoom.a_pos_attack).pointer,
    "scream"       => (->CDoom.a_scream).pointer,
    "vilechase"    => (->CDoom.a_vile_chase).pointer,
    "vilestart"    => (->CDoom.a_vile_start).pointer,
    "viletarget"   => (->CDoom.a_vile_target).pointer,
    "vileattack"   => (->CDoom.a_vile_attack).pointer,
    "startfire"    => (->CDoom.a_start_fire).pointer,
    "fire"         => (->CDoom.a_fire).pointer,
    "firecrackle"  => (->CDoom.a_fire_crackle).pointer,
    "tracer"       => (->CDoom.a_tracer).pointer,
    "skelwhoosh"   => (->CDoom.a_skel_whoosh).pointer,
    "skelfist"     => (->CDoom.a_skel_fist).pointer,
    "skelmissile"  => (->CDoom.a_skel_missile).pointer,
    "fatraise"     => (->CDoom.a_fat_raise).pointer,
    "fatattack1"   => (->CDoom.a_fat_attack1).pointer,
    "fatattack2"   => (->CDoom.a_fat_attack2).pointer,
    "fatattack3"   => (->CDoom.a_fat_attack3).pointer,
    "bossdeath"    => (->CDoom.a_boss_death).pointer,
    "cposattack"   => (->CDoom.a_cpos_attack).pointer,
    "cposrefire"   => (->CDoom.a_cpos_refire).pointer,
    "troopattack"  => (->CDoom.a_troop_attack).pointer,
    "sargattack"   => (->CDoom.a_sarg_attack).pointer,
    "headattack"   => (->CDoom.a_head_attack).pointer,
    "bruisattack"  => (->CDoom.a_bruis_attack).pointer,
    "skullattack"  => (->CDoom.a_skull_attack).pointer,
    "metal"        => (->CDoom.a_metal).pointer,
    "sposattack"   => (->CDoom.a_spos_attack).pointer,
    "spidrefire"   => (->CDoom.a_spid_refire).pointer,
    "babymetal"    => (->CDoom.a_baby_metal).pointer,
    "bspiattack"   => (->CDoom.a_bspi_attack).pointer,
    "hoof"         => (->CDoom.a_hoof).pointer,
    "cyberattack"  => (->CDoom.a_cyber_attack).pointer,
    "painattack"   => (->CDoom.a_pain_attack).pointer,
    "paindie"      => (->CDoom.a_pain_die).pointer,
    "keendie"      => (->CDoom.a_keen_die).pointer,
    "brainpain"    => (->CDoom.a_brain_pain).pointer,
    "brainscream"  => (->CDoom.a_brain_scream).pointer,
    "braindie"     => (->CDoom.a_brain_die).pointer,
    "brainawake"   => (->CDoom.a_brain_awake).pointer,
    "brainspit"    => (->CDoom.a_brain_spit).pointer,
    "spawnsound"   => (->CDoom.a_spawn_sound).pointer,
    "spawnfly"     => (->CDoom.a_spawn_fly).pointer,
    "brainexplode" => (->CDoom.a_brain_explode).pointer,
  }

  # Read a text section the way dehacked intends
  def self.deh_read_text(io : IO, size : Int32) : String
    result = Bytes.new(size)
    count = 0

    while count < size
      c = io.read_byte.not_nil!

      unless c == '\r'
        result[count] = c
        count += 1
      end
    end

    String.new(result[0, count])
  end

  # Parses a text block
  # Although not a BEX extension, it uses DEH_STRINGS so I put it in here
  def self.deh_parse_text(line : String, io : IO)
    sizes = line["Text".size..].split(' ', remove_empty: true).map(&.to_i)

    # Split for interp
    old = deh_read_text(io, sizes[0]).split("'%s'", 2)
    new = deh_read_text(io, sizes[1]).split("'%s'", 2)

    DEH_STRINGS.each_value do |p|
      old.each_with_index do |o, i|
        if p[i]? && o == p[i].value
          if new[i]?
            p[i].value = new[i]
          else
            p[i].value = "\0"
          end
        end
      end
    end

    @@sprnames.each_with_index do |n, i|
      if n == old[0]
        if new[0]?
          @@sprnames[i] = new[0]
        else
          @@sprnames[i] = ""
        end
      end
    end
  end

  # Parse a string block
  def self.deh_parse_string(line : String, io : IO)
    return unless eq = line.index('=')

    key = line[0...eq].strip.upcase
    value = line[(eq + 1)..].lstrip

    # Get multilines
    while value[-1]? == '\\'
      break unless new_line = io.gets
      value = value.rchop + new_line.lstrip
    end

    return unless str_data = DEH_STRINGS[key]?

    # Split for interp and set if found in DEH_STRINGS
    value.split("'%s'", 2).each_with_index do |s, i|
      break if i >= str_data.size
      str_data[i].value = s
    end
  end

  # Parses a par block
  def self.deh_parse_par(line : String)
    line = line.downcase
    if line.starts_with?("par")
      strs = line["par".size..].split(' ', remove_empty: true)
      pars = strs.map &.to_i(strict: false)

      return if pars.size < 2

      if pars.size == 2
        # Map
        Doocr.cpars[pars[0]] = pars[1]
      else
        # Episode, Mission
        Doocr.pars[pars[0]][pars[1]] = pars[2]
      end
    end
  end

  # Parses a codeptr block
  def self.deh_parse_codeptr(line : String)
    line = line.downcase
    return unless line.starts_with?("frame")

    parts = line["frame".size..].delete(' ').split('=')
    return if parts.size < 2

    frame = parts[0].to_i?(strict: false)
    return unless frame # reject unparsable frame numbers instead of defaulting to 0

    return if frame < 0

    while frame >= @@states.size
      i = @@states.size
      @@states << CDoom::State.new(sprite: Doocr::Spritenum::SPR_TNT, tics: -1, nextstate: Doocr::Statenum.new(i))
    end

    name = parts[1]

    # Allow null pointer name
    if name == "null"
      (@@states.to_unsafe + frame).value.action = Pointer(Void).null
      return
    end

    # a_ chop for compatibility with names
    return unless ptr = DEH_CODEPTRS[name.lchop("a_")]? # unknown pointer

    (@@states.to_unsafe + frame).value.action = ptr
  end
end
