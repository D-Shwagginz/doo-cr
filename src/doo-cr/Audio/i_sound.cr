module Doocr::Audio
  module ISound
    abstract def set_listener(listener : Mobj)
    abstract def update
    abstract def start_sound(sfx : Sfx)
    abstract def start_sound(mobj : Mobj, sfx : Sfx, type : SfxType)
    abstract def start_sound(mobj : Mobj, sfx : Sfx, type : SfxType, volume : Int32)
    abstract def stop_sound(mobj : Mobj)
    abstract def reset
    abstract def pause
    abstract def resume

    abstract def max_volume : Int32
    abstract def volume : Int32
    abstract def volume=(@volume : Int32) : Int32
  end
end
