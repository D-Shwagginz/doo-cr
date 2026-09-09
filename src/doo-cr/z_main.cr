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
# ==> Zone memory management

module Doocr
  def self.z_init
    size = 0
    CDoom.mainzone = CDoom.i_zone_base(pointerof(size)).as(CDoom::Memzone*)
    CDoom.mainzone.value.size = size

    # set the entire zone to one free block
    block = (CDoom.mainzone.as(UInt8*) + sizeof(CDoom::Memzone)).as(CDoom::Memblock*)
    CDoom.mainzone.value.blocklist.next = block
    CDoom.mainzone.value.blocklist.prev = block

    CDoom.mainzone.value.blocklist.user = CDoom.mainzone.as(Void**)
    CDoom.mainzone.value.blocklist.tag = CDoom::PU_STATIC
    CDoom.mainzone.value.rover = block

    block.value.prev = pointerof(CDoom.mainzone.value.@blocklist)
    block.value.next = block.value.prev

    # 0 indicates a free block.
    block.value.user = Pointer(Void*).null

    block.value.size = CDoom.mainzone.value.size - sizeof(CDoom::Memzone)
    puts "#{Doocr.mb_used}MBs of memory allocated."
  end

  def self.z_free(ptr : Void*)
    block = (ptr.as(UInt8*) - sizeof(CDoom::Memblock)).as(CDoom::Memblock*)

    if block.value.id != CDoom::ZONEID
      CDoom.i_error("Error: z_free: freed a pointer without ZONEID")
    end

    if block.value.user.address > 0x100
      # smaller values are not pointers

      # clear the user's mark
      block.value.user.value = Pointer(Void).null
    end

    # mark as free
    block.value.user = Pointer(Void*).null
    block.value.tag = 0
    block.value.id = 0

    other = block.value.prev

    if other.value.user.null?
      # merge with previous free block
      other.value.size = other.value.size + block.value.size
      other.value.next = block.value.next
      other.value.next.value.prev = other

      CDoom.mainzone.value.rover = other if block == CDoom.mainzone.value.rover

      block = other
    end

    other = block.value.next
    if other.value.user.null?
      # merge the next free block onto the end
      block.value.size = block.value.size + other.value.size
      block.value.next = other.value.next
      block.value.next.value.prev = block

      CDoom.mainzone.value.rover = block if other == CDoom.mainzone.value.rover
    end
  end

  def self.z_malloc(size : LibC::Int, tag : LibC::Int, user : Void*) : Void*
    size = (size + CDoom::MEM_ALIGN - 1) & ~(CDoom::MEM_ALIGN - 1)

    # scan through the block list,
    # looking for the first free block
    # of sufficient size,
    # throwing out any purgable blocks along the way.

    # account for size of block header
    size += sizeof(CDoom::Memblock)

    # if there is a free block behind the rover,
    #  back up over them
    base = CDoom.mainzone.value.rover

    base = base.value.prev if base.value.prev.value.user.null?

    rover = base
    start = base.value.prev

    loop do
      if rover == start
        # scanned all the way around the list
        CDoom.i_error("Error: z_malloc: failed on allocation of #{size} bytes")
      end

      if !rover.value.user.null?
        if rover.value.tag < CDoom::PU_PURGELEVEL
          # hit a block that can't be purged,
          #  so move base past it
          base = rover.value.next
          rover = rover.value.next
        else
          # free the rover block (adding the size to base)

          # the rover can be the base block
          base = base.value.prev
          CDoom.z_free(rover.as(UInt8*) + sizeof(CDoom::Memblock))
          base = base.value.next
          rover = base.value.next
        end
      else
        rover = rover.value.next
      end

      break unless !base.value.user.null? || base.value.size < size
    end

    # found a block big enough
    extra = base.value.size - size

    if extra > CDoom::MINFRAGMENT
      # there will be a free fragment after the allocated block
      newblock = (base.as(UInt8*) + size).as(CDoom::Memblock*)
      newblock.value.size = extra

      # 0 indicates free block.
      newblock.value.user = Pointer(Void*).null
      newblock.value.tag = 0
      newblock.value.prev = base
      newblock.value.next = base.value.next
      newblock.value.next.value.prev = newblock

      base.value.next = newblock
      base.value.size = size
    end

    if !user.null?
      # mark as an in use block
      base.value.user = user.as(Void**)
      user.as(Void**).value = (base.as(UInt8*) + sizeof(CDoom::Memblock)).as(Void*)
    else
      if tag >= CDoom::PU_PURGELEVEL
        CDoom.i_error("Error: z_malloc: an owner is required for purgable blocks")
      end

      # mark as in use, but unowned
      base.value.user = Pointer(Void*).new(2_u64)
    end
    base.value.tag = tag

    # next allocation will start looking here
    CDoom.mainzone.value.rover = base.value.next

    base.value.id = CDoom::ZONEID

    return (base.as(UInt8*) + sizeof(CDoom::Memblock)).as(Void*)
  end

  def self.z_free_tags(lowtag : LibC::Int, hightag : LibC::Int)
    block = CDoom.mainzone.value.blocklist.next
    while block != pointerof(CDoom.mainzone.value.@blocklist)
      # get link before freeing
      nextb = block.value.next

      # free block?
      if block.value.user.null?
        block = nextb
        next
      end

      if block.value.tag >= lowtag && block.value.tag <= hightag
        CDoom.z_free(block.as(UInt8*) + sizeof(CDoom::Memblock))
      end

      block = nextb
    end
  end

  def self.z_check_heap
    block = CDoom.mainzone.value.blocklist.next

    loop do
      if block.value.next == pointerof(CDoom.mainzone.value.@blocklist)
        # all blocks have been hit
        break
      end

      if block.as(UInt8*) + block.value.size != block.value.next.as(UInt8*)
        CDoom.i_error("Error: z_check_heap: block size does not touch the next block\n")
      end

      if block.value.next.value.prev != block
        CDoom.i_error("Error: z_check_heap: next block doesn't have proper back link\n")
      end

      if block.value.user.null? && block.value.next.value.user.null?
        CDoom.i_error("Error: z_check_heap: two consecutive free blocks\n")
      end

      block = block.value.next
    end
  end

  def self.z_change_tag2(ptr : Void*, tag : LibC::Int)
    block = (ptr.as(UInt8*) - sizeof(CDoom::Memblock)).as(CDoom::Memblock*)

    if block.value.id != CDoom::ZONEID
      CDoom.i_error("Error: z_change_tag: freed a pointer without ZONEID")
    end

    if tag >= CDoom::PU_PURGELEVEL && block.value.user.address < 0x100
      CDoom.i_error("Error: z_change_tag: an owner is required for purgable blocks")
    end

    block.value.tag = tag
  end
end
