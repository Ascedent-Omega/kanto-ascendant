return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition;local T=assert(S.trainers);local C=assert(S.tower)
  local Pokemon=require('src.pokemon.Pokemon');local Save=require('src.core.SaveData')
  local fillRewardPocket=dofile(root..'/tests/sevii_native_bag_fixture.lua');local restoreBag
  local Pilot=dofile(root..'/tests/sevii_battle_pilot.lua')(game,Q)
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
    assert(game.overworld.map.id==row.map,'physical arrival at '..row.id);Q.faceObject(row.x,row.y);Q.tap('a');U.wait(8)
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
    -- This driver checks tower progression. The separate balance run covers
    -- full-HP fights; shorten winning fights after checking authored teams.
    if accelerate then for _,mon in ipairs(battle.enemyParty)do mon.hp=1 end;battle.enemy.shownHP=1 end
    battle.rng=function(a,b)return a or 0 end
    if row.id=='TOWER_1'and not lose then
      for _=1,1800 do if game.stack:top()==battle and battle.phase=='menu'then break end;Q.tap('a')end
      U.wait(60);assert(U.shot(game,out..'/sevii-tower-battle.png'))
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
  Q.extraWarpAt=function(m,x,y)
    for _,w in ipairs(S.links[m.id]or{})do if w.x==x and w.y==y then return true end end
    return false
  end
  local function stairs(target)
    local link;for _,w in ipairs(S.links[game.overworld.map.id])do if w.map==target then link=w;break end end
    assert(link,'tower stair to '..target);Q.walkTo(link.x,link.y,target);Q.settle()
    assert(game.overworld.map.id==target,'physical stair arrival')
  end
  player(false)
  U.teleport(game,C.rows[1].map,6,13,'up');Q.settle()
  assert(not T.start(game,C.rows[1].id),'pre-League tower gate')
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  S.persist({version=1,stage=3,chapterOneComplete=true,samples={heat=true,drift=true}})
  K.generationRules.resolve(game);S.install(game)
  U.teleport(game,C.rows[2].map,6,13,'up');Q.settle()
  local ok,why=T.start(game,C.rows[2].id);assert(not ok and why=='previous-floor-required','out-of-order battle blocked')
  visit(C.rows[2]);Q.settle();assert(C.progress()==0,'out-of-order talk awards nothing')
  U.teleport(game,C.roof.map,7,9,'up');Q.settle();assert(not C.complete(game),'early roof visit awards no title')
  U.teleport(game,C.rows[1].map,6,13,'up');Q.settle()
  player(true);fight(C.rows[1],true,false);assert(C.progress()==0,'loss has no floor victory')
  assert(game.overworld.map.id~=C.rows[1].map,'native blackout')
  -- All floor changes after this entrance use actual stairs. Healthy party
  -- and deterministic combat RNG are fixtures, not a balance assertion.
  U.teleport(game,C.lobby.map,9,14,'up');Q.settle()
  Q.faceObject(C.lobby.x,C.lobby.y);Q.tap('a');Q.settle()
  stairs(C.rows[1].map)
  for i,row in ipairs(C.rows)do
    player(false)
    assert(game.data.items[row.reward].kascEquipmentRewardEpochs[4],'reward effect ready '..row.reward)
    if i==4 then restoreBag=fillRewardPocket(game,row.reward)else game.save.inventory[row.reward]=0 end
    visit(row);assert(U.shot(game,out..'/sevii-tower-challenge-'..i..'.png'));choose('leave');Q.settle()
    local battle=fight(row,false,true)
    assert(C.progress()==i,'ordered floor count')
    if i==4 then
      assert(not T.record(row.id).claimed,'full Bag preserves floor prize')
      assert(game:writeSave());game:restoreSave(assert(Save.load('red')));Q.settle()
      assert(C.progress()==4 and not T.record(row.id).claimed,'mid-tower reload')
      restoreBag();game.save.inventory[row.reward]=0;visit(row);Q.settle()
    end
    assert(T.record(row.id).claimed and game.save.inventory[row.reward]==1,'floor prize once')
    battle.onFinish('win');assert(game.save.inventory[row.reward]==1,'duplicate callback harmless')
    if i<8 then stairs(C.rows[i+1].map)else stairs(C.roof.map)end
    print('SEVII_TOWER_FLOOR_PASS',i,row.reward)
  end
  assert(not S.state().towerComplete,'title needs roof ceremony')
  restoreBag=fillRewardPocket(game,'LUCKY_EGG')
  Q.faceObject(C.roof.x,C.roof.y);Q.tap('a');Q.settle()
  assert(not S.state().towerComplete and game.save.inventory.LUCKY_EGG==99,
    'full Bag defers both champion title and unique Lucky Egg')
  restoreBag();game.save.inventory.LUCKY_EGG=0
  Q.faceObject(C.roof.x,C.roof.y);Q.tap('a');U.wait(15)
  assert(U.shot(game,out..'/sevii-tower-champion.png'));Q.settle()
  assert(S.state().towerComplete and game.save.inventory.LUCKY_EGG==1,
    'roof ceremony grants one Lucky Egg with persistent title')
  assert(not C.complete(game),'ceremony idempotent')
  assert(game:writeSave());game:restoreSave(assert(Save.load('red')));Q.settle()
  assert(S.state().towerComplete and C.progress()==8 and game.save.inventory.LUCKY_EGG==1,
    'title, eight victories and unique egg reload')
  stairs(C.rows[8].map)
  for i=8,1,-1 do
    visit(C.rows[i]);Q.settle();assert(game.save.inventory[C.rows[i].reward]==1,'descent cannot duplicate prize')
    stairs(i>1 and C.rows[i-1].map or C.lobby.map)
  end
  local exit;for _,w in ipairs(S.links[C.lobby.map])do if S.maps[w.map].kaSeviiSource=='SevenIsland_TrainerTower'then exit=w end end
  assert(exit);Q.walkTo(exit.x,exit.y,exit.map);Q.settle()
  assert(game.overworld.map.id==exit.map,'tower has physical return to island')
  local trainee=Pokemon.new(game.data,'BLASTOISE',40)
  trainee.moves={{id='ICE_BEAM',pp=10}}
  game.save.party={trainee}
  local equipment=K.pokemonEquipment67
  assert(equipment.openNative(game,trainee),'native equipment menu for Lucky Egg')
  choose('give');choose('LUCKY_EGG');Q.settle()
  trainee=game.save.party[1]
  assert(equipment.heldId(trainee)=='LUCKY_EGG'and (game.save.inventory.LUCKY_EGG or 0)==0,
    'actual tower reward equipped, not copied')
  local Experience=require('src.battle.Experience')
  local base=Experience.gainFor(game.data.pokemon.MAGIKARP,5,false,1,false,game.data.constants)
  local before=trainee.exp
  local battle=require('src.battle.BattleState').newWild(game,'MAGIKARP',5,{randomizerProtected=true})
  battle.onFinish=function(result)game.overworld:afterBattle(result,battle)end
  battle.rng=function(lo)return lo end
  game.overworld:pushBattle(battle)
  for _=1,3000 do
    if game.stack:top()==game.overworld then break end
    Q.tap('a')
  end
  assert(game.stack:top()==game.overworld and battle.result=='win','native trainee wins actual wild battle')
  Q.settle()
  assert(trainee.exp-before==math.floor(base*1.5),'held Lucky Egg multiplies actual battle experience')
  assert(game:writeSave());game:restoreSave(assert(Save.load('red')));Q.settle()
  assert(equipment.heldId(game.save.party[1])=='LUCKY_EGG'and game.save.party[1].exp==trainee.exp,
    'held egg and gained experience survive reload')
  print('SEVII_NATIVE_TOWER_PASS','eight authored-team victories, one natural blackout, ordered stairs up/down, rewards, mid-climb save, roof title, return outside; shortened enemy HP on wins, healthy level-100 team and fixed RNG fixtures')
  love.event.quit()
end
