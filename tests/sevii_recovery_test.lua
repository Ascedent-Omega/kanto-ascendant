local items,effects,hooks={},{},{}
local function reg(t)return{get=function(_,id)return t[id]end,register=function(_,id,v)assert(not t[id]);t[id]=v end,
 patch=function(_,id,v)for k,x in pairs(v)do t[id][k]=x end end}end
package.loaded['src.core.Sound']={play=function()end}
local selected,selectedOwner
package.loaded['src.ui.Screens']={push=function(g,screen,mon,prompt,cb,cancel,owner)
 selected,selectedOwner=cb,owner
end}
local profile={activeEpoch=3,extensionsEnabled=true};local cures=0
local R=dofile('sevii_recovery.lua')({content={items=reg(items),item_effects=reg(effects)},
 hooks={wrap=function(_,id,fn)hooks[id]=fn end}},{i18n={text=function(en)return en end},
 rules={MODE_OFF='OFF',peek=function()return profile end},infatuation={cure=function(b,who)
  if not who.love then return false end;who.love=nil;cures=cures+1;return true end}})
local mon={species='EEVEE',hp=30,stats={hp=50},moves={{id='TACKLE',pp=4,ppUps=1},{id='GROWL',pp=2},{id='SKETCH',pp=1}}}
local g={data={items=items,item_effects=effects,moves={TACKLE={pp=35,name='TACKLE'},GROWL={pp=40},SKETCH={pp=1}}},
 save={party={mon},inventory={PP_MAX=2}}}
local b={game=g,player={mon=mon},kascGenerationRulesReceipt={mode='GEN3',activeEpoch=3}}
local n=0;local function check(v,m)n=n+1;assert(v,m)end
local function use(id,target,battle,index)return R.use{itemId=id,target=target,battle=battle,moveIndex=index,data=g.data,save=g.save}end
for _,r in ipairs(R.rows)do
 check(R.supports(g,r.id),'registered effect '..r.id)
 profile.activeEpoch=r.gen-1;check(not R.supports(g,r.id),'generation gate '..r.id);profile.activeEpoch=3
 profile.extensionsEnabled=false;check(not R.supports(g,r.id),'disabled extensions '..r.id);profile.extensionsEnabled=true
end
check(use('PP_MAX',mon,nil,2)=='consumed'and mon.moves[2].ppUps==3 and mon.moves[2].pp==26,'selected move capacity and PP difference')
check(mon.moves[1].pp==4 and mon.moves[1].ppUps==1,'other move unchanged')
check(use('PP_MAX',mon,nil,1)=='consumed'and mon.moves[1].pp==18,'existing PP Up counts preserved')
check(use('PP_MAX',mon,nil,1)=='failed','already maxed refusal')
check(use('PP_MAX',mon,nil,3)=='failed','Sketch refusal')
for _,slot in ipairs{0,5,1.5,'1'}do check(use('PP_MAX',mon,nil,slot)=='failed','invalid selected move '..slot)end
check(use('PP_MAX',mon)=='failed','no implicit first move')
check(use('PP_MAX',mon,b,2)=='failed','cannot use PP Max in battle')
check(use('PP_MAX',{species='EEVEE',moves=mon.moves},nil,2)=='failed','foreign target refused')
mon.isEgg=true;check(use('PP_MAX',mon,nil,2)=='failed','egg refused');mon.isEgg=nil
local faint={species='PIDGEY',hp=0,status='PSN',stats={hp=99},moves={{id='TACKLE',pp=2}}}
local faint2={species='RATTATA',hp=0,stats={hp=77}}
local egg={species='EGG',hp=0,stats={hp=10},isEgg=true}
g.save.party={mon,faint,faint2,egg};mon.status='BRN'
check(use('SACRED_ASH',nil,b)=='failed'and faint.hp==0,'ash battle refusal')
check(use('SACRED_ASH')=='consumed','one ash revives all fainted members')
check(faint.hp==99 and faint2.hp==77 and not faint.status,'full HP and cleared fainted status')
check(mon.hp==30 and mon.status=='BRN'and faint.moves[1].pp==2 and egg.hp==0,'living members, PP and eggs unchanged')
check(use('SACRED_ASH')=='failed','no fainted members no consumption')
mon.status='SLP';check(use('BLUE_FLUTE',mon)=='kept'and not mon.status,'blue field sleep cure reusable')
check(use('BLUE_FLUTE',mon)=='failed','blue no effect')
mon.status='SLP';b.player.sleepTurns=5;b.player.confusedTurns=3
check(use('BLUE_FLUTE',mon,b)=='kept'and not b.player.sleepTurns and not mon.status,'blue clears active sleep counter')
check(b.player.confusedTurns==3,'blue preserves confusion')
check(use('YELLOW_FLUTE',mon,b)=='kept'and not b.player.confusedTurns,'yellow active confusion cure reusable')
check(use('YELLOW_FLUTE',mon,b)=='failed','yellow no effect')
check(use('YELLOW_FLUTE',faint,b)=='failed','yellow cannot cure unrelated reserve')
b.player.love=true;b.player.confusedTurns=2
check(use('RED_FLUTE',mon,b)=='kept'and not b.player.love and cures==1,'red uses existing infatuation owner')
check(b.player.confusedTurns==2,'red does not clear other volatiles')
check(use('RED_FLUTE',mon,b)=='failed','red no effect')
for _,id in ipairs{'RED_FLUTE','YELLOW_FLUTE'}do check(use(id,mon)=='failed','battle-only '..id)end
profile.activeEpoch=1;mon.status='SLP';check(use('BLUE_FLUTE',mon,b)=='kept','frozen battle profile authoritative');profile.activeEpoch=3
b.kascGenerationRulesReceipt.mode='OFF';mon.status='SLP';check(use('BLUE_FLUTE',mon,b)=='failed','frozen OFF blocks');b.kascGenerationRulesReceipt.mode='GEN3'
mon.hp=0;check(use('BLUE_FLUTE',mon,b)=='failed','no waking fainted mon');mon.hp=30
mon.isEgg=true;check(use('BLUE_FLUTE',mon,b)=='failed','no egg status cure');mon.isEgg=nil
local calls,slot=0
local nextUse=function(_,_,_,_,_,i)calls=calls+1;slot=i end
local picker={}
hooks['item.use'](nextUse,g,nil,'PP_MAX',mon,{},nil,picker)
check(type(selected)=='function'and calls==0,'move picker defers native item mutation')
check(selectedOwner==picker,'native party picker owns the held move menu so result handling can close it')
selected(2);selected(1);check(calls==1 and slot==2,'chosen slot sent to native flow once')
hooks['item.use'](nextUse,g,nil,'PP_MAX',mon,{},nil,{})
local original=g.save;g.save={party={mon},inventory={PP_MAX=2}};selected(1);check(calls==1,'stale save callback does not act');g.save=original
hooks['item.use'](nextUse,g,nil,'PP_MAX',mon,{},nil,{})
g.save.inventory.PP_MAX=0;selected(1);check(calls==1,'absent item does not apply');g.save.inventory.PP_MAX=2
hooks['item.use'](nextUse,g,nil,'POTION',mon,{},nil,{});check(calls==2,'other items untouched')
check(use('FLUFFY_TAIL')=='failed','escape toy unavailable in field')
b.kind='wild';check(use('FLUFFY_TAIL',nil,b)=='consumed_escape','native consumable escape flow')
for _,key in ipairs{'ghost','demo','noCatch','kaRocketNoEscape','kaMythicEcho','result'}do
 b[key]=true;check(use('FLUFFY_TAIL',nil,b)=='failed','escape preserves restriction '..key);b[key]=nil
end
b.kind='trainer';check(use('FLUFFY_TAIL',nil,b)=='failed','toy cannot leave trainer battle');b.kind='wild'
b.encounterSource='sevii-special-HEATRAN';check(use('FLUFFY_TAIL',nil,b)=='failed','authored legendary battle source cannot be bypassed');b.encounterSource=nil
b.checkpointOrigin={kind='scripted_battle'};check(use('FLUFFY_TAIL',nil,b)=='failed','scripted battle origin cannot be bypassed');b.checkpointOrigin=nil
b.kascGenerationRulesReceipt.activeEpoch=2;check(use('FLUFFY_TAIL',nil,b)=='failed','toy unavailable under frozen Gen2 profile')
b.kascGenerationRulesReceipt.activeEpoch=3
check(not effects[items.FLUFFY_TAIL.effect].field and effects[items.FLUFFY_TAIL.effect].battle,'battle-only native effect metadata')
print('PASS Sevii recovery: '..n..' checks')
