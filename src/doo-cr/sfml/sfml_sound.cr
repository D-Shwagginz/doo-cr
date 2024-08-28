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

require "../audio/i_sound.cr"

module Doocr::SFML
  class SFMLSound
    include Audio::ISound

    @@sound_count : Int32 = 8

    @@fast_decay : Float32 = 0.5_f32 ** (1.0 / (35 / 5))
    @@slow_decay : Float32 = 0.5_f32 ** (1.0 / 35)

    @@clip_dist : Float32 = 1200
    @@close_dist : Float32 = 160
    @@attenuator : Float32 = @@clip_dist - @@close_dist

    @config : Config

    @buffers : Array(SF::SoundBuffer) = [] of SF::SoundBuffer
    @amplitudes : Array(Float32) = [] of Float32

    @random : DoomRandom | Nil = nil

    @sounds : Array(SF::Sound) = [] of SF::Sound
    @infos : Array(SoundInfo) = [] of SoundInfo

    @ui_sound : SF::Sound | Nil = nil
    @ui_reserved : Sfx = Sfx.new(0)

    @listener : Mobj | Nil = nil

    @master_volume_decay : Float32 = 0_f32

    @last_update : Time = Time.utc

    def initialize(@config, content : GameContent)
      begin
        print("Initialize sound: ")

        @config.audio_soundvolume = @config.audio_soundvolume.clamp(0, max_volume)

        @buffers = Array.new(DoomInfo.sfx_names.size, SF::SoundBuffer.new)
        @amplitudes = Array.new(DoomInfo.sfx_names.size, 0_f32)

        @random = DoomRandom.new if @config.audio_randompitch

        DoomInfo.sfx_names.size.times do |i|
          name = "DS" + DoomInfo.sfx_names[i].to_s.upcase
          lump = content.wad.as(Wad).get_lump_number(name)
          next if lump == -1

          samples = get_samples(content.wad.as(Wad), name)
          sample_rate = samples[1]
          sample_count = samples[2]
          samples = samples[0]
          if !samples.empty?
            @buffers[i].load_from_samples(samples, 1, sample_rate)
            @amplitudes[i] = get_amplitude(samples, sample_rate, sample_count)
          end
        end

        @sounds = Array.new(@@sound_count, SF::Sound.new)
        @infos = Array.new(@@sound_count, SoundInfo.new)

        @ui_sound = SF::Sound.new
        @ui_reserved = Sfx::NONE

        @master_volume_decay = @config.audio_soundvolume.to_f32 / max_volume

        @last_update = Time::UNIX_EPOCH

        puts "OK"
      rescue e
        puts "Failed"
        raise e
      end
    end

    private def get_samples(wad : Wad, name : String) : Tuple(Array(Int16), Int32, Int32)
      bytedata = wad.read_lump(name)
      data = [] of Int16
      bytedata.each.with_index do |d, i|
        data << d.to_i16
      end

      return {[] of Int16, -1, -1} if data.size < 8

      sample_rate = IO::ByteFormat::LittleEndian.decode(UInt16, bytedata[2, 2])
      sample_count = sample_rate = IO::ByteFormat::LittleEndian.decode(Int32, bytedata[4, 4])

      offset = 8
      if contains_dmx_padding(data)
        offset += 16
        sample_count -= 32
      end

      if sample_count > 0
        return {data[offset, sample_count], sample_rate, sample_count}
      else
        return {[] of Int16, sample_rate, sample_count}
      end
    end

    # Check if the data contains pad bytes.
    # If the first and last 16 samples are the same,
    # the data should contain pad bytes.
    # https://doomwiki.org/wiki/Sound
    private def contains_dmx_padding(data : Array(Int16)) : Bool
      bytedata = Bytes.new(data.size * 2)
      data.each.with_index do |d, i|
        bytedata[i * 2] = d.to_u8
        bytedata[i * 2 + 1] = (d >> 2).to_u8
      end
      sample_count = IO::ByteFormat::LittleEndian.decode(Int32, bytedata[0, 4])
      if sample_count < 32
        return false
      else
        first = data[8]
        i = 1
        while i < 16
          return false if data[8 + 1] != first
          i += 1
        end

        last = data[8 + sample_count - 1]
        i = 1
        while i < 16
          return false if data[8 + sample_count - i - 1] != last
          i += 1
        end
      end

      return true
    end

    private def get_amplitude(samples : Array(Int16), sample_rate : Int32, sample_count : Int32) : Float32
      max = 0
      if sample_count > 0
        count = Math.min((sample_rate / 5).to_i32, sample_count)
        count.times do |t|
          a = samples[t] - 128
          a = -a if a < 0
          max = a if a > max
        end
      end
      return max.to_f32 / 128
    end

    def set_listener(listener : Mobj)
      @listener = listener
    end

    def update
      now = Time.local
      if (now - @last_update).total_seconds < 0.01
        # Don't update so frequently (for timedemo).
        return
      end

      @infos.size.times do |i|
        info = @infos[i]
        sound = @sounds[i]

        if info.playing != Sfx::NONE
          if sound.status != SF::SoundSource::Status::Stopped
            if info.type == SfxType::Diffuse
              info.priority *= @@slow_decay
            else
              info.priority *= @@fast_decay
            end
            set_param(sound, info)
          else
            info.playing = Sfx::NONE
            if info.reserved == Sfx::NONE
              info.source = nil
            end
          end
        end

        if info.reserved != Sfx::NONE
          sound.stop if info.playing != Sfx::NONE

          sound.buffer = @buffers[info.reserved.to_i32]
          set_param(sound, info)
          sound.pitch = get_pitch(info.type, info.reserved)
          sound.play
          info.playing = info.reserved
          info.reserved = Sfx::NONE
        end
      end

      if @ui_reserved != Sfx::NONE
        if @ui_sound.as(SF::Sound).status == SF::SoundSource::Status::Playing
          @ui_sound.as(SF::Sound).stop
        end
        @ui_sound.as(SF::Sound).position = SF::Vector3f.new(0, 0, -1)
        @ui_sound.as(SF::Sound).volume = @master_volume_decay
        @ui_sound.as(SF::Sound).buffer = @buffers[@ui_reserved.to_i32]
        @ui_sound.as(SF::Sound).play
        @ui_reserved = Sfx::NONE
      end

      @last_update = now
    end

    def start_sound(sfx : Sfx)
      return if @buffers[sfx.to_i32]? == nil
      @ui_reserved = sfx
    end

    def start_sound(mobj : Mobj, sfx : Sfx, type : SfxType)
      start_sound(mobj, sfx, type, 100)
    end

    def start_sound(mobj : Mobj, sfx : Sfx, type : SfxType, volume : Int32)
      return if @buffers[sfx.to_i32]? == nil

      x = (mobj.x - @listener.as(Mobj).x).to_f32
      y = (mobj.y - @listener.as(Mobj).y).to_f32
      dist = Math.sqrt(x * x + y * y)

      priority = 0_f32
      if type == SfxType::Diffuse
        priority = volume
      else
        priority = @amplitudes[sfx.to_i32] * get_distance_decay(dist) * volume
      end

      @infos.size.times do |i|
        info = @infos[i]
        if info.source == mobj && info.type == type
          info.reserved = sfx
          info.priority = priority.to_f32
          info.volume = volume
          return
        end
      end

      @infos.size.times do |i|
        info = @infos[i]
        if info.reserved == Sfx::NONE && info.playing == Sfx::NONE
          info.reserved = sfx
          info.priority = priority.to_f32
          info.source = mobj
          info.type = type
          info.volume = volume
          return
        end
      end

      min_priority = Float32::MAX
      min_channel = -1
      @infos.size.times do |i|
        info = @infos[i]
        if info.priority < min_priority
          min_priority = info.priority
          min_channel = i
        end
      end
      if priority >= min_priority
        info = @infos[min_channel]
        info.reserved = sfx
        info.priority = priority.to_f32
        info.source = mobj
        info.type = type
        info.volume = volume
      end
    end

    def stop_sound(mobj : Mobj)
      @infos.size.times do |i|
        info = @infos[i]
        if info.source == mobj
          info.last_x = info.source.as(Mobj).x
          info.last_y = info.source.as(Mobj).y
          info.source = nil
          info.volume = (info.volume / 5).to_i32
        end
      end
    end

    def reset
      @random.as(DoomRandom).clear if @random != nil

      @infos.size.times do |i|
        @sounds[i].stop
        @infos[i].clear
      end

      @listener = nil
    end

    def pause
      @infos.size.times do |i|
        sound = @sounds[i]

        if (sound.status == SF::SoundSource::Status::Playing &&
           sound.buffer.as(SF::SoundBuffer).duration - sound.playing_offset > SF.milliseconds(200))
          @sounds[i].pause
        end
      end
    end

    def resume
      @infos.size.times do |i|
        sound = @sounds[i]

        sound.play if sound.status == SF::SoundSource::Status::Paused
      end
    end

    private def set_param(sound : SF::Sound, info : SoundInfo)
      if info.type == SfxType::Diffuse
        sound.position = SF::Vector3f.new(0, 0, -1)
        sound.volume = 0.01_f32 * @master_volume_decay * info.volume
      else
        source_x : Fixed
        source_y : Fixed
        if info.source == nil
          source_x = info.last_x
          source_y = info.last_y
        else
          source_x = info.source.as(Mobj).x
          source_y = info.source.as(Mobj).y
        end

        x = (source_x - @listener.as(Mobj).x).to_f32
        y = (source_y - @listener.as(Mobj).y).to_f32

        if x.abs < 16 && y.abs < 16
          sound.position = SF::Vector3f.new(0, 0, -1)
          sound.volume = 0.01_f32 * @master_volume_decay * info.volume
        else
          dist = Math.sqrt(x * x + y * y)
          angle = Math.atan2(y, x) - @listener.as(Mobj).angle.to_radian.to_f32
          sound.position = SF::Vector3f.new(-Math.sin(angle), 0, -Math.cos(angle))
          sound.volume = 0.01_f32 * @master_volume_decay * get_distance_decay(dist) * info.volume
        end
      end
    end

    private def get_distance_decay(dist : Float32) : Float32
      if dist < @@close_dist
        return 1_f32
      else
        return Math.max((@@clip_dist - dist) / @@attenuator, 0_f32)
      end
    end

    private def get_pitch(type : SfxType, sfx : Sfx) : Float32
      if @random != nil
        if sfx == Sfx::ITEMUP || sfx == Sfx::TINK || sfx == Sfx::RADIO
          return 1_f32
        elsif type == SfxType::Voice
          return 1_f32 + 0.075_f32 * (@random.as(DoomRandom).next - 128) / 128
        else
          return 1_f32 + 0.025_f32 * (@random.as(DoomRandom).next - 128) / 128
        end
      else
        return 1_f32
      end
    end

    def finalize
      puts "Shutdown sound."

      @sounds.size.times do |i|
        @sounds[i].stop
        @sounds[i].finalize
      end

      @sounds.clear

      @buffers.size.times do |i|
        @buffers[i].finalize
      end

      @buffers.clear

      @ui_sound.as(SF::Sound).finalize if @ui_sound != nil
      @ui_sound = nil
    end

    def max_volume : Int32
      return 15
    end

    def volume : Int32
      return @config.audio_soundvolume
    end

    def volume=(volume : Int32)
      @config.audio_soundvolume = volume
      @master_volume_decay = @config.audio_soundvolume.to_f32 / max_volume
    end

    private class SoundInfo
      property reserved : Sfx = Sfx.new(0)
      property playing : Sfx = Sfx.new(0)
      property priority : Float32 = 0_f32

      property source : Mobj | Nil = nil
      property type : SfxType = SfxType.new(0)
      property volume : Int32 = 0
      property last_x : Fixed = Fixed.zero
      property last_y : Fixed = Fixed.zero

      def clear
        @reserved = Sfx::NONE
        @playing = Sfx::NONE
        @priority = 0
        @source = nil
        @type = SfxType.new(0)
        @volume = 0
        @last_x = Fixed.zero
        @lasy_y = Fixed.zero
      end
    end
  end
end
