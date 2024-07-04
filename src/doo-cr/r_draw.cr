# The actual span/column drawing functions.

module Doocr
  # Used to draw player sprites
  #  with the green colorramp mapped to others.
  # Could be used with different translation
  #  tables, e.g. the lighter colored version
  #  of the BaronOfHell, the HellKnight, uses
  #  identical sprites, kinda brightened up.
  @@dc_translation : Array(UInt8) = [] of UInt8
  @@translationtables : Array(UInt8) = Array.new(256*3 + 255, 0_u8)

  def self.r_init_translation_tables
    # translate just the 16 green colors
    256.times do |i|
      if i >= 0x70 && i <= 0x7f
        # map green ramp to gray, brown, red
        @@translationtables[i] = (0x60 + (i & 0xf)).to_u8
        @@translationtables[i + 256] = (0x40 + (i & 0xf)).to_u8
        @@translationtables[i + 512] = (0x20 + (i & 0xf)).to_u8
      else
        # keep all other colors as it
        @@translationtables[i] = @@translationtables[i + 256]
        @@translationtables[i + 512] = i.to_u8
      end
    end
  end
end
