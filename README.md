![logo](https://raw.githubusercontent.com/D-Shwagginz/doo-cr/master/logo/doo-cr.png)

[![Windows Artifact](https://github.com/D-Shwagginz/doo-cr/actions/workflows/windows-artifact.yml/badge.svg)](https://github.com/D-Shwagginz/doo-cr/actions/workflows/windows-artifact.yml) - Download Here!

[![Windows Build](https://github.com/D-Shwagginz/doo-cr/actions/workflows/windows-build.yml/badge.svg)](https://github.com/D-Shwagginz/doo-cr/actions/workflows/windows-build.yml)
[![Ubuntu Build](https://github.com/D-Shwagginz/doo-cr/actions/workflows/ubuntu-build.yml/badge.svg)](https://github.com/D-Shwagginz/doo-cr/actions/workflows/ubuntu-build.yml)<br>
[![Macos Build](https://github.com/D-Shwagginz/doo-cr/actions/workflows/macos-build.yml/badge.svg)](https://github.com/D-Shwagginz/doo-cr/actions/workflows/macos-build.yml)

A DOOM source port written in Crystal Lang based on [PureDoom](https://github.com/Daivuk/PureDOOM) and [LinuxDoom](https://github.com/id-Software/DOOM)

## Features

- Full DOOM, DOOM II, and Final Doom compatibility
- Working networked multiplayer
- Extra in-game settings
- Bug fixes and little additions <sup>[ask me about them!](mailto:devin@shwaggi.nz)</sup>
- A handful of limits removed
- midi music support
- Command line args (see below)
- A scary look into what very unsafe low level Crystal code looks like!
- Somewhat compatible demo playback
- Runtime calculated finesine, finetangent, and tantoangle data tables <br>&ensp;(Remove -DPRECOMPUTED in makefile)
- Smooth midi panning <sup>Thanks ADLMDI!</sup>
- DeHackEd and BEX support
- Multiple sprite and flat section support

## Usage
Running doo-cr will boot up an autodetected .wad file and will place the config file in the current directory.

To specify a wad file use -iwad, or if wanting to load a patch wad file as an iwad, like Chex Quest for example, use -fwad (force wad)

Common command line arguments are:
- -net \
  Creates a netgame. Port 5029 must but forwarded, see -port
- -net \<host.i.p.address> \
  Connects to a netgame
- -port \<port> \
  Sets the port to use for all I/O in a net game. Host must port forward this
- -extratic \<1-4> \
  Sends num extra packets for data redundancy during a netgame
- -iwad \<file> \
  Specify iwad to load
- -fwad \<file> \
  Forces loading of a wad as an iwad
- -file \<file> \
  Loads in a wad or lump on top of iwad and other -file's
- -merge \<file> \
  Will overwrite lumps already loaded with same name<br>
  If a lump doesn't exist yet, it will add it in like -file<br>
  Used to load a wad file as a pwad, but treat it with higher priority than an iwad
- -deh \<file> \
  Loads in a dehacked file
- -deathmatch \
  Used with -net to specify a deathmatch game
- -altdeath \
  Same as deathmatch but respawns items and powerups
- -config \<file> \
  Specify a configuration file to use
- -warp \<episode> \<level> \
  Starts the game at an episode and level number
- -warp \<map> \
  Starts the game at a map number
- -fast \
  Used with warp to enable fast monsters
- -skill \<1-5> \
  Used with warp to set the skill level
- -respawn \
  Used with warp to enable monster respawning
- -mem \<MB> \
  Sets the default zone memory size in MB. The default is 12MB
- -nosound \
  Runs the game without activating the sound thread

- -record \<name> \
  Record a demo with name to a .lmp file. Use Q to end demo
- -playdemo \<name> \
  Plays a lmp out of a wad or present in the folder
- -timedemo \<name> \
  Same as -playdemo but plays at an uncapped ticrate for benchmarking
- -timedemo \<name> -nodraw \
  Same as -timedemo but without drawing the video


## How to build
Use a unix shell, on Windows I use msys2 with UCRT64, with make, cmake and tools, Crystal, and Shards all installed and run `make`.

The make file should copy over all necessary lib files for any OS
into the bin folder.

## Status as a Source Port
This source port will not try to reinvent the wheel.<br>It will not try to be super advanced like GZDoom, ZDoom, etc. <br>It will not try to be 100% demo compatible like DSDA Doom. <br>This is just my source port for me to make Doom whatever I'd like in my favorite language.

If nothing else this project serves as proof that Crystal can be programmed as a low level procedural language for game development, as well as a sign that porting libraries over into Pure Crystal is simply a matter of time and effort given my idea of two-way-bindings that I used with PureDoom to create this project in the first place.

## Development

doo-cr utilized something I call two-way-bindings. I take a function in [PureDoom](https://github.com/Daivuk/PureDOOM), bind it into lib.cr,
rewrite it in Crystal as a [fun](https://crystal-lang.org/reference/1.21/syntax_and_semantics/c_bindings/fun.html) at the top level <sup>Not in a [lib](https://crystal-lang.org/reference/1.21/syntax_and_semantics/c_bindings/lib.html)</sup>, and then turn the C function into an extern declaration.

Because of this, I was able to test each function I rewrote as I rewrote them. The downside is that the code is all very C-typed. It is in Crystal though!

The only thing that still remains in C is just variable declarations that I have been too lazy to move over to Crystal. 

All methods are fully written in Crystal. The only C usage is bindings to [Raylib](https://github.com/sol-vin/raylib-cr) and [libADLMIDI](https://github.com/Wohlstand/libADLMIDI) <sup>rewriting those would be a completely seperate project</sup>

Do note that this code is extremely [unsafe](https://crystal-lang.org/reference/1.21/syntax_and_semantics/unsafe.html) due to its current C-typed nature.

## Plans
- Hardware OpenGL rendering
- By extension, shader effects
- Crystalized code (Not a null pointer in sight)
- Crystal test specs
- No calls into a `lib`
- Whatever I want
- Comments to help make Doom's source easier to read
- Reorganization and renaming of functions, ditto

## Contributing

1. Fork it (<https://github.com/d-shwagginz/doo-cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [D. Shwagginz](https://github.com/d-shwagginz) - creator and maintainer

### Special thanks
- [Ian Rash](https://github.com/sol-vin) for [raylib-cr](https://github.com/sol-vin/raylib-cr) and teaching me how to code!
- [Daivuk](https://github.com/Daivuk) for [PureDoom](https://github.com/Daivuk/PureDOOM)
- [Wohlstand](https://github.com/Wohlstand) for [libADLMIDI](https://github.com/Wohlstand/libADLMIDI)
- [raysan5](https://github.com/raysan5) for [raylib](https://github.com/raysan5/raylib)
