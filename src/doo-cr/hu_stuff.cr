# Heads up display data

module Doocr
  HU_FONTSTART = '!' # the first font characters
  HU_FONTEND   = '_' # the last font characters

  # Calculate # of glyphs in font.
  HU_FONTSIZE = ((HU_FONTEND - HU_FONTSTART).to_i + 1)

  @@hu_font : Array(WAD::Graphic) = [] of WAD::Graphic
end
