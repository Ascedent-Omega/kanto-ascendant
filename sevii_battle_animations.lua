-- Verified native-animation gaps in the Sevii habitat/trainer catalogue.
-- Only the battle's AnimPlayer changes; shared move data and effects do not.
return function(mod,S)
  local M={OWNER='kasc.sevii-battle-animations/v1',aliases={
    BONE_RUSH='BONEMERANG',CHARM='GROWL',DISCHARGE='THUNDERBOLT',DOUBLE_HIT='DOUBLESLAP',
    FALSE_SWIPE='SLASH',LEAF_BLADE='RAZOR_LEAF',MACH_PUNCH='COMET_PUNCH',
    MEGAHORN='HORN_ATTACK',MUD_SLAP='SAND_ATTACK',RAIN_DANCE='SURF',
    SHOCK_WAVE='THUNDERSHOCK',SPARK='THUNDERSHOCK',SUNNY_DAY='FLASH',SWEET_KISS='LOVELY_KISS',
    SYNTHESIS='RECOVER',THUNDER_FANG='THUNDERSHOCK',WHIRLPOOL='CLAMP',
    VITAL_THROW='SEISMIC_TOSS',ZAP_CANNON='THUNDER',
  }}
  -- Explicit Gen1 compositions retain the type/contact family. Recovery
  -- and weather reuse native recovery, light and whole-field water effects.
  local function ownedMap(game)
    local map=game and game.overworld and game.overworld.map
    local expected=map and S.maps[map.id];local def=map and map.def
    if not(expected and def and def.kaSeviiSource==expected.kaSeviiSource
        and def.tileset==expected.tileset and def.width==expected.width
        and def.height==expected.height and def.kaSeviiIsland==expected.kaSeviiIsland)then return end
    return map.id
  end
  function M.bind(battle,candidate)
    local map=ownedMap(battle and battle.game);local player=candidate or battle and battle.animPlayer
    -- VASC keeps its custom programs on a composite player and delegates
    -- native sound/OAM to this existing child. Bind the child so custom
    -- programs keep their own move id, target mode and presentation.
    if player and not player.data and player.native then player=player.native end
    if not map then return false,'map-contract' end
    if not(player and type(player.start)=='function'
        and player.data and type(player.data.moveAnims)=='table')then return false,'native-player' end
    if player._kascSeviiAnimations then return false,'already-bound' end
    local original=player.start;local reported={}
    player._kascSeviiAnimations=M.OWNER
    player.start=function(self,id,side,...)
      local animations=self.data and self.data.moveAnims
      local donor=animations and not animations[id] and M.aliases[id]
      if donor and animations[donor]then
        if not reported[id]then
          reported[id]=true
          if mod.log and mod.log.info then mod.log:info(
            'Sevii animation map='..map..' move='..id..' native='..donor..' owner='..M.OWNER)end
        end
        return original(self,donor,side,...)
      end
      if animations and not animations[id]and not reported[id]then
        reported[id]=true
        if mod.log and mod.log.warn then mod.log:warn(
          'Sevii animation missing map='..map..' move='..tostring(id)
          ..' native='..tostring(donor)..' owner='..M.OWNER)end
      end
      return original(self,id,side,...)
    end
    return true
  end
  mod.events:on('battle.started',function(event)M.bind(event.battle)end,10000)
  return M
end
