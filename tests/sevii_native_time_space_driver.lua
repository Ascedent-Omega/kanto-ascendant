return function(game)
 io.stdout:setvbuf('no')
 local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
 local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
 Q.shot=function(name)assert(U.shot(game,out..'/time-space-'..name..'.png'))end
 local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition;local T,E,P=S.timeSpace,S.specialEncounters,S.legendPolicy
 local N=dofile(root..'/tests/sevii_journey_navigation.lua')(game,S,Q)
 require('src.world.OverworldController').rollEncounter=function()return nil end
 game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
 game.mods.modOptions.kanto_ascendant.living_world_enabled=false
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
 local mon=require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',100)
 mon.moves={{id='SURF',pp=15},{id='STRENGTH',pp=15},{id='ICE_BEAM',pp=10}}
 game.save.party={mon};game.save.inventory.SOULBADGE=true;game.save.inventory.RAINBOWBADGE=true
 assert(K.beyondKanto.activate(game,{decision='qa-time-space-return-aftermath'}))
 Q.extraWarpAt=function(m,x,y)for _,w in ipairs(S.links[m.id]or{})do if w.x==x and w.y==y then return true end end;return false end
 U.teleport(game,S.harbors[6],8,5,'down');Q.settle()
 N.talk(T.sites.LEVIN);Q.settle();assert(not T.record().briefed,'researcher refuses incomplete expedition')
 local s=S.state();s.stage=3;s.chapterOneComplete=true;s.samples={heat=true,drift=true}
 s.expeditionComplete=true;s.seviiRiftSealed=true;S.persist(s);K.generationRules.resolve(game)
 local function checkpoint()
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
 end
 local function choose(id)
  for _=1,1800 do
   local panel=game.stack:top()
   if panel.items then
    if id==24 then assert(U.shot(game,out..'/time-space-clock-menu.png'))end
    local wanted;for i,row in ipairs(panel.items)do if row.value==id then wanted=i end end
    assert(wanted,'missing time-space choice '..id)
    for _=1,60 do if panel.index==wanted then Q.tap('a');return end;Q.tap(panel.index>wanted and'up'or'down')end
    error('time-space choice stuck')
   end
   assert(panel~=game.overworld,'time-space menu closed');Q.tap('a')
  end
  error('time-space menu not reached')
 end
 N.talk(T.sites.LEVIN);Q.settle();assert(T.record().briefed)
 N.talk(T.sites.CLOCK);choose(12);Q.settle();assert(not T.record().timeStable,'readers must be inspected before correct answer counts')
 for i=1,3 do N.talk(T.sites['PULSE_'..i]);Q.settle();assert(T.record().pulses[tostring(i)]);if i==2 then checkpoint()end end
 N.talk(T.sites.CLOCK);choose(24);Q.settle();assert(not T.record().timeStable,'later common beat refused')
 N.talk(T.sites.CLOCK);choose(12);Q.settle();checkpoint();assert(T.record().timeStable,'common rhythm persists')
 N.talk(T.sites.LEVIN);Q.settle();assert(not T.record().complete,'both proofs needed')
 N.talk(T.sites.CENTRE);Q.settle();assert(T.record().surveying)
 N.talk(T.sites.EAST);Q.settle();assert(T.record().point==0 and T.record().surveying,'wrong first marker resets only sequence')
 N.talk(T.sites.WEST);Q.settle();checkpoint();assert(T.record().point==1 and T.record().surveying,'partial loop survives load inside cave')
 N.go('KA_SEVII_SIX_ISLAND_OUTCAST_ISLAND_X0_Y20',7,2);Q.settle()
 assert(not T.record().surveying and T.record().point==0 and T.record().interrupted,'actual exit cancels unfinished loop')
 assert(T.record().timeStable,'clock proof survives leaving unfinished spatial loop')
 N.talk(T.sites.CENTRE);Q.settle();assert(T.record().surveying,'actual reentry allows restart')
 for i,id in ipairs(T.order)do
  N.talk(T.sites[id]);Q.settle();assert(T.record().point==i,'physical ordered marker '..id)
  if i==2 then checkpoint();assert(T.record().point==2 and T.record().surveying)end
 end
 assert(not T.record().spaceStable,'four markers require final return')
 N.talk(T.sites.CENTRE);Q.settle();checkpoint();assert(T.record().spaceStable and not T.record().surveying)
 assert(U.shot(game,out..'/time-space-completed-survey.png'))
 N.talk(T.sites.LEVIN);Q.settle();checkpoint()
 assert(T.record().complete and T.record().title=='SEVII_TIME_SPACE'and S.state().seviiRiftSealed,'research completes with crossing still sealed')
 assert(S.chapters.journal():find('RHYTHM AND BOUNDARY COMPLETE',1,true))
 local captures={}
 for _,id in ipairs{'DIALGA','PALKIA'}do
  N.talk(T.sites[id]);choose('battle');local b
  for _=1,1800 do local top=game.stack:top();if top.enemy and top.phase=='menu'then b=top;break end;Q.tap('a')end
  local species=assert(K.backendGiftSpecies67.byKey['dex:'..E.rows[id].dex])
  assert(b and b.enemy.mon.species==species and b.enemy.mon.level==S.scaling.legend(game,E.rows[id].level),'canonical time-space legend/level')
  assert(P.captureAllowed(game,species,b)and not P.captureAllowed(game,species),'exact authored encounter only')
  for _,mv in ipairs(b.enemy.mon.moves)do assert(game.data.moves[mv.id]and not tostring(game.data.moves[mv.id].effect):find('UNSUPPORTED',1,true),'supported time-space move '..mv.id)end
  local safe,why=require('src.battle.BattleSafety').inspect(game,b)
  assert(not safe and why=='battle_origin_unsupported','custom encounter checkpoint protected')
  Q.catch(species,true,'down');Q.settle();checkpoint()
  local count=0
  for _,list in ipairs({game.save.party,unpack(game.save.boxes)})do for _,m in ipairs(list)do if m.species==species then count=count+1 end end end
  assert(count==1 and P.history.owned(game,species)and S.state().specialCaptures[id],'exactly one saved '..id)
  N.talk(T.sites[id]);Q.settle();local ok,err=E.start(game,id);assert(not ok and err=='legend_owned')
  captures[#captures+1]={id=id,species=species,level=b.enemy.mon.level,count=count};print('SEVII_TIME_SPACE_CAPTURE_RELOAD_PASS',id)
 end
 N.sail(0);assert(game.overworld.map.id=='VERMILION_CITY')
 local f=assert(io.open(out..'/time-space.json','wb'))
 f:write(require('src.link.Json').encode({passed=true,steps=N.steps,seams=N.seams,doors=N.doors,ferries=N.sails,
  captures=captures,wrongBeat=true,wrongMarker=true,partialReload=true,exitResetsUnfinishedLoop=true,clockPreserved=true,questComplete=true,
  scope='Isolated QA: native routes through Dotted Hole and Altering Cave, readings and clock menu, incorrect/common beat, incorrect/ordered markers, partial reload, real exit/reentry interrupting only unfinished survey, report, two native captures/reloads and return to Orania. Champion/finale/team/badges/initial harbor, disabled ordinary spawns and Master Balls are fixtures; no balance proof or animated spacetime distortion.'}));f:close()
 print('SEVII_NATIVE_TIME_SPACE_PASS',N.steps,N.seams,N.doors,N.sails);love.event.quit()
end
