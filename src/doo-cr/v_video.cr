# Primary Raylib (Video Related) Code

module Doocr
  @@screen_width = 640
  @@screen_height = 400

  @@screen_scale = 0.0

  @@real_screen : Raylib::Camera2D = Raylib::Camera2D.new
  @@screen : Raylib::Camera2D = Raylib::Camera2D.new
  @@screen_target : Raylib::RenderTexture2D = Raylib::RenderTexture2D.new

  def self.v_init
    Raylib.set_trace_log_level(Raylib::TraceLogLevel::Error) unless LOG_RAYLIB
    Raylib.init_window(@@screen_width, @@screen_height, "DOOCR")
    Raylib.set_window_min_size(320, 200)
    Raylib.set_target_fps(35)
    @@real_screen.zoom = 1.0_f32
    @@screen.zoom = 1.0_f32
    @@screen_target = Raylib.load_render_texture(SCREENWIDTH, SCREENHEIGHT)
    Raylib.set_texture_filter(@@screen_target.texture, Raylib::TextureFilter::Point)
  end

  def self.v_draw_patch_direct(x : Int32, y : Int32, patch : String | WAD::Graphic)
  end
end
