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
  class StatusBar
    @world : World

    # Used for appopriately pained face.
    @old_health : Int32

    # Used for evil grin.
    @old_weapons_owned : Array(Bool)

    # Count until face changes.
    @face_count : Int32

    # Current face index.
    getter face_index : Int32

    # A random number per tick.
    @random_number : Int32

    @priority : Int32

    @last_attack_down : Int32
    @last_pain_offset : Int32

    @random : DoomRandom

    def initialize(@world : World)
      @old_health = -1
      @old_weapons_owned = @world.as(World).console_player.weapons_owned.clone
      @face_count = 0
      @face_index = 0
      @random_number = 0
      @priority = 0
      @last_attack_down = -1
      @last_pain_offset = 0

      @random = DoomRandom.new
    end

    def reset
      @old_health = -1
      @old_weapons_owned = @world.as(World).console_player.weapons_owned.clone
      @face_count = 0
      @face_index = 0
      @random_number = 0
      @priority = 0
      @last_attack_down = -1
      @last_pain_offset = 0
    end

    def update
      @random_number = @random.next
      update_face()
    end

    private def update_face
      player = @world.as(World).console_player

      if @priority < 10
        # Dead.
        if player.health == 0
          @priority = 9
          @face_index = Face.dead_index
          @face_count = 1
        end
      end

      if @priority < 9
        if player.bonus_count != 0
          # Picking up bonus.
          do_evil_grin = false

          DoomInfo.weaponinfos.size.times do |i|
            if @old_weapons_owned[i] != player.weapons_owned[i]
              do_evil_grin = true
              @old_weapons_owned[i] = player.weapons_owned[i]
            end
          end

          if do_evil_grin
            # Evil grin if just picked up weapon.
            @priority = 8
            @face_count = Face.evil_grin_duration
            @face_index = calc_pain_offset() + Face.evil_grin_offset
          end
        end
      end

      if @priority < 8
        if player.damage_count != 0 &&
           player.attacker != nil &&
           player.attacker != player.mobj
          # Being attacked.
          @priority = 7

          if player.health - @old_health > Face.much_pain
            @face_count = Face.turn_duration
            @face_index = calc_pain_offset() + Face.ouch_offset
          else
            attacker_angle = Geometry.point_to_angle(
              player.mobj.x, player.mobj.y,
              player.attacker.x, player.attacker.y
            )

            diff : Angle
            right : Bool
            if attacker_angle > player.mobj.angle
              # Whether right or left.
              diff = attacker_angle - player.mobj.angle
              right = diff > Angle.ang180
            else
              # Whether left or right.
              diff = player.mobj.angle - attacker_angle
              right = diff <= Angle.ang180
            end

            @face_count = Face.turn_duration
            @face_index = calc_pain_offset()

            if diff < Angle.ang45
              # Head-on
              @face_index += Face.rampage_offset
            elsif right
              # Turn face right.
              @face_index += Face.turn_offset
            else
              # Turn face left
              @face_index += Face.turn_offset + 1
            end
          end
        end
      end

      if @priority < 7
        # Getting hurt because of your own damn stupidity.
        if player.damage_count != 0
          if player.health - @old_health > Face.much_pain
            @priority = 7
            @face_count = Face.turn_duration
            @face_index = calc_pain_offset() + Face.ouch_offset
          else
            @priority = 6
            @face_count = Face.turn_duration
            @face_index = calc_pain_offset() + Face.rampage_offset
          end
        end
      end

      if @priority < 6
        # Rapid firing.
        if player.attack_down
          if @last_attack_down == -1
            @last_attack_down = Face.rampage_delay
          elsif (@last_attack_down -= 1) == 0
            @priority = 5
            @face_index = calc_pain_offset() + Face.rampage_offset
            @face_count = 1
            @last_attack_down = 1
          end
        else
          @last_attack_down = -1
        end
      end

      if @priority < 5
        # Invulnerability
        if ((player.cheats & CheatFlags::GodMode).to_i32 != 0 ||
           player.powers[PowerType::Invulnerability.to_i32] != 0)
          @priority = 4
          @face_index = Face.god_index
          @face_count = 1
        end
      end

      # Look left or look right if the facecount has timed out.
      if @face_count == 0
        @face_index = calc_pain_offset() + (@random_number % 3)
        @face_count = Face.straight_face_duration
        @priority = 0
      end

      @face_count -= 1
    end

    private def calc_pain_offset : Int32
      player = @world.as(World).options.players[@world.as(World).options.console_player]

      health = player.health > 100 ? 100 : player.health

      if health != @old_health
        @last_pain_offset = Face.stride * ((100 - health) * Face.pain_face_count) / 101
        @old_health = health
      end

      return @last_pain_offset
    end

    module Face
      class_getter pain_face_count : Int32 = 5
      class_getter straight_face_count : Int32 = 3
      class_getter turn_face_count : Int32 = 2
      class_getter special_face_count : Int32 = 3

      class_getter stride : Int32 = @@straight_face_count + @@turn_face_count + @@special_face_count
      class_getter extra_face_count : Int32 = 2
      class_getter face_count : Int32 = @@stride * @@pain_face_count + @@extra_face_count

      class_getter turn_offset : Int32 = @@straight_face_count
      class_getter ouch_offset : Int32 = @@turn_offset + @@turn_face_count
      class_getter evil_grin_offset : Int32 = @@ouch_offset + 1
      class_getter rampage_offset : Int32 = @@evil_grin_offset + 1
      class_getter god_index : Int32 = @@pain_face_count * @@stride
      class_getter dead_index : Int32 = @@god_index + 1

      class_getter evil_grin_duration : Int32 = 2 * GameConst.tic_rate
      class_getter straight_face_duration : Int32 = (GameConst.tic_rate / 2).to_i32
      class_getter turn_duration : Int32 = 1 * GameConst.tic_rate
      class_getter ouch_duration : Int32 = 1 * GameConst.tic_rate
      class_getter rampage_delay : Int32 = 2 * GameConst.tic_rate

      class_getter much_pain : Int32 = 20
    end
  end
end
