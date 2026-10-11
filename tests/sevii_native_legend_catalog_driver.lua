-- Read the live canonical catalog and existing authored legend owners.
-- Does not deliver gifts, invoke capture scripts or alter player archives.
return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition;local P=S.legendPolicy
  local Json=require('src.link.Json')
  local function read(path)local f=assert(io.open(path,'rb'));local v=Json.decode(f:read('*a'));f:close();return v end
  game:startNewGame{intro=false};game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  local H=P.history;local originalOwned,originalThisRun=H.owned,H.ownedThisRun
  H.owned=function()return false,'qa-archive-offline'end;H.ownedThisRun=H.owned
  for _,check in ipairs{
    function()return K.hoennRoamers67.priorOwnership(game,'LATIAS')end,
    function()return K.hoennResearchSanctums67.priorOwnership(game,K.hoennResearchSanctums67.rows[1])end,
    function()return K.hoennMoltresVolcano67.priorOwnership(game)end,
    function()return K.hoennLegendPortals67.priorOwnership(game,K.hoennLegendPortals67.rows.RED)end,
    function()return K.hoennBirthIsland67.priorOwnership(game)end,
    function()return K.hoennJirachiFinale67.priorOwnership(game)end,
  }do
    local owned,err=check();assert(not owned and err=='qa-archive-offline','all six original owners bound to the same canonical history authority')
  end
  H.owned,H.ownedThisRun=originalOwned,originalThisRun
  require('tests.drivers.util').teleport(game,S.harbors[1],8,5,'right')
  local sources={}
  for _,r in ipairs(K.hoennResearchSanctums67.rows)do sources[r.species]={
    owner='hoenn_research_sanctums_67.lua',map=r.map,history='canonical history and current-run ownership; separate kaHoennEndgameRunEvents67.completed per-run puzzle/capture/witness'}end
  local eonMaps={};for id in pairs(S.eonRoaming.maps)do eonMaps[#eonMaps+1]=id end;table.sort(eonMaps)
  local kantoCount=0;for _ in pairs(S.eonRoaming.kanto)do kantoCount=kantoCount+1 end
  assert(kantoCount==45,'complete base Kanto outdoor registry')
  local customKanto={};for id in pairs(S.eonRoaming.extraKanto)do customKanto[#customKanto+1]=id end;table.sort(customKanto)
  assert(#customKanto==1 and customKanto[1]=='KA_BLAINE_VOLCANO_FOOT',
    'unchanged authored Kanto outdoor registry')
  for _,id in ipairs(K.hoennRoamers67.order)do sources[id]={
    owner='hoenn_roamers_67.lua',expansion='sevii_eon_roaming.lua',maps=K.hoennRoamers67.routes,expandedMaps=eonMaps,
    kantoOutdoorMaps=kantoCount,customKantoOutdoorMaps=customKanto,
    access='Original Hoenn access; expansion after sealed Sevii finale. Persistent current location; 5 percent only in that area; caves and interiors excluded.',
    history='Canonical lifetime ownership including old hoenn_roamers_67.caught receipts and Legacy lineage; same original roaming identity.'}end
  for _,r in pairs(K.hoennLegendPortals67.rows)do sources[r.species]={
    owner='hoenn_legend_portals_67.lua',map=S.weatherTrio.sites[r.character].map,character=r.character,
    access='Sealed Sevii finale, character fissure-door visit and 130-species Hoenn foundation; old portal closed.',
    history='Canonical lifetime ownership including old '..r.flag..'; separate KA_LEGEND_WITNESS_'..r.species..' for research without a duplicate capture.'}end
  sources.JIRACHI={owner='hoenn_jirachi_finale_67.lua',map=K.hoennJirachiFinale67.MAP,
    access='Original 134 other Hoenn species, all three character paths and three weather research seals.',
    history='Canonical lifetime ownership including old capture seals/receipts; separate KA_LEGEND_WITNESS_JIRACHI allows certificate without another Pokemon.'}
  sources.DEOXYS={owner='hoenn_birth_island_67.lua',map=K.hoennBirthIsland67.MAP,
    access='Original Hoenn/three-path research plus current-run Moltres and Regirock completion and full triangle puzzle.',
    history='Canonical lifetime ownership including old stored-catch receipts; kaHoennEndgameRunEvents67.completed stays per-run with separate caught/witnessed result.'}
  sources.HEATRAN={owner='sevii_mysteries.lua',map=S.mysteries.sites.VENT.map,
    history='hevo_persistent.seviiLegendOwned: canonical Gen4 history and current-run ownership'}
  local additionalSources={}
  for id,row in pairs(S.specialEncounters.rows)do
    if sources[id]then additionalSources[id]={sources[id]}end
    sources[id]={owner=assert(row.owner),captureOwner='sevii_special_encounters.lua',map=row.site.map,
      history='hevo_persistent.seviiLegendOwned: canonical history and current-run ownership'}
  end
  assert(not S.threeHorizons and not S.specialEncounters.rows.GROUDON and not S.specialEncounters.rows.KYOGRE and not S.specialEncounters.rows.RAYQUAZA,'character portal owners retained')
  for id in pairs(S.sleepingGiant.guardians)do
    sources[id].access='Completed Tanoby balance quest AND Hoenn research eligibility. Original sanctuaries remain closed; current-run canonical ownership prevents duplicate acquisition.'
  end
  local formerSources={}
  for _,row in ipairs(K.rocketRecoveryRaids67Data.contraband)do
    local source={owner='rocket_recovery_raids_67.lua',runtimeOwner='rocket_recovery_raids_67_runtime.lua',
      lead=row.key,instance=row.instance,history='captureReceipts plus canonical Gen4 history and current-run ownership'}
    if sources[row.species]then
      source.status='retired after authored Sevii relocation';formerSources[row.species]={source}
    else sources[row.species]=source end
  end
  local rows={};local gen4Owners=0;local hoennOwners=0
  for _,target in ipairs(read(root..'/SEVII_SPECIES_REQUIREMENTS.json').special)do
    local species=assert(K.backendGiftSpecies67.byKey[target.key],target.id..' canonical identity')
    assert(P.dex(species)==target.dex,'canonical legend resolves '..target.id)
    local allowed,why=P.captureAllowed(game,species)
    assert(not allowed and why=='sevii_legendary_source','ordinary Sevii legend source excluded '..target.id..': '..tostring(why))
    local assets=S.habitats.assetPaths(species,game.data.pokemon[species]);local missing={}
    for _,path in ipairs(assets)do if not love.filesystem.getInfo('mods/kanto_ascendant/'..path)then missing[#missing+1]=path end end
    if target.dex>=480 then
      assert(sources[target.id]and sources[target.id].owner:match('^sevii_'),'missing Gen4 island owner '..target.id)
      assert(#missing==0,'missing Gen4 island art '..target.id)
      gen4Owners=gen4Owners+1
    end
    if target.dex==380 or target.dex==381 then assert(#missing==0,'Eon assets ready '..target.id)end
    if target.dex>=377 and target.dex<=379 then
      assert(sources[target.id].owner=='sevii_sleeping_giant.lua'and #missing==0,'Sevii guardian source/art '..target.id)
      hoennOwners=hoennOwners+1
    end
    local profiles,forms={},{}
    for key,r in pairs(K.backendNationalCatalog67.entries)do
      if r.nationalDex==target.dex then forms[#forms+1]=key end
    end
    table.sort(forms)
    for _,campaign in ipairs(K.giftCodeCatalog.campaigns)do
      for _,event in ipairs(campaign.events)do
        local p=K.eventArchive.profile(event.profileId)
        if P.dex(p)==target.dex then profiles[#profiles+1]={profile=event.profileId,
          campaign=campaign.id,status=campaign.status,key=p.backendKey}
        end
      end
    end
    rows[#rows+1]={id=target.id,dex=target.dex,runtime=species,forms=forms,requiredAssets=assets,missingAssets=missing,
      authoredCatchOwner=sources[target.id]or false,formerCatchOwners=formerSources[target.id],additionalCatchOwners=additionalSources[target.id],giftProfiles=profiles,
      seviiCaptureBlocked=true,scope=sources[target.id]and'Known authored catch owner plus catalogued gifts; ordinary island source remains blocked'
        or'No authored field-capture owner found in reviewed Hoenn/Sevii/Rocket modules; catalogued gift profiles are not proof of a publicly obtainable code'}
  end
  assert(#rows==23 and gen4Owners==13 and hoennOwners==3)
  -- Explicitly demonstrate the observed reset behavior on detached data.
  -- This is evidence for the migration decision, not a change to that rule.
  local detached={};local E=K.hoennEndgameRunEvents67
  assert(E.mark(detached,'MOLTRES',{captured=true,battleResult='caught'}))
  assert(E.completed(detached,'MOLTRES'));E.reset(detached);assert(not E.completed(detached,'MOLTRES'))
  local f=assert(io.open(out..'/legend-source-audit.json','wb'))
  f:write(Json.encode({passed=true,rows=rows,perRunResetObserved=true,gen4SeviiOwners=gen4Owners,hoennSeviiOwners=hoennOwners,eonSeviiExtensions=2,originalHistoryOwnersBound=6,
    scope='Live canonical identities, forms, catalogued gift profiles, authored Hoenn/Sevii/Rocket owners and current art paths. All 23 excluded from ordinary Sevii capture. Registry/art inspection is not a substitute for native quest/capture proofs or global older-legend uniqueness.'}));f:close()
  print('SEVII_LEGEND_SOURCE_AUDIT_PASS',#rows,'identities; live owners, forms and gift profiles; detached per-run reset observed')
  love.event.quit()
end
