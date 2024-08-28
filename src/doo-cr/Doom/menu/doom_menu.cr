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
  class DoomMenu
    getter doom : Doom

    @main : SelectableMenu | Nil = nil
    @episode_menu : SelectableMenu | Nil = nil
    @skill_menu : SelectableMenu | Nil = nil
    @option_menu : SelectableMenu | Nil = nil
    @volume : SelectableMenu | Nil = nil
    @load : LoadMenu | Nil = nil
    @save : SaveMenu | Nil = nil
    @help : HelpScreen | Nil = nil

    @this_is_shareware : PressAnyKey | Nil = nil
    @save_failed : PressAnyKey | Nil = nil
    @nightmare_confirm : YesNoConfirm | Nil = nil
    @end_game_confirm : YesNoConfirm | Nil = nil
    @quit_confirm : QuitConfirm | Nil = nil

    getter current : MenuDef | Nil = nil

    getter active : Bool = false

    getter tics : Int32 = 0

    @selected_episode : Int32 = 0

    getter save_slots : SaveSlots | Nil = nil

    def options : GameOptions
      return @doom.options
    end

    def initialize(@doom)
      @this_is_shareware = PressAnyKey.new(
        self,
        DoomInfo::Strings::SWSTRING,
        nil
      )

      @save_failed = PressAnyKey.new(
        self,
        DoomInfo::Strings::SAVEDEAD,
        nil
      )

      @nightmare_confirm = YesNoConfirm.new(
        self,
        DoomInfo::Strings::NIGHTMARE,
        ->{ @doom.new_game(GameSkill::Nightmare, @selected_episode, 1) }
      )

      @end_game_confirm = YesNoConfirm.new(
        self,
        DoomInfo::Strings::ENDGAME,
        ->{ @doom.end_game }
      )

      @quit_confirm = QuitConfirm.new(
        self,
        @doom
      )

      @skill_menu = SelectableMenu.new(
        self,
        "M_NEWG", 96, 14,
        "M_SKILL", 54, 38,
        2,

        SimpleMenuItem.new(
          "M_JKILL", 16, 58, 48, 63,
          ->{ @doom.new_game(GameSkill::Baby, @selected_episode, 1) },
          nil),

        SimpleMenuItem.new(
          "M_ROUGH", 16, 74, 48, 79,
          ->{ doom.new_game(GameSkill::Easy, @selected_episode, 1) },
          nil),

        SimpleMenuItem.new(
          "M_HURT", 16, 90, 48, 95,
          ->{ doom.new_game(GameSkill::Medium, @selected_episode, 1) },
          nil),

        SimpleMenuItem.new(
          "M_ULTRA", 16, 106, 48, 111,
          ->{ doom.new_game(GameSkill::Hard, @selected_episode, 1) },
          nil),

        SimpleMenuItem.new(
          "M_NMARE", 16, 122, 48, 127,
          nil,
          @nightmare_confirm
        ))

      if @doom.options.game_mode == GameMode::Retail
        @episode_menu = SelectableMenu.new(
          self,
          "M_EPISOD", 54, 38,
          0,

          SimpleMenuItem.new(
            "M_EPI1", 16, 58, 48, 63,
            ->{ @selected_episode = 1 },
            @skill_menu),

          SimpleMenuItem.new(
            "M_EPI2", 16, 74, 48, 79,
            ->{ @selected_episode = 2 },
            @skill_menu),

          SimpleMenuItem.new(
            "M_EPI3", 16, 90, 48, 95,
            ->{ @selected_episode = 3 },
            @skill_menu),

          SimpleMenuItem.new(
            "M_EPI4", 16, 106, 48, 111,
            ->{ @selected_episode = 4 },
            @skill_menu)
        )
      else
        if @doom.options.game_mode == GameMode::Shareware
          @episode_menu = SelectableMenu.new(
            self,
            "M_EPISOD", 54, 38,
            0,

            SimpleMenuItem.new(
              "M_EPI1", 16, 58, 48, 63,
              ->{ @selected_episode = 1 },
              @skill_menu),

            SimpleMenuItem.new(
              "M_EPI2", 16, 74, 48, 79,
              nil,
              @this_is_shareware),

            SimpleMenuItem.new(
              "M_EPI3", 16, 90, 48, 95,
              nil,
              @this_is_shareware)
          )
        else
          @episode_menu = SelectableMenu.new(
            self,
            "M_EPISOD", 54, 38,
            0,

            SimpleMenuItem.new(
              "M_EPI1", 16, 58, 48, 63,
              ->{ @selected_episode = 1 },
              @skill_menu),

            SimpleMenuItem.new(
              "M_EPI2", 16, 74, 48, 79,
              ->{ @selected_episode = 2 },
              @skill_menu),

            SimpleMenuItem.new(
              "M_EPI3", 16, 90, 48, 95,
              ->{ @selected_episode = 3 },
              @skill_menu)
          )
        end
      end

      sound = @doom.options.sound.as(Audio::ISound)
      music = @doom.options.music.as(Audio::IMusic)
      @volume = SelectableMenu.new(
        self,
        "M_SVOL", 60, 38,
        0,

        SliderMenuItem.new(
          "M_SFXVOL", 48, 59, 80, 64,
          sound.max_volume + 1,
          ->{ sound.volume },
          ->(vol : Int32) { sound.volume = vol }
        ),

        SliderMenuItem.new(
          "M_MUSVOL", 48, 91, 80, 96,
          music.max_volume + 1,
          ->{ music.volume },
          ->(vol : Int32) { music.volume = vol }
        )
      )

      video = @doom.options.video.as(Video::IVideo)
      user_input = @doom.options.user_input.as(UserInput::IUserInput)
      @option_menu = SelectableMenu.new(
        self,
        "M_OPTTTL", 108, 15,
        0,

        SimpleMenuItem.new(
          "M_ENDGAM", 28, 32, 60, 37,
          nil,
          @end_game_confirm,
          ->{ @doom.current_state == DoomState::Game }),

        ToggleMenuItem.new(
          "M_MESSG", 28, 48, 60, 53, "M_MSGON", "M_MSGOFF", 180,
          ->{ video.display_message ? 0 : 1 },
          ->(value : Int32) { video.display_message = value == 0 }),

        SliderMenuItem.new(
          "M_SCRNSZ", 28, 80 - 16, 60, 85 - 16,
          video.max_window_size + 1,
          ->{ video.window_size },
          ->(size : Int32) { video.window_size = size }),

        SliderMenuItem.new(
          "M_MSENS", 28, 112 - 16, 60, 117 - 16,
          user_input.max_mouse_sensitivity + 1,
          ->{ user_input.mouse_sensitivity },
          ->(ms : Int32) { user_input.mouse_sensitivity = ms }),

        SimpleMenuItem.new(
          "M_SVOL", 28, 144 - 16, 60, 149 - 16,
          nil,
          @volume)
      )

      @load = LoadMenu.new(
        self,
        "M_LOADG", 72, 28,
        0,
        TextBoxMenuItem.new(48, 49, 72, 61),
        TextBoxMenuItem.new(48, 65, 72, 77),
        TextBoxMenuItem.new(48, 81, 72, 93),
        TextBoxMenuItem.new(48, 97, 72, 109),
        TextBoxMenuItem.new(48, 113, 72, 125),
        TextBoxMenuItem.new(48, 129, 72, 141)
      )

      @save = SaveMenu.new(
        self,
        "M_SAVEG", 72, 28,
        0,
        TextBoxMenuItem.new(48, 49, 72, 61),
        TextBoxMenuItem.new(48, 65, 72, 77),
        TextBoxMenuItem.new(48, 81, 72, 93),
        TextBoxMenuItem.new(48, 97, 72, 109),
        TextBoxMenuItem.new(48, 113, 72, 125),
        TextBoxMenuItem.new(48, 129, 72, 141)
      )
      @help = HelpScreen.new(self)

      if @doom.options.game_mode == GameMode::Commercial
        @main = SelectableMenu.new(
          self,
          "M_DOOM", 94, 2,
          0,
          SimpleMenuItem.new("M_NGAME", 65, 67, 97, 72, nil, @skill_menu),
          SimpleMenuItem.new("M_OPTION", 65, 83, 97, 88, nil, @option_menu),
          SimpleMenuItem.new("M_LOADG", 65, 99, 97, 104, nil, @load),
          SimpleMenuItem.new("M_SAVEG", 65, 115, 97, 120, nil, @save,
            ->{ !(doom.current_state == DoomState::Game && doom.game.as(DoomGame).game_state != GameState::Level) }),
          SimpleMenuItem.new("M_QUITG", 65, 131, 97, 136, nil, @quit_confirm)
        )
      else
        @main = SelectableMenu.new(
          self,
          "M_DOOM", 94, 2,
          0,
          SimpleMenuItem.new("M_NGAME", 65, 59, 97, 64, nil, @episode_menu),
          SimpleMenuItem.new("M_OPTION", 65, 75, 97, 80, nil, @option_menu),
          SimpleMenuItem.new("M_LOADG", 65, 91, 97, 96, nil, @load),
          SimpleMenuItem.new("M_SAVEG", 65, 107, 97, 112, nil, @save,
            ->{ !(doom.current_state == DoomState::Game && doom.game.as(DoomGame).game_state != GameState::Level) }),
          SimpleMenuItem.new("M_RDTHIS", 65, 123, 97, 128, nil, @help),
          SimpleMenuItem.new("M_QUITG", 65, 139, 97, 144, nil, @quit_confirm)
        )
      end

      @current = @main
      @active = false

      @tics = 0

      @selected_episode = 1

      @save_slots = SaveSlots.new
    end

    def do_event(e : DoomEvent) : Bool
      if @active
        return true if @current.as(MenuDef).do_event(e)

        close() if e.key == DoomKey::Escape && e.type == EventType::KeyDown

        return true
      else
        if e.key == DoomKey::Escape && e.type == EventType::KeyDown
          set_current(@main.as(MenuDef))
          open()
          start_sound(Sfx::SWTCHN)
          return true
        end

        if e.type == EventType::KeyDown && @doom.current_state == DoomState::Opening
          if (e.key == DoomKey::Enter ||
             e.key == DoomKey::Space ||
             e.key == DoomKey::LControl ||
             e.key == DoomKey::RControl ||
             e.key == DoomKey::Escape)
            set_current(@main.as(MenuDef))
            open()
            start_sound(Sfx::SWTCHN)
            return true
          end
        end

        return false
      end
    end

    def update
      @tics += 1

      @current.as(MenuDef).update if @current != nil

      @doom.pause_game if @active && !@doom.options.net_game
    end

    def set_current(nextm : MenuDef)
      @current = nextm
      @current.as(MenuDef).open
    end

    def open
      @active = true
    end

    def close
      @active = false

      if !@doom.options.net_game
        @doom.resume_game
      end
    end

    def start_sound(sfx : Sfx)
      @doom.options.sound.as(Audio::ISound).start_sound(sfx)
    end

    def notify_save_failed
      set_current(@save_failed.as(PressAnyKey))
    end

    def show_help_screen
      set_current(@help.as(MenuDef))
      open()
      start_sound(Sfx::SWTCHN)
    end

    def show_save_screen
      set_current(@save.as(MenuDef))
      open()
      start_sound(Sfx::SWTCHN)
    end

    def show_load_screen
      set_current(@load.as(MenuDef))
      open()
      start_sound(Sfx::SWTCHN)
    end

    def show_volume_control
      set_current(@volume.as(MenuDef))
      open()
      start_sound(Sfx::SWTCHN)
    end

    def quick_save
      if @save.as(SaveMenu).last_save_slot == -1
        show_save_screen()
      else
        desc = @save_slots.as(SaveSlots)[@save.as(SaveMenu).last_save_slot]
        confirm = YesNoConfirm.new(
          self,
          DoomInfo::Strings::QSPROMPT.to_s.gsub("%s", desc),
          ->{ @save.as(SaveMenu).do_save(@save.as(SaveMenu).last_save_slot) }
        )
        set_current(confirm)
        open()
        start_sound(Sfx::SWTCHN)
      end
    end

    def quick_load
      if @save.as(SaveMenu).last_save_slot == -1
        pak = PressAnyKey.new(
          self,
          DoomInfo::Strings::QSAVESPOT,
          nil
        )
        set_current(pak)
        open()
        start_sound(Sfx::SWTCHN)
      else
        desc = @save_slots.as(SaveSlots)[@save.as(SaveMenu).last_save_slot]
        confirm = YesNoConfirm.new(
          self,
          DoomInfo::Strings::QLPROMPT.to_s.gsub("%s", desc),
          ->{ @load.as(LoadMenu).do_load(@save.as(SaveMenu).last_save_slot) }
        )
        set_current(confirm)
        open()
        start_sound(Sfx::SWTCHN)
      end
    end

    def end_game
      set_current(@end_game_confirm.as(MenuDef))
      open()
      start_sound(Sfx::SWTCHN)
    end

    def quit
      set_current(@quit_confirm.as(MenuDef))
      open()
      start_sound(Sfx::SWTCHN)
    end
  end
end
