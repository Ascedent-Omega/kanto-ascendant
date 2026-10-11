return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'))
  local U=require('tests.drivers.util')
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=assert(game.mods.exports.kanto_ascendant)
  local S=assert(K.seviiExpedition)
  local G=assert(S.sleepingGiant)
  local E=assert(S.specialEncounters)
  local old=assert(K.hoennResearchSanctums67)
  local requested=os.getenv('SEVII_REGI_SPECIES')or'REGIROCK'
  assert(G.guardians[requested],'unknown Regi test species')
  require('src.world.OverworldController').rollEncounter=function()return nil end
  game:startNewGame{intro=false}
  if os.getenv('SEVII_REGI_NGPLUS')=='1'then
    local H=S.legendPolicy.history
    local oldSave=game.save
    oldSave.flags.EVENT_BEAT_CHAMPION_RIVAL=true
    oldSave.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',70)}
    local localMod=oldSave.modData.kanto_ascendant
    localMod.hevo_persistent=localMod.hevo_persistent or{}
    localMod.hevo_persistent[H.KEY]={[tostring(H.ids[requested])]=true}
    assert(H.sync(game)and H.ownedThisRun(game,requested),'old Regi fixture')
    local A=K.legacyJourney.archive
    assert(A.beginJourney(oldSave,{pact='journey',bankPolicy='sealed',
      itemPolicy='empty',runRules=A.safeRunRulesSnapshot(oldSave),playerAvatar='RED'}))
    game:startNewGame{intro=false}
    assert(H.owned(game,requested)and not H.ownedThisRun(game,requested),
      'old Regi reopens in NG+')
  end
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true
  game.save.flags.EVENT_GOT_STARTER=true
  game.save.flags.EVENT_GOT_POKEDEX=true
  game.save.hallOfFame={{}}
  game.save.inventory.HOENN_DEX=1
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'DRAGONITE',100)}
  assert(S.begin(game))
  assert(K.beyondKanto.activate(game,{decision='qa-tanoby-regi-seals'}))
  local state=S.state()
  state.expeditionComplete=true;state.seviiRiftSealed=true
  state.mysteries=state.mysteries or{}
  state.mysteries.sleepingGiant={briefed=true,balanced=true,complete=true,
    title='SEVII_SLEEPING_GIANT',clues={ROCK=true,ICE=true,STEEL=true},weights={6,3,1}}
  S.persist(state)
  assert(old.researchEligible(game),'original Hoenn research still gates Tanoby')
  assert(not old.available(game),'old Regi sanctuaries remain closed')
  for _,row in ipairs(old.rows)do assert(not old.enter(game,row),'old Regi entrance reopened')end
  for _,species in ipairs{requested}do
    local available,why=E.availability(game,species)
    assert(available,'Tanoby guardian unavailable '..species..': '..tostring(why))
    local site=G.sites[G.guardians[species]]
    local entry
    for _,step in ipairs{{0,1},{0,-1},{1,0},{-1,0}}do
      if S.walkable(site.map,site.x+step[1],site.y+step[2])then
        entry={site.x+step[1],site.y+step[2]};break
      end
    end
    assert(entry,'no standing cell for '..species)
    U.teleport(game,site.map,entry[1],entry[2],'up');Q.settle()
    Q.faceObject(site.x,site.y);Q.tap('a');U.wait(8)
    assert(game.stack:top().items,'Tanoby encounter menu missing '..species)
    Q.choose(function(row)return row.value=='battle'end)
    for _=1,1200 do
      local battle=game.stack:top()
      if battle.enemy and battle.phase=='menu'then
        assert(battle.enemy.mon.species==species,'wrong Tanoby guardian')
        print('SEVII_REGI_TANOBY_BATTLE_NATIVE_PASS',species)
        if os.getenv('SEVII_REGI_CAPTURE')=='1'then
          battle.menuIndex=1
          Q.catch(species,true,'left')
          assert(S.legendPolicy.history.owned(game,species),'Tanoby guardian not recorded')
          print('SEVII_REGI_TANOBY_CAPTURE_NATIVE_PASS',species)
        end
        love.event.quit();return
      end
      Q.tap('a')
    end
    error('Tanoby battle failed to start '..species)
  end
end
