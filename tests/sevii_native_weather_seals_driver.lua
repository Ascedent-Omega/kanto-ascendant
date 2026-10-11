return function(game)
  io.stdout:setvbuf('no')
  local K=assert(game.mods.exports.kanto_ascendant)
  local S=assert(K.seviiExpedition)
  local P=assert(K.hoennLegendPortals67)
  local G=assert(K.hoennResearchSanctums67)
  assert(S.weatherTrio and S.weatherTrio.sites.RED and S.weatherTrio.sites.BLUE
    and S.weatherTrio.sites.GREEN,'three authored Sevii weather sites')
  game:startNewGame{intro=false}
  if os.getenv('SEVII_WEATHER_NGPLUS')=='1'then
    local H=S.legendPolicy.history
    local character=os.getenv('SEVII_WEATHER_CHARACTER')or'RED'
    local prior=assert(P.rows[character])
    local old=game.save
    old.flags.EVENT_BEAT_CHAMPION_RIVAL=true
    old.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',70)}
    local localMod=old.modData.kanto_ascendant
    localMod.hevo_persistent=localMod.hevo_persistent or{}
    localMod.hevo_persistent[H.KEY]={[tostring(H.ids[prior.species])]=true}
    localMod.hevo_persistent.secretUnlocks={[prior.flag]=true}
    assert(H.sync(game)and P.caught(game,prior),'old weather catch fixture')
    local A=K.legacyJourney.archive
    assert(A.beginJourney(old,{pact='journey',bankPolicy='sealed',
      itemPolicy='empty',runRules=A.safeRunRulesSnapshot(old),playerAvatar=character}))
    game:startNewGame{intro=false}
    assert(H.owned(game,prior.species)and not H.ownedThisRun(game,prior.species)
      and not P.caught(game,prior),'old weather catch opens in NG+')
  end
  if os.getenv('SEVII_WEATHER_CAPTURE')=='1'
      and os.getenv('SEVII_WEATHER_CAPTURE_ORAS')~='1'then
    game.save.options.modOptions=game.save.options.modOptions or{}
    game.save.options.modOptions.VOXEL_ASCENDANT={battleHudStyle='standard'}
  end
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  assert(not G.available(game),'former Regi sanctuaries must be closed')
  for _,row in ipairs(G.rows)do assert(not G.enter(game,row),'old Regi entrance open')end
  assert(not P.enter(game,P.rows.RED),'old weather door must not start a capture route')
  for character,site in pairs(S.weatherTrio.sites)do
    assert(S.maps[site.map]and S.walkable(site.map,site.x,site.y),
      'missing Sevii weather location '..character)
    local found=false
    for _,object in ipairs(S.maps[site.map].objects)do
      if object.name==site.name then found=true end
    end
    assert(found,'missing physical weather seal '..character)
  end
  local U=require('tests.drivers.util')
  local root=assert(os.getenv('SEVII_KASC_ROOT'))
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  require('src.world.OverworldController').rollEncounter=function()return nil end
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true
  game.save.flags.EVENT_GOT_STARTER=true
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'DRAGONITE',100)}
  game.save.inventory.HOENN_DEX=1
  assert(S.begin(game),'expedition unlocks Hoenn profile')
  assert(K.beyondKanto.activate(game,{decision='qa-weather-seals'}))
  local state=S.state();state.expeditionComplete=true;state.seviiRiftSealed=true;S.persist(state)
  local D=K.hoennDexCompletion67
  local ownSeal=K.legacyJourney.currentHevoSeal
  local doorVisit=K.legacyJourney.currentHevoDoorVisit
  K.legacyJourney.currentHevoSeal=function(_,character)return true,character end
  K.legacyJourney.currentHevoDoorVisit=function()return true end
  for _,id in ipairs(D.foundationOrder)do assert(D.record(game,id))end
  K.generationRules.resolve(game)
  local report=D.report(game)
  print('SEVII_WEATHER_DEX_GATE',report.foundationRequired,#report.foundationMissing,
    tostring(report.generationReady))
  assert(report.portalReady,'130-species event threshold')
  local requested=os.getenv('SEVII_WEATHER_CHARACTER')or'RED'
  assert(P.rows[requested],'unknown weather test character')
  for _,character in ipairs{requested}do
    K.extendedCharacters.select(character)
    local site=S.weatherTrio.sites[character]
    assert(P.available(game,character),'character-specific Dex and shrine gates '..character)
    local entry
    for _,step in ipairs{{0,1},{0,-1},{1,0},{-1,0}}do
      if S.walkable(site.map,site.x+step[1],site.y+step[2])then
        entry={site.x+step[1],site.y+step[2]};break
      end
    end
    assert(entry,'weather seal has no standing cell '..character)
    U.teleport(game,site.map,entry[1],entry[2],'up');Q.settle()
    Q.faceObject(site.x,site.y);Q.tap('a');U.wait(8)
    assert(S.state().weatherSealAwakened[character],
      'Dex threshold did not awaken physical weather event '..character)
    Q.settle()
    Q.tap('a');U.wait(8)
    local top=game.stack:top()
    assert(top.items,'awakened weather seal has no approach menu '..character)
    Q.choose(function(row)return row.value=='approach'end)
    local battle
    for _=1,1200 do
      local screen=game.stack:top()
      if screen.enemy and screen.phase=='menu'then battle=screen;break end
      Q.tap('a')
    end
    assert(battle and battle.enemy.mon.species==P.rows[character].species,
      'canonical weather battle did not start '..character)
    print('SEVII_WEATHER_BATTLE_NATIVE_PASS',character)
    if os.getenv('SEVII_WEATHER_CAPTURE')=='1'then
      battle.menuIndex=1
      Q.catch(P.rows[character].species,true,
        os.getenv('SEVII_WEATHER_CAPTURE_ORAS')=='1'and'left'or'down')
      assert(P.caught(game,P.rows[character]),'capture seal missing '..character)
      print('SEVII_WEATHER_CAPTURE_NATIVE_PASS',character)
    end
  end
  K.legacyJourney.currentHevoSeal=ownSeal
  K.legacyJourney.currentHevoDoorVisit=doorVisit
  print('SEVII_WEATHER_SEALS_NATIVE_PASS')
  love.event.quit()
end
