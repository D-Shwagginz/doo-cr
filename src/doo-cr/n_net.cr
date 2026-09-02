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
# ==> Networking

module Doocr
  def self.net_buffer_size : Int32
    return offsetof(CDoom::Doomdata, @cmds) + sizeof(CDoom::Ticcmd) * CDoom.netbuffer.value.numtics
  end

  #
  # Checksum
  #
  def self.net_buffer_checksum : UInt32
    return 0_u32
  end

  def self.expand_tics(low : Int32) : Int32
    delta = low - (CDoom.maketic & 0xff)

    if delta >= -64 && delta <= 64
      return (CDoom.maketic & ~0xff) + low
    end
    if delta > 64
      return (CDoom.maketic & ~0xff) - 256 + low
    end
    if delta < -64
      return (CDoom.maketic & ~0xff) + 256 + low
    end

    CDoom.i_error("Error: expand_tics: strange value #{low} at maketic #{CDoom.maketic}")
    return 0
  end

  def self.h_send_packet(node : Int32, flags : Int32)
    CDoom.netbuffer.value.checksum = CDoom.net_buffer_checksum | flags.to_u32!

    if node == 0
      CDoom.netbuffer.copy_to(pointerof(CDoom.reboundstore), 1)
      CDoom.reboundpacket = 1
      return
    end

    return if CDoom.demoplayback != 0

    CDoom.i_error("Error: Tried to transmit to another node") if CDoom.netgame == 0

    CDoom.doomcom.value.command = CDoom::Command::SEND
    CDoom.doomcom.value.remotenode = node
    CDoom.doomcom.value.datalength = CDoom.net_buffer_size

    if !CDoom.debugfile.null?
      realretrans = -1
      if CDoom.netbuffer.value.checksum & NCMD_RETRANSMIT != 0
        realretrans = CDoom.expand_tics(CDoom.netbuffer.value.retransmitfrom)
      end

      CDoom.doom_fprint(CDoom.debugfile, "send (")
      CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(CDoom.expand_tics(CDoom.netbuffer.value.starttic), 10))
      CDoom.doom_fprint(CDoom.debugfile, " + ")
      CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(CDoom.netbuffer.value.numtics, 10))
      CDoom.doom_fprint(CDoom.debugfile, ", R ")
      CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(realretrans, 10))
      CDoom.doom_fprint(CDoom.debugfile, ") [")
      CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(CDoom.doomcom.value.datalength, 10))
      CDoom.doom_fprint(CDoom.debugfile, "] ")

      CDoom.doomcom.value.datalength.times do |i|
        CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(CDoom.netbuffer.as(UInt8*)[i], 10))
        CDoom.doom_fprint(CDoom.debugfile, " ")
      end

      CDoom.doom_fprint(CDoom.debugfile, "\n")
    end

    CDoom.i_net_cmd
  end

  #
  # h_get_packet
  # Returns false if no packet is waiting
  #
  def self.h_get_packet : CDoom::DoomBool
    if CDoom.reboundpacket != 0
      CDoom.netbuffer.copy_from(pointerof(CDoom.reboundstore), 1)
      CDoom.doomcom.value.remotenode = 0
      CDoom.reboundpacket = 0
      return 1
    end

    return 0 if CDoom.netgame == 0

    return 0 if CDoom.demoplayback != 0

    CDoom.doomcom.value.command = CDoom::Command::GET
    CDoom.i_net_cmd

    return 0 if CDoom.doomcom.value.remotenode == -1
    if CDoom.doomcom.value.datalength != CDoom.net_buffer_size
      if !CDoom.debugfile.null?
        CDoom.doom_fprint(CDoom.debugfile, "bad packet length ")
        CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(CDoom.doomcom.value.datalength, 10))
        CDoom.doom_fprint(CDoom.debugfile, "\n")
      end
      return 0
    end

    if CDoom.net_buffer_checksum != CDoom.netbuffer.value.checksum & NCMD_CHECKSUM
      if !CDoom.debugfile.null?
        CDoom.doom_fprint(CDoom.debugfile, "bad packet checksum\n")
      end
      return 0
    end

    if !CDoom.debugfile.null?
      if CDoom.netbuffer.value.checksum & NCMD_SETUP != 0
        CDoom.doom_fprint(CDoom.debugfile, "setup packet\n")
      else
        realretrans = -1
        if CDoom.netbuffer.value.checksum & NCMD_RETRANSMIT != 0
          realretrans = CDoom.expand_tics(CDoom.netbuffer.value.retransmitfrom)
        end

        CDoom.doom_fprint(CDoom.debugfile, "get ")
        CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(CDoom.doomcom.value.remotenode, 10))
        CDoom.doom_fprint(CDoom.debugfile, " = (")
        CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(CDoom.expand_tics(CDoom.netbuffer.value.starttic), 10))
        CDoom.doom_fprint(CDoom.debugfile, " + ")
        CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(CDoom.netbuffer.value.numtics, 10))
        CDoom.doom_fprint(CDoom.debugfile, ", R ")
        CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(realretrans, 10))
        CDoom.doom_fprint(CDoom.debugfile, ")[")
        CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(CDoom.doomcom.value.datalength, 10))
        CDoom.doom_fprint(CDoom.debugfile, "]")

        CDoom.doomcom.value.datalength.times do |i|
          CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(CDoom.netbuffer.as(UInt8*)[i], 10))
          CDoom.doom_fprint(CDoom.debugfile, " ")
        end
        CDoom.doom_fprint(CDoom.debugfile, "\n")
      end
    end
    return 1
  end

  #
  # get_packets
  #
  def self.get_packets
    while CDoom.h_get_packet != 0
      next if CDoom.netbuffer.value.checksum & NCMD_SETUP != 0 # extra setup packet
      # puts "get_packets: Got packet with checksum #{CDoom.netbuffer.value.checksum}"

      netconsole = CDoom.netbuffer.value.player & ~PL_DRONE
      netnode = CDoom.doomcom.value.remotenode

      # to save bytes, only the low byte of tic numbers are sent
      # Figure out what the rest of the bytes are
      realstart = CDoom.expand_tics(CDoom.netbuffer.value.starttic)
      realend = realstart + CDoom.netbuffer.value.numtics

      # check for exiting the game
      if CDoom.netbuffer.value.checksum & NCMD_EXIT != 0
        next if CDoom.nodeingame[netnode] == 0
        CDoom.nodeingame[netnode] = 0
        CDoom.playeringame[netconsole] = 0
        CDoom.doom_strcpy(CDoom.exitmsg, "Player 1 left the game")
        CDoom.exitmsg[7] = CDoom.exitmsg[7] + netconsole
        (CDoom.players.to_unsafe + CDoom.consoleplayer).value.message = CDoom.exitmsg
        if netconsole != CDoom.consoleplayer
          # Despawn the player
          g_despawn_player(netconsole)
        end
        CDoom.g_check_demo_status if CDoom.demorecording != 0
        next
      end

      # check for a remote game kill
      CDoom.i_error("Error: Killed by network driver") if CDoom.netbuffer.value.checksum & NCMD_KILL != 0

      CDoom.nodeforplayer[netconsole] = netnode

      # check for retransmit request
      if CDoom.resendcount[netnode] <= 0 &&
         (CDoom.netbuffer.value.checksum & NCMD_RETRANSMIT) != 0
        CDoom.resendto[netnode] = CDoom.expand_tics(CDoom.netbuffer.value.retransmitfrom)
        if !CDoom.debugfile.null?
          CDoom.doom_fprint(CDoom.debugfile, "retransmit from ")
          CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(CDoom.resendto[netnode], 10))
          CDoom.doom_fprint(CDoom.debugfile, "\n")
        end
        CDoom.resendcount[netnode] = RESENDCOUNT
      else
        CDoom.resendcount[netnode] = CDoom.resendcount[netnode] - 1
      end

      # check for out of order / duplicated packet
      next if realend == CDoom.nettics[netnode]

      if realend < CDoom.nettics[netnode]
        if !CDoom.debugfile.null?
          CDoom.doom_fprint(CDoom.debugfile, "out of order packet (")
          CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(realstart, 10))
          CDoom.doom_fprint(CDoom.debugfile, " + ")
          CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(CDoom.netbuffer.value.numtics, 10))
          CDoom.doom_fprint(CDoom.debugfile, ")\n")
        end
        next
      end

      # check for a missed packet
      if realstart > CDoom.nettics[netnode]
        # stop processing until the other system resends the missed tics
        if !CDoom.debugfile.null?
          CDoom.doom_fprint(CDoom.debugfile, "missed tics from ")
          CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(netnode, 10))
          CDoom.doom_fprint(CDoom.debugfile, " (")
          CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(realstart, 10))
          CDoom.doom_fprint(CDoom.debugfile, " - ")
          CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(CDoom.nettics[netnode], 10))
          CDoom.doom_fprint(CDoom.debugfile, ")\n")
        end
        CDoom.remoteresend[netnode] = 1
        next
      end

      # update command store from the packet
      CDoom.remoteresend[netnode] = 0

      start = CDoom.nettics[netnode] - realstart
      src = CDoom.netbuffer.value.cmds.to_unsafe + start

      while CDoom.nettics[netnode] < realend
        # puts "get_packet: Copying tics"
        dest = (CDoom.netcmds.to_unsafe + netconsole).value.to_unsafe + (CDoom.nettics[netnode] % CDoom::BACKUPTICS)
        CDoom.nettics[netnode] = CDoom.nettics[netnode] + 1
        dest.copy_from(src, 1)
        src += 1
      end
    end
  end

  #
  # net_update
  # Builds ticcmds for console player,
  # sends out a packet
  #
  def self.net_update
    # Packet Punching
    if @@punch_countdown > 0
      punch_peers
      @@punch_countdown -= 1
    end

    # check time
    nowtime = CDoom.i_get_time // CDoom.ticdup
    newtics = nowtime - CDoom.gametime
    CDoom.gametime = nowtime

    if newtics > 0 # something new to update
      if CDoom.skiptics <= newtics
        newtics -= CDoom.skiptics
        CDoom.skiptics = 0
      else
        CDoom.skiptics -= newtics
        newtics = 0
      end

      CDoom.netbuffer.value.player = CDoom.consoleplayer

      # build new ticcmds for console player
      gameticdiv = CDoom.gametic // CDoom.ticdup
      newtics.times do |i|
        remaining = newtics - i
        break if CDoom.maketic - gameticdiv >= CDoom::BACKUPTICS // 2 - 1 # can't hold any more

        mouse_step = Raylib::Vector2.new(
          x: @@mouse_queued.x // remaining,
          y: @@mouse_queued.y // remaining)
        @@mouse_queued = Raylib::Vector2.new(
          x: @@mouse_queued.x - mouse_step.x,
          y: @@mouse_queued.y - mouse_step.y)

        i_start_tic(mouse_step)
        CDoom.d_process_events

        CDoom.g_build_ticcmd(CDoom.localcmds.to_unsafe + CDoom.maketic % CDoom::BACKUPTICS)
        CDoom.maketic += 1
      end

      return if CDoom.singletics != 0 # singletic update is syncronous

      # send the packet to the other nodes
      CDoom.doomcom.value.numnodes.times do |i|
        # puts "net_update : Sending packets to other nodes"
        if CDoom.nodeingame[i] != 0
          CDoom.netbuffer.value.starttic = CDoom.resendto[i]
          realstart = CDoom.resendto[i]
          CDoom.netbuffer.value.numtics = CDoom.maketic - realstart
          if CDoom.netbuffer.value.numtics > CDoom::BACKUPTICS
            CDoom.i_error("Error: net_update: netbuffer.value.numtics > BACKUPTICS")
          end

          CDoom.resendto[i] = CDoom.maketic - CDoom.doomcom.value.extratics

          CDoom.netbuffer.value.numtics.times do |j|
            (CDoom.netbuffer.value.cmds.to_unsafe + j).copy_from(
              CDoom.localcmds.to_unsafe + ((realstart + j) % CDoom::BACKUPTICS), 1)
          end

          if CDoom.remoteresend[i] != 0
            CDoom.netbuffer.value.retransmitfrom = CDoom.nettics[i]
            CDoom.h_send_packet(i, NCMD_RETRANSMIT)
          else
            CDoom.netbuffer.value.retransmitfrom = 0
            CDoom.h_send_packet(i, 0)
          end
        end
      end
    end
    # listen for other packets
    CDoom.get_packets
  end

  #
  # check_abort
  #
  def self.check_abort
    stoptic = CDoom.i_get_time + 2
    while CDoom.i_get_time < stoptic
      i_start_tic
    end

    i_start_tic
    while CDoom.eventtail != CDoom.eventhead
      ev = CDoom.events.to_unsafe + CDoom.eventtail
      if ev.value.type == CDoom::Evtype::Keydown && ev.value.data1 == CDoom::KEY_ESCAPE
        CDoom.i_error("Error: Network game synchronization aborted.")
      end
      CDoom.eventtail += 1
      CDoom.eventtail = (CDoom.eventtail) & (CDoom::MAXEVENTS - 1)
    end
  end

  @@punch_countdown = 0

  def self.punch_peers
    @@sendaddress.each_with_index do |addr, i|
      next unless addr
      next if i == CDoom.consoleplayer
      begin
        @@insocket.try &.send(Bytes.new(1) { 0_u8 }, to: addr)
      rescue
      end
    end
  end

  #
  # d_arbitrate_net_start
  #
  def self.d_arbitrate_net_start
    CDoom.autostart = 1

    if CDoom.doomcom.value.consoleplayer != 0
      i_error("Error: d_arbitrate_net_start: Host IP is not valid!") unless @@sendaddress[1]
      puts "sending connection info..."
      loop do
        CDoom.screens[0].clear(CDoom::SCREENWIDTH * 17)
        m_write_text(0, 0, "Escape to exit")
        m_write_text(0, 9, "Sending connection data on port #{@@doomport}")
        doom_draw
        check_abort
        CDoom.netbuffer.value.retransmitfrom = 69
        CDoom.netbuffer.value.starttic = 19
        CDoom.netbuffer.value.numtics = 0
        h_send_packet(1, NCMD_CONNECT) # Assume second node is host

        next if CDoom.h_get_packet == 0
        if CDoom.netbuffer.value.checksum & NCMD_SETUP != 0
          if CDoom.netbuffer.value.player != NETVERSION
            CDoom.i_error("Error: Different DOOM versions cannot play a net game!")
          end
          CDoom.startskill = CDoom::Skill.new(CDoom.netbuffer.value.retransmitfrom & 15)
          CDoom.deathmatch = (CDoom.netbuffer.value.retransmitfrom & 0xc0) >> 6
          CDoom.nomonsters = (CDoom.netbuffer.value.retransmitfrom & 0x20) > 0
          CDoom.respawnparm = (CDoom.netbuffer.value.retransmitfrom & 0x10) > 0
          CDoom.startmap = CDoom.netbuffer.value.starttic & 0x3f
          CDoom.startepisode = CDoom.netbuffer.value.starttic >> 6

          packed = CDoom.netbuffer.value.cmds.to_unsafe.as(UInt8*)
          CDoom.doomcom.value.ticdup = packed.value
          packed += 1
          CDoom.doomcom.value.extratics = packed.value
          packed += 1

          puts "connected! waiting for host to start"
          loop do
            CDoom.screens[0].clear(CDoom::SCREENWIDTH * 17)
            m_write_text(0, 0, "Escape to exit")
            m_write_text(0, 9, "Connected to host!")
            doom_draw
            check_abort
            next if CDoom.h_get_packet == 0

            # Host is sending ips
            if CDoom.netbuffer.value.checksum & NCMD_DISTRIBUTE != 0
              puts "retrieving all clients info"
              CDoom.screens[0].clear(CDoom::SCREENWIDTH * 17)
              m_write_text(0, 0, "Gathering IPs")
              doom_draw
              if CDoom.netbuffer.value.retransmitfrom != 19 ||
                 CDoom.netbuffer.value.starttic != 69
                i_error("Error: d_arbitrate_net_start: Host sent bad IP distribution!")
              end

              numips = CDoom.netbuffer.value.numtics
              ipnums = CDoom.netbuffer.value.cmds.to_unsafe.as(UInt8*)
              CDoom.doomcom.value.consoleplayer = CDoom.netbuffer.value.player
              CDoom.consoleplayer = CDoom.doomcom.value.consoleplayer

              numips.times do |i|
                # Load other client's IP addresses
                CDoom.doomcom.value.numnodes = CDoom.doomcom.value.numnodes + 1
                CDoom.doomcom.value.numplayers = CDoom.doomcom.value.numplayers + 1
                @@sendaddress[i + 2] = Socket::IPAddress.v4(
                  ipnums[0], ipnums[1], ipnums[2], ipnums[3],
                  port: ipnums[4].to_u16 + (ipnums[5].to_u16 << 8))
                ipnums += 6
              end
              return
            end
          end
        end
      end
    else
      # key player, send the setup info
      puts "waiting for client info..."
      loop do
        CDoom.check_abort

        CDoom.doomcom.value.numnodes.times do |i|
          # Send out setup until everyones loaded
          CDoom.netbuffer.value.retransmitfrom = CDoom.startskill
          if CDoom.deathmatch != 0
            CDoom.netbuffer.value.retransmitfrom = CDoom.netbuffer.value.retransmitfrom | (CDoom.deathmatch << 6)
          end
          if CDoom.nomonsters != 0
            CDoom.netbuffer.value.retransmitfrom = CDoom.netbuffer.value.retransmitfrom | 0x20
          end
          if CDoom.respawnparm != 0
            CDoom.netbuffer.value.retransmitfrom = CDoom.netbuffer.value.retransmitfrom | 0x10
          end
          CDoom.netbuffer.value.starttic = CDoom.startepisode * 64 + CDoom.startmap
          CDoom.netbuffer.value.player = NETVERSION
          CDoom.netbuffer.value.numtics = 1
          packed = CDoom.netbuffer.value.cmds.to_unsafe.as(UInt8*)
          packed.value = CDoom.doomcom.value.ticdup.to_u8!
          packed += 1
          packed.value = CDoom.doomcom.value.extratics.to_u8!
          packed += 1
          CDoom.h_send_packet(i, NCMD_SETUP)
        end

        CDoom::MAXPLAYERS.times do |i|
          if CDoom.h_get_packet != 0 &&
             CDoom.netbuffer.value.checksum & NCMD_CONNECT != 0 &&
             CDoom.doomcom.value.remotenode == CDoom.doomcom.value.numplayers
            CDoom.doomcom.value.numnodes = CDoom.doomcom.value.numnodes + 1
            CDoom.doomcom.value.numplayers = CDoom.doomcom.value.numplayers + 1
            puts "connected client!"
          end
        end

        # NEED BREAK

        # Space to start game and end waiting for connections
        CDoom.screens[0].clear(CDoom::SCREENWIDTH * (18 + 8))
        m_write_text(0, 0, "Press space to start. Escape to exit")
        m_write_text(0, 9, "Listening for clients on port #{@@doomport}")
        m_write_text(0, 18, "#{CDoom.doomcom.value.numnodes - 1} player#{
  CDoom.doomcom.value.numnodes != 2 ? "s" : ""
} connected")
        doom_draw
        if CDoom.doomcom.value.numnodes >= CDoom::MAXPLAYERS ||
           Raylib::KeyboardKey::Space.down?
          puts "distributing client info for #{CDoom.doomcom.value.numnodes - 1} clients"
          # Distribute ips
          CDoom.netbuffer.value.retransmitfrom = 19
          CDoom.netbuffer.value.starttic = 69

          # Build ips into ticcmds

          # Send out
          CDoom.doomcom.value.numnodes.times do |i|
            CDoom.netbuffer.value.player = i
            CDoom.netbuffer.value.numtics = 0
            ipnums = CDoom.netbuffer.value.cmds.to_unsafe.as(UInt8*)

            @@sendaddress.each do |add|
              next if !add || add == @@sendaddress[i]
              add.address.split('.').map(&.to_i.to_u8!).each do |ipnum|
                ipnums.value = ipnum
                ipnums += 1
              end
              ipnums.value = (add.port & 0xff).to_u8
              ipnums += 1
              ipnums.value = (add.port >> 8).to_u8
              ipnums += 1
              CDoom.netbuffer.value.numtics = CDoom.netbuffer.value.numtics + 1 # A bit lazy, no?
            end

            50.times do
              h_send_packet(i, NCMD_DISTRIBUTE)
            end
          end
          return
        end
      end
    end
  end

  #
  # d_check_net_game
  # Works out player numbers among the net participants
  #
  def self.d_check_net_game
    CDoom::MAXNETNODES.times do |i|
      CDoom.nodeingame[i] = 0
      CDoom.nettics[i] = 0
      CDoom.remoteresend[i] = 0 # set when local needs tics
      CDoom.resendto[i] = 0     # which tic to start sending
    end

    # i_init_network sets doomcom and netgame
    CDoom.i_init_network
    CDoom.i_error("Error: Doomcom buffer invalid!") if CDoom.doomcom.value.id != CDoom::DOOMCOM_ID

    CDoom.netbuffer = pointerof(CDoom.doomcom.value.@data)
    CDoom.consoleplayer = CDoom.doomcom.value.consoleplayer
    CDoom.displayplayer = CDoom.consoleplayer
    CDoom.d_arbitrate_net_start if CDoom.netgame != 0
    puts "startskill: #{CDoom.startskill} | deathmatch: #{CDoom.deathmatch}" +
         " | startmap: #{CDoom.startmap} | startepisode: #{CDoom.startepisode}"
    print "ticdup: #{CDoom.doomcom.value.ticdup} | extratic: #{CDoom.doomcom.value.extratics} | "

    # read values out of doomcom
    CDoom.ticdup = CDoom.doomcom.value.ticdup
    CDoom.maxsend = CDoom::BACKUPTICS // (2 * CDoom.ticdup) - 1
    CDoom.maxsend = 1 if CDoom.maxsend < 1

    CDoom.doomcom.value.numplayers.times { |i| CDoom.playeringame[i] = 1 }
    CDoom.doomcom.value.numnodes.times { |i| CDoom.nodeingame[i] = 1 }
    @@punch_countdown = 70

    puts "player #{CDoom.consoleplayer + 1} of #{CDoom.doomcom.value.numplayers}" +
         " (#{CDoom.doomcom.value.numnodes} nodes)"
  end

  #
  # d_quit_net_game
  # Called before quitting to leave a net game
  # without hanging the other players
  #
  def self.d_quit_net_game
    doom_close(CDoom.debugfile) if !CDoom.debugfile.null?

    return if CDoom.netgame == 0 || CDoom.usergame == 0 || CDoom.consoleplayer == -1 || CDoom.demoplayback == 1

    # send a bunch of packets for security
    CDoom.netbuffer.value.player = CDoom.consoleplayer
    CDoom.netbuffer.value.numtics = 0
    4.times do |i|
      (CDoom.doomcom.value.numnodes - 1).times do |j|
        j += 1
        CDoom.h_send_packet(j, NCMD_EXIT) if CDoom.nodeingame[j] != 0
        CDoom.i_wait_vbl(1)
      end
    end
  end

  def self.doom_htons(x : Int16) : Int16
    NEEDS_BYTE_SWAP ? x.byte_swap : x
  end

  def self.doom_htonl(x : UInt32) : UInt32
    NEEDS_BYTE_SWAP ? x.byte_swap : x
  end

  def self.udp_socket : UDPSocket
    begin
      UDPSocket.new(Socket::Family::INET)
    rescue ex
      i_error("Error: can't create socket: #{ex.message}")
      raise ex
    end
  end

  def self.bind_to_local_port(socket : UDPSocket, port : Int32)
    begin
      socket.bind("0.0.0.0", port)
    rescue ex
      i_error("Error: bind_to_local_port: bind: #{ex.message}")
    end
  end

  def self.packet_send
    # sock = @@sendsocket
    # Use insocket because in and out ports will both be doomport
    # Helps prevent bugs on lan
    sock = @@insocket
    return unless sock
    dest = @@sendaddress[CDoom.doomcom.value.remotenode]
    return unless dest

    sw = CDoom::Doomdata.new

    # puts "SEND : Sending packet to #{dest.address}"

    # byte swap
    sw.checksum = doom_htonl(CDoom.netbuffer.value.checksum)
    sw.player = CDoom.netbuffer.value.player
    sw.retransmitfrom = CDoom.netbuffer.value.retransmitfrom
    sw.starttic = CDoom.netbuffer.value.starttic
    sw.numtics = CDoom.netbuffer.value.numtics
    c = 0
    while c < CDoom.netbuffer.value.numtics
      (sw.cmds.to_unsafe + c).value.forwardmove = CDoom.netbuffer.value.cmds[c].forwardmove
      (sw.cmds.to_unsafe + c).value.sidemove = CDoom.netbuffer.value.cmds[c].sidemove
      (sw.cmds.to_unsafe + c).value.angleturn = doom_htons(CDoom.netbuffer.value.cmds[c].angleturn)
      (sw.cmds.to_unsafe + c).value.consistancy = doom_htons(CDoom.netbuffer.value.cmds[c].consistancy)
      (sw.cmds.to_unsafe + c).value.chatchar = CDoom.netbuffer.value.cmds[c].chatchar
      (sw.cmds.to_unsafe + c).value.buttons = CDoom.netbuffer.value.cmds[c].buttons
      c += 1
    end

    bytes = Bytes.new(pointerof(sw).as(UInt8*), CDoom.doomcom.value.datalength)
    begin
      c = sock.send(bytes, to: dest)
    rescue ex
      i_error("Error: packet_send: Failed to send packet to #{dest.address}:#{dest.port}")
    end
  end

  @@first = true

  def self.packet_get
    sock = @@insocket
    unless sock
      CDoom.doomcom.value.remotenode = -1
      return
    end

    select
    when result = @@recv_channel.receive
      sw, c, fromaddress = result
    else
      CDoom.doomcom.value.remotenode = -1
      return
    end

    if @@first
      # puts "len=#{c}=[0x#{sw.checksum.to_s(16)} 0x#{sw.player.to_s(16)}]"
    end
    @@first = false

    i = 0
    while i < CDoom.doomcom.value.numnodes
      addr = @@sendaddress[i]
      break if addr && addr.address == fromaddress.address
      i += 1
    end

    # Received address is not loaded, or invalid
    if i == CDoom.doomcom.value.numnodes
      # Not server
      if CDoom.doomcom.value.consoleplayer != 0
        # puts "GET : Invalid ip"
        CDoom.doomcom.value.remotenode = -1
        return
      end
      if CDoom.doomcom.value.numnodes < CDoom::MAXPLAYERS
        # We have room, return if invalid data
        if doom_htonl(sw.checksum) & NCMD_CONNECT != 0 &&
           sw.retransmitfrom == 69 && sw.starttic == 19 &&
           sw.numtics == 0
          # Add it in

          @@sendaddress[i] = fromaddress
        else
          CDoom.doomcom.value.remotenode = -1
          return # Invalid
        end
      end
    end

    # puts "GET : Got valid packet from #{fromaddress.address}"
    CDoom.doomcom.value.remotenode = i
    CDoom.doomcom.value.datalength = c.to_i16!

    CDoom.netbuffer.value.checksum = doom_htonl(sw.checksum)
    CDoom.netbuffer.value.player = sw.player
    CDoom.netbuffer.value.retransmitfrom = sw.retransmitfrom
    CDoom.netbuffer.value.starttic = sw.starttic
    CDoom.netbuffer.value.numtics = sw.numtics

    CDoom.netbuffer.value.numtics.times do |c|
      (CDoom.netbuffer.value.cmds.to_unsafe + c).value.forwardmove = sw.cmds[c].forwardmove
      (CDoom.netbuffer.value.cmds.to_unsafe + c).value.sidemove = sw.cmds[c].sidemove
      (CDoom.netbuffer.value.cmds.to_unsafe + c).value.angleturn = doom_htons(sw.cmds[c].angleturn)
      (CDoom.netbuffer.value.cmds.to_unsafe + c).value.consistancy = doom_htons(sw.cmds[c].consistancy)
      (CDoom.netbuffer.value.cmds.to_unsafe + c).value.chatchar = sw.cmds[c].chatchar
      (CDoom.netbuffer.value.cmds.to_unsafe + c).value.buttons = sw.cmds[c].buttons
    end
  end

  def self.get_local_address : Int32
    hostname = System.hostname
    hostentry = Socket::Addrinfo.resolve(hostname, nil,
      family: Socket::Family::INET, type: Socket::Type::DGRAM).first?

    i_error("Error: get_local_address : get_host_by_name: couldn't get local host") unless hostentry

    octets = hostentry.not_nil!.ip_address.address.split('.').map(&.to_u32)
    (octets[0] | (octets[1] << 8) | (octets[2] << 16) | (octets[3] << 24)).to_i32!
  end

  def self.i_init_network
    CDoom.doomcom = GC.malloc(sizeof(typeof(CDoom.doomcom.value))).as(Pointer(CDoom::Doomcom))
    CDoom.doom_memset(CDoom.doomcom, 0, sizeof(typeof(CDoom.doomcom.value)))

    # set up for network
    i = ARGV.index("-dup")
    if i && i < ARGV.size - 1
      CDoom.doomcom.value.ticdup = ARGV[i + 1][0] - '0'
      CDoom.doomcom.value.ticdup = 1 if CDoom.doomcom.value.ticdup < 1
      CDoom.doomcom.value.ticdup = 9 if CDoom.doomcom.value.ticdup > 9
    else
      CDoom.doomcom.value.ticdup = 1
    end

    CDoom.doomcom.value.extratics = 0
    ARGV.index("-extratic").try do |p|
      if p = ARGV[p + 1]?
        CDoom.doomcom.value.extratics = p.to_i.to_u8!
        CDoom.doomcom.value.extratics = 4 if CDoom.doomcom.value.extratics > 4
      else
        # Set to one if no number is provided
        CDoom.doomcom.value.extratics = 1
      end
    end

    p = ARGV.index("-port")
    if p && p < ARGV.size - 1
      @@doomport = ARGV[p + 1].to_i
      puts "using alternate port #{@@doomport}"
    end

    # parse network game options,
    #  -net <host>
    i = ARGV.index("-net")
    unless i
      # single player game
      CDoom.netgame = 0
      CDoom.doomcom.value.id = CDoom::DOOMCOM_ID
      CDoom.doomcom.value.numplayers = 1
      CDoom.doomcom.value.numnodes = 1
      CDoom.doomcom.value.consoleplayer = 0
      CDoom.deathmatch = 0
      CDoom.consoleplayer = 0
      return
    end

    @@netsend = ->packet_send
    @@netget = ->packet_get
    CDoom.netgame = 1

    CDoom.doomcom.value.numnodes = 1 # this node for sure

    # Host ip is given, else is host
    if (i += 1) < ARGV.size && ARGV[i][0] != '-'
      arg = ARGV[i]

      @@sendaddress[1] =
        if arg[0] == '.'
          Socket::IPAddress.new(arg[1..], @@doomport)
        else
          hostentry = Socket::Addrinfo.resolve(arg, nil,
            family: Socket::Family::INET, type: Socket::Type::DGRAM).first?

          CDoom.i_error("Error: i_init_network: couldn't find #{arg}") unless hostentry

          Socket::IPAddress.new(hostentry.not_nil!.ip_address.address, @@doomport)
        end
      CDoom.doomcom.value.numnodes = 2       # At least
      CDoom.doomcom.value.consoleplayer = -1 # Setup in d_arbitrate_net_start
    end

    CDoom.doomcom.value.id = CDoom::DOOMCOM_ID
    CDoom.doomcom.value.numplayers = CDoom.doomcom.value.numnodes

    @@insocket = udp_socket()
    bind_to_local_port(@@insocket.not_nil!, @@doomport)

    @@sendsocket = udp_socket()
  end

  def self.i_net_cmd
    case CDoom::Command.new(CDoom.doomcom.value.command.to_i32)
    when CDoom::Command::SEND
      @@netsend.call
    when CDoom::Command::GET
      @@netget.call
    else
      i_error("Error: Bad net cmd: #{CDoom::Command.new(CDoom.doomcom.value.command.to_i32)}")
    end
  end
end
