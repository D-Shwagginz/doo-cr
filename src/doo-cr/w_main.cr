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
# ==> Wad and lump handling

module Doocr
  #
  # LUMP BASED ROUTINES.
  #

  #
  # All files are optional, but at least one file must be
  #  found (PWAD, if all required lumps are present).
  # Files with a .wad extension are wadlink files
  #  with multiple lumps.
  # Other files are single lumps with the base filename
  #  for the lump name.
  #
  # If filename starts with a tilde, the file is handled
  #  specially to allow map reloads.
  # But: the reload feature is a fragile hack...
  #
  @@previous_realloc_size = 1

  def self.w_add_file(filename : LibC::Char*)
    allocated = Pointer(CDoom::Filelump).null

    # open the file and add to directory

    # handle reload indicator.
    if filename[0] == '~'.ord
      filename == 1
      CDoom.reloadname = filename
      CDoom.reloadlump = CDoom.numlumps
    end

    if (handle = doom_open(filename, "rb".to_unsafe)).null?
      puts " couldn't open #{String.new(filename)}"
      return
    end

    puts " adding #{String.new(filename)}"
    startlump = CDoom.numlumps

    header = CDoom::Wadinfo.new
    singleinfo = CDoom::Filelump.new

    if CDoom.doom_strcasecmp(filename + CDoom.doom_strlen(filename) - 3, "wad") != 0
      # single lump file
      fileinfo = pointerof(singleinfo)
      singleinfo.filepos = 0
      doom_seek(handle, 0, CDoom::DoomSeek::DOOM_SEEK_END)
      singleinfo.size = doom_tell(handle)
      doom_seek(handle, 0, CDoom::DoomSeek::DOOM_SEEK_SET)
      CDoom.extract_file_base(filename, singleinfo.name)
      CDoom.numlumps += 1
    else
      # WAD file
      doom_read(handle, pointerof(header).as(Void*), sizeof(typeof(header)))
      if CDoom.doom_strncmp(header.identification, "IWAD", 4) != 0
        # Homebrew levels?
        if CDoom.doom_strncmp(header.identification, "PWAD", 4) != 0
          CDoom.i_error("Error: Wad file #{filename} doesn't have IWAD or PWAD id")
        end

        # ???CDoom.modifiedgame = 1
      end
      header.numlumps = header.numlumps
      header.infotableofs = header.infotableofs
      length = header.numlumps * sizeof(CDoom::Filelump)
      fileinfo = GC.malloc(length).as(CDoom::Filelump*)
      allocated = fileinfo
      doom_seek(handle, header.infotableofs, CDoom::DoomSeek::DOOM_SEEK_SET)
      doom_read(handle, fileinfo.as(Void*), length)
      CDoom.numlumps += header.numlumps
    end

    # Fill in lumpinfo
    storehandle = !CDoom.reloadname.null? ? Pointer(Void).null : handle

    i = startlump
    while i < CDoom.numlumps.to_u32!
      @@lumpinfo << CDoom::Lumpinfo.new
      lump_p = @@lumpinfo.to_unsafe + i
      lump_p.value.handle = storehandle
      lump_p.value.position = fileinfo.value.filepos
      lump_p.value.size = fileinfo.value.size
      CDoom.doom_strncpy(lump_p.value.name, fileinfo.value.name, 8)
      i += 1
      fileinfo += 1
    end

    doom_close(handle) if !CDoom.reloadname.null?

    GC.free(allocated.as(Void*)) unless allocated.null?
  end

  def self.w_merge_file(filename : String)
    allocated = Pointer(CDoom::Filelump).null

    # open the file and add to directory

    # handle reload indicator.
    if filename[0] == '~'
      filename == 1
      CDoom.reloadname = filename
      CDoom.reloadlump = CDoom.numlumps
    end

    response = Channel({Bytes, Bool}).new
    @@io_jobs.send({filename, "rb", nil, response})
    data, ok = response.receive
    unless ok
      puts " couldn't open #{filename}"
      return
    end

    puts " adding #{filename}"
    startlump = CDoom.numlumps
    num_merge_lumps = 0

    header = CDoom::Wadinfo.new
    singleinfo = CDoom::Filelump.new
    file = IO::Memory.new(data)
    if filename[-3..-1].downcase.compare("wad") != 0
      # single lump file
      fileinfo = pointerof(singleinfo)
      singleinfo.filepos = 0
      singleinfo.size = file.size
      CDoom.extract_file_base(filename, singleinfo.name)
      num_merge_lumps += 1
    else
      # WAD file
      slice = Slice.new(pointerof(header).as(UInt8*), sizeof(typeof(header)))
      file.read(slice)
      if CDoom.doom_strncmp(header.identification, "IWAD", 4) != 0
        # Homebrew levels?
        if CDoom.doom_strncmp(header.identification, "PWAD", 4) != 0
          CDoom.i_error("Error: Wad file #{filename} doesn't have IWAD or PWAD id")
        end

        # ???CDoom.modifiedgame = 1
      end
      length = header.numlumps * sizeof(CDoom::Filelump)
      fileinfo = GC.malloc(length).as(CDoom::Filelump*)
      allocated = fileinfo
      file.seek(header.infotableofs, IO::Seek::Set)
      slice = Slice.new(fileinfo.as(UInt8*), length)
      file.read(slice)
      num_merge_lumps += header.numlumps
    end

    # Find files in lump and overwrite them
    # Starts from the beginning instead of the end to truly add as an iwad merging
    # Adds the lump if it isn't already found (same as -file)
    mlump = 0
    while mlump < num_merge_lumps
      name_str = String.new((fileinfo + mlump).value.name.to_unsafe, 8).downcase.delete('\0')
      ismap = (name_str[0]? == 'e' && name_str[2]? == 'm') || name_str.starts_with?("map")

      if name_str == "s_start" || name_str == "ss_start" ||
         name_str == "s_end" || name_str == "ss_end" || # Don't overwrite sprite or lump stuff
         name_str == "f_start" || name_str == "ff_start" ||
         name_str == "f_end" || name_str == "ff_end"
        lump_num = CDoom.numlumps
      else
        # Find lump
        lump_num = 0
        CDoom.numlumps.times do |j|
          if String.new(@@lumpinfo[j].name.to_unsafe, 8).downcase.delete('\0') == name_str
            break
          end
          lump_num += 1
        end
      end

      if lump_num == CDoom.numlumps
        # Not been loaded. Initialize lump
        CDoom.numlumps += ismap ? CDoom::ML_BLOCKMAP + 1 : 1

        (ismap ? CDoom::ML_BLOCKMAP + 1 : 1).times do |i|
          @@lumpinfo << CDoom::Lumpinfo.new
        end
        lump_p = @@lumpinfo.to_unsafe + startlump

        startlump += 1
      else
        # Lump exists
        lump_p = @@lumpinfo.to_unsafe + lump_num
      end
      # Set the lump
      if ismap
        (CDoom::ML_BLOCKMAP + 1).times do |m|
          lump_p.value.handle = !CDoom.reloadname.null? ? Pointer(Void).null : Box.box({filename, file, false})
          lump_p.value.position = fileinfo[mlump].filepos
          lump_p.value.size = fileinfo[mlump].size
          CDoom.doom_strncpy(lump_p.value.name, (fileinfo + mlump).value.name, 8)
          lump_p += 1
          mlump += 1
        end
      else
        lump_p.value.handle = !CDoom.reloadname.null? ? Pointer(Void).null : Box.box({filename, file, false})
        lump_p.value.position = fileinfo[mlump].filepos
        lump_p.value.size = fileinfo[mlump].size
        CDoom.doom_strncpy(lump_p.value.name, (fileinfo + mlump).value.name, 8)
        mlump += 1
      end
    end

    file.close if !CDoom.reloadname.null?

    GC.free(allocated.as(Void*)) unless allocated.null?
  end

  #
  # Flushes any of the reloadable lumps in memory
  #  and reloads the directory.
  #
  def self.w_reload
    return if CDoom.reloadname.null?

    if (handle = doom_open(CDoom.reloadname, "rb".to_unsafe)) == 0
      CDoom.i_error("Error: w_reload: couldn't open #{CDoom.reloadname}")
    end

    header = CDoom::Wadinfo.new

    doom_read(handle, pointerof(header).as(Void*), sizeof(typeof(header)))
    lumpcount = header.numlumps
    header.infotableofs = header.infotableofs
    length = lumpcount * sizeof(CDoom::Filelump)
    fileinfo = GC.malloc(length).as(CDoom::Filelump*)
    doom_seek(handle, header.infotableofs, CDoom::DoomSeek::DOOM_SEEK_SET)
    doom_read(handle, fileinfo.as(Void*), length)

    # Fill in lumpinfo
    lump_p = @@lumpinfo.to_unsafe + CDoom.reloadlump

    i = CDoom.reloadlump
    while i < (CDoom.reloadlump + lumpcount).to_u32!
      CDoom.z_free(CDoom.lumpcache[i]) unless CDoom.lumpcache[i].null?

      lump_p.value.position = fileinfo.value.filepos
      lump_p.value.size = fileinfo.value.size

      i += 1
      lump_p += 1
      fileinfo += 1
    end

    doom_close(handle)

    GC.free(fileinfo.as(Void*))
  end

  def self.w_merge_multiple_files(filenames : Array(String))
    # will be realloced as lumps are added

    filenames.each { |fn| w_merge_file(fn) }

    CDoom.i_error("Error: w_merge_multiple_files: no files found") if CDoom.numlumps == 0

    # set up caching
    size = CDoom.numlumps * sizeof(Void*)
    CDoom.lumpcache = GC.malloc(size).as(Void**)

    CDoom.i_error("Error: Couldn't allocate lumpcache") if CDoom.lumpcache.null?

    CDoom.doom_memset(CDoom.lumpcache, 0, size)
  end

  #
  # Pass a null terminated list of files to use.
  # All files are optional, but at least one file
  #  must be found.
  # Files with a .wad extension are idlink files
  #  with multiple lumps.
  # Other files are single lumps with the base filename
  #  for the lump name.
  # Lump names can appear multiple times.
  # The name searcher looks backwards, so a later file
  #  does override all earlier ones.
  #
  def self.w_init_multiple_files(filenames : LibC::Char**)
    # open all the files, load headers, and count lumps
    CDoom.numlumps = 0

    # will be realloced as lumps are added
    @@lumpinfo.clear

    until filenames.value.null?
      CDoom.w_add_file(filenames.value)
      filenames += 1
    end

    CDoom.i_error("Error: w_init_multiple_files: no files found") if CDoom.numlumps == 0

    # set up caching
    size = CDoom.numlumps * sizeof(Void*)
    CDoom.lumpcache = GC.malloc(size).as(Void**)

    CDoom.i_error("Error: Couldn't allocate lumpcache") if CDoom.lumpcache.null?

    CDoom.doom_memset(CDoom.lumpcache, 0, size)

    if w_check_num_for_name("STDISK".to_unsafe) != -1
      @@loading_patch = w_cache_lump_name("STDISK".to_unsafe, CDoom::PU_STATIC).as(CDoom::Patch*)
    end
  end

  #
  # Just initialize from a single file.
  #
  def self.w_init_file(filename : LibC::Char*)
    names = Pointer(UInt8*).malloc(2)

    names[0] = filename
    names[1] = Pointer(UInt8).null
    CDoom.w_init_multiple_files(names)
  end

  #
  # Returns -1 if name not found.
  #
  def self.w_check_num_for_name(name : LibC::Char*) : LibC::Int
    # make the name into two integers for easy compares
    name8 = CDoom::Name8.new
    CDoom.doom_strncpy(name8.s, name, 8)

    # in case the name was a fill 8 chars
    name8.s[8] = 0

    # case insensitive
    CDoom.doom_strupr(name8.s)

    v1 = name8.x[0]
    v2 = name8.x[1]

    # scan backwards so patch lump files take precedence
    lump_p = @@lumpinfo.to_unsafe + CDoom.numlumps

    while lump_p != @@lumpinfo.to_unsafe
      lump_p -= 1
      if lump_p.value.name.to_unsafe.as(Int32*).value == v1 &&
         (lump_p.value.name.to_unsafe + 4).as(Int32*).value == v2
        return (lump_p - @@lumpinfo.to_unsafe).to_i32!
      end
    end

    # TFB. Not found.
    return -1
  end

  #
  # Calls w_check_num_for_name, but bombs out if not found.
  #
  def self.w_get_num_for_name(name : LibC::Char*) : LibC::Int
    i = CDoom.w_check_num_for_name(name)

    if i == -1
      if CDoom.doom_strcmp(name, "HELP2") == 0
        name = "HELP1".to_unsafe # Ultimate Doom EXE was modified to use this instead
        i = CDoom.w_check_num_for_name(name)
      end
      if i == -1
        CDoom.i_error("Error: w_get_num_for_name: #{String.new(name)} not found!")
      end
    end

    return i
  end

  #
  # Returns the buffer size needed to load the given lump.
  #
  def self.w_lump_length(lump : LibC::Int) : LibC::Int
    if lump >= CDoom.numlumps
      CDoom.i_error("Error: w_lump_length: #{lump} >= numlumps")
    end

    return @@lumpinfo[lump].size
  end

  #
  # Loads the lump into the given buffer,
  #  which must be >= w_lump_length().
  #
  def self.w_read_lump(lump : LibC::Int, dest : Void*)
    if lump >= CDoom.numlumps
      CDoom.i_error("Error: w_read_lump: #{lump} >= numlumps")
    end

    l = @@lumpinfo.to_unsafe + lump

    if l.value.handle.null?
      # reloadable file, so use open / read / close
      if (handle = doom_open(CDoom.reloadname, "rb".to_unsafe)) == 0
        CDoom.i_error("Error: w_read_lump: couldn't open #{CDoom.reloadname}")
      end
    else
      handle = l.value.handle
    end

    doom_seek(handle, l.value.position, CDoom::DoomSeek::DOOM_SEEK_SET)
    c = doom_read(handle, dest, l.value.size)

    if c < l.value.size
      CDoom.i_error("Error: w_read_lump: only read #{c} of #{l.value.size} on lump #{lump}")
    end

    doom_close(handle) if l.value.handle.null?
  end

  @@do_loading_disk = false
  @@loading_disk_shown = false

  def self.w_cache_lump_num(lump : LibC::Int, tag : LibC::Int) : Void*
    if lump.to_u32! >= CDoom.numlumps.to_u32!
      CDoom.i_error("Error: w_cache_lump_num #{lump} >= numlumps")
    end

    if CDoom.lumpcache[lump].null?
      # read the lump in
      @@do_loading_disk = true

      ptr = CDoom.z_malloc(CDoom.w_lump_length(lump), tag, CDoom.lumpcache + lump).as(CDoom::Byte*)
      CDoom.w_read_lump(lump, CDoom.lumpcache[lump])
    else
      z_change_tag(CDoom.lumpcache[lump], tag)
    end

    return CDoom.lumpcache[lump]
  end

  def self.w_cache_lump_name(name : LibC::Char*, tag : LibC::Int) : Void*
    return CDoom.w_cache_lump_num(CDoom.w_get_num_for_name(name), tag)
  end
end
