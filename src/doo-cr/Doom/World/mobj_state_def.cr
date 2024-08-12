module Doocr
  class MobjStateDef
    property number : Int32
    property sprite : Sprite
    property frame : Int32
    property tics : Int32
    property player_action : Proc(World, Player, PlayerSpriteDef, Nil) | Nil
    property mobj_action : Proc(World, Mobj, Nil) | Nil
    property next : MobjState
    property misc1 : Int32
    property misc2 : Int32

    def initialize(
      @number : Int32,
      @sprite : Sprite,
      @frame : Int32,
      @tics : Int32,
      @player_action : Proc(World, Player, PlayerSpriteDef, Nil) | Nil,
      @mobj_action : Proc(World, Mobj, Nil) | Nil,
      @next : MobjState,
      @misc1 : Int32,
      @misc2 : Int32
    )
    end
  end
end
