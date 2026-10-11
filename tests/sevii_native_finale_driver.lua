return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util')
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local S=assert(game.mods.exports.kanto_ascendant.seviiExpedition);local P=assert(S.chapters.finale)
  require('src.world.OverworldController').rollEncounter=function()return nil end
  game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
  game.mods.modOptions.kanto_ascendant.living_world_enabled=false
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',70)}
  Q.extraWarpAt=function(m,x,y)
    for _,w in ipairs(S.links[m.id]or{})do if w.x==x and w.y==y then return true end end
    return false
  end
  local function qs()return S.state().chapters and S.state().chapters.seven or{}end
  local function talk(site)Q.faceObject(site.x,site.y);Q.tap('a');U.wait(8)end
  local function reload()assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()end
  local function choose(value)
    local t=game.stack:top();assert(t.items,'stone menu required');local wanted
    for i,row in ipairs(t.items)do if row.value==value then wanted=i end end
    assert(wanted,'missing action '..value)
    for _=1,30 do if t.index==wanted then Q.tap('a');Q.settle();return end;Q.tap(t.index>wanted and'up'or'down')end
    error('stone menu stuck')
  end
  local function currentStone(index)
    for _,n in ipairs(game.overworld.npcs)do
      if n.def.name==P.stones[index].name then return {map=P.keyMap,x=n.cellX,y=n.cellY},n end
    end
    error('missing actual stone')
  end
  local function step(dir)
    local delta=({up={0,-1},down={0,1},left={-1,0},right={1,0}})[dir]
    local p=game.overworld.player;local x,y=p.cellX+delta[1],p.cellY+delta[2]
    for _=1,240 do
      if p.cellX==x and p.cellY==y and not p.moving then Q.settle();return end
      if game.stack:top()~=game.overworld then Q.settle()else U.hold(game,dir,1)end
    end
    U.shot(game,out..'/finale-push-failed.png')
    print('PUSH_STATE',tostring(game.overworld.strengthActive),tostring(qs().briefed),tostring(game.overworld.boulderTried))
    for i=1,3 do local a,n=currentStone(i);print('PUSH_STONE',i,a.x,a.y,tostring(n.def.pushable),tostring(n.moving))end
    error('actual step failed '..dir..' '..p.cellX..','..p.cellY..' -> '..x..','..y)
  end
  U.teleport(game,P.sites.CAMP.map,4,6,'up');Q.settle()
  talk(P.sites.CAMP);Q.settle();assert(not qs().briefed,'League gate')
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  talk(P.sites.CAMP);Q.settle();assert(not qs().briefed,'chapter six gate')
  -- Earlier chapters have independent native playthroughs. Isolate the finale.
  S.persist({version=1,stage=3,samples={heat=true,drift=true},chapterOneComplete=true,
    chapterTwoComplete=true,chapterThreeComplete=true,chapterFourComplete=true,
    chapterFiveComplete=true,chapterSixComplete=true})
  talk(P.sites.CAMP);Q.settle();assert(qs().briefed)
  U.teleport(game,P.keyMap,7,12,'up');Q.settle()
  talk(currentStone(2));choose('SUPPORT');assert(game.overworld.strengthActive)
  Q.walkTo(7,10);step('up');assert(qs().positions,'real push is recorded')
  talk(currentStone(2));choose('RESET')
  assert(game.overworld.player.cellX==7 and game.overworld.player.cellY==12 and not qs().positions,'reset restores safe start')
  talk(currentStone(2));choose('SUPPORT');Q.walkTo(7,12)
  assert(U.shot(game,out..'/finale-calibration-start.png'))
  local route={'left','left','up','up','right','right','up','up','up','up','up','down','left','left','up','up','right','right','right','left','down','down','down','down','down','left','left','up','right','down','right','up','up','up','up','down','left','left','up','up','right','up','right','right','down','left','left','right','down','down','down','down','down','right','right','up','left','down','left','up','up','up','up'}
  for i,dir in ipairs(route)do
    step(dir)
    if i==30 then
      local expected=qs().positions;reload()
      for index,pos in ipairs(expected)do local a=currentStone(index);assert(a.x==pos.x and a.y==pos.y,'stone position after actual reload')end
      -- Strength is deliberately scoped to one native map visit. Restore
      -- assistance through the same actual stone menu after reloading.
      local px,py=game.overworld.player.cellX,game.overworld.player.cellY
      talk(currentStone(2));choose('SUPPORT');Q.walkTo(px,py)
    end
  end
  assert(qs().calibrated,'actual Strength puzzle solved')
  assert(U.shot(game,out..'/finale-calibration-complete.png'))
  reload();assert(qs().calibrated)
  for i=1,3 do local _,n=currentStone(i);assert(n.def.pushable==false,'solved stone locked')end
  U.teleport(game,P.sites.SEAL.map,11,14,'up');Q.settle()
  talk(P.sites.SEAL);Q.settle();assert(not S.state().seviiRiftSealed,'cannot bypass anchor deliveries')
  for _,r in ipairs(P.relays)do
    local site=P.sites[r.id];U.teleport(game,site.map,11,14,'up');Q.settle()
    talk(site);Q.settle();assert(qs().relays[r.id],'actual relay conversation '..r.id)
  end
  reload();assert(P.ready())
  U.teleport(game,P.sites.SEAL.map,11,14,'up');Q.settle()
  local partyCount=#game.save.party
  local pools={};for id in pairs(S.maps)do pools[id]=require('src.link.Json').encode(S.encounters(game,id))end
  talk(P.sites.SEAL)
  local scene=game.stack:top();assert(scene.kind=='sevii-local-seal'and not scene.enemy)
  assert(not S.state().seviiRiftSealed,'no early completion before final picture')
  for phase=1,3 do
    assert(scene.phase==phase);U.wait(80)
    assert(U.shot(game,out..'/finale-seal-'..phase..'.png'));Q.tap('a')
  end
  Q.settle();assert(S.state().seviiRiftSealed and not S.state().expeditionComplete)
  assert(#game.save.party==partyCount,'no legendary gift')
  for id,old in pairs(pools)do assert(require('src.link.Json').encode(S.encounters(game,id))==old,'habitats remain available '..id)end
  reload();assert(S.state().seviiRiftSealed)
  U.teleport(game,P.sites.CAMP.map,4,6,'up');Q.settle()
  talk(P.sites.CAMP);Q.settle();assert(S.state().chapterSevenComplete and S.state().expeditionComplete)
  assert(game.save.inventory.GS_BALL==1 and S.state().chapters.seven.gsBallGranted,
    'Selma gives the unique GS Ball at the expedition ending')
  reload();assert(S.state().expeditionComplete and S.state().futureRiftLead
    and game.save.inventory.GS_BALL==1,'GS Ball survives save and reload')
  assert(not S.state().giratinaCaught and not S.state().giratinaDefeatedForever)
  talk(P.sites.CAMP);Q.settle();assert(S.state().expeditionComplete,'postgame conversation is safe')
  assert(game.save.inventory.GS_BALL==1,'camp cannot duplicate the GS Ball')
  -- The isolated finale fixture did not run Kanto's Oak-lab visibility beats.
  game.save.objectToggles.OAKS_LAB=game.save.objectToggles.OAKS_LAB or{}
  game.save.objectToggles.OAKS_LAB.OAKSLAB_OAK1=true
  U.teleport(game,'OAKS_LAB',5,3,'up');Q.settle()
  Q.faceObject(5,2);Q.tap('a');Q.settle()
  assert(game.save.inventory.GS_BALL==1 and S.state().chapters.seven.gsBallOakConsulted,
    'actual Professor Oak dialogue starts the Ivy lead and returns the GS Ball')
  reload();assert(S.state().chapters.seven.gsBallOakConsulted
    and game.save.inventory.GS_BALL==1,'Oak consultation survives reload')
  -- Check the world-state consequence through the real chapter-one buoy.
  local buoy=S.samples.drift;U.teleport(game,buoy.map,buoy.x,buoy.y+1,'up');Q.settle()
  talk(buoy)
  local t=game.stack:top();local text={};for _,page in ipairs(t.pages or{})do text[#text+1]=table.concat(page,' ')end
  assert(table.concat(text,' '):gsub('%s+',' '):find('strange pulse is gone',1,true),
    'calm postgame buoy text')
  Q.settle()
  print('SEVII_NATIVE_FINALE_PASS','native pushes, reset, reload, three relays, local seal, epilogue, all habitat tables retained, calm buoy')
  love.event.quit()
end
