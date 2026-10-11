local items={LUCKY_EGG={id='LUCKY_EGG',price=200},AMULET_COIN={id='AMULET_COIN',price=200}}
local profile={extensionsEnabled=true,activeEpoch=3,mode='GEN3'}
local callbacks,wrap={},nil
local mod={content={items={get=function(_,id)return items[id]end,patch=function(_,id,v)
  for k,x in pairs(v)do items[id][k]=x end
end}},events={on=function(_,name,fn)callbacks[name]=fn end},hooks={wrap=function(_,name,fn,priority)
  assert(name=='exp.gain'and priority==500);wrap=fn
end},exports={pokemonEquipment67={battleHeldId=function(mon)return mon.item end}}}
local M=dofile('sevii_training_items.lua')(mod,{rules={MODE_OFF='OFF',peek=function()return profile end}})
local egg={species='BLASTOISE',item='LUCKY_EGG'}
local plain={species='PIDGEY'}
local g={data={items=items},save={party={egg,plain}}}
local b={kind='wild',game=g,kascGenerationRulesReceipt={mode='GEN3',activeEpoch=3}}
local checks=0;local function check(v,why)checks=checks+1;assert(v,why)end
local function award(mon,n)return wrap(function()return n end,{mon=mon})end
check(items.LUCKY_EGG.kascSeviiTrainingItem==M.OWNER,'item owner marker')
check(items.AMULET_COIN.kascSeviiTrainingItem==M.OWNER,'coin owner marker')
check(M.supportsItem(g,'LUCKY_EGG',3)and not M.supportsItem(g,'LUCKY_EGG',1),'equipment profile support')
check(M.supportsItem(g,'AMULET_COIN',2)and not M.supportsItem(g,'AMULET_COIN',1),'coin equipment profile support')
check(award(egg,100)==100,'no battle gives no bonus')
callbacks['battle.started']{battle=b}
check(award(egg,100)==150 and award(egg,1)==1,'held egg grants floored x1.5')
check(award(plain,100)==100,'unheld partner stays ordinary')
check(award({species='BLASTOISE',item='LUCKY_EGG'},100)==100,'foreign mon not rewarded')
egg.item=nil;check(award(egg,100)==100,'removed item stops bonus')
egg.item='LUCKY_EGG';b.kascGenerationRulesReceipt.activeEpoch=1
check(award(egg,100)==100,'Gen1 battle receipt rejects item')
b.kascGenerationRulesReceipt.activeEpoch=3;b.kascGenerationRulesReceipt.mode='OFF'
check(award(egg,100)==100,'frozen OFF receipt rejects item')
b.kascGenerationRulesReceipt.mode='GEN3';callbacks['battle.ended']{battle=b}
check(award(egg,100)==100,'end clears active battle')
check(M.bonus(21)==31,'fractional award floors')
local coin={species='PIDGEY',item='AMULET_COIN'}
local trainer={kind='trainer',game=g,kascGenerationRulesReceipt={mode='GEN3',activeEpoch=3},
  trainer={baseMoney=10,name='TEST'},enemy={mon={hp=0,level=5}},enemyParty={{hp=0}},
  player={mon=coin},sides={{}}}
g.save.party={coin,plain};g.save.money=0
local function nativePrize(b)
  b.game.save.money=b.game.save.money+b.trainer.baseMoney*b.enemy.mon.level
  b.result='win'
  return 'paid'
end
check(not M.coinEligible(trainer),'no participation before native start')
callbacks['battle.started']{battle=trainer}
check(M.coinEligible(trainer),'lead holder participates')
check(M.coinPrize(nativePrize,trainer)=='paid'and g.save.money==100,
  'native prize is doubled and credited once')
check(trainer.trainer.baseMoney==10 and not M.coinEligible(trainer),'trainer identity restored and settled')
callbacks['battle.ended']{battle=trainer}
trainer.result=nil;g.save.money=0
callbacks['battle.started']{battle=trainer}
local function existingHappyHour(b)
  local former=b.trainer;local bonus={}
  for k,v in pairs(former)do bonus[k]=v end
  bonus.baseMoney=former.baseMoney*2;b.trainer=bonus
  local result=nativePrize(b);b.trainer=former
  return result
end
check(M.coinPrize(existingHappyHour,trainer)=='paid'and g.save.money==200
  and trainer.trainer.baseMoney==10,'coin and existing doubled prize compose once each')
callbacks['battle.ended']{battle=trainer}
trainer.result=nil;g.save.money=0;trainer.player.mon=plain
callbacks['battle.started']{battle=trainer}
check(not M.coinEligible(trainer),'unheld lead gives no coin bonus')
trainer.player.mon=coin
callbacks['battle.battler_switched']{battle=trainer,side=trainer.sides[1],battler=trainer.player}
check(M.coinEligible(trainer),'switched-in holder participates')
trainer.result='lose'
check(not M.coinEligible(trainer),'loss cannot pay coin bonus')
callbacks['battle.ended']{battle=trainer}
trainer.result=nil;trainer.kascGenerationRulesReceipt.activeEpoch=1
callbacks['battle.started']{battle=trainer}
check(not M.coinEligible(trainer),'Gen1 trainer battle rejects coin')
callbacks['battle.ended']{battle=trainer}
print('PASS Sevii training items: '..checks..' checks')
