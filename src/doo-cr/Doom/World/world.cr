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

module Doocr
  class World
    getter options : GameOptions
    getter game : DoomGame
    getter random : DoomRandom

    getter map : Map | Nil = nil

    getter thinkers : Thinkers | Nil = nil
    getter specials : Specials | Nil = nil
    getter thing_allocation : ThingAllocation | Nil = nil
    getter thing_movement : ThingMovement | Nil = nil
    getter thing_interaction : ThingInteraction | Nil = nil
    getter map_collision : MapCollision | Nil = nil
    getter map_interaction : MapInteraction | Nil = nil
    getter path_traversal : PathTraversal | Nil = nil
    getter hitscan : Hitscan | Nil = nil
    getter visibility_check : VisibilityCheck | Nil = nil
    getter sector_action : SectorAction | Nil = nil
    getter player_behavior : PlayerBehavior | Nil = nil
    getter item_pickup : ItemPickup | Nil = nil
    getter weapon_behavior : WeaponBehavior | Nil = nil
    getter monster_behavior : MonsterBehavior | Nil = nil
    getter lighting_change : LightingChange | Nil = nil
    getter status_bar : StatusBar | Nil = nil
    getter auto_map : AutoMap | Nil = nil
    getter cheat : Cheat | Nil = nil

    property total_kills : Int32 = 0
    property total_items : Int32 = 0
    property total_secrets : Int32 = 0

    property level_time : Int32 = 0
    @done_first_tic : Bool = false
    getter secret_exit : Bool = false
    @completed : Bool = false

    @valid_count : Int32 = 0

    @display_player : Int32 = 0

    # This is for vanilla compatibility.
    # See subst_nil_mobj().
    @dummy : Mobj | Nil = nil

    def game_tic : Int32
      return @game.game_tic
    end

    def console_player
      return @options.players[@options.console_player]
    end

    def display_player
      return @options.players[@display_player]
    end

    def first_tic_is_not_yet_done
      return console_player.view_z == Fixed.epsilon
    end

    def initialize(resources : GameContent, @options : GameOptions, @game : DoomGame)
      @random = @options.random

      @map = Map.new(resources, self)

      @thinkers = Thinkers.new(self)
      @specials = Specials.new(self)
      @thing_allocation = ThingAllocation.new(self)
      @thing_movement = ThingMovement.new(self)
      @thing_interaction = ThingInteraction.new(self)
      @map_collision = MapCollision.new(self)
      @map_interaction = MapInteraction.new(self)
      @path_traversal = PathTraversal.new(self)
      @hitscan = Hitscan.new(self)
      @visibility_check = VisibilityCheck.new(self)
      @sector_action = SectorAction.new(self)
      @player_behavior = PlayerBehavior.new(self)
      @item_pickup = ItemPickup.new(self)
      @weapon_behavior = WeaponBehavior.new(self)
      @monster_behavior = MonsterBehavior.new(self)
      @lighting_change = LightingChange.new(self)
      @status_bar = StatusBar.new(self)
      @auto_map = AutoMap.new(self)
      @cheat = Cheat.new(self)

      @options.intermission_info.total_frags = 0
      @options.intermission_info.par_time = 180

      Player::MAX_PLAYER_COUNT.times do |i|
        @options.players[i].kill_count = 0
        @options.players[i].secret_count = 0
        @options.players[i].item_count = 0
      end

      # Initial height of view will be set by player think.
      @options.players[@options.console_player].view_z = Fixed.epsilon

      @total_kills = 0
      @total_items = 0
      @total_secrets = 0

      load_things()

      # If deathmatch, randomly spawn the active players.
      if @options.deathmatch != 0
        Player::MAX_PLAYER_COUNT.times do |i|
          if @options.players[i].in_game
            @options.players[i].mobj = nil
            @thing_allocation.death_match_spawn_player(i)
          end
        end
      end

      @specials.spawn_specials

      @level_time = 0
      @done_first_tic = false
      @secret_exit = false
      @completed = false

      @valid_count = 0

      @display_player = @options.console_player

      @dummy = Mobj.new(self)

      @options.music.start_music(Map.get_map_bgm(@options), true)
    end

    def update : UpdateResult
      players = @options.players

      Player::MAX_PLAYER_COUNT.times do |i|
        players[i].update_frame_interpolation_info if players[i].in_game
      end
      @thinkers.update_frame_interpolation_info

      @map.sectors.each do |sector|
        sector.update_frame_interpolation_info
      end

      Player::MAX_PLAYER_COUNT.times do |i|
        @player_behavior.player_think(players[i]) if players[i].in_game
      end

      @thinkers.run
      @specials.update
      @thing_allocation.respawn_specials

      @status_bar.update
      @auto_map.update

      @level_time += 1

      if @completed
        return UpdateResult::Completed
      else
        if @done_first_tic
          return UpdateResult::None
        else
          @done_first_tic = true
          return UpdateResult::NeedWipe
        end
      end
    end

    private def load_things
      @map.things.size.times do |i|
        mt = @map.things[i]

        should_spawn = true

        # Do not spawn cool, new monsters if not commercial.
        if @options.game_mode != GameMode::Commercial
          case mt.type
          # Arachnotron, Archvile, Boss Brain, Boss Shooter, Hell Knight
          # Mancubus, Pain Elemental, Former Human Commando, Revenant, Wolf SS
          when 68, 64, 88, 89, 69, 67, 71, 65, 66, 84
            should_spawn = false
            break
          end
        end

        break if !should_spawn

        @thing_allocation.spawn_map_thing(mt)
      end
    end

    def exit_level
      @secret_exit = false
      @completed = true
    end

    def secret_exit_level
      @secret_exit = true
      @completed = true
    end

    def start_sound(mobj : Mobj, sfx : Sfx, type : SfxType)
      @options.sound.as(Audio::ISound).start_sound(mobj, sfx, type)
    end

    def start_sound(mobj : Mobj, sfx : Sfx, type : SfxType, volume : Int32)
      @options.sound.as(Audio::ISound).start_sound(mobj, sfx, type, volume)
    end

    def stop_sound(mobj : Mobj)
      @options.sound.as(Audio::ISound).stop_sound(mobj)
    end

    def get_new_valid_count : Int32
      @valid_count += 1
      return @valid_count
    end

    def do_event(e : DoomEvent) : Bool
      @cheat.do_event(e) if !@options.net_game && !@options.demo_playback

      return true if @auto_map.visible && @auto_map.do_event(e)

      if e.key == DoomKey::Tab && e.type == EventType::KeyDown
        if @auto_map.visible
          @auto_map.close
        else
          @auto_map.open
          return true
        end
      end

      if e.key == DoomKey::F12 && e.type == EventType::KeyDown
        change_display_player() if @options.demo_playback || @options.deathmatch == 0
        return true
      end

      return false
    end

    def change_display_player
      @display_player += 1
      if (@display_player == Player::MAX_PLAYER_COUNT ||
         !@options.players[@display_player].in_game)
        @display_player = 0
      end
    end

    # In vanilla Doom, some action functions have possibilities
    # to access null pointers.
    # This function returns a dummy object if the pointer is null
    # so that we can avoid crash.
    # This safeguard is imported from Chocolate Doom.
    def subst_nil_mobj(mobj : Mobj | Nil) : Mobj
      if mobj == nil
        @dummy.as(Mobj).x = Fixed.zero
        @dummy.as(Mobj).y = Fixed.zero
        @dummy.as(Mobj).z = Fixed.zero
        @dummy.as(Mobj).flags = MobjFlags.new(0)
        return @dummy.as(Mobj)
      else
        return mobj.as(Mobj)
      end
    end
  end
end
