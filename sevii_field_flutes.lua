-- Reusable black/white glass flutes on the Kanto host. The ordinary native
-- rate is adjusted once; forced encounters and roaming proposals own their
-- separate probability. Split Sevii maps share their original source area.
return function(mod,opts)
  local F={KEY='sevii_field_flute_v1',factors={BLACK_FLUTE=.5,WHITE_FLUTE=1.5},
    CLEANSE_TAG='CLEANSE_TAG',OWNER='kasc.sevii-field-items/v1'}
  if mod.content and mod.content.items and mod.content.items:get(F.CLEANSE_TAG)then
    mod.content.items:patch(F.CLEANSE_TAG,{kascSeviiFieldItem=F.OWNER})
  end
  local activeGame
  local function area(game,id)
    local d=game and game.data and game.data.maps and game.data.maps[id]
    return d and d.kaSeviiSource or id
  end
  local function bucket(save,create)
    if not save then return end
    if create then save.modData=save.modData or{};save.modData[mod.id]=save.modData[mod.id]or{}end
    return save.modData and save.modData[mod.id]
  end
  function F.state(game)
    local b=bucket(game and game.save);local s=b and b[F.KEY]
    if type(s)=='table'and F.factors[s.item]and type(s.area)=='string'then return s end
  end
  function F.supportsItem(game,id,epoch)
    if id~=F.CLEANSE_TAG then return false end
    local p=game and opts.rules.peek(game)
    local d=game and game.data and game.data.items and game.data.items[id]
    return d and d.kascSeviiFieldItem==F.OWNER and p and p.extensionsEnabled
      and (tonumber(epoch)or 1)>=2 or false
  end
  function F.leadCleanseTag(game)
    local mon=game and game.save and game.save.party and game.save.party[1]
    if type(mon)~='table' or mon.isEgg or mon.egg or mon.eggSpecies then return false end
    local equipment=mod.exports and mod.exports.pokemonEquipment67
    local id=equipment and equipment.held and equipment.held(mon)
    if id==nil and not equipment then
      local a,b=mon.item,mon.heldItem
      if a and b and a~=b then return false end
      id=a or b
    end
    return id==F.CLEANSE_TAG
  end
  function F.clearOnEntry(game,id)
    local s=F.state(game)
    if s and s.area~=area(game,id)then bucket(game.save)[F.KEY]=nil end
  end
  function F.use(ctx)
    local id=ctx.itemId;local ow=ctx.overworld
    if ctx.battle or not F.factors[id]or not(ctx.save and ow and ow.map)then
      return 'failed',{opts.i18n.text('Use this flute while exploring.',
        'Benutze diese Flöte beim Erkunden.')}
    end
    local g={save=ctx.save,data=ctx.data};local current=F.state(g)
    local destination=area(g,ow.map.id)
    local stop=current and current.item==id and current.area==destination
    bucket(ctx.save,true)[F.KEY]=not stop and{item=id,area=destination}or nil
    require('src.core.Sound').play(ctx.data,'Pokeflute')
    local text=stop and opts.i18n.text('The flute effect has ended.',
      'Die Wirkung der Flöte ist beendet.')
      or id=='BLACK_FLUTE'and opts.i18n.text('Normal wild encounters are less frequent in this area. Play again to end the effect.',
        'Normale wilde Begegnungen sind in diesem Gebiet seltener. Erneut spielen beendet die Wirkung.')
      or opts.i18n.text('Normal wild encounters are more frequent in this area. Play again to end the effect.',
        'Normale wilde Begegnungen sind in diesem Gebiet häufiger. Erneut spielen beendet die Wirkung.')
    return 'kept',{text}
  end
  function F.adjust(game,def,ctx)
    if not game or not game.save or type(ctx)~='table'or ctx.kind
        or(ctx.terrain~='grass'and ctx.terrain~='water'and ctx.terrain~='indoor')
        or type(def)~='table'or type(def.grass)~='table'then return def end
    local p=opts.rules.peek(game)
    if not p or not p.extensionsEnabled then return def end
    local s=F.state(game)
    local flute=s and s.area==area(game,ctx.mapId)and p.activeEpoch>=3
      and F.factors[s.item]or nil
    local cleanse=p.activeEpoch>=2 and F.leadCleanseTag(game)
      and F.supportsItem(game,F.CLEANSE_TAG,p.activeEpoch)
    if not flute and not cleanse then return def end
    local rate=def.grass.rate
    if type(rate)~='number'or rate~=rate or rate<=0 or rate>256 then return def end
    local out,grass={},{}
    for k,v in pairs(def)do out[k]=v end
    for k,v in pairs(def.grass)do grass[k]=v end
    if flute then rate=rate*flute end
    if cleanse then rate=math.floor(rate*2/3)end
    grass.rate=math.min(256,rate);out.grass=grass
    return out
  end
  -- After the existing ability-rate adapter, at the single native roll.
  -- No extra RNG, altered slots, global map mutation or extra spawn trial.
  mod.hooks:wrap('encounter.roll',function(nextRoll,def,ctx)
    return nextRoll(F.adjust(activeGame,def,ctx),ctx)
  end,-11000)
  for _,event in ipairs{'game.ready','save.loaded'}do
    mod.events:on(event,function(ev)if ev and ev.game then
      activeGame=ev.game
      -- save.loaded may precede the new overworld; never inspect the old
      -- slot's map while deciding whether the adopted save keeps its effect.
      local id=activeGame.save and activeGame.save.player and activeGame.save.player.map
      if id then F.clearOnEntry(activeGame,id)end
    end end,3600)
  end
  mod.events:on('map.entered',function(ev)
    local game=ev and ev.game or activeGame
    if game and ev and ev.mapId then F.clearOnEntry(game,ev.mapId)end
  end,3600)
  return F
end
