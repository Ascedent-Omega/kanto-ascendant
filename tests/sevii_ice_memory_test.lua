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
local pictures={};function S.refreshCellPictures(_,metadata,marked)pictures=clone(marked)end
local ui={talks={},tr=function(en)return en end,box=function(_,_,done)if done then done()end end,
  npc=function(map,name,sprite,text,x,y)assert(S.walkable(map,x,y),'ice NPC floor')end}
local I=dofile('sevii_ice_memory.lua')(S,ui)
local checks=0;local function check(v,why)checks=checks+1;assert(v,why)end
local function place(p,dx,dy)
  game.overworld.map.id=p.map;game.overworld.player.cellX=p.x+(dx or 0);game.overworld.player.cellY=p.y+(dy or 0)
end
local function q()return stored.chapters and stored.chapters.four or{}end
place(I.sites.GUIDE,-1,0);check(not I.begin(game),'champion gate')
game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
check(not I.begin(game),'chapter three gate');stored.chapterThreeComplete=true
check(I.begin(game),'local guide briefing');check(not I.begin(game),'briefing idempotent')
check(not I.readRecord(game),'remote reading refused')
place(I.route[1]);check(not I.startTrace(game),'cannot skip record')
check(not I.report(game),'cannot skip trace')
place(I.sites.RECORD,-1,0);check(I.readRecord(game),'record read on location')
check(not I.readRecord(game),'record idempotent')
place(I.sites.ANCHOR,-1,0);check(not I.startTrace(game),'must start from south')
place(I.route[1]);check(I.startTrace(game),'start physical trace')
check(pictures['12,16'],'first mark visible')
place(I.route[3]);I.onStep(game,game.overworld,11,15)
check(not q().tracing and not q().traced and q().recordRead,'skipping a cell resets only trace')
check(not next(pictures),'failed trace pictures cleared')
place(I.route[1]);check(I.startTrace(game),'retry')
place(I.sites.GUIDE,-1,0);I.install(game)
check(not q().tracing and q().recordRead,'leaving resets only active trial')
place(I.route[1]);check(I.startTrace(game),'start after separation')
for index=2,#I.route do
  local p=I.route[index];place(p);I.onStep(game,game.overworld,p.x,p.y)
  check(q().traceIndex==index,'physical route step '..index)
  if index==4 then
    stored=J.decode(J.encode(stored));I.install(game)
    check(q().tracing and q().traceIndex==4,'partial route reload retained')
    check(pictures['11,14']and not pictures['13,14'],'partial route graphics exact')
  end
end
check(q().traced and not q().tracing,'closed ring complete')
local count=0;for _ in pairs(pictures)do count=count+1 end
check(count==8,'all eight unique floor cells marked')
check(not stored.chapterFourComplete,'report required')
check(not I.report(game),'remote report refused')
check(not I.startTrace(game),'completed trial cannot restart')
place(I.sites.GUIDE,-1,0);check(I.report(game),'local debrief completes chapter')
check(not I.report(game),'debrief idempotent')
check(stored.chapterFourComplete and stored.chapterThreeComplete and stored.samples.heat,'previous receipts preserved')
stored=J.decode(J.encode(stored));I.install(game)
check(stored.chapterFourComplete and q().complete,'completed chapter reload retained')
check(not stored.giratinaCaught and not stored.seviiRiftSealed,'reconstruction is not final victory')
-- Generated variant collision is identical for every crack combination.
for _,m in pairs(S.maps)do
  for _,metadata in ipairs{'kaSeviiIceBlocks','kaSeviiTraceBlocks'}do
    for _,row in ipairs(m[metadata]or{})do
      local base=tiles[m.tileset].sourceCellCollision[row.variants['0']+1]
      for _,bid in pairs(row.variants)do
        local variant=tiles[m.tileset].sourceCellCollision[bid+1]
        for i=1,4 do check(base[i]==variant[i],'crack graphics preserve native collision')end
      end
    end
  end
end
print('PASS ice memory: '..checks..' checks')
