local function copy(v)if type(v)~='table'then return v end;local t={};for k,x in pairs(v)do t[k]=copy(x)end;return t end
local saved={expeditionComplete=true,seviiRiftSealed=true};local owned=false;local epoch=4
local S={maps={},links={},state=function()return copy(saved)end,persist=function(s)saved=copy(s)end,
 walkable=function()return true end,unlocked=function(g)return g.champion end,assetsReady=function()return true end,
 chapters={journal=function()return'EXPEDITION'end},legendPolicy={history={owned=function()return owned end}}}
function S.location(id,x,y)S.maps[id]=S.maps[id]or{objects={}};S.links[id]={};return id,x,y end
local backend={byKey={['dex:486']='REGIGIGAS'},bySpecies={REGIGIGAS='dex:486'}}
local E=dofile('sevii_special_encounters.lua')(S,{backendSpecies=function()return backend end,
 generationRules={peekSpeciesAvailable=function(_,id)return epoch>=(id=='REGIGIGAS'and 4 or 3)end}});S.specialEncounters=E
local oldDex=false
local oldMod={id='kanto_ascendant'}
local events=dofile('hoenn_endgame_run_events_67.lua')(oldMod)
local sanctums=dofile('hoenn_research_sanctums_67.lua')(oldMod,{geometry={},dex={},runEvents=events,
 fieldAccess={hasDex=function()return oldDex end},postgame={hasHallOfFame=function(save)return save.champion end},
 generationRules={shouldUseEpoch=function()return epoch>=3 end}})
local ui={sanctums=sanctums,tr=function(en)return en end,box=function()end,talks={},
 npc=function(m,n,s,t,x,y)table.insert(S.maps[m].objects,{name=n,x=x,y=y})end}
local G=dofile('sevii_sleeping_giant.lua')(S,ui)
local g={champion=true,save={champion=true},mods={modOptions={kanto_ascendant={hoenn_regi_sanctums=true}}},data={pokemon={REGIGIGAS={}}},overworld={map={},player={}}}
for id,dex in pairs{REGIROCK=377,REGICE=378,REGISTEEL=379}do
 backend.byKey['dex:'..dex]=id;backend.bySpecies[id]='dex:'..dex;g.data.pokemon[id]={}
end
local n=0;local function check(v,m)n=n+1;assert(v,m)end
local function at(id)local p=G.sites[id];g.overworld.map.id=p.map;g.overworld.player.cellX=p.x;g.overworld.player.cellY=p.y+1 end
local function denied(reason,f,...)local ok,why=f(...);check(not ok and why==reason,reason..': '..tostring(why))end
check(E.rows.REGIGIGAS.dex==486 and E.rows.REGIGIGAS.level==75,'canonical existing Regigigas owner')
for id,site in pairs(G.guardians)do
 check(E.rows[id].site==G.sites[site]and E.rows[id].level==65,'guardian uses existing Tanoby inscription '..id)
 denied('trial-required',E.availability,g,id)
end
at('BALANCE');denied('briefing-required',G.balance,g)
at('RHEA');g.champion=false;denied('league-required',G.begin,g);g.champion=true
saved.expeditionComplete=false;denied('finale-required',G.begin,g);saved.expeditionComplete=true
check(G.begin(g),'researcher begins quest');denied('already-briefed',G.begin,g)
denied('not-at-site',G.move,g,1,2);denied('balance-required',G.report,g)
at('BALANCE');denied('inscriptions-required',G.balance,g)
check(G.move(g,2,1)and G.move(g,3,1),'weights adjustable before full research')
denied('inscriptions-required',G.balance,g)
check(G.reset(g),'reset reversible arrangement')
for _,id in ipairs{'ROCK','ICE','STEEL'}do at(id);check(G.read(g,id),'read physical inscription '..id)end
denied('already-read',G.read,g,'STEEL');denied('unknown-inscription',G.read,g,'FAKE')
at('BALANCE');denied('unbalanced',G.balance,g)
check(G.weights()[1]==4 and G.weights()[2]==4 and G.weights()[3]==2,'failed check retains weights')
denied('invalid-transfer',G.move,g,1,1);denied('invalid-transfer',G.move,g,1,4)
for _=1,4 do assert(G.move(g,1,2))end
denied('empty-tray',G.move,g,1,3)
check(G.weights()[1]==0 and G.weights()[2]==8 and G.weights()[3]==2,'nonnegative conserved total')
check(G.reset(g)and G.record().clues.ROCK and G.record().clues.ICE,'reset preserves copied inscriptions')
check(G.move(g,2,1),'first correct transfer');saved=copy(saved)
check(G.weights()[1]==5 and G.weights()[2]==3 and G.weights()[3]==2,'partial weights survive serialized state')
check(not E.availability(g,'REGIGIGAS'),'partial mechanism grants no encounter')
-- Corrupt arrangement can be repaired locally, but never accidentally solves.
saved.mysteries.sleepingGiant.weights={6,3,2}
denied('reset-required',G.balance,g);denied('reset-required',G.move,g,1,2)
check(G.reset(g),'invalid arrangement repaired with in-world reset')
check(G.move(g,2,1)and G.move(g,3,1)and G.balance(g),'unique integer balance 6 / 3 / 1')
denied('already-balanced',G.reset,g);denied('already-balanced',G.move,g,1,2)
check(not E.availability(g,'REGIGIGAS'),'research report still required')
owned=true;at('RHEA');check(G.report(g),'older legend owner can finish research without duplicate')
check(G.record().complete and G.record().title=='SEVII_SLEEPING_GIANT','persistent non-capture title')
denied('already-complete',G.report,g)
denied('legend_owned',E.availability,g,'REGIGIGAS')
owned=false;check(E.availability(g,'REGIGIGAS'),'first encounter available only after actual research completion')
check(S.chapters.journal():find('THE SLEEPING GIANT COMPLETE',1,true),'complete discovery in combined journal')
for id in pairs(G.guardians)do
 denied('sanctuary-access-required',E.availability,g,id)
end
oldDex=true
for id in pairs(G.guardians)do
 check(E.availability(g,id),'Tanoby balance and Hoenn research open guardian '..id)
 owned=true;denied('legend_owned',E.availability,g,id);owned=false
end
g.mods.modOptions.kanto_ascendant.hoenn_regi_sanctums=false
denied('sanctuary-access-required',E.availability,g,'REGIROCK')
g.mods.modOptions.kanto_ascendant.hoenn_regi_sanctums=true
g.save.champion=false;denied('sanctuary-access-required',E.availability,g,'REGIROCK');g.save.champion=true
ui.sanctums=nil;denied('sanctuary-unavailable',E.availability,g,'REGIROCK');ui.sanctums=sanctums
epoch=3
for id in pairs(G.guardians)do check(E.availability(g,id),'Gen3 supports guardian '..id)end
denied('generation-profile',E.availability,g,'REGIGIGAS')
epoch=2
for id in pairs(G.guardians)do denied('generation-profile',E.availability,g,id)end
epoch=4
check(G.journal():find('former sanctuaries are closed',1,true),'journal explains new guardian locations')
events.reset(g)
for id in pairs(G.guardians)do check(E.availability(g,id),'old sanctuary progress no longer controls Tanoby guardians')end
check(E.availability(g,'REGIGIGAS'),'Regigigas still uses its own completed research')
check(not E.rows.GROUDON and not E.rows.KYOGRE and not E.rows.RAYQUAZA,'character portal legends have no Sevii capture owner')
saved.seviiRiftSealed=false;denied('finale-required',E.availability,g,'REGIGIGAS')
print('PASS Sevii sleeping giant: '..n..' checks')
