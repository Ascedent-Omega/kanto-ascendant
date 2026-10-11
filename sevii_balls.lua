-- Hoenn research balls and the neutral commemorative Premier Ball. Classic Gen3 bonuses/HP/status/shake math,
-- adapted from engine src/core/game3/battle/catching.lua to the Kanto host.
-- The native Bag owns consumption; the normal catch pipeline owns storage.
return function(mod,opts)
  local tr=opts.i18n.text
  local B={OWNER='kasc.sevii-balls/v1',TOKEN='kascSeviiBallTurns',ENVIRONMENT='kascSeviiBallEnvironment',ids={
    'NET_BALL','NEST_BALL','REPEAT_BALL','TIMER_BALL','PREMIER_BALL','DIVE_BALL','LUXURY_BALL'}}
  local names={NET_BALL={'NET BALL','NETZBALL'},NEST_BALL={'NEST BALL','NESTBALL'},
    REPEAT_BALL={'REPEAT BALL','WIEDERBALL'},TIMER_BALL={'TIMER BALL','TIMERBALL'},
    PREMIER_BALL={'PREMIER BALL','PREMIERBALL'},DIVE_BALL={'DIVE BALL','TAUCHBALL'},
    LUXURY_BALL={'LUXURY BALL','LUXUSBALL'}}
  B.FRIENDSHIP_OWNER='kasc.sevii-friendship-items/v1'
  local bell=mod.content.items:get('SOOTHE_BELL')
  if bell then mod.content.items:patch('SOOTHE_BELL',{kascSeviiFriendship=B.FRIENDSHIP_OWNER})end
  function B.supportsFriendshipItem(game,id,epoch)
    local profile=game and opts.rules.peek(game)
    local item=game and game.data and game.data.items and game.data.items[id]
    return id=='SOOTHE_BELL'and item and item.kascSeviiFriendship==B.FRIENDSHIP_OWNER
      and profile and profile.extensionsEnabled and (tonumber(epoch) or 1)>=3 or false
  end
  function B.gainFriendship(game,mon,amount)
    if type(mon)~='table'or type(amount)~='number'or amount<=0 then return false end
    local profile=game and opts.rules.peek(game)
    local supported=profile and profile.extensionsEnabled and (tonumber(profile.activeEpoch) or 1)>=3
    local luxury=supported and mon._kascLuxuryBall==true
    local held=mon.item and mon.item~='NO_ITEM'and mon.item or mon.heldItem
    local soothe=supported and held=='SOOTHE_BELL'
    local gain=math.ceil(amount*(luxury and 2 or 1)*(soothe and 1.5 or 1))
    mon.johtoBond=math.min(255,math.max(0,tonumber(mon.johtoBond)or 0)+gain)
    return true
  end
  local function tokens(b,create)
    if create then b.field=b.field or{};b.field.tokens=b.field.tokens or{}end
    return b.field and b.field.tokens
  end
  function B.completedTurns(b)
    local t=tokens(b);return t and t[B.TOKEN]or 0
  end
  function B.validateCheckpoint(b)
    local t=tokens(b);local n=t and t[B.TOKEN]
    if not(n==nil or type(n)=='number'and n%1==0 and n>=0 and n<=30)then
      return false,'invalid Sevii ball turn counter'
    end
    local e=t and t[B.ENVIRONMENT]
    if e~=nil then
      if type(e)~='table'or not(e.kind=='land'or e.kind=='water'or e.kind=='underwater')
          or type(e.fishing)~='boolean'or not(e.map==false or type(e.map)=='string')
          or b.checkpointOrigin and b.checkpointOrigin.map and e.map~=b.checkpointOrigin.map then
        return false,'invalid Sevii ball environment'
      end
      for key in pairs(e)do if key~='kind'and key~='fishing'and key~='map'then return false,'unknown Sevii ball environment field'end end
    end
    return true
  end
  function B.started(ev)
    local b=ev and ev.battle
    if not b or b.kind~='wild'or b.demo then return end
    local t=tokens(b,true);if t[B.ENVIRONMENT]~=nil then return end -- checkpoint retains its original environment
    local kind=opts.environment and opts.environment(b)or'land'
    local ow=b.game and b.game.overworld
    t[B.ENVIRONMENT]={kind=kind=='underwater'and'underwater'or(kind=='water'or kind=='pond')and'water'or'land',
      fishing=b.encounterSource=='fishing',map=b.checkpointOrigin and b.checkpointOrigin.map or ow and ow.map and ow.map.id or false}
  end
  function B.endTurn(ev)
    local b=ev and ev.battle
    if not b or b.kind~='wild'or b.demo then return end
    local t=tokens(b,true);t[B.TOKEN]=math.min(30,B.completedTurns(b)+1)
  end
  function B.supports(game,id,battle)
    local p=battle and battle.kascGenerationRulesReceipt
    local enabled=p and p.mode~=opts.rules.MODE_OFF
    if not p then p=game and opts.rules.peek(game);enabled=p and p.extensionsEnabled end
    local d=game and game.data.items[id]
    return names[id]and p and enabled and p.activeEpoch>=3
      and d and d.kascSeviiBall==B.OWNER or false
  end
  local function owned(b,mon,def)
    local g=b.game;local set=g.save.pokedex and g.save.pokedex.owned or{}
    if set[mon.species]then return true end
    -- Alternate canonical runtime IDs share a Pokédex species. Seen alone,
    -- party occupancy, and an unclaimed gift never count as a previous catch.
    if def.dex then for id,yes in pairs(set)do
      local d=yes and g.data.pokemon[id]
      if d and d.dex==def.dex then return true end
    end end
    return false
  end
  function B.quote(id,b,mon,def)
    if not b or b.kind~='wild'or b.demo or b.ghost or b.noCatch
        or not B.supports(b.game,id,b)then return nil,'unavailable'end
    mon=mon or b.enemy and b.enemy.mon;def=def or b.enemy and b.enemy.def
    if not mon or not def or not tonumber(def.catchRate)or not mon.stats
        or not tonumber(mon.hp)or not tonumber(mon.stats.hp)or mon.stats.hp<=0
        or not tonumber(mon.level)then return nil,'missing_target_data'end
    local mult,reason=10,tr('NORMAL BONUS','NORMALER BONUS')
    if id=='NET_BALL'then
      local types=b.enemy and b.enemy.curTypes or def.types
      if type(types)~='table'then return nil,'missing_types'end
      for _,v in ipairs(types)do if v=='WATER'or v=='BUG'then mult=30 end end
      reason=mult==30 and tr('WATER OR BUG','WASSER ODER KÄFER')or tr('NO WATER OR BUG','KEIN WASSER/KÄFER')
    elseif id=='DIVE_BALL'then
      -- KASC's native Gen3 adapter admits water/surf/underwater. Extend that
      -- same water rule to the existing authenticated fishing marker.
      -- Never infer a water encounter from the target's type or a rod in Bag.
      local e=tokens(b)and tokens(b)[B.ENVIRONMENT]
      local water=type(e)=='table'and B.validateCheckpoint(b)and(e.kind=='water'or e.kind=='underwater'or e.fishing==true)
      mult=water and 35 or 10
      reason=water and tr('WATER ENCOUNTER','WASSERBEGEGNUNG')or tr('LAND ENCOUNTER','LANDBEGEGNUNG')
    elseif id=='NEST_BALL'then
      mult=math.max(10,40-math.max(1,math.floor(mon.level)))
      reason=tr('TARGET LEVEL ','ZIELLEVEL ')..tostring(mon.level)
    elseif id=='REPEAT_BALL'then
      local yes=owned(b,mon,def);mult=yes and 30 or 10
      reason=yes and tr('ALREADY OWNED','BEREITS BESESSEN')or tr('NOT OWNED YET','NOCH NIE BESESSEN')
    elseif id=='TIMER_BALL'then
      mult=10+B.completedTurns(b)
      reason=tr('FINISHED TURNS ','RUNDEN VORBEI ')..tostring(B.completedTurns(b))
    elseif id=='LUXURY_BALL'then
      reason=tr('FUTURE FRIENDSHIP GAINS x2','SPÄTERE FREUNDSCHAFT x2')
    end
    local max=mon.stats.hp;local hp=math.max(1,math.min(max,mon.hp))
    local rate=math.max(1,math.min(255,def.catchRate))
    local odds=math.max(1,math.floor((3*max-2*hp)*rate*mult/(30*max)))
    if mon.status=='SLP'or mon.status=='FRZ'then odds=odds*2
    elseif mon.status=='PSN'or mon.status=='TOX'or mon.status=='BRN'or mon.status=='PAR'then
      odds=math.floor(odds*1.5)
    end
    odds=math.min(255,odds)
    return {multiplier=mult/10,odds=odds,threshold=math.floor(1048560/math.sqrt(math.sqrt(16711680/odds))),
      text=tr('CATCH BONUS x','FANGBONUS x')..tostring(mult/10)..'\n'..reason}
  end
  function B.attempt(id,ctx)
    local q=B.quote(id,ctx.battle,ctx.targetMon,ctx.targetDef)
    if not q then return false,0 end
    if q.odds>=255 then return true,3 end
    for shake=0,3 do
      if ctx.rng(0,65535)>=q.threshold then return false,shake end
    end
    return true,3 -- Native Kanto animation expects 0..3, not the GBA 0..4.
  end
  function B.use(ctx)
    local q=B.quote(ctx.itemId,ctx.battle)
    if not q then return 'failed',{tr('This ball needs a catchable wild Pokemon and generation 3 rules or later.',
      'Dieser Ball braucht ein fangbares wildes Pokemon und die Regeln ab Generation 3.')}end
    return 'ball',{q.text}
  end
  for _,id in ipairs(B.ids)do
    local old=mod.content.items:get(id)
    assert(not old or not old.effect,'ball already has an effect owner: '..id)
    local effect='KA_SEVII_BALL_'..id
    local fields={name=tr(unpack(names[id])),names={en=names[id][1],de=names[id][2]},
      ball=id,effect=effect,needsTarget=false,tossable=true,keyItem=false,
      originGeneration=3,kascSeviiBall=B.OWNER}
    if old then mod.content.items:patch(id,fields)
    else fields.id=id;fields.price=id=='PREMIER_BALL'and 200 or 1000;mod.content.items:register(id,fields)end
    mod.content.balls:register(id,{randMax=255,hpFactor=12,wobbleFactor=255,
      tossAnim='ULTRATOSS_ANIM',attempt=function(ctx)return B.attempt(id,ctx)end})
    mod.content.item_effects:register(effect,{battle=true,field=false,use=B.use})
    require('src.inventory.ItemEffects').BALLS[id]=true
  end
  mod.events:on('battle.turn_ended',B.endTurn)
  mod.events:on('battle.started',B.started)
  mod.events:on('pokemon.caught',function(ev)
    if ev and ev.ball=='LUXURY_BALL'and type(ev.mon)=='table'then
      ev.mon._kascLuxuryBall=true
    end
  end)
  -- The current host's rod path calls BattleState.newWild(opts.hooked=true)
  -- directly; its unused battle.wild hook does not stamp encounterSource.
  -- Preserve the native constructor's exact rod receipt for Dive and the
  -- existing Lure Ball owner before battle.started freezes the environment.
  local Battle=require('src.battle.BattleState')
  Battle._kascSeviiBallOwner=B
  if not Battle._kascSeviiBallWrapped then
    local original=Battle.newWild
    Battle.newWild=function(game,species,level,options)
      local battle=original(game,species,level,options)
      if battle and options and options.hooked==true then battle.encounterSource='fishing'end
      return battle
    end
    Battle._kascSeviiBallWrapped=true
  end
  return B
end
