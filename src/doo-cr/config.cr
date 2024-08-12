module Doocr
  class Config
    getter key_forward : KeyBinding
    getter key_backward : KeyBinding
    getter key_strafeleft : KeyBinding
    getter key_straferight : KeyBinding
    getter key_turnleft : KeyBinding
    getter key_turnright : KeyBinding
    getter key_fire : KeyBinding
    getter key_use : KeyBinding
    getter key_run : KeyBinding
    getter key_strafe : KeyBinding

    getter mouse_sensitivity : Int32
    getter mouse_disableyaxis : Bool

    getter game_alwaysrun : Bool

    getter video_screenwidth : Int32
    getter video_screenheight : Int32
    getter video_fullscreen : Bool
    getter video_highresolution : Bool
    getter video_displaymessage : Bool
    getter video_gamescreensize : Int32
    getter video_gammacorrection : Int32
    getter video_fpsscale : Int32

    getter audio_soundvolume : Int32
    getter audio_musicvolume : Int32
    getter audio_randompitch : Bool
    getter audio_soundfont : String
    getter audio_musiceffect : Bool

    getter is_restored_from_file : Bool

    # Default settings.
    def initialize
      @key_forward = KeyBinding.new(
        [
          DoomKey::Up,
          DoomKey::W,
        ])
      @key_backward = KeyBinding.new(
        [
          DoomKey::Down,
          DoomKey::S,
        ])
      @key_strafeleft = KeyBinding.new(
        [
          DoomKey::A,
        ])
      @key_straferight = KeyBinding.new(
        [
          DoomKey::D,
        ])
      @key_turnleft = KeyBinding.new(
        [
          DoomKey::Left,
        ])
      @key_turnright = KeyBinding.new(
        [
          DoomKey::Right,
        ])
      @key_fire = KeyBinding.new(
        [
          DoomKey::LControl,
          DoomKey::RControl,
        ],
        [
          DoomMouseButton::Mouse1,
        ])
      @key_use = KeyBinding.new(
        [
          DoomKey::Space,
        ],
        [
          DoomMouseButton::Mouse2,
        ])
      @key_run = KeyBinding.new(
        [
          DoomKey::LShift,
          DoomKey::RShift,
        ])
      @key_strafe = KeyBinding.new(
        [
          DoomKey::LAlt,
          DoomKey::RAlt,
        ])

      @mouse_sensitivity = 8
      @mouse_disableyaxis = false

      @game_alwaysrun = true

      @video_screenwidth = 640
      @video_screenheight = 400
      @video_fullscreen = false
      @video_highresolution = true
      @video_gamescreensize = 7
      @video_displaymessage = true
      @video_gammacorrection = 2
      @video_fpsscale = 2

      @audio_soundvolume = 8
      @audio_musicvolume = 8
      @audio_randompitch = true
      @audio_soundfont = "TimGM6mb.sf2"
      @audio_musiceffect = true

      @is_restored_from_file = false
    end
  end
end
