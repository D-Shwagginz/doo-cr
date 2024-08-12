module Doocr
  class WeaponInfo
    property ammo : AmmoType
    property up_state : MobjState
    property down_state : MobjState
    property ready_state : MobjState
    property attack_state : MobjState
    property flash_state : MobjState

    def initialize(
      @ammo : AmmoType,
      @up_state : MobjState,
      @down_state : MobjState,
      @ready_state : MobjState,
      @attack_state : MobjState,
      @flash_state : MobjState
    )
    end
  end
end
