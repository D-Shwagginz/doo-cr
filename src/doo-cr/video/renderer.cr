module Doocr::Video
  class Renderer
    @@gamma_correction_parameters : Array(Float64) = [
      1.00,
      0.95,
      0.90,
      0.85,
      0.80,
      0.75,
      0.70,
      0.65,
      0.60,
      0.55,
      0.50,
    ]

    @config : Config | Nil

    @palette : Palette | Nil

    @screen : DrawScreen | Nil

    @menu : MenuRenderer | Nil
  end
end
