module Doocr
  class DoomGame
    @content : GameContent
    getter options : GameOptions

    @game_action : GameAction
    getter game_state : GameState

    @game_tic : Int32

    getter world : World
    getter intermission : Intermission
    getter finale : Finale

    getter paused : Bool

    @load_game_slot_number : Int32
    @save_game_slot_number : Int32
    @save_game_description : String

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
        case GameAction
        when GameAction::LoadLevel
          do_load_level()
          break
        when GameAction::NewGame
          do_new_game()
          break
        when GameAction::LoadGame
          do_load_game()
          break
        when GameAction::SaveGame
          do_save_game()
          break
        when GameAction::Completed
          do_completed()
          break
        when GameAction::Victory
          do_finale()
          break
        when GameAction::WorldDone
          do_world_done()
          break
        when GameAction::Nothing
          break
        end
      end

      Player::MAX_PLAYER_COUNT.times do |i|
        if players[i].in_game
          cmd = players[i].cmd
          cmd.copy_from(cmds[i])

          # Check for turbo cheats.
          if (cmd.forward_move > GameConst.turbo_threshold &&
             (@world.level_time & 31) == 0 &&
             ((@world.level_time >> 5) & 3) == i)
            player = players[@options.console_player]
            player.send_message(players[i].name + " is turbo!")
          end
        end
      end

      # Check for special buttons.
      Player::MAX_PLAYER_COUNT.times do |i|
        if players[i].in_game
          if (players[i].cmd.buttons & TicCmdButtons.special) != 0
            if (players[i].cmd.buttons & TicCmdButtons.special_mask) == TicCmdButtons.pause
              @paused = !@paused
              if @paused
                @options.sound.pause
              else
                @options.sound.resume
              end
            end
          end
        end
      end

      # Do main actions.
      result = UpdateResult::None
      case @game_state
      when GameState::Level
        if !@paused || @world.first_tic_is_not_yet_done
          result = @world.update
          if result == UpdateResult::Completed
            @game_action = GameAction::Completed
          end
        end
        break
      when GameState::Intermission
        result = @intermission.update
        if result == UpdateResult::Completed
          @game_action = GameAction::WorldDone

          if @world.secret_exit
            players[@options.console_player].did_secret = true
          end

          if @options.game_mode == GameMode::Commercial
            case @options.map
            when 6, 11, 20, 30
              do_finale()
              result = UpdateResult::NeedWipe
              break
            when 15, 31
              if @world.secret_exit
                do_finale
                result = UpdateResult::NeedWipe
              end
              break
            end
          end
        end
        break
      when GameState::Finale
        result = @finale.update
        if result == UpdateResult::Completed
          @game_action = GameAction::WorldDone
        end
        break
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
        player[i].frags.fill(0)
      end

      @intermission = nil

      @options.sound.reset

      @world = World.new(@content, @options, self)

      @options.user_input.reset
    end

    private def do_new_game
      @game_action = GameAction::Nothing

      init_new(@options.skill, @options.episode, @options.map)
    end

    private def do_load_game
      @game_action = GameAction::Nothing

      directory = ConfigUtilities.get_exe_directory
      path = Path.new(directory, "doomsav" + @load_game_slot_number + ".dsg")
      SaveAndLoad.load(self, path)
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
          break
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

      im_info = @options.intermission_info

      im_info.did_secret = @options.players[@options.console_player].did_secret
      im_info.episode = @options.episode - 1
      im_info.last_level = @options.map - 1

      # IntermissionInfo.Next is 0 biased, unlike GameOptions.Map.
      if @options.game_mode == GameMode::Commercial
        if @world.secret_exit
          case @options.map
          when 15
            im_info.next_level = 30
            break
          when 31
            im_info.next_level = 31
            break
          end
        else
          case @options.map
          when 31, 32
            im_info.next_level = 15
            break
          else im_info.next_level = @options.map
          break
          end
        end
      else
        if @world.sector_exit
          # Go to secret level.
          im_info.next_level = 8
        elsif @options.map == 9
          # Returning from secret level.
          case @options.episode
          when 1
            im_info.next_level = 3
            break
          when 2
            im_info.next_level = 5
            break
          when 3
            im_info.next_level = 6
            break
          when 4
            im_info.next_level = 2
            break
          end
        else
          # Go to next level.
          im_info.next_level = @options.map
        end
      end

      im_info.max_kill_count = @world.total_kills
      im_info.max_item_count = @world.total_items
      im_info.max_secret_count = @world.total_secrets
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
        im_info.players[i].time = @world.level_time
        im_info.players[i].frags = players[i].frags[..Player::MAX_PLAYER_COUNT]
      end

      @game_state = GameState::Intermission
      @intermission = Intermission.new(@options, im_info)
    end

    private def do_world_done
      @game_action = GameAction::Nothing

      @game_state = GameState::Level
      @options.map = @options.intermission_info.next_level + 1
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
      @options.skill = GameSkill.new(Math.clamp(skill.to_i32, GameSkill::Baby.to_i32, GameSkill::Nightmare.to_i32))

      if @options.game_mode == GameMode::Retail
        @options.episode = Math.clamp(episode, 1, 4)
      elsif @options.game_mode == GameMode::Shareware
        @options.episode = 1
      else
        @options.episode = Math.clamp(episode, 1, 4)
      end

      if @options.game_mode == GameMode::Commercial
        @options.map = Math.clamp(map, 1, 32)
      else
        @options.map = Math.clamp(map, 1, 9)
      end

      @options.random.clear

      # Force players to be initialized upon first level load.
      Player::MAX_PLAYER_COUNT.times do |i|
        @options.players[i].player_state = PlayerState::Reborn
      end

      do_load_level()
    end

    def do_event(e : DoomEvent) : Bool
      if @game_state == GameState::Level
        return @world.do_event(e)
      elsif @game_state == GameState::Finale
        return @finale.do_event(e)
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
        @options.players[player_number].mobj_player = nil

        ta = @world.thing_allocation

        # Spawn at random spot if in death match.
        if @options.deathmatch != 0
          ta.death_match_spawn_player(player_number)
          return
        end

        if ta.check_spot(player_number, ta.player_starts[player_number])
          ta.spawn_player(ta.player_starts[player_number])
          return
        end

        # Try to spawn at one of the other players spots.
        Player::MAX_PLAYER_COUNT.times do |i|
          if ta.check_spot(player_number, ta.player_starts[i])
            # Fake as other player
            ta.player_starts[i].type = player_number + 1

            @world.thing_allocation.spawn_player(ta.player_starts[i])

            # Restore.
            ta.player_starts[i].type = i + 1

            return
          end
        end

        # He's going to be inside something.
        # Too bad.
        @world.thing_allocation.spawn_player(ta.player_starts[player_number])
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
