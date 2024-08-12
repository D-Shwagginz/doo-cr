module Doocr
  module ConfigUtilities
    class_getter iwad_names : Array(String) = [
      "DOOM2.WAD",
      "PLUTONIA.WAD",
      "TNT.WAD",
      "DOOM.WAD",
      "DOOM1.WAD",
      "FREEDOOM2.WAD",
      "FREEDOOM1.WAD",
    ]

    def self.get_exe_directory : String
      return Path["__FILE__"].dirname
    end

    def self.get_config_path : String
      return Path.new(get_exe_directory(), "doo-cr.cfg")
    end

    def self.get_default_iwad_path : String
      exe_directory = get_exe_directory()
      @@iwad_names.each do |name|
        path = Path.new(exe_directory, name)
        return path if File.exists?(path)
      end

      current_directory = Dir.current
      @@iwad_names.each do |name|
        path = Path.new(current_directory, name)
        return path if File.exists?(path)
      end

      raise "No IWAD was found!"
    end

    def self.is_iwad(path : String) : Bool
      name = Path[path].basename.upcase
      return @@iwad_names.includes?(name)
    end

    def self.get_wad_paths(args : CommandLineArgs) : Array(String)
      wad_paths = [] of String

      if args.iwad.present
        wad_paths << args.iwad.value
      else
        wad_paths << ConfigUtilities.get_default_iwad_path
      end

      wad_paths << args.file.value if args.file.present

      return wad_paths
    end
  end
end
