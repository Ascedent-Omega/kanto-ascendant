local panel
package.preload['src.render.TextBox']=function()return{new=function(game,text,done,opts)return{text=text,done=done,opts=opts}end}end
local saves={};local mod={id='kanto_ascendant',save={get=function(_,key)return saves[key]end,set=function(_,key,v)saves[key]=v end}}
local E=dofile('hoenn_endgame_run_events_67.lua')(mod)
local owned,historyError,active,writeOk=false,nil,true,true
local battles=0
local S=dofile('hoenn_research_sanctums_67.lua')(mod,{geometry={},runEvents=E,dex={record=function()end},
 postgame={hasHallOfFame=function()return active end},
 legendHistory=function()return{owned=function()return owned,historyError end}end,
 battleState={newWild=function()battles=battles+1;return{enemy={mon={}}}end}})
local g={save={party={},boxes={}},stack={push=function(_,p)panel=p end},writeSave=function()return writeOk end}
local enteredToggles
mod.world={warpTo=function(_,map)enteredToggles=g.save.objectToggles[map];return true end}
local ow={pushBattle=function()end}
local n=0;local function check(v,msg)n=n+1;assert(v,msg)end
for index,row in ipairs(S.rows)do
 owned=true
 check(not S.recordWitness(g,row),'old owner still needs physical puzzle '..row.species)
 active=false;S.syncPuzzleVisibility(g,row);active=true
 check(S.enter(g,row,row.fallbackReturn),'entry after acquiring access '..row.species)
 check(enteredToggles[row.object..'_MEMORY']==true and enteredToggles[row.gateNames[1]]==true,'current memory and closed seal precede destination spawn')
 if row.puzzle.kind=='route'then check(enteredToggles[row.object..'_TECHNIQUE']==true,'technique stone restored before first map build')end
 E.setProgress(g,'REGI_PUZZLE_'..row.species,{solved=true})
 active=false;check(not S.recordWitness(g,row),'league gate '..row.species);active=true
 owned=false;check(not S.recordWitness(g,row),'unowned cannot fabricate seal '..row.species)
 S.challenge(g,ow,nil,nil,row);panel.done();check(battles==index,'first unowned battle remains possible')
 owned=true;S.syncPuzzleVisibility(g,row)
 local t=g.save.objectToggles[row.map]
 check(t[row.object]==false and t[row.object..'_MEMORY']==true,'memory replaces second guardian')
 S.challenge(g,ow,nil,nil,row);panel.opts.choice(false);check(not E.completed(g,row.species),'decline preserves puzzle')
 writeOk=false;local ok,why=S.recordWitness(g,row)
 check(not ok and why=='save'and not E.completed(g,row.species),'failed write retryable')
 writeOk=true;S.challenge(g,ow,nil,nil,row);panel.opts.choice(true)
 local receipt=E.state(g).completed[row.species]
 check(receipt.captured==false and receipt.battleResult=='witnessed','research receipt not forged catch')
 check(not saves[S.SAVE_KEY],'no synthetic caught or Dex record')
 check(not S.recordWitness(g,row),'idempotent ceremony')
 check(g.save.objectToggles[row.map][row.object..'_MEMORY']==false,'finished memory hidden')
 E.state(g).completed[row.species]=nil;owned=false;historyError='offline';S.challenge(g,ow,nil,nil,row)
 check(not panel.done and not panel.opts,'unreadable archive cannot open battle')
 historyError=nil;S.challenge(g,ow,nil,nil,row);local callback=panel.done;owned=true;callback()
 check(panel.opts,'ownership rechecked before deferred battle')
 local old=g.save;g.save={};panel.opts.choice(true);g.save=old
 check(not E.completed(g,row.species),'stale callback does not complete another save')
 assert(S.recordWitness(g,row))
end
E.mark(g,'MOLTRES',{captured=false,battleResult='witnessed'})
check(E.deoxysReady(g),'Regirock witness retains Birth Island prerequisite')
check(not S.recordWitness(g,{species='REGIROCK'}),'foreign row refused')
print('PASS Sevii Regi continuity: '..n..' checks')
