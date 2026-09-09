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
# ==> Midi stuff

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
    return Doocr.mixbuffer.to_unsafe
  end
end
