require "raylib-cr"
require "term-reader"
require "./doo-cr/**"

alias RL = Raylib

module Doocr
  VERSION = "1.0.0Alpha"
end

Doocr::Raylib.main
