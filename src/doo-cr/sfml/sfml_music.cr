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

require "../audio/i_music.cr"

module Doocr::SFML
  class SFMLMusic
    include Audio::IMusic

    @config : Config
    @wad : Wad | Nil = nil

    @stream : MusStream | Nil = nil
    @current : Bgm = Bgm.new(0)

    class_getter adl_bank_name : String = "./midibanks/adl/DMXOPL3-by-sneakernets-GS.wopl"
    class_getter opn_bank_name : String = "./midibanks/opn/xg.wopn"

    class_getter use_adl : Bool = false

    def initialize(@config, content : GameContent)
      begin
        print("Initialize music: ")

        @wad = content.wad.as(Wad)

        @stream = MusStream.new(self, @config)
        @current = Bgm::NONE

        puts "OK"
      rescue e
        puts "Failed"
        raise e
      end
    end

    def start_music(bgm : Bgm, loop : Bool)
      return if bgm == @current

      lump = "D_" + DoomInfo.bgm_names[bgm.to_i32].to_s.as(String).upcase
      data = @wad.as(Wad).read_lump(lump)
      decoder = read_data(data, loop)
      @stream.as(MusStream).set_decoder(decoder)

      @current = bgm
    end

    private def read_data(data : Bytes, loop : Bool) : Decoder
      is_mus = true
      Decoder.mus_header.size.times do |i|
        is_mus = false if data[i] != Decoder.mus_header[i]
      end

      return Decoder.new(data, loop) if is_mus

      is_midi = true
      Decoder.midi_header.size.times do |i|
        is_midi = false if data[i] != Decoder.midi_header[i]
      end

      return Decoder.new(data, loop) if is_midi

      raise "Unknown format!"
    end

    def finalize
      puts "Shutdown music."

      if @stream != nil
        @stream.as(MusStream).finalize
        @stream = nil
      end
    end

    def max_volume : Int32
      return 15
    end

    def volume : Int32
      return @config.audio_musicvolume
    end

    def volume=(volume : Int32)
      @config.audio_musicvolume = volume
    end

    private class MusStream < SF::SoundStream
      @@block_length : Int32 = 2048

      @parent : SFMLMusic
      @config : Config

      @left : Array(Int16) = [] of Int16
      @right : Array(Int16) = [] of Int16

      @current : Decoder | Nil
      @reserved : Decoder | Nil

      @samples = Slice(Int16).new(@@block_length)

      def initialize(@parent, @config)
        @config.audio_musicvolume = @config.audio_musicvolume.clamp(0, @parent.max_volume)

        @left = Array.new(@@block_length, 0_i16)
        @right = Array.new(@@block_length, 0_i16)

        super(2, Decoder.sample_rate)
      end

      def set_decoder(decoder : Decoder)
        @reserved = decoder

        if status == SF::SoundSource::Status::Stopped
          play()
        end
      end

      def on_seek(time_offset)
      end

      def on_get_data : Slice(Int16)?
        if @reserved != @current
          @current.as(Decoder).finalize
          @current = @reserved
        end

        samples = Slice(Int16)

        a = @config.audio_musicvolume / @parent.max_volume

        @current.as(Decoder).render_waveform(@left, @right)

        pos = 0

        @@block_length.times do |t|
          sample_left = (a * @left[t]).to_i32
          if sample_left < Int16::MIN
            sample_left = Int16::MIN
          elsif sample_left > Int16::MAX
            sample_left = Int16::MAX
          end

          sample_right = (a * @right[t])
          if sample_right < Int16::MIN
            sample_right = Int16::MIN
          elsif sample_right > Int16::MAX
            sample_right = Int16::MAX
          end

          @samples[pos] = sample_left.to_i16
          pos += 1
          @samples[pos] = sample_right.to_i16
          pos += 1
        end

        return @samples
      end

      def finalize
        stop()
        if @current != nil
          @current.as(Decoder).finalize
          @current = nil
        end

        if @reserved != nil
          @reserved.as(Decoder).finalize
          @reserved = nil
        end

        super
      end
    end

    private class Decoder
      class_getter mus_header : Array(UInt8) = [
        'M'.ord.to_u8,
        'U'.ord.to_u8,
        'S'.ord.to_u8,
        0x1A_u8,
      ]

      class_getter midi_header : Array(UInt8) = [
        'M'.ord.to_u8,
        'T'.ord.to_u8,
        'h'.ord.to_u8,
        'd'.ord.to_u8,
      ]

      class_getter sample_rate : Int32 = 44100

      @adl_midi_audio_format : ADLMidi::AudioFormat = ADLMidi::AudioFormat.new(
        type: ADLMidi::SampleType::S16,
        container_size: sizeof(Int16),
        sample_offset: sizeof(Int16) * 2
      )
      @opn_midi_audio_format : OPNMidi::AudioFormat = OPNMidi::AudioFormat.new(
        type: OPNMidi::SampleType::S16,
        container_size: sizeof(Int16),
        sample_offset: sizeof(Int16) * 2
      )

      @adl_midi_player : Pointer(ADLMidi::MIDIPlayer) | Nil
      @opn_midi_player : Pointer(OPNMidi::MIDIPlayer) | Nil

      @data : Bytes

      def initialize(@data, loop)
        @adl_midi_player = ADLMidi.init(@@sample_rate)
        @opn_midi_player = OPNMidi.init(@@sample_rate)

        if x = @adl_midi_player.as?(Pointer(ADLMidi::MIDIPlayer))
          ADLMidi.switch_emulator(x, ADLMidi::Emulator::Dosbox)
          ADLMidi.set_num_chips(x, 2)
          ADLMidi.set_bank(x, 14)
          ADLMidi.set_loop_enabled(x, loop.to_unsafe)

          raise "Song data failed to open!" if ADLMidi.open_data(x, @data, @data.size) < 0
          # raise "Invalid ADLMIDI bank file" if ADLMidi.open_bank_file(x, SFMLMusic.adl_bank_name) < 0
        else
          raise "Couldn't initialize ALDMIDI: #{ADLMidi.error_string}"
        end
        if x = @opn_midi_player.as?(Pointer(OPNMidi::MIDIPlayer))
          OPNMidi.switch_emulator(x, OPNMidi::Emulator::Dosbox)
          OPNMidi.set_num_chips(x, 2)
          raise "Invalid OPNMIDI bank file" if OPNMidi.open_bank_file(x, SFMLMusic.opn_bank_name) < 0
          OPNMidi.set_loop_enabled(x, loop.to_unsafe)

          raise "Song data failed to open!" if OPNMidi.open_data(x, @data, @data.size) < 0
        else
          raise "Couldn't initialize OPNMIDI: #{OPNMidi.error_string}"
        end
      end

      def render_waveform(left : Array(Int16), right : Array(Int16))
        if x = @adl_midi_player.as?(Pointer(OPNMidi::MIDIPlayer))
          ADLMidi.play_format(x, left.size, left.as(UInt8*), right.as(UInt8*), pointerof(@adl_midi_audio_format))
        end
      end

      def render_waveform(left : Array(Int16), right : Array(Int16))
        if x = @opn_midi_player.as?(Pointer(OPNMidi::MIDIPlayer))
          OPNMidi.play_format(x, left.size, left.as(UInt8*), right.as(UInt8*), pointerof(@opn_midi_audio_format))
        end
      end

      def finalize
        if x = @adl_midi_player.as?(Pointer(ADLMidi::MIDIPlayer))
          ADLMidi.close(x)
          @adl_midi_player = nil
        end

        if x = @opn_midi_player.as?(Pointer(OPNMidi::MIDIPlayer))
          OPNMidi.close(x)
          @opn_midi_player = nil
        end
      end
    end
  end
end
