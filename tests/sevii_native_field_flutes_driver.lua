return function(game)
 io.stdout:setvbuf('no')
 local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
 local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
 local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition;local F=K.seviiFieldFlutes
 local OW=require('src.world.OverworldController');local nativeRoll=OW.rollEncounter
 OW.rollEncounter=function()return nil end;OW.checkTrainerSight=function()end
 game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
 game.mods.modOptions.kanto_ascendant.living_world_enabled=false
 game.mods.modOptions.kanto_ascendant.living_world_random_encounters=true
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
 game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',100)};game.save.money=90000
 assert(K.beyondKanto.activate(game,{decision='qa-field-flutes'}))
 S.persist({version=1,stage=3,chapterOneComplete=true,samples={heat=true,drift=true}})
 S.install(game);K.generationRules.resolve(game)
 local function ready()
  for _=1,1800 do
   local t=game.stack:top();if t.items then return end
   if t.isTextBox or t.pages then Q.tap('a')else U.wait(1)end
  end
  error('shop menu missing')
 end
 local shop=S.population.recoveryShops[1]
 for _,id in ipairs{'BLACK_FLUTE','WHITE_FLUTE'}do
  U.teleport(game,shop.map,shop.x,shop.y+1,'up');Q.settle();Q.faceObject(shop.x,shop.y);Q.tap('a');ready()
  Q.choose(function(r)return r.label=='BUY'end);ready();Q.choose(function(r)return r.value==id end)
  local quantity=game.stack:top();assert(quantity.qty==1);Q.tap('a')
  local money=game.save.money;Q.answerChoice(true);Q.settle()
  assert(game.save.inventory[id]==1 and game.save.money==money-game.data.items[id].price,'native purchase '..id)
 end
 local function play(id)
  Q.bag(id);Q.settle();assert(game.save.inventory[id]==1,'reusable '..id)
 end
 local pool
 for _,p in ipairs(S.habitats.plan.pools)do if p.terrain=='grass'then pool=p;break end end
 assert(pool)
 local function approach()
  U.teleport(game,pool.map,pool.anchor[1],pool.anchor[2],'down');Q.settle()
  local map=game.overworld.map
  for y=2,map.heightCells-3 do for x=2,map.widthCells-3 do
   if map:isGrassCell(x,y)and map:isWalkableCell(x-1,y)and not map:warpAtCell(x,y)
       and not map:warpAtCell(x-1,y)and Q.pairClear(map,x-1,y,x,y)then
    local door=false;for _,w in ipairs(S.links[pool.map]or{})do if w.y==y and(w.x==x or w.x==x-1)then door=true end end
    if not door then
     U.teleport(game,pool.map,x-1,y,'right');Q.settle()
     if require('src.world.Collision').canMove(game.overworld.map,game.overworld.entities,game.overworld.player,'right')then return{x=x,y=y}end
    end
   end
  end end
  error('grass step approach missing')
 end
 local function step(target)
  local ow=game.overworld;ow.wildEncounterGraceSteps=0;game.save.repelSteps=0
  local base=game.data.encounters[pool.map].grass.rate;local gate=math.floor(base*.75)
  local calls,rolled=0
  ow.rollEncounter=function(self,def,terrain)
   local native=love.math.random
   love.math.random=function(lo,hi)
    if lo==0 and hi==255 then calls=calls+1;return calls==1 and gate or 0 end
    return native(lo,hi)
   end
   local ok,result=pcall(nativeRoll,self,def,terrain);love.math.random=native;assert(ok,result);rolled=result;return result
  end
  U.hold(game,'right',1)
  for _=1,180 do if not ow.player.moving then break end;U.wait(1)end
  U.wait(10);ow.rollEncounter=nil
  assert(ow.player.cellX==target.x and ow.player.cellY==target.y,'physical grass step completed')
  return calls,rolled
 end
 local target=approach();play('BLACK_FLUTE');assert(F.state(game).item=='BLACK_FLUTE')
 assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
 assert(F.state(game).item=='BLACK_FLUTE','saved flute retained in same area')
 target=approach();local calls,rolled=step(target)
 assert(calls==1 and not rolled and game.stack:top()==game.overworld,'black suppresses this ordinary native rate outcome')
 target=approach();play('WHITE_FLUTE');assert(F.state(game).item=='WHITE_FLUTE')
 calls,rolled=step(target);assert(calls==2 and rolled,'white admits native rate plus one slot draw')
 local b
 for _=1,1800 do local t=game.stack:top();if t.enemy and t.phase=='menu'then b=t;break end;Q.tap('a')end
 assert(b and b.enemy.mon.species==rolled.species,'physical ordinary battle starts')
 assert(b:chooseMenu('run'),'native RUN action')
 for _=1,1800 do if game.stack:top()==game.overworld then break end;Q.tap('a')end;Q.settle()
 assert(F.state(game).item=='WHITE_FLUTE','battle does not end area effect')
 play('WHITE_FLUTE');assert(not F.state(game),'native Bag reuse stops effect')
 play('BLACK_FLUTE')
 assert(K.generationRules.switchMode(game,'gen2'))
 local result=require('src.inventory.ItemEffects').use(game.data,game.save,'WHITE_FLUTE',nil,nil,nil,game.overworld)
 assert(result=='failed'and F.state(game).item=='BLACK_FLUTE','older rules refuse flute activation')
 local definition=game.data.encounters[pool.map]
 assert(F.adjust(game,definition,{mapId=pool.map,terrain='grass'})==definition,'older rules suspend effect')
 assert(K.generationRules.switchMode(game,'auto'))
 -- Physical map entries: fragments retain an area, a different area clears
 -- it permanently. Travel is a fixture, not a test of every connecting path.
 local grouped={};local pair
 for id,m in pairs(S.maps)do if m.kaSeviiSource then
  local cell
  for y=2,m.height*2-3 do for x=2,m.width*2-3 do if not cell and S.walkable(id,x,y)then cell={map=id,x=x,y=y}end end end
  if cell then if grouped[m.kaSeviiSource]then pair={grouped[m.kaSeviiSource],cell};break end;grouped[m.kaSeviiSource]=cell end
 end end
 assert(pair)
 local function travel(p)U.teleport(game,p.map,p.x,p.y,'down');Q.settle()end
 travel(pair[1]);if F.state(game)then play(F.state(game).item)end
 play('WHITE_FLUTE');travel(pair[2]);assert(F.state(game).item=='WHITE_FLUTE','same source area survives fragment transition')
 U.teleport(game,'VERMILION_CITY',18,12,'down');Q.settle();assert(not F.state(game),'other area clears effect')
 travel(pair[1]);assert(not F.state(game),'return does not reactivate old effect')
 -- Actual roaming hook stays outside the ordinary rate adapter.
 game.save.inventory.HOENN_HONEY=1;game.save.inventory.HOENN_DEX=1
 local s=S.state();s.expeditionComplete=true;s.seviiRiftSealed=true;S.persist(s)
 local R=K.hoennRoamers67;assert(R.initialize(game));approach()
 local state=R.state(false);state.roamers.LATIAS.map=pool.map;state.roamers.LATIOS.map='ROUTE_25';R.persist(state)
 for _,id in ipairs{'BLACK_FLUTE','WHITE_FLUTE'}do
  play(id);assert(F.state(game).item==id)
  local hits=0;local adjust=F.adjust;local leafCalls=0
  F.adjust=function(...)leafCalls=leafCalls+1;return adjust(...)end
  for roll=1,20 do
   local random=love.math.random;local probabilityDraws=0
   love.math.random=function(lo,hi)
    if lo==1 and hi==20 then probabilityDraws=probabilityDraws+1;return roll end
    if lo==0 and hi==255 then return 255 end
    return random(lo,hi)
   end
   local before=leafCalls;local ok,enc=pcall(nativeRoll,game.overworld,game.data.encounters[pool.map],'grass')
   love.math.random=random;assert(ok,enc);assert(probabilityDraws==1,'one local 5-percent trial')
   if enc and enc.kaEncounterSource=='hoenn_roamer'then
    hits=hits+1;assert(leafCalls==before,'roamer bypasses ordinary flute modifier')
   end
  end
  F.adjust=adjust;assert(hits==1,'unchanged 5-percent probability '..id)
 end
 assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
 assert(game.save.inventory.BLACK_FLUTE==1 and game.save.inventory.WHITE_FLUTE==1,'both purchased flutes survive final reload')
 local f=assert(io.open(out..'/field-flutes.json','wb'))
 f:write(require('src.link.Json').encode({passed=true,shopPurchases=2,physicalGrassMissAndBattle=true,
  savedAreaEffect=true,fragmentContinuity=true,areaExitClears=true,repeatUseStops=true,
  generationGate=true,eonRollsPerFlute=20,eonHitsPerFlute=1,
  fixtures='Post-League/team, story profile, travel, rate RNG and roamer current locations; ordinary physical step battle uses native encounter/battle/Run, shop and Bag use native menus. Not a balance playthrough.'}));f:close()
 print('SEVII_FIELD_FLUTES_NATIVE_PASS');love.event.quit()
end
