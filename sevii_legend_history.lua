-- Lifetime ownership for Sevii's Gen4 specials and migrated older owners.
-- Live save evidence is monotonic; Legacy transports it with HEVO metadata.
-- No Pokemon is removed, merged or rewritten by this history owner.
return function(mod,policy,opts)
  local H={KEY='seviiLegendOwned',ids={ARTICUNO=144,ZAPDOS=145,MOLTRES=146,MEWTWO=150,MEW=151,
    RAIKOU=243,ENTEI=244,SUICUNE=245,LUGIA=249,HO_OH=250,CELEBI=251,
    REGIROCK=377,REGICE=378,REGISTEEL=379,LATIAS=380,LATIOS=381,KYOGRE=382,GROUDON=383,RAYQUAZA=384,JIRACHI=385,DEOXYS=386,UXIE=480,MESPRIT=481,AZELF=482,DIALGA=483,
    PALKIA=484,HEATRAN=485,REGIGIGAS=486,CRESSELIA=488,PHIONE=489,MANAPHY=490,
    DARKRAI=491,SHAYMIN=492,ARCEUS=493}}
  local allowed={};for _,dex in pairs(H.ids)do allowed[tostring(dex)]=true end
  H.RUN_KEY='seviiLegendRun'
  function H.key(value)
    local dex=policy.dex(value)
    local id=type(value)=='table'and(value.eggSpecies or value.species)or value
    dex=dex or H.ids[id]
    local key=dex and tostring(dex);return allowed[key]and key or nil
  end
  local function bucket(save,create)
    if not save then return end
    if create then save.modData=save.modData or{};save.modData[mod.id]=save.modData[mod.id]or{}end
    local b=save.modData and save.modData[mod.id];if not b then return end
    if create then b.hevo_persistent=b.hevo_persistent or{}end
    local p=b.hevo_persistent;if not p then return end
    if create then p[H.KEY]=p[H.KEY]or{}end
    return p[H.KEY]
  end
  local function runId(save)
    local localMod=save and save.modData and save.modData[mod.id]
    local journey=localMod and localMod.legacy_journey
    if type(journey)=='table'and type(journey.runId)=='string'
        and journey.runId~=''then return journey.runId end
    return 'original'
  end
  function H.runId(game)return runId(game and game.save)end
  local function currentRun(save,create)
    if not save then return nil end
    if type(save.modData)~='table'then
      if not create or save.modData~=nil then return nil end
      save.modData={}
    end
    if type(save.modData[mod.id])~='table'then
      if not create or save.modData[mod.id]~=nil then return nil end
      save.modData[mod.id]={}
    end
    local localMod=save.modData[mod.id]
    local id=runId(save);local state=localMod[H.RUN_KEY]
    if type(state)~='table'or state.runId~=id then
      if not create then return nil end
      state={version=1,runId=id,caught={}}
      localMod[H.RUN_KEY]=state
    end
    if type(state.caught)~='table'then
      if not create then return nil end
      state.caught={}
    end
    return state
  end
  local function accept(set,value)
    local key=H.key(value);if key then set[key]=true end
  end
  local function merge(set,source)
    for key,yes in pairs(type(source)=='table'and source or{})do
      if yes==true and allowed[tostring(key)]then set[tostring(key)]=true end
    end
  end
  local function mons(set,rows)
    for _,row in pairs(type(rows)=='table'and rows or{})do
      if type(row)=='table'then accept(set,row.mon or row)end
    end
  end
  local function giftClaims(set,claims,archive)
    if not archive then return end
    for id,row in pairs(type(claims)=='table'and claims or{})do
      local profile=archive.profile(type(row)=='table'and row.profileId or id)
      if profile then accept(set,profile)end
    end
  end
  local function captureSeals(set,seals)
    for _,id in ipairs{'KYOGRE','GROUDON','RAYQUAZA','JIRACHI'}do
      if type(seals)=='table'and seals['KA_LEGEND_CAPTURE_'..id]==true then accept(set,id)end
    end
  end
  local function oldCatch(row,map)
    return type(row)=='table'and row.map==map and type(row.level)=='number'
      and row.level%1==0 and row.level>=1 and row.level<=100
      and(row.battleResult==nil or row.battleResult=='caught'and row.captured==true)
  end
  function H.collect(game)
    local save=game and game.save;if not save then return {},'save_unavailable'end
    local localState=bucket(save,false)
    if localState~=nil and type(localState)~='table'then return {},'local_history_unavailable'end
    local set={};merge(set,localState)
    for species,yes in pairs(save.pokedex and save.pokedex.owned or{})do if yes==true then accept(set,species)end end
    mons(set,save.party);mons(set,save.box)
    for _,box in pairs(save.boxes or{})do mons(set,box)end
    mons(set,save.orphaned and save.orphaned.mons)
    -- Pre-Sevii Rocket receipts remain evidence after a release or trade.
    -- Pending rescues, attempts and cleared bosses are not capture receipts.
    local localMod=save.modData and save.modData[mod.id]
    -- Old postgame catches were recorded per run. Adopt them before NG+
    -- resets that run ledger so a released bird or Johto legend is not
    -- offered again. Encounter wins and unlocked routes are not ownership.
    local postgame=localMod and localMod.postgame
    for id,yes in pairs(type(postgame)=='table'and type(postgame.catches)=='table'
        and postgame.catches or{})do
      if yes==true then accept(set,id)end
    end
    -- An old volcano KO is a route completion, never a capture witness.
    local run=save.kaHoennEndgameRunEvents67
    local moltres=type(run)=='table'and type(run.completed)=='table'and run.completed.MOLTRES
    if type(moltres)=='table'and moltres.captured==true then accept(set,'MOLTRES')end
    local volcano=localMod and localMod.hoenn_moltres_volcano_67
    local caught=type(volcano)=='table'and volcano.caught
    if type(caught)=='table'and caught.captured==true then accept(set,'MOLTRES')end
    local sanctums=localMod and localMod.hoenn_research_sanctums_67
    for _,id in ipairs{'REGIROCK','REGICE','REGISTEEL'}do
      local r=type(run)=='table'and type(run.completed)=='table'and run.completed[id]
      local old=type(sanctums)=='table'and type(sanctums.caught)=='table'and sanctums.caught[id]
      if type(r)=='table'and r.captured==true or type(old)=='table'and old.captured==true then accept(set,id)end
    end
    -- The original Eon owner records only successfully stored catches, or
    -- explicit adoption of an already-owned Dex entry. Roaming/recovery
    -- records and an empty placeholder are not evidence of ownership.
    local eon=localMod and localMod.hoenn_roamers_67
    for _,id in ipairs{'LATIAS','LATIOS'}do
      local receipt=type(eon)=='table'and type(eon.caught)=='table'and eon.caught[id]
      local level=type(receipt)=='table'and receipt.level
      if type(receipt)=='table'and(receipt.adopted==true
          or type(level)=='number'and level%1==0 and level>=1 and level<=100)then accept(set,id)end
    end
    local persistent=localMod and localMod.hevo_persistent
    captureSeals(set,type(persistent)=='table'and persistent.secretUnlocks)
    local birth=localMod and localMod.hoenn_birth_island_67
    local wish=localMod and localMod.hoenn_jirachi_finale_67
    if oldCatch(type(birth)=='table'and birth.caught,'KA_HOENN_BIRTH_ISLAND')then accept(set,'DEOXYS')end
    if oldCatch(type(wish)=='table'and wish.caught,'KA_HOENN_WISH_CHAMBER')then accept(set,'JIRACHI')end
    local deoxys=type(run)=='table'and type(run.completed)=='table'and run.completed.DEOXYS
    -- The old Deoxys writer recorded map/level only after a stored catch,
    -- while the event normalizer defaulted captured=false. New ceremonies
    -- explicitly say witnessed and must never be mistaken for that old form.
    if type(deoxys)=='table'and(deoxys.captured==true
        or oldCatch(deoxys,'KA_HOENN_BIRTH_ISLAND'))then accept(set,'DEOXYS')end
    for id,yes in pairs(type(persistent)=='table'and type(persistent.hoennDexOwned)=='table'and persistent.hoennDexOwned or{})do
      if yes==true then accept(set,id)end
    end
    local daycare=localMod and localMod.daycare_plus
    mons(set,type(daycare)=='table'and daycare.parents)
    -- These are eggs already produced/reserved by the Day-Care owner, unlike
    -- an unissued gift-code claim. Keep them claimable and count their species.
    mons(set,type(daycare)=='table'and daycare.reservedEggs)
    if save.daycare and type(save.daycare.mon)=='table'then accept(set,save.daycare.mon)end
    local raid=localMod and localMod.rocket_recovery_raids_67
    local receipts=type(raid)=='table'and raid.captureReceipts
    for key,species in pairs({darkrai_dream='DARKRAI',regigigas_power='REGIGIGAS'})do
      local receipt=type(receipts)=='table'and receipts[key]
      if type(receipt)=='table'and receipt.species==species then accept(set,species)end
    end
    local event=opts.eventArchive and opts.eventArchive()
    -- Read the event owner's normalized ledger only for this adopted save.
    if event and game.save==H.save then
      local s=event.state();giftClaims(set,s.claimed,event)
      giftClaims(set,s.giftCodes and s.giftCodes.claimed,event)
    end
    local archive=opts.journey and opts.journey.archive
    if not(archive and archive.seviiLegendView)then return set,'legacy_history_unavailable'end
    local ok,view,err=pcall(archive.seviiLegendView)
    if not ok or not view or err then return set,'legacy_history_unavailable'end
    merge(set,view.owned);mons(set,view.bank);mons(set,view.quarantine)
    captureSeals(set,view.secretUnlocks)
    for id,yes in pairs(type(view.hoennDexOwned)=='table'and view.hoennDexOwned or{})do
      if yes==true then accept(set,id)end
    end
    giftClaims(set,view.claimedGifts,event)
    local bridge=opts.bankBridge and opts.bankBridge()
    if not(bridge and bridge.load)then return set,'bank_history_unavailable'end
    local got,vault,why=pcall(bridge.load,game)
    if not got then return set,'bank_history_unavailable'end
    if vault then mons(set,vault.pokemon)
    elseif why~='vault_not_found'and not(why=='shared_storage_capability_missing'
        and view.bankAuthority=='legacy_archive')then return set,'bank_history_unavailable'end
    -- Older hosts explicitly retain the Legacy bank as their authority and
    -- cannot use a shared vault. Its already-read bank is sufficient there;
    -- never apply this fallback to a migrated shared-vault lineage or an I/O error.
    return set
  end
  function H.owned(game,value)
    local key=H.key(value);if not key then return false end
    local set,err=H.collect(game)
    return set[key]==true,err
  end
  local function seedCurrentRun(save,state)
    local localMod=save.modData and save.modData[mod.id]
    local postgame=localMod and localMod.postgame
    for id,yes in pairs(type(postgame)=='table'and type(postgame.catches)=='table'
        and postgame.catches or{})do
      if yes==true then accept(state.caught,id)end
    end
    local events=save.kaHoennEndgameRunEvents67
    for id,receipt in pairs(type(events)=='table'and type(events.completed)=='table'
        and events.completed or{})do
      if type(receipt)=='table'and receipt.captured==true then accept(state.caught,id)end
    end
    local roamers=localMod and localMod.hoenn_roamers_67
    for id,receipt in pairs(type(roamers)=='table'and type(roamers.caught)=='table'
        and roamers.caught or{})do
      if type(receipt)=='table'and(receipt.adopted==true
          or type(receipt.level)=='number')then accept(state.caught,id)end
    end
  end
  -- Lifetime evidence stays in `owned` for Legacy and gift continuity.
  -- Encounter eligibility uses only captures in this actual playthrough.
  function H.ownedThisRun(game,value)
    local key=H.key(value);if not key then return false end
    if not(game and game.save)then return false,'save_unavailable'end
    local lifetime,err=H.collect(game)
    local existing=currentRun(game.save,false)
    local state=existing or currentRun(game.save,true)
    if not state then return false,'run_history_unavailable'end
    if not existing then
      if state.runId=='original'then merge(state.caught,lifetime)
      else seedCurrentRun(game.save,state)end
    end
    return state.caught[key]==true
      or state.runId=='original'and lifetime[key]==true,err
  end
  function H.record(game,mon)
    local key=H.key(mon);if not key or not game or not game.save then return false end
    local stored=false
    for _,m in ipairs(game.save.party or{})do if m==mon then stored=true end end
    for _,box in ipairs(game.save.boxes or{})do for _,m in ipairs(box)do if m==mon then stored=true end end end
    for _,m in ipairs(game.save.orphaned and game.save.orphaned.mons or{})do if m==mon then stored=true end end
    if not stored then return false end
    local state=bucket(game.save,true)
    if type(state)~='table'then return false end
    state[key]=true
    local run=currentRun(game.save,true)
    if run then run.caught[key]=true end
    return true
  end
  function H.sync(game)
    if not(game and game.save)then return false end
    H.game,H.save=game,game.save
    local set,err=H.collect(game);local state=bucket(game.save,true)
    if type(state)~='table'then return false,'local_history_unavailable'end
    merge(state,set)
    -- Known witnesses are still retained if an external store is offline.
    -- Missing stores never become evidence that a legend is unowned.
    return err==nil,err
  end
  mod.events:on('pokemon.caught',function(ev)
    if ev then H.record(ev.game or ev.battle and ev.battle.game,ev.mon)end
  end,3885)
  for _,event in ipairs({'game.ready','save.loaded'})do
    mod.events:on(event,function(ev)if ev and ev.game then H.sync(ev.game)end end,3875)
  end
  mod.events:on('save.writing',function(ev)
    if ev and H.game and H.game.save==ev.save then H.sync(H.game)end
  end,3875)
  return H
end
