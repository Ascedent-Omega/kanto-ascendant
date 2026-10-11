local function copy(v)if type(v)~='table'then return v end;local t={};for k,x in pairs(v)do t[k]=copy(x)end;return t end
local saved={expeditionComplete=true,seviiRiftSealed=true}
local S={maps={},links={},state=function()return copy(saved)end,persist=function(s)saved=copy(s)end,
  unlocked=function(g)return g.save.flags.champion end,walkable=function()return true end}
function S.location(id,x,y)S.maps[id]=S.maps[id]or{objects={}};S.links[id]={};return id,x,y end
local owned,historyError,art,generation,beyond=false,nil,true,true,true
S.assetsReady=function()return art end
S.legendPolicy={history={owned=function()return owned,historyError end}}
local talks={};local ui={tr=function(en)return en end,box=function()end,talks=talks,
  npc=function(m,n,s,t,x,y)table.insert(S.maps[m].objects,{name=n,x=x,y=y})end}
local opts={backendSpecies=function()return{byKey={['dex:485']='HEATRAN'},bySpecies={HEATRAN='dex:485'}}end,
  beyondKanto={peekIsActive=function()return beyond end},generationRules={peekSpeciesAvailable=function()return generation end}}
local M=dofile('sevii_mysteries.lua')(S,ui,opts)
local g={data={pokemon={HEATRAN={}}},save={flags={champion=true},party={{species='BLASTOISE',hp=1}}}}
local ow={map={},player={}};g.overworld=ow
g.stack={states={ow},top=function(self)return self.states[#self.states]end}
local writes,finished=0,0
g.writeSave=function()writes=writes+1;return true end
ow.pushBattle=function(_,b)table.insert(g.stack.states,b)end
ow.afterBattle=function()finished=finished+1;g.stack.states={ow}end
package.loaded['src.battle.BattleState']={newWild=function(game,species,level,args)
  assert(args.randomizerProtected and args.encounterSource=='sevii-heatran')
  return{game=game,kind='wild',enemy={mon={species=species,level=level}}}
end}
local n=0;local function check(v,msg)n=n+1;assert(v,msg)end
local function at(id)local p=M.sites[id];ow.map.id=p.map;ow.player.cellX=p.x;ow.player.cellY=p.y+1 end
local function denied(reason,f,...)
  local ok,why=f(...);check(not ok and why==reason,reason..': '..tostring(why))
end
check(M.availability(g),'unowned post-expedition encounter available')
g.save.flags.champion=false;denied('league-required',M.availability,g);g.save.flags.champion=true
saved.expeditionComplete=false;denied('finale-required',M.availability,g);saved.expeditionComplete=true
saved.seviiRiftSealed=false;denied('finale-required',M.availability,g);saved.seviiRiftSealed=true
beyond=false;denied('beyond-kanto-sealed',M.availability,g);beyond=true
generation=false;denied('generation-profile',M.availability,g);generation=true
art=false;denied('missing-art',M.availability,g);art=true
historyError='unavailable';denied('legend_history_unavailable',M.availability,g);historyError=nil
owned=true;denied('legend_owned',M.availability,g);owned=false
denied('not-at-researcher',M.begin,g)
at('UPPER');denied('briefing-required',M.read,g,'UPPER')
at('RESEARCHER');check(M.begin(g),'actual site briefing');denied('already-briefed',M.begin,g)
at('VENT');denied('readings-required',M.tune,g,'MIDDLE');denied('vent-closed',M.start,g)
for _,id in ipairs{'UPPER','MIDDLE','LOWER'}do
  at(id);check(M.read(g,id),'reading '..id);check(M.record().readings[id],'persisted reading '..id)
end
at('VENT');denied('wrong-order',M.tune,g,'UPPER');check(M.record().tuned==0,'safe wrong-order reset')
check(M.tune(g,'MIDDLE'),'middle first');saved=copy(saved)
check(M.record().tuned==1,'partial valve sequence persists')
check(M.tune(g,'UPPER')and M.tune(g,'LOWER'),'remaining vent order')
check(M.record().open,'vent open');denied('already-open',M.tune,g,'LOWER')
g.save.party[1].hp=0;denied('no-healthy-party',M.start,g);g.save.party[1].hp=1
local normalWrite=g.writeSave;g.writeSave=function()return false end
denied('save-failed',M.start,g);check(g.stack:top()==ow and not M.record().caught,'failed save starts no battle');g.writeSave=normalWrite
local ok,b=M.start(g);check(ok and b.enemy.mon.level==70 and writes==1,'native constructor after save')
check(M.canCapture(g,b,'HEATRAN'),'exact live battle authorized')
check(not M.canCapture(g,{game=g,kind='wild',enemy=b.enemy},'HEATRAN'),'copied battle has no capability')
check(not M.canCapture(g,b,'MOLTRES'),'species mismatch denied')
denied('not-in-overworld',M.start,g)
generation=false;check(not M.canCapture(g,b,'HEATRAN'),'profile revalidated at capture');generation=true
owned=true;check(not M.canCapture(g,b,'HEATRAN'),'ownership revalidated at capture');owned=false
local map=ow.map.id;ow.map.id='OTHER';check(not M.canCapture(g,b,'HEATRAN'),'map mismatch denied');ow.map.id=map
b.onFinish('run');check(not M.record().caught and not M.canCapture(g,b,'HEATRAN'),'flee retains retry, revokes capability')
b.onFinish('caught');check(finished==1 and not M.record().caught,'duplicate completion ignored')
ok,b=M.start(g);check(ok,'retry after flee');b.onFinish('win');check(not M.record().caught,'KO permits retry')
ok,b=M.start(g);check(ok,'retry after KO')
local stale=b;g.save=copy(g.save);g.stack.states={ow}
check(not M.canCapture(g,stale,'HEATRAN'),'adopted save revokes old authority')
ok,b=M.start(g);check(ok,'new attempt after reload')
stale.onFinish('caught');check(g.stack:top()==b and not M.record().caught,'stale callback cannot finish new battle')
owned=true;b.onFinish('caught');check(M.record().caught,'delivered capture records mystery completion')
check(not M.canCapture(g,b,'HEATRAN'),'finished capture revoked')
denied('legend_owned',M.start,g)
check(M.journal():find('HEATRAN',1,true),'completion visible in journal')
local completed=copy(saved)
saved.mysteries={};owned=true;generation=false;art=false;historyError='unavailable'
at('RESEARCHER');check(M.begin(g),'previous owner can begin pressure research even if capture unavailable')
for _,id in ipairs{'UPPER','MIDDLE','LOWER'}do at(id);check(M.read(g,id),'previous owner reading '..id)end
at('VENT');check(M.tune(g,'MIDDLE')and M.tune(g,'UPPER')and M.tune(g,'LOWER'),'previous owner completes pressure puzzle without capture')
check(M.record().open and not M.record().caught,'research complete without new specimen')
check(M.journal():find('complete without a capture',1,true),'research-only completion explained')
saved=completed;generation=true;art=true;historyError=nil
print('PASS Sevii mysteries: '..n..' checks')
