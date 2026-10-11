-- Shared per-run battle owner for authored post-expedition mysteries.
-- Runtime capabilities are never serialized or inferred from a battle tag.
return function(S,opts)
  local E={rows={}}
  local active=setmetatable({},{__mode='k'})
  local allowed={[377]=true,[378]=true,[379]=true,[480]=true,[481]=true,[482]=true,[483]=true,[484]=true,[486]=true,
    [488]=true,[489]=true,[490]=true,[491]=true,[492]=true,[493]=true}
  function E.register(id,row)
    assert(not E.rows[id]and allowed[row.dex],'invalid special encounter '..id)
    assert(row.site and S.maps[row.site.map]and type(row.ready)=='function','missing special encounter site/quest')
    E.rows[id]=row;return row
  end
  function E.level(game,id)
    local row=E.rows[id]
    if not row then return nil end
    return S.scaling and S.scaling.legend(game,row.level)or row.level
  end
  function E.near(game,p)
    local ow=game and game.overworld;local a=ow and ow.player
    return p and ow and ow.map and a and ow.map.id==p.map
      and math.abs(a.cellX-p.x)+math.abs(a.cellY-p.y)==1
  end
  function E.storyReady(game)
    if not S.unlocked(game)then return false,'league-required'end
    local s=S.state()
    if not(s.expeditionComplete and s.seviiRiftSealed)then return false,'finale-required'end
    if opts.beyondKanto and not opts.beyondKanto.peekIsActive(game)then return false,'beyond-kanto-sealed'end
    return true
  end
  function E.availability(game,id)
    local row=E.rows[id];if not row then return false,'unknown-encounter'end
    local ok,why=E.storyReady(game);if not ok then return false,why end
    local owner=opts.backendSpecies and opts.backendSpecies();local key='dex:'..row.dex
    local species=owner and owner.byKey[key];local def=species and game.data.pokemon[species]
    if not def or owner.bySpecies[species]~=key then return false,'species-unavailable'end
    if not opts.generationRules.peekSpeciesAvailable(game,species,def)then return false,'generation-profile'end
    if not S.assetsReady(species,def)then return false,'missing-art'end
    local history=S.legendPolicy and S.legendPolicy.history
    if not history then return false,'legend_history_unavailable'end
    local owned,err=(history.ownedThisRun or history.owned)(game,species)
    if owned then return false,'legend_owned'end
    if err then return false,'legend_history_unavailable'end
    local ready,reason=row.ready(game)
    if not ready then return false,reason or 'trial-required'end
    return true,species
  end
  function E.canCapture(game,battle,species)
    local a=game and active[game]
    if not a or a.battle~=battle or a.save~=game.save or a.finished
        or battle.game~=game or battle.kind~='wild'or species~=a.species
        or not battle.enemy or battle.enemy.mon.species~=species
        or not game.overworld or game.overworld.map.id~=a.row.site.map then return false end
    local ok,resolved=E.availability(game,a.id);if not ok or resolved~=species then return false end
    for _,screen in ipairs(game.stack.states or{})do if screen==battle then return true end end
    return false
  end
  function E.start(game,id)
    local row=E.rows[id]
    if not row or not E.near(game,row.site)then return false,'not-at-site'end
    if game.stack:top()~=game.overworld then return false,'not-in-overworld'end
    local ok,species=E.availability(game,id);if not ok then return false,species end
    local healthy=false
    for _,m in ipairs(game.save.party or{})do
      if (m.hp or 0)>0 and not(m.isEgg or m.egg or m.eggSpecies)then healthy=true end
    end
    if not healthy then return false,'no-healthy-party'end
    if active[game]then active[game].finished=true;active[game]=nil end
    if type(game.writeSave)~='function'or game:writeSave()==false then return false,'save-failed'end
    local b=require('src.battle.BattleState').newWild(game,species,E.level(game,id),{
      randomizerProtected=true,encounterSource='sevii-special-'..id})
    local a={battle=b,save=game.save,species=species,row=row,id=id};active[game]=a
    b.onFinish=function(result)
      if a.finished then return end;a.finished=true
      if active[game]==a then active[game]=nil end
      if game.save~=a.save then return end
      if result=='caught'and S.legendPolicy.history.owned(game,species)then
        local s=S.state();s.specialCaptures=s.specialCaptures or{};s.specialCaptures[id]=true;S.persist(s)
      end
      game.overworld:afterBattle(result,b)
    end
    game.overworld:pushBattle(b);return true,b
  end
  return E
end
