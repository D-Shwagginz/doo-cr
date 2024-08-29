module Doocr::Test
  context "Do Nothing", tags: "do nothing" do
    it "E1M1" do
      content = GameContent.create_dummy(WadPath::DOOM1)

      options = GameOptions.new
      options.skill = GameSkill::Hard
      options.episode = 1
      options.map = 1
      options.players[0].in_game = true

      cmds = Array.new(Player::MAX_PLAYER_COUNT, TicCmd.new)
      game = DoomGame.new(content, options)
      game.defered_init_new

      tics = 350

      agg_mobj_hash = 0
      agg_sector_hash = 0
      tics.times do |i|
        game.update(cmds)
        agg_mobj_hash = DoomDebug.combine_hash(agg_mobj_hash, DoomDebug.get_mobj_hash(game.world.as(World)))
        agg_sector_hash = DoomDebug.combine_hash(agg_sector_hash, DoomDebug.get_sector_hash(game.world.as(World)))
      end

      # DoomDebug.get_mobj_hash(game.world.as(World)).to_u32.should eq 0x66be313b_u32
      # agg_mobj_hash.to_u32.should eq 0xbd67b2b2_u32
      # DoomDebug.get_sector_hash(game.world.as(World)).to_u32.should eq 0x2cef7a1d_u32
      # agg_sector_hash.to_u32.should eq 0x5b99ca23_u32
    end
  end
end
