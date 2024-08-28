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
  class Player
    MAX_PLAYER_COUNT = 4

    class_getter normal_view_height : Fixed = Fixed.from_i(41)

    @@default_player_names : Array(String) = [
      "Green",
      "Indigo",
      "Brown",
      "Red",
    ]

    getter number : Int32 = 0
    getter name : String | Nil = nil
    property in_game : Bool = false

    property mobj : Mobj | Nil = nil
    property player_state : PlayerState = PlayerState.new(0)
    property cmd : TicCmd | Nil = nil

    # Determine POV, including viewpoint bobbing during movement.
    # Focal origin above mobj.z
    property view_z : Fixed = Fixed.zero

    # Base height above floor for view_z
    property view_height : Fixed = Fixed.zero

    # Bob / squat speed.
    property delta_view_height : Fixed = Fixed.zero

    # Bounded / scaled total momentum.
    property bob : Fixed = Fixed.zero

    # This is only used between levels,
    # mobj.Health is used during levels.
    property health : Int32 = 0
    property armor_points : Int32 = 0

    # Armor type is 0-2
    property armor_type : Int32 = 0

    # Power ups. invinc and invis are tic counters.
    getter powers : Array(Int32) = [] of Int32
    getter cards : Array(Bool) = [] of Bool
    property backpack : Bool = false

    # Frags, kill of other players.
    getter frags : Array(Int32) = [] of Int32

    property ready_weapon : WeaponType = WeaponType.new(0)

    # Is WeaponType::NoChange if not changing.
    property pending_weapon : WeaponType = WeaponType.new(0)

    property weapon_owned : Array(Bool) = [] of Bool
    property ammo : Array(Int32) = [] of Int32
    property max_ammo : Array(Int32) = [] of Int32

    # True if button down last tic.
    property attack_down : Bool = false
    property use_down : Bool = false

    # Bit flags, for cheats and debug.
    property cheats : CheatFlags = CheatFlags.new(0)

    # Refired shots are less accurate.
    property refire : Int32 = 0

    # For intermission stats.
    property kill_count : Int32 = 0
    property item_count : Int32 = 0
    property secret_count : Int32 = 0

    # Hint messages.
    property message : String | Nil = nil
    property message_time : Int32 = 0

    # For screen flashing (red or bright)
    property damage_count : Int32 = 0
    property bonus_count : Int32 = 0

    # Who did damage (nil for floors / ceilings)
    property attacker : Mobj | Nil = nil

    # So gun flashes light up areas.
    property extra_light : Int32 = 0

    # Current PLAYPAL, ???
    # can be set to REDCOLORMAP for pain, etc
    property fixed_colormap : Int32 = 0

    # Player skin colorshift,
    # 0-3 for which color to draw player.
    property colormap : Int32 = 0

    # Overlay view sprites (gun, etc).
    getter player_sprites : Array(PlayerSpriteDef) = [] of PlayerSpriteDef

    # True if secret level has been done.
    property did_secret : Bool = false

    # For frame interpolation.
    @interpolate : Bool = false
    @old_view_z : Fixed = Fixed.zero
    @old_angle : Angle = Angle.ang0

    def initialize(@number)
      @name = @@default_player_names[@number]

      @cmd = TicCmd.new

      @powers = Array.new(PowerType::Count.to_i32, 0)
      @cards = Array.new(CardType::Count.to_i32, false)

      @frags = Array.new(MAX_PLAYER_COUNT, 0)

      @weapon_owned = Array.new(WeaponType::Count.to_i32, false)
      @ammo = Array.new(AmmoType::Count.to_i32, 0)
      @max_ammo = Array.new(AmmoType::Count.to_i32, 0)

      @player_sprites = Array.new(PlayerSprite::Count.to_i32, PlayerSpriteDef.new)
    end

    def clear
      @mobj = nil
      @player_state = PlayerState.new(0)
      @cmd.as(TicCmd).clear

      @view_z = Fixed.zero
      @view_height = Fixed.zero
      @delta_view_height = Fixed.zero
      @bob = Fixed.zero

      @health = 0
      @armor_points = 0
      @armor_type = 0

      @weapon_owned.fill(false)
      @ammo.fill(0)
      @max_ammo.fill(0)

      @use_down = false
      @attack_down = false

      @cheats = CheatFlags.new(0)

      @refire = 0

      @kill_count = 0
      @item_count = 0
      @secret_count = 0

      @message = nil
      @message_time = 0

      @damage_count = 0
      @bonus_count = 0

      @attacker = nil

      @extra_light = 0

      @fixed_colormap = 0

      @colormap = 0

      @player_sprites.each do |psp|
        psp.clear
      end

      @did_secret = false

      @interpolate = false
      @old_view_z = Fixed.zero
      @old_angle = Angle.ang0
    end

    def reborn
      @mobj = nil
      @player_state = PlayerState::Live
      @cmd.as(TicCmd).clear

      @view_z = Fixed.zero
      @view_height = Fixed.zero
      @delta_view_height = Fixed.zero
      @bob = Fixed.zero

      @health = DoomInfo::DeHackEdConst.initial_health
      @armor_points = 0
      @armor_type = 0

      @powers.fill(0)
      @cards.fill(false)
      @backpack = false

      @ready_weapon = WeaponType::Pistol
      @pending_weapon = WeaponType::Pistol

      @weapon_owned.fill(false)
      @ammo.fill(0)
      @max_ammo.fill(0)

      @weapon_owned[WeaponType::Fist.to_i32] = true
      @weapon_owned[WeaponType::Pistol.to_i32] = true
      @ammo[AmmoType::Clip.to_i32] = DoomInfo::DeHackEdConst.initial_bullets
      AmmoType::Count.to_i32.times do |i|
        @max_ammo[i] = DoomInfo::AmmoInfos.max[i]
      end

      # Don't do anything immediately.
      @use_down = true
      @attack_down = true

      @cheats = CheatFlags.new(0)

      @refire = 0

      @message = nil
      @message_time = 0

      @damage_count = 0
      @bonus_count = 0

      @attacker = nil

      @extra_light = 0

      @fixed_colormap = 0

      @colormap = 0

      @player_sprites.each do |psp|
        psp.clear
      end

      @did_secret = false

      @interpolate = false
      @old_view_z = Fixed.zero
      @old_angle = Angle.ang0
    end

    def finish_level
      @powers.fill(0)
      @cards.fill(false)

      # Cancel invisibility.
      @mobj.as(Mobj).flags &= ~MobjFlags::Shadow

      # Cancel gun flashes.
      @extra_light = 0

      # Cancel ir gogles.
      @fixed_colormap = 0

      # No palette changes.
      @damage_count = 0
      @bonus_count = 0
    end

    def send_message(message : String | DoomString)
      message = message.to_s
      if (@message.same?(DoomInfo::Strings::MSGOFF.to_s) &&
         !message.same?(DoomInfo::Strings::MSGON.to_s))
        return
      end

      @message = message
      @message_time = 4 * GameConst.tic_rate
    end

    def update_frame_interpolation_info
      @interpolate = true
      @old_view_z = @view_z
      @old_angle = @mobj.as(Mobj).angle
    end

    def disable_frame_interpolation_for_one_frame
      @interpolate = false
    end

    def get_interpolated_view_z(frame_frac : Fixed) : Fixed
      # Without the second condition, flicker will occur on the first frame.
      if @interpolate && @mobj.as(Mobj).world.as(World).level_time > 1
        return @old_view_z + frame_frac * (@view_z - @old_view_z)
      else
        return @view_z
      end
    end

    def get_interpolated_angle(frame_frac : Fixed) : Angle
      if @interpolate
        delta = @mobj.as(Mobj).angle - @old_angle
        if delta < Angle.ang180
          return @old_angle + Angle.from_degree(frame_frac.to_f64 * delta.to_degree)
        else
          return @old_angle - Angle.from_degree(frame_frac.to_f64 * (360.0 - delta.to_degree))
        end
      else
        return @mobj.as(Mobj).angle
      end
    end
  end
end
