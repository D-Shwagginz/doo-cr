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
# ==> System audio

module Doocr
  def self.i_set_channels
    # Init internal lookups (raw data, mixing buffer, channels).
    # This function sets up internal lookups used during
    #  the mixing process.
    # This table provides step widths for pitch parameters.
    # I fail to see that this is currently used.
    i = -128
    while i < 128
      Doocr.steptable[i + 128] = ((2**(i / 64.0)) * 65536).floor.to_i32!
      i += 1
    end

    # Generates volume lookup tables
    #  which also turn the unsigned samples
    #  into signed samples.
    128.times do |i|
      256.times do |j|
        Doocr.vol_lookup[i * 256 + j] = (i * (j - 128) * 256) // 127
      end
    end
  end

  # MUSIC API - dummy. Some code from DOS version.
  def self.i_set_music_volume(volume : Int32)
    Doocr.mus_volume = Doocr.snd_music_volume * 8
  end

  def self.i_get_sfx_lump_num(sfx : Doocr::Sfxinfo) : Int32
    namebuf = uninitialized StaticArray(UInt8, 9)

    CDoom.doom_strcpy(namebuf, "ds")
    CDoom.doom_concat(namebuf, sfx.name.to_unsafe)
    return CDoom.w_get_num_for_name(namebuf)
  end

  #
  # Starting a sound means adding it
  #  to the current list of active sounds
  #  in the internal channels.
  # As the SFX info struct contains
  #  e.g. a pointer to the raw data,
  #  it is ignored.
  # As our sound handling does not handle
  #  priority, it is ignored.
  # Pitching (that is, increased speed of playback)
  #  is set, but currently not used by mixing.
  #
  def self.i_start_sound(id : Int32, vol : Int32, sep : Int32, pitch : Int32, priority : Int32) : Int32
    # Returns a handle (not used).
    pitch = Doocr::NORM_PITCH if @@randompitch == 0
    id = CDoom.addsfx(id, vol, Doocr.steptable[pitch], sep)
    return id
  end

  def self.i_stop_sound(handle : Int32)
    @@sound_mutex.synchronize do
      Doocr::NUM_CHANNELS.times do |chan|
        if Doocr.channelhandles[chan] == handle && !Doocr.channels[chan].null?
          Doocr.channels[chan] = Pointer(UInt8).null
          break
        end
      end
    end
  end

  def self.i_sound_is_playing(handle : Int32) : Int32
    @@sound_mutex.synchronize do
      Doocr::NUM_CHANNELS.times do |chan|
        return (!Doocr.channels[chan].null?).to_unsafe if Doocr.channelhandles[chan] == handle
      end
    end

    return 0
  end

  #
  # This function loops all active (internal) sound
  #  channels, retrieves a given number of samples
  #  from the raw sound data, modifies it according
  #  to the current (internal) channel parameters,
  #  mixes the per channel samples into the global
  #  mixbuffer, clamping it to the allowed range,
  #  and sets up everything for transferring the
  #  contents of the mixbuffer to the (two)
  #  hardware channels (left and right, that is).
  #
  # This function currently supports only 16bit.
  #
  def self.i_update_sound
    # Left and right channel
    #  are in global mixbuffer, alternating.
    leftout = Doocr.mixbuffer.to_unsafe
    rightout = Doocr.mixbuffer.to_unsafe + 1
    step = 2

    # Determine end, for left channel only
    #  (right channel is implicit).
    leftend = Doocr.mixbuffer.to_unsafe + Doocr::SAMPLECOUNT * step

    @@sound_mutex.synchronize do
      # Mix sounds into the mixing buffer.
      # Loop over step*SAMPLECOUNT,
      #  that is 512 values for two channels.
      while leftout != leftend
        # Reset left/right value.

        dl = 0
        dr = 0

        # Love thy L2 chache - made this a loop.
        # Now more channels could be set at compile time
        #  as well. Thus loop those  channels.
        Doocr::NUM_CHANNELS.times do |chan|
          # Check channel, if active.
          if !Doocr.channels[chan].null?
            # Get the raw data from the channel.
            sample = Doocr.channels[chan].value
            # Add left and right part
            #  for this channel (sound)
            #  to the current data.
            # Adjust volume accordingly.
            dl += Doocr.channelleftvol_lookup[chan][sample]
            dr += Doocr.channelrightvol_lookup[chan][sample]
            # Increment index ???
            Doocr.channelstepremainder[chan] = Doocr.channelstepremainder[chan] + Doocr.channelstep[chan]
            # MSB is next sample???
            Doocr.channels[chan] = Doocr.channels[chan] + (Doocr.channelstepremainder[chan] >> 16)
            # Limit to LSB???
            Doocr.channelstepremainder[chan] = Doocr.channelstepremainder[chan] & (65536 - 1)
            # Check whether we are done.
            Doocr.channels[chan] = Pointer(UInt8).null if Doocr.channels[chan] >= Doocr.channelsend[chan]
          end
        end

        # Clamp to range. Left hardware channel.
        # Has been char instead of short.
        # if (dl > 127) *leftout = 127;
        # else if (dl < -128) *leftout = -128;
        # else *leftout = dl;

        if dl > 0x7fff
          leftout.value = 0x7fff
        elsif dl < -0x8000
          leftout.value = -0x8000
        else
          leftout.value = dl.to_i16!
        end

        # Same for right hardware channel.
        if dr > 0x7fff
          rightout.value = 0x7fff
        elsif dr < -0x8000
          rightout.value = -0x8000
        else
          rightout.value = dr.to_i16!
        end

        # Increment current pointers in mixbuffer.
        leftout += step
        rightout += step
      end
    end
  end

  def self.i_update_sound_params(handle : LibC::Int, vol : LibC::Int, sep : LibC::Int, pitch : LibC::Int)
    @@sound_mutex.synchronize do
      # I fail too see that this is used.
      # Would be using the handle to identify
      #  on which channel the sound might be active,
      #  and resetting the channel parameters.
      Doocr::NUM_CHANNELS.times do |chan|
        # Found channel
        if Doocr.channelhandles[chan] == handle
          pitch = 128 if @@randompitch == 0
          step = Doocr.steptable[pitch]
          Doocr.channelstep[chan] = step.to_u32
          Doocr.channelstart[chan] = Doocr.gametic

          sep += 1

          leftvol = vol - ((vol * sep * sep) >> 16)
          sep = sep - 257
          rightvol = vol - ((vol * sep * sep) >> 16)

          CDoom.i_error("Error: rightvol out of bounds") if rightvol < 0 || rightvol > 127
          CDoom.i_error("Error: leftvol out of bounds") if leftvol < 0 || leftvol > 127

          Doocr.channelleftvol_lookup[chan] = Doocr.vol_lookup.to_unsafe + leftvol*256
          Doocr.channelrightvol_lookup[chan] = Doocr.vol_lookup.to_unsafe + rightvol*256

          break
        end
      end
    end
  end

  def self.i_shutdown_sound
    # # Wait till all pending sounds are finished.
    # hopetill = i_get_time + 1*70 # Give a second to finish

    # print "i_shutdown_sound: Finishing pending sounds..."

    # loop do
    #   done = true

    #   Doocr.num_channels.times do |i|
    #     next if Doocr.channels[i].null?
    #     done = false
    #   end

    #   if done
    #     puts " finished!"
    #     break
    #   end

    #   if i_get_time > hopetill
    #     puts " couldn't finish."
    #     break
    #   end
    # end

    # Done.
    return
  end

  def self.update_audio
    RAudio.init_audio_device
    RAudio.set_master_volume(10.0)
    RAudio.set_audio_stream_buffer_size_default(512)
    @@audio_stream = RAudio.load_audio_stream(CDoom::DOOM_SAMPLERATE, 16, 2)
    RAudio.set_audio_stream_volume(@@audio_stream.not_nil!, 1.0)
    RAudio.play_audio_stream(@@audio_stream.not_nil!)

    @@adl_player = ADLMIDI.adl_init(MIDI_SAMPLE_RATE)
    ADLMIDI.adl_setNumChips(@@adl_player.not_nil!, 4)
    ADLMIDI.adl_setBank(@@adl_player.not_nil!, @@midibank)

    ADLMIDI.adl_setSoftPanEnabled(@@adl_player.not_nil!, @@midismoothpan)

    RAudio.set_audio_stream_buffer_size_default(MIDI_BUFFER_SIZE // 2)
    @@music_stream = RAudio.load_audio_stream(MIDI_SAMPLE_RATE, 16, 2)
    RAudio.set_audio_stream_volume(@@music_stream.not_nil!, 1.0)
    RAudio.play_audio_stream(@@music_stream.not_nil!)
    @@music_buffer = Pointer(Int16).malloc(MIDI_BUFFER_SIZE)
    @@midi_tick_accumulator = 0.0

    @@last_time = Raylib.get_time

    loop do
      next unless Raylib.window_ready? && RAudio.audio_device_ready? &&
                  @@audio_stream && @@adl_player
      now = Raylib.get_time
      @@midi_tick_accumulator += now - @@last_time
      @@last_time = now

      unless @@mus_is_midi
        while @@midi_tick_accumulator >= MIDI_TICK_TIME
          while (msg = doom_tick_midi) != 0
            status = (msg & 0xFF).to_u8
            data1 = ((msg >> 8) & 0xFF).to_u8
            data2 = ((msg >> 16) & 0xFF).to_u8
            command = status & 0xF0
            channel = status & 0x0F

            return if @@closing
            @@adl_player.try do |ap|
              case command
              when 0x80
                ADLMIDI.adl_rt_noteOff(ap, channel, data1)
              when 0x90
                if data2 == 0
                  ADLMIDI.adl_rt_noteOff(ap, channel, data1) # vel 0 == note off
                else
                  ADLMIDI.adl_rt_noteOn(ap, channel, data1, data2)
                end
              when 0xA0
                ADLMIDI.adl_rt_noteAfterTouch(ap, channel, data1, data2)
              when 0xB0
                ADLMIDI.adl_rt_controllerChange(ap, channel, data1, data2)
              when 0xC0
                ADLMIDI.adl_rt_patchChange(ap, channel, data1)
              when 0xD0
                ADLMIDI.adl_rt_channelAfterTouch(ap, channel, data1)
              when 0xE0
                ADLMIDI.adl_rt_pitchBendML(ap, channel, data2, data1) # wire order: LSB, MSB
              end
            end
          end
          @@midi_tick_accumulator -= MIDI_TICK_TIME
        end
      end

      return if @@closing
      unless Doocr.mus_playing == 0
        @@music_stream.try do |m|
          RAudio.set_audio_stream_volume(m, Doocr.snd_music_volume / 15.0)
          @@adl_player.try do |ap|
            if RAudio.audio_stream_processed?(m)
              if @@mus_is_midi
                ADLMIDI.adl_play(ap, MIDI_BUFFER_SIZE, @@music_buffer)
              else
                generated = ADLMIDI.adl_generate(ap, MIDI_BUFFER_SIZE, @@music_buffer)
              end
              RAudio.update_audio_stream(m, @@music_buffer, MIDI_BUFFER_SIZE // 2)
            end
          end
        end
      end

      return if @@closing
      @@audio_stream.try do |a|
        RAudio.set_audio_stream_volume(a, @@snd_sfx_volume / 15.0)
        if RAudio.audio_stream_processed?(a)
          RAudio.update_audio_stream(a, doom_get_sound_buffer, 512)
        end
      end
    end

    @@audio_stream.try { |a| RAudio.unload_audio_stream(a) }

    sleep 1.millisecond # Let music stop
    @@music_stream.try { |m| RAudio.unload_audio_stream(m) }
    @@adl_player.try { |ap| ADLMIDI.adl_close(ap) }

    RAudio.close_audio_device
  end

  def self.i_init_sound
    # Initialize external data (all sounds) at start, keep static.
    print "i_init_sound: "

    i = 1
    while i < @@s_sfx.size
      # Alias? Example is the chaingun sound linked to pistol.
      sfx = @@s_sfx[i]
      if sfx.link.nil?
        # Load data from WAD file.
        sfx.data = CDoom.getsfx(sfx.name.to_unsafe, @@lengths.to_unsafe + i)
      else
        # Previously loaded already?
        link_index = @@s_sfx.index(sfx.link.not_nil!).not_nil!
        sfx.data = sfx.link.not_nil!.data
        @@lengths[i] = @@lengths[link_index]
      end

      i += 1
    end

    print "Pre-cached all sound data - "

    # Now initialize mixbuffer with zero.
    Doocr::MIXBUFFERSIZE.times { |i| Doocr.mixbuffer[i] = 0 }

    # Finished initialization.
    puts "sound module ready."
  end

  #
  # MUSIC API.
  #
  def self.i_init_music
  end

  def self.i_shutdown_music
  end

  def self.i_play_song(handle : Int32, looping : Int32)
    i_set_music_volume(Doocr.snd_music_volume)
    @@midi_tick_accumulator = 0

    Doocr.musicdies = Doocr.gametic + CDoom::TICRATE * 30

    Doocr.mus_loop = looping != 0 ? 1 : 0
    Doocr.mus_playing = 1
    if @@mus_is_midi
      if current_music = @@mus_playing_s_sound
        @@adl_player.try { |ap| ADLMIDI.adl_openData(ap, Doocr.mus_data, w_lump_length(current_music.lumpnum)) }
      end
    end
  end

  def self.i_pause_song(handle : Int32)
    Doocr.mus_playing = 0
  end

  def self.i_resume_song(handle : Int32)
    Doocr.mus_playing = 1 if !Doocr.mus_data.null?
  end

  def self.reset_all_channels
    16.times do |i|
      Doocr.queued_midi_msgs[Doocr.queue_midi_tail % Doocr::MAX_QUEUED_MIDI_MSGS] = 0b10110000_u64 | i.to_u64 | (123_u64 << 8)
      Doocr.queue_midi_tail += 1
    end
  end

  def self.i_stop_song(handle : LibC::Int)
    Doocr.mus_data = Pointer(UInt8).null
    Doocr.mus_delay = 0
    Doocr.mus_offset = 0
    Doocr.mus_playing = 0
    @@mus_is_midi = false
    @@adl_player.try { |ap| ADLMIDI.adl_panic(ap) }
    @@adl_player.try { |ap| ADLMIDI.adl_reset(ap) }

    CDoom.reset_all_channels
  end

  def self.i_unregister_song(handle : LibC::Int)
    CDoom.i_stop_song(handle)
  end

  def self.i_register_song(data : Void*) : LibC::Int
    @@mus_is_midi = false
    @@mus_channel_volume.fill(127)

    @@mus_header.read(data.as(UInt8*))
    if (!@@mus_header.id.starts_with?("MUS") || @@mus_header.id.bytes[3] != 0x1A)
      if !@@mus_header.id.starts_with?("MThd")
        # Not a midi either
        return 0
      else
        @@mus_is_midi = true
      end
    end

    Doocr.mus_data = data.as(UInt8*)
    Doocr.mus_delay = 0
    Doocr.mus_offset = @@mus_header.score_start
    Doocr.mus_playing = 0

    return 1
  end

  # Is the song playing?
  def self.i_qry_song_playing(handle : LibC::Int) : LibC::Int
    return Doocr.mus_playing
  end

  @@mus_channel_volume = Array(Int32).new(16, 127)

  # Is the song playing?
  def self.i_tick_song : UInt64
    return 0_u64 if @@mus_is_midi
    midi_event : UInt64 | UInt32 = 0

    # Dequeue MIDI events
    if Doocr.queue_midi_head != Doocr.queue_midi_tail
      Doocr.queue_midi_head += 1
      r = Doocr.queued_midi_msgs[(Doocr.queue_midi_head - 1).remainder(Doocr::MAX_QUEUED_MIDI_MSGS)]
      r.to_u64!
    end

    if Doocr.mus_playing == 0 || Doocr.mus_data.null?
      return 0_u64
    end

    if Doocr.mus_delay <= 0
      event = Doocr.mus_data[Doocr.mus_offset].to_i32
      Doocr.mus_offset += 1
      type = (event & 0b01110000) >> 4
      channel = event & 0b00001111

      if channel == 15
        channel = 9 # Percussion is 9 on GM
      elsif channel == 9
        channel = 15
      end

      case type
      when Doocr::EVENT_RELEASE_NOTE
        note = Doocr.mus_data[Doocr.mus_offset].to_i32 & 0b01111111
        Doocr.mus_offset += 1
        midi_event = (0x00000080_u32 | channel | (note << 8))
      when Doocr::EVENT_PLAY_NOTE
        note_bytes = Doocr.mus_data[Doocr.mus_offset].to_i32
        Doocr.mus_offset += 1
        note = note_bytes & 0b01111111
        if note_bytes & 0b10000000 != 0
          @@mus_channel_volume[channel] = Doocr.mus_data[Doocr.mus_offset].to_i32 & 0b01111111
          Doocr.mus_offset += 1
        end
        vol = @@mus_channel_volume[channel]
        midi_event = (0x00000090_u32 | channel | (note << 8) | (vol << 16))
      when Doocr::EVENT_PITCH_BEND
        bend_amount = Doocr.mus_data[Doocr.mus_offset].to_i32 * 64
        Doocr.mus_offset += 1
        l = bend_amount & 0b01111111
        m = (bend_amount & 0b1111111110000000) >> 7
        midi_event = (0x000000E0_u32 | channel | (l << 8) | (m << 16))
      when Doocr::EVENT_SYSTEM_EVENT
        controller = Doocr.mus_data[Doocr.mus_offset].to_i32 & 0b01111111
        Doocr.mus_offset += 1
        case controller
        when Doocr::CONTROLLER_EVENT_ALL_SOUNDS_OFF
          midi_event = (0x000000B0_u32 | channel | (120 << 8))
        when Doocr::CONTROLLER_EVENT_ALL_NOTES_OFF
          midi_event = (0x000000B0_u32 | channel | (123 << 8))
        when Doocr::CONTROLLER_EVENT_MONO
          midi_event = (0x000000B0_u32 | channel | (126 << 8))
        when Doocr::CONTROLLER_EVENT_POLY
          midi_event = (0x000000B0_u32 | channel | (127 << 8))
        when Doocr::CONTROLLER_EVENT_RESET_ALL_CONTROLLERS
          midi_event = (0x000000B0_u32 | channel | (121 << 8))
          @@mus_channel_volume[channel] = 127
        when Doocr::CONTROLLER_EVENT_EVENT # Doom never implemented
        end
      when Doocr::EVENT_CONTROLLER
        controller = Doocr.mus_data[Doocr.mus_offset].to_i32 & 0b01111111
        Doocr.mus_offset += 1
        value = Doocr.mus_data[Doocr.mus_offset].to_i32 & 0b01111111
        Doocr.mus_offset += 1
        case controller
        when Doocr::CONTROLLER_CHANGE_INSTRUMENT
          midi_event = (0x000000C0_u32 | channel | (value << 8))
        when Doocr::CONTROLLER_BANK_SELECT
          midi_event = (0x000000B0_u32 | channel | 0x2000 | (value << 16))
        when Doocr::CONTROLLER_MODULATION
          midi_event = (0x000000B0_u32 | channel | 0x0100 | (value << 16))
        when Doocr::CONTROLLER_VOLUME
          midi_event = (0x000000B0_u32 | channel | 0x0700 | (value << 16))
        when Doocr::CONTROLLER_PAN
          midi_event = (0x000000B0_u32 | channel | 0x0A00 | (value << 16))
        when Doocr::CONTROLLER_EXPRESSION
          midi_event = (0x000000B0_u32 | channel | 0x0B00 | (value << 16))
        when Doocr::CONTROLLER_REVERB
          midi_event = (0x000000B0_u32 | channel | 0x5B00 | (value << 16))
        when Doocr::CONTROLLER_CHORUS
          midi_event = (0x000000B0_u32 | channel | 0x5D00 | (value << 16))
        when Doocr::CONTROLLER_SUSTAIN
          midi_event = (0x000000B0_u32 | channel | 0x4000 | (value << 16))
        when Doocr::CONTROLLER_SOFT
          midi_event = (0x000000B0_u32 | channel | 0x4300 | (value << 16))
        end
      when Doocr::EVENT_END_OF_MEASURE
      when Doocr::EVENT_FINISH
        # Loop
        if Doocr.mus_loop != 0
          Doocr.mus_delay = 0
          Doocr.mus_offset = @@mus_header.score_start
        else
          Doocr.mus_playing = 0
          return 0_u64
        end
      when Doocr::EVENT_UNUSED
        dummy = Doocr.mus_data[Doocr.mus_offset].to_i32
        Doocr.mus_offset += 1
      end

      if event & 0b10000000 != 0 # Followed by delay
        Doocr.mus_delay = 0
        delay_byte = 0
        loop do
          delay_byte = Doocr.mus_data[Doocr.mus_offset]
          Doocr.mus_offset += 1
          Doocr.mus_delay = Doocr.mus_delay * 128 + (delay_byte & 0b01111111)

          break unless delay_byte & 0b10000000 != 0
        end

        return midi_event.to_u64!
      end
    end

    Doocr.mus_delay -= 1

    return midi_event.to_u64!
  end
end
