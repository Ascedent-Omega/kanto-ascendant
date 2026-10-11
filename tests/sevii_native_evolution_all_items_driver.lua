-- Exercise every registered evolution find and its paid replacement in the
-- native engine. QA unlocks all character packages only to cover the matrix;
-- the game keeps those character gates intact.
return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'))
  local U=require('tests.drivers.util')
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=assert(game.mods.exports.kanto_ascendant)
  local S=assert(K.seviiExpedition)
  local R=assert(S.evolutionResearch)
  require('src.world.OverworldController').rollEncounter=function()return nil end
  game:startNewGame{intro=false}
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true
  game.save.flags.EVENT_GOT_STARTER=true
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  game.save.money=300000
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'MEWTWO',75)}
  assert(K.beyondKanto.activate(game,{decision='qa-sevii-evolution-matrix'}))
  local progress=S.state();progress.stage=3;progress.chapterOneComplete=true
  progress.samples={heat=true,drift=true};S.persist(progress)
  assert(K.generationRules.resolve(game).activeEpoch>=4)
  local persistent=K.hevoPackages.persistent(game.save,true)
  for _,package in ipairs(K.hevoPackages.order)do
    if package.item then persistent.packageUnlocks[package.id]=true end
  end
  K.hevoPackages.reconcile(game.save)
  local function approach(site)
    for _,v in ipairs{{0,1,'up'},{0,-1,'down'},{1,0,'left'},{-1,0,'right'}}do
      local x,y=site.x+v[1],site.y+v[2]
      local occupied=false
      for _,object in ipairs(S.maps[site.map].objects)do
        if object.x==x and object.y==y then occupied=true;break end
      end
      if S.walkable(site.map,x,y)and not occupied then return x,y,v[3]end
    end
    error('no approach '..site.id)
  end
  for _,row in ipairs(R.rows)do
    assert(R.available(game,row.id),'functional item registration '..row.id)
    local site=assert(R.sites[row.id]);local x,y,facing=approach(site)
    U.teleport(game,site.map,x,y,facing);Q.settle()
    local ok,why=R.claim(game,row.id)
    assert(ok,'native island find '..row.id..': '..tostring(why))
    assert(not R.claim(game,row.id),'one-time island find '..row.id)
    print('SEVII_EVOLUTION_FIND_PASS',row.id)
  end
  local shop=S.population.evolutionShop
  U.teleport(game,shop.map,shop.x,shop.y+1,'up');Q.settle()
  assert(#R.stock(game)==#R.rows,'every discovered item is stocked')
  for _,row in ipairs(R.rows)do
    local before=game.save.money
    local ok,why=R.buy(game,row.id)
    assert(ok,'native replacement purchase '..row.id..': '..tostring(why))
    assert(game.save.inventory[row.id]==2 and game.save.money==before-row.price,
      'replacement quantity and price '..row.id)
    print('SEVII_EVOLUTION_SHOP_PASS',row.id)
  end
  assert(game:writeSave())
  game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  for _,row in ipairs(R.rows)do
    assert(R.discovered(game,row.id)and game.save.inventory[row.id]==2,
      'item remains unlocked after reload '..row.id)
  end
  print('SEVII_EVOLUTION_ALL_ITEMS_PASS',#R.rows)
  love.event.quit()
end
