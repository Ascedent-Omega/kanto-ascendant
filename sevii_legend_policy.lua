-- Only an authored, live special encounter may offer a Sevii legend.
-- Giratina remains a recurring story actor, never a capture.
return function(mod,S,opts)
  local P={OWNER='kasc.sevii-legend-policy/v1'}
  local legends={}
  for _,dex in ipairs({144,145,146,150,151,243,244,245,249,250,251,
      377,378,379,380,381,382,383,384,385,386,
      480,481,482,483,484,485,486,487,488,489,490,491,492,493})do legends[dex]=true end
  function P.dex(value)
    local key=type(value)=='table'and value.backendKey or nil
    local id=type(value)=='table'and value.species or value
    local owner=opts.backendSpecies and opts.backendSpecies()
    key=key or owner and owner.bySpecies[id]
    local catalog=type(opts.nationalCatalog)=='function'and opts.nationalCatalog()or opts.nationalCatalog
    local row=key and catalog and catalog.entries[key]
    if row then return row.nationalDex end
    if id=='GIRATINA'then return 487 end
    return key and tonumber(key:match('^dex:(%d+)$'))or nil
  end
  function P.acquisitionAllowed(game,profile)
    if P.dex(profile)==487 then return false,'story_reserved'end
    if P.history and P.history.key(profile)then
      local owned,err=P.history.owned(game,profile)
      if owned then return false,'legend_owned'end
      if err then return false,'legend_history_unavailable'end
    end
    return true
  end
  function P.captureAllowed(game,species,battle)
    local dex=P.dex(species)
    if dex==487 then return false,'story_reserved'end
    if P.history and P.history.key(species)then
      local owned,err=(P.history.ownedThisRun or P.history.owned)(game,species)
      if owned then return false,'legend_owned'end
      if err then return false,'legend_history_unavailable'end
    end
    local ow=game and game.overworld;local map=ow and ow.map and ow.map.id
    if S.maps[map]and legends[dex]then
      if S.mysteries and S.mysteries.canCapture(game,battle,species)then return true end
      if S.specialEncounters and S.specialEncounters.canCapture(game,battle,species)then return true end
      if S.eonRoaming and S.eonRoaming.canCapture(game,battle,species)then return true end
      if S.weatherTrio and S.weatherTrio.canCapture(game,battle,species)then return true end
      return false,'sevii_legendary_source'
    end
    return true
  end
  function P.raidCaptureAllowed(game,row)
    local dex=P.dex(row.species)
    -- Once an authored island quest owns this species, the former Rocket
    -- lead is retired. The raid owner advances its campaign without a catch.
    for _,encounter in pairs(S.specialEncounters and S.specialEncounters.rows or{})do
      if encounter.dex==dex then return false,'sevii_relocated'end
    end
    if P.history and P.history.key(row)then
      local owned,err=(P.history.ownedThisRun or P.history.owned)(game,row)
      if owned then return false,'legend_owned'end
      if err then return false,'legend_history_unavailable'end
    end
    return true
  end
  function P.newOffspringAllowed(game,species)
    -- Authored single-acquisition specials cannot be duplicated in Day Care.
    -- Previously produced eggs, including ones awaiting pickup, are retained.
    return P.dex(species)~=487 and not(P.history and P.history.key(species))
  end
  function P.ballUse(original,data,save,id,target,battle,...)
    local def=data and data.items and data.items[id]
    local Items=require('src.inventory.ItemEffects')
    local ball=def and def.ball or Items.isBall and Items.isBall(id)
    if ball and battle and battle.kind=='wild'and battle.game and battle.game.save==save
        and battle.enemy and not P.captureAllowed(battle.game,battle.enemy.mon.species,battle)then
      return'failed',{opts.i18n.text('This Pokemon cannot\nbe caught.',
        'Dieses Pokemon kann\nnicht gefangen werden.')}
    end
    return original(data,save,id,target,battle,...)
  end
  local Items=require('src.inventory.ItemEffects')
  Items._kascSeviiLegendPolicy=P
  if not Items._kascSeviiLegendPolicyWrapped then
    local original=Items.use
    Items.use=function(...)return Items._kascSeviiLegendPolicy.ballUse(original,...)end
    Items._kascSeviiLegendPolicyWrapped=true
  end
  mod.hooks:wrap('catch.rate',function(nextCatch,ball,mon,def,ctx)
    local battle=ctx and ctx.battle
    if battle and not P.captureAllowed(battle.game,mon and mon.species or def and def.id,battle)then return false,0 end
    return nextCatch(ball,mon,def,ctx)
  end,1000000)
  if opts.legendHistory then P.history=opts.legendHistory(mod,P,opts)end
  return P
end
