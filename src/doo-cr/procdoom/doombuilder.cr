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
# ==> The Doom Builder CFG file generator

module Doocr::Mod
  def self.build_doombuilder_cfg
    File.open("./Doom_Mod.cfg", "w") do |cfg|
      cfg.puts "" \
               "type = \"Doom Builder 2 Game Configuration\";
game = \"Doom: Modded Doom 2 (Doom format)\";
engine = \"doom2\";

// Should this configuration be initially available?
enabledbydefault = true;

// STANDARD DOOM SETTINGS
// Settings common to all games and all map formats
include(\"Includes\\\\Doom_common.cfg\", \"common\");

// Settings common to Doom map format
include(\"Includes\\\\Doom_common.cfg\", \"mapformat_doom\");

// Settings common to Doom games
include(\"Includes\\\\Game_Doom.cfg\");

// Map name format for Doom 2.
mapnameformat = \"MAPxy\";

//mxd. No DECORATE support in vanilla
decorategames = \"\";

// Default thing filters
// (these are not required, just useful for new users)
thingsfilters
{
	include(\"Includes\\\\Doom_misc.cfg\", \"thingsfilters\");
}

// THING TYPES
// Each engine has its own additional thing types
// Order should always be 1: Game; 2: ZDoom/game; 3: ZDoom/zdoom
thingtypes
{
	// Basic game actors
	include(\"Includes\\\\Doom_things.cfg\");
	include(\"Includes\\\\Doom2_things.cfg\");
}

// ENUMERATIONS
// Each engine has its own additional thing types
// These are enumerated lists for linedef types and UDMF fields.
enums
{
	// Basic game enums
	include(\"Includes\\\\Doom_misc.cfg\", \"enums\");
}

// Dehacked data
dehacked
{
  include(\"Includes\\\\Dehacked_Doom.cfg\");
}"

      cfg.puts "linedeftypes
	{
    mod
    {
      title = \"Mod\";
	"

      @@lines.each do |line|
        cfg.puts "#{line.number}
      {
        title = \"#{line.db_name}\";
      }"
      end
      cfg.puts "}}"

      cfg.puts "sectortypes
      {"
      @@sectors.each do |sector|
        cfg.puts "#{sector.number} = \"#{sector.db_name}\";"
      end
      cfg.puts "}"

      cfg.puts "thingtypes
      {
      mod
      {
      color = 0;
      arrow = 1;
      title = \"Mod\";
      width = 16;
      sort = 1;
      height = 56;
      error = 2;"
      @@things.each do |thing|
        next if thing.doomednum == -1
        cfg.puts "#{thing.doomednum}
        {
        title = \"#{thing.db_name}\";
        width = #{thing.radius.round.to_i32};
        height = #{thing.height.round.to_i32};"
        cfg.puts "sprite = \"#{thing.db_sprite.upcase}\";" unless thing.db_sprite.empty?
        cfg.puts "hangs = #{thing.flags.spawn_ceiling?.to_unsafe};"
        cfg.puts "blocking = #{thing.flags.solid?.to_unsafe};"
        cfg.puts "}"
      end
      cfg.puts "}}"
    end
  end
end
