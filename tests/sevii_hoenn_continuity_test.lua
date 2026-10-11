local panel,storage,battles=nil,{},0
package.preload['src.render.TextBox']=function()return{new=function(_,text,done,opts)return{text=text,done=done,opts=opts}end}end
local mod={id='kanto_ascendant',save={get=function(_,k)return storage[k]end,set=function(_,k,v)storage[k]=v;return true end}}
local active,writeOk,historyError=true,true,nil;local owners={};local profile={secretUnlocks={}}
local doorVisited=true
local journey={profile=function()return profile end,currentHevoSeal=function(_,char)return active,char end,
 currentHevoDoorVisit=function()return doorVisited end,syncHevoPersistent=function()return true end}
local recorded=0
local dex={report=function()return{portalReady=active,birthIslandReady=active,jirachiDexReady=active}end,
 record=function()recorded=recorded+1 end}
local battleState={newWild=function(game,id)battles=battles+1;return{game=game,kind='wild',enemy={mon={species=id}}}end}
local H={owned=function(_,id)return owners[id]==true,historyError end}
local E=dofile('hoenn_endgame_run_events_67.lua')(mod)
local P=dofile('hoenn_legend_portals_67.lua')(mod,{dex=dex,journey=journey,geometry={},battleState=battleState})
local B=dofile('hoenn_birth_island_67.lua')(mod,{dex=dex,runEvents=E,battleState=battleState})
local onlyDoor=false
local J=dofile('hoenn_jirachi_finale_67.lua')(mod,{dex=dex,journey=journey,
 battleState=battleState,convergenceOnly=function()return onlyDoor end})
for _,owner in ipairs{P,B,J}do owner.bindLegendHistory(H)end
local g={save={party={},boxes={}},overworld={map={id='ROUTE_1'},player={cellX=4,cellY=5}},stack={states={},push=function(_,p)panel=p end},writeSave=function()return writeOk end}
local currentBattle
local ow={pushBattle=function(_,battle)currentBattle=battle;g.stack.states={battle}end,afterBattle=function()end}
local n=0;local function check(v,msg)n=n+1;assert(v,msg)end
local sites={RED={map='KA_SEVII_RED',x=4,y=4},BLUE={map='KA_SEVII_BLUE',x=4,y=4},GREEN={map='KA_SEVII_GREEN',x=4,y=4}}
check(P.bindSeviiSites(sites),'physical island encounters replace the old rooms')
for _,char in ipairs{'RED','BLUE','GREEN'}do
 local row=P.rows[char];g.overworld.map.id=sites[char].map;owners[row.species]=true
 check(not P.enter(g,row),'former weather chamber entrance closed '..char)
 doorVisited=false;check(not P.available(g,char),'own black door visit required '..char);doorVisited=true
 active=false;check(not P.recordWitness(g,row),'original character/research access required '..char);active=true
 local before=battles;P.challenge(g,ow,nil,nil,row);check(panel.opts,'owned legend offers ceremony')
 panel.opts.choice(false);check(not P.witnessed(g,row),'decline leaves seal untouched')
 writeOk=false;local ok,why=P.recordWitness(g,row);check(not ok and why=='save'and not P.witnessed(g,row),'failed save is retryable');writeOk=true
 P.challenge(g,ow,nil,nil,row);panel.opts.choice(true)
 check(P.witnessed(g,row)and not P.caught(g,row),'separate research witness, never synthetic capture seal')
 check(battles==before and not P.recordWitness(g,row),'no duplicate battle; ceremony idempotent')
 g.save.modData.kanto_ascendant.hevo_persistent.secretUnlocks={};owners[row.species]=false;historyError='offline'
 P.challenge(g,ow,nil,nil,row);check(not panel.opts and not panel.done,'history outage cannot launch catch');historyError=nil
 P.challenge(g,ow,nil,nil,row);local pending=panel.done;owners[row.species]=true;pending()
 check(panel.opts and battles==before,'new ownership rechecked after dialogue')
 local old=g.save;g.save={};panel.opts.choice(true);g.save=old
 check(not P.witnessed(g,row),'queued choice cannot mutate adopted save')
 owners[row.species]=false;P.challenge(g,ow,nil,nil,row);panel.done();check(battles==before+1,'first original catch remains possible')
 check(P.canCapture(g,currentBattle,row.species),'live physical Sevii battle admits ball '..char)
 check(not P.canCapture(g,{game=g,kind='wild',enemy=currentBattle.enemy},row.species),
  'copied battle fields cannot authorize a Sevii catch '..char)
 table.insert(g.save.party,currentBattle.enemy.mon)
 currentBattle.onFinish('caught')
 check(not P.canCapture(g,currentBattle,row.species),'finished battle permission expires '..char)
 check(P.caught(g,row)and recorded>0,'stored native battle identity writes unique capture seal '..char)
 check(not P.recordCatch(g,row,currentBattle.enemy.mon),'duplicate capture receipt refused '..char)
end
g.overworld.map.id=B.MAP;owners.DEOXYS=true
check(not B.recordWitness(g),'Birth Island still requires current-run Moltres/Regirock')
E.mark(g,'MOLTRES',{battleResult='witnessed'});E.mark(g,'REGIROCK',{battleResult='witnessed'})
check(not B.recordWitness(g),'triangle puzzle remains required')
for _=1,#B.trianglePositions-1 do B.triangleTalk(g,ow,nil,nil)end
writeOk=false;local ok,why=B.recordWitness(g);check(not ok and why=='save'and not B.caught(g),'failed Deoxys ceremony rolled back');writeOk=true
local before=battles;B.triangleTalk(g,ow,nil,nil);panel.opts.choice(true)
local receipt=E.state(g).completed.DEOXYS
check(B.caught(g)and receipt.battleResult=='witnessed'and not receipt.captured,'Deoxys current-run research completion')
check(battles==before and not(storage[B.SAVE_KEY]and storage[B.SAVE_KEY].caught),'no Deoxys catch record or duplicate')
E.reset(g);check(not B.caught(g)and not B.recordWitness(g),'NG+ resets only per-run puzzle/completion')
E.mark(g,'MOLTRES',{});E.mark(g,'REGIROCK',{});E.setProgress(g,'DEOXYS_TRIANGLE',#B.trianglePositions-1)
owners.DEOXYS=false;check(B.startBattle(g,ow),'first Deoxys catch route retained')
g.overworld.map.id=J.MAP;owners.JIRACHI=true
onlyDoor=true;panel=nil
local rejected,route=J.enter(g)
check(not rejected and route=='convergence-door-only','captain shortcut cannot bypass convergence door')
local captainDone=false
J.captainTalk(g,ow,nil,function()captainDone=true end)
check(captainDone and panel==nil,'captain keeps original behavior when Sevii owns Jirachi door')
active=false;check(not J.recordWitness(g),'Jirachi still requires original full research');active=true
writeOk=false;ok,why=J.recordWitness(g);check(not ok and why=='save'and not J.witnessed(g),'failed wish witness rolled back');writeOk=true
before=battles;J.challenge(g,ow,nil,nil);panel.opts.choice(true)
check(J.witnessed(g)and not J.caught(g)and storage[J.SAVE_KEY].certificate,'certificate earned without forged catch')
check(getmetatable(panel)==J.Certificate and battles==before,'real certificate screen, no duplicate battle')
check(not storage[J.SAVE_KEY].caught and not J.recordWitness(g),'wish witness idempotent; caught ledger unchanged')
-- The real Dex authority distinguishes captures from research witnesses.
local source={order={},species={}};local names={[382]='KYOGRE',[383]='GROUDON',[384]='RAYQUAZA',[385]='JIRACHI',[386]='DEOXYS'}
for i=252,386 do local id=names[i]or('SPECIES_'..i);source.order[#source.order+1]=id;source.species[id]={sourceDex=i}end
profile.completedPaths={red=true,green=true,blue=false}
local D=dofile('hoenn_dex_completion_67.lua')(mod,{data=source,journey=journey})
g.save.pokedex={owned={}};for _,id in ipairs(D.order)do g.save.pokedex.owned[id]=id~='DEOXYS'end
g.save.modData.kanto_ascendant.hevo_persistent.secretUnlocks={KA_LEGEND_WITNESS_GROUDON=true,KA_LEGEND_WITNESS_KYOGRE=true,KA_LEGEND_WITNESS_RAYQUAZA=true}
check(not D.report(g).birthIslandReady,'research witnesses cannot skip three character paths')
profile.completedPaths.blue=true;local report=D.report(g)
check(report.birthIslandReady and report.allPortalResearch and not report.allPortalCaptures,'all original paths plus witnessed seals open research, not capture ledger')
check(not report.jirachiDexReady,'Deoxys ownership still required before Jirachi')
g.save.pokedex.owned.DEOXYS=true;check(D.report(g).jirachiDexReady,'full original 134-species requirement remains usable')
-- An absent local map import is supported: original Kanto owners retain
-- their baseline behavior instead of waiting forever for an absent archive.
local R=dofile('hoenn_roamers_67.lua')(mod,{fieldAccess={legendAccess=function()return true end}})
local V=dofile('hoenn_moltres_volcano_67.lua')(mod,{geometry={},runEvents=E,postgame={}})
local T=dofile('hoenn_research_sanctums_67.lua')(mod,{geometry={},runEvents=E,postgame={},dex=dex})
local absent=dofile('sevii_expedition.lua')({read=function()return nil end},{
 hoennRoamers=R,hoennMoltres=V,hoennSanctums=T})
check(not absent.available,'absent import skips Sevii without replacing original owners')
local clean={save={pokedex={owned={}}}}
for _,lookup in ipairs{
 function()return R.priorOwnership(clean,'LATIAS')end,
 function()return V.priorOwnership(clean)end,
 function()return T.priorOwnership(clean,T.rows[1])end,
}do local owned,err=lookup();check(not owned and not err,'absent optional import is not an archive failure')end
clean.save.pokedex.owned.LATIAS=true
check(R.priorOwnership(clean,'LATIAS'),'original Dex ownership still authoritative without Sevii')
for _,owner in ipairs{R,V,T}do owner.bindLegendHistory(H)end
owners.LATIAS=true;owners.MOLTRES=true;owners[T.rows[1].species]=true
check(R.priorOwnership(clean,'LATIAS')and V.priorOwnership(clean)and T.priorOwnership(clean,T.rows[1]),'bound owners share canonical history')
historyError='offline';owners.LATIAS=false
local owned,err=R.priorOwnership(clean,'LATIAS')
check(not owned and err=='offline','bound unreadable archive cannot fall back to old Dex behavior')
print('PASS Sevii Hoenn continuity: '..n..' checks')
