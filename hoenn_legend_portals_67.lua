-- KASC 6.7 optional character-locked Hoenn legend portal card.
--
-- Weather legends now answer on Sevii after the own HEVO door visit and the
-- 130-species foundation. Capture receipts remain monotonic Legacy evidence.

return function(mod,opts)
  opts=opts or{}
  local dex=assert(opts.dex,"Hoenn Dex authority missing")
  local journey=assert(opts.journey,"Legacy journey missing")
  local geometry=assert(opts.geometry,"Hoenn exploration geometry missing")
  local skyTileset=opts.skyTileset or"KA_HOENN_SKY_67"
  local function tr(en,de)
    return opts.i18n and opts.i18n.text and opts.i18n.text(en,de)or en
  end
  local P={registered=false,bound=false,LEVEL=70}
  P.rows={
    RED={character="RED",species="GROUDON",flag="KA_LEGEND_CAPTURE_GROUDON",
      map="KA_HEVO_GROUDON_CHAMBER",index=1984,label={en="GROUDON CHAMBER",de="GROUDON-KAMMER"},
      text="TEXT_KA_HEVO_GROUDON_CAPTURE",returnX=3},
    BLUE={character="BLUE",species="KYOGRE",flag="KA_LEGEND_CAPTURE_KYOGRE",
      map="KA_HEVO_KYOGRE_CHAMBER",index=1985,label={en="KYOGRE CHAMBER",de="KYOGRE-KAMMER"},
      text="TEXT_KA_HEVO_KYOGRE_CAPTURE",returnX=15},
    GREEN={character="GREEN",species="RAYQUAZA",flag="KA_LEGEND_CAPTURE_RAYQUAZA",
      map="KA_HEVO_RAYQUAZA_CHAMBER",index=1986,label={en="RAYQUAZA CHAMBER",de="RAYQUAZA-KAMMER"},
      text="TEXT_KA_HEVO_RAYQUAZA_CAPTURE",returnX=27},
  }
  P.byMap={};for _,row in pairs(P.rows)do P.byMap[row.map]=row end
  local activeGame,shared,originalDoor,seviiSites,seviiLevel
  local liveBattles=setmetatable({},{__mode='k'})
  local function option(game)
    local bucket=game and game.mods and game.mods.modOptions
      and game.mods.modOptions[mod.id]
    if bucket and bucket.hoenn_legend_portals~=nil then
      return bucket.hoenn_legend_portals~=false
    end
    local value=mod.options and mod.options.get
      and mod.options:get("hoenn_legend_portals")
    return value~=false
  end
  local function persistent(save,create)
    if type(save)~="table"then return nil end
    if type(save.modData)~="table"then if not create then return nil end;save.modData={}end
    local bucket=save.modData[mod.id]
    if type(bucket)~="table"then if not create then return nil end;bucket={};save.modData[mod.id]=bucket end
    if type(bucket.hevo_persistent)~="table"then
      if not create then return nil end;bucket.hevo_persistent={}
    end
    local p=bucket.hevo_persistent
    if type(p.secretUnlocks)~="table"then
      if not create then return p end;p.secretUnlocks={}
    end
    return p
  end
  local function profileReceipts()
    local ok,value=pcall(journey.profile)
    return ok and type(value)=="table"and value.secretUnlocks or{}
  end
  local function runToken(game)
    local history=opts.legendHistory
    return history and type(history.runId)=='function'and history.runId(game)or'original'
  end
  local function runCaptures(game,create)
    local save=game and game.save;local localMod=save and save.modData and save.modData[mod.id]
    if not localMod then return nil end
    local token=runToken(game)
    local state=localMod.hoennLegendPortalRunCaptures
    if type(state)~='table'or state.runId~=token then
      if not create then return nil end
      state={runId=token,caught={}};localMod.hoennLegendPortalRunCaptures=state
    end
    return state
  end
  function P.caught(game,row)
    row=type(row)=="table"and row or P.rows[row]
    if not row then return false end
    local history=opts.legendHistory
    if runToken(game)~='original'and history and history.ownedThisRun then
      return history.ownedThisRun(game,row.species)==true
    end
    local p=persistent(game and game.save,false)
    return p and p.secretUnlocks and p.secretUnlocks[row.flag]==true
      or profileReceipts()[row.flag]==true or false
  end
  local function currentCharacter(game)
    local value=shared and type(shared.character)=="function"and shared.character(game)
    value=type(value)=="string"and value:upper()or nil
    return P.rows[value]and value or nil
  end
  local function sealValid(game,character)
    if type(journey.currentHevoSeal)~="function"then return false end
    local ok,sealed,owner=pcall(journey.currentHevoSeal,game and game.save,character)
    return ok and sealed==true and owner==character
  end
  function P.available(game,character)
    character=character or currentCharacter(game)
    return option(game)and P.rows[character]~=nil and sealValid(game,character)
      and type(journey.currentHevoDoorVisit)=="function"
      and journey.currentHevoDoorVisit(game and game.save,character)==true
      and dex.report(game).portalReady==true
  end
  function P.bindSeviiSites(sites,levelProvider)
    assert(type(sites)=="table","Sevii legend sites missing")
    seviiSites=sites
    if levelProvider~=nil then
      assert(type(levelProvider)=="function","Sevii level provider must be callable")
      seviiLevel=levelProvider
    end
    return true
  end
  function P.seviiLevel(game)
    return seviiLevel and seviiLevel(game,P.LEVEL)or P.LEVEL
  end
  function P.atSeviiSite(game,row)
    if not seviiSites then return false end
    local site=seviiSites[row.character]
    local ow=game and game.overworld;local player=ow and ow.player
    return site and ow.map and ow.map.id==site.map and player
      and math.abs(player.cellX-site.x)+math.abs(player.cellY-site.y)==1 or false
  end
  function P.canCapture(game,battle,species)
    local live=game and liveBattles[game]
    if not(live and live.battle==battle and live.save==game.save
        and live.row.species==species and not live.finished
        and battle.game==game and battle.kind=='wild'
        and battle.enemy and battle.enemy.mon.species==species
        and P.available(game,live.row.character)
        and P.atSeviiSite(game,live.row))then return false end
    for _,screen in ipairs(game.stack and game.stack.states or{})do
      if screen==battle then return true end
    end
    return false
  end
  function P.bindLegendHistory(history)opts.legendHistory=assert(history)end
  function P.priorOwnership(game,row)
    if not opts.legendHistory then return false end
    local h=opts.legendHistory
    return (h.ownedThisRun or h.owned)(game,row.species)
  end
  function P.witnessed(game,row)
    if runToken(game)~='original'then return false end
    local flag='KA_LEGEND_WITNESS_'..row.species
    local p=persistent(game and game.save,false)
    return p and p.secretUnlocks and p.secretUnlocks[flag]==true or profileReceipts()[flag]==true or false
  end
  function P.recordWitness(game,row)
    if not(row and P.rows[row.character]==row and P.available(game,row.character)
        and (not seviiSites or P.atSeviiSite(game,row)))then return false,'unavailable'end
    if P.caught(game,row)or P.witnessed(game,row)then return false,'recorded'end
    local owned,why=P.priorOwnership(game,row);if not owned then return false,why or'unowned'end
    local p=persistent(game.save,true);local flag='KA_LEGEND_WITNESS_'..row.species
    local previous=p.secretUnlocks[flag];p.secretUnlocks[flag]=true
    if type(game.writeSave)=='function'and game:writeSave()==false then
      p.secretUnlocks[flag]=previous;return false,'save'
    end
    -- No synthetic capture seal. This separate research witness preserves
    -- the original character/130-species gate when the Pokemon is banked.
    pcall(journey.syncHevoPersistent,game.save)
    return true
  end
  local function stored(save,mon)
    for _,candidate in ipairs(save and save.party or{})do if candidate==mon then return true end end
    for _,box in ipairs(save and save.boxes or{})do
      for _,candidate in ipairs(box)do if candidate==mon then return true end end
    end
    return false
  end
  function P.recordCatch(game,row,mon)
    row=type(row)=="table"and row or P.rows[row]
    if not(row and game and game.save and mon and mon.species==row.species and stored(game.save,mon))then
      return false,"not-stored"
    end
    local p=persistent(game.save,true)
    local run=runToken(game);local current=run~='original'and runCaptures(game,true)
    if current and current.caught[row.species]or run=='original'
        and p.secretUnlocks[row.flag]==true then return false,"recorded"end
    if current then current.caught[row.species]=true end
    p.secretUnlocks[row.flag]=true
    dex.record(game,row.species)
    local ok,result=pcall(journey.syncHevoPersistent,game.save)
    if type(game.writeSave)=="function"then game:writeSave()end
    return true,ok and result~=false and"recorded"or"local-only"
  end
  local function show(game,text,done,boxOpts)
    game.stack:push(require("src.render.TextBox").new(game,text,done,boxOpts));return true
  end
  local function warp(game,mapId,x,y,facing)
    if mod.world and type(mod.world.warpTo)=="function"then
      local ok=mod.world:warpTo(mapId,x,y,facing);if ok then return true end
    end
    local ow=game and game.overworld
    if not(ow and type(ow.startWarpTo)=="function")then return false end
    ow:startWarpTo(mapId,x,y,facing);return true
  end
  function P.enter(game,row)
    if seviiSites then return false,"moved-to-sevii"end
    if not P.available(game,row.character)then return false,"unavailable"end
    if type(game.writeSave)=="function"and game:writeSave()==false then
      return false,"save"
    end
    if opts.accessReturn then opts.accessReturn.clear(game.save) end
    return warp(game,row.map,8,11,"up")
  end
  function P.leave(game,row)
    local back = opts.accessReturn and opts.accessReturn.point(game.save, row.map)
    if back then
      local ok = warp(game, back.map, back.x, back.y, back.facing)
      if ok then opts.accessReturn.clear(game.save) end
      return ok
    end
    return warp(game,shared.ID,row.returnX,20,"down")
  end
  function P.doorInteraction(game,ow,npc,done)
    -- The black door retains its original HEVO journey and Jirachi's own
    -- convergence route. Weather legends answer only at their Sevii sites.
    return originalDoor(game or activeGame,ow,npc,done)
  end
  function P.challenge(game,ow,npc,done,row)
    if not P.available(game,row.character)
        or (seviiSites and not P.atSeviiSite(game,row))then return show(game,tr(
      "This research seal is not open yet.","Dieses Forschungssiegel ist noch nicht offen."),done)end
    if P.caught(game,row)then return show(game,tr("The capture seal is complete.",
      "Das Fangsiegel ist vollständig."),done)end
    if P.witnessed(game,row)then return show(game,tr("Your bond has already been witnessed here.",
      "Deine Bindung wurde hier bereits bestaetigt."),done)end
    local owned,historyError=P.priorOwnership(game,row)
    if owned then
      local save=game.save
      return show(game,tr("The seal recognizes your bond. Confirm this research without another capture?",
        "Das Siegel erkennt deine Bindung. Forschung ohne einen weiteren Fang bestaetigen?"),nil,
        {defaultNo=true,choice=function(yes)
          if game.save~=save then if done then done()end;return end
          if yes then local ok,why=P.recordWitness(game,row)
            if not ok and why~='recorded'then return show(game,tr("The record could not be saved. Try again.",
              "Der Beleg wurde nicht gespeichert. Versuch es erneut."),done)end
          end
          if done then done()end
        end})
    end
    if historyError then return show(game,tr("The ownership archive is unavailable. Try again later.",
      "Das Besitzarchiv ist nicht lesbar. Versuche es spaeter erneut."),done)end
    local save=game.save
    local function start()
      if game.save~=save then if done then done()end;return end
      local prior,err=P.priorOwnership(game,row)
      if prior or err or not P.available(game,row.character)then return P.challenge(game,ow,npc,done,row)end
      local BattleState=opts.battleState or require("src.battle.BattleState")
      local battle=BattleState.newWild(game,row.species,P.seviiLevel(game),{
        encounterSource="hoenn_legend_portal",randomizerProtected=true})
      battle.kaHoennLegendPortal=row.character
      local live={battle=battle,save=save,row=row,finished=false}
      liveBattles[game]=live
      battle.onFinish=function(result)
        live.finished=true
        if liveBattles[game]==live then liveBattles[game]=nil end
        if result=="caught"then P.recordCatch(game,row,battle.enemy and battle.enemy.mon)end
        if ow and type(ow.afterBattle)=="function"then ow:afterBattle(result,battle)end
        if done then done()end
      end
      if ow and type(ow.pushBattle)=="function"then ow:pushBattle(battle)
      elseif done then done()end
    end
    return show(game,tr(row.species.." answers your "..row.character.." seal!",
      row.species.." antwortet deinem "..row.character.."EN Siegel!"),start)
  end
  function P.bindShared(module)
    if P.bound then return false,"already-bound"end
    shared=assert(module,"shared HEVO room missing")
    originalDoor=assert(shared.doorInteraction,"shared door handler missing")
    shared.doorInteraction=P.doorInteraction
    P.bound=true;return true
  end
  function P.register()
    if P.registered then return false,"already-registered"end
    assert(P.bound,"portal card must bind the shared door before registration")
    local tilesets=mod.content.tilesets
    if tilesets and type(tilesets.get)=="function"and not tilesets:get("CAVERN")then
      P.registered,P.skipped=true,"missing-cavern";return true,P.skipped
    end
    local indexes={};for id,def in mod.content.maps:each()do
      if def and def.index then indexes[def.index]=id end
    end
    for _,key in ipairs({"RED","BLUE","GREEN"})do
      local row=P.rows[key]
      assert(not mod.content.maps:get(row.map),"duplicate legend chamber "..row.map)
      assert(not indexes[row.index],"duplicate legend chamber index "..row.index)
      indexes[row.index]=row.map
      local returnText=row.text.."_RETURN"
      local isSky=row.character=="GREEN"
      -- Keep the chamber's scripted encounter/receipt owner, but show the
      -- actual legendary instead of the shared SPRITE_MONSTER placeholder.
      -- These three small native sheets are bundled with the room so the
      -- display does not depend on an optional follower download.
      local sprite="SPRITE_KA_HEVO_LEGEND_"..row.species
      mod.content.sprites:register(sprite,{id=sprite,
        image=mod.path.."/assets/hoenn_legend_rooms/"..row.species:lower()..".png",
        frames=6,walker=true,trueColor=true,pokemonSpecies=row.species,
        voxelChamberImage=mod.path..'/assets/hoenn_legend_rooms/'..row.species:lower()..'_front.png'})
      local source=assert(geometry.map(row.map),"missing legend exploration map")
      assert(source.index==row.index,"legend map index changed")
      local chamberBlocks={};for i,block in ipairs(source.blocks)do chamberBlocks[i]=block end
      if row.character=="RED"then
        -- CAVERN block 1 uses elevation tile 0x20. The two blocks under
        -- the arrival point form an island: native tile-pair collision
        -- forbids every step onto the surrounding 0x05 floor. Continue
        -- the ordinary cave floor through the landing to the encounter.
        chamberBlocks[4+4*source.width+1]=25
        chamberBlocks[4+5*source.width+1]=25
      end
      mod.content.maps:register(row.map,{id=row.map,index=row.index,
        label=tr(row.label.en,row.label.de),tileset=isSky and skyTileset or"CAVERN",
        width=source.width,height=source.height,borderBlock=isSky and 0 or 125,
        blocks=chamberBlocks,warps={},
        signs={{name="KA_HEVO_"..row.species.."_RETURN",x=8,y=13,text=returnText}},
        connections={},
        outdoor=isSky,
        -- The air atlas already contains the authored sky platform.  Treating
        -- its tile IDs as generic FULL geometry invents forest walls around
        -- Rayquaza; MAP_STUDIO keeps that additive visual map flat and airy.
        voxelMode=isSky and"MAP_STUDIO"or"FULL",
        voxelRevision=source.voxelRevision+(row.character=="RED"and 1 or 0),voxelAuthority="2D_BLOCKS",
        kaExplorationRevisionSha256=geometry.EXPLORATION_REVISION_SHA256,objects={
          {index=1,name="KA_HEVO_"..row.species,sprite=sprite,x=8,y=4,
            movement="STAY",range="DOWN",text=row.text,passable=false}}})
      mod.content.encounters:register(row.map,{grass={rate=0,slots={}}})
      if mod.content.map_songs then mod.content.map_songs:register(row.map,"Music_Dungeon1")end
      mod.content.text:register(row.text,row.species.." is waiting.")
      mod.content.text:register(returnText,"Return through the black portal?")
      mod.content.text_pointers:patch("???",{[row.text]={text=row.text},
        [returnText]={text=returnText}})
      mod.content.map_scripts:register(row.map,{priority=3400,talk={
        [row.text]=function(game,ow,npc,done)return P.challenge(game,ow,npc,done,row)end,
        [returnText]=function(game,_,_,done)
          return show(game,tr("Return through the entrance?",
            "Durch den Eingang zurückkehren?"),nil,{defaultNo=true,
              choice=function(yes)if yes then P.leave(game,row)elseif done then done()end end})
        end}})
    end
    P.registered=true;return true
  end
  function P.secureSave(save)
    local player=save and save.player;local row=player and P.byMap[player.map]
    if not row then return false end
    local back = opts.accessReturn and opts.accessReturn.point(save, row.map)
    if back then player.map,player.x,player.y,player.facing=back.map,back.x,back.y,back.facing
    else player.map,player.x,player.y,player.facing=shared.ID,row.returnX,20,"down" end
    player.surfing=false;return true
  end
  function P.install(game,deps)
    activeGame=game or activeGame;deps=deps or{}
    opts.battleState=deps.battleState or opts.battleState
    return true
  end
  if mod.events and type(mod.events.on)=="function"then
    mod.events:on("save.writing",function(ev)
      P.secureSave(ev and ev.save or activeGame and activeGame.save)
    end,4220)
  end
  return P
end
