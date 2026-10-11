-- The level-100 team fixture yields level-100 legends under the current authored scaling policy.
return function(game)
 io.stdout:setvbuf('no')
 local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
 local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
 Q.shot=function(name)assert(U.shot(game,out..'/giant-'..name..'.png'))end
 local settle=Q.settle
 Q.settle=function()
  local ok,why=pcall(settle)
  if not ok then
   U.shot(game,out..'/giant-stuck.png')
   for i,screen in ipairs(game.stack.states)do
    print('GIANT_STUCK_SCREEN',i)
    for k,v in pairs(screen)do if type(v)=='string'or type(v)=='number'or type(v)=='boolean'then print(k,v)end end
   end
   error(why)
  end
 end
 local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition;local G,E,P=S.sleepingGiant,S.specialEncounters,S.legendPolicy
 local N=dofile(root..'/tests/sevii_journey_navigation.lua')(game,S,Q)
 require('src.world.OverworldController').rollEncounter=function()return nil end
 game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
 game.mods.modOptions.kanto_ascendant.living_world_enabled=false
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
 local mon=require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',100)
 mon.moves={{id='SURF',pp=15},{id='STRENGTH',pp=15},{id='ICE_BEAM',pp=10}}
 game.save.party={mon};game.save.inventory.SOULBADGE=true;game.save.inventory.RAINBOWBADGE=true
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
 N.talk(G.sites.BALANCE);assert(U.shot(game,out..'/giant-counterweights-menu.png'))
 choose('move2');choose('check');Q.settle();assert(G.record().balanced)
 local available,why=E.availability(game,'REGIGIGAS');assert(not available and why=='trial-required','report remains necessary')
 N.talk(G.sites.RHEA);Q.settle();checkpoint()
 assert(G.record().complete and G.record().title=='SEVII_SLEEPING_GIANT','research completes without any legendary owned')
 assert(S.chapters.journal():find('THE SLEEPING GIANT COMPLETE',1,true))
 N.talk(G.sites.REGIGIGAS);choose('battle');local b
 for _=1,1800 do local top=game.stack:top();if top.enemy and top.phase=='menu'then b=top;break end;Q.tap('a')end
 assert(b and b.enemy.mon.species=='REGIGIGAS'and b.enemy.mon.level==100,'native Regigigas scales to the level-100 fixture team')
 assert(P.captureAllowed(game,'REGIGIGAS',b)and not P.captureAllowed(game,'REGIGIGAS'),'exact authored capture only')
 for _,mv in ipairs(b.enemy.mon.moves)do assert(game.data.moves[mv.id]and not tostring(game.data.moves[mv.id].effect):find('UNSUPPORTED',1,true),'supported giant move '..mv.id)end
 local safe,why=require('src.battle.BattleSafety').inspect(game,b)
 assert(not safe and why=='battle_origin_unsupported','custom encounter checkpoint protected')
 Q.catch('REGIGIGAS',true,'down');Q.settle();checkpoint()
 local count=0
 for _,list in ipairs({game.save.party,unpack(game.save.boxes)})do for _,m in ipairs(list)do if m.species=='REGIGIGAS'then count=count+1 end end end
 assert(count==1 and P.history.owned(game,'REGIGIGAS')and S.state().specialCaptures.REGIGIGAS,'one saved giant and ownership receipt')
 N.talk(G.sites.REGIGIGAS);Q.settle();local ok,err=E.start(game,'REGIGIGAS');assert(not ok and err=='legend_owned')
 N.talk(G.sites.BALANCE);Q.settle();assert(G.record().balanced,'completed mechanism cannot be reset')
 N.sail(0);assert(game.overworld.map.id=='VERMILION_CITY')
 local f=assert(io.open(out..'/sleeping-giant.json','wb'))
 f:write(require('src.link.Json').encode({passed=true,steps=N.steps,seams=N.seams,doors=N.doors,ferries=N.sails,
  species='REGIGIGAS',count=count,level=75,inscriptionsReload=true,wrongBalanceAndReset=true,partialBalanceReload=true,questComplete=true,rocketRelocated=true,
  scope='Isolated QA: physical harbor/canyon/ruin routes, three inscriptions, real control menu and partial save/load, report, one native catch/reload, repeat denial and return to Orania. Champion/finale/team/badges/initial harbor, historical pending Rocket rescue, disabled ordinary spawns and Master Ball are fixtures; not a balance proof or Rocket boss replay.'}));f:close()
 print('SEVII_NATIVE_SLEEPING_GIANT_PASS',N.steps,N.seams,N.doors,N.sails);love.event.quit()
end
