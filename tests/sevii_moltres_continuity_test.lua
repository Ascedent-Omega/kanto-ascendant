local panel
package.preload['src.render.TextBox']=function()return{new=function(game,text,done,opts)
 return{text=text,done=done,opts=opts}
end}end
local saves={}
local mod={id='kanto_ascendant',save={get=function(_,key)return saves[key]end,set=function(_,key,v)saves[key]=v end}}
local E=dofile('hoenn_endgame_run_events_67.lua')(mod)
local owned,historyError,archiveAvailable,active,writeOk=false,nil,true,true,true
local battles=0
local V=dofile('hoenn_moltres_volcano_67.lua')(mod,{geometry={},runEvents=E,
 postgame={hasHallOfFame=function()return active end,legendSetting=function()return'apex'end},
 legendHistory=function()if archiveAvailable then return{owned=function()return owned,historyError end}end end,
 battleState={newWild=function()battles=battles+1;return{enemy={mon={species='MOLTRES'}}}end}})
local g={save={party={},boxes={}},stack={push=function(_,p)panel=p end},writeSave=function()return writeOk end}
local ow={pushBattle=function()end}
local n=0;local function check(v,msg)n=n+1;assert(v,msg)end
local function solved()
 E.setProgress(g,'MOLTRES',{puzzleVersion=4,heatProtection=true,baseRubies={true,true,true},
  ascentRubies={true,true,true},baseDrilled=true,lowerPlugCleared=true,guardianDefeated=true,
  currentSolved=true,upperPlugCleared=true,summitUnlocked=true})
end
owned=true;check(not V.recordWitness(g),'ownership does not skip volcano puzzle')
V.challenge(g,ow);check(not panel.opts and battles==0,'locked crater has no ceremony')
solved();active=false;check(not V.recordWitness(g),'pre-league ceremony refused');active=true
owned=false;check(not V.recordWitness(g),'unowned cannot fabricate completion')
V.challenge(g,ow);panel.done();check(battles==1,'first unowned encounter remains live')
owned=true;V.syncVisibility(g)
local t=g.save.objectToggles[V.MAP]
check(t.KA_MOLTRES_VOLCANO==false and t.KA_MOLTRES_MEMORY==true,'old owner sees feather instead of duplicate bird')
V.challenge(g,ow);check(panel.opts.defaultNo==true,'witness is voluntary')
panel.opts.choice(false);check(not E.completed(g,'MOLTRES'),'declining keeps route open')
writeOk=false;local ok,why=V.recordWitness(g)
check(not ok and why=='save'and not E.completed(g,'MOLTRES'),'failed save rolls back route receipt')
writeOk=true;V.challenge(g,ow);panel.opts.choice(true)
local receipt=E.state(g).completed.MOLTRES
check(receipt and receipt.captured==false and receipt.battleResult=='witnessed','route completes without forged catch')
check(battles==1 and not saves[V.SAVE_KEY],'witness never starts another fight or writes historical caught data')
check(not V.recordWitness(g),'ceremony idempotent')
check(g.save.objectToggles[V.MAP].KA_MOLTRES_MEMORY==false,'completed feather hidden')
E.mark(g,'REGIROCK',{captured=false,battleResult='win'})
check(E.deoxysReady(g),'witnessed volcano preserves Birth Island route prerequisite')
E.reset(g);check(not E.completed(g,'MOLTRES')and owned,'NG+ resets puzzle, not external ownership')
solved();owned=false;historyError='bank_history_unavailable';V.challenge(g,ow)
check(not panel.done and not panel.opts and battles==1,'unknown ownership fails closed before fight')
V.syncVisibility(g);check(g.save.objectToggles[V.MAP].KA_MOLTRES_MEMORY==true,'unavailable archive has interactable explanation')
historyError=nil;V.challenge(g,ow);local stale=panel.done;owned=true;stale()
check(panel.opts and battles==1,'ownership rechecked after intro text')
local oldSave=g.save;g.save={};panel.opts.choice(true);g.save=oldSave
check(not E.completed(g,'MOLTRES'),'late ceremony cannot modify a different adopted save')
owned=false;archiveAvailable=false;V.challenge(g,ow)
check(not panel.opts and battles==1,'missing configured history owner fails closed')
print('PASS Sevii Moltres continuity: '..n..' checks')
