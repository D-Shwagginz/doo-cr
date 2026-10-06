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
# TODO: Fix game jitter on lower end hardware (less cpu cores)
# TODO: Figure out why the game doesn't display on windows on older gpus
module Doocr
  VERSION_STR = "1.7" # Used for displaying
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

  # Create seperate thread so audio updates seperately from game code
  unless ARGV.includes?("-headless") || ARGV.includes?("-nosound")
    audio_context = Fiber::ExecutionContext::Isolated.new("doom-audio") do
      Doocr.update_audio
    end
  end

  @@pause_socket = false
  # Create a seperate thread for the packets-in buffer during a netgame
  if ARGV.includes?("-net")
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

  alias IOJob = {String, String, Bytes?, ::Channel({Bytes, Bool})} # path, mode, write_data (nil=read), response
  @@io_jobs = ::Channel(IOJob).new

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

# A Fiber SpinLock mainly so that the audio fiber doesn't jump off its thread
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

# Make it happen!
Doocr.doom_init
