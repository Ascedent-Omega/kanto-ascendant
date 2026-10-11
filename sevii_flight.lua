-- Seven outdoor Fly landings. Ferries remain available throughout the story.
return function(mod,S)
  local F={OWNER='kasc.sevii-flight/v1',points={},byMap={}}
  local coordinates={
    {86,62},{189,131},{351,141},{299,52},{83,214},{224,241},{358,251},
  }
  local warps,order={},{}
  for island=1,7 do
    local harbor=assert(S.harbors[island],'Sevii harbor missing')
    local exit=assert(S.links[harbor][1],'Sevii harbor exit missing')
    assert(S.maps[exit.map].outdoor and S.walkable(exit.map,exit.toX,exit.toY),
      'Sevii Fly needs a safe outdoor landing')
    assert(not F.byMap[exit.map],'Sevii Fly destinations share a map')
    local point={island=island,map=exit.map,x=exit.toX,y=exit.toY,
      chartX=coordinates[island][1],chartY=coordinates[island][2]}
    F.points[island]=point;F.byMap[point.map]=point
    warps[point.map]={x=point.x,y=point.y}
    order[#order+1]=point.map
  end
  mod.content.field:patch('flyWarps',warps)
  mod.content.field:patch('flyOrder',{__append=order})

  -- GBA map indices are deliberately retained for every other Sevii system.
  -- The Gen 1 Fly gate treats any indexed map above the eleven Kanto towns
  -- as ineligible, so only these seven authored landings need an exception.
  local Map=require('src.world.Map')
  if not Map.__kascSeviiFlyWrapped then
    local original=Map.isFlyTown
    Map.isFlyTown=function(def)
      local owner=Map.__kascSeviiFlyOwner
      if owner and def and owner.byMap[def.id]then
        return owner.unlocked()
      end
      return original(def)
    end
    Map.__kascSeviiFlyWrapped=true
  end
  Map.__kascSeviiFlyOwner=F

  function F.unlocked()
    return S.state().chapterFiveComplete==true
  end
  function F.visit(game,island)
    local point=F.points[island]
    if not point or not game or not game.save then return false end
    local s=S.state()
    s.chartVisited=s.chartVisited or{}
    if not s.chartVisited[tostring(island)]or not s.chartUnlocked then
      s.chartUnlocked=true
      s.chartVisited[tostring(island)]=true
      S.persist(s)
    end
    if F.unlocked()then
      game.save.visited=game.save.visited or{}
      game.save.visited[point.map]=true
    end
    return true
  end
  function F.chartUnlocked()
    return S.state().chartUnlocked==true
  end
  function F.sync(game)
    if not(F.unlocked()and game and game.save)then return false end
    game.save.visited=game.save.visited or{}
    local chart=S.state().chartVisited or{}
    for island,point in ipairs(F.points)do
      if chart[tostring(island)]then game.save.visited[point.map]=true end
    end
    return true
  end
  function F.visited(game,island)
    local point=F.points[island]
    if not point then return false end
    local s=S.state()
    return s.chartVisited and s.chartVisited[tostring(island)]==true
      or game and game.save and game.save.visited
        and game.save.visited[point.map]==true or false
  end
  function F.eligible(game,island)
    return F.unlocked() and F.visited(game,island)
  end
  function F.currentIsland(game)
    local id=game and game.overworld and game.overworld.map
      and game.overworld.map.id
    local map=id and S.maps[id]
    return map and map.kaSeviiIsland or nil
  end
  function F.install()
    local Overworld=require('src.world.OverworldController')
    if not Overworld.__kascSeviiFlightWrapped then
      local original=Overworld.flyTo
      Overworld.flyTo=function(self,mapId)
        local owner=Overworld.__kascSeviiFlightOwner
        local id=self.map and self.map.id
        if owner and id and owner.maps[id]and not owner.unlocked()then
          return false
        end
        return original(self,mapId)
      end
      Overworld.__kascSeviiFlightWrapped=true
    end
    Overworld.__kascSeviiFlightOwner={maps=S.maps,unlocked=F.unlocked}
  end
  return F
end
