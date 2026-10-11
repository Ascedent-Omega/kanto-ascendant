return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util')
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local S=assert(game.mods.exports.kanto_ascendant.seviiExpedition)
  local C=S.chapters;local I=assert(C.ice);local R=C.rescue
  require('src.world.OverworldController').rollEncounter=function()return nil end
  game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
  game.mods.modOptions.kanto_ascendant.living_world_enabled=false
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',70)}
  local function visit(p,dx,dy,dir)
    U.teleport(game,p.map,p.x+(dx or -1),p.y+(dy or 0),dir or'right');Q.settle()
  end
  local function talk()Q.tap('a');Q.settle()end
  local function qs()return S.state().chapters and S.state().chapters.four or{}end
  local function reload()
    assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  end
  local function step(dir,x,y,map)
    local started=false
    for f=1,180 do
      local ow=game.overworld
      if ow.player.moving then started=true end
      if started and not ow.player.moving and ow.map.id==(map or ow.map.id)
          and ow.player.cellX==x and ow.player.cellY==y then Q.settle();return end
      if not started then U.hold(game,dir,1)else U.wait(1)end
    end
    error('physical ice step failed '..dir..' to '..x..','..y)
  end
  visit(I.sites.GUIDE);talk();assert(not qs().briefed,'chapter three gate')
  -- Earlier chapters have their own physical playthroughs. Prepare only
  -- their state here through their normal guarded chapter APIs.
  assert(S.begin(game))
  for _,id in ipairs{'heat','drift'}do
    local p=S.samples[id];visit(p,0,-1,'down');assert(S.collect(game,id))
  end
  assert(S.report());visit(C.sites.ARCHIVIST);assert(C.readArchive(game))
  visit(C.sites.MIRROR_STONE,1,0,'left');assert(C.decode(game,{'SHORE','WAVE','STAR'}))
  visit(C.sites.ARCHIVIST);assert(C.report(game))
  visit(R.sites.stranded,0,1,'up');assert(R.begin(game))
  visit(R.sites.exit,0,0,'down');assert(R.arrive(game))
  visit(R.sites.home);assert(R.report(game))
  visit(I.sites.GUIDE);talk();assert(qs().briefed,'native guide briefing')
  assert(not I.readRecord(game)and not I.report(game),'cannot remotely skip archive')
  local ice=S.location('FourIsland_IcefallCave_1F',8,14)
  U.teleport(game,ice,8,15,'up');Q.settle()
  local ow=game.overworld;local original=ow.map:blockAt(4,7)
  local originalTile=ow.map:cellTile(8,14)
  assert(U.shot(game,out..'/ice-intact.png'))
  step('up',8,14,ice)
  assert(S.state().iceVisit.cracks['8,14'],'real first step cracks ice')
  local cracked=game.overworld.map:blockAt(4,7)
  assert(cracked~=original and game.overworld.map:cellTile(8,14)~=originalTile,'actual runtime picture changed')
  assert(U.shot(game,out..'/ice-cracked.png'))
  step('down',8,15,ice);reload()
  assert(game.overworld.map:blockAt(4,7)==cracked,'crack picture survives actual reload')
  local below=S.location('FourIsland_IcefallCave_B1F',8,14)
  step('up',8,14,below)
  assert(not S.state().iceVisit,'leaving ice floor clears visit cracks')
  -- Walk from the fall landing to the record case, without a teleport.
  for y=13,8,-1 do step('up',8,y,below)end
  step('right',9,8,below);talk()
  assert(qs().recordRead,'native frozen record conversation')
  U.teleport(game,ice,8,15,'up');Q.settle()
  assert(game.overworld.map:blockAt(4,7)==original,'return visit refreezes old runtime block')
  local start=I.route[1]
  visit(start,0,0,'up');talk();assert(qs().tracing and qs().traceIndex==1,'native anchor starts physical trace')
  step('down',12,17,start.map)
  assert(not qs().tracing and not qs().traced and qs().recordRead,'wrong step resets only attempt')
  visit(start,0,0,'up');talk();step('left',11,16,start.map)
  visit(I.sites.GUIDE);assert(not qs().tracing and qs().interrupted,'leaving chamber resets attempt')
  visit(start,0,0,'up');talk()
  local dirs={'left','up','up','right','right','down','down','left'}
  for index,dir in ipairs(dirs)do
    local p=I.route[index+1];step(dir,p.x,p.y,p.map)
    if index==4 then
      assert(qs().tracing and qs().traceIndex==5)
      local blocks={};for _,row in ipairs(S.maps[start.map].kaSeviiTraceBlocks)do
        blocks[#blocks+1]=game.overworld.map:blockAt(row.x,row.y)
      end
      assert(U.shot(game,out..'/chapter-four-trace.png'));reload()
      assert(qs().tracing and qs().traceIndex==5,'partial physical trace survives reload')
      for j,row in ipairs(S.maps[start.map].kaSeviiTraceBlocks)do
        assert(game.overworld.map:blockAt(row.x,row.y)==blocks[j],'partial trace picture survives reload')
      end
    end
  end
  assert(qs().traced and not qs().tracing,'eight actual steps close the boundary')
  assert(not S.state().chapterFourComplete,'guide report still required')
  assert(U.shot(game,out..'/chapter-four-seal.png'))
  visit(I.sites.GUIDE);talk();assert(S.state().chapterFourComplete,'native debrief completes chapter four')
  reload();assert(S.state().chapterFourComplete and S.state().chapterThreeComplete,'all progress preserved')
  assert(not S.state().giratinaCaught and not S.state().seviiRiftSealed,'rehearsal does not defeat antagonist or finish expansion')
  print('SEVII_NATIVE_ICE_MEMORY_PASS','crack graphics, fall, refreeze, record, wrong route, separation, trace, reload, report')
  love.event.quit()
end
