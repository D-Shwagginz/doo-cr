# All of The Sounds

module Doocr
  #
  # Identifiers for all music in game.
  #

  enum Music
    None
    E1M1
    E1m2
    E1M3
    E1M4
    E1M5
    E1M6
    E1M7
    E1M8
    E1M9
    E2M1
    E2M2
    E2M3
    E2M4
    E2M5
    E2M6
    E2M7
    E2M8
    E2M9
    E3M1
    E3M2
    E3M3
    E3M4
    E3M5
    E3M6
    E3M7
    E3M8
    E3M9
    Inter
    Intro
    Bunny
    Victor
    Introa
    Runnin
    Stalks
    Countd
    Betwee
    Doom
    TheDa
    Shawn
    Ddtblu
    InCit
    Dead
    Stlks2
    Theda2
    Doom2
    Ddtbl2
    Runni2
    Dead2
    Stlks3
    Romero
    Shawn2
    Messag
    Count2
    Ddtbl3
    Aampie
    Theda3
    Adrian
    Messg2
    Romer2
    Tense
    Shawn3
    Openin
    Evil
    Ultima
    ReadM
    Dm2ttl
    Dm2int
    NumMusic
  end

  #
  # Identifiers for all sfx in game.
  #
  enum SFX
    None
    Pistol
    Shotgn
    Sgcock
    Dshtgn
    Dbopn
    Dbcls
    Dbload
    Plasma
    Bfg
    Sawup
    Sawidl
    Sawful
    Sawhit
    Rlaunc
    Rxplod
    Firsht
    Firxpl
    Pstart
    Pstop
    Doropn
    Dorcls
    Stnmov
    Swtchn
    Swtchx
    Plpain
    Dmpain
    Popain
    Vipain
    Mnpain
    Pepain
    Slop
    Itemup
    Wpnup
    Oof
    Telept
    Posit1
    Posit2
    Posit3
    Bgsit1
    Bgsit2
    Sgtsit
    Cacsit
    Brssit
    Cybsit
    Spisit
    Bspsit
    Kntsit
    Vilsit
    Mansit
    Pesit
    Sklatk
    Sgtatk
    Skepch
    Vilatk
    Claw
    Skeswg
    Pldeth
    Pdiehi
    Podth1
    Podth2
    Podth3
    Bgdth1
    Bgdth2
    Sgtdth
    Cacdth
    Skldth
    Brsdth
    Cybdth
    Spidth
    Bspdth
    Vildth
    Kntdth
    Pedth
    Skedth
    Posact
    Bgact
    Dmact
    Bspact
    Bspwlk
    Vilact
    Noway
    Barexp
    Punch
    Hoof
    Metal
    Chgun
    Tink
    Bdopn
    Bdcls
    Itmbk
    Flame
    Flamst
    Getpow
    Bospit
    Boscub
    Bossit
    Bospn
    Bosdth
    Manatk
    Mandth
    Sssit
    Ssdth
    Keenpn
    Keendt
    Skeact
    Skesit
    Skeatk
    Radio
    NumSfx
  end

  #
  # SoundFX struct.
  #
  struct SFXInfo
    # up to 6-character name
    property name : String

    # Sfx singularity (only one at a time)
    property singularity : Bool

    # Sfx priority
    property priority : Int32

    # referenced sound if a link
    property link : Int32

    # pitch if a link
    property pitch : Int32

    # volume if a link
    property volume : Int32

    # sound data
    property data : RAudio::Sound = RAudio::Sound.new

    # this is checked every second to see if sound
    # can be thrown out (if 0, then decrement, if -1,
    # then throw out, if > 0, then it is in use)
    property usefulness : Int32 = 0

    # lump number of sfx
    property lumpnum : Int32 = 0

    def initialize(@name, @singularity, @priority, @link, @pitch, @volume)
    end
  end

  #
  # MusicInfo struct.
  #
  struct MusicInfo
    # up to 6-character name
    property name : String

    # lump number of music
    property lumpnum : Int32 = 0

    # music data
    property data : RAudio::Music = RAudio::Music.new

    # music handle once registered
    property handle : Int32 = 0

    def initialize(@name)
    end
  end

  #
  # Information about all the music
  #

  @@music =
    [
      MusicInfo.new(""),
      MusicInfo.new("e1m1"),
      MusicInfo.new("e1m2"),
      MusicInfo.new("e1m3"),
      MusicInfo.new("e1m4"),
      MusicInfo.new("e1m5"),
      MusicInfo.new("e1m6"),
      MusicInfo.new("e1m7"),
      MusicInfo.new("e1m8"),
      MusicInfo.new("e1m9"),
      MusicInfo.new("e2m1"),
      MusicInfo.new("e2m2"),
      MusicInfo.new("e2m3"),
      MusicInfo.new("e2m4"),
      MusicInfo.new("e2m5"),
      MusicInfo.new("e2m6"),
      MusicInfo.new("e2m7"),
      MusicInfo.new("e2m8"),
      MusicInfo.new("e2m9"),
      MusicInfo.new("e3m1"),
      MusicInfo.new("e3m2"),
      MusicInfo.new("e3m3"),
      MusicInfo.new("e3m4"),
      MusicInfo.new("e3m5"),
      MusicInfo.new("e3m6"),
      MusicInfo.new("e3m7"),
      MusicInfo.new("e3m8"),
      MusicInfo.new("e3m9"),
      MusicInfo.new("inter"),
      MusicInfo.new("intro"),
      MusicInfo.new("bunny"),
      MusicInfo.new("victor"),
      MusicInfo.new("introa"),
      MusicInfo.new("runnin"),
      MusicInfo.new("stalks"),
      MusicInfo.new("countd"),
      MusicInfo.new("betwee"),
      MusicInfo.new("doom"),
      MusicInfo.new("the_da"),
      MusicInfo.new("shawn"),
      MusicInfo.new("ddtblu"),
      MusicInfo.new("in_cit"),
      MusicInfo.new("dead"),
      MusicInfo.new("stlks2"),
      MusicInfo.new("theda2"),
      MusicInfo.new("doom2"),
      MusicInfo.new("ddtbl2"),
      MusicInfo.new("runni2"),
      MusicInfo.new("dead2"),
      MusicInfo.new("stlks3"),
      MusicInfo.new("romero"),
      MusicInfo.new("shawn2"),
      MusicInfo.new("messag"),
      MusicInfo.new("count2"),
      MusicInfo.new("ddtbl3"),
      MusicInfo.new("ampie"),
      MusicInfo.new("theda3"),
      MusicInfo.new("adrian"),
      MusicInfo.new("messg2"),
      MusicInfo.new("romer2"),
      MusicInfo.new("tense"),
      MusicInfo.new("shawn3"),
      MusicInfo.new("openin"),
      MusicInfo.new("evil"),
      MusicInfo.new("ultima"),
      MusicInfo.new("read_m"),
      MusicInfo.new("dm2ttl"),
      MusicInfo.new("dm2int"),
    ]

  #
  # Information about all the sfx
  #

  @@sfx =
    [
      # S_sfx[0] needs to be a dummy for odd reasons.
      SFXInfo.new("none", false, 0, SFX::None.value, -1, -1),

      SFXInfo.new("pistol", false, 64, SFX::None.value, -1, -1),
      SFXInfo.new("shotgn", false, 64, SFX::None.value, -1, -1),
      SFXInfo.new("sgcock", false, 64, SFX::None.value, -1, -1),
      SFXInfo.new("dshtgn", false, 64, SFX::None.value, -1, -1),
      SFXInfo.new("dbopn", false, 64, SFX::None.value, -1, -1),
      SFXInfo.new("dbcls", false, 64, SFX::None.value, -1, -1),
      SFXInfo.new("dbload", false, 64, SFX::None.value, -1, -1),
      SFXInfo.new("plasma", false, 64, SFX::None.value, -1, -1),
      SFXInfo.new("bfg", false, 64, SFX::None.value, -1, -1),
      SFXInfo.new("sawup", false, 64, SFX::None.value, -1, -1),
      SFXInfo.new("sawidl", false, 118, SFX::None.value, -1, -1),
      SFXInfo.new("sawful", false, 64, SFX::None.value, -1, -1),
      SFXInfo.new("sawhit", false, 64, SFX::None.value, -1, -1),
      SFXInfo.new("rlaunc", false, 64, SFX::None.value, -1, -1),
      SFXInfo.new("rxplod", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("firsht", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("firxpl", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("pstart", false, 100, SFX::None.value, -1, -1),
      SFXInfo.new("pstop", false, 100, SFX::None.value, -1, -1),
      SFXInfo.new("doropn", false, 100, SFX::None.value, -1, -1),
      SFXInfo.new("dorcls", false, 100, SFX::None.value, -1, -1),
      SFXInfo.new("stnmov", false, 119, SFX::None.value, -1, -1),
      SFXInfo.new("swtchn", false, 78, SFX::None.value, -1, -1),
      SFXInfo.new("swtchx", false, 78, SFX::None.value, -1, -1),
      SFXInfo.new("plpain", false, 96, SFX::None.value, -1, -1),
      SFXInfo.new("dmpain", false, 96, SFX::None.value, -1, -1),
      SFXInfo.new("popain", false, 96, SFX::None.value, -1, -1),
      SFXInfo.new("vipain", false, 96, SFX::None.value, -1, -1),
      SFXInfo.new("mnpain", false, 96, SFX::None.value, -1, -1),
      SFXInfo.new("pepain", false, 96, SFX::None.value, -1, -1),
      SFXInfo.new("slop", false, 78, SFX::None.value, -1, -1),
      SFXInfo.new("itemup", true, 78, SFX::None.value, -1, -1),
      SFXInfo.new("wpnup", true, 78, SFX::None.value, -1, -1),
      SFXInfo.new("oof", false, 96, SFX::None.value, -1, -1),
      SFXInfo.new("telept", false, 32, SFX::None.value, -1, -1),
      SFXInfo.new("posit1", true, 98, SFX::None.value, -1, -1),
      SFXInfo.new("posit2", true, 98, SFX::None.value, -1, -1),
      SFXInfo.new("posit3", true, 98, SFX::None.value, -1, -1),
      SFXInfo.new("bgsit1", true, 98, SFX::None.value, -1, -1),
      SFXInfo.new("bgsit2", true, 98, SFX::None.value, -1, -1),
      SFXInfo.new("sgtsit", true, 98, SFX::None.value, -1, -1),
      SFXInfo.new("cacsit", true, 98, SFX::None.value, -1, -1),
      SFXInfo.new("brssit", true, 94, SFX::None.value, -1, -1),
      SFXInfo.new("cybsit", true, 92, SFX::None.value, -1, -1),
      SFXInfo.new("spisit", true, 90, SFX::None.value, -1, -1),
      SFXInfo.new("bspsit", true, 90, SFX::None.value, -1, -1),
      SFXInfo.new("kntsit", true, 90, SFX::None.value, -1, -1),
      SFXInfo.new("vilsit", true, 90, SFX::None.value, -1, -1),
      SFXInfo.new("mansit", true, 90, SFX::None.value, -1, -1),
      SFXInfo.new("pesit", true, 90, SFX::None.value, -1, -1),
      SFXInfo.new("sklatk", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("sgtatk", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("skepch", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("vilatk", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("claw", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("skeswg", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("pldeth", false, 32, SFX::None.value, -1, -1),
      SFXInfo.new("pdiehi", false, 32, SFX::None.value, -1, -1),
      SFXInfo.new("podth1", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("podth2", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("podth3", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("bgdth1", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("bgdth2", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("sgtdth", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("cacdth", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("skldth", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("brsdth", false, 32, SFX::None.value, -1, -1),
      SFXInfo.new("cybdth", false, 32, SFX::None.value, -1, -1),
      SFXInfo.new("spidth", false, 32, SFX::None.value, -1, -1),
      SFXInfo.new("bspdth", false, 32, SFX::None.value, -1, -1),
      SFXInfo.new("vildth", false, 32, SFX::None.value, -1, -1),
      SFXInfo.new("kntdth", false, 32, SFX::None.value, -1, -1),
      SFXInfo.new("pedth", false, 32, SFX::None.value, -1, -1),
      SFXInfo.new("skedth", false, 32, SFX::None.value, -1, -1),
      SFXInfo.new("posact", true, 120, SFX::None.value, -1, -1),
      SFXInfo.new("bgact", true, 120, SFX::None.value, -1, -1),
      SFXInfo.new("dmact", true, 120, SFX::None.value, -1, -1),
      SFXInfo.new("bspact", true, 100, SFX::None.value, -1, -1),
      SFXInfo.new("bspwlk", true, 100, SFX::None.value, -1, -1),
      SFXInfo.new("vilact", true, 100, SFX::None.value, -1, -1),
      SFXInfo.new("noway", false, 78, SFX::None.value, -1, -1),
      SFXInfo.new("barexp", false, 60, SFX::None.value, -1, -1),
      SFXInfo.new("punch", false, 64, SFX::None.value, -1, -1),
      SFXInfo.new("hoof", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("metal", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("chgun", false, 64, SFX::Pistol.value, 150, 0),
      SFXInfo.new("tink", false, 60, SFX::None.value, -1, -1),
      SFXInfo.new("bdopn", false, 100, SFX::None.value, -1, -1),
      SFXInfo.new("bdcls", false, 100, SFX::None.value, -1, -1),
      SFXInfo.new("itmbk", false, 100, SFX::None.value, -1, -1),
      SFXInfo.new("flame", false, 32, SFX::None.value, -1, -1),
      SFXInfo.new("flamst", false, 32, SFX::None.value, -1, -1),
      SFXInfo.new("getpow", false, 60, SFX::None.value, -1, -1),
      SFXInfo.new("bospit", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("boscub", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("bossit", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("bospn", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("bosdth", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("manatk", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("mandth", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("sssit", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("ssdth", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("keenpn", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("keendt", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("skeact", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("skesit", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("skeatk", false, 70, SFX::None.value, -1, -1),
      SFXInfo.new("radio", false, 60, SFX::None.value, -1, -1),
    ]
end
