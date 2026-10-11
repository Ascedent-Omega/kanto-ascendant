local function copy(v)if type(v)~='table'then return v end;local o={};for k,x in pairs(v)do o[k]=copy(x)end;return o end
local callbacks,hooks,storage={},{},{}
local owners={};local historyError,missing;local access=true
local mod={id='kanto_ascendant',save={get=function(_,k)return copy(storage[k])end,set=function(_,k,v)storage[k]=copy(v)end},
 events={on=function(_,id,fn)callbacks[id]=fn end},hooks={wrap=function(_,id,fn)hooks[id]=fn end}}
local R=dofile('hoenn_roamers_67.lua')(mod,{fieldAccess={legendAccess=function()return access end,
 peekLegendAccess=function()return access end},randomInt=function(lo)return lo end,
 legendHistory=function()if missing then return end;return{owned=function(_,id)return owners[id]==true,historyError end}end})
local g={save={party={},boxes={{}},pokedex={owned={}}},data={encounters={ROUTE_1={grass={}},ROUTE_2={grass={}},ROUTE_3={grass={}}}},overworld={map={id='ROUTE_1'}}}
local n=0;local function check(v,msg)n=n+1;assert(v,msg)end
callbacks['game.ready']{game=g}
local s=R.state(false);check(s.roamers.LATIAS.map~=s.roamers.LATIOS.map,'separate initial Kanto routes')
local function at(id)
 local s=R.state(false);g.overworld.map.id=s.roamers[id].map
 return {mapId=g.overworld.map.id},{surface='GRASS'}
end
local rec,surface=at('LATIAS')
check(#R.observations(g,rec.mapId)==1,'existing visible observation before ownership')
access=false;check(not R.proposeVisible(g,rec,surface)and #R.observations(g,rec.mapId)==0,'original Honey/Dex/NG+ authority retained');access=true
local function battle(id)
 local rec,surface=at(id);local enc,proposal=R.proposeVisible(g,rec,surface);assert(enc and proposal)
 local b={game=g,kind='wild',enemy={mon={species=id,level=40,hp=99,stats={hp=99},dvs={special=7}}},encounterSource='wild'}
 R.bindVisible(b,proposal);callbacks['battle.started']{battle=b};return b
end
local first=battle('LATIAS');check(first.kaHoennRoamer=='LATIAS','original encounter owner binds unowned identity')
first.enemy.mon.hp=23;first.enemy.mon.status='PAR';callbacks['battle.ended']{battle=first,result='run'}
s=R.state(false);check(s.roamers.LATIAS.hp==23 and s.roamers.LATIAS.status=='PAR'and s.roamers.LATIAS.dvs.special==7,'original wounded identity retained')
local again=battle('LATIAS');check(again.enemy.mon.hp==23 and again.enemy.mon.status=='PAR'and again.enemy.mon.dvs.special==7,'second encounter restores same identity')
callbacks['battle.ended']{battle=again,result='run'}
rec,surface=at('LATIAS');historyError='bank-offline'
check(not R.proposeVisible(g,rec,surface)and #R.observations(g,rec.mapId)==0,'unreadable history hides new proposals and observations')
check(R.state(false).roamers.LATIAS.hp==23,'history outage preserves unowned wounded identity')
callbacks['map.entered']{mapId='ROUTE_3'}
check(R.state(false).roamers.LATIAS.map==rec.mapId,'history outage does not relocate preserved identity')
historyError=nil;missing=true;check(not R.proposeVisible(g,rec,surface),'missing bound history fails closed');missing=false
local _,queued=R.proposeVisible(g,rec,surface);owners.LATIAS=true
local stale={game=g,kind='wild',enemy={mon={species='LATIAS',level=40,hp=99,stats={hp=99},dvs={}}}}
R.bindVisible(stale,queued);callbacks['battle.started']{battle=stale}
check(not stale.kaHoennRoamer,'ownership gained after proposal blocks roamer admission')
check(R.initialize(g),'existing initialization remains usable')
s=R.state(false);check(s.caught.LATIAS.adopted and not s.roamers.LATIAS,'lineage-owned species removed from roaming only')
check(s.roamers.LATIOS~=nil,'other unowned Eon remains possible')
local second=battle('LATIOS');table.insert(g.save.boxes[1],second.enemy.mon)
callbacks['pokemon.caught']{game=g,battle=second,mon=second.enemy.mon}
check(second.kaHoennRoamerStored and R.state(false).caught.LATIOS.level==40,'actual stored first catch remains recorded')
callbacks['battle.ended']{battle=second,result='caught'}
check(not R.state(false).roamers.LATIOS,'caught identity never respawns')
-- A battle may not finish into a newly adopted save or manufacture its capture.
storage={};owners={};callbacks['save.loaded']{game=g}
local late=battle('LATIOS');local prior=g.save;g.save={party={},boxes={{}},pokedex={owned={}}}
local before=R.state(false).roamers.LATIOS.map
callbacks['pokemon.caught']{game=g,battle=late,mon=late.enemy.mon}
callbacks['battle.ended']{battle=late,result='win'}
check(not R.state(false).caught.LATIOS and R.state(false).roamers.LATIOS.map==before and R.state(false).roamers.LATIOS.recovery==0,'old battle cannot alter adopted save')
g.save=prior
check(not R.markCaught(g,'LATIOS',{species='LATIOS'},'ROUTE_1'),'non-stored object cannot fabricate catch receipt')
storage={};owners={};callbacks['save.loaded']{game=g}
rec,surface=at('LATIAS');local hits=0
for roll=1,20 do
 local enc=hooks['encounter.roll'](function()return nil end,{},
  {terrain='grass',mapId=rec.mapId,rng=function(lo,hi)assert(lo==1 and hi==20);return roll end})
 if enc then hits=hits+1 end
end
check(hits==1,'exact 5 percent Kanto chance without a second ordinary-encounter prerequisite')
local before=R.state(false).roamers.LATIAS.map
check(before==rec.mapId,'unsuccessful rolls do not reroll the current location')
local open=true
local V={DENOMINATOR=20,area=function(id)return id=='ISLAND_A'or id=='ISLAND_B'and true or nil end,
 routes=function()return open and{'ISLAND_A','ROUTE_1'}or{}end,
 accepts=function(_,id)return open and(id=='ISLAND_A'or id=='ISLAND_B')end,readyFor=function()return true end}
R.setExpansion(V)
check(#R.routePool(g)==4,'original routes plus island area; overlapping Kanto entry never gets double weight')
local row=R.state(false);row.roamers.LATIAS.map='ROUTE_1';R.persist(row);g.overworld.map.id='ISLAND_B'
check(not R.rollExpansion(g,'ISLAND_B',function()error('no roll while both roamers are elsewhere')end),'wrong area never offers a roamer')
check(#R.observations(g,'ISLAND_B')==0,'no visible observation in the wrong area')
row.roamers.LATIAS.map='ISLAND_A';R.persist(row)
local enc=R.rollExpansion(g,'ISLAND_B',function(lo,hi)check(hi==20 or hi==2,'one probability roll followed by identity selection');return 1 end)
check(enc and R.acceptsExpansionEncounter(g,enc,{mapId='ISLAND_B'}),'same roamer admitted only in its current area, including map fragments')
check(not R.acceptsExpansionEncounter(g,copy(enc),{mapId='ISLAND_B'}),'copied or fabricated encounter is not a live proposal')
local b={game=g,kind='wild',enemy={mon={species='LATIAS',level=40,hp=99,stats={hp=99},dvs={special=4}}}}
callbacks['battle.started']{battle=b};g.stack={states={b}}
check(R.canCaptureExpansion(g,b,'LATIAS'),'live original owner authorized on island')
check(not R.canCaptureExpansion(g,{game=g,kind='wild',enemy=b.enemy,kaHoennRoamer='LATIAS',kaHoennRoamerMap='ISLAND_B'},'LATIAS'),'serialized battle fields do not grant permission')
open=false;check(not R.canCaptureExpansion(g,b,'LATIAS'),'story gate rechecked during capture');open=true
callbacks['battle.ended']{battle=b,result='run'}
check(not R.canCaptureExpansion(g,b,'LATIAS'),'completed battle permission expires')
row=R.state(false);row.roamers.LATIAS.map='ISLAND_A';row.roamers.LATIOS.map='ISLAND_A';R.persist(row)
local hits=0
for roll=1,20 do
 local probabilityCalls=0
 local e=R.rollExpansion(g,'ISLAND_A',function(lo,hi)
  if hi==20 then probabilityCalls=probabilityCalls+1;return roll end
  assert(hi==2);return 2
 end)
 if e then hits=hits+1;check(e.species=='LATIOS','either identity can be selected')end
 check(probabilityCalls==1,'one local probability draw with two roamers sharing this area')
end
check(hits==1,'two local roamers still yield exactly 5 percent total')
row=R.state(false);row.roamers.LATIAS.map='ROUTE_1';row.roamers.LATIOS.map='ROUTE_2';R.persist(row)
check(not R.rollExpansion(g,'ISLAND_A',function()error('wrong map must never consume a probability roll')end),'moving elsewhere removes the local encounter opportunity')
row=R.state(false);row.roamers.LATIAS.map='ISLAND_A';row.roamers.LATIAS.hp=17;row.roamers.LATIAS.status='PAR';row.roamers.LATIAS.dvs={special=9};R.persist(row)
open=false;R.initialize(g);row=R.state(false).roamers.LATIAS
check(row.map~='ISLAND_A'and row.map~='ISLAND_B','closing an area relocates to a still accessible destination')
check(row.hp==17 and row.status=='PAR'and row.dvs.special==9,'gate changes never recreate or heal the same identity')
print('PASS Sevii Eon continuity: '..n..' checks')
