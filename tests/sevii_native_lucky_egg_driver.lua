return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'))
  local U=require('tests.drivers.util')
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local Save=require('src.core.SaveData')
  local K=game.mods.exports.kanto_ascendant
  game:restoreSave(assert(Save.load('red')))
  Q.settle()
  assert(K.pokemonEquipment67.heldId(game.save.party[1])=='LUCKY_EGG','tower save has Lucky Egg equipped')
  assert(K.seviiExpedition.state().towerComplete,'tower title persisted')
  local trainee=game.save.party[1]
  local equipment=K.pokemonEquipment67
  trainee=game.save.party[1]
  assert(equipment.heldId(trainee)=='LUCKY_EGG'and (game.save.inventory.LUCKY_EGG or 0)==0,
    'actual tower reward equipped, not copied')
  local Experience=require('src.battle.Experience')
  local base=Experience.gainFor(game.data.pokemon.MAGIKARP,5,false,1,false,game.data.constants)
  local before=trainee.exp
  local battle=require('src.battle.BattleState').newWild(game,'MAGIKARP',5,{randomizerProtected=true})
  battle.onFinish=function(result)game.overworld:afterBattle(result,battle)end
  battle.rng=function(lo)return lo end
  game.overworld:pushBattle(battle)
  for _=1,3000 do
    if game.stack:top()==game.overworld then break end
    Q.tap('a')
  end
  assert(game.stack:top()==game.overworld and battle.result=='win','native trainee wins actual wild battle')
  Q.settle()
  assert(trainee.exp-before==math.floor(base*1.5),'held Lucky Egg multiplies actual battle experience')
  assert(game:writeSave());game:restoreSave(assert(Save.load('red')));Q.settle()
  assert(equipment.heldId(game.save.party[1])=='LUCKY_EGG'and game.save.party[1].exp==trainee.exp,
    'held egg and gained experience survive reload')
  print('SEVII_NATIVE_LUCKY_EGG_PASS')
  love.event.quit()
end
