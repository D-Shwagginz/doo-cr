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

module LibDoom
  VERSION_STR = "1.4" # Used for displaying
  DEMOVERSION = 110
  SAVEVERSION =  10
  NETVERSION  =  13

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
  was_down = LibDoom.keystates[CDoom::DoomKey::{{doomkey}}.value]
  is_down = Raylib::KeyboardKey::{{raylibkey}}.down?

  LibDoom.doom_key_down(CDoom::DoomKey::{{doomkey}}) if is_down && !was_down
  LibDoom.doom_key_up(CDoom::DoomKey::{{doomkey}}) if !is_down && was_down
end

  macro poll_two_key(doomkey, raylibkey1, raylibkey2)
  was_down = LibDoom.keystates[CDoom::DoomKey::{{doomkey}}.value]
  is_down = Raylib::KeyboardKey::{{raylibkey1}}.down? || Raylib::KeyboardKey::{{raylibkey2}}.down?
  
  LibDoom.doom_key_down(CDoom::DoomKey::{{doomkey}}) if is_down && !was_down
  LibDoom.doom_key_up(CDoom::DoomKey::{{doomkey}}) if !is_down && was_down
end

  macro poll_button(doombutton, raylibbutton)
  was_down = CDoom.button_states[CDoom::DoomButton::{{doombutton}}.value] != 0
  is_down = Raylib::MouseButton::{{raylibbutton}}.down?
  LibDoom.doom_button_down(CDoom::DoomButton::{{doombutton}}) if is_down && !was_down
  LibDoom.doom_button_up(CDoom::DoomButton::{{doombutton}}) if !is_down && was_down
end

  # -- Macros for quick key polling --

  unless ARGV.includes?("-nosound")
    # Create seperate thread so audio updates seperately from game code
    audio_context = Fiber::ExecutionContext::Isolated.new("doom-audio") do
      LibDoom.update_audio
    end
  end

  @@pause_socket = false
  if ARGV.includes?("-net") || ARGV.includes?("-altnet")
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

MAIN_THREAD = Thread.current
Fiber::ExecutionContext.default.resize(1)

at_exit do
  print "\e7"       # save cursor position
print "\e[r"      # reset scrolling region
print "\e8"       # restore cursor position
print "\e[?25h"   # show cursor
end

# Make it happen!
LibDoom.doom_init(ARGC_UNSAFE, ARGV_UNSAFE, 0)
