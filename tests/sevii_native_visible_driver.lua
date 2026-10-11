-- Natural visible-spawn initialization; no testSpawn/forced species calls.
return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition
  Q.shot=function(name)assert(U.shot(game,out..'/visible-'..name..'.png'))end
  require('src.world.OverworldController').rollEncounter=function()return nil end
  game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  assert(K.beyondKanto.activate(game,{decision='qa-expanded-postleague-fixture'}))
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',70)}
  game.save.pokedex.owned.BLASTOISE=true
  game.mods.modOptions.kanto_ascendant.living_world_enabled=true
  game.mods.modOptions.kanto_ascendant.living_world_random_encounters=false
  game.mods.modOptions.kanto_ascendant.living_world_water=true
  game.mods.modOptions.kanto_ascendant.living_world_caves=true
  -- Use the actual settings owner so the chosen mode survives native load.
  local manager=require('src.mods.ManagerState').new(game)
  manager:setOption('kanto_ascendant','living_world_enabled',true)
  manager:setOption('kanto_ascendant','living_world_random_encounters',false)
  manager:setOption('kanto_ascendant','living_world_water',true)
  manager:setOption('kanto_ascendant','living_world_caves',true)
  local W=K.internalWilds.exports
  W.handleOptionsChanged{mod='kanto_ascendant',key='living_world_enabled',value=true}
  assert(S.begin(game))
  for _,id in ipairs{'heat','drift'}do local p=S.samples[id]
    U.teleport(game,p.map,p.x,p.y-1,'down');assert(S.collect(game,id))end
  assert(S.report());K.generationRules.resolve(game);S.install(game)
  local reports={}
  -- Authored rooms deliberately suppress extra visible/ambient bodies.
  local room=S.habitats.bySpecies.ROTOM.pool
  U.teleport(game,room.map,room.anchor[1],room.anchor[2],'down');Q.settle();U.wait(60)
  local allowed,why=K.wildsSpawnSafety.mapAllowed(game,game.overworld.map)
  assert(not allowed and why=='rejected: authored Sevii room','warehouse room safety policy')
  assert(not W.spawnSystemState().pipelineVerified and not next(W.logic.spawns),'authored room stays free of visible bodies')
  print('SEVII_VISIBLE_AUTHORED_ROOM_EXCLUSION_PASS',room.map)
  for _,id in ipairs({'TURTWIG','SNORUNT','FEEBAS'})do
    local target=S.habitats.bySpecies[id];local pool=target.pool
    U.teleport(game,pool.map,pool.anchor[1],pool.anchor[2],'down');Q.settle()
    print('SEVII_VISIBLE_ENTRY',id,tostring(W.logic:featureActive()),
      tostring(W.logic.activeMapId),tostring(W.logic.state.resetReason))
    -- Native load may refresh the active species authority after map.entered.
    -- Exercise the public next-step initialization before testing contact.
    if not W.spawnSystemState().pipelineVerified then
      local ow=game.overworld;ow.player.surfing=pool.terrain=='water'
      local moved=false
      for _,d in ipairs{'up','down','left','right'}do
        if require('src.world.Collision').canMove(ow.map,ow.entities,ow.player,d)then
          local x,y=ow.player.cellX,ow.player.cellY;U.hold(game,d,24);Q.settle()
          moved=ow.player.cellX~=x or ow.player.cellY~=y
          if moved then break end
        end
      end
      assert(moved,'visible habitat has a real initial movement step')
      print('SEVII_VISIBLE_AFTER_STEP',id,tostring(W.logic:featureActive()),
        tostring(W.logic.activeMapId),tostring(W.logic.state.resetReason))
    end
    U.wait(60);Q.settle()
    U.wait(120);Q.settle()
    U.wait(120)
    local rows={}
    for key,r in pairs(W.logic.spawns)do
      rows[#rows+1]={id=key,species=r.species,state=r.state,x=r.x,y=r.y,
        hasEntity=W.logic.entities[key]~=nil}
    end
    local state=W.spawnSystemState()
    print('SEVII_VISIBLE_MODE',id,tostring(game.mods.modOptions.kanto_ascendant.living_world_enabled),tostring(game.overworld.map.def.index),tostring(game.overworld.map.def.tileset))
    print('SEVII_VISIBLE_PROBE',id,#rows,require('src.link.Json').encode(state))
    assert(state.pipelineVerified and #rows>0,'natural visible spawn pipeline '..id)
    local valid={}
    for _,r in ipairs(pool.species)do valid[assert(S.habitats.resolve(game,r))]=true end
    for _,r in ipairs(rows)do assert(valid[r.species]and r.hasEntity,'visible species stays in authored pool')end
    local caught
    -- Place only the player next to an already naturally spawned entity.
    -- Species, spawn record and collision/battle hooks are never fabricated.
    for attempt=1,12 do
      if caught then break end
      -- Spawn effects run on elapsed time, while the accelerated driver
      -- counts simulation frames. Wait for a real battle-ready body before
      -- stepping onto it; an early contact legitimately despawns it safely.
      local ready=false
      for _=1,1200 do
        for key,r in pairs(W.logic.spawns)do
          local e=W.logic.entities[key]
          if r.state=='available'and valid[r.species]and e and e.canTriggerBattle
              and(not e.spawnFx or e.spawnFx.done)then ready=true;break end
        end
        if ready then break end
        U.wait(30)
      end
      assert(ready,'natural visible body finishes its entrance effect')
      local ow=game.overworld;local map=ow.map;local player=ow.player
      local choice,approach
      for _,r in pairs(W.logic.spawns)do
        local body=W.logic.entities[r.id]
        if r.state=='available'and valid[r.species]and body and body.canTriggerBattle
            and(not body.spawnFx or body.spawnFx.done)then
          for _,d in ipairs({{-1,0,'right'},{1,0,'left'},{0,-1,'down'},{0,1,'up'}})do
            local x,y=r.x+d[1],r.y+d[2]
            if map:inBounds(x,y)and(map:isWalkableCell(x,y)or map:isWaterCell(x,y))
                and not require('src.world.Collision').occupied(ow.entities,x,y,player)
                and Q.pairClear(map,x,y,r.x,r.y)and not map:warpAtCell(x,y)then choice=r;approach={x=x,y=y,dir=d[3]};break end
          end
          if choice then break end
        end
      end
      assert(choice,'approachable naturally spawned wild Pokemon')
      player.cellX=approach.x;player.cellY=approach.y;player.px=approach.x*16;player.py=approach.y*16
      player.moving=false;player.progress=0;player.facing=approach.dir;player.turnTimer=0;player.turnArmed=false
      player.surfing=map:isWaterCell(approach.x,approach.y)
      assert(U.shot(game,out..'/visible-'..id..'.png'))
      local en=W.logic.entities[choice.id];local occupied=require('src.world.Collision').occupied(ow.entities,choice.x,choice.y,player)
      print('VISIBLE_ENTITY',tostring(en and en.passable),tostring(en and en.hiddenBody),tostring(en and en.canTriggerBattle),en and en.cellX,en and en.cellY,tostring(occupied==en),tostring(W.isBattleableWild(en)),require('src.link.Json').encode(en and en.spawnFx or{}))
      U.hold(game,approach.dir,28)
      print('VISIBLE_CONTACT_ATTEMPT',attempt,choice.species,choice.x,choice.y,player.cellX,player.cellY,tostring(W.logic.pendingBattle),tostring(player.inputLocked),tostring(game.stack:top()==ow))
      for _=1,1800 do
        local t=game.stack:top()
        if t.enemy and t.enemy.mon and t.phase=='menu'then
          assert(W.logic.pendingBattle,'battle comes from a visible record')
          caught=t.enemy.mon.species;assert(valid[caught],'contact encounter keeps habitat identity');break
        end
        if t==game.overworld and not player.moving and not(ow.runner and ow.runner:isRunning())then break end
        Q.tap('a')
      end
    end
    assert(caught,'native collision opens visible encounter')
    Q.catch(caught,true,'down')
    assert(game.save.pokedex.owned[caught],'visible Pokemon actually caught')
    assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
    assert(game.save.pokedex.owned[caught],'visible catch survives reload')
    local stored=false;local seen={}
    local function scan(value)
      if type(value)~='table'or seen[value]then return end
      seen[value]=true
      if value.species==caught then stored=true end
      for _,v in pairs(value)do scan(v)end
    end
    scan(game.save.party);scan(game.save.box);scan(game.save.boxes)
    assert(stored,'visible catch remains in party/PC after reload')
    reports[#reports+1]={target=id,map=pool.map,terrain=pool.terrain,state=state,spawns=rows,caught=caught}
    print('SEVII_VISIBLE_CONTACT_CAPTURE_PASS',id,caught)
  end
  local f=assert(io.open(out..'/visible-probe.json','wb'))
  f:write(require('src.link.Json').encode({passed=true,scope='Natural visible spawns, native collision/contact, actual Master Ball capture and reload. Initial post-League/expanded fixtures, map teleports and adjacent player-position/surfing fixtures; no forced species/spawn/battle invocation.',maps=reports}));f:close()
  print('SEVII_NATIVE_VISIBLE_CONTACT_PASS',#reports)
  love.event.quit()
end
