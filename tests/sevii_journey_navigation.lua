-- Physical QA navigation across native cells, map seams and script doors.
-- No warp/teleport API is used here. Failed movement is recorded and replanned.
return function(game,S,Q)
  local U=Q.U;local Map=require('src.world.Map')
  local N={steps=0,seams=0,doors=0,sails=0,blocked={}}
  local maps,solid,links,falls={},{},{},{}
  local dirs={{'up',0,-1,'north'},{'down',0,1,'south'},{'left',-1,0,'west'},{'right',1,0,'east'}}
  local function key(m,x,y)return m..':'..x..':'..y end
  local function at()local o=game.overworld;return o.map.id,o.player.cellX,o.player.cellY end
  for id,m in pairs(S.maps)do
    maps[id]=Map.new(m,game.data.tilesets[m.tileset]);solid[id]={};links[id]={};falls[id]={}
    for _,o in ipairs(m.objects)do if not o.hidden and not o.kaSeviiRoutePassable then solid[id][o.x..','..o.y]=true end end
    for _,w in ipairs(S.links[id])do links[id][w.x..','..w.y]=w end
    for _,w in ipairs(m.kaSeviiFalls or{})do falls[id][w.x..','..w.y]=true end
  end
  local function usable(id,x,y)
    local m=maps[id]
    local occupied=id==N.currentMap and N.currentSolid or solid[id]
    return m and m:inBounds(x,y)and not occupied[x..','..y]
      and not(falls[id][x..','..y]and(N.avoidThinIce or N.iceVisit and N.iceVisit.map==id and N.iceVisit.cracks[x..','..y]))
      and(m:isWalkableCell(x,y)or m:isWaterCell(x,y))
      and not(N.landOnly and not m:isWalkableCell(x,y))
  end
  local function edge(p,d)
    local m=maps[p.map];local x,y=p.x+d[2],p.y+d[3];local id=p.map;local kind='step'
    if not m:inBounds(x,y)then
      local c=m:connection(d[4]);if not c or not maps[c.map]then return end
      id=c.map;local dest=maps[id]
      if d[1]=='up'then x,y=p.x-c.offset*2,dest.def.height*2-1
      elseif d[1]=='down'then x,y=p.x-c.offset*2,0
      elseif d[1]=='left'then x,y=dest.def.width*2-1,p.y-c.offset*2
      else x,y=0,p.y-c.offset*2 end
      kind='seam'
    else
      for _,l in ipairs(S.maps[p.map].kaSeviiLedges or{})do
        if l.facing==d[1]and m:cellTile(p.x,p.y)==l.standingTile and m:cellTile(x,y)==l.ledgeTile then
          x,y=x+d[2],y+d[3];break
        end
      end
    end
    if not usable(id,x,y)then return end
    if kind=='seam'and S.sourceElevation then
      local OW=require('src.world.OverworldController')
      local probe=setmetatable({map=m,player={cellX=p.x,cellY=p.y,surfing=m:isWaterCell(p.x,p.y)}},{__index=OW})
      if not S.sourceElevation.canCross(probe,d[1])then return end
    end
    if kind=='step'and id==p.map and math.abs(x-p.x)+math.abs(y-p.y)==1
        and m:isWalkableCell(p.x,p.y)and m:isWalkableCell(x,y)
        and not Q.pairClear(m,p.x,p.y,x,y)then return end
    local water=maps[id]:isWaterCell(x,y)and not maps[id]:isWalkableCell(x,y)
    -- Surf's native field menu cannot mount onto a tile beyond this map's
    -- bounds. Enter water before crossing a water seam instead.
    if kind=='seam'and water and not m:isWaterCell(p.x,p.y)then return end
    local w=links[id][x..','..y]
    if w then id,x,y,kind=w.map,w.toX,w.toY,'door'end
    return{map=id,x=x,y=y,dir=d[1],kind=kind,water=water,prev=p}
  end
  function N.go(id,gx,gy,targets)
    assert(S.maps[id],'journey only navigates imported maps')
    local function goal(m,x,y)return m==id and(targets and targets[x..','..y]or not targets and x==gx and y==gy)end
    Q.settle();local retries=0
    while true do
      local cur,sx,sy=at();if goal(cur,sx,sy)then return end
      N.iceVisit=S.state().iceVisit
      maps[cur]=game.overworld.map
      N.currentMap=cur;N.currentSolid={}
      local collision=require('src.world.Collision');local ow=game.overworld
      for y=0,ow.map.def.height*2-1 do for x=0,ow.map.def.width*2-1 do
        if collision.occupied(ow.entities,x,y,ow.player)then N.currentSolid[x..','..y]=true end
      end end
      local start={map=cur,x=sx,y=sy};local queue={start};local seen={[key(cur,sx,sy)]=true};local index=1;local finish
      while queue[index]do
        local p=queue[index];index=index+1
        if goal(p.map,p.x,p.y)then finish=p;break end
        for _,d in ipairs(dirs)do
          local n=edge(p,d)
          if n then local k=key(n.map,n.x,n.y)
            if not seen[k]and not N.blocked[key(p.map,p.x,p.y)..'>'..k]then seen[k]=true;queue[#queue+1]=n end
          end
        end
      end
      if not finish then
        print('JOURNEY_NO_PATH_VISITED',#queue,'target',id)
        for cell,dir in pairs(targets or{})do print('JOURNEY_NO_PATH_TARGET',cell,dir,tostring(seen[id..':'..cell:gsub(',',':')]))end
        local visited={};for _,p in ipairs(queue)do visited[p.map]=(visited[p.map]or 0)+1 end
        for m,count in pairs(visited)do print('JOURNEY_NO_PATH_MAP',m,count)end
        for src,rows in pairs(links)do for cell,w in pairs(rows)do if w.map==id then
          print('JOURNEY_NO_PATH_DOOR',src,cell,tostring(usable(src,w.x,w.y)),w.toX,w.toY)
          for _,d in ipairs(dirs)do local x,y=w.x-d[2],w.y-d[3]
            local n=maps[src]:inBounds(x,y)and edge({map=src,x=x,y=y},d)
            print('JOURNEY_NO_PATH_APPROACH',d[1],tostring(seen[key(src,x,y)]),n and key(n.map,n.x,n.y)or'blocked')
          end
        end end end
        for _,d in ipairs(dirs)do
          local n=edge(start,d);print('JOURNEY_NO_PATH_EDGE',d[1],n and key(n.map,n.x,n.y)or'blocked')
        end
      end
      assert(finish,'no physical journey path '..key(cur,sx,sy)..' -> '..key(id,gx,gy))
      local route={};while finish.prev do table.insert(route,1,finish);finish=finish.prev end
      print('JOURNEY_ROUTE',cur,sx,sy,id,gx,gy,#route)
      local retry=false
      for _,n in ipairs(route)do
        local before,bx,by=at()
        if n.water and not game.overworld.player.surfing then
          print('JOURNEY_SURF',before,bx,by,n.dir,n.map,n.x,n.y)
          U.hold(game,n.dir,1);Q.field('SURF');Q.settle()
          if not game.overworld.player.surfing then
            print('JOURNEY_SURF_REFUSED',before,bx,by,n.dir)
            N.blocked[key(before,bx,by)..'>'..key(n.map,n.x,n.y)]=true
            retries=retries+1;assert(retries<20,'no usable native Surf approach');retry=true;break
          end
        end
        local arrived=false
        for frame=1,180 do
          local m,x,y=at();local ow=game.overworld
          if m~=before and m~=n.map then break end
          if m==n.map and x==n.x and y==n.y and not ow.player.moving and not ow.transitioning then arrived=true;break end
          if game.stack:top()~=ow then Q.settle()
          elseif not ow.player.moving and not ow.transitioning then U.hold(game,n.dir,1)
          else U.wait(1)end
        end
        Q.settle()
        -- A door on a fragment edge first crosses the seam, then completes
        -- its scripted doorway. Judge the settled arrival, not that transient
        -- intermediate map, before recording a blocked edge.
        local settledMap,settledX,settledY=at()
        arrived=settledMap==n.map and settledX==n.x and settledY==n.y
        if not arrived then
          local m,x,y=at();print('JOURNEY_BLOCKED',before,bx,by,n.dir,n.map,n.x,n.y,'actual',m,x,y)
          N.blocked[key(before,bx,by)..'>'..key(n.map,n.x,n.y)]=true
          retries=retries+1;assert(retries<20,'physical route repeatedly blocked');retry=true;break
        end
        N.steps=N.steps+1
        if n.kind=='seam'then N.seams=N.seams+1 elseif n.kind=='door'then N.doors=N.doors+1 end
      end
      if not retry then local m,x,y=at();assert(goal(m,x,y));return end
    end
  end
  function N.visit(p)
    -- A floor tile can be enclosed by walls or the NPC itself. Search all
    -- adjacent candidates together rather than assuming the southern one.
    local targets,dry={},{}
    for _,d in ipairs{{0,1,'up'},{-1,0,'right'},{1,0,'left'},{0,-1,'down'}}do
      if usable(p.map,p.x+d[1],p.y+d[2])then
        targets[(p.x+d[1])..','..(p.y+d[2])]=d[3]
        if maps[p.map]:isWalkableCell(p.x+d[1],p.y+d[2])then dry[(p.x+d[1])..','..(p.y+d[2])]=d[3]end
      end
      -- Native Gen1 talk reaches an NPC two cells away across a registered
      -- counter. Nurses remain behind their source-authored solid counter.
      local map=maps[p.map]
      if map:isCounterCell(p.x+d[1],p.y+d[2])then
        local x,y=p.x+d[1]*2,p.y+d[2]*2
        if usable(p.map,x,y)then
          targets[x..','..y]=d[3]
          if map:isWalkableCell(x,y)then dry[x..','..y]=d[3]end
        end
      end
    end
    assert(next(targets),'no interaction cell at '..key(p.map,p.x,p.y))
    if next(dry)then targets=dry end
    N.go(p.map,p.x,p.y,targets)
    local _,x,y=at();U.hold(game,assert(targets[x..','..y]),1)
  end
  function N.talk(p)N.visit(p);Q.tap('a');U.wait(10)end
  function N.sail(island)
    local here=S.maps[game.overworld.map.id].kaSeviiIsland
    N.talk({map=S.harbors[here],x=7,y=4})
    Q.choose(function(r)return r.value==island end);Q.settle()
    assert(game.overworld.map.id==(island==0 and'VERMILION_CITY'or S.harbors[island]),'native ferry destination')
    N.sails=N.sails+1
  end
  return N
end
