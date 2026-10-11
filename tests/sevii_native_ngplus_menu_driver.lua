-- Native Legacy terminal/menu handoff, through the final YES choice and
-- engine-created fresh save. The old completed path is an isolated fixture.
return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'))
  local U=require('tests.drivers.util')
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=assert(game.mods.exports.kanto_ascendant)
  local J=assert(K.legacyJourney)
  local H=assert(K.seviiExpedition.legendPolicy.history)
  game:startNewGame{intro=false}
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true
  game.save.flags.EVENT_GOT_STARTER=true
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',70)}
  local bucket=game.save.modData.kanto_ascendant
  bucket.hevo_run={dungeonLegacy={seals={RED=true}}}
  bucket.hidden_evolution_story_campaign={doorVisits={RED=true}}
  assert(J.reconcileHevoSealGate(game.save))
  assert(J.canBegin(game.save),'completed current RED path opens Legacy')
  local oldRun=game.save
  oldRun.pokedex.owned.ARTICUNO=true
  oldRun.boxes[1][1]=require('src.pokemon.Pokemon').new(game.data,'ARTICUNO',50)
  assert(H.sync(game)and H.ownedThisRun(game,'ARTICUNO'))

  assert(J.openLabTerminal(game),'real terminal menu opens')
  local function untilMenu(expected)
    for _=1,2500 do
      local t=game.stack:top()
      if t and t.items then
        print('LEGACY_MENU',tostring(t.title))
        assert(not expected or tostring(t.title):find(expected,1,true),
          'unexpected menu '..tostring(t.title))
        return t
      end
      if t and t.screenId=='OakSpeech'then return t end
      if t and t.labels and t.onChoose then return t end
      if t and (t.isTextBox or t.pages)then Q.tap('a')else U.wait(1)end
    end
    error('Legacy flow did not reach next menu')
  end
  untilMenu('KASC TERMINAL')
  Q.choose(function(v)return v.value=='legacy_journey'end)
  untilMenu('PACT')
  Q.choose(function(v)return v.value=='journey'or v.value=='JOURNEY'end)
  untilMenu('BANK')
  Q.choose(function(v)return v.value=='sealed'or v.value=='SEALED'end)
  untilMenu('ITEM')
  Q.choose(function(v)return v.value=='safe'or v.value=='SAFE'end)
  untilMenu('RULES')
  Q.choose(function(v)return v.key=='done'end)
  local choice=untilMenu()
  assert(choice.labels and choice.index==2,'irreversible final choice defaults to NO')
  assert(game.save==oldRun and H.ownedThisRun(game,'ARTICUNO'),
    'all preceding menus leave the original run intact')
  Q.tap('up');assert(choice.index==1,'player must explicitly choose YES')
  Q.tap('a')
  for _=1,500 do
    if game.save~=oldRun then break end
    U.wait(1)
  end
  assert(game.save~=oldRun,'final YES created a new engine save')
  assert(game.stack:top().screenId=='OakSpeech',
    'new Legacy cycle starts in the normal Oak identity flow')
  assert(H.owned(game,'ARTICUNO')and not H.ownedThisRun(game,'ARTICUNO'),
    'old legendary remains archived and is catchable in the new cycle')
  assert(K.seviiExpedition.legendPolicy.captureAllowed(game,'ARTICUNO'))
  for _=1,3000 do
    local t=game.stack:top()
    if t==game.overworld and game.overworld.map.id=='OAKS_LAB'
        and not game.overworld.transitioning then break end
    if t and t.items then
      if #t.items>1 and tostring(t.items[1].label)=='NEW NAME' and t.index==1
        then Q.tap('down')else Q.tap('a')end
    elseif t and getmetatable(t)==require('src.ui.NamingScreen') then
      Q.tap('start')
    elseif t and t.portraits and t.done then
      if t.confirming and not t.confirmYes then
        Q.tap('up')
        if not t.confirmYes then Q.tap('left')end
      else Q.tap('a')end
    elseif t and t.labels and t.onChoose then Q.tap('a')
    elseif t and (t.isTextBox or t.pages)then Q.tap('a')
    else U.wait(3)end
  end
  assert(game.overworld.map.id=='OAKS_LAB'
    and game.stack:top()==game.overworld,
    'normal Oak identity and naming flow reaches the new-run lab')
  assert(J.isActive(game.save)and H.owned(game,'ARTICUNO')
    and not H.ownedThisRun(game,'ARTICUNO'),
    'historical legend remains separate from new-run ownership after intro')
  print('SEVII_NATIVE_NGPLUS_MENU_PASS')
  love.event.quit()
end
