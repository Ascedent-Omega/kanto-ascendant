-- Isolated native continuity audit for Kanto/Johto legends that predate Sevii.
return function(game)
  io.stdout:setvbuf('no')
  local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local K=assert(game.mods.exports.kanto_ascendant)
  local P=assert(K.seviiExpedition.legendPolicy)
  local H=assert(P.history)
  local A=assert(K.eventArchive)
  local L=assert(K.legacyJourney.archive)
  local Json=require('src.link.Json')
  game:startNewGame{intro=false}
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',70)}
  assert(H.sync(game))

  local bird=assert(A.profile('event_articuno'))
  assert(A.acquisitionAllowed(game,bird),'first old bird gift remains possible')
  local receipt={version=1,digest=string.rep('b',64),campaignId='sevii-old-legend-qa',
    buildId='isolated-qa',eventId='old-articuno',profileId=bird.id}
  local delivered=assert(A.deliverGift(game,bird.id,'OLD LEGEND QA',receipt,{boxOnly=true}))
  assert(delivered.species=='ARTICUNO'and H.owned(game,'ARTICUNO'))
  assert(not P.captureAllowed(game,'ARTICUNO'))
  assert(K.postgame.caught(K.postgame.state(),game.save,'ARTICUNO'))
  local removed=false
  for _,box in ipairs(game.save.boxes)do for i=#box,1,-1 do
    if box[i]==delivered then table.remove(box,i);removed=true;break end
  end end
  assert(removed,'QA gift was actually placed in a PC box')
  assert(game:writeSave())
  game:restoreSave(assert(require('src.core.SaveData').load('red')))
  assert(H.owned(game,'ARTICUNO'),'released old gift retained after load')
  assert(not A.acquisitionAllowed(game,bird),'old gift cannot issue a second bird')
  game.mods.modOptions.kanto_ascendant.legend_articuno='vanilla'
  K.postgame.syncPersistentObjects(game)
  assert(game.save.objectToggles.SEAFOAM_ISLANDS_B4F.SEAFOAMISLANDSB4F_ARTICUNO==false,
    'vanilla static bird must stay hidden after old ownership')

  local old={'ZAPDOS','MEWTWO','RAIKOU','ENTEI','SUICUNE','LUGIA','HO_OH','CELEBI'}
  local s=K.postgame.state()
  for _,id in ipairs(old)do s.catches[id]=true end
  assert(H.sync(game),'old run catches must migrate')
  for _,id in ipairs(old)do s.catches[id]=nil end
  for _,id in ipairs(old)do
    assert(H.owned(game,id),'missing permanent ownership '..id)
    assert(K.postgame.caught(s,game.save,id),'postgame would respawn '..id)
    local allowed,why=P.captureAllowed(game,id)
    assert(not allowed and why=='legend_owned','repeat capture allowed '..id)
  end
  local mewtwo=assert(A.profile('event_mewtwo'))
  local allowed,why=A.acquisitionAllowed(game,mewtwo)
  assert(not allowed and why=='legend_owned','alternate Mewtwo gift must be refused')
  assert(game:writeSave())
  game:restoreSave(assert(require('src.core.SaveData').load('red')))
  for _,id in ipairs(old)do assert(H.owned(game,id),'old catch lost after load '..id)end
  assert(K.beyondKanto.activate(game,{decision='qa-old-legend-catalog'}))
  local profile=K.legacyJourney.profile
  K.legacyJourney.profile=function()
    return {completedPaths={red=true,blue=true,green=true}}
  end
  local listed={}
  for _,row in ipairs(K.legacyStarters.rows(game,'free'))do listed[row.id]=true end
  K.legacyJourney.profile=profile
  assert(listed.MOLTRES,'unowned capstone remains in the eligible catalogue')
  assert(not listed.ARTICUNO,'owned gift bird must leave the NG+ catalogue')
  for _,id in ipairs(old)do assert(not listed[id],'owned old catch in NG+ catalogue '..id)end

  local state,err=L.beginJourney(game.save,{pact='journey',bankPolicy='sealed',itemPolicy='empty',
    runRules=L.safeRunRulesSnapshot(game.save),playerAvatar='BLUE'})
  assert(state,'Legacy transaction: '..tostring(err))
  local fresh={party={},boxes={},flags={},modData={}}
  local seeded,seedErr=L.seedNewSave(fresh)
  assert(seeded,'Legacy seed: '..tostring(seedErr))
  local history=fresh.modData.kanto_ascendant.hevo_persistent[H.KEY]
  for _,id in ipairs(old)do assert(history[tostring(H.ids[id])],'NG+ lost '..id)end
  assert(history['144'],'NG+ lost Articuno gift')
  fresh.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true
  fresh.player={name='QA',id=4242}
  fresh.pokedex={seen={},owned={}}
  fresh.modData.kanto_ascendant.legacy_journey.rivalBallTaken=true
  local current=game.save
  game.save=fresh
  K.legacyJourney.profile=function()
    return {completedPaths={red=true,blue=true,green=true}}
  end
  local chosen,choiceWhy=K.legacyStarters.choose(game,'ARTICUNO','free','catalog','catalog')
  assert(not chosen and choiceWhy=='legend_owned','direct NG+ partner selection repeated an owned bird: '..tostring(choiceWhy))
  local oldWrite=game.writeSave
  game.writeSave=function(self)
    assert(H.sync(self),'simulate save.writing after temporary partner allocation')
    return false
  end
  local issued,issueWhy=K.legacyStarters.choose(game,'MOLTRES','free','catalog','catalog')
  game.writeSave=oldWrite
  K.legacyJourney.profile=profile
  assert(not issued and issueWhy=='save failed','capstone failure did not reach save: '..tostring(issueWhy))
  assert(not H.owned(game,'MOLTRES'),'failed partner save reserved unissued Moltres')
  game.save=current
  local f=assert(io.open(out..'/old-legends.json','wb'))
  f:write(Json.encode({passed=true,giftSpecies='ARTICUNO',migratedOldRunCatches=old,
    releaseLoad=true,postgameSuppressed=true,vanillaObjectSuppressed=true,repeatCaptureSuppressed=true,
    alternateGiftSuppressed=true,legacyCatalogueFiltered=true,legacyDirectChoiceBlocked=true,
    failedPartnerSaveReleasesHistory=true,legacySeeded=true,
    scope='Native gift delivery, save/reload and Legacy transaction. Old postgame catches and release are isolated QA fixtures; no claim of a full old-game hunt or NG+ menu traversal.'}))
  f:close()
  print('SEVII_OLD_LEGENDS_PASS',#old+1)
  love.event.quit()
end
