return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util')
  local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local S=assert(game.mods.exports.kanto_ascendant.seviiExpedition)
  require('src.world.OverworldController').rollEncounter=function()return nil end
  game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  assert(S.state().expeditionComplete,'completed finale QA profile required')
  for _,site in ipairs{S.chapters.sites.MIRROR_STONE,S.chapters.ruins.sites.ANCHOR}do
    local landing
    for _,d in ipairs{{0,1,'up'},{0,-1,'down'},{1,0,'left'},{-1,0,'right'}}do
      if S.walkable(site.map,site.x+d[1],site.y+d[2])then landing=d;break end
    end
    assert(landing);U.teleport(game,site.map,site.x+landing[1],site.y+landing[2],landing[3]);Q.settle()
    local object
    for _,n in ipairs(game.overworld.npcs)do if n.cellX==site.x and n.cellY==site.y then object=n;break end end
    assert(object and object.def.pushable==false,'story anchor explicitly fixed')
    game.overworld.strengthActive=true;U.hold(game,landing[3],60);Q.settle()
    assert(object.cellX==site.x and object.cellY==site.y,'actual Strength cannot move story anchor')
  end
  local A=dofile(root..'/sevii_apparition.lua');local complete=false
  assert(A.open(game,'mods/kanto_ascendant',function(en,de)return de end,function()complete=true end,{finale=true}))
  local scene=game.stack:top()
  for phase=1,3 do
    assert(scene.phase==phase);U.wait(80)
    assert(U.shot(game,out..'/finale-de-'..phase..'.png'));Q.tap('a')
  end
  Q.settle();assert(complete and S.state().expeditionComplete)
  print('SEVII_NATIVE_AFTERMATH_PASS','fixed story stones resist Strength; German finale labels rendered')
  love.event.quit()
end
