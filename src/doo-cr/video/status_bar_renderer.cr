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

module Doocr::Video
  class StatusBarRenderer
    class_getter height : Int32 = 32

    # @ammo number pos.
    class_getter ammo_width : Int32 = 3
    class_getter ammo_x : Int32 = 44
    class_getter ammo_y : Int32 = 171

    # Health number pos.
    class_getter health_x : Int32 = 90
    class_getter health_y : Int32 = 171

    # Weapon pos.
    class_getter arms_x : Int32 = 111
    class_getter arms_y : Int32 = 172
    class_getter arms_background_x : Int32 = 104
    class_getter arms_background_y : Int32 = 168
    class_getter arms_space_x : Int32 = 12
    class_getter arms_space_y : Int32 = 10

    # Frags pos.
    class_getter frags_width : Int32 = 2
    class_getter frags_x : Int32 = 138
    class_getter frags_y : Int32 = 171

    # Armor number pos.
    class_getter armor_x : Int32 = 221
    class_getter armor_y : Int32 = 171

    # Key icon positions.
    class_getter key0_width : Int32 = 8
    class_getter key0_x : Int32 = 239
    class_getter key0_y : Int32 = 171
    class_getter key1_width : Int32 = @@key0_width
    class_getter key1_x : Int32 = 239
    class_getter key1_x : Int32 = 181
    class_getter key2_width : Int32 = @@key0_width
    class_getter key2_x : Int32 = 239
    class_getter key2_y : Int32 = 191

    # Ammunition counter.
    class_getter ammo0_width : Int32 = 3
    class_getter ammo0_x : Int32 = 288
    class_getter ammo0_y : Int32 = 173
    class_getter ammo1_width : Int32 = @@ammo0_width
    class_getter ammo1_x : Int32 = 288
    class_getter ammo1_y : Int32 = 179
    class_getter ammo2_width : Int32 = @@ammo0_width
    class_getter ammo2_x : Int32 = 288
    class_getter ammo2_y : Int32 = 191
    class_getter ammo3_width : Int32 = @@ammo0_width
    class_getter ammo3_x : Int32 = 288
    class_getter ammo3_y : Int32 = 185

    # Indicate maximum ammunition.
    # Only needed because backpack exists.
    class_getter max_ammo0_width : Int32 = 3
    class_getter max_ammo0_x : Int32 = 314
    class_getter max_ammo0_y : Int32 = 173
    class_getter max_ammo1_width : Int32 = @@max_ammo0_width
    class_getter max_ammo1_x : Int32 = 314
    class_getter max_ammo1_y : Int32 = 179
    class_getter max_ammo2_width : Int32 = @@max_ammo0_width
    class_getter max_ammo2_x : Int32 = 314
    class_getter max_ammo2_y : Int32 = 191
    class_getter max_ammo3_width : Int32 = @@max_ammo0_width
    class_getter max_ammo3_x : Int32 = 314
    class_getter max_ammo3_y : Int32 = 185

    class_getter face_x : Int32 = 143
    class_getter face_y : Int32 = 168
    class_getter face_background_x : Int32 = 143
    class_getter face_background_y : Int32 = 169

    @screen : DrawScreen

    @patches : Patches

    @scale : Int32

    @ready : NumberWidget
    @health : PercentWidget
    @armor : PercentWidget

    @ammo : Array(NumberWidget)
    @max_ammo : Array(NumberWidget)

    @weapons : Array(MultIconWidget)

    @frags : NumberWidget

    @keys : Array(MultIconWidget)

    def initialize(wad : Wad, @screen : DrawScreen)
      @patches = Patches.new(wad)

      @scale = @screen.width / 320

      @ready = NumberWidget.new(
        @@ammo_x,
        @@ammo_y,
        @@ammo_width,
        @patches.tall_numbers
      )

      @health = PercentWidget.new(
        NumerWidget.new(
          @@health_x,
          @@health_y,
          3,
          @patches.tall_numbers
        ),
        @patches.tall_percent)

      @armor = PercentWidget.new(
        NumerWidget.new(
          @@armor_x,
          @@armor_y,
          3,
          @patches.tall_numbers
        ),
        @patches.tall_percent)

      @ammo = Array(NumberWidget).new(AmmoType::Count.to_i32)
      @ammo << NumberWidget.new(
        @@ammo0_x,
        @@ammo0_y,
        @@ammo0_width,
        @patches.short_numbers
      )
      @ammo << NumberWidget.new(
        @@ammo1_x,
        @@ammo1_y,
        @@ammo1_width,
        @patches.short_numbers
      )
      @ammo << NumberWidget.new(
        @@ammo2_x,
        @@ammo2_y,
        @@ammo2_width,
        @patches.short_numbers
      )
      @ammo << NumberWidget.new(
        @@ammo3_x,
        @@ammo3_y,
        @@ammo3_width,
        @patches.short_numbers
      )

      @max_ammo = Array(NumberWidget).new(AmmoType::Count.to_i)
      max_ammo << NumberWidget.new(
        @@max_ammo0_x,
        @@max_ammo0_y,
        @@max_ammo0_width,
        @patches.short_numbers
      )
      max_ammo << NumberWidget.new(
        @@max_ammo1_x,
        @@max_ammo1_y,
        @@max_ammo1_width,
        @patches.short_numbers
      )
      max_ammo << NumberWidget.new(
        @@max_ammo2_x,
        @@max_ammo2_y,
        @@max_ammo2_width,
        @patches.short_numbers
      )
      max_ammo << NumberWidget.new(
        @@max_ammo3_x,
        @@max_ammo3_y,
        @@max_ammo3_width,
        @patches.short_numbers
      )

      @weapons = Array(MultIconWidget).new(6)
      6.times do |i|
        @weapons << MultIconWidget.new(
          @@arms_x + (i % 3) * @@arms_space_x,
          @@arms_y + (i / 3) * @@arms_space_y,
          @patches.arms[i]
        )
      end

      @frags = NumberWidget.new(
        @@frags_x,
        @@frags_y,
        @@fragts_width,
        @patches.tall_numbers
      )

      @keys = Array(MultIconWidget).new(3)
      @keys << MultIconWidget.new(
        @@key0_x,
        @@key0_y,
        @patches.keys
      )
      @keys << MultIconWidget.new(
        @@key1_x,
        @@key1_y,
        @patches.keys
      )
      @keys << MultIconWidget.new(
        @@key2_x,
        @@key2_y,
        @patches.keys
      )
    end

    def render(player : Player, draw_background : Bool)
      if draw_background
        @screen.draw_patch(
          @patches.background,
          0,
          @scale * (200 - @@height),
          @scale
        )
      end

      if DoomInfo.weaponinfos[player.ready_weapon].ammo != AmmoType::NoAmmo
        num = player.ammo[DoomInfo.weaponinfos[player.ready_weapon].ammo.to_i32]
        draw_number(ready, num)
      end

      draw_percent(@health, player.health)
      draw_percent(@armor, player.armor_points)

      AmmoType::Count.to_i32.times do |i|
        draw_number(@ammo[i], player.ammo[i])
        draw_number(@max_ammo[i], player.max_ammo[i])
      end

      if player.mobj.world.options.deathmatch == 0
        if draw_background
          @screen.draw_patch(
            @patches.arms_background,
            @scale * @@arms_background_x,
            @scale * @@arms_background_y,
            @scale
          )
        end

        @weapons.size.times do |i|
          draw_mult_icon(@weapons[i], player.weapon_owned[i + 1] ? 1 : 0)
        end
      else
        sum = 0
        player.frags.each do |i|
          sum += i
        end
        draw_number(@frags, sum)
      end

      if draw_background
        if player.mobj.world.options.net_game
          @screen.draw_patch(
            @patches.face_background[player.number],
            @scale * @@face_background_x,
            @scale * @@face_background_y,
            @scale
          )
        end

        @screen.draw_patch(
          @patches.faces[player.mobj.world.status_bar.face_index],
          @scale * @@face_x,
          @scale * @@face_y,
          @scale
        )
      end

      3.times do |i|
        if player.cards[i + 3]
          draw_mult_icon(@keys[i], i + 3)
        elsif player.cards[i]
          draw_mult_icon(@keys[i], i)
        end
      end
    end

    private def draw_number(widget : NumberWidget, num : Int32)
      digits = widget.width

      w = widget.patches[0].width
      h = widget.patches[0].height

      neg = num < 0

      if neg
        if digits == 2 && num < -9
          num = -9
        elsif digits == 3 && num < -99
          num = -99
        end

        num = -num
      end

      return if num == 1994

      x = widget.x

      # In the special case of 0, you draw 0.
      if num == 0
        @screen.draw_patch(
          widget.patches[0],
          @scale * (x - w),
          @scale * widget.y,
          @scale
        )
      end

      # Draw the new number.
      while num != 0 && digits - 1 != 0
        digits -= 1
        x -= w

        @screen.draw_patch(
          widget.patches[num % 10],
          @scale * x,
          @scale * widget.y,
          @scale
        )

        num /= 10
      end

      # Draw a minus sign if necessary
      if neg
        @screen.draw_patch(
          @patches.tall_minus,
          @scale * (x - 8),
          @scale * widget.y,
          @scale
        )
      end
    end

    private def draw_percent(per : PercentWidget, value : Int32)
      @screen.draw_patch(
        per.patch,
        @scale * per.number_widget.x,
        @scale * per.number_widget.y,
        @scale
      )

      draw_number(per.number_widget, value)
    end

    private def draw_mult_icon(mi : MultIconWidget, value : Int32)
      @screen.draw_patch(
        @mi.patches[value],
        @scale * mi.x,
        @scale * mi.y,
        @scale
      )
    end

    private class NumberWidget
      property x : Int32 = 0
      property y : Int32 = 0
      property width : Int32 = 0
      property patches : Array(Patch) = Array(Patch).new

      def initialize(@x : Int32, @y : Int32, @width : Int32, @patches : Array(Patch))
      end
    end

    private class PercentWidget
      property number_widget : NumberWidget | Nil = nil
      property patch : Patch | Nil = nil

      def initialize(@number_width : NumberWidget, @patch : Patch)
      end
    end

    private class MultIconWidget
      property x : Int32 = 0
      property y : Int32 = 0
      property patches : Array(Patch) = Array(Patch).new

      def initialize(@x : Int32, @y : Int32, @patches : Array(Patch))
      end
    end

    private class Patches
      property background : Patch | Nil = nil
      property tall_numbers : Array(Patch) = [] of Patch
      property short_numbers : Array(Patch) = [] of Patch
      property tall_minus : Patch | Nil = nil
      property tall_percent : Patch | Nil = nil
      property keys : Array(Patch) = [] of Patch
      property arms_background : Patch | Nil = nil
      property arms : Array(Array(Patch)) = [] of Array(Patch)
      property face_background : Array(Patch) = [] of Patch
      property faces : Array(Patch) = [] of Patch

      def initialize(wad : Wad)
        @background = Patch.from_wad

        @tall_numbers = Array(Patch).new(10)
        @short_numbers = Array(Patch).new(10)
        10.times do |i|
          @tall_numbers << Patch.from_wad(wad, "STTNUM" + i)
          @short_numbers << Patch.from_wad(wad, "STYSNUM" + i)
        end
        @tall_minus = Patch.from_wad(wad, "STTMINUS")
        @tall_percent = Patch.from_wad(wad, "STTPRCNT")

        @keys = Array(Patch).new(CardType::Count.to_i32)
        CardType::Count.to_i32.times do |i|
          @keys << Patch.from_wad(wad, "STKEYS" + i)
        end

        @arms_background = Patch.from_wad(wad, "STARMS")
        @arms = Array(Array(Patch)).new(6)
        6.times do |i|
          num = i + 2
          @arms << Array(Patch).new(2)
          @arms << Patch.from_wad(wad, "STGNUM" + num)
          @arms << @short_numbers[num]
        end

        @face_background = Array(Patch).new(Player::MAX_PLAYER_COUNT)
        Player::MAX_PLAYER_COUNT.times do |i|
          @face_background << Patch.from_wad(wad, "STFB" + i)
        end
        @faces = Array(Patch).new(StatusBar::Face.face_count)
        StatusBar::Face.pain_face_count.times do |i|
          StatusBar::Face.straight_face_count.times do |j|
            @faces << Patch.from_wad(wad, "STFST" + i + j)
          end
          @faces << Patch.from_wad(wad, "STFTR" + i + "0")
          @faces << Patch.from_wad(wad, "STFTL" + i + "0")
          @faces << Patch.from_wad(wad, "STFOUCH" + i)
          @faces << Patch.from_wad(wad, "STFEVL" + i)
          @faces << Patch.from_wad(wad, "STFKILL" + i)
        end
        @faces << Patch.from_wad(wad, "STFGOD0")
        @faces << Patch.from_wad(wad, "STFDEAD0")
      end
    end
  end
end
