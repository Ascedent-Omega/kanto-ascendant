-- The level-100 team fixture yields level-100 legends under the current authored scaling policy.
return function(game)
 io.stdout:setvbuf('no')
 local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
 local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
 Q.shot=function(name)assert(U.shot(game,out..'/garden-'..name..'.png'))end
 local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition;local G,E,P=S.garden,S.specialEncounters,S.legendPolicy
 local N=dofile(root..'/tests/sevii_journey_navigation.lua')(game,S,Q)
 require('src.world.OverworldController').rollEncounter=function()return nil end
 game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
 game.mods.modOptions.kanto_ascendant.living_world_enabled=false
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
 local mon=require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',100)
 mon.moves={{id='SURF',pp=15},{id='STRENGTH',pp=15},{id='ICE_BEAM',pp=10}}
 game.save.party={mon};game.save.inventory.SOULBADGE=true;game.save.inventory.RAINBOWBADGE=true
 assert(K.beyondKanto.activate(game,{decision='qa-garden-return-aftermath'}))
 Q.extraWarpAt=function(m,x,y)for _,w in ipairs(S.links[m.id]or{})do if w.x==x and w.y==y then return true end end;return false end
 U.teleport(game,S.harbors[3],8,5,'down');Q.settle()
 N.talk(G.sites.ODA);Q.settle();assert(not G.record().briefed,'researcher refuses incomplete expedition')
 local s=S.state();s.stage=3;s.chapterOneComplete=true;s.samples={heat=true,drift=true}
 s.expeditionComplete=true;s.seviiRiftSealed=true;S.persist(s);K.generationRules.resolve(game)
 local function checkpoint()
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
 end
 local function shown(id)local p=G.sites[id];local rows=game.save.objectToggles and game.save.objectToggles[p.map];return rows and rows[p.name]end
 local function actor(id)
  for _,n in ipairs(game.overworld.npcs or{})do if n.def.name==G.sites[id].name then return n end end
 end
 local function choose(id)
  for _=1,1800 do
   local panel=game.stack:top()
   if panel.items then
    local wanted;for i,row in ipairs(panel.items)do if row.value==id then wanted=i end end
    assert(wanted,'missing garden choice '..id)
    for _=1,60 do if panel.index==wanted then Q.tap('a');return end;Q.tap(panel.index>wanted and'up'or'down')end
    error('garden choice stuck')
   end
   assert(panel~=game.overworld,'garden menu closed');Q.tap('a')
  end
  error('garden menu not reached')
 end
 N.talk(G.sites.ODA);Q.settle();assert(G.record().briefed and G.record().seeds)
 N.talk(G.sites.GATE);Q.settle();assert(not G.record().watered,'cannot skip clearance')
 N.talk(G.sites.RIKA);Q.settle();assert(not G.record().thanks,'cannot thank before restoring garden')
 N.talk(G.sites.BED);Q.settle();assert(G.record().inspected)
 N.talk(G.sites.BED);Q.settle();assert(not G.record().sown and G.record().seeds,'dry bed cannot consume seeds')
 N.talk(G.sites.SILT);Q.settle();checkpoint()
 assert(G.record().cleared and not shown('SILT')and not actor('SILT'),'debris physically removed and stays removed on reload')
 N.talk(G.sites.GATE);choose('fast');Q.settle()
 assert(not G.record().watered and G.record().seeds,'wrong sluice setting preserves seed cargo')
 N.talk(G.sites.GATE);choose('slow');Q.settle();checkpoint();assert(G.record().watered)
 N.talk(G.sites.BED);Q.settle();checkpoint();assert(G.record().sown and not G.record().seeds,'planting consumes seed packet exactly once')
 N.talk(G.sites.BED);Q.settle();assert(G.record().sown and not G.record().seeds,'repeat interaction does not replace cargo')
 N.talk(G.sites.ODA);Q.settle();assert(not G.record().complete,'report waits for local gratitude')
 N.talk(G.sites.RIKA);choose('pokemon');Q.settle();checkpoint()
 assert(G.record().thanks=='pokemon','gratitude choice saved without requiring the all option')
 assert(U.shot(game,out..'/garden-restored-clearing.png'))
 N.talk(G.sites.ODA);Q.settle();checkpoint()
 assert(G.record().complete and G.record().title=='SEVII_FOREST_GARDEN','restoration completes without capture')
 assert(S.chapters.journal():find('WHAT GROWS AGAIN COMPLETE',1,true))
 local captures={}
 for _,id in ipairs{'SHAYMIN'}do
  N.talk(G.sites[id]);choose('battle');local b
  for _=1,1800 do local top=game.stack:top();if top.enemy and top.phase=='menu'then b=top;break end;Q.tap('a')end
  local species=assert(K.backendGiftSpecies67.byKey['dex:'..E.rows[id].dex])
  assert(b and b.enemy.mon.species==species and b.enemy.mon.level==100,'canonical garden legend/level')
  assert(P.captureAllowed(game,species,b)and not P.captureAllowed(game,species),'exact authored encounter only')
  for _,mv in ipairs(b.enemy.mon.moves)do assert(game.data.moves[mv.id]and not tostring(game.data.moves[mv.id].effect):find('UNSUPPORTED',1,true),'supported garden move '..mv.id)end
  local safe,why=require('src.battle.BattleSafety').inspect(game,b)
  assert(not safe and why=='battle_origin_unsupported','custom encounter checkpoint protected')
  Q.catch(species,true,'down');Q.settle();checkpoint()
  local count=0
  for _,list in ipairs({game.save.party,unpack(game.save.boxes)})do for _,m in ipairs(list)do if m.species==species then count=count+1 end end end
  assert(count==1 and P.history.owned(game,species)and S.state().specialCaptures[id],'exactly one saved '..id)
  N.talk(G.sites[id]);Q.settle();local ok,err=E.start(game,id);assert(not ok and err=='legend_owned')
  captures[#captures+1]={id=id,species=species,level=E.rows[id].level,count=count};print('SEVII_GARDEN_CAPTURE_RELOAD_PASS',id)
 end
 N.sail(0);assert(game.overworld.map.id=='VERMILION_CITY')
 local f=assert(io.open(out..'/forest-garden.json','wb'))
 f:write(require('src.link.Json').encode({passed=true,steps=N.steps,seams=N.seams,doors=N.doors,ferries=N.sails,
  captures=captures,debrisPhysicallyRemoved=true,wrongSluice=true,partialReload=true,seedsConsumedOnce=true,gratitudeChoice='pokemon',questComplete=true,
  scope='Isolated QA: real forest routes and talks, dry-bed refusal, physical debris removal, wrong/correct sluice settings, planting, saved gratitude choice, report, native Shaymin capture/reload and return to Orania. Champion/finale/team/badges/initial harbor, disabled ordinary spawns and Master Balls are fixtures. Water flow and seedling growth are narrated, not newly rendered landscape animations; not a balance proof.'}));f:close()
 print('SEVII_NATIVE_GARDEN_PASS',N.steps,N.seams,N.doors,N.sails);love.event.quit()
end
