# Copyright (C) 2026 Devin Shwagginz
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# ==> Old crossover bindings for when I was using a two-way-bindings system
#      and working with PureDoom. Hope to get rid of this someday.

fun doom_memset(ptr : Void*, value : Int32, num : Int32)
  Doocr.doom_memset(ptr, value, num)
end

fun doom_memcpy(destination : Void*, source : Void*, num : Int32) : Void*
  Doocr.doom_memcpy(destination, source, num)
end

fun doom_strlen(str : UInt8*) : Int32
  Doocr.doom_strlen(str)
end

fun doom_concat(dst : UInt8*, src : UInt8*) : UInt8*
  Doocr.doom_concat(dst, src)
end

fun doom_strcpy(dst : UInt8*, src : UInt8*) : UInt8*
  Doocr.doom_strcpy(dst, src)
end

fun doom_strncpy(dst : UInt8*, src : UInt8*, num : Int32) : UInt8*
  Doocr.doom_strncpy(dst, src, num)
end

fun doom_strcmp(str1 : UInt8*, str2 : UInt8*) : Int32
  Doocr.doom_strcmp(str1, str2)
end

fun doom_strncmp(str1 : UInt8*, str2 : UInt8*, n : Int32) : Int32
  Doocr.doom_strncmp(str1, str2, n)
end

fun doom_toupper(c : Int32) : Int32
  Doocr.doom_toupper(c)
end

fun doom_strcasecmp(str1 : UInt8*, str2 : UInt8*) : Int32
  Doocr.doom_strcasecmp(str1, str2)
end

fun doom_strncasecmp(str1 : UInt8*, str2 : UInt8*, n : Int32) : Int32
  Doocr.doom_strncasecmp(str1, str2, n)
end

fun doom_atoi(str : UInt8*) : Int32
  Doocr.doom_atoi(str)
end

fun doom_atox(str : UInt8*) : Int32
  Doocr.doom_atox(str)
end

fun doom_itoa(k : Int32, radix : Int32) : UInt8*
  Doocr.doom_itoa(k, radix)
end

fun doom_ctoa(c : UInt8) : UInt8*
  Doocr.doom_ctoa(c)
end

fun doom_ptoa(p : Void*) : UInt8*
  Doocr.doom_ptoa(p)
end

fun doom_fprint(handle : Void*, str : UInt8*) : Int32
  Doocr.doom_fprint(handle, str)
end

fun doom_tick_midi : LibC::ULongLong
  Doocr.doom_tick_midi
end

fun doom_get_sound_buffer : Int16*
  Doocr.doom_get_sound_buffer
end

fun doom_key_down(key : Doocr::DoomKey)
  Doocr.doom_key_down(key)
end

fun doom_key_up(key : Doocr::DoomKey)
  Doocr.doom_key_up(key)
end

fun doom_button_down(button : Doocr::DoomButton)
  Doocr.doom_button_down(button)
end

fun doom_button_up(button : Doocr::DoomButton)
  Doocr.doom_button_up(button)
end

fun doom_mouse_move(delta_x : Int32, delta_y : Int32)
  Doocr.doom_mouse_move(delta_x, delta_y)
end

 

fun d_post_event = D_PostEvent(ev : CDoom::Event*)
  Doocr.d_post_event(ev)
end

fun d_process_events = D_ProcessEvents
  Doocr.d_process_events
end

fun d_display = D_Display
  Doocr.d_display
end

fun d_doom_loop = D_DoomLoop
  Doocr.d_doom_loop
end

fun d_page_ticker = D_PageTicker
  Doocr.d_page_ticker
end

fun d_page_drawer = D_PageDrawer
  Doocr.d_page_drawer
end

fun d_advance_demo = D_AdvanceDemo
  Doocr.d_advance_demo
end

fun d_do_advance_demo = D_DoAdvanceDemo
  Doocr.d_do_advance_demo
end

fun d_start_title = D_StartTitle
  Doocr.d_start_title
end

fun d_add_file = D_AddFile(file : LibC::Char*)
  Doocr.d_add_file(String.new(file))
end

fun identify_version = IdentifyVersion
  Doocr.identify_version
end

fun find_response_file = FindResponseFile
  Doocr.find_response_file
end

fun net_buffer_size = NetBufferSize : LibC::Int
  Doocr.net_buffer_size
end

fun net_buffer_checksum = NetbufferChecksum : LibC::UInt
  Doocr.net_buffer_checksum
end

fun expand_tics = ExpandTics(low : LibC::Int) : LibC::Int
  Doocr.expand_tics(low)
end

fun h_send_packet = HSendPacket(node : LibC::Int, flags : LibC::Int)
  Doocr.h_send_packet(node, flags)
end

fun h_get_packet = HGetPacket : LibC::Int
  Doocr.h_get_packet
end

fun get_packets = GetPackets
  Doocr.get_packets
end

fun net_update = NetUpdate
  Doocr.net_update
end

fun check_abort = CheckAbort
  Doocr.check_abort
end

fun d_arbitrate_net_start = D_ArbitrateNetStart
  Doocr.d_arbitrate_net_start
end

fun d_check_net_game = D_CheckNetGame
  Doocr.d_check_net_game
end

fun d_quit_net_game = D_QuitNetGame
  Doocr.d_quit_net_game
end

fun try_run_tics = TryRunTics
  Doocr.try_run_tics
end

fun f_start_finale = F_StartFinale
  Doocr.f_start_finale
end

fun f_responder = F_Responder(event : CDoom::Event*) : LibC::Int
  Doocr.f_responder(event)
end

fun f_ticker = F_Ticker
  Doocr.f_ticker
end

fun f_text_write = F_TextWrite
  Doocr.f_text_write
end

fun f_start_cast = F_StartCast
  Doocr.f_start_cast
end

fun f_cast_ticker = F_CastTicker
  Doocr.f_cast_ticker
end

fun f_cast_responder = F_CastResponder(ev : CDoom::Event*) : LibC::Int
  Doocr.f_cast_responder(ev)
end

fun f_cast_print = F_CastPrint(text : LibC::Char*)
  Doocr.f_cast_print(text)
end

fun f_cast_drawer = F_CastDrawer
  Doocr.f_cast_drawer
end

fun f_draw_patch_col = F_DrawPatchCol(x : LibC::Int, patch : CDoom::Patch*, col : LibC::Int)
  Doocr.f_draw_patch_col(x, patch, col)
end

fun f_bunny_scroll = F_BunnyScroll
  Doocr.f_bunny_scroll
end

fun f_drawer = F_Drawer
  Doocr.f_drawer
end

fun wipe_shitty_col_major_x_form = wipe_shittyColMajorXform(array : LibC::Short*, width : LibC::Int, height : LibC::Int)
  Doocr.wipe_shitty_col_major_x_form(array, width, height)
end

fun wipe_init_color_x_form = wipe_initColorXForm(width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int
  Doocr.wipe_init_color_x_form(width, height, ticks)
end

fun wipe_do_color_x_form = wipe_doColorXForm(width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int
  Doocr.wipe_do_color_x_form(width, height, ticks)
end

fun wipe_exit_color_x_form = wipe_exitColorXForm(width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int
  Doocr.wipe_exit_color_x_form(width, height, ticks)
end

fun wipe_init_melt = wipe_initMelt(width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int
  Doocr.wipe_init_melt(width, height, ticks)
end

fun wipe_do_melt = wipe_doMelt(width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int
  Doocr.wipe_do_melt(width, height, ticks)
end

fun wipe_exit_melt = wipe_exitMelt(width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int
  Doocr.wipe_exit_melt(width, height, ticks)
end

fun wipe_start_screen = wipe_StartScreen(x : LibC::Int, y : LibC::Int, width : LibC::Int, height : LibC::Int) : LibC::Int
  Doocr.wipe_start_screen(x, y, width, height)
end

fun wipe_end_screen = wipe_EndScreen(x : LibC::Int, y : LibC::Int, width : LibC::Int, height : LibC::Int) : LibC::Int
  Doocr.wipe_end_screen(x, y, width, height)
end

fun wipe_screen_wipe = wipe_ScreenWipe(wipeno : LibC::Int, x : LibC::Int, y : LibC::Int, width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int
  Doocr.wipe_screen_wipe(wipeno, x, y, width, height, ticks)
end

fun g_build_ticcmd = G_BuildTiccmd(cmd : CDoom::Ticcmd*)
  Doocr.g_build_ticcmd(cmd)
end

fun g_do_load_level = G_DoLoadLevel
  Doocr.g_do_load_level
end

fun g_responder = G_Responder(ev : CDoom::Event*) : LibC::Int
  Doocr.g_responder(ev)
end

fun g_ticker = G_Ticker
  Doocr.g_ticker
end

fun g_init_player = G_InitPlayer(player : LibC::Int)
  Doocr.g_init_player(player)
end

fun g_player_finish_level = G_PlayerFinishLevel(player : LibC::Int)
  Doocr.g_player_finish_level(player)
end

fun g_player_reborn = G_PlayerReborn(player : LibC::Int)
  Doocr.g_player_reborn(player)
end

fun g_check_spot = G_CheckSpot(playernum : LibC::Int, mthing : CDoom::Mapthing*) : LibC::Int
  Doocr.g_check_spot(playernum, mthing)
end

fun g_deathmatch_spawn_player = G_DeathMatchSpawnPlayer(playernum : LibC::Int)
  Doocr.g_deathmatch_spawn_player(playernum)
end

fun g_do_reborn = G_DoReborn(playernum : LibC::Int)
  Doocr.g_do_reborn(playernum)
end

fun g_screenshot = G_ScreenShot
  Doocr.g_screenshot
end

fun g_exit_level = G_ExitLevel
  Doocr.g_exit_level
end

fun g_secret_exit_level = G_SecretExitLevel
  Doocr.g_secret_exit_level
end

fun g_do_completed = G_DoCompleted
  Doocr.g_do_completed
end

fun g_world_done = G_WorldDone
  Doocr.g_world_done
end

fun g_do_world_done = G_DoWorldDone
  Doocr.g_do_world_done
end

fun g_load_game = G_LoadGame(name : LibC::Char*)
  Doocr.g_load_game(name)
end

fun g_do_load_game = G_DoLoadGame
  Doocr.g_do_load_game
end

fun g_save_game = G_SaveGame(slot : LibC::Int, description : LibC::Char*)
  Doocr.g_save_game(slot, description)
end

fun g_do_save_game = G_DoSaveGame
  Doocr.g_do_save_game
end

fun g_defered_init_new = G_DeferedInitNew(skill : Doocr::Skill, episode : LibC::Int, map : LibC::Int)
  Doocr.g_defered_init_new(skill, episode, map)
end

fun g_do_new_game = G_DoNewGame
  Doocr.g_do_new_game
end

fun g_init_new = G_InitNew(skill : Doocr::Skill, episode : LibC::Int, map : LibC::Int)
  Doocr.g_init_new(skill, episode, map)
end

fun g_read_demo_ticcmd = G_ReadDemoTiccmd(cmd : CDoom::Ticcmd*)
  Doocr.g_read_demo_ticcmd(cmd)
end

fun g_write_demo_ticcmd = G_WriteDemoTiccmd(cmd : CDoom::Ticcmd*)
  Doocr.g_write_demo_ticcmd(cmd)
end

fun g_record_demo = G_RecordDemo(name : LibC::Char*)
  Doocr.g_record_demo(name)
end

fun g_begin_recording = G_BeginRecording
  Doocr.g_begin_recording
end

fun g_defered_play_demo = G_DeferedPlayDemo(demo : LibC::Char*)
  Doocr.g_defered_play_demo(demo)
end

fun p_give_power = P_GivePower(player : CDoom::Player*, power : LibC::Int) : LibC::Int
  Doocr.p_give_power(player, power)
end

fun g_do_play_demo = G_DoPlayDemo
  Doocr.g_do_play_demo
end

fun g_time_demo = G_TimeDemo(name : LibC::Char*)
  Doocr.g_time_demo(name)
end

fun g_check_demo_status = G_CheckDemoStatus : LibC::Int
  Doocr.g_check_demo_status
end

fun hulib_clear_text_line = HUlib_clearTextLine(t : CDoom::HU_Textline*)
  Doocr.hulib_clear_text_line(t)
end

fun hulib_init_text_line = HUlib_initTextLine(t : CDoom::HU_Textline*, x : LibC::Int, y : LibC::Int, f : CDoom::Patch**, sc : LibC::Int)
  Doocr.hulib_init_text_line(t, x, y, f, sc)
end

fun hulib_add_char_to_text_line = HUlib_addCharToTextLine(t : CDoom::HU_Textline*, ch : LibC::Char) : LibC::Int
  Doocr.hulib_add_char_to_text_line(t, ch)
end

fun hulib_del_char_from_text_line = HUlib_delCharFromTextLine(t : CDoom::HU_Textline*) : LibC::Int
  Doocr.hulib_del_char_from_text_line(t)
end

fun hulib_draw_text_line = HUlib_drawTextLine(l : CDoom::HU_Textline*, drawcursor : LibC::Int)
  Doocr.hulib_draw_text_line(l, drawcursor)
end

fun hulib_erase_text_line = HUlib_eraseTextLine(l : CDoom::HU_Textline*)
  Doocr.hulib_erase_text_line(l)
end

fun hulib_init_s_text = HUlib_initSText(s : CDoom::HU_Stext*,
                                        x : LibC::Int,
                                        y : LibC::Int,
                                        h : LibC::Int,
                                        font : CDoom::Patch**,
                                        startchar : LibC::Int,
                                        on : LibC::Int*)
  Doocr.hulib_init_s_text(s, x, y, h, font, startchar, on)
end

fun hulib_add_line_to_s_text = HUlib_addLineToSText(s : CDoom::HU_Stext*)
  Doocr.hulib_add_line_to_s_text(s)
end

fun hulib_add_message_to_s_text = HUlib_addMessageToSText(s : CDoom::HU_Stext*, prefix : LibC::Char*, msg : LibC::Char*)
  Doocr.hulib_add_message_to_s_text(s, prefix, msg)
end

fun hulib_draw_s_text = HUlib_drawSText(s : CDoom::HU_Stext*)
  Doocr.hulib_draw_s_text(s)
end

fun hulib_erase_s_text = HUlib_eraseSText(s : CDoom::HU_Stext*)
  Doocr.hulib_erase_s_text(s)
end

fun hulib_init_i_text = HUlib_initIText(it : CDoom::HU_Itext*,
                                        x : LibC::Int,
                                        y : LibC::Int,
                                        font : CDoom::Patch**,
                                        startchar : LibC::Int,
                                        on : LibC::Int*)
  Doocr.hulib_init_i_text(it, x, y, font, startchar, on)
end

fun hulib_del_char_from_i_text = HUlib_delCharFromIText(it : CDoom::HU_Itext*)
  Doocr.hulib_del_char_from_i_text(it)
end

fun hulib_erase_line_from_i_text = HUlib_eraseLineFromIText(it : CDoom::HU_Itext*)
  Doocr.hulib_erase_line_from_i_text(it)
end

fun hulib_reset_i_text = HUlib_resetIText(it : CDoom::HU_Itext*)
  Doocr.hulib_reset_i_text(it)
end

fun hulib_add_prefix_to_i_text = HUlib_addPrefixToIText(it : CDoom::HU_Itext*, str : LibC::Char*)
  Doocr.hulib_add_prefix_to_i_text(it, str)
end

fun hulib_key_in_i_text = HUlib_keyInIText(it : CDoom::HU_Itext*, ch : LibC::UChar) : LibC::Int
  Doocr.hulib_key_in_i_text(it, ch)
end

fun hulib_draw_i_text = HUlib_drawIText(it : CDoom::HU_Itext*)
  Doocr.hulib_draw_i_text(it)
end

fun hulib_erase_i_text = HUlib_eraseIText(it : CDoom::HU_Itext*)
  Doocr.hulib_erase_i_text(it)
end

fun foreign_translation = ForeignTranslation(ch : LibC::Char) : LibC::Char
  Doocr.foreign_translation(ch)
end

fun hu_init = HU_Init
  Doocr.hu_init
end

fun hu_stop = HU_Stop
  Doocr.hu_stop
end

fun hu_start = HU_Start
  Doocr.hu_start
end

fun hu_drawer = HU_Drawer
  Doocr.hu_drawer
end

fun hu_erase = HU_Erase
  Doocr.hu_erase
end

fun hu_ticker = HU_Ticker
  Doocr.hu_ticker
end

fun hu_queue_chat_char = HU_queueChatChar(c : LibC::Char)
  Doocr.hu_queue_chat_char(c)
end

fun hu_dequeue_chat_char = HU_dequeueChatChar : LibC::Char
  Doocr.hu_dequeue_chat_char
end

fun hu_responder = HU_Responder(ev : CDoom::Event*) : LibC::Int
  Doocr.hu_responder(ev)
end

fun i_init_network = I_InitNetwork
  Doocr.i_init_network
end

fun i_net_cmd = I_NetCmd
  Doocr.i_net_cmd
end

fun getsfx(sfxname : LibC::Char*, len : LibC::Int*) : Void*
  Doocr.getsfx(sfxname, len)
end

fun addsfx(sfxid : LibC::Int, volume : LibC::Int, step : LibC::Int, seperation : LibC::Int) : LibC::Int
  Doocr.addsfx(sfxid, volume, step, seperation)
end

fun i_set_channels = I_SetChannels
  Doocr.i_set_channels
end

fun i_set_music_volume = I_SetMusicVolume(volume : LibC::Int)
  Doocr.i_set_music_volume(volume)
end

fun i_get_sfx_lump_num = I_GetSfxLumpNum(sfx : CDoom::Sfxinfo*) : LibC::Int
  Doocr.i_get_sfx_lump_num(sfx)
end

fun i_start_sound = I_StartSound(id : LibC::Int, vol : LibC::Int, sep : LibC::Int, pitch : LibC::Int, priority : LibC::Int) : LibC::Int
  Doocr.i_start_sound(id, vol, sep, pitch, priority)
end

fun i_stop_sound = I_StopSound(handle : LibC::Int)
  Doocr.i_stop_sound(handle)
end

fun i_sound_is_playing = I_SoundIsPlaying(handle : LibC::Int) : LibC::Int
  Doocr.i_sound_is_playing(handle)
end

fun i_update_sound = I_UpdateSound
  Doocr.i_update_sound
end

fun i_update_sound_params = I_UpdateSoundParams(handle : LibC::Int, vol : LibC::Int, sep : LibC::Int, pitch : LibC::Int)
  Doocr.i_update_sound_params(handle, vol, sep, pitch)
end

fun i_shutdown_sound = I_ShutdownSound
  Doocr.i_shutdown_sound
end

fun i_init_sound = I_InitSound
  Doocr.i_init_sound
end

fun i_init_music = I_InitMusic
  Doocr.i_init_music
end

fun i_shutdown_music = I_ShutdownMusic
  Doocr.i_shutdown_music
end

fun i_play_song = I_PlaySong(handle : LibC::Int, looping : LibC::Int)
  Doocr.i_play_song(handle, looping)
end

fun i_pause_song = I_PauseSong(handle : LibC::Int)
  Doocr.i_pause_song(handle)
end

fun i_resume_song = I_ResumeSong(handle : LibC::Int)
  Doocr.i_resume_song(handle)
end

fun reset_all_channels
  Doocr.reset_all_channels
end

fun i_stop_song = I_StopSong(handle : LibC::Int)
  Doocr.i_stop_song(handle)
end

fun i_unregister_song = I_UnRegisterSong(handle : LibC::Int)
  Doocr.i_unregister_song(handle)
end

fun i_register_song = I_RegisterSong(data : Void*) : LibC::Int
  Doocr.i_register_song(data)
end

fun i_qry_song_playing = I_QrySongPlaying(handle : LibC::Int) : LibC::Int
  Doocr.i_qry_song_playing(handle)
end

fun i_tick_song = I_TickSong : LibC::ULongLong
  Doocr.i_tick_song
end

fun i_tactile = I_Tactile(on : LibC::Int, off : LibC::Int, total : LibC::Int)
  Doocr.i_tactile(on, off, total)
end

fun i_base_ticcmd = I_BaseTiccmd : CDoom::Ticcmd*
  Doocr.i_base_ticcmd
end

fun i_get_heap_size = I_GetHeapSize : LibC::Int
  Doocr.i_get_heap_size
end

fun i_zone_base = I_ZoneBase(size : LibC::Int*) : UInt8*
  Doocr.i_zone_base(size)
end

fun i_get_time = I_GetTime : LibC::Int
  Doocr.i_get_time
end

fun i_init = I_Init
  Doocr.i_init
end

fun i_quit = I_Quit
  Doocr.i_quit
end

fun i_wait_vbl = I_WaitVBL(count : LibC::Int)
  Doocr.i_wait_vbl(count)
end

fun i_shutdown_graphics = I_ShutdownGraphics
  Doocr.i_shutdown_graphics
end

fun i_init_graphics = I_InitGraphics
  Doocr.i_init_graphics
end

fun i_alloc_low = I_AllocLow(length : LibC::Int) : UInt8*
  Doocr.i_alloc_low(length)
end

fun i_error = I_Error(error : LibC::Char*)
  Doocr.i_error(String.new(error))
end

fun i_shutdown_graphics = I_ShutdownGraphics
  Doocr.i_shutdown_graphics
end

fun i_start_frame = I_StartFrame
  Doocr.i_start_frame
end

fun i_start_tic = I_StartTic
  Doocr.i_start_tic
end

fun i_update_no_blit = I_UpdateNoBlit
  Doocr.i_update_no_blit
end

fun i_finish_update = I_FinishUpdate
  Doocr.i_finish_update
end

fun i_read_screen = I_ReadScreen(scr : UInt8*)
  Doocr.i_read_screen(scr)
end

fun i_set_palette = I_SetPalette(palette : UInt8*)
  Doocr.i_set_palette(palette)
end

fun i_init_graphics = I_InitGraphics
  Doocr.i_init_graphics
end

fun m_clear_box = M_ClearBox(box : LibC::Int*)
  Doocr.m_clear_box(box)
end

fun m_add_to_box = M_AddToBox(box : LibC::Int*, x : LibC::Int, y : LibC::Int)
  Doocr.m_add_to_box(box, x, y)
end

fun cht_check_cheat = cht_CheckCheat(cht : CDoom::Cheatseq*, key : LibC::Char) : LibC::Int
  Doocr.cht_check_cheat(Doocr.cheat_me, key.to_u8!)
end

fun cht_get_param = cht_GetParam(cht : CDoom::Cheatseq*, buffer : LibC::Char*)
  Doocr.cht_get_param(Doocr.cheat_me, buffer)
end

fun fixed_mul = FixedMul(a : LibC::Int, b : LibC::Int) : LibC::Int
  Doocr.fixed_mul(a, b)
end

fun fixed_div = FixedDiv(a : LibC::Int, b : LibC::Int) : LibC::Int
  Doocr.fixed_div(a, b)
end

fun fixed_div2 = FixedDiv2(a : LibC::Int, b : LibC::Int) : LibC::Int
  Doocr.fixed_div2(a, b)
end

fun m_read_save_strings = M_ReadSaveStrings
  Doocr.m_read_save_strings
end

fun m_draw_load = M_DrawLoad
  Doocr.m_draw_load
end

fun m_draw_save_load_border = M_DrawSaveLoadBorder(x : LibC::Int, y : LibC::Int)
  Doocr.m_draw_save_load_border(x, y)
end

fun m_load_select = M_LoadSelect(choice : LibC::Int)
  Doocr.m_load_select(choice)
end

fun m_load_game = M_LoadGame(choice : LibC::Int)
  Doocr.m_load_game(choice)
end

fun m_draw_save = M_DrawSave
  Doocr.m_draw_save
end

fun m_do_save = M_DoSave(slot : LibC::Int)
  Doocr.m_do_save(slot)
end

fun m_save_select = M_SaveSelect(choice : LibC::Int)
  Doocr.m_save_select(choice)
end

fun m_save_game = M_SaveGame(choice : LibC::Int)
  Doocr.m_save_game(choice)
end

fun m_quicksave_response = M_QuickSaveResponse(ch : LibC::Int)
  Doocr.m_quicksave_response(ch)
end

fun m_quicksave = M_QuickSave
  Doocr.m_quicksave
end

fun m_quickload_response = M_QuickLoadResponse(ch : LibC::Int)
  Doocr.m_quickload_response(ch)
end

fun m_quickload = M_QuickLoad
  Doocr.m_quickload
end

fun m_draw_readthis1 = M_DrawReadThis1
  Doocr.m_draw_readthis1
end

fun m_draw_readthis2 = M_DrawReadThis2
  Doocr.m_draw_readthis2
end

fun m_draw_sound = M_DrawSound
  Doocr.m_draw_sound
end

fun m_sound = M_Sound(choice : LibC::Int)
  Doocr.m_sound(choice)
end

fun m_sfxvol = M_SfxVol(choice : LibC::Int)
  Doocr.m_sfxvol(choice)
end

fun m_musicvol = M_MusicVol(choice : LibC::Int)
  Doocr.m_musicvol(choice)
end

fun m_draw_mainmenu = M_DrawMainMenu
  Doocr.m_draw_mainmenu
end

fun m_draw_newgame = M_DrawNewGame
  Doocr.m_draw_newgame
end

fun m_new_game = M_NewGame(choice : LibC::Int)
  Doocr.m_new_game(choice)
end

fun m_draw_episode = M_DrawEpisode
  Doocr.m_draw_episode
end

fun m_verify_nightmare = M_VerifyNightmare(ch : LibC::Int)
  Doocr.m_verify_nightmare(ch)
end

fun m_choose_skill = M_ChooseSkill(choice : LibC::Int)
  Doocr.m_choose_skill(choice)
end

fun m_episode = M_Episode(choice : LibC::Int)
  Doocr.m_episode(choice)
end

fun m_draw_options = M_DrawOptions
  Doocr.m_draw_options
end

fun m_options = M_Options(choice : LibC::Int)
  Doocr.m_options(choice)
end

fun m_change_messages = M_ChangeMessages(choice : LibC::Int)
  Doocr.m_change_messages(choice)
end

fun m_change_crosshair = M_ChangeCrosshair(choice : LibC::Int)
  Doocr.m_change_crosshair(choice)
end

fun m_change_alwaysrun = M_ChangeAlwaysRun(choice : LibC::Int)
  Doocr.m_change_alwaysrun(choice)
end

fun m_endgame_response = M_EndGameResponse(ch : Int32)
  Doocr.m_endgame_response(ch)
end

fun m_endgame = M_EndGame(choice : LibC::Int)
  Doocr.m_endgame(choice)
end

fun m_readthis = M_ReadThis(choice : LibC::Int)
  Doocr.m_readthis(choice)
end

fun m_readthis2 = M_ReadThis2(choice : LibC::Int)
  Doocr.m_readthis2(choice)
end

fun m_finish_readthis = M_FinishReadThis(choice : LibC::Int)
  Doocr.m_finish_readthis(choice)
end

fun m_quit_response = M_QuitResponse(ch : LibC::Int)
  Doocr.m_quit_response(ch)
end

fun m_change_sensitivity = M_ChangeSensitivity(choice : LibC::Int)
  Doocr.m_change_sensitivity(choice)
end

fun m_mouse_move = M_MouseMove(choice : LibC::Int)
  Doocr.m_mouse_move(choice)
end

fun m_size_display = M_SizeDisplay(choice : LibC::Int)
  Doocr.m_size_display(choice)
end

fun m_draw_thermo = M_DrawThermo(x : LibC::Int, y : LibC::Int, therm_width : LibC::Int, therm_dot : LibC::Int)
  Doocr.m_draw_thermo(x, y, therm_width, therm_dot)
end

fun m_stop_message = M_StopMessage
  Doocr.m_stop_message
end

fun m_string_height = M_StringHeight(string : LibC::Char*) : LibC::Int
  Doocr.m_string_height(string)
end

fun m_start_control_panel = M_StartControlPanel
  Doocr.m_start_control_panel
end

fun m_drawer = M_Drawer
  Doocr.m_drawer
end

fun m_clear_menus = M_ClearMenus
  Doocr.m_clear_menus
end

fun m_ticker = M_Ticker
  Doocr.m_ticker
end

fun m_draw_text(x : LibC::Int, y : LibC::Int, direct : LibC::Int, string : LibC::Char*) : LibC::Int
  Doocr.m_draw_text(x, y, direct, string)
end

fun m_write_file = M_WriteFile(name : LibC::Char*, source : Void*, length : LibC::Int) : LibC::Int
  Doocr.m_write_file(name, source, length)
end

fun m_save_defaults = M_SaveDefaults
  Doocr.m_save_defaults
end

fun m_load_defaults = M_LoadDefaults
  Doocr.m_load_defaults
end


fun m_screenshot = M_ScreenShot
  Doocr.m_screenshot
end

fun p_random = P_Random : LibC::Int
  Doocr.p_random
end

fun m_random = M_Random : LibC::Int
  Doocr.m_random
end

fun m_clear_random = M_ClearRandom
  Doocr.m_clear_random
end

fun t_move_ceiling = T_MoveCeiling(ceiling : CDoom::Ceiling*)
  Doocr.t_move_ceiling(ceiling)
end

fun ev_do_ceiling = EV_DoCeiling(line : CDoom::Line*, type : Doocr::Ceilingenum) : LibC::Int
  Doocr.ev_do_ceiling(line, type)
end

fun p_add_active_ceiling = P_AddActiveCeiling(c : CDoom::Ceiling*)
  Doocr.p_add_active_ceiling(c)
end

fun p_remove_active_ceiling = P_RemoveActiveCeiling(c : CDoom::Ceiling*)
  Doocr.p_remove_active_ceiling(c)
end

fun p_activate_in_stasis_ceiling = P_ActivateInStasisCeiling(line : CDoom::Line*)
  Doocr.p_activate_in_stasis_ceiling(line)
end

fun ev_ceiling_crush_stop = EV_CeilingCrushStop(line : CDoom::Line*) : LibC::Int
  Doocr.ev_ceiling_crush_stop(line)
end

fun t_vertical_door = T_VerticalDoor(door : CDoom::Vldoor*)
  Doocr.t_vertical_door(door)
end

fun ev_do_locked_door = EV_DoLockedDoor(line : CDoom::Line*, type : Doocr::Vldoorenum, thing : CDoom::Mobj*) : LibC::Int
  Doocr.ev_do_locked_door(line, type, thing)
end

fun ev_do_door = EV_DoDoor(line : CDoom::Line*, type : Doocr::Vldoorenum) : LibC::Int
  Doocr.ev_do_door(line, type)
end

fun ev_vertical_door = EV_VerticalDoor(line : CDoom::Line*, thing : CDoom::Mobj*)
  Doocr.ev_vertical_door(line, thing)
end

fun p_spawn_door_close_in_30 = P_SpawnDoorCloseIn30(sec : CDoom::Sector*)
  Doocr.p_spawn_door_close_in_30(sec)
end

fun p_spawn_door_raise_in_5_mins = P_SpawnDoorRaiseIn5Mins(sec : CDoom::Sector*, secnum : LibC::Int)
  Doocr.p_spawn_door_raise_in_5_mins(sec, secnum)
end

fun p_recursive_sound = P_RecursiveSound(sec : CDoom::Sector*, soundblocks : LibC::Int)
  Doocr.p_recursive_sound(sec, soundblocks)
end

fun p_noise_alert = P_NoiseAlert(target : CDoom::Mobj*, emmiter : CDoom::Mobj*)
  Doocr.p_noise_alert(target, emmiter)
end

fun p_check_melee_range = P_CheckMeleeRange(actor : CDoom::Mobj*) : LibC::Int
  Doocr.p_check_melee_range(actor)
end

fun p_check_missile_range = P_CheckMissileRange(actor : CDoom::Mobj*) : LibC::Int
  Doocr.p_check_missile_range(actor)
end

fun p_move = P_Move(actor : CDoom::Mobj*) : LibC::Int
  Doocr.p_move(actor)
end

fun p_try_walk = P_TryWalk(actor : CDoom::Mobj*) : LibC::Int
  Doocr.p_try_walk(actor)
end

fun p_new_chase_dir = P_NewChaseDir(actor : CDoom::Mobj*)
  Doocr.p_new_chase_dir(actor)
end

fun p_look_for_players = P_LookForPlayers(actor : CDoom::Mobj*, allaround : LibC::Int) : LibC::Int
  Doocr.p_look_for_players(actor, allaround)
end

fun a_keen_die = A_KeenDie(mo : CDoom::Mobj*)
  Doocr.a_keen_die(mo)
end

fun a_look = A_Look(actor : CDoom::Mobj*)
  Doocr.a_look(actor)
end

fun a_chase = A_Chase(actor : CDoom::Mobj*)
  Doocr.a_chase(actor)
end

fun a_face_target = A_FaceTarget(actor : CDoom::Mobj*)
  Doocr.a_face_target(actor)
end

fun a_pos_attack = A_PosAttack(actor : CDoom::Mobj*)
  Doocr.a_pos_attack(actor)
end

fun a_spos_attack = A_SPosAttack(actor : CDoom::Mobj*)
  Doocr.a_spos_attack(actor)
end

fun a_cpos_attack = A_CPosAttack(actor : CDoom::Mobj*)
  Doocr.a_cpos_attack(actor)
end

fun a_cpos_refire = A_CPosRefire(actor : CDoom::Mobj*)
  Doocr.a_cpos_refire(actor)
end

fun a_spid_refire = A_SpidRefire(actor : CDoom::Mobj*)
  Doocr.a_spid_refire(actor)
end

fun a_bspi_attack = A_BspiAttack(actor : CDoom::Mobj*)
  Doocr.a_bspi_attack(actor)
end

fun a_troop_attack = A_TroopAttack(actor : CDoom::Mobj*)
  Doocr.a_troop_attack(actor)
end

fun a_sarg_attack = A_SargAttack(actor : CDoom::Mobj*)
  Doocr.a_sarg_attack(actor)
end

fun a_head_attack = A_HeadAttack(actor : CDoom::Mobj*)
  Doocr.a_head_attack(actor)
end

fun a_cyber_attack = A_CyberAttack(actor : CDoom::Mobj*)
  Doocr.a_cyber_attack(actor)
end

fun a_bruis_attack = A_BruisAttack(actor : CDoom::Mobj*)
  Doocr.a_bruis_attack(actor)
end

fun a_skel_missile = A_SkelMissile(actor : CDoom::Mobj*)
  Doocr.a_skel_missile(actor)
end

fun a_tracer = A_Tracer(actor : CDoom::Mobj*)
  Doocr.a_tracer(actor)
end

fun a_skel_whoosh = A_SkelWhoosh(actor : CDoom::Mobj*)
  Doocr.a_skel_whoosh(actor)
end

fun a_skel_fist = A_SkelFist(actor : CDoom::Mobj*)
  Doocr.a_skel_fist(actor)
end

fun pit_vile_check = PIT_VileCheck(thing : CDoom::Mobj*) : LibC::Int
  Doocr.pit_vile_check(thing)
end

fun a_vile_chase = A_VileChase(actor : CDoom::Mobj*)
  Doocr.a_vile_chase(actor)
end

fun a_vile_start = A_VileStart(actor : CDoom::Mobj*)
  Doocr.a_vile_start(actor)
end

fun a_start_fire = A_StartFire(actor : CDoom::Mobj*)
  Doocr.a_start_fire(actor)
end

fun a_fire_crackle = A_FireCrackle(actor : CDoom::Mobj*)
  Doocr.a_fire_crackle(actor)
end

fun a_fire = A_Fire(actor : CDoom::Mobj*)
  Doocr.a_fire(actor)
end

fun a_vile_target = A_VileTarget(actor : CDoom::Mobj*)
  Doocr.a_vile_target(actor)
end

fun a_vile_attack = A_VileAttack(actor : CDoom::Mobj*)
  Doocr.a_vile_attack(actor)
end

fun a_fat_raise = A_FatRaise(actor : CDoom::Mobj*)
  Doocr.a_fat_raise(actor)
end

fun a_fat_attack1 = A_FatAttack1(actor : CDoom::Mobj*)
  Doocr.a_fat_attack1(actor)
end

fun a_fat_attack2 = A_FatAttack2(actor : CDoom::Mobj*)
  Doocr.a_fat_attack2(actor)
end

fun a_fat_attack3 = A_FatAttack3(actor : CDoom::Mobj*)
  Doocr.a_fat_attack3(actor)
end

fun a_skull_attack = A_SkullAttack(actor : CDoom::Mobj*)
  Doocr.a_skull_attack(actor)
end

fun a_pain_shoot_skull = A_PainShootSkull(actor : CDoom::Mobj*, angle : LibC::UInt)
  Doocr.a_pain_shoot_skull(actor, angle)
end

fun a_pain_attack = A_PainAttack(actor : CDoom::Mobj*)
  Doocr.a_pain_attack(actor)
end

fun a_pain_die = A_PainDie(actor : CDoom::Mobj*)
  Doocr.a_pain_die(actor)
end

fun a_scream = A_Scream(actor : CDoom::Mobj*)
  Doocr.a_scream(actor)
end

fun a_xscream = A_XScream(actor : CDoom::Mobj*)
  Doocr.a_xscream(actor)
end

fun a_pain = A_Pain(actor : CDoom::Mobj*)
  Doocr.a_pain(actor)
end

fun a_fall = A_Fall(actor : CDoom::Mobj*)
  Doocr.a_fall(actor)
end

fun a_explode = A_Explode(thingy : CDoom::Mobj*)
  Doocr.a_explode(thingy)
end

fun a_boss_death = A_BossDeath(mo : CDoom::Mobj*)
  Doocr.a_boss_death(mo)
end

fun a_hoof = A_Hoof(mo : CDoom::Mobj*)
  Doocr.a_hoof(mo)
end

fun a_metal = A_Metal(mo : CDoom::Mobj*)
  Doocr.a_metal(mo)
end

fun a_baby_metal = A_BabyMetal(mo : CDoom::Mobj*)
  Doocr.a_baby_metal(mo)
end

fun a_open_shotgun2 = A_OpenShotgun2(player : CDoom::Player*, psp : CDoom::Pspdef*)
  Doocr.a_open_shotgun2(player, psp)
end

fun a_load_shotgun2 = A_LoadShotgun2(player : CDoom::Player*, psp : CDoom::Pspdef*)
  Doocr.a_load_shotgun2(player, psp)
end

fun a_close_shotgun2 = A_CloseShotgun2(player : CDoom::Player*, psp : CDoom::Pspdef*)
  Doocr.a_close_shotgun2(player, psp)
end

fun a_brain_awake = A_BrainAwake(mo : CDoom::Mobj*)
  Doocr.a_brain_awake(mo)
end

fun a_brain_pain = A_BrainPain(mo : CDoom::Mobj*)
  Doocr.a_brain_pain(mo)
end

fun a_brain_scream = A_BrainScream(mo : CDoom::Mobj*)
  Doocr.a_brain_scream(mo)
end

fun a_brain_explode = A_BrainExplode(mo : CDoom::Mobj*)
  Doocr.a_brain_explode(mo)
end

fun a_brain_die = A_BrainDie(mo : CDoom::Mobj*)
  Doocr.a_brain_die(mo)
end

fun a_brain_spit = A_BrainSpit(mo : CDoom::Mobj*)
  Doocr.a_brain_spit(mo)
end

fun a_spawn_sound = A_SpawnSound(mo : CDoom::Mobj*)
  Doocr.a_spawn_sound(mo)
end

fun a_spawn_fly = A_SpawnFly(mo : CDoom::Mobj*)
  Doocr.a_spawn_fly(mo)
end

fun a_player_scream = A_PlayerScream(mo : CDoom::Mobj*)
  Doocr.a_player_scream(mo)
end

fun t_move_plane = T_MovePlane(sector : CDoom::Sector*, speed : LibC::Int, dest : LibC::Int, crush : LibC::Int, floor_or_ceiling : LibC::Int, direction : LibC::Int) : Doocr::Result
  Doocr.t_move_plane(sector, speed, dest, crush, floor_or_ceiling, direction)
end

fun t_move_floor = T_MoveFloor(floor : CDoom::Floormove*)
  Doocr.t_move_floor(floor)
end

fun ev_do_floor = EV_DoFloor(line : CDoom::Line*, floortype : Doocr::Floorenum) : LibC::Int
  Doocr.ev_do_floor(line, floortype)
end

fun ev_build_stairs = EV_BuildStairs(line : CDoom::Line*, type : Doocr::Stairenum) : LibC::Int
  Doocr.ev_build_stairs(line, type)
end

fun p_give_ammo = P_GiveAmmo(player : CDoom::Player*, ammo : Doocr::Ammotype, num : LibC::Int) : LibC::Int
  Doocr.p_give_ammo(player, ammo, num)
end

fun p_give_weapon = P_GiveWeapon(player : CDoom::Player*, weapon : Doocr::Weapontype, dropped : LibC::Int) : LibC::Int
  Doocr.p_give_weapon(player, weapon, dropped)
end

fun p_give_body = P_GiveBody(player : CDoom::Player*, num : LibC::Int) : LibC::Int
  Doocr.p_give_body(player, num)
end

fun p_give_armor = P_GiveArmor(player : CDoom::Player*, armortype : LibC::Int) : LibC::Int
  Doocr.p_give_armor(player, armortype)
end

fun p_give_card = P_GiveCard(player : CDoom::Player*, card : Doocr::Card)
  Doocr.p_give_card(player, card)
end

fun p_touch_special_thing = P_TouchSpecialThing(special : CDoom::Mobj*, toucher : CDoom::Mobj*)
  Doocr.p_touch_special_thing(special, toucher)
end

fun p_kill_mobj = P_KillMobj(source : CDoom::Mobj*, target : CDoom::Mobj*)
  Doocr.p_kill_mobj(source, target)
end

fun p_damage_mobj = P_DamageMobj(target : CDoom::Mobj*, inflictor : CDoom::Mobj*, source : CDoom::Mobj*, damage : LibC::Int)
  Doocr.p_damage_mobj(target, inflictor, source, damage)
end

fun t_fire_flicker = T_FireFlicker(flick : CDoom::Fireflicker*)
  Doocr.t_fire_flicker(flick)
end

fun p_spawn_fire_flicker = P_SpawnFireFlicker(sector : CDoom::Sector*)
  Doocr.p_spawn_fire_flicker(sector)
end

fun t_light_flash = T_LightFlash(flash : CDoom::Lightflash*)
  Doocr.t_light_flash(flash)
end

fun p_spawn_light_flash = P_SpawnLightFlash(sector : CDoom::Sector*)
  Doocr.p_spawn_light_flash(sector)
end

fun t_strobe_flash = T_StrobeFlash(flash : CDoom::Strobe*)
  Doocr.t_strobe_flash(flash)
end

fun p_spawn_strobe_flash = P_SpawnStrobeFlash(sector : CDoom::Sector*, fast_or_slow : LibC::Int, in_sync : LibC::Int)
  Doocr.p_spawn_strobe_flash(sector, fast_or_slow, in_sync)
end

fun ev_start_light_strobing = EV_StartLightStrobing(line : CDoom::Line*)
  Doocr.ev_start_light_strobing(line)
end

fun ev_turn_tag_lights_off = EV_TurnTagLightsOff(line : CDoom::Line*)
  Doocr.ev_turn_tag_lights_off(line)
end

fun ev_light_turn_on = EV_LightTurnOn(line : CDoom::Line*, bright : LibC::Int)
  Doocr.ev_light_turn_on(line, bright)
end

fun t_glow = T_Glow(g : CDoom::Glow*)
  Doocr.t_glow(g)
end

fun p_spawn_glowing_light = P_SpawnGlowingLight(sector : CDoom::Sector*)
  Doocr.p_spawn_glowing_light(sector)
end

fun pit_stomp_thing = PIT_StompThing(thing : CDoom::Mobj*) : LibC::Int
  Doocr.pit_stomp_thing(thing)
end

fun p_teleport_move = P_TeleportMove(thing : CDoom::Mobj*, x : LibC::Int, y : LibC::Int) : LibC::Int
  Doocr.p_teleport_move(thing, x, y)
end

fun pit_check_line = PIT_CheckLine(ld : CDoom::Line*) : LibC::Int
  Doocr.pit_check_line(ld)
end

fun pit_check_thing = PIT_CheckThing(thing : CDoom::Mobj*) : LibC::Int
  Doocr.pit_check_thing(thing)
end

fun p_check_position = P_CheckPosition(thing : CDoom::Mobj*, x : LibC::Int, y : LibC::Int) : LibC::Int
  Doocr.p_check_position(thing, x, y)
end

fun p_try_move = P_TryMove(thing : CDoom::Mobj*, x : LibC::Int, y : LibC::Int) : LibC::Int
  Doocr.p_try_move(thing, x, y)
end

fun p_thing_height_clip = P_ThingHeightClip(thing : CDoom::Mobj*) : LibC::Int
  Doocr.p_thing_height_clip(thing)
end

fun p_hit_slide_line = P_HitSlideLine(ld : CDoom::Line*)
  Doocr.p_hit_slide_line(ld)
end

fun ptr_slide_traverse = PTR_SlideTraverse(int : CDoom::Intercept*) : LibC::Int
  Doocr.ptr_slide_traverse(int)
end

fun p_slide_move = P_SlideMove(mo : CDoom::Mobj*)
  Doocr.p_slide_move(mo)
end

fun ptr_aim_traverse = PTR_AimTraverse(int : CDoom::Intercept*) : LibC::Int
  Doocr.ptr_aim_traverse(int)
end

fun ptr_shoot_traverse = PTR_ShootTraverse(int : CDoom::Intercept*) : LibC::Int
  Doocr.ptr_shoot_traverse(int)
end

fun p_aim_line_attack = P_AimLineAttack(t1 : CDoom::Mobj*, angle : LibC::UInt, distance : LibC::Int) : LibC::Int
  Doocr.p_aim_line_attack(t1, angle, distance)
end

fun p_line_attack = P_LineAttack(t1 : CDoom::Mobj*, angle : LibC::UInt, distance : LibC::Int, slope : LibC::Int, damage : LibC::Int)
  Doocr.p_line_attack(t1, angle, distance, slope, damage)
end

fun ptr_use_traverse = PTR_UseTraverse(int : CDoom::Intercept*) : LibC::Int
  Doocr.ptr_use_traverse(int)
end

fun p_use_lines = P_UseLines(player : CDoom::Player*)
  Doocr.p_use_lines(player)
end

fun pit_radius_attack = PIT_RadiusAttack(thing : CDoom::Mobj*) : LibC::Int
  Doocr.pit_radius_attack(thing)
end

fun p_radius_attack = P_RadiusAttack(spot : CDoom::Mobj*, source : CDoom::Mobj*, damage : LibC::Int)
  Doocr.p_radius_attack(spot, source, damage)
end

fun pit_change_sector = PIT_ChangeSector(thing : CDoom::Mobj*) : LibC::Int
  Doocr.pit_change_sector(thing)
end

fun p_change_sector = P_ChangeSector(sector : CDoom::Sector*, crunch : LibC::Int) : LibC::Int
  Doocr.p_change_sector(sector, crunch)
end

fun p_aprox_distance = P_AproxDistance(dx : LibC::Int, dy : LibC::Int) : LibC::Int
  Doocr.p_aprox_distance(dx, dy)
end

fun p_point_on_line_side = P_PointOnLineSide(x : LibC::Int, y : LibC::Int, line : CDoom::Line*) : LibC::Int
  Doocr.p_point_on_line_side(x, y, line)
end

fun p_box_on_line_side = P_BoxOnLineSide(tmbox : LibC::Int*, ld : CDoom::Line*) : LibC::Int
  Doocr.p_box_on_line_side(tmbox, ld)
end

fun p_point_on_divline_side = P_PointOnDivlineSide(x : LibC::Int, y : LibC::Int, line : CDoom::Divline*) : LibC::Int
  Doocr.p_point_on_divline_side(x, y, line)
end

fun p_make_divline = P_MakeDivline(li : CDoom::Line*, dl : CDoom::Divline*)
  Doocr.p_make_divline(li, dl)
end

fun p_intercept_vector = P_InterceptVector(v2 : CDoom::Divline*, v1 : CDoom::Divline*) : LibC::Int
  Doocr.p_intercept_vector(v2, v1)
end

fun p_line_opening = P_LineOpening(linedef : CDoom::Line*)
  Doocr.p_line_opening(linedef)
end

fun p_unset_thing_position = P_UnsetThingPosition(thing : CDoom::Mobj*)
  Doocr.p_unset_thing_position(thing)
end

fun p_set_thing_position = P_SetThingPosition(thing : CDoom::Mobj*)
  Doocr.p_set_thing_position(thing)
end

fun p_block_lines_iterator = P_BlockLinesIterator(x : LibC::Int, y : LibC::Int, func : Proc(CDoom::Line*, LibC::Int)) : LibC::Int
  Doocr.p_block_lines_iterator(x, y, func)
end

fun p_block_things_iterator = P_BlockThingsIterator(x : LibC::Int, y : LibC::Int, func : Proc(CDoom::Mobj*, LibC::Int)) : LibC::Int
  Doocr.p_block_things_iterator(x, y, func)
end

fun pit_add_line_intercepts = PIT_AddLineIntercepts(ld : CDoom::Line*) : LibC::Int
  Doocr.pit_add_line_intercepts(ld)
end

fun pit_add_thing_intercepts = PIT_AddThingIntercepts(thing : CDoom::Mobj*) : LibC::Int
  Doocr.pit_add_thing_intercepts(thing)
end

fun p_traverse_intercepts = P_TraverseIntercepts(func : Doocr::Traverser, maxfrac : LibC::Int) : LibC::Int
  Doocr.p_traverse_intercepts(func, maxfrac)
end

fun p_path_traverse = P_PathTraverse(x1 : LibC::Int, y1 : LibC::Int, x2 : LibC::Int, y2 : LibC::Int, flags : LibC::Int, trav : Proc(CDoom::Intercept*, LibC::Int)) : LibC::Int
  Doocr.p_path_traverse(x1, y1, x2, y2, flags, trav)
end

fun p_set_mobj_state = P_SetMobjState(mobj : CDoom::Mobj*, state : Doocr::Statenum) : LibC::Int
  Doocr.p_set_mobj_state(mobj, state)
end

fun p_explode_missile = P_ExplodeMissile(mo : CDoom::Mobj*)
  Doocr.p_explode_missile(mo)
end

fun p_xymovement = P_XYMovement(mo : CDoom::Mobj*)
  Doocr.p_xymovement(mo)
end

fun p_zmovement = P_ZMovement(mo : CDoom::Mobj*)
  Doocr.p_zmovement(mo)
end

fun p_nightmare_respawn = P_NightmareRespawn(mobj : CDoom::Mobj*)
  Doocr.p_nightmare_respawn(mobj)
end

fun p_mobj_thinker = P_MobjThinker(mobj : CDoom::Mobj*)
  Doocr.p_mobj_thinker(mobj)
end

fun p_spawn_mobj = P_SpawnMobj(x : LibC::Int, y : LibC::Int, z : LibC::Int, type : Doocr::Mobjtype) : CDoom::Mobj*
  Doocr.p_spawn_mobj(x, y, z, type)
end

fun p_remove_mobj = P_RemoveMobj(mobj : CDoom::Mobj*)
  Doocr.p_remove_mobj(mobj)
end

fun p_respawn_specials = P_RespawnSpecials
  Doocr.p_respawn_specials
end

fun p_spawn_player = P_SpawnPlayer(mthing : CDoom::Mapthing*)
  Doocr.p_spawn_player(mthing)
end

fun p_spawn_map_thing = P_SpawnMapThing(mthing : CDoom::Mapthing*)
  Doocr.p_spawn_map_thing(mthing)
end

fun p_spawn_puff = P_SpawnPuff(x : LibC::Int, y : LibC::Int, z : LibC::Int)
  Doocr.p_spawn_puff(x, y, z)
end

fun p_spawn_blood = P_SpawnBlood(x : LibC::Int, y : LibC::Int, z : LibC::Int, damage : LibC::Int)
  Doocr.p_spawn_blood(x, y, z, damage)
end

fun p_check_missile_spawn = P_CheckMissileSpawn(th : CDoom::Mobj*)
  Doocr.p_check_missile_spawn(th)
end

fun p_spawn_missile = P_SpawnMissile(source : CDoom::Mobj*, dest : CDoom::Mobj*, type : Doocr::Mobjtype) : CDoom::Mobj*
  Doocr.p_spawn_missile(source, dest, type)
end

fun p_spawn_player_missile = P_SpawnPlayerMissile(source : CDoom::Mobj*, type : Doocr::Mobjtype)
  Doocr.p_spawn_player_missile(source, type)
end

fun t_plat_raise = T_PlatRaise(plat : CDoom::Plat*)
  Doocr.t_plat_raise(plat)
end

fun ev_do_plat = EV_DoPlat(line : CDoom::Line*, type : Doocr::Plattype, amount : LibC::Int) : LibC::Int
  Doocr.ev_do_plat(line, type, amount)
end

fun p_activate_in_stasis = P_ActivateInStasis(tag : LibC::Int)
  Doocr.p_activate_in_stasis(tag)
end

fun ev_stop_plat = EV_StopPlat(line : CDoom::Line*)
  Doocr.ev_stop_plat(line)
end

fun p_add_active_plat = P_AddActivePlat(plat : CDoom::Plat*)
  Doocr.p_add_active_plat(plat)
end

fun p_remove_active_plat = P_RemoveActivePlat(plat : CDoom::Plat*)
  Doocr.p_remove_active_plat(plat)
end

fun p_set_psprite = P_SetPsprite(player : CDoom::Player*, position : LibC::Int, stnum : Doocr::Statenum)
  Doocr.p_set_psprite(player, position, stnum)
end

fun p_bring_up_weapon = P_BringUpWeapon(player : CDoom::Player*)
  Doocr.p_bring_up_weapon(player)
end

fun p_check_ammo = P_CheckAmmo(player : CDoom::Player*) : LibC::Int
  Doocr.p_check_ammo(player)
end

fun p_fire_weapon = P_FireWeapon(player : CDoom::Player*)
  Doocr.p_fire_weapon(player)
end

fun p_drop_weapon = P_DropWeapon(player : CDoom::Player*)
  Doocr.p_drop_weapon(player)
end

fun a_weapon_ready = A_WeaponReady(player : CDoom::Player*, psp : CDoom::Pspdef*)
  Doocr.a_weapon_ready(player, psp)
end

fun a_refire = A_ReFire(player : CDoom::Player*, psp : CDoom::Pspdef*)
  Doocr.a_refire(player, psp)
end

fun a_check_reload = A_CheckReload(player : CDoom::Player*, psp : CDoom::Pspdef*)
  Doocr.a_check_reload(player, psp)
end

fun a_lower = A_Lower(player : CDoom::Player*, psp : CDoom::Pspdef*)
  Doocr.a_lower(player, psp)
end

fun a_raise = A_Raise(player : CDoom::Player*, psp : CDoom::Pspdef*)
  Doocr.a_raise(player, psp)
end

fun a_gun_flash = A_GunFlash(player : CDoom::Player*, psp : CDoom::Pspdef*)
  Doocr.a_gun_flash(player, psp)
end

fun a_punch = A_Punch(player : CDoom::Player*, psp : CDoom::Pspdef*)
  Doocr.a_punch(player, psp)
end

fun a_saw = A_Saw(player : CDoom::Player*, psp : CDoom::Pspdef*)
  Doocr.a_saw(player, psp)
end

fun a_fire_missile = A_FireMissile(player : CDoom::Player*, psp : CDoom::Pspdef*)
  Doocr.a_fire_missile(player, psp)
end

fun a_fire_bfg = A_FireBFG(player : CDoom::Player*, psp : CDoom::Pspdef*)
  Doocr.a_fire_bfg(player, psp)
end

fun a_fire_plasma = A_FirePlasma(player : CDoom::Player*, psp : CDoom::Pspdef*)
  Doocr.a_fire_plasma(player, psp)
end

fun p_bullet_slope = P_BulletSlope(mo : CDoom::Mobj*)
  Doocr.p_bullet_slope(mo)
end

fun p_gunshot = P_GunShot(mo : CDoom::Mobj*, accurate : LibC::Int)
  Doocr.p_gunshot(mo, accurate)
end

fun a_fire_pistol = A_FirePistol(player : CDoom::Player*, psp : CDoom::Pspdef*)
  Doocr.a_fire_pistol(player, psp)
end

fun a_fire_shotgun = A_FireShotgun(player : CDoom::Player*, psp : CDoom::Pspdef*)
  Doocr.a_fire_shotgun(player, psp)
end

fun a_fire_shotgun2 = A_FireShotgun2(player : CDoom::Player*, psp : CDoom::Pspdef*)
  Doocr.a_fire_shotgun2(player, psp)
end

fun a_fire_cgun = A_FireCGun(player : CDoom::Player*, psp : CDoom::Pspdef*)
  Doocr.a_fire_cgun(player, psp)
end

fun a_light0 = A_Light0(player : CDoom::Player*, psp : CDoom::Pspdef*)
  Doocr.a_light0(player, psp)
end

fun a_light1 = A_Light1(player : CDoom::Player*, psp : CDoom::Pspdef*)
  Doocr.a_light1(player, psp)
end

fun a_light2 = A_Light2(player : CDoom::Player*, psp : CDoom::Pspdef*)
  Doocr.a_light2(player, psp)
end

fun a_bfg_spray = A_BFGSpray(mo : CDoom::Mobj*)
  Doocr.a_bfg_spray(mo)
end

fun a_bfg_sound = A_BFGsound(player : CDoom::Player*, psp : CDoom::Pspdef*)
  Doocr.a_bfg_sound(player, psp)
end

fun p_setup_psprites = P_SetupPsprites(curplayer : CDoom::Player*)
  Doocr.p_setup_psprites(curplayer)
end

fun p_move_psprites = P_MovePsprites(curplayer : CDoom::Player*)
  Doocr.p_move_psprites(curplayer)
end

fun p_load_vertexes = P_LoadVertexes(lump : LibC::Int)
  Doocr.p_load_vertexes(lump)
end

fun p_load_segs = P_LoadSegs(lump : LibC::Int)
  Doocr.p_load_segs(lump)
end

fun p_load_subsectors = P_LoadSubsectors(lump : LibC::Int)
  Doocr.p_load_subsectors(lump)
end

fun p_load_sectors = P_LoadSectors(lump : LibC::Int)
  Doocr.p_load_sectors(lump)
end

fun p_load_nodes = P_LoadNodes(lump : LibC::Int)
  Doocr.p_load_nodes(lump)
end

fun p_load_things = P_LoadThings(lump : LibC::Int)
  Doocr.p_load_things(lump)
end

fun p_load_linedefs = P_LoadLineDefs(lump : LibC::Int)
  Doocr.p_load_linedefs(lump)
end

fun p_load_sidedefs = P_LoadSideDefs(lump : LibC::Int)
  Doocr.p_load_sidedefs(lump)
end

fun p_group_lines = P_GroupLines
  Doocr.p_group_lines
end

fun p_setup_level = P_SetupLevel(episode : LibC::Int, map : LibC::Int, playermask : LibC::Int, skill : Doocr::Skill)
  Doocr.p_setup_level(episode, map, playermask, skill)
end

fun p_init = P_Init
  Doocr.p_init
end

fun p_divline_side = P_DivlineSide(x : LibC::Int, y : LibC::Int, node : CDoom::Divline*) : LibC::Int
  Doocr.p_divline_side(x, y, node)
end

fun p_intercept_vector2 = P_InterceptVector2(v2 : CDoom::Divline*, v1 : CDoom::Divline*) : LibC::Int
  Doocr.p_intercept_vector2(v2, v1)
end

fun p_cross_subsector = P_CrossSubsector(num : LibC::Int) : LibC::Int
  Doocr.p_cross_subsector(num)
end

fun p_cross_bsp_node = P_CrossBSPNode(bspnum : LibC::Int) : LibC::Int
  Doocr.p_cross_bsp_node(bspnum)
end

fun p_check_sight = P_CheckSight(t1 : CDoom::Mobj*, t2 : CDoom::Mobj*) : LibC::Int
  Doocr.p_check_sight(t1, t2)
end

fun p_init_pic_anims = P_InitPicAnims
  Doocr.p_init_pic_anims
end

fun get_side = getSide(current_sector : LibC::Int, line : LibC::Int, side : LibC::Int) : CDoom::Side*
  Doocr.get_side(current_sector, line, side)
end

fun get_sector = getSector(current_sector : LibC::Int, line : LibC::Int, side : LibC::Int) : CDoom::Sector*
  Doocr.get_sector(current_sector, line, side)
end

fun two_sided = twoSided(sector : LibC::Int, line : LibC::Int) : LibC::Int
  Doocr.two_sided(sector, line)
end

fun get_next_sector = getNextSector(line : CDoom::Line*, sec : CDoom::Sector*) : CDoom::Sector*
  Doocr.get_next_sector(line, sec)
end

fun p_find_lowest_floor_surrounding = P_FindLowestFloorSurrounding(sec : CDoom::Sector*) : LibC::Int
  Doocr.p_find_lowest_floor_surrounding(sec)
end

fun p_find_highest_floor_surrounding = P_FindHighestFloorSurrounding(sec : CDoom::Sector*) : LibC::Int
  Doocr.p_find_highest_floor_surrounding(sec)
end

fun p_find_next_highest_floor = P_FindNextHighestFloor(sec : CDoom::Sector*, currentheight : LibC::Int) : LibC::Int
  Doocr.p_find_next_highest_floor(sec, currentheight)
end

fun p_find_lowest_ceiling_surrounding = P_FindLowestCeilingSurrounding(sec : CDoom::Sector*) : LibC::Int
  Doocr.p_find_lowest_ceiling_surrounding(sec)
end

fun p_find_highest_ceiling_surrounding = P_FindHighestCeilingSurrounding(sec : CDoom::Sector*) : LibC::Int
  Doocr.p_find_highest_ceiling_surrounding(sec)
end

fun p_find_sector_from_line_tag = P_FindSectorFromLineTag(line : CDoom::Line*, start : LibC::Int) : LibC::Int
  Doocr.p_find_sector_from_line_tag(line, start)
end

fun p_find_min_surrounding_light = P_FindMinSurroundingLight(sector : CDoom::Sector*, max : LibC::Int) : LibC::Int
  Doocr.p_find_min_surrounding_light(sector, max)
end

fun p_cross_special_line = P_CrossSpecialLine(linenum : LibC::Int, side : LibC::Int, thing : CDoom::Mobj*)
  Doocr.p_cross_special_line(linenum, side, thing)
end

fun p_shoot_special_line = P_ShootSpecialLine(thing : CDoom::Mobj*, line : CDoom::Line*)
  Doocr.p_shoot_special_line(thing, line)
end

fun p_player_in_special_sector = P_PlayerInSpecialSector(player : CDoom::Player*)
  Doocr.p_player_in_special_sector(player)
end

fun p_update_specials = P_UpdateSpecials
  Doocr.p_update_specials
end

fun ev_do_donut = EV_DoDonut(line : CDoom::Line*) : LibC::Int
  Doocr.ev_do_donut(line)
end

fun p_spawn_specials = P_SpawnSpecials
  Doocr.p_spawn_specials
end

fun p_init_switch_list = P_InitSwitchList
  Doocr.p_init_switch_list
end

fun p_change_switch_texture = P_ChangeSwitchTexture(line : CDoom::Line*, use_again : LibC::Int)
  Doocr.p_change_switch_texture(line, use_again)
end

fun p_use_special_line = P_UseSpecialLine(thing : CDoom::Mobj*, line : CDoom::Line*, side : LibC::Int) : LibC::Int
  Doocr.p_use_special_line(thing, line, side)
end

fun ev_teleport = EV_Teleport(line : CDoom::Line*, side : LibC::Int, thing : CDoom::Mobj*) : LibC::Int
  Doocr.ev_teleport(line, side, thing)
end

fun p_init_thinkers = P_InitThinkers
  Doocr.p_init_thinkers
end

fun p_add_thinker = P_AddThinker(thinker : CDoom::Thinker*)
  Doocr.p_add_thinker(thinker)
end

fun p_remove_thinker = P_RemoveThinker(thinker : CDoom::Thinker*)
  Doocr.p_remove_thinker(thinker)
end

fun p_run_thinkers = P_RunThinkers
  Doocr.p_run_thinkers
end

fun p_ticker = P_Ticker
  Doocr.p_ticker
end

fun p_thrust = P_Thrust(player : CDoom::Player*, angle : LibC::UInt, move : LibC::Int)
  Doocr.p_thrust(player, angle, move)
end

fun p_calc_height = P_CalcHeight(player : CDoom::Player*)
  Doocr.p_calc_height(player)
end

fun p_move_player = P_MovePlayer(player : CDoom::Player*)
  Doocr.p_move_player(player)
end

fun p_death_think = P_DeathThink(player : CDoom::Player*)
  Doocr.p_death_think(player)
end

fun p_player_think = P_PlayerThink(player : CDoom::Player*)
  Doocr.p_player_think(player)
end

fun r_clear_draw_segs = R_ClearDrawSegs
  Doocr.r_clear_draw_segs
end

fun r_clip_solid_wall_segment = R_ClipSolidWallSegment(first : LibC::Int, last : LibC::Int)
  Doocr.r_clip_solid_wall_segment(first, last)
end

fun r_clip_pass_wall_segment = R_ClipPassWallSegment(first : LibC::Int, last : LibC::Int)
  Doocr.r_clip_pass_wall_segment(first, last)
end

fun r_clear_clip_segs = R_ClearClipSegs
  Doocr.r_clear_clip_segs
end

fun r_addline = R_AddLine(line : CDoom::Seg*)
  Doocr.r_addline(line)
end

fun r_check_bbox = R_CheckBBox(bspcoord : LibC::Int*) : LibC::Int
  Doocr.r_check_bbox(bspcoord)
end

fun r_subsector = R_Subsector(num : LibC::Int)
  Doocr.r_subsector(num)
end

fun r_render_bsp_node = R_RenderBSPNode(bspnum : LibC::Int)
  Doocr.r_render_bsp_node(bspnum)
end

fun r_draw_column_in_cache = R_DrawColumnInCache(patch : CDoom::Post*, cache : UInt8*, originy : LibC::Int, cacheheight : LibC::Int)
  Doocr.r_draw_column_in_cache(patch, cache, originy, cacheheight)
end

fun r_generate_composite = R_GenerateComposite(texnum : LibC::Int)
  Doocr.r_generate_composite(texnum)
end

fun r_generate_lookup = R_GenerateLookup(texnum : LibC::Int)
  Doocr.r_generate_lookup(texnum)
end

fun r_get_column = R_GetColumn(tex : LibC::Int, col : LibC::Int) : UInt8*
  Doocr.r_get_column(tex, col)
end

fun r_init_textures = R_InitTextures
  Doocr.r_init_textures
end

fun r_init_flats = R_InitFlats
  Doocr.r_init_flats
end

fun r_init_sprite_lumps = R_InitSpriteLumps
  Doocr.r_init_sprite_lumps
end

fun r_init_colormaps = R_InitColormaps
  Doocr.r_init_colormaps
end

fun r_init_data = R_InitData
  Doocr.r_init_data
end

fun r_flat_num_for_name = R_FlatNumForName(name : LibC::Char*) : LibC::Int
  Doocr.r_flat_num_for_name(name)
end

fun r_check_texture_num_for_name = R_CheckTextureNumForName(name : LibC::Char*) : LibC::Int
  Doocr.r_check_texture_num_for_name(name)
end

fun r_texture_num_for_name = R_TextureNumForName(name : LibC::Char*) : LibC::Int
  Doocr.r_texture_num_for_name(name)
end

fun r_precache_level = R_PrecacheLevel
  Doocr.r_precache_level
end

fun r_draw_column = R_DrawColumn
  Doocr.r_draw_column
end

fun r_draw_fuzz_column = R_DrawFuzzColumn
  Doocr.r_draw_fuzz_column
end

fun r_draw_translated_column = R_DrawTranslatedColumn
  Doocr.r_draw_translated_column
end

fun r_init_translation_tables = R_InitTranslationTables
  Doocr.r_init_translation_tables
end

fun r_draw_span = R_DrawSpan
  Doocr.r_draw_span
end

fun r_init_buffer = R_InitBuffer(width : LibC::Int, height : LibC::Int)
  Doocr.r_init_buffer(width, height)
end

fun r_fill_back_screen = R_FillBackScreen
  Doocr.r_fill_back_screen
end

fun r_video_erase = R_VideoErase(ofs : LibC::UInt, count : LibC::Int)
  Doocr.r_video_erase(ofs, count)
end

fun r_draw_view_border = R_DrawViewBorder
  Doocr.r_draw_view_border
end

fun r_add_point_to_box = R_AddPointToBox(x : LibC::Int, y : LibC::Int, box : LibC::Int*)
  Doocr.r_add_point_to_box(x, y, box)
end

fun r_point_on_side = R_PointOnSide(x : LibC::Int, y : LibC::Int, node : CDoom::Node*) : LibC::Int
  Doocr.r_point_on_side(x, y, node)
end

fun r_point_on_seg_side = R_PointOnSegSide(x : LibC::Int, y : LibC::Int, line : CDoom::Seg*) : LibC::Int
  Doocr.r_point_on_seg_side(x, y, line)
end

fun r_point_to_angle = R_PointToAngle(x : LibC::Int, y : LibC::Int) : LibC::UInt
  Doocr.r_point_to_angle(x, y)
end

fun r_point_to_angle2 = R_PointToAngle2(x1 : LibC::Int, y1 : LibC::Int, x2 : LibC::Int, y2 : LibC::Int) : LibC::UInt
  Doocr.r_point_to_angle2(x1, y1, x2, y2)
end

fun r_point_to_dist = R_PointToDist(x : LibC::Int, y : LibC::Int) : LibC::Int
  Doocr.r_point_to_dist(x, y)
end

fun r_scale_from_global_angle = R_ScaleFromGlobalAngle(visangle : LibC::UInt) : LibC::Int
  Doocr.r_scale_from_global_angle(visangle)
end

fun r_init_tables = R_InitTables
  Doocr.r_init_tables
end

fun r_init_texture_mapping = R_InitTextureMapping
  Doocr.r_init_texture_mapping
end

fun r_init_light_tables = R_InitLightTables
  Doocr.r_init_light_tables
end

fun r_set_view_size = R_SetViewSize(blocks : LibC::Int, detail : LibC::Int)
  Doocr.r_set_view_size(blocks, detail)
end

fun r_execute_set_view_size = R_ExecuteSetViewSize
  Doocr.r_execute_set_view_size
end

fun r_init = R_Init
  Doocr.r_init
end

fun r_point_in_subsector = R_PointInSubsector(x : LibC::Int, y : LibC::Int) : CDoom::Subsector*
  Doocr.r_point_in_subsector(x, y)
end

fun r_setup_frame = R_SetupFrame(player : CDoom::Player*)
  Doocr.r_setup_frame(player)
end

fun r_render_player_view = R_RenderPlayerView(player : CDoom::Player*)
  Doocr.r_render_player_view(player)
end

fun r_map_plane = R_MapPlane(y : LibC::Int, x1 : LibC::Int, x2 : LibC::Int)
  Doocr.r_map_plane(y, x1, x2)
end

fun r_clear_planes = R_ClearPlanes
  Doocr.r_clear_planes
end

fun r_make_spans = R_MakeSpans(x : LibC::Int, t1 : LibC::Int, b1 : LibC::Int, t2 : LibC::Int, b2 : LibC::Int)
  Doocr.r_make_spans(x, t1, b1, t2, b2)
end

fun r_draw_planes = R_DrawPlanes
  Doocr.r_draw_planes
end

fun r_render_masked_seg_range = R_RenderMaskedSegRange(ds : CDoom::Drawseg*, x1 : LibC::Int, x2 : LibC::Int)
  Doocr.r_render_masked_seg_range(ds, x1, x2)
end

fun r_render_seg_loop = R_RenderSegLoop
  Doocr.r_render_seg_loop
end

fun r_store_wall_range = R_StoreWallRange(start : LibC::Int, stop : LibC::Int)
  Doocr.r_store_wall_range(start, stop)
end

fun r_init_sky_map = R_InitSkyMap
  Doocr.r_init_sky_map
end

fun r_install_sprite_lump = R_InstallSpriteLump(lump : LibC::Int, frame : LibC::UInt, rotation : LibC::UInt, flipped : LibC::Int)
  Doocr.r_install_sprite_lump(lump, frame, rotation, flipped)
end

fun r_clear_sprites = R_ClearSprites
  Doocr.r_clear_sprites
end

fun r_new_vis_sprite = R_NewVisSprite : CDoom::Vissprite*
  Doocr.r_new_vis_sprite
end

fun r_draw_masked_column = R_DrawMaskedColumn(column : CDoom::Post*)
  Doocr.r_draw_masked_column(column)
end

fun r_draw_vis_sprite = R_DrawVisSprite(vis : CDoom::Vissprite*, x1 : LibC::Int, x2 : LibC::Int)
  Doocr.r_draw_vis_sprite(vis, x1, x2)
end

fun r_project_sprite = R_ProjectSprite(thing : CDoom::Mobj*)
  Doocr.r_project_sprite(thing)
end

fun r_add_sprites = R_AddSprites(sec : CDoom::Sector*)
  Doocr.r_add_sprites(sec)
end

fun r_draw_psprite = R_DrawPSprite(psp : CDoom::Pspdef*)
  Doocr.r_draw_psprite(psp)
end

fun r_draw_player_sprites = R_DrawPlayerSprites
  Doocr.r_draw_player_sprites
end

fun r_sort_vis_sprites = R_SortVisSprites
  Doocr.r_sort_vis_sprites
end

fun r_draw_sprite = R_DrawSprite(spr : CDoom::Vissprite*)
  Doocr.r_draw_sprite(spr)
end

fun r_draw_masked = R_DrawMasked
  Doocr.r_draw_masked
end

fun s_init = S_Init(sfx_volume : LibC::Int, music_volume : LibC::Int)
  Doocr.s_init(sfx_volume, music_volume)
end

fun s_start = S_Start
  Doocr.s_start
end

fun s_start_sound_at_volume = S_StartSoundAtVolume(origin_p : Void*, sfx_id : LibC::Int, volume : LibC::Int)
  Doocr.s_start_sound_at_volume(origin_p, sfx_id, volume)
end

fun s_start_sound = S_StartSound(origin : Void*, sfx_id : LibC::Int)
  Doocr.s_start_sound(origin, sfx_id)
end

fun s_stop_sound = S_StopSound(origin : Void*)
  Doocr.s_stop_sound(origin)
end

fun s_pause_sound = S_PauseSound
  Doocr.s_pause_sound
end

fun s_resume_sound = S_ResumeSound
  Doocr.s_resume_sound
end

fun s_update_sounds = S_UpdateSounds(listener_p : Void*)
  Doocr.s_update_sounds(listener_p)
end

fun s_set_music_volume = S_SetMusicVolume(volume : LibC::Int)
  Doocr.s_set_music_volume(volume)
end

fun s_start_music = S_StartMusic(music_id : LibC::Int)
  Doocr.s_start_music(music_id)
end

fun s_change_music = S_ChangeMusic(music_id : LibC::Int, looping : LibC::Int)
  Doocr.s_change_music(music_id, looping)
end

fun s_stop_music = S_StopMusic
  Doocr.s_stop_music
end

fun s_stop_channel = S_StopChannel(cnum : LibC::Int)
  Doocr.s_stop_channel(cnum)
end

fun s_adjust_sound_params = S_AdjustSoundParams(listener : CDoom::Mobj*, source : CDoom::Mobj*, vol : LibC::Int*, sep : LibC::Int*, pitch : LibC::Int*) : LibC::Int
  Doocr.s_adjust_sound_params(listener, source, vol, sep, pitch)
end

fun s_get_channel = S_getChannel(origin : Void*, sfxinfo : CDoom::Sfxinfo*) : LibC::Int
  Doocr.s_get_channel(origin, sfxinfo)
end

fun stlib_init = STlib_init
  Doocr.stlib_init
end

fun stlib_init_num = STlib_initNum(n : CDoom::ST_Number*,
                                   x : LibC::Int,
                                   y : LibC::Int,
                                   pl : CDoom::Patch**,
                                   num : LibC::Int*,
                                   on : LibC::Int*,
                                   width : LibC::Int)
  Doocr.stlib_init_num(n,
    x,
    y,
    pl,
    num,
    on,
    width)
end

fun stlib_draw_num = STlib_drawNum(n : CDoom::ST_Number*, refresh : LibC::Int)
  Doocr.stlib_draw_num(n, refresh)
end

fun stlib_update_num = STlib_updateNum(n : CDoom::ST_Number*, refresh : LibC::Int)
  Doocr.stlib_update_num(n, refresh)
end

fun stlib_init_percent = STlib_initPercent(p : CDoom::ST_Percent*,
                                           x : LibC::Int,
                                           y : LibC::Int,
                                           pl : CDoom::Patch**,
                                           num : LibC::Int*,
                                           on : LibC::Int*,
                                           percent : CDoom::Patch*)
  Doocr.stlib_init_percent(p, x, y, pl, num, on, percent)
end

fun stlib_update_percent = STlib_updatePercent(per : CDoom::ST_Percent*, refresh : LibC::Int)
  Doocr.stlib_update_percent(per, refresh)
end

fun stlib_init_mult_icon = STlib_initMultIcon(mi : CDoom::ST_Multicon*,
                                              x : LibC::Int,
                                              y : LibC::Int,
                                              il : CDoom::Patch**,
                                              inum : LibC::Int*,
                                              on : LibC::Int*)
  Doocr.stlib_init_mult_icon(mi, x, y, il, inum, on)
end

fun stlib_update_mult_icon = STlib_updateMultIcon(mi : CDoom::ST_Multicon*, refresh : LibC::Int)
  Doocr.stlib_update_mult_icon(mi, refresh)
end

fun stlib_init_bin_icon = STlib_initBinIcon(b : CDoom::ST_Binicon*,
                                            x : LibC::Int,
                                            y : LibC::Int,
                                            i : CDoom::Patch*,
                                            val : LibC::Int*,
                                            on : LibC::Int*)
  Doocr.stlib_init_bin_icon(b, x, y, i, val, on)
end

fun stlib_update_bin_icon = STlib_updateBinIcon(bi : CDoom::ST_Binicon*, refresh : LibC::Int)
  Doocr.stlib_update_bin_icon(bi, refresh)
end

fun st_refresh_background = ST_refreshBackground
  Doocr.st_refresh_background
end

fun st_responder = ST_Responder(ev : CDoom::Event*) : LibC::Int
  Doocr.st_responder(ev)
end

fun st_calc_pain_offset = ST_calcPainOffset : LibC::Int
  Doocr.st_calc_pain_offset
end

fun st_update_face_widget = ST_updateFaceWidget
  Doocr.st_update_face_widget
end

fun st_update_widgets = ST_updateWidgets
  Doocr.st_update_widgets
end

fun st_ticker = ST_Ticker
  Doocr.st_ticker
end

fun st_do_palette_stuff = ST_doPaletteStuff
  Doocr.st_do_palette_stuff
end

fun st_draw_widgets = ST_drawWidgets(refresh : LibC::Int)
  Doocr.st_draw_widgets(refresh)
end

fun st_do_refresh = ST_doRefresh
  Doocr.st_do_refresh
end

fun st_diff_draw = ST_diffDraw
  Doocr.st_diff_draw
end

fun st_drawer = ST_Drawer(fullscreen : LibC::Int, refresh : LibC::Int)
  Doocr.st_drawer(fullscreen, refresh)
end

fun st_load_graphics = ST_loadGraphics
  Doocr.st_load_graphics
end

fun st_load_data = ST_loadData
  Doocr.st_load_data
end

fun st_unload_graphics = ST_unloadGraphics
  Doocr.st_unload_graphics
end

fun st_unload_data = ST_unloadData
  Doocr.st_unload_data
end

fun st_init_data = ST_initData
  Doocr.st_init_data
end

fun st_create_widgets = ST_createWidgets
  Doocr.st_create_widgets
end

fun st_start = ST_Start
  Doocr.st_start
end

fun st_stop = ST_Stop
  Doocr.st_stop
end

fun st_init = ST_Init
  Doocr.st_init
end

fun slope_div = SlopeDiv(num : LibC::UInt, den : LibC::UInt) : LibC::Int
  Doocr.slope_div(num, den)
end

fun v_mark_rect = V_MarkRect(x : LibC::Int,
                             y : LibC::Int,
                             width : LibC::Int,
                             height : LibC::Int)
  Doocr.v_mark_rect(x, y, width, height)
end

fun v_copy_rect = V_CopyRect(srcx : LibC::Int,
                             srcy : LibC::Int,
                             srcscrn : LibC::Int,
                             width : LibC::Int,
                             height : LibC::Int,
                             destx : LibC::Int,
                             desty : LibC::Int,
                             destscrn : LibC::Int)
  Doocr.v_copy_rect(srcx, srcy, srcscrn, width, height, destx, desty, destscrn)
end

fun v_draw_patch = V_DrawPatch(x : LibC::Int,
                               y : LibC::Int,
                               scrn : LibC::Int,
                               patch : CDoom::Patch*)
  Doocr.v_draw_patch(x, y, scrn, patch)
end

fun v_draw_patch_flipped = V_DrawPatchFlipped(x : LibC::Int, y : LibC::Int, scrn : LibC::Int, patch : CDoom::Patch*)
  Doocr.v_draw_patch_flipped(x, y, scrn, patch)
end

fun v_draw_patch_rect_direct = V_DrawPatchRectDirect(x : LibC::Int, y : LibC::Int, scrn : LibC::Int, patch : CDoom::Patch*, src_x : LibC::Int, src_w : LibC::Int)
  Doocr.v_draw_patch_rect_direct(x, y, scrn, patch, src_x, src_w)
end

fun v_draw_patch_direct = V_DrawPatchDirect(x : LibC::Int,
                                            y : LibC::Int,
                                            scrn : LibC::Int,
                                            patch : CDoom::Patch*)
  Doocr.v_draw_patch_direct(x, y, scrn, patch)
end

fun v_draw_block = V_DrawBlock(x : LibC::Int,
                               y : LibC::Int,
                               scrn : LibC::Int,
                               width : LibC::Int,
                               height : LibC::Int,
                               src : UInt8*)
  Doocr.v_draw_block(x, y, scrn, width, height, src)
end

fun v_get_block = V_GetBlock(x : LibC::Int,
                             y : LibC::Int,
                             scrn : LibC::Int,
                             width : LibC::Int,
                             height : LibC::Int,
                             dest : UInt8*)
  Doocr.v_get_block(x, y, scrn, width, height, dest)
end

fun v_init = V_Init
  Doocr.v_init
end

fun doom_strupr(s : LibC::Char*)
  Doocr.doom_strupr(s)
end

fun extract_file_base = ExtractFileBase(path : LibC::Char*, dest : LibC::Char*)
  Doocr.extract_file_base(path, dest)
end

fun w_add_file = W_AddFile(filename : LibC::Char*)
  Doocr.w_add_file(filename)
end

fun w_reload = W_Reload
  Doocr.w_reload
end

fun w_init_multiple_files = W_InitMultipleFiles(filenames : LibC::Char**)
  Doocr.w_init_multiple_files(filenames)
end

fun w_init_file = W_InitFile(filename : LibC::Char*)
  Doocr.w_init_file(filename)
end

fun w_check_num_for_name = W_CheckNumForName(name : LibC::Char*) : LibC::Int
  Doocr.w_check_num_for_name(name)
end

fun w_get_num_for_name = W_GetNumForName(name : LibC::Char*) : LibC::Int
  Doocr.w_get_num_for_name(name)
end

fun w_lump_length = W_LumpLength(lump : LibC::Int) : LibC::Int
  Doocr.w_lump_length(lump)
end

fun w_read_lump = W_ReadLump(lump : LibC::Int, dest : Void*)
  Doocr.w_read_lump(lump, dest)
end

fun w_cache_lump_num = W_CacheLumpNum(lump : LibC::Int, tag : LibC::Int) : Void*
  Doocr.w_cache_lump_num(lump, tag)
end

fun w_cache_lump_name = W_CacheLumpName(name : LibC::Char*, tag : LibC::Int) : Void*
  Doocr.w_cache_lump_name(name, tag)
end

fun wi_slam_background = WI_slamBackground
  Doocr.wi_slam_background
end

fun wi_draw_lf = WI_drawLF
  Doocr.wi_draw_lf
end

fun wi_draw_el = WI_drawEL
  Doocr.wi_draw_el
end

fun wi_draw_on_lnode = WI_drawOnLnode(n : LibC::Int, c : CDoom::Patch**)
  Doocr.wi_draw_on_lnode(n, c)
end

fun wi_init_animated_back = WI_initAnimatedBack
  Doocr.wi_init_animated_back
end

fun wi_update_animated_back = WI_updateAnimatedBack
  Doocr.wi_update_animated_back
end

fun wi_draw_animated_back = WI_drawAnimatedBack
  Doocr.wi_draw_animated_back
end

fun wi_draw_num = WI_drawNum(x : LibC::Int, y : LibC::Int, n : LibC::Int, digits : LibC::Int) : LibC::Int
  Doocr.wi_draw_num(x, y, n, digits)
end

fun wi_draw_percent = WI_drawPercent(x : LibC::Int, y : LibC::Int, p : LibC::Int)
  Doocr.wi_draw_percent(x, y, p)
end

fun wi_draw_time = WI_drawTime(x : LibC::Int, y : LibC::Int, t : LibC::Int)
  Doocr.wi_draw_time(x, y, t)
end

fun wi_end = WI_End
  Doocr.wi_end
end

fun wi_init_no_state = WI_initNoState
  Doocr.wi_init_no_state
end

fun wi_update_no_state = WI_updateNoState
  Doocr.wi_update_no_state
end

fun wi_init_show_next_loc = WI_initShowNextLoc
  Doocr.wi_init_show_next_loc
end

fun wi_update_show_next_loc = WI_updateShowNextLoc
  Doocr.wi_update_show_next_loc
end

fun wi_draw_show_next_loc = WI_drawShowNextLoc
  Doocr.wi_draw_show_next_loc
end

fun wi_draw_no_state = WI_drawNoState
  Doocr.wi_draw_no_state
end

fun wi_frag_sum = WI_fragSum(playernum : LibC::Int) : LibC::Int
  Doocr.wi_frag_sum(playernum)
end

fun wi_init_deathmatch_stats = WI_initDeathmatchStats
  Doocr.wi_init_deathmatch_stats
end

fun wi_update_deathmatch_stats = WI_updateDeathmatchStats
  Doocr.wi_update_deathmatch_stats
end

fun wi_draw_deathmatch_stats = WI_drawDeathmatchStats
  Doocr.wi_draw_deathmatch_stats
end

fun wi_init_netgame_stats = WI_initNetgameStats
  Doocr.wi_init_netgame_stats
end

fun wi_update_netgame_stats = WI_updateNetgameStats
  Doocr.wi_update_netgame_stats
end

fun wi_draw_netgame_stats = WI_drawNetgameStats
  Doocr.wi_draw_netgame_stats
end

fun wi_init_stats = WI_initStats
  Doocr.wi_init_stats
end

fun wi_update_stats = WI_updateStats
  Doocr.wi_update_stats
end

fun wi_draw_stats = WI_drawStats
  Doocr.wi_draw_stats
end

fun wi_check_for_accelerate = WI_checkForAccelerate
  Doocr.wi_check_for_accelerate
end

fun wi_ticker = WI_Ticker
  Doocr.wi_ticker
end

fun wi_load_data = WI_loadData
  Doocr.wi_load_data
end

fun wi_unload_data = WI_unloadData
  Doocr.wi_unload_data
end

fun wi_drawer = WI_Drawer
  Doocr.wi_drawer
end

fun z_init = Z_Init
  Doocr.z_init
end

fun z_free = Z_Free(ptr : Void*)
  Doocr.z_free(ptr)
end

fun z_malloc = Z_Malloc(size : LibC::Int, tag : LibC::Int, ptr : Void*) : Void*
  Doocr.z_malloc(size, tag, ptr)
end

fun z_free_tags = Z_FreeTags(lowtag : LibC::Int, hightag : LibC::Int)
  Doocr.z_free_tags(lowtag, hightag)
end

fun z_check_heap = Z_CheckHeap
  Doocr.z_check_heap
end

fun z_change_tag2 = Z_ChangeTag2(ptr : Void*, tag : LibC::Int)
  Doocr.z_change_tag2(ptr, tag)
end
