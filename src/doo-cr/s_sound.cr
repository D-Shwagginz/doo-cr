# Sound Functions and data

module Doocr
  def self.s_init(sfx_volume : Int32, music_volume : Int32)
    puts "s_init: default sfx volume #{sfx_volume}"

    s_set_sfx_volume(sfx_volume)
    s_set_music_volume(music_volume)
  end

  def self.s_set_sfx_volume(volume : Int32)
    raise "Attempt to set sfx volume at #{volume} when max sfx volume is #{MAX_SFX_VOLUME}" if volume < 0 || volume > MAX_SFX_VOLUME
    @@config["sfx_volume"] = volume
    @@sounds.values.each { |i| RAudio.set_sound_volume(i, MAX_SFX_VOLUME/volume) }
  end

  def self.s_set_music_volume(volume : Int32)
    raise "Attempt to set music volume at #{volume} when max music volume is #{MAX_MUSIC_VOLUME}" if volume < 0 || volume > MAX_SFX_VOLUME
    @@config["music_volume"] = volume
    RAudio.set_audio_stream_volume(@@mus_stream, MAX_MUSIC_VOLUME/volume)
  end
end
