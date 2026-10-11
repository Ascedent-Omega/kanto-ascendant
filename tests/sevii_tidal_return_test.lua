local function copy(v)if type(v)~='table'then return v end;local t={};for k,x in pairs(v)do t[k]=copy(x)end;return t end
local saved={expeditionComplete=true,seviiRiftSealed=true};local owned={}
local S={maps={},links={},state=function()return copy(saved)end,persist=function(s)saved=copy(s)end,
 walkable=function()return true end,unlocked=function(g)return g.champion end,assetsReady=function()return true end,
 chapters={journal=function()return'EXPEDITION'end},legendPolicy={history={owned=function(_,id)return owned[id]==true end}}}
function S.location(id,x,y)S.maps[id]=S.maps[id]or{objects={}};S.links[id]={};return id,x,y end
local backend={byKey={['dex:489']='PHIONE',['dex:490']='MANAPHY'},bySpecies={PHIONE='dex:489',MANAPHY='dex:490'}}
local E=dofile('sevii_special_encounters.lua')(S,{backendSpecies=function()return backend end,
 generationRules={peekSpeciesAvailable=function()return true end}});S.specialEncounters=E
local g={champion=true,save={},data={pokemon={PHIONE={},MANAPHY={}}},overworld={map={},player={}}}
local toggles=0;local world={toggleObject=function(_,map,name,show)
 g.save.objectToggles=g.save.objectToggles or{};g.save.objectToggles[map]=g.save.objectToggles[map]or{}
 g.save.objectToggles[map][name]=show;toggles=toggles+1 end}
local T=dofile('sevii_tidal_return.lua')(S,{tr=function(en)return en end,box=function()end,talks={},world=function()return world end,
 npc=function(m,n,s,t,x,y)table.insert(S.maps[m].objects,{name=n,x=x,y=y})end})
local n=0;local function check(v,m)n=n+1;assert(v,m)end
local function at(id)local p=T.sites[id];g.overworld.map.id=p.map;g.overworld.player.cellX=p.x;g.overworld.player.cellY=p.y+1 end
local function denied(reason,f,...)local ok,why=f(...);check(not ok and why==reason,reason..': '..tostring(why))end
local function visible(id)local p=T.sites[id];return g.save.objectToggles[p.map][p.name]end
check(E.rows.PHIONE.dex==489 and E.rows.MANAPHY.dex==490,'canonical two species owners')
T.install(g);check(visible('NERI')and not visible('HOME'),'stranded actor appears only on island')
local before=toggles;T.install(g);check(toggles==before,'idempotent visibility refresh')
at('NERI');denied('briefing-required',T.requestRepair,g)
at('TAMO');g.champion=false;denied('league-required',T.begin,g);g.champion=true
saved.seviiRiftSealed=false;denied('finale-required',T.begin,g);saved.seviiRiftSealed=true
check(T.begin(g),'research briefing');denied('already-briefed',T.begin,g)
at('PLANK');denied('neri-required',T.collect,g)
at('SOUTH');denied('repair-required',T.signal,g,'SOUTH')
at('HOME');denied('return-required',T.checkIn,g)
at('NERI');check(T.requestRepair(g),'find stranded crew');denied('already-requested',T.requestRepair,g)
denied('plank-required',T.repair,g)
at('PLANK');check(T.collect(g),'recover marked plank');saved=copy(saved)
check(T.record().plank and T.record().plankTaken,'cargo persists through serialization');denied('already-collected',T.collect,g)
at('NERI');check(T.repair(g),'repair boat without capture');check(not T.record().plank and T.record().repaired,'plank consumed exactly once')
denied('already-repaired',T.repair,g)
at('PLANK');denied('already-collected',T.collect,g)
at('MIDDLE');denied('wrong-signal',T.signal,g,'MIDDLE');check(T.record().signals==0,'out of order signal preserves progress')
at('NORTH');check(T.signal(g,'NORTH'),'boat departs on first shore signal')
check(not visible('NERI')and not visible('HOME'),'one actor in transit, no shore duplicate')
denied('already-signalled',T.signal,g,'NORTH');saved=copy(saved);T.install(g)
check(T.record().signals==1 and not visible('NERI'),'partial course and departure survive load')
at('SOUTH');denied('wrong-signal',T.signal,g,'SOUTH');check(T.record().signals==1,'skipped middle leaves north confirmed')
at('MIDDLE');check(T.signal(g,'MIDDLE'),'second confirmed passage');denied('unknown-signal',T.signal,g,'FAKE')
at('SOUTH');check(T.signal(g,'SOUTH'),'safe arrival after third signal')
check(T.record().returned and visible('HOME')and not visible('NERI'),'rescue actor moved home once')
denied('already-home',T.signal,g,'SOUTH');saved=copy(saved);T.install(g)
check(visible('HOME')and not visible('NERI'),'completed actor placement survives load')
at('TAMO');denied('check-in-required',T.report,g)
check(not E.rows.PHIONE.ready(g)and not E.rows.MANAPHY.ready(g),'captures wait for personal check-in and report')
at('HOME');check(T.checkIn(g),'actual resident confirms safe return');denied('already-checked-in',T.checkIn,g)
owned.PHIONE=true;owned.MANAPHY=true
at('TAMO');check(T.report(g),'older owners may finish rescue without new specimens')
check(T.record().complete and T.record().title=='SEVII_TIDAL_RETURN','durable rescue recognition')
denied('legend_owned',E.availability,g,'PHIONE');denied('legend_owned',E.availability,g,'MANAPHY')
owned={};check(E.availability(g,'PHIONE')and E.availability(g,'MANAPHY'),'both first encounters available after rescue')
check(S.chapters.journal():find('THE WAY HOME COMPLETE',1,true),'rescue in combined journal')
denied('already-complete',T.report,g)
print('PASS Sevii tidal return: '..n..' checks')
