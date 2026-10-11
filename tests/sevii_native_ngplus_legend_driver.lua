-- A real Legacy handoff carries lifetime ownership without retiring the
-- new run's wild legendary encounters. No test Pokemon is gifted to a user.
return function(game)
  io.stdout:setvbuf('no')
  local K=assert(game.mods.exports.kanto_ascendant)
  local P=assert(K.seviiExpedition.legendPolicy)
  local H=assert(P.history)
  local A=assert(K.legacyJourney.archive)
  game:startNewGame{intro=false}
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',70)}
  local old=game.save
  old.modData=old.modData or{};old.modData.kanto_ascendant=old.modData.kanto_ascendant or{}
  old.modData.kanto_ascendant.hevo_persistent=
    old.modData.kanto_ascendant.hevo_persistent or{}
  local receipts={}
  for id,dex in pairs(H.ids)do receipts[tostring(dex)]=true end
  old.modData.kanto_ascendant.hevo_persistent[H.KEY]=receipts
  old.modData.kanto_ascendant.hevo_persistent.secretUnlocks={
    KA_LEGEND_CAPTURE_GROUDON=true,KA_LEGEND_CAPTURE_JIRACHI=true}
  assert(H.sync(game),'original history sync')
  assert(K.hoennLegendPortals67.caught(game,K.hoennLegendPortals67.rows.RED)
    and K.hoennJirachiFinale67.caught(game),
    'original Hoenn capture seals remain closed')
  for _,id in ipairs{'ARTICUNO','RAIKOU','REGIROCK','GROUDON','JIRACHI','HEATRAN'}do
    assert(H.owned(game,id)and H.ownedThisRun(game,id),'original run stays closed '..id)
  end
  local handoff,why=A.beginJourney(old,{pact='journey',bankPolicy='sealed',
    itemPolicy='empty',runRules=A.safeRunRulesSnapshot(old),playerAvatar='BLUE'})
  assert(handoff,'Legacy begin: '..tostring(why))
  -- Exercise the engine's save.new_game hook and save.created reset, not just
  -- the archive helper. The source save is still retained by Legacy.
  game:startNewGame{intro=false}
  local fresh=game.save
  assert(fresh.modData.kanto_ascendant.legacy_journey.runId,'new run identity')
  for id in pairs(H.ids)do
    assert(H.owned(game,id),'Legacy lost historical ownership '..id)
    assert(not H.ownedThisRun(game,id),'new run still counts an old catch '..id)
    assert(P.captureAllowed(game,id),'new run still blocks catch '..id)
  end
  local postgame=K.postgame.state()
  for _,id in ipairs{'ARTICUNO','ZAPDOS','MOLTRES','MEWTWO','RAIKOU',
      'ENTEI','SUICUNE','LUGIA','HO_OH','CELEBI'}do
    assert(not K.postgame.caught(postgame,fresh,id),
      'old static or roaming encounter remains suppressed in NG+ '..id)
  end
  K.postgame.syncPersistentObjects(game)
  for _,row in ipairs{{'SEAFOAM_ISLANDS_B4F','SEAFOAMISLANDSB4F_ARTICUNO'},
      {'POWER_PLANT','POWERPLANT_ZAPDOS'},
      {'CERULEAN_CAVE_B1F','CERULEANCAVEB1F_MEWTWO'}}do
    assert(fresh.objectToggles[row[1]][row[2]]==true,
      'static Kanto legend did not reappear in NG+ '..row[2])
  end
  for _,id in ipairs{'REGIROCK','REGICE','REGISTEEL'}do
    assert(not K.hoennResearchSanctums67.priorOwnership(game,{species=id}),
      'old Regi does not become a new-run capture '..id)
  end
  assert(not K.hoennLegendPortals67.priorOwnership(game,
    K.hoennLegendPortals67.rows.RED),'old Groudon does not consume new seal')
  assert(not K.hoennRoamers67.priorOwnership(game,'LATIAS'),
    'old roamer does not consume new roaming encounter')
  assert(not K.hoennJirachiFinale67.priorOwnership(game),
    'old Jirachi does not consume new wish encounter')
  assert(not K.hoennLegendPortals67.caught(game,K.hoennLegendPortals67.rows.RED)
    and not K.hoennJirachiFinale67.caught(game),
    'old capture seals do not suppress the new-run Hoenn encounters')
  local mon={species='REGIROCK'};fresh.party={mon}
  assert(H.record(game,mon)and H.ownedThisRun(game,'REGIROCK'),
    'captured Regirock closes this run')
  local can,why=P.captureAllowed(game,'REGIROCK')
  assert(not can and why=='legend_owned','second Regirock refused in same run')
  assert(not H.ownedThisRun(game,'REGICE'),'other guardian remains available')
  print('SEVII_NATIVE_NGPLUS_LEGENDS_PASS',#fresh.party)
  love.event.quit()
end
