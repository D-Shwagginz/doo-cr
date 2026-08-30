//  Copyright (C) 2026 Devin Shwagginz
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//
// ==> The code from PureDoom that is still leftover.
//      The only thing in here used is variable declarations.

#define SCREENWIDTH 320
#define SCREENHEIGHT 200
#define MAXPLAYERS 4
#define MAXEVENTS (64 * 64) // [pd] Crank up the number because we pump them faster
#define MAXWADFILES 20
#define HU_FONTSTART '!'    // the first font characters
#define HU_FONTEND '_'      // the last font characters
#define HU_FONTSIZE (HU_FONTEND - HU_FONTSTART + 1)        
#define FINEANGLES 8192
#define MAXNETNODES                8
#define BACKUPTICS                24
#define MAXDRAWSEGS 256
#define HU_MAXLINES 4
#define HU_MAXLINELENGTH 80
#define MAXSWITCHES 50
#define MAXBUTTONS 16
#define MAXPLATS 30
#define MAXCEILINGS 30
#define LIGHTLEVELS 16
#define MAXLIGHTSCALE 48
#define MAXLIGHTZ 128
#define MAXVISSPRITES 128
#define ITEMQUESIZE                128
#define MAXINTERCEPTS        128
#define AM_NUMMARKPOINTS 10
#define SAVESTRINGSIZE 24
#define NUMKEYS         256
#define BODYQUESIZE     32
#define QUEUESIZE 128
#define SAMPLECOUNT 512
#define NUM_CHANNELS 16
#define BUFMUL 4
#define MIXBUFFERSIZE (SAMPLECOUNT*BUFMUL)
#define MAX_QUEUED_MIDI_MSGS 256
#define MAXSPECIALCROSS 8
#define MAX_DEATHMATCH_STARTS        10
#define MAXANIMS 32
#define MAXLINEANIMS 64
#define MAXSEGS 32
#define MAXWIDTH 1120
#define MAXHEIGHT 832
#define FUZZTABLE 50 
#define MAXVISPLANES        128
#define MAXOPENINGS        SCREENWIDTH*64
#define ST_NUMPAINFACES 5
#define ST_NUMSTRAIGHTFACES 3
#define ST_NUMTURNFACES 2
#define ST_NUMSPECIALFACES 3
#define ST_FACESTRIDE (ST_NUMSTRAIGHTFACES + ST_NUMTURNFACES + ST_NUMSPECIALFACES)
#define ST_NUMEXTRAFACES 2
#define ST_NUMFACES (ST_FACESTRIDE * ST_NUMPAINFACES + ST_NUMEXTRAFACES)
#define NUMEPISODES 4


// -----------------------------------------------------------------------------
// TYPE DEFINITIONS (kept in original dependency order)
// -----------------------------------------------------------------------------

typedef struct sfxinfo_struct sfxinfo_t;

typedef enum
{
    DOOM_SEEK_CUR = 1,
    DOOM_SEEK_END = 2,
    DOOM_SEEK_SET = 0
} doom_seek_t;

typedef void(*doom_print_fn)(const char* str);

typedef void*(*doom_malloc_fn)(int size);

typedef void(*doom_free_fn)(void* ptr);

typedef void*(*doom_open_fn)(const char* filename, const char* mode);

typedef void(*doom_close_fn)(void* handle);

typedef int(*doom_read_fn)(void* handle, void *buf, int count);

typedef int(*doom_write_fn)(void* handle, const void *buf, int count);

typedef int(*doom_seek_fn)(void* handle, int offset, doom_seek_t origin);

typedef int(*doom_tell_fn)(void* handle);

typedef int(*doom_eof_fn)(void* handle);

typedef void(*doom_gettime_fn)(int* sec, int* usec);

typedef void(*doom_exit_fn)(int code);

typedef char*(*doom_getenv_fn)(const char* var);

typedef void (*actionf_v)();

typedef void (*actionf_p1)(void*);

typedef void (*actionf_p2)(void*, void*);

typedef union
{
    actionf_p1 acp1;
    actionf_v  acv;
    actionf_p2 acp2;
} actionf_t;

typedef actionf_t think_t;

typedef struct thinker_s
{
    struct thinker_s* prev;
    struct thinker_s* next;
    think_t function;
    long long pad;
    char remove;
} thinker_t;

typedef enum
{
    shareware,      // DOOM 1 shareware, E1, M9
    registered,     // DOOM 1 registered, E3, M27
    commercial,     // DOOM 2 retail, E1 M34
    // DOOM 2 german edition not handled
    retail,         // DOOM 1 retail, E4, M36
    indetermined    // Well, no IWAD found.
} GameMode_t;

typedef enum
{
    doom,       // DOOM 1
    doom2,      // DOOM 2
    pack_tnt,   // TNT mission pack
    pack_plut,  // Plutonia pack
    none
} GameMission_t;

typedef enum
{
    english,
    french,
    german,
    unknown
} Language_t;

typedef enum
{
    GS_LEVEL,
    GS_INTERMISSION,
    GS_FINALE,
    GS_DEMOSCREEN
} gamestate_t;

typedef enum
{
    sk_baby,
    sk_easy,
    sk_medium,
    sk_hard,
    sk_nightmare
} skill_t;

typedef enum
{
    it_bluecard,
    it_yellowcard,
    it_redcard,
    it_blueskull,
    it_yellowskull,
    it_redskull,
    NUMCARDS
} card_t;

typedef enum
{
    wp_fist,
    wp_pistol,
    wp_shotgun,
    wp_chaingun,
    wp_missile,
    wp_plasma,
    wp_bfg,
    wp_chainsaw,
    wp_supershotgun,
    NUMWEAPONS,
    // No pending weapon change.
    wp_nochange
} weapontype_t;

typedef enum
{
    am_clip,    // Pistol / chaingun ammo.
    am_shell,   // Shotgun / double barreled shotgun.
    am_cell,    // Plasma rifle, BFG.
    am_misl,    // Missile launcher.
    NUMAMMO,
    am_noammo   // Unlimited for chainsaw / fist.        
} ammotype_t;

typedef enum
{
    pw_invulnerability,
    pw_strength,
    pw_invisibility,
    pw_ironfeet,
    pw_allmap,
    pw_infrared,
    NUMPOWERS
} powertype_t;

typedef struct
{
    ammotype_t ammo;
    int upstate;
    int downstate;
    int readystate;
    int atkstate;
    int flashstate;
} weaponinfo_t;

typedef int doom_boolean;

typedef unsigned char byte;

typedef enum
{
    ev_keydown,
    ev_keyup,
    ev_mouse,
    ev_joystick
} evtype_t;

typedef struct
{
    evtype_t type;
    int data1;  // keys / mouse/joystick buttons
    int data2;  // mouse/joystick x move
    int data3;  // mouse/joystick y move
} event_t;

typedef enum
{
    ga_nothing,
    ga_loadlevel,
    ga_newgame,
    ga_loadgame,
    ga_savegame,
    ga_playdemo,
    ga_completed,
    ga_victory,
    ga_worlddone,
    ga_screenshot
} gameaction_t;

typedef struct
{
    char forwardmove;   // *2048 for move
    char sidemove;      // *2048 for move
    short angleturn;    // <<16 for angle delta
    short consistancy;  // checks for net game
    byte chatchar;
    byte buttons;
} ticcmd_t;

typedef struct
{
    short x;
    short y;
    short angle;
    short type;
    short options;
} mapthing_t;

typedef enum
{
    SPR_TROO,
    SPR_SHTG,
    SPR_PUNG,
    SPR_PISG,
    SPR_PISF,
    SPR_SHTF,
    SPR_SHT2,
    SPR_CHGG,
    SPR_CHGF,
    SPR_MISG,
    SPR_MISF,
    SPR_SAWG,
    SPR_PLSG,
    SPR_PLSF,
    SPR_BFGG,
    SPR_BFGF,
    SPR_BLUD,
    SPR_PUFF,
    SPR_BAL1,
    SPR_BAL2,
    SPR_PLSS,
    SPR_PLSE,
    SPR_MISL,
    SPR_BFS1,
    SPR_BFE1,
    SPR_BFE2,
    SPR_TFOG,
    SPR_IFOG,
    SPR_PLAY,
    SPR_POSS,
    SPR_SPOS,
    SPR_VILE,
    SPR_FIRE,
    SPR_FATB,
    SPR_FBXP,
    SPR_SKEL,
    SPR_MANF,
    SPR_FATT,
    SPR_CPOS,
    SPR_SARG,
    SPR_HEAD,
    SPR_BAL7,
    SPR_BOSS,
    SPR_BOS2,
    SPR_SKUL,
    SPR_SPID,
    SPR_BSPI,
    SPR_APLS,
    SPR_APBX,
    SPR_CYBR,
    SPR_PAIN,
    SPR_SSWV,
    SPR_KEEN,
    SPR_BBRN,
    SPR_BOSF,
    SPR_ARM1,
    SPR_ARM2,
    SPR_BAR1,
    SPR_BEXP,
    SPR_FCAN,
    SPR_BON1,
    SPR_BON2,
    SPR_BKEY,
    SPR_RKEY,
    SPR_YKEY,
    SPR_BSKU,
    SPR_RSKU,
    SPR_YSKU,
    SPR_STIM,
    SPR_MEDI,
    SPR_SOUL,
    SPR_PINV,
    SPR_PSTR,
    SPR_PINS,
    SPR_MEGA,
    SPR_SUIT,
    SPR_PMAP,
    SPR_PVIS,
    SPR_CLIP,
    SPR_AMMO,
    SPR_ROCK,
    SPR_BROK,
    SPR_CELL,
    SPR_CELP,
    SPR_SHEL,
    SPR_SBOX,
    SPR_BPAK,
    SPR_BFUG,
    SPR_MGUN,
    SPR_CSAW,
    SPR_LAUN,
    SPR_PLAS,
    SPR_SHOT,
    SPR_SGN2,
    SPR_COLU,
    SPR_SMT2,
    SPR_GOR1,
    SPR_POL2,
    SPR_POL5,
    SPR_POL4,
    SPR_POL3,
    SPR_POL1,
    SPR_POL6,
    SPR_GOR2,
    SPR_GOR3,
    SPR_GOR4,
    SPR_GOR5,
    SPR_SMIT,
    SPR_COL1,
    SPR_COL2,
    SPR_COL3,
    SPR_COL4,
    SPR_CAND,
    SPR_CBRA,
    SPR_COL6,
    SPR_TRE1,
    SPR_TRE2,
    SPR_ELEC,
    SPR_CEYE,
    SPR_FSKU,
    SPR_COL5,
    SPR_TBLU,
    SPR_TGRN,
    SPR_TRED,
    SPR_SMBT,
    SPR_SMGT,
    SPR_SMRT,
    SPR_HDB1,
    SPR_HDB2,
    SPR_HDB3,
    SPR_HDB4,
    SPR_HDB5,
    SPR_HDB6,
    SPR_POB1,
    SPR_POB2,
    SPR_BRS1,
    SPR_TLMP,
    SPR_TLP2,
    NUMSPRITES
} spritenum_t;

typedef enum
{
    S_NULL,
    S_LIGHTDONE,
    S_PUNCH,
    S_PUNCHDOWN,
    S_PUNCHUP,
    S_PUNCH1,
    S_PUNCH2,
    S_PUNCH3,
    S_PUNCH4,
    S_PUNCH5,
    S_PISTOL,
    S_PISTOLDOWN,
    S_PISTOLUP,
    S_PISTOL1,
    S_PISTOL2,
    S_PISTOL3,
    S_PISTOL4,
    S_PISTOLFLASH,
    S_SGUN,
    S_SGUNDOWN,
    S_SGUNUP,
    S_SGUN1,
    S_SGUN2,
    S_SGUN3,
    S_SGUN4,
    S_SGUN5,
    S_SGUN6,
    S_SGUN7,
    S_SGUN8,
    S_SGUN9,
    S_SGUNFLASH1,
    S_SGUNFLASH2,
    S_DSGUN,
    S_DSGUNDOWN,
    S_DSGUNUP,
    S_DSGUN1,
    S_DSGUN2,
    S_DSGUN3,
    S_DSGUN4,
    S_DSGUN5,
    S_DSGUN6,
    S_DSGUN7,
    S_DSGUN8,
    S_DSGUN9,
    S_DSGUN10,
    S_DSNR1,
    S_DSNR2,
    S_DSGUNFLASH1,
    S_DSGUNFLASH2,
    S_CHAIN,
    S_CHAINDOWN,
    S_CHAINUP,
    S_CHAIN1,
    S_CHAIN2,
    S_CHAIN3,
    S_CHAINFLASH1,
    S_CHAINFLASH2,
    S_MISSILE,
    S_MISSILEDOWN,
    S_MISSILEUP,
    S_MISSILE1,
    S_MISSILE2,
    S_MISSILE3,
    S_MISSILEFLASH1,
    S_MISSILEFLASH2,
    S_MISSILEFLASH3,
    S_MISSILEFLASH4,
    S_SAW,
    S_SAWB,
    S_SAWDOWN,
    S_SAWUP,
    S_SAW1,
    S_SAW2,
    S_SAW3,
    S_PLASMA,
    S_PLASMADOWN,
    S_PLASMAUP,
    S_PLASMA1,
    S_PLASMA2,
    S_PLASMAFLASH1,
    S_PLASMAFLASH2,
    S_BFG,
    S_BFGDOWN,
    S_BFGUP,
    S_BFG1,
    S_BFG2,
    S_BFG3,
    S_BFG4,
    S_BFGFLASH1,
    S_BFGFLASH2,
    S_BLOOD1,
    S_BLOOD2,
    S_BLOOD3,
    S_PUFF1,
    S_PUFF2,
    S_PUFF3,
    S_PUFF4,
    S_TBALL1,
    S_TBALL2,
    S_TBALLX1,
    S_TBALLX2,
    S_TBALLX3,
    S_RBALL1,
    S_RBALL2,
    S_RBALLX1,
    S_RBALLX2,
    S_RBALLX3,
    S_PLASBALL,
    S_PLASBALL2,
    S_PLASEXP,
    S_PLASEXP2,
    S_PLASEXP3,
    S_PLASEXP4,
    S_PLASEXP5,
    S_ROCKET,
    S_BFGSHOT,
    S_BFGSHOT2,
    S_BFGLAND,
    S_BFGLAND2,
    S_BFGLAND3,
    S_BFGLAND4,
    S_BFGLAND5,
    S_BFGLAND6,
    S_BFGEXP,
    S_BFGEXP2,
    S_BFGEXP3,
    S_BFGEXP4,
    S_EXPLODE1,
    S_EXPLODE2,
    S_EXPLODE3,
    S_TFOG,
    S_TFOG01,
    S_TFOG02,
    S_TFOG2,
    S_TFOG3,
    S_TFOG4,
    S_TFOG5,
    S_TFOG6,
    S_TFOG7,
    S_TFOG8,
    S_TFOG9,
    S_TFOG10,
    S_IFOG,
    S_IFOG01,
    S_IFOG02,
    S_IFOG2,
    S_IFOG3,
    S_IFOG4,
    S_IFOG5,
    S_PLAY,
    S_PLAY_RUN1,
    S_PLAY_RUN2,
    S_PLAY_RUN3,
    S_PLAY_RUN4,
    S_PLAY_ATK1,
    S_PLAY_ATK2,
    S_PLAY_PAIN,
    S_PLAY_PAIN2,
    S_PLAY_DIE1,
    S_PLAY_DIE2,
    S_PLAY_DIE3,
    S_PLAY_DIE4,
    S_PLAY_DIE5,
    S_PLAY_DIE6,
    S_PLAY_DIE7,
    S_PLAY_XDIE1,
    S_PLAY_XDIE2,
    S_PLAY_XDIE3,
    S_PLAY_XDIE4,
    S_PLAY_XDIE5,
    S_PLAY_XDIE6,
    S_PLAY_XDIE7,
    S_PLAY_XDIE8,
    S_PLAY_XDIE9,
    S_POSS_STND,
    S_POSS_STND2,
    S_POSS_RUN1,
    S_POSS_RUN2,
    S_POSS_RUN3,
    S_POSS_RUN4,
    S_POSS_RUN5,
    S_POSS_RUN6,
    S_POSS_RUN7,
    S_POSS_RUN8,
    S_POSS_ATK1,
    S_POSS_ATK2,
    S_POSS_ATK3,
    S_POSS_PAIN,
    S_POSS_PAIN2,
    S_POSS_DIE1,
    S_POSS_DIE2,
    S_POSS_DIE3,
    S_POSS_DIE4,
    S_POSS_DIE5,
    S_POSS_XDIE1,
    S_POSS_XDIE2,
    S_POSS_XDIE3,
    S_POSS_XDIE4,
    S_POSS_XDIE5,
    S_POSS_XDIE6,
    S_POSS_XDIE7,
    S_POSS_XDIE8,
    S_POSS_XDIE9,
    S_POSS_RAISE1,
    S_POSS_RAISE2,
    S_POSS_RAISE3,
    S_POSS_RAISE4,
    S_SPOS_STND,
    S_SPOS_STND2,
    S_SPOS_RUN1,
    S_SPOS_RUN2,
    S_SPOS_RUN3,
    S_SPOS_RUN4,
    S_SPOS_RUN5,
    S_SPOS_RUN6,
    S_SPOS_RUN7,
    S_SPOS_RUN8,
    S_SPOS_ATK1,
    S_SPOS_ATK2,
    S_SPOS_ATK3,
    S_SPOS_PAIN,
    S_SPOS_PAIN2,
    S_SPOS_DIE1,
    S_SPOS_DIE2,
    S_SPOS_DIE3,
    S_SPOS_DIE4,
    S_SPOS_DIE5,
    S_SPOS_XDIE1,
    S_SPOS_XDIE2,
    S_SPOS_XDIE3,
    S_SPOS_XDIE4,
    S_SPOS_XDIE5,
    S_SPOS_XDIE6,
    S_SPOS_XDIE7,
    S_SPOS_XDIE8,
    S_SPOS_XDIE9,
    S_SPOS_RAISE1,
    S_SPOS_RAISE2,
    S_SPOS_RAISE3,
    S_SPOS_RAISE4,
    S_SPOS_RAISE5,
    S_VILE_STND,
    S_VILE_STND2,
    S_VILE_RUN1,
    S_VILE_RUN2,
    S_VILE_RUN3,
    S_VILE_RUN4,
    S_VILE_RUN5,
    S_VILE_RUN6,
    S_VILE_RUN7,
    S_VILE_RUN8,
    S_VILE_RUN9,
    S_VILE_RUN10,
    S_VILE_RUN11,
    S_VILE_RUN12,
    S_VILE_ATK1,
    S_VILE_ATK2,
    S_VILE_ATK3,
    S_VILE_ATK4,
    S_VILE_ATK5,
    S_VILE_ATK6,
    S_VILE_ATK7,
    S_VILE_ATK8,
    S_VILE_ATK9,
    S_VILE_ATK10,
    S_VILE_ATK11,
    S_VILE_HEAL1,
    S_VILE_HEAL2,
    S_VILE_HEAL3,
    S_VILE_PAIN,
    S_VILE_PAIN2,
    S_VILE_DIE1,
    S_VILE_DIE2,
    S_VILE_DIE3,
    S_VILE_DIE4,
    S_VILE_DIE5,
    S_VILE_DIE6,
    S_VILE_DIE7,
    S_VILE_DIE8,
    S_VILE_DIE9,
    S_VILE_DIE10,
    S_FIRE1,
    S_FIRE2,
    S_FIRE3,
    S_FIRE4,
    S_FIRE5,
    S_FIRE6,
    S_FIRE7,
    S_FIRE8,
    S_FIRE9,
    S_FIRE10,
    S_FIRE11,
    S_FIRE12,
    S_FIRE13,
    S_FIRE14,
    S_FIRE15,
    S_FIRE16,
    S_FIRE17,
    S_FIRE18,
    S_FIRE19,
    S_FIRE20,
    S_FIRE21,
    S_FIRE22,
    S_FIRE23,
    S_FIRE24,
    S_FIRE25,
    S_FIRE26,
    S_FIRE27,
    S_FIRE28,
    S_FIRE29,
    S_FIRE30,
    S_SMOKE1,
    S_SMOKE2,
    S_SMOKE3,
    S_SMOKE4,
    S_SMOKE5,
    S_TRACER,
    S_TRACER2,
    S_TRACEEXP1,
    S_TRACEEXP2,
    S_TRACEEXP3,
    S_SKEL_STND,
    S_SKEL_STND2,
    S_SKEL_RUN1,
    S_SKEL_RUN2,
    S_SKEL_RUN3,
    S_SKEL_RUN4,
    S_SKEL_RUN5,
    S_SKEL_RUN6,
    S_SKEL_RUN7,
    S_SKEL_RUN8,
    S_SKEL_RUN9,
    S_SKEL_RUN10,
    S_SKEL_RUN11,
    S_SKEL_RUN12,
    S_SKEL_FIST1,
    S_SKEL_FIST2,
    S_SKEL_FIST3,
    S_SKEL_FIST4,
    S_SKEL_MISS1,
    S_SKEL_MISS2,
    S_SKEL_MISS3,
    S_SKEL_MISS4,
    S_SKEL_PAIN,
    S_SKEL_PAIN2,
    S_SKEL_DIE1,
    S_SKEL_DIE2,
    S_SKEL_DIE3,
    S_SKEL_DIE4,
    S_SKEL_DIE5,
    S_SKEL_DIE6,
    S_SKEL_RAISE1,
    S_SKEL_RAISE2,
    S_SKEL_RAISE3,
    S_SKEL_RAISE4,
    S_SKEL_RAISE5,
    S_SKEL_RAISE6,
    S_FATSHOT1,
    S_FATSHOT2,
    S_FATSHOTX1,
    S_FATSHOTX2,
    S_FATSHOTX3,
    S_FATT_STND,
    S_FATT_STND2,
    S_FATT_RUN1,
    S_FATT_RUN2,
    S_FATT_RUN3,
    S_FATT_RUN4,
    S_FATT_RUN5,
    S_FATT_RUN6,
    S_FATT_RUN7,
    S_FATT_RUN8,
    S_FATT_RUN9,
    S_FATT_RUN10,
    S_FATT_RUN11,
    S_FATT_RUN12,
    S_FATT_ATK1,
    S_FATT_ATK2,
    S_FATT_ATK3,
    S_FATT_ATK4,
    S_FATT_ATK5,
    S_FATT_ATK6,
    S_FATT_ATK7,
    S_FATT_ATK8,
    S_FATT_ATK9,
    S_FATT_ATK10,
    S_FATT_PAIN,
    S_FATT_PAIN2,
    S_FATT_DIE1,
    S_FATT_DIE2,
    S_FATT_DIE3,
    S_FATT_DIE4,
    S_FATT_DIE5,
    S_FATT_DIE6,
    S_FATT_DIE7,
    S_FATT_DIE8,
    S_FATT_DIE9,
    S_FATT_DIE10,
    S_FATT_RAISE1,
    S_FATT_RAISE2,
    S_FATT_RAISE3,
    S_FATT_RAISE4,
    S_FATT_RAISE5,
    S_FATT_RAISE6,
    S_FATT_RAISE7,
    S_FATT_RAISE8,
    S_CPOS_STND,
    S_CPOS_STND2,
    S_CPOS_RUN1,
    S_CPOS_RUN2,
    S_CPOS_RUN3,
    S_CPOS_RUN4,
    S_CPOS_RUN5,
    S_CPOS_RUN6,
    S_CPOS_RUN7,
    S_CPOS_RUN8,
    S_CPOS_ATK1,
    S_CPOS_ATK2,
    S_CPOS_ATK3,
    S_CPOS_ATK4,
    S_CPOS_PAIN,
    S_CPOS_PAIN2,
    S_CPOS_DIE1,
    S_CPOS_DIE2,
    S_CPOS_DIE3,
    S_CPOS_DIE4,
    S_CPOS_DIE5,
    S_CPOS_DIE6,
    S_CPOS_DIE7,
    S_CPOS_XDIE1,
    S_CPOS_XDIE2,
    S_CPOS_XDIE3,
    S_CPOS_XDIE4,
    S_CPOS_XDIE5,
    S_CPOS_XDIE6,
    S_CPOS_RAISE1,
    S_CPOS_RAISE2,
    S_CPOS_RAISE3,
    S_CPOS_RAISE4,
    S_CPOS_RAISE5,
    S_CPOS_RAISE6,
    S_CPOS_RAISE7,
    S_TROO_STND,
    S_TROO_STND2,
    S_TROO_RUN1,
    S_TROO_RUN2,
    S_TROO_RUN3,
    S_TROO_RUN4,
    S_TROO_RUN5,
    S_TROO_RUN6,
    S_TROO_RUN7,
    S_TROO_RUN8,
    S_TROO_ATK1,
    S_TROO_ATK2,
    S_TROO_ATK3,
    S_TROO_PAIN,
    S_TROO_PAIN2,
    S_TROO_DIE1,
    S_TROO_DIE2,
    S_TROO_DIE3,
    S_TROO_DIE4,
    S_TROO_DIE5,
    S_TROO_XDIE1,
    S_TROO_XDIE2,
    S_TROO_XDIE3,
    S_TROO_XDIE4,
    S_TROO_XDIE5,
    S_TROO_XDIE6,
    S_TROO_XDIE7,
    S_TROO_XDIE8,
    S_TROO_RAISE1,
    S_TROO_RAISE2,
    S_TROO_RAISE3,
    S_TROO_RAISE4,
    S_TROO_RAISE5,
    S_SARG_STND,
    S_SARG_STND2,
    S_SARG_RUN1,
    S_SARG_RUN2,
    S_SARG_RUN3,
    S_SARG_RUN4,
    S_SARG_RUN5,
    S_SARG_RUN6,
    S_SARG_RUN7,
    S_SARG_RUN8,
    S_SARG_ATK1,
    S_SARG_ATK2,
    S_SARG_ATK3,
    S_SARG_PAIN,
    S_SARG_PAIN2,
    S_SARG_DIE1,
    S_SARG_DIE2,
    S_SARG_DIE3,
    S_SARG_DIE4,
    S_SARG_DIE5,
    S_SARG_DIE6,
    S_SARG_RAISE1,
    S_SARG_RAISE2,
    S_SARG_RAISE3,
    S_SARG_RAISE4,
    S_SARG_RAISE5,
    S_SARG_RAISE6,
    S_HEAD_STND,
    S_HEAD_RUN1,
    S_HEAD_ATK1,
    S_HEAD_ATK2,
    S_HEAD_ATK3,
    S_HEAD_PAIN,
    S_HEAD_PAIN2,
    S_HEAD_PAIN3,
    S_HEAD_DIE1,
    S_HEAD_DIE2,
    S_HEAD_DIE3,
    S_HEAD_DIE4,
    S_HEAD_DIE5,
    S_HEAD_DIE6,
    S_HEAD_RAISE1,
    S_HEAD_RAISE2,
    S_HEAD_RAISE3,
    S_HEAD_RAISE4,
    S_HEAD_RAISE5,
    S_HEAD_RAISE6,
    S_BRBALL1,
    S_BRBALL2,
    S_BRBALLX1,
    S_BRBALLX2,
    S_BRBALLX3,
    S_BOSS_STND,
    S_BOSS_STND2,
    S_BOSS_RUN1,
    S_BOSS_RUN2,
    S_BOSS_RUN3,
    S_BOSS_RUN4,
    S_BOSS_RUN5,
    S_BOSS_RUN6,
    S_BOSS_RUN7,
    S_BOSS_RUN8,
    S_BOSS_ATK1,
    S_BOSS_ATK2,
    S_BOSS_ATK3,
    S_BOSS_PAIN,
    S_BOSS_PAIN2,
    S_BOSS_DIE1,
    S_BOSS_DIE2,
    S_BOSS_DIE3,
    S_BOSS_DIE4,
    S_BOSS_DIE5,
    S_BOSS_DIE6,
    S_BOSS_DIE7,
    S_BOSS_RAISE1,
    S_BOSS_RAISE2,
    S_BOSS_RAISE3,
    S_BOSS_RAISE4,
    S_BOSS_RAISE5,
    S_BOSS_RAISE6,
    S_BOSS_RAISE7,
    S_BOS2_STND,
    S_BOS2_STND2,
    S_BOS2_RUN1,
    S_BOS2_RUN2,
    S_BOS2_RUN3,
    S_BOS2_RUN4,
    S_BOS2_RUN5,
    S_BOS2_RUN6,
    S_BOS2_RUN7,
    S_BOS2_RUN8,
    S_BOS2_ATK1,
    S_BOS2_ATK2,
    S_BOS2_ATK3,
    S_BOS2_PAIN,
    S_BOS2_PAIN2,
    S_BOS2_DIE1,
    S_BOS2_DIE2,
    S_BOS2_DIE3,
    S_BOS2_DIE4,
    S_BOS2_DIE5,
    S_BOS2_DIE6,
    S_BOS2_DIE7,
    S_BOS2_RAISE1,
    S_BOS2_RAISE2,
    S_BOS2_RAISE3,
    S_BOS2_RAISE4,
    S_BOS2_RAISE5,
    S_BOS2_RAISE6,
    S_BOS2_RAISE7,
    S_SKULL_STND,
    S_SKULL_STND2,
    S_SKULL_RUN1,
    S_SKULL_RUN2,
    S_SKULL_ATK1,
    S_SKULL_ATK2,
    S_SKULL_ATK3,
    S_SKULL_ATK4,
    S_SKULL_PAIN,
    S_SKULL_PAIN2,
    S_SKULL_DIE1,
    S_SKULL_DIE2,
    S_SKULL_DIE3,
    S_SKULL_DIE4,
    S_SKULL_DIE5,
    S_SKULL_DIE6,
    S_SPID_STND,
    S_SPID_STND2,
    S_SPID_RUN1,
    S_SPID_RUN2,
    S_SPID_RUN3,
    S_SPID_RUN4,
    S_SPID_RUN5,
    S_SPID_RUN6,
    S_SPID_RUN7,
    S_SPID_RUN8,
    S_SPID_RUN9,
    S_SPID_RUN10,
    S_SPID_RUN11,
    S_SPID_RUN12,
    S_SPID_ATK1,
    S_SPID_ATK2,
    S_SPID_ATK3,
    S_SPID_ATK4,
    S_SPID_PAIN,
    S_SPID_PAIN2,
    S_SPID_DIE1,
    S_SPID_DIE2,
    S_SPID_DIE3,
    S_SPID_DIE4,
    S_SPID_DIE5,
    S_SPID_DIE6,
    S_SPID_DIE7,
    S_SPID_DIE8,
    S_SPID_DIE9,
    S_SPID_DIE10,
    S_SPID_DIE11,
    S_BSPI_STND,
    S_BSPI_STND2,
    S_BSPI_SIGHT,
    S_BSPI_RUN1,
    S_BSPI_RUN2,
    S_BSPI_RUN3,
    S_BSPI_RUN4,
    S_BSPI_RUN5,
    S_BSPI_RUN6,
    S_BSPI_RUN7,
    S_BSPI_RUN8,
    S_BSPI_RUN9,
    S_BSPI_RUN10,
    S_BSPI_RUN11,
    S_BSPI_RUN12,
    S_BSPI_ATK1,
    S_BSPI_ATK2,
    S_BSPI_ATK3,
    S_BSPI_ATK4,
    S_BSPI_PAIN,
    S_BSPI_PAIN2,
    S_BSPI_DIE1,
    S_BSPI_DIE2,
    S_BSPI_DIE3,
    S_BSPI_DIE4,
    S_BSPI_DIE5,
    S_BSPI_DIE6,
    S_BSPI_DIE7,
    S_BSPI_RAISE1,
    S_BSPI_RAISE2,
    S_BSPI_RAISE3,
    S_BSPI_RAISE4,
    S_BSPI_RAISE5,
    S_BSPI_RAISE6,
    S_BSPI_RAISE7,
    S_ARACH_PLAZ,
    S_ARACH_PLAZ2,
    S_ARACH_PLEX,
    S_ARACH_PLEX2,
    S_ARACH_PLEX3,
    S_ARACH_PLEX4,
    S_ARACH_PLEX5,
    S_CYBER_STND,
    S_CYBER_STND2,
    S_CYBER_RUN1,
    S_CYBER_RUN2,
    S_CYBER_RUN3,
    S_CYBER_RUN4,
    S_CYBER_RUN5,
    S_CYBER_RUN6,
    S_CYBER_RUN7,
    S_CYBER_RUN8,
    S_CYBER_ATK1,
    S_CYBER_ATK2,
    S_CYBER_ATK3,
    S_CYBER_ATK4,
    S_CYBER_ATK5,
    S_CYBER_ATK6,
    S_CYBER_PAIN,
    S_CYBER_DIE1,
    S_CYBER_DIE2,
    S_CYBER_DIE3,
    S_CYBER_DIE4,
    S_CYBER_DIE5,
    S_CYBER_DIE6,
    S_CYBER_DIE7,
    S_CYBER_DIE8,
    S_CYBER_DIE9,
    S_CYBER_DIE10,
    S_PAIN_STND,
    S_PAIN_RUN1,
    S_PAIN_RUN2,
    S_PAIN_RUN3,
    S_PAIN_RUN4,
    S_PAIN_RUN5,
    S_PAIN_RUN6,
    S_PAIN_ATK1,
    S_PAIN_ATK2,
    S_PAIN_ATK3,
    S_PAIN_ATK4,
    S_PAIN_PAIN,
    S_PAIN_PAIN2,
    S_PAIN_DIE1,
    S_PAIN_DIE2,
    S_PAIN_DIE3,
    S_PAIN_DIE4,
    S_PAIN_DIE5,
    S_PAIN_DIE6,
    S_PAIN_RAISE1,
    S_PAIN_RAISE2,
    S_PAIN_RAISE3,
    S_PAIN_RAISE4,
    S_PAIN_RAISE5,
    S_PAIN_RAISE6,
    S_SSWV_STND,
    S_SSWV_STND2,
    S_SSWV_RUN1,
    S_SSWV_RUN2,
    S_SSWV_RUN3,
    S_SSWV_RUN4,
    S_SSWV_RUN5,
    S_SSWV_RUN6,
    S_SSWV_RUN7,
    S_SSWV_RUN8,
    S_SSWV_ATK1,
    S_SSWV_ATK2,
    S_SSWV_ATK3,
    S_SSWV_ATK4,
    S_SSWV_ATK5,
    S_SSWV_ATK6,
    S_SSWV_PAIN,
    S_SSWV_PAIN2,
    S_SSWV_DIE1,
    S_SSWV_DIE2,
    S_SSWV_DIE3,
    S_SSWV_DIE4,
    S_SSWV_DIE5,
    S_SSWV_XDIE1,
    S_SSWV_XDIE2,
    S_SSWV_XDIE3,
    S_SSWV_XDIE4,
    S_SSWV_XDIE5,
    S_SSWV_XDIE6,
    S_SSWV_XDIE7,
    S_SSWV_XDIE8,
    S_SSWV_XDIE9,
    S_SSWV_RAISE1,
    S_SSWV_RAISE2,
    S_SSWV_RAISE3,
    S_SSWV_RAISE4,
    S_SSWV_RAISE5,
    S_KEENSTND,
    S_COMMKEEN,
    S_COMMKEEN2,
    S_COMMKEEN3,
    S_COMMKEEN4,
    S_COMMKEEN5,
    S_COMMKEEN6,
    S_COMMKEEN7,
    S_COMMKEEN8,
    S_COMMKEEN9,
    S_COMMKEEN10,
    S_COMMKEEN11,
    S_COMMKEEN12,
    S_KEENPAIN,
    S_KEENPAIN2,
    S_BRAIN,
    S_BRAIN_PAIN,
    S_BRAIN_DIE1,
    S_BRAIN_DIE2,
    S_BRAIN_DIE3,
    S_BRAIN_DIE4,
    S_BRAINEYE,
    S_BRAINEYESEE,
    S_BRAINEYE1,
    S_SPAWN1,
    S_SPAWN2,
    S_SPAWN3,
    S_SPAWN4,
    S_SPAWNFIRE1,
    S_SPAWNFIRE2,
    S_SPAWNFIRE3,
    S_SPAWNFIRE4,
    S_SPAWNFIRE5,
    S_SPAWNFIRE6,
    S_SPAWNFIRE7,
    S_SPAWNFIRE8,
    S_BRAINEXPLODE1,
    S_BRAINEXPLODE2,
    S_BRAINEXPLODE3,
    S_ARM1,
    S_ARM1A,
    S_ARM2,
    S_ARM2A,
    S_BAR1,
    S_BAR2,
    S_BEXP,
    S_BEXP2,
    S_BEXP3,
    S_BEXP4,
    S_BEXP5,
    S_BBAR1,
    S_BBAR2,
    S_BBAR3,
    S_BON1,
    S_BON1A,
    S_BON1B,
    S_BON1C,
    S_BON1D,
    S_BON1E,
    S_BON2,
    S_BON2A,
    S_BON2B,
    S_BON2C,
    S_BON2D,
    S_BON2E,
    S_BKEY,
    S_BKEY2,
    S_RKEY,
    S_RKEY2,
    S_YKEY,
    S_YKEY2,
    S_BSKULL,
    S_BSKULL2,
    S_RSKULL,
    S_RSKULL2,
    S_YSKULL,
    S_YSKULL2,
    S_STIM,
    S_MEDI,
    S_SOUL,
    S_SOUL2,
    S_SOUL3,
    S_SOUL4,
    S_SOUL5,
    S_SOUL6,
    S_PINV,
    S_PINV2,
    S_PINV3,
    S_PINV4,
    S_PSTR,
    S_PINS,
    S_PINS2,
    S_PINS3,
    S_PINS4,
    S_MEGA,
    S_MEGA2,
    S_MEGA3,
    S_MEGA4,
    S_SUIT,
    S_PMAP,
    S_PMAP2,
    S_PMAP3,
    S_PMAP4,
    S_PMAP5,
    S_PMAP6,
    S_PVIS,
    S_PVIS2,
    S_CLIP,
    S_AMMO,
    S_ROCK,
    S_BROK,
    S_CELL,
    S_CELP,
    S_SHEL,
    S_SBOX,
    S_BPAK,
    S_BFUG,
    S_MGUN,
    S_CSAW,
    S_LAUN,
    S_PLAS,
    S_SHOT,
    S_SHOT2,
    S_COLU,
    S_STALAG,
    S_BLOODYTWITCH,
    S_BLOODYTWITCH2,
    S_BLOODYTWITCH3,
    S_BLOODYTWITCH4,
    S_DEADTORSO,
    S_DEADBOTTOM,
    S_HEADSONSTICK,
    S_GIBS,
    S_HEADONASTICK,
    S_HEADCANDLES,
    S_HEADCANDLES2,
    S_DEADSTICK,
    S_LIVESTICK,
    S_LIVESTICK2,
    S_MEAT2,
    S_MEAT3,
    S_MEAT4,
    S_MEAT5,
    S_STALAGTITE,
    S_TALLGRNCOL,
    S_SHRTGRNCOL,
    S_TALLREDCOL,
    S_SHRTREDCOL,
    S_CANDLESTIK,
    S_CANDELABRA,
    S_SKULLCOL,
    S_TORCHTREE,
    S_BIGTREE,
    S_TECHPILLAR,
    S_EVILEYE,
    S_EVILEYE2,
    S_EVILEYE3,
    S_EVILEYE4,
    S_FLOATSKULL,
    S_FLOATSKULL2,
    S_FLOATSKULL3,
    S_HEARTCOL,
    S_HEARTCOL2,
    S_BLUETORCH,
    S_BLUETORCH2,
    S_BLUETORCH3,
    S_BLUETORCH4,
    S_GREENTORCH,
    S_GREENTORCH2,
    S_GREENTORCH3,
    S_GREENTORCH4,
    S_REDTORCH,
    S_REDTORCH2,
    S_REDTORCH3,
    S_REDTORCH4,
    S_BTORCHSHRT,
    S_BTORCHSHRT2,
    S_BTORCHSHRT3,
    S_BTORCHSHRT4,
    S_GTORCHSHRT,
    S_GTORCHSHRT2,
    S_GTORCHSHRT3,
    S_GTORCHSHRT4,
    S_RTORCHSHRT,
    S_RTORCHSHRT2,
    S_RTORCHSHRT3,
    S_RTORCHSHRT4,
    S_HANGNOGUTS,
    S_HANGBNOBRAIN,
    S_HANGTLOOKDN,
    S_HANGTSKULL,
    S_HANGTLOOKUP,
    S_HANGTNOBRAIN,
    S_COLONGIBS,
    S_SMALLPOOL,
    S_BRAINSTEM,
    S_TECHLAMP,
    S_TECHLAMP2,
    S_TECHLAMP3,
    S_TECHLAMP4,
    S_TECH2LAMP,
    S_TECH2LAMP2,
    S_TECH2LAMP3,
    S_TECH2LAMP4,
    NUMSTATES
} statenum_t;

typedef struct
{
    spritenum_t sprite;
    long long frame;
    long long tics;
    actionf_t action;
    statenum_t nextstate;
    long long misc1, misc2;
} state_t;

typedef enum
{
    MT_PLAYER,
    MT_POSSESSED,
    MT_SHOTGUY,
    MT_VILE,
    MT_FIRE,
    MT_UNDEAD,
    MT_TRACER,
    MT_SMOKE,
    MT_FATSO,
    MT_FATSHOT,
    MT_CHAINGUY,
    MT_TROOP,
    MT_SERGEANT,
    MT_SHADOWS,
    MT_HEAD,
    MT_BRUISER,
    MT_BRUISERSHOT,
    MT_KNIGHT,
    MT_SKULL,
    MT_SPIDER,
    MT_BABY,
    MT_CYBORG,
    MT_PAIN,
    MT_WOLFSS,
    MT_KEEN,
    MT_BOSSBRAIN,
    MT_BOSSSPIT,
    MT_BOSSTARGET,
    MT_SPAWNSHOT,
    MT_SPAWNFIRE,
    MT_BARREL,
    MT_TROOPSHOT,
    MT_HEADSHOT,
    MT_ROCKET,
    MT_PLASMA,
    MT_BFG,
    MT_ARACHPLAZ,
    MT_PUFF,
    MT_BLOOD,
    MT_TFOG,
    MT_IFOG,
    MT_TELEPORTMAN,
    MT_EXTRABFG,
    MT_MISC0,
    MT_MISC1,
    MT_MISC2,
    MT_MISC3,
    MT_MISC4,
    MT_MISC5,
    MT_MISC6,
    MT_MISC7,
    MT_MISC8,
    MT_MISC9,
    MT_MISC10,
    MT_MISC11,
    MT_MISC12,
    MT_INV,
    MT_MISC13,
    MT_INS,
    MT_MISC14,
    MT_MISC15,
    MT_MISC16,
    MT_MEGA,
    MT_CLIP,
    MT_MISC17,
    MT_MISC18,
    MT_MISC19,
    MT_MISC20,
    MT_MISC21,
    MT_MISC22,
    MT_MISC23,
    MT_MISC24,
    MT_MISC25,
    MT_CHAINGUN,
    MT_MISC26,
    MT_MISC27,
    MT_MISC28,
    MT_SHOTGUN,
    MT_SUPERSHOTGUN,
    MT_MISC29,
    MT_MISC30,
    MT_MISC31,
    MT_MISC32,
    MT_MISC33,
    MT_MISC34,
    MT_MISC35,
    MT_MISC36,
    MT_MISC37,
    MT_MISC38,
    MT_MISC39,
    MT_MISC40,
    MT_MISC41,
    MT_MISC42,
    MT_MISC43,
    MT_MISC44,
    MT_MISC45,
    MT_MISC46,
    MT_MISC47,
    MT_MISC48,
    MT_MISC49,
    MT_MISC50,
    MT_MISC51,
    MT_MISC52,
    MT_MISC53,
    MT_MISC54,
    MT_MISC55,
    MT_MISC56,
    MT_MISC57,
    MT_MISC58,
    MT_MISC59,
    MT_MISC60,
    MT_MISC61,
    MT_MISC62,
    MT_MISC63,
    MT_MISC64,
    MT_MISC65,
    MT_MISC66,
    MT_MISC67,
    MT_MISC68,
    MT_MISC69,
    MT_MISC70,
    MT_MISC71,
    MT_MISC72,
    MT_MISC73,
    MT_MISC74,
    MT_MISC75,
    MT_MISC76,
    MT_MISC77,
    MT_MISC78,
    MT_MISC79,
    MT_MISC80,
    MT_MISC81,
    MT_MISC82,
    MT_MISC83,
    MT_MISC84,
    MT_MISC85,
    MT_MISC86,
    NUMMOBJTYPES
} mobjtype_t;

typedef struct
{
    int        doomednum;
    int        spawnstate;
    int        spawnhealth;
    int        seestate;
    int        seesound;
    int        reactiontime;
    int        attacksound;
    int        painstate;
    int        painchance;
    int        painsound;
    int        meleestate;
    int        missilestate;
    int        deathstate;
    int        xdeathstate;
    int        deathsound;
    int        speed;
    int        radius;
    int        height;
    int        mass;
    int        damage;
    int        activesound;
    int        flags;
    int        raisestate;
} mobjinfo_t;

typedef struct
{
    unsigned char* sequence;
    unsigned char* p;
} cheatseq_t;

typedef int fixed_t;

typedef struct
{
    char* name;
    int* location;
    int defaultvalue;
    int scantranslate; // PC scan code hack
    int untranslated; // lousy hack
    char** text_location; // [pd] int* location was used to store text pointer. Can't change to intptr_t unless we change all settings type
    char* default_text_value; // [pd] So we don't change defaultvalue behavior for int to intptr_t
} default_t;

struct sfxinfo_struct
{
    // up to 6-character name
    char* name;

    // Sfx singularity (only one at a time)
    int singularity;

    // Sfx priority
    int priority;

    // referenced sound if a link
    sfxinfo_t* link;

    // pitch if a link
    int pitch;

    // volume if a link
    int volume;

    // sound data
    void* data;

    // this is checked every second to see if sound
    // can be thrown out (if 0, then decrement, if -1,
    // then throw out, if > 0, then it is in use)
    int usefulness;

    // lump number of sfx
    int lumpnum;
};

typedef struct
{
    // up to 6-character name
    char* name;

    // lump number of music
    int lumpnum;

    // music data
    void* data;

    // music handle once registered
    int handle;
} musicinfo_t;

typedef enum
{
    sfx_None,
    sfx_pistol,
    sfx_shotgn,
    sfx_sgcock,
    sfx_dshtgn,
    sfx_dbopn,
    sfx_dbcls,
    sfx_dbload,
    sfx_plasma,
    sfx_bfg,
    sfx_sawup,
    sfx_sawidl,
    sfx_sawful,
    sfx_sawhit,
    sfx_rlaunc,
    sfx_rxplod,
    sfx_firsht,
    sfx_firxpl,
    sfx_pstart,
    sfx_pstop,
    sfx_doropn,
    sfx_dorcls,
    sfx_stnmov,
    sfx_swtchn,
    sfx_swtchx,
    sfx_plpain,
    sfx_dmpain,
    sfx_popain,
    sfx_vipain,
    sfx_mnpain,
    sfx_pepain,
    sfx_slop,
    sfx_itemup,
    sfx_wpnup,
    sfx_oof,
    sfx_telept,
    sfx_posit1,
    sfx_posit2,
    sfx_posit3,
    sfx_bgsit1,
    sfx_bgsit2,
    sfx_sgtsit,
    sfx_cacsit,
    sfx_brssit,
    sfx_cybsit,
    sfx_spisit,
    sfx_bspsit,
    sfx_kntsit,
    sfx_vilsit,
    sfx_mansit,
    sfx_pesit,
    sfx_sklatk,
    sfx_sgtatk,
    sfx_skepch,
    sfx_vilatk,
    sfx_claw,
    sfx_skeswg,
    sfx_pldeth,
    sfx_pdiehi,
    sfx_podth1,
    sfx_podth2,
    sfx_podth3,
    sfx_bgdth1,
    sfx_bgdth2,
    sfx_sgtdth,
    sfx_cacdth,
    sfx_skldth,
    sfx_brsdth,
    sfx_cybdth,
    sfx_spidth,
    sfx_bspdth,
    sfx_vildth,
    sfx_kntdth,
    sfx_pedth,
    sfx_skedth,
    sfx_posact,
    sfx_bgact,
    sfx_dmact,
    sfx_bspact,
    sfx_bspwlk,
    sfx_vilact,
    sfx_noway,
    sfx_barexp,
    sfx_punch,
    sfx_hoof,
    sfx_metal,
    sfx_chgun,
    sfx_tink,
    sfx_bdopn,
    sfx_bdcls,
    sfx_itmbk,
    sfx_flame,
    sfx_flamst,
    sfx_getpow,
    sfx_bospit,
    sfx_boscub,
    sfx_bossit,
    sfx_bospn,
    sfx_bosdth,
    sfx_manatk,
    sfx_mandth,
    sfx_sssit,
    sfx_ssdth,
    sfx_keenpn,
    sfx_keendt,
    sfx_skeact,
    sfx_skesit,
    sfx_skeatk,
    sfx_radio,
    NUMSFX
} sfxenum_t;

typedef enum
{
    AutomapState,
    FirstPersonState
} st_stateenum_t;

typedef enum
{
    StartChatState,
    WaitDestState,
    GetChatState
} st_chatstateenum_t;

typedef unsigned angle_t;

typedef struct mobj_s
{
    // List: thinker links.
    thinker_t thinker;

    // Info for drawing: position.
    fixed_t x;
    fixed_t y;
    fixed_t z;

    // More list: links in sector (if needed)
    struct mobj_s* snext;
    struct mobj_s* sprev;

    //More drawing info: to determine current sprite.
    angle_t angle;        // orientation
    spritenum_t sprite;        // used to find patch_t and flip value
    int frame;        // might be ORed with FF_FULLBRIGHT

    // Interaction info, by BLOCKMAP.
    // Links in blocks (if needed).
    struct mobj_s* bnext;
    struct mobj_s* bprev;

    struct subsector_s* subsector;

    // The closest interval over all contacted Sectors.
    fixed_t floorz;
    fixed_t ceilingz;

    // For movement checking.
    fixed_t radius;
    fixed_t height;

    // Momentums, used to update position.
    fixed_t momx;
    fixed_t momy;
    fixed_t momz;

    // If == validcount, already checked.
    int validcount;

    mobjtype_t type;
    mobjinfo_t* info; // &mobjinfo[mobj->type]

    int tics; // state tic counter
    state_t* state;
    int flags;
    int health;

    // Movement direction, movement generation (zig-zagging).
    int movedir; // 0-7
    int movecount; // when 0, select a new dir

    // Thing being chased/attacked (or 0),
    // also the originator for missiles.
    struct mobj_s* target;

    // Reaction time: if non 0, don't attack yet.
    // Used by player to freeze a bit after teleporting.
    int reactiontime;

    // If >0, the target will be chased
    // no matter what (even if shot)
    int threshold;

    // Additional info record for player avatars only.
    // Only valid if type == MT_PLAYER
    struct player_s* player;

    // Player number last looked for.
    int lastlook;

    // For nightmare respawn.
    mapthing_t spawnpoint;

    // Thing being chased/attacked for tracers.
    struct mobj_s* tracer;
} mobj_t;

typedef enum
{
    ps_weapon,
    ps_flash,
    NUMPSPRITES
} psprnum_t;

typedef struct
{
    state_t* state;        // a 0 state means not active
    int tics;
    fixed_t sx;
    fixed_t sy;
} pspdef_t;

typedef enum
{
    // Playing or camping.
    PST_LIVE,
    // Dead on the ground, view follows killer.
    PST_DEAD,
    // Ready to restart/respawn???
    PST_REBORN
} playerstate_t;

typedef enum
{
    // No clipping, walk through barriers.
    CF_NOCLIP = 1,
    // No damage, no health loss.
    CF_GODMODE = 2,
    // Not really a cheat, just a debug aid.
    CF_NOMOMENTUM = 4
} cheat_t;

typedef struct player_s
{
    mobj_t* mo;
    playerstate_t playerstate;
    ticcmd_t cmd;

    // Determine POV,
    //  including viewpoint bobbing during movement.
    // Focal origin above r.z
    fixed_t viewz;
    // Base height above floor for viewz.
    fixed_t viewheight;
    // Bob/squat speed.
    fixed_t deltaviewheight;
    // bounded/scaled total momentum.
    fixed_t bob;

    // This is only used between levels,
    // mo->health is used during levels.
    int health;
    int armorpoints;
    // Armor type is 0-2.
    int armortype;

    // Power ups. invinc and invis are tic counters.
    int powers[NUMPOWERS];
    doom_boolean cards[NUMCARDS];
    doom_boolean backpack;

    // Frags, kills of other players.
    int frags[MAXPLAYERS];
    weapontype_t readyweapon;

    // Is wp_nochange if not changing.
    weapontype_t pendingweapon;

    doom_boolean weaponowned[NUMWEAPONS];
    int ammo[NUMAMMO];
    int maxammo[NUMAMMO];

    // True if button down last tic.
    int attackdown;
    int usedown;

    // Bit flags, for cheats and debug.
    // See cheat_t, above.
    int cheats;

    // Refired shots are less accurate.
    int refire;

    // For intermission stats.
    int killcount;
    int itemcount;
    int secretcount;

    // Hint messages.
    char* message;

    // For screen flashing (red or bright).
    int damagecount;
    int bonuscount;

    // Who did damage (0 for floors/ceilings).
    mobj_t* attacker;

    // So gun flashes light up areas.
    int extralight;

    // Current PLAYPAL, ???
    //  can be set to REDCOLORMAP for pain, etc.
    int fixedcolormap;

    // Player skin colorshift,
    //  0-3 for which color to draw player.
    int colormap;

    // Overlay view sprites (gun, etc).
    pspdef_t psprites[NUMPSPRITES];

    // True if secret level has been done.
    doom_boolean didsecret;
} player_t;

typedef struct
{
    doom_boolean in;        // whether the player is in game

    // Player stats, kills, collected items etc.
    int skills;
    int sitems;
    int ssecret;
    int stime;
    int frags[4];
    int score;        // current score on entry, modified on return
} wbplayerstruct_t;

typedef struct
{
    int epsd;        // episode # (0-2)

    // if true, splash the secret level
    doom_boolean didsecret;

    // previous and next levels, origin 0
    int last;
    int next;

    int maxkills;
    int maxitems;
    int maxsecret;
    int maxfrags;

    // the par time
    int partime;

    // index of this player in game
    int pnum;

    wbplayerstruct_t plyr[MAXPLAYERS];
} wbstartstruct_t;

typedef struct
{
    // High bit is retransmit request.
    unsigned checksum;
    // Only valid if NCMD_RETRANSMIT.
    byte retransmitfrom;

    byte starttic;
    byte player;
    byte numtics;
    ticcmd_t cmds[BACKUPTICS];
} doomdata_t;

typedef struct
{
    // Supposed to be DOOMCOM_ID?
    long long id;

    // DOOM executes an int to execute commands.
    short intnum;
    // Communication between DOOM and the driver.
    // Is CMD_SEND or CMD_GET.
    short command;
    // Is dest for send, set by get (-1 = no packet).
    short remotenode;

    // Number of bytes in doomdata to be sent
    short datalength;

    // Info common to all nodes.
    // Console is allways node 0.
    short numnodes;
    // Flag: 1 = no duplication, 2-5 = dup for slow nets.
    short ticdup;
    // Flag: 1 = send a backup tic in every packet.
    short extratics;
    // Flag: 1 = deathmatch.
    short deathmatch;
    // Flag: -1 = new game, 0-5 = load savegame
    short savegame;
    short episode;  // 1-3
    short map;      // 1-9
    short skill;    // 1-5

    // Info specific to this node.
    short consoleplayer;
    short numplayers;

    // These are related to the 3-display mode,
    //  in which two drones looking left and right
    //  were used to render two additional views
    //  on two additional computers.
    // Probably not operational anymore.
    // 1 = left, 0 = center, -1 = right
    short angleoffset;
    // 1 = drone
    short drone;

    // The packet data to be sent.
    doomdata_t data;
} doomcom_t;

typedef struct
{
    fixed_t        x;
    fixed_t        y;
} vertex_t;

struct line_s;

typedef struct
{
    thinker_t                thinker;        // not used for anything
    fixed_t                x;
    fixed_t                y;
    fixed_t                z;
} degenmobj_t;

typedef struct
{
    fixed_t floorheight;
    fixed_t ceilingheight;
    short floorpic;
    short ceilingpic;
    short lightlevel;
    short special;
    short tag;

    // 0 = untraversed, 1,2 = sndlines -1
    int soundtraversed;

    // thing that made a sound (or null)
    mobj_t* soundtarget;

    // mapblock bounding box for height changes
    int blockbox[4];

    // origin for any sounds played by the sector
    degenmobj_t soundorg;

    // if == validcount, already checked
    int validcount;

    // list of mobjs in sector
    mobj_t* thinglist;

    // thinker_t for reversable actions
    void* specialdata;

    int linecount;
    struct line_s** lines;        // [linecount] size
} sector_t;

typedef struct
{
    // add this to the calculated texture column
    fixed_t textureoffset;

    // add this to the calculated texture top
    fixed_t rowoffset;

    // Texture indices.
    // We do not maintain names here. 
    short toptexture;
    short bottomtexture;
    short midtexture;

    // Sector the SideDef is facing.
    sector_t* sector;
} side_t;

typedef enum
{
    ST_HORIZONTAL,
    ST_VERTICAL,
    ST_POSITIVE,
    ST_NEGATIVE
} slopetype_t;

typedef struct line_s
{
    // Vertices, from v1 to v2.
    vertex_t* v1;
    vertex_t* v2;

    // Precalculated v2 - v1 for side checking.
    fixed_t dx;
    fixed_t dy;

    // Animation related.
    short flags;
    short special;
    short tag;

    // Visual appearance: SideDefs.
    // sidenum[1] will be -1 if one sided
    short sidenum[2];

    // Neat. Another bounding box, for the extent
    // of the LineDef.
    fixed_t bbox[4];

    // To aid move clipping.
    slopetype_t slopetype;

    // Front and back sector.
    // Note: redundant? Can be retrieved from SideDefs.
    sector_t* frontsector;
    sector_t* backsector;

    // if == validcount, already checked
    int validcount;

    // thinker_t for reversable actions
    void* specialdata;
} line_t;

typedef struct subsector_s
{
    sector_t* sector;
    short numlines;
    short firstline;
} subsector_t;

typedef struct
{
    vertex_t* v1;
    vertex_t* v2;

    fixed_t offset;

    angle_t angle;

    side_t* sidedef;
    line_t* linedef;

    // Sector references.
    // Could be retrieved from linedef, too.
    // backsector is 0 for one sided lines
    sector_t* frontsector;
    sector_t* backsector;
} seg_t;

typedef struct
{
    // Partition line.
    fixed_t x;
    fixed_t y;
    fixed_t dx;
    fixed_t dy;

    // Bounding box for each child.
    fixed_t bbox[2][4];

    // If NF_SUBSECTOR its a subsector.
    unsigned short children[2];
} node_t;

typedef struct
{
    byte topdelta;        // -1 is the last post in a column
    byte length;         // length data bytes follows
} post_t;

typedef post_t column_t;

typedef byte lighttable_t;

typedef struct drawseg_s
{
    seg_t* curline;
    int x1;
    int x2;

    fixed_t scale1;
    fixed_t scale2;
    fixed_t scalestep;

    // 0=none, 1=bottom, 2=top, 3=both
    int silhouette;

    // do not clip sprites above this
    fixed_t bsilheight;

    // do not clip sprites below this
    fixed_t tsilheight;

    // Pointers to lists for sprite clipping,
    //  all three adjusted so [x1] is first value.
    short* sprtopclip;
    short* sprbottomclip;
    short* maskedtexturecol;
} drawseg_t;

typedef struct
{
    short width;                // bounding box size 
    short height;
    short leftoffset;        // pixels to the left of origin 
    short topoffset;        // pixels below the origin 
    int columnofs[8];        // only [width] used
    // the [0] is &columnofs[width] 
} patch_t;

typedef struct vissprite_s
{
    // Doubly linked list.
    struct vissprite_s* prev;
    struct vissprite_s* next;

    int x1;
    int x2;

    // for line side calculation
    fixed_t gx;
    fixed_t gy;

    // global bottom / top for silhouette clipping
    fixed_t gz;
    fixed_t gzt;

    // horizontal position of x1
    fixed_t startfrac;

    fixed_t scale;

    // negative if flipped
    fixed_t xiscale;

    fixed_t texturemid;
    int patch;

    // for color translation and shadow draw,
    //  maxbright frames as well
    lighttable_t* colormap;

    int mobjflags;
} vissprite_t;

typedef struct
{
    // If false use 0 for any position.
    // Note: as eight entries are available,
    //  we might as well insert the same name eight times.
    doom_boolean rotate;

    // Lump to use for view angles 0-7.
    short lump[8];

    // Flip bit (1 = flip) to use for view angles 0-7.
    byte flip[8];
} spriteframe_t;

typedef struct
{
    int numframes;
    spriteframe_t* spriteframes;
} spritedef_t;

typedef struct
{
    fixed_t height;
    int picnum;
    int lightlevel;
    int minx;
    int maxx;

    // leave pads for [minx-1]/[maxx+1]

    byte pad1;
    // Here lies the rub for all
    //  dynamic resize/change of resolution.
    byte top[SCREENWIDTH];
    byte pad2;
    byte pad3;
    // See above.
    byte bottom[SCREENWIDTH];
    byte pad4;
} visplane_t;

typedef struct
{
    // left-justified position of scrolling text window
    int x;
    int y;

    patch_t** f;                        // font
    int sc;                        // start character
    char l[HU_MAXLINELENGTH + 1];        // line of text
    int len;                              // current line length

    // whether this line needs to be udpated
    int needsupdate;
} hu_textline_t;

typedef struct
{
    hu_textline_t l[HU_MAXLINES];        // text lines to draw
    int h;                // height in lines
    int cl;                // current line number

    // pointer to doom_boolean stating whether to update window
    doom_boolean* on;
    doom_boolean laston;                // last value of *->on.
} hu_stext_t;

typedef struct
{
    hu_textline_t l;                // text line to input on

     // left margin past which I am not to delete characters
    int lm;

    // pointer to doom_boolean stating whether to update window
    doom_boolean* on;
    doom_boolean laston; // last value of *->on;
} hu_itext_t;

typedef struct
{
    char* name1;
    char* name2;
    short episode;
} switchlist_t;

typedef enum
{
    top,
    middle,
    bottom
} bwhere_e;

typedef struct
{
    line_t* line;
    bwhere_e where;
    int btexture;
    int btimer;
    mobj_t* soundorg;
} button_t;

typedef enum
{
    up,
    down,
    waiting,
    in_stasis
} plat_e;

typedef enum
{
    perpetualRaise,
    downWaitUpStay,
    raiseAndChange,
    raiseToNearestAndChange,
    blazeDWUS
} plattype_e;

typedef struct
{
    thinker_t thinker;
    sector_t* sector;
    fixed_t speed;
    fixed_t low;
    fixed_t high;
    int wait;
    int count;
    plat_e status;
    plat_e oldstatus;
    doom_boolean crush;
    int tag;
    plattype_e type;
} plat_t;

typedef enum
{
    door_normal,
    close30ThenOpen,
    door_close,
    door_open,
    raiseIn5Mins,
    blazeRaise,
    blazeOpen,
    blazeClose
} vldoor_e;

typedef enum
{
    lowerToFloor,
    raiseToHighest,
    lowerAndCrush,
    crushAndRaise,
    fastCrushAndRaise,
    silentCrushAndRaise
} ceiling_e;

typedef struct
{
    thinker_t thinker;
    ceiling_e type;
    sector_t* sector;
    fixed_t bottomheight;
    fixed_t topheight;
    fixed_t speed;
    doom_boolean crush;

    // 1 = up, 0 = waiting, -1 = down
    int direction;

    // ID
    int tag;
    int olddirection;
} ceiling_t;

typedef enum
{
    // lower floor to highest surrounding floor
    lowerFloor,

    // lower floor to lowest surrounding floor
    lowerFloorToLowest,

    // lower floor to highest surrounding floor VERY FAST
    turboLower,

    // raise floor to lowest surrounding CEILING
    raiseFloor,

    // raise floor to next highest surrounding floor
    raiseFloorToNearest,

    // raise floor to shortest height texture around it
    raiseToTexture,

    // lower floor to lowest surrounding floor
    //  and change floorpic
    lowerAndChange,

    raiseFloor24,
    raiseFloor24AndChange,
    raiseFloorCrush,

    // raise to next highest floor, turbo-speed
    raiseFloorTurbo,
    donutRaise,
    raiseFloor512
} floor_e;

typedef void (*planefunction_t) (int top, int bottom);

typedef struct
{
    fixed_t x;
    fixed_t y;
    fixed_t dx;
    fixed_t dy;
} divline_t;

typedef struct
{
    fixed_t frac; // along trace line
    doom_boolean isaline;
    union
    {
        mobj_t* thing;
        line_t* line;
    } d;
} intercept_t;

typedef struct
{
    // upper right-hand corner
    //  of the number (right-justified)
    int x;
    int y;

    // max # of digits in number
    int width;

    // last number value
    int oldnum;

    // pointer to current value
    int* num;

    // pointer to doom_boolean stating
    //  whether to update number
    doom_boolean* on;

    // list of patches for 0-9
    patch_t** p;

    // user data
    int data;
} st_number_t;

typedef struct
{
    // number information
    st_number_t n;

    // percent sign graphic
    patch_t* p;
} st_percent_t;

typedef struct
{
    // center-justified location of icons
    int x;
    int y;

    // last icon number
    int oldinum;

    // pointer to current icon
    int* inum;

    // pointer to doom_boolean stating
    //  whether to update icon
    doom_boolean* on;

    // list of icons
    patch_t** p;

    // user data
    int data;
} st_multicon_t;

typedef struct
{
    // center-justified location of icon
    int x;
    int y;

    // last icon value
    int oldval;

    // pointer to current icon status
    doom_boolean* val;

    // pointer to doom_boolean
    //  stating whether to update icon
    doom_boolean* on;


    patch_t* p; // icon
    int data;   // user data

} st_binicon_t;

typedef struct
{
    char name[8];
    void* handle;
    int position;
    int size;
} lumpinfo_t;

typedef enum
{
    NoState = -1,
    StatCount,
    ShowNextLoc
} stateenum_t;

typedef struct memblock_s
{
    int size;       // including the header and possibly tiny fragments
    void** user;    // 0 if a free block
    int tag;        // purgelevel
    int id;         // should be ZONEID
    struct memblock_s* next;
    struct memblock_s* prev;
} memblock_t;

typedef struct
{
    fixed_t                x, y;
} mpoint_t;

typedef struct
{
    mpoint_t a, b;
} mline_t;

typedef struct
{
    char* name;
    mobjtype_t type;
} castinfo_t;

typedef struct
{
    char ID[4];
    unsigned short scoreLen;
    unsigned short scoreStart;
    unsigned short channels;
    unsigned short sec_channels;
    unsigned short instrCnt;
    unsigned short dummy;
} mus_header_t;

typedef struct
{
    // 0 = no cursor here, 1 = ok, 2 = arrows ok
    short status;

    char* name;

    // choice = menu item #.
    // if status = 2,
    //   choice=0:leftarrow,1:rightarrow
    void (*routine)(int choice);

    // hotkey in menu
    char alphaKey;
} menuitem_t;

typedef struct menu_s
{
    short numitems; // # of menu items
    struct menu_s* prevMenu; // previous menu
    menuitem_t* menuitems; // menu items
    void (*routine)(); // draw routine
    short x;
    short y; // x,y of menu
    short lastOn; // last item user was on in menu
} menu_t;

typedef struct
{
    char* lump;
    int x, w;
    int offx;
    int offy;
} menu_custom_text_seg_t;

typedef struct
{
    char* name;
    menu_custom_text_seg_t segs[16];
} menu_custom_text_t;

typedef enum
{
    DI_EAST,
    DI_NORTHEAST,
    DI_NORTH,
    DI_NORTHWEST,
    DI_WEST,
    DI_SOUTHWEST,
    DI_SOUTH,
    DI_SOUTHEAST,
    DI_NODIR,
    NUMDIRS
} dirtype_t;

typedef struct
{
    doom_boolean istexture;
    int picnum;
    int basepic;
    int numpics;
    int speed;
} anim_t;

typedef struct
{
    doom_boolean istexture; // if false, it is a flat
    char* endname;
    char* startname;
    int speed;
} animdef_t;

typedef struct
{
    int first;
    int last;
} cliprange_t;

typedef struct
{
    short originx;
    short originy;
    short patch;
    short stepdir;
    short colormap;
} mappatch_t;

typedef struct
{
    // Block origin (allways UL),
    // which has allready accounted
    // for the internal origin of the patch.
    int originx;
    int originy;
    int patch;
} texpatch_t;

typedef struct
{
    // Keep name for switch changing, etc.
    char name[8];
    short width;
    short height;

    // All the patches[patchcount]
    //  are drawn back to front into the cached texture.
    short patchcount;
    texpatch_t patches[1];
} texture_t;

typedef struct
{
    // sound information (if null, channel avail.)
    sfxinfo_t* sfxinfo;

    // origin of sound
    void* origin;

    // handle of the sound being played
    int handle;
} channel_t;

typedef enum
{
    ANIM_ALWAYS,
    ANIM_RANDOM,
    ANIM_LEVEL
} animenum_t;

typedef struct
{
    int x;
    int y;
} point_t;

typedef struct
{
    animenum_t type;

    // period in tics between animations
    int period;

    // number of animation frames
    int nanims;

    // location of animation
    point_t loc;

    // ALWAYS: n/a,
    // RANDOM: period deviation (<256),
    // LEVEL: level
    int data1;

    // ALWAYS: n/a,
    // RANDOM: random base period,
    // LEVEL: n/a
    int data2;

    // actual graphics for frames of animations
    patch_t* p[3];

    // following must be initialized to zero before use!

    // next value of bcnt (used in conjunction with period)
    int nexttic;

    // last drawn animation frame
    int lastdrawn;

    // next frame number to animate
    int ctr;

    // used by RANDOM and LEVEL when animating
    int state;
} anim_t_wi_stuff;

typedef struct
{
    // total bytes malloced, including header
    int size;

    // start / end cap for linked list
    memblock_t blocklist;

    memblock_t* rover;
} memzone_t;

// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// VARIABLES (grouped by type)
// -----------------------------------------------------------------------------

// int

int totalkills, totalitems, totalsecret;

int last_update_time;

int button_states[3];

int cheating;

int grid;

int leveljuststarted;

int finit_width;

int finit_height;

int f_x;

int f_y;

int f_w;

int f_h;

int lightlev;

int amclock;

int markpointnum;

int followplayer;

int startepisode;

int startmap;

int eventhead;

int eventtail;

int demosequence;

int pagetic;

int nettics[MAXNETNODES];

int resendto[MAXNETNODES];

int resendcount[MAXNETNODES];

int nodeforplayer[MAXPLAYERS];

int maketic;

int lastnettic;

int skiptics;

int ticdup;

int maxsend;

int gametime;

int frametics[4];

int frameon;

int frameskip[4];

int oldnettics;

int finalestage;

int finalecount;

int castnum;

int casttics;

int castframes;

int castonmelee;

int gameepisode;

int gamemap;

int starttime;

int consoleplayer;

int displayplayer;

int gametic;

int levelstarttic;

int key_right;

int key_left;

int key_up;

int key_down;

int key_strafeleft;

int key_straferight;

int key_fire;

int key_use;

int key_strafe;

int key_speed;

int mousebfire;

int mousebstrafe;

int mousebforward;

int mousemove;

int joybfire;

int joybstrafe;

int joybuse;

int joybspeed;

int turnheld;

int mousex;

int mousey;

int dclicktime;

int dclickstate;

int dclicks;

int dclicktime2;

int dclickstate2;

int dclicks2;

int joyxmove;

int joyymove;

int savegameslot;

int bodyqueslot;

int pars[4][10];

int cpars[32];

int d_episode;

int d_map;

int message_counter;

int head = 0;

int tail = 0;

int flag;

int mus_offset;

int mus_delay;

int mus_volume;

int mus_channel_volumes[16];

int looping;

int musicdies;

int lengths[NUMSFX];

int audio_fd;

int channelstart[NUM_CHANNELS];

int channelhandles[NUM_CHANNELS];

int channelids[NUM_CHANNELS];

int steptable[256];

int vol_lookup[128 * 256];

int queue_midi_head;

int queue_midi_tail;

int mb_used;

int myargc;

int firsttime;

int mouseSensitivity;

int showMessages;

int detailLevel;

int screenblocks;

int screenSize;

int quickSaveSlot;

int messageToPrint;

int messx;

int messy;

int messageLastMenuActive;

int saveStringEnter;

int saveSlot;

int saveCharIndex;

int custom_texts_count;

int epi;

int quitsounds[8];

int quitsounds2[8];

int usemouse;

int usejoystick;

int crosshair;

int always_run;

int numdefaults;

int rndindex;

int prndindex;

int TRACEANGLE = 0xc000000;

int numbraintargets;

int braintargeton;

int        maxammo[NUMAMMO];

int        clipammo[NUMAMMO];

int tmflags;

int numspechit;

int la_damage;

int bombdamage;

int ptflags;

int itemrespawntime[ITEMQUESIZE];

int iquehead;

int iquetail;

int numvertexes;

int numsegs;

int numsectors;

int numsubsectors;

int numnodes;

int numlines;

int numsides;

int bmapwidth;

int bmapheight;

int sightcounts[2];

int levelTimeCount;

int switchlist[MAXSWITCHES * 2];

int numswitches;

int leveltime;

int checkcoord[12][4];

int firstflat;

int lastflat;

int numflats;

int firstpatch;

int lastpatch;

int numpatches;

int firstspritelump;

int lastspritelump;

int numspritelumps;

int numtextures;

int flatmemory;

int texturememory;

int spritememory;

int viewwidth;

int scaledviewwidth;

int viewheight;

int viewwindowx;

int viewwindowy;

int columnofs[MAXWIDTH];

int dc_x;

int dc_yl;

int dc_yh;

int dccount;

int fuzzoffset[FUZZTABLE];

int fuzzpos;

int ds_y;

int ds_x1;

int ds_x2;

int dscount;

int viewangleoffset;

int validcount = 1;

int centerx;

int centery;

int framecount;

int sscount;

int linecount;

int loopcount;

int detailshift;

int viewangletox[FINEANGLES / 2];

int extralight;

int setblocks;

int setdetail;

int spanstart[SCREENHEIGHT];

int spanstop[SCREENHEIGHT];

int toptexture;

int bottomtexture;

int midtexture;

int rw_angle1;

int rw_x;

int rw_stopx;

int worldtop;

int worldbottom;

int worldhigh;

int worldlow;

int skyflatnum;

int skytexture;

int skytexturemid;

int numsprites;

int maxframe;

int newvissprite;

int nextcleanup;

int snd_SfxVolume;

int snd_MusicVolume;

int numChannels;

int veryfirsttime;

int lu_palette;

int st_msgcounter;

int st_fragscount;

int st_oldhealth;

int st_facecount;

int st_faceindex;

int keyboxes[3];

int st_randomnumber;

int st_palette;

int dirtybox[4];

int usegamma;

int numlumps;

int reloadlump;

int info[2500][10];

int profilecount;

int NUMANIMS[NUMEPISODES];

int acceleratestage;

int me;

int cnt;

int bcnt;

int firstrefresh;

int cnt_kills[MAXPLAYERS];

int cnt_items[MAXPLAYERS];

int cnt_secret[MAXPLAYERS];

int cnt_time;

int cnt_par;

int cnt_pause;

int NUMCMAPS;

int dm_state;

int dm_frags[MAXPLAYERS][MAXPLAYERS];

int dm_totals[MAXPLAYERS];

int cnt_frags[MAXPLAYERS];

int dofrags;

int ng_state;

int sp_state;

// int*

int* y;

int* channelleftvol_lookup[NUM_CHANNELS];

int* channelrightvol_lookup[NUM_CHANNELS];

int* texturewidthmask;

int* texturecompositesize;

int* flattranslation;

int* texturetranslation;

int* finetangent;

int* finesine;

// unsigned int

unsigned int channelstep[NUM_CHANNELS];

unsigned int channelstepremainder[NUM_CHANNELS];

unsigned int st_clock;

// short

short consistancy[MAXPLAYERS][BACKUPTICS];

short itemOn;

short skullAnimCounter;

short whichSkull;

short numlinespecials;

short openings[MAXOPENINGS];

short floorclip[SCREENWIDTH];

short ceilingclip[SCREENWIDTH];

short negonearray[SCREENWIDTH];

short screenheightarray[SCREENWIDTH];

// short*

short* blockmap;

short* blockmaplump;

short* lastopening;

short* maskedtexturecol;

short* mfloorclip;

short* mceilingclip;

// short**

short** texturecolumnlump;

// signed short

signed short mixbuffer[MIXBUFFERSIZE];

// unsigned long

unsigned long long queued_midi_msgs[MAX_QUEUED_MIDI_MSGS];

// char

char itoa_buf[20];

char error_buf[260];

char wadfile[1024];

char mapdir[1024];

char basedefault[1024];

char title[128];

char exitmsg[80];

char demoname[32];

char savedescription[32];

char savename[256];

char chat_dest[MAXPLAYERS];

char chatchars[QUEUESIZE];

char french_shiftxform[128];

char english_shiftxform[128];

char frenchKeyMap[128];

char chat_char;

char saveOldString[SAVESTRINGSIZE];

char savegamestrings[10][SAVESTRINGSIZE];

char endstring[160];

char tempstring[80];

// char*

char* wadfiles[MAXWADFILES];

char* pagename;

char* doom1_endmsg[8];

char* doom2_endmsg[8];

char* e1text;

char* e2text;

char* e3text;

char* e4text;

char* c1text;

char* c2text;

char* c3text;

char* c4text;

char* c5text;

char* c6text;

char* p1text;

char* p2text;

char* p3text;

char* p4text;

char* p5text;

char* p6text;

char* t1text;

char* t2text;

char* t3text;

char* t4text;

char* t5text;

char* t6text;

char* finaletext;

char* finaleflat;

char* defdemoname;

char* chat_macros[10];

char* player_names[4];

char* shiftxform;

char* mapnames[45];

char* mapnames2[32];

char* mapnamesp[32];

char* mapnamest[32];

char* messageString;

char* gammamsg[5];

char* skullName[2];

char* detailNames[2];

char* msgNames[2];

char* defaultfile;

char* spritename;

char* reloadname;

// char**

char** sprnames;

char** myargv;

// unsigned char

unsigned char cheat_amap_seq[5];

unsigned char screen_palette[256 * 3];

unsigned char cheat_xlate_table[256];

unsigned char rndtable[256];

unsigned char cheat_mus_seq[9];

unsigned char cheat_choppers_seq[11];

unsigned char cheat_god_seq[6];

unsigned char cheat_ammo_seq[6];

unsigned char cheat_ammonokey_seq[5];

unsigned char cheat_noclip_seq[11];

unsigned char cheat_commercial_noclip_seq[7];

unsigned char cheat_powerup_seq[7][10];

unsigned char cheat_clev_seq[10];

unsigned char cheat_mypos_seq[8];

// unsigned char*

unsigned char* screen_buffer;

unsigned char* final_screen_buffer;

unsigned char* mus_data;

unsigned char* channels[NUM_CHANNELS];

unsigned char* channelsend[NUM_CHANNELS];

// byte

byte translations[3][256];

byte gammatable[5][256];

// byte*

byte* fb;

byte* wipe_scr_start;

byte* wipe_scr_end;

byte* wipe_scr;

byte* demobuffer;

byte* demo_p;

byte* demoend;

byte* savebuffer;

byte* save_p;

byte* rejectmatrix;

byte* viewimage;

byte* ylookup[MAXHEIGHT];

byte* dc_source;

byte* dc_translation;

byte* translationtables;

byte* ds_source;

byte* screens[5];

// byte**

byte** texturecomposite;

// fixed_t

fixed_t m_x, m_y;

fixed_t m_x2, m_y2;

fixed_t old_m_w, old_m_h;

fixed_t old_m_x, old_m_y;

fixed_t mtof_zoommul;

fixed_t ftom_zoommul;

fixed_t m_w;

fixed_t m_h;

fixed_t min_x;

fixed_t min_y;

fixed_t max_x;

fixed_t max_y;

fixed_t max_w;

fixed_t max_h;

fixed_t min_w;

fixed_t min_h;

fixed_t min_scale_mtof;

fixed_t max_scale_mtof;

fixed_t scale_mtof;

fixed_t scale_ftom;

fixed_t forwardmove[2];

fixed_t sidemove[2];

fixed_t angleturn[3];

fixed_t xspeed[8];

fixed_t yspeed[8];

fixed_t viletryx;

fixed_t viletryy;

fixed_t tmbbox[4];

fixed_t tmx;

fixed_t tmy;

fixed_t tmfloorz;

fixed_t tmceilingz;

fixed_t tmdropoffz;

fixed_t shootz;

fixed_t attackrange;

fixed_t aimslope;

fixed_t bestslidefrac;

fixed_t secondslidefrac;

fixed_t tmxmove;

fixed_t tmymove;

fixed_t opentop;

fixed_t openbottom;

fixed_t openrange;

fixed_t lowfloor;

fixed_t swingx;

fixed_t swingy;

fixed_t bulletslope;

fixed_t bmaporgx;

fixed_t bmaporgy;

fixed_t sightzstart;

fixed_t topslope;

fixed_t bottomslope;

fixed_t t2x;

fixed_t t2y;

fixed_t dc_iscale;

fixed_t dc_texturemid;

fixed_t ds_xfrac;

fixed_t ds_yfrac;

fixed_t ds_xstep;

fixed_t ds_ystep;

fixed_t centerxfrac;

fixed_t centeryfrac;

fixed_t projection;

fixed_t viewx;

fixed_t viewy;

fixed_t viewz;

fixed_t viewcos;

fixed_t viewsin;

fixed_t planeheight;

fixed_t yslope[SCREENHEIGHT];

fixed_t distscale[SCREENWIDTH];

fixed_t basexscale;

fixed_t baseyscale;

fixed_t cachedheight[SCREENHEIGHT];

fixed_t cacheddistance[SCREENHEIGHT];

fixed_t cachedxstep[SCREENHEIGHT];

fixed_t cachedystep[SCREENHEIGHT];

fixed_t rw_offset;

fixed_t rw_distance;

fixed_t rw_scale;

fixed_t rw_scalestep;

fixed_t rw_midtexturemid;

fixed_t rw_toptexturemid;

fixed_t rw_bottomtexturemid;

fixed_t pixhigh;

fixed_t pixlow;

fixed_t pixhighstep;

fixed_t pixlowstep;

fixed_t topfrac;

fixed_t topstep;

fixed_t bottomfrac;

fixed_t bottomstep;

fixed_t pspritescale;

fixed_t pspriteiscale;

fixed_t spryscale;

fixed_t sprtopscreen;

// fixed_t*

fixed_t* textureheight;

fixed_t* spritewidth;

fixed_t* spriteoffset;

fixed_t* spritetopoffset;

fixed_t* finecosine;

// doom_boolean

doom_boolean stopped;

doom_boolean automapactive;

doom_boolean devparm;

doom_boolean nomonsters;

doom_boolean respawnparm;

doom_boolean fastparm;

doom_boolean drone;

doom_boolean singletics;

doom_boolean is_wiping_screen;

doom_boolean autostart;

doom_boolean advancedemo;

doom_boolean nodeingame[MAXNETNODES];

doom_boolean remoteresend[MAXNETNODES];

doom_boolean reboundpacket;

doom_boolean modifiedgame;

doom_boolean castdeath;

doom_boolean castattacking;

doom_boolean go = 0;

doom_boolean respawnmonsters;

doom_boolean paused;

doom_boolean sendpause;

doom_boolean sendsave;

doom_boolean usergame;

doom_boolean timingdemo;

doom_boolean nodrawers;

doom_boolean noblit;

doom_boolean viewactive;

doom_boolean deathmatch;

doom_boolean netgame;

doom_boolean playeringame[MAXPLAYERS];

doom_boolean demorecording;

doom_boolean demoplayback;

doom_boolean netdemo;

doom_boolean singledemo;

doom_boolean precache;

doom_boolean gamekeydown[NUMKEYS];

doom_boolean mousearray[4];

doom_boolean joyarray[5];

doom_boolean secretexit;

doom_boolean always_off;

doom_boolean message_on;

doom_boolean message_nottobefuckedwith;

doom_boolean headsupactive;

doom_boolean chat_on;

doom_boolean message_dontfuckwithme;

doom_boolean mus_loop;

doom_boolean mus_playing;

doom_boolean grabMouse;

doom_boolean shmFinished;

doom_boolean messageNeedsInput;

doom_boolean inhelpscreens;

doom_boolean menuactive;

doom_boolean floatok;

doom_boolean crushchange;

doom_boolean nofit;

doom_boolean earlyout;

doom_boolean levelTimer;

doom_boolean onground;

doom_boolean setsizeneeded;

doom_boolean segtextured;

doom_boolean markfloor;

doom_boolean markceiling;

doom_boolean maskedtexture;

doom_boolean mus_paused;

doom_boolean st_firsttime;

doom_boolean st_statusbaron;

doom_boolean st_chat;

doom_boolean st_oldchat;

doom_boolean st_cursoron;

doom_boolean st_notdeathmatch;

doom_boolean st_armson;

doom_boolean st_fragson;

doom_boolean oldweaponsowned[NUMWEAPONS];

doom_boolean st_stopped;

doom_boolean snl_pointeron;

// doom_boolean*

doom_boolean* mousebuttons = &mousearray[1];

doom_boolean* joybuttons = &joyarray[1];

// void*

void* debugfile;

void* statcopy;

// void**

void** lumpcache;

// void (*)()

void (*netget) (void);

void (*netsend) (void);

void (*messageRoutine)(int response);

void (*colfunc) (void);

void (*basecolfunc) (void);

void (*fuzzcolfunc) (void);

void (*transcolfunc) (void);

void (*spanfunc) (void);

// GameMission_t

GameMission_t gamemission;

// GameMode_t

GameMode_t gamemode;

// Language_t

Language_t language;

// angle_t

angle_t viewangle;

angle_t clipangle;

angle_t xtoviewangle[SCREENWIDTH + 1];

angle_t rw_normalangle;

angle_t rw_centerangle;

// angle_t*

angle_t* tantoangle;

// anim_t

anim_t anims[MAXANIMS];

// anim_t*

anim_t* lastanim;

// anim_t_wi_stuff

anim_t_wi_stuff epsd0animinfo[10];

anim_t_wi_stuff epsd1animinfo[9];

anim_t_wi_stuff epsd2animinfo[6];

// anim_t_wi_stuff*

anim_t_wi_stuff* anims_wi_stuff[NUMEPISODES];

// animdef_t*

animdef_t* animdefs;

// button_t

button_t buttonlist[MAXBUTTONS];

// castinfo_t

castinfo_t castorder[18];

// ceiling_t*

ceiling_t* activeceilings[MAXCEILINGS];

// channel_t*

channel_t* channels_s_sound;

// cheatseq_t

cheatseq_t cheat_amap;

cheatseq_t cheat_mus;

cheatseq_t cheat_god;

cheatseq_t cheat_ammo;

cheatseq_t cheat_ammonokey;

cheatseq_t cheat_noclip;

cheatseq_t cheat_commercial_noclip;

cheatseq_t cheat_powerup[7];

cheatseq_t cheat_choppers;

cheatseq_t cheat_clev;

cheatseq_t cheat_mypos;

// cliprange_t

cliprange_t solidsegs[MAXSEGS];

// cliprange_t*

cliprange_t* newend;


// dirtype_t

dirtype_t opposite[9];

dirtype_t diags[4];

// divline_t

divline_t trace;

divline_t strace;

// doom_close_fn

doom_close_fn doom_close;

// doom_eof_fn

doom_eof_fn doom_eof;

// doom_exit_fn

doom_exit_fn doom_exit;

// doom_free_fn

doom_free_fn doom_free;

// doom_getenv_fn

doom_getenv_fn doom_getenv;

// doom_gettime_fn

doom_gettime_fn doom_gettime;

// doom_malloc_fn

doom_malloc_fn doom_malloc;

// doom_open_fn

doom_open_fn doom_open;

// doom_print_fn

doom_print_fn doom_print;

// doom_read_fn

doom_read_fn doom_read;

// doom_seek_fn

doom_seek_fn doom_seek;

// doom_tell_fn

doom_tell_fn doom_tell;

// doom_write_fn

doom_write_fn doom_write;

// doomcom_t*

doomcom_t* doomcom;

// doomdata_t

doomdata_t reboundstore;

// doomdata_t*

doomdata_t* netbuffer;

// drawseg_t

drawseg_t drawsegs[MAXDRAWSEGS];

// drawseg_t*

drawseg_t* ds_p;

// event_t

event_t st_notify;

event_t events[MAXEVENTS];

// gameaction_t

gameaction_t gameaction;

// gamestate_t

gamestate_t wipegamestate;

gamestate_t gamestate;

// hu_itext_t

hu_itext_t w_chat;

hu_itext_t w_inputbuffer[MAXPLAYERS];

// hu_stext_t

hu_stext_t w_message;

// hu_textline_t

hu_textline_t w_title;

// intercept_t

intercept_t intercepts[MAXINTERCEPTS];

// intercept_t*

intercept_t* intercept_p;

// lighttable_t*

lighttable_t* colormaps;

lighttable_t* dc_colormap;

lighttable_t* ds_colormap;

lighttable_t* fixedcolormap;

lighttable_t* scalelight[LIGHTLEVELS][MAXLIGHTSCALE];

lighttable_t* scalelightfixed[MAXLIGHTSCALE];

lighttable_t* zlight[LIGHTLEVELS][MAXLIGHTZ];

// lighttable_t**

lighttable_t** planezlight;

lighttable_t** walllights;

lighttable_t** spritelights;

// line_t*

line_t* ceilingline;

line_t* spechit[MAXSPECIALCROSS];

line_t* bestslideline;

line_t* secondslideline;

line_t* lines;

line_t* linespeciallist[MAXLINEANIMS];

line_t* linedef;

// lumpinfo_t*

lumpinfo_t* lumpinfo;

// mapthing_t

mapthing_t itemrespawnque[ITEMQUESIZE];

mapthing_t deathmatchstarts[MAX_DEATHMATCH_STARTS];

mapthing_t playerstarts[MAXPLAYERS];

// mapthing_t*

mapthing_t* deathmatch_p;

// memzone_t*

memzone_t* mainzone;

// menu_custom_text_t

menu_custom_text_t menu_custom_texts[4];

// menu_t

menu_t  MainDef;

menu_t  EpiDef;

menu_t  NewDef;

menu_t  OptionsDef;

menu_t  OptionsNoMouseDef;

menu_t  MouseOptionsDef;

menu_t  ReadDef1;

menu_t  ReadDef2;

menu_t  SoundDef;

menu_t  LoadDef;

menu_t  SaveDef;

// menu_t*

menu_t* currentMenu;

// menuitem_t

menuitem_t MainMenu[6];

menuitem_t EpisodeMenu[4];

menuitem_t NewGameMenu[5];

menuitem_t OptionsMenuFull[8];

menuitem_t OptionsMenuNoMouse[7];

menuitem_t MouseOptionsMenu[3];

menuitem_t ReadMenu1[1];

menuitem_t ReadMenu2[1];

menuitem_t SoundMenuFull[4];

menuitem_t DOOM_LoadMenu[6];

menuitem_t SaveMenu[6];

// menuitem_t*

menuitem_t* OptionsMenu;

menuitem_t* SoundMenu;

// mline_t

mline_t player_arrow[7];

mline_t cheat_player_arrow[16];

mline_t triangle_guy[3];

mline_t thintriangle_guy[3];

// mobj_t*

mobj_t* bodyque[BODYQUESIZE];

mobj_t* soundtarget;

mobj_t* corpsehit;

mobj_t* vileobj;

mobj_t* braintargets[32];

mobj_t* tmthing;

mobj_t* linetarget;

mobj_t* shootthing;

mobj_t* usething;

mobj_t* slidemo;

mobj_t* bombsource;

mobj_t* bombspot;

// mobj_t**

mobj_t** blocklinks;

// mobjinfo_t*

mobjinfo_t* mobjinfo;

// mpoint_t

mpoint_t m_paninc;

mpoint_t f_oldloc;

mpoint_t markpoints[AM_NUMMARKPOINTS];

// mus_header_t

mus_header_t mus_header;

// musicinfo_t*

musicinfo_t* mus_playing_s_sound;

musicinfo_t* S_music;

// node_t*

node_t* nodes;

// patch_t*

patch_t* marknums[10];

patch_t* hu_font[HU_FONTSIZE];

patch_t* sttminus;

patch_t* sbar;

patch_t* tallnum[10];

patch_t* tallpercent;

patch_t* shortnum[10];

patch_t* keys[NUMCARDS];

patch_t* faces[ST_NUMFACES];

patch_t* faceback;

patch_t* armsbg;

patch_t* arms[6][2];

patch_t* bg;

patch_t* yah[2];

patch_t* splat;

patch_t* percent;

patch_t* colon;

patch_t* num[10];

patch_t* wiminus;

patch_t* finished;

patch_t* entering;

patch_t* sp_secret;

patch_t* kills;

patch_t* secret;

patch_t* items;

patch_t* frags;

patch_t* time_patch;

patch_t* par;

patch_t* sucks;

patch_t* killers;

patch_t* victims;

patch_t* total;

patch_t* star;

patch_t* bstar;

patch_t* p[MAXPLAYERS];

patch_t* bp[MAXPLAYERS];

// patch_t**

patch_t** lnames;

// planefunction_t

planefunction_t floorfunc;

planefunction_t ceilingfunc;

// plat_t*

plat_t* activeplats[MAXPLATS];

// player_t

player_t players[MAXPLAYERS];

// player_t*

player_t* plr;

player_t* plr;

player_t* viewplayer;

player_t* plyr;

// point_t*

point_t* lnodes[NUMEPISODES];

// sector_t*

sector_t* sectors;

sector_t* frontsector;

sector_t* backsector;

// seg_t*

seg_t* segs;

seg_t* curline;

// sfxinfo_t*

sfxinfo_t* S_sfx;

// side_t*

side_t* sides;

side_t* sidedef;

// skill_t

skill_t startskill;

skill_t gameskill;

skill_t d_skill;

// spritedef_t*

spritedef_t* sprites;

// spriteframe_t

spriteframe_t sprtemp[29];

// st_binicon_t

st_binicon_t w_armsbg;

// st_chatstateenum_t

st_chatstateenum_t st_chatstate;

// st_multicon_t

st_multicon_t w_arms[6];

st_multicon_t w_faces;

st_multicon_t w_keyboxes[3];

// st_number_t

st_number_t w_ready;

st_number_t w_frags;

st_number_t w_ammo[4];

st_number_t w_maxammo[4];

// st_percent_t

st_percent_t w_health;

st_percent_t w_armor;

// st_stateenum_t

st_stateenum_t st_gamestate;

// state_t*

state_t* caststate;

state_t* states;

// stateenum_t

stateenum_t state;

// subsector_t*

subsector_t* subsectors;

// switchlist_t*

switchlist_t* alphSwitchList;

// texture_t**

texture_t** textures;

// thinker_t

thinker_t thinkercap;

// ticcmd_t

ticcmd_t localcmds[BACKUPTICS];

ticcmd_t netcmds[MAXPLAYERS][BACKUPTICS];

ticcmd_t emptycmd;

// unsigned short**

unsigned short** texturecolumnofs;

// vertex_t*

vertex_t* vertexes;

// visplane_t

visplane_t visplanes[MAXVISPLANES];

// visplane_t*

visplane_t* lastvisplane;

visplane_t* floorplane;

visplane_t* ceilingplane;

// vissprite_t

vissprite_t vissprites[MAXVISSPRITES];

vissprite_t vsprsortedhead;

vissprite_t overflowsprite;

// vissprite_t*

vissprite_t* vissprite_p;

// wbplayerstruct_t*

wbplayerstruct_t* plrs;

// wbstartstruct_t

wbstartstruct_t wminfo;

// wbstartstruct_t*

wbstartstruct_t* wbs;

// weaponinfo_t

weaponinfo_t weaponinfo[NUMWEAPONS];
