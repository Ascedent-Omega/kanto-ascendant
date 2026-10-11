-- Read-only compatibility/offspring probe on detached parents. This never
-- deposits Pokemon, generates an egg, claims a receipt or modifies player data.
return function(game)
 io.stdout:setvbuf('no')
 local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
 local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition;local D=K.daycare
 game:startNewGame{intro=false};game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
 game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',70)}
 assert(K.beyondKanto.activate(game,{decision='qa-legend-breeding-source-audit'}))
 S.persist({stage=3,chapterOneComplete=true,expeditionComplete=true,seviiRiftSealed=true,samples={heat=true,drift=true}})
 K.generationRules.resolve(game)
 assert(K.generationRules.switchMode(game,'gen4'))
 local Json=require('src.link.Json');local f=assert(io.open(root..'/SEVII_SPECIES_REQUIREMENTS.json','rb'))
 local requirements=Json.decode(f:read('*a'));f:close()
 requirements.special[#requirements.special+1]={id='GIRATINA',dex=487,key='dex:487'}
 local results={};local potential=0
 for _,r in ipairs(requirements.special)do
  local id=assert(K.backendGiftSpecies67.byKey[r.key]);local mon={species=id,otId=101,dvs={attack=8,defense=3,speed=9,special=5}}
  local ditto={species='DITTO',otId=202,dvs={attack=7,defense=7,speed=4,special=6}}
  local compatible,value=D.compatible(game,mon,ditto)
  local offspring=compatible and D.eggSpecies(game,mon,ditto,function()return 0 end)or nil
  if r.dex>=480 then assert(not compatible and D.eggSpecies(game,mon,ditto)==nil,'special cannot generate offspring '..r.id)end
  if compatible and offspring then potential=potential+1 end
  results[#results+1]={id=r.id,dex=r.dex,runtime=id,compatible=compatible==true,compatibility=value,offspring=offspring}
  print('SEVII_LEGEND_BREEDING_PROBE',r.id,tostring(compatible),tostring(offspring))
 end
 assert(potential==0,'no surveyed special can breed')
 local ordinary=D.compatible(game,{species='MAGIKARP',otId=101,dvs={defense=3,special=5}},{species='DITTO',otId=202,dvs={defense=7,special=6}})
 assert(ordinary,'ordinary breeding remains enabled')
 local f=assert(io.open(out..'/legend-breeding-audit.json','wb'))
 f:write(Json.encode({passed=true,rows=results,potentialOffspring=potential,ordinaryCompatible=ordinary,
  scope='Isolated Gen4/Beyond-Kanto QA. Read-only Day-Care compatible/eggSpecies on detached species-plus-Ditto records with differing DVs and OTs. Positive compatibility is an unguarded acquisition lead, not a proof of generated/delivered eggs or a full breeding UI test.'}));f:close()
 print('SEVII_LEGEND_BREEDING_AUDIT_PASS',#results,potential);love.event.quit()
end
