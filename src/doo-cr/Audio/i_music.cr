module Doocr::Audio
  module IMusic
    abstract def start_musc(bgm : Bgm, loop : Bool)

    abstract def max_volume : Int32
    abstract def volume : Int32
    abstract def volume=(@volume : Int32) : Int32
  end
end
