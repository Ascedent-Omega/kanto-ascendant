return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition;local T=assert(S.trainers)
  local Pokemon=require('src.pokemon.Pokemon');local Save=require('src.core.SaveData')
  local fillRewardPocket=dofile(root..'/tests/sevii_native_bag_fixture.lua')
  local Pilot=dofile(root..'/tests/sevii_battle_pilot.lua')(game,Q)
  local restoreBag
  require('src.world.OverworldController').rollEncounter=function()return nil end
  game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
  game.mods.modOptions.kanto_ascendant.living_world_enabled=false
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
  local function player(lose)
    local mon=Pokemon.new(game.data,lose and'MAGIKARP'or'MEWTWO',lose and 5 or 100)
    mon.moves={{id=lose and'SPLASH'or'ICE_BEAM',pp=40}}
    if lose then mon.hp=1 end
    local partner=Pokemon.new(game.data,lose and'MAGIKARP'or'BLASTOISE',lose and 5 or 100)
    partner.moves={{id=lose and'SPLASH'or'ICE_BEAM',pp=40}}
    if lose then partner.hp=1 end
    game.save.party={mon,partner}
  end
  local function visit(row)
    U.teleport(game,row.map,row.x,row.y+1,'up');Q.settle();Q.tap('a');U.wait(8)
  end
  local function choose(value)
    local top=game.stack:top();assert(top.items,'trainer challenge menu')
    local wanted;for i,item in ipairs(top.items)do if item.value==value then wanted=i end end
    assert(wanted,'missing trainer choice '..value)
    for _=1,20 do if top.index==wanted then Q.tap('a');return end;Q.tap(top.index>wanted and'up'or'down')end
    error('trainer choice did not settle')
  end
  local function fight(row,lose,accelerate)
    visit(row);choose('battle')
    local battle
    for _=1,600 do
      for _,state in ipairs(game.stack.states)do if state.seviiTrainerKey==row.id then battle=state end end
      if battle then break end;U.wait(1)
    end
    assert(battle and battle.kind=='trainer'and #battle.enemyParty==3,'native three-Pokemon trainer battle')
    local intended=assert(T.team(game,row))
    for i,mon in ipairs(battle.enemyParty)do
      assert(mon.species==intended[i].species and mon.level==intended[i].level,'authored team retained '..row.id)
    end
    assert(not T.start(game,row.id),'second start rejected during battle')
    -- Do not claim a balance test: later cases shorten enemy HP only after
    -- checking all authored identities/levels. First win and loss are normal.
    if accelerate then for _,mon in ipairs(battle.enemyParty)do mon.hp=1 end;battle.enemy.shownHP=1 end
    battle.rng=function(a,b)return a or 0 end
    if row.id=='BEACH'and not lose then
      for _=1,1800 do if game.stack:top()==battle and battle.phase=='menu'then break end;Q.tap('a')end
      U.wait(60);assert(U.shot(game,out..'/sevii-trainer-mira.png'))
    end
    for _=1,12000 do
      if game.stack:top()==game.overworld then break end
      local top=game.stack:top()
      if top.battle==battle and top.forceSwitch and top.onSwitch then
        Pilot.selectReplacement(top,Pilot.bestReplacement(battle,top.party or game.save.party))
      elseif top==battle and battle.phase=='doubleTarget' and battle.enemy2 then
        local target=battle.doubleTargetIndex==1 and battle.enemy or battle.enemy2
        if target.mon.hp<=0 then Q.tap('right')else Q.tap('a')end
      elseif top.labels and top.onChoose then Q.tap('b')else Q.tap('a')end
    end
    assert(game.stack:top()==game.overworld,'battle ended '..row.id);Q.settle()
    assert(battle.result==(lose and'lose'or'win'),'expected native result '..row.id)
    assert((T.record(row.id).won==true)==not lose,'victory receipt only on win')
    return battle
  end
  assert(#T.rows==14,'fourteen island trainers')
  player(false);visit(T.rows[1]);Q.settle();assert(not T.start(game,T.rows[1].id),'pre-League gate')
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  S.persist({version=1,stage=3,chapterOneComplete=true,samples={heat=true,drift=true}})
  K.generationRules.resolve(game);S.install(game)
  -- Declining a challenge must release the NPC and award nothing.
  visit(T.rows[1]);choose('leave');Q.settle();assert(not T.record('BEACH').won)
  player(true);fight(T.rows[1],true,false)
  assert(game.overworld.map.id~=T.rows[1].map,'native blackout returns to heal point')
  assert(not T.record('BEACH').claimed,'loss has no item receipt')
  for index,row in ipairs(T.rows)do
    player(false)
    local ready=game.data.items[row.reward].kascEquipmentRewardEpochs
    assert(ready and ready[4],'working reward in normal Sevii profile '..row.reward)
    if index==1 then restoreBag=fillRewardPocket(game,row.reward)else game.save.inventory[row.reward]=0 end
    if index==1 then for _,mon in ipairs(game.save.party)do mon.moves={{id='THUNDERBOLT',pp=40}}end end
    local battle=fight(row,false,index~=1)
    if index==1 then
      assert(not T.record(row.id).claimed and game.save.inventory[row.reward]==99,'full Bag keeps reward pending')
      assert(game:writeSave());game:restoreSave(assert(Save.load('red')));Q.settle()
      assert(T.record(row.id).won and not T.record(row.id).claimed,'pending reward reload')
      restoreBag()
      game.save.inventory[row.reward]=0;visit(row);Q.settle()
    end
    assert(T.record(row.id).claimed and game.save.inventory[row.reward]==1,'exactly one item '..row.id)
    local money=game.save.money
    visit(row);Q.settle();assert(game.save.inventory[row.reward]==1 and game.save.money==money,'repeat talk cannot duplicate reward')
    assert(not T.start(game,row.id),'no repeat prize battle')
    -- A duplicated native finish callback cannot issue another item or warp.
    battle.onFinish('win');assert(game.save.inventory[row.reward]==1 and game.save.money==money)
    print('SEVII_NATIVE_TRAINER_PASS',index,row.id,row.reward)
  end
  assert(game:writeSave());game:restoreSave(assert(Save.load('red')));Q.settle()
  for _,row in ipairs(T.rows)do assert(T.record(row.id).won and T.record(row.id).claimed,'all victories and rewards survive reload')end
  print('SEVII_NATIVE_TRAINERS_PASS','14 victories, one natural blackout, one full-HP win, 13 accelerated HP fixtures, full-Bag retry, no duplicates, save/reload')
  love.event.quit()
end
