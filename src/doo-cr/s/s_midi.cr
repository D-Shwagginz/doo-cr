module Doocr
  # Midi info
  MIDI_BUFFER_SIZE =  1024
  MIDI_SAMPLE_RATE = 44100
  MIDI_TICK_TIME   = 1.0 / 140.0

  
  def self.doom_tick_midi : UInt64
    return CDoom.i_tick_song
  end

  def self.doom_get_sound_buffer : Int16*
    CDoom.i_update_sound
    return CDoom.mixbuffer.to_unsafe
  end
end