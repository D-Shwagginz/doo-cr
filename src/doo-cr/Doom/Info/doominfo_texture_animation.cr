module Doocr
  module DoomInfo
    class_getter texture_animation : Array(AnimationDef) = [
      AnimationDef.new(false, "NUKAGE3", "NUKAGE1", 8),
      AnimationDef.new(false, "FWATER4", "FWATER1", 8),
      AnimationDef.new(false, "SWATER4", "SWATER1", 8),
      AnimationDef.new(false, "LAVA4", "LAVA1", 8),
      AnimationDef.new(false, "BLOOD3", "BLOOD1", 8),

      # DOOM II flat animations.
      AnimationDef.new(false, "RROCK08", "RROCK05", 8),
      AnimationDef.new(false, "SLIME04", "SLIME01", 8),
      AnimationDef.new(false, "SLIME08", "SLIME05", 8),
      AnimationDef.new(false, "SLIME12", "SLIME09", 8),

      AnimationDef.new(true, "BLODGR4", "BLODGR1", 8),
      AnimationDef.new(true, "SLADRIP3", "SLADRIP1", 8),

      AnimationDef.new(true, "BLODRIP4", "BLODRIP1", 8),
      AnimationDef.new(true, "FIREWALL", "FIREWALA", 8),
      AnimationDef.new(true, "GSTFONT3", "GSTFONT1", 8),
      AnimationDef.new(true, "FIRELAVA", "FIRELAV3", 8),
      AnimationDef.new(true, "FIREMAG3", "FIREMAG1", 8),
      AnimationDef.new(true, "FIREBLU2", "FIREBLU1", 8),
      AnimationDef.new(true, "ROCKRED3", "ROCKRED1", 8),

      AnimationDef.new(true, "BFALL4", "BFALL1", 8),
      AnimationDef.new(true, "SFALL4", "SFALL1", 8),
      AnimationDef.new(true, "WFALL4", "WFALL1", 8),
      AnimationDef.new(true, "DBRAIN4", "DBRAIN1", 8),
    ]
  end
end
