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
  # Vanilla-compatible save and load, full of messy binary handling code.
  module SaveAndLoad
    class_getter description_size : Int32 = 24
    class_getter version_size : Int32 = 16
    class_getter save_buffer_size : Int32 = 360 * 1024

    private enum ThinkerClass
      End
      Mobj
    end

    private enum SpecialClass
      Ceiling
      Door
      Floor
      Plat
      Flash
      Strobe
      Glow
      EndSpecials
    end

    def self.save(game : DoomGame, description : String, path : String)
      sg = SaveGame.new(description)
      sg.save(game, path)
    end

    def self.load(game : DoomGame, path : String)
      options = game.options.as(GameOptions)
      game.init_new(options.skill, options.episode, options.map)

      File.open(path) do |file|
        lg = LoadGame.new(file.getb_to_end)
        lg.load(game)
      end
    end

    #
    # Save game
    #
    class SaveGame
      @data : Bytes = Bytes.new(0)
      @ptr : Int32 = 0

      def initialize(description : String)
        @data = Bytes.new(SaveAndLoad.save_buffer_size)
        @ptr = 0

        write_description(description)
        write_version()
      end

      private def write_description(description : String)
        description.size.times do |i|
          @data[i] = description[i].ord.to_u8
        end
        @ptr += description.size
      end

      private def write_version
        version = "version 109"
        version.size.times do |i|
          @data[@ptr + i] = version[i].ord.to_u8
        end
        @ptr += SaveAndLoad.version_size
      end

      def save(game : DoomGame, path : String)
        world = game.world.as(World)
        options = world.options.as(GameOptions)
        @data[@ptr] = options.skill.to_u8
        @ptr += 1
        @data[@ptr] = options.episode.to_u8
        @ptr += 1
        @data[@ptr] = options.map.to_u8
        @ptr += 1
        Player::MAX_PLAYER_COUNT.times do |i|
          @data[@ptr] = options.players[i].in_game ? 1_u8 : 0_u8
          @ptr += 1
        end

        @data[@ptr] = (world.level_time >> 16).to_u8
        @ptr += 1
        @data[@ptr] = (world.level_time >> 8).to_u8
        @ptr += 1
        @data[@ptr] = world.level_time.to_u8
        @ptr += 1

        archive_players(world)
        archive_world(world)
        archive_thinkers(world)
        archive_specials(world)

        @data[@ptr] = 0x1d
        @ptr += 1

        File.write(path, @data)
      end

      private def pad_pointer
        @ptr += (4 - (@ptr & 3)) & 3
      end

      private def archive_players(world : World)
        players = world.options.as(GameOptions).players
        Player::MAX_PLAYER_COUNT.times do |i|
          next if !players[i].in_game

          pad_pointer

          @ptr = archive_player(players[i], @data, @ptr)
        end
      end

      private def archive_world(world : World)
        # Do sectors.
        sectors = world.map.as(Map).sectors
        sectors.size.times do |i|
          @ptr = archive_sector(sectors[i], @data, @ptr)
        end

        # Do lines.
        lines = world.map.as(Map).lines
        lines.size.times do |i|
          @ptr = archive_line(lines[i], @data, @ptr)
        end
      end

      private def archive_thinkers(world : World)
        thinkers = world.thinkers.as(Thinkers)

        # Read in saved thinkers.
        enumerator = thinkers.get_enumerator
        while true
          thinker = enumerator.current
          if mobj = thinker.as(Mobj?)
            @data[@ptr] = ThinkerClass::Mobj.to_u8
            @ptr += 1
            pad_pointer

            write_thinker_state(@data, @ptr + 8, mobj.thinker_state.as(ThinkerState))
            write(@data, @ptr + 12, mobj.x.data)
            write(@data, @ptr + 16, mobj.y.data)
            write(@data, @ptr + 20, mobj.z.data)
            write(@data, @ptr + 32, mobj.angle.data)
            write(@data, @ptr + 36, mobj.sprite.to_i32)
            write(@data, @ptr + 40, mobj.frame)
            write(@data, @ptr + 56, mobj.floor_z.data)
            write(@data, @ptr + 60, mobj.ceiling_z.data)
            write(@data, @ptr + 64, mobj.radius.data)
            write(@data, @ptr + 68, mobj.height.data)
            write(@data, @ptr + 72, mobj.mom_x.data)
            write(@data, @ptr + 76, mobj.mom_y.data)
            write(@data, @ptr + 80, mobj.mom_z.data)
            write(@data, @ptr + 88, mobj.type.to_i32)
            write(@data, @ptr + 96, mobj.tics)
            write(@data, @ptr + 100, mobj.state.as(MobjStateDef).number)
            write(@data, @ptr + 104, mobj.flags.to_i32)
            write(@data, @ptr + 108, mobj.health)
            write(@data, @ptr + 112, mobj.move_dir.to_i32)
            write(@data, @ptr + 116, mobj.move_count)
            write(@data, @ptr + 124, mobj.reaction_time)
            write(@data, @ptr + 128, mobj.threshold)
            if mobj.player == nil
              write(@data, @ptr + 132, 0)
            else
              write(@data, @ptr + 132, mobj.player.as(Player).number + 1)
            end
            write(@data, @ptr + 136, mobj.last_look)
            if spawn_point = mobj.spawn_point.as(MapThing)
              write(@data, @ptr + 140, spawn_point.x.to_i_floor)
              write(@data, @ptr + 142, spawn_point.y.to_i_floor)
              write(@data, @ptr + 144, spawn_point.angle.to_degree.round_even.to_i16)
              write(@data, @ptr + 146, spawn_point.type.to_i16)
              write(@data, @ptr + 148, spawn_point.flags.to_i16)
            else
              write(@data, @ptr + 140, 0_i16)
              write(@data, @ptr + 142, 0_i16)
              write(@data, @ptr + 144, 0_i16)
              write(@data, @ptr + 146, 0_i16)
              write(@data, @ptr + 148, 0_i16)
            end
            @ptr += 154
          end
          break if !enumerator.move_next
        end
      end

      private def archive_specials(world : World)
        thinkers = world.thinkers.as(Thinkers)
        sa = world.sector_action.as(SectorAction)

        # Read in saved thinkers.
        enumerator = thinkers.get_enumerator
        while true
          thinker = enumerator.current
          if thinker.thinker_state == ThinkerState::InStasis
            ceiling = thinker.as?(CeilingMove)
            if sa.check_active_ceiling(ceiling)
              ceiling = ceiling.as(CeilingMove)
              @data[@ptr] = SpecialClass::Ceiling.to_u8
              @ptr += 1
              pad_pointer()
              write_thinker_state(@data, @ptr + 8, ceiling.thinker_state.as(ThinkerState))
              write(@data, @ptr + 12, ceiling.type.to_i32)
              write(@data, @ptr + 16, ceiling.sector.as(Sector).number)
              write(@data, @ptr + 20, ceiling.bottom_height.data)
              write(@data, @ptr + 24, ceiling.top_height.data)
              write(@data, @ptr + 28, ceiling.speed.data)
              write(@data, @ptr + 32, ceiling.crush ? 1 : 0)
              write(@data, @ptr + 36, ceiling.direction)
              write(@data, @ptr + 40, ceiling.tag)
              write(@data, @ptr + 44, ceiling.old_direction)
              @ptr += 48
            end
            enumerator.move_next
            next
          end

          if ceiling = thinker.as?(CeilingMove)
            @data[@ptr] = SpecialClass::Ceiling.to_u8
            @ptr += 1
            pad_pointer
            write_thinker_state(@data, @ptr + 8, ceiling.thinker_state.as(ThinkerState))
            write(@data, @ptr + 12, ceiling.type.to_i32)
            write(@data, @ptr + 16, ceiling.sector.as(Sector).number)
            write(@data, @ptr + 20, ceiling.bottom_height.data)
            write(@data, @ptr + 24, ceiling.top_height.data)
            write(@data, @ptr + 28, ceiling.speed.data)
            write(@data, @ptr + 32, ceiling.crush ? 1 : 0)
            write(@data, @ptr + 36, ceiling.direction)
            write(@data, @ptr + 40, ceiling.tag)
            write(@data, @ptr + 44, ceiling.old_direction)
            @ptr += 48
            enumerator.move_next
            next
          end

          if door = thinker.as?(VerticalDoor)
            @data[@ptr] = SpecialClass::Door.to_u8
            @ptr += 1
            pad_pointer
            write_thinker_state(@data, @ptr + 8, door.thinker_state.as(ThinkerState))
            write(@data, @ptr + 12, door.type.as(VerticalDoorType).to_i32)
            write(@data, @ptr + 16, door.sector.as(Sector).number)
            write(@data, @ptr + 20, door.top_height.data)
            write(@data, @ptr + 24, door.speed.data)
            write(@data, @ptr + 28, door.direction)
            write(@data, @ptr + 32, door.top_wait)
            write(@data, @ptr + 36, door.top_count_down)
            @ptr += 40
            enumerator.move_next
            next
          end

          if floor = thinker.as?(FloorMove)
            @data[@ptr] = SpecialClass::Floor.to_u8
            @ptr += 1
            pad_pointer
            write_thinker_state(@data, @ptr + 8, floor.thinker_state.as(ThinkerState))
            write(@data, @ptr + 12, floor.type.to_i32)
            write(@data, @ptr + 16, floor.crush ? 1 : 0)
            write(@data, @ptr + 20, floor.sector.as(Sector).number)
            write(@data, @ptr + 24, floor.direction)
            write(@data, @ptr + 28, floor.new_special.to_i32)
            write(@data, @ptr + 32, floor.texture)
            write(@data, @ptr + 36, floor.floor_dest_height.data)
            write(@data, @ptr + 40, floor.speed.data)
            @ptr += 44
            enumerator.move_next
            next
          end

          if plat = thinker.as?(Platform)
            @data[@ptr] = SpecialClass::Plat.to_u8
            @ptr += 1
            pad_pointer
            write_thinker_state(@data, @ptr + 8, plat.thinker_state.as(ThinkerState))
            write(@data, @ptr + 12, plat.sector.as(Sector).number)
            write(@data, @ptr + 16, plat.speed.data)
            write(@data, @ptr + 20, plat.low.data)
            write(@data, @ptr + 24, plat.high.data)
            write(@data, @ptr + 28, plat.wait)
            write(@data, @ptr + 32, plat.count)
            write(@data, @ptr + 36, plat.status.to_i32)
            write(@data, @ptr + 40, plat.old_status.to_i32)
            write(@data, @ptr + 44, plat.crush ? 1 : 0)
            write(@data, @ptr + 48, plat.tag)
            write(@data, @ptr + 52, plat.type.as(PlatformType).to_i32)

            @ptr += 56
            enumerator.move_next
            next
          end

          if flash = thinker.as?(LightFlash)
            @data[@ptr] = SpecialClass::Flash.to_u8
            @ptr += 1
            pad_pointer
            write_thinker_state(@data, @ptr + 8, flash.thinker_state.as(ThinkerState))
            write(@data, @ptr + 12, flash.sector.as(Sector).number)
            write(@data, @ptr + 16, flash.count)
            write(@data, @ptr + 20, flash.max_light)
            write(@data, @ptr + 24, flash.min_light)
            write(@data, @ptr + 28, flash.max_time)
            write(@data, @ptr + 32, flash.min_time)

            @ptr += 36
            enumerator.move_next
            next
          end

          if strobe = thinker.as?(StrobeFlash)
            @data[@ptr] = SpecialClass::Strobe.to_u8
            @ptr += 1
            pad_pointer
            write_thinker_state(@data, @ptr + 8, strobe.thinker_state.as(ThinkerState))
            write(@data, @ptr + 12, strobe.sector.as(Sector).number)
            write(@data, @ptr + 16, strobe.count)
            write(@data, @ptr + 20, strobe.min_light)
            write(@data, @ptr + 24, strobe.max_light)
            write(@data, @ptr + 28, strobe.dark_time)
            write(@data, @ptr + 32, strobe.bright_time)

            @ptr += 36
            enumerator.move_next
            next
          end

          if glow = thinker.as?(GlowingLight)
            @data[@ptr] = SpecialClass::Glow.to_u8
            @ptr += 1
            pad_pointer
            write_thinker_state(@data, @ptr + 8, glow.thinker_state.as(ThinkerState))
            write(@data, @ptr + 12, glow.sector.as(Sector).number)
            write(@data, @ptr + 16, glow.min_light)
            write(@data, @ptr + 20, glow.max_light)
            write(@data, @ptr + 24, glow.direction)

            @ptr += 28
            enumerator.move_next
            next
          end

          break if !enumerator.move_next
        end

        @data[@ptr] = SpecialClass::EndSpecials.to_u8
        @ptr += 1
      end

      private def archive_player(player : Player, data : Bytes, ptr : Int32) : Int32
        write(data, ptr + 4, player.player_state.to_i32)
        write(data, ptr + 16, player.view_z.data)
        write(data, ptr + 20, player.view_height.data)
        write(data, ptr + 24, player.delta_view_height.data)
        write(data, ptr + 28, player.bob.data)
        write(data, ptr + 32, player.health)
        write(data, ptr + 36, player.armor_points)
        write(data, ptr + 40, player.armor_type)
        PowerType::Count.to_i32.times do |i|
          write(data, ptr + 44 + 4 * i, player.powers[i])
        end
        PowerType::Count.to_i32.times do |i|
          write(data, ptr + 68 + 4 * i, player.cards[i] ? 1 : 0)
        end
        write(data, ptr + 92, player.backpack ? 1 : 0)
        Player::MAX_PLAYER_COUNT.times do |i|
          write(data, ptr + 96 + 4 * i, player.frags[i])
        end
        write(data, ptr + 112, player.ready_weapon.to_i32)
        write(data, ptr + 116, player.pending_weapon.to_i32)
        WeaponType::Count.to_i32.times do |i|
          write(data, ptr + 120 + 4 * i, player.weapon_owned[i] ? 1 : 0)
        end
        AmmoType::Count.to_i32.times do |i|
          write(data, ptr + 156 + 4 * i, player.ammo[i])
        end
        AmmoType::Count.to_i32.times do |i|
          write(data, ptr + 172 + 4 * i, player.max_ammo[i])
        end

        write(data, ptr + 188, player.attack_down ? 1 : 0)
        write(data, ptr + 192, player.use_down ? 1 : 0)
        write(data, ptr + 196, player.cheats.to_i32)
        write(data, ptr + 200, player.refire)
        write(data, ptr + 204, player.kill_count)
        write(data, ptr + 208, player.item_count)
        write(data, ptr + 212, player.secret_count)
        write(data, ptr + 220, player.damage_count)
        write(data, ptr + 224, player.bonus_count)
        write(data, ptr + 232, player.extra_light)
        write(data, ptr + 236, player.fixed_colormap)
        write(data, ptr + 240, player.colormap)
        PlayerSprite::Count.to_i32.times do |i|
          if x = player.player_sprites[i].state.as?(MobjStateDef)
            write(data, ptr + 244 + 16 * i, x.number)
          else
            write(data, ptr + 244 + 16 * i, 0)
          end
          write(data, ptr + 244 + 16 * i + 4, player.player_sprites[i].tics)
          write(data, ptr + 244 + 16 * i + 8, player.player_sprites[i].sx.data)
          write(data, ptr + 244 + 16 * i + 12, player.player_sprites[i].sy.data)
        end
        write(data, ptr + 276, player.did_secret ? 1 : 0)

        return ptr + 280
      end

      private def archive_sector(sector : Sector, data : Bytes, ptr : Int32) : Int32
        write(data, ptr, sector.floor_height.to_i_floor.to_i16)
        write(data, ptr + 2, sector.ceiling_height.to_i_floor.to_i16)
        write(data, ptr + 4, sector.floor_flat.to_i16)
        write(data, ptr + 6, sector.ceiling_flat.to_i16)
        write(data, ptr + 8, sector.light_level.to_i16)
        write(data, ptr + 10, sector.special.to_i16)
        write(data, ptr + 12, sector.tag.to_i16)
        return ptr + 14
      end

      private def archive_line(line : LineDef, data : Bytes, ptr : Int32) : Int32
        write(data, ptr, line.flags.to_i16)
        write(data, ptr + 2, line.special.to_i16)
        write(data, ptr + 4, line.tag.to_i16)
        ptr += 6

        if side = line.front_side.as?(SideDef)
          write(data, ptr, side.texture_offset.to_i_floor.to_i16)
          write(data, ptr + 2, side.row_offset.to_i_floor.to_i16)
          write(data, ptr + 4, side.top_texture.to_i16)
          write(data, ptr + 6, side.bottom_texture.to_i16)
          write(data, ptr + 8, side.middle_texture.to_i16)
          ptr += 10
        end

        if side = line.back_side.as?(SideDef)
          write(data, ptr, side.texture_offset.to_i_floor.to_i16)
          write(data, ptr + 2, side.row_offset.to_i_floor.to_i16)
          write(data, ptr + 4, side.top_texture.to_i16)
          write(data, ptr + 6, side.bottom_texture.to_i16)
          write(data, ptr + 8, side.middle_texture.to_i16)
          ptr += 10
        end

        return ptr
      end

      def write(data : Bytes, ptr : Int32, value : Int32 | UInt32)
        data[ptr] = value.to_u8
        data[ptr + 1] = (value >> 8).to_u8
        data[ptr + 2] = (value >> 16).to_u8
        data[ptr + 3] = (value >> 24).to_u8
      end

      def write(data : Bytes, ptr : Int32, value : Int16)
        data[ptr] = value.to_u8
        data[ptr + 1] = (value >> 8).to_u8
      end

      def write_thinker_state(data : Bytes, ptr : Int32, state : ThinkerState)
        case state
        when ThinkerState::InStasis
          write(data, ptr, 0)
        else
          write(data, ptr, 1)
        end
      end
    end

    #
    # Load game
    #
    class LoadGame
      @data : Bytes = Bytes.new(0)
      @ptr : Int32 = 0

      def initialize(@data)
        @ptr = 0

        read_description()

        version = read_version
        raise "Unsupported version!" if version != "VERSION 109"
      end

      def load(game : DoomGame)
        options = game.world.as(World).options.as(GameOptions)
        options.skill = GameSkill.new(@data[@ptr])
        @ptr += 1
        options.episode = @data[@ptr]
        @ptr += 1
        options.map = @data[@ptr]
        @ptr += 1
        Player::MAX_PLAYER_COUNT.times do |i|
          options.players[i].in_game = @data[@ptr] != 0
          @ptr += 1
        end

        game.init_new(options.skill, options.episode, options.map)

        a = @data[@ptr]
        @ptr += 1
        b = @data[@ptr]
        @ptr += 1
        c = @data[@ptr]
        @ptr += 1
        level_time = (a << 16) + (b << 8) + c

        world = game.world.as(World)
        unarchive_players(world)
        unarchive_world(world)
        unarchive_thinkers(world)
        unarchive_specials(world)

        raise "Bad savegame!" if @data[@ptr] != 0x1d

        world.level_time = level_time

        options.sound.as(Audio::ISound).set_listener(world.console_player.mobj.as(Mobj))
      end

      private def pad_pointer
        @ptr += (4 - (@ptr & 3)) & 3
      end

      private def read_description : String
        value = DoomInterop.to_s(@data, @ptr, SaveAndLoad.description_size)
        @ptr += SaveAndLoad.description_size
        return value
      end

      private def read_version : String
        value = DoomInterop.to_s(@data, @ptr, SaveAndLoad.version_size)
        @ptr += SaveAndLoad.version_size
        return value
      end

      private def unarchive_players(world : World)
        players = world.options.as(GameOptions).players
        Player::MAX_PLAYER_COUNT.times do |i|
          next if !players[i].in_game

          pad_pointer

          @ptr = unarchive_player(players[i], @data, @ptr)
        end
      end

      private def unarchive_world(world : World)
        # Do sectors.
        sectors = world.map.as(Map).sectors
        sectors.size.times do |i|
          @ptr = unarchive_sector(sectors[i], @data, @ptr)
        end

        # Do lines.
        lines = world.map.as(Map).lines
        lines.size.times do |i|
          @ptr = unarchive_line(lines[i], @data, @ptr)
        end
      end

      private def unarchive_thinkers(world : World)
        thinkers = world.thinkers.as(Thinkers)
        ta = world.thing_allocation.as(ThingAllocation)

        # Remove all the current thinkers.
        enumerator = thinkers.get_enumerator
        while true
          thinker = enumerator.current
          if mobj = thinker.as?(Mobj)
            ta.remove_mobj(mobj)
          end
          break if !enumerator.move_next
        end
        thinkers.reset

        # Read in saved thinkers.
        while true
          tclass = ThinkerClass.new(@data[@ptr])
          @ptr += 1
          case tclass
          when ThinkerClass::End
            # End of list.
            return
          when ThinkerClass::Mobj
            pad_pointer
            mobj = Mobj.new(world)
            mobj.thinker_state = read_thinker_state(@data, @ptr + 8)
            mobj.x = Fixed.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 12, 4]))
            mobj.y = Fixed.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 16, 4]))
            mobj.z = Fixed.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 20, 4]))
            mobj.angle = Angle.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 32, 4]))
            mobj.sprite = Sprite.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 36, 4]))
            mobj.frame = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 40, 4])
            mobj.floor_z = Fixed.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 56, 4]))
            mobj.ceiling_z = Fixed.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 60, 4]))
            mobj.radius = Fixed.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 64, 4]))
            mobj.height = Fixed.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 68, 4]))
            mobj.mom_x = Fixed.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 72, 4]))
            mobj.mom_y = Fixed.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 76, 4]))
            mobj.mom_z = Fixed.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 80, 4]))
            mobj.type = MobjType.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 88, 4]))
            mobj.info = DoomInfo.mobj_infos[mobj.type.to_i32]
            mobj.tics = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 96, 4])
            mobj.state = DoomInfo.states[IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 100, 4])]
            mobj.flags = MobjFlags.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 104, 4]))
            mobj.health = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 108, 4])
            mobj.move_dir = Direction.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 112, 4]))
            mobj.move_count = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 116, 4])
            mobj.reaction_time = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 124, 4])
            mobj.threshold = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 128, 4])
            player_number = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 132, 4])
            if player_number != 0
              mobj.player = world.options.as(GameOptions).players[player_number - 1]
              mobj.player.as(Player).mobj = mobj
            end
            mobj.last_look = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 136, 4])
            mobj.spawn_point = MapThing.new(
              Fixed.from_i(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 140, 4])),
              Fixed.from_i(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 142, 4])),
              Angle.new(Angle.ang45.data * (IO::ByteFormat::LittleEndian.decode(Int16, @data[@ptr + 144, 2]) / 45).to_u32),
              IO::ByteFormat::LittleEndian.decode(Int16, @data[@ptr + 146, 2]),
              ThingFlags.new(IO::ByteFormat::LittleEndian.decode(Int16, @data[@ptr + 148, 2]))
            )
            @ptr += 154

            world.thing_movement.as(ThingMovement).set_thing_position(mobj)
            # mobj.floor_z = mobj.subsector.as(Subsector).sector.as(Sector).floor_height
            # mobj.ceiling_z = mobj.subsector.as(Subsector).sector.as(Sector).ceiling_height
            thinkers.add(mobj)
          else
            raise "Unknown thinker class in savegame!"
          end
        end
      end

      private def unarchive_specials(world : World)
        thinkers = world.thinkers.as(Thinkers)
        sa = world.sector_action.as(SectorAction)

        # Read in saved thinkers.
        while true
          tclass = SpecialClass.new(@data[@ptr])
          @ptr += 1
          case tclass
          when SpecialClass::EndSpecials
            # End of list.
            return
          when SpecialClass::Ceiling
            pad_pointer
            ceiling = CeilingMove.new(world)
            ceiling.thinker_state = read_thinker_state(@data, @ptr + 8)
            ceiling.type = CeilingMoveType.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 12, 4]))
            ceiling.sector = world.map.as(Map).sectors[IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 16, 4])]
            ceiling.sector.as(Sector).special_data = ceiling
            ceiling.bottom_height = Fixed.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 20, 4]))
            ceiling.top_height = Fixed.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 24, 4]))
            ceiling.speed = Fixed.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 28, 4]))
            ceiling.crush = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 32, 4]) != 0
            ceiling.direction = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 36, 4])
            ceiling.tag = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 40, 4])
            ceiling.old_direction = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 44, 4])
            @ptr += 48

            thinkers.add(ceiling)
            sa.add_active_ceiling(ceiling)
          when SpecialClass::Door
            pad_pointer
            door = VerticalDoor.new(world)
            door.thinker_state = read_thinker_state(@data, @ptr + 8)
            door.type = VerticalDoorType.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 12, 4]))
            door.sector = world.map.as(Map).sectors[IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 16, 4])]
            door.sector.as(Sector).special_data = door
            door.top_height = Fixed.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 20, 4]))
            door.speed = Fixed.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 24, 4]))
            door.direction = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 28, 4])
            door.top_wait = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 32, 4])
            door.top_count_down = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 36, 4])
            @ptr += 40

            thinkers.add(door)
          when SpecialClass::Floor
            pad_pointer
            floor = FloorMove.new(world)
            floor.thinker_state = read_thinker_state(@data, @ptr + 8)
            floor.type = FloorMoveType.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 12, 4]))
            floor.crush = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 16, 4]) != 0
            floor.sector = world.map.as(Map).sectors[IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 20, 4])]
            floor.sector.as(Sector).special_data = floor
            floor.direction = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 24, 4])
            floor.new_special = SectorSpecial.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 28, 4]))
            floor.texture = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 32, 4])
            floor.floor_dest_height = Fixed.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 36, 4]))
            floor.speed = Fixed.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 40, 4]))
            @ptr += 44

            thinkers.add(floor)
          when SpecialClass::Plat
            pad_pointer
            plat = Platform.new(world)
            plat.thinker_state = read_thinker_state(@data, @ptr + 8)
            plat.sector = world.map.as(Map).sectors[IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 12, 4])]
            plat.sector.as(Sector).special_data = plat
            plat.speed = Fixed.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 16, 4]))
            plat.low = Fixed.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 20, 4]))
            plat.high = Fixed.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 24, 4]))
            plat.wait = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 28, 4])
            plat.count = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 32, 4])
            plat.status = PlatformState.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 36, 4]))
            plat.old_status = PlatformState.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 40, 4]))
            plat.crush = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 44, 4]) != 0
            plat.tag = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 48, 4])
            plat.type = PlatformType.new(IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 52, 4]))
            @ptr += 56

            thinkers.add(plat)
            sa.add_active_platform(plat)
          when SpecialClass::Flash
            pad_pointer
            flash = LightFlash.new(world)
            flash.thinker_state = read_thinker_state(@data, @ptr + 8)
            flash.sector = world.map.as(Map).sectors[IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 12, 4])]
            flash.count = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 16, 4])
            flash.max_light = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 20, 4])
            flash.min_light = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 24, 4])
            flash.max_time = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 28, 4])
            flash.min_time = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 32, 4])
            @ptr += 36

            thinkers.add(flash)
          when SpecialClass::Strobe
            pad_pointer
            strobe = StrobeFlash.new(world)
            strobe.thinker_state = read_thinker_state(@data, @ptr + 8)
            strobe.sector = world.map.as(Map).sectors[IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 12, 4])]
            strobe.count = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 16, 4])
            strobe.min_light = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 20, 4])
            strobe.max_light = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 24, 4])
            strobe.dark_time = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 28, 4])
            strobe.bright_time = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 32, 4])
            @ptr += 36

            thinkers.add(strobe)
          when SpecialClass::Glow
            pad_pointer
            glow = GlowingLight.new(world)
            glow.thinker_state = read_thinker_state(@data, @ptr + 8)
            glow.sector = world.map.as(Map).sectors[IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 12, 4])]
            glow.min_light = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 16, 4])
            glow.max_light = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 20, 4])
            glow.direction = IO::ByteFormat::LittleEndian.decode(Int32, @data[@ptr + 24, 4])
            @ptr += 28

            thinkers.add(glow)
          else
            raise "Unknown special in savegame!"
          end
        end
      end

      private def read_thinker_state(data : Bytes, ptr : Int32)
        case IO::ByteFormat::LittleEndian.decode(Int32, data[ptr, 4])
        when 0
          return ThinkerState::InStasis
        else
          return ThinkerState::Active
        end
      end

      private def unarchive_player(player : Player, data : Bytes, ptr : Int32) : Int32
        player.clear

        player.player_state = PlayerState.new(IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 4, 4]))
        player.view_z = Fixed.new(IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 16, 4]))
        player.view_height = Fixed.new(IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 20, 4]))
        player.delta_view_height = Fixed.new(IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 24, 4]))
        player.bob = Fixed.new(IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 28, 4]))
        player.health = IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 32, 4])
        player.armor_points = IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 36, 4])
        player.armor_type = IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 40, 4])
        PowerType::Count.to_i32.times do |i|
          player.powers[i] = IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 44 + 4 * i, 4])
        end
        CardType::Count.to_i32.times do |i|
          player.cards[i] = IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 68 + 4 * i, 4]) != 0
        end
        player.backpack = IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 92, 4]) != 0
        Player::MAX_PLAYER_COUNT.times do |i|
          player.frags[i] = IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 96 + 4 * i, 4])
        end
        player.ready_weapon = WeaponType.new(IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 112, 4]))
        player.pending_weapon = WeaponType.new(IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 116, 4]))
        WeaponType::Count.to_i32.times do |i|
          player.weapon_owned[i] = IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 120 + 4 * i, 4]) != 0
        end
        AmmoType::Count.to_i32.times do |i|
          player.ammo[i] = IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 156 + 4 * i, 4])
        end
        AmmoType::Count.to_i32.times do |i|
          player.max_ammo[i] = IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 172 + 4 * i, 4])
        end
        player.attack_down = IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 188, 4]) != 0
        player.use_down = IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 192, 4]) != 0
        player.cheats = CheatFlags.new(IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 196, 4]))
        player.refire = IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 200, 4])
        player.kill_count = IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 204, 4])
        player.item_count = IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 208, 4])
        player.secret_count = IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 212, 4])
        player.damage_count = IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 220, 4])
        player.bonus_count = IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 224, 4])
        player.extra_light = IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 232, 4])
        player.fixed_colormap = IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 236, 4])
        player.colormap = IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 240, 4])
        PlayerSprite::Count.to_i32.times do |i|
          player.player_sprites[i].state = DoomInfo.states[IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 244 + 16 * i, 4])]
          if player.player_sprites[i].state.as(MobjStateDef).number == MobjState::Nil.to_i32
            player.player_sprites[i].state = nil
          end
          player.player_sprites[i].tics = IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 244 + 16 * i + 4, 4])
          player.player_sprites[i].sx = Fixed.new(IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 244 + 16 * i + 8, 4]))
          player.player_sprites[i].sy = Fixed.new(IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 244 + 16 * i + 12, 4]))
        end
        player.did_secret = IO::ByteFormat::LittleEndian.decode(Int32, data[ptr + 276, 4]) != 0

        return ptr + 280
      end

      private def unarchive_sector(sector : Sector, data : Bytes, ptr : Int32) : Int32
        sector.floor_height = Fixed.from_i(IO::ByteFormat::LittleEndian.decode(Int16, data[ptr, 2]))
        sector.ceiling_height = Fixed.from_i(IO::ByteFormat::LittleEndian.decode(Int16, data[ptr + 2, 2]))
        sector.floor_flat = IO::ByteFormat::LittleEndian.decode(Int16, data[ptr + 4, 2])
        sector.ceiling_flat = IO::ByteFormat::LittleEndian.decode(Int16, data[ptr + 6, 2])
        sector.light_level = IO::ByteFormat::LittleEndian.decode(Int16, data[ptr + 8, 2])
        sector.special = SectorSpecial.new(IO::ByteFormat::LittleEndian.decode(Int16, data[ptr + 10, 2]))
        sector.tag = IO::ByteFormat::LittleEndian.decode(Int16, data[ptr + 12, 2])
        sector.special_data = nil
        sector.sound_target = nil
        return ptr + 14
      end

      private def unarchive_line(line : LineDef, data : Bytes, ptr : Int32) : Int32
        line.flags = LineFlags.new(IO::ByteFormat::LittleEndian.decode(Int16, data[ptr, 2]))
        line.special = LineSpecial.new(IO::ByteFormat::LittleEndian.decode(Int16, data[ptr + 2, 2]))
        line.tag = IO::ByteFormat::LittleEndian.decode(Int16, data[ptr + 4, 2])
        ptr += 6

        if side = line.front_side.as?(SideDef)
          side.texture_offset = Fixed.from_i(IO::ByteFormat::LittleEndian.decode(Int16, data[ptr, 2]))
          side.row_offset = Fixed.from_i(IO::ByteFormat::LittleEndian.decode(Int16, data[ptr + 2, 2]))
          side.top_texture = IO::ByteFormat::LittleEndian.decode(Int16, data[ptr + 4, 2])
          side.bottom_texture = IO::ByteFormat::LittleEndian.decode(Int16, data[ptr + 6, 2])
          side.middle_texture = IO::ByteFormat::LittleEndian.decode(Int16, data[ptr + 8, 2])
          ptr += 10
        end

        if side = line.back_side.as?(SideDef)
          side.texture_offset = Fixed.from_i(IO::ByteFormat::LittleEndian.decode(Int16, data[ptr, 2]))
          side.row_offset = Fixed.from_i(IO::ByteFormat::LittleEndian.decode(Int16, data[ptr + 2, 2]))
          side.top_texture = IO::ByteFormat::LittleEndian.decode(Int16, data[ptr + 4, 2])
          side.bottom_texture = IO::ByteFormat::LittleEndian.decode(Int16, data[ptr + 6, 2])
          side.middle_texture = IO::ByteFormat::LittleEndian.decode(Int16, data[ptr + 8, 2])
          ptr += 10
        end

        return ptr
      end
    end
  end
end
