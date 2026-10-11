local function copy(v)if type(v)~='table'then return v end;local t={};for k,x in pairs(v)do t[k]=copy(x)end;return t end
local saved={};local enabled=true
local S={maps={},links={},state=function()return copy(saved)end,persist=function(v)saved=copy(v)end,
  walkable=function()return true end,chapters={journal=function()return'EXPEDITION'end}}
function S.location(id,x,y)S.maps[id]=S.maps[id]or{objects={}};S.links[id]=S.links[id]or{};return id,x,y end
local dirs={{8,5},{5,1},{5,8},{5,8},{8,5},{2,5},{5,8},{8,5},{5,1}}
for i,d in ipairs(dirs)do
  local from='FiveIsland_LostCave_Room'..i;S.location(from,5,5)
  S.links[from][1]={x=d[1],y=d[2],map='FiveIsland_LostCave_Room'..(i+1),toX=5,toY=5}
end
local E={rows={},storyReady=function()return enabled,enabled and nil or'finale-required'end}
function E.register(id,row)E.rows[id]=row end
function E.near(g,p)return p and g.map==p.map and math.abs(g.x-p.x)+math.abs(g.y-p.y)==1 end
S.specialEncounters=E
local D=dofile('sevii_dreams.lua')(S,{tr=function(en)return en end,box=function()end,talks={},
  npc=function(m,n,s,t,x,y)table.insert(S.maps[m].objects,{name=n,x=x,y=y})end})
local n=0;local function check(v,m)n=n+1;assert(v,m)end
local g={};local function at(id)local p=D.sites[id];g.map=p.map;g.x=p.x;g.y=p.y+1 end
local function denied(reason,f,...)local ok,why=f(...);check(not ok and why==reason,reason..': '..tostring(why))end
check(E.rows.CRESSELIA.dex==488 and E.rows.DARKRAI.dex==491,'canonical special registrations')
at('JORI');denied('briefing-required',D.wake,g)
at('ILSE');enabled=false;denied('finale-required',D.begin,g);enabled=true
check(D.begin(g),'actual nurse site briefing');denied('already-briefed',D.begin,g)
denied('not-at-site',D.collectFeather,g)
at('JORI');denied('feather-required',D.wake,g)
at('LANTERN');denied('wake-required',D.startTrail,g)
at('DARKRAI');denied('trail-required',D.soothe,g)
at('FEATHER');check(D.collectFeather(g),'unique quest feather');saved=copy(saved)
check(D.record().feather and D.record().featherTaken,'feather reload');denied('already-collected',D.collectFeather,g)
check(not E.rows.CRESSELIA.ready(g),'Cresselia waits for resident to wake')
at('JORI');check(D.wake(g),'resident wakes without capture');denied('already-awake',D.wake,g)
check(E.rows.CRESSELIA.ready(g)and not E.rows.DARKRAI.ready(g),'independent encounter gates')
at('ILSE');denied('quiet-required',D.report,g)
at('LANTERN');check(D.startTrail(g),'trail begins at lantern')
D.onWarp(g,D.route[1],{x=5,y=1,map=D.route[1]})
check(D.record().lostWay and not D.record().trail,'same-room wrong door resets trail')
check(D.startTrail(g),'wrong path retry')
for i=1,4 do D.onWarp(g,D.route[i],D.doors[i]);check(D.record().trail==i+1,'actual authored door '..i)end
saved=copy(saved);check(D.record().trail==5,'partial trail serializes')
D.onWarp(g,'OTHER',D.doors[5]);check(not D.record().trail,'unexpected departure cannot advance')
check(D.startTrail(g),'second retry');enabled=false;D.onWarp(g,D.route[1],D.doors[1]);enabled=true
check(not D.record().trail,'revoked story permission resets trail')
check(D.startTrail(g),'fresh permitted trail')
for i=1,9 do D.onWarp(g,D.route[i],D.doors[i])end
check(D.record().refugeReady and D.record().trail==10,'all nine real links required')
at('LANTERN');denied('already-traced',D.startTrail,g)
check(D.record().refugeReady and D.record().trail==10,'revisiting lantern cannot erase completed route')
at('DARKRAI');check(D.soothe(g),'leave feather in refuge')
check(D.record().quiet and not D.record().feather and not D.record().trail,'single feather dedicated, active trail closed')
denied('already-quiet',D.soothe,g)
at('FEATHER');denied('already-collected',D.collectFeather,g)
at('ILSE');check(D.report(g),'report resolves nightmare without capture')
check(E.rows.DARKRAI.ready(g),'Darkrai encounter follows completed story')
check(D.record().title=='SEVII_MOONLIT_NIGHT','permanent quest recognition')
denied('already-complete',D.report,g)
saved.expeditionComplete=true;check(S.chapters.journal():find('A MOONLIT NIGHT COMPLETE',1,true),'integrated journal')
print('PASS Sevii dreams: '..n..' checks')
