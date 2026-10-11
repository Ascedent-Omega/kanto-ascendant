return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util')
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=assert(game.mods.exports.kanto_ascendant);local S=assert(K.seviiExpedition);local C=assert(S.chapters)
  require('src.world.OverworldController').rollEncounter=function()return nil end
  game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  assert(K.beyondKanto.activate(game,{decision='qa-expanded-postleague-fixture'}))
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',70)}
  game.mods.modOptions.kanto_ascendant.living_world_enabled=false
  local function visit(site,offset)
    U.teleport(game,site.map,site.x+(offset or -1),site.y,offset==1 and'left'or'right');Q.settle()
  end
  local function talk()Q.tap('a');U.wait(12)end
  visit(C.sites.ARCHIVIST);talk();Q.settle()
  assert(not S.state().chapters,'cannot start chapter two before chapter one')
  assert(S.begin(game))
  for _,id in ipairs{'heat','drift'}do
    local p=S.samples[id];U.teleport(game,p.map,p.x,p.y-1,'down');assert(S.collect(game,id))
  end
  assert(S.report());S.install(game)
  visit(C.sites.ARCHIVIST);talk()
  assert(U.shot(game,out..'/chapter-two-archive.png'));Q.settle()
  assert(S.state().chapters.two.archiveRead,'archive NPC records clue')
  visit(C.sites.MIRROR_STONE,1)
  local function startPuzzle()
    talk()
    for i=1,1800 do if game.stack:top().items then return end;Q.tap('a')end
    error('mirror selection did not open')
  end
  startPuzzle();Q.choose(function(i)return i.value=='SHORE'end);Q.tap('b');Q.settle()
  assert(not S.state().chapters.two.decoded,'cancel leaves puzzle retryable')
  startPuzzle()
  for _,symbol in ipairs{'STAR','WAVE','SHORE'}do Q.choose(function(i)return i.value==symbol end);U.wait(5)end
  Q.settle();assert(not S.state().chapters.two.decoded,'wrong answer remains retryable')
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  assert(S.state().chapters.two.archiveRead,'archive clue survives actual native reload')
  startPuzzle()
  for _,symbol in ipairs{'SHORE','WAVE','STAR'}do Q.choose(function(i)return i.value==symbol end);U.wait(5)end
  assert(U.shot(game,out..'/chapter-two-reflection.png'));Q.settle()
  assert(S.state().chapters.two.decoded,'correct reflected order persisted')
  visit(C.sites.ARCHIVIST);talk();Q.settle()
  assert(S.state().chapterTwoComplete,'chapter two archive report')
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  assert(S.state().chapterTwoComplete and S.state().chapterOneComplete,'both chapters survive native reload')
  assert(not S.state().giratinaCaught and not S.state().seviiRiftSealed,'early clue is not final victory')
  talk();Q.settle();assert(S.state().chapterTwoComplete,'completed archive remains safe to revisit')
  print('SEVII_NATIVE_CHAPTER_TWO_PASS','actual archive dialogue, cancel, wrong answer, reflection, report, reload')
  love.event.quit()
end
