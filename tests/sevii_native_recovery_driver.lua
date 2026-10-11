return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util')
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=game.mods.exports.kanto_ascendant;local S=assert(K.seviiExpedition);local P=assert(S.population);local R=assert(K.seviiRecovery)
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
    local landings={}
    for _,links in pairs(S.links)do for _,w in ipairs(links)do
      if w.map==site.map then landings[#landings+1]={w.toX,w.toY,w.facing}end
    end end
    -- Cave arrival pockets differ; avoid nondeterministic Lua pairs order.
    table.sort(landings,function(a,b)return a[1]<b[1]or a[1]==b[1]and a[2]<b[2]end)
    local landing=landings[1]or {site.x,site.y+1,'up'}
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
  visit(P.recoveryShops[1]);Q.settle();assert(game.save.money==90000,'recovery shops respect league gate')
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  assert(K.beyondKanto.activate(game,{decision='qa-recovery-supplies'}))
  S.persist({version=1,stage=3,chapterOneComplete=true,samples={heat=true,drift=true}})
  S.install(game);K.generationRules.resolve(game)
  local purchased=0
  for _,shop in ipairs(P.recoveryShops)do
    for _,id in ipairs(P.recoveryStock(game,shop.id))do
      purchase(shop,id,true);if id=='PP_MAX'then purchase(shop,id,true)end
      purchased=purchased+1
    end
  end
  assert(purchased==8,'eight current recovery supplies including both field flutes and Zinc')
  game.save.money=0;purchase(P.recoveryShops[2],'PP_MAX',false);game.save.money=90000
  local ash=P.sites.EMBER_ASH
  local restoreBag=dofile(root..'/tests/sevii_native_bag_fixture.lua')(game,'SACRED_ASH');visit(ash);Q.settle()
  assert(not(S.state().population and S.state().population.finds and S.state().population.finds.EMBER_ASH),'full ash stack leaves find unclaimed')
  restoreBag();game.save.inventory.SACRED_ASH=nil;visit(ash);Q.settle()
  assert(game.save.inventory.SACRED_ASH==1 and S.state().population.finds.EMBER_ASH,'actual one-time ash pickup')
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
    local top=game.stack:top()
    assert(U.shot(game,out..'/recovery-stalled-menu.png'))
    print('RECOVERY_STALLED_MENU',tostring(top.screenId),tostring(top.held),tostring(top.ready),tostring(top.owner),tostring(top.mon==game.save.party[1]))
    error('medicine UI did not close')
  end
  local function checkpoint()
    assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  end
  local function fieldItem(id)
    game.stack:push(require('src.ui.BagMenu').new(game));U.wait(10);pickItem(id);U.wait(5)
    if game.stack:top().items then choose(function(v)return v.value=='use'or v.label=='USE'end)
    elseif game.stack:top().labels then Q.tap('a')end;U.wait(10)
  end
  local mon=game.save.party[1]
  local function movePickerReady()
    for _=1,1800 do
      local top=game.stack:top()
      if top.mon==mon and top.prompt and top.ready then return top end
      U.wait(1) -- Native MoveSelectMenu types its prompt before exposing the selection.
    end
    error('native PP Max move picker did not become ready')
  end
  mon.moves={{id='TACKLE',pp=3},{id='WITHDRAW',pp=2,ppUps=1}}
  local base=game.data.moves.WITHDRAW.pp
  fieldItem('PP_MAX');assert(game.stack:top().pickOnly);Q.tap('a');movePickerReady()
  assert(game.stack:top().mon==mon and game.stack:top().prompt,'real PP Max move picker')
  assert(U.shot(game,out..'/recovery-pp-max-move-picker.png'))
  Q.tap('b');settleField();assert(game.save.inventory.PP_MAX==2 and not mon.moves[1].ppUps,'cancel does not consume or choose default move');print('SEVII_PP_MAX_CANCEL_PASS')
  fieldItem('PP_MAX');Q.tap('a');movePickerReady();Q.tap('down');Q.tap('a');settleField()
  assert(game.save.inventory.PP_MAX==1 and mon.moves[2].ppUps==3 and mon.moves[2].pp==2+2*math.floor(base/5),'chosen move receives only missing PP capacity')
  assert(not mon.moves[1].ppUps and mon.moves[1].pp==3,'first move unchanged')
  print('SEVII_PP_MAX_CHOSEN_MOVE_AND_MENU_RETURN_PASS')
  fieldItem('PP_MAX');Q.tap('a');movePickerReady();Q.tap('down');Q.tap('a');settleField()
  assert(game.save.inventory.PP_MAX==1,'maxed move refusal keeps item')
  print('SEVII_PP_MAX_MAXED_REFUSAL_AND_MENU_RETURN_PASS')
  mon.status='SLP';fieldItem('BLUE_FLUTE');assert(game.stack:top().pickOnly);Q.tap('a');settleField()
  assert(not mon.status and game.save.inventory.BLUE_FLUTE==1,'blue field wake is reusable')
  local faint=require('src.pokemon.Pokemon').new(game.data,'PIDGEY',20)
  local faint2=require('src.pokemon.Pokemon').new(game.data,'RATTATA',20)
  faint.hp=0;faint.status='PSN';faint.moves[1].pp=1;faint2.hp=0;game.save.party[2]=faint;game.save.party[3]=faint2
  mon.hp=10;mon.status='BRN';fieldItem('SACRED_ASH');settleField()
  assert((game.save.inventory.SACRED_ASH or 0)==0 and faint.hp==faint.stats.hp and faint2.hp==faint2.stats.hp and not faint.status,'ash revives all fainted team members once')
  assert(mon.hp==10 and mon.status=='BRN'and faint.moves[1].pp==1,'ash leaves living member and PP unchanged')
  checkpoint();mon=game.save.party[1]
  assert(mon.moves[2].ppUps==3 and game.save.party[2].hp==faint.stats.hp and game.save.party[3].hp==faint2.stats.hp,'PP Max and ash effects survive reload')
  visit(ash);Q.settle();assert((game.save.inventory.SACRED_ASH or 0)==0,'spent ash does not respawn')
  mon.hp=mon.stats.hp;mon.status=nil;mon.moves={{id='WITHDRAW',pp=30}};mon.dvs.attack=15
  local battle=require('src.battle.BattleState').newWild(game,'MAGIKARP',5,{randomizerProtected=true})
  battle.enemy.mon.dvs.attack=0;battle.enemy.mon.moves={{id='SPLASH',pp=40}};battle.enemy.curMoves=battle.enemy.mon.moves
  battle.onFinish=function(result)game.overworld:afterBattle(result,battle)end
  game.overworld:pushBattle(battle)
  for _=1,1800 do if game.stack:top()==battle and battle.phase=='menu'then break end;Q.tap('a')end
  local rows={}
  for _,id in ipairs{'BLUE_FLUTE','YELLOW_FLUTE','RED_FLUTE'}do
    if id=='BLUE_FLUTE'then mon.status='SLP';battle.player.sleepTurns=4
    elseif id=='YELLOW_FLUTE'then battle.player.confusedTurns=4
    else
      mon.moves={{id='ATTRACT',pp=15}};battle.player.curMoves=mon.moves;
      battle.enemy.mon.moves={{id='ATTRACT',pp=15}};battle.enemy.curMoves=battle.enemy.mon.moves
      battle.rng=function(lo,hi)if lo==1 and hi==2 then return 2 end;return lo end
      local setupTurn=K.seviiBalls.completedTurns(battle)
      assert(battle:chooseMenu('fight'));U.wait(6);Q.tap('a')
      for _=1,1800 do
        if game.stack:top()==battle and battle.phase=='menu'and K.seviiBalls.completedTurns(battle)>setupTurn then break end
        Q.tap('a')
      end
      assert(K.pokemonInfatuation67.state(battle,battle.player)and K.pokemonInfatuation67.state(battle,battle.enemy),'actual Attract round sets both conditions')
      battle.enemy.mon.moves={{id='SPLASH',pp=40}};battle.enemy.curMoves=battle.enemy.mon.moves
    end
    local before=K.seviiBalls.completedTurns(battle)
    assert(battle:chooseMenu('item'));U.wait(12);pickItem(id);U.wait(10)
    assert(game.stack:top().pickOnly,'flute native party picker '..id);Q.tap('a')
    for _=1,1800 do
      if game.stack:top()==battle and battle.phase=='menu'and K.seviiBalls.completedTurns(battle)>before then break end
      Q.tap('a')
    end
    assert(game.stack:top()==battle and battle.phase=='menu'and K.seviiBalls.completedTurns(battle)==before+1,'one actual item turn '..id)
    assert(game.save.inventory[id]==1,'flute is retained '..id)
    if id=='BLUE_FLUTE'then assert(not mon.status and not battle.player.sleepTurns)
    elseif id=='YELLOW_FLUTE'then assert(not battle.player.confusedTurns)
    else assert(not K.pokemonInfatuation67.state(battle,battle.player)and K.pokemonInfatuation67.state(battle,battle.enemy),'red cures only selected side')end
    rows[#rows+1]={id=id,turnSpent=true,retained=true};print('SEVII_RECOVERY_FLUTE_PASS',id)
  end
  battle.rng=function(lo)return lo end;assert(battle:chooseMenu('run'))
  for _=1,1800 do if game.stack:top()==game.overworld then break end;Q.tap('a')end
  Q.settle();checkpoint()
  for _,id in ipairs{'BLUE_FLUTE','YELLOW_FLUTE','RED_FLUTE'}do assert(game.save.inventory[id]==1,'retained flute saved')end
  local f=assert(io.open(out..'/recovery-items.json','wb'))
  f:write(require('src.link.Json').encode({passed=true,shopItems=purchased,flutes=rows,ppMaxMoveSelection=true,ppMaxCancel=true,ppMaxNoEffect=true,
    ashOneTimePickup=true,ashFullBagRetry=true,ashPartyRevival=true,
    scope='Isolated QA: native purchases and insufficient-money refusal, full-stack/retry/one-time ash find, real PP Max party/move selection/cancel/refusal, field blue flute and ash, all three actual reusable flute battle turns, real Attract setup and native infatuation-owner cure preserving other side, save/load. Travel, champion/profile, team/moves/HP/status/DVs and escape RNG are fixtures; not a complete island journey or balance proof.'}));f:close()
  print('SEVII_NATIVE_RECOVERY_PASS');love.event.quit()
end
