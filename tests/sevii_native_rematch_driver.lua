-- Two real trainer battles verify the island rematch lifecycle and its
-- bridge into KASC's ordinary bonus-reward controllers.
return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'))
  local U=require('tests.drivers.util')
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=game.mods.exports.kanto_ascendant
  local S=K.seviiExpedition
  local T=S.trainers
  local Pokemon=require('src.pokemon.Pokemon')
  require('src.world.OverworldController').rollEncounter=function()return nil end
  game:startNewGame{intro=false}
  game.save.options.colors='redpp';game:applyOptions()
  game.mods.modOptions.kanto_ascendant.living_world_enabled=false
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true
  game.save.flags.EVENT_GOT_STARTER=true
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  local mon=Pokemon.new(game.data,'MEWTWO',75)
  mon.moves={{id='ICE_BEAM',pp=40}}
  game.save.party={mon}
  S.persist({version=1,stage=3,chapterOneComplete=true,
    samples={heat=true,drift=true}})
  K.generationRules.resolve(game)
  S.install(game)
  local row;for _,candidate in ipairs(T.rows)do if not candidate.doubleArena and not candidate.requiredId then row=candidate;break end end
  assert(row,'single trainer for the one-mon rematch fixture')
  local function fight()
    U.teleport(game,row.map,row.x,row.y+1,'up');Q.settle()
    local started,battle=T.start(game,row.id)
    assert(started and battle and #battle.enemyParty==3,'native Sevii battle')
    local first=battle.enemyParty[1].level
    for _,enemy in ipairs(battle.enemyParty)do enemy.hp=1 end
    battle.enemy.shownHP=1
    battle.rng=function(a)return a or 0 end
    for _=1,12000 do
      if game.stack:top()==game.overworld then break end
      local top=game.stack:top()
      if top.labels and top.onChoose then Q.tap('b')else Q.tap('a')end
    end
    assert(game.stack:top()==game.overworld and battle.result=='win',
      'native battle ends in victory')
    Q.settle()
    return first,battle
  end
  local original=fight()
  local record=T.record(row.id)
  assert(record.won and record.rematches==nil and record.claimed,
    'first victory awards the unique island prize')
  local qty=game.save.inventory[row.reward]
  assert(record.readyAt>K.trainerStepClock() and T.remaining(row.id)>0,
    'configured rest starts after first fight')
  local ready=S.state();ready.trainers[row.id].readyAt=K.trainerStepClock()
  S.persist(ready)
  local nextLevel=assert(T.team(game,row))[1].level
  assert(nextLevel==math.min(100,original+2),'rematch level follows KASC level gain')
  local rematch,battle=fight()
  assert(battle.rematch and rematch==nextLevel and battle.rematchNumber==1,
    'native rematch metadata and enemy level')
  record=T.record(row.id)
  assert(record.rematches==1 and record.readyAt>K.trainerStepClock(),
    'victory advances rematch tier and schedules another break')
  assert(game.save.inventory[row.reward]==qty,'unique prize is not duplicated')
  print('SEVII_NATIVE_REMATCH_PASS',original,rematch,record.rematches)
  love.event.quit()
end
