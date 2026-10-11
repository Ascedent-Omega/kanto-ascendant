-- Extend the existing Eon identities; never construct a second quest owner.
return function(mod,S,opts)
  local R=assert(opts.hoennRoamers);local V={maps={},groups={},kanto={},extraKanto={},DENOMINATOR=20}
  local tr=opts.i18n and opts.i18n.text or function(en)return en end
  for id,m in pairs(S.maps)do
    local source=m.kaSeviiSource or ''
    local natural=m.outdoor or source=='MtEmber_Exterior'or source=='MtEmber_Summit'
      or source=='ThreeIsland_BerryForest'or source=='SixIsland_PatternBush'
      or source=='TrainerTower_Roof'
    if natural then
      V.maps[id]=source;V.groups[source]=V.groups[source]or{}
      table.insert(V.groups[source],id)
    end
  end
  -- Vanilla Kanto has no explicit outdoor flag on its generated maps.
  -- Decks and roof terraces are outside even though they reuse indoor art.
  local terraces={CELADON_MANSION_ROOF=true,CELADON_MART_ROOF=true,
    SS_ANNE_BOW=true,VERMILION_DOCK=true}
  for id,m in mod.content.maps:each()do
    if not S.maps[id]and type(m.index)=='number'and m.index>=0 and m.index<256
        and (m.outdoor==true or m.outdoor~=false and
          (m.tileset=='OVERWORLD'or m.tileset=='PLATEAU'or m.tileset=='FOREST'or terraces[id]))then
      V.kanto[id]=true;V.maps[id]=id;V.groups[id]={id}
    end
  end
  for _,id in ipairs{'KA_BLAINE_VOLCANO_FOOT'}do
    local m=mod.content.maps:get(id)
    if m and m.outdoor==true then V.extraKanto[id]=true;V.maps[id]=id;V.groups[id]={id}end
  end
  for _,ids in pairs(V.groups)do table.sort(ids)end
  function V.area(map)return V.maps[map]end
  function V.available(game)return S.specialEncounters.storyReady(game)end
  function V.mapAccessible(game,map)
    return true
  end
  function V.accepts(game,map)return V.maps[map]~=nil and V.available(game)==true and V.mapAccessible(game,map)end
  function V.routes(game)
    local out={};if not V.available(game)then return out end
    -- Fragments of a long coast are one area, not many independently weighted
    -- destinations. Every fragment still admits an encounter with that roamer.
    for _,ids in pairs(V.groups)do if V.mapAccessible(game,ids[1])then out[#out+1]=ids[1]end end;table.sort(out);return out
  end
  function V.readyFor(game,id)
    if id~='LATIAS'and id~='LATIOS'then return false end
    local d=game.data.pokemon[id]
    return d and opts.generationRules.peekSpeciesAvailable(game,id,d)
      and S.assetsReady(id,d)or false
  end
  R.setExpansion(V)
  -- The host already calls encounter.roll on all high-index Sevii floor,
  -- grass and Surf cells, after scripts, warps, poison, grace and Repel ticks.
  -- Run before the ordinary habitat filter; leave all other rolls intact.
  mod.hooks:wrap('encounter.roll',function(nextRoll,definition,ctx)
    if ctx and V.maps[ctx.mapId]and not ctx.kaProtected and not ctx.kaEncounterSource
        and not(ctx.opts and(ctx.opts.hooked or ctx.opts.scriptedEncounter or ctx.opts.randomizerProtected))then
      local game=S.habitats.game
      if game and game.overworld and game.overworld.map.id==ctx.mapId then
        local row=R.rollExpansion(game,ctx.mapId,ctx.rng)
        if row then return row end
      end
    end
    return nextRoll(definition,ctx)
  end,2300)
  mod.hooks:wrap('encounter.species',function(nextSpecies,row,ctx)
    local game=S.habitats.game
    if game and ctx and R.acceptsExpansionEncounter(game,row,ctx)then return row end
    return nextSpecies(row,ctx)
  end,2300)
  -- The host only rolls on grass/water and cave-like floors. Extend its
  -- existing floor branch for this synchronous step, then restore the exact
  -- policy and method even on error. All of the host's earlier returns
  -- (story, warp, poison, Repel expiry, grace) therefore still apply.
  function V.install(game)
    local ow=game and game.overworld
    if not ow or type(ow.onStepComplete)~='function'or ow._kascEonStepWrapped then return end
    local originalStep=ow.onStepComplete
    local activeFloor,activePolicy,floorFallback
    local function admittedFloor(def,policy)
      if def==activeFloor and policy==activePolicy then return true end
      return floorFallback(def,policy)
    end
    ow._kascEonStepWrapped=true
    ow.onStepComplete=function(self,...)
      local field=game.data.field;local policy=field and field.indoorEncounters
      if self~=game.overworld or not policy or not V.accepts(game,self.map.id)
          or not R.available(game)or type(self.map.def.index)~='number'then
        return originalStep(self,...)
      end
      local originalInstance=rawget(self,'rollEncounter');local originalRoll=self.rollEncounter
      local extended={};for k,v in pairs(policy)do extended[k]=v end
      extended.firstIndoorMap=-math.huge;extended.excludedTileset=false
      field.indoorEncounters=extended
      -- New hosts exclude explicitly outdoor maps before consulting the
      -- floor policy. Admit only this owned Sevii floor for the synchronous
      -- native step; preserve its story/warp/Repel/grace guards and keep
      -- Kanto's current behavior and every map definition untouched.
      local host,originalFloor,newSeviiFloor
      if S.maps[self.map.id]then
        host=require('src.world.OverworldController')
        originalFloor=host.rollsIndoorEncounters
        if type(originalFloor)=='function'and not originalFloor(self.map.def,policy)then
          newSeviiFloor=true
          activeFloor,activePolicy,floorFallback=self.map.def,extended,originalFloor
          host.rollsIndoorEncounters=admittedFloor
        end
      end
      self.rollEncounter=function(world,definition,terrain)
        if terrain=='indoor'and(newSeviiFloor or not(world.map.def.index>=policy.firstIndoorMap
            and world.map.def.tileset~=policy.excludedTileset))then
          -- A newly admitted town/forest floor gets only the roaming pool.
          -- It must not acquire that map's ordinary grass encounters.
          local row=originalRoll(world,nil,'eon_outdoor')
          return row and R.acceptsExpansionEncounter(game,row,{mapId=world.map.id})and row or nil
        end
        return originalRoll(world,definition,terrain)
      end
      local ok,result=pcall(originalStep,self,...)
      self.rollEncounter=originalInstance;field.indoorEncounters=policy
      if originalFloor then host.rollsIndoorEncounters=originalFloor end
      activeFloor,activePolicy,floorFallback=nil,nil,nil
      if not ok then error(result,0)end
      return result
    end
  end
  function V.canCapture(game,battle,species)return R.canCaptureExpansion(game,battle,species)end
  local prior=S.chapters.journal
  S.chapters.journal=function()
    local text=prior()
    if S.state().expeditionComplete then
      text=text..'\n\n'..tr('WIDER SKIES: With the local crossing sealed, LATIAS and LATIOS extend their Kanto journeys to Sevii. Look across the islands and seas; caves, homes and Pokemon Centers remain quiet. These are the same wandering Pokemon, not new arrivals. Their usual Hoenn access requirements still apply. In Kanto and Sevii, a roamer present in your area has a 5% chance per eligible step to appear. Repel still works.',
        'WEITER HIMMEL: Seit der örtliche Übergang versiegelt ist, erweitern LATIAS und LATIOS ihre Kanto-Reisen um Sevii. Suche auf den Inseln und auf dem Meer; Höhlen, Häuser und Pokemon-Center bleiben ruhig. Es sind dieselben wandernden Pokemon, keine neuen Ankömmlinge. Ihre bisherigen Hoenn-Zugangsvoraussetzungen gelten weiter. Ist ein Wanderer in deinem Gebiet, kann er in Kanto und auf Sevii bei jedem geeigneten Schritt mit 5 % Wahrscheinlichkeit erscheinen. Schutz wirkt weiterhin.')
    end
    return text
  end
  return V
end
