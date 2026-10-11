local function copy(v)if type(v)~='table'then return v end;local t={};for k,x in pairs(v)do t[k]=copy(x)end;return t end
local saved={expeditionComplete=true,seviiRiftSealed=true};local owned=false
local S={maps={},links={},state=function()return copy(saved)end,persist=function(s)saved=copy(s)end,
 walkable=function()return true end,unlocked=function(g)return g.champion end,assetsReady=function()return true end,
 chapters={journal=function()return'EXPEDITION'end},legendPolicy={history={owned=function()return owned end}}}
function S.location(id,x,y)S.maps[id]=S.maps[id]or{objects={},kaSeviiSource=id};S.links[id]={};return id,x,y end
local backend={byKey={['dex:483']='DIALGA',['dex:484']='PALKIA'},bySpecies={DIALGA='dex:483',PALKIA='dex:484'}}
local E=dofile('sevii_special_encounters.lua')(S,{backendSpecies=function()return backend end,
 generationRules={peekSpeciesAvailable=function()return true end}});S.specialEncounters=E
local g={champion=true,save={},data={pokemon={DIALGA={},PALKIA={}}},overworld={map={},player={}}}
local T=dofile('sevii_time_space.lua')(S,{tr=function(en)return en end,box=function()end,talks={},
 npc=function(m,n,s,t,x,y)table.insert(S.maps[m].objects,{name=n,x=x,y=y})end})
local n=0;local function check(v,m)n=n+1;assert(v,m)end
local function at(id)local p=T.sites[id];g.overworld.map.id=p.map;g.overworld.player.cellX=p.x;g.overworld.player.cellY=p.y+1 end
local function denied(reason,f,...)local ok,why=f(...);check(not ok and why==reason,reason..': '..tostring(why))end
check(E.rows.DIALGA.dex==483 and E.rows.PALKIA.dex==484,'canonical pair')
at('CLOCK');denied('briefing-required',T.align,g,12)
at('LEVIN');g.champion=false;denied('league-required',T.begin,g);g.champion=true
saved.seviiRiftSealed=false;denied('finale-required',T.begin,g);saved.seviiRiftSealed=true
check(T.begin(g),'research begins');denied('already-briefed',T.begin,g)
denied('both-required',T.report,g)
at('CLOCK');denied('readings-required',T.align,g,12)
denied('unknown-pulse',T.read,g,4)
for i=1,3 do at('PULSE_'..i);check(T.read(g,i),'read pulse '..i);denied('already-read',T.read,g,i)end
saved=copy(saved);check(T.record().pulses['1']and T.record().pulses['3'],'copied periods persist')
at('CLOCK');denied('wrong-beat',T.align,g,6);denied('wrong-beat',T.align,g,24)
check(not T.record().timeStable and T.record().pulses['2'],'wrong beat preserves readings')
check(T.align(g,12),'first positive common beat');denied('already-aligned',T.align,g,12)
at('LEVIN');denied('both-required',T.report,g)
at('WEST');denied('survey-required',T.mark,g,'WEST')
at('CENTRE');denied('loop-required',T.closeSurvey,g);check(T.startSurvey(g),'start ordered loop');denied('already-started',T.startSurvey,g)
at('EAST');denied('wrong-marker',T.mark,g,'EAST');check(T.record().point==0 and T.record().surveying,'wrong marker restarts only sequence')
at('WEST');check(T.mark(g,'WEST'),'first real marker');saved=copy(saved);T.install(g)
check(T.record().point==1,'partial progress persists when loading in cave')
S.maps.CAVE_FRAGMENT={kaSeviiSource=T.CAVE};g.overworld.map.id='CAVE_FRAGMENT';T.install(g)
check(T.record().point==1 and T.record().surveying,'runtime seams do not leave physical cave')
at('LEVIN');T.install(g)
check(not T.record().surveying and T.record().point==0 and T.record().interrupted,'leaving cancels unfinished loop')
check(T.record().timeStable,'completed clock survives interrupted spatial task')
at('NORTH');denied('survey-required',T.mark,g,'NORTH')
at('CENTRE');check(T.startSurvey(g),'restart after leaving')
denied('unknown-marker',T.mark,g,'FAKE')
for _,id in ipairs(T.order)do at(id);check(T.mark(g,id),'confirm marker '..id)end
check(not T.record().spaceStable,'four markers still require returning to centre')
at('CENTRE');check(T.closeSurvey(g),'closed physical circuit');denied('already-surveyed',T.closeSurvey,g)
denied('already-surveyed',T.startSurvey,g)
at('WEST');denied('already-surveyed',T.mark,g,'WEST')
at('LEVIN');saved=copy(saved);T.install(g);check(T.record().spaceStable,'completed spatial proof survives departure/reload')
owned=true;check(T.report(g),'old owners may finish without new captures')
check(T.record().complete and T.record().title=='SEVII_TIME_SPACE','durable completion')
denied('legend_owned',E.availability,g,'DIALGA');denied('legend_owned',E.availability,g,'PALKIA')
owned=false;check(E.availability(g,'DIALGA')and E.availability(g,'PALKIA'),'both first encounters enabled')
denied('already-complete',T.report,g);check(S.chapters.journal():find('RHYTHM AND BOUNDARY COMPLETE',1,true),'combined journal')
check(saved.seviiRiftSealed,'research never reopens crossing')
print('PASS Sevii time and space: '..n..' checks')
