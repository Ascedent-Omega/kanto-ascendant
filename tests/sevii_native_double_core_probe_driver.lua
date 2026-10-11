-- Controlled native spike. It does not register a gameplay double battle.
return function(game)
  io.stdout:setvbuf('no')
  local Pokemon=require('src.pokemon.Pokemon')
  local BattleState=require('src.battle.BattleState')
  game:startNewGame{intro=false}
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true
  game.save.flags.EVENT_GOT_STARTER=true
  game.save.party={
    Pokemon.new(game.data,'RATICATE',50),
    Pokemon.new(game.data,'PIKACHU',50),
  }
  local battle=BattleState.newTrainer(game,'OPP_YOUNGSTER',1)
  assert(battle.player and battle.enemy)
  local partner=BattleState.makeBattler(game.data,game.save.party[2],true,game.save)
  local move
  for _,entry in ipairs(partner.curMoves or{})do
    if entry.pp>0 and game.data.moves[entry.id]
        and (game.data.moves[entry.id].power or 0)>0 then move=entry;break end
  end
  assert(move,'partner has no damaging attack')
  local before=battle.enemy.mon.hp
  local ok,err=pcall(function()battle:executeAction(partner,battle.enemy,move)end)
  print('SEVII_DOUBLE_CORE_PROBE',tostring(ok),tostring(err),move.id,
    before,battle.enemy.mon.hp)
  assert(ok,err)
  assert(battle.enemy.mon.hp<before,'partner move did not affect chosen enemy')
  print('SEVII_DOUBLE_CORE_PARTNER_ATTACK_PASS')
  local otherBattle=BattleState.newTrainer(game,'OPP_YOUNGSTER',1)
  local enemyPartnerMon=Pokemon.new(game.data,'RATICATE',50)
  local enemyPartner=BattleState.makeBattler(game.data,enemyPartnerMon,false)
  local leadHp=otherBattle.enemy.mon.hp
  local partnerHp=enemyPartner.mon.hp
  local targetOk,targetErr=pcall(function()
    otherBattle:executeAction(partner,enemyPartner,move)
  end)
  print('SEVII_DOUBLE_CORE_OFF_LEAD',tostring(targetOk),tostring(targetErr),
    leadHp,otherBattle.enemy.mon.hp,partnerHp,enemyPartner.mon.hp,
    tostring(otherBattle.result))
  assert(targetOk,targetErr)
  assert(enemyPartner.mon.hp<partnerHp,'off-lead target took no damage')
  assert(otherBattle.enemy.mon.hp==leadHp,'lead was damaged instead of target')
  assert(otherBattle.result==nil,'off-lead knockout ended the fight early')
  print('SEVII_DOUBLE_CORE_OFF_LEAD_ATTACK_PASS')
  local faintBattle=BattleState.newTrainer(game,'OPP_YOUNGSTER',1)
  local faintMon=Pokemon.new(game.data,'RATICATE',50)
  faintMon.hp=1
  local faintTarget=BattleState.makeBattler(game.data,faintMon,false)
  local faintOk,faintErr=pcall(function()
    faintBattle:executeAction(partner,faintTarget,move)
  end)
  print('SEVII_DOUBLE_CORE_OFF_LEAD_KO',tostring(faintOk),tostring(faintErr),
    tostring(faintBattle.result),tostring(faintTarget.mon.hp))
  assert(faintOk,faintErr)
  assert(faintTarget.mon.hp==0)
  assert(faintBattle.result==nil,'off-lead KO ended the fight while lead lives')
  print('SEVII_DOUBLE_CORE_OFF_LEAD_KO_PASS')
  love.event.quit()
end
