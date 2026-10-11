-- Original FRLG movement elevations are collision labels, never world Y.
-- IsElevationMismatchAt in pret/pokefirered src/event_object_movement.c:
-- source 0 or destination 0/15 permits entry; other unequal labels block.
return function(mod,maps)
  local E={rows={},warps={}}
  for id,def in pairs(maps)do
    assert(def.kaOwner=='kasc.sevii-expedition/v1','foreign elevation owner: '..id)
    local rows=def.kaSeviiElevations
    assert(type(rows)=='table'and #rows==def.height*2,'missing source elevation rows: '..id)
    for _,row in ipairs(rows)do
      assert(type(row)=='string'and #row==def.width*2,'invalid source elevation width: '..id)
      for x=1,#row do local value=row:byte(x)-33
        assert(value>=0 and value<=15,'invalid source elevation label: '..id)
      end
    end
    E.rows[id]=rows
    local warps={};E.warps[id]=warps
    for _,w in ipairs(def.kaSeviiWarps or{})do
      warps[w.y]=warps[w.y]or{};warps[w.y][w.x]=true
    end
  end
  local function at(id,def,x,y)
    local rows=def and def.kaOwner=='kasc.sevii-expedition/v1'and E.rows[id]
    if not rows or x<0 or y<0 or x~=math.floor(x)or y~=math.floor(y)then return end
    local row=rows[y+1];local value=row and row:byte(x+1)
    return value and value-33
  end
  function E.at(map,x,y)
    return map and at(map.id,map.def,x,y)
  end
  local function compatible(a,b,surfing,warp)
    return a==nil or b==nil or warp or surfing and b==3
      or a==0 or b==0 or b==15 or a==b
  end
  function E.canCross(ow,dir)
    local map=ow.map;local player=ow.player
    if not map or not player or not E.rows[map.id]then return true end
    local dest,_,x,y=ow:connectionLanding(dir)
    if not dest then return true end
    local a=E.at(map,player.cellX,player.cellY)
    local b=at(dest.id,dest,x,y)
    local row=E.warps[dest.id]and E.warps[dest.id][y]
    return compatible(a,b,player.surfing,row and row[x])
  end
  function E.install()
    local OW=require('src.world.OverworldController')
    if not OW.__kascSeviiElevationCrossOriginal then
      local original=OW.crossConnection;OW.__kascSeviiElevationCrossOriginal=original
      OW.crossConnection=function(ow,dir,conn)
        local owner=OW.__kascSeviiElevationOwner
        if owner and not owner.canCross(ow,dir)then return false end
        return original(ow,dir,conn)
      end
    end
    OW.__kascSeviiElevationOwner=E
  end
  function E.allow(allowed,ctx)
    if not allowed or not ctx then return allowed end
    local a=E.at(ctx.map,ctx.fromX,ctx.fromY)
    local b=E.at(ctx.map,ctx.toX,ctx.toY)
    -- The native Gen1 host steps onto admitted directional stair warps;
    -- FRLG activates those warps before its ordinary elevation verdict.
    -- Keep the existing target/collision/occupancy checks in that adapter.
    if a~=nil and type(ctx.map.warpAtCell)=='function'
        and ctx.map:warpAtCell(ctx.toX,ctx.toY)then return allowed end
    -- FRLG CanStopSurfing permits a surfer to land on movement layer 3.
    -- The host already owns the dismount and entity occupancy verdict.
    if a~=nil and b==3 and ctx.mover and ctx.mover.surfing then return allowed end
    if not compatible(a,b,false,false)then
      ctx.reason='sevii-elevation';return false
    end
    return allowed
  end
  mod.hooks:wrap('movement.collision',function(nextCollision,allowed,ctx)
    return E.allow(nextCollision(allowed,ctx),ctx)
  end)
  return E
end
