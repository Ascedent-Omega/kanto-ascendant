return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util')
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=assert(game.mods.exports.kanto_ascendant);local S=assert(K.seviiExpedition)
  game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  assert(K.beyondKanto.activate(game,{decision='qa-expanded-postleague-fixture'}))
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',70)}
  local visited=0
  for island=1,7 do
    U.teleport(game,S.harbors[island],8,5,'right');Q.settle()
    -- Actual NPC talk, not a direct call to the guide's menu builder.
    Q.tap('a');U.wait(20)
    assert(game.stack:top().items and #game.stack:top().items==7,'harbor guide opens island list')
    Q.choose(function(item)return item.value==island end);U.wait(15)
    local speciesMenu=game.stack:top()
    local expected=S.guide.entries(game,island)
    assert(speciesMenu.items and #speciesMenu.items==#expected,'live guide catalogue')
    visited=visited+#expected
    if island==3 then
      Q.choose(function(item)return item.id=='TURTWIG'end);U.wait(30)
      local text=game.stack:top();assert(text.pages,'description opens native text box')
      assert(U.shot(game,out..'/guide-turtwig.png'))
      for i=1,1800 do if game.stack:top()==speciesMenu then break end;Q.tap('a')end
      assert(game.stack:top()==speciesMenu,'description returns to species selection')
      assert(speciesMenu.items[speciesMenu.index].id=='TURTWIG','selected species retained')
    end
    Q.tap('b');U.wait(10);assert(#game.stack:top().items==7,'cancel to island list')
    Q.tap('b');Q.settle();assert(game.stack:top()==game.overworld,'cancel releases NPC conversation')
    assert(game.overworld.player.cellX==8 and game.overworld.player.cellY==5,'guide never warps player')
  end
  assert(visited==218,'all ordinary targets discoverable')
  print('SEVII_NATIVE_GUIDE_PASS',visited,'species; seven harbor interactions')
  love.event.quit()
end
