local items,effects={},{}
local function registry(rows)return{
  get=function(_,id)return rows[id]end,
  register=function(_,id,value)assert(not rows[id]);rows[id]=value end,
  patch=function(_,id,value)for key,field in pairs(value)do rows[id][key]=field end end,
}end
local hook,applied
local profile={extensionsEnabled=true,activeEpoch=3}
local mod={content={items=registry(items),item_effects=registry(effects)},
  hooks={wrap=function(_,name,fn)assert(name=='item.use');hook=fn end},
  exports={daycare={breedingIVs={valid=function(_,mon)return mon.bred==true end,
    apply=function(_,mon,epoch)applied=(applied or 0)+1;mon.bredEpoch=epoch;return true end}}}}
local Z=dofile('sevii_zinc.lua')(mod,{i18n={text=function(en)return en end},
  rules={peek=function()return profile end}})
local game={data={items=items,item_effects=effects,pokemon={TEST={name='Test'}}},save={party={}}}
local checks=0;local function check(value,message)checks=checks+1;assert(value,message)end
local function pokemon(special,bred)
  local mon={species='TEST',statExp={special=special},bred=bred}
  game.save.party={mon};return mon
end
local function use(mon)
  return Z.use{data=game.data,save=game.save,itemId='ZINC',target=mon}
end
local mon=pokemon(5120,true)
check(Z.supports(game),'Gen3 Zinc is registered and available')
check(use(mon)=='consumed'and mon.statExp.special==5120
  and mon.statExp.specialDefense==7680,'Zinc raises only Special Defense')
check(applied==1 and mon.bredEpoch==3,'bred stat projection refreshed')
local function calcium(_,_,_,target)
  target.statExp.special=target.statExp.special+2560
  return 'consumed',nil,{useJingle=true}
end
local result,messages,extra=hook(calcium,game,nil,'CALCIUM',mon)
check(result=='consumed'and messages==nil and extra.useJingle,
  'native Calcium return values preserved')
check(mon.statExp.special==7680 and mon.statExp.specialDefense==10240,
  'Calcium still trains both sides after Zinc')
check(applied==2,'bred projection refreshed after Calcium')
check(hook(function(_,_,_,target)target.statExp.special=target.statExp.special+2560 end,
    game,nil,'CALCIUM',mon)==nil and mon.statExp.specialDefense==12800,
  'Gen-1 Bag dispatcher without return value still carries Calcium training')
mon.statExp.specialDefense=25599
check(use(mon)=='consumed'and mon.statExp.specialDefense==28159,
  'last valid vitamin dose is not clipped to threshold')
check(use(mon)=='failed'and mon.statExp.specialDefense==28159,
  'vitamin limit refuses another dose')
mon=pokemon(0,false);profile.activeEpoch=2
check(not Z.supports(game)and use(mon)=='failed'and mon.statExp.specialDefense==nil,
  'Gen2 keeps the shared Special training model')
profile.activeEpoch=3;profile.extensionsEnabled=false
check(use(mon)=='failed','OFF refuses Zinc')
local prior=applied
mon.bred=true;mon.statExp.specialDefense=2560
hook(calcium,game,nil,'CALCIUM',mon)
check(mon.statExp.special==2560 and mon.statExp.specialDefense==5120
  and applied==prior,'OFF Calcium preserves separate training without Gen3 stat projection')
profile.extensionsEnabled=true;mon.isEgg=true
check(use(mon)=='failed','Egg refuses Zinc')
mon.isEgg=nil;local other=pokemon(0,false)
check(use(mon)=='failed'and other.statExp.specialDefense==nil,
  'foreign party target refuses Zinc')
mon=other;check(use(mon)=='consumed'and mon.statExp.specialDefense==2560,
  'unbred Pokemon gets a separate training value')
check(hook(function()return'failed'end,game,nil,'CALCIUM',mon)=='failed'
  and mon.statExp.specialDefense==2560,'failed Calcium does not change Zinc')
local Oak=dofile('legacy_oak_finale.lua')({exports={},hooks={wrap=function()end}},
  {journey={},paths={}})
local trialData={pokemon={TEST={baseStats={hp=80,attack=80,defense=80,speed=80,special=80},
  level1Moves={'TACKLE'}}},moves={TACKLE={pp=35}}}
local trialMon={species='TEST',level=70,moves={{id='TACKLE',pp=35}},
  dvs={attack=10,defense=10,speed=10,special=10},
  statExp={hp=0,attack=0,defense=0,speed=0,special=0,specialDefense=2560}}
local trial=assert(Oak.normaliseMon(trialData,trialMon))
check(trial.statExp.specialDefense==2560 and trial.statExp.special==0,
  'Oak Legacy trial keeps separate Zinc training in its validated copy')
trialMon.statExp.specialDefense=65536
local denied,reason=Oak.normaliseMon(trialData,trialMon)
check(denied==nil and reason=='invalid_stat_exp',
  'Oak Legacy trial rejects invalid separate training')
print('PASS Sevii Zinc: '..checks..' checks')
