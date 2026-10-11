-- Native Bag effects for recovery supplies and reusable Hoenn flutes.
-- The host owns item consumption and turns; PP Max uses its move picker.
return function(mod,opts)
  local tr=opts.i18n.text
  local R={OWNER='kasc.sevii-recovery/v1',rows={
    {id='PP_MAX',en='PP MAX',de='AP-TOP',gen=3,price=9800,target=true},
    {id='SACRED_ASH',en='SACRED ASH',de='ZAUBERASCHE',gen=2,price=20000},
    {id='BLUE_FLUTE',en='BLUE FLUTE',de='BLAUE FLÖTE',gen=3,price=500,target=true,battle=true},
    {id='YELLOW_FLUTE',en='YELLOW FLUTE',de='GELBE FLÖTE',gen=3,price=500,target=true,battle=true,onlyBattle=true},
    {id='RED_FLUTE',en='RED FLUTE',de='ROTE FLÖTE',gen=3,price=500,target=true,battle=true,onlyBattle=true},
    {id='BLACK_FLUTE',en='BLACK FLUTE',de='SCHWARZE FLÖTE',gen=3,price=1000,fieldFlute=true},
    {id='WHITE_FLUTE',en='WHITE FLUTE',de='WEISSE FLÖTE',gen=3,price=1000,fieldFlute=true},
    {id='FLUFFY_TAIL',en='FLUFFY TAIL',de='ENECO-RUTE',gen=3,price=1000,battle=true,onlyBattle=true},
  }}
  local byId={};for _,r in ipairs(R.rows)do byId[r.id]=r end
  local function egg(m)return m.isEgg or m.egg or m.eggSpecies or m.is_egg or m.species=='EGG'end
  local function member(save,mon)
    for _,m in ipairs(save and save.party or{})do if m==mon then return true end end;return false
  end
  local function failed()return 'failed',{tr('It will not have any effect.','Das wird keine Wirkung haben.')}end
  function R.supports(game,id,battle)
    local r=byId[id];local p=battle and battle.kascGenerationRulesReceipt
    local active=p and p.mode~=opts.rules.MODE_OFF
    if not p then p=game and opts.rules.peek(game);active=p and p.extensionsEnabled end
    local d=game and game.data.items[id];local e=d and game.data.item_effects[d.effect]
    return r and active and p.activeEpoch>=r.gen and d and e
      and d.kascSeviiRecovery==R.OWNER and e.kascSeviiRecovery==R.OWNER or false
  end
  function R.use(ctx)
    local id,mon,b=ctx.itemId,ctx.target,ctx.battle;local r=byId[id]
    local g=b and b.game or{data=ctx.data,save=ctx.save,overworld=ctx.overworld}
    if not r or not R.supports(g,id,b)or b and not r.battle or not b and r.onlyBattle then return failed()end
    if r.fieldFlute then
      if not opts.fieldFlutes then return failed()end
      return opts.fieldFlutes.use(ctx)
    end
    if id=='FLUFFY_TAIL'then
      -- Use the native single-consumption escape result. Preserve KASC's
      -- authored raid/echo restrictions and never bypass a ghost scene.
      if b.kind~='wild'or b.demo or b.ghost or b.noCatch or b.result
          or b.kaRocketNoEscape or b.kaMythicEcho
          or b.encounterSource~=nil and b.encounterSource~='wild'and b.encounterSource~='fishing'
          or b.checkpointOrigin and b.checkpointOrigin.kind and b.checkpointOrigin.kind~='wild_encounter' then return failed()end
      return 'consumed_escape',{tr('The wild Pokemon was distracted. Got away safely!',
        'Das wilde Pokemon wurde abgelenkt. Du bist sicher entkommen!')}
    end
    if id=='SACRED_ASH'then
      local count=0
      for _,m in ipairs(ctx.save.party or{})do
        if not egg(m)and m.hp==0 and m.stats and type(m.stats.hp)=='number'and m.stats.hp>0 then
          m.hp=m.stats.hp;m.status=nil;count=count+1
        end
      end
      if count==0 then return failed()end
      return 'consumed',{tr('The Sacred Ash revived %d fainted Pokemon.',
        'Die Zauberasche hat %d besiegte Pokemon wiederbelebt.'):format(count)}
    end
    if not mon or not member(ctx.save,mon)or egg(mon)then return failed()end
    if id=='PP_MAX'then
      local index=ctx.moveIndex
      if type(index)~='number'or index%1~=0 or index<1 or index>4 then return failed()end
      local move=mon.moves and mon.moves[index];local def=move and ctx.data.moves[move.id]
      local base=def and def.pp;local used=move and(move.ppUps or 0)
      if not def or move.id=='SKETCH'or type(base)~='number'or base<5
          or type(used)~='number'or used%1~=0 or used<0 or used>=3
          or type(move.pp)~='number'or move.pp<0 then return failed()end
      local bonus=math.floor(base/5);local maximum=base+3*bonus
      move.pp=math.min(maximum,move.pp+(3-used)*bonus);move.ppUps=3
      if move.maxPp~=nil then move.maxPp=maximum end
      return 'consumed',{tr('%s now has its maximum PP capacity.','%s hat jetzt die maximale AP-Kapazität.'):format(def.name or move.id)}
    end
    if type(mon.hp)~='number'or mon.hp<=0 then return failed()end
    local who=b and b.player and b.player.mon==mon and b.player
    if id=='BLUE_FLUTE'then
      if mon.status~='SLP'then return failed()end
      mon.status=nil;if who then who.sleepTurns=nil end
    elseif id=='YELLOW_FLUTE'then
      if not who or(who.confusedTurns or 0)<=0 then return failed()end
      who.confusedTurns=nil
    elseif id=='RED_FLUTE'then
      if not who or not opts.infatuation or not opts.infatuation.cure(b,who)then return failed()end
    end
    require('src.core.Sound').play(ctx.data,'Pokeflute')
    return 'kept',{tr('The flute cleared the condition. It can be used again.',
      'Die Flöte hat den Zustand geheilt. Sie kann erneut benutzt werden.')}
  end
  -- BagMenu offers party selection for custom target effects, then calls
  -- item.use. Add only the missing move step, retaining native consumption.
  mod.hooks:wrap('item.use',function(nextUse,game,battle,id,target,list,index,picker)
    if id~='PP_MAX'or index~=nil or battle or not target or egg(target)
        or not R.supports(game,id)then return nextUse(game,battle,id,target,list,index,picker)end
    local save=game.save;local used=false
    require('src.ui.Screens').push(game,'MoveSelectMenu',target,
      tr('Maximize PP of\nwhich move?','Maximale AP für\nwelche Attacke?'),function(slot)
        if used or game.save~=save or not member(save,target)or(save.inventory[id]or 0)<1 then return end
        used=true;return nextUse(game,battle,id,target,list,slot,picker)
      end,nil,picker)
  end,3400)
  for _,r in ipairs(R.rows)do
    local old=mod.content.items:get(r.id);assert(not old or not old.effect,'recovery effect already owned: '..r.id)
    local effect='KA_SEVII_RECOVERY_'..r.id
    local fields={name=tr(r.en,r.de),names={en=r.en,de=r.de},effect=effect,
      needsTarget=r.target==true,field=not r.onlyBattle,battle=r.battle==true,
      keyItem=false,originGeneration=r.gen,kascSeviiRecovery=R.OWNER}
    if old then mod.content.items:patch(r.id,fields)
    else fields.id=r.id;fields.price=r.price;mod.content.items:register(r.id,fields)end
    mod.content.item_effects:register(effect,{needsTarget=r.target==true,
      field=not r.onlyBattle,battle=r.battle==true,kascSeviiRecovery=R.OWNER,use=R.use})
  end
  return R
end
