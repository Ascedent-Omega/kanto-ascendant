local function copy(v)if type(v)~='table'then return v end;local t={};for k,x in pairs(v)do t[k]=copy(x)end;return t end
local saved={expeditionComplete=true,seviiRiftSealed=true};local owned=false
local S={maps={},links={},state=function()return copy(saved)end,persist=function(s)saved=copy(s)end,
 walkable=function()return true end,unlocked=function(g)return g.champion end,assetsReady=function()return true end,
 chapters={journal=function()return'EXPEDITION'end},legendPolicy={history={owned=function()return owned end}}}
function S.location(id,x,y)S.maps[id]=S.maps[id]or{objects={}};S.links[id]={};return id,x,y end
local backend={byKey={['dex:492']='SHAYMIN'},bySpecies={SHAYMIN='dex:492'}}
local E=dofile('sevii_special_encounters.lua')(S,{backendSpecies=function()return backend end,
 generationRules={peekSpeciesAvailable=function()return true end}});S.specialEncounters=E
local g={champion=true,save={},data={pokemon={SHAYMIN={}}},overworld={map={},player={}}}
local toggles=0;local world={toggleObject=function(_,map,name,show)
 g.save.objectToggles=g.save.objectToggles or{};g.save.objectToggles[map]=g.save.objectToggles[map]or{}
 g.save.objectToggles[map][name]=show;toggles=toggles+1 end}
local G=dofile('sevii_garden.lua')(S,{tr=function(en)return en end,box=function()end,talks={},world=function()return world end,
 npc=function(m,n,s,t,x,y)table.insert(S.maps[m].objects,{name=n,x=x,y=y})end})
local n=0;local function check(v,m)n=n+1;assert(v,m)end
local function at(id)local p=G.sites[id];g.overworld.map.id=p.map;g.overworld.player.cellX=p.x;g.overworld.player.cellY=p.y+1 end
local function denied(reason,f,...)local ok,why=f(...);check(not ok and why==reason,reason..': '..tostring(why))end
local function debris()local p=G.sites.SILT;return g.save.objectToggles[p.map][p.name]end
check(E.rows.SHAYMIN.dex==492 and E.rows.SHAYMIN.level==65,'canonical owner and level')
G.install(g);check(debris(),'debris initially present');local old=toggles;G.install(g);check(old==toggles,'idempotent visibility')
at('BED');denied('briefing-required',G.inspect,g)
at('ODA');g.champion=false;denied('league-required',G.begin,g);g.champion=true
saved.seviiRiftSealed=false;denied('finale-required',G.begin,g);saved.seviiRiftSealed=true
check(G.begin(g)and G.record().seeds,'briefing gives saved seeds once');denied('already-briefed',G.begin,g)
at('SILT');denied('inspection-required',G.clear,g)
at('GATE');denied('clearance-required',G.release,g,'slow')
at('RIKA');denied('planting-required',G.thank,g,'everyone')
at('BED');denied('water-required',G.sow,g);check(G.inspect(g),'inspect dry bed');denied('already-inspected',G.inspect,g)
at('SILT');check(G.clear(g)and not debris(),'clear actual debris');denied('already-cleared',G.clear,g)
saved=copy(saved);G.install(g);check(G.record().cleared and not debris(),'clearance and visibility persist')
at('GATE');denied('too-fast',G.release,g,'fast');check(not G.record().watered and G.record().seeds,'mistake costs no seeds/progress')
check(G.release(g,'slow'),'slow release');denied('already-watered',G.release,g,'slow')
saved=copy(saved);check(G.record().watered,'water progress survives load')
at('BED');check(G.sow(g),'plant saved seeds');check(G.record().sown and not G.record().seeds,'seeds consumed once')
denied('already-sown',G.sow,g)
at('ODA');denied('gratitude-required',G.report,g)
at('RIKA');denied('unknown-choice',G.thank,g,'wrong')
local before=copy(saved)
for _,choice in ipairs{'neighbors','pokemon','everyone'}do
 saved=copy(before);check(G.thank(g,choice)and G.record().thanks==choice,'every gratitude choice valid '..choice)
 check(G.sign()~=''and G.journal():find(G.sign(),1,true),'saved sign visible '..choice)
 denied('already-thanked',G.thank,g,choice)
end
owned=true;at('ODA');check(G.report(g),'earlier owners can finish restoration')
check(G.record().complete and G.record().title=='SEVII_FOREST_GARDEN','durable title');denied('legend_owned',E.availability,g,'SHAYMIN')
owned=false;check(E.availability(g,'SHAYMIN'),'first encounter available after report')
denied('already-complete',G.report,g);check(S.chapters.journal():find('WHAT GROWS AGAIN COMPLETE',1,true),'journal integrated')
at('BED');denied('not-at-site',G.report,g)
print('PASS Sevii garden: '..n..' checks')
