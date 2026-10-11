-- Continuous expedition QA. Only initial Orania/champion/team setup uses a
-- fixture; quest progress must come from native dialogue, puzzles and walking.
return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition;local C=S.chapters
  local N=dofile(root..'/tests/sevii_journey_navigation.lua')(game,S,Q)
  local natural=os.getenv('SEVII_JOURNEY_NATURAL')=='1'
  local resources=natural and dofile(root..'/tests/sevii_journey_resources.lua')(game,S,Q,N)or nil
  -- Read the actual renderer modules for QA readiness. The exported sandbox
  -- facade does not expose every internal status-returning helper.
  local function rendererLibrary(fn,seen)
    if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
    for i=1,200 do local key,value=debug.getupvalue(fn,i);if not key then break end
      if key=='V'then return value end
    end
    for i=1,200 do local key,value=debug.getupvalue(fn,i);if not key then break end
      local found=rendererLibrary(value,seen);if found then return found end
    end
  end
  local renderer=assert(rendererLibrary(game.mods.exports.VOXEL_ASCENDANT.lib.require('VoxelScene').render),'native renderer library')
  local function sceneReady()
    if require('src.render.Pipelines').level('voxel')==0 then return true end
    return not renderer.require('VoxelScene').pendingReason
      and not renderer.require('LoadingCompanion').status().visible
  end
  local function settle()
    for _=1,3000 do
      local t=game.stack:top();local ow=game.overworld
      if t==ow and not ow.transitioning and not ow.player.moving and not(ow.runner and ow.runner:isRunning())and sceneReady()then
        -- A wild encounter can open on the final movement frame. Confirm
        -- overworld readiness after the idle frames before sending talk A.
        U.wait(3)
        if game.stack:top()==ow and not ow.transitioning and not ow.player.moving
            and not(ow.runner and ow.runner:isRunning())and sceneReady()then return end
        t=game.stack:top()
      end
      if resources and t.enemy and t.enemy.mon and t.player then resources.battle(t)
      elseif getmetatable(t)==require('src.ui.QuarantineReport')then Q.tap('a')
      elseif t.isTextBox or t.pages then Q.tap('a')
      elseif t.items or t.party or t.subItems then Q.tap('b')else U.wait(1)end
    end
    error('journey UI did not settle')
  end
  Q.settle=function()
    local ok,why=pcall(settle)
    if not ok then
      local t=game.stack:top();print('JOURNEY_UI_FAILURE',tostring(t.kind),tostring(t.title),tostring(t.phase),tostring(t.enemy and t.enemy.mon and t.enemy.mon.species))
      assert(U.shot(game,out..'/journey-ui-failure.png'));error(why,0)
    end
  end
  Q.choose=function(match)
    for _=1,1800 do local t=game.stack:top();if t.items or t.submenu and t.subItems then break end;Q.tap('a')end
    local m=game.stack:top();local rows=m.submenu and m.subItems or m.items
    assert(rows,'choice menu');local wanted
    for i,r in ipairs(rows)do if match(r)then wanted=i;break end end
    assert(wanted,'choice row')
    for _=1,80 do local index=m.submenu and m.subIndex or m.index
      if index==wanted then Q.tap('a');return end;Q.tap(index>wanted and'up'or'down')end
    error('choice stuck')
  end
  if not natural then require('src.world.OverworldController').rollEncounter=function()return nil end end
  local resume=tonumber(os.getenv('SEVII_JOURNEY_RESUME')or'0')
  local last=tonumber(os.getenv('SEVII_JOURNEY_LAST')or'7')
  local reportFile=out..'/'..(os.getenv('SEVII_JOURNEY_REPORT')or'journey-progress.json')
  local character=os.getenv('SEVII_JOURNEY_CHARACTER')
  local upgrade=os.getenv('SEVII_JOURNEY_UPGRADE')=='1'
  assert(not natural or resume==0 and not upgrade,'resource journey requires a fresh continuous run')
  local oldSnapshot
  local function same(a,b)
    if type(a)~=type(b)then return false end
    if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not same(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end
    return true
  end
  local function checkOldSave(initial)
    if not oldSnapshot then return end
    assert(#game.save.boxes==#oldSnapshot.boxes,'pre-Sevii PC box count preserved')
    for bi,box in ipairs(oldSnapshot.boxes)do
      local live=game.save.boxes[bi];assert(#live==#box,'pre-Sevii PC occupants preserved')
      for mi,old in ipairs(box)do
        local mon=live[mi]
        for key,value in pairs(old)do assert(same(mon[key],value),'pre-Sevii PC field preserved '..key)end
        for key,value in pairs(mon)do if old[key]==nil then
          -- Existing equipment/ability services lazily bind an old Pokemon
          -- when Sevii advances AUTO to Gen3. Preserve original fields and
          -- permit only these reviewed service-owned additions.
          assert(key=='_kascAbility67'and type(value)=='table'
              and type(K.pokemonAbilityBinding67.view(game,mon,3).id)=='string'
            or key=='_kascEquipmentHandle'and type(value)=='string'
              and #value==35 and value:match('^eq%-%x+$'),'unexpected PC field addition '..key)
        end end
      end
    end
    assert(same(game.save.kaHoennEndgameRunEvents67,oldSnapshot.events),'pre-Sevii legendary receipt preserved')
    assert(game.save.money==oldSnapshot.money,'pre-Sevii money preserved')
    for id,count in pairs(oldSnapshot.inventory)do
      local current=game.save.inventory[id]
      assert(current==count or type(count)=='number'and type(current)=='number'and current>=count,'pre-Sevii item retained '..id)
    end
    if initial then
      assert(same(game.save.party,oldSnapshot.party),'pre-Sevii team loads unchanged')
      assert(not S.state().chapterOneComplete,'old save does not invent story completion')
    else
      for i,m in ipairs(oldSnapshot.party)do local current=game.save.party[i]
        assert(current and current.species==m.species and current.nickname==m.nickname
          and same(current.dvs,m.dvs)and current.ot==m.ot and current.otId==m.otId,'original team identity survives expedition')
      end
    end
  end
  local function checkCharacter()
    if character then assert(K.extendedCharacters.isEnabled()and K.extendedCharacters.getPlayerCharacter()==character,'requested character remains selected')end
  end
  Q.extraWarpAt=function(m,x,y)for _,w in ipairs(S.links[m.id]or{})do if w.x==x and w.y==y then return true end end;return false end
  local function checkpoint(chapter)
    local beforeReload=resources and resources.snapshot()
    assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
    if beforeReload then
      local afterReload=resources.snapshot()
      assert(same(beforeReload.party,afterReload.party),'journey HP/PP/status/levels preserved on load')
      assert(same(beforeReload.inventory,afterReload.inventory)and beforeReload.money==afterReload.money,'journey stock/money preserved on load')
    end
    checkCharacter()
    checkOldSave(false)
    local f=assert(io.open(reportFile,'wb'))
    f:write(require('src.link.Json').encode({steps=N.steps,seams=N.seams,doors=N.doors,sails=N.sails,
      character=K.extendedCharacters.getPlayerCharacter(),characterEnabled=K.extendedCharacters.isEnabled(),
      upgradedFromBase=upgrade,oldSavePreserved=upgrade and true or nil,
      chapter=chapter,complete=chapter==7 and S.state().expeditionComplete and game.overworld.map.id=='VERMILION_CITY',
      resources=resources and resources.snapshot()or nil,
      scope=natural and resources.scope or'Continuous native journey; initial champion/team/Orania fixtures; random and visible encounters disabled. Step counts cover successful navigator movements, excluding manual puzzle actions and interrupted attempts.'}));f:close()
    print('SEVII_CONTINUOUS_CHAPTER_PASS',chapter,N.steps,'steps',N.seams,'seams',N.doors,'doors')
    if chapter==last then love.event.quit();return true end
  end
  if resume==0 then
  if upgrade then
    local f=assert(io.open(out..'/upgrade-before.json','rb'))
    oldSnapshot=require('src.link.Json').decode(f:read('*a'));f:close()
    game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
    assert(game.overworld.map.id=='VERMILION_CITY','baseline old save starts in Orania')
    checkCharacter();checkOldSave(true)
    game.mods.modOptions.kanto_ascendant.living_world_enabled=false
    print('SEVII_OLD_SAVE_UPGRADE_LOAD_PASS',character)
  else
  game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
  if character then K.extendedCharacters.select(character);checkCharacter()end
  game.mods.modOptions.kanto_ascendant.living_world_enabled=false
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
  local mon=require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',70)
  mon.moves={{id='SURF',pp=15},{id='STRENGTH',pp=15},{id='ICE_BEAM',pp=10}}
  game.save.party={mon};game.save.inventory.SOULBADGE=true;game.save.inventory.RAINBOWBADGE=true
  if resources then resources.prepare()end
  U.teleport(game,'VERMILION_CITY',27,26,'right');Q.settle()
  Q.tap('a');Q.settle();assert(game.overworld.map.id=='VERMILION_CITY','pre-League ferry blocked')
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  assert(K.beyondKanto.activate(game,{decision='qa-expanded-postleague-fixture'}))
  end
  Q.settle();Q.tap('a');Q.settle()
  if game.overworld.map.id~=S.PORT then
    local p=game.overworld.player
    print('SEVII_FERRY_FAILURE',game.overworld.map.id,p.cellX,p.cellY,p.facing,
      tostring(renderer.require('VoxelScene').pendingReason),require('src.link.Json').encode(renderer.require('LoadingCompanion').status()))
    assert(U.shot(game,out..'/ferry-failure.png'))
  end
  assert(game.overworld.map.id==S.PORT,'native Orania ferry')
  if resources then resources.rest()end
  N.talk({map=S.ONE,x=16,y=12});Q.settle();assert(S.state().stage==1,'Mara starts chapter one')
  for _,id in ipairs{'drift','heat'}do N.talk(S.samples[id]);Q.settle();assert(S.state().samples[id],'physical buoy '..id)end
  N.talk({map=S.ONE,x=16,y=12});Q.settle();assert(S.state().chapterOneComplete,'actual report')
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  N.sail(2)
  N.talk(C.sites.ARCHIVIST);Q.settle();assert(S.state().chapters.two.archiveRead)
  N.talk(C.sites.MIRROR_STONE)
  for _,symbol in ipairs{'SHORE','WAVE','STAR'}do Q.choose(function(r)return r.value==symbol end);U.wait(5)end
  Q.settle();assert(S.state().chapters.two.decoded)
  N.talk(C.sites.ARCHIVIST);Q.settle();assert(S.state().chapterTwoComplete)
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  if checkpoint(2)then return end
  else
    game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
    game.mods.modOptions.kanto_ascendant.living_world_enabled=false
    local f=assert(io.open(reportFile,'rb'));local saved=require('src.link.Json').decode(f:read('*a'));f:close()
    assert(saved.chapter==resume,'resume must match verified journey checkpoint')
    N.steps,N.seams,N.doors,N.sails=saved.steps,saved.seams,saved.doors,saved.sails
    checkCharacter()
  end
  assert(S.state().chapterTwoComplete,'actual chapter-two checkpoint')
  if resume<3 then
    N.sail(3)
    local R=C.rescue;N.talk(R.sites.stranded);Q.settle()
    assert(S.state().chapters.three.escorting,'native forest rescue begins')
    N.landOnly=true;N.go(R.sites.exit.map,R.sites.exit.x,R.sites.exit.y);N.landOnly=false
    assert(S.state().chapters.three.rescued,'physical forest escort reaches exit')
    N.talk(R.sites.home);Q.settle();assert(S.state().chapterThreeComplete)
    if checkpoint(3)then return end
  end
  if resume<4 then
    N.sail(4)
    local I=C.ice;N.talk(I.sites.GUIDE);Q.settle();assert(S.state().chapters.four.briefed)
    local ice=assert(S.location('FourIsland_IcefallCave_1F',8,15))
    N.avoidThinIce=true;N.go(ice,8,15);N.avoidThinIce=false;Q.walkTo(8,14);Q.walkTo(8,15)
    local below=assert(S.location('FourIsland_IcefallCave_B1F',8,14))
    Q.walkTo(8,14,below);Q.settle();assert(game.overworld.map.id==below)
    N.talk(I.sites.RECORD);Q.settle();assert(S.state().chapters.four.recordRead)
    local start=I.route[1];N.go(start.map,start.x,start.y);U.hold(game,'up',1);Q.tap('a');Q.settle()
    assert(S.state().chapters.four.tracing)
    for i=2,#I.route do local p=I.route[i];Q.walkTo(p.x,p.y);Q.settle()end
    assert(S.state().chapters.four.traced)
    N.talk(I.sites.GUIDE);Q.settle();assert(S.state().chapterFourComplete)
    if checkpoint(4)then return end
  end
  if resume<5 then
    N.sail(5)
    local P=C.station
    N.talk(P.sites.NOAH);Q.settle();assert(S.state().chapters.five.briefed)
    N.talk(P.sites.CONSOLE)
    for _,value in ipairs{'ISOLATE','AIR','DOOR','CLOSE'}do Q.choose(function(r)return r.value==value end);U.wait(5)end
    Q.settle();assert(P.load()==3)
    N.talk(P.sites.ADA);Q.settle();assert(S.state().chapters.five.escorting)
    Q.walkTo(24,24);Q.settle();assert(S.state().chapters.five.rescued)
    N.talk(P.sites.CONSOLE)
    for _,value in ipairs{'AIR','RADIO','CALL'}do Q.choose(function(r)return r.value==value end);U.wait(5)end
    Q.settle();assert(S.state().chapterFiveComplete)
    if checkpoint(5)then return end
  end
  if resume<6 then
    N.sail(6)
    local P=C.ruins
    N.talk(P.sites.RESEARCHER);Q.settle();assert(S.state().chapters.six.briefed)
    Q.walkTo(6,5,P.floors[1]);Q.settle()
    local exits={{6,1},{1,5},{11,5},{6,9}}
    for i=1,4 do
      local p=P.sites['STONE_'..i];Q.faceObject(p.x,p.y);Q.tap('a');Q.settle()
      assert(S.state().chapters.six.inscriptions[tostring(i)])
      Q.walkTo(exits[i][1],exits[i][2],i==4 and P.sites.ANCHOR.map or P.floors[i+1]);Q.settle()
    end
    Q.faceObject(P.sites.ANCHOR.x,P.sites.ANCHOR.y);Q.tap('a');U.wait(10)
    local scene=game.stack:top();assert(scene.kind=='sevii-giratina-apparition')
    for i=1,3 do assert(scene.phase==i);U.wait(60);Q.tap('a')end
    Q.settle();assert(S.state().chapters.six.witnessed)
    Q.walkTo(11,7,P.sites.RESEARCHER.map);Q.settle()
    -- The eastern side corridor is isolated from the entrance landing.
    -- Return through the anchor chamber and the four real upward ladders.
    Q.walkTo(13,5,P.sites.ANCHOR.map);Q.settle()
    Q.walkTo(5,9,P.floors[4]);Q.settle()
    for i=4,1,-1 do Q.walkTo(6,7,i==1 and P.sites.RESEARCHER.map or P.floors[i-1]);Q.settle()end
    Q.faceObject(P.sites.RESEARCHER.x,P.sites.RESEARCHER.y);Q.tap('a');Q.settle()
    if not S.state().chapterSixComplete then
      local ow=game.overworld;local state=S.state();local actors={}
      for _,n in ipairs(ow.npcs)do actors[#actors+1]={name=n.def.name,x=n.cellX,y=n.cellY,passable=n.passable}end
      local f=assert(io.open(out..'/chapter-six-report-failure.json','w'))
      f:write(require('src.link.Json').encode({map=ow.map.id,x=ow.player.cellX,y=ow.player.cellY,
        facing=ow.player.facing,state=state,actors=actors}));f:close()
      assert(U.shot(game,out..'/chapter-six-report-failure.png'))
    end
    assert(S.state().chapterSixComplete)
    if checkpoint(6)then return end
  end
  if resume<7 then
    N.sail(7)
    local P=C.finale
    N.talk(P.sites.CAMP);Q.settle();assert(S.state().chapters.seven.briefed)
    N.go(P.keyMap,7,12)
    local function stone(index)
      for _,n in ipairs(game.overworld.npcs)do if n.def.name==P.stones[index].name then return n end end
      error('calibration stone missing')
    end
    local n=stone(2);Q.faceObject(n.cellX,n.cellY);Q.tap('a');U.wait(8)
    Q.choose(function(r)return r.value=='SUPPORT'end);Q.settle();Q.walkTo(7,12)
    local route={'left','left','up','up','right','right','up','up','up','up','up','down','left','left','up','up','right','right','right','left','down','down','down','down','down','left','left','up','right','down','right','up','up','up','up','down','left','left','up','up','right','up','right','right','down','left','left','right','down','down','down','down','down','right','right','up','left','down','left','up','up','up','up'}
    for _,dir in ipairs(route)do
      local d=({up={0,-1},down={0,1},left={-1,0},right={1,0}})[dir]
      local p=game.overworld.player;local x,y=p.cellX+d[1],p.cellY+d[2];local arrived=false
      for _=1,240 do
        if p.cellX==x and p.cellY==y and not p.moving then arrived=true;break end
        if game.stack:top()~=game.overworld then Q.settle()else U.hold(game,dir,1)end
      end
      assert(arrived,'physical calibration push');Q.settle()
    end
    assert(S.state().chapters.seven.calibrated)
    for _,r in ipairs(P.relays)do N.talk(P.sites[r.id]);Q.settle();assert(S.state().chapters.seven.relays[r.id])end
    assert(P.ready());N.talk(P.sites.SEAL)
    local scene=game.stack:top();assert(scene.kind=='sevii-local-seal')
    for i=1,3 do assert(scene.phase==i);U.wait(60);Q.tap('a')end
    Q.settle();assert(S.state().seviiRiftSealed and not S.state().expeditionComplete)
    N.talk(P.sites.CAMP);Q.settle();assert(S.state().expeditionComplete and S.state().futureRiftLead)
    assert(game.save.inventory.GS_BALL==1,
      'Sevii ending gives the GS Ball as a Key Item')
    assert(S.habitats.coverage(game).available==218,'all ordinary habitats remain available after finale')
    N.sail(0);assert(game.overworld.map.id=='VERMILION_CITY','whole journey returns to Kanto')
    assert(not S.state().giratinaCaught and not S.state().giratinaDefeatedForever)
    if checkpoint(7)then return end
  end
  love.event.quit()
end
