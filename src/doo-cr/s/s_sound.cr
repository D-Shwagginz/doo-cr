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
end
