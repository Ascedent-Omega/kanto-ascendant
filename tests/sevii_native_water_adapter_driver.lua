-- Real native encounter hook contract, all owned water pools plus one step.
return function(game)
 io.stdout:setvbuf('no')
 local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
 local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
 local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition;local E=S.habitats
 local OW=require('src.world.OverworldController');local nativeRoll=OW.rollEncounter
 OW.rollEncounter=function()return nil end
 Q.setup();game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',100)}
 assert(K.beyondKanto.activate(game,{decision='qa-water-adapter'}))
 S.persist({stage=3,chapterOneComplete=true,samples={heat=true,drift=true}});K.generationRules.resolve(game);S.install(game)
 local p=require('src.render.Pipelines');local camera=tonumber(os.getenv('SEVII_COMPONENT_CAMERA')or'0')
 local function travel(pool,x,y,facing)
  U.teleport(game,pool.map,x,y,facing or'down');S.install(game);p.setLevel('voxel',camera);Q.settle()
 end
 local function roll(def)
  local old=love.math.random;local calls=0
  love.math.random=function(lo,hi)
   if lo==0 and hi==255 then calls=calls+1;return 0 end
   return old(lo,hi)
  end
  local ok,result=pcall(nativeRoll,game.overworld,def,'water');love.math.random=old;assert(ok,result)
  return result,calls
 end
 local rows={};local physical
 for _,pool in ipairs(E.plan.pools)do if pool.terrain=='water'then
  travel(pool,pool.anchor[1],pool.anchor[2])
  local live=E.encounters(game,pool.map);assert(live.water and live.water.rate>0)
  local picked,calls=roll({grass=live.water})
  rows[#rows+1]={map=pool.map,anchor=pool.anchor,expected=live.water.slots[1].species,actual=picked and picked.species,draws=calls,passed=picked~=nil and picked.species==live.water.slots[1].species}
  if E.bySpecies.FEEBAS.pool==pool then physical=pool end
 end end
 local f=assert(io.open(out..'/water-rolls.json','w'));f:write(require('src.link.Json').encode(rows));f:close()
 assert(physical)
 local ax,ay=physical.anchor[1],physical.anchor[2];travel(physical,ax,ay)
 local ow=game.overworld;local m=ow.map;local dir
 for _,d in ipairs{{-1,0,'right'},{1,0,'left'},{0,-1,'down'},{0,1,'up'}}do
  local x,y=ax+d[1],ay+d[2]
  if m:inBounds(x,y)and m:isWaterCell(x,y)and Q.pairClear(m,x,y,ax,ay)then
   travel(physical,x,y,d[3]);ow.player.surfing=true
   if require('src.world.Collision').canMove(m,ow.entities,ow.player,d[3])then dir=d[3];break end
  end
 end
 assert(dir);ow.wildEncounterGraceSteps=0;game.save.repelSteps=0
 local observed,draws
 ow.rollEncounter=function(self,def,terrain)
  observed=terrain;local result;result,draws=roll(def);return result
 end
 local from={ow.player.cellX,ow.player.cellY}
 for _=1,240 do
  if game.stack:top()~=ow or ow.player.cellX==ax and ow.player.cellY==ay then break end
  U.hold(game,dir,1)
 end
 for _=1,240 do if not ow.player.moving then break end;U.wait(1)end
 U.wait(20)
 local battle
 for _=1,900 do
  local top=game.stack:top()
  if top.enemy and top.enemy.mon then battle=top;if top.phase=='menu'then break end end
  if top==ow and not ow.player.moving then break end
  if top.enemy or top.isTextBox or top.pages then Q.tap('a')else U.wait(1)end
 end
 assert(ow.player.cellX==ax and ow.player.cellY==ay,'native water step reaches its authored cell')
 assert(U.shot(game,out..'/native-water-step.png'))
 local passed=true;for _,r in ipairs(rows)do if not r.passed then passed=false end end
 local receipt={passed=passed and battle~=nil and battle.phase=='menu',waterPools=#rows,rows=rows,physical={camera=p.level('voxel'),map=physical.map,from=from,to={ax,ay},terrain=observed,draws=draws,species=battle and battle.enemy.mon.species,phase=battle and battle.phase},scope='All owned water pools through the native encounter.roll hook, then a real Surf step at the Feebas habitat anchor. Champion/team/Gen4, travel, Surf flag and rate/slot RNG are fixtures. No encounter or species is injected.'}
 local f=assert(io.open(out..'/water-adapter.json','w'));f:write(require('src.link.Json').encode(receipt));f:close()
 print('SEVII_NATIVE_WATER_ADAPTER_FINISHED',#rows,tostring(receipt.passed),observed,tostring(battle~=nil))
 love.event.quit()
end
