-- Four ground positions for the opted-in Sevii trainer doubles. This module
-- plans scenery only; the battle controller and renderer must both provide
-- four active slots before a fight can claim one of these layouts.
local A = {}

-- Voxel height and line-of-sight surveyed in the native map. Keep this list
-- narrow: a walkable clearing alone is not a playable four-actor shot.
local approved={
  BEACH={x=13,y=22,camera='wide'},
  VOLCANO={x=14,y=46,camera='wide'},
  -- All four Garden clearings fail the physical MAP camera. Keep Nela's
  -- ordinary single battle until a four-actor shot is authored there.
}

local offsets = {
  -- Two allies and two opponents, with two clear rows between sides.
  {{-1,2},{1,2},{-1,-2},{1,-2}},
  {{2,-1},{2,1},{-2,-1},{-2,1}},
}

local function occupied(S,map,x,y)
  local def=S.maps and S.maps[map]
  if not def then return true end
  for _,n in ipairs(def.objects or{})do
    if n.x==x and n.y==y then return true end
  end
  for _,link in ipairs(S.links and S.links[map]or{})do
    if link.x==x and link.y==y then return true end
  end
  return false
end

local function clear(S,map,x,y)
  return S.walkable(map,x,y) and not occupied(S,map,x,y)
end

local function candidate(S,map,cx,cy,shape)
  local cells={}
  for i,delta in ipairs(shape)do
    local x,y=cx+delta[1],cy+delta[2]
    if not clear(S,map,x,y)then return nil end
    cells[i]={x=x,y=y}
  end
  -- Require an apron around both partners, not merely the four feet. Large
  -- Voxel silhouettes and the camera need a full five-by-seven clearing.
  local spanX,spanY=shape==offsets[1]and 2 or 3,shape==offsets[1]and 3 or 2
  for y=cy-spanY,cy+spanY do
    for x=cx-spanX,cx+spanX do
      if not clear(S,map,x,y)then return nil end
    end
  end
  return {map=map,center={x=cx,y=cy},player={cells[1],cells[2]},
    enemy={cells[3],cells[4]},orientation=shape==offsets[1]and'ns'or'ew'}
end

function A.candidates(S,row)
  local found={}
  if not(S and row and row.map and row.x and row.y and S.walkable)then return found end
  -- Reuse the same deterministic clearing for first fight and rematches.
  -- The closest safe stage wins; map art can later reject it at render time.
  for radius=0,7 do
    for dy=-radius,radius do
      for dx=-radius,radius do
        if math.max(math.abs(dx),math.abs(dy))==radius then
          for _,shape in ipairs(offsets)do
            local layout=candidate(S,row.map,row.x+dx,row.y+dy,shape)
            if layout then found[#found+1]=layout end
          end
        end
      end
    end
  end
  return found
end

function A.find(S,row)
  local known=row and approved[row.id]
  if not known then return nil end
  for _,layout in ipairs(A.candidates(S,row))do
    if layout.center.x==known.x and layout.center.y==known.y then
      layout.camera=known.camera
      return layout
    end
  end
  return nil
end

return A
