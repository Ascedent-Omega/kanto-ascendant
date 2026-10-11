-- Real physical steps trigger the native overworld roll and battle push.
-- Only the roll's RNG is controlled; map terrain, guards and hook dispatch
-- are the ordinary engine path. Native capture/storage is tested separately.
return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util')
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=assert(game.mods.exports.kanto_ascendant);local S=assert(K.seviiExpedition);local E=S.habitats
  local OW=require('src.world.OverworldController');local nativeRoll=OW.rollEncounter
  OW.rollEncounter=function()return nil end -- Fixture travel only.
  game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
  game.mods.modOptions.kanto_ascendant.living_world_enabled=false
  game.mods.modOptions.kanto_ascendant.living_world_random_encounters=true
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  assert(K.beyondKanto.activate(game,{decision='qa-expanded-postleague-fixture'}))
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'JOLTEON',100)}
  assert(S.begin(game))
  for _,id in ipairs{'heat','drift'}do
    local p=S.samples[id];U.teleport(game,p.map,p.x,p.y-1,'down');assert(S.collect(game,id))
  end
  assert(S.report());K.generationRules.resolve(game);S.install(game)
  local results={};local Encounter=require('src.world.Encounter');local Collision=require('src.world.Collision')
  local targets={'TURTWIG','ROTOM','FEEBAS'}
  if os.getenv('SEVII_WALK_ALL')=='1'then
    targets={}
    for _,pool in ipairs(E.plan.pools)do targets[#targets+1]=pool.species[1].id end
  end
  for _,id in ipairs(targets)do
    local target=assert(E.bySpecies[id]);local pool=target.pool;local expected=assert(E.resolve(game,target.row))
    local ax,ay=pool.anchor[1],pool.anchor[2]
    U.teleport(game,pool.map,ax,ay,'down');Q.settle();S.install(game)
    local map=game.overworld.map
    assert(pool.terrain=='water'and map:isWaterCell(ax,ay)
      or pool.terrain=='grass'and map:isGrassCell(ax,ay)
      or pool.terrain=='indoor'and map:isWalkableCell(ax,ay),'native terrain matches habitat')
    local def=E.encounters(game,pool.map) -- current time/weather-weighted native catalogue
    local native=pool.terrain=='water'and{grass=def.water}or def
    local roll
    for n=0,255 do
      local calls=0;local pick=Encounter.roll(native,function()calls=calls+1;return calls==1 and 0 or n end)
      if pick and pick.species==expected then roll=n;break end
    end
    assert(roll,'target probability bucket exists')
    local direction
    for _,d in ipairs{{-1,0,'right'},{1,0,'left'},{0,-1,'down'},{0,1,'up'}}do
      local x,y=ax+d[1],ay+d[2]
      if map:inBounds(x,y)and (pool.terrain=='water'and map:isWaterCell(x,y)
          or pool.terrain~='water'and map:isWalkableCell(x,y))then
        U.teleport(game,pool.map,x,y,d[3]);Q.settle()
        local ow=game.overworld;ow.player.surfing=pool.terrain=='water'
        if Collision.canMove(ow.map,ow.entities,ow.player,d[3])then direction=d[3];break end
      end
    end
    assert(direction,'walkable native approach to encounter anchor')
    local ow=game.overworld;ow.wildEncounterGraceSteps=0;game.save.repelSteps=0
    local observed
    ow.rollEncounter=function(self,encDef,terrain)
      observed=terrain
      local originalRandom=love.math.random;local calls=0
      love.math.random=function()calls=calls+1;return calls==1 and 0 or roll end
      local ok,result=pcall(nativeRoll,self,encDef,terrain)
      love.math.random=originalRandom
      assert(ok,result);return result
    end
    for frame=1,180 do
      if game.stack:top()~=ow then break end
      if not ow.player.moving then U.hold(game,direction,1)else U.wait(1)end
    end
    local battle
    for frame=1,1800 do
      local top=game.stack:top()
      if top.enemy and top.enemy.mon then battle=top;if battle.phase=='menu'then break end end
      Q.tap('a')
    end
    assert(battle and battle.enemy.mon.species==expected,'native walking battle '..id)
    assert(observed==pool.terrain,'native terrain dispatch '..id..': '..tostring(observed))
    assert(ow.player.cellX==ax and ow.player.cellY==ay,'battle starts on authored physical cell')
    U.wait(60);assert(U.shot(game,out..'/walking-'..id..'.png'))
    results[#results+1]={id=id,map=pool.map,terrain=observed,surfing=ow.player.surfing==true}
    assert(battle:chooseMenu('run'),'native RUN action')
    for frame=1,1800 do if game.stack:top()==ow then break end;Q.tap('a')end
    Q.settle();assert(game.stack:top()==ow,'native run returns to overworld')
    ow.rollEncounter=nil
    print('SEVII_NATIVE_WALKING_ENCOUNTER',id,observed,pool.map)
  end
  local f=assert(io.open(out..'/'..(os.getenv('SEVII_WALK_REPORT')or'walking-encounters.json'),'wb'))
  f:write(require('src.link.Json').encode({passed=true,results=results}));f:close()
  OW.rollEncounter=nativeRoll
  print('SEVII_NATIVE_WALKING_ENCOUNTERS_PASS',#results)
  love.event.quit()
end
