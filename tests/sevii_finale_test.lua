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
local game={save={flags={},inventory={}},data={items={GS_BALL={pocket='KEY_ITEM'}}},
  overworld={map={id='VERMILION_CITY'},player={cellX=0,cellY=0}}}

local actors={};local W={};local P
function W:npc(map,name)return actors[map..':'..name]end
function W:toggleObject(map,name,show)
 game.save.objectToggles=game.save.objectToggles or{};game.save.objectToggles[map]=game.save.objectToggles[map]or{}
 game.save.objectToggles[map][name]=show
end
function W:warpTo(map,x,y)
 game.overworld.map.id=map;game.overworld.player.cellX=x;game.overworld.player.cellY=y
 P.install(game);return true
end
local finish,missing
local ui={talks={},tr=function(en)return en end,box=function(_,_,done)if done then done()end end,
 world=function()return W end,apparition={open=function(_,_,_,done,opts)
  assert(opts.finale,'dedicated finale mode');if missing then return false,'missing-art'end;finish=done;return true
 end},npc=function(map,name,sprite,text,x,y)
  assert(S.walkable(map,x,y),'finale NPC floor')
  local def={name=name,x=x,y=y,sprite=sprite};table.insert(S.maps[map].objects,def)
  local a={x=x,y=y,npc={def=def}}
  function a:position()return self.x,self.y end
  function a:placeAt(x,y)self.x,self.y=x,y end
  actors[map..':'..name]=a
 end}
P=dofile('sevii_finale.lua')(S,ui)
-- game.ready precedes the first map. It must not leave installation locked.
local initialMap=game.overworld.map;game.overworld.map=nil;P.install(game);game.overworld.map=initialMap
local checks=0;local function check(v,why)checks=checks+1;assert(v,why)end
local function place(p,dy)game.overworld.map.id=p.map;game.overworld.player.cellX=p.x;game.overworld.player.cellY=p.y+(dy or 1)end
local function q()return stored.chapters and stored.chapters.seven or{}end
place(P.sites.CAMP);P.install(game)
check(not P.begin(game),'league gate');game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
check(not P.begin(game),'ruins chapter gate');stored.chapterSixComplete=true
check(P.begin(game),'briefing');check(not P.begin(game),'briefing idempotent')
place(P.sites.SEAL);check(not P.seal(game),'cannot skip calibration and relays')
place(P.stones[2]);P.install(game);check(P.support(game)and game.overworld.strengthActive,'support without party Strength')
check(P.reset(game),'accessible stone reset');check(game.overworld.player.cellX==7 and game.overworld.player.cellY==12,'safe reset landing')
local route={'left','left','up','up','right','right','up','up','up','up','up','down','left','left','up','up','right','right','right','left','down','down','down','down','down','left','left','up','right','down','right','up','up','up','up','down','left','left','up','up','right','up','right','right','down','left','left','right','down','down','down','down','down','right','right','up','left','down','left','up','up','up','up'}
local pushes=0
for step,dir in ipairs(route)do
 local delta=({up={0,-1},down={0,1},left={-1,0},right={1,0}})[dir]
 local player=game.overworld.player;local x,y=player.cellX+delta[1],player.cellY+delta[2]
 check(S.walkable(P.keyMap,x,y),'walkable route '..step)
 for _,site in ipairs(P.stones)do
  local a=W:npc(site.map,site.name)
  if a.x==x and a.y==y then
   local bx,by=x+delta[1],y+delta[2]
   check(S.walkable(P.keyMap,bx,by),'push stays on floor')
   for _,b in pairs(actors)do check(not(b~=a and b.npc.def.name:find('STONE_')and b.x==bx and b.y==by),'no stone overlap')end
   a:placeAt(bx,by);P.onBoulderMoved(game,game.overworld,a.npc);pushes=pushes+1;break
  end
 end
 player.cellX,player.cellY=x,y
 if step==30 then
  local positions=J.encode(q().positions);stored=J.decode(J.encode(stored));P.install(game)
  check(J.encode(q().positions)==positions,'push snapshot serializes')
 end
end
check(q().calibrated,'three sockets solved');check(not P.reset(game),'completed calibration cannot be reset')
for _,site in ipairs(P.stones)do check(not W:npc(site.map,site.name).npc.def.pushable,'solved stones locked')end
for _,r in ipairs(P.relays)do
 check(not P.placeRelay(game,r.id),'remote relay rejected')
 place(P.sites[r.id]);check(P.placeRelay(game,r.id),'relay placement '..r.id);check(not P.placeRelay(game,r.id),'relay idempotent')
end
check(P.ready(),'all anchors ready');place(P.sites.CAMP);check(not P.report(game),'cannot report before sealing')
place(P.sites.SEAL);missing=true;check(not P.seal(game)and not stored.seviiRiftSealed,'missing art cannot seal');missing=false
check(P.seal(game)and not stored.seviiRiftSealed,'opening scene grants nothing')
finish();check(stored.seviiRiftSealed and q().antagonistRemains,'local seal only after scene')
check(not P.seal(game),'sealing idempotent');place(P.sites.CAMP)
local keySlots=require('src.inventory.Bag').capacity(game.data,'KEY_ITEM')
for i=1,keySlots do local id='TEST_KEY_'..i;game.data.items[id]={pocket='KEY_ITEM'};game.save.inventory[id]=1 end
local reported,reason=P.report(game)
check(reported and reason=='bag-full'and stored.chapterSevenComplete
  and stored.expeditionComplete,'epilogue completes even with full Key Item pocket')
check(not game.save.inventory.GS_BALL and not q().gsBallGranted,
  'full pocket leaves unique gift pending')
game.save.inventory['TEST_KEY_'..keySlots]=nil
check(P.claimGsBall(game)and game.save.inventory.GS_BALL==1 and q().gsBallGranted,
  'GS Ball collected at camp when pocket has room')
check(not P.claimGsBall(game)and game.save.inventory.GS_BALL==1,
  'GS Ball cannot be claimed twice')
check(not P.consultOakAboutGsBall(game),'Oak consultation requires his lab')
game.overworld.map.id='OAKS_LAB'
check(P.consultOakAboutGsBall(game)and game.save.inventory.GS_BALL==1
  and q().gsBallOakConsulted and stored.orangeIslandsLead=='IVY_GS_BALL',
  'Oak asks Ivy about the GS Ball but leaves it with the trainer')
check(not P.consultOakAboutGsBall(game),'Oak consultation is idempotent')
check(not P.report(game),'epilogue idempotent');stored=J.decode(J.encode(stored));P.install(game)
check(stored.samples.heat and stored.chapterSixComplete,'earlier history retained')
check(stored.futureRiftLead and not stored.giratinaCaught and not stored.giratinaDefeatedForever,'recurring antagonist not caught or ended')
print('PASS finale: '..checks..' checks, '..#route..' moves, '..pushes..' pushes')
