-- A real held Everstone for the Kanto host's shared evolution dispatcher.
-- The item remains ordinary equipment; only a post-League island find is new.
return function(mod,opts)
  local E={OWNER='kasc.sevii-everstone/v1',ITEM='EVERSTONE'}
  local old=mod.content.items:get(E.ITEM)
  if old then mod.content.items:patch(E.ITEM,{kascSeviiEverstone=E.OWNER})end
  function E.supportsItem(game,id,epoch)
    local p=game and opts.rules.peek(game)
    local def=game and game.data and game.data.items and game.data.items[id]
    return id==E.ITEM and def and def.kascSeviiEverstone==E.OWNER
      and p and p.extensionsEnabled and (tonumber(epoch) or 1)>=2 or false
  end
  function E.held(mon)
    if type(mon)~='table'then return false end
    local a,b=mon.item,mon.heldItem
    if a~=nil and a~=false and a~=''and a~='NO_ITEM'
        and b~=nil and b~=false and b~=''and b~='NO_ITEM'and a~=b then return false end
    return a==E.ITEM or b==E.ITEM
  end
  function E.blocks(game,mon,trigger)
    local p=game and opts.rules.peek(game)
    return p and p.extensionsEnabled and (tonumber(p.activeEpoch) or 1)>=2
      and E.held(mon) and not(trigger and trigger.kind=='item-check') or false
  end
  mod.hooks:wrap('evolution.check',function(nextCheck,game,mon,evo,trigger)
    if E.blocks(game,mon,trigger)then return false end
    return nextCheck(game,mon,evo,trigger)
  end,9600)
  return E
end
