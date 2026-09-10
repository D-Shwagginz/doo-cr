module Doocr
	alias ActionfV = Proc(Nil)
	alias ActionfP1 = Proc(Void*, Nil)
	alias ActionfP2 = Proc(Void*, Void*, Nil)

	alias Traverser = Proc(Pointer(CDoom::Intercept), LibC::Int)

enum Spritenum
  SPR_TROO
  SPR_SHTG
  SPR_PUNG
  SPR_PISG
  SPR_PISF
  SPR_SHTF
  SPR_SHT2
  SPR_CHGG
  SPR_CHGF
  SPR_MISG
  SPR_MISF
  SPR_SAWG
  SPR_PLSG
  SPR_PLSF
  SPR_BFGG
  SPR_BFGF
  SPR_BLUD
  SPR_PUFF
  SPR_BAL1
  SPR_BAL2
  SPR_PLSS
  SPR_PLSE
  SPR_MISL
  SPR_BFS1
  SPR_BFE1
  SPR_BFE2
  SPR_TFOG
  SPR_IFOG
  SPR_PLAY
  SPR_POSS
  SPR_SPOS
  SPR_VILE
  SPR_FIRE
  SPR_FATB
  SPR_FBXP
  SPR_SKEL
  SPR_MANF
  SPR_FATT
  SPR_CPOS
  SPR_SARG
  SPR_HEAD
  SPR_BAL7
  SPR_BOSS
  SPR_BOS2
  SPR_SKUL
  SPR_SPID
  SPR_BSPI
  SPR_APLS
  SPR_APBX
  SPR_CYBR
  SPR_PAIN
  SPR_SSWV
  SPR_KEEN
  SPR_BBRN
  SPR_BOSF
  SPR_ARM1
  SPR_ARM2
  SPR_BAR1
  SPR_BEXP
  SPR_FCAN
  SPR_BON1
  SPR_BON2
  SPR_BKEY
  SPR_RKEY
  SPR_YKEY
  SPR_BSKU
  SPR_RSKU
  SPR_YSKU
  SPR_STIM
  SPR_MEDI
  SPR_SOUL
  SPR_PINV
  SPR_PSTR
  SPR_PINS
  SPR_MEGA
  SPR_SUIT
  SPR_PMAP
  SPR_PVIS
  SPR_CLIP
  SPR_AMMO
  SPR_ROCK
  SPR_BROK
  SPR_CELL
  SPR_CELP
  SPR_SHEL
  SPR_SBOX
  SPR_BPAK
  SPR_BFUG
  SPR_MGUN
  SPR_CSAW
  SPR_LAUN
  SPR_PLAS
  SPR_SHOT
  SPR_SGN2
  SPR_COLU
  SPR_SMT2
  SPR_GOR1
  SPR_POL2
  SPR_POL5
  SPR_POL4
  SPR_POL3
  SPR_POL1
  SPR_POL6
  SPR_GOR2
  SPR_GOR3
  SPR_GOR4
  SPR_GOR5
  SPR_SMIT
  SPR_COL1
  SPR_COL2
  SPR_COL3
  SPR_COL4
  SPR_CAND
  SPR_CBRA
  SPR_COL6
  SPR_TRE1
  SPR_TRE2
  SPR_ELEC
  SPR_CEYE
  SPR_FSKU
  SPR_COL5
  SPR_TBLU
  SPR_TGRN
  SPR_TRED
  SPR_SMBT
  SPR_SMGT
  SPR_SMRT
  SPR_HDB1
  SPR_HDB2
  SPR_HDB3
  SPR_HDB4
  SPR_HDB5
  SPR_HDB6
  SPR_POB1
  SPR_POB2
  SPR_BRS1
  SPR_TLMP
  SPR_TLP2
  NUMSPRITES

  SPR_TNT = 138
end

enum Statenum
  S_NULL
  S_LIGHTDONE
  S_PUNCH
  S_PUNCHDOWN
  S_PUNCHUP
  S_PUNCH1
  S_PUNCH2
  S_PUNCH3
  S_PUNCH4
  S_PUNCH5
  S_PISTOL
  S_PISTOLDOWN
  S_PISTOLUP
  S_PISTOL1
  S_PISTOL2
  S_PISTOL3
  S_PISTOL4
  S_PISTOLFLASH
  S_SGUN
  S_SGUNDOWN
  S_SGUNUP
  S_SGUN1
  S_SGUN2
  S_SGUN3
  S_SGUN4
  S_SGUN5
  S_SGUN6
  S_SGUN7
  S_SGUN8
  S_SGUN9
  S_SGUNFLASH1
  S_SGUNFLASH2
  S_DSGUN
  S_DSGUNDOWN
  S_DSGUNUP
  S_DSGUN1
  S_DSGUN2
  S_DSGUN3
  S_DSGUN4
  S_DSGUN5
  S_DSGUN6
  S_DSGUN7
  S_DSGUN8
  S_DSGUN9
  S_DSGUN10
  S_DSNR1
  S_DSNR2
  S_DSGUNFLASH1
  S_DSGUNFLASH2
  S_CHAIN
  S_CHAINDOWN
  S_CHAINUP
  S_CHAIN1
  S_CHAIN2
  S_CHAIN3
  S_CHAINFLASH1
  S_CHAINFLASH2
  S_MISSILE
  S_MISSILEDOWN
  S_MISSILEUP
  S_MISSILE1
  S_MISSILE2
  S_MISSILE3
  S_MISSILEFLASH1
  S_MISSILEFLASH2
  S_MISSILEFLASH3
  S_MISSILEFLASH4
  S_SAW
  S_SAWB
  S_SAWDOWN
  S_SAWUP
  S_SAW1
  S_SAW2
  S_SAW3
  S_PLASMA
  S_PLASMADOWN
  S_PLASMAUP
  S_PLASMA1
  S_PLASMA2
  S_PLASMAFLASH1
  S_PLASMAFLASH2
  S_BFG
  S_BFGDOWN
  S_BFGUP
  S_BFG1
  S_BFG2
  S_BFG3
  S_BFG4
  S_BFGFLASH1
  S_BFGFLASH2
  S_BLOOD1
  S_BLOOD2
  S_BLOOD3
  S_PUFF1
  S_PUFF2
  S_PUFF3
  S_PUFF4
  S_TBALL1
  S_TBALL2
  S_TBALLX1
  S_TBALLX2
  S_TBALLX3
  S_RBALL1
  S_RBALL2
  S_RBALLX1
  S_RBALLX2
  S_RBALLX3
  S_PLASBALL
  S_PLASBALL2
  S_PLASEXP
  S_PLASEXP2
  S_PLASEXP3
  S_PLASEXP4
  S_PLASEXP5
  S_ROCKET
  S_BFGSHOT
  S_BFGSHOT2
  S_BFGLAND
  S_BFGLAND2
  S_BFGLAND3
  S_BFGLAND4
  S_BFGLAND5
  S_BFGLAND6
  S_BFGEXP
  S_BFGEXP2
  S_BFGEXP3
  S_BFGEXP4
  S_EXPLODE1
  S_EXPLODE2
  S_EXPLODE3
  S_TFOG
  S_TFOG01
  S_TFOG02
  S_TFOG2
  S_TFOG3
  S_TFOG4
  S_TFOG5
  S_TFOG6
  S_TFOG7
  S_TFOG8
  S_TFOG9
  S_TFOG10
  S_IFOG
  S_IFOG01
  S_IFOG02
  S_IFOG2
  S_IFOG3
  S_IFOG4
  S_IFOG5
  S_PLAY
  S_PLAY_RUN1
  S_PLAY_RUN2
  S_PLAY_RUN3
  S_PLAY_RUN4
  S_PLAY_ATK1
  S_PLAY_ATK2
  S_PLAY_PAIN
  S_PLAY_PAIN2
  S_PLAY_DIE1
  S_PLAY_DIE2
  S_PLAY_DIE3
  S_PLAY_DIE4
  S_PLAY_DIE5
  S_PLAY_DIE6
  S_PLAY_DIE7
  S_PLAY_XDIE1
  S_PLAY_XDIE2
  S_PLAY_XDIE3
  S_PLAY_XDIE4
  S_PLAY_XDIE5
  S_PLAY_XDIE6
  S_PLAY_XDIE7
  S_PLAY_XDIE8
  S_PLAY_XDIE9
  S_POSS_STND
  S_POSS_STND2
  S_POSS_RUN1
  S_POSS_RUN2
  S_POSS_RUN3
  S_POSS_RUN4
  S_POSS_RUN5
  S_POSS_RUN6
  S_POSS_RUN7
  S_POSS_RUN8
  S_POSS_ATK1
  S_POSS_ATK2
  S_POSS_ATK3
  S_POSS_PAIN
  S_POSS_PAIN2
  S_POSS_DIE1
  S_POSS_DIE2
  S_POSS_DIE3
  S_POSS_DIE4
  S_POSS_DIE5
  S_POSS_XDIE1
  S_POSS_XDIE2
  S_POSS_XDIE3
  S_POSS_XDIE4
  S_POSS_XDIE5
  S_POSS_XDIE6
  S_POSS_XDIE7
  S_POSS_XDIE8
  S_POSS_XDIE9
  S_POSS_RAISE1
  S_POSS_RAISE2
  S_POSS_RAISE3
  S_POSS_RAISE4
  S_SPOS_STND
  S_SPOS_STND2
  S_SPOS_RUN1
  S_SPOS_RUN2
  S_SPOS_RUN3
  S_SPOS_RUN4
  S_SPOS_RUN5
  S_SPOS_RUN6
  S_SPOS_RUN7
  S_SPOS_RUN8
  S_SPOS_ATK1
  S_SPOS_ATK2
  S_SPOS_ATK3
  S_SPOS_PAIN
  S_SPOS_PAIN2
  S_SPOS_DIE1
  S_SPOS_DIE2
  S_SPOS_DIE3
  S_SPOS_DIE4
  S_SPOS_DIE5
  S_SPOS_XDIE1
  S_SPOS_XDIE2
  S_SPOS_XDIE3
  S_SPOS_XDIE4
  S_SPOS_XDIE5
  S_SPOS_XDIE6
  S_SPOS_XDIE7
  S_SPOS_XDIE8
  S_SPOS_XDIE9
  S_SPOS_RAISE1
  S_SPOS_RAISE2
  S_SPOS_RAISE3
  S_SPOS_RAISE4
  S_SPOS_RAISE5
  S_VILE_STND
  S_VILE_STND2
  S_VILE_RUN1
  S_VILE_RUN2
  S_VILE_RUN3
  S_VILE_RUN4
  S_VILE_RUN5
  S_VILE_RUN6
  S_VILE_RUN7
  S_VILE_RUN8
  S_VILE_RUN9
  S_VILE_RUN10
  S_VILE_RUN11
  S_VILE_RUN12
  S_VILE_ATK1
  S_VILE_ATK2
  S_VILE_ATK3
  S_VILE_ATK4
  S_VILE_ATK5
  S_VILE_ATK6
  S_VILE_ATK7
  S_VILE_ATK8
  S_VILE_ATK9
  S_VILE_ATK10
  S_VILE_ATK11
  S_VILE_HEAL1
  S_VILE_HEAL2
  S_VILE_HEAL3
  S_VILE_PAIN
  S_VILE_PAIN2
  S_VILE_DIE1
  S_VILE_DIE2
  S_VILE_DIE3
  S_VILE_DIE4
  S_VILE_DIE5
  S_VILE_DIE6
  S_VILE_DIE7
  S_VILE_DIE8
  S_VILE_DIE9
  S_VILE_DIE10
  S_FIRE1
  S_FIRE2
  S_FIRE3
  S_FIRE4
  S_FIRE5
  S_FIRE6
  S_FIRE7
  S_FIRE8
  S_FIRE9
  S_FIRE10
  S_FIRE11
  S_FIRE12
  S_FIRE13
  S_FIRE14
  S_FIRE15
  S_FIRE16
  S_FIRE17
  S_FIRE18
  S_FIRE19
  S_FIRE20
  S_FIRE21
  S_FIRE22
  S_FIRE23
  S_FIRE24
  S_FIRE25
  S_FIRE26
  S_FIRE27
  S_FIRE28
  S_FIRE29
  S_FIRE30
  S_SMOKE1
  S_SMOKE2
  S_SMOKE3
  S_SMOKE4
  S_SMOKE5
  S_TRACER
  S_TRACER2
  S_TRACEEXP1
  S_TRACEEXP2
  S_TRACEEXP3
  S_SKEL_STND
  S_SKEL_STND2
  S_SKEL_RUN1
  S_SKEL_RUN2
  S_SKEL_RUN3
  S_SKEL_RUN4
  S_SKEL_RUN5
  S_SKEL_RUN6
  S_SKEL_RUN7
  S_SKEL_RUN8
  S_SKEL_RUN9
  S_SKEL_RUN10
  S_SKEL_RUN11
  S_SKEL_RUN12
  S_SKEL_FIST1
  S_SKEL_FIST2
  S_SKEL_FIST3
  S_SKEL_FIST4
  S_SKEL_MISS1
  S_SKEL_MISS2
  S_SKEL_MISS3
  S_SKEL_MISS4
  S_SKEL_PAIN
  S_SKEL_PAIN2
  S_SKEL_DIE1
  S_SKEL_DIE2
  S_SKEL_DIE3
  S_SKEL_DIE4
  S_SKEL_DIE5
  S_SKEL_DIE6
  S_SKEL_RAISE1
  S_SKEL_RAISE2
  S_SKEL_RAISE3
  S_SKEL_RAISE4
  S_SKEL_RAISE5
  S_SKEL_RAISE6
  S_FATSHOT1
  S_FATSHOT2
  S_FATSHOTX1
  S_FATSHOTX2
  S_FATSHOTX3
  S_FATT_STND
  S_FATT_STND2
  S_FATT_RUN1
  S_FATT_RUN2
  S_FATT_RUN3
  S_FATT_RUN4
  S_FATT_RUN5
  S_FATT_RUN6
  S_FATT_RUN7
  S_FATT_RUN8
  S_FATT_RUN9
  S_FATT_RUN10
  S_FATT_RUN11
  S_FATT_RUN12
  S_FATT_ATK1
  S_FATT_ATK2
  S_FATT_ATK3
  S_FATT_ATK4
  S_FATT_ATK5
  S_FATT_ATK6
  S_FATT_ATK7
  S_FATT_ATK8
  S_FATT_ATK9
  S_FATT_ATK10
  S_FATT_PAIN
  S_FATT_PAIN2
  S_FATT_DIE1
  S_FATT_DIE2
  S_FATT_DIE3
  S_FATT_DIE4
  S_FATT_DIE5
  S_FATT_DIE6
  S_FATT_DIE7
  S_FATT_DIE8
  S_FATT_DIE9
  S_FATT_DIE10
  S_FATT_RAISE1
  S_FATT_RAISE2
  S_FATT_RAISE3
  S_FATT_RAISE4
  S_FATT_RAISE5
  S_FATT_RAISE6
  S_FATT_RAISE7
  S_FATT_RAISE8
  S_CPOS_STND
  S_CPOS_STND2
  S_CPOS_RUN1
  S_CPOS_RUN2
  S_CPOS_RUN3
  S_CPOS_RUN4
  S_CPOS_RUN5
  S_CPOS_RUN6
  S_CPOS_RUN7
  S_CPOS_RUN8
  S_CPOS_ATK1
  S_CPOS_ATK2
  S_CPOS_ATK3
  S_CPOS_ATK4
  S_CPOS_PAIN
  S_CPOS_PAIN2
  S_CPOS_DIE1
  S_CPOS_DIE2
  S_CPOS_DIE3
  S_CPOS_DIE4
  S_CPOS_DIE5
  S_CPOS_DIE6
  S_CPOS_DIE7
  S_CPOS_XDIE1
  S_CPOS_XDIE2
  S_CPOS_XDIE3
  S_CPOS_XDIE4
  S_CPOS_XDIE5
  S_CPOS_XDIE6
  S_CPOS_RAISE1
  S_CPOS_RAISE2
  S_CPOS_RAISE3
  S_CPOS_RAISE4
  S_CPOS_RAISE5
  S_CPOS_RAISE6
  S_CPOS_RAISE7
  S_TROO_STND
  S_TROO_STND2
  S_TROO_RUN1
  S_TROO_RUN2
  S_TROO_RUN3
  S_TROO_RUN4
  S_TROO_RUN5
  S_TROO_RUN6
  S_TROO_RUN7
  S_TROO_RUN8
  S_TROO_ATK1
  S_TROO_ATK2
  S_TROO_ATK3
  S_TROO_PAIN
  S_TROO_PAIN2
  S_TROO_DIE1
  S_TROO_DIE2
  S_TROO_DIE3
  S_TROO_DIE4
  S_TROO_DIE5
  S_TROO_XDIE1
  S_TROO_XDIE2
  S_TROO_XDIE3
  S_TROO_XDIE4
  S_TROO_XDIE5
  S_TROO_XDIE6
  S_TROO_XDIE7
  S_TROO_XDIE8
  S_TROO_RAISE1
  S_TROO_RAISE2
  S_TROO_RAISE3
  S_TROO_RAISE4
  S_TROO_RAISE5
  S_SARG_STND
  S_SARG_STND2
  S_SARG_RUN1
  S_SARG_RUN2
  S_SARG_RUN3
  S_SARG_RUN4
  S_SARG_RUN5
  S_SARG_RUN6
  S_SARG_RUN7
  S_SARG_RUN8
  S_SARG_ATK1
  S_SARG_ATK2
  S_SARG_ATK3
  S_SARG_PAIN
  S_SARG_PAIN2
  S_SARG_DIE1
  S_SARG_DIE2
  S_SARG_DIE3
  S_SARG_DIE4
  S_SARG_DIE5
  S_SARG_DIE6
  S_SARG_RAISE1
  S_SARG_RAISE2
  S_SARG_RAISE3
  S_SARG_RAISE4
  S_SARG_RAISE5
  S_SARG_RAISE6
  S_HEAD_STND
  S_HEAD_RUN1
  S_HEAD_ATK1
  S_HEAD_ATK2
  S_HEAD_ATK3
  S_HEAD_PAIN
  S_HEAD_PAIN2
  S_HEAD_PAIN3
  S_HEAD_DIE1
  S_HEAD_DIE2
  S_HEAD_DIE3
  S_HEAD_DIE4
  S_HEAD_DIE5
  S_HEAD_DIE6
  S_HEAD_RAISE1
  S_HEAD_RAISE2
  S_HEAD_RAISE3
  S_HEAD_RAISE4
  S_HEAD_RAISE5
  S_HEAD_RAISE6
  S_BRBALL1
  S_BRBALL2
  S_BRBALLX1
  S_BRBALLX2
  S_BRBALLX3
  S_BOSS_STND
  S_BOSS_STND2
  S_BOSS_RUN1
  S_BOSS_RUN2
  S_BOSS_RUN3
  S_BOSS_RUN4
  S_BOSS_RUN5
  S_BOSS_RUN6
  S_BOSS_RUN7
  S_BOSS_RUN8
  S_BOSS_ATK1
  S_BOSS_ATK2
  S_BOSS_ATK3
  S_BOSS_PAIN
  S_BOSS_PAIN2
  S_BOSS_DIE1
  S_BOSS_DIE2
  S_BOSS_DIE3
  S_BOSS_DIE4
  S_BOSS_DIE5
  S_BOSS_DIE6
  S_BOSS_DIE7
  S_BOSS_RAISE1
  S_BOSS_RAISE2
  S_BOSS_RAISE3
  S_BOSS_RAISE4
  S_BOSS_RAISE5
  S_BOSS_RAISE6
  S_BOSS_RAISE7
  S_BOS2_STND
  S_BOS2_STND2
  S_BOS2_RUN1
  S_BOS2_RUN2
  S_BOS2_RUN3
  S_BOS2_RUN4
  S_BOS2_RUN5
  S_BOS2_RUN6
  S_BOS2_RUN7
  S_BOS2_RUN8
  S_BOS2_ATK1
  S_BOS2_ATK2
  S_BOS2_ATK3
  S_BOS2_PAIN
  S_BOS2_PAIN2
  S_BOS2_DIE1
  S_BOS2_DIE2
  S_BOS2_DIE3
  S_BOS2_DIE4
  S_BOS2_DIE5
  S_BOS2_DIE6
  S_BOS2_DIE7
  S_BOS2_RAISE1
  S_BOS2_RAISE2
  S_BOS2_RAISE3
  S_BOS2_RAISE4
  S_BOS2_RAISE5
  S_BOS2_RAISE6
  S_BOS2_RAISE7
  S_SKULL_STND
  S_SKULL_STND2
  S_SKULL_RUN1
  S_SKULL_RUN2
  S_SKULL_ATK1
  S_SKULL_ATK2
  S_SKULL_ATK3
  S_SKULL_ATK4
  S_SKULL_PAIN
  S_SKULL_PAIN2
  S_SKULL_DIE1
  S_SKULL_DIE2
  S_SKULL_DIE3
  S_SKULL_DIE4
  S_SKULL_DIE5
  S_SKULL_DIE6
  S_SPID_STND
  S_SPID_STND2
  S_SPID_RUN1
  S_SPID_RUN2
  S_SPID_RUN3
  S_SPID_RUN4
  S_SPID_RUN5
  S_SPID_RUN6
  S_SPID_RUN7
  S_SPID_RUN8
  S_SPID_RUN9
  S_SPID_RUN10
  S_SPID_RUN11
  S_SPID_RUN12
  S_SPID_ATK1
  S_SPID_ATK2
  S_SPID_ATK3
  S_SPID_ATK4
  S_SPID_PAIN
  S_SPID_PAIN2
  S_SPID_DIE1
  S_SPID_DIE2
  S_SPID_DIE3
  S_SPID_DIE4
  S_SPID_DIE5
  S_SPID_DIE6
  S_SPID_DIE7
  S_SPID_DIE8
  S_SPID_DIE9
  S_SPID_DIE10
  S_SPID_DIE11
  S_BSPI_STND
  S_BSPI_STND2
  S_BSPI_SIGHT
  S_BSPI_RUN1
  S_BSPI_RUN2
  S_BSPI_RUN3
  S_BSPI_RUN4
  S_BSPI_RUN5
  S_BSPI_RUN6
  S_BSPI_RUN7
  S_BSPI_RUN8
  S_BSPI_RUN9
  S_BSPI_RUN10
  S_BSPI_RUN11
  S_BSPI_RUN12
  S_BSPI_ATK1
  S_BSPI_ATK2
  S_BSPI_ATK3
  S_BSPI_ATK4
  S_BSPI_PAIN
  S_BSPI_PAIN2
  S_BSPI_DIE1
  S_BSPI_DIE2
  S_BSPI_DIE3
  S_BSPI_DIE4
  S_BSPI_DIE5
  S_BSPI_DIE6
  S_BSPI_DIE7
  S_BSPI_RAISE1
  S_BSPI_RAISE2
  S_BSPI_RAISE3
  S_BSPI_RAISE4
  S_BSPI_RAISE5
  S_BSPI_RAISE6
  S_BSPI_RAISE7
  S_ARACH_PLAZ
  S_ARACH_PLAZ2
  S_ARACH_PLEX
  S_ARACH_PLEX2
  S_ARACH_PLEX3
  S_ARACH_PLEX4
  S_ARACH_PLEX5
  S_CYBER_STND
  S_CYBER_STND2
  S_CYBER_RUN1
  S_CYBER_RUN2
  S_CYBER_RUN3
  S_CYBER_RUN4
  S_CYBER_RUN5
  S_CYBER_RUN6
  S_CYBER_RUN7
  S_CYBER_RUN8
  S_CYBER_ATK1
  S_CYBER_ATK2
  S_CYBER_ATK3
  S_CYBER_ATK4
  S_CYBER_ATK5
  S_CYBER_ATK6
  S_CYBER_PAIN
  S_CYBER_DIE1
  S_CYBER_DIE2
  S_CYBER_DIE3
  S_CYBER_DIE4
  S_CYBER_DIE5
  S_CYBER_DIE6
  S_CYBER_DIE7
  S_CYBER_DIE8
  S_CYBER_DIE9
  S_CYBER_DIE10
  S_PAIN_STND
  S_PAIN_RUN1
  S_PAIN_RUN2
  S_PAIN_RUN3
  S_PAIN_RUN4
  S_PAIN_RUN5
  S_PAIN_RUN6
  S_PAIN_ATK1
  S_PAIN_ATK2
  S_PAIN_ATK3
  S_PAIN_ATK4
  S_PAIN_PAIN
  S_PAIN_PAIN2
  S_PAIN_DIE1
  S_PAIN_DIE2
  S_PAIN_DIE3
  S_PAIN_DIE4
  S_PAIN_DIE5
  S_PAIN_DIE6
  S_PAIN_RAISE1
  S_PAIN_RAISE2
  S_PAIN_RAISE3
  S_PAIN_RAISE4
  S_PAIN_RAISE5
  S_PAIN_RAISE6
  S_SSWV_STND
  S_SSWV_STND2
  S_SSWV_RUN1
  S_SSWV_RUN2
  S_SSWV_RUN3
  S_SSWV_RUN4
  S_SSWV_RUN5
  S_SSWV_RUN6
  S_SSWV_RUN7
  S_SSWV_RUN8
  S_SSWV_ATK1
  S_SSWV_ATK2
  S_SSWV_ATK3
  S_SSWV_ATK4
  S_SSWV_ATK5
  S_SSWV_ATK6
  S_SSWV_PAIN
  S_SSWV_PAIN2
  S_SSWV_DIE1
  S_SSWV_DIE2
  S_SSWV_DIE3
  S_SSWV_DIE4
  S_SSWV_DIE5
  S_SSWV_XDIE1
  S_SSWV_XDIE2
  S_SSWV_XDIE3
  S_SSWV_XDIE4
  S_SSWV_XDIE5
  S_SSWV_XDIE6
  S_SSWV_XDIE7
  S_SSWV_XDIE8
  S_SSWV_XDIE9
  S_SSWV_RAISE1
  S_SSWV_RAISE2
  S_SSWV_RAISE3
  S_SSWV_RAISE4
  S_SSWV_RAISE5
  S_KEENSTND
  S_COMMKEEN
  S_COMMKEEN2
  S_COMMKEEN3
  S_COMMKEEN4
  S_COMMKEEN5
  S_COMMKEEN6
  S_COMMKEEN7
  S_COMMKEEN8
  S_COMMKEEN9
  S_COMMKEEN10
  S_COMMKEEN11
  S_COMMKEEN12
  S_KEENPAIN
  S_KEENPAIN2
  S_BRAIN
  S_BRAIN_PAIN
  S_BRAIN_DIE1
  S_BRAIN_DIE2
  S_BRAIN_DIE3
  S_BRAIN_DIE4
  S_BRAINEYE
  S_BRAINEYESEE
  S_BRAINEYE1
  S_SPAWN1
  S_SPAWN2
  S_SPAWN3
  S_SPAWN4
  S_SPAWNFIRE1
  S_SPAWNFIRE2
  S_SPAWNFIRE3
  S_SPAWNFIRE4
  S_SPAWNFIRE5
  S_SPAWNFIRE6
  S_SPAWNFIRE7
  S_SPAWNFIRE8
  S_BRAINEXPLODE1
  S_BRAINEXPLODE2
  S_BRAINEXPLODE3
  S_ARM1
  S_ARM1A
  S_ARM2
  S_ARM2A
  S_BAR1
  S_BAR2
  S_BEXP
  S_BEXP2
  S_BEXP3
  S_BEXP4
  S_BEXP5
  S_BBAR1
  S_BBAR2
  S_BBAR3
  S_BON1
  S_BON1A
  S_BON1B
  S_BON1C
  S_BON1D
  S_BON1E
  S_BON2
  S_BON2A
  S_BON2B
  S_BON2C
  S_BON2D
  S_BON2E
  S_BKEY
  S_BKEY2
  S_RKEY
  S_RKEY2
  S_YKEY
  S_YKEY2
  S_BSKULL
  S_BSKULL2
  S_RSKULL
  S_RSKULL2
  S_YSKULL
  S_YSKULL2
  S_STIM
  S_MEDI
  S_SOUL
  S_SOUL2
  S_SOUL3
  S_SOUL4
  S_SOUL5
  S_SOUL6
  S_PINV
  S_PINV2
  S_PINV3
  S_PINV4
  S_PSTR
  S_PINS
  S_PINS2
  S_PINS3
  S_PINS4
  S_MEGA
  S_MEGA2
  S_MEGA3
  S_MEGA4
  S_SUIT
  S_PMAP
  S_PMAP2
  S_PMAP3
  S_PMAP4
  S_PMAP5
  S_PMAP6
  S_PVIS
  S_PVIS2
  S_CLIP
  S_AMMO
  S_ROCK
  S_BROK
  S_CELL
  S_CELP
  S_SHEL
  S_SBOX
  S_BPAK
  S_BFUG
  S_MGUN
  S_CSAW
  S_LAUN
  S_PLAS
  S_SHOT
  S_SHOT2
  S_COLU
  S_STALAG
  S_BLOODYTWITCH
  S_BLOODYTWITCH2
  S_BLOODYTWITCH3
  S_BLOODYTWITCH4
  S_DEADTORSO
  S_DEADBOTTOM
  S_HEADSONSTICK
  S_GIBS
  S_HEADONASTICK
  S_HEADCANDLES
  S_HEADCANDLES2
  S_DEADSTICK
  S_LIVESTICK
  S_LIVESTICK2
  S_MEAT2
  S_MEAT3
  S_MEAT4
  S_MEAT5
  S_STALAGTITE
  S_TALLGRNCOL
  S_SHRTGRNCOL
  S_TALLREDCOL
  S_SHRTREDCOL
  S_CANDLESTIK
  S_CANDELABRA
  S_SKULLCOL
  S_TORCHTREE
  S_BIGTREE
  S_TECHPILLAR
  S_EVILEYE
  S_EVILEYE2
  S_EVILEYE3
  S_EVILEYE4
  S_FLOATSKULL
  S_FLOATSKULL2
  S_FLOATSKULL3
  S_HEARTCOL
  S_HEARTCOL2
  S_BLUETORCH
  S_BLUETORCH2
  S_BLUETORCH3
  S_BLUETORCH4
  S_GREENTORCH
  S_GREENTORCH2
  S_GREENTORCH3
  S_GREENTORCH4
  S_REDTORCH
  S_REDTORCH2
  S_REDTORCH3
  S_REDTORCH4
  S_BTORCHSHRT
  S_BTORCHSHRT2
  S_BTORCHSHRT3
  S_BTORCHSHRT4
  S_GTORCHSHRT
  S_GTORCHSHRT2
  S_GTORCHSHRT3
  S_GTORCHSHRT4
  S_RTORCHSHRT
  S_RTORCHSHRT2
  S_RTORCHSHRT3
  S_RTORCHSHRT4
  S_HANGNOGUTS
  S_HANGBNOBRAIN
  S_HANGTLOOKDN
  S_HANGTSKULL
  S_HANGTLOOKUP
  S_HANGTNOBRAIN
  S_COLONGIBS
  S_SMALLPOOL
  S_BRAINSTEM
  S_TECHLAMP
  S_TECHLAMP2
  S_TECHLAMP3
  S_TECHLAMP4
  S_TECH2LAMP
  S_TECH2LAMP2
  S_TECH2LAMP3
  S_TECH2LAMP4
  NUMSTATES
end

enum Mobjtype
  MT_PLAYER
  MT_POSSESSED
  MT_SHOTGUY
  MT_VILE
  MT_FIRE
  MT_UNDEAD
  MT_TRACER
  MT_SMOKE
  MT_FATSO
  MT_FATSHOT
  MT_CHAINGUY
  MT_TROOP
  MT_SERGEANT
  MT_SHADOWS
  MT_HEAD
  MT_BRUISER
  MT_BRUISERSHOT
  MT_KNIGHT
  MT_SKULL
  MT_SPIDER
  MT_BABY
  MT_CYBORG
  MT_PAIN
  MT_WOLFSS
  MT_KEEN
  MT_BOSSBRAIN
  MT_BOSSSPIT
  MT_BOSSTARGET
  MT_SPAWNSHOT
  MT_SPAWNFIRE
  MT_BARREL
  MT_TROOPSHOT
  MT_HEADSHOT
  MT_ROCKET
  MT_PLASMA
  MT_BFG
  MT_ARACHPLAZ
  MT_PUFF
  MT_BLOOD
  MT_TFOG
  MT_IFOG
  MT_TELEPORTMAN
  MT_EXTRABFG
  MT_MISC0
  MT_MISC1
  MT_MISC2
  MT_MISC3
  MT_MISC4
  MT_MISC5
  MT_MISC6
  MT_MISC7
  MT_MISC8
  MT_MISC9
  MT_MISC10
  MT_MISC11
  MT_MISC12
  MT_INV
  MT_MISC13
  MT_INS
  MT_MISC14
  MT_MISC15
  MT_MISC16
  MT_MEGA
  MT_CLIP
  MT_MISC17
  MT_MISC18
  MT_MISC19
  MT_MISC20
  MT_MISC21
  MT_MISC22
  MT_MISC23
  MT_MISC24
  MT_MISC25
  MT_CHAINGUN
  MT_MISC26
  MT_MISC27
  MT_MISC28
  MT_SHOTGUN
  MT_SUPERSHOTGUN
  MT_MISC29
  MT_MISC30
  MT_MISC31
  MT_MISC32
  MT_MISC33
  MT_MISC34
  MT_MISC35
  MT_MISC36
  MT_MISC37
  MT_MISC38
  MT_MISC39
  MT_MISC40
  MT_MISC41
  MT_MISC42
  MT_MISC43
  MT_MISC44
  MT_MISC45
  MT_MISC46
  MT_MISC47
  MT_MISC48
  MT_MISC49
  MT_MISC50
  MT_MISC51
  MT_MISC52
  MT_MISC53
  MT_MISC54
  MT_MISC55
  MT_MISC56
  MT_MISC57
  MT_MISC58
  MT_MISC59
  MT_MISC60
  MT_MISC61
  MT_MISC62
  MT_MISC63
  MT_MISC64
  MT_MISC65
  MT_MISC66
  MT_MISC67
  MT_MISC68
  MT_MISC69
  MT_MISC70
  MT_MISC71
  MT_MISC72
  MT_MISC73
  MT_MISC74
  MT_MISC75
  MT_MISC76
  MT_MISC77
  MT_MISC78
  MT_MISC79
  MT_MISC80
  MT_MISC81
  MT_MISC82
  MT_MISC83
  MT_MISC84
  MT_MISC85
  MT_MISC86
  NUMMOBJTYPES
end

enum Musicenum
  MUS_None
  MUS_e1m1
  MUS_e1m2
  MUS_e1m3
  MUS_e1m4
  MUS_e1m5
  MUS_e1m6
  MUS_e1m7
  MUS_e1m8
  MUS_e1m9
  MUS_e2m1
  MUS_e2m2
  MUS_e2m3
  MUS_e2m4
  MUS_e2m5
  MUS_e2m6
  MUS_e2m7
  MUS_e2m8
  MUS_e2m9
  MUS_e3m1
  MUS_e3m2
  MUS_e3m3
  MUS_e3m4
  MUS_e3m5
  MUS_e3m6
  MUS_e3m7
  MUS_e3m8
  MUS_e3m9
  MUS_inter
  MUS_intro
  MUS_bunny
  MUS_victor
  MUS_introa
  MUS_runnin
  MUS_stalks
  MUS_countd
  MUS_betwee
  MUS_doom
  MUS_the_da
  MUS_shawn
  MUS_ddtblu
  MUS_in_cit
  MUS_dead
  MUS_stlks2
  MUS_theda2
  MUS_doom2
  MUS_ddtbl2
  MUS_runni2
  MUS_dead2
  MUS_stlks3
  MUS_romero
  MUS_shawn2
  MUS_messag
  MUS_count2
  MUS_ddtbl3
  MUS_ampie
  MUS_theda3
  MUS_adrian
  MUS_messg2
  MUS_romer2
  MUS_tense
  MUS_shawn3
  MUS_openin
  MUS_evil
  MUS_ultima
  MUS_read_m
  MUS_dm2ttl
  MUS_dm2int
  NUMMUSIC
end

enum Sfxenum
  SFX_None
  SFX_pistol
  SFX_shotgn
  SFX_sgcock
  SFX_dshtgn
  SFX_dbopn
  SFX_dbcls
  SFX_dbload
  SFX_plasma
  SFX_bfg
  SFX_sawup
  SFX_sawidl
  SFX_sawful
  SFX_sawhit
  SFX_rlaunc
  SFX_rxplod
  SFX_firsht
  SFX_firxpl
  SFX_pstart
  SFX_pstop
  SFX_doropn
  SFX_dorcls
  SFX_stnmov
  SFX_swtchn
  SFX_swtchx
  SFX_plpain
  SFX_dmpain
  SFX_popain
  SFX_vipain
  SFX_mnpain
  SFX_pepain
  SFX_slop
  SFX_itemup
  SFX_wpnup
  SFX_oof
  SFX_telept
  SFX_posit1
  SFX_posit2
  SFX_posit3
  SFX_bgsit1
  SFX_bgsit2
  SFX_sgtsit
  SFX_cacsit
  SFX_brssit
  SFX_cybsit
  SFX_spisit
  SFX_bspsit
  SFX_kntsit
  SFX_vilsit
  SFX_mansit
  SFX_pesit
  SFX_sklatk
  SFX_sgtatk
  SFX_skepch
  SFX_vilatk
  SFX_claw
  SFX_skeswg
  SFX_pldeth
  SFX_pdiehi
  SFX_podth1
  SFX_podth2
  SFX_podth3
  SFX_bgdth1
  SFX_bgdth2
  SFX_sgtdth
  SFX_cacdth
  SFX_skldth
  SFX_brsdth
  SFX_cybdth
  SFX_spidth
  SFX_bspdth
  SFX_vildth
  SFX_kntdth
  SFX_pedth
  SFX_skedth
  SFX_posact
  SFX_bgact
  SFX_dmact
  SFX_bspact
  SFX_bspwlk
  SFX_vilact
  SFX_noway
  SFX_barexp
  SFX_punch
  SFX_hoof
  SFX_metal
  SFX_chgun
  SFX_tink
  SFX_bdopn
  SFX_bdcls
  SFX_itmbk
  SFX_flame
  SFX_flamst
  SFX_getpow
  SFX_bospit
  SFX_boscub
  SFX_bossit
  SFX_bospn
  SFX_bosdth
  SFX_manatk
  SFX_mandth
  SFX_sssit
  SFX_ssdth
  SFX_keenpn
  SFX_keendt
  SFX_skeact
  SFX_skesit
  SFX_skeatk
  SFX_radio
  NUMSFX
end
	KEY_RIGHTARROW = 0xae
	KEY_LEFTARROW = 0xac
	KEY_UPARROW = 0xad
	KEY_DOWNARROW = 0xaf
	KEY_ESCAPE = 27
	KEY_ENTER = 13
	KEY_TAB = 9
	KEY_F1 = 0x80 + 0x3b
	KEY_F2 = 0x80 + 0x3c
	KEY_F3 = 0x80 + 0x3d
	KEY_F4 = 0x80 + 0x3e
	KEY_F5 = 0x80 + 0x3f
	KEY_F6 = 0x80 + 0x40
	KEY_F7 = 0x80 + 0x41
	KEY_F8 = 0x80 + 0x42
	KEY_F9 = 0x80 + 0x43
	KEY_F10 = 0x80 + 0x44
	KEY_F11 = 0x80 + 0x57
	KEY_F12 = 0x80 + 0x58
	KEY_BACKSPACE = 127
	KEY_PAUSE = 0xff
	KEY_EQUALS = 0x3d
	KEY_MINUS = 0x2d
	KEY_RSHIFT = 0x80 + 0x36
	KEY_RCTRL = 0x80 + 0x1d
	KEY_RALT = 0x80 + 0x38
	KEY_LALT = KEY_RALT
	PU_STATIC = 1
	PU_SOUND = 2
	PU_MUSIC = 3
	PU_DAVE = 4
	PU_LEVEL = 50
	PU_LEVSPEC = 51
	PU_PURGELEVEL = 100
	PU_CACHE = 101
	ZONEID = 0x1d4a11
	MINFRAGMENT = 64
	MEM_ALIGN = sizeof(Void*)
	SCREEN_PALETTE_SIZE = 256 * 3
	SAMPLECOUNT = 512
	NUM_CHANNELS = 16
	BUFMUL = 4
	MIXBUFFERSIZE = SAMPLECOUNT * BUFMUL
	SAMPLERATE = 11025
	SAMPLESIZE = 2
	MAX_QUEUED_MIDI_MSGS = 256
	EVENT_RELEASE_NOTE = 0
	EVENT_PLAY_NOTE = 1
	EVENT_PITCH_BEND = 2
	EVENT_SYSTEM_EVENT = 3
	EVENT_CONTROLLER = 4
	EVENT_END_OF_MEASURE = 5
	EVENT_FINISH = 6
	EVENT_UNUSED = 7
	CONTROLLER_EVENT_ALL_SOUNDS_OFF = 10
	CONTROLLER_EVENT_ALL_NOTES_OFF = 11
	CONTROLLER_EVENT_MONO = 12
	CONTROLLER_EVENT_POLY = 13
	CONTROLLER_EVENT_RESET_ALL_CONTROLLERS = 14
	CONTROLLER_EVENT_EVENT = 15
	CONTROLLER_CHANGE_INSTRUMENT = 0
	CONTROLLER_BANK_SELECT = 1
	CONTROLLER_MODULATION = 2
	CONTROLLER_VOLUME = 3
	CONTROLLER_PAN = 4
	CONTROLLER_EXPRESSION = 5
	CONTROLLER_REVERB = 6
	CONTROLLER_CHORUS = 7
	CONTROLLER_SUSTAIN = 8
	CONTROLLER_SOFT = 9
	WIPE_COLORXFORM = 0
	WIPE_MELT = 1
	WIPE_NUMWIPES = 2
	REDS = 256 - 5 * 16
	REDRANGE = 16
	BLUES = 256 - 4 * 16 + 8
	BLUERANGE = 8
	GREENS = 7 * 16
	GREENRANGE = 16
	GRAYS = 6 * 16
	GRAYSRANGE = 16
	BROWNS = 4 * 16
	BROWNRANGE = 16
	YELLOWS = 256 - 32 + 7
	YELLOWRANGE = 1
	BLACK = 0
	WHITE = 256 - 47
	BACKGROUND = BLACK
	YOURCOLORS = WHITE
	YOURRANGE = 0
	WALLCOLORS = REDS
	WALLRANGE = REDRANGE
	TSWALLCOLORS = GRAYS
	TSWALLRANGE = GRAYSRANGE
	FDWALLCOLORS = BROWNS
	FDWALLRANGE = BROWNRANGE
	CDWALLCOLORS = YELLOWS
	CDWALLRANGE = YELLOWRANGE
	THINGCOLORS = GREENS
	THINGRANGE = GREENRANGE
	SECRETWALLCOLORS = WALLCOLORS
	SECRETWALLRANGE = WALLRANGE
	GRIDCOLORS = GRAYS + GRAYSRANGE // 2
	GRIDRANGE = 0
	XHAIRCOLORS = GRAYS
	FB = 0
	ML_LABEL = 0
	ML_THINGS = 1
	ML_LINEDEFS = 2
	ML_SIDEDEFS = 3
	ML_VERTEXES = 4
	ML_SEGS = 5
	ML_SSECTORS = 6
	ML_NODES = 7
	ML_SECTORS = 8
	ML_REJECT = 9
	ML_BLOCKMAP = 10
	ML_BLOCKING = 1
	ML_BLOCKMONSTERS = 2
	ML_TWOSIDED = 4
	ML_DONTPEGTOP = 8
	ML_DONTPEGBOTTOM = 16
	ML_SECRET = 32
	ML_SOUNDBLOCK = 64
	ML_DONTDRAW = 128
	ML_MAPPED = 256
	NF_SUBSECTOR = 0x8000
	BOXTOP = 0
	BOXBOTTOM = 1
	BOXLEFT = 2
	BOXRIGHT = 3
	MAXEVENTS = 64 * 64
	MAXWADFILES = 20
	DOOMCOM_ID = 0x12345678
	MAXNETNODES = 8
	BACKUPTICS = 24
	MAX_DM_STARTS = 10
	MAXINTERCEPTS = 128
	ITEMQUESIZE = 128
	MAXBUTTONS = 16
	BUTTONTIME = 35
	class Pic
		property width : UInt8
		property height : UInt8
		property data : UInt8

		def initialize(@width : UInt8 = 0, @height : UInt8 = 0, @data : UInt8 = 0)
		end
	end
	class AltNetData
		property gametic : Int32
		property maketic : Int32
		property section : Array(UInt8)

		def initialize(@gametic : Int32 = 0, @maketic : Int32 = 0)
			@section = Array.new(1024, 0_u8)
		end
	end

	class Maskdraw
		property x1 : Int32
		property x2 : Int32
		property column : Int32
		property topclip : Int32
		property bottomclip : Int32

		def initialize(@x1 : Int32 = 0, @x2 : Int32 = 0, @column : Int32 = 0,
		               @topclip : Int32 = 0, @bottomclip : Int32 = 0)
		end
	end
	class Degenmobj
		property x : Int32
		property y : Int32
		property z : Int32
		getter token : Pointer(Void)

		def initialize(@x : Int32 = 0, @y : Int32 = 0, @z : Int32 = 0)
			@token = Pointer(UInt8).malloc(1).as(Void*)
		end
	end

	class AnimPoint
		property x : Int32
		property y : Int32

		def initialize(@x : Int32 = 0, @y : Int32 = 0)
		end
	end
	SAVEGAMESIZE = 0x2c000
	SAVESTRINGSIZE = 24
	TURBOTHRESHOLD = 0x32
	SLOWTURNTICS = 6
	NUMKEYS = 256
	BODYQUESIZE = 32
	VERSIONSIZE = 16
	DEMOMARKER = 0x80
	LINEHEIGHT = 16
	MAXSPECIALCROSS = 8
	MAX_DEATHMATCH_STARTS = 10
	MAXDRAWSEGS = 256
	MAXSWITCHES = 50
	MAXVISSPRITES = 128
	MAXANIMS = 32
	MAXLINEANIMS = 64
	MAX_ADJOINING_SECTORS = 20
	SWITCHLIST_SIZE = MAXSWITCHES * 2
	MAXSEGS = 32
	MAXVISPLANES = 128
	MAXOPENINGS = SCREENWIDTH * 64
	AM_MSGHEADER = ('a'.ord << 24) + ('m'.ord << 16)
	AM_MSGENTERED = AM_MSGHEADER | ('e'.ord << 8)
	AM_MSGEXITED = AM_MSGHEADER | ('x'.ord << 8)
	AM_PANDOWNKEY = 0xaf
	AM_PANUPKEY = 0xad
	AM_PANRIGHTKEY = 0xae
	AM_PANLEFTKEY = 0xac
	AM_ZOOMINKEY = '='
	AM_ZOOMOUTKEY = '-'
	AM_STARTKEY = 9
	AM_ENDKEY = 9
	AM_GOBIGKEY = '0'
	AM_FOLLOWKEY = 'f'
	AM_GRIDKEY = 'g'
	AM_MARKKEY = 'm'
	AM_CLEARMARKKEY = 'c'
	AM_NUMMARKPOINTS = 10
	HU_FONTSTART = 33
	HU_FONTEND = 95
	HU_FONTSIZE = HU_FONTEND - HU_FONTSTART + 1
	HU_BROADCAST = 5
	HU_MSGREFRESH = 13
	HU_MSGX = 0
	HU_MSGY = 0
	HU_MSGWIDTH = 64
	HU_MSGHEIGHT = 1
	HU_MSGTIMEOUT = 4 * 35
	HU_CHARERASE = 127
	HU_MAXLINES = 4
	HU_MAXLINELENGTH = 80
	HU_TITLEHEIGHT = 1
	HU_INPUTTOGGLE = 't'.ord
	HU_INPUTWIDTH = 64
	HU_INPUTHEIGHT = 1
	NUMEPISODES = 4
	NUMMAPS = 9
	WI_TITLEY = 2
	WI_SPACINGY = 33
	SP_STATSX = 50
	SP_STATSY = 50
	SP_TIMEX = 16
	SP_TIMEY = SCREENHEIGHT - 32
	NG_STATSY = 50
	NG_SPACINGX = 64
	DM_MATRIXX = 42
	DM_MATRIXY = 68
	DM_SPACINGX = 40
	DM_TOTALSX = 269
	DM_KILLERSX = 10
	DM_KILLERSY = 100
	DM_VICTIMSX = 5
	DM_VICTIMSY = 50
	SP_KILLS = 0
	SP_ITEMS = 2
	SP_SECRET = 4
	SP_FRAGS = 6
	SP_TIME = 8
	SP_PAUSE = 1
	SHOWNEXTLOCDELAY = 4
	STLIB_BG = 4
	STLIB_FG = 0
	ST_HEIGHT = 32 * SCREEN_MUL
	ST_WIDTH = SCREENWIDTH
	ST_Y = SCREENHEIGHT - ST_HEIGHT
	ST_X = 0
	ST_FX = 143
	ST_NUMPAINFACES = 5
	ST_NUMSTRAIGHTFACES = 3
	ST_NUMTURNFACES = 2
	ST_NUMSPECIALFACES = 3
	ST_FACESTRIDE = ST_NUMSTRAIGHTFACES + ST_NUMTURNFACES + ST_NUMSPECIALFACES
	ST_NUMEXTRAFACES = 2
	ST_NUMFACES = ST_FACESTRIDE * ST_NUMPAINFACES + ST_NUMEXTRAFACES
	ST_TURNOFFSET = ST_NUMSTRAIGHTFACES
	ST_OUCHOFFSET = ST_TURNOFFSET + ST_NUMTURNFACES
	ST_EVILGRINOFFSET = ST_OUCHOFFSET + 1
	ST_RAMPAGEOFFSET = ST_EVILGRINOFFSET + 1
	ST_GODFACE = ST_NUMPAINFACES * ST_FACESTRIDE
	ST_DEADFACE = ST_GODFACE + 1
	ST_FACESX = 143
	ST_FACESY = 168
	ST_EVILGRINCOUNT = 2 * 35
	ST_STRAIGHTFACECOUNT = 35 // 2
	ST_TURNCOUNT = 35
	ST_OUCHCOUNT = 35
	ST_RAMPAGEDELAY = 2 * 35
	ST_MUCHPAIN = 20
	ST_AMMOWIDTH = 3
	ST_AMMOX = 44
	ST_AMMOY = 171
	ST_HEALTHX = 90
	ST_HEALTHY = 171
	ST_ARMSX = 111
	ST_ARMSY = 172
	ST_ARMSBGX = 104
	ST_ARMSBGY = 168
	ST_ARMSXSPACE = 12
	ST_ARMSYSPACE = 10
	ST_FRAGSX = 138
	ST_FRAGSY = 171
	ST_FRAGSWIDTH = 2
	ST_ARMORX = 221
	ST_ARMORY = 171
	ST_KEY0WIDTH = 8
	ST_KEY0X = 239
	ST_KEY0Y = 171
	ST_KEY1WIDTH = ST_KEY0WIDTH
	ST_KEY1X = 239
	ST_KEY1Y = 181
	ST_KEY2WIDTH = ST_KEY0WIDTH
	ST_KEY2X = 239
	ST_KEY2Y = 191
	ST_AMMO0WIDTH = 3
	ST_AMMO0X = 288
	ST_AMMO0Y = 173
	ST_AMMO1WIDTH = ST_AMMO0WIDTH
	ST_AMMO1X = 288
	ST_AMMO1Y = 179
	ST_AMMO2WIDTH = ST_AMMO0WIDTH
	ST_AMMO2X = 288
	ST_AMMO2Y = 191
	ST_AMMO3WIDTH = ST_AMMO0WIDTH
	ST_AMMO3X = 288
	ST_AMMO3Y = 185
	ST_MAXAMMO0WIDTH = 3
	ST_MAXAMMO0X = 314
	ST_MAXAMMO0Y = 173
	ST_MAXAMMO1WIDTH = ST_MAXAMMO0WIDTH
	ST_MAXAMMO1X = 314
	ST_MAXAMMO1Y = 179
	ST_MAXAMMO2WIDTH = ST_MAXAMMO0WIDTH
	ST_MAXAMMO2X = 314
	ST_MAXAMMO2Y = 191
	ST_MAXAMMO3WIDTH = ST_MAXAMMO0WIDTH
	ST_MAXAMMO3X = 314
	ST_MAXAMMO3Y = 185
	ST_MSGWIDTH = 52
	MAXHEALTH = 100
	VIEWHEIGHT = 41 * FRACUNIT
	MAPBLOCKUNITS = 128
	MAPBLOCKSIZE = MAPBLOCKUNITS * FRACUNIT
	MAPBLOCKSHIFT = FRACBITS + 7
	MAPBMASK = MAPBLOCKSIZE - 1
	MAPBTOFRAC = MAPBLOCKSHIFT - FRACBITS
	PLAYERRADIUS = 16 * FRACUNIT
	MAXRADIUS = 32 * FRACUNIT
	GRAVITY = FRACUNIT
	MAXMOVE = 30 * FRACUNIT
	USERANGE = 64 * FRACUNIT
	MELEERANGE = 64 * FRACUNIT
	MISSILERANGE = 32 * 64 * FRACUNIT
	BASETHRESHOLD = 100
	STARTREDPALS = 1
	STARTBONUSPALS = 9
	NUMREDPALS = 8
	NUMBONUSPALS = 4
	RADIATIONPAL = 13
	DEVMAPS = "devmaps"
	DEVDATA = "devdata"
	NUM_QUITMESSAGES = 22
	SKYFLATNAME = "F_SKY1"
	ANGLETOSKYSHIFT = 22
	FF_FULLBRIGHT = 0x8000
	FF_FRAMEMASK = 0x7fff
	SIL_NONE = 0
	SIL_BOTTOM = 1
	SIL_TOP = 2
	SIL_BOTH = 3
	GLOWSPEED = 8
	STROBEBRIGHT = 5
	FASTDARK = 15
	SLOWDARK = 35
	PLATWAIT = 3
	PLATSPEED = FRACUNIT
	MAXPLATS = 30
	VDOORSPEED = FRACUNIT * 2
	VDOORWAIT = 150
	CEILSPEED = FRACUNIT
	CEILWAIT = 150
	MAXCEILINGS = 30
	FLOORSPEED = FRACUNIT
	FLOATSPEED = FRACUNIT * 4
	ONFLOORZ = Int32::MIN
	ONCEILINGZ = Int32::MAX
	PT_ADDLINES = 1
	PT_ADDTHINGS = 2
	PT_EARLYOUT = 4
	CENTERY = SCREENHEIGHT // 2
	MAXARGVS = 100
	TEXTSPEED = 3
	TEXTWAIT = 250
	QUEUESIZE = 128
	IPPORT_USERRESERVED = 5000
	SKULLXOFF = -32
	STRING_VALUE = 0xffff
	FATSPREAD = ANG90 // 8
	SKULLSPEED = 20 * FRACUNIT
	BONUSADD = 6
	STOPSPEED = 0x1000
	FRICTION = 0xe800
	LOWERSPEED = FRACUNIT * 6
	RAISESPEED = FRACUNIT * 6
	WEAPONBOTTOM = 128 * FRACUNIT
	WEAPONTOP = 32 * FRACUNIT
	BFGCELLS = 40
	INVERSECOLORMAP = 32
	MAXBOB = 0x100000
	ANG5 = ANG90 // 18
	HEIGHTBITS = 12
	HEIGHTUNIT = 1 << HEIGHTBITS
	MINZ = FRACUNIT * 4
	BASEYCENTER = 100
	S_PITCH_PERTURB = 1
	S_STEREO_SWING = 96 * 0x10000
	S_IFRACVOL = 30
	NA = 0
	S_NUMCHANNELS = 2
	INITSCALEMTOF = (0.2 * FRACUNIT)
	F_PANINC = 4
	M_ZOOMIN = (1.02 * FRACUNIT).to_i32
	M_ZOOMOUT = (FRACUNIT / 1.02).to_i32
	LINE_NEVERSEE = 128
	NUMPLYRLINES = 7
	NUMCHEATPLYLINES = 16
	NUMTRIANGLEGUYLINES = 3
	NUMTHINTRIANGLEGUYLINES = 3
	ANGLETOFINESHIFT = 19
	VIEWANGLETOX_SIZE = FINEANGLES // 2
	XTOVIEWANGLE_SIZE = SCREENWIDTH + 1
	LIGHTLEVELS = 16
	LIGHTSEGSHIFT = 4
	MAXLIGHTSCALE = 48
	LIGHTSCALESHIFT = 12
	MAXLIGHTZ = 128
	LIGHTZSHIFT = 20
	NUMCOLORMAPS = 32
	MAXWIDTH = 1120
	MAXHEIGHT = 832
	SBARHEIGHT = 32
	FUZZTABLE = 50
	FUZZOFF = SCREENWIDTH
	FIELDOFVIEW = 2048
	DISTMAP = 2
	S_MAX_VOLUME = 127
	S_CLIPPING_DIST = 1200 * 0x10000
	S_CLOSE_DIST = 160 * 0x10000
	S_ATTENUATOR = (S_CLIPPING_DIST - S_CLOSE_DIST) >> FRACBITS
	NORM_PITCH = 128
	NORM_PRIORITY = 64
	NORM_SEP = 128
	enum Bwhere
		Top
		Middle
		Bottom
	end

	enum Platenum
		Up
		Down
		Waiting
		InStasis
	end

	enum Plattype
		PerpetualRaise
		DownWaitUpStay
		RaiseAndChange
		RaiseToNearestAndChange
		BlazeDWUS
	end

	enum Vldoorenum
		DoorNormal
		Close30ThenOpen
		DoorClose
		DoorOpen
		RaiseIn5Mins
		BlazeRaise
		BlazeOpen
		BlazeClose
	end

	enum Ceilingenum
		LowerToFloor
		RaiseToHighest
		LowerAndCrush
		CrushAndRaise
		FastCrushAndRaise
		SilentCrushAndRaise
	end

	enum Floorenum
		LowerFloor
		LowerFloorToLowest
		TurboLower
		RaiseFloor
		RaiseFloorToNearest
		RaiseToTexture
		LowerAndChange
		RaiseFloor24
		RaiseFloor24AndChange
		RaiseFloorCrush
		RaiseFloorTurbo
		DonutRaise
		RaiseFloor512
	end

	enum Stairenum
		Build8
		Turbo16
	end

	enum Result
		Ok
		Crushed
		Pastdest
	end

	enum Buttoncode
		BT_ATTACK = 1
		BT_USE = 2
		BT_SPECIAL = 128
		BT_SPECIALMASK = 3
		BT_CHANGE = 4
		BT_WEAPONMASK = 8 + 16 + 32
		BT_WEAPONSHIFT = 3
		BTS_PAUSE = 1
		BTS_SAVEGAME = 2
		BTS_SAVEMASK = 4 + 8 + 16
		BTS_SAVESHIFT = 2
	end

	enum ST_Statenum
		AutomapState
		FirstPersonState
	end

	enum ST_Chatstateenum
		StartChatState
		WaitDestState
		GetChatState
	end

	@[Flags]
	enum Mobjflag
		MF_SPECIAL
		MF_SOLID
		MF_SHOOTABLE
		MF_NOSECTOR
		MF_NOBLOCKMAP
		MF_AMBUSH
		MF_JUSTHIT
		MF_JUSTATTACKED
		MF_SPAWNCEILING
		MF_NOGRAVITY
		MF_DROPOFF = 0x400
		MF_PICKUP = 0x800
		MF_NOCLIP = 0x1000
		MF_SLIDE = 0x2000
		MF_FLOAT = 0x4000
		MF_TELEPORT = 0x8000
		MF_MISSILE = 0x10000
		MF_DROPPED = 0x20000
		MF_SHADOW = 0x40000
		MF_NOBLOOD = 0x80000
		MF_CORPSE = 0x100000
		MF_INFLOAT = 0x200000
		MF_COUNTKILL = 0x400000
		MF_COUNTITEM = 0x800000
		MF_SKULLFLY = 0x1000000
		MF_NOTDMATCH = 0x2000000
		MF_TRANSLATION = 0xc000000
		MF_TRANSSHIFT = 26
	end

	enum Psprnum
		Weapon
		Flash
		NUMPSPRITES
	end

	enum Playerstate
		PST_LIVE
		PST_DEAD
		PST_REBORN
	end

	@[Flags]
	enum Cheat
		CF_NOCLIP
		CF_GODMODE
		CF_NOMOMENTUM
		CF_ME
	end

	enum Command
		SEND = 1
		GET = 2
	end

	enum Slopetype
		HORIZONTAL
		VERTICAL
		POSITIVE
		NEGATIVE
	end

	enum Stateenum
		NoState = -1
		StatCount
		ShowNextLoc
	end

	enum Mainenum
		Newgame
		Options
		Loadgame
		Savegame
		Readthis
		Quitdoom
		MainEnd
	end

	enum Episodesenum
		Ep1
		Ep2
		Ep3
		Ep4
		EpEnd
	end

	enum NewgameEnum
		Killthings
		Toorough
		Hurtme
		Violence
		Nightmare
		NewgEnd
	end

	enum OptionsEnum
		Endgame
		Messages
		Scrnsize
		Optionempty1
		Mousesensitivity
		Optionempty2
		Soundvol
		More
		OptEnd
	end

	enum MouseoptionsEnum
		Mousemov
		Mousesens
		Mouseoptionempty1
		MouseOptEnd
	end

	enum Readenum
		Rdthsempty1
		Read1End
	end

	enum Read2enum
		Rdthsempty2
		Read2End
	end

	enum Soundenum
		Sfxvol
		Sfxempty1
		Musicvol
		Sfxempty2
		SoundEnd
	end

	enum Loadenum
		Load1
		Load2
		Load3
		Load4
		Load5
		Load6
		LoadEnd
	end

	enum Dirtype
		East
		NorthEast
		North
		NorthWest
		West
		SouthWest
		South
		SouthEast
		NoDir
		NUMDIRS
	end

	enum Thinkerclass : UInt8
		End
		Mobj
	end

	enum Specials : UInt8
		Ceiling
		Door
		Floor
		Plat
		Flash
		Strobe
		Glow
		End
	end

	enum Animenum
		Always
		Random
		Level
	end

	HUSTR_KEYGREEN = 'g'
	HUSTR_KEYINDIGO = 'i'
	HUSTR_KEYBROWN = 'b'
	HUSTR_KEYRED = 'r'

	class Cheatseq
		property sequence : UInt8*
		property p : UInt8*

		def initialize(@sequence : UInt8*, @p : UInt8*)
		end
	end

	class Spriteframe
		property rotate : Int32 = -1
		getter lump : Array(Int16) = Array.new(8, -1_i16)
		getter flip : Array(UInt8) = Array.new(8, 0xff_u8)
	end

	DOOM_SAMPLERATE = 11025
	DOOM_MIDI_RATE = 140
	DOOM_FLAG_HIDE_MOUSE_OPTIONS = 1
	DOOM_FLAG_HIDE_SOUND_OPTIONS = 2
	DOOM_FLAG_HIDE_MUSIC_OPTIONS = 4
	DOOM_FLAG_MENU_DARKEN_BG = 8

	VERSION = 110
	BASE_WIDTH = 320
	SCREEN_MUL = 1
	INV_ASPECT_RATIO = 0.625
	SCREENWIDTH = 320
	SCREENHEIGHT = 200
	MAXPLAYERS = 4

	MTF_EASY = 1
	MTF_NORMAL = 2
	MTF_HARD = 4
	MTF_AMBUSH = 8

	{% if flag?(:DOOM_FAST_TICK) %}
		TICKMUL = 2
	{% else %}
		TICKMUL = 1
	{% end %}
	TICRATE = 35 * TICKMUL

	enum GameMode
		Shareware
		Registered
		Commercial
		Retail
		Indetermined
	end

	enum GameMission
		Doom
		Doom2
		PackTnt
		PackPlut
		None
	end

	enum Language
		English
		French
		German
		Unknown
	end

	enum Gamestate
		Needwipe = -1
		Level
		Intermission
		Finale
		Demoscreen
	end

	enum Skill
		Baby
		Easy
		Medium
		Hard
		Nightmare
	end

	enum Card
		Bluecard
		Yellowcard
		Redcard
		Blueskull
		Yellowskull
		Redskull
		NUMCARDS
	end

	enum Weapontype
		Fist
		Pistol
		Shotgun
		Chaingun
		Missile
		Plasma
		Bfg
		Chainsaw
		Supershotgun
		NUMWEAPONS
		Nochange
	end

	enum Ammotype
		Clip
		Shell
		Cell
		Misl
		OG_NumAmmo
		Noammo
		NUMAMMO
	end

	enum Powertype
		Invulnerability
		Strength
		Invisibility
		Ironfeet
		Allmap
		Infrared
		NUMPOWERS
	end

	enum Powerduration
		INVULNTICS = 30 * TICRATE
		INVISTICS = 60 * TICRATE
		INFRATICS = 120 * TICRATE
		IRONTICS = 60 * TICRATE
	end

	enum Evtype
		Keydown
		Keyup
		Mouse
		Joystick
	end

	enum Gameaction
		Nothing
		Loadlevel
		Newgame
		Loadgame
		Savegame
		Playdemo
		Completed
		Victory
		Worlddone
		Screenshot
	end

	class Islope
		property slp : Int32
		property islp : Int32

		def initialize(@slp : Int32 = 0, @islp : Int32 = 0)
		end
	end

	class Fpoint
		property x : Int32
		property y : Int32

		def initialize(@x : Int32 = 0, @y : Int32 = 0)
		end
	end

	class Fline
		property a : Fpoint?
		property b : Fpoint?

		def initialize(@a : Fpoint? = nil, @b : Fpoint? = nil)
		end
	end

	class Mpoint
		property x : Int32
		property y : Int32

		def initialize(@x : Int32 = 0, @y : Int32 = 0)
		end
	end

	class Mline
		property a : Mpoint?
		property b : Mpoint?

		def initialize(@a : Mpoint? = nil, @b : Mpoint? = nil)
		end
	end

	@@player_arrow : Array(Mline) = Array.new(7) { Mline.new(Mpoint.new, Mpoint.new) }
	@@cheat_player_arrow : Array(Mline) = Array.new(16) { Mline.new(Mpoint.new, Mpoint.new) }
	@@triangle_guy : Array(Mline) = Array.new(3) { Mline.new(Mpoint.new, Mpoint.new) }
	@@thintriangle_guy : Array(Mline) = Array.new(3) { Mline.new(Mpoint.new, Mpoint.new) }
	@@markpoints : Array(Mpoint) = Array.new(10) { Mpoint.new(-1, -1) }
	@@m_paninc = Mpoint.new
	@@f_oldloc = Mpoint.new

	class Point
		property x : Int32
		property y : Int32

		def initialize(@x : Int32 = 0, @y : Int32 = 0)
		end
	end

	class Castinfo
		property name : String
		property type : Doocr::Mobjtype

		def initialize(@name : String = "", @type : Doocr::Mobjtype = Doocr::Mobjtype::MT_PLAYER)
		end
	end

	class Name8
		property s : StaticArray(UInt8, 9)

		def initialize
			@s = StaticArray(UInt8, 9).new(0_u8)
		end

		def x : StaticArray(Int32, 2)
			words = StaticArray(Int32, 2).new(0)
			2.times do |word|
				offset = word * 4
				words[word] = @s[offset].to_i32 |
											(@s[offset + 1].to_i32 << 8) |
											(@s[offset + 2].to_i32 << 16) |
											(@s[offset + 3].to_i32 << 24)
			end
			words
		end
	end

	class MusHeader
		getter id : String
		getter score_len : UInt16
		getter score_start : UInt16
		getter channels : UInt16
		getter sec_channels : UInt16
		getter instr_cnt : UInt16
		getter dummy : UInt16

		def initialize
			@id = ""
			@score_len = 0_u16
			@score_start = 0_u16
			@channels = 0_u16
			@sec_channels = 0_u16
			@instr_cnt = 0_u16
			@dummy = 0_u16
		end

		def read(data : UInt8*)
			@id = String.new(data, 4)
			@score_len = data[4].to_u16 | (data[5].to_u16 << 8)
			@score_start = data[6].to_u16 | (data[7].to_u16 << 8)
			@channels = data[8].to_u16 | (data[9].to_u16 << 8)
			@sec_channels = data[10].to_u16 | (data[11].to_u16 << 8)
			@instr_cnt = data[12].to_u16 | (data[13].to_u16 << 8)
			@dummy = data[14].to_u16 | (data[15].to_u16 << 8)
		end
	end

	class Animdef
		property istexture : Int32
		property endname : String
		property startname : String
		property speed : Int32

		def initialize(@istexture : Int32 = -1, @endname : String = "", @startname : String = "", @speed : Int32 = -1)
		end
	end

	class Wbplayer
		property in : Int32
		property skills : Int32
		property sitems : Int32
		property ssecret : Int32
		property stime : Int32
		property frags : StaticArray(Int32, 4)
		property score : Int32

		def initialize
			@in = 0
			@skills = 0
			@sitems = 0
			@ssecret = 0
			@stime = 0
			@frags = StaticArray(Int32, 4).new(0)
			@score = 0
		end
	end

	class Wbstart
		property epsd : Int32
		property didsecret : Int32
		property last : Int32
		property next : Int32
		property maxkills : Int32
		property maxitems : Int32
		property maxsecret : Int32
		property maxfrags : Int32
		property partime : Int32
		property pnum : Int32
		property plyr : Array(Wbplayer)

		def initialize
			@epsd = 0
			@didsecret = 0
			@last = 0
			@next = 0
			@maxkills = 0
			@maxitems = 0
			@maxsecret = 0
			@maxfrags = 0
			@partime = 0
			@pnum = 0
			@plyr = Array.new(CDoom::MAXPLAYERS) { Wbplayer.new }
		end
	end

	class Wadinfo
		getter identification : String
		property numlumps : Int32
		property infotableofs : Int32

		def initialize
			@identification = ""
			@numlumps = 0
			@infotableofs = 0
		end

		def read(data : UInt8*)
			@identification = String.new(data, 4)
			@numlumps = read_i32(data + 4)
			@infotableofs = read_i32(data + 8)
		end

		private def read_i32(data : UInt8*) : Int32
			data[0].to_i32 |
				(data[1].to_i32 << 8) |
				(data[2].to_i32 << 16) |
				(data[3].to_i32 << 24)
		end
	end

	class Lumpinfo
		property name : String
		property handle : File?
		property position : Int32
		property size : Int32

		def initialize(@name : String = "", @handle : File? = nil, @position : Int32 = 0, @size : Int32 = 0)
		end
	end

	class Switchlist
		property name1 : String
		property name2 : String
		property episode : Int32

		def initialize(@name1 : String = "", @name2 : String = "", @episode : Int32 = 0)
		end
	end

	class Button
		property line : Pointer(CDoom::Line)?
		property where : Doocr::Bwhere
		property btexture : Int32
		property btimer : Int32
		property soundorg : Pointer(Void)?

		def initialize
			@line = nil
			@where = Doocr::Bwhere::Top
			@btexture = 0
			@btimer = 0
			@soundorg = nil
		end

		def reset
			@line = nil
			@where = Doocr::Bwhere::Top
			@btexture = 0
			@btimer = 0
			@soundorg = nil
		end
	end

	class Default
		property name : String
		property location : Pointer(Int32)?
		property defaultvalue : Int32
		property scantranslate : Int32
		property untranslated : Int32
		property text_location : Pointer(UInt8*)?
		property default_text_value : String

		def initialize(@name : String = "", @location : Pointer(Int32)? = nil, @defaultvalue : Int32 = 0,
						 @scantranslate : Int32 = 0, @untranslated : Int32 = 0,
						 @text_location : Pointer(UInt8*)? = nil, @default_text_value : String = "")
		end
	end

	class Musicinfo
		property name : String
		property lumpnum : Int32
		property data : Void*
		property handle : Int32

		def initialize(@name : String = "", @lumpnum : Int32 = 0, @data : Void* = Pointer(Void).null, @handle : Int32 = 0)
		end

	end

	class AnimWIStuff
		property type : Doocr::Animenum
		property period : Int32
		property nanims : Int32
		property loc : Point
		property data1 : Int32
		property data2 : Int32
		property p : Array(Pointer(CDoom::Patch))
		property nexttic : Int32
		property lastdrawn : Int32
		property ctr : Int32
		property state : Int32

		def initialize(@type : Doocr::Animenum = Doocr::Animenum::Always, @period : Int32 = 0,
						 @nanims : Int32 = 0, @loc : Point = Point.new, @data1 : Int32 = 0,
						 @data2 : Int32 = 0, @p : Array(Pointer(CDoom::Patch)) = Array.new(3) { Pointer(CDoom::Patch).null },
						 @nexttic : Int32 = 0, @lastdrawn : Int32 = 0, @ctr : Int32 = 0, @state : Int32 = 0)
		end
	end

	@@s_music : Array(Musicinfo) = [] of Musicinfo
	@@mus_playing_s_sound : Musicinfo?
	@@anims_wi_stuff : Array(Array(AnimWIStuff)) = [] of Array(AnimWIStuff)
	@@numanims : Array(Int32) = [] of Int32

	class_property gameaction : Doocr::Gameaction = Doocr::Gameaction::Nothing
	class_property gamestate : Doocr::Gamestate = Doocr::Gamestate::Demoscreen
	class_property gamemode : Doocr::GameMode = Doocr::GameMode::Indetermined
	class_property gamemission : Doocr::GameMission = Doocr::GameMission::None
	class_property gameskill : Doocr::Skill = Doocr::Skill::Medium
	class_property gameepisode : Int32 = 1
	class_property gamemap : Int32 = 1
	class_property paused : Int32 = 0
	class_property netgame : Int32 = 0
	class_property deathmatch : Int32 = 0
	class_property respawnmonsters : Int32 = 0
	class_property autostart : Int32 = 0
	class_property startskill : Doocr::Skill = Doocr::Skill::Medium
	class_property startepisode : Int32 = 1
	class_property startmap : Int32 = 1
	class_property nomonsters : Int32 = 0
	class_property respawnparm : Int32 = 0
	class_property fastparm : Int32 = 0
	class_property devparm : Int32 = 0
	class_property modifiedgame : Int32 = 0
	class_property language : Doocr::Language = Doocr::Language::English
	class_property statusbaractive : Int32 = 0
	class_property automapactive : Int32 = 0
	class_property menuactive : Int32 = 0
	class_property viewactive : Int32 = 0
	class_property nodrawers : Int32 = 0
	class_property noblit : Int32 = 0
	class_property totalkills : Int32 = 0
	class_property totalitems : Int32 = 0
	class_property totalsecret : Int32 = 0
	class_property levelstarttic : Int32 = 0
	class_property leveltime : Int32 = 0
	class_property gametic : Int32 = 0
	class_property demosequence : Int32 = 0
	class_property pagetic : Int32 = 0
	class_property inhelpscreens : Int32 = 0
	class_property go : Int32 = 0
	class_property traceangle : UInt32 = 0
	class_property t2x : Int32 = 0
	class_property t2y : Int32 = 0
	class_property usergame : Int32 = 0
	class_property demoplayback : Int32 = 0
	class_property demorecording : Int32 = 0
	class_property singledemo : Int32 = 0
	class_property consoleplayer : Int32 = 0
	class_property displayplayer : Int32 = 0
	class_property viewangleoffset : Int32 = 0
	class_property viewwindowx : Int32 = 0
	class_property viewwindowy : Int32 = 0
	class_property viewheight : Int32 = 200
	class_property viewwidth : Int32 = 320
	class_property scaledviewwidth : Int32 = 320
	class_property st_oldhealth : Int32 = -1
	class_property st_facecount : Int32 = 0
	class_property st_faceindex : Int32 = 0
	class_property st_palette : Int32 = 0
	class_property st_stopped : Int32 = 1
	class_property snl_pointeron : Int32 = 0
	class_property floatok : Int32 = 0
	class_property secretexit : Int32 = 0
	class_property d_episode : Int32 = 0
	class_property d_map : Int32 = 0
	class_property tmflags : Int32 = 0
	class_property la_damage : Int32 = 0
	class_property crushchange : Int32 = 0
	class_property bombdamage : Int32 = 0
	class_property earlyout : Int32 = 0
	class_property ptflags : Int32 = 0
	class_property onground : Int32 = 0
	class_property numlinespecials : Int32 = 0
	class_property numswitches : Int32 = 0
	class_property lastflat : Int32 = 0
	class_property fuzzpos : Int32 = 0
	class_property maxframe : Int32 = 0
	class_property audio_flag : Int32 = 0
	class_property mus_offset : Int32 = 0
	class_property mus_delay : Int32 = 0
	class_property mus_playing : Int32 = 0
	class_property mus_volume : Int32 = 0
	class_property looping : Int32 = 0
	class_property musicdies : Int32 = 0
	class_property mus_paused : Int32 = 0
	class_property nextcleanup : Int32 = 0
	class_property nofit : Int32 = 0
	class_property mus_loop : Int32 = 0
	class_getter mus_channel_volumes : Array(Int32) = Array.new(16, 0)
	class_getter channelstart : Array(Int32) = Array.new(Doocr::NUM_CHANNELS, 0)
	class_getter channelhandles : Array(Int32) = Array.new(Doocr::NUM_CHANNELS, 0)
	class_getter channelids : Array(Int32) = Array.new(Doocr::NUM_CHANNELS, 0)
	class_getter channelstep : Array(UInt32) = Array.new(Doocr::NUM_CHANNELS, 0_u32)
	class_getter channelstepremainder : Array(UInt32) = Array.new(Doocr::NUM_CHANNELS, 0_u32)
	class_getter channelsend : Array(UInt8*) = Array.new(Doocr::NUM_CHANNELS, Pointer(UInt8).null)
	class_getter steptable : Array(Int32) = Array.new(256, 0)
	class_getter vol_lookup : Array(Int32) = Array.new(32768, 0)
	class_getter channelleftvol_lookup : Array(Int32*) = Array.new(Doocr::NUM_CHANNELS, Pointer(Int32).null)
	class_getter channelrightvol_lookup : Array(Int32*) = Array.new(Doocr::NUM_CHANNELS, Pointer(Int32).null)
	class_getter viewangletox : Array(Int32) = Array.new(Doocr::VIEWANGLETOX_SIZE, 0)
	class_getter floorclip : Array(Int16) = Array.new(320, 0_i16)
	class_getter ceilingclip : Array(Int16) = Array.new(320, 0_i16)
	class_getter negonearray : Array(Int16) = Array.new(320, 0_i16)
	class_getter screenheightarray : Array(Int16) = Array.new(320, 0_i16)
	class_getter columnofs : Array(Int32) = Array.new(1120, 0)
	class_getter fuzzoffset : Array(Int32) = Array.new(50, 0)
	class_getter spanstart : Array(Int32) = Array.new(832, 0)
	class_getter spanstop : Array(Int32) = Array.new(832, 0)
	class_getter mixbuffer : Array(Int16) = Array.new(2048, 0_i16)
	class_property chat_on : Int32 = 0
	class_property always_off : Int32 = 0
	class_property st_firsttime : Int32 = 0
	class_property veryfirsttime : Int32 = 0
	class_property lu_palette : Int32 = 0
	class_property st_clock : UInt32 = 0
	class_property st_msgcounter : Int32 = 0
	class_property st_randomnumber : Int32 = 0
	class_property st_chat : Int32 = 0
	class_property st_oldchat : Int32 = 0
	class_property st_cursoron : Int32 = 0
	class_property st_statusbaron : Int32 = 0
	class_property st_chatstate : Doocr::ST_Chatstateenum = Doocr::ST_Chatstateenum::StartChatState
	class_property st_gamestate : Doocr::ST_Statenum = Doocr::ST_Statenum::FirstPersonState
	class_property wipegamestate : Doocr::Gamestate = Doocr::Gamestate::Demoscreen
	class_property show_messages : Int32 = 1
	class_property is_wiping_screen : Int32 = 0
	class_property st_notdeathmatch : Int32 = 0
	class_property st_armson : Int32 = 0
	class_property st_fragson : Int32 = 0
	class_property st_fragscount : Int32 = 0

	def self.st_faceindex_ptr : Int32*
		pointerof(@@st_faceindex)
	end

	def self.snd_music_volume_ptr : Int32*
		pointerof(@@snd_music_volume)
	end

	def self.show_messages_ptr : Int32*
		pointerof(@@show_messages)
	end


	def self.chat_on_ptr : Int32*
		pointerof(@@chat_on)
	end

	def self.always_off_ptr : Int32*
		pointerof(@@always_off)
	end

	def self.st_notdeathmatch_ptr : Int32*
		pointerof(@@st_notdeathmatch)
	end

	def self.st_armson_ptr : Int32*
		pointerof(@@st_armson)
	end

	def self.st_fragson_ptr : Int32*
		pointerof(@@st_fragson)
	end

	def self.st_fragscount_ptr : Int32*
		pointerof(@@st_fragscount)
	end

	def self.st_statusbaron_ptr : Int32*
		pointerof(@@st_statusbaron)
	end

	macro crystal_int_state(*names)
		{% for name in names %}
			@@{{name.id}} : Int32 = 0
			def self.{{name.id}}; @@{{name.id}}; end
			def self.{{name.id}}=(value : Int32); @@{{name.id}} = value; end
		{% end %}
	end

	crystal_int_state key_right, key_left, key_up, key_down, key_strafeleft, key_straferight,
		key_fire, key_use, key_strafe, key_speed, mousebfire, mousebstrafe, mousebforward,
		mousemove, joybfire, joybstrafe, joybuse, joybspeed, savegameslot, save_string_enter,
		save_slot, screenblocks, detail_level, screen_size, quick_save_slot

	class_property centerx : Int32 = 0
	class_property centery : Int32 = 0
	class_property centerxfrac : Int32 = 0
	class_property centeryfrac : Int32 = 0
	class_property validcount : Int32 = 0
	class_property linecount : Int32 = 0
	class_property loopcount : Int32 = 0
	class_property extralight : Int32 = 0
	class_property framecount : Int32 = 0
	class_property dccount : Int32 = 0
	class_property dscount : Int32 = 0
	class_property lightlev : Int32 = 0
	class_property amclock : Int32 = 0
	class_property cheating : Int32 = 0
	class_property grid : Int32 = 0
	class_property leveljuststarted : Int32 = 0
	class_property finit_width : Int32 = 320
	class_property finit_height : Int32 = 168
	class_property f_x : Int32 = 0
	class_property f_y : Int32 = 0
	class_property f_w : Int32 = 320
	class_property f_h : Int32 = 168
	class_property markpointnum : Int32 = 0
	class_property followplayer : Int32 = 1
	class_property stopped : Int32 = 1
	class_property reloadlump : Int32 = 0
	class_property reloadname : String = ""
	class_property numlumps : Int32 = 0
	class_getter lumpcache : Array(Pointer(Void)) = [] of Pointer(Void)
	class_property rejectmatrix : Pointer(UInt8) = Pointer(UInt8).null
	class_property blockmaplump : Pointer(Int16) = Pointer(Int16).null
	class_property blockmap : Pointer(Int16) = Pointer(Int16).null
	class_property rw_w : Int32 = 0
	class_property rw_stopx : Int32 = 0
	class_property segtextured : Int32 = 0
	class_property markfloor : Int32 = 0
	class_property markceiling : Int32 = 0
	class_property maskedtexture : Int32 = 0
	class_property toptexture : Int32 = 0
	class_property bottomtexture : Int32 = 0
	class_property midtexture : Int32 = 0
	class_property skymap : Int32 = 0
	class_property dc_x : Int32 = 0
	class_property dc_yl : Int32 = 0
	class_property dc_yh : Int32 = 0
	class_property dc_iscale : Int32 = 0
	class_property dc_texturemid : Int32 = 0
	class_property ds_y : Int32 = 0
	class_property ds_x1 : Int32 = 0
	class_property ds_x2 : Int32 = 0
	class_property ds_xfrac : Int32 = 0
	class_property ds_yfrac : Int32 = 0
	class_property ds_xstep : Int32 = 0
	class_property ds_ystep : Int32 = 0
	class_property viewx : Int32 = 0
	class_property viewy : Int32 = 0
	class_property viewz : Int32 = 0
	class_property viewangle : UInt32 = 0
	class_property clipangle : UInt32 = 0
	class_property rw_distance : Int32 = 0
	class_property rw_normalangle : UInt32 = 0
	class_property rw_angle1 : UInt32 = 0
	class_property sscount : Int32 = 0
	class_property viewcos : Int32 = 0
	class_property viewsin : Int32 = 0
	class_property projection : Int32 = 0
	class_property planeheight : Int32 = 0
	class_property rw_x : Int32 = 0
	class_property rw_centerangle : UInt32 = 0
	class_property rw_offset : Int32 = 0
	class_property rw_scalestep : Int32 = 0
	class_property rw_midtexturemid : Int32 = 0
	class_property rw_toptexturemid : Int32 = 0
	class_property rw_bottomtexturemid : Int32 = 0
	class_property worldtop : Int32 = 0
	class_property worldbottom : Int32 = 0
	class_property worldhigh : Int32 = 0
	class_property worldlow : Int32 = 0
	class_property rw_scale : Int32 = 0
	class_property pixhigh : Int32 = 0
	class_property pixlow : Int32 = 0
	class_property pixhighstep : Int32 = 0
	class_property pixlowstep : Int32 = 0
	class_property topfrac : Int32 = 0
	class_property topstep : Int32 = 0
	class_property bottomfrac : Int32 = 0
	class_property bottomstep : Int32 = 0
	class_property spryscale : Int32 = 0
	class_property sprtopscreen : Int32 = 0
	class_property pspritescale : Int32 = 0
	class_property pspriteiscale : Int32 = 0
	class_getter gammatable : Array(Array(UInt8)) = Array.new(5) { Array.new(256, 0_u8) }
	class_getter maxammo : Array(Int32) = Array.new(Doocr::Ammotype::NUMAMMO.value, 0)
	class_getter clipammo : Array(Int32) = Array.new(Doocr::Ammotype::NUMAMMO.value, 0)
	class_getter texturetranslation : Array(Int32) = [] of Int32
	class_getter flattranslation : Array(Int32) = [] of Int32
	class_getter texturewidthmask : Array(Int32) = [] of Int32
	class_getter texturecompositesize : Array(Int32) = [] of Int32
	class_getter texturecolumnlump : Array(Int16*) = [] of Int16*
	class_getter texturecolumnofs : Array(UInt16*) = [] of UInt16*
	class_getter texturecomposite : Array(UInt8*) = [] of UInt8*
	class_getter textureheight : Array(Int32) = [] of Int32
	class_getter ylookup : Array(UInt8*) = Array.new(832, Pointer(UInt8).null)
	class_getter yslope : Array(Int32) = Array.new(832, 0)
	class_getter distscale : Array(Int32) = Array.new(320, 0)
	class_property basexscale : Int32 = 0
	class_property baseyscale : Int32 = 0
	class_getter cachedheight : Array(Int32) = Array.new(832, 0)
	class_getter cacheddistance : Array(Int32) = Array.new(832, 0)
	class_getter cachedxstep : Array(Int32) = Array.new(832, 0)
	class_getter cachedystep : Array(Int32) = Array.new(832, 0)
	class_property walllights : Pointer(Pointer(UInt8)) = Pointer(Pointer(UInt8)).null
	class_property spritelights : Pointer(Pointer(UInt8)) = Pointer(Pointer(UInt8)).null
	class_property newvissprite : Int32 = 0
	class_property snd_music_volume : Int32 = 15
	class_property mus_data : UInt8* = Pointer(UInt8).null
	class_property queue_midi_head : Int32 = 0
	class_property queue_midi_tail : Int32 = 0
	class_property mb_used : Int32 = 12
	class_getter cheat_mus_storage : Array(Cheatseq) = [Cheatseq.new(Pointer(UInt8).null, Pointer(UInt8).null)]
	class_getter cheat_god_storage : Array(Cheatseq) = [Cheatseq.new(Pointer(UInt8).null, Pointer(UInt8).null)]
	class_getter cheat_ammo_storage : Array(Cheatseq) = [Cheatseq.new(Pointer(UInt8).null, Pointer(UInt8).null)]
	class_getter cheat_ammonokey_storage : Array(Cheatseq) = [Cheatseq.new(Pointer(UInt8).null, Pointer(UInt8).null)]
	class_getter cheat_noclip_storage : Array(Cheatseq) = [Cheatseq.new(Pointer(UInt8).null, Pointer(UInt8).null)]
	class_getter cheat_commercial_noclip_storage : Array(Cheatseq) = [Cheatseq.new(Pointer(UInt8).null, Pointer(UInt8).null)]
	class_getter cheat_choppers_storage : Array(Cheatseq) = [Cheatseq.new(Pointer(UInt8).null, Pointer(UInt8).null)]
	class_getter cheat_clev_storage : Array(Cheatseq) = [Cheatseq.new(Pointer(UInt8).null, Pointer(UInt8).null)]
	class_getter cheat_mypos_storage : Array(Cheatseq) = [Cheatseq.new(Pointer(UInt8).null, Pointer(UInt8).null)]
	class_getter cheat_amap_storage : Array(Cheatseq) = [Cheatseq.new(Pointer(UInt8).null, Pointer(UInt8).null)]
	class_getter cheat_me_storage : Array(Cheatseq) = [Cheatseq.new(Pointer(UInt8).null, Pointer(UInt8).null)]
	class_getter cheat_mus : Cheatseq = cheat_mus_storage[0]
	class_getter cheat_god : Cheatseq = cheat_god_storage[0]
	class_getter cheat_ammo : Cheatseq = cheat_ammo_storage[0]
	class_getter cheat_ammonokey : Cheatseq = cheat_ammonokey_storage[0]
	class_getter cheat_noclip : Cheatseq = cheat_noclip_storage[0]
	class_getter cheat_commercial_noclip : Cheatseq = cheat_commercial_noclip_storage[0]
	class_getter cheat_choppers : Cheatseq = cheat_choppers_storage[0]
	class_getter cheat_clev : Cheatseq = cheat_clev_storage[0]
	class_getter cheat_mypos : Cheatseq = cheat_mypos_storage[0]
	class_getter cheat_amap : Cheatseq = cheat_amap_storage[0]
	class_getter cheat_me : Cheatseq = cheat_me_storage[0]
	class_getter cheat_powerup : Array(Cheatseq) = Array.new(7) { Cheatseq.new(Pointer(UInt8).null, Pointer(UInt8).null) }
	class_getter sprtemp : Array(Spriteframe) = Array.new(29) { Spriteframe.new }
	class_getter rndtable : Array(Int32) = Array.new(256, 0)
	class_getter opposite : Array(Doocr::Dirtype) = Array.new(9, Doocr::Dirtype::NoDir)
	class_getter diags : Array(Doocr::Dirtype) = Array.new(4, Doocr::Dirtype::NoDir)
	class_getter xspeed : Array(Int32) = Array.new(8, 0)
	class_getter yspeed : Array(Int32) = Array.new(8, 0)
	class_getter checkcoord : Array(Array(Int32)) = Array.new(12) { Array.new(4, 0) }
	class_getter quitsounds : Array(Int32) = Array.new(8, 0)
	class_getter quitsounds2 : Array(Int32) = Array.new(8, 0)
	class_getter forwardmove : Array(Int32) = [0x19, 0x32]
	class_getter sidemove : Array(Int32) = [0x18, 0x28]
	class_getter angleturn : Array(Int32) = [640, 1280, 320]
	class_property opentop : Int32 = 0
	class_property openbottom : Int32 = 0
	class_property openrange : Int32 = 0
	class_property lowfloor : Int32 = 0
	class_property tmfloorz : Int32 = 0
	class_property tmceilingz : Int32 = 0
	class_property tmx : Int32 = 0
	class_property tmy : Int32 = 0
	class_property tmdropoffz : Int32 = 0
	class_property shootz : Int32 = 0
	class_property attackrange : Int32 = 0
	class_property aimslope : Int32 = 0
	class_property topslope : Int32 = 0
	class_property bottomslope : Int32 = 0
	class_property tmxmove : Int32 = 0
	class_property tmymove : Int32 = 0
	class_property swingx : Int32 = 0
	class_property swingy : Int32 = 0
	class_property bulletslope : Int32 = 0
	class_property sightzstart : Int32 = 0
	class_property bestslidefrac : Int32 = 0
	class_property secondslidefrac : Int32 = 0
	class_property bestslideline : Pointer(CDoom::Line) = Pointer(CDoom::Line).null
	class_property secondslideline : Pointer(CDoom::Line) = Pointer(CDoom::Line).null
	class_property slidemo : Pointer(CDoom::Mobj) = Pointer(CDoom::Mobj).null
	class_property bombsource : Pointer(CDoom::Mobj) = Pointer(CDoom::Mobj).null
	class_property bombspot : Pointer(CDoom::Mobj) = Pointer(CDoom::Mobj).null
	class_property ceilingline : Pointer(CDoom::Line) = Pointer(CDoom::Line).null
	class_property linetarget : Pointer(CDoom::Mobj) = Pointer(CDoom::Mobj).null
	class_property shootthing : Pointer(CDoom::Mobj) = Pointer(CDoom::Mobj).null
	class_property tmthing : Pointer(CDoom::Mobj) = Pointer(CDoom::Mobj).null
	class_getter tmbbox : Array(Int32) = Array.new(4, 0)
	class_property soundtarget : Pointer(CDoom::Mobj) = Pointer(CDoom::Mobj).null
	class_property corpsehit : Pointer(CDoom::Mobj) = Pointer(CDoom::Mobj).null
	class_property vileobj : Pointer(CDoom::Mobj) = Pointer(CDoom::Mobj).null
	class_property viletryx : Int32 = 0
	class_property viletryy : Int32 = 0
	class_getter braintargets : Array(Pointer(CDoom::Mobj)) = Array.new(32, Pointer(CDoom::Mobj).null)
	class_property usething : Pointer(CDoom::Mobj) = Pointer(CDoom::Mobj).null
	class_getter spechit : Array(Pointer(CDoom::Line)) = Array.new(Doocr::MAXSPECIALCROSS, Pointer(CDoom::Line).null)
	class_property level_timer : Int32 = 0
	class_property level_time_count : Int32 = 0
	class_property defaultfile : String = "default.cfg"
	class_property basedefault : String = "./config.cfg"
	class_property num_channels : Int32 = 16
	class_getter wadfiles : Array(String) = [] of String
	class_property deathmatch_p : Int32 = 0
	class_getter activeplats : Array(Pointer(CDoom::Plat)) = Array.new(Doocr::MAXPLATS, Pointer(CDoom::Plat).null)
	class_getter activeceilings : Array(Pointer(CDoom::Ceiling)) = Array.new(Doocr::MAXCEILINGS, Pointer(CDoom::Ceiling).null)
	class_getter itemrespawnque : Array(CDoom::Mapthing) = Array.new(Doocr::ITEMQUESIZE) { CDoom::Mapthing.new }
	class_getter blocklinks : Array(Pointer(CDoom::Mobj)) = [] of Pointer(CDoom::Mobj)
	class_getter channels : Array(Pointer(UInt8)) = Array.new(Doocr::NUM_CHANNELS, Pointer(UInt8).null)
	class SoundChannel
		property sfxinfo : Pointer(CDoom::Sfxinfo)
		property origin : Void*
		property handle : Int32

		def initialize
			@sfxinfo = Pointer(CDoom::Sfxinfo).null
			@origin = Pointer(Void).null
			@handle = 0
		end
	end

	class_getter channels_s_sound : Array(SoundChannel) = Array.new(Doocr::NUM_CHANNELS) { SoundChannel.new }
	class_property mainzone : Pointer(CDoom::Memzone) = Pointer(CDoom::Memzone).null
	class_property plr : Pointer(CDoom::Player) = Pointer(CDoom::Player).null
	class_property plyr : Pointer(CDoom::Player) = Pointer(CDoom::Player).null
	class_getter reboundstore : Array(CDoom::Doomdata) = [CDoom::Doomdata.new]
	class_getter w_title : Array(CDoom::HU_Textline) = [CDoom::HU_Textline.new]
	class_getter w_chat : Array(CDoom::HU_Itext) = [CDoom::HU_Itext.new]
	class_getter w_inputbuffer : Array(CDoom::HU_Itext) = Array.new(CDoom::MAXPLAYERS) { CDoom::HU_Itext.new }
	class_getter w_message : Array(CDoom::HU_Stext) = [CDoom::HU_Stext.new]
	class_getter w_ready : Array(CDoom::ST_Number) = [CDoom::ST_Number.new]
	class_getter w_frags : Array(CDoom::ST_Number) = [CDoom::ST_Number.new]
	class_getter w_health : Array(CDoom::ST_Percent) = [CDoom::ST_Percent.new]
	class_getter w_armsbg : Array(CDoom::ST_Binicon) = [CDoom::ST_Binicon.new]
	class_getter w_arms : Array(CDoom::ST_Multicon) = Array.new(6) { CDoom::ST_Multicon.new }
	class_getter w_faces : Array(CDoom::ST_Multicon) = [CDoom::ST_Multicon.new]
	class_getter w_keyboxes : Array(CDoom::ST_Multicon) = Array.new(3) { CDoom::ST_Multicon.new }
	class_getter w_armor : Array(CDoom::ST_Percent) = [CDoom::ST_Percent.new]
	class_getter w_ammo : Array(CDoom::ST_Number) = Array.new(4) { CDoom::ST_Number.new }
	class_getter w_maxammo : Array(CDoom::ST_Number) = Array.new(4) { CDoom::ST_Number.new }
	class_property fb : Pointer(UInt8) = Pointer(UInt8).null
	class_property wipe_scr_start : Pointer(UInt8) = Pointer(UInt8).null
	class_property wipe_scr_end : Pointer(UInt8) = Pointer(UInt8).null
	class_property wipe_scr : Pointer(UInt8) = Pointer(UInt8).null
	class_getter itoa_buf : Array(LibC::Char) = Array.new(20, 0_u8)
	class_getter trace : Array(CDoom::Divline) = [CDoom::Divline.new]
	class_getter strace : Array(CDoom::Divline) = [CDoom::Divline.new]
	class_getter overflowsprite : Array(CDoom::Vissprite) = [CDoom::Vissprite.new]
	class_getter zlight : Array(Pointer(UInt8)) = Array.new(Doocr::LIGHTLEVELS * Doocr::MAXLIGHTZ, Pointer(UInt8).null)
	class_property sprites : Pointer(CDoom::Spritedef) = Pointer(CDoom::Spritedef).null
	class_property vertexes : Pointer(CDoom::Vertex) = Pointer(CDoom::Vertex).null
	class_property segs : Pointer(CDoom::Seg) = Pointer(CDoom::Seg).null
	class_property sectors : Pointer(CDoom::Sector) = Pointer(CDoom::Sector).null
	class_property subsectors : Pointer(CDoom::Subsector) = Pointer(CDoom::Subsector).null
	class_property nodes : Pointer(CDoom::Node) = Pointer(CDoom::Node).null
	class_property lines : Pointer(CDoom::Line) = Pointer(CDoom::Line).null
	class_property sides : Pointer(CDoom::Side) = Pointer(CDoom::Side).null
	class_getter drawsegs : Array(CDoom::Drawseg) = Array.new(Doocr::MAXDRAWSEGS) { CDoom::Drawseg.new }
	class_property ds_p : Pointer(CDoom::Drawseg) = Pointer(CDoom::Drawseg).null
	class_getter vissprites : Array(CDoom::Vissprite) = Array.new(Doocr::MAXVISSPRITES) { CDoom::Vissprite.new }
	class_getter vsprsortedhead : Array(CDoom::Vissprite) = [CDoom::Vissprite.new]
	class_getter intercepts : Array(CDoom::Intercept) = Array.new(Doocr::MAXINTERCEPTS) { CDoom::Intercept.new }
	class_property intercept_p : Pointer(CDoom::Intercept) = Pointer(CDoom::Intercept).null
	class_getter thinkercap : Array(CDoom::Thinker) = [CDoom::Thinker.new]
	class_property doomcom : Pointer(CDoom::Doomcom) = Pointer(CDoom::Doomcom).null
	class_property netbuffer : Pointer(CDoom::Doomdata) = Pointer(CDoom::Doomdata).null
	class_getter localcmds : Array(CDoom::Ticcmd) = Array.new(Doocr::BACKUPTICS) { CDoom::Ticcmd.new }
	class_getter netcmds : Array(StaticArray(CDoom::Ticcmd, CDoom::MAXPLAYERS)) = Array.new(Doocr::BACKUPTICS) { StaticArray(CDoom::Ticcmd, CDoom::MAXPLAYERS).new(CDoom::Ticcmd.new) }
	class_property demobuffer : Pointer(UInt8) = Pointer(UInt8).null
	class_property demo_p : Pointer(UInt8) = Pointer(UInt8).null
	class_property demoend : Pointer(UInt8) = Pointer(UInt8).null
	class_getter textures : Array(Pointer(CDoom::Texture)) = [] of Pointer(CDoom::Texture)
	class_getter events : Array(CDoom::Event) = Array.new(Doocr::MAXEVENTS) { CDoom::Event.new }
	class_getter screens : Array(Pointer(UInt8)) = Array.new(5, Pointer(UInt8).null)
	class_property numcmaps : Int32 = 0
	class_getter deathmatchstarts : Array(CDoom::Mapthing) = Array.new(Doocr::MAX_DM_STARTS) { CDoom::Mapthing.new }
	class_getter playerstarts : Array(CDoom::Mapthing) = Array.new(CDoom::MAXPLAYERS) { CDoom::Mapthing.new }
	class_property state : Doocr::Stateenum = Doocr::Stateenum::NoState
	class_property d_skill : Doocr::Skill = Doocr::Skill::Medium
	class_property epi : Int32 = 1
	class_property pagename : String = "TITLEPIC"
	class_property finaletext : String = ""
	class_property finaleflat : String = "F_SKY1"
	class_property spritename : String = ""
	class_property demoname : String = ""
	class_property savename : String = ""
	class_property defdemoname : String = ""
	class_property exitmsg : String = ""
	class_getter pars : Array(Array(Int32)) = Array.new(4) { Array.new(9, 0) }
	class_getter cpars : Array(Int32) = Array.new(32, 0)
	class_getter detail_names : Array(String) = ["M_GDHIGH", "M_GDLOW"]
	class_getter msg_names : Array(String) = ["M_MSGOFF", "M_MSGON"]
	class_getter player_names : Array(String) = Array.new(4, "")
	class_getter mapnames : Array(String) = Array.new(45, "")
	class_getter mapnames2 : Array(String) = Array.new(32, "")
	class_getter mapnamesp : Array(String) = Array.new(32, "")
	class_getter mapnamest : Array(String) = Array.new(32, "")
	class_getter chat_dest : Array(UInt8) = Array.new(4, 0_u8)
	class_getter chatchars : Array(UInt8) = Array.new(128, 0_u8)
	class_getter french_shiftxform : Array(UInt8) = Array.new(128, 0_u8)
	class_getter english_shiftxform : Array(UInt8) = Array.new(128, 0_u8)
	class_getter french_key_map : Array(UInt8) = Array.new(128, 0_u8)
	class_property shiftxform : Array(UInt8) = english_shiftxform
	class_getter gammamsg : Array(String) = Array.new(5, "")
	class_getter skull_name : Array(String) = ["M_SKULL1", "M_SKULL2"]
	class_getter openings : Array(Int16) = Array.new(20480, 0_i16)
	class_property lastopening : Int16* = Pointer(Int16).null
	class_property bmaporgx : Int32 = 0
	class_property bmaporgy : Int32 = 0
	class_property rndindex : Int32 = 0
	class_property prndindex : Int32 = 0
	class_property firstflat : Int32 = 0
	class_property firstspritelump : Int32 = 0
	class_property lastspritelump : Int32 = 0
	class_property numspritelumps : Int32 = 0
	class_getter xtoviewangle : Array(UInt32) = Array.new(Doocr::XTOVIEWANGLE_SIZE, 0_u32)
	class_getter spritewidth : Array(Int32) = [] of Int32
	class_getter spriteoffset : Array(Int32) = [] of Int32
	class_getter spritetopoffset : Array(Int32) = [] of Int32
	class_getter translationtables : Array(UInt8) = Array.new(768, 0_u8)
	class_getter screen_palette : Array(UInt8) = Array.new(Doocr::SCREEN_PALETTE_SIZE, 0_u8)
	class_getter yah : Array(Pointer(CDoom::Patch)) = Array.new(2, Pointer(CDoom::Patch).null)
	class_getter tallnum : Array(Pointer(CDoom::Patch)) = Array.new(10, Pointer(CDoom::Patch).null)
	class_getter shortnum : Array(Pointer(CDoom::Patch)) = Array.new(10, Pointer(CDoom::Patch).null)
	class_getter keys : Array(Pointer(CDoom::Patch)) = Array.new(Doocr::Card::NUMCARDS.value, Pointer(CDoom::Patch).null)
	class_getter faces : Array(Pointer(CDoom::Patch)) = Array.new(Doocr::ST_NUMFACES, Pointer(CDoom::Patch).null)
	class_property tallpercent : Pointer(CDoom::Patch) = Pointer(CDoom::Patch).null
	class_property armsbg : Pointer(CDoom::Patch) = Pointer(CDoom::Patch).null
	class_property sbar : Pointer(CDoom::Patch) = Pointer(CDoom::Patch).null
	class_property faceback : Pointer(CDoom::Patch) = Pointer(CDoom::Patch).null
	class_getter arms : Array(Array(Pointer(CDoom::Patch))) = Array.new(6) { Array.new(2, Pointer(CDoom::Patch).null) }
	class_property bg : Pointer(CDoom::Patch) = Pointer(CDoom::Patch).null
	class_property splat : Pointer(CDoom::Patch) = Pointer(CDoom::Patch).null
	class_getter splat_pair : Array(Pointer(CDoom::Patch)) = Array.new(2, Pointer(CDoom::Patch).null)
	class_property percent : Pointer(CDoom::Patch) = Pointer(CDoom::Patch).null
	class_property colon : Pointer(CDoom::Patch) = Pointer(CDoom::Patch).null
	class_getter num : Array(Pointer(CDoom::Patch)) = Array.new(10, Pointer(CDoom::Patch).null)
	class_property wiminus : Pointer(CDoom::Patch) = Pointer(CDoom::Patch).null
	class_property finished : Pointer(CDoom::Patch) = Pointer(CDoom::Patch).null
	class_property entering : Pointer(CDoom::Patch) = Pointer(CDoom::Patch).null
	class_property sp_secret : Pointer(CDoom::Patch) = Pointer(CDoom::Patch).null
	class_property kills : Pointer(CDoom::Patch) = Pointer(CDoom::Patch).null
	class_property secret : Pointer(CDoom::Patch) = Pointer(CDoom::Patch).null
	class_property items : Pointer(CDoom::Patch) = Pointer(CDoom::Patch).null
	class_property frags : Pointer(CDoom::Patch) = Pointer(CDoom::Patch).null
	class_property time_patch : Pointer(CDoom::Patch) = Pointer(CDoom::Patch).null
	class_property par : Pointer(CDoom::Patch) = Pointer(CDoom::Patch).null
	class_property sucks : Pointer(CDoom::Patch) = Pointer(CDoom::Patch).null
	class_property killers : Pointer(CDoom::Patch) = Pointer(CDoom::Patch).null
	class_property victims : Pointer(CDoom::Patch) = Pointer(CDoom::Patch).null
	class_property total : Pointer(CDoom::Patch) = Pointer(CDoom::Patch).null
	class_property star : Pointer(CDoom::Patch) = Pointer(CDoom::Patch).null
	class_property bstar : Pointer(CDoom::Patch) = Pointer(CDoom::Patch).null
	class_getter p : Array(Pointer(CDoom::Patch)) = Array.new(CDoom::MAXPLAYERS, Pointer(CDoom::Patch).null)
	class_getter bp : Array(Pointer(CDoom::Patch)) = Array.new(CDoom::MAXPLAYERS, Pointer(CDoom::Patch).null)
	class_getter lnames : Array(Pointer(CDoom::Patch)) = [] of Pointer(CDoom::Patch)
	class_getter hu_font : Array(Pointer(CDoom::Patch)) = Array.new(Doocr::HU_FONTSIZE, Pointer(CDoom::Patch).null)
	class_property sttminus : Pointer(CDoom::Patch) = Pointer(CDoom::Patch).null
	class_property caststate : Pointer(CDoom::State) = Pointer(CDoom::State).null
	class_property vissprite_count : Int32 = 0
	class_property fixedcolormap : Pointer(UInt8) = Pointer(UInt8).null
	class_property planezlight : Pointer(Pointer(UInt8)) = Pointer(Pointer(UInt8)).null
	class_getter scalelightfixed : Array(Pointer(UInt8)) = Array.new(Doocr::MAXLIGHTSCALE, Pointer(UInt8).null)
	class_getter scalelight : Array(Array(Pointer(UInt8))) = Array.new(Doocr::LIGHTLEVELS) { Array.new(Doocr::MAXLIGHTSCALE, Pointer(UInt8).null) }
	class_property curline : Pointer(CDoom::Seg) = Pointer(CDoom::Seg).null
	class_property sidedef : Pointer(CDoom::Side) = Pointer(CDoom::Side).null
	class_property linedef : Pointer(CDoom::Line) = Pointer(CDoom::Line).null
	class_property frontsector : Pointer(CDoom::Sector) = Pointer(CDoom::Sector).null
	class_property backsector : Pointer(CDoom::Sector) = Pointer(CDoom::Sector).null
	class_property dc_colormap : Pointer(UInt8) = Pointer(UInt8).null
	class_property ds_colormap : Pointer(UInt8) = Pointer(UInt8).null
	class_property dc_source : Pointer(UInt8) = Pointer(UInt8).null
	class_property ds_source : Pointer(UInt8) = Pointer(UInt8).null
	class_property dc_translation : Pointer(UInt8) = Pointer(UInt8).null
	class_property colormaps : Pointer(UInt8) = Pointer(UInt8).null
	class_property mfloorclip : Pointer(Int16) = Pointer(Int16).null
	class_property mceilingclip : Pointer(Int16) = Pointer(Int16).null
	class_property maskedtexturecol : Pointer(Int16) = Pointer(Int16).null
	class_property viewplayer : Pointer(CDoom::Player) = Pointer(CDoom::Player).null
	class_property debugfile : File? = nil
	class_property colfunc : Proc(Nil) = ->{}

	def self.debug_fprint(text : String)
		self.debugfile.try { |file| file << text }
	end

	def self.debug_fprint(text : UInt8*)
		debug_fprint(String.new(text))
	end
	class_getter wipe_y : Array(Int32) = [] of Int32
	class_property numflats : Int32 = 0
	class_property numtextures : Int32 = 0
	class_property flatmemory : Int32 = 0
	class_property texturememory : Int32 = 0
	class_property spritememory : Int32 = 0
	class_property bmapwidth : Int32 = 0
	class_property bmapheight : Int32 = 0
	class_getter dirtybox : Array(Int32) = Array.new(4, 0)
	class_property usegamma : Int32 = 0
	class_property last_update_time : Int32 = 0
	class_getter button_states : Array(Int32) = Array.new(3, 0)
	class_getter nettics : Array(Int32) = Array.new(8, 0)
	class_getter nodeingame : Array(Int32) = Array.new(8, 0)
	class_getter remoteresend : Array(Int32) = Array.new(8, 0)
	class_getter resendto : Array(Int32) = Array.new(8, 0)
	class_getter resendcount : Array(Int32) = Array.new(8, 0)
	class_getter nodeforplayer : Array(Int32) = Array.new(4, 0)
	class_getter dm_frags : Array(Array(Int32)) = Array.new(CDoom::MAXPLAYERS) { Array.new(CDoom::MAXPLAYERS, 0) }
	class_getter dm_totals : Array(Int32) = Array.new(CDoom::MAXPLAYERS, 0)
	class_property dofrags : Int32 = 0
	class_property numbraintargets : Int32 = 0
	class_property braintargeton : Int32 = 0
	class_property numspechit : Int32 = 0
	class_getter sightcounts : Array(Int32) = Array.new(2, 0)
	class_property reboundpacket : Int32 = 0
	class_getter frametics : Array(Int32) = Array.new(4, 0)
	class_getter frameskip : Array(Int32) = Array.new(4, 0)
	class_getter playeringame : Array(Int32) = Array.new(4, 0)
	class_getter itemrespawntime : Array(Int32) = Array.new(128, 0)
	class_property iquehead : Int32 = 0
	class_property iquetail : Int32 = 0
	class_property numvertexes : Int32 = 0
	class_property numsegs : Int32 = 0
	class_property numsectors : Int32 = 0
	class_property numsubsectors : Int32 = 0
	class_property numnodes : Int32 = 0
	class_property numlines : Int32 = 0
	class_property numsides : Int32 = 0
	class_getter gamekeydown : Array(Int32) = Array(Int32).new(256, 0)
	class_getter mousebuttons : Array(Int32) = Array(Int32).new(4, 0)
	class_getter joybuttons : Array(Int32) = Array(Int32).new(5, 0)
	class_property savedescription : String = ""
	class_property timingdemo : Int32 = 0
	class_property starttime : Int32 = 0
	class_property netdemo : Int32 = 0
	crystal_int_state rndindex, maketic, ticdup, lastnettic, skiptics, maxsend, gametime, frameon,
		oldnettics, turnheld, dclicktime, dclickstate, dclicks, dclicktime2, dclickstate2, dclicks2,
		joyxmove, joyymove, sendpause, sendsave
	crystal_int_state finalestage, finalecount, castnum, casttics, castdeath, castframes, castonmelee,
		castattacking, acceleratestage, me, cnt, bcnt, firstrefresh, cnt_time, cnt_par, cnt_pause,
		dm_state, ng_state, sp_state, message_on, message_nottobefuckedwith, message_counter,
		headsupactive, head, tail, message_dontfuckwithme, message_to_print, messx, messy,
		message_last_menu_active, message_needs_input, item_on, skull_anim_counter, which_skull
	class_property message_string : Pointer(UInt8) = Pointer(UInt8).null
	class_property message_routine : Proc(Int32, Nil) = NULL_PROCP1
	class_getter cnt_kills : Array(Int32) = Array(Int32).new(4, 0)
	class_getter cnt_items : Array(Int32) = Array(Int32).new(4, 0)
	class_getter cnt_secret : Array(Int32) = Array(Int32).new(4, 0)
	class_getter cnt_frags : Array(Int32) = Array(Int32).new(4, 0)
	class_property scale_mtof : Int32 = 0
	class_property scale_ftom : Int32 = 0
	class_property mtof_zoommul : Int32 = 0
	class_property ftom_zoommul : Int32 = 0
	class_property m_x : Int32 = 0
	class_property m_y : Int32 = 0
	class_property m_x2 : Int32 = 0
	class_property m_y2 : Int32 = 0
	class_property m_w : Int32 = 0
	class_property m_h : Int32 = 0
	class_property min_x : Int32 = 0
	class_property min_y : Int32 = 0
	class_property max_x : Int32 = 0
	class_property max_y : Int32 = 0
	class_property max_w : Int32 = 0
	class_property max_h : Int32 = 0
	class_property min_w : Int32 = 0
	class_property min_h : Int32 = 0
	class_property min_scale_mtof : Int32 = 0
	class_property max_scale_mtof : Int32 = 0
	class_property old_m_w : Int32 = 0
	class_property old_m_h : Int32 = 0
	class_property old_m_x : Int32 = 0
	class_property old_m_y : Int32 = 0

	class Anim
		property istexture : Int32
		property picnum : Int32
		property basepic : Int32
		property numpics : Int32
		property speed : Int32

		def initialize
			@istexture = 0
			@picnum = 0
			@basepic = 0
			@numpics = 0
			@speed = 0
		end
	end

	class_getter anims : Array(Anim) = Array.new(Doocr::MAXANIMS) { Anim.new }
	class_property lastanim : Int32 = 0

	class Cliprange
		property first : Int32
		property last : Int32

		def initialize(@first : Int32 = 0, @last : Int32 = 0)
		end
	end

	class Weaponinfo
		property ammo : Doocr::Ammotype
		property upstate : Int32
		property downstate : Int32
		property readystate : Int32
		property atkstate : Int32
		property flashstate : Int32

		def initialize(@ammo : Doocr::Ammotype, upstate : Doocr::Statenum, downstate : Doocr::Statenum,
		               readystate : Doocr::Statenum, atkstate : Doocr::Statenum, flashstate : Doocr::Statenum)
			@upstate = upstate.value
			@downstate = downstate.value
			@readystate = readystate.value
			@atkstate = atkstate.value
			@flashstate = flashstate.value
		end
	end

	class_getter weaponinfo : Array(Weaponinfo) = [] of Weaponinfo
	class_getter keyboxes : Array(Int32) = Array.new(3, -1)
	class_getter oldweaponsowned : Array(Int32) = Array.new(Doocr::Weapontype::NUMWEAPONS.value, 0)
	class_getter queued_midi_msgs : Array(UInt64) = Array.new(Doocr::MAX_QUEUED_MIDI_MSGS, 0_u64)
	class_getter chat_macros : Array(String) = Array.new(10, "")
	class_getter consistancy : Array(Array(Int16)) = Array.new(CDoom::MAXPLAYERS) { Array.new(Doocr::BACKUPTICS, 0_i16) }

	class_getter solidsegs : Array(Cliprange) = Array.new(Doocr::MAXSEGS) { Cliprange.new }
	class_property newend : Int32 = 0
	class_getter linespeciallist : Array(Pointer(CDoom::Line)) = Array.new(Doocr::MAXLINEANIMS, Pointer(CDoom::Line).null)
	class_getter switchlist : Array(Int32) = Array.new(Doocr::SWITCHLIST_SIZE, -1)
	class_getter bodyque : Array(Pointer(CDoom::Mobj)) = Array.new(Doocr::BODYQUESIZE, Pointer(CDoom::Mobj).null)
	class_getter marknums : Array(Pointer(CDoom::Patch)) = Array.new(10, Pointer(CDoom::Patch).null)
	class_property precache : Int32 = 1
	class_property singletics : Int32 = 0
	class_property bodyqueslot : Int32 = 0
	class_property skyflatnum : Int32 = 0
	class_property advancedemo : Int32 = 0
	class_property eventhead : Int32 = 0
	class_property eventtail : Int32 = 0
	class_property skytexture : Int32 = 0
	class_property skytexturemid : Int32 = 0
	class_property setsizeneeded : Int32 = 0
	class_property setblocks : Int32 = 11
	class_property setdetail : Int32 = 0
	class_property detailshift : Int32 = 0
	@@usemouse : Int32 = 1
	@@usejoystick : Int32 = 0
	@@crosshair : Int32 = 0
	@@always_run : Int32 = 0

	def self.usemouse; @@usemouse; end
	def self.usemouse=(value : Int32); @@usemouse = value; end
	def self.usejoystick; @@usejoystick; end
	def self.usejoystick=(value : Int32); @@usejoystick = value; end
	def self.crosshair; @@crosshair; end
	def self.crosshair=(value : Int32); @@crosshair = value; end
	def self.always_run; @@always_run; end
	def self.always_run=(value : Int32); @@always_run = value; end
	@@mouse_sensitivity : Int32 = 5

	def self.mouse_sensitivity
		@@mouse_sensitivity
	end

	def self.mouse_sensitivity=(value : Int32)
		@@mouse_sensitivity = value
	end

	@@lnodes : Array(Array(Point)) = [] of Array(Point)
	@@castorder : Array(Castinfo) = Array.new(18) { Castinfo.new }
	@@mus_header = MusHeader.new
	@@wminfo = Wbstart.new
	@@wbs : Wbstart = @@wminfo
	@@plrs : Array(Wbplayer) = @@wminfo.plyr
	@@alph_switch_list : Array(Switchlist) = [] of Switchlist
	@@buttonlist : Array(Button) = Array.new(16) { Button.new }

	enum DoomKey
		UNKNOWN       =   -1
		TAB           =    9
		ENTER         =   13
		ESCAPE        =   27
		SPACE         =   32
		APOSTROPHE    =   39
		MULTIPLY      =   42
		COMMA         =   44
		MINUS         = 0x2d
		PERIOD        =   46
		SLASH         =   47
		ZERO          =   48
		ONE           =   49
		TWO           =   50
		THREE         =   51
		FOUR          =   52
		FIVE          =   53
		SIX           =   54
		SEVEN         =   55
		EIGHT         =   56
		NINE          =   57
		SEMICOLON     =   58
		EQUALS        = 0x3d
		LEFT_BRACKET  =   91
		RIGHT_BRACKET =   93
		A             =  97
		B             =  98
		C             =  99
		D             = 100
		E             = 101
		F             = 102
		G             = 103
		H             = 104
		I             = 105
		J             = 106
		K             = 107
		L             = 108
		M             = 109
		N             = 110
		O             = 111
		P             = 112
		Q             = 113
		R             = 114
		S             = 115
		T             = 116
		U             = 117
		V             = 118
		W             = 119
		X             = 120
		Y             = 121
		Z             = 122
		BACKSPACE     = 127
		CTRL          = (0x80 + 0x1d)
		LEFT_ARROW    = 0xac
		UP_ARROW      = 0xad
		RIGHT_ARROW   = 0xae
		DOWN_ARROW    = 0xaf
		SHIFT         = (0x80 + 0x36)
		ALT           = (0x80 + 0x38)
		F1            = (0x80 + 0x3b)
		F2            = (0x80 + 0x3c)
		F3            = (0x80 + 0x3d)
		F4            = (0x80 + 0x3e)
		F5            = (0x80 + 0x3f)
		F6            = (0x80 + 0x40)
		F7            = (0x80 + 0x41)
		F8            = (0x80 + 0x42)
		F9            = (0x80 + 0x43)
		F10           = (0x80 + 0x44)
		F11           = (0x80 + 0x57)
		F12           = (0x80 + 0x58)
		PAUSE         = 0xff
	end

	enum DoomButton
		LEFT   = 0
		RIGHT  = 1
		MIDDLE = 2
	end
end