-- Usable Johto/Hoenn supplies. Registered effects let the native Bag own
-- targeting, consumption, battle turns and saves; no inventory mutation here.
-- Classic amounts follow src/core/gen2/ItemEffects.lua; bitter penalties
-- follow its Happiness.CHANGES rows 15..17. KASC retains these classic
-- amounts in later profiles, as it does for its native Hyper Potion.
return function(mod,opts)
  local tr=opts.i18n.text
  local M={OWNER='kasc.sevii-medicine/v1',rows={
    {id='MOOMOO_MILK',en='MOOMOO MILK',de='KUHMUH-MILCH',gen=2,price=500,hp=100},
    {id='BERRY_JUICE',en='BERRY JUICE',de='BEERENSAFT',gen=2,price=100,hp=20},
    {id='ENERGY_POWDER',en='ENERGY POWDER',de='ENERGIEPULVER',gen=2,price=500,hp=50,bitter={5,10}},
    {id='ENERGY_ROOT',en='ENERGY ROOT',de='KRAFTWURZEL',gen=2,price=1200,hp=200,bitter={10,15}},
    {id='HEAL_POWDER',en='HEAL POWDER',de='HEILPUDER',gen=2,price=300,cure=true,bitter={5,10}},
    {id='REVIVAL_HERB',en='REVIVAL HERB',de='VITALKRAUT',gen=2,price=2800,revive=true,bitter={15,20}},
    {id='LAVA_COOKIE',en='LAVA COOKIE',de='LAVAKEKS',gen=3,price=350,cure=true},
  }}
  local byId={};for _,r in ipairs(M.rows)do byId[r.id]=r end
  local ailments={PSN=true,BRN=true,FRZ=true,SLP=true,PAR=true}
  local function failure()return 'failed',{tr('It will not have any effect.','Das wird keine Wirkung haben.')}end
  local function member(save,mon)
    for _,m in ipairs(save and save.party or{})do if m==mon then return true end end
    return false
  end
  local function battler(b,mon)
    if b and b.player and b.player.mon==mon then return b.player end
  end
  function M.supports(game,id)
    local r=byId[id];local p=game and opts.rules.peek(game)
    local d=game and game.data and game.data.items[id]
    local e=d and game.data.item_effects and game.data.item_effects[d.effect]
    return r and p and p.extensionsEnabled and p.activeEpoch>=r.gen
      and d and d.kascSeviiMedicine==M.OWNER and e and e.kascSeviiMedicine==M.OWNER or false
  end
  local function bitter(mon,r)
    if not r.bitter then return end
    -- Existing evolution and move owners read these different fields.
    -- Lower each present value; never replace an old value with a new default.
    local found=false
    for _,key in ipairs({'happiness','friendship','johtoBond'})do
      local n=tonumber(mon[key])
      if n then found=true;mon[key]=math.max(0,math.min(255,n)-r.bitter[n>=200 and 2 or 1])end
    end
    if not found then mon.johtoBond=0 end -- existing missing-bond policy
  end
  function M.use(ctx)
    local r=byId[ctx.itemId];local mon=ctx.target
    -- Native OverworldController uses a module-local Game, not ow.game.
    -- Item effects receive the exact save/data pair; resolve that context
    -- just like the existing evolution effects, without a stale game cache.
    local game=ctx.battle and ctx.battle.game or
      {data=ctx.data,save=ctx.save,overworld=ctx.overworld}
    if not r or not M.supports(game,ctx.itemId)then
      return 'failed',{tr('This medicine needs its generation rules.',
        'Diese Medizin braucht die passenden Generationsregeln.')}
    end
    if not mon or not member(ctx.save,mon)or mon.isEgg or mon.egg or mon.eggSpecies or mon.is_egg
        or type(mon.hp)~='number'or not mon.stats or type(mon.stats.hp)~='number'then return failure()end
    local w=battler(ctx.battle,mon);local before=mon.hp
    if r.revive then
      if before>0 then return failure()end
      mon.hp=mon.stats.hp;mon.status=nil
      if ctx.battle and ctx.battle.participants then ctx.battle.participants[mon]=true end
    elseif r.hp then
      if before<=0 or before>=mon.stats.hp then return failure()end
      mon.hp=math.min(mon.stats.hp,before+r.hp)
    else
      if before<=0 or not(ailments[mon.status]or w and(w.confusedTurns or 0)>0)then return failure()end
      mon.status=nil
    end
    if r.cure or r.revive then
      if w then w.toxicCounter=nil;w.sleepTurns=nil;w.confusedTurns=nil end
    end
    bitter(mon,r)
    require('src.core.Sound').play(ctx.data,r.cure and 'Heal_Ailment'or'Heal_HP')
    local name=mon.nickname or(ctx.data.pokemon[mon.species]or{}).name or mon.species
    local message=r.cure and tr('%s recovered from its status problems.','%s ist von Statusproblemen geheilt.')
      or r.revive and tr('%s is back at full HP.','%s ist wieder bei vollen KP.')
      or tr('%s recovered %d HP.','%s hat %d KP erhalten.')
    local messages={message:format(name,mon.hp-before)}
    if r.bitter then messages[#messages+1]=tr('The bitter taste lowered its friendship.',
      'Der bittere Geschmack hat die Freundschaft gesenkt.')end
    return 'consumed',messages,(not r.cure)and{healedFrom=before}or nil
  end
  for _,r in ipairs(M.rows)do
    local effect='KA_SEVII_MEDICINE_'..r.id
    local old=mod.content.items:get(r.id)
    assert(not old or not old.effect,'medicine already has an effect owner: '..r.id)
    local fields={name=tr(r.en,r.de),names={en=r.en,de=r.de},effect=effect,
      needsTarget=true,field=true,battle=true,keyItem=false,kascSeviiMedicine=M.OWNER,
      originGeneration=r.gen}
    if old then mod.content.items:patch(r.id,fields)
    else fields.id=r.id;fields.price=r.price;mod.content.items:register(r.id,fields)end
    mod.content.item_effects:register(effect,{needsTarget=true,field=true,battle=true,
      kascSeviiMedicine=M.OWNER,use=M.use})
  end
  return M
end
