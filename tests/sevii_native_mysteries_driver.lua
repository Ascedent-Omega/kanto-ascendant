-- The level-100 team fixture yields level-100 legends under the current authored scaling policy.
return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition;local M=S.mysteries;local P=S.legendPolicy
  local N=dofile(root..'/tests/sevii_journey_navigation.lua')(game,S,Q)
  require('src.world.OverworldController').rollEncounter=function()return nil end
  game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
  game.mods.modOptions.kanto_ascendant.living_world_enabled=false
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  local mon=require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',100)
  mon.moves={{id='SURF',pp=15},{id='STRENGTH',pp=15},{id='ICE_BEAM',pp=10}}
  game.save.party={mon};game.save.inventory.SOULBADGE=true;game.save.inventory.RAINBOWBADGE=true
  assert(K.beyondKanto.activate(game,{decision='qa-post-expedition-mystery-fixture'}))
  Q.extraWarpAt=function(m,x,y)for _,w in ipairs(S.links[m.id]or{})do if w.x==x and w.y==y then return true end end;return false end
  U.teleport(game,S.harbors[1],8,5,'down');Q.settle()
  N.talk(M.sites.RESEARCHER);Q.settle()
  assert(not M.record().briefed,'actual researcher refuses unfinished expedition')
  local state=S.state();state.stage=3;state.chapterOneComplete=true;state.samples={heat=true,drift=true}
  state.expeditionComplete=true;state.seviiRiftSealed=true;S.persist(state);K.generationRules.resolve(game)
  local available,reason=M.availability(game)
  if not available then
    local sp=K.backendGiftSpecies67.byKey['dex:485']
    for _,path in ipairs(S.habitats.assetPaths(sp,game.data.pokemon[sp]))do
      local found=love.filesystem.getInfo('mods/kanto_ascendant/'..path)
      print('HEATRAN_ASSET_PROBE',path,tostring(found~=nil))
    end
  end
  assert(available,'native post-expedition availability: '..tostring(reason))
  N.talk(M.sites.RESEARCHER);Q.settle();assert(M.record().briefed)
  for _,id in ipairs{'UPPER','MIDDLE','LOWER'}do
    N.talk(M.sites[id]);Q.settle();assert(M.record().readings[id],'real survey reading '..id)
    assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
    assert(M.record().readings[id],'reading reload '..id)
  end
  local function choose(id)
    for _=1,1800 do
      if game.stack:top().items then
        local panel=game.stack:top();local wanted
        for i,row in ipairs(panel.items)do if row.value==id then wanted=i end end
        assert(wanted,'missing mystery choice '..id)
        for _=1,60 do
          if panel.index==wanted then Q.tap('a');return end
          Q.tap(panel.index>wanted and'up'or'down')
        end
        error('mystery choice stuck '..id)
      end
      assert(game.stack:top()~=game.overworld,'mystery menu unexpectedly closed');Q.tap('a')
    end
    error('mystery menu missing')
  end
  N.talk(M.sites.VENT);choose('UPPER');choose('LEAVE');Q.settle()
  assert(M.record().tuned==0 and not M.record().open,'incorrect valve order resets safely')
  N.talk(M.sites.VENT);choose('MIDDLE');choose('LEAVE');Q.settle()
  assert(M.record().tuned==1);assert(game:writeSave())
  game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle();assert(M.record().tuned==1)
  N.talk(M.sites.VENT);choose('UPPER');choose('LOWER');choose('LEAVE');Q.settle()
  assert(M.record().open,'real valve menu opens Heatran encounter')
  assert(U.shot(game,out..'/heatran-valve-chamber.png'))
  local normalWrite=game.writeSave;game.writeSave=function()return false end
  local ok,why=M.start(game);assert(not ok and why=='save-failed'and game.stack:top()==game.overworld)
  game.writeSave=normalWrite
  local function start()
    N.talk(M.sites.VENT);choose('BATTLE')
    for _=1,1800 do
      local b=game.stack:top()
      if b.enemy and b.phase=='menu'then
        assert(P.captureAllowed(game,b.enemy.mon.species,b),'authored live battle permitted')
        assert(not P.captureAllowed(game,b.enemy.mon.species),'map/species alone insufficient')
        return b
      end
      Q.tap('a')
    end
    error('authored native battle did not start')
  end
  local b=start();local species=assert(K.backendGiftSpecies67.byKey['dex:485'])
  assert(b.enemy.mon.species==species and b.enemy.mon.level==100)
  for _,move in ipairs(b.enemy.mon.moves)do
    assert(game.data.moves[move.id]and not tostring(game.data.moves[move.id].effect):find('UNSUPPORTED',1,true),'supported Heatran moves')
  end
  local safe,reason=require('src.battle.BattleSafety').inspect(game,b)
  assert(not safe and reason=='battle_origin_unsupported','custom completion cannot become an unsafe checkpoint')
  local counterfeit=require('src.battle.BattleState').newWild(game,species,70,{randomizerProtected=true})
  assert(not P.captureAllowed(game,species,counterfeit),'unowned copy of same species not authorized')
  b.rng=function(lo)return lo end
  assert(b:chooseMenu('run'),'native RUN action');U.wait(1) -- Public native controller action; independent of HUD navigation layout.
  for _=1,1800 do if game.stack:top()==game.overworld then break end;Q.tap('a')end
  Q.settle();assert(not P.history.owned(game,species)and not M.record().caught,'native flee preserves retry')
  print('SEVII_MYSTERY_WALK_PUZZLE_FLEE_PASS',N.steps,N.seams,N.doors)
  b=start()
  game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  assert(not M.canCapture(game,b,species)and not M.record().caught,'abandoned battle loses capability after reload')
  b=start();Q.catch(species,true,'down');Q.settle()
  assert(M.record().caught and P.history.owned(game,species),'native catch records local and lineage receipt')
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  local count=0
  for _,list in ipairs({game.save.party,unpack(game.save.boxes)})do
    for _,m in ipairs(list)do if m.species==species then count=count+1 end end
  end
  assert(count==1 and M.record().caught,'exactly one Heatran survives reload')
  N.talk(M.sites.VENT);Q.settle();ok,why=M.start(game);assert(not ok and why=='legend_owned')
  N.visit(M.sites.RESEARCHER);N.sail(0)
  assert(game.overworld.map.id=='VERMILION_CITY','physical return through cave and native ferry')
  local f=assert(io.open(out..'/heatran-mystery.json','wb'))
  f:write(require('src.link.Json').encode({passed=true,steps=N.steps,seams=N.seams,doors=N.doors,
    readings=3,partialPuzzleReload=true,nativeFlee=true,abandonedBattleReload=true,
    nativeCapture=true,onceOnlyAfterReload=true,returnMap=game.overworld.map.id,
    scope='Isolated QA. Real walking from island-one harbor through Mt Ember, three survey NPCs, valve menu, flee, catch, save/load, walk back and ferry. Initial champion/finale/team/badges/harbor position, disabled ordinary spawns, Master Balls and flee RNG are fixtures; not a balance proof.'}));f:close()
  print('SEVII_NATIVE_HEATRAN_MYSTERY_PASS',N.steps,N.seams,N.doors);love.event.quit()
end
