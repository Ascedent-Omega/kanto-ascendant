-- The level-100 team fixture yields level-100 legends under the current authored scaling policy.
return function(game)
 io.stdout:setvbuf('no')
 local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
 local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
 Q.shot=function(name)assert(U.shot(game,out..'/regi-return-'..name..'.png'))end
 local settle=Q.settle
 Q.settle=function()
  local ok,why=pcall(settle)
  if not ok then
   U.shot(game,out..'/regi-return-stuck.png')
   for i,screen in ipairs(game.stack.states)do
    print('GIANT_STUCK_SCREEN',i)
    for k,v in pairs(screen)do if type(v)=='string'or type(v)=='number'or type(v)=='boolean'then print(k,v)end end
   end
   error(why)
  end
 end
 local rawUpdate=game.update
 game.update=function(self,dt)return require('src.mods.Runtime').call('core.update',rawUpdate,self,dt)end
 local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition;local G,E,P=S.sleepingGiant,S.specialEncounters,S.legendPolicy
 local N=dofile(root..'/tests/sevii_journey_navigation.lua')(game,S,Q)
 require('src.world.OverworldController').rollEncounter=function()return nil end
 game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
 game.mods.modOptions.kanto_ascendant.living_world_enabled=false
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
 local mon=require('src.pokemon.Pokemon').new(game.data,'DRAGONITE',100)
 mon.moves={{id='SURF',pp=15},{id='STRENGTH',pp=15},{id='ICE_BEAM',pp=10},{id='FLY',pp=15}}
 game.save.party={mon};game.save.inventory.SOULBADGE=true;game.save.inventory.RAINBOWBADGE=true;game.save.inventory.THUNDERBADGE=true
 assert(K.beyondKanto.activate(game,{decision='qa-sleeping-giant-aftermath'}))
 Q.extraWarpAt=function(m,x,y)for _,w in ipairs(S.links[m.id]or{})do if w.x==x and w.y==y then return true end end;return false end
 U.teleport(game,S.harbors[7],8,5,'down');Q.settle()
 N.talk(G.sites.RHEA);Q.settle();assert(not G.record().briefed,'actual researcher rejects incomplete expedition')
 local s=S.state();s.stage=3;s.chapterOneComplete=true;s.samples={heat=true,drift=true}
 s.expeditionComplete=true;s.seviiRiftSealed=true;S.persist(s);K.generationRules.resolve(game)
 local function checkpoint()
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
 end
 local function choose(id)
  for _=1,1800 do
   local panel=game.stack:top()
   if panel.items then
    local wanted;for i,row in ipairs(panel.items)do if row.value==id then wanted=i end end
    assert(wanted,'missing giant choice '..id)
    for _=1,60 do if panel.index==wanted then Q.tap('a');return end;Q.tap(panel.index>wanted and'up'or'down')end
    error('giant choice stuck')
   end
   assert(panel~=game.overworld,'giant menu closed');Q.tap('a')
  end
  error('giant menu not reached')
 end
 -- The new authored owner retires the old lead even before its research is
 -- completed. A historical pending raid may finish without inventing a catch.
 local R=K.rocketRecoveryRaids67;local raid=R.status();raid.status='capture';raid.instance=4
 raid.pendingCaptures={K.rocketRecoveryRaids67Data.contraband[3]};raid.captureIndex=1
 game.save.modData.kanto_ascendant[R.stateKey]=raid
 assert(R.reconcileCaptures(game));assert(R.status().status=='complete'and not P.history.owned(game,'REGIGIGAS'))
 local permitted,reason=P.raidCaptureAllowed(game,K.rocketRecoveryRaids67Data.contraband[3])
 assert(not permitted and reason=='sevii_relocated','old Rocket owner retired')
 N.talk(G.sites.RHEA);Q.settle();assert(G.record().briefed)
 N.talk(G.sites.BALANCE);choose('check');choose('leave');Q.settle()
 assert(not G.record().balanced,'inscriptions required by actual controls')
 for _,id in ipairs{'ROCK','ICE','STEEL'}do N.talk(G.sites[id]);Q.settle();assert(G.record().clues[id])end
 checkpoint();assert(G.record().clues.ROCK and G.record().clues.ICE and G.record().clues.STEEL)
 N.talk(G.sites.BALANCE);choose('check');choose('move3');choose('reset');choose('leave');Q.settle()
 assert(not G.record().balanced and G.weights()[1]==4 and G.weights()[2]==4 and G.weights()[3]==2,'wrong balance and explicit reset')
 N.talk(G.sites.BALANCE);choose('move1');choose('leave');Q.settle();checkpoint()
 assert(G.weights()[1]==5 and G.weights()[2]==3 and G.weights()[3]==2,'actual partial arrangement saved')
 N.talk(G.sites.BALANCE);assert(U.shot(game,out..'/regi-return-counterweights-menu.png'))
 choose('move2');choose('check');Q.settle();assert(G.record().balanced)
 local available,why=E.availability(game,'REGIGIGAS');assert(not available and why=='trial-required','report remains necessary')
 N.talk(G.sites.RHEA);Q.settle();checkpoint()
 assert(G.record().complete and G.record().title=='SEVII_SLEEPING_GIANT','research completes without any legendary owned')
 assert(S.chapters.journal():find('THE SLEEPING GIANT COMPLETE',1,true))
 -- Current authored policy keeps the old Hoenn sites closed. Research
 -- access remains necessary, but their retired puzzles are not prerequisites.
 for _,id in ipairs{'REGIROCK','REGICE','REGISTEEL'}do
  local ok,why=E.availability(game,id);assert(not ok and why=='sanctuary-access-required','Hoenn research gate '..id)
 end
 N.sail(0);assert(game.overworld.map.id=='VERMILION_CITY')
 local sanctums=K.hoennResearchSanctums67;local events=K.hoennEndgameRunEvents67
 game.save.inventory.HOENN_DEX=1;game.save.flags.EVENT_GOT_POKEDEX=true;game.save.hallOfFame={{}}
 assert(sanctums.researchEligible(game)and not sanctums.available(game),'research accessible; retired sanctums closed')
 for _,row in ipairs(sanctums.rows)do assert(not sanctums.enter(game,row),'retired sanctuary cannot reopen')end
 checkpoint()
 U.teleport(game,'VERMILION_CITY',27,26,'right');Q.settle()
 Q.tap('a');Q.settle();assert(game.overworld.map.id==S.PORT,'native return ferry to Sevii');N.sails=N.sails+1
 N.sail(7)
 local captures={}
 assert(K.generationRules.switchMode(game,'gen3'));Q.settle()
 for _,id in ipairs{'REGIROCK','REGICE','REGISTEEL'}do assert(E.availability(game,id),'Gen3 guardian '..id)end
 local permitted,reason=E.availability(game,'REGIGIGAS');assert(not permitted and reason=='generation-profile','Gen3 does not expose Regigigas')
 assert(K.generationRules.switchMode(game,'gen2'));Q.settle()
 for _,id in ipairs{'REGIROCK','REGICE','REGISTEEL'}do local ok,why=E.availability(game,id);assert(not ok and why=='generation-profile','Gen2 cannot expose guardian')end
 assert(K.generationRules.switchMode(game,'gen4'));Q.settle()
 local function count(id)
  local n=0;for _,list in ipairs({game.save.party,unpack(game.save.boxes)})do for _,m in ipairs(list)do if m.species==id then n=n+1 end end end;return n
 end
 for _,id in ipairs{'REGIROCK','REGICE','REGISTEEL','REGIGIGAS'}do
  local site=G.guardians[id]or id
  N.talk(G.sites[site]);choose('battle');local b
  for _=1,1800 do local top=game.stack:top();if top.enemy and top.phase=='menu'then b=top;break end;Q.tap('a')end
  assert(b and b.enemy.mon.species==id and b.enemy.mon.level==100,'canonical guardian/level '..id)
  assert(P.captureAllowed(game,id,b)and not P.captureAllowed(game,id),'exact authored encounter only')
  if G.guardians[id]then
   game.mods.modOptions.kanto_ascendant.hoenn_regi_sanctums=false
   assert(not P.captureAllowed(game,id,b),'original access is rechecked during capture')
   game.mods.modOptions.kanto_ascendant.hoenn_regi_sanctums=true
  end
  for _,mv in ipairs(b.enemy.mon.moves)do assert(game.data.moves[mv.id]and not tostring(game.data.moves[mv.id].effect):find('UNSUPPORTED',1,true),'supported guardian move '..mv.id)end
  Q.catch(id,true,'down');Q.settle();checkpoint()
  assert(count(id)==1 and P.history.owned(game,id)and S.state().specialCaptures[id],'one saved '..id)
  N.talk(G.sites[site]);Q.settle();local ok,why=E.start(game,id);assert(not ok and why=='legend_owned')
  local allowed,why=P.acquisitionAllowed(game,{backendKey='dex:'..E.rows[id].dex});assert(not allowed and why=='legend_owned')
  captures[#captures+1]={species=id,level=b.enemy.mon.level,count=count(id)}
  print('SEVII_REGI_RETURN_CAPTURE_PASS',id)
 end
 N.talk(G.sites.BALANCE);Q.settle();assert(G.record().balanced,'completed mechanism cannot be reset')
 N.sail(0);assert(game.overworld.map.id=='VERMILION_CITY')
 -- No duplicate acquisition is available through the retired owner.
 assert(not sanctums.available(game))
 for _,row in ipairs(sanctums.rows)do
  assert(not sanctums.enter(game,row),'old owner remains closed after Tanoby catch')
  assert(count(row.species)==1,'single ownership retained '..row.species)
 end
 local L=K.legacyJourney.archive
 local archive,err=L.beginJourney(game.save,{pact='journey',bankPolicy='sealed',itemPolicy='empty',
  runRules=L.safeRunRulesSnapshot(game.save),playerAvatar='BLUE'})
 assert(archive,tostring(err));local fresh={party={},boxes={},flags={},modData={}}
 assert(L.seedNewSave(fresh))
 for _,dex in ipairs{377,378,379,486}do assert(fresh.modData.kanto_ascendant.hevo_persistent.seviiLegendOwned[tostring(dex)],'real Legacy transfer '..dex)end
 events.reset(fresh);assert(not events.completed(fresh,'REGIROCK')and fresh.modData.kanto_ascendant.hevo_persistent.seviiLegendOwned['377'])
 local f=assert(io.open(out..'/regi-return.json','wb'))
 f:write(require('src.link.Json').encode({passed=true,steps=N.steps,seams=N.seams,doors=N.doors,ferries=N.sails,
  captures=captures,retiredSanctumsClosed=true,questComplete=true,actualLegacyTransaction=true,
  scope='Isolated QA: native Tanoby counterweights quest, partial/wrong/reset/save controls, Hoenn research refusal and unlock, retired shrine entry refusal, Gen2/Gen3/Gen4 gates, all four native captures/reload, single ownership, ferries to/from Orania and actual Legacy transaction. Champion/finale/team/badges, initial harbor, Hoenn Dex, disabled ordinary encounters and Master Balls are fixtures. No old retired puzzles are required by the current authored policy; this does not certify the former policy or battle balance.'}));f:close()
 print('SEVII_NATIVE_REGI_RETURN_PASS',N.steps,N.seams,N.doors,N.sails);love.event.quit()
end
