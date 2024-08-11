# System interface for sound.

module Doocr
  MAX_SFX_VOLUME               =   15
  MAX_MUSIC_VOLUME             =   15
  MAX_SAMPLES_PER_MUSIC_UPDATE = 4096

  @@sounds : Hash(String, RAudio::Sound) = Hash(String, RAudio::Sound).new
  @@adl_midi_player : Pointer(ADLMidi::MIDIPlayer) = ADLMidi.init(44100)
  @@opn_midi_player : Pointer(OPNMidi::MIDIPlayer) = OPNMidi.init(44100)
  @@adl_midi_audio_format : ADLMidi::AudioFormat = ADLMidi::AudioFormat.new(
    type: ADLMidi::SampleType::S16,
    container_size: sizeof(Int16),
    sample_offset: sizeof(Int16) * 2
  )
  @@opn_midi_audio_format : OPNMidi::AudioFormat = OPNMidi::AudioFormat.new(
    type: OPNMidi::SampleType::S16,
    container_size: sizeof(Int16),
    sample_offset: sizeof(Int16) * 2
  )

  @@mus_stream : RAudio::AudioStream = RAudio.load_audio_stream(44100, 16, 2)

  @@adl_bank_name : String = "./midibanks/adl/DMXOPL3-by-sneakernets-GS.wopl"
  @@opn_bank_name : String = "./midibanks/opn/xg.wopn"

  @@use_adl : Bool = false

  def self.i_init_sound
    RAudio.init_audio_device

    buf = IO::Memory.new

    @@lumps.each do |name, lump|
      next unless lump.as?(WAD::Sound)
      lump.as(WAD::Sound).to_wav(buf)
      wavedata = buf.to_slice
      wav = RAudio.load_wave_from_memory(".wav", wavedata, wavedata.size)
      sound = RAudio.load_sound_from_wave(wav)
      @@sounds[name] = sound
      RAudio.unload_wave(wav)
      buf.clear
    end

    buf.close
    GC.collect
  end

  def self.i_init_music
    RAudio.set_audio_stream_buffer_size_default(MAX_SAMPLES_PER_MUSIC_UPDATE)
    @@mus_stream = RAudio.load_audio_stream(44100, 16, 2)
    RAudio.play_audio_stream(@@mus_stream)

    if @@use_adl
      if @@adl_midi_player
        ADLMidi.switch_emulator(@@adl_midi_player, ADLMidi::Emulator::Dosbox)
        ADLMidi.set_num_chips(@@adl_midi_player, 2)
        raise "i_init_music: Invalid ADLMIDI bank file" if ADLMidi.open_bank_file(@@adl_midi_player, @@adl_bank_name) < 0
        ADLMidi.set_loop_enabled(@@adl_midi_player, 1)

        song = @@lumps["D_E1M1"].as?(WAD::Music)
        raise "nosong" unless song

        raise "w" if ADLMidi.open_data(@@adl_midi_player, song.raw, song.raw.size) < 0

        RAudio.set_audio_stream_callback(@@mus_stream, ->i_audio_input_callback(Void*, UInt32))
      else
        raise "i_init_music: Couldn't initialize ALDMIDI: #{ADLMidi.error_string}"
      end
    else
      if @@opn_midi_player
        OPNMidi.switch_emulator(@@opn_midi_player, OPNMidi::Emulator::Dosbox)
        OPNMidi.set_num_chips(@@opn_midi_player, 2)
        raise "i_init_music: Invalid OPNMIDI bank file" if OPNMidi.open_bank_file(@@opn_midi_player, @@opn_bank_name) < 0
        OPNMidi.set_loop_enabled(@@opn_midi_player, 1)

        song = @@lumps["D_E1M1"].as?(WAD::Music)
        raise "nosong" unless song

        raise "w" if OPNMidi.open_data(@@opn_midi_player, song.raw, song.raw.size) < 0

        RAudio.set_audio_stream_callback(@@mus_stream, ->i_audio_input_callback(Void*, UInt32))
      else
        raise "i_init_music: Couldn't initialize OPNMIDI: #{OPNMidi.error_string}"
      end
    end
  end

  def self.i_audio_input_callback(buffer : Void*, frames : UInt32)
    if @@use_adl
      ADLMidi.play_format(@@adl_midi_player, frames * 2, buffer.as(UInt8*), buffer.as(UInt8*) + @@adl_midi_audio_format.container_size, pointerof(@@adl_midi_audio_format))
    else
      OPNMidi.play_format(@@opn_midi_player, frames * 2, buffer.as(UInt8*), buffer.as(UInt8*) + @@opn_midi_audio_format.container_size, pointerof(@@opn_midi_audio_format))
    end
  end
end
