return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'))
  local U=require('tests.drivers.util')
  local A=dofile(root..'/sevii_double_arenas.lua')
  local S=assert(game.mods.exports.kanto_ascendant.seviiExpedition)
  local V=assert(game.mods.exports.VOXEL_ASCENDANT)
  local BattleArena=V.lib.require('BattleArena')
  local BattleCam=V.lib.require('BattleCam')
  local VoxelScene=V.lib.require('VoxelScene')
  print('SEVII_DOUBLE_CAPABILITIES',
    V.lib.require('BattleScene').doubleActorLayoutVersion,
    V.lib.require('OverworldBattle').doubleTextureCaptureVersion,
    V.lib.require('OverworldBattle').doublePlatformVersion)
  assert(S.doubleVisualReady(game),'Voxel four-actor scene capability missing')
  game:startNewGame{intro=false}
  local rows=S.trainers.rows
  local available={}
  for _,row in ipairs(rows)do
    local layout=A.find(S,row)
    assert((row.doubleArena~=nil)==(layout~=nil),'registered layout differs '..row.id)
    if layout then
      assert(layout.map==row.map)
      assert(#layout.player==2 and #layout.enemy==2)
      for _,side in ipairs{layout.player,layout.enemy}do
        for _,cell in ipairs(side)do assert(S.walkable(row.map,cell.x,cell.y))end
      end
      local again=A.find(S,row)
      assert(again and again.center.x==layout.center.x and again.center.y==layout.center.y)
      available[#available+1]=row.id
      print('SEVII_DOUBLE_ARENA_PASS',row.id,layout.map,
        layout.center.x,layout.center.y,layout.orientation)
      U.teleport(game,row.map,layout.center.x,layout.center.y,'down')
      local map=game.overworld.map
      assert(map and map.id==row.map,'native map unavailable')
      local function world(cell)
        return {cell.x*16+8,cell.y*16+8}
      end
      local function mean(pair)
        local a,b=world(pair[1]),world(pair[2])
        return {(a[1]+b[1])/2,(a[2]+b[2])/2}
      end
      local ground=VoxelScene.groundAt(map,layout.center.x,layout.center.y)
      local best=0
      for _,cam in ipairs{'tele','wide'}do
        for _,swap in ipairs{false,true}do
          local arena={player=mean(swap and layout.enemy or layout.player),
                       enemy=mean(swap and layout.player or layout.enemy),cam=cam}
          arena.mid={(arena.player[1]+arena.enemy[1])/2,
                     (arena.player[2]+arena.enemy[2])/2}
          local rig=BattleCam.rig(arena,ground,true)
          local clear=rig and rig.eye and BattleArena.cameraClear(map,rig.eye)
          local scores={}
          if clear then
            for _,side in ipairs{layout.player,layout.enemy}do
              for _,cell in ipairs(side)do
                local mark=world(cell)
                local height=VoxelScene.groundAt(map,cell.x,cell.y)
                scores[#scores+1]=BattleArena.visibility(map,rig.eye,mark,height)
              end
            end
          end
          local min=3
          if not clear then min=0 else
            for _,score in ipairs(scores)do min=math.min(min,score)end
          end
          best=math.max(best,min)
          if cam==layout.camera and not swap then
            assert(min==3,'approved Voxel shot is blocked for '..row.id)
          end
          print('SEVII_DOUBLE_VOXEL_VISIBILITY',row.id,cam,swap,
            clear and table.concat(scores,',') or 'eye-blocked')
        end
      end
      print('SEVII_DOUBLE_VOXEL_BEST',row.id,best)
      if best<3 then
        local alternatives=A.candidates(S,row)
        local alternate=nil
        for _,other in ipairs(alternatives)do
          local height=VoxelScene.groundAt(map,other.center.x,other.center.y)
          for _,cam in ipairs{'tele','wide'}do
            local arena={player=mean(other.player),enemy=mean(other.enemy),cam=cam}
            arena.mid={(arena.player[1]+arena.enemy[1])/2,
                       (arena.player[2]+arena.enemy[2])/2}
            local eye=BattleCam.rig(arena,height,true).eye
            if BattleArena.cameraClear(map,eye)then
              local visible=true
              for _,side in ipairs{other.player,other.enemy}do
                for _,cell in ipairs(side)do
                  local h=VoxelScene.groundAt(map,cell.x,cell.y)
                  if BattleArena.visibility(map,eye,world(cell),h)<3 then
                    visible=false
                  end
                end
              end
              if visible then
                alternate={layout=other,cam=cam}
                break
              end
            end
          end
          if alternate then break end
        end
        print('SEVII_DOUBLE_VOXEL_ALTERNATIVE',row.id,#alternatives,
          alternate and alternate.layout.center.x or 'none',
          alternate and alternate.layout.center.y or 'none',
          alternate and alternate.cam or 'none')
      end
    else
      print('SEVII_DOUBLE_ARENA_UNSAFE',row.id,row.map)
    end
  end
  assert(#available>=3,'need at least three surveyed double arenas')
  print('SEVII_DOUBLE_ARENA_SURVEY_PASS',#available,#rows)
  love.event.quit()
end
