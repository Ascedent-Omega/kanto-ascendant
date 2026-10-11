-- Native KASC Card wiring: catch events, shiny roll preflight, run endings,
-- option toggle and save reload. Catch events are fixtures; engine capture is
-- covered separately by the Sevii native capture suite.
return function(game)
  io.stdout:setvbuf('no')
  local K=assert(game.mods.exports.kanto_ascendant)
  local Shiny=assert(K.shinySystem)
  local Runtime=require('src.mods.Runtime')
  local Pokemon=require('src.pokemon.Pokemon')
  game:startNewGame{intro=false}
  game.mods.modOptions.kanto_ascendant.living_world_enabled=false
  local function captured(species)
    Runtime.emit('pokemon.caught',{game=game,battle={kind='wild',game=game},
      mon=Pokemon.new(game.data,species,5),species=species})
  end
  local function roll(species)
    local ctx={mapId='ROUTE_1',rng=function()return 1 end}
    local out=Runtime.call('encounter.roll',function()return{species=species,level=5}end,
      {grass={rate=25,slots={{species=species,level=5,weight=1}}}},ctx)
    assert(out and out.species==species)
    local mon=Pokemon.new(game.data,species,5)
    local applied=Shiny.prepareSprite({mon=mon,side='front',kind='battle',
      species=species,data=game.data})
    return applied,Shiny.isShiny(mon)
  end
  local function bonusCalls(species)
    local calls=0
    local ctx={mapId='ROUTE_1',rng=function(_,high)
      calls=calls+1;return high end}
    Runtime.call('encounter.roll',function()return{species=species,level=5}end,
      {grass={rate=25,slots={{species=species,level=5,weight=1}}}},ctx)
    return calls
  end
  assert(Shiny.catchCombo().count==0,'fresh save has no combo')
  for _=1,10 do captured('PIKACHU')end
  assert(Shiny.catchCombo().species=='PIKACHU'and Shiny.catchCombo().count==10)
  assert(bonusCalls('PIKACHU')==0,'ten catches add no runtime rolls')
  assert(not roll('PIKACHU'),'ten catches have no combo bonus yet')
  captured('PIKACHU')
  assert(bonusCalls('PIKACHU')==1,'eleven catches add one runtime roll')
  local applied,shiny=roll('PIKACHU')
  assert(applied and shiny,'eleventh same-species catch grants a real shiny preflight')
  assert(not roll('EEVEE'),'different species cannot use the Pikachu bonus')
  for _=1,10 do captured('PIKACHU')end
  assert(bonusCalls('PIKACHU')==3,'twenty-one catches add three runtime rolls')
  for _=1,10 do captured('PIKACHU')end
  assert(bonusCalls('PIKACHU')==6,'thirty-one catches add six runtime rolls')
  game.mods.modOptions.kanto_ascendant.shiny_hunts='natural'
  assert(bonusCalls('PIKACHU')==0,'NATURAL ignores combo bonus')
  game.mods.modOptions.kanto_ascendant.shiny_hunts='ascendant'
  game.mods.modOptions.kanto_ascendant.shiny_catch_combo=false
  assert(bonusCalls('PIKACHU')==0,'disabled Card ignores existing combo')
  game.mods.modOptions.kanto_ascendant.shiny_catch_combo=true
  local BattleState=require('src.battle.BattleState')
  local retreat=setmetatable({kind='wild'},BattleState)
  assert(retreat:runRoll(100,50) and retreat.kaShinyComboPlayerRetreat,
    'successful player escape marks the real run path')
  Runtime.emit('battle.ended',{battle={kind='wild',game=game,player={},enemy={},
    kaShinyComboPlayerRetreat=true},result='run'})
  assert(Shiny.catchCombo().count==31,'player retreat preserves combo')
  Runtime.emit('battle.ended',{battle={kind='wild',game=game,player={},enemy={}},result='run'})
  assert(Shiny.catchCombo().count==0,'wild escape breaks combo')
  captured('PIKACHU');captured('EEVEE')
  assert(Shiny.catchCombo().species=='EEVEE'and Shiny.catchCombo().count==1,
    'different catch starts a new chain')
  game.mods.modOptions.kanto_ascendant.shiny_catch_combo=false
  captured('EEVEE')
  assert(Shiny.catchCombo().count==0,'Card off stops stacking')
  game.mods.modOptions.kanto_ascendant.shiny_catch_combo=true
  captured('PIKACHU')
  assert(game:writeSave())
  game:restoreSave(assert(require('src.core.SaveData').load('red')))
  assert(Shiny.catchCombo().species=='PIKACHU'and Shiny.catchCombo().count==1,
    'combo survives save reload')
  game:startNewGame{intro=false}
  assert(Shiny.catchCombo().count==0,'a new playthrough starts a fresh combo')
  print('KASC_NATIVE_SHINY_COMBO_PASS')
  love.event.quit()
end
