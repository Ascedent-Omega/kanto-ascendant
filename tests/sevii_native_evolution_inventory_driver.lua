-- Read-only inventory of registered Gen-III/IV evolution mechanisms.
return function(game)
  io.stdout:setvbuf('no')
  game:startNewGame{intro=false}
  local items={'DEEP_SEA_TOOTH','DEEP_SEA_SCALE','PRISM_SCALE','PROTECTOR',
    'MAGMARIZER','ELECTIRIZER','RAZOR_FANG','RAZOR_CLAW','DUBIOUS_DISC',
    'SHINY_STONE','DUSK_STONE','DAWN_STONE','REAPER_CLOTH','OVAL_STONE',
    'MAGNETIC_CORE','METAL_COAT','UP_GRADE','DRAGON_SCALE','KINGS_ROCK'}
  for _,id in ipairs(items)do
    local row=game.data.items[id]
    print('EVOLUTION_CATALOG',id,row and row.name or'-',row and row.price or'-',
      row and row.effect or'-',row and tostring(row.needsTarget)or'-',
      row and tostring(row.keyItem)or'-')
  end
  local K=game.mods.exports.kanto_ascendant
  for _,p in ipairs(K.hevoPackages.order)do
    if p.item then print('HEVO_ITEM',p.item,p.id,p.character)end
  end
  print('EVOLUTION_CATALOG_PASS')
  love.event.quit()
end
