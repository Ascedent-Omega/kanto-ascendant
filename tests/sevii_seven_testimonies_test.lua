local function copy(v)if type(v)~='table'then return v end;local t={};for k,x in pairs(v)do t[k]=copy(x)end;return t end
local saved={expeditionComplete=true,seviiRiftSealed=true,mysteries={}};local owned=false
local S={maps={},links={},state=function()return copy(saved)end,persist=function(s)saved=copy(s)end,
 walkable=function()return true end,unlocked=function(g)return g.champion end,assetsReady=function()return true end,
 chapters={journal=function()return'EXPEDITION'end},legendPolicy={history={owned=function()return owned end}}}
function S.location(id,x,y)S.maps[id]=S.maps[id]or{objects={}};S.links[id]={};return id,x,y end
local backend={byKey={['dex:493']='ARCEUS'},bySpecies={ARCEUS='dex:493'}}
local E=dofile('sevii_special_encounters.lua')(S,{backendSpecies=function()return backend end,
 generationRules={peekSpeciesAvailable=function()return true end}});S.specialEncounters=E
local g={champion=true,save={},data={pokemon={ARCEUS={}}},overworld={map={},player={}}}
local A=dofile('sevii_seven_testimonies.lua')(S,{tr=function(en)return en end,box=function()end,talks={},
 npc=function(m,n,s,t,x,y)table.insert(S.maps[m].objects,{name=n,x=x,y=y})end})
local n=0;local function check(v,m)n=n+1;assert(v,m)end
local function at(id)local p=A.sites[id];g.overworld.map.id=p.map;g.overworld.player.cellX=p.x;g.overworld.player.cellY=p.y+1 end
local function denied(reason,f,...)local ok,why=f(...);check(not ok and why==reason,reason..': '..tostring(why))end
check(E.rows.ARCEUS.dex==493 and E.rows.ARCEUS.level==80,'canonical capstone encounter')
at('BOOK_1');denied('briefing-required',A.collect,g,1)
at('SORA');g.champion=false;denied('league-required',A.begin,g);g.champion=true
saved.expeditionComplete=false;denied('finale-required',A.begin,g);saved.expeditionComplete=true
check(A.begin(g),'book can begin with unfinished side stories');denied('already-briefed',A.begin,g)
denied('pages-required',A.compile,g)
at('ARCEUS');denied('book-required',A.witness,g);denied('trial-required',E.availability,g,'ARCEUS')
denied('unknown-report',A.collect,g,8);check(not A.sourceReady(8),'unknown source rejected')
for i,row in ipairs(A.rows)do
 at('BOOK_'..i);denied('research-required',A.collect,g,i)
 saved.mysteries[row.key]={[row.flag]=true}
 check(A.sourceReady(i),'source research ready '..row.key)
 check(A.collect(g,i),'copy completed report '..i);denied('already-copied',A.collect,g,i)
 saved=copy(saved);check(A.record().pages[tostring(i)],'page survives serialization '..i)
end
check(not saved.mysteries.heatran.caught and not saved.specialCaptures,'no legendary capture receipt needed')
owned=true;at('SORA');check(A.compile(g),'old owner can complete island book')
check(A.record().complete and A.record().title=='SEVII_SEVEN_TESTIMONIES','durable completion')
denied('already-complete',A.compile,g);denied('legend_owned',E.availability,g,'ARCEUS')
owned=false;denied('trial-required',E.availability,g,'ARCEUS')
at('ARCEUS');check(A.witness(g),'read book at actual altar');denied('already-witnessed',A.witness,g)
check(E.availability(g,'ARCEUS'),'first encounter only after book and audience')
owned=true;denied('legend_owned',E.availability,g,'ARCEUS')
check(S.chapters.journal():find('SEVEN TESTIMONIES COMPLETE',1,true),'capstone in journal')
check(saved.seviiRiftSealed and saved.expeditionComplete,'main ending unchanged')
print('PASS Sevii seven testimonies: '..n..' checks')
