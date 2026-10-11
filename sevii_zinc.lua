-- Zinc trains Special Defense in Gen 3+ without rewriting a legacy save's
-- shared Special stat experience. Calcium continues to train both sides.
return function(mod,opts)
  local tr=opts.i18n.text
  local Z={OWNER='kasc.sevii-zinc/v1',ITEM='ZINC'}
  local function pack(...)return{n=select('#',...),...}end
  local function number(value)
    return type(value)=='number'and value%1==0 and value>=0 and value<=65535
  end
  local function member(save,mon)
    for _,row in ipairs(save and save.party or{})do if row==mon then return true end end
    return false
  end
  local function failure()
    return 'failed',{tr('It will not have any effect.','Das wird keine Wirkung haben.')}
  end
  function Z.supports(game)
    local p=game and opts.rules.peek(game)
    local d=game and game.data and game.data.items and game.data.items.ZINC
    local e=d and game.data.item_effects and game.data.item_effects[d.effect]
    return p and p.extensionsEnabled and p.activeEpoch>=3
      and d and d.kascSeviiZinc==Z.OWNER and e and e.kascSeviiZinc==Z.OWNER or false
  end
  local function refresh(game,mon)
    local genetics=mod.exports and mod.exports.daycare and mod.exports.daycare.breedingIVs
    local profile=opts.rules.peek(game)
    if profile and profile.extensionsEnabled and profile.activeEpoch>=3
        and genetics and genetics.valid and genetics.valid(game,mon)then
      genetics.apply(game,mon,profile.activeEpoch)
    end
  end
  function Z.use(ctx)
    local game=ctx.battle and ctx.battle.game or{data=ctx.data,save=ctx.save}
    local mon=ctx.target
    if ctx.battle or not Z.supports(game)or not member(ctx.save,mon)
        or mon.isEgg or mon.egg or mon.is_egg or mon.eggSpecies
        or type(mon.statExp)~='table' or not number(mon.statExp.special or 0)then
      return failure()
    end
    local current=mon.statExp.specialDefense
    if current==nil then current=mon.statExp.special or 0 end
    if not number(current)or current>=25600 then return failure()end
    mon.statExp.specialDefense=math.min(65535,current+2560)
    refresh(game,mon)
    return 'consumed',{tr("%s's SP. DEF rose!",'Die SP.-VERT. von %s ist gestiegen!')
      :format(mon.nickname or(ctx.data.pokemon[mon.species]or{}).name or mon.species)},
      {useJingle=true}
  end
  local old=mod.content.items:get(Z.ITEM)
  assert(not old or not old.effect,'Zinc already has an effect owner')
  local fields={name=tr('ZINC','ZINK'),names={en='ZINC',de='ZINK'},
    effect='KA_SEVII_ZINC',needsTarget=true,field=true,battle=false,
    keyItem=false,originGeneration=3,kascSeviiZinc=Z.OWNER}
  if old then mod.content.items:patch(Z.ITEM,fields)
  else fields.id=Z.ITEM;fields.price=9800;mod.content.items:register(Z.ITEM,fields)end
  mod.content.item_effects:register(fields.effect,{needsTarget=true,field=true,
    battle=false,kascSeviiZinc=Z.OWNER,use=Z.use})

  -- A legacy Calcium use still raises the shared Special value. If Zinc has
  -- opened the separate Defense track, carry that successful training to it.
  mod.hooks:wrap('item.use',function(nextUse,game,battle,id,target,...)
    local exp=target and target.statExp
    local before=id=='CALCIUM'and member(game and game.save,target)
      and type(exp)=='table'and number(exp.specialDefense)
      and number(exp.special or 0)and(exp.special or 0)or nil
    local result=pack(nextUse(game,battle,id,target,...))
    -- The Gen-1 Bag dispatcher returns no result after applying the effect;
    -- the legacy Special gain itself is the reliable success signal.
    if before and number(exp.special)and exp.special>before then
      exp.specialDefense=math.min(65535,exp.specialDefense+exp.special-before)
      refresh(game,target)
    end
    return unpack(result,1,result.n)
  end,3400)
  return Z
end
