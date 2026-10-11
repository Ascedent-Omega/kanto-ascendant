-- Focused native check of early Legacy access, downward scaling and the
-- researcher's direct NG+ stock. A private save identity is required.
return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'))
  local U=require('tests.drivers.util')
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=assert(game.mods.exports.kanto_ascendant)
  local S=assert(K.seviiExpedition)
  local R=assert(S.evolutionResearch)
  local Pokemon=require('src.pokemon.Pokemon')
  require('src.world.OverworldController').rollEncounter=function()return nil end
  game:startNewGame{intro=false}
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true
  game.save.flags.EVENT_GOT_STARTER=true
  game.save.party={Pokemon.new(game.data,'PIKACHU',12)}
  game.save.money=20000
  local bucket=game.save.modData.kanto_ascendant
  bucket.legacy_journey={runId='qa-sevii-early-access'}
  assert(K.legacyJourney.isActive(game.save))
  assert(not game.save.flags.EVENT_BEAT_CHAMPION_RIVAL and S.unlocked(game),
    'Legacy cycle opens the port before the League')
  U.teleport(game,'VERMILION_CITY',27,26,'left');Q.settle()
  assert(S.depart(game),'first Vermilion visit can sail')
  Q.settle()
  assert(S.maps[game.overworld.map.id],'native ferry arrives on Sevii')
  local function approachable(site)
    for _,delta in ipairs{{1,0},{-1,0},{0,1},{0,-1}}do
      local x,y=site.x+delta[1],site.y+delta[2]
      local occupied=false
      for _,object in ipairs(S.maps[site.map].objects)do
        if object.x==x and object.y==y then occupied=true;break end
      end
      if S.walkable(site.map,x,y)and not occupied then return true end
    end
    return false
  end
  for id,site in pairs(R.sites)do
    assert(approachable(site),'evolution find has a free approach: '..id)
  end
  for id,site in pairs(R.fields)do
    assert(approachable(site),'evolution field has a free approach: '..id)
  end
  local row=S.trainers.rows[1]
  local team=assert(S.trainers.team(game,row))
  assert(team[1].level==14 and team[3].level==16,
    'early Legacy trainer and ace scale to level-12 team')
  assert(S.scaling.wild(game,60)==9 and S.scaling.legend(game,65)==20,
    'wild and legendary targets follow Legacy level')
  local stock=R.stock(game)
  local has={};for _,id in ipairs(stock)do has[id]=true end
  assert(has.PRISM_SCALE and has.DEEP_SEA_TOOTH and has.DAWN_STONE
    and has.OVAL_STONE and has.MAGNETIC_CORE,
    'functional non-HEVO evolution stock is direct in NG+')
  local shop=assert(S.population.evolutionShop)
  U.teleport(game,shop.map,shop.x,shop.y+1,'up');Q.settle()
  local before=game.save.money
  assert(R.buy(game,'OVAL_STONE'))
  assert(game.save.inventory.OVAL_STONE==1 and game.save.money==before-2000,
    'NG+ direct purchase consumes money and adds the item')
  Q.tap('a')
  for _=1,300 do
    local top=game.stack:top()
    if top.items then break end
    if top.isTextBox or top.pages then Q.tap('a')else U.wait(1)end
  end
  local menu=game.stack:top();assert(menu.items,'researcher opens native list')
  local listed={};for _,item in ipairs(menu.items)do listed[item.value]=true end
  assert(listed.OVAL_STONE and listed.DAWN_STONE,
    'NG+ item list shows direct evolution stock in the actual NPC UI')
  Q.tap('b');Q.settle()
  local packages=K.hevoPackages
  packages.persistent(game.save,true).packageUnlocks.protector=true
  assert(not K.beyondKanto.peekIsActive(game) and R.available(game,'PROTECTOR'),
    'a previously unlocked HEVO item is stocked before Beyond Kanto in NG+')
  before=game.save.money
  assert(R.buy(game,'PROTECTOR'))
  assert(game.save.inventory.PROTECTOR==1 and game.save.money==before-9800,
    'direct NG+ HEVO replacement uses the established price')
  -- In an ordinary first cycle, a real find unlocks exactly that item's
  -- replacement purchase; the direct NG+ privilege does not leak across modes.
  bucket.legacy_journey=nil
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  game.save.money=30000
  assert(K.beyondKanto.activate(game,{decision='qa-sevii-evolution-finds'}))
  local progress=S.state();progress.stage=3;progress.chapterOneComplete=true
  progress.samples={heat=true,drift=true};S.persist(progress)
  K.generationRules.resolve(game)
  assert(not R.discovered(game,'PRISM_SCALE') and not R.discovered(game,'PROTECTOR'))
  local find=R.sites.PRISM_SCALE
  U.teleport(game,find.map,find.x-1,find.y,'right');Q.settle()
  local found,why=R.claim(game,'PRISM_SCALE')
  assert(found,'real Prism Scale find: '..tostring(why)..' epoch='..
    tostring(K.generationRules.peek(game).activeEpoch))
  assert(not R.claim(game,'PRISM_SCALE'),'find stays one-time')
  assert(R.discovered(game,'PRISM_SCALE'))
  U.teleport(game,shop.map,shop.x,shop.y+1,'up');Q.settle()
  before=game.save.money
  assert(R.buy(game,'PRISM_SCALE'))
  assert(game.save.inventory.PRISM_SCALE==2 and game.save.money==before-2100,
    'first-cycle find opens paid replacement')
  packages.persistent(game.save,true).packageUnlocks.protector=true
  assert(not R.discovered(game,'PROTECTOR') and not R.buy(game,'PROTECTOR'),
    'HEVO replacement still needs its Sevii find')
  find=R.sites.PROTECTOR
  U.teleport(game,find.map,find.x,find.y+1,'up');Q.settle()
  assert(R.claim(game,'PROTECTOR'),'character-unlocked Gen4 item can be found')
  U.teleport(game,shop.map,shop.x,shop.y+1,'up');Q.settle()
  before=game.save.money
  assert(R.buy(game,'PROTECTOR'))
  assert(game.save.inventory.PROTECTOR==3 and game.save.money==before-9800,
    'HEVO purchase uses the established 9800 price')
  assert(game:writeSave())
  game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  assert(R.discovered(game,'PRISM_SCALE') and R.discovered(game,'PROTECTOR'),
    'find receipts survive native save and reload')
  local older=S.state();older.version=1;older.evolutionResearch=nil
  S.persist(older)
  assert(R.discovered(game,'DEEP_SEA_TOOTH'),
    'existing Sevii saves retain marine-item shop access after migration')
  -- BEACH requires two usable members for its native double battle.
  game.save.party={Pokemon.new(game.data,'PIKACHU',12),Pokemon.new(game.data,'BULBASAUR',12)}
  game.save.modData.kanto_ascendant.legacy_journey={runId='qa-rematch-cycle'}
  local record=S.state();record.trainers=record.trainers or{}
  record.trainers.BEACH={won=true,claimed=true,rematches=0,
    readyAt=K.trainerStepClock()+100}
  S.persist(record)
  U.teleport(game,row.map,row.x,row.y+1,'up');Q.settle()
  local started,reason=S.trainers.start(game,'BEACH')
  assert(not started and reason=='resting','Sevii rematch respects trainer break')
  record=S.state();record.trainers.BEACH.readyAt=K.trainerStepClock()
  S.persist(record)
  local battle
  started,battle=S.trainers.start(game,'BEACH')
  assert(started and battle and #battle.enemyParty==3,'native Sevii rematch starts')
  assert(battle.enemyParty[1].level==16 and battle.enemyParty[3].level==18,
    'rematch uses configured level gain on early Legacy scale')
  print('SEVII_NATIVE_LEGACY_ACCESS_PASS',#stock,team[1].level,team[3].level,
    'first-cycle-find-shop-reload-rematch')
  love.event.quit()
end
