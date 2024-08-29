module Doocr::Test
  describe Demo, tags: "demo" do
    it "Doom2" do
      content = GameContent.create_dummy(WadPath::DOOM2)

      demo = Demo.new(content.wad.as(Wad).read_lump("DEMO1"))
      options = demo.options.as(GameOptions)
      options.map.should eq 11
      options.console_player.should eq 0
      options.players[0].in_game.should be_true
      options.players[1].in_game.should be_false
      options.players[2].in_game.should be_false
      options.players[3].in_game.should be_false

      demo = Demo.new(content.wad.as(Wad).read_lump("DEMO2"))
      options = demo.options.as(GameOptions)
      options.map.should eq 5
      options.console_player.should eq 0
      options.players[0].in_game.should be_true
      options.players[1].in_game.should be_false
      options.players[2].in_game.should be_false
      options.players[3].in_game.should be_false

      demo = Demo.new(content.wad.as(Wad).read_lump("DEMO3"))
      options = demo.options.as(GameOptions)
      options.map.should eq 26
      options.console_player.should eq 0
      options.players[0].in_game.should be_true
      options.players[1].in_game.should be_false
      options.players[2].in_game.should be_false
      options.players[3].in_game.should be_false
    end
  end
end
