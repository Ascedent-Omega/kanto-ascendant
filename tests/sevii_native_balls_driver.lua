return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition;local P=S.population;local B=K.seviiBalls
  require('src.world.OverworldController').rollEncounter=function()return nil end
  game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
  game.mods.modOptions.kanto_ascendant.living_world_enabled=false
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',70),require('src.pokemon.Pokemon').new(game.data,'PIDGEY',10)};game.save.money=90000
  Q.extraWarpAt=function(m,x,y)for _,w in ipairs(S.links[m.id]or{})do if w.x==x and w.y==y then return true end end;return false end
  local function visit()
    local p=P.researchBallShop
    U.teleport(game,p.map,p.x,p.y+1,'up');Q.settle();Q.faceObject(p.x,p.y);Q.tap('a');U.wait(8)
  end
  local function choose(match)
    for _=1,1800 do
      local t=game.stack:top()
      if t.items then Q.choose(match);return end
      assert(t~=game.overworld,'menu unexpectedly closed');Q.tap('a')
    end
    error('menu not reached')
  end
  visit();Q.settle();assert(game.save.money==90000,'League-gated research shop')
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  assert(K.beyondKanto.activate(game,{decision='qa-expanded-postleague-fixture'}))
  S.persist({version=1,stage=3,chapterOneComplete=true,samples={heat=true,drift=true}})
  S.install(game);K.generationRules.resolve(game)
  assert(#P.researchBallStock(game)==7,'five conditional balls plus Premier and Luxury available')
  for _,id in ipairs(B.ids)do
    visit();choose(function(r)return r.label=='BUY'end);choose(function(r)return r.value==id end)
    assert(game.stack:top().qty==1);Q.tap('up');assert(game.stack:top().qty==2);Q.tap('a')
    local money=game.save.money;Q.answerChoice(true);Q.settle()
    assert(game.save.inventory[id]==2 and game.save.money==money-2*game.data.items[id].price,'two actually purchased '..id)
  end
  local function pickItem(id)
    for _=1,8 do
      for _,r in ipairs(game.stack:top().items or{})do
        if r.value==id then choose(function(v)return v.value==id end);return end
      end
      Q.tap('right')
    end
    error('purchased ball not found '..id)
  end
  local function waitMenu(b)
    for _=1,3000 do if game.stack:top()==b and b.phase=='menu'then return end;Q.tap('a')end
    error('battle menu not reached')
  end
  local function openBag(b)
    assert(b:chooseMenu('item'),'native Bag action');U.wait(12)
  end
  local report={}
  local function storedCount(species)
    local seen={};local count=0
    local function scan(v)
      if type(v)~='table'or seen[v]then return end;seen[v]=true
      if v.species==species then count=count+1;return end
      for _,x in pairs(v)do scan(x)end
    end
    scan(game.save.party);scan(game.save.box);scan(game.save.boxes);return count
  end
  local function luxuryCaughtCount()
    local seen={};local count=0
    local function scan(v)
      if type(v)~='table'or seen[v]then return end;seen[v]=true
      if v.species and v._kascLuxuryBall==true then count=count+1;return end
      for _,x in pairs(v)do scan(x)end
    end
    scan(game.save.party);scan(game.save.box);scan(game.save.boxes);return count
  end
  for index,id in ipairs(B.ids)do
    if id=='PREMIER_BALL'then
      -- KASC may send earlier catches directly to the PC. Prepare a genuinely
      -- full team using those exact caught records; this is not a PC-menu test.
      for _,box in ipairs(game.save.boxes or{})do
        while #game.save.party<6 and #box>0 do table.insert(game.save.party,table.remove(box,1))end
      end
      assert(#game.save.party==6,'full-party fixture uses prior actual catches')
    end
    local species=index==1 and'WINGULL'or'MAGIKARP'
    local storedBefore=storedCount(species)
    local luxuryBefore=luxuryCaughtCount()
    U.teleport(game,S.harbors[5],8,5,'down');Q.settle()
    local b=require('src.battle.BattleState').newWild(game,species,5,{randomizerProtected=true})
    b.onFinish=function(result)game.overworld:afterBattle(result,b)end
    game.overworld:pushBattle(b);waitMenu(b)
    assert(B.completedTurns(b)==0,'new battle timer starts at zero')
    if index==1 or id=='PREMIER_BALL'then
      b.rng=function(_,hi)return hi end
      openBag(b);pickItem(id);U.wait(10)
      if game.stack:top().items then choose(function(r)return r.value=='use'or r.label=='USE'end)end
      for _=1,3000 do
        if game.stack:top()==b and b.phase=='menu'and game.save.inventory[id]==1 then break end
        Q.tap('a')
      end
      assert(game.save.inventory[id]==1 and B.completedTurns(b)==1,'failed real throw consumes once and advances Timer Ball')
      if index==1 then
      game.save.inventory.MOOMOO_MILK=1;game.save.party[1].hp=1
      openBag(b);pickItem('MOOMOO_MILK');U.wait(10)
      assert(game.stack:top().pickOnly,'native medicine target');Q.tap('a')
      for _=1,3000 do
        if game.stack:top()==b and b.phase=='menu'and(game.save.inventory.MOOMOO_MILK or 0)==0 then break end
        Q.tap('a')
      end
      assert(B.completedTurns(b)==2 and B.quote('TIMER_BALL',b).multiplier==1.2,'actual item turn counts toward Timer Ball')
      print('SEVII_BALL_TIMER_ITEM_TURNS_PASS',B.completedTurns(b))
      end
    end
    b.rng=function(lo)return lo end
    local q=assert(B.quote(id,b));if id=='PREMIER_BALL'then assert(q.multiplier==1,'ordinary Premier rate even with owned target')end
    local count=game.save.inventory[id]
    openBag(b);pickItem(id);U.wait(10)
    if game.stack:top().items then choose(function(r)return r.value=='use'or r.label=='USE'end)end
    assert(U.shot(game,out..'/research-ball-'..id..'.png'))
    local done=false
    for _=1,3000 do
      local t=game.stack:top()
      if t==game.overworld then done=true;break
      elseif t.def and t.def.id==species and not t.enemy then Q.tap('b')
      elseif t.labels and t.onChoose then
        local wanted=game.save.inventory[id]==count and 1 or 2
        if t.pending~=nil then U.wait(1)elseif t.index~=wanted then Q.tap('down')else Q.tap('a')end
      else Q.tap('a')end
    end
    assert(done,'actual capture finishes '..id);Q.settle()
    assert((game.save.inventory[id]or 0)==count-1 and storedCount(species)==storedBefore+1,'native consumption and party/PC delivery '..id)
    if id=='LUXURY_BALL'then assert(luxuryCaughtCount()==luxuryBefore+1,'actual Luxury catch records provenance')end
    assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
    assert(storedCount(species)==storedBefore+1,'native caught mon survives reload '..id)
    if id=='LUXURY_BALL'then assert(luxuryCaughtCount()==luxuryBefore+1,'Luxury provenance survives reload')end
    if id=='PREMIER_BALL'then
      assert(#game.save.party==6 and #(game.save.boxes[1]or{})==1,'Premier catch really stored in PC and loaded')
    end
    report[#report+1]={id=id,multiplier=q.multiplier,odds=q.odds,stored=true}
    print('SEVII_BALL_PURCHASE_CAPTURE_RELOAD_PASS',id,q.multiplier)
  end
  local f=assert(io.open(out..'/research-balls.json','wb'))
  f:write(require('src.link.Json').encode({passed=true,balls=report,
    scope='Native purchases, Bag preflight, actual throws/catches and reload. Failed Net/Premier throws consume once and advance Timer Ball; medicine round also advances it. Premier remains x1 and its catch reaches the full-party PC then reloads. Earlier caught records are moved from PC into the team as the full-party fixture, without exercising PC-menu withdrawal. Prepared post-League state, travel, target species/level, HP and RNG are controlled QA fixtures.'}));f:close()
  print('SEVII_NATIVE_RESEARCH_BALLS_PASS',#report);love.event.quit()
end
