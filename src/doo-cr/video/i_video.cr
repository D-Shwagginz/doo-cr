module Doocr
  module IVideo
    abstract def render(doom : Doom, frame_frac : Fixed)
    abstract def initialize_wipe
    abstract def has_focus : Bool

    abstract def max_window_size : Int32
    abstract def window_size : Int32
    abstract def window_size=(@window_size : Int32)

    abstract def display_message : Bool
    abstract def display_message=(@display_message : Bool)

    abstract def max_gamma_correction_level : Int32
    abstract def gamma_correction_level : Int32
    abstract def gamma_correction_level=(@gamma_correction_level : Int32)

    abstract def wipe_band_count : Int32
    abstract def wipe_height : Int32
  end
end
