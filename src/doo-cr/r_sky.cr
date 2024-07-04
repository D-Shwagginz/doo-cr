# Sky rendering

module Doocr
  @@skytexturemid : Int32 = 0

  def self.r_init_sky_map
    @@skytexturemid = 100*FRACUNIT
  end
end
