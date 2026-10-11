local items,effects={},{}
local function registry(t)return{get=function(_,id)return t[id]end,
 register=function(_,id,r)assert(not t[id]);t[id]=r end,
 patch=function(_,id,r)for k,v in pairs(r)do t[id][k]=v end end}end
local sound=0;package.preload['src.core.Sound']=function()return{play=function()sound=sound+1 end}end
local profile={extensionsEnabled=true,activeEpoch=4}
local M=dofile('sevii_medicine.lua')({content={items=registry(items),item_effects=registry(effects)}},
 {i18n={text=function(en)return en end},rules={peek=function()return profile end}})
local g={data={items=items,item_effects=effects,pokemon={TEST={name='Test'}}},save={party={}}}
local ow={game=g};local checks=0
local function check(v,msg)checks=checks+1;assert(v,msg)end
local function mon(hp,bond,status)
 local m={species='TEST',hp=hp,stats={hp=300},johtoBond=bond,status=status};g.save.party={m};return m
end
local function use(id,m,b)
 return M.use{data=g.data,save=g.save,itemId=id,target=m,overworld=ow,battle=b}
end
for _,r in ipairs(M.rows)do
 local hp=r.revive and 0 or 1;local m=mon(hp,220,r.cure and'PSN'or nil)
 check(use(r.id,m)=='consumed','usable '..r.id)
 check(m.hp==(r.hp and hp+r.hp or r.revive and 300 or hp),'amount '..r.id)
 check(m.johtoBond==220-(r.bitter and r.bitter[2]or 0),'bitter upper tier '..r.id)
 if r.cure then check(m.status==nil,'status healed '..r.id)end
 local m=mon(300,220)
 check(use(r.id,m)=='failed'and m.johtoBond==220,'ineffective has no penalty '..r.id)
 m=mon(hp,100,r.cure and'PAR'or nil)
 check(use(r.id,m)=='consumed'and m.johtoBond==100-(r.bitter and r.bitter[1]or 0),'bitter lower tier '..r.id)
 m=mon(hp,2,r.cure and'SLP'or nil);m.isEgg=true
 check(use(r.id,m)=='failed'and m.hp==hp and m.johtoBond==2,'egg unchanged '..r.id)
 m=mon(hp,220,r.cure and'PSN'or nil);profile.activeEpoch=1
 check(use(r.id,m)=='failed'and m.hp==hp and m.johtoBond==220,'Gen1 rejects '..r.id)
 profile.activeEpoch=4;profile.extensionsEnabled=false
 check(use(r.id,m)=='failed','OFF rejects '..r.id);profile.extensionsEnabled=true
 local other=mon(hp,220,r.cure and'BRN'or nil)
 check(use(r.id,m)=='failed'and other.hp==hp,'foreign target rejected '..r.id)
end
for _,id in ipairs({'HEAL_POWDER','LAVA_COOKIE'})do
 for _,status in ipairs({'PSN','BRN','FRZ','SLP','PAR'})do
  local m=mon(100,220,status);local b={game=g,player={mon=m,toxicCounter=8,sleepTurns=4,confusedTurns=3}}
  check(use(id,m,b)=='consumed'and not m.status and not b.player.toxicCounter and not b.player.sleepTurns and not b.player.confusedTurns,'active status counters '..id..status)
 end
 local m=mon(100,220);local b={game=g,player={mon=m,confusedTurns=3}}
 check(use(id,m,b)=='consumed'and not b.player.confusedTurns,'confusion only '..id)
end
local m=mon(0,1,'PSN');m.friendship=220;m.happiness=150
local b={game=g,player={mon=m},participants={}}
check(use('REVIVAL_HERB',m,b)=='consumed'and b.participants[m]and m.hp==300 and not m.status,'revived participant restored')
check(m.johtoBond==0 and m.friendship==200 and m.happiness==135,'all existing bond representations lowered without resetting')
m=mon(295,50);check(use('MOOMOO_MILK',m)=='consumed'and m.hp==300,'HP caps')
m=mon(0,220);check(use('ENERGY_ROOT',m)=='failed'and m.johtoBond==220,'HP healing cannot revive')
profile.activeEpoch=2;m=mon(100,220,'PAR');check(use('LAVA_COOKIE',m)=='failed'and m.status=='PAR','Gen3 cookie gate')
check(use('HEAL_POWDER',m)=='consumed','Johto herbs in Gen2')
print('PASS Sevii medicine: '..checks..' checks')
