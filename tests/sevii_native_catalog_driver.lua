-- Native registry/art/generation audit, isolated test profile only.
return function(game)
  io.stdout:setvbuf('no')
  local U=require('tests.drivers.util')
  local K=assert(game.mods.exports.kanto_ascendant)
  local S=assert(K.seviiExpedition)
  local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  game:startNewGame{intro=false}
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true
  game.save.flags.EVENT_GOT_STARTER=true
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',65)}
  assert(S.begin(game),'expedition start')
  local first=K.generationRules.resolve(game)
  assert(first.activeEpoch>=3,'Sevii introduction must unlock Hoenn without owned Hoenn Pokemon')
  for _,id in ipairs{'drift','heat'}do
    local sample=S.samples[id]
    U.teleport(game,sample.map,sample.x,sample.y-1,'down')
    assert(S.collect(game,id))
  end
  assert(S.report())
  local profile=K.generationRules.resolve(game)
  assert(profile.activeEpoch>=4,'completed investigation must unlock Sinnoh in AUTO')
  S.install(game)
  local E=S.habitats
  assert(E.coverage(game).available==0,'sealed Kanto profile excludes all Sevii wild species')
  assert(K.beyondKanto.activate(game,{decision='qa-expanded-postleague-fixture'}))
  S.install(game)
  local result={coverage=E.coverage(game),profile=profile,rows={}}
  for id,target in pairs(E.bySpecies)do
    local species,def=E.resolve(game,target.row)
    local paths=species and E.assetPaths(species,def)or{}
    local row={id=id,dex=target.row.dex,runtime=species,paths=paths,map=target.pool.map,
      terrain=target.pool.terrain,anchor=target.pool.anchor}
    if species then
      local mon=require('src.pokemon.Pokemon').new(game.data,species,target.row.level)
      assert(mon.species==species and #mon.moves>0,'native species construction '..id)
      row.moves=mon.moves
    end
    result.rows[#result.rows+1]=row
  end
  table.sort(result.rows,function(a,b)return a.dex<b.dex end)
  local file=assert(io.open(out..'/catalog-live.json','wb'))
  file:write(require('src.link.Json').encode(result));file:close()
  assert(result.coverage.available==218,'native catalogue must have every ordinary island species')
  U.wait(30)
  assert(K.generationRules.switchMode(game,'gen1'))
  S.install(game);assert(E.coverage(game).available==0,'explicit Gen1 selection preserved')
  assert(K.generationRules.switchMode(game,'gen3'))
  S.install(game);assert(E.coverage(game).available==125,'explicit Gen3 selection preserved')
  assert(K.generationRules.switchMode(game,'auto'))
  S.install(game);assert(E.coverage(game).available==218,'AUTO restores island coverage')
  print('SEVII_NATIVE_CATALOG',result.coverage.available,'/',result.coverage.required,'epoch',profile.activeEpoch)
  for _,row in ipairs(result.coverage.missing)do print('SEVII_MISSING',row.id,row.reason)end
  love.event.quit()
end
