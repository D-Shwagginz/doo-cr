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

module Doocr
  class Wad
    getter names : Array(String) = [] of String
    getter lump_infos : Array(LumpInfo) = [] of LumpInfo
    getter game_version : GameVersion = GameVersion.new(0)
    getter game_mode : GameMode = GameMode.new(0)
    getter mission_pack : MissionPack = MissionPack.new(0)
    @streams : Array(File) = [] of File

    def initialize(*file_names : String)
      initialize(file_names.to_a)
    end

    def initialize(file_names : Array(String))
      begin
        print("Open WAD files: ")

        @names = [] of String
        @streams = [] of File
        @lump_infos = [] of LumpInfo

        file_names.each do |filename|
          addfile(filename)
        end

        @game_mode = get_game_mode(@names)
        @mission_pack = get_mission_pack(@names)
        @game_version = get_game_version(@names)

        s = ""
        file_names.select { |x| Path[x].basename }.each do |v|
          s = s + v + ", "
        end
        s = s.rchop

        puts("OK ( #{s} )")
      rescue e
        puts("Failed")
        raise e
      end
    end

    private def addfile(filename : String)
      @names << Path[filename].stem.downcase

      stream = File.new(filename, "r")
      @streams << stream

      data = Bytes.new(12)
      if stream.read(data) != data.size
        raise "Failed to read the WAD file."
      end

      identification = String.new(data[0, 4])
      lump_count = IO::ByteFormat::LittleEndian.decode(Int32, data[4, 4])
      lump_info_table_offset = IO::ByteFormat::LittleEndian.decode(Int32, data[8, 4])
      if identification != "IWAD" && identification != "PWAD"
        raise "The file is not a WAD file."
      end

      data = Bytes.new(LumpInfo.datasize * lump_count)
      stream.seek(lump_info_table_offset, IO::Seek::Set)
      if stream.read(data) != data.size
        raise "Failed to read the WAD file."
      end

      lump_count.times do |i|
        offset = LumpInfo.datasize * i
        lumpinfo = LumpInfo.new(
          String.new(data[offset + 8, 8]).delete('\0').upcase.strip,
          stream,
          IO::ByteFormat::LittleEndian.decode(Int32, data[offset, 4]),
          IO::ByteFormat::LittleEndian.decode(Int32, data[offset + 4, 4])
        )
        @lump_infos << lumpinfo
      end
    end

    def get_lump_number(name : String) : Int
      i = @lump_infos.size - 1
      while i >= 0
        if @lump_infos[i].name.delete('\0').upcase.strip == name.delete('\0').upcase.strip
          return i
        end
        i -= 1
      end

      return -1
    end

    def get_lump_size(number : Int) : Int
      return @lump_infos[number].size
    end

    def read_lump(number : Int) : Bytes
      lumpinfo = @lump_infos[number]

      data = Bytes.new(lumpinfo.size)

      lumpinfo.stream.seek(lumpinfo.position, IO::Seek::Set)
      read = lumpinfo.stream.read(data)
      if read != lumpinfo.size
        raise "Failed to read the lump #{number}."
      end

      return data
    end

    def read_lump(name : String) : Bytes
      lumpnumber = get_lump_number(name)

      if lumpnumber == -1
        raise "The lump '#{name}' was not found."
      end

      return read_lump(lumpnumber)
    end

    def finalize
      puts("Close WAD files.")

      @streams.each do |stream|
        stream.close
      end

      @streams.clear
    end

    private def get_game_version(names : Array(String))
      names.each do |name|
        case name.downcase
        when "doom2", "freedoom2"
          return GameVersion::Version109
        when "doom", "doom1", "freedoom1"
          return GameVersion::Ultimate
        when "plutonia", "tnt"
          return GameVersion::Final
        end
      end

      return GameVersion::Version109
    end

    private def get_game_mode(names : Array(String))
      names.each do |name|
        case name.downcase
        when "doom2", "plutonia", "tnt", "freedoom2"
          return GameMode::Commercial
        when "doom", "freedoom1"
          return GameMode::Retail
        when "doom1"
          return GameMode::Shareware
        end
      end

      return GameMode::Indetermined
    end

    private def get_mission_pack(names : Array(String))
      names.each do |name|
        case name.downcase
        when "plutonia"
          return MissionPack::Plutonia
        when "tnt"
          return MissionPack::Tnt
        end
      end

      return MissionPack::Doom2
    end
  end
end
