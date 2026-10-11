return function(game)
 io.stdout:setvbuf('no')
 local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
 local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
 local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition;local B=K.seviiBalls
 local OW=require('src.world.OverworldController');local nativeRoll=OW.rollEncounter
 local Json=require('src.link.Json');local CP=require('src.core.Checkpoint')
 OW.rollEncounter=function()return nil end
 game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
 game.mods.modOptions.kanto_ascendant.living_world_enabled=false
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true;game.save.money=90000
 game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',100)}
 game.save.inventory.OLD_ROD=1
 assert(K.beyondKanto.activate(game,{decision='qa-dive-ball'}))
 S.persist({version=1,stage=3,chapterOneComplete=true,samples={heat=true,drift=true}})
 S.install(game);K.generationRules.resolve(game)
 local function menu(match)
  for _=1,1800 do if game.stack:top().items then Q.choose(match);return end;Q.tap('a')end
  error('native menu missing')
 end
 local shop=S.population.researchBallShop
 U.teleport(game,shop.map,shop.x,shop.y+1,'up');Q.settle();Q.tap('a')
 menu(function(r)return r.label=='BUY'end);menu(function(r)return r.value=='DIVE_BALL'end)
 Q.tap('up');Q.tap('up');assert(game.stack:top().qty==3);Q.tap('a')
 local money=game.save.money;Q.answerChoice(true);Q.settle()
 assert(game.save.inventory.DIVE_BALL==3 and game.save.money==money-3*game.data.items.DIVE_BALL.price,'three purchased balls')
 local function waitBattle()
  for _=1,2400 do local t=game.stack:top();if t.enemy and t.enemy.mon and t.phase=='menu'then U.wait(15);return t end;Q.tap('a')end
  error('native battle missing')
 end
 local function throw(b)
  assert(b:chooseMenu('item'));U.wait(12)
  local found=false
  for _=1,8 do
   for _,r in ipairs(game.stack:top().items or{})do if r.value=='DIVE_BALL'then found=true;break end end
   if found then menu(function(r)return r.value=='DIVE_BALL'end);break end
   Q.tap('right')
  end
  assert(found,'purchased ball in Bag');U.wait(10)
  if game.stack:top().items then menu(function(r)return r.value=='use'or r.label=='USE'end)end
 end
 local function count(species)
  local n=0;for _,m in ipairs(game.save.party)do if m.species==species then n=n+1 end end
  for _,box in ipairs(game.save.boxes or{})do for _,m in ipairs(box)do if m.species==species then n=n+1 end end end
  return n
 end
 local function catch(b)
  local species=b.enemy.mon.species;local before=count(species);local stock=game.save.inventory.DIVE_BALL
  b.rng=function(lo)return lo end;throw(b)
  for _=1,3000 do local t=game.stack:top()
   if t==game.overworld then break
   elseif t.def and t.def.id==species and not t.enemy then Q.tap('b')
   elseif t.labels and t.onChoose then
    local wanted=game.save.inventory.DIVE_BALL==stock and 1 or 2
    if t.pending~=nil then U.wait(1)elseif t.index~=wanted then Q.tap('down')else Q.tap('a')end
   else Q.tap('a')end
  end
  Q.settle();assert((game.save.inventory.DIVE_BALL or 0)==stock-1 and count(species)==before+1,'native catch consumes and stores once')
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  assert(count(species)==before+1 and(game.save.inventory.DIVE_BALL or 0)==stock-1,'catch and consumption survive reload')
  return species
 end
 -- Physical water step. Travel, Surf mode and a selected rate/slot draw are
 -- fixtures; the actual map collision, encounter dispatcher and start event run.
 local pool,slotDraw,expected
 for _,p in ipairs(S.habitats.plan.pools)do if p.terrain=='water'and not pool then
  local definition=game.data.encounters[p.map]
  for draw=0,255 do
   local calls=0;local row=require('src.world.Encounter').roll({grass=definition.water},function()calls=calls+1;return calls==1 and 0 or draw end)
   local d=row and game.data.pokemon[row.species]
   -- A 255-rate target can be an automatic catch at x3.5 even at full HP.
   -- Pick an actual authored slot that permits a failed throw, without
   -- changing the target's catch rate or the production catch calculation.
   if d and d.catchRate<=200 then pool,slotDraw,expected=p,draw,row.species;break end
  end
 end end
 assert(pool,'water species with non-guaranteed full-HP catch')
 local ax,ay=pool.anchor[1],pool.anchor[2];U.teleport(game,pool.map,ax,ay,'down');Q.settle()
 local map=game.overworld.map;local direction
 for _,d in ipairs{{-1,0,'right'},{1,0,'left'},{0,-1,'down'},{0,1,'up'}}do
  if map:inBounds(ax+d[1],ay+d[2])and map:isWaterCell(ax+d[1],ay+d[2])then
   U.teleport(game,pool.map,ax+d[1],ay+d[2],d[3]);Q.settle();game.overworld.player.surfing=true
   if require('src.world.Collision').canMove(map,game.overworld.entities,game.overworld.player,d[3])then direction=d[3];break end
  end
 end
 assert(direction);local ow=game.overworld;ow.wildEncounterGraceSteps=0;game.save.repelSteps=0
 ow.rollEncounter=function(self,def,terrain)
  assert(terrain=='water');local random=love.math.random;local calls=0
  love.math.random=function()calls=calls+1;return calls==1 and 0 or slotDraw end
  local ok,result=pcall(nativeRoll,self,def,terrain);love.math.random=random;assert(ok,result);return result
 end
 U.hold(game,direction,1);local b=waitBattle();ow.rollEncounter=nil
 assert(ow.player.cellX==ax and ow.player.cellY==ay and b.enemy.mon.species==expected and B.quote('DIVE_BALL',b).multiplier==3.5,'actual water encounter receives bonus')
 assert(K.apricornBalls.quote('LURE_BALL',{battle=b,targetMon=b.enemy.mon,targetDef=b.enemy.def}).multiplier==1,'Lure Ball does not mistake Surf for fishing')
 local snapshot,why=CP.capture(game);assert(snapshot,'water checkpoint capture '..tostring(why))
 local f=assert(io.open(out..'/dive-water-checkpoint.json','wb'));f:write(Json.encode(snapshot));f:close()
 f=assert(io.open(out..'/dive-water-checkpoint.json','rb'));local saved=Json.decode(f:read('*a'));f:close()
 local ok,reason=CP.restore(game,saved);assert(ok,'water checkpoint restore '..tostring(reason));b=waitBattle()
 assert(B.quote('DIVE_BALL',b).multiplier==3.5 and B.validateCheckpoint(b),'restored battle retains exact environment')
 assert(B.quote('DIVE_BALL',b).odds<255,'failed-throw fixture is not an automatic catch')
 b.rng=function(_,hi)return hi end;throw(b);b=waitBattle()
 assert(game.save.inventory.DIVE_BALL==2 and B.completedTurns(b)==1,'failed Dive throw consumes once and takes a turn')
 assert(U.shot(game,out..'/dive-water-battle.png'));local waterSpecies=catch(b)
 -- The Old Rod's real shore path stamps fishing. Merely standing beside
 -- water or facing it would not make a land battle a water encounter.
 U.teleport(game,'VERMILION_CITY',18,12,'down');Q.settle();map=game.overworld.map
 local shore
 for y=2,map.heightCells-3 do for x=2,map.widthCells-3 do
  if not shore and map:isWalkableCell(x,y)and not map:isWaterCell(x,y)and not map:warpAtCell(x,y)then
   for _,d in ipairs{{0,1,'down'},{0,-1,'up'},{1,0,'right'},{-1,0,'left'}}do
    if map:isWaterCell(x+d[1],y+d[2])then shore={x=x,y=y,dir=d[3]};break end
   end
  end
 end end
 assert(shore);U.teleport(game,'VERMILION_CITY',shore.x,shore.y,shore.dir);Q.settle()
 game.overworld.player.surfing=false -- travel fixture must leave the earlier water mount
 assert(game.overworld:facingIsShoreOrWater(),'native fishable shore')
 Q.bag('OLD_ROD');b=waitBattle()
 assert(b.encounterSource=='fishing'and not game.overworld.player.surfing,'native shore fishing receipt')
 assert(B.quote('DIVE_BALL',b).multiplier==3.5,'fishing receives bonus from shore')
 assert(K.apricornBalls.quote('LURE_BALL',{battle=b,targetMon=b.enemy.mon,targetDef=b.enemy.def}).multiplier==3,'existing Lure Ball gets actual hooked provenance')
 local fishSpecies=catch(b)
 assert((game.save.inventory.DIVE_BALL or 0)==0,'all three purchased balls consumed')
 f=assert(io.open(out..'/dive-ball.json','wb'));f:write(Json.encode({passed=true,water=waterSpecies,fishing=fishSpecies,checkpointRestored=true,purchased=3,failedThrows=1,captures=2,
  scope='Native purchase, physical water step, JSON checkpoint restore, failed throw/turn, actual water and Old Rod shore catches with normal save/load. Post-League/team/rod, travel, Surf mode and encounter/capture random values are explicit fixtures; not a balance or field-move unlock test.'}));f:close()
 print('SEVII_NATIVE_DIVE_BALL_PASS',waterSpecies,fishSpecies);love.event.quit()
end
