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
  class DoomGame
    @content : GameContent
    getter options : GameOptions

    @game_action : GameAction = GameAction.new(0)
    getter game_state : GameState = GameState.new(0)

    getter game_tic : Int32 = 0

    getter world : World | Nil = nil
    getter intermission : Intermission | Nil = nil
    getter finale : Finale | Nil = nil

    getter paused : Bool = false

    @load_game_slot_number : Int32 = 0
    @save_game_slot_number : Int32 = 0
    @save_game_description : String | Nil = nil

    def initialize(@content : GameContent, @options : GameOptions)
      @game_action = GameAction::Nothing
      @game_tic = 0
    end

    #
    # Public methods to control the game state
    #

    # Start a new game.
    # Can be called by the startup code or the menu task.

    def defered_init_new
      @game_action = GameAction::NewGame
    end

    # Start a new game.
    # Can be called by the startup code or the menu task.
    def defered_init_new(skill : GameSkill, episode : Int32, map : Int32)
      @options.skill = skill
      @options.episode = episode
      @options.map = map
      @game_action = GameAction::NewGame
    end

    # Load the saved game at the given slot number.
    # Can be called by the startup code or the menu task.
    def load_game(slot_number : Int32)
      @load_game_slot_number = slot_number
      @game_action = GameAction::LoadGame
    end

    # Save the game at the given slot number.
    # Can be called by the startup code or the menu task.
    def save_game(slot_number : Int32, description : String)
      @save_game_slot_number = slot_number
      @save_game_description = description
      @game_action = GameAction::SaveGame
    end

    # Advance the game one frame.
    def update(cmds : Array(TicCmd)) : UpdateResult
      # Do player reborns if needed.
      players = @options.players
      Player::MAX_PLAYER_COUNT.times do |i|
        if players[i].in_game && players[i].player_state == PlayerState::Reborn
          do_reborn(i)
        end
      end

      # Do things to change the game state.
      while @game_action != GameAction::Nothing
        case @game_action
        when GameAction::LoadLevel
          do_load_level()
        when GameAction::NewGame
          do_new_game()
        when GameAction::LoadGame
          do_load_game()
        when GameAction::SaveGame
          do_save_game()
        when GameAction::Completed
          do_completed()
        when GameAction::Victory
          do_finale()
        when GameAction::WorldDone
          do_world_done()
        when GameAction::Nothing
        end
      end

      Player::MAX_PLAYER_COUNT.times do |i|
        if players[i].in_game
          cmd = players[i].cmd.as(TicCmd)
          cmd.copy_from(cmds[i])

          # Check for turbo cheats.
          if (cmd.forward_move > GameConst.turbo_threshold &&
             (@world.as(World).level_time & 31) == 0 &&
             ((@world.as(World).level_time >> 5) & 3) == i)
            player = players[@options.console_player]
            player.send_message("#{players[i].name} is turbo!")
          end
        end
      end

      # Check for special buttons.
      Player::MAX_PLAYER_COUNT.times do |i|
        if players[i].in_game
          if (players[i].cmd.as(TicCmd).buttons & TicCmdButtons.special).to_i32 != 0
            if (players[i].cmd.as(TicCmd).buttons & TicCmdButtons.special_mask) == TicCmdButtons.pause
              @paused = !@paused
              if @paused
                @options.sound.as(Audio::ISound).pause
              else
                @options.sound.as(Audio::ISound).resume
              end
            end
          end
        end
      end

      # Do main actions.
      result = UpdateResult::None
      case @game_state
      when GameState::Level
        if !@paused || @world.as(World).first_tic_is_not_yet_done
          result = @world.as(World).update
          if result == UpdateResult::Completed
            @game_action = GameAction::Completed
          end
        end
      when GameState::Intermission
        result = @intermission.as(Intermission).update
        if result == UpdateResult::Completed
          @game_action = GameAction::WorldDone

          if @world.as(World).secret_exit
            players[@options.console_player].did_secret = true
          end

          if @options.game_mode == GameMode::Commercial
            case @options.map
            when 6, 11, 20, 30
              do_finale()
              result = UpdateResult::NeedWipe
            when 15, 31
              if @world.as(World).secret_exit
                do_finale
                result = UpdateResult::NeedWipe
              end
            end
          end
        end
      when GameState::Finale
        result = @finale.as(Finale).update
        if result == UpdateResult::Completed
          @game_action = GameAction::WorldDone
        end
      end

      @game_tic += 1

      if result == UpdateResult::NeedWipe
        return UpdateResult::NeedWipe
      else
        return UpdateResult::None
      end
    end

    #
    # Actual game actions
    #

    # It seems that these methods should not be called directly
    # from outside for some reason.
    # So if you want to start a new game or do load / save, use
    # the following public methods.
    #
    #     - DeferedInitNew
    #     - LoadGame
    #     - SaveGame

    private def do_load_level
      @game_action = GameAction::Nothing

      @game_state = GameState::Level

      players = @options.players
      Player::MAX_PLAYER_COUNT.times do |i|
        if players[i].in_game && players[i].player_state == PlayerState::Dead
          players[i].player_state = PlayerState::Reborn
        end
        players[i].frags.fill(0)
      end

      @intermission = nil

      @options.sound.as(Audio::ISound).reset

      @world = World.new(@content, @options, self)

      @options.user_input.as(UserInput::IUserInput).reset
    end

    private def do_new_game
      @game_action = GameAction::Nothing

      init_new(@options.skill, @options.episode, @options.map)
    end

    private def do_load_game
      @game_action = GameAction::Nothing

      directory = ConfigUtilities.get_exe_directory
      path = Path.new(directory, "doomsav#{@load_game_slot_number}.dsg")
      SaveAndLoad.load(self, path.to_s)
    end

    private def do_save_game
      @game_action = GameAction::Nothing

      directory = ConfigUtilities.get_exe_directory
      path = Path[directory, "doomsav#{@save_game_slot_number}.dsg"]
      description = @save_game_description.nil? ? "NIL" : @save_game_description.as(String)
      SaveAndLoad.save(self, description, path.to_s)
      @world.as(World).console_player.send_message(DoomInfo::Strings::GGSAVED)
    end

    private def do_completed
      @game_action = GameAction::Nothing

      Player::MAX_PLAYER_COUNT.times do |i|
        if @options.players[i].in_game
          # Take away cards and stuff
          @options.players[i].finish_level
        end
      end

      if @options.game_mode != GameMode::Commercial
        case @options.map
        when 8
          @game_action = GameAction::Victory
          return
        when 9
          Player::MAX_PLAYER_COUNT.times do |i|
            @options.players[i].did_secret = true
          end
        end
      end

      if (@options.map == 8) && (@options.game_mode != GameMode::Commercial)
        # Victory.
        @game_action = GameAction::Victory
        return
      end

      if (@options.map == 9) && (@options.game_mode != GameMode::Commercial)
        # Exit secret level.
        Player::MAX_PLAYER_COUNT.times do |i|
          @options.players[i].did_secret = true
        end
      end

      im_info = @options.intermission_info.as(IntermissionInfo)

      im_info.did_secret = @options.players[@options.console_player].did_secret
      im_info.episode = @options.episode - 1
      im_info.last_level = @options.map - 1

      # IntermissionInfo.Next is 0 biased, unlike GameOptions.Map.
      if @options.game_mode == GameMode::Commercial
        if @world.as(World).secret_exit
          case @options.map
          when 15
            im_info.next_level = 30
          when 31
            im_info.next_level = 31
          end
        else
          case @options.map
          when 31, 32
            im_info.next_level = 15
          else im_info.next_level = @options.map
          end
        end
      else
        if @world.as(World).secret_exit
          # Go to secret level.
          im_info.next_level = 8
        elsif @options.map == 9
          # Returning from secret level.
          case @options.episode
          when 1
            im_info.next_level = 3
          when 2
            im_info.next_level = 5
          when 3
            im_info.next_level = 6
          when 4
            im_info.next_level = 2
          end
        else
          # Go to next level.
          im_info.next_level = @options.map
        end
      end

      im_info.max_kill_count = @world.as(World).total_kills
      im_info.max_item_count = @world.as(World).total_items
      im_info.max_secret_count = @world.as(World).total_secrets
      im_info.total_frags = 0
      if @options.game_mode == GameMode::Commercial
        im_info.par_time = 35 * DoomInfo::ParTimes.doom2[@options.map - 1]
      else
        im_info.par_time = 35 * DoomInfo::ParTimes.doom1[@options.episode - 1][@options.map - 1]
      end

      players = @options.players
      Player::MAX_PLAYER_COUNT.times do |i|
        im_info.players[i].in_game = players[i].in_game
        im_info.players[i].kill_count = players[i].kill_count
        im_info.players[i].item_count = players[i].item_count
        im_info.players[i].secret_count = players[i].secret_count
        im_info.players[i].time = @world.as(World).level_time
        im_info.players[i].frags = players[i].frags.dup
      end

      @game_state = GameState::Intermission
      @intermission = Intermission.new(@options, im_info)
    end

    private def do_world_done
      @game_action = GameAction::Nothing

      @game_state = GameState::Level
      @options.map = @options.intermission_info.as(IntermissionInfo).next_level + 1
      do_load_level()
    end

    private def do_finale
      @game_action = GameAction::Nothing

      @game_state = GameState::Finale
      @finale = Finale.new(@options)
    end

    #
    # Miscellaneous things
    #

    def init_new(skill : GameSkill, episode : Int32, map : Int32)
      @options.skill = GameSkill.new(skill.to_i32.clamp(GameSkill::Baby.to_i32, GameSkill::Nightmare.to_i32))

      if @options.game_mode == GameMode::Retail
        @options.episode = episode.clamp(1, 4)
      elsif @options.game_mode == GameMode::Shareware
        @options.episode = 1
      else
        @options.episode = episode.clamp(1, 4)
      end

      if @options.game_mode == GameMode::Commercial
        @options.map = map.clamp(1, 32)
      else
        @options.map = map.clamp(1, 9)
      end

      @options.random.as(DoomRandom).clear

      # Force players to be initialized upon first level load.
      Player::MAX_PLAYER_COUNT.times do |i|
        @options.players[i].player_state = PlayerState::Reborn
      end

      do_load_level()
    end

    def do_event(e : DoomEvent) : Bool
      if @game_state == GameState::Level
        return @world.as(World).do_event(e)
      elsif @game_state == GameState::Finale
        return @finale.as(Finale).do_event(e)
      end

      return false
    end

    private def do_reborn(player_number : Int32)
      if !@options.net_game
        # Reload the level from scratch
        @game_action = GameAction::LoadLevel
      else
        # Respawn at the start

        # First dissasociate the corpse.
        @options.players[player_number].mobj = nil

        ta = @world.as(World).thing_allocation.as(ThingAllocation)

        # Spawn at random spot if in death match.
        if @options.deathmatch != 0
          ta.as(ThingAllocation).death_match_spawn_player(player_number)
          return
        end

        if ta.as(ThingAllocation).check_spot(player_number, ta.as(ThingAllocation).player_starts[player_number].as(MapThing))
          ta.as(ThingAllocation).spawn_player(ta.as(ThingAllocation).player_starts[player_number].as(MapThing))
          return
        end

        # Try to spawn at one of the other players spots.
        Player::MAX_PLAYER_COUNT.times do |i|
          if ta.as(ThingAllocation).check_spot(player_number, ta.as(ThingAllocation).player_starts[i].as(MapThing))
            # Fake as other player
            ta.as(ThingAllocation).player_starts[i].as(MapThing).type = player_number + 1

            @world.as(World).thing_allocation.as(ThingAllocation).spawn_player(ta.as(ThingAllocation).player_starts[i].as(MapThing))

            # Restore.
            ta.as(ThingAllocation).player_starts[i].as(MapThing).type = i + 1

            return
          end
        end

        # He's going to be inside something.
        # Too bad.
        @world.as(World).thing_allocation.as(ThingAllocation).spawn_player(ta.as(ThingAllocation).player_starts[player_number].as(MapThing))
      end
    end

    private enum GameAction
      Nothing
      LoadLevel
      NewGame
      LoadGame
      SaveGame
      Completed
      Victory
      WorldDone
    end
  end
end
