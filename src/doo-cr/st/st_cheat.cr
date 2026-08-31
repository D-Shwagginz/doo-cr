module Doocr
@@firsttime = 1
  @@cheat_xlate_table = uninitialized StaticArray(UInt8, 256)

  def self.cht_check_cheat(cht : CDoom::Cheatseq*, key : LibC::Char) : LibC::Int
    rc = 0
    if @@firsttime != 0
      @@firsttime = 0
      256.times { |i| @@cheat_xlate_table[i] = (scramble(i)).to_u8 }
    end

    if cht.value.p.null?
      cht.value.p = cht.value.sequence # initialize if first time
    end

    if cht.value.p.value == 0
      cht.value.p.value = key
      cht.value.p = cht.value.p + 1
    elsif @@cheat_xlate_table[key.to_u8!] == cht.value.p.value
      cht.value.p = cht.value.p + 1
    else
      cht.value.p = cht.value.sequence
    end

    if cht.value.p.value == 1
      cht.value.p = cht.value.p + 1
    elsif cht.value.p.value == 0xff # end of sequence character
      cht.value.p = cht.value.sequence
      rc = 1
    end

    return rc
  end

  def self.cht_get_param(cht : CDoom::Cheatseq*, buffer : LibC::Char*)
    p = cht.value.sequence
    while p.value != 1
      p += 1
    end
    p += 1

    c = 0

    loop do
      c = p.value
      buffer.value = c
      buffer += 1
      p.value = 0
      p += 1

      break unless c != 0 && p.value != 0xff
    end

    buffer.value = 0 if p.value == 0xff
  end
end