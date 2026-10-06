# Copyright (C) 2026 Devin Shwagginz
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# ==> The entry point for Doo-cr

require "socket"

require "./doo-cr/lib_doocr.cr"
require "./doo-cr/lib.cr"
require "./doo-cr/**"

require "raylib-cr"
require "raylib-cr/audio.cr"
require "./adlmidi.cr"

# The Doocr module housing all code
#
# TODO: Add mod examples into readme
# TODO: Add infinite comments to everything ever
# TODO: Fix Linux (Ubuntu) audio bugging
# TODO: Optimize drawing code
module Doocr
end

# Make it happen!
Doocr.doom_init
