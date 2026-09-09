module Doocr
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
		property type : CDoom::Mobjtype

		def initialize(@name : String = "", @type : CDoom::Mobjtype = CDoom::Mobjtype::MT_PLAYER)
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
		property where : CDoom::Bwhere
		property btexture : Int32
		property btimer : Int32
		property soundorg : Pointer(CDoom::Mobj)?

		def initialize
			@line = nil
			@where = CDoom::Bwhere::Top
			@btexture = 0
			@btimer = 0
			@soundorg = nil
		end

		def reset
			@line = nil
			@where = CDoom::Bwhere::Top
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
		property type : CDoom::Animenum
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

		def initialize(@type : CDoom::Animenum = CDoom::Animenum::Always, @period : Int32 = 0,
						 @nanims : Int32 = 0, @loc : Point = Point.new, @data1 : Int32 = 0,
						 @data2 : Int32 = 0, @p : Array(Pointer(CDoom::Patch)) = Array.new(3) { Pointer(CDoom::Patch).null },
						 @nexttic : Int32 = 0, @lastdrawn : Int32 = 0, @ctr : Int32 = 0, @state : Int32 = 0)
		end
	end

	@@s_music : Array(Musicinfo) = [] of Musicinfo
	@@mus_playing_s_sound : Musicinfo?
	@@anims_wi_stuff : Array(Array(AnimWIStuff)) = [] of Array(AnimWIStuff)
	@@numanims : Array(Int32) = [] of Int32

	class_property gameaction : CDoom::Gameaction = CDoom::Gameaction::Nothing
	class_property gamestate : CDoom::Gamestate = CDoom::Gamestate::Demoscreen
	class_property gamemode : CDoom::GameMode = CDoom::GameMode::Indetermined
	class_property gamemission : CDoom::GameMission = CDoom::GameMission::None
	class_property gameskill : CDoom::Skill = CDoom::Skill::Medium
	class_property gameepisode : Int32 = 1
	class_property gamemap : Int32 = 1
	class_property paused : Int32 = 0
	class_property netgame : Int32 = 0
	class_property deathmatch : Int32 = 0
	class_property respawnmonsters : Int32 = 0
	class_property autostart : Int32 = 0
	class_property startskill : CDoom::Skill = CDoom::Skill::Medium
	class_property startepisode : Int32 = 1
	class_property startmap : Int32 = 1
	class_property nomonsters : Int32 = 0
	class_property respawnparm : Int32 = 0
	class_property fastparm : Int32 = 0
	class_property devparm : Int32 = 0
	class_property modifiedgame : Int32 = 0
	class_property language : CDoom::Language = CDoom::Language::English
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
	class_getter channelstart : Array(Int32) = Array.new(CDoom::NUM_CHANNELS, 0)
	class_getter channelhandles : Array(Int32) = Array.new(CDoom::NUM_CHANNELS, 0)
	class_getter channelids : Array(Int32) = Array.new(CDoom::NUM_CHANNELS, 0)
	class_getter channelstep : Array(UInt32) = Array.new(CDoom::NUM_CHANNELS, 0_u32)
	class_getter channelstepremainder : Array(UInt32) = Array.new(CDoom::NUM_CHANNELS, 0_u32)
	class_getter channelsend : Array(UInt8*) = Array.new(CDoom::NUM_CHANNELS, Pointer(UInt8).null)
	class_getter steptable : Array(Int32) = Array.new(256, 0)
	class_getter vol_lookup : Array(Int32) = Array.new(32768, 0)
	class_getter channelleftvol_lookup : Array(Int32*) = Array.new(CDoom::NUM_CHANNELS, Pointer(Int32).null)
	class_getter channelrightvol_lookup : Array(Int32*) = Array.new(CDoom::NUM_CHANNELS, Pointer(Int32).null)
	class_getter viewangletox : Array(Int32) = Array.new(CDoom::VIEWANGLETOX_SIZE, 0)
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
	class_property st_chatstate : CDoom::ST_Chatstateenum = CDoom::ST_Chatstateenum::StartChatState
	class_property st_gamestate : CDoom::ST_Statenum = CDoom::ST_Statenum::FirstPersonState
	class_property wipegamestate : CDoom::Gamestate = CDoom::Gamestate::Demoscreen
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
	class_getter maxammo : Array(Int32) = Array.new(CDoom::Ammotype::NUMAMMO.value, 0)
	class_getter clipammo : Array(Int32) = Array.new(CDoom::Ammotype::NUMAMMO.value, 0)
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
	class_property walllights : Pointer(Pointer(CDoom::Lighttable)) = Pointer(Pointer(CDoom::Lighttable)).null
	class_property spritelights : Pointer(Pointer(CDoom::Lighttable)) = Pointer(Pointer(CDoom::Lighttable)).null
	class_property newvissprite : Int32 = 0
	class_property snd_music_volume : Int32 = 15
	class_property mus_data : UInt8* = Pointer(UInt8).null
	class_property queue_midi_head : Int32 = 0
	class_property queue_midi_tail : Int32 = 0
	class_property mb_used : Int32 = 12
	class_getter cheat_mus : Cheatseq = Cheatseq.new(Pointer(UInt8).null, Pointer(UInt8).null)
	class_getter cheat_god : Cheatseq = Cheatseq.new(Pointer(UInt8).null, Pointer(UInt8).null)
	class_getter cheat_ammo : Cheatseq = Cheatseq.new(Pointer(UInt8).null, Pointer(UInt8).null)
	class_getter cheat_ammonokey : Cheatseq = Cheatseq.new(Pointer(UInt8).null, Pointer(UInt8).null)
	class_getter cheat_noclip : Cheatseq = Cheatseq.new(Pointer(UInt8).null, Pointer(UInt8).null)
	class_getter cheat_commercial_noclip : Cheatseq = Cheatseq.new(Pointer(UInt8).null, Pointer(UInt8).null)
	class_getter cheat_choppers : Cheatseq = Cheatseq.new(Pointer(UInt8).null, Pointer(UInt8).null)
	class_getter cheat_clev : Cheatseq = Cheatseq.new(Pointer(UInt8).null, Pointer(UInt8).null)
	class_getter cheat_mypos : Cheatseq = Cheatseq.new(Pointer(UInt8).null, Pointer(UInt8).null)
	class_getter cheat_amap : Cheatseq = Cheatseq.new(Pointer(UInt8).null, Pointer(UInt8).null)
	class_getter cheat_me : Cheatseq = Cheatseq.new(Pointer(UInt8).null, Pointer(UInt8).null)
	class_getter cheat_powerup : Array(Cheatseq) = Array.new(7) { Cheatseq.new(Pointer(UInt8).null, Pointer(UInt8).null) }
	class_getter sprtemp : Array(Spriteframe) = Array.new(29) { Spriteframe.new }
	class_getter rndtable : Array(Int32) = Array.new(256, 0)
	class_getter opposite : Array(CDoom::Dirtype) = Array.new(9, CDoom::Dirtype::NoDir)
	class_getter diags : Array(CDoom::Dirtype) = Array.new(4, CDoom::Dirtype::NoDir)
	class_getter xspeed : Array(Int32) = Array.new(8, 0)
	class_getter yspeed : Array(Int32) = Array.new(8, 0)
	class_getter checkcoord : Array(Array(Int32)) = Array.new(12) { Array.new(4, 0) }
	class_getter quitsounds : Array(Int32) = Array.new(8, 0)
	class_getter quitsounds2 : Array(Int32) = Array.new(8, 0)
	class_getter forwardmove : Array(Int32) = [0x19, 0x32]
	class_getter sidemove : Array(Int32) = [0x18, 0x28]
	class_getter angleturn : Array(Int32) = [640, 1280, 320]
	class_getter pars : Array(Array(Int32)) = Array.new(4) { Array.new(9, 0) }
	class_getter cpars : Array(Int32) = Array.new(32, 0)
	class_getter detail_names : Array(String) = ["M_GDHIGH", "M_GDLOW"]
	class_getter msg_names : Array(String) = ["M_MSGOFF", "M_MSGON"]
	class_getter player_names : Array(String) = Array.new(4, "")
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