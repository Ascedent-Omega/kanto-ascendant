-- Focused GS Ball reward and Professor Oak handoff in the native client.
return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'))
  local U=require('tests.drivers.util')
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=assert(game.mods.exports.kanto_ascendant)
  local S=assert(K.seviiExpedition)
  local P=assert(S.chapters.finale)
  game:startNewGame{intro=false}
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true
  game.save.flags.EVENT_GOT_STARTER=true
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',70)}
  S.persist({version=1,stage=3,samples={heat=true,drift=true},
    chapterOneComplete=true,chapterTwoComplete=true,chapterThreeComplete=true,
    chapterFourComplete=true,chapterFiveComplete=true,chapterSixComplete=true,
    seviiRiftSealed=true,chapters={seven={briefed=true,calibrated=true,
      relays={WEST=true,MIDDLE=true,EAST=true},sealed=true}}})
  U.teleport(game,P.sites.CAMP.map,4,6,'up');Q.settle()
  Q.faceObject(P.sites.CAMP.x,P.sites.CAMP.y);Q.tap('a');Q.settle()
  assert(S.state().expeditionComplete and game.save.inventory.GS_BALL==1,
    'the native finale gives the GS Ball once')
  assert(game:writeSave())
  game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  assert(game.save.inventory.GS_BALL==1,'GS Ball persists')
  -- This isolated post-League fixture skipped Kanto's Oak-lab story toggles.
  game.save.objectToggles.OAKS_LAB=game.save.objectToggles.OAKS_LAB or{}
  game.save.objectToggles.OAKS_LAB.OAKSLAB_OAK1=true
  U.teleport(game,'OAKS_LAB',5,3,'up');Q.settle()
  local oakVisible=false
  for _,npc in ipairs(game.overworld.npcs or{})do
    if npc.def and npc.def.name=='OAKSLAB_OAK1'then oakVisible=true end
  end
  assert(oakVisible,'Professor Oak is reachable in the lab')
  Q.faceObject(5,2);Q.tap('a');U.wait(8)
  local speech=game.stack:top();local lines={}
  for _,page in ipairs(speech.pages or{})do lines[#lines+1]=table.concat(page,' ')end
  local dialogue=table.concat(lines,' '):gsub('%s+',' ')
  assert(dialogue:upper():find('IVY',1,true),
    'Oak names Professor Ivy in the actual dialogue')
  if os.getenv('SEVII_EXPECT_GERMAN')=='1' then
    assert(dialogue:find('EICH',1,true)
      and dialogue:find('Freundin',1,true)
      and dialogue:find('Komm später',1,true),
      'German Oak dialogue names Ivy and asks for a later return')
  else
    assert(dialogue:find('Come back with the ball later',1,true),
      'English Oak dialogue asks for a later return with the GS Ball')
  end
  Q.settle()
  assert(S.state().chapters.seven.gsBallOakConsulted
    and S.state().orangeIslandsLead=='IVY_GS_BALL'
    and game.save.inventory.GS_BALL==1,
    'Professor Oak discusses the GS Ball and leaves it with the trainer')
  assert(game:writeSave())
  game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  assert(S.state().chapters.seven.gsBallOakConsulted
    and game.save.inventory.GS_BALL==1,'Oak consultation and ball persist')
  print('SEVII_NATIVE_GS_BALL_PASS')
  love.event.quit()
end
