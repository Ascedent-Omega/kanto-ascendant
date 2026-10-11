return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util')
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=game.mods.exports.kanto_ascendant;local S=assert(K.seviiExpedition);local P=assert(S.population);local M=assert(K.seviiMedicine)
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
    Q.tap('a') -- current native host types the price before its YES/NO choice
    local money=game.save.money;local count=game.save.inventory[item]or 0
    Q.answerChoice(true);Q.settle()
    if expected then
      assert((game.save.inventory[item]or 0)==count+1,'purchase item '..item)
      assert(game.save.money==money-game.data.items[item].price,'native price debit')
    else assert((game.save.inventory[item]or 0)==count and game.save.money==money,'failed purchase is atomic')end
  end
  visit(P.medicineShops[1]);Q.settle();assert(game.save.money==90000,'pre-League gate')
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  S.persist({version=1,stage=3,chapterOneComplete=true,samples={heat=true,drift=true}})
  S.install(game);K.generationRules.resolve(game)
  for _,r in ipairs(M.rows)do
    local effect=game.data.item_effects[game.data.items[r.id].effect];local original=effect.use
    effect.use=function(ctx)
      local result,msg,extra=original(ctx)
      print('MEDICINE_USE',ctx.itemId,result,ctx.overworld and ctx.overworld.game==game,
        K.generationRules.peek(game).activeEpoch,K.generationRules.peek(game).extensionsEnabled,
        table.concat(msg or{},' / '))
      return result,msg,extra
    end
  end
  local purchased=0
  for _,shop in ipairs(P.medicineShops)do
    for _,id in ipairs(P.medicineStock(game,shop.id))do
      for i=1,2 do purchase(shop,id,true)end
      purchased=purchased+1
    end
  end
  assert(purchased==7,'all seven usable medicines have sources')
  game.save.money=0;purchase(P.medicineShops[1],'MOOMOO_MILK',false);game.save.money=90000
  local function pickItem(id)
    for _=1,8 do
      local t=game.stack:top();local found=false
      for _,r in ipairs(t.items or{})do if r.value==id then found=true end end
      if found then choose(function(r)return r.value==id end);return end
      Q.tap('right')
    end
    error('purchased medicine absent in Bag '..id)
  end
  local function settleField()
    for _=1,1800 do
      local t=game.stack:top()
      if t==game.overworld then Q.settle();return end
      if t.isTextBox or t.pages then Q.tap('a')else Q.tap('b')end
    end
    error('medicine UI did not close')
  end
  local mon=game.save.party[1]
  for _,r in ipairs(M.rows)do
    mon.hp=r.revive and 0 or 1;mon.status=r.cure and'PSN'or nil;mon.johtoBond=220
    local expected=r.revive and mon.stats.hp or r.hp and math.min(mon.stats.hp,1+r.hp)or 1
    game.stack:push(require('src.ui.BagMenu').new(game));U.wait(10)
    pickItem(r.id);U.wait(5)
    local top=game.stack:top()
    if top.items then choose(function(v)return v.value=='use'or v.label=='USE'end)
    elseif top.labels then Q.tap('a')end
    U.wait(10);top=game.stack:top()
    assert(top.pickOnly,'native medicine party picker '..r.id)
    Q.tap('a');settleField()
    print('MEDICINE_AFTER',r.id,game.save.inventory[r.id],mon.hp,mon.johtoBond)
    assert(game.save.inventory[r.id]==1,'native single consumption '..r.id)
    assert(mon.hp==expected and(not r.cure or not mon.status),'native field effect '..r.id)
    assert(mon.johtoBond==220-(r.bitter and r.bitter[2]or 0),'native friendship '..r.id)
    print('MEDICINE_FIELD_PASS',r.id,mon.hp,mon.johtoBond)
  end
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  mon=game.save.party[1];for _,r in ipairs(M.rows)do assert(game.save.inventory[r.id]==1,'saved remaining medicine')end
  assert(mon.hp==1 and not mon.status and mon.johtoBond==220,'saved treatment')
  mon.hp=mon.stats.hp;mon.moves={{id='WITHDRAW',pp=40}}
  local bench=require('src.pokemon.Pokemon').new(game.data,'PIDGEY',30);game.save.party[2]=bench
  local battle=require('src.battle.BattleState').newWild(game,'MAGIKARP',5,{randomizerProtected=true})
  battle.onFinish=function(result)game.overworld:afterBattle(result,battle)end
  game.overworld:pushBattle(battle)
  for _=1,1800 do if game.stack:top()==battle and battle.phase=='menu'then break end;Q.tap('a')end
  assert(battle.phase=='menu','native battle')
  for _,r in ipairs(M.rows)do
    local target=r.revive and bench or mon
    target.hp=r.revive and 0 or 1;target.status=r.cure and'PSN'or nil;target.johtoBond=220
    if r.cure then battle.player.toxicCounter=4;battle.player.confusedTurns=3 end
    local expected=r.revive and target.stats.hp or r.hp and math.min(target.stats.hp,1+r.hp)or 1
    local beforeTurn=battle.turnCount or 0
    assert(battle:chooseMenu('item'),'native Bag action');U.wait(12);pickItem(r.id);U.wait(10)
    assert(game.stack:top().pickOnly,'native battle party picker '..r.id)
    local picker=game.stack:top();local desired=r.revive and 2 or 1
    for _=1,8 do if picker.index==desired then break end;Q.tap(picker.index>desired and'up'or'down')end
    assert(picker.index==desired,'correct treatment target');Q.tap('a')
    for _=1,1800 do
      if game.stack:top()==battle and battle.phase=='menu'and(game.save.inventory[r.id]or 0)==0 then break end
      Q.tap('a')
    end
    assert(battle.phase=='menu'and(game.save.inventory[r.id]or 0)==0,'battle consumes exactly once '..r.id)
    assert(battle.turnCount>beforeTurn,'medicine spends a battle turn '..r.id)
    assert(target.hp==expected and(not r.cure or not target.status),'battle medicine effect '..r.id)
    assert(target.johtoBond==220-(r.bitter and r.bitter[2]or 0),'battle friendship '..r.id)
    if r.revive then assert(battle.participants[bench],'revive restores participation')end
    if r.cure then assert(not battle.player.toxicCounter and not battle.player.confusedTurns,'volatile cure')end
    print('MEDICINE_BATTLE_PASS',r.id,target.hp,target.johtoBond)
  end
  assert(battle:chooseMenu('run'),'native Run action')
  for _=1,1800 do if game.stack:top()==game.overworld then break end;Q.tap('a')end
  Q.settle();assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  for _,r in ipairs(M.rows)do assert((game.save.inventory[r.id]or 0)==0,'used items remain consumed after load')end
  assert(game.save.party[2].hp==bench.stats.hp and game.save.party[2].johtoBond==200,'revived bench persists')
  print('SEVII_NATIVE_MEDICINE_PASS','seven purchases; seven actual field uses; seven actual battle turns; heal, cure, revive, friendship and save/load')
  love.event.quit()
end
