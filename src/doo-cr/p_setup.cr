# Do all the WAD I/O, get map description,

module Doocr
  def self.p_init
    p_init_switch_list()
    p_init_pic_anims()
    r_init_sprites(@@sprnames)
  end
end
