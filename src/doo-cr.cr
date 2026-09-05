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

require "./doo-cr/lib.cr"
require "./doo-cr/**"

require "raylib-cr"
require "raylib-cr/audio.cr"
require "./adlmidi.cr"

# VGA DOS terminal colorings
SHELLCOLORS = [
  {0, 0, 0},       # 0  black
  {0, 0, 170},     # 1  blue
  {0, 170, 0},     # 2  green
  {0, 170, 170},   # 3  cyan
  {170, 0, 0},     # 4  red
  {170, 0, 170},   # 5  magenta
  {170, 85, 0},    # 6  brown
  {170, 170, 170}, # 7  light gray
  {85, 85, 85},    # 8  dark gray
  {85, 85, 255},   # 9  bright blue
  {85, 255, 85},   # 10 bright green
  {85, 255, 255},  # 11 bright cyan
  {255, 85, 85},   # 12 bright red
  {255, 85, 255},  # 13 bright magenta
  {255, 255, 85},  # 14 yellow
  {255, 255, 255}, # 15 white
]

module Doocr
  VERSION_STR = "1.6" # Used for displaying
  # Demo compatible version (Gameplay version)
  DEMOVERSION = 110
  # Save compatible version (Save data version)
  SAVEVERSION = 11
  # Net compatible version (Netcode version)
  NETVERSION = 15

  BUILD_TIME = {{ "#{`date -u +"%m-%d-%Y %H:%M:%S UTC"`.strip}" }}

  # The resolution of the player's viewport for hardware rendering
  # NOTE: the screen wipe is only designed for 320 x 240
  #        the game will snap from 320 x 240 to whatever res is set here after wiping
  @@sres_x = 320
  @@sres_y = 240

  unless ARGV.includes?("-headless") || ARGV.includes?("-nosound")
    # Create seperate thread so audio updates seperately from game code
    audio_context = Fiber::ExecutionContext::Isolated.new("doom-audio") do
      Doocr.update_audio
    end
  end

  @@pause_socket = false
  if ARGV.includes?("-net")
    # Create a seperate thread for the packets-in buffer during a netgame
    net_context = Fiber::ExecutionContext::Isolated.new("doom-net") do
      until @@insocket
      end
      sock = @@insocket.not_nil!
      loop do
        next if @@pause_socket
        sw_ptr = GC.malloc(sizeof(CDoom::Doomdata)).as(CDoom::Doomdata*)
        buf = Bytes.new(sw_ptr.as(UInt8*), sizeof(CDoom::Doomdata))
        begin
          c, fromaddress = sock.receive(buf)
          @@recv_channel.send({sw_ptr.value, c, fromaddress})
        rescue ex
        end
      end
    end
  end

  alias IOJob = {String, String, Bytes?, Channel({Bytes, Bool})} # path, mode, write_data (nil=read), response
  @@io_jobs = Channel(IOJob).new

  # Create a thread for File IO
  io_context = Fiber::ExecutionContext::Isolated.new("doom-io") do
    loop do
      path, mode, write_data, response = @@io_jobs.receive
      if data = write_data
        begin
          File.write(path, data)
          response.send({Bytes.empty, true})
        rescue
          response.send({Bytes.empty, false})
        end
      else
        begin
          response.send({File.read(path).to_slice, true})
        rescue
          response.send({Bytes.empty, false})
        end
      end
    end
  end
end

struct SpinLock
  def initialize
    @flag = Atomic(Bool).new(false)
  end

  def synchronize(&)
    until @flag.compare_and_set(false, true)[1]
      LibC.sched_yield # let another OS thread run; does NOT touch Crystal's fiber scheduler
    end
    begin
      yield
    ensure
      @flag.set(false)
    end
  end
end

lib LibC
  fun sched_yield : Int32
end

Fiber::ExecutionContext.default.resize(1)
MAIN_THREAD = Thread.current

# Terminal exit stuff (Should move raylib deinit into here?)
at_exit do
  print "\e7"     # save cursor position
  print "\e[r"    # reset scrolling region
  print "\e8"     # restore cursor position
  print "\e[?25h" # show cursor

  unless Doocr.w_check_num_for_name("ENDOOM".to_unsafe) == -1
    endoom = Doocr.w_cache_lump_name("ENDOOM".to_unsafe, CDoom::PU_CACHE).as(UInt8*)

    cp437 = [
      " ", "☺", "☻", "♥", "♦", "♣", "♠", "•",
      "◘", "○", "◙", "♂", "♀", "♪", "♫", "☼",
      "►", "◄", "↕", "‼", "¶", "§", "▬", "↨",
      "↑", "↓", "→", "←", "∟", "↔", "▲", "▼",
      " ", "!", "\"", "#", "$", "%", "&", "'",
      "(", ")", "*", "+", ",", "-", ".", "/",
      "0", "1", "2", "3", "4", "5", "6", "7",
      "8", "9", ":", ";", "<", "=", ">", "?",
      "@", "A", "B", "C", "D", "E", "F", "G",
      "H", "I", "J", "K", "L", "M", "N", "O",
      "P", "Q", "R", "S", "T", "U", "V", "W",
      "X", "Y", "Z", "[", "\\", "]", "^", "_",
      "`", "a", "b", "c", "d", "e", "f", "g",
      "h", "i", "j", "k", "l", "m", "n", "o",
      "p", "q", "r", "s", "t", "u", "v", "w",
      "x", "y", "z", "{", "|", "}", "~", "⌂",
      "Ç", "ü", "é", "â", "ä", "à", "å", "ç",
      "ê", "ë", "è", "ï", "î", "ì", "Ä", "Å",
      "É", "æ", "Æ", "ô", "ö", "ò", "û", "ù",
      "ÿ", "Ö", "Ü", "¢", "£", "¥", "₧", "ƒ",
      "á", "í", "ó", "ú", "ñ", "Ñ", "ª", "º",
      "¿", "⌐", "¬", "½", "¼", "¡", "«", "»",
      "░", "▒", "▓", "│", "┤", "╡", "╢", "╖",
      "╕", "╣", "║", "╗", "╝", "╜", "╛", "┐",
      "└", "┴", "┬", "├", "─", "┼", "╞", "╟",
      "╚", "╔", "╩", "╦", "╠", "═", "╬", "╧",
      "╨", "╤", "╥", "╙", "╘", "╒", "╓", "╫",
      "╪", "┘", "┌", "█", "▄", "▌", "▐", "▀",
      "α", "ß", "Γ", "π", "Σ", "σ", "µ", "τ",
      "Φ", "Θ", "Ω", "δ", "∞", "φ", "ε", "∩",
      "≡", "±", "≥", "≤", "⌠", "⌡", "÷", "≈",
      "°", "∙", "·", "√", "ⁿ", "²", "■", " ",
    ]

    25.times do |y|
      80.times do |x|
        i = (y * 80 + x) * 2

        ch = endoom[i]
        attr = endoom[i + 1]

        fg = attr & 0x0F
        bg = (attr >> 4) & 0x07
        blink = (attr & 0x80) != 0

        fr, fgc, fb = SHELLCOLORS[fg]
        br, bgc, bb = SHELLCOLORS[bg]

        # Set the exact foreground/background for this DOS text cell.
        print "\e[38;2;#{fr};#{fgc};#{fb}m"
        print "\e[48;2;#{br};#{bgc};#{bb}m"

        # DOS blink -> terminal blink.
        print "\e[5m" if blink

        # CP437 -> Unicode for the terminal.
        print cp437[ch]
      end

      # Move to the beginning of the next row without adding an
      # extra terminal column.
      print "\e[0m\r\n"
    end

    print "\e[0m"
  end
end

Doocr.make_mod do |mod|
  mod.name = "Bonk Doom"
  mod.check_wad "bonk"
  mod.make_player_var "can_dash?", false

  mod.update_player do |player|
    mo = player.value.mo
    if mo.value.z == mo.value.floorz
      mod.player_var(player)["can_dash?"] = true
    end
  end

  mod.add_weapon Doocr::Mod::Weapon::WeaponSlot::Fist do |weapon|
    weapon.ammo_type = Doocr::Mod::Weapon::AmmoType::Noammo
    weapon.states do |up, down, ready, atk, flash|
      ready.add "PUNG", 'A', 1, (->CDoom.a_weapon_ready).pointer
      ready.loop

      down.add "PUNG", 'A', 1, (->CDoom.a_lower).pointer
      down.loop

      up.add "PUNG", 'A', 1, (->CDoom.a_raise).pointer
      up.loop

      atk.add "PUNG", 'B', 3
      atk.add "PUNG", 'C', 3
      atk.add "PUNG", 'D', 2 do
        player = mod.get_player
        mo = player.value.mo
        if mo.value.z == mo.value.floorz
          Doocr.s_start_sound(mo.as(Void*), CDoom::Sfxenum::SFX_metal.value)
          mo.value.momz = Doocr::FRACUNIT * 20
        elsif mod.player_var(player)["can_dash?"]
          Doocr.s_start_sound(mo.as(Void*), CDoom::Sfxenum::SFX_stnmov.value)
          mo.value.momx = 0
          mo.value.momy = 0
          mo.value.momz = 0
          Doocr.p_thrust(player, mo.value.angle, Doocr::FRACUNIT * 20)

          mod.player_var(player)["can_dash?"] = false
        end
      end
      atk.add "PUNG", 'C', 3
      atk.add "PUNG", 'B', 3
      atk.goto ready
    end
  end

  mod.add_line "Air launch", Doocr::Mod::Line::When::Crossed do |line, side, thing|
    if thing.value.z == thing.value.floorz
      Doocr.s_start_sound(thing.as(Void*), CDoom::Sfxenum::SFX_rlaunc.value)
      thing.value.momz = Doocr::FRACUNIT * 30
    end
  end

  mod.add_sector "Insta kill" do |sector, player|
    mo = player.value.mo
    if mo.value.z < sector.value.floorheight + Doocr::FRACUNIT * 200
      Doocr.p_damage_mobj(player.value.mo, Pointer(CDoom::Mobj).null, Pointer(CDoom::Mobj).null, 10000)
    end
  end

  mod.add_line "Switch change floor and move sector up amount", Doocr::Mod::Line::When::Used do |line, side, thing|
    Doocr.p_change_switch_texture(line, 0)

    sector = Doocr.p_find_sector_from_line_tag(line, -1)
    sector = CDoom.sectors + sector
    floor = CDoom.z_malloc(sizeof(CDoom::Floormove), CDoom::PU_LEVSPEC, Pointer(Void).null).as(CDoom::Floormove*)
    CDoom.p_add_thinker(pointerof(floor.value.@thinker))
    sector.value.specialdata = floor
    sector.value.special = 0
    sector.value.floorpic = Doocr.r_flat_num_for_name("FLAT1".to_unsafe)
    pointerof(floor.value.@thinker.@function).as(CDoom::ActionfP1*).value = CDoom::ActionfP1.new((->CDoom.t_move_floor).pointer, Pointer(Void).null)
    floor.value.type = CDoom::Floorenum::RaiseFloor
    floor.value.crush = 0
    floor.value.direction = 1
    floor.value.sector = sector
    floor.value.speed = CDoom::FLOORSPEED * 20
    floor.value.floordestheight = Doocr::FRACUNIT * 350
  end
end

# Make it happen!
Doocr.doom_init
