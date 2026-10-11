return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util')
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local S=assert(game.mods.exports.kanto_ascendant.seviiExpedition);local P=assert(S.chapters.ruins)
  require('src.world.OverworldController').rollEncounter=function()return nil end
  game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
  game.mods.modOptions.kanto_ascendant.living_world_enabled=false
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',70)}
  -- Teach the native path helper about script-owned Sevii holes.
  Q.extraWarpAt=function(m,x,y)
    for _,w in ipairs(S.links[m.id]or{})do if w.x==x and w.y==y then return true end end
    return false
  end
  local function qs()return S.state().chapters and S.state().chapters.six or{}end
  local function talk(site)Q.faceObject(site.x,site.y);Q.tap('a');U.wait(8)end
  local function reload()assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()end
  U.teleport(game,P.sites.RESEARCHER.map,6,8,'up');Q.settle()
  talk(P.sites.RESEARCHER);Q.settle();assert(not qs().briefed)
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  talk(P.sites.RESEARCHER);Q.settle();assert(not qs().briefed)
  -- Chapters 1-5 have independent native playthroughs.
  S.persist({version=1,stage=3,samples={heat=true,drift=true},chapterOneComplete=true,
    chapterTwoComplete=true,chapterThreeComplete=true,chapterFourComplete=true,chapterFiveComplete=true})
  talk(P.sites.RESEARCHER);Q.settle();assert(qs().briefed)
  Q.walkTo(6,5,P.floors[1]);Q.settle();assert(game.overworld.map.id==P.floors[1])
  talk(P.sites.STONE_1);Q.settle();assert(qs().inscriptions['1'])
  Q.walkTo(11,5,P.sites.RESEARCHER.map);Q.settle()
  assert(qs().depth==0 and qs().inscriptions['1'],'wrong hole is recoverable')
  Q.walkTo(6,5,P.floors[1]);Q.settle()
  local exits={{6,1},{1,5},{11,5},{6,9}}
  for i=1,4 do
    talk(P.sites['STONE_'..i]);Q.settle();assert(qs().inscriptions[tostring(i)])
    local dest=i==4 and P.sites.ANCHOR.map or P.floors[i+1]
    Q.walkTo(exits[i][1],exits[i][2],dest);Q.settle()
    assert(game.overworld.map.id==dest and qs().depth==i,'native route floor '..i)
    if i==2 then reload();assert(qs().depth==2,'route survives actual reload')end
  end
  local partyCount=#game.save.party
  talk(P.sites.ANCHOR)
  local scene=game.stack:top();assert(scene.kind=='sevii-giratina-apparition'and not scene.enemy,'nonbattle scene')
  for phase=1,3 do
    assert(scene.phase==phase);U.wait(80)
    assert(U.shot(game,out..'/ruins-apparition-'..phase..'.png'))
    Q.tap('a')
  end
  Q.settle();assert(qs().witnessed and qs().identity=='GIRATINA')
  assert(#game.save.party==partyCount and not S.state().chapterSixComplete,'no gift and report required')
  reload();assert(qs().witnessed,'scene receipt survives reload')
  -- Return through the actual side door and entrance corridor.
  Q.walkTo(11,7,P.sites.RESEARCHER.map);Q.settle()
  Q.walkTo(13,5,P.sites.ANCHOR.map);Q.settle()
  Q.walkTo(5,9,P.floors[4]);Q.settle()
  for i=4,1,-1 do
    Q.walkTo(6,7,i==1 and P.sites.RESEARCHER.map or P.floors[i-1]);Q.settle()
  end
  talk(P.sites.RESEARCHER);Q.settle();assert(S.state().chapterSixComplete)
  reload();assert(S.state().chapterSixComplete and S.state().chapterFiveComplete)
  assert(not S.state().giratinaCaught and not S.state().seviiRiftSealed)
  print('SEVII_NATIVE_RUINS_PASS','four real floors, wrong exit, reload, visible Giratina, no battle, report')
  love.event.quit()
end
