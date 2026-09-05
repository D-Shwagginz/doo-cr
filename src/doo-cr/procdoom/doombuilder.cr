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

      cfg.puts "" \
               "sectortypes
      {"
      @@sectors.each do |sector|
        cfg.puts "#{sector.number} = \"#{sector.db_name}\";"
      end
      cfg.puts "}"
    end
  end
end
