module Doocr::Test
  context "Fire Once", tags: "fire once" do
    it "Map01" do
      content = GameContent.create_dummy(WadPath::DOOM2)

      options = GameOptions.new
      options.skill = GameSkill::Hard
      options.map = 1
      options.players[0].in_game = true

      cmds = Array.new(Player::MAX_PLAYER_COUNT, TicCmd.new)
      game = DoomGame.new(content, options)
      game.defered_init_new

      tics = 700
      press_fire_until = 20

      agg_hash = 0
      i = 1
      tics.times do |i|
        if i < press_fire_until
          cmds[0].buttons = TicCmdButtons.attack
        else
          cmds[0].buttons = 0
        end

        game.update(cmds)
        agg_hash = DoomDebug.combine_hash(agg_hash, DoomDebug.get_mobj_hash(game.world.as(World)))
      end

      DoomDebug.get_mobj_hash(game.world.as(World)).to_u32!.should eq 0xef1aa1d8_u32
      agg_hash.to_u32!.should eq 0xe6edcf39_u32
    end
  end
end
