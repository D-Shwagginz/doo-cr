module Doocr
  class Doom
    @args : CommandLineArgs
    @config : Config
    @content : GameContent
    @video : IVideo
    @sound : Audio::ISound
    @music : Audio::IMusic
    @user_input : UserInput::IUserInput

    @events : Array(DoomEvent)

    @options : GameOptions
  end
end
