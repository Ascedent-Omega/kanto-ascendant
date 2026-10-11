-- Read-only compatibility audit: a 2v2 engine is not a valid KASC backend
-- merely because its menu can display four battlers.
return function(game)
  io.stdout:setvbuf('no')
  local G3=require('src.mods.Gen3Compat')
  local G3Pokemon=require('src.core.game3.pokemon')
  local speciesPackReady=type(G3Pokemon._names)=='table'
  print('SEVII_DOUBLE_RULE_SPECIES_PACK',speciesPackReady and 'ready' or 'not-loaded')
  local examples={
    moves={'THUNDERBOLT','FLASH_CANNON','AURA_SPHERE','DARK_PULSE'},
  }
  for _,key in ipairs(examples.moves)do
    print('SEVII_DOUBLE_RULE_MOVE',key,tostring(G3.moveId(key)))
  end
  local base=game.data.moves and game.data.moves.THUNDERBOLT
  local later=game.data.moves and game.data.moves.FLASH_CANNON
  assert(base and later,'KASC later-generation move data missing')
  assert(G3.moveId('FLASH_CANNON')==nil,
    'Game3 pack unexpectedly learned a later KASC move; review audit')
  print('SEVII_DOUBLE_RULE_AUDIT_RECORDED',
    'Game3 pack not active in KASC runtime; later move absent')
  love.event.quit()
end
