@[Link("ADLMIDI")]
lib ADLMidi
  enum SampleType
    S16   =  0
    S8    =  1
    F32   =  2
    F64   =  3
    S24   =  4
    S32   =  5
    U8    =  6
    U16   =  7
    U24   =  8
    U32   =  9
    Count = 10
  end

  enum Emulator
    Nuked    = 0
    Nuked174 = 1
    Dosbox   = 2
    Opal     = 3
    Java     = 4
    End      = 5
  end

  struct Version
    major : LibC::UShort
    minor : LibC::UShort
    patch : LibC::UShort
  end

  struct MIDIPlayer
    midiplayer : Void*
  end

  struct Bank
    pointer : StaticArray(Void*, 3)
  end

  struct BankId
    percussive : LibC::Char
    msb : LibC::Char
    lsb : LibC::Char
  end

  struct Operator
    avekf_20 : LibC::Char
    ksl_l_40 : LibC::Char
    atdec_60 : LibC::Char
    susrel_80 : LibC::Char
    waveform_E0 : LibC::Char
  end

  struct Instrument
    version : LibC::Int
    note_offset1 : LibC::Short
    note_offset2 : LibC::Short
    midi_velocity_offset : LibC::SChar
    second_voice_detune : LibC::SChar
    inst_flags : LibC::Char
    fb_conn1_C0 : LibC::Char
    fb_conn2_C0 : LibC::Char
    operators : StaticArray(Operator, 4)
    delay_on_ms : LibC::UShort
    delay_off_ms : LibC::UShort
  end

  struct MarkerEntry
    label : LibC::Char*
    pos_time : LibC::Double
    pos_ticks : LibC::ULong
  end

  struct AudioFormat
    type : SampleType
    container_size : LibC::UInt
    sample_offset : LibC::UInt
  end

  alias RawEventHook = Proc(Void*, LibC::Char, LibC::Char, LibC::Char, LibC::Char*, LibC::Long, Void)
  alias NoteHook = Proc(Void*, LibC::Int, LibC::Int, LibC::Int, LibC::Int, LibC::Double, Void)
  alias DebugMessageHook = Proc(Void*, LibC::Char*, Void)
  alias LoopPointHook = Proc(Void*, Void)

  alias TriggerHandler = Proc(Void*, LibC::UInt, LibC::Long, Void)

  fun init = adl_init(sample_rate : LibC::Long) : MIDIPlayer*
  fun close = adl_close(device : MIDIPlayer*) : Void
  fun set_device_identifier = adl_setDeviceIdentifier(device : MIDIPlayer*, id : LibC::UInt) : LibC::Int
  fun set_num_chips = adl_setNumChips(device : MIDIPlayer*, num_chips : LibC::Int) : LibC::Int
  fun get_num_chips = adl_getNumChips(device : MIDIPlayer*) : LibC::Int
  fun get_num_chips_obtained = adl_getNumChipsObtained(device : MIDIPlayer*) : LibC::Int
  fun set_bank = adl_setBank(device : MIDIPlayer*, bank : LibC::Int) : LibC::Int
  fun get_banks_count = adl_getBanksCount : LibC::Int
  fun get_bank_names = adl_getBankNames : LibC::Char**
  fun reserve_banks = adl_reserveBanks(device : MIDIPlayer*, banks : LibC::UInt) : LibC::Int
  fun get_bank = adl_getBank(device : MIDIPlayer*, idp : BankId*, flags : LibC::Int, bank : Bank*) : LibC::Int
  fun get_bank_id = adl_getBankId(device : MIDIPlayer*, bank : Bank*, id : BankId*) : LibC::Int
  fun remove_bank = adl_removeBank(device : MIDIPlayer*, bank : Bank*) : LibC::Int
  fun get_first_bank = adl_getFirstBank(device : MIDIPlayer*, bank : Bank*) : LibC::Int
  fun get_next_bank = adl_getNextBank(device : MIDIPlayer*, bank : Bank*) : LibC::Int
  fun get_instrument = adl_getInstrument(device : MIDIPlayer*, bank : Bank*, index : LibC::UInt, ins : Instrument*) : LibC::Int
  fun set_instrument = adl_setInstrument(device : MIDIPlayer*, bank : Bank*, index : LibC::UInt, ins : Instrument*) : LibC::Int
  fun load_embedded_bank = adl_loadEmbeddedBank(device : MIDIPlayer*, bank : Bank*, num : LibC::Int) : LibC::Int
  fun set_num_four_ops_chn = adl_setNumFourOpsChn(device : MIDIPlayer*, ops4 : LibC::Int) : LibC::Int
  fun get_num_four_ops_chn = adl_getNumFourOpsChn(device : MIDIPlayer*) : LibC::Int
  fun get_num_four_ops_chn_obtained = adl_getNumFourOpsChnObtained(device : MIDIPlayer*) : LibC::Int
  fun set_perc_mode = adl_setPercMode(device : MIDIPlayer*, percmod : LibC::Int) : Void
  fun set_h_vibrato = adl_setHVibrato(device : MIDIPlayer*, hvibro : LibC::Int) : Void
  fun get_h_vibrato = adl_getHVibratio(device : MIDIPlayer*) : LibC::Int
  fun set_h_tremolo = adl_setHTremolo(device : MIDIPlayer*, htrmo : LibC::Int) : Void
  fun get_h_tremolo = adl_getHTremolo(device : MIDIPlayer*) : LibC::Int
  fun set_scale_modulators = adl_setScaleModulators(device : MIDIPlayer*, smod : LibC::Int) : Void
  fun set_full_range_brightness = adl_setFullRangeBrightness(device : MIDIPlayer*, fr_brightness : LibC::Int) : Void
  fun set_auto_arpeggio = adl_setAutoArpeggio(device : MIDIPlayer*, aa_en : LibC::Int) : Void
  fun get_auto_arpeggio = adl_getAutoArpeggio(device : MIDIPlayer*) : LibC::Int
  fun set_loop_enabled = adl_setLoopEnabled(device : MIDIPlayer*, loop_en : LibC::Int) : Void
  fun set_loop_count = adl_setLoopCount(device : MIDIPlayer*, loop_count : LibC::Int) : Void
  fun set_loop_hooks_only = adl_setLoopHooksOnly(device : MIDIPlayer*, loop_hooks_only : LibC::Int) : Void
  fun set_soft_pan_enabled = adl_setSoftPanEnabled(device : MIDIPlayer*, soft_pan_en : LibC::Int) : Void
  fun set_logarithmic_volumes = adl_setLogarithmicVolumes(device : MIDIPlayer*, logvol : LibC::Int) : Void
  fun set_volume_range_model = adl_setVolumeRangeModel(device : MIDIPlayer*, volume_model : LibC::Int) : Void
  fun get_volume_range_model = adl_getVolumeRangeModel(device : MIDIPlayer*) : LibC::Int
  fun set_channel_alloc_mode = adl_setChannelAllocMode(device : MIDIPlayer*, chanalloc : LibC::Int) : Void
  fun get_channel_alloc_mode = adl_getChannelAllocMode(device : MIDIPlayer*) : LibC::Int
  fun open_bank_file = adl_openBankFile(device : MIDIPlayer*, file_path : LibC::Char*) : LibC::Int
  fun open_bank_data = adl_openBankData(device : MIDIPlayer*, mem : Void*, size : LibC::ULong) : LibC::Int
  fun open_file = adl_openFile(device : MIDIPlayer*, file_path : LibC::Char*) : LibC::Int
  fun open_data = adl_openData(device : MIDIPlayer*, mem : Void*, size : LibC::ULong) : LibC::Int
  fun select_song_num = adl_selectSongNum(device : MIDIPlayer*, song_number : LibC::Int) : Void
  fun get_songs_count = adl_getSongsCount(device : MIDIPlayer*) : LibC::Int
  fun emulator_name = adl_emulatorName : LibC::Char*
  fun chip_emulator_name = adl_chipEmulatorName(device : MIDIPlayer*) : LibC::Char*
  fun switch_emulator = adl_switchEmulator(device : MIDIPlayer*, emulator : LibC::Int) : LibC::Int
  fun set_run_at_pcm_rate = adl_setRunAtPcmRate(device : MIDIPlayer*, enabled : LibC::Int) : LibC::Int
  fun linked_library_version = adl_linkedLibraryVersion : LibC::Char*
  fun linked_version = adl_linkedVersion : Version*
  fun error_string = adl_errorString : LibC::Char*
  fun error_info = adl_errorInfo : LibC::Char*
  fun reset = adl_reset(device : MIDIPlayer*) : Void
  fun total_time_length = adl_totalTimeLength(device : MIDIPlayer*) : LibC::Double
  fun loop_start_time = adl_loopStartTime(device : MIDIPlayer*) : LibC::Double
  fun loop_end_time = adl_loopEndTime(device : MIDIPlayer*) : LibC::Double
  fun position_tell = adl_positionTell(device : MIDIPlayer*) : LibC::Double
  fun position_seek = adl_positionSeek(device : MIDIPlayer*, seconds : LibC::Double) : Void
  fun position_rewind = adl_positionRewind(device : MIDIPlayer*) : Void
  fun set_tempo = adl_setTempo(device : MIDIPlayer*, tempo : LibC::Double) : Void
  fun describe_channels = adl_describeChannels(device : MIDIPlayer*, str : LibC::Char*, attr : LibC::Char*, size : LibC::Long) : LibC::Int
  fun meta_music_title = adl_metaMusicTitle(device : MIDIPlayer*) : LibC::Char*
  fun meta_music_copyright = adl_metaMusicCopyright(device : MIDIPlayer*) : LibC::Char*
  fun meta_track_title_count = adl_metaTrackTitleCount(device : MIDIPlayer*) : LibC::Long
  fun meta_track_title = adl_metaTrackTitle(device : MIDIPlayer*, index : LibC::Long) : LibC::Char*
  fun meta_marker_count = adl_metaMarkerCount(device : MIDIPlayer*) : LibC::Long
  fun meta_marker = adl_metaMarker(device : MIDIPlayer*, index : LibC::Long) : MarkerEntry
  fun set_raw_event_hook = adl_setRawEventHook(device : MIDIPlayer*, raw_event_hook : RawEventHook, user_data : Void*) : Void
  fun set_note_hook = adl_setNoteHook(device : MIDIPlayer*, note_hook : NoteHook, user_data : Void*) : Void
  fun set_debug_message_hook = adl_setDebugMessageHook(device : MIDIPlayer*, debug_message_hook : DebugMessageHook, user_data : Void*) : Void
  fun set_loop_start_hook = adl_setLoopStartHook(device : MIDIPlayer*, loop_start_hook : LoopPointHook, user_data : Void*) : Void
  fun set_loop_end_hook = adl_setLoopEndHook(device : MIDIPlayer*, loop_end_hook : LoopPointHook, user_data : Void*) : Void
  fun play = adl_play(device : MIDIPlayer*, sample_count : LibC::Int, outp : LibC::Short*) : LibC::Int
  fun play_format = adl_playFormat(device : MIDIPlayer*, sample_count : LibC::Int, out_left : LibC::Char*, out_right : LibC::Char*, format : AudioFormat*) : LibC::Int
  fun generate = adl_generate(device : MIDIPlayer*, sample_count : LibC::Int, outp : LibC::Short*) : LibC::Int
  fun generate_format = adl_generateFormat(device : MIDIPlayer*, sample_count : LibC::Int, out_left : LibC::Char*, out_right : LibC::Char*, format : AudioFormat*) : LibC::Int
  fun tick_events = adl_tickEvents(device : MIDIPlayer*, seconds : LibC::Double, granulality : LibC::Double) : LibC::Double
  fun at_end = adl_atEnd(device : MIDIPlayer*) : LibC::Int
  fun track_count = adl_trackCount(device : MIDIPlayer*) : LibC::Long
  fun set_track_options = adl_setTrackOptions(device : MIDIPlayer*, track_number : LibC::Long, track_options : LibC::UInt) : LibC::Int
  fun set_channel_enabled = adl_setChannelEnabled(device : MIDIPlayer*, channel_number : LibC::Long, enabled : LibC::Int) : LibC::Int
  fun set_trigger_handler = adl_setTriggerHandler(device : MIDIPlayer*, handler : TriggerHandler, user_data : Void*) : LibC::Int
  fun panic = adl_panic(device : MIDIPlayer*) : Void
  fun rt_reset_state = adl_rt_resetState(device : MIDIPlayer*) : Void
  fun rt_note_on = adl_rt_noteOn(device : MIDIPlayer*, channel : LibC::Char, note : LibC::Char, velocity : LibC::Char) : LibC::Int
  fun rt_note_off = adl_rt_noteOff(device : MIDIPlayer*, channel : LibC::Char, note : LibC::Char) : Void
  fun rt_note_after_touch = adl_rt_noteAfterTouch(device : MIDIPlayer*, channel : LibC::Char, note : LibC::Char, at_val : LibC::Char) : Void
  fun rt_channel_after_touch = adl_rt_channelAfterTouch(device : MIDIPlayer*, channel : LibC::Char, at_val : LibC::Char) : Void
  fun rt_controller_change = adl_rt_controllerChange(device : MIDIPlayer*, channel : LibC::Char, type : LibC::Char, value : LibC::Char) : Void
  fun rt_patch_change = adl_rt_patchChange(device : MIDIPlayer*, channel : LibC::Char, patch : LibC::Char) : Void
  fun rt_pitch_bend = adl_rt_pitchBend(device : MIDIPlayer*, channel : LibC::Char, pitch : LibC::UShort) : Void
  fun rt_pitch_bend_ml = adl_rt_pitchBendML(device : MIDIPlayer*, channel : LibC::Char, msb : LibC::Char, lsb : LibC::Char) : Void
  fun rt_bank_change_lsb = adl_rt_bankChangeLSB(device : MIDIPlayer*, channel : LibC::Char, lsb : LibC::Char) : Void
  fun rt_bank_change_msb = adl_rt_bankChangeMSB(device : MIDIPlayer*, channel : LibC::Char, msb : LibC::Char) : Void
  fun rt_bank_change = adl_rt_bankChange(device : MIDIPlayer*, channel : LibC::Char, bank : LibC::Short) : Void
  fun rt_system_exclusive = adl_rt_systemExclusive(device : MIDIPlayer*, msg : LibC::Char*, size : LibC::Long) : LibC::Int
end
