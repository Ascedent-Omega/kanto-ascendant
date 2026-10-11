return function(game)
  io.stdout:setvbuf('no')
  local U=require('tests.drivers.util')
  local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local V=game.mods.exports.VOXEL_ASCENDANT
  assert(V,'Voxel Ascendant is required for this Sevii visual QA')
  game:startNewGame{intro=false}
  if V.setupCard then V.setupCard.suspended=true end
  if V.ascendantContent then
    V.ascendantContent.promptDisabled=true
    V.ascendantContent.onboardingShown=true
  end
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true
  game.save.flags.EVENT_GOT_STARTER=true
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  local pipelines=require('src.render.Pipelines')
  pipelines.setLevel('voxel',0)
  local views={
    {'one','KA_SEVII_ONE',12,13},
    {'forest','KA_SEVII_THREE_ISLAND_BERRY_FOREST',12,10},
    {'ice','KA_SEVII_FOUR_ISLAND_ICEFALL_CAVE_BACK',12,21},
    {'roof','KA_SEVII_TRAINER_TOWER_ROOF',11,9},
  }
  for _,v in ipairs(views)do
    U.teleport(game,v[2],v[3],v[4],'up')
    assert(pipelines.level('voxel')==1,'Sevii must enable Voxel Ascendant automatically')
    for n=1,1800 do
      if n>60 and V.lib.require('VoxelState').ready then break end
      U.wait(1)
      if n==1800 then error('Voxel scene not ready on '..v[2])end
    end
    U.wait(50)
    assert(pipelines.level('voxel')==1,'voxel level was disabled')
    assert(U.shot(game,out..'/sevii-voxel-'..v[1]..'.png'))
    print('SEVII_VOXEL_SHOT',v[1],game.overworld.map.id)
  end
  U.teleport(game,'VERMILION_CITY',27,26,'left')
  assert(pipelines.level('voxel')==0,'leaving Sevii restores the earlier Voxel preference')
  print('SEVII_VOXEL_NATIVE_PASS')
  love.event.quit()
end
