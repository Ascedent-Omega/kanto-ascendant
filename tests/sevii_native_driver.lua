-- Isolated profile only. Exercises real dialogue, walking, Surf, save reload
-- and ferry scripts. Teleports below are explicit test setup between sites.
return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'))
  local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util')
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  Q.shot=function(name)assert(U.shot(game,out..'/'..name..'.png'))end
  local K=assert(game.mods.exports.kanto_ascendant,'KASC load failed')
  local S=assert(K.seviiExpedition,'Sevii module missing')
  assert(S.available,'Sevii import missing')
  local OW=require('src.world.OverworldController')
  local nativeRoll=OW.rollEncounter;OW.rollEncounter=function()return nil end
  game:startNewGame{intro=false}
  game.save.options.colors='redpp'
  game:applyOptions()
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true
  game.save.flags.EVENT_GOT_STARTER=true
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  assert(K.beyondKanto.activate(game,{decision='qa-expanded-postleague-fixture'}))
  local Pokemon=require('src.pokemon.Pokemon')
  local mon=Pokemon.new(game.data,'BLASTOISE',65)
  mon.moves={{id='SURF',pp=15},{id='TACKLE',pp=35}}
  game.save.party={mon,Pokemon.new(game.data,'NUMEL',50)}
  game.save.inventory.SOULBADGE=true
  game.save.inventory.HOENN_HONEY=1;game.save.inventory.HOENN_DEX=1
  K.generationRules.resolve(game)
  S.install(game)
  assert(S.assetsReady('WINGULL'),'verified optional Wingull art required for capture QA')
  U.teleport(game,'VERMILION_CITY',27,26,'right');Q.settle()
  Q.shot('01-orania-ferry');Q.tap('a');Q.settle()
  assert(game.overworld.map.id==S.PORT,'ferry dialogue did not sail')
  Q.shot('02-island-harbor')
  Q.walkTo(8,2,S.ONE);Q.settle()
  assert(game.overworld.map.id==S.ONE,'harbor exit')
  Q.walkTo(16,13);U.hold(game,'up',1);Q.tap('a');Q.settle()
  assert(S.state().stage==1,'story introduction')
  Q.shot('03-one-island')
  Q.walkTo(14,5,S.CENTER);Q.settle()
  assert(game.overworld.map.id==S.CENTER,'center doorway')
  Q.shot('04-island-center')
  Q.walkTo(9,9,S.ONE);Q.settle()
  assert(game.overworld.map.id==S.ONE,'center return')
  for _,id in ipairs{'heat','drift'}do
    local p=S.samples[id]
    U.teleport(game,p.map,p.x,p.y-1,'down');Q.settle()
    Q.shot('05-buoy-'..id)
    Q.tap('a');Q.settle();assert(S.state().samples[id],'buoy interaction '..id)
    assert(game:writeSave(),'save on island')
    local loaded=assert(require('src.core.SaveData').load('red'))
    game:restoreSave(loaded);Q.settle()
    assert(S.state().samples[id],'sample persisted across actual save reload')
  end
  assert(S.state().stage==2,'both measurements recorded')
  U.teleport(game,S.ONE,16,13,'up');Q.settle();Q.tap('a');Q.settle()
  assert(S.state().chapterOneComplete,'chapter conclusion')
  Q.shot('06-chapter-complete')
  -- Real SURF start and movement on an imported tileset, using native field UI.
  U.teleport(game,'KA_SEVII_KINDLE',3,61,'right');Q.settle()
  assert(game.overworld:tilesetHasWater(),'imported tileset supports Surf')
  Q.field('SURF');Q.settle()
  assert(game.overworld.player.surfing,'Surf on GBA water')
  Q.walkTo(6,62);Q.shot('07-surf')
  -- Native battle/capture path, with an explicit fixture encounter so the
  -- end-to-end test is deterministic rather than waiting for an RNG roll.
  U.teleport(game,'KA_SEVII_TREASURE',10,22,'down');Q.settle()
  local battle=require('src.battle.BattleState').newWild(game,'WINGULL',48,
    {encounterSource='sevii-expedition',randomizerProtected=true})
  battle.onFinish=function(result)game.overworld:afterBattle(result,battle)end
  game.overworld:pushBattle(battle)
  game.save.inventory.MASTER_BALL=2
  for i=1,1800 do
    if game.stack:top()==battle and battle.phase=='menu'then break end
    Q.tap('a')
  end
  assert(battle.phase=='menu','native battle menu')
  Q.shot('09-wingull-battle')
  Q.tap('down');assert(battle.menuIndex==3,'native 2x2 item navigation');Q.tap('a');U.wait(30)
  local found=false
  for pocket=1,8 do
    for _,item in ipairs(game.stack:top().items or{})do if item.value=='MASTER_BALL'then found=true end end
    if found then Q.choose(function(item)return item.value=='MASTER_BALL'end);break end
    Q.tap('right')
  end
  assert(found,'Master Ball fixture missing');U.wait(10)
  if game.stack:top().items then Q.choose(function(item)return item.value=='use'or item.label=='USE'end)end
  local finished=false
  for i=1,3000 do
    local top=game.stack:top()
    if top==game.overworld then finished=true;break
    elseif top.def and top.def.id=='WINGULL'and not top.enemy then Q.tap('b')
    elseif top.labels and top.onChoose then
      -- Confirm the rare-item protection before the ball is consumed;
      -- decline the nickname after the capture.
      local wanted=(game.save.inventory.MASTER_BALL or 0)==2 and 1 or 2
      if top.pending~=nil then U.wait(1)elseif top.index~=wanted then Q.tap('down')else Q.tap('a')end
    else Q.tap('a')end
  end
  assert(finished,'native capture did not finish');Q.settle()
  assert(game.save.pokedex.owned.WINGULL,'Sevii capture reaches native Pokedex')
  for island=2,7 do
    local current=game.overworld.map.def and game.overworld.map.def.kaSeviiIsland or 1
    U.teleport(game,S.harbors[current],8,4,'left');Q.settle();Q.tap('a');U.wait(8)
    Q.choose(function(item)return item.value==island end);Q.settle()
    assert(game.overworld.map.id==S.harbors[island],'ferry to island '..island)
    local exit=assert(S.links[S.harbors[island]][1])
    Q.walkTo(exit.x,exit.y,exit.map);Q.settle()
    assert(game.overworld.map.id==exit.map,'harbor exit on island '..island)
    Q.shot('island-'..island..'-arrival')
  end
  local ice=assert(S.location('FourIsland_IcefallCave_1F',11,13))
  U.teleport(game,ice,11,13,'left');Q.settle()
  U.hold(game,'left',18);U.wait(35)
  assert(game.overworld.player.cellX==9,'native imported directional ledge')
  U.teleport(game,ice,8,15,'up');Q.settle();Q.walkTo(8,14)
  assert(S.state().iceVisit.cracks['8,14'],'thin ice cracks on first crossing')
  Q.walkTo(8,15)
  local below=assert(S.location('FourIsland_IcefallCave_B1F',8,14))
  Q.walkTo(8,14,below);Q.settle()
  assert(game.overworld.map.id==below,'thin ice falls on second crossing')
  Q.shot('icefall-landing')
  U.teleport(game,S.PORT,8,4,'left');Q.settle();Q.tap('a');U.wait(8)
  Q.choose(function(item)return item.value==0 end);Q.settle()
  assert(game.overworld.map.id=='VERMILION_CITY','ferry return')
  assert(S.state().chapterOneComplete,'return retains story')
  Q.shot('08-orania-return')
  OW.rollEncounter=nativeRoll
  print('SEVII_NATIVE_SEVEN_FERRIES_STORY_SAVE_SURF_CAPTURE_ICE_PASS')
  love.event.quit()
end
