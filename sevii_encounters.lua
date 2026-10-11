-- All authored ordinary Sevii captures share one source-driven catalogue.
-- National keys resolve through the canonical backend, never private Dex ABI.
return function(mod,S,opts)
  local raw=assert(mod:read('assets/sevii_local/habitats.json'),'Rebuild the Sevii import: habitat catalogue missing')
  local plan=opts.json.decode(raw)
  assert(plan.schema=='kasc.sevii-compiled-habitats/v1'and plan.ordinarySpecies==218,'Sevii habitat scope mismatch')
  local E={plan=plan,byMap={},bySpecies={},byRuntime={},SOURCE='sevii-expedition'}
  -- Rare targets remain possible at every hour. Night or real field weather
  -- makes their authored window noticeably better without Dex dead ends.
  E.rare={
    ROTOM={time='night'},SPIRITOMB={time='night'},DRIFLOON={time='night'},
    SABLEYE={time='night'},LUNATONE={time='night'},
    SOLROCK={time='day'},RIOLU={time='day'},BAGON={time='day'},
    FEEBAS={weather='rain'},CASTFORM={weather='rain'},
  }
  local assetCache={}
  local hevo={}
  for _,id in ipairs(opts.hevoSpecies and opts.hevoSpecies.order or{})do hevo[id]=true end
  for _,pool in ipairs(plan.pools)do
    assert(S.maps[pool.map],'Habitat map missing: '..pool.map)
    assert(pool.reachableCells>0 and #pool.species>0 and #pool.species<=10,'Unreachable or overflowing habitat')
    local slot=pool.terrain=='water'and'water'or'grass'
    E.byMap[pool.map]=E.byMap[pool.map]or{}
    assert(not E.byMap[pool.map][slot],'Conflicting Sevii surfaces')
    E.byMap[pool.map][slot]=pool
    for _,row in ipairs(pool.species)do
      assert(not E.bySpecies[row.id],'Duplicate Sevii target '..row.id)
      E.bySpecies[row.id]={pool=pool,row=row}
    end
  end
  local function backend()return opts.backendSpecies and opts.backendSpecies()end
  function E.resolve(game,row)
    local owner=backend()
    local id=owner and owner.byKey[row.key]or row.id
    local def=game.data.pokemon[id]
    -- Test fixtures and older canonical Hoenn rows can omit sourceDex; the
    -- backend is the authoritative identity whenever it has been loaded.
    if not def then return nil,'species-not-registered'end
    if owner and owner.bySpecies[id]~=row.key then return nil,'identity-mismatch'end
    E.byRuntime[id]=row
    return id,def
  end
  function E.assetPaths(name,def)
    local paths={}
    local function add(path)
      if type(path)~='string'then return end
      local prefix=mod.path..'/'
      if path:sub(1,#prefix)==prefix then path=path:sub(#prefix+1)end
      paths[path]=true
    end
    local row=opts.hoennSpecies and opts.hoennSpecies.bySpecies[name]
    for _,path in pairs(row and row.assets or{})do add(path)end
    local late=opts.lateSpecies and opts.lateSpecies.bySpecies[name]
    for _,path in pairs(late and late.assets or{})do add(path)end
    local owner=backend()
    for _,path in ipairs(owner and owner.spriteContentPaths(name)or{})do add(path)end
    for _,key in ipairs{'spriteFront','spriteBack'}do add(def and def[key])end
    -- Reused starter/HEVO owners have padded legacy stills. Their reviewed
    -- classic battle cards also supply the renderer's placement ownership.
    -- Runtime Dex (including private HEVO slots) indexes this art registry.
    local art=opts.classicArt
    local dex=def and def.dex
    local classic=art and dex and (art[tostring(dex)]or art[dex])
    for _,key in ipairs{'front','back','frontShiny','backShiny'}do
      add(classic and classic[key])
    end
    -- HEVO's original stills use 64px canvases. Its Crystal frame owner
    -- supplies the safe battle position; it is not in the later card table.
    if hevo[name] and dex then
      for _,side in ipairs{'front','back'}do
        for _,variant in ipairs{'normal','shiny'}do
          local clocks=side=='back'and opts.animationData and opts.animationData.back or opts.animationData
          local timing=clocks and clocks[variant]and clocks[variant][tostring(dex)]
          for frame=1,math.max(1,timing and #timing or 1)do
            add(('assets/crystal_animated/%s/%s/%d/%03d.png'):format(side,variant,dex,frame))
          end
        end
      end
    end
    if def and type(def.icon)=='table'then add(def.icon.image)end
    local out={};for path in pairs(paths)do out[#out+1]=path end;table.sort(out)
    return out
  end
  function E.assetsReady(name,def)
    if assetCache[name]~=nil then return assetCache[name]end
    for _,path in ipairs(E.assetPaths(name,def))do
      local bytes=mod:read(path)
      if type(bytes)~='string'or #bytes==0 or path:match('%.png$')and bytes:sub(1,8)~='\137PNG\r\n\26\n' then
        assetCache[name]=false;return false,path
      end
    end
    assetCache[name]=true;return true
  end
  function E.availability(game,row)
    if not S.unlocked(game)then return false,'league-required'end
    if opts.beyondKanto and not opts.beyondKanto.peekIsActive(game)then
      return false,'beyond-kanto-sealed'
    end
    local id,def=E.resolve(game,row)
    if not id then return false,def end
    if row.generation==3 and opts.fieldAccess and not opts.fieldAccess.encountersEnabled(game)then
      return false,'hoenn-disabled'
    end
    if not opts.generationRules.peekSpeciesAvailable(game,id,def)then return false,'generation-profile'end
    if not E.assetsReady(id,def)then return false,'missing-art'end
    return true,id
  end
  function E.rareWindow(game,id)
    local rule=E.rare[id];if not rule then return false end
    if rule.time then
      local ok,mode=pcall(opts.timeMode or function()return nil end)
      return ok and mode==rule.time
    end
    if rule.weather then
      local ok,mode=pcall(opts.fieldWeather or function()return nil end,game)
      return ok and type(mode)=='string'and mode:lower()==rule.weather
    end
    return false
  end
  local function weightedSlots(game,rows)
    local slots,weights={},{}
    for i,row in ipairs(rows)do
      slots[i]={species=row.id,level=row.level}
      weights[i]=E.rare[row.sourceId]and(E.rareWindow(game,row.sourceId)and 16 or 1)or 16
    end
    local total=0;for _,weight in ipairs(weights)do total=total+weight end
    local remaining=10-#slots
    local shares={}
    for i,weight in ipairs(weights)do shares[i]=remaining*weight/total end
    while #slots<10 do
      local best=1
      for i=2,#rows do if shares[i]>shares[best]then best=i end end
      slots[#slots+1]={species=rows[best].id,level=rows[best].level}
      shares[best]=shares[best]-1
    end
    return slots
  end
  function E.encounters(game,map)
    local out={kaProtected=true,kaEncounterSource=E.SOURCE,kaWildsStrictSurface=true}
    for terrain,pool in pairs(E.byMap[map]or{})do
      local eligible={}
      for _,row in ipairs(pool.species)do
        local allowed,id=E.availability(game,row)
        if allowed then eligible[#eligible+1]={id=id,sourceId=row.id,
          level=S.scaling and S.scaling.wild(game,row.level)or row.level}end
      end
      -- Every target retains at least one slot; rare-only habitats lower the
      -- native encounter rate until their time or weather window arrives.
      assert(#eligible<=10,'Sevii pool overflow')
      local count=#eligible
      local rate=count>0 and 18 or 0
      if count==1 and E.rare[eligible[1].sourceId]
          and not E.rareWindow(game,eligible[1].sourceId)then rate=3 end
      out[terrain]={rate=rate,slots=count>0 and weightedSlots(game,eligible)or{}}
    end
    out.grass=out.grass or{rate=0,slots={}}
    return out
  end
  function E.coverage(game)
    local out={available=0,required=218,missing={},locations=plan.locations}
    for id,target in pairs(E.bySpecies)do
      local allowed,reason=E.availability(game,target.row)
      if allowed then out.available=out.available+1 else out.missing[#out.missing+1]={id=id,reason=reason}end
    end
    table.sort(out.missing,function(a,b)return a.id<b.id end)
    return out
  end
  local function permitted(ctx)
    local pools=ctx and E.byMap[ctx.mapId]
    if not pools then return false end
    local pool=pools[ctx.terrain=='water'and'water'or'grass']
    if not pool then return false end
    -- Native Gen1 categorizes high map indices as indoors. Reject that
    -- fallback on outdoor grass habitats, so paths remain safe to walk.
    return ctx.terrain==pool.terrain or pool.terrain=='indoor'and ctx.terrain=='grass'
  end
  local function accepted(encounter,ctx)
    if not encounter or not permitted(ctx)then return false end
    -- Cached map slots must not outlive a save/profile/content change.
    local row=E.byRuntime[encounter.species]
    if not row or not E.availability(E.game,row)then return false end
    local target=E.bySpecies[row.id]
    local pool=E.byMap[ctx.mapId][ctx.terrain=='water'and'water'or'grass']
    return target and target.pool==pool
      and encounter.level==(S.scaling and S.scaling.wild(E.game,row.level)or row.level)or false
  end
  if mod.hooks then
    mod.hooks:wrap('encounter.roll',function(nextRoll,definition,ctx)
      if not(ctx and S.maps[ctx.mapId])then return nextRoll(definition,ctx)end
      if not permitted(ctx)then return nil end
      ctx.kaProtected=true;ctx.kaEncounterSource=E.SOURCE
      local live=E.game and E.encounters(E.game,ctx.mapId)or definition
      -- The native controller rolls definition.grass even while Surfing:
      -- it packs the map's water table into that slot before this hook.
      -- Replacing its definition with our live catalogue must preserve that
      -- interface. E.encounters returns a fresh roll-local definition, so
      -- this does not mutate a stored map table or allocate another table.
      if E.game and ctx.terrain=='water'then live.grass=live.water end
      local rolled=nextRoll(live,ctx)
      if not accepted(rolled,ctx)then return nil end
      rolled.kaProtected=true;rolled.kaEncounterSource=E.SOURCE
      return rolled
    end,2200)
    mod.hooks:wrap('encounter.species',function(nextSpecies,encounter,ctx)
      if not(ctx and S.maps[ctx.mapId])then return nextSpecies(encounter,ctx)end
      if not accepted(encounter,ctx)then return nil end
      -- Other species-substitution layers cannot turn an authored Sevii
      -- encounter into a randomizer or character-lineage encounter.
      return encounter
    end,2200)
  end
  return E
end
