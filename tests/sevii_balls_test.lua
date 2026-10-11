local items,effects,balls={},{},{}
items.SOOTHE_BELL={id='SOOTHE_BELL',price=4000}
local function reg(t)return {get=function(_,id)return t[id]end,
 register=function(_,id,v)assert(not t[id]);t[id]=v end,
 patch=function(_,id,v)for k,x in pairs(v)do t[id][k]=x end end}end
local native={BALLS={}}
package.preload['src.inventory.ItemEffects']=function()return native end
local Battle={newWild=function(game,species,level)return{game=game,enemy={mon={species=species,level=level}}}end}
package.preload['src.battle.BattleState']=function()return Battle end
local callbacks={};local profile={extensionsEnabled=true,activeEpoch=3};local environment='land'
local B=dofile('sevii_balls.lua')({content={items=reg(items),balls=reg(balls),item_effects=reg(effects)},
 events={on=function(_,id,f)callbacks[id]=f end}},
 {i18n={text=function(en)return en end},rules={MODE_OFF='OFF',peek=function()return profile end},environment=function()return environment end})
local d={dex=129,types={'WATER'},catchRate=45}
local mon={species='MAGIKARP',level=5,hp=100,stats={hp=100}}
local g={data={items=items,pokemon={MAGIKARP=d,ALIAS=d}},save={pokedex={owned={},seen={MAGIKARP=true}}}}
local b={game=g,kind='wild',enemy={mon=mon,def=d,curTypes={'WATER'}}}
local n=0;local function check(v,msg)n=n+1;assert(v,msg)end
check(Battle.newWild(g,'MAGIKARP',5,{hooked=true}).encounterSource=='fishing','native rod constructor receipt')
check(not Battle.newWild(g,'MAGIKARP',5,{}).encounterSource,'ordinary constructor stays unmarked')
local function q(id)return assert(B.quote(id,b))end
for _,id in ipairs(B.ids)do
 check(native.BALLS[id]and items[id].ball==id and effects[items[id].effect].use==B.use,'registered usable '..id)
 check(B.use{itemId=id,battle=b}=='ball','native preflight '..id)
 profile.activeEpoch=2;check(not B.quote(id,b),'Gen2 rejects '..id);profile.activeEpoch=3
 profile.extensionsEnabled=false;check(not B.quote(id,b),'OFF rejects '..id);profile.extensionsEnabled=true
 for _,flag in ipairs({'ghost','noCatch','demo'})do
  b[flag]=true;check(not B.quote(id,b),'story/no demo '..id..flag);b[flag]=nil
 end
 b.kind='trainer';check(not B.quote(id,b),'trainer rejected '..id);b.kind='wild'
 local ctx={battle=b,targetMon=mon,targetDef=d,rng=function()return 0 end}
 check(B.attempt(id,ctx)==true,'real random-roll success '..id)
 ctx.rng=function()return 65535 end
 check(B.attempt(id,ctx)==false,'real random-roll failure '..id)
end
check(q('PREMIER_BALL').multiplier==1 and q('PREMIER_BALL').odds==15,'Premier uses neutral Hoenn catch formula')
check(q('LUXURY_BALL').multiplier==1 and q('LUXURY_BALL').odds==15,'Luxury keeps neutral catch formula')
local ordinary={johtoBond=70};local luxury={johtoBond=70}
callbacks['pokemon.caught']{ball='LUXURY_BALL',mon=luxury}
check(luxury._kascLuxuryBall==true,'successful Luxury capture records ball provenance')
check(B.gainFriendship(g,ordinary,10)and ordinary.johtoBond==80,'ordinary gain stays unchanged')
check(B.gainFriendship(g,luxury,10)and luxury.johtoBond==90,'Luxury doubles established gain')
local soothe={johtoBond=70,item='SOOTHE_BELL',heldItem='SOOTHE_BELL'}
check(B.gainFriendship(g,soothe,10)and soothe.johtoBond==85,'held Soothe Bell increases established gain')
check(B.supportsFriendshipItem(g,'SOOTHE_BELL',3),'equipment view exposes working bell')
check(B.gainFriendship(g,soothe,1)and soothe.johtoBond==87,'small Soothe Bell gain rounds up')
luxury.item='SOOTHE_BELL';luxury.heldItem='SOOTHE_BELL'
check(B.gainFriendship(g,luxury,1)and luxury.johtoBond==93,'Luxury and held bell combine')
profile.activeEpoch=2;B.gainFriendship(g,luxury,1)
check(luxury.johtoBond==94,'earlier profile does not boost friendship')
check(not B.supportsFriendshipItem(g,'SOOTHE_BELL',2),'equipment view rejects earlier profile')
profile.activeEpoch=3;profile.extensionsEnabled=false;B.gainFriendship(g,luxury,1)
check(luxury.johtoBond==95,'disabled extensions do not boost friendship')
check(not B.supportsFriendshipItem(g,'SOOTHE_BELL',3),'equipment view rejects disabled extension')
profile.extensionsEnabled=true;luxury.johtoBond=254;B.gainFriendship(g,luxury,10)
check(luxury.johtoBond==255,'Luxury gain respects friendship cap')
check(q('NET_BALL').multiplier==3 and q('NET_BALL').odds==45,'water bonus and full HP odds')
b.enemy.curTypes={'NORMAL','BUG'};check(q('NET_BALL').multiplier==3,'secondary type')
b.enemy.curTypes={'FIRE'};check(q('NET_BALL').multiplier==1,'current type takes priority')
for _,r in ipairs({{1,3.9},{5,3.5},{29,1.1},{30,1},{40,1},{100,1}})do
 mon.level=r[1];check(q('NEST_BALL').multiplier==r[2],'nest level '..r[1])
end
check(q('REPEAT_BALL').multiplier==1,'seen alone gives no repeat bonus')
g.save.pokedex.owned.ALIAS=true;check(q('REPEAT_BALL').multiplier==3,'owned canonical alias')
g.save.pokedex.owned={MAGIKARP=true};check(q('REPEAT_BALL').multiplier==3,'owned exact identity')
check(q('TIMER_BALL').multiplier==1,'first turn neutral')
for i=1,40 do
 callbacks['battle.turn_ended']{battle=b,turn=0} -- item turns may keep native turnCount unchanged
 check(q('TIMER_BALL').multiplier==1+math.min(i,30)/10,'completed move/item turn '..i)
end
check(q('PREMIER_BALL').multiplier==1 and q('PREMIER_BALL').odds==15,'Premier does not inherit type, level, ownership or turn bonuses')
check(B.validateCheckpoint(b),'valid checkpoint counter')
local restored={game=g,kind='wild',field={tokens={[B.TOKEN]=b.field.tokens[B.TOKEN]}},enemy=b.enemy}
check(B.quote('TIMER_BALL',restored).multiplier==4,'data-only checkpoint token restored')
b.field.tokens[B.TOKEN]=-1;check(not B.validateCheckpoint(b),'invalid checkpoint rejected');b.field=nil
check(B.validateCheckpoint(b)and B.completedTurns(b)==0,'old checkpoint starts without invented turns')
b.kascGenerationRulesReceipt={mode='GEN3',activeEpoch=3};profile.activeEpoch=1
check(B.quote('NET_BALL',b)~=nil,'frozen battle profile remains authoritative')
b.kascGenerationRulesReceipt={mode='OFF',activeEpoch=3};check(not B.quote('NET_BALL',b),'frozen OFF rejects')
b.kascGenerationRulesReceipt=nil;profile.activeEpoch=3
mon.hp=1;mon.level=30;b.enemy.curTypes={'WATER'}
local base=q('NET_BALL').odds;check(base==134,'Gen3 HP term')
mon.status='SLP';check(q('NET_BALL').odds==255,'sleep doubles and caps')
mon.status='PAR';check(q('NET_BALL').odds==201,'paralysis 1.5 factor')
mon.status=nil;mon.hp=100
local threshold=q('NET_BALL').threshold
local calls=0
local ok,shakes=B.attempt('NET_BALL',{battle=b,targetMon=mon,targetDef=d,rng=function(lo,hi)
 check(lo==0 and hi==65535,'16-bit catch random range');calls=calls+1;return calls==3 and threshold or threshold-1
end})
check(not ok and shakes==2 and calls==3,'strict threshold and partial shakes')
check(q('DIVE_BALL').multiplier==1,'old checkpoint without origin remains neutral')
b.checkpointOrigin={map='SHORE'};g.overworld={map={id='SHORE'}}
for _,kind in ipairs{'land','water','pond','underwater'}do
 b.field=nil;environment=kind;callbacks['battle.started']{battle=b}
 local expected=kind=='land'and 1 or 3.5
 check(q('DIVE_BALL').multiplier==expected,'captured starting environment '..kind)
 environment='land';b.encounterSource='static';callbacks['battle.started']{battle=b}
 check(q('DIVE_BALL').multiplier==expected,'replayed start never replaces original environment '..kind)
end
b.field=nil;environment='land';b.encounterSource='fishing';B.started{battle=b}
check(q('DIVE_BALL').multiplier==3.5,'native fishing source admits shore fishing')
b.encounterSource='wild';g.overworld.map.id='OTHER'
check(q('DIVE_BALL').multiplier==3.5,'starting fishing receipt survives mutable live context')
local restored={game=g,kind='wild',field={tokens={[B.ENVIRONMENT]={kind='land',fishing=true,map='SHORE'}}},checkpointOrigin={map='SHORE'},enemy=b.enemy}
check(B.validateCheckpoint(restored)and B.quote('DIVE_BALL',restored).multiplier==3.5,'data-only checkpoint preserves fishing bonus')
restored.checkpointOrigin.map='OTHER';check(not B.validateCheckpoint(restored),'cross-map environment rejected')
check(B.quote('DIVE_BALL',restored).multiplier==1,'invalid provenance grants no bonus')
restored.checkpointOrigin.map='SHORE';restored.field.tokens[B.ENVIRONMENT].extra=true
check(not B.validateCheckpoint(restored),'unknown environment field rejected')
for _,bad in ipairs{1,'water',{kind='water',map='SHORE',fishing=1},{kind='forest',map='SHORE',fishing=false}}do
 restored.field.tokens[B.ENVIRONMENT]=bad;check(not B.validateCheckpoint(restored),'malformed environment rejected')
 check(B.quote('DIVE_BALL',restored).multiplier==1,'malformed environment remains neutral')
end
b.field=nil;environment='land';b.encounterSource='wild';B.started{battle=b}
check(q('DIVE_BALL').multiplier==1,'water-type target alone never grants bonus')
profile.activeEpoch=2;check(not B.quote('DIVE_BALL',b),'Dive respects earlier profile');profile.activeEpoch=3
print('PASS Sevii balls: '..n..' checks')
