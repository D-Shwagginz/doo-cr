#
# Copyright (C) 1993-1996 Id Software, Inc.
# Copyright (C) 2019-2020 Nobuaki Tanaka
# Copyright (C) 2024 Devin Shwagginz
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#

module Doocr::Video
  class Renderer
    @@gamma_correction_parameters : Array(Float64) = [
      1.00,
      0.95,
      0.90,
      0.85,
      0.80,
      0.75,
      0.70,
      0.65,
      0.60,
      0.55,
      0.50,
    ]

    @config : Config | Nil

    @palette : Palette | Nil

    @screen : DrawScreen | Nil

    @menu : MenuRenderer | Nil
  end
end
