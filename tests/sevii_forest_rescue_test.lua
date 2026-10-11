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
local game={save={flags={}},overworld={map={id='VERMILION_CITY'},player={cellX=0,cellY=0},npcs={}}}
local actors={};local serial=0;local moves=0
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
    self.x,self.y=self.x+d[1],self.y+d[2];moves=moves+1
  end
  actors[id]=a;return id
end
function W:npc(map,id)local a=actors[id];return a and a.map==map and a or nil end
function W:removeNpc(id)actors[id]=nil end
local messages={};local ui={talks={},world=function()return W end,tr=function(en)return en end,
  box=function(_,text,done)messages[#messages+1]=text;if done then done()end end,
  npc=function(map,name,sprite,text,x,y)
    assert(S.walkable(map,x,y),'authored rescue NPC floor')
    local m=S.maps[map];m.objects[#m.objects+1]={name=name,x=x,y=y}
  end}
local R=dofile('sevii_forest_rescue.lua')(S,ui)
local checks=0;local function check(v,why)checks=checks+1;assert(v,why)end
local function place(p,dx,dy)
  game.overworld.map.id=p.map;game.overworld.player.cellX=p.x+(dx or 0);game.overworld.player.cellY=p.y+(dy or 0)
end
local function q()return stored.chapters and stored.chapters.three or{}end
place(R.sites.stranded,0,1)
check(not R.begin(game),'League gate');game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
check(not R.begin(game),'previous chapter gate');stored.chapterTwoComplete=true
place(R.sites.home,1,0);check(not R.begin(game),'remote rescue rejected')
check(not R.report(game),'cannot skip rescue')
place(R.sites.stranded,0,1);check(R.begin(game),'start near stranded surveyor')
check(not R.begin(game),'no duplicate escort')
check(q().escorting and next(actors),'actual companion spawned')
local _,a=next(actors);check(a.passable,'companion passable')
check(game.save.objectToggles[R.sites.stranded.map].KA_SEVII_LINA_STRANDED==false,'stranded duplicate hidden')
check(not R.arrive(game),'cannot complete from wrong place')
game.overworld.player.cellX=5
R.onStep(game,game.overworld,5,7)
check(moves==1,'companion walks behind player')
check(q().companion.x==4 and q().companion.y==7,'serializable follower position')
stored=J.decode(J.encode(stored));actors={}
R.install(game);check(next(actors)~=nil and q().escorting,'companion recreated after reload')
place({map='VERMILION_CITY',x=27,y=26});R.install(game)
check(not q().escorting and q().separated and not next(actors),'escape resets only escort')
check(game.save.objectToggles[R.sites.stranded.map].KA_SEVII_LINA_STRANDED==true,'surveyor returns after separation')
check(stored.chapterTwoComplete and stored.samples.heat,'previous progress retained')
place(R.sites.stranded,0,1);check(R.begin(game),'resume interrupted rescue')
place(R.sites.exit);check(R.arrive(game),'physical exit completes rescue')
check(q().rescued and not q().escorting and not next(actors),'companion removed after arrival')
check(not stored.chapterThreeComplete,'still need debrief')
check(game.save.objectToggles[R.sites.home.map].KA_SEVII_LINA_HOME==true,'surveyor appears at home')
check(not R.report(game),'remote debrief rejected')
place(R.sites.home,1,0);check(R.report(game),'debrief completes chapter')
check(not R.report(game),'debrief idempotent')
check(stored.chapterThreeComplete and stored.stage==3,'preserve old generation evidence')
stored=J.decode(J.encode(stored));R.install(game)
check(stored.chapterThreeComplete and q().complete,'completion survives reload')
check(not next(actors),'no postgame duplicate companion')
print('PASS forest rescue: '..checks..' checks')
