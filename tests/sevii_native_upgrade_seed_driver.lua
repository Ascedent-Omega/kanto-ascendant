-- Runs exclusively against the unchanged pre-Sevii base commit.
return function(game)
  io.stdout:setvbuf('no')
  local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local K=game.mods.exports.kanto_ascendant;assert(not K.seviiExpedition,'seed must use original KASC')
  local U=require('tests.drivers.util');local Pokemon=require('src.pokemon.Pokemon')
  local character=os.getenv('SEVII_JOURNEY_CHARACTER')or'BLUE'
  game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
  K.extendedCharacters.select(character)
  game.mods.modOptions.kanto_ascendant.living_world_enabled=false
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  assert(K.beyondKanto.activate(game,{decision='qa-pre-sevii-expanded-save'}))
  local mon=Pokemon.new(game.data,'BLASTOISE',70)
  mon.nickname='ALTSTAND';mon.moves={{id='SURF',pp=15},{id='STRENGTH',pp=15},{id='ICE_BEAM',pp=10}}
  game.save.party={mon};game.save.money=41827
  game.save.inventory.SOULBADGE=true;game.save.inventory.RAINBOWBADGE=true
  game.save.inventory.MOOMOO_MILK=3;game.save.inventory.NET_BALL=2
  local moltres=Pokemon.new(game.data,'MOLTRES',50);moltres.nickname='EINMALIG'
  require('src.battle.BattleState').stampOT(game.save,mon)
  require('src.battle.BattleState').stampOT(game.save,moltres)
  game.save.boxes[1][#game.save.boxes[1]+1]=moltres
  game.save.pokedex.owned.BLASTOISE=true;game.save.pokedex.owned.MOLTRES=true
  assert(K.hoennEndgameRunEvents67.mark(game,'MOLTRES',{
    captured=true,battleResult='caught',map='KA_BLAINE_VOLCANO',level=50}))
  U.teleport(game,'VERMILION_CITY',27,26,'right');U.wait(120)
  assert(game:writeSave())
  game:restoreSave(assert(require('src.core.SaveData').load('red')));U.wait(120)
  local function snapshot()
    return {character=K.extendedCharacters.getPlayerCharacter(),party=game.save.party,
      boxes=game.save.boxes,money=game.save.money,inventory=game.save.inventory,
      events=game.save.kaHoennEndgameRunEvents67,owned=game.save.pokedex.owned}
  end
  local f=assert(io.open(out..'/upgrade-before.json','wb'))
  f:write(require('src.link.Json').encode(snapshot()));f:close()
  print('SEVII_OLD_BASE_SAVE_CREATED',character,#game.save.party,#game.save.boxes[1])
  love.event.quit()
end
