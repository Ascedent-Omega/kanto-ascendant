-- Actual 146-step forest escort with native NPC movement and map seams.
-- Teleports set up/abort the quest; none are used on the successful route.
return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util')
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=assert(game.mods.exports.kanto_ascendant);local S=assert(K.seviiExpedition)
  local C=S.chapters;local R=assert(C.rescue)
  require('src.world.OverworldController').rollEncounter=function()return nil end
  game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
  game.mods.modOptions.kanto_ascendant.living_world_enabled=false
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',70)}
  assert(S.begin(game))
  for _,id in ipairs{'heat','drift'}do
    local p=S.samples[id];U.teleport(game,p.map,p.x,p.y-1,'down');assert(S.collect(game,id))
  end
  assert(S.report())
  local p=C.sites.ARCHIVIST;U.teleport(game,p.map,p.x-1,p.y,'right');assert(C.readArchive(game))
  p=C.sites.MIRROR_STONE;U.teleport(game,p.map,p.x+1,p.y,'left');assert(C.decode(game,{'SHORE','WAVE','STAR'}))
  p=C.sites.ARCHIVIST;U.teleport(game,p.map,p.x-1,p.y,'right');assert(C.report(game))
  local function rescueState()return S.state().chapters.three end
  local function start()
    local p=R.sites.stranded
    U.teleport(game,p.map,p.x,p.y+1,'up');Q.settle();Q.tap('a');Q.settle()
    assert(rescueState().escorting,'native surveyor conversation starts escort')
  end
  start();U.teleport(game,S.PORT,8,4,'down');Q.settle()
  assert(not rescueState().escorting and rescueState().separated,'aborted escort can resume')
  start()
  local function coords()
    local ow=game.overworld;local m=S.maps[ow.map.id]
    return ow.player.cellX+m.kaSeviiSourceOrigin[1],ow.player.cellY+m.kaSeviiSourceOrigin[2]
  end
  local function actor()
    for _,n in ipairs(game.overworld.npcs)do if n.def.name=='KA_SEVII_LINA_ESCORT'then return n end end
  end
  assert(actor()and actor().passable,'visible companion cannot block the player')
  assert(U.shot(game,out..'/chapter-three-escort.png'))
  -- Find a real land route from the current source cell to the south gate.
  local sx,sy=coords();local queue={{sx,sy}};local seen={[sx..','..sy]=true};local at=1;local previous={}
  local tx,ty=43,40
  local steps={{1,0,'right'},{0,1,'down'},{-1,0,'left'},{0,-1,'up'}}
  while queue[at]and not seen[tx..','..ty]do
    local p=queue[at];at=at+1
    for _,d in ipairs(steps)do
      local x,y=p[1]+d[1],p[2]+d[2];local key=x..','..y
      local map,lx,ly=S.location(R.SOURCE,x,y)
      if not seen[key]and map and S.walkable(map,lx,ly)then
        seen[key]=true;previous[key]={x=p[1],y=p[2],dir=d[3]};queue[#queue+1]={x,y}
      end
    end
  end
  assert(seen[tx..','..ty],'forest must have a land return route')
  local route={};local x,y=tx,ty
  while x~=sx or y~=sy do
    local prev=assert(previous[x..','..y]);table.insert(route,1,{x=x,y=y,dir=prev.dir});x,y=prev.x,prev.y
  end
  local crossed={};local followSeen=0
  for index,step in ipairs(route)do
    local arrived=false
    for frame=1,180 do
      local x,y=coords()
      if x==step.x and y==step.y and not game.overworld.player.moving then arrived=true;break end
      if not game.overworld.player.moving then U.hold(game,step.dir,1)else U.wait(1)end
    end
    assert(arrived,'physical escort step failed '..index..' to '..step.x..','..step.y)
    Q.settle();crossed[game.overworld.map.id]=true
    if rescueState().escorting then
      assert(actor(),'companion survives map seam')
      assert(actor().passable,'companion remains passable')
      followSeen=followSeen+1
    end
    if index==math.floor(#route/2)then
      assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
      local a=assert(actor(),'companion restored after real reload')
      local player=game.overworld.player
      assert(math.abs(a.cellX-player.cellX)+math.abs(a.cellY-player.cellY)<=2,'restored companion is nearby')
      assert(rescueState().escorting,'escort persists through reload')
      assert(U.shot(game,out..'/chapter-three-reloaded.png'))
    end
  end
  assert(rescueState().rescued and not rescueState().escorting and not actor(),'surveyor safely leaves party at gate')
  assert(rescueState().landmarks.west and rescueState().landmarks.north,'route observations recorded')
  Q.tap('down');Q.settle()
  assert(S.maps[game.overworld.map.id].kaSeviiSource=='ThreeIsland_BondBridge','real forest exit remains usable')
  p=R.sites.home;U.teleport(game,p.map,p.x-1,p.y,'right');Q.settle();Q.tap('a');U.wait(90)
  assert(U.shot(game,out..'/chapter-three-home.png'));Q.settle()
  assert(S.state().chapterThreeComplete,'rescued surveyor report completes chapter three')
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  assert(S.state().chapterThreeComplete and S.state().chapterTwoComplete,'complete expedition history survives reload')
  local maps=0;for _ in pairs(crossed)do maps=maps+1 end
  print('SEVII_NATIVE_FOREST_RESCUE_PASS',#route,'physical steps',maps,'map fragments',followSeen,'companion checks')
  love.event.quit()
end
