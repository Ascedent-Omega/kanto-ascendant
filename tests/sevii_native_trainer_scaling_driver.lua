-- Check the constructed native trainer battle, not only the authored roster.
return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'))
  local U=require('tests.drivers.util')
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  require('src.world.OverworldController').rollEncounter=function()return nil end
  game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
  game.mods.modOptions.kanto_ascendant.living_world_enabled=false
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true
  game.save.flags.EVENT_GOT_STARTER=true
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',90)}
  local K=game.mods.exports.kanto_ascendant
  assert(K.beyondKanto.activate(game,{decision='qa-sevii-trainer-scaling'}))
  U.teleport(game,'VERMILION_CITY',27,26,'left');Q.settle()
  local S=assert(K.seviiExpedition)
  assert(S.depart(game));Q.settle()
  local T=assert(S.trainers);local row=assert(T.rows[1])
  U.teleport(game,row.map,row.x,row.y+1,'up');Q.settle()
  local ok,battle=T.start(game,row.id)
  assert(ok and battle.kind=='trainer' and #battle.enemyParty==3,
    'native trainer battle starts with three opponents')
  local expected=assert(T.team(game,row))
  for i,mon in ipairs(battle.enemyParty)do
    assert(mon.species==expected[i].species and mon.level==expected[i].level,
      'battle slot '..i..' uses the Sevii-scaled level')
  end
  assert(battle.enemyParty[1].level==90 and battle.enemyParty[3].level==92,
    'level-90 team meets level-90 trainer and level-92 ace')
  print('SEVII_NATIVE_TRAINER_SCALING_PASS',battle.enemyParty[1].level,
    battle.enemyParty[3].level)
  love.event.quit()
end
