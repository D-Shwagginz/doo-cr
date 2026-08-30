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
require "./doo-cr/variables.cr"
require "./doo-cr/doo-cr.cr"
require "./doo-cr/implementation.cr"

require "raylib-cr"
require "raylib-cr/audio.cr"
require "./adlmidi.cr"

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
  VERSION_STR = "1.5" # Used for displaying
  DEMOVERSION = 110
  SAVEVERSION =  11
  NETVERSION  =  15

  BUILD_TIME = {{ "#{`date -u +"%m-%d-%Y %H:%M:%S UTC"`.strip}" }}

  # The resolution of the player's viewport for hardware rendering
  # NOTE: the screen wipe is only designed for 320 x 240
  #        the game will snap from 320 x 240 to whatever res is set here after wiping
  @@sres_x = 320
  @@sres_y = 240

  # Midi info
  MIDI_BUFFER_SIZE =  1024
  MIDI_SAMPLE_RATE = 44100
  MIDI_TICK_TIME   = 1.0 / 140.0

  # -- Macros for quick key polling --
  macro poll_key(doomkey, raylibkey)
  was_down = Doocr.keystates[CDoom::DoomKey::{{doomkey}}.value]
  is_down = Raylib::KeyboardKey::{{raylibkey}}.down?

  Doocr.doom_key_down(CDoom::DoomKey::{{doomkey}}) if is_down && !was_down
  Doocr.doom_key_up(CDoom::DoomKey::{{doomkey}}) if !is_down && was_down
end

  macro poll_two_key(doomkey, raylibkey1, raylibkey2)
  was_down = Doocr.keystates[CDoom::DoomKey::{{doomkey}}.value]
  is_down = Raylib::KeyboardKey::{{raylibkey1}}.down? || Raylib::KeyboardKey::{{raylibkey2}}.down?
  
  Doocr.doom_key_down(CDoom::DoomKey::{{doomkey}}) if is_down && !was_down
  Doocr.doom_key_up(CDoom::DoomKey::{{doomkey}}) if !is_down && was_down
end

  macro poll_button(doombutton, raylibbutton)
  was_down = CDoom.button_states[CDoom::DoomButton::{{doombutton}}.value] != 0
  is_down = Raylib::MouseButton::{{raylibbutton}}.down?
  Doocr.doom_button_down(CDoom::DoomButton::{{doombutton}}) if is_down && !was_down
  Doocr.doom_button_up(CDoom::DoomButton::{{doombutton}}) if !is_down && was_down
end

  # -- Macros for quick key polling --

  unless ARGV.includes?("-nosound")
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

at_exit do
  print "\e7"     # save cursor position
  print "\e[r"    # reset scrolling region
  print "\e8"     # restore cursor position
  print "\e[?25h" # show cursor

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

# Make it happen!
Doocr.doom_init(ARGC_UNSAFE, ARGV_UNSAFE, 0)
