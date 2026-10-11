local function copy(v)if type(v)~='table'then return v end;local t={};for k,x in pairs(v)do t[k]=copy(x)end;return t end
local callbacks={};local store={};local released,writes=0,0;local unavailable={DARKRAI=true}
local data=dofile('rocket_recovery_raids_67_data.lua')
local mod={events={on=function(_,event,fn)callbacks[event]=fn end},save={get=function(_,k)return copy(store[k])end,set=function(_,k,v)store[k]=copy(v)end}}
local R=dofile('rocket_recovery_raids_67.lua')(mod,{data=data,captureAvailable=function(_,r)return not unavailable[r.species]end,
 sources={release=function()released=released+1;return true end},generationRules={rulesReceipt=function()return{activeEpoch=4,supportedEpoch=4}end}})
local g={data={moves={}},writeSave=function()writes=writes+1;return true end}
local n=0;local function check(v,m)n=n+1;assert(v,m)end
local function setup(instance,rows)
 store[R.stateKey]={schema=R.schema,version=R.version,status='capture',instance=instance,incident=1,rulesReceipt={activeEpoch=4,supportedEpoch=4},scaleReceipt={},
 pendingCaptures=copy(rows),captureIndex=1,captureReceipts={},rewardReceipts={kept=true},source='box'}
end
local darkrai,genesect,regigigas,zygarde=unpack(data.contraband)
setup(4,{regigigas});check(R.install(g),'load ordinary pending rescue')
check(R.currentCapture().species=='REGIGIGAS'and writes==0 and released==0,'string instance ID preserves unowned pending capture on reload')
setup(2,{darkrai});check(R.install(g),'retired island source reconciled')
check(R.status().status=='active'and R.status().instance==3,'campaign advances from retired Darkrai rescue')
check(not next(R.status().captureReceipts)and R.status().rewardReceipts.kept,'no fabricated catch or discarded reward')
setup(2,{});local boss=store[R.stateKey];boss.status='active';boss.fight=data.instances[2].fights;boss.rewardPlan={qa=true}
check(R.onFightWon(g),'new boss completion uses source migration gate')
check(R.status().status=='active'and R.status().instance==3 and not R.currentCapture(),'new Darkrai rescue never queued after relocation')
check(R.status().completed.lavender_relay and R.status().rewardReceipts.lavender_relay.qa,'real boss and reward receipts preserved')
setup(4,{darkrai,regigigas});check(R.reconcileCaptures(g),'mixed queue reconciled')
check(R.currentCapture().species=='REGIGIGAS'and R.status().captureIndex==2,'later available entry kept')
check(R.reconcileCaptures(g)and R.status().captureIndex==2,'reconciliation idempotent')
unavailable.REGIGIGAS=true;check(R.reconcileCaptures(g),'ownership changed while queued')
check(R.status().status=='complete'and R.status().campaignComplete and released==1,'final rescue frees custody and completes campaign')
check(not next(R.status().captureReceipts),'skip never claims Pokemon delivered')
setup(3,{genesect});check(R.install(g)and R.currentCapture().species=='GENESECT','unrelated Gen5 lead remains')
setup(4,{zygarde});local s=store[R.stateKey];s.cellReceipts={zygarde_cells={}}
for _,id in ipairs(zygarde.instances)do s.cellReceipts.zygarde_cells[id]=true end
check(R.install(g)and R.currentCapture().species=='ZYGARDE_10','four-cell lead uses stable string instance ID')
setup(4,{regigigas});g.save={};R.game=g
callbacks['save.loaded']{save={}}
check(R.status().status=='capture','unrelated save event cannot mutate active rescue')
callbacks['save.loaded']{save=g.save}
check(R.status().status=='complete','adopted save event reconciles old owned rescue')
setup(2,{darkrai});g.writeSave=function()return false end
local ok,why=R.reconcileCaptures(g);check(not ok and why=='capture_defer_save_failed','migration save failure surfaced')
-- Source selection uses canonical identities; an absent island owner leaves
-- an existing unowned Rocket lead intact. Other generations stay untouched.
package.loaded['src.inventory.ItemEffects']={use=function()end}
local owned={};local S={maps={},specialEncounters={rows={DARKRAI={dex=491}}}}
local P=dofile('sevii_legend_policy.lua')({hooks={wrap=function()end}},S,{
 backendSpecies=function()return{bySpecies={DARKRAI='dex:491',REGIGIGAS='dex:486',GENESECT='dex:649',ZYGARDE_10='dex:718'}}end,
 legendHistory=function()return{key=function(id)return id.species=='REGIGIGAS'end,
 owned=function(_,id)return owned[id.species]==true end}end})
local allowed,reason=P.raidCaptureAllowed(g,darkrai)
check(not allowed and reason=='sevii_relocated','authored Darkrai quest retires original source')
check(P.raidCaptureAllowed(g,regigigas),'unowned Regigigas remains until its island quest exists')
owned.REGIGIGAS=true;check(not P.raidCaptureAllowed(g,regigigas),'old ownership excludes another Rocket specimen')
check(P.raidCaptureAllowed(g,genesect)and P.raidCaptureAllowed(g,zygarde),'unrelated Rocket species preserved')
S.specialEncounters.rows.REGIGIGAS={dex=486};owned.REGIGIGAS=nil
check(not P.raidCaptureAllowed(g,regigigas),'future authored relocation uses same owner rule')
print('PASS Sevii Rocket transition: '..n..' checks')
