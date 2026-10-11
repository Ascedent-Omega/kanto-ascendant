package.path=assert(os.getenv('KASC_ENGINE'))..'/?.lua;'..package.path
local J=require('src.link.Json')
local f=assert(io.open('assets/sevii_local/bundle.json','rb'));local bundle=J.decode(f:read('*a'));f:close()
local function clone(v)if type(v)~='table'then return v end;local t={};for k,x in pairs(v)do t[k]=clone(x)end;return t end
local stored={stage=3,chapterOneComplete=true,samples={heat=true,drift=true}}
local S={maps={},links={}}
local tiles={};for _,row in ipairs(bundle.tilesets)do tiles[row.id]=row end
for _,row in ipairs(bundle.maps)do S.maps[row.id]=row end
function S.location(source,x,y)
  for id,m in pairs(S.maps)do local o,z=m.kaSeviiSourceOrigin,m.kaSeviiSourceSize
    if m.kaSeviiSource==source and x>=o[1]and y>=o[2]and x<o[1]+z[1]and y<o[2]+z[2]then return id,x-o[1],y-o[2]end
  end
end
function S.walkable(id,x,y)
  local m=S.maps[id];if not m or x<0 or y<0 or x>=m.width*2 or y>=m.height*2 then return false end
  local k=tiles[m.tileset].sourceCellCollision[m.blocks[math.floor(y/2)*m.width+math.floor(x/2)+1]+1][y%2*2+x%2+1]
  return k=='FLOOR'or k=='GRASS'
end
function S.state()return clone(stored)end
function S.persist(s)stored=clone(s)end
function S.unlocked(g)return g.save.flags.EVENT_BEAT_CHAMPION_RIVAL==true end
local game={save={flags={}},overworld={map={id='VERMILION_CITY'},player={cellX=0,cellY=0}}}
local actors={};local safeActors={};local serial=0;local walked=0
local W={}
function W:toggleObject(map,name,v)
  game.save.objectToggles=game.save.objectToggles or{};game.save.objectToggles[map]=game.save.objectToggles[map]or{}
  game.save.objectToggles[map][name]=v
end
function W:spawnNpc(map,def)
  serial=serial+1;local id=map..serial
  local a={map=map,x=def.x,y=def.y,npc={}}
  function a:position()return self.x,self.y end
  function a:setPassable(v)self.passable=v end
  function a:isMoving()return false end
  function a:placeAt(x,y)self.x,self.y=x,y end
  function a:stepNow(dir)
    local d=({up={0,-1},down={0,1},left={-1,0},right={1,0}})[dir]
    self.x,self.y=self.x+d[1],self.y+d[2];walked=walked+1
    assert(S.walkable(self.map,self.x,self.y),'companion walks through floor')
  end
  actors[id]=a;return id
end
function W:npc(map,id)
  local a=actors[id]
  if a then return a.map==map and a or nil end
  if map==game.overworld.map.id and id:match('_SAFE$')
      and game.save.objectToggles and game.save.objectToggles[map]
      and game.save.objectToggles[map][id]then
    local safe=safeActors[id]
    if not safe then
      safe={passable=false,setPassable=function(self,value)self.passable=value end}
      safeActors[id]=safe
    end
    return safe
  end
end
function W:removeNpc(id)actors[id]=nil end
function S.refreshCellPictures(_,metadata,marked)
  local m=S.maps[game.overworld.map.id];if not m then return end
  for _,row in ipairs(m[metadata]or{})do
    local mask=0;for _,p in ipairs(row.cells)do if marked[p.x..','..p.y]then mask=mask+p.bit end end
    m.blocks[row.y*m.width+row.x+1]=row.variants[tostring(mask)]
  end
end
local ui={talks={},world=function()return W end,tr=function(en)return en end,
  box=function(_,_,done)if done then done()end end,
  npc=function(map,name,sprite,text,x,y)
    assert(S.walkable(map,x,y),'station NPC floor')
    local m=S.maps[map];m.objects[#m.objects+1]={name=name,x=x,y=y}
  end}
local P=dofile('sevii_station.lua')(S,ui)
local checks=0;local function check(v,why)checks=checks+1;assert(v,why)end
local function place(p,dx,dy)
  game.overworld.map.id=p.map;game.overworld.player.cellX=p.x+(dx or 0);game.overworld.player.cellY=p.y+(dy or 0)
end
local function q()return stored.chapters and stored.chapters.five or{}end
place(P.sites.NOAH,0,-1);P.install(game)
check(not S.walkable(P.map,P.gate.x,P.gate.y),'unpowered gate is physically closed')
check(not P.begin(game),'champion gate');game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
check(not P.begin(game),'previous chapter gate');stored.chapterFourComplete=true
check(P.begin(game),'briefing on location');check(not P.begin(game),'briefing idempotent')
check(not P.isolate(game),'remote isolation rejected')
place(P.sites.CONSOLE,0,1)
check(P.load()==3,'probe consumes full supply')
check(not P.toggle(game,'AIR'),'isolation required');check(P.isolate(game),'probe disconnected')
check(P.load()==0,'supply free after isolation');check(not P.isolate(game),'isolation idempotent')
check(not P.toggle(game,'BOGUS'),'unknown circuit rejected')
check(P.toggle(game,'AIR')and P.load()==2,'air costs two')
check(not P.toggle(game,'RADIO')and not q().circuits.RADIO,'overload leaves previous allocation intact')
check(not S.walkable(P.map,P.gate.x,P.gate.y),'air alone cannot open gate')
check(P.toggle(game,'DOOR')and P.load()==3,'airlock costs one')
check(S.walkable(P.map,P.gate.x,P.gate.y),'both rescue circuits open physical gate')
check(not P.callMara(game),'cannot complete before rescue')
place(P.sites.ADA,0,1);check(P.startRescue(game),'begin group rescue')
local count=0;for _,a in pairs(actors)do count=count+1;check(a.passable,'group cannot block player')end
check(count==3,'two humans and Pokemon are real actors')
check(not P.startRescue(game),'no duplicate group')
place(P.sites.CONSOLE,0,1);check(not P.toggle(game,'AIR'),'cannot cut power during evacuation')
place({map='VERMILION_CITY',x=27,y=26});P.install(game)
check(not q().escorting and q().separated and not next(actors),'abandon resets crew only')
check(q().circuits.AIR and q().circuits.DOOR and q().isolated,'repair progress retained')
place(P.sites.ADA,0,1);check(P.startRescue(game),'rescue can restart')
-- Walk a floor path that avoids the remaining static station actors.
local start={x=24,y=6};local target={x=24,y=24};local queue={start};local seen={['24,6']=true};local prev={};local at=1
local blocked={}
for _,id in ipairs{'NOAH','CONSOLE','EMERGENCY'}do local p=P.sites[id];blocked[p.x..','..p.y]=true end
while queue[at]and not seen['24,24']do
  local p=queue[at];at=at+1
  for _,d in ipairs{{1,0},{0,1},{-1,0},{0,-1}}do
    local x,y=p.x+d[1],p.y+d[2];local key=x..','..y
    if not seen[key]and not blocked[key]and S.walkable(P.map,x,y)then
      seen[key]=true;prev[key]=p;queue[#queue+1]={x=x,y=y}
    end
  end
end
check(seen['24,24'],'physical evacuation route exists')
local route={};local p=target
while p.x~=start.x or p.y~=start.y do table.insert(route,1,p);p=prev[p.x..','..p.y]end
for index,p in ipairs(route)do
  place({map=P.map,x=p.x,y=p.y});P.onStep(game,game.overworld,p.x,p.y)
  if index==math.floor(#route/2)then
    stored=J.decode(J.encode(stored));actors={};P.install(game)
    local count=0;for _ in pairs(actors)do count=count+1 end
    check(count==3 and q().escorting,'group recreated after actual serialization')
  end
end
check(q().rescued and not q().escorting and not next(actors),'entire group reaches assembly')
check(walked>=#route,'followers actually stepped')
check(not stored.chapterFiveComplete,'radio report required')
for _,c in ipairs(P.crew)do
  check(game.save.objectToggles[P.map]['KA_SEVII_STATION_'..c.id..'_SAFE'],'crew visible at assembly')
  check(not game.save.objectToggles[P.map]['KA_SEVII_STATION_'..c.id],'no duplicate stranded crew')
  check(W:npc(P.map,'KA_SEVII_STATION_'..c.id..'_SAFE').passable,'rescued companions cannot close the only assembly exit')
end
-- An already completed older save may stand behind the newly visible crew.
stored=J.decode(J.encode(stored));safeActors={};game.overworld.npcs={}
place({map=P.map,x=22,y=23});P.install(game)
for _,c in ipairs(P.crew)do
  check(W:npc(P.map,'KA_SEVII_STATION_'..c.id..'_SAFE').passable,'loaded rescued crew leave an escape route')
end
place(P.sites.CONSOLE,0,1)
check(not P.callMara(game),'radio requires power')
check(P.toggle(game,'AIR')and P.toggle(game,'RADIO'),'redirect power after rescue')
check(S.walkable(P.map,P.gate.x,P.gate.y),'secured gate remains open without air')
check(P.callMara(game),'radio report completes chapter')
check(not P.callMara(game),'report idempotent')
stored=J.decode(J.encode(stored));P.install(game)
check(stored.chapterFiveComplete and stored.chapterFourComplete and stored.samples.heat,'earlier receipts retained')
check(not stored.giratinaCaught and not stored.seviiRiftSealed,'not the finale')
-- Older saves inside the room can release the gate without quest progress.
stored.chapters.five={};place(P.sites.EMERGENCY,0,-1);P.install(game)
check(not S.walkable(P.map,P.gate.x,P.gate.y),'reset gate closed')
check(P.emergencyRelease(game)and S.walkable(P.map,P.gate.x,P.gate.y),'inside safety release opens escape')
check(not q().briefed and not q().rescued and not q().complete,'safety release grants no quest progress')
print('PASS station: '..checks..' checks, '..#route..' route steps, '..walked..' companion steps')
