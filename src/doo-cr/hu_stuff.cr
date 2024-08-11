# Heads up display data

module Doocr
  HU_FONTSTART = '!' # the first font characters
  HU_FONTEND   = '_' # the last font characters

  # Calculate # of glyphs in font.
  HU_FONTSIZE = ((HU_FONTEND - HU_FONTSTART).to_i + 1)

  @@hu_font : Array(WAD::Graphic) = Array.new(HU_FONTSIZE, WAD::Graphic.new)

  @@shiftxform : Array(Char) = [] of Char

  @@french_shiftxform : Array(Char) = [
    0.chr,
    1.chr, 2.chr, 3.chr, 4.chr, 5.chr, 6.chr, 7.chr, 8.chr, 9.chr, 10.chr,
    11.chr, 12.chr, 13.chr, 14.chr, 15.chr, 16.chr, 17.chr, 18.chr, 19.chr, 20.chr,
    21.chr, 22.chr, 23.chr, 24.chr, 25.chr, 26.chr, 27.chr, 28.chr, 29.chr, 30.chr,
    31.chr,
    ' ', '!', '"', '#', '$', '%', '&',
    '"', # shift-'
    '(', ')', '*', '+',
    '?', # shift-,
    '_', # shift--
    '>', # shift-.
    '?', # shift-/
    '0', # shift-0
    '1', # shift-1
    '2', # shift-2
    '3', # shift-3
    '4', # shift-4
    '5', # shift-5
    '6', # shift-6
    '7', # shift-7
    '8', # shift-8
    '9', # shift-9
    '/',
    '.', # shift-;
    '<',
    '+', # shift-=
    '>', '?', '@',
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    '[', # shift-[
    '!', # shift-backslash - OH MY GOD DOES WATCOM SUCK
    ']', # shift-]
    '"', '_',
    '\'', # shift-`
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    '{', '|', '}', '~', 127.chr,
  ]

  @@english_shiftxform : Array(Char) = [
    0.chr,
    1.chr, 2.chr, 3.chr, 4.chr, 5.chr, 6.chr, 7.chr, 8.chr, 9.chr, 10.chr,
    11.chr, 12.chr, 13.chr, 14.chr, 15.chr, 16.chr, 17.chr, 18.chr, 19.chr, 20.chr,
    21.chr, 22.chr, 23.chr, 24.chr, 25.chr, 26.chr, 27.chr, 28.chr, 29.chr, 30.chr,
    31.chr,
    ' ', '!', '"', '#', '$', '%', '&',
    '"', # shift-'
    '(', ')', '*', '+',
    '<', # shift-,
    '_', # shift--
    '>', # shift-.
    '?', # shift-/
    ')', # shift-0
    '!', # shift-1
    '@', # shift-2
    '#', # shift-3
    '$', # shift-4
    '%', # shift-5
    '^', # shift-6
    '&', # shift-7
    '*', # shift-8
    '(', # shift-9
    ':',
    ':', # shift-;
    '<',
    '+', # shift-=
    '>', '?', '@',
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    '[', # shift-[
    '!', # shift-backslash - OH MY GOD DOES WATCOM SUCK
    ']', # shift-]
    '"', '_',
    '\'', # shift-`
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    '{', '|', '}', '~', 127.chr,
  ]

  @@french_key_map : Array(Char) = [
    0.chr,
    1.chr, 2.chr, 3.chr, 4.chr, 5.chr, 6.chr, 7.chr, 8.chr, 9.chr, 10.chr,
    11.chr, 12.chr, 13.chr, 14.chr, 15.chr, 16.chr, 17.chr, 18.chr, 19.chr, 20.chr,
    21.chr, 22.chr, 23.chr, 24.chr, 25.chr, 26.chr, 27.chr, 28.chr, 29.chr, 30.chr,
    31.chr,
    ' ', '!', '"', '#', '$', '%', '&', '%', '(', ')', '*', '+', ';', '-', ':', '!',
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ':', 'M', '<', '=', '>', '?',
    '@', 'Q', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', ',', 'N', 'O',
    'P', 'A', 'R', 'S', 'T', 'U', 'V', 'Z', 'X', 'Y', 'W', '^', '\\', '$', '^', '_',
    '@', 'Q', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', ',', 'N', 'O',
    'P', 'A', 'R', 'S', 'T', 'U', 'V', 'Z', 'X', 'Y', 'W', '^', '\\', '$', '^', 127.chr,
  ]

  def self.hu_init
    if @@language == Language::French
      @@shiftxform = @@french_shiftxform
    else
      @@shiftxform = @@english_shiftxform
    end

    # load the heads-up font
    j = HU_FONTSTART
    HU_FONTSIZE.times do |i|
      x = "STCFN#{j.ord.to_s(precision: 3)}"
      j += 1
      y = @@lumps[x].as?(WAD::Graphic)
      raise "hu_init: Invalid Font Graphic #{x}" unless y
      @@hu_font[i] = y.as(WAD::Graphic)
    end
  end
end
