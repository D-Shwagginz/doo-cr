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
# ==> Sound code

module Doocr
  @@snd_sfx_volume = 8

  #
  # This function loads the sound data from the WAD lump,
  #  for single sound.
  #
  def self.getsfx(sfxname : UInt8*, len : Int32*) : Void*
    name = uninitialized StaticArray(UInt8, 20)

    # Get the sound data from the WAD, allocate lump
    #  in zone memory.
    CDoom.doom_strcpy(name, "ds")
    CDoom.doom_concat(name, sfxname)

    # Now, there is a severe problem with the
    #  sound handling, in it is not (yet/anymore)
    #  gamemode aware. That means, sounds from
    #  DOOM II will be requested even with DOOM
    #  shareware.
    # The sound list is wired into sounds.c,
    #  which sets the external variable.
    # I do not do runtime patches to that
    #  variable. Instead, we will use a
    #  default sound for replacement.
    sfxlump = 0
    if CDoom.w_check_num_for_name(name) == -1
      sfxlump = CDoom.w_get_num_for_name("dspistol")
    else
      sfxlump = CDoom.w_get_num_for_name(name)
    end

    size = CDoom.w_lump_length(sfxlump)

    sfx = CDoom.w_cache_lump_num(sfxlump, CDoom::PU_STATIC).as(UInt8*)

    samplerate = (sfx + 0x02).as(UInt16*).value
    # Do we need to resample?
    if (resample_div = samplerate // CDoom::DOOM_SAMPLERATE) > 1
      # Boy do we!
      # Downsample multiples of DOOM_SAMPLERATE.
      #  If it's inbetween, too bad.
      src_len = size - 8 - 16 - 16
      out_len = src_len // resample_div
      src = Bytes.new(src_len)
      src.copy_from(sfx + 8 + 16, src_len)
      size = 8 + 16 + out_len + 16
      out_len.times do |i|
        avg = 0
        resample_div.times do |res|
          avg += src[i * resample_div + res].to_u16!
        end
        sfx[i + 8 + 16] = (avg // resample_div).to_u8!
      end
    end

    # Pads the sound effect out to the mixing buffer size.
    # The original realloc would interfere with zone memory.
    paddedsize = ((size - 8 + (CDoom::SAMPLECOUNT - 1)) // CDoom::SAMPLECOUNT) * CDoom::SAMPLECOUNT

    # Allocate from zone memory.
    paddedsfx = CDoom.z_malloc(paddedsize + 8, CDoom::PU_STATIC, Pointer(Void).null).as(UInt8*)
    # ddt: (unsigned char *) realloc(sfx, paddedsize+8);
    # This should interfere with zone memory handling,
    #  which does not kick in in the soundserver.

    # Now copy and pad.
    CDoom.doom_memcpy(paddedsfx, sfx, size)
    i = size
    while i < paddedsize + 8
      paddedsfx[i] = 128
      i += 1
    end

    # Remove the cached lump.
    CDoom.z_free(sfx)

    # Preserve padded length.
    len.value = paddedsize

    # Return allocated padded data
    return (paddedsfx + 8).as(Void*)
  end

  @@sound_mutex = SpinLock.new
  @@handlenums : UInt16 = 0

  #
  # This function adds a sound to the
  #  list of currently active sounds,
  #  which is maintained as a given number
  #  (eight, usually) of internal channels.
  # Returns a handle.
  #
  def self.addsfx(sfxid : Int32, volume : Int32, step : Int32, seperation : Int32) : Int32
    rc = -1
    @@sound_mutex.synchronize do
      oldest = CDoom.gametic
      oldestnum = 0

      # Chainsaw troubles.
      # Play these sound effects only one at a time.
      if sfxid == CDoom::Sfxenum::SFX_sawup.value ||
         sfxid == CDoom::Sfxenum::SFX_sawidl.value ||
         sfxid == CDoom::Sfxenum::SFX_sawful.value ||
         sfxid == CDoom::Sfxenum::SFX_sawhit.value ||
         sfxid == CDoom::Sfxenum::SFX_stnmov.value ||
         sfxid == CDoom::Sfxenum::SFX_pistol.value
        # Loop all channels, check.
        CDoom::NUM_CHANNELS.times do |i|
          # Active, and using the same SFX?
          if !CDoom.channels[i].null? && CDoom.channelids[i] == sfxid
            # Reset.
            CDoom.channels[i] = Pointer(UInt8).null
            # We are sure that iff,
            #  there will only be one
            break
          end
        end
      end

      i = 0
      # Loop all channels to find oldest SFX.
      while i < CDoom::NUM_CHANNELS && !CDoom.channels[i].null?
        if CDoom.channelstart[i] < oldest
          oldestnum = i
          oldest = CDoom.channelstart[i]
        end
        i += 1
      end

      # Tales from the cryptic.
      # If we found a channel, fine.
      # If not, we simply overwrite the first one, 0.
      # Probably only happens at startup.
      slot = i
      slot = oldestnum if i == CDoom::NUM_CHANNELS

      # Okay, in the less recent channel,
      #  we will handle the new SFX.
      # Set pointer to raw data.
      CDoom.channels[slot] = (CDoom.s_sfx + sfxid).value.data.as(UInt8*)
      # Set pointer to end of raw data.
      CDoom.channelsend[slot] = CDoom.channels[slot] + CDoom.lengths[sfxid]

      # Reset current handle number, limited to 0..100.
      @@handlenums = 100 if @@handlenums == 0

      # Assign current handle number.
      # Preserved so sounds could be stopped (unused).
      CDoom.channelhandles[slot] = @@handlenums
      rc = @@handlenums
      @@handlenums += 1

      # Set stepping???
      # Kinda getting the impression this is never used.
      CDoom.channelstep[slot] = step.to_u32
      # ???
      CDoom.channelstepremainder[slot] = 0
      # Should be gametic, I presume.
      CDoom.channelstart[slot] = CDoom.gametic

      # Seperation, that is, orientation/stereo.
      #  range is: 1 - 256
      seperation += 1

      # Per left/right channel.
      #  x^2 seperation,
      #  adjust volume properly.
      leftvol = volume - ((volume * seperation * seperation) >> 16)
      seperation = seperation - 257
      rightvol = volume - ((volume * seperation * seperation) >> 16)

      # Sanity check, clamp volume.
      CDoom.i_error("Error: rightvol out of bounds") if rightvol < 0 || rightvol > 127
      CDoom.i_error("Error: leftvol out of bounds") if leftvol < 0 || leftvol > 127

      # Get the proper lookup table piece
      #  for this volume level???
      CDoom.channelleftvol_lookup[slot] = CDoom.vol_lookup.to_unsafe + leftvol*256
      CDoom.channelrightvol_lookup[slot] = CDoom.vol_lookup.to_unsafe + rightvol*256

      # Preserve sound SFX id,
      #  e.g. for avoiding duplicates of chainsaw.
      CDoom.channelids[slot] = sfxid
    end

    # You tell me.
    return rc.to_i32
  end

  #
  # Initializes sound stuff, including volume
  # Sets channels, SFX and music volume,
  #  allocates channel buffer, sets S_sfx lookup.
  #
  def self.s_init(sfx_volume : LibC::Int, music_volume : LibC::Int)
    # Whatever these did with DMX, these are rather dummies now. [ds] or are they...
    CDoom.i_set_channels

    @@snd_sfx_volume = sfx_volume
    # No music with Linux - another dummy. [ds] this didn't age well.
    CDoom.s_set_music_volume(music_volume)

    # Allocating the internal channels for mixing
    # (the maximum numer of sounds rendered
    # simultaneously) within zone memory.
    CDoom.channels_s_sound =
      CDoom.z_malloc(CDoom.num_channels * sizeof(CDoom::Channel), CDoom::PU_STATIC, Pointer(Void).null).as(CDoom::Channel*)

    # Free all channels for use
    CDoom.num_channels.times do |i|
      (CDoom.channels_s_sound + i).value.sfxinfo = Pointer(CDoom::Sfxinfo).null
    end

    # no sounds are playing, and they are not mus_paused
    CDoom.mus_paused = 0

    # Note that sounds have not been cached (yet)
    i = 1
    while i < CDoom::Sfxenum::NUMSFX.value
      (CDoom.s_sfx + i).value.lumpnum = -1
      (CDoom.s_sfx + i).value.usefulness = -1
      i += 1
    end
  end

  @@regmus = [
    # Song - Who? - Where?

    CDoom::Musicenum::MUS_e3m4, # American        e4m1
    CDoom::Musicenum::MUS_e3m2, # Romero        e4m2
    CDoom::Musicenum::MUS_e3m3, # Shawn        e4m3
    CDoom::Musicenum::MUS_e1m5, # American        e4m4
    CDoom::Musicenum::MUS_e2m7, # Tim         e4m5
    CDoom::Musicenum::MUS_e2m4, # Romero        e4m6
    CDoom::Musicenum::MUS_e2m6, # J.Anderson        e4m7 CHIRON.WAD
    CDoom::Musicenum::MUS_e2m5, # Shawn        e4m8
    CDoom::Musicenum::MUS_e1m9, # Tim                e4m9
  ]

  #
  # Per level startup code.
  # Kills playing sounds at start of level,
  #  determines music if any, changes music.
  #
  def self.s_start
    # kill all playing sounds at start of level
    #  (trust me - a good idea)
    CDoom.num_channels.times do |cnum|
      CDoom.s_stop_channel(cnum) unless CDoom.channels_s_sound[cnum].sfxinfo.null?
    end

    # start new music for the level
    CDoom.mus_paused = 0

    if CDoom.gamemode == CDoom::GameMode::Commercial
      mnum = CDoom::Musicenum::MUS_runnin.value + CDoom.gamemap - 1
    else
      if CDoom.gameepisode < 4
        mnum = CDoom::Musicenum::MUS_e1m1.value + (CDoom.gameepisode - 1) * 9 + CDoom.gamemap - 1
      else
        mnum = @@regmus[CDoom.gamemap - 1].value
      end
    end

    CDoom.s_change_music(mnum, 1)

    CDoom.nextcleanup = 15
  end

  def self.s_start_sound_at_volume(origin_p : Void*, sfx_id : LibC::Int, volume : LibC::Int)
    origin = origin_p.as(CDoom::Mobj*)

    # check for bogus sound #
    if sfx_id < 1 || sfx_id > CDoom::Sfxenum::NUMSFX.value
      CDoom.i_error("Error: Bad sfx #: #{sfx_id}")
    end

    sfx = CDoom.s_sfx + sfx_id

    # Initialize sound parameters
    unless sfx.value.link.null?
      pitch = sfx.value.pitch
      priority = sfx.value.priority
      volume += sfx.value.volume

      return if volume < 1

      volume = 15 if volume > 15
    else
      pitch = CDoom::NORM_PITCH
      priority = CDoom::NORM_PRIORITY
    end

    # Check to see if it is audible,
    #  and if not, modify the params
    sep = CDoom::NORM_SEP
    if !origin.null? && origin != @@players[CDoom.consoleplayer].mo
      rc = CDoom.s_adjust_sound_params(@@players[CDoom.consoleplayer].mo,
        origin,
        pointerof(volume),
        pointerof(sep),
        pointerof(pitch))

      if origin.value.x == @@players[CDoom.consoleplayer].mo.value.x &&
         origin.value.y == @@players[CDoom.consoleplayer].mo.value.y
        sep = CDoom::NORM_SEP
      end

      return if rc == 0
    end

    # hacks to vary the sfx pitches
    if sfx_id >= CDoom::Sfxenum::SFX_sawup.value &&
       sfx_id <= CDoom::Sfxenum::SFX_sawhit.value
      pitch += 8 - (CDoom.m_random & 15)

      if pitch < 0
        pitch = 0
      elsif pitch > 255
        pitch = 255
      end
    elsif sfx_id != CDoom::Sfxenum::SFX_itemup.value &&
          sfx_id != CDoom::Sfxenum::SFX_tink.value
      pitch += 16 - (CDoom.m_random & 31)

      if pitch < 0
        pitch = 0
      elsif pitch > 255
        pitch = 255
      end
    end

    # kill old sound
    CDoom.s_stop_sound(origin)

    # try to find a channel
    cnum = CDoom.s_get_channel(origin, sfx)

    return if cnum < 0

    #
    # This is supposed to handle the loading/caching.
    # For some odd reason, the caching is done nearly
    #  each time the sound is needed?
    #

    # get lumpnum if necessary
    sfx.value.lumpnum = CDoom.i_get_sfx_lump_num(sfx) if sfx.value.lumpnum < 0

    # increase the usefulness
    if sfx.value.usefulness < 0
      sfx.value.usefulness = 1
    else
      sfx.value.usefulness = sfx.value.usefulness + 1
    end

    # Assigns the handle to one of the channels in the
    #  mix/output buffer.
    (CDoom.channels_s_sound + cnum).value.handle = CDoom.i_start_sound(sfx_id,
      volume,
      sep,
      pitch,
      priority)
  end

  def self.s_start_sound(origin : Void*, sfx_id : LibC::Int)
    Doocr.s_start_sound_at_volume(origin, sfx_id, 15)
  end

  def self.s_stop_sound(origin : Void*)
    CDoom.num_channels.times do |cnum|
      if !CDoom.channels_s_sound[cnum].sfxinfo.null? && CDoom.channels_s_sound[cnum].origin == origin
        CDoom.s_stop_channel(cnum)
        break
      end
    end
  end

  #
  # Stop and resume music, during game PAUSE.
  #
  def self.s_pause_sound
    if !CDoom.mus_playing_s_sound.null? && CDoom.mus_paused == 0
      CDoom.i_pause_song(CDoom.mus_playing_s_sound.value.handle)
      CDoom.mus_paused = 1
    end
  end

  def self.s_resume_sound
    if !CDoom.mus_playing_s_sound.null? && CDoom.mus_paused != 0
      CDoom.i_resume_song(CDoom.mus_playing_s_sound.value.handle)
      CDoom.mus_paused = 0
    end
  end

  #
  # Updates music & sounds
  #
  def self.s_update_sounds(listener_p : Void*)
    listener = listener_p.as(CDoom::Mobj*)

    CDoom.num_channels.times do |cnum|
      c = CDoom.channels_s_sound + cnum
      sfx = c.value.sfxinfo

      unless c.value.sfxinfo.null?
        if CDoom.i_sound_is_playing(c.value.handle) != 0
          # initialize parameters
          volume = 15
          pitch = CDoom::NORM_PITCH
          sep = CDoom::NORM_SEP

          unless sfx.value.link.null?
            pitch = sfx.value.pitch
            volume += sfx.value.volume
            if volume < 1
              CDoom.s_stop_channel(cnum)
              next
            elsif volume > 15
              volume = 15
            end
          end

          # check non-local sounds for distance clipping
          #  or modify their params
          if !c.value.origin.null? && listener_p != c.value.origin
            audible = CDoom.s_adjust_sound_params(listener,
              c.value.origin.as(CDoom::Mobj*),
              pointerof(volume),
              pointerof(sep),
              pointerof(pitch))

            if audible == 0
              CDoom.s_stop_channel(cnum)
            else
              CDoom.i_update_sound_params(c.value.handle, volume, sep, pitch)
            end
          end
        else
          # if channel is allocated but sound has stopped,
          #  free it
          CDoom.s_stop_channel(cnum)
        end
      end
    end
  end

  def self.s_set_music_volume(volume : LibC::Int)
    if volume < 0 || volume > 127
      CDoom.i_error("Error: Attempt to set music volume at #{volume}")
    end

    CDoom.snd_music_volume = volume
    CDoom.i_set_music_volume(volume)
  end

  #
  # Starts some music with the music id found in sounds.h.
  #
  def self.s_start_music(m_id : LibC::Int)
    CDoom.s_change_music(m_id, 0)
  end

  def self.s_change_music(musicnum : LibC::Int, looping : LibC::Int)
    music = CDoom.s_music + musicnum

    if musicnum <= CDoom::Musicenum::MUS_None.value ||
       musicnum >= CDoom::Musicenum::NUMMUSIC.value
      CDoom.i_error("Error: Bad music number #{musicnum}")
    end

    return if CDoom.mus_playing_s_sound == music

    # shutdown old music
    CDoom.s_stop_music

    # get lumpnum if neccessary
    if music.value.lumpnum == 0
      music.value.lumpnum = CDoom.w_get_num_for_name("d_#{String.new(music.value.name)}")
    end
    # load & register it
    music.value.data = CDoom.w_cache_lump_num(music.value.lumpnum, CDoom::PU_MUSIC)
    music.value.handle = CDoom.i_register_song(music.value.data)
    # play it
    CDoom.mus_playing_s_sound = music

    CDoom.i_play_song(music.value.handle, looping)
  end

  def self.s_stop_music
    unless CDoom.mus_playing_s_sound.null?
      if CDoom.mus_paused != 0
        CDoom.i_resume_song(CDoom.mus_playing_s_sound.value.handle)
      end

      CDoom.i_stop_song(CDoom.mus_playing_s_sound.value.handle)
      CDoom.i_unregister_song(CDoom.mus_playing_s_sound.value.handle)
      z_change_tag(CDoom.mus_playing_s_sound.value.data, CDoom::PU_CACHE)

      CDoom.mus_playing_s_sound.value.data = Pointer(Void).null
      CDoom.mus_playing_s_sound = Pointer(CDoom::Musicinfo).null
    end
  end

  def self.s_stop_channel(cnum : LibC::Int)
    c = CDoom.channels_s_sound + cnum

    unless c.value.sfxinfo.null?
      # stop the sound playing
      CDoom.i_stop_sound(c.value.handle) if CDoom.i_sound_is_playing(c.value.handle) != 0

      # check to see
      #  if other channels are playing the sound
      i = 0
      while i < CDoom.num_channels
        if cnum != i &&
           c.value.sfxinfo == CDoom.channels_s_sound[i].sfxinfo
          break
        end

        i += 1
      end

      # degrade usefulness of sound data
      c.value.sfxinfo.value.usefulness = c.value.sfxinfo.value.usefulness - 1

      c.value.sfxinfo = Pointer(CDoom::Sfxinfo).null
    end
  end

  #
  # Changes volume, stereo-separation, and pitch variables
  #  from the norm of a sound effect to be played.
  # If the sound is not audible, returns a 0.
  # Otherwise, modifies parameters and returns 1.
  #
  def self.s_adjust_sound_params(listener : CDoom::Mobj*, source : CDoom::Mobj*, vol : LibC::Int*, sep : LibC::Int*, pitch : LibC::Int*) : LibC::Int
    # calculate the distance to sound origin
    #  and clip it if necessary
    adx = doom_abs(listener.value.x - source.value.x)
    ady = doom_abs(listener.value.y - source.value.y)

    # From _GG1_ p.428. Appox. eucledian distance fast.
    approx_dist = adx + ady - ((adx < ady ? adx : ady) >> 1)

    return 0 if CDoom.gamemap != 8 &&
                approx_dist > CDoom::S_CLIPPING_DIST

    # angle of source to listener
    angle = CDoom.r_point_to_angle2(listener.value.x,
      listener.value.y,
      source.value.x,
      source.value.y)

    if angle > listener.value.angle
      angle = angle &- listener.value.angle
    else
      angle = angle &+ (0xffffffff &- listener.value.angle)
    end

    angle >>= CDoom::ANGLETOFINESHIFT

    # stereo separation
    sep.value = 128 - (CDoom.fixed_mul(CDoom::S_STEREO_SWING, @@finesine[angle]) >> FRACBITS)

    # volume calculation
    if approx_dist < CDoom::S_CLOSE_DIST
      vol.value = 15
    elsif CDoom.gamemap == 8
      vol.value = 15
    else
      # distance effect
      vol.value = (15 *
                   ((CDoom::S_CLIPPING_DIST - approx_dist) >> FRACBITS)) // CDoom::S_ATTENUATOR
    end

    return (vol.value > 0).to_unsafe
  end

  #
  # If none available, return -1.  Otherwise channel #.
  #
  def self.s_get_channel(origin : Void*, sfxinfo : CDoom::Sfxinfo*) : LibC::Int
    # channel number to use
    cnum = 0

    # Find an open channel
    while cnum < CDoom.num_channels
      if CDoom.channels_s_sound[cnum].sfxinfo.null?
        break
      elsif !origin.null? && CDoom.channels_s_sound[cnum].origin == origin
        CDoom.s_stop_channel(cnum)
        break
      end

      cnum += 1
    end

    # None available
    if cnum == CDoom.num_channels
      # Look for lower priority
      cnum = 0
      while cnum < CDoom.num_channels
        if CDoom.channels_s_sound[cnum].sfxinfo.value.priority >= sfxinfo.value.priority
          break
        end

        cnum += 1
      end

      if cnum == CDoom.num_channels
        # FUCK!  No lower priority.  Sorry, Charlie.
        return -1
      else
        # Otherwise, kick out lower priority
        CDoom.s_stop_channel(cnum)
      end
    end

    c = CDoom.channels_s_sound + cnum

    # channel is decided to be cnum.
    c.value.sfxinfo = sfxinfo
    c.value.origin = origin

    return cnum
  end
end
