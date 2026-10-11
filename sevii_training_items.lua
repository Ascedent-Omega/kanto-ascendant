-- Post-League training rewards with native battle effects. The equipment
-- menu owns held-item transactions; the battle owns experience awards.
return function(mod,opts)
  local M={OWNER='kasc.sevii-training-items/v1',LUCKY_EGG='LUCKY_EGG',AMULET_COIN='AMULET_COIN'}
  for _,id in ipairs({M.LUCKY_EGG,M.AMULET_COIN})do
    local old=mod.content.items:get(id)
    if old then mod.content.items:patch(id,{kascSeviiTrainingItem=M.OWNER})end
  end
  local activeBattle
  local coinParticipants=setmetatable({},{__mode='k'})
  local coinPaid=setmetatable({},{__mode='k'})
  local function pack(...)return{n=select('#',...),...}end
  function M.supportsItem(game,id,epoch)
    local p=game and opts.rules.peek(game)
    local def=game and game.data and game.data.items and game.data.items[id]
    return (id==M.LUCKY_EGG or id==M.AMULET_COIN)
      and def and def.kascSeviiTrainingItem==M.OWNER
      and p and p.extensionsEnabled and (tonumber(epoch)or 1)>=2 or false
  end
  function M.held(mon,battle,id)
    if type(mon)~='table'then return false end
    id=id or M.LUCKY_EGG
    local equipment=mod.exports and mod.exports.pokemonEquipment67
    if equipment and equipment.battleHeldId then
      return equipment.battleHeldId(mon,battle)==id
    end
    local a,c=mon.item,mon.heldItem
    if a and c and a~=c then return false end
    return a==id or c==id
  end
  local function battleReady(b)
    if not(b and b.game and not b.demo and(b.kind=='wild'or b.kind=='trainer'))then return false end
    local p=b.kascGenerationRulesReceipt or opts.rules.peek(b.game)
    return p and (p.mode==nil or p.mode~=opts.rules.MODE_OFF)
      and p.extensionsEnabled~=false and (tonumber(p.activeEpoch)or 1)>=2 or false
  end
  function M.bonus(gained)
    return math.floor(math.max(0,tonumber(gained)or 0)*1.5)
  end
  function M.eligible(ctx)
    local b=activeBattle;local mon=ctx and ctx.mon
    if not battleReady(b)or type(mon)~='table'or not M.held(mon,b)then return false end
    for _,owned in ipairs(b.game.save and b.game.save.party or{})do
      if owned==mon then return true end
    end
    return false
  end
  mod.events:on('battle.started',function(ev)
    local b=ev and ev.battle
    if b and not b.demo then
      activeBattle=b
      if battleReady(b)and b.kind=='trainer'and b.player
        and M.held(b.player.mon,b,M.AMULET_COIN)then coinParticipants[b]=true end
    end
  end)
  mod.events:on('battle.battler_switched',function(ev)
    local b=ev and ev.battle
    if battleReady(b)and b.kind=='trainer'and ev.side==b.sides[1]
      and ev.battler and M.held(ev.battler.mon,b,M.AMULET_COIN)then coinParticipants[b]=true end
  end)
  mod.events:on('battle.ended',function(ev)
    if ev then
      if ev.battle==activeBattle then activeBattle=nil end
      coinParticipants[ev.battle]=nil;coinPaid[ev.battle]=nil
    end
  end)
  mod.hooks:wrap('exp.gain',function(nextGain,ctx)
    local gained=nextGain(ctx)
    if M.eligible(ctx)then return M.bonus(gained)end
    return gained
  end,500)
  function M.coinEligible(b)
    if not battleReady(b)or b.kind~='trainer'or not coinParticipants[b]
      or coinPaid[b]or b.result or not(b.trainer and b.enemy and b.enemy.mon)
      or b.enemy.mon.hp>0 then return false end
    local base=tonumber(b.trainer.baseMoney)
    if not base or base<=0 or base%1~=0 then return false end
    for _,mon in ipairs(b.enemyParty or{})do if mon.hp>0 then return false end end
    return true
  end
  function M.coinPrize(original,b,...)
    if not M.coinEligible(b)then return original(b,...)end
    local previous=b.trainer
    local overlay={}
    for k,v in pairs(previous)do overlay[k]=v end
    overlay.baseMoney=previous.baseMoney*2
    b.trainer=overlay
    local result=pack(pcall(original,b,...))
    b.trainer=previous
    if result[1]and b.result=='win'then coinPaid[b]=true end
    if not result[1]then error(result[2],0)end
    return unpack(result,2,result.n)
  end
  function M.install()
    local B=opts.battleState or require('src.battle.BattleState')
    B._kascSeviiTrainingItems=M
    if not B._kascSeviiTrainingItemsWrapped then
      local original=B.enemyMonFainted
      B.enemyMonFainted=function(...)return B._kascSeviiTrainingItems.coinPrize(original,...)end
      B._kascSeviiTrainingItemsWrapped=true
    end
  end
  return M
end
