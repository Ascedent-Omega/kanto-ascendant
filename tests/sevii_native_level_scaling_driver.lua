-- Real seven-harbor return rides before the story, plus live regional level
-- checks. Quest availability is a fixture only for the final Regirock fight.
return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'))
  local U=require('tests.drivers.util')
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=game.mods.exports.kanto_ascendant;local S=assert(K.seviiExpedition)
  local N=dofile(root..'/tests/sevii_journey_navigation.lua')(game,S,Q)
  require('src.world.OverworldController').rollEncounter=function()return nil end
  game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
  game.mods.modOptions.kanto_ascendant.living_world_enabled=false
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true
  game.save.flags.EVENT_GOT_STARTER=true
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',90)}
  assert(K.beyondKanto.activate(game,{decision='qa-sevii-scaling'}))
  U.teleport(game,'VERMILION_CITY',27,26,'left');Q.settle()
  assert(S.depart(game)and S.state().stage==0,'first arrival does not force story progress')
  Q.settle()
  N.sail(0)
  for island=2,7 do
    assert(S.depart(game),'reboarding from Kanto')
    Q.settle()
    N.sail(island)
    assert(S.state().stage==0,'island '..island..' remains pre-story')
    N.sail(0)
  end
  assert(N.sails==13 and game.overworld.map.id=='VERMILION_CITY',
    'all seven islands offer native return ferry before the first chapter')
  assert(S.scaling.legend(game,65)==65,'Kanto retains authored levels')
  assert(S.depart(game))
  Q.settle()
  S.persist({version=1,stage=3,chapterOneComplete=true,
    expeditionComplete=true,seviiRiftSealed=true,samples={heat=true,drift=true}})
  K.generationRules.resolve(game);S.install(game)
  local target=assert(S.habitats.bySpecies.WINGULL)
  U.teleport(game,target.pool.map,target.pool.anchor[1],target.pool.anchor[2],'down');Q.settle()
  local expectedWild=S.scaling.wild(game,target.row.level)
  assert(expectedWild>=80,'team reference raises ordinary Sevii wild level')
  local encounters=S.habitats.encounters(game,target.pool.map)
  local surface=target.pool.terrain=='water'and encounters.water or encounters.grass
  local found=false
  for _,slot in ipairs(surface.slots)do
    if slot.species=='WINGULL'and slot.level==expectedWild then found=true end
  end
  assert(found,'actual Sevii habitat slots use scaled levels')
  local trainer=assert(S.trainers.rows[1])
  U.teleport(game,trainer.map,trainer.x,trainer.y+1,'up');Q.settle()
  local team=assert(S.trainers.team(game,trainer))
  assert(team[1].level==S.scaling.trainer(game,trainer.level,false)
    and team[3].level==S.scaling.trainer(game,trainer.level+2,true),
    'native trainer roster keeps authored floor and scaled ace')
  local E=assert(S.specialEncounters)
  local row=assert(E.rows.REGIROCK)
  local species=assert(K.backendGiftSpecies67.byKey['dex:377'])
  U.teleport(game,row.site.map,row.site.x,row.site.y+1,'up');Q.settle()
  local original=E.availability
  E.availability=function(_,id)
    if id=='REGIROCK'then return true,species end
    return original(game,id)
  end
  local ok,battle=E.start(game,'REGIROCK')
  assert(ok and battle.enemy.mon.species==species
    and battle.enemy.mon.level==S.scaling.legend(game,row.level),
    'real legendary constructor uses Sevii team scaling')
  assert(battle.enemy.mon.level==92,'level-90 team meets level-92 Regirock')
  assert(K.hoennLegendPortals67.seviiLevel(game)==92,
    'character-bound weather legend uses the same Sevii rule')
  print('SEVII_NATIVE_LEVEL_SCALING_PASS',N.sails,'ferries',
    expectedWild,'wild',team[1].level,'trainer',battle.enemy.mon.level,'legend')
  love.event.quit()
end
