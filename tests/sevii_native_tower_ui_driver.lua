-- Render saved tower progress and the challenge UI; completed QA save only.
return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition;local C=S.tower
  game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  assert(S.state().towerComplete and C.progress()==8,'completed tower QA save required')
  assert(S.chapters.journal():find('SEVII TOWER: Champion.',1,true),'title visible in expedition journal')
  U.teleport(game,C.roof.map,7,9,'up');Q.settle();Q.tap('a');U.wait(240)
  assert(U.shot(game,out..'/sevii-tower-title.png'));Q.settle()
  -- A copied incomplete last-floor receipt is only a rendering fixture.
  local s=S.state();s.trainers.TOWER_8=nil;S.persist(s)
  local r=C.rows[8];U.teleport(game,r.map,r.x,r.y+1,'up');Q.settle();Q.tap('a');U.wait(30)
  local menu=game.stack:top();assert(menu.__vascHeaderLabel=='TRAINER TOWER')
  assert(U.shot(game,out..'/sevii-tower-menu.png'));Q.tap('b');Q.settle()
  game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  assert(S.state().towerComplete and C.progress()==8,'rendering fixture did not alter saved tower record')
  print('SEVII_TOWER_UI_PASS','saved journal title and dedicated challenge heading')
  love.event.quit()
end
