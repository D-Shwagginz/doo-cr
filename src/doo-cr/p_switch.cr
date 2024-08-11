# Switches, buttons. Two-state animation. Exits.

module Doocr
  # CHANGE THE TEXTURE OF A WALL SWITCH TO ITS OPPOSITE
  @@alph_switch_list = [
    # Doom shareware episode 1 switches
    SwitchList.new("SW1BRCOM", "SW2BRCOM", 1),
    SwitchList.new("SW1BRN1", "SW2BRN1", 1),
    SwitchList.new("SW1BRN2", "SW2BRN2", 1),
    SwitchList.new("SW1BRNGN", "SW2BRNGN", 1),
    SwitchList.new("SW1BROWN", "SW2BROWN", 1),
    SwitchList.new("SW1COMM", "SW2COMM", 1),
    SwitchList.new("SW1COMP", "SW2COMP", 1),
    SwitchList.new("SW1DIRT", "SW2DIRT", 1),
    SwitchList.new("SW1EXIT", "SW2EXIT", 1),
    SwitchList.new("SW1GRAY", "SW2GRAY", 1),
    SwitchList.new("SW1GRAY1", "SW2GRAY1", 1),
    SwitchList.new("SW1METAL", "SW2METAL", 1),
    SwitchList.new("SW1PIPE", "SW2PIPE", 1),
    SwitchList.new("SW1SLAD", "SW2SLAD", 1),
    SwitchList.new("SW1STARG", "SW2STARG", 1),
    SwitchList.new("SW1STON1", "SW2STON1", 1),
    SwitchList.new("SW1STON2", "SW2STON2", 1),
    SwitchList.new("SW1STONE", "SW2STONE", 1),
    SwitchList.new("SW1STRTN", "SW2STRTN", 1),

    # Doom registered episodes 2&3 switches
    SwitchList.new("SW1BLUE", "SW2BLUE", 2),
    SwitchList.new("SW1CMT", "SW2CMT", 2),
    SwitchList.new("SW1GARG", "SW2GARG", 2),
    SwitchList.new("SW1GSTON", "SW2GSTON", 2),
    SwitchList.new("SW1HOT", "SW2HOT", 2),
    SwitchList.new("SW1LION", "SW2LION", 2),
    SwitchList.new("SW1SATYR", "SW2SATYR", 2),
    SwitchList.new("SW1SKIN", "SW2SKIN", 2),
    SwitchList.new("SW1VINE", "SW2VINE", 2),
    SwitchList.new("SW1WOOD", "SW2WOOD", 2),

    # Doom II switches
    SwitchList.new("SW1PANEL", "SW2PANEL", 3),
    SwitchList.new("SW1ROCK", "SW2ROCK", 3),
    SwitchList.new("SW1MET2", "SW2MET2", 3),
    SwitchList.new("SW1WDMET", "SW2WDMET", 3),
    SwitchList.new("SW1BRIK", "SW2BRIK", 3),
    SwitchList.new("SW1MOD1", "SW2MOD1", 3),
    SwitchList.new("SW1ZIM", "SW2ZIM", 3),
    SwitchList.new("SW1STON6", "SW2STON6", 3),
    SwitchList.new("SW1TEK", "SW2TEK", 3),
    SwitchList.new("SW1MARB", "SW2MARB", 3),
    SwitchList.new("SW1SKULL", "SW2SKULL", 3),

    SwitchList.new("\0", "\0", 0),
  ]

  @@switchlist : Array(Int32) = Array.new(MAXSWITCHES * 2, 0)
  @@numswitches : Int32 = 0

  def self.p_init_switch_list
    episode = 1

    episode = 2 if @@gamemode == GameMode::Registered
    episode = 3 if @@gamemode == GameMode::Commercial

    index = 0
    MAXSWITCHES.times do |i|
      if @@alph_switch_list[i].episode == 0
        @@numswitches = (index/2).to_i
        @@switchlist[index] = -1
        break
      end

      if @@alph_switch_list[i].episode <= episode
        x = @@textures.index { |tex| tex.name == @@alph_switch_list[i].name1 }
        raise "p_init_switch_list: Missing Switch Texture. Looking for #{@@alph_switch_list[i].name1}" unless x
        y = @@textures.index { |tex| tex.name == @@alph_switch_list[i].name2 }
        raise "p_init_switch_list: Missing Switch Texture. Looking for #{@@alph_switch_list[i].name2}" unless y
        @@switchlist[index] = x
        index += 1
        @@switchlist[index] = y
        index += 1
      end
    end
  end
end
