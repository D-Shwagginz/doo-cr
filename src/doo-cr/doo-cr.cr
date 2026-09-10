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
# ==> The entry point of DOO-CR

# The majority of these fils will be rewritten to be modernized,
# Crystalized, and overall improved (changed to be how I want it lol)
#
# A lot of this should scare you. It sure scared me.
# 99% of this is one to one with C, specifically PureDoom.
# I reworked a lot of stuff already but even then the first line
#  in this module is still a null pointer... so... it needs more work :)

module Doocr
  NULL_PROC   = Proc(Nil).new(Pointer(Void).null, Pointer(Void).null)
  NULL_PROCP1 = Proc(Int32, Nil).new(Pointer(Void).null, Pointer(Void).null)

  def self.open(filename : String, mode : String) : IO
    response = Channel({Bytes, Bool}).new
    @@io_jobs.send({filename, "rb", nil, response})
    data, ok = response.receive
    return IO::Memory.new(data)
  end

  def self.open(filename : String, mode : String, &)
    yield open(filename, mode)
  end

  def self.doom_memset(ptr : Void*, value : Int32, num : Int32)
    ptr.as(UInt8*).fill(num, value.to_u8!)
  end

  def self.doom_memcpy(destination : Void*, source : Void*, num : Int32) : Void*
    destination.as(UInt8*).copy_from(source.as(UInt8*), num)
    return destination
  end

  def self.doom_strlen(str : UInt8*) : Int32
    return String.new(str).size
  end

  def self.doom_concat(dst : UInt8*, src : UInt8*) : UInt8*
    concat = String.new(dst) + String.new(src)
    concat.to_slice.copy_to(dst, concat.bytesize)
    dst[concat.bytesize] = 0
    return dst
  end

  def self.doom_strcpy(dst : UInt8*, src : UInt8*) : UInt8*
    cpy = String.new(src)
    cpy.to_slice.copy_to(dst, cpy.bytesize)
    dst[cpy.bytesize] = 0
    return dst
  end

  def self.doom_strncpy(dst : UInt8*, src : UInt8*, num : Int32) : UInt8*
    len = doom_strlen(src) < num ? doom_strlen(src) : num
    diff = num - len
    dst.copy_from(src, len)
    (dst + len).fill(diff, 0_u8)
    return dst
  end

  def self.doom_strcmp(str1 : UInt8*, str2 : UInt8*) : Int32
    return str1.memcmp(str2, doom_strlen(str1) + 1).clamp(-1, 1)
  end

  def self.doom_strncmp(str1 : UInt8*, str2 : UInt8*, n : Int32) : Int32
    n.times do |i|
      c1 = str1[i]
      c2 = str2[i]
      return (c1.to_i32 - c2.to_i32).clamp(-1, 1) if c1 != c2
      return 0 if c1 == 0
    end
    return 0
  end

  def self.doom_toupper(c : Int32) : Int32
    return c - 'a'.ord + 'A'.ord if c >= 'a'.ord && c <= 'z'.ord
    return c
  end

  def self.doom_strcasecmp(str1 : UInt8*, str2 : UInt8*) : Int32
    return String.new(str1).compare(String.new(str2), case_insensitive: true)
  end

  def self.doom_strncasecmp(str1 : UInt8*, str2 : UInt8*, n : Int32) : Int32
    n.times do |i|
      c1 = doom_toupper(str1[i].to_i32)
      c2 = doom_toupper(str2[i].to_i32)
      return (c1 - c2).clamp(-1, 1) if c1 != c2
      return 0 if c1 == 0
    end
    return 0
  end

  def self.doom_atoi(str : UInt8*) : Int32
    String.new(str).to_i?(strict: false).try { |i| return i }
    return 0
  end

  def self.doom_atox(str : UInt8*) : Int32
    String.new(str).to_i?(base: 16, strict: false).try { |i| return i }
    return 0
  end

  def self.doom_itoa(k : Int32, radix : Int32) : UInt8*
    a = k.to_s(radix)
      a.to_slice.copy_to(Doocr.itoa_buf.to_unsafe, a.bytesize)
      Doocr.itoa_buf[a.bytesize] = 0
      return Doocr.itoa_buf.to_unsafe
  end

  def self.doom_ctoa(c : UInt8) : UInt8*
    Doocr.itoa_buf[0] = c
    Doocr.itoa_buf[1] = 0
    return Doocr.itoa_buf.to_unsafe
  end

  def self.doom_ptoa(p : Void*) : UInt8*
    a = "0x" + p.address.to_s(16).upcase
      a.to_slice.copy_to(Doocr.itoa_buf.to_unsafe, a.bytesize)
      Doocr.itoa_buf[a.bytesize] = 0
      return Doocr.itoa_buf.to_unsafe
  end

  def self.doom_fprint(handle : Void*, str : UInt8*) : Int32
    io = Box(File).unbox(handle)
    text = String.new(str)
    io << text
    text.bytesize
  end

  def self.doom_init
    Doocr.last_update_time = CDoom.i_get_time

    d_doom_main
  end

  def self.fixed_mul(a : LibC::Int, b : LibC::Int) : LibC::Int
    return ((a.to_i64 * b.to_i64) >> FRACBITS).to_i32!
  end

  def self.fixed_div(a : LibC::Int, b : LibC::Int) : LibC::Int
    return (a ^ b) < 0 ? Int32::MIN : Int32::MAX if (doom_abs(a) >> 14) >= doom_abs(b)
    return CDoom.fixed_div2(a, b)
  end

  def self.fixed_div2(a : LibC::Int, b : LibC::Int) : LibC::Int
    c = (a.to_f64 / b.to_f64) * FRACUNIT

    CDoom.i_error("Error: fixed_div: divide by zero") if c >= 2147483648.0 || c < -2147483648.0
    return c.to_i32!
  end

  def self.doom_strupr(s : LibC::Char*)
    while s.value != 0
      s.value = CDoom.doom_toupper(s.value).to_u8!
      s += 1
    end
  end

  def self.extract_file_base(path : LibC::Char*, dest : LibC::Char*)
    src = path + CDoom.doom_strlen(path) - 1

    # back up until a \ or the start
    while src != path &&
          (src - 1).value != '\\'.ord &&
          (src - 1).value != '/'.ord
      src -= 1
    end

    # copy up to eight characters
    CDoom.doom_memset(dest, 0, 8)
    length = 0

    while src.value != 0 && src.value != '.'.ord
      length += 1
      if length == 9
        CDoom.i_error("Error: Filename base of #{path} >8 chars")
      end

      dest.value = CDoom.doom_toupper(src.value).to_u8!
      dest += 1
      src += 1
    end
  end
end
