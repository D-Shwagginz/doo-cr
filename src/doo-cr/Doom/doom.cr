module Doocr
  class Doom
    @args : CommandLineArgs | Nil
    @config : Config | Nil
    @content : GameContent | Nil
    @video : IVideo | Nil
    @sound : Audio::ISound | Nil
    @music : Audio::IMusic | Nil
    @user_input : UserInput::IUserInput | Nil

    @events : Array(DoomEvent) = Array(DoomEvent).new

    @options : GameOptions | Nil
  end
end
