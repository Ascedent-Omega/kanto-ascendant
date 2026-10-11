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
    for _,links in pairs(S.links)do for _,w in ipairs(links)do
      if w.map==site.map then landing={w.toX,w.toY,w.facing};break end
    end;if landing then break end end
    assert(landing,'no entrance '..site.id)
    U.teleport(game,site.map,landing[1],landing[2],landing[3]);Q.settle()
    Q.faceObject(site.x,site.y);Q.tap('a');U.wait(8)
  end
  local function menuReady()
    for _=1,1800 do
      local t=game.stack:top()
      if t.items or t.__pokemonUiHostV1 and t.__pokemonUiHostV1.surface=='pc_box' then return t end
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
    Q.tap('a') -- current native host types the price before its YES/NO choice
    local money=game.save.money;local count=game.save.inventory[item]or 0
    Q.answerChoice(true);Q.settle()
    if expected then
      assert((game.save.inventory[item]or 0)==count+1,'purchase item '..item)
      assert(game.save.money==money-game.data.items[item].price,'native price debit')
    else assert((game.save.inventory[item]or 0)==count and game.save.money==money,'failed purchase is atomic')end
  end
  visit(P.shops[1]);Q.settle();assert(game.save.money==90000,'pre-League service gate')
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  S.persist({version=1,stage=3,samples={heat=true,drift=true},chapterOneComplete=true,
    chapterTwoComplete=true,chapterThreeComplete=true,chapterFourComplete=true,chapterFiveComplete=true})
  S.install(game);U.wait(20)
  for island,site in ipairs(P.shops)do
    purchase(site,'ULTRA_BALL',true)
    print('NATIVE_SUPPLY_SHOP',island)
  end
  game.save.money=0;purchase(P.shops[3],'ULTRA_BALL',false);game.save.money=90000
  for island,site in ipairs(P.pcs)do
    visit(site);local pc=menuReady();assert(#pc.items>=3,'native main PC')
    Q.tap('a');local boxMenu=menuReady();local found=false
    if boxMenu.__pokemonUiHostV1 then
      assert(boxMenu.__pokemonUiHostV1.owner=='VOXEL_ASCENDANT'
        and boxMenu.__pokemonUiHostV1.surface=='pc_box','native storage owner')
      found=true -- Current Host-v1 storage owns its model and actions, not legacy menu.items.
    else
      for _,row in ipairs(boxMenu.items)do if row.label and row.label:find('DEPOSIT',1,true)then found=true end end
    end
    assert(found,'real Pokemon storage menu '..island)
    if island==1 then assert(U.shot(game,out..'/sevii-pc-storage.png'))end
    Q.settle()
  end
  local completed=0
  for _,site in ipairs(P.residents)do visit(site);Q.settle();completed=completed+1 end
  for id,site in pairs(P.sites)do
    if id:find('JOURNAL_',1,true)==1 then visit(site);Q.settle()end
  end
  local q=P.quartermaster
  assert(#P.pending()==4,'four current chapter packages, including the forest keepsake')
  local restoreBag=dofile(root..'/tests/sevii_native_bag_fixture.lua')(game,'ULTRA_BALL')
  visit(q);choose(function(row)return row.value=='SURVEY'end);Q.settle()
  assert(#P.pending()==4 and game.save.inventory.ULTRA_BALL==99,'full Bag leaves reward claim pending')
  restoreBag();game.save.inventory.ULTRA_BALL=0
  visit(q);choose(function(row)return row.value=='SURVEY'end);Q.settle()
  assert(game.save.inventory.ULTRA_BALL==5,'actual supply reward delivery')
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  assert(game.save.inventory.ULTRA_BALL==5 and #P.pending()==3,'supply receipt and Bag reload together')
  for _,shop in ipairs(P.berryShops)do
    local stock=P.berryStock(game,shop.id)
    assert(#stock==(shop.generation==2 and 10 or 15),'complete active berry assortment')
  end
  purchase(P.berryShops[1],'MYSTERYBERRY',true)
  purchase(P.berryShops[2],'LIECHI_BERRY',true)
  purchase(P.berryShops[2],'PETAYA_BERRY',true)
  visit(P.berryShops[2]);choose(function(row)return row.label=='BUY'end)
  assert(U.shot(game,out..'/sevii-hoenn-berry-shop.png'));Q.settle()
  -- The purchased berry uses the existing battle owner, not a new effect.
  assert(K.pokemonModernBerries67.supportsItem(game,'LIECHI_BERRY',3))
  assert(K.pokemonEquipmentEffects67.supportsItem(game,'MYSTERYBERRY',3))
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  assert(game.save.inventory.LIECHI_BERRY==1 and game.save.inventory.PETAYA_BERRY==1 and game.save.inventory.MYSTERYBERRY==1)
  -- Use the actual purchased berry via the equipment menu and one native
  -- battle turn. Low HP and a harmless foe are isolated effect fixtures.
  local equipment=K.pokemonEquipment67
  assert(equipment.openNative(game,game.save.party[1]))
  choose(function(row)return row.value=='give'end)
  choose(function(row)return row.value=='LIECHI_BERRY'end);Q.settle()
  local mon=game.save.party[1]
  assert(equipment.heldId(mon)=='LIECHI_BERRY'and(game.save.inventory.LIECHI_BERRY or 0)==0,'purchased berry equipped, not copied')
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  mon=game.save.party[1];assert(equipment.heldId(mon)=='LIECHI_BERRY','held berry reload')
  mon.hp=math.max(1,math.floor(mon.stats.hp/4));mon.moves={{id='WITHDRAW',pp=40}}
  local battle=require('src.battle.BattleState').newWild(game,'MAGIKARP',5,
    {encounterSource=S.habitats.SOURCE,randomizerProtected=true})
  battle.onFinish=function(result)game.overworld:afterBattle(result,battle)end
  game.overworld:pushBattle(battle)
  for _=1,1800 do if game.stack:top()==battle and battle.phase=='menu'then break end;Q.tap('a')end
  assert(battle.phase=='menu','berry test native battle menu')
  Q.tap('a');Q.tap('a') -- Fight / Withdraw through the normal battle UI.
  for _=1,1800 do
    if game.stack:top()==battle and battle.phase=='menu'and not equipment.heldId(mon)then break end
    Q.tap('a')
  end
  assert(not equipment.heldId(mon)and battle.player.stages.attack==1,'purchased Liechi consumed and boosts attack in real turn')
  assert(battle.phase=='menu','berry turn finished')
  assert(battle:chooseMenu('run'),'native Run action')
  for _=1,1800 do if game.stack:top()==game.overworld then break end;Q.tap('a')end
  assert(game.stack:top()==game.overworld,'berry battle escape');Q.settle()
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  assert(not equipment.heldId(game.save.party[1])and(game.save.inventory.LIECHI_BERRY or 0)==0,'consumed berry stays consumed after reload')
  print('SEVII_PURCHASED_BERRY_NATIVE_EFFECT_PASS','Liechi: shop, equipment, reload, attack boost, consumption, reload')
  local s=S.state();s.seviiRiftSealed=true;s.expeditionComplete=true;S.persist(s)
  for _,site in ipairs(P.residents)do visit(site);Q.settle();completed=completed+1 end
  visit(q);choose(function(row)return row.value=='EXPEDITION'end);Q.settle()
  assert(game.save.inventory.RARE_CANDY==3,'completion package delivered')
  print('SEVII_NATIVE_POPULATION_PASS',completed,'resident conversations; seven purchases, seven PCs, seven journals, full-Bag retry, saved rewards, Gen2/3 berry purchases')
  love.event.quit()
end
