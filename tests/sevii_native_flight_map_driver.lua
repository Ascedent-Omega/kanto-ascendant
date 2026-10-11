-- Isolated profile: native field gate, illustrated card and START switching.
return function(game)
  io.stdout:setvbuf('no')
  package.path=assert(os.getenv('KASC_ENGINE'))..'/?.lua;'..package.path
  local root=assert(os.getenv('SEVII_KASC_ROOT'))
  local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util')
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=assert(game.mods.exports.kanto_ascendant)
  local S=assert(K.seviiExpedition)
  local bridge=assert(game.mods.exports.vasc_kanto_sevii_fly_map_widescreen)
  assert(S.available and bridge.active)
  game:startNewGame{intro=false}
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true
  game.save.flags.EVENT_GOT_STARTER=true
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  assert(K.beyondKanto.activate(game,{decision='flight-map-qa'}))
  local Pokemon=require('src.pokemon.Pokemon')
  local mon=Pokemon.new(game.data,'PIDGEOT',60)
  mon.moves={{id='FLY',pp=15},{id='TACKLE',pp=35}}
  game.save.party={mon}
  game.save.inventory.THUNDERBADGE=true
  local Map=require('src.world.Map')
  local Screens=require('src.ui.Screens')
  assert(not S.flight.chartUnlocked(),'Sevii chart must be locked before travel')
  Screens.push(game,'TownMap',{})
  U.wait(5)
  local beforeArrival=game.stack:top()
  assert(beforeArrival.region=='kanto','Kanto overview before island arrival')
  Q.tap('start')
  assert(beforeArrival.region=='kanto','START cannot expose Sevii before arrival')
  game.stack:pop()
  for _,point in ipairs(S.flight.points)do
    assert(game.data.field.flyWarps[point.map],point.map..' warp absent')
    assert(not Map.isFlyTown(game.data.maps[point.map]),
      point.map..' prematurely flyable')
  end
  local first=S.flight.points[1]
  U.teleport(game,first.map,first.x,first.y,'down');Q.settle()
  assert(S.flight.visited(game,1)and not S.flight.eligible(game,1),
    'island visited before radio must stay locked')
  assert(game.overworld:flyTo('PALLET_TOWN')==false,
    'native Fly to Kanto must stay locked while on Sevii')
  Screens.push(game,'TownMap',{fly=true,onFly=function(id)
    game.overworld:flyTo(id)
  end})
  U.wait(8)
  local screen=game.stack:top()
  assert(screen.region=='sevii'and #screen.flyTargets==0,
    'locked map must still show Sevii overview')
  assert(U.shot(game,out..'/sevii-map-locked.png'))
  Q.tap('select');U.wait(150)
  assert(game.stack:top().isTextBox,'SELECT opens island information at arrival')
  local info=bridge.formatLocationInfo(screen.locations[screen.selected],'en',game)
  assert(info:find('volcanic coast',1,true)
    and info:find('research',1,true)and info:find('camp',1,true),
    'SELECT must include the actual place description, not only the location name')
  assert(U.shot(game,out..'/sevii-map-select-info.png'))
  Q.tap('a');U.wait(300)
  assert(U.shot(game,out..'/sevii-map-select-description.png'))
  game.stack:pop()
  Q.tap('start');U.wait(8)
  assert(screen.region=='kanto'and #screen.flyTargets==0,
    'START should show Kanto without granting Fly')
  assert(U.shot(game,out..'/kanto-map-switch.png'))
  Q.tap('start');U.wait(8)
  assert(screen.region=='sevii','START should return to Sevii')
  game.stack:pop()
  local s=S.state();s.chapterFiveComplete=true;S.persist(s)
  S.flight.visit(game,2) -- second charted island fixture for destination UI
  S.flight.sync(game)
  assert(S.flight.eligible(game,1)and S.flight.eligible(game,2))
  assert(Map.isFlyTown(game.data.maps[first.map]),'radio unlocks native Fly gate')
  Screens.push(game,'TownMap',{fly=true,onFly=function(id)
    game.overworld:flyTo(id)
  end})
  U.wait(8)
  screen=game.stack:top()
  assert(screen.region=='sevii'and #screen.flyTargets==2,
    'native picker has exactly two visited islands')
  assert(U.shot(game,out..'/sevii-map-unlocked.png'))
  game.stack:pop()
  local second=S.flight.points[2]
  game.overworld:flyTo(second.map)
  for _=1,3000 do
    local ow=game.overworld
    if ow.map.id==second.map and game.stack:top()==ow and not ow.transitioning
        and not ow.player.inputLocked and Q.sceneReady()then break end
    U.wait(1)
  end
  assert(game.overworld.map.id==second.map,
    'native Fly animation must land on charted island two')
  assert(game.overworld.player.cellX==second.x
    and game.overworld.player.cellY==second.y,
    'native Fly landing must match the safe outdoor point')
  print('SEVII_NATIVE_FLIGHT_MAP_PASS',#S.flight.points)
end
