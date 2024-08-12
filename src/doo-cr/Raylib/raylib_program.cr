module Doocr::Raylib
  def self.main
    puts(ApplicationInfo::TITLE)
    reader = Term::Reader.new

    begin
      quit_message : String = ""

      app = RaylibDoom.new(CommandLineArgs.new(ARGV))
      app.Run
      quit_message = app.quit_message
      app = nil

      if quit_message != ""
        puts(quit_message)
        puts("Press any key to exit.")
        key_down = false
        until key_down
          reader.on_key { |key, event| key_down = true }
        end
      end
    rescue e
      puts(e)
      puts("Press any key to exit.")
      key_down = false
      until key_down
        reader.on_key { |key, event| key_down = true }
      end
    end
  end
end
