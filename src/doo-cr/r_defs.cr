# Refresh/rendering module, shared data struct definitions.

module Doocr
  # Sprites are patches with a special naming convention
  #  so they can be recognized by R_InitSprites.
  # The base name is NNNNFx or NNNNFxFx, with
  #  x indicating the rotation, x = 0, 1-7.
  # The sprite and frame specified by a thing_t
  #  is range checked at run time.
  # A sprite is a patch_t that is assumed to represent
  #  a three dimensional object and may have multiple
  #  rotations pre drawn.
  # Horizontal flipping is used to save space,
  #  thus NNNNF2F5 defines a mirrored patch.
  # Some sprites will only have one picture used
  # for all views: NNNNF0
  struct Spriteframe
    # If false use 0 for any position.
    # Note: as eight entries are available,
    #  we might as well insert the same name eight times.
    property rotate : Int8 = -1

    # Lump to use for view angles 0-7.
    property lump : Array(Int16) = Array.new(8, -1_i16)

    # Flip bit (1 = flip) to use for view angles 0-7.
    property flip : Array(UInt8) = Array.new(8, 255_u8)
  end

  # A sprite definition:
  #  a number of animation frames.
  class Spritedef
    property numframes : Int32 = 0
    property spriteframes : Array(Spriteframe) = [] of Spriteframe
  end
end
