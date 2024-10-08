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
    class_getter states : Array(MobjStateDef) = [
      MobjStateDef.new(0, Sprite::TROO, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                  # State.Nil
      MobjStateDef.new(1, Sprite::SHTG, 4, 0, ->PlayerActions.light0(World, Player, PlayerSpriteDef), nil, MobjState::Nil, 0, 0),                # State.Lightdone
      MobjStateDef.new(2, Sprite::PUNG, 0, 1, ->PlayerActions.weaponready(World, Player, PlayerSpriteDef), nil, MobjState::Punch, 0, 0),         # State.punch
      MobjStateDef.new(3, Sprite::PUNG, 0, 1, ->PlayerActions.lower(World, Player, PlayerSpriteDef), nil, MobjState::Punchdown, 0, 0),           # State.punchdown
      MobjStateDef.new(4, Sprite::PUNG, 0, 1, ->PlayerActions.raise(World, Player, PlayerSpriteDef), nil, MobjState::Punchup, 0, 0),             # State.punchup
      MobjStateDef.new(5, Sprite::PUNG, 1, 4, nil, nil, MobjState::Punch2, 0, 0),                                                                # State.punch1
      MobjStateDef.new(6, Sprite::PUNG, 2, 4, ->PlayerActions.punch(World, Player, PlayerSpriteDef), nil, MobjState::Punch3, 0, 0),              # State.punch2
      MobjStateDef.new(7, Sprite::PUNG, 3, 5, nil, nil, MobjState::Punch4, 0, 0),                                                                # State.punch3
      MobjStateDef.new(8, Sprite::PUNG, 2, 4, nil, nil, MobjState::Punch5, 0, 0),                                                                # State.punch4
      MobjStateDef.new(9, Sprite::PUNG, 1, 5, ->PlayerActions.refire(World, Player, PlayerSpriteDef), nil, MobjState::Punch, 0, 0),              # State.punch5
      MobjStateDef.new(10, Sprite::PISG, 0, 1, ->PlayerActions.weaponready(World, Player, PlayerSpriteDef), nil, MobjState::Pistol, 0, 0),       # State.Pistol
      MobjStateDef.new(11, Sprite::PISG, 0, 1, ->PlayerActions.lower(World, Player, PlayerSpriteDef), nil, MobjState::Pistoldown, 0, 0),         # State.Pistoldown
      MobjStateDef.new(12, Sprite::PISG, 0, 1, ->PlayerActions.raise(World, Player, PlayerSpriteDef), nil, MobjState::Pistolup, 0, 0),           # State.Pistolup
      MobjStateDef.new(13, Sprite::PISG, 0, 4, nil, nil, MobjState::Pistol2, 0, 0),                                                              # State.Pistol1
      MobjStateDef.new(14, Sprite::PISG, 1, 6, ->PlayerActions.firepistol(World, Player, PlayerSpriteDef), nil, MobjState::Pistol3, 0, 0),       # State.Pistol2
      MobjStateDef.new(15, Sprite::PISG, 2, 4, nil, nil, MobjState::Pistol4, 0, 0),                                                              # State.Pistol3
      MobjStateDef.new(16, Sprite::PISG, 1, 5, ->PlayerActions.refire(World, Player, PlayerSpriteDef), nil, MobjState::Pistol, 0, 0),            # State.Pistol4
      MobjStateDef.new(17, Sprite::PISF, 32768, 7, ->PlayerActions.light1(World, Player, PlayerSpriteDef), nil, MobjState::Lightdone, 0, 0),     # State.Pistolflash
      MobjStateDef.new(18, Sprite::SHTG, 0, 1, ->PlayerActions.weaponready(World, Player, PlayerSpriteDef), nil, MobjState::Sgun, 0, 0),         # State.Sgun
      MobjStateDef.new(19, Sprite::SHTG, 0, 1, ->PlayerActions.lower(World, Player, PlayerSpriteDef), nil, MobjState::Sgundown, 0, 0),           # State.Sgundown
      MobjStateDef.new(20, Sprite::SHTG, 0, 1, ->PlayerActions.raise(World, Player, PlayerSpriteDef), nil, MobjState::Sgunup, 0, 0),             # State.Sgunup
      MobjStateDef.new(21, Sprite::SHTG, 0, 3, nil, nil, MobjState::Sgun2, 0, 0),                                                                # State.Sgun1
      MobjStateDef.new(22, Sprite::SHTG, 0, 7, ->PlayerActions.fireshotgun(World, Player, PlayerSpriteDef), nil, MobjState::Sgun3, 0, 0),        # State.Sgun2
      MobjStateDef.new(23, Sprite::SHTG, 1, 5, nil, nil, MobjState::Sgun4, 0, 0),                                                                # State.Sgun3
      MobjStateDef.new(24, Sprite::SHTG, 2, 5, nil, nil, MobjState::Sgun5, 0, 0),                                                                # State.Sgun4
      MobjStateDef.new(25, Sprite::SHTG, 3, 4, nil, nil, MobjState::Sgun6, 0, 0),                                                                # State.Sgun5
      MobjStateDef.new(26, Sprite::SHTG, 2, 5, nil, nil, MobjState::Sgun7, 0, 0),                                                                # State.Sgun6
      MobjStateDef.new(27, Sprite::SHTG, 1, 5, nil, nil, MobjState::Sgun8, 0, 0),                                                                # State.Sgun7
      MobjStateDef.new(28, Sprite::SHTG, 0, 3, nil, nil, MobjState::Sgun9, 0, 0),                                                                # State.Sgun8
      MobjStateDef.new(29, Sprite::SHTG, 0, 7, ->PlayerActions.refire(World, Player, PlayerSpriteDef), nil, MobjState::Sgun, 0, 0),              # State.Sgun9
      MobjStateDef.new(30, Sprite::SHTF, 32768, 4, ->PlayerActions.light1(World, Player, PlayerSpriteDef), nil, MobjState::Sgunflash2, 0, 0),    # State.Sgunflash1
      MobjStateDef.new(31, Sprite::SHTF, 32769, 3, ->PlayerActions.light2(World, Player, PlayerSpriteDef), nil, MobjState::Lightdone, 0, 0),     # State.Sgunflash2
      MobjStateDef.new(32, Sprite::SHT2, 0, 1, ->PlayerActions.weaponready(World, Player, PlayerSpriteDef), nil, MobjState::Dsgun, 0, 0),        # State.Dsgun
      MobjStateDef.new(33, Sprite::SHT2, 0, 1, ->PlayerActions.lower(World, Player, PlayerSpriteDef), nil, MobjState::Dsgundown, 0, 0),          # State.Dsgundown
      MobjStateDef.new(34, Sprite::SHT2, 0, 1, ->PlayerActions.raise(World, Player, PlayerSpriteDef), nil, MobjState::Dsgunup, 0, 0),            # State.Dsgunup
      MobjStateDef.new(35, Sprite::SHT2, 0, 3, nil, nil, MobjState::Dsgun2, 0, 0),                                                               # State.Dsgun1
      MobjStateDef.new(36, Sprite::SHT2, 0, 7, ->PlayerActions.fireshotgun2(World, Player, PlayerSpriteDef), nil, MobjState::Dsgun3, 0, 0),      # State.Dsgun2
      MobjStateDef.new(37, Sprite::SHT2, 1, 7, nil, nil, MobjState::Dsgun4, 0, 0),                                                               # State.Dsgun3
      MobjStateDef.new(38, Sprite::SHT2, 2, 7, ->PlayerActions.checkreload(World, Player, PlayerSpriteDef), nil, MobjState::Dsgun5, 0, 0),       # State.Dsgun4
      MobjStateDef.new(39, Sprite::SHT2, 3, 7, ->PlayerActions.openshotgun2(World, Player, PlayerSpriteDef), nil, MobjState::Dsgun6, 0, 0),      # State.Dsgun5
      MobjStateDef.new(40, Sprite::SHT2, 4, 7, nil, nil, MobjState::Dsgun7, 0, 0),                                                               # State.Dsgun6
      MobjStateDef.new(41, Sprite::SHT2, 5, 7, ->PlayerActions.loadshotgun2(World, Player, PlayerSpriteDef), nil, MobjState::Dsgun8, 0, 0),      # State.Dsgun7
      MobjStateDef.new(42, Sprite::SHT2, 6, 6, nil, nil, MobjState::Dsgun9, 0, 0),                                                               # State.Dsgun8
      MobjStateDef.new(43, Sprite::SHT2, 7, 6, ->PlayerActions.closeshotgun2(World, Player, PlayerSpriteDef), nil, MobjState::Dsgun10, 0, 0),    # State.Dsgun9
      MobjStateDef.new(44, Sprite::SHT2, 0, 5, ->PlayerActions.refire(World, Player, PlayerSpriteDef), nil, MobjState::Dsgun, 0, 0),             # State.Dsgun10
      MobjStateDef.new(45, Sprite::SHT2, 1, 7, nil, nil, MobjState::Dsnr2, 0, 0),                                                                # State.Dsnr1
      MobjStateDef.new(46, Sprite::SHT2, 0, 3, nil, nil, MobjState::Dsgundown, 0, 0),                                                            # State.Dsnr2
      MobjStateDef.new(47, Sprite::SHT2, 32776, 5, ->PlayerActions.light1(World, Player, PlayerSpriteDef), nil, MobjState::Dsgunflash2, 0, 0),   # State.Dsgunflash1
      MobjStateDef.new(48, Sprite::SHT2, 32777, 4, ->PlayerActions.light2(World, Player, PlayerSpriteDef), nil, MobjState::Lightdone, 0, 0),     # State.Dsgunflash2
      MobjStateDef.new(49, Sprite::CHGG, 0, 1, ->PlayerActions.weaponready(World, Player, PlayerSpriteDef), nil, MobjState::Chain, 0, 0),        # State.Chain
      MobjStateDef.new(50, Sprite::CHGG, 0, 1, ->PlayerActions.lower(World, Player, PlayerSpriteDef), nil, MobjState::Chaindown, 0, 0),          # State.Chaindown
      MobjStateDef.new(51, Sprite::CHGG, 0, 1, ->PlayerActions.raise(World, Player, PlayerSpriteDef), nil, MobjState::Chainup, 0, 0),            # State.Chainup
      MobjStateDef.new(52, Sprite::CHGG, 0, 4, ->PlayerActions.firecgun(World, Player, PlayerSpriteDef), nil, MobjState::Chain2, 0, 0),          # State.Chain1
      MobjStateDef.new(53, Sprite::CHGG, 1, 4, ->PlayerActions.firecgun(World, Player, PlayerSpriteDef), nil, MobjState::Chain3, 0, 0),          # State.Chain2
      MobjStateDef.new(54, Sprite::CHGG, 1, 0, ->PlayerActions.refire(World, Player, PlayerSpriteDef), nil, MobjState::Chain, 0, 0),             # State.Chain3
      MobjStateDef.new(55, Sprite::CHGF, 32768, 5, ->PlayerActions.light1(World, Player, PlayerSpriteDef), nil, MobjState::Lightdone, 0, 0),     # State.Chainflash1
      MobjStateDef.new(56, Sprite::CHGF, 32769, 5, ->PlayerActions.light2(World, Player, PlayerSpriteDef), nil, MobjState::Lightdone, 0, 0),     # State.Chainflash2
      MobjStateDef.new(57, Sprite::MISG, 0, 1, ->PlayerActions.weaponready(World, Player, PlayerSpriteDef), nil, MobjState::Missile, 0, 0),      # State.Missile
      MobjStateDef.new(58, Sprite::MISG, 0, 1, ->PlayerActions.lower(World, Player, PlayerSpriteDef), nil, MobjState::Missiledown, 0, 0),        # State.Missiledown
      MobjStateDef.new(59, Sprite::MISG, 0, 1, ->PlayerActions.raise(World, Player, PlayerSpriteDef), nil, MobjState::Missileup, 0, 0),          # State.Missileup
      MobjStateDef.new(60, Sprite::MISG, 1, 8, ->PlayerActions.gunflash(World, Player, PlayerSpriteDef), nil, MobjState::Missile2, 0, 0),        # State.Missile1
      MobjStateDef.new(61, Sprite::MISG, 1, 12, ->PlayerActions.firemissile(World, Player, PlayerSpriteDef), nil, MobjState::Missile3, 0, 0),    # State.Missile2
      MobjStateDef.new(62, Sprite::MISG, 1, 0, ->PlayerActions.refire(World, Player, PlayerSpriteDef), nil, MobjState::Missile, 0, 0),           # State.Missile3
      MobjStateDef.new(63, Sprite::MISF, 32768, 3, ->PlayerActions.light1(World, Player, PlayerSpriteDef), nil, MobjState::Missileflash2, 0, 0), # State.Missileflash1
      MobjStateDef.new(64, Sprite::MISF, 32769, 4, nil, nil, MobjState::Missileflash3, 0, 0),                                                    # State.Missileflash2
      MobjStateDef.new(65, Sprite::MISF, 32770, 4, ->PlayerActions.light2(World, Player, PlayerSpriteDef), nil, MobjState::Missileflash4, 0, 0), # State.Missileflash3
      MobjStateDef.new(66, Sprite::MISF, 32771, 4, ->PlayerActions.light2(World, Player, PlayerSpriteDef), nil, MobjState::Lightdone, 0, 0),     # State.Missileflash4
      MobjStateDef.new(67, Sprite::SAWG, 2, 4, ->PlayerActions.weaponready(World, Player, PlayerSpriteDef), nil, MobjState::Sawb, 0, 0),         # State.saw
      MobjStateDef.new(68, Sprite::SAWG, 3, 4, ->PlayerActions.weaponready(World, Player, PlayerSpriteDef), nil, MobjState::Saw, 0, 0),          # State.sawb
      MobjStateDef.new(69, Sprite::SAWG, 2, 1, ->PlayerActions.lower(World, Player, PlayerSpriteDef), nil, MobjState::Sawdown, 0, 0),            # State.sawdown
      MobjStateDef.new(70, Sprite::SAWG, 2, 1, ->PlayerActions.raise(World, Player, PlayerSpriteDef), nil, MobjState::Sawup, 0, 0),              # State.sawup
      MobjStateDef.new(71, Sprite::SAWG, 0, 4, ->PlayerActions.saw(World, Player, PlayerSpriteDef), nil, MobjState::Saw2, 0, 0),                 # State.saw1
      MobjStateDef.new(72, Sprite::SAWG, 1, 4, ->PlayerActions.saw(World, Player, PlayerSpriteDef), nil, MobjState::Saw3, 0, 0),                 # State.saw2
      MobjStateDef.new(73, Sprite::SAWG, 1, 0, ->PlayerActions.refire(World, Player, PlayerSpriteDef), nil, MobjState::Saw, 0, 0),               # State.saw3
      MobjStateDef.new(74, Sprite::PLSG, 0, 1, ->PlayerActions.weaponready(World, Player, PlayerSpriteDef), nil, MobjState::Plasma, 0, 0),       # State.Plasma
      MobjStateDef.new(75, Sprite::PLSG, 0, 1, ->PlayerActions.lower(World, Player, PlayerSpriteDef), nil, MobjState::Plasmadown, 0, 0),         # State.Plasmadown
      MobjStateDef.new(76, Sprite::PLSG, 0, 1, ->PlayerActions.raise(World, Player, PlayerSpriteDef), nil, MobjState::Plasmaup, 0, 0),           # State.Plasmaup
      MobjStateDef.new(77, Sprite::PLSG, 0, 3, ->PlayerActions.fireplasma(World, Player, PlayerSpriteDef), nil, MobjState::Plasma2, 0, 0),       # State.Plasma1
      MobjStateDef.new(78, Sprite::PLSG, 1, 20, ->PlayerActions.refire(World, Player, PlayerSpriteDef), nil, MobjState::Plasma, 0, 0),           # State.Plasma2
      MobjStateDef.new(79, Sprite::PLSF, 32768, 4, ->PlayerActions.light1(World, Player, PlayerSpriteDef), nil, MobjState::Lightdone, 0, 0),     # State.Plasmaflash1
      MobjStateDef.new(80, Sprite::PLSF, 32769, 4, ->PlayerActions.light1(World, Player, PlayerSpriteDef), nil, MobjState::Lightdone, 0, 0),     # State.Plasmaflash2
      MobjStateDef.new(81, Sprite::BFGG, 0, 1, ->PlayerActions.weaponready(World, Player, PlayerSpriteDef), nil, MobjState::Bfg, 0, 0),          # State.Bfg
      MobjStateDef.new(82, Sprite::BFGG, 0, 1, ->PlayerActions.lower(World, Player, PlayerSpriteDef), nil, MobjState::Bfgdown, 0, 0),            # State.Bfgdown
      MobjStateDef.new(83, Sprite::BFGG, 0, 1, ->PlayerActions.raise(World, Player, PlayerSpriteDef), nil, MobjState::Bfgup, 0, 0),              # State.Bfgup
      MobjStateDef.new(84, Sprite::BFGG, 0, 20, ->PlayerActions.bfgsound(World, Player, PlayerSpriteDef), nil, MobjState::Bfg2, 0, 0),           # State.Bfg1
      MobjStateDef.new(85, Sprite::BFGG, 1, 10, ->PlayerActions.gunflash(World, Player, PlayerSpriteDef), nil, MobjState::Bfg3, 0, 0),           # State.Bfg2
      MobjStateDef.new(86, Sprite::BFGG, 1, 10, ->PlayerActions.firebfg(World, Player, PlayerSpriteDef), nil, MobjState::Bfg4, 0, 0),            # State.Bfg3
      MobjStateDef.new(87, Sprite::BFGG, 1, 20, ->PlayerActions.refire(World, Player, PlayerSpriteDef), nil, MobjState::Bfg, 0, 0),              # State.Bfg4
      MobjStateDef.new(88, Sprite::BFGF, 32768, 11, ->PlayerActions.light1(World, Player, PlayerSpriteDef), nil, MobjState::Bfgflash2, 0, 0),    # State.Bfgflash1
      MobjStateDef.new(89, Sprite::BFGF, 32769, 6, ->PlayerActions.light2(World, Player, PlayerSpriteDef), nil, MobjState::Lightdone, 0, 0),     # State.Bfgflash2
      MobjStateDef.new(90, Sprite::BLUD, 2, 8, nil, nil, MobjState::Blood2, 0, 0),                                                               # State.Blood1
      MobjStateDef.new(91, Sprite::BLUD, 1, 8, nil, nil, MobjState::Blood3, 0, 0),                                                               # State.Blood2
      MobjStateDef.new(92, Sprite::BLUD, 0, 8, nil, nil, MobjState::Nil, 0, 0),                                                                  # State.Blood3
      MobjStateDef.new(93, Sprite::PUFF, 32768, 4, nil, nil, MobjState::Puff2, 0, 0),                                                            # State.Puff1
      MobjStateDef.new(94, Sprite::PUFF, 1, 4, nil, nil, MobjState::Puff3, 0, 0),                                                                # State.Puff2
      MobjStateDef.new(95, Sprite::PUFF, 2, 4, nil, nil, MobjState::Puff4, 0, 0),                                                                # State.Puff3
      MobjStateDef.new(96, Sprite::PUFF, 3, 4, nil, nil, MobjState::Nil, 0, 0),                                                                  # State.Puff4
      MobjStateDef.new(97, Sprite::BAL1, 32768, 4, nil, nil, MobjState::Tball2, 0, 0),                                                           # State.Tball1
      MobjStateDef.new(98, Sprite::BAL1, 32769, 4, nil, nil, MobjState::Tball1, 0, 0),                                                           # State.Tball2
      MobjStateDef.new(99, Sprite::BAL1, 32770, 6, nil, nil, MobjState::Tballx2, 0, 0),                                                          # State.Tballx1
      MobjStateDef.new(100, Sprite::BAL1, 32771, 6, nil, nil, MobjState::Tballx3, 0, 0),                                                         # State.Tballx2
      MobjStateDef.new(101, Sprite::BAL1, 32772, 6, nil, nil, MobjState::Nil, 0, 0),                                                             # State.Tballx3
      MobjStateDef.new(102, Sprite::BAL2, 32768, 4, nil, nil, MobjState::Rball2, 0, 0),                                                          # State.Rball1
      MobjStateDef.new(103, Sprite::BAL2, 32769, 4, nil, nil, MobjState::Rball1, 0, 0),                                                          # State.Rball2
      MobjStateDef.new(104, Sprite::BAL2, 32770, 6, nil, nil, MobjState::Rballx2, 0, 0),                                                         # State.Rballx1
      MobjStateDef.new(105, Sprite::BAL2, 32771, 6, nil, nil, MobjState::Rballx3, 0, 0),                                                         # State.Rballx2
      MobjStateDef.new(106, Sprite::BAL2, 32772, 6, nil, nil, MobjState::Nil, 0, 0),                                                             # State.Rballx3
      MobjStateDef.new(107, Sprite::PLSS, 32768, 6, nil, nil, MobjState::Plasball2, 0, 0),                                                       # State.Plasball
      MobjStateDef.new(108, Sprite::PLSS, 32769, 6, nil, nil, MobjState::Plasball, 0, 0),                                                        # State.Plasball2
      MobjStateDef.new(109, Sprite::PLSE, 32768, 4, nil, nil, MobjState::Plasexp2, 0, 0),                                                        # State.Plasexp
      MobjStateDef.new(110, Sprite::PLSE, 32769, 4, nil, nil, MobjState::Plasexp3, 0, 0),                                                        # State.Plasexp2
      MobjStateDef.new(111, Sprite::PLSE, 32770, 4, nil, nil, MobjState::Plasexp4, 0, 0),                                                        # State.Plasexp3
      MobjStateDef.new(112, Sprite::PLSE, 32771, 4, nil, nil, MobjState::Plasexp5, 0, 0),                                                        # State.Plasexp4
      MobjStateDef.new(113, Sprite::PLSE, 32772, 4, nil, nil, MobjState::Nil, 0, 0),                                                             # State.Plasexp5
      MobjStateDef.new(114, Sprite::MISL, 32768, 1, nil, nil, MobjState::Rocket, 0, 0),                                                          # State.Rocket
      MobjStateDef.new(115, Sprite::BFS1, 32768, 4, nil, nil, MobjState::Bfgshot2, 0, 0),                                                        # State.Bfgshot
      MobjStateDef.new(116, Sprite::BFS1, 32769, 4, nil, nil, MobjState::Bfgshot, 0, 0),                                                         # State.Bfgshot2
      MobjStateDef.new(117, Sprite::BFE1, 32768, 8, nil, nil, MobjState::Bfgland2, 0, 0),                                                        # State.Bfgland
      MobjStateDef.new(118, Sprite::BFE1, 32769, 8, nil, nil, MobjState::Bfgland3, 0, 0),                                                        # State.Bfgland2
      MobjStateDef.new(119, Sprite::BFE1, 32770, 8, nil, ->MobjActions.bfgspray(World, Mobj), MobjState::Bfgland4, 0, 0),                        # State.Bfgland3
      MobjStateDef.new(120, Sprite::BFE1, 32771, 8, nil, nil, MobjState::Bfgland5, 0, 0),                                                        # State.Bfgland4
      MobjStateDef.new(121, Sprite::BFE1, 32772, 8, nil, nil, MobjState::Bfgland6, 0, 0),                                                        # State.Bfgland5
      MobjStateDef.new(122, Sprite::BFE1, 32773, 8, nil, nil, MobjState::Nil, 0, 0),                                                             # State.Bfgland6
      MobjStateDef.new(123, Sprite::BFE2, 32768, 8, nil, nil, MobjState::Bfgexp2, 0, 0),                                                         # State.Bfgexp
      MobjStateDef.new(124, Sprite::BFE2, 32769, 8, nil, nil, MobjState::Bfgexp3, 0, 0),                                                         # State.Bfgexp2
      MobjStateDef.new(125, Sprite::BFE2, 32770, 8, nil, nil, MobjState::Bfgexp4, 0, 0),                                                         # State.Bfgexp3
      MobjStateDef.new(126, Sprite::BFE2, 32771, 8, nil, nil, MobjState::Nil, 0, 0),                                                             # State.Bfgexp4
      MobjStateDef.new(127, Sprite::MISL, 32769, 8, nil, ->MobjActions.explode(World, Mobj), MobjState::Explode2, 0, 0),                         # State.explode1
      MobjStateDef.new(128, Sprite::MISL, 32770, 6, nil, nil, MobjState::Explode3, 0, 0),                                                        # State.explode2
      MobjStateDef.new(129, Sprite::MISL, 32771, 4, nil, nil, MobjState::Nil, 0, 0),                                                             # State.explode3
      MobjStateDef.new(130, Sprite::TFOG, 32768, 6, nil, nil, MobjState::Tfog01, 0, 0),                                                          # State.Tfog
      MobjStateDef.new(131, Sprite::TFOG, 32769, 6, nil, nil, MobjState::Tfog02, 0, 0),                                                          # State.Tfog01
      MobjStateDef.new(132, Sprite::TFOG, 32768, 6, nil, nil, MobjState::Tfog2, 0, 0),                                                           # State.Tfog02
      MobjStateDef.new(133, Sprite::TFOG, 32769, 6, nil, nil, MobjState::Tfog3, 0, 0),                                                           # State.Tfog2
      MobjStateDef.new(134, Sprite::TFOG, 32770, 6, nil, nil, MobjState::Tfog4, 0, 0),                                                           # State.Tfog3
      MobjStateDef.new(135, Sprite::TFOG, 32771, 6, nil, nil, MobjState::Tfog5, 0, 0),                                                           # State.Tfog4
      MobjStateDef.new(136, Sprite::TFOG, 32772, 6, nil, nil, MobjState::Tfog6, 0, 0),                                                           # State.Tfog5
      MobjStateDef.new(137, Sprite::TFOG, 32773, 6, nil, nil, MobjState::Tfog7, 0, 0),                                                           # State.Tfog6
      MobjStateDef.new(138, Sprite::TFOG, 32774, 6, nil, nil, MobjState::Tfog8, 0, 0),                                                           # State.Tfog7
      MobjStateDef.new(139, Sprite::TFOG, 32775, 6, nil, nil, MobjState::Tfog9, 0, 0),                                                           # State.Tfog8
      MobjStateDef.new(140, Sprite::TFOG, 32776, 6, nil, nil, MobjState::Tfog10, 0, 0),                                                          # State.Tfog9
      MobjStateDef.new(141, Sprite::TFOG, 32777, 6, nil, nil, MobjState::Nil, 0, 0),                                                             # State.Tfog10
      MobjStateDef.new(142, Sprite::IFOG, 32768, 6, nil, nil, MobjState::Ifog01, 0, 0),                                                          # State.Ifog
      MobjStateDef.new(143, Sprite::IFOG, 32769, 6, nil, nil, MobjState::Ifog02, 0, 0),                                                          # State.Ifog01
      MobjStateDef.new(144, Sprite::IFOG, 32768, 6, nil, nil, MobjState::Ifog2, 0, 0),                                                           # State.Ifog02
      MobjStateDef.new(145, Sprite::IFOG, 32769, 6, nil, nil, MobjState::Ifog3, 0, 0),                                                           # State.Ifog2
      MobjStateDef.new(146, Sprite::IFOG, 32770, 6, nil, nil, MobjState::Ifog4, 0, 0),                                                           # State.Ifog3
      MobjStateDef.new(147, Sprite::IFOG, 32771, 6, nil, nil, MobjState::Ifog5, 0, 0),                                                           # State.Ifog4
      MobjStateDef.new(148, Sprite::IFOG, 32772, 6, nil, nil, MobjState::Nil, 0, 0),                                                             # State.Ifog5
      MobjStateDef.new(149, Sprite::PLAY, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Play
      MobjStateDef.new(150, Sprite::PLAY, 0, 4, nil, nil, MobjState::PlayRun2, 0, 0),                                                            # State.PlayRun1
      MobjStateDef.new(151, Sprite::PLAY, 1, 4, nil, nil, MobjState::PlayRun3, 0, 0),                                                            # State.PlayRun2
      MobjStateDef.new(152, Sprite::PLAY, 2, 4, nil, nil, MobjState::PlayRun4, 0, 0),                                                            # State.PlayRun3
      MobjStateDef.new(153, Sprite::PLAY, 3, 4, nil, nil, MobjState::PlayRun1, 0, 0),                                                            # State.PlayRun4
      MobjStateDef.new(154, Sprite::PLAY, 4, 12, nil, nil, MobjState::Play, 0, 0),                                                               # State.PlayAtk1
      MobjStateDef.new(155, Sprite::PLAY, 32773, 6, nil, nil, MobjState::PlayAtk1, 0, 0),                                                        # State.PlayAtk2
      MobjStateDef.new(156, Sprite::PLAY, 6, 4, nil, nil, MobjState::PlayPain2, 0, 0),                                                           # State.PlayPain
      MobjStateDef.new(157, Sprite::PLAY, 6, 4, nil, ->MobjActions.pain(World, Mobj), MobjState::Play, 0, 0),                                    # State.PlayPain2
      MobjStateDef.new(158, Sprite::PLAY, 7, 10, nil, nil, MobjState::PlayDie2, 0, 0),                                                           # State.PlayDie1
      MobjStateDef.new(159, Sprite::PLAY, 8, 10, nil, ->MobjActions.player_scream(World, Mobj), MobjState::PlayDie3, 0, 0),                      # State.PlayDie2
      MobjStateDef.new(160, Sprite::PLAY, 9, 10, nil, ->MobjActions.fall(World, Mobj), MobjState::PlayDie4, 0, 0),                               # State.PlayDie3
      MobjStateDef.new(161, Sprite::PLAY, 10, 10, nil, nil, MobjState::PlayDie5, 0, 0),                                                          # State.PlayDie4
      MobjStateDef.new(162, Sprite::PLAY, 11, 10, nil, nil, MobjState::PlayDie6, 0, 0),                                                          # State.PlayDie5
      MobjStateDef.new(163, Sprite::PLAY, 12, 10, nil, nil, MobjState::PlayDie7, 0, 0),                                                          # State.PlayDie6
      MobjStateDef.new(164, Sprite::PLAY, 13, -1, nil, nil, MobjState::Nil, 0, 0),                                                               # State.PlayDie7
      MobjStateDef.new(165, Sprite::PLAY, 14, 5, nil, nil, MobjState::PlayXdie2, 0, 0),                                                          # State.PlayXdie1
      MobjStateDef.new(166, Sprite::PLAY, 15, 5, nil, ->MobjActions.xscream(World, Mobj), MobjState::PlayXdie3, 0, 0),                           # State.PlayXdie2
      MobjStateDef.new(167, Sprite::PLAY, 16, 5, nil, ->MobjActions.fall(World, Mobj), MobjState::PlayXdie4, 0, 0),                              # State.PlayXdie3
      MobjStateDef.new(168, Sprite::PLAY, 17, 5, nil, nil, MobjState::PlayXdie5, 0, 0),                                                          # State.PlayXdie4
      MobjStateDef.new(169, Sprite::PLAY, 18, 5, nil, nil, MobjState::PlayXdie6, 0, 0),                                                          # State.PlayXdie5
      MobjStateDef.new(170, Sprite::PLAY, 19, 5, nil, nil, MobjState::PlayXdie7, 0, 0),                                                          # State.PlayXdie6
      MobjStateDef.new(171, Sprite::PLAY, 20, 5, nil, nil, MobjState::PlayXdie8, 0, 0),                                                          # State.PlayXdie7
      MobjStateDef.new(172, Sprite::PLAY, 21, 5, nil, nil, MobjState::PlayXdie9, 0, 0),                                                          # State.PlayXdie8
      MobjStateDef.new(173, Sprite::PLAY, 22, -1, nil, nil, MobjState::Nil, 0, 0),                                                               # State.PlayXdie9
      MobjStateDef.new(174, Sprite::POSS, 0, 10, nil, ->MobjActions.look(World, Mobj), MobjState::PossStnd2, 0, 0),                              # State.PossStnd
      MobjStateDef.new(175, Sprite::POSS, 1, 10, nil, ->MobjActions.look(World, Mobj), MobjState::PossStnd, 0, 0),                               # State.PossStnd2
      MobjStateDef.new(176, Sprite::POSS, 0, 4, nil, ->MobjActions.chase(World, Mobj), MobjState::PossRun2, 0, 0),                               # State.PossRun1
      MobjStateDef.new(177, Sprite::POSS, 0, 4, nil, ->MobjActions.chase(World, Mobj), MobjState::PossRun3, 0, 0),                               # State.PossRun2
      MobjStateDef.new(178, Sprite::POSS, 1, 4, nil, ->MobjActions.chase(World, Mobj), MobjState::PossRun4, 0, 0),                               # State.PossRun3
      MobjStateDef.new(179, Sprite::POSS, 1, 4, nil, ->MobjActions.chase(World, Mobj), MobjState::PossRun5, 0, 0),                               # State.PossRun4
      MobjStateDef.new(180, Sprite::POSS, 2, 4, nil, ->MobjActions.chase(World, Mobj), MobjState::PossRun6, 0, 0),                               # State.PossRun5
      MobjStateDef.new(181, Sprite::POSS, 2, 4, nil, ->MobjActions.chase(World, Mobj), MobjState::PossRun7, 0, 0),                               # State.PossRun6
      MobjStateDef.new(182, Sprite::POSS, 3, 4, nil, ->MobjActions.chase(World, Mobj), MobjState::PossRun8, 0, 0),                               # State.PossRun7
      MobjStateDef.new(183, Sprite::POSS, 3, 4, nil, ->MobjActions.chase(World, Mobj), MobjState::PossRun1, 0, 0),                               # State.PossRun8
      MobjStateDef.new(184, Sprite::POSS, 4, 10, nil, ->MobjActions.face_target(World, Mobj), MobjState::PossAtk2, 0, 0),                        # State.PossAtk1
      MobjStateDef.new(185, Sprite::POSS, 5, 8, nil, ->MobjActions.pos_attack(World, Mobj), MobjState::PossAtk3, 0, 0),                          # State.PossAtk2
      MobjStateDef.new(186, Sprite::POSS, 4, 8, nil, nil, MobjState::PossRun1, 0, 0),                                                            # State.PossAtk3
      MobjStateDef.new(187, Sprite::POSS, 6, 3, nil, nil, MobjState::PossPain2, 0, 0),                                                           # State.PossPain
      MobjStateDef.new(188, Sprite::POSS, 6, 3, nil, ->MobjActions.pain(World, Mobj), MobjState::PossRun1, 0, 0),                                # State.PossPain2
      MobjStateDef.new(189, Sprite::POSS, 7, 5, nil, nil, MobjState::PossDie2, 0, 0),                                                            # State.PossDie1
      MobjStateDef.new(190, Sprite::POSS, 8, 5, nil, ->MobjActions.scream(World, Mobj), MobjState::PossDie3, 0, 0),                              # State.PossDie2
      MobjStateDef.new(191, Sprite::POSS, 9, 5, nil, ->MobjActions.fall(World, Mobj), MobjState::PossDie4, 0, 0),                                # State.PossDie3
      MobjStateDef.new(192, Sprite::POSS, 10, 5, nil, nil, MobjState::PossDie5, 0, 0),                                                           # State.PossDie4
      MobjStateDef.new(193, Sprite::POSS, 11, -1, nil, nil, MobjState::Nil, 0, 0),                                                               # State.PossDie5
      MobjStateDef.new(194, Sprite::POSS, 12, 5, nil, nil, MobjState::PossXdie2, 0, 0),                                                          # State.PossXdie1
      MobjStateDef.new(195, Sprite::POSS, 13, 5, nil, ->MobjActions.xscream(World, Mobj), MobjState::PossXdie3, 0, 0),                           # State.PossXdie2
      MobjStateDef.new(196, Sprite::POSS, 14, 5, nil, ->MobjActions.fall(World, Mobj), MobjState::PossXdie4, 0, 0),                              # State.PossXdie3
      MobjStateDef.new(197, Sprite::POSS, 15, 5, nil, nil, MobjState::PossXdie5, 0, 0),                                                          # State.PossXdie4
      MobjStateDef.new(198, Sprite::POSS, 16, 5, nil, nil, MobjState::PossXdie6, 0, 0),                                                          # State.PossXdie5
      MobjStateDef.new(199, Sprite::POSS, 17, 5, nil, nil, MobjState::PossXdie7, 0, 0),                                                          # State.PossXdie6
      MobjStateDef.new(200, Sprite::POSS, 18, 5, nil, nil, MobjState::PossXdie8, 0, 0),                                                          # State.PossXdie7
      MobjStateDef.new(201, Sprite::POSS, 19, 5, nil, nil, MobjState::PossXdie9, 0, 0),                                                          # State.PossXdie8
      MobjStateDef.new(202, Sprite::POSS, 20, -1, nil, nil, MobjState::Nil, 0, 0),                                                               # State.PossXdie9
      MobjStateDef.new(203, Sprite::POSS, 10, 5, nil, nil, MobjState::PossRaise2, 0, 0),                                                         # State.PossRaise1
      MobjStateDef.new(204, Sprite::POSS, 9, 5, nil, nil, MobjState::PossRaise3, 0, 0),                                                          # State.PossRaise2
      MobjStateDef.new(205, Sprite::POSS, 8, 5, nil, nil, MobjState::PossRaise4, 0, 0),                                                          # State.PossRaise3
      MobjStateDef.new(206, Sprite::POSS, 7, 5, nil, nil, MobjState::PossRun1, 0, 0),                                                            # State.PossRaise4
      MobjStateDef.new(207, Sprite::SPOS, 0, 10, nil, ->MobjActions.look(World, Mobj), MobjState::SposStnd2, 0, 0),                              # State.SposStnd
      MobjStateDef.new(208, Sprite::SPOS, 1, 10, nil, ->MobjActions.look(World, Mobj), MobjState::SposStnd, 0, 0),                               # State.SposStnd2
      MobjStateDef.new(209, Sprite::SPOS, 0, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::SposRun2, 0, 0),                               # State.SposRun1
      MobjStateDef.new(210, Sprite::SPOS, 0, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::SposRun3, 0, 0),                               # State.SposRun2
      MobjStateDef.new(211, Sprite::SPOS, 1, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::SposRun4, 0, 0),                               # State.SposRun3
      MobjStateDef.new(212, Sprite::SPOS, 1, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::SposRun5, 0, 0),                               # State.SposRun4
      MobjStateDef.new(213, Sprite::SPOS, 2, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::SposRun6, 0, 0),                               # State.SposRun5
      MobjStateDef.new(214, Sprite::SPOS, 2, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::SposRun7, 0, 0),                               # State.SposRun6
      MobjStateDef.new(215, Sprite::SPOS, 3, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::SposRun8, 0, 0),                               # State.SposRun7
      MobjStateDef.new(216, Sprite::SPOS, 3, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::SposRun1, 0, 0),                               # State.SposRun8
      MobjStateDef.new(217, Sprite::SPOS, 4, 10, nil, ->MobjActions.face_target(World, Mobj), MobjState::SposAtk2, 0, 0),                        # State.SposAtk1
      MobjStateDef.new(218, Sprite::SPOS, 32773, 10, nil, ->MobjActions.spos_attack(World, Mobj), MobjState::SposAtk3, 0, 0),                    # State.SposAtk2
      MobjStateDef.new(219, Sprite::SPOS, 4, 10, nil, nil, MobjState::SposRun1, 0, 0),                                                           # State.SposAtk3
      MobjStateDef.new(220, Sprite::SPOS, 6, 3, nil, nil, MobjState::SposPain2, 0, 0),                                                           # State.SposPain
      MobjStateDef.new(221, Sprite::SPOS, 6, 3, nil, ->MobjActions.pain(World, Mobj), MobjState::SposRun1, 0, 0),                                # State.SposPain2
      MobjStateDef.new(222, Sprite::SPOS, 7, 5, nil, nil, MobjState::SposDie2, 0, 0),                                                            # State.SposDie1
      MobjStateDef.new(223, Sprite::SPOS, 8, 5, nil, ->MobjActions.scream(World, Mobj), MobjState::SposDie3, 0, 0),                              # State.SposDie2
      MobjStateDef.new(224, Sprite::SPOS, 9, 5, nil, ->MobjActions.fall(World, Mobj), MobjState::SposDie4, 0, 0),                                # State.SposDie3
      MobjStateDef.new(225, Sprite::SPOS, 10, 5, nil, nil, MobjState::SposDie5, 0, 0),                                                           # State.SposDie4
      MobjStateDef.new(226, Sprite::SPOS, 11, -1, nil, nil, MobjState::Nil, 0, 0),                                                               # State.SposDie5
      MobjStateDef.new(227, Sprite::SPOS, 12, 5, nil, nil, MobjState::SposXdie2, 0, 0),                                                          # State.SposXdie1
      MobjStateDef.new(228, Sprite::SPOS, 13, 5, nil, ->MobjActions.xscream(World, Mobj), MobjState::SposXdie3, 0, 0),                           # State.SposXdie2
      MobjStateDef.new(229, Sprite::SPOS, 14, 5, nil, ->MobjActions.fall(World, Mobj), MobjState::SposXdie4, 0, 0),                              # State.SposXdie3
      MobjStateDef.new(230, Sprite::SPOS, 15, 5, nil, nil, MobjState::SposXdie5, 0, 0),                                                          # State.SposXdie4
      MobjStateDef.new(231, Sprite::SPOS, 16, 5, nil, nil, MobjState::SposXdie6, 0, 0),                                                          # State.SposXdie5
      MobjStateDef.new(232, Sprite::SPOS, 17, 5, nil, nil, MobjState::SposXdie7, 0, 0),                                                          # State.SposXdie6
      MobjStateDef.new(233, Sprite::SPOS, 18, 5, nil, nil, MobjState::SposXdie8, 0, 0),                                                          # State.SposXdie7
      MobjStateDef.new(234, Sprite::SPOS, 19, 5, nil, nil, MobjState::SposXdie9, 0, 0),                                                          # State.SposXdie8
      MobjStateDef.new(235, Sprite::SPOS, 20, -1, nil, nil, MobjState::Nil, 0, 0),                                                               # State.SposXdie9
      MobjStateDef.new(236, Sprite::SPOS, 11, 5, nil, nil, MobjState::SposRaise2, 0, 0),                                                         # State.SposRaise1
      MobjStateDef.new(237, Sprite::SPOS, 10, 5, nil, nil, MobjState::SposRaise3, 0, 0),                                                         # State.SposRaise2
      MobjStateDef.new(238, Sprite::SPOS, 9, 5, nil, nil, MobjState::SposRaise4, 0, 0),                                                          # State.SposRaise3
      MobjStateDef.new(239, Sprite::SPOS, 8, 5, nil, nil, MobjState::SposRaise5, 0, 0),                                                          # State.SposRaise4
      MobjStateDef.new(240, Sprite::SPOS, 7, 5, nil, nil, MobjState::SposRun1, 0, 0),                                                            # State.SposRaise5
      MobjStateDef.new(241, Sprite::VILE, 0, 10, nil, ->MobjActions.look(World, Mobj), MobjState::VileStnd2, 0, 0),                              # State.VileStnd
      MobjStateDef.new(242, Sprite::VILE, 1, 10, nil, ->MobjActions.look(World, Mobj), MobjState::VileStnd, 0, 0),                               # State.VileStnd2
      MobjStateDef.new(243, Sprite::VILE, 0, 2, nil, ->MobjActions.vile_chase(World, Mobj), MobjState::VileRun2, 0, 0),                          # State.VileRun1
      MobjStateDef.new(244, Sprite::VILE, 0, 2, nil, ->MobjActions.vile_chase(World, Mobj), MobjState::VileRun3, 0, 0),                          # State.VileRun2
      MobjStateDef.new(245, Sprite::VILE, 1, 2, nil, ->MobjActions.vile_chase(World, Mobj), MobjState::VileRun4, 0, 0),                          # State.VileRun3
      MobjStateDef.new(246, Sprite::VILE, 1, 2, nil, ->MobjActions.vile_chase(World, Mobj), MobjState::VileRun5, 0, 0),                          # State.VileRun4
      MobjStateDef.new(247, Sprite::VILE, 2, 2, nil, ->MobjActions.vile_chase(World, Mobj), MobjState::VileRun6, 0, 0),                          # State.VileRun5
      MobjStateDef.new(248, Sprite::VILE, 2, 2, nil, ->MobjActions.vile_chase(World, Mobj), MobjState::VileRun7, 0, 0),                          # State.VileRun6
      MobjStateDef.new(249, Sprite::VILE, 3, 2, nil, ->MobjActions.vile_chase(World, Mobj), MobjState::VileRun8, 0, 0),                          # State.VileRun7
      MobjStateDef.new(250, Sprite::VILE, 3, 2, nil, ->MobjActions.vile_chase(World, Mobj), MobjState::VileRun9, 0, 0),                          # State.VileRun8
      MobjStateDef.new(251, Sprite::VILE, 4, 2, nil, ->MobjActions.vile_chase(World, Mobj), MobjState::VileRun10, 0, 0),                         # State.VileRun9
      MobjStateDef.new(252, Sprite::VILE, 4, 2, nil, ->MobjActions.vile_chase(World, Mobj), MobjState::VileRun11, 0, 0),                         # State.VileRun10
      MobjStateDef.new(253, Sprite::VILE, 5, 2, nil, ->MobjActions.vile_chase(World, Mobj), MobjState::VileRun12, 0, 0),                         # State.VileRun11
      MobjStateDef.new(254, Sprite::VILE, 5, 2, nil, ->MobjActions.vile_chase(World, Mobj), MobjState::VileRun1, 0, 0),                          # State.VileRun12
      MobjStateDef.new(255, Sprite::VILE, 32774, 0, nil, ->MobjActions.vile_start(World, Mobj), MobjState::VileAtk2, 0, 0),                      # State.VileAtk1
      MobjStateDef.new(256, Sprite::VILE, 32774, 10, nil, ->MobjActions.face_target(World, Mobj), MobjState::VileAtk3, 0, 0),                    # State.VileAtk2
      MobjStateDef.new(257, Sprite::VILE, 32775, 8, nil, ->MobjActions.vile_target(World, Mobj), MobjState::VileAtk4, 0, 0),                     # State.VileAtk3
      MobjStateDef.new(258, Sprite::VILE, 32776, 8, nil, ->MobjActions.face_target(World, Mobj), MobjState::VileAtk5, 0, 0),                     # State.VileAtk4
      MobjStateDef.new(259, Sprite::VILE, 32777, 8, nil, ->MobjActions.face_target(World, Mobj), MobjState::VileAtk6, 0, 0),                     # State.VileAtk5
      MobjStateDef.new(260, Sprite::VILE, 32778, 8, nil, ->MobjActions.face_target(World, Mobj), MobjState::VileAtk7, 0, 0),                     # State.VileAtk6
      MobjStateDef.new(261, Sprite::VILE, 32779, 8, nil, ->MobjActions.face_target(World, Mobj), MobjState::VileAtk8, 0, 0),                     # State.VileAtk7
      MobjStateDef.new(262, Sprite::VILE, 32780, 8, nil, ->MobjActions.face_target(World, Mobj), MobjState::VileAtk9, 0, 0),                     # State.VileAtk8
      MobjStateDef.new(263, Sprite::VILE, 32781, 8, nil, ->MobjActions.face_target(World, Mobj), MobjState::VileAtk10, 0, 0),                    # State.VileAtk9
      MobjStateDef.new(264, Sprite::VILE, 32782, 8, nil, ->MobjActions.vile_attack(World, Mobj), MobjState::VileAtk11, 0, 0),                    # State.VileAtk10
      MobjStateDef.new(265, Sprite::VILE, 32783, 20, nil, nil, MobjState::VileRun1, 0, 0),                                                       # State.VileAtk11
      MobjStateDef.new(266, Sprite::VILE, 32794, 10, nil, nil, MobjState::VileHeal2, 0, 0),                                                      # State.VileHeal1
      MobjStateDef.new(267, Sprite::VILE, 32795, 10, nil, nil, MobjState::VileHeal3, 0, 0),                                                      # State.VileHeal2
      MobjStateDef.new(268, Sprite::VILE, 32796, 10, nil, nil, MobjState::VileRun1, 0, 0),                                                       # State.VileHeal3
      MobjStateDef.new(269, Sprite::VILE, 16, 5, nil, nil, MobjState::VilePain2, 0, 0),                                                          # State.VilePain
      MobjStateDef.new(270, Sprite::VILE, 16, 5, nil, ->MobjActions.pain(World, Mobj), MobjState::VileRun1, 0, 0),                               # State.VilePain2
      MobjStateDef.new(271, Sprite::VILE, 16, 7, nil, nil, MobjState::VileDie2, 0, 0),                                                           # State.VileDie1
      MobjStateDef.new(272, Sprite::VILE, 17, 7, nil, ->MobjActions.scream(World, Mobj), MobjState::VileDie3, 0, 0),                             # State.VileDie2
      MobjStateDef.new(273, Sprite::VILE, 18, 7, nil, ->MobjActions.fall(World, Mobj), MobjState::VileDie4, 0, 0),                               # State.VileDie3
      MobjStateDef.new(274, Sprite::VILE, 19, 7, nil, nil, MobjState::VileDie5, 0, 0),                                                           # State.VileDie4
      MobjStateDef.new(275, Sprite::VILE, 20, 7, nil, nil, MobjState::VileDie6, 0, 0),                                                           # State.VileDie5
      MobjStateDef.new(276, Sprite::VILE, 21, 7, nil, nil, MobjState::VileDie7, 0, 0),                                                           # State.VileDie6
      MobjStateDef.new(277, Sprite::VILE, 22, 7, nil, nil, MobjState::VileDie8, 0, 0),                                                           # State.VileDie7
      MobjStateDef.new(278, Sprite::VILE, 23, 5, nil, nil, MobjState::VileDie9, 0, 0),                                                           # State.VileDie8
      MobjStateDef.new(279, Sprite::VILE, 24, 5, nil, nil, MobjState::VileDie10, 0, 0),                                                          # State.VileDie9
      MobjStateDef.new(280, Sprite::VILE, 25, -1, nil, nil, MobjState::Nil, 0, 0),                                                               # State.VileDie10
      MobjStateDef.new(281, Sprite::FIRE, 32768, 2, nil, ->MobjActions.start_fire(World, Mobj), MobjState::Fire2, 0, 0),                         # State.Fire1
      MobjStateDef.new(282, Sprite::FIRE, 32769, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Fire3, 0, 0),                               # State.Fire2
      MobjStateDef.new(283, Sprite::FIRE, 32768, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Fire4, 0, 0),                               # State.Fire3
      MobjStateDef.new(284, Sprite::FIRE, 32769, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Fire5, 0, 0),                               # State.Fire4
      MobjStateDef.new(285, Sprite::FIRE, 32770, 2, nil, ->MobjActions.fire_crackle(World, Mobj), MobjState::Fire6, 0, 0),                       # State.Fire5
      MobjStateDef.new(286, Sprite::FIRE, 32769, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Fire7, 0, 0),                               # State.Fire6
      MobjStateDef.new(287, Sprite::FIRE, 32770, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Fire8, 0, 0),                               # State.Fire7
      MobjStateDef.new(288, Sprite::FIRE, 32769, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Fire9, 0, 0),                               # State.Fire8
      MobjStateDef.new(289, Sprite::FIRE, 32770, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Fire10, 0, 0),                              # State.Fire9
      MobjStateDef.new(290, Sprite::FIRE, 32771, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Fire11, 0, 0),                              # State.Fire10
      MobjStateDef.new(291, Sprite::FIRE, 32770, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Fire12, 0, 0),                              # State.Fire11
      MobjStateDef.new(292, Sprite::FIRE, 32771, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Fire13, 0, 0),                              # State.Fire12
      MobjStateDef.new(293, Sprite::FIRE, 32770, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Fire14, 0, 0),                              # State.Fire13
      MobjStateDef.new(294, Sprite::FIRE, 32771, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Fire15, 0, 0),                              # State.Fire14
      MobjStateDef.new(295, Sprite::FIRE, 32772, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Fire16, 0, 0),                              # State.Fire15
      MobjStateDef.new(296, Sprite::FIRE, 32771, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Fire17, 0, 0),                              # State.Fire16
      MobjStateDef.new(297, Sprite::FIRE, 32772, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Fire18, 0, 0),                              # State.Fire17
      MobjStateDef.new(298, Sprite::FIRE, 32771, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Fire19, 0, 0),                              # State.Fire18
      MobjStateDef.new(299, Sprite::FIRE, 32772, 2, nil, ->MobjActions.fire_crackle(World, Mobj), MobjState::Fire20, 0, 0),                      # State.Fire19
      MobjStateDef.new(300, Sprite::FIRE, 32773, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Fire21, 0, 0),                              # State.Fire20
      MobjStateDef.new(301, Sprite::FIRE, 32772, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Fire22, 0, 0),                              # State.Fire21
      MobjStateDef.new(302, Sprite::FIRE, 32773, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Fire23, 0, 0),                              # State.Fire22
      MobjStateDef.new(303, Sprite::FIRE, 32772, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Fire24, 0, 0),                              # State.Fire23
      MobjStateDef.new(304, Sprite::FIRE, 32773, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Fire25, 0, 0),                              # State.Fire24
      MobjStateDef.new(305, Sprite::FIRE, 32774, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Fire26, 0, 0),                              # State.Fire25
      MobjStateDef.new(306, Sprite::FIRE, 32775, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Fire27, 0, 0),                              # State.Fire26
      MobjStateDef.new(307, Sprite::FIRE, 32774, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Fire28, 0, 0),                              # State.Fire27
      MobjStateDef.new(308, Sprite::FIRE, 32775, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Fire29, 0, 0),                              # State.Fire28
      MobjStateDef.new(309, Sprite::FIRE, 32774, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Fire30, 0, 0),                              # State.Fire29
      MobjStateDef.new(310, Sprite::FIRE, 32775, 2, nil, ->MobjActions.fire(World, Mobj), MobjState::Nil, 0, 0),                                 # State.Fire30
      MobjStateDef.new(311, Sprite::PUFF, 1, 4, nil, nil, MobjState::Smoke2, 0, 0),                                                              # State.Smoke1
      MobjStateDef.new(312, Sprite::PUFF, 2, 4, nil, nil, MobjState::Smoke3, 0, 0),                                                              # State.Smoke2
      MobjStateDef.new(313, Sprite::PUFF, 1, 4, nil, nil, MobjState::Smoke4, 0, 0),                                                              # State.Smoke3
      MobjStateDef.new(314, Sprite::PUFF, 2, 4, nil, nil, MobjState::Smoke5, 0, 0),                                                              # State.Smoke4
      MobjStateDef.new(315, Sprite::PUFF, 3, 4, nil, nil, MobjState::Nil, 0, 0),                                                                 # State.Smoke5
      MobjStateDef.new(316, Sprite::FATB, 32768, 2, nil, ->MobjActions.tracer(World, Mobj), MobjState::Tracer2, 0, 0),                           # State.tracer
      MobjStateDef.new(317, Sprite::FATB, 32769, 2, nil, ->MobjActions.tracer(World, Mobj), MobjState::Tracer, 0, 0),                            # State.Tracer2
      MobjStateDef.new(318, Sprite::FBXP, 32768, 8, nil, nil, MobjState::Traceexp2, 0, 0),                                                       # State.Traceexp1
      MobjStateDef.new(319, Sprite::FBXP, 32769, 6, nil, nil, MobjState::Traceexp3, 0, 0),                                                       # State.Traceexp2
      MobjStateDef.new(320, Sprite::FBXP, 32770, 4, nil, nil, MobjState::Nil, 0, 0),                                                             # State.Traceexp3
      MobjStateDef.new(321, Sprite::SKEL, 0, 10, nil, ->MobjActions.look(World, Mobj), MobjState::SkelStnd2, 0, 0),                              # State.SkelStnd
      MobjStateDef.new(322, Sprite::SKEL, 1, 10, nil, ->MobjActions.look(World, Mobj), MobjState::SkelStnd, 0, 0),                               # State.SkelStnd2
      MobjStateDef.new(323, Sprite::SKEL, 0, 2, nil, ->MobjActions.chase(World, Mobj), MobjState::SkelRun2, 0, 0),                               # State.SkelRun1
      MobjStateDef.new(324, Sprite::SKEL, 0, 2, nil, ->MobjActions.chase(World, Mobj), MobjState::SkelRun3, 0, 0),                               # State.SkelRun2
      MobjStateDef.new(325, Sprite::SKEL, 1, 2, nil, ->MobjActions.chase(World, Mobj), MobjState::SkelRun4, 0, 0),                               # State.SkelRun3
      MobjStateDef.new(326, Sprite::SKEL, 1, 2, nil, ->MobjActions.chase(World, Mobj), MobjState::SkelRun5, 0, 0),                               # State.SkelRun4
      MobjStateDef.new(327, Sprite::SKEL, 2, 2, nil, ->MobjActions.chase(World, Mobj), MobjState::SkelRun6, 0, 0),                               # State.SkelRun5
      MobjStateDef.new(328, Sprite::SKEL, 2, 2, nil, ->MobjActions.chase(World, Mobj), MobjState::SkelRun7, 0, 0),                               # State.SkelRun6
      MobjStateDef.new(329, Sprite::SKEL, 3, 2, nil, ->MobjActions.chase(World, Mobj), MobjState::SkelRun8, 0, 0),                               # State.SkelRun7
      MobjStateDef.new(330, Sprite::SKEL, 3, 2, nil, ->MobjActions.chase(World, Mobj), MobjState::SkelRun9, 0, 0),                               # State.SkelRun8
      MobjStateDef.new(331, Sprite::SKEL, 4, 2, nil, ->MobjActions.chase(World, Mobj), MobjState::SkelRun10, 0, 0),                              # State.SkelRun9
      MobjStateDef.new(332, Sprite::SKEL, 4, 2, nil, ->MobjActions.chase(World, Mobj), MobjState::SkelRun11, 0, 0),                              # State.SkelRun10
      MobjStateDef.new(333, Sprite::SKEL, 5, 2, nil, ->MobjActions.chase(World, Mobj), MobjState::SkelRun12, 0, 0),                              # State.SkelRun11
      MobjStateDef.new(334, Sprite::SKEL, 5, 2, nil, ->MobjActions.chase(World, Mobj), MobjState::SkelRun1, 0, 0),                               # State.SkelRun12
      MobjStateDef.new(335, Sprite::SKEL, 6, 0, nil, ->MobjActions.face_target(World, Mobj), MobjState::SkelFist2, 0, 0),                        # State.SkelFist1
      MobjStateDef.new(336, Sprite::SKEL, 6, 6, nil, ->MobjActions.skel_whoosh(World, Mobj), MobjState::SkelFist3, 0, 0),                        # State.SkelFist2
      MobjStateDef.new(337, Sprite::SKEL, 7, 6, nil, ->MobjActions.face_target(World, Mobj), MobjState::SkelFist4, 0, 0),                        # State.SkelFist3
      MobjStateDef.new(338, Sprite::SKEL, 8, 6, nil, ->MobjActions.skel_fist(World, Mobj), MobjState::SkelRun1, 0, 0),                           # State.SkelFist4
      MobjStateDef.new(339, Sprite::SKEL, 32777, 0, nil, ->MobjActions.face_target(World, Mobj), MobjState::SkelMiss2, 0, 0),                    # State.SkelMiss1
      MobjStateDef.new(340, Sprite::SKEL, 32777, 10, nil, ->MobjActions.face_target(World, Mobj), MobjState::SkelMiss3, 0, 0),                   # State.SkelMiss2
      MobjStateDef.new(341, Sprite::SKEL, 10, 10, nil, ->MobjActions.skel_missile(World, Mobj), MobjState::SkelMiss4, 0, 0),                     # State.SkelMiss3
      MobjStateDef.new(342, Sprite::SKEL, 10, 10, nil, ->MobjActions.face_target(World, Mobj), MobjState::SkelRun1, 0, 0),                       # State.SkelMiss4
      MobjStateDef.new(343, Sprite::SKEL, 11, 5, nil, nil, MobjState::SkelPain2, 0, 0),                                                          # State.SkelPain
      MobjStateDef.new(344, Sprite::SKEL, 11, 5, nil, ->MobjActions.pain(World, Mobj), MobjState::SkelRun1, 0, 0),                               # State.SkelPain2
      MobjStateDef.new(345, Sprite::SKEL, 11, 7, nil, nil, MobjState::SkelDie2, 0, 0),                                                           # State.SkelDie1
      MobjStateDef.new(346, Sprite::SKEL, 12, 7, nil, nil, MobjState::SkelDie3, 0, 0),                                                           # State.SkelDie2
      MobjStateDef.new(347, Sprite::SKEL, 13, 7, nil, ->MobjActions.scream(World, Mobj), MobjState::SkelDie4, 0, 0),                             # State.SkelDie3
      MobjStateDef.new(348, Sprite::SKEL, 14, 7, nil, ->MobjActions.fall(World, Mobj), MobjState::SkelDie5, 0, 0),                               # State.SkelDie4
      MobjStateDef.new(349, Sprite::SKEL, 15, 7, nil, nil, MobjState::SkelDie6, 0, 0),                                                           # State.SkelDie5
      MobjStateDef.new(350, Sprite::SKEL, 16, -1, nil, nil, MobjState::Nil, 0, 0),                                                               # State.SkelDie6
      MobjStateDef.new(351, Sprite::SKEL, 16, 5, nil, nil, MobjState::SkelRaise2, 0, 0),                                                         # State.SkelRaise1
      MobjStateDef.new(352, Sprite::SKEL, 15, 5, nil, nil, MobjState::SkelRaise3, 0, 0),                                                         # State.SkelRaise2
      MobjStateDef.new(353, Sprite::SKEL, 14, 5, nil, nil, MobjState::SkelRaise4, 0, 0),                                                         # State.SkelRaise3
      MobjStateDef.new(354, Sprite::SKEL, 13, 5, nil, nil, MobjState::SkelRaise5, 0, 0),                                                         # State.SkelRaise4
      MobjStateDef.new(355, Sprite::SKEL, 12, 5, nil, nil, MobjState::SkelRaise6, 0, 0),                                                         # State.SkelRaise5
      MobjStateDef.new(356, Sprite::SKEL, 11, 5, nil, nil, MobjState::SkelRun1, 0, 0),                                                           # State.SkelRaise6
      MobjStateDef.new(357, Sprite::MANF, 32768, 4, nil, nil, MobjState::Fatshot2, 0, 0),                                                        # State.Fatshot1
      MobjStateDef.new(358, Sprite::MANF, 32769, 4, nil, nil, MobjState::Fatshot1, 0, 0),                                                        # State.Fatshot2
      MobjStateDef.new(359, Sprite::MISL, 32769, 8, nil, nil, MobjState::Fatshotx2, 0, 0),                                                       # State.Fatshotx1
      MobjStateDef.new(360, Sprite::MISL, 32770, 6, nil, nil, MobjState::Fatshotx3, 0, 0),                                                       # State.Fatshotx2
      MobjStateDef.new(361, Sprite::MISL, 32771, 4, nil, nil, MobjState::Nil, 0, 0),                                                             # State.Fatshotx3
      MobjStateDef.new(362, Sprite::FATT, 0, 15, nil, ->MobjActions.look(World, Mobj), MobjState::FattStnd2, 0, 0),                              # State.FattStnd
      MobjStateDef.new(363, Sprite::FATT, 1, 15, nil, ->MobjActions.look(World, Mobj), MobjState::FattStnd, 0, 0),                               # State.FattStnd2
      MobjStateDef.new(364, Sprite::FATT, 0, 4, nil, ->MobjActions.chase(World, Mobj), MobjState::FattRun2, 0, 0),                               # State.FattRun1
      MobjStateDef.new(365, Sprite::FATT, 0, 4, nil, ->MobjActions.chase(World, Mobj), MobjState::FattRun3, 0, 0),                               # State.FattRun2
      MobjStateDef.new(366, Sprite::FATT, 1, 4, nil, ->MobjActions.chase(World, Mobj), MobjState::FattRun4, 0, 0),                               # State.FattRun3
      MobjStateDef.new(367, Sprite::FATT, 1, 4, nil, ->MobjActions.chase(World, Mobj), MobjState::FattRun5, 0, 0),                               # State.FattRun4
      MobjStateDef.new(368, Sprite::FATT, 2, 4, nil, ->MobjActions.chase(World, Mobj), MobjState::FattRun6, 0, 0),                               # State.FattRun5
      MobjStateDef.new(369, Sprite::FATT, 2, 4, nil, ->MobjActions.chase(World, Mobj), MobjState::FattRun7, 0, 0),                               # State.FattRun6
      MobjStateDef.new(370, Sprite::FATT, 3, 4, nil, ->MobjActions.chase(World, Mobj), MobjState::FattRun8, 0, 0),                               # State.FattRun7
      MobjStateDef.new(371, Sprite::FATT, 3, 4, nil, ->MobjActions.chase(World, Mobj), MobjState::FattRun9, 0, 0),                               # State.FattRun8
      MobjStateDef.new(372, Sprite::FATT, 4, 4, nil, ->MobjActions.chase(World, Mobj), MobjState::FattRun10, 0, 0),                              # State.FattRun9
      MobjStateDef.new(373, Sprite::FATT, 4, 4, nil, ->MobjActions.chase(World, Mobj), MobjState::FattRun11, 0, 0),                              # State.FattRun10
      MobjStateDef.new(374, Sprite::FATT, 5, 4, nil, ->MobjActions.chase(World, Mobj), MobjState::FattRun12, 0, 0),                              # State.FattRun11
      MobjStateDef.new(375, Sprite::FATT, 5, 4, nil, ->MobjActions.chase(World, Mobj), MobjState::FattRun1, 0, 0),                               # State.FattRun12
      MobjStateDef.new(376, Sprite::FATT, 6, 20, nil, ->MobjActions.fat_raise(World, Mobj), MobjState::FattAtk2, 0, 0),                          # State.FattAtk1
      MobjStateDef.new(377, Sprite::FATT, 32775, 10, nil, ->MobjActions.fat_attack1(World, Mobj), MobjState::FattAtk3, 0, 0),                    # State.FattAtk2
      MobjStateDef.new(378, Sprite::FATT, 8, 5, nil, ->MobjActions.face_target(World, Mobj), MobjState::FattAtk4, 0, 0),                         # State.FattAtk3
      MobjStateDef.new(379, Sprite::FATT, 6, 5, nil, ->MobjActions.face_target(World, Mobj), MobjState::FattAtk5, 0, 0),                         # State.FattAtk4
      MobjStateDef.new(380, Sprite::FATT, 32775, 10, nil, ->MobjActions.fat_attack2(World, Mobj), MobjState::FattAtk6, 0, 0),                    # State.FattAtk5
      MobjStateDef.new(381, Sprite::FATT, 8, 5, nil, ->MobjActions.face_target(World, Mobj), MobjState::FattAtk7, 0, 0),                         # State.FattAtk6
      MobjStateDef.new(382, Sprite::FATT, 6, 5, nil, ->MobjActions.face_target(World, Mobj), MobjState::FattAtk8, 0, 0),                         # State.FattAtk7
      MobjStateDef.new(383, Sprite::FATT, 32775, 10, nil, ->MobjActions.fat_attack3(World, Mobj), MobjState::FattAtk9, 0, 0),                    # State.FattAtk8
      MobjStateDef.new(384, Sprite::FATT, 8, 5, nil, ->MobjActions.face_target(World, Mobj), MobjState::FattAtk10, 0, 0),                        # State.FattAtk9
      MobjStateDef.new(385, Sprite::FATT, 6, 5, nil, ->MobjActions.face_target(World, Mobj), MobjState::FattRun1, 0, 0),                         # State.FattAtk10
      MobjStateDef.new(386, Sprite::FATT, 9, 3, nil, nil, MobjState::FattPain2, 0, 0),                                                           # State.FattPain
      MobjStateDef.new(387, Sprite::FATT, 9, 3, nil, ->MobjActions.pain(World, Mobj), MobjState::FattRun1, 0, 0),                                # State.FattPain2
      MobjStateDef.new(388, Sprite::FATT, 10, 6, nil, nil, MobjState::FattDie2, 0, 0),                                                           # State.FattDie1
      MobjStateDef.new(389, Sprite::FATT, 11, 6, nil, ->MobjActions.scream(World, Mobj), MobjState::FattDie3, 0, 0),                             # State.FattDie2
      MobjStateDef.new(390, Sprite::FATT, 12, 6, nil, ->MobjActions.fall(World, Mobj), MobjState::FattDie4, 0, 0),                               # State.FattDie3
      MobjStateDef.new(391, Sprite::FATT, 13, 6, nil, nil, MobjState::FattDie5, 0, 0),                                                           # State.FattDie4
      MobjStateDef.new(392, Sprite::FATT, 14, 6, nil, nil, MobjState::FattDie6, 0, 0),                                                           # State.FattDie5
      MobjStateDef.new(393, Sprite::FATT, 15, 6, nil, nil, MobjState::FattDie7, 0, 0),                                                           # State.FattDie6
      MobjStateDef.new(394, Sprite::FATT, 16, 6, nil, nil, MobjState::FattDie8, 0, 0),                                                           # State.FattDie7
      MobjStateDef.new(395, Sprite::FATT, 17, 6, nil, nil, MobjState::FattDie9, 0, 0),                                                           # State.FattDie8
      MobjStateDef.new(396, Sprite::FATT, 18, 6, nil, nil, MobjState::FattDie10, 0, 0),                                                          # State.FattDie9
      MobjStateDef.new(397, Sprite::FATT, 19, -1, nil, ->MobjActions.boss_death(World, Mobj), MobjState::Nil, 0, 0),                             # State.FattDie10
      MobjStateDef.new(398, Sprite::FATT, 17, 5, nil, nil, MobjState::FattRaise2, 0, 0),                                                         # State.FattRaise1
      MobjStateDef.new(399, Sprite::FATT, 16, 5, nil, nil, MobjState::FattRaise3, 0, 0),                                                         # State.FattRaise2
      MobjStateDef.new(400, Sprite::FATT, 15, 5, nil, nil, MobjState::FattRaise4, 0, 0),                                                         # State.FattRaise3
      MobjStateDef.new(401, Sprite::FATT, 14, 5, nil, nil, MobjState::FattRaise5, 0, 0),                                                         # State.FattRaise4
      MobjStateDef.new(402, Sprite::FATT, 13, 5, nil, nil, MobjState::FattRaise6, 0, 0),                                                         # State.FattRaise5
      MobjStateDef.new(403, Sprite::FATT, 12, 5, nil, nil, MobjState::FattRaise7, 0, 0),                                                         # State.FattRaise6
      MobjStateDef.new(404, Sprite::FATT, 11, 5, nil, nil, MobjState::FattRaise8, 0, 0),                                                         # State.FattRaise7
      MobjStateDef.new(405, Sprite::FATT, 10, 5, nil, nil, MobjState::FattRun1, 0, 0),                                                           # State.FattRaise8
      MobjStateDef.new(406, Sprite::CPOS, 0, 10, nil, ->MobjActions.look(World, Mobj), MobjState::CposStnd2, 0, 0),                              # State.CposStnd
      MobjStateDef.new(407, Sprite::CPOS, 1, 10, nil, ->MobjActions.look(World, Mobj), MobjState::CposStnd, 0, 0),                               # State.CposStnd2
      MobjStateDef.new(408, Sprite::CPOS, 0, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::CposRun2, 0, 0),                               # State.CposRun1
      MobjStateDef.new(409, Sprite::CPOS, 0, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::CposRun3, 0, 0),                               # State.CposRun2
      MobjStateDef.new(410, Sprite::CPOS, 1, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::CposRun4, 0, 0),                               # State.CposRun3
      MobjStateDef.new(411, Sprite::CPOS, 1, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::CposRun5, 0, 0),                               # State.CposRun4
      MobjStateDef.new(412, Sprite::CPOS, 2, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::CposRun6, 0, 0),                               # State.CposRun5
      MobjStateDef.new(413, Sprite::CPOS, 2, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::CposRun7, 0, 0),                               # State.CposRun6
      MobjStateDef.new(414, Sprite::CPOS, 3, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::CposRun8, 0, 0),                               # State.CposRun7
      MobjStateDef.new(415, Sprite::CPOS, 3, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::CposRun1, 0, 0),                               # State.CposRun8
      MobjStateDef.new(416, Sprite::CPOS, 4, 10, nil, ->MobjActions.face_target(World, Mobj), MobjState::CposAtk2, 0, 0),                        # State.CposAtk1
      MobjStateDef.new(417, Sprite::CPOS, 32773, 4, nil, ->MobjActions.cpos_attack(World, Mobj), MobjState::CposAtk3, 0, 0),                     # State.CposAtk2
      MobjStateDef.new(418, Sprite::CPOS, 32772, 4, nil, ->MobjActions.cpos_attack(World, Mobj), MobjState::CposAtk4, 0, 0),                     # State.CposAtk3
      MobjStateDef.new(419, Sprite::CPOS, 5, 1, nil, ->MobjActions.cpos_refire(World, Mobj), MobjState::CposAtk2, 0, 0),                         # State.CposAtk4
      MobjStateDef.new(420, Sprite::CPOS, 6, 3, nil, nil, MobjState::CposPain2, 0, 0),                                                           # State.CposPain
      MobjStateDef.new(421, Sprite::CPOS, 6, 3, nil, ->MobjActions.pain(World, Mobj), MobjState::CposRun1, 0, 0),                                # State.CposPain2
      MobjStateDef.new(422, Sprite::CPOS, 7, 5, nil, nil, MobjState::CposDie2, 0, 0),                                                            # State.CposDie1
      MobjStateDef.new(423, Sprite::CPOS, 8, 5, nil, ->MobjActions.scream(World, Mobj), MobjState::CposDie3, 0, 0),                              # State.CposDie2
      MobjStateDef.new(424, Sprite::CPOS, 9, 5, nil, ->MobjActions.fall(World, Mobj), MobjState::CposDie4, 0, 0),                                # State.CposDie3
      MobjStateDef.new(425, Sprite::CPOS, 10, 5, nil, nil, MobjState::CposDie5, 0, 0),                                                           # State.CposDie4
      MobjStateDef.new(426, Sprite::CPOS, 11, 5, nil, nil, MobjState::CposDie6, 0, 0),                                                           # State.CposDie5
      MobjStateDef.new(427, Sprite::CPOS, 12, 5, nil, nil, MobjState::CposDie7, 0, 0),                                                           # State.CposDie6
      MobjStateDef.new(428, Sprite::CPOS, 13, -1, nil, nil, MobjState::Nil, 0, 0),                                                               # State.CposDie7
      MobjStateDef.new(429, Sprite::CPOS, 14, 5, nil, nil, MobjState::CposXdie2, 0, 0),                                                          # State.CposXdie1
      MobjStateDef.new(430, Sprite::CPOS, 15, 5, nil, ->MobjActions.xscream(World, Mobj), MobjState::CposXdie3, 0, 0),                           # State.CposXdie2
      MobjStateDef.new(431, Sprite::CPOS, 16, 5, nil, ->MobjActions.fall(World, Mobj), MobjState::CposXdie4, 0, 0),                              # State.CposXdie3
      MobjStateDef.new(432, Sprite::CPOS, 17, 5, nil, nil, MobjState::CposXdie5, 0, 0),                                                          # State.CposXdie4
      MobjStateDef.new(433, Sprite::CPOS, 18, 5, nil, nil, MobjState::CposXdie6, 0, 0),                                                          # State.CposXdie5
      MobjStateDef.new(434, Sprite::CPOS, 19, -1, nil, nil, MobjState::Nil, 0, 0),                                                               # State.CposXdie6
      MobjStateDef.new(435, Sprite::CPOS, 13, 5, nil, nil, MobjState::CposRaise2, 0, 0),                                                         # State.CposRaise1
      MobjStateDef.new(436, Sprite::CPOS, 12, 5, nil, nil, MobjState::CposRaise3, 0, 0),                                                         # State.CposRaise2
      MobjStateDef.new(437, Sprite::CPOS, 11, 5, nil, nil, MobjState::CposRaise4, 0, 0),                                                         # State.CposRaise3
      MobjStateDef.new(438, Sprite::CPOS, 10, 5, nil, nil, MobjState::CposRaise5, 0, 0),                                                         # State.CposRaise4
      MobjStateDef.new(439, Sprite::CPOS, 9, 5, nil, nil, MobjState::CposRaise6, 0, 0),                                                          # State.CposRaise5
      MobjStateDef.new(440, Sprite::CPOS, 8, 5, nil, nil, MobjState::CposRaise7, 0, 0),                                                          # State.CposRaise6
      MobjStateDef.new(441, Sprite::CPOS, 7, 5, nil, nil, MobjState::CposRun1, 0, 0),                                                            # State.CposRaise7
      MobjStateDef.new(442, Sprite::TROO, 0, 10, nil, ->MobjActions.look(World, Mobj), MobjState::TrooStnd2, 0, 0),                              # State.TrooStnd
      MobjStateDef.new(443, Sprite::TROO, 1, 10, nil, ->MobjActions.look(World, Mobj), MobjState::TrooStnd, 0, 0),                               # State.TrooStnd2
      MobjStateDef.new(444, Sprite::TROO, 0, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::TrooRun2, 0, 0),                               # State.TrooRun1
      MobjStateDef.new(445, Sprite::TROO, 0, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::TrooRun3, 0, 0),                               # State.TrooRun2
      MobjStateDef.new(446, Sprite::TROO, 1, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::TrooRun4, 0, 0),                               # State.TrooRun3
      MobjStateDef.new(447, Sprite::TROO, 1, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::TrooRun5, 0, 0),                               # State.TrooRun4
      MobjStateDef.new(448, Sprite::TROO, 2, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::TrooRun6, 0, 0),                               # State.TrooRun5
      MobjStateDef.new(449, Sprite::TROO, 2, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::TrooRun7, 0, 0),                               # State.TrooRun6
      MobjStateDef.new(450, Sprite::TROO, 3, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::TrooRun8, 0, 0),                               # State.TrooRun7
      MobjStateDef.new(451, Sprite::TROO, 3, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::TrooRun1, 0, 0),                               # State.TrooRun8
      MobjStateDef.new(452, Sprite::TROO, 4, 8, nil, ->MobjActions.face_target(World, Mobj), MobjState::TrooAtk2, 0, 0),                         # State.TrooAtk1
      MobjStateDef.new(453, Sprite::TROO, 5, 8, nil, ->MobjActions.face_target(World, Mobj), MobjState::TrooAtk3, 0, 0),                         # State.TrooAtk2
      MobjStateDef.new(454, Sprite::TROO, 6, 6, nil, ->MobjActions.troop_attack(World, Mobj), MobjState::TrooRun1, 0, 0),                        # State.TrooAtk3
      MobjStateDef.new(455, Sprite::TROO, 7, 2, nil, nil, MobjState::TrooPain2, 0, 0),                                                           # State.TrooPain
      MobjStateDef.new(456, Sprite::TROO, 7, 2, nil, ->MobjActions.pain(World, Mobj), MobjState::TrooRun1, 0, 0),                                # State.TrooPain2
      MobjStateDef.new(457, Sprite::TROO, 8, 8, nil, nil, MobjState::TrooDie2, 0, 0),                                                            # State.TrooDie1
      MobjStateDef.new(458, Sprite::TROO, 9, 8, nil, ->MobjActions.scream(World, Mobj), MobjState::TrooDie3, 0, 0),                              # State.TrooDie2
      MobjStateDef.new(459, Sprite::TROO, 10, 6, nil, nil, MobjState::TrooDie4, 0, 0),                                                           # State.TrooDie3
      MobjStateDef.new(460, Sprite::TROO, 11, 6, nil, ->MobjActions.fall(World, Mobj), MobjState::TrooDie5, 0, 0),                               # State.TrooDie4
      MobjStateDef.new(461, Sprite::TROO, 12, -1, nil, nil, MobjState::Nil, 0, 0),                                                               # State.TrooDie5
      MobjStateDef.new(462, Sprite::TROO, 13, 5, nil, nil, MobjState::TrooXdie2, 0, 0),                                                          # State.TrooXdie1
      MobjStateDef.new(463, Sprite::TROO, 14, 5, nil, ->MobjActions.xscream(World, Mobj), MobjState::TrooXdie3, 0, 0),                           # State.TrooXdie2
      MobjStateDef.new(464, Sprite::TROO, 15, 5, nil, nil, MobjState::TrooXdie4, 0, 0),                                                          # State.TrooXdie3
      MobjStateDef.new(465, Sprite::TROO, 16, 5, nil, ->MobjActions.fall(World, Mobj), MobjState::TrooXdie5, 0, 0),                              # State.TrooXdie4
      MobjStateDef.new(466, Sprite::TROO, 17, 5, nil, nil, MobjState::TrooXdie6, 0, 0),                                                          # State.TrooXdie5
      MobjStateDef.new(467, Sprite::TROO, 18, 5, nil, nil, MobjState::TrooXdie7, 0, 0),                                                          # State.TrooXdie6
      MobjStateDef.new(468, Sprite::TROO, 19, 5, nil, nil, MobjState::TrooXdie8, 0, 0),                                                          # State.TrooXdie7
      MobjStateDef.new(469, Sprite::TROO, 20, -1, nil, nil, MobjState::Nil, 0, 0),                                                               # State.TrooXdie8
      MobjStateDef.new(470, Sprite::TROO, 12, 8, nil, nil, MobjState::TrooRaise2, 0, 0),                                                         # State.TrooRaise1
      MobjStateDef.new(471, Sprite::TROO, 11, 8, nil, nil, MobjState::TrooRaise3, 0, 0),                                                         # State.TrooRaise2
      MobjStateDef.new(472, Sprite::TROO, 10, 6, nil, nil, MobjState::TrooRaise4, 0, 0),                                                         # State.TrooRaise3
      MobjStateDef.new(473, Sprite::TROO, 9, 6, nil, nil, MobjState::TrooRaise5, 0, 0),                                                          # State.TrooRaise4
      MobjStateDef.new(474, Sprite::TROO, 8, 6, nil, nil, MobjState::TrooRun1, 0, 0),                                                            # State.TrooRaise5
      MobjStateDef.new(475, Sprite::SARG, 0, 10, nil, ->MobjActions.look(World, Mobj), MobjState::SargStnd2, 0, 0),                              # State.SargStnd
      MobjStateDef.new(476, Sprite::SARG, 1, 10, nil, ->MobjActions.look(World, Mobj), MobjState::SargStnd, 0, 0),                               # State.SargStnd2
      MobjStateDef.new(477, Sprite::SARG, 0, 2, nil, ->MobjActions.chase(World, Mobj), MobjState::SargRun2, 0, 0),                               # State.SargRun1
      MobjStateDef.new(478, Sprite::SARG, 0, 2, nil, ->MobjActions.chase(World, Mobj), MobjState::SargRun3, 0, 0),                               # State.SargRun2
      MobjStateDef.new(479, Sprite::SARG, 1, 2, nil, ->MobjActions.chase(World, Mobj), MobjState::SargRun4, 0, 0),                               # State.SargRun3
      MobjStateDef.new(480, Sprite::SARG, 1, 2, nil, ->MobjActions.chase(World, Mobj), MobjState::SargRun5, 0, 0),                               # State.SargRun4
      MobjStateDef.new(481, Sprite::SARG, 2, 2, nil, ->MobjActions.chase(World, Mobj), MobjState::SargRun6, 0, 0),                               # State.SargRun5
      MobjStateDef.new(482, Sprite::SARG, 2, 2, nil, ->MobjActions.chase(World, Mobj), MobjState::SargRun7, 0, 0),                               # State.SargRun6
      MobjStateDef.new(483, Sprite::SARG, 3, 2, nil, ->MobjActions.chase(World, Mobj), MobjState::SargRun8, 0, 0),                               # State.SargRun7
      MobjStateDef.new(484, Sprite::SARG, 3, 2, nil, ->MobjActions.chase(World, Mobj), MobjState::SargRun1, 0, 0),                               # State.SargRun8
      MobjStateDef.new(485, Sprite::SARG, 4, 8, nil, ->MobjActions.face_target(World, Mobj), MobjState::SargAtk2, 0, 0),                         # State.SargAtk1
      MobjStateDef.new(486, Sprite::SARG, 5, 8, nil, ->MobjActions.face_target(World, Mobj), MobjState::SargAtk3, 0, 0),                         # State.SargAtk2
      MobjStateDef.new(487, Sprite::SARG, 6, 8, nil, ->MobjActions.sarg_attack(World, Mobj), MobjState::SargRun1, 0, 0),                         # State.SargAtk3
      MobjStateDef.new(488, Sprite::SARG, 7, 2, nil, nil, MobjState::SargPain2, 0, 0),                                                           # State.SargPain
      MobjStateDef.new(489, Sprite::SARG, 7, 2, nil, ->MobjActions.pain(World, Mobj), MobjState::SargRun1, 0, 0),                                # State.SargPain2
      MobjStateDef.new(490, Sprite::SARG, 8, 8, nil, nil, MobjState::SargDie2, 0, 0),                                                            # State.SargDie1
      MobjStateDef.new(491, Sprite::SARG, 9, 8, nil, ->MobjActions.scream(World, Mobj), MobjState::SargDie3, 0, 0),                              # State.SargDie2
      MobjStateDef.new(492, Sprite::SARG, 10, 4, nil, nil, MobjState::SargDie4, 0, 0),                                                           # State.SargDie3
      MobjStateDef.new(493, Sprite::SARG, 11, 4, nil, ->MobjActions.fall(World, Mobj), MobjState::SargDie5, 0, 0),                               # State.SargDie4
      MobjStateDef.new(494, Sprite::SARG, 12, 4, nil, nil, MobjState::SargDie6, 0, 0),                                                           # State.SargDie5
      MobjStateDef.new(495, Sprite::SARG, 13, -1, nil, nil, MobjState::Nil, 0, 0),                                                               # State.SargDie6
      MobjStateDef.new(496, Sprite::SARG, 13, 5, nil, nil, MobjState::SargRaise2, 0, 0),                                                         # State.SargRaise1
      MobjStateDef.new(497, Sprite::SARG, 12, 5, nil, nil, MobjState::SargRaise3, 0, 0),                                                         # State.SargRaise2
      MobjStateDef.new(498, Sprite::SARG, 11, 5, nil, nil, MobjState::SargRaise4, 0, 0),                                                         # State.SargRaise3
      MobjStateDef.new(499, Sprite::SARG, 10, 5, nil, nil, MobjState::SargRaise5, 0, 0),                                                         # State.SargRaise4
      MobjStateDef.new(500, Sprite::SARG, 9, 5, nil, nil, MobjState::SargRaise6, 0, 0),                                                          # State.SargRaise5
      MobjStateDef.new(501, Sprite::SARG, 8, 5, nil, nil, MobjState::SargRun1, 0, 0),                                                            # State.SargRaise6
      MobjStateDef.new(502, Sprite::HEAD, 0, 10, nil, ->MobjActions.look(World, Mobj), MobjState::HeadStnd, 0, 0),                               # State.HeadStnd
      MobjStateDef.new(503, Sprite::HEAD, 0, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::HeadRun1, 0, 0),                               # State.HeadRun1
      MobjStateDef.new(504, Sprite::HEAD, 1, 5, nil, ->MobjActions.face_target(World, Mobj), MobjState::HeadAtk2, 0, 0),                         # State.HeadAtk1
      MobjStateDef.new(505, Sprite::HEAD, 2, 5, nil, ->MobjActions.face_target(World, Mobj), MobjState::HeadAtk3, 0, 0),                         # State.HeadAtk2
      MobjStateDef.new(506, Sprite::HEAD, 32771, 5, nil, ->MobjActions.head_attack(World, Mobj), MobjState::HeadRun1, 0, 0),                     # State.HeadAtk3
      MobjStateDef.new(507, Sprite::HEAD, 4, 3, nil, nil, MobjState::HeadPain2, 0, 0),                                                           # State.HeadPain
      MobjStateDef.new(508, Sprite::HEAD, 4, 3, nil, ->MobjActions.pain(World, Mobj), MobjState::HeadPain3, 0, 0),                               # State.HeadPain2
      MobjStateDef.new(509, Sprite::HEAD, 5, 6, nil, nil, MobjState::HeadRun1, 0, 0),                                                            # State.HeadPain3
      MobjStateDef.new(510, Sprite::HEAD, 6, 8, nil, nil, MobjState::HeadDie2, 0, 0),                                                            # State.HeadDie1
      MobjStateDef.new(511, Sprite::HEAD, 7, 8, nil, ->MobjActions.scream(World, Mobj), MobjState::HeadDie3, 0, 0),                              # State.HeadDie2
      MobjStateDef.new(512, Sprite::HEAD, 8, 8, nil, nil, MobjState::HeadDie4, 0, 0),                                                            # State.HeadDie3
      MobjStateDef.new(513, Sprite::HEAD, 9, 8, nil, nil, MobjState::HeadDie5, 0, 0),                                                            # State.HeadDie4
      MobjStateDef.new(514, Sprite::HEAD, 10, 8, nil, ->MobjActions.fall(World, Mobj), MobjState::HeadDie6, 0, 0),                               # State.HeadDie5
      MobjStateDef.new(515, Sprite::HEAD, 11, -1, nil, nil, MobjState::Nil, 0, 0),                                                               # State.HeadDie6
      MobjStateDef.new(516, Sprite::HEAD, 11, 8, nil, nil, MobjState::HeadRaise2, 0, 0),                                                         # State.HeadRaise1
      MobjStateDef.new(517, Sprite::HEAD, 10, 8, nil, nil, MobjState::HeadRaise3, 0, 0),                                                         # State.HeadRaise2
      MobjStateDef.new(518, Sprite::HEAD, 9, 8, nil, nil, MobjState::HeadRaise4, 0, 0),                                                          # State.HeadRaise3
      MobjStateDef.new(519, Sprite::HEAD, 8, 8, nil, nil, MobjState::HeadRaise5, 0, 0),                                                          # State.HeadRaise4
      MobjStateDef.new(520, Sprite::HEAD, 7, 8, nil, nil, MobjState::HeadRaise6, 0, 0),                                                          # State.HeadRaise5
      MobjStateDef.new(521, Sprite::HEAD, 6, 8, nil, nil, MobjState::HeadRun1, 0, 0),                                                            # State.HeadRaise6
      MobjStateDef.new(522, Sprite::BAL7, 32768, 4, nil, nil, MobjState::Brball2, 0, 0),                                                         # State.Brball1
      MobjStateDef.new(523, Sprite::BAL7, 32769, 4, nil, nil, MobjState::Brball1, 0, 0),                                                         # State.Brball2
      MobjStateDef.new(524, Sprite::BAL7, 32770, 6, nil, nil, MobjState::Brballx2, 0, 0),                                                        # State.Brballx1
      MobjStateDef.new(525, Sprite::BAL7, 32771, 6, nil, nil, MobjState::Brballx3, 0, 0),                                                        # State.Brballx2
      MobjStateDef.new(526, Sprite::BAL7, 32772, 6, nil, nil, MobjState::Nil, 0, 0),                                                             # State.Brballx3
      MobjStateDef.new(527, Sprite::BOSS, 0, 10, nil, ->MobjActions.look(World, Mobj), MobjState::BossStnd2, 0, 0),                              # State.BossStnd
      MobjStateDef.new(528, Sprite::BOSS, 1, 10, nil, ->MobjActions.look(World, Mobj), MobjState::BossStnd, 0, 0),                               # State.BossStnd2
      MobjStateDef.new(529, Sprite::BOSS, 0, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::BossRun2, 0, 0),                               # State.BossRun1
      MobjStateDef.new(530, Sprite::BOSS, 0, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::BossRun3, 0, 0),                               # State.BossRun2
      MobjStateDef.new(531, Sprite::BOSS, 1, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::BossRun4, 0, 0),                               # State.BossRun3
      MobjStateDef.new(532, Sprite::BOSS, 1, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::BossRun5, 0, 0),                               # State.BossRun4
      MobjStateDef.new(533, Sprite::BOSS, 2, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::BossRun6, 0, 0),                               # State.BossRun5
      MobjStateDef.new(534, Sprite::BOSS, 2, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::BossRun7, 0, 0),                               # State.BossRun6
      MobjStateDef.new(535, Sprite::BOSS, 3, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::BossRun8, 0, 0),                               # State.BossRun7
      MobjStateDef.new(536, Sprite::BOSS, 3, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::BossRun1, 0, 0),                               # State.BossRun8
      MobjStateDef.new(537, Sprite::BOSS, 4, 8, nil, ->MobjActions.face_target(World, Mobj), MobjState::BossAtk2, 0, 0),                         # State.BossAtk1
      MobjStateDef.new(538, Sprite::BOSS, 5, 8, nil, ->MobjActions.face_target(World, Mobj), MobjState::BossAtk3, 0, 0),                         # State.BossAtk2
      MobjStateDef.new(539, Sprite::BOSS, 6, 8, nil, ->MobjActions.bruis_attack(World, Mobj), MobjState::BossRun1, 0, 0),                        # State.BossAtk3
      MobjStateDef.new(540, Sprite::BOSS, 7, 2, nil, nil, MobjState::BossPain2, 0, 0),                                                           # State.BossPain
      MobjStateDef.new(541, Sprite::BOSS, 7, 2, nil, ->MobjActions.pain(World, Mobj), MobjState::BossRun1, 0, 0),                                # State.BossPain2
      MobjStateDef.new(542, Sprite::BOSS, 8, 8, nil, nil, MobjState::BossDie2, 0, 0),                                                            # State.BossDie1
      MobjStateDef.new(543, Sprite::BOSS, 9, 8, nil, ->MobjActions.scream(World, Mobj), MobjState::BossDie3, 0, 0),                              # State.BossDie2
      MobjStateDef.new(544, Sprite::BOSS, 10, 8, nil, nil, MobjState::BossDie4, 0, 0),                                                           # State.BossDie3
      MobjStateDef.new(545, Sprite::BOSS, 11, 8, nil, ->MobjActions.fall(World, Mobj), MobjState::BossDie5, 0, 0),                               # State.BossDie4
      MobjStateDef.new(546, Sprite::BOSS, 12, 8, nil, nil, MobjState::BossDie6, 0, 0),                                                           # State.BossDie5
      MobjStateDef.new(547, Sprite::BOSS, 13, 8, nil, nil, MobjState::BossDie7, 0, 0),                                                           # State.BossDie6
      MobjStateDef.new(548, Sprite::BOSS, 14, -1, nil, ->MobjActions.boss_death(World, Mobj), MobjState::Nil, 0, 0),                             # State.BossDie7
      MobjStateDef.new(549, Sprite::BOSS, 14, 8, nil, nil, MobjState::BossRaise2, 0, 0),                                                         # State.BossRaise1
      MobjStateDef.new(550, Sprite::BOSS, 13, 8, nil, nil, MobjState::BossRaise3, 0, 0),                                                         # State.BossRaise2
      MobjStateDef.new(551, Sprite::BOSS, 12, 8, nil, nil, MobjState::BossRaise4, 0, 0),                                                         # State.BossRaise3
      MobjStateDef.new(552, Sprite::BOSS, 11, 8, nil, nil, MobjState::BossRaise5, 0, 0),                                                         # State.BossRaise4
      MobjStateDef.new(553, Sprite::BOSS, 10, 8, nil, nil, MobjState::BossRaise6, 0, 0),                                                         # State.BossRaise5
      MobjStateDef.new(554, Sprite::BOSS, 9, 8, nil, nil, MobjState::BossRaise7, 0, 0),                                                          # State.BossRaise6
      MobjStateDef.new(555, Sprite::BOSS, 8, 8, nil, nil, MobjState::BossRun1, 0, 0),                                                            # State.BossRaise7
      MobjStateDef.new(556, Sprite::BOS2, 0, 10, nil, ->MobjActions.look(World, Mobj), MobjState::Bos2Stnd2, 0, 0),                              # State.Bos2Stnd
      MobjStateDef.new(557, Sprite::BOS2, 1, 10, nil, ->MobjActions.look(World, Mobj), MobjState::Bos2Stnd, 0, 0),                               # State.Bos2Stnd2
      MobjStateDef.new(558, Sprite::BOS2, 0, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::Bos2Run2, 0, 0),                               # State.Bos2Run1
      MobjStateDef.new(559, Sprite::BOS2, 0, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::Bos2Run3, 0, 0),                               # State.Bos2Run2
      MobjStateDef.new(560, Sprite::BOS2, 1, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::Bos2Run4, 0, 0),                               # State.Bos2Run3
      MobjStateDef.new(561, Sprite::BOS2, 1, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::Bos2Run5, 0, 0),                               # State.Bos2Run4
      MobjStateDef.new(562, Sprite::BOS2, 2, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::Bos2Run6, 0, 0),                               # State.Bos2Run5
      MobjStateDef.new(563, Sprite::BOS2, 2, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::Bos2Run7, 0, 0),                               # State.Bos2Run6
      MobjStateDef.new(564, Sprite::BOS2, 3, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::Bos2Run8, 0, 0),                               # State.Bos2Run7
      MobjStateDef.new(565, Sprite::BOS2, 3, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::Bos2Run1, 0, 0),                               # State.Bos2Run8
      MobjStateDef.new(566, Sprite::BOS2, 4, 8, nil, ->MobjActions.face_target(World, Mobj), MobjState::Bos2Atk2, 0, 0),                         # State.Bos2Atk1
      MobjStateDef.new(567, Sprite::BOS2, 5, 8, nil, ->MobjActions.face_target(World, Mobj), MobjState::Bos2Atk3, 0, 0),                         # State.Bos2Atk2
      MobjStateDef.new(568, Sprite::BOS2, 6, 8, nil, ->MobjActions.bruis_attack(World, Mobj), MobjState::Bos2Run1, 0, 0),                        # State.Bos2Atk3
      MobjStateDef.new(569, Sprite::BOS2, 7, 2, nil, nil, MobjState::Bos2Pain2, 0, 0),                                                           # State.Bos2Pain
      MobjStateDef.new(570, Sprite::BOS2, 7, 2, nil, ->MobjActions.pain(World, Mobj), MobjState::Bos2Run1, 0, 0),                                # State.Bos2Pain2
      MobjStateDef.new(571, Sprite::BOS2, 8, 8, nil, nil, MobjState::Bos2Die2, 0, 0),                                                            # State.Bos2Die1
      MobjStateDef.new(572, Sprite::BOS2, 9, 8, nil, ->MobjActions.scream(World, Mobj), MobjState::Bos2Die3, 0, 0),                              # State.Bos2Die2
      MobjStateDef.new(573, Sprite::BOS2, 10, 8, nil, nil, MobjState::Bos2Die4, 0, 0),                                                           # State.Bos2Die3
      MobjStateDef.new(574, Sprite::BOS2, 11, 8, nil, ->MobjActions.fall(World, Mobj), MobjState::Bos2Die5, 0, 0),                               # State.Bos2Die4
      MobjStateDef.new(575, Sprite::BOS2, 12, 8, nil, nil, MobjState::Bos2Die6, 0, 0),                                                           # State.Bos2Die5
      MobjStateDef.new(576, Sprite::BOS2, 13, 8, nil, nil, MobjState::Bos2Die7, 0, 0),                                                           # State.Bos2Die6
      MobjStateDef.new(577, Sprite::BOS2, 14, -1, nil, nil, MobjState::Nil, 0, 0),                                                               # State.Bos2Die7
      MobjStateDef.new(578, Sprite::BOS2, 14, 8, nil, nil, MobjState::Bos2Raise2, 0, 0),                                                         # State.Bos2Raise1
      MobjStateDef.new(579, Sprite::BOS2, 13, 8, nil, nil, MobjState::Bos2Raise3, 0, 0),                                                         # State.Bos2Raise2
      MobjStateDef.new(580, Sprite::BOS2, 12, 8, nil, nil, MobjState::Bos2Raise4, 0, 0),                                                         # State.Bos2Raise3
      MobjStateDef.new(581, Sprite::BOS2, 11, 8, nil, nil, MobjState::Bos2Raise5, 0, 0),                                                         # State.Bos2Raise4
      MobjStateDef.new(582, Sprite::BOS2, 10, 8, nil, nil, MobjState::Bos2Raise6, 0, 0),                                                         # State.Bos2Raise5
      MobjStateDef.new(583, Sprite::BOS2, 9, 8, nil, nil, MobjState::Bos2Raise7, 0, 0),                                                          # State.Bos2Raise6
      MobjStateDef.new(584, Sprite::BOS2, 8, 8, nil, nil, MobjState::Bos2Run1, 0, 0),                                                            # State.Bos2Raise7
      MobjStateDef.new(585, Sprite::SKUL, 32768, 10, nil, ->MobjActions.look(World, Mobj), MobjState::SkullStnd2, 0, 0),                         # State.SkullStnd
      MobjStateDef.new(586, Sprite::SKUL, 32769, 10, nil, ->MobjActions.look(World, Mobj), MobjState::SkullStnd, 0, 0),                          # State.SkullStnd2
      MobjStateDef.new(587, Sprite::SKUL, 32768, 6, nil, ->MobjActions.chase(World, Mobj), MobjState::SkullRun2, 0, 0),                          # State.SkullRun1
      MobjStateDef.new(588, Sprite::SKUL, 32769, 6, nil, ->MobjActions.chase(World, Mobj), MobjState::SkullRun1, 0, 0),                          # State.SkullRun2
      MobjStateDef.new(589, Sprite::SKUL, 32770, 10, nil, ->MobjActions.face_target(World, Mobj), MobjState::SkullAtk2, 0, 0),                   # State.SkullAtk1
      MobjStateDef.new(590, Sprite::SKUL, 32771, 4, nil, ->MobjActions.skull_attack(World, Mobj), MobjState::SkullAtk3, 0, 0),                   # State.SkullAtk2
      MobjStateDef.new(591, Sprite::SKUL, 32770, 4, nil, nil, MobjState::SkullAtk4, 0, 0),                                                       # State.SkullAtk3
      MobjStateDef.new(592, Sprite::SKUL, 32771, 4, nil, nil, MobjState::SkullAtk3, 0, 0),                                                       # State.SkullAtk4
      MobjStateDef.new(593, Sprite::SKUL, 32772, 3, nil, nil, MobjState::SkullPain2, 0, 0),                                                      # State.SkullPain
      MobjStateDef.new(594, Sprite::SKUL, 32772, 3, nil, ->MobjActions.pain(World, Mobj), MobjState::SkullRun1, 0, 0),                           # State.SkullPain2
      MobjStateDef.new(595, Sprite::SKUL, 32773, 6, nil, nil, MobjState::SkullDie2, 0, 0),                                                       # State.SkullDie1
      MobjStateDef.new(596, Sprite::SKUL, 32774, 6, nil, ->MobjActions.scream(World, Mobj), MobjState::SkullDie3, 0, 0),                         # State.SkullDie2
      MobjStateDef.new(597, Sprite::SKUL, 32775, 6, nil, nil, MobjState::SkullDie4, 0, 0),                                                       # State.SkullDie3
      MobjStateDef.new(598, Sprite::SKUL, 32776, 6, nil, ->MobjActions.fall(World, Mobj), MobjState::SkullDie5, 0, 0),                           # State.SkullDie4
      MobjStateDef.new(599, Sprite::SKUL, 9, 6, nil, nil, MobjState::SkullDie6, 0, 0),                                                           # State.SkullDie5
      MobjStateDef.new(600, Sprite::SKUL, 10, 6, nil, nil, MobjState::Nil, 0, 0),                                                                # State.SkullDie6
      MobjStateDef.new(601, Sprite::SPID, 0, 10, nil, ->MobjActions.look(World, Mobj), MobjState::SpidStnd2, 0, 0),                              # State.SpidStnd
      MobjStateDef.new(602, Sprite::SPID, 1, 10, nil, ->MobjActions.look(World, Mobj), MobjState::SpidStnd, 0, 0),                               # State.SpidStnd2
      MobjStateDef.new(603, Sprite::SPID, 0, 3, nil, ->MobjActions.metal(World, Mobj), MobjState::SpidRun2, 0, 0),                               # State.SpidRun1
      MobjStateDef.new(604, Sprite::SPID, 0, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::SpidRun3, 0, 0),                               # State.SpidRun2
      MobjStateDef.new(605, Sprite::SPID, 1, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::SpidRun4, 0, 0),                               # State.SpidRun3
      MobjStateDef.new(606, Sprite::SPID, 1, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::SpidRun5, 0, 0),                               # State.SpidRun4
      MobjStateDef.new(607, Sprite::SPID, 2, 3, nil, ->MobjActions.metal(World, Mobj), MobjState::SpidRun6, 0, 0),                               # State.SpidRun5
      MobjStateDef.new(608, Sprite::SPID, 2, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::SpidRun7, 0, 0),                               # State.SpidRun6
      MobjStateDef.new(609, Sprite::SPID, 3, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::SpidRun8, 0, 0),                               # State.SpidRun7
      MobjStateDef.new(610, Sprite::SPID, 3, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::SpidRun9, 0, 0),                               # State.SpidRun8
      MobjStateDef.new(611, Sprite::SPID, 4, 3, nil, ->MobjActions.metal(World, Mobj), MobjState::SpidRun10, 0, 0),                              # State.SpidRun9
      MobjStateDef.new(612, Sprite::SPID, 4, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::SpidRun11, 0, 0),                              # State.SpidRun10
      MobjStateDef.new(613, Sprite::SPID, 5, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::SpidRun12, 0, 0),                              # State.SpidRun11
      MobjStateDef.new(614, Sprite::SPID, 5, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::SpidRun1, 0, 0),                               # State.SpidRun12
      MobjStateDef.new(615, Sprite::SPID, 32768, 20, nil, ->MobjActions.face_target(World, Mobj), MobjState::SpidAtk2, 0, 0),                    # State.SpidAtk1
      MobjStateDef.new(616, Sprite::SPID, 32774, 4, nil, ->MobjActions.spos_attack(World, Mobj), MobjState::SpidAtk3, 0, 0),                     # State.SpidAtk2
      MobjStateDef.new(617, Sprite::SPID, 32775, 4, nil, ->MobjActions.spos_attack(World, Mobj), MobjState::SpidAtk4, 0, 0),                     # State.SpidAtk3
      MobjStateDef.new(618, Sprite::SPID, 32775, 1, nil, ->MobjActions.spid_refire(World, Mobj), MobjState::SpidAtk2, 0, 0),                     # State.SpidAtk4
      MobjStateDef.new(619, Sprite::SPID, 8, 3, nil, nil, MobjState::SpidPain2, 0, 0),                                                           # State.SpidPain
      MobjStateDef.new(620, Sprite::SPID, 8, 3, nil, ->MobjActions.pain(World, Mobj), MobjState::SpidRun1, 0, 0),                                # State.SpidPain2
      MobjStateDef.new(621, Sprite::SPID, 9, 20, nil, ->MobjActions.scream(World, Mobj), MobjState::SpidDie2, 0, 0),                             # State.SpidDie1
      MobjStateDef.new(622, Sprite::SPID, 10, 10, nil, ->MobjActions.fall(World, Mobj), MobjState::SpidDie3, 0, 0),                              # State.SpidDie2
      MobjStateDef.new(623, Sprite::SPID, 11, 10, nil, nil, MobjState::SpidDie4, 0, 0),                                                          # State.SpidDie3
      MobjStateDef.new(624, Sprite::SPID, 12, 10, nil, nil, MobjState::SpidDie5, 0, 0),                                                          # State.SpidDie4
      MobjStateDef.new(625, Sprite::SPID, 13, 10, nil, nil, MobjState::SpidDie6, 0, 0),                                                          # State.SpidDie5
      MobjStateDef.new(626, Sprite::SPID, 14, 10, nil, nil, MobjState::SpidDie7, 0, 0),                                                          # State.SpidDie6
      MobjStateDef.new(627, Sprite::SPID, 15, 10, nil, nil, MobjState::SpidDie8, 0, 0),                                                          # State.SpidDie7
      MobjStateDef.new(628, Sprite::SPID, 16, 10, nil, nil, MobjState::SpidDie9, 0, 0),                                                          # State.SpidDie8
      MobjStateDef.new(629, Sprite::SPID, 17, 10, nil, nil, MobjState::SpidDie10, 0, 0),                                                         # State.SpidDie9
      MobjStateDef.new(630, Sprite::SPID, 18, 30, nil, nil, MobjState::SpidDie11, 0, 0),                                                         # State.SpidDie10
      MobjStateDef.new(631, Sprite::SPID, 18, -1, nil, ->MobjActions.boss_death(World, Mobj), MobjState::Nil, 0, 0),                             # State.SpidDie11
      MobjStateDef.new(632, Sprite::BSPI, 0, 10, nil, ->MobjActions.look(World, Mobj), MobjState::BspiStnd2, 0, 0),                              # State.BspiStnd
      MobjStateDef.new(633, Sprite::BSPI, 1, 10, nil, ->MobjActions.look(World, Mobj), MobjState::BspiStnd, 0, 0),                               # State.BspiStnd2
      MobjStateDef.new(634, Sprite::BSPI, 0, 20, nil, nil, MobjState::BspiRun1, 0, 0),                                                           # State.BspiSight
      MobjStateDef.new(635, Sprite::BSPI, 0, 3, nil, ->MobjActions.baby_metal(World, Mobj), MobjState::BspiRun2, 0, 0),                          # State.BspiRun1
      MobjStateDef.new(636, Sprite::BSPI, 0, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::BspiRun3, 0, 0),                               # State.BspiRun2
      MobjStateDef.new(637, Sprite::BSPI, 1, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::BspiRun4, 0, 0),                               # State.BspiRun3
      MobjStateDef.new(638, Sprite::BSPI, 1, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::BspiRun5, 0, 0),                               # State.BspiRun4
      MobjStateDef.new(639, Sprite::BSPI, 2, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::BspiRun6, 0, 0),                               # State.BspiRun5
      MobjStateDef.new(640, Sprite::BSPI, 2, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::BspiRun7, 0, 0),                               # State.BspiRun6
      MobjStateDef.new(641, Sprite::BSPI, 3, 3, nil, ->MobjActions.baby_metal(World, Mobj), MobjState::BspiRun8, 0, 0),                          # State.BspiRun7
      MobjStateDef.new(642, Sprite::BSPI, 3, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::BspiRun9, 0, 0),                               # State.BspiRun8
      MobjStateDef.new(643, Sprite::BSPI, 4, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::BspiRun10, 0, 0),                              # State.BspiRun9
      MobjStateDef.new(644, Sprite::BSPI, 4, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::BspiRun11, 0, 0),                              # State.BspiRun10
      MobjStateDef.new(645, Sprite::BSPI, 5, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::BspiRun12, 0, 0),                              # State.BspiRun11
      MobjStateDef.new(646, Sprite::BSPI, 5, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::BspiRun1, 0, 0),                               # State.BspiRun12
      MobjStateDef.new(647, Sprite::BSPI, 32768, 20, nil, ->MobjActions.face_target(World, Mobj), MobjState::BspiAtk2, 0, 0),                    # State.BspiAtk1
      MobjStateDef.new(648, Sprite::BSPI, 32774, 4, nil, ->MobjActions.bspi_attack(World, Mobj), MobjState::BspiAtk3, 0, 0),                     # State.BspiAtk2
      MobjStateDef.new(649, Sprite::BSPI, 32775, 4, nil, nil, MobjState::BspiAtk4, 0, 0),                                                        # State.BspiAtk3
      MobjStateDef.new(650, Sprite::BSPI, 32775, 1, nil, ->MobjActions.spid_refire(World, Mobj), MobjState::BspiAtk2, 0, 0),                     # State.BspiAtk4
      MobjStateDef.new(651, Sprite::BSPI, 8, 3, nil, nil, MobjState::BspiPain2, 0, 0),                                                           # State.BspiPain
      MobjStateDef.new(652, Sprite::BSPI, 8, 3, nil, ->MobjActions.pain(World, Mobj), MobjState::BspiRun1, 0, 0),                                # State.BspiPain2
      MobjStateDef.new(653, Sprite::BSPI, 9, 20, nil, ->MobjActions.scream(World, Mobj), MobjState::BspiDie2, 0, 0),                             # State.BspiDie1
      MobjStateDef.new(654, Sprite::BSPI, 10, 7, nil, ->MobjActions.fall(World, Mobj), MobjState::BspiDie3, 0, 0),                               # State.BspiDie2
      MobjStateDef.new(655, Sprite::BSPI, 11, 7, nil, nil, MobjState::BspiDie4, 0, 0),                                                           # State.BspiDie3
      MobjStateDef.new(656, Sprite::BSPI, 12, 7, nil, nil, MobjState::BspiDie5, 0, 0),                                                           # State.BspiDie4
      MobjStateDef.new(657, Sprite::BSPI, 13, 7, nil, nil, MobjState::BspiDie6, 0, 0),                                                           # State.BspiDie5
      MobjStateDef.new(658, Sprite::BSPI, 14, 7, nil, nil, MobjState::BspiDie7, 0, 0),                                                           # State.BspiDie6
      MobjStateDef.new(659, Sprite::BSPI, 15, -1, nil, ->MobjActions.boss_death(World, Mobj), MobjState::Nil, 0, 0),                             # State.BspiDie7
      MobjStateDef.new(660, Sprite::BSPI, 15, 5, nil, nil, MobjState::BspiRaise2, 0, 0),                                                         # State.BspiRaise1
      MobjStateDef.new(661, Sprite::BSPI, 14, 5, nil, nil, MobjState::BspiRaise3, 0, 0),                                                         # State.BspiRaise2
      MobjStateDef.new(662, Sprite::BSPI, 13, 5, nil, nil, MobjState::BspiRaise4, 0, 0),                                                         # State.BspiRaise3
      MobjStateDef.new(663, Sprite::BSPI, 12, 5, nil, nil, MobjState::BspiRaise5, 0, 0),                                                         # State.BspiRaise4
      MobjStateDef.new(664, Sprite::BSPI, 11, 5, nil, nil, MobjState::BspiRaise6, 0, 0),                                                         # State.BspiRaise5
      MobjStateDef.new(665, Sprite::BSPI, 10, 5, nil, nil, MobjState::BspiRaise7, 0, 0),                                                         # State.BspiRaise6
      MobjStateDef.new(666, Sprite::BSPI, 9, 5, nil, nil, MobjState::BspiRun1, 0, 0),                                                            # State.BspiRaise7
      MobjStateDef.new(667, Sprite::APLS, 32768, 5, nil, nil, MobjState::ArachPlaz2, 0, 0),                                                      # State.ArachPlaz
      MobjStateDef.new(668, Sprite::APLS, 32769, 5, nil, nil, MobjState::ArachPlaz, 0, 0),                                                       # State.ArachPlaz2
      MobjStateDef.new(669, Sprite::APBX, 32768, 5, nil, nil, MobjState::ArachPlex2, 0, 0),                                                      # State.ArachPlex
      MobjStateDef.new(670, Sprite::APBX, 32769, 5, nil, nil, MobjState::ArachPlex3, 0, 0),                                                      # State.ArachPlex2
      MobjStateDef.new(671, Sprite::APBX, 32770, 5, nil, nil, MobjState::ArachPlex4, 0, 0),                                                      # State.ArachPlex3
      MobjStateDef.new(672, Sprite::APBX, 32771, 5, nil, nil, MobjState::ArachPlex5, 0, 0),                                                      # State.ArachPlex4
      MobjStateDef.new(673, Sprite::APBX, 32772, 5, nil, nil, MobjState::Nil, 0, 0),                                                             # State.ArachPlex5
      MobjStateDef.new(674, Sprite::CYBR, 0, 10, nil, ->MobjActions.look(World, Mobj), MobjState::CyberStnd2, 0, 0),                             # State.CyberStnd
      MobjStateDef.new(675, Sprite::CYBR, 1, 10, nil, ->MobjActions.look(World, Mobj), MobjState::CyberStnd, 0, 0),                              # State.CyberStnd2
      MobjStateDef.new(676, Sprite::CYBR, 0, 3, nil, ->MobjActions.hoof(World, Mobj), MobjState::CyberRun2, 0, 0),                               # State.CyberRun1
      MobjStateDef.new(677, Sprite::CYBR, 0, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::CyberRun3, 0, 0),                              # State.CyberRun2
      MobjStateDef.new(678, Sprite::CYBR, 1, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::CyberRun4, 0, 0),                              # State.CyberRun3
      MobjStateDef.new(679, Sprite::CYBR, 1, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::CyberRun5, 0, 0),                              # State.CyberRun4
      MobjStateDef.new(680, Sprite::CYBR, 2, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::CyberRun6, 0, 0),                              # State.CyberRun5
      MobjStateDef.new(681, Sprite::CYBR, 2, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::CyberRun7, 0, 0),                              # State.CyberRun6
      MobjStateDef.new(682, Sprite::CYBR, 3, 3, nil, ->MobjActions.metal(World, Mobj), MobjState::CyberRun8, 0, 0),                              # State.CyberRun7
      MobjStateDef.new(683, Sprite::CYBR, 3, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::CyberRun1, 0, 0),                              # State.CyberRun8
      MobjStateDef.new(684, Sprite::CYBR, 4, 6, nil, ->MobjActions.face_target(World, Mobj), MobjState::CyberAtk2, 0, 0),                        # State.CyberAtk1
      MobjStateDef.new(685, Sprite::CYBR, 5, 12, nil, ->MobjActions.cyber_attack(World, Mobj), MobjState::CyberAtk3, 0, 0),                      # State.CyberAtk2
      MobjStateDef.new(686, Sprite::CYBR, 4, 12, nil, ->MobjActions.face_target(World, Mobj), MobjState::CyberAtk4, 0, 0),                       # State.CyberAtk3
      MobjStateDef.new(687, Sprite::CYBR, 5, 12, nil, ->MobjActions.cyber_attack(World, Mobj), MobjState::CyberAtk5, 0, 0),                      # State.CyberAtk4
      MobjStateDef.new(688, Sprite::CYBR, 4, 12, nil, ->MobjActions.face_target(World, Mobj), MobjState::CyberAtk6, 0, 0),                       # State.CyberAtk5
      MobjStateDef.new(689, Sprite::CYBR, 5, 12, nil, ->MobjActions.cyber_attack(World, Mobj), MobjState::CyberRun1, 0, 0),                      # State.CyberAtk6
      MobjStateDef.new(690, Sprite::CYBR, 6, 10, nil, ->MobjActions.pain(World, Mobj), MobjState::CyberRun1, 0, 0),                              # State.CyberPain
      MobjStateDef.new(691, Sprite::CYBR, 7, 10, nil, nil, MobjState::CyberDie2, 0, 0),                                                          # State.CyberDie1
      MobjStateDef.new(692, Sprite::CYBR, 8, 10, nil, ->MobjActions.scream(World, Mobj), MobjState::CyberDie3, 0, 0),                            # State.CyberDie2
      MobjStateDef.new(693, Sprite::CYBR, 9, 10, nil, nil, MobjState::CyberDie4, 0, 0),                                                          # State.CyberDie3
      MobjStateDef.new(694, Sprite::CYBR, 10, 10, nil, nil, MobjState::CyberDie5, 0, 0),                                                         # State.CyberDie4
      MobjStateDef.new(695, Sprite::CYBR, 11, 10, nil, nil, MobjState::CyberDie6, 0, 0),                                                         # State.CyberDie5
      MobjStateDef.new(696, Sprite::CYBR, 12, 10, nil, ->MobjActions.fall(World, Mobj), MobjState::CyberDie7, 0, 0),                             # State.CyberDie6
      MobjStateDef.new(697, Sprite::CYBR, 13, 10, nil, nil, MobjState::CyberDie8, 0, 0),                                                         # State.CyberDie7
      MobjStateDef.new(698, Sprite::CYBR, 14, 10, nil, nil, MobjState::CyberDie9, 0, 0),                                                         # State.CyberDie8
      MobjStateDef.new(699, Sprite::CYBR, 15, 30, nil, nil, MobjState::CyberDie10, 0, 0),                                                        # State.CyberDie9
      MobjStateDef.new(700, Sprite::CYBR, 15, -1, nil, ->MobjActions.boss_death(World, Mobj), MobjState::Nil, 0, 0),                             # State.CyberDie10
      MobjStateDef.new(701, Sprite::PAIN, 0, 10, nil, ->MobjActions.look(World, Mobj), MobjState::PainStnd, 0, 0),                               # State.painStnd
      MobjStateDef.new(702, Sprite::PAIN, 0, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::PainRun2, 0, 0),                               # State.painRun1
      MobjStateDef.new(703, Sprite::PAIN, 0, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::PainRun3, 0, 0),                               # State.painRun2
      MobjStateDef.new(704, Sprite::PAIN, 1, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::PainRun4, 0, 0),                               # State.painRun3
      MobjStateDef.new(705, Sprite::PAIN, 1, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::PainRun5, 0, 0),                               # State.painRun4
      MobjStateDef.new(706, Sprite::PAIN, 2, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::PainRun6, 0, 0),                               # State.painRun5
      MobjStateDef.new(707, Sprite::PAIN, 2, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::PainRun1, 0, 0),                               # State.painRun6
      MobjStateDef.new(708, Sprite::PAIN, 3, 5, nil, ->MobjActions.face_target(World, Mobj), MobjState::PainAtk2, 0, 0),                         # State.painAtk1
      MobjStateDef.new(709, Sprite::PAIN, 4, 5, nil, ->MobjActions.face_target(World, Mobj), MobjState::PainAtk3, 0, 0),                         # State.painAtk2
      MobjStateDef.new(710, Sprite::PAIN, 32773, 5, nil, ->MobjActions.face_target(World, Mobj), MobjState::PainAtk4, 0, 0),                     # State.painAtk3
      MobjStateDef.new(711, Sprite::PAIN, 32773, 0, nil, ->MobjActions.pain_attack(World, Mobj), MobjState::PainRun1, 0, 0),                     # State.painAtk4
      MobjStateDef.new(712, Sprite::PAIN, 6, 6, nil, nil, MobjState::PainPain2, 0, 0),                                                           # State.painPain
      MobjStateDef.new(713, Sprite::PAIN, 6, 6, nil, ->MobjActions.pain(World, Mobj), MobjState::PainRun1, 0, 0),                                # State.painPain2
      MobjStateDef.new(714, Sprite::PAIN, 32775, 8, nil, nil, MobjState::PainDie2, 0, 0),                                                        # State.painDie1
      MobjStateDef.new(715, Sprite::PAIN, 32776, 8, nil, ->MobjActions.scream(World, Mobj), MobjState::PainDie3, 0, 0),                          # State.painDie2
      MobjStateDef.new(716, Sprite::PAIN, 32777, 8, nil, nil, MobjState::PainDie4, 0, 0),                                                        # State.painDie3
      MobjStateDef.new(717, Sprite::PAIN, 32778, 8, nil, nil, MobjState::PainDie5, 0, 0),                                                        # State.painDie4
      MobjStateDef.new(718, Sprite::PAIN, 32779, 8, nil, ->MobjActions.pain_die(World, Mobj), MobjState::PainDie6, 0, 0),                        # State.painDie5
      MobjStateDef.new(719, Sprite::PAIN, 32780, 8, nil, nil, MobjState::Nil, 0, 0),                                                             # State.painDie6
      MobjStateDef.new(720, Sprite::PAIN, 12, 8, nil, nil, MobjState::PainRaise2, 0, 0),                                                         # State.painRaise1
      MobjStateDef.new(721, Sprite::PAIN, 11, 8, nil, nil, MobjState::PainRaise3, 0, 0),                                                         # State.painRaise2
      MobjStateDef.new(722, Sprite::PAIN, 10, 8, nil, nil, MobjState::PainRaise4, 0, 0),                                                         # State.painRaise3
      MobjStateDef.new(723, Sprite::PAIN, 9, 8, nil, nil, MobjState::PainRaise5, 0, 0),                                                          # State.painRaise4
      MobjStateDef.new(724, Sprite::PAIN, 8, 8, nil, nil, MobjState::PainRaise6, 0, 0),                                                          # State.painRaise5
      MobjStateDef.new(725, Sprite::PAIN, 7, 8, nil, nil, MobjState::PainRun1, 0, 0),                                                            # State.painRaise6
      MobjStateDef.new(726, Sprite::SSWV, 0, 10, nil, ->MobjActions.look(World, Mobj), MobjState::SswvStnd2, 0, 0),                              # State.SswvStnd
      MobjStateDef.new(727, Sprite::SSWV, 1, 10, nil, ->MobjActions.look(World, Mobj), MobjState::SswvStnd, 0, 0),                               # State.SswvStnd2
      MobjStateDef.new(728, Sprite::SSWV, 0, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::SswvRun2, 0, 0),                               # State.SswvRun1
      MobjStateDef.new(729, Sprite::SSWV, 0, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::SswvRun3, 0, 0),                               # State.SswvRun2
      MobjStateDef.new(730, Sprite::SSWV, 1, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::SswvRun4, 0, 0),                               # State.SswvRun3
      MobjStateDef.new(731, Sprite::SSWV, 1, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::SswvRun5, 0, 0),                               # State.SswvRun4
      MobjStateDef.new(732, Sprite::SSWV, 2, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::SswvRun6, 0, 0),                               # State.SswvRun5
      MobjStateDef.new(733, Sprite::SSWV, 2, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::SswvRun7, 0, 0),                               # State.SswvRun6
      MobjStateDef.new(734, Sprite::SSWV, 3, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::SswvRun8, 0, 0),                               # State.SswvRun7
      MobjStateDef.new(735, Sprite::SSWV, 3, 3, nil, ->MobjActions.chase(World, Mobj), MobjState::SswvRun1, 0, 0),                               # State.SswvRun8
      MobjStateDef.new(736, Sprite::SSWV, 4, 10, nil, ->MobjActions.face_target(World, Mobj), MobjState::SswvAtk2, 0, 0),                        # State.SswvAtk1
      MobjStateDef.new(737, Sprite::SSWV, 5, 10, nil, ->MobjActions.face_target(World, Mobj), MobjState::SswvAtk3, 0, 0),                        # State.SswvAtk2
      MobjStateDef.new(738, Sprite::SSWV, 32774, 4, nil, ->MobjActions.cpos_attack(World, Mobj), MobjState::SswvAtk4, 0, 0),                     # State.SswvAtk3
      MobjStateDef.new(739, Sprite::SSWV, 5, 6, nil, ->MobjActions.face_target(World, Mobj), MobjState::SswvAtk5, 0, 0),                         # State.SswvAtk4
      MobjStateDef.new(740, Sprite::SSWV, 32774, 4, nil, ->MobjActions.cpos_attack(World, Mobj), MobjState::SswvAtk6, 0, 0),                     # State.SswvAtk5
      MobjStateDef.new(741, Sprite::SSWV, 5, 1, nil, ->MobjActions.cpos_refire(World, Mobj), MobjState::SswvAtk2, 0, 0),                         # State.SswvAtk6
      MobjStateDef.new(742, Sprite::SSWV, 7, 3, nil, nil, MobjState::SswvPain2, 0, 0),                                                           # State.SswvPain
      MobjStateDef.new(743, Sprite::SSWV, 7, 3, nil, ->MobjActions.pain(World, Mobj), MobjState::SswvRun1, 0, 0),                                # State.SswvPain2
      MobjStateDef.new(744, Sprite::SSWV, 8, 5, nil, nil, MobjState::SswvDie2, 0, 0),                                                            # State.SswvDie1
      MobjStateDef.new(745, Sprite::SSWV, 9, 5, nil, ->MobjActions.scream(World, Mobj), MobjState::SswvDie3, 0, 0),                              # State.SswvDie2
      MobjStateDef.new(746, Sprite::SSWV, 10, 5, nil, ->MobjActions.fall(World, Mobj), MobjState::SswvDie4, 0, 0),                               # State.SswvDie3
      MobjStateDef.new(747, Sprite::SSWV, 11, 5, nil, nil, MobjState::SswvDie5, 0, 0),                                                           # State.SswvDie4
      MobjStateDef.new(748, Sprite::SSWV, 12, -1, nil, nil, MobjState::Nil, 0, 0),                                                               # State.SswvDie5
      MobjStateDef.new(749, Sprite::SSWV, 13, 5, nil, nil, MobjState::SswvXdie2, 0, 0),                                                          # State.SswvXdie1
      MobjStateDef.new(750, Sprite::SSWV, 14, 5, nil, ->MobjActions.xscream(World, Mobj), MobjState::SswvXdie3, 0, 0),                           # State.SswvXdie2
      MobjStateDef.new(751, Sprite::SSWV, 15, 5, nil, ->MobjActions.fall(World, Mobj), MobjState::SswvXdie4, 0, 0),                              # State.SswvXdie3
      MobjStateDef.new(752, Sprite::SSWV, 16, 5, nil, nil, MobjState::SswvXdie5, 0, 0),                                                          # State.SswvXdie4
      MobjStateDef.new(753, Sprite::SSWV, 17, 5, nil, nil, MobjState::SswvXdie6, 0, 0),                                                          # State.SswvXdie5
      MobjStateDef.new(754, Sprite::SSWV, 18, 5, nil, nil, MobjState::SswvXdie7, 0, 0),                                                          # State.SswvXdie6
      MobjStateDef.new(755, Sprite::SSWV, 19, 5, nil, nil, MobjState::SswvXdie8, 0, 0),                                                          # State.SswvXdie7
      MobjStateDef.new(756, Sprite::SSWV, 20, 5, nil, nil, MobjState::SswvXdie9, 0, 0),                                                          # State.SswvXdie8
      MobjStateDef.new(757, Sprite::SSWV, 21, -1, nil, nil, MobjState::Nil, 0, 0),                                                               # State.SswvXdie9
      MobjStateDef.new(758, Sprite::SSWV, 12, 5, nil, nil, MobjState::SswvRaise2, 0, 0),                                                         # State.SswvRaise1
      MobjStateDef.new(759, Sprite::SSWV, 11, 5, nil, nil, MobjState::SswvRaise3, 0, 0),                                                         # State.SswvRaise2
      MobjStateDef.new(760, Sprite::SSWV, 10, 5, nil, nil, MobjState::SswvRaise4, 0, 0),                                                         # State.SswvRaise3
      MobjStateDef.new(761, Sprite::SSWV, 9, 5, nil, nil, MobjState::SswvRaise5, 0, 0),                                                          # State.SswvRaise4
      MobjStateDef.new(762, Sprite::SSWV, 8, 5, nil, nil, MobjState::SswvRun1, 0, 0),                                                            # State.SswvRaise5
      MobjStateDef.new(763, Sprite::KEEN, 0, -1, nil, nil, MobjState::Keenstnd, 0, 0),                                                           # State.Keenstnd
      MobjStateDef.new(764, Sprite::KEEN, 0, 6, nil, nil, MobjState::Commkeen2, 0, 0),                                                           # State.Commkeen
      MobjStateDef.new(765, Sprite::KEEN, 1, 6, nil, nil, MobjState::Commkeen3, 0, 0),                                                           # State.Commkeen2
      MobjStateDef.new(766, Sprite::KEEN, 2, 6, nil, ->MobjActions.scream(World, Mobj), MobjState::Commkeen4, 0, 0),                             # State.Commkeen3
      MobjStateDef.new(767, Sprite::KEEN, 3, 6, nil, nil, MobjState::Commkeen5, 0, 0),                                                           # State.Commkeen4
      MobjStateDef.new(768, Sprite::KEEN, 4, 6, nil, nil, MobjState::Commkeen6, 0, 0),                                                           # State.Commkeen5
      MobjStateDef.new(769, Sprite::KEEN, 5, 6, nil, nil, MobjState::Commkeen7, 0, 0),                                                           # State.Commkeen6
      MobjStateDef.new(770, Sprite::KEEN, 6, 6, nil, nil, MobjState::Commkeen8, 0, 0),                                                           # State.Commkeen7
      MobjStateDef.new(771, Sprite::KEEN, 7, 6, nil, nil, MobjState::Commkeen9, 0, 0),                                                           # State.Commkeen8
      MobjStateDef.new(772, Sprite::KEEN, 8, 6, nil, nil, MobjState::Commkeen10, 0, 0),                                                          # State.Commkeen9
      MobjStateDef.new(773, Sprite::KEEN, 9, 6, nil, nil, MobjState::Commkeen11, 0, 0),                                                          # State.Commkeen10
      MobjStateDef.new(774, Sprite::KEEN, 10, 6, nil, ->MobjActions.keen_die(World, Mobj), MobjState::Commkeen12, 0, 0),                         # State.Commkeen11
      MobjStateDef.new(775, Sprite::KEEN, 11, -1, nil, nil, MobjState::Nil, 0, 0),                                                               # State.Commkeen12
      MobjStateDef.new(776, Sprite::KEEN, 12, 4, nil, nil, MobjState::Keenpain2, 0, 0),                                                          # State.Keenpain
      MobjStateDef.new(777, Sprite::KEEN, 12, 8, nil, ->MobjActions.pain(World, Mobj), MobjState::Keenstnd, 0, 0),                               # State.Keenpain2
      MobjStateDef.new(778, Sprite::BBRN, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Brain
      MobjStateDef.new(779, Sprite::BBRN, 1, 36, nil, ->MobjActions.brain_pain(World, Mobj), MobjState::Brain, 0, 0),                            # State.brain_pain
      MobjStateDef.new(780, Sprite::BBRN, 0, 100, nil, ->MobjActions.brain_scream(World, Mobj), MobjState::BrainDie2, 0, 0),                     # State.BrainDie1
      MobjStateDef.new(781, Sprite::BBRN, 0, 10, nil, nil, MobjState::BrainDie3, 0, 0),                                                          # State.BrainDie2
      MobjStateDef.new(782, Sprite::BBRN, 0, 10, nil, nil, MobjState::BrainDie4, 0, 0),                                                          # State.BrainDie3
      MobjStateDef.new(783, Sprite::BBRN, 0, -1, nil, ->MobjActions.brain_die(World, Mobj), MobjState::Nil, 0, 0),                               # State.BrainDie4
      MobjStateDef.new(784, Sprite::SSWV, 0, 10, nil, ->MobjActions.look(World, Mobj), MobjState::Braineye, 0, 0),                               # State.Braineye
      MobjStateDef.new(785, Sprite::SSWV, 0, 181, nil, ->MobjActions.brain_awake(World, Mobj), MobjState::Braineye1, 0, 0),                      # State.Braineyesee
      MobjStateDef.new(786, Sprite::SSWV, 0, 150, nil, ->MobjActions.brain_spit(World, Mobj), MobjState::Braineye1, 0, 0),                       # State.Braineye1
      MobjStateDef.new(787, Sprite::BOSF, 32768, 3, nil, ->MobjActions.spawn_sound(World, Mobj), MobjState::Spawn2, 0, 0),                       # State.Spawn1
      MobjStateDef.new(788, Sprite::BOSF, 32769, 3, nil, ->MobjActions.spawn_fly(World, Mobj), MobjState::Spawn3, 0, 0),                         # State.Spawn2
      MobjStateDef.new(789, Sprite::BOSF, 32770, 3, nil, ->MobjActions.spawn_fly(World, Mobj), MobjState::Spawn4, 0, 0),                         # State.Spawn3
      MobjStateDef.new(790, Sprite::BOSF, 32771, 3, nil, ->MobjActions.spawn_fly(World, Mobj), MobjState::Spawn1, 0, 0),                         # State.Spawn4
      MobjStateDef.new(791, Sprite::FIRE, 32768, 4, nil, ->MobjActions.fire(World, Mobj), MobjState::Spawnfire2, 0, 0),                          # State.Spawnfire1
      MobjStateDef.new(792, Sprite::FIRE, 32769, 4, nil, ->MobjActions.fire(World, Mobj), MobjState::Spawnfire3, 0, 0),                          # State.Spawnfire2
      MobjStateDef.new(793, Sprite::FIRE, 32770, 4, nil, ->MobjActions.fire(World, Mobj), MobjState::Spawnfire4, 0, 0),                          # State.Spawnfire3
      MobjStateDef.new(794, Sprite::FIRE, 32771, 4, nil, ->MobjActions.fire(World, Mobj), MobjState::Spawnfire5, 0, 0),                          # State.Spawnfire4
      MobjStateDef.new(795, Sprite::FIRE, 32772, 4, nil, ->MobjActions.fire(World, Mobj), MobjState::Spawnfire6, 0, 0),                          # State.Spawnfire5
      MobjStateDef.new(796, Sprite::FIRE, 32773, 4, nil, ->MobjActions.fire(World, Mobj), MobjState::Spawnfire7, 0, 0),                          # State.Spawnfire6
      MobjStateDef.new(797, Sprite::FIRE, 32774, 4, nil, ->MobjActions.fire(World, Mobj), MobjState::Spawnfire8, 0, 0),                          # State.Spawnfire7
      MobjStateDef.new(798, Sprite::FIRE, 32775, 4, nil, ->MobjActions.fire(World, Mobj), MobjState::Nil, 0, 0),                                 # State.Spawnfire8
      MobjStateDef.new(799, Sprite::MISL, 32769, 10, nil, nil, MobjState::Brainexplode2, 0, 0),                                                  # State.Brainexplode1
      MobjStateDef.new(800, Sprite::MISL, 32770, 10, nil, nil, MobjState::Brainexplode3, 0, 0),                                                  # State.Brainexplode2
      MobjStateDef.new(801, Sprite::MISL, 32771, 10, nil, ->MobjActions.brain_explode(World, Mobj), MobjState::Nil, 0, 0),                       # State.Brainexplode3
      MobjStateDef.new(802, Sprite::ARM1, 0, 6, nil, nil, MobjState::Arm1A, 0, 0),                                                               # State.Arm1
      MobjStateDef.new(803, Sprite::ARM1, 32769, 7, nil, nil, MobjState::Arm1, 0, 0),                                                            # State.Arm1A
      MobjStateDef.new(804, Sprite::ARM2, 0, 6, nil, nil, MobjState::Arm2A, 0, 0),                                                               # State.Arm2
      MobjStateDef.new(805, Sprite::ARM2, 32769, 6, nil, nil, MobjState::Arm2, 0, 0),                                                            # State.Arm2A
      MobjStateDef.new(806, Sprite::BAR1, 0, 6, nil, nil, MobjState::Bar2, 0, 0),                                                                # State.Bar1
      MobjStateDef.new(807, Sprite::BAR1, 1, 6, nil, nil, MobjState::Bar1, 0, 0),                                                                # State.Bar2
      MobjStateDef.new(808, Sprite::BEXP, 32768, 5, nil, nil, MobjState::Bexp2, 0, 0),                                                           # State.Bexp
      MobjStateDef.new(809, Sprite::BEXP, 32769, 5, nil, ->MobjActions.scream(World, Mobj), MobjState::Bexp3, 0, 0),                             # State.Bexp2
      MobjStateDef.new(810, Sprite::BEXP, 32770, 5, nil, nil, MobjState::Bexp4, 0, 0),                                                           # State.Bexp3
      MobjStateDef.new(811, Sprite::BEXP, 32771, 10, nil, ->MobjActions.explode(World, Mobj), MobjState::Bexp5, 0, 0),                           # State.Bexp4
      MobjStateDef.new(812, Sprite::BEXP, 32772, 10, nil, nil, MobjState::Nil, 0, 0),                                                            # State.Bexp5
      MobjStateDef.new(813, Sprite::FCAN, 32768, 4, nil, nil, MobjState::Bbar2, 0, 0),                                                           # State.Bbar1
      MobjStateDef.new(814, Sprite::FCAN, 32769, 4, nil, nil, MobjState::Bbar3, 0, 0),                                                           # State.Bbar2
      MobjStateDef.new(815, Sprite::FCAN, 32770, 4, nil, nil, MobjState::Bbar1, 0, 0),                                                           # State.Bbar3
      MobjStateDef.new(816, Sprite::BON1, 0, 6, nil, nil, MobjState::Bon1A, 0, 0),                                                               # State.Bon1
      MobjStateDef.new(817, Sprite::BON1, 1, 6, nil, nil, MobjState::Bon1B, 0, 0),                                                               # State.Bon1A
      MobjStateDef.new(818, Sprite::BON1, 2, 6, nil, nil, MobjState::Bon1C, 0, 0),                                                               # State.Bon1B
      MobjStateDef.new(819, Sprite::BON1, 3, 6, nil, nil, MobjState::Bon1D, 0, 0),                                                               # State.Bon1C
      MobjStateDef.new(820, Sprite::BON1, 2, 6, nil, nil, MobjState::Bon1E, 0, 0),                                                               # State.Bon1D
      MobjStateDef.new(821, Sprite::BON1, 1, 6, nil, nil, MobjState::Bon1, 0, 0),                                                                # State.Bon1E
      MobjStateDef.new(822, Sprite::BON2, 0, 6, nil, nil, MobjState::Bon2A, 0, 0),                                                               # State.Bon2
      MobjStateDef.new(823, Sprite::BON2, 1, 6, nil, nil, MobjState::Bon2B, 0, 0),                                                               # State.Bon2A
      MobjStateDef.new(824, Sprite::BON2, 2, 6, nil, nil, MobjState::Bon2C, 0, 0),                                                               # State.Bon2B
      MobjStateDef.new(825, Sprite::BON2, 3, 6, nil, nil, MobjState::Bon2D, 0, 0),                                                               # State.Bon2C
      MobjStateDef.new(826, Sprite::BON2, 2, 6, nil, nil, MobjState::Bon2E, 0, 0),                                                               # State.Bon2D
      MobjStateDef.new(827, Sprite::BON2, 1, 6, nil, nil, MobjState::Bon2, 0, 0),                                                                # State.Bon2E
      MobjStateDef.new(828, Sprite::BKEY, 0, 10, nil, nil, MobjState::Bkey2, 0, 0),                                                              # State.Bkey
      MobjStateDef.new(829, Sprite::BKEY, 32769, 10, nil, nil, MobjState::Bkey, 0, 0),                                                           # State.Bkey2
      MobjStateDef.new(830, Sprite::RKEY, 0, 10, nil, nil, MobjState::Rkey2, 0, 0),                                                              # State.Rkey
      MobjStateDef.new(831, Sprite::RKEY, 32769, 10, nil, nil, MobjState::Rkey, 0, 0),                                                           # State.Rkey2
      MobjStateDef.new(832, Sprite::YKEY, 0, 10, nil, nil, MobjState::Ykey2, 0, 0),                                                              # State.Ykey
      MobjStateDef.new(833, Sprite::YKEY, 32769, 10, nil, nil, MobjState::Ykey, 0, 0),                                                           # State.Ykey2
      MobjStateDef.new(834, Sprite::BSKU, 0, 10, nil, nil, MobjState::Bskull2, 0, 0),                                                            # State.Bskull
      MobjStateDef.new(835, Sprite::BSKU, 32769, 10, nil, nil, MobjState::Bskull, 0, 0),                                                         # State.Bskull2
      MobjStateDef.new(836, Sprite::RSKU, 0, 10, nil, nil, MobjState::Rskull2, 0, 0),                                                            # State.Rskull
      MobjStateDef.new(837, Sprite::RSKU, 32769, 10, nil, nil, MobjState::Rskull, 0, 0),                                                         # State.Rskull2
      MobjStateDef.new(838, Sprite::YSKU, 0, 10, nil, nil, MobjState::Yskull2, 0, 0),                                                            # State.Yskull
      MobjStateDef.new(839, Sprite::YSKU, 32769, 10, nil, nil, MobjState::Yskull, 0, 0),                                                         # State.Yskull2
      MobjStateDef.new(840, Sprite::STIM, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Stim
      MobjStateDef.new(841, Sprite::MEDI, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Medi
      MobjStateDef.new(842, Sprite::SOUL, 32768, 6, nil, nil, MobjState::Soul2, 0, 0),                                                           # State.Soul
      MobjStateDef.new(843, Sprite::SOUL, 32769, 6, nil, nil, MobjState::Soul3, 0, 0),                                                           # State.Soul2
      MobjStateDef.new(844, Sprite::SOUL, 32770, 6, nil, nil, MobjState::Soul4, 0, 0),                                                           # State.Soul3
      MobjStateDef.new(845, Sprite::SOUL, 32771, 6, nil, nil, MobjState::Soul5, 0, 0),                                                           # State.Soul4
      MobjStateDef.new(846, Sprite::SOUL, 32770, 6, nil, nil, MobjState::Soul6, 0, 0),                                                           # State.Soul5
      MobjStateDef.new(847, Sprite::SOUL, 32769, 6, nil, nil, MobjState::Soul, 0, 0),                                                            # State.Soul6
      MobjStateDef.new(848, Sprite::PINV, 32768, 6, nil, nil, MobjState::Pinv2, 0, 0),                                                           # State.Pinv
      MobjStateDef.new(849, Sprite::PINV, 32769, 6, nil, nil, MobjState::Pinv3, 0, 0),                                                           # State.Pinv2
      MobjStateDef.new(850, Sprite::PINV, 32770, 6, nil, nil, MobjState::Pinv4, 0, 0),                                                           # State.Pinv3
      MobjStateDef.new(851, Sprite::PINV, 32771, 6, nil, nil, MobjState::Pinv, 0, 0),                                                            # State.Pinv4
      MobjStateDef.new(852, Sprite::PSTR, 32768, -1, nil, nil, MobjState::Nil, 0, 0),                                                            # State.Pstr
      MobjStateDef.new(853, Sprite::PINS, 32768, 6, nil, nil, MobjState::Pins2, 0, 0),                                                           # State.Pins
      MobjStateDef.new(854, Sprite::PINS, 32769, 6, nil, nil, MobjState::Pins3, 0, 0),                                                           # State.Pins2
      MobjStateDef.new(855, Sprite::PINS, 32770, 6, nil, nil, MobjState::Pins4, 0, 0),                                                           # State.Pins3
      MobjStateDef.new(856, Sprite::PINS, 32771, 6, nil, nil, MobjState::Pins, 0, 0),                                                            # State.Pins4
      MobjStateDef.new(857, Sprite::MEGA, 32768, 6, nil, nil, MobjState::Mega2, 0, 0),                                                           # State.Mega
      MobjStateDef.new(858, Sprite::MEGA, 32769, 6, nil, nil, MobjState::Mega3, 0, 0),                                                           # State.Mega2
      MobjStateDef.new(859, Sprite::MEGA, 32770, 6, nil, nil, MobjState::Mega4, 0, 0),                                                           # State.Mega3
      MobjStateDef.new(860, Sprite::MEGA, 32771, 6, nil, nil, MobjState::Mega, 0, 0),                                                            # State.Mega4
      MobjStateDef.new(861, Sprite::SUIT, 32768, -1, nil, nil, MobjState::Nil, 0, 0),                                                            # State.Suit
      MobjStateDef.new(862, Sprite::PMAP, 32768, 6, nil, nil, MobjState::Pmap2, 0, 0),                                                           # State.Pmap
      MobjStateDef.new(863, Sprite::PMAP, 32769, 6, nil, nil, MobjState::Pmap3, 0, 0),                                                           # State.Pmap2
      MobjStateDef.new(864, Sprite::PMAP, 32770, 6, nil, nil, MobjState::Pmap4, 0, 0),                                                           # State.Pmap3
      MobjStateDef.new(865, Sprite::PMAP, 32771, 6, nil, nil, MobjState::Pmap5, 0, 0),                                                           # State.Pmap4
      MobjStateDef.new(866, Sprite::PMAP, 32770, 6, nil, nil, MobjState::Pmap6, 0, 0),                                                           # State.Pmap5
      MobjStateDef.new(867, Sprite::PMAP, 32769, 6, nil, nil, MobjState::Pmap, 0, 0),                                                            # State.Pmap6
      MobjStateDef.new(868, Sprite::PVIS, 32768, 6, nil, nil, MobjState::Pvis2, 0, 0),                                                           # State.Pvis
      MobjStateDef.new(869, Sprite::PVIS, 1, 6, nil, nil, MobjState::Pvis, 0, 0),                                                                # State.Pvis2
      MobjStateDef.new(870, Sprite::CLIP, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Clip
      MobjStateDef.new(871, Sprite::AMMO, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Ammo
      MobjStateDef.new(872, Sprite::ROCK, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Rock
      MobjStateDef.new(873, Sprite::BROK, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Brok
      MobjStateDef.new(874, Sprite::CELL, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Cell
      MobjStateDef.new(875, Sprite::CELP, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Celp
      MobjStateDef.new(876, Sprite::SHEL, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Shel
      MobjStateDef.new(877, Sprite::SBOX, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Sbox
      MobjStateDef.new(878, Sprite::BPAK, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Bpak
      MobjStateDef.new(879, Sprite::BFUG, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Bfug
      MobjStateDef.new(880, Sprite::MGUN, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Mgun
      MobjStateDef.new(881, Sprite::CSAW, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Csaw
      MobjStateDef.new(882, Sprite::LAUN, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Laun
      MobjStateDef.new(883, Sprite::PLAS, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Plas
      MobjStateDef.new(884, Sprite::SHOT, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Shot
      MobjStateDef.new(885, Sprite::SGN2, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Shot2
      MobjStateDef.new(886, Sprite::COLU, 32768, -1, nil, nil, MobjState::Nil, 0, 0),                                                            # State.Colu
      MobjStateDef.new(887, Sprite::SMT2, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Stalag
      MobjStateDef.new(888, Sprite::GOR1, 0, 10, nil, nil, MobjState::Bloodytwitch2, 0, 0),                                                      # State.Bloodytwitch
      MobjStateDef.new(889, Sprite::GOR1, 1, 15, nil, nil, MobjState::Bloodytwitch3, 0, 0),                                                      # State.Bloodytwitch2
      MobjStateDef.new(890, Sprite::GOR1, 2, 8, nil, nil, MobjState::Bloodytwitch4, 0, 0),                                                       # State.Bloodytwitch3
      MobjStateDef.new(891, Sprite::GOR1, 1, 6, nil, nil, MobjState::Bloodytwitch, 0, 0),                                                        # State.Bloodytwitch4
      MobjStateDef.new(892, Sprite::PLAY, 13, -1, nil, nil, MobjState::Nil, 0, 0),                                                               # State.Deadtorso
      MobjStateDef.new(893, Sprite::PLAY, 18, -1, nil, nil, MobjState::Nil, 0, 0),                                                               # State.Deadbottom
      MobjStateDef.new(894, Sprite::POL2, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Headsonstick
      MobjStateDef.new(895, Sprite::POL5, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Gibs
      MobjStateDef.new(896, Sprite::POL4, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Headonastick
      MobjStateDef.new(897, Sprite::POL3, 32768, 6, nil, nil, MobjState::Headcandles2, 0, 0),                                                    # State.Headcandles
      MobjStateDef.new(898, Sprite::POL3, 32769, 6, nil, nil, MobjState::Headcandles, 0, 0),                                                     # State.Headcandles2
      MobjStateDef.new(899, Sprite::POL1, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Deadstick
      MobjStateDef.new(900, Sprite::POL6, 0, 6, nil, nil, MobjState::Livestick2, 0, 0),                                                          # State.Livestick
      MobjStateDef.new(901, Sprite::POL6, 1, 8, nil, nil, MobjState::Livestick, 0, 0),                                                           # State.Livestick2
      MobjStateDef.new(902, Sprite::GOR2, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Meat2
      MobjStateDef.new(903, Sprite::GOR3, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Meat3
      MobjStateDef.new(904, Sprite::GOR4, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Meat4
      MobjStateDef.new(905, Sprite::GOR5, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Meat5
      MobjStateDef.new(906, Sprite::SMIT, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Stalagtite
      MobjStateDef.new(907, Sprite::COL1, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Tallgrncol
      MobjStateDef.new(908, Sprite::COL2, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Shrtgrncol
      MobjStateDef.new(909, Sprite::COL3, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Tallredcol
      MobjStateDef.new(910, Sprite::COL4, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Shrtredcol
      MobjStateDef.new(911, Sprite::CAND, 32768, -1, nil, nil, MobjState::Nil, 0, 0),                                                            # State.Candlestik
      MobjStateDef.new(912, Sprite::CBRA, 32768, -1, nil, nil, MobjState::Nil, 0, 0),                                                            # State.Candelabra
      MobjStateDef.new(913, Sprite::COL6, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Skullcol
      MobjStateDef.new(914, Sprite::TRE1, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Torchtree
      MobjStateDef.new(915, Sprite::TRE2, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Bigtree
      MobjStateDef.new(916, Sprite::ELEC, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Techpillar
      MobjStateDef.new(917, Sprite::CEYE, 32768, 6, nil, nil, MobjState::Evileye2, 0, 0),                                                        # State.Evileye
      MobjStateDef.new(918, Sprite::CEYE, 32769, 6, nil, nil, MobjState::Evileye3, 0, 0),                                                        # State.Evileye2
      MobjStateDef.new(919, Sprite::CEYE, 32770, 6, nil, nil, MobjState::Evileye4, 0, 0),                                                        # State.Evileye3
      MobjStateDef.new(920, Sprite::CEYE, 32769, 6, nil, nil, MobjState::Evileye, 0, 0),                                                         # State.Evileye4
      MobjStateDef.new(921, Sprite::FSKU, 32768, 6, nil, nil, MobjState::Floatskull2, 0, 0),                                                     # State.Floatskull
      MobjStateDef.new(922, Sprite::FSKU, 32769, 6, nil, nil, MobjState::Floatskull3, 0, 0),                                                     # State.Floatskull2
      MobjStateDef.new(923, Sprite::FSKU, 32770, 6, nil, nil, MobjState::Floatskull, 0, 0),                                                      # State.Floatskull3
      MobjStateDef.new(924, Sprite::COL5, 0, 14, nil, nil, MobjState::Heartcol2, 0, 0),                                                          # State.Heartcol
      MobjStateDef.new(925, Sprite::COL5, 1, 14, nil, nil, MobjState::Heartcol, 0, 0),                                                           # State.Heartcol2
      MobjStateDef.new(926, Sprite::TBLU, 32768, 4, nil, nil, MobjState::Bluetorch2, 0, 0),                                                      # State.Bluetorch
      MobjStateDef.new(927, Sprite::TBLU, 32769, 4, nil, nil, MobjState::Bluetorch3, 0, 0),                                                      # State.Bluetorch2
      MobjStateDef.new(928, Sprite::TBLU, 32770, 4, nil, nil, MobjState::Bluetorch4, 0, 0),                                                      # State.Bluetorch3
      MobjStateDef.new(929, Sprite::TBLU, 32771, 4, nil, nil, MobjState::Bluetorch, 0, 0),                                                       # State.Bluetorch4
      MobjStateDef.new(930, Sprite::TGRN, 32768, 4, nil, nil, MobjState::Greentorch2, 0, 0),                                                     # State.Greentorch
      MobjStateDef.new(931, Sprite::TGRN, 32769, 4, nil, nil, MobjState::Greentorch3, 0, 0),                                                     # State.Greentorch2
      MobjStateDef.new(932, Sprite::TGRN, 32770, 4, nil, nil, MobjState::Greentorch4, 0, 0),                                                     # State.Greentorch3
      MobjStateDef.new(933, Sprite::TGRN, 32771, 4, nil, nil, MobjState::Greentorch, 0, 0),                                                      # State.Greentorch4
      MobjStateDef.new(934, Sprite::TRED, 32768, 4, nil, nil, MobjState::Redtorch2, 0, 0),                                                       # State.Redtorch
      MobjStateDef.new(935, Sprite::TRED, 32769, 4, nil, nil, MobjState::Redtorch3, 0, 0),                                                       # State.Redtorch2
      MobjStateDef.new(936, Sprite::TRED, 32770, 4, nil, nil, MobjState::Redtorch4, 0, 0),                                                       # State.Redtorch3
      MobjStateDef.new(937, Sprite::TRED, 32771, 4, nil, nil, MobjState::Redtorch, 0, 0),                                                        # State.Redtorch4
      MobjStateDef.new(938, Sprite::SMBT, 32768, 4, nil, nil, MobjState::Btorchshrt2, 0, 0),                                                     # State.Btorchshrt
      MobjStateDef.new(939, Sprite::SMBT, 32769, 4, nil, nil, MobjState::Btorchshrt3, 0, 0),                                                     # State.Btorchshrt2
      MobjStateDef.new(940, Sprite::SMBT, 32770, 4, nil, nil, MobjState::Btorchshrt4, 0, 0),                                                     # State.Btorchshrt3
      MobjStateDef.new(941, Sprite::SMBT, 32771, 4, nil, nil, MobjState::Btorchshrt, 0, 0),                                                      # State.Btorchshrt4
      MobjStateDef.new(942, Sprite::SMGT, 32768, 4, nil, nil, MobjState::Gtorchshrt2, 0, 0),                                                     # State.Gtorchshrt
      MobjStateDef.new(943, Sprite::SMGT, 32769, 4, nil, nil, MobjState::Gtorchshrt3, 0, 0),                                                     # State.Gtorchshrt2
      MobjStateDef.new(944, Sprite::SMGT, 32770, 4, nil, nil, MobjState::Gtorchshrt4, 0, 0),                                                     # State.Gtorchshrt3
      MobjStateDef.new(945, Sprite::SMGT, 32771, 4, nil, nil, MobjState::Gtorchshrt, 0, 0),                                                      # State.Gtorchshrt4
      MobjStateDef.new(946, Sprite::SMRT, 32768, 4, nil, nil, MobjState::Rtorchshrt2, 0, 0),                                                     # State.Rtorchshrt
      MobjStateDef.new(947, Sprite::SMRT, 32769, 4, nil, nil, MobjState::Rtorchshrt3, 0, 0),                                                     # State.Rtorchshrt2
      MobjStateDef.new(948, Sprite::SMRT, 32770, 4, nil, nil, MobjState::Rtorchshrt4, 0, 0),                                                     # State.Rtorchshrt3
      MobjStateDef.new(949, Sprite::SMRT, 32771, 4, nil, nil, MobjState::Rtorchshrt, 0, 0),                                                      # State.Rtorchshrt4
      MobjStateDef.new(950, Sprite::HDB1, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Hangnoguts
      MobjStateDef.new(951, Sprite::HDB2, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Hangbnobrain
      MobjStateDef.new(952, Sprite::HDB3, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Hangtlookdn
      MobjStateDef.new(953, Sprite::HDB4, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Hangtskull
      MobjStateDef.new(954, Sprite::HDB5, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Hangtlookup
      MobjStateDef.new(955, Sprite::HDB6, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Hangtnobrain
      MobjStateDef.new(956, Sprite::POB1, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Colongibs
      MobjStateDef.new(957, Sprite::POB2, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Smallpool
      MobjStateDef.new(958, Sprite::BRS1, 0, -1, nil, nil, MobjState::Nil, 0, 0),                                                                # State.Brainstem
      MobjStateDef.new(959, Sprite::TLMP, 32768, 4, nil, nil, MobjState::Techlamp2, 0, 0),                                                       # State.Techlamp
      MobjStateDef.new(960, Sprite::TLMP, 32769, 4, nil, nil, MobjState::Techlamp3, 0, 0),                                                       # State.Techlamp2
      MobjStateDef.new(961, Sprite::TLMP, 32770, 4, nil, nil, MobjState::Techlamp4, 0, 0),                                                       # State.Techlamp3
      MobjStateDef.new(962, Sprite::TLMP, 32771, 4, nil, nil, MobjState::Techlamp, 0, 0),                                                        # State.Techlamp4
      MobjStateDef.new(963, Sprite::TLP2, 32768, 4, nil, nil, MobjState::Tech2Lamp2, 0, 0),                                                      # State.Tech2Lamp
      MobjStateDef.new(964, Sprite::TLP2, 32769, 4, nil, nil, MobjState::Tech2Lamp3, 0, 0),                                                      # State.Tech2Lamp2
      MobjStateDef.new(965, Sprite::TLP2, 32770, 4, nil, nil, MobjState::Tech2Lamp4, 0, 0),                                                      # State.Tech2Lamp3
      MobjStateDef.new(966, Sprite::TLP2, 32771, 4, nil, nil, MobjState::Tech2Lamp, 0, 0),                                                       # State.Tech2Lamp4
    ]
  end
end
