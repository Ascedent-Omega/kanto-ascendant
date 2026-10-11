-- Isolated fixture: unlocks, current roamer location and RNG are controlled.
-- Encounters themselves must start through physical steps and native hooks.
return function(game)
 io.stdout:setvbuf('no')
 local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
 local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
 Q.shot=function(name)assert(U.shot(game,out..'/eon-'..name..'.png'))end
 local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition
 local R,V,H=K.hoennRoamers67,S.eonRoaming,S.legendPolicy.history
 local OW=require('src.world.OverworldController');local nativeRoll=OW.rollEncounter
 OW.rollEncounter=function()return nil end -- Only fixture travel.
 game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
 game.mods.modOptions.kanto_ascendant.living_world_enabled=false
 game.mods.modOptions.kanto_ascendant.living_world_random_encounters=true
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
 game.save.party={require('src.pokemon.Pokemon').new(game.data,'DRAGONITE',100)}
 game.save.inventory.HOENN_HONEY=1;game.save.inventory.HOENN_DEX=1
 game.save.inventory.SOULBADGE=true
 assert(K.beyondKanto.activate(game,{decision='qa-eon-roaming'}))
 local st=S.state();st.expeditionComplete=true;st.seviiRiftSealed=true;S.persist(st)
 S.install(game);K.generationRules.resolve(game)
 U.teleport(game,S.ONE,11,8,'down');Q.settle();assert(game:writeSave())
 assert(H.sync(game));assert(R.initialize(game));assert(R.available(game))
 assert(V.accepts(game,S.ONE)and not V.accepts(game,S.CENTER))
 for id,m in pairs(S.maps)do
  if (m.kaSeviiSource or''):find('Cave',1,true)then assert(not V.accepts(game,id),'no caves '..id)end
 end
 local function checkpoint()
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
 end
 local results={}
 local function approach(id,water)
  local target
  if water then
   for _,p in ipairs(S.habitats.plan.pools)do
    if p.terrain=='water'and V.accepts(game,p.map)then target={map=p.map,x=p.anchor[1],y=p.anchor[2]};break end
   end
  else
   U.teleport(game,S.ONE,11,8,'down');Q.settle()
   local map=game.overworld.map
   for y=2,map.heightCells-3 do for x=2,map.widthCells-3 do
    if not target and map:isWalkableCell(x,y)and map:isWalkableCell(x-1,y)
      and not map:warpAtCell(x,y)and not map:warpAtCell(x-1,y)
      and Q.pairClear(map,x-1,y,x,y)then
      local linked=false;for _,w in ipairs(S.links[S.ONE]or{})do if w.y==y and(w.x==x or w.x==x-1)then linked=true end end
      if not linked then target={map=S.ONE,x=x,y=y}end
    end
   end end
  end
  assert(target);U.teleport(game,target.map,target.x,target.y,'down');Q.settle()
  local map=game.overworld.map;local direction
  for _,d in ipairs{{-1,0,'right'},{1,0,'left'},{0,-1,'down'},{0,1,'up'}}do
   local x,y=target.x+d[1],target.y+d[2]
   if map:inBounds(x,y)and (water and map:isWaterCell(x,y)or not water and map:isWalkableCell(x,y))then
    U.teleport(game,target.map,x,y,d[3]);Q.settle();local ow=game.overworld;ow.player.surfing=water
    if require('src.world.Collision').canMove(ow.map,ow.entities,ow.player,d[3])then direction=d[3];break end
   end
  end
  assert(direction,'physical approach exists')
  local s=R.state(false)
  for species,row in pairs(s.roamers)do row.map=species==id and target.map or'ROUTE_25' end
  R.persist(s)
  if os.getenv('SEVII_EON_REPRO_ONLY')=='1'then local pipes=require('src.render.Pipelines');pipes.setLevel('voxel',tonumber(os.getenv('SEVII_COMPONENT_CAMERA')or'0'));pipes.syncOptions(game.save.options);Q.settle()end
  return target,direction
 end
 local function step(target,direction,roll)
  local ow=game.overworld;ow.wildEncounterGraceSteps=0
  local calls=0
  local observed
  ow.rollEncounter=function(self,definition,terrain)
   observed=terrain
   local random=love.math.random
   love.math.random=function(lo,hi)if lo==1 and hi==20 then calls=calls+1;return roll end;return random(lo,hi)end
   local ok,result=pcall(nativeRoll,self,definition,terrain);love.math.random=random;assert(ok,result)
   -- Suppress unrelated ordinary encounters in this focused fixture.
   return result and result.kaEncounterSource=='hoenn_roamer'and result or nil
  end
  U.hold(game,direction,1)
  for _=1,180 do if not ow.player.moving then break end;U.wait(1)end
  U.wait(10);ow.rollEncounter=nil
  assert(ow.player.cellX==target.x and ow.player.cellY==target.y,'one real completed step')
  return calls,observed
 end
 -- Every classified Kanto map must admit a real step encounter, including
 -- floors without grass. Only travel, trainer sight and RNG are fixtures.
 OW.checkTrainerSight=function()end
 for _,badge in ipairs{'BOULDERBADGE','CASCADEBADGE','THUNDERBADGE','RAINBOWBADGE','SOULBADGE','MARSHBADGE','VOLCANOBADGE','EARTHBADGE'}do game.save.inventory[badge]=true end
 local kanto={};if os.getenv('SEVII_EON_SCOPE')~='sevii'then for id in pairs(V.kanto)do kanto[#kanto+1]=id end end
 local portalAccess=K.hoennLegendPortals67.available
 assert(not V.accepts(game,'KA_HEVO_RAYQUAZA_CHAMBER'),'locked original sky portal omitted')
 -- Geometry/step fixture only: the original portal remains the sole gate.
 K.hoennLegendPortals67.available=function(_,character)assert(character=='GREEN');return true end
 if os.getenv('SEVII_EON_SCOPE')~='sevii'then for id in pairs(V.extraKanto)do kanto[#kanto+1]=id end end;table.sort(kanto)
 local kantoResults={};local identity
 for _,mapId in ipairs(kanto)do
  U.teleport(game,mapId,1,1,'right');Q.settle()
  local map=game.overworld.map;local candidates={}
  local function open(x,y,water)
   if not map:inBounds(x,y)or map:warpAtCell(x,y)then return false end
   if water then return map:isWaterCell(x,y)and not map:isWalkableCell(x,y)end
   return map:isWalkableCell(x,y)
  end
  for y=2,map.heightCells-3 do for x=2,map.widthCells-3 do
   local water=not map:isWalkableCell(x,y)and map:isWaterCell(x,y)
   if open(x,y,water)and open(x-1,y,water)and Q.pairClear(map,x-1,y,x,y)then
    candidates[#candidates+1]={map=mapId,x=x,y=y,water=water,grass=map:isGrassCell(x,y)}
   end
  end end
  table.sort(candidates,function(a,b)
   local function rank(v)return v.water and 2 or v.grass and 1 or 0 end
   return rank(a)<rank(b)
  end)
  local target
  for _,c in ipairs(candidates)do
   U.teleport(game,mapId,c.x-1,c.y,'right');Q.settle()
   local ow=game.overworld;ow.player.surfing=c.water
   if require('src.world.Collision').canMove(ow.map,ow.entities,ow.player,'right')then target=c;break end
  end
  assert(target,'walkable pair '..mapId)
  game.save.safari=mapId:find('SAFARI_ZONE_',1,true)and{balls=30,steps=500}or nil
  local state=R.state(false);state.roamers.LATIAS.map=mapId;state.roamers.LATIOS.map=mapId=='ROUTE_25'and'ROUTE_1'or'ROUTE_25';R.persist(state)
  game.save.repelSteps=0
  local policy=game.data.field.indoorEncounters
  local calls,terrain=step(target,'right',1)
  assert(game.data.field.indoorEncounters==policy,'temporary floor policy restored '..mapId)
  assert(calls==1,'one native local roll '..mapId..': '..tostring(calls))
  local b
  for _=1,1800 do local t=game.stack:top();if t.enemy and t.enemy.mon and t.phase=='menu'then b=t;break end;Q.tap('a')end
  assert(b and b.kaHoennRoamer=='LATIAS'and R.canCaptureExpansion(game,b,'LATIAS'),'bound roamer on '..mapId)
  local mon=b.enemy.mon;local Json=require('src.link.Json')
  local snapshot={dvs=mon.dvs,stats=mon.stats}
  if identity then
   for _,group in ipairs{'dvs','stats'}do for key,value in pairs(identity[group])do assert(snapshot[group][key]==value,'stable '..group..'.'..key..' on '..mapId)end end
  else identity=snapshot end
  Q.tap('down');Q.tap('right');assert(b.menuIndex==4,'native RUN selection');Q.tap('a')
  for _=1,1800 do if game.stack:top()==game.overworld then break end;Q.tap('a')end
  Q.settle();assert(R.state(false).roamers.LATIAS and not H.owned(game,'LATIAS'),'escape retains unique uncaught identity')
  kantoResults[#kantoResults+1]={map=mapId,terrain=terrain,safari=b.safari~=nil}
  print('SEVII_EON_KANTO_STEP_PASS',mapId,terrain)
  game.save.safari=nil
 end
 K.hoennLegendPortals67.available=portalAccess
 if os.getenv('SEVII_EON_SCOPE')~='sevii'then assert(#kantoResults==47,'all 45 base Kanto outdoor maps plus 2 authored outdoor maps physically tested') end
 for _,id in ipairs{'LATIAS','LATIOS'}do
  local water=id=='LATIOS';local target,direction=approach(id,water)
  -- Same map: 19 of the 20 probability outcomes must not start a battle.
  game.save.repelSteps=0
  local missedCalls,missedTerrain=step(target,direction,tonumber(os.getenv('SEVII_EON_REPRO_ROLL'))or 20)
  print('SEVII_EON_STEP_REPRO',id,target.map,target.x,target.y,missedCalls,tostring(missedTerrain),tostring(R.available(game)),tostring(game.overworld.map.def.outdoor))
  if os.getenv('SEVII_EON_REPRO_ONLY')=='1'then
   if missedCalls>0 and game.stack:top()~=game.overworld then for _=1,1800 do local t=game.stack:top();if t.enemy and t.phase=='menu'then break end;Q.tap('a')end end
   local f=assert(io.open(out..'/eon-step-repro.json','w'));f:write(require('src.link.Json').encode({species=id,map=target.map,x=target.x,y=target.y,calls=missedCalls,terrain=missedTerrain,available=R.available(game),outdoor=game.overworld.map.def.outdoor,phase=game.stack:top().phase or'overworld',roll=tonumber(os.getenv('SEVII_EON_REPRO_ROLL'))or 20}));f:close();Q.shot('floor-step-repro');print('SEVII_EON_STEP_DIAGNOSTIC_PASS');love.event.quit();return
  end
  assert(missedCalls==1 and game.stack:top()==game.overworld,'miss stays on overworld')
  target,direction=approach(id,water)
  local s=R.state(false);s.roamers[id].map='ROUTE_1';R.persist(s)
  assert(step(target,direction,1)==0 and game.stack:top()==game.overworld,'wrong map never even draws the 5% roll')
  target,direction=approach(id,water);game.save.repelSteps=20
  assert(step(target,direction,1)==1 and game.stack:top()==game.overworld,'normal Repel blocks lower-level roamer')
  assert(game.save.repelSteps==19,'native step still decrements Repel')
  target,direction=approach(id,water);game.save.repelSteps=0
  assert(step(target,direction,1)==1,'one local roll')
  local b
  for _=1,1800 do
   local t=game.stack:top();if t.enemy and t.enemy.mon and t.phase=='menu'then b=t;break end;Q.tap('a')
  end
  assert(b and b.kaHoennRoamer==id and b.enemy.mon.species==id,'native battle binds existing identity')
  assert(R.canCaptureExpansion(game,b,id),'live capture permission')
  Q.catch(id,true,'down');Q.settle();assert(H.owned(game,id)and not R.state(false).roamers[id])
  checkpoint();assert(H.owned(game,id)and not R.state(false).roamers[id],'caught remains retired after native load')
  results[#results+1]={species=id,map=target.map,water=water,wrongMapExcluded=true,repel=true,caughtAndLoaded=true}
  print('SEVII_EON_NATIVE_CAPTURE_RELOAD_PASS',id,target.map)
 end
 local L=K.legacyJourney.archive
 game.save.party={game.save.party[1]};game.save.boxes={};for i=1,12 do game.save.boxes[i]={}end
 game.save.pokedex.owned={DRAGONITE=true};assert(game:writeSave())
 local archived,why=L.beginJourney(game.save,{pact='journey',bankPolicy='sealed',itemPolicy='empty',
  runRules=L.safeRunRulesSnapshot(game.save),playerAvatar='BLUE'})
 assert(archived,'actual Eon Legacy transaction '..tostring(why))
 local fresh={party={},boxes={},flags={},modData={}}
 assert(L.seedNewSave(fresh));local owned=fresh.modData.kanto_ascendant.hevo_persistent[H.KEY]
 assert(owned['380']and owned['381'],'both caught identities cross actual Legacy archive without carried Pokemon')
 print('SEVII_EON_LEGACY_PASS')
 OW.rollEncounter=nativeRoll
 local f=assert(io.open(out..'/eon-roaming.json','wb'));f:write(require('src.link.Json').encode({passed=true,results=results,kanto=kantoResults,stableDVsAndStats=true,actualLegacy=true}));f:close()
 print('SEVII_EON_NATIVE_PASS');love.event.quit()
end
