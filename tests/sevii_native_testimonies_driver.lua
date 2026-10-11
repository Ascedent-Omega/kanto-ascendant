return function(game)
 io.stdout:setvbuf('no')
 local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
 local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
 Q.shot=function(name)assert(U.shot(game,out..'/testimonies-'..name..'.png'))end
 local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition;local A,E,P=S.sevenTestimonies,S.specialEncounters,S.legendPolicy
 local N=dofile(root..'/tests/sevii_journey_navigation.lua')(game,S,Q)
 require('src.world.OverworldController').rollEncounter=function()return nil end
 game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
 game.mods.modOptions.kanto_ascendant.living_world_enabled=false
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
 local mon=require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',100)
 mon.moves={{id='SURF',pp=15},{id='STRENGTH',pp=15},{id='ICE_BEAM',pp=10}}
 game.save.party={mon};game.save.inventory.SOULBADGE=true;game.save.inventory.RAINBOWBADGE=true
 assert(K.beyondKanto.activate(game,{decision='qa-testimonies-return-aftermath'}))
 Q.extraWarpAt=function(m,x,y)for _,w in ipairs(S.links[m.id]or{})do if w.x==x and w.y==y then return true end end;return false end
 U.teleport(game,S.harbors[7],8,5,'down');Q.settle()
 N.talk(A.sites.SORA);Q.settle();assert(not A.record().briefed,'researcher refuses incomplete expedition')
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
    assert(wanted,'missing testimonies choice '..id)
    for _=1,60 do if panel.index==wanted then Q.tap('a');return end;Q.tap(panel.index>wanted and'up'or'down')end
    error('testimonies choice stuck')
   end
   assert(panel~=game.overworld,'testimonies menu closed');Q.tap('a')
  end
  error('testimonies menu not reached')
 end
 local initial=S.state();initial.mysteries=initial.mysteries or{}
 for _,r in ipairs(A.rows)do if r.key~='heatran'then initial.mysteries[r.key]={[r.flag]=true}end end
 S.persist(initial)
 local oldSpecies=assert(K.backendGiftSpecies67.byKey['dex:485'])
 local oldHeatran=require('src.pokemon.Pokemon').new(game.data,oldSpecies,70)
 game.save.party[#game.save.party+1]=oldHeatran;assert(P.history.record(game,oldHeatran));checkpoint()
 N.talk(A.sites.SORA);Q.settle();assert(A.record().briefed)
 N.talk(A.sites.SORA);Q.settle();assert(not A.record().complete,'book waits for physically copied pages')
 N.sail(1)
 N.talk(A.sites.BOOK_1);Q.settle();assert(not A.record().pages['1'],'Heatran ownership alone does not finish pressure research')
 local M=S.mysteries
 N.talk(M.sites.RESEARCHER);Q.settle();assert(M.record().briefed,'old Heatran owner can begin actual research dialogue')
 for _,id in ipairs{'UPPER','MIDDLE','LOWER'}do N.talk(M.sites[id]);Q.settle();assert(M.record().readings[id])end
 N.talk(M.sites.VENT);choose('MIDDLE');choose('LEAVE');Q.settle();checkpoint();assert(M.record().tuned==1)
 N.talk(M.sites.VENT);choose('UPPER');choose('LOWER');choose('LEAVE');Q.settle()
 assert(M.record().open and not M.record().caught,'old owner completes actual pressure menu without catching again')
 N.talk(M.sites.VENT);choose('BATTLE');Q.settle()
 local ok,why=M.start(game);assert(not ok and why=='legend_owned','new Heatran remains unavailable')
 checkpoint();assert(M.record().open and not M.record().caught)
 local heatCount=0;for _,list in ipairs({game.save.party,unpack(game.save.boxes)})do for _,m in ipairs(list)do if m.species==oldSpecies then heatCount=heatCount+1 end end end
 assert(heatCount==1,'existing Heatran retained with no second specimen')
 for i=1,7 do
  if i>1 then N.sail(i)end
  N.talk(A.sites['BOOK_'..i]);Q.settle();checkpoint();assert(A.record().pages[tostring(i)],'actual upstairs report/reload '..i)
  N.talk(A.sites['BOOK_'..i]);Q.settle();assert(A.record().pages[tostring(i)],'repeat report remains copied')
 end
 N.talk(A.sites.SORA);Q.settle();checkpoint()
 assert(A.record().complete and A.record().title=='SEVII_SEVEN_TESTIMONIES','island book complete without new legendary captures')
 assert(not S.state().specialCaptures and not M.record().caught,'capstone did not demand a prior capture')
 N.talk(A.sites.ARCEUS);Q.settle();checkpoint();assert(A.record().witnessed,'native book reading unlocks voluntary audience')
 assert(S.state().seviiRiftSealed and S.state().expeditionComplete,'original local ending persists')
 assert(U.shot(game,out..'/testimonies-tanoby-stone.png'))
 local captures={}
 for _,id in ipairs{'ARCEUS'}do
  N.talk(A.sites[id]);choose('battle');local b
  for _=1,1800 do local top=game.stack:top();if top.enemy and top.phase=='menu'then b=top;break end;Q.tap('a')end
  local species=assert(K.backendGiftSpecies67.byKey['dex:'..E.rows[id].dex])
  assert(b and b.enemy.mon.species==species and b.enemy.mon.level==S.scaling.legend(game,E.rows[id].level),'canonical testimonies legend/level')
  assert(P.captureAllowed(game,species,b)and not P.captureAllowed(game,species),'exact authored encounter only')
  for _,mv in ipairs(b.enemy.mon.moves)do assert(game.data.moves[mv.id]and not tostring(game.data.moves[mv.id].effect):find('UNSUPPORTED',1,true),'supported testimonies move '..mv.id)end
  local safe,why=require('src.battle.BattleSafety').inspect(game,b)
  assert(not safe and why=='battle_origin_unsupported','custom encounter checkpoint protected')
  Q.catch(species,true,'down');Q.settle();checkpoint()
  local count=0
  for _,list in ipairs({game.save.party,unpack(game.save.boxes)})do for _,m in ipairs(list)do if m.species==species then count=count+1 end end end
  assert(count==1 and P.history.owned(game,species)and S.state().specialCaptures[id],'exactly one saved '..id)
  N.talk(A.sites[id]);Q.settle();local ok,err=E.start(game,id);assert(not ok and err=='legend_owned')
  captures[#captures+1]={id=id,species=species,level=b.enemy.mon.level,count=count};print('SEVII_TESTIMONIES_CAPTURE_RELOAD_PASS',id)
 end
 N.sail(0);assert(game.overworld.map.id=='VERMILION_CITY')
 local f=assert(io.open(out..'/seven-testimonies.json','wb'))
 f:write(require('src.link.Json').encode({passed=true,steps=N.steps,seams=N.seams,doors=N.doors,ferries=N.sails,
  captures=captures,pages=7,oldHeatranResearchComplete=true,oldHeatranCount=heatCount,noPriorCapturesRequired=true,questComplete=true,
  scope='Isolated QA: real seven-island ferries and upstairs report visits, research-required refusal, full native pressure puzzle with an already owned Heatran, single existing Heatran retained, partial/save reload, Sora compilation, narrated stone audience, actual Arceus capture/reload and return to Orania. Six other research completions, champion/finale/team/badges/initial harbor/old Heatran, disabled ordinary spawns and Master Balls are fixtures. Those six quest paths have separate native proofs; this is not a full replay of every prerequisite or a balance proof.'}));f:close()
 print('SEVII_NATIVE_TESTIMONIES_PASS',N.steps,N.seams,N.doors,N.sails);love.event.quit()
end
