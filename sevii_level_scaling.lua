-- First-cycle authored levels remain floors. A Legacy Journey may reach
-- Sevii before the League, so only that cycle follows the active party both
-- downward and upward. This policy never touches Kanto maps.
return function(S,opts)
  local L={OWNER='kasc.sevii-level-scaling/v1'}
  local function integer(value)
    return type(value)=='number'and value%1==0 and value>=1 and value<=100
  end
  function L.reference(game)
    local save=game and game.save
    if not(save and type(save.party)=='table')then return nil end
    local total,count,highest=0,0,0
    for _,mon in ipairs(save.party)do
      if type(mon)=='table'and not(mon.isEgg or mon.egg or mon.eggSpecies)
          and integer(mon.level)and(not game.data or not game.data.pokemon
            or game.data.pokemon[mon.species])then
        total=total+mon.level;count=count+1;highest=math.max(highest,mon.level)
      end
    end
    if count==0 then return nil end
    -- A single high-level partner must not become harmless merely because
    -- the player carries several low-level utility Pokémon.
    return math.max(math.floor(total/count+0.5),highest-8)
  end
  function L.level(game,authored,kind,ace)
    if not integer(authored)then return authored end
    local map=game and game.overworld and game.overworld.map
    if not(map and S.maps[map.id])then return authored end
    local reference=L.reference(game)
    if not reference then return authored end
    local offset=kind=='wild'and -10 or kind=='legend'and 2 or 0
    if kind=='trainer'and ace then offset=offset+2 end
    if opts.legacyJourney and opts.legacyJourney.isActive(game.save)then
      local legacyOffset=kind=='wild'and -3 or kind=='legend'and 8
        or ace and 4 or 2
      local floor=kind=='wild'and 2 or kind=='legend'and 15 or 5
      return math.min(100,math.max(floor,reference+legacyOffset))
    end
    return math.min(100,math.max(authored,reference+offset))
  end
  function L.legend(game,authored)return L.level(game,authored,'legend')end
  function L.wild(game,authored)return L.level(game,authored,'wild')end
  function L.trainer(game,authored,ace)return L.level(game,authored,'trainer',ace)end
  return L
end
