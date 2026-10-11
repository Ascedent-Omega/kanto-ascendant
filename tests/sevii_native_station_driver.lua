return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util')
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local S=assert(game.mods.exports.kanto_ascendant.seviiExpedition);local P=assert(S.chapters.station)
  require('src.world.OverworldController').rollEncounter=function()return nil end
  local uiOnly=os.getenv('SEVII_STATION_UI_ONLY')=='1'
  if uiOnly then game:restoreSave(assert(require('src.core.SaveData').load('red')))
  else game:startNewGame{intro=false}end
  game.save.options.colors='redpp';game:applyOptions()
  game.mods.modOptions.kanto_ascendant.living_world_enabled=false
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',70)}
  local function qs()return S.state().chapters and S.state().chapters.five or{}end
  local function reload()
    assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  end
  local function talkAt(site)
    Q.faceObject(site.x,site.y);Q.tap('a');U.wait(8)
  end
  local function menuReady()
    for _=1,1800 do
      local top=game.stack:top()
      if top.items then return end
      assert(top~=game.overworld,'power menu unexpectedly closed')
      Q.tap('a')
    end
    error('power menu never returned')
  end
  local function choose(value)
    menuReady()
    local top=game.stack:top();local wanted
    for i,row in ipairs(top.items)do if row.value==value then wanted=i end end
    assert(wanted,'missing station menu value '..value)
    for attempt=1,60 do
      if top.index==wanted then Q.tap('a');U.wait(5);return end
      Q.tap(top.index>wanted and'up'or'down')
    end
    U.shot(game,out..'/station-menu-failure.png')
    error('station menu selection stuck '..value..' '..tostring(top.index))
  end
  local function crew()
    local found={}
    for _,n in ipairs(game.overworld.npcs)do
      if n.def.name and n.def.name:find('KA_SEVII_STATION_FOLLOW_',1,true)==1 then found[#found+1]=n end
    end
    return found
  end
  if uiOnly then
    Q.settle();assert(S.state().chapterFiveComplete,'UI smoke requires completed QA station profile')
    talkAt(P.sites.CONSOLE);menuReady()
    local panel=game.stack:top()
    assert(panel.kind=='sevii-station-power'and panel.__vascHeaderLabel=='GEZEITENLINIE')
    assert(type(panel.ascendantFocusHelp)=='function','contextual circuit help')
    assert(U.shot(game,out..'/station-console-final.png'))
    choose('CLOSE');Q.settle();assert(game.stack:top()==game.overworld)
    print('SEVII_NATIVE_STATION_UI_PASS','station label, help and close')
    love.event.quit();return
  end
  U.teleport(game,P.map,24,24,'up');Q.settle()
  talkAt(P.sites.NOAH);Q.settle();assert(not qs().briefed,'League gate on actual conversation')
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  talkAt(P.sites.NOAH);Q.settle();assert(not qs().briefed,'chapter four gate on actual conversation')
  -- An older save inside the newly closed room must retain a way out.
  U.teleport(game,P.map,23,5,'down');Q.settle()
  talkAt(P.sites.EMERGENCY);Q.settle()
  assert(game.overworld.map:isWalkableCell(22,8),'inside emergency exit is physically open')
  assert(not qs().rescued and not S.state().chapterFiveComplete,'emergency exit grants no progress')
  U.teleport(game,P.map,24,24,'up');Q.settle()
  -- Earlier chapters are independently tested. This fixture represents a
  -- complete chapter-four save and isolates the station's native gameplay.
  S.persist({version=1,stage=3,samples={heat=true,drift=true},chapterOneComplete=true,
    chapterTwoComplete=true,chapterThreeComplete=true,chapterFourComplete=true,
    chapters={two={archiveRead=true,decoded=true,complete=true},
      three={found=true,rescued=true,complete=true},four={briefed=true,recordRead=true,traced=true,complete=true}}})
  S.install(game);Q.settle()
  assert(not game.overworld.map:isWalkableCell(22,8),'closed airlock collision restored')
  Q.walkTo(22,9);Q.settle();U.hold(game,'up',24);Q.settle()
  assert(game.overworld.player.cellY==9,'actual movement cannot cross closed door')
  assert(U.shot(game,out..'/station-gate-closed.png'))
  talkAt(P.sites.NOAH);Q.settle();assert(qs().briefed,'native engineer briefing')
  talkAt(P.sites.CONSOLE);choose('AIR');menuReady()
  assert(not qs().circuits.AIR,'probe must first be isolated')
  choose('ISOLATE');choose('AIR');choose('RADIO');menuReady()
  assert(qs().isolated and qs().circuits.AIR and not qs().circuits.RADIO,'overload rejected without losing air')
  choose('DOOR');menuReady()
  assert(P.load()==3 and game.overworld.map:isWalkableCell(22,8),'allocated power opens native door')
  assert(U.shot(game,out..'/station-power-rescue.png'))
  choose('CLOSE');Q.settle();reload()
  assert(P.load()==3 and game.overworld.map:isWalkableCell(22,8),'allocation and actual door survive reload')
  talkAt(P.sites.ADA);Q.settle()
  assert(qs().escorting and #crew()==3,'actual conversation creates all three followers')
  U.teleport(game,S.harbors[5],8,4,'down');Q.settle()
  assert(not qs().escorting and qs().separated,'leaving mission is recoverable')
  U.teleport(game,P.map,24,24,'up');Q.settle()
  -- From this point through assembly, no teleport or direct quest API.
  talkAt(P.sites.ADA);Q.settle();assert(qs().escorting and #crew()==3)
  for _,n in ipairs(crew())do assert(n.passable,'followers cannot block player')end
  Q.walkTo(24,19);Q.settle()
  assert(qs().escorting and #crew()==3,'entire group reaches lower corridor')
  assert(U.shot(game,out..'/station-evacuation.png'))
  local oldPositions={}
  -- A save can occur while a follower is still interpolating its last step.
  -- The quest stores the completed cell target, not sub-tile animation time.
  for index,c in ipairs(P.crew)do
    local p=qs().positions[index]
    oldPositions['KA_SEVII_STATION_FOLLOW_'..c.id]={p.x,p.y}
  end
  for _,n in ipairs(crew())do
    local p=oldPositions[n.def.name]
    assert((n.targetX or n.cellX)==p[1]and(n.targetY or n.cellY)==p[2],
      'saved position is the actual native step destination: '..n.def.name)
  end
  reload()
  assert(qs().escorting and #crew()==3,'all companions restored after native reload')
  for _,n in ipairs(crew())do
    local p=assert(oldPositions[n.def.name]);assert(n.cellX==p[1]and n.cellY==p[2], 'companion position retained: '..n.def.name..' '..n.cellX..','..n.cellY..' expected '..p[1]..','..p[2])
  end
  Q.walkTo(24,24);Q.settle()
  assert(qs().rescued and not qs().escorting and #crew()==0,'complete group arrives at assembly')
  assert(not S.state().chapterFiveComplete,'radio report required')
  for _,c in ipairs(P.crew)do
    local found=false
    for _,n in ipairs(game.overworld.npcs)do if n.def.name=='KA_SEVII_STATION_'..c.id..'_SAFE'then found=true end end
    assert(found,'rescued actor visible at assembly: '..c.id)
  end
  assert(U.shot(game,out..'/station-assembly.png'))
  talkAt(P.sites.CONSOLE);choose('CALL');menuReady()
  assert(not S.state().chapterFiveComplete,'unpowered radio cannot complete chapter')
  choose('AIR');choose('RADIO');menuReady()
  assert(P.load()==3 and game.overworld.map:isWalkableCell(22,8),'secured door stays open after power transfer')
  assert(U.shot(game,out..'/station-power-radio.png'))
  choose('CALL');Q.settle()
  assert(S.state().chapterFiveComplete,'actual radio conversation completes chapter five')
  reload()
  assert(S.state().chapterFiveComplete and S.state().chapterFourComplete and S.state().samples.heat,'whole history preserved')
  assert(not S.state().giratinaCaught and not S.state().seviiRiftSealed,'station is not the final victory')
  print('SEVII_NATIVE_STATION_PASS','airlock collision, emergency exit, budget, overload, three followers, rescue, save/load, radio')
  love.event.quit()
end
