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
      Doocr.reloadname = String.new(filename)
      Doocr.reloadlump = Doocr.numlumps
    end

    path = String.new(filename)
    begin
      handle = File.open(path, "rb")
    rescue
      puts " couldn't open #{path}"
      return
    end

    puts " adding #{String.new(filename)}"
    startlump = Doocr.numlumps

    header = Wadinfo.new
    singleinfo = CDoom::Filelump.new

    if CDoom.doom_strcasecmp(filename + CDoom.doom_strlen(filename) - 3, "wad") != 0
      # single lump file
      fileinfo = pointerof(singleinfo)
      singleinfo.filepos = 0
      handle.seek(0, IO::Seek::End)
      singleinfo.size = handle.pos.to_i32
      handle.seek(0, IO::Seek::Set)
      CDoom.extract_file_base(filename, singleinfo.name)
      Doocr.numlumps += 1
    else
      # WAD file
      header_data = Bytes.new(12)
      handle.read_fully(header_data)
      header.read(header_data.to_unsafe)
      if !header.identification.starts_with?("IWAD")
        # Homebrew levels?
        if !header.identification.starts_with?("PWAD")
          CDoom.i_error("Error: Wad file #{filename} doesn't have IWAD or PWAD id")
        end

        # ???Doocr.modifiedgame = 1
      end
      header.numlumps = header.numlumps
      header.infotableofs = header.infotableofs
      length = header.numlumps * sizeof(CDoom::Filelump)
      fileinfo = GC.malloc(length).as(CDoom::Filelump*)
      allocated = fileinfo
      handle.seek(header.infotableofs, IO::Seek::Set)
      handle.read_fully(Slice.new(fileinfo.as(UInt8*), length))
      Doocr.numlumps += header.numlumps
    end

    # Fill in lumpinfo
    storehandle = Doocr.reloadname.empty? ? handle : nil

    i = startlump
    while i < Doocr.numlumps.to_u32!
      @@lumpinfo << Lumpinfo.new(
        name: String.new(fileinfo.value.name.to_unsafe, 8),
        handle: storehandle,
        position: fileinfo.value.filepos,
        size: fileinfo.value.size
      )
      i += 1
      fileinfo += 1
    end

    handle.close unless Doocr.reloadname.empty?

    GC.free(allocated.as(Void*)) unless allocated.null?
  end

  def self.w_merge_file(filename : String)
    allocated = Pointer(CDoom::Filelump).null

    # open the file and add to directory

    # handle reload indicator.
    if filename[0] == '~'
      filename == 1
      Doocr.reloadname = filename
      Doocr.reloadlump = Doocr.numlumps
    end

    begin
      file = File.open(filename, "rb")
    rescue
      puts " couldn't open #{filename}"
      return
    end

    puts " adding #{filename}"
    startlump = Doocr.numlumps
    num_merge_lumps = 0

    header = Wadinfo.new
    singleinfo = CDoom::Filelump.new
    if filename[-3..-1].downcase.compare("wad") != 0
      # single lump file
      fileinfo = pointerof(singleinfo)
      singleinfo.filepos = 0
      singleinfo.size = file.size
      CDoom.extract_file_base(filename, singleinfo.name)
      num_merge_lumps += 1
    else
      # WAD file
      header_data = Bytes.new(12)
      file.read(header_data)
      header.read(header_data.to_unsafe)
      if !header.identification.starts_with?("IWAD")
        # Homebrew levels?
        if !header.identification.starts_with?("PWAD")
          CDoom.i_error("Error: Wad file #{filename} doesn't have IWAD or PWAD id")
        end

        # ???Doocr.modifiedgame = 1
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
        lump_num = Doocr.numlumps
      else
        # Find lump
        lump_num = 0
        Doocr.numlumps.times do |j|
          if @@lumpinfo[j].name.downcase.delete('\0') == name_str
            break
          end
          lump_num += 1
        end
      end

      if lump_num == Doocr.numlumps
        # Not been loaded. Initialize lump
        Doocr.numlumps += ismap ? Doocr::ML_BLOCKMAP + 1 : 1

        (ismap ? Doocr::ML_BLOCKMAP + 1 : 1).times do |i|
          @@lumpinfo << Lumpinfo.new
        end
        startlump += 1
      end
      # Set the lump
      if ismap
        (Doocr::ML_BLOCKMAP + 1).times do |m|
          lump = @@lumpinfo[lump_num + m]
          lump.handle = Doocr.reloadname.empty? ? file : nil
          lump.position = fileinfo[mlump].filepos
          lump.size = fileinfo[mlump].size
          lump.name = String.new((fileinfo + mlump).value.name.to_unsafe, 8)
          mlump += 1
        end
      else
        lump = @@lumpinfo[lump_num]
        lump.handle = Doocr.reloadname.empty? ? file : nil
        lump.position = fileinfo[mlump].filepos
        lump.size = fileinfo[mlump].size
        lump.name = String.new((fileinfo + mlump).value.name.to_unsafe, 8)
        mlump += 1
      end
    end

    file.close

    GC.free(allocated.as(Void*)) unless allocated.null?
  end

  #
  # Flushes any of the reloadable lumps in memory
  #  and reloads the directory.
  #
  def self.w_reload
    return if Doocr.reloadname.empty?

    begin
      handle = File.open(Doocr.reloadname, "rb")
    rescue
      CDoom.i_error("Error: w_reload: couldn't open #{Doocr.reloadname}")
    end

    header = Wadinfo.new
    header_data = Bytes.new(12)
    handle.not_nil!.read_fully(header_data)
    header.read(header_data.to_unsafe)
    lumpcount = header.numlumps
    header.infotableofs = header.infotableofs
    length = lumpcount * sizeof(CDoom::Filelump)
    fileinfo = GC.malloc(length).as(CDoom::Filelump*)
    handle.not_nil!.seek(header.infotableofs, IO::Seek::Set)
    handle.not_nil!.read_fully(Slice.new(fileinfo.as(UInt8*), length))

    i = Doocr.reloadlump
    while i < (Doocr.reloadlump + lumpcount).to_u32!
      CDoom.z_free(Doocr.lumpcache[i]) unless Doocr.lumpcache[i].null?

      @@lumpinfo[i].position = fileinfo.value.filepos
      @@lumpinfo[i].size = fileinfo.value.size

      i += 1
      fileinfo += 1
    end

    handle.not_nil!.close

    GC.free(fileinfo.as(Void*))
  end

  def self.w_merge_multiple_files(filenames : Array(String))
    # will be realloced as lumps are added

    filenames.each { |fn| w_merge_file(fn) }

    CDoom.i_error("Error: w_merge_multiple_files: no files found") if Doocr.numlumps == 0

    # set up caching
    Doocr.lumpcache.clear
    Doocr.numlumps.times { Doocr.lumpcache << Pointer(Void).null }
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
    Doocr.numlumps = 0

    # will be realloced as lumps are added
    @@lumpinfo.clear

    until filenames.value.null?
      CDoom.w_add_file(filenames.value)
      filenames += 1
    end

    CDoom.i_error("Error: w_init_multiple_files: no files found") if Doocr.numlumps == 0

    # set up caching
    Doocr.lumpcache.clear
    Doocr.numlumps.times { Doocr.lumpcache << Pointer(Void).null }

    if w_check_num_for_name("STDISK".to_unsafe) != -1
      @@loading_patch = w_cache_lump_name("STDISK".to_unsafe, Doocr::PU_STATIC).as(CDoom::Patch*)
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
    name8 = Name8.new
    CDoom.doom_strncpy(name8.s.to_unsafe, name, 8)

    # in case the name was a fill 8 chars
    name8.s[8] = 0

    # case insensitive
    CDoom.doom_strupr(name8.s.to_unsafe)

    v1 = name8.x[0]
    v2 = name8.x[1]

    # scan backwards so patch lump files take precedence
    (Doocr.numlumps - 1).downto(0) do |i|
      lump = @@lumpinfo[i]
      if lump.name.to_unsafe.as(Int32*).value == v1 &&
         (lump.name.to_unsafe + 4).as(Int32*).value == v2
        return i
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
    if lump >= Doocr.numlumps
      CDoom.i_error("Error: w_lump_length: #{lump} >= numlumps")
    end

    return @@lumpinfo[lump].size
  end

  #
  # Loads the lump into the given buffer,
  #  which must be >= w_lump_length().
  #
  def self.w_read_lump(lump : LibC::Int, dest : Void*)
    if lump >= Doocr.numlumps
      CDoom.i_error("Error: w_read_lump: #{lump} >= numlumps")
    end

    l = @@lumpinfo[lump]

    handle = l.handle
    if handle.nil?
      # reloadable file, so use open / read / close
      begin
        handle = File.open(Doocr.reloadname, "rb")
      rescue
        CDoom.i_error("Error: w_read_lump: couldn't open #{Doocr.reloadname}")
      end
    end

    handle.not_nil!.seek(l.position, IO::Seek::Set)
    c = handle.not_nil!.read(Slice.new(dest.as(UInt8*), l.size))

    if c < l.size
      CDoom.i_error("Error: w_read_lump: only read #{c} of #{l.size} on lump #{lump}")
    end

    handle.not_nil!.close if l.handle.nil?
  end

  @@do_loading_disk = false
  @@loading_disk_shown = false

  def self.w_cache_lump_num(lump : LibC::Int, tag : LibC::Int) : Void*
    if lump.to_u32! >= Doocr.numlumps.to_u32!
      CDoom.i_error("Error: w_cache_lump_num #{lump} >= numlumps")
    end

    if Doocr.lumpcache[lump].null?
      # read the lump in
      @@do_loading_disk = true

      ptr = CDoom.z_malloc(CDoom.w_lump_length(lump), tag, Doocr.lumpcache.to_unsafe + lump).as(UInt8*)
      CDoom.w_read_lump(lump, Doocr.lumpcache[lump])
    else
      z_change_tag(Doocr.lumpcache[lump], tag)
    end

    return Doocr.lumpcache[lump]
  end

  def self.w_cache_lump_name(name : LibC::Char*, tag : LibC::Int) : Void*
    return CDoom.w_cache_lump_num(CDoom.w_get_num_for_name(name), tag)
  end
end
