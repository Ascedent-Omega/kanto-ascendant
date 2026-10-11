return function(game)
 io.stdout:setvbuf('no')
 local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
 local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
 Q.shot=function(name)assert(U.shot(game,out..'/tidal-'..name..'.png'))end
 local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition;local T,E,P=S.tidalReturn,S.specialEncounters,S.legendPolicy
 local N=dofile(root..'/tests/sevii_journey_navigation.lua')(game,S,Q)
 require('src.world.OverworldController').rollEncounter=function()return nil end
 game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
 game.mods.modOptions.kanto_ascendant.living_world_enabled=false
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
 local mon=require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',100)
 mon.moves={{id='SURF',pp=15},{id='STRENGTH',pp=15},{id='ICE_BEAM',pp=10}}
 game.save.party={mon};game.save.inventory.SOULBADGE=true;game.save.inventory.RAINBOWBADGE=true
 assert(K.beyondKanto.activate(game,{decision='qa-tidal-return-aftermath'}))
 Q.extraWarpAt=function(m,x,y)for _,w in ipairs(S.links[m.id]or{})do if w.x==x and w.y==y then return true end end;return false end
 U.teleport(game,S.harbors[6],8,5,'down');Q.settle()
 N.talk(T.sites.TAMO);Q.settle();assert(not T.record().briefed,'researcher refuses incomplete expedition')
 local s=S.state();s.stage=3;s.chapterOneComplete=true;s.samples={heat=true,drift=true}
 s.expeditionComplete=true;s.seviiRiftSealed=true;S.persist(s);K.generationRules.resolve(game)
 local function checkpoint()
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
 end
 local function shown(id)local p=T.sites[id];local rows=game.save.objectToggles and game.save.objectToggles[p.map];return rows and rows[p.name]end
 local function actor(id)
  for _,n in ipairs(game.overworld.npcs or{})do if n.def.name==T.sites[id].name then return n end end
 end
 local function choose(id)
  for _=1,1800 do
   local panel=game.stack:top()
   if panel.items then
    local wanted;for i,row in ipairs(panel.items)do if row.value==id then wanted=i end end
    assert(wanted,'missing tidal choice '..id)
    for _=1,60 do if panel.index==wanted then Q.tap('a');return end;Q.tap(panel.index>wanted and'up'or'down')end
    error('tidal choice stuck')
   end
   assert(panel~=game.overworld,'tidal menu closed');Q.tap('a')
  end
  error('tidal menu not reached')
 end
 N.talk(T.sites.TAMO);Q.settle();assert(T.record().briefed)
 assert(not shown('HOME')and not actor('HOME'),'crew member absent from home before rescue')
 N.talk(T.sites.SOUTH);Q.settle();assert(not T.record().returned,'signal cannot skip repair')
 N.talk(T.sites.PLANK);Q.settle();assert(not T.record().plankTaken,'find crew before recovering marked cargo')
 N.talk(T.sites.NERI);Q.settle();assert(T.record().requested and actor('NERI'))
 assert(U.shot(game,out..'/tidal-stranded-researcher.png'))
 N.talk(T.sites.PLANK);Q.settle();checkpoint();assert(T.record().plank and T.record().plankTaken,'actual cargo recovery/load')
 N.talk(T.sites.NERI);Q.settle();assert(T.record().repaired and not T.record().plank,'actual repair consumes plank')
 N.talk(T.sites.NORTH);Q.settle();checkpoint()
 assert(T.record().signals==1 and not shown('NERI')and not shown('HOME'),'saved departure has no actor duplicate')
 N.visit(T.sites.NERI);assert(not actor('NERI'),'stranded actor physically removed after departure')
 N.talk(T.sites.SOUTH);Q.settle();assert(T.record().signals==1 and not T.record().returned,'wrong second signal preserves north')
 N.talk(T.sites.MIDDLE);Q.settle();checkpoint();assert(T.record().signals==2,'second passage survives load')
 N.talk(T.sites.SOUTH);Q.settle();checkpoint()
 assert(T.record().returned and shown('HOME')and not shown('NERI'),'actual safe return moves actor home')
 N.talk(T.sites.TAMO);Q.settle();assert(not T.record().complete,'must check in with returned researcher')
 N.talk(T.sites.HOME);Q.settle();assert(T.record().checkedIn and actor('HOME'),'real returned NPC conversation')
 assert(U.shot(game,out..'/tidal-researcher-home.png'))
 N.talk(T.sites.TAMO);Q.settle();checkpoint()
 assert(T.record().complete and T.record().title=='SEVII_TIDAL_RETURN','rescue completes without legendary capture')
 assert(S.chapters.journal():find('THE WAY HOME COMPLETE',1,true))
 local captures={}
 for _,id in ipairs{'PHIONE','MANAPHY'}do
  N.talk(T.sites[id]);choose('battle');local b
  for _=1,1800 do local top=game.stack:top();if top.enemy and top.phase=='menu'then b=top;break end;Q.tap('a')end
  local species=assert(K.backendGiftSpecies67.byKey['dex:'..E.rows[id].dex])
  assert(b and b.enemy.mon.species==species and b.enemy.mon.level==S.scaling.legend(game,E.rows[id].level),'canonical tidal legend/level')
  assert(P.captureAllowed(game,species,b)and not P.captureAllowed(game,species),'exact authored encounter only')
  for _,mv in ipairs(b.enemy.mon.moves)do assert(game.data.moves[mv.id]and not tostring(game.data.moves[mv.id].effect):find('UNSUPPORTED',1,true),'supported tidal move '..mv.id)end
  local safe,why=require('src.battle.BattleSafety').inspect(game,b)
  assert(not safe and why=='battle_origin_unsupported','custom encounter checkpoint protected')
  Q.catch(species,true,'down');Q.settle();checkpoint()
  local count=0
  for _,list in ipairs({game.save.party,unpack(game.save.boxes)})do for _,m in ipairs(list)do if m.species==species then count=count+1 end end end
  assert(count==1 and P.history.owned(game,species)and S.state().specialCaptures[id],'exactly one saved '..id)
  N.talk(T.sites[id]);Q.settle();local ok,err=E.start(game,id);assert(not ok and err=='legend_owned')
  captures[#captures+1]={id=id,species=species,level=b.enemy.mon.level,count=count};print('SEVII_TIDAL_CAPTURE_RELOAD_PASS',id)
 end
 N.sail(0);assert(game.overworld.map.id=='VERMILION_CITY')
 local f=assert(io.open(out..'/tidal-return.json','wb'))
 f:write(require('src.link.Json').encode({passed=true,steps=N.steps,seams=N.seams,doors=N.doors,ferries=N.sails,
  captures=captures,cargoReload=true,wrongSignal=true,partialCourseReload=true,physicalActorDeparture=true,physicalActorHome=true,questComplete=true,
  scope='Isolated QA: physical harbor/coast/island routes, real plank collection and boat repair, out-of-order signal refusal, partial save/load, actor removed from island and visible at home, report, two native captures/reloads and return to Orania. Champion/finale/team/badges/initial harbor, disabled ordinary spawns and Master Balls are fixtures; not a balance proof or a rendered boat journey.'}));f:close()
 print('SEVII_NATIVE_TIDAL_RETURN_PASS',N.steps,N.seams,N.doors,N.sails);love.event.quit()
end
