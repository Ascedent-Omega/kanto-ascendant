-- Every target is selected through its real authored encounter pool and
-- hook chain; battles/captures/storage/save reload use the native engine.
-- Teleports and deterministic RNG are test setup, not a walking playthrough.
return function(game,afterCaptures)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util')
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=assert(game.mods.exports.kanto_ascendant);local S=assert(K.seviiExpedition)
  local E=S.habitats;local Json=require('src.link.Json')
  local OW=require('src.world.OverworldController');OW.rollEncounter=function()return nil end
  game:startNewGame{intro=false}
  game.save.options.colors='redpp';game:applyOptions()
  game.mods.modOptions.kanto_ascendant.living_world_enabled=false
  game.mods.modOptions.kanto_ascendant.living_world_random_encounters=true
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  assert(K.beyondKanto.activate(game,{decision='qa-expanded-postleague-fixture'}))
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',70)}
  assert(S.begin(game))
  for _,id in ipairs{'heat','drift'}do
    local p=S.samples[id];U.teleport(game,p.map,p.x,p.y-1,'down');assert(S.collect(game,id))
  end
  assert(S.report());K.generationRules.resolve(game);S.install(game)
  assert(E.coverage(game).available==218,'complete native art/identity catalogue required')
  local rows={};local wanted={}
  for id in (os.getenv('SEVII_CAPTURE_IDS')or''):gmatch('[^,]+')do
    assert(E.bySpecies[id],'unknown capture test target '..id);wanted[id]=true
  end
  for id,target in pairs(E.bySpecies)do
    if not next(wanted)or wanted[id]then rows[#rows+1]=target end
  end
  table.sort(rows,function(a,b)return a.row.dex<b.row.dex end)
  local report={passed=false,requested=#rows,captures={}}
  local function saveReport()
    local f=assert(io.open(out..'/'..(os.getenv('SEVII_CAPTURE_REPORT')or'captures-native.json'),'wb'));f:write(Json.encode(report));f:close()
  end
  local R=require('src.mods.Runtime');local Encounter=require('src.world.Encounter')
  for index,target in ipairs(rows)do
    local pool,row=target.pool,target.row
    local species=assert(E.resolve(game,row))
    U.teleport(game,pool.map,pool.anchor[1],pool.anchor[2],'down');Q.settle();S.install(game)
    local definition=game.data.encounters[pool.map]
    local native=pool.terrain=='water'and{grass=definition.water}or definition
    local selectedRoll
    for pick=0,255 do
      local call=0
      local rolled=Encounter.roll(native,function()call=call+1;return call==1 and 0 or pick end)
      if rolled and rolled.species==species then selectedRoll=pick;break end
    end
    assert(selectedRoll,'target not natively rollable '..row.id)
    local call=0
    local ctx={mapId=pool.map,terrain=pool.terrain,rng=function()call=call+1;return call==1 and 0 or selectedRoll end}
    local encounter=R.call('encounter.roll',function(def,c)return Encounter.roll(def,c.rng)end,native,ctx)
    assert(encounter and encounter.species==species,'live encounter hook substituted '..row.id)
    encounter=R.call('encounter.species',function(enc)return enc end,encounter,ctx)
    assert(encounter and encounter.species==species,'live species hook substituted '..row.id)
    local battle=require('src.battle.BattleState').newWild(game,encounter.species,encounter.level,
      {encounterSource=E.SOURCE,randomizerProtected=true})
    battle.onFinish=function(result)game.overworld:afterBattle(result,battle)end
    game.overworld:pushBattle(battle);game.save.inventory.MASTER_BALL=2
    for i=1,1800 do if game.stack:top()==battle and battle.phase=='menu'then break end;Q.tap('a')end
    assert(battle.phase=='menu','battle menu '..row.id)
    U.wait(90) -- Let the independent sprite entrance animation settle.
    local front=K.crystalAnimation.activeFrontMons[battle.enemy.mon]
    if front and front.source=='crystal'and front.requestedScale==nil then
      local _,height=battle.enemy.sprite:getDimensions()
      if height<=56 then
        local _,dy=K.crystalAnimation.enemyFrontOffset(battle)
        local top=8*(7-math.max(1,math.min(7,math.floor(height/8))))+dy
        assert(top>=0 and top+height<=56,'complete native Crystal front stays above the player HUD')
      end
    end
    if os.getenv('SEVII_CAPTURE_DEBUG') then
      local owner=K.crystalAnimation.activeFrontMons[battle.enemy.mon]
      print('SEVII_SPRITE',row.id,battle.enemy.sprite:getDimensions())
      for k,v in pairs(owner or{})do print('SEVII_SPRITE_OWNER',k,tostring(v))end
      print('SEVII_SPRITE_OFFSET',K.crystalAnimation.enemyFrontOffset(battle))
      print('SEVII_SPRITE_SCALE',K.crystalAnimation.battleScale(battle,'front',nil,species,game.data))
    end
    assert(U.shot(game,out..'/captures/'..row.dex..'-'..row.id..'.png'))
    Q.tap('down');assert(battle.menuIndex==3,'item navigation');Q.tap('a');U.wait(30)
    local found=false
    for pocket=1,8 do
      for _,item in ipairs(game.stack:top().items or{})do if item.value=='MASTER_BALL'then found=true end end
      if found then Q.choose(function(item)return item.value=='MASTER_BALL'end);break end
      Q.tap('right')
    end
    assert(found,'Master Ball fixture');U.wait(10)
    if game.stack:top().items then Q.choose(function(item)return item.value=='use'or item.label=='USE'end)end
    local finished=false
    for i=1,3000 do
      local top=game.stack:top()
      if top==game.overworld then finished=true;break
      elseif top.def and top.def.id==species and not top.enemy then Q.tap('b')
      elseif top.labels and top.onChoose then
        local desired=(game.save.inventory.MASTER_BALL or 0)==2 and 1 or 2
        if top.pending~=nil then U.wait(1)elseif top.index~=desired then Q.tap('down')else Q.tap('a')end
      else Q.tap('a')end
    end
    assert(finished,'capture UI stuck '..row.id);Q.settle()
    assert(game.save.pokedex.owned[species],'native caught receipt '..row.id)
    report.captures[#report.captures+1]={id=row.id,dex=row.dex,runtime=species,map=pool.map,terrain=pool.terrain}
    saveReport();print('SEVII_CAPTURE_PASS',index,#rows,row.id,species)
    if index%20==0 or index==#rows then
      assert(game:writeSave(),'capture save')
      game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
      for _,caught in ipairs(report.captures)do assert(game.save.pokedex.owned[caught.runtime],'capture receipt lost after reload')end
    end
  end
  -- Prove the actual captured identities survived in native party/PC storage.
  local stored={}
  local function scan(value,seen)
    if type(value)~='table'or seen[value]then return end;seen[value]=true
    if type(value.species)=='string' then stored[value.species]=true end
    for _,v in pairs(value)do if type(v)=='table'then scan(v,seen)end end
  end
  scan(game.save.party,{});scan(game.save.box,{});scan(game.save.boxes,{})
  for _,caught in ipairs(report.captures)do assert(stored[caught.runtime],'captured Pokemon missing from party/PC '..caught.id)end
  report.passed=true;saveReport()
  print('SEVII_NATIVE_ALL_CAPTURE_STORAGE_RELOAD_PASS',#rows)
  if afterCaptures then afterCaptures(game,report)end
  love.event.quit()
end
