return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util')
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=game.mods.exports.kanto_ascendant;local S=assert(K.seviiExpedition);local P=assert(S.population)
  require('src.world.OverworldController').rollEncounter=function()return nil end
  game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
  game.mods.modOptions.kanto_ascendant.living_world_enabled=false
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',70)}
  game.save.money=90000
  Q.extraWarpAt=function(m,x,y)
    for _,w in ipairs(S.links[m.id]or{})do if w.x==x and w.y==y then return true end end
    return false
  end
  local function visit(site)
    local landing
    if site.id=='EMBER_ASH'then landing={22,16,'up'}end -- accessible Ruby Path entrance, away from the sealed upper ledge
    if site.id=='ICE_EVERSTONE'then landing={3,16,'right'}end -- lower chamber, before the ice puzzle
    for _,links in pairs(S.links)do for _,w in ipairs(links)do
      if not landing and w.map==site.map then landing={w.toX,w.toY,w.facing};break end
    end;if landing then break end end
    landing=landing or {site.x,site.y+1,'up'}
    U.teleport(game,site.map,landing[1],landing[2],landing[3]);Q.settle()
    Q.faceObject(site.x,site.y);Q.tap('a');U.wait(8)
  end
  local function menuReady()
    for _=1,1800 do
      local t=game.stack:top()
      if t.items then return t end
      assert(t~=game.overworld,'menu unexpectedly closed')
      if t.isTextBox or t.pages then Q.tap('a')else U.wait(1)end
    end
    error('menu never appeared')
  end
  local function choose(match)
    local t=menuReady();local wanted
    for i,row in ipairs(t.items)do if match(row)then wanted=i;break end end
    assert(wanted,'menu row missing')
    for _=1,120 do
      if t.index==wanted then Q.tap('a');return end
      Q.tap(t.index>wanted and'up'or'down')
    end
    error('menu navigation stuck')
  end
  local function purchase(site,item,expected)
    visit(site);choose(function(row)return row.label=='BUY'end)
    choose(function(row)return row.value==item end)
    local qty=game.stack:top();assert(qty.qty==1,'native quantity chooser')
    Q.tap('a') -- native price text precedes the YES/NO box
    local money=game.save.money;local count=game.save.inventory[item]or 0
    Q.answerChoice(true);Q.settle()
    if expected then
      assert((game.save.inventory[item]or 0)==count+1,'purchase item '..item)
      assert(game.save.money==money-game.data.items[item].price,'native price debit')
    else assert((game.save.inventory[item]or 0)==count and game.save.money==money,'failed purchase is atomic')end
  end
  visit(P.apricornShop);Q.settle();assert(game.save.money==90000,'pre-League gate')
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  S.persist({version=1,stage=5,chapterOneComplete=true,chapterFourComplete=true,
    samples={heat=true,drift=true}})
  S.install(game);K.generationRules.resolve(game)
  local ids=P.apricornStock(game);assert(#ids==7,'seven operational balls')
  for _,id in ipairs(ids)do purchase(P.apricornShop,id,true)end
  game.save.money=0;purchase(P.apricornShop,'FRIEND_BALL',false);game.save.money=90000
  for _,p in ipairs(P.finds)do
    local restoreBag=dofile(root..'/tests/sevii_native_bag_fixture.lua')(game,p.item)
    visit(p);Q.settle()
    assert(not ((S.state().population or{}).finds or{})[p.id],'full native pocket does not consume find')
    restoreBag();game.save.inventory[p.item]=nil
    visit(p);Q.settle();assert(game.save.inventory[p.item]==1,'actual find delivery '..p.item)
    visit(p);Q.settle();assert(game.save.inventory[p.item]==1,'no duplicate '..p.item)
    assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
    visit(p);Q.settle();assert(game.save.inventory[p.item]==1,'saved find receipt '..p.item)
    if ({COLLECTOR_BELT=true,RUBBING_ICE=true,
        RESORT_GLASSES=true,STUDENT_SPOON=true})[p.id]then
      local equipment=K.pokemonEquipment67
      assert(equipment.openNative(game,game.save.party[1]),'type souvenir equipment menu')
      choose(function(row)return row.value=='give'end)
      choose(function(row)return row.value==p.item end);Q.settle()
      assert(equipment.heldId(game.save.party[1])==p.item
        and (game.save.inventory[p.item]or 0)==0,'found type item equipped')
      assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
      assert(equipment.heldId(game.save.party[1])==p.item,'type item survives reload')
      assert(equipment.openNative(game,game.save.party[1]),'type souvenir return menu')
      choose(function(row)return row.value=='take'end);Q.settle()
      assert((game.save.inventory[p.item]or 0)==1
        and not equipment.heldId(game.save.party[1]),'same type item returned')
    end
    if p.item=='SOOTHE_BELL'then
      local equipment=K.pokemonEquipment67
      assert(equipment.openNative(game,game.save.party[1]),'native equipment menu for nursery bell')
      choose(function(row)return row.value=='give'end)
      choose(function(row)return row.value=='SOOTHE_BELL'end);Q.settle()
      local mon=game.save.party[1]
      assert(equipment.heldId(mon)=='SOOTHE_BELL'and(game.save.inventory.SOOTHE_BELL or 0)==0,
        'one actual found bell equipped')
      mon.johtoBond=70
      assert(K.seviiBalls.gainFriendship(game,mon,10)and mon.johtoBond==85,
        'equipped bell boosts existing KASC friendship gain')
      assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
      mon=game.save.party[1]
      assert(equipment.heldId(mon)=='SOOTHE_BELL'and mon.johtoBond==85,'held bell and bonus survive reload')
      assert(equipment.openNative(game,mon),'native equipment menu for bell return')
      choose(function(row)return row.value=='take'end);Q.settle()
      assert((game.save.inventory.SOOTHE_BELL or 0)==1 and not equipment.heldId(game.save.party[1]),
        'native equipment returns same bell before sale')
    end
    if p.item=='EVERSTONE'then
      local equipment=K.pokemonEquipment67
      local Evolution=require('src.pokemon.Evolution')
      game.save.party[2]=require('src.pokemon.Pokemon').new(game.data,'MAGIKARP',20)
      local mon=game.save.party[2]
      assert(Evolution.pendingFor(game,mon,{kind='levelup'})=='GYARADOS','ordinary level evolution available')
      assert(equipment.openNative(game,mon),'native equipment menu for Everstone')
      choose(function(row)return row.value=='give'end)
      choose(function(row)return row.value=='EVERSTONE'end);Q.settle()
      mon=game.save.party[2]
      assert(equipment.heldId(mon)=='EVERSTONE'and(game.save.inventory.EVERSTONE or 0)==0,
        'one actual cave Everstone equipped')
      assert(not Evolution.pendingFor(game,mon,{kind='levelup'}),'held stone blocks native level evolution')
      local finished=false
      assert(Evolution.checkParty(game,function()finished=true end,{[mon]=true})==0 and finished,
        'after-battle evolution dispatcher respects stone')
      assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
      mon=game.save.party[2]
      assert(equipment.heldId(mon)=='EVERSTONE'and not Evolution.pendingFor(game,mon,{kind='levelup'}),
        'stone effect survives reload')
      assert(equipment.openNative(game,mon),'native equipment menu for Everstone return')
      choose(function(row)return row.value=='take'end);Q.settle()
      assert((game.save.inventory.EVERSTONE or 0)==1 and
        Evolution.pendingFor(game,game.save.party[2],{kind='levelup'})=='GYARADOS',
        'taking stone restores native level evolution')
      table.remove(game.save.party,2) -- remove only the evolution QA fixture before the later Friend Ball catch
    end
    if p.item=='AMULET_COIN'then
      local equipment=K.pokemonEquipment67
      assert(equipment.openNative(game,game.save.party[1]),'native equipment menu for Amulet Coin')
      choose(function(row)return row.value=='give'end)
      choose(function(row)return row.value=='AMULET_COIN'end);Q.settle()
      assert(equipment.heldId(game.save.party[1])=='AMULET_COIN'and
        (game.save.inventory.AMULET_COIN or 0)==0,'found coin equipped once')
      local Battle=require('src.battle.BattleState')
      local b=Battle.newTrainer(game,'OPP_YOUNGSTER',1,{randomizerProtected=true})
      b.onFinish=function(result)game.overworld:afterBattle(result,b)end
      b.rng=function(lo)return lo end
      local before=game.save.money
      game.overworld:pushBattle(b)
      for _=1,1800 do if game.stack:top()==b and b.phase=='menu'then break end;Q.tap('a')end
      assert(b.phase=='menu','native Amulet Coin battle starts')
      for _,mon in ipairs(b.enemyParty)do mon.hp=1 end
      b.enemy.shownHP=1
      for _=1,9000 do if game.stack:top()==game.overworld then break end;Q.tap('a')end
      assert(game.stack:top()==game.overworld and b.result=='win','coin holder wins trainer battle')
      Q.settle()
      local prize=b.trainer.baseMoney*b.enemy.mon.level
      assert(prize>0 and game.save.money-before==prize*2,
        'participating coin holder doubles native trainer prize')
      assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
      assert(equipment.heldId(game.save.party[1])=='AMULET_COIN',
        'equipped coin survives save and reload')
      assert(equipment.openNative(game,game.save.party[1]),'native equipment menu for coin return')
      choose(function(row)return row.value=='take'end);Q.settle()
      assert((game.save.inventory.AMULET_COIN or 0)==1 and
        not equipment.heldId(game.save.party[1]),'same coin returned for sale')
    end
    visit(P.shops[1]);choose(function(r)return r.label=='SELL'end)
    choose(function(r)return r.value==p.item end)
    assert(game.stack:top().qty==1,'native sale quantity');Q.tap('a')
    local money=game.save.money;Q.answerChoice(true);Q.settle()
    assert((game.save.inventory[p.item]or 0)==0 and game.save.money==money+math.floor(game.data.items[p.item].price/2),'actual sale '..p.item)
    visit(p);Q.settle();assert((game.save.inventory[p.item]or 0)==0,'selling cannot regenerate find')
  end
  if os.getenv('SEVII_FINDS_ONLY')=='1'then
    print('SEVII_ALL_NATIVE_FINDS_PASS',#P.finds)
    love.event.quit();return
  end
  local Battle=require('src.battle.BattleState');local Items=require('src.inventory.ItemEffects')
  U.teleport(game,S.harbors[1],8,5,'right');Q.settle()
  local battle=Battle.newWild(game,'MAGIKARP',5,{randomizerProtected=true})
  for _,id in ipairs(ids)do
    assert(Items.use(game.data,game.save,id,nil,battle)=='ball','native ball preflight '..id)
    battle.rng=function(a)return a end
    assert(battle:catchAttempt(id),'native catch formula '..id)
  end
  -- One actually purchased Friend Ball goes through the real Bag, throw,
  -- capture, party delivery and save reload. RNG is an isolated success fixture.
  battle.onFinish=function(result)game.overworld:afterBattle(result,battle)end
  game.overworld:pushBattle(battle)
  for _=1,1800 do if game.stack:top()==battle and battle.phase=='menu'then break end;Q.tap('a')end
  assert(battle.phase=='menu')
  assert(battle:chooseMenu('item'),'native Bag action');U.wait(20)
  local found=false
  for _=1,8 do
    for _,r in ipairs(game.stack:top().items or{})do if r.value=='FRIEND_BALL'then found=true end end
    if found then choose(function(r)return r.value=='FRIEND_BALL'end);break end
    Q.tap('right')
  end
  assert(found,'purchased Friend Ball in real Bag');U.wait(10)
  if game.stack:top().items then choose(function(r)return r.value=='use'or r.label=='USE'end)end
  local finished=false
  for _=1,3000 do
    local top=game.stack:top()
    if top==game.overworld then finished=true;break
    elseif top.def and top.def.id=='MAGIKARP'and not top.enemy then Q.tap('b')
    elseif top.labels and top.onChoose then
      local desired=(game.save.inventory.FRIEND_BALL or 0)==1 and 1 or 2
      if top.pending~=nil then U.wait(1)elseif top.index~=desired then Q.tap('down')else Q.tap('a')end
    else Q.tap('a')end
  end
  assert(finished,'capture UI finishes');Q.settle()
  assert((game.save.inventory.FRIEND_BALL or 0)==0,'purchased ball consumed once')
  local function findCaught()
    local function scan(t,seen)
      if type(t)~='table'or seen[t]then return end;seen[t]=true
      if t.species=='MAGIKARP'then return t end
      for _,v in pairs(t)do local mon=scan(v,seen);if mon then return mon end end
    end
    return scan({game.save.party,game.save.box,game.save.boxes},{})
  end
  local caught=findCaught()
  assert(caught and caught.species=='MAGIKARP'and caught.apricornFriendBallApplied and caught.johtoBond>=200,'native Friend Ball effect applied to caught mon')
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  caught=findCaught();assert(caught and caught.apricornFriendBallApplied and caught.johtoBond>=200,'catch metadata survives reload')
  for _,p in ipairs(P.finds)do assert(S.state().population.finds[p.id],'all sold finds remain claimed')end
  print('SEVII_NATIVE_FINDS_APRICORN_PASS','seven purchases/formulas; '..#P.finds..' full-Bag retries, pickups, sales and persistent receipts; purchased Friend Ball real capture/reload')
  love.event.quit()
end
