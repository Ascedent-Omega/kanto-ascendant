-- The level-100 team fixture yields level-100 legends under the current authored scaling policy.
return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  Q.shot=function(name)assert(U.shot(game,out..'/guardians-'..name..'.png'))end
  local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition
  local G,E,P=S.lakeGuardians,S.specialEncounters,S.legendPolicy
  local N=dofile(root..'/tests/sevii_journey_navigation.lua')(game,S,Q)
  require('src.world.OverworldController').rollEncounter=function()return nil end
  game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
  game.mods.modOptions.kanto_ascendant.living_world_enabled=false
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  local mon=require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',100)
  mon.moves={{id='SURF',pp=15},{id='STRENGTH',pp=15},{id='ICE_BEAM',pp=10}}
  game.save.party={mon};game.save.inventory.SOULBADGE=true;game.save.inventory.RAINBOWBADGE=true
  assert(K.beyondKanto.activate(game,{decision='qa-guardian-aftermath-fixture'}))
  Q.extraWarpAt=function(m,x,y)for _,w in ipairs(S.links[m.id]or{})do if w.x==x and w.y==y then return true end end;return false end
  U.teleport(game,S.harbors[4],8,5,'down');Q.settle()
  N.talk(G.sites.ARCHIVIST);Q.settle();assert(not G.record().briefed,'unfinished expedition refused by actual NPC')
  local state=S.state();state.stage=3;state.chapterOneComplete=true;state.samples={heat=true,drift=true}
  state.expeditionComplete=true;state.seviiRiftSealed=true;S.persist(state);K.generationRules.resolve(game)
  N.talk(G.sites.ARCHIVIST);Q.settle();assert(G.record().briefed)
  local function menu()
    for _=1,1800 do
      local t=game.stack:top();if t.items then return t end
      assert(t~=game.overworld,'guardian menu unexpectedly closed');Q.tap('a')
    end
    error('guardian menu missing')
  end
  local function choose(id)
    local panel=menu();local wanted
    for i,row in ipairs(panel.items)do if row.value==id then wanted=i end end
    assert(wanted,'missing guardian choice '..id)
    for _=1,60 do if panel.index==wanted then Q.tap('a');return end;Q.tap(panel.index>wanted and'up'or'down')end
    error('guardian choice stuck '..id)
  end
  local function checkpoint()
    assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  end
  local captures={}
  local function catch(id)
    N.talk(G.sites[id]);choose('battle');local battle
    for _=1,1800 do
      local b=game.stack:top();if b.enemy and b.phase=='menu'then battle=b;break end;Q.tap('a')
    end
    assert(battle,'guardian battle started '..id)
    local species=assert(K.backendGiftSpecies67.byKey['dex:'..E.rows[id].dex])
    assert(battle.enemy.mon.species==species and battle.enemy.mon.level==100,'canonical guardian and level')
    assert(P.captureAllowed(game,species,battle)and not P.captureAllowed(game,species),'only live authored battle')
    local other=require('src.battle.BattleState').newWild(game,species,65,{randomizerProtected=true})
    assert(not P.captureAllowed(game,species,other),'unregistered same-species battle denied')
    local safe,reason=require('src.battle.BattleSafety').inspect(game,battle)
    assert(not safe and reason=='battle_origin_unsupported','checkpoint guard')
    for _,mv in ipairs(battle.enemy.mon.moves)do
      assert(game.data.moves[mv.id]and not tostring(game.data.moves[mv.id].effect):find('UNSUPPORTED',1,true),'supported guardian move '..mv.id)
    end
    Q.catch(species,true,'down');Q.settle();checkpoint()
    assert(P.history.owned(game,species)and S.state().specialCaptures[id],'capture and lineage receipts after load')
    local count=0
    for _,list in ipairs({game.save.party,unpack(game.save.boxes)})do for _,m in ipairs(list)do if m.species==species then count=count+1 end end end
    assert(count==1,'exactly one guardian stored '..id)
    N.talk(G.sites[id]);Q.settle()
    local ok,why=E.start(game,id);assert(not ok and why=='legend_owned','repeat source blocked '..id)
    captures[#captures+1]={id=id,species=species,count=count};print('SEVII_GUARDIAN_CAPTURE_RELOAD_PASS',id)
  end
  N.sail(2);N.talk(G.sites.UXIE);choose('BIRD');Q.settle()
  assert(G.record().answers==0 and not G.record().knowledge,'wrong memory answer resets')
  N.talk(G.sites.UXIE);menu();assert(U.shot(game,out..'/guardian-knowledge-menu.png'))
  choose('CURRENT');choose('leave');Q.settle();checkpoint();assert(G.record().answers==1,'partial knowledge survives load')
  N.talk(G.sites.UXIE);choose('GIRATINA');choose('CROSSING');Q.settle()
  assert(G.record().knowledge);catch('UXIE')
  N.sail(5);N.talk(G.sites.MILA);Q.settle();assert(G.record().requested)
  N.talk(G.sites.KEEPSAKE);Q.settle();checkpoint();assert(G.record().keepsake,'real recovered keepsake survives load')
  N.talk(G.sites.MILA);Q.settle();assert(G.record().compassion and not G.record().keepsake)
  catch('MESPRIT')
  N.sail(7);N.talk(G.sites.AZELF);Q.settle();assert(not G.record().resolve,'tower requirement enforced by actual NPC')
  -- Eight victories were proven separately in tower-native2. This driver
  -- fixtures only those earned wins, then performs the actual roof ceremony.
  state=S.state();state.trainers=state.trainers or{}
  for i=1,8 do state.trainers['TOWER_'..i]={won=true,claimed=true}end
  S.persist(state)
  N.talk(S.tower.roof);Q.settle();assert(S.state().towerComplete,'actual tower title ceremony')
  N.talk(G.sites.AZELF);Q.settle();assert(G.record().resolve);catch('AZELF')
  N.sail(4);N.talk(G.sites.ARCHIVIST);Q.settle();checkpoint()
  assert(G.record().complete and G.record().title=='SEVII_THREE_VOICES','actual research report recorded')
  assert(S.chapters.journal():find('THREE VOICES COMPLETE',1,true),'combined journal includes completion')
  N.sail(0);assert(game.overworld.map.id=='VERMILION_CITY')
  local f=assert(io.open(out..'/lake-guardians.json','wb'))
  f:write(require('src.link.Json').encode({passed=true,steps=N.steps,seams=N.seams,doors=N.doors,ferries=N.sails,
    captures=captures,partialMemoryReload=true,keepsakeReload=true,actualTowerCeremony=true,researchComplete=true,
    scope='Isolated QA: physical routes between island harbors, all quest actors, quiz/keepsake delivery, roof ceremony, three actual catches and reloads, report and return to Orania. Initial champion/finale/team/badges/harbor position, disabled ordinary spawns, eight pre-earned tower wins and Master Balls are fixtures; not a balance proof or repeat of eight tower battles.'}));f:close()
  print('SEVII_NATIVE_LAKE_GUARDIANS_PASS',#captures,N.steps,N.seams,N.doors,N.sails);love.event.quit()
end
