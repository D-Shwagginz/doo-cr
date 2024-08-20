module Doocr
  class World
    @options : GameOptions | Nil
    @game : DoomGame | Nil
    @random : DoomRandom | Nil

    @map : Map | Nil

    @thinkers : Thinkers | Nil
    @specials : Specials | Nil
    @thing_allocation : ThingAllocation | Nil
    @thing_movement : ThingMovement | Nil
    @thing_interaction : ThingInteraction | Nil
    @map_collision : MapCollision | Nil
    @map_interaction : MapInteraction | Nil
    @path_traversal : PathTraversal | Nil
    @hitscan : Hitscan | Nil
    @visibility_check : VisibilityCheck | Nil
    
  end
end
