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

local seenScene,finish,missing
local ui={talks={},tr=function(en)return en end,box=function(_,_,done)if done then done()end end,
 npc=function(map,name,sprite,text,x,y)assert(S.walkable(map,x,y),'ruin NPC floor')end,
 apparition={open=function(_,_,_,done)if missing then return false,'missing-art'end;seenScene=true;finish=done;return true end}}
local P=dofile('sevii_ruins.lua')(S,ui)
local checks=0;local function check(v,why)checks=checks+1;assert(v,why)end
local function place(p)game.overworld.map.id=p.map;game.overworld.player.cellX=p.x;game.overworld.player.cellY=p.y+1 end
local function q()return stored.chapters and stored.chapters.six or{}end
place(P.sites.RESEARCHER);check(not P.begin(game),'league gate')
game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true;check(not P.begin(game),'station gate')
stored.chapterFiveComplete=true;check(P.begin(game),'briefing');check(not P.begin(game),'idempotent briefing')
place(P.sites.ANCHOR);check(not P.witness(game),'cannot bypass route');check(not P.report(game),'remote report')
local exits={{6,1},{1,5},{11,5},{6,9}}
local function warp(i,x,y)
 game.overworld.map.id=P.floors[i];P.beforeWarp(game,game.overworld,x,y,{})
end
warp(1,6,1);check(q().depth==0,'must read inscription')
for i=1,4 do
 place(P.sites['STONE_'..i]);check(P.read(game,i),'read '..i)
 if i==1 then warp(i,11,5);check(q().depth==0,'wrong exit resets route')end
 warp(i,exits[i][1],exits[i][2]);check(q().depth==i,'physical route depth '..i)
 game.overworld.map.id=i==4 and P.sites.ANCHOR.map or P.floors[i+1]
 stored=J.decode(J.encode(stored));P.install(game);check(q().depth==i,'serialized route survives '..i)
end
place(P.sites.ANCHOR);missing=true;check(not P.witness(game)and not q().witnessed,'missing art grants nothing');missing=false
check(P.witness(game)and seenScene and not q().witnessed,'scene begins without early receipt')
finish();check(q().witnessed and q().identity=='GIRATINA','completed scene receipt')
check(not P.witness(game),'no repeated apparition');check(not stored.chapterSixComplete,'report still required')
place(P.sites.RESEARCHER);check(P.report(game),'report completes');check(not P.report(game),'report idempotent')
check(stored.chapterSixComplete and stored.chapterFiveComplete,'previous progress intact')
check(not stored.giratinaCaught and not stored.seviiRiftSealed,'no catch or finale receipt')
stored.chapters.six={briefed=true,depth=2,inscriptions={['1']=true,['2']=true}}
game.overworld.map.id='VERMILION_CITY';P.install(game)
check(q().depth==0 and q().inscriptions['2'],'abandon resets route but retains clues')
print('PASS ruins: '..checks..' checks')
