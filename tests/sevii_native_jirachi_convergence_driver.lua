-- Isolated native check: with Sevii installed Jirachi has only the
-- Victory Road convergence entrance, even after the full Hoenn record.
return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'))
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  game:startNewGame{intro=false}
  local K=assert(game.mods.exports.kanto_ascendant)
  Q.K=K
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true
  game.save.flags.EVENT_GOT_STARTER=true
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'DRAGONITE',70)}
  if os.getenv('SEVII_JIRACHI_NGPLUS')=='1'then
    local history=K.seviiExpedition.legendPolicy.history
    local localMod=game.save.modData.kanto_ascendant
    localMod.hevo_persistent=localMod.hevo_persistent or{}
    localMod.hevo_persistent[history.KEY]={[tostring(history.ids.JIRACHI)]=true}
    localMod.hevo_persistent.secretUnlocks={KA_LEGEND_CAPTURE_JIRACHI=true}
    assert(history.sync(game)and K.hoennJirachiFinale67.caught(game),
      'old Jirachi capture fixture')
  end
  Q.ngplus('RED')
  local J,D,H=K.hoennJirachiFinale67,K.hoennDexCompletion67,K.hiddenAccessReveal
  local A=K.legacyJourney.archive
  if os.getenv('SEVII_JIRACHI_NGPLUS')=='1'then
    local history=K.seviiExpedition.legendPolicy.history
    assert(history.owned(game,'JIRACHI')and not history.ownedThisRun(game,'JIRACHI')
      and not J.caught(game),'old Jirachi must reopen in NG+')
  end
  assert(K.seviiExpedition.available,'Sevii map import required')
  game.save.inventory.HOENN_DEX=1
  game.save.inventory.HOENN_HONEY=1
  game.save.flags.EVENT_GOT_POKEDEX=true
  for _,species in ipairs(D.order)do assert(D.record(game,species))end
  for _,character in ipairs{'RED','BLUE','GREEN'}do
    assert(A.completeHevoPath(game.save,character))
  end
  assert(A.completeFinale(game.save))
  local persistent=game.save.modData.kanto_ascendant.hevo_persistent
  persistent.secretUnlocks=persistent.secretUnlocks or{}
  for _,flag in pairs(D.portalLegends)do persistent.secretUnlocks[flag]=true end
  assert(D.report(game).jirachiDexReady,'all 134 other Hoenn species recorded')
  assert(J.available(game),'Jirachi finale unlocked')
  local entered,why=J.enter(game)
  assert(not entered and why=='convergence-door-only',
    'old captain shortcut must be closed with Sevii installed')
  local door
  for _,definition in ipairs(H.definitions())do
    if definition.eligibility.kind=='jirachi_convergence'then door=definition;break end
  end
  assert(door and door.id=='VICTORY_ROAD_JIRACHI_ACCESS')
  assert(door.mapId=='VICTORY_ROAD_1F'
    and door.handoff.destination.map==J.MAP,'wish chamber bound to convergence door')
  local allowed,reason=H.available(game,door)
  assert(allowed,'convergence gate unavailable: '..tostring(reason))
  if os.getenv('SEVII_JIRACHI_NGPLUS')=='1'then
    local U=require('tests.drivers.util')
    U.teleport(game,J.MAP,8,5,'up');Q.settle()
    Q.faceObject(8,4);Q.tap('a')
    for _=1,1200 do
      local screen=game.stack:top()
      if screen.enemy and screen.phase=='menu'then
        assert(screen.enemy.mon.species=='JIRACHI',
          'reopened wish encounter has the wrong species')
        print('SEVII_JIRACHI_NGPLUS_BATTLE_PASS')
        print('SEVII_JIRACHI_NGPLUS_MENU_INDEX',screen.menuIndex)
        Q.catch('JIRACHI',true,'left')
        local history=K.seviiExpedition.legendPolicy.history
        assert(J.caught(game)and history.ownedThisRun(game,'JIRACHI'),
          'new-run Jirachi capture was not recorded')
        assert(not K.seviiExpedition.legendPolicy.captureAllowed(game,'JIRACHI'),
          'second Jirachi catch in this NG+ must be blocked')
        print('SEVII_JIRACHI_NGPLUS_CAPTURE_PASS')
        love.event.quit();return
      end
      Q.tap('a')
    end
    error('reopened Jirachi battle did not start')
  end
  print('SEVII_JIRACHI_CONVERGENCE_ONLY_NATIVE_PASS')
  love.event.quit()
end
