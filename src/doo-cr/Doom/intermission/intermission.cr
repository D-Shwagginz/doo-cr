module Doocr
  class Intermission
    getter options : GameOptions

    # Contains information passed into intermission.
    getter info : IntermissionInfo
    @scores : Array(PlayerScores)

    # Used to accelerate or skip a stage.
    @accelerate_stage : Bool

    # Specifies cureent state.
    @state : IntermissionState

    getter kill_count : Array(Int32)
    getter item_count : Array(Int32)
    getter secret_count : Array(Int32)
    getter frag_count : Array(Int32)
    getter time_count : Int32
    getter par_count : Int32
    @pause_count : Int32

    @sp_state : Int32

    @ng_state : Int32
    getter do_frags : Bool

    @dm_state : Int32
    getter dm_frag_count : Array(Array(Int32))
    getter dm_total_count : Array(Int32)

    getter random : DoomRandom
    getter animations : Array(Animation)
    getter show_you_are_here : Bool

    # Used for general timing.
    @count : Int32

    # Used for timing of background animation.
    @bg_count : Int32

    @completed : Bool

    def initialize(@options : GameOptions, @info : IntermissionInfo)
      @scores = info.players

      @kill_count = Array.new(Player::MAX_PLAYER_COUNT, 0)
      @item_count = Array.new(Player::MAX_PLAYER_COUNT, 0)
      @secret_count = Array.new(Player::MAX_PLAYER_COUNT, 0)
      @frag_count = Array.new(Player::MAX_PLAYER_COUNT, 0)

      @dm_frag_count = Array(Array(Int32)).new(Player::MAX_PLAYER_COUNT)
      Player::MAX_PLAYER_COUNT.times do |i|
        @dm_frag_count << Array(Int32).new(Player::MAX_PLAYER_COUNT)
      end
      @dm_total_count = Array.new(Player::MAX_PLAYER_COUNT, 0)

      if @options.deathmatch != 0
        init_deathmatch_stats()
      elsif @options.net_game
        init_net_game_stats()
      else
        init_single_player_stats()
      end

      @completed = false
    end

    #
    # Initialization
    #

    private def init_single_player_stats
      @state = IntermissionState::StatCount
      @accelerate_stage = false
      @sp_state = 1
      @kill_count[0] = -1
      @item_count[0] = -1
      @secret_count[0] = -1
      @time_count = -1
      @par_count = -1
      @pause_count = GameConst.tic_rate

      init_animated_back()
    end

    private def init_net_game_stats
      @state = IntermissionState::StatCount
      @accelerate_stage = false
      @ng_state = 1
      @pause_count = GameConst.tic_rate

      frags = 0
      Player::MAX_PLAYER_COUNT.times do |i|
        next if !@options.players[i].in_game

        @kill_count[i] = 0
        @item_count[i] = 0
        @secret_count[i] = 0
        @frag_count[i] = 0

        frags += get_frag_sum(i)
      end
      @do_frags = frags > 0

      init_animated_back()
    end

    private def init_deathmatch_stats
      @state = IntermissionState::StatCount
      @accelerate_stage = false
      @dm_state = 1
      @pause_count = GameConst.tic_rate

      Player::MAX_PLAYER_COUNT.times do |i|
        if @options.players[i].in_game
          Player::MAX_PLAYER_COUNT.times do |j|
            if @options.players[j].in_game
              @dm_frag_count[i][j] = 0
            end
            @dm_total_count[i] = 0
          end
        end
      end

      init_animated_back()
    end

    private def init_no_state
      @state = IntermissionState::NoState
      @accelerate_stage = false
      @count = 10
    end

    @@show_next_loc_delay : Int32 = 4

    private def init_show_next_loc
      @state = IntermissionState::ShowNextLoc
      @accelerate_stage = false
      @count = @@show_next_loc_delay * GameConst.tic_rate

      init_animated_back()
    end

    private def init_animated_back
      return if @options.game_mode == GameMode::Commercial

      return if @info.episode > 2

      if @animations == nil
        @animations = Array(Animation).new(ANimationInfo.episodes[@info.episode].size)
        @animations.size.times do |i|
          @animations[i] = Animation.new(self, AnimationInfo.episodes[@info.episode][i], i)
        end

        @random = DoomRandom.new
      end

      @animations.each do |animation|
        animation.reset(@bg_count)
      end
    end

    #
    # Update
    #

    def update : UpdateResult
      # Counter for general background animation.
      @bg_count += 1

      check_for_accelerate()

      if @bg_count == 1
        # intermission music
        if @options.game_mode == GameMode::Commercial
          @options.music.start_music(Bgm::DM2INT, true)
        else
          @options.music.start_music(Bgm::INTER, true)
        end
      end

      case @state
      when IntermissionState::StatCount
        if @options.deathmatch != 0
          update_deathmatch_stats()
        elsif @options.net_game
          update_net_game_stats()
        else
          update_single_player_stats()
        end
        break
      when IntermissionState::ShowNextLoc
        update_show_next_loc()
        break
      when IntermissionState::NoState
        update_no_state()
        break
      end

      if @completed
        return UpdateResult::Completed
      else
        if @bg_count == 1
          return UpdateResult::NeedWipe
        else
          return UpdateResult::None
        end
      end
    end

    private def update_single_player_stats
      update_animated_back()

      if @accelerate_stage && @sp_state != 10
        @accelerate_stage = false
        @kill_count[0] = @scores[0].kill_count * 100 / @info.max_kill_count
        @item_count[0] = @scores[0].item_count * 100 / @info.max_item_count
        @secret_count[0] = @scores[0].secret_count * 100 / @info.max_secret_count
        @time_count = @scores[0].time / GameConst.tic_rate
        @par_count = @info.par_time / GameConst.tic_rate
        start_sound(Sfx::BAREXP)
        @sp_state = 10
      end

      if @sp_state == 2
        @kill_count[0] += 2

        if (@bg_count & 3) == 0
          start_sound(Sfx::PISTOL)
        end

        if @kill_count[0] >= @scores[0].kill_count * 100 / @info.max_kill_count
          @kill_count[0] = @scores[0].kill_count * 100 / @info.max_kill_count
          start_sound(Sfx::BAREXP)
          @sp_state += 1
        end
      elsif @sp_state == 4
        @item_count[0] += 2

        if (@bg_count & 3) == 0
          start_sound(Sfx::PISTOL)
        end

        if @item_count[0] >= @scores[0].item_count * 100 / @info.max_item_count
          @item_count[0] = @scores[0].item_count * 100 / @info.max_item_count
          start_sound(Sfx::BAREXP)
          @sp_state += 1
        end
      elsif @sp_state == 6
        @secret_count[0] += 2

        if (@bg_count & 3) == 0
          start_sound(Sfx::PISTOL)
        end

        if @secret_count[0] >= @scores[0].secret_count * 100 / @info.max_secret_count
          @secret_count[0] = @scores[0].secret_count * 100 / @info.max_secret_count
          start_sound(Sfx::BAREXP)
          @sp_state += 1
        end
      elsif @sp_state == 8
        if (@bg_count & 3) == 0
          start_sound(Sfx::PISTOL)
        end

        @time_count += 3

        if @time_count >= @scores[0].time / GameConst.tic_rate
          @time_count = @scores[0].time / GameConst.tic_rate
        end

        @par_count += 3

        if @par_count >= @info.par_time / GameConst.tic_rate
          @par_count = @info.par_time / GameConst.tic_rate

          if @time_count >= @scores[0].time / GameConst.tic_rate
            start_sound(Sfx::BAREXP)
            @sp_state += 1
          end
        end
      elsif @sp_state == 10
        if @accelerate_stage
          start_sound(Sfx::SGCOCK)

          if @options.game_mode == GameMode::Commercial
            init_no_state()
          else
            init_show_next_loc()
          end
        end
      elsif (@sp_state & 1) != 0
        @pause_count -= 1
        if @pause_count == 0
          @sp_state += 1
          @pause_count = GameConst.tic_rate
        end
      end
    end

    private def update_net_game_stats
      update_animated_back()

      still_ticking : Bool

      if @accelerate_stage && @ng_state != 10
        @accelerate_stage = false

        Player::MAX_PLAYER_COUNT.times do |i|
          next if !@options.players[i].in_game

          @kill_count[0] = @scores[0].kill_count * 100 / @info.max_kill_count
          @item_count[0] = @scores[0].item_count * 100 / @info.max_item_count
          @secret_count[0] = @scores[0].secret_count * 100 / @info.max_secret_count
        end

        start_sound(Sfx::BAREXP)

        @ng_state = 10
      end

      if @ng_state == 2
        if (@bg_count & 3) == 0
          start_sound(Sfx::PISTOL)
        end

        still_ticking = false

        Player::MAX_PLAYER_COUNT.times do |i|
          next if !options.players[i].in_game

          @kill_count[i] += 2
          if @kill_count[i] >= scores[i].kill_count * 100 / info.max_kill_count
            @kill_count[i] = scores[i].kill_count * 100 / info.max_kill_count
          else
            still_ticking = true
          end
        end

        if !still_ticking
          start_sound(Sfx::BAREXP)
          @ng_state += 1
        end
      elsif @ng_state == 4
        if (@bg_count & 3) == 0
          start_sound(Sfx::PISTOL)
        end

        still_ticking == false

        Player::MAX_PLAYER_COUNT.times do |i|
          next if !@options.players[i].in_game

          @item_count[i] += 2
          if @item_count[i] >= scores[i].item_count * 100 / info.max_item_count
            @item_count[i] = scores[i].item_count * 100 / info.max_item_count
          else
            still_ticking = true
          end
        end

        if !still_ticking
          start_sound(Sfx::BAREXP)
          @ng_state += 1
        end
      elsif @ng_state == 6
        if (@bg_count & 3) == 0
          start_sound(Sfx::PISTOL)
        end

        still_ticking == false

        Player::MAX_PLAYER_COUNT.times do |i|
          next if !@options.players[i].in_game

          @secret_count[i] += 2
          if @secret_count[i] >= scores[i].secret_count * 100 / info.max_secret_count
            @secret_count[i] = scores[i].secret_count * 100 / info.max_secret_count
          else
            still_ticking = true
          end
        end

        if !still_ticking
          start_sound(Sfx::BAREXP)
          if @do_frags
            @ng_state += 1
          else
            @ng_state += 3
          end
        end
      elsif @ng_state == 8
        if (@bg_count & 3) == 0
          start_sound(Sfx::PISTOL)
        end

        still_ticking = false

        Player::MAX_PLAYER_COUNT.times do |i|
          next if !options.players[i].in_game

          @frag_count[i] += 1
          sum = get_frag_sum(i)
          if @frag_count[i] >= sum
            @kill_count[i] = sum
          else
            still_ticking = true
          end
        end

        if !still_ticking
          start_sound(Sfx::PLDETH)
          @ng_state += 1
        end
      elsif @ng_state == 10
        if @accelerate_stage
          start_sound(Sfx::SGCOCK)

          if @options.game_mode == GameMode::Commercial
            init_no_state()
          else
            init_show_next_loc()
          end
        end
      elsif (@ng_state & 1) != 0
        @pause_count -= 1
        if @pause_count == 0
          @ng_state += 1
          @pause_count = GameConst.tic_rate
        end
      end
    end

    private def update_deathmatch_stats
      update_animated_back()

      still_ticking : Bool

      if @accelerate_stage && @dm_state != 4
        @accelerate_stage = false

        Player::MAX_PLAYER_COUNT.times do |i|
          if @options.players[i].in_game
            Player::MAX_PLAYER_COUNT.times do |j|
              if @options.players[j].in_game
                @dm_frag_count[i][j] = @scores[i].frags[j]
              end
            end

            @dm_total_count[i] = get_frag_sum(i)
          end
        end

        start_sound(Sfx::BAREXP)

        @dm_state = 4
      end

      if @dm_state == 2
        if (@bg_count & 3) == 0
          start_sound(Sfx::PISTOL)
        end

        still_ticking = false

        Player::MAX_PLAYER_COUNT.times do |i|
          if @options.players[i].in_game
            Players.max_player_count.tims do |j|
              if @options.players[j].in_game && @dm_frag_count[i][j] != @scores[i].frags[j]
                if @scores[i].frags[j] < 0
                  @dm_frag_count[i][j] -= 1
                else
                  @dm_frag_count[i][j] += 1
                end

                if @dm_frag_count[i][j] > 99
                  @dm_frag_count[i][j] = 99
                end

                if @dm_frag_count[i][j] < -99
                  @dm_frag_count[i][j] = -99
                end

                still_ticking = true
              end
            end

            @dm_total_count[i] = get_frag_sum(i)

            if @dm_total_count[i] > 99
              @dm_total_count[i] = 99
            end

            if @dm_total_count[i] < -99
              @dm_total_count[i] = -99
            end
          end
        end

        if !still_ticking
          start_sound(Sfx::BAREXP)
          @dm_state += 1
        end
      elsif @dm_state == 4
        if @accelerate_stage
          start_sound(Sfx::SLOP)

          if @options.game_mode == GameMode::Commercial
            init_no_state()
          else
            init_show_next_loc()
          end
        end
      elsif (@dm_state & 1) != 0
        @pause_count -= 1
        if @pause_count == 0
          @dm_state += 1
          @pause_count = GameConst.tic_rate
        end
      end
    end

    private def update_show_next_loc
      update_animated_back()

      @count -= 1
      if @count == 0 || @accelerate_stage
        init_no_state()
      else
        @show_you_are_here = (@count & 31) < 20
      end
    end

    private def update_no_state
      update_animated_back()

      @count -= 1
      if @count == 0
        @completed = true
      end
    end

    private def update_animated_back
      return if @options.game_mode == GameMode::Commercial
      return if @info.episode > 2
      @animations.each do |a|
        a.update(@bg_count)
      end
    end

    #
    # Check for button press
    #

    private def check_for_accelerate
      # Check for button presses to skip delays.
      Player::MAX_PLAYER_COUNT.times do |i|
        player = @options.players[i]
        if player.in_game
          if (player.cmd.buttons & TicCmdButtons.attack) != 0
            if !player.attack_down
              @accelerate_stage = true
            end
            player.attack_down = true
          else
            player.attack_down = false
          end

          if (player.cmd.buttons & TicCmdButtons.use) != 0
            if !player.use_down
              @accelerate_stage = true
            end
            player.use_down = true
          else
            player.use_down = false
          end
        end
      end
    end

    #
    # Miscellaneous functions
    #

    private def get_frag_sum(player_number : Int32) : Int32
      frags = 0

      Player::MAX_PLAYER_COUNT.times do |i|
        if @options.players[i].in_game && i != player_number
          frags += @scores[player_number].frags[i]
        end
      end

      frags -= @scores[player_number].frags[player_number]

      return frags
    end

    private def start_sound(sfx : Sfx)
      @options.sound.start_sound(sfx)
    end
  end
end
