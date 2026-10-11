local function copy(v)if type(v)~='table'then return v end;local t={};for k,x in pairs(v)do t[k]=copy(x)end;return t end
local saved={expeditionComplete=true,seviiRiftSealed=true};local wins=0
local S={maps={},links={},state=function()return copy(saved)end,persist=function(s)saved=copy(s)end,
  unlocked=function(g)return g.save.flags.champion end,walkable=function()return true end,
  chapters={journal=function()return'EXPEDITION'end},tower={progress=function()return wins end}}
function S.location(id,x,y)S.maps[id]=S.maps[id]or{objects={}};S.links[id]={};return id,x,y end
local owned,historyError,art,generation,beyond={},nil,true,true,true
S.assetsReady=function()return art end
S.legendPolicy={history={owned=function(g,id)return owned[id]==true,historyError end}}
local backend={byKey={['dex:480']='UXIE',['dex:481']='MESPRIT',['dex:482']='AZELF'},
  bySpecies={UXIE='dex:480',MESPRIT='dex:481',AZELF='dex:482'}}
local opts={backendSpecies=function()return backend end,beyondKanto={peekIsActive=function()return beyond end},
  generationRules={peekSpeciesAvailable=function()return generation end}}
local E=dofile('sevii_special_encounters.lua')(S,opts);S.specialEncounters=E
local talks={};local ui={tr=function(en)return en end,box=function()end,talks=talks,
  npc=function(m,n,s,t,x,y)table.insert(S.maps[m].objects,{name=n,x=x,y=y})end}
local G=dofile('sevii_lake_guardians.lua')(S,ui)
local g={data={pokemon={UXIE={},MESPRIT={},AZELF={}}},save={flags={champion=true},party={{species='BLASTOISE',hp=1}}}}
local ow={map={},player={}};g.overworld=ow
g.stack={states={ow},top=function(self)return self.states[#self.states]end}
local writes,finished=0,0;g.writeSave=function()writes=writes+1;return true end
ow.pushBattle=function(_,b)table.insert(g.stack.states,b)end
ow.afterBattle=function()finished=finished+1;g.stack.states={ow}end
package.loaded['src.battle.BattleState']={newWild=function(game,id,level,args)
  assert(args.randomizerProtected and args.encounterSource=='sevii-special-'..id)
  return{game=game,kind='wild',enemy={mon={species=id,level=level}}}
end}
local n=0;local function check(v,msg)n=n+1;assert(v,msg)end
local function at(id)local p=G.sites[id];ow.map.id=p.map;ow.player.cellX=p.x;ow.player.cellY=p.y+1 end
local function denied(reason,f,...)local ok,why=f(...);check(not ok and why==reason,reason..': '..tostring(why))end
check(not pcall(E.register,'GIRATINA',{dex=487}),'Giratina never registerable')
check(not pcall(E.register,'UXIE',E.rows.UXIE),'duplicate source rejected')
at('ARCHIVIST');g.save.flags.champion=false;denied('league-required',G.begin,g);g.save.flags.champion=true
saved.expeditionComplete=false;denied('finale-required',G.begin,g);saved.expeditionComplete=true
beyond=false;denied('beyond-kanto-sealed',G.begin,g);beyond=true
at('UXIE');denied('briefing-required',G.answer,g,'CURRENT')
at('ARCHIVIST');check(G.begin(g),'archive briefing');denied('already-briefed',G.begin,g)
at('UXIE');denied('trial-required',E.start,g,'UXIE')
denied('wrong-answer',G.answer,g,'BIRD');check(G.record().answers==0,'incorrect lore safely resets')
check(G.answer(g,'CURRENT'),'first remembered fact');saved=copy(saved);check(G.record().answers==1,'partial recall serialized')
check(G.answer(g,'GIRATINA')and G.answer(g,'CROSSING'),'correct source and local ending')
check(G.record().knowledge,'knowledge task complete');denied('already-complete',G.answer,g,'CROSSING')
at('KEEPSAKE');denied('mila-required',G.collect,g)
at('MILA');check(G.request(g),'listen to Mila');denied('keepsake-required',G.returnKeepsake,g)
at('KEEPSAKE');check(G.collect(g),'physically retrieve unique keepsake');saved=copy(saved)
check(G.record().keepsake,'keepsake reload');denied('already-collected',G.collect,g)
at('MILA');check(G.returnKeepsake(g),'return keepsake');check(G.record().compassion and not G.record().keepsake,'hand-off consumed quest token')
at('KEEPSAKE');denied('already-collected',G.collect,g)
at('AZELF');denied('tower-required',G.proveResolve,g);wins=8;denied('tower-required',G.proveResolve,g)
saved.towerComplete=true;check(G.proveResolve(g),'tower wins plus ceremony earn resolve')
at('ARCHIVIST');check(G.report(g)and G.record().complete,'research completes without captures')
check(S.chapters.journal():find('THREE VOICES COMPLETE',1,true),'research title in integrated journal')
at('UXIE');check(E.availability(g,'UXIE'),'unowned unlocked encounter available')
generation=false;denied('generation-profile',E.start,g,'UXIE');generation=true
art=false;denied('missing-art',E.start,g,'UXIE');art=true
historyError='offline';denied('legend_history_unavailable',E.start,g,'UXIE');historyError=nil
owned.UXIE=true;denied('legend_owned',E.start,g,'UXIE');owned.UXIE=nil
local write=g.writeSave;g.writeSave=function()return false end;denied('save-failed',E.start,g,'UXIE');g.writeSave=write
g.save.party[1].hp=0;denied('no-healthy-party',E.start,g,'UXIE');g.save.party[1].hp=1
g.save.party[1].isEgg=true;denied('no-healthy-party',E.start,g,'UXIE');g.save.party[1].isEgg=nil
local ok,b=E.start(g,'UXIE');check(ok and writes==1 and b.enemy.mon.level==65,'real battle factory after saving')
check(E.canCapture(g,b,'UXIE'),'exact battle capability')
check(not E.canCapture(g,{game=g,kind='wild',enemy=b.enemy},'UXIE'),'copied battle cannot forge authority')
check(not E.canCapture(g,b,'AZELF'),'species mismatch denied')
denied('not-in-overworld',E.start,g,'UXIE')
owned.UXIE=true;check(not E.canCapture(g,b,'UXIE'),'new ownership checked at capture');owned.UXIE=nil
local map=ow.map.id;ow.map.id='OTHER';check(not E.canCapture(g,b,'UXIE'),'map mismatch denied');ow.map.id=map
b.onFinish('run');check(not(saved.specialCaptures and saved.specialCaptures.UXIE),'flee creates no capture receipt')
b.onFinish('caught');check(finished==1,'duplicate callback ignored')
ok,b=E.start(g,'UXIE');check(ok,'retry after flee');b.onFinish('win');check(not(saved.specialCaptures and saved.specialCaptures.UXIE),'KO creates no capture receipt')
ok,b=E.start(g,'UXIE');local old=b;g.save=copy(g.save);g.stack.states={ow}
check(not E.canCapture(g,old,'UXIE'),'adopting save revokes old authority')
ok,b=E.start(g,'UXIE');check(ok,'retry after abandoned battle reload');old.onFinish('caught')
check(g.stack:top()==b,'old callback cannot end new battle')
owned.UXIE=true;b.onFinish('caught');check(saved.specialCaptures.UXIE,'delivered catch recorded')
denied('legend_owned',E.start,g,'UXIE')
for _,id in ipairs{'MESPRIT','AZELF'}do
  at(id);check(E.availability(g,id),'other guardian independent '..id)
  local yes,battle=E.start(g,id);check(yes and E.canCapture(g,battle,id),'separate authority '..id)
  owned[id]=true;battle.onFinish('caught');check(saved.specialCaptures[id],'own receipt '..id)
end
check(G.record().complete,'capture/history never erases research completion')
print('PASS Sevii lake guardians: '..n..' checks')
